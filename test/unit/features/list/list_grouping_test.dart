// Unit tests for buildFlatList day-grouping behavior (D-09, B3).
//
// buildFlatList is defined in:
//   lib/features/list/presentation/widgets/list_day_group_header.dart
//
// Run: flutter test test/unit/features/list/list_grouping_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_day_group_header.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

// Helper: construct a minimal TaggedTransaction with a given timestamp.
TaggedTransaction _makeTx(String id, DateTime timestamp) {
  return TaggedTransaction(
    transaction: Transaction(
      id: id,
      bookId: 'book1',
      deviceId: 'device1',
      amount: 1000,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: timestamp,
      currentHash: 'stub_hash',
      createdAt: timestamp,
      entrySource: EntrySource.manual,
    ),
  );
}

void main() {
  group('buildFlatList day-grouping behavior', () {
    // Three transactions: two on day1 (older), one on day2 (newer)
    final day1 = DateTime(2026, 5, 1, 10, 0);
    final day1b = DateTime(2026, 5, 1, 15, 0);
    final day2 = DateTime(2026, 5, 2, 9, 0);

    final txs = [
      _makeTx('tx-1', day1),
      _makeTx('tx-2', day1b),
      _makeTx('tx-3', day2),
    ];

    test(
        'groups transactions by day (asc): oldest day first when SortDirection.asc',
        () {
      final items = buildFlatList(txs, SortDirection.asc);
      // asc: day1 (May 1) comes before day2 (May 2)
      expect(
        items.first,
        isA<DayHeaderItem>().having((h) => h.date.day, 'day', equals(1)),
      );
      // Should have 4 items: header(day1), tx-1, tx-2, header(day2) ... wait
      // Actually 5 items: header(day1), tx-1, tx-2, header(day2), tx-3
      expect(items.length, equals(5));
    });

    test(
        'groups transactions by day (desc): newest day first when SortDirection.desc',
        () {
      final items = buildFlatList(txs, SortDirection.desc);
      // desc: day2 (May 2) comes before day1 (May 1)
      expect(
        items.first,
        isA<DayHeaderItem>().having((h) => h.date.day, 'day', equals(2)),
      );
      expect(items.length, equals(5));
    });
  });
}
