// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_ledger_snapshot.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

@ProviderFor(perCategorySoulBreakdown)
final perCategorySoulBreakdownProvider = PerCategorySoulBreakdownFamily._();

/// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

final class PerCategorySoulBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<PerCategorySoulBreakdown>>,
          MetricResult<PerCategorySoulBreakdown>,
          FutureOr<MetricResult<PerCategorySoulBreakdown>>
        >
    with
        $FutureModifier<MetricResult<PerCategorySoulBreakdown>>,
        $FutureProvider<MetricResult<PerCategorySoulBreakdown>> {
  /// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
  /// D-08 min-N/Other rollup — the provider is plumbing only.
  PerCategorySoulBreakdownProvider._({
    required PerCategorySoulBreakdownFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'perCategorySoulBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perCategorySoulBreakdownHash();

  @override
  String toString() {
    return r'perCategorySoulBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<PerCategorySoulBreakdown>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<PerCategorySoulBreakdown>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return perCategorySoulBreakdown(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerCategorySoulBreakdownProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perCategorySoulBreakdownHash() =>
    r'4161e0a42a2fcac03e00c5f14fbc86371310d040';

/// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.

final class PerCategorySoulBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<PerCategorySoulBreakdown>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  PerCategorySoulBreakdownFamily._()
    : super(
        retry: null,
        name: r'perCategorySoulBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
  /// D-08 min-N/Other rollup — the provider is plumbing only.

  PerCategorySoulBreakdownProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => PerCategorySoulBreakdownProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'perCategorySoulBreakdownProvider';
}

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

@ProviderFor(perCategorySoulBreakdownFamily)
final perCategorySoulBreakdownFamilyProvider =
    PerCategorySoulBreakdownFamilyFamily._();

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

final class PerCategorySoulBreakdownFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<PerCategorySoulBreakdown>>,
          MetricResult<PerCategorySoulBreakdown>,
          FutureOr<MetricResult<PerCategorySoulBreakdown>>
        >
    with
        $FutureModifier<MetricResult<PerCategorySoulBreakdown>>,
        $FutureProvider<MetricResult<PerCategorySoulBreakdown>> {
  /// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
  /// "Family · Top categories" card.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the card renders "Family data not available" instead of a misleading
  /// single-book result.
  PerCategorySoulBreakdownFamilyProvider._({
    required PerCategorySoulBreakdownFamilyFamily super.from,
    required ({
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'perCategorySoulBreakdownFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perCategorySoulBreakdownFamilyHash();

  @override
  String toString() {
    return r'perCategorySoulBreakdownFamilyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<PerCategorySoulBreakdown>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<PerCategorySoulBreakdown>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return perCategorySoulBreakdownFamily(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerCategorySoulBreakdownFamilyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perCategorySoulBreakdownFamilyHash() =>
    r'7925a639e37c6d1ebf203a1cb12b47ab697a9ddf';

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.

final class PerCategorySoulBreakdownFamilyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<PerCategorySoulBreakdown>>,
          ({
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  PerCategorySoulBreakdownFamilyFamily._()
    : super(
        retry: null,
        name: r'perCategorySoulBreakdownFamilyProvider',
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

  PerCategorySoulBreakdownFamilyProvider call({
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => PerCategorySoulBreakdownFamilyProvider._(
    argument: (
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'perCategorySoulBreakdownFamilyProvider';
}

/// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

@ProviderFor(soulVsSurvivalSnapshot)
final soulVsSurvivalSnapshotProvider = SoulVsSurvivalSnapshotFamily._();

/// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

final class SoulVsSurvivalSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<SoulVsSurvivalSnapshot>>,
          MetricResult<SoulVsSurvivalSnapshot>,
          FutureOr<MetricResult<SoulVsSurvivalSnapshot>>
        >
    with
        $FutureModifier<MetricResult<SoulVsSurvivalSnapshot>>,
        $FutureProvider<MetricResult<SoulVsSurvivalSnapshot>> {
  /// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
  /// either-ledger-zero gate (any side missing/zero → [Empty]).
  SoulVsSurvivalSnapshotProvider._({
    required SoulVsSurvivalSnapshotFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'soulVsSurvivalSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$soulVsSurvivalSnapshotHash();

  @override
  String toString() {
    return r'soulVsSurvivalSnapshotProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<SoulVsSurvivalSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<SoulVsSurvivalSnapshot>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return soulVsSurvivalSnapshot(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SoulVsSurvivalSnapshotProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$soulVsSurvivalSnapshotHash() =>
    r'25ba40374bf172a8f009da2555cc76699c27edd3';

/// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).

final class SoulVsSurvivalSnapshotFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<SoulVsSurvivalSnapshot>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  SoulVsSurvivalSnapshotFamily._()
    : super(
        retry: null,
        name: r'soulVsSurvivalSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
  ///
  /// Window-keyed Future provider that delegates to
  /// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
  /// either-ledger-zero gate (any side missing/zero → [Empty]).

  SoulVsSurvivalSnapshotProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => SoulVsSurvivalSnapshotProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'soulVsSurvivalSnapshotProvider';
}

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

@ProviderFor(soulVsSurvivalSnapshotFamily)
final soulVsSurvivalSnapshotFamilyProvider =
    SoulVsSurvivalSnapshotFamilyFamily._();

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

final class SoulVsSurvivalSnapshotFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricResult<SoulVsSurvivalSnapshot>>,
          MetricResult<SoulVsSurvivalSnapshot>,
          FutureOr<MetricResult<SoulVsSurvivalSnapshot>>
        >
    with
        $FutureModifier<MetricResult<SoulVsSurvivalSnapshot>>,
        $FutureProvider<MetricResult<SoulVsSurvivalSnapshot>> {
  /// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the Family compare card renders the empty state rather than a half-
  /// populated family aggregate.
  SoulVsSurvivalSnapshotFamilyProvider._({
    required SoulVsSurvivalSnapshotFamilyFamily super.from,
    required ({
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'soulVsSurvivalSnapshotFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$soulVsSurvivalSnapshotFamilyHash();

  @override
  String toString() {
    return r'soulVsSurvivalSnapshotFamilyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MetricResult<SoulVsSurvivalSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricResult<SoulVsSurvivalSnapshot>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return soulVsSurvivalSnapshotFamily(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SoulVsSurvivalSnapshotFamilyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$soulVsSurvivalSnapshotFamilyHash() =>
    r'0a14bb9c18a5d3c4fd3784bf9655c3ca18fb403b';

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.

final class SoulVsSurvivalSnapshotFamilyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MetricResult<SoulVsSurvivalSnapshot>>,
          ({
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  SoulVsSurvivalSnapshotFamilyFamily._()
    : super(
        retry: null,
        name: r'soulVsSurvivalSnapshotFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
  ///
  /// D-20 gate (defense in depth — the use case also short-circuits on empty
  /// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
  /// the Family compare card renders the empty state rather than a half-
  /// populated family aggregate.

  SoulVsSurvivalSnapshotFamilyProvider call({
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => SoulVsSurvivalSnapshotFamilyProvider._(
    argument: (
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'soulVsSurvivalSnapshotFamilyProvider';
}
