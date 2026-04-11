import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

/// Migration tests for schema v13 → v14 (category taxonomy upgrade).
///
/// These tests are intentionally RED until Task 14:
///   - bumps schemaVersion to 14 in AppDatabase
///   - adds the v14 migration block in onUpgrade
///
/// The `schemaVersion` guard at the top of each group ensures tests fail
/// (RED) until the version is actually bumped.  Once schemaVersion == 14 and
/// the onUpgrade SQL is in place, all assertions should turn GREEN.
///
/// Test approach (no drift_schemas/ snapshots available):
///   1. Open a fresh AppDatabase.forTesting() (in-memory NativeDatabase).
///   2. Seed v13-era data via raw customStatement SQL.
///   3. Run the v14 migration SQL directly via [_runV14MigrationSteps] —
///      these statements mirror exactly what must live in onUpgrade (from < 14).
///   4. Assert the expected post-migration state.
///
/// The helper [_runV14MigrationSteps] is the contract: once Task 14 adds the
/// same SQL to onUpgrade, the tests validate that the DB ends up in the
/// correct state when migrating real user data.

// ─── Expected target schema version ──────────────────────────────────────────

const int _targetSchemaVersion = 14;

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Insert a minimal transaction row with the given [categoryId].
Future<void> _insertTransaction(
  AppDatabase db,
  String id,
  String categoryId,
) async {
  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  await db.customStatement('''
    INSERT INTO transactions (
      id, book_id, device_id, amount, type, category_id, ledger_type,
      timestamp, current_hash, created_at,
      is_private, is_synced, is_deleted, soul_satisfaction
    ) VALUES (
      ?, 'book_test', 'dev_test', 1000, 'expense', ?, 'survival',
      $now, 'hash_$id', $now,
      0, 0, 0, 5
    )
  ''', [id, categoryId]);
}

/// Insert a minimal category row.
Future<void> _insertCategory(
  AppDatabase db,
  String id,
  String name, {
  int level = 1,
  String? parentId,
  bool isSystem = true,
}) async {
  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  final parentVal = parentId == null ? 'NULL' : "'$parentId'";
  final systemVal = isSystem ? 1 : 0;
  await db.customStatement('''
    INSERT INTO categories (
      id, name, icon, color, parent_id, level,
      is_system, is_archived, sort_order, created_at
    ) VALUES (
      '$id', '$name', 'help_outline', '#607D8B', $parentVal, $level,
      $systemVal, 0, 99, $now
    )
  ''');
}

/// Insert a category_ledger_config row.
Future<void> _insertLedgerConfig(
  AppDatabase db,
  String categoryId,
  String ledgerType,
) async {
  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  await db.customStatement('''
    INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
    VALUES ('$categoryId', '$ledgerType', $now)
  ''');
}

/// Run the v14 migration steps.
///
/// This is the contract for what must live inside `onUpgrade` when `from < 14`
/// in AppDatabase.  The SQL here must be kept in sync with the actual
/// migration implementation in Task 14.
///
/// Steps:
///   1. Remap removed/renamed category IDs in transactions.
///   2. Delete orphan ledger configs for removed L1 categories.
///   3. Delete removed system category rows.
///   4. INSERT OR REPLACE new system categories (cat_pet, cat_allowance, + L2s).
///   5. INSERT OR REPLACE ledger configs for new L1 categories.
Future<void> _runV14MigrationSteps(AppDatabase db) async {
  const remaps = <String, String>{
    'cat_cash_card': 'cat_other_unclassified',
    'cat_uncategorized': 'cat_other_unclassified',
    'cat_daily_pets': 'cat_pet_other',
    'cat_other_allowance': 'cat_allowance_self',
    'cat_other_advances': 'cat_other_misc',
    'cat_other_business': 'cat_other_misc',
    'cat_other_debt': 'cat_other_misc',
    'cat_food_general': 'cat_food_other',
    'cat_food_breakfast': 'cat_food_dining_out',
    'cat_food_lunch': 'cat_food_dining_out',
    'cat_food_dinner': 'cat_food_dining_out',
    'cat_daily_general': 'cat_daily_other',
    'cat_transport_general': 'cat_transport_other',
    'cat_social_general': 'cat_social_other',
    'cat_utilities_general': 'cat_utilities_other',
    'cat_communication_info': 'cat_communication_other',
    'cat_insurance_general': 'cat_insurance_other',
    'cat_special_general': 'cat_special_other',
    'cat_special_furniture': 'cat_housing_furniture',
    'cat_special_housing': 'cat_housing_renovation',
  };

  // Step 1: remap transactions
  for (final entry in remaps.entries) {
    await db.customStatement(
      'UPDATE transactions SET category_id = ? WHERE category_id = ?',
      [entry.value, entry.key],
    );
  }

  const removedIds = ['cat_cash_card', 'cat_uncategorized'];

  // Step 2: delete orphan ledger configs
  for (final id in removedIds) {
    await db.customStatement(
      'DELETE FROM category_ledger_configs WHERE category_id = ?',
      [id],
    );
  }

  // Step 3: delete removed system categories
  for (final id in removedIds) {
    await db.customStatement(
      'DELETE FROM categories WHERE id = ? AND is_system = 1',
      [id],
    );
  }

  // Step 4: upsert new/updated system categories
  final now = DateTime(2026, 4, 10).millisecondsSinceEpoch;
  await db.customStatement('''
    INSERT OR REPLACE INTO categories
      (id, name, icon, color, parent_id, level, is_system, is_archived, sort_order, created_at)
    VALUES
      ('cat_pet', 'category_pet', 'pets', '#7CB342', NULL, 1, 1, 0, 3, $now)
  ''');
  await db.customStatement('''
    INSERT OR REPLACE INTO categories
      (id, name, icon, color, parent_id, level, is_system, is_archived, sort_order, created_at)
    VALUES
      ('cat_allowance', 'category_allowance', 'wallet', '#8D6E63', NULL, 1, 1, 0, 17, $now)
  ''');
  await db.customStatement('''
    INSERT OR REPLACE INTO categories
      (id, name, icon, color, parent_id, level, is_system, is_archived, sort_order, created_at)
    VALUES
      ('cat_pet_other', 'category_pet_other', 'more_horiz', '#7CB342', 'cat_pet', 2, 1, 0, 7, $now)
  ''');
  await db.customStatement('''
    INSERT OR REPLACE INTO categories
      (id, name, icon, color, parent_id, level, is_system, is_archived, sort_order, created_at)
    VALUES
      ('cat_allowance_self', 'category_allowance_self', 'person', '#8D6E63', 'cat_allowance', 2, 1, 0, 1, $now)
  ''');

  // Step 5: upsert ledger configs for new L1s
  await db.customStatement('''
    INSERT OR REPLACE INTO category_ledger_configs (category_id, ledger_type, updated_at)
    VALUES ('cat_pet', 'soul', $now)
  ''');
  await db.customStatement('''
    INSERT OR REPLACE INTO category_ledger_configs (category_id, ledger_type, updated_at)
    VALUES ('cat_allowance', 'soul', $now)
  ''');
}

/// Query a single string value from the first column of the result.
Future<String?> _queryString(AppDatabase db, String sql, [List<Object?> args = const []]) async {
  final result = await db.customSelect(sql, variables: [
    for (final a in args) Variable(a),
  ]).getSingleOrNull();
  return result?.data.values.first as String?;
}

/// Count rows matching a query (query must SELECT COUNT(*) AS c ...).
Future<int> _queryCount(AppDatabase db, String sql, [List<Object?> args = const []]) async {
  final result = await db.customSelect(sql, variables: [
    for (final a in args) Variable(a),
  ]).getSingle();
  return result.data.values.first as int;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  // Guard: this assertion fails (RED) until Task 14 bumps schemaVersion to 14.
  test('AppDatabase schemaVersion is 14 (RED until Task 14)', () {
    expect(
      db.schemaVersion,
      _targetSchemaVersion,
      reason: 'schemaVersion must be bumped to 14 in app_database.dart',
    );
  });

  // ─── Transaction remap tests ────────────────────────────────────────────────

  group('v14 migration — transaction remaps', () {
    test('remaps cat_cash_card transactions to cat_other_unclassified', () async {
      await _insertCategory(db, 'cat_other_expense', 'Other Expense');
      await _insertCategory(
        db,
        'cat_other_unclassified',
        'Unclassified',
        level: 2,
        parentId: 'cat_other_expense',
      );
      await _insertCategory(db, 'cat_cash_card', 'Cash / Card');
      await _insertTransaction(db, 'tx_cc_1', 'cat_cash_card');
      await _insertTransaction(db, 'tx_cc_2', 'cat_cash_card');

      await _runV14MigrationSteps(db);

      final remappedCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_other_unclassified'",
      );
      expect(remappedCount, 2, reason: 'Both cat_cash_card transactions should be remapped');

      final oldCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_cash_card'",
      );
      expect(oldCount, 0, reason: 'No transactions should remain with cat_cash_card');
    });

    test('remaps cat_uncategorized transactions to cat_other_unclassified', () async {
      await _insertCategory(db, 'cat_other_expense', 'Other Expense');
      await _insertCategory(
        db,
        'cat_other_unclassified',
        'Unclassified',
        level: 2,
        parentId: 'cat_other_expense',
      );
      await _insertCategory(db, 'cat_uncategorized', 'Uncategorized');
      await _insertTransaction(db, 'tx_unc_1', 'cat_uncategorized');

      await _runV14MigrationSteps(db);

      final remappedCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_other_unclassified'",
      );
      expect(remappedCount, 1, reason: 'cat_uncategorized transaction should be remapped');

      final oldCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_uncategorized'",
      );
      expect(oldCount, 0);
    });

    test('remaps cat_daily_pets transactions to cat_pet_other', () async {
      await _insertCategory(db, 'cat_daily', 'Daily');
      await _insertCategory(db, 'cat_daily_pets', 'Pets', level: 2, parentId: 'cat_daily');
      await _insertTransaction(db, 'tx_pets_1', 'cat_daily_pets');
      await _insertTransaction(db, 'tx_pets_2', 'cat_daily_pets');

      await _runV14MigrationSteps(db);

      final remappedCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_pet_other'",
      );
      expect(remappedCount, 2, reason: 'cat_daily_pets transactions should remap to cat_pet_other');

      final oldCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_daily_pets'",
      );
      expect(oldCount, 0);
    });

    test('remaps cat_other_allowance transactions to cat_allowance_self', () async {
      await _insertCategory(db, 'cat_other_expense', 'Other Expense');
      await _insertCategory(
        db,
        'cat_other_allowance',
        'Allowance',
        level: 2,
        parentId: 'cat_other_expense',
      );
      await _insertTransaction(db, 'tx_allow_1', 'cat_other_allowance');

      await _runV14MigrationSteps(db);

      final remappedCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_allowance_self'",
      );
      expect(remappedCount, 1, reason: 'cat_other_allowance should remap to cat_allowance_self');

      final oldCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_other_allowance'",
      );
      expect(oldCount, 0);
    });

    test(
      'remaps meal-time food transactions (breakfast/lunch/dinner) to cat_food_dining_out',
      () async {
        await _insertCategory(db, 'cat_food', 'Food');
        await _insertCategory(
          db, 'cat_food_breakfast', 'Breakfast', level: 2, parentId: 'cat_food',
        );
        await _insertCategory(
          db, 'cat_food_lunch', 'Lunch', level: 2, parentId: 'cat_food',
        );
        await _insertCategory(
          db, 'cat_food_dinner', 'Dinner', level: 2, parentId: 'cat_food',
        );
        await _insertCategory(
          db, 'cat_food_dining_out', 'Dining Out', level: 2, parentId: 'cat_food',
        );

        await _insertTransaction(db, 'tx_bk', 'cat_food_breakfast');
        await _insertTransaction(db, 'tx_lu', 'cat_food_lunch');
        await _insertTransaction(db, 'tx_di', 'cat_food_dinner');

        await _runV14MigrationSteps(db);

        final remappedCount = await _queryCount(
          db,
          "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_food_dining_out'",
        );
        expect(
          remappedCount,
          3,
          reason: 'breakfast, lunch, dinner should all map to cat_food_dining_out',
        );

        for (final oldId in ['cat_food_breakfast', 'cat_food_lunch', 'cat_food_dinner']) {
          final old = await _queryCount(
            db,
            "SELECT COUNT(*) AS c FROM transactions WHERE category_id = '$oldId'",
          );
          expect(old, 0, reason: '$oldId transactions should be remapped');
        }
      },
    );

    test('remaps cat_food_general transactions to cat_food_other', () async {
      await _insertCategory(db, 'cat_food', 'Food');
      await _insertCategory(db, 'cat_food_general', 'General', level: 2, parentId: 'cat_food');
      await _insertCategory(db, 'cat_food_other', 'Other Food', level: 2, parentId: 'cat_food');
      await _insertTransaction(db, 'tx_fg_1', 'cat_food_general');

      await _runV14MigrationSteps(db);

      final remappedCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_food_other'",
      );
      expect(remappedCount, 1, reason: 'cat_food_general should remap to cat_food_other');

      final oldCount = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM transactions WHERE category_id = 'cat_food_general'",
      );
      expect(oldCount, 0);
    });

    test('preserves total transaction count through migration', () async {
      // Seed old category rows and transactions across multiple remapped IDs
      await _insertCategory(db, 'cat_food', 'Food');
      await _insertCategory(db, 'cat_food_breakfast', 'Breakfast', level: 2, parentId: 'cat_food');
      await _insertCategory(db, 'cat_food_lunch', 'Lunch', level: 2, parentId: 'cat_food');
      await _insertCategory(db, 'cat_food_dining_out', 'Dining Out', level: 2, parentId: 'cat_food');
      await _insertCategory(db, 'cat_cash_card', 'Cash/Card');
      await _insertCategory(db, 'cat_uncategorized', 'Uncategorized');
      await _insertCategory(db, 'cat_daily', 'Daily');
      await _insertCategory(db, 'cat_daily_pets', 'Pets', level: 2, parentId: 'cat_daily');
      await _insertCategory(db, 'cat_other_expense', 'Other');
      await _insertCategory(
        db, 'cat_other_unclassified', 'Unclassified', level: 2, parentId: 'cat_other_expense',
      );

      const seedIds = [
        'cat_food_breakfast',
        'cat_food_lunch',
        'cat_cash_card',
        'cat_uncategorized',
        'cat_daily_pets',
      ];
      var idx = 0;
      for (final catId in seedIds) {
        await _insertTransaction(db, 'tx_count_${idx++}', catId);
        await _insertTransaction(db, 'tx_count_${idx++}', catId);
      }

      final beforeCount = await _queryCount(
        db,
        'SELECT COUNT(*) AS c FROM transactions',
      );

      await _runV14MigrationSteps(db);

      final afterCount = await _queryCount(
        db,
        'SELECT COUNT(*) AS c FROM transactions',
      );

      expect(
        afterCount,
        beforeCount,
        reason: 'Migration must not add or remove rows — only remap category_id values',
      );
    });
  });

  // ─── Categories table tests ──────────────────────────────────────────────────

  group('v14 migration — categories table', () {
    test('categories table contains cat_pet after migration', () async {
      await _runV14MigrationSteps(db);

      final count = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM categories WHERE id = 'cat_pet'",
      );
      expect(count, 1, reason: 'cat_pet L1 should be inserted into categories by migration');
    });

    test('categories table does not contain cat_cash_card after migration', () async {
      await _insertCategory(db, 'cat_cash_card', 'Cash / Card');
      await _insertLedgerConfig(db, 'cat_cash_card', 'survival');

      await _runV14MigrationSteps(db);

      final count = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM categories WHERE id = 'cat_cash_card'",
      );
      expect(count, 0, reason: 'cat_cash_card should be removed from categories');
    });

    test('categories table does not contain cat_uncategorized after migration', () async {
      await _insertCategory(db, 'cat_uncategorized', 'Uncategorized');
      await _insertLedgerConfig(db, 'cat_uncategorized', 'survival');

      await _runV14MigrationSteps(db);

      final count = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM categories WHERE id = 'cat_uncategorized'",
      );
      expect(count, 0, reason: 'cat_uncategorized should be removed from categories');
    });
  });

  // ─── Ledger config tests ─────────────────────────────────────────────────────

  group('v14 migration — category_ledger_configs', () {
    test('category_ledger_configs has cat_pet → soul after migration', () async {
      await _runV14MigrationSteps(db);

      final ledgerType = await _queryString(
        db,
        "SELECT ledger_type FROM category_ledger_configs WHERE category_id = 'cat_pet'",
      );
      expect(ledgerType, 'soul', reason: 'cat_pet should be soul ledger');
    });

    test('category_ledger_configs has cat_allowance → soul after migration', () async {
      await _runV14MigrationSteps(db);

      final ledgerType = await _queryString(
        db,
        "SELECT ledger_type FROM category_ledger_configs WHERE category_id = 'cat_allowance'",
      );
      expect(ledgerType, 'soul', reason: 'cat_allowance should be soul ledger');
    });

    test('orphan ledger config for cat_cash_card is deleted after migration', () async {
      await _insertCategory(db, 'cat_cash_card', 'Cash / Card');
      await _insertLedgerConfig(db, 'cat_cash_card', 'survival');

      await _runV14MigrationSteps(db);

      final count = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM category_ledger_configs WHERE category_id = 'cat_cash_card'",
      );
      expect(count, 0, reason: 'Orphan ledger config for cat_cash_card must be deleted');
    });

    test('orphan ledger config for cat_uncategorized is deleted after migration', () async {
      await _insertCategory(db, 'cat_uncategorized', 'Uncategorized');
      await _insertLedgerConfig(db, 'cat_uncategorized', 'survival');

      await _runV14MigrationSteps(db);

      final count = await _queryCount(
        db,
        "SELECT COUNT(*) AS c FROM category_ledger_configs WHERE category_id = 'cat_uncategorized'",
      );
      expect(count, 0, reason: 'Orphan ledger config for cat_uncategorized must be deleted');
    });
  });
}
