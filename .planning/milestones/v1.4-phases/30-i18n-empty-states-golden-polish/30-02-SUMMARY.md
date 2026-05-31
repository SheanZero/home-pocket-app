---
phase: 30-i18n-empty-states-golden-polish
plan: "02"
subsystem: list-feature
tags: [empty-state, i18n, semantics, accessibility, enum, riverpod, tdd]
dependency_graph:
  requires:
    - "30-01 — ARB keys for listEmptyDay, listEmptyDayClear, listLoadError, listCalNavPrev/Next/CurrentMonth"
  provides:
    - "lib/features/list/presentation/widgets/list_empty_state.dart — 3-state enum-driven widget"
    - "lib/features/list/presentation/screens/list_screen.dart — anyOtherFilter-priority branching + localized error"
    - "lib/features/list/presentation/widgets/list_calendar_header.dart — localized Semantics labels"
    - "test/widget/features/list/list_empty_state_test.dart — 3-variant widget tests"
    - "test/unit/features/list/presentation/providers/list_filter_notifier_test.dart — D-05 day-only-clear test"
    - "docs/worklog/30-d08-hardcoded-string-inventory.md — D-08 deferred inventory"
  affects:
    - "list tab empty state rendering (visual + accessibility)"
    - "filter-clear behavior: day-only vs. clearAll distinction"
tech_stack:
  added: []
  patterns:
    - "enum-driven switch dispatch (3-state variant → icon/message/action 4-tuple)"
    - "anyOtherFilter-priority branching for D-05 variant selection"
    - "D-05 selectDay(null) day-only clear — distinct from clearAll()"
key_files:
  created:
    - docs/worklog/30-d08-hardcoded-string-inventory.md
  modified:
    - lib/features/list/presentation/widgets/list_empty_state.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_calendar_header.dart
    - test/widget/features/list/list_empty_state_test.dart
    - test/unit/features/list/presentation/providers/list_filter_notifier_test.dart
decisions:
  - "D-04/D-06: 3-state ListEmptyVariant enum with locked copy via ARB keys (S.of(context))"
  - "D-05: anyOtherFilter checked first; dayEmpty.onAction = selectDay(null) NOT clearAll()"
  - "D-12: '[data load error]' replaced with S.of(context).listLoadError"
  - "D-13: 3 calendar nav Semantics labels replaced with S.of(context).listCalNavPrev/Next/CurrentMonth"
  - "D-08: list/ in-scope fix complete; 9 sort_filter_bar Semantics labels deferred; JPY/font constants are non-i18n"
  - "Worktree rebase required: worktree was at ba9f6de, needed 5c1221dc to include list feature"
metrics:
  duration: "~25 minutes"
  completed: "2026-05-31"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 5
  files_created: 1
---

# Phase 30 Plan 02: ListEmptyState 3-State Enum + D-13 Semantics + D-08 Sweep Summary

3-state `ListEmptyVariant` enum replacing binary `isFilterActive:bool`, `anyOtherFilter`-priority branching in list_screen, localized calendar-nav Semantics labels, D-12 error string fix, and D-08 hardcoded-string inventory covering all findings in `lib/features/list/`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rework ListEmptyState to 3-state enum + update list_screen.dart branching + D-12 error string | 0ddc824c | list_empty_state.dart, list_screen.dart, list_empty_state_test.dart |
| 2 | Localize list_calendar_header.dart Semantics labels (D-13) + add day-only-clear unit test | 591854a8 | list_calendar_header.dart, list_filter_notifier_test.dart |
| 3 | D-08 hardcoded-string sweep — verify list/ clean + create deferred inventory | 6ad9ae03 | docs/worklog/30-d08-hardcoded-string-inventory.md |

## Changes Made

### Task 1: ListEmptyState 3-state enum + list_screen branching + D-12

**list_empty_state.dart:**
- Added `ListEmptyVariant` enum: `noData | dayEmpty | filtered`
- Changed constructor from `isFilterActive: bool` to `variant: ListEmptyVariant`
- Switch dispatch producing 4-tuple `(icon, message, actionLabel?, onAction?)`:
  - `noData` → `Icons.receipt_long_outlined` + `listEmptyMonth`, no button
  - `dayEmpty` → `Icons.event_busy_outlined` + `listEmptyDay` + `listEmptyDayClear` button calling `selectDay(null)` (D-05 CRITICAL)
  - `filtered` → `Icons.search_off_outlined` + `listEmptyFiltered` + `listEmptyFilteredClear` button calling `clearAll()`

**list_screen.dart:**
- D-12: Replaced `'[data load error]'` with `S.of(context).listLoadError`
- D-05: Replaced `anyFilterActive` bool with `anyOtherFilter`-priority variant logic:
  - `anyOtherFilter` (non-day filters) → `ListEmptyVariant.filtered`
  - `activeDayFilter != null` only → `ListEmptyVariant.dayEmpty`
  - neither → `ListEmptyVariant.noData`

**list_empty_state_test.dart:**
- Migrated from `isFilterActive: bool` API to `variant: ListEmptyVariant` API
- 3 new test cases: `noData` (no TextButton), `dayEmpty` (TextButton present), `filtered` (TextButton present)
- All 3 tests GREEN

### Task 2: Calendar nav Semantics + D-05 day-only-clear test

**list_calendar_header.dart:**
- `_MonthNavBar` `build()` has BuildContext — used direct `S.of(context)` (Option B)
- 3 hardcoded labels replaced:
  - `'Previous month'` → `S.of(context).listCalNavPrev`
  - `'Return to current month'` → `S.of(context).listCalNavCurrentMonth`
  - `'Next month'` → `S.of(context).listCalNavNext`

**list_filter_notifier_test.dart:**
- Added `selectDay(null) clears day filter but preserves all other filter fields (D-05)` test
- Sets ledgerType/categoryIds/searchQuery/memberBookId, calls `selectDay(null)`, verifies day cleared + others preserved
- Test GREEN — confirms `selectDay(null)` correctly implements day-only clear

### Task 3: D-08 inventory

- Ran grep sweeps on `lib/features/list/` — confirmed clean (all in-scope issues fixed in Tasks 1 and 2)
- Found 9 additional Semantics labels in `list_sort_filter_bar.dart` — documented as deferred (need ARB keys)
- App-wide sweep: `JPY` defaults and `fontFamily: 'Outfit'` hardcodes are non-i18n constants (not i18n candidates)
- Created `docs/worklog/30-d08-hardcoded-string-inventory.md` with full structured findings

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test test/widget/features/list/list_empty_state_test.dart` | PASS (3/3) |
| `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | PASS (21/21) |
| `grep -r 'isFilterActive' lib/` | 0 matches — PASS |
| `grep 'Previous month\|Next month\|Return to current month' list_calendar_header.dart` | 0 matches — PASS |
| `grep 'listLoadError' list_screen.dart` | 1 match — PASS |
| `flutter analyze --no-fatal-infos` | 4 pre-existing issues (build/ + category_selection_screen) — PASS |
| D-08 inventory at docs/worklog/30-d08-hardcoded-string-inventory.md | EXISTS — PASS |

**Pre-existing test failures (out of scope):**
- `test/golden/home_hero_card_golden_test.dart` — 7 golden mismatches, existed before Phase 30
- `test/widget/features/list/list_sort_filter_bar_member_test.dart` — 2 failures (FAM-04 chip), existed before Phase 30

## Deviations from Plan

### Setup Deviation: Worktree rebase required

**Found during:** Pre-execution setup
**Issue:** Worktree was at `ba9f6de` (Phase 23 era) while `main` was at `5c1221dc` (Phase 30). `lib/features/list/` did not exist in the worktree.
**Fix:** `git rebase 5c1221dc` on the worktree branch to bring it up to date with main's HEAD.
**Impact:** None — rebase succeeded cleanly, no conflicts.

### Auto-documentation: Additional Semantics labels found

**Found during:** Task 3 D-08 sweep
**Issue:** `list_sort_filter_bar.dart` contains 9 additional Semantics `label:` hardcoded strings not identified in RESEARCH.md. These follow the same D-13 pattern.
**Action:** Documented in deferred inventory rather than fixing inline (would require ARB key additions outside this plan's scope).
**Files modified:** None — documentation only.

## Known Stubs

None — this plan implements complete widget logic. All 3 variants are fully wired to ARB keys and provider callbacks. No placeholder data flows to UI.

## Threat Flags

None — widget render logic changes are UI-only. Semantics labels are accessibility strings with no security impact. Button callbacks invoke existing notifier methods (`selectDay`, `clearAll`) with no new user input surface.

## Self-Check: PASSED

- [x] `lib/features/list/presentation/widgets/list_empty_state.dart` defines `ListEmptyVariant` enum — FOUND
- [x] `lib/features/list/presentation/screens/list_screen.dart` contains `anyOtherFilter` — FOUND
- [x] `lib/features/list/presentation/widgets/list_calendar_header.dart` contains `listCalNavPrev` — FOUND
- [x] `test/widget/features/list/list_empty_state_test.dart` contains `ListEmptyVariant.dayEmpty` — FOUND
- [x] `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` contains `selectDay(null) clears day filter` — FOUND
- [x] `docs/worklog/30-d08-hardcoded-string-inventory.md` exists — FOUND
- [x] Commit 0ddc824c exists — VERIFIED
- [x] Commit 591854a8 exists — VERIFIED
- [x] Commit 6ad9ae03 exists — VERIFIED
- [x] list_empty_state_test PASSES (3/3) — VERIFIED
- [x] list_filter_notifier_test PASSES (21/21) — VERIFIED
