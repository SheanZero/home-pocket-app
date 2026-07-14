// Widget tests for ListLedgerSegments (v15 A1/A3 port).
//
// The ledger filter (すべて / 日常 / ときめき) graduated from inline chips in
// ListSortFilterBar to a dedicated full-width segmented control. These tests
// cover the FILTER-02 behaviour (tapping a segment sets/clears ledgerType) that
// previously lived in list_sort_filter_bar_test.dart.
//
// Run: flutter test test/widget/features/list/list_ledger_segments_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_ledger_segments.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Future<ProviderContainer> _pumpSegments(WidgetTester tester) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(
              body: ListLedgerSegments(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('ListLedgerSegments', () {
    testWidgets('renders three segments (すべて / 日常 / ときめき)',
        (tester) async {
      await _pumpSegments(tester);

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('ときめき'), findsOneWidget);
    });

    testWidgets('FILTER-02: tapping 日常 sets ledgerType.daily', (tester) async {
      final container = await _pumpSegments(tester);

      expect(container.read(listFilterProvider).ledgerType, isNull);

      await tester.tap(find.text('日常'));
      await tester.pumpAndSettle();

      expect(
        container.read(listFilterProvider).ledgerType,
        equals(LedgerType.daily),
      );
    });

    testWidgets('tapping ときめき sets ledgerType.joy', (tester) async {
      final container = await _pumpSegments(tester);

      await tester.tap(find.text('ときめき'));
      await tester.pumpAndSettle();

      expect(
        container.read(listFilterProvider).ledgerType,
        equals(LedgerType.joy),
      );
    });

    testWidgets('tapping すべて clears the ledger filter', (tester) async {
      final container = await _pumpSegments(tester);

      // Start from a set filter.
      container
          .read(listFilterProvider.notifier)
          .setLedgerFilter(LedgerType.joy);
      await tester.pump();

      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle();

      expect(container.read(listFilterProvider).ledgerType, isNull);
    });
  });
}
