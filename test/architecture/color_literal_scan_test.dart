import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: no raw hex Color() literals in feature/application/shared code.
///
/// Every Color(0x…) literal in lib/features/, lib/application/, lib/shared/ must
/// be migrated to a named AppPalette token (COLOR-01). This test acts as the
/// automated gate for that requirement.
///
/// Expected state:
///   BEFORE Plan 33-02 through 33-04 complete → FAILS (61 literals present)
///   AFTER  migration complete                → PASSES (zero literals)
///
/// Run: flutter test test/architecture/color_literal_scan_test.dart

void main() {
  group('Color literal scanner (COLOR-01)', () {
    test(
      'production feature/application/shared files do not contain raw Color(0x…) literals',
      () {
        final hits = <String>[];
        final literalPattern = RegExp(r'Color\(0[xX]');

        for (final dir in [
          'lib/features',
          'lib/application',
          'lib/shared',
        ]) {
          final directory = Directory(dir);
          if (!directory.existsSync()) continue;

          for (final entity in directory.listSync(recursive: true)) {
            if (entity is! File || !_shouldScan(entity)) continue;

            final source = entity.readAsStringSync();
            final matches = literalPattern.allMatches(source).toList();
            if (matches.isNotEmpty) {
              hits.add('${_normalizePath(entity.path)}: ${matches.length} hit(s)');
            }
          }
        }

        expect(
          hits,
          isEmpty,
          reason:
              'Raw Color(0x…) literals found — must use AppPalette tokens (COLOR-01):\n'
              '${hits.join("\n")}',
        );
      },
    );
  });
}

bool _shouldScan(File file) {
  final path = _normalizePath(file.path);
  if (!path.endsWith('.dart')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  return true;
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');
