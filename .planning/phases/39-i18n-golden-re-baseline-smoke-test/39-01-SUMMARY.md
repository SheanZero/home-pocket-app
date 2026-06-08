---
phase: 39-i18n-golden-re-baseline-smoke-test
plan: "01"
subsystem: i18n
status: complete
tags: [i18n, arb, localization, nav-rename, shopping-list]
dependency_graph:
  requires: []
  provides: [homeTabShopping ARB key, shortened nav label]
  affects: [lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb, lib/generated/app_localizations*.dart, home_bottom_nav_bar.dart]
tech_stack:
  added: []
  patterns: [flutter-gen-l10n, ARB key rename]
key_files:
  created: []
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
    - test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
decisions:
  - "ARB key homeTabTodo renamed to homeTabShopping across all 3 locales atomically"
  - "todoTab stale key deleted (and its @todoTab metadata) from all 3 ARBs per D39-02"
  - "Shortened values: 買い物 (ja), 购物 (zh), Shopping (en) per D39-01"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  tasks_total: 2
  files_modified: 9
  completed_date: "2026-06-08"
---

# Phase 39 Plan 01: ARB Key Rename + Stale Key Deletion Summary

**One-liner:** ARB key rename homeTabTodo→homeTabShopping with shortened values (買い物/购物/Shopping), stale todoTab deletion across all 3 locales, Dart call site updated, gen-l10n regenerated.

## What Was Built

Satisfied NAV-03 (SC1 + SC2) by renaming the ARB key `homeTabTodo` to `homeTabShopping` with the shortened label values per D39-01, deleting the stale `todoTab` key (and both @-metadata blocks) from all three ARB files, updating the single Dart call site in `home_bottom_nav_bar.dart`, updating the test label assertions, and regenerating `lib/generated/app_localizations*.dart` via `flutter gen-l10n`.

## Tasks Completed

### Task 1: ARB key rename + stale key deletion (all 3 locales, atomic)
- **Commit:** `f14514e0`
- Renamed `"homeTabTodo"` to `"homeTabShopping"` in app_ja.arb / app_zh.arb / app_en.arb
- Updated values: `"買い物"` (ja), `"购物"` (zh), `"Shopping"` (en) per D39-01
- Renamed `"@homeTabTodo"` to `"@homeTabShopping"` with updated description in all 3 files
- Deleted `"todoTab"` key and `"@todoTab"` metadata block from all 3 files
- SC1: `jq 'keys|length'` = 1075 for all three files (parity confirmed)
- SC2: `grep -rn 'homeTabTodo|todoTab|待办|Todo' lib/l10n/` returns 0 hits
- All three ARBs remain valid JSON (jq parse confirms)

### Task 2: Update Dart call site, nav test assertions, and run flutter gen-l10n
- **Commit:** `f36ed030`
- `home_bottom_nav_bar.dart:45`: `l10n.homeTabTodo` → `l10n.homeTabShopping`
- `home_bottom_nav_bar_shopping_test.dart`: updated 3 label assertions (+ 3 test descriptions)
  - `find.text('買い物リスト')` → `find.text('買い物')`
  - `find.text('购物清单')` → `find.text('购物')`
  - `find.text('Shopping List')` → `find.text('Shopping')`
- Negation assertions (やること / 待办事项 / Todo) left unchanged
- `flutter gen-l10n` ran with 0 warnings; regenerated 4 files in `lib/generated/`
- All 5 nav bar shopping tests pass

## Verification Results

| Check | Result |
|-------|--------|
| SC2: grep stale ARB keys | PASS: 0 hits |
| SC1: jq keys parity | PASS: 1075 for all 3 files |
| No Dart refs to old keys | PASS: 0 refs (excl. generated) |
| flutter gen-l10n | PASS: 0 warnings |
| home_bottom_nav_bar_shopping_test.dart | PASS: 5/5 tests |

## Deviations from Plan

None — plan executed exactly as written. Both tasks completed atomically in order. The `lib/generated/` files are gitignored in the project's root `.gitignore`, but the worktree's local git tracked them correctly (as confirmed by the 6-file commit including all 4 generated files).

## Known Stubs

None. All ARB values are real translations; no placeholder text introduced.

## Threat Flags

None. This plan performs i18n string rename only — no new runtime behavior, no new data flows, no security surface changes.

## Self-Check

Files created/modified:
- `lib/l10n/app_ja.arb` — FOUND (modified, committed in f14514e0)
- `lib/l10n/app_zh.arb` — FOUND (modified, committed in f14514e0)
- `lib/l10n/app_en.arb` — FOUND (modified, committed in f14514e0)
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` — FOUND (modified, committed in f36ed030)
- `test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` — FOUND (modified, committed in f36ed030)
- `lib/generated/app_localizations*.dart` (4 files) — FOUND (regenerated, committed in f36ed030)

Commits:
- `f14514e0` — feat(39-01): rename ARB key homeTabTodo→homeTabShopping, delete todoTab
- `f36ed030` — feat(39-01): update Dart call site, test assertions, regenerate l10n

## Self-Check: PASSED
