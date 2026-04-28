# Phase 8: Re-Audit + Exit Verification - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Terminal verification phase for the Codebase Cleanup Initiative. Phase 8 re-runs the full hybrid audit pipeline (4 automated tooling scanners + 4 AI semantic-scan agents) on the post-cleanup `lib/` tree, produces a separate `.planning/audit/re-audit/issues.json`, and uses `scripts/reaudit_diff.dart` to prove zero open findings against the Phase-1 catalogue. All eight exit gates must pass simultaneously, the four CI guardrails must be locked as permanent (config + docs), and a human smoke test must confirm behavior is byte-identical to the pre-refactor user experience.

**In scope:**
- Implement `scripts/reaudit_diff.dart` (Phase 1 left a stub).
- Re-run `/gsd-audit-semantic` end-to-end with the locked agent prompts under `.claude/commands/audit/`.
- Produce `.planning/audit/re-audit/` artifacts (`issues.json`, `ISSUES.md`, `shards/`, `agent-shards/`, `REAUDIT-DIFF.md`).
- Replace `phase6-touched-files.txt` in `audit.yml` with a new `cleanup-touched-files.txt` (Phase 3-6 union).
- Lock the 4 CI guardrails permanent: code-side comments + remove residual `continue-on-error` / report-only + lift coverage job's `if: pull_request` so `push to main` runs the same gate.
- Regenerate the coverage baseline (`coverage-baseline.txt` / `.json`) per REPO-LOCK-POLICY.md lifecycle row "Phase 8".
- Author `08-SMOKE-TEST.md` golden-path checklist + add focused widget golden tests (`test/golden/`) for high-risk amount/report/form surfaces.
- Append `## Update YYYY-MM-DD: Re-audit Outcome` to `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` with re-audit delta + smoke-test result + cleanup-touched-files.txt path.

**Out of scope:**
- New feature work, behavior changes, schema changes, security architecture changes (per PROJECT.md "Out of Scope").
- Rewriting Phase 1-7 decisions or the locked agent prompts.
- Configuring GitHub branch protection (left as a documented manual admin step in ADR-011, not a Phase 8 deliverable).
- Removing the historical `phase6-touched-files.txt` (kept as audit trail; superseded by `cleanup-touched-files.txt` in `audit.yml`).
- Capturing a fresh "pre-refactor" reference — Phases 3-6 are already on main, so byte-identical is verified against current behavior + retained widget golden tests as forward-locked baseline.

</domain>

<decisions>
## Implementation Decisions

### `reaudit_diff.dart` Output Contract & Drift Handling

- **D-01:** `scripts/reaudit_diff.dart` produces a classified report with three integer counters — `resolved`, `regression`, `new` — and exits 1 if **any** of `regression` or `new` is non-zero, or if any open finding remains in the resolved-set baseline. Exit 0 only when `regression == 0 && new == 0 && open_in_baseline == 0`. Output is emitted to (a) stdout (compact summary), (b) `.planning/audit/re-audit/REAUDIT-DIFF.json` (machine-readable for CI consumption), and (c) `.planning/audit/re-audit/REAUDIT-DIFF.md` (human-readable per-bucket finding list grouped severity-then-category, per Phase 1 D-10/D-11 format).
  - **Why:** Strict reading of EXIT-02 ("exit 0 only when there are zero open findings"); classified counters keep CI / human triage usable when something does fail. Aligns with Phase 1 D-09 dual-audience format.
  - **How to apply:** `reaudit_diff.dart` is the gate script for Phase 8 close. Plan implementing it must include unit-style tests in `test/scripts/` covering the three exit-1 branches (regression > 0, new > 0, open-in-baseline > 0) and the exit-0 happy path.

- **D-02:** Baseline catalogue for the diff is the live repository's `.planning/audit/issues.json` at Phase 8 start (currently 50 findings, all `status: closed`). The diff script reads this file as the authoritative ID universe; new entries that Phase 6 added (D-02 stable rows for re-scanned LOW findings) are part of the baseline because they are committed to the catalogue.
  - **Why:** Single source of truth, no extra snapshot artifact to maintain. Phase 6 D-02 explicitly committed mid-cleanup discoveries into the catalogue with `closed_in_phase` lifecycle fields, so they are legitimate Phase-1-style baseline rows now.
  - **How to apply:** `reaudit_diff.dart` reads `.planning/audit/issues.json` directly. Match key per Phase 1 D-07: `(category, normalized_file_path, description)`. Honor Phase 1 D-08 split/merge fields (`split_from`, `closed_as_duplicate_of`) when interpreting the baseline ID set.

### AI Semantic Scan Re-run Scope

- **D-03:** The 4 AI semantic-scan agents (`drift_unused_column`, `layer_violation`, `semantic_duplication`, `transitive_import` under `.claude/commands/audit/`) are **all re-run** end-to-end as part of Phase 8 with their Phase 1 locked prompts. Output writes to `.planning/audit/re-audit/agent-shards/<dimension>.json`, kept disjoint from the original `.planning/audit/agent-shards/`.
  - **Why:** ROADMAP §Phase 8 wording is "full audit pipeline" — interpretation is the literal one. Agents catch indirect / semantic / transitive violations no automated scanner can. Risk of new patterns from Phase 4-7 commits (Wave 0 characterization tests, presentation refactor, ADR-011 doc edits) makes a full re-run protective rather than excessive.
  - **How to apply:** Plan invokes `/gsd-audit-semantic` once with an output-directory override pointing at `.planning/audit/re-audit/agent-shards/`. The Phase-1 `merge_findings.dart` is then re-run against `.planning/audit/re-audit/shards/` ∪ `.planning/audit/re-audit/agent-shards/` to produce `.planning/audit/re-audit/issues.json`. Stable IDs in the re-audit catalogue are produced by the same merger logic; matching to baseline is `reaudit_diff`'s job, not the merger's.

### Coverage Gate Scope + Guardrails Permanence

- **D-04:** The per-file coverage gate in `.github/workflows/audit.yml` switches its input list from `.planning/audit/phase6-touched-files.txt` (19 files) to a new `.planning/audit/cleanup-touched-files.txt` (union of all `lib/` files modified across Phases 3-6 plan manifests, expected ~100-200 entries). Phase 8 produces the new file deterministically by parsing the `files_modified` frontmatter / git diff of each Phase 3-6 plan commit.
  - **Why:** PROJECT.md mandates "≥80% test coverage on every file the refactor touches" — the union is the literal scope. Keeping `phase6-touched-files.txt` as the gate input would let regressions slip through any Phase 3-5-touched file that isn't in the Phase 6 list.
  - **How to apply:** Phase 8 plan creates `cleanup-touched-files.txt` (deterministic generator script in `scripts/` so it is reproducible), updates `audit.yml`'s `coverage_gate.dart --list` argument to point at it, keeps `phase6-touched-files.txt` on disk as a historical artifact (no rename, no delete) but removes its `audit.yml` reference.

- **D-05:** EXIT-05 "permanent" applies via three structural changes in addition to documentation:
  1. `.github/workflows/audit.yml` gets a top-of-file warning comment block: `# ⚠️ Permanent gate — do not weaken without ADR amendment. See docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md.`
  2. Audit `audit.yml` for any residual `continue-on-error: true` / report-only / WARN-only steps and remove them. Each of the four guardrails (`import_guard`, `riverpod_lint`/`custom_lint`, `coverde` per-file ≥80%, `sqlite3_flutter_libs` reject) must be a hard `run:` step with no soft-fail flag.
  3. The `coverage` job currently has `if: ${{ github.event_name == 'pull_request' }}`. Remove it so coverage gates run on `push: branches: [main]` too. Ensures direct-to-main commits cannot bypass the 80% gate.
  4. **Documentation:** `.planning/audit/REPO-LOCK-POLICY.md` gets a new closing section "## Phase 8 Close — Permanent Gates" recording (a) all four guardrails are now blocking on every PR + push to main, (b) the lock window is closed, and (c) ADR-011 amendment is the cross-reference.
  - **Why:** EXIT-05 says "failing them blocks future PRs" — without lifting `if: pull_request` on coverage, a malicious or careless direct-push to main could bypass the bar. Without the warning comment, future contributors editing `audit.yml` won't know which lines are load-bearing.
  - **How to apply:** Phase 8 plan includes a "guardrails permanence" task with four sub-steps matching the four points above. Branch-protection-rule configuration is **not** automated by Phase 8 (left as a manual admin step documented in ADR-011 amendment).

### Smoke Test Scope and Artifact

- **D-06:** Phase 8 produces `08-SMOKE-TEST.md` in the phase directory containing a golden-path checklist covering the user-facing flows that touch refactored code: (a) transaction create / edit / delete on both ledgers, (b) ledger switch (Survival ↔ Soul), (c) monthly report screen with currency formatting in JPY / CNY / USD, (d) settings: backup export + import, (e) family sync push + pull, (f) voice input, (g) language switch (ja → zh → en) with all 3 locales' amount + date formatting verified, (h) ARB-driven UI text spot-check on screens touched in Phase 5. Each item is a manual checkbox the user marks off after running on the latest local build. The user fills the checklist; Phase 8 cannot close until every item is marked done. Discrepancies are blocking findings recorded as new issues.
  - **Why:** PROJECT.md "strict pure refactor — every refactored path must yield identical observable behavior" is the project's load-bearing constraint. A checklist makes the verification reproducible and traceable in ADR-011.
  - **How to apply:** Plan creates `08-SMOKE-TEST.md` with the 8 sections above. Phase 8 close requires the file to be committed with all checkboxes ticked.

- **D-07:** A small set of widget golden tests is added to `test/golden/` covering the highest-regression-risk surfaces (touched in Phases 3-5 monetary / formatter / ARB changes): `amount_display.dart` rendering JPY/CNY/USD, monthly report summary card, transaction form with currency-formatted amount preview, soul fullness card with localized labels. Goldens are generated against the **current (post-cleanup) tree** and used as forward-locked regression baselines — they cannot prove byte-identical to pre-refactor (Phases 3-6 already on main), but they protect against any future drift.
  - **Why:** Phase 5 introduced `AppTextStyles.amountLarge/amountMedium/amountSmall` with `FontFeature.tabularFigures()` enforcement (D-17..D-20 in 05-CONTEXT). A widget golden lock prevents accidental rollback of those styles. Same logic for `FormatterService` UI surfaces.
  - **How to apply:** Plan adds 5-8 widget golden tests + necessary helpers under `test/golden/`. Use `test/helpers/test_localizations.dart` (Phase 5 reusable asset) for `S.of(context)` access. Coverage from these tests counts toward the cleanup-touched-files.txt 80% gate (per D-04).

### ADR-011 Amendment

- **D-08:** Phase 8 close appends `## Update YYYY-MM-DD: Re-audit Outcome` to `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` per Phase 7 D-06 (ADR append-only rule) and `.claude/rules/arch.md` line 173. The appended section records:
  1. **Re-audit delta** — `resolved`/`regression`/`new` counts from `REAUDIT-DIFF.json`, plus a one-line summary linking `.planning/audit/issues.json` ↔ `.planning/audit/re-audit/issues.json`.
  2. **Smoke test outcome** — link to `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` and one-line status (PASS / DISCREPANCIES_FOUND).
  3. **Coverage gate change** — note that `audit.yml` now reads `cleanup-touched-files.txt` (path), and that `coverage-baseline.txt` was regenerated per REPO-LOCK-POLICY lifecycle.
  4. **Guardrails permanence** — confirm the four code-side changes from D-05 landed (warning comment, no soft-fail flags, `if: pull_request` lifted, REPO-LOCK-POLICY §"Phase 8 Close" added).
  - **Why:** ADR append-only is the locked project convention (Phase 7 D-06). ADR-011 was created in Phase 7 anticipating Phase 8 outcomes; closing it without the re-audit delta would leave the cleanup story incomplete.
  - **How to apply:** Plan implementing this is the **last** plan in Phase 8 (after re-audit + smoke + coverage regeneration), so the appended section can cite real numbers.

### Locked Carry-Forward (Phase 1 + Phase 7 + REPO-LOCK-POLICY)

These are **not** re-decided here — they constrain Phase 8 directly:
- **Phase 1 D-01:** AI semantic scan agents have locked prompts under `.claude/commands/audit/`. Phase 8 invocation is the same `/gsd-audit-semantic` slash command with the same 4 prompt files (`drift_unused_column.md`, `layer_violation.md`, `semantic_duplication.md`, `transitive_import.md`) — re-confirmed by D-03.
- **Phase 1 D-04:** "End of Phase 8: all gates remain blocking permanently." → Implemented by D-05.
- **Phase 1 D-06 / D-07:** Stable ID matching contract `(category, normalized_file_path, description)` for `reaudit_diff` — wired by D-02.
- **Phase 1 D-08:** Splits keep original ID open + add `split_from`; merges close child IDs with `closed_as_duplicate_of` — `reaudit_diff` honors these schema fields when interpreting the baseline.
- **Phase 7 D-06:** ADR append-only — Phase 8 follows for the ADR-011 amendment per D-08.
- **REPO-LOCK-POLICY.md lifecycle row "Phase 8":** "Coverage baseline regenerated; gate stays blocking permanently." → Coverage baseline regen is a Phase 8 plan task; gate-permanent-blocking is D-05.

### Claude's Discretion
- Plan boundary / wave numbering inside Phase 8 (e.g., whether `reaudit_diff.dart` impl is its own plan or shares a plan with the re-audit dry-run).
- Exact format of `cleanup-touched-files.txt` generator script (one-shot Bash + git log vs Dart subprocess) — pick whatever is most consistent with existing Phase 1 `scripts/`.
- Specific list of widget golden tests (5-8 range from D-07; planner picks the highest-impact subset based on Phase 3-5 plan diffs).
- Wording / structure of the ADR-011 appended `## Update` section, provided D-08's four required content items appear.
- Whether `08-SMOKE-TEST.md` checklist items are flat or nested by area; user fills them either way.
- Naming of any helper script (e.g., `scripts/build_cleanup_touched_files.sh`) — match the `audit_*.sh` precedent if added.
- Disposition of historical `phase6-touched-files.txt`: keep on disk (committed) but no longer referenced by `audit.yml`; planner may add a one-line header comment "Superseded by cleanup-touched-files.txt in Phase 8" but must NOT delete or rename.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Requirements
- `.planning/ROADMAP.md` §"Phase 8: Re-Audit + Exit Verification" — Phase goal + 4 success criteria (zero open findings, 8 simultaneous exit gates, 4 permanent guardrails, smoke test confirmation).
- `.planning/REQUIREMENTS.md` §EXIT-01..EXIT-05 — Locked Phase 8 deliverables: re-audit issues.json produced, reaudit_diff exits 0, ≥80% global coverage, 8 simultaneous exit gates, 4 permanent CI guardrails.
- `.planning/PROJECT.md` — Pure-refactor constraint, behavior preservation, "re-running the audit at the end finds zero violations" core value, out-of-scope boundaries.
- `.planning/STATE.md` — Project state ledger; current position is Phase 8 ready-to-plan.
- `.planning/SUMMARY.md` — "Eight gates" enumeration referenced by EXIT-04.

### Audit Catalogue and Schema (re-audit critical path)
- `.planning/audit/issues.json` — Baseline catalogue. Phase 8 reads this directly per D-02; 50 findings, all `status: closed`. The ID universe `reaudit_diff` matches against.
- `.planning/audit/ISSUES.md` — Human-readable companion to issues.json; format reference for `REAUDIT-DIFF.md`.
- `.planning/audit/SCHEMA.md` — Locked finding schema. `reaudit_diff` must respect required fields, `tool_source` enum, `confidence` enum, split/merge convention (Phase 1 D-08).
- `.planning/audit/coverage-baseline.txt` / `.planning/audit/coverage-baseline.json` — Frozen Phase 2 baseline, regenerated by Phase 8 per REPO-LOCK-POLICY.
- `.planning/audit/files-needing-tests.txt` / `.json` — Frozen Phase 2 list; expected to shrink to near-empty post-cleanup; regen alongside coverage baseline.
- `.planning/audit/phase6-touched-files.txt` — Current per-file gate input; superseded by `cleanup-touched-files.txt` per D-04 (kept on disk as historical artifact).
- `.planning/audit/REPO-LOCK-POLICY.md` — Cleanup runway lock policy; Phase 8 close ceremony point. Amendment per D-05 point 4.
- `.planning/audit/shards/` and `.planning/audit/agent-shards/` — Original Phase 1 raw shards; format reference for `re-audit/shards/` and `re-audit/agent-shards/`.

### Re-audit Pipeline Sources
- `scripts/reaudit_diff.dart` — Phase 1 stub (line 8: "Phase 8 implementation pending"); full implementation is the Phase 8 deliverable per D-01.
- `scripts/merge_findings.dart` — Phase 1 merger; reused unchanged by Phase 8 against re-audit shard set.
- `scripts/audit_layer.sh`, `scripts/audit_dead_code.sh`, `scripts/audit_providers.sh`, `scripts/audit_duplication.sh` — 4 automated scanners; reused unchanged by Phase 8.
- `scripts/audit/finding.dart` — Schema mirror; do NOT modify in Phase 8.
- `scripts/coverage_baseline.dart` and `scripts/coverage_gate.dart` — Phase 2 scripts; reused. `coverage_gate.dart`'s `--list` argument switches to `cleanup-touched-files.txt` per D-04.
- `.claude/commands/audit/drift_unused_column.md`, `layer_violation.md`, `semantic_duplication.md`, `transitive_import.md` — 4 locked AI agent prompts (Phase 1 D-01); re-invoked verbatim by D-03.

### Phase 1 Pipeline Decisions (locked carry-forward)
- `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — Stable finding IDs (D-06/D-07), splits/merges (D-08), staged-then-permanent gate enablement (D-04), AI agent invocation contract (D-01).

### Phase 7 Documentation Decisions (locked carry-forward)
- `.planning/phases/07-documentation-sweep/07-CONTEXT.md` — ADR append-only convention (D-06); Phase 8 follows it for the ADR-011 amendment per D-08.
- `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` — Created by Phase 7 (Plan 07-05); Phase 8 appends `## Update YYYY-MM-DD: Re-audit Outcome` per D-08.
- `.claude/rules/arch.md` — ADR append-only documentation rule, line 173.

### CI and Project-wide Rules
- `.github/workflows/audit.yml` — Lines to modify per D-04 (`coverage_gate.dart --list` arg) and D-05 (warning comment, residual continue-on-error sweep, lift `if: pull_request` on coverage job).
- `analysis_options.yaml` — `import_guard` plugin registration; do NOT modify.
- `pubspec.yaml` — `intl: 0.20.2` exact pin (Pitfall #5), `riverpod_lint ^2.6.4` (Pitfall #10); do NOT modify.
- `CLAUDE.md` — Project instructions; "Common Pitfalls" annotations from Phase 7 D-? must remain in sync with re-audit findings; do NOT modify in Phase 8.

### Codebase Ground Truth
- `.planning/codebase/CONCERNS.md`, `CONVENTIONS.md`, `STRUCTURE.md`, `TESTING.md` — Pre-cleanup map; AI agents consume per Phase 1 D-02.
- `test/architecture/domain_import_rules_test.dart` and `provider_graph_hygiene_test.dart` — Architecture tests from Phases 3-4; reused as-is.
- `test/helpers/test_localizations.dart` — Phase 5 reusable helper for widget golden tests under D-07.

### Smoke Test Targets (D-06 surfaces)
- `lib/features/accounting/` — transaction create / edit / delete; ledger switch.
- `lib/features/home/` — soul fullness card, ledger summary cards.
- `lib/features/analytics/` — monthly report; touched in Phase 5 D-04 (FormatterService + AppTextStyles enforcement).
- `lib/features/settings/` — backup export / import.
- `lib/features/family_sync/` — sync push + pull (Phase 6 touched files).
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — voice input.
- `lib/features/accounting/presentation/widgets/amount_display.dart` and `lib/core/theme/app_text_styles.dart` — Phase 5 amount-display enforcement.
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — locale switch verification.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/merge_findings.dart`: Phase 1 merger emits `issues.json` with stable IDs from arbitrary `shards/` + `agent-shards/`. Phase 8 invokes it pointing at `.planning/audit/re-audit/shards/` + `re-audit/agent-shards/` to produce `re-audit/issues.json`. No code change required.
- `scripts/coverage_gate.dart`: Per-file ≥80% gate. Phase 8 changes its `--list` argument from `phase6-touched-files.txt` to `cleanup-touched-files.txt`. Script unchanged.
- `scripts/coverage_baseline.dart`: Already produces `coverage-baseline.txt` + `.json` + `files-needing-tests.txt` + `.json`. Phase 8 re-runs it after `flutter test --coverage` to regenerate the baseline post-cleanup.
- `scripts/audit_*.sh` + `scripts/audit/<dimension>.dart`: 4 automated scanners. Phase 8 invokes them with output redirected to `.planning/audit/re-audit/shards/`.
- `.claude/commands/audit/*.md`: 4 locked AI agent prompts. `/gsd-audit-semantic` invocation by Phase 8 produces `re-audit/agent-shards/`.
- `test/helpers/test_localizations.dart`: Wraps widgets with `S.of(context)` access; reused by D-07 widget golden tests.
- `test/architecture/`: Existing arch tests (`domain_import_rules_test.dart`, `provider_graph_hygiene_test.dart`); Phase 8 may add a thin assertion that `reaudit_diff.dart` exits 0 against current catalogue (smoke test of the gate itself).

### Established Patterns
- Stable finding IDs (Phase 1 D-06/D-07): never reissued; `status` lifecycle is `open` → `closed` with `closed_in_phase` + `closed_commit`. Phase 8 honors when interpreting `issues.json` as baseline.
- Audit shard layout: `<root>/shards/<tool>.json` for tooling, `<root>/agent-shards/<dimension>.json` for AI. Phase 8's re-audit mirrors this layout under `<root>/re-audit/`.
- Coverage exclusions: `**/*.g.dart`, `**/*.freezed.dart`, `**/*.mocks.dart`, `lib/generated/**` — already encoded in `audit.yml` `coverde filter` step. Phase 8 inherits.
- ADR convention (`.claude/rules/arch.md`): ADRs are append-only after `✅ 已接受`. Phase 8's amendment to ADR-011 is a `## Update YYYY-MM-DD:` block, not a body rewrite.
- `gsd-sdk query commit`: Project commit helper used across phases; Phase 8 plans use it for atomic plan commits per the cleanup-runway pattern.
- `lib/`-clean commits convention (Phase 7 D-08): Phase 8 similarly should produce mostly `.planning/` + `scripts/` + `.github/workflows/audit.yml` + `docs/arch/03-adr/ADR-011_*.md` + `test/golden/` commits. The widget golden tests (D-07) are the only `test/` additions.

### Integration Points
- `.github/workflows/audit.yml` (lines ~106 + ~118 + ~94 area): `coverage_gate.dart --list` argument; coverage job's `if: pull_request`; top-of-file warning comment block; sweep for residual `continue-on-error` (none currently in main file but verify post-Phase 6 Wave 0 commits did not regress this).
- `.planning/audit/issues.json`: Read-only input to `reaudit_diff`. Do NOT modify in Phase 8 (it is the baseline artifact).
- `.planning/audit/re-audit/`: New directory created by Phase 8. Holds `issues.json`, `ISSUES.md`, `REAUDIT-DIFF.json`, `REAUDIT-DIFF.md`, `shards/`, `agent-shards/`.
- `.planning/audit/cleanup-touched-files.txt`: New artifact created by Phase 8 from Phase 3-6 plan manifests / git diffs.
- `.planning/audit/REPO-LOCK-POLICY.md`: Append a "## Phase 8 Close — Permanent Gates" section.
- `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md`: Append `## Update YYYY-MM-DD: Re-audit Outcome`. No body edit.
- `test/golden/`: New directory; widget golden tests per D-07.
- `08-SMOKE-TEST.md` in this phase directory: Created by Phase 8; user-filled checklist per D-06.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose strict-exit (D-01 option 2: "分类报告 + 严格 exit") over both zero-tolerance silent-fail and triage-relaxed exit. Planner should ensure `reaudit_diff.dart` produces all three counters even when exit-1, so the human reading CI logs can immediately see whether the failure is regression vs new vs leftover open-baseline.
- User explicitly chose to re-run all 4 AI agents (D-03 option 1) over only running automated scanners or pre-validating prompt drift. Plan should not introduce a "skip AI scan if prompt diff is empty" optimization — full re-run is the locked contract.
- User explicitly chose Phase 3-6 union for cleanup-touched-files.txt (D-04 option 1) over keeping `phase6-touched-files.txt` or expanding to all of `lib/`. The union list is the literal interpretation of PROJECT.md "every file the refactor touches" and aligns with the per-plan `files_modified` discipline that Phases 3-6 already followed.
- User explicitly chose code-side guardrails permanence (D-05 option 2) over docs-only. The lift of `if: pull_request` on the coverage job is the load-bearing change here — without it, direct-to-main commits could bypass the 80% gate.
- User explicitly chose checklist + widget goldens (D-06+D-07 option 2) over checklist-only. Goldens cannot prove byte-identical to pre-refactor (Phases 3-6 already on main), but they lock the post-cleanup baseline forward — which the Cleanup Initiative needs anyway as it transitions to feature work.
- User explicitly chose to amend ADR-011 with a `## Update YYYY-MM-DD: Re-audit Outcome` section (D-08) over leaving ADR-011 as Phase 7 wrote it. This makes ADR-011 the single canonical "what the cleanup achieved" document.

</specifics>

<deferred>
## Deferred Ideas

- **GitHub branch-protection rule configuration** — Phase 8 documents the recommended required-status-checks setup in ADR-011's amendment but does not configure them programmatically. Repo admin (user) does this manually; Phase 8 cannot edit GitHub platform settings.
- **markdown-link-check in CI** — Phase 7 deferred this; Phase 8 inherits the deferral. Filed in ADR-011 §"Out of Scope / Deferred" by Phase 7. Out of cleanup initiative scope; reconsider during a future tooling milestone.
- **Module numbering drift D3** (Phase 7 D-02) — pre-existing MOD-001/002/etc. heading inconsistency. Tracked in ADR-011 §"Out of Scope / Deferred"; lifted to FUTURE-DOC backlog after the initiative.
- **Pre-refactor visual reference capture** — discussed during D-07 but unactionable: Phases 3-6 are already on main, so "pre-refactor" no longer exists as a runnable build. Goldens lock the post-cleanup state forward instead.
- **FUTURE-ARCH-01..04, FUTURE-TOOL-01..02** (REQUIREMENTS.md v2) — explicitly out of cleanup initiative scope; recorded for the next milestone.

</deferred>

---

*Phase: 08-re-audit-exit-verification*
*Context gathered: 2026-04-28*
