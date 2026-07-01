# DEBUG: App-lock auth uses iOS device passcode, not the app's own PIN (G2)

**Phase:** 55-pin-phase
**Gap:** G2 (UAT Test 1)
**Status:** ROOT CAUSE FOUND
**Goal:** find_root_cause_only

---

## Symptoms

- **Truth (expected):** App-lock authentication uses the app's OWN 4-digit Argon2id-hashed PIN, with Face ID as optional convenience. The iOS device passcode is NEVER the credential; if Face ID is cancelled/unavailable, the app's OWN PIN page is the fallback (Test 2: 重試 + パスコードを使用 → app PIN page).
- **Actual (user, screenshot):** iOS system panel `为 "Home Pocket" 输入 iPhone 密码 / 需要验证身份以继续` — a 6-dot **device-passcode** entry with the native iOS keypad — appears instead of the app's PIN screen. Verbatim: “解锁是用的iphone密码，不是应用自己的pin码”.
- **Reproduction:** Test 1 in UAT (arm lock → unlock). Also reachable via background→foreground relock (Test 2) and D-05 reauth.
- **Errors:** None (no crash) — this is a wrong-credential behavior, not a failure.

---

## Root Cause

`BiometricService.authenticate({required reason, bool biometricOnly = false})`
(`lib/infrastructure/security/biometric_service.dart:82-84`) defaults
`biometricOnly = false`. It forwards that to `local_auth`:

```dart
await _localAuth.authenticate(
  localizedReason: reason,
  biometricOnly: biometricOnly,   // <-- false by default
  sensitiveTransaction: true,
  persistAcrossBackgrounding: true,
);
```

`local_auth` maps `biometricOnly: false` to iOS `LAPolicy.deviceOwnerAuthentication`,
which **permits the device passcode as a fallback**. iOS then renders its own
“Enter iPhone passcode” sheet and, on success, `authenticate` returns `true` — so
the app treats a **device-passcode** unlock as a successful biometric unlock and
never routes to its own PIN screen.

Both real call sites invoke `authenticate()` WITHOUT `biometricOnly: true`, so both
inherit the passcode-allowing default:

1. **`lib/features/applock/presentation/screens/app_lock_screen.dart:92-94`** —
   `_runBiometric()` (the unlock-screen Face ID auto-prompt). This is the path the
   user hit. Because `biometricOnly` defaults false, cancelling/failing Face ID drops
   into the iOS device-passcode sheet instead of the app's `AppLockSurface.pin` page.
2. **`lib/application/security/app_lock_service.dart:65-70`** — `reauth()` (D-05,
   used before disabling / changing the PIN). Same defect: re-auth can be satisfied by
   the iOS device passcode rather than biometric-or-app-PIN.

The biometric-only failure path is already fully built: `authenticate()` catches
every `LocalAuthException` and returns `AuthResult.fallbackToPIN()`, and
`_runBiometric()` already leaves the user on the Face ID surface with 重試 /
パスコードを使用 → app PIN page on any non-success. That intended flow is simply
**bypassed** whenever iOS is allowed to satisfy auth with the device passcode.

---

## Evidence Summary

- `biometricOnly` default is `false` (`biometric_service.dart:84`); doc comment on
  line 81 literally says “[biometricOnly] prevents device PIN fallback if true.”
- Grep of all `.authenticate(` callers: only 2 real sites, neither passes
  `biometricOnly` → both use the passcode-allowing default.
- Screenshot is the iOS `deviceOwnerAuthentication` device-passcode UI, not any
  Flutter-drawn screen in `lib/features/applock/presentation/screens/`.
- Test 2's expected fallback (パスコードを使用 → app PIN page) only fires when
  `local_auth` returns non-success, which requires `biometricOnly: true`.

---

## Files Involved

- `lib/features/applock/presentation/screens/app_lock_screen.dart:94` — unlock Face ID call omits `biometricOnly: true`.
- `lib/application/security/app_lock_service.dart:67` — `reauth()` call omits `biometricOnly: true`.
- `lib/infrastructure/security/biometric_service.dart:84` — `biometricOnly` defaults to `false` (the passcode-allowing default that both callers inherit).

---

## Suggested Fix Direction

Force biometric-only at both auth entry points so iOS never offers the device
passcode, letting the app own the fallback via its existing PIN surface:

- **Preferred (targeted, least-surprising):** pass `biometricOnly: true` at both call
  sites — `app_lock_screen.dart:94` and `app_lock_service.dart:67`.
- **Alternative (defensive default):** flip `BiometricService.authenticate`'s default
  to `biometricOnly = true`, since this app never wants a device-passcode fallback,
  and audit for any caller that legitimately wanted passcode fallback (none found).

Add a regression guard: a `BiometricService`/call-site test asserting `authenticate`
is invoked with `biometricOnly: true` from the unlock screen and `reauth()`
(fake `LocalAuthentication` recording the flag). Manual re-verify on device: Test 1 +
Test 2 — cancelling Face ID must land on the app's own PIN page, never the iOS
passcode sheet.
