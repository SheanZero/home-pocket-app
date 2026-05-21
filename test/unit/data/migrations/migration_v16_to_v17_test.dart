import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

const _targetSchemaVersion = 17;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('v17 entry_source column migration', () {
    test('AppDatabase schemaVersion is 17', () {
      expect(db.schemaVersion, _targetSchemaVersion);
    });

    test('omitted entry_source stores DEFAULT manual', () async {
      await _insertTransaction(db, id: 'tx_default');

      final row = await _findTransaction(db, 'tx_default');

      expect(row.entrySource, equals('manual'));
    });

    test('accepts voice', () async {
      await _insertTransaction(
        db,
        id: 'tx_voice',
        entrySource: const Value('voice'),
      );

      final row = await _findTransaction(db, 'tx_voice');

      expect(row.entrySource, equals('voice'));
    });

    test('accepts ocr (reserved, no live use in v1.2)', () async {
      await _insertTransaction(
        db,
        id: 'tx_ocr',
        entrySource: const Value('ocr'),
      );

      final row = await _findTransaction(db, 'tx_ocr');

      expect(row.entrySource, equals('ocr'));
    });

    test('rejects invalid entry_source via CHECK constraint', () async {
      expect(
        () => _insertTransaction(
          db,
          id: 'tx_invalid',
          entrySource: const Value('keyboard'),
        ),
        throwsA(isA<Object>()),
      );
    });
  });
}

Future<void> _insertTransaction(
  AppDatabase db, {
  required String id,
  Value<String> entrySource = const Value.absent(),
}) async {
  final now = DateTime(2026, 5, 21, 12);
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: id,
          bookId: 'book_v17',
          deviceId: 'device_v17',
          amount: 1200,
          type: 'expense',
          categoryId: 'cat_joy',
          ledgerType: 'soul',
          timestamp: now,
          currentHash: 'hash_$id',
          createdAt: now,
          entrySource: entrySource,
        ),
      );
}

Future<TransactionRow> _findTransaction(AppDatabase db, String id) {
  return (db.select(
    db.transactions,
  )..where((row) => row.id.equals(id))).getSingle();
}
