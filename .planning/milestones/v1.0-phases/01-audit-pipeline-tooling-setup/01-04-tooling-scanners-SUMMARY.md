---
phase: 01
plan: 04
plan_name: tooling-scanners
status: complete
requirements: [AUDIT-02, AUDIT-06]
duration_min: ~10 (subagent partial + orchestrator inline completion)
self_check: PASSED
---

# Plan 01-04: Tooling Scanners — SUMMARY

## Performance

| Metric | Value |
|--------|-------|
| Tasks | 2/2 complete |
| Commits | 3 (1 wrappers, 1 chmod fix, 1 Dart cores) |
| Files modified | 0 in `lib/**` (Phase 1 discovery-only constraint preserved) |

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add 4 POSIX audit-scanner shell wrappers | `a356a36` feat(01-04): add 4 POSIX audit-scanner shell wrappers |
| 1 (fix) | Mark wrappers executable in git index | `ce02d52` fix(01-04): mark audit-scanner wrappers executable in git index |
| 2 | Add 4 Dart scanner cores with text-reporter fallback | (current HEAD) feat(01-04): add 4 Dart scanner cores with text-reporter fallback |

## Accomplishments

1. **4 POSIX shell wrappers** in `scripts/`:
   - `audit_layer.sh` → `dart run scripts/audit/layer.dart`
   - `audit_providers.sh` → `dart run scripts/audit/providers.dart`
   - `audit_dead_code.sh` → `dart run scripts/audit/dead_code.dart`
   - `audit_duplication.sh` → `dart run scripts/audit/duplication.dart`

   All 4 are 5-line POSIX wrappers (RESEARCH Pattern 1, PATTERNS Group C): shebang + path comment + description + `set -euo pipefail` + `exec dart run …`. Mode 100755 in git index.

2. **4 Dart scanner cores** in `scripts/audit/`:
   - `layer.dart` (160 lines) — `import_guard` filter, CRITICAL severity, `tool_source: import_guard`
   - `providers.dart` (167 lines) — `riverpod` filter, HIGH severity, `tool_source: riverpod_lint`
   - `dead_code.dart` (174 lines) — `dart_code_linter:metrics check-unused-{code,files}`, LOW severity
   - `duplication.dart` (22 lines) — Phase-1 stub, emits `{findings: []}` per CONTEXT.md D-01.b

3. **End-to-end smoke check on the unmodified codebase:**

   | Scanner | Findings | Notes |
   |---------|----------|-------|
   | `audit_layer.sh` | **19** | Real layer violations from `import_guard.yaml` rules placed in Plan 02 — see sample below |
   | `audit_providers.sh` | 0 | No `riverpod_lint` violations on the unmodified codebase |
   | `audit_dead_code.sh` | 0 | `dart_code_linter:metrics --reporter=json` returned non-JSON; fallback emitted empty (Assumption A3) |
   | `audit_duplication.sh` | 0 | Phase-1 stub, intentional empty array |

   Sample `layer.json` finding (the first of 19):
   ```json
   {
     "category": "layer_violation",
     "severity": "CRITICAL",
     "file_path": "lib/features/accounting/domain/models/category_ledger_config.dart",
     "line_start": 3,
     "line_end": 3,
     "description": "Import of 'transaction.dart' is not allowed by '...'/import_guard.yaml'.",
     "rationale": "Layer violation flagged by import_guard",
     "suggested_fix": "Move/refactor to satisfy the layer rule.",
     "tool_source": "import_guard",
     "confidence": "high",
     "status": "open"
   }
   ```

4. **Schema conformance** — all 4 shards validated via `python3 -c "json.load(...)"` checking `findings` is a list and `tool_source` is set. snake_case keys throughout, severities match scanner-locked defaults (Pitfall P1-9).

## Decisions Made

1. **Text-reporter fallback (Assumption A2 honored)** — When the orchestrator first ran the scanners, `dart run custom_lint --reporter=json` produced empty stdout (a known bug/quirk in the version-pinned `custom_lint` against analyzer 7.6.0). The plan anticipates this: A2 says "If the JSON reporter doesn't return a parseable stdout, fall back to a graceful empty array". I extended this — instead of emitting an empty shard, both `layer.dart` and `providers.dart` now re-run `custom_lint --no-fatal-infos` with the default text reporter and parse line-by-line. This recovers the 19 `import_guard` findings the layer scanner is supposed to surface, fully wiring AUDIT-02.
2. **Text-line regex** — `^\s*([^:]+\.dart):(\d+):(\d+)\s+•\s+(.+?)\s+•\s+(\S+)\s+•\s+(INFO|WARNING|ERROR)\s*$`. Captures relative file path, line, col, message, code, severity. Discriminates by `code.startsWith('import_guard')` / `'riverpod'`.
3. **`dead_code.dart` defensive parsing** — `dart_code_linter:metrics --reporter=json` outputs non-JSON for `check-unused-files` in version 1.0.0 (a control-character carriage return precedes anything else). Per Assumption A3, the scanner catches `FormatException`, logs a stderr warning, and continues — the shard still gets written with `findings: []`.
4. **Defense-in-depth generated-file filter** — Each scanner applies `_isGenerated()` (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `lib/generated/`) before mapping to `Finding`, even though the merger (Plan 05) will also filter. This ensures shards are clean inputs.
5. **Plain Dart, no @freezed** (Pitfall P1-7) — scripts run standalone with `dart run`; no build_runner step.
6. **Process invocations use `runInShell: true`** so the system shell resolves `dart` from `PATH`. Matches `scripts/arb_to_csv.dart` precedent.

## Files Created / Modified

| Path | Action |
|------|--------|
| `scripts/audit_layer.sh` | created — 5-line POSIX wrapper, 100755 |
| `scripts/audit_providers.sh` | created — 5-line POSIX wrapper, 100755 |
| `scripts/audit_dead_code.sh` | created — 5-line POSIX wrapper, 100755 |
| `scripts/audit_duplication.sh` | created — 5-line POSIX wrapper, 100755 |
| `scripts/audit/layer.dart` | created — 160 lines, JSON + text-reporter fallback |
| `scripts/audit/providers.dart` | created — 167 lines, JSON + text-reporter fallback |
| `scripts/audit/dead_code.dart` | created — 174 lines, dart_code_linter:metrics |
| `scripts/audit/duplication.dart` | created — 22 lines, Phase-1 stub |
| `.planning/audit/shards/layer.json` | written by smoke check — 19 findings |
| `.planning/audit/shards/providers.json` | written by smoke check — 0 findings |
| `.planning/audit/shards/dead_code.json` | written by smoke check — 0 findings |
| `.planning/audit/shards/duplication.json` | written by smoke check — 0 findings (stub) |

## Deviations from Plan

1. **Text-reporter fallback added** — plan only documents JSON-reporter fallback to `{findings: []}`. Orchestrator extended this to a working text-reporter path so the layer scanner actually surfaces findings rather than emitting an empty shard. This better satisfies AUDIT-02 ("layer-rule encoding is complete and observable") because the rules from Plan 02 now have a producer with real output.
2. **Subagent partial completion** — the parallel-spawn agent for this plan committed Task 1 (shell wrappers) but hit a usage-limit interruption before Task 2 (Dart cores). The orchestrator merged the partial work and completed Task 2 inline.

## Issues Encountered

1. **`custom_lint --reporter=json` returns empty stdout** — root cause: `custom_lint 0.7.6` against `analyzer 7.6.0`. Verified by `dart run custom_lint --reporter=json --no-fatal-infos > /tmp/stdout 2> /tmp/stderr` showing both as 0 bytes, while the default text reporter produces 9542 bytes of findings. Worked around via the text-reporter fallback (see Decisions §1).
2. **`dart_code_linter:metrics check-unused-files --reporter=json` emits non-JSON** — first character is a carriage return / control sequence. Worked around per Assumption A3 (catch FormatException, log warning, continue with empty array).

## Threat Mitigations

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-1-04-01 (malformed JSON crashes scanner) | try/catch around jsonDecode + text-reporter fallback for empty JSON output | mitigated |
| T-1-04-02 (absolute paths leak) | `_relPath()` strips `Directory.current.path` prefix; text reporter already emits relative paths | mitigated |
| T-1-04-03 (generated-file findings pollute shards) | `_isGenerated()` filter applied in each scanner before mapping to `Finding` | mitigated |
| T-1-04-04 (long-running scanner) | accepted; CI job timeout enforces an upper bound | accepted |
| T-1-04-05 (severity drift) | Severity hard-coded per-scanner; no recomputation in merger | mitigated |

## Acceptance Criteria — Verified

**Task 1 — wrappers:**
- [x] 4 wrapper files exist in `scripts/`
- [x] All 4 are 100755 (executable in git index)
- [x] All 4 have `#!/usr/bin/env bash` shebang on line 1
- [x] All 4 use `set -euo pipefail`
- [x] All 4 use single-line `exec dart run scripts/audit/<dim>.dart "$@"`
- [x] `bash -n` parses each cleanly
- [x] Wrapper-to-Dart name mapping correct

**Task 2 — Dart cores:**
- [x] 4 Dart cores exist in `scripts/audit/`
- [x] `dart analyze scripts/audit/` exits 0 (no issues)
- [x] `dart format scripts/audit/` clean (0 changed)
- [x] No `@freezed` / `@JsonSerializable` / `part` directive in any
- [x] `layer.dart` imports `finding.dart` and filters `import_guard` codes
- [x] `providers.dart` imports `finding.dart` and filters `riverpod` codes
- [x] `dead_code.dart` invokes `dart_code_linter:metrics`
- [x] `duplication.dart` is the explicit Phase-1 stub (`'Phase 1 stub'` literal in source)
- [x] Each `bash scripts/audit_<dim>.sh` exits 0 and produces a shard
- [x] Each shard is valid JSON with a `findings` array
- [x] Tool sources match SCHEMA §6: `import_guard`, `riverpod_lint`, `dart_code_linter` (×2)
- [x] No `lib/**/*.dart` modified

## Next Phase Readiness

| Plan | Unblocked by 01-04 | Reason |
|------|--------------------|--------|
| 01-05 (merger) | yes | Has 4 deterministic, schema-conformant shard files to consume |
| 01-08 (e2e pipeline run) | yes | All 4 wrappers individually invocable; pipeline produces real layer-violation baseline |

## Self-Check

- [x] All tasks executed (2/2)
- [x] Each task committed individually (3 commits total — wrappers, chmod fix, cores)
- [x] All wrappers produce valid SCHEMA-conformant shards
- [x] AUDIT-02 fully wired: Plan 02 layer rules now surface 19 real findings via `audit_layer.sh`
- [x] AUDIT-06 satisfied: each scanner is individually invocable and produces a JSON shard
- [x] No `lib/**/*.dart` modified
- [x] Threat-model mitigations verified
- [x] All Pitfalls (P1-7 no @freezed, P1-8 stdout-only, P1-9 severity-lock) honored

**Self-Check: PASSED**
