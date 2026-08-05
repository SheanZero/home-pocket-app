---
phase: 55
slug: pin-phase
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-30
finalized: 2026-06-30
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `55-RESEARCH.md` § "Validation Architecture". App Lock = UI gate over an
> already-decrypted DB; the lock NEVER binds the DB encryption key.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Dart) + `mocktail` for service fakes |
| **Config file** | none — `flutter test` auto-discovers `test/**`; goldens via `flutter_test_config.dart` |
| **Quick run command** | `flutter test test/<scoped path for the task under test>` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | quick ~10–30s · full suite several minutes (~2300 tests) |

> Goldens are macOS-baselined (see [[golden-ci-platform-gate]]); update baselines only on macOS.
> Never `dart format` the whole `test/` tree (repo is not format-clean).

---

## Sampling Rate

- **After every task commit:** Run the quick `flutter test` for the touched area.
- **After every plan wave:** Run `flutter analyze && flutter test` (full — architecture tests
  like the hardcoded-CJK UI scan + ARB parity only fire in the full suite).
- **Before `/gsd-verify-work`:** Full suite must be green, `flutter analyze` 0 issues.
- **Max feedback latency:** ~30s for the quick loop.

---

## Per-Task Verification Map

> Mapped to the 11 emitted plans (55-01..55-11). Full requirement→test detail in
> `55-RESEARCH.md` § Validation Architecture. Status is ⬜ pending until execution.

| Plan | Wave | Requirement | Secure Behavior (must be TRUE) | Test Type | Automated Command | Status |
|------|------|-------------|--------------------------------|-----------|-------------------|--------|
| 55-01 | 1 | LOCK-07 | Salted Argon2id (m=19456,t=2,p=1,32B) off-isolate; PHC string in `pinHash`; constant-time compare; never plaintext | unit | `flutter test test/.../pin_hasher_test.dart` (determinism + reject-wrong-PIN + `constantTimeBytesEquality`) | ⬜ pending |
| 55-02 | 1 | LOCK-05/10 | Every `LocalAuthExceptionCode` (all 14 incl. lockedOut/permanentlyLockedOut/cancel) + wildcard → `fallbackToPIN`; catches the NEW `LocalAuthException` model, not legacy `PlatformException` | unit | `flutter test test/.../biometric_service_test.dart` | ⬜ pending |
| 55-03 | 1 | LOCK-01/06 | `appLockEnabled`/`biometricUnlockEnabled` via SharedPreferences (no Drift, schema 22); legacy `biometricLockEnabled` retired; onboarding skip repointed (D-02) | unit | `flutter test test/.../app_settings_test.dart` | ⬜ pending |
| 55-04 | 1 | LOCK-09 | All lock/PIN/forgot-PIN/SecuritySection keys in ja/zh/en + `@`-descriptions + gen-l10n; forgot-PIN copy = unrecoverable/reinstall/lose-unsynced/no-recovery | arch | full suite: ARB parity + hardcoded-CJK scan | ⬜ pending |
| 55-05 | 1 | LOCK-08 | Covered-by-descope: REQUIREMENTS LOCK-08 → LOCK-V2-04, ROADMAP SC-4 annotated, RESEARCH sign-off cited; NO rate-limiting implemented | docs | grep REQUIREMENTS.md/ROADMAP.md for the descope edits | ⬜ pending |
| 55-06 | 1 | LOCK-03/04 | Two-flag guard (`_authInProgress` + `_didPause`): `inactive`→mask-only, `paused`→`resumed`→relock, no relock loop; mask only when lock effective | unit | `flutter test test/.../app_lock_lifecycle_observer_test.dart` (4 scenarios) | ⬜ pending |
| 55-07 | 2 | LOCK-01/06 | `lockEffective` = `appLockEnabled && pinHash != null` (single source); setPin/verifyPin/reauth/disableLock | unit | `flutter test test/.../app_lock_service_test.dart` | ⬜ pending |
| 55-08 | 2 | LOCK-04/06 | Tone-B widgets: PinKeypad / PinDots(shake) / FaceIdPanel(ghost escape) / opaque PrivacyMask | widget | `flutter test test/widget/.../app_lock/*` | ⬜ pending |
| 55-09 | 3 | LOCK-05/06 | AppLockScreen: Face-ID auto-trigger + stay-with-escape, PIN instant-verify, forgot-PIN copy, `onUnlocked` callback | widget | `flutter test test/widget/.../app_lock_screen_test.dart` | ⬜ pending |
| 55-10 | 3 | LOCK-01/06 | SecuritySection D-11 refactor; enable-requires-PIN (revert on cancel); disable/change require reauth (D-05) via `verifyPin`; deep-link auto-open (D-10) | widget | `flutter test test/widget/.../security_section_test.dart` | ⬜ pending |
| 55-11 | 4 | LOCK-01/02/03/04 | `main.dart` `_isLocked` gate branch (cold-start) + observer registration + opaque mask host; unlock via setState flag (not pushReplacement) | widget + manual | `flutter test` + on-device QA checkpoint (see Manual-Only) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · test paths are indicative — executor sets the exact path*

---

## Wave 0 Requirements

Wave 0 is satisfied **inline** in the wave-1 test tasks (no separate Wave 0 plan needed):

- [x] Test fakes/mocks for `BiometricService`, `SecureStorageService`, `SettingsRepository`
      (mocktail) — created inline in 55-06 / 55-07 test tasks.
- [x] A lifecycle harness helper to drive `AppLifecycleState` transitions — created inline in 55-06.

*Existing `flutter_test` infrastructure otherwise covers all phase requirements (no framework install needed).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Face ID/Touch ID prompt → `active→inactive→resumed` does NOT spuriously relock or flicker the mask | LOCK-03/04/05 | System biometric UI + real lifecycle cannot be faithfully simulated in `flutter_test` | On device: enable lock, set PIN, foreground app, trigger Face ID; confirm no mask flash, no relock loop; cancel Face ID → lands on PIN page |
| Task-switcher / app-switcher snapshot shows opaque brand cover, no ledger amounts | LOCK-04 | Snapshot timing is OS-driven and device-dependent ([[research A3]]) | On device (iOS + Android): open app-switcher, inspect the app's thumbnail |
| KDF latency in the 250–500ms target band on a real mid-range device | LOCK-07 | Argon2id cost is device-dependent; needs on-device calibration | Time set-PIN + unlock on a real device; adjust params if outside band |
| Keychain accessibility unchanged → existing installs not bricked | LOCK-07 | Requires upgrade-install over a prior build | Install over a previous version; confirm master key still readable (app boots past init) |

---

## Validation Sign-Off

- [x] All tasks have an automated verify or a Wave 0 dependency (every autonomous task carries a scoped `<automated>` command; 55-11's OS-driven behaviors covered by the on-device QA checkpoint)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (fakes + lifecycle harness created inline in 55-06/55-07)
- [x] No watch-mode flags
- [x] Feedback latency < 30s for the quick loop
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-30 (plan-checker Dimension 8 PASS; per-task map mapped to 55-01..55-11)
