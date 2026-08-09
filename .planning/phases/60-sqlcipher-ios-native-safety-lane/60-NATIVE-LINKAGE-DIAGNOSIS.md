---
phase: 60
plan: "08"
captured: 2026-08-09
classification: compile_only
runtime_proved: false
---

# Phase 60 Native Linkage Diagnosis

This record is compile-only evidence. It does not claim that the current-schema
SQLCipher lifecycle ran on a booted Simulator.

## Toolchain

| Item | Observed value |
| --- | --- |
| Flutter / Dart | Flutter 3.44.8 stable / Dart 3.12.2 |
| Flutter framework revision | `058e0af2c2` |
| Flutter engine revision | `0cd610717b` |
| Xcode | 26.2 (`17C52`) |
| CocoaPods | 1.16.2 |
| Build target | Runner, Debug, iOS Simulator, unsigned |

Host usernames, absolute build paths, Simulator identifiers, credentials, and
application data are intentionally omitted.

## Before Repair

The checked-in `AppDelegate.swift` implemented
`FlutterImplicitEngineDelegate.didInitializeImplicitFlutterEngine(_:)` and
registered `GeneratedPluginRegistrant`, but it had drifted from the locked
Flutter 3.44.8 template by omitting
`application(_:didFinishLaunchingWithOptions:)` and its delegation to
`super.application(...)`.

The Runner project already had exactly one
`FlutterGeneratedPluginSwiftPackage` product in the Runner Frameworks build
phase and exactly one Runner `packageProductDependencies` entry. No
source-controlled Xcode membership change was justified.

The fail-first contract command was:

```sh
flutter test test/architecture/ios_native_linkage_contract_test.dart -r expanded
```

It failed because the launch override was absent. The package-product assertion
passed after its test parser was made syntactically valid, so the RED state was
attributable to source lifecycle drift rather than Swift-package membership.

The clean native tracer used this supported sequence before changing Runner
source:

```sh
flutter clean
flutter pub get --enforce-lockfile
(cd ios && pod install --deployment)
flutter build ios --simulator --debug --no-codesign
```

Result: exit 0, `Runner.app` built. The historical undefined-symbol failure did
**not** reproduce from clean generated artifacts. Therefore the observed
undefined-symbol set for this run is empty, and this plan does not attribute the
historical failure to the missing override. The defensible diagnosis is that the
historical failure depended on stale/generated native state that clean supported
regeneration removed; the checked-in AppDelegate drift was a separate locked-
template contract defect.

An earlier sandboxed attempt stopped before Xcode because Flutter could not
write its shared SDK cache. It is excluded from native evidence; the command was
rerun with SDK-cache access and produced the result above.

## Source Repair

- Restored the locked Flutter 3.44.8
  `application(_:didFinishLaunchingWithOptions:)` override.
- Delegated launch handling to `super.application(...)` exactly as the locked
  template does.
- Preserved `FlutterImplicitEngineDelegate` and generated plugin registration
  through `engineBridge.pluginRegistry`.
- Left `project.pbxproj` unchanged because its generated Swift-package product
  membership was already singular and correctly attached to Runner Frameworks.
- Did not edit `.dart_tool/flutter_build`, `ios/Flutter/ephemeral`, generated
  `Package.swift`, or generated registrant output.

## After Repair

The focused contract passed:

```text
flutter test test/architecture/ios_native_linkage_contract_test.dart -r expanded
2 tests passed
```

The same clean supported native sequence was then rerun. Final build result:

```text
Xcode build done.
Built build/ios/iphonesimulator/Runner.app
exit 0
```

This proves one clean Debug-Simulator compile/link path for the source-controlled
Runner contract. It does not prove a booted-Simulator launch, SQLCipher identity,
sentinel persistence, or cold reopen; those remain the responsibility of plan
60-10.

## Source Inventory for Plan 60-09

| Seam | Final state |
| --- | --- |
| App launch override | Present and delegates to `super.application(...)` |
| Implicit-engine callback | Present |
| Generated plugin registration | Present through `engineBridge.pluginRegistry` |
| Runner Frameworks product | One `FlutterGeneratedPluginSwiftPackage` entry |
| Runner package dependency | One generated package product dependency |
| Generated-file edits | None |
| Runtime evidence | Not run / not claimed |

## Regression Contract

`ios_native_linkage_contract_test.dart` now checks the checked-in source and
executes focused in-memory mutations. It fails when any of these seams is
removed or duplicated:

- launch override;
- delegation to `super.application(...)`;
- implicit-engine callback;
- generated plugin registration;
- Runner Frameworks generated-package product membership; or
- Runner generated-package product dependency membership.

The plan referenced
`notification_stack_release_contract_test.dart` and
`no_apns_uat_contract_test.dart`, but neither file exists in this repository.
The same required release invariants are owned by the existing
`dependency_compatibility_contract_test.dart`,
`first_release_feature_contract_test.dart`, and
`ios_uat_identity_contract_test.dart`; those canonical tests were used rather
than creating duplicate notification contracts.

Final focused command:

```sh
flutter test \
  test/architecture/ios_native_linkage_contract_test.dart \
  test/architecture/ios_minimum_version_contract_test.dart \
  test/architecture/sqlcipher_native_assets_contract_test.dart \
  test/architecture/dependency_compatibility_contract_test.dart \
  test/architecture/first_release_feature_contract_test.dart \
  test/architecture/ios_uat_identity_contract_test.dart \
  -r expanded
```

Result: PASS, 103 tests. The suite retains iOS 15, the exact Native Assets
SQLCipher graph, notification-package removal, and the no-APNs production/UAT
surface.
