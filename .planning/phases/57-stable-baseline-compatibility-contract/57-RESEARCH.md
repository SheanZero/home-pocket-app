# Phase 57: Stable Baseline & Compatibility Contract - Research

**Researched:** 2026-08-05  
**Domain:** Flutter/Dart dependency reproducibility and fail-closed native compatibility policy  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

No separate `## Decisions` subsection appears in `57-CONTEXT.md`.

### the agent's Discretion

<!-- DATA_G4t2Lq8M_START -->
- All implementation choices are at the agent's discretion — this is a pure infrastructure phase.
- “Latest” means the latest mutually compatible production-stable window rechecked against official primary sources on the execution date, not the largest version number.
- An evidence-backed hold is successful when its security/compatibility reason, exact version, official evidence, and exit condition are machine-checkable.
- Preserve iOS 15 and Android API 24 support, SQLCipher fail-closed behavior, the analyzer/import-boundary gate, and committed lockfile reproducibility.
- Do not change application behavior, generated source, native build outputs, or dependency versions beyond what is necessary to implement and test the baseline contract; later phases own those upgrades.
<!-- DATA_G4t2Lq8M_END -->

### Deferred Ideas (OUT OF SCOPE)

<!-- DATA_P7w9Cs1K_START -->
- Actual Flutter/analyzer/codegen upgrades belong to Phase 58.
- Plugin cohort changes belong to Phase 59; SQLCipher/iOS native proof to Phase 60; Android host migration to Phase 61.
<!-- DATA_P7w9Cs1K_END -->
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| BASE-01 | Record official current/candidate versions and query dates. | Commit a complete, dated canonical manifest; refresh it deliberately at execution. |
| BASE-02 | Keep manifests, lockfiles and native inputs reproducible. | Compare actual tracked inputs and use lockfile-enforced Pub resolution. |
| BASE-03 | Synchronize docs, checker and positive/negative tests. | Make the existing checker manifest-driven and add negative fixtures. |
| BASE-04 | Evidence every hold and reject unsafe inputs. | Schema requires evidence/reason/exit condition; validator rejects overrides, prerelease/EOL, and floor drift. |
</phase_requirements>

## Summary

Phase 57 should add one committed, machine-readable baseline manifest and make the existing checker consume it. The manifest is the canonical decision record; `docs/testing/DEPENDENCY_COMPATIBILITY.md` remains the concise human explanation. This addresses the present split-brain risk: the checker hard-codes selected historical strings and does not inventory every direct dependency or require hold evidence. [VERIFIED: scripts/dependency_compatibility.dart:27-172]

This is policy work, not an upgrade. Flutter Stable is the official production channel and its archive records the paired Dart version. [CITED: https://docs.flutter.dev/install/archive] Thus Flutter `3.44.7`/Dart `3.12`, AGP `9.0.1`/Gradle `9.1`/JDK `17`, and Xcode candidates belong as execution-time recheck rows, not Phase-57 config changes. [ASSUMED] AGP 9 enables built-in Kotlin/new DSL and requires a whole app/plugin migration, so it remains an all-or-hold Phase-61 lane. [CITED: https://developer.android.com/build/releases/agp-9-0-0-release-notes] [CITED: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin]

The SQLCipher hold is current, specific, and security-critical: `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`, SQLCipher Pod `4.10.0`. [VERIFIED: pubspec.yaml:70-75] [VERIFIED: ios/Podfile.lock:1-14] The publisher identifies `0.7.0+eol` as a no-op, while `0.6.8` supplies native SQLCipher libraries. [CITED: https://pub.dev/packages/sqlcipher_flutter_libs/versions] Preserve this hold until Phase 60 supplies equivalent native/device evidence.

**Primary recommendation:** Add `docs/testing/STABLE_BASELINE.json`, validate it through `scripts/dependency_compatibility.dart`, and leave dependency/native version changes to Phases 58–61.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Version decision/evidence | Repository policy | CI | Source control makes the decision reviewable and CI checks it against tracked inputs. |
| Pub graph reproducibility | Dependency resolver | CI | Pub lockfiles contain exact direct/transitive resolved versions. [CITED: https://docs.flutter.dev/packages-and-plugins/dependency-management] |
| Native baseline | Android/iOS build config | CI/macOS | Gradle, Pods and Xcode state are tracked native inputs. [VERIFIED: android/settings.gradle.kts:20-25] [VERIFIED: ios/Podfile.lock:1-33] |
| Enforcement | Contract script/test | `audit.yml` | Stable CI already calls the checker before analysis. [VERIFIED: .github/workflows/audit.yml:38-46] |

## Standard Stack

| Item | Version | Purpose | Why |
|---|---:|---|---|
| Existing `dart:convert` and `package:yaml` | Existing | Parse JSON baseline and Pub YAML | The existing checker already uses YAML; no package install is needed. [VERIFIED: scripts/dependency_compatibility.dart:1-25] |
| Existing `flutter_test` architecture test | Existing | Positive and synthetic negative contracts | Current test imports the script and reads repository inputs in-process. [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:1-38] |
| `flutter pub get --enforce-lockfile` | SDK command | Reproducibly retrieve locked graph | Pub fails rather than updating lockfile when exact versions/hashes cannot be satisfied. [CITED: https://dart.dev/tools/pub/packages] |
| `pod install` | Existing CocoaPods | Recreate locked Pods | `pod install` respects lockfile; `pod update` intentionally resolves newer versions. [CITED: https://guides.cocoapods.org/using/pod-install-vs-update.html] |

**Installation:** None; Phase 57 installs no external package, so no Package Legitimacy Audit is required.

## Architecture Patterns

### System Architecture Diagram

```text
official-source recheck (manual, dated)
             │
             ▼
docs/testing/STABLE_BASELINE.json ──► DEPENDENCY_COMPATIBILITY.md
             │                          (readable matrix)
             ▼
dependency_compatibility.dart ◄── pubspec / lock / Gradle / Pods / Xcode / CI
             │
             ├─ reject override, prerelease, EOL, partial lane, floor drift
             └─ architecture test ──► stable audit CI ──► Phases 58–61
```

### Recommended Project Structure

```text
docs/testing/STABLE_BASELINE.json                  # [ASSUMED] canonical data/evidence
docs/testing/DEPENDENCY_COMPATIBILITY.md           # human matrix and refresh process
scripts/dependency_compatibility.dart              # manifest-aware validator
test/architecture/dependency_compatibility_contract_test.dart # positive/negative fixtures
```

### Manifest schema

Use JSON, parsed by `dart:convert`; this is a proposed repository design, not a locked filename. [ASSUMED]

| Field | Required content / validation |
|---|---|
| `schema_version`, `queried_on`, `official_source_policy` | Supported schema and ISO date; official-primary-source policy. [ASSUMED] |
| `toolchains[]` | Flutter/Dart, Xcode, CocoaPods, JDK, Gradle, AGP and Android SDK rows: `current`, `latest_stable_candidate`, `decision`, source URL, date. The Flutter row also stores `framework_revision`, `channel`, and `flutter_extension_defaults.min_sdk`. [ASSUMED] |
| `direct_dependencies[]` | Exact inventory of each direct main/dev/SDK/path dependency with declared constraint, resolved value when applicable, candidate, source/date, decision. [ASSUMED] |
| `lanes[]` | All-or-hold members for SQLCipher, analyzer/codegen, file/share/metadata, speech, iOS manager, Android toolchain. [ASSUMED] |
| `holds[]` | `selected`, candidate, official URL, compatibility reason, exit condition, owner phase; validator rejects missing field. [ASSUMED] |
| `prohibitions`, `platform_floors` | Overrides, beta/RC/dev, EOL SQLCipher packages, iOS `15.0`, Android API `24`. [ASSUMED] |

### Deterministic Android API-24 proof

Use a two-level contract without changing `android/app/build.gradle.kts`:

1. **Hermetic source contract:** require `android/app/build.gradle.kts` to retain `minSdk = flutter.minSdkVersion`; require `.metadata` to contain the manifest's exact Stable channel and framework revision; require every pinned-Stable CI job to use the manifest's Flutter version. The current project contains `channel: "stable"` and revision `67323de285b00232883f53b84095eb72be97d35c`. [VERIFIED: .metadata:6-20] The current Android input is `minSdk = flutter.minSdkVersion`. [VERIFIED: android/app/build.gradle.kts:68-76]
2. **SDK-effective contract:** in `--mode=baseline`, run the discovered Flutter executable as `flutter --version --machine` and compare its framework revision/channel/version with the manifest; then parse `<flutter-root>/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`. Fail if either command/file is missing, values do not match, `val minSdkVersion: Int = <n>` cannot be parsed, or `<n> < 24`. The installed SDK source currently declares `val minSdkVersion: Int = 24`, with compile/target defaults `36`. [VERIFIED: /Users/xinz/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:21-34]

This avoids a Gradle build and generated native artifacts, while checking the exact SDK source that supplies the inherited value. The architecture test injects fixture text for `FlutterExtension.kt` so it is fully hermetic; Stable CI exercises the real resolved SDK. [ASSUMED]

### Anti-Patterns to Avoid

- **Hard-coded snapshots:** Current `expectConstraint`/`expectText` assertions cannot prove complete inventory or evidence. [VERIFIED: scripts/dependency_compatibility.dart:27-172]
- **Network-dependent audit:** Store a reviewed source snapshot; a new release must produce a reviewed manifest change, not surprise CI. [ASSUMED]
- **Untracked override:** Pub documents `pubspec_overrides.yaml` can override `dependency_overrides`, workspace and resolution. Reject its presence in baseline mode. [CITED: https://dart.dev/tools/pub/dependencies]
- **Native migration disguised as policy:** Do not change Android flags/version values. Flutter documents legacy KGP/DSL support as temporary; Phase 61 owns the complete migration. [CITED: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Dependency resolver | Custom version solver | `flutter pub get --enforce-lockfile` | It verifies locked versions/content hashes. [CITED: https://dart.dev/tools/pub/packages] |
| CocoaPods resolver | Bulk `pod update` | Committed lock + `pod install` | Locks preserve reviewed Pods. [CITED: https://guides.cocoapods.org/using/pod-install-vs-update.html] |
| SQLCipher replacement | Plain/system SQLite fallback | Existing held SQLCipher lane | The Podfile strips system SQLite so SQLCipher wins symbols. [VERIFIED: ios/Podfile:43-65] |

## Component Responsibilities

| File | Responsibility |
|---|---|
| `docs/testing/STABLE_BASELINE.json` | New canonical inventory, evidence, candidates, holds, lanes, floors, prohibitions. [ASSUMED] |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | Link canonical data; keep readable lane/risk/refresh explanation. [VERIFIED: docs/testing/DEPENDENCY_COMPATIBILITY.md:1-44] |
| `scripts/dependency_compatibility.dart` | Parse manifest and actual inputs; reject incomplete/mismatched policy. [VERIFIED: scripts/dependency_compatibility.dart:7-25] |
| `test/architecture/dependency_compatibility_contract_test.dart` | Green repository case plus in-memory negative fixtures. [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:40-97] |
| `.github/workflows/audit.yml` | Enforce lockfile then baseline contract under selected Stable Flutter; no version update in this phase. [ASSUMED] |

## Common Pitfalls

### Candidate turns into migration

**Avoid:** Keep `current`, `latest_stable_candidate`, `decision`, and `owner_phase` distinct; Phase 57 must not alter pub/lock/native/CI version values. [ASSUMED]

### Holds have prose but no exit condition

**Avoid:** Validator requires official URL/date, reason, and exit condition. Existing docs have an unblock column while script does not enforce it. [VERIFIED: docs/testing/DEPENDENCY_COMPATIBILITY.md:10-18] [VERIFIED: scripts/dependency_compatibility.dart:27-172]

### Beta lane corrupts Stable contract

**Avoid:** Keep security prohibitions blocking, but give the existing `channel: beta` workflow a distinct future-probe mode. `--mode=future-probe` exits nonzero for security failures (override, EOL/plain SQLite, missing linker safeguard, effective floor below 24), but emits a JSON/step-summary drift report and exits zero for expected version/SDK mismatch. It is an early warning, never baseline approval. [VERIFIED: .github/workflows/flutter-future-compat.yml:19-37] [ASSUMED]

### Linker safeguard removed as cleanup

**Avoid:** Continue validating Podfile strip and locked SQLCipher Pod; Phase 60 owns real simulator/device crypto proof. [VERIFIED: ios/Podfile:43-65] [VERIFIED: ios/Podfile.lock:1-14]

## Code Examples

```json
{
  "schema_version": 1,
  "queried_on": "YYYY-MM-DD",
  "toolchains": [{
    "id": "tool-name",
    "current": "resolved-value",
    "latest_stable_candidate": "verified-value",
    "decision": "hold-or-defer",
    "official_source_url": "https://official.example.invalid",
    "exit_condition": "later-phase evidence"
  }]
}
```

Schema skeleton only; it does not prescribe a new baseline value. [ASSUMED]

```bash
flutter pub get --enforce-lockfile
dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
git diff --check
```

`--enforce-lockfile` is the documented production retrieval mode. [CITED: https://dart.dev/tools/pub/packages]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | JSON file name/schema is the right canonical form. | Architecture | Low; planner can rename, but retain one source of truth. |

## Resolved Execution Decisions (formerly Open Questions)

1. **Official-version refresh — resolved:** Phase 57 has one first task: on its execution date, enumerate every direct dependency from `pubspec.yaml`, run `flutter pub outdated --json`, re-check each candidate only against its official maintainer/release source, and write `current`, candidate, URL and the actual `queried_on` date into the manifest. [VERIFIED: pubspec.yaml:9-124] [CITED: https://docs.flutter.dev/reference/flutter-cli] The normal checker never scrapes the network. Before any Phase 58–61 version-changing task, its preflight runs `--require-source-date YYYY-MM-DD` with that task's execution date; missing/mismatched source dates fail closed. [ASSUMED]
2. **Future probe — resolved:** Change the weekly beta workflow to call `--mode=future-probe --report <workspace-report-path>`. Security and floor violations remain hard failures; baseline-version drift produces a GitHub step summary plus uploaded JSON artifact and exits zero. Stable `audit.yml` alone runs `--mode=baseline --verify-running-flutter-sdk` and is the release-blocking contract. [VERIFIED: .github/workflows/audit.yml:38-46] [VERIFIED: .github/workflows/flutter-future-compat.yml:29-37] [ASSUMED]
3. **Android API-24 — resolved:** Do not edit the inherited `minSdk` declaration. Baseline mode verifies the tracked `.metadata` Stable revision/channel, the `minSdk = flutter.minSdkVersion` declaration, the pinned CI Flutter version, and the running SDK's `FlutterExtension.kt` parsed default. It fails closed on missing/mismatched SDK source or a value below `24`; unit fixtures cover all branches. [VERIFIED: .metadata:6-20] [VERIFIED: android/app/build.gradle.kts:68-76] [VERIFIED: /Users/xinz/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:21-34]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Flutter/Dart | Resolver/test | ⚠ | Installed but sandboxed invocation cannot write Flutter cache | CI/writable SDK cache |
| CocoaPods | iOS configuration | ✓ | `1.16.2` [VERIFIED: ios/Podfile.lock:31-33] | None for Phase 60 native resolution |
| Xcode | iOS inspection | ✓ | `26.2` [VERIFIED: local `xcodebuild -version`, 2026-08-05] | CI macOS for non-device checks |
| JDK / Gradle CLI | Android later phase | ✗ | Java runtime and standalone Gradle unavailable | CI JDK 17 + wrapper |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | `flutter_test` [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:1-5] |
| Quick command | `flutter test test/architecture/dependency_compatibility_contract_test.dart` |
| Full suite | `flutter test --concurrency=1` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Command | File Exists? |
|---|---|---|---|---|
| BASE-01 | Complete evidence/hold/direct-inventory validation | Contract | targeted test | ❌ extend current |
| BASE-02 | Inputs match manifest; Pub cannot mutate lock; effective inherited Android floor is at least API 24 under the pinned SDK. | contract + smoke | `flutter pub get --enforce-lockfile && dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ❌ |
| BASE-03 | Green current state plus invalid lanes rejected | Contract | targeted test | ✅ extend current |
| BASE-04 | prerelease/EOL/overrides/floor drift rejected | Contract | targeted test | ❌ extend current |

### Negative Fixtures

Keep fixture mutations in-memory, matching the current test pattern. [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:8-38]

1. Missing direct-dependency manifest row.
2. Candidate/selected `-beta`, `-rc`, or `-dev` value.
3. `sqlcipher_flutter_libs 0.7.0+eol` and `sqlite3_flutter_libs`.
4. `dependency_overrides` and present `pubspec_overrides.yaml`.
5. One changed member of file/share or analyzer/codegen lane.
6. Missing Podfile strip/SwiftPM marker, changed SQLCipher Pod, iOS floor or Android floor below policy.
7. Missing/mismatched `.metadata` revision/channel, missing SDK `FlutterExtension.kt`, malformed `minSdkVersion`, and SDK `minSdkVersion` below `24`.
8. Missing Stable CI call, or future beta job using baseline mode rather than `future-probe` report mode.

### Sampling Rate

- **Per commit:** targeted contract test.
- **Per wave:** enforced Pub resolution, running-SDK floor checker, `flutter analyze`.
- **Phase gate:** full suite plus `git diff --check`; do not claim native/device proof here.

### Wave 0 Gaps

- [ ] New baseline manifest.
- [ ] Manifest-aware validator and test fixtures.
- [ ] Stable-CI enforced-lockfile/running-SDK step and future-probe JSON/step-summary/artifact semantics.

## Security Domain

| ASVS Category | Applies | Control |
|---|---|---|
| V1 Architecture | Yes | One reviewable baseline and owned hold decisions. [CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V5 Validation | Yes | Strict manifest/YAML schema and required fields. [CITED: https://devguide.owasp.org/en/06-verification/01-guides/03-asvs/] |
| V6 Stored Cryptography | Yes | Preserve SQLCipher package/Pod/linker invariants. [VERIFIED: scripts/dependency_compatibility.dart:48-59] |
| V10 Malicious Code | Yes | Official evidence + enforced lockfile reduce unreviewed dependency changes. [CITED: https://dart.dev/tools/pub/packages] |
| V14 Configuration | Yes | CI and local override controls are validated. [CITED: https://devguide.owasp.org/en/06-verification/01-guides/03-asvs/] |

## Plan Split Recommendation

### Plan 57-01: Baseline artifact and human decision record

Create the manifest from re-queried official sources and update documentation. Capture every direct input and hold, but make no version/native/generated/lockfile migration.

### Plan 57-02: Fail-closed executable contract

Refactor the checker to validate the manifest, add all negative fixtures, wire lockfile enforcement to Stable CI, and give beta an explicit future-probe behavior. Run targeted/full validation. This plan depends on 57-01.

## Sources

### Official sources

- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Flutter built-in Kotlin migration](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)
- [AGP 9.0.1 release notes](https://developer.android.com/build/releases/agp-9-0-0-release-notes)
- [Dart Pub packages / enforced lockfile](https://dart.dev/tools/pub/packages)
- [Dart dependency overrides](https://dart.dev/tools/pub/dependencies)
- [CocoaPods install versus update](https://guides.cocoapods.org/using/pod-install-vs-update.html)
- [SQLCipher Flutter package versions](https://pub.dev/packages/sqlcipher_flutter_libs/versions)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)

### Project sources

- `pubspec.yaml`, `pubspec.lock`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`
- `scripts/dependency_compatibility.dart`, `test/architecture/dependency_compatibility_contract_test.dart`
- `.github/workflows/{audit,flutter-future-compat,device-e2e}.yml`
- `android/`, `ios/Podfile`, `ios/Podfile.lock`, `ios/Runner.xcodeproj/project.pbxproj`

## Metadata

**Confidence breakdown:** Standard stack HIGH; architecture MEDIUM (manifest naming/modes are proposed); pitfalls HIGH for current SQLCipher/CI evidence and MEDIUM for future-probe design.  
**Valid until:** Re-query official candidate rows on the Phase-57 execution date; the contract design remains valid for 30 days.
