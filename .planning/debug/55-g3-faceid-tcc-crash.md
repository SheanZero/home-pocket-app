# Debug: G3 — Face ID TCC crash on biometric-only unlock

**Phase:** 55 (pin-phase) · gap-closure 55-12 follow-on
**Date:** 2026-07-01
**Status:** ROOT CAUSE CONFIRMED → fix applied (Info.plist), on-device re-verify pending

---

## Symptom

On-device (physical iPhone, Face ID enrolled), after the 55-12 biometric-only fix
(`d7870f8c`), triggering app-lock unlock crashes the app:

```
thread #11, queue = 'com.apple.tcc.auth.kTCCServiceFaceID',
stop reason = abort with payload or reason
frame #0: libsystem_kernel.dylib`__abort_with_payload + 8
```

The abort is raised by the system **TCC** daemon on the `kTCCServiceFaceID` queue —
the OS terminated the process, not a Dart exception.

## Root cause

`ios/Runner/Info.plist` was **missing `NSFaceIDUsageDescription`**. iOS requires this
privacy usage-description string before an app may evaluate any `LAPolicy` that invokes
Face ID; without it, the first real Face ID invocation is TCC-aborted (`__abort_with_payload`).

Only `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` were present
(voice-entry feature). Face ID / biometric app-lock never added its key.

## Why this ALSO explains the original G2 symptom

The missing key is the single common cause of both observed behaviors:

| Build | Policy (from `biometricOnly`) | iOS behavior with NO usage-description key |
|-------|-------------------------------|--------------------------------------------|
| before 55-12 fix | `biometricOnly:false` → `deviceOwnerAuthentication` | Face ID uninvokable → iOS presents the **device-passcode sheet** as fallback → "passcode accepted" (**G2**). No crash — passcode is a legal fallback for this policy. |
| after 55-12 fix | `biometricOnly:true` → `deviceOwnerAuthenticationWithBiometrics` | No passcode fallback allowed → iOS **must** invoke Face ID → TCC finds no usage description → `__abort_with_payload` **crash** (**G3**). |

So G2 (passcode accepted) was a downstream symptom of the same missing key: Face ID was
never truly evaluated, so `local_auth` degraded to the passcode sheet. The Dart
biometric-only change was correct but insufficient on its own — biometric-only cannot run
on-device until the plist key exists.

## Fix

`ios/Runner/Info.plist`: add
```xml
<key>NSFaceIDUsageDescription</key>
<string>アプリロックの解除に Face ID を使用します</string>
```
(Japanese-only, matching the existing usage-description convention in this Info.plist —
no `InfoPlist.strings` localization is used in this project.)

`plutil -lint ios/Runner/Info.plist` → OK.

## Verification

- Cannot be unit-tested (`local_auth` is mocked in all suites; TCC only applies on device).
- Requires a clean device rebuild so the new Info.plist ships: `flutter clean && flutter pub get`
  then reinstall — an incremental install can keep the old Info.plist and reproduce the crash.
- On-device re-verify = 55-12 Task 3 (UAT Test 1 + Test 2): Face ID prompt appears (no crash);
  cancel → app's own 4-digit PIN page; iOS device-passcode sheet never shown.
