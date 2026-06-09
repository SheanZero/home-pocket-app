---
phase: quick-260609-pmc
plan: "02"
subsystem: shopping_list
tags: [ux, icons, drag-lift, reorder-mode, golden-tests]
dependency_graph:
  requires: [260609-pmc-01]
  provides: [bar-line-move-icons, opaque-drag-card]
  affects: [shopping_item_tile, shopping_list_screen]
tech_stack:
  added: []
  patterns: [palette.card opaque surface token, Flutter Icons bar-line variants]
key_files:
  modified:
    - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
    - test/golden/goldens/shopping_item_tile_reorder_mode_ja.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_ja.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_zh.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_zh.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_en.png
    - test/golden/goldens/shopping_item_tile_reorder_mode_dark_en.png
decisions:
  - Use Icons.vertical_align_top/bottom for move buttons — bar-line variants make "jump to edge" intent unambiguous vs plain chevrons
  - Use palette.card as Material color in proxyDecorator — eliminates gray shadow bleed-through from transparent surface; per-ledger accent border (width 4) inside child retained for item identity
metrics:
  duration: 8m
  completed: "2026-06-09T18:53:00Z"
  tasks_completed: 2
  tasks_total: 2
---

# Phase quick-260609-pmc Plan 02: Sort-mode UX Refinements — Bar-line Icons + Opaque Drag Card

**One-liner:** Replaced chevron move buttons with `vertical_align_top/bottom` bar-line icons and fixed dragged-item rendering to opaque `palette.card` surface with elevation shadow only.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Swap move-to-top/bottom icons to bar-line variants | c8d25310 | shopping_item_tile.dart, test file, 6 golden PNGs |
| 2 | Fix proxyDecorator — opaque card, shadow only, no green border | f5496651 | shopping_list_screen.dart |

## Verification Results

```
flutter analyze:                                               0 issues (full project)
flutter test test/widget/features/shopping_list/:             84/84 passed
flutter test shopping_item_tile_golden_test.dart --tags golden: 24/24 passed
```

All three verification commands clean.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — changes are purely UI/cosmetic (icon swap, Material color token).

## Self-Check: PASSED

- `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` — FOUND, contains `Icons.vertical_align_top` (line 393) and `Icons.vertical_align_bottom` (line 426); zero `keyboard_arrow` references remain
- `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart` — FOUND, `color: ctx.palette.card` at line 186; no `Colors.transparent`, no `DecoratedBox`, no `BorderSide(borderInputActive)` in proxyDecorator
- Commit c8d25310 — FOUND (Task 1)
- Commit f5496651 — FOUND (Task 2)
