import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/dependency_compatibility.dart' as compatibility;

const _runningFlutterMachineJson = '''
{
  "flutterVersion": "3.44.8",
  "channel": "stable",
  "frameworkRevision": "058e0af2c2b57e369d905a03ac9748b0ebf543c6"
}
''';

const _flutterExtensionFixture = 'val minSdkVersion: Int = 24';

void main() {
  Map<String, String> currentInputs() => {
    'pubspec': File('pubspec.yaml').readAsStringSync(),
    'lock': File('pubspec.lock').readAsStringSync(),
    'settings': File('android/settings.gradle.kts').readAsStringSync(),
    'appBuild': File('android/app/build.gradle.kts').readAsStringSync(),
    'properties': File('android/gradle.properties').readAsStringSync(),
    'wrapper': File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync(),
    'podfile': File('ios/Podfile').readAsStringSync(),
    'podLock': File('ios/Podfile.lock').readAsStringSync(),
    'xcode': File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
    'audit': File('.github/workflows/audit.yml').readAsStringSync(),
    'future': File(
      '.github/workflows/flutter-future-compat.yml',
    ).readAsStringSync(),
    'metadata': File('.metadata').readAsStringSync(),
  };

  Map<String, String> trackedInputs(Map<String, String> input) => {
    '.metadata': input['metadata']!,
    'pubspec.yaml': input['pubspec']!,
    'pubspec.lock': input['lock']!,
    'android/settings.gradle.kts': input['settings']!,
    'android/app/build.gradle.kts': input['appBuild']!,
    'android/gradle.properties': input['properties']!,
    'android/gradle/wrapper/gradle-wrapper.properties': input['wrapper']!,
    'ios/Podfile': input['podfile']!,
    'ios/Podfile.lock': input['podLock']!,
    'ios/Runner.xcodeproj/project.pbxproj': input['xcode']!,
  };

  List<String> validate(
    Map<String, String> input, {
    String? baselineJson,
    String? extensionSource,
    String? runningFlutterMachineJson,
    bool pubspecOverridesPresent = false,
  }) => compatibility
      .validateDependencyCompatibility(
        pubspecYaml: input['pubspec']!,
        lockYaml: input['lock']!,
        androidSettings: input['settings']!,
        androidAppBuild: input['appBuild']!,
        androidProperties: input['properties']!,
        gradleWrapper: input['wrapper']!,
        podfile: input['podfile']!,
        podfileLock: input['podLock']!,
        xcodeProject: input['xcode']!,
        auditWorkflow: input['audit']!,
        futureWorkflow: input['future']!,
        baselineJson:
            baselineJson ??
            File('docs/testing/STABLE_BASELINE.json').readAsStringSync(),
        metadataYaml: input['metadata']!,
        flutterExtensionSource: extensionSource ?? _flutterExtensionFixture,
        runningFlutterMachineJson:
            runningFlutterMachineJson ?? _runningFlutterMachineJson,
        pubspecOverridesPresent: pubspecOverridesPresent,
        trackedInputContents: trackedInputs(input),
      )
      .messages;

  compatibility.CompatibilityReport validateReport(
    Map<String, String> input, {
    required String baselineJson,
    required compatibility.DependencyCompatibilityMode mode,
  }) => compatibility.validateDependencyCompatibility(
    pubspecYaml: input['pubspec']!,
    lockYaml: input['lock']!,
    androidSettings: input['settings']!,
    androidAppBuild: input['appBuild']!,
    androidProperties: input['properties']!,
    gradleWrapper: input['wrapper']!,
    podfile: input['podfile']!,
    podfileLock: input['podLock']!,
    xcodeProject: input['xcode']!,
    auditWorkflow: input['audit']!,
    futureWorkflow: input['future']!,
    baselineJson: baselineJson,
    metadataYaml: input['metadata']!,
    flutterExtensionSource: _flutterExtensionFixture,
    runningFlutterMachineJson: _runningFlutterMachineJson,
    pubspecOverridesPresent: false,
    trackedInputContents: trackedInputs(input),
    mode: mode,
  );

  test('BASE-01 committed stable baseline manifest exists', () {
    expect(File('docs/testing/STABLE_BASELINE.json').existsSync(), isTrue);
  });

  test('BASE-01 traces the reviewed SQLCipher hold through the validator', () {
    expect(validate(currentInputs()), isEmpty);
  });

  test('BASE-01 returns diagnostics for malformed baseline JSON', () {
    expect(validate(currentInputs(), baselineJson: '{'), isNotEmpty);
  });

  test('BASE-01 rejects an unsupported manifest schema', () {
    final baseline = File(
      'docs/testing/STABLE_BASELINE.json',
    ).readAsStringSync();
    expect(
      validate(
        currentInputs(),
        baselineJson: baseline.replaceFirst(
          '"schema_version": 1',
          '"schema_version": 2',
        ),
      ),
      isNotEmpty,
    );
  });

  test('BASE-01 rejects a missing SQLCipher hold evidence field', () {
    final baseline = File(
      'docs/testing/STABLE_BASELINE.json',
    ).readAsStringSync();
    expect(
      validate(
        currentInputs(),
        baselineJson: baseline.replaceFirst(
          '"exit_condition":',
          '"missing_exit_condition":',
        ),
      ),
      isNotEmpty,
    );
  });

  test(
    'BASE-02 rejects direct dependency inventory drift in both directions',
    () {
      final baseline = File(
        'docs/testing/STABLE_BASELINE.json',
      ).readAsStringSync();
      expect(
        validate(
          currentInputs(),
          baselineJson: baseline.replaceFirst(
            '"cupertino_icons": {',
            '"unexpected_package": {',
          ),
        ),
        isNotEmpty,
      );
    },
  );

  test('BASE-02 rejects tracked input digest drift', () {
    final input = currentInputs();
    input['properties'] = '${input['properties']}\n# drift';
    expect(
      validate(input),
      contains('tracked input digest mismatch: android/gradle.properties'),
    );
  });

  test('BASE-02 rejects an effective Flutter Android floor below API 24', () {
    expect(
      validate(currentInputs(), extensionSource: 'val minSdkVersion: Int = 23'),
      isNotEmpty,
    );
  });

  test('BASE-02 rejects a Stable CI job without an explicit Flutter pin', () {
    final input = currentInputs();
    input['audit'] = input['audit']!.replaceFirst(
      '          flutter-version: 3.44.8\n',
      '',
    );

    expect(
      validate(input),
      contains(
        'every Stable CI Flutter pin must match the selected current identity',
      ),
    );
  });

  group('BASE-03/BASE-04 fail-closed repository fixtures', () {
    String baseline() =>
        File('docs/testing/STABLE_BASELINE.json').readAsStringSync();

    void expectIssue(String source, String expected) {
      expect(
        validate(currentInputs(), baselineJson: source),
        contains(expected),
      );
    }

    test('rejects malformed direct-dependency evidence', () {
      expectIssue(
        baseline().replaceFirst(
          '"official_source": "https://pub.dev/packages/file_picker"',
          '"source": "https://pub.dev/packages/file_picker"',
        ),
        'dependency file_picker is missing required field: official_source',
      );
    });

    test('rejects an EOL SQLCipher selection', () {
      expectIssue(
        baseline().replaceFirst(
          '"resolved": "0.6.8"',
          '"resolved": "0.7.0+eol"',
        ),
        'dependency sqlcipher_flutter_libs selects forbidden prerelease or EOL value',
      );
    });

    test('rejects prerelease candidates presented as production stable', () {
      expectIssue(
        baseline().replaceFirst(
          '"candidate": "3.44.8"',
          '"candidate": "3.45.0-beta.1"',
        ),
        'dependency flutter candidate must be production stable',
      );
    });

    test('rejects a selected value below its reviewed candidate', () {
      expectIssue(
        baseline().replaceFirst(
          '"selected_current": "3.44.8"',
          '"selected_current": "3.44.7"',
        ),
        'toolchain flutter selected value must not be lower than its candidate',
      );
    });

    test('rejects dependency_overrides in pubspec independently', () {
      final input = currentInputs();
      input['pubspec'] =
          '${input['pubspec']}\ndependency_overrides:\n  intl: 0.20.2\n';
      expect(
        validate(input),
        contains('pubspec dependency_overrides must not be present'),
      );
    });

    test('rejects a present pubspec_overrides.yaml independently', () {
      expect(
        validate(currentInputs(), pubspecOverridesPresent: true),
        contains('pubspec_overrides.yaml must not be present'),
      );
    });

    test('rejects plaintext sqlite3_flutter_libs', () {
      final input = currentInputs();
      input['pubspec'] = input['pubspec']!.replaceFirst(
        '  sqlite3: ^2.9.4',
        '  sqlite3: ^2.9.4\n  sqlite3_flutter_libs: ^0.5.0',
      );
      expect(
        validate(input),
        contains(
          'sqlite3_flutter_libs conflicts with SQLCipher and is forbidden',
        ),
      );
    });

    test('rejects a missing SQLCipher linker strip', () {
      final input = currentInputs();
      input['podfile'] = input['podfile']!.replaceFirst(
        'original.gsub',
        'original.sub',
      );
      expect(
        validate(input),
        contains(
          'ios/Podfile must preserve the SQLCipher system-SQLite linker strip',
        ),
      );
    });

    test('rejects an incomplete atomic compatibility lane', () {
      expectIssue(
        baseline().replaceFirst(' + sqlite3 2.9.4', ''),
        'compatibility lane encrypted_storage is incomplete',
      );
    });

    test('rejects an iOS support floor below 15.0', () {
      expectIssue(
        baseline().replaceFirst('"selected": "15.0"', '"selected": "14.0"'),
        'iOS support floor must be 15.0',
      );
    });

    test('rejects missing Stable CI mode contract marker', () {
      final input = currentInputs();
      input['audit'] = input['audit']!.replaceFirst(
        '--verify-running-flutter-sdk',
        '',
      );
      expect(
        validate(input),
        contains('audit workflow must invoke SDK verification'),
      );
    });

    test('rejects metadata revision and channel drift independently', () {
      final input = currentInputs();
      input['metadata'] = input['metadata']!.replaceFirst(
        'channel: "stable"',
        'channel: "beta"',
      );
      expect(
        validate(input),
        contains(
          '.metadata channel must match the selected Flutter Stable identity',
        ),
      );
    });

    test('rejects running SDK machine JSON identity drift', () {
      expect(
        validate(
          currentInputs(),
          runningFlutterMachineJson: _runningFlutterMachineJson.replaceFirst(
            '3.44.8',
            '3.45.0',
          ),
        ),
        contains(
          'running Flutter SDK must match the selected current identity',
        ),
      );
    });

    test('rejects missing and malformed FlutterExtension minSdk source', () {
      expect(
        validate(currentInputs(), extensionSource: ''),
        contains(
          'FlutterExtension.kt is missing from the resolved Flutter SDK',
        ),
      );
      expect(
        validate(
          currentInputs(),
          extensionSource: 'val minSdkVersion: Int = API24',
        ),
        contains('FlutterExtension.kt must declare an integer minSdkVersion'),
      );
    });

    test('rejects inherited minSdk removal and API 23', () {
      final input = currentInputs();
      input['appBuild'] = input['appBuild']!.replaceFirst(
        'minSdk = flutter.minSdkVersion',
        'minSdk = 24',
      );
      expect(
        validate(input),
        contains('Android minSdk must inherit flutter.minSdkVersion'),
      );
      expect(
        validate(
          currentInputs(),
          extensionSource: 'val minSdkVersion: Int = 23',
        ),
        contains(
          'FlutterExtension.kt minSdkVersion must match the manifest and be >= 24',
        ),
      );
    });
  });

  test('CLI parser accepts strict modes and rejects malformed arguments', () {
    expect(
      compatibility.parseDependencyCompatibilityMode(const []),
      compatibility.DependencyCompatibilityMode.baseline,
    );
    expect(
      compatibility.parseDependencyCompatibilityMode(const [
        '--mode=future-probe',
        '--verify-running-flutter-sdk',
      ]),
      compatibility.DependencyCompatibilityMode.futureProbe,
    );
    expect(
      () => compatibility.parseDependencyCompatibilityMode(const [
        '--mode=baseline',
        '--mode=future-probe',
      ]),
      throwsArgumentError,
    );
    expect(
      () => compatibility.parseDependencyCompatibilityMode(const [
        '--mode=unknown',
      ]),
      throwsArgumentError,
    );
  });

  test('future probe demotes only ordinary candidate drift', () {
    final baseline = File('docs/testing/STABLE_BASELINE.json')
        .readAsStringSync()
        .replaceFirst('"candidate": "3.44.8"', '"candidate": "3.45.0-beta.1"');
    final stable = validateReport(
      currentInputs(),
      baselineJson: baseline,
      mode: compatibility.DependencyCompatibilityMode.baseline,
    );
    final probe = validateReport(
      currentInputs(),
      baselineJson: baseline,
      mode: compatibility.DependencyCompatibilityMode.futureProbe,
    );

    expect(stable.errors, isNotEmpty);
    expect(probe.errors, isEmpty);
    expect(probe.warnings, hasLength(1));
    expect(probe.isPassing, isTrue);
  });

  test('future probe keeps security and platform-floor failures blocking', () {
    final baseline = File('docs/testing/STABLE_BASELINE.json')
        .readAsStringSync()
        .replaceFirst('"resolved": "0.6.8"', '"resolved": "0.7.0+eol"')
        .replaceFirst('"selected": 24', '"selected": 23');
    final probe = validateReport(
      currentInputs(),
      baselineJson: baseline,
      mode: compatibility.DependencyCompatibilityMode.futureProbe,
    );

    expect(probe.errors, isNotEmpty);
    expect(probe.warnings, isEmpty);
  });

  group('CI workflow source contracts', () {
    const baselineCommand =
        'dart run scripts/dependency_compatibility.dart '
        '--mode=baseline --verify-running-flutter-sdk';
    const futureProbeCommand =
        'dart run scripts/dependency_compatibility.dart '
        '--mode=future-probe --verify-running-flutter-sdk';

    test('Stable analysis pins, locks, and verifies the baseline before analyze',
        () {
      final audit = currentInputs()['audit']!;
      expect(audit, contains('flutter-version: 3.44.8'));
      expect(audit, contains('flutter pub get --enforce-lockfile'));
      expect(audit, contains(baselineCommand));
      expect(
        audit.indexOf('flutter pub get --enforce-lockfile'),
        lessThan(audit.indexOf(baselineCommand)),
      );
      expect(
        audit.indexOf(baselineCommand),
        lessThan(audit.indexOf('run: flutter analyze')),
      );
    });

    test('both beta jobs are explicit future probes that keep their builds', () {
      final future = currentInputs()['future']!;
      expect(RegExp(r'channel: beta').allMatches(future), hasLength(2));
      expect(RegExp(RegExp.escape(futureProbeCommand)).allMatches(future),
          hasLength(2));
      expect(future, contains('flutter build apk --debug'));
      expect(future, contains('flutter build ios --simulator --debug'));
      expect(future, isNot(contains('--mode=baseline')));
    });
  });

  test(
    'concurrent pure validations return identical immutable reports',
    () async {
      final baseline = File(
        'docs/testing/STABLE_BASELINE.json',
      ).readAsStringSync();
      final input = currentInputs();
      final reports = await Future.wait(
        List.generate(
          4,
          (_) async => validateReport(
            input,
            baselineJson: baseline,
            mode: compatibility.DependencyCompatibilityMode.baseline,
          ),
        ),
      );

      expect(
        reports.map((report) => report.messages),
        everyElement(equals([])),
      );
      expect(
        () => reports.first.issues.add(
          const compatibility.CompatibilityIssue(
            code: 'TEST',
            severity: compatibility.CompatibilitySeverity.error,
            message: 'test',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(input['pubspec'], File('pubspec.yaml').readAsStringSync());
    },
  );
}
