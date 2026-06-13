---
phase: 41-exchange-rate-service
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/infrastructure/exchange_rate/exchange_rate_api_client.dart
  - lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
  - lib/application/currency/rate_result.dart
  - lib/application/currency/get_exchange_rate_use_case.dart
  - lib/application/currency/repository_providers.dart
  - lib/application/settings/export_backup_use_case.dart
  - lib/application/settings/import_backup_use_case.dart
  - lib/data/daos/exchange_rate_dao.dart
  - lib/data/repositories/exchange_rate_repository_impl.dart
  - lib/features/currency/domain/repositories/exchange_rate_repository.dart
  - lib/features/settings/domain/models/backup_data.dart
  - lib/features/settings/presentation/providers/repository_providers.dart
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: fixes_applied
fix_report:
  fixed_at: 2026-06-13T00:00:00Z
  iteration: 1
  resolved:
    - CR-01
    - CR-02
    - WR-01
    - WR-02
    - WR-03
    - WR-04
    - IN-03
  skipped:
    - WR-05  # acceptable as-is per the finding's own guidance (D-09 bounds
             # the table; downgradable to Info). No fragile row-count cap added.
  deferred:
    - IN-01  # cooldown duration hoisted to a const as part of WR-04; 2-year
             # retention literal left inline (Info, non-blocking).
    - IN-02  # timeout-budget documentation (Info, non-blocking).
---

# Phase 41: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The Phase 41 exchange-rate service layer is largely well-built: the never-throw guarantee in `getRate`/`execute` is solid (nested try/catch, every path resolves to a `RateResult` variant), the three-source fallback chain is correct, URL privacy (SC-5) holds (URLs carry only date + currency, full URL logging is `kDebugMode`-guarded), the T-41-06 zero/non-finite guard is present, and the Clean Architecture layering + Riverpod 3 provider conventions are respected.

Two real defects warrant blocking: (1) the backup **import path persists exchange-rate rows with zero validation**, an asymmetric trust boundary versus the manual-override path which *does* validate — a malformed/hostile `.hpb` poisons the rate cache; (2) a **date-key skew** between the API URL date (local calendar date) and the cache key (UTC-normalized), which on non-UTC devices (the app defaults to Japan, UTC+9) stores each day's rate under the *previous* UTC day's key and creates near-midnight wrong-day cache hits and a latent RATE-05/D-03 misclassification surface. Several warnings concern the toast-signal payload carrying rate values mislabeled as JPY amounts, and inconsistent normalization between the API date and cache date.

## Critical Issues

### CR-01: Backup import persists exchange-rate rows with no value validation (trust boundary gap)

**✅ RESOLVED (commit 49861b04):** Each imported row now routes through the canonical `validateAppliedRate` (ADR-020) before upsert, and the `source` field is guarded against values outside `{frankfurter, fawazahmed0, manual}`; invalid rows are skipped, the rest still import. Test: `import_backup_use_case_test.dart` "CR-01: skips imported rows with an invalid rate but keeps valid ones".

**File:** `lib/application/settings/import_backup_use_case.dart:167-188`
**Issue:** The D-10 import loop deserializes each `exchangeRates` entry and calls `_exchangeRateRepo.upsert(er)` directly, reading `rate` as an unvalidated `String`. There is **no parse/positive/finite check** on `rate`. A backup file (which is attacker-supplyable — the password protects confidentiality, not authenticity of contents once decrypted) containing `"rate": "abc"`, `"-1"`, `"0"`, `"Infinity"`, `"NaN"`, or `"1e9"` is written straight into the cache table. Because the rate stays a string until `convertToJpy`, the poison surfaces *later*: `convertToJpy` calls `double.parse` (not `tryParse`) on the stored value and will throw, or produce a non-finite/negative JPY amount, on any transaction that subsequently resolves to this cached row via the fallback path. This is asymmetric with the manual-override write path (`get_exchange_rate_use_case.dart:103`) which *does* validate (`double.tryParse` + finite + `> 0`, T-41-13). The two write entry points to `source` rows must share the same validation floor.
**Fix:** Validate each imported row before upsert, reusing the canonical `validateAppliedRate` from `lib/shared/utils/currency_conversion.dart` (single-parse-site, ADR-020). Skip (or fail the import for) invalid rows rather than persisting them:
```dart
for (final erJson in backupData.exchangeRates) {
  final rawRate = erJson['rate'] as String;
  if (validateAppliedRate(rawRate) != null) {
    // skip malformed row (or: return Result.error('Backup contains invalid rate'))
    continue;
  }
  final er = ExchangeRate(/* ... */ rate: rawRate /* ... */);
  await _exchangeRateRepo.upsert(er);
}
```
Also consider guarding the `source` field against unexpected values (only `frankfurter` / `fawazahmed0` / `manual` are valid) so an imported `source` cannot silently break the D-07 non-manual fallback partition.

### CR-02: API URL date (local) and cache key (UTC-normalized) disagree — wrong-day cache rows on non-UTC devices

**✅ RESOLVED (commit d86f8154):** All three normalizers (cache service, repo impl, use case) now key on `DateTime.utc(d.year, d.month, d.day)` — local calendar date as UTC midnight — dropping the `.toUtc()` shift, so they agree with `_formatDate` and the transaction picker. IN-03 folded in: the API's bare `YYYY-MM-DD` `actualRateDate` is parsed as UTC-midnight of those digits, not via local `DateTime.parse`. Test: `exchange_rate_repository_impl_test.dart` "CR-02: local-calendar-date key (no UTC skew)" (JST-local-midnight round-trip).

**File:** `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart:53,166-169` vs `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart:158-163`
**Issue:** Two date paths use different time bases for the *same* request:
- `ExchangeRateApiClient._formatDate` builds the URL from **local** components (`date.year/month/day`, no conversion) — so the API is queried for the local calendar date (e.g. `2026-06-14`).
- `ExchangeRateCacheService._normalizeToUtcMidnight` (and the matching repo impl) does `date.toUtc()` *before* truncating to midnight. For a local-midnight `DateTime` on the app's default JST locale (UTC+9), `2026-06-14T00:00+09:00.toUtc()` → `2026-06-13T15:00Z` → key `2026-06-13`.

The transaction date picker produces exactly such local-midnight `DateTime`s (`transaction_details_form.dart:307`, `DateTime(date.year, date.month, date.day)`). Net effect on UTC+ devices: **the rate fetched for local date X is stored under cache key X-1**. Consequences: (a) near a local midnight boundary, `findByDate` for "today" can resolve a row that actually holds a neighboring day's rate; (b) the D-01 "today valid" and D-03 correctable-proxy logic compare `today = _normalizeToUtcMidnight(DateTime.now())` (also UTC-shifted) against `rateDate`, so the *fetchedAt*-based guards mostly mask it, but the keying is semantically one day off from what the user picked and from the URL actually queried. Lookups are internally self-consistent (same normalize on read/write), which is why tests pass, but the stored fact ("this is the rate for date K") is wrong by one day for the entire eastern hemisphere.
**Fix:** Pick one date basis and use it everywhere. Since CONTEXT D (and `_formatDate`) commit to "device local calendar date," normalize the cache key to local-date-as-UTC-midnight *without* the `.toUtc()` shift:
```dart
DateTime _normalizeToUtcMidnight(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day); // use local Y/M/D, not d.toUtc().Y/M/D
```
Apply the identical change in `exchange_rate_repository_impl.dart:71-74` and `get_exchange_rate_use_case.dart:161-164` so all three normalizers agree with `_formatDate`. Add a test that fetches a rate at a JST-midnight `DateTime` and asserts the stored `rateDate` equals the requested calendar date (not the day before).

## Warnings

### WR-01: Toast signal carries rate values mislabeled as JPY amounts

**✅ RESOLVED (commit 2adb2da1):** `RateSignalToast` now carries the full-precision rate strings (`oldRate`/`newRate`) plus `changeFraction`, instead of rounding rates into int `*Jpy` fields (which collapsed sub-1 rates to "0 → 0"). Phase 42 computes the JPY-equivalent delta from these + the amount it owns. Test: "WR-01: sub-1 rates produce a meaningful toast (not 0 → 0)".

**File:** `lib/application/currency/get_exchange_rate_use_case.dart:147-148`
**Issue:** `_maybeToast` returns `RateSignalToast(oldJpy: oldRate.round(), newJpy: newRate.round())`, but `oldRate`/`newRate` are **JPY-per-unit exchange rates**, while the `RateSignalToast` fields are documented (`rate_result.dart:150-153`) as "Previous/New JPY-equivalent amount." For sub-1 rates (e.g. a foreign currency stronger than JPY, rate ≈ 0.0062) both `.round()` to `0`, so the toast says "0 → 0." The >1% threshold math (line 144) is correct; only the carried payload is wrong/meaningless. Phase 42 will render a misleading toast.
**Fix:** Either compute the real JPY-equivalent delta here (requires the amount, which the use case does not currently receive — would need a `params.amountMinorUnits`), or change `RateSignalToast` to carry the rate strings it actually has (`oldRate`/`newRate` as `String`) and let Phase 42 compute the JPY delta from the resolved rate + amount. Do not round rates into int fields named `*Jpy`.

### WR-02: D-03 correctable-proxy re-fetch loses the proxy row when fetch fails offline

**✅ RESOLVED (commit 54d13656):** New `_proxyAwareFallback` returns the already-held exact-date correctable proxy (`RateFallback(rate: cached.rate, cachedDate: cached.rateDate)`) when re-fetch is impossible (offline / cooldown / fetch fail), before falling back to `findLatestNonManual`. Test: "WR-02: unrefreshable correctable proxy returns the exact-date proxy, not a latest-any-date fallback".

**File:** `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart:57,69-71,94-100`
**Issue:** When `findByDate` returns a correctable proxy (`_isCorrectableProxy` true), the cache-hit branch is skipped and control falls to the fetch path. If the device is then offline / in cooldown (line 69) or the fetch fails (line 94), `_cacheFallback(currency)` runs and returns the **most-recent** non-manual row via `findLatestNonManual` — which is *not necessarily* the proxy row for the requested date (it could be a newer date's row). So a correctable-proxy lookup for a specific historical date can silently return a *different date's* rate as a `RateFallback`, instead of the exact-date proxy the cache already holds. The exact-date proxy value is perfectly usable when re-fetch is impossible.
**Fix:** In the offline/fetch-fail fallback, prefer the already-fetched exact-date proxy row when present before falling back to `findLatestNonManual`. Capture the `cached` row from line 56 and, if it was a correctable proxy that could not be refreshed, return `RateFallback(rate: cached.rate, cachedDate: cached.rateDate)` rather than the latest-any-date row.

### WR-03: `RateManual` fallback only reached when latest row is manual; mixed history can hide a usable manual rate

**✅ RESOLVED (commit 54d13656):** Added `findLatestManual(currency)` to the DAO, repo impl, and domain interface; the manual fallback branch now calls it directly instead of inferring from `findLatest`. Tests: DAO/repo "WR-03: findLatestManual ..." and cache service "WR-03: manual fallback uses findLatestManual directly (not findLatest)".

**File:** `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart:125-132`
**Issue:** `_cacheFallback` reaches the manual branch only if `findLatestNonManual` returned null AND `findLatest(currency)` (latest of *any* source) happens to be `source == 'manual'`. If the currency has, say, an old API row plus a newer manual override, `findLatestNonManual` returns the old API row (correct per D-07 priority). But if it has *only* manual rows except one even-older API row, the intended "manual as last resort" still works. The edge case: when `findLatestNonManual` is null (no API rows at all) but `findLatest` returns a non-manual row due to a race/inconsistency, the manual fallback is skipped and the code drops to `RateUnavailable` despite a manual row existing. This is a narrow consistency gap, but the second query (`findLatest` then re-check `source == 'manual'`) is fragile.
**Fix:** Add a dedicated `findLatestManual(currency)` (mirroring `findLatestNonManual`) and call it directly in the manual branch instead of inferring from `findLatest`. Removes the dependency on which source happens to be newest.

### WR-04: Cooldown is never proactively cleared; stale `_cooldownUntil` only lazily expires

**✅ RESOLVED (commit 54d13656):** The connectivity gate is now consulted BEFORE the cooldown gate (`await _isOffline()` first, then `_inCooldown`), and `_cooldownUntil` is reset to `null` on a successful fetch. D-06 (online all-sources-fail still backs off for the window) is preserved — verified by the existing D-06 test plus "WR-04: connectivity is consulted before the cooldown is honored" and "WR-04: a successful fetch clears the in-memory cooldown". Cooldown duration hoisted to `_cooldownDuration` const (folds in IN-01's cooldown half).

**File:** `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart:42-45,96`
**Issue:** `_cooldownUntil` is set on all-sources-fail and only checked lazily via `_inCooldown`. It is never reset to `null` on a later successful fetch. Functionally the `isBefore` comparison handles expiry, so this is not a correctness bug, but a successful fetch *during* a still-active cooldown window cannot happen (the cooldown gate at line 69 forces cache-only), meaning a transient outage that recovers in 10s still blocks all network for the full ~1 min. D-06 intends "skip network during cooldown," but pairing it with no early-clear means genuine fast reconnects are delayed up to a minute even after connectivity is restored — the connectivity gate (`_isOffline`) is bypassed because `_inCooldown` is checked with `||` *before* it.
**Fix:** Re-order the gate so connectivity is consulted first, or clear the cooldown when `_isOffline()` reports back online: `if (_inCooldown && await _isOffline())` for the skip, and set `_cooldownUntil = null` when a fetch later succeeds (line 84 area). At minimum, check connectivity before honoring the cooldown so a restored connection can retry.

### WR-05: `findAll()` loads the entire rate cache into memory for every export with no bound

**⏭️ SKIPPED (by design):** The finding itself states "Acceptable as-is given D-09 bounds the table" and offers to downgrade to Info. The unbounded `transactions` load (far larger) uses the same pattern without a cap; adding an arbitrary row-count ceiling risks rejecting legitimate large-but-valid exports. No code change — left as accepted residual robustness note.

**File:** `lib/data/daos/exchange_rate_dao.dart:86-88`, `lib/application/settings/export_backup_use_case.dart:60,75-88`
**Issue:** Export calls `_exchangeRateRepo.findAll()` which `SELECT *`s the whole table, then maps every row to a `Map`. With the 2-year retention (D-09) and many currencies × daily rows this is bounded in practice, but there is no defensive cap and the rows are held fully in memory alongside all transactions during the GZip+encrypt pipeline. Not a security or correctness defect, but worth a guard given the backup runs on-device under memory pressure. (Flagged as WARNING per project file-size/robustness conventions; out-of-scope perf if you treat 2-yr retention as sufficient bound — downgrade to Info at your discretion.)
**Fix:** Acceptable as-is given D-09 bounds the table; if you want defense-in-depth, page the export or assert a sane row-count ceiling before serialization.

## Info

### IN-01: Magic-number cooldown duration and 2-year retention window are inline literals

**File:** `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart:96,160`
**Issue:** `Duration(minutes: 1)` (cooldown) and `now.year - 2` (retention) are inline magic numbers. CONTEXT marks these as "Claude's discretion" but they are policy values likely to be tuned.
**Fix:** Hoist to named `static const` (e.g. `_cooldownDuration`, `_retentionYears`) for discoverability and single-point tuning.

### IN-02: API timeout constants imply a ~4s worst case, exceeding the D-04 ~3s budget

**File:** `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart:33-34,67,77`
**Issue:** Per-source timeouts are 1500 (Frankfurter) + 1500 (`_primaryTimeout` reused for jsDelivr) + 1000 (Cloudflare) = up to **4.0s** of sequential network wait, above the D-04 "~3s total budget." Acceptable as worst-case-only (most requests resolve on source 1), but the sum drifts past the stated cap.
**Fix:** Either tighten the splits (e.g. 1200/1000/800 ≈ 3s) or document explicitly that 4s is the rare triple-fail ceiling and 3s is the typical path. Hoisting to named constants (IN-01) makes this tunable.

### IN-03: `actualRateDate` parsed with `DateTime.parse` (local) but compared/stored against UTC-normalized keys

**✅ RESOLVED (commit d86f8154, folded into CR-02):** `actualRateDate` is now parsed via `_parseUtcDate` (UTC-midnight of the bare `YYYY-MM-DD`), sharing one basis with the `rateDate` key. Test assertion updated in `exchange_rate_api_client_test.dart` (RATE-05).

**File:** `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart:110-112`
**Issue:** `DateTime.parse(responseDate)` on a bare `YYYY-MM-DD` yields a **local** DateTime, which then flows into the same UTC-normalization skew as CR-02 when stored. On business days `actualRateDate` is null so this is dormant, but on weekend/holiday rows (RATE-05, exactly when `actualRateDate` is set) the stored `actualRateDate` inherits the one-day skew. Folds into CR-02's fix.
**Fix:** Parse as `DateTime.utc(...)` from the components, or normalize via the same local-Y/M/D path adopted in CR-02, so `actualRateDate` and `rateDate` share one basis.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
