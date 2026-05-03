// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyReportHash() => r'7cf906607233c12e61fc5015a9ac872c4b8d122e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Monthly report for the selected month.
///
/// Copied from [monthlyReport].
@ProviderFor(monthlyReport)
const monthlyReportProvider = MonthlyReportFamily();

/// Monthly report for the selected month.
///
/// Copied from [monthlyReport].
class MonthlyReportFamily extends Family<AsyncValue<MonthlyReport>> {
  /// Monthly report for the selected month.
  ///
  /// Copied from [monthlyReport].
  const MonthlyReportFamily();

  /// Monthly report for the selected month.
  ///
  /// Copied from [monthlyReport].
  MonthlyReportProvider call({
    required String bookId,
    required int year,
    required int month,
  }) {
    return MonthlyReportProvider(bookId: bookId, year: year, month: month);
  }

  @override
  MonthlyReportProvider getProviderOverride(
    covariant MonthlyReportProvider provider,
  ) {
    return call(
      bookId: provider.bookId,
      year: provider.year,
      month: provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyReportProvider';
}

/// Monthly report for the selected month.
///
/// Copied from [monthlyReport].
class MonthlyReportProvider extends AutoDisposeFutureProvider<MonthlyReport> {
  /// Monthly report for the selected month.
  ///
  /// Copied from [monthlyReport].
  MonthlyReportProvider({
    required String bookId,
    required int year,
    required int month,
  }) : this._internal(
         (ref) => monthlyReport(
           ref as MonthlyReportRef,
           bookId: bookId,
           year: year,
           month: month,
         ),
         from: monthlyReportProvider,
         name: r'monthlyReportProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$monthlyReportHash,
         dependencies: MonthlyReportFamily._dependencies,
         allTransitiveDependencies:
             MonthlyReportFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
       );

  MonthlyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.year,
    required this.month,
  }) : super.internal();

  final String bookId;
  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<MonthlyReport> Function(MonthlyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyReportProvider._internal(
        (ref) => create(ref as MonthlyReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MonthlyReport> createElement() {
    return _MonthlyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyReportProvider &&
        other.bookId == bookId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyReportRef on AutoDisposeFutureProviderRef<MonthlyReport> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _MonthlyReportProviderElement
    extends AutoDisposeFutureProviderElement<MonthlyReport>
    with MonthlyReportRef {
  _MonthlyReportProviderElement(super.provider);

  @override
  String get bookId => (origin as MonthlyReportProvider).bookId;
  @override
  int get year => (origin as MonthlyReportProvider).year;
  @override
  int get month => (origin as MonthlyReportProvider).month;
}

String _$expenseTrendHash() => r'3f3497209b33b8aac9e6eff40fe290252e131a24';

/// 6-month expense trend.
///
/// Copied from [expenseTrend].
@ProviderFor(expenseTrend)
const expenseTrendProvider = ExpenseTrendFamily();

/// 6-month expense trend.
///
/// Copied from [expenseTrend].
class ExpenseTrendFamily extends Family<AsyncValue<ExpenseTrendData>> {
  /// 6-month expense trend.
  ///
  /// Copied from [expenseTrend].
  const ExpenseTrendFamily();

  /// 6-month expense trend.
  ///
  /// Copied from [expenseTrend].
  ExpenseTrendProvider call({
    required String bookId,
    required DateTime anchor,
  }) {
    return ExpenseTrendProvider(bookId: bookId, anchor: anchor);
  }

  @override
  ExpenseTrendProvider getProviderOverride(
    covariant ExpenseTrendProvider provider,
  ) {
    return call(bookId: provider.bookId, anchor: provider.anchor);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'expenseTrendProvider';
}

/// 6-month expense trend.
///
/// Copied from [expenseTrend].
class ExpenseTrendProvider extends AutoDisposeFutureProvider<ExpenseTrendData> {
  /// 6-month expense trend.
  ///
  /// Copied from [expenseTrend].
  ExpenseTrendProvider({required String bookId, required DateTime anchor})
    : this._internal(
        (ref) => expenseTrend(
          ref as ExpenseTrendRef,
          bookId: bookId,
          anchor: anchor,
        ),
        from: expenseTrendProvider,
        name: r'expenseTrendProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$expenseTrendHash,
        dependencies: ExpenseTrendFamily._dependencies,
        allTransitiveDependencies:
            ExpenseTrendFamily._allTransitiveDependencies,
        bookId: bookId,
        anchor: anchor,
      );

  ExpenseTrendProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.anchor,
  }) : super.internal();

  final String bookId;
  final DateTime anchor;

  @override
  Override overrideWith(
    FutureOr<ExpenseTrendData> Function(ExpenseTrendRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExpenseTrendProvider._internal(
        (ref) => create(ref as ExpenseTrendRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        anchor: anchor,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ExpenseTrendData> createElement() {
    return _ExpenseTrendProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseTrendProvider &&
        other.bookId == bookId &&
        other.anchor == anchor;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, anchor.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExpenseTrendRef on AutoDisposeFutureProviderRef<ExpenseTrendData> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `anchor` of this provider.
  DateTime get anchor;
}

class _ExpenseTrendProviderElement
    extends AutoDisposeFutureProviderElement<ExpenseTrendData>
    with ExpenseTrendRef {
  _ExpenseTrendProviderElement(super.provider);

  @override
  String get bookId => (origin as ExpenseTrendProvider).bookId;
  @override
  DateTime get anchor => (origin as ExpenseTrendProvider).anchor;
}

String _$earliestTransactionMonthHash() =>
    r'71b0c1fffe8f2530e09b0a091c191cf7d7e68634';

/// Earliest month with a non-deleted transaction in the active book.
///
/// Copied from [earliestTransactionMonth].
@ProviderFor(earliestTransactionMonth)
const earliestTransactionMonthProvider = EarliestTransactionMonthFamily();

/// Earliest month with a non-deleted transaction in the active book.
///
/// Copied from [earliestTransactionMonth].
class EarliestTransactionMonthFamily extends Family<AsyncValue<DateTime?>> {
  /// Earliest month with a non-deleted transaction in the active book.
  ///
  /// Copied from [earliestTransactionMonth].
  const EarliestTransactionMonthFamily();

  /// Earliest month with a non-deleted transaction in the active book.
  ///
  /// Copied from [earliestTransactionMonth].
  EarliestTransactionMonthProvider call({required String bookId}) {
    return EarliestTransactionMonthProvider(bookId: bookId);
  }

  @override
  EarliestTransactionMonthProvider getProviderOverride(
    covariant EarliestTransactionMonthProvider provider,
  ) {
    return call(bookId: provider.bookId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'earliestTransactionMonthProvider';
}

/// Earliest month with a non-deleted transaction in the active book.
///
/// Copied from [earliestTransactionMonth].
class EarliestTransactionMonthProvider
    extends AutoDisposeFutureProvider<DateTime?> {
  /// Earliest month with a non-deleted transaction in the active book.
  ///
  /// Copied from [earliestTransactionMonth].
  EarliestTransactionMonthProvider({required String bookId})
    : this._internal(
        (ref) => earliestTransactionMonth(
          ref as EarliestTransactionMonthRef,
          bookId: bookId,
        ),
        from: earliestTransactionMonthProvider,
        name: r'earliestTransactionMonthProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$earliestTransactionMonthHash,
        dependencies: EarliestTransactionMonthFamily._dependencies,
        allTransitiveDependencies:
            EarliestTransactionMonthFamily._allTransitiveDependencies,
        bookId: bookId,
      );

  EarliestTransactionMonthProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
  }) : super.internal();

  final String bookId;

  @override
  Override overrideWith(
    FutureOr<DateTime?> Function(EarliestTransactionMonthRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EarliestTransactionMonthProvider._internal(
        (ref) => create(ref as EarliestTransactionMonthRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DateTime?> createElement() {
    return _EarliestTransactionMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EarliestTransactionMonthProvider && other.bookId == bookId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EarliestTransactionMonthRef on AutoDisposeFutureProviderRef<DateTime?> {
  /// The parameter `bookId` of this provider.
  String get bookId;
}

class _EarliestTransactionMonthProviderElement
    extends AutoDisposeFutureProviderElement<DateTime?>
    with EarliestTransactionMonthRef {
  _EarliestTransactionMonthProviderElement(super.provider);

  @override
  String get bookId => (origin as EarliestTransactionMonthProvider).bookId;
}

String _$satisfactionDistributionHash() =>
    r'33a0f1e6d5e6d598c7a9bc4345b0834cbd36c05e';

/// Satisfaction score distribution for the selected month.
///
/// Copied from [satisfactionDistribution].
@ProviderFor(satisfactionDistribution)
const satisfactionDistributionProvider = SatisfactionDistributionFamily();

/// Satisfaction score distribution for the selected month.
///
/// Copied from [satisfactionDistribution].
class SatisfactionDistributionFamily
    extends Family<AsyncValue<List<SatisfactionScoreBucket>>> {
  /// Satisfaction score distribution for the selected month.
  ///
  /// Copied from [satisfactionDistribution].
  const SatisfactionDistributionFamily();

  /// Satisfaction score distribution for the selected month.
  ///
  /// Copied from [satisfactionDistribution].
  SatisfactionDistributionProvider call({
    required String bookId,
    required int year,
    required int month,
  }) {
    return SatisfactionDistributionProvider(
      bookId: bookId,
      year: year,
      month: month,
    );
  }

  @override
  SatisfactionDistributionProvider getProviderOverride(
    covariant SatisfactionDistributionProvider provider,
  ) {
    return call(
      bookId: provider.bookId,
      year: provider.year,
      month: provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'satisfactionDistributionProvider';
}

/// Satisfaction score distribution for the selected month.
///
/// Copied from [satisfactionDistribution].
class SatisfactionDistributionProvider
    extends AutoDisposeFutureProvider<List<SatisfactionScoreBucket>> {
  /// Satisfaction score distribution for the selected month.
  ///
  /// Copied from [satisfactionDistribution].
  SatisfactionDistributionProvider({
    required String bookId,
    required int year,
    required int month,
  }) : this._internal(
         (ref) => satisfactionDistribution(
           ref as SatisfactionDistributionRef,
           bookId: bookId,
           year: year,
           month: month,
         ),
         from: satisfactionDistributionProvider,
         name: r'satisfactionDistributionProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$satisfactionDistributionHash,
         dependencies: SatisfactionDistributionFamily._dependencies,
         allTransitiveDependencies:
             SatisfactionDistributionFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
       );

  SatisfactionDistributionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.year,
    required this.month,
  }) : super.internal();

  final String bookId;
  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<List<SatisfactionScoreBucket>> Function(
      SatisfactionDistributionRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SatisfactionDistributionProvider._internal(
        (ref) => create(ref as SatisfactionDistributionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SatisfactionScoreBucket>>
  createElement() {
    return _SatisfactionDistributionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SatisfactionDistributionProvider &&
        other.bookId == bookId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SatisfactionDistributionRef
    on AutoDisposeFutureProviderRef<List<SatisfactionScoreBucket>> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _SatisfactionDistributionProviderElement
    extends AutoDisposeFutureProviderElement<List<SatisfactionScoreBucket>>
    with SatisfactionDistributionRef {
  _SatisfactionDistributionProviderElement(super.provider);

  @override
  String get bookId => (origin as SatisfactionDistributionProvider).bookId;
  @override
  int get year => (origin as SatisfactionDistributionProvider).year;
  @override
  int get month => (origin as SatisfactionDistributionProvider).month;
}

String _$selectedMonthHash() => r'1e278a1a3b1a328fc41224840fb663025d470215';

/// Currently selected month for analytics view.
///
/// Copied from [SelectedMonth].
@ProviderFor(SelectedMonth)
final selectedMonthProvider =
    AutoDisposeNotifierProvider<SelectedMonth, DateTime>.internal(
      SelectedMonth.new,
      name: r'selectedMonthProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedMonthHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedMonth = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
