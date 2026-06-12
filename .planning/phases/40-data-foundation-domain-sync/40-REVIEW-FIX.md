---
phase: 40-data-foundation-domain-sync
fixed_at: 2026-06-12T13:05:00Z
review_path: .planning/phases/40-data-foundation-domain-sync/40-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 11
skipped: 0
status: all_fixed
---

# Phase 40: Code Review Fix Report

**Fixed at:** 2026-06-12T13:05:00Z
**Source review:** .planning/phases/40-data-foundation-domain-sync/40-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (CR-01, WR-01..WR-10; fix_scope=critical_warning)
- Fixed: 11
- Skipped: 0

All fixes were applied in an isolated git worktree on a temp branch, each verified (targeted tests + `flutter analyze` 0 issues), committed atomically, then fast-forwarded onto `main` after the FULL suite passed (2680/2680, includes architecture/import-guard tests). Goldens re-baselined on macOS per the golden CI platform gate.

## Fixed Issues

### CR-01: Sync ingestion bypasses the partial-triple invariant *(fixed: requires human verification — policy choice)*

**Files modified:** `lib/features/accounting/domain/models/transaction_sync_mapper.dart`, `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`
**Commit:** 2b91ec32
**Applied fix:** `fromSyncMap` now extracts the three currency fields with `is` type checks (wrong JSON types can no longer throw) and validates the full triple: all-three-present, `originalAmount > 0`, ISO 4217 shape (`^[A-Z]{3}$`), and a plain-decimal positive rate. **Policy chosen: degrade invalid/partial triples to JPY-native (all three null)** rather than rejecting the operation — the hashed JPY `amount` stays authoritative; only provenance metadata is dropped. Documented in-code. 14 new mapper tests cover partial triples, invalid rates (`0`, `-1`, `abc`, `NaN`, `1.493e2`, untrimmed), wrong JSON types, bad currency codes, and the valid-triple pass-through.
**Adaptation:** the reviewer's sketch could not import a shared validator — the domain-models import guard (`test/architecture/domain_import_rules_test.dart` enforces intra-domain-only `allow` leaves) forbids `lib/shared/` imports from `domain/models/`. The rate-shape check is therefore duplicated as a documented private `_isValidRate` (matching the reviewer's own sketch). **Human should confirm the degrade-to-JPY-native policy (vs reject-op) is the desired semantics.**

### WR-01: convertToJpy input validation

**Files modified:** `lib/shared/utils/currency_conversion.dart`
**Commit:** 5f4d5712
**Applied fix:** `convertToJpy` now throws `ArgumentError` for `subunitToUnit <= 0` (previously Infinity → `UnsupportedError` crash) and `originalMinorUnits < 0` (previously silent negative JPY), and `FormatException` for non-finite/non-positive/unparseable `appliedRate`. Tests for these paths landed in the WR-08 commit.

### WR-02: D-05 shape validation (scientific notation / trim)

**Files modified:** `lib/shared/utils/currency_conversion.dart`, `lib/application/accounting/create_transaction_use_case.dart`, `test/unit/application/accounting/create_transaction_use_case_test.dart`
**Commit:** b36b2a69
**Applied fix:** Added `validateAppliedRate(String)` to `currency_conversion.dart` (hosted there per the reviewer's IN-04 suggestion, preserving the single-parse-site guarantee): rejects untrimmed input and anything not matching `^\d+(\.\d+)?$` (kills `1.493e2`, signs, whitespace), then rejects non-finite/<= 0. Use case now calls it instead of inline `double.parse`. Error messages were worded so the pre-existing `'NaN'`/`'-1.5'`/`'0'` tests (asserting `contains('positive number')`) stay green. Added 4 new tests: `1.493e2`, `' 149.30 '`, `'abc'`, `''`.

### WR-03: originalAmount / originalCurrency validation

**Files modified:** `lib/application/accounting/create_transaction_use_case.dart`, `test/unit/application/accounting/create_transaction_use_case_test.dart`
**Commit:** 86441a15
**Applied fix:** Inside the complete-triple branch: `originalAmount <= 0` → error; `originalCurrency` must match `^[A-Z]{3}$` → error. 4 new tests (`0`, `-5000`, `''`, `'usd'`).

### WR-04: amount ↔ triple consistency check *(fixed: requires human verification — new business rule)*

**Files modified:** `lib/shared/utils/currency_conversion.dart`, `lib/application/accounting/create_transaction_use_case.dart`, `test/unit/application/accounting/create_transaction_use_case_test.dart`
**Commit:** b145a910
**Applied fix:** Chose the assert-consistency option (vs deriving amount): the use case now computes `convertToJpy(originalAmount, appliedRate, subunitToUnitFor(originalCurrency))` and returns `Result.error` when `params.amount` differs — making `convertToJpy` the enforced canonical site with a production caller. Added `subunitToUnitFor()` (JPY/KRW → 1, default 100, mirrors `NumberFormatter._getCurrencyDecimals`) with a documented Phase 41 hand-off note for a richer currency metadata source. Two pre-existing tests passed *inconsistent* triples (amount 1000 with USD 5000 @ 149.30); they were adjusted to consistent triples, and a new mismatch test pins the rejection. **Human should confirm: (a) reject-on-mismatch (not derive-amount) is the desired contract for Phase 41's UI, and (b) the default-100 subunit fallback for unlisted currencies.**

### WR-05: fetchedAt / actualRateDate UTC round-trip

**Files modified:** `lib/data/tables/exchange_rates_table.dart`, `lib/data/app_database.g.dart` (build_runner), `test/unit/data/daos/exchange_rate_dao_test.dart`
**Commit:** 72b5e081
**Applied fix:** Both columns now use `integer().map(const UtcEpochDateTimeConverter())` exactly as `rateDate` does (SQL type stays INTEGER epoch-seconds, so the v21 migration SQL is unchanged). Ran `build_runner build --delete-conflicting-outputs`. New DAO test asserts `isUtc` and value equality after a persistence round-trip. Done before Phase 41 writes real data, as the review urged.

### WR-06: findByDate / upsert UTC-midnight normalization

**Files modified:** `lib/data/repositories/exchange_rate_repository_impl.dart`, `test/unit/data/repositories/exchange_rate_repository_impl_test.dart` (new file)
**Commit:** 80016466
**Applied fix:** Repository (the domain-facing boundary, per the review) normalizes via `_normalizeToUtcMidnight` in both `findByDate` and `upsert`. New 4-test repo suite covers non-midnight UTC lookups, local-zone DateTimes (timezone-robust: derived via `.toLocal()` from fixed UTC instants), and the no-near-duplicate upsert guarantee (single row after two same-day upserts).

### WR-07: migration test type assertion + honest naming

**Files modified:** `test/unit/data/migrations/schema_v21_migration_test.dart`
**Commit:** 227851b1
**Applied fix:** Group renamed to "v21 schema columns (fresh install)" with a comment stating the onUpgrade ALTER path is NOT exercised (repo convention); per-test names no longer claim "after v20→v21 upgrade". Added the ADR-020-mandated assertions: `applied_rate` is `TEXT`, `original_amount` is `INTEGER`, `original_currency` is `TEXT` (via `PRAGMA table_info` type column).

### WR-08: conversion tests — rounding claim, tautology, boundaries

**Files modified:** `test/unit/shared/currency_conversion_test.dart`
**Commit:** 6efd8160
**Applied fix:** Header comment corrected (half-away-from-zero, explicitly NOT banker's). Tautological preview==persist test replaced by a discriminating half-yen test (1501 × '0.5' = 750.5 → 751; banker's would give 750 — values chosen to be exactly representable in binary) plus 749.5 → 750 and a float-precision stressor ('0.1' × 1,000,000 → 100000). Added WR-01 invalid-input tests (6 bad rates → FormatException; zero/negative subunit and negative minor units → ArgumentError) and coverage for `validateAppliedRate` (accept/reject matrices incl. `.5`/`5.`/signs) and `subunitToUnitFor`. File now runs 26 tests.

### WR-09: ADR-021 original_amount type contradiction

**Files modified:** `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md`
**Commit:** 8a227316
**Applied fix:** Appended `## Update 2026-06-12: original_amount 列类型修正（INTEGER，非 TEXT）` per the ADR's append-only rule (original decision body untouched). Records: INTEGER minor units, `int?` Freezed field, JSON int on the wire, only `applied_rate` is TEXT, and that string-amount peer payloads degrade per CR-01.

### WR-10: golden tests baselined wrong amount representation

**Files modified:** `test/golden/amount_display_golden_test.dart`, `test/golden/goldens/amount_display_{usd,usd_dark,cny,cny_dark}.png`
**Commit:** 9b7ae189
**Applied fix:** The four USD/CNY tests now pass the major-unit display string `'1235.00'` (the `AmountDisplay` contract — it does no minor-unit conversion), goldens re-baselined on macOS via `--update-goldens` (only the 4 expected PNGs changed; JPY goldens untouched, same Ahem-block baseline style). Added a pixel-independent test asserting `find.text('1,235.00')` so decimal rendering for 2-decimal currencies is verified.

## Skipped Issues

None.

## Out of Scope (Info findings, not fixed per fix_scope=critical_warning)

- **IN-01** redundant `idx_exchange_rates_currency_date` (duplicates composite PK)
- **IN-02** `equals(21)` schemaVersion assertion will break at v22
- **IN-03** ADR-000 INDEX statistics/review table not updated for ADR-020/021/022
- **IN-04** inline parse in use case — *substantially resolved as a side effect of WR-02/WR-04* (`validateAppliedRate` now hosted in `currency_conversion.dart` and the use case no longer parses inline)
- **IN-05** noise comments in number_formatter.dart; unused `ExchangeRate._()` constructor
- **IN-06** missing FormatException/empty-string tests — *partially resolved as a side effect of WR-02* (`'abc'` and `''` cases added; the old `'not a valid number'` branch no longer exists)

## Verification

- Per-fix: targeted test file(s) + `flutter analyze` → 0 issues after every commit
- Final gate: full `flutter test` → **2680/2680 passed** (includes architecture tests: import guards, provider hygiene, hardcoded-CJK scan)
- Goldens: re-baselined and re-verified on macOS (golden CI platform gate respected)

---

_Fixed: 2026-06-12T13:05:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
