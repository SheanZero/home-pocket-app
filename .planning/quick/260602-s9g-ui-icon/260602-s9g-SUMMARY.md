---
phase: quick-260602-s9g
plan: 01
subsystem: ui
tags: [flutter, home-screen, golden-tests, category-icons, best-joy-strip]

requires:
  - phase: quick-260602-nb2
    provides: tinted Best Joy strip + categoryIconFromId resolver (reworked here)
provides:
  - parentCategoryIconFromId / parentCategoryIconForCategory parent-aware icon resolvers
  - flat (box-free) Best Joy strip with ring-matching header on the home hero card
  - HomeTransactionTile restructured to match ListTransactionTile layout
  - re-baselined home_hero_card golden masters (10 PNGs)
affects: [home-screen, list-tile-parity, future home-card tweaks]

tech-stack:
  added: []
  patterns:
    - "Parent-aware category icon resolution (L2 -> L1 parent icon) as a pure provider-free helper"
    - "Home recent-tx preview reuses the monthly list tile's visual layout (icon -> info column -> amount)"

key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/utils/category_display_utils.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/features/home/presentation/widgets/home_transaction_tile.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - test/unit/features/accounting/presentation/utils/category_display_utils_test.dart
    - test/features/home/presentation/widgets/home_transaction_tile_test.dart
    - test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart
    - test/widget/features/home/presentation/screens/home_tap_to_edit_test.dart
    - test/golden/goldens/home_hero_card_*.png (10 masters)

key-decisions:
  - "categoryColor now drives the leading L1 icon tint on HomeTransactionTile (was the L2 text color), matching ListTransactionTile semantics"
  - "Best Joy value-state strip drops the date subtitle so the L2 title is a single centered line aligned with the amount"
  - "parentCategoryIconForCategory exposed as the Category-based core so the parent-missing fallback branch is unit-testable"

patterns-established:
  - "parentCategoryIconFromId(String): id -> parent L1 icon; falls back to own icon when parent absent; favorite_border for unknown ids"
  - "Flat home-card region: no tinted box, header = auto_awesome (palette.joy) + bodyLarge/textPrimary title, relying on card padding"

requirements-completed: [UI-S9G]

duration: 14min
completed: 2026-06-02
---

# Quick 260602-s9g: Home UI Icon & Strip Fixes Summary

**Flattened the Best Joy strip to a box-free ring-style region, switched its leading glyph to the parent (L1) category icon via a new tested resolver, amount-sized the L2 title, shrank the satisfaction pill, and rebuilt the home recent-tx tile to mirror the monthly list tile.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-06-02T11:23Z (approx)
- **Completed:** 2026-06-02T11:37Z
- **Tasks:** 4/4
- **Files modified:** 9 (4 source/util, 4 test, 10 golden PNGs)

## Accomplishments

1. **Task 1 (TDD) — `parentCategoryIconFromId`**: Added a pure, provider-free parent-aware icon resolver plus `parentCategoryIconForCategory(Category)` core. RED test committed first (786160d4), then GREEN implementation (a8a78c58). Covers: L2 -> parent L1 icon (`cat_hobbies_games` -> `sports_esports`, not `videogame_asset`), L1 pass-through, unknown -> `favorite_border`, and the parent-missing -> own-icon fallback.
2. **Task 2 — Best Joy strip restyle** (745f1088): Removed the tinted/bordered container; header now matches `_ringSection` exactly (auto_awesome + textPrimary, no info icon). Leading icon uses `parentCategoryIconFromId`. L2 title enlarged to fontSize 17, centered on one line with the amount (date subtitle removed). Satisfaction pill shrunk (icon 16, text 12, padding 8/4). Dropped now-unused `isDark` param and `intl`/`DateFormatter` imports.
3. **Task 3 — HomeTransactionTile parity** (01e00d6d): Restructured to `Icon(l1Icon,28) -> Expanded(Column[L2 name + joy icon / ledger badge + optional merchant]) -> amount`, mirroring `ListTransactionTile` minus the Dismissible and member chip. Added required `l1Icon`, made `merchant` nullable. `home_screen` wires `l1Icon: parentCategoryIconFromId(tx.categoryId)` and passes nullable `tx.merchant`.
4. **Task 4 — goldens + verification** (d6b6c32f): Re-baselined 10 `home_hero_card_*` masters; visually confirmed flat strip / ring header / parent icon / centered larger title / compact pill in both light and dark. `list_transaction_tile` goldens did NOT drift. Full suite green (2294 tests).

## Verification

- `flutter analyze` on all modified files: **0 issues**.
- `flutter test` full suite: **2294/2294 passed**, including the 4 new `parentCategoryIconFromId` unit tests and re-baselined goldens.
- Golden visual check (light + dark `home_hero_card_single_*`): flat strip, mauve auto_awesome + textPrimary header, parent-category leading icon, fontSize-17 title centered with amount, compact satisfaction pill. `list_transaction_tile` masters unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated HomeTransactionTile test call sites for the new required `l1Icon`**
- **Found during:** Task 4 (full analyze)
- **Issue:** Adding the required `l1Icon` field (Task 3) broke 14 analyzer errors across 3 existing test files that construct `HomeTransactionTile` without it.
- **Fix:** Added `l1Icon:` to all constructions; rewrote 2 assertions that checked the L2-text color to instead check the leading L1 icon tint (the new home of `categoryColor`), matching the intended layout change.
- **Files modified:** `test/features/.../home_transaction_tile_test.dart`, `test/widget/.../home_transaction_tile_test.dart`, `test/widget/.../home_tap_to_edit_test.dart`
- **Commit:** d6b6c32f

## Deferred Issues

Pre-existing, out of scope (logged in `deferred-items.md`):
- `category_selection_screen.dart` lines 373 & 485: `onReorder` deprecation infos (present at base commit, untouched by this task).
- `build/ios/SourcePackages/.../analysis_options.yaml`: generated-package include warning (not project source).

## Known Stubs

None. All wiring is live (`home_screen` resolves real `tx.categoryId` -> parent icon; no placeholder data).

## Self-Check: PASSED

- All 4 tasks executed and committed atomically.
- Modified source files report 0 analyzer issues.
- Full test suite green (2294 tests).
- Golden masters visually validated (light + dark); list tile masters confirmed unchanged.
