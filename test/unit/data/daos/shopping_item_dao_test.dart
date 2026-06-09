// ShoppingItemDao data-layer test: DONE-02 ordering, soft-delete stream
// exclusion, and upsert round-trip against an in-memory database.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';

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

    test(
        'watchByListType orders completed items by completed_at DESC '
        '(most recently completed first) while active stay by sort_order '
        '(quick-260609-pmc-06)',
        () async {
      // Two active items (sort_order 0,1) + three completed with distinct
      // completed_at. Completed must appear newest-first regardless of sort_order.
      await dao.upsert(_makeItem(id: 'active_0', sortOrder: 0));
      await dao.upsert(_makeItem(id: 'active_1', sortOrder: 1));
      await dao.upsert(_makeItem(
        id: 'done_old',
        isCompleted: true,
        sortOrder: 5,
        completedAt: DateTime(2026, 6, 9, 8),
      ));
      await dao.upsert(_makeItem(
        id: 'done_new',
        isCompleted: true,
        sortOrder: 99,
        completedAt: DateTime(2026, 6, 9, 12),
      ));
      await dao.upsert(_makeItem(
        id: 'done_mid',
        isCompleted: true,
        sortOrder: 1,
        completedAt: DateTime(2026, 6, 9, 10),
      ));

      final items = await dao.watchByListType('private').first;

      expect(
        items.map((r) => r.id).toList(),
        ['active_0', 'active_1', 'done_new', 'done_mid', 'done_old'],
      );
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

    test(
        'reorderBatch writes a contiguous 0..N-1 order so drag-to-top lands '
        'first even when items hold stale non-contiguous values '
        '(quick-260609-pmc-04)',
        () async {
      // Reproduce the bug precondition: item_a was previously "置顶" to a stale
      // sort_order = -1; b and c are 0 and 1. Display order: a, b, c.
      await dao.upsert(_makeItem(id: 'a', sortOrder: -1));
      await dao.upsert(_makeItem(id: 'b', sortOrder: 0));
      await dao.upsert(_makeItem(id: 'c', sortOrder: 1));

      // "Drag c to the top" → persist the full new order c, a, b.
      await dao.reorderBatch(['c', 'a', 'b']);

      final items = await dao.watchByListType('private').first;
      expect(items.map((r) => r.id).toList(), ['c', 'a', 'b']);
      // Contiguous 0..N-1 — no stale negative left to sabotage the next op.
      expect(items.map((r) => r.sortOrder).toList(), [0, 1, 2]);
    });

    test('reorderBatch with an empty list is a no-op', () async {
      await dao.upsert(_makeItem(id: 'solo', sortOrder: 5));
      await dao.reorderBatch(const []);
      final row = await dao.findById('solo');
      expect(row!.sortOrder, 5);
    });
  });
}

ShoppingItemsCompanion _makeItem({
  required String id,
  bool isCompleted = false,
  int sortOrder = 0,
  String listType = 'private',
  DateTime? completedAt,
  DateTime? createdAt,
}) {
  return ShoppingItemsCompanion(
    id: Value(id),
    deviceId: const Value('device_1'),
    listType: Value(listType),
    name: Value('Item $id'),
    isCompleted: Value(isCompleted),
    sortOrder: Value(sortOrder),
    completedAt: Value(completedAt),
    createdAt: Value(createdAt ?? DateTime.now()),
  );
}
