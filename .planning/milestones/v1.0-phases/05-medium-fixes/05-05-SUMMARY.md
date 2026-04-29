---
phase: 05-medium-fixes
plan: "05"
subsystem: testing
tags: [architecture-tests, i18n, audit, coverage, flutter]

requires:
  - phase: 05-01
    provides: RD-001 hardcoded CJK cleanup foundation
  - phase: 05-03
    provides: settings and locale cleanup dependencies
  - phase: 05-04
    provides: analytics localization and money-display fixes
provides:
  - lib-only MOD-009 reference scanner
  - hardcoded CJK production UI scanner with exact data whitelist
  - MEDIUM audit closure gate for issues.json
  - RD-001 and RD-002 audit closure records
  - merchant database per-file coverage above 80 percent
affects: [06-low-fixes, 07-documentation-sweep, 08-re-audit, audit-closure]

tech-stack:
  added: []
  patterns:
    - dart:io recursive architecture scanners
    - ARB-backed UI labels for scanner cleanup
    - positional coverage_gate.dart invocation for per-file gates

key-files:
  created:
    - test/architecture/mod009_live_lib_scan_test.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart
    - test/architecture/medium_findings_closed_test.dart
    - test/unit/infrastructure/ml/merchant_database_test.dart
  modified:
    - lib/infrastructure/ml/merchant_database.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/settings/presentation/widgets/appearance_section.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - .planning/audit/issues.json

key-decisions:
  - "The CJK scanner strips full-line comments and RegExp literals so parser data can remain tested without allowing UI literals."
  - "Home ledger labels and settings language labels moved behind ARB getters rather than widening the CJK whitelist."
  - "RD-001 and RD-002 closure points to commit a66c625cd252705a4579c1728e992928370505d7, the scanner-enforcement code change."
  - "coverage_gate.dart was invoked with the existing positional file argument syntax because the planned --files flag is not supported by the repo script."

patterns-established:
  - "Architecture scanners should keep whitelist paths exact and avoid wildcarding presentation files."
  - "Production UI CJK cleanup should prefer l10n keys and generated S getters over test exceptions."

requirements-completed: [MED-01, MED-02, MED-03, MED-06, MED-08]

duration: 22min
completed: 2026-04-27
---

# Phase 05 Plan 05: Scanner Closure Summary

**Final Phase 5 scanner gates now block live MOD-009 references, hardcoded CJK UI literals, and open MEDIUM audit findings.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-04-27T04:54:53Z
- **Completed:** 2026-04-27T05:16:16Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added a lib-only MOD-009 scanner and removed the live merchant database MOD-009 comment without touching historical docs.
- Added a hardcoded CJK scanner with exact data-file whitelist and moved remaining user-visible home/settings strings behind ARB-backed getters.
- Added a MEDIUM audit closure test, closed RD-001 and RD-002 in `.planning/audit/issues.json`, and covered merchant lookup paths to keep the per-file coverage gate above threshold.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace live MOD-009 comment and add lib-only scanner**
   - `1c116fe` test: add failing MOD-009 lib scanner
   - `a69f60c` fix: remove live MOD-009 merchant comment
2. **Task 2: Add hardcoded CJK scanner and close MEDIUM audit findings**
   - `e640a25` test: add failing medium closure scanners
   - `a66c625` fix: enforce hardcoded CJK scanner
   - `8e3f0e0` chore: close medium audit findings
   - `b617fbc` test: cover merchant database lookup

**Plan metadata:** final docs commit created after state updates.

## Files Created/Modified

- `test/architecture/mod009_live_lib_scan_test.dart` - Recursively scans live `lib/**/*.dart` files for `MOD-009` and `mod009`.
- `lib/infrastructure/ml/merchant_database.dart` - Removes the live MOD-009 reference from the shared merchant lookup comment.
- `test/architecture/hardcoded_cjk_ui_scan_test.dart` - Scans production Dart string literals for hardcoded CJK outside the approved data whitelist.
- `test/architecture/medium_findings_closed_test.dart` - Parses `.planning/audit/issues.json` and fails on any open MEDIUM finding.
- `.planning/audit/issues.json` - Marks RD-001 and RD-002 closed in phase 5 with the scanner-enforcement commit hash.
- `test/unit/infrastructure/ml/merchant_database_test.dart` - Covers exact, alias, substring, empty, and unknown merchant lookup paths.
- `lib/features/home/presentation/screens/home_screen.dart` - Uses generated l10n getters for ledger tags, shadow-book title, and previous-month amount text.
- `lib/features/settings/presentation/widgets/appearance_section.dart` - Uses generated l10n getters for language labels.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` - Adds home ledger/shadow-book keys and preserves native language names.
- `lib/generated/app_localizations*.dart` - Regenerated after ARB changes.

## Decisions Made

- Kept historical documentation out of the MOD-009 scanner per D-14 and limited the scanner to live `lib/**/*.dart`.
- Did not broaden the CJK whitelist to presentation files; residual UI strings were localized instead.
- Used the existing positional `coverage_gate.dart` CLI syntax because `--files` exits with an unknown-flag error in this repo.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Scanner Bug] Avoided false positives on parser RegExp literals**
- **Found during:** Task 2
- **Issue:** The CJK scanner initially flagged intentional parser regex/data literals rather than user-visible UI text.
- **Fix:** Stripped `RegExp(...)` literals after full-line comments before scanning string literals.
- **Files modified:** `test/architecture/hardcoded_cjk_ui_scan_test.dart`
- **Verification:** `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart`
- **Committed in:** `a66c625`

**2. [Rule 2 - Missing Critical] Localized residual CJK UI strings**
- **Found during:** Task 2
- **Issue:** The new scanner exposed remaining hardcoded CJK in home and settings UI paths.
- **Fix:** Added ARB keys, regenerated l10n output, and updated widgets to use `S.of(context)` getters.
- **Files modified:** `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/settings/presentation/widgets/appearance_section.dart`, `lib/l10n/app_*.arb`, `lib/generated/app_localizations*.dart`
- **Verification:** CJK scanner, home widget tests, appearance widget tests, ARB parity test, and `flutter analyze`.
- **Committed in:** `a66c625`

**3. [Rule 3 - Blocking] Added merchant database coverage for per-file gate**
- **Found during:** Task 2
- **Issue:** `merchant_database.dart` coverage was 8 percent after scanner work, below the required 80 percent gate.
- **Fix:** Added focused unit tests for merchant lookup match and null paths.
- **Files modified:** `test/unit/infrastructure/ml/merchant_database_test.dart`
- **Verification:** Per-file gate reports `24/25 | 96.00 | PASS`.
- **Committed in:** `b617fbc`

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 1 Rule 2, 1 Rule 3)
**Impact on plan:** All auto-fixes were required to make the planned scanner and coverage gates meaningful. No architecture boundary changed.

## Issues Encountered

- The planned coverage command used `--files`, but `scripts/coverage_gate.dart` only accepts file paths positionally. The final verification used `dart run scripts/coverage_gate.dart lib/infrastructure/ml/merchant_database.dart --threshold 80 --lcov coverage/lcov_clean.info`.
- A mistyped exploratory home test path failed because the file did not exist; valid home, appearance, architecture, coverage, analyze, and full-suite commands passed.

## Known Stubs

- `lib/features/home/presentation/screens/home_screen.dart:148` - Pre-existing TODO to wire `GroupBar` to real group data when available.
- `lib/features/home/presentation/screens/home_screen.dart:177` - Pre-existing TODO to navigate to the full transaction list.
- `lib/l10n/app_en.arb:1367`, `lib/l10n/app_ja.arb:1367`, `lib/l10n/app_zh.arb:1367` - Pre-existing `datePickerComingSoon` UI copy for a future date picker.

## Threat Flags

None - this plan introduced source/audit scanners only and did not add network endpoints, auth paths, file-write surfaces, or schema trust boundaries.

## Verification

- `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart test/architecture/mod009_live_lib_scan_test.dart test/architecture/medium_findings_closed_test.dart` - passed, 3 tests.
- `flutter test --coverage` - passed, 1267 tests.
- `/Users/xinz/.pub-cache/bin/coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'` - passed.
- `dart run scripts/coverage_gate.dart lib/infrastructure/ml/merchant_database.dart --threshold 80 --lcov coverage/lcov_clean.info` - passed, 96.00 percent.
- `flutter analyze` - passed, no issues.
- `flutter test` - passed, 1267 tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 5 MEDIUM gates are closed. Phase 6 can rely on automated guards for live MOD-009 references, hardcoded CJK UI literals, and open MEDIUM audit findings.

## TDD Gate Compliance

- RED commits: `1c116fe`, `e640a25`
- GREEN/fix commits: `a69f60c`, `a66c625`, `8e3f0e0`, `b617fbc`
- Compliance: PASSED

## Self-Check: PASSED

- Confirmed summary and created scanner/test files exist.
- Confirmed task commits exist in git history: `1c116fe`, `a69f60c`, `e640a25`, `a66c625`, `8e3f0e0`, `b617fbc`.

---
*Phase: 05-medium-fixes*
*Completed: 2026-04-27*
