# Category 双層分類 Data Layer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the two-layer category data model per BASIC-004 PRD, including CategoryNode updates, CategoryLedgerConfig table, effective-ledger-type resolution service, and new default categories with i18n keys.

**Architecture:** Extend the existing Category domain model to match the PRD's `CategoryNode` (add `isArchived`, `updatedAt`; enforce level 1-2). Add a separate `CategoryLedgerConfig` table for personal ledger type preferences (L1 mandatory, L2 optional override). Create `ResolveLedgerTypeService` in the application layer for effective type resolution. Replace the old 10+4 default categories with the PRD's 19 L1 + 103 L2 + 4 income categories using i18n keys.

**Tech Stack:** Drift (SQLCipher), Freezed, Riverpod code-gen, flutter_test + mockito

**Source PRD:** `docs/arch/04-basic/BASIC-004_Category_PRD.md`

**Git rule:** Generated files (`.g.dart`, `.freezed.dart`, `.mocks.dart`) are gitignored. Only commit hand-written source files.

**Verification cadence:** Run `flutter analyze` + `flutter test` every 2–3 tasks (after Tasks 2, 5, 8, 10, 13, 14, 15, 16). Fix regressions immediately before proceeding.

---

## Terminology Mapping (CRITICAL)

The PRD uses `cost/soul` terminology for the dual ledger, but the **existing codebase and database use `survival/soul`**.

| PRD Term | Code / DB Value | Enum |
|----------|-----------------|------|
| cost (生存) | `survival` | `LedgerType.survival` |
| soul (灵魂) | `soul` | `LedgerType.soul` |

**Canonical rule:** All code, database values, default constants, and API contracts MUST use `survival` / `soul` (the existing `LedgerType` enum values defined in `lib/features/accounting/domain/models/transaction.dart`). When reading the PRD, mentally map `cost → survival`. The PRD's `cost` label is a UI display concern handled by i18n, not a data value.

**Why keep `survival`:**
- Already stored in the `transactions.ledger_type` column in production
- `LedgerType.survival` is referenced across 20+ files
- Renaming would require a data migration + sweeping refactor with zero functional benefit

**All code examples in this plan use `survival` / `soul` accordingly.**

---

## Gap Analysis

| Aspect | Current | Target (PRD §6) |
|--------|---------|-----------------|
| Max levels | 3 | 2 (strict) |
| `type` field | `TransactionType` on Category | Separate `CategoryLedgerConfig` table |
| `isArchived` | missing | required |
| `updatedAt` | missing | required |
| `familyId` / `createdBy` | missing | deferred (Phase 1 = single user) |
| Default L1s | 10 expense + 4 income | 19 expense L1s + 4 income L1s |
| Default L2s | 6 | 103 (from PRD §10.1–10.16) |
| Ledger type resolution | hardcoded on Category | L1 preference + L2 override → effective type |

**Deferred to Family Sync phase:** `familyId`, `createdBy`, sync merge logic (FR-006/007).

---

## Task 1: Update Category Domain Model

**Files:**
- Modify: `lib/features/accounting/domain/models/category.dart`

**Step 1: Update the Freezed model**

Remove `type` (TransactionType) and `budgetAmount`. Add `isArchived` and `updatedAt`. Keep `icon`, `color` (needed for UI).

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    @Default(false) bool isSystem,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
```

Key changes:
- Removed `type` (TransactionType) — replaced by `CategoryLedgerConfig`
- Removed `budgetAmount` — can be re-added later if needed
- Added `isArchived` (default false)
- Added `updatedAt` (nullable)
- Removed `import 'transaction.dart'` (no longer depends on TransactionType)

**Step 2: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/features/accounting/domain/models/category.dart
git commit -m "refactor(category): remove type field, add isArchived and updatedAt"
```

> **Note:** Generated files (`.g.dart`, `.freezed.dart`) are gitignored. Only commit hand-written source files.

---

## Task 2: Create CategoryLedgerConfig Domain Model

**Files:**
- Create: `lib/features/accounting/domain/models/category_ledger_config.dart`

**Step 1: Write the failing test**

File: `test/unit/features/accounting/domain/models/category_ledger_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('CategoryLedgerConfig', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 18);
      final config = CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: now,
      );

      expect(config.categoryId, 'cat_food');
      expect(config.ledgerType, LedgerType.survival);
      expect(config.updatedAt, now);
    });

    test('serializes to and from JSON', () {
      final now = DateTime(2026, 2, 18);
      final config = CategoryLedgerConfig(
        categoryId: 'cat_entertainment',
        ledgerType: LedgerType.soul,
        updatedAt: now,
      );

      final json = config.toJson();
      final restored = CategoryLedgerConfig.fromJson(json);

      expect(restored.categoryId, config.categoryId);
      expect(restored.ledgerType, config.ledgerType);
    });

    test('copyWith creates new instance', () {
      final config = CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: DateTime(2026, 2, 18),
      );

      final updated = config.copyWith(ledgerType: LedgerType.soul);
      expect(updated.ledgerType, LedgerType.soul);
      expect(updated.categoryId, 'cat_food');
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/features/accounting/domain/models/category_ledger_config_test.dart
```

Expected: FAIL — `CategoryLedgerConfig` not found.

**Step 3: Write the model**

File: `lib/features/accounting/domain/models/category_ledger_config.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'category_ledger_config.freezed.dart';
part 'category_ledger_config.g.dart';

/// Personal ledger type configuration for a category.
///
/// - For L1 categories: mandatory (every L1 must have a config).
/// - For L2 categories: optional override (inherits parent L1 if absent).
///
/// This data is personal and NOT synced across family members.
@freezed
abstract class CategoryLedgerConfig with _$CategoryLedgerConfig {
  const factory CategoryLedgerConfig({
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime updatedAt,
  }) = _CategoryLedgerConfig;

  factory CategoryLedgerConfig.fromJson(Map<String, dynamic> json) =>
      _$CategoryLedgerConfigFromJson(json);
}
```

**Step 4: Run code generation and tests**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/accounting/domain/models/category_ledger_config_test.dart
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/models/category_ledger_config.dart \
        test/unit/features/accounting/domain/models/category_ledger_config_test.dart
git commit -m "feat(category): add CategoryLedgerConfig domain model"
```

**Checkpoint (after Tasks 1–2):** `flutter analyze && flutter test` — domain models compile, existing tests still pass.

---

## Task 3: Update Categories Drift Table

**Files:**
- Modify: `lib/data/tables/categories_table.dart`

**Step 1: Update table definition**

Remove `type` and `budgetAmount` columns. Add `isArchived` and `updatedAt` columns.

```dart
import 'package:drift/drift.dart';

/// Categories table — two-level transaction categories (L1 / L2).
///
/// Database constraints enforced:
/// - level IN (1, 2)
/// - L1 (level=1): parentId IS NULL
/// - L2 (level=2): parentId IS NOT NULL
/// - parentId references categories(id) (foreign key)
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get parentId => text()
      .nullable()
      .references(Categories, #id)();
  IntColumn get level => integer().check(level.isIn([1, 2]))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_categories_parent_id', columns: {#parentId}),
    TableIndex(name: 'idx_categories_level', columns: {#level}),
    TableIndex(name: 'idx_categories_archived', columns: {#isArchived}),
  ];
}
```

Key changes:
- Removed `type` column (replaced by `CategoryLedgerConfigs` table)
- Removed `budgetAmount` column
- Added `isArchived` boolean column (default false)
- Added `updatedAt` nullable datetime column
- Updated index: `idx_categories_type` → `idx_categories_archived`
- Updated doc comment: "two-level" instead of "3 levels"
- **`level` CHECK constraint:** `level IN (1, 2)` — prevents invalid hierarchy depths
- **`parentId` foreign key:** `.references(Categories, #id)` — ensures referential integrity
- **L1/L2 parentId consistency:** enforced via application-layer validation + migration CHECK constraints (see Task 5)

**Step 2: Commit** (will be committed together with Task 4 after code gen)

---

## Task 4: Create CategoryLedgerConfigs Drift Table

**Files:**
- Create: `lib/data/tables/category_ledger_configs_table.dart`

**Step 1: Write the table definition**

```dart
import 'package:drift/drift.dart';

import 'categories_table.dart';

/// Personal ledger type configuration for categories.
///
/// Stores each user's survival/soul preference per category.
/// (PRD term "cost" = code term "survival", see Terminology Mapping)
/// - L1 categories: mandatory entry
/// - L2 categories: optional override (absence = inherit from parent L1)
///
/// This table is NOT synced across family members.
@DataClassName('CategoryLedgerConfigRow')
class CategoryLedgerConfigs extends Table {
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get ledgerType => text()
      .check(ledgerType.isIn(['survival', 'soul']))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {categoryId};
}
```

Key constraints:
- **`categoryId` foreign key:** references `categories.id` — prevents orphaned configs
- **`ledgerType` CHECK:** must be `'survival'` or `'soul'` — prevents invalid values (see Terminology Mapping)

**Step 2: Commit** (will be committed together after code gen in Task 6)

---

## Task 5: Update AppDatabase — Register New Table & Migration

**Files:**
- Modify: `lib/data/app_database.dart`

**Step 1: Register table and add migration**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_ledger_configs_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  AuditLogs,
  Books,
  Categories,
  CategoryLedgerConfigs,
  Transactions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 3) {
          await migrator.addColumn(categories, categories.budgetAmount);
        }
        if (from < 4) {
          await migrator.addColumn(
            transactions, transactions.soulSatisfaction);
        }
        if (from < 5) {
          // Category model v2: add isArchived, updatedAt; create ledger configs
          await migrator.addColumn(categories, categories.isArchived);
          await migrator.addColumn(categories, categories.updatedAt);
          await migrator.createTable(categoryLedgerConfigs);

          // Migrate existing type data to ledger configs
          // All existing L1 categories with type='expense' get survival default
          // (PRD term "cost" = code term "survival", see Terminology Mapping)
          await customStatement('''
            INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
            SELECT id, 'survival', CAST(strftime('%s', 'now') * 1000 AS INTEGER)
            FROM categories WHERE level = 1 AND type IS NOT NULL
          ''');

          // Add CHECK constraints for level and parentId consistency
          // Note: SQLite CHECK constraints can only be added at table creation,
          // not via ALTER TABLE. For existing rows, we validate and fix data first.
          // Drift's .check() on the column definition handles new inserts.

          // Fix any existing data that violates L1/L2 parentId rules:
          // L1 must have parentId IS NULL
          await customStatement('''
            UPDATE categories SET parent_id = NULL
            WHERE level = 1 AND parent_id IS NOT NULL
          ''');
          // L2 must have parentId IS NOT NULL (orphaned L2s get archived)
          await customStatement('''
            UPDATE categories SET is_archived = 1
            WHERE level = 2 AND parent_id IS NULL
          ''');

          // Drop old columns (SQLite doesn't support DROP COLUMN < 3.35.0,
          // so we leave type and budget_amount as unused columns for now)
        }
      },
    );
  }
}
```

Note: SQLite before 3.35.0 doesn't support `DROP COLUMN`. Since we target older Android/iOS, we leave `type` and `budget_amount` columns in the table but stop reading/writing them. They'll be garbage-collected in a future major migration.

**Step 2: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/tables/categories_table.dart \
        lib/data/tables/category_ledger_configs_table.dart \
        lib/data/app_database.dart
git commit -m "feat(category): add CategoryLedgerConfigs table, update schema to v5"
```

**Checkpoint (after Tasks 3–5):** `flutter analyze && flutter test` — schema compiles, code gen succeeds, migration builds.

---

## Task 6: Update CategoryDao

**Files:**
- Modify: `lib/data/daos/category_dao.dart`

**Step 1: Update DAO to match new schema**

Remove `type` and `budgetAmount` from insert params. Add `isArchived`, `updatedAt`. Add `update` method. Add `findActive` (non-archived).

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';

/// Parameter object for batch category insertion.
class CategoryInsertData {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? parentId;
  final int level;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryInsertData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    this.isSystem = false,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });
}

/// Data access object for the Categories table.
class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<void> insertCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    bool isSystem = false,
    bool isArchived = false,
    int sortOrder = 0,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) async {
    // Application-level validation: L1/L2 parentId consistency
    assert(level == 1 || level == 2, 'level must be 1 or 2');
    assert(level != 1 || parentId == null, 'L1 must have parentId == null');
    assert(level != 2 || parentId != null, 'L2 must have parentId != null');

    await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        parentId: Value(parentId),
        level: level,
        isSystem: Value(isSystem),
        isArchived: Value(isArchived),
        sortOrder: Value(sortOrder),
        createdAt: createdAt,
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
    required DateTime updatedAt,
  }) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isArchived:
            isArchived != null ? Value(isArchived) : const Value.absent(),
        sortOrder:
            sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<CategoryRow?> findById(String id) async {
    return (_db.select(_db.categories)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoryRow>> findAll() async {
    return (_db.select(_db.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  /// Returns only non-archived categories.
  Future<List<CategoryRow>> findActive() async {
    return (_db.select(_db.categories)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  Future<List<CategoryRow>> findByLevel(int level) async {
    return (_db.select(_db.categories)
      ..where((t) => t.level.equals(level))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  Future<List<CategoryRow>> findByParent(String parentId) async {
    return (_db.select(_db.categories)
      ..where((t) => t.parentId.equals(parentId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.categories).go();
  }

  Future<void> insertBatch(List<CategoryInsertData> categories) async {
    // Validate all entries before batch insert
    for (final cat in categories) {
      assert(cat.level == 1 || cat.level == 2, 'level must be 1 or 2');
      assert(cat.level != 1 || cat.parentId == null,
          'L1 "${cat.id}" must have parentId == null');
      assert(cat.level != 2 || cat.parentId != null,
          'L2 "${cat.id}" must have parentId != null');
    }

    await _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(
          _db.categories,
          CategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            icon: cat.icon,
            color: cat.color,
            parentId: Value(cat.parentId),
            level: cat.level,
            isSystem: Value(cat.isSystem),
            isArchived: Value(cat.isArchived),
            sortOrder: Value(cat.sortOrder),
            createdAt: cat.createdAt,
            updatedAt: Value(cat.updatedAt),
          ),
        );
      }
    });
  }
}
```

Removed: `findByType`, `findWithBudget` (these relied on the removed `type`/`budgetAmount` columns).
Added: `updateCategory`, `findActive`.

**Step 2: Write/update tests**

File: `test/unit/data/daos/category_dao_test.dart`

Update existing tests to remove `type` parameter. Add tests for `updateCategory`, `findActive`, `isArchived`.

**Step 3: Run tests**

```bash
flutter test test/unit/data/daos/category_dao_test.dart
```

**Step 4: Commit**

```bash
git add lib/data/daos/category_dao.dart \
        test/unit/data/daos/category_dao_test.dart
git commit -m "refactor(category): update CategoryDao for two-level model"
```

---

## Task 7: Create CategoryLedgerConfigDao

**Files:**
- Create: `lib/data/daos/category_ledger_config_dao.dart`
- Create: `test/unit/data/daos/category_ledger_config_dao_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_ledger_config_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryLedgerConfigDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryLedgerConfigDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryLedgerConfigDao', () {
    test('upsert and findById', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );

      final config = await dao.findById('cat_food');
      expect(config, isNotNull);
      expect(config!.ledgerType, 'survival');
    });

    test('upsert overwrites existing entry', () async {
      final t1 = DateTime(2026, 2, 18, 10);
      final t2 = DateTime(2026, 2, 18, 11);

      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: t1,
      );
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'soul',
        updatedAt: t2,
      );

      final config = await dao.findById('cat_food');
      expect(config!.ledgerType, 'soul');
    });

    test('findAll returns all configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );
      await dao.upsert(
        categoryId: 'cat_entertainment',
        ledgerType: 'soul',
        updatedAt: now,
      );

      final all = await dao.findAll();
      expect(all.length, 2);
    });

    test('delete removes config', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );

      await dao.delete('cat_food');
      final config = await dao.findById('cat_food');
      expect(config, isNull);
    });

    test('deleteAll removes all configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food', ledgerType: 'survival', updatedAt: now);
      await dao.upsert(
        categoryId: 'cat_fun', ledgerType: 'soul', updatedAt: now);

      await dao.deleteAll();
      final all = await dao.findAll();
      expect(all, isEmpty);
    });

    test('upsertBatch inserts multiple configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsertBatch([
        LedgerConfigInsertData(
          categoryId: 'cat_food', ledgerType: 'survival', updatedAt: now),
        LedgerConfigInsertData(
          categoryId: 'cat_fun', ledgerType: 'soul', updatedAt: now),
      ]);

      final all = await dao.findAll();
      expect(all.length, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/data/daos/category_ledger_config_dao_test.dart
```

**Step 3: Write DAO implementation**

File: `lib/data/daos/category_ledger_config_dao.dart`

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';

/// Parameter object for batch ledger config insertion.
class LedgerConfigInsertData {
  final String categoryId;
  final String ledgerType;
  final DateTime updatedAt;

  const LedgerConfigInsertData({
    required this.categoryId,
    required this.ledgerType,
    required this.updatedAt,
  });
}

/// Data access object for the CategoryLedgerConfigs table.
class CategoryLedgerConfigDao {
  CategoryLedgerConfigDao(this._db);

  final AppDatabase _db;

  /// Insert or update a ledger config for a category.
  Future<void> upsert({
    required String categoryId,
    required String ledgerType,
    required DateTime updatedAt,
  }) async {
    await _db.into(_db.categoryLedgerConfigs).insertOnConflictUpdate(
      CategoryLedgerConfigsCompanion.insert(
        categoryId: categoryId,
        ledgerType: ledgerType,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<CategoryLedgerConfigRow?> findById(String categoryId) async {
    return (_db.select(_db.categoryLedgerConfigs)
      ..where((t) => t.categoryId.equals(categoryId))).getSingleOrNull();
  }

  Future<List<CategoryLedgerConfigRow>> findAll() async {
    return _db.select(_db.categoryLedgerConfigs).get();
  }

  Future<void> delete(String categoryId) async {
    await (_db.delete(_db.categoryLedgerConfigs)
      ..where((t) => t.categoryId.equals(categoryId))).go();
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.categoryLedgerConfigs).go();
  }

  Future<void> upsertBatch(List<LedgerConfigInsertData> configs) async {
    await _db.batch((batch) {
      for (final c in configs) {
        batch.insert(
          _db.categoryLedgerConfigs,
          CategoryLedgerConfigsCompanion.insert(
            categoryId: c.categoryId,
            ledgerType: c.ledgerType,
            updatedAt: c.updatedAt,
          ),
          onConflict: DoUpdate(
            (old) => CategoryLedgerConfigsCompanion(
              ledgerType: Value(c.ledgerType),
              updatedAt: Value(c.updatedAt),
            ),
          ),
        );
      }
    });
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/unit/data/daos/category_ledger_config_dao_test.dart
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/data/daos/category_ledger_config_dao.dart \
        test/unit/data/daos/category_ledger_config_dao_test.dart
git commit -m "feat(category): add CategoryLedgerConfigDao"
```

---

## Task 8: Update CategoryRepository Interface & Implementation

**Files:**
- Modify: `lib/features/accounting/domain/repositories/category_repository.dart`
- Modify: `lib/data/repositories/category_repository_impl.dart`

**Step 1: Update repository interface**

Remove `findByType`, `findWithBudget` (no longer applicable). Add `update`, `findActive`.

```dart
import '../models/category.dart';

/// Abstract repository interface for category data access.
abstract class CategoryRepository {
  Future<void> insert(Category category);
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  });
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<List<Category>> findActive();
  Future<List<Category>> findByLevel(int level);
  Future<List<Category>> findByParent(String parentId);
  Future<void> insertBatch(List<Category> categories);
  Future<void> deleteAll();
}
```

**Step 2: Update repository implementation**

```dart
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../app_database.dart';
import '../daos/category_dao.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryDao dao}) : _dao = dao;

  final CategoryDao _dao;

  @override
  Future<void> insert(Category category) async {
    await _dao.insertCategory(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      parentId: category.parentId,
      level: category.level,
      isSystem: category.isSystem,
      isArchived: category.isArchived,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {
    await _dao.updateCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      isArchived: isArchived,
      sortOrder: sortOrder,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Category>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findActive() async {
    final rows = await _dao.findActive();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByLevel(int level) async {
    final rows = await _dao.findByLevel(level);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByParent(String parentId) async {
    final rows = await _dao.findByParent(parentId);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> deleteAll() => _dao.deleteAll();

  @override
  Future<void> insertBatch(List<Category> categories) async {
    await _dao.insertBatch(
      categories
          .map((c) => CategoryInsertData(
                id: c.id,
                name: c.name,
                icon: c.icon,
                color: c.color,
                parentId: c.parentId,
                level: c.level,
                isSystem: c.isSystem,
                isArchived: c.isArchived,
                sortOrder: c.sortOrder,
                createdAt: c.createdAt,
                updatedAt: c.updatedAt,
              ))
          .toList(),
    );
  }

  Category _toModel(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      parentId: row.parentId,
      level: row.level,
      isSystem: row.isSystem,
      isArchived: row.isArchived,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
```

**Step 3: Update existing repository test**

File: `test/unit/data/repositories/category_repository_impl_test.dart`

Update tests to remove `type`/`budgetAmount` references and add tests for `update`, `findActive`.

**Step 4: Run tests**

```bash
flutter test test/unit/data/repositories/category_repository_impl_test.dart
```

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/repositories/category_repository.dart \
        lib/data/repositories/category_repository_impl.dart \
        test/unit/data/repositories/category_repository_impl_test.dart
git commit -m "refactor(category): update CategoryRepository for two-level model"
```

**Checkpoint (after Tasks 6–8):** `flutter analyze && flutter test` — DAO + repository layer compiles and passes.

---

## Task 9: Create CategoryLedgerConfigRepository

**Files:**
- Create: `lib/features/accounting/domain/repositories/category_ledger_config_repository.dart`
- Create: `lib/data/repositories/category_ledger_config_repository_impl.dart`
- Create: `test/unit/data/repositories/category_ledger_config_repository_impl_test.dart`

**Step 1: Write repository interface**

```dart
import '../models/category_ledger_config.dart';

/// Repository for personal category ledger type configurations.
abstract class CategoryLedgerConfigRepository {
  Future<void> upsert(CategoryLedgerConfig config);
  Future<CategoryLedgerConfig?> findById(String categoryId);
  Future<List<CategoryLedgerConfig>> findAll();
  Future<void> delete(String categoryId);
  Future<void> deleteAll();
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs);
}
```

**Step 2: Write failing test, then implementation**

Implementation maps between `CategoryLedgerConfig` domain model and `CategoryLedgerConfigRow` Drift row, using `CategoryLedgerConfigDao`.

**Step 3: Run tests, commit**

```bash
git commit -m "feat(category): add CategoryLedgerConfigRepository"
```

---

## Task 10: Create ResolveLedgerTypeService

**Files:**
- Create: `lib/application/dual_ledger/resolve_ledger_type_service.dart`
- Create: `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/resolve_ledger_type_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryLedgerConfigRepository])
import 'resolve_ledger_type_service_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryLedgerConfigRepository mockConfigRepo;
  late ResolveLedgerTypeService service;

  final epoch = DateTime(2026, 1, 1);

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockConfigRepo = MockCategoryLedgerConfigRepository();
    service = ResolveLedgerTypeService(
      categoryRepository: mockCategoryRepo,
      ledgerConfigRepository: mockConfigRepo,
    );
  });

  group('ResolveLedgerTypeService', () {
    test('L1 category returns its own ledger config', () async {
      when(mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => Category(
          id: 'cat_food', name: 'Food', icon: 'restaurant',
          color: '#FF5722', level: 1, createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food');
      expect(result, LedgerType.survival);
    });

    test('L2 with override returns L2 config', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch', name: 'Lunch', icon: 'lunch',
          color: '#FF5722', parentId: 'cat_food', level: 2,
          createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food_lunch',
          ledgerType: LedgerType.soul,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food_lunch');
      expect(result, LedgerType.soul);
    });

    test('L2 without override inherits from parent L1', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch', name: 'Lunch', icon: 'lunch',
          color: '#FF5722', parentId: 'cat_food', level: 2,
          createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food_lunch'))
          .thenAnswer((_) async => null);
      when(mockConfigRepo.findById('cat_food')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food_lunch');
      expect(result, LedgerType.survival);
    });

    test('returns null when category not found', () async {
      when(mockCategoryRepo.findById('nonexistent'))
          .thenAnswer((_) async => null);

      final result = await service.resolve('nonexistent');
      expect(result, isNull);
    });

    test('resolveL1 returns parent L1 for L2 category', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch', name: 'Lunch', icon: 'lunch',
          color: '#FF5722', parentId: 'cat_food', level: 2,
          createdAt: epoch,
        ),
      );

      final result = await service.resolveL1('cat_food_lunch');
      expect(result, 'cat_food');
    });

    test('resolveL1 returns own id for L1 category', () async {
      when(mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => Category(
          id: 'cat_food', name: 'Food', icon: 'restaurant',
          color: '#FF5722', level: 1, createdAt: epoch,
        ),
      );

      final result = await service.resolveL1('cat_food');
      expect(result, 'cat_food');
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
```

**Step 3: Write the service**

File: `lib/application/dual_ledger/resolve_ledger_type_service.dart`

```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';

/// Resolves the effective ledger type for a category.
///
/// Resolution rules (PRD FR-004):
/// - L1: returns its own `CategoryLedgerConfig.ledgerType`
/// - L2 with override: returns the L2's own config
/// - L2 without override: inherits from parent L1's config
class ResolveLedgerTypeService {
  ResolveLedgerTypeService({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  })  : _categoryRepo = categoryRepository,
        _configRepo = ledgerConfigRepository;

  final CategoryRepository _categoryRepo;
  final CategoryLedgerConfigRepository _configRepo;

  /// Returns the effective [LedgerType] for [categoryId], or null if
  /// the category doesn't exist or has no config.
  Future<LedgerType?> resolve(String categoryId) async {
    final category = await _categoryRepo.findById(categoryId);
    if (category == null) return null;

    // Check for direct config (works for both L1 and L2 with override)
    final directConfig = await _configRepo.findById(categoryId);
    if (directConfig != null) return directConfig.ledgerType;

    // L2 without override → inherit from parent L1
    if (category.level == 2 && category.parentId != null) {
      final parentConfig = await _configRepo.findById(category.parentId!);
      return parentConfig?.ledgerType;
    }

    return null;
  }

  /// Returns the resolved L1 category ID for statistics aggregation.
  ///
  /// - L1 → returns its own ID
  /// - L2 → returns its parentId (the L1)
  Future<String?> resolveL1(String categoryId) async {
    final category = await _categoryRepo.findById(categoryId);
    if (category == null) return null;

    if (category.level == 1) return category.id;
    return category.parentId;
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/application/dual_ledger/resolve_ledger_type_service.dart \
        test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
git commit -m "feat(dual-ledger): add ResolveLedgerTypeService"
```

**Checkpoint (after Tasks 9–10):** `flutter analyze && flutter test` — all new code compiles, unit tests pass.

---

## Task 11: Update Default Categories

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`
- Create: `test/unit/shared/constants/default_categories_test.dart`

**Conventions:**
- Category ID: `cat_{english_snake_case}` for L1, `cat_{parent}_{english_snake_case}` for L2
- `name` field stores i18n key (e.g. `'category_food'`). Actual ARB entries deferred to UI task.
- `type` field removed (see Task 1). Ledger type now in `defaultLedgerConfigs`.
- L1 sort order matches PRD §10.0 exactly.

**Step 1: Write the failing test**

File: `test/unit/shared/constants/default_categories_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories', () {
    test('has 19 expense L1 categories', () {
      final l1s = DefaultCategories.expenseL1;
      expect(l1s.length, 19);
      expect(l1s.every((c) => c.level == 1), isTrue);
      expect(l1s.every((c) => c.parentId == null), isTrue);
    });

    test('L1 sort order matches PRD §10.0', () {
      final l1s = DefaultCategories.expenseL1;
      expect(l1s[0].id, 'cat_food');          // sortOrder 1
      expect(l1s[1].id, 'cat_daily');          // sortOrder 2
      expect(l1s[2].id, 'cat_transport');      // sortOrder 3
      expect(l1s[3].id, 'cat_hobbies');        // sortOrder 4
      expect(l1s[4].id, 'cat_clothing');       // sortOrder 5
      expect(l1s[5].id, 'cat_social');         // sortOrder 6
      expect(l1s[6].id, 'cat_health');         // sortOrder 7
      expect(l1s[7].id, 'cat_education');      // sortOrder 8
      expect(l1s[8].id, 'cat_cash_card');      // sortOrder 9
      expect(l1s[9].id, 'cat_utilities');      // sortOrder 10
      expect(l1s[10].id, 'cat_communication'); // sortOrder 11
      expect(l1s[11].id, 'cat_housing');       // sortOrder 12
      expect(l1s[12].id, 'cat_car');           // sortOrder 13
      expect(l1s[13].id, 'cat_tax');           // sortOrder 14
      expect(l1s[14].id, 'cat_insurance');     // sortOrder 15
      expect(l1s[15].id, 'cat_special');       // sortOrder 16
      expect(l1s[16].id, 'cat_asset');         // sortOrder 17
      expect(l1s[17].id, 'cat_other_expense'); // sortOrder 18
      expect(l1s[18].id, 'cat_uncategorized'); // sortOrder 19
    });

    test('has 4 income L1 categories', () {
      final l1s = DefaultCategories.incomeL1;
      expect(l1s.length, 4);
      expect(l1s.every((c) => c.level == 1 && c.parentId == null), isTrue);
    });

    test('has 103 expense L2 categories (PRD §10.1–10.16)', () {
      final l2s = DefaultCategories.all
          .where((c) => c.level == 2)
          .toList();
      expect(l2s.length, 103);
      expect(l2s.every((c) => c.parentId != null), isTrue);
    });

    test('all L2 categories have valid parentId pointing to an L1', () {
      final l1Ids = DefaultCategories.all
          .where((c) => c.level == 1)
          .map((c) => c.id)
          .toSet();
      final l2s = DefaultCategories.all.where((c) => c.level == 2);
      for (final l2 in l2s) {
        expect(l1Ids.contains(l2.parentId), isTrue,
            reason: '${l2.id} parentId=${l2.parentId} not in L1 set');
      }
    });

    test('no duplicate IDs', () {
      final ids = DefaultCategories.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all categories are isSystem true', () {
      expect(DefaultCategories.all.every((c) => c.isSystem), isTrue);
    });

    test('defaultLedgerConfigs covers all expense L1 categories', () {
      final configIds =
          DefaultCategories.defaultLedgerConfigs.map((c) => c.categoryId).toSet();
      final expenseL1Ids =
          DefaultCategories.expenseL1.map((c) => c.id).toSet();
      expect(configIds.containsAll(expenseL1Ids), isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart
```

**Step 3: Write the complete default categories**

File: `lib/shared/constants/default_categories.dart`

```dart
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/category_ledger_config.dart';
import '../../features/accounting/domain/models/transaction.dart';

/// System default categories per PRD BASIC-004 §10.
///
/// All system categories use `isSystem: true`.
/// The `name` field stores an i18n key (e.g. 'category_food').
/// Actual display strings are in ARB files.
///
/// L1 sort order matches PRD §10.0 exactly.
abstract final class DefaultCategories {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  // ─── Public API ───

  /// All default categories (expense L1 + L2 + income L1).
  static List<Category> get all => [
        ...expenseL1,
        ..._expenseL2,
        ...incomeL1,
      ];

  /// 19 expense L1 categories (PRD §10.0 sort order).
  static List<Category> get expenseL1 => _expenseL1;

  /// Income L1 categories.
  static List<Category> get incomeL1 => _incomeL1;

  /// Default ledger configs for all L1 categories.
  /// Maps each L1 to its default LedgerType (survival/soul).
  static List<CategoryLedgerConfig> get defaultLedgerConfigs =>
      _defaultLedgerConfigs;

  // ─── Expense L1 (PRD §10.0 sort order) ───

  static final List<Category> _expenseL1 = [
    _l1('cat_food', 'category_food', 'restaurant', '#FF5722', 1),
    _l1('cat_daily', 'category_daily', 'local_mall', '#00BCD4', 2),
    _l1('cat_transport', 'category_transport', 'directions_bus', '#2196F3', 3),
    _l1('cat_hobbies', 'category_hobbies', 'sports_esports', '#9C27B0', 4),
    _l1('cat_clothing', 'category_clothing', 'checkroom', '#E91E63', 5),
    _l1('cat_social', 'category_social', 'people', '#FF9800', 6),
    _l1('cat_health', 'category_health', 'local_hospital', '#F44336', 7),
    _l1('cat_education', 'category_education', 'school', '#3F51B5', 8),
    _l1('cat_cash_card', 'category_cash_card', 'credit_card', '#546E7A', 9),
    _l1('cat_utilities', 'category_utilities', 'flash_on', '#FFC107', 10),
    _l1('cat_communication', 'category_communication', 'phone_iphone', '#00ACC1', 11),
    _l1('cat_housing', 'category_housing', 'home', '#795548', 12),
    _l1('cat_car', 'category_car', 'directions_car', '#455A64', 13),
    _l1('cat_tax', 'category_tax', 'account_balance', '#5D4037', 14),
    _l1('cat_insurance', 'category_insurance', 'security', '#827717', 15),
    _l1('cat_special', 'category_special', 'star', '#AD1457', 16),
    _l1('cat_asset', 'category_asset', 'savings', '#1B5E20', 17),
    _l1('cat_other_expense', 'category_other_expense', 'more_horiz', '#607D8B', 18),
    _l1('cat_uncategorized', 'category_uncategorized', 'help_outline', '#9E9E9E', 19),
  ];

  // ─── Expense L2 (PRD §10.1–10.16, 103 items) ───
  //
  // Some L1s have a "general" L2 (sortOrder 0) with the same name as the
  // parent. This is the catch-all subcategory for that L1, matching the
  // PRD convention where the first row in each section duplicates the L1 name.

  static final List<Category> _expenseL2 = [
    // §10.16 Food (7 L2s)
    _l2('cat_food_general', 'category_food_general', 'restaurant', '#FF5722', 'cat_food', 0),
    _l2('cat_food_groceries', 'category_food_groceries', 'shopping_basket', '#FF5722', 'cat_food', 1),
    _l2('cat_food_dining_out', 'category_food_dining_out', 'restaurant_menu', '#FF5722', 'cat_food', 2),
    _l2('cat_food_breakfast', 'category_food_breakfast', 'free_breakfast', '#FF5722', 'cat_food', 3),
    _l2('cat_food_lunch', 'category_food_lunch', 'lunch_dining', '#FF5722', 'cat_food', 4),
    _l2('cat_food_dinner', 'category_food_dinner', 'dinner_dining', '#FF5722', 'cat_food', 5),
    _l2('cat_food_cafe', 'category_food_cafe', 'local_cafe', '#FF5722', 'cat_food', 6),
    _l2('cat_food_other', 'category_food_other', 'more_horiz', '#FF5722', 'cat_food', 99),

    // §10.15 Daily Necessities (6 L2s)
    _l2('cat_daily_general', 'category_daily_general', 'local_mall', '#00BCD4', 'cat_daily', 0),
    _l2('cat_daily_household', 'category_daily_household', 'cleaning_services', '#00BCD4', 'cat_daily', 1),
    _l2('cat_daily_children', 'category_daily_children', 'child_care', '#00BCD4', 'cat_daily', 2),
    _l2('cat_daily_pets', 'category_daily_pets', 'pets', '#00BCD4', 'cat_daily', 3),
    _l2('cat_daily_tobacco', 'category_daily_tobacco', 'smoking_rooms', '#00BCD4', 'cat_daily', 4),
    _l2('cat_daily_other', 'category_daily_other', 'more_horiz', '#00BCD4', 'cat_daily', 99),

    // §10.1 Transport (6 L2s)
    _l2('cat_transport_general', 'category_transport_general', 'directions_bus', '#2196F3', 'cat_transport', 0),
    _l2('cat_transport_train', 'category_transport_train', 'train', '#2196F3', 'cat_transport', 1),
    _l2('cat_transport_bus', 'category_transport_bus', 'directions_bus', '#2196F3', 'cat_transport', 2),
    _l2('cat_transport_taxi', 'category_transport_taxi', 'local_taxi', '#2196F3', 'cat_transport', 3),
    _l2('cat_transport_flights', 'category_transport_flights', 'flight', '#2196F3', 'cat_transport', 4),
    _l2('cat_transport_other', 'category_transport_other', 'more_horiz', '#2196F3', 'cat_transport', 99),

    // §10.12 Hobbies & Entertainment
    _l2('cat_hobbies_leisure', 'category_hobbies_leisure', 'sports_tennis', '#9C27B0', 'cat_hobbies', 1),
    _l2('cat_hobbies_events', 'category_hobbies_events', 'event', '#9C27B0', 'cat_hobbies', 2),
    _l2('cat_hobbies_movies', 'category_hobbies_movies', 'movie', '#9C27B0', 'cat_hobbies', 3),
    _l2('cat_hobbies_games', 'category_hobbies_games', 'videogame_asset', '#9C27B0', 'cat_hobbies', 4),
    _l2('cat_hobbies_books', 'category_hobbies_books', 'menu_book', '#9C27B0', 'cat_hobbies', 5),
    _l2('cat_hobbies_travel', 'category_hobbies_travel', 'luggage', '#9C27B0', 'cat_hobbies', 6),
    _l2('cat_hobbies_other', 'category_hobbies_other', 'more_horiz', '#9C27B0', 'cat_hobbies', 99),

    // §10.10 Clothing & Beauty
    _l2('cat_clothing_clothes', 'category_clothing_clothes', 'checkroom', '#E91E63', 'cat_clothing', 1),
    _l2('cat_clothing_accessories', 'category_clothing_accessories', 'watch', '#E91E63', 'cat_clothing', 2),
    _l2('cat_clothing_underwear', 'category_clothing_underwear', 'dry_cleaning', '#E91E63', 'cat_clothing', 3),
    _l2('cat_clothing_hair', 'category_clothing_hair', 'content_cut', '#E91E63', 'cat_clothing', 4),
    _l2('cat_clothing_cosmetics', 'category_clothing_cosmetics', 'face_retouching_natural', '#E91E63', 'cat_clothing', 5),
    _l2('cat_clothing_esthetic', 'category_clothing_esthetic', 'spa', '#E91E63', 'cat_clothing', 6),
    _l2('cat_clothing_cleaning', 'category_clothing_cleaning', 'local_laundry_service', '#E91E63', 'cat_clothing', 7),
    _l2('cat_clothing_other', 'category_clothing_other', 'more_horiz', '#E91E63', 'cat_clothing', 99),

    // §10.7 Socializing (5 L2s)
    _l2('cat_social_general', 'category_social_general', 'people', '#FF9800', 'cat_social', 0),
    _l2('cat_social_drinks', 'category_social_drinks', 'local_bar', '#FF9800', 'cat_social', 1),
    _l2('cat_social_gifts', 'category_social_gifts', 'card_giftcard', '#FF9800', 'cat_social', 2),
    _l2('cat_social_ceremonial', 'category_social_ceremonial', 'celebration', '#FF9800', 'cat_social', 3),
    _l2('cat_social_other', 'category_social_other', 'more_horiz', '#FF9800', 'cat_social', 99),

    // §10.5 Health & Medical
    _l2('cat_health_fitness', 'category_health_fitness', 'fitness_center', '#F44336', 'cat_health', 1),
    _l2('cat_health_massage', 'category_health_massage', 'self_improvement', '#F44336', 'cat_health', 2),
    _l2('cat_health_hospital', 'category_health_hospital', 'local_hospital', '#F44336', 'cat_health', 3),
    _l2('cat_health_medicine', 'category_health_medicine', 'medication', '#F44336', 'cat_health', 4),
    _l2('cat_health_other', 'category_health_other', 'more_horiz', '#F44336', 'cat_health', 99),

    // §10.6 Education & Self-Improvement
    _l2('cat_education_books', 'category_education_books', 'menu_book', '#3F51B5', 'cat_education', 1),
    _l2('cat_education_newspapers', 'category_education_newspapers', 'newspaper', '#3F51B5', 'cat_education', 2),
    _l2('cat_education_classes', 'category_education_classes', 'cast_for_education', '#3F51B5', 'cat_education', 3),
    _l2('cat_education_textbooks', 'category_education_textbooks', 'auto_stories', '#3F51B5', 'cat_education', 4),
    _l2('cat_education_tuition', 'category_education_tuition', 'school', '#3F51B5', 'cat_education', 5),
    _l2('cat_education_cram_school', 'category_education_cram_school', 'edit_note', '#3F51B5', 'cat_education', 6),
    _l2('cat_education_other', 'category_education_other', 'more_horiz', '#3F51B5', 'cat_education', 99),

    // §10.4 Utilities (5 L2s)
    _l2('cat_utilities_general', 'category_utilities_general', 'flash_on', '#FFC107', 'cat_utilities', 0),
    _l2('cat_utilities_electricity', 'category_utilities_electricity', 'bolt', '#FFC107', 'cat_utilities', 1),
    _l2('cat_utilities_water', 'category_utilities_water', 'water_drop', '#FFC107', 'cat_utilities', 2),
    _l2('cat_utilities_gas', 'category_utilities_gas', 'local_fire_department', '#FFC107', 'cat_utilities', 3),
    _l2('cat_utilities_other', 'category_utilities_other', 'more_horiz', '#FFC107', 'cat_utilities', 99),

    // §10.13 Communication
    _l2('cat_communication_mobile', 'category_communication_mobile', 'smartphone', '#00ACC1', 'cat_communication', 1),
    _l2('cat_communication_landline', 'category_communication_landline', 'phone', '#00ACC1', 'cat_communication', 2),
    _l2('cat_communication_internet', 'category_communication_internet', 'wifi', '#00ACC1', 'cat_communication', 3),
    _l2('cat_communication_broadcast', 'category_communication_broadcast', 'live_tv', '#00ACC1', 'cat_communication', 4),
    _l2('cat_communication_info', 'category_communication_info', 'info', '#00ACC1', 'cat_communication', 5),
    _l2('cat_communication_delivery', 'category_communication_delivery', 'local_shipping', '#00ACC1', 'cat_communication', 6),
    _l2('cat_communication_other', 'category_communication_other', 'more_horiz', '#00ACC1', 'cat_communication', 99),

    // §10.14 Housing
    _l2('cat_housing_rent', 'category_housing_rent', 'apartment', '#795548', 'cat_housing', 1),
    _l2('cat_housing_mortgage', 'category_housing_mortgage', 'real_estate_agent', '#795548', 'cat_housing', 2),
    _l2('cat_housing_management', 'category_housing_management', 'corporate_fare', '#795548', 'cat_housing', 3),
    _l2('cat_housing_furniture', 'category_housing_furniture', 'chair', '#795548', 'cat_housing', 4),
    _l2('cat_housing_appliances', 'category_housing_appliances', 'kitchen', '#795548', 'cat_housing', 5),
    _l2('cat_housing_renovation', 'category_housing_renovation', 'construction', '#795548', 'cat_housing', 6),
    _l2('cat_housing_insurance', 'category_housing_insurance', 'shield', '#795548', 'cat_housing', 7),
    _l2('cat_housing_other', 'category_housing_other', 'more_horiz', '#795548', 'cat_housing', 99),

    // §10.9 Car & Motorcycle
    _l2('cat_car_fuel', 'category_car_fuel', 'local_gas_station', '#455A64', 'cat_car', 1),
    _l2('cat_car_parking', 'category_car_parking', 'local_parking', '#455A64', 'cat_car', 2),
    _l2('cat_car_toll', 'category_car_toll', 'toll', '#455A64', 'cat_car', 3),
    _l2('cat_car_loan', 'category_car_loan', 'payments', '#455A64', 'cat_car', 4),
    _l2('cat_car_insurance', 'category_car_insurance', 'security', '#455A64', 'cat_car', 5),
    _l2('cat_car_tax', 'category_car_tax', 'receipt_long', '#455A64', 'cat_car', 6),
    _l2('cat_car_maintenance', 'category_car_maintenance', 'build', '#455A64', 'cat_car', 7),
    _l2('cat_car_other', 'category_car_other', 'more_horiz', '#455A64', 'cat_car', 99),

    // §10.3 Taxes & Social Security
    _l2('cat_tax_income', 'category_tax_income', 'receipt', '#5D4037', 'cat_tax', 1),
    _l2('cat_tax_pension', 'category_tax_pension', 'elderly', '#5D4037', 'cat_tax', 2),
    _l2('cat_tax_health_insurance', 'category_tax_health_insurance', 'health_and_safety', '#5D4037', 'cat_tax', 3),
    _l2('cat_tax_other', 'category_tax_other', 'more_horiz', '#5D4037', 'cat_tax', 99),

    // §10.2 Insurance (4 L2s)
    _l2('cat_insurance_general', 'category_insurance_general', 'security', '#827717', 'cat_insurance', 0),
    _l2('cat_insurance_life', 'category_insurance_life', 'favorite', '#827717', 'cat_insurance', 1),
    _l2('cat_insurance_medical', 'category_insurance_medical', 'medical_services', '#827717', 'cat_insurance', 2),
    _l2('cat_insurance_other', 'category_insurance_other', 'more_horiz', '#827717', 'cat_insurance', 99),

    // §10.8 Special Expenses (7 L2s)
    _l2('cat_special_general', 'category_special_general', 'star', '#AD1457', 'cat_special', 0),
    _l2('cat_special_furniture', 'category_special_furniture', 'weekend', '#AD1457', 'cat_special', 1),
    _l2('cat_special_housing', 'category_special_housing', 'home_repair_service', '#AD1457', 'cat_special', 2),
    _l2('cat_special_wedding', 'category_special_wedding', 'favorite_border', '#AD1457', 'cat_special', 3),
    _l2('cat_special_fertility', 'category_special_fertility', 'child_friendly', '#AD1457', 'cat_special', 4),
    _l2('cat_special_nursing', 'category_special_nursing', 'accessible', '#AD1457', 'cat_special', 5),
    _l2('cat_special_other', 'category_special_other', 'more_horiz', '#AD1457', 'cat_special', 99),

    // §10.11 Other
    _l2('cat_other_advances', 'category_other_advances', 'swap_horiz', '#607D8B', 'cat_other_expense', 1),
    _l2('cat_other_remittance', 'category_other_remittance', 'send', '#607D8B', 'cat_other_expense', 2),
    _l2('cat_other_allowance', 'category_other_allowance', 'wallet', '#607D8B', 'cat_other_expense', 3),
    _l2('cat_other_business', 'category_other_business', 'business_center', '#607D8B', 'cat_other_expense', 4),
    _l2('cat_other_debt', 'category_other_debt', 'money_off', '#607D8B', 'cat_other_expense', 5),
    _l2('cat_other_misc', 'category_other_misc', 'category', '#607D8B', 'cat_other_expense', 6),
    _l2('cat_other_unclassified', 'category_other_unclassified', 'help_outline', '#607D8B', 'cat_other_expense', 7),
    _l2('cat_other_other', 'category_other_other', 'more_horiz', '#607D8B', 'cat_other_expense', 99),
  ];

  // ─── Income L1 ───

  static final List<Category> _incomeL1 = [
    _l1('cat_salary', 'category_salary', 'account_balance', '#4CAF50', 1),
    _l1('cat_bonus', 'category_bonus', 'stars', '#FFC107', 2),
    _l1('cat_investment', 'category_investment', 'trending_up', '#009688', 3),
    _l1('cat_other_income', 'category_other_income', 'attach_money', '#8BC34A', 99),
  ];

  // ─── Default Ledger Configs (expense L1 only) ───
  //
  // Default assignment rationale:
  //   survival = necessities (food, housing, utilities, transport, etc.)
  //   soul     = self-investment / enjoyment (hobbies, education, etc.)
  //
  // Users can change any L1's type in Settings.

  static final List<CategoryLedgerConfig> _defaultLedgerConfigs = [
    _config('cat_food', LedgerType.survival),
    _config('cat_daily', LedgerType.survival),
    _config('cat_transport', LedgerType.survival),
    _config('cat_hobbies', LedgerType.soul),
    _config('cat_clothing', LedgerType.survival),
    _config('cat_social', LedgerType.survival),
    _config('cat_health', LedgerType.survival),
    _config('cat_education', LedgerType.soul),
    _config('cat_cash_card', LedgerType.survival),
    _config('cat_utilities', LedgerType.survival),
    _config('cat_communication', LedgerType.survival),
    _config('cat_housing', LedgerType.survival),
    _config('cat_car', LedgerType.survival),
    _config('cat_tax', LedgerType.survival),
    _config('cat_insurance', LedgerType.survival),
    _config('cat_special', LedgerType.survival),
    _config('cat_asset', LedgerType.soul),
    _config('cat_other_expense', LedgerType.survival),
    _config('cat_uncategorized', LedgerType.survival),
  ];

  // ─── Factory helpers ───

  static Category _l1(
    String id, String name, String icon, String color, int sortOrder,
  ) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: color,
        level: 1,
        isSystem: true,
        sortOrder: sortOrder,
        createdAt: _epoch,
      );

  static Category _l2(
    String id, String name, String icon, String color,
    String parentId, int sortOrder,
  ) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: color,
        parentId: parentId,
        level: 2,
        isSystem: true,
        sortOrder: sortOrder,
        createdAt: _epoch,
      );

  static CategoryLedgerConfig _config(String categoryId, LedgerType type) =>
      CategoryLedgerConfig(
        categoryId: categoryId,
        ledgerType: type,
        updatedAt: _epoch,
      );
}
```

**Step 4: Run code generation and tests**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/unit/shared/constants/default_categories_test.dart
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/shared/constants/default_categories.dart \
        test/unit/shared/constants/default_categories_test.dart
git commit -m "feat(category): update default categories to PRD §10 (19 L1 + L2s)"
```

### L1 ↔ PRD §10.0 Cross-Reference

| sortOrder | ID | PRD ja | PRD en | Default Ledger |
|---|---|---|---|---|
| 1 | cat_food | 食費 | Food | survival |
| 2 | cat_daily | 日用品 | Daily Necessities | survival |
| 3 | cat_transport | 交通費 | Transport | survival |
| 4 | cat_hobbies | 趣味・娯楽 | Hobbies & Entertainment | **soul** |
| 5 | cat_clothing | 衣服・美容 | Clothing & Beauty | survival |
| 6 | cat_social | 交際費 | Socializing | survival |
| 7 | cat_health | 健康・医療 | Health & Medical | survival |
| 8 | cat_education | 教育・教養 | Education & Self-Improvement | **soul** |
| 9 | cat_cash_card | 現金・カード | Cash & Card | survival |
| 10 | cat_utilities | 水道・光熱費 | Utilities | survival |
| 11 | cat_communication | 通信費 | Communication | survival |
| 12 | cat_housing | 住宅 | Housing | survival |
| 13 | cat_car | 車・バイク | Car & Motorcycle | survival |
| 14 | cat_tax | 税・社会保障 | Taxes & Social Security | survival |
| 15 | cat_insurance | 保険 | Insurance | survival |
| 16 | cat_special | 特別な支出 | Special Expenses | survival |
| 17 | cat_asset | 資産形成 | Asset Building | **soul** |
| 18 | cat_other_expense | その他 | Other | survival |
| 19 | cat_uncategorized | 未分類 | Uncategorized | survival |

---

## Task 12: Update SeedCategoriesUseCase

**Files:**
- Modify: `lib/application/accounting/seed_categories_use_case.dart`
- Modify: `test/unit/application/accounting/seed_categories_use_case_test.dart`

**Step 1: Update use case to also seed ledger configs**

```dart
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../shared/constants/default_categories.dart';
import '../../shared/utils/result.dart';

class SeedCategoriesUseCase {
  SeedCategoriesUseCase({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  })  : _categoryRepo = categoryRepository,
        _configRepo = ledgerConfigRepository;

  final CategoryRepository _categoryRepo;
  final CategoryLedgerConfigRepository _configRepo;

  Future<Result<void>> execute() async {
    final existing = await _categoryRepo.findAll();
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    await _categoryRepo.insertBatch(DefaultCategories.all);
    await _configRepo.upsertBatch(DefaultCategories.defaultLedgerConfigs);
    return Result.success(null);
  }
}
```

**Step 2: Update tests**

Update mocks to include `CategoryLedgerConfigRepository`. Verify `upsertBatch` is called with default configs.

**Step 3: Run tests, commit**

```bash
git commit -m "feat(category): seed ledger configs alongside categories"
```

---

## Task 13: Update Providers

**Files:**
- Modify: `lib/features/accounting/presentation/providers/repository_providers.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart`

**Step 1: Add CategoryLedgerConfigRepository provider**

In `repository_providers.dart`:

```dart
@riverpod
CategoryLedgerConfigRepository categoryLedgerConfigRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = CategoryLedgerConfigDao(database);
  return CategoryLedgerConfigRepositoryImpl(dao: dao);
}
```

**Step 2: Add ResolveLedgerTypeService provider**

In `use_case_providers.dart`:

```dart
@riverpod
ResolveLedgerTypeService resolveLedgerTypeService(Ref ref) {
  return ResolveLedgerTypeService(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}
```

**Step 3: Update SeedCategoriesUseCase provider**

```dart
@riverpod
SeedCategoriesUseCase seedCategoriesUseCase(Ref ref) {
  return SeedCategoriesUseCase(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}
```

**Step 4: Run code generation and tests**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
```

**Step 5: Commit**

```bash
git commit -m "feat(category): wire up ledger config providers"
```

**Checkpoint (after Tasks 11–13):** `flutter analyze && flutter test` — new defaults + providers wired, code gen passes.

---

## Task 14: Fix Application Layer References (accounting, settings)

**Files:**
- `lib/application/accounting/create_transaction_use_case.dart`
- `lib/application/settings/export_backup_use_case.dart`
- `lib/application/settings/import_backup_use_case.dart`
- `lib/application/settings/clear_all_data_use_case.dart`
- Corresponding test files

**Step 1: Fix each file**

For each file:
- Replace `category.type` references with `resolveLedgerTypeService.resolve(categoryId)` or remove
- Replace `findByType(...)` calls with `findByLevel(1)` or `findActive()` + filter
- Replace `findWithBudget()` calls (remove or replace)
- Update tests accordingly

**Step 2: Run checkpoint**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Both must pass with zero issues before proceeding.

**Step 3: Commit**

```bash
git commit -m "fix(accounting,settings): update references to removed Category.type"
```

---

## Task 15: Fix Analytics & Presentation References

**Files:**
- `lib/application/analytics/demo_data_service.dart`
- `lib/application/analytics/get_budget_progress_use_case.dart`
- `lib/features/accounting/presentation/screens/transaction_form_screen.dart`
- `lib/features/analytics/presentation/providers/analytics_providers.dart`
- Corresponding test files

**Step 1: Fix each file**

Same approach as Task 14:
- Replace `category.type` references
- Replace `findByType(...)` / `findWithBudget()` calls
- Update tests

**Step 2: Run checkpoint**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Both must pass with zero issues.

**Step 3: Commit**

```bash
git commit -m "fix(analytics,presentation): update references to removed Category.type"
```

---

## Task 16: Final Verification

**Step 1: Full suite**

```bash
flutter analyze
flutter test
```

Both must pass with zero issues.

**Step 2: Commit any remaining fixes**

---

## Summary

**16 tasks, 6 checkpoints, ~12 commits.**

| Task | Component | File | Status |
|------|-----------|------|--------|
| 1 | Category model (v2) | `lib/features/accounting/domain/models/category.dart` | Modified |
| 2 | CategoryLedgerConfig model | `lib/features/accounting/domain/models/category_ledger_config.dart` | New |
| 3 | Categories table (v2) | `lib/data/tables/categories_table.dart` | Modified |
| 4 | CategoryLedgerConfigs table | `lib/data/tables/category_ledger_configs_table.dart` | New |
| 5 | AppDatabase (v5) | `lib/data/app_database.dart` | Modified |
| 6 | CategoryDao (v2) | `lib/data/daos/category_dao.dart` | Modified |
| 7 | CategoryLedgerConfigDao | `lib/data/daos/category_ledger_config_dao.dart` | New |
| 8 | CategoryRepository (v2) | `lib/features/accounting/domain/repositories/category_repository.dart` | Modified |
| 9 | CategoryLedgerConfigRepository | `lib/features/accounting/domain/repositories/category_ledger_config_repository.dart` | New |
| 10 | ResolveLedgerTypeService | `lib/application/dual_ledger/resolve_ledger_type_service.dart` | New |
| 11 | Default categories (v2) | `lib/shared/constants/default_categories.dart` | Modified |
| 12 | SeedCategoriesUseCase (v2) | `lib/application/accounting/seed_categories_use_case.dart` | Modified |
| 13 | Provider wiring | `repository_providers.dart`, `use_case_providers.dart` | Modified |
| 14 | Fix accounting/settings refs | Various application + test files | Modified |
| 15 | Fix analytics/presentation refs | Various presentation + test files | Modified |
| 16 | Final verification | — | — |

### Verification Checkpoints

| After | Scope | What it catches |
|-------|-------|----------------|
| Tasks 1–2 | Domain models | Freezed compile, existing tests still pass |
| Tasks 3–5 | DB schema | Table/migration compile, code gen |
| Tasks 6–8 | DAO + repo | Data layer integration, DAO unit tests |
| Tasks 9–10 | Service layer | New repos + service, mocked unit tests |
| Tasks 11–13 | Defaults + providers | Seed data consistency, provider wiring |
| Tasks 14–15 | Dependent fixups | Full regression — zero analyze warnings, all tests green |
