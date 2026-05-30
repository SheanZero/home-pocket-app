// Widget tests for ListEmptyState (B3).
//
// ListEmptyState is defined in:
//   lib/features/list/presentation/widgets/list_empty_state.dart
//
// These tests cover both render paths:
//   - isFilterActive: false → receipt_long_outlined icon, no clearAll TextButton
//   - isFilterActive: true  → search_off_outlined icon + clearAll TextButton
//
// Run: flutter test test/widget/features/list/list_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Pumps a ListEmptyState inside UncontrolledProviderScope + MaterialApp.
///
/// [isFilterActive] controls which render path is exercised.
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
            child: ListEmptyState(isFilterActive: isFilterActive),
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
      expect(
        find.byIcon(Icons.receipt_long_outlined),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets(
        'isFilterActive: true — shows search_off_outlined icon and clearAll TextButton',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, isFilterActive: true);
      expect(
        find.byIcon(Icons.search_off_outlined),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
