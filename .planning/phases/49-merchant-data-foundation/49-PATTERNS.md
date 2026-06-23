# Phase 49: Merchant Data Foundation - Pattern Map

**Mapped:** 2026-06-23
**Files analyzed:** 12 create + 2 modify = 14
**Analogs found:** 13 / 14 (1 genuinely new — encrypted-executor integration test — closest-precedent only)

> Almost every file in this phase is a **copy-and-adapt** of an existing repo pattern. The two artifacts with no real precedent are the **hand-written normalizer** and the **encrypted-executor migration ladder test**. Everything else has an exact analog with verified line ranges below.

> **MEMORY.md gotcha honored throughout:** `drift-customindices-is-decorative` — `customIndices` getter does NOT create indexes. Indexes MUST be emitted as explicit `CREATE INDEX IF NOT EXISTS` in a single-point `_createMerchantIndexes()` helper called from **BOTH** `onCreate` **AND** the `if (from < 22)` onUpgrade block. (D-02)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|-------------------|------|-----------|----------------|-------|
| `lib/data/tables/merchants_table.dart` | table | CRUD | `lib/data/tables/exchange_rates_table.dart` | exact |
| `lib/data/tables/merchant_match_keys_table.dart` | table | CRUD | `lib/data/tables/shopping_items_table.dart` (FK via customConstraints) + `exchange_rates_table.dart` | exact |
| `lib/data/daos/merchant_dao.dart` | dao | CRUD | `lib/data/daos/exchange_rate_dao.dart` | exact |
| `lib/data/repositories/merchant_repository_impl.dart` | repository | CRUD | `lib/data/repositories/category_repository_impl.dart` | exact |
| `lib/features/accounting/domain/repositories/merchant_repository.dart` | repository (interface) | CRUD | `lib/features/accounting/domain/repositories/category_repository.dart` | exact |
| `lib/application/accounting/seed_merchants_use_case.dart` | use case | batch/seed | `lib/application/accounting/seed_categories_use_case.dart` | exact |
| `lib/infrastructure/ml/merchant_name_normalizer.dart` | utility (infra) | transform | *(no analog — RESEARCH confirms none reusable)* | none |
| `lib/shared/constants/default_merchants.dart` | config/const data | — | `lib/shared/constants/default_categories.dart` | exact |
| `integration_test/merchant_migration_ladder_test.dart` | test (integration) | — | `test/unit/data/migrations/schema_v21_migration_test.dart` + `category_v14_migration_test.dart` + `encrypted_database.dart` | role-only (new dir) |
| `test/unit/data/migrations/merchant_v22_migration_test.dart` | test (unit) | — | `test/unit/data/migrations/schema_v21_migration_test.dart` | exact |
| `test/unit/application/accounting/seed_merchants_use_case_test.dart` | test (unit) | — | `seed_categories_use_case` tests | role-match |
| `test/unit/.../default_merchants_categoryid_test.dart` | test (unit, hard gate) | — | *(new — assert categoryId ∈ L2 set)* | role-only |
| **MODIFY** `lib/data/app_database.dart` | data (migrator) | — | `_createExchangeRateIndexes()` + `from < 21` block (this file) | exact (in-file) |
| **MODIFY** `lib/application/seed/seed_all_use_case.dart` (+ providers + test) | use case (orchestration) | — | how `SeedCategoriesUseCase` is wired in (this file) | exact (in-file) |

---

## Pattern Assignments

### `lib/data/tables/merchants_table.dart` (table, CRUD)

**Analog:** `lib/data/tables/exchange_rates_table.dart` (full file, 77 lines)

**Table-def + decorative-index doc-comment to mirror** (`exchange_rates_table.dart:27-77`):
```dart
/// NOTE: customIndices is DECORATIVE (v1.6 CR-01 lesson). Index created explicitly
/// via _createExchangeRateIndexes() in AppDatabase.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currency => text()();
  TextColumn get rate => text()();
  @override
  Set<Column> get primaryKey => {currency, rateDate};

  // Index declarations (no @override — CLAUDE.md pitfall #11). NOTE: Drift's
  // migrator does NOT consume this getter; the index is created explicitly in
  // AppDatabase._createExchangeRateIndexes() (onCreate + onUpgrade).
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_exchange_rates_currency_date', columns: {#currency, #rateDate}),
  ];
}
```

**What differs for merchants:**
- Columns: `id` (`text()()`, stable string PK), `nameJa` (`text()()` required), `nameZh`/`nameEn` (`text().nullable()()`), `region` (`text().withDefault(const Constant('JP'))()` — companion-layer default, see `shopping_items_table.dart:12` `listType` precedent), `categoryId` (`text()()` real L2), `ledgerHint` (`text()()` — seed-derived from categoryId, D-09).
- `Set<Column> get primaryKey => {id};` (single stable string id, e.g. `mer_seven_eleven`).
- `customIndices`: `idx_merchants_region` (`{#region}`), `idx_merchants_category` (`{#categoryId}`) — DECORATIVE; real creation in `_createMerchantIndexes()`.
- Multilingual names are **DATA columns, not ARB** (ROADMAP i18n: merchant-names-as-data).

---

### `lib/data/tables/merchant_match_keys_table.dart` (table, CRUD)

**Analog:** `lib/data/tables/shopping_items_table.dart` (FK via `customConstraints`, line 58) + `exchange_rates_table.dart` (decorative-index style)

**FK pattern to mirror** (`shopping_items_table.dart:55-69`):
```dart
@override
Set<Column> get primaryKey => {id};

List<String> get customConstraints => [ /* FK / composite constraints as raw SQL */ ];

List<TableIndex> get customIndices => [ /* DECORATIVE */ ];
```

**What differs:**
- Columns: row `id` (`text()()` PK, or composite), `merchantId` (`text()()` FK → merchants.id), `surface` (`text()()` original form), `matchKey` (`text()()` seed-normalized, INDEXED), `kind` (`text()()` — `name`|`alias`|`locale`).
- FK declared via `customConstraints` raw SQL (`REFERENCES merchants(id)`).
- **`match_key` index is NON-UNIQUE** — cross-merchant collisions are legal (RESEARCH finding #6, anti-pattern: never `UNIQUE` on `match_key`). Disambiguation is Phase 50's job.
- Seed inserter must tolerate duplicate `(merchant_id, match_key)` (name==alias after normalization) via `INSERT OR IGNORE` on a stable PK.
- `customIndices`: `idx_merchant_match_keys_key` (`{#matchKey}`), `idx_merchant_match_keys_merchant` (`{#merchantId}`) — DECORATIVE.

---

### `lib/data/daos/merchant_dao.dart` (dao, CRUD)

**Analog:** `lib/data/daos/exchange_rate_dao.dart` (full file, 104 lines)

**Plain-class DAO shape to mirror** (`exchange_rate_dao.dart:13-16, 49-51, 101-103`):
```dart
class ExchangeRateDao {
  ExchangeRateDao(this._db);
  final AppDatabase _db;

  Future<void> upsert(ExchangeRatesCompanion companion) async {
    await _db.into(_db.exchangeRates).insertOnConflictUpdate(companion);
  }

  Future<List<ExchangeRateRow>> findAll() async {
    return _db.select(_db.exchangeRates).get();
  }
}
```

**What differs:**
- Plain class taking `AppDatabase` — **NOT** `@DriftAccessor` (RESEARCH finding #5: recent DAOs are plain wrappers; only `group_dao`/`group_member_dao` use `@DriftAccessor`).
- Methods: `findAll()` (count guard), batch insert of merchant rows + match-key rows. Use Drift **companions / `insertBatch`**, NOT string-interpolated `customStatement` (Security: avoid the v14-block interpolation style for DATA — finding #5 / Security Domain).
- Wrap the full seed expansion in **one transaction** (`_db.transaction(...)`) with `INSERT OR IGNORE` (`insertOnConflictUpdate` or `mode: InsertMode.insertOrIgnore`).

---

### `lib/data/repositories/merchant_repository_impl.dart` (repository, CRUD)

**Analog:** `lib/data/repositories/category_repository_impl.dart` (lines 1-60)

**Impl shape to mirror** (`category_repository_impl.dart:1-10, 49-60`):
```dart
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../app_database.dart';
import '../daos/category_dao.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryDao dao}) : _dao = dao;
  final CategoryDao _dao;

  @override
  Future<List<Category>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }
}
```

**What differs:** maps `MerchantRow`/`MerchantMatchKeyRow` → a domain `Merchant` model (define in `lib/features/accounting/domain/models/`); `insertBatch(List<Merchant>)` delegates to the DAO's transactional batch.

---

### `lib/features/accounting/domain/repositories/merchant_repository.dart` (interface, CRUD)

**Analog:** `lib/features/accounting/domain/repositories/category_repository.dart` (full file)

**Interface shape to mirror** (`category_repository.dart:4-19`):
```dart
abstract class CategoryRepository {
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<void> insertBatch(List<Category> categories);
}
```

**What differs:** `MerchantRepository` exposes `findAll()` (drives the seed count-guard), `findById(String)`, `insertBatch(...)`. **Domain imports neither `data/` nor `infrastructure/`** (layer rule). Phase 49 defines the interface shape; Phase 50's `MerchantRecognizer` is the first consumer — do NOT wire consumers now.

---

### `lib/application/accounting/seed_merchants_use_case.dart` (use case, batch/seed)

**Analog:** `lib/application/accounting/seed_categories_use_case.dart` (full file, 30 lines)

**Count-guarded idempotent seed to mirror** (`seed_categories_use_case.dart:20-29`):
```dart
Future<Result<void>> execute() async {
  final existing = await _categoryRepo.findAll();
  if (existing.isNotEmpty) {
    return Result.success(null);
  }
  await _categoryRepo.insertBatch(DefaultCategories.all);
  await _configRepo.upsertBatch(DefaultCategories.defaultLedgerConfigs);
  return Result.success(null);
}
```

**What differs:**
- `findAll()` on `MerchantRepository`; if empty, expand `DefaultMerchants` → N merchant rows + M match-key rows, all in **one transaction** with `INSERT OR IGNORE` (D-05).
- For each merchant: derive `ledgerHint` from `categoryId` via the shared map (D-09, see Shared Pattern below) — do NOT hand-write per-merchant ledger.
- For each surface form (name + aliases + locale names): compute `matchKey = normalizeMerchantKey(surface)` (the new infra normalizer) and insert a `merchant_match_keys` row.
- Re-seed convergence (Crit #3): stable authored ids + `INSERT OR IGNORE` → double-launch leaves row counts unchanged.

---

### `lib/infrastructure/ml/merchant_name_normalizer.dart` (utility, transform) — NO ANALOG

**Closest reference:** none reusable. RESEARCH finding #2/#3 confirms: repo has NO Unicode NFKC utility; `VoiceTextParser`/`voice_category_resolver` "normalize" are numeral-tokenizers / L2-category resolvers, not text folders. Current merchant lookup is `.toLowerCase()` only (`merchant_database.dart:132`).

**Hand-written pipeline (zero new deps, D-03)** — RESEARCH provided working code (Code Examples §):
```dart
String normalizeMerchantKey(String input) {
  final buf = StringBuffer();
  for (final rune in input.runes) {
    var r = rune;
    if (r >= 0xFF01 && r <= 0xFF5E) {
      r -= 0xFEE0;                 // fullwidth ASCII → halfwidth
    } else if (r == 0x3000) {
      r = 0x20;                    // ideographic space → ASCII space
    } else if (r >= 0x30A1 && r <= 0x30F6) {
      r -= 0x60;                   // katakana → hiragana
    }
    buf.writeCharCode(r);
  }
  return buf.toString()
      .toLowerCase()
      .replaceAll('・', '')
      .replaceAll(RegExp(r'\s+'), '');
}
```

**Build it COMPLETE now** (steps 1-3 mandatory; add half-width katakana U+FF61..FF9F + combining dakuten U+3099/309A handling) so Phase 50's query-time consumer reuses the SAME function unchanged. Pitfalls: NFKC alone does NOT fold kana case (step 2 is a separate deliberate fold); keep `ー` (U+30FC) in the key (stripping over-merges); leave 小書き small kana as-is (meaningful). Unit-test **property-style** (table of input/expected pairs).

---

### `lib/shared/constants/default_merchants.dart` (config/const data)

**Analog:** `lib/shared/constants/default_categories.dart`

**Const-list-with-getter pattern to mirror** (`default_categories.dart:6-13`):
```dart
abstract final class DefaultCategories {
  static List<Category> get all => [...expenseL1, ..._expenseL2];
  static List<CategoryLedgerConfig> get defaultLedgerConfigs => _defaultLedgerConfigs;
}
```

**What differs:**
- `abstract final class DefaultMerchants { static List<DefaultMerchant> get all => [...]; }`.
- Each row: stable `id` (`mer_<ascii_slug>`, authored as DATA — never generated from JP name at seed time, finding #6), `nameJa`, `nameZh?`, `nameEn?`, `aliases` (List, kind=alias surface forms), `categoryId` (real L2). **No per-merchant ledger** (derived).
- Seed core = existing 12 `_MerchantEntry` in `merchant_database.dart:46+` (name/aliases/categoryId already D-04-verified) — port + expand to ~400 (D-08, Claude authors). Aliases keep hand-written romaji (`'Starbucks'`/`'mcdonalds'`/`'マック'`) per D-04.
- Split by category group into multiple files aggregated by `DefaultMerchants.all` (~400 × multi-field exceeds 800-line guideline; RESEARCH Open Q #2).

---

### `lib/data/app_database.dart` (MODIFY — migrator)

**In-file analogs (exact line ranges verified):**

1. **Register tables + bump version** — `@DriftDatabase(tables: [...])` at lines **25-41**; add `Merchants, MerchantMatchKeys`. `schemaVersion => 21` at line **49** → `22`.

2. **onCreate explicit-index calls** — lines **54-62**:
```dart
onCreate: (migrator) async {
  await migrator.createAll();
  await _createShoppingItemIndexes();
  await _createExchangeRateIndexes();
  // ADD: await _createMerchantIndexes();
},
```

3. **onUpgrade step shape** — mirror the `from < 21` block at lines **445-463**:
```dart
if (from < 21) {
  await migrator.createTable(exchangeRates);
  await _createExchangeRateIndexes();
  await customStatement('ALTER TABLE transactions ADD COLUMN original_currency TEXT');
}
```
ADD after it:
```dart
if (from < 22) {
  await migrator.createTable(merchants);
  await migrator.createTable(merchantMatchKeys);
  await _createMerchantIndexes();   // single-point helper — BOTH paths
}
```

4. **Single-point index helper** — mirror `_createExchangeRateIndexes()` at lines **496-506** (and `_createShoppingItemIndexes()` 468-494):
```dart
Future<void> _createMerchantIndexes() async {
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_key '
      'ON merchant_match_keys (match_key)');
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_merchant '
      'ON merchant_match_keys (merchant_id)');
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchants_region '
      'ON merchants (region)');
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchants_category '
      'ON merchants (category_id)');
}
```
**CRITICAL:** call from BOTH onCreate (step 2) AND the `from < 22` block (step 3). This is the `drift-customindices-is-decorative` gotcha. Run `build_runner` after editing (regenerates `app_database.g.dart`).

---

### `lib/application/seed/seed_all_use_case.dart` (MODIFY — orchestration) + providers + test

**In-file analog (verified):** the existing two-leaf composition at lines **18-37**:
```dart
class SeedAllUseCase {
  SeedAllUseCase({
    required SeedCategoriesUseCase seedCategories,
    required SeedVoiceSynonymsUseCase seedVoiceSynonyms,
  }) : _seedCategories = seedCategories, _seedVoiceSynonyms = seedVoiceSynonyms;

  Future<Result<void>> execute() async {
    final categoriesResult = await _seedCategories.execute();
    if (!categoriesResult.isSuccess) return categoriesResult;
    return _seedVoiceSynonyms.execute();
  }
}
```

**What differs:**
- Add `SeedMerchantsUseCase` as a **third leaf** (constructor param + field), executed AFTER categories (merchant `categoryId` must validate against seeded L2s). Short-circuit on prior failure (same pattern).
- Wire its provider in `seed_providers.dart`; update `test/unit/application/seed/seed_all_use_case_test.dart` for the third leaf.
- **Pitfall #1 (RESEARCH):** D-06 says "main.dart:65 seedRunner" but that callback is a **deliberate no-op** (`main.dart:64`, `app_initializer.dart:108`). Real seeding runs in `HomePocketApp._initialize()` → `seedAllUseCaseProvider.execute()` (`main.dart:112-113`). **Wire into `SeedAllUseCase`, NOT the `seedRunner` no-op.** Leave `seedRunner: (_) async {}` untouched.

---

### Provider wiring (in `lib/features/accounting/presentation/providers/repository_providers.dart`)

**Analog (verified):** `categoryRepository` provider at lines **69-75**:
```dart
@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = CategoryDao(database);
  return CategoryRepositoryImpl(dao: dao);
}
```
**Add:** a `merchantRepository` `@riverpod` provider following the identical 3-line shape (`appAppDatabaseProvider` → `MerchantDao(database)` → `MerchantRepositoryImpl(dao: ...)`). Run `build_runner` (regenerates `.g.dart`).

---

### `integration_test/merchant_migration_ladder_test.dart` (NEW — encrypted ladder) — NO PRECEDENT

**Closest analogs (combine three):**
- `test/unit/data/migrations/schema_v21_migration_test.dart` (lines 30-43) — PRAGMA/`sqlite_master` assertion style; notes it only exercises onCreate.
- `test/unit/data/migrations/category_v14_migration_test.dart` (lines 14-24) — hand-rolled raw-SQL-seed + `_runVNMigrationSteps` ladder doc-comment.
- `lib/infrastructure/crypto/database/encrypted_database.dart:21,40-51` — `createEncryptedExecutor(MasterKeyRepository, {inMemory})`; `_setupEncryption` asserts `PRAGMA cipher_version` non-empty (throws `StateError('SQLCipher not loaded')` otherwise).

**Assertion pattern to mirror** (`schema_v21_migration_test.dart:30-38`):
```dart
final rows = await db.customSelect(
  "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='merchants'").get();
expect(rows.map((r) => r.read<String>('name')).toSet(),
       containsAll(['idx_merchant_match_keys_key', /* ... */]));
final idx = await db.customSelect('PRAGMA index_list(merchants)').get();
expect(idx, isNotEmpty);
```

**What differs / why no analog:**
- **NEW `integration_test/` dir** (does not exist). Verify `integration_test:` is in `dev_dependencies` (Flutter SDK package); add `integration_test: { sdk: flutter }` if absent.
- Must run on **device/simulator** where `sqlcipher_flutter_libs` natives load — host `flutter test` links plain libsqlite3, so `createEncryptedExecutor` throws (Pitfall #2). Assert `PRAGMA cipher_version` non-empty INSIDE the test.
- For reopen-and-upgrade across two executor instances, `NativeDatabase.memory()` does NOT persist — use `createEncryptedExecutor(keyRepo, inMemory: false)` against a temp file.
- Ladder steps {fresh v22, v21→v22, v17→v22, v3→v22}. RESEARCH recommends: full host-VM ladder (memory, `merchant_v22_migration_test.dart`) for all four + encrypted integration test covering at least fresh-v22 and v21→v22 (the only real v1.8-user path). Gate on-device behind `checkpoint:human-verify` if no simulator CI.

---

## Shared Patterns

### Idempotent count-guarded seed
**Source:** `lib/application/accounting/seed_categories_use_case.dart:20-29`
**Apply to:** `SeedMerchantsUseCase`
`findAll()` → if non-empty return success → else single-transaction batch insert with stable ids + `INSERT OR IGNORE`. Post-open (runs every launch, inserts only when empty) covers fresh + upgrade uniformly (why D-05 chose post-open over migrator-seed).

### Single-point explicit-index helper (decorative-customIndices defense)
**Source:** `lib/data/app_database.dart:496-506` (`_createExchangeRateIndexes`) + `468-494` (`_createShoppingItemIndexes`)
**Apply to:** `_createMerchantIndexes()` — called from onCreate (54-62) AND `from < 22` block. (MEMORY.md `drift-customindices-is-decorative`, CR-01 Phase 36.)

### ledger_hint derivation from categoryId (single source of truth)
**Source:** `lib/shared/constants/default_categories.dart:12-13, 1192` (`_defaultLedgerConfigs`) + precedence from `lib/application/accounting/category_service.dart:26-41` (`resolveLedgerType`)
**Apply to:** seed-time `ledgerHint` for every merchant (D-09). Evaluate against the const list (no DB round-trip):
```dart
LedgerType deriveLedgerHint(String categoryId) {
  final configs = DefaultCategories.defaultLedgerConfigs;
  final direct = configs.where((c) => c.categoryId == categoryId);  // L1 or L2-override
  if (direct.isNotEmpty) return direct.first.ledgerType;
  final cat = DefaultCategories.all.firstWhere((c) => c.id == categoryId);
  final parent = configs.firstWhere((c) => c.categoryId == cat.parentId); // L2 inherits L1
  return parent.ledgerType;
}
```
Do NOT hand-write a second merchant→ledger map. Derived value WINS over the old 12-entry hand tags — expected diffs: `Amazon`/`ヤマダ電機` were tagged `joy` but derive to `daily`; surface these at commit review (D-08 spot-check), not as bugs.

### Plain-class DAO + provider wiring
**Source:** `lib/data/daos/exchange_rate_dao.dart:13-16` + `repository_providers.dart:69-75`
**Apply to:** `MerchantDao` (plain class taking `AppDatabase`, not `@DriftAccessor`) + `merchantRepository` `@riverpod` provider.

### Security: parameterized seed inserts, never log raw names
**Source:** CLAUDE.md crypto rules + RESEARCH Security Domain
**Apply to:** DAO/seed — build `merchant_match_keys` inserts via Drift companions / `insertBatch`, NOT string-interpolated `customStatement` (do NOT copy the v14 interpolation style for DATA). Reuse `createEncryptedExecutor` unchanged (no second key path). Seed list is public/non-sensitive but never log raw matched merchant names.

---

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| `lib/infrastructure/ml/merchant_name_normalizer.dart` | utility/transform | RESEARCH finding #2/#3: repo has NO reusable Unicode NFKC / kana-fold code. RESEARCH supplies complete hand-written code. Build complete (incl. half-width-kana + combining marks) so Phase 50 reuses unchanged. |
| `integration_test/merchant_migration_ladder_test.dart` | test (integration) | No `integration_test/` dir or encrypted-executor test exists. Closest precedents (hand-rolled migration test + `createEncryptedExecutor`) combined into a new device/sim harness. Highest-risk item (Crit #4). |
| `test/unit/.../default_merchants_categoryid_test.dart` | test (hard gate) | New guard: assert every `DefaultMerchants.categoryId` ∈ `{DefaultCategories L2 ids}` (139 L2s). Prevents D-04-class silent-null bug. |

---

## Metadata

**Analog search scope:** `lib/data/tables/`, `lib/data/daos/`, `lib/data/repositories/`, `lib/features/accounting/domain/repositories/`, `lib/application/{accounting,seed}/`, `lib/shared/constants/`, `lib/infrastructure/{ml,crypto}/`, `test/unit/data/migrations/`
**Files read (verified line ranges):** `exchange_rates_table.dart`, `exchange_rate_dao.dart`, `seed_categories_use_case.dart`, `app_database.dart` (1-75, 430-507), `seed_all_use_case.dart`, `category_repository.dart`, `category_repository_impl.dart` (1-60), `category_service.dart` (20-44), `shopping_items_table.dart` (grep), `default_categories.dart` (grep), `merchant_database.dart` (grep), `repository_providers.dart` (grep + 69-84)
**Pattern extraction date:** 2026-06-23
