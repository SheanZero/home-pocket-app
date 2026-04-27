---
phase: "06-low-fixes"
plan: "05"
type: execute
wave: 4
depends_on:
  - "06-03"
files_modified:
  - lib/infrastructure/sync/relay_api_client.dart
  - lib/infrastructure/sync/push_notification_service.dart
  - lib/infrastructure/sync/sync_lifecycle_observer.dart
  - lib/infrastructure/sync/sync_scheduler.dart
  - lib/infrastructure/sync/websocket_service.dart
autonomous: true
requirements:
  - LOW-06
  - LOW-07
must_haves:
  truths:
    - "Sync infrastructure logs do not expose request bodies, tokens, signatures, auth headers, device IDs, group IDs, invite codes, or payloads."
    - "Debug-only sync infrastructure diagnostics are guarded by kDebugMode."
    - "The shared production_logging_privacy_test.dart passes after infrastructure cleanup."
  artifacts:
    - path: "test/architecture/production_logging_privacy_test.dart"
      provides: "Static guard for infrastructure sync logging privacy"
  key_links:
    - from: "test/architecture/production_logging_privacy_test.dart"
      to: "lib/infrastructure/sync/relay_api_client.dart"
      via: "recursive source scan"
      pattern: "message=$message"
---

<objective>
Make sync infrastructure logging privacy-safe.

Purpose: complete the D-04 through D-06 logging boundary for networking, push notification, lifecycle, scheduling, and WebSocket infrastructure.
Output: guarded/scrubbed infrastructure diagnostics with no sensitive request, identity, token, signature, or payload data in logs.
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
  <name>Task 1: Guard or scrub sync infrastructure logs</name>
  <files>lib/infrastructure/sync/relay_api_client.dart, lib/infrastructure/sync/push_notification_service.dart, lib/infrastructure/sync/sync_lifecycle_observer.dart, lib/infrastructure/sync/sync_scheduler.dart, lib/infrastructure/sync/websocket_service.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-PATTERNS.md
    - test/architecture/production_logging_privacy_test.dart
    - lib/infrastructure/sync/relay_api_client.dart
    - lib/infrastructure/sync/push_notification_service.dart
    - lib/infrastructure/sync/sync_lifecycle_observer.dart
    - lib/infrastructure/sync/sync_scheduler.dart
    - lib/infrastructure/sync/websocket_service.dart
  </read_first>
  <action>
    In the five `lib/infrastructure/sync/` files listed above, wrap every retained `debugPrint(` in `if (kDebugMode) { ... }` and add `import 'package:flutter/foundation.dart';` if needed. In `relay_api_client.dart`, delete or scrub logs for `[RequestSigner] message=$message`, request body logging, signatures, auth headers, tokens, base URLs containing sensitive paths, and raw response payloads. In `push_notification_service.dart`, remove token values and raw message dumps from logs; keep only generic lifecycle/debug status behind `kDebugMode`. Keep behavior unchanged.
  </action>
  <acceptance_criteria>
    - `rg -n "(print|debugPrint|dev\\.log).*\\b(message|body|token|signature|Authorization|initialMessage|payload|deviceId|groupId|inviteCode)\\b" lib/infrastructure/sync --glob "*.dart"` finds zero sensitive logging matches.
    - `LOGGING_PRIVACY_SCOPE=lib/infrastructure/sync/relay_api_client.dart,lib/infrastructure/sync/push_notification_service.dart,lib/infrastructure/sync/sync_lifecycle_observer.dart,lib/infrastructure/sync/sync_scheduler.dart,lib/infrastructure/sync/websocket_service.dart flutter test test/architecture/production_logging_privacy_test.dart` exits 0.
    - `flutter analyze` exits 0.
  </acceptance_criteria>
  <verify>
    <automated>LOGGING_PRIVACY_SCOPE=lib/infrastructure/sync/relay_api_client.dart,lib/infrastructure/sync/push_notification_service.dart,lib/infrastructure/sync/sync_lifecycle_observer.dart,lib/infrastructure/sync/sync_scheduler.dart,lib/infrastructure/sync/websocket_service.dart flutter test test/architecture/production_logging_privacy_test.dart && flutter analyze</automated>
  </verify>
  <done>Sync infrastructure logs are debug-guarded and scrubbed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Sync networking -> logs | Request metadata and cryptographic material can be accidentally logged. |
| Push notification SDK -> logs | Tokens and message payloads can escape to system logs. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-05-01 | I | `relay_api_client.dart` logging | mitigate | Remove/scrub request body, signature, token, and message signing logs. |
| T-06-05-02 | I | `push_notification_service.dart` logging | mitigate | Remove token values and raw message dumps from logs. |
| T-06-05-03 | R | logging regression guard | mitigate | Re-run `production_logging_privacy_test.dart` after infrastructure cleanup. |
</threat_model>

<verification>
Run the production logging architecture test and `flutter analyze`.
</verification>

<success_criteria>
No unguarded infrastructure sync `debugPrint()` remains, sensitive sync infrastructure values are not logged, and tests/analyzer pass.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-05-SUMMARY.md`.
</output>
