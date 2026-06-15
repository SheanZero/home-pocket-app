# Project Research Summary

**Project:** Home Pocket (まもる家計簿) — v1.8 统计页面重设计（实用化 × 悦己情感化）
**Domain:** Personal-finance analytics/statistics-page full redesign in a local-first, dual-ledger kakeibo Flutter app under a permanent anti-gamification constraint
**Researched:** 2026-06-15
**Confidence:** HIGH

## Executive Summary

v1.8 is a **presentation-layer rebuild**, not a greenfield build. The statistics page is being redesigned from a "指标罗列" dashboard into something both more practical (收支总览/结余率前面化, 支出趋势, 分类下钻) and more emotionally affirming (凸显悦己 — "让用户为自己花钱而感到开心"). Across all four research dimensions one structural reality dominates: **the data already exists.** `GetMonthlyReportUseCase` already computes `totalIncome / totalExpenses / savings / savingsRate` (the entire practical overview is a pure presentation transform with zero new data work); 13 of 15 analytics use cases are directly reusable; category drill-down reuses the v1.4 `GetListTransactionsUseCase` or a thin new read-only path; and the charting library (`fl_chart ^1.2.0`) is already the latest version — **there is no fl_chart 2.x**, so the backlog "TOOL-V2-01 1.x→2.x upgrade" rests on a false premise and must be retired/re-scoped.

The defining challenge of this milestone is **not technical — it is a design-boundary problem.** The milestone goal ("凸显悦己 / feel good about spending on yourself") sits one design decision away from violating ADR-012's permanent anti-gamification contract (no badges/streaks/cross-period-delta/targets-as-achievement/leaderboards), which is structurally locked by `anti_toxicity_*_test.dart` + `home_screen_isolation_test.dart`. The cross-cutting finding is that this tension is **structurally containable**: by inheriting ADR-016 §5's already-litigated line — **ambient `f(progress)→color` is OK; discrete unlock/threshold/celebration events are forbidden** — and by anchoring the emotional layer on kakeibo's own non-gamified precedent (Q4 "how can I improve" explicitly includes "spend MORE on what you enjoy" → values-affirmation, not achievement). Every direction explored in the Phase 43 HTML gate must carry an ADR-012 self-audit, and any direction that grazes the boundary requires a **new ADR before any code**.

The recommended approach is the user-mandated sequencing: a **Phase 43 design gate first (HTML only, no production code)** → data/use-case additions (only what the selected direction needs) → shell rebuild (preserving HomeHero isolation) → cards → i18n + anti-toxicity sweep extension + macOS golden re-baseline + full-suite gate + UAT. The primary risks are (1) the anti-gamification trap, (2) breaking the HomeHero isolation / single-Joy-expression invariants, (3) provider rebuild storms from non-canonicalized `DateTime` family keys, and (4) scope creep pulling in income-tracking/month-lock/budget/fl_chart-bump — all mitigated by holding the gate hard, canonicalizing window boundaries via `DateBoundaries`, and locking scope in REQUIREMENTS.md.

## Key Findings

### Recommended Stack

**No dependency changes are required for the core redesign.** `fl_chart ^1.2.0` is the latest published version (the version ladder is `…0.71→1.0→1.1→1.1.1→1.2.0`; no 2.x exists), it is MIT + offline + telemetry-free (mandatory for a zero-knowledge app), and it is already integrated across the existing analytics widgets with golden coverage. The two features the redesign wants — per-rod `BarChartRodData.label` and `PieChartSectionData.cornerRadius` — **already shipped in 1.2.0**, available now with no bump. All warm/celebratory 悦己 motion should use **built-in Flutter animations** (`TweenAnimationBuilder` count-up, `AnimatedSwitcher`, `AnimatedContainer` glow — the existing app idiom), and reorderable cards use built-in `ReorderableListView` + `shared_preferences`.

**Core technologies:**
- **fl_chart `^1.2.0` (KEEP — do not bump or swap)**: bar/donut/line/sparkline/histogram — latest version, already integrated, MIT, zero network; its 1.2.0 `label` API obsoletes the histogram's fragile `Stack`+`DecoratedBox` per-rod-label hack
- **Built-in Flutter animations**: warm 悦己 micro-interactions (count-up, glow, view-toggle) — no dependency, no privacy surface, value-affirming not achievement-rewarding
- **Built-in `ReorderableListView` + `shared_preferences`**: customizable/reorderable dashboard (if selected) — no new dep; card order stays a per-device UI pref, never enters the E2EE sync pipeline
- **`lottie ^3.3.x` (OPTIONAL, design-gated, asset-only)**: ONLY if Phase 43 selects a vector flourish built-in tweens can't express; `Lottie.asset` exclusively, never `Lottie.network`

**Hard NO:** any analytics/telemetry SDK (zero-knowledge), `syncfusion_flutter_charts` (commercial license), `confetti` (reads as gamification reward — escalate to a design decision, don't adopt by default), touching the win32-pinned trio (`file_picker`/`package_info_plus`/`share_plus`) or the `intl 0.20.2` pin, and **upgrading/replacing fl_chart** (no 2.x, full rewrite + golden re-baseline for zero gain).

### Expected Features

**Must have (table stakes — the practical "实用化" half):**
- **Income / Expense / Net (结余) overview as the top one-glance block** — the explicit (a) milestone ask; already computed, never surfaced. **Gated on verifying income is reliably captured today.**
- **Savings rate (结余率) headline** — `(income−expense)/income`, already pre-computed on `MonthlyReport`; degrade gracefully (show "—", not 0%/-∞%) when income=0
- **Spending-by-category donut + ranked list** — already shipped; keep, restyle
- **Tap-a-category drill-down** — the explicit "分类下钻" ask; route into the existing v1.4 filtered list, don't build a new screen
- **Neutral spending trend (6-month rolling)** — already shipped; trend is rolling/neutral by nature, ADR-012-safe
- **Time-window selector + honest empty/low-data states** — established codebase patterns; apply consistently to new blocks

**Should have (competitive — the emotional "悦己情感化" half, all ADR-012-compatible):**
- **"Money well spent" 悦己 affirmation block** — the unique product thesis; surface 已花悦己 + `Σ joy_contribution` as *celebration of investing in yourself*, framing-only work over ADR-016 data. **Must NOT become a progress-to-target ring** (HomeHero owns the only target ring, ADR-016 §3)
- **Worth-it / satisfaction reflection surface** — reuse satisfaction histogram + per-category joy (min-N=3); frame as proud/content, never "beat last month"
- **Memory/story surface (elevated best-joy moments)** — pure surfacing of existing card
- **Kakeibo Q4 reflection prompt (open-ended, affirming)** — strong differentiator; needs careful copy + possibly a new ADR if it persists user-authored text (encryption implications)

**Defer (v2+ / design-direction-only):**
- **Sankey income→expense→结余 flow** — high value, high cost (no native fl_chart support); explore as a Phase 43 *direction* only, defer build if cost-prohibitive
- **Neutral "about typical" rolling band** — BOUNDARY-SENSITIVE (ADR-012 #4 adjacency); only with a validated non-judgmental framing, likely needing a new ADR
- **Per-currency analytics sub-totals (CUR-V2-02)** — out of v1.8 scope unless the redesign naturally absorbs it

**Anti-features (explicit ADR-012 violations — DO NOT BUILD):** cross-period delta callouts ("+15% vs 上月", #4/#7), streaks (#1/#5), badges/achievement unlocks (#2/#7), savings-rate/joy goal with celebration toast/confetti (#2), per-member leaderboard/contribution ranking (#6, type-enforced), public sharing of joy metrics (#5), "spend less on joy"/guilt nudges (inverts the product ethic), satisfaction-as-target "hit 8+" (#3 + Goodhart).

### Architecture Approach

A **presentation-layer rebuild maximizing reuse** of the fixed 5-layer Clean Architecture. New work concentrates in `presentation/` (a thin shell + one card-file-per-card under `widgets/cards/`, each a `ConsumerWidget` watching exactly one provider family with the shared `(bookId, startDate, endDate, joyMetricVariant)` key tuple and rendering its own `.when(data/loading/error)` for per-card isolation). The only genuinely-new sub-presentation work is at most **one read-only drill-down path** (`GetCategoryDrillDownUseCase` + `CategoryDrillDown` model + `AnalyticsDao.getCategoryTransactions` + index check). **Budget-vs-actual is the ONLY ask carrying a Drift migration** (needs a new `budgets` table; the use case is a `[]`-returning stub) — recommend explicit exclusion unless the gate elevates it.

**Major components:**
1. **`monthlyReportProvider` → savings-overview card** — pure reuse; zero new data work (the headline finding)
2. **Thin `analytics_screen.dart` shell + data-driven `_refresh()`** — replaces the 592-LOC monolith + 100-LOC manual invalidation; the data-driven refresh derives its invalidation set from the card registry, structurally guaranteeing no `home/*` provider is touched
3. **`widgets/cards/*`** — one file per card, reusing existing chart widgets (`MonthlySpendTrendBarChart`, `CategorySpendDonutChart`, `SatisfactionDistributionHistogram`) where the design keeps them
4. **Optional `state_analytics_layout.dart`** — SharedPreferences-backed card order (NOT Drift — must never enter family sync)

**Invariants that must survive the rebuild:** HomeHero isolation (`home_screen.dart` must not import `state_time_window`/`state_ledger_snapshot`; AnalyticsScreen must never read/invalidate `home/*` providers); `FamilyHappiness` stays aggregate-only (no per-member fields — type-enforced); `MonthlyReport.previousMonthComparison` stays unsurfaced (consumed by HomeHero only); single-Joy-expression (`grep density|joyPerYen lib/` == 0).

### Critical Pitfalls

1. **The anti-gamification trap** — "feel happy" silently becomes "gamified" because each step (a prominent fullness number → score; a target → goal-to-beat; "best category" → ranking; a 悦己 trend → soft cross-period comparison) feels innocent. **Avoid:** make it the explicit central question of the Phase 43 gate; each HTML direction carries an ADR-012 self-audit mapping every emotional element to *ambient/celebratory-of-the-past* (OK) vs *target/comparison/achievement* (forbidden), borrowing ADR-016 §5's line; reframe emotion as reflection not grading; new ADR if any direction grazes the boundary.
2. **Breaking HomeHero isolation / single-Joy-expression** — the cleanest-looking refactor ("share one joy provider between Home and Analytics") is exactly the forbidden coupling; a "value-for-money" story tempts reviving the retired density metric. **Avoid:** keep all windowed analytics providers in `features/analytics/` only; treat `home_screen_isolation_test.dart` + the `density|joyPerYen` grep as non-negotiable green gates in the FULL suite.
3. **Provider rebuild storms** — non-canonicalized `DateTime` family keys (microsecond-exact `==`) silently produce new provider instances → Drift refetch/jank storms; many cards each watching a whole large snapshot. **Avoid:** canonicalize every window boundary through `DateBoundaries`/`TimeWindow` before it reaches a family key; use `ref.watch(provider.select(...))`; scope invalidation; reuse reactive `readsFrom:` streams; profile on a real device before close.
4. **fl_chart churn (phantom upgrade or mid-redesign swap)** — pulling forward TOOL-V2-01 "upgrade to 2.x" (a version that doesn't exist), or any lib bump/swap that mixes render-engine diffs with intentional redesign diffs, makes goldens unattributable. **Avoid:** keep `^1.2.0`; retire/re-scope TOOL-V2-01; validate every chart affordance against the current API in Phase 43; never bundle a lib change into the visual diff.
5. **i18n / anti-toxicity copy regressions + scope creep + golden volume** — emotional copy attracts comparatives (更好/最棒/best/score) on *new* cards the existing sweeps don't cover; "全面大改" invites adjacent backlog; the chart widgets have NO golden coverage today so baselines are authored from scratch (macOS-only). **Avoid:** "anti-toxicity sweep added (ja/zh/en × all states)" is part of every card's definition-of-done; maintain ARB parity from the first commit + keep the 生存/灵魂 grep-ban green; lock scope to the 4 practical + 1 emotional feature in REQUIREMENTS.md; do golden re-baseline as its own macOS phase after visuals are final, with clean diff-attribution.

## Implications for Roadmap

Based on research, the user-mandated sequencing (design gate first) decomposes into:

### Phase 43: HTML Design Exploration Gate (DESIGN GATE — NO production code)
**Rationale:** The central anti-gamification question is unresolved until a direction is selected; building before the gate risks constructing a surface ADR-012 later rejects (rework). User requirement: "未获批前不进入开发."
**Delivers:** (a) a written current-impl map (the ARCHITECTURE.md reuse map is the seed); (b) multiple HTML design directions, each carrying an ADR-012 self-audit table (ambient-OK vs target/comparison/achievement-forbidden); (c) discussion → ONE selected direction; (d) a go/no-go on a new ADR if any direction grazes the boundary; (e) the locked emotional-vocabulary list for the anti-toxicity sweeps; (f) per-direction fl_chart affordance validation against the current API.
**Addresses:** the emotional "凸显悦己" thesis; resolves the central design question.
**Avoids:** Pitfall 1 (anti-gamification trap), Pitfall 4 (chart affordance assumptions), Pitfall 6 (scope/gate/vocabulary lock).
**Gate exit criterion:** user approves one direction. No Dart/production code committed.

### Phase 44: Data / Use-Case Additions (only what the selected design requires)
**Rationale:** Cards can't be built against use cases that don't exist; reuse-first keeps this phase small.
**Delivers:** confirm the selected direction against the §1 reuse map; build the ONE new read-only path if drill-down is in scope (`CategoryDrillDown` model + `GetCategoryDrillDownUseCase` + `AnalyticsDao.getCategoryTransactions` + index check), TDD; new providers wired in `repository_providers.dart` + `state_*.dart`. **Budget-vs-actual ONLY if the gate explicitly elevated it** (the one item carrying a v21→v22 Drift migration).
**Uses:** existing 13 reusable use cases; `DateBoundaries`/`TimeWindow` canonicalization (Pitfall 3).
**Avoids:** Pitfall 3 (canonicalized keys from the start), scope creep (budget excluded by default).

### Phase 45: Presentation Shell Rebuild
**Rationale:** The card contract (per-card AsyncValue.when, shared key tuple, isolation-safe refresh) must be in place before cards are filled in.
**Delivers:** thin `analytics_screen.dart` (AppBar + `TimeWindowChip` + `JoyMetricVariantChip` + scroll + card-list driver); data-driven `_refresh()` derived from the card registry; cards split into `widgets/cards/`.
**Implements:** the card-based dashboard component; carries the HomeHero isolation invariant forward.
**Avoids:** Pitfall 2 (no `home/*` reads/invalidations; isolation test stays green by construction).

### Phase 46: Cards
**Rationale:** Build/port each card once the shell contract exists.
**Delivers:** savings-rate overview (new, pure reuse), spend trend, category breakdown + drill-down entry, 悦己 narrative (design-gate-defined form), daily-vs-joy, best-joy/largest-expense stories, family (aggregate-only). Reuse existing chart widgets; adopt fl_chart 1.2.0 `label` (kill the histogram Stack hack) + `cornerRadius`. Optional customizable dashboard (`state_analytics_layout.dart` + SharedPreferences + `ReorderableListView`) lands here or as a sub-phase.
**Addresses:** all P1 features + selected P2 features.
**Avoids:** Pitfall 2 (aggregate-only family, no per-member; no density metric), Pitfall 4 (no lib bump).

### Phase 47: i18n + Anti-Toxicity Sweep + macOS Goldens + Full-Suite Gate + UAT
**Rationale:** Validate the finished surface; the golden baseline only stabilizes once visuals are final.
**Delivers:** ARB parity ja/zh/en for all new copy + `flutter gen-l10n` clean; **every new card added to the `anti_toxicity_phase16/17`-style sweep** (forbidden substrings render `findsNothing` in all 3 locales × all states); chart goldens authored + re-baselined **on macOS** (none exist today); full suite (incl. `home_screen_isolation_test.dart` + both anti-toxicity sweeps + architecture/CJK scans + density grep) as the per-wave milestone gate; on-device visual UAT.
**Avoids:** Pitfall 5 (copy regressions, ARB parity, golden volume/platform), Pitfall 6 (full-suite-per-wave, not scoped subsets).

### Phase Ordering Rationale

- **Design gate first is mandatory** — user requirement + the central ADR-012 question must close before any code; otherwise the emotional surface risks being built then rejected.
- **Data before presentation** — cards depend on use cases existing; reuse-first keeps the data phase minimal (most surfaces are pure reuse).
- **Shell before cards** — the per-card isolation contract and isolation-safe refresh must exist before cards are filled in.
- **i18n + goldens + sweeps last** — they validate the finished surface; goldens stabilize only when visuals are final and must be macOS-baselined without any lib bump in the diff.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 43:** The whole phase IS research/design exploration — the ADR-012 boundary classification of "neutral context" patterns (rolling band, reflection prompt) and the decision on whether a new ADR is needed are MEDIUM-confidence and must be resolved here. Use `/gsd-plan-phase --research-phase` framing for the current-impl deep-dive.
- **Phase 44:** Light research — verify income-capture reliability (the P1 gate) and the `(book_id, category_id, timestamp)` index need before committing the drill-down path.

Phases with standard patterns (skip research-phase):
- **Phase 45 (shell):** well-documented established pattern (existing card/provider organization is battle-tested across 6 milestones).
- **Phase 46 (cards):** reuse of existing chart widgets + provider idiom; the only novelty (drill-down card) is scoped in Phase 44.
- **Phase 47 (i18n/goldens/sweeps):** established codebase pipeline (ARB parity, anti-toxicity sweep template, macOS golden re-baseline).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | fl_chart latest-version + feature availability verified against pub.dev versions page + 1.2.0 changelog; no 2.x confirmed via primary sources |
| Features | HIGH | UX patterns from named best-in-class apps + kakeibo philosophy, cross-checked; MEDIUM only on the exact ADR-012 classification of a few "neutral context" patterns (flagged as Phase 43 decisions) |
| Architecture | HIGH | Reuse map, isolation mechanism, and anti-gamification enforcement all read directly from source/tests (live screen, 6 provider files, monthly-report use case, isolation + anti-toxicity tests, ADR-012/016) |
| Pitfalls | HIGH | Codebase-grounded — ADR-012/016, both structural tests, the chart widgets, and the provider graph read directly |

**Overall confidence:** HIGH

### Gaps to Address

- **Is income reliably captured today?** — the single biggest open risk; gates 结余率/收支总览 as P1. The app has historically been expense-centric. **Verify during Phase 44 (or as a Phase 43 input)** before committing the overview block; if income is sparse, savings rate is misleading.
- **The exact form of the 悦己 emotional surface** — a design decision deferred to Phase 43; the research constrains it (ADR-012 ambient-vs-discrete line) but does not pick it.
- **Whether a new ADR is needed** — depends on whether the selected direction grazes the ADR-012 boundary (e.g. a target/comparison-adjacent mechanic, or persisting user-authored reflection text). Decide at the Phase 43 gate, ratify before build.
- **Customizable/reorderable dashboard yes/no** — design decision for Phase 43; if yes, SharedPreferences-not-Drift is the constrained answer.
- **Neutral rolling-context ("about typical" band) allowability** — boundary-sensitive vs ADR-012 #4; only with a validated non-judgmental framing, likely needing a new ADR. Defer.
- **Budget-vs-actual in scope?** — the only ask carrying a Drift migration; recommend explicit exclusion in REQUIREMENTS.md unless the gate elevates it.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — fl_chart stay/upgrade/replace verdict; no 2.x; 1.2.0 `label`/`cornerRadius`; animation/dashboard stack; hard-NO list
- `.planning/research/FEATURES.md` — table stakes / differentiators / anti-features; kakeibo Q4 non-gamified precedent; feature dependencies + MVP + prioritization
- `.planning/research/ARCHITECTURE.md` — reuse map (13/15 use cases, savings-rate already computed); card contract; HomeHero isolation + anti-gamification enforcement; build order
- `.planning/research/PITFALLS.md` — 6 critical pitfalls; tech-debt/integration/perf/security/UX traps; phase assignment
- `.planning/PROJECT.md` — v1.8 goal, central design question, Out-of-Scope boundaries, ADR-012/016/017 constraints
- pub.dev `fl_chart` versions page + 1.2.0 changelog — latest is 1.2.0; `BarChartRodData.label` + `PieChartSectionData.cornerRadius` shipped (HIGH)
- `docs/arch/03-adr/ADR-012` + `ADR-016` + `home_screen_isolation_test.dart` + `anti_toxicity_phase16/17_test.dart` — read directly for the enforcement mechanism

### Secondary (MEDIUM confidence)
- YNAB / Monarch / Copilot / bizorca / TD MySpend UX references — drill-down, Sankey, emotional-intent categories, neutral rolling baseline (boundary reference)
- Kakeibo method sources (Penny Hoarder, SoFi, kakeibo-templates) — Q4 "spend more on what you enjoy" values-affirmation framing

### Tertiary (LOW confidence)
- A stale WebSearch result describing "fl_chart 2.0 migration (colors→color, y→toY)" — corrected: these are the 0.x→1.x-era changes mislabeled; the project already uses 1.x idioms

---
*Research completed: 2026-06-15*
*Ready for roadmap: yes*
