import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  group('Category Name Translations', () {
    test('Japanese category strings should exist', () async {
      // Arrange
      final localizations = await S.delegate.load(const Locale('ja'));

      // Assert - Survival categories
      expect(localizations.categoryFood, isNotEmpty);
      expect(localizations.categoryHousing, isNotEmpty);
      expect(localizations.categoryTransport, isNotEmpty);
      expect(localizations.categoryUtilities, isNotEmpty);
      expect(localizations.categoryHealthcare, isNotEmpty);

      // Soul categories
      expect(localizations.categoryEntertainment, isNotEmpty);
      expect(localizations.categoryHobbies, isNotEmpty);
      expect(localizations.categorySelfImprovement, isNotEmpty);
      expect(localizations.categoryTravel, isNotEmpty);
      expect(localizations.categoryGifts, isNotEmpty);
    });

    test('All locales should have matching category keys', () async {
      // Arrange
      final ja = await S.delegate.load(const Locale('ja'));
      final en = await S.delegate.load(const Locale('en'));
      final zh = await S.delegate.load(const Locale('zh'));

      // Assert - Verify all have same categories
      expect(ja.categoryFood, isNotEmpty);
      expect(en.categoryFood, isNotEmpty);
      expect(zh.categoryFood, isNotEmpty);

      expect(ja.categoryEntertainment, isNotEmpty);
      expect(en.categoryEntertainment, isNotEmpty);
      expect(zh.categoryEntertainment, isNotEmpty);
    });
  });
}
