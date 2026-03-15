import 'package:drift/drift.dart' show Value;
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

  group('Books table', () {
    test('inserts and retrieves a book', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: 'book_001',
              name: 'My Book',
              currency: 'JPY',
              deviceId: 'dev_001',
              createdAt: now,
            ),
          );

      final rows = await db.select(db.books).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'book_001');
      expect(rows.first.name, 'My Book');
      expect(rows.first.currency, 'JPY');
      expect(rows.first.isArchived, false);
      expect(rows.first.isShadow, false);
      expect(rows.first.groupId, isNull);
      expect(rows.first.ownerDeviceId, isNull);
      expect(rows.first.ownerDeviceName, isNull);
      expect(rows.first.transactionCount, 0);
    });

    test('stores shadow book fields', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: 'shadow_001',
              name: 'Partner Records',
              currency: 'JPY',
              deviceId: 'partner-device',
              createdAt: now,
              isShadow: const Value(true),
              groupId: const Value('group-1'),
              ownerDeviceId: const Value('partner-device'),
              ownerDeviceName: const Value('Partner Phone'),
            ),
          );

      final rows = await db.select(db.books).get();
      expect(rows.single.isShadow, true);
      expect(rows.single.groupId, 'group-1');
      expect(rows.single.ownerDeviceId, 'partner-device');
      expect(rows.single.ownerDeviceName, 'Partner Phone');
    });

    test('updates a book', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: 'book_001',
              name: 'My Book',
              currency: 'JPY',
              deviceId: 'dev_001',
              createdAt: now,
            ),
          );

      await (db.update(db.books)..where((t) => t.id.equals('book_001'))).write(
        const BooksCompanion(
          name: Value('Updated Book'),
          isArchived: Value(true),
        ),
      );

      final rows = await db.select(db.books).get();
      expect(rows.first.name, 'Updated Book');
      expect(rows.first.isArchived, true);
    });

    test('enforces primary key uniqueness', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: 'book_001',
              name: 'Book 1',
              currency: 'JPY',
              deviceId: 'dev_001',
              createdAt: now,
            ),
          );

      expect(
        () => db
            .into(db.books)
            .insert(
              BooksCompanion.insert(
                id: 'book_001',
                name: 'Book 2',
                currency: 'USD',
                deviceId: 'dev_002',
                createdAt: now,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
