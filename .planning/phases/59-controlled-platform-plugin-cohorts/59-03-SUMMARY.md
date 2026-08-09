---
phase: 59-controlled-platform-plugin-cohorts
plan: "03"
subsystem: platform-plugin-compatibility
tags: [flutter, speech-to-text, ios, privacy, trilingual, safe-hold]
requires:
  - phase: 59-02
    provides: Fail-closed plugin evidence contract and Phase 59 acceptance ledger
provides:
  - Binary, evidence-gated speech candidate decision contract
  - Exact 7.3.0 speech_to_text hold with redacted per-scenario native exit conditions
  - Automated adapter, privacy fallback, and ja/zh/en corpus proof on the held graph
affects: [59-04, 59-05, 59-06, 59-07, 62-automated-release-gate-lock, 63-isolated-wired-iphone-acceptance]
tech-stack:
  added: []
  patterns: [binary candidate-or-hold contract, caller-owned recognition fallback, redacted native evidence ledger]
key-files:
  created: [.planning/phases/59-controlled-platform-plugin-cohorts/59-03-SUMMARY.md]
  modified: [docs/testing/STABLE_BASELINE.json, docs/testing/DEPENDENCY_COMPATIBILITY.md, scripts/dependency_compatibility.dart, test/architecture/dependency_compatibility_contract_test.dart, .planning/phases/59-controlled-platform-plugin-cohorts/59-PLUGIN-ACCEPTANCE.md]
decisions:
  - "Keep speech_to_text exactly at 7.3.0: 7.4.0 is eligible but cannot be selected without complete native-build and physical-iPhone evidence."
  - "Require every accepted speech candidate to have PASS evidence for automated proof, native build, iPhone permission, ja/zh/en recognition, cancellation, surfaced error, on-device recognition, and both fallback branches."
requirements-completed: [PLUG-01, PLUG-03]
metrics:
  duration: 7min
  completed: 2026-08-09
status: complete
actuals:
  tokens: 3811
  tasks: 3
  commits: 3
coverage:
  - id: D1
    description: Binary speech candidate-or-hold contract rejects prereleases, incomplete native evidence, failed locales, and accepted graph mismatches.
    requirement: PLUG-01
    verification:
      - kind: unit
        ref: "flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-03'"
        status: pass
    human_judgment: false
  - id: D2
    description: Existing centralized adapter retains one retry maximum, caller-controlled no-fallback behavior, cancellation/restart semantics, and ja/zh/en parsing coverage on the held graph.
    requirement: PLUG-03
    verification:
      - kind: integration
        ref: "speech_recognition_service + ondevice + ja/zh/en corpus matrix"
        status: pass
    human_judgment: false
  - id: D3
    description: Exact 7.3.0 hold documents every unavailable native scenario with its redacted, attributable exit condition.
    requirement: PLUG-03
    verification:
      - kind: other
        ref: "dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk"
        status: pass
    human_judgment: false
---

# Phase 59 Plan 03: Speech Adapter Candidate Hold Summary

**A binary evidence contract retains `speech_to_text` 7.3.0 while proving the centralized, trilingual adapter and caller-owned fallback behavior on the selected graph.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-09T00:26:13Z
- **Completed:** 2026-08-09T00:32:41Z
- **Tasks:** 3/3
- **Files modified:** 5

## Accomplishments

- Added RED/GREEN contract coverage that makes an accepted speech candidate impossible without complete PASS evidence and matching declaration/lock versions.
- Rechecked the official package source: `7.4.0` is stable and `7.5.0-beta.1` is ineligible; the selected declaration and lock remain exactly `7.3.0`.
- Passed the current adapter, one-retry/no-retry, restart/cancel, ja/zh/en corpus, and dependency-baseline checks without adding a direct plugin call or changing permissions, native files, or caller signatures.
- Recorded redacted `UNAVAILABLE` rows for native build, permission, ja/zh/en recognition, cancellation, error, on-device recognition, and both fallback outcomes. No physical-iPhone observation was claimed.

## Task Commits

1. **Task 1: Refresh and lock the two-terminal-state speech decision** — `0bf794a3` (RED), `308fa2c0` (GREEN)
2. **Task 2: Evaluate the candidate behind the single adapter and complete automated trilingual proof** — no source commit; required candidate prerequisites were unavailable, so the exact selected graph was intentionally left unchanged after verification.
3. **Task 3: Record physical-iPhone evidence or retain exact 7.3.0** — `24866a98`

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-03'` — passed (6 tests).
- Speech adapter/on-device plus ja/zh/en corpus and dependency contract matrix — passed (187 tests).
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed (0 errors, 0 warnings).
- Production source scan — exactly one `_speech.listen` call, in `SpeechRecognitionService`.
- `flutter analyze` — ran; it reports the 289 pre-existing unrelated `prefer_initializing_formals` information diagnostics already recorded by 59-02. No scoped analyzer diagnostic was introduced.

## Decisions Made

- Retain the exact `speech_to_text 7.3.0` declaration and resolution; do not stage or resolve `7.4.0` without a complete, attributable candidate evaluation.
- Treat any missing, unavailable, failed, or partial native evidence as a hold; a candidate/version match alone never counts as acceptance.
- Preserve the caller-controlled `allowOnDeviceFallback` policy and the single adapter boundary; no transcript, device identifier, production credential, or native observation was recorded.

## Deviations from Plan

None - plan executed exactly as written. The plan explicitly requires the exact hold when native candidate prerequisites or physical-iPhone evidence are unavailable.

## Issues Encountered

- `flutter analyze` continues to report 289 unrelated informational diagnostics. This pre-existing debt was documented by 59-02 and was not changed in this scoped compatibility lane.

## Known Holds

- `speech_to_text 7.4.0` remains unselected. It requires a pre-authorized non-production candidate identity and complete redacted PASS evidence for supported build, physical-iPhone permission, ja/zh/en recognition, cancellation, error, fresh on-device recognition, and allowed/disallowed fallback behavior.
- The Phase 63 isolated wired-iPhone UAT lane was not used and is not substituted for this Phase 59 candidate decision.

## Next Phase Readiness

Later plugin cohorts inherit the binary terminal-state contract and the redacted evidence pattern. A future speech candidate attempt must start from the exact hold, preserve the centralized adapter, and meet every native evidence gate before changing Pub inputs.

## Self-Check: PASSED

- All planned contract, adapter, test, baseline, evidence, and summary files exist.
- Commits `0bf794a3`, `308fa2c0`, and `24866a98` exist in repository history.
