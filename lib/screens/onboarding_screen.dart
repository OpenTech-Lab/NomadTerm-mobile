import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/connection_config.dart';
import '../providers/settings_provider.dart';
import '../services/repo_auth_service.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import 'session_list_screen.dart';

/// Connection setup screen — QR scan or quick-connect from history.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _detected = false; // guard against duplicate detections
  bool _connecting = false;
  String? _connectError;
  String _version = '';

  final _repoAuth = RepoAuthService();
  List<ConnectionConfig> _savedRepos = [];

  late final MobileScannerController _scannerController;
  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _loadSavedRepos();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _loadSavedRepos() async {
    final repos = await _repoAuth.loadAllRepos();
    final now = DateTime.now();
    final valid = repos
        .where((r) => r.expiresAt == null || r.expiresAt!.isAfter(now))
        .toList();
    setState(() => _savedRepos = valid);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _startScanning() {
    _detected = false;
    _scannerController.start();
    _scanLineController.repeat();
    setState(() => _scanning = true);
  }

  void _stopScanning() {
    _scannerController.stop();
    _scanLineController.stop();
    setState(() => _scanning = false);
  }

  Future<void> _connectWith(ConnectionConfig config) async {
    if (!mounted || _connecting) return;
    setState(() {
      _connecting = true;
      _connectError = null;
    });

    final ws = WsService(config);
    try {
      await ws.connect();
      // Give a brief moment for the ready/error to propagate.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        ws.dispose();
        return;
      }

      if (ws.isConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: ws,
              child: const SessionListScreen(),
            ),
          ),
        );
      } else {
        ws.dispose();
        setState(() {
          _connecting = false;
          _connectError = 'cannot reach server at ${config.host}:${config.port}';
        });
      }
    } catch (e) {
      ws.dispose();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connectError = 'cannot reach server at ${config.host}:${config.port}';
      });
    }
  }

  Future<void> _renameRepo(ConnectionConfig repo, String newName) async {
    await _repoAuth.saveRepo(repo.copyWith(repoName: newName));
    await _loadSavedRepos();
  }

  Future<void> _deleteRepo(ConnectionConfig repo) async {
    final id = repo.repoId.isNotEmpty ? repo.repoId : repo.token;
    await _repoAuth.removeRepo(id);
    await _loadSavedRepos();
  }

  void _showEditSheet(ConnectionConfig repo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.read<SettingsProvider>().nomadTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _EditSheet(
        repo: repo,
        onSave: (name) async {
          Navigator.pop(context);
          await _renameRepo(repo, name);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteRepo(repo);
        },
      ),
    );
  }

  void _onQrDetected(String raw) {
    if (_detected) return;
    _detected = true;
    _scannerController.stop();
    _scanLineController.stop();

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      _detected = false;
      setState(() => _scanning = false);
      return;
    }

    ConnectionConfig? config;

    if (uri.scheme == 'nomadterm') {
      final expiresStr = uri.queryParameters['expires_at'];
      config = ConnectionConfig(
        host: uri.host,
        port: uri.port > 0 ? uri.port : 7681,
        token: uri.queryParameters['token'] ?? '',
        useTls: uri.queryParameters['tls'] == '1',
        repoId: uri.queryParameters['repo_id'] ?? '',
        repoPath: uri.queryParameters['repo_path'] ?? '',
        repoName: uri.queryParameters['repo_name'] ?? '',
        expiresAt:
            (expiresStr != null ? DateTime.tryParse(expiresStr) : null) ??
            DateTime.now().add(const Duration(days: 30)),
      );
    } else if (uri.scheme == 'ws' || uri.scheme == 'wss') {
      // Legacy QR format — connect directly without showing form fields
      config = ConnectionConfig(
        host: uri.host,
        port: uri.port > 0 ? uri.port : 7681,
        token: uri.queryParameters['token'] ?? '',
        useTls: uri.scheme == 'wss',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }

    if (config == null) {
      _detected = false;
      setState(() => _scanning = false);
      return;
    }

    _repoAuth.saveRepo(config);
    _connectWith(config);
  }

  // ── QR scanner overlay ───────────────────────────────────────────────
  Widget _buildScanner(NomadTheme th) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: Icon(Icons.close, size: 18, color: th.accent),
        onPressed: _stopScanning,
      ),
      title: Text('scan qr', style: th.monoMd(color: th.accent)),
      actions: [
        IconButton(
          icon: Icon(Icons.flashlight_on, size: 20, color: th.accent),
          onPressed: () => _scannerController.toggleTorch(),
          tooltip: 'toggle torch',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: TDivider(),
      ),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) _onQrDetected(barcode!.rawValue!);
          },
        ),
        AnimatedBuilder(
          animation: _scanLineController,
          builder: (context, child) => CustomPaint(
            painter: _QrScanOverlayPainter(
              accentColor: th.accent,
              scanProgress: _scanLineController.value,
            ),
          ),
        ),
        Positioned(
          bottom: 52,
          left: 0,
          right: 0,
          child: Text(
            'align qr code within the frame',
            textAlign: TextAlign.center,
            style: th.monoSm(color: Colors.white70, size: 13),
          ),
        ),
      ],
    ),
  );

  // ── Main screen ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final th = sp.nomadTheme;
    final fsz = sp.uiFontSize;

    if (_scanning) return _buildScanner(th);

    return Scaffold(
      backgroundColor: th.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Header ────────────────────────────────────────────
              Text(
                'nomadterm',
                style: th.monoLg(
                  color: th.accent,
                  size: fsz + 8,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remote ai terminal  ${_version.isNotEmpty ? 'v$_version' : ''}',
                style: th.monoSm(size: fsz - 2),
              ),
              const SizedBox(height: 36),

              // ── Quick connect ─────────────────────────────────────
              Text(
                '// quick connect',
                style: th.monoSm(color: th.textDim, size: fsz - 3),
              ),
              const SizedBox(height: 10),

              if (_savedRepos.isEmpty)
                _EmptyHistory(th: th, fsz: fsz)
              else
                ..._savedRepos.map(
                  (repo) => _SavedRepoTile(
                    repo: repo,
                    fontSize: fsz,
                    onTap: () => _connectWith(repo),
                    onShowEdit: () => _showEditSheet(repo),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Connection status ──────────────────────────────────
              if (_connecting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: th.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('connecting…', style: th.monoSm(color: th.textMuted, size: fsz - 2)),
                  ]),
                ),
              if (_connectError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: th.errorRed),
                    ),
                    child: Text(
                      _connectError!,
                      style: th.monoSm(color: th.errorRed, size: fsz - 2),
                    ),
                  ),
                ),

              // ── Add new connection ────────────────────────────────
              Text(
                '// add connection',
                style: th.monoSm(color: th.textDim, size: fsz - 3),
              ),
              const SizedBox(height: 10),
              _TermButton(
                label: '\$ scan-qr',
                onTap: _connecting ? null : _startScanning,
                fontSize: fsz,
              ),

              const SizedBox(height: 40),
              Text(
                'start daemon: nomadterm --ws --bind-tailscale',
                style: th.monoSm(size: fsz - 3),
              ),
              const SizedBox(height: 6),
              Text(
                'remote access works best with tailscale on both devices',
                style: th.monoSm(color: th.textDim, size: fsz - 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final NomadTheme th;
  final double fsz;

  const _EmptyHistory({required this.th, required this.fsz});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(border: Border.all(color: th.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'no saved connections',
            style: th.monoMd(color: th.textMuted, size: fsz),
          ),
          const SizedBox(height: 4),
          Text(
            'scan the qr code from the daemon gui to connect',
            style: th.monoSm(color: th.textDim, size: fsz - 3),
          ),
        ],
      ),
    );
  }
}

class _TermButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  const _TermButton({
    required this.label,
    required this.onTap,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(border: Border.all(color: th.border)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: th.monoMd(color: th.accent, size: fontSize),
          ),
        ),
      ),
    );
  }
}

// ── QR scanner viewfinder overlay ────────────────────────────────────────

class _QrScanOverlayPainter extends CustomPainter {
  final Color accentColor;
  final double scanProgress; // 0.0 → 1.0

  const _QrScanOverlayPainter({
    required this.accentColor,
    required this.scanProgress,
  });

  static const _frameSize = 260.0;
  static const _cornerLen = 26.0;
  static const _cornerThick = 3.0;
  static const _dimAlpha = 0.72;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - _frameSize / 2;
    final top = cy - _frameSize / 2;
    final right = cx + _frameSize / 2;
    final bot = cy + _frameSize / 2;

    // ── dim surround ──────────────────────────────────────────────────
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: _dimAlpha);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), dimPaint);
    canvas.drawRect(Rect.fromLTRB(0, bot, size.width, size.height), dimPaint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bot), dimPaint);
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bot), dimPaint);

    // ── corner brackets ───────────────────────────────────────────────
    final cp = Paint()
      ..color = accentColor
      ..strokeWidth = _cornerThick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // top-left
    canvas.drawLine(Offset(left, top + _cornerLen), Offset(left, top), cp);
    canvas.drawLine(Offset(left, top), Offset(left + _cornerLen, top), cp);
    // top-right
    canvas.drawLine(Offset(right - _cornerLen, top), Offset(right, top), cp);
    canvas.drawLine(Offset(right, top), Offset(right, top + _cornerLen), cp);
    // bottom-left
    canvas.drawLine(Offset(left, bot - _cornerLen), Offset(left, bot), cp);
    canvas.drawLine(Offset(left, bot), Offset(left + _cornerLen, bot), cp);
    // bottom-right
    canvas.drawLine(Offset(right - _cornerLen, bot), Offset(right, bot), cp);
    canvas.drawLine(Offset(right, bot - _cornerLen), Offset(right, bot), cp);

    // ── animated scan line ────────────────────────────────────────────
    final lineY = top + scanProgress * _frameSize;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.0),
          accentColor.withValues(alpha: 0.85),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(left, lineY - 1, _frameSize, 2));
    canvas.drawRect(Rect.fromLTWH(left, lineY - 1, _frameSize, 2.5), linePaint);
  }

  @override
  bool shouldRepaint(_QrScanOverlayPainter old) =>
      old.scanProgress != scanProgress || old.accentColor != accentColor;
}

// ── Edit / rename sheet ───────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final ConnectionConfig repo;
  final Future<void> Function(String name) onSave;
  final Future<void> Function() onDelete;

  const _EditSheet({
    required this.repo,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.repo.repoName.isNotEmpty
        ? widget.repo.repoName
        : widget.repo.host;
    _nameCtrl = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final th = sp.nomadTheme;
    final fsz = sp.uiFontSize;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// edit connection',
            style: th.monoSm(color: th.textDim, size: fsz - 3),
          ),
          const SizedBox(height: 16),

          // ── name field ─────────────────────────────────────────
          Text(
            'name',
            style: th.monoSm(color: th.textMuted, size: fsz - 3),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: th.monoMd(size: fsz),
            cursorColor: th.accent,
            decoration: InputDecoration(
              prefixText: '> ',
              prefixStyle: th.monoMd(color: th.accent, size: fsz),
            ),
          ),
          const SizedBox(height: 24),

          // ── save ───────────────────────────────────────────────
          _SheetButton(
            label: '\$ save',
            color: th.accent,
            onTap: () {
              final name = _nameCtrl.text.trim();
              widget.onSave(name.isNotEmpty ? name : widget.repo.host);
            },
            fsz: fsz,
          ),
          const SizedBox(height: 8),

          // ── remove ─────────────────────────────────────────────
          _SheetButton(
            label: '\$ remove connection',
            color: th.errorRed,
            onTap: widget.onDelete,
            fsz: fsz,
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double fsz;

  const _SheetButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.fsz,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(border: Border.all(color: color)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label,
          style: th.monoMd(color: color, size: fsz),
        ),
      ),
    );
  }
}

class _SavedRepoTile extends StatelessWidget {
  final ConnectionConfig repo;
  final VoidCallback onTap;
  final VoidCallback onShowEdit;
  final double fontSize;

  const _SavedRepoTile({
    required this.repo,
    required this.onTap,
    required this.onShowEdit,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    final name = repo.repoName.isNotEmpty ? repo.repoName : repo.host;
    final expires = repo.expiresAt != null
        ? 'exp ${repo.expiresAt!.toLocal().toString().substring(0, 10)}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(border: Border.all(color: th.border)),
      child: Row(
        children: [
          // ── tap-to-connect area ────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: th.monoMd(size: fontSize)),
                    Text(
                      '${repo.host}:${repo.port}  $expires',
                      style: th.monoSm(color: th.textMuted, size: fontSize - 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── edit button ────────────────────────────────────────────
          GestureDetector(
            onTap: onShowEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Icon(Icons.edit_outlined, size: 15, color: th.textDim),
            ),
          ),
        ],
      ),
    );
  }
}
