import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: production `*Service` class names stay layer-unique.
///
/// Run: flutter test test/architecture/service_name_collision_test.dart

const _allowedCrossLayerServiceNames = <String>{};

void main() {
  group('Service name collision guard', () {
    test(
      'no production *Service class name is declared in more than one layer',
      () {
        final classNamesByLayer = <String, Map<String, List<String>>>{};

        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is! File ||
              !entity.path.endsWith('.dart') ||
              entity.path.endsWith('.g.dart') ||
              entity.path.endsWith('.freezed.dart') ||
              entity.path.contains('/generated/')) {
            continue;
          }

          final layer = _layerFor(entity.path);
          final src = entity.readAsStringSync();
          final matches = RegExp(
            r'(?:abstract\s+final\s+class|class)\s+(\w+Service)\b',
          ).allMatches(src);

          for (final match in matches) {
            final className = match.group(1)!;
            classNamesByLayer
                .putIfAbsent(className, () => <String, List<String>>{})
                .putIfAbsent(layer, () => <String>[])
                .add(entity.path);
          }
        }

        final collisions = <String>[];
        for (final entry in classNamesByLayer.entries) {
          if (_allowedCrossLayerServiceNames.contains(entry.key)) continue;
          if (entry.value.keys.length > 1) {
            collisions.add(
              '${entry.key}: ${entry.value.entries.map((layerEntry) => '${layerEntry.key}=${layerEntry.value}').join(', ')}',
            );
          }
        }

        expect(
          collisions,
          isEmpty,
          reason:
              'Service class names must be unique across production layers:\n'
              '${collisions.join("\n")}',
        );
        expect(
          classNamesByLayer['CategoryService'],
          equals({
            'application': ['lib/application/accounting/category_service.dart'],
          }),
        );
        expect(
          classNamesByLayer['CategoryLocaleService'],
          equals({
            'infrastructure': [
              'lib/infrastructure/category/category_locale_service.dart',
            ],
          }),
        );
      },
    );
  });
}

String _layerFor(String path) {
  final segments = path.split(Platform.pathSeparator);
  final libIndex = segments.indexOf('lib');
  if (libIndex == -1 || libIndex + 1 >= segments.length) {
    return 'unknown';
  }
  return segments[libIndex + 1];
}
