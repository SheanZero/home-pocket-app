// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getMonthlyReportUseCaseHash() =>
    r'ba1bdbe33efe416704852d870225a34fc24cde98';

/// GetMonthlyReportUseCase provider.
///
/// Copied from [getMonthlyReportUseCase].
@ProviderFor(getMonthlyReportUseCase)
final getMonthlyReportUseCaseProvider =
    AutoDisposeProvider<GetMonthlyReportUseCase>.internal(
      getMonthlyReportUseCase,
      name: r'getMonthlyReportUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getMonthlyReportUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetMonthlyReportUseCaseRef =
    AutoDisposeProviderRef<GetMonthlyReportUseCase>;
String _$getBudgetProgressUseCaseHash() =>
    r'44ee40f9374353b4f05af2927913d4299ad7c9c8';

/// GetBudgetProgressUseCase provider.
///
/// Copied from [getBudgetProgressUseCase].
@ProviderFor(getBudgetProgressUseCase)
final getBudgetProgressUseCaseProvider =
    AutoDisposeProvider<GetBudgetProgressUseCase>.internal(
      getBudgetProgressUseCase,
      name: r'getBudgetProgressUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getBudgetProgressUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetBudgetProgressUseCaseRef =
    AutoDisposeProviderRef<GetBudgetProgressUseCase>;
String _$getExpenseTrendUseCaseHash() =>
    r'dfd62efcd364189bcdaa5d2b36b4dad57edb476d';

/// GetExpenseTrendUseCase provider.
///
/// Copied from [getExpenseTrendUseCase].
@ProviderFor(getExpenseTrendUseCase)
final getExpenseTrendUseCaseProvider =
    AutoDisposeProvider<GetExpenseTrendUseCase>.internal(
      getExpenseTrendUseCase,
      name: r'getExpenseTrendUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getExpenseTrendUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetExpenseTrendUseCaseRef =
    AutoDisposeProviderRef<GetExpenseTrendUseCase>;
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

String _$budgetProgressHash() => r'ae41ba06c07f8df96d4f818047e39734ecf98443';

/// Budget progress for the selected month.
///
/// Copied from [budgetProgress].
@ProviderFor(budgetProgress)
const budgetProgressProvider = BudgetProgressFamily();

/// Budget progress for the selected month.
///
/// Copied from [budgetProgress].
class BudgetProgressFamily extends Family<AsyncValue<List<BudgetProgress>>> {
  /// Budget progress for the selected month.
  ///
  /// Copied from [budgetProgress].
  const BudgetProgressFamily();

  /// Budget progress for the selected month.
  ///
  /// Copied from [budgetProgress].
  BudgetProgressProvider call({
    required String bookId,
    required int year,
    required int month,
  }) {
    return BudgetProgressProvider(bookId: bookId, year: year, month: month);
  }

  @override
  BudgetProgressProvider getProviderOverride(
    covariant BudgetProgressProvider provider,
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
  String? get name => r'budgetProgressProvider';
}

/// Budget progress for the selected month.
///
/// Copied from [budgetProgress].
class BudgetProgressProvider
    extends AutoDisposeFutureProvider<List<BudgetProgress>> {
  /// Budget progress for the selected month.
  ///
  /// Copied from [budgetProgress].
  BudgetProgressProvider({
    required String bookId,
    required int year,
    required int month,
  }) : this._internal(
         (ref) => budgetProgress(
           ref as BudgetProgressRef,
           bookId: bookId,
           year: year,
           month: month,
         ),
         from: budgetProgressProvider,
         name: r'budgetProgressProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$budgetProgressHash,
         dependencies: BudgetProgressFamily._dependencies,
         allTransitiveDependencies:
             BudgetProgressFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
       );

  BudgetProgressProvider._internal(
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
    FutureOr<List<BudgetProgress>> Function(BudgetProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BudgetProgressProvider._internal(
        (ref) => create(ref as BudgetProgressRef),
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
  AutoDisposeFutureProviderElement<List<BudgetProgress>> createElement() {
    return _BudgetProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetProgressProvider &&
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
mixin BudgetProgressRef on AutoDisposeFutureProviderRef<List<BudgetProgress>> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _BudgetProgressProviderElement
    extends AutoDisposeFutureProviderElement<List<BudgetProgress>>
    with BudgetProgressRef {
  _BudgetProgressProviderElement(super.provider);

  @override
  String get bookId => (origin as BudgetProgressProvider).bookId;
  @override
  int get year => (origin as BudgetProgressProvider).year;
  @override
  int get month => (origin as BudgetProgressProvider).month;
}

String _$expenseTrendHash() => r'5d83b624ba1718f2bad4b96a31671c1acf48a8fd';

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
  ExpenseTrendProvider call({required String bookId}) {
    return ExpenseTrendProvider(bookId: bookId);
  }

  @override
  ExpenseTrendProvider getProviderOverride(
    covariant ExpenseTrendProvider provider,
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
  String? get name => r'expenseTrendProvider';
}

/// 6-month expense trend.
///
/// Copied from [expenseTrend].
class ExpenseTrendProvider extends AutoDisposeFutureProvider<ExpenseTrendData> {
  /// 6-month expense trend.
  ///
  /// Copied from [expenseTrend].
  ExpenseTrendProvider({required String bookId})
    : this._internal(
        (ref) => expenseTrend(ref as ExpenseTrendRef, bookId: bookId),
        from: expenseTrendProvider,
        name: r'expenseTrendProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$expenseTrendHash,
        dependencies: ExpenseTrendFamily._dependencies,
        allTransitiveDependencies:
            ExpenseTrendFamily._allTransitiveDependencies,
        bookId: bookId,
      );

  ExpenseTrendProvider._internal(
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
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ExpenseTrendData> createElement() {
    return _ExpenseTrendProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseTrendProvider && other.bookId == bookId;
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
mixin ExpenseTrendRef on AutoDisposeFutureProviderRef<ExpenseTrendData> {
  /// The parameter `bookId` of this provider.
  String get bookId;
}

class _ExpenseTrendProviderElement
    extends AutoDisposeFutureProviderElement<ExpenseTrendData>
    with ExpenseTrendRef {
  _ExpenseTrendProviderElement(super.provider);

  @override
  String get bookId => (origin as ExpenseTrendProvider).bookId;
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
