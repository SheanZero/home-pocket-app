import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _gradlePath = 'android/app/build.gradle.kts';

void main() {
  group('Android release signing contract', () {
    test('release artifacts use dedicated, fail-closed production signing', () {
      expect(
        validateAndroidReleaseSigning(File(_gradlePath).readAsStringSync()),
        isEmpty,
      );
    });

    test('the guard rejects a debug signing fallback', () {
      final source = File(_gradlePath).readAsStringSync().replaceFirst(
        'signingConfigs.getByName("release")',
        'signingConfigs.getByName("debug")',
      );

      expect(
        validateAndroidReleaseSigning(source),
        contains('release build type must not use debug signing'),
      );
    });
  });
}

List<String> validateAndroidReleaseSigning(String source) {
  final findings = <String>[];

  if (!source.contains('rootProject.file("key.properties")')) {
    findings.add('release signing must load ignored android/key.properties');
  }
  for (final environmentName in const [
    'ANDROID_KEYSTORE_PATH',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD',
  ]) {
    if (!source.contains(environmentName)) {
      findings.add('release signing must support $environmentName for CI');
    }
  }
  if (!source.contains('create("release")')) {
    findings.add('a dedicated release signing config is required');
  }
  if (!source.contains('signingConfig = signingConfigs.getByName("release")')) {
    findings.add(
      'release build type must use the dedicated release signing config',
    );
  }
  if (source.contains('signingConfig = signingConfigs.getByName("debug")')) {
    findings.add('release build type must not use debug signing');
  }
  if (!source.contains('requireReleaseSigning()')) {
    findings.add(
      'release signing must fail closed when credentials are absent',
    );
  }
  if (!source.contains('tasks.register("verifyReleaseSigning")')) {
    findings.add('release signing must have a Gradle verification task');
  }
  if (!source.contains('CN=Android Debug')) {
    findings.add('release signing must reject the Android Debug certificate');
  }
  if (!source.contains(r'^(assemble|bundle|package).*Release$')) {
    findings.add('release artifact tasks must depend on signing verification');
  }

  return findings;
}
