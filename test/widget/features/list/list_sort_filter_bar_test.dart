// Wave 0 widget test stubs for ListSortFilterBar (SORT-01..04, FILTER-01..04).
//
// ListSortFilterBar is defined in:
//   lib/features/list/presentation/widgets/list_sort_filter_bar.dart
// TODO: created in 28-05 — that widget does not exist yet; the import below
// will fail to resolve until Wave 4 (28-05) creates the file.
//
// Run: flutter test test/widget/features/list/list_sort_filter_bar_test.dart

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/list_sort_config.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';
// TODO: created in 28-05
// import 'package:home_pocket/features/list/presentation/widgets/list_sort_filter_bar.dart';

/// Pumps a ListSortFilterBar stub inside UncontrolledProviderScope + MaterialApp.
///
/// TODO: uncomment and wire ListSortFilterBar once 28-05 creates it.
Future<void> _pumpBar(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const Scaffold(
          body: Center(
            // TODO: created in 28-05 — replace with:
            // ListSortFilterBar(bookId: 'book1'),
            child: Text('sort_filter_bar stub'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ListSortFilterBar', () {
    testWidgets(
        'SC#4: sort chip label reflects current field name (not generic Sort)',
        (tester) async {
      // Initial state: SortField.updatedAt — label should be '更新日時' (ja)
      // or 'Edit time' (en), NOT a generic 'Sort' string.
      final container = ProviderContainer.test();
      await _pumpBar(tester, container);
      // TODO: created in 28-05 — implement after ListSortFilterBar exists:
      //   expect(find.text('更新日時'), findsOneWidget);
      //   expect(find.text('Sort'), findsNothing);
      fail('implement in 28-05 after ListSortFilterBar is created');
    });

    testWidgets('FILTER-02: tapping ledger chip sets ledgerFilter',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpBar(tester, container);
      // TODO: created in 28-05 — implement after ListSortFilterBar exists:
      //   await tester.tap(find.text('生存'));
      //   await tester.pumpAndSettle();
      //   expect(
      //     container.read(listFilterProvider).ledgerType,
      //     equals(LedgerType.survival),
      //   );
      fail('implement in 28-05 after ListSortFilterBar is created');
    });

    testWidgets('FILTER-04: clear chip appears only when filter active',
        (tester) async {
      // Use ProviderContainer.test() to manipulate filter state, then pump bar.
      final container = ProviderContainer.test();

      // Initially no filter active → clear chip should be absent.
      await _pumpBar(tester, container);
      // TODO: created in 28-05 — implement:
      //   expect(find.text('クリア'), findsNothing);

      // Set a ledger filter → clear chip should appear.
      container
          .read(listFilterProvider.notifier)
          .setLedgerFilter(LedgerType.soul);
      await tester.pump();
      // TODO: created in 28-05 — implement:
      //   expect(find.text('クリア'), findsOneWidget);

      // Partial GREEN: provider state is verifiable even without bar widget.
      expect(
        container.read(listFilterProvider).ledgerType,
        equals(LedgerType.soul),
      );
    });
  });
}
