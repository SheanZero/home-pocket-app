// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_calendar_totals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-day expense totals for the calendar header.
///
/// Watches (bookId, year, month) AND the selected ledger from
/// [listFilterProvider] via a narrow `.select`, so day-cell amounts and the
/// month total reflect the active ledger. It still does NOT watch
/// memberBookId/search — narrowing to `ledgerType` alone keeps the "31 cells
/// re-render on every keystroke" hazard (Pitfall 3) away.
///
/// Phase 29 seam: bookId is a single value (own-book only).

@ProviderFor(calendarDailyTotals)
final calendarDailyTotalsProvider = CalendarDailyTotalsFamily._();

/// Per-day expense totals for the calendar header.
///
/// Watches (bookId, year, month) AND the selected ledger from
/// [listFilterProvider] via a narrow `.select`, so day-cell amounts and the
/// month total reflect the active ledger. It still does NOT watch
/// memberBookId/search — narrowing to `ledgerType` alone keeps the "31 cells
/// re-render on every keystroke" hazard (Pitfall 3) away.
///
/// Phase 29 seam: bookId is a single value (own-book only).

final class CalendarDailyTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, int>>,
          Map<DateTime, int>,
          FutureOr<Map<DateTime, int>>
        >
    with
        $FutureModifier<Map<DateTime, int>>,
        $FutureProvider<Map<DateTime, int>> {
  /// Per-day expense totals for the calendar header.
  ///
  /// Watches (bookId, year, month) AND the selected ledger from
  /// [listFilterProvider] via a narrow `.select`, so day-cell amounts and the
  /// month total reflect the active ledger. It still does NOT watch
  /// memberBookId/search — narrowing to `ledgerType` alone keeps the "31 cells
  /// re-render on every keystroke" hazard (Pitfall 3) away.
  ///
  /// Phase 29 seam: bookId is a single value (own-book only).
  CalendarDailyTotalsProvider._({
    required CalendarDailyTotalsFamily super.from,
    required ({String bookId, int year, int month}) super.argument,
  }) : super(
         retry: null,
         name: r'calendarDailyTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarDailyTotalsHash();

  @override
  String toString() {
    return r'calendarDailyTotalsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<DateTime, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<DateTime, int>> create(Ref ref) {
    final argument = this.argument as ({String bookId, int year, int month});
    return calendarDailyTotals(
      ref,
      bookId: argument.bookId,
      year: argument.year,
      month: argument.month,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarDailyTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarDailyTotalsHash() =>
    r'86307fc71c34ad9a24cffafe4cac4b405ec9c3a2';

/// Per-day expense totals for the calendar header.
///
/// Watches (bookId, year, month) AND the selected ledger from
/// [listFilterProvider] via a narrow `.select`, so day-cell amounts and the
/// month total reflect the active ledger. It still does NOT watch
/// memberBookId/search — narrowing to `ledgerType` alone keeps the "31 cells
/// re-render on every keystroke" hazard (Pitfall 3) away.
///
/// Phase 29 seam: bookId is a single value (own-book only).

final class CalendarDailyTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<DateTime, int>>,
          ({String bookId, int year, int month})
        > {
  CalendarDailyTotalsFamily._()
    : super(
        retry: null,
        name: r'calendarDailyTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-day expense totals for the calendar header.
  ///
  /// Watches (bookId, year, month) AND the selected ledger from
  /// [listFilterProvider] via a narrow `.select`, so day-cell amounts and the
  /// month total reflect the active ledger. It still does NOT watch
  /// memberBookId/search — narrowing to `ledgerType` alone keeps the "31 cells
  /// re-render on every keystroke" hazard (Pitfall 3) away.
  ///
  /// Phase 29 seam: bookId is a single value (own-book only).

  CalendarDailyTotalsProvider call({
    required String bookId,
    required int year,
    required int month,
  }) => CalendarDailyTotalsProvider._(
    argument: (bookId: bookId, year: year, month: month),
    from: this,
  );

  @override
  String toString() => r'calendarDailyTotalsProvider';
}

/// Family-wide month totals split by ledger.
///
/// This intentionally ignores search, category, day, and member filters. The
/// calendar receipt footer is a stable monthly family overview; only the
/// selected month and the locally available family books affect it.

@ProviderFor(calendarFamilyLedgerTotals)
final calendarFamilyLedgerTotalsProvider = CalendarFamilyLedgerTotalsFamily._();

/// Family-wide month totals split by ledger.
///
/// This intentionally ignores search, category, day, and member filters. The
/// calendar receipt footer is a stable monthly family overview; only the
/// selected month and the locally available family books affect it.

final class CalendarFamilyLedgerTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalendarLedgerTotals>,
          CalendarLedgerTotals,
          FutureOr<CalendarLedgerTotals>
        >
    with
        $FutureModifier<CalendarLedgerTotals>,
        $FutureProvider<CalendarLedgerTotals> {
  /// Family-wide month totals split by ledger.
  ///
  /// This intentionally ignores search, category, day, and member filters. The
  /// calendar receipt footer is a stable monthly family overview; only the
  /// selected month and the locally available family books affect it.
  CalendarFamilyLedgerTotalsProvider._({
    required CalendarFamilyLedgerTotalsFamily super.from,
    required ({String bookId, int year, int month}) super.argument,
  }) : super(
         retry: null,
         name: r'calendarFamilyLedgerTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarFamilyLedgerTotalsHash();

  @override
  String toString() {
    return r'calendarFamilyLedgerTotalsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CalendarLedgerTotals> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalendarLedgerTotals> create(Ref ref) {
    final argument = this.argument as ({String bookId, int year, int month});
    return calendarFamilyLedgerTotals(
      ref,
      bookId: argument.bookId,
      year: argument.year,
      month: argument.month,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarFamilyLedgerTotalsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarFamilyLedgerTotalsHash() =>
    r'4badf1ae79e8caf0087fe23d8f14c41d4d1a8178';

/// Family-wide month totals split by ledger.
///
/// This intentionally ignores search, category, day, and member filters. The
/// calendar receipt footer is a stable monthly family overview; only the
/// selected month and the locally available family books affect it.

final class CalendarFamilyLedgerTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CalendarLedgerTotals>,
          ({String bookId, int year, int month})
        > {
  CalendarFamilyLedgerTotalsFamily._()
    : super(
        retry: null,
        name: r'calendarFamilyLedgerTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family-wide month totals split by ledger.
  ///
  /// This intentionally ignores search, category, day, and member filters. The
  /// calendar receipt footer is a stable monthly family overview; only the
  /// selected month and the locally available family books affect it.

  CalendarFamilyLedgerTotalsProvider call({
    required String bookId,
    required int year,
    required int month,
  }) => CalendarFamilyLedgerTotalsProvider._(
    argument: (bookId: bookId, year: year, month: month),
    from: this,
  );

  @override
  String toString() => r'calendarFamilyLedgerTotalsProvider';
}
