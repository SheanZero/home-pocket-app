import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB File Validation', () {
    late Map<String, dynamic> jaArb;
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> zhArb;

    setUpAll(() {
      // Load ARB files
      final jaFile = File('lib/l10n/app_ja.arb');
      final enFile = File('lib/l10n/app_en.arb');
      final zhFile = File('lib/l10n/app_zh.arb');

      jaArb = jsonDecode(jaFile.readAsStringSync()) as Map<String, dynamic>;
      enArb = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      zhArb = jsonDecode(zhFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('All ARB files should have valid JSON structure', () {
      expect(jaArb, isNotEmpty);
      expect(enArb, isNotEmpty);
      expect(zhArb, isNotEmpty);
    });

    test('All ARB files should have @@locale key', () {
      expect(jaArb['@@locale'], 'ja');
      expect(enArb['@@locale'], 'en');
      expect(zhArb['@@locale'], 'zh');
    });

    test('All translation keys should exist in all locales', () {
      // Get translation keys (exclude @ metadata keys)
      final jaKeys = jaArb.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      final enKeys = enArb.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      final zhKeys = zhArb.keys
          .where((key) => !key.startsWith('@'))
          .toSet();

      // All files should have the same translation keys
      expect(jaKeys, equals(enKeys),
          reason: 'Japanese and English ARB files should have matching keys');
      expect(jaKeys, equals(zhKeys),
          reason: 'Japanese and Chinese ARB files should have matching keys');
    });

    test('No translation values should be empty', () {
      // Check Japanese
      for (var entry in jaArb.entries) {
        if (!entry.key.startsWith('@')) {
          expect(entry.value.toString().trim(), isNotEmpty,
              reason: 'Japanese translation for "${entry.key}" is empty');
        }
      }

      // Check English
      for (var entry in enArb.entries) {
        if (!entry.key.startsWith('@')) {
          expect(entry.value.toString().trim(), isNotEmpty,
              reason: 'English translation for "${entry.key}" is empty');
        }
      }

      // Check Chinese
      for (var entry in zhArb.entries) {
        if (!entry.key.startsWith('@')) {
          expect(entry.value.toString().trim(), isNotEmpty,
              reason: 'Chinese translation for "${entry.key}" is empty');
        }
      }
    });

    test('Parameterized strings should have matching placeholders', () {
      // Find parameterized strings (containing {})
      final parameterizedKeys = jaArb.keys
          .where((key) => !key.startsWith('@'))
          .where((key) => jaArb[key].toString().contains('{'))
          .toList();

      for (var key in parameterizedKeys) {
        final jaValue = jaArb[key] as String;
        final enValue = enArb[key] as String;
        final zhValue = zhArb[key] as String;

        // Extract placeholders
        final jaPlaceholders = _extractPlaceholders(jaValue);
        final enPlaceholders = _extractPlaceholders(enValue);
        final zhPlaceholders = _extractPlaceholders(zhValue);

        expect(jaPlaceholders, equals(enPlaceholders),
            reason: 'Placeholders mismatch for "$key" between ja and en');
        expect(jaPlaceholders, equals(zhPlaceholders),
            reason: 'Placeholders mismatch for "$key" between ja and zh');
      }
    });

    test('All strings should have @metadata entries', () {
      final translationKeys = jaArb.keys
          .where((key) => !key.startsWith('@'))
          .toList();

      for (var key in translationKeys) {
        final metadataKey = '@$key';
        expect(jaArb.containsKey(metadataKey), isTrue,
            reason: 'Japanese ARB missing metadata for "$key"');
        expect(enArb.containsKey(metadataKey), isTrue,
            reason: 'English ARB missing metadata for "$key"');
        expect(zhArb.containsKey(metadataKey), isTrue,
            reason: 'Chinese ARB missing metadata for "$key"');
      }
    });

    test('Should have at least 70 translation keys', () {
      // Navigation (15) + Categories (20) + Errors/UI (30) + Existing (10) = 75+
      final translationKeys = jaArb.keys
          .where((key) => !key.startsWith('@'))
          .length;

      expect(translationKeys, greaterThanOrEqualTo(70),
          reason: 'Should have at least 70 translation keys for comprehensive i18n');
    });
  });
}

/// Extract placeholder names from a string like "Amount is {value}"
Set<String> _extractPlaceholders(String text) {
  final regex = RegExp(r'\{(\w+)\}');
  return regex.allMatches(text).map((m) => m.group(1)!).toSet();
}
