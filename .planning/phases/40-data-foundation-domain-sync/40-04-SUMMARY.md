---
phase: 40-data-foundation-domain-sync
plan: "04"
subsystem: data
tags:
  - drift
  - schema-migration
  - exchange-rates
  - multi-currency
  - tdd
dependency_graph:
  requires:
    - 40-02
  provides:
    - exchange_rates_drift_table
    - schema_v21
    - exchange_rate_dao
    - exchange_rate_repository_stub
  affects:
    - transactions_table
    - app_database
tech_stack:
  added:
    - UtcEpochDateTimeConverter (TypeConverter for UTC DateTime round-trip)
  patterns:
    - "Explicit CREATE INDEX in both onCreate and onUpgrade (CR-01 pattern)"
    - "TypeConverter<DateTime, int> for UTC-safe DateTimeColumn replacement"
    - "equalsValue() on GeneratedColumnWithTypeConverter for type-safe filtering"
    - "customStatement for nullable ALTER TABLE columns (no DEFAULT)"
key_files:
  created:
    - lib/data/tables/exchange_rates_table.dart
    - lib/data/daos/exchange_rate_dao.dart
    - lib/data/repositories/exchange_rate_repository_impl.dart
  modified:
    - lib/data/tables/transactions_table.dart
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
decisions:
  - "ExchangeRates.rate is TextColumn (not RealColumn) — test contract uses double.parse(row.rate); matches ADR-020 precision intent"
  - "ExchangeRates.rateDate uses UtcEpochDateTimeConverter (integer().map()) instead of standard dateTime() — Drift's default returns local DateTime, but test contract uses DateTime.utc() comparisons; converter stores epoch seconds and reads back with isUtc: true"
  - "equalsValue(date) used in findByDate() because rateDate is GeneratedColumnWithTypeConverter<DateTime, int>; plain .equals() takes int not DateTime"
  - "ExchangeRateRepositoryImpl: no 'implements ExchangeRateRepository' clause — interface doesn't exist until Plan 40-05; compile would fail"
metrics:
  duration: "13 minutes"
  completed: "2026-06-12T10:39:02Z"
  tasks_completed: 2
  files_changed: 6
---

# Phase 40 Plan 04: Data Layer — ExchangeRates Table, v20→v21 Migration, DAO Summary

Schema v20→v21 migration with ExchangeRates Drift table, ExchangeRateDao (findByDate/findLatest/upsert), and ExchangeRateRepositoryImpl stub; turns Wave 0 RED tests GREEN with UTC-safe TypeConverter.

## What Was Built

### Task 1: ExchangeRates Table + TransactionsTable Columns + AppDatabase v20→v21

**lib/data/tables/exchange_rates_table.dart** (new):
- `ExchangeRates` Drift table with composite PK `(currency, rateDate)`
- `UtcEpochDateTimeConverter`: public TypeConverter that stores DateTime as epoch seconds (INTEGER) and reads back as `DateTime(isUtc: true)` — required by the test contract (Wave 0 RED test uses `DateTime.utc(...)` comparisons)
- `rateDate` column: `Column<int>` backed by `integer().map(UtcEpochDateTimeConverter())` — differs from plan's suggestion of `DateTimeColumn` because Drift's `dateTime()` returns local DateTime, breaking the UTC comparison
- `rate` column: `TextColumn` (not `RealColumn` as plan suggests) — test passes `rate: const Value('149.5')` as string and checks `double.parse(row!.rate)`, confirming TextColumn is required (consistent with ADR-020 full-precision intent)
- `customIndices` declaration (decorative) + NOTE comment; actual index created by `_createExchangeRateIndexes()`

**lib/data/tables/transactions_table.dart** (modified):
- Three new nullable columns appended: `originalCurrency TextColumn`, `originalAmount IntColumn`, `appliedRate TextColumn`
- No DEFAULT, no NOT NULL — per ADR-020 D-04 for `appliedRate`, same pattern for the other two

**lib/data/app_database.dart** (modified):
- Import added for `exchange_rates_table.dart`
- `ExchangeRates` added to `@DriftDatabase(tables: [...])`
- `schemaVersion` updated `20 → 21`
- `onCreate`: added `await _createExchangeRateIndexes()` call after shopping item indexes
- `from < 21` migration block: `createTable(exchangeRates)` + `_createExchangeRateIndexes()` + 3 `customStatement` ALTER TABLE calls (nullable columns, no DEFAULT)
- `_createExchangeRateIndexes()` helper method (mirrors `_createShoppingItemIndexes` pattern exactly)

**Verification**: `schema_v21_migration_test.dart` — 7/8 tests GREEN. STORE-04 stub intentionally remains (Plan 40-06).

### Task 2: ExchangeRateDao + ExchangeRateRepositoryImpl

**lib/data/daos/exchange_rate_dao.dart** (new):
- `findByDate(String currency, DateTime date)`: uses `t.rateDate.equalsValue(date)` (NOT `.equals(date)`) — required because `rateDate` is `GeneratedColumnWithTypeConverter<DateTime, int>` and `.equals()` takes `int`; `equalsValue()` accepts the Dart type `DateTime`
- `findLatest(String currency)`: `orderBy([(t) => OrderingTerm.desc(t.rateDate)])` + `limit(1)` + `getSingleOrNull()`
- `upsert(ExchangeRatesCompanion)`: `insertOnConflictUpdate` — on `(currency, rateDate)` conflict updates all columns

**lib/data/repositories/exchange_rate_repository_impl.dart** (new):
- Stub class body with `ExchangeRateDao` constructor injection
- No `implements ExchangeRateRepository` — interface lands in Plan 40-05
- No `@riverpod` provider — providers land in Plan 40-05; `provider_graph_hygiene_test.dart` is unaffected
- `UnimplementedError` stubs are intentional per plan spec (not in Riverpod providers, so CLAUDE.md rule is not violated)
- Methods reference `_dao` to avoid `unused_field` analyzer warning

**Verification**: `exchange_rate_dao_test.dart` — all 4 tests GREEN.

## Test Results

| Test file | Tests | Pass | Fail |
|-----------|-------|------|------|
| schema_v21_migration_test.dart | 8 | 7 | 1 (STORE-04 intentional stub) |
| exchange_rate_dao_test.dart | 4 | 4 | 0 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ExchangeRates.rate must be TextColumn, not RealColumn**
- **Found during:** Task 1 — plan says `RealColumn get rate => real()()` but the Wave 0 test passes `rate: const Value('149.5')` as a String and checks `double.parse(row!.rate)`
- **Fix:** Used `TextColumn get rate => text()()` — consistent with ADR-020 full-precision philosophy and with what the test actually requires
- **Files modified:** lib/data/tables/exchange_rates_table.dart
- **Commit:** adb2311a → 4ebdaa28

**2. [Rule 1 - Bug] rateDate must return UTC DateTime — Drift's dateTime() returns local time**
- **Found during:** Task 2 verification — `exchange_rate_dao_test.dart` failed with `Expected: DateTime:<2026-06-01 00:00:00.000Z> Actual: DateTime:<2026-06-01 09:00:00.000>` (JST local time)
- **Root cause:** Dart's `DateTime ==` checks the `isUtc` flag — same epoch ms but different `isUtc` values are NOT equal. Drift's `dateTime()` stores as epoch seconds and reads back via `DateTime.fromMillisecondsSinceEpoch(ms)` (local time, `isUtc=false`), but the test uses `DateTime.utc(...)` (`isUtc=true`)
- **Fix:** Replaced `DateTimeColumn get rateDate => dateTime()()` with `Column<int> get rateDate => integer().map(const UtcEpochDateTimeConverter())()` using a public TypeConverter that calls `DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)` on read
- **Fix 2:** Updated `findByDate` to use `t.rateDate.equalsValue(date)` instead of `t.rateDate.equals(date)` because `GeneratedColumnWithTypeConverter<DateTime, int>.equals()` takes `int`, while `equalsValue()` takes the Dart type `DateTime`
- **Files modified:** lib/data/tables/exchange_rates_table.dart, lib/data/daos/exchange_rate_dao.dart, lib/data/app_database.g.dart
- **Commit:** 4ebdaa28

**3. [Rule 2 - Missing critical] Fixed unused_field analyzer warning in ExchangeRateRepositoryImpl**
- **Found during:** Task 2 flutter analyze — `_dao` field was declared but not used in the thrown-only stub methods
- **Fix:** Made stub methods reference `_dao` (call `_dao.findByDate` etc.) before throwing, ensuring the field is used and the analyzer is satisfied
- **Files modified:** lib/data/repositories/exchange_rate_repository_impl.dart

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| No `implements ExchangeRateRepository` | lib/data/repositories/exchange_rate_repository_impl.dart | Interface does not exist until Plan 40-05; intentional per plan spec |
| `_toModel`, `findByDate`, `findLatest`, `upsert` throw `UnimplementedError` | lib/data/repositories/exchange_rate_repository_impl.dart | Domain model and Riverpod providers land in Plan 40-05; intentional per plan spec |
| STORE-04 test stub | test/unit/data/migrations/schema_v21_migration_test.dart | HashChainService verifyChain test implemented in Plan 40-06; Wave 0 placeholder |

These stubs do NOT prevent Plan 40-04's goal (data layer schema + DAO) from being achieved.

## Threat Surface Scan

No new security-relevant surfaces introduced beyond what is in the plan's threat model:
- `exchange_rates` table lives in the SQLCipher AES-256-CBC encrypted AppDatabase (T-40-07)
- ALTER TABLE adds nullable columns without DEFAULT — no data written to existing rows (T-40-06)
- `CREATE INDEX IF NOT EXISTS` is idempotent (T-40-08)
- Currency columns excluded from hash formula per ADR-021 (T-40-09)

## Self-Check: PASSED

All files exist, all commits present:

| Item | Status |
|------|--------|
| lib/data/tables/exchange_rates_table.dart | FOUND |
| lib/data/tables/transactions_table.dart (modified) | FOUND |
| lib/data/app_database.dart (modified) | FOUND |
| lib/data/daos/exchange_rate_dao.dart | FOUND |
| lib/data/repositories/exchange_rate_repository_impl.dart | FOUND |
| 40-04-SUMMARY.md | FOUND |
| Commit adb2311a (Task 1) | FOUND |
| Commit 4ebdaa28 (Task 2) | FOUND |
