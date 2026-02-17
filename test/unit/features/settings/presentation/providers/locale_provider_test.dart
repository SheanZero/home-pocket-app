import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/infrastructure/i18n/models/locale_settings.dart';

void main() {
  group('LocaleNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is Japanese default', () {
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('setLocale changes to English', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('setLocale changes to Chinese', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('zh'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('zh'));
    });

    test('setSystemDefault uses system locale', () {
      container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault(const Locale('en'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('setSystemDefault falls back for unsupported locale', () {
      container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault(const Locale('ko'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('resetToDefault restores Japanese', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      container.read(localeNotifierProvider.notifier).resetToDefault();
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
    });
  });

  group('currentLocaleProvider', () {
    test('returns locale from LocaleNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentLocaleProvider), const Locale('ja'));

      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      expect(container.read(currentLocaleProvider), const Locale('en'));
    });
  });
}
