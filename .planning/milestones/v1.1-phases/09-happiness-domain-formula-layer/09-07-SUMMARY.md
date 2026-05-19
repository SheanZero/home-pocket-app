---
phase: 09-happiness-domain-formula-layer
plan: 07
subsystem: analytics
tags: [use-case, family, anti-leaderboard, fan-out, tdd]

requires:
  - phase: 09-happiness-domain-formula-layer
    provides: Plan 09-02 FamilyHappiness/SharedJoyInsight/MetricResult domain contracts and Plan 09-04 AnalyticsRepository happiness methods
provides:
  - GetFamilyHappinessUseCase with groupBookIds fan-out aggregation
  - FAMILY-01 aggregate-only family highlights sum
  - FAMILY-02 shared joy insight 3-tuple wrapping with min-N Empty handling
  - Group median satisfaction from combined per-book distributions
  - Anti-leaderboard grep-gate test covering family return contracts
affects: [family-happiness, phase-10-homepage, phase-11-statistics, anti-leaderboard-contract]

tech-stack:
  added: []
  patterns:
    - "Use cases accept presentation-resolved groupBookIds and stay free of member metadata."
    - "Family metrics aggregate per-book repository data without preserving per-book or per-member breakdowns."

key-files:
  created:
    - lib/application/analytics/get_family_happiness_use_case.dart
    - test/unit/application/analytics/get_family_happiness_use_case_test.dart
  modified: []

key-decisions:
  - "Duplicated the distribution median helper locally in the family use case, matching the plan and avoiding cross-use-case coupling until a third caller appears."
  - "Kept shared joy sampleSize equal to totalGroupSoulTx while SharedJoyInsight itself carries only categoryId, avgSatisfaction, and totalCount."

patterns-established:
  - "Family use-case privacy contract is enforced by both return types and a test-suite grep gate."
  - "Group zero-sample alignment returns Empty for every main metric, while nonzero samples can still return Value(0) for highlights."

requirements-completed: [FAMILY-01, FAMILY-02]

duration: 4min
completed: 2026-05-02
---

# Phase 09 Plan 07: Family Happiness Use Case Summary

**Family-level happiness metrics now aggregate shadow-book data without exposing member or per-book leaderboard shapes.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-02T01:17:22Z
- **Completed:** 2026-05-02T01:21:39Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added 9 tests covering empty short-circuit, zero-count alignment, per-book fan-out, highlights aggregation, shared joy wrapping, min-N Empty handling, group median, and anti-leaderboard contract scanning.
- Implemented `GetFamilyHappinessUseCase.execute(groupBookIds:, year:, month:)` with no repository calls for empty groups.
- Aggregated FAMILY-01 as `MetricResult<int>` with a single family count and computed group median from combined satisfaction buckets.
- Wrapped FAMILY-02 as `MetricResult<SharedJoyInsight>` using only the approved 3-tuple fields.

## Task Commits

1. **Task 1 RED: Family use case tests and grep gate** - `eb3fda2` (test)
2. **Task 2 GREEN: GetFamilyHappinessUseCase** - `e5b3398` (feat)

## Files Created/Modified

- `test/unit/application/analytics/get_family_happiness_use_case_test.dart` - Mocktail TDD tests for all plan cases plus the anti-leaderboard grep-gate.
- `lib/application/analytics/get_family_happiness_use_case.dart` - Family aggregate use case with `Future.wait` fan-out, single shared-joy query, aggregate highlights, and group median helper.

## Verification

- RED: `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart` failed because `get_family_happiness_use_case.dart` did not exist and `GetFamilyHappinessUseCase` was undefined.
- GREEN: `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart` passed: 9 tests.
- `flutter analyze lib/application/analytics/get_family_happiness_use_case.dart test/unit/application/analytics/get_family_happiness_use_case_test.dart` passed with 0 issues.
- Full `flutter analyze` passed with 0 issues after concurrent 09-05 work finished pairing its RED test with implementation.
- Contract grep found no `Map<MemberId, ...>`, `Map<String, int>`, `memberId`, `deviceId`, or `memberDisplayName` leakage in the family use case and family tuple models.
- Acceptance greps confirmed `groupBookIds`, empty short-circuit, `Future.wait`, `_highlightsThreshold = 6`, and `Value(highlightsSum, totalGroupSoulTx)`.

## Decisions Made

- Duplicated the median distribution-walk helper in `GetFamilyHappinessUseCase` rather than extracting shared utility code. This matches the plan rationale: two callers are not enough to justify new cross-use-case coupling.
- Left shadow-book resolution outside the use case. Presentation remains responsible for resolving the family group into `groupBookIds`.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- Full `flutter analyze` initially failed because concurrent Plan 09-05 had committed a RED test importing a missing `GetHappinessReportUseCase`. This was out of scope for 09-07 and was not modified here. A later full analyze passed after the concurrent implementation landed.

## Known Stubs

None. Stub scan found only legitimate `== null` checks, not placeholder data or hardcoded empty UI values.

## Threat Flags

None. This plan implemented the planned T-9-04 mitigation surface; no new endpoint, auth path, file access pattern, schema change, or unplanned trust boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 10 and Phase 11 can consume `FamilyHappiness` through this use case once presentation resolves `groupBookIds`. The anti-leaderboard contract is pinned by both type shape and tests.

## Self-Check: PASSED

- Created use case file exists on disk.
- Created test file exists on disk.
- SUMMARY.md exists on disk.
- Task commit `eb3fda2` exists in git history.
- Task commit `e5b3398` exists in git history.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not modified.

---
*Phase: 09-happiness-domain-formula-layer*
*Completed: 2026-05-02*
