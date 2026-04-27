import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: ARB key parity invariants.
///
/// Run: flutter test test/architecture/arb_key_parity_test.dart

const _arbFiles = {
  'en': 'lib/l10n/app_en.arb',
  'ja': 'lib/l10n/app_ja.arb',
  'zh': 'lib/l10n/app_zh.arb',
};

const _ocrStubKeys = [
  'ocrScan',
  'ocrScanTitle',
  'ocrHint',
  '@ocrScan',
  '@ocrScanTitle',
  '@ocrHint',
];

void main() {
  group('ARB key parity', () {
    test('normal and metadata key sets match across supported locales', () {
      final localeData = _loadArbFiles();

      final normalKeys = localeData.map(
        (locale, entries) =>
            MapEntry(locale, _sortedKeys(entries, metadata: false)),
      );
      final metadataKeys = localeData.map(
        (locale, entries) =>
            MapEntry(locale, _sortedKeys(entries, metadata: true)),
      );

      _expectMatchingKeySets(normalKeys, 'normalKeys');
      _expectMatchingKeySets(metadataKeys, 'metadataKeys');
    });

    test('OCR placeholder stubs and metadata are preserved', () {
      final localeData = _loadArbFiles();

      for (final MapEntry(key: locale, value: entries) in localeData.entries) {
        for (final key in _ocrStubKeys) {
          expect(
            entries,
            contains(key),
            reason: '$locale is missing required OCR stub key $key',
          );
        }

        for (final metadataKey in _ocrStubKeys.where(
          (key) => key.startsWith('@'),
        )) {
          final metadata = entries[metadataKey];
          expect(
            metadata,
            isA<Map<String, Object?>>(),
            reason: '$locale $metadataKey must be an ARB metadata object',
          );
          expect(
            (metadata as Map<String, Object?>)['description'],
            contains('Future OCR/MOD-005 stub'),
            reason:
                '$locale $metadataKey description must document the future OCR stub',
          );
        }
      }
    });
  });
}

Map<String, Map<String, Object?>> _loadArbFiles() {
  return _arbFiles.map((locale, path) {
    final file = File(path);
    final entries = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    return MapEntry(locale, entries);
  });
}

List<String> _sortedKeys(
  Map<String, Object?> entries, {
  required bool metadata,
}) {
  final keys =
      entries.keys.where((key) => key.startsWith('@') == metadata).toList()
        ..sort();
  return keys;
}

void _expectMatchingKeySets(Map<String, List<String>> keySets, String label) {
  final template = keySets['en']!;

  for (final MapEntry(key: locale, value: keys) in keySets.entries) {
    expect(
      keys,
      template,
      reason: '$label differ for $locale compared with en',
    );
  }
}
