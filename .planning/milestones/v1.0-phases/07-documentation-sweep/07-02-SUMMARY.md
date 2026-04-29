---
phase: "07-documentation-sweep"
plan: "02"
subsystem: "docs/arch/03-adr"
tags: [documentation, adr, append-only, drift-fix]
dependency_graph:
  requires: []
  provides: [DOCS-01-adr-drift-fixes]
  affects: [docs/arch/03-adr/ADR-002_Database_Solution.md, docs/arch/03-adr/ADR-007_Layer_Responsibilities.md, docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md]
tech_stack:
  added: []
  patterns: [ADR-append-only, D-06-locked-pattern]
key_files:
  created: []
  modified:
    - docs/arch/03-adr/ADR-002_Database_Solution.md
    - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md
    - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md
decisions:
  - "Cited verified line numbers (audit.yml:69-75 and import_guard.yaml:6) rather than plan's draft citations (64-69 and :5) per threat model T-07-02-02 verification requirement"
  - "dart run custom_lint cited at audit.yml:39 (verified), not :36 as drafted in plan"
metrics:
  duration: "4m 32s"
  completed: "2026-04-27T13:17:33Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 4
---

# Phase 07 Plan 02: ADR Drift Fixes (append-only) Summary

Appended a locked `## Update 2026-04-27: Cleanup Initiative Outcome` section to four ADRs (002, 007, 008, 010) referencing now-deprecated tooling or pre-cleanup file paths, using the D-06 append-only pattern with zero mutations to original decision bodies.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 07-02-01 | Append Cleanup-Outcome update to ADR-002 | 3b6a121 | docs/arch/03-adr/ADR-002_Database_Solution.md (lines 632-652) |
| 07-02-02 | Append Cleanup-Outcome update to ADR-007 | 649ad87 | docs/arch/03-adr/ADR-007_Layer_Responsibilities.md (lines 957-986) |
| 07-02-03 | Append Cleanup-Outcome updates to ADR-008 + ADR-010 | e0687d5 | docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md (lines 1188-1205), docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md (lines 1466-1480) |

## Modified ADRs — Appended Section Line Ranges

| ADR | File | Original Lines | Appended Section Lines | Append Lines Added |
|-----|------|---------------|------------------------|-------------------|
| ADR-002 | ADR-002_Database_Solution.md | 1-631 | 633-652 | +20 |
| ADR-007 | ADR-007_Layer_Responsibilities.md | 1-956 | 958-986 | +30 |
| ADR-008 | ADR-008_Book_Balance_Update_Strategy.md | 1-1187 | 1189-1205 | +17 |
| ADR-010 | ADR-010_CRDT_Conflict_Resolution_Strategy.md | 1-1465 | 1467-1480 | +15 |

## Append-Only Invariant Verification

Per-file `git diff ... | grep -cE '^-[^-]'` results (zero = append-only confirmed):

| ADR | Lines Removed | Status |
|-----|--------------|--------|
| ADR-002 | 0 | PASS |
| ADR-007 | 0 | PASS |
| ADR-008 | 0 | PASS |
| ADR-010 | 0 | PASS |

All four files: **strictly additive diffs only**.

## ADR-011 Forward Link

Each appended section contains the relative link `[ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)`. This link is forward-looking — ADR-011 is created by Plan 07-05 (Wave B). The broken-link state is bounded to in-flight Wave A and will resolve when Plan 07-05 lands. Wave B INDEX health check (Plan 07-04) tolerates this transient state.

## Specific Appendix Content

### ADR-002 Appendix
- Cites CI gate AUDIT-09 at `.github/workflows/audit.yml:69-75` for sqlite3_flutter_libs rejection
- Cites `lib/import_guard.yaml:6` deny rule for `package:sqlite3_flutter_libs/**`
- Notes original lines 52 and 387 (dual-listing of both libraries) are historical context only

### ADR-007 Appendix
- Lists all 5 per-layer import_guard.yaml configs that mechanically enforce layer rules
- Cites `dart run custom_lint` at `.github/workflows/audit.yml:39`
- Cites `test/architecture/domain_import_rules_test.dart` and `test/architecture/provider_graph_hygiene_test.dart`
- Notes mockito body references are pre-Phase-4-04 historical artifacts; post-cleanup uses mocktail

### ADR-008 Appendix
- Notes Phase 3 centralization moved transaction repo from `lib/features/accounting/data/repositories/` to `lib/data/repositories/`
- States post-cleanup source path: `lib/data/repositories/transaction_repository_impl.dart`
- Original code samples at lines ~832, ~848 preserved as historical context

### ADR-010 Appendix
- Notes line-37 path reference moved from `lib/features/accounting/data/repositories/` to `lib/data/repositories/`
- Original line-37 reference preserved as historical context (verified: still present in file)

## Deviations from Plan

### Auto-adjusted Citations (Rule 2 - Verification)

Per threat model T-07-02-02: "Each cited line number is verified via Read in `<read_first>` before the appendix is written."

**Plan's draft citations vs. verified actual:**

| Citation | Plan Draft | Verified Actual | File |
|----------|-----------|-----------------|------|
| AUDIT-09 sqlite3 gate | `audit.yml:64-69` | `audit.yml:69-75` | .github/workflows/audit.yml |
| import_guard deny line | `import_guard.yaml:5` | `import_guard.yaml:6` | lib/import_guard.yaml |
| dart run custom_lint | `audit.yml:36` | `audit.yml:39` | .github/workflows/audit.yml |

All citations in the appended sections use the **verified** line numbers. The plan's draft citations were pre-filled estimates; verification before writing is explicitly required by the threat model.

## lib/-clean Invariant

`git diff --name-only 5b91629..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`.

Only paths under `docs/arch/03-adr/` were modified.

## Known Stubs

None. This plan appends documentation only — no data stubs or placeholders were introduced.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Documentation-only changes.

## Self-Check: PASSED

- [x] All 4 ADR files exist with `## Update 2026-04-27: Cleanup Initiative Outcome` section
- [x] Commit 3b6a121 exists (ADR-002)
- [x] Commit 649ad87 exists (ADR-007)
- [x] Commit e0687d5 exists (ADR-008 + ADR-010)
- [x] All 4 per-file diff guards return 0 (append-only)
- [x] lib/-clean: zero lib/test/pubspec/github/analysis_options files touched
- [x] All 4 ADR-011 cross-references present
