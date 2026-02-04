import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/entities/locale_settings.dart';

void main() {
  group('LocaleSettings', () {
    test('should create LocaleSettings with default Japanese locale', () {
      // Arrange & Act
      const settings = LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

      // Assert
      expect(settings.locale.languageCode, 'ja');
      expect(settings.isSystemDefault, false);
    });

    test('should support copyWith for immutability', () {
      // Arrange
      const settings = LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

      // Act
      final updated = settings.copyWith(locale: const Locale('en'));

      // Assert
      expect(updated.locale.languageCode, 'en');
      expect(updated.isSystemDefault, false);
      expect(settings.locale.languageCode, 'ja'); // Original unchanged
    });

    test('should support equality comparison', () {
      // Arrange
      const settings1 = LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );
      const settings2 = LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );
      const settings3 = LocaleSettings(
        locale: Locale('en'),
        isSystemDefault: false,
      );

      // Assert
      expect(settings1, settings2);
      expect(settings1, isNot(settings3));
    });
  });
}
