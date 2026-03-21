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
  final _focusNode = FocusNode();
  StreamSubscription? _sub;
  bool _showBar = true;

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
      if (_showBar) setState(() => _showBar = false);
    };

    // Request keyboard focus as soon as the terminal is ready.
    _focusNode.requestFocus();
  }

  void _toggleBar() {
    setState(() => _showBar = !_showBar);
    // Re-focus the terminal after toggling so the keyboard stays up.
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp  = context.watch<SettingsProvider>();
    final th  = sp.nomadTheme;
    final termTheme = _buildTermTheme(th);

    return Scaffold(
      backgroundColor: th.bg,
      appBar: _showBar ? _buildAppBar(th) : null,
      body: SafeArea(
        child: GestureDetector(
          // translucent so TerminalView still receives pointer events for text
          // selection, scroll, etc. — the onTap only fires on unhandled taps.
          behavior: HitTestBehavior.translucent,
          onTap: _toggleBar,
          child: TerminalView(
            _terminal,
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            padding: const EdgeInsets.all(4),
            textStyle: TerminalStyle(fontSize: sp.termFontSize),
            theme: termTheme,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(NomadTheme th) => PreferredSize(
    preferredSize: const Size.fromHeight(36),
    child: Container(
      color: th.bg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text('‹', style: th.monoLg(color: th.textMuted, size: 18)),
        ),
        const SizedBox(width: 12),
        Text(
          '${th.cliDisplayName(widget.session.cli)}  ${widget.session.id.substring(0, 8)}',
          style: th.monoSm(color: th.textMuted),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            context.read<WsService>().kill(widget.session.id);
            Navigator.of(context).pop();
          },
          child: Text(th.labelKill, style: th.monoSm(color: th.errorRed)),
        ),
      ]),
    ),
  );
}

/// Build an xterm [TerminalTheme] from the active [NomadTheme].
TerminalTheme _buildTermTheme(NomadTheme th) {
  if (th is PixelRpgTheme) {
    return TerminalTheme(
      cursor:                     th.accent,
      selection:                  const Color(0xFF2D1040),
      foreground:                 th.textPrimary,
      background:                 th.bg,
      black:                      th.bg,
      white:                      th.textPrimary,
      red:                        th.errorRed,
      green:                      th.accent,
      yellow:                     th.warnYellow,
      blue:                       th.mp,
      magenta:                    const Color(0xFFCC99CC),
      cyan:                       const Color(0xFF99CCFF),
      brightBlack:                const Color(0xFF4A3060),
      brightRed:                  const Color(0xFFFF8080),
      brightGreen:                const Color(0xFFDDB0FF),
      brightYellow:               const Color(0xFFFFD080),
      brightBlue:                 const Color(0xFF99BBFF),
      brightMagenta:              const Color(0xFFEEBBEE),
      brightCyan:                 const Color(0xFFBBDDFF),
      brightWhite:                th.textPrimary,
      searchHitBackground:        const Color(0xFF3D1F6B),
      searchHitBackgroundCurrent: const Color(0xFF5D2F9B),
      searchHitForeground:        th.accent,
    );
  }
  // Matrix (default)
  return const TerminalTheme(
    cursor:                     Color(0xFF00FF88),
    selection:                  Color(0xFF003820),
    foreground:                 Color(0xFFCCCCCC),
    background:                 Color(0xFF000000),
    black:                      Color(0xFF000000),
    white:                      Color(0xFFCCCCCC),
    red:                        Color(0xFFFF5555),
    green:                      Color(0xFF00FF88),
    yellow:                     Color(0xFFFFB300),
    blue:                       Color(0xFF6699CC),
    magenta:                    Color(0xFFCC99CC),
    cyan:                       Color(0xFF66CCCC),
    brightBlack:                Color(0xFF444444),
    brightRed:                  Color(0xFFFF8080),
    brightGreen:                Color(0xFF80FFB0),
    brightYellow:               Color(0xFFFFD080),
    brightBlue:                 Color(0xFF99BBDD),
    brightMagenta:              Color(0xFFDDBBDD),
    brightCyan:                 Color(0xFF99DDDD),
    brightWhite:                Color(0xFFEEEEEE),
    searchHitBackground:        Color(0xFF1A4020),
    searchHitBackgroundCurrent: Color(0xFF2A6030),
    searchHitForeground:        Color(0xFF00FF88),
  );
}
