import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';

void main() {
  group('TimeWindow.range', () {
    test('week returns Monday start and Sunday inclusive end', () {
      final range = TimeWindow.week(
        mondayStart: DateTime(2026, 5, 11),
      ).range;

      expect(range.start, DateTime(2026, 5, 11));
      expect(range.end, DateTime(2026, 5, 17, 23, 59, 59));
    });

    test('month returns first day and inclusive last day', () {
      final range = TimeWindow.month(year: 2026, month: 5).range;

      expect(range.start, DateTime(2026, 5));
      expect(range.end, DateTime(2026, 5, 31, 23, 59, 59));
    });

    test('month handles February in a non-leap year', () {
      final range = TimeWindow.month(year: 2025, month: 2).range;

      expect(range.start, DateTime(2025, 2));
      expect(range.end, DateTime(2025, 2, 28, 23, 59, 59));
    });

    test('month handles February in a leap year', () {
      final range = TimeWindow.month(year: 2024, month: 2).range;

      expect(range.start, DateTime(2024, 2));
      expect(range.end, DateTime(2024, 2, 29, 23, 59, 59));
    });

    test('quarter Q1 returns January through March', () {
      final range = TimeWindow.quarter(year: 2026, quarter: 1).range;

      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2026, 3, 31, 23, 59, 59));
    });

    test('quarter Q2 returns April through June', () {
      final range = TimeWindow.quarter(year: 2026, quarter: 2).range;

      expect(range.start, DateTime(2026, 4));
      expect(range.end, DateTime(2026, 6, 30, 23, 59, 59));
    });

    test('quarter Q3 returns July through September', () {
      final range = TimeWindow.quarter(year: 2026, quarter: 3).range;

      expect(range.start, DateTime(2026, 7));
      expect(range.end, DateTime(2026, 9, 30, 23, 59, 59));
    });

    test('quarter Q4 returns October through December', () {
      final range = TimeWindow.quarter(year: 2026, quarter: 4).range;

      expect(range.start, DateTime(2026, 10));
      expect(range.end, DateTime(2026, 12, 31, 23, 59, 59));
    });

    test('year returns January first through December thirty-first', () {
      final range = TimeWindow.year(year: 2026).range;

      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2026, 12, 31, 23, 59, 59));
    });

    test('custom strips input time components into inclusive dates', () {
      final range = TimeWindow.custom(
        startDate: DateTime(2026, 3, 15, 8, 30),
        endDate: DateTime(2026, 7, 20, 12, 45),
      ).range;

      expect(range.start, DateTime(2026, 3, 15));
      expect(range.end, DateTime(2026, 7, 20, 23, 59, 59));
    });
  });

  group('TimeWindow equality', () {
    test('same variant with same values is equal with matching hashCode', () {
      const first = TimeWindow.month(year: 2026, month: 5);
      const second = TimeWindow.month(year: 2026, month: 5);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different variants are not equal', () {
      const month = TimeWindow.month(year: 2026, month: 5);
      const year = TimeWindow.year(year: 2026);

      expect(month, isNot(year));
    });
  });

  test('sealed pattern matching covers every variant without default', () {
    String label(TimeWindow window) => switch (window) {
      WeekWindow() => 'week',
      MonthWindow() => 'month',
      QuarterWindow() => 'quarter',
      YearWindow() => 'year',
      CustomWindow() => 'custom',
    };

    expect(
      [
        label(TimeWindow.week(mondayStart: DateTime(2026, 5, 11))),
        label(const TimeWindow.month(year: 2026, month: 5)),
        label(const TimeWindow.quarter(year: 2026, quarter: 2)),
        label(const TimeWindow.year(year: 2026)),
        label(
          TimeWindow.custom(
            startDate: DateTime(2026, 5),
            endDate: DateTime(2026, 5, 31),
          ),
        ),
      ],
      ['week', 'month', 'quarter', 'year', 'custom'],
    );
  });
}
