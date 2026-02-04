import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  group('Navigation Menu Translations', () {
    test('Japanese navigation strings should exist', () async {
      // Arrange
      final localizations = await S.delegate.load(const Locale('ja'));

      // Assert - Existing navigation strings
      expect(localizations.home, isNotEmpty);
      expect(localizations.transactions, isNotEmpty);
      expect(localizations.analytics, isNotEmpty);
      expect(localizations.settings, isNotEmpty);
      expect(localizations.survivalLedger, isNotEmpty);
      expect(localizations.soulLedger, isNotEmpty);

      // Assert - New navigation strings
      expect(localizations.dashboard, isNotEmpty);
      expect(localizations.reports, isNotEmpty);
      expect(localizations.sync, isNotEmpty);
      expect(localizations.backup, isNotEmpty);
      expect(localizations.security, isNotEmpty);
      expect(localizations.about, isNotEmpty);
      expect(localizations.help, isNotEmpty);
      expect(localizations.profile, isNotEmpty);
      expect(localizations.language, isNotEmpty);
    });

    test('English navigation strings should exist', () async {
      // Arrange
      final localizations = await S.delegate.load(const Locale('en'));

      // Assert
      expect(localizations.dashboard, isNotEmpty);
      expect(localizations.reports, isNotEmpty);
      expect(localizations.sync, isNotEmpty);
      expect(localizations.backup, isNotEmpty);
      expect(localizations.security, isNotEmpty);
      expect(localizations.about, isNotEmpty);
      expect(localizations.help, isNotEmpty);
      expect(localizations.profile, isNotEmpty);
      expect(localizations.language, isNotEmpty);
    });

    test('Chinese navigation strings should exist', () async {
      // Arrange
      final localizations = await S.delegate.load(const Locale('zh'));

      // Assert
      expect(localizations.dashboard, isNotEmpty);
      expect(localizations.reports, isNotEmpty);
      expect(localizations.sync, isNotEmpty);
      expect(localizations.backup, isNotEmpty);
      expect(localizations.security, isNotEmpty);
      expect(localizations.about, isNotEmpty);
      expect(localizations.help, isNotEmpty);
      expect(localizations.profile, isNotEmpty);
      expect(localizations.language, isNotEmpty);
    });
  });
}
