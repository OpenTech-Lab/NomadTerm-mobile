import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/ws_service.dart';
import '../widgets/approve_dialog.dart';
import '../services/notification_service.dart';
import 'terminal_screen.dart';

const _cliTools = ['claude', 'codex', 'copilot', 'gemini'];

/// Lists active PTY sessions and lets the user spawn new ones.
class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  List<Session> _sessions = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenToEvents());
  }

  void _listenToEvents() {
    final ws = context.read<WsService>();
    _sub = ws.events.listen((event) {
      switch (event) {
        case WsSessionList(:final sessions):
          setState(() => _sessions = sessions);
        case WsApproveRequest(:final id, :final command, :final risk):
          _handleApprove(id, command, risk);
        default:
          break;
      }
    });
  }

  void _handleApprove(String id, String command, String risk) async {
    final ws = context.read<WsService>();

    // If app is in foreground, show dialog inline.
    if (mounted) {
      final decision = await showCupertinoApproveDialog(
        context,
        command: command,
        risk: risk,
      );
      if (decision != null) {
        ws.approve(id, decision: decision);
      }
    } else {
      // Background: send notification.
      await NotificationService.showApproveNotification(
        id: id.hashCode,
        command: command,
        risk: risk,
      );
    }
  }

  Future<void> _spawnSession() async {
    final ws = context.read<WsService>();

    final cli = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Choose AI CLI', style: TextStyle(color: Colors.white)),
        children: _cliTools
            .map(
              (tool) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, tool),
                child: Text(tool, style: const TextStyle(color: Colors.white70)),
              ),
            )
            .toList(),
      ),
    );

    if (cli != null) ws.spawn(cli);
  }

  void _openTerminal(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(session: session),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WsService>();

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('NomadTerm', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              ws.isConnected ? Icons.wifi : Icons.wifi_off,
              color: ws.isConnected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
      body: _sessions.isEmpty
          ? const Center(
              child: Text(
                'No active sessions.\nTap + to spawn an AI CLI.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (_, i) {
                final s = _sessions[i];
                return ListTile(
                  leading: const Icon(Icons.terminal, color: Color(0xFF6C63FF)),
                  title: Text(s.cli, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.status, style: const TextStyle(color: Colors.white54)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () => _openTerminal(s),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _spawnSession,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add),
      ),
    );
  }
}
