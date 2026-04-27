---
phase: "06-low-fixes"
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/audit/issues.json
  - .planning/audit/ISSUES.md
  - .planning/audit/shards/dead_code.json
  - scripts/audit/dead_code.dart
  - scripts/audit_dead_code.sh
  - test/architecture/low_findings_closed_test.dart
  - test/architecture/stale_suppressions_scan_test.dart
autonomous: true
requirements:
  - LOW-01
  - LOW-02
  - LOW-03
  - LOW-07
must_haves:
  truths:
    - "Phase 6 does not treat the missing current LOW rows as completion."
    - "Scanner-backed LOW findings discovered by the re-scan are represented by stable rows in issues.json before closure."
    - "Generated files are excluded from stale-suppression cleanup."
  artifacts:
    - path: "test/architecture/low_findings_closed_test.dart"
      provides: "Regression gate asserting zero open LOW findings"
    - path: "test/architecture/stale_suppressions_scan_test.dart"
      provides: "Source scanner for stale non-generated ignore directives"
  key_links:
    - from: "scripts/audit_dead_code.sh"
      to: ".planning/audit/shards/dead_code.json"
      via: "dead-code scanner output"
      pattern: "severity.*LOW"
---

<objective>
Refresh LOW audit catalogue trust and remove scanner-backed dead-code/suppression debt.

Purpose: satisfy D-01 through D-03 before any later plan claims Phase 6 completion.
Output: refreshed LOW catalogue/shard state, dead-code cleanup instructions completed, and architecture tests that prove LOW rows and stale suppressions cannot stay open.
</objective>

<execution_context>
@/Users/xinz/.codex/get-shit-done/workflows/execute-plan.md
@/Users/xinz/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/06-low-fixes/06-CONTEXT.md
@.planning/phases/06-low-fixes/06-RESEARCH.md
@.planning/phases/06-low-fixes/06-VALIDATION.md
@.planning/phases/06-low-fixes/06-PATTERNS.md
@.planning/audit/SCHEMA.md
@.planning/audit/issues.json
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Re-scan LOW findings and restore catalogue traceability</name>
  <files>scripts/audit/dead_code.dart, scripts/audit_dead_code.sh, .planning/audit/shards/dead_code.json, .planning/audit/issues.json, .planning/audit/ISSUES.md</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-CONTEXT.md
    - .planning/phases/06-low-fixes/06-PATTERNS.md
    - .planning/audit/SCHEMA.md
    - .planning/audit/issues.json
    - scripts/audit/dead_code.dart
    - scripts/audit_dead_code.sh
    - scripts/merge_findings.dart
  </read_first>
  <action>
    Run `bash scripts/audit_dead_code.sh` and inspect `.planning/audit/shards/dead_code.json`. If the scan reports concrete unused-code or unused-file findings, add stable `LOW` rows to `.planning/audit/issues.json` using the schema fields `id`, `category`, `severity`, `file_path`, `line_start`, `line_end`, `description`, `rationale`, `suggested_fix`, `tool_source`, `confidence`, and `status`. Use stable IDs with a `DC-` prefix for dead-code findings. Regenerate `.planning/audit/ISSUES.md` through `dart run scripts/merge_findings.dart`. Do not mark a finding closed until the corresponding code/file cleanup has been completed.
  </action>
  <acceptance_criteria>
    - `bash scripts/audit_dead_code.sh` exits 0.
    - `.planning/audit/shards/dead_code.json` exists.
    - `dart run scripts/merge_findings.dart` exits 0.
    - `jq '.findings[] | select(.severity == "LOW" and .status == "open") | .id' .planning/audit/issues.json` prints only real open LOW findings before cleanup, not stale placeholders.
    - Every scanner-backed LOW row in `.planning/audit/issues.json` has a non-empty `id`, `tool_source`, `confidence`, and `suggested_fix`.
  </acceptance_criteria>
  <verify>
    <automated>bash scripts/audit_dead_code.sh && dart run scripts/merge_findings.dart && jq '.findings[] | select(.severity == "LOW") | .id' .planning/audit/issues.json</automated>
  </verify>
  <done>The LOW catalogue reflects the scanner-backed state and can be trusted by later closure gates.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Delete dead code and stale suppressions, then add closure gates</name>
  <files>test/architecture/low_findings_closed_test.dart, test/architecture/stale_suppressions_scan_test.dart, .planning/audit/issues.json, .planning/audit/ISSUES.md</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-VALIDATION.md
    - .planning/audit/issues.json
    - .planning/audit/SCHEMA.md
    - test/architecture/medium_findings_closed_test.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart
    - scripts/coverage_gate.dart
  </read_first>
  <action>
    Remove unused private members, unreachable branches, orphaned production/test files, and stale non-generated `// ignore:` or `// ignore_for_file:` directives discovered by Task 1. Do not edit generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`). Create `test/architecture/low_findings_closed_test.dart` by following the JSON parsing shape of `medium_findings_closed_test.dart`; it must fail when any finding has `"severity": "LOW"` and `"status": "open"`. Create `test/architecture/stale_suppressions_scan_test.dart`; recursively scan non-generated `lib/**/*.dart`, `test/**/*.dart`, and `scripts/**/*.dart`, skip generated files, and fail on `// ignore:` or `// ignore_for_file:` unless the test contains an explicit allow-list entry with a reason string. Once cleanup is complete, close all remediated LOW rows in `.planning/audit/issues.json` with `"status": "closed"`, `"closed_in_phase": "6"`, and `"closed_commit"` set to the current commit hash after code changes land. Regenerate `.planning/audit/ISSUES.md`.
  </action>
  <acceptance_criteria>
    - `dart run dart_code_linter:metrics check-unused-code lib` exits 0.
    - `dart run dart_code_linter:metrics check-unused-files lib` exits 0.
    - `rg -n "severity.*LOW|status.*open" test/architecture/low_findings_closed_test.dart` finds matches.
    - `rg -n "ignore_for_file|ignore:|generated|allow" test/architecture/stale_suppressions_scan_test.dart` finds matches.
    - `flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart` exits 0.
    - `jq '[.findings[] | select(.severity == "LOW" and .status == "open")] | length' .planning/audit/issues.json` prints `0`.
  </acceptance_criteria>
  <verify>
    <automated>dart run dart_code_linter:metrics check-unused-code lib && dart run dart_code_linter:metrics check-unused-files lib && flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart && flutter analyze</automated>
  </verify>
  <done>Dead code and stale suppressions are gone, generated files remain untouched, and LOW closure is enforced by tests.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Scanner output -> audit catalogue | Shard JSON becomes stable finding rows. |
| Source files -> architecture tests | Tests read repository code and fail on forbidden patterns. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-01-01 | R | `.planning/audit/issues.json` | mitigate | Preserve stable IDs, add lifecycle fields, and add `low_findings_closed_test.dart`. |
| T-06-01-02 | T | `stale_suppressions_scan_test.dart` | mitigate | Skip generated files and require explicit allow-list reasons for any remaining suppressions. |
</threat_model>

<verification>
Run dead-code scanners, LOW closure tests, stale-suppression tests, `flutter analyze`, and targeted coverage for any touched production files.
</verification>

<success_criteria>
`issues.json` has zero open LOW rows, dead-code scanners report zero findings, stale non-generated suppressions are gone, and analyzer/tests are green.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-01-SUMMARY.md`.
</output>

