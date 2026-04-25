# Audit Findings

**Total findings:** 26

## CRITICAL

### Layer Violations

| ID | File:Line | Description | Suggested Fix | tool_source |
|----|-----------|-------------|---------------|-------------|
| LV-001 | lib/features/accounting/domain/models/category_ledger_config.dart:3 | Import of 'transaction.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-002 | lib/features/accounting/domain/models/category_reorder_state.dart:3 | Import of 'category.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-003 | lib/features/accounting/domain/models/transaction_sync_mapper.dart:1 | Import of 'transaction.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-004 | lib/features/accounting/domain/models/voice_parse_result.dart:3 | Import of 'transaction.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-005 | lib/features/accounting/domain/repositories/book_repository.dart:1 | Import of '../models/book.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-006 | lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart:1 | Import of '../models/category_keyword_preference.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-007 | lib/features/accounting/domain/repositories/category_ledger_config_repository.dart:1 | Import of '../models/category_ledger_config.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-008 | lib/features/accounting/domain/repositories/category_repository.dart:1 | Import of '../models/category.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-009 | lib/features/accounting/domain/repositories/merchant_category_preference_repository.dart:1 | Import of '../models/merchant_category_preference.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-010 | lib/features/accounting/domain/repositories/transaction_repository.dart:1 | Import of '../models/transaction.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-011 | lib/features/analytics/domain/models/monthly_report.dart:3 | Import of 'daily_expense.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/analytics/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-012 | lib/features/analytics/domain/models/monthly_report.dart:4 | Import of 'month_comparison.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/analytics/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-013 | lib/features/analytics/domain/repositories/analytics_repository.dart:1 | Import of '../models/analytics_aggregate.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/analytics/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-014 | lib/features/family_sync/domain/models/group_info.dart:3 | Import of 'group_member.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/family_sync/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-015 | lib/features/family_sync/domain/repositories/group_repository.dart:1 | Import of '../models/group_info.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/family_sync/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-016 | lib/features/family_sync/domain/repositories/group_repository.dart:2 | Import of '../models/group_member.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/family_sync/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-017 | lib/features/family_sync/use_cases/check_group_use_case.dart:1 | use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md) | Move to lib/application/family_sync/. Phase 3 fix. | agent:layer |
| LV-018 | lib/features/family_sync/use_cases/deactivate_group_use_case.dart:1 | use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md) | Move to lib/application/family_sync/. Phase 3 fix. | agent:layer |
| LV-019 | lib/features/family_sync/use_cases/leave_group_use_case.dart:1 | use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md) | Move to lib/application/family_sync/. Phase 3 fix. | agent:layer |
| LV-020 | lib/features/family_sync/use_cases/regenerate_invite_use_case.dart:1 | use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md) | Move to lib/application/family_sync/. Phase 3 fix. | agent:layer |
| LV-021 | lib/features/family_sync/use_cases/remove_member_use_case.dart:1 | use_cases/ inside features/ violates Thin Feature rule (CLAUDE.md) | Move to lib/application/family_sync/. Phase 3 fix. | agent:layer |
| LV-022 | lib/features/home/domain/models/ledger_row_data.dart:1 | Import of 'dart:ui' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/home/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-023 | lib/features/profile/domain/repositories/user_profile_repository.dart:1 | Import of '../models/user_profile.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/profile/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |
| LV-024 | lib/features/settings/domain/repositories/settings_repository.dart:1 | Import of '../models/app_settings.dart' is not allowed by '/Users/xinz/Development/home-pocket-app/lib/features/settings/domain/import_guard.yaml'. | Move/refactor to satisfy the layer rule. | import_guard |

## MEDIUM

### Redundant Code

| ID | File:Line | Description | Suggested Fix | tool_source |
|----|-----------|-------------|---------------|-------------|
| RD-001 | lib/application/accounting/category_service.dart:1 | Duplicate CategoryService class — parallel implementation at lib/infrastructure/category/category_service.dart | See companion finding on lib/infrastructure/category/category_service.dart. Phase 6 fix. | agent:duplication |
| RD-002 | lib/infrastructure/category/category_service.dart:1 | Duplicate CategoryService class — parallel implementation also exists at lib/application/accounting/category_service.dart with overlapping responsibilities | Rename one of the two to reflect its actual concern (e.g., CategoryLocaleFormatter vs CategoryClassifier), or consolidate. Phase 6 fix. | agent:duplication |

