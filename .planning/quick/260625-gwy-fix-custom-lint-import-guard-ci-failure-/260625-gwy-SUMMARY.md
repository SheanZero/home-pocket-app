---
quick_id: 260625-gwy
description: fix custom_lint import_guard CI failure — whitelist 5 legit domain→domain model imports
date: 2026-06-25
status: complete
commit: 26cf4f79
---

# Quick Task 260625-gwy: Fix custom_lint import_guard CI failure

## What

CI step `dart run custom_lint --no-fatal-infos` failed (exit 1, GitHub Actions
run 28139595431) with 5 `import_guard` WARNINGS. Diagnosed all 5 as legitimate
**same-layer domain→domain model imports** absent from the per-directory
`import_guard.yaml` allow-lists (each whitelist inherits a feature-level deny and
must explicitly re-allow sibling / cross-feature domain model imports). No layer
violation, no bad import — the whitelists were just incomplete. Fix = add the 5
missing allow-list entries.

## Changes

| File | Added allow entry |
|------|-------------------|
| `lib/features/accounting/domain/repositories/import_guard.yaml` | `../models/merchant.dart` |
| `lib/features/accounting/domain/repositories/import_guard.yaml` | `../models/merchant_match_entry.dart` |
| `lib/features/analytics/domain/models/import_guard.yaml` | `monthly_report.dart` |
| `lib/features/analytics/domain/models/import_guard.yaml` | `../../../accounting/domain/models/transaction.dart` |
| `lib/features/voice/domain/models/import_guard.yaml` | `recognition_outcome.dart` |

5 insertions across 3 files. Zero `.dart` source changes.

## Verification

- `dart run custom_lint --no-fatal-infos` → **exit 0, "No issues found!"** (the failing CI step)
- `flutter analyze` → **"No issues found!"** (0 issues)

## Notes

- Cross-feature domain→domain (`analytics → accounting/.../transaction.dart`) is an
  established allowed pattern — voice's yaml already allows the same `transaction.dart`
  import with the same "no layer violation" rationale.
- Executed inline (no planner/executor subagents): a 5-line allow-list addition is
  below the threshold where GSD subagent delegation adds value (the documented
  小代码任务上 GSD anti-pattern). gsd-quick artifacts (PLAN/SUMMARY/STATE/atomic
  commit) still produced.

## Commit

- `26cf4f79` — fix(260625-gwy): whitelist 5 legit domain→domain imports for custom_lint
