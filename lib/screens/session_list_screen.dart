import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import '../widgets/approve_dialog.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

const _cliTools = ['claude', 'codex', 'copilot', 'gemini'];

/// Session list — looks like a process manager / multiplexer status screen.
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
    if (!mounted) {
      await NotificationService.showApproveNotification(
        id: id.hashCode, command: command, risk: risk,
      );
      return;
    }
    final decision = await showApproveDialog(context, command: command, risk: risk);
    if (decision != null) ws.approve(id, decision: decision);
  }

  Future<void> _spawnSession() async {
    final ws = context.read<WsService>();
    final cli = await _showCliPicker();
    if (cli != null) ws.spawn(cli);
  }

  Future<String?> _showCliPicker() => showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: T.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.border))),
            child: Text('select ai cli', style: T.monoSm(color: T.textMuted)),
          ),
          // Options
          ..._cliTools.map((tool) => InkWell(
            onTap: () => Navigator.pop(ctx, tool),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: T.border)),
              ),
              child: Row(children: [
                Text('> ', style: T.monoMd(color: T.accent)),
                Text(tool, style: T.monoMd()),
              ]),
            ),
          )),
          // Cancel
          InkWell(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text('  cancel', style: T.monoSm(color: T.textMuted)),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws  = context.watch<WsService>();
    final fsz = context.watch<SettingsProvider>().uiFontSize;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          Text('nomadterm', style: T.monoMd(color: T.accent, size: fsz)),
          const SizedBox(width: 12),
          Text(
            '${_sessions.length} session${_sessions.length == 1 ? '' : 's'}',
            style: T.monoSm(size: fsz - 2),
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: StatusDot(
              active: ws.isConnected,
              label: ws.isConnected ? 'connected' : 'reconnecting',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 16),
            tooltip: 'settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            )),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: TDivider(),
        ),
      ),
      body: _sessions.isEmpty
          ? _buildEmpty()
          : _buildList(ws),
      floatingActionButton: FloatingActionButton(
        onPressed: _spawnSession,
        tooltip: 'new session',
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('no active sessions', style: T.monoMd(color: T.textMuted)),
        const SizedBox(height: 8),
        Text('tap + to spawn an ai cli', style: T.monoSm()),
      ],
    ),
  );

  Widget _buildList(WsService ws) => ListView.separated(
    itemCount: _sessions.length,
    separatorBuilder: (ctx, i) => const TDivider(),
    itemBuilder: (_, i) {
      final s = _sessions[i];
      return _SessionTile(
        session: s,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TerminalScreen(session: s),
        )),
        onKill: () => ws.kill(s.id),
      );
    },
  );
}

// ── Session tile ─────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onKill;

  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onKill,
  });

  @override
  Widget build(BuildContext context) {
    final running = session.isRunning;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          // Status indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running ? T.accent : T.textMuted,
            ),
          ),
          const SizedBox(width: 12),

          // CLI name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.cli, style: T.monoMd()),
                const SizedBox(height: 2),
                Text(session.status, style: T.monoSm()),
              ],
            ),
          ),

          // Session ID (short)
          Text(
            session.id.substring(0, 8),
            style: T.monoSm(color: T.textDim),
          ),
          const SizedBox(width: 16),

          // Kill button
          GestureDetector(
            onTap: onKill,
            child: Text('✕', style: T.monoSm(color: T.textMuted, size: 13)),
          ),
          const SizedBox(width: 8),

          // Arrow
          Text('›', style: T.monoMd(color: T.textMuted)),
        ]),
      ),
    );
  }
}
