import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/dependency_compatibility.dart' as compatibility;

const _runningFlutterMachineJson = '''
{
  "flutterVersion": "3.44.8",
  "channel": "stable",
  "frameworkRevision": "058e0af2c2b57e369d905a03ac9748b0ebf543c6",
  "dartSdkVersion": "3.12.2"
}
''';

const _betaFlutterMachineJson = '''
{
  "flutterVersion": "3.45.0-0.1.pre",
  "channel": "beta",
  "frameworkRevision": "aabbccddeeff00112233445566778899aabbccdd",
  "dartSdkVersion": "3.13.0-0.1.pre"
}
''';

const _flutterExtensionFixture = '''
val compileSdkVersion: Int = 36
val minSdkVersion: Int = 24
val targetSdkVersion: Int = 36
''';

const _generatedSwiftPackageIos15Manifest = '''
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ]
)
''';

String _activeWorkflowSource(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .join('\n');

String? _workflowJobSource(String workflow, String jobName) {
  final source = _activeWorkflowSource(workflow);
  final start = RegExp(
    '^  ${RegExp.escape(jobName)}:\\n',
    multiLine: true,
  ).firstMatch(source);
  if (start == null) return null;
  Match? next;
  for (final match in RegExp(
    r'^  [a-z][a-z0-9-]*:\n',
    multiLine: true,
  ).allMatches(source)) {
    if (match.start >= start.end) {
      next = match;
      break;
    }
  }
  return source.substring(start.end, next?.start ?? source.length);
}

List<String> _stableReleaseAuthorityViolations(String workflow) {
  final releaseGateHost = _workflowJobSource(workflow, 'release-gate-host');
  if (releaseGateHost == null) {
    return ['Stable release-gate host job is missing'];
  }

  const authorityCommand = 'dart run scripts/release_gate.dart --scope=host';
  final authorityMatches = RegExp(
    '^\\s*-\\s*(?:name: [^\\n]+\\n\\s*)?run: ${RegExp.escape(authorityCommand)}${r'\s*$'}',
    multiLine: true,
  ).allMatches(releaseGateHost);
  final violations = <String>[];
  if (authorityMatches.length != 1) {
    violations.add(
      'Stable CI must invoke the host release authority exactly once',
    );
  }

  final checkout = releaseGateHost.indexOf('uses: actions/checkout@v4');
  final flutterPin = releaseGateHost.indexOf('flutter-version: 3.44.8');
  final authority = releaseGateHost.indexOf(authorityCommand);
  if (checkout < 0 || flutterPin < checkout || authority < flutterPin) {
    violations.add(
      'release authority must follow checkout and the exact Stable Flutter pin',
    );
  }

  const directCommands = [
    'flutter pub get',
    'bash scripts/verify_codegen_reproducibility.sh',
    'dart run scripts/dependency_compatibility.dart',
    'flutter analyze',
    'dart run import_lint',
    'flutter gen-l10n',
    'build_runner build',
    'dart run scripts/verify_tooling_guards.dart',
    'test/architecture/layer_import_rules_test.dart',
    'test/architecture/domain_import_rules_test.dart',
    'test/architecture/presentation_layer_rules_test.dart',
  ];
  for (final command in directCommands) {
    if (releaseGateHost.contains(command)) {
      violations.add('Stable release-gate host must not duplicate $command');
    }
  }
  if (releaseGateHost.contains('continue-on-error: true') ||
      releaseGateHost.contains('|| true')) {
    violations.add('Stable release authority must not soften failures');
  }
  return violations;
}

List<String> _stableWorkflowAuthorityUniquenessViolations(String workflow) {
  final activeWorkflow = _activeWorkflowSource(workflow);
  const authorityCommand = 'dart run scripts/release_gate.dart --scope=host';
  final releaseGateHost = _workflowJobSource(workflow, 'release-gate-host');
  final auditScanners = _workflowJobSource(workflow, 'audit-scanners');
  final violations = <String>[];

  if (RegExp(
        '^\\s*-\\s*(?:name: [^\\n]+\\n\\s*)?run: ${RegExp.escape(authorityCommand)}${r'\s*$'}',
        multiLine: true,
      ).allMatches(activeWorkflow).length !=
      1) {
    violations.add(
      'Stable workflow must invoke the release authority exactly once',
    );
  }
  if (releaseGateHost == null || !releaseGateHost.contains(authorityCommand)) {
    violations.add(
      'the sole authority invocation must live in release-gate-host',
    );
  }
  if (auditScanners == null) {
    violations.add('Supplemental audit-scanners job is missing');
    return violations;
  }
  if (!auditScanners.contains('flutter pub get --enforce-lockfile')) {
    violations.add(
      'supplemental scanners must use enforced dependency retrieval',
    );
  }

  const duplicateCommands = [
    'flutter gen-l10n',
    'build_runner build',
    'flutter analyze',
    'dart run import_lint',
    'dart run scripts/verify_tooling_guards.dart',
    'test/architecture/layer_import_rules_test.dart',
    'test/architecture/domain_import_rules_test.dart',
    'test/architecture/presentation_layer_rules_test.dart',
  ];
  for (final command in duplicateCommands) {
    if (activeWorkflow.contains(command)) {
      violations.add('Stable workflow must not duplicate $command');
    }
  }
  final host = releaseGateHost;
  if (host != null &&
      (host.contains('continue-on-error: true') || host.contains('|| true'))) {
    violations.add('Stable release authority must not soften failures');
  }
  return violations;
}

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
    String? generatedSwiftPackageManifest,
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
        legacyKgpPlugins: const [
          'file_picker',
          'package_info_plus',
          'share_plus',
          'speech_to_text',
        ],
        generatedSwiftPackageManifest: generatedSwiftPackageManifest,
        pubspecOverridesPresent: pubspecOverridesPresent,
        trackedInputContents: trackedInputs(input),
      )
      .messages;

  compatibility.CompatibilityReport validateReport(
    Map<String, String> input, {
    required String baselineJson,
    required compatibility.DependencyCompatibilityMode mode,
    String? extensionSource,
    String? runningFlutterMachineJson,
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
    flutterExtensionSource: extensionSource ?? _flutterExtensionFixture,
    runningFlutterMachineJson:
        runningFlutterMachineJson ?? _runningFlutterMachineJson,
    legacyKgpPlugins: const [
      'file_picker',
      'package_info_plus',
      'share_plus',
      'speech_to_text',
    ],
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

  test('AND-01/AND-02 terminal Android hold rejects every coupled drift', () {
    final mutations = <String, (String, String, String)>{
      'settings': (
        'id("com.android.application") version "8.11.1"',
        'id("com.android.application") version "9.3.1"',
        'Android hold must declare AGP 8.11.1 exactly once',
      ),
      'wrapper': (
        'gradle-8.14-all.zip',
        'gradle-9.5.0-all.zip',
        'Android hold wrapper must be exactly Gradle 8.14',
      ),
      'properties': (
        'android.builtInKotlin=false',
        '',
        'Android hold must retain both legacy opt-outs exactly once',
      ),
      'appBuild': (
        'id("kotlin-android")',
        '',
        'Android hold must apply app KGP exactly once',
      ),
    };

    for (final entry in mutations.entries) {
      final input = currentInputs();
      input[entry.key] = input[entry.key]!.replaceFirst(
        entry.value.$1,
        entry.value.$2,
      );
      expect(validate(input), contains(entry.value.$3), reason: entry.key);
    }
  });

  test('AND-01/AND-04 independently lock JDK 17 and Android API 36/24', () {
    final baseline =
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;
    final toolchains = baseline['toolchains'] as Map<String, dynamic>;
    (toolchains['jdk'] as Map<String, dynamic>)['selected_current'] = '21';
    expect(
      validate(currentInputs(), baselineJson: jsonEncode(baseline)),
      contains('Android JDK must be exactly 17'),
    );

    expect(
      validate(
        currentInputs(),
        extensionSource: _flutterExtensionFixture.replaceAll('36', '35'),
      ),
      contains(
        'FlutterExtension.kt compileSdkVersion and targetSdkVersion must both be API 36',
      ),
    );

    final app = currentInputs();
    app['appBuild'] = app['appBuild']!.replaceFirst(
      'targetCompatibility = JavaVersion.VERSION_17',
      'targetCompatibility = JavaVersion.VERSION_11',
    );
    expect(
      validate(app),
      contains(
        'Android Java source and target compatibility must remain JDK 17',
      ),
    );
  });

  test('AND-02 cannot relabel the current legacy graph as selected', () {
    final baseline =
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;
    final lane =
        (baseline['lanes'] as Map<String, dynamic>)['phase61_android']
            as Map<String, dynamic>;
    lane['decision'] = 'selected';
    lane['selected'] =
        'AGP 9.3.1 + Gradle 9.5.0 + built-in Kotlin/new DSL + JDK 17 + API 36';
    final toolchains = baseline['toolchains'] as Map<String, dynamic>;
    (toolchains['agp'] as Map<String, dynamic>)['selected_current'] = '9.3.1';
    (toolchains['gradle'] as Map<String, dynamic>)['selected_current'] =
        '9.5.0';

    expect(
      validate(currentInputs(), baselineJson: jsonEncode(baseline)),
      contains(
        'Android selected graph must use only the built-in Kotlin compiler DSL',
      ),
    );
  });

  test(
    'GEN-02/GEN-03 exact analyzer and code-generation graph fails closed',
    () {
      final expectedLockVersions = <String, String>{
        'analyzer': '12.1.0',
        'analyzer_plugin': '0.14.8',
        'build': '4.0.7',
        'source_gen': '4.2.4',
        'flutter_riverpod': '3.3.2',
        'riverpod': '3.3.2',
        'riverpod_annotation': '4.0.3',
        'riverpod_generator': '4.0.4',
        'riverpod_lint': '3.1.4',
        'freezed_annotation': '3.1.0',
        'freezed': '3.2.6-dev.1',
        'json_annotation': '4.12.0',
        'json_serializable': '6.14.1',
        'drift': '2.34.0',
        'drift_dev': '2.34.0',
        'build_runner': '2.15.1',
        'import_lint': '2.0.0',
        'dart_code_linter': '4.1.9',
      };

      for (final entry in expectedLockVersions.entries) {
        final input = currentInputs();
        final matcher = RegExp(
          '(^  ${RegExp.escape(entry.key)}:\\n'
          r'(?:^(?:    |      ).*\n)*?^    version: )"'
          '${RegExp.escape(entry.value)}"',
          multiLine: true,
        );
        expect(matcher.hasMatch(input['lock']!), isTrue, reason: entry.key);
        input['lock'] = input['lock']!.replaceFirstMapped(
          matcher,
          (match) =>
              match.group(0)!.replaceFirst(entry.value, '${entry.value}.drift'),
        );

        expect(
          validate(input),
          contains(
            '${entry.key} lock must be ${entry.value} '
            '(found ${entry.value}.drift)',
          ),
          reason: entry.key,
        );
      }
    },
  );

  test(
    'GEN-01/GEN-03 requires the canonical exact graph in the architecture lane',
    () {
      const laneMembers = [
        'analyzer 12.1.0',
        'analyzer_plugin 0.14.8',
        'build 4.0.7',
        'source_gen 4.2.4',
        'flutter_riverpod 3.3.2',
        'riverpod_annotation 4.0.3',
        'riverpod_generator 4.0.4',
        'riverpod_lint 3.1.4',
        'freezed_annotation 3.1.0',
        'freezed 3.2.6-dev.1',
        'json_annotation 4.12.0',
        'json_serializable 6.14.1',
        'drift 2.34.0',
        'drift_dev 2.34.0',
        'build_runner 2.15.1',
        'import_lint 2.0.0',
        'dart_code_linter 4.1.9',
      ];
      final baseline = File(
        'docs/testing/STABLE_BASELINE.json',
      ).readAsStringSync();

      for (final member in laneMembers) {
        final manifest = jsonDecode(baseline) as Map<String, dynamic>;
        final lanes = manifest['lanes'] as Map<String, dynamic>;
        final architecture = lanes['architecture'] as Map<String, dynamic>;
        architecture['selected'] = (architecture['selected'] as String)
            .replaceFirst(member, '');
        expect(
          validate(currentInputs(), baselineJson: jsonEncode(manifest)),
          contains('compatibility lane architecture is incomplete'),
          reason: member,
        );
      }
    },
  );

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

    test('rejects a direct-dependency hold without a compatibility reason', () {
      final manifest = jsonDecode(baseline()) as Map<String, dynamic>;
      final dependencies =
          manifest['direct_dependencies'] as Map<String, dynamic>;
      final riverpod = dependencies['flutter_riverpod'] as Map<String, dynamic>;
      riverpod.remove('compatibility_reason');

      expectIssue(
        jsonEncode(manifest),
        'dependency flutter_riverpod hold is missing required field: '
        'compatibility_reason',
      );
    });

    test('rejects a toolchain hold with a blank exit condition', () {
      final manifest = jsonDecode(baseline()) as Map<String, dynamic>;
      final toolchains = manifest['toolchains'] as Map<String, dynamic>;
      final xcode = toolchains['xcode'] as Map<String, dynamic>;
      xcode['exit_condition'] = '   ';

      expectIssue(
        jsonEncode(manifest),
        'toolchain xcode hold is missing required field: exit_condition',
      );
    });

    test('rejects an EOL SQLCipher selection', () {
      expectIssue(
        baseline().replaceFirst(
          '"resolved": "3.5.1"',
          '"resolved": "3.5.1+eol"',
        ),
        'dependency sqlite3 selects forbidden prerelease or EOL value',
      );
    });

    test('rejects prerelease candidates presented as production stable', () {
      final manifest = jsonDecode(baseline()) as Map<String, dynamic>;
      final dependencies =
          manifest['direct_dependencies'] as Map<String, dynamic>;
      final flutter = dependencies['flutter'] as Map<String, dynamic>;
      flutter['candidate'] = '3.45.0-beta.1';
      expectIssue(
        jsonEncode(manifest),
        'dependency flutter candidate must be production stable',
      );
    });

    test('rejects a selected value below its reviewed candidate', () {
      expectIssue(
        baseline().replaceFirst(
          '"selected_current": "36"',
          '"selected_current": "35"',
        ),
        'toolchain android_sdk selected value must not be lower than its candidate',
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
        '  sqlite3: ^3.3.1',
        '  sqlite3: ^3.3.1\n  sqlite3_flutter_libs: ^0.5.0',
      );
      expect(
        validate(input),
        contains(
          'sqlite3_flutter_libs conflicts with SQLCipher and is forbidden',
        ),
      );
    });

    test('rejects every independent Native Assets graph substitution', () {
      final declarationMutations = <String, String>{
        'Drift declaration': 'drift: 2.34.1',
        'sqlite3 declaration': 'sqlite3: ^3.3.2',
        'legacy SQLCipher Flutter library':
            'sqlite3: ^3.3.1\n  sqlcipher_flutter_libs: 0.6.8',
      };
      final declarationDiagnostics = <String, String>{
        'Drift declaration': 'drift constraint must be 2.34.0 (found 2.34.1)',
        'sqlite3 declaration':
            'sqlite3 constraint must be ^3.3.1 (found ^3.3.2)',
        'legacy SQLCipher Flutter library':
            'sqlcipher_flutter_libs is obsolete on the sqlite3 Native Assets path',
      };
      for (final entry in declarationMutations.entries) {
        final input = currentInputs();
        input['pubspec'] = input['pubspec']!.replaceFirst(
          entry.key == 'Drift declaration'
              ? 'drift: 2.34.0'
              : 'sqlite3: ^3.3.1',
          entry.value,
        );
        expect(validate(input), contains(declarationDiagnostics[entry.key]));
      }

      final lockMutations = <String, (String, String)>{
        'Drift lock': ('drift', '2.34.1'),
        'sqlite3 lock': ('sqlite3', '3.5.2'),
      };
      for (final entry in lockMutations.entries) {
        final input = currentInputs();
        final package = entry.value.$1;
        final actual = entry.value.$2;
        input['lock'] = input['lock']!.replaceFirstMapped(
          RegExp(
            '(^  ${RegExp.escape(package)}:\\n'
            r'(?:^(?:    |      ).*\n)*?^    version: )"[^"]+"',
            multiLine: true,
          ),
          (match) => '${match.group(1)}"$actual"',
        );
        expect(
          validate(input),
          contains(
            '$package lock must be ${package == 'drift' ? '2.34.0' : '3.5.1'} (found $actual)',
          ),
        );
      }

      final hookInput = currentInputs();
      hookInput['pubspec'] = hookInput['pubspec']!.replaceFirst(
        'source: sqlcipher',
        'source: sqlite3',
      );
      expect(
        validate(hookInput),
        contains(
          'pubspec must select SQLCipher through hooks.user_defines.sqlite3.source',
        ),
      );

      final podInput = currentInputs();
      podInput['podLock'] = '${podInput['podLock']}\n  - SQLCipher (4.17.0)\n';
      expect(
        validate(podInput),
        contains(
          'ios/Podfile.lock must not retain the legacy SQLCipher CocoaPod path',
        ),
      );
    });

    test('rejects an active legacy SQLCipher linker strip', () {
      final input = currentInputs();
      input['podfile'] = '''${input['podfile']}
installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
    ref = config.base_configuration_reference
    next if ref.nil?
    xcconfig_path = ref.real_path
    original = File.read(xcconfig_path)
    stripped = original.gsub(/\\s-l"?sqlite3"?/, '')
    File.write(xcconfig_path, stripped) if stripped != original
  end
end
''';
      expect(
        validate(input),
        contains(
          'ios/Podfile must not retain the obsolete sqlite3 linker strip',
        ),
      );
    });

    test('ignores an obsolete linker strip inside a Ruby block comment', () {
      final input = currentInputs();
      input['podfile'] = '''${input['podfile']}
=begin
installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
    stripped = original.gsub(/\\s-l"?sqlite3"?/, '')
    File.write(xcconfig_path, stripped) if stripped != original
  end
end
=end
''';

      expect(
        validate(input),
        isNot(
          contains(
            'ios/Podfile must not retain the obsolete sqlite3 linker strip',
          ),
        ),
      );
    });

    test('rejects an incomplete atomic compatibility lane', () {
      expectIssue(
        baseline().replaceFirst(' + sqlite3 3.5.1', ''),
        'compatibility lane encrypted_storage is incomplete',
      );
    });

    test('rejects an iOS support floor below 15.0', () {
      expectIssue(
        baseline().replaceFirst('"selected": "15.0"', '"selected": "14.0"'),
        'iOS support floor must be 15.0',
      );
    });

    test('rejects native iOS deployment targets below 15.0', () {
      final podfileInput = currentInputs();
      podfileInput['podfile'] = podfileInput['podfile']!.replaceFirst(
        "platform :ios, '15.0'",
        "platform :ios, '14.0'",
      );
      expect(
        validate(podfileInput),
        contains('ios/Podfile platform must declare iOS 15.0 or later'),
      );

      final xcodeInput = currentInputs();
      xcodeInput['xcode'] = xcodeInput['xcode']!.replaceFirst(
        'IPHONEOS_DEPLOYMENT_TARGET = 15.0;',
        'IPHONEOS_DEPLOYMENT_TARGET = 14.0;',
      );
      expect(
        validate(xcodeInput),
        contains(
          'every Xcode IPHONEOS_DEPLOYMENT_TARGET must be iOS 15.0 or later',
        ),
      );
    });

    test('rejects an explicit generated Swift package floor below iOS 15', () {
      expect(
        validate(
          currentInputs(),
          generatedSwiftPackageManifest: _generatedSwiftPackageIos15Manifest,
        ),
        isEmpty,
      );
      expect(
        validate(
          currentInputs(),
          generatedSwiftPackageManifest: _generatedSwiftPackageIos15Manifest
              .replaceFirst('15.0', '14.0'),
        ),
        contains(
          'generated Flutter Swift package must declare iOS 15.0 or later',
        ),
      );
    });

    test('rejects a comment-only Stable CI release-authority marker', () {
      final input = currentInputs();
      input['audit'] = input['audit']!.replaceFirst(
        '        run: dart run scripts/release_gate.dart --scope=host\n',
        '        # run: dart run scripts/release_gate.dart --scope=host\n',
      );
      expect(
        validate(input),
        contains(
          'audit workflow must invoke the repository-owned host release authority',
        ),
      );
    });

    test('rejects commented-out beta SDK verification commands', () {
      final input = currentInputs();
      input['future'] = input['future']!.replaceAll(
        '      - run: dart run scripts/dependency_compatibility.dart --mode=future-probe --verify-running-flutter-sdk',
        '      # - run: dart run scripts/dependency_compatibility.dart --mode=future-probe --verify-running-flutter-sdk',
      );

      expect(
        validate(input),
        contains(
          'future workflow must invoke SDK verification in each beta job',
        ),
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

    test('rejects a running Dart SDK version outside the Stable baseline', () {
      expect(
        validate(
          currentInputs(),
          runningFlutterMachineJson: _runningFlutterMachineJson.replaceFirst(
            '"dartSdkVersion": "3.12.2"',
            '"dartSdkVersion": "3.13.0"',
          ),
        ),
        contains('running Dart SDK must match the selected current identity'),
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

  test('CLI success summary is mode-aware', () {
    final baselineSummary = compatibility.successSummary(
      compatibility.DependencyCompatibilityMode.baseline,
    );
    final futureProbeSummary = compatibility.successSummary(
      compatibility.DependencyCompatibilityMode.futureProbe,
      betaIdentityParsed: true,
    );
    final nonBetaFutureProbeSummary = compatibility.successSummary(
      compatibility.DependencyCompatibilityMode.futureProbe,
    );

    expect(baselineSummary, contains('Flutter Stable identity'));
    expect(futureProbeSummary, contains('Flutter beta identity parsed'));
    expect(futureProbeSummary, contains('SQLCipher'));
    expect(futureProbeSummary, contains('iOS 15'));
    expect(futureProbeSummary, contains('Android minSdk >= 24'));
    expect(futureProbeSummary, isNot(contains('Stable identity')));
    expect(
      nonBetaFutureProbeSummary,
      contains('Flutter future-probe identity parsed'),
    );
    expect(nonBetaFutureProbeSummary, isNot(contains('beta identity parsed')));
  });

  test('future probe demotes only ordinary candidate drift', () {
    final baseline = File('docs/testing/STABLE_BASELINE.json')
        .readAsStringSync()
        .replaceFirst(
          '"resolved": "1.0.9", "candidate": "1.0.9"',
          '"resolved": "1.0.9", "candidate": "1.0.10"',
        );
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

  test('future probe keeps prerelease and EOL candidates blocking', () {
    final productionBaseline = File(
      'docs/testing/STABLE_BASELINE.json',
    ).readAsStringSync();
    final invalidCandidates = ['1.0.10-beta.1', '1.0.10+eol'];

    for (final candidate in invalidCandidates) {
      final probe = validateReport(
        currentInputs(),
        baselineJson: productionBaseline.replaceFirst(
          '"resolved": "1.0.9", "candidate": "1.0.9"',
          '"resolved": "1.0.9", "candidate": "$candidate"',
        ),
        mode: compatibility.DependencyCompatibilityMode.futureProbe,
      );

      expect(probe.errors, isNotEmpty);
      expect(
        probe.errors.map((issue) => issue.message),
        contains(
          'dependency cupertino_icons candidate must be production stable',
        ),
      );
      expect(probe.isPassing, isFalse);
    }
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

  test(
    'future probe reports expected beta SDK identity drift as a warning',
    () {
      final probe = validateReport(
        currentInputs(),
        baselineJson: File(
          'docs/testing/STABLE_BASELINE.json',
        ).readAsStringSync(),
        mode: compatibility.DependencyCompatibilityMode.futureProbe,
        runningFlutterMachineJson: _betaFlutterMachineJson,
      );

      expect(probe.errors, isEmpty);
      expect(
        probe.warnings.map((issue) => issue.message),
        contains(
          'running Flutter beta SDK differs from the selected Stable identity',
        ),
      );
    },
  );

  test('future probe rejects malformed beta SDK machine identities', () {
    const nonStringMachineJson = '''
{
  "flutterVersion": 1,
  "channel": "beta",
  "frameworkRevision": "aabbccddeeff00112233445566778899aabbccdd",
  "dartSdkVersion": false
}
''';
    final malformedMachineJsons = [
      nonStringMachineJson,
      _betaFlutterMachineJson.replaceFirst('3.45.0-0.1.pre', 'not-a-version'),
      _betaFlutterMachineJson.replaceFirst(
        'aabbccddeeff00112233445566778899aabbccdd',
        'not-a-revision',
      ),
    ];
    for (final machineJson in malformedMachineJsons) {
      final probe = validateReport(
        currentInputs(),
        baselineJson: File(
          'docs/testing/STABLE_BASELINE.json',
        ).readAsStringSync(),
        mode: compatibility.DependencyCompatibilityMode.futureProbe,
        runningFlutterMachineJson: machineJson,
      );

      expect(
        probe.errors.map((issue) => issue.message),
        contains(
          'running Flutter --version --machine output must contain well-formed string Flutter identity fields',
        ),
      );
      expect(probe.warnings, isEmpty);
    }
  });

  test('future probe keeps beta Android floor regression blocking', () {
    final probe = validateReport(
      currentInputs(),
      baselineJson: File(
        'docs/testing/STABLE_BASELINE.json',
      ).readAsStringSync(),
      mode: compatibility.DependencyCompatibilityMode.futureProbe,
      runningFlutterMachineJson: _betaFlutterMachineJson,
      extensionSource: 'val minSdkVersion: Int = 23',
    );

    expect(
      probe.errors.map((issue) => issue.message),
      contains(
        'FlutterExtension.kt minSdkVersion must match the manifest and be >= 24',
      ),
    );
  });

  group('CI workflow source contracts', () {
    const futureProbeCommand =
        'dart run scripts/dependency_compatibility.dart '
        '--mode=future-probe --verify-running-flutter-sdk';

    test(
      'Stable CI invokes the host release authority after the exact SDK pin',
      () {
        final audit = currentInputs()['audit']!;
        expect(audit, contains('flutter-version: 3.44.8'));
        expect(
          audit.indexOf('flutter-version: 3.44.8'),
          lessThan(
            audit.indexOf('dart run scripts/release_gate.dart --scope=host'),
          ),
        );
        expect(
          audit.indexOf('dart run scripts/release_gate.dart --scope=host'),
          lessThan(audit.indexOf('bash scripts/audit_layer.sh')),
        );
      },
    );

    test(
      'Stable CI routes post-generation lint and architecture gates through one authority',
      () {
        final audit = currentInputs()['audit']!;
        expect(_stableReleaseAuthorityViolations(audit), isEmpty);

        expect(
          _stableReleaseAuthorityViolations(
            audit.replaceFirst(
              'dart run scripts/release_gate.dart --scope=host',
              'flutter analyze --no-fatal-infos',
            ),
          ),
          isNotEmpty,
          reason: 'omitting the release authority must fail',
        );
        expect(
          _stableReleaseAuthorityViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              '# run: dart run scripts/release_gate.dart --scope=host',
            ),
          ),
          isNotEmpty,
          reason: 'comment-only authority presence must fail',
        );
        expect(
          _stableReleaseAuthorityViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              'run: dart run scripts/release_gate.dart --scope=host\n'
                  '      - run: dart run scripts/release_gate.dart --scope=host',
            ),
          ),
          isNotEmpty,
          reason: 'duplicate authority calls must fail',
        );
        expect(
          _stableReleaseAuthorityViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              'continue-on-error: true\n'
                  '        run: dart run scripts/release_gate.dart --scope=host || true',
            ),
          ),
          isNotEmpty,
          reason: 'soft-failed authority calls must fail',
        );
      },
    );

    test(
      'Stable CI keeps one authoritative release gate without host duplicates',
      () {
        final audit = currentInputs()['audit']!;
        expect(_stableWorkflowAuthorityUniquenessViolations(audit), isEmpty);

        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              '# run: dart run scripts/release_gate.dart --scope=host',
            ),
          ),
          isNotEmpty,
          reason: 'comment-only authority presence must fail',
        );
        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              'run: dart run scripts/release_gate.dart --scope=host\n'
                  '      - run: dart run scripts/release_gate.dart --scope=host',
            ),
          ),
          isNotEmpty,
          reason: 'duplicate authorities must fail',
        );
        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              'flutter pub get --enforce-lockfile',
              'flutter pub get',
            ),
          ),
          isNotEmpty,
          reason:
              'supplemental scanners cannot use unlocked dependency retrieval',
        );
        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              'flutter pub get --enforce-lockfile',
              'flutter pub get --enforce-lockfile\n'
                  '          flutter pub run build_runner build',
            ),
          ),
          isNotEmpty,
          reason: 'a duplicated host generator must fail',
        );
        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              'run: dart run scripts/release_gate.dart --scope=host',
              'continue-on-error: true\n'
                  '        run: dart run scripts/release_gate.dart --scope=host || true',
            ),
          ),
          isNotEmpty,
          reason: 'soft-failed authority calls must fail',
        );
      },
    );

    test(
      'supplemental scanners retrieve the reviewed graph and docs name the wrapper',
      () {
        final audit = currentInputs()['audit']!;
        final scanners = _workflowJobSource(audit, 'audit-scanners');
        expect(scanners, isNotNull);
        expect(scanners, contains('flutter pub get --enforce-lockfile'));
        expect(
          _stableWorkflowAuthorityUniquenessViolations(
            audit.replaceFirst(
              '      - run: flutter pub get --enforce-lockfile',
              '      - run: flutter pub get',
            ),
          ),
          isNotEmpty,
          reason:
              'ordinary supplemental retrieval must fail the Stable contract',
        );

        final guide = File(
          'docs/testing/DEPENDENCY_COMPATIBILITY.md',
        ).readAsStringSync();
        expect(
          guide,
          contains('bash scripts/verify_codegen_reproducibility.sh'),
        );
        expect(guide, contains('sole Stable static-analysis entry'));
        expect(guide, contains('locked resolution'));
        expect(guide, contains('two clean generation passes'));
      },
    );

    test(
      'both beta jobs are explicit future probes that keep their builds',
      () {
        final future = currentInputs()['future']!;
        expect(RegExp(r'channel: beta').allMatches(future), hasLength(2));
        expect(
          RegExp(
            r'^\s*-\s+run:\s+' + RegExp.escape(futureProbeCommand) + r'[ \t]*$',
            multiLine: true,
          ).allMatches(future),
          hasLength(2),
        );
        expect(future, contains('flutter build apk --debug'));
        expect(future, contains('flutter build ios --simulator --debug'));
        expect(future, isNot(contains('--mode=baseline')));
      },
    );
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

  group('PLUG-03 speech_to_text terminal decision contract', () {
    Map<String, dynamic> speechManifest() =>
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;

    Map<String, dynamic> speechRow(Map<String, dynamic> manifest) =>
        (manifest['direct_dependencies']
                as Map<String, dynamic>)['speech_to_text']
            as Map<String, dynamic>;

    test(
      'rejects every missing speech evidence field with a lane diagnostic',
      () {
        const fields = <String>[
          'queried_on',
          'candidate',
          'decision',
          'compatibility_reason',
          'exit_condition',
          'owner_phase',
        ];

        for (final field in fields) {
          final manifest = speechManifest();
          speechRow(manifest).remove(field);

          expect(
            validate(currentInputs(), baselineJson: jsonEncode(manifest)),
            contains(
              'PLUG-03 speech_to_text is missing required evidence field: $field',
            ),
            reason: field,
          );
        }
      },
    );

    test(
      'rejects declaration-only and lock-only speech drift before acceptance',
      () {
        final declarationInput = currentInputs();
        declarationInput['pubspec'] = declarationInput['pubspec']!.replaceFirst(
          'speech_to_text: 7.3.0',
          'speech_to_text: 7.4.0',
        );
        expect(
          validate(declarationInput),
          contains(
            'PLUG-03 speech_to_text declaration must remain 7.3.0 (found 7.4.0)',
          ),
        );

        final lockInput = currentInputs();
        lockInput['lock'] = lockInput['lock']!.replaceFirstMapped(
          RegExp(
            r'(^  speech_to_text:\n(?:^(?:    |      ).*\n)*?^    version: )"7\.3\.0"',
            multiLine: true,
          ),
          (match) => '${match.group(1)}"7.4.0"',
        );
        expect(
          validate(lockInput),
          contains(
            'PLUG-03 speech_to_text resolution must remain 7.3.0 (found 7.4.0)',
          ),
        );
      },
    );

    test('rejects a prerelease speech candidate', () {
      final manifest = speechManifest();
      speechRow(manifest)['candidate'] = '7.5.0-beta.1';

      expect(
        validate(currentInputs(), baselineJson: jsonEncode(manifest)),
        contains(
          'PLUG-03 speech_to_text candidate must be a production-stable release',
        ),
      );
    });

    test('rejects accepted speech when an iPhone evidence result is missing', () {
      final manifest = speechManifest();
      final speech = speechRow(manifest);
      speech['decision'] = 'accepted';
      final evidence = speech['acceptance_evidence'] as Map<String, dynamic>;
      evidence.remove('iphone_ja_recognition');

      expect(
        validate(currentInputs(), baselineJson: jsonEncode(manifest)),
        contains(
          'PLUG-03 speech_to_text accepted decision requires PASS iPhone evidence: iphone_ja_recognition',
        ),
      );
    });

    test(
      'rejects accepted speech when one trilingual locale evidence result fails',
      () {
        final manifest = speechManifest();
        final speech = speechRow(manifest);
        speech['decision'] = 'accepted';
        final evidence = speech['acceptance_evidence'] as Map<String, dynamic>;
        evidence['iphone_zh_recognition'] = 'FAILED';

        expect(
          validate(currentInputs(), baselineJson: jsonEncode(manifest)),
          contains(
            'PLUG-03 speech_to_text accepted decision requires PASS iPhone evidence: iphone_zh_recognition',
          ),
        );
      },
    );

    test('rejects accepted speech paired with the held declaration and lock', () {
      final manifest = speechManifest();
      final speech = speechRow(manifest);
      speech['decision'] = 'accepted';
      final evidence = speech['acceptance_evidence'] as Map<String, dynamic>;
      for (final field in evidence.keys.toList()) {
        evidence[field] = 'PASS';
      }

      expect(
        validate(currentInputs(), baselineJson: jsonEncode(manifest)),
        contains(
          'PLUG-03 speech_to_text accepted declaration must equal candidate 7.4.0 (found 7.3.0)',
        ),
      );
      expect(
        validate(currentInputs(), baselineJson: jsonEncode(manifest)),
        contains(
          'PLUG-03 speech_to_text accepted resolution must equal candidate 7.4.0 (found 7.3.0)',
        ),
      );
    });
  });

  group('PLUG-01/PLUG-02 complete platform plugin cohort contract', () {
    Map<String, dynamic> manifest() =>
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;

    test(
      'rejects missing Phase 59 inventory evidence with lane diagnostics',
      () {
        const packages = <String>[
          'flutter_secure_storage',
          'local_auth',
          'speech_to_text',
          'file_picker',
          'image_picker',
          'share_plus',
          'package_info_plus',
          'url_launcher',
          'path_provider',
          'connectivity_plus',
          'lucide_icons_flutter',
        ];
        const fields = <String>[
          'package',
          'queried_on',
          'candidate',
          'decision',
          'owner_phase',
        ];

        for (final package in packages) {
          for (final field in fields) {
            final source = manifest();
            final dependencies =
                source['direct_dependencies'] as Map<String, dynamic>;
            (dependencies[package] as Map<String, dynamic>).remove(field);

            expect(
              validate(currentInputs(), baselineJson: jsonEncode(source)),
              contains(
                'PLUG-01 $package is missing required evidence field: $field',
              ),
              reason: '$package $field',
            );
          }
        }
      },
    );

    test('rejects partial and malformed exact file/share cohort membership', () {
      final source = manifest();
      final lanes = source['lanes'] as Map<String, dynamic>;
      final cohort = lanes['phase59_file_share'] as Map<String, dynamic>;
      final members = cohort['members'] as List<dynamic>;

      for (var index = 0; index < members.length; index++) {
        final mutated = manifest();
        final lane =
            (mutated['lanes'] as Map<String, dynamic>)['phase59_file_share']
                as Map<String, dynamic>;
        (lane['members'] as List<dynamic>).removeAt(index);
        expect(
          validate(currentInputs(), baselineJson: jsonEncode(mutated)),
          contains(
            'PLUG-02 file/share cohort must contain exactly the four atomic members',
          ),
          reason: members[index],
        );
      }

      final duplicate = manifest();
      final duplicateMembers =
          ((duplicate['lanes'] as Map<String, dynamic>)['phase59_file_share']
                  as Map<String, dynamic>)['members']
              as List<dynamic>;
      duplicateMembers[1] = duplicateMembers.first;
      expect(
        validate(currentInputs(), baselineJson: jsonEncode(duplicate)),
        contains(
          'PLUG-02 file/share cohort must contain exactly the four atomic members',
        ),
      );

      final reordered = manifest();
      final reorderedMembers =
          ((reordered['lanes'] as Map<String, dynamic>)['phase59_file_share']
                  as Map<String, dynamic>)['members']
              as List<dynamic>;
      reorderedMembers.sort((left, right) => '$right'.compareTo('$left'));
      expect(
        validate(currentInputs(), baselineJson: jsonEncode(reordered)),
        contains('PLUG-01 Phase 59 plugin inventory must be in lexical order'),
      );
    });

    test('rejects declaration and lock drift for every atomic member', () {
      const declarations = <String, String>{
        'file_picker': '^11.0.3',
        'share_plus': '^12.0.2',
        'package_info_plus': '^9.0.1',
      };
      const locks = <String, String>{
        'file_picker': '11.0.3',
        'share_plus': '12.0.2',
        'package_info_plus': '9.0.1',
        'win32': '5.15.0',
      };

      for (final entry in declarations.entries) {
        final input = currentInputs();
        input['pubspec'] = input['pubspec']!.replaceFirst(
          '${entry.key}: ${entry.value}',
          '${entry.key}: ${entry.value}.drift',
        );
        expect(
          validate(input),
          contains(
            'PLUG-02 ${entry.key} declaration must remain ${entry.value} '
            '(found ${entry.value}.drift)',
          ),
          reason: entry.key,
        );
      }

      for (final entry in locks.entries) {
        final input = currentInputs();
        final matcher = RegExp(
          '(^  ${RegExp.escape(entry.key)}:\\n'
          r'(?:^(?:    |      ).*\n)*?^    version: )"'
          '${RegExp.escape(entry.value)}"',
          multiLine: true,
        );
        expect(matcher.hasMatch(input['lock']!), isTrue, reason: entry.key);
        input['lock'] = input['lock']!.replaceFirstMapped(
          matcher,
          (match) => '${match.group(1)}"${entry.value}.drift"',
        );
        expect(
          validate(input),
          contains(
            'PLUG-02 ${entry.key} resolution must remain ${entry.value} '
            '(found ${entry.value}.drift)',
          ),
          reason: entry.key,
        );
      }
    });

    test('names every partial atomic declaration and lock mutation', () {
      const declarations = <String, String>{
        'file_picker': '^11.0.3',
        'share_plus': '^12.0.2',
        'package_info_plus': '^9.0.1',
      };
      const locks = <String, String>{
        'file_picker': '11.0.3',
        'share_plus': '12.0.2',
        'package_info_plus': '9.0.1',
        'win32': '5.15.0',
      };

      for (final entry in declarations.entries) {
        final input = currentInputs();
        input['pubspec'] = input['pubspec']!.replaceFirst(
          '${entry.key}: ${entry.value}',
          '${entry.key}: ${entry.value}.partial',
        );
        expect(
          validate(input),
          contains('PLUG-02 atomic cohort declaration drift for ${entry.key}'),
        );
      }

      for (final entry in locks.entries) {
        final input = currentInputs();
        final matcher = RegExp(
          '(^  ${RegExp.escape(entry.key)}:\\n'
          r'(?:^(?:    |      ).*\n)*?^    version: )"'
          '${RegExp.escape(entry.value)}"',
          multiLine: true,
        );
        input['lock'] = input['lock']!.replaceFirstMapped(
          matcher,
          (match) => '${match.group(1)}"${entry.value}.partial"',
        );
        expect(
          validate(input),
          contains('PLUG-02 atomic cohort resolution drift for ${entry.key}'),
        );
      }
    });

    test('rejects every missing held atomic-cohort evidence field', () {
      const directMembers = <String>[
        'file_picker',
        'share_plus',
        'package_info_plus',
      ];
      const fields = <String>[
        'candidate',
        'official_source',
        'queried_on',
        'compatibility_reason',
        'exit_condition',
      ];

      for (final package in directMembers) {
        for (final field in fields) {
          final mutated = manifest();
          final dependencies =
              mutated['direct_dependencies'] as Map<String, dynamic>;
          (dependencies[package] as Map<String, dynamic>).remove(field);
          expect(
            validate(currentInputs(), baselineJson: jsonEncode(mutated)),
            contains(
              'PLUG-02 atomic cohort $package is missing hold evidence field: $field',
            ),
          );
        }
      }

      for (final field in fields) {
        final mutated = manifest();
        final lanes = mutated['lanes'] as Map<String, dynamic>;
        final transitives =
            lanes['phase59_native_transitives'] as Map<String, dynamic>;
        (transitives['win32'] as Map<String, dynamic>).remove(field);
        expect(
          validate(currentInputs(), baselineJson: jsonEncode(mutated)),
          contains(
            'PLUG-02 atomic cohort win32 is missing hold evidence field: $field',
          ),
        );
      }
    });
  });

  group('PLUG-04 MVP notification removal contract', () {
    Map<String, dynamic> manifest() =>
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;

    test('rejects a notification dependency restored to any graph', () {
      const packages = <String>[
        'firebase_core',
        'firebase_messaging',
        'flutter_local_notifications',
      ];
      for (final package in packages) {
        final source = manifest();
        (source['direct_dependencies'] as Map<String, dynamic>)[package] = {};
        expect(
          validate(currentInputs(), baselineJson: jsonEncode(source)),
          contains(
            'PLUG-04 MVP must not retain notification dependency $package',
          ),
          reason: package,
        );
      }
    });

    test('rejects an incomplete Phase 60 removal record', () {
      final source = manifest();
      final lane =
          (source['lanes']
                  as Map<String, dynamic>)['phase60_mvp_notification_removal']
              as Map<String, dynamic>;
      lane['native_registration_absent'] = false;

      expect(
        validate(currentInputs(), baselineJson: jsonEncode(source)),
        contains(
          'PLUG-04 notification removal must record the Phase 60 MVP supersession',
        ),
      );
    });
  });

  group('PLUG-04 biometric app-lock candidate contract', () {
    Map<String, dynamic> manifest() =>
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;

    Map<String, dynamic> localAuthRow(Map<String, dynamic> source) =>
        (source['direct_dependencies'] as Map<String, dynamic>)['local_auth']
            as Map<String, dynamic>;

    Map<String, dynamic> biometricLane(Map<String, dynamic> source) =>
        (source['lanes'] as Map<String, dynamic>)['phase59_biometric']
            as Map<String, dynamic>;

    test(
      'rejects missing local_auth source and terminal decision evidence',
      () {
        const fields = <String>[
          'official_source',
          'queried_on',
          'candidate',
          'decision',
          'compatibility_reason',
          'exit_condition',
          'acceptance_evidence',
        ];

        for (final field in fields) {
          final source = manifest();
          localAuthRow(source).remove(field);

          expect(
            validate(currentInputs(), baselineJson: jsonEncode(source)),
            contains(
              'PLUG-04 local_auth is missing biometric evidence field: $field',
            ),
            reason: field,
          );
        }
      },
    );

    test('rejects acceptance without Face ID and app-PIN fallback evidence', () {
      final source = manifest();
      final localAuth = localAuthRow(source);
      localAuth['decision'] = 'accepted';
      final evidence = localAuth['acceptance_evidence'] as Map<String, dynamic>;
      for (final field in evidence.keys.toList()) {
        evidence[field] = 'PASS';
      }
      evidence['face_id_success'] = 'UNAVAILABLE';
      evidence['app_pin_fallback'] = 'UNAVAILABLE';

      final diagnostics = validate(
        currentInputs(),
        baselineJson: jsonEncode(source),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 local_auth accepted decision requires PASS native evidence: face_id_success',
        ),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 local_auth accepted decision requires PASS native evidence: app_pin_fallback',
        ),
      );
    });

    test('rejects passcode policy and missing secure-option proof', () {
      final source = manifest();
      final policy = biometricLane(source);
      policy['biometric_only'] = false;
      policy.remove('sensitive_transaction');
      policy.remove('persist_across_backgrounding');

      final diagnostics = validate(
        currentInputs(),
        baselineJson: jsonEncode(source),
      );
      expect(
        diagnostics,
        contains('PLUG-04 biometric app lock must remain biometric-only'),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 biometric app lock is missing secure-option proof: sensitive_transaction',
        ),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 biometric app lock is missing secure-option proof: persist_across_backgrounding',
        ),
      );
    });

    test(
      'rejects missing residual exception and lockout PIN-fallback proof',
      () {
        final source = manifest();
        final localAuth = localAuthRow(source);
        final evidence =
            localAuth['acceptance_evidence'] as Map<String, dynamic>;
        evidence.remove('temporary_lockout_app_pin_fallback');
        evidence.remove('biometric_lockout_app_pin_fallback');
        evidence.remove('platform_exception_app_pin_fallback');
        evidence.remove('unknown_exception_app_pin_fallback');

        final diagnostics = validate(
          currentInputs(),
          baselineJson: jsonEncode(source),
        );
        for (final field in const <String>[
          'temporary_lockout_app_pin_fallback',
          'biometric_lockout_app_pin_fallback',
          'platform_exception_app_pin_fallback',
          'unknown_exception_app_pin_fallback',
        ]) {
          expect(
            diagnostics,
            contains(
              'PLUG-04 local_auth is missing app-PIN fallback evidence: $field',
            ),
            reason: field,
          );
        }
      },
    );

    test('rejects local_auth declaration and lock drift while held', () {
      final declarationInput = currentInputs();
      declarationInput['pubspec'] = declarationInput['pubspec']!.replaceFirst(
        'local_auth: ^3.0.2',
        'local_auth: ^3.0.3',
      );
      expect(
        validate(declarationInput),
        contains(
          'PLUG-04 local_auth declaration must remain ^3.0.2 (found ^3.0.3)',
        ),
      );

      final lockInput = currentInputs();
      lockInput['lock'] = lockInput['lock']!.replaceFirstMapped(
        RegExp(
          r'(^  local_auth:\n(?:^(?:    |      ).*\n)*?^    version: )"3\.0\.2"',
          multiLine: true,
        ),
        (match) => '${match.group(1)}"3.0.3"',
      );
      expect(
        validate(lockInput),
        contains(
          'PLUG-04 local_auth resolution must remain 3.0.2 (found 3.0.3)',
        ),
      );
    });
  });

  group('PLUG-04 secure storage persisted-key hold contract', () {
    Map<String, dynamic> manifest() =>
        jsonDecode(File('docs/testing/STABLE_BASELINE.json').readAsStringSync())
            as Map<String, dynamic>;

    Map<String, dynamic> secureStorageRow(Map<String, dynamic> source) =>
        (source['direct_dependencies']
                as Map<String, dynamic>)['flutter_secure_storage']
            as Map<String, dynamic>;

    Map<String, dynamic> secureStorageLane(Map<String, dynamic> source) =>
        (source['lanes'] as Map<String, dynamic>)['phase59_secure_storage']
            as Map<String, dynamic>;

    test('rejects incomplete secure-storage major acceptance evidence', () {
      final source = manifest();
      final row = secureStorageRow(source);
      row['decision'] = 'accepted';
      row['migration_design'] = 'none';
      row['acceptance_evidence'] = <String, dynamic>{
        'existing_key_read': 'UNAVAILABLE',
        'existing_database_startup': 'UNAVAILABLE',
      };

      final diagnostics = validate(
        currentInputs(),
        baselineJson: jsonEncode(source),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 flutter_secure_storage accepted decision requires a read-then-rewrite migration design',
        ),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 flutter_secure_storage accepted decision requires PASS persisted-key evidence: existing_key_read',
        ),
      );
      expect(
        diagnostics,
        contains(
          'PLUG-04 flutter_secure_storage accepted decision requires PASS persisted-key evidence: existing_database_startup',
        ),
      );
    });

    test('rejects an accessibility change and selected declaration/lock drift', () {
      final source = manifest();
      secureStorageLane(source)['keychain_accessibility'] = 'first_unlock';
      expect(
        validate(currentInputs(), baselineJson: jsonEncode(source)),
        contains(
          'PLUG-04 flutter_secure_storage must retain unlocked_this_device Keychain accessibility',
        ),
      );

      final declarationInput = currentInputs();
      declarationInput['pubspec'] = declarationInput['pubspec']!.replaceFirst(
        'flutter_secure_storage: ^10.3.1',
        'flutter_secure_storage: ^11.0.0',
      );
      expect(
        validate(declarationInput),
        contains(
          'PLUG-04 flutter_secure_storage declaration must remain ^10.3.1 (found ^11.0.0)',
        ),
      );

      final lockInput = currentInputs();
      lockInput['lock'] = lockInput['lock']!.replaceFirstMapped(
        RegExp(
          r'(^  flutter_secure_storage:\n(?:^(?:    |      ).*\n)*?^    version: )"10\.3\.1"',
          multiLine: true,
        ),
        (match) => '${match.group(1)}"11.0.0"',
      );
      expect(
        validate(lockInput),
        contains(
          'PLUG-04 flutter_secure_storage resolution must remain 10.3.1 (found 11.0.0)',
        ),
      );
    });
  });

  group('Phase 59 final artifact convergence contract', () {
    String baseline() =>
        File('docs/testing/STABLE_BASELINE.json').readAsStringSync();
    String compatibilityDocument() =>
        File('docs/testing/DEPENDENCY_COMPATIBILITY.md').readAsStringSync();
    String acceptanceLedger() =>
        File('docs/testing/PLATFORM_PLUGIN_ACCEPTANCE.md').readAsStringSync();
    String coverageMatrix() =>
        File('docs/testing/PLATFORM_PLUGIN_COVERAGE.md').readAsStringSync();

    List<String> validateArtifacts({
      String? baselineJson,
      String? document,
      String? ledger,
      String? coverage,
    }) => compatibility
        .validatePhase59EvidenceArtifacts(
          baselineJson: baselineJson ?? baseline(),
          compatibilityDocument: document ?? compatibilityDocument(),
          acceptanceLedger: ledger ?? acceptanceLedger(),
          coverageMatrix: coverage ?? coverageMatrix(),
        )
        .messages;

    test('accepts the exact final selected and held graph', () {
      expect(validateArtifacts(), isEmpty);
    });

    test('rejects readable-document, ledger-result, and API-matrix mutations', () {
      final document = compatibilityDocument().replaceFirst(
        '`speech_to_text 7.4.0`',
        '`speech_to_text 7.5.0`',
      );
      expect(
        validateArtifacts(document: document),
        contains(
          'PLUG-03 readable compatibility document must retain speech_to_text candidate 7.4.0',
        ),
      );

      final ledger = acceptanceLedger().replaceFirst(
        '| 2026-08-09 | speech_to_text | 7.3.0 declared/resolved |',
        '| 2026-08-09 | speech_to_text | 7.4.0 declared/resolved |',
      );
      expect(
        validateArtifacts(ledger: ledger),
        contains(
          'PLUG-03 acceptance ledger must retain speech_to_text selected 7.3.0',
        ),
      );

      final coverage = coverageMatrix().replaceFirst(
        '| speech_to_text.ja_recognition | INTEGRATE | |',
        '| speech_to_text.ja_recognition | OPT-OUT | mutation |',
      );
      expect(
        validateArtifacts(coverage: coverage),
        contains(
          'PLUG-03 API coverage must integrate speech_to_text.ja_recognition',
        ),
      );
    });
  });
}
