---
phase: 07-documentation-sweep
plan: "03"
subsystem: documentation
tags: [docs, pitfall-annotations, path-drift, i18n, DOCS-01, DOCS-02]
dependency_graph:
  requires: []
  provides: [DOCS-01-partial, DOCS-02]
  affects: [CLAUDE.md, .claude/rules/arch.md]
tech_stack:
  added: []
  patterns: [enforcement-status annotations, path-spelling normalization]
key_files:
  created: []
  modified:
    - CLAUDE.md
    - .claude/rules/arch.md
decisions:
  - "Used 3-space indentation for all annotation lines (including items 10-13) to satisfy grep acceptance criterion"
  - "Phantom MOD-014 replaced with BASIC-003 path per D-01 lock"
  - "Mechanical sed replacement for arch.md (all 13 occurrences of doc/arch/)"
metrics:
  duration: "234s"
  completed: "2026-04-27T13:14:27Z"
  tasks_completed: 3
  files_modified: 2
---

# Phase 07 Plan 03: CLAUDE.md Pitfall Annotation + Path Drift Fix Summary

Annotated all 13 Common Pitfalls in CLAUDE.md with locked enforcement-status tags, fixed 6 path-drift sites (`doc/arch/` → `docs/arch/`) in CLAUDE.md, replaced 2 phantom MOD-014 references with BASIC-003, and fixed ~13 path-drift sites in `.claude/rules/arch.md`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 07-03-01 | Annotate 13 Common Pitfalls (DOCS-02) | 8c60920 | CLAUDE.md |
| 07-03-02 | Fix CLAUDE.md path drift + phantom MOD-014 (D4-1..D4-3, D5-1, D5-2) | 61ed96d | CLAUDE.md |
| 07-03-03 | Fix .claude/rules/arch.md path drift (D4-4, D-03) | 6c835bb | .claude/rules/arch.md |

## Pre/Post Grep Counts

### CLAUDE.md — `doc/arch[^/]`

| State | Count |
|-------|-------|
| Before | 6 occurrences (lines 190, 220, 227, 255, 256, 257, 258) |
| After | 0 |

### CLAUDE.md — `MOD-014`

| State | Count |
|-------|-------|
| Before | 2 occurrences (lines 190, 220) |
| After | 0 |

### .claude/rules/arch.md — `doc/arch[^/]`

| State | Count |
|-------|-------|
| Before | 13 occurrences |
| After | 0 |

## Annotation Completeness Check

```
python3 verification: OK: all 13 pitfalls annotated
  grep -cE '^   \*\[(Structurally|Partially) enforced|^   \*\[Manually-checked only' CLAUDE.md → 13
  Structurally enforced: 7  (pitfalls 2, 3, 5, 6, 8, 10, 13)
  Partially enforced:    2  (pitfalls 1, 12)
  Manually-checked only: 4  (pitfalls 4, 7, 9, 11)
```

All annotations match the locked Pitfall-to-annotation map from 07-PATTERNS.md verbatim. Em-dash used throughout, no double-hyphens.

## lib/-clean Confirmation

`git diff --name-only HEAD~3 HEAD` lists only:
- `CLAUDE.md`
- `.claude/rules/arch.md`

Zero changes to `lib/`, `test/`, `pubspec`, `.github/`, or `analysis_options`. lib/-clean invariant satisfied.

## Deviations from Plan

None — plan executed exactly as written. Items 10-13 were initially given 4-space indentation (to align with double-digit numbers) but corrected to 3-space before commit to satisfy the `grep -cE '^   \*\[...'` acceptance criterion requiring exactly 3 spaces for all 13 items.

## Threat Flag Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Documentation-only changes.

## Self-Check

- [x] CLAUDE.md annotated: verified with Python snippet
- [x] CLAUDE.md path drift: `! grep -nE 'doc/arch[^/]' CLAUDE.md` exits 0
- [x] CLAUDE.md MOD-014 clean: `! grep -n 'MOD-014' CLAUDE.md` exits 0
- [x] .claude/rules/arch.md path drift: `! grep -nE 'doc/arch[^/]' .claude/rules/arch.md` exits 0
- [x] Commits exist: 8c60920, 61ed96d, 6c835bb confirmed
- [x] lib/-clean: only CLAUDE.md and .claude/rules/arch.md changed

## Self-Check: PASSED
