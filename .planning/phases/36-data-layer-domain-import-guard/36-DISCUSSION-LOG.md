# Phase 36: Data Layer + Domain + Import Guard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 36-data-layer-domain-import-guard
**Areas discussed:** tags storage design, quantity numeric type, completedAt / completion-merge

---

## tags storage design

| Option | Description | Selected |
|--------|-------------|----------|
| JSON-encoded TextColumn | nullable TextColumn storing JSON `List<String>`; encode/decode at repo boundary; safe for special chars; v2 tag-filter needs no schema change | ✓ |
| Comma-separated TextColumn | simplest `'a,b,c'`, but breaks on commas in a tag and limits future extension | |
| Defer tags entirely (no column) | no tags column in v20, push tags to v2 — conflicts with D4 which lists tags as a v1.6 form field | |

**User's choice:** JSON-encoded TextColumn
**Notes:** Surfaced that ITEM-03's "reuse the existing tag system" premise is unfounded — codebase has no tag column, entity, or table. The field had to be designed, not mirrored.

---

## quantity numeric type

| Option | Description | Selected |
|--------|-------------|----------|
| nullable IntColumn (integer) | whole-count, blank defaults to 1 in UI; matches estimatedPrice IntColumn; no decimal/weight | ✓ |
| nullable RealColumn (decimal) | supports 1.5 / 0.5 (weight) but adds float formatting and v1.6 has no unit concept | |
| nullable TextColumn (freeform) | "2杯"/"500g" — flexible but uncomputable, conflicts with D8 unit-parsing deferral | |

**User's choice:** nullable IntColumn (integer)
**Notes:** No existing `quantity` column anywhere to mirror; type was genuinely open.

---

## completedAt / completion-merge

| Option | Description | Selected |
|--------|-------------|----------|
| Honor D7: no column, LWW | simplest, matches transaction CRDT + competitors; accepts the rare "rename un-checks a completed item" race | |
| Add completedAt sticky column | v20 adds `completedAt DateTime?`; `isCompleted:true` sticky when `completedAt > incoming.updatedAt`; deviates from D7 | ✓ |

**User's choice:** Add completedAt sticky column
**Notes:** ⚠ Deliberate override of locked decision **D7 / SYNC-05** ("LWW, no completedAt column"). User was explicitly told D7 was locked and that the research (PITFALLS OPEN-1) recommended Option B (no column). Chose the column anyway because this is a family-shared public list where the un-check race is real and user-visible, and adding the column later costs another migration. CONTEXT.md flags the required reconciliation of ROADMAP field list + REQUIREMENTS.md SYNC-05/D7 in the same commit. Merge algorithm itself is a Phase 37 deliverable; Phase 36 only lands the column + contract test.

## Claude's Discretion

- `sortOrder` initial-value strategy.
- `addedByBookId` null-handling at attribution display (omit chip, never throw).
- Freezed model field granularity and `shopping_items` index design (follow `transactions` pattern).

## Deferred Ideas

- Tag-based filtering UI → v2 (TAGFILT-01) — JSON column keeps it a non-breaking add.
- Decimal / unit-bearing quantity → out of scope (D8).
- Per-segment independent filter providers (research OPEN-2 Option A) → conflicts with locked D5; a Phase 38 decision.
