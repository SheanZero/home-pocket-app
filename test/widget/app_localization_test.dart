import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/app.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';

void main() {
  group('HomePocketApp Localization', () {
    testWidgets('should initialize with Japanese locale', (tester) async {
      // Arrange
      final container = ProviderContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );

      // Assert
      final locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'ja');
    });

    testWidgets('should update locale when provider changes', (tester) async {
      // Arrange
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );

      // Act
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      // Assert
      final locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'en');
    });

    testWidgets('should support all three locales', (tester) async {
      // Arrange
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );

      // Test Japanese
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('ja'));
      await tester.pumpAndSettle();
      expect(container.read(currentLocaleProvider).languageCode, 'ja');

      // Test Chinese
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('zh'));
      await tester.pumpAndSettle();
      expect(container.read(currentLocaleProvider).languageCode, 'zh');

      // Test English
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(container.read(currentLocaleProvider).languageCode, 'en');
    });
  });
}
