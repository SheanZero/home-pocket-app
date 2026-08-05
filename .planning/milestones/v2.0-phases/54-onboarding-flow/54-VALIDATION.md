---
phase: 54
slug: onboarding-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-29
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `54-RESEARCH.md` § Validation Architecture (HIGH confidence).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (+ `ProviderContainer.test()`, `test/helpers/test_provider_scope.dart` `waitForFirstValue`) |
| **Config file** | `flutter_test_config.dart` (golden comparator swap off-macOS — MEMORY golden-ci-platform-gate) |
| **Quick run command** | `flutter test test/unit/features/settings test/widget/features/onboarding` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~quick <30s touched-file scope · full suite several min |

---

## Sampling Rate

- **After every task commit:** `flutter analyze` + the touched test file(s) (`flutter test <file>`)
- **After every plan wave:** Full `flutter test` (the two architecture scans — `arb_key_parity_test.dart`, `hardcoded_cjk_ui_scan_test.dart` — are full-suite-only; scoped tests miss them — MEMORY gsd-parallel-executor)
- **Before `/gsd-verify-work`:** `flutter analyze` (0 issues) + full `flutter test` green
- **Max feedback latency:** quick scope < ~30s

---

## Per-Task Verification Map

> Task IDs assigned by the planner; rows below map each requirement/decision to its automated proof. The planner's tasks MUST reference these test files.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| ONBOARD-01 | Idempotent gate: `onboarding_complete=true` → straight to shell; `false`/absent → onboarding | widget | `flutter test test/widget/features/onboarding/onboarding_gate_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-01 | `setOnboardingComplete`/getter round-trips via SharedPreferences | unit | `flutter test test/unit/data/repositories/settings_repository_impl_test.dart` | ⚠️ extend | ⬜ pending |
| ONBOARD-02 | Intro skippable → lands on settings | widget | `flutter test test/widget/features/onboarding/onboarding_intro_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-03 | Confirm UI lang → `localeProvider` state + persisted `language`; MaterialApp locale updates | widget | `flutter test test/widget/features/onboarding/onboarding_settings_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-04 | Confirm currency → `Book.currency` updated, default JPY | widget | `flutter test test/widget/features/onboarding/onboarding_settings_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-05 | Voice default = chosen UI lang; `'system'` resolves concrete (zh-CN/ja-JP/en-US, not `'system'`) | unit | `flutter test test/unit/features/settings/voice_default_resolution_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-06 | Lock-entry: skip leaves `biometricLockEnabled` off; 现在设置 deep-links security | widget | `flutter test test/widget/features/onboarding/onboarding_lock_entry_test.dart` | ❌ W0 | ⬜ pending |
| ONBOARD-07 | Back stack: settings↔intro, lock→settings, cannot dead-lock; nickname-required blocks confirm (D-14) | widget | `flutter test test/widget/features/onboarding/onboarding_settings_test.dart` | ❌ W0 | ⬜ pending |
| D-05 | Clear-all → `onboarding_complete=false` AND `UserProfile` wiped | unit | `flutter test test/unit/application/settings/clear_all_data_use_case_test.dart` | ⚠️ extend | ⬜ pending |
| D-06 | Import (old backup w/o field) → `onboarding_complete=true` | unit | `flutter test test/unit/application/settings/import_backup_use_case_test.dart` | ⚠️ extend | ⬜ pending |
| Cross | ARB three-locale (ja/zh/en) parity | arch | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ exists | ⬜ pending |
| Cross | No hardcoded CJK in onboarding UI | arch | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/widget/features/onboarding/onboarding_gate_test.dart` — idempotency (ONBOARD-01)
- [ ] `test/widget/features/onboarding/onboarding_intro_test.dart` — skippable (ONBOARD-02)
- [ ] `test/widget/features/onboarding/onboarding_settings_test.dart` — write-through + nickname-required + back-stack (ONBOARD-03/04/07, D-14)
- [ ] `test/widget/features/onboarding/onboarding_lock_entry_test.dart` — skip/deep-link (ONBOARD-06)
- [ ] `test/unit/features/settings/voice_default_resolution_test.dart` — `'system'` → concrete (ONBOARD-05)
- [ ] Extend `test/unit/data/repositories/settings_repository_impl_test.dart` — new `onboarding_complete` key round-trip
- [ ] Extend `test/unit/application/settings/import_backup_use_case_test.dart` — D-06 force-true on restore
- [ ] Extend `test/unit/application/settings/clear_all_data_use_case_test.dart` — D-05 flag reset + `UserProfile` wipe
- [ ] Retarget/remove `test/widget/features/profile/.../profile_onboarding_screen_test.dart` (boot gate retired — D-01)
- [ ] Shared widget-test scope uses `ProviderContainer.test()` + `waitForFirstValue` for async settings providers

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| MaterialApp visually switches language instantly on confirm | ONBOARD-03 | Live `MaterialApp.locale` rebuild visual; widget test asserts provider state but pixel-switch is visual | On a device, pick a non-device language in onboarding → confirm → verify app chrome re-renders in that language without restart |
| 现在设置 lands scrolled to the security area | ONBOARD-06 | `Scrollable.ensureVisible` scroll-anchor is device-render-timing dependent | Complete onboarding → 现在设置 → confirm Settings opens scrolled to `SecuritySection`, not the top |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < ~30s (quick scope)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
