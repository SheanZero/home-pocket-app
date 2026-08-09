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
        expect(_runnerProjectContractIssues(project), isEmpty);
      },
    );

    test('AppDelegate mutation cases fail every repaired lifecycle seam', () {
      final source = File(_appDelegatePath).readAsStringSync();
      const mutations = <String, String>{
        'launch override': 'override func application(',
        'super launch delegation':
            'super.application(application, '
            'didFinishLaunchingWithOptions: launchOptions)',
        'implicit-engine callback': 'didInitializeImplicitFlutterEngine',
        'generated plugin registration':
            'GeneratedPluginRegistrant.register('
            'with: engineBridge.pluginRegistry)',
      };

      for (final mutation in mutations.entries) {
        expect(
          _appDelegateContractIssues(_removeOnce(source, mutation.value)),
          contains(mutation.key),
          reason: 'mutation must fail: ${mutation.key}',
        );
      }
    });

    test('Runner Frameworks mutations fail missing and duplicate products', () {
      final project = File(_runnerProjectPath).readAsStringSync();
      final frameworkLine = RegExp(
        r'^\s+[0-9A-F]+ /\* FlutterGeneratedPluginSwiftPackage '
        r'in Frameworks \*/,$',
        multiLine: true,
      ).firstMatch(project)!.group(0)!;

      expect(
        _runnerProjectContractIssues(_removeOnce(project, frameworkLine)),
        contains('Runner Frameworks generated package product'),
      );
      expect(
        _runnerProjectContractIssues(
          project.replaceFirst(frameworkLine, '$frameworkLine\n$frameworkLine'),
        ),
        contains('Runner Frameworks generated package product'),
      );

      final runnerTarget = _objectsWithIsa(
        project,
        'PBXNativeTarget',
      ).singleWhere((target) => target.contains('\n\t\t\tname = Runner;'));
      final dependencyLine = RegExp(
        r'^\s+[0-9A-F]+ /\* FlutterGeneratedPluginSwiftPackage \*/,$',
        multiLine: true,
      ).firstMatch(runnerTarget)!.group(0)!;
      expect(
        _runnerProjectContractIssues(_removeOnce(project, dependencyLine)),
        contains('Runner generated package product dependency'),
      );
      expect(
        _runnerProjectContractIssues(
          project.replaceFirst(
            dependencyLine,
            '$dependencyLine\n$dependencyLine',
          ),
        ),
        contains('Runner generated package product dependency'),
      );
    });
  });
}

List<String> _appDelegateContractIssues(String source) {
  final issues = <String>[];
  const requiredMarkers = <String, String>{
    'launch override': 'override func application(',
    'super launch delegation':
        'super.application(application, '
        'didFinishLaunchingWithOptions: launchOptions)',
    'implicit-engine callback': 'didInitializeImplicitFlutterEngine',
    'generated plugin registration':
        'GeneratedPluginRegistrant.register('
        'with: engineBridge.pluginRegistry)',
  };
  for (final marker in requiredMarkers.entries) {
    if (!source.contains(marker.value)) {
      issues.add(marker.key);
    }
  }
  return issues;
}

List<String> _runnerProjectContractIssues(String project) {
  final issues = <String>[];
  final frameworkPhases = _objectsWithIsa(project, 'PBXFrameworksBuildPhase');
  final runnerPackagePhases = frameworkPhases
      .where((phase) => phase.contains(_generatedPluginPackage))
      .toList();
  if (runnerPackagePhases.length != 1 ||
      _occurrences(runnerPackagePhases.single, _generatedPluginPackage) != 1) {
    issues.add('Runner Frameworks generated package product');
  }

  final nativeTargets = _objectsWithIsa(project, 'PBXNativeTarget');
  final runnerTargets = nativeTargets
      .where((target) => target.contains('\n\t\t\tname = Runner;'))
      .toList();
  if (runnerTargets.length != 1 ||
      _occurrences(runnerTargets.single, _generatedPluginPackage) != 1) {
    issues.add('Runner generated package product dependency');
  }
  return issues;
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

String _removeOnce(String source, String token) {
  expect(source, contains(token), reason: 'fixture token must exist: $token');
  return source.replaceFirst(token, '');
}
