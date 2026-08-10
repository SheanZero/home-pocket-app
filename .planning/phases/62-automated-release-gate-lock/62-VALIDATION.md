---
phase: 62
slug: automated-release-gate-lock
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-10
---

# Phase 62 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` and SDK `integration_test`; Flutter 3.44.8 / Dart 3.12.2 |
| **Config file** | none — Flutter project defaults |
| **Quick run command** | `flutter test test/scripts/release_gate_test.dart test/architecture/release_gate_ci_contract_test.dart -r expanded` |
| **Full suite command** | `flutter test -r expanded`; use `flutter test --concurrency=1 -r expanded` for the required timeout-recovery confirmation |
| **Estimated runtime** | Targeted tests: under 2 minutes; full suite/device gate: measured and recorded by the release-lock runner |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted release-gate or CI-contract test command
- **After every plan wave:** Run `flutter analyze` and `flutter test -r expanded`
- **Before `$gsd-verify-work`:** The single release-lock entrypoint and its candidate/drift proof must be green
- **Max feedback latency:** 120 seconds for unit/architecture task sampling; platform stages report their measured duration

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-01-01 | 01 | 0 | QA-01, QA-02 | T-62-W0-01, T-62-W0-03 | Temporary-Git/process fixtures are trustworthy and the production behavior contract starts RED | test infrastructure | `flutter test test/scripts/release_gate_test.dart -r expanded` (expected RED until 62-03) | planned by 62-01 | ⬜ pending |
| 62-01-02 | 01 | 0 | QA-03, QA-04 | T-62-W0-02 | One-authority/CI/report contract exists before workflow implementation | architecture | `flutter test test/architecture/release_gate_ci_contract_test.dart -r expanded` (expected RED until 62-08) | planned by 62-01 | ⬜ pending |
| 62-02-01 | 02 | 1 | QA-04 | T-62-D02 | Report lifecycle cannot be inferred | checkpoint:decision | N/A — blocking RPT owner checkpoint | summary planned | ⬜ pending |
| 62-02-02 | 02 | 1 | QA-03 | T-62-D01 | Required Apple-Silicon topology has an authorized owner | checkpoint:decision | N/A — blocking CI owner checkpoint | summary planned | ⬜ pending |
| 62-02-03 | 02 | 1 | QA-03, QA-04 | T-62-D03 | JDK/signing-path ownership and evidence claim are explicit | checkpoint:decision | N/A — blocking SIGN owner checkpoint | summary planned | ⬜ pending |
| 62-03-01 | 03 | 2 | QA-01, QA-03 | T-62-01..06 | Clean candidate traverses the real prerequisite/evidence tracer | unit + tracer | `flutter test test/scripts/release_gate_test.dart -r expanded` | W0 dependency | ⬜ pending |
| 62-03-02 | 03 | 2 | QA-01 | T-62-01..06 | Candidate mutation and final drift fail closed under selected RPT lifecycle | unit | `flutter test test/scripts/release_gate_test.dart -r expanded` | W0 dependency | ⬜ pending |
| 62-04-01 | 04 | 3 | QA-01, QA-02 | T-62-07..12 | Retry/resume classification is closed and candidate-bound | unit | `flutter test test/scripts/release_gate_test.dart -r expanded` | W0 dependency | ⬜ pending |
| 62-04-02 | 04 | 3 | QA-02 | T-62-10..12 | Timeout recovery still requires complete serial suite and coverage | unit + script | `flutter test test/scripts/release_gate_test.dart test/scripts/coverage_gate_test.dart -r expanded` | W0 dependency + existing | ⬜ pending |
| 62-05-01 | 05 | 4 | QA-03, QA-04 | T-62-13..18 | Android evidence is current-candidate and follows selected SIGN claim | unit + architecture | `flutter test test/scripts/android_safety_lane_test.dart test/architecture/android_toolchain_contract_test.dart -r expanded` | existing | ⬜ pending |
| 62-05-02 | 05 | 4 | QA-03, QA-04 | T-62-16..18 | Local arm64 is mandatory; x86 stays supplemental; post-test hygiene blocks | unit + architecture | `flutter test test/scripts/android_safety_lane_test.dart test/architecture/android_toolchain_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/release_preflight_test.dart -r expanded` | existing | ⬜ pending |
| 62-06-01 | 06 | 4 | QA-04 | T-62-19..24 | Only an erased redacted Simulator can enter the iOS result | unit + architecture | `flutter test test/scripts/release_gate_ios_test.dart test/architecture/release_gate_ios_contract_test.dart -r expanded` | planned by 62-06 | ⬜ pending |
| 62-06-02 | 06 | 4 | QA-03, QA-04 | T-62-22..24 | Recursive iOS execution and post-test release hygiene are mandatory | unit + architecture | `flutter test test/scripts/release_gate_ios_test.dart test/architecture/release_gate_ios_contract_test.dart test/scripts/release_preflight_test.dart -r expanded` | planned by 62-06 + existing | ⬜ pending |
| 62-07-01 | 07 | 5 | QA-02, QA-03, QA-04 | T-62-25..30 | Shared discovery/skip accounting cannot omit a platform row | unit + script | `flutter test test/scripts/release_gate_test.dart test/scripts/android_safety_lane_test.dart test/scripts/release_gate_ios_test.dart test/scripts/release_preflight_test.dart -r expanded` | W0 dependency + planned | ⬜ pending |
| 62-07-02 | 07 | 5 | QA-04 | T-62-25..30 | Verdict, privacy, fix ledger, and renderer fail closed | unit + architecture | `flutter test test/scripts/release_gate_test.dart test/architecture/production_logging_privacy_test.dart -r expanded` | W0 dependency + existing | ⬜ pending |
| 62-08-01 | 08 | 6 | QA-03 | T-62-31..36 | Selected CI-A/CI-B route calls one authority and x86 cannot substitute | architecture | `flutter test test/architecture/release_gate_ci_contract_test.dart test/architecture/codegen_reproducibility_contract_test.dart test/architecture/device_e2e_contract_test.dart -r expanded` | W0 dependency + existing | ⬜ pending |
| 62-08-02 | 08 | 6 | QA-03, QA-04 | T-62-34..36 | Selected RPT lifecycle preserves tested candidate/report binding | architecture + unit | `flutter test test/architecture/release_gate_ci_contract_test.dart test/scripts/release_gate_test.dart -r expanded` | W0 dependency | ⬜ pending |
| 62-09-01 | 09 | 7 | QA-01..QA-04 | T-62-37..42 | Exact clean candidate completes every mandatory automated gate | end-to-end | `dart run scripts/release_gate.dart --scope=full --result=build/release_gate/final.json` | planned by 62-03..08 | ⬜ pending |
| 62-09-02 | 09 | 7 | QA-01..QA-04 | T-62-39..41 | Selected publication plus validation remain candidate-bound/privacy-safe | end-to-end + architecture | selected publish command, targeted tests, `flutter analyze`, API precheck, `git diff --check` | planned by 62-08 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scripts/release_gate_test.dart` — created by Plan 62-01 Task 1 before production; covers candidate fingerprint, stage ordering, retry eligibility and limit, resume invalidation, discovery/execution coverage, skip allowlist, verdict, JSON schema, and privacy-filter mutations
- [ ] `test/architecture/release_gate_ci_contract_test.dart` — created by Plan 62-01 Task 2 before workflow/report implementation; covers one entrypoint, PR versus `main` routing, selected topology, Flutter/lock alignment, selected report lifecycle, and supplemental-lane classification
- [ ] `test/helpers/release_gate_test_support.dart` — created by Plan 62-01 Task 1 with temporary-Git and synthetic normalized-command-result fixtures; no unit test boots emulators

Plan 62-01 is the only Wave 0 writer. Plans 62-03 and 62-08 explicitly depend on it (directly or through the decision gate) and extend these seams rather than creating them. The Wave 0 production-facing assertions intentionally start RED; Plan 62-03 must turn the behavior seam green, and Plan 62-08 must turn the CI contract green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Local Android primary acceptance | QA-04 | Local JDK 17 and SDK/device readiness are environmental prerequisites | Install/activate JDK 17, cold-boot the API 36 arm64-v8a AVD with snapshots disabled, then run the repository-owned release-lock entrypoint and retain its redacted evidence |
| Candidate-bound iOS Simulator integration suite | QA-04 | Simulator boot and device execution are platform operations | Erase app/test data, cold-boot the selected Simulator, run the same release-lock entrypoint, and verify the JSON evidence binds the result to the candidate commit and digests |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 executed and covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is recorded and targeted checks remain under 120 seconds
- [x] `nyquist_compliant: true` set because the plan provides continuous automated sampling and explicit Wave 0 dependencies
- [ ] `wave_0_complete: true` remains forbidden until Plan 62-01 executes and all three Wave 0 files exist

**Approval:** pending
