import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection_config.dart';
import '../models/session.dart';
import '../models/usage.dart';

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

class WsUsageUpdate extends WsEvent {
  final UsageData data;
  WsUsageUpdate(this.data);
}

/// Manages the WebSocket connection to the NomadTerm daemon.
///
/// Reconnects automatically on disconnect. All events are exposed via
/// a broadcast [Stream] that multiple widgets can subscribe to.
class WsService extends ChangeNotifier {
  final ConnectionConfig config;

  WsService(this.config);

  WebSocketChannel? _channel;
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
  Future<void> connect() async {
    if (_disposed) return;
    await _disconnect();

    final uri = Uri.parse(config.wsUrl);
    _channel = WebSocketChannel.connect(
      uri,
      protocols: const [],
      // Pass Bearer token as a query param since WebSocket headers
      // are not easily injectable on all platforms.
    );

    try {
      await _channel!.ready;
    } catch (e) {
      final msg = e.toString();
      final isAuth = msg.contains('401') ||
          msg.toLowerCase().contains('unauthorized') ||
          msg.toLowerCase().contains('forbidden');
      _lastError = isAuth
          ? 'auth failed — wrong token (401)'
          : 'cannot reach daemon: $msg';
      _eventController.add(WsError(_lastError!));
      notifyListeners();
      if (!isAuth) _scheduleReconnect(); // don't retry on auth errors
      return;
    }

    _connected = true;
    _lastError = null;
    _eventController.add(WsConnected());
    notifyListeners();

    _sub = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _handleDisconnect(),
      onDone: _handleDisconnect,
    );
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
    await _channel?.sink.close();
    _channel = null;
  }

  /// Send a JSON control message to the daemon.
  void send(Map<String, dynamic> message) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode(message));
  }

  /// Spawn a new AI CLI session.
  void spawn(String cli) => send({'type': 'spawn', 'cli': cli});

  /// Send text input to a session.
  void input(String sessionId, String data) =>
      send({'type': 'input', 'session_id': sessionId, 'data': data});

  /// Send binary PTY input (raw keystrokes) as a binary frame.
  void inputBinary(Uint8List data) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(data);
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
    _channel?.sink.close();
    _eventController.close();
    super.dispose();
  }
}
