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
| b59fbf16 | file_picker / share_plus / package_info_plus / win32 | Dart | repository contract | n/a | test | pass | exact membership, declaration, and lock mutations | automated contract green | Native UI cannot be exercised by this test. | Run cancel, select one `.hpb`, import, and share-sheet scenarios on every affected supported platform. |
| pending native evidence | file_picker | Android/iOS | supported native destination | not recorded | supported build | unavailable | cancel, select one `.hpb`, and import validation | unavailable — hold | JDK 17, Android destination, and attributable supported iOS evidence are unavailable. | Record only redacted metadata for each successful and cancellation result. |
| pending native evidence | share_plus | Android/iOS | supported native destination | not recorded | supported build | unavailable | present encrypted-backup file and family-invite share sheets | unavailable — hold | No supported native destination evidence. | Record redacted share-sheet presentation and dismissal/success outcome metadata. |
| pending native evidence | package_info_plus | Android/iOS | supported native destination | not recorded | supported build | unavailable | application identity and version lookup | unavailable — hold | No attributable native build result. | Record redacted app identity/version lookup result on the exact graph. |

## Speech acceptance evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | automated result | physical-iPhone result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|---|
| b59fbf16 | speech_to_text 7.3.0 | Dart | repository contract | n/a | test | pass | Manifest evidence and declaration/lock drift | contract green | not applicable | Automated proof does not exercise native recognition. | Keep the physical-iPhone hold until every named scenario is recorded. |
| pending device evidence | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | supported build | unavailable | ja/zh/en permission, recognition, cancellation, error, and caller-controlled fallback | Adapter/corpus evidence is separate | unavailable — hold | A simulator, corpus, or resolver result is not physical-iPhone proof. | Run the named scenarios on a supported physical iPhone and record only redacted outcome metadata. |

The approved Task 1 tracer checkpoint confirms this exact hold interpretation:
`7.3.0` remains selected, `7.4.0` remains the stable candidate, and
`7.5.0-beta.1` remains ineligible. It does not add physical-iPhone evidence or
change the hold decision.

## Notification transport and lifecycle evidence

| commit | package/policy | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| b59fbf16 | Firebase Core / Messaging / local notifications | Dart | repository contract | n/a | test | pass | selected graph and evidence completeness | automated contract green | Contract cannot prove native lifecycle. | Run the existing notification lifecycle tests plus supported native smoke before accepting a candidate. |
| pending native evidence | Android FCM | Android | emulator or device | not recorded | supported build | unavailable | registration, foreground, opened-app, initial-message, and hidden-settings policy | unavailable — hold | JDK 17 and Android emulator/device unavailable. | Record redacted lifecycle outcomes while retaining Android FCM identity. |
| pending native evidence | custom iOS APNs | iOS | supported iPhone | not recorded | supported build | unavailable | custom APNs routing and hidden-settings policy | unavailable — hold | No attributable supported-iPhone native result. | Record redacted lifecycle outcomes without replacing custom APNs with Firebase. |

## Biometric/PIN and secure-storage evidence

| commit | package/policy | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| b59fbf16 | local_auth | Dart | repository contract | n/a | test | pass | selected graph and dated evidence | automated contract green | Contract cannot show system prompt behavior. | Verify biometric-only failures continue to reach the app-PIN fallback on a supported native destination. |
| pending native evidence | biometric app lock | iOS/Android | supported destination | not recorded | supported build | unavailable | availability, biometric-only prompt, error, and app-PIN fallback | unavailable — hold | Native biometric UI evidence is unavailable. | Record redacted outcome metadata; OS device-passcode fallback remains prohibited. |
| b59fbf16 | flutter_secure_storage | Dart | repository contract | n/a | test | pass | selected graph and dated evidence | automated contract green | Contract cannot prove an existing key is readable. | Verify existing-key read and key-before-database startup behavior on supported native storage. |
| pending native evidence | secure-storage existing key | iOS/Android | supported destination | not recorded | supported build | unavailable | existing key readability, `unlocked_this_device`, and startup ordering | unavailable — hold | Stored-key/device evidence is unavailable. | Record redacted pass/fail metadata only; do not include a key, path, or database detail. |

## Lucide source and asset integrity evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| b59fbf16 | lucide_icons_flutter path fork | Dart | repository asset contract | n/a | test | pass | static font subset and used-codepoint contract | automated asset test green | Upstream refresh has not been selected. | Re-review upstream source/license and all references before changing the fork. |

## Decision rule

`speech_to_text` is accepted only when the centralized adapter, ja/zh/en corpus,
permission, recognition, cancellation, error, caller-controlled network
fallback, and physical-iPhone evidence are all complete. Until then, the exact
selected 7.3.0 graph remains a hold.
