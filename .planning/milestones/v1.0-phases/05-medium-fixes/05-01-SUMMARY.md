---
phase: 05-medium-fixes
plan: 01
subsystem: architecture
tags: [flutter, dart, category-localization, architecture-test, coverage]

requires:
  - phase: 04-high-fixes
    provides: Provider graph hygiene tests and architecture-test conventions
provides:
  - Infrastructure category localization helper renamed to CategoryLocaleService
  - Application category localization facade wired to the renamed infrastructure helper
  - Unit coverage for category locale resolution, fallback, and passthrough behavior
  - Architecture guard preventing cross-layer duplicate *Service class names
affects: [phase-05-medium-fixes, category-localization, architecture-tests]

tech-stack:
  added: []
  patterns:
    - dart:io production-source scanner in test/architecture
    - static helper facade remains application-facing for category display

key-files:
  created:
    - test/architecture/service_name_collision_test.dart
  modified:
    - lib/infrastructure/category/category_locale_service.dart
    - lib/application/accounting/category_localization_service.dart
    - test/unit/infrastructure/category/category_locale_service_test.dart

key-decisions:
  - "Renamed only the infrastructure category localization helper; application CategoryService remains the accounting business service."
  - "Used an empty allow list for cross-layer *Service name collisions so future duplicates fail by default."

patterns-established:
  - "Architecture scanner: collect production class declarations by layer and fail on duplicate service names across layers."

requirements-completed: [MED-02]

duration: 14min
completed: 2026-04-27
---

# Phase 05 Plan 01: Category Locale Service Rename Summary

**Category locale helper renamed with behavior coverage and a layer-wide service-name collision guard**

## Performance

- **Duration:** 14 min
- **Started:** 2026-04-27T03:42:29Z
- **Completed:** 2026-04-27T03:56:30Z
- **Tasks:** 2 completed, plus existing RED commit preserved
- **Files modified:** 5

## Accomplishments

- Renamed `lib/infrastructure/category/category_service.dart` to `category_locale_service.dart` and changed the class to `CategoryLocaleService`.
- Rewired `CategoryLocalizationService` to import and delegate to `infra.CategoryLocaleService`.
- Expanded locale-map regression tests for ja/zh/en, unsupported locale fallback, ID resolution, and unknown passthrough.
- Added `service_name_collision_test.dart` to prevent future duplicate `*Service` class names across production layers.

## Task Commits

1. **RED: failing test for helper rename** - `61fa14e` (test, existing previous executor commit)
2. **Task 1 GREEN: Rename infrastructure helper to CategoryLocaleService** - `a93ab74` (feat)
3. **Task 2: Add category locale and service collision regression tests** - `6a0c9ff` (test)

## Files Created/Modified

- `lib/infrastructure/category/category_locale_service.dart` - Renamed static category locale helper with `CategoryLocaleService`.
- `lib/application/accounting/category_localization_service.dart` - Application facade now imports `category_locale_service.dart` and delegates to `CategoryLocaleService`.
- `test/unit/infrastructure/category/category_locale_service_test.dart` - Covers static map lookup, fallback, and passthrough behavior.
- `test/architecture/service_name_collision_test.dart` - Scans production Dart files and rejects duplicate `*Service` names across layers.
- `.planning/phases/05-medium-fixes/deferred-items.md` - Records unrelated analyzer findings that are outside 05-01 ownership.

## Decisions Made

- Kept `lib/application/accounting/category_service.dart` unchanged so `CategoryService` continues to mean accounting business logic.
- Kept the service collision allow list empty, matching the plan’s strict default.
- Used the current `coverage_gate.dart` positional file syntax because this repo version does not support the plan’s `--files` flag.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used installed coverde path**
- **Found during:** Task 2
- **Issue:** `coverde` was installed at `/Users/xinz/.pub-cache/bin/coverde` but not available on `PATH`.
- **Fix:** Ran the installed executable directly.
- **Files modified:** None.
- **Verification:** `/Users/xinz/.pub-cache/bin/coverde filter ...` exited 0 and produced `coverage/lcov_clean.info`.
- **Committed in:** N/A, verification environment only.

**2. [Rule 3 - Blocking] Adjusted coverage gate invocation to current CLI**
- **Found during:** Task 2
- **Issue:** `dart run scripts/coverage_gate.dart --files ...` exited 2 because the script accepts files positionally, not via `--files`.
- **Fix:** Ran the equivalent supported command with the same files as positionals.
- **Files modified:** None.
- **Verification:** Coverage gate reported both touched production files at 100% and exited 0.
- **Committed in:** N/A, verification command only.

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** Verification completed with equivalent commands; no product scope changed.

## Issues Encountered

- `dart format .` initially formatted unrelated pre-existing files. Those unrelated path changes were explicitly restored before commits; only plan-owned files were committed.
- `flutter analyze` exits 1 because of two pre-existing info-level findings in `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` (`no_leading_underscores_for_local_identifiers` at lines 57 and 73). This is outside 05-01 ownership and is recorded in `deferred-items.md`.

## Verification

- `flutter test test/unit/infrastructure/category/category_locale_service_test.dart` - PASS.
- `flutter test test/unit/features/accounting/presentation/utils/category_display_utils_test.dart` - PASS.
- `flutter test test/unit/infrastructure/category/category_locale_service_test.dart test/architecture/service_name_collision_test.dart` - PASS.
- `flutter test --coverage` - PASS, 1245 tests passed.
- `/Users/xinz/.pub-cache/bin/coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'` - PASS.
- `dart run scripts/coverage_gate.dart lib/infrastructure/category/category_locale_service.dart lib/application/accounting/category_localization_service.dart --threshold 80 --lcov coverage/lcov_clean.info` - PASS, both files 100%.
- `flutter analyze` - FAIL, unrelated pre-existing info findings documented above.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

05-01 is functionally complete. Remaining Phase 5 plans can rely on `CategoryLocaleService` as the infrastructure category localization helper and on the architecture test to prevent the naming collision from returning. The unrelated analyzer findings should be handled outside this plan before a phase-level clean-analyze gate is enforced.

## Self-Check: PASSED

- Found `.planning/phases/05-medium-fixes/05-01-SUMMARY.md`.
- Found `.planning/phases/05-medium-fixes/deferred-items.md`.
- Found commits `61fa14e`, `a93ab74`, and `6a0c9ff` in git history.

---
*Phase: 05-medium-fixes*
*Completed: 2026-04-27*
