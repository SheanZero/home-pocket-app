---
phase: 09-happiness-domain-formula-layer
plan: 08
subsystem: providers
tags: [riverpod, analytics, happiness, presentation, provider-wiring]

requires:
  - phase: 09-happiness-domain-formula-layer
    provides: Plans 09-05, 09-06, and 09-07 happiness use cases
provides:
  - Happiness use case providers in the analytics presentation provider registry
  - Consumer-facing happinessReport, bestJoyMoment, and familyHappiness async providers
  - Provider wiring smoke tests for happiness use cases and family empty shortcuts
affects: [phase-10-homepage, phase-11-statistics, happiness-provider-surface]

tech-stack:
  added: []
  patterns:
    - "Use case providers live in lib/features/analytics/presentation/providers/repository_providers.dart, matching existing analytics providers."
    - "Consumer-facing async state providers live in state_happiness.dart and call constructor-injected use cases."

key-files:
  created:
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/providers/state_happiness.g.dart
    - test/unit/features/analytics/presentation/providers/repository_providers_test.dart
  modified:
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart

key-decisions:
  - "Added providers to the presentation analytics repository_providers.dart, not the application-layer re-export file."
  - "familyHappinessProvider explicitly returns empty FamilyHappiness for no active group and for active group with no shadow books."
  - "Q6c remains open: familyHappinessProvider currently passes shadow book IDs only; Phase 10/11 may add current-device book inclusion if required."

patterns-established:
  - "Happiness provider surface mirrors state_analytics.dart: parameterized Riverpod Future providers with caller-supplied book/year/month/currency parameters."
  - "Family provider resolves activeGroupProvider and shadowBooksProvider.future at presentation level before invoking the family use case."

requirements-completed: [HAPPY-01, HAPPY-02, HAPPY-03, HAPPY-04, FAMILY-01, FAMILY-02]

duration: 52min
completed: 2026-05-02
---

# Phase 09 Plan 08: Happiness Provider Wiring Summary

**Riverpod provider wiring now exposes Phase 09 happiness use cases through the analytics presentation layer and a consumer-facing happiness state surface.**

## Performance

- **Duration:** 52 min
- **Started:** 2026-05-02T00:40:00Z
- **Completed:** 2026-05-02T01:32:12Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `getHappinessReportUseCaseProvider`, `getBestJoyMomentUseCaseProvider`, and `getFamilyHappinessUseCaseProvider` to the existing analytics presentation provider registry.
- Created `state_happiness.dart` with `happinessReportProvider`, `bestJoyMomentProvider`, and `familyHappinessProvider`.
- Wired family happiness through `activeGroupProvider` and `shadowBooksProvider.future`, mapping `ShadowBookInfo.book.id` to `groupBookIds`.
- Added smoke tests confirming the 3 use-case providers resolve and family happiness returns empty results without a group or shadow books.

## Task Commits

1. **Task 1: Extend repository_providers.dart with 3 new use case providers** - `e8c1e87` (feat)
2. **Task 2 RED: Happiness provider smoke tests** - `447565e` (test)
3. **Task 2 GREEN: state_happiness.dart async providers** - `420df04` (feat)

## Files Created/Modified

- `lib/features/analytics/presentation/providers/repository_providers.dart` - Added 3 happiness use case providers in the correct single-source provider registry.
- `lib/features/analytics/presentation/providers/repository_providers.g.dart` - Regenerated Riverpod provider code.
- `lib/features/analytics/presentation/providers/state_happiness.dart` - Added consumer-facing async providers for personal, top-joy, and family happiness.
- `lib/features/analytics/presentation/providers/state_happiness.g.dart` - Generated Riverpod provider code.
- `test/unit/features/analytics/presentation/providers/repository_providers_test.dart` - Added provider graph smoke tests and family empty-shortcut tests.

## Decisions Made

- Followed `09-PATTERNS.md`: use case providers were added to `lib/features/analytics/presentation/providers/repository_providers.dart`; `lib/application/analytics/repository_providers.dart` remains only the app database re-export surface.
- Kept `currencyCode`, `bookId`, `year`, and `month` caller-supplied for personal providers. Phase 10 owns current-book and currency resolution.
- Implemented explicit provider-level empty short-circuits for no group and empty shadow books. This keeps the provider defensive even though `GetFamilyHappinessUseCase` also handles `groupBookIds: []`.
- Q6c is not resolved in this plan: `familyHappinessProvider` passes shadow books only. Current-device book inclusion remains a Phase 10/11 call-site refinement if the product contract requires "family" to include the local user's own book.

## Verification

- RED: `flutter test test/unit/features/analytics/presentation/providers/repository_providers_test.dart` failed before `state_happiness.dart` existed.
- `flutter pub run build_runner build --delete-conflicting-outputs` passed and generated provider code.
- `flutter test test/unit/features/analytics/presentation/providers/repository_providers_test.dart` passed: 5 tests.
- `flutter test test/architecture/provider_graph_hygiene_test.dart` passed: 5 tests.
- `flutter analyze lib/features/analytics/presentation/providers/` passed with 0 issues.
- `flutter analyze` passed with 0 issues.
- Acceptance greps passed for 3 `@riverpod` declarations, provider function names, `shadowBooksProvider.future`, `activeGroupProvider`, generated `state_happiness.g.dart`, and retained `getMonthlyReportUseCase`.

## Deviations from Plan

None - plan executed as specified.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The plan referenced `test/arch/provider_graph_hygiene_test.dart`; the repository path is `test/architecture/provider_graph_hygiene_test.dart`, so verification used the existing path.
- Full `flutter test` is not green in the current worktree for out-of-scope, pre-existing failures:
  - `test/unit/data/migrations/index_v15_migration_test.dart` expects `AppDatabase.schemaVersion == 15`, but Phase 09 already moved schemaVersion to 16.
  - `test/scripts/build_cleanup_touched_files_test.dart` has 4 subprocess failures from `build_cleanup_touched_files.sh` exiting 1 against the historical plan tree.
  - Final full-suite result: `+1377 -5`.

## Known Stubs

None. Stub scan found only the intentional `activeGroup == null` empty-state branch in `state_happiness.dart`.

## Threat Flags

None. This plan added provider wiring only; no endpoint, auth path, file access pattern, schema change, or new trust boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 10 and Phase 11 can consume `happinessReportProvider`, `bestJoyMomentProvider`, and `familyHappinessProvider` without duplicating use-case wiring. Current-book inclusion for family metrics remains the only documented open integration detail.

## Self-Check: PASSED

- Found `lib/features/analytics/presentation/providers/state_happiness.dart`.
- Found `lib/features/analytics/presentation/providers/state_happiness.g.dart`.
- Found `test/unit/features/analytics/presentation/providers/repository_providers_test.dart`.
- Found task commits `e8c1e87`, `447565e`, and `420df04` in git history.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not modified.

---
*Phase: 09-happiness-domain-formula-layer*
*Completed: 2026-05-02*
