import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repo_info.dart';
import '../providers/settings_provider.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import 'session_list_screen.dart';

/// Displayed after connecting via QR. Sends [ListRepos] to the server,
/// shows the response, and navigates into [SessionListScreen] for the
/// chosen workspace.
class RepoListScreen extends StatefulWidget {
  const RepoListScreen({super.key});

  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  List<RepoInfo>? _repos;
  String? _error;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final ws = context.read<WsService>();
    _sub = ws.events.listen((event) {
      if (event is WsRepoList) {
        setState(() => _repos = event.repos);
        _sub?.cancel();
      } else if (event is WsError) {
        setState(() => _error = event.message);
        _sub?.cancel();
      }
    });
    ws.listRepos();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _openRepo(RepoInfo repo) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<WsService>(),
          child: SessionListScreen(workspacePath: repo.path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final th = sp.nomadTheme;
    final fsz = sp.uiFontSize;

    return Scaffold(
      backgroundColor: th.bg,
      appBar: AppBar(
        backgroundColor: th.bg,
        title: Text('select repo', style: th.monoMd(color: th.accent, size: fsz)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: TDivider(),
        ),
      ),
      body: SafeArea(child: _buildBody(th, fsz)),
    );
  }

  Widget _buildBody(NomadTheme th, double fsz) {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: th.monoSm(color: th.errorRed, size: fsz - 2)),
      );
    }

    if (_repos == null) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 1.5, color: th.accent),
      );
    }

    if (_repos!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('// no repos', style: th.monoSm(color: th.textDim, size: fsz - 3)),
            const SizedBox(height: 8),
            Text(
              'Add a folder in the desktop app, then reconnect.',
              style: th.monoSm(color: th.textMuted, size: fsz - 2),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _repos!.length,
      itemBuilder: (_, i) {
        final repo = _repos![i];
        return GestureDetector(
          onTap: () => _openRepo(repo),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: th.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repo.name, style: th.monoMd(size: fsz)),
                const SizedBox(height: 2),
                Text(
                  repo.path,
                  style: th.monoSm(color: th.textMuted, size: fsz - 3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
