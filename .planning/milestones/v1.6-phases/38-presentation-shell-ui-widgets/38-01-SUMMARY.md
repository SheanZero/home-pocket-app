---
phase: 38-presentation-shell-ui-widgets
plan: "01"
subsystem: shopping_list/domain
tags: [freezed, build_runner, test_infra, wave0_blocker]
requires: []
provides:
  - ShoppingListFilter.categoryIds field (Set<String>)
  - test/widget/features/shopping_list/ directory tree
  - test/unit/features/shopping_list/ directory tree
  - mock_use_cases.dart with 6 Mocktail stubs + shoppingRepositoryOverride
affects:
  - lib/features/shopping_list/domain/models/shopping_list_filter.dart
  - lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart
  - test/widget/features/shopping_list/ (9 stub test files)
  - test/unit/features/shopping_list/ (1 stub test file)
tech_stack:
  added: []
  patterns: [freezed, mocktail, stub_test_pattern]
key_files:
  created:
    - test/widget/features/shopping_list/helpers/mock_use_cases.dart
    - test/unit/features/shopping_list/providers/state_shopping_filter_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
    - test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart
    - test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart
  modified:
    - lib/features/shopping_list/domain/models/shopping_list_filter.dart
    - lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart
    - lib/features/family_sync/presentation/providers/repository_providers.g.dart
decisions:
  - "mock_use_cases.dart defers use-case provider overrides via TODO comments — those providers don't exist until Wave 1; the file compiles cleanly in Wave 0"
  - "family_sync/repository_providers.g.dart hash updated as expected side effect of full build_runner run"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 10
  files_modified: 3
---

# Phase 38 Plan 01: Wave 0 Blocker Removal — categoryIds + Test Infra Summary

Wave 0 blocker removal: added `Set<String> categoryIds` to `ShoppingListFilter`, regenerated Freezed code, and created all test infrastructure scaffolds for Phase 38 downstream plans.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add categoryIds to ShoppingListFilter + build_runner | 40fe2e55 | shopping_list_filter.dart, .freezed.dart, family_sync/.g.dart |
| 2 | Test directory tree + mock use-case helpers | 33f12dea | mock_use_cases.dart + 9 stub test files |

## Verification Results

- `flutter pub run build_runner build --delete-conflicting-outputs` exits 0
- `grep -c "categoryIds" shopping_list_filter.freezed.dart` returns 31 (requirement: ≥1)
- `flutter test test/widget/features/shopping_list/ test/unit/features/shopping_list/` — 9/9 pass
- `flutter analyze lib/features/shopping_list/domain/models/` — 0 issues
- `flutter analyze test/widget/features/shopping_list/ test/unit/features/shopping_list/` — 0 issues

## Deviations from Plan

### Auto-handled differences

**1. [Rule 2 - Scope adaptation] mock_use_cases.dart provider overrides deferred to Wave 1**
- **Found during:** Task 2 implementation
- **Issue:** The plan requested `shoppingTestOverrides(...)` helper with 6 use-case provider overrides (e.g. `createShoppingItemUseCaseProvider`), but those providers do not exist yet — they will be created in Phase 38 Wave 1 plans. Importing non-existent providers would cause compile errors and break the Wave 0 "all stub files compile" requirement.
- **Fix:** The 6 mock classes (MockCreateShoppingItemUseCase, etc.) are declared. The `shoppingTestOverrides(...)` function is deferred with a TODO comment. The `shoppingRepositoryOverride(MockShoppingItemRepository)` helper is fully implemented as it references the existing `shoppingItemRepositoryProvider`.
- **Files modified:** test/widget/features/shopping_list/helpers/mock_use_cases.dart
- **Impact:** Zero — Wave 1 plans that need the full provider overrides will fill in the TODO when providers exist.

**2. [Info] family_sync/repository_providers.g.dart hash updated**
- **Found during:** Task 1 build_runner run
- **Issue:** Running `build_runner build --delete-conflicting-outputs` on the full project regenerated a hash in `lib/features/family_sync/presentation/providers/repository_providers.g.dart` (hash drift in `_$applySyncOperationsUseCaseHash`).
- **Fix:** Staged and committed with Task 1 as expected build artifact.

## Known Stubs

All 9 test files are intentional stubs (`test('stub', () {})`). They are placeholder files for Wave 1–4 tests that will replace them with real assertions. This is the plan's intent, not a defect.

The mock_use_cases.dart file has 3 TODO markers for:
- Wave-1 `state_shopping_filter.dart` import
- Wave-1 `state_shopping_batch.dart` import
- Wave-1 use-case provider overrides in `shoppingTestOverrides(...)`

## Threat Flags

None. The `categoryIds` field contains internal category UUIDs (no PII). No new network endpoints, auth paths, or file access patterns introduced.

## Self-Check: PASSED

Files exist:
- FOUND: lib/features/shopping_list/domain/models/shopping_list_filter.dart
- FOUND: lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart
- FOUND: test/widget/features/shopping_list/helpers/mock_use_cases.dart
- FOUND: test/unit/features/shopping_list/providers/state_shopping_filter_test.dart
- FOUND: test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
- FOUND: test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart

Commits exist:
- FOUND: 40fe2e55 feat(38-01): add categoryIds field to ShoppingListFilter + regenerate Freezed
- FOUND: 33f12dea test(38-01): create test infra directory tree + mock use-case helpers
