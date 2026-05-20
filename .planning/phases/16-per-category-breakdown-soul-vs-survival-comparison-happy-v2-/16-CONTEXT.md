# Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01) - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 16 extends AnalyticsScreen Variant ε with two new descriptive surfaces:

1. **HAPPY-V2-01 — Per-Category satisfaction breakdown.** Soul-ledger only. Lists categories with `avg satisfaction / entry count` within the active Phase 15 time window. Respects min-N filtering (categories with <3 entries grouped into an "Other" fold row). Default view shows top 5, with "show all" expansion.

2. **STATSUI-V2-01 — Soul-vs-Survival comparison surface.** Re-framed as an **engagement axis** (not satisfaction axis) because `transactions.soul_satisfaction` defaults to `2` and the satisfaction picker only renders for soul-ledger entries — a raw `AVG(soul_satisfaction)` over survival rows is structurally meaningless. Compares both ledgers on `entry count + total spend` shared metrics; Soul column additionally carries `avg satisfaction` (single-sided, because only soul has explicit user ratings). Descriptive copy only — no value-judgment language.

Both surfaces follow Phase 15's `selectedTimeWindowProvider` and re-query on window change. Both live in AnalyticsScreen's existing **Distribution** section group (no new section group introduced).

**In scope:**
- Soul-ledger per-category breakdown card with sorted list, min-N "Other" fold row, top-5 default + "show all" expansion.
- Soul-vs-Survival comparison card with side-by-side two-column mini-card layout (Soul column / Survival column).
- New DAO method(s) for the per-category aggregate (analogous to `getSharedJoyCategoryInsight` but returning the full list, not just argmax).
- Group-mode behavior: Per-Category renders as **two stacked cards** (You + Family) within the Distribution group; Soul-vs-Survival renders as a **2×2 grid** (rows = You / Family; columns = Soul | Survival).
- Application-layer use cases respecting `(startDate, endDate)` window contracts established in Phase 15.
- ARB ja/zh/en parity for all new strings; `S.of(context)`; `DateFormatter` and project formatter infrastructure for any displayed dates/numbers.
- Goldens for both surfaces in light + dark themes (per current theme support in the project).
- Widget tests asserting absence of forbidden value-judgment language in all three locales.
- ADR-012 §6 compliance: no per-family-member breakdown anywhere — only ledger-type and you/family ledger-aggregate axes.

**Out of scope:**
- New analytics capabilities beyond the two surfaces above.
- HomeHero changes — HomeHero remains current-month-anchored and is not affected.
- Cross-period delta UI (forbidden by ADR-012 §4).
- Per-family-member surfaces (forbidden by ADR-012 §6).
- Any change to the satisfaction picker, `soul_satisfaction` semantics, or ADR-014 defaults.
- Any change to Phase 15 `selectedTimeWindowProvider`, TimeWindowChip, TimeWindowPickerSheet, or the time-window validation rules.
- Survival-ledger satisfaction rating (not introduced; ADR-014 picker remains soul-only).
- Custom-window or filter UI beyond what Phase 15 already provides.
- AnalyticsScreen Variant ζ or further visual redesigns beyond inserting these two cards.

</domain>

<decisions>
## Implementation Decisions

### Soul-vs-Survival Comparison Semantics (Area 1 — Survival 满足度的语义陷阱)

- **D-01: Re-frame Soul-vs-Survival as an "engagement axis", NOT a satisfaction axis.** The ROADMAP-supplied example "Soul ledger averages 7.4 satisfaction; survival ledger 5.1" is replaced with engagement metrics because `transactions.soul_satisfaction` defaults to `2` and the picker only appears for soul-ledger entries (per ADR-014). A raw `AVG(soul_satisfaction)` over survival rows would be dominated by the default value and read as "survival = always unhappy", which is an anti-toxicity reverse-pattern.
  - **Why:** ADR-014 D-10 explicitly accepts the picker `Neutral=1` vs default `2` collision and the absence of a survival-ledger picker. Phase 16 honors that asymmetry rather than papering over it with a misleading number.
  - **What this overrides:** ROADMAP Phase 16 Success Criteria 3 example wording. The wording must be corrected in the plan-phase task list (see D-12 below).

- **D-02: Shared metrics for the comparison surface are `entry count + total spend`.** No `avg/tx`, no spend percentage. Both ledgers expose the same two numbers in the same vertical order. This keeps the comparison purely descriptive and avoids implicit ranking (`avg/tx` would whisper "single-tx cost"; spend share would whisper "you spend more on X").

- **D-03: Soul column carries an additional `avg satisfaction` row.** Single-sided by design — Soul has user ratings, Survival does not. The asymmetry is the product truth (one ledger has a picker; the other does not) and must be visible in the surface, not hidden behind a forced-symmetric AVG. The presence of `avg satisfaction` on Soul only is, in itself, a small statement of "soul-ledger gets intentional rating".

- **D-04: Survival ledger never displays a "satisfaction-derived" number in this surface.** No `avg(sat)` row on Survival, no Joy/¥ proxy, no rating-derived score. Survival numbers stay strictly "what was logged" (count + spend).

- **D-05: Empty state — if either ledger has 0 entries within the active window, the entire Soul-vs-Survival card renders Empty.** Consistent with `SharedJoyInsight` Empty semantics: no half-populated comparison. Empty copy is descriptive ("No data this window") — no "you haven't logged enough" framing.

### Per-Category Breakdown Card (Area 2 — 卡片形态与排序)

- **D-06: Card form is a vertical ranked list (one row per category).** Each row: leading category icon/emoji + localized name, trailing `avg sat / N entries`. Matches the SharedJoyInsight one-line expression already in v1.1 patterns. No mini-bars, no donut, no table layout — these introduce visual ranking semantics that bleed toward gamification.

- **D-07: Sort axis is `avg satisfaction DESC, count DESC, category_id ASC` — the exact same tie-break order as `getSharedJoyCategoryInsight`.** Consistency with the family-aggregate equivalent matters more than alternative sort theories (count-first, mixed scores). The product question "which categories bring the most joy" maps directly to this ordering.

- **D-08: <3 entries categories are grouped into a single "Other" fold row.** The fold row shows aggregate count (`Other: N entries across M categories`); it is NOT expanded by default and NOT included in the main sort. This preserves the "single-data-point categories never crowned" requirement (SC-2) while keeping the information visible ("there are low-frequency entries elsewhere"). Tap behavior on Other (expand inline vs noop) is planner discretion.

- **D-09: Default view shows top 5 categories above the "Other" row, with an "expand all" affordance to reveal categories ranked 6+ (still respecting min-N).** The 5-row default matches Variant ε card-density expectations. Categories that fail min-N never appear in the expansion either — they remain in the Other fold.

- **D-10: "Other" fold-row aggregate metrics are entry count only (NOT an averaged avg satisfaction).** Averaging averages across heterogeneous low-N categories produces a meaningless number; show only `Other: N entries across M categories` to avoid the false signal. Sorting and crowning never apply to the Other row.

### Soul-vs-Survival Visual Frame (Area 3 — 视觉范式 & 插入位置)

- **D-11: Card form is a side-by-side two-column mini-card.** Single `Card` container with two equal-width columns separated by a thin divider. Left column = Soul (sage green accent `#47B88A` per project palette); right column = Survival (blue accent `#5A9CC8` per project palette). Each column shows its metrics top-down: header count → spend → (Soul only) avg sat.

- **D-12: Section header language frame is "Ledger · This window" (en) / "本月账本描述" (zh) / "今期の家計簿" (ja).** Avoids "comparison"/"vs"/"versus" framing. ARB key recommendation: `analyticsCardTitleLedgerThisWindow`. Section header line stays consistent with existing Variant ε header style (`'Total · ...'` / `'Joy · ...'`). The phrase "This window" generalizes for week / month / quarter / year / custom selection.

- **D-13: Both new cards live in the AnalyticsScreen `Distribution` section group, NOT in a new section.** Insertion order (recommended, planner may refine within group):
  1. `_CategoryDonutCard` (existing)
  2. `_SoulVsSurvivalCard` (new — STATSUI-V2-01)
  3. `_SatisfactionHistogramOrFallback` (existing)
  4. `_PerCategoryBreakdownCard` (new — HAPPY-V2-01)
  - Stories group remains BestJoy + LargestExpense + (group-mode) FamilyInsight, unchanged in this phase.

- **D-14: Anti-toxicity forbidden-substring list is planner discretion, derived from ADR-012 + ADR-014 + project copy conventions.** Plan must explicitly produce the trilingual forbidden list and the widget test asserting absence in rendered output. Required minimum coverage:
  - **en:** `better`, `worse`, `winner`, `loser`, `vs`, `versus`, `compare`, `higher is good`, `lower is bad`, `score`, `rank`
  - **zh:** `更好`, `更差`, `赢`, `输`, `胜`, `败`, `vs`, `对比`, `比较`, `排名`, `分数`
  - **ja:** `勝ち`, `負け`, `より良い`, `より悪い`, `比較`, `対決`, `スコア`, `ランキング`
  - Planner adds more if locale review surfaces additional risk patterns.

- **D-15: ROADMAP Phase 16 Success Criteria 3 wording correction is a plan-task deliverable.** The example "Soul ledger averages 7.4 satisfaction; survival ledger 5.1" must be rewritten in `.planning/ROADMAP.md` to reflect the engagement-axis decision (D-01..D-04). Suggested replacement wording: *"...displaying both ledgers' engagement metrics (entry count + total spend; Soul column additionally shows average satisfaction). Copy is descriptive only — no value-judgment terms (better/worse/winner/loser/vs framing) — verified by ARB review + widget assertion of forbidden-substring absence in all three locales."* — Phase 16 plan's first task list item.

### Group/Family Mode (Area 4 — Group mode 行为)

- **D-16: In `isGroupMode = true`, both surfaces show the You-vs-Family aggregation; per-family-member breakdown is forbidden (ADR-012 §6).** "Family aggregate" means `SELECT ... WHERE book_id IN (shadowBooks)` — never `GROUP BY book_id` or any per-member projection. This is type-system-enforced via the existing FamilyHighlightsSum + SharedJoyInsight contracts; Phase 16 inherits the same contract.

- **D-17: Per-Category in group mode renders as TWO STACKED CARDS within the Distribution group.** Top card "You · Top categories" (current book, top 5 + Other fold); bottom card "Family · Top categories" (group aggregate, top 5 + Other fold). Cards use the same internal layout and sort rules (D-06..D-10) — the only difference is the underlying `WHERE` clause and the header copy.
  - **Why two cards, not one merged card:** family aggregation uses a different DAO query shape (`book_id IN (...)`); merging into one card would either mix sources visually or require a sub-tab affordance that adds UI complexity. Two cards keeps each surface honest about its data source.

- **D-18: Soul-vs-Survival in group mode renders as a 2×2 grid in a single card.**
  - Row 1: "You · Soul" | "You · Survival"
  - Row 2: "Family · Soul" | "Family · Survival"
  - Same engagement metrics in every cell (count + spend; You · Soul and Family · Soul additionally show avg sat). Single Card container preserves the "Ledger · This window" header.
  - **Why a single card with grid (not 4 cards or 2 cards):** the 2×2 grid is the cleanest expression of two crossing axes (you/family × soul/survival). It reads as "snapshot" not "scoreboard" because no cell visually outranks another — all four cells share equal weight, alignment, and styling.

- **D-19: The asymmetry between Per-Category (2 stacked cards) and Soul-vs-Survival (1 card with 2×2 grid) is intentional and accepted.** Per-Category is "Top-N ranked lists for two scopes" — list layouts don't tile cleanly into a grid; stacked cards is the right shape. Soul-vs-Survival is "two crossing axes" — grid is the right shape. The two surfaces are different "shape problems" and must be allowed different solutions.

- **D-20: When `isGroupMode = true` but `shadowBooksProvider` returns 0 or 1 book, Family rows/cards fall back to Empty.** "Family" only makes sense with ≥2 books in the group. Empty copy stays descriptive ("Family data not available this window") — no "add family member" prompt (out of scope for Phase 16).

### Planner / UI-Spec Discretion

- **Exact ARB key names** for new strings, beyond the recommendations above. Subject to ja/zh/en parity and `S.of(context)` usage.
- **Card padding, divider width, column dividers, and exact icon/typography in cells** — UI-spec deliverable; must adhere to Variant ε card density conventions.
- **Tap behavior on the per-category list rows and the Other fold row** — planner discretion. Recommended: noop in Phase 16 (no transaction-list drill-in). Inline expansion for Other is acceptable if it stays compact.
- **Tap behavior on Soul-vs-Survival cells** — noop in Phase 16. Future drill-in is deferred.
- **DAO query shape for per-category breakdown** — planner picks between (a) a new `getPerCategorySoulBreakdown(bookId, startDate, endDate)` returning a list of `(category_id, avg_sat, count)` rows with `HAVING COUNT >= 3`, sorted by `AVG DESC, COUNT DESC, category_id ASC`, plus a parallel "low-N" count query for the Other row; or (b) a single query returning all categories, with min-N filtering and Other aggregation in Dart. Both acceptable at v1.2 volumes; (a) is closer to the SharedJoyInsight precedent.
- **Group-aggregate DAO query shape** — analogous structure to `getSharedJoyCategoryInsight` but returning a list (no `LIMIT 1`). Planner decides whether to extend that DAO method with an `aggregate: bool` flag or add a new method `getPerCategorySoulBreakdownAcrossBooks(bookIds, startDate, endDate)`. Recommendation: separate method for clarity (the existing method's `LIMIT 1` is semantic, not incidental).
- **Use case + provider naming** — follow established conventions (`GetPerCategorySoulBreakdownUseCase`, `getPerCategorySoulBreakdownProvider` in `state_happiness.dart` or a new `state_category_breakdown.dart`).
- **Localized category names** flow through `CategoryLocaleService` (`lib/infrastructure/category/category_locale_service.dart`); planner verifies the existing path works for the new list surface.
- **Refresh / invalidation wiring** — extend `_refresh()` in `analytics_screen.dart` to invalidate the two new providers when their `(startDate, endDate)` keys are active. HomeHero and Home tab providers MUST NOT be invalidated (D-12 in Phase 15 CONTEXT is binding).
- **Theme support and goldens** — current project theme support determines whether goldens cover both light + dark; planner verifies in the UI-spec step.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — v1.2 milestone goal, Joy-axis focus, Family privacy hardening deferred (FAMILY-V2-01/02/03 stay out of v1.2 — relevant because Phase 16 must NOT introduce per-family-member surfaces).
- `.planning/REQUIREMENTS.md` — HAPPY-V2-01, STATSUI-V2-01; cross-phase constraints (ADR-012, ADR-014, ADR-016, CI guardrails, i18n parity).
- `.planning/ROADMAP.md` — Phase 16 Goal + 5 Success Criteria. **Plan must correct SC-3 wording** per D-15 above (engagement-axis re-frame).
- `.planning/STATE.md` — Current milestone position; Phase 15 close decisions including `selectedTimeWindowProvider` ownership, HomeHero month-anchor, and the no-invalidation rule for Home tab providers.

### Prior phase hand-off
- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md` — `Σ joy_contribution` backend, MetricResult contract, `getSoulRowsForJoyContribution` DAO pattern, soul-only ledger filter.
- `.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-CONTEXT.md` — Variant ε layout, KPI mini-hero, "Joy Index / 悦己指数 / ときめき指数" product vocabulary, anti-delta-framing constraints for any ledger-related copy.
- `.planning/phases/15-custom-time-windows-happy-v2-02/15-CONTEXT.md` — Phase 15 `selectedTimeWindowProvider`, `(startDate, endDate)` use-case migration, HomeHero isolation rule, `_refresh()` invalidation pattern, TimeWindowChip / TimeWindowPickerSheet integration model.

### Architecture / ADRs
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` §6 — per-member breakdown forbidden; §2/§4/§5/§7 also load-bearing for anti-toxicity copy constraints.
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — soul-only picker semantics; `soul_satisfaction` default = 2; Neutral=1/default=2 collision (D-10 of ADR-014) is the structural reason D-01..D-04 above re-frame the comparison axis.
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — `Σ joy_contribution` is the single Joy expression; HomeHero remains month-anchored (Phase 16 must not touch HomeHero); 100% behavior contract (zero discrete events) extends to Phase 16 surfaces — no celebration affordances when Joy or category leadership changes.
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF per-tx formula still active (referenced by ADR-016 §2); not directly used by Phase 16 surfaces, but the α=0.88 + `ptvfBaseFor(currencyCode)` infrastructure remains the codebase shape Phase 16 builds alongside.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Clean Architecture / Thin Feature rules; new use cases live in `lib/application/analytics/`; new widgets live in `lib/features/analytics/presentation/widgets/`.
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod 3 conventions; `state_<aggregate>.dart` provider naming pattern.

### Source integration points
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — Distribution section composition (lines 106–121); insert two new cards per D-13; extend `_refresh()` to invalidate the two new providers per D-19.
- `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` — section header style precedent.
- `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart` — neighbor card in Distribution; provides Category data lookup + ARB key conventions (e.g., `analyticsCategoryDonutOther`).
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` — neighbor card precedent for satisfaction-based visualization (Phase 16 list card sits adjacent).
- `lib/features/analytics/presentation/widgets/family_insight_card.dart` — group-mode card precedent; surfaces only in `isGroupMode = true`; ADR-012 §6-compliant aggregate-only.
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`, `monthlyJoyTargetRecommendationProvider`. New per-category and Soul-vs-Survival providers may live here or a new `state_ledger_snapshot.dart` (planner discretion).
- `lib/features/analytics/presentation/providers/state_time_window.dart` — `selectedTimeWindowProvider` is the consumer-side contract for `(startDate, endDate)`.
- `lib/application/analytics/get_family_happiness_use_case.dart` — group-mode aggregate use case pattern (shadow book resolution, type-system anti-leaderboard contract).
- `lib/application/analytics/get_satisfaction_distribution_use_case.dart` — current window-aware soul-only use case shape; Phase 16 per-category use case mirrors this structure.
- `lib/application/analytics/_time_window_validation.dart` — `TimeWindowValidation.assertValid(start, end)` — Phase 16 use cases MUST call this at entry.
- `lib/application/analytics/repository_providers.dart` — analytics use case provider wiring entry point.
- `lib/features/analytics/domain/models/shared_joy_insight.dart` — anti-leaderboard tuple precedent (`categoryId + avgSatisfaction + totalCount`); new per-category list item model mirrors this shape but lives in a list.
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — extend with new DAO surface(s) per planner discretion in D-discretion bullet.
- `lib/data/daos/analytics_dao.dart`:
  - `_soulExpenseFilter` constant (line 82) — `"ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0"`; reused by per-category breakdown.
  - `getSharedJoyCategoryInsight` (lines 410–445) — group-aggregate `GROUP BY category_id HAVING COUNT >= 3` precedent. New per-category list query mirrors but returns all rows + sort by AVG/COUNT/id.
  - `getLedgerTotals` (line 214) — already aggregates `GROUP BY ledger_type`; potential reuse for Soul-vs-Survival spend column.
  - `getSoulSatisfactionOverview` (line 244) — reusable for Soul column avg sat.
- `lib/data/tables/transactions_table.dart` lines 34–42 — `soulSatisfaction` default = 2, CHECK 1..10 (the structural reason for D-01..D-04).
- `lib/data/tables/category_ledger_configs_table.dart` line 13 — `ledger_type IN ('survival', 'soul')` enum constraint.
- `lib/infrastructure/category/category_locale_service.dart` — localized category name resolution.
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — currency / count formatting per CLAUDE.md i18n rules.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` — add new section header + per-category labels + Soul/Survival column headers + Empty-state copy + Other-row aggregate string + (existing key reuse where possible).
- `lib/generated/app_localizations*.dart` — generated after `flutter gen-l10n`; do not hand-edit.

### Project rules
- `CLAUDE.md` — Thin Feature rule (no `lib/features/{f}/application/` or `data/` subdirs); Riverpod 3 conventions; intl 0.20.2 pin; required code-gen after `@freezed` / `@riverpod` / Drift annotation changes.
- `.claude/rules/arch.md` — no new ADR in Phase 16 (decisions here derive from already-ratified ADR-012/014/016).
- `.claude/rules/coding-style.md` — immutability, `copyWith`, file size targets.
- `.claude/rules/testing.md` — TDD workflow; per-file coverage ≥70% (CI gate per REQUIREMENTS.md Cross-Phase Constraints).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`getSharedJoyCategoryInsight`** (`lib/data/daos/analytics_dao.dart`:410–445) — the structural precedent for per-category aggregation under min-N. The Phase 16 per-category list-DAO is the same query shape minus `LIMIT 1`, with the same tie-break order kept.
- **`getSoulSatisfactionOverview`** + **`getSoulRowsForJoyContribution`** — already window-aware (`startDate`/`endDate`); usable for Soul column metrics in Soul-vs-Survival without new infrastructure.
- **`getLedgerTotals`** — already returns `(ledger_type, SUM(amount))` grouped by ledger_type; usable for the spend cell of both Soul and Survival columns.
- **`SharedJoyInsight`** model — anti-leaderboard tuple `(categoryId, avgSatisfaction, totalCount)`; Phase 16 per-category list-item model has the same fields; reuse or sibling.
- **`MetricResult<T>` sealed type** — `Empty | Value`; per-category list-item itself isn't a MetricResult, but the wrapping aggregate (`PerCategorySoulBreakdown { items: List<...>, totalCount: int, otherCount: int }`) should be a `MetricResult` so empty-window / sub-min-N cases stay explicit.
- **`AnalyticsScreenSectionHeader`** — existing section divider widget; new cards do NOT add a new section header (D-13).
- **`FamilyInsightCard`** — group-mode card precedent (only rendered when `isGroupMode = true`, aggregate-only, no per-member rows); Phase 16 family-aggregate variants follow the same gate.
- **`CategoryLocaleService`** — localized category name lookup; new list rows feed category IDs through it.
- **`TimeWindowValidation.assertValid`** — guard called from every window-aware use case at entry.
- **`AsyncValue.when` per-card fault isolation** — preserved on the two new cards.

### Established Patterns

- AnalyticsScreen uses sectioned cards (`Time / Distribution / Stories`) with `AnalyticsScreenSectionHeader` dividers — Phase 16 stays inside the existing structure.
- User-facing text via `S.of(context)` with ja/zh/en ARB parity; locale-aware date display via `DateFormatter`.
- Provider families key on `(bookId, startDate, endDate)` for window-aware analytics providers; group-mode providers additionally consume `shadowBooksProvider`.
- Use case → Repository → DAO layering; domain models live in `features/analytics/domain/models/`; use cases live in `lib/application/analytics/`.
- DAO ledger filters use literal `'soul'` / `'survival'` strings tied to `category_ledger_configs.ledger_type` enum.
- `_soulExpenseFilter` constant (`ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0`) is the canonical soul filter; the survival mirror is `ledger_type = 'survival' AND type = 'expense' AND is_deleted = 0` — define a `_survivalExpenseFilter` constant for parity.
- Refresh invalidation must include the two new providers (window-keyed); MUST NOT invalidate HomeHero/Home tab providers (Phase 15 D-12).

### Integration Points

- **AnalyticsScreen → new cards:** insert `_SoulVsSurvivalCard` between `_CategoryDonutCard` and `_SatisfactionHistogramOrFallback`; insert `_PerCategoryBreakdownCard` after `_SatisfactionHistogramOrFallback`. In group mode, `_PerCategoryBreakdownCard` renders twice (You + Family) as stacked cards (D-17).
- **State layer:** new providers `perCategorySoulBreakdownProvider` (window-keyed, optionally group-aggregate variant) and `soulVsSurvivalSnapshotProvider` (window-keyed, includes both ledger metrics + group-aggregate variant when `isGroupMode = true`). Either extend `state_happiness.dart` or open `state_ledger_snapshot.dart` — planner discretion.
- **Empty + sub-min-N flow:** the use case returns Empty when 0 entries in window; the card renders Empty UI. When ≥1 entries but ALL fall in <3-entry categories, the list is empty but the Other row carries the aggregate count — surface still renders, just with "Other" as the only row.
- **Group-mode gate:** family-aggregate providers only consume `shadowBooksProvider` when `isGroupMode = true`; otherwise they are not built. `FamilyInsightCard` precedent.
- **ARB parity gate:** the trilingual forbidden-substring widget test enforces D-14; failing locale flags the surface for ARB review.

</code_context>

<specifics>
## Specific Ideas

- **The "Survival default=2" trap is the load-bearing insight of Phase 16.** It's why ROADMAP SC-3 wording must change (D-15), why the comparison surface re-frames to engagement axis (D-01..D-04), and why the Soul column carries an asymmetric `avg satisfaction` row (D-03). Downstream agents that don't internalize this will reach for `AVG(soul_satisfaction)` on survival rows and produce the anti-toxicity reverse pattern.
- **"Ledger · This window" / "本月账本描述" is the agreed framing** — descriptive, not comparative. No "vs" / "comparison" / "versus" language anywhere near these cards.
- **`SharedJoyInsight` is the family-aggregate precedent** — Phase 16 follows its tie-break order, its min-N threshold (3), and its no-per-member-projection contract verbatim.
- **The 2×2 grid for Soul-vs-Survival in group mode is the user's explicit design choice** — it expresses two crossing axes (you/family × soul/survival) with equal visual weight per cell. Do not collapse to 4 horizontal columns (overflows on narrow viewports) or 4 separate cards (loses the "snapshot" gestalt).
- **Per-Category in group mode is two stacked cards** — the user accepted intentional asymmetry vs Soul-vs-Survival's 2×2 grid because the two surfaces are different shape problems (ranked list vs crossing-axis snapshot).
- **Anti-toxicity widget tests are not optional.** D-14 names the minimum forbidden-substring set; planner expands. Failure modes are silent (a single locale slipping a "比較" header would ship a regression).

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-16 — future v1.2 / v1.3+ candidates

- **Per-category drill-in (tap row → transaction list filtered by category).** Plan-mentioned as planner discretion (default noop); a real drill-in surface is its own phase.
- **Per-category trend over time** (mini-sparkline per category, week-over-week movement) — out of scope; ADR-012 §4 cross-period delta concern would also need addressing.
- **Survival ledger satisfaction picker** — explicitly out of scope and contradicts ADR-014. If product ever wants symmetric satisfaction, that needs a fresh ADR.
- **Spend-share % representation in Soul-vs-Survival** — rejected because % expressions whisper ranking ("60% on survival" reads as evaluative). Could be revisited with explicit framing guardrails in a future phase.
- **Per-family-member breakdown of any kind** — permanently forbidden (ADR-012 §6).
- **Goldens for additional viewport widths beyond the project's default golden suite** — out of scope unless current goldens already cover those.
- **Cross-phase audit for "default-2" leak in other analytics surfaces** — Phase 16 fixes the comparison surface specifically; broader audit (does HomeHero, Variant ε KPIs, or any other surface implicitly read `soul_satisfaction` on survival rows?) is a future hygiene pass.

### Out-of-v1.2

- **FAMILY-V2-03 Privacy Consent Gate** — already deferred at milestone start; Phase 16 must NOT add any family-axis feature beyond aggregate display already gated by `isGroupMode`. No consent UI, no member opt-in, no member-level data anywhere.

### Reviewed Todos (not folded)

`cross_reference_todos` returned 0 matches for Phase 16. The remaining v1.1 verification debt (Phase 11 device/simulator UAT) is unrelated to Phase 16 scope.

</deferred>

---

*Phase: 16 — Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01)*
*Context gathered: 2026-05-20*
