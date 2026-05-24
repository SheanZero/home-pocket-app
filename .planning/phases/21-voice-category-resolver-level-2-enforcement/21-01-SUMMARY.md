---
phase: 21
plan: 01
subsystem: voice-category-resolver
tags: [architecture-test, invariant, voice, category, l2-fallback]
requires: []
provides:
  - D-03 architectural safety net (every L1 has ${l1Id}_other L2)
  - _otherIdOverrides reference shape (cat_other_expense → cat_other_other)
affects: []
tech_stack:
  added: []
  patterns:
    - architecture-test in test/architecture/
    - constants-iteration assertion idiom
key_files:
  created:
    - test/architecture/category_other_l2_invariant_test.dart
  modified: []
decisions:
  - "Use override map (`_otherIdOverrides`) instead of renaming `cat_other_other` to `cat_other_expense_other` — destructive rename forbidden without ADR (PATTERNS.md §7 caveat)."
  - "Hard-assert L1 count == 19 with a directional reason; future PRD changes must consciously update the invariant."
metrics:
  duration_minutes: 8
  completed_date: 2026-05-24
  task_count: 1
  file_count: 1
---

# Phase 21 Plan 01: Voice Category Resolver L2 Enforcement — D-03 Architecture Invariant Summary

**One-liner:** Installs the D-03 architectural safety net (every L1 in `DefaultCategories.expenseL1` has a `${l1Id}_other` L2, with the documented `cat_other_expense → cat_other_other` override) as a runnable architecture test, BEFORE the resolver in Plan 03 depends on it.

## What was built

1 new test file: `test/architecture/category_other_l2_invariant_test.dart` (97 lines).

The test:
- Collects all L1 ids from `DefaultCategories.expenseL1` (asserts exactly 19, matching PRD §10.0).
- Builds an `{id → Category}` map of every level=2 entry in `DefaultCategories.all`.
- For each L1, resolves the expected `_other` L2 id via `_otherIdOverrides[l1Id] ?? '${l1Id}_other'`.
- Asserts the L2 exists, has `level == 2`, and `parentId == l1Id`.
- Collects any missing L1s into a list and fails with the explicit list + remediation guidance ("either add the missing `<l1Id>_other` L2, or — if non-convention — add to `_otherIdOverrides` AND update `VoiceCategoryResolver._ensureL2` (Plan 03) to consult it").

`_otherIdOverrides` is the single-key map `{'cat_other_expense': 'cat_other_other'}` — verified against `default_categories.dart:1181`. The file-level doc comment quotes D-03 from CONTEXT.md and explains why the override exists rather than being renamed.

## Verification

| Check | Command | Result |
| ----- | ------- | ------ |
| Test passes | `flutter test test/architecture/category_other_l2_invariant_test.dart` | exit 0, "All tests passed!" |
| Static analysis | `flutter analyze test/architecture/category_other_l2_invariant_test.dart` | "No issues found! (ran in 1.0s)" |
| Override declared + used | `grep -c "_otherIdOverrides" …` | 4 (≥ 2 required) |
| Override key present | `grep -c "cat_other_expense" …` | 5 (≥ 1 required) |
| Source of truth referenced | `grep -c "DefaultCategories.expenseL1" …` | 2 (≥ 1 required) |

All Plan 21-01 `<done>` criteria satisfied.

## Decisions Made

1. **Override map over destructive rename.** PATTERNS.md §7 caveat is explicit: renaming `cat_other_other` to `cat_other_expense_other` affects existing user databases + sync state and is forbidden without an ADR. The test embraces the aliasing instead and documents the constraint in the doc comment so future maintainers don't "fix" it.
2. **Hard count assertion on L1 = 19.** A change in L1 count signals a PRD §10.0 edit; rather than have the invariant adapt silently, the test asserts the count explicitly and instructs the editor to re-validate D-03 assumptions.
3. **Single architecture test file, single test block.** PATTERNS.md §7 analog (`mod009_live_lib_scan_test.dart`) uses one group + one test for the architectural invariant; mirrored exactly here for consistency.

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 | Add D-03 architecture invariant test for L1 → `${l1Id}_other` L2 | `f804bf9` |

## Self-Check: PASSED

- File `test/architecture/category_other_l2_invariant_test.dart` exists in the worktree (verified via `git status --short` showing it as the only untracked file before commit, then via the commit's diff stat showing `1 file changed, 97 insertions(+)`).
- Commit `f804bf9` exists on branch `worktree-agent-afbc26c5c5fca542d`.
- `flutter test` and `flutter analyze` both pass green.
- No file deletions in commit.
- No untracked files left in working tree post-commit.
