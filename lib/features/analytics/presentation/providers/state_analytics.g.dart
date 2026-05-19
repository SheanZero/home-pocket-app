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
    required ({String bookId, DateTime startDate, DateTime endDate})
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
            as ({String bookId, DateTime startDate, DateTime endDate});
    return monthlyReport(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
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

String _$monthlyReportHash() => r'f638e2c4193007cd84efc597361c7c556015e60b';

/// Monthly report for the selected window.

final class MonthlyReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MonthlyReport>,
          ({String bookId, DateTime startDate, DateTime endDate})
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
  }) => MonthlyReportProvider._(
    argument: (bookId: bookId, startDate: startDate, endDate: endDate),
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
    required ({String bookId, DateTime startDate, DateTime endDate})
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
            as ({String bookId, DateTime startDate, DateTime endDate});
    return satisfactionDistribution(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
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
    r'ad577b2f3bdb52b0f0a269e541d82aac25a58f60';

/// Satisfaction score distribution for the selected window.

final class SatisfactionDistributionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SatisfactionScoreBucket>>,
          ({String bookId, DateTime startDate, DateTime endDate})
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
  }) => SatisfactionDistributionProvider._(
    argument: (bookId: bookId, startDate: startDate, endDate: endDate),
    from: this,
  );

  @override
  String toString() => r'satisfactionDistributionProvider';
}
