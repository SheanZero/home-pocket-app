---
phase: 38-presentation-shell-ui-widgets
plan: "03"
subsystem: home-nav-shopping-list
status: complete
tags: [nav, i18n, import_guard, shopping_list, arb]
dependency_graph:
  requires: [38-01]
  provides: [nav-shopping-bag-icon, arb-homeTabTodo-updated, shopping-list-import-guard-dirs]
  affects: [home_bottom_nav_bar, app_localizations, shopping_list_presentation]
tech_stack:
  added: []
  patterns: [thin-feature-import-guard, active-inactive-icon-pair, arb-value-update]
key_files:
  created:
    - lib/features/shopping_list/presentation/screens/import_guard.yaml
    - lib/features/shopping_list/presentation/widgets/import_guard.yaml
  modified:
    - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart
    - test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
    - test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
decisions:
  - "Active icon uses _activeIcons[index], inactive uses _icons[index] via a second const list pattern (cleanest Dart approach vs special-casing index 3 in _buildTab)"
  - "import_guard.yaml files for screens/ and widgets/ use inherit:true to chain deny rules from parent presentation/import_guard.yaml"
  - "Nav bar test in shopping_list test directory tests all 3 locales + active/inactive icon states"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-08"
  tasks_completed: 2
  files_changed: 7
---

# Phase 38 Plan 03: Shopping Bag Icon + ARB Update + Import Guard Files Summary

**One-liner:** 4th nav tab renamed to 買い物リスト/购物清单/Shopping List with shopping bag icon, plus import_guard scaffold for new shopping list presentation subdirectories.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Update home_bottom_nav_bar.dart — shopping bag icon for 4th tab (NAV-02) | c30d42e4 | home_bottom_nav_bar.dart |
| 2 | Update ARB homeTabTodo values + create import_guard.yaml files (NAV-02) | b4624cdc | app_*.arb, import_guard.yaml (x2), test files |

## What Was Built

### Task 1: Shopping Bag Icon (NAV-02)

`home_bottom_nav_bar.dart` now has two icon lists:
- `_icons` (inactive): index 3 changed from `Icons.check_box_outlined` to `Icons.shopping_bag_outlined`
- `_activeIcons` (active): new const list, mirrors `_icons` with index 3 as `Icons.shopping_bag`
- `_buildTab` updated to select `isActive ? _activeIcons[index] : _icons[index]`

### Task 2: ARB Updates + Import Guard Files

ARB value updates (key unchanged per NAV-03 defer rule):
- `app_ja.arb`: "homeTabTodo" = "買い物リスト"
- `app_zh.arb`: "homeTabTodo" = "购物清单"
- `app_en.arb`: "homeTabTodo" = "Shopping List"

`flutter gen-l10n` ran clean (generated files are gitignored).

New import_guard.yaml files created:
- `lib/features/shopping_list/presentation/screens/import_guard.yaml` — `inherit: true`
- `lib/features/shopping_list/presentation/widgets/import_guard.yaml` — `inherit: true`

Both inherit the deny rules from the parent `presentation/import_guard.yaml` (blocks infrastructure/daos/tables).

Test implementation: `home_bottom_nav_bar_shopping_test.dart` replaced stub with 5 assertions covering all 3 locales + active/inactive icon states.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed stale 'やること' assertions in two existing nav bar test files**
- **Found during:** Task 2
- **Issue:** `test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart` (line 96) and `test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart` (line 27) both assert `expect(find.text('やること'), findsOneWidget)` which would fail after the ARB update
- **Fix:** Updated both to `find.text('買い物リスト')`
- **Files modified:** Both nav bar test files listed above
- **Commit:** b4624cdc

## Verification Results

- `grep "shopping_bag" lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` — 2 lines returned (shopping_bag_outlined + shopping_bag)
- `grep "買い物リスト" lib/l10n/app_ja.arb` — 1 hit
- `grep "购物清单" lib/l10n/app_zh.arb` — 1 hit
- `flutter gen-l10n` — exits 0
- `flutter analyze lib/features/home/presentation/widgets/` — No issues found
- `flutter test test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` — 5/5 passed
- All 17 nav bar tests across 3 test files: 17/17 passed

## Known Stubs

None — plan goal fully achieved. ARB values are live; icons render correctly; import_guard files exist for both subdirectories.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The ARB string update is user-visible label only; import_guard.yaml files enforce boundary rules. No threat flags.

## Self-Check: PASSED

- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` — FOUND
- `lib/l10n/app_ja.arb` (contains 買い物リスト) — FOUND
- `lib/l10n/app_zh.arb` (contains 购物清单) — FOUND
- `lib/l10n/app_en.arb` (contains Shopping List) — FOUND
- `lib/features/shopping_list/presentation/screens/import_guard.yaml` — FOUND
- `lib/features/shopping_list/presentation/widgets/import_guard.yaml` — FOUND
- Task 1 commit c30d42e4 — FOUND
- Task 2 commit b4624cdc — FOUND
