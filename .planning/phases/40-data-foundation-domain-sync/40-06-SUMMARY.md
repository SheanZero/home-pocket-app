---
phase: 40-data-foundation-domain-sync
plan: "06"
subsystem: domain
tags:
  - freezed
  - transaction-model
  - sync-mapper
  - partial-triple-invariant
  - hash-chain
  - multi-currency
  - tdd
  - store-03
  - store-04
dependency_graph:
  requires:
    - 40-04
    - 40-05
  provides:
    - transaction_currency_fields
    - sync_mapper_currency_roundtrip
    - partial_triple_invariant
    - appliedrate_validity
    - store04_verifychain_green
  affects:
    - lib/features/accounting/domain/models/transaction.dart
    - lib/features/accounting/domain/models/transaction_sync_mapper.dart
    - lib/application/accounting/create_transaction_use_case.dart
    - test/unit/data/migrations/schema_v21_migration_test.dart
tech_stack:
  added: []
  patterns:
    - "Nullable Freezed fields without @Default (consistent with note/photoHash/merchant pattern)"
    - "Conditional if-in-map pattern for toSyncMap backward compat (v1.6 peers get no extra keys)"
    - "as T? null-safe cast in fromSyncMap (absent keys → null, Pitfall 4 guard)"
    - "Partial-triple invariant: hasCurrencyField && !hasAllCurrencyFields → Result.error before DB write"
    - "appliedRate validity: double.parse + isNaN/isInfinite/<=0 guards (D-05)"
    - "Architecture assertion test: verifies calculateTransactionHash has exactly 4 params (ADR-021)"
key_files:
  created: []
  modified:
    - lib/features/accounting/domain/models/transaction.dart
    - lib/features/accounting/domain/models/transaction.freezed.dart
    - lib/features/accounting/domain/models/transaction.g.dart
    - lib/features/accounting/domain/models/transaction_sync_mapper.dart
    - lib/application/accounting/create_transaction_use_case.dart
    - test/unit/data/migrations/schema_v21_migration_test.dart
    - test/unit/application/accounting/create_transaction_use_case_test.dart
decisions:
  - "D-05 appliedRate validation: double.parse('NaN') does NOT throw FormatException in Dart — returns double.nan; added rate.isNaN guard to catch NaN/Infinity cases alongside rate<=0 check"
  - "Architecture assertion test uses 64-char length check for SHA-256 correctness, proving both signature and return type"
  - "STORE-04 verifyChain test builds chain data in-memory (not reading from DB rows) — this is correct because HashChainService.verifyChain takes List<Map>, not a database handle"
metrics:
  duration: "18 minutes"
  completed: "2026-06-12T11:01:51Z"
  tasks_completed: 3
  files_changed: 7
---

# Phase 40 Plan 06: Transaction Domain Extension, Sync Pipeline, Partial-Triple Invariant, STORE-04 Closure Summary

Transaction Freezed model extended with three nullable currency fields (no @Default), TransactionSyncMapper updated for null-safe v1.7 sync with v1.6 backward compatibility, CreateTransactionUseCase gains partial-triple invariant + appliedRate validity (D-05), and STORE-04 verifyChain test implemented GREEN with ADR-021 architecture assertion — completing Phase 40.

## What Was Built

### Task 1: Extend Transaction Freezed model, update TransactionSyncMapper, implement STORE-04 verifyChain

**lib/features/accounting/domain/models/transaction.dart** (modified):
- Added three nullable fields after `metadata`: `String? originalCurrency`, `int? originalAmount`, `String? appliedRate`
- No `@Default` annotation on any field — consistent with existing `note`, `photoHash`, `merchant` pattern
- Comment: "Foreign-currency provenance (all three null = JPY-native row per STORE-01)"

**lib/features/accounting/domain/models/transaction.freezed.dart + transaction.g.dart** (regenerated):
- build_runner regenerated both files with new fields included in `copyWith`, `==`, `hashCode`, `toJson`/`fromJson`

**lib/features/accounting/domain/models/transaction_sync_mapper.dart** (modified):
- `toSyncMap`: three conditional entries added after `photoHash` conditional — `if (transaction.originalCurrency != null) 'originalCurrency': ...` etc. (v1.6 backward compat: absent keys mean v1.6 peers parse correctly)
- `fromSyncMap`: three null-safe reads added inside Transaction constructor — `originalCurrency: data['originalCurrency'] as String?` etc. (absent keys → null without exception, Pitfall 4 guard)

**test/unit/data/migrations/schema_v21_migration_test.dart** (modified):
- Added import for `HashChainService`
- Replaced `fail('not implemented ...')` stub with full STORE-04 implementation:
  - Seeds JPY-native row (all three currency columns NULL) and USD foreign-currency row (originalCurrency='USD', originalAmount=5000, appliedRate='149.30') in `AppDatabase.forTesting()`
  - Builds `List<Map<String, dynamic>>` with correctly chained SHA-256 hashes for both rows
  - Calls `hashService.verifyChain(chainData)` — result.isValid = true (ADR-021: currency fields excluded from hash formula)
- Added architecture assertion test: calls `calculateTransactionHash` with exactly 4 parameters, asserts return value is 64-char SHA-256 string

**Verification**: 29 tests GREEN (5 STORE-03 sync mapper group + 7 existing transaction_test.dart + all schema_v21_migration_test.dart including STORE-04)

### Task 2: Add partial-triple invariant and appliedRate validation to CreateTransactionUseCase

**lib/application/accounting/create_transaction_use_case.dart** (modified):
- `CreateTransactionParams`: three new optional fields — `String? originalCurrency`, `int? originalAmount`, `String? appliedRate`
- `execute()`: partial-triple check (STORE-04): `hasCurrencyField && !hasAllCurrencyFields` → `Result.error('partial foreign-currency data: ...')` before any DB or category lookup
- `execute()`: appliedRate validity (D-05): when `hasAllCurrencyFields`, wrap `double.parse` in try/catch + `rate.isNaN || rate.isInfinite || rate <= 0` → `Result.error('appliedRate must be a positive number')`
- `execute()`: Transaction construction passes all three currency fields from params

**test/unit/application/accounting/create_transaction_use_case_test.dart** (modified):
- Added `makeParams()` helper function for concise partial-triple test construction
- Group "partial-triple invariant" (7 tests): only-one/two-of-three → Result.error; all-null passes to category; all-three-with-valid-rate passes to category
- Group "appliedRate validity (D-05)" (4 tests): NaN → error (isNaN path), '-1.5' → error (rate<=0), '0' → error (rate<=0), '0.001' → passes to category

### Task 3: Full suite smoke check and import_guard verification

- `flutter analyze` → 0 issues
- `flutter test --no-pub` → 2635/2635 tests GREEN
- `flutter test test/architecture/` → 47/47 architecture tests GREEN (import_guard + provider hygiene)
- STORE-04 verifyChain test GREEN (was fail('not implemented'))
- `calculateTransactionHash` architecture assertion GREEN (4 params, 64-char SHA-256)

## Test Results

| Test file | Tests | Pass | Fail |
|-----------|-------|------|------|
| transaction_sync_mapper_test.dart (STORE-03 group) | 5 | 5 | 0 |
| transaction_test.dart | 7 | 7 | 0 |
| schema_v21_migration_test.dart | 10 | 10 | 0 (STORE-04 now GREEN) |
| create_transaction_use_case_test.dart | 20 | 20 | 0 |
| Full suite | 2635 | 2635 | 0 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] double.parse('NaN') does not throw FormatException in Dart**
- **Found during:** Task 2 — test `appliedRate='NaN' → Result.error (FormatException path)` failed
- **Issue:** Dart's `double.parse('NaN')` returns `double.nan` without throwing `FormatException` (per IEEE 754, NaN is a valid floating-point value). The plan's behavior doc said "NaN → error (FormatException path)" which is incorrect about the exception path.
- **Fix:** Added `rate.isNaN || rate.isInfinite` guard alongside `rate <= 0` check. NaN is caught by `rate.isNaN` and returns `Result.error('appliedRate must be a positive number')`. Test updated to match the actual error path ("isNaN path" vs "FormatException path"). The externally observable behavior (NaN → Result.error) is unchanged.
- **Files modified:** `lib/application/accounting/create_transaction_use_case.dart`, `test/unit/application/accounting/create_transaction_use_case_test.dart`
- **Commit:** 0e812a81

**2. [Rule 2 - Missing critical] Local function leading underscore analyzer warning**
- **Found during:** Task 2 flutter analyze — `_baseParams` local function has underscore prefix, triggering `no_leading_underscores_for_local_identifiers` info
- **Fix:** Renamed `_baseParams` to `makeParams`
- **Files modified:** `test/unit/application/accounting/create_transaction_use_case_test.dart`
- **Commit:** 0e812a81

## Known Stubs

None. All plan goals achieved. Phase 40 is complete.

## Threat Surface Scan

All mitigations from the threat model implemented:

| Threat | Mitigation | Status |
|--------|-----------|--------|
| T-40-13: fromSyncMap null-safe cast | `as T?` null-safe cast for all three currency fields | Implemented |
| T-40-14: partial-triple sync manipulation | `hasCurrencyField && !hasAllCurrencyFields → Result.error` before DB write | Implemented |
| T-40-15: appliedRate FormatException | `double.parse` + `isNaN/isInfinite/<=0` guards | Implemented |
| T-40-16: hash chain scope | Architecture assertion test: 4-param calculateTransactionHash, ADR-021 confirmed | Implemented |

No new security-relevant surfaces introduced beyond the plan's threat model.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/features/accounting/domain/models/transaction.dart (originalCurrency field) | FOUND |
| lib/features/accounting/domain/models/transaction.freezed.dart (regenerated) | FOUND |
| lib/features/accounting/domain/models/transaction_sync_mapper.dart (originalCurrency in toSyncMap+fromSyncMap) | FOUND |
| lib/application/accounting/create_transaction_use_case.dart (partial-triple + appliedRate validation) | FOUND |
| test/unit/data/migrations/schema_v21_migration_test.dart (STORE-04 verifyChain GREEN) | FOUND |
| test/unit/application/accounting/create_transaction_use_case_test.dart (partial-triple + appliedRate tests) | FOUND |
| 40-06-SUMMARY.md | FOUND |
| Commit 10e7c8b9 (Task 1) | FOUND |
| Commit 0e812a81 (Task 2) | FOUND |
