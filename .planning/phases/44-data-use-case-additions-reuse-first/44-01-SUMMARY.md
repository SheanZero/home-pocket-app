---
phase: 44-data-use-case-additions-reuse-first
plan: 01
subsystem: analytics
tags: [dart, freezed-free, domain-pure, l1-rollup, category-aggregation, ovw-01]

# Dependency graph
requires:
  - phase: 43-html-design-gate-no-production-code
    provides: GATE-03 selected direction (trend-on-top + sorted level-1 categories practical / joy ambient); locked the OVW-01 "10 L1 categories descending" donut as a pure display transform
provides:
  - "Domain-pure shared L1-rollup helper lib/features/analytics/domain/category_l1_rollup.dart exposing a LOCKED public API: l1AncestorOf, L1CategoryRollup, rollupCategoryBreakdownsToL1 (donut path), l1RollupFromTransactions (drill path)"
  - "Single source-of-truth L1-ancestor rule consumed by BOTH the OVW-01 donut transform and the Plan 03 drill subtotal/count — no second rollup, no drift"
affects: [44-03 (drill-down use case binds to l1RollupFromTransactions), 45 (analytics shell), 46 (overview donut card consuming rollupCategoryBreakdownsToL1)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Domain-pure shared transform: plain Dart class + top-level functions, no Freezed/build_runner, no Flutter import — lives directly in feature domain/ root governed by deny-only import_guard"
    - "Single source-of-truth aggregation: two public entrypoints (breakdowns path + raw-transaction path) both route through ONE l1AncestorOf rule so donut slice == drill header by construction (D-11, kills Pitfall-3 subtotal drift)"

key-files:
  created:
    - lib/features/analytics/domain/category_l1_rollup.dart
    - test/unit/features/analytics/domain/category_l1_rollup_test.dart
  modified:
    - lib/features/analytics/domain/import_guard.yaml

key-decisions:
  - "L1CategoryRollup implemented as a plain immutable class with const ctor + value equality (operator==/hashCode/toString) rather than Freezed — keeps the helper genuinely pure with zero build_runner / .freezed.dart dependency, satisfying the domain-pure (no Flutter, no codegen) constraint"
  - "The LOCKED path lib/features/analytics/domain/category_l1_rollup.dart sits directly in the feature domain/ root, which carries a deny-only import_guard.yaml (no allow whitelist, per the Phase-3 D-01 architecture convention enforced by domain_import_rules_test.dart). Verified via dart run custom_lint that the file's domain->domain imports (models/monthly_report.dart, accounting/domain/models/category.dart + transaction.dart) match none of the deny patterns and pass cleanly — so NO allow block was added (which would have broken the architecture meta-test)"

patterns-established:
  - "Files placed directly in a feature domain/ root are governed by the deny-only feature-level import_guard.yaml; cross-feature domain->domain imports pass because they match no deny pattern — no per-file allow whitelist is needed (and must not be added, per domain_import_rules_test.dart)"

requirements-completed: [OVW-01]

# Metrics
duration: 12min
completed: 2026-06-16
---

# Phase 44 Plan 01: Shared L1-Rollup Pure Helper Summary

**Domain-pure L1-category rollup helper with a LOCKED public API (l1AncestorOf + L1CategoryRollup + two rollup entrypoints), the single source-of-truth for both the OVW-01 donut transform and the Plan 03 drill subtotal — no Freezed, no Flutter import, no DAO/migration.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-16T14:03:58Z
- **Completed:** 2026-06-16
- **Tasks:** 1 (TDD: RED → GREEN)
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments
- Authored the ONE genuinely-new pure bit of Phase 44: `lib/features/analytics/domain/category_l1_rollup.dart`, exporting the four LOCKED public symbols (`l1AncestorOf`, `L1CategoryRollup`, `rollupCategoryBreakdownsToL1`, `l1RollupFromTransactions`) so Plan 03 binds to a fixed API and cannot invent a parallel aggregation.
- Single source-of-truth guarantee: both rollup entrypoints route through the one `l1AncestorOf` rule (level==1 → id; level==2 → parentId; null/missing-safe), so the donut slice and the drill header are mathematically the same number (D-11, kills RESEARCH Pitfall 3).
- 17-case unit test green (TDD RED → GREEN), covering the ancestor rule, both rollup paths, Pitfall 2 (L1-direct + L2-child both counted), amount-desc ordering, top-N truncation, zero/empty edges, and the single-source cross-check that both entrypoints agree.
- Zero data-layer footprint: schema stays v21, no DAO/migration/provider added (D-10/D-13).

## Task Commits

Each task was committed atomically (TDD cycle):

1. **Task 1 (RED): failing test for shared L1-rollup helper** - `10d5ae39` (test)
2. **Task 1 (GREEN): implement shared L1-rollup pure helper** - `4be3ebf9` (feat)

REFACTOR: none needed — implementation was minimal and clean.

_Plan metadata commit follows this SUMMARY._

## Files Created/Modified
- `lib/features/analytics/domain/category_l1_rollup.dart` (created) - Domain-pure helper: `l1AncestorOf` ancestor rule, `L1CategoryRollup` value type, `rollupCategoryBreakdownsToL1` (donut), `l1RollupFromTransactions` (drill).
- `test/unit/features/analytics/domain/category_l1_rollup_test.dart` (created) - 17 unit cases covering every `<behavior>` clause + single-source cross-check.
- `lib/features/analytics/domain/import_guard.yaml` (modified) - Comment-only clarification that files living directly in `domain/` are governed by the deny-only config (no allow block added).

## Decisions Made
- **Plain class over Freezed for `L1CategoryRollup`:** plan allowed planner discretion; chose a plain immutable class with const ctor + value equality to avoid any `build_runner`/`.freezed.dart` dependency and keep the file genuinely pure.
- **No allow block in `domain/import_guard.yaml`:** the LOCKED path sits in the feature `domain/` root, where the architecture convention (enforced by `domain_import_rules_test.dart`) mandates a deny-only config. Adding an allow whitelist (initial attempt) broke that meta-test; verified via `dart run custom_lint` that the deny-only config already permits the file's domain→domain imports, so the allow block was removed.

## Deviations from Plan

None - plan executed exactly as written. (The brief import_guard allow-block attempt was an in-flight course correction within Task 1, not a scope deviation; final state matches the plan's domain-pure intent and the existing architecture convention.)

## Issues Encountered
- **import_guard placement:** First attempt added an `allow:` block to `lib/features/analytics/domain/import_guard.yaml` to whitelist the new file's imports. `domain_import_rules_test.dart` failed (feature-level domain yaml must carry no allow block — whitelists belong in `models/`/`repositories/` subdirs). Resolved by reverting to deny-only and confirming via `dart run custom_lint` (No issues found) that the file's cross-feature domain→domain imports match none of the deny patterns and pass without any whitelist. Both the architecture test and the target unit test are green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- LOCKED public API is committed and unit-tested — Plan 03's `GetCategoryDrillDownUseCase` can bind to `l1RollupFromTransactions(transactions, categoryMap, l1CategoryId)` for its subtotal/count, and Phase 46's overview donut card can bind to `rollupCategoryBreakdownsToL1(breakdowns, categoryMap, {topN})`.
- No blockers. Schema unchanged at v21; no DAO/migration introduced.

## Self-Check: PASSED

- FOUND: `lib/features/analytics/domain/category_l1_rollup.dart`
- FOUND: `test/unit/features/analytics/domain/category_l1_rollup_test.dart`
- FOUND commit: `10d5ae39` (test/RED)
- FOUND commit: `4be3ebf9` (feat/GREEN)

---
*Phase: 44-data-use-case-additions-reuse-first*
*Completed: 2026-06-16*
