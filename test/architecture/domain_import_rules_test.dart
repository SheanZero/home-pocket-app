// Architecture meta-test: enforces Domain layer import rules across all features.
//
// Per Phase 3 D-02/D-03 (CONTEXT.md): asserts that every
// `lib/features/<f>/domain/import_guard.yaml` retains the deny set and
// does NOT carry an `allow:` block (corrected D-01 strategy moves the
// whitelist to per-subdirectory yamls). Asserts each
// `lib/features/<f>/domain/{models,repositories}/import_guard.yaml`
// (where present) declares only annotation packages + same-feature
// intra-domain leaves.
//
// Failing this test means someone weakened the architectural commitment;
// fix the yaml or have an explicit conversation about why it should change.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Domain layer import_guard rules', () {
    const features = [
      'accounting',
      'analytics',
      'family_sync',
      'home',
      'profile',
      'settings',
    ];
    const requiredDeny = [
      'package:home_pocket/data/**',
      'package:home_pocket/infrastructure/**',
      'package:home_pocket/application/**',
      'package:home_pocket/features/**/presentation/**',
      'package:flutter/**',
    ];

    for (final feature in features) {
      group('feature: $feature', () {
        test('feature-level domain yaml has full deny set + no allow', () {
          final path = 'lib/features/$feature/domain/import_guard.yaml';
          final yaml =
              loadYaml(File(path).readAsStringSync()) as YamlMap;
          final deny = (yaml['deny'] as YamlList)
              .map((e) => e.toString())
              .toList();
          expect(deny, containsAll(requiredDeny),
              reason: 'Feature $feature: deny list weakened');
          expect(yaml['allow'], isNull,
              reason:
                  'Phase 3 D-01 (corrected): feature-level allow moved to per-subdirectory yamls. '
                  'Feature $feature has parent allow — strip it; put leaves in models/ or repositories/ yaml.');
          expect(yaml['inherit'], isTrue,
              reason: 'Feature $feature: inherit must remain true');
        });

        test('models/ subdir yaml allow is intra-domain only', () {
          final path =
              'lib/features/$feature/domain/models/import_guard.yaml';
          if (!File(path).existsSync()) return; // not all features need this
          final yaml =
              loadYaml(File(path).readAsStringSync()) as YamlMap;
          final allow = (yaml['allow'] as YamlList)
              .map((e) => e.toString())
              .toList();
          for (final entry in allow) {
            final isAnnotation = entry == 'dart:core' ||
                entry.startsWith('package:freezed_annotation') ||
                entry.startsWith('package:json_annotation') ||
                entry.startsWith('package:meta');
            final isIntraDomainLeaf =
                entry.endsWith('.dart') && !entry.contains('/');
            expect(isAnnotation || isIntraDomainLeaf, isTrue,
                reason:
                    'Feature $feature models/: allow leaf "$entry" is neither annotation nor intra-domain leaf');
          }
          expect(yaml['inherit'], isTrue);
        });

        test('repositories/ subdir yaml allow is intra-domain only', () {
          final path =
              'lib/features/$feature/domain/repositories/import_guard.yaml';
          if (!File(path).existsSync()) return;
          final yaml =
              loadYaml(File(path).readAsStringSync()) as YamlMap;
          final allow = (yaml['allow'] as YamlList)
              .map((e) => e.toString())
              .toList();
          for (final entry in allow) {
            final isAnnotation = entry == 'dart:core' ||
                entry.startsWith('package:freezed_annotation') ||
                entry.startsWith('package:json_annotation') ||
                entry.startsWith('package:meta');
            final isIntraDomainLeaf = entry.startsWith('../models/') &&
                entry.endsWith('.dart');
            expect(isAnnotation || isIntraDomainLeaf, isTrue,
                reason:
                    'Feature $feature repositories/: allow leaf "$entry" is neither annotation nor ../models/*.dart');
          }
          expect(yaml['inherit'], isTrue);
        });
      });
    }
  });
}
