# Feature Research

**Domain:** Multi-currency transaction entry for local-first family accounting app (v1.7)
**Researched:** 2026-06-12
**Confidence:** HIGH (core UX patterns, API behavior, rounding rules), MEDIUM (app-specific implementation details from competitors)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any multi-currency accounting app. Missing these makes the feature feel unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Currency selector adjacent to amount | Every reference app (Toshl, Spendee, 随手记, 钱迹) places a tappable currency code/symbol directly next to the numeric input. Users expect to tap the code to switch — not navigate away | LOW | Tap currency code → bottom sheet or inline dropdown; must not require leaving the entry screen. SmartKeyboard already occupies the bottom; selector sits above the numpad |
| Recently/commonly used currencies at top | Toshl shows 5 most-recently-used. Spendee and 随手记 both promote frequent currencies. Travelers transact in the same 2–3 foreign currencies repeatedly | LOW | 4–6 pinned entries before the full ISO list; JPY always pinned as home currency first; remaining slots = most-recently-used |
| Full searchable ISO 4217 currency list behind "more" | All reference apps provide 160+ currency coverage with search. A short "frequent" list alone is insufficient | LOW | ISO 4217 alphabetical list with 3-letter code + currency name; text search filters by name or code in real time |
| Live conversion preview below amount | Toshl explicitly shows the converted home-currency value below the entry field as user types. Spendee shows dual-currency on saved transactions. Users need "how much is this in yen" before saving | MEDIUM | Reactive to keypad input and date changes; uses cached rate; shows "取得中…" spinner while fetching; no action required from user |
| Auto-fetch rate by transaction date | Toshl uses historical rates back to 1999; Lunch Money stores the historic rate per transaction. Users expect "the rate that day" not "today's rate" | MEDIUM | Frankfurter API: `GET /v1/{YYYY-MM-DD}?from={CURRENCY}&to=JPY` — free, no API key, ECB-sourced |
| Manual rate override | Toshl (delete-and-retype), Spendee (popup before save), 钱迹, 随手记 all support per-transaction rate override. Users with actual bank/card rates want to record the real rate | LOW | Editable rate field on the entry screen; recalculates JPY preview immediately on change |
| Offline / stale-rate graceful degradation | Rate fetch fails without network. Users must still be able to record the transaction | MEDIUM | Use last cached rate; show staleness date inline (e.g. "前回取得: 2026-06-10"); manual override always available as escape hatch |
| Storage of original currency + original amount + applied rate | All reference apps (Toshl, Spendee, Lunch Money, 钱迹) preserve original amount and rate per transaction. Users expect to see "I paid $50 at ¥156.30/USD" in the detail/edit view | MEDIUM | Three new nullable columns on `transactions`; Drift schema migration v20→v21 |
| JPY-converted amount drives all lists and analytics | 随手記, Toshl, Lunch Money all aggregate in home currency. Users cannot compare daily spending across currencies without a single unit | LOW | Existing `amount` INTEGER column in JPY remains the single source for sorting, summing, and analytics. No change to analytics layer |
| Foreign amount annotation in list rows | Toshl and Spendee both show the original currency/amount as secondary text on foreign-currency rows. Users want to recall "that was $50" without opening detail view | LOW | Small secondary text on `ListTransactionTile` for non-JPY rows only; e.g. "USD 50.00"; domestic rows unchanged |
| Full original-currency info in detail/edit | Spendee, 钱迹, and Toshl all display original amount + rate in the edit view. Users editing foreign transactions expect to see the complete record | MEDIUM | Edit screen: originalCurrency, originalAmount, appliedRate fields visible; originalAmount and appliedRate re-editable; jpyAmount shown as derived/read-only |
| JPY integer rounding (no decimals) | JPY has 0 decimal digits per ISO 4217. All enterprise systems (NetSuite, Zuora, PeopleSoft) floor/round to integer. Users tracking in Japan expect whole-yen amounts | LOW | `(originalAmount * appliedRate).round()` — Dart `round()` is HALF_UP for positive values; result stored as INTEGER; fractional yen never displayed anywhere |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Date-aware historical rate (not just today's rate) | Most consumer apps (Spendee: "updated every 24 hours" = always today; 随手记: real-time-only) use today's rate regardless of transaction date, creating retroactive drift on past records. Fetching the actual ECB rate for the entered date makes the record permanently accurate | MEDIUM | Frankfurter `/v1/{date}` endpoint; re-fetch triggered automatically when user changes transaction date while in foreign-currency mode; cache keyed `(date, currencyCode)` |
| Transparent weekend/holiday fallback with date label | Frankfurter silently returns the last ECB business day's rate for weekend/holiday dates. Most apps give no indication. Showing "レート: 2026-06-09 (直近の取引日)" makes the fallback explicit and trustworthy | LOW | Parse `date` field from Frankfurter JSON response; if `responseDate != requestedDate`, show inline note in muted secondary text. Low cost; high trust signal |
| Voice currency words zh/ja | No competitor accounting app has voice input at all. Extending the existing zh/ja voice parser to understand 「50ドル」/「五十美元」is a unique capability reinforcing the app's voice-first positioning | MEDIUM | Zh: 美元/欧元/英镑/港币/澳元/加元; Ja: ドル/ユーロ/ポンド/香港ドル/豪ドル → ISO codes; amount parse logic unchanged; currency word resolved as a token before the amount state machine runs |
| Per-day local rate cache | No consumer app explicitly advertises per-day caching with transparent staleness. Enables full offline use after the first fetch per (date, currency) pair; avoids redundant API calls when family members enter multiple transactions on the same trip date | MEDIUM | New Drift table: `exchange_rate_cache(date TEXT, currency_code TEXT, rate REAL, fetched_at INTEGER)`; past dates have permanent TTL (ECB never revises historical rates); today's rate has 1-hour TTL |
| Active-currency persistence within session | Toshl's documented behavior: the currency selected for one entry becomes the suggested default for the next entry in the same session. Eliminates re-selecting "USD" for the 5th time on a travel expense session | LOW | Riverpod ephemeral provider holds last-used foreign currency; resets to JPY on app restart; no disk persistence needed in MVP |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Shopping list `estimatedPrice` multi-currency | Users may want to estimate items in foreign currency | Shopping list has no SmartKeyboard and no amount-entry flow; adding multi-currency to it is a separate feature with separate scope; high implementation cost for marginal use | Explicitly out of v1.7 scope. Carry as SHOP-CURRENCY-V2 |
| Live intraday exchange rates | "The rate at the moment of purchase" | ECB publishes once per business day at ~16:00 CET. No free real-time source with adequate precision and no API key. Card-network rates are proprietary and inaccessible | Per-day historical rate matches how banks actually post transactions. Correct granularity for accounting |
| Retroactive mass rate-update on all historical transactions | "Revalue everything with today's rate" or "update all USD transactions to match my statement" | Destroys hash-chain integrity; makes analytics non-reproducible; a single re-rate could silently alter months of JPY totals | Allow per-transaction rate override only; each transaction stores its own locked rate |
| Per-user "home currency" different from JPY | "I think in USD, not JPY" | Requires rewriting analytics, summaries, and comparisons — an architectural rewrite, not an increment | Provide original-amount annotation on every foreign row so non-JPY thinkers see their reference number |
| Automatic currency detection from voice alone | "I said 50 dollars, detect USD" | "Dollar" is ambiguous (US/AU/CA/HK). Resolving ambiguity requires a disambiguation prompt, adding friction for the 95%+ JPY-only case | Map explicit currency words to ISO codes; 美元 → USD unambiguous; ドル → USD as default (most common for Japan-based users); show currency selector for user to confirm/change |
| Real-time conversion widget on home screen | "Show me how much my USD balance is in JPY" | Always-on network dependency on the home screen; distracts from the app's kakeibo philosophy; no concept of "USD balance" in this app (single JPY account) | Conversion preview appears only during foreign-currency entry, on demand |
| Three-field bidirectional linked editing in MVP | "Let me type the JPY amount and back-calculate the rate" | Bidirectional binding creates circular update risk on MVP; requires careful input-focus state management to avoid infinite recalculation | MVP: one-way (originalAmount × appliedRate → jpyAmount). Bidirectional promoted to P2 differentiator for post-validation |

---

## Feature Dependencies

```
[Currency selector on SmartKeyboard]
    └──requires──> [ISO currency list + recently-used store (ephemeral Riverpod)]
    └──requires──> [Bottom sheet / inline dropdown widget]

[Auto rate fetch by transaction date]
    └──requires──> [Frankfurter HTTP client (http package, already in pubspec)]
    └──requires──> [exchange_rate_cache Drift table (v20→v21 migration)]
    └──requires──> [Transaction date field (already exists)]

[Live conversion preview]
    └──requires──> [Auto rate fetch by transaction date]
    └──requires──> [Currency selector on SmartKeyboard]

[Manual rate override]
    └──enhances──> [Auto rate fetch by transaction date]
    └──requires──> [Live conversion preview] (override replaces fetched rate in same UI panel)

[Drift schema migration v20→v21]
    └──creates──> [transactions.originalCurrency TEXT nullable]
    └──creates──> [transactions.originalAmount REAL nullable]
    └──creates──> [transactions.appliedRate REAL nullable]
    └──creates──> [exchange_rate_cache table]

[Family sync transparent passthrough]
    └──requires──> [Drift schema migration v20→v21]
    └──extends──> [TransactionSyncMapper (existing)] with 3 new nullable fields

[Foreign amount annotation in list row]
    └──requires──> [transactions.originalCurrency + originalAmount columns]
    └──extends──> [ListTransactionTile (existing v1.4)]

[Detail/edit: full original info]
    └──requires──> [transactions.originalCurrency + originalAmount + appliedRate columns]
    └──extends──> [TransactionDetailsForm (existing v1.3)]

[Weekend/holiday date label]
    └──requires──> [Auto rate fetch — parse responseDate from Frankfurter JSON]
    └──enhances──> [Live conversion preview] (adds date note below rate field)

[Voice currency words zh/ja]
    └──requires──> [ISO code mapping dictionary (new, small)]
    └──extends──> [Existing zh/ja voice parsers (lib/infrastructure/voice/, v1.3)]
    └──sets──> [Currency selector active currency after parse]

[Active-currency persistence in session]
    └──requires──> [Currency selector on SmartKeyboard]
    └──implemented via──> [Ephemeral Riverpod provider — no disk persistence needed]
```

### Dependency Notes

- **Both schema changes land in one migration**: The `exchange_rate_cache` table and the three new nullable columns on `transactions` must be in the same Drift schema migration (v20→v21). Splitting them would require two sequential schema bumps with no benefit.
- **Family sync passthrough requires no new protocol**: The three new nullable fields on `transactions` are plain nullable columns. The existing `TransactionSyncMapper` serializes all non-ignored fields; adding the three fields is a low-risk extension.
- **Voice currency resolution does not depend on rate fetch**: The voice parser maps a currency word to an ISO code. Rate fetch is triggered separately when the entry form initializes with that currency code.
- **SmartKeyboard is the entry-point gate for all paths**: Manual entry, voice prefill (post-parse), and edit-from-list all converge at `TransactionDetailsForm`, which hosts SmartKeyboard. The currency selector on SmartKeyboard is therefore naturally available in all three paths.
- **JPY-as-active-currency = domestic mode**: When JPY is selected (the default), no currency selector indicator is shown, no rate fetch occurs, no preview panel is shown, and no annotation appears on the list row. Domestic UX is unchanged.

---

## MVP Definition

### Launch With (v1.7)

Minimum feature set for a complete, coherent multi-currency entry experience.

- [ ] **Currency selector on SmartKeyboard** — 4–6 common currencies pinned (JPY, USD, EUR, CNY, HKD, GBP) + "more" → full searchable ISO list; active currency persists within session
- [ ] **Auto rate fetch by transaction date** — Frankfurter API, per-day local Drift cache; weekend/holiday → last ECB business day with inline date note
- [ ] **Live conversion preview** — JPY result displayed below foreign amount field in real time; shows "取得中…" spinner during fetch; updates when date changes
- [ ] **Manual rate override** — editable rate field inline; recalculates preview immediately; user's manual rate takes precedence over fetched rate
- [ ] **Offline fallback** — use last cached rate; show "前回取得: YYYY-MM-DD" staleness label; manual override always available as escape hatch
- [ ] **Drift schema v20→v21** — `originalCurrency TEXT`, `originalAmount REAL`, `appliedRate REAL` nullable on `transactions`; `exchange_rate_cache` table
- [ ] **JPY rounding** — `(originalAmount * appliedRate).round()` integer; no fractional yen stored or displayed anywhere
- [ ] **Foreign annotation in list row** — secondary text "USD 50.00" beneath JPY amount on `ListTransactionTile` for non-JPY rows; domestic rows unchanged
- [ ] **Detail/edit: full original info** — `TransactionDetailsForm` shows originalCurrency, originalAmount, appliedRate for foreign transactions; originalAmount and appliedRate re-editable; jpyAmount shown as derived display
- [ ] **Family sync passthrough** — three new nullable fields serialized/deserialized transparently in existing `TransactionSyncMapper`
- [ ] **Voice currency words zh/ja** — 美元/欧元/英镑/港币/澳元/加元 (zh) and ドル/ユーロ/ポンド/香港ドル/豪ドル (ja) → ISO codes; existing amount state machines unchanged

### Add After Validation (v1.x)

- [ ] **Three-field linked editing** — in edit view, editing jpyAmount back-calculates appliedRate; bidirectional binding. Valuable for credit-card-statement reconcilers; validate basic flow works first
- [ ] **"Remember this rate" option** — Spendee's approach: per-transaction rate remembered for next time; useful for users with fixed exchange relationships
- [ ] **English voice currency words** — extend VOICE-EN-V2-01 when it ships

### Future Consideration (v2+)

- [ ] **Shopping list estimated price in foreign currency** — needs SmartKeyboard on shopping form first (SHOP-CURRENCY-V2)
- [ ] **Per-user foreign currency preference default** — family member Alice always defaults to USD; needs multi-profile settings
- [ ] **Self-hosted Frankfurter instance** — if API availability becomes a concern; Frankfurter is open source and self-hostable

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Currency selector (common + full search) | HIGH | LOW | P1 |
| Auto rate fetch by transaction date | HIGH | MEDIUM | P1 |
| Live conversion preview | HIGH | MEDIUM | P1 |
| Drift schema migration + sync passthrough | HIGH (prerequisite) | MEDIUM | P1 |
| JPY integer rounding | HIGH (correctness) | LOW | P1 |
| Offline fallback + staleness label | HIGH | MEDIUM | P1 |
| Manual rate override | HIGH | LOW | P1 |
| Foreign annotation in list row | MEDIUM | LOW | P1 |
| Detail/edit: full original info | MEDIUM | MEDIUM | P1 |
| Voice currency words zh/ja | MEDIUM | MEDIUM | P1 |
| Weekend/holiday date label on preview | MEDIUM | LOW | P1 (piggybacks on rate fetch) |
| Active-currency session persistence | MEDIUM | LOW | P1 |
| Three-field linked editing | MEDIUM | HIGH | P2 |
| "Remember this rate" option | LOW | LOW | P2 |
| Shopping list multi-currency | LOW | HIGH | P3 |

---

## Competitor Feature Analysis

| Feature | Toshl | Spendee | 随手记/钱迹 | Home Pocket v1.7 |
|---------|-------|---------|------------|-----------------|
| Currency selector location | Adjacent to amount, tap to expand | Adjacent to amount, triggers popup | Per-account setting; inline per entry | Adjacent to amount on SmartKeyboard |
| Recently used currencies | Top 5 in list | Not documented | Recent list | Top 4–6 pinned + JPY; full ISO searchable |
| Rate source | ECB-based, refreshed hourly | "Updated every 24 hours" | Real-time (unspecified provider) | Frankfurter (ECB), per-day Drift cache |
| Historical rate by transaction date | YES — back to 1999 | NO — today's rate only | Unclear | YES — Frankfurter `/v1/{date}` |
| Weekend/holiday fallback behavior | Silent (returns nearest date) | Not documented | Not documented | Explicit: shows actual rate date inline |
| Manual rate override | YES — edit rate field, 3-field linked | YES — popup before save | YES | YES — inline edit on entry + edit screens |
| Offline behavior | Not documented | Not documented | Not documented | Last cached rate; staleness date label; override available |
| Conversion preview during entry | YES — shown below amount as user types | YES — dual currency on saved view | Unclear | YES — live below foreign amount field |
| List annotation of foreign rows | Not documented | YES — shows both currencies on tile | Unclear | Small secondary text "CURR amount" on tile |
| JPY rounding | Standard integer | Standard integer | Standard integer | `.round()` to integer |
| Voice input | NO | NO | NO | YES — zh/ja currency words (unique) |
| Active-currency session memory | YES — becomes default for next entry | YES — "remember this rate" option | Unclear | YES — ephemeral Riverpod provider |

---

## Edge Cases and Behavioral Contracts

### Currency Selection State Machine

**Default on fresh open:** JPY (home). No currency UI shown; numpad behaves as before.
**After selecting a foreign currency:** it becomes the active currency for subsequent entries this session (Toshl pattern). Subsequent entries open with that currency pre-selected.
**Switching back to JPY:** removes conversion preview panel; rate fetch not triggered.
**Cross-session:** last non-JPY currency is retained in the "recently used" list but JPY remains the initial default on fresh app open.

### Rate Fetch Trigger Points

1. User selects a foreign currency for the first time in the entry screen.
2. User changes the transaction date while a foreign currency is active.
3. User edits an existing foreign transaction (fetch triggered on screen open if no cached rate exists for that `(date, currencyCode)` pair).

If `(date, currencyCode)` is already in cache within TTL → use cache immediately (no spinner).

TTL rules: past dates → permanent (ECB rates are immutable historical data). Today's date → 1 hour.

### Weekend / Holiday Rate Gap

**Contract:** Frankfurter returns the last ECB business day's rate when the requested date is a weekend or an ECB closing day. The response JSON's `date` field will contain the actual rate date, which will differ from the requested date.

**UX rule:** When `responseDate != requestedDate`, display beneath the rate field in small muted text:
- ja: `レート: {responseDate}（直近の取引日）`
- zh: `汇率: {responseDate}（最近交易日）`
- en: `Rate: {responseDate} (latest trading day)`

This is informational, not a warning. ECB behavior is correct.

**Japan-specific note:** Japanese national holidays are NOT ECB holidays. Frankfurter will publish a rate on Japanese national holidays that fall on a weekday. No special handling needed for Japanese calendar.

**ECB holidays:** New Year's Day, Good Friday, Easter Monday, Labour Day (May 1), Christmas Day (Dec 25–26). Rare edge case; transparent fallback is sufficient.

### Offline Behavior

**No network, no cache:** Rate field empty; conversion preview shows "—"; an inline prompt appears: "汇率未取得 — 手动输入" with the rate field focused. Transaction cannot be saved without either a fetched rate or a manually entered rate. The user is never blocked: they can always type the rate they saw on another app.

**Cache exists but stale (past TTL):** Use the cached rate. Show `"前回取得: {cachedDate}"` as secondary text below the rate field. Manual override available.

**No network, previous fetch available for same (date, currency):** Use cache silently. No indicator needed (rate for a past date is immutable; staleness is irrelevant).

### Editing Existing Foreign Transactions

**Editable fields:**
- `originalAmount` — YES; user may have mis-typed
- `appliedRate` — YES; user may want to match the credit card statement rate
- `originalCurrency` — YES (currency selector in edit mode); changing currency triggers a new rate fetch for the stored transaction date
- Transaction `date` — changing it triggers a rate re-fetch; preview updates; user must save to lock in the new derived jpyAmount

**Derived display (not directly editable in MVP):**
- `jpyAmount` (the stored `amount` INTEGER) — shown as a read-only derived display: "≈ ¥7,815". Recalculated on save from `round(originalAmount * appliedRate)`.

**On save:** `amount = round(originalAmount * appliedRate)`. This is the only integer stored. Analytics, sorting, and list totals continue to use `amount` unchanged.

### Rounding Contract

`jpyAmount = (originalAmount * appliedRate).round()`

Dart's `double.round()` is HALF_UP for positive values (rounds 0.5 up). Example: 50 USD × 156.305 = 7815.25 → stored as ¥7815.

`appliedRate` is stored as REAL (64-bit double) at full precision. Display in UI: 4 significant decimal places (e.g. "156.3050").

### JPY Selected as Foreign Currency

If the user explicitly selects JPY (correcting a wrong currency): `originalCurrency = "JPY"`, `originalAmount = amount (REAL, same value)`, `appliedRate = 1.0`. Row is treated as domestic (no annotation in list).

### Voice Currency Word Resolution

**Ambiguous cases:**
- ドル (ja) → USD (default; most common in Japan context). User sees currency selector pre-filled with USD; can change before saving.
- "Dollar" in English voice (future) → USD default; same logic.
- 澳元 (zh) / 豪ドル (ja) → AUD (unambiguous)
- 港币 (zh) / 香港ドル (ja) → HKD (unambiguous)
- 人民币/元 (zh) — interpreted as CNY only in multi-currency context; in JPY-only mode (current parser), 元 already maps to a JPY amount. When multi-currency is active: if a currency word precedes/follows the amount, treat as CNY; otherwise retain existing JPY parse.

Voice sets the active currency on the entry form. Rate fetch is triggered after the form loads with that currency.

---

## Sources

- Toshl Finance currency UX (iOS): https://toshl.com/blog/currencies-in-toshl-finance-ounces-of-gold-welcome-ios/ — HIGH confidence
- Spendee help center exchange rate: https://help.spendee.com/article/231-how-to-setchange-the-currency-and-exchange-rate — HIGH confidence
- 钱迹 multi-currency guide: https://docs.qianjiapp.com/multiple_currency.html — MEDIUM confidence
- V2EX multi-currency design discussion: https://v2ex.com/t/1172725 — MEDIUM confidence
- Frankfurter API v1 docs: https://frankfurter.dev/v1/ — HIGH confidence
- Frankfurter weekend/holiday behavior (last business day): search-verified across multiple sources — HIGH confidence
- money2 Dart package (integer minor units, ISO 4217, JPY zero-decimal): https://pub.dev/packages/money2 — HIGH confidence
- ISO 4217 zero-decimal currencies (JPY, KRW, VND): https://en.wikipedia.org/wiki/ISO_4217 — HIGH confidence
- JPY rounding in enterprise systems (NetSuite, Zuora, PeopleSoft): multiple search-verified sources — HIGH confidence
- YNAB multi-currency guide: https://support.ynab.com/en_us/using-multiple-currencies-in-ynab-a-guide-SyBF6PHno — MEDIUM confidence
- Toshl currency feature overview: https://toshl.com/currencies/ — HIGH confidence

---

*Feature research for: Multi-currency transaction entry (Home Pocket v1.7)*
*Researched: 2026-06-12*
