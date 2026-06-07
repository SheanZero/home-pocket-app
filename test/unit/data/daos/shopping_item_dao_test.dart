// ignore_for_file: directives_ordering
// Wave-0 DAO test scaffold — RED state expected.
// ShoppingItemDao does not exist yet; this file will fail to analyze/compile
// until Plan 05 creates lib/data/daos/shopping_item_dao.dart.
// Tests will turn GREEN after Plans 02 (table + migration), 05 (DAO).

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart'; // RED — does not exist yet

void main() {
  late AppDatabase db;
  late ShoppingItemDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = ShoppingItemDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingItemDao', () {
    test('watchByListType returns active items ordered by sort_order ASC, completed last',
        () async {
      // Insert: item B (active, sortOrder=1), item A (active, sortOrder=2), item C (completed, sortOrder=0)
      await dao.upsert(_makeItem(id: 'item_b', sortOrder: 1));
      await dao.upsert(_makeItem(id: 'item_a', sortOrder: 2));
      await dao.upsert(_makeItem(id: 'item_c', isCompleted: true, sortOrder: 0));

      // Capture the first stream emission
      final items = await dao.watchByListType('private').first;

      // DONE-02: ORDER BY is_completed ASC, sort_order ASC, created_at ASC
      // Expected: item_b (active,sort=1), item_a (active,sort=2), item_c (completed,sort=0)
      expect(items.length, 3);
      expect(items[0].id, 'item_b');
      expect(items[1].id, 'item_a');
      expect(items[2].id, 'item_c');
      expect(items[2].isCompleted, isTrue);
    });

    test('watchByListType excludes soft-deleted items', () async {
      await dao.upsert(_makeItem(id: 'item_visible'));
      await dao.upsert(_makeItem(id: 'item_deleted'));

      await dao.softDelete('item_deleted');

      final items = await dao.watchByListType('private').first;

      // Deleted item must not appear in the stream
      expect(items.any((r) => r.id == 'item_deleted'), isFalse);

      // Row still physically exists with isDeleted=true
      final row = await dao.findById('item_deleted');
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);
    });

    test('upsert inserts new row and updates existing row', () async {
      // Insert
      await dao.upsert(_makeItem(id: 'item_upsert', sortOrder: 0));
      final before = await dao.findById('item_upsert');
      expect(before, isNotNull);
      expect(before!.name, 'Item item_upsert');

      // Update same id with changed name
      await dao.upsert(
        _makeItem(id: 'item_upsert', sortOrder: 0).copyWith(
          name: const Value('Updated Name'),
        ),
      );
      final after = await dao.findById('item_upsert');
      expect(after, isNotNull);
      expect(after!.name, 'Updated Name');
    });
  });
}

ShoppingItemsCompanion _makeItem({
  required String id,
  bool isCompleted = false,
  int sortOrder = 0,
  String listType = 'private',
}) {
  return ShoppingItemsCompanion(
    id: Value(id),
    deviceId: const Value('device_1'),
    listType: Value(listType),
    name: Value('Item $id'),
    isCompleted: Value(isCompleted),
    sortOrder: Value(sortOrder),
    createdAt: Value(DateTime.now()),
  );
}
