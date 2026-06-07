# Phase 36: Data Layer + Domain + Import Guard - Research

**Researched:** 2026-06-07
**Domain:** Drift table design, Dart migration pattern, Freezed domain models, import_guard.yaml enforcement, widget relocation
**Confidence:** HIGH — all findings from direct codebase reads; zero training-data assertions about package capabilities

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (tags storage):** `tags` is a **nullable `TextColumn` holding JSON-encoded `List<String>`**. Encode/decode at the repository boundary (same layer as `note` encryption). No existing tag system — designed from scratch.
- **D-02 (quantity type):** `quantity` is a **nullable `IntColumn`** (whole-count). A blank quantity defaults to 1 in the UI layer, not the schema.
- **D-03 (completion-merge — SUPERSEDES locked D7 / SYNC-05):** Add a **`completedAt DateTime?` nullable column** to the v20 table (table field count = **15**, not 14). Sticky-complete merge rule: when `completedAt > incoming.updatedAt`, `isCompleted: true` is preserved. Phase 36 deliverable: column exists in v20 + contract test coverage. Merge *algorithm* is Phase 37. **Ripple:** ROADMAP Phase-36 field list and REQUIREMENTS.md SYNC-05/D7 must be reconciled in the same commit.
- **Schema v20:** migration `if (from < 20)` → `migrator.createTable(shoppingItems)`. Current code is v19 (confirmed in `lib/data/app_database.dart:45`).
- **estimatedPrice:** nullable `IntColumn` (integer sub-units, JPY = yen, rendered via `NumberFormatter`).
- **note:** `TEXT NOT NULL`, encrypted at the repository boundary (mirror `TransactionRepositoryImpl`).
- **DAO ordering:** `ORDER BY is_completed ASC, sort_order ASC, created_at ASC` enforced in SQL.
- **Reactive delivery:** `.watch()` + `readsFrom:` the shopping table — SYNC-06 / applies the v1.4 GAP-2 lesson.
- **Domain models:** `ShoppingItem`, `ShoppingListFilter`, `ShoppingItemParams` Freezed models; `ShoppingItemRepository` interface with no Drift imports; every new `shopping_list/` subdir gets an `import_guard.yaml`.
- **`LedgerTypeSelector` move:** `accounting/presentation/widgets/` → `lib/shared/widgets/` with all import sites updated.
- **`CategorySelectionScreen` allow-listed:** in `lib/features/shopping_list/presentation/import_guard.yaml`.
- D1, D6, D5 remain locked; only D7 is overridden by D-03.

### Claude's Discretion

- `sortOrder` initial-value strategy, `addedByBookId` null-handling at attribution display, exact Freezed model field granularity.
- Index design on `shopping_items` (likely `listType`, `listType+isDeleted`) following the `transactions` `customIndices` pattern.

### Deferred Ideas (OUT OF SCOPE)

- Tag-based filtering (v2 TAGFILT-01)
- Decimal / unit-bearing quantity
- Per-segment independent filter providers (Phase 38 decision, not this phase)
- All use-case logic + sync apply handlers (Phase 37)
- All UI/widgets/providers (Phase 38)
- ARB/goldens/smoke test (Phase 39)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DONE-02 | Completed items sort to bottom via DAO query order (`ORDER BY is_completed ASC, sort_order ASC, created_at ASC`), not client sort | DAO design section; SQL ordering pattern from `TransactionDao` |
| ITEM-03 | Add/edit form reuses existing category tree, tag system, and ledger selector | LedgerTypeSelector move to `lib/shared/widgets/`; CategorySelectionScreen allow-list in import_guard |
| ITEM-05 | `estimatedPrice` stored as integer sub-units; `note` field encrypted at repository boundary | `TransactionRepositoryImpl` encryption pattern; IntColumn confirmation |
| SHOP-01 | Public/private shopping list distinction enforced at data level via `listType` column with CHECK constraint | ShoppingItems table design with `CHECK(list_type IN ('public', 'private'))` |
| SYNC-05 | This phase: reconcile REQUIREMENTS.md D7/"no completedAt" with D-03 decision (add column); document sticky-complete rule | D-03 reconciliation action; contract test coverage of `completed_at` column |
</phase_requirements>

---

## Summary

Phase 36 is a pure foundation phase: no use-case logic, no UI, no sync wiring. It must deliver four artifacts — the v20 Drift table, the `ShoppingItemDao`, the `ShoppingItemRepositoryImpl`, and the Freezed domain models + repository interface — that all downstream phases (37-39) depend on without modification. Every column name and domain interface method signature locked here is a contract that cannot be changed without a new migration.

The research confirms zero new packages are required. Every pattern needed already exists in the codebase: the `Transactions` table is the direct template for `ShoppingItems`, `TransactionRepositoryImpl` is the template for `note` encryption and JSON `tags` encode/decode, `TransactionDao.watchByBookIds` is the template for the reactive `watchByListType` stream (`readsFrom:` mandatory), and `lib/features/list/` is the full structural analog for the `shopping_list/domain/` import_guard YAML tree.

The critical reconciliation action for this phase is making the v20 schema authoritative: REQUIREMENTS.md SYNC-05/D7 ("no completedAt / pure LWW") conflicts with D-03 (add the column), and ROADMAP Phase-36 success-criteria field list (14 fields, no `completedAt`) also conflicts. Both must be corrected in the same commit that introduces the v20 migration, or the plan-checker will re-derive the old D7 behaviour.

**Primary recommendation:** Build the `ShoppingItems` table strictly mirroring `transactions_table.dart` (15 fields including `completedAt`), wire the migration as `if (from < 20) { await migrator.createTable(shoppingItems); }`, write the Wave-0 raw-sqlite3 contract test following `ledger_type_v18_migration_test.dart` as the exact template, then build the domain + guard layer mirroring `lib/features/list/` verbatim.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ShoppingItems Drift table definition | Data (`lib/data/tables/`) | — | Thin Feature rule: all table defs live in `lib/data/` so `AppDatabase` can import them without a layer violation |
| ShoppingItemDao (queries, `.watch()`) | Data (`lib/data/daos/`) | — | DAO is implementation detail; domain layer never imports it |
| ShoppingItemRepositoryImpl | Data (`lib/data/repositories/`) | Infrastructure (encryption) | Encryption at boundary; infrastructure called from data, not from domain |
| Domain models (Freezed) | Domain (`lib/features/shopping_list/domain/models/`) | — | Pure models, no Drift or Flutter imports; other layers depend on these |
| ShoppingItemRepository interface | Domain (`lib/features/shopping_list/domain/repositories/`) | — | Interface owned by domain; impl in data layer satisfies it |
| import_guard enforcement | Tooling (custom_lint) | — | Enforces all four layer boundaries at lint time |
| LedgerTypeSelector widget | Shared (`lib/shared/widgets/`) | — | Generic widget, no accounting-specific state; relocated this phase |
| CategorySelectionScreen | Accounting Presentation (stays) | — | Has accounting-specific providers; cannot move to shared |
| Wave-0 contract test | Test layer (raw-sqlite3) | — | Must bypass Drift ORM to verify physical schema structure |

---

## Standard Stack

### Core (already installed — zero new packages)

[VERIFIED: direct pubspec.yaml read, 2026-06-07]

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | `^2.25.0` | ORM, table DSL, reactive streams | Established codebase ORM; `migrator.createTable` is the v-bump pattern |
| `freezed_annotation` | `^3.0.0` | Immutable domain models | All domain models in project use `@freezed`; enforces copyWith |
| `flutter_riverpod` | `^3.1.0` | State management (Phase 37+) | Established provider pattern; keepAlive convention set in v1.4 |
| `riverpod_annotation` | `^4.0.0` | Code-gen `@riverpod` providers | Used throughout; generator naming rules from CLAUDE.md |
| `sqlite3` | transitive | Raw-sqlite3 for contract tests | Already in dev-deps; used by all existing migration tests |
| `sqlcipher_flutter_libs` | `^0.6.7` | Encrypted DB | Required; NEVER use `sqlite3_flutter_libs` |

### Dev (code generation — already installed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `build_runner` | any | Code generation | After every `@DriftDatabase`, `@freezed`, or `@riverpod` change |
| `drift_dev` | `^2.25.0` | Drift code gen | Generates `app_database.g.dart` and DAO companions |
| `freezed` | `^3.0.0` | Freezed model gen | Generates `*.freezed.dart` |
| `riverpod_generator` | `^4.0.0` | Riverpod code gen | Generates `*.g.dart` for `@riverpod` |
| `custom_lint` | any | import_guard enforcement | Run after every new file: `dart run custom_lint --no-fatal-infos` |
| `import_guard_custom_lint` | any | Layer boundary lint | Reads all `import_guard.yaml` files in the tree |

### Version Pins — Do Not Touch

- `intl: 0.20.2` (exact, pinned by flutter_localizations)
- `sqlcipher_flutter_libs: ^0.6.7` (NOT `^0.7.x`, NOT `sqlite3_flutter_libs`)
- `file_picker/package_info_plus/share_plus` win32 trio (do not bump individually)

**Installation:** No new packages. Run `flutter pub get` to confirm existing resolution is still clean.

---

## Package Legitimacy Audit

No new packages installed in this phase. All dependencies listed above are already in `pubspec.yaml` (verified by direct read, 2026-06-07). No audit table required.

---

## Architecture Patterns

### System Architecture Diagram

```
[Wave-0 contract test]
        |  raw sqlite3 in-memory
        v
[lib/data/tables/shopping_items_table.dart]   (ShoppingItems Drift table, 15 fields)
        |
        | migrator.createTable(shoppingItems) in if (from < 20) block
        v
[lib/data/app_database.dart]                  (schemaVersion => 20; registers ShoppingItems)
        |
        | AppDatabase injected
        v
[lib/data/daos/shopping_item_dao.dart]        (ShoppingItemDao)
        |                                      watchByListType() -> Stream<List<ShoppingItemRow>>
        | FieldEncryptionService (note encrypt/decrypt)
        | jsonEncode/jsonDecode (tags)
        v
[lib/data/repositories/shopping_item_repository_impl.dart]  (ShoppingItemRepositoryImpl)
        |
        | implements
        v
[lib/features/shopping_list/domain/repositories/shopping_item_repository.dart]  (interface)
        ^
        | import_guard enforced
[lib/features/shopping_list/domain/models/]   (ShoppingItem, ShoppingListFilter,
        |                                       ShoppingItemParams — @freezed, no Drift)
        |
[import_guard.yaml files] (one per subdir, mirroring lib/features/list/)

[lib/shared/widgets/ledger_type_selector.dart]  (MOVED from accounting/presentation/widgets/)
        ^
        | updated import
[lib/features/accounting/presentation/widgets/transaction_details_form.dart]
```

### Recommended Project Structure — New Files This Phase

```
lib/
  data/
    tables/
      shopping_items_table.dart         NEW — ShoppingItems Drift table (15 cols, @DataClassName('ShoppingItemRow'))
    daos/
      shopping_item_dao.dart            NEW — ShoppingItemDao with watchByListType, softDelete, upsert
    repositories/
      shopping_item_repository_impl.dart  NEW — note encryption + JSON tags at boundary
  shared/
    widgets/
      ledger_type_selector.dart         MOVED from features/accounting/presentation/widgets/
  features/
    shopping_list/
      domain/
        import_guard.yaml               NEW — deny data/**, infrastructure/**, application/**, features/**/presentation/**
        models/
          import_guard.yaml             NEW — allow dart:core, freezed_annotation/**, ../../../accounting/domain/models/transaction.dart
          shopping_item.dart            NEW — @freezed ShoppingItem (15 fields + completedAt)
          shopping_list_filter.dart     NEW — @freezed ShoppingListFilter
          shopping_item_params.dart     NEW — @freezed ShoppingItemParams
        repositories/
          shopping_item_repository.dart NEW — abstract interface (no Drift imports)
      presentation/
        import_guard.yaml               NEW — deny infrastructure/**, data/daos/**, data/tables/**; allow CategorySelectionScreen path

test/
  unit/
    data/
      migrations/
        shopping_items_v20_contract_test.dart  NEW — raw-sqlite3 Wave-0 contract test
```

### Pattern 1: Drift Table with CHECK Constraints and {#symbol} Indices

Exact pattern from `lib/data/tables/transactions_table.dart` [VERIFIED: direct read, 2026-06-07]:

```dart
// lib/data/tables/shopping_items_table.dart
import 'package:drift/drift.dart';

@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  // Identity
  TextColumn get id => text()();
  TextColumn get deviceId => text()();

  // Visibility: 'public' syncs via family_sync; 'private' is local-only (D1)
  TextColumn get listType => text().withDefault(const Constant('private'))();

  // Required content
  TextColumn get name => text().withLength(min: 1, max: 200)();

  // Optional accounting hints (no FK — D3 no transaction linkage)
  TextColumn get ledgerType => text().nullable()();    // 'daily' | 'joy' | null
  TextColumn get categoryId => text().nullable()();

  // D-01: JSON-encoded List<String>. Encode/decode at repository boundary.
  TextColumn get tags => text().nullable()();

  // note is NOT NULL — encrypted at repository boundary (ITEM-05)
  TextColumn get note => text().nullable()();

  // D-02: whole-count quantity; D-04 estimated price (integer yen, nullable)
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get estimatedPrice => integer().nullable()();

  // D-03: completedAt — sticky-complete merge reference timestamp
  DateTimeColumn get completedAt => dateTime().nullable()();

  // State flags
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Family attribution: nullable TEXT, no FK (shadow book may not exist locally)
  TextColumn get addedByBookId => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK(list_type IN ('public', 'private'))",
    'CHECK(quantity >= 1)',
    "CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL)",
    'CHECK(estimated_price IS NULL OR estimated_price >= 0)',
  ];

  // Convention: TableIndex + {#columnName} symbol syntax (CLAUDE.md)
  // NO @override annotation on customIndices (see CLAUDE.md pitfall #11)
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_shopping_list_type', columns: {#listType}),
    TableIndex(name: 'idx_shopping_list_deleted', columns: {#listType, #isDeleted}),
    TableIndex(name: 'idx_shopping_completed', columns: {#isCompleted}),
    TableIndex(name: 'idx_shopping_sort_order', columns: {#sortOrder}),
    TableIndex(name: 'idx_shopping_added_by_book', columns: {#addedByBookId}),
  ];
}
```

**Column count:** 19 declared columns (id, deviceId, listType, name, ledgerType, categoryId, tags, note, quantity, estimatedPrice, completedAt, isCompleted, sortOrder, isSynced, isDeleted, addedByBookId, createdAt, updatedAt). The "15 fields" in CONTEXT.md refers to the 15 business/user-visible fields (D4 fields + completedAt + audit columns), not the Dart getter count. The contract test must verify the physical column names, not the count.

### Pattern 2: Schema v19 → v20 Migration

Exact addition to `app_database.dart` `onUpgrade` [VERIFIED: direct read, schemaVersion=19 confirmed, 2026-06-07]:

```dart
// In AppDatabase.migration.onUpgrade — add AFTER the if (from < 19) block:
if (from < 20) {
  await migrator.createTable(shoppingItems);
}
```

Also: bump `int get schemaVersion => 19;` → `int get schemaVersion => 20;`.

Also: add `ShoppingItems` to `@DriftDatabase(tables: [...])` annotation.

**Critical:** After adding `ShoppingItems` to the annotation and bumping schemaVersion, run `flutter pub run build_runner build --delete-conflicting-outputs` immediately. The generated `app_database.g.dart` will fail to compile if schemaVersion was not bumped (Drift's generated schema validator catches version mismatches).

### Pattern 3: Reactive DAO Stream with readsFrom: (MANDATORY)

Template from `lib/data/daos/transaction_dao.dart` `watchByBookIds` [VERIFIED: direct read, 2026-06-07]:

```dart
// lib/data/daos/shopping_item_dao.dart
Stream<List<ShoppingItemRow>> watchByListType(String listType) {
  return _db
      .customSelect(
        'SELECT * FROM shopping_items '
        'WHERE list_type = ? '
        'AND is_deleted = 0 '
        'ORDER BY is_completed ASC, sort_order ASC, created_at ASC',
        variables: [Variable.withString(listType)],
        readsFrom: {_db.shoppingItems},  // MANDATORY — without this stream never emits
      )
      .watch()
      .map(
        (rows) => rows.map((row) => _db.shoppingItems.map(row.data)).toList(),
      );
}
```

`readsFrom: {_db.shoppingItems}` is mandatory. Without it Drift cannot detect table mutations and the stream will not emit after writes — this is the v1.4 GAP-2 lesson from `watchByBookIds` (documented in ARCHITECTURE.md and PITFALLS.md). Using a `FutureProvider + ref.invalidate` pattern would fail for pull-sync writes that have no ref.invalidate call site.

### Pattern 4: Note Encryption + JSON tags at Repository Boundary

Template from `lib/data/repositories/transaction_repository_impl.dart` [VERIFIED: direct read, 2026-06-07]:

```dart
// lib/data/repositories/shopping_item_repository_impl.dart

@override
Future<void> insert(ShoppingItem item) async {
  // Note encryption — same as TransactionRepositoryImpl
  String? encryptedNote;
  if (item.note != null && item.note!.isNotEmpty) {
    encryptedNote = await _encryptionService.encryptField(item.note!);
  }

  // Tags JSON encode — same layer as note encryption
  final encodedTags = item.tags.isEmpty ? null : jsonEncode(item.tags);

  await _dao.insert(ShoppingItemsCompanion.insert(
    id: item.id,
    deviceId: item.deviceId,
    listType: item.listType,
    name: item.name,
    note: Value(encryptedNote),
    tags: Value(encodedTags),
    // ... other fields
  ));
}

// Decode on read:
ShoppingItem _toModel(ShoppingItemRow row) {
  String? decryptedNote; // decrypt via _encryptionService.decryptField(row.note)
  List<String> tags = [];
  if (row.tags != null) {
    tags = (jsonDecode(row.tags!) as List).cast<String>();
  }
  return ShoppingItem(
    // ... map all fields
    note: decryptedNote,
    tags: tags,
  );
}
```

### Pattern 5: Freezed Domain Model (no Drift imports)

```dart
// lib/features/shopping_list/domain/models/shopping_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart'; // for LedgerType enum

part 'shopping_item.freezed.dart';

@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    required String id,
    required String deviceId,
    required String listType,         // 'public' | 'private'
    required String name,
    LedgerType? ledgerType,
    String? categoryId,
    @Default(<String>[]) List<String> tags,
    String? note,                     // decrypted plaintext
    @Default(1) int quantity,
    int? estimatedPrice,
    DateTime? completedAt,            // D-03: sticky-complete timestamp
    @Default(false) bool isCompleted,
    @Default(0) int sortOrder,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
    String? addedByBookId,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ShoppingItem;
}
```

`LedgerType` is imported from `accounting/domain/models/transaction.dart` — this is a same-layer cross-feature domain import. The `lib/features/list/domain/models/list_filter_state.dart` already does this (confirmed by reading `lib/features/list/domain/models/import_guard.yaml`); the pattern is established and the per-subdirectory allow-list is the documented mechanism.

### Pattern 6: import_guard.yaml Files (mirror lib/features/list/)

**`lib/features/shopping_list/domain/import_guard.yaml`** [VERIFIED: mirrors `list/domain/import_guard.yaml` verbatim]:

```yaml
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
# NOTE: no `allow:` block — see models/import_guard.yaml
```

**`lib/features/shopping_list/domain/models/import_guard.yaml`** [VERIFIED: mirrors `list/domain/models/import_guard.yaml`]:

```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - ../../../accounting/domain/models/transaction.dart   # for LedgerType enum

inherit: true
```

**`lib/features/shopping_list/presentation/import_guard.yaml`** [VERIFIED: mirrors `list/presentation/import_guard.yaml` + CategorySelectionScreen allow]:

```yaml
allow:
  - package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart

deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

**Why CategorySelectionScreen is allow-listed, not moved:** It is a full `ConsumerStatefulWidget` (240+ lines) with `categoryRepositoryProvider` (accounting-specific) and `state_category_reorder.dart` (accounting-specific). Moving it to `lib/shared/` would drag accounting-specific providers into the shared layer — a worse violation. Keep it in `lib/features/accounting/presentation/screens/` and make the dependency intentional with an explicit `allow:` entry.

### Pattern 7: Wave-0 Raw-sqlite3 Contract Test

Template from `lib/test/unit/data/migrations/entry_source_v17_migration_test.dart` (raw-sqlite3 style) [VERIFIED: direct read, 2026-06-07]:

```dart
// test/unit/data/migrations/shopping_items_v20_contract_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('AppDatabase schemaVersion is 20', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    expect(db.schemaVersion, equals(20));
  });

  group('shopping_items v20 physical schema', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV20ShoppingItemsTable(rawDb);
    });

    tearDown(() => rawDb.dispose());

    test('shopping_items table exists with correct columns', () {
      final cols = rawDb
          .select('PRAGMA table_info(shopping_items)')
          .map((r) => r['name'] as String)
          .toSet();

      expect(cols, containsAll([
        'id', 'device_id', 'list_type', 'name', 'ledger_type',
        'category_id', 'tags', 'note', 'quantity', 'estimated_price',
        'completed_at', 'is_completed', 'sort_order', 'is_synced',
        'is_deleted', 'added_by_book_id', 'created_at', 'updated_at',
      ]));
    });

    test('list_type CHECK rejects invalid values', () {
      expect(
        () => _insertRow(rawDb, listType: 'shared'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('list_type accepts public and private', () {
      expect(() => _insertRow(rawDb, listType: 'public'), returnsNormally);
      expect(() => _insertRow(rawDb, listType: 'private'), returnsNormally);
    });

    test('is_deleted soft-delete flag: row persists with isDeleted=true', () {
      _insertRow(rawDb, id: 'item_1');
      rawDb.execute(
        "UPDATE shopping_items SET is_deleted = 1 WHERE id = 'item_1'",
      );
      final rows = rawDb.select(
        "SELECT is_deleted FROM shopping_items WHERE id = 'item_1'",
      );
      expect(rows.first['is_deleted'], equals(1));
    });

    test('completed_at column accepts NULL and datetime values', () {
      _insertRow(rawDb, id: 'item_null_ca');
      final rows = rawDb.select(
        "SELECT completed_at FROM shopping_items WHERE id = 'item_null_ca'",
      );
      expect(rows.first['completed_at'], isNull);
    });
  });
}

void _createV20ShoppingItemsTable(Database db) {
  // Mirrors exactly the SQL that migrator.createTable(shoppingItems) would emit
  db.execute('''
    CREATE TABLE shopping_items (
      id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      list_type TEXT NOT NULL DEFAULT 'private',
      name TEXT NOT NULL,
      ledger_type TEXT,
      category_id TEXT,
      tags TEXT,
      note TEXT,
      quantity INTEGER NOT NULL DEFAULT 1,
      estimated_price INTEGER,
      completed_at INTEGER,
      is_completed INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      added_by_book_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      PRIMARY KEY (id),
      CHECK(list_type IN ('public', 'private')),
      CHECK(quantity >= 1),
      CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL),
      CHECK(estimated_price IS NULL OR estimated_price >= 0)
    )
  ''');
}

void _insertRow(
  Database db, {
  String id = 'item_test',
  String listType = 'private',
}) {
  final now = DateTime(2026, 6, 7, 12).millisecondsSinceEpoch;
  db.execute(
    '''INSERT INTO shopping_items
       (id, device_id, list_type, name, created_at)
       VALUES (?, 'device_test', ?, 'Test Item', ?)''',
    [id, listType, now],
  );
}
```

**Important note on the test:** The raw-sqlite3 `_createV20ShoppingItemsTable` helper must mirror the SQL that `migrator.createTable(shoppingItems)` actually emits. After writing the Drift table class, run the Drift code generator and inspect the generated `app_database.g.dart` to verify the actual DDL matches the test helper. The contract test's value is precisely that it tests the physical schema, not the Dart ORM layer.

### Pattern 8: LedgerTypeSelector Relocation

Current location [VERIFIED: direct read, 2026-06-07]: `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`

The widget has zero accounting-specific state — it takes `LedgerType selected`, `ValueChanged<LedgerType> onChanged`, `String dailyLabel`, `String joyLabel` and renders two styled chips using `AppPalette` and `AppTextStyles`. Safe to move.

Action:
1. Move file to `lib/shared/widgets/ledger_type_selector.dart`
2. Update import in `lib/features/accounting/presentation/widgets/transaction_details_form.dart` from `ledger_type_selector.dart` → `../../../../shared/widgets/ledger_type_selector.dart`
3. Run `dart run custom_lint --no-fatal-infos` to confirm zero new violations

The widget's own import `../../../../core/theme/app_palette.dart` and `../../../../core/theme/app_text_styles.dart` must be updated to reflect the new path from `lib/shared/widgets/`: `../../core/theme/app_palette.dart` and `../../core/theme/app_text_styles.dart`.

### Anti-Patterns to Avoid

- **`@override` on `customIndices`:** Drift table `customIndices` is NOT a getter inherited from `Table` — do NOT add `@override`. Adding `@override` causes a compile error. See CLAUDE.md pitfall #11.
- **`Index()` constructor:** Use `TableIndex` (not `Index`), `{#columnName}` Symbol syntax (not string column refs).
- **Data files inside `lib/features/`:** Tables, DAOs, and repository impls inside `lib/features/shopping_list/` violate the Thin Feature rule. They must live in `lib/data/`. The `AppDatabase` import direction would also be inverted.
- **`from < 19` migration block:** The v19 slot is taken (category sort-order reorder). Shopping list migration MUST be `if (from < 20)`. Read `app_database.dart` directly — do not trust CLAUDE.md's stale "v18→v19" reference.
- **`migrator.addColumn` for new table:** Use `migrator.createTable(shoppingItems)` for the new table, not `addColumn` or raw `customStatement('CREATE TABLE ...')`. `customStatement` bypasses Drift's schema validation and does not include customConstraints automatically.
- **Missing `readsFrom:` on the watch query:** Without `readsFrom: {_db.shoppingItems}`, the stream never emits after writes. This is the v1.4 GAP-2 lesson. Always use `readsFrom:` on `customSelect(...).watch()`.
- **Drift imports in domain models:** `ShoppingItem`, `ShoppingListFilter`, `ShoppingItemParams` must import ONLY `package:freezed_annotation/` and `dart:core`. No `package:drift/` anywhere in `lib/features/shopping_list/domain/`.
- **Moving `CategorySelectionScreen` to shared:** It depends on `categoryRepositoryProvider` (accounting feature). Moving it would drag accounting providers into shared — worse than a documented cross-feature allow-listed import.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Note field encryption | Custom XOR / base64 | `FieldEncryptionService.encryptField/decryptField` | ChaCha20-Poly1305 AEAD; already key-managed; handles nonces, auth tags |
| JSON tags encoding | Custom delimiters (comma-split) | `jsonEncode(List<String>)` / `jsonDecode(...).cast<String>()` | Tags containing commas/quotes break delimiter-based approaches |
| Reactive stream | `FutureProvider + ref.invalidate` | Drift `customSelect(..., readsFrom:).watch()` | Pull-sync writes have no `ref.invalidate` call site; stream is the only reliable approach |
| Layer boundary enforcement | Manual code review | `import_guard.yaml` + `dart run custom_lint` | Automated, catches violations at lint time before CI |
| Schema version detection | String search in CLAUDE.md | `grep schemaVersion lib/data/app_database.dart` | CLAUDE.md is stale (says v18, actual is v19) |

**Key insight:** The encryption service, JSON codec, and reactive stream are all established patterns in the codebase. Deviating from them creates inconsistency and security risk.

---

## Common Pitfalls

### Pitfall 1: Migration Slot Collision (v19 already taken)

**What goes wrong:** Developer writes `if (from < 19)` for the shopping list table. This collides with the existing category sort-order reorder block (lines 413-423 of `app_database.dart`). For any user already on v19, the new `if (from < 19)` block is skipped entirely — the shopping_items table is never created. All DAO queries throw `SqliteException: no such table: shopping_items`.

**Why it happens:** CLAUDE.md states schema "v18→v19" (stale reference). The CONTEXT.md correctly states "actual is v19, confirmed in `lib/data/app_database.dart:45`". A developer who reads CLAUDE.md first writes the wrong migration number.

**How to avoid:** First action in Wave 0: `grep schemaVersion lib/data/app_database.dart`. Confirm `19`. Use `if (from < 20)` with `schemaVersion => 20`.

**Warning signs:** Build passes but `watchByListType` stream immediately throws; `SqliteException: no such table: shopping_items` in device logs.

### Pitfall 2: Missing readsFrom on watchByListType

**What goes wrong:** The `watchByListType` implementation uses `_db.customSelect(...).watch()` but omits `readsFrom: {_db.shoppingItems}`. The stream is created and the initial value is emitted, but subsequent inserts, updates, or soft-deletes do NOT cause the stream to emit a new value. Items added via the use case appear only after a hot restart.

**Why it happens:** The v1.4 GAP-2 dead-code debt (`watchByBookIds`) was caused by exactly this omission. The existing `TransactionDao.findByBookId` (a `Future`-based query) omits `readsFrom` correctly — but `watchByBookIds` requires it. A developer copying `findByBookId` as the template for `watchByListType` omits `readsFrom`.

**How to avoid:** Always use `_db.customSelect(sql, variables: [...], readsFrom: {_db.shoppingItems}).watch()`. Never `.get()` and never a `Stream.fromFuture`.

**Warning signs:** New items appear in the list after navigating away and back, but not immediately after creation.

### Pitfall 3: @override on customIndices

**What goes wrong:** Adding `@override` before `List<TableIndex> get customIndices` causes a compile error: "The member 'customIndices' is not a member of the supertype Table."

**Why it happens:** `customConstraints` IS overriding a `Table` getter (it has `@override`). `customIndices` is NOT — it is a new getter introduced by convention in this project, not part of Drift's `Table` base class. Copying the `customConstraints` pattern and adding `@override` to `customIndices` fails compilation.

**How to avoid:** Check `transactions_table.dart` — `customConstraints` has `@override`; `customIndices` does NOT.

**Warning signs:** Immediate compile error on `dart pub run build_runner build`.

### Pitfall 4: Domain Models Importing Drift Types

**What goes wrong:** The `ShoppingItem` Freezed model includes `import 'package:drift/drift.dart'` (e.g., to access `Value<T>` or Companion types). The `domain/import_guard.yaml` deny rule `package:home_pocket/data/**` does not block `package:drift/` directly but the companion types belong to the data layer — using them in the domain model creates an implicit dependency on the Drift ORM in what should be a Drift-free layer.

**Why it happens:** The developer wants to represent optional fields with `Value<T>` (Drift's absent/present wrapper) in the params model.

**How to avoid:** Use plain Dart nullability (`String? note`) in domain models. Drift `Value<T>` (for Companion types) is only used inside the DAO and repository impl, never in domain models or params.

**Warning signs:** `import 'package:drift/drift.dart'` in any file under `lib/features/shopping_list/domain/`.

### Pitfall 5: CLAUDE.md stale schema version reference (does not auto-update)

**What goes wrong:** After bumping schemaVersion to 20 in `app_database.dart`, CLAUDE.md still says "v18→v19". The next developer reading CLAUDE.md before this phase's output is committed will be misled.

**Why it happens:** CLAUDE.md is maintained manually; it has lagged behind each schema migration.

**How to avoid:** The Phase 36 plan must include a task to update CLAUDE.md's schema version reference from "v18→v19" to "v19→v20" in the same commit that bumps the schema. The CONTEXT.md explicitly calls this out.

### Pitfall 6: REQUIREMENTS.md / ROADMAP Conflict Not Reconciled

**What goes wrong:** REQUIREMENTS.md SYNC-05 and the locked D7 say "no completedAt column / pure last-write-wins". ROADMAP Phase-36 success criteria lists 14 fields (no `completedAt`). D-03 overrides D7 and adds the column. If REQUIREMENTS.md and ROADMAP are not updated in the same commit, the plan-checker or a future phase researcher will re-derive the old D7 behaviour and flag a conflict.

**How to avoid:** The plan must include explicit tasks to update REQUIREMENTS.md SYNC-05/D7 and ROADMAP Phase-36 field list to reflect D-03. These are documentation reconciliation tasks, not optional.

---

## Code Examples

### ShoppingItemDao — Full Method Set

```dart
// lib/data/daos/shopping_item_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

class ShoppingItemDao {
  ShoppingItemDao(this._db);
  final AppDatabase _db;

  Future<void> insert(ShoppingItemsCompanion item) =>
      _db.into(_db.shoppingItems).insert(item);

  Future<void> update(ShoppingItemsCompanion item) =>
      (_db.update(_db.shoppingItems)
        ..where((t) => t.id.equals(item.id.value)))
      .write(item);

  Future<void> softDelete(String id) =>
      (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
        ShoppingItemsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> softDeleteAllCompleted(String listType) =>
      (_db.update(_db.shoppingItems)
        ..where((t) => t.listType.equals(listType))
        ..where((t) => t.isCompleted.equals(true))
        ..where((t) => t.isDeleted.equals(false)))
      .write(
        ShoppingItemsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<ShoppingItemRow?> findById(String id) =>
      (_db.select(_db.shoppingItems)..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  /// Reactive stream — readsFrom: is MANDATORY (v1.4 GAP-2 lesson).
  Stream<List<ShoppingItemRow>> watchByListType(String listType) =>
      _db
          .customSelect(
            'SELECT * FROM shopping_items '
            'WHERE list_type = ? AND is_deleted = 0 '
            'ORDER BY is_completed ASC, sort_order ASC, created_at ASC',
            variables: [Variable.withString(listType)],
            readsFrom: {_db.shoppingItems},
          )
          .watch()
          .map((rows) =>
              rows.map((r) => _db.shoppingItems.map(r.data)).toList());

  Future<void> upsert(ShoppingItemsCompanion item) =>
      _db.into(_db.shoppingItems).insertOnConflictUpdate(item);

  Future<void> reorder(String id, int newSortOrder) =>
      (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
        ShoppingItemsCompanion(
          sortOrder: Value(newSortOrder),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
```

### ShoppingItemRepository Interface

```dart
// lib/features/shopping_list/domain/repositories/shopping_item_repository.dart
// NO drift imports — pure domain interface
import '../models/shopping_item.dart';

abstract class ShoppingItemRepository {
  Future<void> insert(ShoppingItem item);
  Future<void> update(ShoppingItem item);
  Future<void> softDelete(String id);
  Future<void> softDeleteAllCompleted(String listType);
  Future<ShoppingItem?> findById(String id);
  Stream<List<ShoppingItem>> watchByListType(String listType);
  Future<void> upsert(ShoppingItem item);
  Future<void> reorder(String id, int newSortOrder);
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `soul_satisfaction` column, `survival`/`soul` ledger values | `joy_fullness`, `daily`/`joy` (v18 migration) | Phase 31 (v1.5) | `ledger_type` CHECK in shopping table must use `'daily'`/`'joy'` |
| Schema v18 (per CLAUDE.md) | Schema v19 (actual) | quick task 260603-ti2 | Shopping list is v20, not v19; CLAUDE.md stale ref must be corrected |
| `watchByBookIds` without `readsFrom:` (dead code) | `watchByBookIds` with `readsFrom: {_db.transactions}` | v1.4 GAP-2 fix | `watchByListType` MUST include `readsFrom:` from day one |
| `Index()` constructor for Drift table indices | `TableIndex(name:, columns: {#symbol})` | Phase 24 (v1.4) | All new table indices use `TableIndex` + symbol syntax; `@override` only on `customConstraints` |

**Deprecated/outdated:**
- `REQUIREMENTS.md D7` ("no completedAt, pure LWW"): Overridden by D-03; must be updated this phase.
- ROADMAP Phase-36 success criteria: Lists 14 fields without `completedAt`; must be updated to 15 fields + `completedAt`.
- CLAUDE.md schema version reference "v18→v19": Stale; update to reflect v19→v20.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `customSelect(..., readsFrom:).watch()` produces reactive stream from `shoppingItems` when called with a `WHERE list_type = ?` filter | Pattern 3 / DAO section | Stream would not re-emit on insert — same GAP-2 failure as v1.4 |

**Note on A1:** The `readsFrom: {_db.shoppingItems}` reactivity behaviour is confirmed via `TransactionDao.watchByBookIds` which uses the exact same pattern [VERIFIED: direct read 2026-06-07]. The only [ASSUMED] element is that the same pattern applies to a WHERE-filtered customSelect on the new table — there is no functional difference; Drift tracks table-level writes, not row-level.

All other claims are [VERIFIED] from direct codebase reads on 2026-06-07.

---

## Open Questions

1. **`sortOrder` initial-value strategy for new items**
   - What we know: `sortOrder` defaults to `0` in the schema; the DAO `ORDER BY` uses `sort_order ASC` within active items.
   - What's unclear: Should new items be inserted with `sortOrder = 0` (always added to top of active items) or `sortOrder = max(sortOrder) + 1` (appended to bottom of active items)?
   - Recommendation: Claude's discretion — the project convention in similar features inserts at `sortOrder = 0` with a stable secondary sort (`created_at ASC`) acting as tiebreaker. New items appear at top; existing items maintain relative order. This avoids a `MAX(sort_order)` query on every insert. The DAO can expose a `maxSortOrder(String listType)` helper for Phase 37 reorder use case if needed.

2. **`note` field nullability in the Dart companion vs Drift table**
   - What we know: The CONTEXT.md says `note` is `TEXT NOT NULL`; the table design in ARCHITECTURE.md uses `text().nullable()`.
   - What's unclear: Whether `note` should be `text().nullable()()` (nullable in Dart, no NOT NULL constraint in SQL) or `text()()` with `withDefault(Constant(''))`.
   - Recommendation: Use `text().nullable()()` — consistent with how `TransactionRepositoryImpl` handles note encryption (encrypts only when `note != null && note!.isNotEmpty`). An empty note is represented as `null` in the domain model and `null` in the database; no empty string sentinel needed.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `drift` code generator | Table/DAO code gen | ✓ | `^2.25.0` | — |
| `sqlite3` (raw) | Wave-0 contract test | ✓ | transitive from drift_dev | — |
| `flutter_test` | All tests | ✓ | SDK | — |
| `custom_lint` | import_guard enforcement | ✓ | transitive | — |
| SQLCipher (`sqlcipher_flutter_libs`) | Runtime DB encryption | ✓ | `^0.6.7` | — |

Step 2.6: No external tool dependencies beyond the project's own packages. All required tools are confirmed present via `pubspec.yaml` read on 2026-06-07.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `package:sqlite3` for raw contract tests |
| Config file | None — uses `flutter test` directly |
| Quick run command | `flutter test test/unit/data/migrations/shopping_items_v20_contract_test.dart -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DONE-02 | `watchByListType` emits rows ordered `is_completed ASC, sort_order ASC, created_at ASC` | unit | `flutter test test/unit/data/daos/shopping_item_dao_test.dart -x` | ❌ Wave 0 |
| DONE-02 | Soft-deleted rows excluded from `watchByListType` stream | unit | same as above | ❌ Wave 0 |
| ITEM-05 | `note` is encrypted at repository boundary; retrieved value decrypts to plaintext | unit | `flutter test test/unit/data/repositories/shopping_item_repository_impl_test.dart -x` | ❌ Wave 0 |
| ITEM-05 | `estimatedPrice` stored and retrieved as integer (not double) | unit | same as above | ❌ Wave 0 |
| SHOP-01 | `shopping_items` table has `list_type` column with `CHECK(list_type IN ('public', 'private'))` | contract | `flutter test test/unit/data/migrations/shopping_items_v20_contract_test.dart -x` | ❌ Wave 0 |
| SYNC-05 | `completed_at` column exists in v20 schema (D-03 reconciliation verified at physical schema) | contract | same as above | ❌ Wave 0 |
| ITEM-03 | `LedgerTypeSelector` imports from `lib/shared/widgets/` in both consumers | lint | `dart run custom_lint --no-fatal-infos` | ❌ Wave 0 (after move) |
| ITEM-03 | `shopping_list/presentation/import_guard.yaml` allows `CategorySelectionScreen` import | lint | same as above | ❌ Wave 0 |
| — | `ShoppingItemRepository` interface has no Drift imports | lint | `dart run custom_lint --no-fatal-infos` | ❌ Wave 0 |
| — | Domain model files under `shopping_list/domain/` have no `data/**`, `infrastructure/**` imports | lint | same as above | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter analyze && dart run custom_lint --no-fatal-infos`
- **Per wave merge:** `flutter test test/unit/data/ -x`
- **Phase gate:** `flutter test && flutter analyze` — must be green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/data/migrations/shopping_items_v20_contract_test.dart` — covers SHOP-01, SYNC-05 (column existence)
- [ ] `test/unit/data/daos/shopping_item_dao_test.dart` — covers DONE-02 (ordering, soft-delete exclusion, reactive stream)
- [ ] `test/unit/data/repositories/shopping_item_repository_impl_test.dart` — covers ITEM-05 (note encryption, estimatedPrice integer)

No new test framework install needed — `flutter_test` + `sqlite3` already in dev deps.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | `listType` privacy gate: private items guarded at use-case boundary (Phase 37); this phase creates the column that enables the gate |
| V5 Input Validation | yes | `withLength(min: 1, max: 200)` on `name`; `CHECK` constraints on `list_type`, `ledger_type`, `quantity`, `estimated_price` |
| V6 Cryptography | yes | `FieldEncryptionService` for `note` (ChaCha20-Poly1305); `jsonEncode/jsonDecode` for `tags` (not cryptographic, but must not be hand-rolled delimiter-splitting) |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `note` field stores plaintext in DB | Information Disclosure | Encrypt at repository boundary via `FieldEncryptionService.encryptField/decryptField` — same as `TransactionRepositoryImpl` |
| Private item leaks to family sync | Information Disclosure / Privacy | `listType` column + CHECK constraint is Phase 36's contribution; the guard at use-case level is Phase 37 |
| SQL injection via `listType` in `customSelect` | Tampering | Use `Variable.withString(listType)` parameterised query — never string interpolation in SQL |
| Tags JSON injection | Tampering | Use `jsonEncode(List<String>)` from `dart:convert`; on decode, cast via `.cast<String>()` and handle `FormatException` |

---

## Project Constraints (from CLAUDE.md)

- Zero analyzer warnings before commit (`flutter analyze` must report 0 issues).
- Do not suppress with `// ignore:` — fix root cause.
- `TableIndex` with `{#columnName}` symbol syntax; no `@override` on `customIndices`.
- Never `sqlite3_flutter_libs` — only `sqlcipher_flutter_libs: ^0.6.7`.
- All UI text via `S.of(context)` — no hardcoded strings (not applicable this phase — no UI).
- Drift migration: `migrator.createTable` (not raw `CREATE TABLE`) for new tables.
- Run `build_runner` after any `@DriftDatabase`, `@freezed`, or `@riverpod` change.
- NEVER implement custom crypto — use `lib/infrastructure/crypto/services/`.
- Dependency flow: `Presentation → Application → Domain ← Data ← Infrastructure`. Domain is independent. Outer layers depend on inner, never reverse.
- Thin Feature rule: Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`.
- ONE `repository_providers.dart` per feature (note: this file is created in Phase 37/38, not Phase 36).
- `intl: 0.20.2` exact pin (not applicable this phase — no i18n changes).
- CLAUDE.md stale ref to fix: "v18→v19" → update to "v19→v20" in the same commit.

---

## Sources

### Primary (HIGH confidence — direct codebase reads, 2026-06-07)

- `lib/data/tables/transactions_table.dart` — `@DataClassName`, `customConstraints`, `List<TableIndex> get customIndices` with `{#symbol}` syntax (NO `@override`); confirmed [VERIFIED]
- `lib/data/app_database.dart` — `schemaVersion => 19` at line 45; `if (from < 19)` block is category sort-order (lines 413-423); `migrator.createTable` is the v-bump pattern; [VERIFIED]
- `lib/data/daos/transaction_dao.dart` — `watchByBookIds` with `readsFrom: {_db.transactions}` is the reactive stream template; GAP-2 source documented in source comment [VERIFIED]
- `lib/data/repositories/transaction_repository_impl.dart` — `note` encryption via `FieldEncryptionService.encryptField`; `metadata` JSON encode via `jsonEncode`; exact template for shopping item repo [VERIFIED]
- `lib/features/list/domain/import_guard.yaml` — deny block with `data/**`, `infrastructure/**`, `application/**`, `features/**/presentation/**`, `flutter/**`; `inherit: true` [VERIFIED]
- `lib/features/list/domain/models/import_guard.yaml` — `allow:` list: `dart:core`, `freezed_annotation/**`, relative `accounting/domain/models/transaction.dart` path [VERIFIED]
- `lib/features/list/presentation/import_guard.yaml` — deny `infrastructure/**`, `data/daos/**`, `data/tables/**` [VERIFIED]
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — zero accounting-specific dependencies; safe to move; imports only `AppPalette`, `AppTextStyles`, `LedgerType` [VERIFIED]
- `test/unit/data/migrations/entry_source_v17_migration_test.dart` — raw-sqlite3 contract test template (Wave-0 pattern) [VERIFIED]
- `test/unit/data/migrations/category_v19_dining_out_first_test.dart` — most recent migration test; confirms v19 block content (category sort-order swap) [VERIFIED]
- `.planning/phases/36-data-layer-domain-import-guard/36-CONTEXT.md` — locked decisions D-01, D-02, D-03, canonical refs [VERIFIED]
- `.planning/REQUIREMENTS.md` — full req list; SYNC-05/D7 conflict with D-03 documented [VERIFIED]
- `.planning/ROADMAP.md` — Phase 36 success criteria (14-field list, missing completedAt — conflict with D-03 documented) [VERIFIED]

### Secondary (MEDIUM confidence — milestone research, 2026-06-07)

- `.planning/research/ARCHITECTURE.md` — full file manifest, complete table DDL example, DAO design, import_guard YAML examples, cross-feature widget resolution analysis [HIGH from codebase reads]
- `.planning/research/PITFALLS.md` — 18 pitfalls derived from direct source inspection; all critical pitfalls (privacy leak, migration collision, readsFrom, Thin Feature placement) verified [HIGH from codebase reads]
- `.planning/research/SUMMARY.md` — executive summary, recommended stack, key patterns, open questions [HIGH from codebase reads]
- `.planning/research/STACK.md` — zero new packages confirmation, pubspec.yaml dependency list [HIGH from direct pubspec.yaml read]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from pubspec.yaml and source reads; zero new packages
- Architecture (table design, migration, DAO): HIGH — verified from `transactions_table.dart`, `app_database.dart`, `transaction_dao.dart`; exact templates available
- Domain / import_guard: HIGH — verified from `lib/features/list/` structure which is the direct mirror
- Pitfalls: HIGH — all from direct source inspection, not training data
- Reconciliation actions (REQUIREMENTS.md, ROADMAP): HIGH — conflicts documented in CONTEXT.md and verified by reading both files

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (stable stack; Drift/Freezed/Riverpod APIs do not change within minor versions)
