import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Presentation layer import_guard rules', () {
    const features = [
      'accounting',
      'analytics',
      'dual_ledger', // INCLUDED — has presentation/ even though no domain/
      'family_sync',
      'home',
      'profile',
      'settings',
    ];
    // Phase 4 scope: infrastructure/** + existing data/daos/** + data/tables/**.
    // data/repositories/** intentionally NOT denied here — out of scope per CONTEXT.md
    // <domain> 'In scope' list; scheduled for Phase 5+ MED scope.
    const requiredDeny = [
      'package:home_pocket/infrastructure/**',
      'package:home_pocket/data/daos/**',
      'package:home_pocket/data/tables/**',
    ];

    for (final feature in features) {
      group('feature: $feature', () {
        test(
          'presentation yaml denies infrastructure/** + data/daos/** + data/tables/**',
          () {
            final path = 'lib/features/$feature/presentation/import_guard.yaml';
            final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
            final deny = (yaml['deny'] as YamlList)
                .map((e) => e.toString())
                .toList();
            expect(
              deny,
              containsAll(requiredDeny),
              reason:
                  'Feature $feature presentation: deny list weakened '
                  '(Phase 4 scope: infrastructure + data/daos + data/tables)',
            );
            expect(
              yaml['inherit'],
              isTrue,
              reason: 'Feature $feature presentation: inherit must be true',
            );
          },
        );
      });
    }
  });
}
