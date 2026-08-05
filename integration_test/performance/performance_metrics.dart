/// Deterministic, dependency-free metric aggregation shared by the device
/// harness and host-side unit tests.
library;

import 'dart:convert';

class PerformanceSummary {
  const PerformanceSummary({
    required this.count,
    required this.minMs,
    required this.maxMs,
    required this.p50Ms,
    required this.p95Ms,
    required this.p99Ms,
  });

  final int count;
  final double minMs;
  final double maxMs;
  final double p50Ms;
  final double p95Ms;
  final double p99Ms;

  factory PerformanceSummary.fromSamples(Iterable<num> samples) {
    final sorted = samples.map((sample) => sample.toDouble()).toList()..sort();
    if (sorted.isEmpty) {
      throw ArgumentError.value(samples, 'samples', 'must not be empty');
    }
    return PerformanceSummary(
      count: sorted.length,
      minMs: sorted.first,
      maxMs: sorted.last,
      p50Ms: _nearestRank(sorted, 0.50),
      p95Ms: _nearestRank(sorted, 0.95),
      p99Ms: _nearestRank(sorted, 0.99),
    );
  }

  Map<String, Object> toJson() => {
    'count': count,
    'min_ms': minMs,
    'max_ms': maxMs,
    'p50_ms': p50Ms,
    'p95_ms': p95Ms,
    'p99_ms': p99Ms,
  };

  /// Nearest-rank percentile is stable for the small repeat counts used here.
  static double _nearestRank(List<double> sorted, double percentile) {
    final index = (sorted.length * percentile).ceil().clamp(1, sorted.length);
    return sorted[index - 1];
  }
}

class PerformanceReport {
  PerformanceReport({
    required this.metadata,
    required this.samples,
    this.counters = const {},
    this.observations = const {},
    this.notes = const [],
  });

  final Map<String, Object?> metadata;
  final Map<String, List<double>> samples;
  final Map<String, num> counters;
  final Map<String, Object?> observations;
  final List<String> notes;

  Map<String, Object?> toJson() {
    final metrics = <String, Object>{};
    for (final entry in samples.entries) {
      if (entry.value.isNotEmpty) {
        metrics[entry.key] = PerformanceSummary.fromSamples(
          entry.value,
        ).toJson();
      }
    }
    return {
      'schema_version': 1,
      'metadata': metadata,
      'metrics': metrics,
      'counters': counters,
      'observations': observations,
      'notes': notes,
    };
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
