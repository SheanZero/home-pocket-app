import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';

void main() {
  group('MetricResult construction', () {
    test('constructs Empty variants as MetricResult subtypes', () {
      const intResult = Empty<int>();
      const doubleResult = Empty<double>();

      expect(intResult, isA<MetricResult<int>>());
      expect(doubleResult, isA<MetricResult<double>>());
    });
  });

  group('Value data', () {
    test('exposes data and sample size', () {
      const result = Value<int>(42, 7);

      expect(result.data, 42);
      expect(result.sampleSize, 7);
    });
  });

  group('Pattern matching', () {
    test('supports exhaustive switch over Empty and Value variants', () {
      String render(MetricResult<int> result) {
        return switch (result) {
          Empty() => 'empty',
          Value(:final data, :final sampleSize) => '$data/$sampleSize',
        };
      }

      expect(render(const Empty<int>()), 'empty');
      expect(render(const Value<int>(42, 7)), '42/7');
    });
  });

  group('Object equality', () {
    test('uses default reference equality for Empty variants', () {
      expect(const Empty<int>(), const Empty<int>());
    });
  });
}
