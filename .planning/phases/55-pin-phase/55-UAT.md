---
status: testing
phase: 55-pin-phase
source: [55-VERIFICATION.md]
started: 2026-06-30T06:50:00Z
updated: 2026-06-30T06:50:00Z
---

## Current Test

number: 1
name: Arm the lock — enable app lock, set a 4-digit PIN (double-entry), first unlock
expected: |
  Settings → 安全 → enable アプリロック requires setting a PIN first; the double-entry
  set-PIN screen accepts a matching pair (mismatch shakes+clears, never persists a
  half-entry); cancelling set-PIN leaves the toggle OFF. After arming, the biometric
  sub-toggle and 修改 PIN appear; the master toggle is ON.
awaiting: user response

## Tests

### 1. Arm the lock — enable + set-PIN (double-entry) + first unlock
expected: Enabling app lock forces a 4-digit PIN via the double-entry SetPinScreen (mismatch shakes+clears, no half-entry persisted; cancel ⇒ toggle stays OFF). Once armed, biometric sub-toggle + 修改 PIN are revealed and the master toggle is ON. Disabling the lock requires re-auth (PIN or biometric) first (D-05).
result: [pending]

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
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
