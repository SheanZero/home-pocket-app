---
phase: 40-data-foundation-domain-sync
plan: "02"
subsystem: architecture-decisions
tags:
  - adr
  - multi-currency
  - documentation
  - exchange-rate
  - hash-chain
  - edit-semantics
dependency_graph:
  requires:
    - 40-01
  provides:
    - ADR-020 (appliedRate TextColumn decision — prerequisite for Wave 2 transactions table impl)
    - ADR-021 (hash chain scope decision — prerequisite for Wave 2 hash_chain_service.dart constraint)
    - ADR-022 (edit semantics — prerequisite for Phase 42 edit UI + Phase 41 rate override state)
  affects:
    - Phase 41 (RATE-06, RateResult override flag design)
    - Phase 42 (DISP-04 superseded by D-01, edit page implementation)
tech_stack:
  added: []
  patterns:
    - ADR append-only format (ratified, locked decisions)
    - Three new ADRs document CONTEXT.md locked decisions before Wave 2 code lands
key_files:
  created:
    - docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md
    - docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md
    - docs/arch/03-adr/ADR-022_Edit_Semantics.md
  modified:
    - docs/arch/03-adr/ADR-000_INDEX.md
decisions:
  - "D-04 (appliedRate TextColumn): locked in ADR-020 — TextColumn prevents double precision loss (Pitfall 1)"
  - "D-05 (no normalization, numeric comparison): locked in ADR-020 — rate stored as-is, compared as double"
  - "D-01 (JPY read-only in edit UI): locked in ADR-022 — only originalAmount+appliedRate are editable inputs"
  - "D-02 (manual override + date change dialog): locked in ADR-022 — dialog rather than silent behavior"
  - "D-03 (non-blocking toast + undo for >1% recalc): locked in ADR-022 — 5-second undo window"
  - "Hash chain scope (ADR-021): new three currency columns excluded from calculateTransactionHash formula"
  - "DISP-04 superseded: ADR-022 is canonical edit-semantics spec; 'bidirectional three-field' wording retired"
metrics:
  duration: "~8 minutes"
  completed_date: "2026-06-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 0
---

# Phase 40 Plan 02: ADR Documentation (Exchange Rate Precision, Hash Chain Scope, Edit Semantics) Summary

Three architecture decision records formalizing multi-currency locked decisions (D-01 through D-05) before any Wave 2 migration code lands.

## What Was Built

### Task 1 — ADR-020 (Exchange Rate Precision) + ADR-021 (Hash Chain Scope)

**Commit:** deed814c

**ADR-020** (`docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md`):
- Locks D-04: `appliedRate` stored as `TextColumn` on transactions table, not `RealColumn`
- Documents the double-precision loss risk (PITFALLS.md Pitfall 1) — RealColumn round-trip can yield different `.round()` result than preview, causing preview-vs-stored JPY divergence
- Three options analyzed: RealColumn (rejected), TextColumn (selected), scaled integer (rejected)
- Single parse site: `convertToJpy()` in `lib/shared/utils/currency_conversion.dart`
- Aligns with transactions table zero-RealColumn precedent (merchant, photoHash all TextColumn)
- References STORE-01, STORE-02

**ADR-021** (`docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md`):
- Locks hash formula preservation: `SHA-256(transactionId|amount|timestamp|previousHash)` unchanged
- Confirms `original_currency`, `original_amount`, `applied_rate` are EXCLUDED from `calculateTransactionHash`
- hash_chain_service.dart zero changes (STORE-04 satisfied)
- Documents the backward-compat rationale: including new columns would invalidate ALL pre-v21 chain hashes
- References STORE-04
- Adds architecture test requirement: `schema_v21_migration_test.dart` must assert four-parameter signature

### Task 2 — ADR-022 (Edit Semantics) + ADR-000_INDEX.md update

**Commit:** c17296fb

**ADR-022** (`docs/arch/03-adr/ADR-022_Edit_Semantics.md`):
- Locks D-01: JPY amount is read-only in edit UI for foreign-currency rows. Two editable inputs: originalAmount + appliedRate. Principle: "原币是事实，日元是结果" (original currency is fact, JPY is result)
- Locks D-02: Manual override + date change triggers dialog asking "保留手动汇率 / 按新日期重取" — no silent behavior in either direction
- Locks D-03: No-override auto-recalc >1% JPY change triggers non-blocking toast + 5-second undo window; saving is never blocked
- Supersedes REQUIREMENTS.md DISP-04 "bidirectional three-field" wording
- Documents Phase 41 constraint: `RateResult` must carry `isManualOverride: bool`
- Documents Phase 42 constraint: edit form per D-01 (two editable fields, one derived display)

**ADR-000_INDEX.md** (`docs/arch/03-adr/ADR-000_INDEX.md`):
- Added full entries for ADR-020, ADR-021, ADR-022
- Updated accepted count: 13 → 16
- Updated total: 18 → 21
- Updated last-updated date: 2026-06-03 → 2026-06-12

## Verification

All success criteria met:

- [x] `ls docs/arch/03-adr/ADR-02*.md` returns three files (ADR-020, ADR-021, ADR-022)
- [x] `grep 'ADR-02[012]' docs/arch/03-adr/ADR-000_INDEX.md` returns three matching section headers
- [x] ADR-020 status "✅ 已接受", contains "TextColumn", references STORE-01/STORE-02
- [x] ADR-021 status "✅ 已接受", contains hash formula `transactionId|amount|timestamp|previousHash`, references STORE-04
- [x] ADR-022 status "✅ 已接受", contains D-01 (JPY read-only), D-02 (dialog), D-03 (toast+undo)
- [x] No Dart files modified in either commit
- [x] No migration code, no schema changes — purely documentation

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — plan produces only documentation artifacts (ADR files). No data-wiring stubs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. ADR files are documentation-only. No threat flags.

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | ADR-020 Exchange Rate Precision + ADR-021 Hash Chain Scope | deed814c | ADR-020_Exchange_Rate_Precision.md, ADR-021_Hash_Chain_Scope.md |
| 2 | ADR-022 Edit Semantics + ADR-000_INDEX.md update | c17296fb | ADR-022_Edit_Semantics.md, ADR-000_INDEX.md |

## Self-Check: PASSED

Files exist:
- FOUND: docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md
- FOUND: docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md
- FOUND: docs/arch/03-adr/ADR-022_Edit_Semantics.md
- FOUND: docs/arch/03-adr/ADR-000_INDEX.md (modified)

Commits exist:
- FOUND: deed814c (Task 1)
- FOUND: c17296fb (Task 2)
