---
phase: 54-onboarding-flow
plan: 04
subsystem: settings
tags: [onboarding, backup-import, clear-data, identity-wipe, riverpod]

requires:
  - phase: 54-onboarding-flow
    provides: "AppSettings.onboardingComplete (bool, @Default(false)) from 54-01 — the flag both reset paths drive"
provides:
  - "ImportBackupUseCase forces onboardingComplete=true on restore (D-06) — old/pre-Phase-54 backups skip onboarding"
  - "ClearAllDataUseCase resets settings to const AppSettings() (flag→false) AND deletes the UserProfile (D-05) — wipe = fresh install"
  - "clearAllDataUseCase provider now wired to userProfileRepositoryProvider (profile feature, prefix alias)"
affects: [54-07-onboarding-gate]

tech-stack:
  added: []
  patterns:
    - "Restore transform: AppSettings.fromJson(map).copyWith(onboardingComplete: true) — flag rides inside the existing settings map, no BackupData field added"
    - "Identity wipe: find() → null-guarded delete(profile.id) using the pre-existing UserProfileRepository.delete contract (no new repo method)"
    - "Cross-feature provider wiring via prefix-aliased import (mirrors family_sync `as profile`)"

key-files:
  created: []
  modified:
    - lib/application/settings/import_backup_use_case.dart
    - lib/application/settings/clear_all_data_use_case.dart
    - lib/features/settings/presentation/providers/repository_providers.dart
    - test/unit/application/settings/import_backup_use_case_test.dart
    - test/unit/application/settings/clear_all_data_use_case_test.dart

key-decisions:
  - "D-06: import always forces onboardingComplete=true (even when the backup explicitly carries false) — a restored backup represents an existing user"
  - "D-05: delete-all deletes the UserProfile in addition to the existing book-rebuild + dataResetSignal behavior (260627-v0w) — identity-wipe is ADDED, not a replacement"
  - "No BackupData field added; idempotency stays driven by the explicit flag, never inferred from currency or profile presence (ONBOARD-01)"

patterns-established:
  - "Backup-restore flag-override template: copyWith on the deserialized settings before updateSettings"

requirements-completed: [ONBOARD-01]

coverage:
  - id: D-06a
    description: "Import of a pre-Phase-54 backup whose settings map omits onboarding_complete → persisted onboardingComplete == true"
    requirement: "ONBOARD-01"
    verification:
      - kind: unit
        ref: "test/unit/application/settings/import_backup_use_case_test.dart#D-06: old backup lacking onboarding_complete"
        status: pass
    human_judgment: false
  - id: D-06b
    description: "Import of a backup with onboarding_complete=false → still forced true"
    requirement: "ONBOARD-01"
    verification:
      - kind: unit
        ref: "test/unit/application/settings/import_backup_use_case_test.dart#D-06: backup with onboarding_complete=false"
        status: pass
    human_judgment: false
  - id: D-05a
    description: "Clear-all resets settings to defaults → onboardingComplete == false"
    requirement: "ONBOARD-01"
    verification:
      - kind: unit
        ref: "test/unit/application/settings/clear_all_data_use_case_test.dart#D-05: resets settings to defaults"
        status: pass
    human_judgment: false
  - id: D-05b
    description: "Clear-all deletes the UserProfile with the right id when one exists; no-op when absent"
    requirement: "ONBOARD-01"
    verification:
      - kind: unit
        ref: "test/unit/application/settings/clear_all_data_use_case_test.dart#D-05: deletes/no delete cases"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-06-29
status: complete
---

# Phase 54 Plan 04: Clear / Import Reset Semantics Summary

**Both destructive data paths now keep the onboarding flag correct: import forces `onboardingComplete=true` (old backups skip onboarding), and delete-all resets it to `false` while wiping the UserProfile so identity does not survive a fresh-install reset.**

## Performance

- **Duration:** ~11 min
- **Tasks:** 2 (both TDD)
- **Files modified:** 5 (3 source, 2 test)

## Accomplishments
- **D-06 (import = skip onboarding):** `ImportBackupUseCase._restoreData` now does `AppSettings.fromJson(backupData.settings).copyWith(onboardingComplete: true)` before `updateSettings`. Pre-Phase-54 backups whose settings map omits the key, and backups carrying an explicit `false`, both land as `true`. No `BackupData` field added — the flag rides inside the existing settings map.
- **D-05 (delete-all = fresh install):** `ClearAllDataUseCase` gained a `UserProfileRepository` dependency; after the existing `const AppSettings()` reset (flag→false) it calls `find()` and null-guards `delete(profile.id)`. The pre-existing book-rebuild + `dataResetSignal` behavior from 260627-v0w is preserved — identity-wipe is additive.
- Provider wired: `clearAllDataUseCase` now passes `userProfileRepo: ref.watch(profile.userProfileRepositoryProvider)` via a prefix-aliased import (mirrors `family_sync`).

## Task Commits

1. **Task 1: Import forces onboardingComplete=true (D-06)** — `3cb2d6b4` (feat)
2. **Task 2: Clear-all wipes identity + resets flag (D-05)** — `69469903` (feat)

## Files Created/Modified
- `lib/application/settings/import_backup_use_case.dart` — copyWith(onboardingComplete: true) on restore
- `lib/application/settings/clear_all_data_use_case.dart` — inject UserProfileRepository, delete profile after settings reset
- `lib/features/settings/presentation/providers/repository_providers.dart` — prefix-aliased profile import + provider wiring
- `test/unit/application/settings/import_backup_use_case_test.dart` — 2 D-06 cases
- `test/unit/application/settings/clear_all_data_use_case_test.dart` — MockUserProfileRepository + 3 D-05 cases

## Decisions Made
- Import forces the flag true unconditionally (existing-user semantics), never inferred from data presence (ONBOARD-01).
- Used the existing `UserProfileRepository.delete(String id)` contract — no new repo method.
- No build_runner regen needed: the provider edit changed only an existing provider body (no new/renamed `@riverpod` declaration), so `repository_providers.g.dart` is unchanged.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Verification
- `flutter analyze` → No issues found (0).
- `flutter test` on both use-case test files → 13/13 passing (includes pre-existing cases).
- Acceptance greps: `copyWith(onboardingComplete: true)` ×1; `userProfileRepo`/`_userProfileRepo` ×5; `delete(` ×1; `userProfileRepositoryProvider` ×1 in settings providers; `backup_data.dart` NOT in the diff.

## Threat Mitigation
- **T-54-05 (identity persists after delete-all):** mitigated — `ClearAllDataUseCase` now deletes the `UserProfile`; re-onboarding starts identity-blank.
- **T-54-06 (malicious backup sets onboarding state):** accepted per plan — settings are device-local config; forcing `onboardingComplete=true` on import is the intended behavior.

## Next Phase Readiness
- 54-07 (onboarding gate) reads `onboardingComplete`; both reset paths now keep it correct end-to-end. No blockers.

## Self-Check: PASSED

---
*Phase: 54-onboarding-flow*
*Completed: 2026-06-29*
