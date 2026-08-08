# Phase 59: Controlled Platform Plugin Cohorts - Research

**Researched:** 2026-08-08
**Domain:** Flutter platform-plugin compatibility, native lifecycle, and behavior-preserving dependency upgrades
**Confidence:** MEDIUM

## User Constraints

No `CONTEXT.md` was supplied; the user explicitly chose to continue without it. The phase scope is therefore constrained by PLUG-01 through PLUG-04 and the Phase 59 roadmap goal. [VERIFIED: .planning/REQUIREMENTS.md:24-29] [VERIFIED: .planning/ROADMAP.md:133-145]

## Project Constraints (from AGENTS.md)

- Work on `main`; check `git status -sb` before editing, preserve unrelated changes, and do not reset or overwrite user work. [VERIFIED: AGENTS.md:29-35]
- Keep platform adapters in `lib/infrastructure/`, business contracts in feature domain, cross-feature orchestration in `lib/application/`, and presentation state in feature presentation; lower layers must not depend on UI. [VERIFIED: AGENTS.md:39-65]
- Use Riverpod 3 generated providers and existing provider locations; do not duplicate repository providers or reintroduce legacy Riverpod state APIs. [VERIFIED: AGENTS.md:86-111]
- Do not bypass the crypto and secure-storage layers, log sensitive values, weaken SQLCipher verification, or add `sqlcipher_flutter_libs` / `sqlite3_flutter_libs`. [VERIFIED: AGENTS.md:113-135]
- Preserve initialization ordering: `AppInitializer.initialize()` completes before `runApp()`, with security readiness before encrypted database access. [VERIFIED: AGENTS.md:137-141]
- Keep all user-facing strings localized in ja/zh/en and regenerate localizations after ARB changes. [VERIFIED: AGENTS.md:143-161]
- Use TDD for behavior changes; require zero-issue `flutter analyze`, relevant targeted tests, a full suite for broad changes, and the 70% coverage gate. [VERIFIED: AGENTS.md:190-213]
- Do not hand-edit generated output; regenerate after changes to generated inputs. [VERIFIED: AGENTS.md:71-84]
- Preserve the iOS SQLCipher/Native Assets posture and do not combine unrelated formatter churn with a scoped change. [VERIFIED: AGENTS.md:216-245]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLUG-01 | Independently modernize every direct/significant native dependency or retain it with BASE-04 evidence; no blanket major upgrade. | Keep one per-package candidate/decision/evidence/exit-condition record in `STABLE_BASELINE.json`, then make the validator and mutation tests reject partial cohort changes. [VERIFIED: docs/testing/STABLE_BASELINE.json:95-149] |
| PLUG-02 | Treat `file_picker`, `share_plus`, `package_info_plus`, and `win32` atomically while `.hpb` select/import/share remains usable. | The current constraints explicitly conflict across the newest plus and file-picker lines, so hold or move all four together only after native behavior evidence. [VERIFIED: pubspec.yaml:52-63] |
| PLUG-03 | Upgrade `speech_to_text` only after ja/zh/en parsing, permission, cancel/error, and iPhone evidence; otherwise retain 7.3.0. | Preserve the single service adapter, its per-session on-device-to-default fallback policy, corpus tests, and an explicit physical-iPhone acceptance checkpoint. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:45-204] |
| PLUG-04 | Recheck Firebase, notifications, biometric, and secure storage without exposing hidden notification settings or changing the cloud fallback. | Preserve Android FCM / iOS APNs split, notification feature gate, biometric-only app-lock policy, Keychain accessibility, and fail-closed startup order. [VERIFIED: lib/application/family_sync/repository_providers.dart:69-82] [VERIFIED: lib/core/config/release_features.dart:1-9] [VERIFIED: lib/infrastructure/security/providers.dart:12-35] |

## Summary

Phase 59 is a compatibility-decision and narrow-regression phase, not a blanket `pub upgrade`. The project already has an executable baseline and a compatibility validator, but the native/plugin entries owned by this phase must be refreshed and independently evidenced. The accepted outcome for any cohort is either one clean, behaviorally proven dependency resolution or an explicit evidence-backed hold with a concrete exit condition. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-120] [VERIFIED: docs/testing/DEPENDENCY_COMPATIBILITY.md:27-31]

The strongest plan is ordered by native blast radius: first make the contract reject partial plugin drift; then evaluate the file/share/package-info/win32 cohort as one hold-or-upgrade decision; next evaluate speech behind its existing adapter and language corpus; finally validate the Firebase/notification, biometric, and secure-storage lanes without altering release policy. A physical iPhone or Android environment unavailable at execution is not a reason to assert success: it is the evidence condition that causes the relevant candidate to remain held. [VERIFIED: .planning/ROADMAP.md:138-143] [VERIFIED: AGENTS.md:190-213]

**Primary recommendation:** Treat `file_picker`/`share_plus`/`package_info_plus`/`win32` as a Phase-61-blocked hold unless a single compatible native/toolchain resolution is proven; independently attempt `speech_to_text` 7.4.0 only behind its existing adapter and retain 7.3.0 if any acceptance check fails. [VERIFIED: pubspec.yaml:41-59] [CITED: https://pub.dev/packages/share_plus] [CITED: https://pub.dev/packages/package_info_plus]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `.hpb` picker, import entry, and system share invocation | Browser / Client | iOS/Android platform service | The Flutter presentation screen invokes the picker and share sheet, while the OS owns document selection and share UI. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:93-157] |
| Encrypted backup restore semantics | API / Backend (application layer) | Database / Storage | The picker supplies a file only; restore use cases own atomic encrypted-data validation and recovery. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:139-157] |
| Speech permission/session/cancellation adapter | API / Backend (infrastructure service) | Browser / Client | `SpeechRecognitionService` owns plugin calls and emits callbacks; presentation passes locale and handles UI behavior. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:45-204] |
| Push registration, delivery, local display, and tap routing | API / Backend (infrastructure service) | iOS/Android native lifecycle | `PushNotificationService` coordinates plugin clients and native callbacks, while `AppDelegate` owns custom APNs lifecycle events. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:373-585] [VERIFIED: ios/Runner/AppDelegate.swift:41-236] |
| Biometric and key storage | API / Backend (infrastructure service) | iOS Keychain / Android Keystore | The infrastructure wrappers define security policy; native stores enforce it. [VERIFIED: lib/infrastructure/security/biometric_service.dart:58-168] [VERIFIED: lib/infrastructure/security/secure_storage_service.dart:73-186] |
| Version/compatibility policy | CI / build tooling | Client/native build | The baseline and validator decide which resolution is allowed before native builds execute. [VERIFIED: docs/testing/STABLE_BASELINE.json:95-149] [VERIFIED: scripts/dependency_compatibility.dart:371-381] |

## Standard Stack

### Core

| Library / cohort | Selected version(s) | Purpose | Planning decision |
|------------------|---------------------|---------|-------------------|
| File/share/package metadata cohort | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | `.hpb` selection/import, platform sharing, build metadata | Safe hold by default in Phase 59. `share_plus` 13.3.0 and `package_info_plus` 10.2.1 require AGP `>=8.12.1`, while the app remains on the Phase-61-owned AGP 8.11.1 lane; do not split or force this cohort. [VERIFIED: pubspec.lock:348-355] [VERIFIED: pubspec.lock:990-997] [VERIFIED: pubspec.lock:1222-1229] [VERIFIED: pubspec.lock:1691-1698] [CITED: https://pub.dev/packages/share_plus] [CITED: https://pub.dev/packages/package_info_plus] |
| Speech | `speech_to_text 7.3.0` → candidate `7.4.0` | Platform speech recognition | Attempt only through the existing adapter and acceptance matrix; 7.4.0 is currently listed by the official package page as stable, while 7.5.0-beta.1 is not eligible. [VERIFIED: pubspec.yaml:41-44] [CITED: https://pub.dev/packages/speech_to_text] |
| Notifications | `firebase_core 4.13.0`, `firebase_messaging 16.5.0`, `flutter_local_notifications 22.2.0` | FCM on Android, custom APNs on iOS, local display/tap routing | Retain Firebase versions already current; evaluate 22.3.0 only as the coordinated notification lane and evidence-hold it if clean native/tap checks cannot run. [VERIFIED: pubspec.yaml:65-68] [CITED: https://pub.dev/packages/firebase_core] [CITED: https://pub.dev/packages/firebase_messaging] [CITED: https://pub.dev/packages/flutter_local_notifications] |
| App lock / keys | `local_auth 3.0.2`, `flutter_secure_storage 10.3.1` | Biometric app lock and secure key persistence | Keep `local_auth` at its currently published version; evidence-hold secure storage rather than taking the newly published 11.0.0 major without a real keychain read/migration proof. [VERIFIED: pubspec.yaml:31-35] [CITED: https://pub.dev/packages/local_auth] [CITED: https://pub.dev/packages/flutter_secure_storage] |

The source-of-truth declarations are quoted verbatim: `speech_to_text: 7.3.0`, `file_picker: ^11.0.3`, `share_plus: ^12.0.2`, `package_info_plus: ^9.0.1`, `firebase_core: ^4.13.0`, `firebase_messaging: ^16.5.0`, and `flutter_local_notifications: ^22.2.0`. [VERIFIED: pubspec.yaml:41-68]

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `docs/testing/STABLE_BASELINE.json` | Auditable candidate, decision, reason, and exit condition per dependency | Update it with fresh official lookup data before changing a phase-owned resolution. [VERIFIED: docs/testing/STABLE_BASELINE.json:95-149] |
| `scripts/dependency_compatibility.dart` + its architecture contract test | Fails closed on declarations/lockfile/cohort policy drift | Extend for every accepted Phase 59 decision and add negative mutations before resolving packages. [VERIFIED: scripts/dependency_compatibility.dart:371-381] [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:149-239] |
| Existing voice corpora and plugin-service tests | Separates parser correctness from platform recognition/session behavior | Run every time speech adapter or its package version changes. [VERIFIED: test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart:98-250] [VERIFIED: test/integration/voice/voice_corpus_ja_test.dart:15-49] [VERIFIED: test/integration/voice/voice_corpus_zh_test.dart:15-49] [VERIFIED: test/integration/voice/voice_corpus_en_test.dart:45-71] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Cohort hold | Update each plugin to its newest major independently | Rejected: current source explicitly records a `win32`-major conflict between the newest Plus lines and file_picker 11, and current Android tooling is below the newer Plus requirement. [VERIFIED: pubspec.yaml:52-59] [CITED: https://pub.dev/packages/share_plus] |
| Existing platform plugins | Custom picker/share/speech/push/biometric implementations | Rejected: these require platform-specific permissions, lifecycle, and OS integration that the supported plugins already own. [CITED: https://pub.dev/packages/speech_to_text] [CITED: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages] [CITED: https://pub.dev/packages/local_auth] |

**Installation:** No new package name is recommended. Resolve only a selected existing cohort with `flutter pub get --enforce-lockfile` after the contract has been updated; a candidate that cannot pass its acceptance criteria remains held. [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:118-124]

## Package Legitimacy Audit

No new external package is proposed, so the install-time package-legitimacy gate is not triggered. The phase changes versions only of packages already declared in `pubspec.yaml`; their official pub.dev pages and cached package pubspecs identify their publishers/repositories. The supplied legitimacy seam supports only npm, PyPI, and crates, not pub.dev, so it cannot produce a Pub verdict. [VERIFIED: pubspec.yaml:31-68] [CITED: https://pub.dev/packages/speech_to_text] [CITED: https://pub.dev/packages/firebase_core] [CITED: https://pub.dev/packages/local_auth]

| Existing package | Official evidence | Disposition |
|------------------|-------------------|-------------|
| `file_picker`, `share_plus`, `package_info_plus`, `win32` | Existing dependency declarations plus official Plus-package pages | Cohort hold until a single compatible resolution and native behavior proof exist. [VERIFIED: pubspec.yaml:52-59] [CITED: https://pub.dev/packages/share_plus] [CITED: https://pub.dev/packages/package_info_plus] |
| `speech_to_text` | Official package page lists stable 7.4.0 and prerelease 7.5.0-beta.1 | Candidate 7.4.0 only; never select the prerelease. [CITED: https://pub.dev/packages/speech_to_text] |
| Firebase, notifications, local auth, secure storage | Official publisher/package pages | Recheck at execution and evidence-hold any version that cannot preserve the app's native contract. [CITED: https://pub.dev/packages/firebase_core] [CITED: https://pub.dev/packages/firebase_messaging] [CITED: https://pub.dev/packages/flutter_local_notifications] [CITED: https://pub.dev/packages/local_auth] [CITED: https://pub.dev/packages/flutter_secure_storage] |

## Architecture Patterns

### System Architecture Diagram

```text
pubspec.yaml + pubspec.lock + official package pages
                    |
                    v
  STABLE_BASELINE.json -> dependency_compatibility.dart -> negative contract tests
                    |
                    v
  [file/share/package-info/win32] --> OS document picker/share sheet --> .hpb restore / invite share
  [speech_to_text] -------------> platform recognizer -------------> service adapter -> ja/zh/en parser
  [Firebase/local notification] -> Android FCM OR custom iOS APNs -> local display -> tap routing
  [local_auth/secure storage] --> OS biometric/key store -----------> app-lock/key-manager/startup guard
                    |
                    v
          clean native build + targeted tests + explicit device evidence
                    |
                    +--> accepted resolution and updated contract
                    \--> evidence-backed hold and unchanged lockfile
```

The diagram follows actual responsibility boundaries: picker/share calls originate in the backup and family presentation screens, speech is centralized in one infrastructure adapter, and Android versus iOS push selection occurs in the application provider. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:93-157] [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:45-204] [VERIFIED: lib/application/family_sync/repository_providers.dart:69-82]

### Recommended Project Structure

```text
docs/testing/
├── STABLE_BASELINE.json                 # official-source candidate/hold evidence
└── DEPENDENCY_COMPATIBILITY.md           # human-readable cohort matrix
scripts/
└── dependency_compatibility.dart         # executable fail-closed policy
test/
├── architecture/dependency_compatibility_contract_test.dart
├── infrastructure/{speech,security,sync}/ # adapter characterization tests
└── integration/voice/                     # ja/zh/en parser corpora
lib/
├── infrastructure/{speech,security,sync}/ # existing plugin adapters
└── features/settings/presentation/        # existing picker/share UI seam
```

Use the existing locations; do not introduce a new plugin abstraction merely to make a version upgrade appear cleaner. The project already centralizes the security, speech, and push adapters, while the picker/share calls are intentionally limited to their presentation flows. [VERIFIED: lib/infrastructure/security/providers.dart:12-59] [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:9-15] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:111-201] [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:93-157]

### Pattern 1: Fail-closed compatibility decision before resolution

**What:** Update the baseline entry, validator rules, and negative contract mutations before changing the selected package constraints and lockfile. [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:241-379]

**When to use:** For every Phase 59 cohort decision, including an evidence hold; a hold must be tested so a later incidental resolution cannot silently break it. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-120]

**Example:**

```dart
// Preserve the project’s exact atomic file/share cohort rule.
expectConstraint('file_picker', '^11.0.3');
expectLocked('file_picker', '11.0.3');
expectConstraint('share_plus', '^12.0.2');
expectLocked('share_plus', '12.0.2');
expectConstraint('package_info_plus', '^9.0.1');
expectLocked('win32', '5.15.0');
```

The quoted current values are the existing contract: `file_picker` `^11.0.3`, `share_plus` `^12.0.2`, `package_info_plus` `^9.0.1`, and `win32` `5.15.0`. [VERIFIED: scripts/dependency_compatibility.dart:371-377]

### Pattern 2: Preserve a single speech adapter and its privacy fallback

**What:** Adapt package API changes only in `SpeechRecognitionService`; callers continue to pass locale and fallback policy through the use-case boundary. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:70-204]

**When to use:** If 7.4.0 compiles but changes types, callbacks, errors, or native symbols; do not spread plugin-specific changes through voice presentation. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-110]

**Example:**

```dart
await _speech.listen(
  onResult: onResult,
  localeId: localeId,
  listenOptions: stt.SpeechListenOptions(
    cancelOnError: false,
    partialResults: true,
    onDevice: onDevice,
  ),
);
```

The source's exact option values are `cancelOnError: false`, `partialResults: true`, and `onDevice: onDevice`; the caller-visible fallback gate is preserved by `allowOnDeviceFallback`. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:65-76] [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:143-157]

### Pattern 3: Retain deliberately split native push behavior

**What:** Android uses `Firebase.initializeApp`/FCM, while iOS uses the app's custom APNs client; both feed the same push service and local-notification adapter. [VERIFIED: lib/application/family_sync/repository_providers.dart:69-82] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:481-578]

**When to use:** During Firebase/notification upgrades and native regeneration. Do not change the iOS routing into a generic Firebase implementation as a side effect of a package bump. [VERIFIED: ios/Runner/AppDelegate.swift:58-98] [VERIFIED: ios/Runner/AppDelegate.swift:186-236]

### Anti-Patterns to Avoid

- **Blanket major upgrades:** The package graph has a known `win32` conflict; lockfile resolution alone is not behavioral evidence. [VERIFIED: pubspec.yaml:52-59]
- **Re-enabling notification settings to test the plugin:** `ReleaseFeatures.pushNotifications` is deliberately `false`, and both UI and native auto-registration are protected by tests. [VERIFIED: lib/core/config/release_features.dart:1-9] [VERIFIED: test/architecture/first_release_feature_contract_test.dart:8-36]
- **Changing Keychain accessibility during a secure-storage bump:** existing keys can become unreadable and the initializer will fail closed. [VERIFIED: lib/infrastructure/security/providers.dart:12-35] [VERIFIED: lib/core/initialization/app_initializer.dart:55-82]
- **Calling `listen` mid-session or assuming continuous dictation:** the adapter cancels before restart and upstream documents the plugin for short phrases, not continuous transcription. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:161-204] [CITED: https://pub.dev/packages/speech_to_text]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Document selection | Custom iOS/Android file chooser or path resolver | `file_picker` through the existing backup screen | OS document providers and cancellation/path semantics are platform-specific. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:122-157] |
| System sharing | Custom intent/UIActivityViewController bridge | `share_plus` | The plugin owns Android `ACTION_SEND` and iOS `UIActivityViewController`. [CITED: https://pub.dev/packages/share_plus] |
| Speech recognition | Custom platform recognizer bridge | `speech_to_text` behind `SpeechRecognitionService` | Permissions, availability, locale selection, callback lifecycle, and cancellation vary by OS. [CITED: https://pub.dev/packages/speech_to_text] |
| Push/local notification plumbing | New direct FCM/APNs or local notification implementation | Current `PushNotificationService` client interfaces | The app already models foreground, opened-app, and initial-message delivery in one testable service. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:79-201] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:545-578] |
| Biometric/key persistence | Direct `LocalAuthentication`/`FlutterSecureStorage` calls from UI | Existing infrastructure services/providers | Existing policy prevents OS-passcode app-lock bypass and preserves stored key accessibility. [VERIFIED: lib/infrastructure/security/biometric_service.dart:103-167] [VERIFIED: lib/infrastructure/security/providers.dart:12-59] |

**Key insight:** The valuable custom code is the app's policy adapter, not a replacement for an OS integration plugin; upgrade only the plugin seam while preserving that policy. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:63-158] [VERIFIED: lib/infrastructure/security/biometric_service.dart:103-167]

## Common Pitfalls

### Pitfall 1: Breaking the file/share cohort through transitive `win32` drift

**What goes wrong:** The resolver selects one Plus major with `win32` 6 while file_picker 11 requires `win32` 5, producing an incompatible or untested native graph. [VERIFIED: pubspec.yaml:52-59]

**How to avoid:** First change the compatibility contract and negative tests; then either resolve all four packages together on a toolchain that meets their documented requirements or retain the exact hold. [VERIFIED: scripts/dependency_compatibility.dart:371-381] [CITED: https://pub.dev/packages/share_plus] [CITED: https://pub.dev/packages/package_info_plus]

**Warning signs:** A changed `win32` lock entry, changed Plus major, or required AGP/Gradle change outside the reviewed Phase 59 diff. [VERIFIED: pubspec.lock:1691-1698] [CITED: https://pub.dev/packages/share_plus]

### Pitfall 2: Treating speech parser tests as native recognition acceptance

**What goes wrong:** ja/zh/en corpus tests can remain green even when a plugin upgrade changes permission prompts, device locale availability, on-device fallback, cancellation, or iPhone audio-session behavior. [VERIFIED: test/integration/voice/voice_corpus_ja_test.dart:15-49] [VERIFIED: test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart:98-250]

**How to avoid:** Require all corpus and adapter tests plus manual iPhone acceptance for initialize, permission, one utterance per supported locale, cancel, a surfaced error, and the allowed/disallowed on-device fallback branches. If any manual branch cannot be executed or fails, document the result and retain 7.3.0. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-110] [CITED: https://pub.dev/packages/speech_to_text]

### Pitfall 3: Accidentally exposing notification controls or changing transport disclosure

**What goes wrong:** A notification update makes first-release settings visible, restores Android auto-registration, adds iOS remote-push entitlement, or swaps the iOS APNs route for Firebase. [VERIFIED: lib/core/config/release_features.dart:1-9] [VERIFIED: test/architecture/first_release_feature_contract_test.dart:19-36] [VERIFIED: lib/application/family_sync/repository_providers.dart:69-82]

**How to avoid:** Extend the existing release-feature/native manifest contract tests and assert Android FCM plus custom iOS APNs remain selected. Test foreground, opened-app, and initial-message routing through existing fakes; do not require live production credentials. [VERIFIED: test/architecture/first_release_feature_contract_test.dart:19-36] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:525-578]

### Pitfall 4: Making existing secure keys unreadable

**What goes wrong:** A secure-storage change alters `KeychainAccessibility` or default cipher/migration behavior; master-key lookup fails and the app must fail closed because a database already exists. [VERIFIED: lib/infrastructure/security/providers.dart:12-35] [VERIFIED: lib/core/initialization/app_initializer.dart:55-82]

**How to avoid:** Preserve `KeychainAccessibility.unlocked_this_device`; do not adopt secure-storage 11.0.0 without an explicit read-then-rewrite migration design and real existing-key/device evidence. [VERIFIED: lib/infrastructure/security/secure_storage_service.dart:89-101] [CITED: https://pub.dev/packages/flutter_secure_storage]

### Pitfall 5: Confusing local-notification initialization with permission policy

**What goes wrong:** Initialization changes cause a user prompt or delivery behavior at the wrong lifecycle point. FCM requires different treatment in foreground/background/terminated states, and Apple token timing matters for FCM clients. [CITED: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages] [CITED: https://firebase.google.com/docs/cloud-messaging/flutter/get-started]

**How to avoid:** Preserve the existing initialization order—identity policy, optional Firebase initialization, local client initialization, permission request, token, subscriptions, then cold-start message—and test that order through fakes. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:481-578]

## Code Examples

### Current supported backup share pattern

```dart
await SharePlus.instance.share(
  ShareParams(files: [XFile(result.data!.path)]),
);
```

The exact existing pattern is `SharePlus.instance.share` with `ShareParams(files: [XFile(result.data!.path)])`; preserve it during any cohort acceptance test. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:110-116]

### Current supported `.hpb` selection pattern

```dart
final picked = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: const ['hpb'],
);
if (picked == null || picked.files.single.path == null || !mounted) return;
```

The exact source values are `FileType.custom` and `allowedExtensions: const ['hpb']`; preserve cancellation and single-path guards rather than broadening backup import scope. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:122-128]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FilePicker instance methods | Static `FilePicker.pickFiles()` API | file_picker 11.0.0 | The app already calls the static API, so this upgrade must not introduce an instance-API migration. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:122-128] [CITED: https://pub.dev/packages/file_picker/changelog] |
| Generic native update | Cohort-specific, contract-first hold-or-upgrade | v2.1 Phase 59 | The baseline encodes atomic file/share and notification lanes with exit conditions. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-120] |
| Secure-storage major without data proof | Existing-key compatibility evidence before a major move | secure-storage 10+ API era | Platform cipher and Keychain options affect persisted secrets, so the 11.0.0 candidate is not safe by registry recency alone. [VERIFIED: lib/infrastructure/security/providers.dart:12-35] [CITED: https://pub.dev/packages/flutter_secure_storage] |

**Deprecated/outdated:** Do not rely on the prior Phase-57 candidate snapshot alone: official package pages currently show newer `share_plus`, `package_info_plus`, `flutter_local_notifications`, and `flutter_secure_storage` releases, so every final decision must be re-queried on execution day. [CITED: https://pub.dev/packages/share_plus] [CITED: https://pub.dev/packages/package_info_plus] [CITED: https://pub.dev/packages/flutter_local_notifications] [CITED: https://pub.dev/packages/flutter_secure_storage]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No assumed technical claim is used for the recommended decisions. | All | — |

All package-version, compatibility, and codebase behavior claims above are either sourced from the current repository or cited to official package/platform documentation.

## Open Questions

1. **Can the execution environment provide the required Android and iPhone evidence?**
   - What we know: Flutter 3.44.8/Dart 3.12.2, Xcode 26.2, and CocoaPods 1.16.2 are installed; no JDK, Android emulator, Android device, or iOS Simulator was detected. [VERIFIED: environment audit 2026-08-08]
   - What's unclear: Whether a wired iPhone is available for the required speech acceptance and whether JDK 17/emulator access can be supplied for Android native validation.
   - Recommendation: Make every candidate upgrade contingent on the missing evidence. If the prerequisite is unavailable, preserve the current lockfile and record an evidence-backed hold; do not claim device acceptance.

2. **Should the project take the very recent `flutter_local_notifications` 22.3.0 patch?**
   - What we know: 22.3.0 was published hours before research, while the current app has 22.2.0 and a coupled notification lifecycle. [VERIFIED: pubspec.yaml:65-68] [CITED: https://pub.dev/packages/flutter_local_notifications]
   - What's unclear: Its changelog impact on the app's Android/iOS initialization/tap route.
   - Recommendation: Recheck the official changelog at execution, run the native/build and fake-client matrix first, and retain 22.2.0 if evidence is incomplete.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter / Dart | Resolution, analysis, Dart and native build/test commands | ✓ | Flutter 3.44.8 / Dart 3.12.2 | — [VERIFIED: `flutter --version`, 2026-08-08] |
| Xcode | iOS plugin compilation and iPhone speech/native evidence | ✓ | 26.2 | Hold candidates needing iOS evidence if a compatible destination is unavailable. [VERIFIED: `xcodebuild -version`, 2026-08-08] |
| CocoaPods | Existing iOS plugin/native resolution | ✓ | 1.16.2 | SwiftPM/CocoaPods lane remains Phase 60-owned; do not change it here. [VERIFIED: `pod --version`, 2026-08-08] |
| JDK 17 | Android Gradle build for plugin candidates | ✗ | — | No safe build fallback; install/provide JDK 17 or evidence-hold Android-impacting candidates. [VERIFIED: `java -version`, 2026-08-08] |
| Android Emulator/device | Android picker/share/speech/notification verification | ✗ | — | Hold candidate changes; Phase 61 owns emulator setup. [VERIFIED: `emulator` lookup and `adb devices -l`, 2026-08-08] |
| iOS Simulator | Simulator native smoke | ✗ | — | A physical iPhone may supply required speech evidence; otherwise hold. [VERIFIED: `xcrun simctl list devices available`, 2026-08-08] |

**Missing dependencies with no fallback:** JDK 17 for an Android native candidate build; an Android emulator/device for Android behavioral acceptance.

**Missing dependencies with fallback:** iOS Simulator — a current wired iPhone can provide narrowly scoped non-production speech/plugin evidence, but it must not be represented as Phase 63 final acceptance.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` under Flutter 3.44.8 / Dart 3.12.2. [VERIFIED: pubspec.yaml:91-99] [VERIFIED: `flutter --version`, 2026-08-08] |
| Config file | `pubspec.yaml` and existing test directories; no separate framework config was found. [VERIFIED: pubspec.yaml:91-99] |
| Quick run command | `flutter test test/architecture/dependency_compatibility_contract_test.dart` |
| Full suite command | `flutter test --coverage --concurrency=1` |

The baseline validator test was run during research and passed for the committed compatible graph. [VERIFIED: `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'BASE-01 traces the reviewed SQLCipher hold through the validator' -r compact`, 2026-08-08]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUG-01 | Baseline, direct dependency inventory, selected lock values, and cohort completeness reject drift | Contract + mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart` and `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend [VERIFIED: test/architecture/dependency_compatibility_contract_test.dart:241-379] |
| PLUG-02 | Backup export/share UI and `.hpb` import cancellation/single-file behavior stay stable | Widget + use-case + manual native smoke | `flutter test test/widget/features/settings/backup_restore_screen_test.dart test/unit/application/settings/import_backup_use_case_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` | ✅; native smoke gap [VERIFIED: test/widget/features/settings/backup_restore_screen_test.dart:8-31] |
| PLUG-03 | Trilingual parse, adapter init/restart/cancel/error/fallback behavior | Unit + integration corpus + manual iPhone acceptance | `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart test/integration/voice/voice_corpus_ja_test.dart test/integration/voice/voice_corpus_zh_test.dart test/integration/voice/voice_corpus_en_test.dart` | ✅; device acceptance gap [VERIFIED: test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart:98-250] |
| PLUG-04 | Push lifecycle, hidden feature/native opt-out, biometric fallback, secure-storage policy, startup guard | Unit + architecture + native smoke | `flutter test test/infrastructure/sync/push_notification_service_test.dart test/infrastructure/security/biometric_service_test.dart test/infrastructure/security/secure_storage_service_test.dart test/core/initialization/app_initializer_test.dart test/architecture/first_release_feature_contract_test.dart` | ✅; native smoke gap [VERIFIED: test/architecture/first_release_feature_contract_test.dart:8-36] |

### Sampling Rate

- **Per task commit:** The target command for the modified cohort plus `flutter test test/architecture/dependency_compatibility_contract_test.dart`.
- **Per accepted cohort:** `flutter analyze`, the authoritative `bash scripts/verify_codegen_reproducibility.sh`, then the cohort's targeted tests. [VERIFIED: .planning/phases/58-flutter-analyzer-code-generation-lane/58-VALIDATION.md:41-50]
- **Per wave merge / phase gate:** `flutter test --coverage --concurrency=1`, filtered 70% coverage gate where code/tests change, and `git diff --check`. [VERIFIED: .planning/phases/58-flutter-analyzer-code-generation-lane/58-VALIDATION.md:49-50]

### Wave 0 Gaps

- [ ] Extend `scripts/dependency_compatibility.dart` and its mutation tests with the exact selected/held Phase 59 cohort values and an explicit rejection of partial file/share/notification/speech drift. [VERIFIED: scripts/dependency_compatibility.dart:371-381]
- [ ] Add a phase evidence/checklist artifact that records official query date, candidate, clean native build result, supported-platform behavior result, hold reason, and exit condition for each significant direct/native-transitive plugin. [VERIFIED: docs/testing/STABLE_BASELINE.json:95-149]
- [ ] Define a manual device test script for `.hpb` picker cancellation/selection/import and real share-sheet presentation; widget tests cannot operate an OS document picker or share sheet. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:93-157]
- [ ] Define the speech iPhone acceptance sheet (ja/zh/en locale, permission, recognition, cancellation, error, and fallback); do not substitute corpus tests for it. [VERIFIED: docs/testing/STABLE_BASELINE.json:110-110]
- [ ] Provide JDK 17 and an Android emulator/device before accepting any Android-impacting candidate upgrade; otherwise write an evidence hold. [VERIFIED: environment audit 2026-08-08]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Biometric authentication remains biometric-only and all failed/unknown native outcomes route to the app PIN. [VERIFIED: lib/infrastructure/security/biometric_service.dart:103-167] |
| V3 Session Management | Yes | Push subscriptions are bound to an identity generation and invalidated on local wipe. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:418-428] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:525-578] |
| V4 Access Control | Yes | Incoming family push data is filtered through the existing acceptance policy before routing/navigation. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:225-254] |
| V5 Input Validation | Yes | Keep backup import validation in existing use cases and restrict UI selection to the `.hpb` extension; do not add an unsafe file path parser. [VERIFIED: lib/features/settings/presentation/screens/backup_restore_screen.dart:122-157] |
| V6 Cryptography | Yes | Preserve the existing key-manager/secure-storage layering and fail-closed missing-master-key behavior; no custom crypto or plaintext fallback. [VERIFIED: lib/infrastructure/security/providers.dart:12-59] [VERIFIED: lib/core/initialization/app_initializer.dart:55-82] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Keychain accessibility drift makes encrypted data unrecoverable | Denial of service / tampering | Preserve `unlocked_this_device`; require a read-then-rewrite migration plus real stored-key evidence before changing it. [VERIFIED: lib/infrastructure/security/providers.dart:12-35] |
| OS-passcode fallback bypasses app PIN policy | Elevation of privilege | Keep `biometricOnly: true`, `sensitiveTransaction: true`, and PIN fallback on errors/lockout. [VERIFIED: lib/infrastructure/security/biometric_service.dart:103-167] |
| Push payload for a revoked identity navigates or displays content | Information disclosure / spoofing | Keep identity-generation binding, acceptance policy, and local-notification cleanup. [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:106-109] [VERIFIED: lib/infrastructure/sync/push_notification_service.dart:481-578] |
| Speech fallback sends sensitive financial speech to a network recognizer without intent | Information disclosure | Preserve the caller-controlled `allowOnDeviceFallback` gate and never log transcript content. [VERIFIED: lib/infrastructure/speech/speech_recognition_service.dart:63-129] |
| Native upgrade re-enables notification permission/registration | Privacy / unexpected data flow | Keep feature flag false, Android auto-init disabled, and no iOS production remote-push entitlement. [VERIFIED: test/architecture/first_release_feature_contract_test.dart:8-36] |

## Sources

### Primary (HIGH confidence)

- Repository source-of-truth: `pubspec.yaml`, `pubspec.lock`, `docs/testing/STABLE_BASELINE.json`, `scripts/dependency_compatibility.dart`, infrastructure adapters, native manifests, and tests — current selected graph and behavioral contracts. [VERIFIED: pubspec.yaml:31-89] [VERIFIED: docs/testing/STABLE_BASELINE.json:95-149]

### Secondary (MEDIUM confidence)

- [speech_to_text official package documentation](https://pub.dev/packages/speech_to_text) — stable/prerelease distinction, lifecycle, permission, locale, and short-phrase constraints.
- [share_plus official package documentation](https://pub.dev/packages/share_plus) and [package_info_plus official package documentation](https://pub.dev/packages/package_info_plus) — platform share/metadata behavior and current native toolchain floors.
- [Firebase Cloud Messaging Flutter receive documentation](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) and [Firebase Flutter setup documentation](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) — foreground/background/terminated, permission, APNs-token guidance.
- [local_auth official package documentation](https://pub.dev/packages/local_auth) and [flutter_secure_storage official package documentation](https://pub.dev/packages/flutter_secure_storage) — platform support, authentication handling, Keychain/configuration risks.
- [flutter_local_notifications official package documentation](https://pub.dev/packages/flutter_local_notifications) and [file_picker changelog](https://pub.dev/packages/file_picker/changelog) — notification lifecycle capability and file-picker 11 static API change.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — current project selections are verified in source, while current external release/toolchain claims come from official package pages rather than Context7.
- Architecture: HIGH — adapters, policy boundaries, native manifests, and tests were opened in this session.
- Pitfalls: HIGH — the critical lane conflict and security/feature-flag constraints are explicitly encoded in current source; upstream lifecycle facts are officially cited.

**Research date:** 2026-08-08
**Valid until:** 2026-08-15 (package releases and native toolchain requirements are fast-moving).
