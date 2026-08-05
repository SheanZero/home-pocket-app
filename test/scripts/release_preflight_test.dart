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

      final clean = source.indexOf('run_flutter clean');
      final removeRegistrants = source.lastIndexOf('remove_generated_registrants');
      final pubGet = source.indexOf('run_flutter pub get');
      final codegen = source.lastIndexOf('regenerate_if_required');
      final smoke = source.lastIndexOf('run_smoke_compile');
      final scan = source.lastIndexOf('assert_release_registrants_clean');

      expect(clean, greaterThanOrEqualTo(0));
      expect(removeRegistrants, greaterThan(clean));
      expect(pubGet, greaterThan(clean));
      expect(pubGet, greaterThan(removeRegistrants));
      expect(codegen, greaterThan(pubGet));
      expect(smoke, greaterThan(codegen));
      expect(scan, greaterThan(smoke));
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
        expect(result.stdout, contains('flutter build apk --profile'));
        expect(
          result.stdout,
          isNot(contains('flutter build appbundle --release')),
        );
      },
    );
  });
}
