import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/entities/locale_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';

void main() {
  group('LocaleProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with Japanese locale', () {
      // Act
      final settings = container.read(localeNotifierProvider);

      // Assert
      expect(settings.locale.languageCode, 'ja');
      expect(settings.isSystemDefault, false);
    });

    test('should change locale when setLocale is called', () {
      // Arrange
      final notifier = container.read(localeNotifierProvider.notifier);

      // Act
      notifier.setLocale(const Locale('en'));

      // Assert
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale.languageCode, 'en');
      expect(settings.isSystemDefault, false);
    });

    test('should support Chinese locale', () {
      // Arrange
      final notifier = container.read(localeNotifierProvider.notifier);

      // Act
      notifier.setLocale(const Locale('zh'));

      // Assert
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale.languageCode, 'zh');
    });

    test('should set system default locale', () {
      // Arrange
      final notifier = container.read(localeNotifierProvider.notifier);

      // Act
      notifier.setSystemDefault(const Locale('en'));

      // Assert
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale.languageCode, 'en');
      expect(settings.isSystemDefault, true);
    });
  });
}
