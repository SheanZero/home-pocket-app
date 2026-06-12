# Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 14 new/modified files
**Analogs found:** 14 / 14

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/data/tables/exchange_rates_table.dart` | model (Drift table) | CRUD | `lib/data/tables/shopping_items_table.dart` | exact |
| `lib/data/app_database.dart` (modify) | config (migration) | CRUD | `lib/data/app_database.dart` itself (from < 20 block) | self-analog |
| `lib/data/daos/exchange_rate_dao.dart` | service (DAO) | CRUD | `lib/data/daos/shopping_item_dao.dart` | exact |
| `lib/data/repositories/exchange_rate_repository_impl.dart` | service (repo impl) | CRUD | `lib/data/repositories/shopping_item_repository_impl.dart` | role-match |
| `lib/features/currency/domain/models/exchange_rate.dart` | model (Freezed) | CRUD | `lib/features/shopping_list/domain/models/shopping_item.dart` | exact |
| `lib/features/currency/domain/repositories/exchange_rate_repository.dart` | service (interface) | CRUD | `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` | exact |
| `lib/features/accounting/domain/models/transaction.dart` (modify) | model (Freezed) | CRUD | itself + `lib/features/shopping_list/domain/models/shopping_item.dart` | self-analog |
| `lib/features/accounting/domain/models/transaction_sync_mapper.dart` (modify) | utility (sync mapper) | request-response | itself (note/merchant/photoHash pattern) | self-analog |
| `lib/application/accounting/create_transaction_use_case.dart` (modify) | service (use case) | CRUD | itself (joyFullness validation block) | self-analog |
| `lib/application/currency/repository_providers.dart` | config (Riverpod wiring) | request-response | `lib/application/accounting/repository_providers.dart` | exact |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` (modify) | utility (formatter) | transform | itself (`_getCurrencySymbol` switch) | self-analog |
| `lib/shared/utils/currency_conversion.dart` | utility (math) | transform | `lib/shared/utils/result.dart` (pure static utility shape) | role-match |
| `test/unit/data/migrations/schema_v21_migration_test.dart` | test | CRUD | `test/unit/data/migrations/shopping_items_v20_contract_test.dart` | exact |
| `test/unit/data/daos/exchange_rate_dao_test.dart` | test | CRUD | `test/unit/data/migrations/shopping_items_v20_contract_test.dart` | role-match |

---

## Pattern Assignments

### `lib/data/tables/exchange_rates_table.dart` (model, CRUD)

**Analog:** `lib/data/tables/shopping_items_table.dart`

**Imports pattern** (shopping_items_table.dart lines 1-2):
```dart
import 'package:drift/drift.dart';
```

**Core table pattern** (shopping_items_table.dart lines 3-82):
```dart
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  TextColumn get id => text()();
  // ...nullable columns:
  TextColumn get note => text().nullable()();
  IntColumn get estimatedPrice => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  // ...
  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK(list_type IN ('public', 'private'))",
  ];

  // NOTE: customIndices is DECORATIVE — indices must be created explicitly
  // in AppDatabase helper methods (onCreate + onUpgrade). See CR-01 lesson.
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_shopping_list_type', columns: {#listType}),
  ];
}
```

**Phase 40 application** — `ExchangeRates` table uses composite PK per D-09:
```dart
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currency => text()();           // ISO 4217 code
  DateTimeColumn get rateDate => dateTime()();   // midnight UTC of the exchange day
  RealColumn get rate => real()();               // JPY per 1 unit of currency
  DateTimeColumn get fetchedAt => dateTime()();  // cache timestamp for TTL (RATE-02)
  TextColumn get source => text()();             // 'frankfurter' | 'fawazahmed0' | 'manual'
  DateTimeColumn get actualRateDate => dateTime().nullable()(); // weekend fallback (RATE-05)

  @override
  Set<Column> get primaryKey => {currency, rateDate};

  // customIndices is DECORATIVE — must call _createExchangeRateIndexes() explicitly
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_exchange_rates_currency_date', columns: {#currency, #rateDate}),
  ];
}
```

**Critical note:** `rate` on `exchange_rates` is `RealColumn` (acceptable — rates are queried but not multiplied back through DB). Only `appliedRate` on `transactions` must be `TextColumn` (D-04 anti-pattern guard).

---

### `lib/data/app_database.dart` — migration block addition (config, CRUD)

**Analog:** itself — `from < 20` block (lines 433-440) + `_createShoppingItemIndexes()` (lines 450-471)

**Migration block pattern** (app_database.dart lines 433-440):
```dart
if (from < 20) {
  // Phase 36: shopping list — create the shopping_items table (v19→v20).
  // createTable emits the table DDL including customConstraints. The
  // customIndices getter is NOT consumed by Drift's migrator, so each
  // index must be created explicitly (mirrors every other table here).
  await migrator.createTable(shoppingItems);
  await _createShoppingItemIndexes();
}
```

**ALTER TABLE for nullable columns pattern** (app_database.dart lines 355-358):
```dart
// D-01: Phase 17 entry_source column.
// Cannot use migrator.addColumn here because table-level
// customConstraints are not applied by addColumn to existing rows.
await customStatement(
  '''ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL '''
  '''DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))''',
);
```

**Index helper pattern** (app_database.dart lines 450-471):
```dart
Future<void> _createShoppingItemIndexes() async {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_shopping_list_type '
    'ON shopping_items (list_type)',
  );
  // ... more indices
}
```

**onCreate — must also call the new helper** (app_database.dart lines 52-57):
```dart
onCreate: (migrator) async {
  await migrator.createAll();
  // createAll() does not emit the customIndices getter (not a real Drift
  // API), so shopping_items indices must be created explicitly on fresh
  // installs too — not only on the v19→v20 upgrade path.
  await _createShoppingItemIndexes();
},
```

**Phase 40 additions follow these exact patterns:**
- Add `if (from < 21)` block after the `if (from < 20)` block
- Use `customStatement('ALTER TABLE transactions ADD COLUMN ...')` for the three nullable columns (no DEFAULT needed — nullable)
- Add `await migrator.createTable(exchangeRates)` + `await _createExchangeRateIndexes()`
- Add `ExchangeRates` to `@DriftDatabase(tables: [...])` list
- Add `await _createExchangeRateIndexes()` to `onCreate`
- Update `schemaVersion => 20` to `schemaVersion => 21`

---

### `lib/data/daos/exchange_rate_dao.dart` (service/DAO, CRUD)

**Analog:** `lib/data/daos/shopping_item_dao.dart`

**Imports + constructor pattern** (shopping_item_dao.dart lines 1-14):
```dart
import 'package:drift/drift.dart';

import '../app_database.dart';

class ShoppingItemDao {
  ShoppingItemDao(this._db);

  final AppDatabase _db;
```

**findById (single row, getSingleOrNull) pattern** (shopping_item_dao.dart lines 58-61):
```dart
Future<ShoppingItemRow?> findById(String id) async {
  return (_db.select(_db.shoppingItems)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
}
```

**upsert pattern** (shopping_item_dao.dart lines 126-128):
```dart
Future<void> upsert(ShoppingItemsCompanion item) async {
  await _db.into(_db.shoppingItems).insertOnConflictUpdate(item);
}
```

**Multi-condition where + orderBy + limit pattern** (transaction_dao.dart — use for `findLatest`):
```dart
Future<ExchangeRateRow?> findLatest(String currency) =>
  (_db.select(_db.exchangeRates)
    ..where((t) => t.currency.equals(currency))
    ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
    ..limit(1))
    .getSingleOrNull();
```

**Phase 40 `ExchangeRateDao` implements three methods:**
- `findByDate(String currency, DateTime date)` — composite key lookup
- `findLatest(String currency)` — order by rateDate DESC + limit 1
- `upsert(ExchangeRatesCompanion companion)` — insertOnConflictUpdate

---

### `lib/data/repositories/exchange_rate_repository_impl.dart` (service, CRUD)

**Analog:** `lib/data/repositories/shopping_item_repository_impl.dart`

**Imports + constructor pattern** (shopping_item_repository_impl.dart lines 1-30):
```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../daos/shopping_item_dao.dart';
import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';

class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  ShoppingItemRepositoryImpl({
    required ShoppingItemDao dao,
    // optional: other services
  })  : _dao = dao;

  final ShoppingItemDao _dao;
```

**_toModel mapping pattern** (shopping_item_repository_impl.dart lines 178-227):
```dart
Future<ShoppingItem> _toModel(ShoppingItemRow row) async {
  return ShoppingItem(
    id: row.id,
    // ... map each column to domain field
  );
}
```

**Phase 40 note:** `ExchangeRateRepositoryImpl` is simpler — no field encryption (rate data is not sensitive PII), no JSON encoding. The `_toModel` pattern maps `ExchangeRateRow` to `ExchangeRate` Freezed model straightforwardly.

---

### `lib/features/currency/domain/models/exchange_rate.dart` (model, CRUD)

**Analog:** `lib/features/shopping_list/domain/models/shopping_item.dart`

**Imports + Freezed pattern** (shopping_item.dart lines 1-41):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_item.freezed.dart';

/// Immutable domain model representing a single shopping list item.
///
/// Fields mirror the v20 `shopping_items` Drift table column order.
/// No Drift or Flutter imports — this is a pure domain type.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const ShoppingItem._();  // private constructor for custom methods

  const factory ShoppingItem({
    required String id,
    // ... required fields ...
    String? note,          // nullable without @Default
    @Default(false) bool isCompleted,  // non-null with @Default
    DateTime? completedAt, // nullable DateTime
  }) = _ShoppingItem;
}
```

**Phase 40 `ExchangeRate` Freezed model:**
- No `part '*.g.dart'` needed (no `fromJson` unless explicitly wanted)
- Fields mirror the `exchange_rates` table column set per D-09
- `actualRateDate` is `DateTime?` (nullable)
- No `@Default` needed — all fields are either required or nullable

---

### `lib/features/currency/domain/repositories/exchange_rate_repository.dart` (service/interface, CRUD)

**Analog:** `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart`

**Interface pattern** (shopping_item_repository.dart lines 1-27):
```dart
// No Drift imports. Domain-owned interface — data layer satisfies it via ShoppingItemRepositoryImpl.
import '../models/shopping_item.dart';

/// Abstract repository interface for shopping item data access.
///
/// Implemented by [ShoppingItemRepositoryImpl] in `lib/data/repositories/`.
/// All method signatures are pure Dart — no Drift or Flutter types.
abstract class ShoppingItemRepository {
  Future<void> insert(ShoppingItem item);
  Future<ShoppingItem?> findById(String id);
  Future<void> upsert(ShoppingItem item);
}
```

**Phase 40 `ExchangeRateRepository` interface exposes:**
- `Future<ExchangeRate?> findByDate(String currency, DateTime date)`
- `Future<ExchangeRate?> findLatest(String currency)`
- `Future<void> upsert(ExchangeRate rate)`

---

### `lib/features/accounting/domain/models/transaction.dart` — three new fields (model, CRUD)

**Analog:** itself — existing nullable field pattern (lines 24-28):
```dart
// Optional fields — no @Default, no required:
String? note,
String? photoHash,
String? merchant,
Map<String, dynamic>? metadata,
```

**Phase 40 additions follow the same pattern:**
```dart
// Foreign-currency provenance (all null = JPY-native row per STORE-01)
String? originalCurrency,   // ISO 4217 code, e.g. 'USD'; null = native JPY
int? originalAmount,        // minor units (cents for USD: $12.50 → 1250); null = native JPY
String? appliedRate,        // JPY per 1 whole unit as string (D-04); null = native JPY
```

**No @Default annotation needed** — Freezed implicitly defaults nullable to `null`. All three arrive together or not at all (enforced by partial-triple invariant in use case).

---

### `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — currency fields (utility, request-response)

**Analog:** itself — existing conditional emit pattern (lines 22-26):
```dart
// toSyncMap — conditional emit for nullable fields:
if (transaction.note != null) 'note': transaction.note,
if (transaction.merchant != null) 'merchant': transaction.merchant,
if (transaction.photoHash != null) 'photoHash': transaction.photoHash,

// fromSyncMap — null-safe cast for optional fields:
note: data['note'] as String?,
photoHash: data['photoHash'] as String?,
merchant: data['merchant'] as String?,
// ...with fallback for enum-valued optionals:
joyFullness: data['joyFullness'] as int? ?? 2,
```

**Phase 40 additions follow identical pattern:**
```dart
// toSyncMap additions (after photoHash conditional):
if (transaction.originalCurrency != null)
  'originalCurrency': transaction.originalCurrency,
if (transaction.originalAmount != null)
  'originalAmount': transaction.originalAmount,
if (transaction.appliedRate != null)
  'appliedRate': transaction.appliedRate,

// fromSyncMap additions (inside Transaction(...) constructor):
originalCurrency: data['originalCurrency'] as String?,
originalAmount: data['originalAmount'] as int?,
appliedRate: data['appliedRate'] as String?,
```

**Backward-compat invariant:** Absent keys in a v1.6 payload produce `null` via `as T?` — no `?? fallback` needed since `null` is the correct JPY-native state.

---

### `lib/application/accounting/create_transaction_use_case.dart` — partial-triple invariant (service, CRUD)

**Analog:** itself — existing validation pattern (lines 76-86):
```dart
Future<Result<Transaction>> execute(CreateTransactionParams params) async {
  // 1. Validate input
  if (params.bookId.isEmpty) {
    return Result.error('bookId must not be empty');
  }
  if (params.amount <= 0) {
    return Result.error('amount must be greater than 0');
  }
  // ... additional validation blocks same shape
```

**joyFullness validation** (lines 115-125) shows the "check + Result.error" pattern for a numeric range:
```dart
if (joyFullness < 1 || joyFullness > 10) {
  return Result.error(
    'joyFullness must be between 1 and 10, got $joyFullness',
  );
}
```

**Phase 40 adds partial-triple check to `CreateTransactionParams` + use case:**
```dart
// In CreateTransactionParams — three optional fields added:
final String? originalCurrency;
final int? originalAmount;
final String? appliedRate;

// In execute(), after amount validation, before category lookup:
final hasOrig = params.originalCurrency != null ||
    params.originalAmount != null ||
    params.appliedRate != null;
final hasAll = params.originalCurrency != null &&
    params.originalAmount != null &&
    params.appliedRate != null;
if (hasOrig && !hasAll) {
  return Result.error(
    'partial foreign-currency data: all three of originalCurrency, '
    'originalAmount, appliedRate must be non-null together',
  );
}
```

**Result type source** — `lib/shared/utils/result.dart` (lines 6-19):
```dart
class Result<T> {
  factory Result.success(T? data) => Result._(data: data, isSuccess: true);
  factory Result.error(String message) =>
      Result._(error: message, isSuccess: false);
}
```

---

### `lib/application/currency/repository_providers.dart` (config, request-response)

**Analog:** `lib/application/accounting/repository_providers.dart`

**Imports + code-gen pattern** (accounting/repository_providers.dart lines 1-10):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import '../../infrastructure/security/providers.dart' as security;

part 'repository_providers.g.dart';
```

**`@riverpod` provider pattern** (accounting/repository_providers.dart lines 19-22):
```dart
@riverpod
AppDatabase appAppDatabase(Ref ref) {
  return ref.watch(security.appDatabaseProvider);
}
```

**Phase 40 `lib/application/currency/repository_providers.dart`** wires `ExchangeRateRepository` → `ExchangeRateRepositoryImpl`:
- Import the DAO, impl, and interface
- Reference `appDatabaseProvider` from infrastructure/security/providers.dart
- Single `@riverpod` provider: `ExchangeRateRepository appExchangeRateRepository(Ref ref)`
- Follow the `app`-prefix convention established in accounting/repository_providers.dart comment

---

### `lib/infrastructure/i18n/formatters/number_formatter.dart` — disambiguation table (utility, transform)

**Analog:** itself — `_getCurrencySymbol` (lines 54-68) and `_getCurrencyDecimals` (lines 70-77):

**Current implementation (BUG — lines 54-68):**
```dart
static String _getCurrencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'CNY':            // BUG: both return '¥' — CNY should be 'CN¥'
      return '¥';
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return currencyCode;  // ISO code fallback already exists
  }
}

static int _getCurrencyDecimals(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
      return 0;
    default:
      return 2;
  }
}
```

**Phase 40 fix — break the `JPY`/`CNY` fallthrough and add full table per D-06/D-07/D-08:**
```dart
static String _getCurrencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY': return '¥';     // ¥ — unambiguous
    case 'CNY': return 'CN¥';  // CN¥ — D-06 disambiguation
    case 'KRW': return '₩';    // ₩ — D-08
    case 'USD': return r'$';
    case 'EUR': return '€';
    case 'GBP': return '£';
    case 'HKD': return 'HK\$';      // D-06
    case 'AUD': return 'A\$';       // D-06
    case 'CAD': return 'C\$';       // D-06
    case 'TWD': return 'NT\$';      // D-06
    case 'SGD': return 'S\$';       // D-06
    default: return currencyCode;   // D-07 ISO code prefix fallback
  }
}

static int _getCurrencyDecimals(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'KRW': return 0;           // D-08 KRW 0 decimals
    default: return 2;
  }
}
```

**Golden re-baseline note:** After this change, run `flutter test --update-goldens test/golden/amount_display_golden_test.dart` **on macOS only** (MEMORY.md golden-ci-platform-gate). Tests at lines 114 and 132 of the golden test use `'¥'` for CNY — those assertions must change to `'CN¥'`.

---

### `lib/shared/utils/currency_conversion.dart` (utility, transform)

**Analog:** `lib/shared/utils/result.dart` — pure static utility class pattern (lines 1-19):
```dart
/// Simple Result type for use case return values.
class Result<T> {
  final T? data;
  const Result._({...});
  factory Result.success(T? data) => ...;
  factory Result.error(String message) => ...;
}
```

**Phase 40 shape — top-level function (simpler than class):**
```dart
/// Single canonical JPY conversion site for STORE-02.
///
/// Formula: (originalMinorUnits / subunitToUnit * rate).round()
/// All callers (preview and persist paths) MUST use this function.
/// [subunitToUnit]: 100 for USD/EUR/etc (cents), 1 for JPY.
int convertToJpy({
  required int originalMinorUnits,
  required String appliedRate,
  required int subunitToUnit,
}) {
  final rate = double.parse(appliedRate);
  return (originalMinorUnits / subunitToUnit * rate).round();
}
```

**No class wrapper needed** — unlike `Result<T>` this is a pure function with no type parameter or factory pattern.

---

### `test/unit/data/migrations/schema_v21_migration_test.dart` (test, CRUD)

**Analog:** `test/unit/data/migrations/shopping_items_v20_contract_test.dart`

**Test structure pattern** (shopping_items_v20_contract_test.dart lines 1-153):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  // Test 1: Drift schemaVersion guard
  test('AppDatabase schemaVersion is 20', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    expect(db.schemaVersion, equals(20));
  });

  // Test 2: index creation via sqlite_master
  test('real Drift schema creates all shopping_items indices', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND tbl_name = 'shopping_items'",
        )
        .get();
    final indexNames = rows.map((r) => r.read<String>('name')).toSet();
    expect(indexNames, containsAll(['idx_shopping_list_type', ...]));
  });

  // Test 3: physical schema with raw sqlite3 (column checks, CHECK constraints)
  group('shopping_items v20 physical schema', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV20ShoppingItemsTable(rawDb);
    });
    tearDown(() => rawDb.dispose());

    test('shopping_items table has correct column names', () { ... });
    test("list_type CHECK rejects 'shared'", () { ... });
  });
}

// Helper: raw DDL function for the table under test
void _createV20ShoppingItemsTable(Database db) {
  db.execute('''CREATE TABLE shopping_items (...) ''');
}

void _insertRow(Database db, { String id = 'item_test' }) { ... }
```

**Phase 40 test file covers:**
1. `schemaVersion` is 21
2. `exchange_rates` index created on fresh install
3. `transactions` has the three new nullable columns after upgrade
4. `exchange_rates` columns are correct types
5. Nullable columns in `transactions` accept NULL values
6. Partial-triple: `HashChainService.calculateTransactionHash` signature does not include currency fields

---

### `test/unit/data/daos/exchange_rate_dao_test.dart` (test, CRUD)

**Analog:** `test/unit/data/migrations/shopping_items_v20_contract_test.dart` + `lib/data/daos/shopping_item_dao.dart`

**DAO test pattern uses `AppDatabase.forTesting()` (in-memory):**
```dart
void main() {
  late AppDatabase db;
  late ExchangeRateDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = ExchangeRateDao(db);
  });

  tearDown(() => db.close());

  test('findByDate returns null when empty', () async { ... });
  test('upsert inserts and findByDate retrieves', () async { ... });
  test('findLatest returns most-recent when multiple dates exist', () async { ... });
  test('upsert on conflict updates the rate', () async { ... });
}
```

---

## Shared Patterns

### Drift DAO constructor
**Source:** `lib/data/daos/shopping_item_dao.dart` (lines 11-13)
**Apply to:** `exchange_rate_dao.dart`
```dart
class ExchangeRateDao {
  ExchangeRateDao(this._db);
  final AppDatabase _db;
```

### Repository implementation constructor
**Source:** `lib/data/repositories/shopping_item_repository_impl.dart` (lines 20-29)
**Apply to:** `exchange_rate_repository_impl.dart`
```dart
class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  ShoppingItemRepositoryImpl({required ShoppingItemDao dao, ...}) : _dao = dao;
  final ShoppingItemDao _dao;
```

### Freezed nullable field (no `@Default`)
**Source:** `lib/features/accounting/domain/models/transaction.dart` (lines 24-28) and `lib/features/shopping_list/domain/models/shopping_item.dart`
**Apply to:** `transaction.dart` (new fields), `exchange_rate.dart`
```dart
String? note,        // nullable, no @Default = implicitly null
int? estimatedPrice, // nullable int
DateTime? completedAt, // nullable DateTime
```

### Result.error validation return
**Source:** `lib/shared/utils/result.dart` (lines 14-16) + `lib/application/accounting/create_transaction_use_case.dart` (lines 78-86)
**Apply to:** `create_transaction_use_case.dart` (partial-triple check), partial-triple validation
```dart
if (condition) {
  return Result.error('descriptive error message');
}
```

### Riverpod `@riverpod` code-gen provider
**Source:** `lib/application/accounting/repository_providers.dart` (lines 19-22)
**Apply to:** `lib/application/currency/repository_providers.dart`
```dart
@riverpod
SomeType appSomeProvider(Ref ref) {
  return ref.watch(otherProvider);
}
```
Note: `part 'repository_providers.g.dart'` must be present; run build_runner after adding.

### Explicit `CREATE INDEX` helper
**Source:** `lib/data/app_database.dart` (lines 450-471)
**Apply to:** v20→v21 migration block + `onCreate` in `app_database.dart`
```dart
Future<void> _createShoppingItemIndexes() async {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_name ON table (col)',
  );
}
// Called from BOTH onCreate and the from < N upgrade block.
```

### `insertOnConflictUpdate` for upsert
**Source:** `lib/data/daos/shopping_item_dao.dart` (lines 126-128)
**Apply to:** `exchange_rate_dao.dart`
```dart
Future<void> upsert(ShoppingItemsCompanion item) async {
  await _db.into(_db.shoppingItems).insertOnConflictUpdate(item);
}
```

---

## No Analog Found

None — all files have suitable analogs in the codebase.

---

## Key Anti-Patterns (from RESEARCH.md — must NOT copy)

| Anti-Pattern | Where the bug lives | Correct pattern |
|---|---|---|
| `RealColumn get appliedRate` on `transactions` | Do not copy from any existing `RealColumn` usage | Use `TextColumn get appliedRate => text().nullable()()` (D-04) |
| `customIndices` as sole index mechanism | `transactions_table.dart` lines 51-58 (illustrative only — those indices are also decorative) | Add `_createExchangeRateIndexes()` to both `onCreate` and `from < 21` |
| `data['originalCurrency'] as String` (non-nullable cast) | — | Must be `data['originalCurrency'] as String?` |
| Including currency fields in hash formula | — | `HashChainService.calculateTransactionHash` signature stays unchanged |
| Golden re-baseline on non-macOS | — | Run `--update-goldens` on macOS only |

---

## Metadata

**Analog search scope:** `lib/data/`, `lib/features/`, `lib/application/`, `lib/infrastructure/`, `lib/shared/`, `test/`
**Files scanned:** 16 source files read directly
**Pattern extraction date:** 2026-06-12
