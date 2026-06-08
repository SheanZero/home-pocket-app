---
phase: 39-i18n-golden-re-baseline-smoke-test
plan: "03"
subsystem: shopping_list/golden_tests
tags:
  - golden
  - shopping_list
  - i18n
  - v1.6
dependency_graph:
  requires:
    - "38-*: ShoppingItemTile widget implementation (SHOP-02/03, DONE-01, SYNC-04)"
  provides:
    - "test/golden/shopping_item_tile_golden_test.dart — 18 golden baselines for ShoppingItemTile"
    - "18 PNG masters in test/golden/goldens/"
  affects:
    - "NAV-03 (SC3) — baseline count now meets 18-PNG requirement"
tech_stack:
  added: []
  patterns:
    - "SliverReorderableList ancestor wrapper for ReorderableDragStartListener golden tests"
    - "Loop-based testWidgets across 3 locales × 2 modes in a single group"
    - "shadowBooksProvider.overrideWith for attribution chip variant"
key_files:
  created:
    - test/golden/shopping_item_tile_golden_test.dart
    - test/golden/goldens/shopping_item_tile_active_ja.png
    - test/golden/goldens/shopping_item_tile_active_zh.png
    - test/golden/goldens/shopping_item_tile_active_en.png
    - test/golden/goldens/shopping_item_tile_active_dark_ja.png
    - test/golden/goldens/shopping_item_tile_active_dark_zh.png
    - test/golden/goldens/shopping_item_tile_active_dark_en.png
    - test/golden/goldens/shopping_item_tile_completed_ja.png
    - test/golden/goldens/shopping_item_tile_completed_zh.png
    - test/golden/goldens/shopping_item_tile_completed_en.png
    - test/golden/goldens/shopping_item_tile_completed_dark_ja.png
    - test/golden/goldens/shopping_item_tile_completed_dark_zh.png
    - test/golden/goldens/shopping_item_tile_completed_dark_en.png
    - test/golden/goldens/shopping_item_tile_attribution_ja.png
    - test/golden/goldens/shopping_item_tile_attribution_zh.png
    - test/golden/goldens/shopping_item_tile_attribution_en.png
    - test/golden/goldens/shopping_item_tile_attribution_dark_ja.png
    - test/golden/goldens/shopping_item_tile_attribution_dark_zh.png
    - test/golden/goldens/shopping_item_tile_attribution_dark_en.png
  modified: []
decisions:
  - "D39-03: Component-level tile golden (390×80 SizedBox, not full-screen snapshot)"
  - "D39-04: Three tile variants — active (daily border), completed (joy border + DONE-01 strikethrough+fade), attribution chip (public-family member, SYNC-04)"
  - "D39-05: active tile uses LedgerType.daily (daily green border), completed uses LedgerType.joy (joy sakura-pink border)"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-08"
  tasks_completed: 1
  tasks_total: 2
  files_created: 19
  files_modified: 0
---

# Phase 39 Plan 03: ShoppingItemTile Golden Baselines Summary

**One-liner:** ShoppingItemTile golden test with 18 PNG baselines — 3 variants (active/completed/attribution) × 3 locales × 2 modes — with mandatory SliverReorderableList ancestor wrapper.

## What Was Built

Created `test/golden/shopping_item_tile_golden_test.dart` and generated 18 PNG baseline files covering the full ShoppingItemTile visual surface:

- **active** — `LedgerType.daily`, `isCompleted=false`, `listType='private'` → daily green left border (ADR-019 `#5FAE72`)
- **completed** — `LedgerType.joy`, `isCompleted=true`, `listType='private'` → joy sakura-pink left border + animated strikethrough + 50% opacity fade (DONE-01)
- **attribution** — `LedgerType.daily`, `listType='public'`, `addedByBookId='shadow-book-42'` → attribution chip "🐱 Alice" via `shadowBooksProvider` override (SYNC-04)

Each variant tested in `ja`, `zh`, `en` × `light`, `dark` = 18 tests, all passing.

## Task Results

### Task 1: Write shopping_item_tile_golden_test.dart

**Status:** Complete  
**Commit:** `748de14f`

- File created with `@Tags(['golden'])` header
- `_wrap` helper includes mandatory `SliverReorderableList` > `ReorderableDelayedDragStartListener` > `ShoppingItemTile` nesting (prevents "Reorderable ancestor not found" error)
- `shadowBooksProvider.overrideWith((_) async => shadowBooks)` enables attribution chip variant
- `currentLocaleProvider.overrideWith((_) async => locale)` prevents async timer pending
- Bare `ThemeData.light()` / `ThemeData.dark()` works correctly — `context.palette` null-safe fallback resolves to `AppPalette.light/dark` based on brightness

### Task 2: Generate golden baselines and visual verify

**Status:** Complete (automated)  
- `flutter test --update-goldens --tags golden` → 18/18 passed, 18 PNGs created
- `flutter test --tags golden` (verify run, no --update-goldens) → 18/18 passed

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all golden fixtures use fixed item data; no stubs flowing to UI rendering.

## Threat Flags

None — T-39-01 mitigated as planned: private-tile variants (active/completed) use `listType='private'`; attribution variant uses `listType='public'` with explicit `shadowBooks` entry. No cross-contamination.

## Self-Check

### Created files exist:

- `test/golden/shopping_item_tile_golden_test.dart` — FOUND
- All 18 PNG files in `test/golden/goldens/` — FOUND (confirmed by `ls | wc -l` = 18)

### Commits exist:

- `748de14f` — feat(39-03): ShoppingItemTile golden baselines — FOUND

## Self-Check: PASSED
