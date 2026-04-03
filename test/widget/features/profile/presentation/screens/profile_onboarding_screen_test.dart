import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_onboarding_screen.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  group('ProfileOnboardingScreen', () {
    testWidgets('shows welcome text and start button initially', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const ProfileOnboardingScreen(bookId: 'book-1'),
          locale: const Locale('ja'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('はじめまして！'), findsOneWidget);
      expect(find.textContaining('まもる家計簿へようこそ'), findsOneWidget);
      expect(find.textContaining('はじめる'), findsOneWidget);
    });

    testWidgets('keeps the start button visible when nickname is entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const ProfileOnboardingScreen(bookId: 'book-1'),
          locale: const Locale('ja'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'たけし');
      await tester.pumpAndSettle();

      expect(find.textContaining('はじめる'), findsOneWidget);
    });

    testWidgets('shows a tappable avatar area', (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const ProfileOnboardingScreen(bookId: 'book-1'),
          locale: const Locale('ja'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
