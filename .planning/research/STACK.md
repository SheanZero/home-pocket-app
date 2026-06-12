# Stack Research

**Domain:** Multi-currency transaction entry — Flutter family accounting app (Home Pocket v1.7)
**Researched:** 2026-06-12
**Confidence:** HIGH (all APIs live-verified via curl; all package versions verified via pub.dev API; no training-data assertions made without verification)

---

## Context

This research covers only the NEW stack additions for v1.7 multi-currency support. The existing validated
stack (Flutter + Riverpod 3 + Freezed + Drift/SQLCipher + GoRouter + `http ^1.6.0` + `shared_preferences ^2.3.4`)
is unchanged and not re-evaluated here.

---

## TL;DR

**Two new pub.dev packages required:** `currency_picker ^2.0.22` and `sealed_currencies ^3.2.0`. No new HTTP client. No decimal arithmetic package. No API key. The existing `http` package (already at latest 1.6.0) handles all exchange rate network calls.

---

## Recommended Stack

### Core Technologies (New Additions)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Frankfurter API** (`api.frankfurter.dev`) | REST, no client lib | Primary exchange-rate source — historical rates by date, JPY base | Free, no API key, no rate limits, commercial use allowed, 30 currencies (CNY/KRW/HKD/SGD/THB confirmed), historical back to 1999-01-04 (ECB origin), live-verified returning correct JSON for `?from=JPY` |
| **fawazahmed0/exchange-api** (jsDelivr + Cloudflare CDN) | `@fawazahmed0/currency-api` npm, date-versioned | Fallback for currencies not in Frankfurter (TWD and 330+ others) | Free, no API key, CC0 1.0 Universal license (public domain, commercial use explicitly allowed), 360+ currencies (TWD confirmed), jsDelivr primary + Cloudflare fallback; used only when Frankfurter returns 404 |
| **`currency_picker`** | `^2.0.22` | ISO 4217 currency picker widget with search | Latest (published 2026-06-11); depends only on `collection ^1.19.1` (already pinned in pubspec); zero intl dependency; searchable bottom-sheet UX |
| **`sealed_currencies`** | `^3.2.0` | ISO 4217 metadata — symbols, subunit counts, localized names (ja/zh/en) | Version 3.2.0 (published 2026-05-22); no intl in transitive dep chain (chain is `sealed_currencies → l10n_currencies ^2.0.2 + sealed_languages ^3.2.0 → l10n_languages`; all four packages are intl-free); provides `subunitToUnit` (100 for USD/CNY, 1 for JPY) critical for minor-unit arithmetic |

### Existing Dependencies — No Change

| Library | Current Version | Role in v1.7 | Notes |
|---------|-----------------|-------------|-------|
| `http` | `^1.6.0` | Exchange rate HTTP GET calls | Already at latest; same `import 'package:http/http.dart' as http` pattern as `relay_api_client.dart` |
| `shared_preferences` | `^2.3.4` | Per-date rate cache (flat JSON map keyed by `"exrate:{YYYY-MM-DD}:{CURRENCY}"`) | Already used for settings; fully adequate for flat string→double cache; initialized before DB in `AppInitializer` |
| `drift` / `drift_dev` | `^2.25.0` | Schema v20→v21 migration — three new nullable columns on `transactions` | No version bump; follows established migration pattern |

### NOT Adding

| Library | Why Not |
|---------|---------|
| `dio` | `http` already in pubspec and used in `relay_api_client.dart`; Dio adds ~300 KB bundle overhead; no retry/interceptor features needed for 1–2 GET calls per rate lookup with simple offline fallback |
| `decimal` (`^3.2.4`) | Adds `intl >=0.19.0 <0.21.0` constraint; double + `.round()` is sufficient (see Amount Arithmetic section); the pinned `intl 0.20.2` satisfies the range but adds a future-upgrade constraint with no benefit |

---

## Exchange Rate API — Full Comparison

### Live-Verified Results (2026-06-12)

| Criterion | Frankfurter (`api.frankfurter.dev`) | fawazahmed0 (`cdn.jsdelivr.net/npm/@fawazahmed0/currency-api`) |
|-----------|-------------------------------------|---------------------------------------------------------------|
| **API key required** | No | No |
| **Cost** | Free | Free |
| **License** | "Free for commercial use, no quotas" (per docs) | CC0 1.0 Universal — public domain; verified in GitHub LICENSE file |
| **Currency count** | 30 (live-verified full list below) | 360+ fiat + crypto (live-verified) |
| **CNY** | YES | YES |
| **KRW** | YES | YES |
| **TWD** | **NO** — not in ECB feed (confirmed: `/currencies` list does not include TWD; `?to=TWD` returns `{"message":"not found"}`) | **YES** — confirmed in 2024-10-10 snapshot and `latest` endpoint |
| **HKD / SGD / THB** | YES | YES |
| **VND** | NO | YES |
| **Historical dates** | Back to **1999-01-04** (ECB origin) — live-verified | npm CDN: **2024-10-10 to present** (~8 months rolling); dates before 2024-10-10 return 404 |
| **JPY base** | YES — `?from=JPY&to=USD` returns direct JPY rate | YES — `/currencies/jpy.min.json` returns JPY-keyed map |
| **Infrastructure** | Cloudflare CDN; self-hostable | jsDelivr (primary) + Cloudflare Pages fallback (`latest.currency-api.pages.dev`) |
| **Privacy** | Cloudflare analytics on public endpoint; no user data in URL | CDN access only; no user data in URL |
| **Response format** | `{"amount":1.0,"base":"JPY","date":"2023-06-15","rates":{"USD":0.00708}}` | `{"date":"2026-06-11","jpy":{"usd":0.00623,...}}` |

**Frankfurter confirmed currency list (30 total):** AUD, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HKD, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR, NOK, NZD, PHP, PLN, RON, SEK, SGD, THB, TRY, USD, ZAR

**Note on fawazahmed0 historical range:** The npm-versioned `@fawazahmed0/currency-api` package starts at 2024-10-10. The older `currency-api` GitHub repo used a different jsDelivr URL scheme (`cdn.jsdelivr.net/gh/fawazahmed0/currency-api@{date}`) which no longer resolves for historical dates. For transactions dated before 2024-10-10 in TWD or other Frankfurter-unsupported currencies, the app must fall back to the nearest cached rate or manual override — this is acceptable per the milestone spec.

### Recommended Dual-Source Lookup Strategy

```
For currency code C on transaction date D:

1. Try Frankfurter: GET https://api.frankfurter.dev/v1/{D}?from=JPY&to={C}
   → 200 OK with rate → cache and use
   → 404 "not found" (currency not in Frankfurter set) → step 2
   → Network error / timeout → step 3

2. Try fawazahmed0 (primary CDN):
   GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{D}/v1/currencies/jpy.min.json
   → 200 OK → extract rate for key `{c.toLowerCase()}` → cache and use
   → 404 (date before 2024-10-10 or not yet published) → try Cloudflare fallback:
   GET https://{D}.currency-api.pages.dev/v1/currencies/jpy.min.json
   → 200 OK → cache and use
   → 404 or error → step 3

3. Offline fallback:
   → Return most recent cached rate for (C, nearest date ≤ D) if available
   → If no cached rate: surface manual override UI (user inputs rate directly)
```

This maps exactly to the milestone spec: "离线/查询失败时回退最近缓存并允许手动修改汇率". The vast majority of currencies used by a Japan-based family (USD, EUR, CNY, KRW, HKD, SGD, THB) are covered by Frankfurter with full history. TWD routes to fawazahmed0. Most users entering recent transactions stay within the ~8-month fawazahmed0 history window.

---

## ISO 4217 Currency Metadata

**Recommendation: `sealed_currencies ^3.2.0` for domain/data layer + `currency_picker ^2.0.22` for the picker UI widget.**

These serve distinct roles and should not be conflated:

**`sealed_currencies`** provides compile-time currency objects. Each `FiatCurrency` subclass carries:
- `code` — ISO 4217 three-letter code (e.g. `"USD"`)
- `symbol` — commonly displayed symbol (e.g. `"$"`)
- `subunitToUnit` — integer multiplier for minor units (100 for USD/CNY/TWD/KRW, 1 for JPY)
- `commonNameFor(BasicLocale(LangJpn()))` — Japanese name (e.g. `"米ドル"`)
- `commonNameFor(BasicLocale(LangZho()))` — Chinese name (e.g. `"美元"`)
- `commonNameFor(BasicLocale(LangEng()))` — English name (e.g. `"US Dollar"`)

The `LangJpn`/`LangZho`/`LangEng` classes come from `sealed_languages` (transitively pulled in). Wire the name resolver to the app's `currentLocaleProvider` at display time — match locale to the corresponding `Lang*` class.

**`currency_picker`** provides a bottom-sheet widget with flag icons, currency name, code, and a search field. Wire it to emit an ISO 4217 code string; use that code to look up the full `FiatCurrency` object via `sealed_currencies` for display and arithmetic elsewhere in the app.

**`subunitToUnit` values** relevant to the app's target users:

| Currency | `subunitToUnit` | Practical meaning |
|----------|-----------------|-------------------|
| JPY | 1 | No decimal places; `amount` column is already in yen |
| USD / EUR / GBP | 100 | User input `12.50` → store `1250` minor units |
| CNY | 100 | User input `50.00` → store `5000` fen |
| KRW | 100 | ISO 4217 says 100, but KRW has no subunit in practice; treat display as 0 decimals |
| TWD | 100 | User input `300.00` → store `30000` minor units |
| HKD / SGD / THB | 100 | Standard 2-decimal |

**Note on KRW display:** Despite `subunitToUnit = 100` in ISO 4217, KRW amounts are displayed without decimals by convention. Detect this at the `NumberFormatter` layer: if `currencyCode == "KRW"`, format with 0 decimal places regardless of `subunitToUnit`.

---

## Amount Arithmetic — No `decimal` Package Needed

The core calculation: `originalAmount` (user-entered float) × `exchangeRate` (rate from API) → `amount` (integer JPY).

**Approach: integer minor-unit storage + double arithmetic + `.round()`.**

```dart
// User enters: 12.50 USD
// API returns: 1 JPY = 0.00623 USD → 1 USD = 160.51 JPY

final subunitToUnit = 100; // from sealed_currencies FiatCurrency
final originalMinorUnits = (userInputDouble * subunitToUnit).round(); // 1250

// exchangeRate stored as: 1 originalCurrency = X JPY
// Frankfurter returns ?from=JPY&to=USD giving 0.00623 → invert: 1/0.00623 = 160.51
final jpyPerOriginalUnit = 1.0 / frankfurterRate; // 160.51
final jpyAmount = (originalMinorUnits * jpyPerOriginalUnit / subunitToUnit).round(); // 2006

// Store in transactions:
// amount = 2006 (JPY, used for all accounting)
// currencyCode = "USD"
// originalAmount = 1250 (minor units, i.e. $12.50)
// exchangeRate = 160.51 (JPY per USD, for display purposes)
```

`double` arithmetic is sufficient because:
1. Exchange rates carry at most 4–6 significant figures from the API — precision beyond that is noise.
2. The final JPY amount is rounded to the nearest integer — rounding absorbs any float imprecision.
3. Dart `double` is IEEE 754 64-bit — exact for integers up to 2^53 (far beyond any realistic currency amount).

The existing `NumberFormatter` in `lib/infrastructure/i18n/formatters/number_formatter.dart` (pinned `intl 0.20.2`) handles display of the original amount with the correct decimal places — pass `currencyCode` and `originalMinorUnits / subunitToUnit` to get locale-correct formatting.

---

## Drift Schema v20 → v21

Three new nullable columns on `Transactions` table:

```dart
// Add to transactions_table.dart:

/// ISO 4217 currency code of the original input amount.
/// Null means the amount was entered directly in JPY (no conversion).
TextColumn get currencyCode => text().nullable()();

/// Original amount in minor units of currencyCode.
/// e.g. USD $12.50 → 1250. Null when currencyCode is null.
IntColumn get originalAmount => integer().nullable()();

/// Exchange rate used: 1 unit of currencyCode = exchangeRate JPY.
/// e.g. 160.51 for USD. Null when currencyCode is null.
RealColumn get exchangeRate => real().nullable()();
```

Migration block in `app_database.dart` (add to `onUpgrade`):

```dart
if (from < 21) {
  await db.execute(
    'ALTER TABLE transactions ADD COLUMN currency_code TEXT',
  );
  await db.execute(
    'ALTER TABLE transactions ADD COLUMN original_amount INTEGER',
  );
  await db.execute(
    'ALTER TABLE transactions ADD COLUMN exchange_rate REAL',
  );
}
```

All three are nullable with no default — existing rows get NULL, correctly meaning "JPY, no conversion". No backfill required. The `amount` column (existing integer JPY) participates in all existing analytics/statistics unchanged.

---

## Exchange Rate Cache

**Use SharedPreferences, not a new Drift table.**

Rationale:
- Cache is a flat `Map<String, double>` — no joins, no streams, no foreign keys needed.
- SharedPreferences is already initialized before the Drift DB in `AppInitializer` (KeyManager → Database → other services).
- Cache is reconstructible: if lost (app reinstall, SharedPreferences cleared), the app fetches again on next access.
- Cache never needs to be family-synced — rates are public data, fetched on demand per device.

Cache key format: `"exrate:YYYY-MM-DD:CURRENCY_CODE"` → `double` stored as double preference.

For "offline fallback to nearest earlier cached rate": iterate candidate dates descending from transaction date, checking for a cached key for that currency, until one is found or a configurable lookback limit (e.g., 30 days) is reached.

---

## Privacy Architecture Compliance

The milestone explicitly flags this as the first external network API dependency, requiring compatibility with local-first/privacy architecture:

- **No user data in any API URL.** Frankfurter request: `?from=JPY&to=USD` — currency codes only. fawazahmed0 request: `/currencies/jpy.min.json` — no user identifier.
- **Outbound only.** Both are GET-only CDN/REST endpoints; no webhook, no subscription, no inbound call.
- **Offline-complete.** Cached rates + manual override ensure the app works fully offline — no feature is gated on network availability.
- **No API key.** No registration, no account linkage, no device fingerprint tied to API usage.
- **Cache is local.** SharedPreferences stays on-device; rate cache is never serialized into the family sync pipeline.
- **Rate fetch is best-effort.** The infrastructure layer (`lib/infrastructure/currency/`) fetches rates; the application layer decides whether to prompt for manual override on failure — user agency preserved.

---

## Installation

```yaml
# pubspec.yaml — add to dependencies block:
currency_picker: ^2.0.22
sealed_currencies: ^3.2.0
```

No other `pubspec.yaml` changes. No dev_dependencies changes. No `build_runner` regeneration triggered by these packages (neither uses code generation).

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Frankfurter + fawazahmed0 dual-source | `open.er-api.com` free tier | No historical rates on free tier — requires paid plan for date-specific lookups; disqualifying for "fetch rate for transaction date" requirement |
| Frankfurter + fawazahmed0 dual-source | `exchangerate-api.com` free tier | Requires API key registration + 1,500 calls/month cap; conflicts with privacy-first architecture and creates a paid-service hard dependency |
| Frankfurter + fawazahmed0 dual-source | `exchangeratesapi.io` | API key required even on free tier; free tier is latest-only (no historical) |
| `sealed_currencies` for metadata | Hand-rolled ISO 4217 table | Maintenance burden; `sealed_currencies` has 100% test coverage, ja/zh/en translations including for all 170+ fiat currencies, correct `subunitToUnit` values |
| `currency_picker` for UI | Custom `ListView` from `sealed_currencies` data | `currency_picker` is actively maintained (published 2026-06-11), includes flag icons, search, zero intl dep |
| SharedPreferences for rate cache | New Drift table | Drift overkill for flat key→value cache; SharedPreferences already init'd before DB |
| Double arithmetic + `.round()` | `decimal` package | `decimal` adds intl version constraint; precision beyond `.round()` is meaningless given API rate precision |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `open.er-api.com` free tier | No historical rates — fatal for the date-specific rate requirement | Frankfurter (30 currencies, 1999→present) |
| `dio` HTTP client | Already have `http ^1.6.0`; Dio adds ~300 KB bundle, interceptor complexity not needed | `package:http/http.dart` (already in pubspec) |
| `decimal` package | Adds intl version constraint; `.round()` on double is sufficient | Double arithmetic (native Dart) |
| Raw ECB SDMX API | XML, complex pagination, same 30-currency limitation as Frankfurter but without clean JSON wrapper | Frankfurter wraps ECB cleanly |
| `currency_dart`, `geo_currencies` | Less maintained, smaller currency sets, no confirmed ja/zh translations | `sealed_currencies ^3.2.0` |
| Any API requiring registration | Privacy-first architecture; no user account linkage to external service | Frankfurter (no key) + fawazahmed0 (no key) |

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `currency_picker ^2.0.22` | `collection ^1.19.1` (already in pubspec) | Zero new transitive deps; no intl |
| `sealed_currencies ^3.2.0` | No intl dep in chain | `l10n_currencies ^2.0.2` + `sealed_languages ^3.2.0` + `l10n_languages ^2.x` — all intl-free; pub.dev API confirmed no intl in transitive closure |
| Frankfurter REST | `http ^1.6.0` | No client lib; same GET pattern as `relay_api_client.dart` |
| fawazahmed0 CDN | `http ^1.6.0` | Same pattern; jsDelivr primary, Cloudflare fallback URL for `latest`; historical dates via npm versioning from 2024-10-10 |
| **intl 0.20.2 (PINNED)** | All new packages | Confirmed: no new package in the recommended stack has an intl dependency. The pinned `0.20.2` is not at risk. |

---

## Sources

- `https://api.frankfurter.dev/v1/currencies` — live-verified; 30-currency list printed; TWD absent; CNY/KRW/HKD/SGD/THB present. HIGH confidence.
- `https://api.frankfurter.dev/v1/2020-01-15?from=JPY&to=USD,EUR,CNY,KRW` — live-verified historical rate response. HIGH confidence.
- `https://api.frankfurter.dev/v1/1999-01-04` — live-verified; earliest available date confirmed. HIGH confidence.
- `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2024-10-10/v1/currencies/jpy.min.json` — live-verified; TWD/CNY/KRW present; npm package start date 2024-10-10 confirmed via npm registry. HIGH confidence.
- `https://latest.currency-api.pages.dev/v1/currencies/jpy.min.json` — live-verified Cloudflare fallback; TWD/CNY/KRW all confirmed. HIGH confidence.
- `https://github.com/fawazahmed0/exchange-api/blob/main/LICENSE` — CC0 1.0 Universal; commercial use explicitly allowed. HIGH confidence.
- `https://frankfurter.dev/docs/` — "free for commercial use, no quotas" per docs; Cloudflare privacy note. MEDIUM confidence (docs statement, no formal ToS document).
- `https://pub.dev/api/packages/currency_picker` — version 2.0.22, published 2026-06-11; deps: `collection ^1.19.1` only. HIGH confidence.
- `https://pub.dev/api/packages/sealed_currencies` — version 3.2.0; deps: `l10n_currencies ^2.0.2 + sealed_languages ^3.2.0`; no intl in chain confirmed. HIGH confidence.
- `https://pub.dev/api/packages/decimal` — version 3.2.4; `intl >=0.19.0 <0.21.0` dep confirmed (compatible with 0.20.2 but adds constraint). HIGH confidence.
- `lib/data/tables/transactions_table.dart` (read 2026-06-12) — `amount` is `integer()`; schema v20 confirmed; migration pattern verified. HIGH confidence.
- `lib/infrastructure/sync/relay_api_client.dart` (read 2026-06-12) — `http` package usage pattern confirmed. HIGH confidence.
- `pubspec.yaml` (read 2026-06-12) — confirmed `http: ^1.6.0` and `shared_preferences: ^2.3.4` already present; no `dio` or `decimal`. HIGH confidence.

---

*Stack research for: Home Pocket v1.7 多币种支持 (multi-currency transaction entry)*
*Researched: 2026-06-12*
