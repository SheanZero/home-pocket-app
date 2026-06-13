---
phase: 41-exchange-rate-service
plan: "04"
subsystem: infrastructure
tags: [exchange-rate, cache-first, connectivity, adr-022, backup, tdd, mocktail]

# Dependency graph
requires:
  - phase: 41-exchange-rate-service
    plan: "01"
    provides: ExchangeRateRepository.findLatestNonManual (D-07) / deleteOlderThan (D-09) / findAll (D-10); Wave 0 RED scaffolds for cache service + use case
  - phase: 41-exchange-rate-service
    plan: "02"
    provides: connectivity_plus ^7.1.1 (D-05 gate)
  - phase: 41-exchange-rate-service
    plan: "03"
    provides: ExchangeRateApiClient three-source fetch; RateResult sealed union (5 variants) + RateSignal/RateResultWithSignal
provides:
  - ExchangeRateCacheService — full cache-first orchestration (D-01/D-03/D-05/D-06/D-07/D-08/D-09), getRate never throws
  - GetExchangeRateUseCase + GetExchangeRateParams — ADR-022 D-02 dialog / D-03 toast signals, RATE-04 manual override, never throws
  - BackupData.exchangeRates field (D-10 backward-compat) + export collection + import upsert loop
affects: [42 (form provider calls GetExchangeRateUseCase → RateResultWithSignal)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "connectivity_plus 7.x checkConnectivity() returns List<ConnectivityResult>; offline = results.every((r) => r == none)"
    - "getRate/execute never-throw: nested try/catch — fetch failure sets cooldown then cache-fallback; unexpected error also cache-falls-back"
    - "Exhaustive switch over sealed RateResult to extract rate string (RateUnavailable → null)"

key-files:
  created:
    - lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
    - lib/application/currency/get_exchange_rate_use_case.dart
  modified:
    - lib/features/settings/domain/models/backup_data.dart
    - lib/features/settings/domain/models/backup_data.freezed.dart
    - lib/features/settings/domain/models/backup_data.g.dart
    - lib/application/settings/export_backup_use_case.dart
    - lib/application/settings/import_backup_use_case.dart
    - lib/features/settings/presentation/providers/repository_providers.dart
    - test/unit/infrastructure/exchange_rate/exchange_rate_cache_service_test.dart
    - test/unit/application/currency/get_exchange_rate_use_case_test.dart
    - test/unit/application/settings/export_backup_use_case_test.dart
    - test/unit/application/settings/import_backup_use_case_test.dart

key-decisions:
  - "Cache service owns D-07 fallback priority (findLatestNonManual → manual findLatest → RateUnavailable); the use case delegates rather than re-implementing it"
  - "ADR-022 D-02 dialog fires whenever wasManualOverride AND previousRate present (date-change is the caller's responsibility to signal via previousRate); D-03 toast threshold is computed on rate doubles (|new-old|/old > 0.01), rates stay strings on the wire"
  - "Manual override (RATE-04) is a use-case write path: validates via double.tryParse + positive-finite guard (T-41-13), upserts source='manual', returns RateCached(isManualOverride:true) — no cache-service fetch"
  - "Backup providers needed appExchangeRateRepositoryProvider wired in (Rule 3) — the new required constructor param otherwise broke compilation of the provider file"

patterns-established:
  - "Never-block-save service: nested try/catch where inner catch sets D-06 cooldown and the outer catch is the RATE-03 safety net — both terminate in cache-fallback"
  - "TTL prune as unawaited fire-and-forget after upsert (D-09) — test settles it with await Future.delayed(Duration.zero) before verifying deleteOlderThan capture"

requirements-completed: [RATE-02, RATE-03, RATE-04, RATE-06]

# Metrics
duration: 6min
completed: 2026-06-13
---

# Phase 41 Plan 04: ExchangeRateCacheService + GetExchangeRateUseCase + Backup D-10 Summary

**Closed the Phase 41 behavioral contract: built the cache-first ExchangeRateCacheService (D-01/D-03/D-05/D-06/D-07/D-08/D-09, never-throws), the GetExchangeRateUseCase with ADR-022 D-02 dialog / D-03 toast signals and RATE-04 manual override, and extended BackupData + export/import for D-10 exchange-rate persistence — bringing all remaining Wave 0 scaffolds GREEN (33 tests).**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-13T00:02:42Z
- **Completed:** 2026-06-13T00:09:04Z
- **Tasks:** 3
- **Files modified:** 13 (2 created, 11 modified incl. 2 regenerated)

## Accomplishments
- `ExchangeRateCacheService.getRate` implements the complete cache-first flow: exact-date cache HIT (RATE-02, zero API calls), D-03 correctable-proxy one-shot re-fetch with fetchedAt-today loop guard, D-05 connectivity gate, D-06 in-memory cooldown, D-07 fallback priority (API-cached → manual), D-08 RateUnavailable, D-09 2-year TTL prune on upsert. Never throws (RATE-03).
- `GetExchangeRateUseCase` adds the ADR-022 signal layer over the cache service: D-02 dialog when override + previousRate present, D-03 toast when no override and >1% rate delta, no signal under threshold/no previousRate. RATE-04 manual override is a validated write path (source='manual'). execute() never throws.
- `BackupData.exchangeRates` field added with `@Default([])` for backward-compat; export collects + serializes rates in epoch-seconds shape; import upserts each on restore (idempotent by composite PK). Family sync pipeline untouched (D-10 research-locked).
- Never-block-save invariant (SC-5) verified: 0 HTTP/cache-service refs in `create_transaction_use_case.dart`.
- 33 tests GREEN across the three test groups; `flutter analyze` 0 issues on all touched dirs.

## Task Commits

Each task was committed atomically:

1. **Task 1: ExchangeRateCacheService cache-first orchestration** — `b6b8ea39` (feat) — 9 tests
2. **Task 2: GetExchangeRateUseCase with ADR-022 signals** — `bc9a2310` (feat) — 8 tests
3. **Task 3: Backup D-10 exchange-rate persistence** — `8ba46e9e` (feat) — 4 backup tests + regenerated freezed/g

## Files Created/Modified
- `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` — cache-first service composing repository + ApiClient + Connectivity
- `lib/application/currency/get_exchange_rate_use_case.dart` — GetExchangeRateParams + GetExchangeRateUseCase (ADR-022 signals, manual override)
- `lib/features/settings/domain/models/backup_data.dart` (+ .freezed.dart / .g.dart) — exchangeRates field
- `lib/application/settings/export_backup_use_case.dart` — exchangeRateRepo + findAll + epoch-seconds serialization
- `lib/application/settings/import_backup_use_case.dart` — exchangeRateRepo + upsert loop in _restoreData
- `lib/features/settings/presentation/providers/repository_providers.dart` — wired appExchangeRateRepositoryProvider into both backup use cases
- 4 test files unfolded from RED scaffolds / extended with the new constructor param + D-10 assertions

## Decisions Made
- D-07 fallback priority lives in the cache service; the use case delegates and forwards the result unchanged. Keeps the priority logic in one place (the orchestrator) and the use case focused on ADR-022 signals + the manual-override write.
- ADR-022 D-02 dialog signal fires on `wasManualOverride && previousRate != null` — the caller (Phase 42) owns the "date changed" determination and expresses it by passing `previousRate`. D-03 toast threshold uses rate doubles for comparison only; rate strings are never converted for storage (ADR-020).
- Manual override validates with `double.tryParse` + positive-finite guard (consistent with `convertToJpy` / `validateAppliedRate`), returns RateUnavailable on invalid input without upserting (T-41-13).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Backup providers broke on the new required constructor param**
- **Found during:** Task 3 (after adding `required ExchangeRateRepository exchangeRateRepo` to both backup use cases)
- **Issue:** `lib/features/settings/presentation/providers/repository_providers.dart` constructs `ExportBackupUseCase(...)` and `ImportBackupUseCase(...)` without the new param → would fail compilation app-wide.
- **Fix:** Imported `application/currency/repository_providers.dart` and wired `exchangeRateRepo: ref.watch(appExchangeRateRepositoryProvider)` into both providers. The provider already existed (Phase 41-01/40), so no new provider was created.
- **Files modified:** lib/features/settings/presentation/providers/repository_providers.dart
- **Verification:** `flutter analyze` 0 issues on the settings feature dir; backup tests GREEN.
- **Committed in:** `8ba46e9e` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for compilation; no scope creep. The `.g.dart` for these providers was unchanged (provider names/signatures identical, only bodies changed).

## Threat Model Compliance
- **T-41-09 (DoS cooldown):** in-memory `_cooldownUntil` set on all-sources-fail, ~1 min, per-instance (cleared on restart). Verified by the D-06 test (second call within window does zero network).
- **T-41-10 (proxy infinite loop):** `fetchedAt.isBefore(today)` guard on `_isCorrectableProxy`. Verified by the "after re-fetch today, no infinite loop" test.
- **T-41-11 (backup ID):** exchange rates ride the existing AES-256-GCM `.hpb` container; family sync untouched.
- **T-41-12 (malformed import JSON):** `as int` / `as String` casts in the import loop throw on wrong type → caught by the existing outer try/catch → `Result.error('Backup import failed: ...')`.
- **T-41-13 (invalid manual rate):** `double.tryParse` + positive-finite guard → RateUnavailable, no upsert. Verified by the "invalid manual override" test.
- **T-41-14 (SC-5 never-block-save):** grep returns 0 in `lib/application/accounting/`.

## Issues Encountered
One unused-variable analyzer warning in the new export test (`final now` left over) — removed before commit.

## User Setup Required
None — no external service config; connectivity_plus already installed (Plan 02).

## Next Phase Readiness
- Phase 42 form provider can call `GetExchangeRateUseCase.execute(GetExchangeRateParams(...))` and receive `RateResultWithSignal` (RateResult + optional RateSignalDialog/RateSignalToast).
- The cache service is fully self-contained; Phase 42 needs a provider wiring `ExchangeRateCacheService` (repository + ApiClient + Connectivity) and `GetExchangeRateUseCase` if not already present — none created in this plan beyond the backup provider fix.
- No blockers.

## Self-Check: PASSED
- FOUND: lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
- FOUND: lib/application/currency/get_exchange_rate_use_case.dart
- FOUND: backup_data.g.dart contains exchangeRates (3 matches)
- FOUND commit: b6b8ea39
- FOUND commit: bc9a2310
- FOUND commit: 8ba46e9e
- VERIFIED: 33/33 tests GREEN; SC-5 grep returns 0; analyze 0 issues

---
*Phase: 41-exchange-rate-service*
*Completed: 2026-06-13*
