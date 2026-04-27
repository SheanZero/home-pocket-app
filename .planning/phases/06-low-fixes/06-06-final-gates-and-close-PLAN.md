---
phase: "06-low-fixes"
plan: "06"
type: execute
wave: 5
depends_on:
  - "06-01"
  - "06-02"
  - "06-03"
  - "06-04"
  - "06-05"
files_modified:
  - analysis_options.yaml
  - .github/workflows/audit.yml
  - .planning/audit/phase6-touched-files.txt
  - .planning/audit/issues.json
  - .planning/audit/ISSUES.md
  - test/architecture/low_findings_closed_test.dart
  - test/architecture/stale_suppressions_scan_test.dart
  - test/architecture/production_logging_privacy_test.dart
autonomous: true
requirements:
  - LOW-01
  - LOW-02
  - LOW-03
  - LOW-04
  - LOW-05
  - LOW-06
  - LOW-07
must_haves:
  truths:
    - "LOW-related gates become blocking only after all LOW fixes land."
    - "analysis_options.yaml enforces avoid_print: true."
    - "Full Phase 6 verification is green before the phase is marked complete."
  artifacts:
    - path: ".github/workflows/audit.yml"
      provides: "Blocking LOW scanner/analyzer enforcement"
    - path: "analysis_options.yaml"
      provides: "avoid_print lint enforcement"
  key_links:
    - from: ".github/workflows/audit.yml"
      to: "scripts/audit_dead_code.sh"
      via: "blocking CI step"
      pattern: "scripts/audit_dead_code.sh"
---

<objective>
Flip Phase 6 cleanup gates to blocking and close the LOW phase.

Purpose: satisfy D-07 through D-09 and prove all LOW requirements pass together.
Output: blocking lint/audit enforcement, final catalogue closure, and full verification evidence.
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
@.planning/audit/issues.json
@.github/workflows/audit.yml
@analysis_options.yaml
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Make LOW lint and audit gates blocking</name>
  <files>analysis_options.yaml, .github/workflows/audit.yml, .planning/audit/phase6-touched-files.txt</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-CONTEXT.md
    - analysis_options.yaml
    - .github/workflows/audit.yml
    - scripts/audit_dead_code.sh
    - scripts/coverage_gate.dart
  </read_first>
  <action>
    Create `.planning/audit/phase6-touched-files.txt` with one path per touched production file that must satisfy the 80% gate. Seed it with the concrete Phase 6 production targets:
    `lib/data/tables/audit_logs_table.dart`, `lib/data/tables/user_profiles_table.dart`, `lib/data/tables/category_ledger_configs_table.dart`, `lib/data/app_database.dart`, `lib/main.dart`, `lib/core/initialization/app_initializer.dart`, `lib/application/accounting/create_transaction_use_case.dart`, `lib/application/accounting/merchant_category_learning_service.dart`, `lib/data/repositories/transaction_repository_impl.dart`, `lib/application/family_sync/sync_engine.dart`, `lib/application/family_sync/sync_orchestrator.dart`, `lib/application/family_sync/transaction_change_tracker.dart`, `lib/application/family_sync/full_sync_use_case.dart`, `lib/application/family_sync/pull_sync_use_case.dart`, `lib/infrastructure/sync/relay_api_client.dart`, `lib/infrastructure/sync/push_notification_service.dart`, `lib/infrastructure/sync/sync_lifecycle_observer.dart`, `lib/infrastructure/sync/sync_scheduler.dart`, and `lib/infrastructure/sync/websocket_service.dart`. Add any additional production file touched by Plans 06-01 through 06-04 before running the final gate.

    In `analysis_options.yaml`, change `avoid_print: false` to `avoid_print: true`. In `.github/workflows/audit.yml`, keep the Phase 3/4 already-blocking guardrails intact and remove the LOW-related `continue-on-error: true` only after the Phase 6 checks pass locally. The static-analysis job must run `flutter analyze --no-fatal-infos`, `dart run custom_lint`, all audit scanner scripts, and `dart run scripts/merge_findings.dart` as blocking commands. In the coverage job, after `coverde filter` creates `coverage/lcov_clean.info`, add a blocking step named `Per-file coverage gate` that runs `dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info`. Do not make unrelated future Phase 8 re-audit requirements mandatory yet.
  </action>
  <acceptance_criteria>
    - `rg -n "avoid_print: true" analysis_options.yaml` finds one match.
    - `rg -n "lib/data/app_database.dart|lib/infrastructure/sync/relay_api_client.dart|lib/application/accounting/create_transaction_use_case.dart" .planning/audit/phase6-touched-files.txt` finds matches.
    - `rg -n "continue-on-error: true.*Phase 6|Audit scanners" .github/workflows/audit.yml` confirms the audit scanner step is not marked continue-on-error.
    - `rg -n "Per-file coverage gate|scripts/coverage_gate.dart --list \\.planning/audit/phase6-touched-files\\.txt --threshold 80 --lcov coverage/lcov_clean.info" .github/workflows/audit.yml` finds matches.
    - `flutter analyze` exits 0.
    - `bash scripts/audit_dead_code.sh` exits 0.
  </acceptance_criteria>
  <verify>
    <automated>flutter analyze && bash scripts/audit_dead_code.sh && dart run scripts/merge_findings.dart</automated>
  </verify>
  <done>LOW lint/audit checks now fail locally and in CI when regressions are introduced.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Run final Phase 6 verification and close remaining LOW rows</name>
  <files>.planning/audit/issues.json, .planning/audit/ISSUES.md, .planning/audit/phase6-touched-files.txt, test/architecture/low_findings_closed_test.dart, test/architecture/stale_suppressions_scan_test.dart, test/architecture/production_logging_privacy_test.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-VALIDATION.md
    - .planning/audit/issues.json
    - .planning/audit/SCHEMA.md
    - test/architecture/low_findings_closed_test.dart
    - test/architecture/stale_suppressions_scan_test.dart
    - test/architecture/production_logging_privacy_test.dart
  </read_first>
  <action>
    Run final Phase 6 verification: `dart format .`, `flutter analyze`, `dart run dart_code_linter:metrics check-unused-code lib`, `dart run dart_code_linter:metrics check-unused-files lib`, `flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart test/architecture/production_logging_privacy_test.dart test/unit/data/migrations/index_v15_migration_test.dart`, `flutter test --coverage`, `coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\\.g\\.dart$,\\.freezed\\.dart$,\\.mocks\\.dart$,^lib/generated/'`, `dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info`, and `flutter test`. For every LOW row closed in this plan, set `"status": "closed"`, `"closed_in_phase": "6"`, and `"closed_commit"` to the current commit hash containing the fix. Regenerate `.planning/audit/ISSUES.md`.
  </action>
  <acceptance_criteria>
    - `dart format .` exits 0 with no intended diff left unreviewed.
    - `flutter analyze` exits 0.
    - `dart run dart_code_linter:metrics check-unused-code lib` exits 0.
    - `dart run dart_code_linter:metrics check-unused-files lib` exits 0.
    - `flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart test/architecture/production_logging_privacy_test.dart test/unit/data/migrations/index_v15_migration_test.dart` exits 0.
    - `dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0 after `coverde filter`.
    - `flutter test` exits 0.
    - `jq '[.findings[] | select(.severity == "LOW" and .status == "open")] | length' .planning/audit/issues.json` prints `0`.
  </acceptance_criteria>
  <verify>
    <automated>dart format . && flutter analyze && dart run dart_code_linter:metrics check-unused-code lib && dart run dart_code_linter:metrics check-unused-files lib && flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart test/architecture/production_logging_privacy_test.dart test/unit/data/migrations/index_v15_migration_test.dart && flutter test --coverage && coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/' && dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info && flutter test</automated>
  </verify>
  <done>All Phase 6 gates pass together and the LOW catalogue is closed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Local verification -> CI | Local gates become pull-request blocking checks. |
| Audit catalogue -> roadmap completion | LOW finding status controls phase completion. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-06-01 | R | LOW closure evidence | mitigate | Require final `low_findings_closed_test.dart`, full tests, and `closed_commit` metadata. |
| T-06-06-02 | D | CI audit scanner step | mitigate | Make scanner/analyzer steps blocking only after Phase 6 cleanup is green. |
</threat_model>

<verification>
Run `dart format .`, `flutter analyze`, dead-code scanners, logging/suppression/LOW closure architecture tests, v15 migration tests, coverage generation/filtering, `scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info`, and full `flutter test`.
</verification>

<success_criteria>
All LOW requirements are covered, all Phase 6 checks pass, CI gates are blocking for LOW regressions, and `issues.json` has zero open LOW findings.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-06-SUMMARY.md`.
</output>
