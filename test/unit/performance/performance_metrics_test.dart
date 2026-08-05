import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/performance/performance_metrics.dart';

void main() {
  group('PerformanceSummary', () {
    test('uses deterministic nearest-rank P50/P95/P99 values', () {
      final summary = PerformanceSummary.fromSamples(
        List.generate(100, (index) => index + 1),
      );

      expect(summary.count, 100);
      expect(summary.minMs, 1);
      expect(summary.maxMs, 100);
      expect(summary.p50Ms, 50);
      expect(summary.p95Ms, 95);
      expect(summary.p99Ms, 99);
    });

    test('rejects empty sample sets', () {
      expect(
        () => PerformanceSummary.fromSamples(const []),
        throwsArgumentError,
      );
    });
  });

  test('report emits structured counters and observations', () {
    final report = PerformanceReport(
      metadata: const {'platform': 'ios'},
      samples: {
        'query_ms': [1, 2, 3],
        'empty': [],
      },
      counters: const {'total_frames': 10, 'jank_frames': 2},
      observations: const {'jank_percent': 20.0, 'frame_budget_ms': 16.67},
    ).toJson();

    expect(report['schema_version'], 1);
    expect((report['metrics'] as Map).containsKey('query_ms'), isTrue);
    expect((report['metrics'] as Map).containsKey('empty'), isFalse);
    expect(report['counters'], {'total_frames': 10, 'jank_frames': 2});
    expect(report['observations'], {
      'jank_percent': 20.0,
      'frame_budget_ms': 16.67,
    });
  });
}
