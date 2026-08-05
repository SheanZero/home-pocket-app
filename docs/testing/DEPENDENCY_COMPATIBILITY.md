# Dependency and future Flutter compatibility

P2-04 is managed as coordinated native dependency lanes, not as a blanket
`pub upgrade --major-versions`. The blocking contract is
`dart run scripts/dependency_compatibility.dart`; the weekly
`flutter-future-compat` workflow builds Android and iOS with Flutter beta.

## Current compatibility matrix

| Lane | Verified versions | Why this is intentional | Unblock condition |
|---|---|---|---|
| Encrypted database | `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`, SQLCipher pod `4.10.0` | `sqlcipher_flutter_libs 0.7.0+eol` contains no native library. sqlite3 3.x is outside the proven encrypted path. | An ADR-approved replacement or maintained plugin with iOS SwiftPM support, followed by real-device `PRAGMA cipher_version`, encrypted reopen, migration, and backup/restore evidence. |
| iOS dependency manager | Flutter SwiftPM for supported plugins; CocoaPods only for SQLCipher | Flutter 3.44 still falls back for the one plugin without a package manifest. The Podfile strip prevents system sqlite3 from winning linker symbols. | Move SQLCipher to its official Swift package through a reviewed plugin/fork, then repeat iOS simulator and signed-device SQLCipher tests. Do not disable SwiftPM project-wide. |
| File/share/package metadata | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | New plus plugins require win32 6.x; the latest stable file_picker 11 requires win32 5.x. file_picker 12 is currently prerelease and changes selection defaults. | A stable file_picker 12+ release. Upgrade all four packages together and explicitly keep single-file backup import semantics. |
| Speech | exact `speech_to_text 7.3.0` | 7.4.0 was published from a beta line and changes the adapter/test API. Native version switching also requires a clean build to avoid stale Kotlin symbols. | A stable compatible release plus voice adapter, Android microphone, and iOS speech tests. |
| Android toolchain | Flutter `3.44.0`, AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, `android.builtInKotlin=false`, `android.newDsl=false` | Flutter's migration guide requires Flutter 3.47+ before enabling Built-in Kotlin. Current compatible package refresh reduced KGP warnings from seven plugins to four. | On Flutter 3.47+, migrate the app and every remaining plugin together, set Built-in Kotlin only after both debug/release builds and device E2E pass. |
| Notifications and compatible plugins | `flutter_local_notifications 22.2.0`, Firebase Core `4.13.0`, Firebase Messaging `16.5.0`, plus the versions in `pubspec.lock` | These upgrades resolve within current stable constraints and passed host tests plus Android/iOS builds. | Continue ordinary compatible refreshes; any native plugin version switch starts with `flutter clean`. |

The current Flutter warning names `file_picker`, `package_info_plus`,
`share_plus`, and `speech_to_text`. It is not suppressed. The file picker
stable line is already conditional for AGP 9; the other packages remain held by
the coordinated constraints above. The beta workflow becomes the early failure
signal when Flutter changes a warning into an error.

## Required upgrade procedure

1. Upgrade one compatibility lane at a time; never replace SQLCipher with
   `sqlite3_flutter_libs` or the `0.7.0+eol` placeholder.
2. Run `flutter clean` after changing a native plugin version, then
   `flutter pub get` and `dart run scripts/dependency_compatibility.dart`.
3. Run `flutter analyze`, custom lint, affected tests, and the full host suite.
4. Build Android and iOS. For database or linker changes, run device E2E on
   both platforms and confirm a non-empty `PRAGMA cipher_version` after closing
   and reopening the encrypted file.
5. For the file/share group, verify backup import selects exactly one `.hpb`
   file and export still opens the platform share sheet.
6. For notifications, verify registration, foreground routing, cold-start tap,
   and signed APNs/FCM delivery evidence before release.
7. Update this matrix and the executable contract in the same commit. A version
   change without updated rationale is expected to fail CI.
