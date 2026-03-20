import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/connection_config.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/ws_service.dart';
import '../theme.dart';
import 'session_list_screen.dart';

/// Connection setup screen — terminal login aesthetic.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostCtrl  = TextEditingController(text: '100.x.x.x');
  final _portCtrl  = TextEditingController(text: '7681');
  final _tokenCtrl = TextEditingController();

  bool _scanning    = false;
  bool _connecting  = false;
  String? _error;

  final _auth = AuthService();

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host  = _hostCtrl.text.trim();
    final token = _tokenCtrl.text.trim();

    if (host.isEmpty || token.isEmpty) {
      setState(() => _error = 'host and token are required');
      return;
    }

    setState(() { _connecting = true; _error = null; });

    final config = ConnectionConfig(
      host: host,
      port: int.tryParse(_portCtrl.text.trim()) ?? 7681,
      token: token,
    );
    await _auth.saveConfig(config);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => WsService(config)..connect(),
        child: const SessionListScreen(),
      ),
    ));
  }

  void _onQrDetected(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    _hostCtrl.text  = uri.host;
    _portCtrl.text  = uri.port.toString();
    _tokenCtrl.text = uri.queryParameters['token'] ?? '';
    setState(() => _scanning = false);
  }

  // ── QR scanner overlay ───────────────────────────────────────────────
  Widget _buildScanner(NomadTheme th) => Scaffold(
    backgroundColor: th.bg,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: () => setState(() => _scanning = false),
      ),
      title: Text('scan qr', style: th.monoMd()),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: TDivider(),
      ),
    ),
    body: MobileScanner(
      onDetect: (capture) {
        final barcode = capture.barcodes.firstOrNull;
        if (barcode?.rawValue != null) _onQrDetected(barcode!.rawValue!);
      },
    ),
  );

  // ── Main form ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sp  = context.watch<SettingsProvider>();
    final th  = sp.nomadTheme;
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

              // ── Logo / header ──────────────────────────────────────
              Text('nomadterm',
                  style: th.monoLg(color: th.accent, size: fsz + 8, weight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('remote ai terminal  v0.1.0', style: th.monoSm(size: fsz - 2)),
              const SizedBox(height: 32),

              // ── Section label ──────────────────────────────────────
              Text('// connect to daemon',
                  style: th.monoSm(color: th.textDim, size: fsz - 3)),
              const SizedBox(height: 16),

              // ── Fields ─────────────────────────────────────────────
              _TermField(label: 'host', controller: _hostCtrl, hint: '100.x.x.x', fontSize: fsz),
              const SizedBox(height: 10),
              _TermField(label: 'port', controller: _portCtrl, hint: '7681',
                  keyboardType: TextInputType.number, fontSize: fsz),
              const SizedBox(height: 10),
              _TermField(label: 'token', controller: _tokenCtrl, hint: 'bearer token',
                  obscure: false, fontSize: fsz),

              // ── Error ──────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.error_outline, size: 12, color: th.errorRed),
                  const SizedBox(width: 6),
                  Text(_error!, style: th.monoSm(color: th.errorRed, size: fsz - 2)),
                ]),
              ],

              const SizedBox(height: 32),

              // ── Actions ────────────────────────────────────────────
              _TermButton(
                label: '\$ connect',
                onTap: _connecting ? null : _connect,
                primary: true,
                loading: _connecting,
                fontSize: fsz,
              ),
              const SizedBox(height: 10),
              _TermButton(
                label: '\$ scan-qr',
                onTap: () => setState(() => _scanning = true),
                fontSize: fsz,
              ),

              const SizedBox(height: 40),
              Text(
                'start daemon: nomadterm --ws --bind-tailscale',
                style: th.monoSm(size: fsz - 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _TermField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final double fontSize;

  const _TermField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.fontSize,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: th.monoSm(color: th.textMuted, size: fontSize - 3)),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: th.monoMd(size: fontSize),
          cursorColor: th.accent,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '> ',
            prefixStyle: th.monoMd(color: th.accent, size: fontSize),
          ),
        ),
      ],
    );
  }
}

class _TermButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  final double fontSize;

  const _TermButton({
    required this.label,
    required this.onTap,
    required this.fontSize,
    this.primary = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    final enabled = onTap != null && !loading;
    final fg = primary ? th.bg : th.accent;
    final bg = primary ? th.accent : Colors.transparent;
    final bd = primary ? th.accent : th.border;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bd),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
                )
              : Text(label, style: th.monoMd(color: fg, size: fontSize)),
        ),
      ),
    );
  }
}
