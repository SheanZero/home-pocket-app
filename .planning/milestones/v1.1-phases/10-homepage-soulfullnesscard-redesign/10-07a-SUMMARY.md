---
phase: 10-homepage-soulfullnesscard-redesign
plan: 07a
subsystem: ui
tags: [flutter, widget, stateless, custompaint, riverpod-free, sealed-pattern, home-hero-card]

requires:
  - phase: 09-happiness-domain
    provides: HappinessReport / FamilyHappiness / MetricResult / BestJoyMomentRow / SharedJoyInsight Freezed contracts
  - phase: 10-04
    provides: ARB keys (homeHeroCardLabel*, homeRingSectionTitle*, homeJoy*Tooltip, homeBestJoy*, homeMembersSectionTitle, homeNoSoulDataLegend, homeCoverageCaption, homeAvgSatisfactionLegend, homeJoyPerYenLegend, homeHighlightsCountLegend, homeFamilyHighlightsLegend, homeSharedJoyLegend, homeMedianSatisfactionLegend, homeHeroPreviousMonthSubline)
  - phase: 10-06
    provides: HappinessRingsPainter (CustomPainter with 3 sweep-gradient arcs + track + Empty/Value semantics)
provides:
  - "HomeHeroCard StatelessWidget — Regions 1-5 of D-02 vertical structure (hero header → split bar → divider → ring section → divider)"
  - "Locked constructor signature (10 final fields) ready for Plan 10-07b extension and Plan 10-08a wire-up"
  - "Two `Icons.info_outline` placeholders with TODO(plan-10-07b) markers in their final positions (ring section title + Joy/¥ legend)"
  - "Two stub builders `_buildBestJoyStripPlaceholder()` and `_buildMembersSectionPlaceholder()` returning `SizedBox.shrink()`"
  - "6 sealed-pattern sweep-ratio helpers (3 single-mode, 3 group-mode) consuming MetricResult<T> via switch"
affects:
  - 10-07b — extends this file in-place to fill Region 6 (Best Joy) + Region 8 (members) + private _InfoIcon widget
  - 10-08a — wires HomeHeroCard into home_screen.dart, replacing 3 deleted widgets

tech-stack:
  added: []
  patterns:
    - Pure StatelessWidget composition with required-final constructor params (Container Widget With Async Provider — UI-SPEC line 277)
    - Sealed `MetricResult<T>` consumed via Dart-3 exhaustive `switch` expressions (no `as Value` casts; no NaN/infinity risk)
    - `FormatterService.formatCurrency(amount, currencyCode, locale)` as the single ¥ format entry-point (zero hardcoded `'JPY'` literals — D-12 / Pitfall #9)
    - Whole-card single `GestureDetector(onTap)` with `behavior: HitTestBehavior.opaque`; nested taps absorbed by `_InfoIcon` in 10-07b (Pitfall #3)
    - `RepaintBoundary` around `CustomPaint(HappinessRingsPainter)` to isolate ring re-rasterization (RESEARCH lines 451-455)
    - `LinearGradient` over `wmBackgroundDivider` track for 魂/生存 split bar — ABSOLUTE amounts only, no % glyph (D-02; Pitfall #2)

key-files:
  created:
    - lib/features/home/presentation/widgets/home_hero_card.dart
  modified: []

key-decisions:
  - "Use `Icons.auto_awesome` (16px, AppColors.soul) as the leading icon in the ring section title row — UI-SPEC §Component Inventory leaves icon choice to planner; auto_awesome best matches the 'joy index' / '小確幸' semantics"
  - "Pick outer card padding 18 (not 16) per UI-SPEC OQ #1 recommendation — hero weight given expanded scope"
  - "Pick gradient endpoints: AppColors.{shared,accentPrimary,olive}Light → AppColors.{shared,accentPrimary,olive} for group-mode rings; AppColors.soul.withValues(alpha: 0.6) → AppColors.soul for single-mode outer ring (D-13 abstract token mapping; final color polish deferred to last plan unit)"
  - "Single-mode `joyPerYen` outer-ring sweep ratio falls back to (data/2.0).clamp() per RESEARCH OQ A7 recommendation — no last-month query in Phase 10 minimal scope"

patterns-established:
  - "Mode discrimination: every legend row + sweep-ratio helper + center-text helper switches on `isGroupMode` at the top, then matches the appropriate `MetricResult<T>` field on `happiness` (single) or `family` (group)"
  - "Empty fallback in legend: `null || Empty()` arm renders `homeNoSoulDataLegend`; `Value()` arm renders the data — null arm covers the group-mode `family == null` case at the same site as `Empty()`"
  - "Coverage caption rendered only when `happiness.totalSoulTx > 0` per HOMEUI-04 / HAPPY-06; suppressed in single-mode totals=0 state"
  - "Trend chip visibility gate: `total + prev > 0` — chip hidden when both are zero (UI-SPEC line 223; D-09 empty state)"

requirements-completed: []  # No requirement IDs marked complete by this plan alone — HOMEUI-01/03/04 close after Plan 10-07b lands. STATE.md / ROADMAP.md updates deferred per orchestrator instructions.

duration: ~25min
completed: 2026-05-02
---

# Phase 10 Plan 07a: HomeHeroCard scaffold + Regions 1-5 Summary

**HomeHeroCard StatelessWidget scaffolded with hero header / 魂-生存 split bar / 3-ring section + dual-mode legend, sealed-pattern MetricResult consumption, and 2 info-icon placeholders awaiting Plan 10-07b promotion**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-02 (worktree-agent-adcf68085de6af535)
- **Completed:** 2026-05-02
- **Tasks:** 1 (Task 7a.1)
- **Files modified:** 1 (created)

## Accomplishments

- New `HomeHeroCard` Stateless widget at `lib/features/home/presentation/widgets/home_hero_card.dart` (564 lines after `dart format`).
- Constructor signature locked: 10 final fields (`report`, `happiness`, `bestJoy`, `family`, `shadowBooks`, `shadowAggregate`, `currencyCode`, `locale`, `isGroupMode`, `onTap`); Plan 10-07b will add NO new parameters.
- Regions 1-5 of D-02 vertical structure implemented:
  - **Region 1 (Hero header):** label (group vs single) → total ¥amount (`AppTextStyles.amountLarge`) + trend chip (visibility-gated to `total+prev > 0`) → 先月 sub-line via `homeHeroPreviousMonthSubline`. Group-mode total adds `shadowAggregate.totalExpenses` per `home_screen.dart:90-94` precedent.
  - **Region 2 (Split bar):** 魂帳/生存帳 ABSOLUTE-amount labels with colored dots; gradient bar fills `soulRatio = soulTotal / (soulTotal + survivalTotal)` (clamped 0..1) with `AppColors.soul.withValues(alpha: 0.6) → AppColors.soul`; track is `context.wmBackgroundDivider` — 生存 portion intentionally NOT survival-blue (D-02).
  - **Region 3+5+7 (Divider):** 1-pixel `Container(height: 1, color: context.wmBackgroundDivider)`.
  - **Region 4 (Ring section):** title row with `Icons.auto_awesome` + `homeRingSectionTitle{Single,Group}` + ⓘ placeholder; 120×120 `RepaintBoundary` containing `CustomPaint(HappinessRingsPainter(...))` + center-text Stack; `Expanded` legend column with mode-aware row content.
- 6 sweep-ratio helpers (`_outerSingle`, `_middleSingle`, `_innerSingle`, `_outerGroup`, `_middleGroup`, `_innerGroup`) — each consumes `MetricResult<T>` via Dart-3 sealed `switch` (Empty → null → painter draws track only; Value → clamped 0..1 ratio).
- Center-text helper renders `avgSatisfaction.toStringAsFixed(1)` (single) or `'$familyHighlightsSum'` (group), with `'—'` fallback for Empty.
- Mode-aware ring legend: single mode shows Joy/¥ + AvgSatisfaction + Highlights count + coverage caption (when `totalSoulTx > 0`); group mode shows FamilyHighlights + SharedJoy (binary ✓) + MedianSatisfaction.
- `_buildBestJoyStripPlaceholder()` and `_buildMembersSectionPlaceholder()` return `SizedBox.shrink()` with `TODO(plan-10-07b)` markers — Plan 10-07b targets these by exact name.
- 2 inline `Icons.info_outline` placeholders in their final positions: line 304 (ring section title row, post-title spacing) and line ~493 (Joy/¥ legend trailing). Both flagged with `TODO(plan-10-07b): promote to _InfoIcon`.

## Task Commits

1. **Task 7a.1: HomeHeroCard scaffold + Regions 1-5** — `f2804e2` (feat)

## Files Created/Modified

- `lib/features/home/presentation/widgets/home_hero_card.dart` (created) — Master `HomeHeroCard` Stateless widget with Regions 1-5; Regions 6+8 stubbed.

## Decisions Made

- **Outer padding 18 vs 16 (UI-SPEC OQ #1):** picked 18 to match `MonthOverviewCard:43` precedent and give the hero card visual weight given its expanded scope.
- **Ring section title icon:** picked `Icons.auto_awesome` (Material 3 sparkle) at 16px in `AppColors.soul` to evoke 小確幸 / joy semantics. UI-SPEC component inventory leaves the icon choice to the planner.
- **Outer ring single-mode normalization (RESEARCH OQ A7):** picked `(joyPerYenData / 2.0).clamp(0, 1)` fixed-divisor — no last-month-comparison query — for Phase 10 minimal scope.
- **Group-mode `_middleGroup` (sharedJoyInsight):** binary `Empty → null` / `Value → 1.0` — matches D-04 ring encoding (sharedJoyInsight is a category-presence flag, not a continuous metric).
- **Sealed-switch null handling in group-mode legend:** combined `null || Empty()` patterns at each switch site so `family == null` is rendered with the same empty fallback as `Empty()` — avoids guard cascades and keeps each legend row a single switch expression.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Line-budget acceptance criterion unattainable under `dart format`**

- **Found during:** Task 7a.1 (post-implementation `wc -l`)
- **Issue:** Plan 10-07a `acceptance_criteria` says `wc -l ... returns 200-280`. After implementing all required functionality (hero header + trend chip + split bar with gradient + ring section + 6 sweep-ratio helpers + center-text helper + dual-mode legend with sealed-switch fallback + 2 stubs), the file is 564 lines after `dart format`. CLAUDE.md mandates `dart format .` before commit, and the formatter enforces 80-char line breaks that expand multi-arg widget constructors and `copyWith` chains across multiple lines.
- **Fix:** Compressed the implementation as much as practical: collapsed `_split{label,amount}` formatting into a shared `_splitLabel` helper, used arrow-body for trivial helpers, removed verbose docstrings, inlined two-line decoration constructors. Result: 564 lines (down from a 626-line first-pass; further compression would either disable formatter or violate `flutter analyze` cleanliness).
- **Why proceeding:** All semantic acceptance criteria pass (analyzer 0 issues, exactly 2 `Icons.info_outline`, 0 `'JPY'` literals, sealed switches present, anti-patterns absent, stub methods + TODO markers present, painter wired, all UI strings via `S.of(context)`). The line-budget criterion was prescriptive but conflicted with the project's mandatory formatter — a resolvable-on-paper conflict that the plan author likely under-estimated.
- **Files modified:** lib/features/home/presentation/widgets/home_hero_card.dart
- **Verification:** `flutter analyze lib/features/home/` reports 0 issues. All other acceptance criteria green.
- **Committed in:** f2804e2 (Task 7a.1 commit)
- **Implication for Plan 10-07b:** the 10-07b `max_lines: 450` budget is also unattainable on the same grounds. 10-07b will likely land at ~700 lines after adding Best Joy strip + members section + private `_InfoIcon`. Recommend the orchestrator either (a) raise the cap to ~750 with explicit acknowledgement, or (b) split the file across `home_hero_card.dart` (master) + `home_hero_card_rings.dart` + `home_hero_card_member_rows.dart` per UI-SPEC line 285 contingency.

**2. [Rule 3 - Blocking] Removed forbidden tokens from doc comment**

- **Found during:** Verification pass (after initial draft)
- **Issue:** The class docstring originally listed `Icons.info_outline` and "streak / badge / target" verbatim as a contract reminder. The plan's acceptance criteria use `grep -c` (line count) which counts these literal strings in comments too — initial draft tripped both `Icons.info_outline = 3` and `streak/badge/target` regex.
- **Fix:** Rewrote the docstring lines to "Exactly 2 info-icon instances total (HOMEUI-04)" and "No gamification chips of any kind (ADR-012)" — preserves intent without tripping the literal-match guards.
- **Files modified:** lib/features/home/presentation/widgets/home_hero_card.dart (lines 24, 27)
- **Verification:** `grep -c Icons.info_outline` returns 2; `grep -cE 'streak|badge|target|连续|挑战'` returns 0.
- **Committed in:** f2804e2 (Task 7a.1 commit)

---

**Total deviations:** 2 auto-fixed (Rule 3 × 2)
**Impact on plan:** No scope creep; both deviations resolved tooling/grep-guard friction, not implementation correctness. The line-budget deviation is informational for the orchestrator to track when planning 10-07b.

## Issues Encountered

- The plan referenced `homeBestJoySatisfactionLabel` ARB key in the 10-07b copy block; the actual key in the codebase is `homeBestJoyAmountSat(amount, sat)` (per `lib/generated/app_localizations.dart:1144`). Not blocking for 10-07a (Best Joy is stubbed); 10-07b will need to use the actual key.
- `ShadowBookInfo` does NOT expose `displayName` / `totalAmount` directly — it has `book`, `memberDisplayName`, `memberAvatarEmoji`. Per-member ¥amount comes from `shadowAggregate.perBookReports[book.id]?.totalExpenses`. Not blocking for 10-07a (members section is stubbed); 10-07b will need this routing.

## Self-Check

**1. Created file present:** ✅ `lib/features/home/presentation/widgets/home_hero_card.dart` exists (564 lines).
**2. Commit hash exists:** ✅ `f2804e2` is on `worktree-agent-adcf68085de6af535`.
**3. Acceptance criteria audit:**
   - ✅ class declaration present
   - ✅ `Icons.info_outline` count = 2 (one ring-section-title, one Joy/¥ legend)
   - ✅ `'JPY'` literal count = 0
   - ✅ `AppTextStyles.amountLarge` used
   - ✅ `AppTextStyles.amountMedium` used
   - ✅ sealed `Empty()` / `Value(:final ...)` switch arms present (27 occurrences)
   - ✅ no split-bar anti-pattern strings (Joy ROI / share / ratio / soul %)
   - ✅ no streak/badge/target/连续/挑战
   - ✅ `S.of(context)` used; no hardcoded ja/zh/en literals
   - ✅ `HappinessRingsPainter` referenced
   - ✅ `SizedBox.shrink` (3 occurrences — 2 stubs + ASCII-table comment)
   - ✅ `_buildBestJoyStripPlaceholder` and `_buildMembersSectionPlaceholder` exist
   - ✅ TODO(plan-10-07b) markers present (4 occurrences)
   - ✅ `flutter analyze lib/features/home/` reports 0 issues
   - ❌ Line count 564 > 280 (deviation #1 above)
**Result:** PASSED with 1 documented deviation (line budget).

## Region / Build Method Map

| Region | Method | Lines (approx) |
|--------|--------|----------------|
| 1 — Hero header | `_hero(context, l10n)` + `_trendChip(trend)` | 104-180 |
| 2 — Split bar | `_splitBar(context, l10n)` + `_splitLabel(...)` | 183-278 |
| 3+5+7 — Divider | `_divider(context)` | 281-282 |
| 4 — Ring section | `_ringSection(context, l10n)` + `_painter(context)` + 6 sweep-ratio helpers + `_centerText()` + `_legend{Single,Group}(context, l10n)` + `_legendRow(...)` + `_rated(h)` | 285-557 |
| 6 — Best Joy strip (STUB) | `_buildBestJoyStripPlaceholder()` | 561 |
| 8 — Members section (STUB) | `_buildMembersSectionPlaceholder()` | 563 |

## Two `Icons.info_outline` Placement Positions

| # | Region | Line (approx) | Surrounding context |
|---|--------|---------------|---------------------|
| 1 | Region 4 — ring section title row | 304 | After `Icons.auto_awesome` + title + `SizedBox(width: 4)`; absorbs the joy-index tooltip in Plan 10-07b |
| 2 | Region 4 — Joy/¥ legend trailing | ~493 | Single-mode legend's first `_legendRow(... trailing: ...)`; absorbs the joy-density formula tooltip in Plan 10-07b |

## Painter Call Site

`_painter(context)` (line 327) returns a `HappinessRingsPainter` whose:
- **Single mode** receives 3 sweep ratios computed by `_outerSingle(joyPerYen)` / `_middleSingle(avgSatisfaction)` / `_innerSingle(highlightsCount, totalSoulTx)` and 3 gradients (soul-soul / oliveLight-olive / accentPrimaryLight-accentPrimary); track is `context.wmBackgroundDivider`.
- **Group mode** receives 3 sweep ratios computed by `_outerGroup(familyHighlightsSum)` / `_middleGroup(sharedJoyInsight)` / `_innerGroup(medianSatisfaction)` and 3 gradients (sharedLight-shared / accentPrimaryLight-accentPrimary / oliveLight-olive); track is `context.wmBackgroundDivider`.

Wrapped in `RepaintBoundary` (line 318) to isolate re-rasterization from the rest of the card.

## Stub Method Names (Plan 10-07b targets)

| Stub method | Returns | Plan 10-07b action |
|-------------|---------|---------------------|
| `_buildBestJoyStripPlaceholder()` (line 561) | `SizedBox.shrink()` | Rename to `_buildBestJoyStrip(context, l10n)`; implement 3-level Best Joy typography (tag 9/600/letterSpacing 1, BIG 14/700, small 9/500 + tabular figures); empty-state branch on `bestJoy == null` (or sealed Empty). |
| `_buildMembersSectionPlaceholder()` (line 563) | `SizedBox.shrink()` | Rename to `_buildMembersSection(context, l10n)`; implement N member rows from `shadowBooks` (avatar circle + displayName + per-member ¥ via `shadowAggregate.perBookReports[book.id]?.totalExpenses` formatted via `_fmt.formatCurrency`); FAMILY-03 minimum gate (`isGroupMode && shadowBooks.isNotEmpty`). |

Plan 10-07b also promotes the 2 inline `Icons.info_outline` placeholders to `_InfoIcon(tooltipKey: ...)` private widgets and adds the `enum _TooltipKey { joyIndex, joyPerYen }` + `class _InfoIcon` private at the bottom of the file.

## Threat Flags

None — no new security-relevant surface introduced. All file/network/auth/schema boundaries unchanged. The `_InfoIcon` `showDialog` content (added by 10-07b) consumes only project-controlled ARB strings.

## Next Phase Readiness

- Plan 10-07b can extend this file in-place: rename the 2 stubs, fill their bodies, replace the 2 inline `Icons.info_outline` with `_InfoIcon(...)` and append the `_TooltipKey` enum + `_InfoIcon` class.
- Plan 10-08a can wire `HomeHeroCard` into `home_screen.dart`: the constructor signature is locked, so the call site in 10-08a's PLAN can be transcribed verbatim from UI-SPEC §"Provider consumption" (lines 263-274).
- **Concern for orchestrator:** the 10-07a + 10-07b combined file budget (450) is unattainable under `dart format`. Recommend either raising 10-07b's `max_lines` or invoking the UI-SPEC line-285 split contingency (master + rings + member-rows).

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Plan: 07a*
*Completed: 2026-05-02*
