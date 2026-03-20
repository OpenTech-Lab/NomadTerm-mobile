import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';

/// Settings screen — terminal-styled sliders for font sizes.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        title: Text('settings', style: T.monoMd()),
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
          _Section(label: '// font size'),

          _SliderRow(
            label: 'ui font size',
            value: sp.uiFontSize,
            min: 11,
            max: 22,
            onChanged: (v) => sp.setUiFontSize(v),
            preview: Text(
              'nomadterm',
              style: T.monoMd(color: T.accent, size: sp.uiFontSize),
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
              style: T.monoMd(size: sp.termFontSize),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(label, style: T.monoSm(color: T.textDim, size: 11)),
      );
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + current value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: T.monoSm(color: T.textMuted)),
                Text(
                  value.toStringAsFixed(1),
                  style: T.monoSm(color: T.accent),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: T.surface,
              child: preview,
            ),
            const SizedBox(height: 10),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1,
                activeTrackColor: T.accent,
                inactiveTrackColor: T.border,
                thumbColor: T.accent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                overlayColor: T.accent.withAlpha(30),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) * 2).round(), // 0.5 steps
                onChanged: onChanged,
              ),
            ),

            // Min / Max labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(min.toStringAsFixed(0), style: T.monoSm(color: T.textDim, size: 10)),
                Text(max.toStringAsFixed(0), style: T.monoSm(color: T.textDim, size: 10)),
              ],
            ),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(children: [
            Text('> ', style: T.monoMd(color: T.textMuted)),
            Text(label, style: T.monoMd(color: T.textPrimary)),
          ]),
        ),
      );
}
