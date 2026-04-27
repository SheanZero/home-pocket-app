import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: live lib/ code must not reference deprecated MOD-009.
///
/// Historical documentation is intentionally out of scope for Phase 5.
///
/// Run: flutter test test/architecture/mod009_live_lib_scan_test.dart

void main() {
  group('MOD-009 live lib scanner', () {
    test('lib/ Dart files do not reference MOD-009 or mod009', () {
      final hits = <String>[];
      final forbidden = RegExp(r'\bMOD-009\b|\bmod009\b');

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !_shouldScan(entity)) continue;

        final source = entity.readAsStringSync();
        if (forbidden.hasMatch(source)) {
          hits.add(entity.path);
        }
      }

      expect(
        hits,
        isEmpty,
        reason:
            'Deprecated MOD-009 references found in live lib/ Dart files: $hits',
      );
    });
  });
}

bool _shouldScan(File file) {
  final path = file.path;
  if (!path.endsWith('.dart')) return false;
  if (path.startsWith('lib/generated/')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  return true;
}
