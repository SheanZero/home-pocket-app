---
phase: 61-android-toolchain-emulator-lane
verified: 2026-08-10T01:16:56Z
status: gaps_found
score: 10/18 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The final ledger is attributable to the current source tree and its release/primary-Emulator acceptance evidence."
    status: failed
    reason: "The machine verifier accepts evidence whose source_commit/package_source_commit is e6b5cbf672e885dcbb4446621cc20e7ca05aa058 while HEAD is ea3f9e988127ac90b1ca4b38e585069cd88fe3fd. The safety verifier itself changed after the recorded runtime/package run, but validateCurrentAndroidSafetyLane neither compares HEAD nor recomputes a scoped input digest."
    artifacts:
      - path: "scripts/verify_android_safety_lane.dart"
        issue: "Current verification checks only syntactic commit hashes and equality between two historical evidence fields; it has no current-source identity check."
      - path: ".planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md"
        issue: "The durable PASS records release and arm64 runtime evidence for e6b5cbf, not the current tree."
    missing:
      - "Bind evidence to a clean, scoped manifest/digest of Android release inputs, lib/, integration_test/, scripts/, pubspec.yaml, and pubspec.lock; reject a mismatch during --mode=verify."
      - "Add a regression mutation proving an edit after evidence makes strict verification fail, then re-run the signed AAB/APK and primary arm64 matrix against the final source identity."
  - truth: "The API 36 x86_64 GitHub/Intel lane remains independently testable supplemental evidence and is not a Phase 61 blocker."
    status: failed
    reason: "The GitHub job has default fail-fast behavior. It is labelled supplemental but has neither an explicit non-blocking mechanism nor separation from a required workflow/check, so an x86_64 failure fails the device-e2e workflow."
    artifacts:
      - path: ".github/workflows/device-e2e.yml"
        issue: "android-device-e2e has no job-level continue-on-error or other checked-in non-blocking routing."
      - path: "test/architecture/device_e2e_contract_test.dart"
        issue: "The source contract checks the label and ABI but does not test the owner-approved non-blocking condition."
    missing:
      - "Encode the chosen supplemental/non-blocking CI mechanism and add a source-contract test for it."
prohibition_flags:
  count: 8
  disposition: "unverified-prohibition — human review recommended"
  items:
    - "Do not call a mixed or compatibility-flagged AGP 9 graph migrated."
    - "Do not patch Pub-cache, generated Flutter output, or resolved plugin source to manufacture compatibility."
    - "Do not patch caches or plugin source, upgrade Phase 59 packages, or leave candidate edits in the source worktree."
    - "Do not represent a workflow declaration, host test, arm64 diagnostic, or Emulator run as Android physical-device acceptance."
    - "Do not request, use, print, or persist production signing credentials or the evidence private-key material."
    - "Do not merge arm64 primary evidence with x86_64 supplemental evidence, host tests, or an unexecuted CI declaration."
    - "Do not represent Emulator success as Android physical-device acceptance."
    - "Do not convert missing, incompatible, compile-only, mixed-ABI, or unexecuted evidence into a passing claim."
---

# Phase 61: Android Toolchain & Emulator Lane Verification Report

**Phase Goal:** The supported Android build is either fully migrated as one production-stable AGP lane or safely held at the last green AGP 8 lane, with no partial toolchain state; the local Apple Silicon API 36 `google_apis` `arm64-v8a` Emulator is the primary runtime acceptance while the API 36 `x86_64` GitHub/Intel lane remains independently testable supplemental evidence.

**Verified:** 2026-08-10T01:16:56Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

The checked-in Android configuration is a coherent AGP 8 hold, and its source-level guards are substantive. The phase is not achieved because the final release and primary-Emulator PASS records are not bound to the current source tree, and the nominally supplemental x86_64 workflow is still workflow-blocking.

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence |
| --- | --- | --- | --- |
| 1 | AGP 9.3.1 / Gradle 9.5.0 / JDK 17 / API 36 is evaluated as one lane while minSdk remains 24. | ✓ VERIFIED | Candidate metadata, hold evidence, selected Android files, baseline validator, and 117 focused tests agree on the candidate and minSdk 24. |
| 2 | Either complete AGP 9 migration or exact last-green AGP 8 hold with blocker. | ✓ VERIFIED | `settings.gradle.kts`, wrapper, properties, and baseline hold are exactly AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20; the validator rejects partial mutations and names the Flutter/plugin blocker and exit condition. |
| 3 | Final lane produces accepted non-debug signed AAB/APK with no test registrar/plugin. | ✗ FAILED | Historical artifacts were inspected, but the current verifier accepts their old evidence after the safety/release acceptance code changed. No current-source package proof exists. |
| 4 | Clean local API 36 arm64 primary runtime passes; x86_64 is separately testable supplemental evidence; physical Android acceptance is not claimed. | ✗ FAILED | Historical arm64 evidence has all expected fields and the physical-device disclaimer, but it is stale; moreover the x86_64 GitHub job can fail the workflow instead of being explicitly supplemental/non-blocking. |

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Candidate probing is isolated and interruption-safe with unchanged source inputs. | ✓ VERIFIED | Candidate runner uses an external disposable workspace and before/after digest checks; the focused suite passed its success/failure cleanup tests. |
| 2 | Only a complete selected graph or exact last-green hold is terminal; mixed state fails. | ✓ VERIFIED | Current hold files and `validateAndroidSafetyLane` enforce the two states; mutation contracts passed. |
| 3 | minSdk 24 and JDK 17 remain in either state. | ✓ VERIFIED | Baseline, Android source, and baseline CLI passed; JDK/API/minSdk mutations are covered by contracts. |
| 4 | The AGP 9.3.1 candidate probe removes KGP/opt-outs together and records the first blocker. | ✓ VERIFIED | Candidate evidence records the full transaction and explicit Flutter opt-out restoration; code and contracts reject partial construction. |
| 5 | The source worktree retains the exact AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 hold after probing. | ✓ VERIFIED | Current `settings.gradle.kts`, wrapper, and `gradle.properties` exactly match the hold; focused tests and baseline CLI passed. |
| 6 | Hold evidence includes component, official source, reproduction, and machine-checkable exit condition. | ✓ VERIFIED | Ledger and `STABLE_BASELINE.json` contain all fields and tests reject their absence. |
| 7 | The checked-in Android graph matches the terminal decision. | ✓ VERIFIED | Direct source inspection and canonical dependency validator passed. |
| 8 | Dependency validation rejects partial AGP/KGP/DSL mutations and stale blockers. | ✓ VERIFIED | `scripts/dependency_compatibility.dart` is invoked by the passing baseline command; focused mutation contracts passed. |
| 9 | Device E2E preserves the separately testable **supplemental, non-blocking** x86_64 lane. | ✗ FAILED | API/JDK/Flutter/full-suite/preflight declarations exist, but `.github/workflows/device-e2e.yml` has default blocking job behavior. |
| 10 | Missing credentials and Android Debug certificates are rejected by real release tasks. | ✗ FAILED | The ledger records historical negative runs, but the current verifier has no source-identity check for accepting those results. |
| 11 | A non-debug ephemeral certificate produces both release formats under the terminal graph. | ✗ FAILED | Both historical artifact rows exist, but their acceptance is stale relative to the current source/verification code. |
| 12 | Artifact signatures, metadata, registrant, and archive hygiene are independently verified. | ✗ FAILED | Source scanners and test contracts are substantive, but the real AAB/APK proof is not attributable to the current tree. |
| 13 | A clean API 36 arm64 AVD cold-boots, reaches readiness, and records a redacted serial. | ✗ FAILED | The durable record is detailed, but it is accepted for historical `e6b5cbf…` while HEAD is `ea3f9e98…`; current runtime behavior is not proven. |
| 14 | Every checked-in integration test executes on the terminal graph with distinct critical journeys. | ✗ FAILED | Six historical matrix rows and exact discovery checks exist; no digest binds that matrix to the current test/app/release inputs. |
| 15 | Post-integration clean AAB/APK metadata and hygiene are regenerated and clean. | ✗ FAILED | Current emulator orchestration calls `runReleaseEvidence`, but the only accepted run predates later safety-verifier changes. |
| 16 | Final ledger is attributable to one exact current selected-or-held graph. | ✗ FAILED | `source_commit` and `package_source_commit` are equal only to each other, not to current HEAD or a current scoped digest. Strict verify passes incorrectly. |
| 17 | Candidate, package, primary arm64, x86 supplemental, and physical-device result classes stay distinct. | ✓ VERIFIED | Evidence keeps separate fields, labels arm64 `primary_local_arm64`, records x86 as `UNAVAILABLE_LIMITATION`, and explicitly says Android physical-device validation was not performed or claimed. |
| 18 | Focused tests, analyzer, baseline validator, evidence verifier, and whitespace gate pass. | ✓ VERIFIED | This verification ran all 117 focused tests, `flutter analyze`, baseline validation, strict evidence verification, and `git diff --check` successfully. |

**Score:** 10/18 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/verify_android_safety_lane.dart` | Lane modes, redaction, terminal validation, release/emulator orchestration | ⚠️ HOLLOW ACCEPTANCE | 2,771 substantive lines; wired to CLI/tests/baseline/evidence. It omits current-HEAD or scoped-digest verification, so the acceptance boundary is fail-open for stale evidence. |
| `test/architecture/android_toolchain_contract_test.dart` | Terminal-graph mutations | ✓ VERIFIED | Substantive focused contract; included in the 117 passing tests. Its provenance test mutates historical fields but does not mutate current source after evidence. |
| `61-ANDROID-SAFETY-EVIDENCE.md` | Redacted candidate/package/runtime/physical ledger | ⚠️ HOLLOW ACCEPTANCE | Structured, parsed, and redacted, but final PASS rows are stale relative to HEAD. |
| `docs/testing/STABLE_BASELINE.json` | Selected-or-hold policy and exit condition | ✓ VERIFIED | Exact hold policy is read by both safety and canonical dependency validators. |
| `scripts/dependency_compatibility.dart` | Canonical terminal graph validator | ✓ VERIFIED | Substantive and executable; `--mode=baseline --verify-running-flutter-sdk` passed. |
| `.github/workflows/device-e2e.yml` | Reproducible API 36 x86_64 supplemental lane | ⚠️ PARTIAL | Correctly pins API 36/x86_64/JDK 17/Flutter 3.44.8/full suite, but lacks an explicit non-blocking supplemental mechanism. |
| `scripts/release_preflight.sh` | Dual-format packaging and post-build hygiene boundary | ✓ VERIFIED WITH WARNING | Both artifact paths and scans exist and are invoked by release/emulator orchestration. See WR-01 on the JDK-specific package path. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `verify_android_safety_lane.dart` | `STABLE_BASELINE.json` | single version-policy authority | ✓ WIRED | The verifier reads the baseline directly; structural key-link query also passed. |
| Safety verifier | evidence ledger | strict `--mode=verify` parsing | ✗ NOT SAFE | Parser/wiring exists, but it does not establish that the evidence was produced from the current inputs. |
| Emulator runner | release evidence | `runEmulatorEvidence` calls `runReleaseEvidence` after the matrix | ✓ WIRED | Lines 1207–1216 provide the post-test release rescan path. Historical result still needs renewal after fixing provenance. |
| Workflow | x86_64 suite/preflight | emulator-runner then `release_preflight.sh` | ⚠️ PARTIAL | Command/ABI are wired, but job failure remains blocking contrary to the owner-approved lane separation. |
| Release build tasks | signing verification | Gradle release-task dependency | ✓ WIRED | `android/app/build.gradle.kts` wires every release package task to `verifyReleaseSigning`. |

### Data-Flow Trace (Level 4)

No dynamic UI/data-rendering artifacts are in scope. The relevant static flow is baseline → validator → checked-in Android graph → evidence ledger. The flow reaches the ledger but fails its final provenance boundary because the ledger is not bound back to current source inputs.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 61 mutation/source contracts | `flutter test` on the six Phase 61 architecture/script files | 117 tests passed | ✓ PASS |
| Current strict evidence check | `dart run scripts/verify_android_safety_lane.dart --mode=verify` | Exit 0, `PASS: Android safety lane evidence is coherent` | ✗ FAIL (adversarial) |
| Demonstrate stale-evidence condition | Compare evidence commit `e6b5cbf…` to HEAD `ea3f9e98…`; diff relevant scope | Safety verifier changed after the runtime/package evidence | ✗ FAIL |
| Static quality and canonical policy | `flutter analyze`; dependency validator; `git diff --check` | 0 analyzer issues; baseline PASS; whitespace PASS | ✓ PASS |

The passing strict verifier is misleading evidence, not a passing behavioral acceptance: it compares two historical evidence fields but never checks the current checkout.

### Probe Execution

**SKIPPED:** no phase-declared `scripts/*/tests/probe-*.sh` files were found. The phase uses its Dart safety verifier and focused Flutter contracts instead.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AND-01 | 61-01, 61-02, 61-03, 61-06 | Current production-stable candidate evaluated as a complete lane while minSdk remains 24. | ✓ SATISFIED | Candidate/hold policy, exact checked-in hold, minSdk/JDK mutations, and baseline CLI are verified. |
| AND-02 | 61-01, 61-02, 61-03, 61-06 | Atomic AGP 9 migration or exact AGP 8 hold with blocker. | ✓ SATISFIED | Exact AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 hold, both opt-outs, Flutter/plugin blocker, and exit condition are in code and contracts. |
| AND-03 | 61-04, 61-05, 61-06 | Non-debug signed release AAB/APK accepted by signing contract and free of test-only content. | ✗ BLOCKED | Source controls are present, but all real package/negative/hygiene PASS evidence can be stale and must be rebound and rerun. |
| AND-04 | 61-03, 61-05, 61-06 | Local API 36 arm64 primary integration acceptance; x86 supplemental independently testable; no physical-device claim. | ✗ BLOCKED | Current primary runtime evidence is stale and x86 workflow behavior violates the explicit non-blocking supplemental contract. The physical-device disclaimer is correctly present. |

No Phase 61 requirements are orphaned: all four required IDs appear in plan frontmatter.

### Anti-Patterns and Review Findings

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/verify_android_safety_lane.dart` | 156, 440–455 | Historical commit syntax/equality only; no current source identity | 🛑 BLOCKER | CR-01 confirmed. Stale or uncommitted code can inherit runtime/package PASS. |
| `.github/workflows/device-e2e.yml` | 37–76 | Supplemental x86 job uses default blocking behavior | 🛑 BLOCKER | CR-02 confirmed. This contradicts the primary-blocking-arm64 / non-blocking-x86 owner contract. |
| `.github/workflows/device-e2e.yml` | 10–27 | Trigger paths omit `scripts/release_preflight.sh` | ⚠️ WARNING | CR-03 confirmed as a CI coverage gap, but does not itself defeat Phase 61: the workflow remains manually dispatchable and local arm64 orchestration independently calls the release rescan. It should be fixed with Phase 62's automatic release-gate lock. |
| `scripts/release_preflight.sh` | 273–281 | `PHASE61_GRADLE_JAVA_HOME` unconditionally adds `-Pphase61SigningEvidence=true` | ⚠️ WARNING | WR-01 confirmed. This bypasses ignored `android/key.properties` for a JDK-selected ordinary local package. The ephemeral environment-backed evidence lane still works, so this is not the source of the AND-03 failure. |
| `android/app/build.gradle.kts` | 69 | Template `TODO` | ℹ️ INFO | Introduced in commit `e54c5efa` (2026-02-06), before Phase 61; no Phase 61 debt marker was introduced. |

## Unverified Prohibition Flags

Eight plan-declared, judgment-tier prohibitions remain flagged in the plan metadata. Static controls provide supporting evidence for several of them, but no developer has supplied the required authoritative judgment disposition. They are retained in frontmatter as `unverified-prohibition — human review recommended`; they are not counted as verified truths and are not silently converted to PASS.

## Gaps Summary

Two related release gates prevent Phase 61 from passing:

1. **Acceptance evidence is not current-source attributable.** The source changed after `e6b5cbf…` generated the primary Emulator and package evidence. The verifier's own post-evidence changes include validation of the integration matrix and provenance fields, yet strict verification accepts the old record. Fix the provenance contract and re-run the signed package plus local primary arm64 matrix; do not treat a historical record as proof for the final tree.
2. **The x86 workflow is not actually supplemental/non-blocking.** Preserve its testable API 36 x86_64 declaration, but encode a non-blocking mechanism and verify it with a contract test.

The CR-03 path-filter and WR-01 signing-source issues are real warnings retained for the developer; they do not by themselves change the phase verdict. No later milestone phase specifically promises a current-evidence binding or non-blocking x86 mechanism, so neither blocker is deferred.

---

_Verified: 2026-08-10T01:16:56Z_  
_Verifier: the agent (gsd-verifier)_
