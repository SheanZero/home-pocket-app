---
phase: 16
plan: 06
subsystem: analytics/presentation
tags: [happy-v2, statsui-v2, presentation-layer, riverpod, providers]
requires:
  - 16-03  # domain models (PerCategorySoulBreakdown, SoulVsSurvivalSnapshot, LedgerSnapshotRow)
  - 16-05  # 4 application use cases for per-category + soul-vs-survival
provides:
  - perCategorySoulBreakdownProvider
  - perCategorySoulBreakdownFamilyProvider
  - soulVsSurvivalSnapshotProvider
  - soulVsSurvivalSnapshotFamilyProvider
  - getPerCategorySoulBreakdownUseCaseProvider
  - getPerCategorySoulBreakdownAcrossBooksUseCaseProvider
  - getSoulVsSurvivalSnapshotUseCaseProvider
  - getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider
affects:
  - lib/features/analytics/presentation/providers/  # +1 new file (state_ledger_snapshot.dart) + extend repository_providers.dart
tech-stack:
  added: []  # uses already-pinned riverpod_annotation
  patterns:
    - window-keyed-future-provider  # mirrors happinessReportProvider pattern at state_happiness.dart:14-30
    - family-mode-gate              # activeGroup + shadowBooks resolution + D-20 length<2 gate
    - defense-in-depth              # D-20 gate at provider + use case layers
    - single-source-of-truth-di     # all 4 new use case providers live in repository_providers.dart (CLAUDE.md Pitfall 10)
key-files:
  created:
    - lib/features/analytics/presentation/providers/state_ledger_snapshot.dart
    - lib/features/analytics/presentation/providers/state_ledger_snapshot.g.dart
  modified:
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart
decisions:
  - "state_ledger_snapshot.dart is a NEW file (per R2): keeps state_happiness.dart Joy-focused; ledger-engagement and per-category surfaces live in their own state file."
  - "Family providers enforce D-20 gate at the provider layer (groupBookIds.length < 2 → Empty()) — defense in depth alongside the use-case-layer guard. Mirrors familyHappiness pattern from state_happiness.dart:86-109."
  - "All 4 use case providers added to the SHARED repository_providers.dart (single source of truth per CLAUDE.md Pitfall 10 + HIGH-04 provider graph hygiene test). No duplicate analyticsRepositoryProvider; all 4 watch the existing one."
  - "Family providers use the IDENTICAL shadow-book accessor as state_happiness.dart:97-98 — `shadowBooks.map((shadow) => shadow.book.id).toList()`. Picking the same accessor keeps the family-mode binding consistent across analytics state providers and avoids drift when the shadow-book model evolves."
  - "Window-keyed Future signature {bookId?, startDate, endDate} matches HappinessReport / BestJoyMoment so Plan 16-10's AnalyticsScreen._refresh() can invalidate all 4 providers without touching the D-12 HomeHero isolation binding."
metrics:
  duration: ~15 minutes
  completed: 2026-05-20
---

# Phase 16 Plan 06: State Providers (state_ledger_snapshot + repository_providers) Summary

Wired the Plan 16-05 application use cases into the presentation layer with 4 new `@riverpod` Future providers in a NEW `state_ledger_snapshot.dart` (keeps `state_happiness.dart` Joy-focused per R2). Extended `repository_providers.dart` with the 4 corresponding singleton use case providers — all sharing the existing `analyticsRepositoryProvider` (no duplicates per CLAUDE.md Pitfall 10). Family providers enforce the D-20 `shadowBooks.length < 2 → Empty()` gate at the provider layer for defense in depth.

## What Was Built

### Task 1 — Extend repository_providers.dart with 4 use-case providers (commit `d3bd749`)

- Imports added at top of file (alphabetized):
  - `'../../../../application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart'`
  - `'../../../../application/analytics/get_per_category_soul_breakdown_use_case.dart'`
  - `'../../../../application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart'`
  - `'../../../../application/analytics/get_soul_vs_survival_snapshot_use_case.dart'`

- 4 new `@riverpod` use case providers appended after `getFamilyHappinessUseCase`, each delegating to the same `ref.watch(analyticsRepositoryProvider)` (single source of truth):
  - `getPerCategorySoulBreakdownUseCase(Ref ref)` → `GetPerCategorySoulBreakdownUseCase(analyticsRepository: ...)` — doc `/// HAPPY-V2-01 / D-07: ...`.
  - `getPerCategorySoulBreakdownAcrossBooksUseCase(Ref ref)` → across-books variant — doc `/// HAPPY-V2-01 / D-16, D-17: ...`.
  - `getSoulVsSurvivalSnapshotUseCase(Ref ref)` → `GetSoulVsSurvivalSnapshotUseCase(...)` — doc `/// STATSUI-V2-01 / D-01..D-05: ...`.
  - `getSoulVsSurvivalSnapshotAcrossBooksUseCase(Ref ref)` → across-books variant — doc `/// STATSUI-V2-01 / D-18, D-20: ...`.

- `flutter pub run build_runner build --delete-conflicting-outputs` regenerated `repository_providers.g.dart` with the 4 new `*Provider` symbols (verified by grep).

### Task 2 — Create state_ledger_snapshot.dart with 4 Future providers (commit `8497ed0`)

- Single new file `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` with the standard `part 'state_ledger_snapshot.g.dart';` directive. Imports mirror `state_happiness.dart` exactly for `activeGroupProvider` (`../../../family_sync/presentation/providers/state_active_group.dart`) and `shadowBooksProvider` (`../../../home/presentation/providers/state_shadow_books.dart`).

- 4 top-level `@riverpod` Future-returning functions:

  1. **`perCategorySoulBreakdown`** — single-book per-category, signature `{required String bookId, required DateTime startDate, required DateTime endDate}`. Delegates to `getPerCategorySoulBreakdownUseCaseProvider.execute(...)`.

  2. **`perCategorySoulBreakdownFamily`** — family-aggregate variant, signature `{required DateTime startDate, required DateTime endDate}` (no bookId). Resolves `activeGroupProvider.future` (Empty if null) → `shadowBooksProvider.future` → collects `groupBookIds = shadowBooks.map((s) => s.book.id).toList()` → **D-20 gate**: `if (groupBookIds.length < 2) return const Empty();` → delegates to `getPerCategorySoulBreakdownAcrossBooksUseCaseProvider.execute(...)`.

  3. **`soulVsSurvivalSnapshot`** — single-book snapshot, signature `{required String bookId, required DateTime startDate, required DateTime endDate}`. Delegates to `getSoulVsSurvivalSnapshotUseCaseProvider.execute(...)`.

  4. **`soulVsSurvivalSnapshotFamily`** — family snapshot variant, signature `{required DateTime startDate, required DateTime endDate}`. Same D-20 gate structure as Provider 2; delegates to `getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider.execute(...)`.

- Generator output `state_ledger_snapshot.g.dart` contains all 4 expected symbols (`grep` verified):
  - `perCategorySoulBreakdownProvider`
  - `perCategorySoulBreakdownFamilyProvider`
  - `soulVsSurvivalSnapshotProvider`
  - `soulVsSurvivalSnapshotFamilyProvider`

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│ Plan 16-07..16-10 widgets — consume these state providers           │
│   ref.watch(perCategorySoulBreakdownProvider(bookId:..., ...))      │
│   ref.watch(soulVsSurvivalSnapshotFamilyProvider(startDate:..., ...))│
└────────────────────────┬────────────────────────────────────────────┘
                         │ ref.watch
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│ lib/features/analytics/presentation/providers/                      │
│   state_ledger_snapshot.dart                                        │
│     perCategorySoulBreakdown          (window-keyed, single-book)   │
│     perCategorySoulBreakdownFamily    (D-20 gate; family aggregate) │
│     soulVsSurvivalSnapshot            (window-keyed, single-book)   │
│     soulVsSurvivalSnapshotFamily      (D-20 gate; family aggregate) │
│                                                                     │
│   family-mode gate:                                                 │
│     activeGroupProvider.future == null  → Empty()                   │
│     shadowBooks.length < 2              → Empty()  (D-20)           │
└────────────────────────┬────────────────────────────────────────────┘
                         │ ref.watch(getXUseCaseProvider)
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│ lib/features/analytics/presentation/providers/                      │
│   repository_providers.dart                                         │
│     getPerCategorySoulBreakdownUseCaseProvider                      │
│     getPerCategorySoulBreakdownAcrossBooksUseCaseProvider           │
│     getSoulVsSurvivalSnapshotUseCaseProvider                        │
│     getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider             │
│                                                                     │
│     all 4 reuse the existing analyticsRepositoryProvider            │
└────────────────────────┬────────────────────────────────────────────┘
                         │ ref.watch
                         ▼
                  GetX*UseCase classes (Plan 16-05)
```

## Verification

- `flutter pub run build_runner build` — 0 errors, 1211 outputs initially (Task 1) and 4 outputs after Task 2; codegen clean.
- `flutter analyze lib/features/analytics/presentation/providers/repository_providers.dart lib/features/analytics/presentation/providers/repository_providers.g.dart` — **No issues found** (0 issues).
- `flutter analyze lib/features/analytics/presentation/providers/state_ledger_snapshot.dart lib/features/analytics/presentation/providers/state_ledger_snapshot.g.dart` — **No issues found** (0 issues).
- `flutter analyze` (full project) — **No issues found** (0 issues across the whole worktree).
- `flutter test test/architecture/provider_graph_hygiene_test.dart test/architecture/domain_import_rules_test.dart` — all 23 tests pass. This covers:
  - HIGH-04 structure: each feature has exactly one `repository_providers.dart`.
  - HIGH-04 DI consolidation: every UseCase-suffix provider lives only in `repository_providers.dart` (the 4 new providers were placed correctly).
  - HIGH-04 global uniqueness: no duplicate `@riverpod` function names within `lib/features/`.
  - HIGH-06 no UnimplementedError in production providers — the 4 new providers all have real return paths (Empty() short-circuit or use case delegate).
- `flutter test test/unit/features/analytics/presentation/providers/` — 15 tests pass; no regressions in characterization tests.
- Generated symbols verified by grep on `repository_providers.g.dart` and `state_ledger_snapshot.g.dart` — all 8 `*Provider` symbols present.
- Acceptance criteria assertions:
  - `grep -E 'Future<MetricResult<' state_ledger_snapshot.dart | wc -l` → 4 (matches "4 Future providers" expectation).
  - `grep -c 'groupBookIds.length < 2' state_ledger_snapshot.dart` → 2 (one D-20 gate per family provider).

## Layer-Purity Check

- `state_ledger_snapshot.dart` imports:
  - `riverpod_annotation` (allowed).
  - Domain models (`ledger_snapshot.dart`, `metric_result.dart`, `per_category_soul_breakdown.dart`) — allowed per "Domain is independent; Presentation may consume Domain".
  - Sibling feature providers (`state_active_group.dart`, `state_shadow_books.dart`) — presentation-to-presentation cross-feature, allowed.
  - `repository_providers.dart` — same feature, same layer.
  - **No imports from `lib/data/`** (CLAUDE.md Pitfall 2 — Domain-to-Data forbidden also extends to Presentation reaching past Application).

- `repository_providers.dart` (modified): existing imports from `lib/data/` (already there for `analyticsDao`, `AnalyticsRepositoryImpl`) are unchanged. The 4 new use-case provider imports point to `lib/application/analytics/` only.

## D-20 Gate Contract

The provider-layer D-20 gate is intentionally redundant with the use-case-layer gate at `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart:33-35` and `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart:49-51` (both short-circuit `if (groupBookIds.isEmpty) return const Empty();`). The provider gate is a tighter rule (`length < 2`, not just empty) that encodes a **presentation contract**: the Family compare card requires at least 2 books to render a meaningful family aggregate. Plan 16-10 will surface this as the "Family data not available" empty state in the widget tree.

Defense in depth means a future refactor that loosens the use-case guard (e.g., to allow single-member family probes for debugging) won't accidentally render a misleading "Family · 1 book" card.

## Deviations from Plan

None — plan executed exactly as written. Both tasks completed in sequence; build_runner + analyze ran clean on the first try; arch guardrail tests pass; no auto-fixes (Rules 1-3) applied.

## Self-Check: PASSED

Created files:
- FOUND: `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart`
- FOUND: `lib/features/analytics/presentation/providers/state_ledger_snapshot.g.dart`

Modified files:
- FOUND: `lib/features/analytics/presentation/providers/repository_providers.dart` (extended with 4 new use case providers)
- FOUND: `lib/features/analytics/presentation/providers/repository_providers.g.dart` (regenerated with 4 new `*Provider` symbols)

Commits:
- FOUND: `d3bd749` feat(16-06): wire 4 ledger-snapshot use case providers
- FOUND: `8497ed0` feat(16-06): add state_ledger_snapshot.dart with 4 Riverpod Future providers
