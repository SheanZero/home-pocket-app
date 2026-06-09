# Deferred / Out-of-Scope Items — quick 260609-ec2

## OOS-1: `test/scripts/merge_findings_test.dart` idempotency flake under full-suite parallelism

- **Discovered during:** Task 3 full `flutter test`.
- **Symptom:** `merge_findings.dart (subprocess) idempotency: identical shards produce byte-identical issues.json` fails when run as part of the full suite (2513 pass, 1 fail). Re-running the file in isolation (`flutter test test/scripts/merge_findings_test.dart`) passes all 8 tests green.
- **Assessment:** Pre-existing flake in audit-script subprocess tooling under parallel execution. Zero coupling to this task's changes — all work was confined to `lib/features/shopping_list/presentation/` (tile, filter bar, reorder provider) + their tests/goldens. The audit-script tests do not import or exercise any shopping-list code.
- **Action:** Not fixed (scope boundary — only auto-fix issues caused by the current task's changes). Logged for a future audit-tooling stabilization pass.
- **Verification that the task's own surface is green:** `flutter analyze` 0 issues; shopping tile + filter bar widget tests fully green; 24 affected goldens re-baselined and passing; `provider_graph_hygiene_test` and `hardcoded_cjk_ui_scan_test` both green.
