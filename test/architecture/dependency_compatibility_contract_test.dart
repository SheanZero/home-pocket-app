import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/dependency_compatibility.dart' as compatibility;

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
  };

  List<String> validate(Map<String, String> input) {
    return compatibility.validateDependencyCompatibility(
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
    );
  }

  test('P2-04 current dependency and native compatibility contract passes', () {
    expect(validate(currentInputs()), isEmpty);
  });

  test('P2-04 rejects the no-op SQLCipher EOL line', () {
    final input = currentInputs();
    input['pubspec'] = input['pubspec']!.replaceFirst(
      'sqlcipher_flutter_libs: ^0.6.8',
      'sqlcipher_flutter_libs: ^0.7.0',
    );

    expect(
      validate(input),
      contains(contains('sqlcipher_flutter_libs constraint')),
    );
  });

  test('P2-04 rejects an uncoordinated stable plugin upgrade', () {
    final input = currentInputs();
    input['pubspec'] = input['pubspec']!.replaceFirst(
      'share_plus: ^12.0.2',
      'share_plus: ^13.3.0',
    );

    expect(validate(input), contains(contains('share_plus constraint')));
  });

  test('P2-04 rejects an analyzer-incompatible Riverpod upgrade', () {
    final input = currentInputs();
    input['pubspec'] = input['pubspec']!.replaceFirst(
      'flutter_riverpod: ^3.1.0',
      'flutter_riverpod: ^3.4.2',
    );

    expect(validate(input), contains(contains('flutter_riverpod constraint')));
  });

  test('P2-04 rejects analyzer versions outside the verified 8.x line', () {
    final input = currentInputs();
    input['lock'] = input['lock']!.replaceFirst(
      'version: "8.4.0"',
      'version: "9.0.0"',
    );

    expect(validate(input), contains(contains('analyzer lock')));
  });

  test('P2-04 rejects premature Built-in Kotlin enablement', () {
    final input = currentInputs();
    input['properties'] = input['properties']!.replaceFirst(
      'android.builtInKotlin=false',
      'android.builtInKotlin=true',
    );

    expect(validate(input), contains(contains('android.builtInKotlin=false')));
  });
}
