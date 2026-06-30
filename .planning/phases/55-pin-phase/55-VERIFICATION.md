---
phase: 55-pin-phase
verified: 2026-06-30T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Background→foreground relock with Face ID auto-prompt (real device)"
    expected: "Fully backgrounding (home/app-switcher) then returning re-shows the lock screen with a Face ID auto-prompt; NO flicker and NO relock loop after the Face ID sheet dismisses"
    why_human: "Real OS lifecycle (paused→resumed) + system Face ID sheet churn cannot be faithfully unit-tested; the _authInProgress fence logic is unit-covered, but real-device no-loop behavior is OS-driven (55-11 Task 4 step 2/5)"
  - test: "App-switcher snapshot mask frame timing (real device)"
    expected: "The app's app-switcher snapshot card shows the opaque brand cover, NOT any ledger amounts — the mask paints before the OS captures the snapshot"
    why_human: "OS snapshot capture timing vs the synchronous ValueNotifier mask flip is a frame-timing property invisible to widget tests (RESEARCH §5; 55-11 Task 4 step 3)"
  - test: "Control Center / Notification Center does NOT relock (real device)"
    expected: "Pulling down Control Center / Notification Center without backgrounding does not relock on return (mask may briefly show, no PIN/Face prompt)"
    why_human: "Distinguishing inactive-only (no relock) from a true paused round-trip requires real OS lifecycle events; unit-tested at the observer level but device confirmation is the contract (55-11 Task 4 step 4)"
  - test: "Argon2id on-device KDF latency"
    expected: "set-PIN + unlock derivation feels ~250–500 ms (acceptable band 150–800 ms); far outside → file a follow-up to tune params"
    why_human: "Real-hardware Argon2id (m=19456,t=2,p=1) latency cannot be measured in CI; on-device feel is the calibration check (RESEARCH §1; 55-11 Task 4 step 6)"
  - test: "Keychain upgrade-install boot (existing install)"
    expected: "An app upgraded over an existing install still boots (KeychainAccessibility.unlocked_this_device unchanged → master key still readable)"
    why_human: "Brick-on-upgrade (T-55-30) only manifests against a real prior-version keychain; accessibility constant is code-verified unchanged but the upgrade path is device-only"
---

# Phase 55: 应用锁（生物识别 + PIN） Verification Report

**Phase Goal:** 实现「已解密 DB 之上的 UI gate」应用锁：冷启动 + 回前台完整重锁、任务切换器隐私遮罩、生物识别优先 + 4 位 PIN 强制兜底；PIN 加盐慢哈希存入既有 secure storage；完整 local_auth 错误分类一律回退 PIN；Setting 可开关、关闭时完全 no-op。
**Verified:** 2026-06-30
**Status:** human_needed
**Re-verification:** No — initial verification

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
| LOCK-03 | 06/11 | ✓ SATISFIED | paused→resumed relock guard (unit-tested); device confirm = human |
| LOCK-04 | 06/08/11 | ✓ SATISFIED | Opaque PrivacyMask on inactive; snapshot timing = human |
| LOCK-05 | 02/09 | ✓ SATISFIED | Biometric auto-trigger → PIN fallback |
| LOCK-06 | 03/07/08/09/10 | ✓ SATISFIED | 4-digit forced fallback, double-entry set-PIN |
| LOCK-07 | 01/07 | ✓ SATISFIED | Argon2id off-isolate, constant-time, unlocked_this_device |
| LOCK-08 | 05 | ✓ COVERED-BY-DESCOPE | →LOCK-V2-04 (D-06); REQUIREMENTS + ROADMAP both annotated; invariants (no wipe/no recovery/no counter) hold |
| LOCK-09 | 04 | ✓ SATISFIED | Unrecoverable copy in 3 locales |
| LOCK-10 | 02 | ✓ SATISFIED | Full LocalAuthException classification + wildcard → PIN |

No orphaned requirements: every LOCK-01..10 ID declared in plan frontmatter maps to REQUIREMENTS.md; LOCK-08 explicitly descoped (not silently dropped) with LOCK-V2-04 tracking row.

### Anti-Patterns Found

None. No TODO/FIXME/XXX/TBD/PLACEHOLDER debt markers in any phase-modified source under `lib/features/applock`, `lib/application/security`, `pin_kdf.dart`, or `app_lock_lifecycle_observer.dart`.

### Human Verification Required

The phase carries an intentional, blocking on-device QA checkpoint (plan 55-11 Task 4) for behaviors that are OS/device-driven and cannot be faithfully unit-tested. These are NOT gaps — the underlying logic is code-verified and unit-tested; only the real-device integration remains:

1. **Background→foreground relock + Face ID** — fully background then return; lock re-shows with Face ID auto-prompt, NO flicker, NO relock loop after the sheet dismisses.
2. **App-switcher snapshot mask** — snapshot card shows opaque brand cover, no ledger amounts (mask paints before OS snapshot).
3. **Control Center / Notification Center no-relock** — pulling down without backgrounding does not relock on return.
4. **Argon2id on-device latency** — set-PIN/unlock ~250–500 ms (band 150–800 ms).
5. **Keychain upgrade-install boot** — upgrade over an existing install still boots (accessibility unchanged).

### Gaps Summary

No code-verifiable gaps. Every success criterion (LOCK-01..10, with LOCK-08 covered-by-descope) is satisfied in the codebase: gate wiring, full local_auth error classification, Argon2id off-isolate KDF with constant-time compare and unchanged keychain accessibility, settings enable/disable no-op, ARB tri-locale parity, and the no-pushReplacement setState gate flag. Automated baseline (orchestrator-confirmed): `flutter analyze` = 0 issues; full suite 3467/3467 passing. Status is `human_needed` solely because the phase's device-only behaviors (Face ID lifecycle, snapshot frame timing, KDF latency, keychain upgrade) require the blocking on-device QA checkpoint defined in plan 55-11.

---

_Verified: 2026-06-30_
_Verifier: Claude (gsd-verifier)_
