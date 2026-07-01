---
status: testing
phase: 55-pin-phase
source: [55-VERIFICATION.md]
started: 2026-06-30T06:50:00Z
updated: 2026-07-01T05:00:00Z
---

## Current Test

number: 2
name: Background→foreground relock with Face ID auto-prompt (real device)
expected: |
  Fully backgrounding the app then returning re-shows the lock screen with a Face ID
  auto-prompt; NO flicker / relock loop after the sheet dismisses; cancelling Face ID
  → 重試 + パスコードを使用 → the app's OWN PIN page; wrong PIN shakes+clears, correct
  unlocks.
awaiting: paused — foundational issue found in Test 1 (G2), awaiting user decision to continue or stop

## Tests

### 1. Arm the lock — enable + set-PIN (double-entry) + first unlock
expected: Enabling app lock forces a 4-digit PIN via the double-entry SetPinScreen (mismatch shakes+clears, no half-entry persisted; cancel ⇒ toggle stays OFF). Once armed, biometric sub-toggle + 修改 PIN are revealed and the master toggle is ON. Disabling the lock requires re-auth (PIN or biometric) first (D-05).
result: issue
reported: "解锁是用的iphone密码，不是应用自己的pin码 (screenshot: iOS system '为 Home Pocket 输入 iPhone 密码 / 需要验证身份以继续' device-passcode panel shown instead of the app's own 4-digit PIN screen)"
severity: major
note: "Prior on-device run hit startup blocker G1 (init crash) — now FIXED + verified (analyze clean, 3468/3468 green). This rebuild booted, but authentication uses the iOS device passcode (LocalAuthentication device-passcode fallback), NOT the app's own Argon2id PIN. Defeats the central premise of the pin-phase. See Gap G2."

### 2. Background→foreground relock with Face ID auto-prompt (real device)
expected: Fully backgrounding the app (home / app-switcher) then returning re-shows the lock screen with a Face ID auto-prompt. NO flicker and NO relock loop after the Face ID sheet dismisses. Cancelling Face ID stays on the Face ID page with 重試 + パスコードを使用 → tap → PIN page; wrong PIN shakes+clears and is instantly retryable; correct PIN unlocks.
result: [pending]

### 3. App-switcher snapshot mask frame timing (real device)
expected: The app's app-switcher snapshot card shows the opaque brand cover, NOT any ledger amounts — the mask paints before the OS captures the snapshot.
result: [pending]

### 4. Control Center / Notification Center does NOT relock (real device)
expected: Pulling down Control Center / Notification Center (without backgrounding) does NOT relock on return — the mask may briefly show, but there is no PIN/Face prompt afterward.
result: [pending]

### 5. Argon2id on-device KDF latency
expected: Set-PIN and unlock feel responsive — Argon2id (m=19456,t=2,p=1) derivation ~250–500 ms on a modern device (acceptable band 150–800 ms). File a follow-up if far outside the band.
result: [pending]

### 6. Keychain upgrade-boot (existing install survives an app upgrade)
expected: An app upgraded over an existing install still boots normally (KeychainAccessibility.unlocked_this_device unchanged ⇒ master key still readable; no brick-on-upgrade, T-55-30). Also confirm the forgot-PIN copy states it is unrecoverable (reinstall + loss of unsynced local data) with no implied recovery path.
result: [pending]

## Summary

total: 6
passed: 0
issues: 1
pending: 5
skipped: 0
blocked: 0

## Gaps

# G1 — startup crash on real-device cold start (FIXED in code; needs on-device retest)
- truth: "App boots to the shell/onboarding/lock gate on a real-device cold start"
  status: fixed_pending_retest
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
  status: failed
  reason: "User reported (screenshot): the unlock/auth prompt is the iOS system panel '为 “Home Pocket” 输入 iPhone 密码 / 需要验证身份以继续' — a 6-dot device-passcode entry with the native iOS keypad — instead of the app's own PIN screen. Verbatim: '解锁是用的iphone密码，不是应用自己的pin码'. This is the LocalAuthentication device-passcode fallback (deviceOwnerAuthentication) rather than the custom PIN flow, which defeats the central premise of the pin-phase (an app-specific PIN independent of the device passcode)."
  severity: major
  test: 1
  root_cause: ""     # Filled by diagnosis — likely LAPolicy.deviceOwnerAuthentication (allows device passcode) used where the custom-PIN screen should own the fallback, or biometric path not routing to the app SetPin/UnlockPin screen
  artifacts: []      # Filled by diagnosis
  missing: []        # Filled by diagnosis
  debug_session: ""
