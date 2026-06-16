// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Monthly report for the selected window.

@ProviderFor(monthlyReport)
final monthlyReportProvider = MonthlyReportFamily._();

/// Monthly report for the selected window.

final class MonthlyReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthlyReport>,
          MonthlyReport,
          FutureOr<MonthlyReport>
        >
    with $FutureModifier<MonthlyReport>, $FutureProvider<MonthlyReport> {
  /// Monthly report for the selected window.
  MonthlyReportProvider._({
    required MonthlyReportFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'monthlyReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyReportHash();

  @override
  String toString() {
    return r'monthlyReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MonthlyReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MonthlyReport> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return monthlyReport(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyReportHash() => r'c8717c211e662147ef931407e27e2de744382378';

/// Monthly report for the selected window.

final class MonthlyReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MonthlyReport>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  MonthlyReportFamily._()
    : super(
        retry: null,
        name: r'monthlyReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Monthly report for the selected window.

  MonthlyReportProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => MonthlyReportProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'monthlyReportProvider';
}

/// 6-month expense trend.

@ProviderFor(expenseTrend)
final expenseTrendProvider = ExpenseTrendFamily._();

/// 6-month expense trend.

final class ExpenseTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExpenseTrendData>,
          ExpenseTrendData,
          FutureOr<ExpenseTrendData>
        >
    with $FutureModifier<ExpenseTrendData>, $FutureProvider<ExpenseTrendData> {
  /// 6-month expense trend.
  ExpenseTrendProvider._({
    required ExpenseTrendFamily super.from,
    required ({
      String bookId,
      DateTime anchor,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'expenseTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseTrendHash();

  @override
  String toString() {
    return r'expenseTrendProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ExpenseTrendData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExpenseTrendData> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime anchor,
              JoyMetricVariant joyMetricVariant,
            });
    return expenseTrend(
      ref,
      bookId: argument.bookId,
      anchor: argument.anchor,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseTrendHash() => r'0ff13a49235e35493e4f9c8ec5a2ffa8daeade0c';

/// 6-month expense trend.

final class ExpenseTrendFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExpenseTrendData>,
          ({String bookId, DateTime anchor, JoyMetricVariant joyMetricVariant})
        > {
  ExpenseTrendFamily._()
    : super(
        retry: null,
        name: r'expenseTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 6-month expense trend.

  ExpenseTrendProvider call({
    required String bookId,
    required DateTime anchor,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => ExpenseTrendProvider._(
    argument: (
      bookId: bookId,
      anchor: anchor,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'expenseTrendProvider';
}

/// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
/// over the active analytics window.
///
/// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
/// the window, with a neutral subtotal/count summary sourced from Plan 01's
/// shared rollup (so the header == the donut slice).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
/// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
/// would explode the family key and cause a rebuild storm. This provider defends
/// the contract by re-normalizing the bounds via [DateBoundaries] before they
/// reach the use case — never accept microsecond-exact instants into the key.
///
/// Auto-dispose (the @riverpod default here, NOT keepAlive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
/// home_screen_isolation_test.dart).

@ProviderFor(categoryDrillDown)
final categoryDrillDownProvider = CategoryDrillDownFamily._();

/// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
/// over the active analytics window.
///
/// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
/// the window, with a neutral subtotal/count summary sourced from Plan 01's
/// shared rollup (so the header == the donut slice).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
/// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
/// would explode the family key and cause a rebuild storm. This provider defends
/// the contract by re-normalizing the bounds via [DateBoundaries] before they
/// reach the use case — never accept microsecond-exact instants into the key.
///
/// Auto-dispose (the @riverpod default here, NOT keepAlive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
/// home_screen_isolation_test.dart).

final class CategoryDrillDownProvider
    extends
        $FunctionalProvider<
          AsyncValue<CategoryDrillDown>,
          CategoryDrillDown,
          FutureOr<CategoryDrillDown>
        >
    with
        $FutureModifier<CategoryDrillDown>,
        $FutureProvider<CategoryDrillDown> {
  /// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
  /// over the active analytics window.
  ///
  /// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
  /// the window, with a neutral subtotal/count summary sourced from Plan 01's
  /// shared rollup (so the header == the donut slice).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
  /// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
  /// would explode the family key and cause a rebuild storm. This provider defends
  /// the contract by re-normalizing the bounds via [DateBoundaries] before they
  /// reach the use case — never accept microsecond-exact instants into the key.
  ///
  /// Auto-dispose (the @riverpod default here, NOT keepAlive — D-14) and reads /
  /// invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
  /// home_screen_isolation_test.dart).
  CategoryDrillDownProvider._({
    required CategoryDrillDownFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      String l1CategoryId,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'categoryDrillDownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryDrillDownHash();

  @override
  String toString() {
    return r'categoryDrillDownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CategoryDrillDown> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CategoryDrillDown> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              String l1CategoryId,
            });
    return categoryDrillDown(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      l1CategoryId: argument.l1CategoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryDrillDownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryDrillDownHash() => r'780cecb1ce06f8c4efa63f96cf90d7c633d833a1';

/// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
/// over the active analytics window.
///
/// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
/// the window, with a neutral subtotal/count summary sourced from Plan 01's
/// shared rollup (so the header == the donut slice).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
/// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
/// would explode the family key and cause a rebuild storm. This provider defends
/// the contract by re-normalizing the bounds via [DateBoundaries] before they
/// reach the use case — never accept microsecond-exact instants into the key.
///
/// Auto-dispose (the @riverpod default here, NOT keepAlive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
/// home_screen_isolation_test.dart).

final class CategoryDrillDownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CategoryDrillDown>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            String l1CategoryId,
          })
        > {
  CategoryDrillDownFamily._()
    : super(
        retry: null,
        name: r'categoryDrillDownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
  /// over the active analytics window.
  ///
  /// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
  /// the window, with a neutral subtotal/count summary sourced from Plan 01's
  /// shared rollup (so the header == the donut slice).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
  /// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
  /// would explode the family key and cause a rebuild storm. This provider defends
  /// the contract by re-normalizing the bounds via [DateBoundaries] before they
  /// reach the use case — never accept microsecond-exact instants into the key.
  ///
  /// Auto-dispose (the @riverpod default here, NOT keepAlive — D-14) and reads /
  /// invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
  /// home_screen_isolation_test.dart).

  CategoryDrillDownProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    required String l1CategoryId,
  }) => CategoryDrillDownProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      l1CategoryId: l1CategoryId,
    ),
    from: this,
  );

  @override
  String toString() => r'categoryDrillDownProvider';
}

/// Earliest month with a non-deleted transaction in the active book.

@ProviderFor(earliestTransactionMonth)
final earliestTransactionMonthProvider = EarliestTransactionMonthFamily._();

/// Earliest month with a non-deleted transaction in the active book.

final class EarliestTransactionMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateTime?>,
          DateTime?,
          FutureOr<DateTime?>
        >
    with $FutureModifier<DateTime?>, $FutureProvider<DateTime?> {
  /// Earliest month with a non-deleted transaction in the active book.
  EarliestTransactionMonthProvider._({
    required EarliestTransactionMonthFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'earliestTransactionMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$earliestTransactionMonthHash();

  @override
  String toString() {
    return r'earliestTransactionMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime?> create(Ref ref) {
    final argument = this.argument as String;
    return earliestTransactionMonth(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EarliestTransactionMonthProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$earliestTransactionMonthHash() =>
    r'71b0c1fffe8f2530e09b0a091c191cf7d7e68634';

/// Earliest month with a non-deleted transaction in the active book.

final class EarliestTransactionMonthFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DateTime?>, String> {
  EarliestTransactionMonthFamily._()
    : super(
        retry: null,
        name: r'earliestTransactionMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Earliest month with a non-deleted transaction in the active book.

  EarliestTransactionMonthProvider call({required String bookId}) =>
      EarliestTransactionMonthProvider._(argument: bookId, from: this);

  @override
  String toString() => r'earliestTransactionMonthProvider';
}

/// Satisfaction score distribution for the selected window.

@ProviderFor(satisfactionDistribution)
final satisfactionDistributionProvider = SatisfactionDistributionFamily._();

/// Satisfaction score distribution for the selected window.

final class SatisfactionDistributionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SatisfactionScoreBucket>>,
          List<SatisfactionScoreBucket>,
          FutureOr<List<SatisfactionScoreBucket>>
        >
    with
        $FutureModifier<List<SatisfactionScoreBucket>>,
        $FutureProvider<List<SatisfactionScoreBucket>> {
  /// Satisfaction score distribution for the selected window.
  SatisfactionDistributionProvider._({
    required SatisfactionDistributionFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'satisfactionDistributionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$satisfactionDistributionHash();

  @override
  String toString() {
    return r'satisfactionDistributionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SatisfactionScoreBucket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SatisfactionScoreBucket>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return satisfactionDistribution(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SatisfactionDistributionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$satisfactionDistributionHash() =>
    r'179ba0ba9c310d05c182c3c23aaec6ddb12f5627';

/// Satisfaction score distribution for the selected window.

final class SatisfactionDistributionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SatisfactionScoreBucket>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  SatisfactionDistributionFamily._()
    : super(
        retry: null,
        name: r'satisfactionDistributionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Satisfaction score distribution for the selected window.

  SatisfactionDistributionProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => SatisfactionDistributionProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'satisfactionDistributionProvider';
}
