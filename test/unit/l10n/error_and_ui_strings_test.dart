import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  group('Error Message and UI Translations', () {
    test('Error messages should exist in all locales', () async {
      // Arrange
      final ja = await S.delegate.load(const Locale('ja'));
      final en = await S.delegate.load(const Locale('en'));
      final zh = await S.delegate.load(const Locale('zh'));

      // Assert - Error messages
      expect(ja.errorNetwork, isNotEmpty);
      expect(en.errorNetwork, isNotEmpty);
      expect(zh.errorNetwork, isNotEmpty);

      expect(ja.errorInvalidAmount, isNotEmpty);
      expect(en.errorInvalidAmount, isNotEmpty);
      expect(zh.errorInvalidAmount, isNotEmpty);

      expect(ja.errorRequired, isNotEmpty);
      expect(en.errorRequired, isNotEmpty);
      expect(zh.errorRequired, isNotEmpty);
    });

    test('UI action strings should exist in all locales', () async {
      // Arrange
      final ja = await S.delegate.load(const Locale('ja'));
      final en = await S.delegate.load(const Locale('en'));
      final zh = await S.delegate.load(const Locale('zh'));

      // Assert - UI actions
      expect(ja.confirm, isNotEmpty);
      expect(en.confirm, isNotEmpty);
      expect(zh.confirm, isNotEmpty);

      expect(ja.retry, isNotEmpty);
      expect(en.retry, isNotEmpty);
      expect(zh.retry, isNotEmpty);

      expect(ja.search, isNotEmpty);
      expect(en.search, isNotEmpty);
      expect(zh.search, isNotEmpty);
    });

    test('Validation messages should be parameterized', () async {
      // Arrange
      final en = await S.delegate.load(const Locale('en'));

      // Assert - Should support parameters (checked in ARB structure)
      expect(en.errorMinAmount(100.0), isNotEmpty);
      expect(en.errorMaxAmount(1000.0), isNotEmpty);
    });
  });
}
