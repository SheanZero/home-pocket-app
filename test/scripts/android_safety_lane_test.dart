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
}
