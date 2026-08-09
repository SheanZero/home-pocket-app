import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _appDelegatePath = 'ios/Runner/AppDelegate.swift';
const _runnerProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
const _generatedPluginPackage = 'FlutterGeneratedPluginSwiftPackage';

void main() {
  group('iOS native linkage contract', () {
    test('AppDelegate preserves the locked Flutter launch lifecycle', () {
      final source = File(_appDelegatePath).readAsStringSync();

      expect(
        source,
        contains('override func application('),
        reason: 'Runner must keep the locked Flutter launch override',
      );
      expect(source, contains('didFinishLaunchingWithOptions launchOptions:'));
      expect(
        source,
        contains(
          'super.application(application, '
          'didFinishLaunchingWithOptions: launchOptions)',
        ),
      );
      expect(source, contains('FlutterImplicitEngineDelegate'));
      expect(source, contains('didInitializeImplicitFlutterEngine'));
      expect(
        source,
        contains(
          'GeneratedPluginRegistrant.register('
          'with: engineBridge.pluginRegistry)',
        ),
      );
    });

    test(
      'Runner Frameworks phase links one generated plugin package product',
      () {
        final project = File(_runnerProjectPath).readAsStringSync();
        final frameworkPhases = _objectsWithIsa(
          project,
          'PBXFrameworksBuildPhase',
        );
        final runnerPackagePhases = frameworkPhases
            .where((phase) => phase.contains(_generatedPluginPackage))
            .toList();

        expect(runnerPackagePhases, hasLength(1));
        expect(
          _occurrences(runnerPackagePhases.single, _generatedPluginPackage),
          1,
        );
      },
    );
  });
}

List<String> _objectsWithIsa(String project, String isa) {
  final startMarker = '/* Begin $isa section */';
  final endMarker = '/* End $isa section */';
  final start = project.indexOf(startMarker);
  final end = project.indexOf(endMarker, start + startMarker.length);
  if (start < 0 || end < 0) {
    return const [];
  }

  return project
      .substring(start + startMarker.length, end)
      .split('\n\t\t};')
      .where((object) {
        return object.contains('isa = $isa;');
      })
      .toList();
}

int _occurrences(String source, String token) =>
    token.allMatches(source).length;
