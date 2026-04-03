import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/connection_config.dart';
import '../models/session.dart';
import '../models/usage.dart';

const _kConnectTimeout = Duration(seconds: 8);

/// Events emitted by [WsService].
sealed class WsEvent {}

class WsConnected extends WsEvent {}

class WsDisconnected extends WsEvent {}

class WsPtyOutput extends WsEvent {
  final Uint8List data;
  WsPtyOutput(this.data);
}

class WsSessionList extends WsEvent {
  final List<Session> sessions;
  /// Absolute path of the server's working directory (repo root).
  final String workspace;
  WsSessionList(this.sessions, {this.workspace = ''});
}

class WsApproveRequest extends WsEvent {
  final String id;
  final String command;
  final String risk;
  WsApproveRequest({required this.id, required this.command, required this.risk});
}

class WsError extends WsEvent {
  final String message;
  WsError(this.message);
}

class WsSessionStarted extends WsEvent {
  final String sessionId;
  final String cli;
  WsSessionStarted({required this.sessionId, required this.cli});
}

class WsUsageUpdate extends WsEvent {
  final UsageData data;
  WsUsageUpdate(this.data);
}

/// Manages the WebSocket connection to the NomadTerm daemon.
///
/// Reconnects automatically on disconnect. All events are exposed via
/// a broadcast [Stream] that multiple widgets can subscribe to.
///
/// For wss:// connections, [ConnectionConfig.certFingerprint] is used to
/// pin the server's self-signed certificate (SSH-style TOFU).
class WsService extends ChangeNotifier {
  final ConnectionConfig config;

  WsService(this.config);

  io.WebSocket? _socket;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final _eventController = StreamController<WsEvent>.broadcast();

  /// Stream of events from the daemon (PTY output, session list, approve requests).
  Stream<WsEvent> get events => _eventController.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  String? _lastError;
  /// Human-readable description of the last connection failure, or null when connected.
  String? get lastError => _lastError;

  /// Connect (or reconnect) to the daemon WebSocket.
  /// Tries the LAN URL first; if that fails and a public endpoint is available,
  /// falls back to the public URL automatically.
  Future<void> connect() async {
    if (_disposed) return;
    await _disconnect();

    io.WebSocket? socket;
    String? lastErr;

    // Try each candidate URL in order: LAN first, then public fallback.
    final candidates = [
      config.wsUrl,
      if (config.publicWsUrl != null) config.publicWsUrl!,
    ];

    for (final url in candidates) {
      try {
        socket = await _openSocket(url);
        break; // connected — stop trying
      } catch (e) {
        lastErr = _classifyError(e);
      }
    }

    if (socket == null) {
      _lastError = lastErr ?? 'cannot reach daemon';
      _eventController.add(WsError(_lastError!));
      notifyListeners();
      final isAuthOrMismatch = _lastError!.contains('auth') ||
          _lastError!.contains('fingerprint');
      if (!isAuthOrMismatch) _scheduleReconnect();
      return;
    }

    _socket = socket;
    _connected = true;
    _lastError = null;
    _eventController.add(WsConnected());
    notifyListeners();

    _sub = socket.listen(
      _onMessage,
      onError: (_) => _handleDisconnect(),
      onDone: _handleDisconnect,
    );
  }

  /// Open a WebSocket connection.
  ///
  /// Encryption is provided by Tailscale at the VPN layer — the connection
  /// uses plain ws:// to the server's Tailscale IP (100.x.x.x).
  Future<io.WebSocket> _openSocket(String url) async {
    return io.WebSocket.connect(url).timeout(_kConnectTimeout);
  }

  /// Map an exception to a short, user-readable error string.
  String _classifyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized')) {
      return 'auth error — check token';
    }
    if (msg.contains('handshake') ||
        msg.contains('certificate') ||
        msg.contains('bad cert')) {
      return 'fingerprint mismatch — untrusted certificate';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'connection timed out';
    }
    if (msg.contains('refused') || msg.contains('econnrefused')) {
      return 'connection refused';
    }
    if (msg.contains('no address') || msg.contains('failed host lookup')) {
      return 'host not found';
    }
    return 'cannot reach daemon';
  }

  void _onMessage(dynamic raw) {
    if (raw is Uint8List || raw is List<int>) {
      // Binary frame = raw PTY output → forward to xterm.
      final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw as List<int>);
      _eventController.add(WsPtyOutput(bytes));
      return;
    }

    if (raw is String) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final type = json['type'] as String?;
        switch (type) {
          case 'session_list':
            final list = (json['sessions'] as List)
                .map((e) => Session.fromJson(e as Map<String, dynamic>))
                .toList();
            final workspace = json['workspace'] as String? ?? '';
            _eventController.add(WsSessionList(list, workspace: workspace));
          case 'approve':
            _eventController.add(WsApproveRequest(
              id: json['id'] as String,
              command: json['command'] as String,
              risk: json['risk'] as String? ?? 'unknown',
            ));
          case 'session_started':
            _eventController.add(WsSessionStarted(
              sessionId: json['session_id'] as String,
              cli: json['cli'] as String? ?? '',
            ));
          case 'error':
            _eventController.add(WsError(json['message'] as String? ?? 'unknown error'));
          case 'usage_update':
            _eventController.add(WsUsageUpdate(UsageData.fromJson(json)));
          default:
            debugPrint('[ws] unknown message type: $type');
        }
      } catch (e) {
        debugPrint('[ws] failed to parse message: $e');
      }
    }
  }

  void _handleDisconnect() {
    _connected = false;
    _eventController.add(WsDisconnected());
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  Future<void> _disconnect() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
  }

  /// Send a JSON control message to the daemon.
  void send(Map<String, dynamic> message) {
    if (!_connected || _socket == null) return;
    _socket!.add(jsonEncode(message));
  }

  /// Spawn a new AI CLI session.
  void spawn(String cli) => send({'type': 'spawn', 'cli': cli});

  /// Send text input to a session.
  void input(String sessionId, String data) =>
      send({'type': 'input', 'session_id': sessionId, 'data': data});

  /// Send binary PTY input (raw keystrokes) as a binary frame.
  void inputBinary(Uint8List data) {
    if (!_connected || _socket == null) return;
    _socket!.add(data);
  }

  /// Approve or deny a tool-call.
  void approve(String id, {required bool decision}) =>
      send({'type': 'approve', 'id': id, 'decision': decision});

  /// Kill a session.
  void kill(String sessionId) =>
      send({'type': 'kill', 'session_id': sessionId});

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _socket?.close();
    _eventController.close();
    super.dispose();
  }
}
