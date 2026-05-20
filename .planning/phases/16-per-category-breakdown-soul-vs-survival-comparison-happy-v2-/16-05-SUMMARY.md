---
phase: 16
plan: 05
subsystem: analytics/application
tags: [happy-v2, statsui-v2, application-layer, use-cases, tdd]
requires:
  - 16-03  # domain models (PerCategorySoulBreakdown, SoulVsSurvivalSnapshot, LedgerSnapshotRow)
  - 16-04  # repository interface methods + DAO + impl wiring
provides:
  - GetPerCategorySoulBreakdownUseCase
  - GetPerCategorySoulBreakdownAcrossBooksUseCase
  - GetSoulVsSurvivalSnapshotUseCase
  - GetSoulVsSurvivalSnapshotAcrossBooksUseCase
  - aggregatePerCategoryBreakdown (shared partition/sort/Other helper)
affects:
  - lib/application/analytics/  # 4 new use case files (~390 LOC) + 4 test files (~620 LOC)
tech-stack:
  added: []  # all dependencies (mocktail, flutter_test, collection) already pinned
  patterns:
    - shared-helper-fn  # aggregatePerCategoryBreakdown reused by both per-category use cases
    - parallel-fetch    # snapshot use cases kick off ledger + soul-overview futures concurrently
    - defense-in-depth  # TimeWindowValidation guard + empty-bookIds short-circuit
key-files:
  created:
    - lib/application/analytics/get_per_category_soul_breakdown_use_case.dart
    - lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart
    - lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart
    - lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart
    - test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart
    - test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart
    - test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart
    - test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart
  modified: []
decisions:
  - "Layer-purity contract honored: 4 new use cases import ONLY from lib/features/analytics/domain/ + sibling _time_window_validation.dart; no lib/data/ imports (grep-verified)."
  - "D-04 type-system gate held: SurvivalLedgerSnapshot has no avgSatisfaction field; soul-side avg is sourced ONLY from getSoulSatisfactionOverview (soul-scoped at the DAO via _soulExpenseFilter)."
  - "Shared helper aggregatePerCategoryBreakdown extracted as top-level function in the single-book file and re-imported by the across-books file — DRY without inflating the helper into its own module (both use cases apply identical D-07/D-08/D-09 rules)."
  - "Across-books snapshot use case fans out per-book getSoulSatisfactionOverview calls and computes the family soul avg as a sample-weighted mean: Σ(perBookAvg * perBookCount) / Σ(perBookCount). This recovers the same algebra as a single AVG over the union of all soul rows."
  - "Across-books snapshot returns Soul/Survival populated with the family aggregates; familySoul/familySurvival stay null (those fields are reserved for the widget-level composition in Plan 16-06)."
metrics:
  duration: ~45 minutes
  completed: 2026-05-20
---

# Phase 16 Plan 05: Application Use Cases (Per-Category + Soul-vs-Survival) Summary

Four new application-layer use cases wrap the Plan 16-04 repository surface with TimeWindowValidation guards, Empty/Value MetricResult envelopes, the D-08 min-N=3 filter + Other rollup with D-07 tie-break sort (per-category use cases), and the D-05 either-ledger-zero gate plus D-04 soul-only satisfaction provenance (snapshot use cases). 34 mock-based unit tests cover happy paths, every Empty branch, sort tie-breaks, sample-weighted family avg algebra, and the 3 TimeWindowValidation rejection cases per use case.

## What Was Built

### Task 1 — Per-category soul breakdown use cases (commit `22165b0`)

- `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart`
  - `class GetPerCategorySoulBreakdownUseCase` with constructor `{required AnalyticsRepository analyticsRepository}` storing into `final AnalyticsRepository _repo`.
  - `static const int _minN = 3;` (the D-08 threshold).
  - `Future<MetricResult<PerCategorySoulBreakdown>> execute({bookId, startDate, endDate})` — TimeWindowValidation guard → repo fetch → `aggregatePerCategoryBreakdown(items)`.
  - Top-level `aggregatePerCategoryBreakdown(List<PerCategorySoulBreakdownItem>) → MetricResult<PerCategorySoulBreakdown>` — shared helper that:
    1. Returns `Empty()` if items is empty.
    2. Partitions on `totalCount >= _minN`.
    3. Defensively re-sorts qualifying by D-07 (`avg DESC, count DESC, categoryId ASC`).
    4. Computes `otherCount = Σ low-N counts`, `otherCategoryCount = lowN.length`, `totalCount = Σ qualifying + otherCount`.
    5. Returns `Empty()` only if BOTH qualifying is empty AND otherCount == 0; otherwise wraps in `Value(...)`.

- `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart`
  - `class GetPerCategorySoulBreakdownAcrossBooksUseCase` — TimeWindowValidation guard → `if (groupBookIds.isEmpty) return const Empty();` → repo fan-out via `getPerCategorySoulBreakdownAcrossBooks` → reuses `aggregatePerCategoryBreakdown`.

- Tests (15 cases total):
  - `get_per_category_soul_breakdown_use_case_test.dart` — 8 cases: empty repo → Empty, sub-min-N-only fold-into-Other, mixed qualifying + low-N, sort tie-break `(cat_x, 7.0, 5) / (cat_y, 7.0, 3) / (cat_z, 7.0, 5)` → `[cat_x, cat_z, cat_y]`, totalCount = Σ qualifying + otherCount, and 3 TimeWindowValidation rejections.
  - `get_per_category_soul_breakdown_across_books_use_case_test.dart` — 7 cases: empty-bookIds short-circuit with `verifyNever`, exact bookIds forwarded, partition + sort + Other across pooled rows, empty pooled → Empty, and 3 TimeWindowValidation rejections.

### Task 2 — Soul-vs-Survival engagement snapshot use cases (commit `8869f02`)

- `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart`
  - `class GetSoulVsSurvivalSnapshotUseCase` — TimeWindowValidation guard → parallel fetch via two concurrent futures (`getLedgerSnapshot` + `getSoulSatisfactionOverview`) → find soul/survival rows by `ledgerType` field using `firstWhereOrNull` from `package:collection/collection.dart` → D-05 gate: if EITHER row missing or `entryCount == 0` → `Empty()` → construct `SoulLedgerSnapshot(entryCount, totalSpend, avgSatisfaction: soulOverview.avgSatisfaction)` + `SurvivalLedgerSnapshot(entryCount, totalSpend)` → `Value(snapshot, soulRow.entryCount + survivalRow.entryCount)`.
  - **D-04 provenance contract:** the soul avg is sourced ONLY from the soul-scoped `getSoulSatisfactionOverview` (filtered at the DAO via `_soulExpenseFilter`); the survival row's amount/count never touches this value. `grep -E '(survival.*avgSat|survivalRow\.avg)' lib/application/analytics/` returns nothing.

- `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart`
  - `class GetSoulVsSurvivalSnapshotAcrossBooksUseCase` — TimeWindowValidation guard → empty-bookIds short-circuit BEFORE any repo call → parallel fetch via `getLedgerSnapshotAcrossBooks` + per-book `getSoulSatisfactionOverview` fan-out via `Future.wait` → same D-05 gate at family scope → `_weightedFamilyAvg` computes `Σ(perBookAvg * perBookCount) / Σ(perBookCount)` (returns 0 when total count is 0) → returns `SoulVsSurvivalSnapshot` with `soul`/`survival` populated as family aggregates and `familySoul`/`familySurvival` left null (reserved for widget-level composition in Plan 16-06).

- Tests (19 cases total):
  - `get_soul_vs_survival_snapshot_use_case_test.dart` — 10 cases: happy path (both ledgers populated, soul-only avg provenance asserted), 5 D-05 branches (soul=0, survival=0, soul-row absent, survival-row absent, both absent), provenance verification (`getSoulSatisfactionOverview` called with same window as `getLedgerSnapshot`), and 3 TimeWindowValidation rejections.
  - `get_soul_vs_survival_snapshot_across_books_use_case_test.dart` — 9 cases: empty-bookIds short-circuit with `verifyNever` on both across-books and overview, family happy path (weighted family avg = `(8*3 + 6*4)/(3+4) = 48/7`), family D-05 (soul=0 and survival=0), weighted avg `8*3 + 6*2 / 5 = 7.2`, zero-sample fallback to 0, and 3 TimeWindowValidation rejections.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│ Plan 16-06 (Riverpod providers) — consumes these 4 use cases         │
└────────────────────────┬────────────────────────────────────────────┘
                         │ ref.watch
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│ lib/application/analytics/                                          │
│   GetPerCategorySoulBreakdownUseCase                                │
│   GetPerCategorySoulBreakdownAcrossBooksUseCase                     │
│   GetSoulVsSurvivalSnapshotUseCase                                  │
│   GetSoulVsSurvivalSnapshotAcrossBooksUseCase                       │
│                                                                     │
│   guards:  TimeWindowValidation.assertValid (first statement)       │
│            empty-bookIds → Empty (across-books variants)            │
│                                                                     │
│   shared:  aggregatePerCategoryBreakdown (min-N=3 + Other + sort)   │
│            _weightedFamilyAvg (sample-weighted family soul avg)     │
└──────────────────────┬─────────────────────────────────────────────┘
                       │ AnalyticsRepository interface (domain only)
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│ lib/features/analytics/domain/repositories/analytics_repository.dart │
│   getPerCategorySoulBreakdown            → List<PerCategorySoulBreakdownItem> │
│   getPerCategorySoulBreakdownAcrossBooks → List<PerCategorySoulBreakdownItem> │
│   getLedgerSnapshot                       → List<LedgerSnapshotRow>          │
│   getLedgerSnapshotAcrossBooks            → List<LedgerSnapshotRow>          │
│   getSoulSatisfactionOverview             → SoulSatisfactionOverview         │
└─────────────────────────────────────────────────────────────────────┘
```

## Deviations from Plan

None — plan executed exactly as written. Two minor implementation choices documented inline:

1. **Single-book snapshot fetch pattern:** the plan suggests `Future.wait` with a heterogeneous list, but Dart's type inference would have required `as` casts. Replaced with two concurrent futures + sequential `await` — same parallelism, no casts, type-safe. Equivalent to `Future.wait` for two-element parallelism.

2. **Shared helper placement:** `aggregatePerCategoryBreakdown` is a top-level function in the single-book file (re-imported via `show aggregatePerCategoryBreakdown` from the across-books file). Plan permitted either (a) shared helper or (b) inline copy; chose (a) for DRY. The class-level `_minN` constant remains the canonical source of the min-N value — the helper references `GetPerCategorySoulBreakdownUseCase._minN`, satisfying the plan's "static const int _minN = 3" requirement.

## Verification

### Automated (run before commits)

```bash
flutter analyze lib/application/analytics/get_per_category_soul_breakdown_use_case.dart \
                lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart \
                lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart \
                lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart \
                test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart \
                test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart \
                test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart \
                test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart
# → "No issues found!" (0 warnings, 0 errors across 8 files)

flutter test test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart \
              test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart \
              test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart \
              test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart
# → "All tests passed!" — 34 tests pass:
#     - Task 1: 8 single-book + 7 across-books = 15 cases
#     - Task 2: 10 single-book + 9 across-books = 19 cases

grep -rE "data/daos/|data/repositories/" lib/application/analytics/get_per_category_soul_breakdown_use_case.dart \
                                          lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart \
                                          lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart \
                                          lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart
# → nothing (Application → Data import gate)

grep -E "PerCategorySoulRowRaw" lib/application/analytics/get_per_category_soul_breakdown_use_case.dart \
                                lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart
# → nothing (no DAO row type leaks)

grep -rE "survivalRow\.avgSat|survival.*avgSatisfaction" lib/application/analytics/
# → nothing (D-04 provenance gate)
```

### Behavioral

- **D-05 either-ledger-zero gate:** 5 single-book branches + 2 family-scope branches in tests. The snapshot card will render the global empty state rather than a half-populated comparison.
- **D-04 soul-only provenance:** asserted in the happy-path test by stubbing `getSoulSatisfactionOverview` to return `avg=7.4` and verifying `result.data.soul.avgSatisfaction == 7.4`. The type system also prevents regression — `SurvivalLedgerSnapshot` has no `avgSatisfaction` field.
- **D-07 tie-break:** asserted in the per-category single-book test with `(cat_x, 7.0, 5) / (cat_y, 7.0, 3) / (cat_z, 7.0, 5)` → `[cat_x, cat_z, cat_y]` (avg equal → count DESC; cat_x/cat_z tied → categoryId ASC).
- **Weighted family avg algebra:** asserted with `8*3 + 6*2 over 3+2 = 7.2` and a zero-sample fallback (`overview.count == 0 across books → 0`).
- **Defense-in-depth:** empty `groupBookIds` short-circuits BEFORE any repository call in both across-books use cases (`verifyNever` on every repo method).

## Commits

| Task | Hash       | Message                                                                  |
| ---- | ---------- | ------------------------------------------------------------------------ |
| 1    | `22165b0`  | feat(16-05): add per-category soul breakdown use cases                   |
| 2    | `8869f02`  | feat(16-05): add Soul-vs-Survival engagement snapshot use cases          |

## Self-Check: PASSED

- `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart` — FOUND
- `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` — FOUND
- `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart` — FOUND
- `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart` — FOUND
- `test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart` — FOUND
- `test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart` — FOUND
- `test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart` — FOUND
- `test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart` — FOUND
- Commit `22165b0` — FOUND
- Commit `8869f02` — FOUND
- `flutter analyze` on all 8 files: No issues found
- `flutter test` on all 4 test files: All 34 tests pass
- No imports of `lib/data/daos/` or `lib/data/repositories/` in the 4 source files
- No references to `PerCategorySoulRowRaw` in per-category source files
- No references to `survivalRow.avgSat` or `survival.*avgSatisfaction` in any source file
