// Wave 0 test stub for buildFlatList day-grouping behavior (D-09, B3).
//
// buildFlatList is defined in:
//   lib/features/list/presentation/widgets/list_day_group_header.dart
// TODO: created in 28-03 — that file does not exist yet; import will fail
// until the widget is created.
//
// These stubs are RED: fail('implement in 28-03') is called so they stay
// non-passing until 28-03 implements buildFlatList and the sealed item types.
//
// Run: flutter test test/unit/features/list/list_grouping_test.dart

import 'package:flutter_test/flutter_test.dart';
// TODO: created in 28-03
// import 'package:home_pocket/features/list/presentation/widgets/list_day_group_header.dart';
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
      // TODO: created in 28-03 — import and call buildFlatList when available:
      //   final items = buildFlatList(txs, SortDirection.asc);
      //   expect(items.first, isA<_HeaderItem>()
      //       .having((h) => h.date.day, 'day', equals(1)));
      //
      // Stub: RED state until 28-03 implements the function.
      // ignore: avoid_print
      print('txs count: ${txs.length}, direction: ${SortDirection.asc}');
      fail(
        'implement in 28-03 after buildFlatList is exported from '
        'list_day_group_header.dart',
      );
    });

    test(
        'groups transactions by day (desc): newest day first when SortDirection.desc',
        () {
      // TODO: created in 28-03 — import and call buildFlatList when available:
      //   final items = buildFlatList(txs, SortDirection.desc);
      //   expect(items.first, isA<_HeaderItem>()
      //       .having((h) => h.date.day, 'day', equals(2)));
      //
      // Stub: RED state until 28-03 implements the function.
      // ignore: avoid_print
      print('txs count: ${txs.length}, direction: ${SortDirection.desc}');
      fail(
        'implement in 28-03 after buildFlatList is exported from '
        'list_day_group_header.dart',
      );
    });
  });
}
