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
    baselineJson:
        baselineJson ??
        File('docs/testing/STABLE_BASELINE.json').readAsStringSync(),
    metadataYaml: input['metadata']!,
    flutterExtensionSource: extensionSource ?? _flutterExtensionFixture,
    runningFlutterMachineJson: _runningFlutterMachineJson,
    pubspecOverridesPresent: false,
    trackedInputContents: trackedInputs(input),
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
}
