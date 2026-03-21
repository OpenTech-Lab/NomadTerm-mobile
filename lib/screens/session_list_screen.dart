import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import '../widgets/approve_dialog.dart';
import 'onboarding_screen.dart';
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
  String _workspace = '';
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
        case WsSessionList(:final sessions, :final workspace):
          setState(() {
            _sessions = sessions;
            if (workspace.isNotEmpty) _workspace = workspace;
          });
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

  Future<String?> _showCliPicker() {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final dth = ctx.watch<SettingsProvider>().nomadTheme;
        return Dialog(
          backgroundColor: dth.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: dth.border)),
                ),
                child: Text(dth.labelSelectCli, style: dth.monoSm(color: dth.textMuted)),
              ),
              // Options
              ..._cliTools.map((tool) => InkWell(
                onTap: () => Navigator.pop(ctx, tool),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: dth.border)),
                  ),
                  child: Row(children: [
                    Text('> ', style: dth.monoMd(color: dth.accent)),
                    Text(dth.cliDisplayName(tool), style: dth.monoMd()),
                  ]),
                ),
              )),
              // Cancel
              InkWell(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text('  cancel', style: dth.monoSm(color: dth.textMuted)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws  = context.watch<WsService>();
    final sp  = context.watch<SettingsProvider>();
    final th  = sp.nomadTheme;
    final fsz = sp.uiFontSize;

    return Scaffold(
      backgroundColor: th.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: !ws.isConnected && ws.lastError != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                tooltip: 'Back to QR scan',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (_) => false,
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text('nomadterm', style: th.monoMd(color: th.accent, size: fsz)),
              const SizedBox(width: 12),
              Text(
                th.sessionCountLabel(_sessions.length),
                style: th.monoSm(size: fsz - 2),
              ),
            ]),
            if (_workspace.isNotEmpty)
              Text(
                _workspace.split('/').last.isEmpty
                    ? _workspace
                    : _workspace.split('/').last,
                style: th.monoSm(color: th.textMuted, size: fsz - 3),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: StatusDot(
              active: ws.isConnected,
              label: ws.isConnected
                  ? th.labelConnected
                  : ws.lastError != null
                      ? 'connection failed'
                      : th.labelReconnecting,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 16),
            tooltip: th.labelSettings,
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
          ? _buildEmpty(th)
          : _buildList(ws, th),
      floatingActionButton: FloatingActionButton(
        onPressed: _spawnSession,
        tooltip: th.labelNewSession,
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildEmpty(NomadTheme th) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(th.labelNoSessions, style: th.monoMd(color: th.textMuted)),
        const SizedBox(height: 8),
        Text(th.labelSpawnHint, style: th.monoSm()),
      ],
    ),
  );

  Widget _buildList(WsService ws, NomadTheme th) => ListView.separated(
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
    final th      = context.watch<SettingsProvider>().nomadTheme;
    final running = session.isRunning;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running ? th.accent : th.textMuted,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(th.cliDisplayName(session.cli), style: th.monoMd()),
                const SizedBox(height: 2),
                Text(session.status, style: th.monoSm()),
              ],
            ),
          ),

          Text(session.id.substring(0, 8), style: th.monoSm(color: th.textDim)),
          const SizedBox(width: 16),

          GestureDetector(
            onTap: onKill,
            child: Text(th.labelKill, style: th.monoSm(color: th.textMuted, size: 13)),
          ),
          const SizedBox(width: 8),

          Text('›', style: th.monoMd(color: th.textMuted)),
        ]),
      ),
    );
  }
}
