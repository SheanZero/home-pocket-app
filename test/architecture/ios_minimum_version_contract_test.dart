import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _currentPlatformDeclarationFiles = <String>[
  'AGENTS.md',
  'CLAUDE.md',
  'README.md',
  'README_ja.md',
  'README_zh.md',
  '.planning/PROJECT.md',
  '.planning/codebase/STACK.md',
  '.planning/research/FEATURES.md',
  '.planning/research/SUMMARY.md',
  '.planning/uat/pre-release-uat-progress.html',
  'docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md',
  'docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md',
  'docs/reports/family-management-real-device-uat.html',
];

void main() {
  group('iOS minimum version contract', () {
    test('Podfile and every Xcode build configuration target iOS 15.0', () {
      final podfile = File('ios/Podfile').readAsStringSync();
      expect(podfile, contains("platform :ios, '15.0'"));

      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final targets = RegExp(
        r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);',
      ).allMatches(project).map((match) => match.group(1)).toList();

      expect(targets, isNotEmpty);
      expect(targets.toSet(), {'15.0'});
    });

    for (final path in _currentPlatformDeclarationFiles) {
      test('$path declares iOS 15 and not iOS 14', () {
        final contents = File(path).readAsStringSync();

        expect(contents, contains('iOS 15'));
        expect(contents, isNot(contains('iOS 14')));
      });
    }
  });
}
