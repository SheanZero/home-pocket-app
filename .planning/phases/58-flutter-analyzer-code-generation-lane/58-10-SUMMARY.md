---
phase: 58-flutter-analyzer-code-generation-lane
plan: "10"
subsystem: tooling
tags: [flutter, dart, build_runner, code-generation, reproducibility, testing]
requires:
  - phase: 58-09
    provides: Parenthesized runApp and loop-shadow provider-contract regressions
provides:
  - Two authoritative conflict-deleting build_runner passes in the D-08 sequence
  - Exact executable-line and mutation protection for the complete build command
  - Default-concurrency-safe live fixture verification
affects: [codegen-wrapper, stable-ci, tooling-guards, GEN-04]
actuals:
  tokens: 1940
  tasks: 1
  commits: 3
tech-stack:
  added: []
  patterns:
    - Source contracts count required shell commands by trimmed executable-line equality.
    - Serialized multi-fixture child-process tests receive an explicit concurrency-safe timeout.
key-files:
  created: []
  modified:
    - scripts/verify_codegen_reproducibility.sh
    - test/architecture/codegen_reproducibility_contract_test.dart
    - test/architecture/tooling_guard_negative_fixture_test.dart
key-decisions:
  - "The complete build_runner command is enforced by executable-line equality, so its shorter prefix cannot pass the contract."
  - "Only the existing two unrolled D-08 build steps receive --delete-conflicting-outputs; no alternative CI or generation route was added."
  - "The six-case live fixture test has a two-minute timeout because serialized default-concurrency scheduling can exceed its prior 30-second limit while its isolated work completes in 25 seconds."
patterns-established:
  - "Exact shell-command contracts combine line equality for critical commands with mutation tests for count and ordering."
requirements-completed: [GEN-04]
coverage:
  - id: D1
    description: Both authoritative D-08 generator passes use the exact conflict-deleting build_runner command in the required order.
    requirement: GEN-04
    verification:
      - kind: unit
        ref: "test/architecture/codegen_reproducibility_contract_test.dart#build_runner command is exact on both D-08 passes"
        status: pass
      - kind: integration
        ref: "bash scripts/verify_codegen_reproducibility.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: Provider parser and live child-process guard regressions, including the 58-09 parenthesized and loop-scope closures, remain green under the selected toolchain.
    verification:
      - kind: integration
        ref: "flutter test test/architecture/provider_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart test/architecture/codegen_reproducibility_contract_test.dart"
        status: pass
      - kind: other
        ref: "dart run scripts/verify_tooling_guards.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: Default-concurrency coverage and the exact Stable LCOV 70% gate pass with no generated-output or Phase 58 fixture residue.
    verification:
      - kind: integration
        ref: "flutter test --coverage"
        status: pass
      - kind: other
        ref: "coverde filter + scripts/coverage_gate.dart --threshold 70 + git diff checks"
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-08-08
status: complete
---

# Phase 58 Plan 10: Conflict-Deleting Code Generation Summary

**The authoritative two-pass Flutter code-generation wrapper now regenerates stale conflicts with an exact, mutation-tested command while preserving the single Stable CI route.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-08-08T13:33:00Z
- **Completed:** 2026-08-08T14:02:45Z
- **Tasks:** 1/1
- **Files modified:** 3

## Accomplishments

- Added the missing `--delete-conflicting-outputs` flag to both—and only both—unrolled D-08 `build_runner` passes.
- Replaced prefix-based build command counting with trimmed executable-line equality and mutations for shortened, misspelled, duplicated, reordered, and prematurely gated commands.
- Re-proved the complete wrapper, parenthesized/loop provider contracts, live fixture harness, default-concurrency coverage, Stable 70% gate, whitespace, generated scope, and residue checks.

## Task Commits

1. **Task 1: Require and execute conflict-deleting builds on both D-08 passes** — `38f16221` (RED test), `849db861` (GREEN fix)
2. **Rule 1 verification stabilization: Allow serialized live fixtures under default concurrency** — `c30a30e1` (test)

## Files Created/Modified

- `scripts/verify_codegen_reproducibility.sh` — runs the exact conflict-deleting command after each l10n pass.
- `test/architecture/codegen_reproducibility_contract_test.dart` — protects the complete command and per-pass D-08 ordering with adversarial mutations.
- `test/architecture/tooling_guard_negative_fixture_test.dart` — allows the six serialized live lookalike fixtures to finish in the default-concurrency full suite.

## Decisions Made

- The contract compares trimmed executable lines for the complete build command rather than a substring, preventing the shorter command from satisfying D-08.
- The explicit two-pass wrapper remains unrolled and remains the only Stable CI generation/lint route.
- A two-minute timeout is limited to the multi-fixture live child-process test; it removes a default-concurrency false failure without weakening any fixture assertion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stabilized the serialized live-fixture test under default concurrency**
- **Found during:** Task 1 final default-concurrency coverage verification.
- **Issue:** The existing six-case live provider lookalike test passes in isolation in 25 seconds but exceeded its default 30-second timeout when queued behind concurrent test isolates, causing the required `flutter test --coverage` run to fail.
- **Fix:** Applied a two-minute timeout only to that serialized live-fixture test; its assertions, command paths, locking behavior, and cleanup requirements are unchanged.
- **Files modified:** `test/architecture/tooling_guard_negative_fixture_test.dart`
- **Verification:** Isolated test passed; the rerun of `flutter test --coverage` passed at default concurrency (4,554 passed; 12 skipped).
- **Committed in:** `c30a30e1`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Necessary for the required default-concurrency acceptance gate. It adds no product, dependency, generated-output, schema, native, UI, simulator, or device scope.

## Issues Encountered

- The Flutter build-runner version reports `--delete-conflicting-outputs` as deprecated/ignored, but it accepts the mandated command and both authoritative clean passes, subsequent gates, and source contract pass. The exact command remains required by D-08.
- The first default-concurrency coverage run exposed the pre-existing 30-second test timeout; the scoped stability fix above made the rerun green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GEN-04’s third verifier gap is closed with RED→GREEN source evidence and a live two-pass wrapper run.
- GEN-02’s 58-09 parenthesized-root and loop-scope proof was re-run successfully.
- D-10 remains intact: no dependency graph, generated hand edit, database/schema, plugin, native/Xcode, UI, simulator, or device work was performed. The accepted iOS deployment mismatch remains Phase 60 work.

## Verification

- PASS: RED focused exact-command source contract failed only because the complete executable command count was zero.
- PASS: `bash -n scripts/verify_codegen_reproducibility.sh`.
- PASS: focused and complete `codegen_reproducibility_contract_test.dart`.
- PASS: provider/parser, tooling-fixture, and code-generation architecture suites; `dart run scripts/verify_tooling_guards.dart`.
- PASS: `bash scripts/verify_codegen_reproducibility.sh` including locked resolution, two clean generator passes, analyzer/import-lint, architecture contracts, and all live tooling cases.
- PASS: `flutter test --coverage` at default concurrency — 4,554 passed, 12 skipped.
- PASS: exact Stable LCOV filtering and 70% gate — 15 checked, zero below threshold or missing LCOV records.
- PASS: `git diff --check`, HEAD-scoped Pub/generated diff, and zero `lib/phase58_*fixture.dart` residue.

## Self-Check: PASSED

- Found all three modified implementation/test files and this summary.
- Verified commits `38f16221`, `849db861`, and `c30a30e1` exist.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-08*
