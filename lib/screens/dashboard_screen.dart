import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usage.dart';
import '../providers/settings_provider.dart';
import '../services/ws_service.dart';
import '../theme.dart';

/// Dashboard screen — real-time AI usage and hardware energy monitoring.
///
/// Listens to [WsUsageUpdate] events from [WsService] and renders:
///  - CPU power gauge (circular arc)
///  - Per-CLI AI usage cards (tokens in/out, cost)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UsageData? _latest;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    final ws = context.read<WsService>();
    _sub = ws.events.listen((event) {
      if (event is WsUsageUpdate) {
        setState(() => _latest = event.data);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final th = sp.nomadTheme;
    final fsz = sp.uiFontSize;

    return Scaffold(
      backgroundColor: th.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(th.labelDashboard, style: th.monoMd(color: th.accent, size: fsz)),
        actions: [
          if (_latest != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(_latest!.timestamp),
                  style: th.monoSm(color: th.textDim),
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: TDivider(),
        ),
      ),
      body: _latest == null ? _buildWaiting(th) : _buildContent(th),
    );
  }

  Widget _buildWaiting(NomadTheme th) => Center(
        child: Text(th.labelNoUsageData, style: th.monoSm(color: th.textMuted)),
      );

  Widget _buildContent(NomadTheme th) {
    final hw = _latest!.hardware;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (hw != null) ...[
          _SectionHeader(label: th.labelCpuPower, th: th),
          _PowerGaugeCard(power: hw, th: th),
          const SizedBox(height: 8),
        ],
        _SectionHeader(label: th.labelAiUsage, th: th),
        if (_latest!.aiUsage.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(th.labelNoUsageData, style: th.monoSm(color: th.textMuted)),
          )
        else
          ..._latest!.aiUsage.entries.map(
            (e) => _AiUsageCard(cli: e.key, usage: e.value, th: th),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final NomadTheme th;
  const _SectionHeader({required this.label, required this.th});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(label, style: th.monoSm(color: th.textMuted)),
      );
}

// ── Power gauge card ──────────────────────────────────────────────────────

class _PowerGaugeCard extends StatelessWidget {
  final HardwarePower power;
  final NomadTheme th;
  const _PowerGaugeCard({required this.power, required this.th});

  @override
  Widget build(BuildContext context) {
    // Clamp gauge to a 0–150 W scale.
    const maxW = 150.0;
    final fraction = (power.totalWatts / maxW).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: th.surface,
        border: Border.all(color: th.border),
      ),
      child: Row(children: [
        // Circular gauge.
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _ArcGaugePainter(
              fraction: fraction,
              color: _wattsColor(power.totalWatts, th),
              bgColor: th.border,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    power.totalWatts.toStringAsFixed(1),
                    style: th.monoMd(color: th.textPrimary, size: 14),
                  ),
                  Text(th.labelWatts, style: th.monoSm(color: th.textMuted, size: 10)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Stats column.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(
                label: 'cpu',
                value: '${power.cpuWatts.toStringAsFixed(1)} W',
                th: th,
              ),
              if (power.gpuWatts != null)
                _StatRow(
                  label: 'gpu',
                  value: '${power.gpuWatts!.toStringAsFixed(1)} W',
                  th: th,
                ),
              _StatRow(
                label: 'avg',
                value: '${power.averageSinceSession.toStringAsFixed(1)} W',
                th: th,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Color _wattsColor(double watts, NomadTheme th) {
    if (watts > 100) return th.errorRed;
    if (watts > 60) return th.warnYellow;
    return th.accent;
  }
}

// ── AI usage card ─────────────────────────────────────────────────────────

class _AiUsageCard extends StatelessWidget {
  final String cli;
  final AiUsage usage;
  final NomadTheme th;
  const _AiUsageCard({required this.cli, required this.usage, required this.th});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: th.surface,
        border: Border.all(color: th.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: th.accent)),
            const SizedBox(width: 8),
            Text(th.cliDisplayName(cli), style: th.monoMd()),
            const Spacer(),
            if (usage.cumulativeDayUsd > 0)
              Text(
                '\$${usage.cumulativeDayUsd.toStringAsFixed(4)}',
                style: th.monoSm(color: th.warnYellow),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _StatRow(
              label: th.labelTokensIn,
              value: _formatTokens(usage.inputTokens),
              th: th,
            )),
            Expanded(child: _StatRow(
              label: th.labelTokensOut,
              value: _formatTokens(usage.outputTokens),
              th: th,
            )),
          ]),
          if (usage.estimatedCostUsd > 0)
            _StatRow(
              label: th.labelCostToday,
              value: '\$${usage.estimatedCostUsd.toStringAsFixed(6)}',
              th: th,
            ),
          // Token usage bar.
          const SizedBox(height: 8),
          _TokenBar(usage: usage, th: th),
        ],
      ),
    );
  }

  String _formatTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Token usage bar ───────────────────────────────────────────────────────

class _TokenBar extends StatelessWidget {
  final AiUsage usage;
  final NomadTheme th;
  const _TokenBar({required this.usage, required this.th});

  @override
  Widget build(BuildContext context) {
    final total = usage.totalTokens;
    if (total == 0) return const SizedBox.shrink();
    final inFrac = usage.inputTokens / total;

    return ClipRRect(
      child: Row(children: [
        Expanded(
          flex: (inFrac * 100).round(),
          child: Container(height: 3, color: th.mp),
        ),
        Expanded(
          flex: ((1 - inFrac) * 100).round().clamp(0, 100),
          child: Container(height: 3, color: th.accent),
        ),
      ]),
    );
  }
}

// ── Stat row ──────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final NomadTheme th;
  const _StatRow({required this.label, required this.value, required this.th});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(children: [
          Text('$label  ', style: th.monoSm(color: th.textMuted)),
          Text(value, style: th.monoSm(color: th.textPrimary)),
        ]),
      );
}

// ── Arc gauge painter ─────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double fraction; // 0.0 – 1.0
  final Color color;
  final Color bgColor;

  const _ArcGaugePainter({
    required this.fraction,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 5.0;
    const startAngle = math.pi * 0.75;   // 135°
    const sweepTotal = math.pi * 1.5;    // 270°

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = bgColor;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepTotal, false, bgPaint,
    );
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepTotal * fraction, false, fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.fraction != fraction || old.color != color;
}
