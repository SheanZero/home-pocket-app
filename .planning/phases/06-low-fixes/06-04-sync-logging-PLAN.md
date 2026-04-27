---
phase: "06-low-fixes"
plan: "04"
type: execute
wave: 4
depends_on:
  - "06-03"
files_modified:
  - lib/application/family_sync/sync_engine.dart
  - lib/application/family_sync/sync_orchestrator.dart
  - lib/application/family_sync/transaction_change_tracker.dart
  - lib/application/family_sync/full_sync_use_case.dart
  - lib/application/family_sync/pull_sync_use_case.dart
autonomous: true
requirements:
  - LOW-06
  - LOW-07
must_haves:
  truths:
    - "Family-sync and sync infrastructure logs do not expose request bodies, tokens, signatures, device IDs, group IDs, invite codes, or payloads."
    - "Debug-only sync diagnostics are guarded by kDebugMode."
    - "The shared production_logging_privacy_test.dart passes after sync cleanup."
  artifacts:
    - path: "test/architecture/production_logging_privacy_test.dart"
      provides: "Static guard for sync logging privacy"
  key_links:
    - from: "test/architecture/production_logging_privacy_test.dart"
      to: "lib/infrastructure/sync/relay_api_client.dart"
      via: "recursive source scan"
      pattern: "message=$message"
---

<objective>
Make family-sync application logging privacy-safe.

Purpose: continue the D-04 through D-06 logging boundary after Plan 06-03 introduces the shared architecture guard.
Output: guarded/scrubbed family-sync application diagnostics with no sensitive identity or payload data in logs.
</objective>

<execution_context>
@/Users/xinz/.codex/get-shit-done/workflows/execute-plan.md
@/Users/xinz/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/06-low-fixes/06-CONTEXT.md
@.planning/phases/06-low-fixes/06-RESEARCH.md
@.planning/phases/06-low-fixes/06-VALIDATION.md
@.planning/phases/06-low-fixes/06-PATTERNS.md
@test/architecture/production_logging_privacy_test.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Guard or scrub family-sync application logs</name>
  <files>lib/application/family_sync/sync_engine.dart, lib/application/family_sync/sync_orchestrator.dart, lib/application/family_sync/transaction_change_tracker.dart, lib/application/family_sync/full_sync_use_case.dart, lib/application/family_sync/pull_sync_use_case.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-PATTERNS.md
    - test/architecture/production_logging_privacy_test.dart
    - lib/application/family_sync/sync_engine.dart
    - lib/application/family_sync/sync_orchestrator.dart
    - lib/application/family_sync/transaction_change_tracker.dart
    - lib/application/family_sync/full_sync_use_case.dart
    - lib/application/family_sync/pull_sync_use_case.dart
  </read_first>
  <action>
    In the five `lib/application/family_sync/` files listed above, wrap every retained `debugPrint(` in `if (kDebugMode) { ... }` and add `import 'package:flutter/foundation.dart';` if a file needs `kDebugMode`. Remove or scrub interpolations that include transaction IDs, operation entity IDs, device IDs, group IDs, payload types tied to identifiers, message counts with from-device context, or raw operation maps. Keep non-sensitive debug lifecycle messages only behind `kDebugMode`. Do not change sync behavior.
  </action>
  <acceptance_criteria>
    - `LOGGING_PRIVACY_SCOPE=lib/application/family_sync/sync_engine.dart,lib/application/family_sync/sync_orchestrator.dart,lib/application/family_sync/transaction_change_tracker.dart,lib/application/family_sync/full_sync_use_case.dart,lib/application/family_sync/pull_sync_use_case.dart flutter test test/architecture/production_logging_privacy_test.dart` exits 0 for the family-sync files.
    - `rg -n "(print|debugPrint|dev\\.log).*\\b(entityId|transactionId|fromDeviceId|groupId|payload)\\b" lib/application/family_sync --glob "*.dart"` finds no sensitive logging interpolation.
    - `flutter analyze` exits 0.
  </acceptance_criteria>
  <verify>
    <automated>LOGGING_PRIVACY_SCOPE=lib/application/family_sync/sync_engine.dart,lib/application/family_sync/sync_orchestrator.dart,lib/application/family_sync/transaction_change_tracker.dart,lib/application/family_sync/full_sync_use_case.dart,lib/application/family_sync/pull_sync_use_case.dart flutter test test/architecture/production_logging_privacy_test.dart && flutter analyze</automated>
  </verify>
  <done>Family-sync application logs are debug-guarded and scrubbed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Family-sync application -> logs | Transaction, group, device, and payload metadata can escape to system logs. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-04-01 | I | family-sync logging | mitigate | Remove/scrub transaction, group, device, and payload identifiers in log calls. |
| T-06-04-02 | R | logging regression guard | mitigate | Re-run `production_logging_privacy_test.dart` after family-sync cleanup. |
</threat_model>

<verification>
Run the production logging architecture test and `flutter analyze`.
</verification>

<success_criteria>
No unguarded family-sync `debugPrint()` remains, sensitive family-sync values are not logged, and tests/analyzer pass.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-04-SUMMARY.md`.
</output>
