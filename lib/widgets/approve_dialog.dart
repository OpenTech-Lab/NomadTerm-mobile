import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';

/// Shows a terminal-styled approval dialog for AI tool calls.
///
/// Returns:
///   true  — approved
///   false — denied
///   null  — dismissed
Future<bool?> showApproveDialog(
  BuildContext context, {
  required String command,
  required String risk,
}) =>
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ApproveDialog(command: command, risk: risk),
    );

class _ApproveDialog extends StatelessWidget {
  final String command;
  final String risk;

  const _ApproveDialog({required this.command, required this.risk});

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    final riskColor = switch (risk.toLowerCase()) {
      'high'   => th.errorRed,
      'medium' => th.warnYellow,
      _        => th.accent,
    };

    return Dialog(
      backgroundColor: th.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: th.border)),
            ),
            child: Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: riskColor),
              ),
              const SizedBox(width: 8),
              Text('tool call approval', style: th.monoSm(color: th.textMuted)),
              const Spacer(),
              Text('risk: $risk', style: th.monoSm(color: riskColor)),
            ]),
          ),

          // ── Command block ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: th.bg,
              border: Border.all(color: th.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('// proposed command',
                    style: th.monoSm(color: th.textDim, size: 10)),
                const SizedBox(height: 8),
                Text(command, style: th.monoMd()),
              ],
            ),
          ),

          // ── Actions ───────────────────────────────────────────────
          const TDivider(),
          Row(children: [
            // Deny
            Expanded(
              child: _DialogAction(
                label: '[n] deny',
                color: th.errorRed,
                onTap: () => Navigator.of(context).pop(false),
                border: Border(right: BorderSide(color: th.border)),
              ),
            ),
            // Approve
            Expanded(
              child: _DialogAction(
                label: '[y] approve',
                color: th.accent,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final BoxBorder? border;

  const _DialogAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(border: border),
        alignment: Alignment.center,
        child: Text(label, style: th.monoMd(color: color)),
      ),
    );
  }
}
