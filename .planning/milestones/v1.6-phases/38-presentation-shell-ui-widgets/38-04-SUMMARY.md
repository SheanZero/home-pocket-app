---
phase: 38-presentation-shell-ui-widgets
plan: "04"
subsystem: ui-shopping-list
status: complete
tags: [flutter, riverpod, shopping-list, tile, dismissible, reorderable, animation, attribution-chip, tdd]

dependency_graph:
  requires:
    - phase: 38-02
      provides: batchSelectModeProvider, toggleItemCompletedUseCaseProvider, deleteShoppingItemUseCaseProvider
    - phase: 38-03
      provides: ARB homeTabTodo updated; import_guard.yaml files
  provides:
    - ShoppingItemTile (SHOP-02/03, DONE-01, MGMT-01/02/03, SYNC-04, D38-01/02)
    - ShoppingItemFormScreen stub (compile-forward reference for Plan 38-07)
    - ARB keys: shoppingDelete*/shoppingEditItem/shoppingReorderItem in ja/zh/en
  affects:
    - 38-06 (ShoppingListScreen consumes ShoppingItemTile as its row widget)
    - 38-07 (ShoppingItemFormScreen stub replaced with full implementation)

tech-stack:
  added: []
  patterns:
    - Dismissible with confirmDismiss (showSoftConfirmDialog) and CRITICAL ordering: showSuccessFeedback BEFORE use-case call (context validity at onDismissed boundary)
    - AnimatedDefaultTextStyle + AnimatedOpacity for 200ms/easeInOut strikethrough + fade (DONE-01)
    - ReorderableDragStartListener(index: index) — required L2 fix for buildDefaultDragHandles:false on SliverReorderableList
    - DismissDirection.none + drag handle hidden when batchSelectModeProvider.state.isActive (MGMT-03 / D38-02)
    - Attribution chip via ref.watch(shadowBooksProvider).value ?? const [] (Riverpod 3 .value, not .valueOrNull)
    - Private list attribution gate at widget level (item.listType == 'public' guard — T-38-04-01)
    - AppTextStyles.amountSmall + palette.joyText (NEVER raw palette.joy — WCAG AA) for estimated price
    - 4px left border: palette.daily / palette.joy / palette.borderList per LedgerType (SHOP-03)

key-files:
  created:
    - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart

key-decisions:
  - "showSuccessFeedback called on the line immediately before deleteShoppingItemUseCaseProvider.execute() in onDismissed — baked into the widget so no screen needs to enforce this ordering (MGMT-01 critical order)"
  - "Attribution chip guarded by item.listType == 'public' at widget level (not only at use-case layer) per T-38-04-01 defense-in-depth"
  - "ShoppingItemFormScreen created as a stub (Scaffold + CircularProgressIndicator) to allow tile to compile — Plan 38-07 replaces with full implementation; both compile correctly at this stage"
  - "Tests use overrideWithValue(MockUseCase) with Mocktail rather than fake classes to satisfy Riverpod 3 typed provider overrides; shadowBooksProvider passed via named parameter to _pumpTile to avoid duplicate-override assertion"
  - "Swipe test fling requires pump() + pump(500ms) after tester.fling before asserting Dialog is visible (confirmDismiss is async)"

metrics:
  duration: "~45 minutes"
  completed: "2026-06-08"
  tasks_completed: 2
  files_changed: 11
---

# Phase 38 Plan 04: ShoppingItemTile — Core List Widget Summary

**One-liner:** ConsumerWidget ShoppingItemTile with animated toggle, dual-ledger left-border, swipe-delete (feedback-BEFORE-use-case ordering), batch-mode guard, family attribution chip on public tiles, and ReorderableDragStartListener drag handle.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Implement ShoppingItemTile + ARB keys + ShoppingItemFormScreen stub | 13c201dd | shopping_item_tile.dart, shopping_item_form_screen.dart, app_*.arb, app_localizations*.dart |
| 2 | Fill in shopping_item_tile_test.dart + shopping_item_tile_swipe_test.dart | 71998d7f | shopping_item_tile_test.dart, shopping_item_tile_swipe_test.dart |

## What Was Built

### Task 1: ShoppingItemTile (SHOP-02/03, DONE-01, MGMT-01/02/03, SYNC-04, D38-01/02)

`lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` is a `ConsumerWidget` with:

- **SHOP-02**: item.name rendered as primary text via `AnimatedDefaultTextStyle(AppTextStyles.bodyLarge)`.
- **SHOP-03**: 4px `BorderSide` on left — `palette.daily` / `palette.joy` / `palette.borderList` per `item.ledgerType`.
- **DONE-01**: `GestureDetector.onTap` → `ref.read(toggleItemCompletedUseCaseProvider).execute(item.id)`. `AnimatedDefaultTextStyle` transitions to `TextDecoration.lineThrough + palette.textTertiary`; `AnimatedOpacity` transitions to 0.5 opacity; both at 200ms/`Curves.easeInOut`.
- **MGMT-01**: `Dismissible.confirmDismiss` → `showSoftConfirmDialog`. `onDismissed`: `showSuccessFeedback` first, then `ref.read(deleteShoppingItemUseCaseProvider).execute(item.id)` — feedback before use-case call per context-validity constraint.
- **MGMT-02**: `GestureDetector.onLongPress` → `batchSelectModeProvider.notifier.enter()` + `.toggle(item.id)` (when not in batch mode).
- **MGMT-03**: `direction: batchActive ? DismissDirection.none : DismissDirection.endToStart`; drag handle hidden with `if (!batchActive)` guard.
- **SYNC-04**: Attribution chip rendered only when `item.listType == 'public' && item.addedByBookId != null`; resolved via `ref.watch(shadowBooksProvider).value ?? const []` (Riverpod 3 `.value`, not `.valueOrNull`); silently omits with `SizedBox.shrink()` when shadow book not yet synced.
- **D38-01**: Edit chevron in trailing cluster with `Semantics(label: S.of(ctx).shoppingEditItem, button: true)` and ≥44px hit target via `SizedBox(width:44, height:44)`.
- **D38-02**: `ReorderableDragStartListener(index: index)` wrapping drag-handle icon; hidden in batch mode; `Semantics(label: S.of(ctx).shoppingReorderItem, button: true)`.
- Estimated price: `AppTextStyles.amountSmall.copyWith(color: palette.dailyText / palette.joyText / palette.textSecondary)` — never raw `palette.joy` (WCAG AA).

Also added:
- `ShoppingItemFormScreen` stub (Plan 38-07 will replace with full form).
- 7 new ARB keys in ja/zh/en: `shoppingDeleteConfirmTitle`, `shoppingDeleteConfirmBody`, `shoppingDeleteConfirmButton`, `shoppingDeleteCancelButton`, `shoppingDeletedSnackBar`, `shoppingEditItem`, `shoppingReorderItem`.

### Task 2: Widget Tests

**`shopping_item_tile_test.dart`** (10 tests):
- SHOP-02: item.name as Text widget.
- SHOP-03: 3 tests for daily/joy/null left-border Container `BorderSide` color matching `AppPalette.light`.
- DONE-01: tap GestureDetector → verify Mocktail `mockToggle.execute(item.id)` called.
- MGMT-03: 2 tests — batch isActive → `DismissDirection.none`; batch inactive → `DismissDirection.endToStart`.
- SYNC-04: 3 tests — public+resolvable → chip visible; public+null → no chip; private+resolvable → no chip (T-38-04-01).

**`shopping_item_tile_swipe_test.dart`** (4 tests):
- Fling → Dialog appears.
- Confirm → `deleteUseCase.execute(item.id)` called.
- Cancel → use case NOT called.
- Confirm + ordering → use case called (structural ordering verified by line-sequence in widget source).

## Verification

All plan verification criteria met:

```
grep -n "ReorderableDragStartListener" .../shopping_item_tile.dart → line 269 (1 hit)
grep -n "DismissDirection.none" .../shopping_item_tile.dart → line 57 (1 hit)
grep -n "showSuccessFeedback" .../shopping_item_tile.dart → line 74 (before deleteShoppingItemUseCaseProvider at line 75)
flutter test test/widget/features/shopping_list/presentation/widgets/ → 24/24 tests pass
flutter analyze lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart → No issues found
Full suite: 2416/2416 tests pass (net +30 vs baseline 2386)
```

## Deviations from Plan

### Auto-added: ShoppingItemFormScreen stub (Rule 2 — missing critical compile dependency)

- **Found during:** Task 1
- **Issue:** The tile's trailing chevron calls `Navigator.push(ShoppingItemFormScreen(...))`. `ShoppingItemFormScreen` is built in Plan 38-07 (not yet landed); without a stub the tile fails to compile in Wave 2 parallel execution.
- **Fix:** Created `lib/features/shopping_list/presentation/widgets/shopping_item_form_screen.dart` as a stub `StatelessWidget` with the correct constructor signature (`{required String listType, ShoppingItem? item}`). Plan 38-07 replaces the body with full implementation.
- **Files modified:** `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` (created)
- **Commit:** 13c201dd

### Auto-fixed: Test pattern deviation (Rule 1 — type error in provider overrides)

- **Found during:** Task 2
- **Issue:** Initial test implementation used duck-typed fake classes with `overrideWith(() => _FakeUseCase())`, which fails Riverpod 3's typed provider override — the return type must match the provider's declared type exactly.
- **Fix:** Switched to `overrideWithValue(mockUseCase)` with Mocktail `Mock implements DeleteShoppingItemUseCase` stubs.
- **Impact:** No behavior change, Mocktail pattern consistent with existing tile tests.

### Auto-fixed: Duplicate shadowBooksProvider override assertion (Rule 1 — test failure)

- **Found during:** Task 2
- **Issue:** `_pumpTile` helper had a default `shadowBooksProvider` override; test scenarios also passed `shadowBooksProvider` in `extraOverrides`, triggering Riverpod 3 "provider overridden twice" assertion.
- **Fix:** Refactored `_pumpTile` to accept a named `shadowBooksOverride` parameter that replaces the default, rather than appending to it.
- **Impact:** No semantic change; test isolation preserved.

### Auto-fixed: Dialog requires extra pump frames (Rule 1 — test failure)

- **Found during:** Task 2 swipe tests
- **Issue:** `Dismissible.confirmDismiss` calls `showDialog` asynchronously; `await tester.pump()` alone was insufficient to schedule the dialog. The dialog finder returned 0 matches.
- **Fix:** Added `await tester.pump(const Duration(milliseconds: 500))` after the initial `pump()` to allow the `confirmDismiss` future to resolve and the dialog route to inflate.
- **Impact:** Reliable test execution; matches Flutter test patterns for async dialog scheduling.

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| threat_flag: information_disclosure | shopping_item_tile.dart | Attribution chip guard `item.listType == 'public'` — defense-in-depth at widget level; primary gate is at use-case layer (D37-06). Test T-38-04-01 asserts no chip on private tiles. |

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart | `body: Center(child: CircularProgressIndicator())` | Plan 38-07 implements the full form. Stub exists only to unblock Plan 38-04 tile compilation in Wave 2 parallel execution. |

## Self-Check

- [x] `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` exists
- [x] `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` exists
- [x] `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` has real tests
- [x] `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart` has real tests
- [x] Commit 13c201dd exists
- [x] Commit 71998d7f exists

## Self-Check: PASSED
