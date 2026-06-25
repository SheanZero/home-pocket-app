---
quick_id: 260625-gwy
description: fix custom_lint import_guard CI failure — whitelist 5 legit domain→domain model imports
date: 2026-06-25
status: planned
---

# Quick Task 260625-gwy: Fix custom_lint import_guard CI failure

## Problem

CI step `dart run custom_lint --no-fatal-infos` failed (exit 1) with 5 `import_guard`
WARNINGS (GitHub Actions run 28139595431). All 5 are legitimate **same-layer
domain→domain model imports** that are simply absent from the per-directory
`import_guard.yaml` allow-lists. Each per-dir whitelist inherits a feature-level
deny and must explicitly re-allow sibling / cross-feature domain model imports
(same pattern as the existing `# closes LV-NNN` entries).

The 5 flagged imports:

| # | Source file | Import | Kind |
|---|-------------|--------|------|
| 1 | `accounting/domain/repositories/merchant_repository.dart:1` | `../models/merchant.dart` | intra-feature domain model |
| 2 | `accounting/domain/repositories/merchant_repository.dart:2` | `../models/merchant_match_entry.dart` | intra-feature domain model |
| 3 | `analytics/domain/models/category_drill_down.dart:3` | `../../../accounting/domain/models/transaction.dart` | cross-feature domain→domain |
| 4 | `analytics/domain/models/member_spend_breakdown.dart:1` | `monthly_report.dart` | sibling domain model |
| 5 | `voice/domain/models/voice_parse_result.dart:4` | `recognition_outcome.dart` | sibling domain model |

None is a layer violation (Domain importing Domain is allowed; cross-feature
domain→domain is an established allowed pattern — see the existing
`../../../accounting/domain/models/transaction.dart` allow in voice's yaml).
The fix is to add the missing allow-list entries.

## Task

Add the 5 missing entries to 3 `import_guard.yaml` allow-lists:

1. `lib/features/accounting/domain/repositories/import_guard.yaml`
   - `../models/merchant.dart`
   - `../models/merchant_match_entry.dart`
2. `lib/features/analytics/domain/models/import_guard.yaml`
   - `monthly_report.dart`
   - `../../../accounting/domain/models/transaction.dart`
3. `lib/features/voice/domain/models/import_guard.yaml`
   - `recognition_outcome.dart`

- **files:** the 3 yaml files above
- **action:** append allow-list entries with explanatory comments matching the
  surrounding style
- **verify:** `dart run custom_lint --no-fatal-infos` → 0 issues; `flutter analyze` → 0 issues
- **done:** custom_lint exits 0 (the CI step passes)

## Out of scope

- No source `.dart` edits (the imports are correct as-is).
- No change to feature-level deny rules or the import_guard rule itself.
