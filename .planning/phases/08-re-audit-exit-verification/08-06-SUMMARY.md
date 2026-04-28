---
phase: 08-re-audit-exit-verification
plan: 06
subsystem: testing
tags: [coverage, lcov, coverde, custom_lint, riverpod_lint, import_guard, build_runner, dart_code_linter, exit-gates]

# Dependency graph
requires:
  - phase: 08-re-audit-exit-verification (Plan 08-02)
    provides: cleanup-touched-files.txt (170 entries — Phase 3-6 plan files_modified union)
  - phase: 08-re-audit-exit-verification (Plan 08-03)
    provides: audit.yml hardened (no soft-fail; if pull_request lifted on coverage job)
  - phase: 08-re-audit-exit-verification (Plan 08-04)
    provides: 3 widget golden tests (amount_display, summary_cards, soul_fullness_card) feeding lcov_clean.info
provides:
  - Regenerated post-cleanup coverage baseline (.planning/audit/coverage-baseline.txt + .json)
  - Regenerated post-cleanup files-needing-tests (.planning/audit/files-needing-tests.txt + .json) — 67 entries (down from 102)
  - 08-06-GATES-LOG.md verification log — 4 of 8 EXIT-04 gates PASS, 4 FAIL with detailed failure context
  - Discovery surfaced for user decision: Phase 8 EXIT-03 + EXIT-04 cannot close on current state
affects: [08-07-PLAN.md, 08-08-PLAN.md, ADR-011 amendment]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Coverage pipeline regeneration: flutter test --coverage → coverde filter → coverage_baseline.dart (unchanged)"
    - "Gate verification log: 8-row markdown table + per-failure context appendix"

key-files:
  created:
    - .planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md
  modified:
    - .planning/audit/coverage-baseline.txt
    - .planning/audit/coverage-baseline.json
    - .planning/audit/files-needing-tests.txt
    - .planning/audit/files-needing-tests.json

key-decisions:
  - "Used coverde 0.3.0+1 (matches audit.yml line 36) instead of plan-suggested 3.0.0 (Rule 1 fix — version mismatch in plan)."
  - "Initial Gate 4 implementation interpreted very_good_coverage@v2 as per-file ≥80%; corrected to global ≥80% (matches action's documented min_coverage semantic)."
  - "Stopped at gate-failure documentation per plan success_criteria — did NOT mark EXIT-03/EXIT-04 complete; did NOT edit gates to pass; surfaced for user review."
  - "Coverage gain captured: 41 lib/ files newly above-threshold post-Phases 3-6 + Plan 08-04 goldens. 35 net file-improvement (102 → 67 below-threshold)."

patterns-established:
  - "Pattern: Gate verification log format — 8-row table + per-failure context section + machine-grep STATUS line"
  - "Pattern: coverage_gate WARNING semantics — entries in input list missing from lcov are reported as 0% FAIL (96 of 107 Gate 8 'failures' are WARNINGs from .g.dart, .arb, .yaml entries Plan 08-02 chose not to filter)"

requirements-completed: []  # NEITHER EXIT-03 NOR EXIT-04 marked complete — 4 gates failed.

# Metrics
duration: 7m
completed: 2026-04-28
---

# Phase 8 Plan 06: Coverage Regeneration + EXIT-04 Gate Verification Summary

**Regenerated post-cleanup coverage baseline (102 → 67 files below 80%) and ran all 8 EXIT-04 gates locally; 4 of 8 PASS, 4 FAIL — surfacing as Phase 8 close discovery for user decision.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-04-28T07:01:00Z
- **Completed:** 2026-04-28T07:07:16Z
- **Tasks:** 3 of 3 (Task 1 ephemeral; Tasks 2, 3 committed)
- **Files modified:** 5 (4 baseline artifacts + 1 new gates log)

## Accomplishments

- Regenerated 4 baseline artifacts deterministically from post-cleanup `coverage/lcov_clean.info`:
  - `coverage-baseline.txt`: 234 → 232 entries (2 generated files filtered out)
  - `files-needing-tests.txt`: 102 → 67 entries (35 file improvement; 41 newly above threshold)
- Determinism verified: re-running `coverage_baseline.dart` produces byte-identical `.txt` output (zero diff lines).
- Ran all 8 EXIT-04 gates locally:
  - **PASS (4):** Gate 1 (`flutter analyze`), Gate 5 (import_guard 0 violations), Gate 6 (`check-unused-code lib`), Gate 7 (`build_runner` stale-diff)
  - **FAIL (4):** Gate 2 (`custom_lint` 28 INFO findings), Gate 3 (global coverage 74.6% < 80%), Gate 4 (very_good_coverage same as Gate 3), Gate 8 (`coverage_gate.dart` 11 real failures + 96 missing-from-lcov WARNINGs)
- Created structured `08-06-GATES-LOG.md` with full per-failure context appendix for ADR-011 reference and user decision.

## Task Commits

1. **Task 1: flutter test --coverage** — no commit (ephemeral; `coverage/` is gitignored)
2. **Task 2: regenerate baseline artifacts** — `2f206ba` (docs)
3. **Task 3: run 8 EXIT-04 gates** — `bfe3786` (docs)

_Note: Plan metadata commit comes in Plan 08-06's final-commit step after this SUMMARY._

## Files Created/Modified

- `.planning/audit/coverage-baseline.txt` (modified) — Per-file coverage TSV; 232 entries
- `.planning/audit/coverage-baseline.json` (modified) — Same data + metadata; 232 entries
- `.planning/audit/files-needing-tests.txt` (modified) — Files <80%; 67 entries
- `.planning/audit/files-needing-tests.json` (modified) — Same + percentages
- `.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md` (created) — 8-row gate table + failure-context appendix

## Decisions Made

1. **Coverde version:** Used `coverde 0.3.0+1` (matching `audit.yml` line 36), not plan-suggested `3.0.0`. The plan text appeared to have a typo — `0.3.0+1` is the actually-pinned version. Treated as Rule 1 (bug auto-fix) so local-vs-CI parity is preserved.

2. **Gate 4 semantics:** Initial implementation interpreted `very_good_coverage@v2` `min_coverage: 80` as per-file. Corrected to global ≥80% (sum-of-LH / sum-of-LF) before logging — matches the action's documented behavior. Gate 4 effectively duplicates Gate 3's measurement.

3. **Stop-on-failure discipline:** Plan success_criteria says "If a gate fails (e.g., per-file 80% gate flags some untouched lib/ files), document precisely what failed. Do not 'fix' by editing the gate — document and let user decide." Followed this strictly. Did NOT edit the gates to pass. Did NOT mark EXIT-03/EXIT-04 complete.

4. **Provenance attribution:** All 28 Gate 2 INFO findings traced to Phase 4 commits (`refactor(04-02): family_sync ...` and similar). Pre-existing — not Phase 8 introduced.

## Coverage Delta vs Pre-Cleanup Baseline (for ADR-011 reference)

| Metric | Phase 2 Baseline | Post-Cleanup (Plan 08-06) | Delta |
|---|---|---|---|
| Total files measured | 234 | 232 | -2 |
| Files below 80% | 102 | 67 | -35 (43% reduction) |
| Files newly above-threshold | — | 41 | +41 |
| Global coverage | (Phase 2 inferred ~68%) | 74.6% | +~6.6 pp |

Newly-passing files include all of `summary_cards.dart`, `voice_input_screen.dart`, `analytics_providers.dart`, `merchant_database.dart`, `push_notification_service.dart`, `relay_api_client.dart`, `sync_engine.dart`, `sync_orchestrator.dart`, `transaction_change_tracker.dart` — confirming Plan 08-04 goldens + Phase 4-6 characterization tests had measurable effect.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Coverde version mismatch in plan text**

- **Found during:** Task 1 (coverde install)
- **Issue:** Plan suggested `dart pub global activate coverde 3.0.0`, but `audit.yml` line 36 uses `coverde 0.3.0+1`. Plan version is incorrect (3.0.0 doesn't exist; coverde latest is ~0.3.x).
- **Fix:** Activated `coverde 0.3.0+1` to match audit.yml exactly, preserving local-vs-CI parity.
- **Files modified:** None (Dart pub global state)
- **Verification:** `dart pub global run coverde filter ...` exited 0 with same `--filters` regex as audit.yml.
- **Committed in:** None (no source change required).

**2. [Rule 1 - Bug] Gate 4 (very_good_coverage) interpreted wrong**

- **Found during:** Task 3, Gate 4 attempt
- **Issue:** Initial awk script computed per-file ≥80% for Gate 4. very_good_coverage@v2's `min_coverage: 80` is GLOBAL, not per-file (action source documented).
- **Fix:** Replaced awk with global-pct calculation; rewrote log row.
- **Files modified:** `.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md`
- **Verification:** Result (74.6%) matches Gate 3 arithmetic — both gates measure the same thing via different mechanisms.
- **Committed in:** `bfe3786` (Task 3 commit, log file).

---

**Total deviations:** 2 auto-fixed (Rule 1 × 2)
**Impact on plan:** No scope creep. Both fixes preserve plan intent.

## Discoveries Surfaced for User Decision (BLOCKING for Phase 8 close)

### Discovery 1: Gate 2 (`dart run custom_lint`) — 28 INFO-level findings, blocking exit code

`audit.yml` line 48 runs `dart run custom_lint` WITHOUT `--no-fatal-infos`. This means INFO-level findings cause exit-1 (CI hard-fail). The 28 findings are:
- 25 × `avoid_manual_providers_as_generated_provider_dependency` (riverpod_lint)
- 3 × `scoped_providers_should_specify_dependencies` (riverpod_lint, test files only)
- 0 × `import_guard` violations (Gate 5 PASS)

**Files affected (lib/):** `application/family_sync/repository_providers.dart`, `features/{accounting,analytics,family_sync}/presentation/providers/repository_providers.dart`, `features/family_sync/presentation/providers/state_sync.dart`, `infrastructure/{crypto,security}/providers.dart`.

**Provenance:** All `lib/` files were last touched in Phase 4 (HIGH-02/04 fixes per `c881d0d`, `137de53`). Findings are pre-existing — not Phase 8 introduced.

**User decision needed:** Two paths to gate-pass:
1. **(Lower scope)** Add `--no-fatal-infos` to `dart run custom_lint` in `audit.yml` line 48. Matches the flag already in use by `audit/layer.dart` line 73 and `audit/providers.dart` line 72 (which run custom_lint internally with `--no-fatal-infos`). Note: this would NOT contradict the EXIT-04 spirit — `import_guard` (the load-bearing rule) is already 0 violations and Gate 5 PASS regardless of the flag.
2. **(Higher scope)** Refactor the 7 `lib/` files to eliminate `avoid_manual_providers_as_generated_provider_dependency` warnings — convert manual providers to `@riverpod`. Significant scope expansion, would need a new plan.

### Discovery 2: Gate 3/4 — Global coverage 74.6% < 80% threshold

Even after Phase 4-6 cleanup + Plan 08-04 widget goldens, global coverage on `lib/` is 74.6% via `lcov_clean.info`. The 80% global threshold is documented in `EXIT-03` and enforced by `very_good_coverage@v2` (`audit.yml` line 118). Files-needing-tests count: 67.

**User decision needed:** EXIT-03 success criterion is "≥80% global coverage." Phase 8 cannot close without either:
1. **Lowering threshold** — Out of scope per locked decisions; would require an ADR amendment.
2. **Adding tests** — Multi-plan effort. Most-leveraged candidates (low LH/LF ratios from `files-needing-tests.txt`):
   - `lib/application/profile/repository_providers.dart` (0.00%)
   - `lib/application/analytics/demo_data_service.dart` (0.00%)
   - `lib/data/repositories/sync_repository_impl.dart` (4.0%)
   - `lib/data/daos/sync_queue_dao.dart` (4.3%)
   - `lib/features/family_sync/presentation/screens/create_group_screen.dart` (17.7%)

### Discovery 3: Gate 8 — coverage_gate.dart per-file 80%

107 of 170 entries failed. Decomposes as:

- **96 WARNINGs from missing-from-lcov entries:** `cleanup-touched-files.txt` literally mirrors `files_modified` plan frontmatter, including non-Dart entries:
  - 22 × `*.g.dart` (filtered out by coverde)
  - 3 × `*.arb` (no Dart code)
  - 4 × `*.yaml` (config files like `import_guard.yaml`)
  - ~67 × Dart files not exercised by any test
  
  Plan 08-02 D-04 explicitly accepted this: "cleanup-touched-files.txt does NOT pre-filter .g.dart/.arb — coverde filter excludes them downstream and coverage_gate emits a non-blocking WARNING." However, the WARNING **does** contribute to exit-1 (`coverage_gate.dart` lines 130-138 + 144 + 166).

- **11 real failures:** Dart source files actually under 80%:
  | File | % |
  |---|---|
  | application/profile/repository_providers.dart | 0.00 |
  | application/ml/repository_providers.dart | 40.00 |
  | application/voice/repository_providers.dart | 40.00 |
  | application/accounting/repository_providers.dart | 75.00 |
  | features/family_sync/presentation/screens/create_group_screen.dart | 17.71 |
  | features/home/presentation/providers/state_shadow_books.dart | 34.62 |
  | features/accounting/presentation/screens/transaction_entry_screen.dart | 45.96 |
  | features/analytics/presentation/screens/analytics_screen.dart | 52.73 |
  | features/settings/presentation/widgets/appearance_section.dart | 60.00 |
  | features/family_sync/presentation/providers/state_sync.dart | 61.90 |
  | features/accounting/presentation/screens/transaction_confirm_screen.dart | 63.28 |

**User decision needed:** Either fix `coverage_gate.dart` policy (WARNINGs should not contribute to exit-1) OR pre-filter `cleanup-touched-files.txt` (contradicts Plan 08-02 D-04). Plus add tests for the 11 real failures.

### Discovery 4: amount_display.dart still absent from cleanup-touched-files.txt (Plan 08-04 deferred item)

Per `deferred-items.md`, `lib/features/accounting/presentation/widgets/amount_display.dart` is NOT in `cleanup-touched-files.txt`. Plan 08-06 was identified as the natural place to revisit. Confirmed: still absent. Not blocking on its own — `coverage_gate.dart` simply doesn't measure it against the per-file 80% gate. The widget golden test from Plan 08-04 contributes to global coverage (Gate 3/4) regardless.

**Disposition:** Out of Plan 08-06 scope (would require regenerating `cleanup-touched-files.txt`, contradicting Plan 08-02 D-04 frontmatter-literal-mirror policy). Defer to user.

## Issues Encountered

- Coverde version typo in plan text → fixed via Rule 1.
- Gate 4 semantic interpretation → corrected via Rule 1.
- 4 gates failed simultaneously → did not auto-fix; surfaced as discoveries per plan policy.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Phase 8 cannot close on current state.** EXIT-03 and EXIT-04 are NOT satisfied. Plan 08-08 (ADR-011 amendment, depends on 08-05 + 08-06) is BLOCKED until user decides on gate-pass approach.

Recommended user actions (in priority order):
1. **Decide on Gate 2 fix:** Add `--no-fatal-infos` to `audit.yml` line 48 (low-scope, preserves intent) OR refactor 7 lib/ files to eliminate INFO findings (high-scope).
2. **Decide on Gate 3/4 path:** Spawn a coverage-tests plan to add tests for the 11 lowest-coverage Dart source files OR amend EXIT-03 threshold (requires ADR-011 update).
3. **Decide on Gate 8 policy:** Filter `cleanup-touched-files.txt` to remove non-Dart entries (contradicts 08-02 D-04) OR change `coverage_gate.dart` to make WARNING-not-fail (a policy change that may need ADR coverage).
4. **Decide on amount_display.dart frontmatter gap:** Either patch Phase 3-6 plan frontmatter retroactively (out of cleanup-runway lock) OR document as deferred to v2.

The four PASS gates (1, 5, 6, 7) confirm: `flutter analyze` clean, `import_guard` clean, no unused code in `lib/`, and `build_runner` produces no stale generated files. These guardrails are working as intended.

## Cross-References

- **Gates log:** `.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md` — full per-gate exit codes + failure context appendix
- **Phase 8 D-04:** `.planning/phases/08-re-audit-exit-verification/08-CONTEXT.md` — coverage gate scope decision (cleanup-touched-files.txt as-is)
- **Plan 08-02 D-04:** `cleanup-touched-files.txt` does NOT pre-filter — accepts coverage_gate WARNINGs (contradicts current Gate 8 reality)
- **Plan 08-04 deferred-items.md:** amount_display.dart frontmatter gap

## Self-Check: PASSED

- [x] `.planning/audit/coverage-baseline.txt` exists, 232 entries.
- [x] `.planning/audit/coverage-baseline.json` exists, valid JSON.
- [x] `.planning/audit/files-needing-tests.txt` exists, 67 entries.
- [x] `.planning/audit/files-needing-tests.json` exists, valid JSON.
- [x] `.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md` exists, 8 gate rows + failure-context appendix.
- [x] Commit `2f206ba` exists in `git log`.
- [x] Commit `bfe3786` exists in `git log`.
- [x] All 4 baseline artifact diffs match expected ranges.
- [x] Determinism re-run produced byte-identical `coverage-baseline.txt`.

---

*Phase: 08-re-audit-exit-verification*
*Plan: 06*
*Completed: 2026-04-28*
