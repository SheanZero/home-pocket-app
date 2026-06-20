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

/// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
///
/// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
/// running cumulative within the current month, plus a previous-month reference
/// line for the spend side (total/daily). The joy side is current-month-only —
/// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
/// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
/// instants — the use case derives the 2-month window from the month, so a
/// microsecond-exact key would explode the family cache. The shell normalizes
/// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
/// here; this provider defends the contract by re-anchoring to month precision.
///
/// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01).

@ProviderFor(withinMonthCumulativeTrend)
final withinMonthCumulativeTrendProvider = WithinMonthCumulativeTrendFamily._();

/// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
///
/// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
/// running cumulative within the current month, plus a previous-month reference
/// line for the spend side (total/daily). The joy side is current-month-only —
/// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
/// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
/// instants — the use case derives the 2-month window from the month, so a
/// microsecond-exact key would explode the family cache. The shell normalizes
/// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
/// here; this provider defends the contract by re-anchoring to month precision.
///
/// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01).

final class WithinMonthCumulativeTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<WithinMonthCumulativeTrend>,
          WithinMonthCumulativeTrend,
          FutureOr<WithinMonthCumulativeTrend>
        >
    with
        $FutureModifier<WithinMonthCumulativeTrend>,
        $FutureProvider<WithinMonthCumulativeTrend> {
  /// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
  ///
  /// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
  /// running cumulative within the current month, plus a previous-month reference
  /// line for the spend side (total/daily). The joy side is current-month-only —
  /// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
  /// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
  ///
  /// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
  /// instants — the use case derives the 2-month window from the month, so a
  /// microsecond-exact key would explode the family cache. The shell normalizes
  /// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
  /// here; this provider defends the contract by re-anchoring to month precision.
  ///
  /// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
  /// invalidates ZERO `home/*` providers (GUARD-01).
  WithinMonthCumulativeTrendProvider._({
    required WithinMonthCumulativeTrendFamily super.from,
    required ({
      String bookId,
      DateTime anchor,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'withinMonthCumulativeTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$withinMonthCumulativeTrendHash();

  @override
  String toString() {
    return r'withinMonthCumulativeTrendProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WithinMonthCumulativeTrend> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WithinMonthCumulativeTrend> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime anchor,
              JoyMetricVariant joyMetricVariant,
            });
    return withinMonthCumulativeTrend(
      ref,
      bookId: argument.bookId,
      anchor: argument.anchor,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WithinMonthCumulativeTrendProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$withinMonthCumulativeTrendHash() =>
    r'd52098662e8ca6bb02bccb64b2db7f4c45e90a6e';

/// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
///
/// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
/// running cumulative within the current month, plus a previous-month reference
/// line for the spend side (total/daily). The joy side is current-month-only —
/// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
/// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
/// instants — the use case derives the 2-month window from the month, so a
/// microsecond-exact key would explode the family cache. The shell normalizes
/// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
/// here; this provider defends the contract by re-anchoring to month precision.
///
/// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01).

final class WithinMonthCumulativeTrendFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WithinMonthCumulativeTrend>,
          ({String bookId, DateTime anchor, JoyMetricVariant joyMetricVariant})
        > {
  WithinMonthCumulativeTrendFamily._()
    : super(
        retry: null,
        name: r'withinMonthCumulativeTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
  ///
  /// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
  /// running cumulative within the current month, plus a previous-month reference
  /// line for the spend side (total/daily). The joy side is current-month-only —
  /// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
  /// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
  ///
  /// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
  /// instants — the use case derives the 2-month window from the month, so a
  /// microsecond-exact key would explode the family cache. The shell normalizes
  /// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
  /// here; this provider defends the contract by re-anchoring to month precision.
  ///
  /// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
  /// invalidates ZERO `home/*` providers (GUARD-01).

  WithinMonthCumulativeTrendProvider call({
    required String bookId,
    required DateTime anchor,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => WithinMonthCumulativeTrendProvider._(
    argument: (
      bookId: bookId,
      anchor: anchor,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'withinMonthCumulativeTrendProvider';
}

/// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
/// (deviceId) expense transactions over the active window — the donut's 分类
/// dimension WHEN a member filter is active (genuinely-functional global
/// narrowing: pick a member, see their category split).
///
/// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
/// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
/// percentage are placeholders; `DonutHero` re-resolves the localized name from
/// the id and re-computes percentages off the true total) plus the member's
/// total + entry count for the center figure.
///
/// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
/// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
///
/// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).

@ProviderFor(memberFilteredCategoryBreakdown)
final memberFilteredCategoryBreakdownProvider =
    MemberFilteredCategoryBreakdownFamily._();

/// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
/// (deviceId) expense transactions over the active window — the donut's 分类
/// dimension WHEN a member filter is active (genuinely-functional global
/// narrowing: pick a member, see their category split).
///
/// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
/// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
/// percentage are placeholders; `DonutHero` re-resolves the localized name from
/// the id and re-computes percentages off the true total) plus the member's
/// total + entry count for the center figure.
///
/// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
/// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
///
/// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).

final class MemberFilteredCategoryBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<MemberFilteredCategoryBreakdown>,
          MemberFilteredCategoryBreakdown,
          FutureOr<MemberFilteredCategoryBreakdown>
        >
    with
        $FutureModifier<MemberFilteredCategoryBreakdown>,
        $FutureProvider<MemberFilteredCategoryBreakdown> {
  /// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
  /// (deviceId) expense transactions over the active window — the donut's 分类
  /// dimension WHEN a member filter is active (genuinely-functional global
  /// narrowing: pick a member, see their category split).
  ///
  /// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
  /// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
  /// percentage are placeholders; `DonutHero` re-resolves the localized name from
  /// the id and re-computes percentages off the true total) plus the member's
  /// total + entry count for the center figure.
  ///
  /// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
  /// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
  ///
  /// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).
  MemberFilteredCategoryBreakdownProvider._({
    required MemberFilteredCategoryBreakdownFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      String deviceId,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'memberFilteredCategoryBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberFilteredCategoryBreakdownHash();

  @override
  String toString() {
    return r'memberFilteredCategoryBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MemberFilteredCategoryBreakdown> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MemberFilteredCategoryBreakdown> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              String deviceId,
              JoyMetricVariant joyMetricVariant,
            });
    return memberFilteredCategoryBreakdown(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      deviceId: argument.deviceId,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberFilteredCategoryBreakdownProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberFilteredCategoryBreakdownHash() =>
    r'c7f1012c4f2f7c8039dbb349e9ec12d8d41f41f2';

/// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
/// (deviceId) expense transactions over the active window — the donut's 分类
/// dimension WHEN a member filter is active (genuinely-functional global
/// narrowing: pick a member, see their category split).
///
/// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
/// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
/// percentage are placeholders; `DonutHero` re-resolves the localized name from
/// the id and re-computes percentages off the true total) plus the member's
/// total + entry count for the center figure.
///
/// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
/// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
///
/// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).

final class MemberFilteredCategoryBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MemberFilteredCategoryBreakdown>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            String deviceId,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  MemberFilteredCategoryBreakdownFamily._()
    : super(
        retry: null,
        name: r'memberFilteredCategoryBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
  /// (deviceId) expense transactions over the active window — the donut's 分类
  /// dimension WHEN a member filter is active (genuinely-functional global
  /// narrowing: pick a member, see their category split).
  ///
  /// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
  /// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
  /// percentage are placeholders; `DonutHero` re-resolves the localized name from
  /// the id and re-computes percentages off the true total) plus the member's
  /// total + entry count for the center figure.
  ///
  /// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
  /// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
  ///
  /// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).

  MemberFilteredCategoryBreakdownProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    required String deviceId,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => MemberFilteredCategoryBreakdownProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      deviceId: deviceId,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'memberFilteredCategoryBreakdownProvider';
}

/// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
/// donut's 成员 dimension over the active window.
///
/// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
/// Single-device degrades to one bucket (UI handles graceful degradation).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

@ProviderFor(memberSpendBreakdown)
final memberSpendBreakdownProvider = MemberSpendBreakdownFamily._();

/// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
/// donut's 成员 dimension over the active window.
///
/// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
/// Single-device degrades to one bucket (UI handles graceful degradation).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class MemberSpendBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberSpendBreakdown>>,
          List<MemberSpendBreakdown>,
          FutureOr<List<MemberSpendBreakdown>>
        >
    with
        $FutureModifier<List<MemberSpendBreakdown>>,
        $FutureProvider<List<MemberSpendBreakdown>> {
  /// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
  /// donut's 成员 dimension over the active window.
  ///
  /// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
  /// Single-device degrades to one bucket (UI handles graceful degradation).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
  /// defends the contract by re-normalizing the bounds via [DateBoundaries] before
  /// they reach the use case — never accept microsecond-exact instants into the
  /// family key (rebuild-storm guard).
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).
  MemberSpendBreakdownProvider._({
    required MemberSpendBreakdownFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'memberSpendBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberSpendBreakdownHash();

  @override
  String toString() {
    return r'memberSpendBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<MemberSpendBreakdown>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MemberSpendBreakdown>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return memberSpendBreakdown(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberSpendBreakdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberSpendBreakdownHash() =>
    r'0c3e688a398122cb08484c1f5c2115711fadd04e';

/// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
/// donut's 成员 dimension over the active window.
///
/// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
/// Single-device degrades to one bucket (UI handles graceful degradation).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class MemberSpendBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MemberSpendBreakdown>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  MemberSpendBreakdownFamily._()
    : super(
        retry: null,
        name: r'memberSpendBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
  /// donut's 成员 dimension over the active window.
  ///
  /// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
  /// Single-device degrades to one bucket (UI handles graceful degradation).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
  /// defends the contract by re-normalizing the bounds via [DateBoundaries] before
  /// they reach the use case — never accept microsecond-exact instants into the
  /// family key (rebuild-storm guard).
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).

  MemberSpendBreakdownProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => MemberSpendBreakdownProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'memberSpendBreakdownProvider';
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
/// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
/// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
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
/// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
/// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
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
  /// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
  /// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
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
/// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
/// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
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
  /// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
  /// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
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

/// All categories keyed by id — the {id -> Category} map the donut legend's
/// single-source L1 rollup needs (D-11). Read-only, auto-dispose; reuses the
/// existing accounting `categoryRepository.findAll()` (no new DAO). The SAME
/// `l1AncestorOf` rule the drill use case applies server-side is reapplied here
/// over the donut breakdowns so the legend rows equal the drill subtotals.

@ProviderFor(analyticsCategoriesMap)
final analyticsCategoriesMapProvider = AnalyticsCategoriesMapProvider._();

/// All categories keyed by id — the {id -> Category} map the donut legend's
/// single-source L1 rollup needs (D-11). Read-only, auto-dispose; reuses the
/// existing accounting `categoryRepository.findAll()` (no new DAO). The SAME
/// `l1AncestorOf` rule the drill use case applies server-side is reapplied here
/// over the donut breakdowns so the legend rows equal the drill subtotals.

final class AnalyticsCategoriesMapProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Category>>,
          Map<String, Category>,
          FutureOr<Map<String, Category>>
        >
    with
        $FutureModifier<Map<String, Category>>,
        $FutureProvider<Map<String, Category>> {
  /// All categories keyed by id — the {id -> Category} map the donut legend's
  /// single-source L1 rollup needs (D-11). Read-only, auto-dispose; reuses the
  /// existing accounting `categoryRepository.findAll()` (no new DAO). The SAME
  /// `l1AncestorOf` rule the drill use case applies server-side is reapplied here
  /// over the donut breakdowns so the legend rows equal the drill subtotals.
  AnalyticsCategoriesMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsCategoriesMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsCategoriesMapHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Category>> create(Ref ref) {
    return analyticsCategoriesMap(ref);
  }
}

String _$analyticsCategoriesMapHash() =>
    r'9d46f3d73be4d07ba4637ede874587fa4b8eeeb3';

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

/// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
///
/// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
/// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

@ProviderFor(joyCategoryAmounts)
final joyCategoryAmountsProvider = JoyCategoryAmountsFamily._();

/// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
///
/// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
/// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class JoyCategoryAmountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JoyCategoryAmount>>,
          List<JoyCategoryAmount>,
          FutureOr<List<JoyCategoryAmount>>
        >
    with
        $FutureModifier<List<JoyCategoryAmount>>,
        $FutureProvider<List<JoyCategoryAmount>> {
  /// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
  ///
  /// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
  /// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
  /// defends the contract by re-normalizing the bounds via [DateBoundaries] before
  /// they reach the use case — never accept microsecond-exact instants into the
  /// family key (rebuild-storm guard).
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).
  JoyCategoryAmountsProvider._({
    required JoyCategoryAmountsFamily super.from,
    required ({
      String bookId,
      DateTime startDate,
      DateTime endDate,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'joyCategoryAmountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joyCategoryAmountsHash();

  @override
  String toString() {
    return r'joyCategoryAmountsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<JoyCategoryAmount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JoyCategoryAmount>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime startDate,
              DateTime endDate,
              JoyMetricVariant joyMetricVariant,
            });
    return joyCategoryAmounts(
      ref,
      bookId: argument.bookId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JoyCategoryAmountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joyCategoryAmountsHash() =>
    r'dc30b88219c12ccfc15da8d6ee6567547a20286b';

/// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
///
/// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
/// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class JoyCategoryAmountsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<JoyCategoryAmount>>,
          ({
            String bookId,
            DateTime startDate,
            DateTime endDate,
            JoyMetricVariant joyMetricVariant,
          })
        > {
  JoyCategoryAmountsFamily._()
    : super(
        retry: null,
        name: r'joyCategoryAmountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
  ///
  /// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
  /// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
  ///
  /// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
  /// defends the contract by re-normalizing the bounds via [DateBoundaries] before
  /// they reach the use case — never accept microsecond-exact instants into the
  /// family key (rebuild-storm guard).
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).

  JoyCategoryAmountsProvider call({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => JoyCategoryAmountsProvider._(
    argument: (
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'joyCategoryAmountsProvider';
}

/// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
/// calendar heatmap depth.
///
/// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
/// Pitfall 3) within the month derived from [anchor].
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
/// re-anchors to month precision and derives the month's whole-day window, so a
/// microsecond-exact key never explodes the family cache.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

@ProviderFor(perDayJoyCounts)
final perDayJoyCountsProvider = PerDayJoyCountsFamily._();

/// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
/// calendar heatmap depth.
///
/// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
/// Pitfall 3) within the month derived from [anchor].
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
/// re-anchors to month precision and derives the month's whole-day window, so a
/// microsecond-exact key never explodes the family cache.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class PerDayJoyCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PerDayJoyCount>>,
          List<PerDayJoyCount>,
          FutureOr<List<PerDayJoyCount>>
        >
    with
        $FutureModifier<List<PerDayJoyCount>>,
        $FutureProvider<List<PerDayJoyCount>> {
  /// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
  /// calendar heatmap depth.
  ///
  /// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
  /// Pitfall 3) within the month derived from [anchor].
  ///
  /// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
  /// re-anchors to month precision and derives the month's whole-day window, so a
  /// microsecond-exact key never explodes the family cache.
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).
  PerDayJoyCountsProvider._({
    required PerDayJoyCountsFamily super.from,
    required ({
      String bookId,
      DateTime anchor,
      JoyMetricVariant joyMetricVariant,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'perDayJoyCountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perDayJoyCountsHash();

  @override
  String toString() {
    return r'perDayJoyCountsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PerDayJoyCount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PerDayJoyCount>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime anchor,
              JoyMetricVariant joyMetricVariant,
            });
    return perDayJoyCounts(
      ref,
      bookId: argument.bookId,
      anchor: argument.anchor,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerDayJoyCountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perDayJoyCountsHash() => r'f50e5b3ec0656ef871186628217fcb795a9b1d33';

/// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
/// calendar heatmap depth.
///
/// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
/// Pitfall 3) within the month derived from [anchor].
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
/// re-anchors to month precision and derives the month's whole-day window, so a
/// microsecond-exact key never explodes the family cache.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).

final class PerDayJoyCountsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PerDayJoyCount>>,
          ({String bookId, DateTime anchor, JoyMetricVariant joyMetricVariant})
        > {
  PerDayJoyCountsFamily._()
    : super(
        retry: null,
        name: r'perDayJoyCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
  /// calendar heatmap depth.
  ///
  /// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
  /// Pitfall 3) within the month derived from [anchor].
  ///
  /// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
  /// re-anchors to month precision and derives the month's whole-day window, so a
  /// microsecond-exact key never explodes the family cache.
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01).

  PerDayJoyCountsProvider call({
    required String bookId,
    required DateTime anchor,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => PerDayJoyCountsProvider._(
    argument: (
      bookId: bookId,
      anchor: anchor,
      joyMetricVariant: joyMetricVariant,
    ),
    from: this,
  );

  @override
  String toString() => r'perDayJoyCountsProvider';
}

/// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
/// heatmap's INLINE day expansion.
///
/// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
/// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
/// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
/// demand rather than widening the count model. Returns EXPENSE joy rows only,
/// time-descending, with the optional manualOnly entry-source filter applied —
/// the same gate the count path uses (Pitfall: findByBookIds has no
/// income/expense or entry-source SQL param).
///
/// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
/// here) so two callers with differing sub-day precision share one cache key.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
/// never logs tx contents (T-46-05-02).

@ProviderFor(joyDayTransactions)
final joyDayTransactionsProvider = JoyDayTransactionsFamily._();

/// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
/// heatmap's INLINE day expansion.
///
/// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
/// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
/// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
/// demand rather than widening the count model. Returns EXPENSE joy rows only,
/// time-descending, with the optional manualOnly entry-source filter applied —
/// the same gate the count path uses (Pitfall: findByBookIds has no
/// income/expense or entry-source SQL param).
///
/// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
/// here) so two callers with differing sub-day precision share one cache key.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
/// never logs tx contents (T-46-05-02).

final class JoyDayTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  /// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
  /// heatmap's INLINE day expansion.
  ///
  /// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
  /// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
  /// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
  /// demand rather than widening the count model. Returns EXPENSE joy rows only,
  /// time-descending, with the optional manualOnly entry-source filter applied —
  /// the same gate the count path uses (Pitfall: findByBookIds has no
  /// income/expense or entry-source SQL param).
  ///
  /// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
  /// here) so two callers with differing sub-day precision share one cache key.
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
  /// never logs tx contents (T-46-05-02).
  JoyDayTransactionsProvider._({
    required JoyDayTransactionsFamily super.from,
    required ({String bookId, DateTime day, JoyMetricVariant joyMetricVariant})
    super.argument,
  }) : super(
         retry: null,
         name: r'joyDayTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joyDayTransactionsHash();

  @override
  String toString() {
    return r'joyDayTransactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String bookId,
              DateTime day,
              JoyMetricVariant joyMetricVariant,
            });
    return joyDayTransactions(
      ref,
      bookId: argument.bookId,
      day: argument.day,
      joyMetricVariant: argument.joyMetricVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JoyDayTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joyDayTransactionsHash() =>
    r'ffcbe22225e80be82783df2b9ff83f804848df25';

/// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
/// heatmap's INLINE day expansion.
///
/// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
/// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
/// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
/// demand rather than widening the count model. Returns EXPENSE joy rows only,
/// time-descending, with the optional manualOnly entry-source filter applied —
/// the same gate the count path uses (Pitfall: findByBookIds has no
/// income/expense or entry-source SQL param).
///
/// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
/// here) so two callers with differing sub-day precision share one cache key.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
/// never logs tx contents (T-46-05-02).

final class JoyDayTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Transaction>>,
          ({String bookId, DateTime day, JoyMetricVariant joyMetricVariant})
        > {
  JoyDayTransactionsFamily._()
    : super(
        retry: null,
        name: r'joyDayTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
  /// heatmap's INLINE day expansion.
  ///
  /// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
  /// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
  /// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
  /// demand rather than widening the count model. Returns EXPENSE joy rows only,
  /// time-descending, with the optional manualOnly entry-source filter applied —
  /// the same gate the count path uses (Pitfall: findByBookIds has no
  /// income/expense or entry-source SQL param).
  ///
  /// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
  /// here) so two callers with differing sub-day precision share one cache key.
  ///
  /// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
  /// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
  /// never logs tx contents (T-46-05-02).

  JoyDayTransactionsProvider call({
    required String bookId,
    required DateTime day,
    JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  }) => JoyDayTransactionsProvider._(
    argument: (bookId: bookId, day: day, joyMetricVariant: joyMetricVariant),
    from: this,
  );

  @override
  String toString() => r'joyDayTransactionsProvider';
}
