# Phase 1: Audit Pipeline + Tooling Setup - Context

**Gathered:** 2026-04-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up the hybrid audit pipeline (automated linters + AI-agent semantic scan), produce `.planning/audit/issues.json` (machine-readable, stable IDs, severity-classified) and the human-readable `.planning/audit/ISSUES.md`, and turn on the two non-controversial CI guardrails (`sqlite3_flutter_libs` reject, `build_runner` stale-diff). The findings catalogue produced here is the definition of "done" for every subsequent fix phase.

**Discovery only — no files under `lib/` are modified during this phase.** Tooling registration in `pubspec.yaml`, `analysis_options.yaml`, `scripts/`, `.github/workflows/`, `.planning/audit/`, and the new project-local slash command directory is the entire surface of change.

</domain>

<decisions>
## Implementation Decisions

### AI-Agent Semantic Scan (AUDIT-07)
- **D-01:** Invocation is a project-local GSD slash command `/gsd-audit-semantic` that spawns four parallel subagents — one per scan dimension: (a) misplaced `features/*/use_cases/`, (b) semantic duplication / parallel implementations, (c) indirect layer violations via type aliases or transitive imports, (d) Drift unused-column detection. Each agent has a locked prompt file under `.claude/commands/audit/` (or equivalent project-local path) so prompts are version-controlled and Phase 8 re-runs the same exact contract.
- **D-02:** Agents consume codebase maps (`.planning/codebase/CONCERNS.md` + `STRUCTURE.md` + `CONVENTIONS.md`) for context plus a pre-computed file list scoped to that agent's dimension (e.g., the layer-violation agent gets all files under `lib/features/*/use_cases/` + Domain files via Glob). Token-efficient and deterministic between Phase 1 and Phase 8 runs.
- **D-03:** Each scanner (4 tooling + 4 AI agents = 8 total) writes its own JSON shard to `.planning/audit/shards/<tool>.json`. `scripts/merge_findings.dart` reads all shards, dedupes overlapping findings (same `file_path` + `line_start` + `category`), assigns stable IDs, sorts by severity-then-category, writes `issues.json`. Each finding records `tool_source` so dedupe decisions are auditable.

### CI Gate Enforcement Timing
- **D-04:** Staged enablement aligned to fix-phase exit gates. Phase 1 ships every gate in `report-only` mode (warnings logged in CI, never blocks). Each gate flips to blocking when its corresponding fix phase closes:
  - End of Phase 1: `sqlite3_flutter_libs` reject + `build_runner` stale-diff become **blocking** (no findings to clear; safe immediately).
  - End of Phase 3: `import_guard` becomes **blocking**.
  - End of Phase 4: `riverpod_lint` / `custom_lint` becomes **blocking**.
  - End of Phase 5: i18n / hardcoded-CJK / theme-token checks become **blocking**.
  - End of Phase 6: `dart_code_linter` (`check-unused-code`, `check-unused-files`) + `coverde` per-file ≥80% become **blocking**.
  - End of Phase 8: all gates remain blocking permanently.
- **D-05:** CI provider: GitHub Actions. `.github/workflows/audit.yml` runs on every PR + push to `main`. Repo currently has no `.github/workflows/` directory — this initiative is greenfield for CI.

### Stable Finding ID Scheme (re-audit critical path)
- **D-06:** ID format = category prefix + zero-padded 3-digit sequence:
  - `LV-NNN` Layer Violations
  - `PH-NNN` Provider Hygiene
  - `DC-NNN` Dead Code
  - `RD-NNN` Redundant Code
  Sequence assigned by `merge_findings.dart` in deterministic sort order (`file_path` ascending, then `line_start` ascending). Width 3 caps each category at 999 — comfortable headroom for confirmed violation volumes.
- **D-07:** ID is permanent once assigned. Fix phases update the `status` field (`open` → `closed` with `closed_in_phase` + `closed_commit` recorded) on the existing entry; they do **not** re-issue IDs. Phase 8's re-audit produces a fresh shard set; `scripts/reaudit_diff.dart` matches new findings against Phase 1 IDs by `(category, normalized_file_path, description)`. Re-audit finding without a Phase-1 match = a regression / new finding.
- **D-08:** Splits and merges follow a documented convention in `.planning/audit/SCHEMA.md`: a split keeps the original ID open and adds new IDs (`LV-014` stays open, `LV-201`, `LV-202` added with `split_from: LV-014`). A merge closes child IDs with `closed_as_duplicate_of: <parent_id>`. Planner is responsible for the bookkeeping when scoping each fix plan; the merger script does **not** auto-detect splits/merges (heuristics could silently lose findings).

### `ISSUES.md` Format & Audience
- **D-09:** Dual audience: (a) project owner skimming after Phase 1 to sanity-check scope and severity calls; (b) `/gsd-plan-phase` reading it alongside `issues.json` to scope each fix phase's plans. Format must serve both — scannable by a human, parseable by an agent.
- **D-10:** Grouping: severity-first, then category. Top-level `## CRITICAL` / `## HIGH` / `## MEDIUM` / `## LOW`; inside each, `### Layer Violations` / `### Provider Hygiene` / `### Dead Code` / `### Redundant Code`. Mirrors the fix-phase order (Phase 3 = CRITICAL, Phase 4 = HIGH, …) so a planner can grep `## CRITICAL` to find everything Phase 3 owns.
- **D-11:** Per-finding detail: compact Markdown table per category with columns `ID | File:Line | Description | Suggested Fix | tool_source`. ~1 line per finding. Each row references the JSON entry by ID for deeper context (`rationale`, `confidence`, full `suggested_fix` body). Estimated total: ~100–200 findings → ~300-line file.

### Claude's Discretion
- Audit script language: hybrid pattern — `scripts/audit_*.sh` is a thin POSIX shell wrapper that invokes a Dart implementation in `scripts/audit/<dimension>.dart`. Matches the existing `scripts/arb_to_csv.dart` Dart precedent for the analysis core while keeping the `.sh` invocation surface the requirements name (AUDIT-06). Cross-platform-friendly via the Dart core; the shell wrapper is single-line `dart run scripts/audit/<dimension>.dart "$@"` and degrades gracefully on Windows by invoking the Dart entry directly.
- Pinned versions for `import_guard` and `coverde`: resolve to latest stable on pub.dev at planning time, pin via caret (`^X.Y.Z`) so patch updates flow but minor/major bumps require a deliberate Phase-1 amendment. SUMMARY.md flags both as "verify on pub.dev" — that verification happens during planning, not now.
- `confidence` schema field semantics: three-level enum (`high` | `medium` | `low`). `high` = tool-flagged with structural rule match (no human judgment). `medium` = AI-agent finding with strong code-anchored evidence. `low` = AI-agent inference / pattern-similarity. Drives whether a planner auto-accepts or batches for triage review.
- Layout under `.planning/audit/`: `SCHEMA.md`, `issues.json`, `ISSUES.md`, `shards/<tool>.json` (per-scanner output), `agent-shards/<dimension>.json` (per-AI-agent output), `coverage-baseline.txt` and `files-needing-tests.txt` (Phase 2 will populate, but the directory is created here).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Project scope and constraints
- `.planning/PROJECT.md` — Initiative scope, behavior-preservation constraint, key decisions, what is explicitly out of scope
- `.planning/REQUIREMENTS.md` §AUDIT-01..AUDIT-10 — The 10 locked deliverables this phase must produce
- `.planning/ROADMAP.md` §"Phase 1: Audit Pipeline + Tooling Setup" — Goal, dependencies, success criteria

### Implementation guidance for this phase
- `.planning/research/SUMMARY.md` §"Phase 1: Tooling Setup and Audit Pipeline" — Recommended pipeline shape, exit criterion definition, severity taxonomy
- `.planning/research/STACK.md` — Tool selection rationale, version constraints, upgrade traps (`riverpod_lint` 3.x conflict)
- `.planning/research/ARCHITECTURE.md` — Five-component pipeline structure (Audit Engine → Issue Catalogue → Fix Phases → Doc Sweep → Re-Audit)
- `.planning/research/PITFALLS.md` — Eight pitfalls every fix phase must respect; the audit pipeline must surface findings that prevent them

### Codebase ground-truth (current state)
- `.planning/codebase/CONCERNS.md` — Confirmed live violations with file paths and line numbers; this is what the audit pipeline must catch
- `.planning/codebase/CONVENTIONS.md` — Existing project conventions, including `scripts/` precedent
- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture file layout that `import_guard.yaml` must encode
- `.planning/codebase/TESTING.md` — Current test infrastructure, 14 committed `*.mocks.dart` files (HIGH-07 territory)
- `.planning/codebase/STACK.md` — Already-installed lints (`riverpod_lint ^2.6.4`, `custom_lint ^0.7.5`, `flutter_lints ^6.0.0`) — must not break

### Project-wide rules
- `CLAUDE.md` §"Common Pitfalls" — 13 known pitfalls; each is a category the audit must catch
- `analysis_options.yaml` — Current minimal lint config; Phase 1 extends with the three plugins
- `pubspec.yaml` §`dev_dependencies` — Current dev deps (only `flutter_test` + `flutter_lints`); Phase 1 adds three packages

### External tooling docs (verify versions during planning)
- pub.dev: `import_guard` (Dart 3.10+, Jan 2026) — analyzer plugin for layer rules; configured via `import_guard.yaml`
- pub.dev: `dart_code_linter` (`^1.2.1`, Nov 2025) — free OSS fork of DCM; CLI for `check-unused-code` / `check-unused-files`
- pub.dev: `coverde` (Jan 2026) — per-file coverage CLI; reads standard `lcov.info`
- pub.dev: `riverpod_lint` (`^2.6.4`, Feb 2026) — already installed; **do not upgrade to 3.x** (analyzer conflict with `json_serializable`, see Riverpod issue #4393)
- GitHub: `VeryGoodOpenSource/very_good_coverage@v2` — GitHub Action for global coverage gate

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/arb_to_csv.dart` — Sole existing script. Establishes Dart-as-script precedent and demonstrates the shape of project-local Dart utilities. Audit-pipeline Dart implementations should follow the same module/entry pattern.
- `analysis_options.yaml` — Active lint config with `flutter_lints` base + `prefer_single_quotes` + `prefer_relative_imports` + `invalid_annotation_target: ignore`. Phase 1 layers the three audit plugins on top — no rules to remove.
- `.planning/codebase/` — Seven existing maps generated 2026-04-25. AI-agent scan agents read these for ground-truth context, eliminating the need for the agents to re-explore the codebase from scratch.

### Established Patterns
- `riverpod_lint` + `custom_lint` already wired through `dart run custom_lint` invocation. The audit pipeline extends this — `import_guard` joins as a third analyzer plugin via `analysis_options.yaml` `analyzer.plugins:` entry.
- Generated-file exclusion is conventional: `analyzer.exclude:` lists `**/*.g.dart` + `**/*.freezed.dart`. Audit findings must respect the same exclusion (no findings filed against generated files), and the dead-code scanner must skip them too.
- Build-runner code generation is a hard project requirement (CLAUDE.md). The CI guardrail `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` is therefore a true safety gate, not paranoia.

### Integration Points
- `pubspec.yaml` `dev_dependencies` — Phase 1 adds `import_guard`, `dart_code_linter`, `coverde` (and possibly `jscpd` is npm-side, not pubspec).
- `analysis_options.yaml` — Phase 1 registers `import_guard` as an analyzer plugin and confirms `custom_lint` plugin entry exists. Existing rules untouched.
- `.github/workflows/audit.yml` — New file. Greenfield CI for this initiative.
- `.planning/audit/` — New directory. Layout per Claude's discretion above.
- `scripts/` — Phase 1 adds: `audit_layer.sh`, `audit_dead_code.sh`, `audit_providers.sh`, `audit_duplication.sh`, `merge_findings.dart`, `reaudit_diff.dart` (full impl in Phase 8 but stub here so it's importable), and the corresponding `scripts/audit/<dimension>.dart` files behind the `.sh` wrappers.
- Project-local slash command directory (likely `.claude/commands/`) — Phase 1 adds `/gsd-audit-semantic` and the four locked subagent prompt files it references.

</code_context>

<specifics>
## Specific Ideas

- The `tool_source` field on every finding lets you trace which scanner caught what. If the AI-agent scan reports a finding the automated tooling also caught, the merger keeps the tooling entry (higher confidence) and discards the AI duplicate. If only the AI agent caught it, `tool_source: "agent:<dimension>"` flags the finding for closer triage review.
- The `confidence` field on every finding (high/medium/low per Claude's Discretion above) lets the planner auto-accept high-confidence findings into fix-plan scope and batch low-confidence findings for human review. Prevents AI false positives from auto-driving destructive refactors.
- Pre-Phase 8 dry-run: even though the re-audit is formally Phase 8, `/gsd-audit-semantic` should be runnable from the end of Phase 1 against the unchanged codebase to verify the pipeline produces a stable shard set on a re-run. This is part of the AUDIT-08 deliverable's correctness check.

</specifics>

<deferred>
## Deferred Ideas

- **Removing the `import_guard` reliance on `riverpod_lint 3.x`** — `FUTURE-TOOL-01` already covers this; not a Phase 1 concern.
- **Custom Dart script for Drift-column unused detection** — `FUTURE-TOOL-02` covers this. Phase 1 uses the AI agent for unused-column detection; if Phase 1 reveals the agent misses too many, escalate to the deferred custom script.
- **DCM (paid) upgrade** — `FUTURE-ARCH-03` covers this. The free `dart_code_linter` fork is the Phase 1 choice.
- **Mocktail migration vs CI-generated mocks** — explicitly Phase 4 territory (HIGH-07). Not decided here.
- **`appDatabaseProvider` replacement strategy** — explicitly Phase 3 territory (CRIT-03). Not decided here.
- **`CategoryLocaleService` long-term ARB-driven architecture** — `FUTURE-ARCH-01` covers this. Phase 5 only renames; the architectural overhaul is post-cleanup.
- **Pre-commit hook in addition to GitHub Actions CI** — Considered, declined. GitHub Actions is sole CI surface for this initiative; if local pre-commit becomes desirable later, it can be added without changing the audit pipeline contract.

</deferred>

---

*Phase: 01-audit-pipeline-tooling-setup*
*Context gathered: 2026-04-25*
