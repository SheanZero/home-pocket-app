---
phase: 40-data-foundation-domain-sync
plan: "01"
subsystem: test-scaffolds
tags: [wave-0, tdd, red-state, schema-v21, exchange-rate, currency-conversion, sync-mapper]
dependency_graph:
  requires: []
  provides:
    - test/unit/data/migrations/schema_v21_migration_test.dart
    - test/unit/data/daos/exchange_rate_dao_test.dart
    - test/unit/shared/currency_conversion_test.dart
    - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart (STORE-03 group appended)
  affects:
    - Wave 1 plans (40-02, 40-03) must make these tests GREEN
    - Wave 2 plan 40-06 must implement the STORE-04 HashChainService stub
tech_stack:
  added: []
  patterns:
    - Wave 0 TDD RED scaffolding — compile-fail and assert-fail stubs define contracts before implementation
key_files:
  created:
    - test/unit/data/migrations/schema_v21_migration_test.dart
    - test/unit/data/daos/exchange_rate_dao_test.dart
    - test/unit/shared/currency_conversion_test.dart
  modified:
    - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
decisions:
  - "schema_v21_migration_test.dart uses AppDatabase.forTesting() + sqlite_master queries (same pattern as shopping_items_v20_contract_test.dart) rather than raw sqlite3 for the v21 schema tests"
  - "STORE-04 HashChainService stub uses fail('not implemented') placeholder because setting up HashChainService requires a pre-seeded v21 DB which is absent in Wave 0"
  - "exchange_rate_dao_test.dart references ExchangeRatesCompanion with TextColumn for rate (string, full precision) per pre-implementation decision in STATE.md"
  - "currency_conversion_test.dart uses named params (originalMinorUnits, appliedRate, subunitToUnit) per STORE-02 specification"
metrics:
  duration: "~7 minutes"
  completed: "2026-06-12T10:06:03Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 1
---

# Phase 40 Plan 01: Wave 0 Test Scaffolds — RED State Summary

Wave 0 Nyquist-compliance scaffolding: four test files (three new, one modified) defining the contracts for STORE-01 migration, STORE-01 DAO behavior, STORE-02 rounding utility, STORE-03 sync backward-compat, and STORE-04 hash-chain safety before any implementation code exists.

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | schema_v21_migration_test.dart + exchange_rate_dao_test.dart | ac5bd118 | RED (correct) |
| 2 | currency_conversion_test.dart + STORE-03 sync mapper group | 207e46b4 | RED (correct) |

## Test State Summary

| File | Tests | RED Cause | Will Turn GREEN In |
|------|-------|-----------|-------------------|
| schema_v21_migration_test.dart | 8 stubs | schemaVersion==20, no exchange_rates table/cols | Plan 40-02 (Wave 1) |
| exchange_rate_dao_test.dart | 4 stubs | ExchangeRateDao compile-fail | Plan 40-02 (Wave 1) |
| currency_conversion_test.dart | 10 stubs | currency_conversion.dart missing | Plan 40-03 (Wave 1) |
| transaction_sync_mapper_test.dart (STORE-03 group) | 5 new tests | Transaction lacks 3 new fields | Plan 40-02 (Wave 1) |

## Test Stub Details

### schema_v21_migration_test.dart (8 tests)
1. "AppDatabase schemaVersion is 21" — fails: currently 20
2. "exchange_rates table exists after fresh install" — fails: table absent
3. "exchange_rates index idx_exchange_rates_currency_date exists" — fails: index absent
4. "v20→v21 upgrade columns: original_currency" — fails: column absent
5. "v20→v21 upgrade columns: original_amount" — fails: column absent
6. "v20→v21 upgrade columns: applied_rate" — fails: column absent
7. "nullable columns accept NULL" — fails: columns absent
8. "STORE-04: HashChainService.verifyChain passes..." — stub with `fail('not implemented')`, GREEN in Plan 40-06

### exchange_rate_dao_test.dart (4 tests)
All fail with compile error on missing `ExchangeRateDao` and `ExchangeRatesCompanion` symbols.

### currency_conversion_test.dart (10 tests)
All fail with compile error on missing `package:home_pocket/shared/utils/currency_conversion.dart`.
Covers: USD at 149.30/148.30, EUR, JPY pass-through, KRW (no subunit), zero amount, rate-string precision, preview/persist consistency.

### transaction_sync_mapper_test.dart — STORE-03 group (5 new tests)
All fail with semantic error: `Transaction.originalCurrency/originalAmount/appliedRate` not defined.
Existing 7 tests remain unmodified (the file fails to compile so they also cannot run, but no test code was removed or altered).

## Deviations from Plan

None — plan executed exactly as written.

The `--no-pub` flag for `flutter test` caused a Flutter 3.44.0 native-assets tooling crash when running individual test files. Tests were verified by running without `--no-pub` (same behavior, also matches how the project's CI runs tests). This is a pre-existing Flutter stable channel bug, not a deviation.

## Known Stubs

All stubs are intentional Wave 0 RED-state stubs. None prevent a plan goal from being achieved — the goal of this plan IS to create failing stubs.

The STORE-04 stub (`fail('not implemented')`) is explicitly tracked for Plan 40-06 resolution.

## Threat Flags

No new security-relevant surface introduced. All files are test-only; no production code was modified.

## Self-Check: PASSED

- [x] test/unit/data/migrations/schema_v21_migration_test.dart — FOUND (ac5bd118)
- [x] test/unit/data/daos/exchange_rate_dao_test.dart — FOUND (ac5bd118)
- [x] test/unit/shared/currency_conversion_test.dart — FOUND (207e46b4)
- [x] transaction_sync_mapper_test.dart STORE-03 group — FOUND (207e46b4)
- [x] lib/ flutter analyze — 0 issues
- [x] All 4 target test files in RED state (fail/compile-fail as expected)
