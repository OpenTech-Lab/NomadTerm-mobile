import 'package:flutter/cupertino.dart';

/// Shows a Cupertino-style dialog for approving an AI tool call.
///
/// Returns:
///   true  — user approved once
///   false — user denied
///   null  — dismissed
Future<bool?> showCupertinoApproveDialog(
  BuildContext context, {
  required String command,
  required String risk,
}) =>
    showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tool Call Approval'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Risk: $risk',
              style: TextStyle(
                fontSize: 12,
                color: _riskColor(risk),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

Color _riskColor(String risk) => switch (risk.toLowerCase()) {
      'high' => CupertinoColors.systemRed,
      'medium' => CupertinoColors.systemOrange,
      _ => CupertinoColors.systemGreen,
    };
