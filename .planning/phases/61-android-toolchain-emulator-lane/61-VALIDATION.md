---
phase: 61
slug: android-toolchain-emulator-lane
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-09
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test + Dart process fixtures + real Gradle/Android SDK tools |
| **Config file** | `pubspec.yaml`, `dart_test.yaml`, `android/gradle.properties` |
| **Quick run command** | `flutter test test/architecture/android_toolchain_contract_test.dart test/scripts/android_safety_lane_test.dart` |
| **Full focused command** | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/android_toolchain_contract_test.dart test/architecture/android_release_signing_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/android_safety_lane_test.dart test/scripts/release_preflight_test.dart` |
| **Estimated runtime** | quick ~30 seconds; focused ~90 seconds; package/Emulator lanes are separately sampled expensive evidence |

## Sampling Rate

- **After every task commit:** Run the task's targeted Flutter test or lane-verifier command.
- **After every plan wave:** Run the full focused command above.
- **Before phase verification:** Focused suite, `flutter analyze`, `git diff --check`, candidate/hold evidence validator, real signed-package evidence, and local API 36 `google_apis` `arm64-v8a` primary Emulator evidence must be green. API 36 `x86_64` GitHub/Intel remains supplemental.
- **Max fast-feedback latency:** 90 seconds. Candidate, packaging, and Emulator tasks are explicitly expensive gates and preserve intermediate evidence/diagnostics.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | AND-01, AND-02 | T-61-01-01/02 | Reject stale, partial, or mixed toolchain states | architecture/mutation | `flutter test test/architecture/android_toolchain_contract_test.dart` | ❌ W0 | ⬜ pending |
| 61-01-02 | 01 | 1 | AND-01, AND-02 | T-61-01-03/04 | Parse only exact redacted candidate/hold evidence | script fixture | `flutter test test/scripts/android_safety_lane_test.dart` | ❌ W0 | ⬜ pending |
| 61-02-01 | 02 | 2 | AND-01, AND-02 | T-61-02-01/02 | Candidate changes cannot escape disposable workspace | script fixture + real probe | `dart run scripts/verify_android_safety_lane.dart --mode=candidate-probe` | ❌ W0 | ⬜ pending |
| 61-02-02 | 02 | 2 | AND-01, AND-02 | T-61-02-03/04 | Exact hold has attributable blocker and exit condition | architecture + validator | `dart run scripts/verify_android_safety_lane.dart --mode=verify` | ❌ W0 | ⬜ pending |
| 61-03-01 | 03 | 3 | AND-01, AND-02 | T-61-03-01/02 | Main graph is exact hold or fully selected; minSdk/JDK remain fixed | architecture/mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/android_toolchain_contract_test.dart` | partial | ⬜ pending |
| 61-03-02 | 03 | 3 | AND-04 | T-61-03-03/04 | CI declares API 36 x86_64 GitHub/Intel supplemental full-suite lane | architecture | `flutter test test/architecture/device_e2e_contract_test.dart` | ✅ | ⬜ pending |
| 61-04-01 | 04 | 4 | AND-03 | T-61-04-01/02/03 | Missing/debug signing fails; evidence private key stays disposable | fixture + real Gradle | `flutter test test/architecture/android_release_signing_contract_test.dart test/scripts/android_safety_lane_test.dart` | partial | ⬜ pending |
| 61-04-02 | 04 | 4 | AND-03 | T-61-04-04/05 | Both signed artifacts exist and contain no test plugin | real package + scan | `dart run scripts/verify_android_safety_lane.dart --mode=release` | ❌ W0 | ⬜ pending |
| 61-05-01 | 05 | 5 | AND-04 | T-61-05-01/02 | Only clean local API 36 `google_apis` `arm64-v8a` primary boot can enter runtime evidence | fixture + real Emulator | `dart run scripts/verify_android_safety_lane.dart --mode=emulator --prepare-only` | ❌ W0 | ⬜ pending |
| 61-05-02 | 05 | 5 | AND-03, AND-04 | T-61-05-03/04/05 | Full integration matrix passes; post-test release hygiene is clean | real Emulator + package scan | `dart run scripts/verify_android_safety_lane.dart --mode=emulator` | ❌ W0 | ⬜ pending |
| 61-06-01 | 06 | 6 | AND-01..04 | T-61-06-01/02 | Evidence provenance is complete and redacted | validator + focused suite | `dart run scripts/verify_android_safety_lane.dart --mode=verify` | ❌ W0 | ⬜ pending |
| 61-06-02 | 06 | 6 | AND-01..04 | T-61-06-03/04 | Phase claims exactly the evidence produced | analyzer + focused suite | `flutter analyze && flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/android_toolchain_contract_test.dart test/architecture/android_release_signing_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/android_safety_lane_test.dart test/scripts/release_preflight_test.dart` | partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `test/architecture/android_toolchain_contract_test.dart` — terminal selected/hold, minSdk/JDK, candidate provenance, and legacy-KGP mutation contracts.
- [ ] `test/scripts/android_safety_lane_test.dart` — disposable-workspace, redaction, evidence-schema, signature, artifact-hygiene, Emulator-identity, and complete-matrix fixtures.
- [ ] `scripts/verify_android_safety_lane.dart` — mode scaffold consumed by every expensive Phase 61 gate.

Existing Flutter/Dart test infrastructure covers the framework; no dependency install is required.

## Manual-Only Verifications

None. The candidate decision, signing, packaged artifact hygiene, local arm64-v8a primary Emulator runtime, and explicit absent physical-device result all have automated evidence producers. API 36 x86_64 GitHub/Intel execution remains a supplemental limitation when unavailable or failed; it is neither a pass nor a primary blocker, and human judgment cannot substitute the required local arm64 primary evidence.

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Wave 0 covers every missing test/runner reference.
- [x] No watch-mode flags.
- [x] Fast feedback target is under 90 seconds; expensive native gates are explicit.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-08-09 for execution; remains `draft` until validate-phase lifecycle promotion.
