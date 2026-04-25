---
phase: 01-audit-pipeline-tooling-setup
plan: 06
type: execute
wave: 3
depends_on: [03]
files_modified:
  - .claude/commands/gsd-audit-semantic.md
  - .claude/commands/audit/layer_violation.md
  - .claude/commands/audit/semantic_duplication.md
  - .claude/commands/audit/transitive_import.md
  - .claude/commands/audit/drift_unused_column.md
autonomous: true
requirements: [AUDIT-07]
tags: [ai-agent, slash-command, semantic-scan, prompt]

must_haves:
  truths:
    - "`/gsd-audit-semantic` slash command exists at `.claude/commands/gsd-audit-semantic.md`"
    - "4 subagent prompt files exist at `.claude/commands/audit/{layer_violation,semantic_duplication,transitive_import,drift_unused_column}.md`"
    - "Each subagent prompt scopes a different file glob and a different finding category per D-01 (CONTEXT.md): (a) misplaced features/*/use_cases/, (b) semantic duplication, (c) indirect layer violations, (d) Drift unused-column detection"
    - "Each subagent prompt loads codebase maps (.planning/codebase/{CONCERNS,STRUCTURE,CONVENTIONS}.md) for context per D-02"
    - "Each subagent prompt instructs writing to `.planning/audit/agent-shards/<dim>.json` matching the schema in `.planning/audit/SCHEMA.md`"
    - "The 5 prompt files use the locked 5-section structure from RESEARCH §'Code Examples — Example 4': # Title, ## Inputs, ## Scope, ## What to flag, ## Output format"
    - "Subagent prompts treat the public interface as locked (RESEARCH Pattern 4): Phase 8 re-runs the same exact contract"
  artifacts:
    - path: ".claude/commands/gsd-audit-semantic.md"
      provides: "Top-level slash command that spawns 4 parallel subagents"
      contains: "audit/layer_violation"
    - path: ".claude/commands/audit/layer_violation.md"
      provides: "Subagent prompt: indirect layer violations (type aliases, transitive imports, features/*/use_cases/ misplacement)"
      contains: "agent:layer"
    - path: ".claude/commands/audit/semantic_duplication.md"
      provides: "Subagent prompt: semantic duplication / parallel implementations of same concern"
      contains: "agent:duplication"
    - path: ".claude/commands/audit/transitive_import.md"
      provides: "Subagent prompt: indirect layer violations via type aliases / transitive imports"
      contains: "agent:transitive"
    - path: ".claude/commands/audit/drift_unused_column.md"
      provides: "Subagent prompt: Drift unused-column detection in lib/data/tables/*.dart"
      contains: "agent:drift_col"
  key_links:
    - from: ".claude/commands/gsd-audit-semantic.md"
      to: ".claude/commands/audit/*.md"
      via: "Slash command body references the 4 subagent prompt files for parallel dispatch"
      pattern: ".claude/commands/audit/"
    - from: "Each subagent prompt"
      to: ".planning/audit/agent-shards/<dim>.json"
      via: "Subagent writes its findings shard at task completion"
      pattern: "agent-shards/.*\\.json"
    - from: "Each subagent prompt"
      to: ".planning/audit/SCHEMA.md"
      via: "Prompt instructs the subagent to conform to the locked 11-field schema"
      pattern: "SCHEMA.md"
---

<objective>
Create the project-local slash command + 4 subagent prompt files that implement AUDIT-07 (the AI-agent semantic scan). Per CONTEXT.md D-01, invocation is `/gsd-audit-semantic` which spawns 4 parallel subagents — one per scan dimension. Each subagent has a locked prompt under `.claude/commands/audit/` so prompts are version-controlled and Phase 8 re-runs the same exact contract.

The 4 dimensions per D-01 are:
- (a) **Misplaced `features/*/use_cases/`** — the live CRIT-02 violation; flagged by the layer-violation subagent (already partly covered by Plan 02's `import_guard.yaml` Thin-Feature rule, but the AI agent independently verifies — RESEARCH "Known Threat Patterns" lists this as the rule-misconfig safety net)
- (b) **Semantic duplication / parallel implementations** — D-01.b; the AI handles this dimension since Plan 04's `audit_duplication.sh` is a stub
- (c) **Indirect layer violations** via type aliases or transitive imports — beyond what `import_guard_custom_lint` AST-checks
- (d) **Drift unused-column detection** — per RESEARCH "Don't Hand-Roll" + FUTURE-TOOL-02 (the deferred custom Dart script) — the AI agent fills the gap until Phase 8 / FUTURE-TOOL-02 provides a programmatic alternative

Per RESEARCH Pattern 4: these prompt files are the **public interface** of each audit dimension. Phase 8's re-audit invokes the same `/gsd-audit-semantic` command which loads the same prompt files which scope the same file globs — so Phase 1 and Phase 8 outputs are comparable. Treat these prompt files like API definitions: changes mid-initiative require documented rationale.

Per D-02: agents consume codebase maps (`.planning/codebase/{CONCERNS,STRUCTURE,CONVENTIONS}.md`) for context plus a pre-computed file list scoped to that agent's dimension.

Discovery-only: NO `.dart` file modified. The slash command + prompt files live under `.claude/commands/`, NOT `lib/`.

Purpose:
- AUDIT-07: AI-agent semantic-scan workflow defined and runnable, covering 4 dimensions

Output:
- 1 top-level slash command file: `.claude/commands/gsd-audit-semantic.md`
- 4 subagent prompt files: `.claude/commands/audit/{layer_violation,semantic_duplication,transitive_import,drift_unused_column}.md`
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@.planning/audit/SCHEMA.md
@.planning/codebase/STRUCTURE.md
@.planning/codebase/CONCERNS.md
@.planning/codebase/CONVENTIONS.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-03-SUMMARY.md

<interfaces>
<!-- Verbatim subagent prompt template from RESEARCH §"Code Examples — Example 4". -->

5-section subagent prompt structure (locked per RESEARCH Pattern 4):
1. `# Audit Subagent: <Title>` — heading
2. `## Inputs (read these before scanning)` — list of `.planning/codebase/*.md` files + RESEARCH ref
3. `## Scope` — exact file globs the subagent operates on; explicit "do NOT scan generated files"
4. `## What to flag` — enumerated list of specific findings the subagent is responsible for
5. `## Output format` — JSON shape the subagent writes (matches SCHEMA.md), confidence-scoring guidance

Example 4 verbatim from RESEARCH:
```markdown
# Audit Subagent: Layer Violations

You scan the file list provided and emit findings for indirect layer violations
that the `import_guard_custom_lint` plugin does NOT catch.

## Inputs (read these before scanning)

- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture
- `.planning/codebase/CONCERNS.md` — confirmed live violations
- `.planning/codebase/CONVENTIONS.md` — project import conventions

## Scope

Files: every `.dart` file under `lib/features/*/use_cases/` AND every Domain file
(`lib/features/*/domain/**/*.dart`). Do NOT scan generated files (`*.g.dart`,
`*.freezed.dart`).

## What to flag

1. A Domain file that imports any non-Domain symbol via a type alias.
2. A `features/<f>/use_cases/` file (the location is itself a CRIT-02 violation).
3. A `features/<f>/presentation/` import that reaches `infrastructure/` directly.

## Output format

Write a single JSON file to `.planning/audit/agent-shards/<dim>.json` with:

{
  "tool_source": "agent:<dim>",
  "generated_at": "<ISO8601>",
  "findings": [ ... ]
}

`high` = direct evidence. `medium` = strong inference. `low` = pattern similarity only.
```

Per-dimension scope + what-to-flag mapping (D-01):
| Dimension | Slash file | tool_source | Scope | What to flag |
|-----------|-----------|-------------|-------|--------------|
| (a) Layer | layer_violation.md | agent:layer | `lib/features/*/use_cases/**`, `lib/features/*/domain/**`, `lib/features/*/presentation/**` | Misplaced use_cases/ + indirect Domain → Data via aliases + presentation → infrastructure direct imports |
| (b) Duplication | semantic_duplication.md | agent:duplication | `lib/**/*.dart` (excluding generated) | Two classes/services that do "the same thing" with different names (e.g., dual `CategoryService` per CONCERNS.md MED-02; dual ledger classification logic if duplicated) |
| (c) Transitive | transitive_import.md | agent:transitive | `lib/features/*/domain/**`, `lib/features/*/presentation/**`, `lib/application/**` | An `import 'foo.dart';` whose `foo.dart` re-exports symbols from a forbidden layer; `typedef`-based aliasing of a forbidden type |
| (d) Drift cols | drift_unused_column.md | agent:drift_col | `lib/data/tables/*.dart` + every `*RepositoryImpl.dart` and DAO that consumes them | A column declared in a Drift table that no DAO query references — these are LOW-severity dead state |
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create the top-level /gsd-audit-semantic slash command + 4 subagent prompts</name>
  <files>.claude/commands/gsd-audit-semantic.md, .claude/commands/audit/layer_violation.md, .claude/commands/audit/semantic_duplication.md, .claude/commands/audit/transitive_import.md, .claude/commands/audit/drift_unused_column.md</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Code Examples — Example 4" (verbatim layer-violation subagent template) AND §"Architecture Patterns — Pattern 4" (locked-API contract) AND §"Standard Stack — 7. Slash Command + Subagents" if present
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group D — AI-Agent Slash Command" (5-section structure)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md (D-01 4 dimensions, D-02 codebase-map context, D-03 shard layout)
    - .planning/codebase/CONCERNS.md (live violations the subagents must catch — CRIT-02 use_cases, MED-02 dual CategoryService, HIGH-02 presentation→infrastructure)
    - .planning/codebase/STRUCTURE.md (lib/data/tables/ inventory for the Drift unused-column subagent)
    - .planning/audit/SCHEMA.md (Plan 03 — the 11-field schema each subagent must produce)
  </read_first>
  <action>
    First create the parent directory:
    ```bash
    mkdir -p .claude/commands/audit
    ```

    **File 1: `.claude/commands/gsd-audit-semantic.md` (top-level slash command)**

    ```markdown
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
    ```

    **File 2: `.claude/commands/audit/layer_violation.md`**

    Use the verbatim Example 4 template, with the dim-specific scope + what-to-flag from this plan's `<interfaces>` table:

    ```markdown
    # Audit Subagent: Layer Violations (agent:layer)

    Scan the file list scoped below and emit findings for indirect layer violations
    that the `import_guard_custom_lint` plugin does NOT catch (e.g., type aliases,
    transitive imports, structural violations like `features/*/use_cases/`).

    ## Inputs (read these before scanning)

    - `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture
    - `.planning/codebase/CONCERNS.md` — confirmed live violations (CRIT-02 in
      `lib/features/family_sync/use_cases/` is the canonical example)
    - `.planning/codebase/CONVENTIONS.md` — project import conventions
    - `.planning/audit/SCHEMA.md` — required JSON schema for findings

    ## Scope

    Files:
    - Every `.dart` file under `lib/features/*/use_cases/`
    - Every Domain file: `lib/features/*/domain/**/*.dart`
    - Every Presentation file: `lib/features/*/presentation/**/*.dart`

    Do NOT scan generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`,
    `lib/generated/**`).

    ## What to flag

    1. The mere existence of any file under `lib/features/*/use_cases/` — that
       location is itself a CRIT-02 Thin-Feature violation per CLAUDE.md.
       (severity: CRITICAL, confidence: high)
    2. A Domain file that imports any non-Domain symbol via a type alias
       (e.g., `typedef Foo = SomeDataLayerType;`).
       (severity: CRITICAL, confidence: medium)
    3. A `features/*/presentation/` import that reaches `infrastructure/` directly
       — HIGH-02 territory per CONCERNS.md.
       (severity: HIGH, confidence: high)

    ## Output format

    Write a single JSON file to `.planning/audit/agent-shards/layer.json` matching
    `.planning/audit/SCHEMA.md`:

    ```json
    {
      "tool_source": "agent:layer",
      "generated_at": "<UTC ISO8601>",
      "findings": [
        {
          "category": "layer_violation",
          "severity": "CRITICAL",
          "file_path": "lib/features/family_sync/use_cases/sync_now.dart",
          "line_start": 1,
          "line_end": 1,
          "description": "use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md)",
          "rationale": "Features must not contain application/use_cases per CLAUDE.md 'Thin Feature' rule; per CRIT-02 territory in CONCERNS.md.",
          "suggested_fix": "Move to lib/application/family_sync/. Phase 3 fix.",
          "tool_source": "agent:layer",
          "confidence": "high"
        }
      ]
    }
    ```

    Confidence levels:
    - `high` = direct evidence in source code (the actual import line, the type alias declaration)
    - `medium` = strong inference (e.g., a Domain class field whose name suggests a Data type without an explicit import)
    - `low` = pattern similarity only (you'd want a human to triage)
    ```

    **File 3: `.claude/commands/audit/semantic_duplication.md`**

    ```markdown
    # Audit Subagent: Semantic Duplication (agent:duplication)

    Scan the codebase for parallel implementations of the same concern under
    different class names — semantic duplication that AST-based duplication
    detection misses. Per CONTEXT.md D-01.b, this dimension is delegated to the
    AI agent (Plan 04's `audit_duplication.sh` is a Phase-1 stub).

    ## Inputs (read these before scanning)

    - `.planning/codebase/STRUCTURE.md` — 5-layer organization
    - `.planning/codebase/CONCERNS.md` — confirmed live duplications (MED-02 dual
      `CategoryService` is the canonical example)
    - `.planning/codebase/CONVENTIONS.md` — naming conventions
    - `.planning/audit/SCHEMA.md` — required JSON schema

    ## Scope

    All files under `lib/**/*.dart`. Do NOT scan generated files (`*.g.dart`,
    `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`).

    ## What to flag

    1. Two or more classes / services / use cases with overlapping
       responsibilities under different names (e.g., MED-02 dual
       `CategoryService` — one in `lib/infrastructure/category/` doing locale
       formatting, another doing classification logic).
       (severity: MEDIUM, confidence: medium-to-high based on evidence strength)
    2. Two or more `repository_providers.dart`-style provider declarations
       defining the same dependency in different files (HIGH-04 territory in
       CONCERNS.md).
       (severity: HIGH, confidence: high if names match)
    3. Parallel implementations of the same algorithm split across modules
       (e.g., the rule-engine + merchant-database + ML classifier triplet of
       the dual-ledger system, IF one of them shadows the others' contract).
       (severity: MEDIUM, confidence: low — humans may want to keep the parallel paths)

    ## Output format

    Write to `.planning/audit/agent-shards/duplication.json` matching SCHEMA.md.
    `tool_source` is `agent:duplication`. `category` is `redundant_code`.

    ```json
    {
      "tool_source": "agent:duplication",
      "generated_at": "<UTC ISO8601>",
      "findings": [ /* per SCHEMA.md, with category="redundant_code" */ ]
    }
    ```

    Confidence levels per Example 4 — high = direct evidence, medium = strong inference, low = pattern similarity only.
    ```

    **File 4: `.claude/commands/audit/transitive_import.md`**

    ```markdown
    # Audit Subagent: Transitive Imports (agent:transitive)

    Scan for indirect layer violations via type aliases or transitive imports
    that the per-directory `import_guard.yaml` rules don't catch (those rules
    only see direct imports; this dimension covers `import 'foo.dart';` where
    `foo.dart` re-exports forbidden symbols).

    ## Inputs (read these before scanning)

    - `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture
    - `.planning/codebase/CONCERNS.md` — confirmed live violations
    - `.planning/codebase/CONVENTIONS.md` — import conventions (no barrel files
      per "Anti-patterns Already in Place to Avoid")
    - `.planning/audit/SCHEMA.md` — required schema

    ## Scope

    - `lib/features/*/domain/**` (Domain re-export checks)
    - `lib/features/*/presentation/**` (Presentation indirect-infra checks)
    - `lib/application/**` (Application indirect-Data-table checks)

    Do NOT scan generated files.

    ## What to flag

    1. A Domain file that imports a module which itself re-exports
       Data/Infrastructure types (i.e., transitive Domain → Data via
       intermediate barrel-style file).
       (severity: CRITICAL, confidence: medium)
    2. A `features/<f>/presentation/` import of an Application use case that
       internally re-exports Infrastructure types — making Presentation
       implicitly Infrastructure-coupled (HIGH-02 territory).
       (severity: HIGH, confidence: medium)
    3. A `typedef Foo = SomeForbiddenType;` declaration that smuggles a
       cross-layer type into the layer's API surface.
       (severity: CRITICAL, confidence: high)

    ## Output format

    Write to `.planning/audit/agent-shards/transitive.json` matching SCHEMA.md.
    `tool_source` is `agent:transitive`. `category` is `layer_violation`.
    ```

    **File 5: `.claude/commands/audit/drift_unused_column.md`**

    ```markdown
    # Audit Subagent: Drift Unused Columns (agent:drift_col)

    Scan Drift table declarations for columns that no DAO query reads or
    writes. Per CONTEXT.md `<deferred>` and FUTURE-TOOL-02, a custom Dart
    script for this dimension is deferred — Phase 1 uses the AI agent.

    ## Inputs (read these before scanning)

    - `.planning/codebase/STRUCTURE.md` §"Database" — 11 Drift tables enumerated
    - `.planning/codebase/CONCERNS.md` — known data-layer concerns
    - `.planning/codebase/CONVENTIONS.md` — Drift naming conventions
    - `.planning/audit/SCHEMA.md` — required schema

    ## Scope

    - `lib/data/tables/*.dart` — column declarations
    - `lib/data/daos/*.dart` — query consumers (where `select`, `update`,
      `insert`, etc. reference columns)
    - `lib/data/repositories/*_repository_impl.dart` — higher-level consumers

    Do NOT scan `*.g.dart` or `*.freezed.dart`. Do NOT touch
    `lib/data/migrations/` (out of Phase 1 scope).

    ## What to flag

    1. A column declared in `lib/data/tables/<X>_table.dart` that no
       `lib/data/daos/<X>_dao.dart` query references (verify by symbol search
       across all DAOs + repositories).
       (severity: LOW, confidence: medium — false-positive risk; humans may
       know the column is reserved for future migrations)
    2. A column referenced only in `select(...)` but never in `insert(...)`
       or `update(...)` — possibly a write-through gap.
       (severity: LOW, confidence: low — flag for triage)

    ## Output format

    Write to `.planning/audit/agent-shards/drift_col.json` matching SCHEMA.md.
    `tool_source` is `agent:drift_col`. `category` is `dead_code`.
    ```

    Each file MUST be plain Markdown; no YAML frontmatter (Claude Code slash commands consume Markdown body content).

    Validate the 5 files exist:
    ```bash
    ls .claude/commands/gsd-audit-semantic.md .claude/commands/audit/*.md | wc -l
    # Expected: 5
    ```

    DO NOT execute the slash command in this task. Plan 08 is the end-to-end pipeline run that exercises `/gsd-audit-semantic` once on the unmodified codebase as a Phase-1 dry-run (per CONTEXT.md `<specifics>` "Pre-Phase 8 dry-run"). For THIS task, only the prompt files need to exist.

    DO NOT modify any `.dart` file. DO NOT create `.planning/audit/agent-shards/*.json` files (those are produced by the actual slash-command run in Plan 08).
  </action>
  <verify>
    <automated>test -f .claude/commands/gsd-audit-semantic.md && test -f .claude/commands/audit/layer_violation.md && test -f .claude/commands/audit/semantic_duplication.md && test -f .claude/commands/audit/transitive_import.md && test -f .claude/commands/audit/drift_unused_column.md && test $(ls .claude/commands/audit/*.md | wc -l) -eq 4 && grep -q "agent:layer" .claude/commands/audit/layer_violation.md && grep -q "agent:duplication" .claude/commands/audit/semantic_duplication.md && grep -q "agent:transitive" .claude/commands/audit/transitive_import.md && grep -q "agent:drift_col" .claude/commands/audit/drift_unused_column.md</automated>
  </verify>
  <acceptance_criteria>
    - 5 Markdown files exist: `.claude/commands/gsd-audit-semantic.md` + 4 under `.claude/commands/audit/`
    - Top-level command references all 4 subagent paths: `for d in layer_violation semantic_duplication transitive_import drift_unused_column; do grep -q "audit/$d" .claude/commands/gsd-audit-semantic.md || exit 1; done`
    - Each subagent prompt has the 5 required sections: `for f in .claude/commands/audit/*.md; do for s in '^# Audit Subagent' '^## Inputs' '^## Scope' '^## What to flag' '^## Output format'; do grep -qE "$s" "$f" || { echo "Missing $s in $f"; exit 1; }; done; done`
    - Each subagent declares its `tool_source` value: `grep -q "agent:layer" .claude/commands/audit/layer_violation.md && grep -q "agent:duplication" .claude/commands/audit/semantic_duplication.md && grep -q "agent:transitive" .claude/commands/audit/transitive_import.md && grep -q "agent:drift_col" .claude/commands/audit/drift_unused_column.md`
    - Each subagent instructs writing to the correct shard path: `grep -q "agent-shards/layer.json" .claude/commands/audit/layer_violation.md && grep -q "agent-shards/duplication.json" .claude/commands/audit/semantic_duplication.md && grep -q "agent-shards/transitive.json" .claude/commands/audit/transitive_import.md && grep -q "agent-shards/drift_col.json" .claude/commands/audit/drift_unused_column.md`
    - Each subagent references the SCHEMA.md: `for f in .claude/commands/audit/*.md; do grep -q "SCHEMA.md" "$f" || exit 1; done`
    - Each subagent excludes generated files: `for f in .claude/commands/audit/*.md; do grep -qE "(\\*.g.dart|generated)" "$f" || exit 1; done`
    - Top-level command notes the locked-API rule: `grep -qi "locked\\|Pattern 4\\|locked public interface" .claude/commands/gsd-audit-semantic.md`
    - No `.dart` file modified: `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0
    - No `.planning/audit/agent-shards/*.json` files created (subagents are not run in this task)
  </acceptance_criteria>
  <done>
    The 5 prompt files exist, follow the locked 5-section structure, and reference the correct shard paths + tool_source values. Plan 08 will exercise `/gsd-audit-semantic` end-to-end as the Phase-1 dry-run (CONTEXT.md `<specifics>`).
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Slash-command prompt files (version-controlled API surface) → AI subagent execution | Prompt drift between Phase 1 and Phase 8 silently changes the contract; mitigation = Pattern 4 locked-API rule |
| AI subagent → `.planning/audit/agent-shards/` write | Subagent could write malformed JSON or path-traverse; SCHEMA.md compliance is enforced by the merger's schema validator (Plan 05 Pitfall P1-10 mitigation) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-06-01 | Tampering | Prompt drift between Phase 1 and Phase 8 (changing what an agent flags would invalidate the reaudit_diff comparison) | mitigate | RESEARCH Pattern 4 + this plan's `gsd-audit-semantic.md` body explicitly states "DO NOT modify these files mid-initiative without a documented rationale". CI doesn't enforce this — Phase 8 re-audit relies on the prompts being unchanged from Phase 1 |
| T-1-06-02 | Input Validation | AI subagent writes shard with malformed JSON / missing required fields | mitigate | Plan 05's merger schema-validates each shard via `Finding.fromJson` cast; malformed entries are skipped with a stderr warning (RESEARCH Pitfall P1-10) |
| T-1-06-03 | Path Traversal | Subagent writes outside `.planning/audit/agent-shards/` (e.g., to `lib/`) | mitigate | Each prompt explicitly names the target shard path. Plan 08's verification re-asserts via `git status` after the dry-run that no `lib/` file was modified. Discovery-only constraint enforced. |

T-1-A (audit shards revealing sensitive paths): subagents scan `lib/` Dart code only and emit repo-relative paths per SCHEMA.md §1.
</threat_model>

<verification>
1. 5 Markdown files committed under `.claude/commands/`
2. Top-level command references all 4 subagents
3. Each subagent has the 5-section structure
4. Each subagent declares tool_source, target shard path, and references SCHEMA.md
5. No `.dart` file modified
6. No agent-shard JSON files created (those come from Plan 08's dry-run)
</verification>

<success_criteria>
- AUDIT-07 satisfied: AI-agent semantic-scan workflow defined as `/gsd-audit-semantic` slash command + 4 locked subagent prompts covering the 4 dimensions per D-01
- Plan 08 can dry-run `/gsd-audit-semantic` against the unmodified codebase to produce `.planning/audit/agent-shards/*.json` shards
- Phase 8 re-audit will invoke the same prompts, satisfying RESEARCH Pattern 4's locked-API contract
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-06-SUMMARY.md` describing:
- The 5 prompt files committed
- The 4 dimensions covered (per D-01 mapping)
- The locked-API contract for Phase 8 reuse
- Any deviations from RESEARCH §"Code Examples — Example 4" (e.g., if a subagent needed an extra context input)
</output>
