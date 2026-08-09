import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verify_android_safety_lane.dart' as lane;

void main() {
  test('argument parser keeps expensive modes explicit', () {
    expect(
      lane.parseAndroidSafetyOptions(['--mode=verify', '--allow-not-run']).mode,
      lane.AndroidSafetyMode.verify,
    );
    expect(
      () =>
          lane.parseAndroidSafetyOptions(['--mode=release', '--prepare-only']),
      throwsArgumentError,
    );
    expect(
      () => lane.parseAndroidSafetyOptions(['--mode=unknown']),
      throwsArgumentError,
    );
  });

  test('evidence parser rejects missing markers and sensitive values', () {
    final issues = <String>[];
    expect(lane.parseEvidenceMarkdown('no evidence', issues), isEmpty);
    expect(issues, isNotEmpty);

    final current = File(lane.evidencePath).readAsStringSync();
    final contaminated = current.replaceFirst(
      '"source_commit": "NOT_RUN"',
      '"source_commit": "/Users/alice/private"',
    );
    final findings = lane.validateAndroidSafetyLane(
      baselineJson: File(
        'docs/testing/STABLE_BASELINE.json',
      ).readAsStringSync(),
      settingsGradle: File('android/settings.gradle.kts').readAsStringSync(),
      gradleProperties: File('android/gradle.properties').readAsStringSync(),
      gradleWrapper: File(
        'android/gradle/wrapper/gradle-wrapper.properties',
      ).readAsStringSync(),
      appBuildGradle: File('android/app/build.gradle.kts').readAsStringSync(),
      evidenceMarkdown: contaminated,
      legacyKgpPlugins: const ['speech_to_text'],
      allowNotRun: true,
    );
    expect(
      findings.any((finding) => finding.contains('prohibited sensitive value')),
      isTrue,
    );
  });

  test('strict evidence cannot pass while native results are NOT_RUN', () {
    final result = Process.runSync('dart', [
      'run',
      'scripts/verify_android_safety_lane.dart',
      '--mode=verify',
    ]);
    expect(result.exitCode, isNonZero);
    expect('${result.stderr}', contains('candidate result must be observed'));
  });

  test('text digest is deterministic', () {
    expect(lane.sha256Text('phase61'), hasLength(64));
    expect(lane.sha256Text('phase61'), lane.sha256Text('phase61'));
  });

  test('candidate transaction migrates every coupled Android input', () {
    final migrated = lane.migrateCandidateInputs(
      settingsGradle: File('android/settings.gradle.kts').readAsStringSync(),
      gradleProperties: File('android/gradle.properties').readAsStringSync(),
      gradleWrapper: File(
        'android/gradle/wrapper/gradle-wrapper.properties',
      ).readAsStringSync(),
      appBuildGradle: File('android/app/build.gradle.kts').readAsStringSync(),
    );

    expect(migrated.issues, isEmpty);
    expect(migrated.settingsGradle, contains('version "9.3.1"'));
    expect(migrated.settingsGradle, isNot(contains('kotlin.android')));
    expect(migrated.gradleProperties, isNot(contains('builtInKotlin')));
    expect(migrated.gradleProperties, isNot(contains('newDsl')));
    expect(migrated.gradleWrapper, contains('gradle-9.5.0-all.zip'));
    expect(migrated.appBuildGradle, isNot(contains('kotlin-android')));
    expect(migrated.appBuildGradle, isNot(contains('kotlinOptions')));
    expect(migrated.appBuildGradle, contains('kotlin {'));
    expect(migrated.appBuildGradle, contains('JvmTarget.JVM_17'));
    expect(migrated.appBuildGradle, contains('minSdk = flutter.minSdkVersion'));
  });

  test('candidate transaction rejects incomplete source patterns', () {
    final migrated = lane.migrateCandidateInputs(
      settingsGradle: 'plugins { id("com.android.application") }',
      gradleProperties: 'android.useAndroidX=true\n',
      gradleWrapper: 'distributionUrl=gradle.zip\n',
      appBuildGradle: 'plugins { id("com.android.application") }\n',
    );

    expect(migrated.issues, isNotEmpty);
    expect(migrated.issues.join('\n'), contains('AGP declaration'));
    expect(migrated.issues.join('\n'), contains('minSdk declaration'));
  });

  test('disposable operation cleans up after success and failure', () async {
    String? successfulPath;
    await lane.withDisposableCandidateDirectory((directory) async {
      successfulPath = directory.path;
      File('${directory.path}/sentinel').writeAsStringSync('temporary');
    });
    expect(Directory(successfulPath!).existsSync(), isFalse);

    String? failedPath;
    await expectLater(
      lane.withDisposableCandidateDirectory((directory) async {
        failedPath = directory.path;
        throw StateError('simulated interruption');
      }),
      throwsStateError,
    );
    expect(Directory(failedPath!).existsSync(), isFalse);
  });

  test('candidate output is bounded and durable-path redacted', () {
    final output = lane.scrubCandidateOutput(
      '/Users/alice/project/android ${'x' * 80000}',
    );
    expect(output.length, lessThanOrEqualTo(lane.maxDurableOutputChars));
    expect(output, isNot(contains('/Users/alice')));
    expect(output, contains('<local-path>'));
  });

  test('JDK parser accepts 17 and rejects other or malformed versions', () {
    expect(lane.parseJavaMajor('openjdk version "17.0.16"'), 17);
    expect(lane.parseJavaMajor('openjdk version "21.0.8"'), 21);
    expect(lane.parseJavaMajor('not-java'), isNull);
  });
}
