---
phase: 58-flutter-analyzer-code-generation-lane
plan: "09"
subsystem: tooling
tags: [dart, flutter, riverpod, parser, analyzer, architecture-tests]
requires:
  - phase: 58-08
    provides: Serialized live provider-contract fixture harness and recovery-safe locking
provides:
  - Exact one-parenthesized direct runApp root enforcement
  - Loop-statement-bounded Riverpod alias shadows for C-style and for-in headers
affects: [58-10, provider-contract, tooling-guards]
actuals:
  tokens: 3959
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Exact token-shape recognition keeps parenthesized runApp support fail-closed.
    - Production-tree provider scans share the live-fixture transaction lock.
key-files:
  created: []
  modified:
    - scripts/audit/provider_contract.dart
    - scripts/verify_tooling_guards.dart
    - test/architecture/provider_contract_test.dart
    - test/architecture/tooling_guard_negative_fixture_test.dart
key-decisions:
  - "Recognize only one parenthesized unqualified or verified Flutter-prefix runApp reference; chained, .call-parenthesized, and double-group forms remain excluded."
  - "Walk containing parentheses to find an actual for header and end its alias shadow at the complete loop statement."
requirements-completed: [GEN-02]
coverage:
  - id: D1
    description: "Unscoped one-parenthesized direct runApp roots fail the parser and live child-process guard while Riverpod controls pass."
    requirement: GEN-02
    verification:
      - kind: integration
        ref: "flutter test test/architecture/provider_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart --plain-name 'parenthesized runApp'"
        status: pass
      - kind: other
        ref: "dart run scripts/verify_tooling_guards.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "C-style and for-in header aliases stay fail-closed inside their loop and stop shadowing immediately after it."
    requirement: GEN-02
    verification:
      - kind: unit
        ref: "test/architecture/provider_contract_test.dart#for-loop lexical shadow boundaries"
        status: pass
      - kind: other
        ref: "flutter analyze --no-fatal-infos scripts/audit/provider_contract.dart scripts/verify_tooling_guards.dart test/architecture/provider_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-08
status: complete
---

# Phase 58 Plan 09: Provider Contract Syntax and Loop Scope Summary

**Exact parenthesized runApp enforcement and statement-bounded for-header alias shadows close both remaining provider-contract defects without broadening receiver matching.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-08-08T13:13:47Z
- **Completed:** 2026-08-08T13:31:23Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added fail-first parser and real child-process bad/control evidence for unqualified and verified Flutter-prefix `(runApp)(...)` roots.
- Accepted only exact single grouping around direct function references while preserving immediate and `.call` behavior and rejecting all broader receiver/grouping forms.
- Bound C-style and for-in Riverpod aliases to their own braced or single-statement loops, retaining inside-loop rejection and post-loop imports.

## Task Commits

1. **Task 1: Trace one-parenthesized runApp references through the real provider guard** - `349eb74d` (test), `8d25c572` (fix)
2. **Task 2: Bound C-style and for-in alias bindings to their loop statements** - `711a5d65` (test), `b8d60655` (fix)

## Files Created/Modified

- `scripts/audit/provider_contract.dart` — recognizes exact parenthesized direct roots and calculates for-header statement endpoints.
- `scripts/verify_tooling_guards.dart` — provides the four default parenthesized live fixture cases.
- `test/architecture/provider_contract_test.dart` — proves exact root exclusions, loop boundaries, and lock-safe production-tree scans.
- `test/architecture/tooling_guard_negative_fixture_test.dart` — proves real child-process parenthesized bad/control diagnostics and cleanup.

## Decisions Made

- Parenthesized matching is intentionally limited to one group around `runApp` or a verified Flutter-prefix `runApp`; arbitrary chains, double groups, and parenthesized `.call` references are excluded.
- Loop-header aliases use the existing statement-bound helper path rather than changing if/switch/type scope behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Serialized the production-tree provider scan with live fixtures**
- **Found during:** Task 1 verification
- **Issue:** Default-concurrency test isolates could scan a temporary `phase58_*fixture.dart` while the live harness owned it, causing a false production-tree violation and interrupted fixture cleanup.
- **Fix:** Wrapped only the production-tree assertion in the existing `withToolingGuardFixtureLock` transaction.
- **Files modified:** `test/architecture/provider_contract_test.dart`
- **Verification:** Focused parenthesized parser/live tests, full provider-contract regression, scoped analyzer, and zero-residue checks passed.
- **Committed in:** `8d25c572`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The fix preserves the existing locking contract and makes the required default-concurrency evidence deterministic; no product or tooling-policy scope expanded.

## Issues Encountered

- Flutter's SDK cache requires sandbox escalation for local verification; no dependency or SDK content changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Provider-contract GEN-02 gap evidence is complete for the dependent code-generation closure plan.
- D-10 remains intact: no dependency graph, generated application output, database/schema, native/plugin/device, or UI work was changed.

## Verification

- PASS: focused parenthesized parser and live child-process matrix.
- PASS: `flutter test test/architecture/provider_contract_test.dart` (15 tests).
- PASS: focused live parenthesized fixture test.
- PASS: `dart run scripts/verify_tooling_guards.dart`.
- PASS: scoped analyzer, `git diff --check`, and no `lib/phase58_*fixture.dart` residue.

## Self-Check: PASSED

- Found all four modified implementation/test files and this summary.
- Verified commits `349eb74d`, `8d25c572`, `711a5d65`, and `b8d60655` exist.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-08*
