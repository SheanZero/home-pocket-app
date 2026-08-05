import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/performance/performance_gate.dart';

void main() {
  test('reports baseline_required without silently passing a new device', () {
    final evaluation = evaluatePerformanceGate(
      result: const {'metrics': {}},
      thresholds: const {'schema_version': 1, 'baselines': []},
      baselineId: 'iphone-minimum',
    );

    expect(evaluation.status, 'baseline_required');
    expect(evaluation.exitCode, 0);
  });

  test('fails a reviewed p95 ceiling regression', () {
    final evaluation = evaluatePerformanceGate(
      result: const {
        'metrics': {
          'query_ms': {'p95_ms': 12},
        },
      },
      thresholds: const {
        'schema_version': 1,
        'baselines': [
          {
            'id': 'iphone-minimum',
            'metrics': {
              'query_ms': {'p95_max_ms': 10},
            },
          },
        ],
      },
      baselineId: 'iphone-minimum',
    );

    expect(evaluation.status, 'failed');
    expect(evaluation.exitCode, 1);
    expect(evaluation.failures, ['query_ms: p95 12ms exceeds 10ms']);
  });
}
