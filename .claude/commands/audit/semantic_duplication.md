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
  "findings": [
    {
      "category": "redundant_code",
      "severity": "MEDIUM",
      "file_path": "lib/infrastructure/category/category_service.dart",
      "line_start": 1,
      "line_end": 1,
      "description": "Duplicate CategoryService — locale formatting class shadowed by classification class in lib/application/dual_ledger/",
      "rationale": "MED-02 in CONCERNS.md: two CategoryService implementations doing different concerns under the same name.",
      "suggested_fix": "Rename one of the two services to reflect its actual concern (e.g., CategoryLocaleFormatter and CategoryClassifier). Phase 6 fix.",
      "tool_source": "agent:duplication",
      "confidence": "high"
    }
  ]
}
```

Confidence levels per Example 4 — high = direct evidence, medium = strong inference, low = pattern similarity only.
