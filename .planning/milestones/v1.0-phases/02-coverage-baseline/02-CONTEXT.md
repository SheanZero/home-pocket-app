# Phase 2: Coverage Baseline - Context

**Gathered:** 2026-04-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Snapshot pre-refactor per-file test coverage and produce the gate machinery that subsequent fix phases (3–6) and the Phase-8 re-audit consume.

**This phase delivers, in `.planning/audit/`:** `coverage-baseline.txt` + `coverage-baseline.json` (per-file %, machine-readable companion), `files-needing-tests.txt` + `files-needing-tests.json` (the <80% list — characterization-test target list for Phases 3–6).

**This phase delivers, in `scripts/`:** `coverage_gate.dart` — fix phases invoke it with a touched-files list to verify each file reaches ≥80% coverage. Hybrid invocation contract: `dart run scripts/coverage_gate.dart [<file>...] [--list <path>] [--threshold N] [--lcov <path>] [--json]`; default lcov path is `coverage/lcov_clean.info`; default threshold is 80; if neither positional args nor `--list` is supplied, falls back to `.planning/audit/files-needing-tests.txt`.

**This phase delivers, in `.github/workflows/audit.yml`:** the existing `coverage` job evolves — it now produces `lcov_clean.info` (via `coverde filter`, already globally activated in CI), and the `very_good_coverage@v2` step **flips to blocking** at Phase 2 close (threshold stays at 80). The `coverage_gate.dart` per-file step does NOT enter CI in this phase — it is added at Phase 6 close.

**Discovery only — no `lib/` files are modified during this phase.** Surface of change is `pubspec.yaml` (no new deps; `coverde` stays globally activated as it is today), `.github/workflows/audit.yml` (new step to produce `lcov_clean.info` + flip blocking), `scripts/coverage_gate.dart` (new), `.planning/audit/coverage-baseline.{txt,json}` (new), `.planning/audit/files-needing-tests.{txt,json}` (new).

**Project-level policy locked by this phase:** During Phases 3–6 (the cleanup runway), `main` is locked — only PRs originating from the cleanup plan merge. This is the conscious cost of flipping the global 80% gate to blocking immediately at Phase 2 close (current global coverage is ~48% raw; flipping the gate now means non-cleanup PRs cannot pass). No bypass label, no escape valve. Phase 6 close releases the lock.

</domain>

<decisions>
## Implementation Decisions

### Coverage Gate Invocation Contract (BASE-05)
- **D-01:** `scripts/coverage_gate.dart` accepts a hybrid input: positional CLI file paths AND/OR `--list <file>` pointing to a newline-delimited path list. When neither is supplied, falls back to `.planning/audit/files-needing-tests.txt`. This lets fix-phase plans pass a small, plan-scoped list directly (`dart run scripts/coverage_gate.dart lib/a.dart lib/b.dart`), CI scripts pass a manifest file, and ad-hoc local runs work with no args.
- **D-02:** Threshold is parameterized: `--threshold N`, default 80. Hardcoding was rejected to preserve a no-code-edit lever for Phase 8 (e.g., dial up to 85 once the baseline is clean). Default-80 keeps every existing call site identical to the requirements wording in CLAUDE.md and `.claude/rules/testing.md`.
- **D-03:** Coverage source: default `coverage/lcov_clean.info`, override via `--lcov <path>`. If the default path is missing the script exits with an actionable message (`run flutter test --coverage && coverde filter ...`). This avoids ambiguity with the raw `coverage/lcov.info` (which still contains generated-file noise).
- **D-04:** Output is dual-track: human-readable per-file table to stdout (`path | covered/total | % | PASS|FAIL`) + an optional `--json` flag that emits a structured object suitable for downstream consumers (a future `merge_findings` extension or `reaudit_diff`). Exit is non-zero whenever any supplied file falls below the threshold.

### CI Gate Staging
- **D-05:** `very_good_coverage@v2` global gate (`min_coverage: 80` against `lcov_clean.info`) flips to **blocking immediately at Phase 2 close**. Threshold is NOT stepped (no 50→60→...→80 ladder). The `audit.yml` `coverage` job today is `continue-on-error: true`; this phase removes that flag and produces `lcov_clean.info` upstream of the `very_good_coverage` step (so the action checks only non-generated source).
- **D-06:** `coverage_gate.dart` per-file gate does NOT enter CI during Phases 3–6. It is invoked locally / from the fix-phase verification flow. It enters `audit.yml` only after Phase 6 close (Phase 7 / Phase 8 CI tightening), and is blocking from the moment it is added.
- **D-07:** **Repo lock is the project-level contract that makes D-05 viable.** During Phases 3–6, `main` accepts only PRs originating from the cleanup plan (i.e., PRs implementing roadmap-scoped fix plans). Non-cleanup PRs wait until Phase 6 closes. No CI-side bypass label is added; the discipline lives in the project-level workflow, not in CI escape hatches. Planner is responsible for documenting this constraint when planning each fix phase. Phase 6 close lifts the lock.

### Baseline Refresh Policy
- **D-08:** `coverage-baseline.{txt,json}` and `files-needing-tests.{txt,json}` are **frozen at Phase 2** and **regenerated only at Phase 8** (re-audit). No mid-initiative refresh. The Phase 2 lists serve as the canonical "before" image; Phase 8's regenerated lists are the canonical "after" image; the diff is the empirical evidence that the cleanup raised coverage.
- **D-09:** Fix phases (3–6) consume the frozen `files-needing-tests.txt` indirectly: each fix-phase **plan** declares which `lib/` files it touches (its `touched-files`); the planner intersects that with the frozen `files-needing-tests.txt` to identify which files need characterization tests **before** the refactor. The fix-phase verification step then calls `coverage_gate.dart --files <touched-files> --threshold 80` against the post-refactor `lcov_clean.info` to prove ≥80% on every touched file. This decouples per-phase gating from the global baseline list and keeps the global list immutable.
- **D-10:** Entry order in both `files-needing-tests.txt` and `coverage-baseline.txt` is **path lexicographic ascending**. Deterministic, grep-friendly, diff-noise-minimal. Severity ordering (or coverage-asc ordering) was rejected because Phase 2 is concerned with coverage, not severity, and ordering by % introduces churn between runs.

### Artifact Format
- **D-11:** **Twin-artifact pattern**: every Phase 2 output ships as `.txt` (human) + `.json` (machine), mirroring the `issues.json` + `ISSUES.md` precedent locked in Phase 1 (D-09 / D-10).
  - `coverage-baseline.txt`: `path\tlines_covered/lines_total\tpercentage` per line.
  - `coverage-baseline.json`: array of `{file_path, lines_covered, lines_total, percentage, threshold_met}`; top-level metadata (`generated_at`, `flutter_test_command`, `lcov_source`, `threshold`, `total_files`, `files_below_threshold`).
  - `files-needing-tests.txt`: bare path per line (the planner reads this directly).
  - `files-needing-tests.json`: array of `{file_path, percentage, lines_below_threshold}`; same top-level metadata as above.
- **D-12:** `coverage-baseline.json` and `files-needing-tests.json` do **NOT** carry `issue_ids` (cross-link back to `issues.json`). Phase 2 stays decoupled from Phase 1's catalogue — coverage is a different lens than violation findings. If the fix-phase planner wants the cross-reference, it joins on `file_path` itself; this is a one-line operation against existing artifacts and does not require Phase 2 to take a hard dependency on `issues.json` shape.

### Claude's Discretion
- **lcov stripping mechanism**: `coverde filter` (already globally activated in CI via `dart pub global activate coverde 0.3.0+1`). The four exclusion patterns (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`) plus any other generated patterns the codebase reveals (e.g., `.drift.dart` if found) are passed as `coverde filter` args. Locally, the same command runs as a contributor convenience; no separate Dart implementation needed unless `coverde filter` falls short on a specific pattern.
- **Coverage-baseline regeneration script**: `scripts/coverage_baseline.dart` (or equivalent shell wrapper) parses `lcov_clean.info`, computes per-file %, writes the four artifacts. Lives next to `merge_findings.dart` and follows the same Dart-script-with-shell-wrapper pattern from Phase 1.
- **Test-suite sampling**: assume the existing 183-file test suite is stable enough to baseline once. If the first `flutter test --coverage` reveals flake (test failures non-deterministically across two consecutive runs), the response is to fix the flaky test rather than baseline through it — a flaky test contaminates the per-file %. Concrete flake handling (retry, quarantine) is deferred to a Phase 2.x plan if discovered.
- **`coverage/` directory under `.gitignore`**: keep current behavior (the `coverage/` artifacts are ephemeral CI/local outputs); only `.planning/audit/coverage-baseline.{txt,json}` and `.planning/audit/files-needing-tests.{txt,json}` are committed.
- **Phase 2 idempotency**: re-running the baseline pipeline against the same checkout produces byte-identical artifacts (thanks to lexicographic ordering, deterministic lcov format, and stable JSON key ordering). This is a quiet correctness invariant the Phase 8 re-baseline depends on.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Project scope and constraints
- `.planning/PROJECT.md` — Initiative scope, behavior-preservation constraint, what is explicitly out of scope
- `.planning/REQUIREMENTS.md` §BASE-01..BASE-06 — The 6 locked deliverables this phase must produce
- `.planning/ROADMAP.md` §"Phase 2: Coverage Baseline" — Goal, dependencies, success criteria

### Implementation guidance for this phase
- `.planning/research/SUMMARY.md` §"Phase 2: Coverage Baseline" — Pipeline shape, parallelism with Phase 1, "Flutter community standard, no additional research needed"
- `.planning/research/STACK.md` — Tool selection (coverde, very_good_coverage), version constraints
- `.planning/research/PITFALLS.md` — Eight pitfalls every fix phase must respect; the coverage gate must surface failures in line with these
- `.planning/research/ARCHITECTURE.md` — Five-component pipeline structure (Audit Engine → Issue Catalogue → Fix Phases → Doc Sweep → Re-Audit); Phase 2 lives at the seam between Audit Engine and Fix Phases

### Phase 1 contract (locked)
- `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — Specifically:
  - **D-04 (staged enablement)** — coverage gates extend the same staging contract; Phase 2 fills in the unspecified coverage timing
  - **D-09 / D-10 (dual audience: human + machine)** — coverage artifacts mirror the same `txt + json` twin-artifact pattern
  - **§"Layout under `.planning/audit/`"** — `coverage-baseline.txt` and `files-needing-tests.txt` were already pre-allocated to this directory; Phase 2 adds the `.json` companions

### Audit catalogue (Phase 1 output, Phase 2 read-only consumer)
- `.planning/audit/SCHEMA.md` — Finding-record schema; relevant for Phase 2 only at the "fix-phase planner joins on `file_path`" boundary (D-12)
- `.planning/audit/issues.json` — Phase 1 output. Phase 2 does not depend on it; the fix-phase planner uses `file_path` to join coverage and findings lazily

### Codebase ground-truth (current state)
- `.planning/codebase/TESTING.md` — 183 test files / 268 source files; mockito + mocktail mixed strategy; `AppDatabase.forTesting()` in-memory pattern; coverage requirement ≥80% per CLAUDE.md
- `.planning/codebase/STACK.md` — `flutter_test` (SDK), no `integration_test` package, no Patrol; what coverage tooling exists today
- `.planning/codebase/STRUCTURE.md` — 5-layer file layout; defines what counts as "source" for the per-file % calculation
- `.planning/codebase/CONVENTIONS.md` — `scripts/` precedent for the Dart + shell-wrapper pattern this phase reuses
- `.planning/codebase/CONCERNS.md` — Some fix-phase target files are listed here; Phase 2 itself does not consume this but the fix-phase planner does

### Project-wide rules
- `CLAUDE.md` §"Essential Commands" — Canonical `flutter test --coverage` invocation and the ≥80% wording
- `CLAUDE.md` §"Common Pitfalls" — Avoiding modifying generated files; Phase 2 must respect the same exclusion list when stripping `lcov.info`
- `.claude/rules/testing.md` — ≥80% as a project rule; Phase 2 mechanizes enforcement without changing the rule
- `analysis_options.yaml` — `analyzer.exclude` lists `**/*.g.dart` + `**/*.freezed.dart`; Phase 2 must mirror that exclusion list in `coverde filter` to keep the two consistent
- `pubspec.yaml` — `dev_dependencies` baseline; no new deps added in this phase (`coverde` stays globally activated as it is today)

### CI surface (existing, Phase 2 evolves)
- `.github/workflows/audit.yml` — Three jobs: `static-analysis`, `guardrails`, `coverage`. Phase 2 modifies the `coverage` job: (a) add a step to run `coverde filter` to produce `lcov_clean.info`; (b) remove `continue-on-error: true` on the `very_good_coverage@v2` step; (c) upload the four `.planning/audit/coverage-*` artifacts; (d) (deferred to Phase 7/8) wire `coverage_gate.dart` per-file step

### External tooling docs (verify versions during planning)
- pub.dev / GitHub: `coverde` (already pinned at `0.3.0+1` in CI line 29 of `audit.yml`) — `coverde filter` for lcov stripping, `coverde value` for percentage extraction
- GitHub: `VeryGoodOpenSource/very_good_coverage@v2` — `path`, `min_coverage`, `exclude` (already wired in `audit.yml` lines 100–109; `exclude` patterns must be kept in sync with `coverde filter` patterns to avoid double-stripping or missed strips)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/arb_to_csv.dart` — Establishes the Dart-as-script convention this phase extends. `coverage_baseline.dart` and `coverage_gate.dart` should follow the same module/entry-point shape (top-level `main(List<String> args)`, no extraneous library exports).
- `scripts/merge_findings.dart` — Phase 1 reference implementation of "Dart script that reads JSON shards and produces sorted/deduped output". `coverage_baseline.dart`'s lcov-to-JSON pass mirrors this; both share the "deterministic ordering for byte-identical reruns" invariant (D-12 idempotency).
- `coverage/lcov.info` — Already produced by recent local `flutter test --coverage` runs (~15.4k DA lines). Indicates the suite runs end-to-end today; Phase 2 can baseline against the existing run shape rather than rediscovering it.
- `.planning/audit/SCHEMA.md` — Drafting reference for the `coverage-baseline.json` schema doc. A short companion `.planning/audit/COVERAGE-SCHEMA.md` (or appended section in SCHEMA.md) keeps the artifact contract explicit for Phase 8.
- `coverde` global activation in `audit.yml` line 29 — Phase 2 can call `coverde filter` and `coverde value` from CI without adding any pubspec dep.

### Established Patterns
- **Dart script + shell wrapper**: Phase 1 standardized `scripts/audit_*.sh` wrapping `scripts/audit/*.dart`. Phase 2 follows the same pattern for any orchestration that benefits from shell composition (e.g., `scripts/build_coverage_baseline.sh` that runs `flutter test --coverage` → `coverde filter` → `dart run scripts/coverage_baseline.dart`).
- **Twin artifacts (txt + json)**: Phase 1 D-09/D-10 locked this for `issues.json` + `ISSUES.md`. Phase 2 D-11 inherits it.
- **Stable IDs / deterministic ordering for re-audit reproducibility**: Phase 1 D-06/D-07 codified this for finding IDs. Phase 2 mirrors it for coverage artifacts via lexicographic file path ordering and stable JSON key ordering. Phase 8 byte-equality compares are the payoff.
- **Generated-file exclusion list**: `analysis_options.yaml` `analyzer.exclude:` already enumerates `**/*.g.dart`, `**/*.freezed.dart`. Phase 2 reuses the same list for `coverde filter`. The `audit.yml` `very_good_coverage` step also currently lists `**/*.g.dart`, `**/*.freezed.dart`, `**/*.mocks.dart`, `lib/generated/**` — this list is the source of truth.
- **Staged blocking flips by fix-phase exit (Phase 1 D-04)**: Phase 2 D-05 / D-06 extend this. The `audit.yml` comments (`continue-on-error: true   # Phase X exit gate flips this blocking`) are the in-tree marker convention.

### Integration Points
- `.github/workflows/audit.yml` `coverage` job — Phase 2 modifies this job. Needs an upstream step: `dart pub global activate coverde 0.3.0+1` (already present line 29 in `static-analysis` job; needs to be available in `coverage` job too — either repeat the activation or factor into a setup composite action). Actual additions: a `coverde filter` step before `very_good_coverage`; remove `continue-on-error` on `very_good_coverage`; upload `.planning/audit/coverage-*` artifacts.
- `scripts/` directory — Phase 2 adds: `coverage_baseline.dart` (lcov-to-{txt,json} converter), `coverage_gate.dart` (the gate per BASE-05), and any shell wrapper if the planner deems it useful (`scripts/build_coverage_baseline.sh`).
- `.planning/audit/` — Phase 2 adds 4 artifacts: `coverage-baseline.txt`, `coverage-baseline.json`, `files-needing-tests.txt`, `files-needing-tests.json`. Pre-allocated by Phase 1 directory layout.
- **Repo-lock policy** — A non-CI artifact: planner must capture this constraint in the Phase 3 / 4 / 5 / 6 plans (e.g., as a "Repo lock note" in each fix-phase plan's preamble). This is how D-07 lives outside CI.

</code_context>

<specifics>
## Specific Ideas

- **Repo-lock window**: From the moment Phase 2 closes (very_good_coverage flipped blocking) until Phase 6 closes (last fix phase). During this window, only PRs implementing the cleanup roadmap pass CI. The user is willing to pay this cost to enforce test-first discipline; the planner needs to surface this constraint in every fix-phase plan so contributors are not surprised. This may translate to a CONTRIBUTING.md or a top-of-PR-template note during the cleanup window — captured here as a discretionary planning detail, not a hard requirement on Phase 2 itself.
- **Threshold parameterization headroom**: D-02 deliberately preserves `--threshold N` as a knob even though current rule is "always 80". Phase 8 may want to dial up to 85 for a tighter post-cleanup ceiling, or fix-phase-specific plans may want to assert a stricter local threshold for hot-spot files. The default-80 keeps every existing call site identical to current usage.
- **Idempotent reruns**: A quiet correctness invariant — re-running `scripts/coverage_baseline.dart` against the same `lcov_clean.info` produces byte-identical artifacts. Phase 8's re-audit byte-compares the new baseline against the Phase-2 baseline to prove the cleanup raised coverage; idempotency is what makes that diff meaningful.
- **Phase 2 / Phase 1 parallelism**: Roadmap calls Phase 1 and Phase 2 parallelizable. Practically, since `audit.yml` already exists with a pre-stubbed `coverage` job (created during Phase 1), Phase 2 evolves rather than greenfields it. The Phase 2 / Phase 3 boundary (where fix work begins) is where serialization tightens; before that, `audit.yml` is co-edited by Phase 1 and Phase 2.
- **Phase 8 contract that Phase 2 must respect**: Phase 8's re-audit re-runs the same `coverage_baseline.dart` invocation. The script CLI surface, output schema, and ordering rules locked in Phase 2 are the Phase 8 contract — they must not regress. This is the symmetric Phase 1 / Phase 8 contract for `merge_findings.dart` (D-07 from Phase 1) extended to coverage.

</specifics>

<deferred>
## Deferred Ideas

- **`coverage_gate.dart` enters CI as a blocking step** — explicitly Phase 7 / Phase 8 territory (D-06). Not implemented in Phase 2.
- **Coverage threshold dialed up past 80** — Phase 8 may consider this once the baseline is clean. `--threshold` is the lever; no Phase 2 work needed.
- **Cross-link coverage artifacts to `issues.json` finding IDs** — explicitly rejected (D-12). If the fix-phase planner finds it useful later, it can lazily join on `file_path` without Phase 2 changes.
- **Flake quarantine / test-retry strategy** — deferred to a Phase 2.x plan if the first baseline run reveals flake. Phase 2 assumes test stability based on the existing 183-file suite passing today.
- **Per-feature or per-layer aggregate coverage report** — interesting but out of scope; the per-file list satisfies BASE-03 / BASE-04. A future enhancement could roll up by feature (Survival Ledger, Sync, etc.) but is not a cleanup-initiative deliverable.
- **Pre-commit hook for local coverage check** — considered, declined (consistent with Phase 1 D-04 declining a pre-commit hook for audit). Local discipline is a contributor concern, not a CI surface change.
- **Migrating `coverde` from globally-activated CLI to a pubspec dev_dependency** — declined for now to avoid pubspec churn during the cleanup; revisit post-Phase-8 if multiple call sites would benefit.
- **Test-suite re-sampling cadence** — declined; Phase 2 baseline runs once at Phase 2 close and once at Phase 8. Mid-initiative refreshes were rejected (D-08) to keep the "before" image immutable.

</deferred>

---

*Phase: 02-coverage-baseline*
*Context gathered: 2026-04-25*
