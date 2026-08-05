---
phase: 58-flutter-analyzer-code-generation-lane
plan: "03"
subsystem: tooling
tags: [flutter, code-generation, build_runner, l10n, analyzer, custom_lint]
requires:
  - phase: 57-stable-baseline-compatibility-contract
    provides: Stable SDK and dependency compatibility validator
provides:
  - Strict two-pass code-generation reproducibility wrapper
  - Source contract for fail-closed quality-gate ordering
affects: [58-04, 58-05, Stable CI, local verification]
actuals:
  tokens: 2598
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns:
    - Generation scope is clean before and after each deterministic pass.
    - Lint and architecture gates run exactly once only after pass two.
key-files:
  created:
    - scripts/verify_codegen_reproducibility.sh
    - test/architecture/codegen_reproducibility_contract_test.dart
  modified: []
key-decisions:
  - "Use HEAD-scoped diffs across pubspec, lockfile, localization output, and tracked generated Dart so staged and unstaged generator drift both fail."
  - "Keep the live wrapper unexecuted in Wave 0; Plan 58-05 owns live proof after graph and CI work are committed."
patterns-established:
  - "D-08: enforced lock resolution and baseline validation precede two l10n/build_runner passes."
  - "D-09: each pass must be clean before any analyzer, custom_lint, architecture, tooling-guard, or whitespace gate runs."
requirements-completed: [GEN-04]
coverage:
  - id: D1
    description: Strict two-pass generation wrapper with scoped drift diagnostics and downstream quality gates.
    requirement: GEN-04
    verification:
      - kind: unit
        ref: test/architecture/codegen_reproducibility_contract_test.dart
        status: pass
      - kind: other
        ref: bash -n scripts/verify_codegen_reproducibility.sh
        status: pass
    human_judgment: false
---

# Phase 58 Plan 03: Code Generation Reproducibility Summary

**An executable, source-tested D-08/D-09 gate that proves two clean l10n/build_runner passes before lint, architecture, and tooling enforcement.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-06T01:47:13+09:00
- **Completed:** 2026-08-06T01:50:46+09:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added an executable repository-rooted wrapper that refuses dirty tracked generator scope before resolution, runs the baseline validator, and checks both generated passes against `HEAD`.
- Deferred analyzer, custom_lint, all three architecture tests, tooling guards, and whitespace validation until the second scoped diff is clean.
- Added source-contract mutations that reject reordered, omitted, duplicated, comment-only, and swallowed quality commands; second-pass drift is explicitly reported as nondeterminism.

## Task Commits

1. **Task 1: Lock the first clean generation pass and diff scope** — `09e853a7` (test), `1fb1072e` (feat)
2. **Task 2: Require a second identical pass to prove generator idempotence** — `29b0749c` (test), `5ab287dc` (feat)
3. **Rule 2 completion hardening** — `7b0d8cda` (test), `3768ae38` (fix)

## Files Created/Modified

- `scripts/verify_codegen_reproducibility.sh` — authoritative strict local/Stable-CI code-generation and quality-gate wrapper.
- `test/architecture/codegen_reproducibility_contract_test.dart` — source contract that protects D-08/D-09 ordering and fail-closed behavior.

## Decisions Made

- Use `git diff --exit-code HEAD --` with the explicit generator scope so both staged and unstaged tracked output drift are blocking without altering user work.
- Keep code generation commands unrolled twice so the source contract can verify the exact per-pass order directly.
- Do not execute the live wrapper in Wave 0; it depends on the concurrently created tooling guard and later graph/CI work, and Plan 58-05 owns that integration proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added explicit second-pass nondeterminism evidence**
- **Found during:** Task 2 final contract review
- **Issue:** The generic pass-number diagnostic identified pass 2 but did not explicitly state that the generator was nondeterministic.
- **Fix:** Added a pass-2-specific error message and locked it with the source contract.
- **Files modified:** `scripts/verify_codegen_reproducibility.sh`, `test/architecture/codegen_reproducibility_contract_test.dart`
- **Verification:** Targeted source-contract suite, shell syntax check, and targeted analyzer passed.
- **Committed in:** `7b0d8cda`, `3768ae38`

**Total deviations:** 1 auto-fixed (Rule 2)

## Issues Encountered

Flutter test startup requires SDK-cache writes outside the workspace sandbox; the targeted verification was rerun with the required local execution permission and passed.

`state.advance-plan` could not parse this phase's pre-existing `STATE.md` current-plan format, so it did not advance that counter. The other state, metric, decision, session, roadmap, and requirement handlers completed successfully.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Plans 58-04 and 58-05 can route Stable CI through the committed wrapper. Plan 58-05 must run the live wrapper only after the selected dependency graph and tooling-guard files are committed.

## Self-Check: PASSED

Confirmed both owned artifacts and all six TDD/task commits exist in the repository history.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-06*
