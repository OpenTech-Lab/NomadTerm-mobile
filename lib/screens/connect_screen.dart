import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/connection_config.dart';
import '../services/auth_service.dart';
import '../services/ws_service.dart';
import 'session_list_screen.dart';

/// First-run setup screen: enter Tailscale IP + port + token, or scan QR.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostCtrl = TextEditingController(text: '100.x.x.x');
  final _portCtrl = TextEditingController(text: '7681');
  final _tokenCtrl = TextEditingController();
  bool _scanning = false;
  bool _connecting = false;
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
    setState(() {
      _connecting = true;
      _error = null;
    });

    final config = ConnectionConfig(
      host: _hostCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 7681,
      token: _tokenCtrl.text.trim(),
    );

    await _auth.saveConfig(config);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WsService(config)..connect(),
          child: const SessionListScreen(),
        ),
      ),
    );
  }

  void _onQrDetected(String raw) {
    // Expected format: ws://host:port/ws?token=<token>
    final uri = Uri.tryParse(raw);
    if (uri == null) return;

    _hostCtrl.text = uri.host;
    _portCtrl.text = uri.port.toString();
    final token = uri.queryParameters['token'] ?? '';
    _tokenCtrl.text = token;

    setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _scanning = false),
          ),
          title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) {
              _onQrDetected(barcode!.rawValue!);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'NomadTerm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Remote AI Terminal',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _field(_hostCtrl, 'Tailscale IP', hint: '100.x.x.x'),
              const SizedBox(height: 12),
              _field(_portCtrl, 'Port', hint: '7681', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(_tokenCtrl, 'Token', hint: 'Bearer token from daemon'),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => setState(() => _scanning = true),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white70),
                label: const Text('Scan QR Code', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _connecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _connecting
                    ? const CupertinoActivityIndicator()
                    : const Text('Connect', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white24),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6C63FF)),
          ),
        ),
      );
}
