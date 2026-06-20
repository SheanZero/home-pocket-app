// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AnalyticsDao provider — single source of truth.

@ProviderFor(analyticsDao)
final analyticsDaoProvider = AnalyticsDaoProvider._();

/// AnalyticsDao provider — single source of truth.

final class AnalyticsDaoProvider
    extends $FunctionalProvider<AnalyticsDao, AnalyticsDao, AnalyticsDao>
    with $Provider<AnalyticsDao> {
  /// AnalyticsDao provider — single source of truth.
  AnalyticsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsDaoHash();

  @$internal
  @override
  $ProviderElement<AnalyticsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsDao create(Ref ref) {
    return analyticsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsDao>(value),
    );
  }
}

String _$analyticsDaoHash() => r'7752a816e7935181050dc28cc48cee92385c13e1';

/// GetMonthlyReportUseCase provider.

@ProviderFor(getMonthlyReportUseCase)
final getMonthlyReportUseCaseProvider = GetMonthlyReportUseCaseProvider._();

/// GetMonthlyReportUseCase provider.

final class GetMonthlyReportUseCaseProvider
    extends
        $FunctionalProvider<
          GetMonthlyReportUseCase,
          GetMonthlyReportUseCase,
          GetMonthlyReportUseCase
        >
    with $Provider<GetMonthlyReportUseCase> {
  /// GetMonthlyReportUseCase provider.
  GetMonthlyReportUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMonthlyReportUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getMonthlyReportUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMonthlyReportUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetMonthlyReportUseCase create(Ref ref) {
    return getMonthlyReportUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMonthlyReportUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetMonthlyReportUseCase>(value),
    );
  }
}

String _$getMonthlyReportUseCaseHash() =>
    r'ba1bdbe33efe416704852d870225a34fc24cde98';

/// GetBudgetProgressUseCase provider.

@ProviderFor(getBudgetProgressUseCase)
final getBudgetProgressUseCaseProvider = GetBudgetProgressUseCaseProvider._();

/// GetBudgetProgressUseCase provider.

final class GetBudgetProgressUseCaseProvider
    extends
        $FunctionalProvider<
          GetBudgetProgressUseCase,
          GetBudgetProgressUseCase,
          GetBudgetProgressUseCase
        >
    with $Provider<GetBudgetProgressUseCase> {
  /// GetBudgetProgressUseCase provider.
  GetBudgetProgressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getBudgetProgressUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getBudgetProgressUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetBudgetProgressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetBudgetProgressUseCase create(Ref ref) {
    return getBudgetProgressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetBudgetProgressUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetBudgetProgressUseCase>(value),
    );
  }
}

String _$getBudgetProgressUseCaseHash() =>
    r'dec07f59ecb73ca73f6ee2b53912485c78ed23e1';

/// OVW-02 / D-E1: GetWithinMonthCumulativeUseCase provider.
///
/// Injects the transaction repository directly (NOT analyticsRepository): the
/// within-month trend reuses `findByBookIds` over a 2-month window with a
/// Dart-side per-day per-ledger cumulative transform. Replaces the deleted
/// 6-month `getExpenseTrendUseCase` (D-E2 — the 6-month MonthlyTrend/BarChart
/// stack is removed; round-5 B needs per-day cumulative, not per-month totals).

@ProviderFor(getWithinMonthCumulativeUseCase)
final getWithinMonthCumulativeUseCaseProvider =
    GetWithinMonthCumulativeUseCaseProvider._();

/// OVW-02 / D-E1: GetWithinMonthCumulativeUseCase provider.
///
/// Injects the transaction repository directly (NOT analyticsRepository): the
/// within-month trend reuses `findByBookIds` over a 2-month window with a
/// Dart-side per-day per-ledger cumulative transform. Replaces the deleted
/// 6-month `getExpenseTrendUseCase` (D-E2 — the 6-month MonthlyTrend/BarChart
/// stack is removed; round-5 B needs per-day cumulative, not per-month totals).

final class GetWithinMonthCumulativeUseCaseProvider
    extends
        $FunctionalProvider<
          GetWithinMonthCumulativeUseCase,
          GetWithinMonthCumulativeUseCase,
          GetWithinMonthCumulativeUseCase
        >
    with $Provider<GetWithinMonthCumulativeUseCase> {
  /// OVW-02 / D-E1: GetWithinMonthCumulativeUseCase provider.
  ///
  /// Injects the transaction repository directly (NOT analyticsRepository): the
  /// within-month trend reuses `findByBookIds` over a 2-month window with a
  /// Dart-side per-day per-ledger cumulative transform. Replaces the deleted
  /// 6-month `getExpenseTrendUseCase` (D-E2 — the 6-month MonthlyTrend/BarChart
  /// stack is removed; round-5 B needs per-day cumulative, not per-month totals).
  GetWithinMonthCumulativeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getWithinMonthCumulativeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getWithinMonthCumulativeUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetWithinMonthCumulativeUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetWithinMonthCumulativeUseCase create(Ref ref) {
    return getWithinMonthCumulativeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetWithinMonthCumulativeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetWithinMonthCumulativeUseCase>(
        value,
      ),
    );
  }
}

String _$getWithinMonthCumulativeUseCaseHash() =>
    r'f61e23cec92cc866d489113451a12798501af67d';

/// DRILL-01 / D-01..D-06, D-11: GetCategoryDrillDownUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the drill reuses `findByBookIds` directly with a Dart-side L1 filter, and the
/// summary subtotal/count come from Plan 01's shared `l1RollupFromTransactions`.

@ProviderFor(getCategoryDrillDownUseCase)
final getCategoryDrillDownUseCaseProvider =
    GetCategoryDrillDownUseCaseProvider._();

/// DRILL-01 / D-01..D-06, D-11: GetCategoryDrillDownUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the drill reuses `findByBookIds` directly with a Dart-side L1 filter, and the
/// summary subtotal/count come from Plan 01's shared `l1RollupFromTransactions`.

final class GetCategoryDrillDownUseCaseProvider
    extends
        $FunctionalProvider<
          GetCategoryDrillDownUseCase,
          GetCategoryDrillDownUseCase,
          GetCategoryDrillDownUseCase
        >
    with $Provider<GetCategoryDrillDownUseCase> {
  /// DRILL-01 / D-01..D-06, D-11: GetCategoryDrillDownUseCase provider.
  ///
  /// Injects the transaction + category repositories (NOT analyticsRepository):
  /// the drill reuses `findByBookIds` directly with a Dart-side L1 filter, and the
  /// summary subtotal/count come from Plan 01's shared `l1RollupFromTransactions`.
  GetCategoryDrillDownUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCategoryDrillDownUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCategoryDrillDownUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCategoryDrillDownUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCategoryDrillDownUseCase create(Ref ref) {
    return getCategoryDrillDownUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCategoryDrillDownUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCategoryDrillDownUseCase>(value),
    );
  }
}

String _$getCategoryDrillDownUseCaseHash() =>
    r'5e6e6178adc8f95a2ddafe0a1ab1ca2a1c348365';

/// JOY-02 / D-C2: GetJoyCategoryAmountsUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the joy-amount rollup reuses `findByBookIds(ledgerType: joy)` directly with a
/// Dart-side L1 filter through the locked `l1RollupFromTransactions` (D-11).

@ProviderFor(getJoyCategoryAmountsUseCase)
final getJoyCategoryAmountsUseCaseProvider =
    GetJoyCategoryAmountsUseCaseProvider._();

/// JOY-02 / D-C2: GetJoyCategoryAmountsUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the joy-amount rollup reuses `findByBookIds(ledgerType: joy)` directly with a
/// Dart-side L1 filter through the locked `l1RollupFromTransactions` (D-11).

final class GetJoyCategoryAmountsUseCaseProvider
    extends
        $FunctionalProvider<
          GetJoyCategoryAmountsUseCase,
          GetJoyCategoryAmountsUseCase,
          GetJoyCategoryAmountsUseCase
        >
    with $Provider<GetJoyCategoryAmountsUseCase> {
  /// JOY-02 / D-C2: GetJoyCategoryAmountsUseCase provider.
  ///
  /// Injects the transaction + category repositories (NOT analyticsRepository):
  /// the joy-amount rollup reuses `findByBookIds(ledgerType: joy)` directly with a
  /// Dart-side L1 filter through the locked `l1RollupFromTransactions` (D-11).
  GetJoyCategoryAmountsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getJoyCategoryAmountsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getJoyCategoryAmountsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetJoyCategoryAmountsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetJoyCategoryAmountsUseCase create(Ref ref) {
    return getJoyCategoryAmountsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetJoyCategoryAmountsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetJoyCategoryAmountsUseCase>(value),
    );
  }
}

String _$getJoyCategoryAmountsUseCaseHash() =>
    r'4712f1c44d3966a716df41ac7da3dffe8211e104';

/// JOY-01 / D-C1: GetPerDayJoyCountsUseCase provider.
///
/// Injects the transaction repository directly: per-day joy COUNT reuses
/// `findByBookIds(ledgerType: joy)` with a Dart-side group-by-local-day count —
/// NOT the unfiltered daily-totals SQL aggregate (Pitfall 3). No new DAO, no
/// migration.

@ProviderFor(getPerDayJoyCountsUseCase)
final getPerDayJoyCountsUseCaseProvider = GetPerDayJoyCountsUseCaseProvider._();

/// JOY-01 / D-C1: GetPerDayJoyCountsUseCase provider.
///
/// Injects the transaction repository directly: per-day joy COUNT reuses
/// `findByBookIds(ledgerType: joy)` with a Dart-side group-by-local-day count —
/// NOT the unfiltered daily-totals SQL aggregate (Pitfall 3). No new DAO, no
/// migration.

final class GetPerDayJoyCountsUseCaseProvider
    extends
        $FunctionalProvider<
          GetPerDayJoyCountsUseCase,
          GetPerDayJoyCountsUseCase,
          GetPerDayJoyCountsUseCase
        >
    with $Provider<GetPerDayJoyCountsUseCase> {
  /// JOY-01 / D-C1: GetPerDayJoyCountsUseCase provider.
  ///
  /// Injects the transaction repository directly: per-day joy COUNT reuses
  /// `findByBookIds(ledgerType: joy)` with a Dart-side group-by-local-day count —
  /// NOT the unfiltered daily-totals SQL aggregate (Pitfall 3). No new DAO, no
  /// migration.
  GetPerDayJoyCountsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getPerDayJoyCountsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getPerDayJoyCountsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPerDayJoyCountsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetPerDayJoyCountsUseCase create(Ref ref) {
    return getPerDayJoyCountsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPerDayJoyCountsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPerDayJoyCountsUseCase>(value),
    );
  }
}

String _$getPerDayJoyCountsUseCaseHash() =>
    r'44b10010225efeb773093026f2752178835d3707';

/// STATSUI-DONUT-MEMBER / D2: GetMemberSpendBreakdownUseCase provider.
///
/// Injects the transaction repository directly: per-member spend reuses
/// `findByBookIds` (both ledgers) with a Dart-side expense + group-by-deviceId
/// aggregate. No new DAO, no migration (schema stays v21).

@ProviderFor(getMemberSpendBreakdownUseCase)
final getMemberSpendBreakdownUseCaseProvider =
    GetMemberSpendBreakdownUseCaseProvider._();

/// STATSUI-DONUT-MEMBER / D2: GetMemberSpendBreakdownUseCase provider.
///
/// Injects the transaction repository directly: per-member spend reuses
/// `findByBookIds` (both ledgers) with a Dart-side expense + group-by-deviceId
/// aggregate. No new DAO, no migration (schema stays v21).

final class GetMemberSpendBreakdownUseCaseProvider
    extends
        $FunctionalProvider<
          GetMemberSpendBreakdownUseCase,
          GetMemberSpendBreakdownUseCase,
          GetMemberSpendBreakdownUseCase
        >
    with $Provider<GetMemberSpendBreakdownUseCase> {
  /// STATSUI-DONUT-MEMBER / D2: GetMemberSpendBreakdownUseCase provider.
  ///
  /// Injects the transaction repository directly: per-member spend reuses
  /// `findByBookIds` (both ledgers) with a Dart-side expense + group-by-deviceId
  /// aggregate. No new DAO, no migration (schema stays v21).
  GetMemberSpendBreakdownUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMemberSpendBreakdownUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getMemberSpendBreakdownUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMemberSpendBreakdownUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetMemberSpendBreakdownUseCase create(Ref ref) {
    return getMemberSpendBreakdownUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMemberSpendBreakdownUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetMemberSpendBreakdownUseCase>(
        value,
      ),
    );
  }
}

String _$getMemberSpendBreakdownUseCaseHash() =>
    r'f696a91b3474f4d04529ffa402d46235f3e511fb';

/// HAPPY-01..04: GetHappinessReportUseCase provider.

@ProviderFor(getHappinessReportUseCase)
final getHappinessReportUseCaseProvider = GetHappinessReportUseCaseProvider._();

/// HAPPY-01..04: GetHappinessReportUseCase provider.

final class GetHappinessReportUseCaseProvider
    extends
        $FunctionalProvider<
          GetHappinessReportUseCase,
          GetHappinessReportUseCase,
          GetHappinessReportUseCase
        >
    with $Provider<GetHappinessReportUseCase> {
  /// HAPPY-01..04: GetHappinessReportUseCase provider.
  GetHappinessReportUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getHappinessReportUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getHappinessReportUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetHappinessReportUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetHappinessReportUseCase create(Ref ref) {
    return getHappinessReportUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetHappinessReportUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetHappinessReportUseCase>(value),
    );
  }
}

String _$getHappinessReportUseCaseHash() =>
    r'15d49cc3064fdd42c1795c7d6d71f538e13315dd';

/// JOYMIG-02 / D-04: GetMonthlyJoyTargetRecommendationUseCase provider.

@ProviderFor(getMonthlyJoyTargetRecommendationUseCase)
final getMonthlyJoyTargetRecommendationUseCaseProvider =
    GetMonthlyJoyTargetRecommendationUseCaseProvider._();

/// JOYMIG-02 / D-04: GetMonthlyJoyTargetRecommendationUseCase provider.

final class GetMonthlyJoyTargetRecommendationUseCaseProvider
    extends
        $FunctionalProvider<
          GetMonthlyJoyTargetRecommendationUseCase,
          GetMonthlyJoyTargetRecommendationUseCase,
          GetMonthlyJoyTargetRecommendationUseCase
        >
    with $Provider<GetMonthlyJoyTargetRecommendationUseCase> {
  /// JOYMIG-02 / D-04: GetMonthlyJoyTargetRecommendationUseCase provider.
  GetMonthlyJoyTargetRecommendationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMonthlyJoyTargetRecommendationUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$getMonthlyJoyTargetRecommendationUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMonthlyJoyTargetRecommendationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetMonthlyJoyTargetRecommendationUseCase create(Ref ref) {
    return getMonthlyJoyTargetRecommendationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMonthlyJoyTargetRecommendationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GetMonthlyJoyTargetRecommendationUseCase>(value),
    );
  }
}

String _$getMonthlyJoyTargetRecommendationUseCaseHash() =>
    r'd8940e9f1c5d56ee7d00a5fde540944ccb43428b';

/// STATSUI-02 / D-05: GetSatisfactionDistributionUseCase provider.

@ProviderFor(getSatisfactionDistributionUseCase)
final getSatisfactionDistributionUseCaseProvider =
    GetSatisfactionDistributionUseCaseProvider._();

/// STATSUI-02 / D-05: GetSatisfactionDistributionUseCase provider.

final class GetSatisfactionDistributionUseCaseProvider
    extends
        $FunctionalProvider<
          GetSatisfactionDistributionUseCase,
          GetSatisfactionDistributionUseCase,
          GetSatisfactionDistributionUseCase
        >
    with $Provider<GetSatisfactionDistributionUseCase> {
  /// STATSUI-02 / D-05: GetSatisfactionDistributionUseCase provider.
  GetSatisfactionDistributionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSatisfactionDistributionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$getSatisfactionDistributionUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSatisfactionDistributionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSatisfactionDistributionUseCase create(Ref ref) {
    return getSatisfactionDistributionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSatisfactionDistributionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSatisfactionDistributionUseCase>(
        value,
      ),
    );
  }
}

String _$getSatisfactionDistributionUseCaseHash() =>
    r'c365f2ba9dba19868c355b237ee87adc705d7898';

/// HAPPY-04: GetBestJoyMomentUseCase provider.

@ProviderFor(getBestJoyMomentUseCase)
final getBestJoyMomentUseCaseProvider = GetBestJoyMomentUseCaseProvider._();

/// HAPPY-04: GetBestJoyMomentUseCase provider.

final class GetBestJoyMomentUseCaseProvider
    extends
        $FunctionalProvider<
          GetBestJoyMomentUseCase,
          GetBestJoyMomentUseCase,
          GetBestJoyMomentUseCase
        >
    with $Provider<GetBestJoyMomentUseCase> {
  /// HAPPY-04: GetBestJoyMomentUseCase provider.
  GetBestJoyMomentUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getBestJoyMomentUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getBestJoyMomentUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetBestJoyMomentUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetBestJoyMomentUseCase create(Ref ref) {
    return getBestJoyMomentUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetBestJoyMomentUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetBestJoyMomentUseCase>(value),
    );
  }
}

String _$getBestJoyMomentUseCaseHash() =>
    r'771dd6a48a0acc165f59d7605be955df501f6764';

/// STATSUI-06 / D-15: GetLargestMonthlyExpenseUseCase provider.

@ProviderFor(getLargestMonthlyExpenseUseCase)
final getLargestMonthlyExpenseUseCaseProvider =
    GetLargestMonthlyExpenseUseCaseProvider._();

/// STATSUI-06 / D-15: GetLargestMonthlyExpenseUseCase provider.

final class GetLargestMonthlyExpenseUseCaseProvider
    extends
        $FunctionalProvider<
          GetLargestMonthlyExpenseUseCase,
          GetLargestMonthlyExpenseUseCase,
          GetLargestMonthlyExpenseUseCase
        >
    with $Provider<GetLargestMonthlyExpenseUseCase> {
  /// STATSUI-06 / D-15: GetLargestMonthlyExpenseUseCase provider.
  GetLargestMonthlyExpenseUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getLargestMonthlyExpenseUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getLargestMonthlyExpenseUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetLargestMonthlyExpenseUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetLargestMonthlyExpenseUseCase create(Ref ref) {
    return getLargestMonthlyExpenseUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetLargestMonthlyExpenseUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetLargestMonthlyExpenseUseCase>(
        value,
      ),
    );
  }
}

String _$getLargestMonthlyExpenseUseCaseHash() =>
    r'668d2dd01bbbb4d5d03561f596be122301408893';

/// FAMILY-01..02: GetFamilyHappinessUseCase provider.

@ProviderFor(getFamilyHappinessUseCase)
final getFamilyHappinessUseCaseProvider = GetFamilyHappinessUseCaseProvider._();

/// FAMILY-01..02: GetFamilyHappinessUseCase provider.

final class GetFamilyHappinessUseCaseProvider
    extends
        $FunctionalProvider<
          GetFamilyHappinessUseCase,
          GetFamilyHappinessUseCase,
          GetFamilyHappinessUseCase
        >
    with $Provider<GetFamilyHappinessUseCase> {
  /// FAMILY-01..02: GetFamilyHappinessUseCase provider.
  GetFamilyHappinessUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getFamilyHappinessUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getFamilyHappinessUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetFamilyHappinessUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetFamilyHappinessUseCase create(Ref ref) {
    return getFamilyHappinessUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetFamilyHappinessUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetFamilyHappinessUseCase>(value),
    );
  }
}

String _$getFamilyHappinessUseCaseHash() =>
    r'3b15f9eed8685f06f2e98a20b4c92bff4c96a0f4';

/// HAPPY-V2-01 / D-07: per-category joy satisfaction breakdown use case provider.

@ProviderFor(getPerCategoryJoyBreakdownUseCase)
final getPerCategoryJoyBreakdownUseCaseProvider =
    GetPerCategoryJoyBreakdownUseCaseProvider._();

/// HAPPY-V2-01 / D-07: per-category joy satisfaction breakdown use case provider.

final class GetPerCategoryJoyBreakdownUseCaseProvider
    extends
        $FunctionalProvider<
          GetPerCategoryJoyBreakdownUseCase,
          GetPerCategoryJoyBreakdownUseCase,
          GetPerCategoryJoyBreakdownUseCase
        >
    with $Provider<GetPerCategoryJoyBreakdownUseCase> {
  /// HAPPY-V2-01 / D-07: per-category joy satisfaction breakdown use case provider.
  GetPerCategoryJoyBreakdownUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getPerCategoryJoyBreakdownUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$getPerCategoryJoyBreakdownUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPerCategoryJoyBreakdownUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetPerCategoryJoyBreakdownUseCase create(Ref ref) {
    return getPerCategoryJoyBreakdownUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPerCategoryJoyBreakdownUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPerCategoryJoyBreakdownUseCase>(
        value,
      ),
    );
  }
}

String _$getPerCategoryJoyBreakdownUseCaseHash() =>
    r'9c3a3db204ce7fc69cb53cc5fc07c2446cbbed1c';

/// HAPPY-V2-01 / D-16, D-17: family-aggregate per-category breakdown use case provider.

@ProviderFor(getPerCategoryJoyBreakdownAcrossBooksUseCase)
final getPerCategoryJoyBreakdownAcrossBooksUseCaseProvider =
    GetPerCategoryJoyBreakdownAcrossBooksUseCaseProvider._();

/// HAPPY-V2-01 / D-16, D-17: family-aggregate per-category breakdown use case provider.

final class GetPerCategoryJoyBreakdownAcrossBooksUseCaseProvider
    extends
        $FunctionalProvider<
          GetPerCategoryJoyBreakdownAcrossBooksUseCase,
          GetPerCategoryJoyBreakdownAcrossBooksUseCase,
          GetPerCategoryJoyBreakdownAcrossBooksUseCase
        >
    with $Provider<GetPerCategoryJoyBreakdownAcrossBooksUseCase> {
  /// HAPPY-V2-01 / D-16, D-17: family-aggregate per-category breakdown use case provider.
  GetPerCategoryJoyBreakdownAcrossBooksUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getPerCategoryJoyBreakdownAcrossBooksUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$getPerCategoryJoyBreakdownAcrossBooksUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPerCategoryJoyBreakdownAcrossBooksUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetPerCategoryJoyBreakdownAcrossBooksUseCase create(Ref ref) {
    return getPerCategoryJoyBreakdownAcrossBooksUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    GetPerCategoryJoyBreakdownAcrossBooksUseCase value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GetPerCategoryJoyBreakdownAcrossBooksUseCase>(
            value,
          ),
    );
  }
}

String _$getPerCategoryJoyBreakdownAcrossBooksUseCaseHash() =>
    r'81ed071d7120510661339cf3744ce51dca7b6e5f';

/// STATSUI-V2-01 / D-01..D-05: Daily-vs-Joy engagement snapshot use case provider.

@ProviderFor(getDailyVsJoySnapshotUseCase)
final getDailyVsJoySnapshotUseCaseProvider =
    GetDailyVsJoySnapshotUseCaseProvider._();

/// STATSUI-V2-01 / D-01..D-05: Daily-vs-Joy engagement snapshot use case provider.

final class GetDailyVsJoySnapshotUseCaseProvider
    extends
        $FunctionalProvider<
          GetDailyVsJoySnapshotUseCase,
          GetDailyVsJoySnapshotUseCase,
          GetDailyVsJoySnapshotUseCase
        >
    with $Provider<GetDailyVsJoySnapshotUseCase> {
  /// STATSUI-V2-01 / D-01..D-05: Daily-vs-Joy engagement snapshot use case provider.
  GetDailyVsJoySnapshotUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getDailyVsJoySnapshotUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getDailyVsJoySnapshotUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetDailyVsJoySnapshotUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetDailyVsJoySnapshotUseCase create(Ref ref) {
    return getDailyVsJoySnapshotUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetDailyVsJoySnapshotUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetDailyVsJoySnapshotUseCase>(value),
    );
  }
}

String _$getDailyVsJoySnapshotUseCaseHash() =>
    r'd4d4d8bf0517e3e51bbfe7841dc0f01e306880ec';

/// STATSUI-V2-01 / D-18, D-20: family-aggregate Daily-vs-Joy snapshot use case provider.

@ProviderFor(getDailyVsJoySnapshotAcrossBooksUseCase)
final getDailyVsJoySnapshotAcrossBooksUseCaseProvider =
    GetDailyVsJoySnapshotAcrossBooksUseCaseProvider._();

/// STATSUI-V2-01 / D-18, D-20: family-aggregate Daily-vs-Joy snapshot use case provider.

final class GetDailyVsJoySnapshotAcrossBooksUseCaseProvider
    extends
        $FunctionalProvider<
          GetDailyVsJoySnapshotAcrossBooksUseCase,
          GetDailyVsJoySnapshotAcrossBooksUseCase,
          GetDailyVsJoySnapshotAcrossBooksUseCase
        >
    with $Provider<GetDailyVsJoySnapshotAcrossBooksUseCase> {
  /// STATSUI-V2-01 / D-18, D-20: family-aggregate Daily-vs-Joy snapshot use case provider.
  GetDailyVsJoySnapshotAcrossBooksUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getDailyVsJoySnapshotAcrossBooksUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$getDailyVsJoySnapshotAcrossBooksUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetDailyVsJoySnapshotAcrossBooksUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetDailyVsJoySnapshotAcrossBooksUseCase create(Ref ref) {
    return getDailyVsJoySnapshotAcrossBooksUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetDailyVsJoySnapshotAcrossBooksUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GetDailyVsJoySnapshotAcrossBooksUseCase>(value),
    );
  }
}

String _$getDailyVsJoySnapshotAcrossBooksUseCaseHash() =>
    r'cebe2f2b1d220a763360740ba985f38cd2d50400';
