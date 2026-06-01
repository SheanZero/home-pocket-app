// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_ledger_snapshot.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// HAPPY-V2-01 single-book per-category joy satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategoryJoyBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

@ProviderFor(perCategoryJoyBreakdown)
final perCategoryJoyBreakdownProvider = PerCategoryJoyBreakdownFamily._();

/// HAPPY-V2-01 single-book per-category joy satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategoryJoyBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

final class PerCategoryJoyBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<PerCategoryJoyBreakdown>>,
          MetricResult<PerCategoryJoyBreakdown>,
          FutureOr<MetricResult<PerCategoryJoyBreakdown>>
        >
    with
        $FutureModifier<MetricResult<PerCategoryJoyBreakdown>>,
        $FutureProvider<MetricResult<PerCategoryJoyBreakdown>> {
  /// HAPPY-V2-01 single-book per-category joy satisfaction breakdown.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetPerCategoryJoyBreakdownUseCase]. The use case owns the D-07 sort and
  /// D-08 min-N/Other rollup — the provider is plumbing only.
  PerCategoryJoyBreakdownProvider._({
    required PerCategoryJoyBreakdownFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'perCategoryJoyBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perCategoryJoyBreakdownHash();

  @override
  String toString() {
    return r'perCategoryJoyBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<PerCategoryJoyBreakdown>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<PerCategoryJoyBreakdown>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return perCategoryJoyBreakdown(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerCategoryJoyBreakdownProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perCategoryJoyBreakdownHash() =>
    r'02b126ffc55bea5574c17c779b651f18b79ea137';

/// HAPPY-V2-01 single-book per-category joy satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategoryJoyBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

final class PerCategoryJoyBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<PerCategoryJoyBreakdown>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  PerCategoryJoyBreakdownFamily._()
    : super(
        retry: null,
        name: r'perCategoryJoyBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// HAPPY-V2-01 single-book per-category joy satisfaction breakdown.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetPerCategoryJoyBreakdownUseCase]. The use case owns the D-07 sort and
  /// D-08 min-N/Other rollup — the provider is plumbing only.

  PerCategoryJoyBreakdownProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => PerCategoryJoyBreakdownProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'perCategoryJoyBreakdownProvider';
}

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

@ProviderFor(perCategoryJoyBreakdownFamily)
final perCategoryJoyBreakdownFamilyProvider =
    PerCategoryJoyBreakdownFamilyFamily._();

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

final class PerCategoryJoyBreakdownFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<PerCategoryJoyBreakdown>>,
          MetricResult<PerCategoryJoyBreakdown>,
          FutureOr<MetricResult<PerCategoryJoyBreakdown>>
        >
    with
        $FutureModifier<MetricResult<PerCategoryJoyBreakdown>>,
        $FutureProvider<MetricResult<PerCategoryJoyBreakdown>> {
  /// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
  /// "Family · Top categories" card.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the card renders "Family data not available" instead of a misleading
  /// single-book result.
  PerCategoryJoyBreakdownFamilyProvider._({
    required PerCategoryJoyBreakdownFamilyFamily super.from,
    required ({
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'perCategoryJoyBreakdownFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perCategoryJoyBreakdownFamilyHash();

  @override
  String toString() {
    return r'perCategoryJoyBreakdownFamilyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<PerCategoryJoyBreakdown>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<PerCategoryJoyBreakdown>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return perCategoryJoyBreakdownFamily(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerCategoryJoyBreakdownFamilyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perCategoryJoyBreakdownFamilyHash() =>
    r'6de555fe103df3430d8e5a54aa1f3732463d09ad';

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

final class PerCategoryJoyBreakdownFamilyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<PerCategoryJoyBreakdown>>,
          ({
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  PerCategoryJoyBreakdownFamilyFamily._()
    : super(
        retry: null,
        name: r'perCategoryJoyBreakdownFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
  /// "Family · Top categories" card.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the card renders "Family data not available" instead of a misleading
  /// single-book result.

  PerCategoryJoyBreakdownFamilyProvider call({
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => PerCategoryJoyBreakdownFamilyProvider._(
    argument: (
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'perCategoryJoyBreakdownFamilyProvider';
}

/// STATSUI-V2-01 single-book Daily-vs-Joy engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetDailyVsJoySnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

@ProviderFor(dailyVsJoySnapshot)
final dailyVsJoySnapshotProvider = DailyVsJoySnapshotFamily._();

/// STATSUI-V2-01 single-book Daily-vs-Joy engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetDailyVsJoySnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

final class DailyVsJoySnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<DailyVsJoySnapshot>>,
          MetricResult<DailyVsJoySnapshot>,
          FutureOr<MetricResult<DailyVsJoySnapshot>>
        >
    with
        $FutureModifier<MetricResult<DailyVsJoySnapshot>>,
        $FutureProvider<MetricResult<DailyVsJoySnapshot>> {
  /// STATSUI-V2-01 single-book Daily-vs-Joy engagement snapshot.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetDailyVsJoySnapshotUseCase]. The use case enforces the D-05
  /// either-ledger-zero gate (any side missing/zero → [Empty]).
  DailyVsJoySnapshotProvider._({
    required DailyVsJoySnapshotFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'dailyVsJoySnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyVsJoySnapshotHash();

  @override
  String toString() {
    return r'dailyVsJoySnapshotProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<DailyVsJoySnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<DailyVsJoySnapshot>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return dailyVsJoySnapshot(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyVsJoySnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyVsJoySnapshotHash() =>
    r'29d41e5fb28976b2831021ae1acd88d8abf858bb';

/// STATSUI-V2-01 single-book Daily-vs-Joy engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetDailyVsJoySnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

final class DailyVsJoySnapshotFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<DailyVsJoySnapshot>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  DailyVsJoySnapshotFamily._()
    : super(
        retry: null,
        name: r'dailyVsJoySnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-V2-01 single-book Daily-vs-Joy engagement snapshot.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetDailyVsJoySnapshotUseCase]. The use case enforces the D-05
  /// either-ledger-zero gate (any side missing/zero → [Empty]).

  DailyVsJoySnapshotProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => DailyVsJoySnapshotProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'dailyVsJoySnapshotProvider';
}

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Daily-vs-Joy snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

@ProviderFor(dailyVsJoySnapshotFamily)
final dailyVsJoySnapshotFamilyProvider = DailyVsJoySnapshotFamilyFamily._();

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Daily-vs-Joy snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

final class DailyVsJoySnapshotFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<DailyVsJoySnapshot>>,
          MetricResult<DailyVsJoySnapshot>,
          FutureOr<MetricResult<DailyVsJoySnapshot>>
        >
    with
        $FutureModifier<MetricResult<DailyVsJoySnapshot>>,
        $FutureProvider<MetricResult<DailyVsJoySnapshot>> {
  /// STATSUI-V2-01 D-18, D-20 — family-aggregate Daily-vs-Joy snapshot.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the Family compare card renders the empty state rather than a half-
  /// populated family aggregate.
  DailyVsJoySnapshotFamilyProvider._({
    required DailyVsJoySnapshotFamilyFamily super.from,
    required ({
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'dailyVsJoySnapshotFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyVsJoySnapshotFamilyHash();

  @override
  String toString() {
    return r'dailyVsJoySnapshotFamilyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<DailyVsJoySnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<DailyVsJoySnapshot>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return dailyVsJoySnapshotFamily(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyVsJoySnapshotFamilyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyVsJoySnapshotFamilyHash() =>
    r'296fe2d7b25e9f41e48161150eaebdb1ba390887';

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Daily-vs-Joy snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

final class DailyVsJoySnapshotFamilyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<DailyVsJoySnapshot>>,
          ({
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  DailyVsJoySnapshotFamilyFamily._()
    : super(
        retry: null,
        name: r'dailyVsJoySnapshotFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-V2-01 D-18, D-20 — family-aggregate Daily-vs-Joy snapshot.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the Family compare card renders the empty state rather than a half-
  /// populated family aggregate.

  DailyVsJoySnapshotFamilyProvider call({
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => DailyVsJoySnapshotFamilyProvider._(
    argument: (
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'dailyVsJoySnapshotFamilyProvider';
}
