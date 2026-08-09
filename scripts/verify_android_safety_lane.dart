/// Fail-closed Android candidate/hold, release, and Emulator evidence runner.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum AndroidSafetyMode { verify, candidateProbe, release, emulator }

const candidateAgp = '9.3.1';
const candidateGradle = '9.5.0';
const selectedAgp = '8.11.1';
const selectedGradle = '8.14';
const selectedKotlin = '2.2.20';
const requiredJdk = '17';
const requiredAndroidApi = 36;
const requiredAndroidAbi = 'x86_64';
const candidateQueriedOn = '2026-08-09';
const physicalDeviceDisclaimer =
    'Android physical-device validation was not performed or claimed.';

const evidencePath =
    '.planning/phases/61-android-toolchain-emulator-lane/'
    '61-ANDROID-SAFETY-EVIDENCE.md';
const _evidenceStart = '<!-- phase61-evidence-json:start -->';
const _evidenceEnd = '<!-- phase61-evidence-json:end -->';

class AndroidSafetyOptions {
  const AndroidSafetyOptions({
    required this.mode,
    required this.allowNotRun,
    required this.prepareOnly,
  });

  final AndroidSafetyMode mode;
  final bool allowNotRun;
  final bool prepareOnly;
}

AndroidSafetyOptions parseAndroidSafetyOptions(List<String> arguments) {
  AndroidSafetyMode? mode;
  var allowNotRun = false;
  var prepareOnly = false;
  for (final argument in arguments) {
    if (argument.startsWith('--mode=')) {
      if (mode != null) throw ArgumentError('mode supplied more than once');
      mode = switch (argument.substring('--mode='.length)) {
        'verify' => AndroidSafetyMode.verify,
        'candidate-probe' => AndroidSafetyMode.candidateProbe,
        'release' => AndroidSafetyMode.release,
        'emulator' => AndroidSafetyMode.emulator,
        _ => throw ArgumentError('unknown Android safety mode'),
      };
    } else if (argument == '--allow-not-run') {
      if (allowNotRun) {
        throw ArgumentError('allow-not-run supplied more than once');
      }
      allowNotRun = true;
    } else if (argument == '--prepare-only') {
      if (prepareOnly) {
        throw ArgumentError('prepare-only supplied more than once');
      }
      prepareOnly = true;
    } else {
      throw ArgumentError('unknown argument: $argument');
    }
  }
  if (mode == null || (prepareOnly && mode != AndroidSafetyMode.emulator)) {
    throw ArgumentError(
      'usage: --mode=verify|candidate-probe|release|emulator '
      '[--allow-not-run] [--prepare-only for emulator]',
    );
  }
  return AndroidSafetyOptions(
    mode: mode,
    allowNotRun: allowNotRun,
    prepareOnly: prepareOnly,
  );
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseAndroidSafetyOptions(arguments);
    switch (options.mode) {
      case AndroidSafetyMode.verify:
        final issues = validateCurrentAndroidSafetyLane(
          allowNotRun: options.allowNotRun,
        );
        if (issues.isNotEmpty) {
          for (final issue in issues) {
            stderr.writeln('ERROR: $issue');
          }
          exitCode = 1;
          return;
        }
        stdout.writeln('PASS: Android safety lane evidence is coherent');
      case AndroidSafetyMode.candidateProbe:
        stderr.writeln(
          'ERROR: candidate-probe mode is not implemented until plan 61-02',
        );
        exitCode = 2;
      case AndroidSafetyMode.release:
        stderr.writeln(
          'ERROR: release mode is not implemented until plan 61-04',
        );
        exitCode = 2;
      case AndroidSafetyMode.emulator:
        stderr.writeln(
          'ERROR: emulator mode is not implemented until plan 61-05',
        );
        exitCode = 2;
    }
  } on Object catch (error) {
    stderr.writeln('ERROR: $error');
    exitCode = 2;
  }
}

List<String> validateCurrentAndroidSafetyLane({required bool allowNotRun}) {
  return validateAndroidSafetyLane(
    baselineJson: File('docs/testing/STABLE_BASELINE.json').readAsStringSync(),
    settingsGradle: File('android/settings.gradle.kts').readAsStringSync(),
    gradleProperties: File('android/gradle.properties').readAsStringSync(),
    gradleWrapper: File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync(),
    appBuildGradle: File('android/app/build.gradle.kts').readAsStringSync(),
    evidenceMarkdown: File(evidencePath).readAsStringSync(),
    legacyKgpPlugins: inventoryLegacyKgpPlugins(Directory.current),
    allowNotRun: allowNotRun,
  );
}

List<String> validateAndroidSafetyLane({
  required String baselineJson,
  required String settingsGradle,
  required String gradleProperties,
  required String gradleWrapper,
  required String appBuildGradle,
  required String evidenceMarkdown,
  required List<String> legacyKgpPlugins,
  required bool allowNotRun,
}) {
  final issues = <String>[];
  final baseline = _decodeObject(baselineJson, 'baseline', issues);
  final toolchains = _object(baseline['toolchains']);
  final lane = _object(_object(baseline['lanes'])['phase61_android']);
  final agp = _object(toolchains['agp']);
  final gradle = _object(toolchains['gradle']);
  final jdk = _object(toolchains['jdk']);
  final sdk = _object(toolchains['android_sdk']);
  final floors = _object(_object(baseline['platform_floors'])['android']);

  _expect(
    agp['production_stable_candidate'] == candidateAgp,
    issues,
    'AGP candidate must be $candidateAgp',
  );
  _expect(
    gradle['production_stable_candidate'] == candidateGradle,
    issues,
    'Gradle candidate must be $candidateGradle',
  );
  _expect(
    agp['queried_on'] == candidateQueriedOn,
    issues,
    'AGP candidate query date must be $candidateQueriedOn',
  );
  _expect(
    gradle['queried_on'] == candidateQueriedOn,
    issues,
    'Gradle candidate query date must be $candidateQueriedOn',
  );
  _expect(
    '${jdk['selected_current']}' == requiredJdk,
    issues,
    'JDK selected runtime must remain $requiredJdk',
  );
  _expect(
    '${sdk['selected_current']}' == '$requiredAndroidApi',
    issues,
    'Android SDK must remain API $requiredAndroidApi',
  );
  _expect(floors['selected'] == 24, issues, 'Android minSdk must remain 24');

  final decision = lane['decision'];
  _expect(
    decision == 'hold' || decision == 'selected',
    issues,
    'Android lane decision must be hold or selected',
  );
  if (decision == 'hold') {
    _expect(
      agp['selected_current'] == selectedAgp,
      issues,
      'hold must retain AGP $selectedAgp',
    );
    _expect(
      gradle['selected_current'] == selectedGradle,
      issues,
      'hold must retain Gradle $selectedGradle',
    );
    _expect(
      settingsGradle.contains(
        'id("com.android.application") version "$selectedAgp" apply false',
      ),
      issues,
      'hold settings must retain AGP $selectedAgp',
    );
    _expect(
      settingsGradle.contains(
        'id("org.jetbrains.kotlin.android") version "$selectedKotlin" apply false',
      ),
      issues,
      'hold settings must retain Kotlin $selectedKotlin',
    );
    _expect(
      gradleWrapper.contains('gradle-$selectedGradle-all.zip'),
      issues,
      'hold wrapper must retain Gradle $selectedGradle',
    );
    _expect(
      gradleProperties.contains('android.builtInKotlin=false') &&
          gradleProperties.contains('android.newDsl=false'),
      issues,
      'hold must retain both Flutter legacy Kotlin/DSL flags',
    );
    _expect(
      appBuildGradle.contains('id("kotlin-android")'),
      issues,
      'hold app must retain legacy KGP application',
    );
    _expect(
      legacyKgpPlugins.isNotEmpty,
      issues,
      'hold blocker inventory must include legacy KGP plugins',
    );
    for (final field in ['compatibility_reason', 'exit_condition']) {
      _expect(
        '${lane[field] ?? ''}'.trim().isNotEmpty,
        issues,
        'hold lane is missing $field',
      );
    }
  } else if (decision == 'selected') {
    _expect(
      agp['selected_current'] == candidateAgp,
      issues,
      'selected lane must use AGP $candidateAgp',
    );
    _expect(
      gradle['selected_current'] == candidateGradle,
      issues,
      'selected lane must use Gradle $candidateGradle',
    );
    _expect(
      !settingsGradle.contains('org.jetbrains.kotlin.android'),
      issues,
      'selected lane must remove the legacy KGP declaration',
    );
    _expect(
      !appBuildGradle.contains('kotlin-android'),
      issues,
      'selected lane must remove app legacy KGP',
    );
    _expect(
      !gradleProperties.contains('android.builtInKotlin') &&
          !gradleProperties.contains('android.newDsl'),
      issues,
      'selected lane must remove both temporary flags',
    );
    _expect(
      legacyKgpPlugins.isEmpty,
      issues,
      'selected lane must have no resolved legacy KGP plugins',
    );
  }

  final evidence = parseEvidenceMarkdown(evidenceMarkdown, issues);
  _validateEvidence(evidence, issues, allowNotRun: allowNotRun);
  return issues;
}

Map<String, Object?> parseEvidenceMarkdown(
  String markdown,
  List<String> issues,
) {
  final start = markdown.indexOf(_evidenceStart);
  final end = markdown.indexOf(_evidenceEnd);
  if (start < 0 || end <= start) {
    issues.add('evidence JSON markers are missing or malformed');
    return const {};
  }
  final body = markdown
      .substring(start + _evidenceStart.length, end)
      .replaceFirst(RegExp(r'^\s*```json\s*'), '')
      .replaceFirst(RegExp(r'\s*```\s*$'), '')
      .trim();
  return _decodeObject(body, 'evidence', issues);
}

void _validateEvidence(
  Map<String, Object?> evidence,
  List<String> issues, {
  required bool allowNotRun,
}) {
  _expect(
    evidence['schema_version'] == 1,
    issues,
    'evidence schema_version must be 1',
  );
  _expect(
    evidence['physical_device_statement'] == physicalDeviceDisclaimer,
    issues,
    'physical-device disclaimer is missing',
  );
  final graph = _object(evidence['graph']);
  _expect(
    graph['candidate_agp'] == candidateAgp,
    issues,
    'evidence candidate AGP is stale',
  );
  _expect(
    graph['candidate_gradle'] == candidateGradle,
    issues,
    'evidence candidate Gradle is stale',
  );
  _expect('${graph['jdk']}' == requiredJdk, issues, 'evidence JDK must be 17');
  _expect(
    graph['android_api'] == requiredAndroidApi,
    issues,
    'evidence Android API must be 36',
  );
  _expect(graph['min_sdk'] == 24, issues, 'evidence minSdk must be 24');

  final encoded = jsonEncode(evidence);
  for (final pattern in <RegExp>[
    RegExp(r'/Users/[^/\s"]+'),
    RegExp(
      r'(storePassword|keyPassword|keystore_password|secret)\s*[:=]',
      caseSensitive: false,
    ),
    RegExp(r'emulator-\d{4}'),
  ]) {
    if (pattern.hasMatch(encoded)) {
      issues.add(
        'evidence contains prohibited sensitive value: ${pattern.pattern}',
      );
    }
  }

  final results = _object(evidence['results']);
  for (final field in [
    'candidate',
    'compile',
    'package',
    'emulator',
    'physical_device',
  ]) {
    _expect(
      '${results[field] ?? ''}'.isNotEmpty,
      issues,
      'evidence result is missing: $field',
    );
  }
  if (!allowNotRun) {
    _expect(
      results['candidate'] == 'INCOMPATIBLE' || results['candidate'] == 'PASS',
      issues,
      'candidate result must be observed',
    );
    _expect(
      results['compile'] == 'PASS',
      issues,
      'compile result must be PASS',
    );
    _expect(
      results['package'] == 'PASS',
      issues,
      'package result must be PASS',
    );
    _expect(
      results['emulator'] == 'PASS',
      issues,
      'emulator result must be PASS',
    );
  }
  _expect(
    results['physical_device'] == 'NOT_PERFORMED_NOT_CLAIMED',
    issues,
    'physical-device result must remain explicitly absent',
  );
}

List<String> inventoryLegacyKgpPlugins(Directory root) {
  final dependencyFile = File('${root.path}/.flutter-plugins-dependencies');
  if (!dependencyFile.existsSync()) return const [];
  final decoded = jsonDecode(dependencyFile.readAsStringSync());
  if (decoded is! Map) return const [];
  final plugins = _object(decoded.cast<String, Object?>()['plugins']);
  final android = plugins['android'];
  if (android is! List) return const [];
  final found = <String>[];
  for (final raw in android) {
    if (raw is! Map) continue;
    final row = raw.cast<String, Object?>();
    final name = '${row['name'] ?? ''}';
    final path = '${row['path'] ?? ''}';
    if (name.isEmpty || path.isEmpty) continue;
    final androidDir = Directory('$path/android');
    if (!androidDir.existsSync()) continue;
    final sources = <String>[];
    for (final fileName in [
      'build.gradle',
      'build.gradle.kts',
      'settings.gradle',
      'settings.gradle.kts',
    ]) {
      final file = File('${androidDir.path}/$fileName');
      if (file.existsSync()) sources.add(file.readAsStringSync());
    }
    final source = sources.join('\n');
    if (RegExp(
      r'''(?:kotlin-android|org\.jetbrains\.kotlin\.android)''',
    ).hasMatch(source)) {
      found.add(name);
    }
  }
  found.sort();
  return found;
}

String sha256Text(String value) =>
    sha256.convert(utf8.encode(value)).toString();

Map<String, Object?> _decodeObject(
  String source,
  String label,
  List<String> issues,
) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map) return decoded.cast<String, Object?>();
  } on FormatException catch (error) {
    issues.add('$label is invalid JSON: ${error.message}');
    return const {};
  }
  issues.add('$label root must be a JSON object');
  return const {};
}

Map<String, Object?> _object(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};

void _expect(bool condition, List<String> issues, String message) {
  if (!condition) issues.add(message);
}
