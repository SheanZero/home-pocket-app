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

Do NOT scan generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`,
`lib/generated/**`).

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

```json
{
  "tool_source": "agent:transitive",
  "generated_at": "<UTC ISO8601>",
  "findings": [
    {
      "category": "layer_violation",
      "severity": "CRITICAL",
      "file_path": "lib/features/accounting/domain/models/category.dart",
      "line_start": 12,
      "line_end": 12,
      "description": "Domain typedef aliases an Infrastructure type, smuggling Data dependency into Domain API surface",
      "rationale": "Pattern 4 transitive-import threat: layer rule passes because the import is to a same-layer file, but the typedef re-exports a forbidden type.",
      "suggested_fix": "Remove typedef; use Domain-native type. Phase 3 fix.",
      "tool_source": "agent:transitive",
      "confidence": "high"
    }
  ]
}
```

Confidence levels — high = direct evidence (typedef line, re-export statement), medium = strong inference, low = pattern similarity only.
