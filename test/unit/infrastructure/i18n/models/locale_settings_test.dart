import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/models/locale_settings.dart';

void main() {
  group('LocaleSettings', () {
    test('defaultSettings returns Japanese locale', () {
      final settings = LocaleSettings.defaultSettings();
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('fromSystem with supported locale uses it', () {
      final settings = LocaleSettings.fromSystem(const Locale('en'));
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with Chinese locale uses it', () {
      final settings = LocaleSettings.fromSystem(const Locale('zh'));
      expect(settings.locale, const Locale('zh'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with unsupported locale falls back to Japanese', () {
      final settings = LocaleSettings.fromSystem(const Locale('ko'));
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with French locale falls back to Japanese', () {
      final settings = LocaleSettings.fromSystem(const Locale('fr'));
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('copyWith preserves existing values', () {
      final original = LocaleSettings.defaultSettings();
      final copied = original.copyWith(locale: const Locale('en'));
      expect(copied.locale, const Locale('en'));
      expect(copied.isSystemDefault, original.isSystemDefault);
    });
  });
}
