---
phase: 62-automated-release-gate-lock
plan: 08
subsystem: release-gate-ci
tags: [github-actions, apple-silicon, release-gate, attestation, rpt-a]
requires:
  - phase: 62-02
    provides: Owner-authorized CI-A and RPT-A decisions
  - phase: 62-07
    provides: Candidate-bound release-gate JSON authority and deterministic renderer
provides:
  - PR host and main Apple-Silicon CI routing through release_gate.dart
  - Explicit supplemental x86 evidence with a reviewable normalized outcome artifact
  - RPT-A report-only candidate attestation publication and checked-in report surface
affects: [62-09, phase-63, release-process]
actuals:
  tokens: 22696
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - CI-A full scope runs only on the release-owner-authorized Apple-Silicon label set.
    - RPT-A resolves the latest positive candidate-scope commit and permits only the compatibility report as a successor mutation.
key-files:
  created:
    - docs/testing/RELEASE_COMPATIBILITY.md
  modified:
    - .github/workflows/audit.yml
    - .github/workflows/device-e2e.yml
    - scripts/release_gate.dart
    - scripts/release_gate/report.dart
    - test/architecture/release_gate_ci_contract_test.dart
decisions:
  - "Use CI-A exact labels self-hosted, macOS, ARM64, happy-pocket-release; unavailable Apple-Silicon capacity remains a failing or pending mandatory result."
  - "Use RPT-A publication only with an explicit --publish-report command against validated green JSON bound to the immutable tested candidate."
metrics:
  duration: 9min
  completed: 2026-08-10
status: complete
requirements-completed: [QA-01, QA-02, QA-03, QA-04]
coverage:
  - id: D1
    description: "PR host and every-main CI-A release-gate routing, exact labels, and supplemental x86 classification are mutation-tested."
    requirement: QA-03
    verification:
      - kind: unit
        ref: "flutter test test/architecture/release_gate_ci_contract_test.dart test/architecture/codegen_reproducibility_contract_test.dart test/architecture/device_e2e_contract_test.dart -r expanded"
        status: pass
    human_judgment: false
  - id: D2
    description: "RPT-A candidate-scope resolution, validated JSON publication boundary, and report rendering are covered by release-gate contracts."
    requirement: QA-04
    verification:
      - kind: unit
        ref: "flutter test test/architecture/release_gate_ci_contract_test.dart test/scripts/release_gate_test.dart -r expanded"
        status: pass
    human_judgment: false
---

# Phase 62 Plan 08: CI Authority and Report Attestation Summary

**CI-A now routes every `main` merge through the mandatory labeled Apple-Silicon release gate, while RPT-A publishes only a candidate-bound metadata report successor.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-10T14:20:02+09:00
- **Completed:** 2026-08-10T14:29:00+09:00
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Replaced competing PR/main verdict graphs with `release_gate.dart --scope=host` on PRs and CI-A `--scope=full` on the exact authorized Apple-Silicon runner labels.
- Kept the API 36 GitHub/Intel x86_64 lane independently executable but non-blocking, with an always-uploaded normalized supplemental outcome artifact.
- Added a fail-closed RPT-A publication command that checks validated green JSON, tested candidate identity, exact report-only mutation scope, and idempotent successor verification.

## Task Commits

1. **Task 1: Route PR and main CI through one authority and demote x86 to supplemental** — `d754dd0d` (RED), `2742948a` (GREEN)
2. **Task 2: Implement the immutable-candidate report attestation lifecycle** — `783f9b3f` (RED), `31870541` (GREEN)

## Files Created/Modified

- `.github/workflows/audit.yml` — PR host authority plus non-authoritative audit artifact collection.
- `.github/workflows/device-e2e.yml` — fail-closed CI-A full gate and supplemental x86 outcome artifact.
- `scripts/release_gate.dart` — RPT-A positive candidate scope, report publication option, validated result parser, and exact mutation proof.
- `scripts/release_gate/report.dart` — deterministic command, environment-boundary, delta, hold, and fix sections.
- `docs/testing/RELEASE_COMPATIBILITY.md` — honest pre-publication report surface; it does not claim a runner is online or a candidate has passed.
- `test/architecture/release_gate_ci_contract_test.dart` — CI-A, supplemental, one-authority, and RPT-A regression coverage.

## Decisions Made

- CI-A is configuration only until a live attributed run exists; missing or offline capacity cannot become an x86-derived pass.
- Report publication is explicit and idempotent, so later `main` verification does not create a report-commit loop.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made workflow contract tests follow the single full-gate topology**
- **Found during:** Task 1
- **Issue:** The existing device workflow test still required separately declared iOS commands after CI-A intentionally moved that work inside `release_gate.dart`.
- **Fix:** Updated the contract to assert the CI-A full authority and retain the x86 lane checks.
- **Files modified:** `test/architecture/device_e2e_contract_test.dart`
- **Verification:** Plan-wide CI contract command passed.
- **Committed in:** `2742948a`

**2. [Rule 1 - Bug] Supplied default result paths for the plan-authorized CI commands**
- **Found during:** Task 2
- **Issue:** The specified `--scope=host` and `--scope=full` workflow commands omitted a required `--result` argument and would have exited before executing the authority.
- **Fix:** Added scope-derived ignored result defaults while preserving explicit-path validation for publication.
- **Files modified:** `scripts/release_gate.dart`
- **Verification:** Targeted release-gate tests and analyzer passed.
- **Committed in:** `31870541`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs).
**Impact on plan:** Both changes align existing tests and CLI behavior with the owner-authorized CI-A/RPT-A contract; no product or runtime behavior changed.

## Issues Encountered

- Flutter test and analyzer commands needed permission to refresh the external Flutter SDK cache; after the refresh, all scoped checks completed successfully.

## User Setup Required

The release owner must register and keep available the authorized CI-A runner labels (`self-hosted`, `macOS`, `ARM64`, `happy-pocket-release`) before the workflow can produce runtime evidence. This plan does not claim that the runner is currently online.

## Next Phase Readiness

Plan 62-09 can run the full candidate gate, then publish the report with `--publish-report --result=build/release_gate/final.json`. Android physical-device validation remains not performed or claimed.

## Verification

- `flutter test test/architecture/release_gate_ci_contract_test.dart test/architecture/codegen_reproducibility_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/release_gate_test.dart -r expanded` — passed (43 tests).
- `flutter analyze` — passed with 0 issues.
- `node /Users/xinz/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/62-automated-release-gate-lock` — passed (reasoned no-external-API declaration).
- `git diff --check` — passed.

## Self-Check: PASSED

- Found `docs/testing/RELEASE_COMPATIBILITY.md`, `scripts/release_gate.dart`, and both updated workflows.
- Found task commits `d754dd0d`, `2742948a`, `783f9b3f`, and `31870541` in Git history.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
