/// Fail-closed Android candidate/hold, release, and Emulator evidence runner.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

enum AndroidSafetyMode { verify, candidateProbe, release, emulator }

enum AndroidCertificateClass { debug, nonDebug }

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
const maxDurableOutputChars = 32768;

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
        final result = await runCandidateProbe(Directory.current);
        if (!result.completed) {
          stderr.writeln('ERROR: ${result.message}');
          exitCode = 2;
          return;
        }
        stdout.writeln(result.message);
      case AndroidSafetyMode.release:
        final result = await runReleaseEvidence(Directory.current);
        if (!result.completed) {
          stderr.writeln('ERROR: ${result.message}');
          exitCode = 2;
          return;
        }
        stdout.writeln(result.message);
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
    final reason = '${lane['compatibility_reason'] ?? ''}';
    _expect(
      reason.contains('Flutter 3.44.8'),
      issues,
      'hold reason must identify the selected Flutter blocker',
    );
    for (final plugin in legacyKgpPlugins) {
      _expect(
        reason.contains(plugin),
        issues,
        'hold reason must identify legacy KGP plugin $plugin',
      );
    }
    final exitCondition = '${lane['exit_condition'] ?? ''}';
    _expect(
      exitCondition.contains('Flutter 3.47') &&
          exitCondition.contains('Phase 59'),
      issues,
      'hold exit condition must require Flutter 3.47+ and Phase 59 approval',
    );
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
  _validateEvidence(
    evidence,
    issues,
    allowNotRun: allowNotRun,
    legacyKgpPlugins: legacyKgpPlugins,
  );
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
  required List<String> legacyKgpPlugins,
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
  final completedStage = '${evidence['completed_stage'] ?? ''}';
  const stages = ['contract', 'candidate', 'compile', 'package', 'emulator'];
  final stageIndex = stages.indexOf(completedStage);
  _expect(stageIndex >= 0, issues, 'evidence completed_stage is invalid');
  if (!allowNotRun && stageIndex >= 1) {
    _expect(
      results['candidate'] == 'INCOMPATIBLE' || results['candidate'] == 'PASS',
      issues,
      'candidate result must be observed',
    );
    final blocker = _object(evidence['blocker']);
    for (final field in [
      'component',
      'official_source',
      'reproduction',
      'exit_condition',
    ]) {
      _expect(
        '${blocker[field] ?? ''}'.trim().isNotEmpty &&
            blocker[field] != 'NOT_RUN',
        issues,
        'observed candidate blocker is missing $field',
      );
    }
    final inventory = evidence['plugin_legacy_kgp_inventory'];
    _expect(
      inventory is List &&
          inventory
              .map((item) => '$item')
              .toSet()
              .containsAll(legacyKgpPlugins),
      issues,
      'candidate evidence must include the complete legacy KGP inventory',
    );
  } else if (!allowNotRun) {
    _expect(false, issues, 'candidate result must be observed');
  }
  if (!allowNotRun && stageIndex >= 2) {
    _expect(
      results['compile'] == 'PASS',
      issues,
      'compile result must be PASS at compile stage',
    );
  }
  if (!allowNotRun && stageIndex >= 3) {
    _expect(
      results['package'] == 'PASS',
      issues,
      'package result must be PASS at package stage',
    );
  }
  if (!allowNotRun && stageIndex >= 4) {
    _expect(
      results['emulator'] == 'PASS',
      issues,
      'emulator result must be PASS at emulator stage',
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

class CandidateInputs {
  const CandidateInputs({
    required this.settingsGradle,
    required this.gradleProperties,
    required this.gradleWrapper,
    required this.appBuildGradle,
    required this.issues,
  });

  final String settingsGradle;
  final String gradleProperties;
  final String gradleWrapper;
  final String appBuildGradle;
  final List<String> issues;
}

CandidateInputs migrateCandidateInputs({
  required String settingsGradle,
  required String gradleProperties,
  required String gradleWrapper,
  required String appBuildGradle,
}) {
  final issues = <String>[];
  var settings = _replaceExactlyOnce(
    settingsGradle,
    'id("com.android.application") version "$selectedAgp" apply false',
    'id("com.android.application") version "$candidateAgp" apply false',
    'AGP declaration',
    issues,
  );
  settings = _removeExactlyOnce(
    settings,
    '    id("org.jetbrains.kotlin.android") version "$selectedKotlin" apply false\n',
    'legacy KGP declaration',
    issues,
  );

  var properties = gradleProperties;
  for (final entry in <(String, String)>[
    (
      '# This builtInKotlin flag was added automatically by Flutter migrator\n'
          'android.builtInKotlin=false\n',
      'built-in Kotlin opt-out',
    ),
    (
      '# This newDsl flag was added automatically by Flutter migrator\n'
          'android.newDsl=false\n',
      'new DSL opt-out',
    ),
  ]) {
    properties = _removeExactlyOnce(properties, entry.$1, entry.$2, issues);
  }

  final wrapper = _replaceExactlyOnce(
    gradleWrapper,
    'gradle-$selectedGradle-all.zip',
    'gradle-$candidateGradle-all.zip',
    'Gradle wrapper declaration',
    issues,
  );

  var app = _removeExactlyOnce(
    appBuildGradle,
    '    id("kotlin-android")\n',
    'app KGP application',
    issues,
  );
  app = _removeExactlyOnce(
    app,
    '    kotlinOptions {\n'
        '        jvmTarget = JavaVersion.VERSION_17.toString()\n'
        '    }\n\n',
    'legacy kotlinOptions block',
    issues,
  );
  app = _replaceExactlyOnce(
    app,
    '\nval verifyReleaseSigning = tasks.register("verifyReleaseSigning") {',
    '\nkotlin {\n'
        '    compilerOptions {\n'
        '        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n'
        '    }\n'
        '}\n\n'
        'val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {',
    'built-in Kotlin compiler insertion point',
    issues,
  );

  if (!appBuildGradle.contains('minSdk = flutter.minSdkVersion') ||
      !app.contains('minSdk = flutter.minSdkVersion')) {
    issues.add('candidate source is missing the minSdk declaration');
  }
  if (!settings.contains('version "$candidateAgp"') ||
      settings.contains('org.jetbrains.kotlin.android') ||
      properties.contains('android.builtInKotlin') ||
      properties.contains('android.newDsl') ||
      !wrapper.contains('gradle-$candidateGradle-all.zip') ||
      app.contains('kotlin-android') ||
      app.contains('kotlinOptions') ||
      !app.contains('JvmTarget.JVM_17')) {
    issues.add('candidate transaction is incomplete');
  }
  return CandidateInputs(
    settingsGradle: settings,
    gradleProperties: properties,
    gradleWrapper: wrapper,
    appBuildGradle: app,
    issues: issues,
  );
}

String _replaceExactlyOnce(
  String source,
  String before,
  String after,
  String label,
  List<String> issues,
) {
  if (before.isEmpty || source.split(before).length != 2) {
    issues.add('$label must occur exactly once');
    return source;
  }
  return source.replaceFirst(before, after);
}

String _removeExactlyOnce(
  String source,
  String value,
  String label,
  List<String> issues,
) => _replaceExactlyOnce(source, value, '', label, issues);

Future<T> withDisposableCandidateDirectory<T>(
  Future<T> Function(Directory directory) operation,
) async {
  final directory = Directory.systemTemp.createTempSync(
    'home-pocket-phase61-candidate-',
  );
  try {
    return await operation(directory);
  } finally {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}

String scrubCandidateOutput(String raw) {
  var scrubbed = raw
      .replaceAll(RegExp(r'/Users/[^\s]+'), '<local-path>')
      .replaceAll(RegExp(r'/private/(?:tmp|var)/[^\s]+'), '<temp-path>')
      .replaceAll(RegExp(r'emulator-\d{4}'), '<emulator-redacted>');
  if (scrubbed.length > maxDurableOutputChars) {
    const marker = '\n...<bounded-output>...\n';
    final side = (maxDurableOutputChars - marker.length) ~/ 2;
    scrubbed =
        '${scrubbed.substring(0, side)}$marker'
        '${scrubbed.substring(scrubbed.length - side)}';
  }
  return scrubbed;
}

int? parseJavaMajor(String output) {
  final match = RegExp(r'version\s+"(\d+)').firstMatch(output);
  return match == null ? null : int.tryParse(match.group(1)!);
}

AndroidCertificateClass classifyAndroidCertificate(String subject) =>
    subject.toLowerCase().contains('cn=android debug')
    ? AndroidCertificateClass.debug
    : AndroidCertificateClass.nonDebug;

const _testOnlyArtifactPatterns = <String>[
  'integration_test',
  'integration-test',
  'integrationtestplugin',
  'dev.flutter.integration_test',
];

Future<List<String>> scanAndroidReleaseArtifact(File artifact) async {
  if (!artifact.existsSync()) return const ['release artifact is missing'];
  final findings = <String>[];
  final entries = await Process.run(
    'unzip',
    ['-Z1', artifact.path],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (entries.exitCode != 0) {
    return ['release artifact is not a readable ZIP archive'];
  }
  final entryText = '${entries.stdout}'.toLowerCase();
  for (final pattern in _testOnlyArtifactPatterns) {
    if (entryText.contains(pattern)) {
      findings.add('test-only archive entry found: $pattern');
    }
  }

  final packagedPatterns = await _scanArchiveBytes(
    artifact,
    _testOnlyArtifactPatterns,
  );
  for (final pattern in packagedPatterns) {
    findings.add('test-only packaged content found: $pattern');
  }
  return findings;
}

Future<Set<String>> _scanArchiveBytes(
  File artifact,
  List<String> patterns,
) async {
  final process = await Process.start('unzip', ['-p', artifact.path]);
  final loweredPatterns = patterns
      .map((pattern) => pattern.toLowerCase())
      .toList();
  final found = <String>{};
  final maxPatternLength = loweredPatterns
      .map((pattern) => pattern.length)
      .fold<int>(0, (left, right) => left > right ? left : right);
  var tail = '';
  await for (final chunk in process.stdout) {
    final text = '$tail${latin1.decode(chunk, allowInvalid: true)}'
        .toLowerCase();
    for (final pattern in loweredPatterns) {
      if (text.contains(pattern)) found.add(pattern);
    }
    tail = text.length <= maxPatternLength
        ? text
        : text.substring(text.length - maxPatternLength);
  }
  await process.stderr.drain<void>();
  final code = await process.exitCode;
  if (code != 0) found.add('unreadable-archive-content');
  return found;
}

class BoundedCommandResult {
  const BoundedCommandResult({
    required this.command,
    required this.exitCode,
    required this.output,
    required this.timedOut,
  });

  final String command;
  final int exitCode;
  final String output;
  final bool timedOut;
}

class CandidateProbeResult {
  const CandidateProbeResult({required this.completed, required this.message});

  final bool completed;
  final String message;
}

class ReleaseEvidenceResult {
  const ReleaseEvidenceResult({required this.completed, required this.message});

  final bool completed;
  final String message;
}

class _ReleaseArtifactResult {
  const _ReleaseArtifactResult({
    required this.kind,
    required this.sha256,
    required this.sizeBytes,
    required this.certificateSubject,
    required this.certificateFingerprint,
    required this.signatureTool,
    required this.hygiene,
  });

  final String kind;
  final String sha256;
  final int sizeBytes;
  final String certificateSubject;
  final String certificateFingerprint;
  final String signatureTool;
  final String hygiene;
}

Future<ReleaseEvidenceResult> runReleaseEvidence(Directory root) async {
  final jdkHome = _resolveJdk17Home();
  final flutterRoot = _flutterRoot();
  final androidSdk = _androidSdkRoot();
  if (jdkHome == null || flutterRoot == null || androidSdk == null) {
    return const ReleaseEvidenceResult(
      completed: false,
      message: 'verified JDK 17, Flutter, or Android SDK is unavailable',
    );
  }
  final apksigner = _latestBuildTool(androidSdk, 'apksigner');
  final aapt = _latestBuildTool(androidSdk, 'aapt');
  if (apksigner == null || aapt == null) {
    return const ReleaseEvidenceResult(
      completed: false,
      message: 'Android apksigner or aapt is unavailable',
    );
  }

  final sourceCommit = _gitOutput(root, ['rev-parse', 'HEAD']);
  final started = DateTime.now().toUtc();
  final outputArtifacts = _releaseArtifactFiles(root);
  BoundedCommandResult? missingNegative;
  BoundedCommandResult? debugNegative;
  BoundedCommandResult? packaging;
  BoundedCommandResult? apkSignature;
  BoundedCommandResult? aabSignature;
  BoundedCommandResult? aabCertificate;
  BoundedCommandResult? apkMetadata;
  List<_ReleaseArtifactResult>? artifacts;
  Map<String, String>? metadata;
  String? failure;

  try {
    await withDisposableCandidateDirectory((temporary) async {
      final debugPassword = _randomSecret();
      final evidencePassword = _randomSecret();
      final debugKey = File('${temporary.path}/debug-evidence.p12');
      final evidenceKey = File('${temporary.path}/release-evidence.p12');
      final debugKeytool = await _generateEvidenceKey(
        jdkHome: jdkHome,
        workingDirectory: root,
        output: debugKey,
        password: debugPassword,
        alias: 'phase61debug',
        distinguishedName: 'CN=Android Debug,O=Android,C=US',
        durableLabel: 'debug certificate',
      );
      if (debugKeytool.exitCode != 0) {
        throw StateError('temporary debug certificate generation failed');
      }
      final evidenceKeytool = await _generateEvidenceKey(
        jdkHome: jdkHome,
        workingDirectory: root,
        output: evidenceKey,
        password: evidencePassword,
        alias: 'phase61evidence',
        distinguishedName:
            'CN=Happy Pocket Phase 61 Evidence,O=Happy Pocket,C=JP',
        durableLabel: 'non-debug evidence certificate',
      );
      if (evidenceKeytool.exitCode != 0) {
        throw StateError('temporary evidence certificate generation failed');
      }

      final gradleArguments = <String>[
        '--no-daemon',
        '-Dorg.gradle.java.home=$jdkHome',
        '-Pphase61SigningEvidence=true',
        ':app:verifyReleaseSigning',
      ];
      missingNegative = await runBoundedCommand(
        './gradlew',
        gradleArguments,
        workingDirectory: Directory('${root.path}/android'),
        environment: _signingEnvironment(
          jdkHome: jdkHome,
          keyPath: '',
          password: '',
          alias: '',
        ),
        durableCommand:
            './gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (credentials absent)',
      );
      if (missingNegative!.exitCode == 0 ||
          !missingNegative!.output.contains(
            'Android release signing is not configured',
          )) {
        throw StateError('missing release credentials were not rejected');
      }

      debugNegative = await runBoundedCommand(
        './gradlew',
        gradleArguments,
        workingDirectory: Directory('${root.path}/android'),
        environment: _signingEnvironment(
          jdkHome: jdkHome,
          keyPath: debugKey.path,
          password: debugPassword,
          alias: 'phase61debug',
        ),
        durableCommand:
            './gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (Android Debug certificate)',
      );
      if (debugNegative!.exitCode == 0 ||
          !debugNegative!.output.contains(
            'Android release signing certificate is the Android Debug certificate',
          )) {
        throw StateError('Android Debug certificate was not rejected');
      }

      packaging = await runBoundedCommand(
        'bash',
        const [
          'scripts/release_preflight.sh',
          '--platform',
          'android',
          '--package',
        ],
        workingDirectory: root,
        environment: {
          ..._signingEnvironment(
            jdkHome: jdkHome,
            keyPath: evidenceKey.path,
            password: evidencePassword,
            alias: 'phase61evidence',
          ),
          'PHASE61_GRADLE_JAVA_HOME': jdkHome,
          'ANDROID_HOME': androidSdk,
          'ANDROID_SDK_ROOT': androidSdk,
          'PATH': '$flutterRoot/bin:${Platform.environment['PATH'] ?? ''}',
        },
        timeout: const Duration(minutes: 30),
        durableCommand:
            'bash scripts/release_preflight.sh --platform android --package (ephemeral non-debug evidence certificate)',
      );
      if (packaging!.exitCode != 0) {
        throw StateError(
          'dual release packaging failed: ${_diagnosticLine(packaging!.output)}',
        );
      }

      final aab = outputArtifacts['aab']!;
      final apk = outputArtifacts['apk']!;
      if (!aab.existsSync() || !apk.existsSync()) {
        throw StateError(
          'dual release packaging did not produce both artifacts',
        );
      }
      final aabFindings = await scanAndroidReleaseArtifact(aab);
      final apkFindings = await scanAndroidReleaseArtifact(apk);
      if (aabFindings.isNotEmpty || apkFindings.isNotEmpty) {
        throw StateError(
          'release artifact hygiene failed: ${[...aabFindings, ...apkFindings].join('; ')}',
        );
      }
      final registrant = File(
        '${root.path}/android/app/src/main/java/io/flutter/plugins/'
        'GeneratedPluginRegistrant.java',
      );
      if (!registrant.existsSync() ||
          _testOnlyArtifactPatterns.any(
            (pattern) =>
                registrant.readAsStringSync().toLowerCase().contains(pattern),
          )) {
        throw StateError('clean Android release registrant hygiene failed');
      }

      final signatureEnvironment = <String, String>{
        'JAVA_HOME': jdkHome,
        'ANDROID_HOME': androidSdk,
        'ANDROID_SDK_ROOT': androidSdk,
      };
      apkSignature = await runBoundedCommand(
        apksigner,
        ['verify', '--verbose', '--print-certs', apk.path],
        workingDirectory: root,
        environment: signatureEnvironment,
        durableCommand:
            'apksigner verify --verbose --print-certs app-release.apk',
      );
      if (apkSignature!.exitCode != 0) {
        throw StateError('APK signature verification failed');
      }
      aabSignature = await runBoundedCommand(
        '$jdkHome/bin/jarsigner',
        ['-verify', '-verbose', '-certs', aab.path],
        workingDirectory: root,
        environment: signatureEnvironment,
        durableCommand: 'jarsigner -verify -verbose -certs app-release.aab',
      );
      if (aabSignature!.exitCode != 0 ||
          !aabSignature!.output.toLowerCase().contains('jar verified')) {
        throw StateError('AAB JAR signature verification failed');
      }
      aabCertificate = await runBoundedCommand(
        '$jdkHome/bin/keytool',
        ['-printcert', '-jarfile', aab.path],
        workingDirectory: root,
        environment: signatureEnvironment,
        durableCommand: 'keytool -printcert -jarfile app-release.aab',
      );
      if (aabCertificate!.exitCode != 0) {
        throw StateError('AAB certificate inspection failed');
      }

      final apkSubject = _firstMatch(
        apkSignature!.output,
        RegExp(r'Signer #1 certificate DN:\s*(.+)', caseSensitive: false),
      );
      final apkFingerprint = _normalizeFingerprint(
        _firstMatch(
          apkSignature!.output,
          RegExp(
            r'Signer #1 certificate SHA-256 digest:\s*([0-9a-f:]+)',
            caseSensitive: false,
          ),
        ),
      );
      final aabSubject = _firstMatch(
        aabCertificate!.output,
        RegExp(r'Owner:\s*(.+)', caseSensitive: false),
      );
      final aabFingerprint = _normalizeFingerprint(
        _firstMatch(
          aabCertificate!.output,
          RegExp(r'SHA256:\s*([0-9a-f:]+)', caseSensitive: false),
        ),
      );
      if (apkSubject == null ||
          aabSubject == null ||
          apkFingerprint == null ||
          aabFingerprint == null ||
          apkFingerprint != aabFingerprint ||
          classifyAndroidCertificate(apkSubject) !=
              AndroidCertificateClass.nonDebug ||
          classifyAndroidCertificate(aabSubject) !=
              AndroidCertificateClass.nonDebug) {
        throw StateError(
          'release certificate identity is missing, debug, or inconsistent',
        );
      }

      apkMetadata = await runBoundedCommand(
        aapt,
        ['dump', 'badging', apk.path],
        workingDirectory: root,
        environment: signatureEnvironment,
        durableCommand: 'aapt dump badging app-release.apk',
      );
      if (apkMetadata!.exitCode != 0) {
        throw StateError('APK package metadata inspection failed');
      }
      metadata = _parseApkBadging(apkMetadata!.output);
      if (metadata!['application_id'] != 'com.sheanzero.happypocket.app' ||
          metadata!['version_name'] != '0.1.0' ||
          metadata!['version_code'] != '1' ||
          metadata!['min_sdk'] != '24' ||
          metadata!['target_sdk'] != '36') {
        throw StateError(
          'release package/version/platform metadata is unexpected',
        );
      }
      final aabManifest = await Process.run(
        'unzip',
        ['-p', aab.path, 'base/manifest/AndroidManifest.xml'],
        stdoutEncoding: latin1,
        stderrEncoding: utf8,
      );
      final aabManifestText = '${aabManifest.stdout}';
      if (aabManifest.exitCode != 0 ||
          !aabManifestText.contains(metadata!['application_id']!) ||
          !aabManifestText.contains(metadata!['version_name']!)) {
        throw StateError(
          'AAB embedded manifest metadata does not match the APK',
        );
      }

      artifacts = [
        _ReleaseArtifactResult(
          kind: 'release_aab',
          sha256: sha256.convert(aab.readAsBytesSync()).toString(),
          sizeBytes: aab.lengthSync(),
          certificateSubject: 'CN=Happy Pocket Phase 61 Evidence',
          certificateFingerprint: aabFingerprint,
          signatureTool: 'jarsigner + keytool',
          hygiene: 'PASS',
        ),
        _ReleaseArtifactResult(
          kind: 'release_apk',
          sha256: sha256.convert(apk.readAsBytesSync()).toString(),
          sizeBytes: apk.lengthSync(),
          certificateSubject: 'CN=Happy Pocket Phase 61 Evidence',
          certificateFingerprint: apkFingerprint,
          signatureTool: 'apksigner',
          hygiene: 'PASS',
        ),
      ];
    });
  } on Object catch (error) {
    failure = scrubCandidateOutput('$error');
  } finally {
    _deleteReleaseArtifacts(outputArtifacts.values);
    final kotlinCache = Directory('${root.path}/android/.kotlin');
    if (kotlinCache.existsSync()) kotlinCache.deleteSync(recursive: true);
  }

  if (failure != null ||
      missingNegative == null ||
      debugNegative == null ||
      packaging == null ||
      apkSignature == null ||
      aabSignature == null ||
      aabCertificate == null ||
      apkMetadata == null ||
      artifacts == null ||
      metadata == null) {
    return ReleaseEvidenceResult(
      completed: false,
      message: failure ?? 'release evidence execution was incomplete',
    );
  }

  _recordReleaseEvidence(
    root: root,
    sourceCommit: sourceCommit,
    started: started,
    completed: DateTime.now().toUtc(),
    missingNegative: missingNegative!,
    debugNegative: debugNegative!,
    packaging: packaging!,
    apkSignature: apkSignature!,
    aabSignature: aabSignature!,
    aabCertificate: aabCertificate!,
    apkMetadata: apkMetadata!,
    artifacts: artifacts!,
    metadata: metadata!,
  );
  return const ReleaseEvidenceResult(
    completed: true,
    message:
        'PASS: missing/debug signing rejected; ephemeral non-debug AAB/APK signatures and hygiene verified',
  );
}

Future<BoundedCommandResult> _generateEvidenceKey({
  required String jdkHome,
  required Directory workingDirectory,
  required File output,
  required String password,
  required String alias,
  required String distinguishedName,
  required String durableLabel,
}) => runBoundedCommand(
  '$jdkHome/bin/keytool',
  [
    '-genkeypair',
    '-keystore',
    output.path,
    '-storepass',
    password,
    '-keypass',
    password,
    '-alias',
    alias,
    '-dname',
    distinguishedName,
    '-keyalg',
    'RSA',
    '-keysize',
    '2048',
    '-validity',
    '30',
    '-storetype',
    'PKCS12',
    '-noprompt',
  ],
  workingDirectory: workingDirectory,
  durableCommand: 'keytool -genkeypair <$durableLabel; credentials redacted>',
);

Map<String, String> _signingEnvironment({
  required String jdkHome,
  required String keyPath,
  required String password,
  required String alias,
}) => {
  'JAVA_HOME': jdkHome,
  'ANDROID_KEYSTORE_PATH': keyPath,
  'ANDROID_KEYSTORE_PASSWORD': password,
  'ANDROID_KEY_ALIAS': alias,
  'ANDROID_KEY_PASSWORD': password,
};

String _randomSecret() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String? _latestBuildTool(String androidSdk, String tool) {
  final root = Directory('$androidSdk/build-tools');
  if (!root.existsSync()) return null;
  final candidates =
      root
          .listSync()
          .whereType<Directory>()
          .map((directory) => File('${directory.path}/$tool'))
          .where((file) => file.existsSync())
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  return candidates.isEmpty ? null : candidates.last.path;
}

Map<String, File> _releaseArtifactFiles(Directory root) => {
  'aab': File('${root.path}/build/app/outputs/bundle/release/app-release.aab'),
  'apk': File('${root.path}/build/app/outputs/apk/release/app-release.apk'),
};

void _deleteReleaseArtifacts(Iterable<File> artifacts) {
  for (final artifact in artifacts) {
    if (artifact.existsSync()) artifact.deleteSync();
  }
}

String? _firstMatch(String source, RegExp pattern) =>
    pattern.firstMatch(source)?.group(1)?.trim();

String? _normalizeFingerprint(String? value) =>
    value?.replaceAll(':', '').toLowerCase();

Map<String, String> _parseApkBadging(String output) {
  final package = RegExp(
    r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",
  ).firstMatch(output);
  final minSdk = RegExp(r"sdkVersion:'([^']+)'").firstMatch(output);
  final targetSdk = RegExp(r"targetSdkVersion:'([^']+)'").firstMatch(output);
  return {
    'application_id': package?.group(1) ?? '',
    'version_code': package?.group(2) ?? '',
    'version_name': package?.group(3) ?? '',
    'min_sdk': minSdk?.group(1) ?? '',
    'target_sdk': targetSdk?.group(1) ?? '',
  };
}

void _recordReleaseEvidence({
  required Directory root,
  required String sourceCommit,
  required DateTime started,
  required DateTime completed,
  required BoundedCommandResult missingNegative,
  required BoundedCommandResult debugNegative,
  required BoundedCommandResult packaging,
  required BoundedCommandResult apkSignature,
  required BoundedCommandResult aabSignature,
  required BoundedCommandResult aabCertificate,
  required BoundedCommandResult apkMetadata,
  required List<_ReleaseArtifactResult> artifacts,
  required Map<String, String> metadata,
}) {
  final file = File('${root.path}/$evidencePath');
  final markdown = file.readAsStringSync();
  final issues = <String>[];
  final evidence = parseEvidenceMarkdown(markdown, issues);
  if (issues.isNotEmpty) throw StateError(issues.join('; '));
  evidence['completed_stage'] = 'package';
  evidence['source_commit'] = sourceCommit;
  evidence['package_source_commit'] = sourceCommit;
  evidence['package_started_utc'] = started.toIso8601String();
  evidence['package_completed_utc'] = completed.toIso8601String();
  evidence['completed_utc'] = completed.toIso8601String();
  final results = _object(evidence['results']);
  results['package'] = 'PASS';
  evidence['results'] = results;
  evidence['release_signing_negatives'] = {
    'missing_credentials': {
      'result': 'REJECTED_AS_REQUIRED',
      'exit_code': missingNegative.exitCode,
    },
    'android_debug_certificate': {
      'result': 'REJECTED_AS_REQUIRED',
      'exit_code': debugNegative.exitCode,
    },
  };
  evidence['release_package_metadata'] = metadata;
  evidence['commands'] = [
    ...(_objectList(evidence['commands'])),
    _commandEvidence(missingNegative),
    _commandEvidence(debugNegative),
    _commandEvidence(packaging),
    _commandEvidence(apkSignature),
    _commandEvidence(aabSignature),
    _commandEvidence(aabCertificate),
    _commandEvidence(apkMetadata),
  ];
  evidence['artifacts'] = artifacts
      .map(
        (artifact) => {
          'kind': artifact.kind,
          'sha256': artifact.sha256,
          'size_bytes': artifact.sizeBytes,
          'certificate_class': 'NON_DEBUG_EPHEMERAL_EVIDENCE',
          'certificate_subject': artifact.certificateSubject,
          'certificate_sha256': artifact.certificateFingerprint,
          'signature_tool': artifact.signatureTool,
          'archive_and_content_hygiene': artifact.hygiene,
          'durable_artifact_retained': false,
        },
      )
      .toList();
  evidence['release_cleanup'] = {
    'private_key_material': 'ABSENT',
    'release_aab': 'DELETED_AFTER_EVIDENCE',
    'release_apk': 'DELETED_AFTER_EVIDENCE',
    'repository_secret_or_artifact': 'ABSENT',
  };
  final rendered = const JsonEncoder.withIndent('  ').convert(evidence);
  final start = markdown.indexOf(_evidenceStart) + _evidenceStart.length;
  final end = markdown.indexOf(_evidenceEnd);
  file.writeAsStringSync(
    '${markdown.substring(0, start)}\n```json\n$rendered\n```\n${markdown.substring(end)}',
  );
}

List<Map<String, Object?>> _objectList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList()
    : const [];

Future<BoundedCommandResult> runBoundedCommand(
  String executable,
  List<String> arguments, {
  required Directory workingDirectory,
  Map<String, String>? environment,
  Duration timeout = const Duration(minutes: 10),
  String? durableCommand,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
    environment: environment,
    includeParentEnvironment: true,
  );
  final output = _BoundedOutputBuffer(maxDurableOutputChars * 2);
  final drains = <Future<void>>[
    process.stdout.transform(utf8.decoder).forEach(output.add),
    process.stderr.transform(utf8.decoder).forEach(output.add),
  ];
  var timedOut = false;
  int code;
  try {
    code = await process.exitCode.timeout(timeout);
  } on TimeoutException {
    timedOut = true;
    process.kill(ProcessSignal.sigterm);
    code = await process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return 124;
      },
    );
  }
  await Future.wait(drains);
  return BoundedCommandResult(
    command:
        durableCommand ??
        '${executable.split('/').last} ${arguments.join(' ')}',
    exitCode: timedOut ? 124 : code,
    output: scrubCandidateOutput(output.value),
    timedOut: timedOut,
  );
}

class _BoundedOutputBuffer {
  _BoundedOutputBuffer(this.limit);

  final int limit;
  final StringBuffer _buffer = StringBuffer();
  int _length = 0;

  void add(String chunk) {
    if (_length >= limit) return;
    final remaining = limit - _length;
    final kept = chunk.length <= remaining
        ? chunk
        : chunk.substring(0, remaining);
    _buffer.write(kept);
    _length += kept.length;
  }

  String get value => _buffer.toString();
}

Future<CandidateProbeResult> runCandidateProbe(Directory root) async {
  final started = DateTime.now().toUtc();
  final before = trackedAndroidInputDigests(root);
  final pluginBefore = legacyKgpPluginInputDigests(root);
  final legacyPlugins = inventoryLegacyKgpPlugins(root);
  if (legacyPlugins.isEmpty) {
    return const CandidateProbeResult(
      completed: false,
      message: 'legacy KGP inventory unexpectedly empty before candidate probe',
    );
  }

  final jdkHome = _resolveJdk17Home();
  if (jdkHome == null) {
    return const CandidateProbeResult(
      completed: false,
      message: 'verified JDK 17 not found; set PHASE61_JAVA_HOME',
    );
  }
  final java = await runBoundedCommand(
    '$jdkHome/bin/java',
    const ['-version'],
    workingDirectory: root,
    durableCommand: 'java -version',
  );
  if (java.exitCode != 0 || parseJavaMajor(java.output) != 17) {
    return CandidateProbeResult(
      completed: false,
      message: 'candidate JDK check failed: ${java.output}',
    );
  }

  final flutterRoot = _flutterRoot();
  final androidSdk = _androidSdkRoot();
  if (flutterRoot == null || androidSdk == null) {
    return const CandidateProbeResult(
      completed: false,
      message: 'Flutter or Android SDK root is unavailable',
    );
  }

  BoundedCommandResult? pubGet;
  BoundedCommandResult? configuration;
  bool flagsRestored = false;
  String? operationError;
  try {
    await withDisposableCandidateDirectory((temporary) async {
      final archive = File('${temporary.path}/source.tar');
      final archiveResult = await Process.run('git', [
        'archive',
        '--format=tar',
        '-o',
        archive.path,
        'HEAD',
      ], workingDirectory: root.path);
      if (archiveResult.exitCode != 0) {
        throw StateError('git archive failed');
      }
      final extract = await Process.run('tar', [
        '-xf',
        archive.path,
        '-C',
        temporary.path,
      ]);
      archive.deleteSync();
      if (extract.exitCode != 0) throw StateError('archive extraction failed');

      final migrated = migrateCandidateInputs(
        settingsGradle: File(
          '${temporary.path}/android/settings.gradle.kts',
        ).readAsStringSync(),
        gradleProperties: File(
          '${temporary.path}/android/gradle.properties',
        ).readAsStringSync(),
        gradleWrapper: File(
          '${temporary.path}/android/gradle/wrapper/gradle-wrapper.properties',
        ).readAsStringSync(),
        appBuildGradle: File(
          '${temporary.path}/android/app/build.gradle.kts',
        ).readAsStringSync(),
      );
      if (migrated.issues.isNotEmpty) {
        throw StateError(migrated.issues.join('; '));
      }
      File(
        '${temporary.path}/android/settings.gradle.kts',
      ).writeAsStringSync(migrated.settingsGradle);
      File(
        '${temporary.path}/android/gradle.properties',
      ).writeAsStringSync(migrated.gradleProperties);
      File(
        '${temporary.path}/android/gradle/wrapper/gradle-wrapper.properties',
      ).writeAsStringSync(migrated.gradleWrapper);
      File(
        '${temporary.path}/android/app/build.gradle.kts',
      ).writeAsStringSync(migrated.appBuildGradle);
      File('${temporary.path}/android/local.properties').writeAsStringSync(
        'sdk.dir=${_escapePropertiesPath(androidSdk)}\n'
        'flutter.sdk=${_escapePropertiesPath(flutterRoot)}\n',
      );

      final environment = <String, String>{
        'JAVA_HOME': jdkHome,
        'ANDROID_SDK_ROOT': androidSdk,
        'ANDROID_HOME': androidSdk,
        'CI': 'true',
      };
      pubGet = await runBoundedCommand(
        '$flutterRoot/bin/flutter',
        const ['pub', 'get', '--enforce-lockfile'],
        workingDirectory: temporary,
        environment: environment,
        durableCommand: 'flutter pub get --enforce-lockfile',
      );
      if (pubGet!.exitCode != 0) {
        throw StateError('locked dependency retrieval failed');
      }
      configuration = await runBoundedCommand(
        '$flutterRoot/bin/flutter',
        const ['build', 'apk', '--debug', '--config-only'],
        workingDirectory: temporary,
        environment: environment,
        durableCommand: 'flutter build apk --debug --config-only',
      );
      final properties = File(
        '${temporary.path}/android/gradle.properties',
      ).readAsStringSync();
      flagsRestored =
          properties.contains('android.builtInKotlin=false') ||
          properties.contains('android.newDsl=false');
    });
  } on Object catch (error) {
    operationError = scrubCandidateOutput('$error');
  }

  final after = trackedAndroidInputDigests(root);
  final pluginAfter = legacyKgpPluginInputDigests(root);
  if (!_sameDigests(before, after) ||
      !_sameDigests(pluginBefore, pluginAfter)) {
    return const CandidateProbeResult(
      completed: false,
      message:
          'source or resolved plugin input digest changed during candidate probe',
    );
  }
  if (pubGet == null || pubGet!.exitCode != 0) {
    return CandidateProbeResult(
      completed: false,
      message: operationError ?? 'candidate dependency preparation unavailable',
    );
  }
  if (configuration == null) {
    return CandidateProbeResult(
      completed: false,
      message: operationError ?? 'candidate configuration did not run',
    );
  }

  final incompatible = flagsRestored || configuration!.exitCode != 0;
  final diagnostic = flagsRestored
      ? 'Flutter configuration restored the legacy built-in-Kotlin/new-DSL opt-outs.'
      : _diagnosticLine(configuration!.output);
  _recordCandidateEvidence(
    root: root,
    started: started,
    java: java,
    pubGet: pubGet!,
    configuration: configuration!,
    legacyPlugins: legacyPlugins,
    incompatible: incompatible || legacyPlugins.isNotEmpty,
    diagnostic: diagnostic,
  );
  return CandidateProbeResult(
    completed: true,
    message:
        'PASS: disposable candidate probe completed; '
        'terminal result is ${incompatible || legacyPlugins.isNotEmpty ? 'INCOMPATIBLE' : 'PASS'}',
  );
}

Map<String, String> trackedAndroidInputDigests(Directory root) {
  const paths = [
    '.metadata',
    'pubspec.yaml',
    'pubspec.lock',
    'android/settings.gradle.kts',
    'android/gradle.properties',
    'android/gradle/wrapper/gradle-wrapper.properties',
    'android/app/build.gradle.kts',
  ];
  return {
    for (final path in paths)
      path: sha256
          .convert(File('${root.path}/$path').readAsBytesSync())
          .toString(),
  };
}

Map<String, String> legacyKgpPluginInputDigests(Directory root) {
  final dependencyFile = File('${root.path}/.flutter-plugins-dependencies');
  if (!dependencyFile.existsSync()) return const {};
  final decoded = jsonDecode(dependencyFile.readAsStringSync());
  if (decoded is! Map) return const {};
  final plugins = _object(decoded.cast<String, Object?>()['plugins']);
  final android = plugins['android'];
  if (android is! List) return const {};
  final digests = <String, String>{};
  for (final raw in android) {
    if (raw is! Map) continue;
    final row = raw.cast<String, Object?>();
    final name = '${row['name'] ?? ''}';
    final path = '${row['path'] ?? ''}';
    if (name.isEmpty || path.isEmpty) continue;
    for (final fileName in ['build.gradle', 'build.gradle.kts']) {
      final file = File('$path/android/$fileName');
      if (file.existsSync()) {
        digests['$name/$fileName'] = sha256
            .convert(file.readAsBytesSync())
            .toString();
      }
    }
  }
  return digests;
}

bool _sameDigests(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

String? _resolveJdk17Home() {
  final candidates = <String?>[
    Platform.environment['PHASE61_JAVA_HOME'],
    Platform.environment['JAVA_HOME'],
    '/private/tmp/phase61-jdk17/Contents/Home',
    '/private/tmp/phase61-jdk17',
  ];
  for (final candidate in candidates) {
    if (candidate != null && File('$candidate/bin/java').existsSync()) {
      return candidate;
    }
  }
  return null;
}

String? _flutterRoot() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    if (File('${directory.path}/bin/flutter').existsSync() &&
        Directory('${directory.path}/packages/flutter_tools').existsSync()) {
      return directory.path;
    }
    directory = directory.parent;
  }
  return null;
}

String? _androidSdkRoot() {
  for (final candidate in <String?>[
    Platform.environment['ANDROID_SDK_ROOT'],
    Platform.environment['ANDROID_HOME'],
    '${Platform.environment['HOME']}/Library/Android/sdk',
  ]) {
    if (candidate != null && Directory(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

String _escapePropertiesPath(String path) => path.replaceAll('\\', '\\\\');

String _diagnosticLine(String output) {
  for (final line in output.split('\n').reversed) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
    }
  }
  return 'Candidate command produced no diagnostic output.';
}

void _recordCandidateEvidence({
  required Directory root,
  required DateTime started,
  required BoundedCommandResult java,
  required BoundedCommandResult pubGet,
  required BoundedCommandResult configuration,
  required List<String> legacyPlugins,
  required bool incompatible,
  required String diagnostic,
}) {
  final file = File('${root.path}/$evidencePath');
  final markdown = file.readAsStringSync();
  final issues = <String>[];
  final evidence = parseEvidenceMarkdown(markdown, issues);
  if (issues.isNotEmpty) throw StateError(issues.join('; '));
  evidence['completed_stage'] = 'candidate';
  evidence['source_commit'] = _gitOutput(root, ['rev-parse', 'HEAD']);
  evidence['started_utc'] = started.toIso8601String();
  evidence['completed_utc'] = DateTime.now().toUtc().toIso8601String();
  evidence['host_os'] = _hostOs();
  evidence['plugin_legacy_kgp_inventory'] = legacyPlugins;
  evidence['candidate_observation'] = diagnostic;
  evidence['candidate_output_sha256'] = sha256Text(configuration.output);
  evidence['blocker'] = <String, Object?>{
    'component': 'Flutter 3.44.8 and resolved legacy-KGP plugin graph',
    'official_source':
        'https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers',
    'reproduction':
        '${configuration.command} (exit ${configuration.exitCode}); $diagnostic',
    'exit_condition':
        'Upgrade Flutter through a reviewed identity transaction to 3.47 or later and select Phase 59-approved plugin releases whose Android modules no longer apply legacy KGP, then rerun the complete candidate transaction.',
  };
  final results = _object(evidence['results']);
  results['candidate'] = incompatible ? 'INCOMPATIBLE' : 'PASS';
  evidence['results'] = results;
  evidence['commands'] = [
    _commandEvidence(java),
    _commandEvidence(pubGet),
    _commandEvidence(configuration),
  ];
  evidence['clean_tree'] =
      'PASS: source and resolved-plugin input digests unchanged';
  final rendered = const JsonEncoder.withIndent('  ').convert(evidence);
  final start = markdown.indexOf(_evidenceStart) + _evidenceStart.length;
  final end = markdown.indexOf(_evidenceEnd);
  file.writeAsStringSync(
    '${markdown.substring(0, start)}\n```json\n$rendered\n```\n${markdown.substring(end)}',
  );
}

Map<String, Object?> _commandEvidence(BoundedCommandResult result) => {
  'command': result.command,
  'exit_code': result.exitCode,
  'timed_out': result.timedOut,
};

String _gitOutput(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(' ')} failed');
  }
  return '${result.stdout}'.trim();
}

String _hostOs() {
  final version = Process.runSync('sw_vers', const ['-productVersion']);
  final architecture = Process.runSync('uname', const ['-m']);
  final versionValue = version.exitCode == 0
      ? '${version.stdout}'.trim()
      : 'unknown';
  final architectureValue = architecture.exitCode == 0
      ? '${architecture.stdout}'.trim()
      : 'unknown';
  return 'macOS $versionValue $architectureValue';
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
