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
