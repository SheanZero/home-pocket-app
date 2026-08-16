---
phase: 59
plan: "01"
status: in_progress
redaction: required
---

# Phase 59 Plugin Acceptance Ledger

This ledger records decision evidence only. Do not add transcripts, recognized
speech, tokens, keys, database paths, device identifiers, financial values, or
production credentials.

## Official evidence

| queried_on | package | selected | candidate | decision | official source | result |
|---|---|---|---|---|---|---|
| 2026-08-09 | file_picker | 11.0.3 | 11.0.3 Stable | hold | https://pub.dev/packages/file_picker | Current stable is retained pending atomic native evidence. |
| 2026-08-09 | share_plus | 12.0.2 | 13.3.0 Stable | hold | https://pub.dev/packages/share_plus | Candidate requires newer native-toolchain and cohort evidence. |
| 2026-08-09 | package_info_plus | 9.0.1 | 10.2.1 Stable | hold | https://pub.dev/packages/package_info_plus | Candidate is not selected independently of file/share/win32. |
| 2026-08-09 | win32 | 5.15.0 transitive | 6.4.0 Stable | hold | https://pub.dev/packages/win32 | Current file-picker graph requires the exact selected transitive member. |
| 2026-08-09 | speech_to_text | 7.3.0 declared/resolved | 7.4.0 Stable; 7.5.0-beta.1 ineligible | hold | https://pub.dev/packages/speech_to_text | Stable candidate rechecked; no resolver change made. |
| 2026-08-09 | flutter_local_notifications | 22.2.0 | 22.3.0 Stable | hold | https://pub.dev/packages/flutter_local_notifications | Lifecycle/native evidence is unavailable. |
| 2026-08-09 | firebase_core / firebase_messaging | 4.13.0 / 16.5.0 | 4.13.0 / 16.5.0 Stable | hold | https://pub.dev/packages/firebase_core ; https://pub.dev/packages/firebase_messaging | Selected versions retain a split Android-FCM / custom-iOS-APNs policy pending native evidence. |
| 2026-08-09 | local_auth / flutter_secure_storage | 3.0.2 / 10.3.1 | 3.0.2 / 11.0.0 Stable | hold | https://pub.dev/packages/local_auth ; https://pub.dev/packages/flutter_secure_storage | App-PIN fallback and existing-key evidence remain required. |
| 2026-08-09 | image_picker / path_provider / url_launcher / connectivity_plus | 1.2.3 / 2.1.6 / 6.3.2 / 7.3.1 | same Stable | hold | official pub.dev package pages | Current platform behavior lacks attributable native acceptance evidence. |
| 2026-08-09 | lucide_icons_flutter path fork | 3.1.15+homepocket.1 static subset | not applicable | hold | https://github.com/lucide-icons/lucide | Upstream source/license and local static-subset contract rechecked; no fork change made. |

All official-source checks above are candidate evidence, not permission to
resolve or accept a package. The manifest validator is green at `b59fbf16` and
retains the exact selected dependency graph.

## File/share/package acceptance evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| c0703166 / 165dc76e | file_picker 11.0.3 / share_plus 12.0.2 / package_info_plus 9.0.1 / win32 5.15.0 | Dart | repository contract | n/a | test | pass | atomic membership/declaration/lock/evidence mutations; `.hpb` picker/restore; backup-file share; both invite text-share callers | PASS — automated contract green | Automated checks do not exercise OS-owned UI or package identity. | Keep the exact graph until all supported native observations are attributable. |
| 03bebfe8 | file_picker 11.0.3 | Android | no emulator or device available | not recorded | not run | `java -version`; Android destination probe | picker cancel, select one `.hpb`, and encrypted import | UNAVAILABLE — hold | No JDK 17 runtime and no Android emulator/device. | With JDK 17, run a clean Android build and record redacted cancel/select/import outcomes. |
| 03bebfe8 | file_picker 11.0.3 | iOS | supported destinations listed, not exercised | iOS 26.5 family | not run | destination listing only | picker cancel, select one `.hpb`, and encrypted import | UNAVAILABLE — hold | The all-platform atomic probe stops before iOS testing because the Android/JDK prerequisite is missing. | After the Android prerequisite is met, run a clean supported-iOS build and record redacted picker outcomes. |
| 03bebfe8 | share_plus 12.0.2 | Android/iOS | no attributable native share destination | not recorded | not run | prerequisite probe only | present encrypted-backup file and both family-invite text share sheets | UNAVAILABLE — hold | No complete native build matrix; no real share sheet was observed. | Record redacted presentation and dismissal/success outcomes for the file and both text-share scenarios on every supported destination. |
| 03bebfe8 | package_info_plus 9.0.1 | Android/iOS | no attributable native build | not recorded | not run | prerequisite probe only | application identity and version lookup | UNAVAILABLE — hold | No clean native build ran, so the package identity/version result is not attributable. | Record the redacted observed identity/version result after the complete atomic native build matrix is green. |

## PLUG-02 terminal atomic decision

**Decision:** HOLD — retain exactly `file_picker 11.0.3`, `share_plus 12.0.2`,
`package_info_plus 9.0.1`, and transitive `win32 5.15.0`.

The official execution-date candidates remain `file_picker 11.0.3`,
`share_plus 13.3.0`, `package_info_plus 10.2.1`, and `win32 6.4.0`. The newer
Plus line requires Java 17, Kotlin 2.2.0, AGP 8.12.1, and Gradle 8.13; it also
moves `win32` to 6.x while the held file-picker graph resolves 5.15.0. This
environment has no Java 17 runtime and no Android emulator/device, so no
candidate was resolved, no native build or OS-owned picker/share UI was
observed, and no declaration, lockfile, AGP, Gradle, Kotlin, or caller source
was changed. The machine contract, baseline, compatibility document, Pub files,
and this ledger agree on the held four-member graph.

## Speech acceptance evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | automated result | physical-iPhone result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 308fa2c0 | speech_to_text 7.3.0 | Dart | repository contract | n/a | test | pass | binary candidate/hold mutations, adapter, on-device fallback, and ja/zh/en corpus | PASS — targeted adapter/on-device/corpus matrix passed; no transcript recorded | not applicable | Automated proof does not exercise native recognition. | Keep the physical-iPhone hold until every named scenario is PASS on an attributable candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | supported native candidate build/install | PASS automated proof is separate | UNAVAILABLE — HOLD | No Phase-59-attributable 7.4.0 build exists with a pre-authorized non-production identity; the Phase 63 wired-iPhone UAT lane was not used. | Build the exact candidate under an authorized non-production identity, then record only redacted build metadata and result. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | microphone and speech permission granted/denied behavior | PASS automated proof is separate | UNAVAILABLE — HOLD | Permission prompts were not requested because no attributable non-production candidate build was installed. | On the exact candidate build, record redacted granted and denied outcomes. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | ja recognition | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; corpus parsing is not recognizer evidence. | Record a redacted representative ja outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | zh recognition | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; corpus parsing is not recognizer evidence. | Record a redacted representative zh outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | en recognition | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; corpus parsing is not recognizer evidence. | Record a redacted representative en outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | cancel active recognition | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; mock cancellation cannot prove the native audio lifecycle. | Record a redacted cancellation outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | surfaced recognizer error | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; mock errors cannot prove native callback delivery. | Record a redacted surfaced-error outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | fresh-session on-device recognition | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; mock options cannot prove device recognition. | Record a redacted on-device outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | allowed default-recognition fallback after one on-device failure | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; automated retry coverage is not native fallback evidence. | Record the redacted one-retry outcome on the exact candidate build. |
| no Phase-59 candidate commit | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | not built | UNAVAILABLE | disallowed default-recognition fallback after one on-device failure | PASS automated proof is separate | UNAVAILABLE — HOLD | No safe candidate session was run; automated no-retry coverage is not native privacy evidence. | Record the redacted no-retry outcome on the exact candidate build. |

The approved Task 1 tracer checkpoint confirms this exact hold interpretation:
`7.3.0` remains selected, `7.4.0` remains the stable candidate, and
`7.5.0-beta.1` remains ineligible. It does not add physical-iPhone evidence or
change the hold decision.

## Notification transport and lifecycle evidence

| commit | package/policy | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| 096d8416 / 7b255236 | Firebase Core 4.13.0 / Messaging 16.5.0 / local notifications 22.2.0 | Dart | repository contract | n/a | test | pass | declaration/lock/evidence completeness; Android-FCM versus custom-iOS-APNs source construction; success, concurrent initialization, failure/retry, token replay, foreground, opened, local tap, cold-start, and identity wipe | PASS — fake-client lifecycle and architecture contracts are green; no token, payload, identity, or credential recorded | Automated proof cannot exercise a supported native build or OS callback delivery. | Retain the exact graph until both transport-native matrices are attributable. |
| no Phase-59 candidate build | Android FCM | Android | emulator or device | not recorded | supported build | UNAVAILABLE — HOLD | Firebase initialization, registration, foreground, opened-app, cold-start, and hidden-settings policy | PASS automated proof is separate | No JDK 17 runtime and no usable Android emulator/device; the Phase-61 Android toolchain lane is out of scope. | With JDK 17 and a supported destination, build the exact held graph and record redacted Android-FCM initialization/registration/foreground/opened/cold-start results while Firebase auto-init and the notification permission removal remain disabled. |
| no Phase-59 candidate build | custom iOS APNs | iOS | supported iPhone | not recorded | supported build | UNAVAILABLE — HOLD | custom APNs initialization, foreground, opened-app, local tap, cold-start, and hidden-settings policy | PASS automated proof is separate | No Phase-59-attributable supported-iPhone result; the available simulator service is unavailable and Phase 63 wired-iPhone UAT was not used. | Build the exact held graph under an authorized non-production identity and record redacted custom-APNs lifecycle results without initializing Firebase on iOS or adding remote-notification mode / `aps-environment`. |
| 096d8416 | hidden release policy | Android/iOS | source and native manifests | n/a | architecture test | pass | `pushNotifications == false`; no visible notification setting; Android Firebase auto-init/analytics disabled and notification permission removed; iOS Firebase auto-init disabled with no remote-notification mode or `aps-environment`; Android `fcm` and iOS `apns` remain distinct | PASS — source/native contract green | Native manifest/source proof does not replace a device lifecycle observation. | Preserve these policy assertions on every future candidate evaluation; never use a package change to re-enable a hidden release feature. |

## PLUG-04 terminal notification decision

**Decision:** HOLD — retain exactly Firebase Core `4.13.0`, Firebase Messaging
`16.5.0`, and `flutter_local_notifications 22.2.0`. The official execution-date
recheck confirms Firebase Core `4.13.0`, Firebase Messaging `16.5.0`, and the
very recent local-notifications candidate `22.3.0`; registry recency cannot
replace the required build and lifecycle evidence.

Android retains `FirebasePushMessagingClient`, `Firebase.initializeApp`, and
`pushPlatform: fcm`. iOS retains `ApnsPushMessagingClient`, no Firebase
initializer, and `pushPlatform: apns`. `ReleaseFeatures.pushNotifications`
remains false, notification settings remain hidden, Android auto-init remains
disabled, iOS has neither remote-notification background mode nor
`aps-environment`, and the disclosed cloud-fallback policy remains explicit.

The exact hold exits only with PASS automated proof plus attributable supported
Android-FCM and custom-iOS-APNs native builds covering initialization/retry,
foreground, opened-app, local tap, and cold-start behavior. No production
credential, live relay delivery, push token, payload, group/device identity, or
Phase 61/62/63 evidence substitute was used or recorded.

## Phase 60 MVP notification supersession

**Decision:** SUPERSEDED — on 2026-08-09 the owner removed the dormant MVP
notification channel rather than preserving or upgrading its unresolved hold.
The current graph contains no Firebase Core, Firebase Messaging, or local
notification package; no Android Firebase/notification registration and no iOS
APNs/Firebase bridge remains. This correction preserves the Phase 59 hold as
historical evidence and requires any future notification capability to start a
new reviewed dependency, privacy, native-lifecycle, and device-evidence lane.

## Biometric/PIN and secure-storage evidence

| commit | package/policy | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| 46ac1cf1 / 7bf682f0 | local_auth 3.0.2 | Dart | repository contract | n/a | test | pass | exact declaration/lock, official-source decision, biometricOnly=true, sensitiveTransaction=true, persistAcrossBackgrounding=true, false/lockout/LocalAuthException/PlatformException/residual and availability-error app-PIN fallback | PASS — automated policy contract | Automated checks cannot observe a system prompt or prove a native Face ID result. | Keep exactly 3.0.2 until the complete redacted supported-native matrix passes. |
| native evidence unavailable | biometric app lock | iOS | safe non-production supported destination | not recorded | supported build | unavailable | availability, biometric-only Face ID success, cancel/false, temporary lockout, biometric lockout, platform error, unknown error, and app-PIN fallback | UNAVAILABLE — hold | No safe non-production supported-iPhone identity or Phase-59-attributable native build is available. Phase 63 wired-iPhone UAT is not a substitute. | Record only redacted outcome metadata for every listed row on the exact build; no OS device-passcode result may count as app-lock success. |
| b59fbf16 | flutter_secure_storage | Dart | repository contract | n/a | test | pass | selected graph and dated evidence | automated contract green | Contract cannot prove an existing key is readable. | Verify existing-key read and key-before-database startup behavior on supported native storage. |
| pending native evidence | secure-storage existing key | iOS/Android | supported destination | not recorded | supported build | unavailable | existing key readability, `unlocked_this_device`, and startup ordering | unavailable — hold | Stored-key/device evidence is unavailable. | Record redacted pass/fail metadata only; do not include a key, path, or database detail. |

### PLUG-04 secure-storage terminal decision

**Decision:** HOLD — retain exactly `flutter_secure_storage 10.3.1` in both
the declaration and lock. The official 2026-08-09 package/changelog recheck
identifies `11.0.0` as the stable major and documents removal of legacy Android
cipher paths. It does not provide a reviewed, app-specific read-then-rewrite
migration for this app's persisted master key.

| commit | package/policy | platform | destination | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|
| 284bc970 / 4af55c25 / 59-06-03 | flutter_secure_storage 10.3.1 | Dart | repository contract | test | pass | declaration/lock, candidate, accepted-major mutation, Keychain accessibility, Android options, centralized CRUD, precise clear scope, and platform-error wrapping | PASS — automated contract | Automated checks cannot read a prior-build persisted native key. | Keep 10.3.1 unless an approved read-then-rewrite migration plus native prior-key proof exists. |
| 59-06-03 | AppInitializer with exact selected storage policy | Dart | injected repository/database seams | test | pass | existing key reaches database; first launch initializes key before database; missing/unreadable key with existing data returns `masterKeyMissingWithData` without replacement or database construction | PASS — ordering and fail-closed contract | Unit seams cannot prove an existing Keychain/Keystore item or encrypted database from a prior native build. | Keep 10.3.1 until every supported native platform has redacted prior-build existing-key read and existing-encrypted-database startup PASS evidence. |
| unavailable native evidence | flutter_secure_storage 10.3.1 | iOS/Android | supported non-production destination | not run | unavailable | read a key created by the prior selected build, then open its existing encrypted database without replacement | UNAVAILABLE — HOLD | No authorized stored-key/native test state was available; no synthetic production key or candidate build was created. | Use a safe existing-key fixture/device, preserve `unlocked_this_device` and Android options, record redacted PASS only after read then database startup succeeds, and supply the reviewed read-then-rewrite migration before considering 11.0.0. |

The service/provider keep `KeychainAccessibility.unlocked_this_device`; the
service applies the established iOS and Android options to every core CRUD
operation, while the crypto key-manager remains the permitted key boundary.
`clearUserData` preserves the installation master key, and the initializer
fails closed before database construction when existing data lacks a readable
key. This record includes no key name/value pair, database path/header, device
identifier, credential, or user data. Phase 60 SQLCipher/iOS-native safety and
Phase 63 isolated-device acceptance were not claimed or used here.

## Lucide source and asset integrity evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| b59fbf16 | lucide_icons_flutter path fork | Dart | repository asset contract | n/a | test | pass | static font subset and used-codepoint contract | automated asset test green | Upstream refresh has not been selected. | Re-review upstream source/license and all references before changing the fork. |

## Decision rule

`speech_to_text` is accepted only when the centralized adapter, ja/zh/en corpus,
supported native build, physical-iPhone permission, recognition, cancellation,
error, caller-controlled network fallback, and physical-iPhone evidence are all
complete and PASS on the exact candidate build. Until then, the exact selected
7.3.0 graph remains a hold.

## Final Phase 59 convergence

| final reference | result | evidence |
|---|---|---|
| `da459184` / Flutter 3.44.8 / Dart 3.12.2 | PASS | The repository-wide `prefer_initializing_formals` analyzer cleanup leaves `flutter analyze` at 0 issues without suppressions, exclusions, dependency changes, or generated-file edits. |
| exact held selected graph | PASS | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` and the API coverage precheck both passed on the final checkout. |
| `8229c9a3` contract + final checkout | PASS | The Phase 59 targeted dependency, backup/restore, speech, push, biometric, secure-storage, initializer, and Lucide matrix passed 319 tests. |
| exact held selected graph | PASS | `bash scripts/verify_codegen_reproducibility.sh` passed its locked retrieval, two generation passes, analyzer, lint, architecture, negative-fixture, and residue checks. |
| exact held selected graph | PASS | `flutter test --coverage --concurrency=1` passed 4,589 tests with 12 expected skips; filtered LCOV passed all 15 required files at the configured 70% threshold. |

No selected declaration, lock resolution, platform transport, Keychain policy, native entitlement, schema, or Phase 60–63 boundary changed during final convergence. Every unavailable native row above remains a hold with its documented exit condition.
