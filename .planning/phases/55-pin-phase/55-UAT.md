---
status: testing
phase: 55-pin-phase
source: [55-VERIFICATION.md]
started: 2026-06-30T06:50:00Z
updated: 2026-07-01T06:00:00Z
---

## Current Test

number: 3
name: Full-UAT continuation — Tests 3–6 (mask timing, Control Center, KDF latency, keychain upgrade)
expected: |
  Tests 1 & 2 already PASS (55-12). Now running the remaining on-device checks: app-switcher
  snapshot shows the opaque mask (3); Control Center / Notification Center does NOT relock (4);
  Argon2id set-PIN/unlock latency in band (5); an upgrade-over-existing-install still boots and
  forgot-PIN copy is honest (6).
awaiting: user runs Tests 3–6 on device and reports each outcome.

## Tests

### 1. Arm the lock — enable + set-PIN (double-entry) + first unlock
expected: Enabling app lock forces a 4-digit PIN via the double-entry SetPinScreen (mismatch shakes+clears, no half-entry persisted; cancel ⇒ toggle stays OFF). Once armed, biometric sub-toggle + 修改 PIN are revealed and the master toggle is ON. Disabling the lock requires re-auth (PIN or biometric) first (D-05).
result: pass
reported: "解锁是用的iphone密码，不是应用自己的pin码 (screenshot: iOS system '为 Home Pocket 输入 iPhone 密码 / 需要验证身份以继续' device-passcode panel shown instead of the app's own 4-digit PIN screen)"
severity: major
note: "FIXED + verified on-device 2026-07-01 via gap-closure 55-12. Three gaps closed: G2 (biometric-only — device passcode no longer accepted, commit d7870f8c), G3 (NSFaceIDUsageDescription — Face ID no longer TCC-crashes, commit a27c6b91), G4 (biometricUnlockEnabled honored — with biometric OFF the lock opens straight on the app's own PIN keypad, commit e0599330). User approved: with biometric OFF → app PIN keypad directly, no Face ID/iOS-passcode sheet; with biometric ON → Face ID auto-prompt, cancel → app's own PIN. Prior blocker G1 (init crash) also FIXED + verified."

### 2. Background→foreground relock with Face ID auto-prompt (real device)
expected: Fully backgrounding the app (home / app-switcher) then returning re-shows the lock screen with a Face ID auto-prompt. NO flicker and NO relock loop after the Face ID sheet dismisses. Cancelling Face ID stays on the Face ID page with 重試 + パスコードを使用 → tap → PIN page; wrong PIN shakes+clears and is instantly retryable; correct PIN unlocks.
result: pass
note: "Verified on-device 2026-07-01 (55-12 approved). Relock re-shows the lock screen; with biometric ON the Face ID auto-prompt returns and cancel routes to the app's own PIN; with biometric OFF the relock lands directly on the PIN keypad (G4). No relock loop / iOS-passcode sheet."

### 3. App-switcher snapshot mask frame timing (real device)
expected: The app's app-switcher snapshot card shows the opaque brand cover, NOT any ledger amounts — the mask paints before the OS captures the snapshot.
result: [pending]

### 4. Control Center / Notification Center does NOT relock (real device)
expected: Pulling down Control Center / Notification Center (without backgrounding) does NOT relock on return — the mask may briefly show, but there is no PIN/Face prompt afterward.
result: [pending]

### 5. Argon2id on-device KDF latency
expected: Set-PIN and unlock feel responsive — Argon2id (m=19456,t=2,p=1) derivation ~250–500 ms on a modern device (acceptable band 150–800 ms). File a follow-up if far outside the band.
result: pass_with_followup
reported: "输入正确密码后，进入主页面有明显卡顿 (~1 秒). Confirmed 两段都有 (both the verify pause AND the main-page render)."
severity: minor
note: "~1s — perceptible but NOT far outside band, non-blocking, not a phase-55 regression. Two contributors: (A) Argon2id verify is off-isolate (Isolate.run, non-blocking) but the PIN dots sit filled with NO loading indicator during the ~hundreds-of-ms derive → reads as frozen. The KDF cost (19MiB/t=2) is intentional — D-06 made memory-hard hashing the SOLE brute-force defense (rate-limiting descoped), so it must NOT be lowered. (B) On unlock, MainShellScreen eager-builds 4 tabs (Home/List/Analytics/Shopping) in an IndexedStack + all their providers cold-load → first-frame jank; pre-existing (cold boot into the shell has the same cost), independent of app-lock. Disposition: deferred to v2 as LOCK-V2-05 (① lock-screen verify feedback, ② shell lazy-tab first-frame optimization) — both security-neutral. Cold-boot A/B comparison (Test Q2) not run; classification of (B) as pre-existing is from code reasoning (MainShellScreen has no app-lock-specific path)."

### 6. Keychain upgrade-boot (existing install survives an app upgrade)
expected: An app upgraded over an existing install still boots normally (KeychainAccessibility.unlocked_this_device unchanged ⇒ master key still readable; no brick-on-upgrade, T-55-30). Also confirm the forgot-PIN copy states it is unrecoverable (reinstall + loss of unsynced local data) with no implied recovery path.
result: [pending]

## Summary

total: 6
passed: 2
pass_with_followup: 1
issues: 0
pending: 3
skipped: 0
blocked: 0
note: "Tests 1 & 2 PASS (55-12: G2+G3+G4). Test 5 pass_with_followup (~1s unlock lag → deferred to LOCK-V2-05, non-blocking, not a regression). Still pending: Test 3 (mask snapshot timing), Test 4 (Control Center no-relock), Test 6 (keychain upgrade-boot)."

## Gaps

# G1 — startup crash on real-device cold start (FIXED in code; needs on-device retest)
- truth: "App boots to the shell/onboarding/lock gate on a real-device cold start"
  status: fixed_verified
  reason: "User reported (screenshot): 初期化失败 ProviderException: Tried to use a provider that is in error state. AsyncValueIsLoadingException: requireValue was called on AsyncLoading<SharedPreferences>(). App never booted → all 6 tests blocked."
  severity: blocker
  test: 1
  root_cause: "settingsRepository (repository_providers.dart:25) is a *synchronous* provider that calls `.requireValue` on the *async* sharedPreferencesProvider. main.dart _initialize() reads it via `ref.read(settingsRepositoryProvider)` (no retry). On a real-device cold start, SharedPreferences.getInstance() is still AsyncLoading when _seedAndEnsureDefaultBook() returns, so the read rethrows the transient AsyncValueIsLoadingException as a fatal init failure. Simulator/warm-start won the race, which is why earlier phases passed. Never caught by tests: every boot smoke test overrode settingsRepositoryProvider with a fake, short-circuiting the real prefs chain ([[main-dart-boot-provider-characterization-test-gap]])."
  artifacts:
    - path: "lib/main.dart"
      issue: "_initialize() + _reinitializeAfterDataReset() read the sync settingsRepository before sharedPreferences is guaranteed resolved"
  missing:
    - "Pre-warm `await ref.read(sharedPreferencesProvider.future)` before the settingsRepository read in both boot paths (DONE)"
    - "Regression test exercising the REAL settings→prefs chain with prefs held in AsyncLoading (DONE — main_characterization_smoke_test.dart)"
  fix_commit: "(this commit)"
  debug_session: ""

# G2 — unlock authenticates with the iOS device passcode, not the app's own 4-digit PIN
- truth: "App-lock authentication uses the app's OWN 4-digit Argon2id-hashed PIN (with Face ID as an optional convenience) — the iOS device passcode is NEVER the credential"
  status: fixed_verified
  reason: "User reported (screenshot): the unlock/auth prompt is the iOS system panel '为 “Home Pocket” 输入 iPhone 密码 / 需要验证身份以继续' — a 6-dot device-passcode entry with the native iOS keypad — instead of the app's own PIN screen. Verbatim: '解锁是用的iphone密码，不是应用自己的pin码'. This is the LocalAuthentication device-passcode fallback (deviceOwnerAuthentication) rather than the custom PIN flow, which defeats the central premise of the pin-phase (an app-specific PIN independent of the device passcode)."
  severity: major
  test: 1
  root_cause: "BiometricService.authenticate() defaults biometricOnly=false → local_auth uses iOS LAPolicy.deviceOwnerAuthentication, which allows the device passcode as a fallback (iOS renders its own 'Enter iPhone passcode' sheet and returns success). Both real call sites invoke authenticate() WITHOUT biometricOnly:true, so both inherit the passcode-allowing default, bypassing the app's own PIN-fallback surface (which is already fully built via AuthResult.fallbackToPIN)."
  artifacts:
    - path: "lib/features/applock/presentation/screens/app_lock_screen.dart"
      issue: "_runBiometric() line 94 calls authenticate(reason: reason) without biometricOnly:true — the unlock auto-prompt the user hit; Face ID cancel/fail drops to iOS device passcode instead of AppLockSurface.pin"
    - path: "lib/application/security/app_lock_service.dart"
      issue: "reauth() line 67 (D-05 disable/change-PIN gate) calls authenticate(reason:...) without biometricOnly:true — same device-passcode leak"
    - path: "lib/infrastructure/security/biometric_service.dart"
      issue: "authenticate() biometricOnly defaults to false (line 84) — the passcode-allowing default both callers inherit"
  missing:
    - "Pass biometricOnly:true at both call sites (app_lock_screen.dart:94, app_lock_service.dart:67) — OR flip BiometricService.authenticate default to true (app never wants device-passcode fallback)"
    - "Regression test: fake LocalAuthentication asserts authenticate is invoked with biometricOnly:true from the unlock screen + reauth()"
    - "On-device re-verify Test 1 + Test 2: cancelling Face ID must land on the app's OWN PIN page, never the iOS passcode sheet"
  debug_session: ".planning/debug/55-g2-auth-device-passcode.md"

# G3 — Face ID TCC crash (__abort_with_payload) after the biometric-only fix
- truth: "Invoking app-lock Face ID on a real device authenticates without crashing"
  status: fixed_verified
  reason: "After the G2 biometric-only change, the first real Face ID invocation TCC-aborted the app (lldb: thread on 'com.apple.tcc.auth.kTCCServiceFaceID', __abort_with_payload). Surfaced only after G2 because biometric-only (deviceOwnerAuthenticationWithBiometrics) forces an actual Face ID call, whereas the prior passcode-allowing policy silently degraded to the passcode sheet."
  severity: blocker
  test: 1
  root_cause: "ios/Runner/Info.plist was missing NSFaceIDUsageDescription. iOS requires that privacy usage-description string before an app may evaluate any LAPolicy that invokes Face ID; without it the first Face ID evaluation is TCC-killed. The same missing key ALSO caused the original G2 passcode fallback (Face ID uninvokable → local_auth presented the device passcode sheet)."
  artifacts:
    - path: "ios/Runner/Info.plist"
      issue: "no NSFaceIDUsageDescription key (only NSMicrophone/NSSpeechRecognition were present)"
  missing:
    - "Add NSFaceIDUsageDescription (Japanese, matching the existing usage-description convention) — DONE"
    - "Clean device rebuild so the new Info.plist ships (an incremental install keeps the old plist) — verified on-device"
  fix_commit: "a27c6b91"
  debug_session: ".planning/debug/55-g3-faceid-tcc-crash.md"

# G4 — lock screen auto-prompts Face ID even when biometric unlock is OFF
- truth: "With biometricUnlockEnabled OFF, the lock screen opens directly on the app's own PIN keypad and never auto-invokes biometrics (LOCK-07)"
  status: fixed_verified
  reason: "User reported: Settings showed 应用锁 ON but 生物识别解锁 OFF, yet opening the app ran a Face ID prompt. The biometric toggle was ignored by the boot lock gate."
  severity: major
  test: 1
  root_cause: "lib/main.dart _buildHome() mounted AppLockScreen without startOnPinPage, so it defaulted false and always auto-fired the Face ID prompt. main.dart read the settings object at boot (which carries biometricUnlockEnabled) but discarded that field — it only derived _isLocked from appLockEnabled && pinHash."
  artifacts:
    - path: "lib/main.dart"
      issue: "AppLockScreen mount omitted startOnPinPage; biometricUnlockEnabled never captured from the boot settings read"
  missing:
    - "Capture settings.biometricUnlockEnabled on both boot paths + pass startOnPinPage: !_biometricUnlockEnabled — DONE"
    - "Smoke-test guard: biometric-OFF boot shows the PIN page with zero authenticate calls; biometric-ON auto-prompts once — DONE (main_characterization_smoke_test.dart)"
  fix_commit: "e0599330"
  debug_session: ".planning/debug/55-g4-biometric-toggle-ignored.md"
