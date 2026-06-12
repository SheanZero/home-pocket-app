---
phase: 40-data-foundation-domain-sync
verified: 2026-06-12T12:45:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) Verification Report

**Phase Goal:** The complete data and domain substrate for multi-currency is live and sync-safe: three blocking ADR decisions recorded (ADR-020 rate precision / ADR-021 hash scope / ADR-022 edit policy), the CNY/JPY ¥ collision fixed, Drift v20→v21 migrated (exchange_rates cache table + three nullable transactions columns), the Transaction Freezed model extended, and the family sync pipeline passing the new fields null-safely in both directions — unblocking all downstream work (Phase 41 exchange rate service, Phase 42 entry UI).
**Verified:** 2026-06-12T12:45:00Z
**Status:** passed
**Re-verification:** No — initial verification (human items resolved in-session, see "Human Verification — Resolved")

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Drift migration runs cleanly v20→v21: existing transactions gain three null columns without data loss, clean install reaches v21, verifyChain passes on mixed null/non-null currency fields | ✓ VERIFIED | `lib/data/app_database.dart:49` schemaVersion=21; from<21 block adds exchange_rates table + 3 ALTER TABLE stmts; `test/unit/data/migrations/schema_v21_migration_test.dart` lines 111-201 implement STORE-04 verifyChain GREEN (not `fail('not implemented')`); orchestrator-run full suite on main confirms green |
| SC-2 | Three ADRs recorded: (a) appliedRate as TextColumn, (b) currency fields excluded from hash, (c) edit policy — before migration code lands | ✓ VERIFIED | `docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md` (status: ✅ 已接受, TextColumn decision documented); `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md` (status: ✅ 已接受, hash formula transactionId|amount|timestamp|previousHash preserved); `docs/arch/03-adr/ADR-022_Edit_Semantics.md` (status: ✅ 已接受, D-01/D-02/D-03 decisions); `ADR-000_INDEX.md` lines 584-628 updated with all three entries |
| SC-3 | CNY displays as CN¥; JPY continues as ¥; shared JPY rounding utility convertToJpy is the single conversion site; amount golden tests reflect new symbol | ✓ VERIFIED | `lib/infrastructure/i18n/formatters/number_formatter.dart:58-59` case 'CNY' returns 'CN¥', case 'JPY' returns '¥' separately; `lib/shared/utils/currency_conversion.dart` defines top-level `convertToJpy()`; git commit 6c03773e re-baselined CNY goldens; user approved goldens visually at the 40-03 human-verify checkpoint ("goldens approved"); golden suite 6/6 + unit tests asserting literal `CN¥` 23/23 green |
| SC-4 | Transaction.originalCurrency/.originalAmount/.appliedRate exist as nullable Freezed fields; TransactionSyncMapper round-trips null-safely; build_runner clean | ✓ VERIFIED | `lib/features/accounting/domain/models/transaction.dart:31-33` has three nullable fields (no @Default); `transaction.freezed.dart` regenerated with fields in copyWith/==/hashCode; `transaction_sync_mapper.dart:27-31` conditional emit in toSyncMap; `transaction_sync_mapper.dart:61-63` null-safe `as T?` reads in fromSyncMap; 5/5 STORE-03 sync mapper tests GREEN (confirmed via orchestrator full-suite run) |
| SC-5 | Partial-triple invariant: CreateTransactionParams validation returns Result.error on partial state; ExchangeRateDao supports exact-date and latest-for-currency queries; all new code passes import_guard | ✓ VERIFIED | `lib/application/accounting/create_transaction_use_case.dart:97-118` hasCurrencyField && !hasAllCurrencyFields → Result.error + appliedRate validity guard; `lib/data/daos/exchange_rate_dao.dart` findByDate/findLatest/upsert all implemented; `lib/features/currency/domain/` has no data/drift imports; architecture tests included in green full-suite run |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/data/tables/exchange_rates_table.dart` | ExchangeRates Drift table, TextColumn rate, composite PK (currency, rateDate) | ✓ VERIFIED | Exists; TextColumn rate (better than plan's RealColumn — consistent with ADR-020); UtcEpochDateTimeConverter on rateDate; composite PK confirmed |
| `lib/data/tables/transactions_table.dart` | Three new nullable columns: TextColumn originalCurrency, IntColumn originalAmount, TextColumn appliedRate | ✓ VERIFIED | Lines 44-49 confirm all three with `.nullable()()` |
| `lib/data/app_database.dart` | schemaVersion=21, from<21 migration, exchange_rates in @DriftDatabase, _createExchangeRateIndexes in onCreate+onUpgrade | ✓ VERIFIED | schemaVersion=21 at line 49; ExchangeRates in tables list; migration at lines 445-460; index helper called in onCreate and onUpgrade |
| `lib/data/daos/exchange_rate_dao.dart` | findByDate, findLatest, upsert | ✓ VERIFIED | All three methods present and wired to _db.exchangeRates |
| `lib/data/repositories/exchange_rate_repository_impl.dart` | Implements ExchangeRateRepository, _toModel, no UnimplementedError stubs | ✓ VERIFIED | `implements ExchangeRateRepository` at line 13; _toModel maps all fields; no UnimplementedError |
| `lib/features/currency/domain/models/exchange_rate.dart` | ExchangeRate Freezed model, rate as String (full precision, ADR-020) | ✓ VERIFIED | @freezed abstract class, required String rate, `exchange_rate.freezed.dart` generated |
| `lib/features/currency/domain/repositories/exchange_rate_repository.dart` | Pure-Dart interface, no Drift types | ✓ VERIFIED | No data/drift imports; three method signatures |
| `lib/shared/utils/currency_conversion.dart` | convertToJpy top-level function, single parse site | ✓ VERIFIED | Line 15-21; formula: `(originalMinorUnits / subunitToUnit * rate).round()` |
| `lib/application/currency/repository_providers.dart` | @riverpod appExchangeRateRepository provider | ✓ VERIFIED | Line 18 `ExchangeRateRepository appExchangeRateRepository(Ref ref)`; `.g.dart` generated |
| `lib/features/accounting/domain/models/transaction.dart` | Three nullable currency fields added | ✓ VERIFIED | Lines 31-33 |
| `lib/features/accounting/domain/models/transaction_sync_mapper.dart` | Conditional emit in toSyncMap, null-safe read in fromSyncMap | ✓ VERIFIED | Lines 27-31 (emit); lines 61-63 (read with `as T?`) |
| `lib/application/accounting/create_transaction_use_case.dart` | Partial-triple check + appliedRate validity | ✓ VERIFIED | Lines 97-118 |
| `docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md` | status ✅ 已接受, TextColumn decision | ✓ VERIFIED | |
| `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md` | status ✅ 已接受, hash formula documented | ✓ VERIFIED | |
| `docs/arch/03-adr/ADR-022_Edit_Semantics.md` | status ✅ 已接受, D-01/D-02/D-03 | ✓ VERIFIED | |
| `docs/arch/03-adr/ADR-000_INDEX.md` | Updated with ADR-020, ADR-021, ADR-022 entries | ✓ VERIFIED | Lines 584-628 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/data/app_database.dart` | `lib/data/tables/exchange_rates_table.dart` | @DriftDatabase tables list | ✓ WIRED | ExchangeRates in tables list; import at line 10 |
| `lib/data/tables/transactions_table.dart` | `lib/data/app_database.dart` | Drift code generation exposes originalCurrency on TransactionRow | ✓ WIRED | transaction.freezed.dart line 29 has originalCurrency getter |
| `lib/data/daos/exchange_rate_dao.dart` | `lib/data/app_database.dart` | Constructor injection AppDatabase | ✓ WIRED | `ExchangeRateDao(this._db)` uses `_db.exchangeRates` |
| `lib/data/repositories/exchange_rate_repository_impl.dart` | `exchange_rate_repository.dart` | implements ExchangeRateRepository | ✓ WIRED | Line 13 explicit |
| `lib/application/currency/repository_providers.dart` | `exchange_rate_repository_impl.dart` | @riverpod provider construction | ✓ WIRED | Line 21 `ExchangeRateRepositoryImpl(dao: dao)` |
| `transaction_sync_mapper.dart` | `transaction.dart` | toSyncMap uses originalCurrency; fromSyncMap constructs Transaction with it | ✓ WIRED | Lines 27-31, 61-63 confirmed |
| `create_transaction_use_case.dart` | `transaction.dart` | Transaction construction passes three currency fields from params | ✓ WIRED | Lines 198-200 confirmed |
| `ADR-021_Hash_Chain_Scope.md` | `hash_chain_service.dart` | Architecture decision constrains implementation (hash formula preserved) | ✓ WIRED | Architecture assertion test at schema_v21_migration_test.dart:209-228 calls calculateTransactionHash with exactly 4 params |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `ExchangeRateRepositoryImpl.findByDate` | `ExchangeRateRow?` | `ExchangeRateDao.findByDate` → `_db.exchangeRates` Drift query | Yes — real DB query via `getSingleOrNull()` | ✓ FLOWING |
| `TransactionSyncMapper.fromSyncMap` | `originalCurrency/originalAmount/appliedRate` | Peer sync payload `data[key] as T?` | Yes — passes through with null-safe cast; absent = null | ✓ FLOWING |
| `convertToJpy` | Return int | `double.parse(appliedRate)` arithmetic | Yes — pure computation, no hardcoded values | ✓ FLOWING |
| `NumberFormatter._getCurrencySymbol('CNY')` | String symbol | switch-case literal `'CN¥'` | Yes — correct string | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite on merged main | `flutter test` (orchestrator-run, wave-4 post-merge gate, independent of SUMMARY claims) | `01:10 +2635: All tests passed!`, exit 0 | ✓ PASS |
| Static analysis on main | `flutter analyze` (orchestrator-run) | "No issues found!" | ✓ PASS |
| CNY golden suite after re-baseline | `flutter test test/golden/amount_display_golden_test.dart` (40-03 checkpoint, macOS) | 6/6 green | ✓ PASS |
| NumberFormatter CN¥ assertions | unit tests asserting literal `CN¥` string | 23/23 green | ✓ PASS |

### Probe Execution

No phase-declared or conventional probes found. Skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| STORE-01 | 40-04, 40-05, 40-06 | Foreign-currency transactions store JPY amount + three new nullable fields; Drift schema v20→v21 | ✓ SATISFIED | transactions_table.dart has originalCurrency/originalAmount/appliedRate; app_database.dart schemaVersion=21 |
| STORE-02 | 40-05 | JPY conversion: (originalAmount × appliedRate).round() — fractional yen never stored | ✓ SATISFIED | `lib/shared/utils/currency_conversion.dart` single conversion site with `.round()` |
| STORE-03 | 40-06 | Three fields transit family sync null-safely in both directions | ✓ SATISFIED | fromSyncMap uses `as T?` null-safe casts; toSyncMap uses conditional emit; 5 STORE-03 mapper tests GREEN |
| STORE-04 | 40-02, 40-06 | Hash-chain scope ADR recorded; currency fields excluded from hash formula; verifyChain passes on mixed dataset | ✓ SATISFIED | ADR-021 recorded; architecture assertion test GREEN; verifyChain STORE-04 test GREEN |
| STORE-05 | 40-03 | CNY and JPY symbols disambiguated in NumberFormatter | ✓ SATISFIED | number_formatter.dart has separate cases for CNY→CN¥ and JPY→¥; CNY goldens re-baselined and user-approved at checkpoint |

All 5 phase-40 requirements satisfied. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/application/accounting/create_transaction_use_case.dart` | 113 | `double.parse(params.appliedRate!)` inline (IN-04 from review) | ℹ️ Info | Validation-only parse; does not produce JPY arithmetic; does not violate ADR-020 conversion site contract since no JPY rounding occurs here. Code review noted as IN-04. |

No TBD/FIXME/XXX/UnimplementedError in any Phase 40 production files. No hardcoded empty data returns. No stubs.

**Debt marker gate:** PASSED — zero unresolved TBD/FIXME/XXX markers in modified production files.

---

## CR-01 Assessment: Sync Ingestion Bypasses Partial-Triple Invariant

The code review found that `apply_sync_operations_use_case.dart` calls `TransactionSyncMapper.fromSyncMap()` then directly `_transactionRepository.insert(transaction)` with no partial-triple validation at lines 143-148 and 163-172.

**Impact on phase goal:** The phase goal says "family sync pipeline passing the new fields **null-safely** in both directions" (emphasis added). STORE-03 requirement says "transit family sync null-safely in both directions." SC-5 explicitly scopes the partial-triple invariant to "CreateTransactionParams validation returns Result.error" — not to the sync ingestion path.

The null-safe transit is implemented correctly (`as T?` casts, absent keys → null). The partial-triple invariant is enforced at the local creation path (CreateTransactionUseCase). The sync ingestion path does not enforce it.

ADR-021 names "CreateTransactionUseCase" explicitly as the invariant enforcer (lines 90, 145). The phase success criteria are met as written.

**Classification: WARNING** — The sync path is a real security gap (a peer can inject partial-triple rows, which Phase 42's display code will crash on via null-assert or FormatException). This should be fixed before Phase 42 ships. It does not block Phase 40 completion because:
1. No Phase 42 UI code exists yet that would crash on such rows
2. The SC-5 contract (CreateTransactionParams) is satisfied
3. No production caller creates partial-triple rows through the local path

**Recommendation:** Add sync-ingestion partial-triple validation at the start of Phase 41 or 42, before any display code reads these fields. The fix is a focused change to `_handleCreate`/`_handleUpdate` in `apply_sync_operations_use_case.dart`.

---

## Human Verification — Resolved In-Session

Both items originally flagged for human verification were satisfied during this execution session:

### 1. CNY Golden Image Visual Confirmation — RESOLVED

Plan 40-03 was an `autonomous: false` checkpoint plan. At its `checkpoint:human-verify` gate, the orchestrator re-baselined the goldens on this macOS machine, the golden suite passed 6/6, and the **user explicitly approved with "goldens approved"** (AskUserQuestion response, this session). Supporting evidence: unit tests assert the literal `CN¥` string (23/23 green); git commit 6c03773e records the re-baseline.

### 2. Full Test Suite Execution Confirmation — RESOLVED

The orchestrator **independently ran** `flutter test` on merged main as the wave-4 post-merge gate (not relying on SUMMARY claims): result `01:10 +2635: All tests passed!`, exit code 0. `flutter analyze` on main: "No issues found!". This independently confirms the STORE-04 verifyChain test, the 5 STORE-03 sync mapper tests, the partial-triple tests, and the 47 architecture tests are all green on the merged state.

---

## Gaps Summary

No must-have truths failed. No required artifacts are missing, stub, or orphaned. No blockers. All human verification items resolved with in-session evidence.

CR-01 (sync ingestion partial-triple bypass) is a WARNING captured above. It is observable, real, and should be addressed before Phase 42 ships. It does not prevent Phase 40's goal or success criteria from being true in the codebase as defined.

WR-02 through WR-10 from the code review are quality warnings. None block the roadmap success criteria.

---

_Verified: 2026-06-12T12:45:00Z_
_Verifier: Claude (gsd-verifier)_
