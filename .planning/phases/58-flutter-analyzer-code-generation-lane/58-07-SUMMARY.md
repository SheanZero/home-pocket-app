---
phase: 58-flutter-analyzer-code-generation-lane
plan: "07"
subsystem: testing
tags: [dart, flutter, riverpod, analyzer, architecture-tests]
requires:
  - phase: 58-06
    provides: Qualified Flutter root recognition and serialized live-fixture harness
provides:
  - Exact direct-function `runApp.call(...)` provider-root enforcement
  - Type-, if-case-, and switch-case-bounded Riverpod shadow ranges
  - Parser and child-process regressions for bad and scoped `.call` roots
affects: [58-08, provider-contract, tooling-guards]
actuals:
  tokens: 4825
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Direct-function `.call` roots retain the original `runApp` diagnostic offset.
    - Riverpod import-shadow records end at their true type, branch, or switch-case boundary.
key-files:
  created: []
  modified:
    - scripts/audit/provider_contract.dart
    - scripts/verify_tooling_guards.dart
    - test/architecture/provider_contract_test.dart
    - test/architecture/tooling_guard_negative_fixture_test.dart
key-decisions:
  - "Recognize only immediate invocation and exact direct-function `.call(...)` suffixes; arbitrary member chains remain excluded."
  - "Keep enclosing type, then-branch, and same-case shadows fail-closed while excluding unrelated lexical ranges."
patterns-established:
  - "Live bad/control fixtures must prove diagnostics, polarity, attribution, and cleanup through the owned child process."
requirements-completed: [GEN-02]
coverage:
  - id: D1
    description: "Unqualified and verified Flutter-prefix direct-function runApp.call roots receive provider-scope validation without accepting arbitrary chains."
    requirement: GEN-02
    verification:
      - kind: integration
        ref: "flutter test --concurrency=1 test/architecture/provider_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart"
        status: pass
      - kind: integration
        ref: "dart run scripts/verify_tooling_guards.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Riverpod shadow ranges are bounded to type, if-case, and switch-case lexical scopes."
    requirement: GEN-02
    verification:
      - kind: unit
        ref: "test/architecture/provider_contract_test.dart#lexical shadow boundaries"
        status: pass
      - kind: other
        ref: "flutter analyze --no-fatal-infos scripts/audit/provider_contract.dart scripts/verify_tooling_guards.dart test/architecture/provider_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-08-08
status: complete
---

# Phase 58 Plan 07: Provider Contract Gap Closure Summary

**Exact direct-function `runApp.call` enforcement and lexical Riverpod alias ranges close the provider-contract syntax bypass without broadening member-chain matching.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-08-08T11:51:41Z
- **Completed:** 2026-08-08T12:06:41Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added fail-first parser and real child-process bad/control evidence for unqualified and verified Flutter-prefix `runApp.call(...)` roots.
- Routed only exact direct-function `.call(...)` syntax through the established scope validation, preserving immediate calls and rejecting arbitrary or longer chains.
- Bounded Riverpod shadows to type bodies, `if` then statements, and individual `switch` cases while retaining enclosing-root negatives.

## Task Commits

1. **Task 1: Trace direct-function runApp.call roots through the real provider guard** - `6d4fd0eb` (test), `7363f891` (fix)
2. **Task 2: Bound Riverpod shadows to type members, if branches, and switch cases** - `810ac91c` (test), `269e4136` (fix)
3. **Refactor: keep touched tooling-guard test lint-clean** - `1d223e07` (refactor)

## Files Created/Modified

- `scripts/audit/provider_contract.dart` — recognizes exact direct-function `.call` roots and calculates bounded type/branch/case shadow ranges.
- `scripts/verify_tooling_guards.dart` — owns live unqualified and qualified `.call` bad/control fixture cases.
- `test/architecture/provider_contract_test.dart` — exercises `.call` roots and the lexical-shadow boundary matrix.
- `test/architecture/tooling_guard_negative_fixture_test.dart` — proves real child-process `.call` diagnostics, controls, and cleanup.

## Decisions Made

- Direct-function syntax is intentionally limited to `runApp(` and `runApp.call(` token shapes, retaining verified-prefix and no-longer-chain receiver checks.
- Lexical shadow detection remains conservative for enclosing scopes, but unrelated type members, else/post-if, and later-case roots no longer reject valid qualified Riverpod scopes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed a pre-existing redundant `const` in a touched fixture test**
- **Found during:** Final changed-file analyzer gate
- **Issue:** The touched test file had one `unnecessary_const` informational diagnostic, preventing the scoped analyzer result from reaching zero issues.
- **Fix:** Replaced `arguments: const []` with the equivalent `arguments: []`.
- **Files modified:** `test/architecture/tooling_guard_negative_fixture_test.dart`
- **Verification:** Scoped `flutter analyze --no-fatal-infos` reported `No issues found!`.
- **Committed in:** `1d223e07`

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Lint-only cleanup in a declared task file; no guard behavior or scope changed.

## Issues Encountered

- The broad `flutter analyze --no-fatal-infos` invocation completed with 290 informational diagnostics already present across unrelated project files. The plan-owned four-file analyzer invocation reported zero issues. The broad wrapper/regression command remains intentionally deferred to dependent Plan 58-08.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 58-08 can extend the corrected live-fixture guard with lock-open recovery evidence and run the final broad wrapper regression.

## TDD Gate Compliance

- RED commits: `6d4fd0eb`, `810ac91c`
- GREEN commits: `7363f891`, `269e4136`
- REFACTOR commit: `1d223e07`

## Self-Check: PASSED

- Verified all four declared implementation/test files exist.
- Verified commits `6d4fd0eb`, `7363f891`, `810ac91c`, `269e4136`, and `1d223e07` exist.
- Verified no `lib/phase58_*fixture.dart` sentinel remains after live-harness verification.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-08*
