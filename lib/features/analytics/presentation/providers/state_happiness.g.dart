// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_happiness.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// HAPPY-01..04 personal happiness report.

@ProviderFor(happinessReport)
final happinessReportProvider = HappinessReportFamily._();

/// HAPPY-01..04 personal happiness report.

final class HappinessReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<HappinessReport>,
          HappinessReport,
          FutureOr<HappinessReport>
        >
    with $FutureModifier<HappinessReport>, $FutureProvider<HappinessReport> {
  /// HAPPY-01..04 personal happiness report.
  HappinessReportProvider._({
    required HappinessReportFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      String currencyCode,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'happinessReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$happinessReportHash();

  @override
  String toString() {
    return r'happinessReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<HappinessReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HappinessReport> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              String currencyCode,
            });
    return happinessReport(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      currencyCode: argument.currencyCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HappinessReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$happinessReportHash() => r'236f5372581442f06baf87749750e24547ae4764';

/// HAPPY-01..04 personal happiness report.

final class HappinessReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<HappinessReport>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            String currencyCode,
          })
        > {
  HappinessReportFamily._()
    : super(
        retry: null,
        name: r'happinessReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// HAPPY-01..04 personal happiness report.

  HappinessReportProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    required String currencyCode,
  }) => HappinessReportProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      currencyCode: currencyCode,
    ),
    from: this,
  );

  @override
  String toString() => r'happinessReportProvider';
}

/// HAPPY-04 standalone Top Joy.

@ProviderFor(bestJoyMoment)
final bestJoyMomentProvider = BestJoyMomentFamily._();

/// HAPPY-04 standalone Top Joy.

final class BestJoyMomentProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<BestJoyMomentRow>>,
          MetricResult<BestJoyMomentRow>,
          FutureOr<MetricResult<BestJoyMomentRow>>
        >
    with
        $FutureModifier<MetricResult<BestJoyMomentRow>>,
        $FutureProvider<MetricResult<BestJoyMomentRow>> {
  /// HAPPY-04 standalone Top Joy.
  BestJoyMomentProvider._({
    required BestJoyMomentFamily super.from,
    required ({String bookId, DateTime startDate, DateTime endDate})
    super.argument,
  }) : super(
         retry: null,
         name: r'bestJoyMomentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bestJoyMomentHash();

  @override
  String toString() {
    return r'bestJoyMomentProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<BestJoyMomentRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<BestJoyMomentRow>> create(Ref ref) {
    final argument =
        this.argument
            as ({String bookId, DateTime startDate, DateTime endDate});
    return bestJoyMoment(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BestJoyMomentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bestJoyMomentHash() => r'32dd35a5d11b9ad591f5fc758d26254c6c7689e1';

/// HAPPY-04 standalone Top Joy.

final class BestJoyMomentFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<BestJoyMomentRow>>,
          ({String bookId, DateTime startDate, DateTime endDate})
        > {
  BestJoyMomentFamily._()
    : super(
        retry: null,
        name: r'bestJoyMomentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// HAPPY-04 standalone Top Joy.

  BestJoyMomentProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) => BestJoyMomentProvider._(
    argument: (bookId: bookId, startDate: startDate, endDate: endDate),
    from: this,
  );

  @override
  String toString() => r'bestJoyMomentProvider';
}

/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
///
/// Returns Empty when fewer than 3 past months have soul transaction data.

@ProviderFor(monthlyJoyTargetRecommendation)
final monthlyJoyTargetRecommendationProvider =
    MonthlyJoyTargetRecommendationFamily._();

/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
///
/// Returns Empty when fewer than 3 past months have soul transaction data.

final class MonthlyJoyTargetRecommendationProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<int>>,
          MetricResult<int>,
          FutureOr<MetricResult<int>>
        >
    with
        $FutureModifier<MetricResult<int>>,
        $FutureProvider<MetricResult<int>> {
  /// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
  ///
  /// Returns Empty when fewer than 3 past months have soul transaction data.
  MonthlyJoyTargetRecommendationProvider._({
    required MonthlyJoyTargetRecommendationFamily super.from,
    required ({String bookId, String currencyCode}) super.argument,
  }) : super(
         retry: null,
         name: r'monthlyJoyTargetRecommendationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyJoyTargetRecommendationHash();

  @override
  String toString() {
    return r'monthlyJoyTargetRecommendationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<int>> create(Ref ref) {
    final argument = this.argument as ({String bookId, String currencyCode});
    return monthlyJoyTargetRecommendation(
      ref,
      bookId: argument.bookId,
      currencyCode: argument.currencyCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyJoyTargetRecommendationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyJoyTargetRecommendationHash() =>
    r'43a04b4e788697bb3b9c72773789822c8528dbe6';

/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
///
/// Returns Empty when fewer than 3 past months have soul transaction data.

final class MonthlyJoyTargetRecommendationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<int>>,
          ({String bookId, String currencyCode})
        > {
  MonthlyJoyTargetRecommendationFamily._()
    : super(
        retry: null,
        name: r'monthlyJoyTargetRecommendationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
  ///
  /// Returns Empty when fewer than 3 past months have soul transaction data.

  MonthlyJoyTargetRecommendationProvider call({
    required String bookId,
    required String currencyCode,
  }) => MonthlyJoyTargetRecommendationProvider._(
    argument: (bookId: bookId, currencyCode: currencyCode),
    from: this,
  );

  @override
  String toString() => r'monthlyJoyTargetRecommendationProvider';
}

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.

@ProviderFor(largestMonthlyExpense)
final largestMonthlyExpenseProvider = LargestMonthlyExpenseFamily._();

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.

final class LargestMonthlyExpenseProvider
    extends
        $FunctionalProvider<
          AsyncValue<LargestMonthlyExpense?>,
          LargestMonthlyExpense?,
          FutureOr<LargestMonthlyExpense?>
        >
    with
        $FutureModifier<LargestMonthlyExpense?>,
        $FutureProvider<LargestMonthlyExpense?> {
  /// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
  LargestMonthlyExpenseProvider._({
    required LargestMonthlyExpenseFamily super.from,
    required ({String bookId, DateTime startDate, DateTime endDate})
    super.argument,
  }) : super(
         retry: null,
         name: r'largestMonthlyExpenseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$largestMonthlyExpenseHash();

  @override
  String toString() {
    return r'largestMonthlyExpenseProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<LargestMonthlyExpense?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LargestMonthlyExpense?> create(Ref ref) {
    final argument =
        this.argument
            as ({String bookId, DateTime startDate, DateTime endDate});
    return largestMonthlyExpense(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LargestMonthlyExpenseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$largestMonthlyExpenseHash() =>
    r'10c10dad0a1bced96cfa5c53ec560a5a7c846ec0';

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.

final class LargestMonthlyExpenseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<LargestMonthlyExpense?>,
          ({String bookId, DateTime startDate, DateTime endDate})
        > {
  LargestMonthlyExpenseFamily._()
    : super(
        retry: null,
        name: r'largestMonthlyExpenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.

  LargestMonthlyExpenseProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) => LargestMonthlyExpenseProvider._(
    argument: (bookId: bookId, startDate: startDate, endDate: endDate),
    from: this,
  );

  @override
  String toString() => r'largestMonthlyExpenseProvider';
}

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.

@ProviderFor(familyHappiness)
final familyHappinessProvider = FamilyHappinessFamily._();

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.

final class FamilyHappinessProvider
    extends
        $FunctionalProvider<
          AsyncValue<FamilyHappiness>,
          FamilyHappiness,
          FutureOr<FamilyHappiness>
        >
    with $FutureModifier<FamilyHappiness>, $FutureProvider<FamilyHappiness> {
  /// FAMILY-01..02 family happiness aggregate.
  ///
  /// D-09: presentation resolves shadow books to book IDs before invoking the
  /// use case. Q6c remains open: this currently passes shadow books only; Phase
  /// 10/11 may extend the call site if current-device book inclusion is required.
  FamilyHappinessProvider._({
    required FamilyHappinessFamily super.from,
    required ({DateTime startDate, DateTime endDate}) super.argument,
  }) : super(
         retry: null,
         name: r'familyHappinessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$familyHappinessHash();

  @override
  String toString() {
    return r'familyHappinessProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FamilyHappiness> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FamilyHappiness> create(Ref ref) {
    final argument = this.argument as ({DateTime startDate, DateTime endDate});
    return familyHappiness(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyHappinessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$familyHappinessHash() => r'3b7409409c859ea75df4540a1023fd20b53186c9';

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.

final class FamilyHappinessFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FamilyHappiness>,
          ({DateTime startDate, DateTime endDate})
        > {
  FamilyHappinessFamily._()
    : super(
        retry: null,
        name: r'familyHappinessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// FAMILY-01..02 family happiness aggregate.
  ///
  /// D-09: presentation resolves shadow books to book IDs before invoking the
  /// use case. Q6c remains open: this currently passes shadow books only; Phase
  /// 10/11 may extend the call site if current-device book inclusion is required.

  FamilyHappinessProvider call({
    required DateTime startDate,
    required DateTime endDate,
  }) => FamilyHappinessProvider._(
    argument: (startDate: startDate, endDate: endDate),
    from: this,
  );

  @override
  String toString() => r'familyHappinessProvider';
}
