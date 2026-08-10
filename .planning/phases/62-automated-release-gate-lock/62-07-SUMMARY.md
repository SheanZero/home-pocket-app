---
phase: 62-automated-release-gate-lock
plan: 07
subsystem: release-gate
tags: [dart, release-gate, ios, android, privacy, reporting]
requires:
  - phase: 62-04
    provides: Ordered host execution graph and candidate-bound retry contracts
  - phase: 62-05
    provides: Candidate-bound Android arm64 evidence with supplemental x86 boundary
  - phase: 62-06
    provides: Candidate-bound iPhone Simulator integration adapter
provides:
  - One full candidate-bound dual-platform release-gate graph
  - Strict versioned integration skip accounting and post-device hygiene proof
  - Fail-closed three-state verdict, privacy-safe JSON authority, and deterministic Markdown preview
affects: [62-08, 62-09, phase-63]
actuals:
  tokens: 10404
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - One canonical recursive integration inventory is reconciled separately against each platform result
    - The verdict is recomputed from validated evidence and cannot be overridden by persisted fields or CLI input
key-files:
  created:
    - scripts/release_gate/report.dart
    - scripts/release_gate/expected_skips.json
  modified:
    - scripts/release_gate.dart
    - scripts/release_gate/models.dart
    - test/scripts/release_gate_test.dart
key-decisions:
  - "Expected skips are a committed schema-versioned allowlist; an absent manifest or stale path blocks execution."
  - "Only supplemental x86 absence/failure and explicitly accepted historical debt can yield PASS_WITH_LIMITATIONS after every mandatory stage is green."
  - "Markdown is a deterministic privacy-scanned preview of the validated JSON authority and omits raw retry transcripts."
patterns-established:
  - "Platform adapters normalize evidence only; computeVerdict is the sole final release-verdict authority."
requirements-completed: [QA-02, QA-03, QA-04]
coverage:
  - id: D1
    description: Full release-gate orchestration shares one recursive inventory between iOS and Android and blocks incomplete skip accounting.
    requirement: QA-02
    verification:
      - kind: unit
        ref: flutter test test/scripts/release_gate_test.dart test/scripts/android_safety_lane_test.dart test/scripts/release_gate_ios_test.dart test/scripts/release_preflight_test.dart -r expanded
        status: pass
    human_judgment: false
  - id: D2
    description: JSON authority, verdict, privacy scanning, sanitized fix ledger, and deterministic compatibility preview are fail closed.
    requirement: QA-04
    verification:
      - kind: unit
        ref: flutter test test/scripts/release_gate_test.dart test/architecture/production_logging_privacy_test.dart -r expanded
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 07: Aggregate Release-Gate Authority Summary

**A single candidate-bound release gate now reconciles full iOS and Android inventories, blocks unsafe evidence, and renders a deterministic privacy-safe compatibility result.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-10T14:07:28+09:00
- **Completed:** 2026-08-10T14:14:00+09:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `--scope=full` orchestration: prerequisites, host/coverage stages, candidate-bound iOS and Android adapters, final cross-platform preflight, and terminal drift proof.
- Added an explicit empty expected-skip manifest plus strict recursive path/schema/set-equality validation for every accepted non-execution.
- Added the authoritative report contract: exhaustive verdict calculation, privacy/schema validation before either artifact write, bounded sanitized fix records, and fixed-order Markdown preview.

## Task Commits

1. **Task 1: Converge both platforms under exact discovery and skip accounting** — `7d702bbd` (RED), `43b0a91f` (GREEN)
2. **Task 2: Lock verdict, privacy, failure-fix history, and deterministic rendering** — `523411c0` (RED), `f03c0b83` (GREEN), `4d64620a` (follow-up fix)

## Files Created/Modified

- `scripts/release_gate.dart` — full graph orchestration, strict manifest loading, platform evidence normalization, and safe fix-record CLI operation.
- `scripts/release_gate/models.dart` — skip-accounting, limitations, failure-fix, and extended result contracts.
- `scripts/release_gate/report.dart` — schema/privacy validation, sole verdict computation, ledger persistence, and deterministic Markdown renderer.
- `scripts/release_gate/expected_skips.json` — committed versioned empty allowlist.
- `test/scripts/release_gate_test.dart` — full graph, skip mutation, verdict, privacy, and renderer regressions.

## Decisions Made

- A shared allowlist cannot silently excuse Android work: until that adapter explicitly accepts skip records, a nonempty manifest blocks its aggregate stage.
- Manual overrides, unclassified limitations, malformed evidence, and any non-green mandatory stage always compute `BLOCKED`.
- Android physical-device validation remains explicitly unperformed and unclaimed in the rendered report.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored analyzer-compliant fix-record argument validation**
- **Found during:** Task 2 final verification
- **Issue:** Newly added single-line validation branches violated the repository analyzer’s required brace style.
- **Fix:** Wrapped the branches in braces and normalized the related mutation-test formatting.
- **Files modified:** `scripts/release_gate.dart`, `test/scripts/release_gate_test.dart`
- **Verification:** Focused release-gate tests and `flutter analyze` passed with 0 issues.
- **Committed in:** `4d64620a`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** The correction is scoped to the new fix-ledger argument path and preserves the project’s zero-issue analyzer gate.

## Issues Encountered

- Flutter needed its external SDK cache refreshed before targeted verification; elevated test execution completed without changing repository source outside this plan.

## Known Stubs

None — the committed empty skip list is an explicit valid allowlist, not an implicit placeholder, and all unavailable mandatory evidence computes `BLOCKED`.

## User Setup Required

None - no external service configuration required. The actual full device command still requires the planned local Simulator and API 36 arm64 Emulator prerequisites; missing prerequisites are reported as blocked evidence.

## Next Phase Readiness

Plans 62-08 and 62-09 can consume one candidate-bound result with strict dual-platform accounting, three-state verdict semantics, and a privacy-safe deterministic report surface.

## Verification

- `flutter test test/scripts/release_gate_test.dart test/scripts/android_safety_lane_test.dart test/scripts/release_gate_ios_test.dart test/scripts/release_preflight_test.dart test/architecture/production_logging_privacy_test.dart -r expanded` — passed (69 tests).
- `dart format --output=none --set-exit-if-changed scripts/release_gate.dart scripts/release_gate test/scripts/release_gate_test.dart` — passed.
- `flutter analyze` — passed with 0 issues.
- `git diff --check` — passed.

## Self-Check: PASSED

- Confirmed `scripts/release_gate/report.dart` and `scripts/release_gate/expected_skips.json` exist.
- Confirmed task commits `7d702bbd`, `43b0a91f`, `523411c0`, `f03c0b83`, and `4d64620a` exist in Git history.
