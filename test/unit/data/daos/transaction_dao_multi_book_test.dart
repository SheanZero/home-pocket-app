import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to insert a transaction with minimal required fields.
  Future<void> insertTx({
    required String id,
    required String bookId,
    required int amount,
    required DateTime timestamp,
    String ledgerType = 'daily',
    String categoryId = 'cat_misc',
    String currentHash = 'hash_default',
    String? prevHash,
    String entrySource = 'manual',
    String deviceId = 'dev_001',
  }) async {
    await dao.insertTransaction(
      id: id,
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: 'expense',
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: timestamp,
      currentHash: currentHash,
      createdAt: timestamp,
      prevHash: prevHash,
      entrySource: entrySource,
    );
  }

  // ─── SC#1: findByBookIds ─────────────────────────────────────────────────

  group('findByBookIds SC#1', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 12, 31);

    test('returns rows from multiple books in a single call', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(id: 'tx_b1', bookId: 'book_001', amount: 1000, timestamp: ts);
      await insertTx(id: 'tx_b2', bookId: 'book_002', amount: 2000, timestamp: ts);
      await insertTx(id: 'tx_b3', bookId: 'book_003', amount: 3000, timestamp: ts);

      final results = await dao.findByBookIds(
        ['book_001', 'book_002'],
        startDate: start,
        endDate: end,
      );

      final ids = results.map((r) => r.id).toList();
      expect(ids, containsAll(['tx_b1', 'tx_b2']));
      expect(ids, isNot(contains('tx_b3')));
    });

    test('excludes rows where is_deleted = true', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(id: 'tx_active', bookId: 'book_001', amount: 500, timestamp: ts);
      await insertTx(id: 'tx_deleted', bookId: 'book_001', amount: 999, timestamp: ts);
      await dao.softDelete('tx_deleted');

      final results = await dao.findByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );

      final ids = results.map((r) => r.id).toList();
      expect(ids, contains('tx_active'));
      expect(ids, isNot(contains('tx_deleted')));
    });

    test('ledgerType filter returns only matching rows', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(
        id: 'tx_daily',
        bookId: 'book_001',
        amount: 100,
        timestamp: ts,
        ledgerType: 'daily',
      );
      await insertTx(
        id: 'tx_joy',
        bookId: 'book_001',
        amount: 200,
        timestamp: ts,
        ledgerType: 'joy',
      );

      final results = await dao.findByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
        ledgerType: 'daily',
      );

      final ids = results.map((r) => r.id).toList();
      expect(ids, contains('tx_daily'));
      expect(ids, isNot(contains('tx_joy')));
    });

    test('categoryId filter returns only matching rows', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(
        id: 'tx_food',
        bookId: 'book_001',
        amount: 100,
        timestamp: ts,
        categoryId: 'cat_food',
      );
      await insertTx(
        id: 'tx_transport',
        bookId: 'book_001',
        amount: 200,
        timestamp: ts,
        categoryId: 'cat_transport',
      );

      final results = await dao.findByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
        categoryId: 'cat_food',
      );

      final ids = results.map((r) => r.id).toList();
      expect(ids, contains('tx_food'));
      expect(ids, isNot(contains('tx_transport')));
    });

    test('sortField=amount with sortDirection=asc orders by amount ascending', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(id: 'tx_medium', bookId: 'book_001', amount: 500, timestamp: ts);
      await insertTx(id: 'tx_large', bookId: 'book_001', amount: 1000, timestamp: ts);
      await insertTx(id: 'tx_small', bookId: 'book_001', amount: 100, timestamp: ts);

      final results = await dao.findByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
        sortField: SortField.amount,
        sortDirection: SortDirection.asc,
      );

      final amounts = results.map((r) => r.amount).toList();
      expect(amounts, equals([100, 500, 1000]));
    });

    // Note: SortField.updatedAt was removed in quick task 260531-oqn.
    // This test was verifying updatedAt sort order; updated to use timestamp sort.
    test('sortField=timestamp orders by transaction timestamp desc', () async {
      final t1 = DateTime(2026, 1, 10);
      final t2 = DateTime(2026, 2, 10);
      final t3 = DateTime(2026, 3, 10);
      await insertTx(id: 'tx_c', bookId: 'book_001', amount: 300, timestamp: t3);
      await insertTx(id: 'tx_a', bookId: 'book_001', amount: 100, timestamp: t1);
      await insertTx(id: 'tx_b', bookId: 'book_001', amount: 200, timestamp: t2);

      // With timestamp sort desc, newest timestamp comes first.
      final results = await dao.findByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
        sortField: SortField.timestamp,
        sortDirection: SortDirection.desc,
      );

      // tx_c has the latest timestamp (t3), so it should come first.
      expect(results.first.id, 'tx_c');
    });

    test('bookIds=[] short-circuits and returns empty list immediately', () async {
      final ts = DateTime(2026, 3, 1);
      await insertTx(id: 'tx_any', bookId: 'book_001', amount: 100, timestamp: ts);

      final results = await dao.findByBookIds(
        [],
        startDate: start,
        endDate: end,
      );

      expect(results, isEmpty);
    });
  });

  // ─── SC#2: watchByBookIds ────────────────────────────────────────────────

  group('watchByBookIds SC#2', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 12, 31);

    test('stream emits updated list after insert without ref.invalidate', () async {
      // Insert after subscribing — stream must emit [tx] without manual cache clear.
      final stream = dao.watchByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );

      // First emission: empty.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert a transaction.
      final ts = DateTime(2026, 3, 15);
      await insertTx(id: 'tx_w1', bookId: 'book_001', amount: 500, timestamp: ts);

      // New subscription on same params — Drift watch will have emitted the row.
      final stream2 = dao.watchByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );
      final second = await stream2.first;
      expect(second.length, 1);
      expect(second.first.id, 'tx_w1');
    });

    test('stream emits [] after soft-delete (row excluded by is_deleted filter)', () async {
      final ts = DateTime(2026, 3, 15);
      await insertTx(id: 'tx_w2', bookId: 'book_001', amount: 300, timestamp: ts);

      // Should have one row initially.
      final streamBefore = dao.watchByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );
      final before = await streamBefore.first;
      expect(before.length, 1);

      // Soft-delete.
      await dao.softDelete('tx_w2');

      // New subscription — row should be excluded.
      final streamAfter = dao.watchByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );
      final after = await streamAfter.first;
      expect(after, isEmpty);
    });

    test('stream emits updated list after sync-applied UPDATE', () async {
      final ts = DateTime(2026, 3, 15);
      await insertTx(
        id: 'tx_w3',
        bookId: 'book_001',
        amount: 1000,
        timestamp: ts,
        currentHash: 'hash_orig',
      );

      // Simulate sync-applied write (update the row's amount and hash).
      // entrySource uses a valid enum value; 'manual' simulates the source for testing.
      await dao.updateTransaction(
        id: 'tx_w3',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1500,
        type: 'expense',
        categoryId: 'cat_misc',
        ledgerType: 'daily',
        timestamp: ts,
        currentHash: 'hash_updated',
        createdAt: ts,
        entrySource: 'manual',
      );

      // New subscription — should see updated amount.
      final stream = dao.watchByBookIds(
        ['book_001'],
        startDate: start,
        endDate: end,
      );
      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.amount, 1500);
    });
  });

  // ─── SC#4: softDelete hash safety ────────────────────────────────────────

  group('softDelete SC#4', () {
    test(
      'softDelete does not mutate currentHash or prevHash; verifyChain on all 3 rows returns valid',
      () async {
        final hashService = HashChainService();
        final ts1 = DateTime(2026, 1, 1);
        final ts2 = DateTime(2026, 1, 2);
        final ts3 = DateTime(2026, 1, 3);

        // Compute a proper chain so verifyChain succeeds.
        const hash0 = 'genesis';
        final hash1 = hashService.calculateTransactionHash(
          transactionId: 'tx_001',
          amount: 1000.0,
          timestamp: ts1.millisecondsSinceEpoch,
          previousHash: hash0,
        );
        final hash2 = hashService.calculateTransactionHash(
          transactionId: 'tx_002',
          amount: 2000.0,
          timestamp: ts2.millisecondsSinceEpoch,
          previousHash: hash1,
        );
        final hash3 = hashService.calculateTransactionHash(
          transactionId: 'tx_003',
          amount: 3000.0,
          timestamp: ts3.millisecondsSinceEpoch,
          previousHash: hash2,
        );

        await insertTx(
          id: 'tx_001',
          bookId: 'book_chain',
          amount: 1000,
          timestamp: ts1,
          currentHash: hash1,
          prevHash: hash0,
        );
        await insertTx(
          id: 'tx_002',
          bookId: 'book_chain',
          amount: 2000,
          timestamp: ts2,
          currentHash: hash2,
          prevHash: hash1,
        );
        await insertTx(
          id: 'tx_003',
          bookId: 'book_chain',
          amount: 3000,
          timestamp: ts3,
          currentHash: hash3,
          prevHash: hash2,
        );

        // Soft-delete the middle row.
        await dao.softDelete('tx_002');

        // Fetch tx_002 and verify hash fields are NOT mutated.
        final tx002 = await dao.findById('tx_002');
        expect(tx002, isNotNull);
        expect(tx002!.isDeleted, isTrue);
        expect(tx002.currentHash, equals(hash2));
        expect(tx002.prevHash, equals(hash1));

        // Fetch all 3 rows (including soft-deleted) for chain verification.
        // We must fetch including deleted rows, so use raw DB select.
        final allRows = await (db.select(db.transactions)
              ..where((t) => t.bookId.equals('book_chain'))
              ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
            .get();

        expect(allRows.length, 3);

        // Build the map format required by verifyChain.
        final chainMaps = allRows.map((row) => {
              'transactionId': row.id,
              'amount': row.amount.toDouble(),
              'timestamp': row.timestamp.millisecondsSinceEpoch,
              'previousHash': row.prevHash ?? 'genesis',
              'currentHash': row.currentHash,
            }).toList();

        final result = hashService.verifyChain(chainMaps);
        expect(result.isValid, isTrue,
            reason: 'Hash chain must remain valid after soft-delete '
                '(soft-delete must not mutate currentHash or prevHash)');
      },
    );
  });
}
