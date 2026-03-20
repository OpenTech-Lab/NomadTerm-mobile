import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';

/// Central design tokens — pure black professional terminal style.
abstract final class T {
  // ── Colours ───────────────────────────────────────────────────────────
  static const bg       = Color(0xFF000000); // pure black
  static const surface  = Color(0xFF0A0A0A); // panel background
  static const border   = Color(0xFF1C1C1C); // hairline separators
  static const accent   = Color(0xFF00FF88); // terminal green
  static const accentDim= Color(0xFF00C86A); // pressed / disabled
  static const textPrimary = Color(0xFFEEEEEE);
  static const textMuted   = Color(0xFF555555);
  static const textDim     = Color(0xFF2C2C2C);
  static const errorRed    = Color(0xFFFF3B3B);
  static const warnYellow  = Color(0xFFFFB300);

  // ── Typography ────────────────────────────────────────────────────────
  static const mono = TextStyle(fontFamily: 'monospace');

  static TextStyle monoSm({Color color = textMuted, double size = 11}) =>
      TextStyle(fontFamily: 'monospace', fontSize: size, color: color);

  static TextStyle monoMd({Color color = textPrimary, double size = 13}) =>
      TextStyle(fontFamily: 'monospace', fontSize: size, color: color);

  static TextStyle monoLg({Color color = textPrimary, double size = 16, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: 'monospace', fontSize: size, color: color, fontWeight: weight);

  // ── MaterialApp theme ─────────────────────────────────────────────────
  static ThemeData get materialTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: surface,
          onSurface: textPrimary,
          error: errorRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        dividerColor: border,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: accent),
          ),
          labelStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: textMuted,
          ),
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: textDim,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );
}

/// A hairline horizontal rule matching the terminal border colour.
class TDivider extends StatelessWidget {
  const TDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: T.border);
}

/// Read the current UI font size from [SettingsProvider] (watch, not read).
double uiFontSize(BuildContext context) =>
    context.watch<SettingsProvider>().uiFontSize;

/// Small monospaced status badge: green dot + label.
class StatusDot extends StatelessWidget {
  final bool active;
  final String label;
  const StatusDot({super.key, required this.active, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? T.accent : T.errorRed,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: T.monoSm(color: active ? T.accent : T.errorRed)),
        ],
      );
}
