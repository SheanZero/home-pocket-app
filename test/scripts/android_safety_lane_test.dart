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
      RegExp(r'"source_commit": "[^"]+"'),
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
    final baseline = File(
      'docs/testing/STABLE_BASELINE.json',
    ).readAsStringSync();
    final current = File(lane.evidencePath).readAsStringSync();
    final notRun = current
        .replaceFirst(
          '"completed_stage": "candidate"',
          '"completed_stage": "contract"',
        )
        .replaceFirst('"candidate": "INCOMPATIBLE"', '"candidate": "NOT_RUN"');
    final findings = lane.validateAndroidSafetyLane(
      baselineJson: baseline,
      settingsGradle: File('android/settings.gradle.kts').readAsStringSync(),
      gradleProperties: File('android/gradle.properties').readAsStringSync(),
      gradleWrapper: File(
        'android/gradle/wrapper/gradle-wrapper.properties',
      ).readAsStringSync(),
      appBuildGradle: File('android/app/build.gradle.kts').readAsStringSync(),
      evidenceMarkdown: notRun,
      legacyKgpPlugins: lane.inventoryLegacyKgpPlugins(Directory.current),
      allowNotRun: false,
    );
    expect(findings, contains('candidate result must be observed'));
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

  test(
    'bounded command output preserves completion text from the tail',
    () async {
      final fixture = await Directory.systemTemp.createTemp(
        'phase61-bounded-output-',
      );
      addTearDown(() => fixture.delete(recursive: true));
      final emitter = File('${fixture.path}/emitter.dart');
      await emitter.writeAsString('''
import 'dart:io';
void main() {
  stdout.write('COMMAND_START\\n');
  stdout.write('x' * 100000);
  stdout.write('\\nCOMMAND_VERIFIED\\n');
}
''');

      final result = await lane.runBoundedCommand(
        'dart',
        [emitter.path],
        workingDirectory: fixture,
        durableCommand: 'bounded-output-fixture',
      );

      expect(result.exitCode, 0);
      expect(
        result.output.length,
        lessThanOrEqualTo(lane.maxDurableOutputChars),
      );
      expect(result.output, contains('COMMAND_START'));
      expect(result.output, contains('COMMAND_VERIFIED'));
    },
  );

  test('JDK parser accepts 17 and rejects other or malformed versions', () {
    expect(lane.parseJavaMajor('openjdk version "17.0.16"'), 17);
    expect(lane.parseJavaMajor('openjdk version "21.0.8"'), 21);
    expect(lane.parseJavaMajor('not-java'), isNull);
  });

  test('Java signing tools force deterministic English output', () {
    expect(
      lane.javaToolEnglishLocaleArguments,
      equals(['-J-Duser.language=en', '-J-Duser.country=US']),
    );
    expect(
      lane.aabJarVerificationArguments,
      equals(['-J-Duser.language=en', '-J-Duser.country=US', '-verify']),
    );
  });

  test('Emulator launch is cold, snapshot-free, and cross-arch explicit', () {
    final arguments = lane.emulatorLaunchArguments(
      avdName: 'phase61-owned',
      port: 5580,
      hostArchitecture: 'arm64',
    );

    expect(arguments, containsAll(['-avd', 'phase61-owned', '-port', '5580']));
    expect(arguments, containsAll(['-wipe-data', '-no-snapshot']));
    expect(arguments, containsAll(['-no-snapshot-save', '-no-accel']));
    expect(arguments, containsAll(['-no-window', '-no-audio']));
  });

  test('Rosetta emulator override requires the official x86_64 archive', () {
    expect(
      lane.validateX86EmulatorArchiveIdentity(
        fileOutput: 'Mach-O 64-bit executable x86_64',
        actualSha1: lane.officialX86EmulatorArchiveSha1,
      ),
      isEmpty,
    );
    expect(
      lane.validateX86EmulatorArchiveIdentity(
        fileOutput: 'Mach-O 64-bit executable arm64',
        actualSha1: lane.officialX86EmulatorArchiveSha1,
      ),
      isNotEmpty,
    );
    expect(
      lane.validateX86EmulatorArchiveIdentity(
        fileOutput: 'Mach-O 64-bit executable x86_64',
        actualSha1: '0' * 40,
      ),
      isNotEmpty,
    );
  });

  test('Emulator identity rejects false boot, API, ABI, and ownership', () {
    const expected = lane.EmulatorIdentityExpectation(
      avdName: 'phase61-owned',
      serial: 'emulator-5580',
    );
    const valid = <String, String>{
      'serial': 'emulator-5580',
      'bootCompleted': '1',
      'api': '36',
      'abi': 'x86_64',
      'avdName': 'phase61-owned',
    };

    expect(lane.validateEmulatorIdentity(valid, expected), isEmpty);
    for (final mutation in <String, String>{
      'serial': 'emulator-5582',
      'bootCompleted': '0',
      'api': '35',
      'abi': 'arm64-v8a',
      'avdName': 'someone-elses-avd',
    }.entries) {
      final mutated = {...valid, mutation.key: mutation.value};
      expect(
        lane.validateEmulatorIdentity(mutated, expected),
        isNotEmpty,
        reason: '${mutation.key} must fail closed',
      );
    }
  });

  test('Emulator discovery is recursive and serials are redacted', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'phase61-integration-inventory-',
    );
    addTearDown(() => fixture.delete(recursive: true));
    await File('${fixture.path}/root_test.dart').create();
    await File(
      '${fixture.path}/helpers/not_a_test.dart',
    ).create(recursive: true);
    await File(
      '${fixture.path}/performance/nested_test.dart',
    ).create(recursive: true);

    expect(
      lane.discoverIntegrationTestFiles(fixture),
      equals(['performance/nested_test.dart', 'root_test.dart']),
    );
    expect(
      lane.redactEmulatorSerial('booted emulator-5580 owned'),
      equals('booted <emulator-redacted> owned'),
    );
  });

  test('Emulator preparation evidence is exact or honestly unavailable', () {
    final valid = <String, Object?>{
      'result': 'UNAVAILABLE',
      'api': 36,
      'abi': 'x86_64',
      'profile': 'pixel_6',
      'system_image': lane.requiredAndroidSystemImage,
      'cold_boot': 'wipe-data/no-snapshot',
      'host_architecture': 'arm64',
      'runtime': 'cross-architecture software translation requested',
      'emulator_version': 'Android emulator version 36.3.10.0',
      'serial_redacted': 'NOT_RUN',
      'failure': 'x86_64 is unsupported on this aarch64 host',
    };

    expect(lane.validateEmulatorPreparationRecord(valid), isEmpty);
    for (final mutation in <String, Object?>{
      'result': 'PASS',
      'api': 35,
      'abi': 'arm64-v8a',
      'system_image': 'system-images;android-36;google_apis;arm64-v8a',
    }.entries) {
      final mutated = {...valid, mutation.key: mutation.value};
      expect(
        lane.validateEmulatorPreparationRecord(mutated),
        isNotEmpty,
        reason: '${mutation.key} must fail closed',
      );
    }
  });

  test('unavailable emulator retries retain prior handoff evidence', () {
    final previous = <String, Object?>{
      'result': 'UNAVAILABLE',
      'cross_architecture_attempts': [
        {'build': '15917651', 'result': 'UNAVAILABLE: bounded diagnostic'},
      ],
      'cleanup': {'runner_owned_avd': 'ABSENT'},
      'exit_condition': 'Run on an x86_64 host.',
    };
    final current = <String, Object?>{
      'result': 'UNAVAILABLE',
      'failure': 'Native QEMU rejected x86_64 on arm64.',
    };

    final merged = lane.mergeEmulatorPreparationRecord(previous, current);

    expect(merged['failure'], current['failure']);
    expect(merged['cross_architecture_attempts'], previous['cross_architecture_attempts']);
    expect(merged['cleanup'], previous['cleanup']);
    expect(merged['exit_condition'], previous['exit_condition']);
  });

  test(
    'release artifact scanner rejects missing and test-contaminated archives',
    () async {
      final fixture = await Directory.systemTemp.createTemp(
        'phase61-artifact-',
      );
      addTearDown(() => fixture.delete(recursive: true));

      expect(
        await lane.scanAndroidReleaseArtifact(
          File('${fixture.path}/missing.apk'),
        ),
        contains('release artifact is missing'),
      );

      final payload = File('${fixture.path}/IntegrationTestPlugin.class');
      await payload.writeAsString(
        'dev.flutter.plugins.integration_test.IntegrationTestPlugin',
      );
      final artifact = File('${fixture.path}/contaminated.apk');
      final zip = await Process.run('zip', [
        '-q',
        artifact.path,
        payload.uri.pathSegments.last,
      ], workingDirectory: fixture.path);
      expect(zip.exitCode, 0, reason: zip.stderr.toString());

      final findings = await lane.scanAndroidReleaseArtifact(artifact);
      expect(findings.join('\n'), contains('test-only archive entry'));
      expect(findings.join('\n'), contains('test-only packaged content'));

      final releaseNotes = File('${fixture.path}/release-notes.txt');
      await releaseNotes.writeAsString(
        'Ordinary integration-test guidance is not a packaged plugin.',
      );
      final benignArtifact = File('${fixture.path}/benign.apk');
      final benignZip = await Process.run('zip', [
        '-q',
        benignArtifact.path,
        releaseNotes.uri.pathSegments.last,
      ], workingDirectory: fixture.path);
      expect(benignZip.exitCode, 0, reason: benignZip.stderr.toString());
      expect(await lane.scanAndroidReleaseArtifact(benignArtifact), isEmpty);
    },
  );

  test(
    'certificate classifier rejects Android Debug and accepts evidence CN',
    () {
      expect(
        lane.classifyAndroidCertificate('CN=Android Debug,O=Android,C=US'),
        lane.AndroidCertificateClass.debug,
      );
      expect(
        lane.classifyAndroidCertificate(
          'CN=Happy Pocket Phase 61 Evidence,O=Happy Pocket,C=JP',
        ),
        lane.AndroidCertificateClass.nonDebug,
      );
    },
  );
}
