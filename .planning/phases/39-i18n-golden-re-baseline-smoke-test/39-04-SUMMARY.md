---
phase: 39-i18n-golden-re-baseline-smoke-test
plan: "04"
subsystem: shopping_list/golden_tests
tags: [golden, shopping, filter_bar, batch_chrome, i18n]
dependency_graph:
  requires: []
  provides:
    - shopping_filter_bar_active golden baselines (6 PNGs)
    - shopping_selection_header golden baselines (6 PNGs)
    - shopping_batch_action_bar golden baselines (6 PNGs)
  affects:
    - test/golden/
tech_stack:
  added: []
  patterns:
    - _FixedShoppingFilter notifier subclass (daily ledger active state for golden)
    - _FixedBatchSelectMode notifier subclass (stable batch selection state for golden)
    - mocktail _MockDeleteShoppingItemUseCase (provider must be resolvable even without confirm)
key_files:
  created:
    - test/golden/shopping_filter_bar_golden_test.dart
    - test/golden/shopping_batch_chrome_golden_test.dart
    - test/golden/goldens/shopping_filter_bar_active_ja.png
    - test/golden/goldens/shopping_filter_bar_active_zh.png
    - test/golden/goldens/shopping_filter_bar_active_en.png
    - test/golden/goldens/shopping_filter_bar_active_dark_ja.png
    - test/golden/goldens/shopping_filter_bar_active_dark_zh.png
    - test/golden/goldens/shopping_filter_bar_active_dark_en.png
    - test/golden/goldens/shopping_selection_header_ja.png
    - test/golden/goldens/shopping_selection_header_zh.png
    - test/golden/goldens/shopping_selection_header_en.png
    - test/golden/goldens/shopping_selection_header_dark_ja.png
    - test/golden/goldens/shopping_selection_header_dark_zh.png
    - test/golden/goldens/shopping_selection_header_dark_en.png
    - test/golden/goldens/shopping_batch_action_bar_ja.png
    - test/golden/goldens/shopping_batch_action_bar_zh.png
    - test/golden/goldens/shopping_batch_action_bar_en.png
    - test/golden/goldens/shopping_batch_action_bar_dark_ja.png
    - test/golden/goldens/shopping_batch_action_bar_dark_zh.png
    - test/golden/goldens/shopping_batch_action_bar_dark_en.png
  modified: []
decisions:
  - "D39-04: _FixedShoppingFilter subclass pattern used over post-pump container.read() for stable daily-ledger golden state"
  - "D39-04: _FixedBatchSelectMode constructed with matching header (2 items) vs bar (1 item) states for distinct visual coverage"
  - "D39-04: deleteShoppingItemUseCaseProvider overridden with mock in batch bar test — provider must be resolvable during render even though delete dialog is never triggered"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-08T14:34:15Z"
  tasks_completed: 3
  files_created: 20
---

# Phase 39 Plan 04: Filter Bar + Batch Chrome Goldens Summary

**One-liner:** ShoppingFilterBar active-filter + ShoppingSelectionHeader + ShoppingBatchActionBar golden baselines via fixed-state notifier subclasses × 3 locales × 2 modes = 18 PNGs.

## What Was Built

Two new golden test files covering shopping UI chrome widgets:

**`test/golden/shopping_filter_bar_golden_test.dart`** — ShoppingFilterBar with daily ledger chip active.
- `_FixedShoppingFilter extends ShoppingFilter` returns `ShoppingListFilter(ledgerType: LedgerType.daily)` to render the 日常/日常/Daily chip as highlighted.
- Overrides: `shoppingFilterProvider`, `listTypeProvider`, `currentLocaleProvider`.
- 6 tests (3 locales × 2 modes); golden file naming: `shopping_filter_bar_active_{locale}.png` / `shopping_filter_bar_active_dark_{locale}.png`.

**`test/golden/shopping_batch_chrome_golden_test.dart`** — ShoppingSelectionHeader (2 items selected) + ShoppingBatchActionBar (1 item selected, delete button enabled).
- `_FixedBatchSelectMode extends BatchSelectMode` with injected `BatchSelectModeState` — different instances for header (2 selected) vs bar (1 selected).
- `_MockDeleteShoppingItemUseCase` via mocktail — makes `deleteShoppingItemUseCaseProvider` resolvable without real DB calls.
- 12 tests (2 widgets × 3 locales × 2 modes); golden file naming: `shopping_selection_header_{locale}.png` / `shopping_batch_action_bar_{locale}.png` (light+dark variants).

**18 PNG files generated** in `test/golden/goldens/`.

## Verification

```
flutter test test/golden/shopping_filter_bar_golden_test.dart \
             test/golden/shopping_batch_chrome_golden_test.dart --tags golden
→ All 18 tests passed (exit 0)
```

```
flutter analyze test/golden/shopping_filter_bar_golden_test.dart
  → No issues found
flutter analyze test/golden/shopping_batch_chrome_golden_test.dart
  → No issues found
```

PNG counts:
- `ls shopping_filter_bar_*.png | wc -l` → 6
- `ls shopping_selection_header_*.png | wc -l` → 6
- `ls shopping_batch_action_bar_*.png | wc -l` → 6

## Deviations from Plan

None — plan executed exactly as written. Fixed-state notifier subclass pattern followed per PATTERNS.md. Task 3 (checkpoint:human-verify) auto-proceeded per orchestrator instruction to generate goldens directly.

## Known Stubs

None. All 18 PNG baselines render actual widget content (not placeholders).

## Threat Flags

None — golden test files contain only hardcoded test IDs ('id-1', 'id-2'). No user data, no new network surface.

## Commits

| Hash | Message |
|------|---------|
| c55f8d9e | feat(39-04): add filter bar + batch chrome golden test files |
| 13552a50 | feat(39-04): generate 18 PNG golden baselines for filter bar + batch chrome |

## Self-Check: PASSED

All 20 files exist and both commits are present in git log.
