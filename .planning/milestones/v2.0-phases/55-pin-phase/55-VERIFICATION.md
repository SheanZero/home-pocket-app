---
phase: 55-pin-phase
verified: 2026-08-05T01:53:24Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  scope: "Reconcile completed 55-UAT.md and gap-closure plan 55-12"
  human_tests: "6/6 complete on physical Face ID iPhone: 5 pass, 1 pass_with_followup"
  gaps_closed: [G1, G2, G3, G4]
  non_blocking_followup: "LOCK-V2-05 unlock feedback / shell first-frame optimization"
  regressions: []
---

# Phase 55: 应用锁（生物识别 + PIN） Verification Report

**Phase Goal:** 实现「已解密 DB 之上的 UI gate」应用锁：冷启动 + 回前台完整重锁、任务切换器隐私遮罩、生物识别优先 + 4 位 PIN 强制兜底；PIN 加盐慢哈希存入既有 secure storage；完整 local_auth 错误分类一律回退 PIN；Setting 可开关、关闭时完全 no-op。
**Verified:** 2026-08-05 (reconciles completed on-device UAT from 2026-07-01)
**Status:** passed
**Re-verification:** Yes — `55-UAT.md` completed all six device tests and plan 55-12 closed G1–G4

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | (LOCK-01/06) Settings enable/disable app lock; enabling forces a 4-digit PIN first; disabling is a complete no-op | ✓ VERIFIED | `security_section.dart` master `SwitchListTile` ON→`_enableLock` pushes double-entry `SetPinScreen`, persists `enableLock()` ONLY after PIN set (`if (!ok) return; // never enable without a PIN`). `AppLockService.disableLock()` sets `appLockEnabled=false` + `deletePinHash()`. `main.dart` gate: `_lockConfigured` false ⇒ `_isLocked` stays false, observer `onMask` gated by `isLockEffective: () => _lockConfigured` ⇒ no mask/relock |
| 2 | (LOCK-02/03/04) Cold start AND background→foreground require re-unlock; privacy mask on inactive does not leak ledger data | ✓ VERIFIED | `main.dart` `_buildHome`: `if (_isLocked) return AppLockScreen(...)` sits AFTER onboarding, BEFORE `MainShellScreen`. Cold start: `_isLocked = appLockEnabled && pinHash != null` (line 205/211). `AppLockLifecycleObserver`: relock fires only `_didPause && !_authInProgress && isLockEffective()` on resumed; `onMask` on inactive. `PrivacyMask` is an opaque `Container(color: palette.background)`, NOT blur. Observer transitions exercised by `app_lock_lifecycle_observer_test.dart` (59 transition assertions, green in 3467/3467) |
| 3 | (LOCK-05/10) Biometric-first, falls back to PIN; FULL local_auth error classification all → PIN, never locks user out | ✓ VERIFIED | `biometric_service.dart`: notSupported/notEnrolled → `fallbackToPIN()` pre-call; `catch LocalAuthException` switch with explicit temporaryLockout/biometricLockout arms + wildcard `_ → fallbackToPIN()`; residual `on PlatformException` and `catch(_)` both → `fallbackToPIN()`. `AppLockScreen._runBiometric` auto-triggers on entry; non-success stays on Face ID page (no auto-drop), ghost パスコードを使用 escapes to PIN |
| 4 | (LOCK-07) PIN salted Argon2id off-isolate, in existing secure storage (unchanged accessibility), constant-time, never plaintext, no wipe; LOCK-08 descope reflected | ✓ VERIFIED | `pin_kdf.dart`: Argon2id m=19456,t=2,p=1,32B,16B CSPRNG salt via `Isolate.run`; PHC string; `verifyPin` uses `constantTimeBytesEquality.equals`; no plaintext stored/compared. `secure_storage_service.dart`: `pinHash='pin_hash'`, `accessibility: KeychainAccessibility.unlocked_this_device`. No data-wipe path. Descope: REQUIREMENTS LOCK-08 `[~]`→LOCK-V2-04; ROADMAP SC-4 clause struck + DESCOPED per D-06 |
| 5 | (LOCK-09) Lock-screen copy states forgotten PIN unrecoverable (reinstall + data loss), no recovery path; ARB parity ja/zh/en | ✓ VERIFIED | `appLockForgotPinExplanation` present in all 3 ARB files with explicit unrecoverable/reinstall/lose-unsynced-data wording, no recovery hint. ARB key parity: zero key diff across ja/zh/en. Hardcoded-CJK scan passes (part of green 3467/3467 suite) |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/infrastructure/security/pin_kdf.dart` | Argon2id off-isolate KDF | ✓ VERIFIED | Isolate.run, PHC, constant-time |
| `lib/infrastructure/security/biometric_service.dart` | Full error→PIN classification | ✓ VERIFIED | LocalAuthException switch + wildcard + residual nets |
| `lib/infrastructure/security/app_lock_lifecycle_observer.dart` | Two-flag relock/mask guard | ✓ VERIFIED | `_didPause`+`_authInProgress`, inactive mask branch |
| `lib/application/security/app_lock_service.dart` | lockEffective single source of truth | ✓ VERIFIED | `appLockEnabled && pinHash!=null`, setPin/verifyPin/disableLock/reauth |
| `lib/features/applock/presentation/screens/app_lock_screen.dart` | Biometric-first + instant PIN | ✓ VERIFIED | auto-trigger, stays-on-faceid, shake+clear, onUnlocked callback |
| `lib/features/applock/presentation/screens/set_pin_screen.dart` | Double-entry set-PIN | ✓ VERIFIED | enter→confirm steps, mismatch, setPin then pop(true) |
| `lib/features/settings/presentation/widgets/security_section.dart` | Master toggle + sub-toggle + reauth | ✓ VERIFIED | enable-after-PIN, biometric sub-toggle gated, 修改PIN/disable reauth (D-05) |
| `lib/features/applock/presentation/widgets/privacy_mask.dart` | Opaque brand cover | ✓ VERIFIED | solid `palette.background` Container, NOT blur |
| `lib/l10n/app_{ja,zh,en}.arb` | Lock strings at parity | ✓ VERIFIED | 12 lock keys each, zero parity diff |
| `lib/features/settings/domain/models/app_settings.dart` | appLockEnabled + biometricUnlockEnabled | ✓ VERIFIED | both default false; legacy biometricLockEnabled not read by new lock |
| `lib/main.dart` gate | _isLocked, _completeUnlock, mask host, observer | ✓ VERIFIED | setState flags, no pushReplacement, builder-hosted mask |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `derivePinPhc()` | `setPinHash()` | PHC into pinHash slot | ✓ WIRED (`AppLockService.setPin`) |
| `verifyPin()` | `getPinHash()` | parse+re-derive+constant-time | ✓ WIRED |
| `_localAuth.authenticate()` throw | `AuthResult.fallbackToPIN` | LocalAuthException switch + wildcard | ✓ WIRED |
| `AppLockScreen.onUnlocked` | `main.dart _completeUnlock` | setState flag flip | ✓ WIRED (no pushReplacement) |
| Observer `onRelock` | `setState(_isLocked=true)` | paused→resumed guard | ✓ WIRED |
| Observer `onMask`/`onUnmask` | `_maskVisible` ValueNotifier | inactive/resumed | ✓ WIRED in `MaterialApp.builder` |
| `beginAuth`/`endAuth` | `AppLockScreen` biometric fence | onBeginAuth/onEndAuth props | ✓ WIRED |
| SecuritySection toggle | `enableLock`/`disableLock`/`reauth` | after-PIN / reauth-first | ✓ WIRED |
| onboarding skip | `setAppLockEnabled(false)` | D-02 legacy retired | ✓ WIRED |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| LOCK-01 | 03/07/10/11 | ✓ SATISFIED | Settings master toggle + complete no-op when disabled |
| LOCK-02 | 11 | ✓ SATISFIED | Cold-start `_isLocked` gate before shell |
| LOCK-03 | 06/11/12 | ✓ SATISFIED | paused→resumed relock guard unit-tested and verified on-device; no relock loop; Control Center remains inactive-only |
| LOCK-04 | 06/08/11 | ✓ SATISFIED | Opaque PrivacyMask on inactive; app-switcher snapshot timing verified on-device |
| LOCK-05 | 02/09 | ✓ SATISFIED | Biometric auto-trigger → PIN fallback |
| LOCK-06 | 03/07/08/09/10 | ✓ SATISFIED | 4-digit forced fallback, double-entry set-PIN |
| LOCK-07 | 01/07 | ✓ SATISFIED | Argon2id off-isolate, constant-time, unlocked_this_device |
| LOCK-08 | 05 | ✓ COVERED-BY-DESCOPE | →LOCK-V2-04 (D-06); REQUIREMENTS + ROADMAP both annotated; invariants (no wipe/no recovery/no counter) hold |
| LOCK-09 | 04 | ✓ SATISFIED | Unrecoverable copy in 3 locales |
| LOCK-10 | 02 | ✓ SATISFIED | Full LocalAuthException classification + wildcard → PIN |

No orphaned requirements: every LOCK-01..10 ID declared in plan frontmatter maps to REQUIREMENTS.md; LOCK-08 explicitly descoped (not silently dropped) with LOCK-V2-04 tracking row.

### Anti-Patterns Found

None. No TODO/FIXME/XXX/TBD/PLACEHOLDER debt markers in any phase-modified source under `lib/features/applock`, `lib/application/security`, `pin_kdf.dart`, or `app_lock_lifecycle_observer.dart`.

### Human Verification Resolved

`55-UAT.md` is the canonical device record. All six tests completed on a physical Face ID iPhone on 2026-07-01: background→foreground relock, opaque app-switcher snapshot, Control/Notification Center no-relock, biometric-only→app PIN fallback, Keychain upgrade boot, and Argon2id feel. Five passed directly; the ~1s unlock feel passed with non-blocking follow-up `LOCK-V2-05`. Gap-closure plan 55-12 fixed and re-verified G1–G4. No device check remains pending.

### Gaps Summary

No gaps. Every success criterion (LOCK-01..10, with LOCK-08 covered-by-descope) is satisfied in code and the device-only behaviors are closed by `55-UAT.md`. Gap-closure 55-12 additionally guarantees biometric-only authentication (never iOS device passcode), supplies the Face ID usage description, and honors the biometric-off PIN-only path. The sole follow-up is the explicitly non-blocking `LOCK-V2-05` performance polish.

---

_Verified: 2026-08-05 (device UAT evidence: 2026-07-01)_
_Verifier: Claude (gsd-verifier)_
