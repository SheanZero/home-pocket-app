---
phase: 59-controlled-platform-plugin-cohorts
plan: "01"
subsystem: testing
tags: [flutter, platform-plugins, dependency-contract, native-evidence, api-coverage]
requires:
  - phase: 58-flutter-analyzer-code-generation-lane
    provides: Stable Flutter/analyzer baseline and dependency compatibility validator
provides:
  - Fail-closed Phase 59 platform-plugin inventory and atomic file/share cohort contract
  - Redacted acceptance ledger that records unavailable native evidence as holds
  - API coverage seal and seven-plan Nyquist validation map
affects: [59-02, 59-03, 59-04, 59-05, 59-06, 59-07, 62-automated-release-gate-lock]
actuals:
  tokens: 12330
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns: [fail-closed evidence rows, atomic dependency cohort validation, redacted native-evidence ledger]
key-files:
  created: [.planning/phases/59-controlled-platform-plugin-cohorts/59-PLUGIN-ACCEPTANCE.md]
  modified: [docs/testing/STABLE_BASELINE.json, scripts/dependency_compatibility.dart, test/architecture/dependency_compatibility_contract_test.dart, docs/testing/DEPENDENCY_COMPATIBILITY.md, .planning/phases/59-controlled-platform-plugin-cohorts/59-VALIDATION.md]
key-decisions:
  - "Keep speech_to_text 7.3.0 selected: 7.4.0 is the stable candidate, while 7.5.0-beta.1 is ineligible and absent physical-iPhone evidence is a hold."
  - "Treat file_picker, share_plus, package_info_plus, and transitive win32 as one exact atomic cohort."
  - "Retain candidate-only native plugin decisions until attributable platform evidence exists; no resolver change is implied."
patterns-established:
  - "Phase 59 plugin rows use explicit package identity, official query date, candidate, owner, decision, and hold exit conditions."
  - "Acceptance ledgers record redacted scenario metadata only and never promote unavailable native evidence to acceptance."
requirements-completed: [PLUG-01, PLUG-02, PLUG-03, PLUG-04]
coverage:
  - id: D1
    description: Complete fail-closed Phase 59 platform-plugin inventory and exact file/share cohort validation.
    requirement: PLUG-01
    verification:
      - kind: unit
        ref: flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/lucide_asset_size_test.dart
        status: pass
      - kind: other
        ref: dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
        status: pass
    human_judgment: false
  - id: D2
    description: Redacted native acceptance ledger that holds missing picker, share, speech, notification, biometric, and stored-key evidence.
    requirement: PLUG-02
    verification:
      - kind: other
        ref: node /Users/xinz/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/59-controlled-platform-plugin-cohorts
        status: pass
    human_judgment: true
    rationale: Native device evidence is intentionally unavailable and remains a documented hold for later plans.
duration: 19min
completed: 2026-08-09
status: complete
---

# Phase 59 Plan 01: Controlled Plugin Evidence Substrate Summary

**Fail-closed platform-plugin inventory, atomic file/share drift protection, and redacted native-evidence holds with the speech candidate explicitly kept at 7.3.0.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-08-08T23:49:32Z
- **Completed:** 2026-08-09T00:08:03Z
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Traced the approved `speech_to_text` hold from official candidate evidence through manifest, validator, contract tests, and a redacted ledger.
- Added dated Phase 59 ownership/evidence for all in-scope platform plugins and the transitive `win32` member.
- Made the file/share cohort exact, ordered, and fail-closed for every selected declaration and lock mutation.
- Sealed the 63-capability API matrix and mapped the remaining native holds across the seven-plan validation strategy.

## Task Commits

1. **Task 1: Speech evidence tracer** — `fd7a128f` (test), `d98a9ba5` (feat)
2. **Task 2: Complete platform plugin inventory** — `b59fbf16` (feat)
3. **Task 3: Capability matrix and native-evidence ledger** — `6901566d` (docs)

## Files Created/Modified

- `docs/testing/STABLE_BASELINE.json` — dated decisions, exact Phase 59 inventory, atomic cohort, and transitive evidence.
- `scripts/dependency_compatibility.dart` — deterministic Phase 59 inventory and cohort validation.
- `test/architecture/dependency_compatibility_contract_test.dart` — missing-evidence, membership, ordering, declaration, and lock drift mutations.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — readable official-source and hold policy.
- `59-PLUGIN-ACCEPTANCE.md` — redacted acceptance/hold ledger.
- `59-VALIDATION.md` — completed Wave 0 task statuses and validation map.

## Decisions Made

- User-approved tracer facts are preserved exactly: `speech_to_text` stays at 7.3.0; 7.4.0 is the eligible stable candidate; 7.5.0-beta.1 is excluded; no physical-iPhone evidence is fabricated.
- All unavailable Android, iOS, biometric, and existing-key evidence is a hold with a concrete exit condition.
- SQLCipher/Drift and Android toolchain safety remain explicitly owned by Phases 60 and 61.

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/lucide_asset_size_test.dart` — passed (53 tests)
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed (0 errors, 0 warnings)
- `node /Users/xinz/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/59-controlled-platform-plugin-cohorts` — passed (63 capabilities; 53 integrate, 10 reasoned opt-outs)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test bug] Corrected lock-version mutation expectations**
- **Found during:** Task 2
- **Issue:** The new lock mutation test reused Pub declaration constraints, so its matcher looked for caret-prefixed versions in `pubspec.lock`.
- **Fix:** Split exact selected lock versions from declaration constraints.
- **Files modified:** `test/architecture/dependency_compatibility_contract_test.dart`, `scripts/dependency_compatibility.dart`
- **Verification:** Targeted and plan-level contract runs passed.
- **Committed in:** `b59fbf16`

**Total deviations:** 1 auto-fixed (Rule 1)

## Known Holds

- Physical-iPhone speech permission, recognition, cancellation, error, and caller-controlled fallback evidence remains unavailable; this is a required hold, not acceptance.
- Android JDK/emulator/device, notification lifecycle, biometric UI, and existing-key evidence remain unavailable; each is explicitly represented in the acceptance ledger for the owning later plan.

## Next Phase Readiness

Plans 59-02 through 59-07 can consume the centralized manifest, contract, API matrix, and redacted evidence shape. They must retain the exact holds until their native prerequisites and named acceptance scenarios are complete.

## Self-Check: PASSED

- Summary and all six task deliverables exist.
- Commits `fd7a128f`, `d98a9ba5`, `b59fbf16`, and `6901566d` exist in repository history.
