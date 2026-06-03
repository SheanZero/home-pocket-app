import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

const _targetSchemaVersion = 16; // minimum version including v16 migration

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
    // the existing inclusive CHECK(joy_fullness BETWEEN 1 AND 10).
    test(
      'AppDatabase schemaVersion includes v16 migration and later migrations',
      () {
        expect(db.schemaVersion, greaterThanOrEqualTo(_targetSchemaVersion));
      },
    );

    test('omitted joyFullness stores default 2', () async {
      await _insertTransaction(db, id: 'tx_default');

      final row = await _findTransaction(db, 'tx_default');

      expect(row.joyFullness, equals(2));
    });

    test('rejects joyFullness above 10', () async {
      expect(
        () => _insertTransaction(
          db,
          id: 'tx_invalid_high',
          joyFullness: const Value(11),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('accepts inclusive CHECK boundaries 1 and 10', () async {
      await _insertTransaction(
        db,
        id: 'tx_min',
        joyFullness: const Value(1),
      );
      await _insertTransaction(
        db,
        id: 'tx_max',
        joyFullness: const Value(10),
      );

      final rows = await db.select(db.transactions).get();

      expect(rows.map((row) => row.joyFullness), containsAll([1, 10]));
    });
  });
}

Future<void> _insertTransaction(
  AppDatabase db, {
  required String id,
  Value<int> joyFullness = const Value.absent(),
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
          ledgerType: 'joy',
          timestamp: now,
          currentHash: 'hash_$id',
          createdAt: now,
          joyFullness: joyFullness,
        ),
      );
}

Future<TransactionRow> _findTransaction(AppDatabase db, String id) {
  return (db.select(
    db.transactions,
  )..where((row) => row.id.equals(id))).getSingle();
}
