import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/release_preflight.sh';

String _projectRoot() => Directory.current.path;

Future<ProcessResult> _runScript(
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.run('bash', [
    _scriptPath,
    ...arguments,
  ], workingDirectory: workingDirectory ?? _projectRoot());
}

Future<ProcessResult> _scanFixture(Directory fixture) {
  final script = File('${_projectRoot()}/$_scriptPath').absolute.path;
  return Process.run('bash', [
    '-c',
    r'source "$1"; assert_release_registrants_clean "$2"',
    'release-preflight-test',
    script,
    fixture.path,
  ]);
}

void main() {
  group('release_preflight.sh', () {
    test('has a deterministic clean-regenerate-smoke-scan ordering', () {
      final source = File(_scriptPath).readAsStringSync();

      expect(source, contains('#!/usr/bin/env bash'));
      expect(source, contains('set -euo pipefail'));
      expect(source, contains("grep -nF 'integration_test'"));
      expect(source, isNot(contains('rg -n --fixed-strings')));
      expect(source, contains('write_ios_release_pubspec'));
      expect(source, contains('assert_ios_release_artifact_clean'));
      expect(source, contains('flutter build ios --release --no-codesign'));
      expect(source, isNot(contains('flutter build ios --profile')));
      expect(source, contains('flutter build apk --release --config-only'));
      expect(source, contains('assert_android_release_artifacts_clean'));

      final clean = source.indexOf('run_flutter clean');
      final removeRegistrants = source.lastIndexOf(
        'remove_generated_registrants',
      );
      final pubGet = source.indexOf('run_flutter pub get');
      final codegen = source.lastIndexOf('regenerate_if_required');
      final smoke = source.lastIndexOf('run_smoke_compile');
      final scan = source.lastIndexOf('assert_release_registrants_clean');
      final packageAab = source.indexOf('build appbundle --release');
      final packageApk = source.indexOf('build apk --release', packageAab + 1);
      final artifactScan = source.lastIndexOf(
        'assert_android_release_artifacts_clean',
      );

      expect(clean, greaterThanOrEqualTo(0));
      expect(removeRegistrants, greaterThan(clean));
      expect(pubGet, greaterThan(clean));
      expect(pubGet, greaterThan(removeRegistrants));
      expect(codegen, greaterThan(pubGet));
      expect(smoke, greaterThan(codegen));
      expect(scan, greaterThan(smoke));
      expect(packageAab, greaterThanOrEqualTo(0));
      expect(packageApk, greaterThan(packageAab));
      expect(artifactScan, greaterThan(packageApk));
    });

    test('creates an iOS release manifest without integration_test', () async {
      final fixture = await Directory.systemTemp.createTemp(
        'release-preflight-manifest-',
      );
      addTearDown(() => fixture.delete(recursive: true));
      final input = File('${fixture.path}/pubspec.yaml');
      final output = File('${fixture.path}/pubspec.release.yaml');
      await input.writeAsString('''
name: fixture
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  lints: ^6.0.0
''');
      final script = File(_scriptPath).absolute.path;

      final result = await Process.run('bash', [
        '-c',
        r'source "$1"; write_ios_release_pubspec "$2" "$3"',
        'release-preflight-test',
        script,
        input.path,
        output.path,
      ]);

      expect(result.exitCode, equals(0), reason: result.stderr.toString());
      expect(await input.readAsString(), contains('integration_test'));
      final releaseManifest = await output.readAsString();
      expect(releaseManifest, isNot(contains('integration_test')));
      expect(releaseManifest, contains('flutter_test'));
      expect(releaseManifest, contains('lints: ^6.0.0'));
    });

    test(
      'rejects integration_test references in generated native registrants',
      () async {
        final fixture = await Directory.systemTemp.createTemp(
          'release-preflight-',
        );
        addTearDown(() => fixture.delete(recursive: true));
        final registrant = File(
          '${fixture.path}/android/app/src/main/java/io/flutter/plugins/'
          'GeneratedPluginRegistrant.java',
        );
        await registrant.create(recursive: true);
        await registrant.writeAsString(
          'new dev.flutter.plugins.integration_test.IntegrationTestPlugin();',
        );

        final result = await _scanFixture(fixture);

        expect(result.exitCode, isNonZero);
        expect(result.stderr, contains('dev-only integration_test reference'));
      },
    );

    test('accepts registrants without dev-only plugin references', () async {
      final fixture = await Directory.systemTemp.createTemp(
        'release-preflight-',
      );
      addTearDown(() => fixture.delete(recursive: true));
      final registrant = File(
        '${fixture.path}/ios/Runner/GeneratedPluginRegistrant.m',
      );
      await registrant.create(recursive: true);
      await registrant.writeAsString('@import firebase_core;');

      final result = await _scanFixture(fixture);

      expect(result.exitCode, equals(0), reason: result.stderr.toString());
    });

    test(
      'dry run exposes the unsigned smoke step but never packages a release',
      () async {
        final result = await _runScript(['--platform', 'android', '--dry-run']);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        expect(result.stdout, contains('flutter clean'));
        expect(result.stdout, contains('flutter pub get'));
        expect(
          result.stdout,
          contains('flutter build apk --release --config-only'),
        );
        expect(
          result.stdout,
          isNot(contains('flutter build appbundle --release')),
        );
      },
    );

    test(
      'package dry run orders AAB then APK without credential values',
      () async {
        final result = await _runScript([
          '--platform',
          'android',
          '--package',
          '--dry-run',
        ]);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final output = result.stdout.toString();
        final aab = output.indexOf('flutter build appbundle --release');
        final apk = output.indexOf('flutter build apk --release', aab + 1);
        expect(aab, greaterThanOrEqualTo(0));
        expect(apk, greaterThan(aab));
        expect(output, isNot(contains('storePassword')));
        expect(output, isNot(contains('keyPassword')));
      },
    );
  });
}
