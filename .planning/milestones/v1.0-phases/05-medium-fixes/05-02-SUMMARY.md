---
phase: 05-medium-fixes
plan: "02"
subsystem: i18n
tags: [flutter, arb, l10n, architecture-test]

requires:
  - phase: 05-medium-fixes
    provides: Phase 5 context and UI localization key contract
provides:
  - ARB normal-key and metadata-key parity guard for en/ja/zh
  - Phase 5 home, voice, analytics, and budget localization keys
  - Current generated S localization getters and placeholder methods
affects: [phase-05-ui-localization, phase-05-analytics, i18n]

tech-stack:
  added: []
  patterns: [ARB parity architecture test, generated localization refresh]

key-files:
  created:
    - test/architecture/arb_key_parity_test.dart
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart

key-decisions:
  - "Preserved OCR keys as explicit Future OCR/MOD-005 stubs instead of deleting unused-looking placeholders."
  - "Copied ARB metadata shape across locales so normal keys and @metadata keys are both parity-checked."

patterns-established:
  - "ARB parity test parses all locale files with dart:convert and compares sorted normal and metadata key sets."
  - "Placeholder metadata is kept identical across locales before regenerating lib/generated localization output."

requirements-completed: [MED-03, MED-04, MED-05, MED-08]

duration: 10min
completed: 2026-04-27
---

# Phase 05 Plan 02: ARB Audit, Parity, and Key Normalization Summary

**ARB parity guard with preserved OCR/MOD-005 stubs and generated Phase 5 localization getters**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-27T03:08:13Z
- **Completed:** 2026-04-27T03:18:53Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `test/architecture/arb_key_parity_test.dart` to enforce identical normal and metadata key sets across English, Japanese, and Chinese ARBs.
- Preserved `ocrScan`, `ocrScanTitle`, and `ocrHint` in all locales with explicit `Future OCR/MOD-005 stub` metadata.
- Added Phase 5 home, voice, analytics, and budget keys across all locales and regenerated `S` localization output.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add green ARB parity and OCR placeholder guard** - `daa2ac4` (test)
2. **Task 2: Normalize Phase 5 ARB keys and regenerate localization output** - `dcedbcd` (feat)

**Plan metadata:** final docs commit

## Files Created/Modified

- `test/architecture/arb_key_parity_test.dart` - Architecture test for normal-key parity, metadata-key parity, and OCR stub preservation.
- `lib/l10n/app_en.arb` - Template locale metadata parity plus Phase 5 keys.
- `lib/l10n/app_ja.arb` - Japanese locale metadata parity plus Phase 5 keys.
- `lib/l10n/app_zh.arb` - Chinese locale metadata parity plus Phase 5 keys.
- `lib/generated/app_localizations.dart` - Regenerated abstract localization API.
- `lib/generated/app_localizations_en.dart` - Regenerated English localization implementation.
- `lib/generated/app_localizations_ja.dart` - Regenerated Japanese localization implementation.
- `lib/generated/app_localizations_zh.dart` - Regenerated Chinese localization implementation.

## Decisions Made

- Preserved OCR placeholder keys as intentional future MOD-005 stubs with metadata instead of treating them as dead ARB keys.
- Kept all generated localization edits sourced from `flutter gen-l10n`; no generated Dart file was hand-edited.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored locale-specific `@@locale` values after metadata normalization**
- **Found during:** Task 1 (Add green ARB parity and OCR placeholder guard)
- **Issue:** Mechanical metadata normalization initially copied English `@@locale` into Japanese and Chinese ARBs, causing `flutter gen-l10n` to fail because filenames no longer matched locale tags.
- **Fix:** Restored `@@locale` values to `en`, `ja`, and `zh` respectively, then reran `flutter gen-l10n`.
- **Files modified:** `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`
- **Verification:** `flutter gen-l10n` exited 0; `flutter test test/architecture/arb_key_parity_test.dart` exited 0.
- **Committed in:** `daa2ac4`

---

**Total deviations:** 1 auto-fixed (Rule 1: 1)
**Impact on plan:** No scope expansion. The fix was required for valid ARB generation.

## Issues Encountered

- `dart format .` formatted many unrelated files because the wider repository contains pre-existing formatting drift. Those unrelated formatting changes were reverted; only 05-02-owned files were committed.
- `flutter analyze` is blocked by out-of-scope files already present on the branch:
  - `test/unit/infrastructure/category/category_locale_service_test.dart` imports missing `package:home_pocket/infrastructure/category/category_locale_service.dart`, which appears to be from the existing 05-01 RED commit (`61fa14e`) before its implementation landed.
  - `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` has two `no_leading_underscores_for_local_identifiers` infos.

## Known Stubs

- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` - `ocrScan`, `ocrScanTitle`, and `ocrHint` are intentional future OCR/MOD-005 stubs preserved per MED-05.

## Verification

- `flutter gen-l10n` - PASS
- `dart format .` - PASS; unrelated formatting churn reverted afterward
- `flutter test test/architecture/arb_key_parity_test.dart` - PASS (`+2`)
- `rg -n "normalKeys|metadataKeys|Future OCR/MOD-005 stub|ocrScanTitle" test/architecture/arb_key_parity_test.dart` - PASS
- `rg -n '"homeLedgersSection"|"analyticsTransactionCount"|"budgetExceededAmount"|"Future OCR/MOD-005 stub"' lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb` - PASS
- `rg -n "homeLedgersSection|analyticsTransactionCount|budgetExceededAmount|voiceMicrophonePermissionRequired" lib/generated/app_localizations.dart lib/generated/app_localizations_en.dart lib/generated/app_localizations_ja.dart lib/generated/app_localizations_zh.dart` - PASS
- `flutter analyze` - FAIL, blocked by out-of-scope files listed in Issues Encountered

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 5 UI plans can now consume stable generated getters for the home, voice, analytics, and budget strings added here. Full repo analysis should be rerun after the 05-01 category locale implementation lands.

## Self-Check: PASSED

- Created file exists: `test/architecture/arb_key_parity_test.dart`
- Summary exists: `.planning/phases/05-medium-fixes/05-02-SUMMARY.md`
- Task commits exist: `daa2ac4`, `dcedbcd`
- No tracked files were deleted by task commits.

---
*Phase: 05-medium-fixes*
*Completed: 2026-04-27*
