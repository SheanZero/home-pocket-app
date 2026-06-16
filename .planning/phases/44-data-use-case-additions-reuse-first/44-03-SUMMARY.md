---
phase: 44-data-use-case-additions-reuse-first
plan: 03
subsystem: analytics
tags: [dart, freezed, riverpod, drill-down, l1-rollup-reuse, drill-01, tdd]

# Dependency graph
requires:
  - phase: 44-01
    provides: "Locked domain-pure L1-rollup API (l1AncestorOf + l1RollupFromTransactions) — the single source-of-truth this drill path binds to for filter + subtotal/count"
provides:
  - "Single new read-only drill path: GetCategoryDrillDownUseCase flat-lists a tapped L1 category's window transactions (L1-direct + all L2 children) via existing findByBookIds + Dart-side l1AncestorOf filter, with subtotal/count from Plan 01's l1RollupFromTransactions (no second rollup, no drift)"
  - "CategoryDrillDown transient Freezed carrier (transactions/subtotal/count/avgPerDay)"
  - "Auto-dispose, DateBoundaries-normalized, Home-isolated categoryDrillDown provider family + getCategoryDrillDownUseCase provider"
affects: [45 (analytics shell wiring the drill family), 46 (drill-down UI consuming categoryDrillDownProvider)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Reuse-first read path: window fetch through existing TransactionRepository.findByBookIds (categoryId: null) + Dart-side L1 filter — zero new DAO/SQL/index/migration (D-04/D-05/D-06/D-13)"
    - "Single source-of-truth subtotal: drill summary subtotal/count come from Plan 01's l1RollupFromTransactions (same l1AncestorOf rule the OVW-01 donut uses) so the header == the slice by construction (D-11, kills Pitfall 3)"
    - "Defensive family-key normalization: provider collapses window bounds via DateBoundaries.dayRange before they enter the auto-dispose family key (D-12, no rebuild storm)"

key-files:
  created:
    - test/unit/application/analytics/get_category_drill_down_use_case_test.dart
    - lib/features/analytics/domain/models/category_drill_down.dart
    - lib/features/analytics/domain/models/category_drill_down.freezed.dart
    - lib/application/analytics/get_category_drill_down_use_case.dart
  modified:
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_analytics.g.dart

key-decisions:
  - "avgPerDay = subtotal ~/ inclusive-window-day-count — a plain descriptive integer average (never a target/goal), ADR-012-safe (D-03)"
  - "Drill family defensively re-normalizes startDate/endDate via DateBoundaries.dayRange inside the provider (belt-and-suspenders on top of the caller's normalized TimeWindow) so sub-day precision can never fragment the cache key (D-12)"
  - "Transactions returned time-descending (findByBookIds sortField: timestamp, desc) to match the ListTransactionTile mental model; subtotal/count still come from the rollup, not the sorted list"

patterns-established:
  - "A new analytics read path reuses findByBookIds + a domain-pure rollup helper instead of adding a DAO method or index — the structural reuse-first contract for Phase 44 drill paths"

requirements-completed: [DRILL-01]

# Metrics
duration: ~9min
completed: 2026-06-16
---

# Phase 44 Plan 03: Category Drill-Down Read Path Summary

**One new read-only drill path (DRILL-01): tapping an L1 category flat-lists its window transactions — L1-direct AND all L2 children (Pitfall 2) — via the existing `findByBookIds` primitive with a Dart-side `l1AncestorOf` filter, with a neutral subtotal/count summary sourced from Plan 01's locked `l1RollupFromTransactions` so the drill header can never drift from the donut slice (D-11). TDD-first: RED → GREEN → wire. Zero new DAO/index/migration; schema stays v21.**

## Performance

- **Duration:** ~9 min
- **Completed:** 2026-06-16
- **Tasks:** 3 (TDD: RED → GREEN → WIRE)
- **Files modified:** 8 (4 created incl. 1 generated, 4 modified incl. 2 generated)

## Accomplishments
- **RED first (D-04):** wrote `get_category_drill_down_use_case_test.dart` referencing `GetCategoryDrillDownUseCase`/`CategoryDrillDown` before either existed — confirmed failing to compile (RED). Five cases: Pitfall 2 (L1-direct + L2-child both included), sibling-L1 + out-of-window exclusion, subtotal/count cross-checked against `l1RollupFromTransactions` (D-11 single source), empty-window → empty, descriptive `avgPerDay`, and daily+joy ledger both included.
- **GREEN:** `CategoryDrillDown` Freezed carrier + `GetCategoryDrillDownUseCase` — window fetch via `findByBookIds(categoryId: null)`, Dart-side filter via Plan 01's `l1AncestorOf`, subtotal/count from Plan 01's `l1RollupFromTransactions` (no re-sum invented). All 5 RED cases turned GREEN.
- **WIRE:** `getCategoryDrillDownUseCaseProvider` (injects transaction + category repos) + auto-dispose `categoryDrillDownProvider` family with a `DateBoundaries`-normalized key (D-12), reading/invalidating zero `home/*` providers (D-14/GUARD-01).
- **Zero data-layer footprint:** schema stays v21, no DAO/index/migration, no `getCategoryTransactions` (D-06/D-13). Full `flutter analyze` clean (0 issues) across the whole project.

## Task Commits

Each task committed atomically (TDD cycle):

1. **Task 1 (RED): failing GetCategoryDrillDownUseCase test** — `d1072c3d` (test)
2. **Task 2 (GREEN): CategoryDrillDown model + GetCategoryDrillDownUseCase** — `9edac4bc` (feat)
3. **Task 3 (WIRE): drill use-case provider + auto-dispose drill family** — `1b44746a` (feat)

REFACTOR: none needed — implementation was minimal and clean.

_Plan metadata commit follows this SUMMARY._

## Files Created/Modified
- `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` (created) — TDD-first unit test, 5 cases incl. the D-11 single-source cross-check against `l1RollupFromTransactions`.
- `lib/features/analytics/domain/models/category_drill_down.dart` (created) — `CategoryDrillDown` Freezed carrier (`transactions`/`subtotal`/`count`/`avgPerDay`); no JSON (transient).
- `lib/features/analytics/domain/models/category_drill_down.freezed.dart` (generated).
- `lib/application/analytics/get_category_drill_down_use_case.dart` (created) — `GetCategoryDrillDownUseCase`; `findByBookIds` window fetch + Dart-side `l1AncestorOf` filter + `l1RollupFromTransactions` subtotal/count.
- `lib/features/analytics/presentation/providers/repository_providers.dart` (modified) — added `getCategoryDrillDownUseCase` provider (transaction + category repo injection).
- `lib/features/analytics/presentation/providers/state_analytics.dart` (modified) — added auto-dispose `categoryDrillDown` family, `DateBoundaries`-normalized key, Home-isolated.
- `*.g.dart` (regenerated) for both provider files.

## Decisions Made
- **avgPerDay is purely descriptive:** `subtotal ~/ inclusive-day-count`, integer, never a target — keeps the drill summary ADR-012/D-03 safe at the data layer.
- **Defensive in-provider window normalization (D-12):** even though the analytics shell passes a normalized `TimeWindow`, the family re-collapses bounds via `DateBoundaries.dayRange` before keying, so no caller can fragment the cache with sub-day precision.
- **Single-source subtotal enforced structurally (D-11):** the use case passes the unfiltered fetched txns to `l1RollupFromTransactions` (which applies the same `l1AncestorOf` internally), guaranteeing the header equals the donut slice — verified in-test by asserting `result.subtotal == rollup.amount` over identical fixtures.

## Deviations from Plan

None — plan executed exactly as written.

(In-flight tidies within tasks, not scope deviations: (a) reworded two doc-comment negations — "no `getCategoryTransactions`" → "no per-category DAO read method", and "NOT keepAlive" → "never kept alive" — so the plan's literal acceptance greps (`grep -rc getCategoryTransactions lib/` == 0, `grep -c keepAlive ... ` == 0) hold against comment text, not just real symbols. (b) The Task-1 test gained an explicit `CategoryDrillDown result` type annotation to keep the import used and satisfy the "test references `CategoryDrillDown`" acceptance criterion, resolving an `unused_import` analyzer warning; committed with Task 3.))

## Issues Encountered
- **unused_import warning on the test:** the test only used `CategoryDrillDown` transitively via `useCase.execute`'s return, so the analyzer flagged its import. Resolved by adding an explicit `final CategoryDrillDown result = ...` annotation (keeps the import used AND strengthens the acceptance-criterion traceability) rather than dropping the import.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- `categoryDrillDownProvider` is committed, codegen-regenerated, and unit-tested — Phase 45/46 can wire the drill-down UI to it directly (pass a normalized window + tapped `l1CategoryId`).
- No blockers. Schema unchanged at v21; no DAO/migration/index introduced.
- DEFERRED (recorded so it is not silently dropped): the 小确幸 per-day joy heatmap fetch is net-new (no `ledger_type` filter on `getDailyTotals`) and belongs to Phase 46 (RESEARCH Flag A) — out of scope for DRILL-01.

## Self-Check: PASSED

- FOUND: `test/unit/application/analytics/get_category_drill_down_use_case_test.dart`
- FOUND: `lib/features/analytics/domain/models/category_drill_down.dart`
- FOUND: `lib/application/analytics/get_category_drill_down_use_case.dart`
- FOUND commit: `d1072c3d` (test/RED)
- FOUND commit: `9edac4bc` (feat/GREEN)
- FOUND commit: `1b44746a` (feat/WIRE)

---
*Phase: 44-data-use-case-additions-reuse-first*
*Completed: 2026-06-16*
