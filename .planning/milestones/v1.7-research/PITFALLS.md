# Pitfalls Research

**Domain:** Adding multi-currency support to an existing single-currency (JPY integer) accounting app
**App:** Home Pocket (まもる家計簿) — v1.7 多币种支持
**Researched:** 2026-06-12
**Confidence:** HIGH (based on direct codebase inspection + domain reasoning)

---

## Critical Pitfalls

### Pitfall 1: Float Arithmetic for Money and Rate Precision

**What goes wrong:**

Using `double` for either the original foreign-currency amount or the exchange rate causes rounding drift that makes the displayed conversion preview differ from the stored converted JPY amount. For example, `149.99 USD × 157.3421` computed as a double produces `23600.4857...`; displayed as `¥23,600` but stored as `¥23,601` (or vice versa) depending on when rounding is applied.

The hash chain in this app hashes `amount` as a `double` already:
```dart
// HashChainService.calculateTransactionHash
final hashAmount = params.amount.toDouble();
```
If the displayed preview rounds differently from what gets stored and then hashed, the chain hash will be based on a different integer than the user saw confirmed — a subtle integrity gap.

**Why it happens:**

Developers naively use `double * double` and then call `.round()` at display time vs. store time independently. The rounding policy is left implicit, causing non-reproducibility: `(149.99 * 157.3421).round()` can differ from `(149.99 * 157.3421).ceil()`, and from `(original_amount_cents / 100 * rate).round()`.

Exchange rates need 4–6 decimal places (e.g. 157.3421 JPY/USD). If stored as `double`, precision loss accumulates when rates are retrieved and re-multiplied.

**How to avoid:**

- Store the original amount in minor units where possible (e.g. cents for USD, but JPY has no minor units). For currencies with decimal places, store as an integer of minor units (e.g. `14999` for USD 149.99) or use a dedicated `Decimal`/string field.
- Store the exchange rate as a `String` or fixed-precision integer (e.g. rate multiplied by 1,000,000 to preserve 6 decimal places). Never store rate as a raw `double` field in the Drift table.
- Define ONE canonical rounding function (round-half-up for JPY per ISO 4217 — JPY has exponent 0, no sub-unit) used at both the preview calculation site and the persistence site. The function must be identical in both places — extract it to a shared utility.
- The conversion formula must be: `convertedJpy = (originalMinorUnits / 10^decimals * rate).roundToInt()` using integer arithmetic as far as possible.
- Write a unit test asserting: `preview_amount == stored_amount` for at least 10 representative edge cases (amounts ending in .5 after rate multiplication, very small amounts, very large amounts).

**Warning signs:**

- Any `double * double` in the rate conversion path not immediately followed by `.round()` from the shared utility.
- `convertedJpy` computed separately in the UI widget vs. in the use case.
- `NumberFormatter.formatCurrency` producing a value that doesn't match what was passed to `CreateTransactionParams.amount`.

**Phase to address:** Data + Domain foundation phase (same phase that defines the new Drift columns and `CreateTransactionParams` extension). The shared rounding utility must exist before any UI preview code is written.

---

### Pitfall 2: CNY/JPY Symbol Collision (¥ Ambiguity) — CRITICAL for This App

**What goes wrong:**

Both CNY (Chinese Yuan) and JPY (Japanese Yen) use the `¥` symbol (U+00A5). In a zh/ja bilingual app where users transact in both currencies, displaying `¥1,235` is ambiguous — it could mean 1,235 yen (worthless for CNY conversion) or 1,235 yuan (approximately ¥25,000 JPY).

The existing `NumberFormatter._getCurrencySymbol` already has this bug:
```dart
case 'JPY':
case 'CNY':
  return '¥';  // BOTH return the same ¥ symbol
```

The existing `AmountDisplay` golden tests confirm `¥` is shown for CNY with the same symbol as JPY (the test at line 108–121 uses `currencySymbol: '¥'` for CNY). Once users can enter CNY amounts, a list row showing `¥1,235 (¥150)` is unreadable — both ¥ characters refer to different currencies.

**Why it happens:**

CNY and JPY both technically use `¥` in Unicode. Developers copy-paste or use `NumberFormat.currency(symbol: _getCurrencySymbol('CNY'))` without knowing the collision. The bug already exists in the codebase but is harmless today because users can only input JPY — it becomes a user-visible defect the moment CNY is supported.

**How to avoid:**

Use disambiguated symbols:
- JPY: `¥` (bare ¥, understood by Japanese users in ja-locale context)
- CNY: `CN¥` or `人民币` or `元` (never bare `¥` when displayed alongside JPY amounts)
- The CLDR-recommended disambiguation: `JP¥` for JPY and `CN¥` for CNY when locale context is ambiguous

For this app specifically:
1. Fix `NumberFormatter._getCurrencySymbol` to return `'CN¥'` for CNY (not `'¥'`).
2. In list rows showing `(originalAmount originalCurrency)`, always use the ISO 4217 code as a suffix when the currency might be confused: `¥1,235 (CN¥850.00)` or `¥1,235 (850.00元)`.
3. The golden tests for `amount_display_cny` will need re-baselining once this is fixed — do it intentionally, not accidentally.
4. Add a lint/architecture test: `grep -rn "_getCurrencySymbol" lib/ | grep CNY` must not return `¥`.

**Warning signs:**

- Any test or golden that shows `¥` for CNY without a qualifying suffix.
- `_getCurrencySymbol('CNY')` returning `'¥'` (already present in the codebase).
- UI mockup showing `(¥850)` as the foreign-currency annotation for a CNY transaction.

**Phase to address:** Data + Domain foundation phase, before any UI work. The `NumberFormatter` fix is a one-liner but it changes goldens — do it first so golden re-baseline is a known-deliberate change.

---

### Pitfall 3: Storing Converted Amount Only (Losing Auditability)

**What goes wrong:**

The booking amount (JPY integer in the `amount` column) is what analytics, sorting, and list totals use. If only the JPY amount is stored and the original currency/amount/rate are not, users cannot:
- Verify the conversion was correct after the fact.
- Re-derive the JPY amount if the stored rate is later found to be wrong.
- Display "USD 49.99" in the detail screen alongside "¥7,845".
- Correct a wrong rate (edit flow requires knowing what the original was).

Conversely, storing only the original foreign amount (and no JPY) would break every existing analytics use case since they all `SUM(amount)` and `ORDER BY amount` in JPY.

**Why it happens:**

"We already have an `amount` column — just store the result" is the path of least resistance. The extra three columns (`originalCurrency`, `originalAmount`, `exchangeRate`) feel like metadata overhead. Developers defer the decision, then realize at the edit screen that the original data is gone.

**How to avoid:**

The v1.7 spec already calls for storing both. The implementation must enforce it at the model level:
- `CreateTransactionParams` gets three new optional fields: `originalCurrency String?`, `originalAmount int?` (in minor units), `exchangeRate String?` (stored as string to preserve precision).
- A domain invariant: if any of the three is non-null, all three must be non-null. Enforce this in `CreateTransactionUseCase` as a `Result.error` if the set is partial.
- The Drift table migration (v20→v21) adds three nullable columns. Nullable is correct — existing JPY transactions have no original currency.
- The `Transaction` Freezed model gains three nullable fields.
- `HashChainService.calculateTransactionHash` hashes only `amount` (the JPY integer) — the original currency fields are NOT part of the hash formula. See Pitfall 7 for hash chain implications.

**Warning signs:**

- `CreateTransactionParams` accepting `originalCurrency` without `originalAmount` (partial state).
- `Transaction.originalCurrency != null && Transaction.originalAmount == null` passing domain validation.
- The edit screen reading `transaction.amount` and showing it as the "original amount" (confusing JPY booking with foreign original).

**Phase to address:** Data + Domain foundation phase. The invariant check in `CreateTransactionUseCase` must be in the first phase — it cannot be patched in later without a data migration for partially-stored rows.

---

### Pitfall 4: Edit Semantics Traps (Stale Rate on Amount Edit / Date Change)

**What goes wrong:**

Three distinct trap cases when a saved transaction is edited:

**Case A — User edits original foreign amount, rate is stale:** If the user opens a transaction recorded yesterday (USD 50.00 at 157.34 = ¥7,867) and changes the amount to USD 60.00, the app might silently recalculate with yesterday's cached rate (157.34 → ¥9,440) rather than today's rate. Whether to use "rate at transaction date" or "rate at edit time" must be a deliberate policy decision, documented in the ADR, and implemented consistently.

**Case B — User edits the converted JPY amount directly:** If the UI allows direct editing of the `¥7,867` field for a foreign-currency transaction, the original amount and rate are now inconsistent with the stored JPY. Either: (a) disallow direct JPY editing when `originalCurrency != null`, or (b) clear `originalCurrency`/`originalAmount`/`exchangeRate` when the user overrides JPY (treat it as a manual JPY entry). If neither is enforced, the stored triple (`originalCurrency`, `originalAmount`, `exchangeRate`) will be wrong, and the detail screen will show contradictory data.

**Case C — Date change silently re-fetches rate and changes the saved amount:** If the user changes the transaction date (e.g. to record a purchase from yesterday), the app fetches the rate for the new date and recomputes the JPY amount. The user entered USD 50.00 expecting ¥7,867, but after changing the date to last Tuesday the app silently books ¥7,912. This surprises users and causes financial discrepancies.

**Why it happens:**

Edit flows are written after create flows, often by reusing the same `TransactionDetailsForm`. The form doesn't distinguish "rate is live-fetched" from "rate was locked at creation time." The date picker is wired to re-fetch rates for UX responsiveness, without a confirmation step for the amount impact.

**How to avoid:**

- Define the policy explicitly in an ADR decision before implementation:
  - "Rate at transaction date" policy: the edit flow re-fetches the rate for the (potentially changed) transaction date, shows a diff `¥7,867 → ¥7,912`, and asks the user to confirm before saving.
  - "Rate is locked at creation" policy: editing the original amount re-multiplies with the locked rate; editing the date does NOT re-fetch.
  - Recommendation: "Rate at transaction date" with explicit confirmation toast/dialog when date changes cause a JPY amount change greater than 1%.
- The `TransactionDetailsForm` needs a `currencyMode` state that tracks whether the current transaction is a foreign-currency transaction and whether the JPY amount was manually overridden.
- Direct JPY editing for foreign-currency transactions should be allowed only after explicit "override conversion" confirmation, which clears the original-currency metadata.
- `UpdateTransactionUseCase` must receive the original three fields explicitly and not re-derive them from the `amount` column.

**Warning signs:**

- The edit form computing JPY from `originalAmount × rate` inside `build()` (every rebuild recomputes, unstable).
- `onDateChanged` wired to call the rate API without a pending-save flag.
- `UpdateTransactionUseCase` accepting `amount` only and ignoring `originalAmount`/`exchangeRate`.
- No test asserting that editing original amount × stale rate differs from editing original amount × correct rate.

**Phase to address:** Application use cases phase (same phase that implements `UpdateTransactionUseCase` extension and the exchange-rate service). The policy decision should be in the ADR before code is written.

---

### Pitfall 5: Free API Gaps — Weekends, Holidays, Currency Coverage, and Silent Deprecation

**What goes wrong:**

Free exchange rate APIs (e.g. Frankfurter, exchangerate.host, Open Exchange Rates free tier) have well-known gaps:

- **No rate on weekends/holidays:** FX markets close. The ECB reference rates are published on business days only. A transaction dated Saturday 2026-06-13 has no ECB rate. Without a fallback strategy, the rate lookup returns 404/empty and the app either crashes or saves ¥0.
- **Currency coverage gaps:** ECB covers approximately 30 currencies. TWD (New Taiwan Dollar) and KRW (South Korean Won) are NOT in the ECB dataset. If the app advertises TWD/KRW support via the ISO 4217 list but the API doesn't cover them, the rate lookup silently fails.
- **Silent API deprecation:** `exchangerate.host` changed its free tier policy in 2023 to require API keys. `api.frankfurter.app` is maintained but is a single-maintainer open-source project. APIs at this tier can change base URLs, authentication requirements, or response schemas without notice.
- **API response schema drift:** The rate key in the response (`"USD"` vs `"rates.USD"` vs `"data.USD"`) can change between API versions. If the parser assumes a fixed schema and the API changes, the app silently stores ¥0.

**Why it happens:**

Developers test with "today's" rate during development (business days), never test weekend dates, and assume the ISO 4217 currency list maps 1:1 to API coverage.

**How to avoid:**

- **Weekend/holiday fallback:** When a rate lookup for date D returns no data, walk backward up to 4 calendar days to find the most recent business day's rate. Cache this fallback rate tagged with the original requested date AND the actual rate date. Display to the user: "汇率来自 2026-06-12（最近交易日）" so they know it's a proxy rate.
- **Currency allowlist:** Maintain an explicit `SupportedCurrencies` class that lists only currencies covered by the chosen API, distinct from the full ISO 4217 list. The "more currencies" picker shows only supported currencies, not raw ISO 4217.
- **API abstraction layer:** Define an `ExchangeRateRepository` interface at the domain layer. The initial implementation hits Frankfurter. Future implementations can swap to another API without touching business logic. The interface contract: `Future<Rate?> getRateForDate(String fromCurrency, String toCurrency, DateTime date)`.
- **Schema change defense:** Parse the API response strictly — if the expected key is absent, return `null` (rate unavailable) rather than `0` or throw. Log the raw response in debug mode for diagnosability.
- **API health smoke test:** Add a canary test that hits the live API in CI (marked `@Tags(['network'])`, skipped offline) asserting USD/JPY for a known past date returns a value in a plausible range (100–200).

**Warning signs:**

- Rate lookup code directly returns `0.0` on HTTP 404 instead of `null`.
- `SupportedCurrencies.all` equals `iso4217.allCurrencies` (using unfiltered ISO list).
- No test for "Saturday date" lookup.
- `http.get('https://api.frankfurter.app/...')` without an abstraction layer.

**Phase to address:** Exchange rate service phase. The abstraction layer and fallback logic must be built before the UI is wired — UI tests will mock the repository, but the real implementation needs the fallback tested separately.

---

### Pitfall 6: Offline-First Traps — Blocking Save and Race Conditions

**What goes wrong:**

The app is explicitly local-first. Two failure modes:

**Mode A — Blocking save on network:** If `CreateTransactionUseCase` awaits the exchange-rate API call before inserting into the database, the user cannot save a transaction while offline. The existing use case pattern (`CreateTransactionUseCase.execute`) is entirely local/synchronous for all existing fields. Adding a network dependency into the critical path breaks this invariant.

**Mode B — Save-then-backfill race condition:** If the save happens first (with rate = null, then the app tries to backfill the rate later), a crash between save and backfill leaves a transaction with `originalCurrency = 'USD'` but `exchangeRate = null` and `amount = 0`. The analytics SUM query will include a ¥0 transaction. The hash chain will be computed over `amount=0`, which is incorrect.

**Why it happens:**

"Optimistic save then fill in the rate" is a natural pattern, but it requires the rate backfill to be atomic with the hash chain recomputation — which is complex. "Wait for rate then save" is simpler but breaks offline-first.

**How to avoid:**

- The correct architecture: rate lookup is a pre-save step, not a post-save backfill.
- If offline or rate unavailable: save with `exchangeRate` = the last cached rate (even if stale), `originalCurrency`/`originalAmount`/`exchangeRate` are all set. The JPY amount is computed from the stale rate. The user is shown a warning: "汇率来自缓存（2026-06-10），请在联网后手动核查。"
- Manual rate override is always available as the offline fallback — the UI must offer a "手动输入汇率" field that is pre-populated from the cache and editable.
- NEVER leave `exchangeRate = null` after save for a foreign-currency transaction. The domain invariant (Pitfall 3) — if `originalCurrency` is set, all three fields must be non-null — prevents this.
- The rate lookup is async and must happen before `CreateTransactionUseCase.execute` is called. The calling provider/screen is responsible for resolving the rate (with fallback to cache/manual) before calling the use case.

**Warning signs:**

- `CreateTransactionUseCase` contains an `http.get` or `ExchangeRateRepository` call.
- `Transaction` inserted with `amount = 0` because rate was null.
- No test for "network unavailable, user enters foreign currency amount."

**Phase to address:** Exchange rate service phase. The offline fallback path must be tested before the UI is built. The "manual rate override" UI is required for the offline case, not optional.

---

### Pitfall 7: Hash Chain Integrity — New Fields and Migration

**What goes wrong:**

The hash formula is:
```
SHA-256(transactionId|amount|timestamp|previousHash)
```

Two risks when adding new currency fields:

**Risk A — Including new fields in the hash breaks existing chain:** If `originalCurrency` and `originalAmount` are added to the hash formula, then all existing transactions in the chain — which have `null` for these fields — will fail verification because their stored `currentHash` was computed with a different formula.

**Risk B — Not including new fields means they are unprotected:** A malicious actor could change `originalCurrency = 'USD'` and `originalAmount = 50` on a JPY transaction (setting false "foreign origin" metadata) and the hash chain would not detect it, since those fields are outside the hash input.

**Why it happens:**

Developers see "add fields to the hash for integrity" as obviously correct, but fail to think through the migration cost. The opposite decision ("don't add to hash") is also defensible but must be explicit.

**How to avoid:**

- Decision required in the ADR before implementation: explicitly state whether `originalCurrency`/`originalAmount`/`exchangeRate` enter the hash formula.
- **Recommended decision for v1.7:** Do NOT add the new fields to the hash formula. Rationale: (1) migration cost is prohibitive — every existing chain hash would need recomputation, requiring a "re-seal" migration that alters `currentHash` and `prevHash` for every row, invalidating the entire integrity record; (2) the JPY `amount` is the financially material field; the original-currency metadata is audit-support, not the primary record; (3) tamper of metadata fields without changing `amount` changes the display but not the financial integrity.
- Document this decision explicitly: "originalCurrency, originalAmount, exchangeRate are outside the hash boundary. The hash protects financial integrity (JPY amount). Metadata integrity is provided by E2EE transport."
- Add an architecture test asserting that `HashChainService.calculateTransactionHash` does not accept `originalCurrency` or `originalAmount` parameters — prevent accidental scope creep.
- The schema migration v20→v21 adds the three columns as nullable. Existing rows keep their `currentHash` unchanged. Chain verification continues to work on old and new rows without modification.

**Warning signs:**

- `HashChainService.calculateTransactionHash` signature growing to include `originalCurrency`.
- Migration code recomputing `currentHash` for existing rows.
- Chain verification test failing for rows created before v1.7.

**Phase to address:** Data + Domain foundation phase. The hash decision must be in the ADR before writing a single line of the Drift migration. Getting this wrong requires a re-seal migration — high cost.

---

### Pitfall 8: Family Sync Version Skew — Old Device Receives New Fields

**What goes wrong:**

The `TransactionSyncMapper.fromSyncMap` deserialization in `apply_sync_operations_use_case.dart` currently uses `as int? ?? 2` and `as String? ?? 'manual'` patterns for fields added in previous milestones. If a v1.7 device sends a transaction with `originalCurrency: 'USD'` and an older v1.6 device receives it, the `fromSyncMap` will encounter unknown keys. If the new fields are absent on the older device's schema, the insert will fail — either silently (the existing `try/catch` skip-and-continue in `ApplySyncOperationsUseCase`) or with a Drift constraint error.

Conversely, a v1.6 device sending a transaction to a v1.7 device — the v1.7 receiver must handle `originalCurrency = null` gracefully (treat as pure JPY transaction).

**Why it happens:**

Sync mapper `fromSyncMap` uses direct key access (`data['key'] as Type`). Adding a new required-looking field without a default/null guard causes a runtime type cast exception on older sender payloads.

**How to avoid:**

- `TransactionSyncMapper.fromSyncMap` must use null-safe access for all three new fields:
  ```dart
  originalCurrency: data['originalCurrency'] as String?,
  originalAmount: data['originalAmount'] as int?,
  exchangeRate: data['exchangeRate'] as String?,
  ```
- Write a regression test: deserialize a v1.6-style sync payload (no currency fields) into a v1.7 `Transaction` — assert `originalCurrency == null`, `amount` is correct, no exception.
- Write a regression test: deserialize a v1.7 sync payload on the v1.7 `fromSyncMap` — assert all three fields present.
- The three new Drift columns must be `nullable` — `TextColumn get originalCurrency => text().nullable()()`. Never use `NOT NULL` without a DEFAULT for fields added via migration.
- The `TransactionSyncMapper.toSyncMap` must use conditional inclusion for the new fields (same pattern as existing `note`/`merchant`):
  ```dart
  if (transaction.originalCurrency != null) 'originalCurrency': transaction.originalCurrency,
  if (transaction.originalAmount != null) 'originalAmount': transaction.originalAmount,
  if (transaction.exchangeRate != null) 'exchangeRate': transaction.exchangeRate,
  ```

**Warning signs:**

- `data['originalCurrency'] as String` (non-nullable cast) in `fromSyncMap`.
- Integration test for sync round-trip not including a "old-format payload" case.
- Drift migration adding `originalCurrency TEXT NOT NULL` (would fail all v1.6-synced rows).

**Phase to address:** Application use cases + sync phase. The sync mapper tests must include the old-payload regression before the PR lands.

---

### Pitfall 9: i18n Traps — Decimal Separators and Currency Input

**What goes wrong:**

The `SmartKeyboard` currently operates in JPY mode: integer-only, no decimal point used. Adding USD/EUR/CNY requires accepting decimal input. However:

- The existing `onDot` handler in `SmartKeyboard` is already wired but may be no-op for JPY. If it's enabled for all currencies without locale awareness, a German-locale user who expects `,` as decimal separator will get `1.500` instead of `1500`.
- The voice input parser (`VoiceTextParser._extractArabicAmount`) uses regex patterns that may not handle `1,500.00` vs `1.500,00` correctly for all locales. The existing regex assumes `.` as decimal separator.
- `NumberFormat.currency(locale: ...)` in `NumberFormatter.formatCurrency` formats the display correctly per locale, but the input parsing is a separate code path that doesn't use `NumberFormat` — it uses hand-written regex.

**Why it happens:**

Input parsing and output formatting are written by different people at different times. Output formatting uses `intl`'s `NumberFormat` (locale-aware). Input parsing uses hand-written regex (locale-unaware).

**How to avoid:**

- For this app's target locales (ja, zh, en): none of them use `,` as decimal separator. The `.` separator is safe for all three. Document this explicitly as the app's scope — do not add locale-decimal-separator parsing unless a new locale (de, fr) is added.
- The `SmartKeyboard.onDot` must be enabled only when `currencyCode` has `decimalDigits > 0`. JPY has 0 decimal digits — the dot key should remain disabled for JPY (current behavior). USD/EUR/CNY have 2 decimal digits — the dot key must be enabled and the input string capped at 2 decimal places.
- The amount input must track whether a decimal was entered: `'149'`, `'149.'`, `'149.9'`, `'149.99'` — and cap at 2 decimal places.
- The `ParseVoiceInputUseCase` must receive the expected currency context to correctly interpret `150.5ドル` as `150.50 USD` (not `15050 JPY` via the existing integer parser path).
- The conversion to minor units (for storage) must happen after the decimal-aware input is complete: `'149.99'` → `14999` cents.

**Warning signs:**

- `SmartKeyboard` with `onDot` enabled for JPY (existing behavior broken by currency switch).
- `VoiceTextParser.extractAmount` returning `14999` when `'149.99ドル'` is spoken (treating `.` as thousands separator).
- Minor-unit storage of `149` instead of `14999` for `'149.99 USD'` due to premature `int.parse`.

**Phase to address:** UI keypad + voice extension phase.

---

### Pitfall 10: Voice Parsing Ambiguity — Currency Vocabulary Gaps

**What goes wrong:**

The existing `VoiceCurrencySuffixes.all` list contains only JPY-context suffixes: `日元, 块钱, えん, yen, 円, 元, 块, 塊, ドル`. The current zh corpus and ja corpus are entirely JPY-denominated (all test cases end in `元`/`円`).

Adding multi-currency means parsing:
- zh: `五十美元` (50 USD), `一百欧元` (100 EUR), `八十英镑` (80 GBP), `五百港元` (500 HKD)
- ja: `五十ドル` (50 USD), `百ユーロ` (100 EUR), `八十ポンド` (80 GBP)

Ambiguities:
- `元` in zh context means JPY (`日元`) when preceded by a number in a Japanese-app context, but also means CNY (`人民币`/`元`) and is sometimes used loosely for "dollars" by zh speakers. Without currency-intent detection, `五十元` is ambiguous.
- `ドル` already in the suffix list, but the amount parser currently routes to the JA state machine and returns an integer — it doesn't currently output a currency code alongside the amount.
- `円` (JPY) vs `圆` (traditional form of CNY) — same sound, different kanji, OCR/voice confusion possible.

**Why it happens:**

The voice parser was built JPY-first. The `VoiceCurrencySuffixes` class identifies that a suffix was spoken, but the existing contract only returns an `int amount` — no currency is returned alongside. The currency is implicitly JPY.

**How to avoid:**

- The `ParseVoiceInputUseCase` return type must be extended to include `String? detectedCurrency` alongside `int? amount`. This is a contract change — test the existing callers.
- `VoiceCurrencySuffixes.all` must be expanded with foreign-currency suffixes in longest-first order (regex alternation priority):
  - zh additions: `美元, 欧元, 英镑, 港元, 港币, 韩元, 台币, 澳元, 加元`
  - ja additions: `ユーロ, ポンド, 香港ドル, ウォン, 台湾ドル, 豪ドル`
  - English additions: `dollars, euros, pounds, USD, EUR, GBP` (lowercase, for English locale users)
- Ambiguity resolution policy for `元` (zh):
  - If the app UI has a currency selector already set to CNY: interpret `元` as CNY.
  - If app locale is `ja` and currency not explicitly selected: interpret `元` as JPY, not CNY.
  - If app locale is `zh` and currency not explicitly selected: interpret `元` as CNY.
  - Document this in the voice resolver — it's a policy decision, not an inference.
- Add voice corpus test cases for each new currency in each locale (minimum 5 cases per currency per locale before shipping).
- The `holdToRecord` gesture and voice input screen must show the currently selected currency prominently so users can verify intent.

**Warning signs:**

- `ParseVoiceInputUseCase` returning `int? amount` only, no currency output.
- `五十美元` being parsed as `50 JPY` (missing currency detection).
- `VoiceCurrencySuffixes.all` still only containing the v1.3 set when the voice phase lands.
- No zh/ja corpus test cases with foreign currency suffixes.

**Phase to address:** Voice extension phase. This is the most deferred phase and can build on the currency infrastructure from earlier phases — but the `ParseVoiceInputUseCase` contract change must be planned early (it affects callers built in the UI phase).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store `exchangeRate` as `double` in Drift | Simple column type | Precision loss; cannot reproduce exact conversion; audit trail unreliable | Never |
| Skip the `SupportedCurrencies` allowlist, use full ISO 4217 | Less code | TWD/KRW show in picker, rate lookup fails silently at runtime | Never |
| Reuse `¥` symbol for CNY without disambiguation | One less code path | CNY and JPY amounts look identical in zh locale | Never |
| Hash the JPY amount only (not original fields) | No chain migration needed | Original-currency metadata is unprotected from tampering | Acceptable — document it explicitly in ADR |
| Per-day rate cache in SQLite (same encrypted DB) | No new storage mechanism | Cache survives app reinstall if backup is restored; older rates may be years stale | Acceptable — add a cache expiry TTL (e.g. 90 days) |
| Skip re-fetch confirmation on date change | Simpler UX | User surprised when booking amount changes silently | Never for amounts greater than 1% change |
| Use `try/catch` around rate API call with silent ¥0 fallback | No crash | Silent ¥0 transaction in the DB, corrupts analytics | Never — show an error or use cached rate |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Frankfurter API (`api.frankfurter.app`) | Request `latest` endpoint instead of `{date}` endpoint for historical transactions | Use `/{YYYY-MM-DD}?from=USD&to=JPY`; `latest` returns the current rate, not the transaction-date rate |
| Frankfurter API | Request on weekends returns empty `rates` object without HTTP error | Check `rates.isEmpty` explicitly; fallback to prior business day by walking back up to 4 days |
| Frankfurter API | Assume `base: 'EUR'` will always work; request `from=JPY&to=USD` directly | Frankfurter triangulates via EUR internally; the response is correct but the base in the response body is EUR, not JPY — parse `rates[targetCurrency]` only |
| Rate cache | Cache key = currency pair only (USD/JPY) | Cache key must include date: `USD_JPY_2026-06-12` — same pair has different rates on different days |
| Rate cache | Store in SharedPreferences as raw Map | Use Drift table for structured, queryable, TTL-expirable cache — same encrypted DB, no new storage mechanism |
| `NumberFormat.currency` (intl) | Use `symbol: '¥'` for both JPY and CNY | Use `symbol: 'CN¥'` for CNY, `symbol: '¥'` for JPY — `NumberFormat` does not auto-disambiguate |
| Drift v20→v21 migration | `ALTER TABLE` to add `NOT NULL` columns without DEFAULT | SQLite requires `DEFAULT` or `NULL` for new columns; use `text().nullable()()` for all three new columns |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No rate cache — fetches API on every transaction | Lag on every save; offline always fails | Per-day SQLite cache with `DateTime date` + `String currencyPair` primary key | Immediately with any API call |
| Cache lookup on main thread (synchronous Drift read) | UI jank when keypad opens | Rate cache read is `async`; use `FutureProvider` with loading state | Small caches mask this; breaks at approximately 1000 cache entries |
| Analytics SUM including ¥0 rows (failed conversion) | Monthly totals understated | Domain invariant: `amount > 0` enforced by existing `CreateTransactionUseCase` check | Single corrupted row |
| Rebuilding rate every keypad keystroke | Preview lags; redundant API calls | Rate is fetched once per (date, currency) pair and held in provider state; preview is local multiplication | Noticeable after 3+ keystrokes |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Sending transaction amount + timestamp in rate API request URL | Correlates financial data with outbound network requests, violating privacy architecture | Rate API request must be `GET /2026-06-12?from=USD&to=JPY` — date and currency pair only. Never include amount, user ID, book ID, or any user-identifying data |
| Caching raw API response (full JSON with all currency pairs) in plaintext SharedPreferences | Cache persists outside encrypted DB; if device is compromised, reveals which currencies the user accesses | Store rate cache in the existing encrypted SQLite DB (SQLCipher) via a new `exchange_rates_cache` Drift table |
| Logging the full API URL with date as debug output | Date of expensive purchase visible in debug logs | Log only `[RateCache] USD/JPY rate fetched` without date in release builds |
| `exchangeRate` field in sync payload transmits over E2EE but with rate metadata that reveals transaction dates | Acceptable — the sync transport is already E2EE between family members. External relay sees only ciphertext | No change needed; E2EE is already in place per the existing sync architecture |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual distinction between ¥ (JPY) and ¥ (CNY) in list rows | zh users think they overspent; amounts look larger than reality | Always append currency code when a foreign-currency annotation appears: `¥7,867 (CN¥350.00)` |
| Showing rate with too many decimals (e.g. `1 USD = 157.342156 JPY`) | Confusing; users think they need to type precision | Display rate to 2 decimal places in UI (`157.34`); store full precision internally (6 dp as string) |
| Rate refresh spinner blocking the entire save button | User cannot save if rate fetch is slow | Rate is loaded in background when currency is selected; save button is enabled immediately with last-cached rate; spinner is informational only |
| Currency selector buried in "More" menu only | Power users with regular USD expenses cannot switch quickly | Common currencies (USD, EUR, CNY, HKD, KRW) are visible as chips in the keypad row; "More" for the long tail |
| Edit screen hiding original currency info | User cannot verify whether the rate was correct | Transaction detail screen and edit screen always show `originalCurrency`, `originalAmount`, `exchangeRate` when non-null, in a distinct currency-info section |

---

## "Looks Done But Isn't" Checklist

- [ ] **Rate precision:** `exchangeRate` stored as `String` (not `double`) in Drift — verify `transactions_table.dart` schema.
- [ ] **CNY symbol:** `NumberFormatter._getCurrencySymbol('CNY')` returns `'CN¥'`, not `'¥'` — verify by grep.
- [ ] **Domain invariant:** `CreateTransactionUseCase` returns `Result.error` if exactly one of `(originalCurrency, originalAmount, exchangeRate)` is non-null — verify unit test.
- [ ] **Hash chain unaffected:** Running `HashChainService.verifyChain` on a mixed v20/v21 dataset (old JPY rows + new foreign-currency rows) returns valid — verify integration test.
- [ ] **Sync backward compatibility:** `TransactionSyncMapper.fromSyncMap` handles a v1.6-format payload (missing currency fields) without throwing — verify regression test.
- [ ] **Offline save:** Saving a foreign-currency transaction with airplane mode ON uses cached rate and completes without error — verify test with mocked repository returning null from API.
- [ ] **Weekend rate:** Rate lookup for a Saturday date falls back to Friday's rate — verify unit test with a known Saturday date.
- [ ] **Voice currency detection:** `ParseVoiceInputUseCase` returns `detectedCurrency: 'USD'` for `五十美元` — verify corpus test.
- [ ] **Golden re-baseline:** All 133 golden tests pass after the `NumberFormatter` CNY symbol fix — verify that only CNY-specific goldens changed.
- [ ] **Analytics unaffected:** `SUM(amount)` on transactions including foreign-currency rows (which have JPY in `amount`) produces the same result as before — verify existing analytics use case tests still pass.
- [ ] **JPY keyboard unchanged:** `SmartKeyboard` with `currencyCode: 'JPY'` still has `onDot` non-functional — verify golden and widget test.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Float precision used for rate — wrong booking amounts stored | HIGH | Write a one-time migration use case that re-reads `originalAmount`/`exchangeRate` (as string) and recomputes `amount`; recompute hash chain; require user confirmation |
| CNY symbol not disambiguated — users confused | LOW | Fix `NumberFormatter`, re-baseline CNY-specific goldens, release patch |
| Hash chain broken by adding new fields to hash formula | HIGH | Write "re-seal" migration that recomputes `currentHash`/`prevHash` for entire chain using original formula; notify users chain was reset |
| Sync backward-compat broken — old device crashes receiving new transactions | MEDIUM | Release emergency patch with null-safe `fromSyncMap`; affected transactions can be re-synced in next full sync |
| Rate cache stored in plaintext SharedPreferences | MEDIUM | Migrate cache to encrypted Drift table; clear old SharedPreferences cache |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Float arithmetic / rate precision | Phase 1: Data + Domain | Unit test: preview_amount == stored_amount for 10 edge cases |
| CNY/JPY symbol collision | Phase 1: Data + Domain | `NumberFormatter` unit test; CNY golden re-baseline |
| Storing only one side (not both + rate) | Phase 1: Data + Domain | Domain invariant test in `CreateTransactionUseCase` |
| Edit semantics (stale rate, date change) | Phase 2: Application use cases | `UpdateTransactionUseCase` tests for all three edit-mode cases |
| Free API gaps (weekends, coverage, deprecation) | Phase 2: Exchange rate service | Rate service tests with mocked API for weekend date, empty response, absent currency |
| Offline-first (blocking save, race) | Phase 2: Exchange rate service | Integration test with mocked network-unavailable repository |
| Hash chain integrity | Phase 1: Data + Domain (ADR decision) | `verifyChain` test on mixed v20/v21 dataset |
| Family sync version skew | Phase 3: Sync extension | Regression test: v1.6-format payload into v1.7 `fromSyncMap` |
| i18n decimal separator / input | Phase 4: UI + Keypad | `SmartKeyboard` widget tests for JPY (no dot) vs USD (dot enabled, capped 2dp) |
| Voice ambiguity / currency vocabulary | Phase 5: Voice extension | Corpus test for each new currency in zh and ja |

---

## Sources

- `/Users/xinz/Development/home-pocket-app/lib/infrastructure/crypto/services/hash_chain_service.dart` — confirms hash formula inputs (transactionId, amount, timestamp, previousHash only)
- `/Users/xinz/Development/home-pocket-app/lib/data/tables/transactions_table.dart` — confirms schema v20, integer `amount` column
- `/Users/xinz/Development/home-pocket-app/lib/infrastructure/i18n/formatters/number_formatter.dart` — confirms CNY/JPY symbol collision bug at `_getCurrencySymbol`
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/models/transaction_sync_mapper.dart` — confirms sync payload structure and null-safe fallback pattern
- `/Users/xinz/Development/home-pocket-app/lib/application/accounting/create_transaction_use_case.dart` — confirms hash computation is over JPY `amount.toDouble()` only
- `/Users/xinz/Development/home-pocket-app/lib/shared/constants/voice_currency_suffixes.dart` — confirms current voice suffix set is JPY-only (8 tokens)
- `/Users/xinz/Development/home-pocket-app/lib/application/family_sync/apply_sync_operations_use_case.dart` — confirms skip-and-continue fault isolation pattern for unknown sync ops
- `/Users/xinz/Development/home-pocket-app/test/golden/amount_display_golden_test.dart` — confirms 133 existing goldens include CNY tests using same `¥` symbol as JPY
- ISO 4217 standard: JPY exponent=0 (no subunit), CNY exponent=2, USD exponent=2
- ECB currency coverage: TWD and KRW not in ECB/Frankfurter dataset
- CLDR disambiguation: `JP¥`/`CN¥` are canonical narrow symbols for disambiguation

---
*Pitfalls research for: multi-currency support on existing JPY-integer accounting app (Home Pocket v1.7)*
*Researched: 2026-06-12*
