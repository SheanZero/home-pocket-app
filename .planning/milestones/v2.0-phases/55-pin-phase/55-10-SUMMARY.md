---
phase: 55-pin-phase
plan: 10
subsystem: security
tags: [app-lock, pin, set-pin, reauth, biometric, settings, deep-link, flutter, riverpod]

# Dependency graph
requires:
  - phase: 55-04
    provides: app-lock ARB keys (appLockSetPinTitle/ConfirmPinTitle/PinMismatch, securityAppLock/Description, securityChangePin, securityBiometricUnlock/Description, appLockReauthReason)
  - phase: 55-07
    provides: AppLockService (setPin/verifyPin/reauth/enableLock/disableLock/isLockEffective) + appLockServiceProvider + biometricAvailabilityProvider
  - phase: 55-08
    provides: presentational PinKeypad + PinDots (shake/clear) tone-B widgets
  - phase: 54-03
    provides: SettingsScreen scrollToSecurity deep-link scaffold (jumpTo + post-frame ensureVisible, KeyedSubtree SecuritySection)
provides:
  - SetPinScreen — reusable double-entry set-PIN flow (enter -> confirm, mismatch restarts, never persists a half-entry)
  - SecuritySection refactored into the app-lock master toggle + revealed sub-items (biometric sub-toggle + 修改 PIN)
  - Re-auth gate (biometric or in-place PIN verify) before disable AND change (D-05)
  - Phase 54 deep-link auto-opens set-PIN when arriving lock-not-set (D-10)
affects: [55-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-step PIN state machine driving Plan 08 PinKeypad/PinDots (enter -> confirm), success via onCompleted callback or Navigator.pop(true)"
    - "Settings master-toggle arms only after a successful pushed flow returns true (never enable without a PIN); revert is implicit because the switch value is bound to settings, not local state"
    - "D-05 reusable re-auth: AppLockService.reauth() biometric first, falling back to an in-place _PinReauthDialog (verifyPin), NOT the wave-3 AppLockScreen (keeps Plan 10 race-free)"
    - "Deep-link lock-not-set derived from in-hand settings.appLockEnabled (no async provider read) to stay test-safe"

key-files:
  created:
    - lib/features/applock/presentation/screens/set_pin_screen.dart
    - test/widget/features/applock/set_pin_screen_test.dart
    - test/widget/features/settings/security_section_test.dart
  modified:
    - lib/features/settings/presentation/widgets/security_section.dart
    - lib/features/settings/presentation/screens/settings_screen.dart
    - test/widget/features/settings/settings_screen_scroll_to_security_test.dart

key-decisions:
  - "SetPinScreen reports success via optional onCompleted callback; when null it pops(true) so a Navigator.push<bool> caller (master toggle / 修改 PIN / deep-link) arms the lock"
  - "Disable/change re-auth falls back to a minimal in-place _PinReauthDialog (verifyPin) rather than reusing AppLockScreen — only depends on Plan 07, avoiding a wave-3 cross-plan race"
  - "D-10 lock-not-set is read from settings.appLockEnabled (synchronous, in-hand) instead of appLockService.isLockEffective() to avoid an async keychain/prefs read that would throw in the Phase 54 widget test"
  - "Phase 54 scroll test pinned to appLockEnabled:true for its scroll-scope cases; D-10 auto-open behavior covered by two new cases in the same file"

patterns-established:
  - "Pushed full-screen flow returns a bool result; caller performs the privileged state change (enableLock) only on true"
  - "Sub-items gated by biometricAvailabilityProvider via switch on AsyncValue.value (nullable) — hidden when loading/unavailable"

requirements-completed: [LOCK-01, LOCK-06]

coverage:
  - id: D1
    description: "Double-entry SetPinScreen: enter then re-enter; match calls setPin, mismatch restarts and never persists"
    requirement: "LOCK-06"
    verification:
      - kind: unit
        ref: "test/widget/features/applock/set_pin_screen_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "SecuritySection master toggle: enable requires PIN (reverts on cancel), disable requires reauth, sub-items revealed when enabled, notifications kept"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "test/widget/features/settings/security_section_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase 54 deep-link auto-opens set-PIN when lock not set; no-op when already set"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "test/widget/features/settings/settings_screen_scroll_to_security_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "On-device set/change/disable + deep-link arrival feel (visual + haptic) verified end-to-end"
    verification: []
    human_judgment: true
    rationale: "Biometric reauth dialog, haptics, and the real onboarding->settings deep-link push require a physical device (Plan 11 device QA)"

# Metrics
duration: 18min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 10: Settings App-Lock Control Surface Summary

**The Settings security area now arms/disarms the app lock through a double-entry set-PIN flow that never enables without a PIN and never disables or changes without re-authentication, and the Phase 54 onboarding deep-link lands on Security and opens set-PIN directly.**

## Performance

- **Duration:** ~18 min
- **Completed:** 2026-06-30
- **Tasks:** 3 of 3
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- **SetPinScreen (D-03/LOCK-06):** a reusable two-step state machine over the Plan 08 PinKeypad/PinDots. Type 4 digits → advance to confirm; same 4 → `AppLockService.setPin` then report success; different 4 → `appLockPinMismatch`, shake+clear, restart at enter. A typo can never persist a PIN the user does not know (T-55-26). The half-entered first PIN lives only in widget state.
- **SecuritySection refactor (D-11/LOCK-01):** replaced the old `biometricLock` switch with an app-lock master `SwitchListTile` whose value mirrors `settings.appLockEnabled`. ON pushes SetPinScreen and persists `appLockEnabled=true` only on success — else the switch stays off (T-55-24, never lock without a PIN). When enabled it reveals the `生体認証で解除` sub-toggle (gated by `biometricAvailabilityProvider`) and a `修改 PIN` entry. The `notifications` tile is kept verbatim.
- **Re-auth gate (D-05/T-55-25):** OFF and `修改 PIN` both call a reusable re-auth step — biometric (`AppLockService.reauth()`) first, falling back to an in-place `_PinReauthDialog` that verifies the current PIN via `verifyPin`. Only on success does it `disableLock()` / re-open SetPinScreen.
- **Deep-link auto-open (D-10):** `_maybeScrollToSecurity` now, when `scrollToSecurity` AND the lock is not yet set, pushes SetPinScreen after the existing ensureVisible and arms the lock on success — one-shot via the existing `_didScrollToSecurity` guard. Non-deep-link callers are unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Phase 54 scroll test broke once D-10 became active**
- **Found during:** Task 3
- **Issue:** `settings_screen_scroll_to_security_test.dart` overrode `appSettingsProvider` with `appLockEnabled:false`, so the new D-10 auto-open fired inside it and pushed SetPinScreen, which overflowed the deliberately-tiny 300px test viewport and changed which `Scrollable` was `.first`.
- **Fix:** Pinned the two scroll-scope cases to `appLockEnabled:true` (keeping them pure scroll tests) and added two dedicated D-10 cases (lock-not-set auto-opens; lock-already-set no-op) in the same file. This keeps Phase 54's behavior green while covering the new behavior.
- **Files modified:** test/widget/features/settings/settings_screen_scroll_to_security_test.dart
- **Commit:** 1073dd9b

### Design choices (within plan latitude)

- D-10 lock-not-set is read from the in-hand `settings.appLockEnabled` rather than `appLockService.isLockEffective()` (the plan allowed either). The async path would have triggered a real keychain/SharedPreferences read in the Phase 54 widget test (no override) and thrown; the synchronous proxy is the correct onboarding signal and keeps the test race-free.

## Verification

- `flutter analyze` — 0 issues (full project).
- `flutter test` set_pin_screen_test (3) + security_section_test (7) + settings_screen_scroll_to_security_test (4) — all green.
- Regression: full `test/widget/features/settings/`, `test/widget/features/onboarding/`, `test/widget/features/applock/` — 60/60 passing (Phase 54 onboarding + settings stay green).
- No goldens added (widget-only tests), so no macOS baselining required.

## Threat Mitigations Applied

- **T-55-24 (lock without a PIN):** master toggle persists `appLockEnabled` only after SetPinScreen returns true (security_section_test: enable-requires-PIN + revert-on-cancel).
- **T-55-25 (unlocked phone disables/changes lock):** reauth required before disable AND change (security_section_test: biometric-success disable + PIN-fallback disable).
- **T-55-26 (set-PIN typo lockout):** double-entry confirm; mismatch restarts and never persists (set_pin_screen_test).

## Known Stubs

None.

## Self-Check: PASSED
