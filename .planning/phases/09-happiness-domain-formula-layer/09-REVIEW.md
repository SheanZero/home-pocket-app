---
phase: 09-happiness-domain-formula-layer
reviewed: 2026-05-02T02:04:51Z
depth: standard
files_reviewed: 44
files_reviewed_list:
  - docs/arch/03-adr/ADR-000_INDEX.md
  - docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md
  - docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md
  - docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/application/analytics/demo_data_service.dart
  - lib/application/analytics/get_best_joy_moment_use_case.dart
  - lib/application/analytics/get_family_happiness_use_case.dart
  - lib/application/analytics/get_happiness_report_use_case.dart
  - lib/data/app_database.dart
  - lib/data/app_database.g.dart
  - lib/data/daos/analytics_dao.dart
  - lib/data/daos/transaction_dao.dart
  - lib/data/repositories/analytics_repository_impl.dart
  - lib/data/tables/transactions_table.dart
  - lib/features/accounting/domain/models/transaction.dart
  - lib/features/accounting/domain/models/transaction.freezed.dart
  - lib/features/accounting/domain/models/transaction.g.dart
  - lib/features/accounting/domain/models/transaction_sync_mapper.dart
  - lib/features/accounting/presentation/screens/transaction_confirm_screen.dart
  - lib/features/analytics/domain/models/analytics_aggregate.dart
  - lib/features/analytics/domain/models/best_joy_moment_row.dart
  - lib/features/analytics/domain/models/family_happiness.dart
  - lib/features/analytics/domain/models/happiness_report.dart
  - lib/features/analytics/domain/models/metric_result.dart
  - lib/features/analytics/domain/models/shared_joy_insight.dart
  - lib/features/analytics/domain/repositories/analytics_repository.dart
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - lib/features/analytics/presentation/providers/repository_providers.g.dart
  - lib/features/analytics/presentation/providers/state_happiness.dart
  - lib/features/analytics/presentation/providers/state_happiness.g.dart
  - lib/infrastructure/i18n/formatters/joy_density_formatter.dart
  - test/unit/application/accounting/create_transaction_use_case_test.dart
  - test/unit/application/analytics/get_best_joy_moment_use_case_test.dart
  - test/unit/application/analytics/get_family_happiness_use_case_test.dart
  - test/unit/application/analytics/get_happiness_report_use_case_test.dart
  - test/unit/data/daos/analytics_dao_happiness_test.dart
  - test/unit/data/migrations/migration_v15_to_v16_test.dart
  - test/unit/data/repositories/analytics_repository_happiness_test.dart
  - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
  - test/unit/features/analytics/domain/models/happiness_report_test.dart
  - test/unit/features/analytics/domain/models/metric_result_test.dart
  - test/unit/features/analytics/presentation/providers/repository_providers_test.dart
  - test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-05-02T02:04:51Z
**Depth:** standard
**Files Reviewed:** 44
**Status:** issues_found

## Summary

Reviewed the Phase 9 happiness formula layer across ADRs, application use cases, Drift DAO/schema changes, analytics providers, generated outputs, and targeted tests. The core PTVF math, DAO filtering, repository delegation, and MetricResult packaging are coherent, but two correctness issues remain in the provider/demo paths.

## Warnings

### WR-01: Family happiness provider drops the current user's book

**File:** `lib/features/analytics/presentation/providers/state_happiness.dart:60`
**Issue:** `familyHappinessProvider` builds `groupBookIds` only from `shadowBooksProvider`, then returns an empty family report when there are no shadow books. Shadow books represent remote members, so this path excludes the current device's own book from FAMILY-01/FAMILY-02 aggregation and undercounts family metrics. For a one-member active group, or any group where the local book has qualifying soul transactions, the provider reports zero even though the use case can aggregate any supplied book IDs.
**Fix:** Include the active/local book ID in the provider contract before calling the use case. For example, make the provider accept the current book ID from the caller, then append shadow IDs:

```dart
@riverpod
Future<FamilyHappiness> familyHappiness(
  Ref ref, {
  required String currentBookId,
  required int year,
  required int month,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) {
    return _emptyFamilyHappiness(year: year, month: month);
  }

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = <String>{
    currentBookId,
    ...shadowBooks.map((shadow) => shadow.book.id),
  }.toList();

  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  return useCase.execute(groupBookIds: groupBookIds, year: year, month: month);
}
```

Add a provider test that stubs one local book plus one shadow book and verifies both IDs are passed to the analytics repository path.

### WR-02: Demo data can generate satisfaction value 1 despite v1.1 semantics

**File:** `lib/application/analytics/demo_data_service.dart:130`
**Issue:** Soul demo transactions use `1 + _random.nextInt(10)`, so demo analytics can contain `soul_satisfaction = 1`. ADR-014 explicitly leaves value `1` without v1.1 product semantics: the picker writes `{2, 4, 6, 8, 10}`, default/unrated is `2`, and `1` is not a sentinel. Demo data containing `1` will produce reports that cannot be created through the v1.1 UI and may make the new "unipolar positive" baseline look worse than intended.
**Fix:** Generate demo values from the same buckets the picker can write, or at minimum clamp to the v1.1 meaningful range:

```dart
const demoSoulSatisfactionBuckets = [2, 4, 6, 8, 10];
final satisfaction = ledgerType == 'soul'
    ? demoSoulSatisfactionBuckets[
        _random.nextInt(demoSoulSatisfactionBuckets.length)
      ]
    : 2;
```

Add a focused test for `DemoDataService` or the generated fixture path asserting soul demo rows never use `1`.

---

_Reviewed: 2026-05-02T02:04:51Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
