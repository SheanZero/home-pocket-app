---
phase: 03-critical-fixes
plan: 01
subsystem: infra
tags: [import_guard, custom_lint, domain_layer, architecture_test, layer_violation, yaml, dart]

# Dependency graph
requires:
  - phase: 01-audit-pipeline-tooling-setup
    provides: import_guard_custom_lint wired in analysis_options.yaml, audit.yml CI pipeline

provides:
  - "6 feature-level domain import_guard.yaml files (deny-only, allow stripped per corrected D-01)"
  - "8 per-subdirectory import_guard.yaml files (models/ and repositories/ with intra-domain allow lists)"
  - "test/architecture/domain_import_rules_test.dart (18 tests — meta-test convention D-02/D-03)"
  - "yaml: ^3.1.0 added to dev_dependencies"
  - "18 LV findings (LV-001..016, LV-023, LV-024) closed in issues.json"

affects:
  - "03-03 (use_cases migration — audit.yml flip gate depends on this plan's LV closures)"
  - "03-04 (ledger_row_data move — remaining LV-022 closes there)"
  - "Phase 4 (inherits clean Domain layer; test/architecture/ extended for provider-graph hygiene)"

# Tech tracking
tech-stack:
  added:
    - "yaml: ^3.1.0 (promoted from transitive to dev_dependencies for architecture test)"
  patterns:
    - "Corrected D-01: parent domain yaml is deny-only; per-subdirectory yamls own allow whitelist"
    - "test/architecture/ directory established as convention for meta-tests about codebase shape"
    - "import_guard_custom_lint evaluates each config in inheritance chain independently (verified)"

key-files:
  created:
    - "lib/features/accounting/domain/models/import_guard.yaml"
    - "lib/features/accounting/domain/repositories/import_guard.yaml"
    - "lib/features/analytics/domain/models/import_guard.yaml"
    - "lib/features/analytics/domain/repositories/import_guard.yaml"
    - "lib/features/family_sync/domain/models/import_guard.yaml"
    - "lib/features/family_sync/domain/repositories/import_guard.yaml"
    - "lib/features/profile/domain/repositories/import_guard.yaml"
    - "lib/features/settings/domain/repositories/import_guard.yaml"
    - "test/architecture/domain_import_rules_test.dart"
  modified:
    - "lib/features/accounting/domain/import_guard.yaml (allow stripped)"
    - "lib/features/analytics/domain/import_guard.yaml (allow stripped)"
    - "lib/features/family_sync/domain/import_guard.yaml (allow stripped)"
    - "lib/features/home/domain/import_guard.yaml (allow stripped)"
    - "lib/features/profile/domain/import_guard.yaml (allow stripped)"
    - "lib/features/settings/domain/import_guard.yaml (allow stripped)"
    - "pubspec.yaml (yaml: ^3.1.0 added to dev_dependencies)"
    - ".planning/audit/issues.json (18 LV findings closed)"

key-decisions:
  - "Corrected D-01 strategy: strip allow from parent feature-level yaml; push to per-subdirectory yamls (RESEARCH.md §Pattern 1 verified against import_guard_custom_lint source)"
  - "test/architecture/ established as project convention for meta-tests (D-03)"
  - "Task 4 (audit.yml blocking flip) DEFERRED per gating condition: 6 open CRITICAL LVs remain (LV-017..022 belong to Plans 03-03/03-04)"

patterns-established:
  - "Pattern: Per-subdirectory import_guard.yaml owns allow whitelist; parent feature-level yaml owns deny only"
  - "Pattern: test/architecture/ contains meta-tests asserting codebase shape invariants"

requirements-completed:
  - CRIT-01
  - CRIT-04
  - CRIT-06

# Metrics
duration: 6min
completed: 2026-04-26
---

# Phase 03 Plan 01: Domain Import Guard Rules Summary

**18 LV layer violations closed via corrected D-01 strategy: deny-only parent yamls + per-subdirectory allow whitelists, enforced by `test/architecture/domain_import_rules_test.dart` (18 tests GREEN)**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-26T06:58:54Z
- **Completed:** 2026-04-26T07:05:49Z
- **Tasks:** 3 of 4 (Task 4 gated — requires all other Phase 3 plans to complete first)
- **Files modified:** 18

## Accomplishments

- Stripped `allow:` block from 6 feature-level domain `import_guard.yaml` files; parent yamls are now pure deny-only (data, infrastructure, application, presentation, flutter)
- Created 8 per-subdirectory `import_guard.yaml` files (3 `models/`, 5 `repositories/`) with intra-domain allow lists that close LV-001..016, LV-023, LV-024
- Established `test/architecture/` directory with `domain_import_rules_test.dart` — 18 tests all GREEN — as the convention for codebase-shape meta-tests per D-02/D-03
- `dart run custom_lint` exits with 0 `layer_violation` findings (LV series fully cleared)
- Closed 18 CRITICAL findings in `issues.json` with `closed_in_phase: 3` + `closed_commit: d6509c9`

## Task Commits

1. **Task 1: Strip parent allow + add per-subdirectory yamls** - `d6509c9` (feat)
2. **Task 2: Architecture meta-test + yaml dev_dependency** - `1ea8718` (test)
3. **Task 3: Close 18 LV findings in issues.json** - `2450c7e` (chore)
4. **Task 4: audit.yml blocking flip** — DEFERRED (gating condition not met: 6 open CRITICALs remain)

## Files Created/Modified

- `lib/features/{accounting,analytics,family_sync,home,profile,settings}/domain/import_guard.yaml` — allow: block stripped (6 files)
- `lib/features/accounting/domain/models/import_guard.yaml` — NEW: allows transaction.dart, category.dart (LV-001..004)
- `lib/features/accounting/domain/repositories/import_guard.yaml` — NEW: allows ../models/{book,category_keyword_preference,category_ledger_config,category,merchant_category_preference,transaction}.dart (LV-005..010)
- `lib/features/analytics/domain/models/import_guard.yaml` — NEW: allows daily_expense.dart, month_comparison.dart (LV-011..012)
- `lib/features/analytics/domain/repositories/import_guard.yaml` — NEW: allows ../models/analytics_aggregate.dart (LV-013)
- `lib/features/family_sync/domain/models/import_guard.yaml` — NEW: allows group_member.dart (LV-014)
- `lib/features/family_sync/domain/repositories/import_guard.yaml` — NEW: allows ../models/{group_info,group_member}.dart (LV-015..016)
- `lib/features/profile/domain/repositories/import_guard.yaml` — NEW: allows ../models/user_profile.dart (LV-023)
- `lib/features/settings/domain/repositories/import_guard.yaml` — NEW: allows ../models/app_settings.dart (LV-024)
- `test/architecture/domain_import_rules_test.dart` — NEW: 18-test architecture meta-test (D-02/D-03)
- `pubspec.yaml` — yaml: ^3.1.0 added to dev_dependencies
- `.planning/audit/issues.json` — 18 LV findings closed (status: closed, closed_in_phase: 3, closed_commit: d6509c9)

## Decisions Made

1. **Corrected D-01 strategy:** RESEARCH.md verified that `import_guard_custom_lint` evaluates each config in the inheritance chain INDEPENDENTLY against its own `allow` whitelist. Retaining `allow` on the parent feature-level yaml would have caused intra-domain imports to still fail. Solution: strip parent `allow`, push whitelists to per-subdirectory yamls.

2. **Task 4 deferred:** The audit.yml blocking flip requires zero open CRITICALs across all findings. 6 remain (LV-017..021 from Plans 03-03, LV-022 from Plan 03-04). Task 4 must execute as the LAST commit of Phase 3 after all other plans merge.

## Deviations from Plan

**1. Task 4 Gating — Expected Deviation**
- **Found during:** Task 3 (verification step)
- **Issue:** Task 4 has an explicit gating condition: zero open CRITICAL findings in issues.json before executing audit.yml flip. 6 CRITICALs remain (LV-017..022), owned by Plans 03-03 and 03-04.
- **Action:** Documented gating failure. Task 4 skipped per plan instruction ("DO NOT RUN until ALL other plans complete").
- **Impact:** None — this is the intended orchestration pattern. audit.yml flip is the LAST commit of Phase 3 per D-17.

**2. issues.json count discrepancy — Documentation correction**
- Plan acceptance criteria stated "returns 5" for remaining open LV findings. Actual count is 6 (LV-017, 018, 019, 020, 021, 022). This is a minor documentation error in PLAN.md (LV-017..021 = 5 + LV-022 = 6). The technical outcome is correct.

**No other deviations — yaml file changes and architecture test executed exactly as specified.**

## Issues Encountered

None — execution was straightforward. The corrected D-01 strategy (documented in RESEARCH.md) worked correctly on first attempt: `dart run custom_lint` showed 0 layer_violation findings after stripping parent allow blocks.

## Known Stubs

None — this plan creates only YAML config files and a test file. No stub/placeholder patterns introduced.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This plan modifies only YAML architectural config files, a Dart test file, and pubspec.yaml. No threat flags.

## Next Phase Readiness

- Domain layer (CRIT-04) verified clean by `dart run custom_lint` (0 LV findings)
- Architecture test convention established in `test/architecture/` for Phase 4 provider-graph hygiene tests
- Remaining CRITICAL findings (6) owned by Plans 03-03 (LV-017..021) and 03-04 (LV-022)
- Task 4 (audit.yml flip) must execute as Phase 3's final commit after all plans merge

## Self-Check: PASSED

- All 9 created files found on disk
- All 3 task commits (d6509c9, 1ea8718, 2450c7e) present in git log
- 18 LV findings closed in issues.json (LV-001..016 + LV-023, LV-024)
- 6 open CRITICALs remaining (LV-017..022, owned by Plans 03-03/03-04)
- `dart run custom_lint` 0 layer_violation findings
- `flutter analyze --no-fatal-infos` CLEAN
- `flutter test test/architecture/` 18/18 PASS

---
*Phase: 03-critical-fixes*
*Completed: 2026-04-26*
