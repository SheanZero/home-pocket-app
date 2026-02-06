import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Transactions table', () {
    test('inserts and retrieves a transaction', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_001',
              bookId: 'book_001',
              deviceId: 'dev_001',
              amount: 10000,
              type: 'expense',
              categoryId: 'cat_food',
              ledgerType: 'survival',
              timestamp: now,
              currentHash: 'hash_abc',
              createdAt: now,
            ),
          );

      final rows = await db.select(db.transactions).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'tx_001');
      expect(rows.first.amount, 10000);
      expect(rows.first.type, 'expense');
      expect(rows.first.isPrivate, false);
      expect(rows.first.isSynced, false);
      expect(rows.first.isDeleted, false);
    });

    test('queries by bookId and orders by timestamp desc', () async {
      final t1 = DateTime(2026, 2, 5);
      final t2 = DateTime(2026, 2, 6);

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_001',
              bookId: 'book_001',
              deviceId: 'dev_001',
              amount: 1000,
              type: 'expense',
              categoryId: 'cat_food',
              ledgerType: 'survival',
              timestamp: t1,
              currentHash: 'h1',
              createdAt: t1,
            ),
          );

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_002',
              bookId: 'book_001',
              deviceId: 'dev_001',
              amount: 2000,
              type: 'income',
              categoryId: 'cat_salary',
              ledgerType: 'survival',
              timestamp: t2,
              currentHash: 'h2',
              createdAt: t2,
            ),
          );

      final results =
          await (db.select(db.transactions)
                ..where((t) => t.bookId.equals('book_001'))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
              .get();

      expect(results.length, 2);
      expect(results.first.id, 'tx_002');
    });

    test('supports soft delete flag', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_001',
              bookId: 'book_001',
              deviceId: 'dev_001',
              amount: 1000,
              type: 'expense',
              categoryId: 'cat_food',
              ledgerType: 'survival',
              timestamp: now,
              currentHash: 'h1',
              createdAt: now,
            ),
          );

      await (db.update(db.transactions)..where((t) => t.id.equals('tx_001')))
          .write(const TransactionsCompanion(isDeleted: Value(true)));

      final active = await (db.select(
        db.transactions,
      )..where((t) => t.isDeleted.equals(false))).get();

      expect(active.length, 0);
    });

    test('stores nullable fields correctly', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_001',
              bookId: 'book_001',
              deviceId: 'dev_001',
              amount: 500,
              type: 'expense',
              categoryId: 'cat_food',
              ledgerType: 'survival',
              timestamp: now,
              currentHash: 'h1',
              createdAt: now,
              note: const Value('Lunch at cafe'),
              merchant: const Value('Starbucks'),
              prevHash: const Value('prev_hash_abc'),
            ),
          );

      final row = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('tx_001'))).getSingle();

      expect(row.note, 'Lunch at cafe');
      expect(row.merchant, 'Starbucks');
      expect(row.prevHash, 'prev_hash_abc');
      expect(row.photoHash, isNull);
      expect(row.metadata, isNull);
    });
  });
}
