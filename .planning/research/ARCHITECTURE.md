# Architecture Research — v1.8 Analytics Page Redesign (Integration)

**Domain:** Flutter analytics dashboard redesign on an existing 5-layer Clean Architecture (Riverpod 3 + Freezed + Drift/SQLCipher)
**Researched:** 2026-06-15
**Confidence:** HIGH (read the live screen, all 6 provider files, monthly-report use case, all domain models, DAO/repository surface, the isolation test, the anti-toxicity test, ADR-012 and ADR-016)

> **Scope note.** This is an *integration* research file, not a greenfield architecture survey. The 5-layer architecture, Thin-Feature rule, and placement rules are fixed (CLAUDE.md, structurally enforced by `import_guard`). The redesign is a **presentation-layer rebuild that maximizes reuse of the existing application + domain + data layers.** New work concentrates in `presentation/` plus a small, well-bounded set of new use-case / DAO methods for the genuinely-new surfaces (savings-rate overview promotion, category drill-down detail, optional card-order persistence).

---

## 1. REUSE MAP — Existing surfaces vs new work

### 1a. The practical "income / expense / savings-rate overview" — already computed, just not surfaced as a first-class card

`GetMonthlyReportUseCase.execute()` → `MonthlyReport` **already returns everything the practical overview needs**, computed today and thrown away by the current KPI strip:

| Need (v1.8 practical surface) | Existing field on `MonthlyReport` | Status |
|---|---|---|
| Income total | `totalIncome` (int, JPY) | **EXISTS** — fed from `getMonthlyTotals` income/expense split |
| Expense total | `totalExpenses` (int, JPY) | **EXISTS** |
| Savings (balance) | `savings` = income − expenses | **EXISTS, pre-computed** |
| **Savings rate** | `savingsRate` = savings/income×100 (double, 0.0 if income==0) | **EXISTS, pre-computed** — the central ask is already in the model |
| Category composition (donut/list) | `categoryBreakdowns: List<CategoryBreakdown>` (amount, percentage, txCount, icon, color) | **EXISTS** |
| Daily spend series | `dailyExpenses: List<DailyExpense>` (zero-filled per day across window) | **EXISTS** |
| Daily-vs-Joy ledger split | `dailyTotal` / `joyTotal` | **EXISTS** |
| Prev-month comparison | `previousMonthComparison` | **EXISTS but DO NOT surface** — `MonthlyReport` doc-comment: *"AnalyticsScreen no longer surfaces this delta (ADR-012 §4)"*; consumed only by HomeHero. The redesign must keep it unsurfaced (anti-gamification, §3). |

**Implication:** the "收支总览 / 结余率前面化" feature requires **zero new data work**. It is a presentation transform over `monthlyReportProvider` — promote `totalIncome / totalExpenses / savings / savingsRate` into a hero overview card. No new use case, no DAO change, no Drift migration.

### 1b. The 15 existing use cases mapped to redesign surfaces

| Use case | Provider (key tuple) | Domain output | Reuse in redesign |
|---|---|---|---|
| `GetMonthlyReportUseCase` | `monthlyReportProvider(bookId, startDate, endDate, joyMetricVariant)` | `MonthlyReport` | **PRIMARY REUSE** — drives the new savings-rate overview, category donut/list, daily series. Single richest provider. |
| `GetExpenseTrendUseCase` | `expenseTrendProvider(bookId, anchor, joyMetricVariant)` | `ExpenseTrendData` (6-month rolling) | **REUSE** — spending-trend surface |
| `GetHappinessReportUseCase` | `happinessReportProvider(bookId, startDate, endDate, currencyCode, joyMetricVariant)` | `HappinessReport` (avgSatisfaction, joyContribution, median, highlightsCount, topJoy — all `MetricResult`-wrapped) | **REUSE** — 悦己 narrative core |
| `GetSatisfactionDistributionUseCase` | `satisfactionDistributionProvider(...)` | `List<SatisfactionScoreBucket>` | **REUSE** (gated `totalJoyTx >= 5`) |
| `GetPerCategoryJoyBreakdownUseCase` [+AcrossBooks] | `perCategoryJoyBreakdownProvider` / `…FamilyProvider` | `MetricResult<PerCategoryJoyBreakdown>` | **REUSE** — per-category 悦己 |
| `GetDailyVsJoySnapshotUseCase` [+AcrossBooks] | `dailyVsJoySnapshotProvider` / `…FamilyProvider` | `MetricResult<DailyVsJoySnapshot>` | **REUSE** — 日常-vs-悦己 compare |
| `GetBestJoyMomentUseCase` | `bestJoyMomentProvider(...)` | `MetricResult<BestJoyMomentRow>` | **REUSE** — "best joy moment" story |
| `GetLargestMonthlyExpenseUseCase` | `largestMonthlyExpenseProvider(...)` | `LargestMonthlyExpense?` | **REUSE** — largest-expense story |
| `GetFamilyHappinessUseCase` | `familyHappinessProvider(...)` | `FamilyHappiness` (aggregate-only) | **REUSE** — group mode |
| `GetMonthlyJoyTargetRecommendationUseCase` | `monthlyJoyTargetRecommendationProvider(...)` | `MetricResult<int>` | Reuse if redesign surfaces target context (HomeHero territory — keep light) |
| `GetBudgetProgressUseCase` | `getBudgetProgressUseCaseProvider` | `List<BudgetProgress>` | **STUB — returns `[]`.** See §1c. |
| `_TimeWindowValidation` | (internal) | guard | Reuse as-is — every windowed use case calls it |

**13 of 15 use cases are directly reusable. Two are NOT redesign inputs:** `_TimeWindowValidation` is internal plumbing, and `GetBudgetProgressUseCase` is a non-functional stub.

### 1c. Genuinely-NEW work needed

| New capability | New use case / method | DAO change | Drift migration? | Verdict |
|---|---|---|---|---|
| **Savings-rate overview card** | none (transform over `MonthlyReport`) | none | no | **No new code below presentation.** Highest-value, lowest-cost. |
| **Category drill-down detail** (tap a category → its transactions / sub-breakdown for the window) | NEW `GetCategoryDrillDownUseCase(bookId, categoryId, startDate, endDate, entrySourceFilter)` returning a new `CategoryDrillDown` Freezed model (txn list + per-merchant or per-day rollup) | NEW `AnalyticsDao.getCategoryTransactions(...)` or reuse `TransactionDao` window query filtered by categoryId | **likely no** — read-only query over existing `transactions` columns; needs an index check on `(book_id, category_id, timestamp)` | **NEW, scoped.** Decision point for design: drill to a transaction list (reuse `ListTransactionTile` from `lib/features/list/`) vs an in-card sub-breakdown. Prefer reusing the v1.4 list tile + edit path. |
| **Budget-vs-actual** (if in scope) | re-implement `GetBudgetProgressUseCase` | new budget read | **YES — needs a dedicated `budgets` Drift table** (the stub's own comment says so; `Category.budgetAmount` was removed) | **DEFER unless explicitly required.** This is the only redesign ask that forces a schema migration. `CategoryBreakdown` already carries nullable `budgetAmount`/`budgetProgress` slots, so the model is forward-compatible — but the data source does not exist. Recommend treating budget as a **separate future milestone**, not a v1.8 card, unless the design gate elevates it. |
| **Customizable / reorderable card order** (optional) | NEW persistence: `AnalyticsLayoutPreference` | none in AnalyticsDao | see §2d | **NEW, presentation+settings-scoped.** SharedPreferences, NOT Drift (see §2d). |

**Net new below presentation for the core v1.8 goal: at most one read-only drill-down use case + one DAO method.** Everything else (overview, trends, category donut, 悦己 narrative) is reuse. Budget = explicitly out unless the gate pulls it in (it carries the only migration cost).

---

## 2. PRESENTATION STRUCTURE — card-based dashboard

### 2a. Current structure (the baseline being replaced)

`analytics_screen.dart` (592 LOC) is a single `ConsumerWidget` with a hard-coded `SingleChildScrollView > Column` of section headers and private `_XxxCard` `ConsumerWidget`s. **Each card already owns its own `AsyncValue.when` branch** — one failing provider does not blank the screen (good pattern, keep it). The screen also owns a 100-line imperative `_refresh()` that manually `ref.invalidate`s ~12 providers on pull-to-refresh.

**What is good and must be preserved in the redesign:**
- **Per-card `AsyncValue.when` isolation** — already the dominant pattern; the redesign's card contract should formalize it (every card = a `ConsumerWidget` that watches exactly one provider family and renders loading/error/data locally).
- **Provider-per-metric with key tuples** — `(bookId, startDate, endDate, joyMetricVariant)` is the established cache key. Riverpod 3 auto-disposes + auto-recomputes on key-tuple change, which is why toggling the time window or variant "just works."

**What hurts and should change:**
- The monolithic 592-LOC screen + 100-LOC manual `_refresh()`. The redesign should make `_refresh()` data-driven (see §2c) and split cards into their own files (`presentation/widgets/cards/`), keeping each <400 LOC per coding-style rules.

### 2b. Recommended card/provider organization

Keep the **one async provider per metric, keyed by tuple** model — it is already correct and battle-tested across 6 milestones. Organize the redesign as:

```
features/analytics/presentation/
├── screens/
│   └── analytics_screen.dart        # shell: AppBar + chips + scroll + card list driver (THIN)
├── widgets/
│   ├── cards/                        # NEW folder — one file per card, each a ConsumerWidget
│   │   ├── savings_overview_card.dart      # NEW — watches monthlyReportProvider
│   │   ├── spend_trend_card.dart           # reuse MonthlySpendTrendBarChart
│   │   ├── category_breakdown_card.dart    # reuse donut + drill-down entry
│   │   ├── joy_narrative_card.dart         # 悦己 surface (design-gate-defined form)
│   │   └── … (best joy, largest expense, daily-vs-joy, family)
│   └── analytics_card_error_state.dart     # reuse as-is
└── providers/
    ├── repository_providers.dart     # reuse — add drill-down use-case provider if built
    ├── state_analytics.dart          # reuse
    ├── state_happiness.dart          # reuse
    ├── state_ledger_snapshot.dart    # reuse
    ├── state_time_window.dart        # reuse
    ├── state_joy_metric_variant.dart # reuse
    └── state_analytics_layout.dart   # NEW (only if customizable dashboard ships)
```

**Card contract (formalize the existing implicit one):**
- A card is a `ConsumerWidget` that `ref.watch`es exactly its own provider family with the shared key tuple, and renders `.when(data/loading/error)` locally with `AnalyticsCardErrorState(onRetry: () => ref.invalidate(thatProvider))`.
- The shell passes only the key components (`bookId`, window range, `locale`, `joyMetricVariant`); it does NOT pre-read provider data and pass it down (that would couple cards and break per-card error isolation).
- This keeps the dashboard reactive and performant: with Riverpod 3, an off-screen card whose provider is auto-dispose simply does not run; visible cards each rebuild independently only when their own provider changes.

### 2c. Reactivity & performance with many cards

- **Shared key tuple is the performance lever.** Because every card keys on the same `(bookId, startDate, endDate, joyMetricVariant)`, a window/variant change recomputes the relevant providers exactly once each, and Riverpod dedupes identical reads. Do not introduce per-card divergent keys.
- **Make `_refresh()` data-driven.** Replace the hand-written 100-line invalidation list with a single helper that invalidates the family of providers for the current `(bookId, range, variant)` — ideally derive the list from the card registry so adding a card cannot forget an invalidation. This also reduces the risk of accidentally invalidating a home/* provider (see §3).
- **Lazy card construction.** For a long dashboard prefer `CustomScrollView` + `SliverList`/`SliverChildBuilderDelegate` (or `ListView.builder`) over the current eager `Column` so off-screen cards aren't built until scrolled into view — meaningful once card count grows or a reorderable list is added.
- **`keepAlive` only where justified.** The list feature uses `keepAlive`-under-`IndexedStack` to preserve filter state; analytics cards are pure derived reads and should stay **auto-dispose** (default) so leaving the tab frees memory and re-entering recomputes fresh.

### 2d. Customizable / reorderable dashboard — modeling

If the design gate selects a customizable dashboard:

- **Persist card order in SharedPreferences, NOT Drift.** Rationale, all pointing the same way:
  1. **Precedent:** the app already persists user UI preferences (`AppSettings.monthlyJoyTarget`, locale) via the settings/SharedPreferences path — card order is the same class of data.
  2. **Not sync data:** card order is a per-device UI preference; it must NOT enter the E2EE family-sync pipeline (Drift tables flow through sync mappers). Keeping it in SharedPreferences structurally guarantees it never syncs.
  3. **No migration cost:** a Drift table would mean schema v21→v22 + a sync-mapper decision. SharedPreferences avoids both.
- **Model:** an ordered `List<AnalyticsCardId>` (a stable enum of card identifiers) serialized to a JSON string in prefs, plus a `Set<AnalyticsCardId>` of hidden cards if hide/show is in scope.
- **Provider:** a `@riverpod` `AnalyticsLayout` Notifier exposing the ordered/visible card list, with `reorder()` / `setVisible()` methods that write through to prefs. Cards render in the order the notifier yields; the shell maps id→widget via a registry map.
- **Reorder UI:** `ReorderableListView` (or sliver equivalent). Default order = the design-approved canonical order; resetting clears the pref key. Treat an enum-keyed registry as the single source of truth so a removed/renamed card degrades gracefully (unknown id ignored on read).

---

## 3. CONSTRAINT PRESERVATION — must survive a full redesign

### 3a. HomeHero isolation (ADR-016 §3) — enforced by `home_screen_isolation_test.dart`

**The contract, as the test actually enforces it:**
1. **`AnalyticsScreen._refresh()` must NOT invalidate any `home/*` provider.** The current `_refresh()` has the load-bearing comment *"D-12: _refresh MUST NOT invalidate any home/* provider"* and deliberately keys its invalidations on the analytics window — never on HomeHero's month-anchored instances. **Any redesigned refresh must preserve this** (the data-driven refresh in §2c makes it easier to guarantee, because the invalidation set is derived from the analytics card registry, which contains no home providers).
2. **`home_screen.dart` source must not import `state_time_window` / reference `selectedTimeWindowProvider`.** The test reads the home screen source file and asserts these substrings are absent — HomeHero is permanently current-month-anchored, independent of the analytics time window. The redesign touches only the analytics feature, so this stays true by construction; **do not "share" the time-window provider into any home widget.**
3. **HomeHero use cases are never invoked by AnalyticsScreen.** The test mocks the HomeHero-facing use cases and asserts `verifyNever(... .execute(...))` with `any()` across an AnalyticsScreen interaction (incl. the JoyMetricVariant toggle, SC-4). The structural reason it holds: analytics providers and home providers are **distinct provider families even when they wrap the same use case**, and they use different key tuples. **The redesign must not make any analytics card read a `home/*` provider, and must not add a shared provider that both screens watch.**

**Redesign rule:** the analytics feature reads only `analytics/*`, `accounting/*` (book/category), and `family_sync/*` providers. It never reads or invalidates `home/*`. Keep the isolation test green; if a new card needs "current month" data, it must instantiate its own analytics-keyed provider, not borrow HomeHero's.

### 3b. Anti-gamification (ADR-012) — enforced by `anti_toxicity_phase16/17_test.dart` + type system

**Two enforcement layers, both must stay intact:**

1. **Type-level (the strongest lock):** `FamilyHappiness` exposes only **aggregate** metrics — `familyHighlightsSum: MetricResult<int>`, `sharedJoyInsight: MetricResult<SharedJoyInsight>`, `medianSatisfaction: MetricResult<double>`, `totalGroupJoyTx: int`. **There are no per-member fields and no per-member list.** ADR-012 §6 explicitly notes this is *enforced by the type system* so a future PR cannot build a leaderboard without changing the domain contract. **The redesign must not add per-member breakdown, ranking, or contribution-by-member surfaces** — and must not add per-member fields to `FamilyHappiness` to enable one.
2. **Copy-level (substring sweep):** `anti_toxicity_phase16/17_test.dart` renders each card in ja/zh/en and asserts a **locked forbidden-substring list** (`rank`, `ranking`, streak/badge/target/cross-period-delta vocabulary per locale) renders `findsNothing`. **Every NEW card in the redesign must be added to this sweep**, and all new ARB copy must avoid the forbidden vocabulary. The forbidden set is the operative definition of ADR-012's bans:
   - No **streaks / 连续打卡**, no **badges / 成就**, no **daily targets / 每日目标**.
   - No **cross-period delta** ("vs 上月 +X") — this is why `MonthlyReport.previousMonthComparison` is consumed by HomeHero only and **must stay unsurfaced** on the analytics page (§1a). The savings-rate overview shows the *current* rate, not a month-over-month delta arrow.
   - No **ranking / leaderboard**, no **public sharing**, no **per-member breakdown**.

**The open design question (PROJECT.md):** "为自己花钱而开心" must be expressed *celebrating, not grading*. The 悦己 narrative card(s) should highlight satisfaction and "best joy moment" stories (existing `bestJoyMoment` / `joyContribution` data) **without** introducing targets-vs-progress framing, streaks, or comparison. If a chosen design direction wants a new emotional mechanic that brushes the ADR boundary, the gate should evaluate whether a **new ADR** is needed before any code — do not let it leak into build phases unreviewed.

---

## 4. SUGGESTED BUILD ORDER — design gate first

The user's required sequencing puts a **design gate (Phase 43) before any production code.** Decompose accordingly:

### Phase 43 — Research-current-impl + HTML design exploration + selection (DESIGN GATE, NO production code)
- Deliverables: (a) a written current-impl map (this file is the seed); (b) multiple HTML design directions for the redesigned dashboard, each explicitly answering the ADR-012 open question ("celebrate, don't grade"); (c) discussion → **one selected direction**; (d) if any direction needs a mechanic near the ADR-012 line, a go/no-go on a new ADR.
- **Gate exit criterion:** user approves one direction. No Dart/production code committed in this phase. HTML/Pencil mocks only.

### Phase 44 — Data / use-case additions (only what the selected design requires)
- Reuse-first: confirm the selected direction's data needs against the §1 reuse map.
- Build the **one** new read-only path if drill-down is in scope: `CategoryDrillDown` Freezed model (`domain/models/`) + `GetCategoryDrillDownUseCase` (`application/analytics/`) + `AnalyticsDao.getCategoryTransactions` (`data/daos/`) + repository method + index check. TDD per testing rules.
- **Budget-vs-actual only if the gate explicitly elevated it** — that pulls in a new `budgets` Drift table (schema v21→v22) and is the one item with migration cost; otherwise skip.
- Output: new providers wired in `repository_providers.dart` + `state_*.dart`. No screen changes yet.

### Phase 45 — Presentation shell rebuild
- Rebuild `analytics_screen.dart` as a thin shell: AppBar + `TimeWindowChip` + `JoyMetricVariantChip` + scroll container + card-list driver. Make `_refresh()` data-driven over the card registry. Split cards into `widgets/cards/`.
- **Carry the isolation invariant forward** (§3a): no `home/*` reads or invalidations; keep the home-import assertion green.

### Phase 46 — Cards (one wave; each card = its own file + provider watch + AsyncValue.when)
- Build/port each card per the design: savings-rate overview (new), spend trend, category breakdown + drill-down entry, 悦己 narrative, daily-vs-joy, best-joy / largest-expense stories, family (group mode).
- Reuse existing chart widgets (`MonthlySpendTrendBarChart`, `CategorySpendDonutChart`, `SatisfactionDistributionHistogram`) where the design keeps them.
- **(Optional) customizable dashboard** lands here or as a sub-phase: `state_analytics_layout.dart` + SharedPreferences persistence + `ReorderableListView` (§2d).

### Phase 47 — i18n + goldens + anti-toxicity sweep + UAT
- ARB parity across ja/zh/en for all new copy; `flutter gen-l10n`.
- **Add every new card to `anti_toxicity_phase16/17`-style sweep** and verify forbidden substrings render `findsNothing` in all 3 locales (§3b).
- Re-baseline goldens **on macOS** (per project memory: CI is ubuntu, goldens are macOS-baselined; never re-baseline off-macOS).
- Run the full suite incl. `home_screen_isolation_test.dart` and the anti-toxicity tests as the milestone gate; on-device visual UAT.

**Ordering rationale:** design gate first is mandatory (user requirement + the central ADR-012 question must be resolved before code). Data before presentation because cards can't be built against use cases that don't exist. Shell before cards so the card contract (per-card AsyncValue.when, shared key tuple, isolation-safe refresh) is in place before cards are filled in. i18n+goldens+sweeps last because they validate the finished surface and the golden baseline only stabilizes once visuals are final.

---

## Integration Points (quick reference for roadmapper)

| Integration point | New or Modified | Layer |
|---|---|---|
| `monthlyReportProvider` → savings-rate overview card | **Reuse** (new consumer) | presentation |
| `GetCategoryDrillDownUseCase` + `CategoryDrillDown` model + `AnalyticsDao.getCategoryTransactions` | **New** (if drill-down in scope) | application + domain + data |
| `budgets` Drift table + re-implemented `GetBudgetProgressUseCase` | **New, migration** (only if budget elevated) | data (schema v21→v22) + application |
| `analytics_screen.dart` shell + data-driven `_refresh()` | **Modified (rebuild)** | presentation |
| `widgets/cards/*` | **New** (split from monolith, reuse chart widgets) | presentation |
| `state_analytics_layout.dart` + SharedPreferences card order | **New** (optional) | presentation + settings |
| `home_screen_isolation_test.dart` | **Must stay green** (no home reads/invalidations) | test invariant |
| `anti_toxicity_phase16/17_test.dart` | **Extend** with new cards; forbidden sweep | test invariant |
| `FamilyHappiness` aggregate-only type contract | **Unchanged** (no per-member fields) | domain invariant |

## Confidence & Gaps

- **HIGH** on the reuse map, isolation mechanism, and anti-gamification enforcement — all read directly from source/tests.
- **Gap (for the design gate, not this file):** the exact form of the 悦己 emotional surface and whether a customizable dashboard ships are design decisions deferred to Phase 43 — this file constrains them (ADR-012, SharedPreferences-not-Drift) but does not pick them.
- **Gap:** whether budget-vs-actual is in v1.8 scope. Flag for requirements: it is the only ask carrying a Drift migration; recommend explicit exclusion unless the user prioritizes it.
