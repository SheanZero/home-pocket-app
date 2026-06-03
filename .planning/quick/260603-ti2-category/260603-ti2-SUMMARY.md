---
phase: quick-260603-ti2
plan: "01"
subsystem: data/categories
tags: [migration, drift, schema, default-categories, tdd]
dependency_graph:
  requires: []
  provides: [schemaVersion-19, cat_food_dining_out-first-subcategory]
  affects: [ManualOneStepScreen-default-category, fresh-install-path, upgrade-path]
tech_stack:
  added: []
  patterns: [drift-onUpgrade, in-memory-db-test]
key_files:
  created:
    - test/unit/data/migrations/category_v19_dining_out_first_test.dart
  modified:
    - lib/shared/constants/default_categories.dart
    - lib/data/app_database.dart
    - test/unit/data/migrations/entry_source_v17_migration_test.dart
    - test/unit/data/migrations/index_v15_migration_test.dart
    - test/unit/data/migrations/ledger_type_v18_migration_test.dart
    - test/unit/data/migrations/migration_v15_to_v16_test.dart
    - test/unit/data/migrations/migration_v16_to_v17_test.dart
decisions:
  - "sortOrder swap only — no Dart list reordering needed (runtime sort by sortOrder, not list position)"
  - "v19 migration guards with is_system=1 to avoid touching user-created categories"
  - "Two independent idempotent UPDATEs, no transaction wrapper needed"
  - "Existing migration tests fixed to use greaterThanOrEqualTo (Rule 1 bug fix)"
metrics:
  duration: "~15min"
  completed: "2026-06-03"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
status: complete
---

# Quick Task 260603-ti2: 外出就餐提为食费第一子类目 Summary

**One-liner:** Promoted `cat_food_dining_out` to `sortOrder=1` within `cat_food` via static data update + Drift schema v18→v19 migration, ensuring fresh installs and upgrades both default to 食費→外出就餐 in the manual entry screen.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | sortOrder swap in default_categories.dart + TDD RED migration test | 77a4833a |
| 2 | schemaVersion 18→19 + v19 migration block → GREEN | 9a555830 |

## What Was Built

### Task 1 (TDD RED)

- `lib/shared/constants/default_categories.dart`: swapped `cat_food_groceries` sortOrder 1→2 and `cat_food_dining_out` sortOrder 2→1. No list reordering needed — runtime queries sort by `sort_order ASC`.
- `test/unit/data/migrations/category_v19_dining_out_first_test.dart`: 9 tests in two groups:
  - Group A "DefaultCategories static data (v19)": 4 static data assertions — GREEN immediately after Task 1.
  - Group B "v19 migration — sort_order swap": 5 tests including a schemaVersion guard, two sort_order value assertions, a user-category non-interference test, and an idempotency test — 4 of 5 GREEN (migration SQL runs directly), 1 RED (schemaVersion guard expects >= 19, actual was 18).

### Task 2 (GREEN)

- `lib/data/app_database.dart`:
  - `schemaVersion` bumped from 18 to 19.
  - Added `if (from < 19)` block after the `from < 18` transaction block:
    ```dart
    if (from < 19) {
      await customStatement(
        "UPDATE categories SET sort_order = 1 WHERE id = 'cat_food_dining_out' AND is_system = 1",
      );
      await customStatement(
        "UPDATE categories SET sort_order = 2 WHERE id = 'cat_food_groceries' AND is_system = 1",
      );
    }
    ```

## Assumption Verification

**Plan constraint:** "Verify that 食費 (cat_food) is the FIRST L1 expense category by sortOrder."

`cat_food` has `sortOrder = 1` in `_expenseL1` (first entry in the list). The plan's two requirements align:
- L1 first by sortOrder = cat_food ✓
- L2 first by sortOrder within cat_food = cat_food_dining_out ✓

Both requirements satisfied — no mismatch, execution proceeded normally.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed 5 existing migration test schemaVersion guards using `equals` instead of `greaterThanOrEqualTo`**

- **Found during:** Task 2 full-suite run
- **Issue:** `migration_v15_to_v16_test.dart`, `index_v15_migration_test.dart`, `entry_source_v17_migration_test.dart`, `migration_v16_to_v17_test.dart`, `ledger_type_v18_migration_test.dart` all used `_targetSchemaVersion = 18` with `equals()`. When schemaVersion advanced to 19, all 5 guard tests failed with "expected: <18>, actual: <19>".
- **Fix:** Changed `_targetSchemaVersion` in each file to the minimum correct version for that migration (15/16/17/17/18 respectively), and changed `equals(_target)` to `greaterThanOrEqualTo(_target)` — matching the pattern already used in `category_v14_migration_test.dart` and the new `category_v19_dining_out_first_test.dart`.
- **Files modified:** 5 migration test files listed above
- **Commit:** 9a555830 (included in Task 2 commit)

## Verification Results

### flutter analyze

```
4 issues found (ran in 7.1s)
```
All 4 are pre-existing (build/firebase warning + 2 `onReorder` deprecation infos in `category_selection_screen.dart`). Zero new issues introduced by this task.

### Migration test file (targeted)

```
+9: All tests passed!
```

### Full test suite

```
+2312: All tests passed!
```

(+9 new tests vs 2303 pre-task baseline)

## Known Stubs

None. Both fresh-install and upgrade paths are fully wired:
- Fresh install: `DefaultCategories.all` in the v14 `INSERT OR REPLACE` block inherits the new sortOrder from static data.
- Upgrade: `onUpgrade` `from < 19` block applies the UPDATE SQL.
- `ManualOneStepScreen._initializeDefaultCategory` already queries by `sortOrder ASC` — no change needed.

## Threat Flags

None. The v19 migration only issues internal UPDATE statements with no user-input path (T-ti2-01 disposition: accept).

## Self-Check

- [x] `lib/shared/constants/default_categories.dart` exists and contains `cat_food_dining_out` sortOrder=1
- [x] `lib/data/app_database.dart` contains `schemaVersion => 19` and `from < 19` block
- [x] `test/unit/data/migrations/category_v19_dining_out_first_test.dart` exists with 9 tests
- [x] Commit `77a4833a` exists (Task 1 RED)
- [x] Commit `9a555830` exists (Task 2 GREEN)
- [x] `flutter analyze` 0 new issues
- [x] All 2312 tests pass

## Self-Check: PASSED
