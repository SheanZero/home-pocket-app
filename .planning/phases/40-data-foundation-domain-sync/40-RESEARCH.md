# Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) - Research

**Researched:** 2026-06-12
**Domain:** Drift schema migration v20→v21, ADR documentation, NumberFormatter disambiguation, Freezed model extension, sync mapper backward-compat
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: 外币行的日元金额只读。** 编辑页中外币行不可直接修改日元金额；只能修改原币金额和汇率，日元金额始终由 `(originalAmount × appliedRate).round()` 派生。这把 DISP-04 的「三字段双向联动」收窄为「双输入（原币金额、汇率）单派生（日元）」——ADR-022 与 Phase 42 计划必须按此口径执行，REQUIREMENTS.md DISP-04 措辞需同步修正。

**D-02: 手动覆盖汇率后改日期 → 弹窗询问用户**「保留手动汇率，还是按新日期重取？」。这是 RATE-06（"覆盖不被踩"）与 Phase 41 成功标准 4（"除非覆盖后主动改日期"）矛盾的正式定案：既不静默保留也不静默重取。

**D-03: 无覆盖、改日期重取导致日元金额变化 >1% → 非阻断 toast + 可撤销。** 直接重算并提示金额变化，提供撤销恢复旧汇率；不阻断保存（与 never-block-save 不变量一致）。ROADMAP Phase 41 成功标准 4 的「确认信号」按此形态理解。

**D-04: 全程 String。** DB `TextColumn`（已锁定）、Freezed 字段 `String? appliedRate`、sync wire 传字符串；唯一的 round() 转换工具内部 `double.parse` 后相乘。与 sync mapper 现有 `merchant`/`photoHash` 的 String 透传模式同构。

**D-05: 原样保存，不规范化。** API 来源存 JSON 数字的十进制字面量，手动输入存用户原文（trim 后）；只做有效性校验（可解析为正 double），不改写。比较汇率是否变化用数值比较而非字符串比较。

**D-06: 建立完整符号消歧表**，不是只修 CNY。表内明确：CN¥（CNY）、US$（USD）、HK$（HKD）、A$（AUD）、C$（CAD）、NT$（TWD）等所有 `$`/`¥` 系碰撞币种；JPY 保持 `¥` 不变。

**D-07: 表外冷门币种回退 ISO 代码前缀格式**（如 `XXX 1,234.56`），不依赖 intl 各 locale 的默认符号差异，保证 golden 可锁定。

**D-08: KRW 特例本 phase 一并做：** 0 小数显示（ISO subunit=100 但显示惯例 0 位）+ ₩ 符号写进同一张消歧表，避免 Phase 42 二次 golden 重基。

**D-09: 列集 = (currency, rateDate) 主键 + rate + fetchedAt + source + actualRateDate。** fetchedAt：支撑 RATE-02「今日汇率短 TTL」的持久判定（重启不失效）。source：frankfurter / fawazahmed0 / manual，审计可追溯。actualRateDate：周末/节假日请求拿到回溯营业日汇率时记录实际汇率日（RATE-05 的数据基础）。TTL 时长与判定逻辑归 Phase 41 服务层；表只存数据。

### Claude's Discretion

- ADR-022 的次要细节：撤销窗口时长、新建 vs 编辑路径的策略复用方式。
- appliedRate 有效性校验细节（正数、可解析、上下限、科学计数法拒绝等）。
- 符号消歧表的具体币种清单（常用 6 币 + $ 系碰撞币 + Frankfurter 30 币范围内取舍），表外自动回退 ISO 代码。
- `exchange_rates` 索引设计（latest-for-currency 查询需要 `(currency, rateDate DESC)` 形态——记得 v1.6 教训：`customIndices` 是装饰性的，必须在 onCreate + onUpgrade 显式 `CREATE INDEX`）。
- ADR 编号：现有最大 ADR-019，本 phase 三个 ADR 顺延 ADR-020/021/022，并更新 ADR-000_INDEX.md。

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

（注意：D-01 对 DISP-04 的口径收窄不是 deferred，是对 Phase 42 需求的已定修正，planner 在 Phase 42 时必须采用。）

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STORE-01 | Foreign-currency transactions store JPY-converted amount in `amount` plus three new nullable fields (`originalCurrency`, `originalAmount`, `appliedRate`); Drift schema v20→v21; NULL fields = native-JPY row | Drift migration pattern confirmed from v19→v20 (`shopping_items`); three nullable `ALTER TABLE` statements; `ExchangeRates` table with composite PK |
| STORE-02 | JPY conversion follows integer contract: `(originalAmount × appliedRate).round()` — fractional yen never stored anywhere | Single shared rounding utility; `appliedRate` stored as `TextColumn` (D-04); `double.parse` inside utility only |
| STORE-03 | Three new fields transit family sync null-safely in both directions — older payloads apply as JPY rows; new payloads round-trip losslessly | `TransactionSyncMapper` conditional emit + null-safe read pattern confirmed from `merchant`/`photoHash`/`note` precedents |
| STORE-04 | Hash-chain scope decision recorded as ADR before migration work; new currency fields excluded from hash formula; existing chains stay valid | `HashChainService.calculateTransactionHash` signature confirmed: only `transactionId`, `amount`, `timestamp`, `previousHash` — new fields excluded; ADR-021 |
| STORE-05 | CNY and JPY currency symbols disambiguated in `NumberFormatter`; full disambiguation table including KRW; golden tests reflect new symbols | Bug confirmed at `number_formatter.dart:56-57`; 6 CNY goldens need re-baseline (`amount_display_cny.png`, `amount_display_cny_dark.png` + others) |

</phase_requirements>

---

## Summary

Phase 40 is the data-and-domain foundation for the entire v1.7 multi-currency milestone. No new external network calls happen in this phase — all work is internal: three ADR documents, a Drift schema migration, new data/domain layer components, a `NumberFormatter` symbol fix, `Transaction` Freezed extension, and sync mapper backward-compatibility updates.

The phase is composed of two logical halves that build on each other: (A) ADR decisions + schema migration + `ExchangeRateDao`/repo (the "data foundation") and (B) domain model extensions + sync mapper updates (the "domain + sync"). The ADR half must complete before any code changes land because the hash-scope and rate-precision decisions constrain the schema design. The v19→v20 migration (`shopping_items`) is the direct implementation template: same `from < N` guard, same `customStatement`-not-`addColumn` pattern, same explicit `CREATE INDEX` in both `onCreate` and `onUpgrade`.

The `NumberFormatter` fix (CNY → `CN¥`, KRW → `₩` with 0 decimals, plus a full disambiguation table and ISO-code fallback) is a deliberate pre-UI symbol fix. It causes a golden re-baseline of exactly 2 CNY golden files (`amount_display_cny.png`, `amount_display_cny_dark.png`) plus any new KRW/HKD/AUD/CAD/TWD/USD disambiguation goldens. This must happen before the UI phases so the re-baseline is an intentional, scoped event. The fix is a one-function change in `NumberFormatter._getCurrencySymbol` and a decimal-count change in `NumberFormatter._getCurrencyDecimals`.

**Primary recommendation:** Complete the three ADRs first (before any code), then run the schema migration, then extend domain models and sync mapper — following the established v1.6 build order for data-before-domain.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ADR documentation | — (docs layer) | — | Architecture decision records, not code; written before implementation |
| Drift schema migration v20→v21 | Data (`lib/data/`) | — | `app_database.dart` owns `schemaVersion` and `onUpgrade`; table def in `lib/data/tables/` |
| `exchange_rates` cache table + DAO | Data (`lib/data/`) | — | ALL tables in `lib/data/tables/`, ALL DAOs in `lib/data/daos/`, ALL repo impls in `lib/data/repositories/` |
| `ExchangeRate` Freezed model + repo interface | Domain (`lib/features/currency/domain/`) | — | "Thin Feature" pattern: domain folder holds only models + interfaces |
| `Transaction` Freezed model extension | Domain (`lib/features/accounting/domain/models/`) | — | Additive nullable fields to existing Freezed model |
| `TransactionSyncMapper` update | Domain (`lib/features/accounting/domain/models/`) | — | Sync boundary logic lives with the domain model it serializes |
| `CreateTransactionParams` extension + invariant | Application (`lib/application/accounting/`) | — | Business logic validation lives in use case params |
| `NumberFormatter` symbol disambiguation | Infrastructure (`lib/infrastructure/i18n/`) | — | Formatter is infrastructure/i18n concern per existing placement |
| Shared JPY rounding utility | Infrastructure or Application | — | Must be in a layer that both use cases and (future) UI can reach; `lib/shared/utils/` is appropriate |

---

## Standard Stack

### Core (No New Packages in Phase 40)

Phase 40 introduces no new pub.dev packages. All components are built on existing dependencies.

| Library | Version in Use | Purpose in This Phase |
|---------|---------------|----------------------|
| `drift` | `^2.25.0` [VERIFIED: pub.dev] | Schema migration v20→v21; new `ExchangeRates` table; `ExchangeRateDao` |
| `freezed_annotation` | `^3.0.0` [ASSUMED] | `Transaction` model extension; new `ExchangeRate` Freezed model |
| `build_runner` | `^2.4.14` [ASSUMED] | Regenerate `.g.dart` / `.freezed.dart` after Freezed changes |
| `flutter_riverpod` | `^3.1.0` [ASSUMED] | Riverpod provider wiring for `ExchangeRateRepository` |

Note: `currency_picker ^2.0.22` and `sealed_currencies ^3.2.0` are confirmed safe for future phases but are NOT needed in Phase 40 (no UI or ISO metadata queries happen here). [VERIFIED: pub.dev API] — both resolve cleanly against the current pubspec without intl conflicts, confirmed via `dart pub add --dry-run`.

### Packages Confirmed for Phase 41+ (Not Phase 40)

| Library | Version | Resolution Status |
|---------|---------|-------------------|
| `currency_picker` | `2.0.22` | [VERIFIED: pub.dev, published 2026-06-10] — clean resolution, no intl conflict |
| `sealed_currencies` | `3.2.0` | [VERIFIED: pub.dev, published 2026-05-21] — clean resolution, no intl in transitive chain |

### Installation (Phase 40 Only)

No new packages to install. Run `build_runner` after Freezed/Drift changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Package Legitimacy Audit

> Phase 40 installs zero new external packages. No audit required.
> `currency_picker` and `sealed_currencies` (Phase 41+) were pre-verified in prior v1.7 research (STACK.md) via pub.dev API and `dart pub add --dry-run` in this session.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| `currency_picker 2.0.22` | pub.dev | Published 2026-06-10, confirmed latest | Approved for Phase 41+ |
| `sealed_currencies 3.2.0` | pub.dev | Published 2026-05-21, no intl conflict | Approved for Phase 41+ |

*slopcheck was not available at research time. Both packages confirmed via pub.dev API (authoritative registry) with verified publication dates and version numbers.*

---

## Architecture Patterns

### System Architecture Diagram

```
ADR Documents (written first, before any code)
  ├── ADR-020: appliedRate = TextColumn, full precision string
  ├── ADR-021: currency fields excluded from hash formula
  └── ADR-022: edit semantics (D-01 JPY read-only, D-02/D-03 date-change policy)
           ↓
Schema Migration v20 → v21 (app_database.dart)
  ├── transactions: + original_currency TEXT, + original_amount INTEGER, + applied_rate TEXT
  └── exchange_rates: new table (currency PK, rate_date PK, rate REAL, fetched_at, source, actual_rate_date)
           + CREATE INDEX idx_exchange_rates_currency_date
           ↓
Data Layer (lib/data/)
  ├── tables/exchange_rates_table.dart  (ExchangeRates Drift table)
  ├── daos/exchange_rate_dao.dart        (findByDate, findLatest, upsert)
  └── repositories/exchange_rate_repository_impl.dart
           ↓
Domain Layer
  ├── lib/features/currency/domain/models/exchange_rate.dart      (Freezed)
  ├── lib/features/currency/domain/repositories/exchange_rate_repository.dart (interface)
  ├── lib/features/accounting/domain/models/transaction.dart      (+ 3 nullable fields)
  └── lib/features/accounting/domain/models/transaction_sync_mapper.dart (updated)
           ↓
Application Layer
  └── lib/application/accounting/create_transaction_use_case.dart (+ params + invariant)
           ↓
Infrastructure (no-code-change in Phase 40; fix only)
  └── lib/infrastructure/i18n/formatters/number_formatter.dart   (symbol disambiguation)

Sync Round-Trip
  Old device (v1.6) → v1.7 fromSyncMap: absent keys → null → JPY row ✓
  New device (v1.7) → old fromSyncMap: extra keys silently ignored ✓
```

### Recommended Project Structure (New Components)

```
lib/
├── data/
│   ├── tables/
│   │   └── exchange_rates_table.dart   # NEW — ExchangeRates Drift table
│   ├── daos/
│   │   └── exchange_rate_dao.dart       # NEW — findByDate, findLatest, upsert
│   └── repositories/
│       └── exchange_rate_repository_impl.dart  # NEW
├── features/
│   └── currency/
│       └── domain/
│           ├── models/
│           │   └── exchange_rate.dart   # NEW — Freezed model
│           └── repositories/
│               └── exchange_rate_repository.dart  # NEW — interface
├── infrastructure/
│   └── i18n/
│       └── formatters/
│           └── number_formatter.dart    # MODIFY — disambiguation table
└── shared/
    └── utils/
        └── currency_conversion.dart     # NEW — single rounding utility

docs/arch/03-adr/
├── ADR-020_Exchange_Rate_Precision.md  # NEW
├── ADR-021_Hash_Chain_Scope.md         # NEW
└── ADR-022_Edit_Semantics.md           # NEW
```

### Pattern 1: Drift Migration with Explicit Index (v19→v20 template)

The v19→v20 migration (`shopping_items`) is the canonical reference. Phase 40 follows the same pattern:

```dart
// Source: lib/data/app_database.dart (actual code, v19→v20)
if (from < 20) {
  await migrator.createTable(shoppingItems);
  await _createShoppingItemIndexes();  // explicit, not decorative customIndices
}

// Phase 40 mirrors this:
if (from < 21) {
  // New exchange_rates cache table
  await migrator.createTable(exchangeRates);
  await _createExchangeRateIndexes();

  // Three nullable columns on transactions (no DEFAULT — correct for nullable)
  await customStatement('ALTER TABLE transactions ADD COLUMN original_currency TEXT');
  await customStatement('ALTER TABLE transactions ADD COLUMN original_amount INTEGER');
  await customStatement('ALTER TABLE transactions ADD COLUMN applied_rate TEXT');
}

// Private helper — mirrors _createShoppingItemIndexes() exactly:
Future<void> _createExchangeRateIndexes() async {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_exchange_rates_currency_date '
    'ON exchange_rates (currency, rate_date)',
  );
}
```

[VERIFIED: direct codebase inspection of `lib/data/app_database.dart`]

### Pattern 2: TransactionSyncMapper Conditional Emit (existing pattern)

```dart
// Source: lib/features/accounting/domain/models/transaction_sync_mapper.dart
// Existing pattern for nullable fields (note, merchant, photoHash):
if (transaction.note != null) 'note': transaction.note,
if (transaction.merchant != null) 'merchant': transaction.merchant,
if (transaction.photoHash != null) 'photoHash': transaction.photoHash,

// Phase 40 adds (identical pattern):
if (transaction.originalCurrency != null)
  'originalCurrency': transaction.originalCurrency,
if (transaction.originalAmount != null)
  'originalAmount': transaction.originalAmount,
if (transaction.appliedRate != null)
  'appliedRate': transaction.appliedRate,

// fromSyncMap additions (null-safe cast):
originalCurrency: data['originalCurrency'] as String?,
originalAmount: data['originalAmount'] as int?,
appliedRate: data['appliedRate'] as String?,
```

[VERIFIED: direct codebase inspection of `transaction_sync_mapper.dart`]

### Pattern 3: Freezed Nullable Field (no @Default needed)

```dart
// Source: lib/features/accounting/domain/models/transaction.dart
// Existing nullable fields have no @Default annotation:
String? note,
String? photoHash,
String? merchant,

// Phase 40 adds three nullable fields identically:
String? originalCurrency,    // ISO 4217, e.g. 'USD'; null = JPY native
int? originalAmount,         // in minor units (cents for USD); null = JPY native
String? appliedRate,         // string, full precision per D-04; null = JPY native
```

[VERIFIED: direct codebase inspection of `transaction.dart`]

### Pattern 4: ExchangeRates Drift Table (column set per D-09)

```dart
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currency => text()();          // ISO 4217 code
  DateTimeColumn get rateDate => dateTime()();  // midnight UTC of the exchange day
  RealColumn get rate => real()();              // JPY per 1 unit of currency
  DateTimeColumn get fetchedAt => dateTime()(); // cache timestamp for TTL
  TextColumn get source => text()();            // 'frankfurter' | 'fawazahmed0' | 'manual'
  DateTimeColumn get actualRateDate => dateTime().nullable()(); // weekend fallback date

  @override
  Set<Column> get primaryKey => {currency, rateDate};

  // NOTE: customIndices is DECORATIVE (v1.6 lesson / CR-01).
  // Actual index must be created explicitly in _createExchangeRateIndexes().
}
```

### Pattern 5: NumberFormatter Symbol Disambiguation Table

```dart
// Source: lib/infrastructure/i18n/formatters/number_formatter.dart:54-68
// Current bug: JPY and CNY both return '¥'
// Fix per D-06/D-07/D-08:
static String _getCurrencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY': return '¥';        // ¥ — unambiguous in ja context
    case 'CNY': return 'CN¥';     // CN¥
    case 'KRW': return '₩';        // ₩ — D-08 KRW special case
    case 'USD': return r'$';           // already correct
    case 'EUR': return '€';       // € — already correct
    case 'GBP': return '£';       // £ — already correct
    case 'HKD': return 'HK\$';        // D-06 disambiguation
    case 'AUD': return 'A\$';         // D-06 disambiguation
    case 'CAD': return 'C\$';         // D-06 disambiguation
    case 'TWD': return 'NT\$';        // D-06 disambiguation
    case 'SGD': return 'S\$';         // D-06 disambiguation
    default: return currencyCode;      // D-07 ISO code prefix fallback
  }
}

static int _getCurrencyDecimals(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'KRW': return 0;              // D-08 KRW 0 decimals despite ISO subunit=100
    default: return 2;
  }
}
```

### Pattern 6: Shared JPY Rounding Utility

```dart
// lib/shared/utils/currency_conversion.dart (NEW)
/// Single canonical conversion site for STORE-02.
/// All callers (preview and persist) must use this function — no inline math.
int convertToJpy({required int originalMinorUnits, required String appliedRate, required int subunitToUnit}) {
  final rate = double.parse(appliedRate);
  return (originalMinorUnits * rate / subunitToUnit).round();
}
```

**Key:** The `subunitToUnit` divisor is needed because `originalAmount` stores minor units (cents for USD: `$12.50 → 1250`), but the rate is `JPY per 1 whole unit`. [ASSUMED — utility signature is Claude's discretion, but the formula is locked: `(originalAmount × appliedRate).round()` per STORE-02]

### Pattern 7: Partial-Triple Domain Invariant in CreateTransactionParams

```dart
// lib/application/accounting/create_transaction_use_case.dart — add to validate:
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

[VERIFIED: `Result.error` / `Result.success` pattern from `lib/shared/utils/result.dart`]

### Anti-Patterns to Avoid

- **`RealColumn` for `appliedRate` on `transactions`:** D-04 locks this as `TextColumn`. Precision loss on double re-multiplication causes preview-vs-stored divergence. [VERIFIED: Pitfall 1 in PITFALLS.md]
- **`customIndices` for `exchange_rates`:** The v1.6 CR-01 lesson: `customIndices` getter is decorative and not consumed by Drift's migrator. Always emit `CREATE INDEX` in both `onCreate` (via helper) and `onUpgrade`. [VERIFIED: codebase, `shopping_items_table.dart` comment on line 67]
- **`migrator.addColumn` for nullable columns:** Use `customStatement('ALTER TABLE ... ADD COLUMN ... TEXT')` for nullable columns without DEFAULT. The v17 `entry_source` migration used `customStatement` for the same reason (app_database.dart comment). [VERIFIED: direct codebase inspection]
- **Including currency fields in hash formula:** ADR-021 must lock these OUT of `HashChainService.calculateTransactionHash`. The current signature only takes `transactionId`, `amount`, `timestamp`, `previousHash` — do not extend it. [VERIFIED: hash_chain_service.dart lines 12-22]
- **Non-null cast in `fromSyncMap`:** `data['originalCurrency'] as String` (not `as String?`) would crash on any v1.6 sync payload. All three new fields must use `as T?`. [VERIFIED: existing pattern `data['joyFullness'] as int? ?? 2` in current sync mapper]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Drift migration boilerplate | Custom SQL schema manager | `migrator.createTable()` + `customStatement()` | Established pattern, idempotent, `IF NOT EXISTS` guards |
| Freezed serialization | Manual `toJson`/`fromJson` | `@freezed` with `part 'x.g.dart'` | Generated code handles nullability, copyWith, equality |
| Migration test DB setup | Manual sqlite3 schema construction | `AppDatabase.forTesting()` (in-memory) | Runs exact same `onCreate` path as production; tests real migration |
| ADR file numbering | Guess the next number | `ls docs/arch/03-adr/ADR-*.md | sort | tail -1` | Confirmed: current max is ADR-019; new ADRs must be 020, 021, 022 |

**Key insight:** Drift's `migrator.createTable()` correctly emits `customConstraints` (CHECK statements). For nullable columns added via ALTER TABLE, `customStatement` is required because `migrator.addColumn` does not apply table-level `customConstraints` to existing rows.

---

## Common Pitfalls

### Pitfall 1: `appliedRate` as RealColumn / double
**What goes wrong:** If `applied_rate` is `REAL` in SQLite, double-to-string-to-double round-trips lose precision. `149.99 USD × 157.3421 JPY` stored as double, then retrieved and re-multiplied, can yield a different `.round()` result than the preview computed.
**Why it happens:** Drift `RealColumn` maps to SQLite REAL (double). Rate has 4-6 decimal places.
**How to avoid:** Use `TextColumn get appliedRate => text().nullable()()`. Store the string literally (D-05: no normalization). Parse inside the rounding utility only.
**Warning signs:** `RealColumn get appliedRate` in `exchange_rates_table.dart` or `transactions_table.dart`. [VERIFIED: Pitfall 1, PITFALLS.md]

### Pitfall 2: Using `customIndices` for the `exchange_rates` index
**What goes wrong:** The `customIndices` getter is NOT consumed by Drift's migrator. `AppDatabase.forTesting()` will not create the index. The `latest-for-currency` query performance degrades without the index.
**Why it happens:** The CR-01 lesson was discovered in v1.6 Phase 36 — only shopping_items had it; pre-existing tables don't document the failure.
**How to avoid:** Create a `_createExchangeRateIndexes()` private helper in `AppDatabase`, call it from both `onCreate` and the `from < 21` block in `onUpgrade`.
**Warning signs:** The index tested with `sqlite_master WHERE type = 'index' AND tbl_name = 'exchange_rates'` returns empty. [VERIFIED: shopping_items_v20_contract_test.dart as template]

### Pitfall 3: Hash chain breakage by including new fields
**What goes wrong:** Adding `originalCurrency` or `originalAmount` to `HashChainService.calculateTransactionHash` invalidates ALL existing chain hashes. Every pre-migration transaction would fail `verifyChain`.
**Why it happens:** "More data in hash = more integrity" sounds correct but ignores migration cost.
**How to avoid:** ADR-021 must be written and approved before any migration code lands. The hash formula (`transactionId|amount|timestamp|previousHash`) remains unchanged. Add an architecture test asserting the signature does not grow.
**Warning signs:** `HashChainService.calculateTransactionHash` gaining `originalCurrency` parameter. [VERIFIED: hash_chain_service.dart, current signature confirmed]

### Pitfall 4: Sync backward-compat broken by non-nullable cast
**What goes wrong:** A v1.6 device sends a transaction without `originalCurrency`. `data['originalCurrency'] as String` (non-nullable) throws `TypeError` in `fromSyncMap`, and `ApplySyncOperationsUseCase` silently skips the operation (existing try/catch pattern) — the transaction is lost.
**Why it happens:** New fields added without `as String?` null-safe cast.
**How to avoid:** All three new fields must use `as T?` in `fromSyncMap`. Write a regression test: deserialize a v1.6-format payload, assert no exception and `originalCurrency == null`.
**Warning signs:** `data['originalCurrency'] as String` without `?`. [VERIFIED: existing `joyFullness: data['joyFullness'] as int? ?? 2` pattern in transaction_sync_mapper.dart]

### Pitfall 5: Golden re-baseline incomplete or on wrong platform
**What goes wrong:** The CNY symbol fix changes `amount_display_cny.png` and `amount_display_cny_dark.png`. Running `flutter test --update-goldens` on CI (Ubuntu) generates Linux-font-AA goldens that don't match macOS baselines. macOS-only comparison gate (`flutter_test_config.dart`) means CI uses `BaselineExistenceGoldenComparator` (existence-only), but macOS devs will see pixel diff failures.
**Why it happens:** Golden baselines are macOS-rendered; ubuntu renders slightly different anti-aliased fonts.
**How to avoid:** Always run `flutter test --update-goldens test/golden/amount_display_golden_test.dart` on macOS only. The 2 existing CNY goldens + any newly added disambiguation goldens must be re-baselined on macOS in the same commit as the `NumberFormatter` change.
**Warning signs:** Golden baseline committed from a Linux or CI environment. [VERIFIED: flutter_test_config.dart confirms platform gate; MEMORY.md "golden-ci-platform-gate"]

### Pitfall 6: Partial-triple invariant missing from `CreateTransactionParams`
**What goes wrong:** A bug in a future UI or OCR path sets `originalCurrency = 'USD'` but forgets `originalAmount`. The transaction is saved with `amount = 0` (derived from `null × rate`) or the conversion is computed incorrectly. Analytics `SUM(amount)` is poisoned.
**Why it happens:** No validation gate.
**How to avoid:** Add the three-field partial-triple check to `CreateTransactionUseCase.execute` before the DB insert. Return `Result.error(...)` on partial state. Unit test: provide exactly one of the three fields, assert error.
**Warning signs:** `CreateTransactionUseCase` reaching the hash computation step when only one of the three is non-null. [VERIFIED: Pitfall 3, PITFALLS.md]

---

## Code Examples

### Migration v20→v21 (complete block)

```dart
// Source: lib/data/app_database.dart — add after the `from < 20` block
if (from < 21) {
  // exchange_rates cache table (D-09 column set)
  await migrator.createTable(exchangeRates);
  await _createExchangeRateIndexes();

  // Three nullable columns on transactions (foreign-currency provenance)
  // Use customStatement — nullable with no DEFAULT; migrator.addColumn
  // applies customConstraints to fresh rows only, not migration rows.
  await customStatement(
    'ALTER TABLE transactions ADD COLUMN original_currency TEXT',
  );
  await customStatement(
    'ALTER TABLE transactions ADD COLUMN original_amount INTEGER',
  );
  await customStatement(
    'ALTER TABLE transactions ADD COLUMN applied_rate TEXT',
  );
}
```

Also add to `onCreate`:
```dart
onCreate: (migrator) async {
  await migrator.createAll();
  await _createShoppingItemIndexes();
  await _createExchangeRateIndexes();  // ADD THIS
},
```

And add the helper method:
```dart
Future<void> _createExchangeRateIndexes() async {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_exchange_rates_currency_date '
    'ON exchange_rates (currency, rate_date)',
  );
}
```

### ExchangeRateDao (three methods only)

```dart
// lib/data/daos/exchange_rate_dao.dart
class ExchangeRateDao {
  ExchangeRateDao(this._db);
  final AppDatabase _db;

  Future<ExchangeRateRow?> findByDate(String currency, DateTime date) =>
    (_db.select(_db.exchangeRates)
      ..where((t) => t.currency.equals(currency) & t.rateDate.equals(date)))
      .getSingleOrNull();

  Future<ExchangeRateRow?> findLatest(String currency) =>
    (_db.select(_db.exchangeRates)
      ..where((t) => t.currency.equals(currency))
      ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
      ..limit(1))
      .getSingleOrNull();

  Future<void> upsert(ExchangeRatesCompanion companion) =>
    _db.into(_db.exchangeRates).insertOnConflictUpdate(companion);
}
```

### Transaction Freezed extension

```dart
// lib/features/accounting/domain/models/transaction.dart — add inside factory:
// Foreign-currency provenance (all null = JPY-native row)
String? originalCurrency,    // ISO 4217 code, e.g. 'USD'
int? originalAmount,         // minor units (cents for USD: $12.50 → 1250)
String? appliedRate,         // JPY per 1 whole unit of originalCurrency (string, D-04)
```

### ADR structure (first lines of ADR-020)

```markdown
# ADR-020: Exchange Rate Precision Storage

**文档编号:** ADR-020
**状态:** ✅ 已接受
**创建日期:** 2026-06-12

## 决策

`appliedRate` 字段在 `transactions` 表中以 `TextColumn`（字符串）存储，全精度保留。
Freezed 字段类型为 `String? appliedRate`。同步 wire 传字符串字面量。

## 理由

[...]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SharedPreferences for rate cache | Drift `exchange_rates` table | Phase 40 decision (CONTEXT.md D-09) | Queryable, encrypted, offline-fallback SQL |
| `RealColumn` for rate (STACK.md draft) | `TextColumn` (string) | Phase 40 ADR-020 | Prevents precision loss; audit integrity |
| `¥` for both JPY and CNY | `¥` (JPY) / `CN¥` (CNY) | Phase 40 fix | Eliminates user confusion in zh/ja bilingual context |
| `customIndices` as index creation | Explicit `CREATE INDEX` in helper | v1.6 CR-01 lesson | Indices actually created on fresh install and upgrade |

**Deprecated/outdated:**

- `STACK.md` draft used `RealColumn get exchangeRate` and SharedPreferences cache — superseded by CONTEXT.md decisions D-04 (TextColumn) and D-09 (Drift table).
- ARCHITECTURE.md draft column name `conversionRate` — superseded by CONTEXT.md field name `appliedRate` (consistent with D-01/D-04 terminology).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `originalAmount` stored as `INTEGER` (minor units: cents for USD) | Standard Stack, Code Examples | If stored as double string instead, the rounding utility formula changes; unit tests catch this |
| A2 | Freezed generator for nullable fields with no `@Default` annotation implicitly defaults to `null` | Architecture Patterns | If wrong, all `fromJson` calls for `Transaction` break; caught immediately by build_runner + tests |
| A3 | The shared rounding utility lives in `lib/shared/utils/` | Architecture Patterns | Wrong placement would violate import_guard; easily caught by import_guard.yaml lint |
| A4 | `ExchangeRateRepository` Riverpod wiring lives in `lib/application/currency/repository_providers.dart` (new file) | Architecture Patterns | Not needed until Phase 41 actually uses it; low risk for Phase 40 — can defer to Phase 41 |
| A5 | `appliedRate` validity check rejects scientific notation | Code Examples | Edge case; explicit unit test needed; policy can be refined without schema impact |

---

## Open Questions (RESOLVED)

1. **`originalAmount` field type — minor units (int) vs. display amount (string)**
   - **RESOLVED:** `int? originalAmount` (minor units) — adopted by plans 40-04 (`IntColumn get originalAmount => integer().nullable()()`), 40-05, and 40-06 (`int? originalAmount` Freezed field).
   - What we know: D-04 says `appliedRate` is stored as string. CONTEXT.md says `Transaction.originalAmount` is one of the three fields but does not specify its type.
   - ARCHITECTURE.md draft used `double? originalAmount` (display amount). STACK.md draft used `int? originalAmount` (minor units, e.g., cents).
   - STORE-02 formula `(originalAmount × appliedRate).round()` works for either type (different arithmetic).
   - What's unclear: Minor units require knowing `subunitToUnit` at every call site; display-amount (double as string?) is simpler but risks precision.
   - **Recommendation:** Store as `int? originalAmount` (minor units) — consistent with the "integer contract" in STORE-02. JPY has `subunitToUnit = 1`, USD has 100. The rounding utility takes `subunitToUnit` as a parameter. This is A1 in the Assumptions Log — planner should confirm.

2. **Riverpod wiring for `ExchangeRateRepository` — Phase 40 or Phase 41?**
   - **RESOLVED:** Phase 40 — plan 40-05 creates `lib/application/currency/repository_providers.dart` wiring `ExchangeRateRepository` → `ExchangeRateRepositoryImpl`.
   - What we know: Phase 40 creates the interface and impl but no use case uses it yet (use cases are Phase 41).
   - What's unclear: Whether the planner should include a `repository_providers.dart` stub in Phase 40 or defer to Phase 41 when it's first consumed.
   - **Recommendation:** Create a minimal `lib/application/currency/repository_providers.dart` in Phase 40 that wires `ExchangeRateRepository` to `ExchangeRateRepositoryImpl`. This follows Riverpod hygiene (ONE file per feature, created with the impl). Phase 41 adds use case providers to the same file.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build + tests | ✓ | 3.44.0 | — |
| Dart SDK | Build + tests | ✓ | 3.12.0 | — |
| `drift ^2.25.0` | Schema migration | ✓ | 2.25.0 (latest 2.34.0 available) | — |
| `build_runner ^2.4.14` | Freezed/Drift codegen | ✓ | 2.4.14 | — |
| `flutter test` | Unit + migration tests | ✓ | part of Flutter 3.44.0 | — |
| macOS runner | Golden re-baseline | ✓ | macOS (darwin) | Cannot use CI (Ubuntu) |

**Missing dependencies:** None. All required tools are available.

**Note on drift version:** Current version is 2.25.0; latest is 2.34.0. No upgrade is required for Phase 40; the existing `^2.25.0` constraint is satisfied and the migration pattern is stable across minor versions. [VERIFIED: pubspec.yaml + flutter pub add dry-run]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter 3.44.0) |
| Config file | `test/flutter_test_config.dart` (golden platform gate) |
| Quick run command | `flutter test test/unit/data/migrations/ test/unit/infrastructure/i18n/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STORE-01 | v20→v21 migration: three nullable columns appear; `exchange_rates` table created | unit/migration | `flutter test test/unit/data/migrations/schema_v21_migration_test.dart -x` | ❌ Wave 0 |
| STORE-01 | Fresh install (v1→v21) creates `exchange_rates` table + index | unit/migration | same file, separate test case | ❌ Wave 0 |
| STORE-01 | `HashChainService.verifyChain` passes on mixed v20/v21 dataset | unit/migration | same file | ❌ Wave 0 |
| STORE-01 | `ExchangeRateDao.findByDate` returns correct row | unit/dao | `flutter test test/unit/data/daos/exchange_rate_dao_test.dart -x` | ❌ Wave 0 |
| STORE-01 | `ExchangeRateDao.findLatest` returns most-recent when multiple dates exist | unit/dao | same file | ❌ Wave 0 |
| STORE-02 | `convertToJpy` returns same integer from preview and persist call for 10 edge cases | unit | `flutter test test/unit/shared/currency_conversion_test.dart -x` | ❌ Wave 0 |
| STORE-03 | `fromSyncMap` handles v1.6-format payload (no currency fields) → null fields, no exception | unit | `flutter test test/unit/features/accounting/transaction_sync_mapper_test.dart -x` | ❌ Wave 0 (new test cases in existing file) |
| STORE-03 | `fromSyncMap` + `toSyncMap` round-trips v1.7 payload losslessly | unit | same file | ❌ Wave 0 |
| STORE-04 | ADR-021 recorded; `HashChainService.calculateTransactionHash` signature does NOT include currency fields | architecture | `flutter test test/architecture/domain_import_rules_test.dart` (existing) + manual doc check | existing file ✓, new assertion TBD |
| STORE-05 | `NumberFormatter.formatCurrency('CNY', ...)` returns `CN¥` not `¥` | unit | `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart -x` | existing ✓ (update existing CNY test) |
| STORE-05 | `NumberFormatter.formatCurrency('KRW', ...)` returns `₩` with 0 decimals | unit | same file | existing ✓ (new test case) |
| STORE-05 | CNY golden baselines reflect `CN¥` symbol | golden | `flutter test test/golden/amount_display_golden_test.dart --update-goldens` (macOS only) | existing ✓ (re-baseline) |
| STORE-01 | `CreateTransactionUseCase` rejects partial-triple (only 1 of 3 currency fields set) | unit | `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart -x` | existing ✓ (new test cases) |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/data/migrations/ test/unit/infrastructure/i18n/ test/unit/features/accounting/ test/unit/shared/ --no-pub`
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/data/migrations/schema_v21_migration_test.dart` — covers STORE-01 migration contract
- [ ] `test/unit/data/daos/exchange_rate_dao_test.dart` — covers STORE-01 DAO behavior
- [ ] `test/unit/shared/currency_conversion_test.dart` — covers STORE-02 rounding utility
- [ ] `test/unit/features/accounting/transaction_sync_mapper_test.dart` — new test cases for STORE-03 (file exists; need currency round-trip cases)
- [ ] Framework install: none needed — `flutter_test` already present

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `appliedRate` string validated: parseable positive double, no scientific notation policy |
| V6 Cryptography | yes | `exchange_rates` table lives in SQLCipher AES-256-CBC encrypted DB (inherited from `AppDatabase`); no separate crypto action needed |

### Known Threat Patterns for Phase 40 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `appliedRate` injection via sync payload (adversarial string causing `double.parse` throw) | Tampering | Validate in `CreateTransactionUseCase` before parse; catch `FormatException` in rounding utility |
| `exchange_rates` plaintext cache revealing travel patterns | Information Disclosure | Drift table inherits SQLCipher encryption — resolved by architecture choice (D-09) over SharedPreferences |
| Partial-triple sync manipulation (set `originalCurrency` but omit `originalAmount` to poison analytics) | Tampering | Domain invariant in `CreateTransactionUseCase` — `Result.error` on partial state |
| Hash chain re-seal required if new fields accidentally included | Tampering | ADR-021 + architecture test asserting hash function signature is unchanged |

---

## Sources

### Primary (HIGH confidence — direct codebase inspection, 2026-06-12)

- `lib/data/tables/transactions_table.dart` — v20 column list, nullability conventions, `customIndices` decorative comment
- `lib/data/app_database.dart` — `schemaVersion = 20`, migration pattern (`from < N`), `customStatement` vs `migrator.addColumn`, `_createShoppingItemIndexes` helper
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — hash formula confirmed: `transactionId|amount|timestamp|previousHash` only
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — CNY/JPY bug at lines 56-57 confirmed
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — conditional emit pattern, `as T?` null-safe reads
- `lib/features/accounting/domain/models/transaction.dart` — Freezed field list, nullable conventions
- `lib/application/accounting/create_transaction_use_case.dart` — `CreateTransactionParams` fields, `Result.error` validation pattern
- `lib/shared/utils/result.dart` — `Result<T>` class confirmed
- `test/unit/data/migrations/shopping_items_v20_contract_test.dart` — migration test template
- `test/unit/infrastructure/i18n/formatters/number_formatter_test.dart` — existing CNY test (line 36) confirmed uses `'¥'` assertion (will need update)
- `test/golden/amount_display_golden_test.dart` — 2 CNY goldens confirmed; `currencySymbol: '¥'` at lines 114, 132

### Secondary (MEDIUM confidence — prior v1.7 research, 2026-06-12)

- `.planning/research/SUMMARY.md` — consolidated ecosystem overview, stack decisions
- `.planning/research/ARCHITECTURE.md` — integration surface map, build order
- `.planning/research/PITFALLS.md` — 10 critical pitfalls with file-level citations
- `.planning/research/STACK.md` — package verification, API live-test results

### Tertiary (pub.dev API — HIGH confidence for package metadata)

- `https://pub.dev/api/packages/currency_picker` — version 2.0.22, published 2026-06-10
- `https://pub.dev/api/packages/sealed_currencies` — version 3.2.0, published 2026-05-21
- Both confirmed clean against pubspec via `dart pub add --dry-run` in this session

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all dependencies verified in existing pubspec; no new packages in Phase 40
- Architecture: HIGH — all patterns derived from direct codebase inspection of existing implementations
- Pitfalls: HIGH — all critical pitfalls confirmed by reading actual source files with line numbers
- Migration pattern: HIGH — v19→v20 (`shopping_items`) confirmed working via passing test (`flutter test ... shopping_items_v20_contract_test.dart`)

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 (stable internal patterns; drift version may have minor updates but migration API is stable)

---

## Project Constraints (from CLAUDE.md)

The following directives from `CLAUDE.md` are directly relevant to Phase 40 and must be honored:

| Directive | Constraint |
|-----------|-----------|
| Schema version | `schemaVersion => 20` confirmed; migration must set `schemaVersion => 21` |
| `customIndices` is decorative | Must emit explicit `CREATE INDEX` in both `onCreate` and `onUpgrade` (CR-01 lesson) |
| ALL tables in `lib/data/tables/` | `ExchangeRates` table goes in `lib/data/tables/exchange_rates_table.dart` |
| ALL DAOs in `lib/data/daos/` | `ExchangeRateDao` goes in `lib/data/daos/exchange_rate_dao.dart` |
| ALL repo impls in `lib/data/repositories/` | `ExchangeRateRepositoryImpl` goes in `lib/data/repositories/` |
| "Thin Feature" rule | `lib/features/currency/domain/` holds only models + interfaces — no application, infrastructure, or data sub-layers |
| ONE `repository_providers.dart` per feature | `lib/application/currency/repository_providers.dart` is the single wiring point |
| Never `sqlite3_flutter_libs` | Already excluded; `sqlcipher_flutter_libs` is in use |
| Never `RealColumn` for `appliedRate` | D-04 locked; `TextColumn` required |
| Run build_runner after annotated class changes | Required after `transaction.dart` Freezed extension and new `ExchangeRate` model |
| Zero analyzer warnings before commit | `flutter analyze` must pass before any commit |
| No `// ignore:` suppressions | Fix root causes |
| Crypto rules | No new crypto in Phase 40; `exchange_rates` is in SQLCipher DB by inheritance |
| ADR numbering | Current max = ADR-019; new ADRs must be ADR-020, ADR-021, ADR-022 sequentially; update `ADR-000_INDEX.md` |
| All UI text via `S.of(context)` | No UI changes in Phase 40; not applicable |
| `NumberFormatter` for all currency/date formatting | Fix lives in `NumberFormatter`; no ad-hoc formatting elsewhere |
| Tests are first-class code | Migration tests, DAO tests, sync mapper tests required to 80%+ coverage |
| Drift schema is at v20 | Confirmed by reading `app_database.dart`; migration is `from < 21` |
