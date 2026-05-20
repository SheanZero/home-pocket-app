---
phase: 16
plan: 07
subsystem: analytics/presentation
tags: [happy-v2, presentation-layer, widget, riverpod, golden, tdd]
requires:
  - 16-02  # ARB i18n keys (analyticsCardTitlePerCategorySoul + 16 siblings)
  - 16-03  # Domain model PerCategorySoulBreakdown
  - 16-06  # State providers perCategorySoulBreakdownProvider + family variant
provides:
  - PerCategoryBreakdownCard
  - PerCategoryScope
affects:
  - lib/features/analytics/presentation/widgets/  # +1 new file (per_category_breakdown_card.dart)
  - test/widget/features/analytics/presentation/widgets/  # +1 new test file
  - test/golden/  # +1 new golden test file + 3 PNG fixtures
tech-stack:
  added: []
  patterns:
    - consumer-stateful-widget          # ConsumerStatefulWidget + local _isExpanded state
    - async-value-when                  # ref.watch(...).when(loading/error/data)
    - metric-result-pattern-match       # Dart 3 switch on Empty/Value variants
    - variant-epsilon-card-chrome       # BorderRadius.circular(14) + EdgeInsets.all(14)
    - tabular-figure-amounts            # AppTextStyles.amountMedium for per-row text
    - locale-threaded-category-name     # CategoryLocalizationService.resolveFromId(id, locale)
    - test-localizations-helper         # createLocalizedWidget(overrides: [...])
key-files:
  created:
    - lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart
    - test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart
    - test/golden/per_category_breakdown_card_golden_test.dart
    - test/golden/goldens/per_category_breakdown_card_light_ja.png
    - test/golden/goldens/per_category_breakdown_card_dark_ja.png
    - test/golden/goldens/per_category_breakdown_card_group_light_ja.png
  modified: []
decisions:
  - "Used analyticsPerCategoryRow as a single localized string per row (renders category name + avg + count in one Text widget styled with AppTextStyles.amountMedium). The plan offered choosing between a single-line ARB string and two Text spans; the single-line ARB matches how the key was authored in 16-02 (en pattern: '{name} · {avg} avg / {count} entries') and avoids splitting the visual rhythm across two cells."
  - "Wrapped the golden test inner widget in SingleChildScrollView with height=420 to give the 5-row + Other fold variant enough vertical room (initial 320px caused RenderFlex overflow). The card itself never scrolls in production — the screen scrolls it; this is purely a golden-harness sizing decision."
  - "TextButton 'Show all' / 'Show less' uses padding=0 + tap-target-shrinkWrap so the toggle reads as inline text affordance rather than a Material button, matching Variant epsilon density."
  - "Default font (Outfit) is not bundled into Flutter's test runtime, so goldens render category text + amount text as box-glyphs. This is consistent with how home_hero_card_golden_test.dart and amount_display_golden_test.dart goldens render; the structural pixel-comparison (layout, spacing, colors, theme contrast) is what the goldens guard."
metrics:
  duration: ~30 minutes
  completed: 2026-05-20
---

# Phase 16 Plan 07: PerCategoryBreakdownCard widget (HAPPY-V2-01) Summary

First user-visible deliverable for HAPPY-V2-01 — the per-category soul satisfaction breakdown card that surfaces the Plan 16-06 providers in the AnalyticsScreen Distribution group. Renders top-5 by default with `Show all` expansion, an `Other` fold row for sub-min-N categories, and per-scope title variants (solo / group-You / group-Family). All 6 UI-SPEC states (Loading / Empty / Sub-min-N only / Value default / Value expanded / Error) are covered by widget tests; the surface is locked at the pixel level by 3 goldens (light + dark + group-family).

## What Was Built

### Task 1 — `PerCategoryBreakdownCard` widget (commit `7f9522f`)

`lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` (261 lines):

- **`enum PerCategoryScope { solo, you, family }`** — selects title key + which provider to read. Solo + group-You both use the single-book `perCategorySoulBreakdownProvider(bookId, startDate, endDate)`; family uses the no-bookId `perCategorySoulBreakdownFamilyProvider(startDate, endDate)`.
- **`class PerCategoryBreakdownCard extends ConsumerStatefulWidget`** — chosen over `ConsumerWidget` because the Show-all expansion requires local `bool _isExpanded` state (per RESEARCH Open Question #2 + PATTERNS §12 line 606).
- **Constructor:** `{required String bookId, required DateTime startDate, required DateTime endDate, required Locale locale, PerCategoryScope scope = PerCategoryScope.solo}` — uniform shape across scopes (`bookId` is accepted but unused when `scope == family`).
- **Card chrome (Variant ε precedent):** `Card(color: context.wmCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))) + Padding(EdgeInsets.all(14))`. No olive overlay (that's `FamilyInsightCard`-specific); uses standard card surface tint via the theme extension.
- **Title:** `AppTextStyles.titleLarge.copyWith(color: context.wmTextPrimary)` with one of three localized keys (`analyticsCardTitlePerCategorySoul` / `…You` / `…Family`).
- **AsyncValue.when:**
  - `loading` → `SizedBox(height: 200)` placeholder (no row text, no Show-all).
  - `error(_, _)` → `AnalyticsCardErrorState(onRetry: _invalidate)` — retry invalidates the same provider variant we watched.
  - `data` → switch on `MetricResult<PerCategorySoulBreakdown>`: `Empty` renders localized `analyticsPerCategoryEmpty` caption; `Value(:final data)` calls `_renderValue(data)`.
- **`_renderValue`:**
  - Computes `visibleItems = _isExpanded || !hasOverflow ? data.items : data.items.take(5).toList()`.
  - For each visible item: renders a single `Text` via `S.of(context).analyticsPerCategoryRow(localizedName, avg.toStringAsFixed(1), totalCount)` styled with `AppTextStyles.amountMedium` (the row contains a number, so we use the amount style for tabular figures per CLAUDE.md "Amount Display Style").
  - Localized category name resolved via `CategoryLocalizationService.resolveFromId(item.categoryId, widget.locale)` — same call shape used at `family_insight_card.dart:78`.
  - If `data.otherCount > 0`: appends an `Other` fold row with `analyticsPerCategoryOtherFold(otherCount, otherCategoryCount)` styled as `AppTextStyles.caption.copyWith(color: context.wmTextSecondary)`.
  - If `data.items.length > 5`: appends a `TextButton` toggle labeled `analyticsPerCategoryShowAll` (collapsed) / `analyticsPerCategoryShowLess` (expanded). Button uses `padding=0 + minimumSize=Size(0,32) + tapTargetSize=shrinkWrap` so it reads as an inline affordance rather than a chunky Material button.
  - Separates children with `SizedBox(height: 8)` (per UI-SPEC §Spacing — multiple of 4 token).
- **NO new color, spacing, or typography primitives** — every value flows from existing `AppColors` / `AppTextStyles` / `app_theme_colors` tokens.
- **NO forbidden substrings** (`compare|versus|better|worse|winner|loser`) in source — verified by grep in acceptance criteria.

### Task 2 — Widget tests (commit `33b0992`)

`test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` (295 lines, 8 `testWidgets` cases all passing):

1. **`loading state — shows placeholder, no row text`** — Provider override returns `Completer<...>.future` (never completes); `tester.pump()` (no settle); asserts title present + no empty/toggle copy. Completer is completed at the end so the test can tear down cleanly.
2. **`empty state — shows analyticsPerCategoryEmpty body`** — Provider returns `Empty<PerCategorySoulBreakdown>()`; asserts the localized "今期はカテゴリデータがありません" string.
3. **`sub-min-N only — Other fold row visible`** — `items=[]`, `otherCount=5`, `otherCategoryCount=2`; asserts the formatted "その他：5 件、2 カテゴリ" row + absence of Show all.
4. **`value with 3 rows — no Show all`** — 3 qualifying items, otherCount=0; asserts all 3 rows render with their formatted "平均 X.X / N 件" suffix and no toggle affordance.
5. **`value with 7 rows — Show all expansion toggle`** — Initial render shows rows 1–5 + Show all; rows 6–7 hidden. Tap Show all → rows 6–7 visible + Show less. Tap Show less → back to initial. Three pump-and-settle cycles verify the round trip.
6. **`scope=family — uses family provider + family title`** — Overrides the no-bookId `perCategorySoulBreakdownFamilyProvider`; asserts family title "ときめき · 家族のカテゴリ" appears and solo title does NOT.
7. **`error state — AnalyticsCardErrorState rendered`** — Provider returns `Future.error(StateError(...))`; asserts `find.byType(AnalyticsCardErrorState)`.
8. **`value with 6 qualifying + otherCount=3 — Other + Show all`** — Bonus case combining 6 items (overflow trigger) + Other row + Show all toggle — verifies the three affordances coexist correctly.

Test harness: `createLocalizedWidget(widget, locale: const Locale('ja'), overrides: [...])` from `test/helpers/test_localizations.dart`. The helper signature already supports `overrides: List<Override>` from `flutter_riverpod/misc.dart` (verified directly in the helper source).

### Task 3 — Golden tests + 3 PNGs (commit `44a2a7d`)

`test/golden/per_category_breakdown_card_golden_test.dart` (139 lines, 3 `matchesGoldenFile` assertions all passing):

- **`light theme — solo mode, ja locale`** → `goldens/per_category_breakdown_card_light_ja.png` (7,067 bytes).
- **`dark theme — solo mode, ja locale`** → `goldens/per_category_breakdown_card_dark_ja.png` (7,106 bytes).
- **`light theme — group mode, family scope, ja locale`** → `goldens/per_category_breakdown_card_group_light_ja.png` (7,085 bytes).

Fixture: `_fixtureFiveWithOther()` — exactly 5 qualifying categories (so no Show all) + `otherCount=2`, `otherCategoryCount=1` (so the Other fold row IS rendered). This exercises the canonical default surface (rows + Other; no expansion).

Harness `_wrap`: ProviderScope (with provider override) → MaterialApp (locale + theme + S.delegate chain) → Scaffold → Center → SizedBox(360×420) → SingleChildScrollView → PerCategoryBreakdownCard. The SingleChildScrollView is purely a golden-harness sizing concession — the production widget never scrolls; the surrounding AnalyticsScreen scrolls instead.

Goldens generated via `flutter test --update-goldens` then locked by re-running without the flag. Layout pixel-comparison only; text glyphs render as box outlines because the Outfit font is not bundled in Flutter's headless test runtime (same as `home_hero_card_golden_test.dart` + `amount_display_golden_test.dart`).

## How It Works

```
                       AnalyticsScreen (Distribution group)
                                  │
                                  │  inserts (Plan 16-10)
                                  ▼
       ┌───────────────────────────────────────────────────────┐
       │  PerCategoryBreakdownCard  (Plan 16-07)               │
       │    ConsumerStatefulWidget  +  _isExpanded: bool       │
       │                                                       │
       │    ┌──── solo / group-You ────┐  ┌── group-Family ──┐ │
       │    │                          │  │                  │ │
       │    │ perCategorySoulBreakdown │  │ ...Family        │ │
       │    │   Provider (bookId, ...) │  │   Provider(...)  │ │
       │    └────────────┬─────────────┘  └────────┬─────────┘ │
       │                 │                         │           │
       │                 └──── ref.watch().when ───┘           │
       │                          │                            │
       │                          ▼                            │
       │   loading: SizedBox(h=200)                            │
       │   error:   AnalyticsCardErrorState(onRetry)           │
       │   data:    switch (MetricResult)                      │
       │            ├─ Empty  → analyticsPerCategoryEmpty      │
       │            └─ Value  → _renderValue                   │
       │                        ├─ items.take(_isExpanded?     │
       │                        │      items.length : 5)       │
       │                        ├─ otherCount>0 → Other fold   │
       │                        └─ items>5      → Show all /   │
       │                                          Show less    │
       └───────────────────────────────────────────────────────┘
```

## Verification

- **Analyzer:** `flutter analyze lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart test/golden/per_category_breakdown_card_golden_test.dart` → `No issues found!`
- **Project-wide analyzer:** `flutter analyze` (whole worktree) → `No issues found! (ran in 5.7s)`.
- **Widget tests:** `flutter test test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` → 8 / 8 passing.
- **Golden tests (locked):** `flutter test test/golden/per_category_breakdown_card_golden_test.dart` → 3 / 3 passing without `--update-goldens` (goldens stable).
- **Combined run:** 11 tests across both files all pass.
- **Plan acceptance criteria:**
  - `enum PerCategoryScope { solo, you, family }` present (1 match).
  - `class PerCategoryBreakdownCard extends ConsumerStatefulWidget` present (1 match).
  - `bool _isExpanded = false;` present (1 match).
  - All three title ARB keys referenced (`analyticsCardTitlePerCategorySoul`, `…You`, `…Family`).
  - All five row/state ARB keys referenced (`analyticsPerCategoryRow`, `analyticsPerCategoryOtherFold`, `analyticsPerCategoryShowAll`, `analyticsPerCategoryShowLess`, `analyticsPerCategoryEmpty`).
  - Both providers referenced (`perCategorySoulBreakdownProvider`, `perCategorySoulBreakdownFamilyProvider`).
  - Variant ε chrome: `BorderRadius.circular(14)` + `EdgeInsets.all(14)` both present.
  - `AppTextStyles.amount*` used for numeric row content (1 match — `amountMedium` for per-row "name · avg / N 件" line).
  - Forbidden user-visible substrings: `grep -iE 'compare|versus|better|worse|winner|loser' ... | grep -v '^[[:space:]]*//'` → empty (only the doc directive constants appear, and they're inside `///` comments — filtered out).

## Deviations from Plan

None — plan executed exactly as written. Only minor adjustment:

- **Golden harness sizing (not a deviation, just a test-harness detail):** the plan suggested `SizedBox(width: 360, height: 320)`. The 5-row + Other fold variant overflows that height (Card padding + title + 5 amountMedium rows + Other caption + spacing ≈ 350+ logical pixels). Increased to `height: 420` and wrapped in `SingleChildScrollView` to keep the golden output stable. Documented as a key-decision in the frontmatter; not a plan deviation because the plan explicitly delegated "exact harness sizing" to the executor.

No Rule 1 / Rule 2 / Rule 3 auto-fixes were needed. No checkpoints reached. No auth gates.

## Known Stubs

None. The widget consumes real provider data; the Plan 16-06 providers and 16-03 domain model are fully wired upstream. AnalyticsScreen integration (inserting this card into the Distribution group) is Plan 16-10's responsibility.

## Self-Check: PASSED

Created files (all FOUND):

- `lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart`
- `test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart`
- `test/golden/per_category_breakdown_card_golden_test.dart`
- `test/golden/goldens/per_category_breakdown_card_light_ja.png`
- `test/golden/goldens/per_category_breakdown_card_dark_ja.png`
- `test/golden/goldens/per_category_breakdown_card_group_light_ja.png`

Commits (all FOUND in `git log`):

- `7f9522f` feat(16-07): add PerCategoryBreakdownCard widget
- `33b0992` test(16-07): widget tests for PerCategoryBreakdownCard
- `44a2a7d` test(16-07): add PerCategoryBreakdownCard golden tests
