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
  'publish/ios/README.md',
  'publish/ios/RELEASE_GATES.md',
  'publish/ios/RELEASE_STEPS.md',
  'publish/ios/intro/en/app-introduction.md',
  'publish/ios/intro/ja/app-introduction.md',
];

const _nativeSafetyRunner = 'scripts/verify_ios_native_safety_lane.dart';

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

    test(
      'native safety runner is source-controlled, fail-closed, and iOS 15-aware',
      () {
        final runner = File(_nativeSafetyRunner).readAsStringSync();

        for (final marker in <String>[
          'enum NativeSafetyLane { tracer, full, runtime }',
          'COMPILE_ONLY',
          'RUNTIME_PASS',
          'RUNTIME_FAIL',
          'BLOCKED',
          'flutter pub get --enforce-lockfile',
          'pod install --deployment',
          'flutter build ios --simulator --debug --no-codesign',
          '--generated-swift-package-manifest=',
          'CODE_SIGNING_ALLOWED=NO',
          'generic/platform=iOS',
          'platform=iOS Simulator',
          'sqlcipher_native_assets_lifecycle_test.dart',
          'CoreSimulator',
          'Process.start',
          '_simulatorCommandTimeout',
          'lane == NativeSafetyLane.full',
          'git status --short',
          'Directory.systemTemp.createTemp',
          'NOT_RUN',
          '_nativeGraphDigest',
          'disposable Flutter iOS package generation',
          'unsupported_configuration_reason',
          "listed.stdout.toString().split('\\u0000')",
          '_simulatorRuntimeConfigurations',
          'on ProcessException',
          'prepared-clean',
          'before-status-sha256',
          '_terminationObserved',
          "'INCOMPLETE'",
        ]) {
          expect(
            runner,
            contains(marker),
            reason: 'missing safety marker: $marker',
          );
        }

        expect(
          runner,
          isNot(contains('manifest.writeAsString')),
          reason:
              'the generated SwiftPM manifest must be inspected, never edited',
        );
        expect(runner, isNot(contains('ios-deploy')));
        expect(runner, isNot(contains('xcrun devicectl')));
        expect(runner, isNot(contains('install-on-device')));
        expect(runner, isNot(contains('uninstall')));
        expect(
          runner,
          isNot(contains("label: 'simulator-\${configuration.toLowerCase()}'")),
          reason: 'Profile and Release simulator AOT builds are unsupported',
        );
      },
    );
  });
}
