---
phase: 38-presentation-shell-ui-widgets
plan: "06"
subsystem: shopping_list_screen
tags: [screen, widget, batch-mode, sliver-list, riverpod, streaming]
status: complete

dependency_graph:
  requires:
    - 38-04  # ShoppingItemTile, ShoppingEmptyState, ShoppingFilterBar
    - 38-05  # ShoppingItemFormScreen, state providers
  provides:
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    - lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart
    - lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart
  affects:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb

tech_stack:
  added: []
  patterns:
    - SliverReorderableList with onReorderItem (Flutter 3.44 API)
    - ConsumerWidget batch chrome pattern (D38-03 contextual-action-mode)
    - Reactive stream binding via filteredShoppingItemsProvider (GAP-2 lesson)
    - showSuccessFeedback-before-delete-loop (T-38-06-02 context validity rule)
    - _BatchHeaderWrapper wrapper widget for allItemIds prop isolation

key_files:
  created:
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    - lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart
    - lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart

decisions:
  - "Flutter 3.44 removed buildDefaultDragHandles from SliverReorderableList — using onReorderItem + ReorderableDragStartListener in ShoppingItemTile (equivalent L2 fix)"
  - "onReorderItem provides pre-adjusted newIndex — no manual -1 adjustment needed unlike old onReorder"
  - "_BatchHeaderWrapper separates allItemIds read from main build to avoid full-screen rebuilds on batch ID changes"
  - "Clear-all-completed uses delete_sweep_outlined icon (no text label) to save row space"
  - "l10n keys added: shoppingSegment*, shoppingCompletedDivider, shoppingClearCompleted*, shoppingListLoadError, shoppingRetry, shoppingBatch*"

metrics:
  duration: "~45 minutes"
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 4
---

# Phase 38 Plan 06: ShoppingListScreen Shell + Batch Chrome Summary

**One-liner:** ShoppingListScreen with SliverReorderableList (active) + SliverList (completed) + batch-select chrome (ShoppingBatchActionBar + ShoppingSelectionHeader) wired to filteredShoppingItemsProvider reactive stream.

## What Was Built

### Task 1: ShoppingBatchActionBar + ShoppingSelectionHeader

- **ShoppingBatchActionBar** (`lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart`): 56px floating bottom bar with selected-item count label and a FilledButton.tonal delete button (disabled when selection is empty). `showSuccessFeedback` is called BEFORE the delete loop per T-38-06-02 context validity rule. `batchSelectModeProvider.notifier.exit()` fires after all deletions complete.

- **ShoppingSelectionHeader** (`lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart`): 48px header with `palette.backgroundMuted` background. Contains Cancel button (calls `exit()`), centered selection count ("N 件"), and Select-all button (calls `selectAll(allItemIds)`). Receives `allItemIds` as constructor param from `ShoppingListScreen`.

- Added 13 new l10n keys across ja/zh/en ARBs: batch delete, clear-completed, completed divider, segmented control labels, load error/retry.

### Task 2: ShoppingListScreen Shell (TDD — RED then GREEN)

- **ShoppingListScreen** (`lib/features/shopping_list/presentation/screens/shopping_list_screen.dart`): ConsumerWidget shell with Column layout:
  1. SegmentedButton (Public/Private, `listTypeProvider`, `borderInputActive` selected color)
  2. ShoppingFilterBar
  3. `if (batchActive) _BatchHeaderWrapper()` — reads active IDs, passes to ShoppingSelectionHeader
  4. `Expanded(child: _buildBody())` — `filteredShoppingItemsProvider.when(loading/error/data)`
  5. `if (batchActive) ShoppingBatchActionBar()`

- Data callback splits items into active + completed; if both empty returns `ShoppingEmptyState(listType)`; else returns `CustomScrollView` with `SliverReorderableList` (active) + `_CompletedSectionHeader` + `SliverList` (completed).

- `_CompletedSectionHeader` shows a styled divider with `shoppingCompletedDivider` label + `delete_sweep_outlined` icon button that fires `showSoftConfirmDialog` then `ClearCompletedItemsUseCase.execute(listType)` (SC5/DONE-03).

- **Test file**: 9 widget tests covering loading state, empty state, completed section rendering/divider absence, batch chrome visibility with/without batchSelectModeProvider override, CustomScrollView for non-empty list.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flutter 3.44 removed `buildDefaultDragHandles` from SliverReorderableList**
- **Found during:** Task 2 flutter analyze
- **Issue:** Plan specifies `buildDefaultDragHandles: false` but Flutter 3.44 removed this parameter entirely (no such named parameter exists in the SliverReorderableList constructor)
- **Fix:** Removed `buildDefaultDragHandles` — ShoppingItemTile already wraps its drag handle with `ReorderableDragStartListener` which is the canonical Flutter 3.44 approach. Used `onReorderItem` instead of deprecated `onReorder` (provides pre-adjusted index, no manual -1 offset needed).
- **Files modified:** `shopping_list_screen.dart`
- **Commit:** e56c6090

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test) | 935a0f36 | Tests failed as expected (ShoppingListScreen missing) |
| GREEN (feat) | e56c6090 | All 9 tests pass |
| REFACTOR | not needed | Code was clean in GREEN |

## Test Results

- `test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart`: 9/9 pass
- `test/widget/features/shopping_list/` (full scoped suite): 45/45 pass
- `flutter analyze lib/features/shopping_list/presentation/`: No issues found

## Known Stubs

None — all behavior fully wired.

## Threat Flags

No new security-relevant surfaces beyond the plan's threat model.

## Self-Check: PASSED

Files created:
- lib/features/shopping_list/presentation/screens/shopping_list_screen.dart: EXISTS
- lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart: EXISTS
- lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart: EXISTS

Commits:
- b3edafe7: feat(38-06): implement ShoppingBatchActionBar + ShoppingSelectionHeader
- 935a0f36: test(38-06): add failing tests for ShoppingListScreen (RED)
- e56c6090: feat(38-06): implement ShoppingListScreen shell (GREEN)
