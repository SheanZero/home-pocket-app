# Phase 41: 汇率服务 (Exchange Rate Service) - Research

**Researched:** 2026-06-12
**Domain:** Flutter exchange-rate service layer — dual-source HTTP client, cache-first orchestration, sealed RateResult, offline-first use cases, ADR-022 override/date-change semantics
**Confidence:** HIGH — all claims drawn from live API verification (2026-06-12), direct codebase inspection of Phase 40 deliverables, and authoritative ADR decisions already ratified.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: 当日有效 (Today's rate TTL = same calendar day).** Rate fetched "today" is valid until local midnight; does not refresh within the same day. Historical rates are permanent and never revised.

**D-02: 保存即定格，永不回填 (Save locks rate, no backfill).** A transaction saved with today's provisional rate is never auto-updated when ECB publishes the official end-of-day value. `appliedRate` is the fact-at-save-time.

**D-03: 代理值缓存可修正 (Proxy-value cache rows are correctable).** A cache row where `actualRateDate != rateDate` AND `rateDate` is now a historical date (not today) → re-fetch once on next query. On success, overwrite the row. Already-saved transactions are unaffected (D-02).

**D-04: 总等待预算 ~3 秒 (Total network budget ~3 s).** From first API call to fallback: full chain ≤ 3 s. Per-source timeout ~1–1.5 s. Specific ms split is Claude's discretion.

**D-05: Connectivity listener as first gate.** When system reports fully offline, skip all network attempts and go directly to cache fallback. Package selection (connectivity_plus or equivalent) is Claude's discretion. New dependency requires iOS build verification.

**D-06: Online-but-all-sources-fail → ~1 min cooldown window.** After all three source attempts fail while online, record a short cooldown (~1 min); subsequent requests skip network during cooldown and go direct to cache. Resets on next request after cooldown expires.

**D-07: 手动汇率写入缓存但最低优先级 (Manual override is lowest-priority cache fallback).** Manual rate is upserted with `source='manual'`; lookup priority: API-fetched (latest) > API-cached > manual. Only used when offline with no API-cached rate for that currency.

**D-08: 零缓存 + 取不到 → RateResult.unavailable (No cache + no fetch → unavailable).** When a brand-new currency is offline and no rate exists in cache at all, return `RateResult.unavailable`. Phase 42 UI will require manual input before save.

**D-09: 2-year retention, cleanup on upsert.** During `upsert`, also `DELETE FROM exchange_rates WHERE rate_date < (today - 2 years)`. Zero additional scheduling. Already-saved transactions are unaffected (D-02 / no backfill).

**D-10: 备份导出/导入包含 exchange_rates 表 (Backup includes exchange_rates).** Restore gives immediate offline fallback. Family sync pipeline NEVER carries the cache (confirmed in prior research).

### Claude's Discretion

- Per-source timeout millisecond split (total budget ~3 s).
- Whether to retry within a single source (inclination: no — the source chain itself is the retry).
- Sealed `RateResult` variant names and fields (must satisfy SC-2 `fallback` with cached date, SC-3 `fetched.actualDate`).
- Use case decomposition granularity beyond `GetExchangeRateUseCase` (e.g., whether to extract a separate manual-override or date-change-recalc use case).
- Manual rate validity check details (positive, parseable — per Phase 40 conclusion; details are Claude's).
- Cooldown window exact duration (~1 min) and storage location (in-memory is sufficient, no persistence needed).
- "Today" timezone basis (lean toward device local date, consistent with transaction date picker).
- 2-year cleanup boundary precision (compare by `rateDate` value).
- >1% JPY-amount delta computation site (use-case layer emits signal; UI consumes).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RATE-01 | Automatic rate fetch for transaction date from free no-key API (Frankfurter primary, fawazahmed0 fallback) | ExchangeRateApiClient with dual-source strategy; both APIs live-verified 2026-06-12 |
| RATE-02 | Rates cached per (date, currency); historical permanent; today's rate has short TTL | ExchangeRateCacheService with TTL logic (D-01); exchange_rates Drift table already exists from Phase 40 |
| RATE-03 | Offline/fetch-fail: fall back to most-recent cached rate with actual date as staleness indicator; save never blocked | RateResult.fallback carrying cachedDate; connectivity gate (D-05); cooldown (D-06) |
| RATE-04 | User can manually override rate; JPY preview recalculates immediately | Manual override path writes `source='manual'` to cache (D-07); RateResult.manual variant; isManualOverride flag per ADR-022 |
| RATE-05 | Weekend/holiday: actual rate date shown when API returns different date than requested | actualRateDate field already in ExchangeRate model and exchange_rates table; RateResult.fetched.actualDate surface |
| RATE-06 | Date change re-fetches for new date; manual overrides preserved per ADR-022 D-02 | GetExchangeRateUseCase re-invoked on date change; isManualOverride flag triggers ADR-022 D-02 dialog signal vs. D-03 toast signal |

</phase_requirements>

---

## Summary

Phase 41 builds the exchange-rate service layer on top of the Phase 40 data foundation. Phase 40 delivered all persistence infrastructure: the `exchange_rates` Drift table (composite PK, TextColumn `rate`, `actualRateDate`, `source`, `fetchedAt`), `ExchangeRateDao` (findByDate / findLatest / upsert), `ExchangeRateRepositoryImpl`, `ExchangeRate` Freezed model, `ExchangeRateRepository` interface, `repository_providers.dart` Riverpod wiring, and the `convertToJpy()` single-parse-site utility. The full test suite passed 2635/2635 at Phase 40 close.

Phase 41 adds three new layers on this foundation: (1) `ExchangeRateApiClient` in `lib/infrastructure/exchange_rate/` — a stateless HTTP wrapper using the existing `http ^1.2.0` package, implementing the dual-source Frankfurter → fawazahmed0/jsDelivr → Cloudflare fallback chain; (2) `ExchangeRateCacheService` in the same directory — cache-first orchestration with connectivity gating, per-source timeouts (~1–1.5 s each), the ~1-min online-but-all-fail cooldown window, D-03 correctable proxy re-fetch, and D-09 2-year TTL pruning on upsert; (3) application use cases in `lib/application/currency/` — `GetExchangeRateUseCase` returning sealed `RateResult`, manual-override handling per ADR-022 D-02/D-03 signals, and backup export/import extension for D-10. The hard invariant throughout: `CreateTransactionUseCase` and `UpdateTransactionUseCase` contain zero HTTP calls.

Both external APIs are live-verified as of 2026-06-12: Frankfurter `api.frankfurter.dev` returns correct JSON for `JPY→USD` historical dates; fawazahmed0 jsDelivr CDN and Cloudflare fallback both return TWD and confirm `twd` key presence for today's date. The single new package to add (`connectivity_plus ^7.1.1`) has no intl or SQLCipher conflicts. All other infrastructure reuses existing `http ^1.6.0` and the Phase 40 data layer.

**Primary recommendation:** Build in three waves: Wave 1 (infrastructure HTTP client + cache service), Wave 2 (use cases + sealed RateResult + backup extension), Wave 3 (integration tests + Phase 42 contract validation). The `ExchangeRateRepository` interface from Phase 40 may need a `deleteOlderThan` method added for D-09 pruning — this is the only potential interface extension.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP fetch from Frankfurter / fawazahmed0 | Infrastructure (`exchange_rate/`) | — | Stateless I/O wrapping; no business logic; mirrors `sync/relay_api_client.dart` pattern |
| Cache-first orchestration (hit/miss/fallback) | Infrastructure (`exchange_rate/`) | Domain (ExchangeRateRepository) | Infrastructure owns I/O coordination; domain interface abstracts storage |
| Connectivity check (D-05) | Infrastructure (`exchange_rate/`) | — | Platform capability; wraps `connectivity_plus` |
| Cooldown window (D-06) | Infrastructure (`exchange_rate/`) | — | In-memory state; lives alongside the cache service |
| D-03 correctable proxy re-fetch | Infrastructure (`exchange_rate/`) | — | Cache-layer concern; determines when to re-fetch despite a hit |
| D-09 2-year TTL pruning | Infrastructure (`exchange_rate/`) via Repository | Data (ExchangeRateDao) | Needs DAO delete method; triggered on upsert path |
| Sealed RateResult production | Application (`currency/`) | — | Business rule: what does "a rate result" mean to callers? |
| ADR-022 D-02 dialog signal (override + date-change) | Application (`currency/`) | — | Business policy; surfaces signal, does not implement dialog |
| ADR-022 D-03 toast signal (>1% delta) | Application (`currency/`) | — | Business policy; use case computes delta, emits signal |
| Manual override persistence (D-07) | Infrastructure / Application boundary | Domain (ExchangeRateRepository) | Manual rate upserted via repository with `source='manual'` |
| Backup export/import extension (D-10) | Application (`settings/`) | Domain (BackupData) | Settings use case extension; BackupData gains exchange_rates list |
| Rate arithmetic (convertToJpy) | Shared utils | — | Already delivered in Phase 40; unchanged |

---

## Standard Stack

### Core (All from Phase 40 — no new packages required except connectivity_plus)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `http` | `^1.6.0` | HTTP GET calls to Frankfurter and fawazahmed0 | Already in pubspec; same injectable `http.Client` pattern as `relay_api_client.dart` [VERIFIED: pubspec.yaml, direct inspection] |
| Drift + SQLCipher | `^2.25.0` | exchange_rates table (Phase 40 deliverable) | Phase 40 infrastructure; `ExchangeRateDao` already live [VERIFIED: exchange_rate_dao.dart, Phase 40 VERIFICATION] |
| `freezed_annotation` | project pin | `ExchangeRate` model, sealed `RateResult` | Project standard for all domain models [VERIFIED: CLAUDE.md] |
| `riverpod_annotation` | project pin | Provider wiring in `application/currency/` | Project standard; `repository_providers.dart` already exists [VERIFIED: repository_providers.dart] |

### New Package Required

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `connectivity_plus` | `^7.1.1` | Connectivity check gate (D-05): skip network when fully offline | Pub.dev verified: 7.1.1 published; deps are flutter-only + `nm ^0.5.0` + `collection ^1.18.0` (already in pubspec) — no intl conflict, no SQLCipher conflict [VERIFIED: pub.dev API 2026-06-12] |

**connectivity_plus dependency chain** (verified via pub.dev API):
- `flutter`, `flutter_web_plugins`, `connectivity_plus_platform_interface ^2.1.0`, `web >=0.5.0 <2.0.0`, `meta ^1.8.0`, `nm ^0.5.0`, `collection ^1.18.0`
- No `intl` in transitive chain. No sqlite3 conflict. Flutter SDK constraint: `>=3.7.0` (project uses 3.44.0). [VERIFIED: pub.dev API 2026-06-12]

### NOT Adding

| Library | Why Not |
|---------|---------|
| `dio` | `http ^1.6.0` already present; adds bundle overhead [VERIFIED: pubspec.yaml] |
| `decimal` | Adds intl constraint; `convertToJpy()` in `currency_conversion.dart` covers all arithmetic (Phase 40 deliverable) [VERIFIED: currency_conversion.dart] |
| Any rate-parsing library | APIs return JSON; `double.parse()` in `convertToJpy()` is the single parse site [VERIFIED: ADR-020] |

**Installation (new dependency only):**
```bash
flutter pub add connectivity_plus
# Then verify iOS build:
flutter build ios --debug --no-codesign
```

---

## Package Legitimacy Audit

> slopcheck was not installable in this environment — all packages tagged [ASSUMED] or manually verified.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `connectivity_plus` | pub.dev | ~4 yrs (FlutterCommunity) | Multi-million | [github.com/fluttercommunity/plus_plugins](https://github.com/fluttercommunity/plus_plugins) | N/A (slopcheck unavailable) | Approved — well-known FlutterCommunity plugin, used in millions of Flutter apps [VERIFIED: pub.dev API] |

**Packages removed due to slopcheck [SLOP] verdict:** none

**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. `connectivity_plus` is manually verified as the official FlutterCommunity plugin at pub.dev/packages/connectivity_plus with 7.1.1 as current version. No `checkpoint:human-verify` task required given the package's well-documented provenance.*

---

## Architecture Patterns

### System Architecture Diagram

```
User action (currency select / date change)
    │
    ▼
GetExchangeRateUseCase.execute(date, currency)
    │
    ├── [isManualOverride=true AND date changed] → emit DialogSignal.overrideConflict (ADR-022 D-02)
    │
    ▼
ExchangeRateCacheService.getRate(date, currency)
    │
    ├── ConnectivityGate: system offline? → skip to CACHE
    │
    ├── [ONLINE] → check correctable proxy (D-03):
    │     ExchangeRateRepository.findByDate(currency, date)
    │     ├── HIT + not correctable → RateResult.cached(rate, cachedDate)
    │     ├── HIT + correctable (actualRateDate != rateDate, historical date) → go to FETCH
    │     └── MISS → go to FETCH
    │
    ├── [FETCH] Frankfurter: GET api.frankfurter.dev/v1/{date}?from=JPY&to={C}
    │     ├── 200 → parse rate + actualDate → upsert + prune (D-09) → RateResult.fetched(rate, actualDate?)
    │     ├── 404 "not found" (TWD, etc.) → try fawazahmed0
    │     └── timeout/error → try fawazahmed0
    │
    ├── [FETCH] fawazahmed0 jsDelivr: GET cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json
    │     ├── 200 → parse rate → upsert + prune (D-09) → RateResult.fetched(rate, actualDate=null)
    │     ├── 404 → try Cloudflare fallback
    │     └── timeout/error → try Cloudflare fallback
    │
    ├── [FETCH] fawazahmed0 Cloudflare: GET {date}.currency-api.pages.dev/v1/currencies/jpy.min.json
    │     ├── 200 → parse → upsert + prune → RateResult.fetched(rate, actualDate=null)
    │     └── all failed → record cooldown (D-06) → go to CACHE
    │
    └── [CACHE] offline fallback
          ExchangeRateRepository.findLatest(currency) where source != 'manual' → found → RateResult.fallback(rate, cachedDate)
          → manual only: RateResult.manual(rate, cachedDate) [D-07 lowest priority]
          → nothing at all: RateResult.unavailable [D-08]

RateResult returned to GetExchangeRateUseCase
    │
    ├── [no override, date changed, |newJpy - oldJpy| / oldJpy > 0.01] → attach ToastSignal (ADR-022 D-03)
    │
    └── Return RateResult (with isManualOverride flag, optional signal) to caller

Caller (Phase 42 form provider / use case)
    ├── Passes resolved rate to CreateTransactionUseCase / UpdateTransactionUseCase
    └── Neither use case ever calls ExchangeRateCacheService or HTTP
```

### Recommended Project Structure (new files only)

```
lib/infrastructure/exchange_rate/          ← NEW directory (mirrors sync/)
├── exchange_rate_api_client.dart          ← stateless HTTP wrapper
└── exchange_rate_cache_service.dart       ← cache-first orchestration

lib/application/currency/                 ← already exists from Phase 40
├── repository_providers.dart              ← already exists; may add service providers
├── repository_providers.g.dart            ← already exists (generated)
├── get_exchange_rate_use_case.dart        ← NEW
└── (optional) rate_result.dart            ← NEW if not co-located with use case

lib/features/currency/domain/
├── models/exchange_rate.dart              ← Phase 40 (unchanged)
└── repositories/exchange_rate_repository.dart  ← Phase 40; may need deleteOlderThan

lib/data/
├── daos/exchange_rate_dao.dart            ← Phase 40; may need deleteOlderThan
└── repositories/exchange_rate_repository_impl.dart  ← Phase 40; may need deleteOlderThan

lib/application/settings/
├── export_backup_use_case.dart            ← Phase 40 (extend for D-10)
└── import_backup_use_case.dart            ← Phase 40 (extend for D-10)

lib/features/settings/domain/models/
└── backup_data.dart                       ← Phase 40 (extend: add exchangeRates list)
```

### Pattern 1: ExchangeRateApiClient — injectable http.Client mirror of RelayApiClient

**What:** Stateless HTTP wrapper for Frankfurter and fawazahmed0, with injectable `http.Client` for testing.

**When to use:** Called only by `ExchangeRateCacheService` on cache-miss.

```dart
// Source: lib/infrastructure/sync/relay_api_client.dart (injectable client pattern)
class ExchangeRateApiClient {
  ExchangeRateApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;
  static const _frankfurterBase = 'https://api.frankfurter.dev/v1';
  static const _fawazahmedJsDelivr =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api';
  static const _fawazahmedCloudflare =
      'https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json';

  /// Fetch JPY-per-1-unit rate for [currency] on [date].
  ///
  /// Returns (rate string, actualRateDate, source) or throws on all-fail.
  /// URL MUST contain only date (YYYY-MM-DD) and currency code — no user data.
  Future<({String rate, DateTime? actualRateDate, String source})>
      fetchRate(String currency, DateTime date) async { ... }
}
```

**Privacy invariant:** URL contains only `YYYY-MM-DD` date string and ISO 4217 currency code. Never includes user ID, book ID, amount, or any user-derived data. [VERIFIED: STACK.md live-verified API calls]

### Pattern 2: Sealed RateResult — type-safe outcome for all callers

**What:** A sealed class (or Dart `sealed` keyword, or Freezed union) with variants covering every possible cache/fetch outcome.

**When to use:** Returned by `GetExchangeRateUseCase` to all callers (Phase 42 form providers).

```dart
// Suggested variant set (Claude's discretion on naming per CONTEXT.md):
sealed class RateResult {
  const RateResult();
}

/// Fresh from API. actualDate is non-null when API returned a different date
/// (weekend/holiday fallback — RATE-05).
final class RateFetched extends RateResult {
  const RateFetched({
    required this.rate,          // String, full precision (ADR-020)
    required this.currency,
    required this.rateDate,      // the requested date
    this.actualDate,             // non-null on weekend/holiday (RATE-05)
    required this.source,        // 'frankfurter' | 'fawazahmed0'
  });
  // ...
}

/// From cache (exact-date hit, not a correctable proxy, TTL valid).
final class RateCached extends RateResult {
  const RateCached({
    required this.rate,
    required this.currency,
    required this.cachedDate,    // actual date of cached rate (staleness indicator)
    required this.source,
    this.isManualOverride = false,  // ADR-022 D-02 flag
  });
  // ...
}

/// Offline fallback — most recent API-cached rate (source != 'manual').
final class RateFallback extends RateResult {
  const RateFallback({
    required this.rate,
    required this.currency,
    required this.cachedDate,    // actual date (staleness indicator for RATE-03)
  });
  // ...
}

/// Manual-only fallback — only manual override exists (D-07 lowest priority).
final class RateManual extends RateResult {
  const RateManual({
    required this.rate,
    required this.currency,
    required this.cachedDate,
  });
  // ...
}

/// No rate available — new currency + fully offline + no cache (D-08).
/// Phase 42 UI must require manual input before save.
final class RateUnavailable extends RateResult {
  const RateUnavailable({required this.currency});
}
```

**ADR-022 constraint:** `RateResult` (or wrapper) must carry `isManualOverride: bool` so use case can detect ADR-022 D-02 scenario (override flag + date changed → dialog signal).

### Pattern 3: Cache-first orchestration in ExchangeRateCacheService

**What:** Implements the full get-rate flow: connectivity gate → D-03 correctable check → Frankfurter → fawazahmed0 jsDelivr → Cloudflare → cache fallback → unavailable.

**When to use:** Called by `GetExchangeRateUseCase` only.

```dart
// Correctable proxy detection (D-03):
// A cache row is correctable if:
//   row.actualRateDate != null (was a proxy at fetch time) AND
//   row.rateDate < today (is now a historical date, ECB has final value)
bool _isCorrectableProxy(ExchangeRate row) {
  final today = _todayUtcMidnight();
  return row.actualRateDate != null && row.rateDate.isBefore(today);
}

// D-09 TTL pruning — called on every upsert:
Future<void> _pruneOldRows() async {
  final cutoff = DateTime.now().subtract(const Duration(days: 365 * 2));
  await _repository.deleteOlderThan(cutoff);  // needs new repo method
}

// D-06 in-memory cooldown:
DateTime? _cooldownUntil;
bool get _inCooldown =>
    _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);
```

**"Today" timezone:** device local date (consistent with transaction date picker). Convert to UTC midnight for DB comparison.

### Pattern 4: GetExchangeRateUseCase — orchestrates signals per ADR-022

**What:** Application-layer use case. Calls `ExchangeRateCacheService`, applies ADR-022 D-02/D-03 business rules, returns `RateResult` with optional attached signal.

**ADR-022 signal logic (Claude's discretion on exact API shape):**

```dart
// D-02: triggered when overrideFlag=true AND date changed
// Signal: Phase 42 shows dialog; use case just returns a signal in the result
if (wasManualOverride && dateChanged) {
  return RateResult.withSignal(RateDialogSignal.overrideConflict(...));
}

// D-03: triggered when no override, date changed, >1% JPY delta
final changePct = (newJpy - oldJpy).abs() / oldJpy;
if (!wasManualOverride && dateChanged && changePct > 0.01) {
  return RateResult.withSignal(RateToastSignal.jpyAmountChanged(
    oldJpy: oldJpy, newJpy: newJpy));
}
```

**Phase 42 integration contract:** Phase 42 form provider calls `GetExchangeRateUseCase`, inspects `RateResult` for signals, and renders the ADR-022 dialog or toast. The use case never renders UI.

### Anti-Patterns to Avoid

- **HTTP call inside CreateTransactionUseCase or UpdateTransactionUseCase:** Rate is always pre-resolved before these are called. Never-block-save invariant. [VERIFIED: PITFALLS.md Pitfall 6, Phase 40 VERIFICATION SC-5]
- **User data in API URLs:** Frankfurter URL: `/{date}?from=JPY&to={C}` — no amount, no user ID. fawazahmed0 URL: `@{date}/v1/currencies/jpy.min.json` — no user data. [VERIFIED: STACK.md live API calls]
- **Returning 0.0 or null rate on HTTP 404:** Frankfurter 404 means "currency not found" → route to fawazahmed0. Do not treat as fallback-to-cache. [VERIFIED: PITFALLS.md Pitfall 5]
- **Separate `double.parse()` calls outside `convertToJpy()`:** All rate arithmetic must go through `convertToJpy()`. [VERIFIED: ADR-020, currency_conversion.dart]
- **Silently clobbering manual override on date change:** ADR-022 D-02 requires a dialog, not a silent re-fetch. [VERIFIED: ADR-022]
- **Using SharedPreferences for rate cache:** Decided in SUMMARY.md — Drift table wins (encrypted, queryable, SQL ORDER BY fallback). [VERIFIED: SUMMARY.md §Conflict]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP GET with timeout | Custom Future.timeout wrapper | `http.Client` + `http.get(timeout: const Duration(seconds: 2))` | Existing `http` package; mirrors `relay_api_client.dart` pattern [VERIFIED: relay_api_client.dart] |
| Connectivity check | `InternetAddress.lookup()` poll | `connectivity_plus` (D-05) | Platform-native; handles airplane mode, WiFi-without-internet, cellular correctly on iOS + Android |
| Rate precision arithmetic | `double * double` inline | `convertToJpy()` in `currency_conversion.dart` | Phase 40 deliverable; single parse site (ADR-020) [VERIFIED: currency_conversion.dart] |
| Currency metadata | Custom ISO table | `sealed_currencies ^3.2.0` (already approved in STACK.md) | Phase 42 concern; Phase 41 only needs currency code string |
| JSON parsing | Custom regex | `dart:convert jsonDecode()` with safe key lookup | Frankfurter and fawazahmed0 return standard JSON; use `as T?` null-safe casts |
| Cache expiry scheduler | Timer / WorkManager | D-09: DELETE on upsert (zero scheduling) | Piggyback on the upsert that already happens on every new rate fetch |
| "Is correctable proxy" query | Separate DB query | In-memory check of returned `ExchangeRate` row fields | `row.actualRateDate != null && row.rateDate.isBefore(today)` on the row already fetched |

**Key insight:** Every complex rate-service problem (precision, offline fallback, multi-source routing, edit semantics) already has a decided solution in Phase 40 ADRs. Don't re-derive — implement from the ADRs.

---

## Common Pitfalls

### Pitfall 1: Frankfurter Base URL Version

**What goes wrong:** Using `api.frankfurter.app` (deprecated) instead of `api.frankfurter.dev/v1`.

**Why it happens:** ARCHITECTURE.md and old docs used the `.app` URL. The `.dev/v1` domain is the current canonical URL.

**How to avoid:** Use `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}`. [VERIFIED: STACK.md live-verified, Frankfurter API 2026-06-12]

**Warning signs:** URL hardcoded as `api.frankfurter.app` anywhere in code.

### Pitfall 2: Frankfurter Returns Different Date (Weekend/Holiday) — Not a 404

**What goes wrong:** Frankfurter returns 200 with `"date": "2026-06-12"` when you asked for `"2026-06-14"` (Saturday). The `actualRateDate` differs from `requestedDate`. Code that compares `response.date == requestedDate` to detect this correctly is fine; code that assumes they always match will silently miss RATE-05.

**Why it happens:** Frankfurter always returns the nearest available rate; it never 404s for weekends.

**How to avoid:** Always compare `response['date']` to the requested date. If different, set `actualRateDate` on the cached row (already a column in `exchange_rates_table.dart`). Surface this as `RateFetched.actualDate`. [VERIFIED: STACK.md API comparison table]

**Warning signs:** `ExchangeRate(actualRateDate: null)` for a Saturday-date request.

### Pitfall 3: fawazahmed0 URL Format Confusion

**What goes wrong:** Using the old GitHub-based URL (`cdn.jsdelivr.net/gh/fawazahmed0/currency-api@{date}`) which no longer works for historical dates.

**Why it happens:** Older research or training data references the legacy URL scheme.

**How to avoid:** Use the npm package URL:
- Primary jsDelivr: `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{YYYY-MM-DD}/v1/currencies/jpy.min.json`
- Cloudflare fallback: `https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/jpy.min.json`

Both live-verified 2026-06-12. TWD key (`twd`) confirmed present in response. [VERIFIED: live curl 2026-06-12]

**Warning signs:** URL containing `/gh/` instead of `/npm/`.

### Pitfall 4: D-03 Correctable Proxy — Infinite Re-Fetch Loop

**What goes wrong:** Every call to `findByDate` for a historical date with `actualRateDate != null` triggers a re-fetch. If the re-fetch also returns a weekend proxy (e.g., requesting 2026-06-14 Saturday still gets 2026-06-13 Friday), the row is re-stored with `actualRateDate` still non-null, and the next call triggers another re-fetch.

**Why it happens:** D-03 was designed for the "proxy→real value" scenario (ECB publishes the real rate later). But weekends will always return a proxy.

**How to avoid:** The correctable condition is: `row.actualRateDate != null && row.rateDate.isBefore(today)`. After re-fetching, if the new response ALSO returns `actualRateDate != null` (still a proxy, which is correct for genuine weekend dates), accept the result — it's the canonical ECB answer for that date and no further re-fetch is needed. The fix: after one re-fetch attempt, accept whatever the API returns (even if still a proxy) and do NOT mark the row as "requires re-fetch again." The correctable-proxy mechanism is one-shot per row-per-app-session, not a loop.

**How to avoid (implementation):** In `ExchangeRateCacheService`, when a re-fetch is triggered by D-03, the `fetchedAt` timestamp on the new upserted row is fresh (today). So on the NEXT access, even if `actualRateDate != null` is true, the re-fetch guard should also check: `row.fetchedAt` is NOT today (i.e., the row was fetched before today's session), OR the row predates the ECB publication window. Simplest: only trigger D-03 re-fetch if `row.fetchedAt.isBefore(today)` — once re-fetched today, don't re-fetch again today.

**Warning signs:** Log showing the same (currency, date) pair being fetched more than once per day.

### Pitfall 5: Cooldown Window (D-06) — Affects All Currencies

**What goes wrong:** Cooldown is recorded after all three sources fail for currency X. But the cooldown should prevent re-fetching for any currency during the window (not just currency X). Currency Y requested 10 seconds later should also skip network.

**Why it happens:** Naive per-currency cooldown instead of global.

**How to avoid:** Single in-memory `DateTime? _cooldownUntil` on the service. When ANY currency's fetch chain fails completely, set `_cooldownUntil = DateTime.now().add(const Duration(minutes: 1))`. Check before any network attempt. [ASSUMED — duration is ~1 min per D-06; exact value is Claude's discretion]

### Pitfall 6: D-09 Pruning Needs ExchangeRateRepository.deleteOlderThan

**What goes wrong:** Phase 40 `ExchangeRateRepository` interface has only `findByDate`, `findLatest`, and `upsert`. The D-09 2-year pruning requires deleting rows where `rateDate < cutoff`. If `upsert` calls `_pruneOldRows()` but the repository has no delete method, this requires extending the Phase 40 interface.

**Why it happens:** D-09 was specified in Phase 41 CONTEXT.md after Phase 40 was built.

**How to avoid:** Add `Future<void> deleteOlderThan(DateTime cutoff)` to:
1. `ExchangeRateRepository` interface (domain)
2. `ExchangeRateDao` (data — SQL `DELETE WHERE rate_date < ?`)
3. `ExchangeRateRepositoryImpl` (data)

Run `build_runner` after interface change (Freezed is not affected, but DAO regeneration may be needed). [VERIFIED: direct inspection of current interface — method is absent]

### Pitfall 7: Manual Rate (D-07) Lookup Priority

**What goes wrong:** When looking up the fallback rate in `ExchangeRateRepository.findLatest(currency)`, the result might be a `source='manual'` row even when an API-fetched row exists at an older date.

**Why it happens:** `findLatest` orders by `rateDate DESC` — a manual override for today would rank above an API-cached rate for yesterday.

**How to avoid:** Implement two-pass fallback in `ExchangeRateCacheService`:
1. First: `findLatestBySource(currency, excludingManual: true)` — look for most-recent API-sourced row.
2. Second (only if null): `findLatestBySource(currency, manualOnly: true)` — use manual as last resort.

This requires either two separate DAO methods or a `source` filter on `findLatest`. Add `Future<ExchangeRate?> findLatestNonManual(String currency)` to the DAO (and extend the repository interface + impl accordingly). [VERIFIED: D-07 decision, current DAO interface has no source filter]

### Pitfall 8: D-10 Backup — BackupData Freezed Model Requires build_runner

**What goes wrong:** Adding `List<Map<String, dynamic>>? exchangeRates` to `BackupData` (a `@freezed` model with `fromJson`) requires running `build_runner` to regenerate `backup_data.freezed.dart` and `backup_data.g.dart`. Forgetting this step causes `The generated file 'backup_data.g.dart' is outdated` errors.

**How to avoid:** Include `build_runner build --delete-conflicting-outputs` in the Wave that touches `backup_data.dart`. Check the `@Default(<String>[])` vs `List?` nullable choice — prefer `@Default([])` for backward-compat JSON deserialization of old backup files that lack the field. [VERIFIED: backup_data.dart inspection]

---

## Code Examples

### Frankfurter API response parsing

```dart
// Source: STACK.md §Exchange Rate API (live-verified 2026-06-12)
// GET https://api.frankfurter.dev/v1/2026-06-11?from=JPY&to=USD
// Response: {"amount":1.0,"base":"JPY","date":"2026-06-11","rates":{"USD":0.00623}}
//
// To get JPY per 1 USD: invert the rate
// jpyPerUsd = 1.0 / frankfurterRate['USD'] = 1.0 / 0.00623 ≈ 160.51
//
// IMPORTANT: base in response is always JPY (we always request ?from=JPY)
// rates[currency] = 1 JPY in that currency → invert to get JPY per 1 currency

final body = jsonDecode(response.body) as Map<String, dynamic>;
final responseDate = body['date'] as String;
final rates = body['rates'] as Map<String, dynamic>?;
final rawRate = (rates?[currency] as num?)?.toDouble();
if (rawRate == null || rawRate == 0) throw Exception('rate absent');
final jpyPerUnit = 1.0 / rawRate;
final rateStr = jpyPerUnit.toStringAsPrecision(7);  // preserve ≥6 sig figs
```

### fawazahmed0 API response parsing

```dart
// Source: STACK.md §Exchange Rate API (live-verified 2026-06-12)
// GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-06-12/v1/currencies/jpy.min.json
// Response: {"date":"2026-06-12","jpy":{"usd":0.00623, "twd":0.0304, ...}}
//
// Rate is in same format as Frankfurter: 1 JPY = X currency
// invert to get JPY per 1 unit of currency

final body = jsonDecode(response.body) as Map<String, dynamic>;
final jpyRates = body['jpy'] as Map<String, dynamic>?;
final rawRate = (jpyRates?[currency.toLowerCase()] as num?)?.toDouble();
if (rawRate == null || rawRate == 0) throw Exception('currency not in response');
final jpyPerUnit = 1.0 / rawRate;
```

### connectivity_plus check (gate for D-05)

```dart
// Source: connectivity_plus pub.dev documentation [ASSUMED - standard API,
//         verify via ctx7 or pub.dev docs at implementation time]
import 'package:connectivity_plus/connectivity_plus.dart';

final result = await Connectivity().checkConnectivity();
final isOffline = result.every((c) => c == ConnectivityResult.none);
if (isOffline) {
  // skip all network, go direct to cache fallback
}
```

### D-09 pruning on upsert

```dart
// Prune rows older than 2 years during every upsert (D-09).
// Called as a side effect after successful upsert, not blocking the return.
Future<void> _pruneStaleCache() async {
  final cutoff = DateTime.utc(
    DateTime.now().year - 2,
    DateTime.now().month,
    DateTime.now().day,
  );
  await _repository.deleteOlderThan(cutoff);  // new method needed on repository
}
```

### >1% JPY delta check (ADR-022 D-03)

```dart
// Source: ADR-022 §D-03 (direct inspection 2026-06-12)
// Compare old and new JPY integer amounts:
final changePct = (newJpy - oldJpy).abs() / oldJpy;
if (changePct > 0.01 && !wasManualOverride && dateChanged) {
  // emit toast signal (use case responsibility — no UI here)
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SharedPreferences for rate cache | Drift `exchange_rates` table | Phase 41 (locked in SUMMARY.md) | Encrypted, queryable, SQL-based fallback |
| `RealColumn` for rate storage | `TextColumn` (string literal) | ADR-020 (Phase 40) | No float precision loss; preview == stored guaranteed |
| `api.frankfurter.app` URL | `api.frankfurter.dev/v1` URL | Mid-2025 (new domain) | Old domain deprecated |
| Exchange rate as double arithmetic | `convertToJpy()` single parse site | Phase 40 | Single parse point, testable, no inline double multiplication |

**Deprecated/outdated:**
- `RealColumn get rate` on exchange_rates: ARCHITECTURE.md mentioned this; Phase 40 executor used TextColumn instead (correct, ADR-020 compliant). The ARCHITECTURE.md snippet is outdated — actual code uses TextColumn.
- Old GitHub fawazahmed0 URL (`cdn.jsdelivr.net/gh/fawazahmed0/currency-api@{date}`): replaced by npm URL scheme. Only valid from 2024-10-10 forward.

---

## Repository Interface Extensions Needed

Phase 40 delivered `ExchangeRateRepository` with: `findByDate`, `findLatest`, `upsert`.

Phase 41 requires two additional methods:

| New Method | Needed For | Add To |
|------------|-----------|--------|
| `Future<void> deleteOlderThan(DateTime cutoff)` | D-09 2-year TTL pruning on upsert | Repository interface + ExchangeRateDao + ExchangeRateRepositoryImpl |
| `Future<ExchangeRate?> findLatestNonManual(String currency)` | D-07 priority: API-cached before manual fallback | Repository interface + DAO (source != 'manual' filter) + RepositoryImpl |

These are additive extensions; no existing method signatures change. Run `build_runner` if DAO code generation is affected (likely not — Drift DAOs are handwritten, not generated).

---

## D-10 Backup Extension Analysis

**Current state (`backup_data.dart`):** `BackupData` is a `@freezed` class with `transactions`, `categories`, `books`, `settings` — no `exchangeRates` field.

**Required changes:**
1. `BackupData` gains `@Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> exchangeRates` — nullable-with-default ensures backward-compat deserialization of old `.hpb` files.
2. `ExportBackupUseCase.execute()` fetches all `ExchangeRate` rows from `ExchangeRateRepository`, serializes each to `Map<String, dynamic>` (mirror the `TransactionSyncMapper` pattern), and includes in `BackupData`.
3. `ImportBackupUseCase` deserializes `backup.exchangeRates` and upserts each row via `ExchangeRateRepository`.

**BackupData serialization shape for one exchange_rate row:**
```json
{
  "currency": "USD",
  "rateDate": 1749686400,       // epoch seconds (matches UtcEpochDateTimeConverter)
  "rate": "149.5023",
  "fetchedAt": 1749712345,
  "source": "frankfurter",
  "actualRateDate": null
}
```

**D-10 constraint:** Family sync pipeline must NOT include exchange_rates — this is research-locked. Only backup includes them.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `connectivity_plus ^7.1.1` has no transitive dependency conflicts with `sqlcipher_flutter_libs` or any pinned project dep | Package Legitimacy Audit | Need to run `flutter pub get` and verify; `flutter build ios --debug --no-codesign` is the final gate per CLAUDE.md |
| A2 | connectivity_plus `Connectivity().checkConnectivity()` API is stable at v7.1.1 | Code Examples | Verify via Context7 or official docs at implementation time |
| A3 | Cooldown window ~1 min is sufficient to avoid repeated 3-second stalls (D-06) | Architecture Patterns | If too short, users experience repeated slow-then-fallback; if too long, genuine reconnects are delayed |
| A4 | fawazahmed0 `jpy.min.json` endpoint returns rates in the same direction (1 JPY = X currency) consistently across both jsDelivr and Cloudflare CDNs | Code Examples | Verified live 2026-06-12 for both CDNs; re-verify at implementation start per STATE.md flag |

**If this table is empty:** False — A1 and A2 require implementation-time verification.

---

## Open Questions

1. **Connectivity_plus API surface at v7.1.1**
   - What we know: Package exists at 7.1.1; deps are clean; no intl conflict.
   - What's unclear: Exact API — `checkConnectivity()` returns `List<ConnectivityResult>` in v6+; confirm v7.1.1 maintains this shape.
   - Recommendation: Fetch via Context7 or `ctx7 docs connectivity_plus "check connectivity offline detection"` at Wave 1 start before writing the gate.

2. **`ExchangeRateRepository.findLatestNonManual` — SQL filter approach**
   - What we know: `ExchangeRateDao.findLatest` is currently unfiltered by source.
   - What's unclear: Whether to add a new `findLatestNonManual` DAO method or add a `source` filter parameter to `findLatest`.
   - Recommendation: Add `findLatestNonManual(String currency)` as a separate method for clarity; mirrors the existing single-purpose method pattern in the DAO.

3. **D-03 correctable proxy — infinite re-fetch guard**
   - What we know: See Pitfall 4 above.
   - What's unclear: Exact implementation of "don't re-fetch the same row twice in a session" — need a light in-memory set or rely on `fetchedAt = today` logic.
   - Recommendation: Use `fetchedAt`-today check as the guard: a row re-fetched today has `fetchedAt >= today midnight`; skip correctable-proxy re-fetch for such rows.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `http ^1.6.0` | ExchangeRateApiClient | ✓ | 1.6.0 | — |
| Frankfurter API (`api.frankfurter.dev`) | RATE-01, primary source | ✓ | REST (live-verified 2026-06-12) | fawazahmed0 |
| fawazahmed0 jsDelivr CDN | RATE-01, TWD fallback | ✓ | npm versioned (live-verified 2026-06-12) | Cloudflare fallback |
| fawazahmed0 Cloudflare fallback | RATE-01, tertiary | ✓ | `{date}.currency-api.pages.dev` (live-verified 2026-06-12) | cache |
| `connectivity_plus` | D-05 gate | NOT YET IN PUBSPEC | 7.1.1 available | None — required for D-05 |
| Drift `exchange_rates` table | All cache ops | ✓ | Phase 40 deliverable | — |
| `convertToJpy()` | All rate arithmetic | ✓ | Phase 40 deliverable | — |
| Flutter | Build | ✓ | 3.44.0 | — |

**Missing dependencies with no fallback:**
- `connectivity_plus`: must be added to `pubspec.yaml` and iOS build verified before Wave 1 can ship.

**Missing dependencies with fallback:**
- None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none project-level; standard `test/` directory |
| Quick run command | `flutter test test/unit/application/currency/ test/unit/infrastructure/exchange_rate/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RATE-01 | Frankfurter fetch returns rate + actualDate for business day | unit (MockClient) | `flutter test test/unit/infrastructure/exchange_rate/exchange_rate_api_client_test.dart` | ❌ Wave 0 |
| RATE-01 | fawazahmed0 route triggered for TWD (Frankfurter 404) | unit (MockClient) | `flutter test test/unit/infrastructure/exchange_rate/exchange_rate_api_client_test.dart` | ❌ Wave 0 |
| RATE-01 | fawazahmed0 Cloudflare fallback triggered on jsDelivr error | unit (MockClient) | `flutter test test/unit/infrastructure/exchange_rate/exchange_rate_api_client_test.dart` | ❌ Wave 0 |
| RATE-02 | Cache hit on second (date, currency) request → zero network calls | unit (MockClient) | `flutter test test/unit/infrastructure/exchange_rate/exchange_rate_cache_service_test.dart` | ❌ Wave 0 |
| RATE-02 | Today's rate re-fetches after local midnight (TTL=D-01) | unit | same | ❌ Wave 0 |
| RATE-02 | Historical rate never re-fetched (permanent) | unit | same | ❌ Wave 0 |
| RATE-02 | D-03 correctable proxy row triggers one-time re-fetch | unit | same | ❌ Wave 0 |
| RATE-03 | All APIs fail → returns RateResult.fallback with cachedDate | unit (mocked repo) | `flutter test test/unit/application/currency/get_exchange_rate_use_case_test.dart` | ❌ Wave 0 |
| RATE-03 | GetExchangeRateUseCase never throws to caller (wraps all errors) | unit | same | ❌ Wave 0 |
| RATE-03 | D-06 cooldown window: second request within 1 min skips network | unit | exchange_rate_cache_service_test.dart | ❌ Wave 0 |
| RATE-04 | Manual override upserted with source='manual' | unit | get_exchange_rate_use_case_test.dart | ❌ Wave 0 |
| RATE-04 | Manual rate is used only when no API cache exists (D-07 priority) | unit | same | ❌ Wave 0 |
| RATE-05 | Weekend date: actualDate surfaced in RateFetched | unit (MockClient) | exchange_rate_api_client_test.dart | ❌ Wave 0 |
| RATE-06 | Override + date change → ADR-022 D-02 dialog signal emitted | unit | get_exchange_rate_use_case_test.dart | ❌ Wave 0 |
| RATE-06 | No override + date change + >1% delta → ADR-022 D-03 toast signal | unit | same | ❌ Wave 0 |
| RATE-06 | No override + date change + ≤1% delta → no signal emitted | unit | same | ❌ Wave 0 |
| SC-5 | URL privacy: no user data in any constructed URL | unit | exchange_rate_api_client_test.dart | ❌ Wave 0 |
| D-09 | deleteOlderThan called on upsert; rows > 2y removed | unit (in-memory DB) | exchange_rate_cache_service_test.dart | ❌ Wave 0 |
| D-10 | Backup export includes exchange_rates rows | unit | `flutter test test/unit/application/settings/export_backup_use_case_test.dart` | ❌ Wave 0 |
| D-10 | Backup import restores exchange_rates rows via upsert | unit | `flutter test test/unit/application/settings/import_backup_use_case_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/infrastructure/exchange_rate/ test/unit/application/currency/`
- **Per wave merge:** `flutter test` (full suite, must maintain 2635+ green)
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`

### Wave 0 Gaps

All Phase 41 test files are new (no prior existence):

- [ ] `test/unit/infrastructure/exchange_rate/exchange_rate_api_client_test.dart` — covers RATE-01, RATE-05, URL privacy (SC-5)
- [ ] `test/unit/infrastructure/exchange_rate/exchange_rate_cache_service_test.dart` — covers RATE-02, RATE-03 (D-06 cooldown), D-09 pruning
- [ ] `test/unit/application/currency/get_exchange_rate_use_case_test.dart` — covers RATE-03 (use case never throws), RATE-04, RATE-06 (ADR-022 D-02/D-03 signals)
- [ ] Extension test coverage in `test/unit/application/settings/export_backup_use_case_test.dart` — covers D-10 export
- [ ] Extension test coverage in `test/unit/application/settings/import_backup_use_case_test.dart` — covers D-10 import

*(Existing test infrastructure: flutter_test, AppDatabase.forTesting(), MockClient from `http/testing.dart` — all available from Phase 40)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Rate APIs require no authentication |
| V3 Session Management | no | No sessions involved |
| V4 Access Control | no | Public APIs, no user-level access control |
| V5 Input Validation | yes | Validate API JSON response before use; `validateAppliedRate()` already in `currency_conversion.dart` |
| V6 Cryptography | partial | exchange_rates table lives inside SQLCipher-encrypted DB (inherited) |
| V9 Communications | yes | HTTPS only for both APIs; no user data in URLs |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| User data leakage via API URL | Information Disclosure | URL contains only date (YYYY-MM-DD) + ISO currency code; never amount, user ID, book ID. Enforced by architecture test asserting URL contains no user-derived strings. [VERIFIED: PITFALLS.md §Security Mistakes] |
| Plain-text rate cache outside encrypted DB | Information Disclosure | exchange_rates table is inside the SQLCipher AppDatabase (DECIDED in SUMMARY.md; SharedPreferences explicitly rejected) [VERIFIED: SUMMARY.md §Conflict] |
| Logging raw API URL in release builds | Information Disclosure | Log only `[RateCache] USD rate fetched` without date in release mode; guard with `kDebugMode` check [VERIFIED: PITFALLS.md §Security Mistakes] |
| Silent ¥0 transaction from null rate | Tampering | Domain invariant (partial-triple check in CreateTransactionUseCase) prevents null `appliedRate` save; `RateResult.unavailable` forces explicit manual path [VERIFIED: Phase 40 VERIFICATION SC-5] |

---

## Sources

### Primary (HIGH confidence — live-verified or direct codebase inspection 2026-06-12)

- `lib/features/currency/domain/models/exchange_rate.dart` — ExchangeRate model fields, rate as String (ADR-020 compliant)
- `lib/features/currency/domain/repositories/exchange_rate_repository.dart` — current interface (3 methods; no deleteOlderThan yet)
- `lib/data/tables/exchange_rates_table.dart` — TextColumn rate (ADR-020 compliant), UtcEpochDateTimeConverter, composite PK
- `lib/data/daos/exchange_rate_dao.dart` — findByDate/findLatest/upsert; no source filter; no delete method
- `lib/data/repositories/exchange_rate_repository_impl.dart` — _normalizeToUtcMidnight pattern
- `lib/application/currency/repository_providers.dart` — Riverpod provider wiring; `app` prefix convention
- `lib/shared/utils/currency_conversion.dart` — convertToJpy, validateAppliedRate, subunitToUnitFor
- `lib/infrastructure/sync/relay_api_client.dart` — injectable http.Client constructor pattern
- `lib/application/settings/export_backup_use_case.dart` — backup structure; no exchange_rates yet
- `lib/features/settings/domain/models/backup_data.dart` — @freezed model; no exchangeRates field yet
- `docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md` — TextColumn decision, validateAppliedRate rules
- `docs/arch/03-adr/ADR-022_Edit_Semantics.md` — D-01 JPY read-only, D-02 dialog, D-03 toast, isManualOverride flag
- `.planning/phases/40-data-foundation-domain-sync/40-VERIFICATION.md` — Phase 40 test suite 2635/2635 green; all SC verified
- `.planning/research/STACK.md` — dual-source API strategy, live-verified API responses
- `.planning/research/PITFALLS.md` — Pitfall 5 (API gaps), Pitfall 6 (offline-first), security mistakes
- `.planning/research/SUMMARY.md` — Drift table wins over SharedPreferences (conflict resolution)
- `https://api.frankfurter.dev/v1/2026-06-11?from=JPY&to=USD` — live-verified 2026-06-12: `{"amount":1.0,"base":"JPY","date":"2026-06-11","rates":{"USD":0.00623}}`
- `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-06-12/v1/currencies/jpy.min.json` — live-verified 2026-06-12: `twd` key present
- `https://2026-06-12.currency-api.pages.dev/v1/currencies/jpy.min.json` — live-verified 2026-06-12: Cloudflare fallback working, `twd` confirmed
- `https://pub.dev/api/packages/connectivity_plus` — version 7.1.1; deps confirmed clean (no intl, no sqlite3)

### Secondary (MEDIUM confidence)

- `connectivity_plus` pub.dev documentation — API shape (`checkConnectivity()` returning `List<ConnectivityResult>`) assumed stable from v6+ [ASSUMED A2]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages live-verified on pub.dev; both APIs live-tested via curl
- Architecture: HIGH — all conclusions from Phase 40 code inspection; new files mirror established patterns
- Pitfalls: HIGH — most confirmed from direct Phase 40 code inspection + ADR review
- Validation plan: HIGH — test patterns established in Phase 40; file paths follow project conventions

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 (stable stack; re-verify fawazahmed0 CDN URL before implementation as per STATE.md flag)
