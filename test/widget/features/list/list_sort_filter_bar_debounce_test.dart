// Widget tests for ListSortFilterBar search debounce (P2-1).
//
// Typing in the search box must defer the (now cheap, but still non-free)
// `setSearch` filter update by 300ms, while explicit clears stay immediate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_sort_filter_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Future<ProviderContainer> _pumpBar(WidgetTester tester) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isGroupModeProvider.overrideWithValue(false),
        shadowBooksProvider.overrideWith((_) async => const <ShadowBookInfo>[]),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(body: ListSortFilterBar(bookId: 'book1')),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _expandSearch(WidgetTester tester) async {
  await tester.ensureVisible(find.byIcon(Icons.search));
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'P2-1: typing debounces setSearch by 300ms (not applied before the window)',
    (tester) async {
      final container = await _pumpBar(tester);
      await _expandSearch(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      // Within the debounce window the filter must NOT have updated yet.
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        container.read(listFilterProvider).searchQuery,
        '',
        reason: 'searchQuery must not update until the 300ms debounce elapses',
      );

      // After the window elapses, the filter reflects the typed text.
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        container.read(listFilterProvider).searchQuery,
        'abc',
        reason: 'searchQuery must update once the debounce fires',
      );
    },
  );

  testWidgets(
    'P2-1: only the final keystroke is applied (intermediate edits coalesced)',
    (tester) async {
      final container = await _pumpBar(tester);
      await _expandSearch(tester);

      final field = find.byType(TextField);
      await tester.enterText(field, 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'ab');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'abc');
      // Total elapsed since last edit < 300ms → still not applied.
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(listFilterProvider).searchQuery, '');

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        container.read(listFilterProvider).searchQuery,
        'abc',
        reason: 'debounce coalesces rapid edits to the final value',
      );
    },
  );

  testWidgets(
    'P2-1: the clear (X) affordance applies immediately, not debounced',
    (tester) async {
      final container = await _pumpBar(tester);
      await _expandSearch(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(listFilterProvider).searchQuery, 'abc');

      // Tapping the clear icon must reset the search WITHOUT waiting 300ms, and
      // must cancel any pending debounce so it cannot re-apply stale text.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(
        container.read(listFilterProvider).searchQuery,
        '',
        reason: 'clear is immediate (not routed through the debounce)',
      );
    },
  );
}
