// Data models for Usage & Energy Monitoring (doc: 02_Usage & Energy Monitoring.md).

class AiUsage {
  final String? sessionId;
  final int inputTokens;
  final int outputTokens;
  final double estimatedCostUsd;
  final double cumulativeDayUsd;

  const AiUsage({
    this.sessionId,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCostUsd,
    required this.cumulativeDayUsd,
  });

  int get totalTokens => inputTokens + outputTokens;

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
        sessionId: json['session_id'] as String?,
        inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
        outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
        estimatedCostUsd: (json['estimated_cost_usd'] as num?)?.toDouble() ?? 0.0,
        cumulativeDayUsd: (json['cumulative_day_usd'] as num?)?.toDouble() ?? 0.0,
      );
}

class HardwarePower {
  final double cpuWatts;
  final double? gpuWatts;
  final double totalWatts;
  final double averageSinceSession;

  const HardwarePower({
    required this.cpuWatts,
    this.gpuWatts,
    required this.totalWatts,
    required this.averageSinceSession,
  });

  factory HardwarePower.fromJson(Map<String, dynamic> json) => HardwarePower(
        cpuWatts: (json['cpu_watts'] as num?)?.toDouble() ?? 0.0,
        gpuWatts: (json['gpu_watts'] as num?)?.toDouble(),
        totalWatts: (json['total_watts'] as num?)?.toDouble() ?? 0.0,
        averageSinceSession: (json['average_since_session'] as num?)?.toDouble() ?? 0.0,
      );
}

class UsageData {
  final DateTime timestamp;
  final Map<String, AiUsage> aiUsage;
  final HardwarePower? hardware;

  const UsageData({
    required this.timestamp,
    required this.aiUsage,
    this.hardware,
  });

  factory UsageData.fromJson(Map<String, dynamic> json) {
    final tsMs = (json['timestamp'] as num?)?.toInt() ?? 0;
    final aiRaw = json['ai_usage'] as Map<String, dynamic>? ?? {};
    final hwRaw = json['hardware'] as Map<String, dynamic>?;

    return UsageData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
      aiUsage: aiRaw.map(
        (k, v) => MapEntry(k, AiUsage.fromJson(v as Map<String, dynamic>)),
      ),
      hardware: hwRaw != null ? HardwarePower.fromJson(hwRaw) : null,
    );
  }
}
