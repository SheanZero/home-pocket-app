---
phase: "06-low-fixes"
plan: "03"
type: execute
wave: 3
depends_on:
  - "06-01"
files_modified:
  - lib/main.dart
  - lib/core/initialization/app_initializer.dart
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/application/accounting/merchant_category_learning_service.dart
  - lib/data/repositories/transaction_repository_impl.dart
  - test/architecture/production_logging_privacy_test.dart
autonomous: true
requirements:
  - LOW-06
  - LOW-07
must_haves:
  truths:
    - "Production paths do not emit raw request bodies, tokens, signatures, transaction IDs, device IDs, group IDs, invite codes, or payloads."
    - "Debug-only diagnostics are guarded by kDebugMode."
    - "No unguarded print(), debugPrint(), or dev.log remains in lib/ production code."
  artifacts:
    - path: "test/architecture/production_logging_privacy_test.dart"
      provides: "Static guard for unguarded production logging"
  key_links:
    - from: "test/architecture/production_logging_privacy_test.dart"
      to: "lib/**/*.dart"
      via: "recursive source scan"
      pattern: "kDebugMode"
---

<objective>
Make app initialization and accounting logging privacy-safe, and introduce the shared logging privacy guard.

Purpose: satisfy D-04 through D-06 and LOW-06 without replacing the logging system unnecessarily.
Output: guarded/scrubbed app/accounting diagnostics and an architecture test that blocks logging regressions.
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
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add production logging privacy architecture test</name>
  <files>test/architecture/production_logging_privacy_test.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-CONTEXT.md
    - test/architecture/stale_suppressions_scan_test.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart
    - lib/main.dart
    - lib/core/initialization/app_initializer.dart
    - lib/infrastructure/sync/relay_api_client.dart
  </read_first>
  <action>
    Create `test/architecture/production_logging_privacy_test.dart`. The test must support a scoped mode for incremental plans: if `Platform.environment['LOGGING_PRIVACY_SCOPE']` is set to a comma-separated list of file paths, scan only those files; if the variable is absent or empty, recursively scan all `lib/**/*.dart`. Always skip `lib/generated/**`, `*.g.dart`, and `*.freezed.dart`. Fail on any `print(`. Fail on any `debugPrint(` or `dev.log(` call that is not within a nearby `if (kDebugMode)` guarded block. Fail when a logged string or interpolation contains sensitive names: `body`, `token`, `signature`, `deviceId`, `groupId`, `inviteCode`, `transactionId`, `payload`, `encryptedPayload`, `publicKey`, `privateKey`, or `message=`. The test should allow non-sensitive lifecycle labels such as `Database ready` only when guarded by `kDebugMode`.
  </action>
  <acceptance_criteria>
    - `rg -n "print\\(|debugPrint\\(|dev\\.log|kDebugMode|deviceId|groupId|token|signature|payload" test/architecture/production_logging_privacy_test.dart` finds matches.
    - `rg -n "LOGGING_PRIVACY_SCOPE|Platform\\.environment|comma-separated" test/architecture/production_logging_privacy_test.dart` finds matches.
    - `flutter test test/architecture/production_logging_privacy_test.dart` initially fails before cleanup or has explicit TODO expectations removed before commit.
    - `LOGGING_PRIVACY_SCOPE=lib/main.dart,lib/core/initialization/app_initializer.dart,lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/merchant_category_learning_service.dart,lib/data/repositories/transaction_repository_impl.dart flutter test test/architecture/production_logging_privacy_test.dart` exits 0 after this plan's cleanup.
  </acceptance_criteria>
  <verify>
    <automated>LOGGING_PRIVACY_SCOPE=lib/main.dart,lib/core/initialization/app_initializer.dart,lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/merchant_category_learning_service.dart,lib/data/repositories/transaction_repository_impl.dart flutter test test/architecture/production_logging_privacy_test.dart</automated>
  </verify>
  <done>The repository has an automated guard defining privacy-safe logging expectations.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Guard or scrub app and accounting logging surfaces</name>
  <files>lib/main.dart, lib/core/initialization/app_initializer.dart, lib/application/accounting/create_transaction_use_case.dart, lib/application/accounting/merchant_category_learning_service.dart, lib/data/repositories/transaction_repository_impl.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-PATTERNS.md
    - test/architecture/production_logging_privacy_test.dart
    - lib/main.dart
    - lib/core/initialization/app_initializer.dart
    - lib/application/accounting/create_transaction_use_case.dart
    - lib/data/repositories/transaction_repository_impl.dart
    - lib/application/accounting/merchant_category_learning_service.dart
  </read_first>
  <action>
    In `lib/main.dart`, `lib/core/initialization/app_initializer.dart`, `lib/application/accounting/create_transaction_use_case.dart`, `lib/application/accounting/merchant_category_learning_service.dart`, and `lib/data/repositories/transaction_repository_impl.dart`, remove every `print(` or replace it with a `debugPrint`/`dev.log` call inside `if (kDebugMode)`. Wrap any retained `debugPrint(` or `dev.log(` in `if (kDebugMode) { ... }`. Remove sensitive interpolations rather than merely guarding them when the log includes transaction IDs, amounts, merchant names, raw voice input, device IDs, or persistence IDs. In `app_initializer.dart`, do not log the actual `deviceId`; use a generic guarded message such as `Device identity ready`. Keep behavior unchanged.
  </action>
  <acceptance_criteria>
    - `rg -n "print\\(" lib --glob "*.dart" --glob "!lib/generated/**"` finds zero matches.
    - `LOGGING_PRIVACY_SCOPE=lib/main.dart,lib/core/initialization/app_initializer.dart,lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/merchant_category_learning_service.dart,lib/data/repositories/transaction_repository_impl.dart flutter test test/architecture/production_logging_privacy_test.dart` exits 0.
    - `rg -n "(print|debugPrint|dev\\.log).*\\b(deviceId|transactionId|merchantName|rawText|amount|id persisted)\\b" lib/main.dart lib/core/initialization/app_initializer.dart lib/application/accounting/create_transaction_use_case.dart lib/application/accounting/merchant_category_learning_service.dart lib/data/repositories/transaction_repository_impl.dart` finds zero sensitive logging matches.
    - `flutter analyze` exits 0.
  </acceptance_criteria>
  <verify>
    <automated>LOGGING_PRIVACY_SCOPE=lib/main.dart,lib/core/initialization/app_initializer.dart,lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/merchant_category_learning_service.dart,lib/data/repositories/transaction_repository_impl.dart flutter test test/architecture/production_logging_privacy_test.dart && flutter analyze</automated>
  </verify>
  <done>App initialization and accounting logging is removed, guarded, or scrubbed according to the Phase 6 privacy boundary.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| App runtime -> device/system logs | Diagnostic messages can escape the app's encrypted storage boundary. |
| Accounting flows -> logs | Transaction IDs, amounts, merchant names, and raw voice input can be accidentally logged. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-03-01 | I | accounting logging | mitigate | Remove/scrub transaction IDs, amounts, merchant names, raw text, and persistence IDs. |
| T-06-03-02 | I | `app_initializer.dart` logging | mitigate | Do not log actual device identifiers; guard lifecycle messages with `kDebugMode`. |
| T-06-03-03 | R | logging regression guard | mitigate | Add `production_logging_privacy_test.dart` and flip `avoid_print` in Plan 04. |
</threat_model>

<verification>
Run the production logging architecture test, `flutter analyze`, and touched-file coverage gates for modified app/accounting production files.
</verification>

<success_criteria>
No unguarded app/accounting `print()`, `debugPrint()`, or `dev.log()` remains, sensitive values are not logged, and tests/analyzer pass.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-03-SUMMARY.md`.
</output>
