import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';

void main() {
  group('PerCategoryJoyBreakdownItem equality (Freezed value semantics)', () {
    test('two items with identical fields are == and share hashCode', () {
      const a = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.5,
        totalCount: 4,
      );
      const b = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.5,
        totalCount: 4,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('items differing in any single field are not equal', () {
      const base = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.5,
        totalCount: 4,
      );
      const diffId = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_b',
        avgSatisfaction: 7.5,
        totalCount: 4,
      );
      const diffSat = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.6,
        totalCount: 4,
      );
      const diffCount = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.5,
        totalCount: 5,
      );

      expect(base == diffId, isFalse);
      expect(base == diffSat, isFalse);
      expect(base == diffCount, isFalse);
    });
  });

  group('PerCategoryJoyBreakdownItem copyWith (immutability)', () {
    test('copyWith(totalCount: 99) produces a new instance with the new value '
        'and preserves other fields; original is untouched', () {
      const original = PerCategoryJoyBreakdownItem(
        categoryId: 'cat_a',
        avgSatisfaction: 7.5,
        totalCount: 4,
      );

      final copied = original.copyWith(totalCount: 99);

      expect(copied.totalCount, 99);
      expect(copied.categoryId, 'cat_a');
      expect(copied.avgSatisfaction, 7.5);
      // Original untouched.
      expect(original.totalCount, 4);
      expect(identical(copied, original), isFalse);
    });
  });

  group('PerCategoryJoyBreakdown equality across list members', () {
    test('two breakdowns with identical items + counts are equal', () {
      const items = [
        PerCategoryJoyBreakdownItem(
          categoryId: 'cat_a',
          avgSatisfaction: 8.0,
          totalCount: 5,
        ),
        PerCategoryJoyBreakdownItem(
          categoryId: 'cat_b',
          avgSatisfaction: 7.0,
          totalCount: 7,
        ),
      ];

      const a = PerCategoryJoyBreakdown(
        items: items,
        totalCount: 15,
        otherCount: 3,
        otherCategoryCount: 2,
      );
      const b = PerCategoryJoyBreakdown(
        items: items,
        totalCount: 15,
        otherCount: 3,
        otherCategoryCount: 2,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('breakdown with different otherCount is not equal', () {
      const items = <PerCategoryJoyBreakdownItem>[];
      const a = PerCategoryJoyBreakdown(
        items: items,
        totalCount: 0,
        otherCount: 0,
        otherCategoryCount: 0,
      );
      const b = PerCategoryJoyBreakdown(
        items: items,
        totalCount: 0,
        otherCount: 1,
        otherCategoryCount: 1,
      );

      expect(a == b, isFalse);
    });
  });

  group('PerCategoryJoyBreakdown empty construction', () {
    test('empty items + zero counts is allowed (use case wraps Empty separately)',
        () {
      const breakdown = PerCategoryJoyBreakdown(
        items: <PerCategoryJoyBreakdownItem>[],
        totalCount: 0,
        otherCount: 0,
        otherCategoryCount: 0,
      );

      expect(breakdown.items, isEmpty);
      expect(breakdown.totalCount, 0);
      expect(breakdown.otherCount, 0);
      expect(breakdown.otherCategoryCount, 0);
    });

    test('manual constructor allows mixed item + Other totals to add up '
        '(12 qualifying + 3 other = 15)', () {
      const items = [
        PerCategoryJoyBreakdownItem(
          categoryId: 'cat_a',
          avgSatisfaction: 8.0,
          totalCount: 5,
        ),
        PerCategoryJoyBreakdownItem(
          categoryId: 'cat_b',
          avgSatisfaction: 7.0,
          totalCount: 7,
        ),
      ];
      const breakdown = PerCategoryJoyBreakdown(
        items: items,
        totalCount: 15,
        otherCount: 3,
        otherCategoryCount: 2,
      );

      // Sanity: model carries whatever the constructor was given.
      expect(breakdown.totalCount, 15);
      expect(breakdown.otherCount, 3);
      expect(breakdown.otherCategoryCount, 2);
      expect(breakdown.items.length, 2);
    });
  });
}
