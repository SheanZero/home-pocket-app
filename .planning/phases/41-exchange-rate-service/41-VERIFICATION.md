---
phase: 41-exchange-rate-service
verified: 2026-06-13T10:05:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 41: 汇率服务 (Exchange Rate Service) Verification Report

**Phase Goal:** A fully tested, offline-safe exchange rate service — dual-source fetch (Frankfurter primary, fawazahmed0 fallback), Drift-backed per-(date, currency) cache, weekend/holiday date transparency, manual override and date-change semantics enforced through application use cases — with the hard invariant that saving a transaction is never blocked on network.
**Verified:** 2026-06-13T10:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|-----------------------------------|--------|----------|
| 1 | Cache behavior: 2nd same-(date,currency) request = zero network; miss calls API + persists to `exchange_rates` + returns rate; historical permanent, today's short TTL | ✓ VERIFIED | `exchange_rate_cache_service.dart:55-126` cache-first: `findByDate` HIT → `RateCached` early-return; miss → `_apiClient.fetchRate` → `_repository.upsert` → `RateFetched`. D-01 TTL via `_isCorrectableProxy` (`fetchedAt < today` guard, L191-196). Test "Cache HIT … zero API calls" asserts `verifyNever(fetchRate)`; "Cache MISS → calls API, upserts, returns RateFetched" |
| 2 | Offline/failure: all APIs throw → `RateResult.fallback` carrying actual cached date; `GetExchangeRateUseCase` never throws | ✓ VERIFIED | `_cacheFallback` (L152-180) returns `RateFallback`/`RateManual`/`RateUnavailable`; outer try/catch (L119-125) guarantees no throw. Use case wraps in its own try/catch (L87-94). Tests: "use case never throws → RateUnavailable", "WR-02 … cachedDate, requested" asserts fallback carries the exact requested date |
| 3 | Weekend/holiday actualDate surfaced via `RateResult.fetched.actualDate`; TWD routes to fawazahmed0 | ✓ VERIFIED | API client L114-116 sets `actualRateDate` when response date ≠ requested; `RateFetched.actualDate` (rate_result.dart:40). Tests: "RATE-05: 200 with weekend … non-null actualRateDate" (Sat→Fri); "Frankfurter 404 → fawazahmed0 jsDelivr returns rate (TWD)" asserts `source == 'fawazahmed0'` |
| 4 | Manual override + date-change per ADR-022: override used, not clobbered by re-fetch unless date changes; >1% JPY delta → confirmation signal | ✓ VERIFIED | `_applyManualOverride` (use_case L98-131) persists `source='manual'` keyed by (currency, rateDate); a date change is a new composite key → cache miss → re-fetch leaves the old-date override row intact. `wasManualOverride && previousRate` → `RateSignalDialog` (L65-78); `>1%` → `RateSignalToast` via `_maybeToast` (L141-155). Tests: "wasManualOverride=true → emits dialog signal (D-02)", ">1% delta → emits toast (D-03)" |
| 5 | Never-block-save: `Create`/`UpdateTransactionUseCase` zero HTTP; no URL contains user-derived data | ✓ VERIFIED | `grep -E "http\|exchange_rate\|ExchangeRate\|frankfurter\|fawazahmed"` on both use cases = zero matches. API client URLs built solely from `dateStr` + ISO currency (L88-90, L62-63, L72-73). Test "SC-5: URL privacy" captures all 3 URLs, asserts allowed-host regex + no `userId/bookId/amount/deviceId` tokens |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` | Dual-source HTTP wrapper | ✓ VERIFIED | 199 lines; 3-source chain, `ExchangeRateApiException`, injectable `http.Client?`, CR-02 `_parseUtcDate` |
| `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` | Cache-first orchestration | ✓ VERIFIED | 217 lines; D-01/03/05/06/07/08/09 all implemented; WR-02/04 fixes present |
| `lib/application/currency/rate_result.dart` | Sealed RateResult union | ✓ VERIFIED | 5 variants (RateFetched/Cached/Fallback/Manual/Unavailable) + RateSignal(Dialog/Toast) + RateResultWithSignal |
| `lib/application/currency/get_exchange_rate_use_case.dart` | Use case + ADR-022 signals | ✓ VERIFIED | 172 lines; manual-override path, dialog/toast signals, never-throws |
| `lib/features/currency/domain/repositories/exchange_rate_repository.dart` | Extended interface | ✓ VERIFIED | `findLatestNonManual`, `findLatestManual` (WR-03), `deleteOlderThan`, `findAll` all declared |
| `lib/data/daos/exchange_rate_dao.dart` | Drift DAO | ✓ VERIFIED | All new methods implemented with correct source filters + epoch-converter cutoff |
| `lib/data/repositories/exchange_rate_repository_impl.dart` | Delegation impl | ✓ VERIFIED | All interface methods overridden; CR-02 normalization shared |
| `lib/features/settings/domain/models/backup_data.dart` | BackupData + exchangeRates | ✓ VERIFIED | `@Default([])` exchangeRates field (D-10, backward-compat) |
| `lib/application/settings/export_backup_use_case.dart` | Export extended | ✓ VERIFIED | `_exchangeRateRepo.findAll()` collected + serialized |
| `lib/application/settings/import_backup_use_case.dart` | Import extended + CR-01 | ✓ VERIFIED | Upsert loop with `validateAppliedRate` + source whitelist; invalid rows skipped |
| `lib/application/currency/repository_providers.dart` (+`.g.dart`) | Riverpod wiring | ✓ VERIFIED | `appExchangeRateCacheServiceProvider`, `appGetExchangeRateUseCaseProvider` wired |
| `pubspec.yaml` | connectivity_plus | ✓ VERIFIED | `connectivity_plus: ^7.1.1` (D-05) |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| cache_service | repository | `_repository.findByDate/findLatestNonManual/deleteOlderThan/upsert` | ✓ WIRED |
| use_case | cache_service | `_cacheService.getRate` | ✓ WIRED |
| export_backup | repository | `_exchangeRateRepo.findAll()` | ✓ WIRED |
| import_backup | repository | `_exchangeRateRepo.upsert(er)` (post-validation) | ✓ WIRED |
| providers | cache_service / use_case | Riverpod `ref.watch` instantiation | ✓ WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data Source | Produces Real Data | Status |
|----------|-------------|--------------------|--------|
| cache_service `getRate` | Drift `exchange_rates` via repo + live HTTP via api_client | DB query (`findByDate`) + real `http.Client.get` | ✓ FLOWING |
| export/import backup | repo `findAll` / `upsert` | real Drift rows | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Static analysis clean | `flutter analyze` | "No issues found! (ran in 4.2s)" | ✓ PASS |
| Full suite GREEN | `flutter test` | "All tests passed!" — 2717/2717 (+2717 final) | ✓ PASS |
| Phase 41 test files exist | enumerate `test/unit/.../exchange_rate/`, `.../currency/` | 3 files present, populated with asserting tests | ✓ PASS |
| Never-block-save grep | `grep -E http\|exchange_rate on create/update use cases` | zero matches | ✓ PASS |

### Probe Execution

Not applicable — no `scripts/*/tests/probe-*.sh` declared or implied for this phase (verification driven by Flutter test suite, executed once above).

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| RATE-01 | 01,03,05 | Auto-fetch transaction-date rate, Frankfurter primary + fawazahmed0 fallback | ✓ SATISFIED | api_client 3-source chain; TWD-routing test |
| RATE-02 | 01,04,05 | Per-(date,currency) cache, repeat = zero network, historical permanent, today TTL | ✓ SATISFIED | cache-first + `verifyNever(fetchRate)` test; D-01 TTL guard |
| RATE-03 | 02,04,05 | Offline/failure → most-recent cached rate + staleness date, save never blocked | ✓ SATISFIED | `_cacheFallback` + never-throws tests; connectivity gate (D-05); cooldown (D-06) |
| RATE-04 | 04,05 | Manual override, JPY preview recalc | ✓ SATISFIED | `_applyManualOverride` (source='manual'); manual-override tests |
| RATE-05 | 03,05 | API different date → actual rate date shown | ✓ SATISFIED | `actualRateDate`/`RateFetched.actualDate`; weekend test |
| RATE-06 | 04,05 | Date change re-fetches, manual override preserved | ✓ SATISFIED | composite-key isolation keeps override row; ADR-022 dialog/toast signal tests |

No orphaned requirements — all 6 RATE IDs appear in plan frontmatter and trace to verified implementation.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | No TBD/FIXME/XXX debt markers in Phase 41 files. `return null` occurrences are legitimate source-fallthrough/parse-guard returns (api_client), not stubs. Empty `[]` default on `BackupData.exchangeRates` is an intentional backward-compat default, not a hollow render. |

### Human Verification Required

None. All success criteria are programmatically verifiable through deterministic unit tests (HTTP mocked, connectivity mocked, Drift in-memory). No visual/real-time/external-service behavior is in this phase's scope — Phase 42 owns the UI consumption surface. No `<human-check>` blocks present in any Phase 41 PLAN.

### Review-Fix Regression Check

All 6 post-execution review findings confirmed present and non-regressing:

| Finding | Resolution present | Evidence |
|---------|--------------------|----------|
| CR-01 backup-import validation | ✓ | import_backup L178-211: `validateAppliedRate` + `_validBackupRateSources` whitelist, invalid rows skipped |
| CR-02 / IN-03 UTC/local date-key skew | ✓ | All 4 normalizers use `DateTime.utc(d.year,d.month,d.day)` (local Y/M/D); `_parseUtcDate` for actualRateDate |
| WR-01 toast carries rate strings not int JPY | ✓ | `RateSignalToast.{oldRate,newRate,changeFraction}`; "sub-1 rates produce meaningful toast" test |
| WR-02 unrefreshable proxy fallback | ✓ | `_proxyAwareFallback` returns exact-date proxy; dedicated test asserts `cachedDate == requested` |
| WR-03 findLatestManual direct query | ✓ | New interface/DAO/impl method; manual fallback branch calls it directly |
| WR-04 cooldown cleared / connectivity-first | ✓ | `_isOffline()` checked before `_inCooldown`; `_cooldownUntil = null` on success |

### Gaps Summary

No gaps. The phase goal is achieved in the codebase: a dual-source, cache-first, offline-safe exchange rate service with weekend/holiday transparency, ADR-022 manual-override/date-change semantics, and the never-block-save invariant — all backed by 2717/2717 GREEN tests and 0 analyzer issues. SUMMARY claims match the actual implementation on every checked point. All 6 RATE requirements satisfied, all 6 review fixes present with no regression.

---

_Verified: 2026-06-13T10:05:00Z_
_Verifier: Claude (gsd-verifier)_
