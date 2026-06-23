---
phase: 46-cards
plan: 02
subsystem: analytics
tags: [joy, analytics, use-case, riverpod, data-path]
requires:
  - "lib/features/analytics/domain/category_l1_rollup.dart (l1AncestorOf / l1RollupFromTransactions — locked single-source L1 rollup, Phase 44 D-11)"
  - "TransactionRepository.findByBookIds (existing primitive, ledgerType param)"
  - "Phase 46-01 trend provider wiring in state_analytics.dart / repository_providers.dart (added-to, not clobbered)"
provides:
  - "GetJoyCategoryAmountsUseCase + JoyCategoryAmount (per-L1 joy AMOUNT segments — 悦己花在哪, D-C2)"
  - "GetPerDayJoyCountsUseCase + PerDayJoyCount (per-day joy COUNT — 小确幸 calendar heatmap depth, D-C1)"
  - "joyCategoryAmountsProvider + perDayJoyCountsProvider (auto-dispose families)"
  - "getJoyCategoryAmountsUseCaseProvider + getPerDayJoyCountsUseCaseProvider"
affects:
  - "Phase 46-05 (Wave-2 joy cards consume these data paths)"
tech-stack:
  added: []
  patterns:
    - "Domain-pure plain immutable value classes (const ctor + value equality, NOT Freezed) for use-case outputs — mirrors L1CategoryRollup"
    - "Reuse-first: single findByBookIds(ledgerType: joy) fetch + Dart transform; zero DAO/migration"
    - "Single-source L1 rollup via l1RollupFromTransactions (no second rollup loop — D-11)"
key-files:
  created:
    - lib/features/analytics/domain/models/joy_category_amount.dart
    - lib/application/analytics/get_joy_category_amounts_use_case.dart
    - lib/features/analytics/domain/models/per_day_joy_count.dart
    - lib/application/analytics/get_per_day_joy_counts_use_case.dart
    - test/unit/application/analytics/get_joy_category_amounts_use_case_test.dart
    - test/unit/application/analytics/get_per_day_joy_counts_use_case_test.dart
  modified:
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
decisions:
  - "JoyCategoryAmount is a dedicated semantic type (categoryId, amount) rather than reusing L1CategoryRollup — it carries no transactionCount, so the leaner field set communicates the 悦己花在哪 segment intent without dragging an unused count."
  - "Per-day joy COUNT uses a Dart group-over findByBookIds(joy), NOT a new daily-totals SQL ledger+COUNT DAO variant — zero DAO surface / zero migration, the 笔数 grain is naturally available from the row list, and it does not cross the DRILL-01 scope lock (per-day-joy is ambient calendar texture, RESEARCH Flag 2 verdict)."
  - "Both providers re-normalize their family keys defensively (joyCategoryAmounts → DateBoundaries day-range; perDayJoyCounts → month anchor) to prevent microsecond rebuild storms (D-12)."
metrics:
  duration: ~5min
  completed: 2026-06-17
---

# Phase 46 Plan 02: JOY-side Data Paths (per-L1 amount + per-day count) Summary

Built the two JOY-side data paths round-5 B needs — per-L1 joy AMOUNT (悦己花在哪 stacked-bar segment weights, D-C2) via `GetJoyCategoryAmountsUseCase`, and per-day joy COUNT (小确幸 calendar heatmap depth, D-C1) via `GetPerDayJoyCountsUseCase` — as pure Dart transforms over the existing `findByBookIds(ledgerType: joy)` primitive + the locked L1 rollup helper, with ZERO new DAO and ZERO migration (schema stays v21).

## What Was Built

### Task 1 — GetJoyCategoryAmountsUseCase + JoyCategoryAmount (commit `1dfdbc31`)
- `JoyCategoryAmount`: domain-pure plain immutable value class `(categoryId, amount)`, no Flutter import / no build_runner.
- `GetJoyCategoryAmountsUseCase`: ONE `findByBookIds(ledgerType: LedgerType.joy)` fetch → expense-only + optional `manualOnly` entry-source filter → per-L1 rollup through the SAME `l1AncestorOf` / `l1RollupFromTransactions` rule the donut uses (D-11, no second rollup) → sorted amount-descending (D-C2 segment order).
- 6 unit tests GREEN: per-L1 rollup (L2 children roll into L1), joy-ledger-only, expense-only (CR-01), subset-of-L1-total invariant, empty window, book-set-faithful (T-46-02-01).

### Task 2 — GetPerDayJoyCountsUseCase + PerDayJoyCount; wire both providers (commit `c8ef3cd3`)
- `PerDayJoyCount`: domain-pure value class `(date day-anchored, count)`.
- `GetPerDayJoyCountsUseCase`: ONE `findByBookIds(ledgerType: LedgerType.joy)` fetch → expense-only + `manualOnly` filter → Dart group-by-local-calendar-day COUNT (笔数, NOT sum — Pitfall 3). Deliberately NOT the unfiltered daily-totals SQL aggregate.
- Wired `joyCategoryAmounts` (window-normalized key) + `perDayJoyCounts` (month-anchored key) as `@riverpod` auto-dispose families in `state_analytics.dart`; added both use-case providers to `repository_providers.dart`. Both added alongside 46-01's trend wiring (not clobbered). Zero `home/*` reads (GUARD-01).
- 5 unit tests GREEN: count-not-sum, joy+expense-only, local-day-correct, empty, book-set-faithful.

## Rationale (per plan must_have)
Per-day joy COUNT uses a Dart group-over `findByBookIds(joy)` rather than a SQL ledger+COUNT DAO variant because: (1) zero DAO surface change / zero migration (schema stays v21); (2) the 笔数 grain is naturally available from the returned row list; (3) it does NOT cross the DRILL-01 scope lock — per-day-joy is ambient calendar texture, a different concern from the single allowed category drill path (RESEARCH Flag 2 verdict).

## Verification
- `flutter test` for both new test files: 11/11 GREEN.
- `flutter analyze` on `lib/application/analytics/`, `lib/features/analytics/presentation/providers/`, both models, both test files: 0 issues.
- `grep getDailyTotals lib/application/analytics/get_per_day_joy_counts_use_case.dart` → no matches (Pitfall 3 guard passes; comments reworded to avoid the bare token while preserving the rationale).
- Structural locks stay green: `analytics_card_registry_test.dart` (zero home/*, auto-dispose union) + `home_screen_isolation_test.dart` (GUARD-01/02).
- `build_runner` clean (152 outputs); new `.g.dart` for both providers committed.
- Schema unchanged at v21; no new DAO.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded `getDailyTotals` comment references to satisfy the literal Pitfall-3 grep guard**
- **Found during:** Task 2 verification (`grep getDailyTotals ... returns nothing`).
- **Issue:** The use case correctly does NOT call `getDailyTotals`, but the doc comments mentioned the bare token `getDailyTotals` 5× to document *why it is not used*. The plan's verification guard greps for the literal token and expects zero hits.
- **Fix:** Reworded all comment references to "the unfiltered daily-totals SQL aggregate" / "the DAO's DATE(...localtime) day grain" — preserving the rationale while removing the bare token. Same in `repository_providers.dart`.
- **Files modified:** `lib/application/analytics/get_per_day_joy_counts_use_case.dart`, `lib/features/analytics/presentation/providers/repository_providers.dart`.
- **Commit:** `c8ef3cd3` (folded into Task 2).

## Known Stubs
None — both data paths are fully wired over the live `findByBookIds` primitive + locked rollup helper; no placeholder/mock data sources.

## TDD Gate Compliance
Each task wrote its unit tests against not-yet-existing symbols (RED by construction — the use case/model files did not exist), then implemented to GREEN, verified before commit. Tasks committed as single `feat(...)` commits (test + implementation together) rather than separate RED/GREEN commits, since the test could not compile or run until the symbols existed.

## Requirements (JOY-01 / JOY-02)
This plan delivers the **data layer** JOY-01 (已花悦己 / 小确幸 texture) and JOY-02 (分类悦己) ultimately render. The requirement checkboxes in `REQUIREMENTS.md` are intentionally left open here — the user-facing surfaces that satisfy these IDs end-to-end land in the Wave-2/3 card plans (46-04 / 46-05) that consume `joyCategoryAmountsProvider` + `perDayJoyCountsProvider`. Marking them complete on a still-headless data path would be a false "done" signal. The traceability table maps both to "Phase 46" (not a specific plan), so no premature checkbox flip is needed.

## Self-Check: PASSED
All 6 source/test files and the SUMMARY exist on disk; both task commits (`1dfdbc31`, `c8ef3cd3`) are present in git history.
