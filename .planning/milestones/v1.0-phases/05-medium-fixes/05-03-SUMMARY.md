---
phase: 05-medium-fixes
plan: 03
subsystem: ui-i18n
tags: [flutter, i18n, widget-tests, coverage]

requires:
  - phase: 05-02
    provides: Generated localization getters for home and accounting copy
provides:
  - Localized home screen section, ledger, transaction header, and empty-state copy
  - Localized SoulFullnessCard metrics with FormatterService JPY formatting
  - Localized voice microphone permission toast with behavior coverage
affects: [home, accounting, i18n, coverage-gate]

tech-stack:
  added: []
  patterns:
    - "Use generated S.of(context) getters for home/accounting UI copy"
    - "Use FormatterService plus AppTextStyles.amountMedium for touched money display"

key-files:
  created:
    - .planning/phases/05-medium-fixes/05-03-SUMMARY.md
  modified:
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/widgets/soul_fullness_card.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - test/widget/features/home/presentation/screens/home_screen_test.dart
    - test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart
    - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
    - test/features/home/presentation/screens/home_screen_test.dart
    - test/features/home/presentation/widgets/soul_fullness_card_test.dart
    - .planning/phases/05-medium-fixes/deferred-items.md

key-decisions:
  - "Preserved existing layout, overlay, and navigation behavior while routing copy through generated localization getters."
  - "Used the repository-supported coverage gate positional CLI because the plan's --files form is not accepted by scripts/coverage_gate.dart."

patterns-established:
  - "Localized widget tests should assert generated S values instead of repeating literal UI strings."
  - "VoiceInputScreen behavior tests can inject StartSpeechRecognitionUseCase and provider overrides for deterministic permission and recognition paths."

requirements-completed: [MED-03, MED-07, MED-08]

duration: 18m40s
completed: 2026-04-27
---

# Phase 05 Plan 03: Home Accounting Localization Summary

**Home and voice accounting copy now renders through generated localization getters, with touched money display covered by FormatterService and tabular-figure tests.**

## Performance

- **Duration:** 18m40s
- **Started:** 2026-04-27T04:02:38Z
- **Completed:** 2026-04-27T04:21:18Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Replaced hardcoded home screen and soul-card UI copy with generated `S.of(context)` getters.
- Switched the touched soul recent amount to `FormatterService.formatCurrency(..., 'JPY', locale)` and `AppTextStyles.amountMedium`.
- Localized the voice microphone permission toast without changing overlay positioning, icon, dismiss behavior, or recording state flow.
- Expanded widget tests for Japanese and English localized labels, tabular money figures, permission toasts, and voice recognition interaction paths.

## Task Commits

1. **Task 1 RED: Home localization tests** - `f4929c0` (test)
2. **Task 1 GREEN: Home and soul card localization** - `77bd892` (feat)
3. **Task 2 RED: Voice permission localization tests** - `43feac7` (test)
4. **Deviation fix: Duplicate home tests** - `afbc431` (test)
5. **Analyzer cleanup: Soul card test import** - `f8a7514` (fix)
6. **Task 2 GREEN: Voice permission localization** - `10ba7e9` (feat)

_Plan metadata commit is created separately after state updates._

## Files Created/Modified

- `lib/features/home/presentation/screens/home_screen.dart` - Uses generated localization getters for section dividers, ledger titles, recent-transaction header, view-all action, and empty state.
- `lib/features/home/presentation/widgets/soul_fullness_card.dart` - Uses generated localization getters, locale-aware JPY formatting, and amount text styling.
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` - Uses `voiceMicrophonePermissionRequired` for the permission toast.
- `test/widget/features/home/presentation/screens/home_screen_test.dart` - Covers Japanese and English generated labels.
- `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` - Covers localized soul labels and tabular amount styling.
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` - Covers localized permission toasts and voice recognition interaction paths.
- `test/features/home/presentation/screens/home_screen_test.dart` - Updated duplicate home tests to use generated localization values.
- `test/features/home/presentation/widgets/soul_fullness_card_test.dart` - Updated duplicate soul-card tests to use generated localization values.
- `.planning/phases/05-medium-fixes/deferred-items.md` - Records unrelated analyzer findings that remain outside 05-03 ownership.

## Decisions Made

- Kept production behavior changes to the planned copy/formatting surfaces only.
- Used provider and speech-service test doubles for voice tests instead of changing production visibility or adding test hooks.
- Ran the coverage gate with positional file arguments because the repository script rejects the plan's stale `--files` flag.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated duplicate home/soul tests after localization**
- **Found during:** Task 2 verification
- **Issue:** Full coverage surfaced failures in duplicate older tests under `test/features/home/...` that still expected literal copy after production code was correctly localized.
- **Fix:** Updated those duplicate tests to pump localized widgets and assert generated `S` values.
- **Files modified:** `test/features/home/presentation/screens/home_screen_test.dart`, `test/features/home/presentation/widgets/soul_fullness_card_test.dart`
- **Verification:** Targeted duplicate home tests passed, then `flutter test --coverage` passed.
- **Committed in:** `afbc431`

**2. [Rule 3 - Blocking] Used supported coverage gate CLI**
- **Found during:** Task 2 verification
- **Issue:** `scripts/coverage_gate.dart` rejects the plan's `--files` flag with `unknown flag: --files`.
- **Fix:** Re-ran the same gate with supported positional file arguments.
- **Files modified:** None
- **Verification:** Coverage gate passed for all three touched production files.
- **Committed in:** N/A

**3. [Rule 1 - Analyzer] Removed redundant touched-test import**
- **Found during:** Task 2 verification
- **Issue:** `flutter analyze` reported an unnecessary `dart:ui` import in the touched soul-card widget test.
- **Fix:** Removed the redundant import.
- **Files modified:** `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart`
- **Verification:** The touched-file analyzer finding disappeared on rerun.
- **Committed in:** `f8a7514`

---

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3)
**Impact on plan:** No scope creep in production code; test updates and CLI adjustment were required to complete verification against the current repository.

## Issues Encountered

- `dart format .` reformatted unrelated files during Task 1 verification. Those unrelated formatter changes were reverted, and subsequent formatting was scoped to touched files.
- `flutter analyze` still exits non-zero because of two unrelated pre-existing `no_leading_underscores_for_local_identifiers` info findings in `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` at lines 57 and 73. This is recorded in `deferred-items.md` and was not changed because it is outside plan 05-03 ownership.

## Verification

- `flutter test test/widget/features/home/presentation/screens/home_screen_test.dart test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` - passed.
- `flutter test test/features/home/presentation/widgets/soul_fullness_card_test.dart test/features/home/presentation/screens/home_screen_test.dart` - passed.
- `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` - passed.
- `flutter test --coverage` - passed, 1254 tests.
- `/Users/xinz/.pub-cache/bin/coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'` - passed.
- `dart run scripts/coverage_gate.dart lib/features/home/presentation/screens/home_screen.dart lib/features/home/presentation/widgets/soul_fullness_card.dart lib/features/accounting/presentation/screens/voice_input_screen.dart --threshold 80 --lcov coverage/lcov_clean.info` - passed: home 87.42%, soul card 100.00%, voice input 84.04%.
- `flutter analyze` - failed only on unrelated deferred `shadow_books_provider_characterization_test.dart` info findings.
- Hardcoded home/voice copy scans - passed; no planned literal production matches remain.
- Localized getter and formatting scans - passed.

## Known Stubs

No new stubs were introduced. Existing unrelated TODO comments in `home_screen.dart` were not created or changed by this plan.

## Threat Flags

None - no new network endpoints, auth paths, file access patterns, schema changes, or trust-boundary surfaces were introduced.

## TDD Gate Compliance

- RED gate commits exist: `f4929c0`, `43feac7`.
- GREEN gate commits exist after RED: `77bd892`, `10ba7e9`.
- Additional fix commits were made only after verification surfaced duplicate-test and analyzer cleanup issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Home/accounting localization hotspots from this plan are ready for downstream UI/i18n work. The only remaining verification concern is the unrelated analyzer debt already tracked in the phase deferred list.

## Self-Check: PASSED

- Summary file exists: `.planning/phases/05-medium-fixes/05-03-SUMMARY.md`.
- Task and fix commits found in history: `f4929c0`, `77bd892`, `43feac7`, `afbc431`, `f8a7514`, `10ba7e9`.
- Stub scan found no new blocking stubs. Existing TODOs in `home_screen.dart` were pre-existing and unchanged.

---
*Phase: 05-medium-fixes*
*Completed: 2026-04-27*
