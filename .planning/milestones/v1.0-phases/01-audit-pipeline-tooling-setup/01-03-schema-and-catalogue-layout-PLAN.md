---
phase: 01-audit-pipeline-tooling-setup
plan: 03
type: execute
wave: 2
depends_on: [01]
files_modified:
  - .planning/audit/SCHEMA.md
  - .planning/audit/shards/.gitkeep
  - .planning/audit/agent-shards/.gitkeep
  - scripts/audit/finding.dart
autonomous: true
requirements: [AUDIT-04, AUDIT-05]
tags: [schema, catalogue, finding-model]

must_haves:
  truths:
    - "`.planning/audit/SCHEMA.md` documents the 11 locked finding fields (id, category, severity, file_path, line_start, line_end, description, rationale, suggested_fix, tool_source, confidence) PLUS the 3 lifecycle fields (status, closed_in_phase, closed_commit) PLUS split/merge bookkeeping (split_from, closed_as_duplicate_of) per D-08"
    - "Severity taxonomy CRITICAL/HIGH/MEDIUM/LOW is documented with explicit definitions (matches SUMMARY.md)"
    - "Stable-ID scheme documented per D-06: prefixes LV/PH/DC/RD with zero-padded 3-digit sequences"
    - "Confidence enum documented per Claude's Discretion: high (tool-flagged + structural rule match), medium (AI-agent + strong code-anchored evidence), low (AI-agent inference / pattern-similarity)"
    - "`scripts/audit/finding.dart` is the canonical Dart Finding model — plain class (no @freezed), mirrors SCHEMA.md fields exactly"
    - "Layout dirs `.planning/audit/shards/` and `.planning/audit/agent-shards/` are committed (with .gitkeep) so subsequent plans have writable target dirs in CI"
  artifacts:
    - path: ".planning/audit/SCHEMA.md"
      provides: "Authoritative schema for every Phase-1 audit finding"
      contains: "tool_source"
    - path: "scripts/audit/finding.dart"
      provides: "Plain Dart Finding class with toJson + fromJson; shared by all 4 tooling scanners + merger"
      contains: "class Finding"
    - path: ".planning/audit/shards/.gitkeep"
      provides: "Committed empty directory for tooling shards"
    - path: ".planning/audit/agent-shards/.gitkeep"
      provides: "Committed empty directory for AI-agent shards"
  key_links:
    - from: "SCHEMA.md (this plan)"
      to: "scripts/audit/finding.dart (this plan)"
      via: "Field names match 1:1; SCHEMA.md is the doc source of truth, finding.dart is the code mirror"
      pattern: "tool_source"
    - from: "scripts/audit/finding.dart"
      to: "Plan 04's 4 audit cores + Plan 05's merger"
      via: "Imported via relative import `import '../audit/finding.dart';` (RESEARCH Pattern 1 + PATTERNS Group C)"
      pattern: "import.*finding\\.dart"
---

<objective>
Lock down the finding-record contract that every other Phase 1 component reads or writes against. SCHEMA.md is the source-of-truth doc (read by `/gsd-plan-phase` for Phases 3–6 to scope fix plans + read by Phase 8 `reaudit_diff.dart` to compare). `scripts/audit/finding.dart` is the Dart class mirror (imported by every scanner + the merger). The layout dirs `.planning/audit/{shards,agent-shards}/` exist so Plan 04 (tooling scanners) and Plan 06 (AI agents) have writable targets.

Purpose:
- AUDIT-04: lock finding-record schema with 11 fields documented in SCHEMA.md
- AUDIT-05: define the four-level severity taxonomy CRITICAL/HIGH/MEDIUM/LOW with explicit definitions

Output:
- `.planning/audit/SCHEMA.md` (greenfield doc — RESEARCH §"Code Examples — Example 2" + D-06..D-11 + AUDIT-05 definitions)
- `scripts/audit/finding.dart` (plain Dart class — RESEARCH §"Code Examples — Example 2" verbatim, ~70 lines)
- `.planning/audit/shards/.gitkeep` and `.planning/audit/agent-shards/.gitkeep` (empty placeholder files so the dirs commit cleanly)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@.planning/research/SUMMARY.md
@scripts/arb_to_csv.dart
@.planning/codebase/CONVENTIONS.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-01-SUMMARY.md

<interfaces>
<!-- Verbatim Finding class skeleton from RESEARCH §"Code Examples — Example 2", lines 540–610. -->

scripts/audit/finding.dart full body (RESEARCH §"Code Examples — Example 2"):
```dart
// scripts/audit/finding.dart
// Schema lock for every audit shard. Mirrors .planning/audit/SCHEMA.md.

class Finding {
  final String? id; // null until merge_findings stamps it
  final String category; // 'layer_violation' | 'provider_hygiene' | 'dead_code' | 'redundant_code'
  final String severity; // 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  final String filePath; // e.g. 'lib/features/family_sync/use_cases/foo.dart'
  final int lineStart;
  final int lineEnd;
  final String description;
  final String rationale;
  final String suggestedFix;
  final String toolSource; // 'import_guard' | 'riverpod_lint' | 'dart_code_linter' | 'agent:layer' | ...
  final String confidence; // 'high' | 'medium' | 'low'
  final String status; // 'open' | 'closed' (Phase 1 emits 'open')
  final String? closedInPhase; // null in Phase 1
  final String? closedCommit; // null in Phase 1

  const Finding({
    this.id,
    required this.category,
    required this.severity,
    required this.filePath,
    required this.lineStart,
    required this.lineEnd,
    required this.description,
    required this.rationale,
    required this.suggestedFix,
    required this.toolSource,
    required this.confidence,
    this.status = 'open',
    this.closedInPhase,
    this.closedCommit,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'category': category,
        'severity': severity,
        'file_path': filePath,
        'line_start': lineStart,
        'line_end': lineEnd,
        'description': description,
        'rationale': rationale,
        'suggested_fix': suggestedFix,
        'tool_source': toolSource,
        'confidence': confidence,
        'status': status,
        if (closedInPhase != null) 'closed_in_phase': closedInPhase,
        if (closedCommit != null) 'closed_commit': closedCommit,
      };

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
        id: j['id'] as String?,
        category: j['category'] as String,
        severity: j['severity'] as String,
        filePath: j['file_path'] as String,
        lineStart: j['line_start'] as int,
        lineEnd: j['line_end'] as int,
        description: j['description'] as String,
        rationale: j['rationale'] as String,
        suggestedFix: j['suggested_fix'] as String,
        toolSource: j['tool_source'] as String,
        confidence: j['confidence'] as String,
        status: (j['status'] as String?) ?? 'open',
        closedInPhase: j['closed_in_phase'] as String?,
        closedCommit: j['closed_commit'] as String?,
      );
}
```

Severity definitions (per ROADMAP.md + REQUIREMENTS.md framing — AUDIT-05):
- **CRITICAL** — Layer violations breaking dependency rules + runtime-crash providers (UnimplementedError). Domain-importing-Data, `features/*/use_cases/`, `appDatabaseProvider` UnimplementedError. These break the architecture's safety guarantees and ship fix in Phase 3.
- **HIGH** — Provider hygiene + architectural rule violations + deprecated service wiring. Presentation-imports-Infrastructure-directly, duplicate `repository_providers.dart`, `keepAlive` regressions, ResolveLedgerTypeService remnants. Phase 4.
- **MEDIUM** — Dead code, redundancy, i18n violations, theme-token debt. Hardcoded CJK strings, `CategoryService` naming collision, MOD-009 references. Phase 5.
- **LOW** — Unused private members, stale `// ignore:` directives, missing Drift indices, debug `print()`. Phase 6.

Category prefixes (D-06):
- `LV` = Layer Violations
- `PH` = Provider Hygiene
- `DC` = Dead Code
- `RD` = Redundant Code
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create scripts/audit/finding.dart (the canonical Finding model)</name>
  <files>scripts/audit/finding.dart</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Code Examples — Example 2" (verbatim Finding class body) + the "Avoid `@freezed` here" callout
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group C — scripts/audit/finding.dart" (plain Dart class, no codegen)
    - scripts/arb_to_csv.dart (Dart-script precedent — file header + plain Dart conventions)
    - .planning/codebase/CONVENTIONS.md §"Import organization" (dart:core first, then package:, then relative)
  </read_first>
  <action>
    Create `scripts/audit/finding.dart` with the verbatim content from this plan's `<interfaces>` block (the full Finding class from RESEARCH §"Code Examples — Example 2"). The file:

    - Starts with the file-path comment: `// scripts/audit/finding.dart`
    - Has no `dart:` or `package:` imports (the class is pure data — no I/O)
    - Defines exactly one class `Finding` with 14 fields
    - Implements `toJson()` returning a `Map<String, dynamic>` keyed with snake_case JSON keys
    - Implements `factory Finding.fromJson(Map<String, dynamic> j)` parsing snake_case JSON keys
    - Uses `final` fields (immutable)
    - Optional fields (`id`, `closedInPhase`, `closedCommit`) are nullable; `status` defaults to `'open'`

    Critical (RESEARCH §"Code Examples — Example 2" callout, line 612–613):
    > **Avoid `@freezed` here.** Freezed-annotated files trigger `build_runner` and require `.freezed.dart` / `.g.dart` regen. Plain Dart classes keep `scripts/` build-runner-free.

    Phase 1 explicitly cannot introduce build_runner-annotated files into `scripts/` (Pitfall P1-7 — stale-diff CI gate would fire). So plain Dart class only — no `@freezed`, no `@JsonSerializable`, no codegen of any kind.

    Format with `dart format scripts/audit/finding.dart` after writing.

    Run `flutter analyze --no-fatal-infos` to confirm the new file does not introduce analyzer warnings.

    DO NOT modify any `lib/**/*.dart` file (discovery-only constraint).
  </action>
  <verify>
    <automated>test -f scripts/audit/finding.dart && grep -q "class Finding" scripts/audit/finding.dart && grep -q "toJson" scripts/audit/finding.dart && grep -q "factory Finding.fromJson" scripts/audit/finding.dart && ! grep -q "@freezed" scripts/audit/finding.dart && ! grep -q "@JsonSerializable" scripts/audit/finding.dart && dart analyze scripts/audit/finding.dart</automated>
  </verify>
  <acceptance_criteria>
    - `scripts/audit/finding.dart` exists
    - File contains `class Finding` with at least these field names: `id`, `category`, `severity`, `filePath`, `lineStart`, `lineEnd`, `description`, `rationale`, `suggestedFix`, `toolSource`, `confidence`, `status`, `closedInPhase`, `closedCommit` (verify with `grep -c "final \\(String\\|int\\)" scripts/audit/finding.dart` returns ≥ 14)
    - `toJson()` method exists and emits snake_case keys: `grep -q "'file_path'" scripts/audit/finding.dart && grep -q "'line_start'" scripts/audit/finding.dart && grep -q "'tool_source'" scripts/audit/finding.dart && grep -q "'closed_in_phase'" scripts/audit/finding.dart`
    - `fromJson` factory exists: `grep -q "factory Finding.fromJson" scripts/audit/finding.dart`
    - NO `@freezed`: `! grep -q "@freezed" scripts/audit/finding.dart`
    - NO `@JsonSerializable`: `! grep -q "@JsonSerializable" scripts/audit/finding.dart`
    - NO part-of directives: `! grep -q "^part " scripts/audit/finding.dart`
    - `dart analyze scripts/audit/finding.dart` exits 0
    - `dart format --output=none --set-exit-if-changed scripts/audit/finding.dart` exits 0 (file is dart-formatted)
    - No file under `lib/` modified: `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0
  </acceptance_criteria>
  <done>
    `scripts/audit/finding.dart` exists with the canonical `Finding` plain Dart class. Plan 04's scanners + Plan 05's merger import this file relatively. No codegen triggered.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create .planning/audit/SCHEMA.md (locked finding-record contract + severity taxonomy + ID scheme)</name>
  <files>.planning/audit/SCHEMA.md, .planning/audit/shards/.gitkeep, .planning/audit/agent-shards/.gitkeep</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md (D-06..D-11, Claude's Discretion on confidence enum)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Code Examples — Example 2" (12 fields + 3 lifecycle fields)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group E — Schema Documentation" (CONVENTIONS.md style; YAML/JSON code blocks for schema)
    - .planning/codebase/CONVENTIONS.md (style for header + section format)
    - .planning/research/SUMMARY.md §"Severity Taxonomy" if defined there (the canonical CRITICAL/HIGH/MEDIUM/LOW phrasing)
    - scripts/audit/finding.dart (Task 1's output — SCHEMA.md must mirror this file's field names)
  </read_first>
  <action>
    Create `.planning/audit/SCHEMA.md` with the following structure (ALL sections required — AUDIT-04 + AUDIT-05). Use `.planning/codebase/CONVENTIONS.md` as the style template (top-level `# SCHEMA` heading + `**Analysis Date:** YYYY-MM-DD` metadata line + `## ` second-level sections).

    Required content sections (in this order):

    **`# Audit Finding Schema`**

    **`**Locked:** 2026-04-25`** (current planning date) and **`**Phase 1**`** subline.

    **`## 1. Required Fields (11)`** — Markdown table listing each of the 11 locked fields with type, required/optional, valid-values, and example. Fields:
    | Field | Type | Required | Valid Values / Notes | Example |
    | `id` | string | optional (null pre-merge) | `LV-NNN` / `PH-NNN` / `DC-NNN` / `RD-NNN` (zero-padded 3-digit) | `LV-014` |
    | `category` | string | required | `layer_violation` / `provider_hygiene` / `dead_code` / `redundant_code` | `layer_violation` |
    | `severity` | string | required | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` | `CRITICAL` |
    | `file_path` | string | required | repo-relative path; never `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**` | `lib/features/family_sync/use_cases/sync_now.dart` |
    | `line_start` | int | required | 1-indexed | `1` |
    | `line_end` | int | required | ≥ `line_start` | `1` |
    | `description` | string | required | one-sentence what's wrong | `use_cases/ inside features/ violates Thin Feature rule` |
    | `rationale` | string | required | why it matters; references CLAUDE.md / CONCERNS.md when applicable | `Thin Feature rule (CLAUDE.md): features must not contain application/use_cases.` |
    | `suggested_fix` | string | required | concrete remediation; references the target Phase by number | `Move to lib/application/family_sync/. Phase 3 fix.` |
    | `tool_source` | string | required | one of `import_guard`, `riverpod_lint`, `dart_code_linter`, `agent:layer`, `agent:duplication`, `agent:transitive`, `agent:drift_col` | `import_guard` |
    | `confidence` | string | required | `high` (tool-flagged + structural rule match), `medium` (AI-agent + strong code-anchored evidence), `low` (AI-agent inference / pattern-similarity) | `high` |

    **`## 2. Lifecycle Fields (3)`** — Markdown table. Fields:
    | Field | Type | Notes |
    | `status` | string | `open` (default at Phase 1) / `closed` (Phases 3–6 update on resolution) |
    | `closed_in_phase` | string? | null until status flips closed; e.g., `3` |
    | `closed_commit` | string? | null until status flips closed; full git SHA |

    **`## 3. Severity Taxonomy (AUDIT-05)`** — definitions matching ROADMAP.md / SUMMARY.md (verbatim from `<interfaces>` block above):
    - CRITICAL: layer violations breaking dependency rules + runtime-crash providers
    - HIGH: provider hygiene + architectural rule violations + deprecated service wiring
    - MEDIUM: dead code, redundancy, i18n violations, theme-token debt
    - LOW: unused private members, stale `// ignore:` directives, missing Drift indices, debug `print()`

    **`## 4. Stable-ID Scheme (D-06)`** — Document:
    - Category prefixes: `LV` (Layer Violations), `PH` (Provider Hygiene), `DC` (Dead Code), `RD` (Redundant Code)
    - 3-digit zero-padded sequence (allows 999 per category — D-06 capacity statement)
    - Sequence assigned by `merge_findings.dart` in deterministic sort order (`file_path` asc, then `line_start` asc, then category prefix priority `LV` < `PH` < `DC` < `RD`)
    - IDs are PERMANENT once assigned (D-07): fix phases update `status`, never re-issue IDs
    - Re-audit (Phase 8) matches by `(category, normalized_file_path, description)` triple, NOT by ID

    **`## 5. Splits & Merges (D-08)`** — Manual planner bookkeeping:
    - **Split:** original ID stays open; add new IDs with `split_from: <parent_id>` field
    - **Merge:** child IDs close with `closed_as_duplicate_of: <parent_id>` field
    - The merger script does NOT auto-detect splits/merges (heuristics could silently lose findings — D-08 is explicit)

    **`## 6. Tool-Source Inventory`** — Table of every legal `tool_source` value and what it means:
    | tool_source | Producer | Confidence default | Phase |
    | `import_guard` | `dart run custom_lint` (import_guard_custom_lint plugin) → `audit_layer.sh` | high | Phase 1 |
    | `riverpod_lint` | `dart run custom_lint` (riverpod_lint plugin) → `audit_providers.sh` | high | Phase 1 |
    | `dart_code_linter` | `dart_code_linter:metrics check-unused-{code,files}` → `audit_dead_code.sh` | high | Phase 1 |
    | `agent:layer` | AI subagent for indirect layer violations | medium | Phase 1 |
    | `agent:duplication` | AI subagent for semantic duplication | low | Phase 1 |
    | `agent:transitive` | AI subagent for transitive imports | medium | Phase 1 |
    | `agent:drift_col` | AI subagent for Drift unused-column detection | low | Phase 1 |

    **`## 7. Generated-File Exclusion`** — Defense-in-depth (RESEARCH §"Generated-file & ARB exclusions" + RESEARCH §"Anti-Patterns"). The merger MUST drop any finding whose `file_path` matches:
    - `**/*.g.dart`
    - `**/*.freezed.dart`
    - `**/*.mocks.dart`
    - `lib/generated/**`

    **`## 8. JSON Example`** — A 30-line example showing one CRITICAL `LV-001` finding (the live `lib/features/family_sync/use_cases/` violation from CONCERNS.md) and one MEDIUM `DC-001` finding (a hypothetical orphaned utility), demonstrating ALL 11 + 3 lifecycle fields.

    Then create the two `.gitkeep` placeholder files so the dirs commit:
    ```bash
    mkdir -p .planning/audit/shards .planning/audit/agent-shards
    touch .planning/audit/shards/.gitkeep .planning/audit/agent-shards/.gitkeep
    ```

    DO NOT touch any `lib/**/*.dart` file. DO NOT create `.planning/audit/issues.json` or `.planning/audit/ISSUES.md` here — those are emitted by the merger in Plan 05.
  </action>
  <verify>
    <automated>test -f .planning/audit/SCHEMA.md && grep -q "tool_source" .planning/audit/SCHEMA.md && grep -q "CRITICAL" .planning/audit/SCHEMA.md && grep -q "HIGH" .planning/audit/SCHEMA.md && grep -q "MEDIUM" .planning/audit/SCHEMA.md && grep -q "LOW" .planning/audit/SCHEMA.md && grep -q "LV-" .planning/audit/SCHEMA.md && grep -q "PH-" .planning/audit/SCHEMA.md && grep -q "DC-" .planning/audit/SCHEMA.md && grep -q "RD-" .planning/audit/SCHEMA.md && grep -q "split_from" .planning/audit/SCHEMA.md && grep -q "closed_as_duplicate_of" .planning/audit/SCHEMA.md && test -f .planning/audit/shards/.gitkeep && test -f .planning/audit/agent-shards/.gitkeep</automated>
  </verify>
  <acceptance_criteria>
    - `.planning/audit/SCHEMA.md` exists
    - All 11 required-field names appear in SCHEMA.md: `for f in id category severity file_path line_start line_end description rationale suggested_fix tool_source confidence; do grep -q "$f" .planning/audit/SCHEMA.md || exit 1; done`
    - All 3 lifecycle field names appear: `for f in status closed_in_phase closed_commit; do grep -q "$f" .planning/audit/SCHEMA.md || exit 1; done`
    - All 4 severity tiers documented: `for s in CRITICAL HIGH MEDIUM LOW; do grep -q "$s" .planning/audit/SCHEMA.md || exit 1; done`
    - All 4 category prefixes documented: `for p in LV PH DC RD; do grep -q "${p}-" .planning/audit/SCHEMA.md || exit 1; done`
    - Split/merge convention documented: `grep -q "split_from" .planning/audit/SCHEMA.md && grep -q "closed_as_duplicate_of" .planning/audit/SCHEMA.md`
    - Tool-source inventory has all 7 sources: `for t in import_guard riverpod_lint dart_code_linter agent:layer agent:duplication agent:transitive agent:drift_col; do grep -q "$t" .planning/audit/SCHEMA.md || exit 1; done`
    - Generated-file exclusion documented: `grep -q "*.g.dart" .planning/audit/SCHEMA.md && grep -q "*.freezed.dart" .planning/audit/SCHEMA.md && grep -q "*.mocks.dart" .planning/audit/SCHEMA.md`
    - JSON example block present: `grep -q '```json' .planning/audit/SCHEMA.md`
    - Two `.gitkeep` files exist: `test -f .planning/audit/shards/.gitkeep && test -f .planning/audit/agent-shards/.gitkeep`
    - No `lib/**/*.dart` file modified
  </acceptance_criteria>
  <done>
    SCHEMA.md is the locked contract for every finding; finding.dart from Task 1 is the Dart code mirror; placeholder dirs are committed. Plans 04 and 05 can now produce shards / merge into `issues.json` against this schema.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Schema doc → consumer agents (planner, verifier, executor) | Future fix phases trust SCHEMA.md as the canonical contract. If a field name drifts between SCHEMA.md and finding.dart, downstream parsing breaks silently. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-03-01 | Tampering | SCHEMA.md / finding.dart name drift | mitigate | Acceptance criteria explicitly grep both files for matching field names. Plan 05's merger test (`test/scripts/merge_findings_test.dart`) round-trips Finding.toJson → fromJson which exercises the schema/code contract. |
| T-1-03-02 | Information Disclosure | Findings emitted with absolute paths revealing developer machine layout | mitigate | SCHEMA.md §1 explicitly documents `file_path` as repo-relative. Merger script's normalize step (Plan 05) converts any absolute path to repo-relative before writing. |
| T-1-03-03 | Tampering | Generated-file findings reaching `issues.json` (`*.g.dart`, etc.) | mitigate | SCHEMA.md §7 documents the exclusion list; merger script (Plan 05) defends-in-depth with the same list (RESEARCH "Anti-Patterns — Don't filter generated files at scanner level only"). |

T-1-A (audit shards revealing sensitive paths) per phase-level threat model: Phase 1 audit scans `lib/` Dart code only; no secrets, no API keys, no PII enter findings. SCHEMA.md does not need to mandate redaction. Document this in §1 (`file_path` field notes). No new mitigation required.
</threat_model>

<verification>
1. `scripts/audit/finding.dart` parses cleanly with `dart analyze`
2. `.planning/audit/SCHEMA.md` documents all 11 required fields + 3 lifecycle fields + split/merge convention
3. Severity taxonomy CRITICAL/HIGH/MEDIUM/LOW defined with explicit per-phase mappings
4. Stable-ID scheme documents prefixes (LV/PH/DC/RD) + sort order + permanence rule
5. Tool-source inventory lists all 7 valid producers
6. Generated-file exclusion list mirrors `analysis_options.yaml` exclusions + `.mocks.dart`
7. `.gitkeep` placeholders committed for `shards/` and `agent-shards/`
8. No `lib/**/*.dart` modified
</verification>

<success_criteria>
- AUDIT-04 satisfied: schema locked in `.planning/audit/SCHEMA.md` (11 fields + 3 lifecycle fields, machine-readable structure documented)
- AUDIT-05 satisfied: 4-level severity taxonomy with definitions; mapping to fix phases (Phase 3 = CRITICAL, Phase 4 = HIGH, Phase 5 = MEDIUM, Phase 6 = LOW) documented
- `scripts/audit/finding.dart` is the Dart code mirror — Plan 04's 4 scanner cores + Plan 05's merger import this file via relative import
- `.planning/audit/{shards,agent-shards}/` exist as committed empty dirs ready for write targets
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-03-SUMMARY.md` describing the locked schema fields, the severity taxonomy, the category prefixes, the tool-source inventory, and any deviations from RESEARCH §"Code Examples — Example 2" (e.g., if `Finding` needed an extra field for the AI-agent flow that wasn't in the original example).
</output>
