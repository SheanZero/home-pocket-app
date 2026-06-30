---
phase: 55-pin-phase
plan: 03
subsystem: settings
tags: [app-lock, shared-preferences, freezed, riverpod, onboarding]

# Dependency graph
requires:
  - phase: 54-onboarding-flow
    provides: onboarding_lock_entry_screen skip = "lock off" write-through (D-13)
provides:
  - AppSettings.appLockEnabled (default false) — D-01/LOCK-01 master toggle
  - AppSettings.biometricUnlockEnabled (default false) — D-01/LOCK-06 sub-toggle
  - SettingsRepository.setAppLockEnabled / setBiometricUnlockEnabled setters
  - SharedPreferences keys app_lock_enabled / biometric_unlock_enabled (plaintext, no Drift)
  - onboarding skip repointed to setAppLockEnabled(false) (D-02 legacy retirement)
affects: [55-07-lock-effective-predicate, 55-10-security-section-refactor]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New gating booleans persist as plaintext one-key-per-field SharedPreferences (mirrors biometricLockEnabled), NO Drift migration, schemaVersion stays 22"

key-files:
  created: []
  modified:
    - lib/features/settings/domain/models/app_settings.dart
    - lib/features/settings/domain/repositories/settings_repository.dart
    - lib/data/repositories/settings_repository_impl.dart
    - lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart
    - test/unit/features/settings/domain/models/app_settings_test.dart
    - test/unit/data/repositories/settings_repository_impl_test.dart
    - test/widget/features/onboarding/onboarding_lock_entry_test.dart

key-decisions:
  - "Legacy biometricLockEnabled retained in the model (not removed) to avoid breaking Phase 54 tests; it is retired only behaviorally — the new lock never reads it"
  - "Onboarding skip semantic moved from setBiometricLock(false) to setAppLockEnabled(false) per D-02"

patterns-established:
  - "Lock-gating flags default OFF (false) and persist as plaintext prefs — the secret (PIN hash) lives in keychain, not prefs"

requirements-completed: [LOCK-01, LOCK-06]

coverage:
  - id: D1
    description: "AppSettings exposes appLockEnabled (default false) master toggle"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "test/unit/features/settings/domain/models/app_settings_test.dart#creates with default values"
        status: pass
      - kind: unit
        ref: "test/unit/data/repositories/settings_repository_impl_test.dart#appLockEnabled (D-01/LOCK-01) setAppLockEnabled round-trips both directions"
        status: pass
    human_judgment: false
  - id: D2
    description: "AppSettings exposes biometricUnlockEnabled (default false) sub-toggle"
    requirement: "LOCK-06"
    verification:
      - kind: unit
        ref: "test/unit/data/repositories/settings_repository_impl_test.dart#biometricUnlockEnabled (D-01/LOCK-06) setBiometricUnlockEnabled round-trips both directions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Onboarding skip writes setAppLockEnabled(false); legacy biometricLockEnabled never written (D-02 / T-55-07)"
    verification:
      - kind: integration
        ref: "test/widget/features/onboarding/onboarding_lock_entry_test.dart#スキップ writes setAppLockEnabled(false) and completes setupSecurity:false"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 03: App-lock settings fields + legacy retirement Summary

**Added appLockEnabled + biometricUnlockEnabled (default OFF) to AppSettings as plaintext SharedPreferences booleans, and repointed the onboarding skip to setAppLockEnabled(false) — retiring the legacy biometricLockEnabled per D-02, with no Drift migration (schemaVersion stays 22).**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-06-30
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- `AppSettings` gained two default-false booleans (`appLockEnabled`, `biometricUnlockEnabled`) mirroring the `biometricLockEnabled` idiom exactly.
- `SettingsRepository` interface + impl gained `setAppLockEnabled` / `setBiometricUnlockEnabled` plus getSettings/updateSettings wiring against new keys `app_lock_enabled` / `biometric_unlock_enabled`.
- Onboarding lock-entry skip path repointed from `setBiometricLock(false)` to `setAppLockEnabled(false)` (D-02); the new lock never reads the legacy flag (T-55-07 mitigation).
- Regenerated freezed/g.dart; full `flutter analyze` clean (0 issues), 36 touched-file tests green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add appLockEnabled + biometricUnlockEnabled to AppSettings + repository** - `ee27ec49` (feat)
2. **Task 2: Retire legacy biometricLockEnabled — repoint onboarding skip (D-02)** - `b1ff9f69` (refactor)
3. **Task 3: Extend settings + onboarding tests** - `a5194f5d` (test)

## Files Created/Modified
- `lib/features/settings/domain/models/app_settings.dart` - Added two `@Default(false) bool` fields.
- `lib/features/settings/domain/models/app_settings.freezed.dart` / `.g.dart` - Regenerated.
- `lib/features/settings/domain/repositories/settings_repository.dart` - Added two setter signatures.
- `lib/data/repositories/settings_repository_impl.dart` - New keys, getSettings/updateSettings wiring, two setters.
- `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart` - Skip writes `setAppLockEnabled(false)`; doc comments updated.
- `test/unit/features/settings/domain/models/app_settings_test.dart` - Default-false + copyWith immutability assertions.
- `test/unit/data/repositories/settings_repository_impl_test.dart` - Round-trip + default-false groups for both new keys.
- `test/widget/features/onboarding/onboarding_lock_entry_test.dart` - Skip-path now asserts `setAppLockEnabled(false)`, legacy flag untouched.

## Decisions Made
- Kept `biometricLockEnabled` in the model (retired behaviorally, not deleted) to avoid breaking Phase 54's onboarding tests — the new lock simply never reads it.
- `repository_providers.g.dart` regenerated with a refreshed provider hash; committed alongside Task 1 to keep generated files non-stale (AUDIT-10).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The two persisted booleans are ready to feed the "lock effective" predicate (Plan 07) and the SecuritySection refactor (Plan 10).
- No blockers. schemaVersion confirmed still 22; no Drift change.

---
*Phase: 55-pin-phase*
*Completed: 2026-06-30*

## Self-Check: PASSED
- All modified files present on disk.
- All 3 task commits present in git history (ee27ec49, b1ff9f69, a5194f5d).
