---
phase: 27-calendar-header-month-summary
plan: "01"
subsystem: list-feature-prerequisites
tags: [table_calendar, i18n, arb, test-stubs, initialization]
dependency_graph:
  requires: []
  provides:
    - table_calendar package available for Plans 27-02 and 27-03
    - ARB keys calMonthTotal/calDayTotal/calLoadError for all three locales
    - initializeDateFormatting in AppInitializer for ja/zh day-of-week rendering
    - lib/features/list/presentation/widgets/ directory for Plan 27-03
    - Wave 0 test stubs for Plans 27-02 and 27-03
  affects:
    - lib/core/initialization/app_initializer.dart
    - lib/l10n/app_ja.arb, app_en.arb, app_zh.arb
    - pubspec.yaml
tech_stack:
  added:
    - table_calendar: ^3.2.0
    - initl.initializeDateFormatting (already transitive via intl)
  patterns:
    - ARB parameterized key with @metadata placeholders block
    - Wave 0 test stub pattern with ignore_for_file lint suppressions
key_files:
  created:
    - lib/features/list/presentation/widgets/.gitkeep
    - test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart
    - test/widget/features/list/presentation/widgets/list_calendar_header_test.dart
  modified:
    - pubspec.yaml (table_calendar: ^3.2.0 added, intl: 0.20.2 unchanged)
    - lib/l10n/app_ja.arb (calMonthTotal, calDayTotal, calLoadError)
    - lib/l10n/app_en.arb (calMonthTotal, calDayTotal, calLoadError)
    - lib/l10n/app_zh.arb (calMonthTotal, calDayTotal, calLoadError)
    - lib/core/initialization/app_initializer.dart (initializeDateFormatting added)
decisions:
  - "initializeDateFormatting() placed at top of AppInitializer.initialize() before _containerFactory() — ensures date symbols available for all subsequent DateFormatter and table_calendar usage"
  - "calDayTotal uses String-typed {date} placeholder per ARB convention (caller pre-formats date via DateFormatter)"
  - "Wave 0 stubs use ignore_for_file: unused_import, unused_element to suppress lint warnings from stubs that reference Plan 27-02/27-03 symbols not yet in scope"
metrics:
  duration_seconds: 310
  completed_date: "2026-05-30"
  tasks_total: 2
  tasks_completed: 2
  files_created: 3
  files_modified: 6
---

# Phase 27 Plan 01: Prerequisites — table_calendar, ARB Keys, AppInitializer, Test Stubs

**One-liner:** Added table_calendar ^3.2.0, three ARB keys in all three locales (calMonthTotal/calDayTotal/calLoadError), initializeDateFormatting in AppInitializer, and Wave 0 test stubs with compiling placeholder tests.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 | Add table_calendar dep + ARB placeholder keys | af35b82 | Done |
| 2 | initializeDateFormatting + widgets/ dir + test stubs | 9fe03ad | Done |

## Verification Results

- `grep -c "table_calendar" pubspec.yaml` → 1
- `flutter pub get` → exits 0, no intl conflict; intl 0.20.2 pin unchanged
- `grep calMonthTotal lib/l10n/app_{ja,en,zh}.arb` → 1 key match per file
- `flutter gen-l10n` → exits 0, zero errors
- `flutter analyze` → 0 errors, 0 warnings (4 pre-existing info-level items unchanged)
- Both test stubs: `flutter test` → 8 tests, all pass (5 unit + 3 widget)
- `ls lib/features/list/presentation/widgets/` → directory exists (.gitkeep)

## Deviations from Plan

None — plan executed exactly as written with one minor approach note:

**[Rule 2 - Lint suppression] Added ignore_for_file directives to test stubs**
- **Found during:** Task 2 verification — `flutter analyze` reported unused_import and unused_element warnings from Wave 0 stub files
- **Fix:** Added `// ignore_for_file: unused_import, unused_element` at top of both stub files to keep analyzer at zero warnings
- **Rationale:** The imports and mock declarations are intentional placeholders — they will be wired up in Plans 27-02 and 27-03
- **Files modified:** `calendar_totals_provider_test.dart`, `list_calendar_header_test.dart`
- **Commits:** 9fe03ad

## Known Stubs

The following are intentional Wave 0 stubs (to be implemented in Plans 27-02 and 27-03):

| File | Stub | Reason |
|------|------|--------|
| `test/unit/.../calendar_totals_provider_test.dart` | 5 tests with `expect(true, isTrue)` | Provider `calendarTotalsProvider` does not exist yet — implemented in Plan 27-02 |
| `test/widget/.../list_calendar_header_test.dart` | 3 tests with `expect(true, isTrue)` | Widget `ListCalendarHeader` does not exist yet — implemented in Plan 27-03 |
| `lib/.../widgets/.gitkeep` | Empty placeholder file | Widget directory created for Plan 27-03; actual widget files added there |

These stubs do not prevent the plan's goal from being achieved (prerequisite setup complete). Plans 27-02 and 27-03 will replace stub bodies with real implementations.

## Threat Flags

None — this plan contains no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The only dependency added (table_calendar) was vetted in RESEARCH.md (6+ year history, pub.dev official package).

## Self-Check: PASSED

- af35b82 exists: confirmed via `git log --oneline -2`
- 9fe03ad exists: confirmed via `git log --oneline -1`
- `pubspec.yaml` contains `table_calendar: ^3.2.0`: verified
- `lib/l10n/app_ja.arb` contains `calMonthTotal`: verified
- `lib/core/initialization/app_initializer.dart` contains `initializeDateFormatting`: verified
- `lib/features/list/presentation/widgets/.gitkeep` exists: verified
- Both test stub files exist and compile: 8 tests pass
