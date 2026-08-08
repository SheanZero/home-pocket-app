---
phase: 59
slug: controlled-platform-plugin-cohorts
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-08
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` under Flutter 3.44.8 / Dart 3.12.2 |
| **Config file** | `pubspec.yaml`, `dart_test.yaml`, and existing `test/` directories |
| **Quick run command** | `flutter test test/architecture/dependency_compatibility_contract_test.dart` |
| **Full suite command** | `flutter test --coverage --concurrency=1` |
| **Estimated runtime** | Quick contract ~90 seconds; full suite ~15 minutes |

---

## Sampling Rate

- **After every task commit:** Run the modified cohort's targeted command plus `flutter test test/architecture/dependency_compatibility_contract_test.dart`.
- **After every accepted cohort:** Run `flutter analyze`, `bash scripts/verify_codegen_reproducibility.sh`, and the cohort's targeted tests.
- **After every plan wave:** Run the wave's combined targeted matrix and `git diff --check`.
- **Before `$gsd-verify-work`:** Run `flutter test --coverage --concurrency=1`, the filtered 70% coverage gate when code/tests changed, and final generated/native residue checks.
- **Max quick-feedback latency:** 120 seconds; native/device checkpoints are phase boundaries and never replace automated feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 0 | PLUG-01 | T-59-01 | Exact selected/held plugin values and atomic cohort membership reject partial drift before package resolution. | contract + mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ extend | ⬜ pending |
| 59-01-02 | 01 | 0 | PLUG-01 | T-59-02 | Every significant direct/native-transitive plugin records query date, candidate, decision, evidence, hold reason, and exit condition. | source contract | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ⬜ pending |
| 59-02-01 | 02 | 1 | PLUG-02 | T-59-03 | The file/share/package-info/win32 cohort moves atomically or stays at its exact held graph; `.hpb` import behavior remains covered. | widget + unit + contract | `flutter test test/widget/features/settings/backup_restore_screen_test.dart test/unit/application/settings/import_backup_use_case_test.dart test/unit/application/settings/restore_backup_use_case_test.dart test/architecture/dependency_compatibility_contract_test.dart` | ✅ extend | ⬜ pending |
| 59-03-01 | 03 | 1 | PLUG-03 | Speech retains initialization, restart, cancellation, errors, on-device fallback policy, and ja/zh/en parsing on the accepted or held version. | unit + integration corpus | `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart test/integration/voice/voice_corpus_ja_test.dart test/integration/voice/voice_corpus_zh_test.dart test/integration/voice/voice_corpus_en_test.dart` | ✅ extend | ⬜ pending |
| 59-04-01 | 04 | 1 | PLUG-04 | Android FCM/iOS APNs split, hidden notification feature policy, biometric-only authentication, Keychain accessibility, and fail-closed startup remain unchanged. | unit + architecture | `flutter test test/infrastructure/sync/push_notification_service_test.dart test/infrastructure/security/biometric_service_test.dart test/infrastructure/security/secure_storage_service_test.dart test/core/initialization/app_initializer_test.dart test/architecture/first_release_feature_contract_test.dart` | ✅ extend | ⬜ pending |
| 59-05-01 | 05 | 2 | PLUG-01, PLUG-02, PLUG-03, PLUG-04 | Final accepted graph or evidence-backed holds agree across manifest, lockfile, baseline, validator, docs, generated output, and available native evidence. | integration + phase gate | `bash scripts/verify_codegen_reproducibility.sh && flutter test --coverage --concurrency=1 && git diff --check` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `scripts/dependency_compatibility.dart` and `test/architecture/dependency_compatibility_contract_test.dart` with exact Phase 59 cohort membership, selected/held values, and partial-drift mutations.
- [ ] Extend `docs/testing/STABLE_BASELINE.json` and `docs/testing/DEPENDENCY_COMPATIBILITY.md` with official query dates, candidates, decisions, evidence, hold reasons, and exit conditions for every Phase 59 plugin.
- [ ] Add a repeatable `.hpb` picker cancellation/selection/import and real share-sheet device checklist; widget tests cannot drive OS-owned UI.
- [ ] Add a repeatable physical-iPhone speech acceptance sheet for ja/zh/en permission, recognition, cancellation, errors, and fallback.
- [ ] Require JDK 17 plus an Android emulator/device before accepting Android-impacting candidates; absence produces an evidence-backed hold rather than a false pass.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cancel and select a `.hpb` document, import it, and present the real system share sheet. | PLUG-02 | Flutter widget tests cannot operate OS document-picker or share-sheet UI. | On each affected supported platform, cancel once, select one valid `.hpb`, complete import validation, share a supported file, and record build/device/version evidence. |
| Recognize ja/zh/en speech with permission, cancellation, error, and fallback paths on a physical iPhone. | PLUG-03 | Corpus and adapter tests do not exercise native speech recognition, permissions, or device locale behavior. | Use the Phase 59 speech sheet on a physical iPhone; record locale, permission result, recognized phrase, cancellation/error behavior, fallback behavior, build hash, OS, and package version. |
| Validate notification lifecycle, app-lock Face ID/PIN fallback, and existing secure-key readability after an accepted native-impacting candidate. | PLUG-04 | Push delivery, TCC/biometric UI, and persisted Keychain/Keystore data require real native lifecycle and stored state. | Verify notification opt-out/hidden settings and platform transport policy; verify biometric-only prompt routes failures to the app PIN; verify an existing encrypted database/key opens before and after the candidate build. |

If the required native environment is unavailable, the corresponding package remains held with the failed or unavailable acceptance evidence recorded.

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies
- [ ] Sampling continuity: no three consecutive tasks without automated verification
- [ ] Wave 0 covers every missing native or evidence reference
- [x] No watch-mode flags
- [x] Quick feedback target is under 120 seconds
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence is complete

**Approval:** pending
