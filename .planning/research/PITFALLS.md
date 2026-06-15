# Pitfalls Research

**Domain:** Analytics/statistics-page full redesign (实用化 × 悦己情感化) in a local-first dual-ledger Flutter app under a permanent anti-gamification constraint
**Researched:** 2026-06-15
**Confidence:** HIGH (codebase-grounded — ADR-012/016, `home_screen_isolation_test.dart`, `anti_toxicity_phase16/17_test.dart`, the 4 fl_chart widgets, and the analytics provider graph were all read directly)

> Scope note: this is a v1.8 SUBSEQUENT-MILESTONE redesign. The pitfalls below are specific to *adding/redesigning* analytics surfaces in THIS system. Generic Flutter advice is omitted. The single highest-priority risk is the **anti-gamification trap** (Pitfall 1) because the milestone goal ("让用户为自己花钱而感到开心") is one design decision away from violating ADR-012.

---

## Critical Pitfalls

### Pitfall 1: The anti-gamification trap — "feel happy" silently becomes "gamified"

**What goes wrong:**
The milestone explicitly wants users to "feel good about spending on themselves." Every plausible emotional-framing idea sits on a gradient, and several land squarely in ADR-012 forbidden territory without anyone noticing, because each individual step feels innocent:

- A 悦己 "fullness/satisfaction" number rendered prominently → reads as a **score/points** (ADR-012 #2, Goodhart).
- A 悦己 progress element with a target → reads as a **goal-to-beat / achievement** the moment it has a discrete completion state, celebration animation, toast, or haptic (ADR-016 §5 already litigated this for HomeHero — the analytics surface must inherit the same rules).
- "本月悦己最多的分类 / your best joy category" framing → **"best" is a ranking** (forbidden EN `better/winner/rank`, ZH `更好/胜/排名`, JA `より良い/ランキング`).
- Any month-over-month / "vs last period" trend annotation on the 悦己 metric → **cross-period delta** (ADR-012 #4, ADR-016 §3 — permanent, cross-milestone).
- A 6-month 悦己 trend line that visually invites "is this month higher than before?" → soft cross-period comparison even without text.
- Per-member 悦己 contribution in family mode → **leaderboard** (ADR-012 #6).

The subtle failure: the *practical* half of the redesign (income/expense/savings-rate, spending trends, category drill-down) is comparison-heavy and that's fine for **expenses**; the trap is letting that comparison vocabulary and visual grammar bleed onto the **悦己** surfaces.

**Why it happens:**
"Make users feel good" and "celebrate progress" are the exact vocabulary of habit/gamification apps. Designers and the HTML exploration phase will naturally reach for streaks, badges, rings-with-confetti, "you beat last month," and rank framing because those are the field's defaults. Goodhart's Law (ADR-012 §💡): once the 悦己 number becomes a target, users optimize for "keep the number pretty" instead of honest self-spending — which destroys the very data v1.1/v1.2 were built to collect honestly. Family mode makes any comparison relationally toxic ("why is mom's joy score higher than mine?").

**How to avoid:**
1. **Make the trap the explicit central question of the Phase 43 design gate** (PROJECT.md already names it the "Central open design question"). Each HTML direction must carry an ADR-012 self-audit table mapping every emotional element to one of: *ambient/celebratory-of-the-past* (OK) vs *target/comparison/achievement* (forbidden). Borrow ADR-016 §3/§5's exact distinction: **ambient state rendering `f(progress)→color` is OK; discrete unlock/threshold events are forbidden.**
2. **Reframe emotion as reflection, not grading** (ADR-012's "celebrating, not grading"). Honest patterns: showing *what* 悦己 spending happened ("you nourished yourself with X this month"), surfacing a remembered moment (existing `BestJoyStory`), absolute cumulative `Σ joy_contribution` with no comparison baseline. Forbidden patterns: any "you did better/more/higher than [prior period / other member / target]."
3. **No "best category" framing.** If a top-悦己-category surface is wanted, frame it descriptively ("你最常悦己的方式") not comparatively ("你最棒的悦己分类"). Run it through the substring sweep (Pitfall 5).
4. **If any direction genuinely needs a new affordance that grazes the boundary, require a new ADR that explicitly amends ADR-012** (ADR-012 §决策: bans must be lifted by explicit ADR, never by PR). Do not let it slip in as "just UX."
5. **Extend the structural sweeps to every new 悦己 surface** (see Pitfall 5) — the gate must be compile-and-test, not copy-review.

**Warning signs:**
- HTML mockup contains: a progress bar/ring with a "100%!" state, a number labeled like a score, "vs 上月", "连续", a trophy/medal/confetti, a per-member sorted list, the words 更好/最棒/赢/best/top/rank.
- A design rationale sentence containing "成就感 / achievement / reward / streak / keep it up / beat."
- New ARB copy introducing comparative adjectives on a 悦己 string.
- A 悦己 trend chart where the current month is visually emphasized *relative to* prior months (emphasis-as-comparison).

**Phase to address:** **Phase 43 (HTML design-exploration gate)** is the primary defense — the gate must reject any direction that fails the ADR-012 self-audit *before* a line of build code. Build phases then inherit the structural-test enforcement (Pitfall 5).

---

### Pitfall 2: Breaking HomeHero isolation (ADR-016 §3) or the single-Joy-expression invariant

**What goes wrong:**
The redesign touches the same providers and use cases HomeHero depends on. Two structurally-locked invariants are easy to break by accident:

1. **HomeHero isolation** — `home_screen_isolation_test.dart` asserts (a) `lib/features/home/presentation/screens/home_screen.dart` source does **not** contain the strings `state_time_window`, `selectedTimeWindowProvider`, or `state_ledger_snapshot`; and (b) at runtime, an AnalyticsScreen time-window change or Joy-variant-toggle never re-invokes HomeHero's current-month use cases (verifyNever on `DateTime(2020)` window + verifyNever on the per-category/daily-vs-joy providers). A redesign that shares a provider, or "helpfully" routes HomeHero through a new windowed analytics provider, or makes an AnalyticsScreen refresh `ref.invalidate` a shared ancestor, breaks this.
2. **Single Joy expression** — `Σ joy_contribution = Σ(soul_satisfaction × (amount/base)^0.88)` is the *only* Joy metric (ADR-016 §2, Key Decision "single-Joy-expression"). `grep -rn 'density\|joyPerYen' lib/` must stay at 0. A redesign that reintroduces a per-yen / density / "joy efficiency" framing (tempting for a "practical" analytics page!) silently revives the retired metric.

**Why it happens:**
A "全面大改" naturally wants to unify data sources and add a richer windowed Joy view. The cleanest-looking refactor ("let HomeHero and Analytics share one joy provider") is exactly the forbidden coupling. The density metric is conceptually attractive for a "value-for-money" analytics story, so a designer asking "how much joy per yen am I getting?" reintroduces it without realizing it was deliberately retired.

**How to avoid:**
- Treat `home_screen_isolation_test.dart` as a **non-negotiable green gate** through every build phase; never edit it to "make room." If the redesign legitimately needs HomeHero to change, that is a separate, explicit decision — not a side effect of the analytics rewrite.
- Keep all new windowed analytics providers in `lib/features/analytics/`; never import `state_time_window` / `state_ledger_snapshot` into `lib/features/home/`.
- Add the density grep (`grep -rn 'density\|joyPerYen\|joyPer¥\|perYen' lib/` == 0) to the redesign's acceptance gate. If a "value" story is wanted, express it in absolute `Σ joy_contribution` terms, not a ratio.
- HomeHero ring stays single-month, current-month-anchored, target-filled per ADR-016 §3–§5 — unchanged by this milestone unless an ADR says otherwise.

**Warning signs:**
- A new shared provider imported by both `features/home/` and `features/analytics/`.
- `home_screen.dart` diff adds an analytics-provider import.
- Any `density`/`joyPerYen` token appearing in `lib/`.
- AnalyticsScreen mutation that calls `ref.invalidate` on a provider HomeHero also watches.

**Phase to address:** Every build phase; encode as a per-wave gate (the isolation test + density grep must be in the full-suite run, not a scoped subset — see Pitfall 6).

---

### Pitfall 3: Provider rebuild storms — many cards × many `(bookId, startDate, endDate)`-keyed Drift providers

**What goes wrong:**
The analytics presentation layer already has ~30 `@riverpod` providers, most keyed by a `(String bookId, DateTime startDate, DateTime endDate)` tuple, each firing its own Drift query (`state_ledger_snapshot.dart`, `state_happiness.dart`, `state_analytics.dart`). A "全面大改" adds more cards (收支总览, 结余率, 6-month trend, category drill-down) → more keyed providers → more independent queries. Two specific failure modes:

1. **DateTime key non-canonicalization.** Riverpod family keys compare by `==`. `DateTime` equality is exact-microsecond. If any call site constructs `startDate`/`endDate` with even slightly different sub-fields (e.g. `DateTime.now()`-derived vs `DateTime(y,m,1)`), the family produces a *new* provider instance and re-runs every downstream Drift query — a silent rebuild/refetch storm. The existing `time_window` validation + `DateBoundaries` util exist precisely because of this; new code must reuse them.
2. **Fan-out invalidation.** A pull-to-refresh or a window change that invalidates a broad ancestor cascades into 6–10 simultaneous Drift queries + chart re-layouts, causing jank on first paint and on every refresh.

**Why it happens:**
Each card is independently authored and "just adds a provider." DateTime keys look harmless until two construction sites diverge. The drill-down feature multiplies provider count (per-category sub-queries). fl_chart re-layout on every rebuild compounds the cost.

**How to avoid:**
- **Canonicalize all window boundaries through the existing `DateBoundaries` util / `TimeWindow` value object** before they reach a provider family key. Never pass a raw `DateTime.now()`-derived value as a family arg. Consider keying families on a normalized `(year, month)` or a `TimeWindow` value type with stable `==` instead of two `DateTime`s.
- **Select narrowly.** Use `ref.watch(provider.select(...))` so a card rebuilds only when its slice changes, not on every field of a large snapshot.
- **Keep heavy aggregation in the use-case/DAO layer (one query per concept), not recomputed in `build()`** of a card or provider.
- **Scope `ref.invalidate` to the specific providers that changed**, mirroring the v1.4 calendar-isolation Key Decision ("Calendar provider isolated from filter state — watching search/filter would re-render 31 cells per keystroke"). The same lesson applies to a drill-down: the category list provider must not re-run when an unrelated card's state changes.
- **Reuse the reactive-Drift `readsFrom:` stream pattern mandated since v1.6 (Phase 36)** rather than manual broad invalidation, so only genuinely-changed data triggers a rebuild (the v1.4 GAP-2 dead-stream lesson).
- **Profile the assembled screen on a real device** (or via a widget perf test) before milestone close; charts + many providers is exactly the "works in tests, janks on device" class.

**Warning signs:**
- `DateTime` constructed inline at a widget/provider call site instead of via `DateBoundaries`.
- A card whose provider re-runs on unrelated state changes (visible as repeated Drift query logs).
- First-paint jank or refresh stutter on the redesigned screen on device.
- A drill-down that re-queries the parent category list on every sub-selection.

**Phase to address:** The data/provider-wiring build phase; verify with a device perf pass before close.

---

### Pitfall 4: fl_chart migration / chart-library churn — speculative upgrade or mid-redesign swap

**What goes wrong:**
Two distinct risks:

1. **Pulling forward the backlog "fl_chart 1.x→2.x upgrade" (TOOL-V2-01) inside the redesign.** Important reality check: the repo is on `fl_chart: ^1.2.0`, and **fl_chart 2.0 is not released** (as of June 2026 the line is 1.x). The painful breaking migration — `y`→`toY`, `tooltipBgColor`→`getTooltipColor`, `FlTitlesData`/`AxisTitles`/`SideTitles` restructure, `getTitlesWidget` returning a `Widget` — was the **0.x→1.0** break, and the existing 4 chart widgets **already use the post-1.0 API** (`toY`, `getTooltipItem`, `getTitlesWidget`-returning-`Widget`). So "upgrade to 2.x" is upgrading to a version that doesn't exist; doing it on spec is wasted churn and re-baselines every chart golden for no user value.
2. **Swapping chart libraries (or even bumping fl_chart) mid-redesign.** Any chart-lib change re-renders pixels → forces golden re-baselining on top of the redesign's own golden churn, making it impossible to attribute a diff to "intended redesign" vs "library rendering change" (the v1.5 Phase 34 diff-attribution discipline exists for exactly this reason).

A real, narrower fl_chart limitation does exist in this codebase: tooltips/labels are per-*group* via `getTooltipItem(group, groupIndex, rod, rodIndex)`, and there is **no per-rod persistent inline label API** in the current usage — if a design direction calls for always-on per-bar value labels (common in "practical" analytics mockups), it must be built with overlaid widgets / `getTitlesWidget`, not assumed to be a chart feature.

**Why it happens:**
A "全面大改" feels like the natural moment to "finally do the chart upgrade." The backlog item's wording ("fl_chart 1.x→2.x") implies a clean target that isn't real. Designers assume any label/annotation a charting library *could* show is available.

**How to avoid:**
- **Do NOT bundle a chart-library version bump or swap into the visual redesign.** Keep `fl_chart ^1.2.0`. If a genuine fl_chart minor bump is needed for a specific feature, do it as an isolated step with its own golden-attribution pass *before* the redesign, never interleaved.
- **Treat "fl_chart 2.x" as not-yet-existing**; don't plan against it. Revisit TOOL-V2-01 only when an actual 2.0 ships and a feature needs it.
- **Validate every chart affordance in a design direction against the current API** during Phase 43: per-rod inline labels = overlay/`getTitlesWidget`, not native; donut center content, legends, touch tooltips = supported. Flag any "chart can do X" assumption for a 30-min spike before committing the direction.
- If new chart types are needed (savings-rate gauge, stacked income/expense), confirm fl_chart 1.2 supports them; otherwise design within what it offers rather than reaching for a new library.

**Warning signs:**
- A plan task titled "upgrade fl_chart" or "migrate to fl_chart 2".
- A design direction assuming always-visible per-bar value labels.
- A golden diff that mixes layout changes with anti-aliasing/render-engine changes (signals a library bump crept in).
- A new charting dependency added to `pubspec.yaml`.

**Phase to address:** Phase 43 (validate chart affordances per direction) + the chart-build phase (no library churn; attribute goldens cleanly).

---

### Pitfall 5: i18n / anti-toxicity copy regressions across ja/zh/en (emotional framing introduces judgment words)

**What goes wrong:**
The emotional reframing introduces lots of new copy in three locales, and emotional copy is precisely where comparative/judgment words sneak in. The repo already has **two locked structural sweeps** that will fail (correctly) if a forbidden substring is rendered:

- `anti_toxicity_phase16_test.dart` — sweeps `PerCategoryBreakdownCard` + `DailyVsJoyCard` across en/ja/zh × 4 states for forbidden substrings. Locked lists include EN `better/worse/winner/loser/vs/compare/comparison/score/rank/ranking/wins/loses`, ZH `更好/更差/赢/输/胜/败/对比/比较/排名/分数/胜出/落败`, JA `勝ち/負け/より良い/より悪い/比較/対決/スコア/ランキング/勝つ/負ける`.
- `anti_toxicity_phase17_test.dart` — sweeps the `JoyMetricVariantChip` across en/ja/zh × every `JoyMetricVariant` for *data-quality-judgment* words (ZH `不准/不可靠/不完整/质量差/估算不准/错误`, JA `不正確/信頼できない/不完全/精度が低い/誤り`).

Separately: **ARB parity is a hard gate** (key parity locked across ja/zh/en; `flutter gen-l10n` must succeed with no warnings; old vocabulary 生存/灵魂/Survival/Soul is grep-banned per ADR-017). New emotional copy that adds a key to one locale but not the others, or reuses retired vocabulary, breaks the build/gate.

The failure: a new emotional string like "你这个月悦己得更好了" (更好), "your best joy category" (best→adjacent to rank), or "joy score" (score) renders on a *new* card the existing sweeps don't cover → ships a regression because the new surface was never added to the sweep.

**Why it happens:**
Emotional, encouraging copy gravitates to comparatives ("更/most/best/higher"). New cards are authored without extending the forbidden-substring sweeps to cover them (the sweeps are per-widget — a brand-new card is unguarded by default). Trilingual authoring makes it easy to drift one locale.

**How to avoid:**
- **Extend the anti-toxicity sweep to every new/redesigned analytics widget** in the same milestone, in all three locales × all rendered states (the phase16 test is the template: pump the whole card, assert `find.textContaining(substring)` findsNothing). A new card without a sweep is an unguarded surface — treat "sweep added" as part of the card's definition-of-done.
- **Review the locked forbidden lists and extend them** for the new emotional vocabulary the redesign introduces (e.g. add 最棒/最好/排行/超过 / "top"/"beat"/"most" if any direction flirts with them). Relaxing a list requires explicit ADR-012 sign-off (the test comment says so); *adding* forbidden words is encouraged.
- **Maintain ARB key parity from the first commit** — add every new key to all three ARB files together, run `flutter gen-l10n` clean, keep the 生存/灵魂/Survival/Soul grep-ban green.
- **Prefer descriptive over comparative copy** as a standing rule for 悦己 strings (ties to Pitfall 1).
- Thread `locale` correctly into every new card (note the known v1.5 carry-over: `ListTransactionTile` renders an internal date in `ja` regardless of locale — don't repeat that locale-threading bug in new analytics widgets).

**Warning signs:**
- A new analytics card with no corresponding entry in an `anti_toxicity_*_test.dart`.
- ARB key added to one locale only (gen-l10n parity failure).
- New copy containing 更/最/超过/vs/top/best/score in any locale.
- `flutter gen-l10n` warnings.

**Phase to address:** Each UI build phase (sweep + ARB parity per card); a copy-review checkpoint folded into the Phase 43 direction selection (lock the emotional vocabulary before building).

---

### Pitfall 6: Scope creep + short-circuiting the design gate + golden re-baseline volume

**What goes wrong:**
"全面大改" is unbounded by name. Three coupled process failures:

1. **Scope creep** — the redesign pulls in adjacent backlog (income tracking, month-lock/结账锁月, undo-on-delete, combined family-calendar totals, multi-currency analytics sub-totals, the fl_chart upgrade) because "we're rewriting analytics anyway." Several of these are explicitly Out of Scope or are separate DB-migration work.
2. **Short-circuiting the Phase 43 gate** — building before the HTML direction is selected/approved (PROJECT.md: "未获批前不进入开发"). Because the central anti-gamification question is *unresolved until the gate closes*, building early risks constructing a surface that the gate later rejects on ADR-012 grounds → rework.
3. **Golden re-baseline volume** — a full visual overhaul re-bases most of the ~25 analytics/joy golden masters (and any new ones). Plus a critical gap: the **chart widgets (`MonthlySpendTrendBarChart`, `CategorySpendDonutChart`, `SatisfactionDistributionHistogram`) appear to have NO golden coverage today** — adding them under redesign means new baselines authored from scratch, and goldens are **macOS-baselined only** (CI on ubuntu uses `BaselineExistenceGoldenComparator`; never pixel-match cross-platform — see MEMORY golden-CI gate). A re-baseline done on the wrong platform, or mixed with a library bump, produces unattributable diffs.

**Why it happens:**
Rewrites invite "while we're here" additions. The gate feels like a delay when momentum is high. Golden churn is underestimated because the chart-coverage gap isn't visible until someone tries to add it.

**How to avoid:**
- **Hold the Phase 43 gate as a hard precondition.** No build-phase work merges until a single direction is approved and its ADR-012 self-audit passes. If a new ADR is needed (Pitfall 1), ratify it *before* build.
- **Lock scope to the four named practical features + the one emotional feature** (收支/结余率总览, 支出趋势, 分类下钻, 悦己叙事). Explicitly defer at planning time: income *tracking* (vs income/expense *overview*), month-lock, undo-on-delete, combined family-calendar totals, per-currency analytics sub-totals (CUR-V2-02), and the fl_chart bump (Pitfall 4). Write these into Out of Scope in REQUIREMENTS.md.
- **Budget golden re-baseline as its own phase/step** (mirror v1.5 Phase 34: isolated re-baseline with diff-attribution), done on **macOS**, *after* visual changes are final and *without* any library bump in the same diff. Add chart goldens deliberately (light/dark × locales) since none exist today.
- Keep the full test suite (incl. `home_screen_isolation_test.dart` + both anti-toxicity sweeps + architecture scans) as the per-wave gate — the v1.6 Phase 38 lesson: scoped test subsets miss architecture/CJK-scan tests; run the FULL `flutter test` per wave.

**Warning signs:**
- A REQUIREMENTS.md or plan that includes income-tracking/month-lock/undo/family-calendar/fl_chart inside v1.8.
- Build-phase commits landing before a Phase 43 direction is marked approved.
- A single PR diff containing both visual changes and a chart-library bump.
- Golden masters generated/updated on a non-macOS machine.
- A per-wave gate running a scoped test list instead of the full suite.

**Phase to address:** Phase 43 (gate + scope lock + emotional-vocabulary lock); a dedicated golden-re-baseline phase near the end; roadmap-level scope boundaries in REQUIREMENTS.md.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip adding an anti-toxicity sweep for a new analytics card | One less test to write per card | New 悦己 surface is unguarded; a `更好/best/score` regression ships silently in any locale | Never — sweep is part of a card's definition-of-done |
| Pass raw `DateTime.now()`-derived values as provider family keys | Fewer lines than canonicalizing | Provider-family key explosion → silent Drift refetch/rebuild storm | Never — always canonicalize via `DateBoundaries`/`TimeWindow` |
| Reintroduce a "joy per yen / efficiency" view for the "practical" story | Satisfies a "value for money" design ask | Revives the ADR-016-retired density metric; breaks single-Joy-expression invariant + grep gate | Never (without an ADR superseding ADR-016 §2) |
| Bundle the fl_chart bump into the redesign | "Do it while we're here" | Unattributable golden diffs; upgrading to a non-existent 2.x | Never inside this milestone; isolate any real bump with its own attribution pass |
| Build a direction before the Phase 43 gate approves it | Faster start | Rework if the gate rejects it on ADR-012 grounds | Never — gate is a hard precondition |
| Re-baseline goldens mixed with logic changes, on non-macOS | One commit | Can't attribute pixel diffs; CI can't pixel-match off macOS | Never — isolated, macOS, post-finalization |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| HomeHero ↔ AnalyticsScreen providers | Sharing a provider / importing `state_time_window` or `state_ledger_snapshot` into `features/home/` for code reuse | Keep windowed analytics providers in `features/analytics/` only; `home_screen_isolation_test.dart` source-string + verifyNever gates must stay green |
| fl_chart tooltips/labels | Assuming always-on per-rod inline value labels exist | Per-group `getTooltipItem` only; build persistent per-bar labels with overlay widgets / `getTitlesWidget` |
| Drift analytics queries | Recomputing aggregation in provider/widget `build()`; broad `ref.invalidate` on refresh | One query per concept in DAO/use-case; reactive `readsFrom:` streams; scope invalidation to changed providers |
| ARB / `flutter gen-l10n` | Adding an emotional key to one locale; reusing 生存/灵魂/Survival/Soul | Add keys to ja/zh/en together; keep gen-l10n clean + ADR-017 grep-ban green |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `DateTime` family-key non-canonicalization | Repeated identical Drift queries; cards re-fetch on no-op state changes | Canonicalize boundaries via `DateBoundaries`/`TimeWindow` value type with stable `==` | As soon as two call sites construct the boundary slightly differently |
| Many cards each watching a large snapshot whole | Whole-screen rebuild on any field change; first-paint jank | `ref.watch(provider.select(...))` per card slice | Grows with card count (this redesign adds several) |
| Category drill-down re-querying the parent list per sub-selection | Stutter on each drill interaction | Isolate the parent-list provider from sub-selection state (v1.4 calendar-isolation lesson) | When a user actively drills categories |
| fl_chart re-layout on every rebuild | Janky charts on refresh/scroll on device | Stable inputs + narrow rebuilds; profile on real device, not just widget tests | On lower-end Android (API 24+ target) with multiple charts |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| New family-mode 悦己 surface exposing per-member breakdown | Relational harm (leaderboard) + privacy regression | ADR-012 #6: aggregate-only family return types (existing `FamilyHighlightsSum: int` / `SharedJoyInsight` tuple); no per-member sorted surface |
| Logging or surfacing decrypted note/amount detail in a new drill-down | Leaks sensitive financial data | Keep decryption at repository boundary; never log sensitive data (CLAUDE.md crypto rules); display only what the existing use cases already expose |
| Analytics querying across family books without the existing privacy gates | Cross-member data leak | Reuse the established `*_across_books` use cases + shadow-book aggregation that already encode the gates |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Emotional framing that grades ("you did better/worse this month") | Self-judgment, anxiety — the exact harm ADR-012 prevents | Reflective, descriptive framing of *what* 悦己 spending happened; absolute cumulative, no baseline |
| Savings-rate / 结余率 shown without context on a sparse month | A misleading or alarming number when data is thin | Honest empty/low-data states (the codebase already does min-N=3 filters + thin-sample fallbacks — reuse that pattern) |
| Charts with no empty/low-N state | Meaningless or broken visuals when n<3 | Explicit empty + sub-min-N states (existing `PerCategoryBreakdownCard` min-N=3 + Other rollup is the model) |
| Locale not threaded into a new card's internal dates/numbers | Wrong-language dates/numbers (the known `ListTransactionTile` ja bug) | Thread `locale`/`currentLocaleProvider` through every formatter call (CLAUDE.md i18n rules) |

## Summary — phase assignment at a glance

| Pitfall | Primary phase to address |
|---------|--------------------------|
| 1. Anti-gamification trap | **Phase 43 design gate** (ADR-012 self-audit per direction; new ADR if boundary-grazing) |
| 2. HomeHero isolation / single-Joy-expression | Every build phase (isolation test + density grep as gates) |
| 3. Provider rebuild storms | Data/provider-wiring phase (+ device perf pass before close) |
| 4. fl_chart churn | Phase 43 (affordance validation) + chart-build phase (no library bump) |
| 5. i18n / anti-toxicity copy | Each UI build phase (sweep + ARB parity per card) + Phase 43 vocabulary lock |
| 6. Scope creep / gate / goldens | Phase 43 (scope + gate lock) + dedicated macOS golden-re-baseline phase |

## Sources

- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — forbidden-features list, Goodhart rationale, "bans lifted only by explicit ADR" (HIGH)
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §2 single Joy expression, §3 HomeHero isolation, §5 100%-behavior ambient-vs-discrete distinction (HIGH)
- `test/widget/.../home_screen_isolation_test.dart` — structural isolation enforcement (source-string + verifyNever) (HIGH)
- `test/widget/.../anti_toxicity_phase16_test.dart` + `anti_toxicity_phase17_test.dart` — locked forbidden-substring lists per locale (HIGH)
- `lib/features/analytics/presentation/widgets/{monthly_spend_trend_bar_chart,category_spend_donut_chart}.dart` — current fl_chart 1.x API usage (`toY`, `getTooltipItem`, `getTitlesWidget`) (HIGH)
- `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` — `(bookId, startDate, endDate)` family-key pattern (HIGH)
- `.planning/PROJECT.md` — v1.8 goal, Out-of-Scope boundaries, ADR-017 ARB parity gate, golden-CI/Drift constraints, density grep Key Decision (HIGH)
- [fl_chart CHANGELOG (GitHub)](https://github.com/imaNNeo/fl_chart/blob/main/CHANGELOG.md) — confirms the breaking `y`→`toY`/`tooltipBgColor`→`getTooltipColor`/titles-restructure was the 0.x→1.0 migration (already adopted); 2.x not yet released (MEDIUM — web)
- [fl_chart releases](https://github.com/imaNNeo/fl_chart/releases) — current line is 1.x as of June 2026 (MEDIUM — web)
```
