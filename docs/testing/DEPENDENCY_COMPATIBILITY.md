# Dependency compatibility contract

[`STABLE_BASELINE.json`](./STABLE_BASELINE.json) is the canonical,
machine-readable production baseline. It records the execution-date toolchain
identity, every direct main/dev/SDK/path dependency, reviewed candidates,
official sources, decisions, holds, platform floors, prohibitions, and tracked
input digests. This document is deliberately a readable guide to that data; it
does not duplicate the JSON as a second source of truth.

Phase 57 selected Flutter `3.44.8` / Dart `3.12.2` on the Stable channel on
2026-08-05. The direct-dependency inventory and toolchain rows in the canonical
manifest distinguish `already_current` selections from owner-phase holds. A
hold is a successful safety decision, not a silent upgrade failure.

## Compatibility matrix

| Lane | Selected baseline | Candidate | Decision | Reason | Exit condition |
|---|---|---|---|---|---|
| Stable Flutter/Dart | Flutter `3.44.8`, Dart `3.12.2`, revision `058e0af2c2b57e369d905a03ac9748b0ebf543c6` | same | already current | The committed manifest, `.metadata`, Stable CI pin, running machine identity, and Flutter SDK source must agree. | Phase 58 rechecks and approves one coherent SDK/analyzer/codegen graph. |
| Xcode | Xcode `26.2` | Xcode `26.6` | hold — Phase 60 | Xcode can change SwiftPM/CocoaPods resolution, linker inputs, and signing; the encrypted iOS lane is proven with 26.2 and the SQLCipher Pod linker strip. | Phase 60 accepts 26.6 only after clean SwiftPM plus SQLCipher-only CocoaPods debug/profile/release builds and encrypted open/reopen, migration, and backup evidence without system SQLite fallback. |
| Encrypted storage | `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`, SQLCipher Pod `4.10.0` | `0.7.0+eol` / sqlite3 3.x | hold — Phase 60 | The EOL package ships no native SQLCipher library; the proven path needs the held Pod and linker strip. | Phase 60 proves a coordinated native upgrade on iOS and Android without system SQLite fallback. |
| iOS dependency manager | Flutter SwiftPM where supported; CocoaPods for SQLCipher | native-package replacement | hold — Phase 60 | The Podfile strip prevents system `sqlite3` from winning linker symbols. | Reviewed SQLCipher Swift package/plugin plus simulator and signed-device encryption evidence. |
| Analyzer/codegen | analyzer `8.4.0`, `custom_lint 0.8.1`, `import_guard_custom_lint 1.0.0`, Riverpod 3.1/4.0 generation stack, JSON tooling 4.9/6.11 | reviewed analyzer 9+/compatible stack | hold — Phase 58 | The import-boundary guard requires the single analyzer-8 graph; partial updates and split analyzer graphs are forbidden. | Upgrade lint/runtime/generators together, regenerate outputs, and pass architecture/custom-lint/full gates. |
| File/share/metadata | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | stable compatible cohort | hold — Phase 59 | New plus-plugin lines and file-picker behavior must be verified as one native cohort. | Upgrade the cohort together and preserve single-file backup import and platform sharing behavior. |
| Speech | `speech_to_text 7.3.0` | stable compatible release | hold — Phase 59 | The candidate changes adapter/test API and native symbols. | Clean native build plus Android microphone and iOS speech evidence. |
| Android host | AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, JDK 17 | AGP `9.0.1`, Gradle `9.1` | hold — Phase 61 | Built-in Kotlin/new DSL need a complete app and plugin migration. | Debug/release builds and emulator evidence after the all-or-hold migration. |
| Notifications/plugins | `flutter_local_notifications 22.2.0`, Firebase Core `4.13.0`, Messaging `16.5.0` | reviewed compatible cohort | hold — Phase 59 | Native plugin changes require coordinated behavior and clean-build evidence. | Registration, routing, cold-start tap, and signed APNs/FCM evidence. |
| Local Lucide icon subset | `lucide_icons_flutter 3.1.15+homepocket.1` from `third_party/` | not applicable until the local fork is re-reviewed | hold — Phase 59 | The local package preserves the upstream API with one static font and the 37 used codepoints instead of six unused variable-weight assets. | Phase 59 replaces or refreshes it only after reviewing upstream source/license and every icon reference, with static-subset and release tree-shaken asset checks green. |

The effective Android floor has two corroborating levels: `android/app/build.gradle.kts`
inherits `minSdk = flutter.minSdkVersion`, while the selected Stable
`.metadata`/CI pin identifies the same running SDK whose machine JSON and
`FlutterExtension.kt` declare the parsed default API `24`. iOS remains at
`15.0`. Baseline mode fails on any identity mismatch or lower effective floor.

## Riverpod analysis-plugin hold

`riverpod_lint 3.1.0` remains a direct, locked member of the Riverpod cohort,
but it is explicitly **held inactive** in `analysis_options.yaml`. On Flutter
`3.44.8` / analyzer `8.4.0`, its analysis-server route does not provide a
passing bad-example/control-example probe; configuring it as active would turn
an unloaded or protocol-failing plugin into a misleading green lint result.

The runnable production graph is therefore one analyzer-8 lane:
`custom_lint` plus `import_guard_custom_lint`, with the repository-owned
provider contract as the primary Riverpod app-root guard. That contract rejects
a `runApp` root without `ProviderScope` or `UncontrolledProviderScope`, checks
the initialized `AppRunner` root, and fails closed when `riverpod_lint` is
activated unexpectedly or its locked version cannot be parsed. The provider
audit reports this contract as `owned_provider_contract`; it must never report
zero findings after attempting to run an inactive upstream plugin.

The hold may be removed only in one production-graph transaction: the exact
Flutter/analyzer/Riverpod graph resolves without overrides; an official
compatibility probe shows no `PluginException`, `PluginEx`, `UNKNOWN_REQUEST`,
or version-parse failure; the upstream Riverpod bad fixture emits its expected
diagnostic while both `ProviderScope` and `UncontrolledProviderScope` controls
emit none; and two clean generation passes plus analyzer, custom-lint,
architecture, and full-suite gates pass. Until then, no `riverpod_lint` plugin
entry may be added to `analysis_options.yaml`.

## CI modes

Stable CI is the blocking production contract. Its static-analysis job pins the
manifest Flutter version, runs `flutter pub get --enforce-lockfile`, then runs:

```bash
dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
```

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
   `dependency_overrides`, plaintext SQLite, `sqlite3_flutter_libs`, or
   `sqlcipher_flutter_libs 0.7.0+eol` as a workaround.
3. Run `flutter pub get --enforce-lockfile` to retrieve the committed graph.
4. Run the running-SDK baseline validator, targeted contract tests, then the
   phase-final analysis, full-suite, coverage, and whitespace gates.

Phase 57 makes no dependency, lockfile, native configuration, generated Dart,
application behavior, or Drift schema/migration change. Phases 58–61 own the
Flutter/analyzer/codegen, plugin, SQLCipher/iOS, and Android migrations
respectively.
