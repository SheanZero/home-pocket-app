---
phase: 03-critical-fixes
plan: "03"
subsystem: family_sync
tags:
  - use_cases_migration
  - thin_feature_rule
  - critical_fixes
  - layer_violation
dependency_graph:
  requires:
    - "03-05 (characterization tests for deactivate/regenerate/remove_member — D-15 coverage gate)"
  provides:
    - "lib/application/family_sync/check_group_use_case.dart (LV-017 closed)"
    - "lib/application/family_sync/deactivate_group_use_case.dart (LV-018 closed)"
    - "lib/application/family_sync/leave_group_use_case.dart (LV-019 closed)"
    - "lib/application/family_sync/regenerate_invite_use_case.dart (LV-020 closed)"
    - "lib/application/family_sync/remove_member_use_case.dart (LV-021 closed)"
    - "lib/features/family_sync/import_guard.yaml (D-10 literal compliance)"
  affects:
    - "03-01 (phase close gate — all 5 LV findings now closed)"
tech_stack:
  added: []
  patterns:
    - "git mv for rename-preserving file moves (per RESEARCH.md Pitfall 5)"
    - "feature-scoped import_guard.yaml supplementing global deny rule"
    - "cross-feature domain references via package:home_pocket/... absolute paths"
key_files:
  created:
    - "lib/features/family_sync/import_guard.yaml"
  modified:
    - "lib/application/family_sync/check_group_use_case.dart"
    - "lib/application/family_sync/deactivate_group_use_case.dart"
    - "lib/application/family_sync/leave_group_use_case.dart"
    - "lib/application/family_sync/regenerate_invite_use_case.dart"
    - "lib/application/family_sync/remove_member_use_case.dart"
    - "test/unit/application/family_sync/check_group_use_case_test.dart"
    - "test/unit/application/family_sync/deactivate_group_use_case_test.dart"
    - "test/unit/application/family_sync/leave_group_use_case_test.dart"
    - "test/unit/application/family_sync/regenerate_invite_use_case_test.dart"
    - "test/unit/application/family_sync/remove_member_use_case_test.dart"
    - "lib/features/family_sync/presentation/providers/group_providers.dart"
    - "lib/features/family_sync/presentation/screens/create_group_screen.dart"
    - "lib/features/family_sync/presentation/screens/group_management_screen.dart"
    - "lib/features/family_sync/presentation/screens/member_approval_screen.dart"
    - "lib/features/family_sync/presentation/screens/waiting_approval_screen.dart"
    - "lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart"
    - "test/widget/features/family_sync/presentation/screens/group_management_screen_test.dart"
    - "test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart"
    - "test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart"
    - "test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart"
    - "test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart"
    - "test/widget/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart"
    - ".planning/audit/issues.json"
decisions:
  - "Migrated all 5 use_cases in a single wave (all callers updated atomically) to maintain analyze exit 0 after every commit"
  - "feature-scoped import_guard.yaml uses same schema as global rule (deny + inherit: true) per D-10 literal wording"
  - "Relative imports in moved source files rewritten from 3-up (features/family_sync/use_cases/) to 2-up (application/family_sync/); domain refs converted to cross-feature absolute package: paths"
metrics:
  duration: "~30 minutes"
  completed_date: "2026-04-26"
  tasks_completed: 6
  files_changed: 23
---

# Phase 03 Plan 03: use_cases Migration Summary

**One-liner:** Migrated 5 family_sync use_case files from `lib/features/family_sync/use_cases/` to `lib/application/family_sync/` via git mv, closing LV-017..LV-021 and adding a feature-scoped deny rule per CONTEXT.md D-10.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Migrate check_group_use_case (LV-017) + all callers | 0e370d8 | DONE |
| 2 | Migrate deactivate_group_use_case (LV-018) — import fix | 3ff381a | DONE |
| 3 | Migrate leave_group_use_case (LV-019) — import fix | 84018b9 | DONE |
| 4 | Migrate regenerate_invite_use_case (LV-020) — import fix | 122cb8b | DONE |
| 5 | Migrate remove_member_use_case (LV-021) + delete use_cases/ dir | b66ab47, c681e22 | DONE |
| 6 | Add lib/features/family_sync/import_guard.yaml (D-10) | 295edba | DONE |

## Commits

- `0e370d8`: refactor(03-03): move check_group_use_case to lib/application/family_sync (LV-017)
  - git mv source + test; 6 lib callers + 5 widget test callers updated; all imports rewritten
- `3ff381a`: refactor(03-03): move deactivate_group_use_case to lib/application/family_sync (LV-018)
- `84018b9`: refactor(03-03): move leave_group_use_case to lib/application/family_sync (LV-019)
- `122cb8b`: refactor(03-03): move regenerate_invite_use_case to lib/application/family_sync (LV-020)
- `b66ab47`: refactor(03-03): move remove_member_use_case to lib/application/family_sync (LV-021)
- `c681e22`: chore(03-03): remove empty lib/features/family_sync/use_cases/ directory (CRIT-02 close) + LV-017..LV-021 closed in issues.json
- `295edba`: chore(03-03): add lib/features/family_sync/import_guard.yaml — D-10 literal (LV-017..LV-021)

## LV Findings Closed

| Finding | File | Commit |
|---------|------|--------|
| LV-017 | check_group_use_case.dart | 0e370d8 |
| LV-018 | deactivate_group_use_case.dart | 3ff381a |
| LV-019 | leave_group_use_case.dart | 84018b9 |
| LV-020 | regenerate_invite_use_case.dart | 122cb8b |
| LV-021 | remove_member_use_case.dart | b66ab47 |

**CRIT-02 closed:** `lib/features/family_sync/use_cases/` directory no longer exists.

## Verification Results

| Gate | Result |
|------|--------|
| `flutter analyze --no-fatal-infos` | PASS (0 issues) |
| `dart run custom_lint` | PASS (37 INFO-only pre-existing; no layer_violation) |
| `flutter test` (974 tests) | PASS |
| LV-017..LV-021 closed in issues.json | PASS |
| `lib/features/family_sync/use_cases/` deleted | PASS |
| `lib/features/family_sync/import_guard.yaml` exists | PASS |
| import_guard deny rule for use_cases/** | PASS |
| inherit: true | PASS |
| D-10 cited in import_guard.yaml | PASS |

## Coverage Gate Result

**Note (coordination dependency):** `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan03-touched.txt --threshold 80` shows 3 files below 80%:

| File | Coverage | Status |
|------|----------|--------|
| check_group_use_case.dart | 93.88% | PASS |
| leave_group_use_case.dart | 91.67% | PASS |
| deactivate_group_use_case.dart | 66.67% | FAIL — needs Plan 03-05 tests |
| regenerate_invite_use_case.dart | 66.67% | FAIL — needs Plan 03-05 tests |
| remove_member_use_case.dart | 71.43% | FAIL — needs Plan 03-05 tests |

Per CONTEXT.md D-15 and plan Task 5, these 3 files are in `files-needing-tests.txt` (lines 70-72). Plan 03-05 is responsible for writing characterization tests for these files BEFORE their coverage gate is evaluated at Phase 3 close. The coverage gate failure here is a coordination dependency, not a plan 03-03 defect.

## Import Path Rewrite Summary

For files moved from `lib/features/family_sync/use_cases/` to `lib/application/family_sync/`:
- `../../../infrastructure/<X>` (3-up) → `../../infrastructure/<X>` (2-up)
- `../../../application/<X>` (3-up) → sibling `<X>` (same directory)
- `../domain/repositories/<X>` (relative) → `../../features/family_sync/domain/repositories/<X>` (cross-feature)
- `../domain/models/<X>` (relative) → `../../features/family_sync/domain/models/<X>` (cross-feature)

All callers in `lib/features/family_sync/presentation/` updated from relative `../../use_cases/<X>` to absolute `package:home_pocket/application/family_sync/<X>`.

## Deviations from Plan

**1. [Rule — Strategy] All 5 files moved in single wave instead of sequential per-file commits**

- **Found during:** Task 1
- **Issue:** All callers in `group_providers.dart` import all 5 use_cases simultaneously; updating only one caller would leave other imports broken, causing `flutter analyze` to fail after Task 1's caller updates.
- **Fix:** Performed all 5 `git mv` operations and all caller updates atomically in one wave. Then committed per-file import adjustments (Tasks 2-5) as separate commits. Each Task 2-5 commit modifies only the moved file + its test (source import fixes), maintaining per-file commit granularity for the import adjustments.
- **Impact:** The commit for Task 1 includes all 5 git mv renames (git stages them together since they were all in the working tree). Subsequent commits (Tasks 2-5) capture the import rewrites per-file. Net result satisfies the "per-file atomic commit" requirement for review/bisect purposes.
- **Files modified:** All 5 source + test moves, all 6 lib presentation callers, all 5 widget test callers

## Known Stubs

None — this plan is a pure refactor (file moves + import path adjustments). No data, no UI, no stubs introduced.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## git log --follow verification

The `git mv` approach ensures rename detection. Verify history preservation with:
```bash
git log --follow lib/application/family_sync/check_group_use_case.dart
git log --follow lib/application/family_sync/deactivate_group_use_case.dart
# etc.
```

Each file should show pre-move history from `lib/features/family_sync/use_cases/`.

## Self-Check: PASSED

All files verified present at new locations. All LV findings closed in issues.json. All commits recorded in git log.
