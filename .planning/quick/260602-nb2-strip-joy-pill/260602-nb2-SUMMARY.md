---
phase: quick-260602-nb2
plan: 01
subsystem: home / accounting-utils
tags: [ui, home-hero-card, best-joy, joy-strip, mauve, golden-rebaseline, ARCH-002]
requires:
  - AppPalette Mauve Joy tokens (joy / joyText / joyLight) — already live (260602-jcl)
  - DefaultCategories.all (L1+L2 id→icon source)
  - resolveCategoryIcon (icon-name → IconData map)
  - CategoryLocalizationService.resolveFromId (category-name resolution)
provides:
  - categoryIconFromId(categoryId) -> IconData pure static resolver (joy-flavored fallback)
  - Restructured Best Joy tinted strip widget in HomeHeroCard Region 6
affects:
  - lib/features/home/presentation/widgets/home_hero_card.dart
  - lib/features/accounting/presentation/utils/category_display_utils.dart
tech-stack:
  added: []
  patterns:
    - Pure provider-free id→icon resolver reused by a StatelessWidget
    - Shared strip-chrome builder for value + empty states (DRY container)
    - Brightness-driven alpha (isDark ? 0.13 : 0.08) on a palette token
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/utils/category_display_utils.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - test/unit/features/accounting/presentation/utils/category_display_utils_test.dart
    - test/golden/goldens/home_hero_card_single_light_ja.png
    - test/golden/goldens/home_hero_card_single_dark_ja.png
    - test/golden/goldens/home_hero_card_thin_sample_ja.png
    - test/golden/goldens/home_hero_card_all_neutral_cta_ja.png
    - test/golden/goldens/home_hero_card_family_light_ja.png
    - test/golden/goldens/home_hero_card_family_dark_ja.png
    - test/golden/goldens/home_hero_card_joy_target_0_ja.png
    - test/golden/goldens/home_hero_card_joy_target_50_ja.png
    - test/golden/goldens/home_hero_card_joy_target_100_ja.png
    - test/golden/goldens/home_hero_card_joy_target_over_100_ja.png
decisions:
  - "Regenerated all 10 ja hero goldens, not just the 6 listed in the plan frontmatter — Best Joy is a permanent region so the 4 joy_target_* masters also shift; the plan constraint explicitly said to regenerate all that differ"
  - "Kept _satisfactionPill UNCHANGED per plan (enlarged icon/text) — placed under the amount in the right column"
  - "Subtitle format uses date(weekday) with no '悦己 ・' ledger prefix per ARCH-002 + design contract"
metrics:
  duration: ~4 min
  completed: 2026-06-02
  tasks: 3
  files: 13
---

# Phase quick-260602-nb2 Plan 01: Best Joy tinted Joy strip Summary

Redesigned `HomeHeroCard` Region 6 (本月最爱 / 今月の最愛 / Best Joy) from a bare 3-line layout into a tinted Mauve Joy strip — category-icon tile + category-name/date subtitle + amount-over-pill right column — backed by a new pure `categoryIconFromId` resolver, with all 10 ja golden masters re-baselined and the full 2290-test suite green.

## What shipped

1. **`categoryIconFromId(categoryId)` pure resolver** (`category_display_utils.dart`): looks the id up in `DefaultCategories.all` (L1 + L2), feeds the matched `category.icon` string into the existing `resolveCategoryIcon`; on no match returns `Icons.favorite_border` (joy-flavored fallback rather than `help_outline`). Provider-free and non-throwing. 4 new unit tests (L1 `cat_hobbies`/`cat_food`, L2 `cat_food_groceries`, unknown-id fallback) — written RED-first, then GREEN.

2. **Tinted Joy strip** (`home_hero_card.dart` Region 6): a shared `_bestJoyStripContainer` chrome (bg `palette.joy` @ alpha 0.08 light / 0.13 dark, 0.22 joy border, r14, pad14) wraps a joy-color w700 title (heart icon removed). Value state = 36×36 `joyLight` icon tile (`categoryIconFromId(row.categoryId)`) + Expanded middle column (category name primary, `date(weekday)` subtitle, no ledger prefix) + right column (joyText `amountSmall` 17px w800 over the existing `_satisfactionPill`). Empty / all-neutral states reuse the same chrome with a muted placeholder row (`auto_awesome` tile + existing `homeBestJoyEmptySmall` / `homeBestJoyAllNeutralSmall` strings). Dropped the now-unused `_splitCurrencySymbol`.

3. **Golden re-baseline**: all 10 `home_hero_card_*_ja.png` masters regenerated; light + dark visually verified against `docs/design/best-joy-redesign.html`.

## Verification

- `flutter analyze` on every touched file: **0 issues**.
- Full `flutter test`: **2290/2290 green**. Only `home_hero_card` goldens changed (no non-hero golden side effects).
- `categoryIconFromId` unit tests: 4/4 pass.
- ARCH-002 preserved: `BestJoyMomentRow` untouched; primary line stays category name (no merchant/note free-text).
- AppPalette token values unchanged (consumed via `context.palette` only).

## Deviations from Plan

### Scope adjustment (not a code deviation)

- **All 10 ja masters regenerated, plan frontmatter listed 6.** Best Joy is a permanent region, so the 4 `joy_target_{0,50,100,over_100}_ja` masters also shifted. The plan's Task-3 constraint explicitly said to expect MOST to shift and "Regenerate all that differ; do not hand-pick." No fixtures edited. Recorded in the SUMMARY frontmatter `decisions`.

### Out-of-scope items (logged, not fixed)

4 pre-existing analyzer items unrelated to this plan were logged to `deferred-items.md` (2 `onReorder` deprecations in `category_selection_screen.dart` — a file this plan did not touch; 2 in generated `build/ios/SourcePackages/firebase_messaging-*` artifacts). Left untouched per SCOPE BOUNDARY.

No Rule-1/2/3 auto-fixes were needed — the plan executed cleanly.

## Fixture note (expected, pre-existing — NOT a regression)

The Best Joy fixtures use ids `cat_coffee` / `cat_shopping` which are NOT in `DefaultCategories`. The regenerated masters therefore show the `Icons.favorite_border` icon-tile fallback and the `resolveFromId` category-name fallback that the existing widget already produced. Intentional per the plan; fixtures were not edited.

## Known Stubs

None.

## Commits

- `c37b3d62` feat(quick-260602-nb2): add categoryIconFromId pure resolver + unit tests
- `ba93d9da` feat(quick-260602-nb2): restructure Best Joy region into tinted Joy strip
- `c8059ef6` test(quick-260602-nb2): re-baseline home_hero_card goldens for Joy strip

## Self-Check: PASSED

- Files: category_display_utils.dart, home_hero_card.dart, regenerated goldens, SUMMARY.md — all FOUND
- Commits c37b3d62 / ba93d9da / c8059ef6 — all FOUND
- Content tokens: `categoryIconFromId` (resolver + hero call), `joyLight` (hero card) — all FOUND
