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
