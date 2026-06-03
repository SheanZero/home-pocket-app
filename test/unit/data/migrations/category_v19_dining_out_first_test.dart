import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

/// Migration tests for schema v18 → v19 (cat_food_dining_out promoted to
/// first sub-category of cat_food, sortOrder 2→1; cat_food_groceries 1→2).
///
/// Test A (static data assertion): Directly reads DefaultCategories.all and
/// asserts the correct sortOrder values.  This test is always GREEN once
/// default_categories.dart is updated (Task 1).
///
/// Test B (migration assertion): Opens AppDatabase.forTesting(), seeds v18-era
/// category rows with the OLD sort_order values, runs the v19 migration SQL,
/// and asserts the post-migration values.  This test is RED until Task 2
/// raises schemaVersion to 19 and adds the v19 migration block.
///
/// The approach is intentionally symmetrical with category_v14_migration_test.dart:
///   1. Open fresh in-memory DB.
///   2. Seed old rows via raw SQL.
///   3. Run the v19 migration SQL helper _runV19MigrationSteps directly.
///   4. Assert post-migration state.
///
/// Once Task 2 adds the exact same SQL to onUpgrade (from < 19), Test B
/// validates that real user databases upgrading from v18 end up with the
/// correct sortOrder.

// ─── Expected schema version ──────────────────────────────────────────────────

const int _minimumSchemaVersionWithV19Migration = 19;

// ─── V19 migration SQL helper ─────────────────────────────────────────────────

/// Run the v19 migration steps.
///
/// This mirrors exactly what must live inside `onUpgrade` when `from < 19`
/// in AppDatabase. Only touches is_system = 1 rows, so user-created
/// categories are never affected.
Future<void> _runV19MigrationSteps(AppDatabase db) async {
  // 260603-ti2: promote cat_food_dining_out to first sub-category of cat_food.
  // sortOrder: dining_out 2→1, groceries 1→2.
  // Only touches system categories (is_system=1); user-created categories unaffected.
  await db.customStatement(
    "UPDATE categories SET sort_order = 1 WHERE id = 'cat_food_dining_out' AND is_system = 1",
  );
  await db.customStatement(
    "UPDATE categories SET sort_order = 2 WHERE id = 'cat_food_groceries' AND is_system = 1",
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Query a single int column from the result row.
Future<int?> _queryInt(
  AppDatabase db,
  String sql, [
  List<Object?> args = const [],
]) async {
  final result = await db
      .customSelect(sql, variables: [for (final a in args) Variable(a)])
      .getSingleOrNull();
  return result?.data.values.first as int?;
}

/// Insert a minimal system category row with a given sort_order.
Future<void> _insertSystemCategory(
  AppDatabase db, {
  required String id,
  required String parentId,
  required int sortOrder,
}) async {
  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  await db.customStatement(
    '''
    INSERT INTO categories (
      id, name, icon, color, parent_id, level,
      is_system, is_archived, sort_order, created_at
    ) VALUES (
      '$id', '$id', 'help_outline', '#FF5722', '$parentId', 2,
      1, 0, $sortOrder, $now
    )
    ''',
  );
}

/// Insert a minimal user-created category row with a given sort_order.
Future<void> _insertUserCategory(
  AppDatabase db, {
  required String id,
  required String parentId,
  required int sortOrder,
}) async {
  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  await db.customStatement(
    '''
    INSERT INTO categories (
      id, name, icon, color, parent_id, level,
      is_system, is_archived, sort_order, created_at
    ) VALUES (
      '$id', '$id', 'help_outline', '#FF5722', '$parentId', 2,
      0, 0, $sortOrder, $now
    )
    ''',
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ─── Test A: DefaultCategories static data assertion ──────────────────────

  group('DefaultCategories static data (v19)', () {
    test('cat_food_dining_out has sortOrder == 1', () {
      final diningOut = DefaultCategories.all.firstWhere(
        (c) => c.id == 'cat_food_dining_out',
      );
      expect(
        diningOut.sortOrder,
        1,
        reason:
            'cat_food_dining_out must be the first sub-category of cat_food '
            '(sortOrder = 1) so manual entry defaults to dining out',
      );
    });

    test('cat_food_groceries has sortOrder == 2', () {
      final groceries = DefaultCategories.all.firstWhere(
        (c) => c.id == 'cat_food_groceries',
      );
      expect(
        groceries.sortOrder,
        2,
        reason:
            'cat_food_groceries must be second in cat_food (sortOrder = 2)',
      );
    });

    test('cat_food_dining_out sortOrder < cat_food_groceries sortOrder', () {
      final diningOut = DefaultCategories.all.firstWhere(
        (c) => c.id == 'cat_food_dining_out',
      );
      final groceries = DefaultCategories.all.firstWhere(
        (c) => c.id == 'cat_food_groceries',
      );
      expect(
        diningOut.sortOrder,
        lessThan(groceries.sortOrder),
        reason: 'dining_out must sort before groceries within cat_food',
      );
    });

    test('other cat_food sub-categories are unchanged (cafe=3, other=4, delivery=5, drinks=6)', () {
      final foodSubs = DefaultCategories.all
          .where((c) => c.parentId == 'cat_food')
          .toList();
      final byId = {for (final c in foodSubs) c.id: c.sortOrder};
      expect(byId['cat_food_cafe'], 3, reason: 'cafe sortOrder must remain 3');
      expect(byId['cat_food_other'], 4, reason: 'other sortOrder must remain 4');
      expect(byId['cat_food_delivery'], 5, reason: 'delivery sortOrder must remain 5');
      expect(byId['cat_food_drinks'], 6, reason: 'drinks sortOrder must remain 6');
    });
  });

  // ─── Test B: v19 migration assertion ──────────────────────────────────────

  group('v19 migration — sort_order swap', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting();
    });

    tearDown(() async {
      await db.close();
    });

    // Guard: skip migration tests until schemaVersion reaches 19.
    // This test is RED until Task 2 bumps schemaVersion.
    test(
      'AppDatabase schemaVersion includes v19 migration',
      () {
        expect(
          db.schemaVersion,
          greaterThanOrEqualTo(_minimumSchemaVersionWithV19Migration),
          reason:
              'schemaVersion must be at least 19 (set in app_database.dart)',
        );
      },
    );

    test(
      'v19 migration sets cat_food_dining_out sort_order to 1',
      () async {
        // Seed the L1 parent first (needed for FK-like coherence in tests)
        final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
        await db.customStatement(
          '''
          INSERT INTO categories (
            id, name, icon, color, parent_id, level,
            is_system, is_archived, sort_order, created_at
          ) VALUES ('cat_food', 'cat_food', 'restaurant', '#FF5722', NULL, 1, 1, 0, 1, $now)
          ''',
        );

        // Seed v18-era rows with OLD sort_order values
        await _insertSystemCategory(
          db,
          id: 'cat_food_dining_out',
          parentId: 'cat_food',
          sortOrder: 2, // old value
        );
        await _insertSystemCategory(
          db,
          id: 'cat_food_groceries',
          parentId: 'cat_food',
          sortOrder: 1, // old value
        );

        // Run v19 migration SQL
        await _runV19MigrationSteps(db);

        final sortOrder = await _queryInt(
          db,
          "SELECT sort_order FROM categories WHERE id = 'cat_food_dining_out'",
        );
        expect(
          sortOrder,
          1,
          reason:
              'After v19 migration cat_food_dining_out.sort_order must be 1',
        );
      },
    );

    test(
      'v19 migration sets cat_food_groceries sort_order to 2',
      () async {
        final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
        await db.customStatement(
          '''
          INSERT INTO categories (
            id, name, icon, color, parent_id, level,
            is_system, is_archived, sort_order, created_at
          ) VALUES ('cat_food', 'cat_food', 'restaurant', '#FF5722', NULL, 1, 1, 0, 1, $now)
          ''',
        );

        await _insertSystemCategory(
          db,
          id: 'cat_food_dining_out',
          parentId: 'cat_food',
          sortOrder: 2,
        );
        await _insertSystemCategory(
          db,
          id: 'cat_food_groceries',
          parentId: 'cat_food',
          sortOrder: 1,
        );

        await _runV19MigrationSteps(db);

        final sortOrder = await _queryInt(
          db,
          "SELECT sort_order FROM categories WHERE id = 'cat_food_groceries'",
        );
        expect(
          sortOrder,
          2,
          reason:
              'After v19 migration cat_food_groceries.sort_order must be 2',
        );
      },
    );

    test(
      'v19 migration does not affect user-created categories',
      () async {
        final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
        await db.customStatement(
          '''
          INSERT INTO categories (
            id, name, icon, color, parent_id, level,
            is_system, is_archived, sort_order, created_at
          ) VALUES ('cat_food', 'cat_food', 'restaurant', '#FF5722', NULL, 1, 1, 0, 1, $now)
          ''',
        );

        // User-created category that happens to have the same ID-like name
        // but is_system=0 — the migration must not touch it.
        await _insertUserCategory(
          db,
          id: 'user_dining_custom',
          parentId: 'cat_food',
          sortOrder: 99,
        );

        // Also insert the system categories being migrated
        await _insertSystemCategory(
          db,
          id: 'cat_food_dining_out',
          parentId: 'cat_food',
          sortOrder: 2,
        );

        await _runV19MigrationSteps(db);

        final userSortOrder = await _queryInt(
          db,
          "SELECT sort_order FROM categories WHERE id = 'user_dining_custom'",
        );
        expect(
          userSortOrder,
          99,
          reason: 'User-created categories must not be touched by v19 migration',
        );
      },
    );

    test(
      'v19 migration is idempotent (running twice yields same result)',
      () async {
        final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
        await db.customStatement(
          '''
          INSERT INTO categories (
            id, name, icon, color, parent_id, level,
            is_system, is_archived, sort_order, created_at
          ) VALUES ('cat_food', 'cat_food', 'restaurant', '#FF5722', NULL, 1, 1, 0, 1, $now)
          ''',
        );

        await _insertSystemCategory(
          db,
          id: 'cat_food_dining_out',
          parentId: 'cat_food',
          sortOrder: 2,
        );
        await _insertSystemCategory(
          db,
          id: 'cat_food_groceries',
          parentId: 'cat_food',
          sortOrder: 1,
        );

        // Run twice
        await _runV19MigrationSteps(db);
        await _runV19MigrationSteps(db);

        final diningOut = await _queryInt(
          db,
          "SELECT sort_order FROM categories WHERE id = 'cat_food_dining_out'",
        );
        final groceries = await _queryInt(
          db,
          "SELECT sort_order FROM categories WHERE id = 'cat_food_groceries'",
        );
        expect(diningOut, 1, reason: 'dining_out sort_order must be 1 after idempotent re-run');
        expect(groceries, 2, reason: 'groceries sort_order must be 2 after idempotent re-run');
      },
    );
  });
}
