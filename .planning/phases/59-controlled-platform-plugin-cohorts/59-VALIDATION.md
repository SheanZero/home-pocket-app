---
phase: 59
slug: controlled-platform-plugin-cohorts
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 59-01-01 | 01 | 0 | PLUG-01 | T-59-01 | The dependency contract rejects adjacent, empty, reordered, and partial cohort mutations before package resolution. | contract + mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ extend | ✅ green |
| 59-01-02 | 01 | 0 | PLUG-01, PLUG-02, PLUG-03, PLUG-04 | T-59-02 | Every significant plugin has a selected graph, researched candidate, official evidence, decision, hold reason, and exact exit condition. | source contract | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-01-03 | 01 | 0 | PLUG-01, PLUG-02, PLUG-03, PLUG-04 | T-59-03 | The acceptance ledger and API capability matrix cover every Phase 59 cohort and resolve all six edge probes. | source + API coverage | `node /Users/xinz/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/59-controlled-platform-plugin-cohorts` | ✅ new | ✅ green |
| 59-02-01 | 02 | 1 | PLUG-01, PLUG-02 | T-59-06 | File/share/package-info/win32 prerequisites yield either one atomic candidate graph or an evidence-backed hold. | contract + source | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-02-02 | 02 | 1 | PLUG-02 | T-59-09 | The accepted or held graph preserves picker, restore, share-sheet, and package-identity behavior. | widget + unit | `flutter test test/widget/features/settings/backup_restore_screen_test.dart test/unit/application/settings/import_backup_use_case_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` | ✅ extend | ✅ green |
| 59-02-03 | 02 | 1 | PLUG-01, PLUG-02 | T-59-07, T-59-08 | Real device evidence or an exact hold records picker cancellation/selection/import, share-sheet, and package identity without sensitive payload data. | native evidence reconciliation | `flutter test test/widget/features/settings/backup_restore_screen_test.dart test/architecture/dependency_compatibility_contract_test.dart` | ✅ extend | ✅ hold |
| 59-03-01 | 03 | 2 | PLUG-03 | T-59-11 | Speech evidence yields either the stable candidate or an explicit hold without accepting a prerelease. | contract + source | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-03-02 | 03 | 2 | PLUG-03 | T-59-12 | Initialization, restart, cancellation, errors, on-device fallback, and ja/zh/en parsing remain green. | unit + integration corpus | `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart test/integration/voice/voice_corpus_ja_test.dart test/integration/voice/voice_corpus_zh_test.dart test/integration/voice/voice_corpus_en_test.dart` | ✅ extend | ✅ green |
| 59-03-03 | 03 | 2 | PLUG-03 | T-59-13 | A physical-iPhone result or exact device-blocked hold reconciles ja/zh/en permission, recognition, cancellation, error, and fallback evidence. | native evidence reconciliation | `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart` | ✅ extend | ✅ hold |
| 59-04-01 | 04 | 3 | PLUG-04 | T-59-16 | Firebase and notification candidates are accepted only with Android/JDK prerequisites; otherwise their exact current graph is held. | contract + source | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-04-02 | 04 | 3 | PLUG-04 | T-59-16, T-59-19 | Android remains Firebase/FCM, iOS remains direct APNs, and retryable lifecycle behavior remains deterministic. | unit + architecture | `flutter test test/infrastructure/sync/push_notification_service_test.dart test/architecture/first_release_feature_contract_test.dart` | ✅ extend | ✅ green |
| 59-04-03 | 04 | 3 | PLUG-04 | T-59-17, T-59-18 | Android notification evidence or exact hold is recorded without changing hidden-release policy or disclosing payload/identity data. | native evidence reconciliation | `flutter test test/infrastructure/sync/push_notification_service_test.dart test/architecture/first_release_feature_contract_test.dart` | ✅ extend | ✅ hold |
| 59-05-01 | 05 | 4 | PLUG-04 | T-59-25 | The biometric candidate is evaluated as a cohort without unreviewed declaration/lock drift. | contract + source | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-05-02 | 05 | 4 | PLUG-04 | T-59-21, T-59-22 | Biometric-only options and every biometric error continue to fall back to the app PIN. | unit + architecture | `flutter test test/infrastructure/security/biometric_service_test.dart` | ✅ extend | ✅ green |
| 59-06-01 | 06 | 5 | PLUG-04 | T-59-27, T-59-30 | Secure-storage evidence yields one explicit accepted graph or an exact held graph with an attributable terminal decision. | contract + source | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend | ✅ green |
| 59-06-02 | 06 | 5 | PLUG-04 | T-59-26 | Centralized secure storage preserves unlocked-this-device accessibility, CRUD, and clear semantics. | unit + architecture | `flutter test test/infrastructure/security/secure_storage_service_test.dart` | ✅ extend | ✅ green |
| 59-06-03 | 06 | 5 | PLUG-04 | T-59-28 | Master-key readiness still precedes encrypted database access and missing key material with existing data fails closed. | unit + initialization | `flutter test test/core/initialization/app_initializer_test.dart` | ✅ extend | ✅ green |
| 59-07-01 | 07 | 6 | PLUG-01, PLUG-02, PLUG-03, PLUG-04 | T-59-31 | Manifest, lockfile, baseline, validator, docs, acceptance ledger, and generated outputs converge on every accepted or held cohort. | phase convergence | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk && bash scripts/verify_codegen_reproducibility.sh` | ✅ extend | ✅ green |
| 59-07-02 | 07 | 6 | PLUG-01, PLUG-02, PLUG-03, PLUG-04 | T-59-34 | Full tests and filtered coverage close the phase with no generated or native residue. | full phase gate | `flutter test --coverage --concurrency=1 && /Users/xinz/.pub-cache/bin/coverde filter ... && dart run scripts/coverage_gate.dart --list .planning/audit/coverage-gate-required-files.txt --deferred .planning/audit/coverage-gate-deferred.txt --threshold 70 --lcov coverage/lcov_clean.info` | ✅ extend | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Tasks 59-01-01 and 59-01-02 extend `scripts/dependency_compatibility.dart` and its contract tests with exact equality, adjacency, empty-list, ordering, concurrency, unclassified-terminal, policy-invariant, and partial-drift probes.
- [x] Task 59-01-02 extends `docs/testing/STABLE_BASELINE.json` and `docs/testing/DEPENDENCY_COMPATIBILITY.md` with readable official evidence, selected/candidate graphs, decisions, hold reasons, exit conditions, and Lucide license/subset provenance.
- [x] Task 59-01-03 creates `59-PLUGIN-ACCEPTANCE.md` and validates `COVERAGE.md` so every in-scope capability is explicitly integrated or opted out with a reason.
- [ ] Task 59-02-03 records repeatable `.hpb` picker cancellation/selection/import, real share-sheet, and package-identity evidence or the exact device-blocked hold.
- [ ] Task 59-03-03 records a repeatable physical-iPhone speech sheet for ja/zh/en permission, recognition, cancellation, errors, and fallback or the exact device-blocked hold.
- [ ] Every Android-impacting candidate requires JDK 17 plus an Android emulator/device; speech and stored-key cohorts require their named safe native destinations. Missing prerequisites produce evidence-backed holds with exact exit conditions.

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

- [x] All tasks have automated verification or Wave 0 dependencies
- [x] Sampling continuity: no three consecutive tasks without automated verification
- [x] Wave 0 covers every missing native or evidence reference
- [x] No watch-mode flags
- [x] Quick feedback target is under 120 seconds
- [x] `nyquist_compliant: true` set in frontmatter after execution evidence is complete

**Approval:** validated 2026-08-09 — automated evidence is green; unavailable native observations remain explicit `hold` evidence rather than PASS.
