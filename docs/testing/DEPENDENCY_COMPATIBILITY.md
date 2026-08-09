# Dependency compatibility contract

[`STABLE_BASELINE.json`](./STABLE_BASELINE.json) is the canonical,
machine-readable production baseline. It records the execution-date toolchain
identity, every direct main/dev/SDK/path dependency, reviewed candidates,
official sources, decisions, holds, platform floors, prohibitions, and tracked
input digests. This document is deliberately a readable guide to that data; it
does not duplicate the JSON as a second source of truth.

Phase 57 selected Flutter `3.44.8` / Dart `3.12.2` on the Stable channel on
2026-08-05. The 2026-08-08 official Flutter release-manifest recheck found
Flutter `3.44.9` (still Dart `3.12.2`) as the newer Stable candidate; it is a
documented hold until a full identity transaction verifies every SDK surface.
The direct-dependency inventory and toolchain rows in the canonical manifest
distinguish `already_current` selections from owner-phase holds. A hold is a
successful safety decision, not a silent upgrade failure.

## Compatibility matrix

| Lane | Selected baseline | Candidate | Decision | Reason | Exit condition |
|---|---|---|---|---|---|
| Stable Flutter/Dart | Flutter `3.44.8`, Dart `3.12.2`, revision `058e0af2c2b57e369d905a03ac9748b0ebf543c6` | Flutter `3.44.9`, Dart `3.12.2` | hold — Phase 58 | The committed manifest, `.metadata`, Stable CI pin, running machine identity, and Flutter SDK source must agree; a patch cannot change just one identity surface. | Review one identity transaction, retain the exact analyzer cohort without overrides, pass D-04 negative fixtures, and obtain an unexplained-diff-free D-08/D-09 two-pass generation result. |
| Xcode | Xcode `26.2` | Xcode `26.6` | hold — Phase 60 | Xcode changes SwiftPM, Native Asset embedding, and unsigned compilation. The selected lane must retain its locked graph while proving iOS 15 in Runner, CocoaPods, SwiftPM, and the generated plugin package. | Accept a newer Xcode only after retained-lock and disposable from-zero resolution agree, all six unsigned Simulator/generic-device Debug/Profile/Release builds pass, and separately recorded Simulator runtime evidence proves the encrypted fixture path. |
| Encrypted storage | Drift `2.34.0`, sqlite3 `3.5.1`, SQLCipher Native Assets `4.17.x` | Drift `2.34.3` / drift_dev `2.34.5` | hold — Phase 60 | The sqlite3 hook selects SQLCipher Native Assets. Source/config, lock, Pod, linker, and generated-floor checks must reject both retired Flutter libraries, a separate SQLCipher CocoaPod, system/plain SQLite, and the obsolete linker strip. | Move Drift only when the analyzer-13 architecture-lint graph is coherent and the exact replacement completes retained-lock/from-zero resolution, six unsigned compile checks, and separate encrypted Simulator runtime evidence. |
| iOS dependency manager | Flutter SwiftPM plus sqlite3 Native Assets; CocoaPods has no SQLCipher pod | same | hold — Phase 60 | `sqlcipher.framework` is embedded by the Native Assets hook; the generated `FlutterGeneratedPluginSwiftPackage` is a post-generation input and must declare iOS 15.0. Compilation is compile-only and never SQLCipher runtime acceptance. | Regenerate through supported Flutter tooling, pass the generated-package iOS-floor validator, then retain separate Simulator runtime SQLCipher open/reopen, migration, and backup evidence. |
| Analyzer/codegen | analyzer `12.1.0`, analyzer_plugin `0.14.8`, build `4.0.7`, source_gen `4.2.4`, Riverpod `3.3.2`/`4.0.3`/`4.0.4`/`3.1.4`, Freezed `3.1.0`/`3.2.6-dev.1`, JSON `4.12.0`/`6.14.1`, Drift `2.34.0`, build_runner `2.15.1`, import_lint `2.0.0`, dart_code_linter `4.1.9` | analyzer-13-compatible cohort | hold | `import_lint 2.0.0` requires analyzer `^12.1.0`; current newer Riverpod/Drift generator lines require analyzer 13. | All four analyzer/import-boundary exit conditions below must pass in one no-override transaction. |
| File/share/metadata | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | stable compatible cohort | hold — Phase 59 | New plus-plugin lines and file-picker behavior must be verified as one native cohort. | Upgrade the cohort together and preserve single-file backup import and platform sharing behavior. |
| Speech | `speech_to_text 7.3.0` | `7.4.0` Stable (the official page also lists `7.5.0-beta.1` as prerelease) | hold — Phase 59 | The 2026-08-09 official pub.dev query confirms the stable candidate, but resolver output cannot prove the adapter, ja/zh/en corpus, caller-controlled network fallback, or native speech lifecycle. | Keep `7.3.0` until adapter/corpus checks and physical-iPhone permission, recognition, cancellation, error, and fallback evidence pass. |
| Android host | AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, JDK 17 | AGP `9.0.1`, Gradle `9.1` | hold — Phase 61 | Built-in Kotlin/new DSL need a complete app and plugin migration. | Debug/release builds and emulator evidence after the all-or-hold migration. |
| Notifications/plugins | `flutter_local_notifications 22.2.0`, Firebase Core `4.13.0`, Messaging `16.5.0` | Firebase rows already-current; local notifications `22.3.0` candidate | hold — Phase 59 | Android initializes Firebase for FCM; iOS skips Firebase and keeps the custom APNs bridge. Native plugin changes require complete attributable lifecycle evidence without exposing settings. | PASS automated lifecycle plus supported Android-FCM and custom-iOS-APNs builds for initialization/retry/foreground/opened/tap/cold-start, while auto-init, entitlements, hidden settings, and disclosed cloud fallback remain unchanged. |
| Biometric app lock | `local_auth 3.0.2` | `3.0.2` Stable | hold — Phase 59 | The official package permits passcode fallback unless `biometricOnly` is true; this app owns its own Argon2id PIN and must never accept the OS device passcode as app-lock authentication. | Keep the exact graph until a safe non-production supported build records redacted Face ID success plus cancel/false, temporary-lockout, biometric-lockout, platform-error, unknown-error, and reachable app-PIN fallback observations. |
| Local Lucide icon subset | `lucide_icons_flutter 3.1.15+homepocket.1` from `third_party/` | not applicable until the local fork is re-reviewed | hold — Phase 59 | The local package preserves the upstream API with one static font and the 37 used codepoints instead of six unused variable-weight assets. | Phase 59 replaces or refreshes it only after reviewing upstream source/license and every icon reference, with static-subset and release tree-shaken asset checks green. |

The effective Android floor has two corroborating levels: `android/app/build.gradle.kts`
inherits `minSdk = flutter.minSdkVersion`, while the selected Stable
`.metadata`/CI pin identifies the same running SDK whose machine JSON and
`FlutterExtension.kt` declare the parsed default API `24`. iOS remains at
`15.0` in Runner, CocoaPods, SwiftPM, and the generated plugin package. The
generated package is inspected only after supported regeneration; a missing
manifest is labelled compile-only and is neither generated-floor proof nor
runtime encryption evidence. Baseline mode fails on any identity mismatch or
lower supplied floor.

## Analyzer plugin lane

`riverpod_lint 3.1.4` and `import_lint 2.0.0` are active top-level
analysis-server plugins in `analysis_options.yaml`. The old `custom_lint` and
`import_guard_custom_lint` dependencies are removed. Repository-owned
architecture and provider-root tests remain defense in depth.

The production graph intentionally stops at analyzer `12.1.0` with
analyzer_plugin `0.14.8`, build `4.0.7`, and source_gen `4.2.4`: current newer
Drift/Riverpod generator lines require analyzer 13, while import_lint `2.0.0`
requires analyzer `^12.1.0`. The old `custom_lint` and
`import_guard_custom_lint` packages are intentionally absent. The whole
analyzer/runtime/generator/lint cohort must move together; partial upgrades are
not accepted.

The analyzer/import-boundary hold may end only when all four conditions are
met in one review:

1. An officially published import-boundary successor accepts the intended newer analyzer major.
2. Pub resolves the complete SDK/Riverpod/Freezed/JSON/Drift/build_runner/lint graph without `dependency_overrides` or `pubspec_overrides.yaml`.
3. The D-04 deliberately invalid import and Riverpod fixtures still fail closed.
4. The D-08/D-09 two-pass generation oracle leaves no unexplained tracked diff.

## CI modes

Stable CI is the blocking production contract. The static-analysis job has one
sole Stable static-analysis entry:

```bash
bash scripts/verify_codegen_reproducibility.sh
```

The wrapper owns locked resolution, baseline validation, two clean generation passes
(localization and build-runner), then analyzer, active import/Riverpod lint,
architecture contracts, reversible negative-tooling checks, and whitespace
verification. Run direct validator commands only for local diagnosis; they are
not an alternate Stable CI path. The separate guardrails and coverage jobs each
run `flutter pub get --enforce-lockfile` before their own checks because every
independent Stable Flutter job must retrieve the committed graph.

The weekly beta workflow is visibly a non-production future probe. Both Android
and iOS beta jobs retain ordinary `flutter pub get` and real build commands, but
use `--mode=future-probe --verify-running-flutter-sdk`. That mode may report
ordinary direct-dependency candidate drift as a warning only. It never demotes
overrides, prerelease/EOL or plaintext SQLCipher states, partial lanes, or iOS/
Android floor failures: those remain blocking errors.

## Refresh transaction

For an owner-phase upgrade, perform this transaction as one reviewed change:

1. Recheck the candidate only at its official source and update the canonical
   manifest with the actual query date, decision, reason, and exit condition.
2. Update only the owning manifest/dependency/native inputs; do not use
   `dependency_overrides`, plaintext SQLite, `sqlite3_flutter_libs`, or the
   obsolete `sqlcipher_flutter_libs` path as a workaround.
3. Run `flutter pub get --enforce-lockfile` to retrieve the committed graph.
4. Run the running-SDK baseline validator and targeted contract tests. After
   supported Flutter regeneration, pass
   `--generated-swift-package-manifest=<path>` to prove the generated iOS 15
   floor; this remains compile-only and cannot replace Simulator runtime proof.
5. Run the phase-final analysis, full-suite, coverage, and whitespace gates.

The 2026-08-08 refresh raises the project Dart declaration to `^3.12.2` while
preserving the exact solver-produced lock graph. Native Asset configuration,
generated Dart, and database bootstrap remain Phase 60-owned. The committed
real SQLCipher 4.10 fixture is the regression baseline for future encryption
upgrades.

## Phase 59 speech evidence hold

The Phase 59 validator makes the speech decision binary and fail closed. Its
manifest row retains execution-date `queried_on`, official source, a
production-stable candidate, decision, compatibility reason, exit condition,
owner phase, and the complete redacted evidence-result matrix. The package page
queried on 2026-08-09 identifies `7.4.0` as stable and `7.5.0-beta.1` as a
prerelease; the latter is ineligible for this production lane. A `hold` requires
both declaration and lock resolution to stay exactly `7.3.0`. An `accepted`
decision requires PASS for automated proof, supported native build, physical
iPhone permission, ja/zh/en recognition, cancellation, surfaced error,
on-device recognition, and both caller-controlled fallback branches, then
requires declaration and lock resolution to equal the stable candidate. Missing,
UNAVAILABLE, FAILED, or partial native evidence cannot produce an accepted
graph. The redacted ledger therefore separates automated adapter/corpus proof
from physical-iPhone evidence rather than treating a simulator, resolver, or
unavailable device as acceptance.

The current terminal record is `hold`: the adapter and ja/zh/en corpus matrix
passes on the exact `7.3.0` declaration and lock resolution, while every native
candidate-build and physical-iPhone field is `UNAVAILABLE`. A detected device
is not used as evidence without a Phase-59-attributable, pre-authorized
non-production candidate identity; the later isolated wired-iPhone UAT lane is
not a substitute for this selection decision.

## Phase 59 platform-plugin inventory

The Phase 59 validator owns a lexical inventory of every direct, platform-backed
plugin under this cohort: `connectivity_plus`, `file_picker`, Firebase Core and
Messaging, `flutter_local_notifications`, `flutter_secure_storage`,
`image_picker`, `local_auth`, the local Lucide fork, `package_info_plus`,
`path_provider`, `share_plus`, `speech_to_text`, and `url_launcher`. Its
significant transitive `win32` row is kept with the file/share lane. Each row
records the package identity, official source, 2026-08-09 query date, exact
selected graph, stable candidate, Phase 59 owner, decision, and a hold reason
plus exit condition where native evidence remains unavailable.

The four-member file/share cohort is deliberately exact and ordered:
`file_picker 11.0.3`, `package_info_plus 9.0.1`, `share_plus 12.0.2`, and
transitive `win32 5.15.0`. Pub.dev currently lists `file_picker 11.0.3`,
`share_plus 13.3.0`, `package_info_plus 10.2.1`, and `win32 6.4.0`; newer
members are candidates only. A declaration or lock mutation of any selected
member, a missing member, duplicate identity, empty evidence field, or
non-lexical inventory fails before resolution.

On 2026-08-09, the official package pages and changelogs were rechecked.
`file_picker 11.0.3` remains the stable release and its native picker supports
custom extension filtering. `share_plus 13.3.0` and `package_info_plus 10.2.1`
both require Java 17, Kotlin 2.2.0, AGP 8.12.1, and Gradle 8.13; their 13/10
major lines also move the transitive `win32` dependency from 5.15.0 to 6.0.0+.
The selected Android lane remains on AGP 8.11.1 and this execution environment
has no Java 17, Android destination, or usable iOS Simulator. Therefore the
single cohort decision is `hold`: the manifest and validator reject an
independent declaration or lock mutation, and no solver result is accepted
without the complete native evidence exit condition.

Official execution-date candidates retained as holds include
`flutter_secure_storage 11.0.0`, `flutter_local_notifications 22.3.0`, and
the stable `speech_to_text 7.4.0`; Firebase Core `4.13.0`, Firebase Messaging
`16.5.0`, `local_auth 3.0.2`, `image_picker 1.2.3`, `path_provider 2.1.6`,
`connectivity_plus 7.3.1`, and `url_launcher 6.3.2` remain the current stable
candidates but are not accepted without their described native evidence. The
Lucide path fork has no registry candidate: its official upstream source and
license, static subset, and used-codepoint contract remain mandatory evidence.
No candidate is a resolver instruction, and missing JDK, Android, simulator,
physical-iPhone, or existing-key evidence is always a hold rather than a pass.

## Phase 59 biometric app-lock evidence hold

The official `local_auth` package page and changelog were rechecked on
2026-08-09. `3.0.2` remains the production-stable candidate and matches the
selected declaration and lock resolution. The official usage documentation says
that `authenticate` otherwise permits PIN, pattern, or passcode fallback, and
requires `biometricOnly: true` to require biometrics. Its 3.0.0 changelog also
records the direct `authenticate` parameters, `persistAcrossBackgrounding`, and
structured `LocalAuthException` behavior used by the app boundary.

This project therefore holds the exact `3.0.2` graph, rather than calling it
accepted: `BiometricService` must forward `biometricOnly`,
`sensitiveTransaction`, and `persistAcrossBackgrounding` as true; every
unsupported, unenrolled, cancel/false, temporary-lockout, biometric-lockout,
`LocalAuthException`, `PlatformException`, and residual exception path must
leave the app PIN reachable. The machine contract rejects missing official
source/query/candidate/decision data, missing secure-option proof, any
passcode-policy mutation, incomplete fallback evidence, a selected declaration
or lock drift, and an accepted decision without complete PASS native evidence.

Native acceptance is deliberately `UNAVAILABLE` in this lane. No safe
non-production supported iPhone identity and no Phase-59-attributable Face ID
success/failure-to-app-PIN observation is available, and Phase 63 wired-iPhone
UAT is not a substitute. Acceptance requires a redacted supported-build record
for Face ID success, cancel/false, both lockouts, platform and unknown errors,
and app-PIN fallback; it must never record a PIN, biometric material, device
identifier, Keychain item, financial data, or production credential.

## Phase 59 secure-storage persisted-key evidence hold

The official `flutter_secure_storage` package page and changelog were
rechecked on 2026-08-09. `11.0.0` is the current stable major. Its changelog
removes legacy Android cipher paths and warns that data saved with removed
algorithms/features can become unusable unless it was migrated through v10.
That publisher migration information is not an app-specific read-then-rewrite
design for this app's persisted master key, nor is it proof that an existing
`unlocked_this_device` Keychain item and its encrypted database remain
readable.

The selected declaration and lock remain exactly `flutter_secure_storage
10.3.1`. The hold preserves `KeychainAccessibility.unlocked_this_device`, the
established Android options, one `SecureStorageService`/crypto key-manager
boundary, and AppInitializer's key-before-database fail-closed guard. Fresh
install, resolver, or source-only checks cannot accept the major. The baseline
validator rejects a changed accessibility value, direct declaration/lock drift,
or an accepted major without a named `read_then_rewrite` migration and PASS
prior-build existing-key plus existing-encrypted-database startup evidence.

Exit only after an approved migration reads each existing key using the current
options, rewrites it under the reviewed candidate options without minting a
replacement, and records redacted PASS evidence on every supported native
platform that the prior-build key and database open successfully. Until then,
the unavailable existing-key/device result is an explicit exact-10.3.1 hold;
Phase 60 SQLCipher/iOS-native safety and Phase 63 isolated-device acceptance
remain outside this lane.
