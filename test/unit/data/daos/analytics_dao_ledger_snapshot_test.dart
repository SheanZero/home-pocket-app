import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;

  final windowStart = DateTime(2026, 5);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    db = AppDatabase.forTesting();
    dao = AnalyticsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTx({
    required String id,
    String bookId = 'book_joy',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_joy',
    String ledgerType = 'soul',
    DateTime? timestamp,
    bool isDeleted = false,
    int soulSatisfaction = 6,
  }) {
    final effectiveTimestamp = timestamp ?? DateTime(2026, 5, 10, 12);
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: 'device_1',
            amount: amount,
            type: type,
            categoryId: categoryId,
            ledgerType: ledgerType,
            timestamp: effectiveTimestamp,
            currentHash: 'hash_$id',
            createdAt: effectiveTimestamp,
            isDeleted: Value(isDeleted),
            soulSatisfaction: Value(soulSatisfaction),
          ),
        );
  }

  Map<String, LedgerSnapshotRow> indexByLedger(List<LedgerSnapshotRow> rows) {
    return {for (final row in rows) row.ledgerType: row};
  }

  group('getLedgerSnapshot (single book)', () {
    test('per-ledger COUNT + SUM correctness', () async {
      // Soul: 3 rows summing to 600
      await seedTx(id: 'soul_1', amount: 100, ledgerType: 'soul');
      await seedTx(id: 'soul_2', amount: 200, ledgerType: 'soul');
      await seedTx(id: 'soul_3', amount: 300, ledgerType: 'soul');
      // Survival: 2 rows summing to 900
      await seedTx(id: 'surv_1', amount: 400, ledgerType: 'survival');
      await seedTx(id: 'surv_2', amount: 500, ledgerType: 'survival');

      final rows = await dao.getLedgerSnapshot(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isA<List<LedgerSnapshotRow>>());
      expect(rows, hasLength(2));

      final indexed = indexByLedger(rows);
      expect(indexed['soul']!.totalAmount, 600);
      expect(indexed['soul']!.entryCount, 3);
      expect(indexed['survival']!.totalAmount, 900);
      expect(indexed['survival']!.entryCount, 2);
    });

    test('excludes soft-deleted rows', () async {
      await seedTx(id: 'soul_a', amount: 100, ledgerType: 'soul');
      await seedTx(
        id: 'soul_del',
        amount: 999,
        ledgerType: 'soul',
        isDeleted: true,
      );

      final rows = await dao.getLedgerSnapshot(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      final indexed = indexByLedger(rows);
      expect(indexed['soul']!.totalAmount, 100);
      expect(indexed['soul']!.entryCount, 1);
    });

    test('excludes income rows', () async {
      await seedTx(id: 'soul_a', amount: 100, ledgerType: 'soul');
      await seedTx(
        id: 'income_a',
        amount: 9999,
        ledgerType: 'soul',
        type: 'income',
      );

      final rows = await dao.getLedgerSnapshot(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      final indexed = indexByLedger(rows);
      expect(indexed['soul']!.totalAmount, 100);
      expect(indexed['soul']!.entryCount, 1);
    });

    test('respects window boundaries', () async {
      // Inside
      await seedTx(
        id: 'inside_start',
        amount: 100,
        ledgerType: 'soul',
        timestamp: windowStart,
      );
      await seedTx(
        id: 'inside_end',
        amount: 200,
        ledgerType: 'soul',
        timestamp: windowEnd,
      );
      // Outside
      await seedTx(
        id: 'before',
        amount: 999,
        ledgerType: 'soul',
        timestamp: DateTime(2026, 4, 30),
      );
      await seedTx(
        id: 'after',
        amount: 999,
        ledgerType: 'soul',
        timestamp: DateTime(2026, 6, 1),
      );

      final rows = await dao.getLedgerSnapshot(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      final indexed = indexByLedger(rows);
      expect(indexed['soul']!.totalAmount, 300);
      expect(indexed['soul']!.entryCount, 2);
    });

    test('empty window → empty list', () async {
      final rows = await dao.getLedgerSnapshot(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isEmpty);
    });
  });

  group('getLedgerSnapshotAcrossBooks (family pool)', () {
    test('pools rows across books per ledger_type (no GROUP BY book_id)', () async {
      // bookA: 2 soul rows summing to 300
      await seedTx(id: 'a_soul_1', bookId: 'book_a', amount: 100, ledgerType: 'soul');
      await seedTx(id: 'a_soul_2', bookId: 'book_a', amount: 200, ledgerType: 'soul');
      // bookB: 1 soul row + 1 survival row
      await seedTx(id: 'b_soul_1', bookId: 'book_b', amount: 50, ledgerType: 'soul');
      await seedTx(id: 'b_surv_1', bookId: 'book_b', amount: 700, ledgerType: 'survival');

      final rows = await dao.getLedgerSnapshotAcrossBooks(
        bookIds: ['book_a', 'book_b'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      // Pool: one row per ledger_type — soul (count=3, total=350), survival (count=1, total=700)
      expect(rows, hasLength(2));
      final indexed = indexByLedger(rows);
      expect(indexed['soul']!.entryCount, 3);
      expect(indexed['soul']!.totalAmount, 350);
      expect(indexed['survival']!.entryCount, 1);
      expect(indexed['survival']!.totalAmount, 700);
    });

    test('empty bookIds → empty list, no DB call', () async {
      // Seed data that would otherwise match — verify NOT returned
      await seedTx(id: 'soul_a', amount: 1000, ledgerType: 'soul');

      final rows = await dao.getLedgerSnapshotAcrossBooks(
        bookIds: const [],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isEmpty);
    });
  });
}
