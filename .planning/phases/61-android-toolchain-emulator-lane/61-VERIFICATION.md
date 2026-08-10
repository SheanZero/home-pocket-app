---
phase: 61-android-toolchain-emulator-lane
verified: 2026-08-10T01:26:53Z
status: passed
score: 18/18 must-haves verified
behavior_unverified: 0
overrides_applied: 2
overrides:
  - must_have: "The final ledger is attributable to the current source tree and its release/primary-Emulator acceptance evidence."
    reason: "The project owner explicitly accepted deferring current-source evidence rebinding and rerunning the package/arm64 evidence. Historical evidence and the stale-provenance risk remain documented for milestone audit."
    accepted_by: "project owner"
    accepted_at: "2026-08-10T01:26:53Z"
  - must_have: "The API 36 x86_64 GitHub/Intel lane remains independently testable supplemental evidence and is not a Phase 61 blocker."
    reason: "The project owner explicitly accepted deferring an explicit non-blocking mechanism for the supplemental x86_64 job. Local API 36 arm64 remains the primary release acceptance lane, and the CI-routing risk remains documented for milestone audit."
    accepted_by: "project owner"
    accepted_at: "2026-08-10T01:26:53Z"
prohibition_flags:
  count: 8
  disposition: "documented non-blocking review debt — no violation observed; formal judgment deferred by owner"
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

**Verified:** 2026-08-10T01:26:53Z
**Status:** passed
**Re-verification:** Yes — project-owner overrides accepted for both verification gaps

## Goal Achievement

The checked-in Android configuration is a coherent AGP 8 hold, and its source-level guards are substantive. The project owner explicitly accepted the two remaining verification gaps as deferred debt: current-source evidence rebinding and an explicit non-blocking mechanism for the supplemental x86_64 workflow. With those two documented overrides, the phase goal is accepted as achieved.

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence |
| --- | --- | --- | --- |
| 1 | AGP 9.3.1 / Gradle 9.5.0 / JDK 17 / API 36 is evaluated as one lane while minSdk remains 24. | ✓ VERIFIED | Candidate metadata, hold evidence, selected Android files, baseline validator, and 117 focused tests agree on the candidate and minSdk 24. |
| 2 | Either complete AGP 9 migration or exact last-green AGP 8 hold with blocker. | ✓ VERIFIED | `settings.gradle.kts`, wrapper, properties, and baseline hold are exactly AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20; the validator rejects partial mutations and names the Flutter/plugin blocker and exit condition. |
| 3 | Final lane produces accepted non-debug signed AAB/APK with no test registrar/plugin. | ✓ PASSED (override) | Historical artifacts were inspected. The owner accepted deferring current-source evidence rebinding and rerunning the package evidence; the provenance risk remains documented. |
| 4 | Clean local API 36 arm64 primary runtime passes; x86_64 is separately testable supplemental evidence; physical Android acceptance is not claimed. | ✓ PASSED (override) | The arm64 matrix passed and the physical-device disclaimer is present. The owner accepted the stale-provenance risk and deferral of explicit non-blocking x86 routing. |

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
| 9 | Device E2E preserves the separately testable **supplemental, non-blocking** x86_64 lane. | ✓ PASSED (override) | API/JDK/Flutter/full-suite/preflight declarations exist. The owner accepted deferring explicit non-blocking workflow routing. |
| 10 | Missing credentials and Android Debug certificates are rejected by real release tasks. | ✓ PASSED (override) | Historical negative runs are recorded; the owner accepted deferring current-source evidence rebinding. |
| 11 | A non-debug ephemeral certificate produces both release formats under the terminal graph. | ✓ PASSED (override) | Both historical artifact rows exist; the owner accepted their stale-provenance risk. |
| 12 | Artifact signatures, metadata, registrant, and archive hygiene are independently verified. | ✓ PASSED (override) | Source scanners and contracts are substantive; current-source provenance rebinding is deferred by owner acceptance. |
| 13 | A clean API 36 arm64 AVD cold-boots, reaches readiness, and records a redacted serial. | ✓ PASSED (override) | The detailed durable run passed; the owner accepted its historical-source provenance. |
| 14 | Every checked-in integration test executes on the terminal graph with distinct critical journeys. | ✓ PASSED (override) | All six matrix rows and exact discovery checks exist; scoped digest binding is deferred by owner acceptance. |
| 15 | Post-integration clean AAB/APK metadata and hygiene are regenerated and clean. | ✓ PASSED (override) | The recorded post-test release scan passed; renewal after verifier changes is deferred by owner acceptance. |
| 16 | Final ledger is attributable to one exact current selected-or-held graph. | ✓ PASSED (override) | The owner accepted deferring a current-HEAD/scoped-digest binding while retaining the exact stale-provenance finding. |
| 17 | Candidate, package, primary arm64, x86 supplemental, and physical-device result classes stay distinct. | ✓ VERIFIED | Evidence keeps separate fields, labels arm64 `primary_local_arm64`, records x86 as `UNAVAILABLE_LIMITATION`, and explicitly says Android physical-device validation was not performed or claimed. |
| 18 | Focused tests, analyzer, baseline validator, evidence verifier, and whitespace gate pass. | ✓ VERIFIED | This verification ran all 117 focused tests, `flutter analyze`, baseline validation, strict evidence verification, and `git diff --check` successfully. |

**Score:** 18/18 truths accepted (10 directly verified, 8 covered by 2 project-owner overrides, 0 behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/verify_android_safety_lane.dart` | Lane modes, redaction, terminal validation, release/emulator orchestration | ✓ PASSED (override) | 2,771 substantive lines; wired to CLI/tests/baseline/evidence. The owner accepted deferring its missing current-HEAD/scoped-digest verification. |
| `test/architecture/android_toolchain_contract_test.dart` | Terminal-graph mutations | ✓ VERIFIED | Substantive focused contract; included in the 117 passing tests. Its provenance test mutates historical fields but does not mutate current source after evidence. |
| `61-ANDROID-SAFETY-EVIDENCE.md` | Redacted candidate/package/runtime/physical ledger | ✓ PASSED (override) | Structured, parsed, and redacted. The owner accepted the final PASS rows' stale provenance. |
| `docs/testing/STABLE_BASELINE.json` | Selected-or-hold policy and exit condition | ✓ VERIFIED | Exact hold policy is read by both safety and canonical dependency validators. |
| `scripts/dependency_compatibility.dart` | Canonical terminal graph validator | ✓ VERIFIED | Substantive and executable; `--mode=baseline --verify-running-flutter-sdk` passed. |
| `.github/workflows/device-e2e.yml` | Reproducible API 36 x86_64 supplemental lane | ✓ PASSED (override) | Correctly pins API 36/x86_64/JDK 17/Flutter 3.44.8/full suite. The owner accepted deferring an explicit non-blocking mechanism. |
| `scripts/release_preflight.sh` | Dual-format packaging and post-build hygiene boundary | ✓ VERIFIED WITH WARNING | Both artifact paths and scans exist and are invoked by release/emulator orchestration. See WR-01 on the JDK-specific package path. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `verify_android_safety_lane.dart` | `STABLE_BASELINE.json` | single version-policy authority | ✓ WIRED | The verifier reads the baseline directly; structural key-link query also passed. |
| Safety verifier | evidence ledger | strict `--mode=verify` parsing | ✓ PASSED (override) | Parser/wiring exists; current-input provenance binding is explicitly deferred by owner acceptance. |
| Emulator runner | release evidence | `runEmulatorEvidence` calls `runReleaseEvidence` after the matrix | ✓ WIRED | Lines 1207–1216 provide the post-test release rescan path. Historical result still needs renewal after fixing provenance. |
| Workflow | x86_64 suite/preflight | emulator-runner then `release_preflight.sh` | ✓ PASSED (override) | Command/ABI are wired; the owner accepted deferring explicit non-blocking CI routing. |
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

The strict verifier's stale-provenance limitation remains real: it compares two historical evidence fields but never checks the current checkout. The owner explicitly accepted this as deferred debt rather than requiring a rerun in Phase 61.

### Probe Execution

**SKIPPED:** no phase-declared `scripts/*/tests/probe-*.sh` files were found. The phase uses its Dart safety verifier and focused Flutter contracts instead.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AND-01 | 61-01, 61-02, 61-03, 61-06 | Current production-stable candidate evaluated as a complete lane while minSdk remains 24. | ✓ SATISFIED | Candidate/hold policy, exact checked-in hold, minSdk/JDK mutations, and baseline CLI are verified. |
| AND-02 | 61-01, 61-02, 61-03, 61-06 | Atomic AGP 9 migration or exact AGP 8 hold with blocker. | ✓ SATISFIED | Exact AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 hold, both opt-outs, Flutter/plugin blocker, and exit condition are in code and contracts. |
| AND-03 | 61-04, 61-05, 61-06 | Non-debug signed release AAB/APK accepted by signing contract and free of test-only content. | ✓ SATISFIED (override) | Source controls and historical package/negative/hygiene evidence are present; current-source rebinding and rerun are deferred by owner acceptance. |
| AND-04 | 61-03, 61-05, 61-06 | Local API 36 arm64 primary integration acceptance; x86 supplemental independently testable; no physical-device claim. | ✓ SATISFIED (override) | The arm64 primary matrix passed and the physical-device disclaimer is present; stale provenance and explicit non-blocking x86 routing are deferred by owner acceptance. |

No Phase 61 requirements are orphaned: all four required IDs appear in plan frontmatter.

### Anti-Patterns and Review Findings

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/verify_android_safety_lane.dart` | 156, 440–455 | Historical commit syntax/equality only; no current source identity | ⚠️ ACCEPTED DEBT | CR-01 confirmed. Stale or uncommitted code can inherit runtime/package PASS; the owner deferred the fix. |
| `.github/workflows/device-e2e.yml` | 37–76 | Supplemental x86 job uses default blocking behavior | ⚠️ ACCEPTED DEBT | CR-02 confirmed. This contradicts the intended lane separation; the owner deferred the fix. |
| `.github/workflows/device-e2e.yml` | 10–27 | Trigger paths omit `scripts/release_preflight.sh` | ⚠️ WARNING | CR-03 confirmed as a CI coverage gap, but does not itself defeat Phase 61: the workflow remains manually dispatchable and local arm64 orchestration independently calls the release rescan. It should be fixed with Phase 62's automatic release-gate lock. |
| `scripts/release_preflight.sh` | 273–281 | `PHASE61_GRADLE_JAVA_HOME` unconditionally adds `-Pphase61SigningEvidence=true` | ⚠️ WARNING | WR-01 confirmed. This bypasses ignored `android/key.properties` for a JDK-selected ordinary local package. The ephemeral environment-backed evidence lane still works, so this is not the source of the AND-03 failure. |
| `android/app/build.gradle.kts` | 69 | Template `TODO` | ℹ️ INFO | Introduced in commit `e54c5efa` (2026-02-06), before Phase 61; no Phase 61 debt marker was introduced. |

## Accepted Prohibition Review Debt

Eight plan-declared, judgment-tier prohibitions remain visible in the plan metadata. Static controls provide supporting evidence and no violation was observed. Their formal judgment review is deferred as non-blocking owner-accepted debt; they remain in frontmatter and are not silently deleted.

## Accepted Verification Overrides

No unresolved blocking gaps remain after the project owner's explicit acceptance of these two overrides:

1. **Acceptance evidence is not current-source attributable.** The source changed after `e6b5cbf…` generated the primary Emulator and package evidence. The verifier still accepts the old record. Current-source provenance binding and rerunning the signed package plus local primary arm64 matrix are deferred.
2. **The x86 workflow is not explicitly non-blocking.** The API 36 x86_64 declaration remains testable, but encoding and contract-testing a non-blocking mechanism are deferred.

The CR-03 path-filter and WR-01 signing-source issues remain real warnings. All four items remain visible for milestone audit; passing this phase does not claim they were fixed.

---

_Verified: 2026-08-10T01:26:53Z_
_Verifier: the agent (gsd-verifier)_
