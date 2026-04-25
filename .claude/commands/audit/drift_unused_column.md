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

```json
{
  "tool_source": "agent:drift_col",
  "generated_at": "<UTC ISO8601>",
  "findings": [
    {
      "category": "dead_code",
      "severity": "LOW",
      "file_path": "lib/data/tables/transactions_table.dart",
      "line_start": 42,
      "line_end": 42,
      "description": "Column 'foo' declared but never referenced by any DAO or repository",
      "rationale": "Symbol search across lib/data/daos/ and lib/data/repositories/ returns zero references.",
      "suggested_fix": "Remove the column or, if reserved for future migration, add a code comment. Phase 6 fix.",
      "tool_source": "agent:drift_col",
      "confidence": "medium"
    }
  ]
}
```

Confidence levels — high = direct evidence, medium = strong inference, low = pattern similarity only.
