---
phase: 27-calendar-header-month-summary
plan: "03"
subsystem: list-feature-calendar-widget
tags: [flutter, widget, table_calendar, riverpod, tdd, animation]
dependency_graph:
  requires:
    - 27-02 (calendarDailyTotalsProvider, listFilterProvider)
    - 27-01 (listFilterProvider, state_list_filter.dart)
  provides:
    - CalendarHeaderWidget (ConsumerWidget) for ListScreen
    - list_calendar_header.dart (full C-01/C-02/C-03/C-04 implementation)
    - list_screen.dart updated (CalendarHeaderWidget mounted at top)
    - 3 passing widget tests (SC#1/SC#3/SC#4)
  affects:
    - lib/features/list/presentation/widgets/list_calendar_header.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - test/widget/features/list/presentation/widgets/list_calendar_header_test.dart
tech_stack:
  added: []
  patterns:
    - "ConsumerWidget + ref.watch(listFilterProvider) + ref.watch(calendarDailyTotalsProvider(...))"
    - "TableCalendar with headerVisible: false + custom CalendarBuilders (all 4 slots)"
    - "DateTime year-boundary rollover for month navigation: DateTime(year, month±1)"
    - "_dayKey normalization shared between provider and cell lookup"
    - "AnimatedSize(duration: 200ms) for day subline show/hide"
    - "ProviderContainer.test() + UncontrolledProviderScope for widget tests"
    - "Mocktail AnalyticsRepository stub with named-param matchers"
key_files:
  created:
    - lib/features/list/presentation/widgets/list_calendar_header.dart
  modified:
    - lib/features/list/presentation/screens/list_screen.dart
    - test/widget/features/list/presentation/widgets/list_calendar_header_test.dart
decisions:
  - "currencyCode passed as 'JPY' const in Phase 27 (Phase 29 seam comment for bookByIdProvider resolution)"
  - "dart:ui import not needed — Locale is re-exported via flutter/material.dart"
  - "_MonthNavBar and _SummaryRow extracted as private StatelessWidget classes to keep CalendarHeaderWidget.build() under 50 lines"
  - "error callback uses (e, st) param names to satisfy no_leading_underscores_for_local_identifiers lint"
metrics:
  duration_seconds: 565
  completed_date: "2026-05-30"
  tasks_total: 2
  tasks_completed: 2
  files_created: 1
  files_modified: 2
---

# Phase 27 Plan 03: CalendarHeaderWidget Implementation Summary

**One-liner:** `CalendarHeaderWidget` ConsumerWidget with TableCalendar full-month grid, custom day cells (accent/today/outside states), month nav bar (chevron + label-to-today), SummaryRow (amountSmall total + AnimatedSize day subline), mounted in ListScreen; 3 widget tests pass.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 RED | Add failing widget tests (SC#1/SC#3/SC#4) | 0228717 | Done |
| 1 GREEN | Implement CalendarHeaderWidget | 85fc53b | Done |
| 1 REFACTOR | Fix analyze issues (dart:ui import, error callback naming) | 661df78 | Done |
| 2 | Mount CalendarHeaderWidget in ListScreen | e3e5f54 | Done |

## Verification Results

- `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` → 3/3 PASS (SC#1/SC#3/SC#4)
- `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` → 5/5 PASS
- `flutter test` (full suite) → 2149 pass, 12 fail (all 12 pre-existing, unchanged)
- `flutter analyze` → 4 issues (all pre-existing: firebase_messaging build artifact, 2x deprecated onReorder)
- `grep "CalendarHeaderWidget" lib/features/list/presentation/screens/list_screen.dart` → 2 matches (class comment + instantiation)
- `grep "_dayKey" lib/features/list/presentation/widgets/list_calendar_header.dart` → 4 occurrences (definition + cell lookup + subline lookup + function ref)
- `grep "formatCompact" lib/features/list/presentation/widgets/list_calendar_header.dart` → 1 occurrence (day cell)
- `grep "formatCurrency" lib/features/list/presentation/widgets/list_calendar_header.dart` → 2 occurrences (month total + day subline)
- `grep "listFilterProvider" lib/features/list/presentation/providers/state_calendar_totals.dart` → 1 match (doc comment only, no code reference — isolation enforced)
- `grep "CalendarHeaderWidget" lib/features/list/presentation/screens/list_screen.dart` → 1 instantiation match

## TDD Gate Compliance

RED gate: 0228717 — `test(27-03): add failing widget tests...` — tests failed with compilation error (widget file missing)
GREEN gate: 85fc53b — `feat(27-03): implement CalendarHeaderWidget...` — all 3 tests pass
REFACTOR gate: 661df78 — `chore(27-03): remove unnecessary dart:ui import...` — tests still pass

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unnecessary `dart:ui` import from widget and test files**
- **Found during:** GREEN phase — `flutter analyze` reported `unnecessary_import` for `dart:ui` in both `list_calendar_header.dart` and test file
- **Issue:** `Locale` is re-exported via `package:flutter/material.dart`; explicit `dart:ui` import was redundant and flagged by analyzer
- **Fix:** Removed `import 'dart:ui'` from both files
- **Files modified:** `list_calendar_header.dart`, `list_calendar_header_test.dart`
- **Commit:** 85fc53b (widget), 661df78 (test)

**2. [Rule 1 - Bug] Fixed error callback parameter naming for lint compliance**
- **Found during:** GREEN phase — `flutter analyze` flagged `(_, __)` as `unnecessary_underscores` and then `_s` as `no_leading_underscores_for_local_identifiers`
- **Issue:** Dart linter disallows multiple underscores and leading underscores on non-private local identifiers
- **Fix:** Changed `error: (_, __) =>` to `error: (e, st) =>`
- **Files modified:** `list_calendar_header.dart`
- **Commit:** 85fc53b

**3. [Rule 2 - Missing functionality] Extracted `_MonthNavBar` and `_SummaryRow` as private StatelessWidget classes**
- **Found during:** Task 1 implementation — build() method exceeded 50-line guideline in CLAUDE.md
- **Fix:** Extracted nav bar and summary row as separate private widget classes to maintain readability and stay within the file organization guidelines
- **Files modified:** `list_calendar_header.dart`
- **Commit:** 85fc53b

## Known Stubs

- `list_screen.dart`: `const currencyCode = 'JPY'` — intentional Phase 27 placeholder. Phase 29 comment marks this for `bookByIdProvider` resolution. The stub is correctly labeled and does not prevent plan goal (CalendarHeaderWidget mounted and functional).
- `list_screen.dart`: `Expanded(child: Center(child: CircularProgressIndicator()))` — intentional Phase 28 placeholder for transaction list. Correctly labeled with `// Phase 28: replace with transaction list` comment.

## Threat Flags

None — this plan contains no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. Widget renders pre-decrypted data from calendarDailyTotalsProvider (authenticated user's own book).

## Self-Check: PASSED

- `0228717` exists: confirmed via `git log --oneline -5`
- `85fc53b` exists: confirmed via `git log --oneline -5`
- `e3e5f54` exists: confirmed via `git log --oneline -5`
- `661df78` exists: confirmed via `git log --oneline -5`
- `lib/features/list/presentation/widgets/list_calendar_header.dart` exists: verified (371 lines, created)
- `lib/features/list/presentation/screens/list_screen.dart` modified: verified (contains CalendarHeaderWidget)
- 3 widget tests pass: confirmed `flutter test ... → 3: All tests passed!`
- 5 provider tests pass: confirmed `flutter test ... → 5: All tests passed!`
- `flutter analyze` 4 pre-existing issues, 0 new: confirmed
