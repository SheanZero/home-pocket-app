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
