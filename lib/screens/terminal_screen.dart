import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../models/session.dart';
import '../services/ws_service.dart';

/// Full-screen terminal view for a single PTY session.
class TerminalScreen extends StatefulWidget {
  final Session session;
  const TerminalScreen({super.key, required this.session});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal _terminal;
  late final TerminalController _controller;
  StreamSubscription? _sub;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _controller = TerminalController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final ws = context.read<WsService>();

    // Forward PTY output to xterm.
    _sub = ws.events.listen((event) {
      if (event is WsPtyOutput) {
        _terminal.write(String.fromCharCodes(event.data));
      }
    });

    // Forward xterm keyboard input → daemon.
    _terminal.onOutput = (data) {
      ws.input(widget.session.id, data);
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        title: Text(
          widget.session.cli,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _keyboardVisible ? Icons.keyboard_hide : Icons.keyboard,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _keyboardVisible = !_keyboardVisible),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            onPressed: () {
              context.read<WsService>().kill(widget.session.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: TerminalView(
        _terminal,
        controller: _controller,
        autofocus: true,
        // Dark terminal theme.
        theme: const TerminalTheme(
          cursor: Color(0xFFE0E0E0),
          selection: Color(0xFF4040A0),
          foreground: Color(0xFFE0E0E0),
          background: Color(0xFF0d0d1a),
          black: Color(0xFF1a1a2e),
          white: Color(0xFFE0E0E0),
          red: Color(0xFFFF5555),
          green: Color(0xFF50FA7B),
          yellow: Color(0xFFF1FA8C),
          blue: Color(0xFF6272A4),
          magenta: Color(0xFFFF79C6),
          cyan: Color(0xFF8BE9FD),
          brightBlack: Color(0xFF6272A4),
          brightRed: Color(0xFFFF6E6E),
          brightGreen: Color(0xFF69FF94),
          brightYellow: Color(0xFFFFFFA5),
          brightBlue: Color(0xFFD6ACFF),
          brightMagenta: Color(0xFFFF92DF),
          brightCyan: Color(0xFFA4FFFF),
          brightWhite: Color(0xFFFFFFFF),
          searchHitBackground: Color(0xFF5A4A00),
          searchHitBackgroundCurrent: Color(0xFF7A6A00),
          searchHitForeground: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
