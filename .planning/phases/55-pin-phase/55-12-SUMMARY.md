---
phase: 55-pin-phase
plan: 12
subsystem: security
gap_closure: true
tags: [app-lock, biometric, face-id, local-auth, ios, info-plist, flutter]

# Dependency graph
requires:
  - phase: 55-02
    provides: BiometricService.authenticate + LocalAuthException → AuthResult.fallbackToPIN mapping
  - phase: 55-09
    provides: AppLockScreen (Face ID surface + PIN surface, startOnPinPage flag)
  - phase: 55-11
    provides: main.dart app-lock gate branch mounting AppLockScreen
provides:
  - App-lock authentication is biometric-only — the iOS device passcode is never accepted (G2)
  - NSFaceIDUsageDescription so Face ID no longer TCC-crashes on invocation (G3)
  - Lock screen honors the biometricUnlockEnabled toggle (biometric OFF → PIN-only, no auto-prompt) (G4)
affects: [app-lock, security, main.dart, ios-native, biometric]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Secure-by-default: BiometricService.authenticate defaults biometricOnly=true (opt-in required for OS-passcode fallback)"
    - "iOS native privacy usage-description required before evaluating any Face ID LAPolicy"
    - "Boot settings field (biometricUnlockEnabled) threaded into AppLockScreen.startOnPinPage"

key-files:
  created:
    - .planning/debug/55-g3-faceid-tcc-crash.md
    - .planning/debug/55-g4-biometric-toggle-ignored.md
  modified:
    - lib/infrastructure/security/biometric_service.dart
    - lib/features/applock/presentation/screens/app_lock_screen.dart
    - lib/application/security/app_lock_service.dart
    - ios/Runner/Info.plist
    - lib/main.dart
    - test/infrastructure/security/biometric_service_test.dart
    - test/application/security/app_lock_service_test.dart
    - test/widget/features/applock/app_lock_screen_test.dart
    - test/main_characterization_smoke_test.dart

key-decisions:
  - "G2: flip biometricOnly default false→true AND pass biometricOnly:true explicitly at both call sites (defensive default + explicit intent)"
  - "G3: single missing NSFaceIDUsageDescription was the common root cause of BOTH the original G2 passcode fallback AND the post-fix crash"
  - "G4: main.dart captures biometricUnlockEnabled at boot and mounts AppLockScreen with startOnPinPage: !biometricUnlockEnabled"
---

# Plan 55-12 Summary — app-lock hardening (G2 + G3 + G4)

Gap-closure for Phase 55, spawned from on-device UAT (55-UAT.md Test 1). What began as
one gap (G2) uncovered two more once the app-lock path actually ran on real Face ID
hardware. All three are fixed, tested, and verified on-device (user approved 2026-07-01).

## G2 — device passcode accepted instead of the app's own PIN

**Root cause:** `BiometricService.authenticate` defaulted `biometricOnly = false` →
`local_auth` used `LAPolicy.deviceOwnerAuthentication`, which lets iOS satisfy auth with
the **device passcode**. Both call sites inherited the passcode-allowing default.

**Fix (commits `75a7f841` RED, `d7870f8c` GREEN):** flipped the default to
`biometricOnly = true` (secure-by-default) and made both real callers
(`app_lock_screen._runBiometric`, `app_lock_service.reauth`) pass `biometricOnly: true`
explicitly. Regression tests assert the flag reaches `local_auth` from both surfaces and
the default path.

## G3 — Face ID TCC crash (`__abort_with_payload`) after the G2 fix

**Root cause:** `ios/Runner/Info.plist` was missing `NSFaceIDUsageDescription`. Once G2
forced a biometric-only policy, the first real Face ID call was TCC-killed. The same
missing key ALSO explains the original G2 symptom — Face ID was uninvokable, so
`local_auth` silently degraded to the passcode sheet.

**Fix (commit `a27c6b91`):** added `NSFaceIDUsageDescription` (Japanese, matching the
existing usage-description convention; `plutil -lint` OK). Requires a clean device rebuild
so the new plist ships.

## G4 — Face ID prompt fired even with biometric unlock OFF

**Root cause:** `main.dart` mounted `AppLockScreen` without `startOnPinPage`, so it
defaulted false and always auto-fired the Face ID prompt — ignoring the
`biometricUnlockEnabled` toggle it already read at boot.

**Fix (commits `3c8bdeb5` RED, `e0599330` GREEN):** capture `biometricUnlockEnabled` on
both boot paths (`_initialize` + `_reinitializeAfterDataReset`) and mount with
`startOnPinPage: !_biometricUnlockEnabled`. Smoke-test guards: biometric-OFF boot shows
the PIN page with zero `authenticate` calls; biometric-ON auto-prompts exactly once.

## Verification

- `flutter analyze` — 0 issues.
- Full `flutter test` — **3472 passed / 0 failures** (exit 0). No scoped/tailed runs.
- Positive greps: `bool biometricOnly = true` in biometric_service.dart; `biometricOnly: true`
  at both call sites; `NSFaceIDUsageDescription` in Info.plist; `startOnPinPage: !_biometricUnlockEnabled`
  in main.dart.
- On-device (user-approved 2026-07-01, physical Face ID iPhone):
  - biometric OFF → lock opens straight on the app's own 4-digit PIN keypad; no Face ID / iOS-passcode sheet.
  - biometric ON → Face ID auto-prompt; cancel → app's own PIN page; device passcode never shown.
  - No TCC crash; no relock loop.

## Scope note

This gap-closure covers UAT Tests 1 & 2 (unlock credential + relock behavior). Tests 3–6
(app-switcher mask timing, Control Center no-relock, Argon2id KDF latency, keychain
upgrade-boot) remain **pending** — out of scope for 55-12, to be run in a later full-UAT pass.

## Deviations from plan

Plan 55-12 targeted G2 only (3 source + 3 test edits). On-device verification surfaced G3
and G4, which were fixed in the same gap-closure umbrella (each with its own debug note,
TDD RED/GREEN commits, and on-device re-verify) rather than deferred to new plans — the
fixes are small, tightly coupled to the same app-lock path, and were blocking the same UAT.
