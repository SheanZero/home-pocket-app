# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — see [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — see [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 购物清单** — Phases 36-39 (shipped 2026-06-12) — see [archive](milestones/v1.6-ROADMAP.md)
- 🚧 **v1.7 多币种支持** — Phases 40-42 (in progress)

## Phases

<details>
<summary>✅ v1.0 Codebase Cleanup Initiative (Phases 1-8) — SHIPPED 2026-04-29</summary>

- [x] Phase 1: Audit Pipeline + Tooling Setup (8/8 plans) — completed 2026-04-25
- [x] Phase 2: Coverage Baseline (4/4 plans) — completed 2026-04-26
- [x] Phase 3: CRITICAL Fixes (5/5 plans) — completed 2026-04-26
- [x] Phase 4: HIGH Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 5: MEDIUM Fixes (5/5 plans) — completed 2026-04-27
- [x] Phase 6: LOW Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 7: Documentation Sweep (6/6 plans) — completed 2026-04-28
- [x] Phase 8: Re-Audit + Exit Verification (8/8 plans) — completed 2026-04-28

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. Full details: `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 Happiness Metric & Display (Phases 9-12) — SHIPPED 2026-05-05</summary>

- [x] Phase 9: Happiness Domain & Formula Layer (14/14 plans) — completed 2026-05-02
- [x] Phase 10: HomePage SoulFullnessCard Redesign (13/13 plans) — completed 2026-05-03
- [x] Phase 11: AnalyticsScreen Unified Dashboard (8/8 plans) — completed 2026-05-04
- [x] Phase 12: UI Copy Rename Pass (5/5 plans) — completed 2026-05-04

**Outcome:** v1.1 delivered the happiness metric domain, integrated HomeHeroCard, Variant δ AnalyticsScreen, trilingual Joy/Daily ledger copy rename, and accepted ADR-015 lexical hierarchy. One Phase 11 human UAT verification item is acknowledged as deferred at close in `.planning/STATE.md`. Full details: `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.3 迭代帐本输入 (Phases 18-23) — SHIPPED 2026-05-26</summary>

- [x] Phase 18: Shared Details Form Foundation (8/8 plans) — completed 2026-05-22
- [x] Phase 19: Manual One-Step + Keypad Polish (5/5 plans) — completed 2026-05-23
- [x] Phase 20: Voice Number Parser (zh + ja) (9/9 plans) — completed 2026-05-24
- [x] Phase 21: Voice Category Resolver Level-2 Enforcement (6/6 plans) — completed 2026-05-25
- [x] Phase 22: Voice One-Step Integration + Record Button UX (10/10 plans) — completed 2026-05-25
- [x] Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish (9/9 plans) — completed 2026-05-26

**Outcome:** v1.3 transformed ledger entry into single-screen, voice-trustworthy core experience. Single shared `TransactionDetailsForm` widget powers 4 hosts (manual, voice, edit, OCR review). `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor with 6 golden baselines. Locale-aware zh+ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy. `VoiceCategoryResolver` always-L2 contract with merchant DB + extensible synonym dictionary. Hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified). 2 BLOCKER gaps (G-01/G-02) elevated and closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt. Audit status `tech_debt` accepted at close. Full details: `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.4 列表功能 (Phases 24-30) — SHIPPED 2026-05-31</summary>

- [x] Phase 24: Data Layer Extension (3/3 plans) — completed 2026-05-29
- [x] Phase 25: Domain Models + Use Case (2/2 plans) — completed 2026-05-29
- [x] Phase 26: Providers + Shell Wiring (4/4 plans) — completed 2026-05-30
- [x] Phase 27: Calendar Header + Month Summary (4/4 plans) — completed 2026-05-30
- [x] Phase 28: Transaction Tile + Sort/Filter Bar (7/7 plans) — completed 2026-05-30
- [x] Phase 29: List Screen Assembly + Family (4/4 plans) — completed 2026-05-30
- [x] Phase 30: i18n + Empty States + Golden Polish (5/5 plans) — completed 2026-05-31

**Outcome:** Built the placeholder List tab into a full transaction overview. Audit `tech_debt` accepted — 22/22 requirements, 7/7 phases, 7/7 E2E flows satisfied. Full details: `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.5 文案与配色统一 (Phases 31-35) — SHIPPED 2026-06-02</summary>

- [x] Phase 31: Terminology Rename (6/6 plans) — completed 2026-06-01
- [x] Phase 32: Palette Exploration & Selection (3/3 plans) — completed 2026-06-01
- [x] Phase 33: Color Token System & Consolidation (8/8 plans) — completed 2026-06-01
- [x] Phase 34: Golden Re-baseline & Verification (5/5 plans) — completed 2026-06-01
- [x] Phase 35: Close Vocab Leaks — a11y Semantics labels (W1) + totalSoulTx identifiers (W2) (2/2 plans) — completed 2026-06-02

**Outcome:** Brownfield consistency refactor — unified 日常/悦己 vocabulary + `AppPalette` ThemeExtension (ADR-019 "Sakura Mochi × Wakaba" supersedes ADR-018). Audit `tech_debt` accepted at close — 15/15 requirements, 5/5 phases, 6/6 integration seams wired. Full details: `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.6 购物清单 (Phases 36-39) — SHIPPED 2026-06-12</summary>

- [x] Phase 36: Data Layer + Domain + Import Guard (7/7 plans) — completed 2026-06-07
- [x] Phase 37: Application Use Cases + Sync Integration (6/6 plans) — completed 2026-06-08
- [x] Phase 38: Presentation Shell + UI Widgets (8/8 plans) — completed 2026-06-08
- [x] Phase 39: i18n + Golden Re-baseline + Smoke Test (6/6 plans) — completed 2026-06-09

**Outcome:** The placeholder 4th nav tab is a complete family shopping list — public/private segmented lists, family sync for public items via the existing E2EE pipeline, private items never entering the pipeline (three-layer privacy enforcement). ARB parity ja/zh/en, 54 golden baselines, schema v19→v20. Audit `tech_debt` accepted; W1/W2 sync warnings closed at close by quick task 260612-daz; suite 2588/2588 green. Full details: `.planning/milestones/v1.6-ROADMAP.md` + `.planning/milestones/v1.6-MILESTONE-AUDIT.md`.

</details>

### 🚧 v1.7 多币种支持 (Phases 40-42)

**Milestone Goal:** 记账支持外币输入——小键盘选币种、按账目日期自动取汇率转换成日元入账，原币种/原金额/汇率作为附加字段保留并在 UI 中可见。

- [x] **Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync)** — ADRs (rate precision / hash scope / edit policy); CNY `¥` symbol fix; Drift v20→v21 migration (`exchange_rates` cache table + 3 nullable `transactions` columns); `ExchangeRateDao` + repository; `Transaction` Freezed extension; `TransactionSyncMapper` null-safe passthrough + round-trip tests; partial-triple domain invariant (completed 2026-06-12)
- [x] **Phase 41: 汇率服务 (Exchange Rate Service)** — `ExchangeRateApiClient` (Frankfurter primary + fawazahmed0 fallback); `ExchangeRateCacheService` (cache-first, offline fallback, weekend date transparency); application use cases with sealed `RateResult`; manual override semantics; date-change re-fetch policy; never-block-save invariant; privacy verification (completed 2026-06-13)
- [ ] **Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice)** — SmartKeyboard currency selector + `CurrencySelectorSheet`; decimal input gate per ISO 4217 minor unit; live JPY conversion preview; foreign-currency list annotation; detail/edit full display + two-input/one-derived linked editing (ADR-022 D-01; JPY read-only); zh/ja voice currency words (parallel wave inside the phase); i18n + goldens

## Phase Details

### Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync)

**Goal**: The complete data and domain substrate for multi-currency is live and sync-safe: three blocking ADR decisions recorded, the CNY/JPY `¥` collision fixed, Drift v20→v21 migrated (`exchange_rates` cache table + three nullable `transactions` columns), the `Transaction` Freezed model extended, and the family sync pipeline passing the new fields null-safely in both directions — unblocking all downstream work.
**Depends on**: Phase 39 (v1.6 shipped, schema at v20)
**Requirements**: STORE-01, STORE-02, STORE-03, STORE-04, STORE-05
**Success Criteria** (what must be TRUE):

  1. Drift migration runs cleanly from v20→v21: existing transactions gain three null columns without data loss, a clean install reaches v21 in one pass, and `HashChainService.verifyChain` passes on a dataset containing both pre-migration (null currency fields) and post-migration (populated currency fields) rows
  2. Three ADRs are recorded covering: (a) `exchangeRate` stored as `TextColumn` (string, full precision), (b) new currency fields excluded from the hash formula (existing chains stay valid), (c) date-change re-fetch / edit policy with >1% JPY amount change confirmation — all before any migration code lands
  3. CNY amounts display as `CN¥` (not `¥`) across all locales; JPY amounts continue to display `¥`; the shared JPY integer rounding utility `(originalAmount × appliedRate).round()` is the single conversion site; amount golden tests reflect the new symbol
  4. `Transaction.originalCurrency`, `.originalAmount`, `.appliedRate` exist as nullable Freezed fields and `TransactionSyncMapper` round-trips them null-safely — verified by tests: new-to-old wire (extra keys silently ignored), old-to-new wire (absent keys → JPY row); `build_runner` clean
  5. The partial-triple domain invariant holds: if exactly one or two of the three currency fields are non-null, `CreateTransactionParams` validation returns `Result.error` before any DB write; `ExchangeRateDao` supports exact-date and latest-for-currency queries and all new code passes `import_guard`

**Plans**: 6 plans
Plans:
**Wave 1**

- [x] 40-01-PLAN.md — Wave 0 test scaffolds (migration/DAO/conversion/sync mapper stubs, RED)
- [x] 40-02-PLAN.md — Three ADRs (ADR-020/021/022) + index update

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 40-03-PLAN.md — NumberFormatter disambiguation table + golden re-baseline (STORE-05)
- [x] 40-04-PLAN.md — Drift v20→v21 migration + ExchangeRates table + ExchangeRateDao + repository stub

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 40-05-PLAN.md — ExchangeRate domain model + repository interface + currency_conversion utility + Riverpod wiring

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 40-06-PLAN.md — Transaction Freezed extension + TransactionSyncMapper + partial-triple invariant + full test suite

### Phase 41: 汇率服务 (Exchange Rate Service)

**Goal**: A fully tested, offline-safe exchange rate service — dual-source fetch (Frankfurter primary, fawazahmed0 fallback), Drift-backed per-(date, currency) cache, weekend/holiday date transparency, manual override and date-change semantics enforced through application use cases — with the hard invariant that saving a transaction is never blocked on network.
**Depends on**: Phase 40
**Requirements**: RATE-01, RATE-02, RATE-03, RATE-04, RATE-05, RATE-06
**Success Criteria** (what must be TRUE):

  1. Cache behavior is correct: a second request for the same (date, currency) pair triggers zero network calls; a cache miss calls the API, persists the response to the `exchange_rates` Drift table, and returns the rate; historical rates are permanent while today's rate honors a short TTL
  2. Offline / network-failure path: when all API calls throw, the service returns the most-recent cached rate for that currency as `RateResult.fallback` carrying the actual cached date for the staleness indicator; `GetExchangeRateUseCase` never throws to the caller
  3. Weekend / holiday and coverage routing: when Frankfurter returns a rate for a different date than requested (e.g., Saturday request → Friday rate), the actual rate date is surfaced via `RateResult.fetched.actualDate`; a TWD request is correctly routed to fawazahmed0
  4. Manual override and date-change semantics work per the Phase 40 ADR: a user-overridden rate is used for saving and is not clobbered by a subsequent date-change re-fetch unless the user explicitly changes the date after overriding; a date change causing >1% JPY amount difference surfaces a confirmation signal to the UI
  5. The never-block-save invariant is enforced: `CreateTransactionUseCase` and `UpdateTransactionUseCase` contain zero HTTP calls (rate resolution is always pre-computed and passed in), and no URL constructed by `ExchangeRateApiClient` contains any string derived from user data

**Plans**: 5 plans
Plans:
**Wave 1** *(parallel — no interdependencies)*

- [x] 41-01-PLAN.md — Repository interface extensions (findLatestNonManual, deleteOlderThan, findAll) + Wave 0 RED test scaffolds
- [x] 41-02-PLAN.md — connectivity_plus pubspec addition + iOS build verification (checkpoint)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 41-03-PLAN.md — ExchangeRateApiClient (dual-source HTTP) + RateResult sealed class

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 41-04-PLAN.md — ExchangeRateCacheService + GetExchangeRateUseCase + BackupData D-10 extension

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 41-05-PLAN.md — Riverpod provider wiring + full suite GREEN

### Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice)

**Goal**: Users can select a foreign currency on the SmartKeyboard (or speak it in zh/ja), enter a decimal amount per the currency's minor unit, watch a live JPY conversion preview, save, and see the original currency annotated in the list and fully editable in the detail/edit view with bidirectional three-field linked editing — while the JPY-only path remains completely untouched.
**Depends on**: Phase 41 (voice work runs as a parallel wave inside the phase — independent of the keypad/display wave)
**Requirements**: CURR-01, CURR-02, CURR-03, CURR-04, CURR-05, DISP-01, DISP-02, DISP-03, DISP-04, VOICE-CUR-01, VOICE-CUR-02, VOICE-CUR-03
**Success Criteria** (what must be TRUE):

  1. Tapping the currency symbol adjacent to the amount on `SmartKeyboard` opens `CurrencySelectorSheet` without leaving the entry screen; JPY is always first with common currencies re-ordered by recent use before a "more" affordance expanding the full ISO 4217 list with real-time search; the last-used foreign currency is the session default and resets to JPY on restart
  2. When JPY is active, the entry UX is completely unchanged: no rate fetch, no preview panel, no list annotation; the dot key is enabled only for currencies with a minor unit (capped at the currency's decimals) and remains non-functional for JPY and KRW
  3. During foreign-currency entry, a live JPY conversion preview appears below the amount and updates on every keypad tap, currency change, rate change, and date change; a loading state shows while fetching; the actual rate date / staleness label appears when it differs from the transaction date or a cached fallback rate is in use
  4. Foreign-currency rows in the transaction list show a small secondary annotation (e.g., "USD 50.00") while JPY rows are unchanged; the detail/edit view shows original currency, original amount, and applied rate; in edit mode the three fields (original amount / rate / JPY amount) are linked — editing any one recalculates the others without circular-update loops; an integration smoke test confirms USD 50 at 148.30 → `amount=7415`, `original_currency='USD'`
  5. zh voice "五十美元" and ja voice "50ドル" both parse to `{amount: 50, detectedCurrency: 'USD'}` with 欧元/英镑/港币/澳元/加元 and ユーロ/ポンド/香港ドル/豪ドル mapping to their ISO codes; bare 「元」 keeps its existing JPY-terminator behavior and bare 「ドル」 defaults to USD; the detected currency flows through the shared form (editable before save) and triggers the normal rate-fetch flow; voice corpus tests pass with ≥5 cases per currency per locale and all existing corpus tests unchanged

**Planning note**: ROADMAP Goal + SC-4 "bidirectional three-field linked editing / editing any one recalculates the others" is **VOID** — superseded by ADR-022 D-01 (ratified 2026-06-12) and CONTEXT.md D-10: the edit host is **two-input / one-derived** (original amount + rate editable; JPY read-only derived via `convertToJpy()`, never directly assigned). Plans implement the two-input/one-derived model; three-field bidirectional editing is forbidden (circular-dependency risk).
**Plans**: 9 plans in 5 waves
**Wave 1**

- [x] 42-01-PLAN.md — Wave 0 failing-test scaffolding (SC-5 smoke, D-07/D-08, voice corpus, ADR-022 edit, update-plumbing) [W1] — ✅ 5 files (4 RED + SC-5 create smoke GREEN-on-arrival)
- [x] 42-02-PLAN.md — Shared foundation: per-currency decimals via intl currencyFractionDigits (convertToJpy unchanged) [W1]
- [x] 42-03-PLAN.md — Plumbing gap: UpdateTransactionParams + use case carry the currency triple, recompute JPY, no rehash (ADR-021) [W1]
- [x] 42-04-PLAN.md — Voice wave (parallel): zh/ja currency detection → VoiceParseResult.detectedCurrency (VOICE-CUR-01/02/03) [W1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 42-05-PLAN.md — AmountInputController (D-07 cap / D-08 truncate) + SmartKeyboard dot-gating (D-06, 48dp) [W2]
- [ ] 42-06-PLAN.md — CurrencySelectorSheet (JPY-first, search, more, flag rows) + recent-use session provider + ARB names [W2]

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 42-07-PLAN.md — Live JPY ConversionPreviewPanel (D-03/D-04/D-05; ref.listen signals; convertToJpy single site) [W3]

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 42-08-PLAN.md — Manual-entry host wiring (tappable currency key, controller, preview, triple → SC-5) + list foreign annotation [W4]

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 42-09-PLAN.md — Edit-host two-input/one-derived (ADR-022 D-01/D-02/D-03) + voice confirmation surfacing [W5]

**UI hint**: yes

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 29/29 | Complete | 2026-05-31 |
| v1.5 文案与配色统一 | 31-35 | 24/24 | Complete | 2026-06-02 |
| v1.6 购物清单 | 36-39 | 27/27 | Complete | 2026-06-12 |
| v1.7 多币种支持 | 40-42 | 0/TBD | In progress | - |
