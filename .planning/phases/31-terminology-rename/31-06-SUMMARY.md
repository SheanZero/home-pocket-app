---
phase: 31-terminology-rename
plan: "06"
subsystem: documentation
tags: [adr, terminology, lexical-hierarchy, documentation, requirements]
dependency_graph:
  requires: ["31-05"]
  provides: ["ADR-017", "TERMID-04"]
  affects: ["Phase 33 Color Token System coordination seam", "Phase 34 palette-only golden seam"]
tech_stack:
  added: []
  patterns: ["ADR append-only protocol", "Lexical hierarchy extension"]
key_files:
  created:
    - docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md
  modified:
    - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
    - docs/arch/03-adr/ADR-000_INDEX.md
    - .planning/REQUIREMENTS.md
decisions:
  - "ADR-017 created as born-accepted ADR recording v1.5 canonical vocab mapping (日常/悦己/ときめき/Daily/Joy), identifier convention (survival→daily, soul→joy, soulSatisfaction→joyFullness), and LedgerType enum-rename-with-v18-migration schema decision (D-03/D-04/D-16)"
  - "ADR-015 pointer appended (append-only — body unchanged) per D-15"
  - "REQUIREMENTS.md Out-of-Scope row amended to qualify DB migration exclusion per D-06; TERMID-04 marked Complete"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-01"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 3
---

# Phase 31 Plan 06: ADR-017 Terminology Unification v1.5 + Requirements Amendment Summary

**One-liner:** Born-accepted ADR-017 records canonical 日常/悦己/ときめき/Daily/Joy vocab mapping, identifier convention, and v18 migration schema decision; ADR-015 carries append-only successor pointer; REQUIREMENTS.md Out-of-Scope reconciled with D-02/D-16 scope, satisfying TERMID-04.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Author ADR-017, append ADR-015 pointer, add ADR-000_INDEX entry | cf848239 | docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md (created), ADR-015 (appended), ADR-000_INDEX (updated) |
| 2 | Amend REQUIREMENTS.md Out-of-Scope per D-06 + mark TERMID-04 Complete | 5c6d5114 | .planning/REQUIREMENTS.md |

## What Was Built

### ADR-017: Terminology Unification v1.5

New ADR (`docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md`) created as `✅ 已接受` (born accepted — Phase 31 wave 5). The ADR records five content sections per the plan's D-14 specification:

**1. Canonical locale vocab mapping (D-13/D-14):**

| Concept | zh | ja | en | identifier |
|---------|----|----|-----|------------|
| Survival ledger | 日常 | 日常 (にちじょう) | Daily | `daily` |
| Soul ledger | 悦己 | ときめき | Joy | `joy` |

Includes note on ja asymmetry (`joy` identifier ↔ `ときめき` product UI value — coherent with existing `ときめき指数` joy-index term).

**2. Identifier convention (D-07/D-08):** Complete rename table (survival→daily, soul→joy, soulSatisfaction→joyFullness) covering LedgerType enum, AppColors symbols (including all derived: joyLight, joyFullnessBg/Border, joyRoiBg/Border), ARB keys, and Freezed model field.

**3. LedgerType enum-rename + v18 migration schema decision (D-03/D-04/D-16):** Three sub-step v18 migration — (1) `category_ledger_configs` table recreate with new CHECK `IN('daily','joy')`, (2) `transactions.ledger_type` UPDATE, (3) `soul_satisfaction→joy_fullness` RENAME COLUMN — all wrapped in atomic transaction. Rationale cites D-04 (hash chain does NOT cover ledger_type — SHA-256 payload: `id|amount|timestamp|prevHash`), D-03 (pre-release v0.1.0 clean upgrade), D-16 (fold column rename into same migration window).

**4. Phase 33 coordination seam (D-12):** Explicit sentence that AppColors derived symbols were renamed in Phase 31 (already-renamed) — Phase 33 must only consolidate, MUST NOT re-rename.

**5. Phase 34 golden seam (D-19):** Explicit statement: "terminology-driven golden re-baseline was completed in Phase 31 (Plan 05); Phase 34 handles PALETTE-driven golden re-baseline ONLY."

### ADR-015 Append-Only Pointer (D-15)

One-line `## Update 2026-06-01: Extended by ADR-017` section appended at file end. ADR-015 body sections 1-12 are unchanged — confirmed by `git diff` showing only `+` lines at file end (no `-` lines on body content).

### ADR-000_INDEX.md Update

New ADR-017 entry added in the ADR list (after ADR-016), with full summary including canonical mapping, identifier convention, v18 migration rationale, and Phase 33/34 seam notes. Review table row added. Stats updated from 16→17 total ADRs, accepted count 11→12.

### REQUIREMENTS.md Amendment (D-06)

The blanket Out-of-Scope row `| Migrating database column names... | Identifier rename is source-level...` was replaced with a qualified version explicitly stating:
- v1.5 terminology rename DOES migrate `ledger_type` stored values and renames `soul_satisfaction→joy_fullness` (v17→v18, citing D-02/D-16/ADR-017)
- Other DB column changes (e.g. `entry_source`) remain out of scope

TERMID-04 status in the traceability table updated from `Pending` to `Complete`.

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| ADR-017 file exists | PASS |
| Contains ときめき | PASS |
| Canonical mapping (all 5 tokens: 日常/悦己/ときめき/Daily/Joy) | PASS |
| 已接受 present (>=1) | PASS (3 occurrences) |
| Identifier convention + migration decision (survival→daily/soul→joy + v18/hash) | PASS |
| ADR-015 pointer at file end (no body deletions) | PASS (git diff: +only, no -) |
| ADR-017 in INDEX (>=1 hit) | PASS (2 occurrences) |
| Phase 33 seam (D-12) recorded — already-renamed/consolidat | PASS |
| Phase 34 palette-only seam (D-19) — PALETTE/terminology golden | PASS |
| REQUIREMENTS.md cites D-02/D-16 | PASS |
| REQUIREMENTS.md has ledger_type/soul_satisfaction/joy_fullness | PASS |
| Old blanket exclusion amended | PASS (no match for old text) |
| TERMID-04 Complete | PASS |

## Deviations from Plan

None. Plan executed exactly as written.

## Known Stubs

None. This is a documentation-only plan — no code stubs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced (documentation-only plan). Threat T-31-18 (editing ADR-015 body instead of appending) was mitigated — git diff confirms append-only modification. Threat T-31-19 (incorrect Phase 34 wording) was mitigated — ADR-017 Phase 34 seam section explicitly uses palette-only language.

## Self-Check: PASSED

- [x] `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — FOUND
- [x] ADR-017 pointer in ADR-015 — FOUND (line 192)
- [x] ADR-017 in ADR-000_INDEX.md — FOUND
- [x] REQUIREMENTS.md amended with D-02/D-16 citations — FOUND
- [x] Commit cf848239 — FOUND in git log
- [x] Commit 5c6d5114 — FOUND in git log
