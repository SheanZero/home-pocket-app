---
phase: 54-onboarding-flow
plan: 01
subsystem: settings
tags: [shared-preferences, freezed, riverpod, onboarding, i18n, locale]

requires:
  - phase: 51-voice-entry
    provides: voiceLocaleIdFromLanguageCode (zh/ja/en mapping) reused as the canonical voice-locale contract
provides:
  - "AppSettings.onboardingComplete (bool, @Default(false)) — single source of truth for the onboarding gate (D-04)"
  - "SettingsRepository.setOnboardingComplete(bool) + impl _onboardingCompleteKey ('onboarding_complete') plaintext SharedPreferences key"
  - "preselectOnboardingLanguage(deviceLanguage) — device preselect with ja fallback (D-07)"
  - "resolveVoiceLanguageForOnboarding(...) — concrete zh/ja/en voice-default resolver, never 'system' (D-09/ONBOARD-05)"
affects: [54-04-clear-import, 54-05-onboarding-settings, 54-07-onboarding-gate]

tech-stack:
  added: []
  patterns:
    - "Persisted boolean flag mirrors biometricLockEnabled end-to-end (model field + interface setter + impl key in getSettings/updateSettings/dedicated setter)"
    - "Pure deterministic locale helpers take deviceLanguage as a parameter (no PlatformDispatcher in the testable core)"

key-files:
  created:
    - lib/features/onboarding/presentation/utils/onboarding_locale_resolution.dart
    - test/unit/features/settings/voice_default_resolution_test.dart
  modified:
    - lib/features/settings/domain/models/app_settings.dart
    - lib/features/settings/domain/repositories/settings_repository.dart
    - lib/data/repositories/settings_repository_impl.dart
    - test/unit/data/repositories/settings_repository_impl_test.dart

key-decisions:
  - "onboardingComplete persists as a plaintext SharedPreferences key — NO Drift migration, schemaVersion stays 22 (D-04 research-resolved)"
  - "Voice-default resolver constrains output to {ja,zh,en}; 'system' can never leak into voiceLanguage (D-09/Pitfall 4, T-54-02 mitigation)"

patterns-established:
  - "End-to-end persisted-flag template: @Default field on AppSettings + interface setter + _xxxKey touch-points (declaration/getSettings/updateSettings/setter)"
  - "Onboarding locale resolution lives in a pure, widget-free util consumed later by the settings page (54-05)"

requirements-completed: [ONBOARD-01, ONBOARD-05]

coverage:
  - id: D1
    description: "onboardingComplete defaults to false on empty prefs, round-trips both directions via setOnboardingComplete, and persists through updateSettings"
    requirement: "ONBOARD-01"
    verification:
      - kind: unit
        ref: "test/unit/data/repositories/settings_repository_impl_test.dart#onboardingComplete (4 cases)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No Drift migration introduced — schemaVersion stays 22"
    verification:
      - kind: other
        ref: "grep -n 'schemaVersion =>' lib/data/app_database.dart => '=> 22'"
        status: pass
    human_judgment: false
  - id: D3
    description: "preselectOnboardingLanguage returns device language for ja/zh/en, else ja (D-07)"
    verification:
      - kind: unit
        ref: "test/unit/features/settings/voice_default_resolution_test.dart#preselectOnboardingLanguage"
        status: pass
    human_judgment: false
  - id: D4
    description: "resolveVoiceLanguageForOnboarding returns a concrete zh/ja/en code and never 'system' (D-09/ONBOARD-05)"
    requirement: "ONBOARD-05"
    verification:
      - kind: unit
        ref: "test/unit/features/settings/voice_default_resolution_test.dart#resolveVoiceLanguageForOnboarding"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-06-29
status: complete
---

# Phase 54 Plan 01: Onboarding Non-UI Foundation Summary

**Persisted `onboardingComplete` SharedPreferences flag (no Drift migration) plus pure device-preselect and voice-default locale helpers that guarantee a concrete zh/ja/en code and never 'system'.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 2
- **Files modified:** 6 (2 created, 4 modified) + 2 generated

## Accomplishments
- `AppSettings.onboardingComplete` (default false) wired end-to-end through the SettingsRepository interface and SharedPreferences impl, mirroring `biometricLockEnabled` exactly — single source of truth for the onboarding gate (D-04).
- Confirmed zero Drift impact: the flag is a plaintext `onboarding_complete` prefs key; `schemaVersion` stays 22, no `onUpgrade` edit.
- New pure `onboarding_locale_resolution.dart`: `preselectOnboardingLanguage` (ja fallback, D-07) and `resolveVoiceLanguageForOnboarding` (concrete code, never 'system', D-09/Pitfall 4).
- Unit-tested in isolation: 4 new repo cases + 6 resolver cases, including an explicit "never 'system'" assertion.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add persisted onboardingComplete flag end-to-end** - `2ca1fad3` (feat)
2. **Task 2: Pure device-preselect + voice-default resolution helpers** - `66d09ba4` (feat)

_Note: tasks were TDD-scoped; model+test landed together per task since the freezed-generated field is required for the test to compile._

## Files Created/Modified
- `lib/features/settings/domain/models/app_settings.dart` - added `@Default(false) bool onboardingComplete`
- `lib/features/settings/domain/repositories/settings_repository.dart` - added `setOnboardingComplete(bool)` interface method
- `lib/data/repositories/settings_repository_impl.dart` - `_onboardingCompleteKey`, read in getSettings, persist in updateSettings, dedicated setter
- `lib/features/onboarding/presentation/utils/onboarding_locale_resolution.dart` - new pure preselect + voice-default helpers
- `test/unit/data/repositories/settings_repository_impl_test.dart` - 4 onboardingComplete cases
- `test/unit/features/settings/voice_default_resolution_test.dart` - new resolver test (6 cases)
- `app_settings.freezed.dart` / `app_settings.g.dart` - regenerated (force-added; gitignored-yet-tracked)

## Decisions Made
- onboardingComplete is plaintext SharedPreferences, NOT Drift (D-04 research-resolved) — accepts T-54-01 tampering risk (low; no financial data gated by this flag, real lock is Phase 55).
- Resolver returns from a fixed {ja,zh,en} set so 'system' can never be persisted into voiceLanguage (T-54-02 mitigation).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Analyzer flagged a `dangling_library_doc_comments` info on the new util's file header. Converted the file-level `///` block to `//` comments — `flutter analyze` clean (0 issues). Resolved before the Task 2 commit.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Primitives ready for downstream plans: 54-04 (clear/import semantics consume the flag default), 54-05 (settings page feeds the resolver into `setVoiceLanguage`), 54-07 (gate reads `onboardingComplete`).
- No blockers.

## Self-Check: PASSED

---
*Phase: 54-onboarding-flow*
*Completed: 2026-06-29*
