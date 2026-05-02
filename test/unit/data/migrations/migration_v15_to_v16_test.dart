import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

const _targetSchemaVersion = 16;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('v16 soul satisfaction default migration', () {
    // D-02: default soul satisfaction moves from 5 to 2 while preserving
    // the existing inclusive CHECK(soul_satisfaction BETWEEN 1 AND 10).
    test('AppDatabase schemaVersion is 16', () {
      expect(db.schemaVersion, _targetSchemaVersion);
    });

    test('omitted soulSatisfaction stores default 2', () async {
      await _insertTransaction(db, id: 'tx_default');

      final row = await _findTransaction(db, 'tx_default');

      expect(row.soulSatisfaction, equals(2));
    });

    test('rejects soulSatisfaction above 10', () async {
      expect(
        () => _insertTransaction(
          db,
          id: 'tx_invalid_high',
          soulSatisfaction: const Value(11),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('accepts inclusive CHECK boundaries 1 and 10', () async {
      await _insertTransaction(
        db,
        id: 'tx_min',
        soulSatisfaction: const Value(1),
      );
      await _insertTransaction(
        db,
        id: 'tx_max',
        soulSatisfaction: const Value(10),
      );

      final rows = await db.select(db.transactions).get();

      expect(rows.map((row) => row.soulSatisfaction), containsAll([1, 10]));
    });
  });
}

Future<void> _insertTransaction(
  AppDatabase db, {
  required String id,
  Value<int> soulSatisfaction = const Value.absent(),
}) async {
  final now = DateTime(2026, 5, 2, 12);
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: id,
          bookId: 'book_v16',
          deviceId: 'device_v16',
          amount: 1200,
          type: 'expense',
          categoryId: 'cat_joy',
          ledgerType: 'soul',
          timestamp: now,
          currentHash: 'hash_$id',
          createdAt: now,
          soulSatisfaction: soulSatisfaction,
        ),
      );
}

Future<TransactionRow> _findTransaction(AppDatabase db, String id) {
  return (db.select(
    db.transactions,
  )..where((row) => row.id.equals(id))).getSingle();
}
