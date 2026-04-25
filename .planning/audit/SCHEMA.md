# Audit Finding Schema

**Locked:** 2026-04-25
**Phase 1**

This document is the source-of-truth contract for every audit finding emitted in Phase 1 and consumed by every subsequent fix phase (Phases 3–6) and the Phase-8 re-audit. The Dart code mirror is [`scripts/audit/finding.dart`](../../scripts/audit/finding.dart) — field names match 1:1 between this doc and that file.

A finding is the unit record of architectural / quality violations surfaced by the four tooling scanners (Plan 04) and the four AI semantic-scan agents (Plan 06), merged into the unified catalogue (`issues.json` / `ISSUES.md`) by `scripts/merge_findings.dart` (Plan 05).

---

## 1. Required Fields (11)

Every finding MUST include all 11 fields below (with the exception of `id`, which is null on raw shards and stamped by the merger). All keys in JSON output are `snake_case`.

| Field | Type | Required | Valid Values / Notes | Example |
|-------|------|----------|----------------------|---------|
| `id` | string | optional (null pre-merge) | `LV-NNN` / `PH-NNN` / `DC-NNN` / `RD-NNN` (zero-padded 3-digit). Stamped by `merge_findings.dart` (Plan 05) in deterministic sort order. Permanent once assigned. | `LV-014` |
| `category` | string | required | `layer_violation` / `provider_hygiene` / `dead_code` / `redundant_code` | `layer_violation` |
| `severity` | string | required | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` (see §3) | `CRITICAL` |
| `file_path` | string | required | Repo-relative path. NEVER absolute (T-1-03-02 mitigation). NEVER `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**` (see §7). | `lib/features/family_sync/use_cases/sync_now.dart` |
| `line_start` | int | required | 1-indexed line number where the violation begins | `1` |
| `line_end` | int | required | 1-indexed line number where the violation ends; ≥ `line_start` | `1` |
| `description` | string | required | One-sentence statement of what's wrong. Imperative-mood, no leading hedge ("Possibly…"). | `use_cases/ inside features/ violates Thin Feature rule` |
| `rationale` | string | required | Why it matters. References `CLAUDE.md` "Common Pitfalls" or `.planning/codebase/CONCERNS.md` when applicable. | `Thin Feature rule (CLAUDE.md): features must not contain application/use_cases.` |
| `suggested_fix` | string | required | Concrete remediation step. Names the destination file/dir and the target Phase by number. | `Move to lib/application/family_sync/. Phase 3 fix.` |
| `tool_source` | string | required | One of the seven legal producer values (see §6). Drives dedupe priority in the merger. | `import_guard` |
| `confidence` | string | required | `high` (tool-flagged + structural rule match) / `medium` (AI-agent + strong code-anchored evidence) / `low` (AI-agent inference / pattern-similarity). Drives planner auto-accept vs triage-batch behavior. | `high` |

**Notes on `file_path`:** Audit scope is `lib/` Dart code only. No secrets, API keys, or PII enter findings (T-1-A phase-level threat-model carry-over). The merger normalizes any absolute path to repo-relative before writing `issues.json` (T-1-03-02 mitigation).

---

## 2. Lifecycle Fields (3)

Every finding tracks open/closed status for Phase-8 re-audit reconciliation.

| Field | Type | Notes |
|-------|------|-------|
| `status` | string | `open` (default at Phase 1) / `closed` (Phases 3–6 update on resolution). Phase 1 emits `open` for every finding. |
| `closed_in_phase` | string? | null until `status` flips to `closed`; e.g., `"3"` when CRIT items are closed in Phase 3. |
| `closed_commit` | string? | null until `status` flips to `closed`; full git SHA of the commit that closed the finding. Enables drilldown from `issues.json` to the fix diff. |

Fix phases update these three fields on the existing finding entry — they NEVER re-issue IDs (D-07 permanence rule).

---

## 3. Severity Taxonomy (AUDIT-05)

Four-level taxonomy with explicit phase mapping. Severity drives the order in which fix phases tackle findings: Phase 3 = CRITICAL, Phase 4 = HIGH, Phase 5 = MEDIUM, Phase 6 = LOW.

- **CRITICAL** — Layer violations breaking dependency rules + runtime-crash providers (`UnimplementedError`). Examples: Domain importing Data, `features/*/use_cases/` (Thin Feature breach), `appDatabaseProvider` `UnimplementedError`. These break the architecture's safety guarantees. **Fixed in Phase 3.**
- **HIGH** — Provider hygiene + architectural rule violations + deprecated service wiring. Examples: Presentation imports Infrastructure directly, duplicate `repository_providers.dart`, `keepAlive` regressions, `ResolveLedgerTypeService` remnants. **Fixed in Phase 4.**
- **MEDIUM** — Dead code, redundancy, i18n violations, theme-token debt. Examples: Hardcoded CJK strings, `CategoryService` naming collision, MOD-009 references. **Fixed in Phase 5.**
- **LOW** — Unused private members, stale `// ignore:` directives, missing Drift indices, debug `print()`. **Fixed in Phase 6.**

Severity is set by the producing scanner (tooling or agent) based on the rule that fired; the merger does NOT re-classify severity. If a tool flags something as CRITICAL but it doesn't actually break dependency rules, the rule should be re-tuned in the scanner — not silently downgraded by the merger (D-08 explicitness rule).

---

## 4. Stable-ID Scheme (D-06)

Stable IDs are essential for the Phase-8 re-audit critical path: a fix phase closing `LV-014` must be idempotent across re-runs.

**Format:** `<category-prefix>-<3-digit-zero-padded-sequence>`

**Category prefixes:**
- `LV` — **Layer Violations** (category=`layer_violation`)
- `PH` — **Provider Hygiene** (category=`provider_hygiene`)
- `DC` — **Dead Code** (category=`dead_code`)
- `RD` — **Redundant Code** (category=`redundant_code`)

**Width:** 3 digits → 999 IDs per category; comfortable headroom over confirmed violation volumes (~100–200 total per CONCERNS.md).

**Sequence assignment:** `merge_findings.dart` (Plan 05) sorts findings deterministically before stamping IDs:
1. `file_path` ascending (string compare)
2. `line_start` ascending (numeric compare)
3. Category-prefix priority for same `file_path` + `line_start`: `LV` < `PH` < `DC` < `RD`

This guarantees `LV-001`..`LV-NNN` are always assigned in the same order across re-runs given the same input shards.

**Permanence (D-07):** IDs are PERMANENT once assigned. Fix phases update the `status` / `closed_in_phase` / `closed_commit` fields on the existing entry; they do NOT re-issue IDs. Phase-8 re-audit produces a fresh shard set; `scripts/reaudit_diff.dart` matches new findings against Phase-1 IDs by the `(category, normalized_file_path, description)` triple, NOT by ID. A re-audit finding without a Phase-1 match = a regression / new finding.

---

## 5. Splits & Merges (D-08)

Splits and merges of findings are MANUAL planner bookkeeping — the merger script does NOT auto-detect them. Heuristics (e.g., textual similarity) could silently lose findings; D-08 is explicit on this.

**Split** — One Phase-1 finding becomes multiple findings during fix scoping:
- The original ID stays `open` until all children close.
- New IDs are added with a `split_from: <parent_id>` field.
- Example: `LV-014` covers a multi-file Thin-Feature breach. While planning Phase 3, the planner files `LV-201` (file A), `LV-202` (file B) with `split_from: LV-014`. `LV-014` closes only when both children close.

**Merge** — Multiple Phase-1 findings turn out to be the same root cause:
- Child IDs close with a `closed_as_duplicate_of: <parent_id>` field.
- The parent's `status` continues to be tracked normally.
- Example: `PH-014` and `PH-019` both arise from the same duplicated `repository_providers.dart`. After fix-scoping, `PH-019` closes with `closed_as_duplicate_of: PH-014`.

Both `split_from` and `closed_as_duplicate_of` are OPTIONAL fields on the finding record — the canonical Dart model in `scripts/audit/finding.dart` does not include them as typed fields because they are written by humans during planning, not by tooling. They appear in `issues.json` as additional keys when present.

---

## 6. Tool-Source Inventory

`tool_source` is the producer that emitted the finding. Seven legal values, four from automated tooling (Phase 1 Plan 04) and four from AI semantic-scan agents (Plan 06). The merger uses `tool_source` for dedupe priority: when the same `(category, file_path, line_start)` triple is reported by both tooling and an agent, the tooling entry wins (higher confidence).

| `tool_source` | Producer | Confidence default | Phase / Plan |
|---------------|----------|--------------------|--------------|
| `import_guard` | `dart run custom_lint` (`import_guard_custom_lint` plugin) → `audit_layer.sh` | `high` | Phase 1 Plan 04 |
| `riverpod_lint` | `dart run custom_lint` (`riverpod_lint` plugin) → `audit_providers.sh` | `high` | Phase 1 Plan 04 |
| `dart_code_linter` | `dart_code_linter:metrics check-unused-{code,files}` → `audit_dead_code.sh` | `high` | Phase 1 Plan 04 |
| `agent:layer` | AI subagent for indirect layer violations (transitive imports, type-alias smuggling) | `medium` | Phase 1 Plan 06 |
| `agent:duplication` | AI subagent for semantic duplication / parallel implementations | `low` | Phase 1 Plan 06 |
| `agent:transitive` | AI subagent for transitive imports across boundary layers | `medium` | Phase 1 Plan 06 |
| `agent:drift_col` | AI subagent for Drift unused-column detection | `low` | Phase 1 Plan 06 |

The fourth tooling scanner (`audit_duplication.sh`) is reserved for jscpd-style structural duplication and emits `tool_source: dart_code_linter` (Plan 04 will reconcile if a separate value becomes necessary).

---

## 7. Generated-File Exclusion

Defense-in-depth. The merger MUST drop any finding whose `file_path` matches one of the four patterns below. Scanners SHOULD also pre-filter, but defense-in-depth at the merger layer guarantees no generated-file finding ever reaches `issues.json` (T-1-03-03 mitigation; matches `analysis_options.yaml` `analyzer.exclude` plus `.mocks.dart` for the HIGH-07 mock-file regime).

- `**/*.g.dart` (build_runner code-gen)
- `**/*.freezed.dart` (Freezed code-gen)
- `**/*.mocks.dart` (mockito code-gen — currently 14 committed files; HIGH-07 territory)
- `lib/generated/**` (flutter_gen + ARB-generated `app_localizations.dart`)

Findings filed against generated files would be no-ops — fix phases cannot edit those files (Pitfall #1 in `CLAUDE.md`).

---

## 8. JSON Example

A representative pair of findings — one CRITICAL `LV-001` for the live `lib/features/family_sync/use_cases/` Thin-Feature breach (per `.planning/codebase/CONCERNS.md`), one MEDIUM `DC-001` for a hypothetical orphaned utility — demonstrating all 11 required fields plus the 3 lifecycle fields:

```json
[
  {
    "id": "LV-001",
    "category": "layer_violation",
    "severity": "CRITICAL",
    "file_path": "lib/features/family_sync/use_cases/sync_now_use_case.dart",
    "line_start": 1,
    "line_end": 1,
    "description": "use_cases/ inside features/ violates Thin Feature rule",
    "rationale": "Thin Feature rule (CLAUDE.md): features must not contain application/use_cases. Use cases live at lib/application/{domain}/.",
    "suggested_fix": "Move to lib/application/family_sync/sync_now_use_case.dart and rewire wiring provider in features/family_sync/presentation/providers/. Phase 3 fix.",
    "tool_source": "import_guard",
    "confidence": "high",
    "status": "open",
    "closed_in_phase": null,
    "closed_commit": null
  },
  {
    "id": "DC-001",
    "category": "dead_code",
    "severity": "MEDIUM",
    "file_path": "lib/shared/utils/legacy_color_helpers.dart",
    "line_start": 12,
    "line_end": 38,
    "description": "Public function `legacyHexToColor` has no remaining call sites",
    "rationale": "dart_code_linter:check-unused-code reports zero references after MOD-014 i18n migration superseded the legacy theme path.",
    "suggested_fix": "Delete `legacyHexToColor` and any helpers it transitively depended on; ensure no test under test/unit/shared/ still imports it. Phase 5 fix.",
    "tool_source": "dart_code_linter",
    "confidence": "high",
    "status": "open",
    "closed_in_phase": null,
    "closed_commit": null
  }
]
```

When `id` is null on a raw shard (pre-merge), the `toJson()` serialization in `scripts/audit/finding.dart` OMITS the key entirely (rather than emitting `"id": null`). The merger stamps a value before writing `issues.json`. Lifecycle fields `closed_in_phase` and `closed_commit` similarly omit when null.

---

## Files Referenced

- `scripts/audit/finding.dart` — Dart code mirror; field names match this doc 1:1
- `.planning/codebase/CONCERNS.md` — Source of truth for confirmed live violations
- `.planning/codebase/STRUCTURE.md` — 5-layer architecture file layout encoded by `import_guard.yaml`
- `analysis_options.yaml` — `analyzer.exclude` baseline that §7 extends with `.mocks.dart`
- `CLAUDE.md` — "Common Pitfalls" list whose 13 categories the audit pipeline catches
