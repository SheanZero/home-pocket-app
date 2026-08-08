# Phase 59: Controlled Platform Plugin Cohorts - Pattern Map

**Mapped:** 2026-08-08  
**Files analyzed:** 16 likely created/modified files (including conditional package/adaptor changes)  
**Analogs found:** 15 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docs/testing/STABLE_BASELINE.json` | config / compatibility evidence | transform | itself | exact |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | documentation / compatibility evidence | transform | itself | exact |
| `scripts/dependency_compatibility.dart` | utility / validator | transform | itself | exact |
| `test/architecture/dependency_compatibility_contract_test.dart` | test | transform | itself | exact |
| `pubspec.yaml` | config | transform | itself | exact |
| `pubspec.lock` | generated config | transform | existing locked graph | exact (only if a candidate is accepted) |
| `lib/features/settings/presentation/screens/backup_restore_screen.dart` | component | request-response + file-I/O | itself | exact (only if API drift requires an adapter call-site update) |
| `test/widget/features/settings/backup_restore_screen_test.dart` | test | request-response + file-I/O | itself | exact |
| `lib/infrastructure/speech/speech_recognition_service.dart` | service | event-driven | itself | exact (only if 7.4.0 API adaptation is necessary) |
| `test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart` | test | event-driven | itself | exact |
| `test/unit/infrastructure/speech/speech_recognition_service_test.dart` | test | event-driven | existing service test | role-match |
| `test/integration/voice/voice_corpus_{ja,zh,en}_test.dart` | test | transform | existing locale corpora | exact |
| `test/infrastructure/sync/push_notification_service_test.dart` | test | event-driven | itself | exact |
| `test/infrastructure/security/biometric_service_test.dart` | test | request-response | itself | exact |
| `test/infrastructure/security/secure_storage_service_test.dart` and `test/core/initialization/app_initializer_test.dart` | test | CRUD + request-response | existing security/startup tests | exact |
| `59-PLUGIN-ACCEPTANCE.md` (new, recommended phase-local evidence sheet; final name is planner discretion) | documentation / manual acceptance artifact | event-driven + file-I/O | `59-VALIDATION.md` | role-match |

`lib/core/config/release_features.dart`, `lib/application/family_sync/repository_providers.dart`, security providers, and native manifests are **characterization sources**, not expected mutation targets. Do not alter them merely to test plugin updates.

## Pattern Assignments

### `docs/testing/STABLE_BASELINE.json` (compatibility evidence, transform)

**Analog:** `docs/testing/STABLE_BASELINE.json:95-149`

Keep one compact object per direct/significant dependency with selected declaration and resolution, candidate, decision, Phase 59 owner, official-source query date, and—when held—both reason and exit condition. The current Phase 59 entries establish the required evidence shape:

```json
"speech_to_text": {
  "kind": "main",
  "declared": "7.3.0",
  "resolved": "7.3.0",
  "candidate": "7.4.0",
  "decision": "hold",
  "owner_phase": 59,
  "official_source": "https://pub.dev/packages/speech_to_text",
  "queried_on": "2026-08-05",
  "compatibility_reason": "...",
  "exit_condition": "..."
}
```

Apply the same completeness to the atomic file/share/package-info/win32 cohort, notification lane, Firebase confirmation, local auth, secure storage, and Phase-59-owned Lucide fork. A candidate without native evidence remains `hold`; do not create a "passed" decision from unavailable device tooling.

### `docs/testing/DEPENDENCY_COMPATIBILITY.md` (human-readable compatibility evidence, transform)

**Analog:** `docs/testing/DEPENDENCY_COMPATIBILITY.md:1-103`

Use this document as the readable companion to the executable JSON contract: describe the exact cohort membership, selected or held resolution, incompatibility boundary, official evidence, and concrete exit gate. Keep it synchronized with JSON, pubspec, lockfile, and validator values; it must never promise a package move that the lockfile did not resolve.

### `scripts/dependency_compatibility.dart` (fail-closed validator, transform)

**Analog:** `scripts/dependency_compatibility.dart:371-381`

```dart
expectConstraint('file_picker', '^11.0.3');
expectLocked('file_picker', '11.0.3');
expectConstraint('share_plus', '^12.0.2');
expectLocked('share_plus', '12.0.2');
expectConstraint('package_info_plus', '^9.0.1');
expectLocked('package_info_plus', '9.0.1');
expectLocked('win32', '5.15.0');
expectConstraint('speech_to_text', '7.3.0');
expectLocked('speech_to_text', '7.3.0');
expectConstraint('flutter_local_notifications', '^22.2.0');
expectLocked('flutter_local_notifications', '22.2.0');
```

Extend this single validator before resolving any candidate. Preserve the paired declaration/lock checks; add complete atomic-cohort membership validation and targeted diagnostics for partial drift. Model evidence validation after the existing manifest checks rather than adding a separate permissive script.

### `test/architecture/dependency_compatibility_contract_test.dart` (contract mutation test, transform)

**Analog:** `test/architecture/dependency_compatibility_contract_test.dart:241-296, 341-403`

```dart
final input = currentInputs();
input['properties'] = '${input['properties']}\n# drift';
expect(
  validate(input),
  contains('tracked input digest mismatch: android/gradle.properties'),
);
```

Tests read the actual tracked inputs through `currentInputs()` (`:149-180`), mutate one input in memory, and assert a specific validator failure. Add a mutation per Phase-59 lane: one member of the file/share cohort, speech declaration/lock mismatch, notification drift, and incomplete/malformed Phase-59 evidence. Do not write fixtures to the repository at runtime.

### `pubspec.yaml` and `pubspec.lock` (dependency configuration, transform)

**Analog:** locked declarations enforced in `scripts/dependency_compatibility.dart:371-381`

Only modify these together after contract mutations are red and native acceptance evidence is available. The default Phase 59 outcome is a documented hold, which normally leaves both files unchanged. If a single candidate is accepted, update the matching baseline, readable matrix, validator, mutation expectations, constraint, and resolver-produced lockfile in the same cohesive change.

### Backup file/share surface and widget test (component/test, file-I/O)

**Analog:** `lib/features/settings/presentation/screens/backup_restore_screen.dart:110-157`

```dart
await SharePlus.instance.share(
  ShareParams(files: [XFile(result.data!.path)]),
);

final picked = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: const ['hpb'],
);
if (picked == null || picked.files.single.path == null || !mounted) return;
```

Preserve static picker API, exact `.hpb` extension filter, cancellation/path/mounted guard, then the existing restore-use-case boundary. Retain widget localization and negative-content assertions from `test/widget/features/settings/backup_restore_screen_test.dart:8-31`; use the existing import/restore use-case tests for persistence semantics. OS picker/share-sheet behavior belongs in manual evidence, not a fabricated widget fake.

### Speech adapter and tests (service/test, event-driven)

**Analog:** `lib/infrastructure/speech/speech_recognition_service.dart:45-204`

```dart
_isInitialized = await _speech.initialize(
  onStatus: (status) => onStatus?.call(status),
  onError: (error) => onError?.call(error.errorMsg, error.permanent),
  debugLogging: false,
);

await _speech.listen(
  onResult: onResult,
  localeId: localeId,
  listenOptions: stt.SpeechListenOptions(
    listenMode: stt.ListenMode.dictation,
    autoPunctuation: true,
    cancelOnError: false,
    partialResults: true,
    onDevice: onDevice,
  ),
);
```

The adapter is the only allowed plugin API seam. Preserve session-scoped on-device-first behavior and the caller-owned `allowOnDeviceFallback` gate (`:95-129`); `restartListen` must cancel an active session before replaying cached config (`:177-193`). The on-device tests characterize one retry, no retry after degraded/default failure, and explicit no-cloud fallback (`test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart:98-268`). Keep all three corpus files as a trilingual parsing matrix; they cannot substitute for iPhone recognition evidence.

### Push/notification policy characterization (service/test, event-driven)

**Analog:** `lib/application/family_sync/repository_providers.dart:68-81` and `test/infrastructure/sync/push_notification_service_test.dart:485-609`

```dart
messagingClient: Platform.isIOS
    ? ApnsPushMessagingClient()
    : FirebasePushMessagingClient(),
firebaseInitializer: Platform.isIOS ? null : Firebase.initializeApp,
pushPlatform: Platform.isIOS ? 'apns' : 'fcm',
```

Maintain the iOS custom-APNs / Android-FCM split. Extend fake-client tests for initialization failure/retry and foreground/tap routes rather than invoking production credentials. The hidden-release guard is separate and must remain true:

```dart
expect(ReleaseFeatures.pushNotifications, isFalse);
expect(iosInfo, isNot(contains('<string>remote-notification</string>')));
expect(entitlements, isNot(contains('aps-environment')));
```

Source: `test/architecture/first_release_feature_contract_test.dart:8-36`.

### Biometric, secure storage, and startup characterization tests (service/test, request-response + CRUD)

**Analogs:** `lib/infrastructure/security/biometric_service.dart:103-167`, `lib/infrastructure/security/providers.dart:12-59`, `lib/infrastructure/security/secure_storage_service.dart:89-133`, and `lib/core/initialization/app_initializer.dart:55-94`

```dart
final authenticated = await _localAuth.authenticate(
  localizedReason: reason,
  biometricOnly: biometricOnly,
  sensitiveTransaction: true,
  persistAcrossBackgrounding: true,
);
```

Any platform exception or unknown biometric outcome falls back to the app PIN; retain `biometricOnly: true` (`biometric_service.dart:107-167`). Retain Keychain accessibility exactly:

```dart
const FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),
)
```

Source: `lib/infrastructure/security/providers.dart:30-35`. Existing-key failures must still fail closed before database creation (`app_initializer.dart:60-81`). Use injected `mocktail` clients and direct interaction verification as in `test/infrastructure/security/biometric_service_test.dart:117-165` and `test/infrastructure/security/secure_storage_service_test.dart:17-145`.

### `59-PLUGIN-ACCEPTANCE.md` (new recommended manual-evidence artifact)

**Analog:** `.planning/phases/59-controlled-platform-plugin-cohorts/59-VALIDATION.md:52-67`

Follow the validation file’s tables and checkboxes. Record only redacted facts: date, commit, pubspec/lock versions, platform/device/OS/build mode, command/native-build result, scenario, result, hold reason, and exit condition. Separate rows for picker cancel/select/import/share, ja/zh/en permission/recognition/cancel/error/fallback, notification policy/lifecycle, Face ID/PIN fallback, and pre-existing secure-key/database readability. An unavailable Android emulator, iPhone, or stored-key migration case is a **hold evidence row**, never a pass.

## Shared Patterns

### Compatibility decisions are contract-first

**Sources:** `docs/testing/STABLE_BASELINE.json:110-120`; `scripts/dependency_compatibility.dart:371-381`; `test/architecture/dependency_compatibility_contract_test.dart:241-296`

Every decision—upgrade or hold—changes the evidence source and negative contract before package resolution. Keep cohort constraints and lock values exact, then prove malformed/partial drift fails in-memory.

### Preserve policy adapters; upgrade only plugin seams

**Sources:** `lib/infrastructure/speech/speech_recognition_service.dart:70-204`; `lib/infrastructure/security/biometric_service.dart:103-167`; `lib/infrastructure/security/providers.dart:12-59`

No direct plugin calls in UI or new platform bridge. Speech fallback privacy policy, biometric PIN fallback, and Keychain options remain in their existing infrastructure adapters/providers.

### Native acceptance must be explicit and redacted

**Source:** `.planning/phases/59-controlled-platform-plugin-cohorts/59-VALIDATION.md:52-67`

Automated adapter tests characterize code paths; only the manual checklist can evidence OS picker/share UI, speech permission/audio lifecycle, push/native lifecycle, Face ID, and persisted-Keychain reads. Missing native prerequisites imply a documented hold.

### Notification release policy remains off

**Sources:** `lib/core/config/release_features.dart:1-9`; `test/architecture/first_release_feature_contract_test.dart:8-36`; `lib/application/family_sync/repository_providers.dart:68-81`

Do not expose settings, enable remote-push entitlement, restore auto-registration, or replace custom iOS APNs with Firebase as a package-upgrade side effect.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Phase-local manual acceptance evidence sheet (suggested `59-PLUGIN-ACCEPTANCE.md`) | documentation | event-driven + file-I/O | No prior completed phase has a dedicated redacted native-plugin acceptance sheet; use the Phase 59 validation-table pattern. |

## Metadata

**Analog search scope:** `docs/testing/`, `scripts/`, `test/architecture/`, `test/widget/`, `test/unit/`, `test/infrastructure/`, `test/integration/voice/`, `lib/infrastructure/`, `lib/application/`, `lib/features/settings/`, `ios/`  
**Files scanned:** 20 focused implementation, contract, and test files  
**Pattern extraction date:** 2026-08-08
