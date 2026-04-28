# Repo Lock Policy — Cleanup Initiative Window

**Locked:** 2026-04-25
**Phase 2**
**Source of Truth:** `.planning/phases/02-coverage-baseline/02-CONTEXT.md` D-07

## Why This Policy Exists

Phase 2 close (BASE-06 / D-05) flips the `very_good_coverage@v2` global coverage gate in `.github/workflows/audit.yml` from non-blocking to **BLOCKING**. The threshold is 80% against `coverage/lcov_clean.info`. The gate is not staged — it is binary, immediate, and applies to every PR.

Current global coverage is approximately 48% raw (CONCERNS.md reports ~68% naive coverage ratio; PROJECT.md notes the discrepancy). Flipping the gate now means non-cleanup PRs cannot pass CI until the cleanup raises the global coverage above the threshold.

This is a deliberate choice. The user is paying this cost in exchange for test-first discipline during the cleanup runway: every fix-phase plan writes characterization tests BEFORE the refactor, so coverage on touched files reaches 80% as part of the same change that touches them.

## The Policy

During the **cleanup runway** (Phase 2 close → Phase 6 close), the `main` branch accepts only PRs that originate from the cleanup roadmap. Specifically:

- PRs implementing a `.planning/phases/{N}-*/` plan are eligible to merge.
- Non-cleanup PRs (feature work, dependency bumps unrelated to audit, documentation tweaks not part of Phase 7) wait until Phase 6 close.
- The user is the sole arbiter of "originates from the cleanup roadmap" — there is no automated label, gating mechanism, or bot enforcement.

## What This Is Not

- **There is no CI-side bypass.** No `[skip-coverage]` label, no `--allow-coverage-failure` flag, no admin override is added. The discipline lives in the project-level workflow, not in CI escape hatches. Adding a bypass would defeat the purpose of D-05.
- **This is not a hotfix freeze.** Genuine production-stopping bugs are still merge-eligible if their fix is scoped to the affected file(s) AND brings those file(s) to 80% coverage. The policy is about scope discipline, not about emergencies.
- **This is not a doc freeze.** Documentation updates inside `.planning/`, `doc/worklog/`, or in-scope `doc/arch/` ADR additions are merge-eligible because they do not touch `lib/` (and thus do not affect coverage). Documentation updates to `doc/arch/` modules touched by the cleanup are explicitly Phase 7 — they batch.

## Lifecycle

| Trigger | Effect | Owner |
|---------|--------|-------|
| Phase 2 plan 02 lands | `very_good_coverage@v2` becomes BLOCKING; lock window OPENS | This plan + Plan 02 |
| Phase 3, 4, 5 close | Lock remains active | Each fix-phase planner cites this doc in their phase plan preamble |
| Phase 6 close | Lock LIFTS; non-cleanup PRs become merge-eligible again | Phase 6 close ceremony |
| Phase 7 (docs sweep) | Operates under normal merge rules; not bound by lock | — |
| Phase 8 (re-audit) | Coverage baseline regenerated; gate stays blocking permanently | Phase 8 close |

## Planner Responsibility (D-07)

Every fix-phase plan (3, 4, 5, 6) MUST include a "Repo Lock Note" section in its plan preamble that:

1. Cites this document by path: `.planning/audit/REPO-LOCK-POLICY.md`
2. Confirms the plan is a cleanup-roadmap PR (i.e., merges under the lock window)
3. Lists the touched files and confirms each will reach 80% coverage as part of the plan

The planner is the enforcement mechanism. The CI gate enforces the coverage bar; the planner enforces the scope bar.

## Rollback Path

If the lock proves untenable (e.g., a critical non-cleanup PR is blocked by the policy and the user judges it must merge), the rollback is two steps:

1. **Revert `very_good_coverage@v2` to non-blocking** — re-add `continue-on-error: true` to the step in `.github/workflows/audit.yml` `coverage` job. One-line YAML edit; takes effect on next CI run.
2. **Document the breach** — append a dated entry to this file under "## Lock Breaches" (create the section on first breach) explaining what happened, what merged, and when the lock re-engaged.

Do not rely on the rollback as an escape valve. The point of D-05 / D-07 is that the lock is *expensive to break* — that expense is the discipline.

## Frozen Baseline (D-08) Interaction

The Phase 2 coverage baseline is FROZEN until Phase 8 (D-08). The lock window protects the baseline from drift: only cleanup PRs touch the codebase, so the baseline-vs-current divergence is bounded by the cleanup roadmap's own scope. Without the lock, non-cleanup PRs could drag global coverage in unpredictable directions, making the Phase 8 re-baseline diff impossible to attribute.

## References

- `.planning/phases/02-coverage-baseline/02-CONTEXT.md` — D-05, D-07, D-08 source-of-truth
- `.planning/PROJECT.md` — Initiative scope and behavior-preservation constraint
- `.planning/ROADMAP.md` — 8-phase ordering; cleanup runway = Phases 3–6
- `.github/workflows/audit.yml` — The `coverage` job whose `continue-on-error` flip triggers this policy
- `.planning/audit/SCHEMA.md` §9 — Coverage Baseline Schema (the contract the gate enforces)

## Phase 8 Close — Permanent Gates

**Locked:** 2026-04-28
**Phase 8** — Codebase Cleanup Initiative terminal phase
**Cross-reference:** [ADR-011](../../docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md) `## Update YYYY-MM-DD: Re-audit Outcome`

The cleanup runway lock window CLOSES at Phase 8 close. The four CI guardrails are now permanent and blocking on every PR and direct push to `main`:

1. **`import_guard`** (custom_lint plugin host) — runs in `.github/workflows/audit.yml` `static-analysis` job, `dart run custom_lint` step.
2. **`riverpod_lint`** (custom_lint plugin host, same step as `import_guard`) — provider hygiene gate.
3. **`coverde` per-file ≥70%** — runs in the `coverage` job; `if: pull_request` lifted per Phase 8 D-05 so push-to-main also gated. *Threshold amended 80→70 on 2026-04-28; see Update below.*
4. **`sqlite3_flutter_libs` reject** — runs in `guardrails` job; greps `pubspec.lock`, exits 1 on detection.

`audit.yml` carries a top-of-file warning comment block recording these as permanent. Weakening any guardrail (adding `continue-on-error: true`, restoring `if: pull_request` on coverage, removing the warning block) requires an ADR-011 amendment.

The non-cleanup PR lock from "## The Policy" (above) is LIFTED at Phase 6 close per the lifecycle table; the **gate-permanence** lock added by this section is independent and remains in force indefinitely.

## Update 2026-04-28 — Coverage threshold 80% → 70%

Phase 8 Plan 08-06 ran all 8 EXIT-04 gates locally on the post-cleanup tree and surfaced a real gap: global coverage of `lcov_clean.info` came in at **74.6%** — ~5pp short of the 80% target inherited from Phase 2 (BASE-06 / D-05). Per-file `coverage_gate.dart` against `cleanup-touched-files.txt` also returned 11 real failures plus 96 missing-from-lcov warnings.

**User decision (option 3 from the Phase 8 Wave-2 review):** lower the active threshold to 70%, proceed to phase close, and re-evaluate after v1 feature work — either raise the bar uniformly back toward 80% or split per-area thresholds (e.g., infrastructure/data 80%, presentation 70%, generated/glue exempt). Tracked as `coverage-baseline-review` in the backlog.

**Concrete edits applied with this amendment:**
- `.github/workflows/audit.yml`: `min_coverage: 80 → 70` (very_good_coverage step) and `coverage_gate.dart --threshold 80 → 70` (per-file gate step). Top-of-file warning comment updated to reference 70 + this amendment.
- `scripts/coverage_baseline.dart`: const `_threshold = 80 → 70`.
- `scripts/coverage_gate.dart`: default `threshold = 80 → 70` (CI invocations pass `--threshold` explicitly, so the default only governs local runs).
- `test/scripts/coverage_baseline_test.dart`: assertion updated from `j['threshold'] == 80` to `== 70`.
- `.planning/REQUIREMENTS.md`: EXIT-03 / EXIT-04 reworded to 70%; EXIT-04 reset to Pending (gate-pass not yet proven against new threshold). Phase 2 BASE-* and per-phase fix-phase wording (CRIT-05, HIGH-08, MED-08, LOW-07) left at 80% as historical record of what those phases delivered.
- `.planning/ROADMAP.md`: Phase 8 success criteria threshold updated from 80 → 70.

The amendment governs **forward** — fix-phase deliverable records (≥80% on touched files for Phases 3-6) remain unchanged. Future fix work targets the active 70% gate plus any per-area policy adopted at the post-feature-work review.
