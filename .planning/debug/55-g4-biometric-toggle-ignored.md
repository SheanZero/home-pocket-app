# Debug: G4 — lock screen auto-prompts Face ID even when biometric unlock is OFF

**Phase:** 55 (pin-phase) · gap-closure 55-12 follow-on
**Date:** 2026-07-01
**Status:** ROOT CAUSE CONFIRMED → fix applied (main.dart wiring), on-device re-verify pending

---

## Symptom

On-device: Settings shows **应用锁 ON** but **生物识别解锁 (biometricUnlockEnabled) OFF**.
Yet on app open / relock the lock screen immediately runs a **Face ID** prompt.
Expected: with biometric unlock disabled, the lock screen should open straight on the
app's own 4-digit PIN keypad and never invoke biometrics.

## Root cause

`AppLockScreen` already supports this via its `startOnPinPage` flag
("Start directly on the PIN page (PIN-only config / biometric disabled)") — when true it
skips the `initState` post-frame `_runBiometric()` auto-prompt.

But the **caller never wired it**. `lib/main.dart` `_buildHome()` mounted:

```dart
AppLockScreen(
  onUnlocked: _completeUnlock,
  onBeginAuth: _lockObserver?.beginAuth,
  onEndAuth: _lockObserver?.endAuth,
)   // startOnPinPage omitted → defaults false → always auto-fires Face ID
```

`main.dart` reads `settings` at boot (which carries `biometricUnlockEnabled`) but discarded
that field — it only derived `_isLocked`/`_lockConfigured` from `appLockEnabled && pinHash`.
So biometric auto-prompt fired unconditionally, ignoring the user's toggle.

## Fix

`lib/main.dart`:
- New field `bool _biometricUnlockEnabled = false;`
- Captured in BOTH boot paths (`_initialize` + `_reinitializeAfterDataReset`) inside the
  existing `setState`, alongside `_isLocked`, from the already-read `settings`.
- Mount now passes `startOnPinPage: !_biometricUnlockEnabled`.

No new provider read (uses the settings object already fetched at boot), so the
main-dart-boot-provider characterization-test gap does not apply.

## Verification (TDD)

`test/main_characterization_smoke_test.dart` (app-lock gate wiring group):
- `_FakeSettingsRepository` + `_pumpApp` gained a `biometricUnlockEnabled` param;
  added `_SpyBiometricService` (counts `authenticate` calls).
- RED (new): **G4 biometric OFF** → after boot the PIN page is shown
  (`ValueKey('app-lock-forgot-pin')` present) and `spy.authenticateCalls == 0`.
  Failed before the fix (screen stayed on the Face ID surface, auto-fired once).
- **G4 biometric ON** → `spy.authenticateCalls == 1`, PIN page not yet shown.
- LOCK-03 relock test updated to set `biometricUnlockEnabled: true` (it relies on the
  boot auto-prompt).
- GREEN: `flutter analyze` 0 issues; full `flutter test` = **3472 passed / 0 fail** (exit 0).

On-device re-verify still required (Face ID hardware): with 生物识别解锁 OFF, lock →
open → land directly on the PIN keypad, no Face ID sheet; with it ON, the Face ID
auto-prompt returns (cancel → app PIN).
