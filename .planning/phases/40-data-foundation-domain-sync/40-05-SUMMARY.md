---
phase: 40-data-foundation-domain-sync
plan: "05"
subsystem: domain
tags:
  - freezed
  - riverpod
  - exchange-rate
  - multi-currency
  - currency-conversion
  - domain-model
  - repository-interface
dependency_graph:
  requires:
    - 40-04
  provides:
    - exchange_rate_freezed_model
    - exchange_rate_repository_interface
    - exchange_rate_repository_impl_wired
    - currency_conversion_utility
    - app_exchange_rate_repository_provider
  affects:
    - lib/features/currency
    - lib/application/currency
    - lib/shared/utils
    - lib/data/repositories
tech_stack:
  added:
    - "ExchangeRate Freezed model (freezed_annotation @freezed)"
    - "appExchangeRateRepository Riverpod provider (riverpod_annotation @riverpod)"
    - "convertToJpy top-level utility function (pure Dart, no dependencies)"
  patterns:
    - "Thin Feature rule: ExchangeRateRepository interface in features/currency/domain/ with no Drift imports"
    - "Single parse site: double.parse(appliedRate) only in convertToJpy (ADR-020 Pitfall 1 prevention)"
    - "Repository bridge pattern: _toModel(ExchangeRateRow) → ExchangeRate in impl, Drift types never leave data layer"
    - "Value() companion-building in upsert (mirrors ShoppingItemRepositoryImpl pattern)"
    - "app prefix Riverpod provider naming convention (appExchangeRateRepository)"
key_files:
  created:
    - lib/features/currency/domain/models/exchange_rate.dart
    - lib/features/currency/domain/models/exchange_rate.freezed.dart
    - lib/features/currency/domain/repositories/exchange_rate_repository.dart
    - lib/shared/utils/currency_conversion.dart
    - lib/application/currency/repository_providers.dart
    - lib/application/currency/repository_providers.g.dart
  modified:
    - lib/data/repositories/exchange_rate_repository_impl.dart
decisions:
  - "ExchangeRate.rate field is String (not double) — matches ADR-020 TextColumn decision and ExchangeRateRow.rate TextColumn from Plan 40-04"
  - "convertToJpy uses (minorUnits / subunitToUnit * rate).round() — subunitToUnit param enables KRW/JPY (=1) and USD/EUR (=100) with the same function"
  - "appExchangeRateRepository provider returns ExchangeRateRepository interface (not impl) for HIGH-02 compliance; wired via security.appDatabaseProvider"
  - "ExchangeRateRepositoryImpl._toModel is synchronous (no encryption at this layer) — exchange rates are not user PII; no FieldEncryptionService needed"
metrics:
  duration: "4 minutes"
  completed: "2026-06-12T10:50:00Z"
  tasks_completed: 2
  files_changed: 7
---

# Phase 40 Plan 05: Domain Model, Repository Interface, and Currency Conversion Utility Summary

ExchangeRate Freezed model with full D-09 column set (rate as String per ADR-020), ExchangeRateRepository pure-Dart interface, ExchangeRateRepositoryImpl fully wired to interface with _toModel bridge, convertToJpy single-parse-site utility, and @riverpod appExchangeRateRepository provider; all 10 Wave 0 RED tests turned GREEN.

## What Was Built

### Task 1: ExchangeRate Freezed Model, ExchangeRateRepository Interface, convertToJpy Utility

**lib/features/currency/domain/models/exchange_rate.dart** (new):
- `@freezed abstract class ExchangeRate` with full D-09 column set
- Fields: `currency` (String), `rateDate` (DateTime UTC), `rate` (String per ADR-020), `fetchedAt` (DateTime), `source` (String), `actualRateDate` (DateTime? nullable, no @Default)
- Private const constructor `ExchangeRate._()` for future method support
- Zero Drift or Flutter imports — pure domain type

**lib/features/currency/domain/repositories/exchange_rate_repository.dart** (new):
- `abstract class ExchangeRateRepository` with three pure-Dart method signatures
- `findByDate(String currency, DateTime date)` → `Future<ExchangeRate?>`
- `findLatest(String currency)` → `Future<ExchangeRate?>`
- `upsert(ExchangeRate rate)` → `Future<void>`
- Only import: the domain model (Thin Feature rule — no Drift, no Flutter)

**lib/shared/utils/currency_conversion.dart** (new):
- `int convertToJpy({required int originalMinorUnits, required String appliedRate, required int subunitToUnit})`
- Formula: `(originalMinorUnits / subunitToUnit * double.parse(appliedRate)).round()`
- Single canonical parse site for STORE-02 and ADR-020
- No imports needed — pure Dart top-level function

**Verification**: All 10 `currency_conversion_test.dart` Wave 0 tests passed GREEN.

### Task 2: Wire ExchangeRateRepositoryImpl, Add Riverpod Provider, Run build_runner

**lib/data/repositories/exchange_rate_repository_impl.dart** (modified):
- Removed all TODO comments and stub pass-through from Plan 40-04
- Added `implements ExchangeRateRepository` clause
- `_toModel(ExchangeRateRow row) → ExchangeRate`: synchronous mapping of all 6 fields
- `findByDate`: delegates to `_dao.findByDate`, maps via `_toModel`
- `findLatest`: delegates to `_dao.findLatest`, maps via `_toModel`
- `upsert`: builds `ExchangeRatesCompanion` with `Value(x)` for each field, delegates to `_dao.upsert`

**lib/application/currency/repository_providers.dart** (new):
- `@riverpod ExchangeRateRepository appExchangeRateRepository(Ref ref)`
- Constructs `ExchangeRateDao(db)` then `ExchangeRateRepositoryImpl(dao: dao)`
- Returns `ExchangeRateRepository` interface type (not impl) per HIGH-02
- Uses `security.appDatabaseProvider` consistent with accounting layer pattern

**Generated files**:
- `lib/features/currency/domain/models/exchange_rate.freezed.dart` (build_runner: freezed)
- `lib/application/currency/repository_providers.g.dart` (build_runner: riverpod_generator)

**Verification**: 4 DAO tests + 10 currency_conversion tests = 14/14 GREEN.

## Test Results

| Test file | Tests | Pass | Fail |
|-----------|-------|------|------|
| currency_conversion_test.dart | 10 | 10 | 0 |
| exchange_rate_dao_test.dart | 4 | 4 | 0 |

## Deviations from Plan

None — plan executed exactly as written.

The only analyzer issues (18 errors) are pre-existing Wave 0 RED stubs in `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` referencing `Transaction.originalCurrency`, `Transaction.originalAmount`, and `Transaction.appliedRate` fields that Plan 40-06 will add to the Transaction Freezed model. These are intentional RED stubs, not regressions introduced by this plan.

## Known Stubs

None — this plan has no intentional stubs. All method signatures are fully implemented.
The `transaction_sync_mapper_test.dart` errors are Plan 40-06's responsibility (Wave 3 parallel executor).

## Threat Surface Scan

No new security-relevant surfaces beyond the plan's threat model:
- `ExchangeRateRepository` and `ExchangeRateRepositoryImpl` operate on exchange rate cache data (not user PII) — no field encryption needed at this layer (T-40-11: rates stored in SQLCipher-encrypted database)
- `convertToJpy` performs no I/O; `double.parse(appliedRate)` throws `FormatException` on invalid input — caller validation is Plan 40-06's responsibility (T-40-12)
- `appExchangeRateRepository` provider constructs from app-internal DAO only; no external input path at this layer (T-40-10)

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/features/currency/domain/models/exchange_rate.dart | FOUND |
| lib/features/currency/domain/models/exchange_rate.freezed.dart | FOUND |
| lib/features/currency/domain/repositories/exchange_rate_repository.dart | FOUND |
| lib/shared/utils/currency_conversion.dart | FOUND |
| lib/data/repositories/exchange_rate_repository_impl.dart (modified) | FOUND |
| lib/application/currency/repository_providers.dart | FOUND |
| lib/application/currency/repository_providers.g.dart | FOUND |
| Commit fd8363d3 (Task 1) | FOUND |
| Commit 09788e4d (Task 2) | FOUND |
