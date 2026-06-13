# Requirements: Home Pocket v1.7 多币种支持 (Multi-Currency)

**Defined:** 2026-06-12
**Core Value:** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations

## v1.7 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### 币种选择 (Currency Selection)

- [ ] **CURR-01**: User can tap a currency symbol/code adjacent to the amount on the entry keypad (SmartKeyboard) to open the currency selector — without leaving the entry screen
- [ ] **CURR-02**: Currency selector pins common currencies at top (JPY always first; USD/EUR/CNY/HKD/GBP, dynamically re-ordered by recent use) with a "more" affordance expanding the full ISO 4217 list with real-time search by code or name
- [ ] **CURR-03**: Last-used foreign currency is remembered within the app session as the suggested default for the next entry; resets to JPY on app restart
- [ ] **CURR-04**: When JPY is active (default), entry UX is unchanged — no rate fetch, no preview panel, no list annotation (domestic mode untouched)
- [ ] **CURR-05**: Foreign-currency amount entry supports decimal input per the currency's ISO 4217 minor unit (e.g. USD 50.50; JPY/KRW remain 0-decimal)

### 汇率 (Exchange Rate)

- [x] **RATE-01**: On foreign-currency entry, the app automatically fetches the exchange rate for the TRANSACTION DATE (historical rate, not today's) from a free no-key API (Frankfurter primary, fawazahmed0 fallback for uncovered currencies)
- [x] **RATE-02**: Fetched rates are cached locally per (date, currency) pair; repeat entries on the same date/currency hit the cache with zero network calls; historical rates are permanent (never revised), today's rate has a short TTL
- [x] **RATE-03**: When offline or the fetch fails, the app falls back to the most recent cached rate for that currency and shows the rate's actual date as a staleness indicator; saving is never blocked on network
- [x] **RATE-04**: User can manually override the rate on the entry/edit form; the JPY preview recalculates immediately
- [x] **RATE-05**: When the API returns a different date than requested (weekend/holiday — ECB publishes business days only), the actual rate date is shown inline (e.g. 「レート: 06-09 (直近の営業日)」)
- [x] **RATE-06**: Changing the transaction date on a foreign-currency entry re-fetches the rate for the new date and recalculates the JPY amount (manual-override rates are preserved, not clobbered)

### 存储与转换 (Storage & Conversion)

- [x] **STORE-01**: Foreign-currency transactions store the JPY-converted amount in the existing `amount` column (drives ALL lists/analytics/sorting unchanged) plus three new nullable fields: original currency code, original amount (minor units), applied conversion rate — Drift schema v20→v21; NULL fields = native-JPY row
- [x] **STORE-02**: JPY conversion follows the integer contract: `(originalAmount × appliedRate).round()` — fractional yen never stored or displayed anywhere
- [x] **STORE-03**: The three new fields transit family sync null-safely in both directions — older-format payloads (fields absent) apply cleanly as JPY rows; new-format payloads round-trip losslessly
- [x] **STORE-04**: Hash-chain scope decision recorded as an ADR before migration work: new currency fields are excluded from the transaction hash (existing chains stay valid); rationale documented
- [x] **STORE-05**: CNY and JPY currency symbols are disambiguated in NumberFormatter (both currently render `¥` — pre-existing bug); foreign-currency amounts display with unambiguous symbols/codes across all locales

### 展示 (Display)

- [ ] **DISP-01**: During foreign-currency entry, a live JPY conversion preview appears below the amount, reacting to keypad input, currency change, rate change, and date change; shows a loading state while fetching
- [ ] **DISP-02**: Foreign-currency rows in the transaction list show a small secondary annotation with the original currency and amount (e.g. "USD 50.00"); JPY rows are unchanged
- [x] **DISP-03**: The detail/edit view shows the complete original record: original currency, original amount, and applied rate
- [x] **DISP-04**: In edit mode, original amount / rate / JPY amount are three linked editable fields — editing any one recalculates the others without circular-update loops (bidirectional linked editing)

### 语音 (Voice)

- [ ] **VOICE-CUR-01**: zh voice entry recognizes explicit currency words (美元/欧元/英镑/港币 etc.) and sets the entry currency (「五十美元」→ USD 50); bare 「元」 keeps its existing JPY-terminator behavior unchanged
- [ ] **VOICE-CUR-02**: ja voice entry recognizes currency words (ドル/ユーロ/ポンド etc.); bare 「ドル」 defaults to USD; recognized currency is editable on the form before save
- [ ] **VOICE-CUR-03**: Voice parse result carries the detected currency through to the shared form, which then triggers the normal rate-fetch flow; voice corpus tests extended per currency per locale

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Multi-Currency v2

- **CUR-V2-01**: "Remember this rate" option for recurring same-rate entries
- **SHOP-CURRENCY-V2**: Shopping list `estimatedPrice` multi-currency support
- **CUR-V2-02**: Per-currency spending sub-totals in analytics (e.g. "this trip: USD 320 total")

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Live intraday exchange rates | ECB publishes once per business day; no free real-time source without API key; per-day granularity matches how banks post transactions |
| Retroactive mass rate-update on historical transactions | Destroys hash-chain integrity and analytics reproducibility; per-transaction locked rate only |
| Per-user home currency other than JPY | Architectural rewrite of analytics/summaries, not an increment; original-amount annotation serves non-JPY thinkers |
| Automatic currency detection without explicit currency word | "Dollar"-class ambiguity (US/AU/CA/HK) adds disambiguation friction to the 95% JPY-only path; explicit words only, ドル→USD default |
| Real-time conversion widget on home screen | Always-on network dependency conflicts with local-first; no "foreign balance" concept exists |
| Shopping list estimatedPrice multi-currency | Separate scope, no SmartKeyboard flow there; carried as SHOP-CURRENCY-V2 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STORE-01 | Phase 40 | Complete |
| STORE-02 | Phase 40 | Complete |
| STORE-03 | Phase 40 | Complete |
| STORE-04 | Phase 40 | Complete |
| STORE-05 | Phase 40 | Complete |
| RATE-01 | Phase 41 | Complete |
| RATE-02 | Phase 41 | Complete |
| RATE-03 | Phase 41 | Complete |
| RATE-04 | Phase 41 | Complete |
| RATE-05 | Phase 41 | Complete |
| RATE-06 | Phase 41 | Complete |
| CURR-01 | Phase 42 | Pending |
| CURR-02 | Phase 42 | Pending |
| CURR-03 | Phase 42 | Pending |
| CURR-04 | Phase 42 | Pending |
| CURR-05 | Phase 42 | Pending |
| DISP-01 | Phase 42 | Pending |
| DISP-02 | Phase 42 | Pending |
| DISP-03 | Phase 42 | Complete |
| DISP-04 | Phase 42 | Complete |
| VOICE-CUR-01 | Phase 42 | Pending |
| VOICE-CUR-02 | Phase 42 | Pending |
| VOICE-CUR-03 | Phase 42 | Pending |

**Coverage:**

- v1.7 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-12*
*Last updated: 2026-06-12 — traceability revised by roadmapper (3-phase consolidation, Phases 40-42)*
