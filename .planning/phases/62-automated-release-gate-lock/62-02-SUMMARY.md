---
phase: 62-automated-release-gate-lock
plan: 02
subsystem: release-gate-governance
tags: [release-gate, candidate-attestation, github-actions, apple-silicon, android-signing]
requires:
  - phase: 62-01
    provides: Release-gate contract seams and CI RED contracts
provides:
  - Owner-authorized RPT-A candidate/report lifecycle
  - Owner-authorized CI-A Apple-Silicon main-merge topology
  - Owner-authorized SIGN-A Phase 61 signing-path repair scope
affects: [62-03, 62-05, 62-08, 62-09]
tech-stack:
  added: []
  patterns:
    - Candidate C remains immutable; a report is committed only as its bound metadata-only successor.
    - Mandatory Apple-Silicon CI is authorization/configuration until attributable runtime evidence proves availability.
    - JDK selection and signing-evidence activation are independently controlled and mutation-tested.
key-files:
  created:
    - .planning/phases/62-automated-release-gate-lock/62-02-SUMMARY.md
  modified: []
decisions:
  - RPT-A: attest an immutable candidate C with exactly one candidate-bound metadata-only report successor.
  - CI-A: require an owner-operated, labeled GitHub self-hosted Apple-Silicon runner after every main merge; fail closed if unavailable.
  - SIGN-A: Phase 62 repairs the Phase 61 JDK/signing switch seam and may claim only the exercised current-candidate release path.
metrics:
  duration: 3min
  completed: 2026-08-10
status: complete
actuals:
  tokens: 1826
  tasks: 3
  commits: 2
---

# Phase 62 Plan 02: Release Owner Decision Ledger Summary

**Release owner selected the candidate-attestation lifecycle, an owner-operated Apple-Silicon merge gate, and a scoped current-candidate signing-path repair.**

## Accomplishments

- Closed all three decision-gated research questions before dependent release-gate implementation begins.
- Preserved immutable-candidate proof while allowing the concise checked-in compatibility report required by QA-04.
- Defined the required CI topology without treating runner authorization as evidence that infrastructure is registered or online.
- Assigned the Phase 61 JDK/signing ambiguity to Phase 62 with a narrow, non-historical evidence claim.

## Owner Decisions

### RPT-A — Attestation successor

**Selection:** The formal release gate proves immutable, clean candidate **C**. The authoritative JSON evidence remains outside Git. After that proof, exactly one metadata-only successor may update the checked-in compatibility report, and that report must explicitly bind to C.

**Candidate-scope rule:** Any source or configuration change is not metadata-only and therefore selects a new candidate; it must receive a complete fresh candidate-bound gate run. Dependent plans must distinguish the tested parent candidate C from the report-attestation commit with an exact positive scope contract.

**Rationale:** This reconciles D-02/D-04 clean immutable-candidate proof with D-13/D-14 checked-in, final-result-oriented compatibility reporting without permitting a broad report-generation drift exception.

### CI-A — GitHub self-hosted Apple-Silicon runner

**Selection:** Every merge to `main` must run the Phase 62 full release gate on an owner-operated GitHub self-hosted Apple-Silicon runner.

**Authorized configuration:**

- **Exact labels:** `self-hosted`, `macOS`, `ARM64`, `happy-pocket-release`
- **Owner:** repository release owner
- **Authorization:** repository code execution on this owner-operated host is authorized for the Phase 62 full release gate.
- **Failure behavior:** the workflow must fail closed if this labeled runner or its required result is unavailable.
- **Supplemental lane:** API 36 `x86_64` GitHub/Intel evidence remains supplemental only; it cannot satisfy the required Apple-Silicon result and does not become a pass by its absence or failure.

**Evidence boundary:** This decision authorizes the future workflow configuration. It does **not** claim the self-hosted runner is registered, reachable, online, or has produced a passing result. Those facts require attributable runtime evidence from the implemented gate.

### SIGN-A — Repair in Phase 62

**Selection:** Phase 62 implementation and the repository release owner own the scoped repair to the Phase 61 Android adapter.

**Required repair contract:** Separate `PHASE61_GRADLE_JAVA_HOME` / JDK 17 selection from the explicit signing-evidence switch, and cover their independence with mutation tests. JDK 17 selection remains a mandatory, fail-closed prerequisite; choosing it must not silently activate special signing-evidence behavior.

**Permitted evidence claim:** The repaired adapter may claim only the current candidate release path it actually exercises with attributable passing evidence. It must never infer or overclaim historical or special signed-package proof without its own attributable passing evidence.

**Rationale:** This retains strict Android release hygiene while correcting the `PHASE61_GRADLE_JAVA_HOME` coupling identified as Phase 61 warning WR-01.

## Files Created/Modified

- `.planning/phases/62-automated-release-gate-lock/62-02-SUMMARY.md` — durable release-owner decision ledger for dependent Phase 62 plans.

## Verification

- Confirmed the ledger records exactly one requested code for each decision: `RPT-A`, `CI-A`, and `SIGN-A`.
- Confirmed none of the selections is `*-HOLD`; dependent implementation may proceed only under the explicit contracts above.
- Confirmed the CI-A record distinguishes owner authorization/configuration from proof that a labeled self-hosted runner is registered, online, or has completed a run.
- Confirmed the SIGN-A claim is limited to an exercised current candidate and does not certify historical/special package evidence.

## Decisions Made

- Use RPT-A: a metadata-only report attestation successor, explicitly bound to immutable tested candidate C.
- Use CI-A: an owner-operated GitHub self-hosted Apple-Silicon runner labeled `self-hosted`, `macOS`, `ARM64`, and `happy-pocket-release` after every merge to `main`, with fail-closed availability/result handling.
- Use SIGN-A: Phase 62 owns the scoped Android adapter repair; JDK 17 selection and signing-evidence activation are separate mutation-tested controls.

## Deviations from Plan

None — the release owner supplied all three requested blocking decisions explicitly, so the decision checkpoints were completed as authorized.

## Issues Encountered

None.

## Known Stubs

None — this plan records decisions only and does not introduce implementation placeholders.

## User Setup Required

No action is required to record these decisions. Subsequent implementation must configure and exercise the authorized CI-A runner; its registration, availability, and passing status remain runtime evidence obligations rather than established facts.

## Next Phase Readiness

Plans 62-03, 62-05, 62-08, and 62-09 may consume this ledger without reopening the decisions. They must enforce the RPT-A candidate-bound report lifecycle, CI-A's fail-closed Apple-Silicon main-merge topology, and SIGN-A's independently controlled JDK/signing path.

## Self-Check: PASSED

- Found `.planning/phases/62-automated-release-gate-lock/62-02-SUMMARY.md`.
- Found task commit `77c691a6` in Git history.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
