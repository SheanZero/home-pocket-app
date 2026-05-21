---
phase: 17-manual-only-joy-sub-metric-happy-v2-03
plan: 06
subsystem: analytics-application
tags: [analytics, use-cases, entry-source, tests, happy-v2-03]

requires:
  - phase: 17-05
    provides: AnalyticsRepository EntrySource? entrySourceFilter surface
provides:
  - EntrySource? entrySourceFilter threading through 11 AnalyticsScreen-feeding use cases
  - Recommendation use case left byte-identical per D-15
  - Representative use-case tests for null/manual filter forwarding
affects: [analytics-use-cases, manual-only-filter, happy-v2-03]

tech-stack:
  added: []
  patterns:
    - Nullable filter parameters stay application-layer pass-throughs
    - Recommendation use case remains universal by omission

key-files:
  created:
    - .planning/phases/17-manual-only-joy-sub-metric-happy-v2-03/17-06-SUMMARY.md
  modified:
    - lib/application/analytics/get_happiness_report_use_case.dart
    - lib/application/analytics/get_monthly_report_use_case.dart
    - lib/application/analytics/get_per_category_soul_breakdown_use_case.dart
    - lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart
    - lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart
    - lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart
    - lib/application/analytics/get_best_joy_moment_use_case.dart
    - lib/application/analytics/get_satisfaction_distribution_use_case.dart
    - lib/application/analytics/get_largest_monthly_expense_use_case.dart
    - lib/application/analytics/get_expense_trend_use_case.dart
    - lib/application/analytics/get_family_happiness_use_case.dart
    - test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart
    - test/unit/application/analytics/get_best_joy_moment_use_case_test.dart
    - test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart

key-decisions:
  - "Did not modify `get_monthly_joy_target_recommendation_use_case.dart`; D-15 remains enforced by absence of an entrySourceFilter parameter."
  - "Threaded the filter through `GetMonthlyReportUseCase._getPreviousMonthComparison` so the report object stays internally consistent if consumers read that field."
  - "Soul-vs-Survival forwards the same filter to both ledger snapshot and soul overview repo calls."

patterns-established:
  - "Use cases do not interpret metric variants; they accept an optional EntrySource and pass it unchanged to repositories."

requirements-completed: [HAPPY-V2-03]

duration: 6 min
completed: 2026-05-21
---

# Phase 17 Plan 06: Analytics Use Case Filter Threading Summary

**AnalyticsScreen-feeding use cases now accept and forward `EntrySource? entrySourceFilter`; the monthly Joy target recommendation use case remains universal.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-21T01:18:24Z
- **Completed:** 2026-05-21T01:24:16Z
- **Tasks:** 2
- **Files modified:** 14

## Use Case Coverage

| Use case file | execute() param added? | Repo passthrough threaded? |
|---|---:|---:|
| `get_happiness_report_use_case.dart` | Yes | Yes |
| `get_monthly_report_use_case.dart` | Yes | Yes |
| `get_per_category_soul_breakdown_use_case.dart` | Yes | Yes |
| `get_per_category_soul_breakdown_across_books_use_case.dart` | Yes | Yes |
| `get_soul_vs_survival_snapshot_use_case.dart` | Yes | Yes |
| `get_soul_vs_survival_snapshot_across_books_use_case.dart` | Yes | Yes |
| `get_best_joy_moment_use_case.dart` | Yes | Yes |
| `get_satisfaction_distribution_use_case.dart` | Yes | Yes |
| `get_largest_monthly_expense_use_case.dart` | Yes | Yes |
| `get_expense_trend_use_case.dart` | Yes | Yes |
| `get_family_happiness_use_case.dart` | Yes | Yes |
| `get_monthly_joy_target_recommendation_use_case.dart` | BYTE-IDENTICAL (D-15) | BYTE-IDENTICAL (D-15) |

## Task Commits

Each task was committed atomically:

1. **Task 1: Thread entrySourceFilter through analytics use cases** - `91ef56b` (feat)
2. **Task 2: Cover use-case filter forwarding** - `8cc3f6f` (test)

**Plan metadata:** pending current commit

## Test Names

Representative new tests:

- `entrySourceFilter forwarding execute with entrySourceFilter = null preserves default behavior` - PASS
- `entrySourceFilter forwarding execute with entrySourceFilter = EntrySource.manual forwards filter` - PASS
- `GetBestJoyMomentUseCase execute with entrySourceFilter = null forwards null to repo` - PASS
- `GetBestJoyMomentUseCase execute with entrySourceFilter = EntrySource.manual forwards filter` - PASS
- `entrySourceFilter forwarding execute with entrySourceFilter = null forwards null to both repo calls` - PASS
- `entrySourceFilter forwarding execute with entrySourceFilter = EntrySource.manual forwards filter to both columns` - PASS

## Verification

- `flutter analyze lib/application/analytics` returned `No issues found`.
- `git diff lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` returned empty output.
- `grep -F "EntrySource? entrySourceFilter" lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` returned no matches.
- Representative test command passed 31 tests:
  - `test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart`
  - `test/unit/application/analytics/get_best_joy_moment_use_case_test.dart`
  - `test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart`
- Combined regression command passed 153 tests:
  - `test/unit/application/analytics`
  - `test/unit/data/daos/analytics_dao_test.dart`
  - `test/unit/data/migrations/migration_v16_to_v17_test.dart`
  - `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`

## Deviations from Plan

- Added `entrySourceFilter` through the private previous-month comparison helper inside `GetMonthlyReportUseCase`; this keeps the report object internally consistent if a caller reads previous-month fields under the audit lens.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

Plan 17-07 can now add the provider state and chip UI that selects between all entries and manual-only filtering, then pass the selected filter to these use cases.

---
*Phase: 17-manual-only-joy-sub-metric-happy-v2-03*
*Completed: 2026-05-21*
