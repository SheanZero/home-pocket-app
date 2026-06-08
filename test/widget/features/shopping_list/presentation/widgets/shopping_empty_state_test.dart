// Widget tests for ShoppingEmptyState — 3-variant empty state (SHOP-04).
//
// ShoppingEmptyState is defined in:
//   lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart
//
// 3-way variant branch: (listType, isGroupModeProvider)
//   - private  → privateEmpty  → shopping_bag_outlined icon
//   - public + !isGroupMode → publicSolo → group_outlined icon
//   - public + isGroupMode  → publicFamily → add_shopping_cart_outlined icon
//
// Run: flutter test test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Pumps a ShoppingEmptyState with overridden [isGroupModeProvider].
Future<void> _pumpEmptyState(
  WidgetTester tester, {
  required String listType,
  required bool isGroupMode,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isGroupModeProvider.overrideWith((_) => isGroupMode),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ShoppingEmptyState(listType: listType),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ShoppingEmptyState', () {
    // SHOP-04: private list → privateEmpty variant
    testWidgets(
      'SHOP-04 private: shopping_bag_outlined icon rendered',
      (tester) async {
        await _pumpEmptyState(
          tester,
          listType: 'private',
          isGroupMode: false,
        );

        expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
        // CTA button always present for all variants
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    // SHOP-04: public + no family → publicSolo variant
    testWidgets(
      'SHOP-04 public solo: group_outlined icon rendered',
      (tester) async {
        await _pumpEmptyState(
          tester,
          listType: 'public',
          isGroupMode: false,
        );

        expect(find.byIcon(Icons.group_outlined), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    // SHOP-04: public + family → publicFamily variant
    testWidgets(
      'SHOP-04 public family: add_shopping_cart_outlined icon rendered',
      (tester) async {
        await _pumpEmptyState(
          tester,
          listType: 'public',
          isGroupMode: true,
        );

        expect(find.byIcon(Icons.add_shopping_cart_outlined), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    // CTA button tapping: should navigate to ShoppingItemFormScreen
    testWidgets(
      'CTA button navigates to ShoppingItemFormScreen',
      (tester) async {
        await _pumpEmptyState(
          tester,
          listType: 'private',
          isGroupMode: false,
        );

        await tester.tap(find.byType(FilledButton));
        // Use pump() instead of pumpAndSettle() — the stub screen has a
        // CircularProgressIndicator that never settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // ShoppingItemFormScreen stub is pushed
        expect(find.byType(ShoppingItemFormScreen), findsOneWidget);
      },
    );

    // Private always privateEmpty regardless of isGroupMode
    testWidgets(
      'private list always privateEmpty even when isGroupMode=true',
      (tester) async {
        await _pumpEmptyState(
          tester,
          listType: 'private',
          isGroupMode: true,
        );

        expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
        expect(find.byIcon(Icons.add_shopping_cart_outlined), findsNothing);
      },
    );
  });
}
