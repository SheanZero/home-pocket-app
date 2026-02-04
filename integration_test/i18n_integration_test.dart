import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:home_pocket/app.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/formatters/date_formatter.dart';
import 'package:home_pocket/shared/utils/formatters/number_formatter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Internationalization Integration Tests', () {
    testWidgets('Full locale switching flow', (tester) async {
      // Arrange
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Japanese (default)
      var locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'ja');

      // Switch to English
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'en');

      // Switch to Chinese
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('zh'));
      await tester.pumpAndSettle();

      locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'zh');

      // Switch back to Japanese
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('ja'));
      await tester.pumpAndSettle();

      locale = container.read(currentLocaleProvider);
      expect(locale.languageCode, 'ja');
    });

    testWidgets('Localized strings appear in UI', (tester) async {
      // Arrange
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Switch to Japanese
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('ja'));
      await tester.pumpAndSettle();

      // Assert - Verify Japanese strings exist
      final jaLocalizations = await S.delegate.load(const Locale('ja'));
      expect(jaLocalizations.appName, 'Home Pocket');
      expect(jaLocalizations.home, 'ホーム');

      // Act - Switch to English
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      // Assert - Verify English strings
      final enLocalizations = await S.delegate.load(const Locale('en'));
      expect(enLocalizations.home, 'Home');

      // Act - Switch to Chinese
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('zh'));
      await tester.pumpAndSettle();

      // Assert - Verify Chinese strings
      final zhLocalizations = await S.delegate.load(const Locale('zh'));
      expect(zhLocalizations.home, '首页');
    });

    testWidgets('Date formatting updates with locale', (tester) async {
      // Arrange
      final container = ProviderContainer();
      final testDate = DateTime(2026, 2, 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Test Japanese format
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('ja'));
      await tester.pumpAndSettle();
      var formatted = DateFormatter.formatDate(testDate, const Locale('ja'));
      expect(formatted, '2026/02/03');

      // Test English format
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      formatted = DateFormatter.formatDate(testDate, const Locale('en'));
      expect(formatted, '02/03/2026');

      // Test Chinese format
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('zh'));
      await tester.pumpAndSettle();
      formatted = DateFormatter.formatDate(testDate, const Locale('zh'));
      expect(formatted, '2026年02月03日');
    });

    testWidgets('Currency formatting updates with locale', (tester) async {
      // Arrange
      final container = ProviderContainer();
      final amount = 1234.56;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Test JPY formatting
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('ja'));
      await tester.pumpAndSettle();
      var formatted = NumberFormatter.formatCurrency(amount, 'JPY', const Locale('ja'));
      expect(formatted, contains('¥'));

      // Test USD formatting
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      formatted = NumberFormatter.formatCurrency(amount, 'USD', const Locale('en'));
      expect(formatted, contains('\$'));

      // Test CNY formatting
      container.read(localeNotifierProvider.notifier).setLocale(const Locale('zh'));
      await tester.pumpAndSettle();
      formatted = NumberFormatter.formatCurrency(amount, 'CNY', const Locale('zh'));
      expect(formatted, contains('¥'));
    });
  });
}
