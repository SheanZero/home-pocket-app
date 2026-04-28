# Re-Audit Diff Report

**Resolved:** 50
**Regression:** 0
**New:** 0
**Open in Baseline:** 0

---

## Resolved (50)

### CRITICAL

#### Layer Violations

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

### MEDIUM

#### Redundant Code

| ID | File:Line | Description | Suggested Fix | tool_source |
|----|-----------|-------------|---------------|-------------|
| RD-001 | lib/application/accounting/category_service.dart:1 | Duplicate CategoryService class — parallel implementation at lib/infrastructure/category/category_service.dart | See companion finding on lib/infrastructure/category/category_service.dart. Phase 6 fix. | agent:duplication |
| RD-002 | lib/infrastructure/category/category_service.dart:1 | Duplicate CategoryService class — parallel implementation also exists at lib/application/accounting/category_service.dart with overlapping responsibilities | Rename one of the two to reflect its actual concern (e.g., CategoryLocaleFormatter vs CategoryClassifier), or consolidate. Phase 6 fix. | agent:duplication |

### LOW

#### Dead Code

| ID | File:Line | Description | Suggested Fix | tool_source |
|----|-----------|-------------|---------------|-------------|
| DC-001 | lib/application/home/repository_providers.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-002 | lib/application/settings/repository_providers.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-004 | lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart:9 | Unused class `DualLedgerScreen` | Remove the unused declaration or export it. | dart_code_linter |
| DC-003 | lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-005 | lib/features/family_sync/domain/models/sync_message.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-006 | lib/features/family_sync/domain/models/sync_trigger_event.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-007 | lib/features/family_sync/presentation/providers/repository_providers.dart:294 | Unused top level variable `regenerateInviteUseCaseProvider` | Remove the unused declaration or export it. | dart_code_linter |
| DC-009 | lib/features/family_sync/presentation/screens/join_success_screen.dart:16 | Unused class `JoinSuccessScreen` | Remove the unused declaration or export it. | dart_code_linter |
| DC-008 | lib/features/family_sync/presentation/screens/join_success_screen.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-011 | lib/features/family_sync/presentation/widgets/member_avatar.dart:5 | Unused class `MemberAvatar` | Remove the unused declaration or export it. | dart_code_linter |
| DC-010 | lib/features/family_sync/presentation/widgets/member_avatar.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-013 | lib/features/family_sync/presentation/widgets/pair_code_display.dart:12 | Unused class `PairCodeDisplay` | Remove the unused declaration or export it. | dart_code_linter |
| DC-012 | lib/features/family_sync/presentation/widgets/pair_code_display.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-015 | lib/features/family_sync/presentation/widgets/pair_code_input.dart:9 | Unused class `PairCodeInput` | Remove the unused declaration or export it. | dart_code_linter |
| DC-014 | lib/features/family_sync/presentation/widgets/pair_code_input.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-017 | lib/features/family_sync/presentation/widgets/partner_device_tile.dart:6 | Unused class `PartnerDeviceTile` | Remove the unused declaration or export it. | dart_code_linter |
| DC-016 | lib/features/family_sync/presentation/widgets/partner_device_tile.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-019 | lib/features/family_sync/presentation/widgets/status_badge.dart:3 | Unused class `StatusBadge` | Remove the unused declaration or export it. | dart_code_linter |
| DC-018 | lib/features/family_sync/presentation/widgets/status_badge.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-021 | lib/features/family_sync/presentation/widgets/sync_stats_card.dart:5 | Unused class `SyncStatsCard` | Remove the unused declaration or export it. | dart_code_linter |
| DC-020 | lib/features/family_sync/presentation/widgets/sync_stats_card.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-023 | lib/features/home/presentation/widgets/group_bar.dart:8 | Unused class `GroupBar` | Remove the unused declaration or export it. | dart_code_linter |
| DC-022 | lib/features/home/presentation/widgets/group_bar.dart:1 | Unused file (no incoming imports detected) | Delete the file if truly unused. | dart_code_linter |
| DC-024 | lib/infrastructure/crypto/repositories/master_key_repository.dart:14 | Unused class `KeyDerivationException` | Remove the unused declaration or export it. | dart_code_linter |

## Regression (0)

_None._

## New (0)

_None._

## Still Open in Baseline (0)

_None._

