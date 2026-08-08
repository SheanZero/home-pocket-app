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
| Xcode | Xcode `26.2` | Xcode `26.6` | hold — Phase 60 | Xcode can change SwiftPM, Native Asset embedding, and signing. Xcode 26.2 clean-builds the signed device app with the embedded SQLCipher framework. | Accept a newer Xcode after clean simulator and signed-device builds plus encrypted fixture open/reopen evidence. |
| Encrypted storage | Drift `2.34.0`, sqlite3 `3.5.1`, SQLCipher Native Asset `4.17.x` | Drift `2.34.3` / drift_dev `2.34.5` | hold — analyzer lane | A genuine SQLCipher 4.10 fixture passes 4.17 identity, keyed status, schema read, v35→v36 migration, write, encrypted header, and cold reopen checks on Android and iOS simulator. | Move Drift when the analyzer-13 architecture-lint graph is coherent; retain the real-fixture device gate. |
| iOS dependency manager | Flutter SwiftPM plus sqlite3 Native Assets; CocoaPods has no SQLCipher pod | same | already current | `sqlcipher.framework` is embedded by the Native Assets hook and the fixture passes after removing the old `-lsqlite3` strip. | Re-run the signed physical-device runtime test after the device allows installation. |
| Analyzer/codegen | analyzer `12.1.0`, analyzer_plugin `0.14.8`, build `4.0.7`, source_gen `4.2.4`, Riverpod `3.3.2`/`4.0.3`/`4.0.4`/`3.1.4`, Freezed `3.1.0`/`3.2.6-dev.1`, JSON `4.12.0`/`6.14.1`, Drift `2.34.0`, build_runner `2.15.1`, import_lint `2.0.0`, dart_code_linter `4.1.9` | analyzer-13-compatible cohort | hold | `import_lint 2.0.0` requires analyzer `^12.1.0`; current newer Riverpod/Drift generator lines require analyzer 13. | All four analyzer/import-boundary exit conditions below must pass in one no-override transaction. |
| File/share/metadata | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | stable compatible cohort | hold — Phase 59 | New plus-plugin lines and file-picker behavior must be verified as one native cohort. | Upgrade the cohort together and preserve single-file backup import and platform sharing behavior. |
| Speech | `speech_to_text 7.3.0` | `7.4.0` Stable (the official page also lists `7.5.0-beta.1` as prerelease) | hold — Phase 59 | The 2026-08-09 official pub.dev query confirms the stable candidate, but resolver output cannot prove the adapter, ja/zh/en corpus, caller-controlled network fallback, or native speech lifecycle. | Keep `7.3.0` until adapter/corpus checks and physical-iPhone permission, recognition, cancellation, error, and fallback evidence pass. |
| Android host | AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, JDK 17 | AGP `9.0.1`, Gradle `9.1` | hold — Phase 61 | Built-in Kotlin/new DSL need a complete app and plugin migration. | Debug/release builds and emulator evidence after the all-or-hold migration. |
| Notifications/plugins | `flutter_local_notifications 22.2.0`, Firebase Core `4.13.0`, Messaging `16.5.0` | reviewed compatible cohort | hold — Phase 59 | Native plugin changes require coordinated behavior and clean-build evidence. | Registration, routing, cold-start tap, and signed APNs/FCM evidence. |
| Local Lucide icon subset | `lucide_icons_flutter 3.1.15+homepocket.1` from `third_party/` | not applicable until the local fork is re-reviewed | hold — Phase 59 | The local package preserves the upstream API with one static font and the 37 used codepoints instead of six unused variable-weight assets. | Phase 59 replaces or refreshes it only after reviewing upstream source/license and every icon reference, with static-subset and release tree-shaken asset checks green. |

The effective Android floor has two corroborating levels: `android/app/build.gradle.kts`
inherits `minSdk = flutter.minSdkVersion`, while the selected Stable
`.metadata`/CI pin identifies the same running SDK whose machine JSON and
`FlutterExtension.kt` declare the parsed default API `24`. iOS remains at
`15.0`. Baseline mode fails on any identity mismatch or lower effective floor.

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
4. Run the running-SDK baseline validator, targeted contract tests, then the
   phase-final analysis, full-suite, coverage, and whitespace gates.

The 2026-08-08 refresh raises the project Dart declaration to `^3.12.2` while
preserving the exact solver-produced lock graph. Native Asset configuration,
generated Dart, and database bootstrap remain Phase 60-owned. The committed
real SQLCipher 4.10 fixture is the regression baseline for future encryption
upgrades.

## Phase 59 speech evidence hold

The Phase 59 validator treats the current speech decision as a fail-closed
hold: its manifest row must retain execution-date `queried_on`, official source,
stable candidate, decision, compatibility reason, exit condition, and owner
phase, while the declared and resolved selection both remain exactly `7.3.0`.
The package page queried on 2026-08-09 identifies `7.4.0` as stable and
`7.5.0-beta.1` as a prerelease; the latter is ineligible for this production
lane. The redacted Phase 59 acceptance ledger separates automated adapter and
corpus evidence from the still-required physical-iPhone evidence rather than
treating an unavailable device as acceptance.
