import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

enum DependencyCompatibilityMode { baseline, futureProbe }

enum CompatibilitySeverity { error, warning }

class CompatibilityIssue {
  const CompatibilityIssue({
    required this.code,
    required this.severity,
    required this.message,
  });

  final String code;
  final CompatibilitySeverity severity;
  final String message;
}

class CompatibilityReport {
  CompatibilityReport(Iterable<CompatibilityIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<CompatibilityIssue> issues;

  Iterable<CompatibilityIssue> get errors =>
      issues.where((issue) => issue.severity == CompatibilitySeverity.error);
  Iterable<CompatibilityIssue> get warnings =>
      issues.where((issue) => issue.severity == CompatibilitySeverity.warning);
  List<String> get messages =>
      List.unmodifiable(issues.map((issue) => issue.message));
  bool get isPassing => errors.isEmpty;
}

DependencyCompatibilityMode parseDependencyCompatibilityMode(
  List<String> arguments,
) {
  var mode = DependencyCompatibilityMode.baseline;
  var sawMode = false;
  var sawVerification = false;
  for (final argument in arguments) {
    switch (argument) {
      case '--mode=baseline':
        if (sawMode) throw ArgumentError('mode supplied more than once');
        mode = DependencyCompatibilityMode.baseline;
        sawMode = true;
        break;
      case '--mode=future-probe':
        if (sawMode) throw ArgumentError('mode supplied more than once');
        mode = DependencyCompatibilityMode.futureProbe;
        sawMode = true;
        break;
      case '--verify-running-flutter-sdk':
        if (sawVerification) {
          throw ArgumentError('SDK verification supplied more than once');
        }
        sawVerification = true;
        break;
      default:
        throw ArgumentError('unknown argument: $argument');
    }
  }
  return mode;
}

String successSummary(
  DependencyCompatibilityMode mode, {
  bool betaIdentityParsed = false,
}) => switch (mode) {
  DependencyCompatibilityMode.baseline =>
    'Flutter Stable identity and effective Android minSdk >= 24 verified',
  DependencyCompatibilityMode.futureProbe =>
    '${betaIdentityParsed ? 'Flutter beta identity parsed' : 'Flutter future-probe identity parsed'}; SQLCipher, iOS 15, and Android minSdk >= 24 invariants verified',
};

/// Parsed, versioned policy for the reviewed production-stable baseline.
///
/// The parser deliberately accumulates diagnostics so a malformed policy cannot
/// hide a second missing control behind its first error.
class StableBaselineManifest {
  StableBaselineManifest._(this.data, this.diagnostics);

  final Map<String, Object?> data;
  final List<String> diagnostics;

  factory StableBaselineManifest.parse(String baselineJson) {
    final diagnostics = <String>[];
    Map<String, Object?> data = const {};
    try {
      final decoded = jsonDecode(baselineJson);
      if (decoded is! Map) {
        diagnostics.add('baseline manifest root must be a JSON object');
      } else {
        data = decoded.cast<String, Object?>();
      }
    } on FormatException catch (error) {
      diagnostics.add('baseline manifest is invalid JSON: ${error.message}');
    }

    const requiredTopLevel = {
      'schema_version',
      'queried_on',
      'official_source_policy',
      'platform_floors',
      'toolchains',
      'direct_dependencies',
      'lanes',
      'holds',
      'prohibitions',
      'tracked_inputs',
    };
    final unexpected = data.keys.where(
      (key) => !requiredTopLevel.contains(key),
    );
    for (final key in unexpected) {
      diagnostics.add('baseline manifest has unexpected key: $key');
    }
    for (final key in requiredTopLevel) {
      if (!data.containsKey(key)) {
        diagnostics.add('baseline manifest is missing required key: $key');
      }
    }
    if (data['schema_version'] != 1) {
      diagnostics.add('baseline manifest schema_version must be 1');
    }
    if (!_isIsoDate(data['queried_on'])) {
      diagnostics.add('baseline manifest queried_on must be an ISO date');
    }

    final toolchains = _map(data['toolchains']);
    const toolchainIds = {
      'flutter',
      'dart',
      'xcode',
      'cocoapods',
      'jdk',
      'gradle',
      'agp',
      'android_sdk',
    };
    for (final id in toolchainIds) {
      final row = _map(toolchains[id]);
      for (final field in {
        'selected_current',
        'production_stable_candidate',
        'decision',
        'owner_phase',
        'official_source',
        'queried_on',
      }) {
        if (_isBlank(row[field])) {
          diagnostics.add('toolchain $id is missing required field: $field');
        }
      }
      if (!_isIsoDate(row['queried_on'])) {
        diagnostics.add('toolchain $id queried_on must be an ISO date');
      }
      if (row['decision'] == 'hold') {
        for (final field in {'compatibility_reason', 'exit_condition'}) {
          if (_isBlank(row[field])) {
            diagnostics.add(
              'toolchain $id hold is missing required field: $field',
            );
          }
        }
      }
    }
    final flutter = _map(toolchains['flutter']);
    for (final field in {'framework_revision', 'channel'}) {
      if (_isBlank(flutter[field])) {
        diagnostics.add('Flutter toolchain is missing required field: $field');
      }
    }
    if (_map(flutter['flutter_extension_defaults'])['min_sdk'] != 24) {
      diagnostics.add(
        'Flutter toolchain must declare an Android min_sdk of 24',
      );
    }

    final dependencies = _map(data['direct_dependencies']);
    if (dependencies.isEmpty) {
      diagnostics.add('baseline manifest must inventory direct dependencies');
    }
    for (final entry in dependencies.entries) {
      final row = _map(entry.value);
      for (final field in {
        'kind',
        'declared',
        'resolved',
        'candidate',
        'decision',
        'owner_phase',
        'official_source',
        'queried_on',
      }) {
        if (_isBlank(row[field])) {
          diagnostics.add(
            'dependency ${entry.key} is missing required field: $field',
          );
        }
      }
      if (!_isIsoDate(row['queried_on'])) {
        diagnostics.add(
          'dependency ${entry.key} queried_on must be an ISO date',
        );
      }
      if (row['decision'] == 'hold') {
        for (final field in {'compatibility_reason', 'exit_condition'}) {
          if (_isBlank(row[field])) {
            diagnostics.add(
              'dependency ${entry.key} hold is missing required field: $field',
            );
          }
        }
      }
    }

    for (final entry in _map(data['holds']).entries) {
      final hold = _map(entry.value);
      for (final field in {
        'selected_value',
        'candidate',
        'official_source',
        'queried_on',
        'compatibility_reason',
        'exit_condition',
        'owner_phase',
      }) {
        if (_isBlank(hold[field])) {
          diagnostics.add(
            '${entry.key} hold is missing required field: $field',
          );
        }
      }
    }

    return StableBaselineManifest._(data, diagnostics);
  }
}

CompatibilityReport validateDependencyCompatibility({
  required String pubspecYaml,
  required String lockYaml,
  required String androidSettings,
  required String androidAppBuild,
  required String androidProperties,
  required String gradleWrapper,
  required String podfile,
  required String podfileLock,
  required String xcodeProject,
  required String auditWorkflow,
  required String futureWorkflow,
  required String baselineJson,
  required String metadataYaml,
  required String flutterExtensionSource,
  required String runningFlutterMachineJson,
  required bool pubspecOverridesPresent,
  required Map<String, String> trackedInputContents,
  DependencyCompatibilityMode mode = DependencyCompatibilityMode.baseline,
}) {
  final issues = <String>[];
  final baseline = StableBaselineManifest.parse(baselineJson);
  issues.addAll(baseline.diagnostics);
  final pubspec = _map(loadYaml(pubspecYaml));
  final dependencies = _map(pubspec['dependencies']);
  final devDependencies = _map(pubspec['dev_dependencies']);
  final allDirectDependencies = <Object?, Object?>{
    ...dependencies,
    ...devDependencies,
  };
  final lock = _map(loadYaml(lockYaml));
  final packages = _map(lock['packages']);
  final baselineDependencies = _map(baseline.data['direct_dependencies']);
  final toolchains = _map(baseline.data['toolchains']);
  final flutterToolchain = _map(toolchains['flutter']);
  final dartToolchain = _map(toolchains['dart']);

  _validateManifestPolicy(issues: issues, baseline: baseline.data);

  void expectConstraint(String package, String expected) {
    final actual = allDirectDependencies[package]?.toString();
    if (actual != expected) {
      issues.add('$package constraint must be $expected (found $actual)');
    }
  }

  void expectLocked(String package, String expected) {
    final actual = _map(packages[package])['version']?.toString();
    if (actual != expected) {
      issues.add('$package lock must be $expected (found $actual)');
    }
  }

  void expectSdkConstraint(String expected) {
    final actual = _map(pubspec['environment'])['sdk']?.toString();
    if (actual != expected) {
      issues.add(
        'environment.sdk constraint must be $expected (found $actual)',
      );
    }
  }

  void expectText(String label, String contents, String marker) {
    if (!contents.contains(marker)) {
      issues.add('$label must contain: $marker');
    }
  }

  final actualDependencyKeys = allDirectDependencies.keys
      .map((key) => key.toString())
      .toSet();
  final manifestDependencyKeys = baselineDependencies.keys
      .map((key) => key.toString())
      .toSet();
  for (final package in actualDependencyKeys.difference(
    manifestDependencyKeys,
  )) {
    issues.add('baseline is missing direct dependency: $package');
  }
  for (final package in manifestDependencyKeys.difference(
    actualDependencyKeys,
  )) {
    issues.add('baseline declares non-direct dependency: $package');
  }
  for (final package in actualDependencyKeys.intersection(
    manifestDependencyKeys,
  )) {
    final row = _map(baselineDependencies[package]);
    final declared = _declaredDependency(allDirectDependencies[package]);
    final resolved = _map(packages[package])['version']?.toString();
    if (row['declared']?.toString() != declared) {
      issues.add('$package baseline declared constraint must be $declared');
    }
    if (row['resolved']?.toString() != resolved) {
      issues.add('$package baseline resolved version must be $resolved');
    }
  }

  // Security lane: sqlite3 3.x builds SQLCipher as a Dart Native Asset. The
  // legacy Flutter library packages must not re-enter the resolved graph.
  expectConstraint('drift', '2.34.0');
  expectLocked('drift', '2.34.0');
  expectConstraint('sqlite3', '^3.3.1');
  expectLocked('sqlite3', '3.5.1');
  expectConstraint('drift_dev', '2.34.0');
  expectLocked('drift_dev', '2.34.0');
  if (dependencies.containsKey('sqlcipher_flutter_libs') ||
      packages.containsKey('sqlcipher_flutter_libs')) {
    issues.add(
      'sqlcipher_flutter_libs is obsolete on the sqlite3 Native Assets path',
    );
  }
  if (dependencies.containsKey('sqlite3_flutter_libs') ||
      packages.containsKey('sqlite3_flutter_libs')) {
    issues.add(
      'sqlite3_flutter_libs conflicts with SQLCipher and is forbidden',
    );
  }
  if (!RegExp(
    r'^hooks:\s*\n\s+user_defines:\s*\n\s+sqlite3:\s*\n\s+source:\s*sqlcipher\s*$',
    multiLine: true,
  ).hasMatch(pubspecYaml)) {
    issues.add(
      'pubspec must select SQLCipher through hooks.user_defines.sqlite3.source',
    );
  }

  expectConstraint('file_picker', '^11.0.3');
  expectLocked('file_picker', '11.0.3');
  expectConstraint('share_plus', '^12.0.2');
  expectLocked('share_plus', '12.0.2');
  expectConstraint('package_info_plus', '^9.0.1');
  expectLocked('package_info_plus', '9.0.1');
  expectLocked('win32', '5.15.0');
  expectConstraint('flutter_local_notifications', '^22.2.0');
  expectLocked('flutter_local_notifications', '22.2.0');
  _validatePhase59PluginCohorts(
    issues: issues,
    baselineDependencies: baselineDependencies,
    baselineLanes: _map(baseline.data['lanes']),
    directDependencies: allDirectDependencies,
    lockedPackages: packages,
  );
  // The analyzer/plugin/generator cohort is a single solver-produced graph.
  // Moving any member alone can silently invalidate code generation or the
  // active architecture plugins, so both the declarations and lock selections
  // intentionally fail closed on every reviewed member.
  expectSdkConstraint('^3.12.2');

  expectConstraint('flutter_riverpod', '3.3.2');
  expectLocked('flutter_riverpod', '3.3.2');
  expectLocked('riverpod', '3.3.2');
  expectConstraint('riverpod_annotation', '4.0.3');
  expectLocked('riverpod_annotation', '4.0.3');
  expectConstraint('riverpod_generator', '4.0.4');
  expectLocked('riverpod_generator', '4.0.4');
  expectConstraint('riverpod_lint', '3.1.4');
  expectLocked('riverpod_lint', '3.1.4');

  expectConstraint('freezed_annotation', '^3.0.0');
  expectLocked('freezed_annotation', '3.1.0');
  expectConstraint('freezed', '3.2.6-dev.1');
  expectLocked('freezed', '3.2.6-dev.1');
  expectConstraint('json_annotation', '^4.12.0');
  expectLocked('json_annotation', '4.12.0');
  expectConstraint('json_serializable', '^6.9.4');
  expectLocked('json_serializable', '6.14.1');

  expectConstraint('drift', '2.34.0');
  expectLocked('drift', '2.34.0');
  expectConstraint('drift_dev', '2.34.0');
  expectLocked('drift_dev', '2.34.0');
  expectConstraint('build_runner', '^2.4.14');
  expectLocked('build_runner', '2.15.1');
  expectLocked('build', '4.0.7');
  expectLocked('source_gen', '4.2.4');
  expectConstraint('import_lint', '^2.0.0');
  expectLocked('import_lint', '2.0.0');
  expectConstraint('dart_code_linter', '^4.1.9');
  expectLocked('dart_code_linter', '4.1.9');
  expectLocked('analyzer', '12.1.0');
  expectLocked('analyzer_plugin', '0.14.8');

  for (final obsoletePackage in {
    'custom_lint',
    'custom_lint_builder',
    'import_guard_custom_lint',
  }) {
    if (allDirectDependencies.containsKey(obsoletePackage) ||
        packages.containsKey(obsoletePackage)) {
      issues.add(
        '$obsoletePackage must stay absent from the active analyzer 12 graph',
      );
    }
  }

  expectText(
    'android/gradle.properties',
    androidProperties,
    'android.builtInKotlin=false',
  );
  expectText(
    'android/gradle.properties',
    androidProperties,
    'android.newDsl=false',
  );
  expectText(
    'android/settings.gradle.kts',
    androidSettings,
    'id("com.android.application") version "8.11.1"',
  );
  expectText(
    'android/settings.gradle.kts',
    androidSettings,
    'id("org.jetbrains.kotlin.android") version "2.2.20"',
  );
  expectText(
    'android/app/build.gradle.kts',
    androidAppBuild,
    'id("kotlin-android")',
  );
  expectText('Gradle wrapper', gradleWrapper, 'gradle-8.14-all.zip');
  if (pubspecYaml.contains('enable-swift-package-manager: false')) {
    issues.add('Swift Package Manager must stay enabled for supported plugins');
  }
  expectText(
    'Xcode project',
    xcodeProject,
    'FlutterGeneratedPluginSwiftPackage',
  );
  if (podfileLock.contains('SQLCipher') ||
      podfileLock.contains('sqlcipher_flutter_libs')) {
    issues.add(
      'ios/Podfile.lock must not retain the legacy SQLCipher CocoaPod path',
    );
  }
  if (_hasActiveSqlCipherLinkerStrip(podfile)) {
    issues.add('ios/Podfile must not retain the obsolete sqlite3 linker strip');
  }
  _validateIosDeploymentTargets(
    issues: issues,
    podfile: podfile,
    xcodeProject: xcodeProject,
  );
  if (pubspecOverridesPresent) {
    issues.add('pubspec_overrides.yaml must not be present');
  }
  if (_map(pubspec['dependency_overrides']).isNotEmpty ||
      pubspecYaml.contains('dependency_overrides:')) {
    issues.add('pubspec dependency_overrides must not be present');
  }
  if (!androidAppBuild.contains('minSdk = flutter.minSdkVersion')) {
    issues.add('Android minSdk must inherit flutter.minSdkVersion');
  }

  _validateTrackedInputs(
    issues: issues,
    manifestInputs: _map(baseline.data['tracked_inputs']),
    actualContents: trackedInputContents,
  );
  _validateFlutterIdentity(
    issues: issues,
    flutterToolchain: flutterToolchain,
    dartToolchain: dartToolchain,
    metadataYaml: metadataYaml,
    machineJson: runningFlutterMachineJson,
    auditWorkflow: auditWorkflow,
    flutterExtensionSource: flutterExtensionSource,
    mode: mode,
  );

  final hasStableSdkVerificationCommand = RegExp(
    r'^\s*run:\s+bash scripts/verify_codegen_reproducibility\.sh[ \t]*$',
    multiLine: true,
  ).hasMatch(_withoutYamlComments(auditWorkflow));
  if (!hasStableSdkVerificationCommand) {
    issues.add(
      'audit workflow must invoke SDK verification through the authoritative wrapper',
    );
  }
  expectText('future workflow', futureWorkflow, 'channel: beta');
  expectText('future workflow', futureWorkflow, 'flutter build apk --debug');
  expectText(
    'future workflow',
    futureWorkflow,
    'flutter build ios --simulator --debug',
  );
  final futureProbeSdkValidator = RegExp(
    r'^\s*-\s+run:\s+dart run scripts/dependency_compatibility\.dart --mode=future-probe --verify-running-flutter-sdk[ \t]*$',
    multiLine: true,
  );
  const betaJobs = ['android-beta', 'ios-beta'];
  if (futureProbeSdkValidator.allMatches(futureWorkflow).length != 2 ||
      betaJobs.any(
        (job) =>
            futureProbeSdkValidator
                .allMatches(_workflowJobBody(futureWorkflow, job))
                .length !=
            1,
      )) {
    issues.add('future workflow must invoke SDK verification in each beta job');
  }
  return _reportFromMessages(issues, mode);
}

String _workflowJobBody(String workflow, String job) {
  final headers = RegExp(
    r'^  ([A-Za-z0-9_-]+):\s*$',
    multiLine: true,
  ).allMatches(workflow).toList();
  final index = headers.indexWhere((header) => header.group(1) == job);
  if (index == -1) return '';
  final end = index + 1 < headers.length
      ? headers[index + 1].start
      : workflow.length;
  return workflow.substring(headers[index].end, end);
}

String _withoutYamlComments(String source) =>
    source.replaceAll(RegExp(r'^[ \t]*#.*(?:\r?\n|$)', multiLine: true), '');

bool _hasActiveSqlCipherLinkerStrip(String podfile) => RegExp(
  r'''installer\.pods_project\.targets\.each do \|target\|[\s\S]*?target\.build_configurations\.each do \|config\|[\s\S]*?^\s*stripped\s*=\s*original\.gsub\(/\\s-l"\?sqlite3"\?/,\s*''\)\s*$[\s\S]*?^\s*File\.write\(xcconfig_path,\s*stripped\)\s+if\s+stripped\s+!=\s+original\s*$''',
  multiLine: true,
).hasMatch(_withoutRubyComments(podfile));

String _withoutRubyComments(String source) {
  final withoutBlockComments = source.replaceAll(
    RegExp(
      r'^[ \t]*=begin[ \t]*(?:\r?\n|$)[\s\S]*?^[ \t]*=end[ \t]*(?:\r?\n|$)',
      multiLine: true,
    ),
    '',
  );
  return withoutBlockComments.replaceAll(
    RegExp(r'^[ \t]*#.*(?:\r?\n|$)', multiLine: true),
    '',
  );
}

void _validateIosDeploymentTargets({
  required List<String> issues,
  required String podfile,
  required String xcodeProject,
}) {
  final podfileVersion = RegExp(
    r'''^\s*platform\s+:ios\s*,\s*['"]([^'"]+)['"]''',
    multiLine: true,
  ).firstMatch(podfile)?.group(1);
  if (!_isAtLeastIos15(podfileVersion)) {
    issues.add('ios/Podfile platform must declare iOS 15.0 or later');
  }

  final xcodeVersions = RegExp(
    r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;]+);',
  ).allMatches(xcodeProject).map((match) => match.group(1)?.trim());
  if (xcodeVersions.isEmpty ||
      xcodeVersions.any((value) => !_isAtLeastIos15(value))) {
    issues.add(
      'every Xcode IPHONEOS_DEPLOYMENT_TARGET must be iOS 15.0 or later',
    );
  }
}

bool _isAtLeastIos15(String? version) =>
    version != null &&
    RegExp(r'^\d+(?:\.\d+){0,2}$').hasMatch(version) &&
    _compareVersion(version, '15.0') >= 0;

CompatibilityReport _reportFromMessages(
  Iterable<String> messages,
  DependencyCompatibilityMode mode,
) => CompatibilityReport(
  messages.map(
    (message) => CompatibilityIssue(
      code: _diagnosticCode(message),
      severity: _severityFor(message, mode),
      message: message,
    ),
  ),
);

CompatibilitySeverity _severityFor(
  String message,
  DependencyCompatibilityMode mode,
) {
  if (mode == DependencyCompatibilityMode.futureProbe &&
      (RegExp(
            r'^dependency [^ ]+ selected value must not be lower than its candidate$',
          ).hasMatch(message) ||
          message ==
              'running Flutter beta SDK differs from the selected Stable identity')) {
    return CompatibilitySeverity.warning;
  }
  return CompatibilitySeverity.error;
}

String _diagnosticCode(String message) {
  if (message.contains('override')) return 'OVERRIDE_FORBIDDEN';
  if (message.contains('sqlite3_flutter_libs')) return 'PLAINTEXT_SQLITE';
  if (message.contains('SQLCipher') || message.contains('sqlcipher')) {
    return 'SQLCIPHER_INVARIANT';
  }
  if (message.contains('minSdk') || message.contains('support floor')) {
    return 'PLATFORM_FLOOR';
  }
  if (message.contains('candidate')) return 'CANDIDATE_DRIFT';
  if (message.contains('lane')) return 'PARTIAL_LANE';
  if (message.contains('digest')) return 'TRACKED_INPUT_DRIFT';
  return 'BASELINE_CONTRACT';
}

const _phase59AtomicFileShareMembers = <String>[
  'file_picker',
  'package_info_plus',
  'share_plus',
  'win32',
];

/// Validates the Phase 59 speech hold before a package resolver can turn an
/// execution-date candidate into an accepted graph. The explicit lane messages
/// keep evidence failures attributable instead of relying on generic manifest
/// diagnostics.
void _validatePhase59PluginCohorts({
  required List<String> issues,
  required Map<Object?, Object?> baselineDependencies,
  required Map<Object?, Object?> baselineLanes,
  required Map<Object?, Object?> directDependencies,
  required Map<Object?, Object?> lockedPackages,
}) {
  const phase59PluginPackages = <String>[
    'connectivity_plus',
    'file_picker',
    'firebase_core',
    'firebase_messaging',
    'flutter_local_notifications',
    'flutter_secure_storage',
    'image_picker',
    'local_auth',
    'lucide_icons_flutter',
    'package_info_plus',
    'path_provider',
    'share_plus',
    'speech_to_text',
    'url_launcher',
  ];
  const requiredPluginEvidence = <String>{
    'package',
    'queried_on',
    'candidate',
    'decision',
    'owner_phase',
    'official_source',
  };
  final pluginRows = <String, Map<Object?, Object?>>{};
  for (final package in phase59PluginPackages) {
    final row = _map(baselineDependencies[package]);
    pluginRows[package] = row;
    for (final field in requiredPluginEvidence) {
      if (_isBlank(row[field])) {
        issues.add(
          'PLUG-01 $package is missing required evidence field: $field',
        );
      }
    }
    if (row['package']?.toString() != package) {
      issues.add(
        'PLUG-01 $package package identity must match its manifest key',
      );
    }
    if (row['owner_phase'] != 59) {
      issues.add('PLUG-01 $package owner phase must be 59');
    }
  }
  final identities = pluginRows.values
      .map((row) => row['package']?.toString())
      .whereType<String>()
      .toList();
  if (identities.toSet().length != identities.length) {
    issues.add(
      'PLUG-01 Phase 59 plugin inventory has duplicate package identities',
    );
  }

  final inventoryMembers = _listOfStrings(
    _map(baselineLanes['phase59_plugin_inventory'])['members'],
  );
  if (!_hasExactMembers(inventoryMembers, phase59PluginPackages)) {
    issues.add(
      'PLUG-01 Phase 59 plugin inventory must contain every decided plugin exactly once',
    );
  }
  if (!_isLexicallyOrdered(inventoryMembers)) {
    issues.add('PLUG-01 Phase 59 plugin inventory must be in lexical order');
  }

  final fileShareLane = _map(baselineLanes['phase59_file_share']);
  final atomicMembers = _listOfStrings(fileShareLane['members']);
  if (!_hasExactMembers(atomicMembers, _phase59AtomicFileShareMembers)) {
    issues.add(
      'PLUG-02 file/share cohort must contain exactly the four atomic members',
    );
  }
  if (!_isLexicallyOrdered(atomicMembers)) {
    issues.add('PLUG-01 Phase 59 plugin inventory must be in lexical order');
  }
  for (final field in {
    'decision',
    'queried_on',
    'native_prerequisite_result',
    'compatibility_reason',
    'exit_condition',
  }) {
    if (_isBlank(fileShareLane[field])) {
      issues.add(
        'PLUG-02 atomic cohort is missing hold evidence field: $field',
      );
    }
  }
  if (fileShareLane['decision']?.toString() != 'hold') {
    issues.add(
      'PLUG-02 atomic cohort must remain hold until the full native exit condition is met',
    );
  }

  const atomicHoldEvidence = <String>{
    'candidate',
    'official_source',
    'queried_on',
    'compatibility_reason',
    'exit_condition',
  };
  for (final package in const <String>[
    'file_picker',
    'package_info_plus',
    'share_plus',
  ]) {
    final row = pluginRows[package]!;
    for (final field in atomicHoldEvidence) {
      if (_isBlank(row[field])) {
        issues.add(
          'PLUG-02 atomic cohort $package is missing hold evidence field: $field',
        );
      }
    }
    if (row['decision']?.toString() != 'hold') {
      issues.add(
        'PLUG-02 atomic cohort $package must remain hold until the full native exit condition is met',
      );
    }
  }

  final win32 = _map(
    _map(baselineLanes['phase59_native_transitives'])['win32'],
  );
  for (final field in {
    'package',
    'selected',
    'candidate',
    'decision',
    'owner_phase',
    'official_source',
    'queried_on',
    'compatibility_reason',
    'exit_condition',
  }) {
    if (_isBlank(win32[field])) {
      issues.add('PLUG-01 win32 is missing required evidence field: $field');
    }
  }
  for (final field in atomicHoldEvidence) {
    if (_isBlank(win32[field])) {
      issues.add(
        'PLUG-02 atomic cohort win32 is missing hold evidence field: $field',
      );
    }
  }
  if (win32['package']?.toString() != 'win32') {
    issues.add('PLUG-01 win32 package identity must match its manifest key');
  }
  if (win32['owner_phase'] != 59) {
    issues.add('PLUG-01 win32 owner phase must be 59');
  }
  if (win32['decision']?.toString() != 'hold') {
    issues.add(
      'PLUG-02 atomic cohort win32 must remain hold until the full native exit condition is met',
    );
  }

  const speechPackage = 'speech_to_text';
  const requiredSpeechEvidence = {
    'queried_on',
    'candidate',
    'decision',
    'compatibility_reason',
    'exit_condition',
    'owner_phase',
  };
  final speech = _map(baselineDependencies[speechPackage]);

  for (final field in requiredSpeechEvidence) {
    if (_isBlank(speech[field])) {
      issues.add(
        'PLUG-03 speech_to_text is missing required evidence field: $field',
      );
    }
  }
  final candidate = speech['candidate']?.toString() ?? '';
  if (!_isProductionStableVersion(candidate)) {
    issues.add(
      'PLUG-03 speech_to_text candidate must be a production-stable release',
    );
  }
  if (candidate != '7.4.0') {
    issues.add('PLUG-03 speech_to_text candidate must be stable 7.4.0');
  }
  if (speech['owner_phase'] != 59) {
    issues.add('PLUG-03 speech_to_text owner phase must be 59');
  }
  if (speech['official_source']?.toString() !=
      'https://pub.dev/packages/speech_to_text') {
    issues.add('PLUG-03 speech_to_text must cite the official pub.dev source');
  }

  const requiredSpeechAcceptanceResults = <String>{
    'automated_adapter_corpus',
    'supported_native_build',
    'iphone_permission',
    'iphone_ja_recognition',
    'iphone_zh_recognition',
    'iphone_en_recognition',
    'iphone_cancellation',
    'iphone_surfaced_error',
    'iphone_on_device',
    'iphone_allowed_fallback',
    'iphone_disallowed_fallback',
  };
  final acceptanceEvidence = _map(speech['acceptance_evidence']);
  for (final field in requiredSpeechAcceptanceResults) {
    if (_isBlank(acceptanceEvidence[field])) {
      issues.add(
        'PLUG-03 speech_to_text is missing required acceptance evidence result: $field',
      );
    }
  }

  final declared = _declaredDependency(directDependencies[speechPackage]);
  final resolved = _map(lockedPackages[speechPackage])['version']?.toString();
  final decision = speech['decision']?.toString();
  switch (decision) {
    case 'hold':
      if (declared != '7.3.0') {
        issues.add(
          'PLUG-03 speech_to_text declaration must remain 7.3.0 (found $declared)',
        );
      }
      if (resolved != '7.3.0') {
        issues.add(
          'PLUG-03 speech_to_text resolution must remain 7.3.0 (found $resolved)',
        );
      }
    case 'accepted':
      for (final field in requiredSpeechAcceptanceResults) {
        if (acceptanceEvidence[field]?.toString() != 'PASS') {
          issues.add(
            'PLUG-03 speech_to_text accepted decision requires PASS iPhone evidence: $field',
          );
        }
      }
      if (declared != candidate) {
        issues.add(
          'PLUG-03 speech_to_text accepted declaration must equal candidate $candidate (found $declared)',
        );
      }
      if (resolved != candidate) {
        issues.add(
          'PLUG-03 speech_to_text accepted resolution must equal candidate $candidate (found $resolved)',
        );
      }
    default:
      issues.add(
        'PLUG-03 speech_to_text decision must be exactly hold or accepted',
      );
  }

  const notificationPackages = <String>[
    'firebase_core',
    'firebase_messaging',
    'flutter_local_notifications',
  ];
  const notificationCandidates = <String, String>{
    'firebase_core': '4.13.0',
    'firebase_messaging': '16.5.0',
    'flutter_local_notifications': '22.3.0',
  };
  const notificationSelectedDeclarations = <String, String>{
    'firebase_core': '^4.13.0',
    'firebase_messaging': '^16.5.0',
    'flutter_local_notifications': '^22.2.0',
  };
  const notificationSelectedResolutions = <String, String>{
    'firebase_core': '4.13.0',
    'firebase_messaging': '16.5.0',
    'flutter_local_notifications': '22.2.0',
  };
  const requiredNotificationEvidence = <String>{
    'automated_lifecycle',
    'android_fcm_native_build',
    'android_fcm_initialization',
    'android_fcm_foreground',
    'android_fcm_opened_app',
    'android_fcm_cold_start',
    'ios_apns_native_build',
    'ios_apns_initialization',
    'ios_apns_foreground',
    'ios_apns_opened_app',
    'ios_apns_local_tap',
    'ios_apns_cold_start',
    'initialization_retry',
    'hidden_notification_settings',
    'android_auto_init_disabled',
    'ios_remote_notification_mode_absent',
    'ios_aps_environment_absent',
    'cloud_fallback_disclosed',
  };
  for (final package in notificationPackages) {
    final row = pluginRows[package]!;
    for (final field in {
      'queried_on',
      'candidate',
      'decision',
      'compatibility_reason',
      'exit_condition',
      'owner_phase',
      'official_source',
      'acceptance_evidence',
    }) {
      if (_isBlank(row[field])) {
        issues.add(
          'PLUG-04 $package is missing required evidence field: $field',
        );
      }
    }
    final candidate = row['candidate']?.toString() ?? '';
    if (!_isProductionStableVersion(candidate) ||
        candidate != notificationCandidates[package]) {
      issues.add(
        'PLUG-04 $package candidate must be stable ${notificationCandidates[package]}',
      );
    }
    final evidence = _map(row['acceptance_evidence']);
    for (final field in requiredNotificationEvidence) {
      if (_isBlank(evidence[field])) {
        issues.add('PLUG-04 $package is missing lifecycle evidence: $field');
      }
    }
    if (evidence['hidden_notification_settings']?.toString() != 'PASS') {
      issues.add(
        'PLUG-04 $package requires hidden notification settings evidence',
      );
    }
    if (evidence['android_auto_init_disabled']?.toString() != 'PASS' ||
        evidence['ios_remote_notification_mode_absent']?.toString() != 'PASS' ||
        evidence['ios_aps_environment_absent']?.toString() != 'PASS') {
      issues.add('PLUG-04 $package requires native hidden-policy evidence');
    }
    if (evidence['cloud_fallback_disclosed']?.toString() != 'PASS') {
      issues.add('PLUG-04 $package requires disclosed cloud fallback evidence');
    }

    final declared = _declaredDependency(directDependencies[package]);
    final resolved = _map(lockedPackages[package])['version']?.toString();
    switch (row['decision']?.toString()) {
      case 'hold':
        final selectedDeclaration = notificationSelectedDeclarations[package]!;
        final selectedResolution = notificationSelectedResolutions[package]!;
        if (declared != selectedDeclaration) {
          issues.add(
            'PLUG-04 $package declaration must remain $selectedDeclaration '
            '(found $declared)',
          );
        }
        if (resolved != selectedResolution) {
          issues.add(
            'PLUG-04 $package resolution must remain $selectedResolution '
            '(found $resolved)',
          );
        }
      case 'accepted':
        for (final field in requiredNotificationEvidence) {
          if (evidence[field]?.toString() != 'PASS') {
            issues.add(
              'PLUG-04 $package accepted decision requires PASS native evidence: $field',
            );
          }
        }
        if (declared != candidate) {
          issues.add(
            'PLUG-04 $package accepted declaration must equal candidate $candidate '
            '(found $declared)',
          );
        }
        if (resolved != candidate) {
          issues.add(
            'PLUG-04 $package accepted resolution must equal candidate $candidate '
            '(found $resolved)',
          );
        }
      default:
        issues.add(
          'PLUG-04 $package decision must be exactly hold or accepted',
        );
    }
  }

  final notificationLane = _map(baselineLanes['phase59_notification']);
  if (notificationLane['ios_transport']?.toString() != 'apns') {
    issues.add('PLUG-04 notification transport must identify iOS as apns');
  }
  if (notificationLane['android_transport']?.toString() != 'fcm') {
    issues.add('PLUG-04 notification transport must identify Android as fcm');
  }
  if (notificationLane['settings_visible'] != false) {
    issues.add('PLUG-04 notification settings must remain hidden');
  }
  if (notificationLane['ios_firebase_initialization'] != false) {
    issues.add('PLUG-04 iOS must not initialize Firebase messaging');
  }
  if (notificationLane['cloud_fallback_disclosed'] != true) {
    issues.add(
      'PLUG-04 notification lane must retain disclosed cloud fallback policy',
    );
  }

  const localAuthPackage = 'local_auth';
  const localAuthCandidate = '3.0.2';
  const localAuthHeldDeclaration = '^3.0.2';
  const localAuthHeldResolution = '3.0.2';
  const requiredLocalAuthEvidence = <String>{
    'automated_policy_contract',
    'supported_native_build',
    'face_id_success',
    'user_cancel_or_false_app_pin_fallback',
    'temporary_lockout_app_pin_fallback',
    'biometric_lockout_app_pin_fallback',
    'platform_exception_app_pin_fallback',
    'unknown_exception_app_pin_fallback',
    'app_pin_fallback',
  };
  const requiredFallbackEvidence = <String>{
    'temporary_lockout_app_pin_fallback',
    'biometric_lockout_app_pin_fallback',
    'platform_exception_app_pin_fallback',
    'unknown_exception_app_pin_fallback',
  };
  final localAuth = pluginRows[localAuthPackage]!;
  for (final field in {
    'official_source',
    'queried_on',
    'candidate',
    'decision',
    'compatibility_reason',
    'exit_condition',
    'acceptance_evidence',
  }) {
    if (_isBlank(localAuth[field])) {
      issues.add(
        'PLUG-04 local_auth is missing biometric evidence field: $field',
      );
    }
  }
  if (localAuth['official_source']?.toString() !=
      'https://pub.dev/packages/local_auth') {
    issues.add('PLUG-04 local_auth must cite the official pub.dev source');
  }
  if (!_isProductionStableVersion(localAuth['candidate']?.toString() ?? '') ||
      localAuth['candidate']?.toString() != localAuthCandidate) {
    issues.add(
      'PLUG-04 local_auth candidate must be stable $localAuthCandidate',
    );
  }
  final localAuthEvidence = _map(localAuth['acceptance_evidence']);
  for (final field in requiredLocalAuthEvidence) {
    if (_isBlank(localAuthEvidence[field])) {
      issues.add(
        requiredFallbackEvidence.contains(field)
            ? 'PLUG-04 local_auth is missing app-PIN fallback evidence: $field'
            : 'PLUG-04 local_auth is missing native evidence: $field',
      );
    }
  }

  final biometricLane = _map(baselineLanes['phase59_biometric']);
  for (final field in {
    'decision',
    'biometric_only',
    'sensitive_transaction',
    'persist_across_backgrounding',
    'app_pin_fallback_required',
    'device_passcode_accepted',
    'compatibility_reason',
    'exit_condition',
  }) {
    if (!biometricLane.containsKey(field) || _isBlank(biometricLane[field])) {
      issues.add(
        'PLUG-04 biometric app lock is missing secure-option proof: $field',
      );
    }
  }
  if (biometricLane['biometric_only'] != true ||
      biometricLane['device_passcode_accepted'] != false) {
    issues.add('PLUG-04 biometric app lock must remain biometric-only');
  }
  if (biometricLane['sensitive_transaction'] != true ||
      biometricLane['persist_across_backgrounding'] != true ||
      biometricLane['app_pin_fallback_required'] != true) {
    issues.add(
      'PLUG-04 biometric app lock must retain secure PIN-fallback policy',
    );
  }

  final declaredLocalAuth = _declaredDependency(
    directDependencies[localAuthPackage],
  );
  final resolvedLocalAuth = _map(
    lockedPackages[localAuthPackage],
  )['version']?.toString();
  switch (localAuth['decision']?.toString()) {
    case 'hold':
      if (declaredLocalAuth != localAuthHeldDeclaration) {
        issues.add(
          'PLUG-04 local_auth declaration must remain $localAuthHeldDeclaration '
          '(found $declaredLocalAuth)',
        );
      }
      if (resolvedLocalAuth != localAuthHeldResolution) {
        issues.add(
          'PLUG-04 local_auth resolution must remain $localAuthHeldResolution '
          '(found $resolvedLocalAuth)',
        );
      }
    case 'accepted':
      for (final field in requiredLocalAuthEvidence) {
        if (localAuthEvidence[field]?.toString() != 'PASS') {
          issues.add(
            'PLUG-04 local_auth accepted decision requires PASS native evidence: $field',
          );
        }
      }
      if (declaredLocalAuth != '^$localAuthCandidate') {
        issues.add(
          'PLUG-04 local_auth accepted declaration must equal candidate '
          '$localAuthCandidate (found $declaredLocalAuth)',
        );
      }
      if (resolvedLocalAuth != localAuthCandidate) {
        issues.add(
          'PLUG-04 local_auth accepted resolution must equal candidate '
          '$localAuthCandidate (found $resolvedLocalAuth)',
        );
      }
    default:
      issues.add(
        'PLUG-04 local_auth decision must be exactly hold or accepted',
      );
  }

  const secureStoragePackage = 'flutter_secure_storage';
  const secureStorageCandidate = '11.0.0';
  const secureStorageHeldDeclaration = '^10.3.1';
  const secureStorageHeldResolution = '10.3.1';
  const requiredSecureStorageEvidence = <String>{
    'existing_key_read',
    'existing_database_startup',
  };
  final secureStorage = pluginRows[secureStoragePackage]!;
  for (final field in {
    'official_source',
    'queried_on',
    'candidate',
    'decision',
    'compatibility_reason',
    'exit_condition',
    'migration_design',
    'acceptance_evidence',
  }) {
    if (_isBlank(secureStorage[field])) {
      issues.add(
        'PLUG-04 flutter_secure_storage is missing persisted-key evidence field: $field',
      );
    }
  }
  if (secureStorage['official_source']?.toString() !=
      'https://pub.dev/packages/flutter_secure_storage') {
    issues.add(
      'PLUG-04 flutter_secure_storage must cite the official pub.dev source',
    );
  }
  if (!_isProductionStableVersion(
        secureStorage['candidate']?.toString() ?? '',
      ) ||
      secureStorage['candidate']?.toString() != secureStorageCandidate) {
    issues.add(
      'PLUG-04 flutter_secure_storage candidate must be stable $secureStorageCandidate',
    );
  }
  final secureStorageEvidence = _map(secureStorage['acceptance_evidence']);
  for (final field in requiredSecureStorageEvidence) {
    if (_isBlank(secureStorageEvidence[field])) {
      issues.add(
        'PLUG-04 flutter_secure_storage is missing persisted-key evidence: $field',
      );
    }
  }

  final secureStorageLane = _map(baselineLanes['phase59_secure_storage']);
  for (final field in {
    'decision',
    'keychain_accessibility',
    'android_options',
    'centralized_access',
    'compatibility_reason',
    'exit_condition',
  }) {
    if (!secureStorageLane.containsKey(field) ||
        _isBlank(secureStorageLane[field])) {
      issues.add(
        'PLUG-04 flutter_secure_storage is missing platform policy proof: $field',
      );
    }
  }
  if (secureStorageLane['keychain_accessibility']?.toString() !=
      'unlocked_this_device') {
    issues.add(
      'PLUG-04 flutter_secure_storage must retain unlocked_this_device Keychain accessibility',
    );
  }
  if (secureStorageLane['android_options']?.toString() !=
      'established_default') {
    issues.add(
      'PLUG-04 flutter_secure_storage must retain established Android options',
    );
  }
  if (secureStorageLane['centralized_access']?.toString() !=
      'SecureStorageService and crypto key-manager only') {
    issues.add(
      'PLUG-04 flutter_secure_storage must retain centralized key access',
    );
  }

  final declaredSecureStorage = _declaredDependency(
    directDependencies[secureStoragePackage],
  );
  final resolvedSecureStorage = _map(
    lockedPackages[secureStoragePackage],
  )['version']?.toString();
  switch (secureStorage['decision']?.toString()) {
    case 'hold':
      if (declaredSecureStorage != secureStorageHeldDeclaration) {
        issues.add(
          'PLUG-04 flutter_secure_storage declaration must remain '
          '$secureStorageHeldDeclaration (found $declaredSecureStorage)',
        );
      }
      if (resolvedSecureStorage != secureStorageHeldResolution) {
        issues.add(
          'PLUG-04 flutter_secure_storage resolution must remain '
          '$secureStorageHeldResolution (found $resolvedSecureStorage)',
        );
      }
    case 'accepted':
      if (secureStorage['migration_design']?.toString() !=
          'read_then_rewrite') {
        issues.add(
          'PLUG-04 flutter_secure_storage accepted decision requires a read-then-rewrite migration design',
        );
      }
      for (final field in requiredSecureStorageEvidence) {
        if (secureStorageEvidence[field]?.toString() != 'PASS') {
          issues.add(
            'PLUG-04 flutter_secure_storage accepted decision requires PASS persisted-key evidence: $field',
          );
        }
      }
      if (declaredSecureStorage != '^$secureStorageCandidate') {
        issues.add(
          'PLUG-04 flutter_secure_storage accepted declaration must equal '
          'candidate $secureStorageCandidate (found $declaredSecureStorage)',
        );
      }
      if (resolvedSecureStorage != secureStorageCandidate) {
        issues.add(
          'PLUG-04 flutter_secure_storage accepted resolution must equal '
          'candidate $secureStorageCandidate (found $resolvedSecureStorage)',
        );
      }
    default:
      issues.add(
        'PLUG-04 flutter_secure_storage decision must be exactly hold or accepted',
      );
  }

  const declarations = <String, String>{
    'file_picker': '^11.0.3',
    'share_plus': '^12.0.2',
    'package_info_plus': '^9.0.1',
  };
  const locked = <String, String>{
    'file_picker': '11.0.3',
    'share_plus': '12.0.2',
    'package_info_plus': '9.0.1',
    'win32': '5.15.0',
  };
  for (final entry in declarations.entries) {
    final declared = _declaredDependency(directDependencies[entry.key]);
    if (declared != entry.value) {
      issues.add(
        'PLUG-02 ${entry.key} declaration must remain ${entry.value} '
        '(found $declared)',
      );
      issues.add('PLUG-02 atomic cohort declaration drift for ${entry.key}');
    }
  }
  for (final entry in locked.entries) {
    final selected = _map(lockedPackages[entry.key])['version']?.toString();
    if (selected != entry.value) {
      issues.add(
        'PLUG-02 ${entry.key} resolution must remain ${entry.value} '
        '(found $selected)',
      );
      issues.add('PLUG-02 atomic cohort resolution drift for ${entry.key}');
    }
  }
}

List<String> _listOfStrings(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const <String>[];

bool _hasExactMembers(List<String> actual, List<String> expected) =>
    actual.length == expected.length &&
    actual.toSet().length == actual.length &&
    actual.toSet().containsAll(expected) &&
    expected.toSet().containsAll(actual);

bool _isLexicallyOrdered(List<String> values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index - 1].compareTo(values[index]) > 0) return false;
  }
  return true;
}

void _validateManifestPolicy({
  required List<String> issues,
  required Map<String, Object?> baseline,
}) {
  final floors = _map(baseline['platform_floors']);
  if (_map(floors['ios'])['selected']?.toString() != '15.0') {
    issues.add('iOS support floor must be 15.0');
  }
  final androidFloor = _map(floors['android'])['selected'];
  if (androidFloor != 24) {
    issues.add('Android support floor must be API 24');
  }

  final toolchains = _map(baseline['toolchains']);
  for (final entry in toolchains.entries) {
    final id = entry.key.toString();
    final row = _map(entry.value);
    final selected = row['selected_current']?.toString() ?? '';
    final candidate = row['production_stable_candidate']?.toString() ?? '';
    final decision = row['decision']?.toString();
    if (_isUnsafeRelease(selected)) {
      issues.add('toolchain $id selects forbidden prerelease or EOL value');
    }
    if (!_isProductionStableVersion(candidate)) {
      issues.add('toolchain $id candidate must be production stable');
    }
    if (decision == 'already_current' &&
        _isProductionStableVersion(selected) &&
        _isProductionStableVersion(candidate) &&
        _compareVersion(selected, candidate) < 0) {
      issues.add(
        'toolchain $id selected value must not be lower than its candidate',
      );
    }
  }

  final dependencies = _map(baseline['direct_dependencies']);
  for (final entry in dependencies.entries) {
    final id = entry.key.toString();
    final row = _map(entry.value);
    final selected = row['resolved']?.toString() ?? '';
    final candidate = row['candidate']?.toString() ?? '';
    final decision = row['decision']?.toString();
    if (_isUnsafeRelease(selected) && id != 'freezed') {
      issues.add('dependency $id selects forbidden prerelease or EOL value');
    }
    if (!row['kind'].toString().contains('path') &&
        !_isProductionStableVersion(candidate)) {
      issues.add('dependency $id candidate must be production stable');
    }
    if (row['kind']?.toString().contains('sdk') != true &&
        decision == 'already_current' &&
        _isProductionStableVersion(selected) &&
        _isProductionStableVersion(candidate) &&
        _compareVersion(selected, candidate) < 0) {
      issues.add(
        'dependency $id selected value must not be lower than its candidate',
      );
    }
  }

  const laneMembers = {
    'encrypted_storage': [
      'Drift 2.34.0',
      'sqlite3 3.5.1',
      'SQLCipher Native Asset 4.17',
    ],
    'platform_floors': ['iOS 15.0', 'Android API 24'],
    'architecture': [
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
    ],
  };
  final lanes = _map(baseline['lanes']);
  for (final entry in laneMembers.entries) {
    final selected = _map(lanes[entry.key])['selected']?.toString() ?? '';
    if (entry.value.any((member) => !selected.contains(member))) {
      issues.add('compatibility lane ${entry.key} is incomplete');
    }
  }
}

bool _isUnsafeRelease(String value) => RegExp(
  r'(?:^|[-+._])(?:beta|rc|dev|eol)(?:[+._-]|$)',
  caseSensitive: false,
).hasMatch(value);

bool _isProductionStableVersion(String value) =>
    RegExp(r'^\d+(?:\.\d+){0,3}(?:\+\d+)?$').hasMatch(value);

int _compareVersion(String left, String right) {
  final leftParts = RegExp(
    r'\d+',
  ).allMatches(left).map((m) => int.parse(m.group(0)!));
  final rightParts = RegExp(
    r'\d+',
  ).allMatches(right).map((m) => int.parse(m.group(0)!));
  final l = leftParts.toList();
  final r = rightParts.toList();
  if (l.isEmpty || r.isEmpty) return 0;
  for (
    var index = 0;
    index < (l.length > r.length ? l.length : r.length);
    index++
  ) {
    final a = index < l.length ? l[index] : 0;
    final b = index < r.length ? r[index] : 0;
    if (a != b) return a.compareTo(b);
  }
  return 0;
}

void _validateTrackedInputs({
  required List<String> issues,
  required Map<Object?, Object?> manifestInputs,
  required Map<String, String> actualContents,
}) {
  final manifestPaths = manifestInputs.keys
      .map((key) => key.toString())
      .toSet();
  final actualPaths = actualContents.keys.toSet();
  for (final path in actualPaths.difference(manifestPaths)) {
    issues.add('tracked input is missing from baseline: $path');
  }
  for (final path in manifestPaths.difference(actualPaths)) {
    issues.add('baseline declares unprovided tracked input: $path');
  }
  for (final path in actualPaths.intersection(manifestPaths)) {
    final expected = _map(manifestInputs[path])['sha256']?.toString();
    final actual = sha256
        .convert(utf8.encode(actualContents[path]!))
        .toString();
    if (expected != actual) {
      issues.add('tracked input digest mismatch: $path');
    }
  }
}

void _validateFlutterIdentity({
  required List<String> issues,
  required Map<Object?, Object?> flutterToolchain,
  required Map<Object?, Object?> dartToolchain,
  required String metadataYaml,
  required String machineJson,
  required String auditWorkflow,
  required String flutterExtensionSource,
  required DependencyCompatibilityMode mode,
}) {
  final selected = flutterToolchain['selected_current']?.toString();
  final selectedDart = dartToolchain['selected_current']?.toString();
  final channel = flutterToolchain['channel']?.toString();
  final revision = flutterToolchain['framework_revision']?.toString();
  final metadata = _map(loadYaml(metadataYaml));
  final metadataVersion = _map(metadata['version']);
  if (metadataVersion['revision']?.toString() != revision) {
    issues.add(
      '.metadata revision must match the selected Flutter Stable identity',
    );
  }
  if (metadataVersion['channel']?.toString() != channel) {
    issues.add(
      '.metadata channel must match the selected Flutter Stable identity',
    );
  }
  final pins = RegExp(r'flutter-version:\s*([^\s#]+)')
      .allMatches(auditWorkflow)
      .map((match) => match.group(1))
      .whereType<String>()
      .toList();
  final stableChannels = RegExp(
    r'channel:\s*stable',
  ).allMatches(auditWorkflow).length;
  if (pins.isEmpty ||
      pins.length != stableChannels ||
      pins.any((pin) => pin != selected)) {
    issues.add(
      'every Stable CI Flutter pin must match the selected current identity',
    );
  }
  if (machineJson.isNotEmpty) {
    final machine = _parseMachineJson(machineJson, issues);
    final hasIdentity = {
      'flutterVersion',
      'channel',
      'frameworkRevision',
      'dartSdkVersion',
    }.every((field) => !_isBlank(machine[field]));
    if (!hasIdentity) {
      issues.add(
        'running Flutter --version --machine output must include Flutter identity fields',
      );
    } else if (!_hasWellFormedMachineIdentity(machine)) {
      issues.add(
        'running Flutter --version --machine output must contain well-formed string Flutter identity fields',
      );
    } else if (mode == DependencyCompatibilityMode.futureProbe &&
        machine['channel'] == 'beta') {
      issues.add(
        'running Flutter beta SDK differs from the selected Stable identity',
      );
    } else {
      if (machine['flutterVersion']?.toString() != selected ||
          machine['channel']?.toString() != channel ||
          machine['frameworkRevision']?.toString() != revision) {
        issues.add(
          'running Flutter SDK must match the selected current identity',
        );
      }
      if (machine['dartSdkVersion']?.toString() != selectedDart) {
        issues.add('running Dart SDK must match the selected current identity');
      }
    }
  }
  if (flutterExtensionSource.isEmpty && machineJson.isNotEmpty) {
    issues.add('FlutterExtension.kt is missing from the resolved Flutter SDK');
  } else if (flutterExtensionSource.isNotEmpty) {
    final expectedMinSdk = _map(
      flutterToolchain['flutter_extension_defaults'],
    )['min_sdk'];
    final minSdk = RegExp(
      r'val minSdkVersion: Int = (\d+)',
    ).firstMatch(flutterExtensionSource)?.group(1);
    if (minSdk == null || int.tryParse(minSdk) == null) {
      issues.add('FlutterExtension.kt must declare an integer minSdkVersion');
    } else if (int.parse(minSdk) < 24 || minSdk != expectedMinSdk?.toString()) {
      issues.add(
        'FlutterExtension.kt minSdkVersion must match the manifest and be >= 24',
      );
    }
  }
}

bool _hasWellFormedMachineIdentity(Map<String, Object?> machine) {
  final flutterVersion = machine['flutterVersion'];
  final channel = machine['channel'];
  final frameworkRevision = machine['frameworkRevision'];
  final dartSdkVersion = machine['dartSdkVersion'];
  final version = RegExp(
    r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?(?:\+[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$',
  );
  return flutterVersion is String &&
      channel is String &&
      frameworkRevision is String &&
      dartSdkVersion is String &&
      channel.trim().isNotEmpty &&
      version.hasMatch(flutterVersion) &&
      version.hasMatch(dartSdkVersion) &&
      RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(frameworkRevision);
}

Map<String, Object?> _parseMachineJson(String source, List<String> issues) {
  try {
    final value = jsonDecode(source);
    if (value is Map) {
      return value.cast<String, Object?>();
    }
  } on FormatException {
    // The caller receives a stable aggregated diagnostic below.
  }
  issues.add('running Flutter --version --machine output must be valid JSON');
  return const {};
}

String _declaredDependency(Object? value) {
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(',');
  }
  return value.toString();
}

bool _isBlank(Object? value) =>
    value == null || value.toString().trim().isEmpty;

bool _isIsoDate(Object? value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value?.toString() ?? '');

Map<Object?, Object?> _map(Object? value) =>
    value is Map ? value.cast<Object?, Object?>() : const {};

class _RunningFlutterSdk {
  const _RunningFlutterSdk({
    required this.machineJson,
    required this.extensionSource,
    required this.errors,
  });

  final String machineJson;
  final String extensionSource;
  final List<String> errors;
}

Future<_RunningFlutterSdk> _readRunningFlutterSdk() async {
  final command = Platform.isWindows ? 'where' : 'which';
  final result = await Process.run(command, const ['flutter']);
  if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
    return const _RunningFlutterSdk(
      machineJson: '',
      extensionSource: '',
      errors: ['could not resolve flutter executable on PATH'],
    );
  }
  try {
    final executable = result.stdout
        .toString()
        .trim()
        .split(RegExp(r'\r?\n'))
        .first;
    final resolvedExecutable = File(executable).resolveSymbolicLinksSync();
    final flutterRoot = File(resolvedExecutable).parent.parent.path;
    final machine = await Process.run(executable, const [
      '--version',
      '--machine',
    ]);
    if (machine.exitCode != 0) {
      return _RunningFlutterSdk(
        machineJson: '',
        extensionSource: '',
        errors: ['flutter --version --machine failed: ${machine.stderr}'],
      );
    }
    final extension = File(
      '$flutterRoot/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt',
    );
    if (!extension.existsSync()) {
      return _RunningFlutterSdk(
        machineJson: '',
        extensionSource: '',
        errors: [
          'FlutterExtension.kt is missing from the resolved Flutter SDK',
        ],
      );
    }
    return _RunningFlutterSdk(
      machineJson: machine.stdout.toString(),
      extensionSource: extension.readAsStringSync(),
      errors: const [],
    );
  } on FileSystemException catch (error) {
    return _RunningFlutterSdk(
      machineJson: '',
      extensionSource: '',
      errors: ['could not inspect resolved Flutter SDK: ${error.message}'],
    );
  }
}

Map<String, String> _trackedInputContents(String Function(String path) read) =>
    {
      '.metadata': read('.metadata'),
      'pubspec.yaml': read('pubspec.yaml'),
      'pubspec.lock': read('pubspec.lock'),
      'android/settings.gradle.kts': read('android/settings.gradle.kts'),
      'android/app/build.gradle.kts': read('android/app/build.gradle.kts'),
      'android/gradle.properties': read('android/gradle.properties'),
      'android/gradle/wrapper/gradle-wrapper.properties': read(
        'android/gradle/wrapper/gradle-wrapper.properties',
      ),
      'ios/Podfile': read('ios/Podfile'),
      'ios/Podfile.lock': read('ios/Podfile.lock'),
      'ios/Runner.xcodeproj/project.pbxproj': read(
        'ios/Runner.xcodeproj/project.pbxproj',
      ),
    };

bool _pubspecOverridesPresent(String pubspecYaml) =>
    _map(loadYaml(pubspecYaml)).containsKey('dependency_overrides') ||
    File('pubspec_overrides.yaml').existsSync();

Future<void> main(List<String> arguments) async {
  late final DependencyCompatibilityMode mode;
  try {
    mode = parseDependencyCompatibilityMode(arguments);
  } on ArgumentError catch (error) {
    stderr.writeln(
      'Usage: dependency_compatibility.dart '
      '[--mode=baseline|future-probe] [--verify-running-flutter-sdk]',
    );
    stderr.writeln('[dependency-compat] ERROR: ${error.message}');
    exitCode = 2;
    return;
  }

  String read(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('[dependency-compat] ERROR: missing $path');
      return '';
    }
    return file.readAsStringSync();
  }

  final verifyRunningFlutterSdk = arguments.contains(
    '--verify-running-flutter-sdk',
  );
  final running = verifyRunningFlutterSdk
      ? await _readRunningFlutterSdk()
      : const _RunningFlutterSdk(
          machineJson: '',
          extensionSource: '',
          errors: [],
        );
  final pubspec = read('pubspec.yaml');
  final report = validateDependencyCompatibility(
    pubspecYaml: pubspec,
    lockYaml: read('pubspec.lock'),
    androidSettings: read('android/settings.gradle.kts'),
    androidAppBuild: read('android/app/build.gradle.kts'),
    androidProperties: read('android/gradle.properties'),
    gradleWrapper: read('android/gradle/wrapper/gradle-wrapper.properties'),
    podfile: read('ios/Podfile'),
    podfileLock: read('ios/Podfile.lock'),
    xcodeProject: read('ios/Runner.xcodeproj/project.pbxproj'),
    auditWorkflow: read('.github/workflows/audit.yml'),
    futureWorkflow: read('.github/workflows/flutter-future-compat.yml'),
    baselineJson: read('docs/testing/STABLE_BASELINE.json'),
    metadataYaml: read('.metadata'),
    flutterExtensionSource: running.extensionSource,
    runningFlutterMachineJson: running.machineJson,
    pubspecOverridesPresent: _pubspecOverridesPresent(pubspec),
    trackedInputContents: _trackedInputContents(read),
    mode: mode,
  );
  final completeReport = _reportFromMessages([
    ...running.errors,
    ...report.messages,
  ], mode);
  if (!completeReport.isPassing) {
    stderr.writeln(
      '[dependency-compat] FAIL (${completeReport.errors.length} error(s), '
      '${completeReport.warnings.length} warning(s))',
    );
    for (final issue in completeReport.issues) {
      stderr.writeln('  - [${issue.code}] ${issue.message}');
    }
    exitCode = 1;
    return;
  }
  final status = completeReport.warnings.isEmpty ? 'PASS' : 'WARN';
  stdout.writeln(
    '[dependency-compat] $status (0 error(s), '
    '${completeReport.warnings.length} warning(s))',
  );
  for (final warning in completeReport.warnings) {
    stdout.writeln('  - [${warning.code}] ${warning.message}');
  }
  stdout.writeln(
    '  Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher Native Asset 4.17',
  );
  final betaIdentityParsed = completeReport.warnings.any(
    (warning) =>
        warning.message ==
        'running Flutter beta SDK differs from the selected Stable identity',
  );
  stdout.writeln(
    '  ${successSummary(mode, betaIdentityParsed: betaIdentityParsed)}',
  );
}
