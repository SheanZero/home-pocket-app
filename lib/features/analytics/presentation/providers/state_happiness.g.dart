// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_happiness.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$happinessReportHash() => r'123ad750b8925cd7f3c0f65179f4f8250c991996';

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

/// HAPPY-01..04 personal happiness report.
///
/// Copied from [happinessReport].
@ProviderFor(happinessReport)
const happinessReportProvider = HappinessReportFamily();

/// HAPPY-01..04 personal happiness report.
///
/// Copied from [happinessReport].
class HappinessReportFamily extends Family<AsyncValue<HappinessReport>> {
  /// HAPPY-01..04 personal happiness report.
  ///
  /// Copied from [happinessReport].
  const HappinessReportFamily();

  /// HAPPY-01..04 personal happiness report.
  ///
  /// Copied from [happinessReport].
  HappinessReportProvider call({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode,
  }) {
    return HappinessReportProvider(
      bookId: bookId,
      year: year,
      month: month,
      currencyCode: currencyCode,
    );
  }

  @override
  HappinessReportProvider getProviderOverride(
    covariant HappinessReportProvider provider,
  ) {
    return call(
      bookId: provider.bookId,
      year: provider.year,
      month: provider.month,
      currencyCode: provider.currencyCode,
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
  String? get name => r'happinessReportProvider';
}

/// HAPPY-01..04 personal happiness report.
///
/// Copied from [happinessReport].
class HappinessReportProvider
    extends AutoDisposeFutureProvider<HappinessReport> {
  /// HAPPY-01..04 personal happiness report.
  ///
  /// Copied from [happinessReport].
  HappinessReportProvider({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode,
  }) : this._internal(
         (ref) => happinessReport(
           ref as HappinessReportRef,
           bookId: bookId,
           year: year,
           month: month,
           currencyCode: currencyCode,
         ),
         from: happinessReportProvider,
         name: r'happinessReportProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$happinessReportHash,
         dependencies: HappinessReportFamily._dependencies,
         allTransitiveDependencies:
             HappinessReportFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
         currencyCode: currencyCode,
       );

  HappinessReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
  }) : super.internal();

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;

  @override
  Override overrideWith(
    FutureOr<HappinessReport> Function(HappinessReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HappinessReportProvider._internal(
        (ref) => create(ref as HappinessReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<HappinessReport> createElement() {
    return _HappinessReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HappinessReportProvider &&
        other.bookId == bookId &&
        other.year == year &&
        other.month == month &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, currencyCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HappinessReportRef on AutoDisposeFutureProviderRef<HappinessReport> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;

  /// The parameter `currencyCode` of this provider.
  String get currencyCode;
}

class _HappinessReportProviderElement
    extends AutoDisposeFutureProviderElement<HappinessReport>
    with HappinessReportRef {
  _HappinessReportProviderElement(super.provider);

  @override
  String get bookId => (origin as HappinessReportProvider).bookId;
  @override
  int get year => (origin as HappinessReportProvider).year;
  @override
  int get month => (origin as HappinessReportProvider).month;
  @override
  String get currencyCode => (origin as HappinessReportProvider).currencyCode;
}

String _$bestJoyMomentHash() => r'62be259ee9a15c4638f28aea80293416b415e735';

/// HAPPY-04 standalone Top Joy.
///
/// Copied from [bestJoyMoment].
@ProviderFor(bestJoyMoment)
const bestJoyMomentProvider = BestJoyMomentFamily();

/// HAPPY-04 standalone Top Joy.
///
/// Copied from [bestJoyMoment].
class BestJoyMomentFamily
    extends Family<AsyncValue<MetricResult<BestJoyMomentRow>>> {
  /// HAPPY-04 standalone Top Joy.
  ///
  /// Copied from [bestJoyMoment].
  const BestJoyMomentFamily();

  /// HAPPY-04 standalone Top Joy.
  ///
  /// Copied from [bestJoyMoment].
  BestJoyMomentProvider call({
    required String bookId,
    required int year,
    required int month,
  }) {
    return BestJoyMomentProvider(bookId: bookId, year: year, month: month);
  }

  @override
  BestJoyMomentProvider getProviderOverride(
    covariant BestJoyMomentProvider provider,
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
  String? get name => r'bestJoyMomentProvider';
}

/// HAPPY-04 standalone Top Joy.
///
/// Copied from [bestJoyMoment].
class BestJoyMomentProvider
    extends AutoDisposeFutureProvider<MetricResult<BestJoyMomentRow>> {
  /// HAPPY-04 standalone Top Joy.
  ///
  /// Copied from [bestJoyMoment].
  BestJoyMomentProvider({
    required String bookId,
    required int year,
    required int month,
  }) : this._internal(
         (ref) => bestJoyMoment(
           ref as BestJoyMomentRef,
           bookId: bookId,
           year: year,
           month: month,
         ),
         from: bestJoyMomentProvider,
         name: r'bestJoyMomentProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$bestJoyMomentHash,
         dependencies: BestJoyMomentFamily._dependencies,
         allTransitiveDependencies:
             BestJoyMomentFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
       );

  BestJoyMomentProvider._internal(
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
    FutureOr<MetricResult<BestJoyMomentRow>> Function(BestJoyMomentRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BestJoyMomentProvider._internal(
        (ref) => create(ref as BestJoyMomentRef),
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
  AutoDisposeFutureProviderElement<MetricResult<BestJoyMomentRow>>
  createElement() {
    return _BestJoyMomentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BestJoyMomentProvider &&
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
mixin BestJoyMomentRef
    on AutoDisposeFutureProviderRef<MetricResult<BestJoyMomentRow>> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _BestJoyMomentProviderElement
    extends AutoDisposeFutureProviderElement<MetricResult<BestJoyMomentRow>>
    with BestJoyMomentRef {
  _BestJoyMomentProviderElement(super.provider);

  @override
  String get bookId => (origin as BestJoyMomentProvider).bookId;
  @override
  int get year => (origin as BestJoyMomentProvider).year;
  @override
  int get month => (origin as BestJoyMomentProvider).month;
}

String _$dailyJoyPerYenHash() => r'3f9f9596614a46014f27acf73f15c14b684cdaf0';

/// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
///
/// Copied from [dailyJoyPerYen].
@ProviderFor(dailyJoyPerYen)
const dailyJoyPerYenProvider = DailyJoyPerYenFamily();

/// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
///
/// Copied from [dailyJoyPerYen].
class DailyJoyPerYenFamily
    extends Family<AsyncValue<MetricResult<List<DailyJoyPerYenPoint>>>> {
  /// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
  ///
  /// Copied from [dailyJoyPerYen].
  const DailyJoyPerYenFamily();

  /// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
  ///
  /// Copied from [dailyJoyPerYen].
  DailyJoyPerYenProvider call({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode,
  }) {
    return DailyJoyPerYenProvider(
      bookId: bookId,
      year: year,
      month: month,
      currencyCode: currencyCode,
    );
  }

  @override
  DailyJoyPerYenProvider getProviderOverride(
    covariant DailyJoyPerYenProvider provider,
  ) {
    return call(
      bookId: provider.bookId,
      year: provider.year,
      month: provider.month,
      currencyCode: provider.currencyCode,
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
  String? get name => r'dailyJoyPerYenProvider';
}

/// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
///
/// Copied from [dailyJoyPerYen].
class DailyJoyPerYenProvider
    extends AutoDisposeFutureProvider<MetricResult<List<DailyJoyPerYenPoint>>> {
  /// STATSUI-01 / D-05 — daily Joy/¥ trend (PTVF per-day fold).
  ///
  /// Copied from [dailyJoyPerYen].
  DailyJoyPerYenProvider({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode,
  }) : this._internal(
         (ref) => dailyJoyPerYen(
           ref as DailyJoyPerYenRef,
           bookId: bookId,
           year: year,
           month: month,
           currencyCode: currencyCode,
         ),
         from: dailyJoyPerYenProvider,
         name: r'dailyJoyPerYenProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$dailyJoyPerYenHash,
         dependencies: DailyJoyPerYenFamily._dependencies,
         allTransitiveDependencies:
             DailyJoyPerYenFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
         currencyCode: currencyCode,
       );

  DailyJoyPerYenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
  }) : super.internal();

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;

  @override
  Override overrideWith(
    FutureOr<MetricResult<List<DailyJoyPerYenPoint>>> Function(
      DailyJoyPerYenRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DailyJoyPerYenProvider._internal(
        (ref) => create(ref as DailyJoyPerYenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MetricResult<List<DailyJoyPerYenPoint>>>
  createElement() {
    return _DailyJoyPerYenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyJoyPerYenProvider &&
        other.bookId == bookId &&
        other.year == year &&
        other.month == month &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, currencyCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DailyJoyPerYenRef
    on AutoDisposeFutureProviderRef<MetricResult<List<DailyJoyPerYenPoint>>> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;

  /// The parameter `currencyCode` of this provider.
  String get currencyCode;
}

class _DailyJoyPerYenProviderElement
    extends
        AutoDisposeFutureProviderElement<
          MetricResult<List<DailyJoyPerYenPoint>>
        >
    with DailyJoyPerYenRef {
  _DailyJoyPerYenProviderElement(super.provider);

  @override
  String get bookId => (origin as DailyJoyPerYenProvider).bookId;
  @override
  int get year => (origin as DailyJoyPerYenProvider).year;
  @override
  int get month => (origin as DailyJoyPerYenProvider).month;
  @override
  String get currencyCode => (origin as DailyJoyPerYenProvider).currencyCode;
}

String _$largestMonthlyExpenseHash() =>
    r'8183e8ed497fbb177de3f0418793f50f1b0b87ea';

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
///
/// Copied from [largestMonthlyExpense].
@ProviderFor(largestMonthlyExpense)
const largestMonthlyExpenseProvider = LargestMonthlyExpenseFamily();

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
///
/// Copied from [largestMonthlyExpense].
class LargestMonthlyExpenseFamily
    extends Family<AsyncValue<LargestMonthlyExpense?>> {
  /// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
  ///
  /// Copied from [largestMonthlyExpense].
  const LargestMonthlyExpenseFamily();

  /// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
  ///
  /// Copied from [largestMonthlyExpense].
  LargestMonthlyExpenseProvider call({
    required String bookId,
    required int year,
    required int month,
  }) {
    return LargestMonthlyExpenseProvider(
      bookId: bookId,
      year: year,
      month: month,
    );
  }

  @override
  LargestMonthlyExpenseProvider getProviderOverride(
    covariant LargestMonthlyExpenseProvider provider,
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
  String? get name => r'largestMonthlyExpenseProvider';
}

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
///
/// Copied from [largestMonthlyExpense].
class LargestMonthlyExpenseProvider
    extends AutoDisposeFutureProvider<LargestMonthlyExpense?> {
  /// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
  ///
  /// Copied from [largestMonthlyExpense].
  LargestMonthlyExpenseProvider({
    required String bookId,
    required int year,
    required int month,
  }) : this._internal(
         (ref) => largestMonthlyExpense(
           ref as LargestMonthlyExpenseRef,
           bookId: bookId,
           year: year,
           month: month,
         ),
         from: largestMonthlyExpenseProvider,
         name: r'largestMonthlyExpenseProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$largestMonthlyExpenseHash,
         dependencies: LargestMonthlyExpenseFamily._dependencies,
         allTransitiveDependencies:
             LargestMonthlyExpenseFamily._allTransitiveDependencies,
         bookId: bookId,
         year: year,
         month: month,
       );

  LargestMonthlyExpenseProvider._internal(
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
    FutureOr<LargestMonthlyExpense?> Function(LargestMonthlyExpenseRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LargestMonthlyExpenseProvider._internal(
        (ref) => create(ref as LargestMonthlyExpenseRef),
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
  AutoDisposeFutureProviderElement<LargestMonthlyExpense?> createElement() {
    return _LargestMonthlyExpenseProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LargestMonthlyExpenseProvider &&
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
mixin LargestMonthlyExpenseRef
    on AutoDisposeFutureProviderRef<LargestMonthlyExpense?> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _LargestMonthlyExpenseProviderElement
    extends AutoDisposeFutureProviderElement<LargestMonthlyExpense?>
    with LargestMonthlyExpenseRef {
  _LargestMonthlyExpenseProviderElement(super.provider);

  @override
  String get bookId => (origin as LargestMonthlyExpenseProvider).bookId;
  @override
  int get year => (origin as LargestMonthlyExpenseProvider).year;
  @override
  int get month => (origin as LargestMonthlyExpenseProvider).month;
}

String _$familyHappinessHash() => r'5c47e90946b9c52fb257c27c3591378fb9f1e935';

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.
///
/// Copied from [familyHappiness].
@ProviderFor(familyHappiness)
const familyHappinessProvider = FamilyHappinessFamily();

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.
///
/// Copied from [familyHappiness].
class FamilyHappinessFamily extends Family<AsyncValue<FamilyHappiness>> {
  /// FAMILY-01..02 family happiness aggregate.
  ///
  /// D-09: presentation resolves shadow books to book IDs before invoking the
  /// use case. Q6c remains open: this currently passes shadow books only; Phase
  /// 10/11 may extend the call site if current-device book inclusion is required.
  ///
  /// Copied from [familyHappiness].
  const FamilyHappinessFamily();

  /// FAMILY-01..02 family happiness aggregate.
  ///
  /// D-09: presentation resolves shadow books to book IDs before invoking the
  /// use case. Q6c remains open: this currently passes shadow books only; Phase
  /// 10/11 may extend the call site if current-device book inclusion is required.
  ///
  /// Copied from [familyHappiness].
  FamilyHappinessProvider call({required int year, required int month}) {
    return FamilyHappinessProvider(year: year, month: month);
  }

  @override
  FamilyHappinessProvider getProviderOverride(
    covariant FamilyHappinessProvider provider,
  ) {
    return call(year: provider.year, month: provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'familyHappinessProvider';
}

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.
///
/// Copied from [familyHappiness].
class FamilyHappinessProvider
    extends AutoDisposeFutureProvider<FamilyHappiness> {
  /// FAMILY-01..02 family happiness aggregate.
  ///
  /// D-09: presentation resolves shadow books to book IDs before invoking the
  /// use case. Q6c remains open: this currently passes shadow books only; Phase
  /// 10/11 may extend the call site if current-device book inclusion is required.
  ///
  /// Copied from [familyHappiness].
  FamilyHappinessProvider({required int year, required int month})
    : this._internal(
        (ref) => familyHappiness(
          ref as FamilyHappinessRef,
          year: year,
          month: month,
        ),
        from: familyHappinessProvider,
        name: r'familyHappinessProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$familyHappinessHash,
        dependencies: FamilyHappinessFamily._dependencies,
        allTransitiveDependencies:
            FamilyHappinessFamily._allTransitiveDependencies,
        year: year,
        month: month,
      );

  FamilyHappinessProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<FamilyHappiness> Function(FamilyHappinessRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FamilyHappinessProvider._internal(
        (ref) => create(ref as FamilyHappinessRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FamilyHappiness> createElement() {
    return _FamilyHappinessProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyHappinessProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FamilyHappinessRef on AutoDisposeFutureProviderRef<FamilyHappiness> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _FamilyHappinessProviderElement
    extends AutoDisposeFutureProviderElement<FamilyHappiness>
    with FamilyHappinessRef {
  _FamilyHappinessProviderElement(super.provider);

  @override
  int get year => (origin as FamilyHappinessProvider).year;
  @override
  int get month => (origin as FamilyHappinessProvider).month;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
