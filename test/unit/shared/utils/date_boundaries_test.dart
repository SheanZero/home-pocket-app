import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/date_boundaries.dart';

void main() {
  group('DateBoundaries.monthRange', () {
    test('May start is first day at 00:00:00', () {
      final range = DateBoundaries.monthRange(2026, 5);
      expect(range.start, equals(DateTime(2026, 5, 1)));
    });

    test('May end is last day at 23:59:59', () {
      final range = DateBoundaries.monthRange(2026, 5);
      expect(range.end, equals(DateTime(2026, 5, 31, 23, 59, 59)));
    });

    test('Feb non-leap end day is 28', () {
      final range = DateBoundaries.monthRange(2026, 2);
      expect(range.end.day, equals(28));
    });

    test('Dec year-boundary: end month is 12 and day is 31', () {
      final range = DateBoundaries.monthRange(2026, 12);
      expect(range.end.month, equals(12));
      expect(range.end.day, equals(31));
    });
  });

  group('DateBoundaries.dayRange', () {
    test('start strips time component to 00:00:00', () {
      final range = DateBoundaries.dayRange(DateTime(2026, 5, 15, 14, 30));
      expect(range.start, equals(DateTime(2026, 5, 15)));
    });

    test('end is same day at 23:59:59', () {
      final range = DateBoundaries.dayRange(DateTime(2026, 5, 15));
      expect(range.end, equals(DateTime(2026, 5, 15, 23, 59, 59)));
    });
  });
}
