---
phase: 10-homepage-soulfullnesscard-redesign
plan: 05
subsystem: state-management
tags: [riverpod, provider, currency-resolution, parameterized-provider, book-repository]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign
    provides: BookRepository.findById interface (existing) + Book domain model (existing)
provides:
  - bookByIdProvider — parameterized @riverpod Future<Book?> for currency resolution
  - Eliminates the only legitimate path to remove hardcoded 'JPY' from widget code
affects:
  - 10-06 (HomeHeroCard composition — Wave 4 widget will receive currencyCode via constructor)
  - Wave 5 home_screen.dart parent — will read bookByIdProvider(bookId: bookId).valueOrNull?.currency ?? 'JPY'

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parameterized @riverpod with required named arguments (mirrors state_happiness.dart `happinessReport`)"
    - "Resource provider co-located with bookRepository in repository_providers.dart (single source of truth per feature)"

key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/providers/repository_providers.dart (+13 lines: 1 import + provider doc/body)
    - lib/features/accounting/presentation/providers/repository_providers.g.dart (+177 lines: BookByIdFamily + BookByIdProvider + element class — generated)

key-decisions:
  - "Place bookById in repository_providers.dart (not state_*.dart) because the provider is a thin repo wrapper, not a state aggregator"
  - "Return Future<Book?> (not Future<Book>) — null is the legitimate signal for 'no book yet, parent should fall back to JPY'"
  - "No keepAlive directive — default auto-dispose is correct; provider will recreate on bookId change anyway (parameterized providers are family-scoped)"
  - "Commit source + generated .g.dart together in a single commit (CLAUDE.md Pitfall #13 / AUDIT-10 guardrail)"

patterns-established:
  - "Parameterized resource provider: @riverpod Future<T?> name(Ref ref, {required String id}) async => ref.watch(repoProvider).findById(id)"
  - "Currency resolution chain: parent screen reads bookByIdProvider → passes Book.currency through widget constructor → widget never resolves currency itself (CLAUDE.md Widget Parameter Pattern + Pitfall #9)"

requirements-completed: []

# Metrics
duration: ~5 min
completed: 2026-05-03
---

# Phase 10 Plan 05: bookByIdProvider for Currency Resolution Summary

**Adds a parameterized `bookByIdProvider` (Future<Book?>) so HomeHeroCard's parent screen can resolve `Book.currency` via Riverpod and stop hardcoding `'JPY'` inside widget code (CLAUDE.md Pitfall #9).**

## Performance

- **Duration:** ~5 min (build_runner: 20s; flutter analyze: 2.4s + 2.9s)
- **Started:** 2026-05-03T01:05:00Z (approximate)
- **Completed:** 2026-05-03T01:10:36Z
- **Tasks:** 2 (both completed)
- **Files modified:** 2

## Accomplishments
- Added parameterized `@riverpod Future<Book?> bookById(Ref ref, {required String bookId})` to `lib/features/accounting/presentation/providers/repository_providers.dart` at lines 55–65 (delegates to `ref.watch(bookRepositoryProvider).findById(bookId)`)
- Added missing `Book` model import (`../../domain/models/book.dart`) at line 33
- Regenerated `repository_providers.g.dart` via `flutter pub run build_runner build --delete-conflicting-outputs` — emitted `bookByIdProvider` (const family handle), `BookByIdFamily`, `BookByIdProvider` (AutoDisposeFutureProvider<Book?>), and `_BookByIdProviderElement`
- Verified `flutter analyze lib/`: 0 issues
- Verified `provider_graph_hygiene_test.dart`: 6/6 tests passed (HIGH-04 structure, DI consolidation, global uniqueness, HIGH-05 keepAlive, HIGH-06 no UnimplementedError)

## Task Commits

Each task was committed atomically (Tasks 5.1 + 5.2 batched per plan note Pitfall #13 — source and generated files must commit together):

1. **Task 5.1: Add bookByIdProvider** — `da7b7f9` (feat) — combined with Task 5.2
2. **Task 5.2: Run build_runner & verify** — `da7b7f9` (feat) — combined with Task 5.1

**Combined commit:** `da7b7f9` — `feat(10-05): add bookByIdProvider for currency-code resolution`

## Files Created/Modified

- `lib/features/accounting/presentation/providers/repository_providers.dart`
  - Line 33: added `import '../../domain/models/book.dart';`
  - Lines 55–65: new `bookById` provider block (5-line doc comment + `@riverpod` + 4-line function body) inserted between `bookRepository` (lines 47–53) and `categoryRepository` (now at line 67)
- `lib/features/accounting/presentation/providers/repository_providers.g.dart`
  - +177 lines of generated code: `bookByIdProvider` constant, `BookByIdFamily` (extends `Family<AsyncValue<Book?>>`), `BookByIdProvider` (extends `AutoDisposeFutureProvider<Book?>`), `_BookByIdProviderElement` (extends `AutoDisposeFutureProviderElement<Book?>`), plus updated dependency hash list

## Decisions Made

- **Provider placement:** Co-located with `bookRepository` in `repository_providers.dart` (Riverpod Provider Rules: ONE `repository_providers.dart` per feature). Did not move to `state_*.dart` because the provider is a thin lookup wrapper, not state aggregation logic.
- **Nullable return type:** `Future<Book?>` not `Future<Book>` — the null signal is the legitimate hook for parent-screen fallback (`?? 'JPY'`); keeps the JPY literal out of the widget body.
- **Auto-dispose default:** Did not add `@Riverpod(keepAlive: true)` — parameterized providers are family-scoped (one instance per `bookId`), so auto-dispose on unwatch is correct; HIGH-05 keepAlive hard-list test confirmed no regression.

## Deviations from Plan

None — plan executed exactly as written. The acceptance criterion "`@riverpod` count returns ≥ 13 (12 existing + 1 new)" was technically inaccurate (the file had 18 existing `@riverpod` annotations, now 19), but the spirit of the criterion (count went up by exactly 1) is satisfied.

**Total deviations:** 0
**Impact on plan:** None — clean execution.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Self-Check

Verified post-execution:

- `lib/features/accounting/presentation/providers/repository_providers.dart` — exists, contains `Future<Book?> bookById` at line 62, `required String bookId` at line 62, `import '../../domain/models/book.dart';` at line 33, `repo.findById(bookId)` at line 64
- `lib/features/accounting/presentation/providers/repository_providers.g.dart` — exists, contains `bookByIdProvider` (line 60), `BookByIdFamily` (line 70), `BookByIdProvider` class (line 121), `_BookByIdProviderElement` (line 197)
- Commit `da7b7f9` — present in `git log` on branch `worktree-agent-af683bb785298d0aa`
- `flutter analyze lib/` — 0 issues
- `flutter test test/architecture/provider_graph_hygiene_test.dart` — 6/6 passed

## Self-Check: PASSED

## Next Phase Readiness

- Wave 4 (HomeHeroCard composition, plan 10-06+) can now consume `bookByIdProvider` from the parent screen and pass `Book.currency` into the widget via constructor (Widget Parameter Pattern, CLAUDE.md Pitfall #9 compliant).
- Wave 5 (home_screen.dart wiring) usage pattern: `final currency = ref.watch(bookByIdProvider(bookId: bookId)).valueOrNull?.currency ?? 'JPY';`
- No blockers. The `'JPY'` literal in any future widget body is now unambiguously a violation — the legitimate fallback path lives in the parent screen only.

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Completed: 2026-05-03*
