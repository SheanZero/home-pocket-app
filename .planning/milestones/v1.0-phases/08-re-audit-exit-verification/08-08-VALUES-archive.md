# Plan 08-08 Source Values (Archived Working Document)

> Archived working document — see 08-08-PLAN.md Task 1 for context. Values
> below were transcribed into the ADR-011 `## Update 2026-04-28 — Re-audit
> Outcome` section (commit `f3c7606`). Preserved as audit trail per Plan
> 08-08 Task 3 alternate disposition.

**Captured:** 2026-04-28
**Archived:** 2026-04-28 (post-Task-2)

## From .planning/audit/re-audit/REAUDIT-DIFF.json

- resolved: 50
- regression: 0
- new: 0
- open_in_baseline: 0

`reaudit_diff.dart` exits 0 — EXIT-01 + EXIT-02 satisfied (Plan 08-05 close).

## From .planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md

The gate log records the full evolution at three milestones on 2026-04-28:

1. **First run (commit 2f206ba, threshold 80%)** — 4 of 8 gates FAIL. Surfaced
   global coverage 74.6%, 28 riverpod_lint INFO findings, 11 real per-file
   coverage failures + 96 missing-from-lcov entries. STOP per Plan 08-06
   success criterion ("do not 'fix' by editing the gate — document and let
   user decide").
2. **Re-run (commit 03b1a06, threshold 70%)** — Gates 3+4 flip to PASS at
   74.6336%. Gate 2 + Gate 8 unchanged (threshold-independent).
3. **Final re-run (commits 436ccab + 36dfacd)** — `--no-fatal-infos` on
   custom_lint + `--deferred` flag on coverage_gate.dart with 10-entry
   deferred list. ALL 8 GATES PASS. Final per-file gate output:
   `64 checked / 0 failed / 96 missing-from-lcov (skipped) / 10 deferred (skipped)` at threshold 70.

## From .planning/audit/REPO-LOCK-POLICY.md

- "Phase 8 Close — Permanent Gates" section appended on 2026-04-28 (line 70).
- "Update 2026-04-28 — Coverage threshold 80% → 70%" appended (line 87).
- Cross-references ADR-011 `## Update YYYY-MM-DD: Re-audit Outcome` (line 74)
  — this is the placeholder Plan 08-08 fills in with the real date today.

## From .planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md

- Sign-off block: EMPTY (commit d040c12 formally deferred Tasks 2+3 to v1
  release gate per user directive).
- Tracked as FUTURE-QA-01 in REQUIREMENTS.md v2 backlog.
- ROADMAP success criterion 4 amended (artifact = deliverable; behavior
  verification = v1 release gate).

## From .planning/audit/cleanup-touched-files.txt

- Total file count: 170 (Phase 3-6 PLAN.md `files_modified` frontmatter union).

## From .planning/audit/coverage-gate-deferred.txt

- 10 entries under FUTURE-TOOL-03:
  - 3 application provider-wrappers (ml/profile/voice)
  - 4 large UI screens (transaction_entry, transaction_confirm, analytics, create_group)
  - 3 state notifiers / widget sections (state_sync, state_shadow_books, appearance_section)
- Each entry carries WRITTEN RATIONALE (REQUIRED — entries without one cause exit 2).

## From .github/workflows/audit.yml (Plan 08-03 + amendment outputs)

- Top-of-file warning comment block (lines 1-9): PRESENT, references ADR-011 + threshold history.
- `continue-on-error: true` count: 0.
- Coverage job `if: pull_request`: REMOVED (push-to-main also gated).
- Line 48 `flutter analyze --no-fatal-infos`: PRESENT.
- Line 55 `dart run custom_lint --no-fatal-infos`: PRESENT (commit 436ccab).
- Line 123 `coverage_gate.dart --deferred ... --threshold 70`: PRESENT (commit 36dfacd).
- Line 128 `min_coverage: 70`: PRESENT (commit 03b1a06).

## From .planning/REQUIREMENTS.md

- Amendments section line 7-9: 80% → 70% threshold change recorded with
  scope clarifier (forward-only; historical Phase 2-6 wording preserved).
- EXIT-03, EXIT-04, EXIT-05: all checked Complete.
- FUTURE-TOOL-03 (coverage-baseline-review): added 2026-04-28.
- FUTURE-QA-01 (smoke-test-owner-driven): added 2026-04-28.

## Key commits to cite in ADR-011 Update

- `c1b3052` — ADR-011 1.0 created (Phase 7 Plan 07-05) — predecessor.
- `2f206ba` — Plan 08-06 first 8-gate run, surfaced 4 failures.
- `03b1a06` — coverage threshold 80→70 amendment.
- `95b8aa6` — re-run at 70%; Gates 3/4 flip PASS, Gate 2 + Gate 8 still red.
- `436ccab` — Gate 2 close: `--no-fatal-infos` on custom_lint.
- `36dfacd` — Gate 8 close: `--deferred` mechanism + `coverage-gate-deferred.txt`.
- `d040c12` — Plan 08-07 smoke-test execution formally deferred to v1.

## ADR-011 insertion point

- File: `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md`
- Last existing line (184): `- **markdown-link-check CI 门禁：** ...`
- Insertion: append `## Update 2026-04-28 — Re-audit Outcome` at end of file.
- Metadata header bump: 文档版本 1.0 → 1.1 (in-place — frontmatter, per
  coding-rule precedent allowing version metadata edits even on append-only
  ADRs; date 2026-04-28 added).
- Cross-reference target shape (REPO-LOCK-POLICY.md line 74):
  `## Update YYYY-MM-DD: Re-audit Outcome` — section title MUST resolve.
  Using em-dash form `## Update 2026-04-28 — Re-audit Outcome` per
  orchestrator brief; the cross-reference text is illustrative shape only.

## Honesty verification

All values above are READ FROM REAL FILES on disk at 2026-04-28T12:23Z.
None are fabricated. Each downstream citation in the ADR amendment must
trace back to one of these source artifacts.
