import 'package:flutter/material.dart';

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

  Color get _riskColor => switch (risk.toLowerCase()) {
        'high'   => T.errorRed,
        'medium' => T.warnYellow,
        _        => T.accent,
      };

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: T.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: T.border)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _riskColor)),
                const SizedBox(width: 8),
                Text('tool call approval', style: T.monoSm(color: T.textMuted)),
                const Spacer(),
                Text('risk: $risk', style: T.monoSm(color: _riskColor)),
              ]),
            ),

            // ── Command block ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('// proposed command', style: T.monoSm(color: T.textDim, size: 10)),
                  const SizedBox(height: 8),
                  Text(command, style: T.monoMd(color: T.textPrimary)),
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
                  color: T.errorRed,
                  onTap: () => Navigator.of(context).pop(false),
                  border: const Border(right: BorderSide(color: T.border)),
                ),
              ),
              // Approve
              Expanded(
                child: _DialogAction(
                  label: '[y] approve',
                  color: T.accent,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ]),
          ],
        ),
      );
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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(border: border),
          alignment: Alignment.center,
          child: Text(label, style: T.monoMd(color: color)),
        ),
      );
}
