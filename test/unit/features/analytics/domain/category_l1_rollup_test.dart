import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/category_l1_rollup.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';

/// Fixtures: an L1 "Food" (l1_food, level 1) with two L2 children
/// (l2_dining, l2_grocery), plus an unrelated L1 "Transport" (l1_transport).
Category _l1(String id) => Category(
      id: id,
      name: id,
      icon: '🍔',
      color: '#000000',
      level: 1,
      createdAt: DateTime(2026, 1, 1),
    );

Category _l2(String id, String parentId) => Category(
      id: id,
      name: id,
      icon: '🍴',
      color: '#000000',
      parentId: parentId,
      level: 2,
      createdAt: DateTime(2026, 1, 1),
    );

Map<String, Category> _categoryMap(List<Category> cats) => {
      for (final c in cats) c.id: c,
    };

CategoryBreakdown _breakdown(String categoryId, int amount, int count) =>
    CategoryBreakdown(
      categoryId: categoryId,
      categoryName: categoryId,
      icon: '🍔',
      color: '#000000',
      amount: amount,
      percentage: 0,
      transactionCount: count,
    );

Transaction _tx(String id, String categoryId, int amount) => Transaction(
      id: id,
      bookId: 'book_1',
      deviceId: 'device_1',
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      ledgerType: LedgerType.daily,
      timestamp: DateTime(2026, 6, 1),
      currentHash: 'hash_$id',
      createdAt: DateTime(2026, 6, 1),
      entrySource: EntrySource.manual,
    );

void main() {
  final categoryMap = _categoryMap([
    _l1('l1_food'),
    _l2('l2_dining', 'l1_food'),
    _l2('l2_grocery', 'l1_food'),
    _l1('l1_transport'),
  ]);

  group('l1AncestorOf', () {
    test('L1-direct category returns its own id', () {
      expect(l1AncestorOf('l1_food', categoryMap), 'l1_food');
    });

    test('L2-child category returns its parent L1 id', () {
      expect(l1AncestorOf('l2_dining', categoryMap), 'l1_food');
      expect(l1AncestorOf('l2_grocery', categoryMap), 'l1_food');
    });

    test('null category id is null-safe and returns null', () {
      expect(l1AncestorOf(null, categoryMap), isNull);
    });

    test('missing category id falls back to the passed id (never throws)', () {
      expect(l1AncestorOf('unknown_id', categoryMap), 'unknown_id');
    });
  });

  group('L1CategoryRollup value equality', () {
    test('two rollups with the same fields are equal', () {
      const a = L1CategoryRollup(
        categoryId: 'l1_food',
        amount: 100,
        transactionCount: 2,
      );
      const b = L1CategoryRollup(
        categoryId: 'l1_food',
        amount: 100,
        transactionCount: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('rollups with different fields are not equal', () {
      const a = L1CategoryRollup(
        categoryId: 'l1_food',
        amount: 100,
        transactionCount: 2,
      );
      const b = L1CategoryRollup(
        categoryId: 'l1_food',
        amount: 200,
        transactionCount: 2,
      );
      expect(a, isNot(b));
    });
  });

  group('rollupCategoryBreakdownsToL1', () {
    test('two L2 siblings sum into one L1 entry (amount + count)', () {
      final result = rollupCategoryBreakdownsToL1(
        [
          _breakdown('l2_dining', 300, 2),
          _breakdown('l2_grocery', 200, 3),
        ],
        categoryMap,
      );

      expect(result, hasLength(1));
      expect(result.first.categoryId, 'l1_food');
      expect(result.first.amount, 500);
      expect(result.first.transactionCount, 5);
    });

    test('an L1-direct breakdown rolls up to itself (Pitfall 2)', () {
      final result = rollupCategoryBreakdownsToL1(
        [_breakdown('l1_food', 400, 1)],
        categoryMap,
      );

      expect(result, hasLength(1));
      expect(result.first.categoryId, 'l1_food');
      expect(result.first.amount, 400);
      expect(result.first.transactionCount, 1);
    });

    test('L1-direct + L2-child of the same L1 aggregate together', () {
      final result = rollupCategoryBreakdownsToL1(
        [
          _breakdown('l1_food', 400, 1),
          _breakdown('l2_dining', 100, 2),
        ],
        categoryMap,
      );

      expect(result, hasLength(1));
      expect(result.first.categoryId, 'l1_food');
      expect(result.first.amount, 500);
      expect(result.first.transactionCount, 3);
    });

    test('entries are sorted amount-descending', () {
      final result = rollupCategoryBreakdownsToL1(
        [
          _breakdown('l2_dining', 100, 1),
          _breakdown('l1_transport', 900, 1),
        ],
        categoryMap,
      );

      expect(result, hasLength(2));
      expect(result[0].categoryId, 'l1_transport');
      expect(result[0].amount, 900);
      expect(result[1].categoryId, 'l1_food');
      expect(result[1].amount, 100);
    });

    test('topN truncates the result (default top-10)', () {
      final cats = <Category>[];
      final breakdowns = <CategoryBreakdown>[];
      for (var i = 0; i < 15; i++) {
        final id = 'l1_cat_$i';
        cats.add(_l1(id));
        // descending amounts so we know which survive truncation
        breakdowns.add(_breakdown(id, (15 - i) * 100, 1));
      }
      final map = _categoryMap(cats);

      final defaulted = rollupCategoryBreakdownsToL1(breakdowns, map);
      expect(defaulted, hasLength(10));
      expect(defaulted.first.categoryId, 'l1_cat_0');

      final limited = rollupCategoryBreakdownsToL1(breakdowns, map, topN: 3);
      expect(limited, hasLength(3));
    });

    test('empty input yields empty output', () {
      expect(rollupCategoryBreakdownsToL1([], categoryMap), isEmpty);
    });
  });

  group('l1RollupFromTransactions', () {
    test('sums amount + count for one L1 from raw transactions', () {
      final txns = [
        _tx('t1', 'l2_dining', 300),
        _tx('t2', 'l2_grocery', 200),
        _tx('t3', 'l1_transport', 999), // unrelated L1, excluded
      ];

      final rollup = l1RollupFromTransactions(txns, categoryMap, 'l1_food');

      expect(rollup.categoryId, 'l1_food');
      expect(rollup.amount, 500);
      expect(rollup.transactionCount, 2);
    });

    test('L1-direct AND L2-child transactions are both counted (Pitfall 2)', () {
      final txns = [
        _tx('t1', 'l1_food', 400), // filed directly on L1
        _tx('t2', 'l2_dining', 100), // filed on L2 child
      ];

      final rollup = l1RollupFromTransactions(txns, categoryMap, 'l1_food');

      expect(rollup.amount, 500);
      expect(rollup.transactionCount, 2);
    });

    test('target L1 with no matching transactions returns a zero rollup', () {
      final txns = [_tx('t1', 'l1_transport', 999)];

      final rollup = l1RollupFromTransactions(txns, categoryMap, 'l1_food');

      expect(rollup.categoryId, 'l1_food');
      expect(rollup.amount, 0);
      expect(rollup.transactionCount, 0);
    });

    test('empty transactions returns a zero rollup', () {
      final rollup = l1RollupFromTransactions([], categoryMap, 'l1_food');

      expect(rollup.amount, 0);
      expect(rollup.transactionCount, 0);
    });
  });

  group('single-source contract (D-11)', () {
    test(
        'l1RollupFromTransactions and rollupCategoryBreakdownsToL1 agree '
        'on amount + count for the same L1', () {
      // Equivalent fixtures: same txns expressed as L2-grain breakdowns.
      final txns = [
        _tx('t1', 'l1_food', 400),
        _tx('t2', 'l2_dining', 300),
        _tx('t3', 'l2_grocery', 200),
      ];
      // Breakdowns built from the same data (L2-grain, as MonthlyReport does):
      // l1_food direct: 400/1, l2_dining: 300/1, l2_grocery: 200/1.
      final breakdowns = [
        _breakdown('l1_food', 400, 1),
        _breakdown('l2_dining', 300, 1),
        _breakdown('l2_grocery', 200, 1),
      ];

      final fromTxns =
          l1RollupFromTransactions(txns, categoryMap, 'l1_food');
      final fromBreakdowns = rollupCategoryBreakdownsToL1(
        breakdowns,
        categoryMap,
      ).firstWhere((r) => r.categoryId == 'l1_food');

      expect(fromTxns.amount, fromBreakdowns.amount);
      expect(fromTxns.transactionCount, fromBreakdowns.transactionCount);
      expect(fromTxns.amount, 900);
      expect(fromTxns.transactionCount, 3);
    });
  });
}
