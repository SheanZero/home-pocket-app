# Phase 61 Research: Android Toolchain & Emulator Lane

**Researched:** 2026-08-09
**Phase:** 61
**Requirements:** AND-01, AND-02, AND-03, AND-04
**Confidence:** High for the candidate/hold decision inputs; medium for local Emulator runtime cost until the lane executes

## Executive Summary

Phase 61 should be planned as a fail-closed decision transaction followed by proof of the resulting graph, not as an unconditional AGP upgrade. The execution-date production-stable Android candidate has advanced beyond the ROADMAP snapshot: Android's current stable API reference identifies AGP `9.3.1`, and the AGP 9.3 release notes pair that line with Gradle `9.5.0`, SDK Build Tools `36.0.0`, and JDK `17`. API 36 is within the supported range.

The candidate is ineligible for selection under the locked Phase 61 rules. Flutter's official app-developer migration guide says enabling built-in Kotlin requires Flutter `3.47` or later, while Phase 58 locks the app, `.metadata`, CI, and generated graph to Flutter `3.44.8`. The resolved Android plugin graph also contains four published packages that still apply legacy KGP (`file_picker 11.0.3`, `package_info_plus 9.0.1`, `share_plus 12.0.2`, and `speech_to_text 7.3.0`). Phase 59 explicitly holds those versions, and D-06 forbids upgrading them merely to force AGP 9.

The safe implementation path is therefore:

1. Re-query and record AGP `9.3.1` / Gradle `9.5.0` / JDK `17` / API `36` as the execution-date candidate.
2. Run a disposable candidate probe that removes app KGP and both temporary opt-out flags only inside the disposable copy, then capture the first attributable Flutter/plugin incompatibility without editing Pub-cache or generated sources.
3. Verify the main worktree remains or is restored exactly to AGP `8.11.1` / Gradle `8.14` / Kotlin `2.2.20` / JDK `17`, with both legacy flags present and minSdk `24`.
4. Prove that exact hold graph with a non-debug ephemeral evidence key, both release AAB and APK, signature and packaged-content inspection, and the full integration suite on a clean API 36 x86_64 Emulator.

A documented hold is the intended safe success state, not a degraded result. No mixed AGP 9/KGP/new-DSL state may enter the main tree.

## Official Source Recheck

| Surface | Execution-date result | Planning consequence | Source |
|---|---|---|---|
| Current stable AGP | `9.3.1` | Replace the dated `9.0.1` probe value in the candidate ledger; do not silently update the selected graph. | [Android Gradle Plugin API reference](https://developer.android.com/reference/tools/gradle-api) |
| AGP 9.3 companion tools | Gradle `9.5.0`, Build Tools `36.0.0`, JDK `17` | Use the publisher-paired default Gradle rather than independently selecting the newest standalone Gradle. | [AGP 9.3 release notes](https://developer.android.com/build/releases/agp-9-3-0-release-notes) |
| AGP 9 Kotlin behavior | Built-in Kotlin is enabled by default; legacy `kotlin-android` must be removed; the two flags are only a temporary opt-out | Candidate selection must remove KGP and both opt-outs atomically across every Android module. | [Android built-in Kotlin migration](https://developer.android.com/build/migrate-to-built-in-kotlin) |
| Flutter app migration floor | Enabling built-in Kotlin requires Flutter `3.47` or later | Locked Flutter `3.44.8` is an attributable blocker before plugin-specific failures are considered. | [Flutter built-in Kotlin guide for app developers](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) |
| Flutter 3.44 behavior | Flutter 3.44 temporarily supports legacy KGP and old AGP DSL through compatibility settings | The current flags are expected on the exact last-green hold graph and must not be removed there. | [Flutter built-in Kotlin breaking change](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) |
| Gradle/JDK compatibility | Java 17 can run Gradle 7.3 and later, including both selected and candidate lines | Keep JDK 17 as the shared runtime; no JDK change is needed or permitted. | [Gradle compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html) |
| APK signature verification | `apksigner verify` validates APK signatures across supported Android versions | Use SDK Build Tools `apksigner` for the APK certificate and verification evidence. | [apksigner](https://developer.android.com/tools/apksigner) |
| Release signing | APKs and upload AABs must be signed; signing data should remain separate from build files | Generate a disposable non-debug evidence key outside the repository and inject it only through `ANDROID_KEYSTORE_*`. | [Sign your app](https://developer.android.com/studio/publish/app-signing) |
| Emulator isolation | The Android Emulator is a supported test surface; `-wipe-data` clears app/device state and `-no-snapshot` prevents snapshot reuse | Create or reuse a dedicated API 36 x86_64 AVD through checked-in orchestration and force deterministic clean boot/readiness. | [Start the emulator from the command line](https://developer.android.com/studio/run/emulator-commandline), [avdmanager](https://developer.android.com/tools/avdmanager) |

The standalone current Gradle service reported Gradle `9.7.0` on 2026-08-09. It is not the candidate here: Android's AGP 9.3 publisher contract names Gradle `9.5.0` as both minimum and default, and Phase 61 is selecting a coherent Android lane rather than maximizing one independent component.

## Local Graph Findings

### Locked host graph

- Flutter SDK checkout: `3.44.8`.
- Selected Android lane: AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`.
- JDK contract: `17`; the shell has no default Java runtime and Android Studio's bundled JBR is Java `21`, so neither is acceptable evidence for D-04. Execution must use a verified disposable JDK 17 distribution without changing the source tree or host-wide Java selection.
- Android SDK 36 and the Android Emulator binary are installed under the configured SDK. The local Apple-silicon host currently has only an API 36.1 `arm64-v8a` image; the locked x86_64 lane therefore needs a separately installed x86_64 image and software translation (`-no-accel`) or an authorized x86_64 CI host. An arm64 local run may diagnose behavior but cannot populate the D-12 x86_64 result.
- `android/app/build.gradle.kts` inherits `flutter.minSdkVersion`; the selected Flutter source contract resolves that to API 24.
- The app uses Java/Kotlin target 17 and already has a fail-closed release signing task.

### Candidate blockers in the exact resolved graph

The following observations come from `.flutter-plugins-dependencies` plus the resolved packages' Android build inputs. Pub-cache files are read-only evidence and must never be patched.

| Component | Observed incompatibility with D-05 | Consequence |
|---|---|---|
| Flutter `3.44.8` Gradle tooling | Retains legacy `BaseExtension`/`LibraryExtension` paths; official migration guide requires 3.47+ for built-in Kotlin | Candidate cannot be selected without reopening Phase 58, which Phase 61 does not authorize. |
| `file_picker 11.0.3` | Applies `org.jetbrains.kotlin.android` and uses `kotlinOptions` | Exact Phase 59 hold package is not atomically built-in-Kotlin clean. |
| `package_info_plus 9.0.1` | Applies `kotlin-android` and uses `kotlinOptions` | Same blocker; D-06 forbids upgrading only to satisfy AGP 9. |
| `share_plus 12.0.2` | Applies `kotlin-android` and uses `kotlinOptions` | Same blocker. |
| `speech_to_text 7.3.0` | Applies `kotlin-android`, declares its own KGP plugin, and uses `kotlinOptions` | Same blocker and the strongest plugin-specific reproduction candidate. |

Other resolved Android plugins already use newer Kotlin DSL or Java-only build files, but D-05 requires the entire graph. One legacy KGP consumer is enough to reject selection; four are present.

### Existing reusable contracts

- `scripts/dependency_compatibility.dart` and `test/architecture/dependency_compatibility_contract_test.dart` are the canonical baseline/hold authority. Extend their structured manifest checks rather than creating a second version-policy file.
- `android/app/build.gradle.kts` already loads ignored or environment-injected credentials, rejects missing values, rejects `CN=Android Debug`, and wires all release packaging tasks to `verifyReleaseSigning`.
- `scripts/release_preflight.sh` already owns clean Flutter regeneration, release registrant checks, and Android packaging. Extend it to build both Android artifact formats and inspect packaged contents instead of writing an unrelated release script.
- `.github/workflows/device-e2e.yml` already boots an x86_64 Emulator and runs the complete `integration_test/` directory. Update the Android job to API 36 and shared evidence orchestration.
- Existing architecture tests already exercise source-level release signing, device-workflow pins, critical journey markers, and release-preflight ordering. New behavior should begin with mutations against these tests.

## Recommended Implementation Architecture

### 1. One checked-in Android lane verifier

Add `scripts/verify_android_safety_lane.dart` as the orchestration and evidence authority. It should have explicit modes so the expensive work stays attributable:

- `--mode=candidate-probe`: create a disposable workspace, record exact candidate inputs, apply only the candidate transaction there, run Gradle/Flutter graph probes, capture the first failure, and prove the source worktree is unchanged.
- `--mode=release`: generate an ephemeral evidence key outside the repository, build AAB and APK under the final graph, verify signatures and metadata, scan artifacts/registrant, then delete key and artifacts after redacted hashes/results are captured.
- `--mode=emulator`: resolve or create the dedicated API 36 x86_64 AVD, boot with clean state, wait for `sys.boot_completed`, run every `integration_test/` file, then regenerate release metadata and rescan hygiene.
- `--mode=verify`: validate the final checked-in graph and evidence ledger without re-running costly external work.

The exact mode names may differ during implementation, but a single source of truth is preferable to three mutually drifting shell scripts. Shell remains appropriate only for the existing release-preflight boundary and tool invocation.

### 2. Durable evidence schema

Add `.planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md` and a small machine-readable JSON companion only if the existing validator needs structured fields. The durable ledger must include:

- source commit and clean-tree result;
- UTC start/end timestamps and redacted host OS;
- Flutter/Dart, JDK, AGP, Gradle, Kotlin, Android SDK/Build Tools, Emulator version;
- candidate and selected/held graph;
- candidate failure component, exact redacted command, exit code, official source, and machine-checkable exit condition;
- AAB/APK SHA-256, package/version metadata, certificate class/fingerprint, and verification result;
- generated registrant and packaged-content scan results;
- AVD profile, API, ABI, redacted serial, and full per-test-file exit result;
- explicit result classes for compile, package, Emulator runtime, and physical device;
- the literal statement: “Android physical-device validation was not performed or claimed.”

Never store keystore material, passwords, raw device serials, home paths, production credentials, database paths, test financial values, or unredacted logs.

### 3. Candidate/hold state machine

The verifier should accept exactly two terminal states:

- `selected`: every candidate version is exact; app and all resolved Android plugins are built-in-Kotlin/new-DSL clean; KGP and both opt-outs are absent; every release and Emulator gate is attributable to that graph.
- `hold`: the main tree exactly matches AGP `8.11.1` / Gradle `8.14` / Kotlin `2.2.20`; both temporary flags remain; the evidence names at least one candidate blocker and an exit condition; release and Emulator gates pass on the hold graph.

Reject `candidate`, `partial`, missing decision, contradictory versions, stale blocker source, an accepted candidate with any legacy KGP consumer, or a hold with any candidate residue.

### 4. Release artifact inspection

The existing `--package` path builds only an AAB. Phase 61 must build both formats under one preflight:

- `flutter build appbundle --release`
- `flutter build apk --release`

Use the existing release signing task for negative missing/debug checks, `apksigner verify --print-certs` for the APK, and `keytool -printcert -jarfile` (or the JDK jarsigner verification path) for the AAB. Classify the certificate without persisting private material. Inspect archive entries plus relevant DEX/string content for `integration_test`, `IntegrationTestPlugin`, and any enumerated test-only Android registrar/plugin identifiers. Source-only grep is not sufficient.

### 5. Emulator lane

Use an API 36 x86_64 system image and one dedicated AVD name. Boot with `-wipe-data -no-snapshot -no-audio -no-boot-anim` where supported, wait for both `adb wait-for-device` and `getprop sys.boot_completed == 1`, disable animations, and record the redacted runtime identity before starting Flutter tests. The complete `integration_test/` directory must run. Keep per-file or per-group results so the following remain attributable:

- onboarding → ledger → backup → app-lock;
- current-schema SQLCipher create/write/cold reopen;
- backup recovery and tamper/atomicity cases;
- sync delivery and offline queue;
- merchant migration ladder;
- existing synthetic opt-in performance measurement without inventing a new threshold.

After device tests, run clean Android release metadata regeneration and repeat registrant/package hygiene checks because integration testing can alter generated registrants.

## Validation Architecture

### Fast feedback tiers

| Tier | Command or evidence | Frequency | What it proves |
|---|---|---|---|
| Source contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/android_release_signing_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/release_preflight_test.dart` | Every relevant task | Fail-closed graph, signing, workflow, and preflight structure. |
| Lane verifier | `dart run scripts/verify_android_safety_lane.dart --mode=verify` | Every task after scaffold | Terminal selected/hold state, provenance completeness, no mixed graph. |
| Candidate probe | disposable AGP 9.3.1 / Gradle 9.5.0 command recorded by the verifier | Once per official-source refresh or blocker exit | AND-01/AND-02 attempt and attributable blocker without main-tree contamination. |
| Signed packaging | ephemeral key + release AAB/APK + signature and hygiene inspection | Final graph, before Emulator and once after clean regeneration | AND-03 against real artifacts. |
| Emulator runtime | complete `flutter test integration_test/ -d <redacted-emulator>` on API 36 x86_64 | Final graph | AND-04 runtime behavior and SQLCipher lifecycle on Android. |
| Phase convergence | focused suite, `flutter analyze`, `git diff --check`, evidence validator | End of phase | No source-contract or analyzer regression; broad full-suite/coverage remains Phase 62-owned. |

### TDD/mutation cases

The architecture and script tests should go red for at least:

- current stable candidate version/date/source missing or stale;
- candidate versions partly applied to main-tree files;
- hold graph with either opt-out removed or any candidate residue;
- selected graph with app/plugin KGP or legacy DSL consumer;
- minSdk raised above or lowered below 24;
- candidate probe mutating the source worktree;
- evidence blocker missing component, source, reproduction, or exit condition;
- release packaging missing either AAB or APK;
- missing credentials accepted, Android Debug certificate accepted, or artifact unsigned;
- `integration_test`/test registrar present in generated registrant, AAB, or APK;
- Emulator API/ABI not 36/x86_64, incomplete integration file matrix, or physical-device claim forged;
- evidence containing a raw serial, keystore path/password, or other prohibited sensitive field.

### Nyquist mapping

- AND-01: official-source ledger + disposable candidate probe + minSdk/JDK assertions.
- AND-02: exact terminal state machine + legacy KGP inventory + main-tree cleanliness oracle.
- AND-03: source negative contracts + real signed AAB/APK + certificate and packaged-content evidence.
- AND-04: API 36 x86_64 boot evidence + complete integration suite matrix + explicit no-physical-device statement.

## Spec-less Edge Resolution

The deterministic fallback probe surfaced four items. In auto mode they resolve as follows:

- AND-01 concurrency: covered — candidate probing runs only in a unique disposable workspace and asserts the source worktree/input digests are unchanged before accepting evidence.
- AND-02 unclassified: covered — a terminal state validator accepts only complete `selected` or exact `hold`; all mixed states fail.
- AND-03 unclassified: covered — acceptance requires both real artifact files, independent signature verification, and packaged-content scans after a clean regeneration boundary.
- AND-04 unclassified: covered — the checked-in matrix enumerates every integration test file and the evidence distinguishes Emulator from physical-device claims.

No backstop-only edge is necessary because each item has an executable acceptance criterion.

## Prohibition Probe

Adversarial recall was run per requirement, then routine engineering and canonical security items were dropped. The bespoke retained prohibitions are:

1. The lane must not call a mixed or compatibility-flagged AGP 9 graph “migrated.”
2. The candidate probe must not patch Pub-cache, generated Flutter outputs, or resolved plugin sources to manufacture compatibility.
3. Release proof must not request, use, print, or persist production signing credentials or evidence private-key material.
4. Emulator success must not be represented as Android physical-device acceptance.

In spec-less auto mode these remain descriptor-less, flagged, and unverified in PLAN front matter/must-haves so verification cannot silently green a values/safety judgment.

Canonical keystore secrecy, command injection, path traversal, and generic CI credential handling are referred to the phase threat models and `$gsd-secure-phase`; they are not duplicated as bespoke prohibitions.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The disposable candidate downloads a large Gradle/AGP graph before reaching the known Flutter/KGP failure | Time and network cost | Run lexical/official preflight first, then one bounded compile/configuration probe to capture an attributable failure; cache only outside source control. |
| The shell has no default Java and Android Studio bundles JBR 21 | Candidate/release commands fail before the required JDK 17 graph is evaluated | Resolve a verified disposable JDK 17 under a temporary tool directory, set `JAVA_HOME` only for lane commands, record its publisher/version/checksum, and reject every other major. |
| The Apple-silicon host lacks an x86_64 API 36 image | Runtime proof cannot start, or software translation is prohibitively slow | Install the exact image outside the repo and attempt the supported `-no-accel` path; if it cannot finish, leave AND-04 blocked rather than substituting the available arm64 image or claiming CI that did not run. |
| Integration suite runtime is long | Poor diagnostics or timeout | Execute all files while preserving per-file results; retry only the attributable failed file, then rerun the complete matrix if a fix lands. |
| Local ignored platform configuration affects release artifacts | Evidence is non-reproducible or may disclose identifiers | Record only whether required inputs exist, never their contents; artifact scans are allow/deny classifications with redacted output. Do not commit ignored files. |
| AAB inspection is mistaken for installable APK verification | False signature claim | Keep AAB upload-signature and APK platform-signature evidence as distinct rows/tools. |

## Planning Recommendation

Use six sequential plans because the same Android/build/evidence surfaces are shared and the final graph must be selected before packaging or Emulator execution:

1. Contract and tracer scaffold for candidate/hold state, provenance, and minSdk 24.
2. Official requery plus disposable AGP 9 candidate attempt; select or hold atomically.
3. Apply/lock the terminal graph and update baseline/CI contracts.
4. Build and verify ephemeral-non-debug-signed AAB/APK and artifact hygiene.
5. Boot API 36 x86_64 Emulator, run the complete integration suite, regenerate clean release metadata, and rescan.
6. Converge the evidence ledger and focused Phase 61 verification.

Plans 1–2 are the end-to-end tracer: by the end of plan 2 the lane has a real official candidate, a bounded attempted build, an attributable decision, and a machine-checked clean terminal graph. Plans 3–6 deepen and prove that decision without reopening it.

## RESEARCH COMPLETE
