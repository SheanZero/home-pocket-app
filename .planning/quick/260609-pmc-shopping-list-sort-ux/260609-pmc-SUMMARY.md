---
phase: quick-260609-pmc
plan: 01
subsystem: shopping-list
tags: [ux, reorder, filter-bar, drag-gesture, goldens, i18n]
dependency_graph:
  requires: []
  provides: [shopping-sort-ux-fixes]
  affects: [shopping_filter_bar, shopping_list_screen, shopping_item_tile]
tech_stack:
  added: []
  patterns: [SliverReorderableList.proxyDecorator, ReorderableDelayedDragStartListener]
key_files:
  modified:
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
    - lib/l10n/app_zh.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_en.arb
    - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
    - test/golden/shopping_item_tile_golden_test.dart
  created:
    - test/golden/goldens/shopping_item_tile_reorder_mode_ja.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_zh.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_en.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_ja.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_zh.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_en.png
decisions:
  - Fix 1 removes chip prefixes entirely (no avatar: reorderPrefix()) rather than making them optional
  - Fix 4 uses sort_order = -1 for move-to-top (guaranteed first) and sort_order = activeCount for move-to-bottom
  - Move-to-bottom reads filteredShoppingItemsProvider.value inside InkWell.onTap (synchronous, provider cached)
  - proxyDecorator uses borderInputActive (leaf green #6FA36F) for the drag highlight border
metrics:
  duration: ~35 minutes
  completed: 2026-06-09
  tasks_completed: 3
  files_changed: 19
---

# Phase quick-260609-pmc Plan 01: Shopping List Sort UX Fixes Summary

Four UX improvements to shopping list reorder mode: filter bar chip layout parity, long-press drag from anywhere, dragged-item visual highlight, and move-to-top/bottom quick-jump buttons.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix 1 — Remove sort-mode chip prefixes from ShoppingFilterBar | 10bd0e3d | shopping_filter_bar.dart, filter_bar_test.dart |
| 2 | Fix 2+3 — Long-press drag + proxyDecorator highlight | dbe972bf | shopping_list_screen.dart |
| 3 | Fix 4 — Move-to-top/bottom buttons; ARB keys; goldens | cecdaecb | shopping_item_tile.dart, 3x ARB, tests, 6 PNGs |

## What Was Built

### Fix 1: Filter bar chip layout parity (Task 1)
Deleted the `reorderPrefix()` helper and removed its `avatar:` usage from all three `ActionChip` widgets (全部, 私有, category). Also removed the `if (reorderMode)` block that added a `drag_indicator` icon to the segmented control. The filter bar now looks identical in normal and reorder modes. Widget test updated from `findsWidgets` to `findsNothing` for drag_indicator in reorder mode. 6 filter bar goldens re-baselined (no visual change since the existing goldens test non-reorder active state).

### Fix 2: Long-press drag from anywhere (Task 2)
Wrapped `ShoppingItemTile` in `ReorderableDelayedDragStartListener` at the `SliverReorderableList.itemBuilder` level. This adds a long-press-anywhere drag path on top of the existing instant-drag handle (`ReorderableDragStartListener` inside the tile, which is kept). No changes to the tile itself were needed.

### Fix 3: Dragged item border highlight (Task 2)
Added `proxyDecorator:` to `SliverReorderableList`. The decorator uses `AnimatedBuilder` to animate elevation from 0 to 6 via `CurvedAnimation(Curves.easeOut)` and wraps the child in `DecoratedBox` with a 6px left `BorderSide` in `ctx.palette.borderInputActive` (leaf green `#6FA36F`).

### Fix 4: Move-to-top and move-to-bottom buttons (Task 3)
Added two `InkWell` icon buttons to `_buildTrailingCluster` when `reorderMode && isActive`:
- `Icons.keyboard_arrow_up`: calls `reorderShoppingItemsUseCaseProvider.execute(item.id, -1)` — sort_order = -1 guarantees first position
- `Icons.keyboard_arrow_down`: reads `filteredShoppingItemsProvider.value` for activeCount, then `execute(item.id, activeCount)` — places item last

Both buttons use `SizedBox(width: 36, height: 44)`, `palette.textSecondary` icon color, `Semantics(button: true)` + `Tooltip` using the new ARB keys. The existing drag handle is kept after the two buttons.

ARB keys added to all 3 locales:
- `shoppingMoveToTop`: zh=置顶, ja=一番上に移動, en=Move to top
- `shoppingMoveToBottom`: zh=置底, ja=一番下に移動, en=Move to bottom

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `flutter test test/widget/features/shopping_list/` | 84/84 pass |
| `flutter test test/architecture/` | 47/47 pass |
| `flutter test test/golden/shopping_filter_bar_golden_test.dart --tags golden` | 6/6 pass |
| `flutter test test/golden/shopping_item_tile_golden_test.dart --tags golden` | 24/24 pass |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. All changes are local UI interactions (no new network endpoints, auth paths, or trust boundaries). The move-to-top/bottom buttons invoke an existing local-only use case with sort_order integer values; T-pmc-01 and T-pmc-02 from the plan's threat model are accepted.

## Self-Check: PASSED

Files verified:
- FOUND: lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
- FOUND: lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
- FOUND: lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
- FOUND: test/golden/goldens/shopping_item_tile_reorder_mode_ja.png
- FOUND: test/golden/goldens/shopping_item_tile_reorder_mode_dark_en.png

Commits verified:
- FOUND: 10bd0e3d (Task 1)
- FOUND: dbe972bf (Task 2)
- FOUND: cecdaecb (Task 3)
