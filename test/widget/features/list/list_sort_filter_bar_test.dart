// Widget tests for ListSortFilterBar (SORT-01..04, FILTER-01..04).
//
// ListSortFilterBar is defined in:
//   lib/features/list/presentation/widgets/list_sort_filter_bar.dart
//
// Run: flutter test test/widget/features/list/list_sort_filter_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_sort_filter_bar.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

/// Pumps a ListSortFilterBar inside a ProviderScope + MaterialApp with ja locale.
///
/// Overrides [currentLocaleProvider] with a synchronous `ja` value to avoid
/// pending-timer issues from the async settings-repository chain (same pattern
/// as list_category_filter_sheet_test.dart).
Future<ProviderContainer> _pumpBar(WidgetTester tester) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locale_providers.currentLocaleProvider
            .overrideWith((_) async => const Locale('ja')),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(
              body: ListSortFilterBar(bookId: 'book1'),
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
  group('ListSortFilterBar', () {
    testWidgets(
        'SC#4: sort chip label reflects current field name (not generic Sort)',
        (tester) async {
      // Initial state: SortField.timestamp (updated from updatedAt in quick task 260531-oqn)
      // — label should be '日付' (ja), NOT a generic 'Sort' string.
      final container = await _pumpBar(tester);

      // Verify active-field label is present
      expect(find.text('日付'), findsOneWidget);
      // Generic 'Sort' must not appear
      expect(find.text('Sort'), findsNothing);

      // Suppress unused variable warning
      expect(container.read(listFilterProvider).sortConfig.sortField,
          equals(SortField.timestamp));
    });

    // FILTER-02 (tapping the ledger chip) moved to list_ledger_segments_test.dart
    // when the ledger filter graduated from inline chips to the full-width
    // ListLedgerSegments control (v15 A1/A3 port). The bar no longer owns it.

    testWidgets('FILTER-04: clear chip appears only when filter active',
        (tester) async {
      final container = await _pumpBar(tester);

      // Initially no filter active → clear chip should be absent.
      expect(find.text('クリア'), findsNothing);

      // Set a ledger filter → clear chip should appear.
      container
          .read(listFilterProvider.notifier)
          .setLedgerFilter(LedgerType.joy);
      await tester.pump();
      expect(find.text('クリア'), findsOneWidget);

      // Provider state reflects the change.
      expect(
        container.read(listFilterProvider).ledgerType,
        equals(LedgerType.joy),
      );
    });
  });
}
