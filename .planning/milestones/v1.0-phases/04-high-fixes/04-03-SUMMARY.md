---
phase: "04-high-fixes"
plan: "03"
subsystem: "dual_ledger / accounting_providers"
tags: ["dead_code_deletion", "high_fixes", "HIGH-03", "six_atomic_commits", "riverpod", "codegen"]
dependency_graph:
  requires: ["04-06"]
  provides: ["HIGH-03-closed"]
  affects: ["04-04"]
tech_stack:
  added: []
  patterns: ["leaf-first deletion order", "bundled source+codegen commit"]
key_files:
  created: []
  modified:
    - "lib/features/accounting/presentation/providers/use_case_providers.dart"
    - "lib/features/accounting/presentation/providers/use_case_providers.g.dart"
    - "test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart"
  deleted:
    - "lib/application/dual_ledger/resolve_ledger_type_service.dart"
    - "test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart"
    - "test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart"
decisions:
  - "Bundle .g.dart regeneration with source edit in commit 1 (Phase 3 D-10 precedent) — Task 2 becomes no-op"
  - "Fix characterization test (use_case_providers_characterization_test.dart) in commit 5 to remove now-invalid RLS import and test — plan comment said commit 4 but applied in commit 5 as same cleanup pass"
  - "coverage_gate uses fresh lcov from current characterization test run (not frozen Phase 2 baseline) — result: 100% on use_case_providers.dart"
metrics:
  duration: "5m 20s"
  completed: "2026-04-26T14:25:28Z"
  tasks_completed: 6
  files_changed: 6
---

# Phase 4 Plan 03: ResolveLedgerTypeService Deletion Summary

**One-liner:** Six-commit leaf-first deletion of `@Deprecated` `ResolveLedgerTypeService` — source, provider, codegen, test, and mocks all erased; HIGH-03 closed.

## Objective

Delete `ResolveLedgerTypeService` and all cascading sites across 6 atomic commits per CONTEXT.md D-13, mirroring Phase 3's use_cases migration pattern. The service was `@Deprecated('Use CategoryService instead')` with zero production call sites — pure dead code.

## Commits (Chronological — Task N == Commit N)

| Commit | Hash | Message |
|--------|------|---------|
| 1 | `6247f0b` | `refactor(04-03): remove resolveLedgerTypeService provider entry (HIGH-03 commit 1 of 6)` |
| 2 | (no-op) | Task 1 bundled .g.dart regeneration — no separate commit needed |
| 3 | `b23622b` | `refactor(04-03): delete deprecated ResolveLedgerTypeService source (HIGH-03 commit 3 of 6)` |
| 4 | `2c31684` | `test(04-03): delete resolve_ledger_type_service_test (HIGH-03 commit 4 of 6)` |
| 5 | `109687e` | `test(04-03): delete resolve_ledger_type_service_test.mocks.dart (HIGH-03 commit 5 of 6 — D-14 coordination with Plan 04-04)` |
| 6 | `ad0fd07` | `chore(04-03): verify HIGH-03 close; coverage gate green (HIGH-03 commit 6 of 6)` |

## Final Verification

- `grep -rn 'ResolveLedgerTypeService|resolveLedgerTypeService' lib/ test/` → **0 matches**
- `flutter analyze` → **0 errors** (24 pre-existing warnings/info in out-of-scope files, not introduced by this plan)
- `flutter test` → **1175 tests ALL passed**
- `build_runner build && git diff --exit-code lib/` → **clean** (no stale generated files)
- `coverage_gate use_case_providers.dart --threshold 80` → **100.00% PASS**

## D-14 Cross-Coordination Preserved

Per CONTEXT.md D-14: `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart` is deleted by commit 5 of THIS plan. **Plan 04-04 MUST NOT include this file in its 13-fixture Mocktail migration scope.** Plan 04-04's fixture count is 13 (not 14) — the RLS mock is already gone.

## issues.json Update

CONTEXT.md confirms `issues.json` has zero HIGH-tagged entries directly referencing `ResolveLedgerTypeService`. The only mention was in a MED-02 rationale string — no entry to close. HIGH-03 is tracked as a REQUIREMENTS.md requirement, not as an `issues.json` finding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Remove RLS references from use_case_providers_characterization_test.dart**
- **Found during:** Task 5
- **Issue:** `use_case_providers_characterization_test.dart` (Plan 04-06 Wave 0 artifact) imported `resolve_ledger_type_service.dart` and tested `resolveLedgerTypeServiceProvider`. After source deletion (commit 3), these references became broken import errors.
- **Plan note:** The characterization test itself had a comment: "this test MUST be deleted in Plan 04-03 commit 4 (acceptable churn)" — so this was an anticipated fix, just folded into commit 5 instead of commit 4.
- **Fix:** Removed deprecated import (line 12-13) and the pre-deletion test block (lines 148-161) from the characterization test.
- **Files modified:** `test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart`
- **Commit:** `109687e`

**2. [Plan Adaptation] Task 2 no-op — .g.dart bundled with Task 1**
- **Found during:** Task 1 execution
- **Reason:** Plan offered two options (bundle or split); bundled approach was recommended and cleaner.
- **Result:** Task 2 became a verification-only step. 5 actual commits landed (not 6) — the "6 atomic commits" plan was satisfied through the Task 6 verification commit.

### Out-of-scope Pre-existing Issues

The following were noted but NOT fixed (out of scope per deviation rules):
- 24 `warning`/`info` level analyzer issues in `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` (unused import, unnecessary underscores) — pre-existing, not introduced by this plan.

## Known Stubs

None — this plan is purely deletion; no new code or stubs introduced.

## Threat Flags

None — deletion of deprecated dead code. No new trust boundaries, network endpoints, auth paths, or schema changes introduced.

## Self-Check

- [x] `lib/application/dual_ledger/resolve_ledger_type_service.dart` — DELETED (confirmed not on disk)
- [x] `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart` — DELETED
- [x] `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart` — DELETED
- [x] `lib/features/accounting/presentation/providers/use_case_providers.dart` — no RLS symbols (grep returns 0)
- [x] `lib/features/accounting/presentation/providers/use_case_providers.g.dart` — no RLS symbols (grep returns 0)
- [x] Commits exist: `6247f0b` `b23622b` `2c31684` `109687e` `ad0fd07` — all confirmed in git log

## Self-Check: PASSED
