---
phase: 38-presentation-shell-ui-widgets
plan: "05"
subsystem: shopping_list/presentation/widgets
tags: [shopping-list, empty-state, filter-bar, l3-fix, category-filter-sheet]
requirements: [SHOP-04, FILT-01, FILT-02, FILT-03]
dependency_graph:
  requires: ["38-02", "38-03"]
  provides:
    - lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - lib/features/list/presentation/widgets/list_category_filter_sheet.dart (patched onApply)
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart (stub)
  affects:
    - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
    - lib/l10n/app_ja.arb, app_zh.arb, app_en.arb
tech_stack:
  added: []
  patterns:
    - ShoppingEmptyVariant enum + switch for 3-way empty state
    - CategoryFilterSheet onApply callback (backwards-compatible L3 fix)
    - ShoppingFilterBar with shoppingFilterProvider (independent of listFilterProvider)
key_files:
  created:
    - lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
  modified:
    - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
decisions:
  - "ShoppingItemFormScreen stub created to unblock ShoppingEmptyState CTA reference (Plan 07 implements fully)"
  - "ARB keys added in Phase 38 with final values as per UI-SPEC copywriting contract; Phase 39 owns l10n parity check"
  - "Test pump() + explicit Duration used for CTA navigation test to avoid pumpAndSettle timeout on stub CircularProgressIndicator"
  - "isGroupModeProvider returns bool directly (not AsyncValue) — patterns.md .value ?? false is incorrect; used ref.watch(isGroupModeProvider) directly"
metrics:
  duration: "7 minutes"
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 5
  files_modified: 4
status: complete
---

# Phase 38 Plan 05: L3 Fix + ShoppingEmptyState + ShoppingFilterBar Summary

Delivered the backwards-compatible L3 fix to `CategoryFilterSheet`, the 3-variant `ShoppingEmptyState`, and the shopping-specific `ShoppingFilterBar` (with correct `shoppingFilterProvider` wiring via the L3-fixed `onApply` callback). Widget tests for both new widgets pass; existing list feature tests unbroken.

## Completed Tasks

### Task 1: L3 fix to CategoryFilterSheet + ShoppingEmptyState (SHOP-04, L3)

**Commit:** `8d7a43ff`

**CategoryFilterSheet L3 fix** (`lib/features/list/presentation/widgets/list_category_filter_sheet.dart`):
- Added optional `final ValueChanged<Set<String>>? onApply` parameter to the constructor
- Apply button branches: `if (widget.onApply != null) { widget.onApply!(_localSelected); Navigator.pop(context); } else { ref.read(listFilterProvider.notifier).setCategories(...); ... }`
- Zero impact on existing call sites (no `onApply` arg passed -> listFilterProvider write preserved)
- All 28 existing list feature tests still pass post-patch

**ShoppingEmptyState** (`lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart`):
- `enum ShoppingEmptyVariant { privateEmpty, publicSolo, publicFamily }`
- `class ShoppingEmptyState extends ConsumerWidget` with `required String listType`
- Variant determined via `ref.watch(isGroupModeProvider)` (returns `bool` directly)
- Switch produces `(icon, heading, body)` tuple from `S.of(context)` ARB keys
- Layout mirrors `list_empty_state.dart`: Center -> Padding(32) -> Column(min) -> Icon(48) + headings + CTA
- CTA uses `palette.borderInputActive` (leaf green) -> pushes `ShoppingItemFormScreen(listType: listType)`

**ShoppingItemFormScreen stub** (`lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`):
- Minimal `StatelessWidget` stub with correct constructor signature (`listType`, `item?`)
- Required so `ShoppingEmptyState` CTA compiles; Plan 07 replaces with full implementation

**ARB keys** (11 new keys x 3 locales = 33 entries):
- `shoppingEmptyPrivateHeading/Body`, `shoppingEmptyPublicSoloHeading/Body`, `shoppingEmptyPublicFamilyHeading/Body`, `shoppingEmptyCta`
- `shoppingFilterLedgerAll`, `shoppingFilterStatusActive`, `shoppingFilterStatusAll`, `shoppingFilterCategory`
- Values follow UI-SPEC copywriting contract; Phase 39 runs gen-l10n parity gate

### Task 2: ShoppingFilterBar + widget tests (FILT-01, FILT-02, FILT-03)

**Commit:** `0c2301bb`

**ShoppingFilterBar** (`lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart`):
- `ConsumerWidget`, reads `shoppingFilterProvider`
- Container(height:44) + SingleChildScrollView(horizontal, padding:16/6) + Row
- Chip order: All | 日常 | 悦己 | Category | Status | [Clear-all if anyFilterActive]
- Ledger chips: active = dailyLight/joyLight bg + daily/joy border; inactive = card + borderDefault
- Category chip: opens `CategoryFilterSheet` with `onApply` callback writing to `shoppingFilterProvider.notifier.setCategoryIds` — L3 fix applied
- Status chip toggles 'active' / 'all' via `setStatusFilter`
- `anyFilterActive = filter.ledgerType != null || filter.categoryIds.isNotEmpty || filter.statusFilter != 'all'`
- Clear-all chip: conditional on `anyFilterActive`, calls `clearAll()` (FILT-03)

**Test files:**
- `shopping_empty_state_test.dart` (5 tests): SHOP-04 privateEmpty/publicSolo/publicFamily icons; CTA navigation; private-always-privateEmpty invariant
- `shopping_filter_bar_test.dart` (5 tests): FILT-01 chip rendering; FILT-03 clear-all visible + clearAll(); clear-all hidden; ledger chip toggle

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ShoppingItemFormScreen did not exist**
- **Found during:** Task 1 — ShoppingEmptyState CTA needed to reference `ShoppingItemFormScreen`
- **Issue:** Plan 07 creates the form screen; without it the widget would not compile
- **Fix:** Created a minimal `StatelessWidget` stub with the correct constructor signature
- **Files modified:** `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` (new)
- **Commit:** `8d7a43ff`

**2. [Rule 1 - Bug] PATTERNS.md has incorrect isGroupModeProvider usage**
- **Found during:** Task 1 — PATTERNS.md shows `ref.watch(isGroupModeProvider).value ?? false`
- **Issue:** `isGroupModeProvider` returns `bool` directly (not `AsyncValue<bool>`); `.value` would fail
- **Fix:** Used `ref.watch(isGroupModeProvider)` directly
- **Files modified:** `shopping_empty_state.dart` implementation

**3. [Rule 3 - Blocking] pumpAndSettle timeout on CTA navigation test**
- **Found during:** Task 2 test run — stub `ShoppingItemFormScreen` renders `CircularProgressIndicator`
- **Fix:** Replaced `pumpAndSettle()` with `pump() + pump(Duration(milliseconds: 300))`
- **Files modified:** `shopping_empty_state_test.dart`
- **Commit:** `0c2301bb`

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` | 25 | Stub scaffold — full implementation is Plan 07 scope. CTA navigation verified in tests. |

## Verification Results

- `grep "onApply" list_category_filter_sheet.dart` -> 7 hits ✓
- `grep "ShoppingEmptyVariant" shopping_empty_state.dart` -> 8 hits ✓
- `grep "shoppingFilterProvider" shopping_filter_bar.dart` -> 9 hits ✓
- `flutter test shopping_empty_state_test.dart shopping_filter_bar_test.dart` -> 10/10 pass ✓
- `flutter analyze lib/features/shopping_list/` -> No issues ✓
- `flutter test test/widget/features/list/` -> 28/28 pass (backwards-compatible) ✓

## Self-Check: PASSED

All commits verified:
- `8d7a43ff` — Task 1 (L3 fix + ShoppingEmptyState + stub screen + ARB keys)
- `0c2301bb` — Task 2 (ShoppingFilterBar + filled test files)
