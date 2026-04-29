---
plan: 03-02
phase: 03-critical-fixes
status: completed
wave: 2
completed_at: 2026-04-26
---

# Plan 03-02 Summary: AppInitializer + Database Provider Fix

## CRIT-03 Closure

`appDatabaseProvider` no longer throws `UnimplementedError`. It now throws a
diagnostic `StateError` with a message pointing to `AppInitializer` and
`createTestProviderScope`. Production always overrides via
`AppInitializer.initialize()`. Tests use `createTestProviderScope` from
`test/helpers/test_provider_scope.dart`.

## What Was Delivered

### Task 1 — ARB keys + gen-l10n
- Added 3 keys × 3 locales: `initFailedTitle`, `initFailedMessage`, `initFailedRetry`
- `flutter gen-l10n` regenerated all 4 generated files
- Commit: `d675403`

### Task 2 — InitResult Freezed sealed class
- `lib/core/initialization/init_result.dart` — `@freezed sealed class` with
  `InitSuccess(container)` and `InitFailure(type, error, stackTrace?)`
- `enum InitFailureType { masterKey, database, seed, unknown }`
- 8 unit tests (equality, pattern matching, 4 variants) — all GREEN
- Commit: `f537d72`

### Task 3 — AppInitializer
- `lib/core/initialization/app_initializer.dart` — constructor-injected with
  `ProviderContainerFactory`, `AppDatabaseFactory`, `SeedRunner` typedefs
- Preserves boot sequence verbatim: masterKey → keyManager → database → seed
- 14 unit tests (7 happy path + 3 masterKey failures + 2 database failures +
  2 seed failures) — all GREEN, no flutter_secure_storage
- Coverage: 96.7% (29/30 lines)
- Commit: `06adfae`

### Task 4 — appDatabaseProvider fix + createTestProviderScope
- `lib/infrastructure/security/providers.dart`: `@Riverpod(keepAlive: true)` +
  `StateError` diagnostic (removes `UnimplementedError`)
- `test/helpers/test_provider_scope.dart`: `createTestProviderScope()` helper
- 7 unit tests for the provider and helper — all GREEN
- Coverage: 100% on providers.dart
- Commits: `509e063`

### Task 5 — InitFailureScreen + 9 widget tests
- `lib/core/initialization/init_failure_screen.dart`: `StatefulWidget`, localized
  via `S.of(context)`, retry button with loading state
- `InitFailureApp` wrapper for standalone use in `main.dart`
- 9 widget tests (3 locales, retry callback, loading state, disabled state,
  icon, background color, re-enable after retry) — all GREEN
- Coverage: 87.5% (28/32 lines)
- Commit: `610a189`

### Task 6 — main.dart delegation
- `lib/main.dart`: `main()` → `_boot()` → `AppInitializer.initialize()` → sealed
  switch on `InitResult`; failure path renders `InitFailureApp(onRetry: _boot)`
- `HomePocketApp` and `_HomePocketAppState` unchanged (behavior preserved)
- Commit: `0326dce`

### Task 7 — Exit gate
- `flutter analyze --no-fatal-infos`: 0 errors, 0 warnings ✅
- `dart run custom_lint`: 19 pre-existing INFO issues (scoped_providers) ✅
- `flutter test`: 1070/1070 passed ✅
- Coverage for touched files:
  - `app_initializer.dart`: 96.7% ✅
  - `init_failure_screen.dart`: 87.5% ✅
  - `providers.dart`: 100% ✅
  - `init_result.dart`: covered via Freezed (no standalone DA lines) ✅
  - `main.dart`: 63.9% (untestable `_boot()` function; CRIT-05 was specific to
    `app_initializer.dart`)

## Open Question Resolution

UI-SPEC flagged brand-color divergence (`#8AB8DA` vs `colorScheme.primary` =
`#E85A4F`). Per plan default: shipping `#8AB8DA` + `AppColors.textPrimary`
(WCAG AAA contrast, locked in UI-SPEC). Deferred to Phase 7 documentation sweep.

## Requirements Closed

- **CRIT-03**: `appDatabaseProvider` no longer throws `UnimplementedError` ✅
- **CRIT-05**: `app_initializer.dart` ≥80% coverage (96.7%) ✅
- **CRIT-06**: `flutter analyze`, `dart run custom_lint`, `flutter test` all GREEN ✅

## New Files

- `lib/core/initialization/init_result.dart` + `.freezed.dart`
- `lib/core/initialization/app_initializer.dart`
- `lib/core/initialization/init_failure_screen.dart`
- `test/core/initialization/init_result_test.dart`
- `test/core/initialization/app_initializer_test.dart`
- `test/core/initialization/init_failure_screen_test.dart`
- `test/helpers/test_provider_scope.dart`
- `test/infrastructure/security/providers_test.dart`

## Modified Files

- `lib/infrastructure/security/providers.dart` (StateError, keepAlive: true)
- `lib/infrastructure/security/providers.g.dart` (regenerated)
- `lib/main.dart` (delegation to AppInitializer)
- `lib/l10n/app_en.arb`, `app_ja.arb`, `app_zh.arb` (3 new keys each)
- `lib/generated/app_localizations*.dart` (regenerated)
