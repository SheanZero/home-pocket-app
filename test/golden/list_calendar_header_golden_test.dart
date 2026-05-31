// Golden tests for [CalendarHeaderWidget] (Phase 30, D-01/D-02/D-03).
//
// Covers: 3 locales (ja, zh, en), light theme.
//
// DETERMINISM FIX (D-03):
// list_calendar_header.dart:142 calls DateTime.now() to compute isToday.
// Overriding listFilterProvider to January 2025 ensures the pinned month
// is always in the past relative to CI (running 2026+), so no calendar
// cell ever matches today → no special decoration → deterministic render.
//
// Run: flutter test test/golden/list_calendar_header_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/state_calendar_totals.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_calendar_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';

// January 2025 is always in the past relative to CI (2026+).
// No calendar cell will ever match DateTime.now() → deterministic render.
const int _fixedYear = 2025;
const int _fixedMonth = 1;

/// Fixed ListFilter notifier override — returns a known state synchronously.
/// Required because listFilterProvider is a @Riverpod Notifier (not a plain
/// Provider), so overrideWith must supply a Notifier instance.
class _FixedListFilter extends ListFilter {
  @override
  ListFilterState build() => const ListFilterState(
        selectedYear: _fixedYear,
        selectedMonth: _fixedMonth,
      );
}

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      // REQUIRED: prevents DateTime.now() flake in _buildDayCell (line 142).
      // Pinning to Jan 2025 ensures isToday is always false for every cell.
      listFilterProvider.overrideWith(() => _FixedListFilter()),
      // Empty daily totals — no amounts on calendar cells, deterministic.
      calendarDailyTotalsProvider(
        bookId: 'test_book',
        year: _fixedYear,
        month: _fixedMonth,
      ).overrideWith((_) async => <DateTime, int>{}),
      // Solo mode — no family member data needed.
      isGroupModeProvider.overrideWith((_) => false),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 520,
          child: CalendarHeaderWidget(
            bookId: 'test_book',
            currencyCode: 'JPY',
            locale: locale,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CalendarHeaderWidget golden', () {
    testWidgets('locale ja — January 2025 (deterministic)', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle(); // drains AnimatedSize in _SummaryRow
      await expectLater(
        find.byType(CalendarHeaderWidget),
        matchesGoldenFile('goldens/list_calendar_header_ja.png'),
      );
    });

    testWidgets('locale zh — January 2025 (deterministic)', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CalendarHeaderWidget),
        matchesGoldenFile('goldens/list_calendar_header_zh.png'),
      );
    });

    testWidgets('locale en — January 2025 (deterministic)', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CalendarHeaderWidget),
        matchesGoldenFile('goldens/list_calendar_header_en.png'),
      );
    });
  });
}
