/// The sole Phase 62 release-lock verdict authority.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'release_gate/models.dart';
import 'release_gate/process_adapter.dart';
import 'release_gate/execution.dart';
import 'release_gate/ios_simulator_stage.dart';
import 'verify_android_safety_lane.dart' as android_lane;
import 'release_gate/report.dart';

export 'release_gate/models.dart'
    show ReleaseGateRetry, ReleaseVerdict, validateResume;
export 'release_gate/execution.dart'
    show
        FailureClass,
        HostExecutionGraph,
        ReleaseExecutionGraph,
        ResumeCheckpoint,
        RetryDecision,
        classifyFailure,
        earliestInvalidatedStage;

const _prerequisiteCommand = <String>[
  'bash',
  'scripts/verify_codegen_reproducibility.sh',
];
const _rawArtifactRoot = 'build/release_gate/';
const _attestationMetadataPath = 'docs/testing/RELEASE_COMPATIBILITY.md';
const _gateTimeout = Duration(minutes: 20);
const _additionalCandidateInputs = <String>{
  'docs/testing/STABLE_BASELINE.json',
  'scripts/verify_codegen_reproducibility.sh',
  'scripts/release_gate.dart',
  'scripts/release_gate/models.dart',
  'scripts/release_gate/execution.dart',
  'scripts/release_gate/process_adapter.dart',
  '.github/workflows/audit.yml',
  '.github/workflows/device-e2e.yml',
};

/// RPT-A grants metadata treatment to one report path only. The raw evidence
/// root is ignored and never becomes a candidate input; every other path is in
/// candidate scope.
bool isCandidateScopedPath(String path) =>
    path != _attestationMetadataPath && !path.startsWith(_rawArtifactRoot);

class ReleaseGateOptions {
  const ReleaseGateOptions({
    required this.scope,
    required this.resultPath,
    required this.resume,
    this.failureFix,
  });

  final String scope;
  final String resultPath;
  final bool resume;
  final FailureFixRecord? failureFix;
}

/// The two device adapters are injected only for deterministic tests. The
/// repository owns their default construction and no adapter returns a verdict.
class ReleaseGatePlatformAdapters {
  const ReleaseGatePlatformAdapters({
    required this.runIos,
    required this.runAndroid,
  });

  final Future<IosSimulatorEvidence> Function(
    CandidateFingerprint candidate,
    Map<String, IosAllowedSkip> skips,
  )
  runIos;
  final Future<android_lane.Phase62AndroidEvidence> Function(
    CandidateFingerprint candidate,
  )
  runAndroid;
}

ReleaseGateOptions parseReleaseGateOptions(List<String> arguments) {
  String? scope;
  String? resultPath;
  var resume = false;
  var recordFix = false;
  String? fixStage;
  String? failureSummary;
  String? finalFix;
  bool? candidateChanged;
  String? rerunOutcome;
  for (final argument in arguments) {
    if (argument.startsWith('--scope=')) {
      if (scope != null) throw ArgumentError('scope supplied more than once');
      scope = argument.substring('--scope='.length);
    } else if (argument.startsWith('--result=')) {
      if (resultPath != null) {
        throw ArgumentError('result supplied more than once');
      }
      resultPath = argument.substring('--result='.length);
    } else if (argument == '--resume') {
      if (resume) throw ArgumentError('resume supplied more than once');
      resume = true;
    } else if (argument == '--record-fix') {
      if (recordFix) {
        throw ArgumentError('record-fix supplied more than once');
      }
      recordFix = true;
    } else if (argument.startsWith('--fix-stage=')) {
      if (fixStage != null) {
        throw ArgumentError('fix-stage supplied more than once');
      }
      fixStage = argument.substring('--fix-stage='.length);
    } else if (argument.startsWith('--failure-summary=')) {
      if (failureSummary != null) {
        throw ArgumentError('failure-summary supplied more than once');
      }
      failureSummary = argument.substring('--failure-summary='.length);
    } else if (argument.startsWith('--final-fix=')) {
      if (finalFix != null) {
        throw ArgumentError('final-fix supplied more than once');
      }
      finalFix = argument.substring('--final-fix='.length);
    } else if (argument.startsWith('--candidate-changed=')) {
      if (candidateChanged != null) {
        throw ArgumentError('candidate-changed supplied more than once');
      }
      candidateChanged = switch (argument.substring(
        '--candidate-changed='.length,
      )) {
        'true' => true,
        'false' => false,
        _ => throw ArgumentError('candidate-changed must be true or false'),
      };
    } else if (argument.startsWith('--complete-rerun=')) {
      if (rerunOutcome != null) {
        throw ArgumentError('complete-rerun supplied more than once');
      }
      rerunOutcome = argument.substring('--complete-rerun='.length);
    } else {
      throw ArgumentError('unknown argument: $argument');
    }
  }
  if (recordFix) {
    final record = FailureFixRecord(
      stage: fixStage ?? '',
      failureSummary: failureSummary ?? '',
      finalFix: finalFix ?? '',
      candidateChanged: candidateChanged ?? false,
      completeRerunOutcome: rerunOutcome ?? '',
    );
    if (scope != null ||
        resume ||
        resultPath == null ||
        !_isRawArtifactPath(resultPath) ||
        !record.isComplete ||
        validateEvidencePrivacy(record.toJson()).isNotEmpty) {
      throw ArgumentError(
        'record-fix requires --result plus fix-stage, failure-summary, final-fix, candidate-changed, and complete-rerun facts',
      );
    }
    return ReleaseGateOptions(
      scope: 'record-fix',
      resultPath: resultPath,
      resume: false,
      failureFix: record,
    );
  }
  if ((scope != 'tracer' && scope != 'host' && scope != 'full') ||
      resultPath == null ||
      !_isRawArtifactPath(resultPath)) {
    throw ArgumentError(
      'usage: --scope=tracer|host|full [--resume] '
      '--result=build/release_gate/<name>.json',
    );
  }
  return ReleaseGateOptions(
    scope: scope!,
    resultPath: resultPath,
    resume: resume,
  );
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseReleaseGateOptions(arguments);
    if (options.failureFix case final record?) {
      await recordFailureFix(
        root: Directory.current,
        resultPath: options.resultPath,
        candidate: validateCandidate(Directory.current),
        record: record,
      );
      stdout.writeln('RECORDED');
      return;
    }
    if (options.resume && options.scope == 'tracer') {
      throw ArgumentError('resume requires the host or full execution graph');
    }
    final result = await runReleaseGate(
      resultPath: options.resultPath,
      scope: options.scope,
      resume: options.resume,
    );
    stdout.writeln(result.verdict.wireValue);
    exitCode = result.verdict == ReleaseVerdict.blocked ? 1 : 0;
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}

/// Runs the fixed prerequisite graph. Test seams can replace the process
/// boundary and candidate input set, but never the repository-owned command.
Future<GateResult> runReleaseGate({
  Directory? workingDirectory,
  ProcessAdapter? processAdapter,
  List<String>? trackedInputPaths,
  String resultPath = 'build/release_gate/result.json',
  String scope = 'tracer',
  bool resume = false,
  ReleaseGatePlatformAdapters? platformAdapters,
}) async {
  final root = workingDirectory ?? Directory.current;
  final stages = <StageResult>[];
  CandidateFingerprint? candidate;
  try {
    if (scope != 'tracer' && scope != 'host' && scope != 'full') {
      throw const _CandidateFailure('release gate scope is not configured');
    }
    // A missing or untrusted checkpoint is deliberately equivalent to a full
    // run. Candidate capture below happens before every child process, so
    // `--resume` can never weaken the clean-state eligibility contract.
    _assertIgnoredArtifactPath(root, resultPath);
    final captured = _captureCandidate(
      root,
      trackedInputPaths: trackedInputPaths,
    );
    candidate = captured.fingerprint;
    stages.add(
      _stage(
        stage: GateStage.candidate,
        command: const <String>['git', 'candidate-snapshot'],
        exitCode: 0,
        classification: StageClassification.succeeded,
        diagnostic: 'clean committed candidate captured',
      ),
    );

    final started = DateTime.now().toUtc();
    final outcome = await (processAdapter ?? const SystemProcessAdapter()).run(
      _prerequisiteCommand.first,
      _prerequisiteCommand.sublist(1),
      timeout: _gateTimeout,
      workingDirectory: root.path,
    );
    final prerequisite = _stage(
      stage: GateStage.prerequisite,
      command: _prerequisiteCommand,
      startedAtUtc: started,
      exitCode: outcome.exitCode,
      classification: outcome.exitCode == 0
          ? StageClassification.succeeded
          : StageClassification.commandFailed,
      diagnostic: scrubDiagnostic(outcome.diagnostic),
    );
    stages.add(prerequisite);
    if (!prerequisite.succeeded) {
      return await _persist(
        root,
        resultPath,
        GateResult(
          candidate: candidate,
          verdict: ReleaseVerdict.blocked,
          stages: stages,
        ),
      );
    }

    if (scope == 'host' || scope == 'full') {
      final hostStages = await HostExecutionGraph().run(
        processAdapter: processAdapter ?? const SystemProcessAdapter(),
        workingDirectory: root.path,
        timeout: _gateTimeout,
      );
      stages.addAll(hostStages);
    }

    if (scope == 'full') {
      final inventory = _discoverReleaseIntegrationTests(root);
      final skipManifest = _loadExpectedSkips(root, inventory);
      final adapters = platformAdapters ?? _defaultPlatformAdapters(root);
      final ios = await adapters.runIos(candidate, <String, IosAllowedSkip>{
        for (final skip in skipManifest.entries)
          skip.path: IosAllowedSkip(
            reason: skip.reason,
            ownerPhase: skip.ownerPhase,
            exitCondition: skip.exitCondition,
          ),
      });
      stages.add(
        _platformStage(
          GateStage.ios,
          ios.isReady &&
              validatePlatformInventory(
                discovered: inventory,
                executed: ios.executedTests,
                skips: skipManifest,
              ).isEmpty,
          ios.failure?.name ?? 'iOS simulator completed',
        ),
      );

      // The current Android adapter has no accepted skips. A nonempty shared
      // allowlist therefore blocks instead of silently omitting Android work.
      final android = skipManifest.entries.isEmpty
          ? await adapters.runAndroid(candidate)
          : null;
      final androidInventoryIssues = android == null
          ? const <String>[
              'Android adapter does not accept the configured skip',
            ]
          : validatePlatformInventory(
              discovered: inventory,
              executed: android.primary.executedFiles,
              skips: skipManifest,
            );
      stages.add(
        _platformStage(
          GateStage.android,
          android != null &&
              android.result == 'PASS' &&
              androidInventoryIssues.isEmpty,
          android?.failure ?? androidInventoryIssues.join('; '),
        ),
      );

      final postDevicePreflight =
          await (processAdapter ?? const SystemProcessAdapter()).run(
            'bash',
            const <String>['scripts/release_preflight.sh', '--platform', 'all'],
            timeout: _gateTimeout,
            workingDirectory: root.path,
          );
      stages.add(
        _stage(
          stage: GateStage.postDevicePreflight,
          command: const <String>[
            'bash',
            'scripts/release_preflight.sh',
            '--platform',
            'all',
          ],
          exitCode: postDevicePreflight.exitCode,
          classification: postDevicePreflight.exitCode == 0
              ? StageClassification.succeeded
              : StageClassification.commandFailed,
          diagnostic: postDevicePreflight.diagnostic,
        ),
      );
    }

    CandidateFingerprint? after;
    try {
      after = _captureCandidate(
        root,
        trackedInputPaths: trackedInputPaths,
        requireClean: false,
      ).fingerprint;
    } on _CandidateFailure {
      // A deleted critical input is final drift, not a new eligible candidate.
    }
    if (after == null ||
        !_workingTreeIsClean(root) ||
        !candidate.matches(after)) {
      stages.add(
        _stage(
          stage: GateStage.finalDrift,
          command: const <String>['git', 'candidate-snapshot'],
          exitCode: 1,
          classification: StageClassification.driftDetected,
          diagnostic: 'candidate identity changed during release gate',
        ),
      );
      return await _persist(
        root,
        resultPath,
        GateResult(
          candidate: candidate,
          verdict: ReleaseVerdict.blocked,
          stages: stages,
        ),
      );
    }
    stages.add(
      _stage(
        stage: GateStage.finalDrift,
        command: const <String>['git', 'candidate-snapshot'],
        exitCode: 0,
        classification: StageClassification.succeeded,
        diagnostic: 'candidate identity remains unchanged',
      ),
    );
    return await _persist(
      root,
      resultPath,
      GateResult(
        candidate: candidate,
        verdict: ReleaseVerdict.pass,
        stages: stages,
      ),
    );
  } on _CandidateFailure catch (error) {
    stages.add(
      _stage(
        stage: GateStage.candidate,
        command: const <String>['git', 'candidate-snapshot'],
        exitCode: 1,
        classification: StageClassification.invalidCandidate,
        diagnostic: error.message,
      ),
    );
  } on Object catch (error) {
    stages.add(
      _stage(
        stage: GateStage.privacy,
        command: const <String>['release-gate', 'validation'],
        exitCode: 1,
        classification: StageClassification.unknown,
        diagnostic: scrubDiagnostic('$error'),
      ),
    );
  }
  return GateResult(
    candidate: candidate,
    verdict: ReleaseVerdict.blocked,
    stages: stages,
  );
}

ReleaseGatePlatformAdapters _defaultPlatformAdapters(Directory root) =>
    ReleaseGatePlatformAdapters(
      runIos: (candidate, skips) async {
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: const SystemProcessAdapter(),
          candidateProvider: () => validateCandidate(root),
        );
        return adapter.runFullSuite(
          IosSimulatorOptions(
            candidate: candidate,
            workingDirectory: root.path,
            allowedSkips: skips,
          ),
        );
      },
      runAndroid: (candidate) => android_lane.runPhase62AndroidEvidence(
        root,
        candidate: candidate,
        resultPath: 'build/release_gate/android_evidence.json',
        captureCurrentCandidate: () async => validateCandidate(root),
      ),
    );

ReleaseSkipManifest _loadExpectedSkips(
  Directory root,
  List<String> discovered,
) {
  final file = File('${root.path}/scripts/release_gate/expected_skips.json');
  if (!file.existsSync()) {
    throw const _CandidateFailure('expected skip manifest is missing');
  }
  try {
    return ReleaseSkipManifest.fromJsonText(
      file.readAsStringSync(),
      discovered: discovered,
    );
  } on FormatException catch (error) {
    throw _CandidateFailure(
      'expected skip manifest is invalid: ${error.message}',
    );
  }
}

List<String> _discoverReleaseIntegrationTests(Directory root) {
  final directory = Directory('${root.path}/integration_test');
  if (!directory.existsSync()) return const <String>[];
  final paths =
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .map(
            (file) => file.path
                .replaceFirst('${root.path}/', '')
                .replaceAll('\\', '/'),
          )
          .where((path) => path.endsWith('_test.dart'))
          .toList()
        ..sort();
  return List<String>.unmodifiable(paths);
}

StageResult _platformStage(GateStage stage, bool passed, String diagnostic) =>
    _stage(
      stage: stage,
      command: <String>['release-gate', stage.name],
      exitCode: passed ? 0 : 1,
      classification: passed
          ? StageClassification.succeeded
          : StageClassification.commandFailed,
      diagnostic: diagnostic.isEmpty ? 'platform stage failed' : diagnostic,
    );

Future<GateResult> _persist(
  Directory root,
  String resultPath,
  GateResult result,
) async {
  final validationIssues = validateGateResult(result);
  if (!result.isSchemaValid || validationIssues.isNotEmpty) {
    return GateResult(
      candidate: result.candidate,
      verdict: ReleaseVerdict.blocked,
      stages: <StageResult>[
        ...result.stages,
        _stage(
          stage: GateStage.privacy,
          command: const <String>['release-gate', 'privacy-scan'],
          exitCode: 1,
          classification: StageClassification.privacyViolation,
          diagnostic: 'evidence schema or privacy validation failed',
        ),
      ],
      manualOverride: result.manualOverride,
      limitations: result.limitations,
      failureFixes: result.failureFixes,
    );
  }
  final authoritative = GateResult(
    candidate: result.candidate,
    verdict: computeVerdict(result),
    stages: result.stages,
    manualOverride: result.manualOverride,
    limitations: result.limitations,
    failureFixes: result.failureFixes,
  );
  final jsonFile = File('${root.path}/$resultPath');
  final previewFile = File(
    '${jsonFile.parent.path}/${jsonFile.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '')}.preview.md',
  );
  final jsonEvidence = const JsonEncoder.withIndent(
    '  ',
  ).convert(authoritative.toJson());
  final preview = renderCompatibilityReport(authoritative);
  if (validateEvidencePrivacy(jsonEvidence).isNotEmpty ||
      validateEvidencePrivacy(preview).isNotEmpty) {
    return GateResult(
      candidate: result.candidate,
      verdict: ReleaseVerdict.blocked,
      stages: <StageResult>[
        ...result.stages,
        _stage(
          stage: GateStage.privacy,
          command: const <String>['release-gate', 'privacy-scan'],
          exitCode: 1,
          classification: StageClassification.privacyViolation,
          diagnostic: 'rendered evidence failed privacy validation',
        ),
      ],
    );
  }
  await jsonFile.parent.create(recursive: true);
  await jsonFile.writeAsString(jsonEvidence);
  await previewFile.writeAsString(preview);
  return authoritative;
}

({CandidateFingerprint fingerprint, Map<String, String> expectedDigests})
_captureCandidate(
  Directory root, {
  List<String>? trackedInputPaths,
  bool requireClean = true,
}) {
  final commit = _git(root, const <String>['rev-parse', '--verify', 'HEAD']);
  if (requireClean && !_workingTreeIsClean(root)) {
    throw const _CandidateFailure('candidate checkout is not clean');
  }
  final expected = trackedInputPaths == null
      ? <String, String>{
          ..._baselineTrackedInputDigests(root),
          for (final path in _additionalCandidateInputs) path: '',
        }
      : <String, String>{for (final path in trackedInputPaths) path: ''};
  final digests = <String, String>{};
  for (final entry in expected.entries) {
    final file = File('${root.path}/${entry.key}');
    if (!file.existsSync()) {
      throw _CandidateFailure('candidate input is missing: ${entry.key}');
    }
    final digest = sha256.convert(file.readAsBytesSync()).toString();
    if (entry.value.isNotEmpty && entry.value != digest) {
      throw _CandidateFailure('candidate input digest mismatch: ${entry.key}');
    }
    digests[entry.key] = digest;
  }
  return (
    fingerprint: CandidateFingerprint(commit: commit, inputDigests: digests),
    expectedDigests: expected,
  );
}

/// Captures a clean candidate or throws when its Git/input proof is invalid.
CandidateFingerprint validateCandidate(
  Directory root, {
  List<String>? trackedInputPaths,
}) => _captureCandidate(root, trackedInputPaths: trackedInputPaths).fingerprint;

bool _workingTreeIsClean(Directory root) => _git(root, const <String>[
  'status',
  '--porcelain',
  '--untracked-files=all',
]).isEmpty;

Map<String, String> _baselineTrackedInputDigests(Directory root) {
  final manifest = File('${root.path}/docs/testing/STABLE_BASELINE.json');
  if (!manifest.existsSync()) {
    throw const _CandidateFailure('baseline manifest is missing');
  }
  final decoded = jsonDecode(manifest.readAsStringSync());
  if (decoded is! Map || decoded['tracked_inputs'] is! Map) {
    throw const _CandidateFailure('baseline tracked input manifest is invalid');
  }
  final inputs = decoded['tracked_inputs'] as Map;
  final digests = <String, String>{};
  for (final entry in inputs.entries) {
    final row = entry.value;
    if (entry.key is! String || row is! Map || row['sha256'] is! String) {
      throw const _CandidateFailure(
        'baseline tracked input manifest is invalid',
      );
    }
    digests[entry.key] = row['sha256'] as String;
  }
  return digests;
}

String _git(Directory root, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw _CandidateFailure('git ${arguments.join(' ')} failed');
  }
  return result.stdout.toString().trim();
}

void _assertIgnoredArtifactPath(Directory root, String resultPath) {
  if (!_isRawArtifactPath(resultPath)) {
    throw const _CandidateFailure(
      'result path must stay under build/release_gate',
    );
  }
  final ignored = Process.runSync(
    'git',
    <String>['check-ignore', '-q', resultPath],
    workingDirectory: root.path,
    runInShell: false,
  );
  if (ignored.exitCode != 0) {
    throw const _CandidateFailure('release-gate artifacts must be ignored');
  }
}

bool _isRawArtifactPath(String path) =>
    path.startsWith(_rawArtifactRoot) &&
    path.endsWith('.json') &&
    !path.contains('..');

StageResult _stage({
  required GateStage stage,
  required List<String> command,
  required int exitCode,
  required StageClassification classification,
  required String diagnostic,
  DateTime? startedAtUtc,
}) {
  final started = startedAtUtc ?? DateTime.now().toUtc();
  return StageResult(
    stage: stage,
    command: List<String>.unmodifiable(command),
    startedAtUtc: started,
    finishedAtUtc: DateTime.now().toUtc(),
    exitCode: exitCode,
    classification: classification,
    diagnostic: scrubDiagnostic(diagnostic),
  );
}

class _CandidateFailure implements Exception {
  const _CandidateFailure(this.message);

  final String message;
}
