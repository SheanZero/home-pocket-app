import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/release_preflight.sh';
const _runAndroidReleasePreflightTests = bool.fromEnvironment(
  'RUN_ANDROID_RELEASE_PREFLIGHT_TESTS',
);
const _androidReleasePreflightSkipReason =
    'Android release preflight tests are disabled by default. Set '
    'RUN_ANDROID_RELEASE_PREFLIGHT_TESTS=true to enable them.';

String _projectRoot() => Directory.current.path;

Future<ProcessResult> _runScript(
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) {
  return Process.run(
    'bash',
    [_scriptPath, ...arguments],
    workingDirectory: workingDirectory ?? _projectRoot(),
    environment: environment,
  );
}

Future<Directory> _createFakeJdk({
  required String versionOutput,
  int exitCode = 0,
  bool createJava = true,
}) async {
  final home = await Directory.systemTemp.createTemp('release-preflight-jdk-');
  if (!createJava) return home;

  final java = File('${home.path}/bin/java');
  await java.create(recursive: true);
  await java.writeAsString('''#!/usr/bin/env bash
printf '%s\\n' '${versionOutput.replaceAll("'", "'\\\"'\\\"'")}' >&2
exit $exitCode
''');
  await Process.run('chmod', ['+x', java.path]);
  return home;
}

String? _androidPackageJdkGateContractFailure(String source) {
  const gateCall = 'android|all) verify_android_package_jdk17 ;;';
  const packageCall = 'package_signed_release';
  final gate = source.lastIndexOf(gateCall);
  final package = source.lastIndexOf(packageCall);

  if (gate < 0) return 'missing Android package JDK gate invocation';
  if (package < 0) return 'missing signed package invocation';
  if (gate > package) return 'Android package JDK gate runs after packaging';
  if (!source.contains(r'[[ "$java_major" == "17" ]]')) {
    return 'JDK gate does not require exact major 17';
  }
  if (!source.contains(r'"$java_binary" -version 2>&1')) {
    return 'JDK gate does not execute the configured java binary';
  }
  if (!source.contains(r'export JAVA_HOME="$jdk_home"')) {
    return 'JDK gate does not export the verified home';
  }
  if (!source.contains(r'export PATH="$JAVA_HOME/bin:$PATH"')) {
    return 'JDK gate does not prioritize the verified Java binary';
  }
  return null;
}

Future<ProcessResult> _scanFixture(
  Directory fixture, {
  String platform = 'all',
}) {
  final script = File('${_projectRoot()}/$_scriptPath').absolute.path;
  return Process.run('bash', [
    '-c',
    r'source "$1"; RELEASE_PREFLIGHT_PLATFORM="$3"; assert_release_registrants_clean "$2"',
    'release-preflight-test',
    script,
    fixture.path,
    platform,
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
      'Android-only scan ignores unrelated regenerated iOS dev registrant',
      () async {
        final fixture = await Directory.systemTemp.createTemp(
          'release-preflight-platform-',
        );
        addTearDown(() => fixture.delete(recursive: true));
        final androidRegistrant = File(
          '${fixture.path}/android/app/src/main/java/io/flutter/plugins/'
          'GeneratedPluginRegistrant.java',
        );
        final iosRegistrant = File(
          '${fixture.path}/ios/Runner/GeneratedPluginRegistrant.m',
        );
        await androidRegistrant.create(recursive: true);
        await androidRegistrant.writeAsString('register production plugins');
        await iosRegistrant.create(recursive: true);
        await iosRegistrant.writeAsString('IntegrationTestPlugin');

        final result = await _scanFixture(fixture, platform: 'android');

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
      },
    );

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
      skip: _runAndroidReleasePreflightTests
          ? false
          : _androidReleasePreflightSkipReason,
    );

    test('Android package requires independent JDK 17 proof', () async {
      final jdk17 = await _createFakeJdk(
        versionOutput: 'openjdk version "17.0.15" 2025-04-15',
      );
      final jdk21 = await _createFakeJdk(
        versionOutput: 'openjdk version "21.0.7" 2025-04-15',
      );
      final invalidJdk = await _createFakeJdk(
        versionOutput: 'not a Java version',
        exitCode: 1,
      );
      final missingJava = await _createFakeJdk(
        versionOutput: '',
        createJava: false,
      );
      addTearDown(() async {
        await jdk17.delete(recursive: true);
        await jdk21.delete(recursive: true);
        await invalidJdk.delete(recursive: true);
        await missingJava.delete(recursive: true);
      });

      Future<ProcessResult> packageWith(String jdkHome) => _runScript(
        ['--platform', 'android', '--package', '--dry-run'],
        environment: {
          ...Platform.environment,
          'PHASE61_JAVA_HOME': jdkHome,
          'JAVA_HOME': '/ignored-java-home',
          'PHASE61_SIGNING_EVIDENCE': 'true',
        },
      );

      final accepted = await packageWith(jdk17.path);
      expect(accepted.exitCode, equals(0), reason: accepted.stderr.toString());
      expect(
        accepted.stdout,
        contains('Android package JDK verified: ${jdk17.path}'),
      );
      expect(accepted.stdout, contains('bundleRelease'));
      expect(accepted.stdout, contains('assembleRelease'));

      for (final rejected in [jdk21, invalidJdk, missingJava]) {
        final result = await packageWith(rejected.path);
        expect(result.exitCode, isNonZero);
        expect(result.stdout, isNot(contains('bundleRelease')));
        expect(result.stdout, isNot(contains('assembleRelease')));
        expect(
          result.stdout,
          isNot(contains('flutter build appbundle --release')),
        );
      }

      final source = File(_scriptPath).readAsStringSync();
      expect(_androidPackageJdkGateContractFailure(source), isNull);

      final removed = source.replaceFirst(
        'android|all) verify_android_package_jdk17 ;;',
        'android|all) ;;',
      );
      expect(_androidPackageJdkGateContractFailure(removed), isNotNull);

      final late = source
          .replaceFirst(
            'android|all) verify_android_package_jdk17 ;;',
            'android|all) ;;',
          )
          .replaceFirst(
            '    package_signed_release',
            '    package_signed_release\n'
                '    case "\$RELEASE_PREFLIGHT_PLATFORM" in\n'
                '      android|all) verify_android_package_jdk17 ;;\n'
                '    esac',
          );
      expect(_androidPackageJdkGateContractFailure(late), isNotNull);

      final weakened = source.replaceFirst(
        r'[[ "$java_major" == "17" ]]',
        r'[[ "$java_major" == "17" || "$java_major" == "21" ]]',
      );
      expect(_androidPackageJdkGateContractFailure(weakened), isNotNull);
    });

    test(
      'the iOS release gate always routes integration cleanup to preflight',
      () {
        final stage = File(
          'scripts/release_gate/ios_simulator_stage.dart',
        ).readAsStringSync();
        final preflight = stage.indexOf('scripts/release_preflight.sh');
        final cleanup = stage.lastIndexOf("'erase'");

        expect(preflight, greaterThanOrEqualTo(0));
        expect(cleanup, greaterThan(preflight));
      },
    );
  });
}
