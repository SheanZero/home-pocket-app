// Wave 0 widget test stubs for ListEmptyState (B3).
//
// ListEmptyState is defined in:
//   lib/features/list/presentation/widgets/list_empty_state.dart
// TODO: created in 28-04 — that widget does not exist yet; the import below
// will fail to resolve until Wave 3 (28-04) creates the file.
//
// These stubs cover both render paths:
//   - isFilterActive: false → receipt_long_outlined icon, no clearAll TextButton
//   - isFilterActive: true  → search_off_outlined icon + clearAll TextButton
//
// Run: flutter test test/widget/features/list/list_empty_state_test.dart

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/generated/app_localizations.dart';
// TODO: created in 28-04
// import 'package:home_pocket/features/list/presentation/widgets/list_empty_state.dart';

/// Pumps a ListEmptyState stub inside UncontrolledProviderScope + MaterialApp.
///
/// [isFilterActive] controls which render path is exercised.
/// TODO: uncomment and wire ListEmptyState once 28-04 creates it.
Future<void> _pumpEmptyState(
  WidgetTester tester,
  ProviderContainer container, {
  required bool isFilterActive,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Center(
            // TODO: created in 28-04 — replace with:
            // ListEmptyState(isFilterActive: isFilterActive),
            child: Text('empty_state stub: isFilterActive=$isFilterActive'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ListEmptyState', () {
    testWidgets(
        'isFilterActive: false — shows receipt_long_outlined icon, no clearAll button',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, isFilterActive: false);
      // TODO: created in 28-04 — implement after ListEmptyState exists:
      //   expect(
      //     find.byIcon(Icons.receipt_long_outlined),
      //     findsOneWidget,
      //   );
      //   expect(find.byType(TextButton), findsNothing);
      fail(
        'implement in 28-04 after ListEmptyState is created — '
        'verify Icons.receipt_long_outlined and no TextButton',
      );
    });

    testWidgets(
        'isFilterActive: true — shows search_off_outlined icon and clearAll TextButton',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, isFilterActive: true);
      // TODO: created in 28-04 — implement after ListEmptyState exists:
      //   expect(
      //     find.byIcon(Icons.search_off_outlined),
      //     findsOneWidget,
      //   );
      //   expect(find.byType(TextButton), findsOneWidget);
      fail(
        'implement in 28-04 after ListEmptyState is created — '
        'verify Icons.search_off_outlined and clearAll TextButton',
      );
    });
  });
}
