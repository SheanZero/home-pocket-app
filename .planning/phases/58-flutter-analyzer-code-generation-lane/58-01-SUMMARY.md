---
phase: 58-flutter-analyzer-code-generation-lane
plan: "01"
subsystem: tooling
tags: [flutter, analyzer, import_lint, riverpod_lint, architecture, negative-fixtures]
requires:
  - phase: 57-stable-baseline-compatibility-contract
    provides: Stable SDK identity and dependency compatibility contract
provides:
  - Reversible fail-first package and relative import fixtures with exact-path cleanup
  - Fail-closed Riverpod app-root bad/control fixtures on the selected analyzer graph
  - Valid-production-tree tail checks for analyzer, import lint, layer scanning, and provider roots
affects: [58-02, 58-04, 58-05, Stable CI, architecture enforcement]
actuals:
  tokens: 30653
  tasks: 2
  commits: 8
tech-stack:
  added: []
  patterns:
    - Every invalid fixture uses one allowlisted sentinel path, refuses stale content, and cleans in finally.
    - Architecture enforcement is accepted only when deliberately invalid source fails and the valid tree passes.
key-files:
  created:
    - scripts/verify_tooling_guards.dart
    - test/architecture/tooling_guard_negative_fixture_test.dart
    - scripts/audit/provider_contract.dart
    - test/architecture/provider_contract_test.dart
  modified:
    - analysis_options.yaml
    - test/architecture/providers_audit_contract_test.dart
key-decisions:
  - "Close the partial plan against the current selected analyzer 12 + import_lint 2.0.0 + active riverpod_lint 3.1.4 graph; do not downgrade to the superseded analyzer 8/custom_lint proposal."
  - "Retain the repository-owned provider-root contract as defense in depth even though riverpod_lint is active."
patterns-established:
  - "D-04: negative fixtures must prove the actual diagnostic code and exact fixture path, then prove cleanup."
  - "Valid-tree checks fail closed on analyzer plugin protocol/version errors rather than treating a zero exit as sufficient."
requirements-completed: [GEN-02]
coverage:
  - id: D1
    description: Package and relative forbidden imports are independently rejected and every exact sentinel is cleaned.
    requirement: GEN-02
    verification:
      - kind: integration
        ref: "test/architecture/tooling_guard_negative_fixture_test.dart#package import fixture is rejected by import_lint and cleaned"
        status: pass
      - kind: integration
        ref: dart run scripts/verify_tooling_guards.dart
        status: pass
    human_judgment: false
  - id: D2
    description: Missing or shadowed ProviderScope roots fail while genuine ProviderScope controls and the production tree pass.
    requirement: GEN-02
    verification:
      - kind: integration
        ref: test/architecture/tooling_guard_negative_fixture_test.dart
        status: pass
      - kind: integration
        ref: dart run scripts/verify_tooling_guards.dart
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-08
status: complete
---

# Phase 58 Plan 01: Analyzer and Lint Negative-Fixture Infrastructure Summary

**Executable fail-first architecture and Riverpod-root probes with exact sentinel cleanup and a green valid-tree tail check on the current analyzer 12 graph.**

## Performance

- **Duration:** 8 min recovery close-out; implementation existed in prior committed work
- **Started:** 2026-08-08T17:15:00+09:00
- **Completed:** 2026-08-08T17:23:45+09:00
- **Tasks:** 2
- **Files modified:** 8 core tooling/config/test files

## Accomplishments

- Proved package-form and relative-form forbidden domain imports fail through independent architecture enforcement paths and leave no sentinel residue.
- Proved missing, locally shadowed, imported-shadowed, alias-shadowed, comment/string-lookalike, record-pattern, and extension-type ProviderScope roots fail while genuine controls pass.
- Proved the unchanged production tree passes Flutter analysis, import_lint, the repository layer scanner, and the owned provider-root contract after all negative cases are cleaned.

## Task Commits

1. **Task 1: Trace a forbidden domain package import with reversible cleanup** — `6f9e546d` (feat)
2. **Task 2: Expand fail-first proof to source scanning and Riverpod roots** — `19d587f9` (fix), superseded onto the current analyzer/import_lint graph by `55c70b7e` (refactor)
3. **Provider-root false-green hardening** — `52a807d2`, `d6832c53`, `4440298a`, `3d2abfc9`, `6e2eee6f` (fix)

## Files Created/Modified

- `scripts/verify_tooling_guards.dart` — sequential exact-sentinel harness, diagnostic/path matching, cleanup, and valid-tree checks.
- `test/architecture/tooling_guard_negative_fixture_test.dart` — hermetic negative/control, stale-file, cleanup, and protocol-failure coverage.
- `scripts/audit/provider_contract.dart` — fail-closed Riverpod app-root identity contract used as defense in depth.
- `test/architecture/provider_contract_test.dart` — parser and identity-shadow regression coverage.
- `analysis_options.yaml` — current import_lint and riverpod_lint analysis-server plugin configuration.

## Decisions Made

- Preserve the repository's current coherent analyzer 12 graph and validate the plan's architectural intent against it instead of restoring the obsolete analyzer 8/custom_lint implementation detail.
- Keep the owned provider-root scanner alongside active riverpod_lint because the independent bad/control path detects plugin drift and shadowing false greens.

## Deviations from Plan

### Pre-existing Superseding Implementation

**1. Analyzer/lint graph advanced after the original 58-01 plan was written**
- **Found during:** Safe-resume close-out
- **Issue:** The plan named analyzer 8, custom_lint/import_guard, and riverpod_lint 3.1.0. The current committed compatibility source of truth selects analyzer 12.1.0, import_lint 2.0.0, and active riverpod_lint 3.1.4.
- **Resolution:** Preserved the current user-owned graph and verified the same D-04/GEN-02 behavior through its actual enforcement tools. No package downgrade, ignore, deny-rule weakening, or production-source change was made.
- **Verification:** All 10 targeted fixture tests and all 18 live harness cases passed; `git diff --check` passed and no `*phase58*fixture*.dart` remained.
- **Relevant commits:** `19d587f9`, `55c70b7e`, plus the five provider-contract hardening commits listed above.

**Total deviations:** 1 pre-existing superseding implementation reconciled during manual recovery. **Impact:** The plan's security and architecture intent is preserved on a newer coherent graph; obsolete literal version instructions were not re-applied.

## Issues Encountered

Flutter test startup required SDK-cache writes outside the workspace sandbox. The required verification was rerun with local execution permission and passed.

The safe-resume gate correctly halted because `6f9e546d` existed without this SUMMARY. The user selected manual close-out, preventing duplicate execution of Task 1.

## User Setup Required

None.

## Next Phase Readiness

Wave 0 is structurally closed. Plan 58-02 must validate the current analyzer 12/import_lint/Riverpod cohort and must not restore the obsolete analyzer 8 graph.

## Self-Check: PASSED

Confirmed the four key created artifacts exist, all listed commits are present, the targeted suite passed 10/10, the live harness passed 18/18, and no temporary fixture remains.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-08*
