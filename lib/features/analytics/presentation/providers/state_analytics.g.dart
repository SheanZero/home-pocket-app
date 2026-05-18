// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected month for analytics view.

@ProviderFor(SelectedMonth)
final selectedMonthProvider = SelectedMonthProvider._();

/// Currently selected month for analytics view.
final class SelectedMonthProvider
    extends $NotifierProvider<SelectedMonth, DateTime> {
  /// Currently selected month for analytics view.
  SelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMonthHash();

  @$internal
  @override
  SelectedMonth create() => SelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedMonthHash() => r'1e278a1a3b1a328fc41224840fb663025d470215';

/// Currently selected month for analytics view.

abstract class _$SelectedMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Monthly report for the selected month.

@ProviderFor(monthlyReport)
final monthlyReportProvider = MonthlyReportFamily._();

/// Monthly report for the selected month.

final class MonthlyReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthlyReport>,
          MonthlyReport,
          FutureOr<MonthlyReport>
        >
    with $FutureModifier<MonthlyReport>, $FutureProvider<MonthlyReport> {
  /// Monthly report for the selected month.
  MonthlyReportProvider._({
    required MonthlyReportFamily super.from,
    required ({String bookId, int year, int month}) super.argument,
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
    final argument = this.argument as ({String bookId, int year, int month});
    return monthlyReport(
      ref,
      bookId: argument.bookId,
      year: argument.year,
      month: argument.month,
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

String _$monthlyReportHash() => r'7cf906607233c12e61fc5015a9ac872c4b8d122e';

/// Monthly report for the selected month.

final class MonthlyReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MonthlyReport>,
          ({String bookId, int year, int month})
        > {
  MonthlyReportFamily._()
    : super(
        retry: null,
        name: r'monthlyReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Monthly report for the selected month.

  MonthlyReportProvider call({
    required String bookId,
    required int year,
    required int month,
  }) => MonthlyReportProvider._(
    argument: (bookId: bookId, year: year, month: month),
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
    required ({String bookId, DateTime anchor}) super.argument,
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
    final argument = this.argument as ({String bookId, DateTime anchor});
    return expenseTrend(ref, bookId: argument.bookId, anchor: argument.anchor);
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

String _$expenseTrendHash() => r'3f3497209b33b8aac9e6eff40fe290252e131a24';

/// 6-month expense trend.

final class ExpenseTrendFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExpenseTrendData>,
          ({String bookId, DateTime anchor})
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
  }) => ExpenseTrendProvider._(
    argument: (bookId: bookId, anchor: anchor),
    from: this,
  );

  @override
  String toString() => r'expenseTrendProvider';
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

/// Satisfaction score distribution for the selected month.

@ProviderFor(satisfactionDistribution)
final satisfactionDistributionProvider = SatisfactionDistributionFamily._();

/// Satisfaction score distribution for the selected month.

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
  /// Satisfaction score distribution for the selected month.
  SatisfactionDistributionProvider._({
    required SatisfactionDistributionFamily super.from,
    required ({String bookId, int year, int month}) super.argument,
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
    final argument = this.argument as ({String bookId, int year, int month});
    return satisfactionDistribution(
      ref,
      bookId: argument.bookId,
      year: argument.year,
      month: argument.month,
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
    r'33a0f1e6d5e6d598c7a9bc4345b0834cbd36c05e';

/// Satisfaction score distribution for the selected month.

final class SatisfactionDistributionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SatisfactionScoreBucket>>,
          ({String bookId, int year, int month})
        > {
  SatisfactionDistributionFamily._()
    : super(
        retry: null,
        name: r'satisfactionDistributionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Satisfaction score distribution for the selected month.

  SatisfactionDistributionProvider call({
    required String bookId,
    required int year,
    required int month,
  }) => SatisfactionDistributionProvider._(
    argument: (bookId: bookId, year: year, month: month),
    from: this,
  );

  @override
  String toString() => r'satisfactionDistributionProvider';
}
