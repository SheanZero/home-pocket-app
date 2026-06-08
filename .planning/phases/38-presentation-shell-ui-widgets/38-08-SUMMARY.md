---
phase: 38-presentation-shell-ui-widgets
plan: "08"
subsystem: nav-shell-integration
tags: [flutter, riverpod, navigation, fab, batch-mode, i18n]
status: complete

dependency_graph:
  requires:
    - "38-06"  # ShoppingListScreen + batch chrome (4th-tab body)
    - "38-07"  # ShoppingItemFormScreen (FAB index-3 destination)
  provides:
    - Context-aware FAB routing (index 3 → add shopping item; else → transaction entry)
    - ShoppingListScreen wired as 4th IndexedStack child (replaces todoTab placeholder)
    - Batch-mode chrome guard (hides nav bar + FAB while batchSelectMode active)
  affects:
    - lib/features/home/presentation/screens/main_shell_screen.dart
    - test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart
    - test/widget/features/home/presentation/screens/main_shell_screen_test.dart

tech_stack:
  patterns:
    - Context-aware FAB branch (currentIndex == 3 ? add-item : transaction-entry)
    - Conditional Positioned wrapper (if (!batchActive)) to hide nav bar + FAB
    - SC1 invariant: all 6 post-entry ref.invalidate calls preserved verbatim in else branch
    - MockNavigatorObserver route-type assertions for FAB routing tests

key_files:
  modified:
    - lib/features/home/presentation/screens/main_shell_screen.dart
    - test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart
    - test/widget/features/home/presentation/screens/main_shell_screen_test.dart

decisions:
  - "Ran sequentially on main (not worktree) so the wiring landed on main for on-device human-verify; the checkpoint requires testing the real running app, not a throwaway worktree."
  - "i18n regression fix folded into this plan: Wave 3 batch chrome (shopping_batch_action_bar.dart, shopping_selection_header.dart) had hardcoded CJK (件/件選択中) failing hardcoded_cjk_ui_scan_test. Moved to ARB keys shoppingSelectionCount + shoppingBatchSelectingCount (ja/zh/en) and made 38-06 screen tests locale-independent (find.byType instead of find.textContaining('件'))."

metrics:
  duration: "~30 minutes (incl. i18n remediation + human verification)"
  completed_date: "2026-06-08"
  tasks_completed: 3
  files_modified: 3
  human_verification: "approved (10/10 manual steps)"
---

# Phase 38 Plan 08: Wire Shopping List into Main Shell Summary

Final integration plan. Wires the shopping list feature into the app's main navigation shell: replaces the 4th-tab `todoTab` placeholder with `ShoppingListScreen`, adds a context-aware FAB (index 3 routes to the add-shopping-item form; every other index routes to the existing transaction-entry flow with all post-entry invalidations preserved verbatim), and hides the bottom nav bar + FAB while batch-selection mode is active.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Wire main_shell_screen — placeholder→ShoppingListScreen, context-aware FAB, batch guard | `ee504b17` | lib/features/home/presentation/screens/main_shell_screen.dart |
| 2 | FAB routing tests + batch-guard visibility tests | `bb4b83fc` | main_shell_screen_fab_test.dart, main_shell_screen_test.dart |
| 3 | Human-verify checkpoint (10 manual steps) | — | (approved) |

Post-checkpoint i18n remediation: `36702839` — move hardcoded CJK batch-chrome count strings to ARB; locale-independent screen tests.

## SC1 Accounting-Regression Invariant

All 6 post-`ManualOneStepScreen` invalidation calls preserved verbatim in the FAB `else` branch (grep-verified):
`monthlyReportProvider`, `todayTransactionsProvider`, `bestJoyMomentProvider`, `happinessReportProvider` (conditional on `bookAsync.hasValue`), `listTransactionsProvider`, `calendarDailyTotalsProvider`.

## Verification

- `flutter analyze` — 0 phase-38 issues (4 remaining are pre-existing: firebase build artifacts + category_selection deprecations)
- FAB routing tests (NAV-01): 3/3 — index 3 → ShoppingItemFormScreen; index 0/1 → ManualOneStepScreen
- Batch-guard tests (D38-03): nav bar absent when active, present when inactive
- `hardcoded_cjk_ui_scan_test`: passes (i18n regression fixed)
- Full suite: **2445/2445 passed** (SC1 accounting regression green)
- Human verification: **approved** — all 10 manual steps passed on device

## Notable Deviation

A phase-introduced i18n regression (hardcoded CJK in Wave 3 batch chrome) was caught only by the full architecture suite during this plan's verification (the per-wave scoped gates missed it). Remediated here rather than deferred, since it both violates the project i18n rule and broke a committed test.
