# Phase 1: Audit Pipeline + Tooling Setup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-25
**Phase:** 01-audit-pipeline-tooling-setup
**Areas discussed:** AI-agent semantic scan design, CI gate enforcement timing, Stable finding ID scheme, ISSUES.md format & audience

---

## AI-Agent Semantic Scan Design

### Q1: How should the AI-agent semantic scan be invoked so it's deterministic and re-runnable in Phase 8?

| Option | Description | Selected |
|--------|-------------|----------|
| GSD slash command (/gsd-audit-semantic) (Recommended) | New project-local slash command spawning 4 parallel subagents (one per dimension). Locked prompts version-controlled. Each agent writes a JSON shard. Re-runnable by the same command. | ✓ |
| Single Dart driver script | `scripts/audit_semantic.dart` shells out to `claude --print` with sealed prompt template. Fully scriptable, CI-runnable, requires Claude CLI in CI. | |
| Inline subagent task list | `.planning/audit/AGENT-SCAN-TASKS.md` operator-driven checklist. No infrastructure but Phase 8 re-run is manual. | |
| Hybrid: command for humans, JSON spec for re-audit | Phase 1 ships both the slash command and a `scan-spec.json` pinning prompt versions. | |

**User's choice:** GSD slash command (/gsd-audit-semantic)

### Q2: What does the AI-agent scan consume as input on each run?

| Option | Description | Selected |
|--------|-------------|----------|
| Codebase maps + targeted file lists (Recommended) | Each agent reads CONCERNS.md + STRUCTURE.md + CONVENTIONS.md plus a pre-computed file list scoped to its dimension. Token-efficient, deterministic. | ✓ |
| Full lib/ tree per agent | Each agent walks lib/ itself. Simpler input but token-heavy and may drift between runs. | |
| Tooling diff: only files tooling flagged or skipped | Tooling runs first; AI agents only inspect flagged or unanalyzable files. | |

**User's choice:** Codebase maps + targeted file lists

### Q3: How does the AI agent's output combine with the automated tooling's output into issues.json?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-tool shards → Dart merger dedupes by (file_path, line_start, category) (Recommended) | 8 shards (4 tooling + 4 AI). `scripts/merge_findings.dart` dedupes, assigns IDs, sorts by severity. tool_source preserved. | ✓ |
| AI agent reads tooling output and annotates only | Single AI agent reads tooling output + adds semantic findings. Couples merge logic into agent prompt. | |
| Sequential pipeline with JSON pass-through | Bash pipeline appending/dedupes step by step. Pure shell, no merger script. | |

**User's choice:** Per-tool shards → Dart merger

---

## CI Gate Enforcement Timing

### Q1: When should the new lint/coverage checks become CI-blocking?

| Option | Description | Selected |
|--------|-------------|----------|
| Staged: each gate flips to blocking when its fix phase closes (Recommended) | Phase 1 = report-only. Phase 3: import_guard. Phase 4: riverpod_lint. Phase 5: i18n/theme. Phase 6: dart_code_linter + coverde per-file. Phase 8: permanent. | ✓ |
| All gates blocking immediately after Phase 1 | Every PR must pass every check from day one. Would block every fix-phase PR until findings cleared. | |
| All gates report-only until Phase 8 | Warnings only until final verification. No automated regression prevention during Phases 3–7. | |
| Minimal: only the two non-controversial gates blocking; everything else local-only | CI runs only sqlite3_flutter_libs reject + build_runner stale-diff. Other linters local-only. | |

**User's choice:** Staged: each gate flips to blocking when its fix phase closes

### Q2: Where do these CI gates run? The repo has no `.github/workflows/` yet.

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Actions (Recommended) | `.github/workflows/audit.yml` on every PR + push to main. Matches `very_good_coverage@v2`. Standard for OSS Flutter. | ✓ |
| Local pre-commit hook only | `.git/hooks/pre-commit` via `scripts/install-hooks.sh`. Skippable with `--no-verify`. | |
| Both: GitHub Actions + pre-commit hook | Belt and suspenders. Local instant feedback + remote authoritative gate. | |

**User's choice:** GitHub Actions

---

## Stable Finding ID Scheme

### Q1: What format should finding IDs take?

| Option | Description | Selected |
|--------|-------------|----------|
| Category prefix + zero-padded sequence: LV-001, PH-012, DC-007, RD-004 (Recommended) | LV/PH/DC/RD prefixes mapped to four categories. Width 3 (caps at 999). Greppable, references like `Fixes LV-014` work in commits. | ✓ |
| Severity prefix + sequence: CRIT-001, HIGH-012, MED-007, LOW-004 | Aligns IDs with severity tiers. Trade-off: severity changes after triage force renumbering. | |
| Hash-based: AUDIT-a3f2c1, AUDIT-b8e417 | Content hash derived. Survives sequence changes. Opaque to humans. | |
| Compound: LV-001-a3f2 (prefix + sequence + short hash) | Best of both: human-readable + drift-detectable hash suffix. | |

**User's choice:** Category prefix + zero-padded sequence

### Q2: How does an ID stay stable when its underlying file is moved or renamed during a fix phase?

| Option | Description | Selected |
|--------|-------------|----------|
| ID is permanent once assigned; tracked across phases via status updates (Recommended) | Phase 1 assigns IDs once. Fix phases update `status` (open → closed). Phase 8 reaudit_diff matches by (category, normalized path, description). | ✓ |
| Re-assign IDs each run; diff by content | Each run produces fresh IDs. Breaks the "reference LV-014 in commit" workflow. | |
| ID is permanent; an explicit `path_history[]` field tracks file moves | Same as #1 + `path_history` array maintained when planner records moves. More work, deterministic move detection. | |

**User's choice:** ID is permanent + status updates

### Q3: What happens when one finding splits into several (or several merge into one) between phases?

| Option | Description | Selected |
|--------|-------------|----------|
| Document the convention; rely on the planner to update issues.json explicitly (Recommended) | SCHEMA.md convention: split keeps original open + adds new IDs; merge closes child IDs with `closed_as_duplicate_of`. Planner discipline. | ✓ |
| Auto-detect splits/merges in the merger script | Heuristic detection. Heuristics can mis-classify and silently lose findings. | |
| No splits/merges allowed; treat any change as close-old + new finding | Strictest. Loses lineage but eliminates ambiguity. | |

**User's choice:** Document the convention + planner discipline

---

## ISSUES.md Format & Audience

### Q1: Who's the primary reader of ISSUES.md, and when?

| Option | Description | Selected |
|--------|-------------|----------|
| Both: you reviewing scope before each fix phase + planner agent batching findings (Recommended) | Dual audience contract: human-scannable AND agent-parseable. | ✓ |
| Primarily you (the project owner) | Optimize for human review at phase boundaries. Planner reads JSON directly. | |
| Primarily the planner agent | Optimize for machine parsing. Owner reads JSON via `jq`. | |

**User's choice:** Both: owner + planner agent

### Q2: How should ISSUES.md group findings?

| Option | Description | Selected |
|--------|-------------|----------|
| Severity-first, then category (Recommended) | Top-level: CRITICAL/HIGH/MEDIUM/LOW. Inside each: Layer/Provider/Dead/Redundant. Mirrors fix-phase order. | ✓ |
| Category-first, then severity | Top-level by category. Better for understanding debt shape but harder to scope a fix phase. | |
| Both, side-by-side: severity index + category appendix | Severity-grouped main body + category appendix. | |

**User's choice:** Severity-first, then category

### Q3: How much detail per finding in ISSUES.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Compact table per category + suggested-fix one-liner (Recommended) | Markdown table per category (ID | File:Line | Description | Suggested Fix | tool_source). ~1 line per finding. ~300 lines total. | ✓ |
| Section per finding with rationale + diff sketch | H4 per finding with rationale paragraph + fenced diff. 1500-3000 lines for 100-200 findings. | |
| Just IDs + one-liners; everything else in JSON | Minimal MD: flat bullet list per category. Planner must read JSON for actionable detail. | |

**User's choice:** Compact table per category + one-liner suggested fix

---

## Claude's Discretion

The following decisions were folded into CONTEXT.md without explicit user input — too low-stakes for question time, but documented here so the planner has full visibility:

- **Audit script language:** Hybrid (POSIX shell wrapper → Dart implementation). Honors the `.sh` names in AUDIT-06 while matching the project's existing `scripts/arb_to_csv.dart` Dart precedent. Cross-platform via Dart core.
- **Pinned versions for `import_guard` and `coverde`:** Resolve latest stable on pub.dev during planning, pin via caret. Verification step belongs to planning, not discussion.
- **`confidence` schema field semantics:** Three-level enum (`high` | `medium` | `low`) — high for tool-flagged structural matches, medium for AI agents with strong code-anchored evidence, low for AI inference. Drives planner triage decisions.
- **`.planning/audit/` layout:** `SCHEMA.md`, `issues.json`, `ISSUES.md`, `shards/<tool>.json`, `agent-shards/<dimension>.json`. Phase 2's `coverage-baseline.txt` and `files-needing-tests.txt` will land in the same directory.

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` section. None new beyond the existing v2 backlog (`FUTURE-ARCH-01..04`, `FUTURE-TOOL-01..02`) and the previously-deferred per-phase decisions (`appDatabaseProvider` strategy → Phase 3, `*.mocks.dart` strategy → Phase 4, `CategoryLocaleService` long-term architecture → post-cleanup).
