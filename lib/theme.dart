import 'package:flutter/material.dart';

// ── Theme enum ────────────────────────────────────────────────────────────

enum AppTheme { matrix, pixelRpg }

// ── Abstract theme data ───────────────────────────────────────────────────

abstract class NomadTheme {
  // Colours
  Color get bg;
  Color get surface;
  Color get border;
  Color get accent;
  Color get accentDim;
  Color get textPrimary;
  Color get textMuted;
  Color get textDim;
  Color get errorRed;
  Color get warnYellow;
  Color get hp;
  Color get mp;

  // Typography
  String get fontFamily;

  TextStyle monoSm({Color? color, double size = 11}) =>
      TextStyle(fontFamily: fontFamily, fontSize: size, color: color ?? textMuted);

  TextStyle monoMd({Color? color, double size = 13}) =>
      TextStyle(fontFamily: fontFamily, fontSize: size, color: color ?? textPrimary);

  TextStyle monoLg({
    Color? color,
    double size = 16,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        color: color ?? textPrimary,
        fontWeight: weight,
      );

  // Label tokens
  String get labelConnected;
  String get labelReconnecting;
  String get labelNoSessions;
  String get labelSpawnHint;
  String get labelNewSession;
  String get labelSelectCli;
  String get labelSettings;
  String get labelKill;
  String sessionCountLabel(int count);
  String cliDisplayName(String cli);

  // Bottom nav labels
  String get labelTabSessions;
  String get labelTabDashboard;

  // Dashboard labels
  String get labelDashboard;
  String get labelCpuPower;
  String get labelAiUsage;
  String get labelTokensIn;
  String get labelTokensOut;
  String get labelCostToday;
  String get labelWatts;
  String get labelNoUsageData;

  // MaterialApp theme (rebuilt whenever active theme changes)
  ThemeData get materialTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.dark(
          primary: accent,
          surface: surface,
          onSurface: textPrimary,
          error: errorRed,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        dividerColor: border,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: bg,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: accent),
          ),
          labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textMuted),
          hintStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textDim),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );
}

// ── Matrix (default) ──────────────────────────────────────────────────────

class MatrixTheme extends NomadTheme {
  static final MatrixTheme instance = MatrixTheme._();
  MatrixTheme._();

  @override Color get bg          => const Color(0xFF000000);
  @override Color get surface     => const Color(0xFF0A0A0A);
  @override Color get border      => const Color(0xFF1C1C1C);
  @override Color get accent      => const Color(0xFF00FF88);
  @override Color get accentDim   => const Color(0xFF00C86A);
  @override Color get textPrimary => const Color(0xFFEEEEEE);
  @override Color get textMuted   => const Color(0xFF555555);
  @override Color get textDim     => const Color(0xFF2C2C2C);
  @override Color get errorRed    => const Color(0xFFFF3B3B);
  @override Color get warnYellow  => const Color(0xFFFFB300);
  @override Color get hp          => const Color(0xFFFF3B3B);
  @override Color get mp          => const Color(0xFF4488FF);
  @override String get fontFamily => 'monospace';

  @override String get labelConnected    => 'connected';
  @override String get labelReconnecting => 'reconnecting';
  @override String get labelNoSessions   => 'no active sessions';
  @override String get labelSpawnHint    => 'tap + to spawn an ai cli';
  @override String get labelNewSession   => 'new session';
  @override String get labelSelectCli    => 'select ai cli';
  @override String get labelSettings     => 'settings';
  @override String get labelKill         => 'kill';
  @override String sessionCountLabel(int count) =>
      '$count session${count == 1 ? '' : 's'}';
  @override String cliDisplayName(String cli) => cli;

  @override String get labelTabSessions   => 'sessions';
  @override String get labelTabDashboard  => 'dashboard';
  @override String get labelDashboard     => 'dashboard';
  @override String get labelCpuPower      => 'cpu power';
  @override String get labelAiUsage       => 'ai usage';
  @override String get labelTokensIn      => 'in';
  @override String get labelTokensOut     => 'out';
  @override String get labelCostToday     => 'cost today';
  @override String get labelWatts         => 'W';
  @override String get labelNoUsageData   => 'waiting for usage data...';
}

// ── Pixel RPG ─────────────────────────────────────────────────────────────

class PixelRpgTheme extends NomadTheme {
  static final PixelRpgTheme instance = PixelRpgTheme._();
  PixelRpgTheme._();

  @override Color get bg          => const Color(0xFF0D0014);
  @override Color get surface     => const Color(0xFF1A0A2E);
  @override Color get border      => const Color(0xFF3D1F6B);
  @override Color get accent      => const Color(0xFFC084FC);
  @override Color get accentDim   => const Color(0xFF7C3AED);
  @override Color get textPrimary => const Color(0xFFF0E6FF);
  @override Color get textMuted   => const Color(0xFF8B7AAE);
  @override Color get textDim     => const Color(0xFF2D1F45);
  @override Color get errorRed    => const Color(0xFFFF4444);
  @override Color get warnYellow  => const Color(0xFFFFB800);
  @override Color get hp          => const Color(0xFFFF4444);
  @override Color get mp          => const Color(0xFF4488FF);
  @override String get fontFamily => 'monospace';

  @override String get labelConnected    => 'HP: MAX';
  @override String get labelReconnecting => 'HP: LOW';
  @override String get labelNoSessions   => '// NO PARTY MEMBERS';
  @override String get labelSpawnHint    => '[ + ] summon an agent';
  @override String get labelNewSession   => 'summon';
  @override String get labelSelectCli    => '// choose class';
  @override String get labelSettings     => '// config';
  @override String get labelKill         => 'exile';
  @override String sessionCountLabel(int count) => '$count MP';
  @override String cliDisplayName(String cli) => switch (cli) {
        'claude'  => '[MGR] $cli',
        'codex'   => '[WIZ] $cli',
        'copilot' => '[RGE] $cli',
        'gemini'  => '[ORC] $cli',
        _         => cli,
      };

  @override String get labelTabSessions   => '// party';
  @override String get labelTabDashboard  => '// status';
  @override String get labelDashboard     => '// status screen';
  @override String get labelCpuPower      => '// cpu draw';
  @override String get labelAiUsage       => '// party stats';
  @override String get labelTokensIn      => 'MP_IN';
  @override String get labelTokensOut     => 'MP_OUT';
  @override String get labelCostToday     => 'GOLD/DAY';
  @override String get labelWatts         => 'PWR';
  @override String get labelNoUsageData   => '// awaiting signal...';
}

// ── Shared widgets ────────────────────────────────────────────────────────

/// Hairline divider — reads border colour from MaterialApp theme.
class TDivider extends StatelessWidget {
  const TDivider({super.key});
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      );
}

/// Small status badge — reads colours from MaterialApp colorScheme.
class StatusDot extends StatelessWidget {
  final bool active;
  final String label;
  const StatusDot({super.key, required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color)),
      ],
    );
  }
}
