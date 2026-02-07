import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/expense_trend.dart';

void main() {
  group('MonthlyTrend', () {
    test('creates with required fields', () {
      const trend = MonthlyTrend(
        year: 2026,
        month: 2,
        totalExpenses: 200000,
        totalIncome: 300000,
      );

      expect(trend.year, 2026);
      expect(trend.month, 2);
      expect(trend.totalExpenses, 200000);
      expect(trend.totalIncome, 300000);
    });

    test('toJson and fromJson roundtrip', () {
      const original = MonthlyTrend(
        year: 2026,
        month: 2,
        totalExpenses: 200000,
        totalIncome: 300000,
      );

      final json = original.toJson();
      final restored = MonthlyTrend.fromJson(json);
      expect(restored, original);
    });
  });

  group('ExpenseTrendData', () {
    test('creates with empty months', () {
      const data = ExpenseTrendData(months: []);
      expect(data.months, isEmpty);
    });

    test('creates with multiple months', () {
      const data = ExpenseTrendData(
        months: [
          MonthlyTrend(
            year: 2025,
            month: 9,
            totalExpenses: 180000,
            totalIncome: 280000,
          ),
          MonthlyTrend(
            year: 2025,
            month: 10,
            totalExpenses: 200000,
            totalIncome: 300000,
          ),
          MonthlyTrend(
            year: 2025,
            month: 11,
            totalExpenses: 190000,
            totalIncome: 290000,
          ),
        ],
      );

      expect(data.months, hasLength(3));
      expect(data.months.first.month, 9);
      expect(data.months.last.month, 11);
    });

    test('toJson and fromJson roundtrip', () {
      const original = ExpenseTrendData(
        months: [
          MonthlyTrend(
            year: 2025,
            month: 12,
            totalExpenses: 200000,
            totalIncome: 300000,
          ),
        ],
      );

      final json = original.toJson();
      final restored = ExpenseTrendData.fromJson(json);
      expect(restored, original);
    });
  });
}
