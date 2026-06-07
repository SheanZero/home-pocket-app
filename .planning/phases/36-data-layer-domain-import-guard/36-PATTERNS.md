# Phase 36: Data Layer + Domain + Import Guard - Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 11 new/modified files
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/data/tables/shopping_items_table.dart` | model (table) | CRUD | `lib/data/tables/transactions_table.dart` | exact |
| `lib/data/app_database.dart` (modify) | config | CRUD | `lib/data/app_database.dart` — prior `from < N` blocks | exact |
| `lib/data/daos/shopping_item_dao.dart` | service (DAO) | CRUD + streaming | `lib/data/daos/transaction_dao.dart` | exact |
| `lib/data/repositories/shopping_item_repository_impl.dart` | service (repo impl) | CRUD | `lib/data/repositories/transaction_repository_impl.dart` | exact |
| `lib/features/shopping_list/domain/models/shopping_item.dart` | model (domain) | transform | `lib/features/list/domain/models/list_filter_state.dart` | role-match |
| `lib/features/shopping_list/domain/models/shopping_list_filter.dart` | model (domain) | transform | `lib/features/list/domain/models/list_filter_state.dart` | exact |
| `lib/features/shopping_list/domain/models/shopping_item_params.dart` | model (domain) | transform | `lib/features/list/domain/models/list_filter_state.dart` | role-match |
| `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` | repository (interface) | request-response | `lib/features/accounting/domain/repositories/transaction_repository.dart` | exact |
| `lib/features/shopping_list/domain/import_guard.yaml` | config | — | `lib/features/list/domain/import_guard.yaml` | exact |
| `lib/features/shopping_list/domain/models/import_guard.yaml` | config | — | `lib/features/list/domain/models/import_guard.yaml` | exact |
| `lib/features/shopping_list/presentation/import_guard.yaml` | config | — | `lib/features/list/presentation/import_guard.yaml` | exact |
| `lib/shared/widgets/ledger_type_selector.dart` (MOVE) | component | request-response | `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` | exact (same file) |
| `test/unit/data/migrations/shopping_items_v20_contract_test.dart` | test | CRUD | `test/unit/data/migrations/entry_source_v17_migration_test.dart` | role-match |
| `test/unit/data/daos/shopping_item_dao_test.dart` | test | CRUD + streaming | `test/unit/data/repositories/transaction_repository_impl_test.dart` | role-match |
| `test/unit/data/repositories/shopping_item_repository_impl_test.dart` | test | CRUD | `test/unit/data/repositories/transaction_repository_impl_test.dart` | exact |

---

## Pattern Assignments

### `lib/data/tables/shopping_items_table.dart` (model/table, CRUD)

**Analog:** `lib/data/tables/transactions_table.dart`

**Imports pattern** (lines 1):
```dart
import 'package:drift/drift.dart';
```

**Core table pattern** (lines 4-59 of analog):
```dart
// @DataClassName controls the generated row class name
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  // ... columns ...

  @override
  Set<Column> get primaryKey => {id};

  @override                            // customConstraints DOES have @override
  List<String> get customConstraints => [
    'CHECK(joy_fullness BETWEEN 1 AND 10)',
    "CHECK(entry_source IN ('manual', 'voice', 'ocr'))",
  ];

  // customIndices does NOT have @override — compile error if you add it
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_tx_book_id', columns: {#bookId}),
    TableIndex(name: 'idx_tx_book_deleted', columns: {#bookId, #isDeleted}),
  ];
}
```

**Column type conventions** (lines 8-33 of analog):
```dart
TextColumn get id => text()();                                          // required text
TextColumn get note => text().nullable()();                             // optional text
IntColumn get amount => integer()();                                    // required int
IntColumn get joyFullness => integer().withDefault(const Constant(2))(); // int with default
BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // bool flag
DateTimeColumn get timestamp => dateTime()();                           // required datetime
DateTimeColumn get updatedAt => dateTime().nullable()();                // optional datetime
```

**Critical rule:** Use `TableIndex` with `{#columnName}` Symbol syntax, NOT `Index()`, NOT string column names. Do NOT add `@override` to `customIndices` — `customConstraints` has `@override` but `customIndices` does not (CLAUDE.md pitfall #11).

---

### `lib/data/app_database.dart` — schemaVersion bump + migration block (config, CRUD)

**Analog:** `lib/data/app_database.dart` existing structure

**Imports to add** (line 14 area of analog):
```dart
import 'tables/shopping_items_table.dart';    // add alongside other table imports
```

**@DriftDatabase annotation modification** (lines 23-36 of analog — add ShoppingItems):
```dart
@DriftDatabase(
  tables: [
    AuditLogs,
    Books,
    Categories,
    CategoryKeywordPreferences,
    CategoryLedgerConfigs,
    GroupMembers,
    Groups,
    MerchantCategoryPreferences,
    ShoppingItems,    // ADD HERE
    SyncQueue,
    Transactions,
    UserProfiles,
  ],
)
```

**schemaVersion bump** (line 45 of analog):
```dart
// Change:
int get schemaVersion => 19;
// To:
int get schemaVersion => 20;
```

**Migration block pattern** (lines 413-423 of analog — append after existing `from < 19` block):
```dart
if (from < 19) {
  // 260603-ti2: promote cat_food_dining_out to first sub-category of cat_food.
  await customStatement(
    "UPDATE categories SET sort_order = 1 WHERE id = 'cat_food_dining_out' AND is_system = 1",
  );
  await customStatement(
    "UPDATE categories SET sort_order = 2 WHERE id = 'cat_food_groceries' AND is_system = 1",
  );
}
// ADD THIS BLOCK AFTER:
if (from < 20) {
  await migrator.createTable(shoppingItems);
}
```

**Critical:** Use `migrator.createTable(shoppingItems)`, NOT `customStatement('CREATE TABLE ...')`. The `migrator.createTable` call emits the full DDL including `customConstraints`. Run `flutter pub run build_runner build --delete-conflicting-outputs` immediately after this change.

---

### `lib/data/daos/shopping_item_dao.dart` (service/DAO, CRUD + streaming)

**Analog:** `lib/data/daos/transaction_dao.dart`

**Imports pattern** (lines 1-4 of analog):
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
```

**Constructor pattern** (lines 7-10 of analog):
```dart
class TransactionDao {
  TransactionDao(this._db);
  final AppDatabase _db;
```

**Soft-delete pattern** (lines 169-176 of analog):
```dart
Future<void> softDelete(String id) async {
  await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
    TransactionsCompanion(
      isDeleted: const Value(true),
      updatedAt: Value(DateTime.now()),
    ),
  );
}
```

**Reactive stream pattern — MANDATORY `readsFrom:`** (lines 285-324 of analog):
```dart
Stream<List<TransactionRow>> watchByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  ...
}) {
  if (bookIds.isEmpty) return const Stream.empty();

  return _db
      .customSelect(
        'SELECT * FROM transactions '
        'WHERE book_id IN ($placeholders) '
        'AND is_deleted = 0 '
        'ORDER BY $orderBy',
        variables: [
          ...bookIds.map(Variable.withString),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
        readsFrom: {_db.transactions},   // MANDATORY — without this, stream never re-emits
      )
      .watch()
      .map(
        (rows) => rows.map((row) => _db.transactions.map(row.data)).toList(),
      );
}
```

**For `watchByListType`, adapt the SQL ordering to the shopping-specific rule:**
```
ORDER BY is_completed ASC, sort_order ASC, created_at ASC
```
Use `Variable.withString(listType)` for the WHERE parameter — never string interpolation (SQL injection prevention, RESEARCH.md security domain).

**Upsert pattern** (not in TransactionDao — use Drift built-in):
```dart
Future<void> upsert(ShoppingItemsCompanion item) =>
    _db.into(_db.shoppingItems).insertOnConflictUpdate(item);
```

**`findById` pattern** (lines 60-64 of analog):
```dart
Future<TransactionRow?> findById(String id) async {
  return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
}
```

---

### `lib/data/repositories/shopping_item_repository_impl.dart` (service/repo impl, CRUD)

**Analog:** `lib/data/repositories/transaction_repository_impl.dart`

**Imports pattern** (lines 1-9 of analog):
```dart
import 'dart:convert';

import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../app_database.dart';
import '../daos/shopping_item_dao.dart';
```

**Constructor with dependency injection** (lines 15-22 of analog):
```dart
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionDao dao,
    required FieldEncryptionService encryptionService,
  }) : _dao = dao,
       _encryptionService = encryptionService;

  final TransactionDao _dao;
  final FieldEncryptionService _encryptionService;
```

**Note encryption at boundary — insert** (lines 25-54 of analog):
```dart
@override
Future<void> insert(Transaction transaction) async {
  String? encryptedNote;
  if (transaction.note != null && transaction.note!.isNotEmpty) {
    encryptedNote = await _encryptionService.encryptField(transaction.note!);
  }

  // JSON encode for map/list fields — same layer as encryption
  await _dao.insertTransaction(
    // ...
    note: encryptedNote,
    metadata: transaction.metadata != null
        ? jsonEncode(transaction.metadata)
        : null,
    // ...
  );
}
```

**For shopping items, apply the same pattern for both `note` (encrypt) and `tags` (JSON encode):**
```dart
// note: encrypt (same as TransactionRepositoryImpl.insert)
String? encryptedNote;
if (item.note != null && item.note!.isNotEmpty) {
  encryptedNote = await _encryptionService.encryptField(item.note!);
}

// tags: JSON encode (same layer as note encryption; do NOT use comma-split)
final encodedTags = item.tags.isEmpty ? null : jsonEncode(item.tags);
```

**`_toModel` decrypt + JSON decode pattern** (lines 182-220 of analog):
```dart
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    try {
      decryptedNote = await _encryptionService.decryptField(row.note!);
    } catch (_) {
      // Shadow-book notes encrypted with another device key — return null silently.
      // DO NOT log row.note or the exception (may contain ciphertext).
      decryptedNote = null;
    }
  }

  // JSON decode for tags:
  // List<String> tags = [];
  // if (row.tags != null) {
  //   tags = (jsonDecode(row.tags!) as List).cast<String>();
  // }

  return Transaction(
    id: row.id,
    // ... map remaining fields
    note: decryptedNote,
    metadata: row.metadata != null
        ? jsonDecode(row.metadata!) as Map<String, dynamic>
        : null,
  );
}
```

**Reactive stream via asyncMap** (lines 160-179 of analog):
```dart
@override
Stream<List<Transaction>> watchByBookIds(...) {
  return _dao
      .watchByBookIds(...)
      .asyncMap((rows) => Future.wait(rows.map(_toModel)));
}
```

Apply identical `.asyncMap((rows) => Future.wait(rows.map(_toModel)))` for `watchByListType` — required because `_toModel` is async (awaits decryptField).

---

### `lib/features/shopping_list/domain/models/shopping_item.dart` (model, transform)

**Analog:** `lib/features/list/domain/models/list_filter_state.dart`

**Imports pattern** (lines 1-5 of analog):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';   // for LedgerType enum

part 'shopping_item.freezed.dart';
```

**No Drift imports permitted.** No `package:drift/` in any file under `lib/features/shopping_list/domain/`. Use plain Dart nullability (`String? note`), never `Value<T>`.

**`@freezed` model pattern** (lines 19-45 of analog):
```dart
@freezed
abstract class ListFilterState with _$ListFilterState {
  const ListFilterState._();    // private constructor for custom methods

  const factory ListFilterState({
    required int selectedYear,
    required int selectedMonth,
    DateTime? activeDayFilter,
    @Default(ListSortConfig()) ListSortConfig sortConfig,
    LedgerType? ledgerType,
    @Default(<String>{}) Set<String> categoryIds,
    @Default('') String searchQuery,
    String? memberBookId,
  }) = _ListFilterState;

  factory ListFilterState.initial() => ListFilterState(
        selectedYear: DateTime.now().year,
        selectedMonth: DateTime.now().month,
      );
}
```

**`@Default` annotation** for fields with defaults (avoids requiring them in all `copyWith` calls). Cross-feature domain import (`accounting/domain/models/transaction.dart` for `LedgerType`) is the established pattern — the models `import_guard.yaml` allow-list makes this explicit.

---

### `lib/features/shopping_list/domain/models/shopping_list_filter.dart` (model, transform)

**Analog:** `lib/features/list/domain/models/list_filter_state.dart`

Same `@freezed` pattern. This model holds filter state (e.g., `listType` selection, text search). No Drift imports. Import only `freezed_annotation` and optionally `dart:core` types.

---

### `lib/features/shopping_list/domain/models/shopping_item_params.dart` (model, transform)

**Analog:** `lib/features/list/domain/models/list_sort_config.dart` (a params/config model)

Same `@freezed` pattern. Holds parameters for insert/update operations. Use plain nullable Dart types only — no `Value<T>` (Drift-only). This is a write-params DTO for the repository interface.

---

### `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` (repository interface, request-response)

**Analog:** `lib/features/accounting/domain/repositories/transaction_repository.dart`

**Imports pattern** (lines 1-2 of analog):
```dart
import '../models/shopping_item.dart';
// No drift imports. No data layer imports. Domain-only.
```

**Abstract interface pattern** (lines 5-55 of analog):
```dart
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findByBookId(
    String bookId, {
    LedgerType? ledgerType,
    // ...
  });
  Future<void> update(Transaction transaction);
  Future<void> softDelete(String id);

  Stream<List<Transaction>> watchByBookIds(
    List<String> bookIds, {
    // ...
  });
}
```

The interface defines the contract for Phase 37 use-case and Phase 38 provider wiring. Method signatures here are frozen for downstream phases.

---

### `lib/features/shopping_list/domain/import_guard.yaml` (config)

**Analog:** `lib/features/list/domain/import_guard.yaml` (lines 8-16)

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

Copy verbatim. The parent domain guard owns only denies; children (models/) own the allow-list.

---

### `lib/features/shopping_list/domain/models/import_guard.yaml` (config)

**Analog:** `lib/features/list/domain/models/import_guard.yaml` (lines 1-10)

```yaml
# Per-subdirectory whitelist. Inherits parent feature-level deny.
allow:
  - dart:core
  - package:freezed_annotation/**
  - ../../../accounting/domain/models/transaction.dart   # for LedgerType enum

inherit: true
```

The relative path `../../../accounting/domain/models/transaction.dart` is the allow-list entry for the cross-feature `LedgerType` import. This is the verified pattern from the `list` feature's models guard.

---

### `lib/features/shopping_list/presentation/import_guard.yaml` (config)

**Analog:** `lib/features/list/presentation/import_guard.yaml` (lines 1-8) + CategorySelectionScreen allow

```yaml
allow:
  - package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart

deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

The `CategorySelectionScreen` allow-list is intentional: the screen has accounting-specific providers and cannot be moved to shared (see RESEARCH.md Pattern 6 rationale). The allow-list makes the cross-feature dependency explicit and auditable.

---

### `lib/shared/widgets/ledger_type_selector.dart` (MOVE, component, request-response)

**Source:** `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`

**Action:** Move the file. The widget is stateless with zero accounting-specific state — it takes `LedgerType selected`, `ValueChanged<LedgerType> onChanged`, `String dailyLabel`, `String joyLabel` and renders chips using `AppPalette` / `AppTextStyles`.

**Import path update in the widget itself** (lines 1-6 of source):
```dart
// Old paths (from accounting/presentation/widgets/):
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';

// New paths (from shared/widgets/):
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../features/accounting/domain/models/transaction.dart';
// OR: use package-absolute path
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
```

**Import site to update** — single confirmed consumer (from grep):
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` line 36:
  ```dart
  // Old:
  import '../widgets/ledger_type_selector.dart';
  // New:
  import '../../../../shared/widgets/ledger_type_selector.dart';
  ```

Run `dart run custom_lint --no-fatal-infos` after the move to confirm zero violations.

---

### `test/unit/data/migrations/shopping_items_v20_contract_test.dart` (test, CRUD)

**Analog:** `test/unit/data/migrations/entry_source_v17_migration_test.dart`

**Imports pattern** (lines 1-3 of analog):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';
```

**schemaVersion assertion pattern** (lines 8-13 of analog):
```dart
test('AppDatabase schemaVersion includes v17 entry_source migration', () {
  final db = AppDatabase.forTesting();
  addTearDown(db.close);
  expect(db.schemaVersion, greaterThanOrEqualTo(_targetSchemaVersion));
});
```

**Raw-sqlite3 group structure** (lines 15-82 of analog):
```dart
group('v17 entry_source migration', () {
  late Database rawDb;

  setUp(() {
    rawDb = sqlite3.openInMemory();
    _createV16TransactionsTable(rawDb);   // helper creates the table DDL
  });

  tearDown(() {
    rawDb.dispose();
  });

  test('rejects invalid entry_source after migration', () {
    _runV17MigrationSteps(rawDb);
    expect(
      () => _insertV17Row(rawDb, 'tx_invalid', 'keyboard'),
      throwsA(isA<SqliteException>()),
    );
  });
});
```

**DDL helper pattern** (lines 85-111 of analog):
```dart
void _createV16TransactionsTable(Database db) {
  db.execute('''
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY,
      // ... all columns including CHECK constraints
    )
  ''');
}
```

For the v20 contract test, the `_createV20ShoppingItemsTable(Database db)` helper must mirror the exact DDL that `migrator.createTable(shoppingItems)` emits. After running build_runner, inspect `app_database.g.dart` for the actual generated DDL and reconcile the helper with it. Drift stores `DateTime` as `INTEGER` (milliseconds), `bool` as `INTEGER` (0/1).

**`_insertRow` helper pattern** (lines 120-152 of analog):
```dart
void _insertV16Row(Database db, String id) {
  final now = DateTime(2026, 5, 21, 12).millisecondsSinceEpoch;
  db.execute(
    '''INSERT INTO transactions (id, book_id, ...) VALUES (?, ?, ...)''',
    [id, 'book_v16', ...],
  );
}
```

Use `millisecondsSinceEpoch` for all `INTEGER` datetime columns in raw-sqlite3 tests.

---

### `test/unit/data/daos/shopping_item_dao_test.dart` (test, CRUD + streaming)

**Analog:** `test/unit/data/repositories/transaction_repository_impl_test.dart`

**Setup pattern** (lines 14-35 of analog):
```dart
late AppDatabase db;
late ShoppingItemDao dao;

setUp(() {
  db = AppDatabase.forTesting();   // in-memory DB, includes all migrations
  dao = ShoppingItemDao(db);
});

tearDown(() async {
  await db.close();
});
```

**Test structure for DAO ordering (DONE-02):**
- Insert items in non-sorted order (some completed, different `sortOrder` values, different `createdAt`)
- Call `watchByListType` and `await` first emission
- Assert the returned list matches `ORDER BY is_completed ASC, sort_order ASC, created_at ASC`

**Test structure for soft-delete exclusion:**
- Insert an item, call `softDelete(id)`, assert the next `watchByListType` emission excludes it
- Assert the row still physically exists (call `findById` directly on DAO)

For streaming tests, use `expectLater(stream, emitsInOrder([...]))` or capture the first value with a `Completer` (see CLAUDE.md Riverpod test pattern — same principle for raw streams: hold a subscription until the value arrives).

---

### `test/unit/data/repositories/shopping_item_repository_impl_test.dart` (test, CRUD)

**Analog:** `test/unit/data/repositories/transaction_repository_impl_test.dart` (lines 1-80+)

**Mock encryption service pattern** (lines 9-35 of analog):
```dart
class _MockFieldEncryptionService extends Mock implements FieldEncryptionService {}

setUp(() {
  db = AppDatabase.forTesting();
  dao = ShoppingItemDao(db);
  mockEncryption = _MockFieldEncryptionService();
  repo = ShoppingItemRepositoryImpl(
    dao: dao,
    encryptionService: mockEncryption,
  );

  // Default: encryption passthrough for testing
  when(() => mockEncryption.encryptField(any()))
      .thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
  when(() => mockEncryption.decryptField(any())).thenAnswer((inv) async {
    final cipher = inv.positionalArguments[0] as String;
    return cipher.replaceFirst('enc_', '');
  });
});
```

**Key test cases to cover:**
- `insert` stores `note` encrypted (verify `mockEncryption.encryptField` called)
- `insert` stores `tags` as JSON string in the DB row
- `findById` decrypts note and decodes tags back to `List<String>`
- `insert` with null note skips encryption (verify `encryptField` NOT called)
- `insert` with empty tags stores `null` in DB
- `watchByListType` stream excludes soft-deleted items

Also add a silent-failure test for wrong-device-key decrypt (analog: `transaction_repository_note_decrypt_test.dart` — implement `_ThrowingEncryptionService` to simulate decryption failure, assert `note` returns `null`, other fields intact).

---

## Shared Patterns

### Soft Delete
**Source:** `lib/data/daos/transaction_dao.dart` lines 169-176
**Apply to:** `ShoppingItemDao.softDelete`, `ShoppingItemDao.softDeleteAllCompleted`
```dart
await (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
  ShoppingItemsCompanion(
    isDeleted: const Value(true),
    updatedAt: Value(DateTime.now()),
  ),
);
```

### Note Encryption at Repository Boundary
**Source:** `lib/data/repositories/transaction_repository_impl.dart` lines 25-30 and 182-193
**Apply to:** `ShoppingItemRepositoryImpl.insert`, `ShoppingItemRepositoryImpl.update`, `ShoppingItemRepositoryImpl._toModel`
```dart
// Encrypt:
String? encryptedNote;
if (item.note != null && item.note!.isNotEmpty) {
  encryptedNote = await _encryptionService.encryptField(item.note!);
}

// Decrypt with silent failure:
try {
  decryptedNote = await _encryptionService.decryptField(row.note!);
} catch (_) {
  decryptedNote = null;  // DO NOT log ciphertext
}
```

### JSON Encode/Decode at Repository Boundary
**Source:** `lib/data/repositories/transaction_repository_impl.dart` lines 45-47 and 206-209
**Apply to:** `ShoppingItemRepositoryImpl` for `tags` field
```dart
// Encode (insert/update):
metadata: transaction.metadata != null ? jsonEncode(transaction.metadata) : null,

// Decode (toModel):
metadata: row.metadata != null ? jsonDecode(row.metadata!) as Map<String, dynamic> : null,
// Adapt for tags: (jsonDecode(row.tags!) as List).cast<String>()
```

### Reactive Stream with asyncMap
**Source:** `lib/data/repositories/transaction_repository_impl.dart` lines 160-179
**Apply to:** `ShoppingItemRepositoryImpl.watchByListType`
```dart
return _dao
    .watchByListType(listType)
    .asyncMap((rows) => Future.wait(rows.map(_toModel)));
```

### `readsFrom:` in Reactive DAO Queries (MANDATORY)
**Source:** `lib/data/daos/transaction_dao.dart` line 318
**Apply to:** `ShoppingItemDao.watchByListType`
```dart
readsFrom: {_db.shoppingItems},  // mandatory — without this, stream never re-emits
```

### AppDatabase.forTesting() in Tests
**Source:** `test/unit/data/repositories/transaction_repository_impl_test.dart` line 20
**Apply to:** All DAO and repository tests
```dart
db = AppDatabase.forTesting();   // NativeDatabase.memory() — includes all migrations up to current schemaVersion
addTearDown(db.close);
```

### import_guard deny-at-parent, allow-at-child
**Source:** `lib/features/list/domain/import_guard.yaml` + `lib/features/list/domain/models/import_guard.yaml`
**Apply to:** All new shopping_list/ subdirectory guards
The parent `domain/import_guard.yaml` owns deny rules only (`inherit: true`, no `allow:`). The child `domain/models/import_guard.yaml` owns the allow whitelist with exact paths. This split is required by how `import_guard_custom_lint` evaluates configs (each config evaluated independently against its own allow whitelist).

---

## No Analog Found

All files have close analogs. No new patterns need to be imported from RESEARCH.md code examples.

| File | Role | Note |
|------|------|------|
| `test/unit/data/daos/shopping_item_dao_test.dart` | test | No direct DAO stream test analog exists; use `transaction_repository_impl_test.dart` as closest match for setup/teardown; the reactive stream assertion pattern must follow Dart `Stream` testing conventions |

---

## Metadata

**Analog search scope:** `lib/data/`, `lib/features/list/`, `lib/features/accounting/domain/repositories/`, `lib/shared/`, `test/unit/data/`
**Files scanned:** 14 source files + 7 test files
**Pattern extraction date:** 2026-06-07
