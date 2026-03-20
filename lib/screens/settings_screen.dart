import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';
import 'onboarding_screen.dart';

/// Settings screen — terminal-styled sliders for font sizes + theme picker.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final th = sp.nomadTheme;

    return Scaffold(
      backgroundColor: th.bg,
      appBar: AppBar(
        title: Text(th.labelSettings, style: th.monoMd()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: TDivider(),
        ),
      ),
      body: ListView(
        children: [
          // ── Theme ─────────────────────────────────────────────────
          _Section(label: '// theme'),

          _ThemeTile(
            label: 'Matrix',
            description: 'green terminal',
            active: sp.appTheme == AppTheme.matrix,
            onTap: () => sp.setTheme(AppTheme.matrix),
          ),
          const TDivider(),
          _ThemeTile(
            label: 'Pixel RPG',
            description: 'arcane void',
            active: sp.appTheme == AppTheme.pixelRpg,
            onTap: () => sp.setTheme(AppTheme.pixelRpg),
          ),
          const TDivider(),

          // ── Font size ─────────────────────────────────────────────
          _Section(label: '// font size'),

          _SliderRow(
            label: 'ui font size',
            value: sp.uiFontSize,
            min: 11,
            max: 22,
            onChanged: (v) => sp.setUiFontSize(v),
            preview: Text(
              'nomadterm',
              style: th.monoMd(color: th.accent, size: sp.uiFontSize),
            ),
          ),

          const TDivider(),

          _SliderRow(
            label: 'terminal font size',
            value: sp.termFontSize,
            min: 10,
            max: 26,
            onChanged: (v) => sp.setTermFontSize(v),
            preview: Text(
              r'$ echo hello world',
              style: th.monoMd(size: sp.termFontSize),
            ),
          ),

          const TDivider(),
          _Section(label: '// reset'),

          _ActionRow(
            label: 'restore defaults',
            onTap: () async {
              await sp.setUiFontSize(14.0);
              await sp.setTermFontSize(15.0);
            },
          ),

          const TDivider(),
          _Section(label: '// connection'),

          _ActionRow(
            label: 'disconnect  (back to onboarding)',
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (_) => false,
            ),
          ),

          const TDivider(),
        ],
      ),
    );
  }
}

// ── Private layout widgets ────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(label, style: th.monoSm(color: th.textDim, size: 11)),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final String description;
  final bool active;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.description,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? th.accent : th.textDim,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: th.monoMd(color: active ? th.accent : th.textPrimary)),
              Text(description, style: th.monoSm()),
            ],
          ),
        ]),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Widget preview;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: th.monoSm(color: th.textMuted)),
              Text(value.toStringAsFixed(1), style: th.monoSm(color: th.accent)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: th.surface,
            child: preview,
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1,
              activeTrackColor: th.accent,
              inactiveTrackColor: th.border,
              thumbColor: th.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              overlayColor: th.accent.withAlpha(30),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 2).round(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toStringAsFixed(0), style: th.monoSm(color: th.textDim, size: 10)),
              Text(max.toStringAsFixed(0), style: th.monoSm(color: th.textDim, size: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(children: [
          Text('> ', style: th.monoMd(color: th.textMuted)),
          Text(label, style: th.monoMd()),
        ]),
      ),
    );
  }
}
