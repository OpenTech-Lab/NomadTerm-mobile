import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../models/session.dart';
import '../providers/settings_provider.dart';
import '../services/ws_service.dart';
import '../theme.dart';

/// Full-screen terminal — pure black, no chrome.
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
  bool _showBar = true; // auto-hides after first keystroke

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 20000);
    _controller = TerminalController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final ws = context.read<WsService>();

    _sub = ws.events.listen((event) {
      if (event is WsPtyOutput) {
        _terminal.write(String.fromCharCodes(event.data));
      }
    });

    _terminal.onOutput = (data) {
      ws.input(widget.session.id, data);
      // Hide top bar after first keystroke — more screen estate.
      if (_showBar) setState(() => _showBar = false);
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
      // Thin status bar — tap to reveal/hide.
      appBar: _showBar ? _buildAppBar() : null,
      body: GestureDetector(
        onTap: () => setState(() => _showBar = !_showBar),
        child: TerminalView(
          _terminal,
          controller: _controller,
          autofocus: true,
          padding: const EdgeInsets.all(4),
          textStyle: TerminalStyle(
            fontSize: context.watch<SettingsProvider>().termFontSize,
          ),
          theme: _termTheme,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => PreferredSize(
    preferredSize: const Size.fromHeight(36),
    child: Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Back
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text('‹', style: T.monoLg(color: T.textMuted, size: 18)),
        ),
        const SizedBox(width: 12),

        // Session label
        Text(
          '${widget.session.cli}  ${widget.session.id.substring(0, 8)}',
          style: T.monoSm(color: T.textMuted),
        ),

        const Spacer(),

        // Kill
        GestureDetector(
          onTap: () {
            context.read<WsService>().kill(widget.session.id);
            Navigator.of(context).pop();
          },
          child: Text('kill', style: T.monoSm(color: T.errorRed)),
        ),
        const SizedBox(height: 36),
      ]),
    ),
  );
}

/// Pure black terminal theme with green-on-black palette.
const _termTheme = TerminalTheme(
  cursor:       Color(0xFF00FF88), // accent green cursor
  selection:    Color(0xFF003820),
  foreground:   Color(0xFFCCCCCC),
  background:   Color(0xFF000000),
  black:        Color(0xFF000000),
  white:        Color(0xFFCCCCCC),
  red:          Color(0xFFFF5555),
  green:        Color(0xFF00FF88),
  yellow:       Color(0xFFFFB300),
  blue:         Color(0xFF6699CC),
  magenta:      Color(0xFFCC99CC),
  cyan:         Color(0xFF66CCCC),
  brightBlack:  Color(0xFF444444),
  brightRed:    Color(0xFFFF8080),
  brightGreen:  Color(0xFF80FFB0),
  brightYellow: Color(0xFFFFD080),
  brightBlue:   Color(0xFF99BBDD),
  brightMagenta:Color(0xFFDDBBDD),
  brightCyan:   Color(0xFF99DDDD),
  brightWhite:  Color(0xFFEEEEEE),
  searchHitBackground:        Color(0xFF1A4020),
  searchHitBackgroundCurrent: Color(0xFF2A6030),
  searchHitForeground:        Color(0xFF00FF88),
);
