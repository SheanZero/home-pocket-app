# Phase 61 Code Patterns

**Mapped:** 2026-08-09
**Inputs:** `61-CONTEXT.md`, `61-RESEARCH.md`, current Android/release/test sources

## File-to-Pattern Map

| Planned file | Role/data flow | Closest existing analog | Pattern to preserve |
|---|---|---|---|
| `scripts/verify_android_safety_lane.dart` | Parse source/build inputs, orchestrate bounded tools, emit redacted evidence | `scripts/verify_ios_native_safety_lane.dart`; `scripts/dependency_compatibility.dart` | Typed result classes, explicit modes, fail-closed parsing, redaction before durable output, no secret values. |
| `test/architecture/android_toolchain_contract_test.dart` | Mutation contracts for terminal selected/hold graph | `test/architecture/dependency_compatibility_contract_test.dart`; `test/architecture/ios_native_linkage_contract_test.dart` | Read real source once, mutate in memory, assert precise findings; never mutate source on disk. |
| `test/scripts/android_safety_lane_test.dart` | Fixture tests for runner modes/evidence schema | `test/scripts/release_preflight_test.dart`; `test/scripts/ios_native_safety_lane_test.dart` | Temp fixtures, process exit/result assertions, production script sourced or invoked through narrow public helpers. |
| `scripts/release_preflight.sh` | Clean regeneration → signed packaging → artifact scan | Existing functions in the same file | `set -euo pipefail`, explicit ordered steps, separate dry-run, fail helper, no debug signing fallback. |
| `test/scripts/release_preflight_test.dart` | Ordering and rejection fixtures | Existing release-preflight tests | Index/order assertions plus deliberately contaminated registrant/artifact fixtures. |
| `android/settings.gradle.kts` | AGP/KGP plugin graph | Current file; selected state authority in `STABLE_BASELINE.json` | Exact versions only, no dynamic selectors, app/plugin graph changed atomically. |
| `android/gradle.properties` | Built-in Kotlin/new DSL terminal state | Flutter 3.44 migrator-generated flags | Both flags present on hold; both absent only on a fully selected graph. |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle distribution lock | Current wrapper | Exact HTTPS distribution matching terminal AGP lane. |
| `android/app/build.gradle.kts` | App Kotlin/DSL/signing contract | Current file | JDK 17, inherited minSdk 24, dedicated release config, `verifyReleaseSigning` dependency for every release artifact task. |
| `docs/testing/STABLE_BASELINE.json` | Machine-readable candidate/decision/blocker ledger | Existing Android host rows; Phase 59 plugin hold rows | Exact query date/source/candidate/decision/reason/exit condition; one owner phase. |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | Human explanation of machine ledger | Existing Android host row and hold sections | Describe, do not duplicate authority; distinguish candidate, selected, and hold. |
| `.github/workflows/device-e2e.yml` | Hosted API 36 Emulator integration lane | Current API 35 Android job | JDK 17 + Flutter 3.44.8 pin, x86_64, full `integration_test/`, clean post-test release metadata. |
| `test/architecture/device_e2e_contract_test.dart` | CI pin/API/test-matrix source contract | Existing tests in same file | Parse selected baseline, assert both platform pins, exact Android API/ABI and critical markers. |
| `61-ANDROID-SAFETY-EVIDENCE.md` | Redacted terminal evidence | `60-NATIVE-SAFETY-EVIDENCE.md`; `59-PLUGIN-ACCEPTANCE.md` | Separate compile/package/runtime/physical-device result classes; timestamps, commands, exit codes, hashes, no raw logs/secrets. |

## Concrete Reuse Rules

1. Extend `scripts/dependency_compatibility.dart` for durable baseline semantics; the new lane runner may orchestrate expensive tools but must not become a second version-policy authority.
2. Keep candidate edits inside a unique disposable copy. Never use `git checkout`, `git reset`, Pub-cache edits, generated registrant edits, or cache edits to restore the source tree.
3. Use the existing release signing environment names exactly: `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
4. Preserve `release_preflight.sh` ordering: clean, remove registrants, locked Pub retrieval, optional generation, release metadata/build, registrant scan, then packaging/packaged scan.
5. Mirror Phase 60 evidence semantics: a compile result cannot populate package or runtime status, an Emulator result cannot populate physical-device status, and unavailable evidence is explicit.
6. Architecture tests mutate strings/fixtures in memory and assert the checker rejects each unsafe state before the production implementation is loosened.

## Anti-Patterns to Reject

- A second Android version manifest or handwritten version constant that can drift from `STABLE_BASELINE.json`.
- AGP 9 in `settings.gradle.kts` while either legacy flag, KGP declaration, or resolved plugin KGP consumer remains.
- Updating Phase 59 plugin packages or Flutter 3.44.8 to clear the candidate blocker.
- An AAB-only result presented as both AAB and APK proof.
- Source grep presented as packaged artifact hygiene.
- A reused snapshot/dirty AVD presented as isolated runtime proof.
- Raw device serial, username/home path, keystore path/password, or unredacted command environment in planning evidence.

