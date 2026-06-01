import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/family_happiness.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/shared_joy_insight.dart';

void main() {
  group('MetricResult composition', () {
    test('constructs empty HappinessReport metrics', () {
      const report = HappinessReport(
        year: 2026,
        month: 5,
        bookId: 'b1',
        totalSoulTx: 0,
        avgSatisfaction: Empty<double>(),
        joyContribution: Empty<double>(),
        medianSatisfaction: Empty<double>(),
        highlightsCount: Empty<int>(),
        topJoy: Empty<BestJoyMomentRow>(),
      );

      expect(report.totalSoulTx, 0);
      expect(report.avgSatisfaction, isA<MetricResult<double>>());
      expect(report.topJoy, isA<MetricResult<BestJoyMomentRow>>());
    });
  });

  group('HappinessReport copyWith', () {
    test('round-trips populated metrics through copyWith', () {
      final report = HappinessReport(
        year: 2026,
        month: 5,
        bookId: 'b1',
        totalSoulTx: 8,
        avgSatisfaction: const Value<double>(0.75, 8),
        joyContribution: const Value<double>(24.69, 8),
        medianSatisfaction: const Value<double>(8, 8),
        highlightsCount: const Value<int>(3, 8),
        topJoy: Value<BestJoyMomentRow>(
          BestJoyMomentRow(
            transactionId: 'tx1',
            amount: 3000,
            joyFullness: 10,
            categoryId: 'gift',
            timestamp: DateTime(2026, 5, 2),
          ),
          8,
        ),
      );

      final copied = report.copyWith(avgSatisfaction: const Value(0.8, 8));

      expect(copied.avgSatisfaction, isA<Value<double>>());
      expect((copied.avgSatisfaction as Value<double>).data, 0.8);
      expect(copied.bookId, report.bookId);
    });
  });

  group('FamilyHappiness construction', () {
    test('constructs empty group-level metrics without per-member data', () {
      const report = FamilyHappiness(
        year: 2026,
        month: 5,
        totalGroupSoulTx: 0,
        familyHighlightsSum: Empty<int>(),
        sharedJoyInsight: Empty<SharedJoyInsight>(),
        medianSatisfaction: Empty<double>(),
      );

      expect(report.totalGroupSoulTx, 0);
      expect(report.familyHighlightsSum, isA<MetricResult<int>>());
      expect(report.sharedJoyInsight, isA<MetricResult<SharedJoyInsight>>());
    });
  });

  group('SharedJoyInsight tuple shape', () {
    test('constructs and exposes the anti-leaderboard tuple fields', () {
      const insight = SharedJoyInsight(
        categoryId: 'cafe',
        avgSatisfaction: 8.2,
        totalCount: 5,
      );

      expect(insight.categoryId, 'cafe');
      expect(insight.avgSatisfaction, 8.2);
      expect(insight.totalCount, 5);
    });
  });

  group('BestJoyMomentRow shape', () {
    test('constructs and exposes the top joy row fields', () {
      final timestamp = DateTime(2026, 5, 2);
      final row = BestJoyMomentRow(
        transactionId: 'tx1',
        amount: 3000,
        joyFullness: 10,
        categoryId: 'gift',
        timestamp: timestamp,
      );

      expect(row.transactionId, 'tx1');
      expect(row.amount, 3000);
      expect(row.joyFullness, 10);
      expect(row.categoryId, 'gift');
      expect(row.timestamp, timestamp);
    });
  });
}
