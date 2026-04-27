import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repo_info.dart';
import '../providers/settings_provider.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import 'session_list_screen.dart';

/// After connecting via QR, shows the list of repos on the server.
/// The user picks one to open a terminal session in that workspace.
class RepoListScreen extends StatefulWidget {
  const RepoListScreen({super.key});

  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  List<RepoInfo> _repos = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final ws = context.read<WsService>();
    _sub = ws.events.listen((event) {
      if (event is WsRepoList) {
        setState(() {
          _repos = event.repos;
          _loading = false;
        });
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<WsService>(),
        child: SessionListScreen(workspacePath: repo.path),
      ),
    ));
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
      body: _loading
          ? Center(
              child: CircularProgressIndicator(strokeWidth: 1.5, color: th.accent),
            )
          : _repos.isEmpty
              ? Center(
                  child: Text(
                    'no repos configured\nadd folders in the desktop app',
                    textAlign: TextAlign.center,
                    style: th.monoSm(color: th.textMuted, size: fsz - 1),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _repos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final repo = _repos[i];
                    return GestureDetector(
                      onTap: () => _openRepo(repo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: th.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(repo.name, style: th.monoMd(size: fsz)),
                            const SizedBox(height: 3),
                            Text(repo.path, style: th.monoSm(color: th.textDim, size: fsz - 3)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
