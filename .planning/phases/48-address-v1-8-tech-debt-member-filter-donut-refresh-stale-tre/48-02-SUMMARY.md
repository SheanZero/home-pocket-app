---
phase: 48-address-v1-8-tech-debt-member-filter-donut-refresh-stale-tre
plan: 02
subsystem: analytics
tags: [doc-hygiene, tech-debt, dartdoc, build_runner, TD-2]
status: complete
requires:
  - "Phase 46 D-E2 (GetExpenseTrendUseCase / MonthlyTrend removal) already landed"
provides:
  - "scrubbed dartdoc on getWithinMonthCumulativeUseCase (no removed-symbol names)"
  - "regenerated repository_providers.g.dart dartdoc mirrors"
  - "characterization test description naming no removed symbol"
affects:
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - lib/features/analytics/presentation/providers/repository_providers.g.dart
  - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
tech-stack:
  added: []
  patterns:
    - "Riverpod codegen mirrors source dartdoc into 3 generated copies (provider/family/element) — regenerate via build_runner, never hand-edit"
key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart
    - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
decisions:
  - "D-04: dartdoc historical note rephrased without removed identifiers ('the prior 6-month per-month-totals trend was retired in Phase 46 D-E2'); findByBookIds/NOT-analyticsRepository rationale kept verbatim"
  - "D-04: test description reworded to 'within-month cumulative trend path, D-E1' (D-E1 is the live decision; D-E2 was the removal)"
metrics:
  duration: ~6 min
  completed: 2026-06-22
  tasks: 2
  files: 3
---

# Phase 48 Plan 02: Stale TREND-01 Dartdoc Scrub Summary

Scrubbed the removed `getExpenseTrendUseCase` / `MonthlyTrend` symbol names from the `getWithinMonthCumulativeUseCase` provider dartdoc (source + 3 build_runner-regenerated `.g.dart` mirrors) and from one characterization test description; `grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` now returns 0 matches.

## What Was Built

Pure doc-hygiene cleanup of TD-2 from `.planning/v1.8-MILESTONE-AUDIT.md`. `GetExpenseTrendUseCase` + `MonthlyTrend` were removed in Phase 46 (D-E2) and replaced by `GetWithinMonthCumulativeUseCase`, but stale comments still named the deleted symbols. No code path referenced them — misleading comments only.

### Task 1 — Source dartdoc + .g.dart regeneration (commit `8bc4ce4b`)
- Reworded the `getWithinMonthCumulativeUseCase` dartdoc in `repository_providers.dart`:
  - Kept: the "OVW-02 / D-E1" tag and the accurate "Injects the transaction repository directly (NOT analyticsRepository): the within-month trend reuses `findByBookIds` over a 2-month window with a Dart-side per-day per-ledger cumulative transform" rationale.
  - Replaced: "Replaces the deleted 6-month `getExpenseTrendUseCase` (D-E2 — the 6-month MonthlyTrend/BarChart stack is removed...)" → "The prior 6-month per-month-totals trend was retired in Phase 46 (D-E2) in favour of this per-day cumulative path (round-5 B needs per-day cumulative, not per-month totals)." — no removed identifier named.
- Ran `flutter pub run build_runner build` so the three generated copies in `repository_providers.g.dart` (provider/family/element, lines ~168/180/196) regenerated automatically. The `.g.dart` diff is EXACTLY the three dartdoc mirror blocks — no structural/codegen drift. `repository_providers.g.dart` was tracked and committed normally (no `git add -f` needed).

### Task 2 — Characterization test description (commit `24a062b3`)
- Reworded the single test description string in `analytics_providers_characterization_test.dart` from `'... (replaces deleted getExpenseTrendUseCaseProvider — D-E2)'` to `'... (within-month cumulative trend path, D-E1)'`. Test body unchanged (still reads `getWithinMonthCumulativeUseCaseProvider`, expects `isA<GetWithinMonthCumulativeUseCase>()`).

## Verification

- `grep -rn "getExpenseTrend\|MonthlyTrend" lib/` → 0 matches (PASS).
- `grep -rn "getExpenseTrend\|MonthlyTrend" test/` → 0 matches (PASS).
- Combined `grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` → 0 matches (TD-2 acceptance probe, D-04 — PASS).
- `flutter analyze lib/.../repository_providers.dart` → No issues found (PASS).
- `grep -c "findByBookIds" lib/.../repository_providers.dart` → 5 (kept rationale intact — PASS).
- `flutter test .../analytics_providers_characterization_test.dart` → 3/3 passed (test body unchanged, still green — PASS).
- `.g.dart` diff inspected: only the 3 dartdoc mirror blocks changed; no unrelated codegen drift.
- Golden: comment-only + test-description-only → 0 golden re-baseline (as expected).

NOTE: The full-project `flutter analyze` (0 issues) and the FULL `flutter test` per-wave gate are run by the orchestrator after this plan; the plan's own scoped `<verify>` automated checks all pass.

## Deviations from Plan

None — plan executed exactly as written. The `.g.dart` was tracked (not gitignored-yet-tracked), so the contingency `git add -f` path was not needed.

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: `repository_providers.dart`, `repository_providers.g.dart`, `analytics_providers_characterization_test.dart` — all FOUND.
- Commits exist: `8bc4ce4b` (Task 1), `24a062b3` (Task 2) — both FOUND in `git log`.
