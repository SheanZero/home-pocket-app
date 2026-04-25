# /gsd-audit-semantic — AI Semantic Scan Orchestrator

Run the AI-agent semantic-scan portion of the audit pipeline (CONTEXT.md D-01).
Spawns 4 parallel subagents — one per scan dimension — each producing a JSON
shard at `.planning/audit/agent-shards/<dim>.json`. The shards are then merged
into `.planning/audit/issues.json` by `dart run scripts/merge_findings.dart`.

## Behavior

Spawn 4 subagents IN PARALLEL using the prompts at:

1. `.claude/commands/audit/layer_violation.md` → `agent-shards/layer.json`
2. `.claude/commands/audit/semantic_duplication.md` → `agent-shards/duplication.json`
3. `.claude/commands/audit/transitive_import.md` → `agent-shards/transitive.json`
4. `.claude/commands/audit/drift_unused_column.md` → `agent-shards/drift_col.json`

Each subagent reads `.planning/codebase/{STRUCTURE,CONCERNS,CONVENTIONS}.md`
for context (CONTEXT.md D-02). Subagents do NOT modify any `.dart` file or
any other repo file outside `.planning/audit/agent-shards/`.

## Inputs

- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture
- `.planning/codebase/CONCERNS.md` — confirmed live violations
- `.planning/codebase/CONVENTIONS.md` — project import conventions
- `.planning/audit/SCHEMA.md` — locked 11-field finding-record schema

## Output

Each subagent writes one JSON file matching SCHEMA.md to
`.planning/audit/agent-shards/<dim>.json`. After all 4 subagents complete,
run `dart run scripts/merge_findings.dart` to fold the agent-shards into
`.planning/audit/issues.json` + `ISSUES.md`.

## Re-runnability

These prompt files are the locked public interface of each audit dimension
(RESEARCH Pattern 4). Phase 8's re-audit invokes the SAME `/gsd-audit-semantic`
command, loading the SAME prompts, scoping the SAME file globs — so Phase 1
and Phase 8 outputs are comparable by `(category, normalized_file_path,
description)` per D-07. DO NOT modify these files mid-initiative without a
documented rationale and a `/gsd-execute-phase` plan amendment.
