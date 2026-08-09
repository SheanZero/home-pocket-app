# Phase 61: Android Toolchain & Emulator Lane - Context

**Gathered:** 2026-08-09
**Status:** Ready for planning
**Mode:** Auto-selected conservative infrastructure defaults

<domain>
## Phase Boundary

Select and prove one complete production-stable Android host lane for Happy Pocket. Phase 61 owns execution-date AGP/Gradle/JDK/Android SDK revalidation, the all-or-hold AGP 9 and built-in-Kotlin/new-DSL decision, Android release signing and artifact hygiene, and supported Android Emulator integration evidence while preserving minSdk 24. It does not reopen Phase 59 plugin-product decisions, change application behavior or schema, claim Android physical-device acceptance, run the final cross-platform convergence gate, or perform the Phase 63 wired-iPhone acceptance.

</domain>

<decisions>
## Implementation Decisions

### Atomic Candidate or Hold
- **D-01:** Re-query official primary sources at execution time. Evaluate the newest mutually compatible production-stable Android lane corresponding to the ROADMAP candidate (AGP `9.0.1`, Gradle `9.1`, JDK `17`, Android API `36` as of 2026-08-05); do not assume the dated patch values remain current.
- **D-02:** Evaluate the candidate first in a disposable isolated workspace. Select it in the main tree only when the app and every resolved Android plugin compile and package under the same graph, minSdk remains 24, and every Phase 61 gate can be attributed to that exact graph. — **Reversibility:** costly — undoing a selected lane rewrites Gradle/Kotlin configuration, the wrapper, contracts, CI, and evidence together.
- **D-03:** Any unresolved AGP 9, Flutter, or plugin incompatibility requires a complete evidence-backed hold at the exact last-green lane: AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, JDK `17`, and the existing legacy opt-out settings. Record the blocker, affected component, official source, reproduction command, and machine-checkable exit condition. No partial AGP 9 state may remain.
- **D-04:** Preserve inherited Android minSdk 24 and JDK 17 in either outcome. API 36 remains the compile/target and emulator acceptance surface; raising minSdk or changing app behavior is not an escape from a toolchain incompatibility.

### Built-in Kotlin and New DSL Boundary
- **D-05:** If AGP 9 is selected, built-in Kotlin, the new DSL, legacy KGP removal, and cleanup of `android.builtInKotlin=false` plus `android.newDsl=false` are one indivisible transaction across the app and resolved plugin graph. App-only modernization while a plugin or generated build still needs the legacy lane is a blocker, not a pass.
- **D-06:** Do not upgrade or otherwise reopen Phase 59's held Flutter plugin cohorts merely to make AGP 9 pass. A selected Phase 59 package that is incompatible with the atomic AGP 9 lane forces the documented AGP 8 hold unless a separately approved requirement already permits that package change.
- **D-07:** Do not hand-edit Flutter-generated registrants, Pub-cache plugin sources, Gradle caches, or other ephemeral outputs. Make source-controlled Gradle/Flutter changes through supported configuration, then regenerate and prove the result from a clean state.

### Release Signing and Artifact Hygiene
- **D-08:** Generate an ephemeral non-debug evidence keystore outside the repository and inject it through the existing `ANDROID_KEYSTORE_*` environment contract. Never request, read, use, print, or commit production signing credentials or the evidence key material.
- **D-09:** Build both a release AAB and release APK under the final selected-or-held lane. Verify their certificate is non-debug, capture artifact hashes and package/version metadata, and retain negative evidence that missing credentials and an Android Debug certificate are rejected. A config-only, unsigned, profile, or debug build is not release acceptance.
- **D-10:** After emulator integration tests, regenerate clean release metadata and scan the generated Android registrant plus packaged AAB/APK contents for `integration_test` or any test-only registrar/plugin reference. The release artifact itself, not only source text, is the acceptance boundary.
- **D-11:** Release artifacts and keystores remain ignored/disposable. Persist only redacted evidence: source commit, commands, exit codes, artifact hashes, certificate classification/fingerprint, and hygiene results.

### Emulator and Evidence Boundary
- **D-12:** Use a clean supported API 36 x86_64 Android Emulator with deterministic boot/readiness and isolated synthetic data. Record the AVD profile, API, ABI, runtime, and device identifier in redacted form. Android physical hardware is unavailable, out of scope, and must be stated as not performed/not claimed.
- **D-13:** Run the complete existing `integration_test/` suite on the final Android graph. Preserve separately identifiable results for onboarding → ledger → backup → app-lock, current-schema SQLCipher create/write/cold-reopen, sync delivery, and merchant migration. Performance output remains governed by its existing synthetic, opt-in measurement contract and is not promoted into a new product threshold here.
- **D-14:** The final evidence ledger records source commit, UTC timestamps, host OS, JDK, Flutter/Dart, AGP, Gradle, Kotlin, Android SDK/build-tools, emulator identity, exact commands/exit codes, selected-or-held outcome, blocker/exit condition if held, signed artifact hashes, signature/hygiene results, and clean-tree status. Compilation, packaging, Emulator runtime, and absent physical-device evidence remain distinct result classes.
- **D-15:** Phase 61 succeeds either by adopting the complete production-stable candidate with all gates green or by restoring and proving the exact last-green AGP 8 lane with an attributable blocker. A safe hold is success; a mixed graph, unproven release, or host-only substitute is failure.

### the agent's Discretion
- Choose the checked-in runner/evidence file names, disposable-workspace mechanism, AVD name, command ordering, artifact-inspection tools, and evidence JSON/Markdown layout while preserving the locked boundaries above.
- Choose how to partition the full integration suite for diagnostics and retries, provided every test executes on the final API 36 Emulator graph and the named critical journeys retain attributable results.
- Add focused source/mutation contracts for plugin compatibility, Kotlin/DSL cleanup, release signing, registrant hygiene, and provenance when they strengthen the fail-closed lane without weakening existing gates.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and Locked Requirements
- `AGENTS.md` — repository branch, architecture, SQLCipher, Android floor, testing, generated-output, and evidence rules.
- `.planning/ROADMAP.md` — Phase 61 goal, AND-01 through AND-04 success criteria, and Phase 62/63 boundaries.
- `.planning/REQUIREMENTS.md` — Android toolchain, release-signing, Emulator, and explicit no-physical-device requirements.
- `.planning/PROJECT.md` — v2.1 milestone goal and local-first/security constraints.
- `.planning/STATE.md` — active Phase 61 position, all-or-hold rule, and device-evidence boundary.
- `.planning/phases/57-stable-baseline-compatibility-contract/57-CONTEXT.md` — production-stable/hold semantics and Android API 24 invariant.
- `.planning/phases/58-flutter-analyzer-code-generation-lane/58-CONTEXT.md` — locked Flutter `3.44.8` / Dart `3.12.2` graph that the Android lane consumes.
- `.planning/phases/60-sqlcipher-ios-native-safety-lane/60-VERIFICATION.md` — verified SQLCipher Native Assets `4.17.x`, schema 36, and current HPB-v2 boundaries that Android runtime must preserve.

### Android Build Graph
- `docs/testing/STABLE_BASELINE.json` — dated AGP/Gradle/JDK/API candidates, exact selected AGP 8 lane, tracked Android input digests, holds, and exit conditions.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — human-readable atomic Android lane and release evidence contract.
- `.metadata` — locked Flutter project identity.
- `pubspec.yaml` — selected Flutter plugin and SQLCipher Native Assets declarations.
- `pubspec.lock` — exact resolved Flutter/plugin graph whose Android subprojects must be compatible.
- `android/settings.gradle.kts` — AGP/KGP/Flutter plugin declarations and repositories.
- `android/build.gradle.kts` — root/subproject Java 17 and build-directory configuration.
- `android/gradle.properties` — current built-in-Kotlin/new-DSL opt-out flags.
- `android/gradle/wrapper/gradle-wrapper.properties` — selected Gradle distribution.
- `android/app/build.gradle.kts` — min/compile/target SDK inheritance, Java/Kotlin 17, release signing, packaging tasks, and Flutter Gradle plugin application.
- `android/app/src/main/AndroidManifest.xml` — production Android component and plugin-registration surface.
- `android/app/src/main/kotlin/com/sheanzero/happypocket/app/MainActivity.kt` — production Flutter Android host entrypoint.

### Executable Contracts and Runtime Evidence
- `scripts/dependency_compatibility.dart` — existing fail-closed SDK, Android floor, tracked-input, and dependency graph validator.
- `test/architecture/dependency_compatibility_contract_test.dart` — positive/mutation patterns for Android floor and baseline drift.
- `test/architecture/android_release_signing_contract_test.dart` — release-key configuration, missing-key, and debug-certificate source contract.
- `scripts/release_preflight.sh` — clean registrant regeneration, release hygiene, and signed Android packaging entrypoint.
- `test/scripts/release_preflight_test.dart` — preflight and test-only registrant rejection contracts.
- `.github/workflows/device-e2e.yml` — current JDK/Flutter/Android Emulator integration lane; API 35 is an input to update, not Phase 61 acceptance.
- `test/architecture/device_e2e_contract_test.dart` — CI pin, emulator, and critical-journey source contract.
- `integration_test/device_critical_journey_test.dart` — onboarding, ledger, current-v2 backup, app-lock, and SQLCipher user journey.
- `integration_test/sqlcipher_native_assets_lifecycle_test.dart` — production executor current-schema SQLCipher cold-reopen invariant.
- `integration_test/sqlcipher_backup_recovery_test.dart` — isolated current-v2 recovery and atomicity journey.
- `integration_test/device_sync_delivery_test.dart` — offline queue, encrypted sync, pull/apply/ACK, and notification-seam journey.
- `integration_test/merchant_migration_ladder_test.dart` — on-device encrypted merchant current/v21-to-current ladder.
- `integration_test/performance/performance_baseline_test.dart` — isolated synthetic performance measurement contract; no new threshold is inferred in Phase 61.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/dependency_compatibility.dart` and its architecture tests already parse the Flutter floor, tracked Android input digests, selected toolchains, and prohibited graph drift; extend this authority instead of creating a second policy source.
- `android/app/build.gradle.kts` already loads ignored/env release credentials, rejects missing values, rejects the Android Debug certificate, and binds verification to release packaging tasks.
- `scripts/release_preflight.sh` already cleans, regenerates, rejects `integration_test` registrants, and optionally packages a signed Android release.
- `.github/workflows/device-e2e.yml` already boots an x86_64 Android Emulator and runs `integration_test/`; update its JDK/API/evidence contract rather than introducing a parallel CI lane.
- The existing device integration tests use isolated synthetic keys, databases, storage, and network doubles while exercising the production SQLCipher executor and application journeys.

### Established Patterns
- Security- or compatibility-critical native changes are all-or-hold; exact green recovery with an exit condition is an accepted outcome.
- Generated registrants and plugin artifacts are regenerated and inspected, never hand-edited.
- Compile/configuration, release packaging/signing, Emulator runtime, and physical-device evidence are separate claims.
- Sensitive values and device identifiers are redacted; only synthetic data and artifact/toolchain metadata enter evidence.
- The `.planning/codebase/STACK.md` and `INTEGRATIONS.md` maps contain pre-Phase-60 dependency entries; current source, locks, `STABLE_BASELINE.json`, and Phase 60 verification take precedence for Phase 61.

### Integration Points
- `settings.gradle.kts`, `gradle.properties`, the Gradle wrapper, root/app build scripts, Flutter's Gradle plugin, and every Pub plugin Android subproject form one compatibility graph.
- `pubspec.yaml`/`pubspec.lock` and the SQLCipher Native Asset hook must remain unchanged unless a Phase 61 requirement explicitly forces a coordinated source change.
- The release preflight and signing contract connect toolchain selection to real AAB/APK output and registrant hygiene.
- Device E2E CI and the checked-in integration suite provide the supported Emulator runtime boundary consumed later by Phase 62.

</code_context>

<specifics>
## Specific Ideas

- Treat the current AGP `8.11.1` / Gradle `8.14` / Kotlin `2.2.20` graph as the named rollback point, not as an informal fallback reconstructed after a failed edit.
- Use an ephemeral non-debug certificate to prove the signing path without touching production secrets; a debug key or unsigned artifact is never equivalent.
- Keep the full Emulator suite and signed-artifact scan attributable to the exact final graph, with a clean supported regeneration boundary after integration tests.
- State “Android physical-device validation was not performed or claimed” verbatim in final evidence.

</specifics>

<deferred>
## Deferred Ideas

- Phase 59 Flutter plugin cohort upgrades remain held and are not reopened by this toolchain phase.
- Final cross-platform clean generation, analysis, tests, coverage, release, Simulator, and Emulator convergence belongs to Phase 62.
- Signed isolated physical-iPhone acceptance belongs to Phase 63; Android physical-device acceptance remains unavailable and out of scope.

</deferred>

---

*Phase: 61-android-toolchain-emulator-lane*
*Context gathered: 2026-08-09*
