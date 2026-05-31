// Widget tests for ListEmptyState — 3-state enum-driven variant API (Phase 30, D-04/D-05).
//
// ListEmptyState is defined in:
//   lib/features/list/presentation/widgets/list_empty_state.dart
//
// These tests cover all 3 render variants:
//   - ListEmptyVariant.noData    → receipt_long_outlined icon, no TextButton
//   - ListEmptyVariant.dayEmpty  → event_busy_outlined icon + TextButton
//   - ListEmptyVariant.filtered  → search_off_outlined icon + TextButton
//
// Run: flutter test test/widget/features/list/list_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Pumps a ListEmptyState inside UncontrolledProviderScope + MaterialApp.
///
/// [variant] controls which of the 3 render paths is exercised.
Future<void> _pumpEmptyState(
  WidgetTester tester,
  ProviderContainer container, {
  required ListEmptyVariant variant,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ListEmptyState(variant: variant),
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
        'noData — receipt_long_outlined icon, no action button',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, variant: ListEmptyVariant.noData);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets(
        'dayEmpty — event_busy_outlined icon + "show full month" TextButton',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, variant: ListEmptyVariant.dayEmpty);
      expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets(
        'filtered — search_off_outlined icon + "clear filters" TextButton',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpEmptyState(tester, container, variant: ListEmptyVariant.filtered);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
