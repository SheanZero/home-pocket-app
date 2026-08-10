/// The sole Phase 62 release-lock verdict authority.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'release_gate/models.dart';
import 'release_gate/process_adapter.dart';

export 'release_gate/models.dart'
    show ReleaseGateRetry, ReleaseVerdict, validateResume;
export 'release_gate/execution.dart'
    show
        FailureClass,
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
  });

  final String scope;
  final String resultPath;
  final bool resume;
}

ReleaseGateOptions parseReleaseGateOptions(List<String> arguments) {
  String? scope;
  String? resultPath;
  var resume = false;
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
    } else {
      throw ArgumentError('unknown argument: $argument');
    }
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
}) async {
  final root = workingDirectory ?? Directory.current;
  final stages = <StageResult>[];
  CandidateFingerprint? candidate;
  try {
    if (scope != 'tracer') {
      // Host composition lands in Task 2. Never accept a host resume as a
      // tracer run, because that could silently skip mandatory stages.
      throw const _CandidateFailure('host execution graph is not configured');
    }
    if (resume) {
      throw const _CandidateFailure('resume checkpoint is not configured');
    }
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

Future<GateResult> _persist(
  Directory root,
  String resultPath,
  GateResult result,
) async {
  if (!result.isSchemaValid || !_isPrivacySafe(jsonEncode(result.toJson()))) {
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
    );
  }
  final jsonFile = File('${root.path}/$resultPath');
  final previewFile = File(
    '${jsonFile.parent.path}/${jsonFile.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '')}.preview.md',
  );
  final jsonEvidence = const JsonEncoder.withIndent(
    '  ',
  ).convert(result.toJson());
  final preview = _renderPreview(result);
  if (!_isPrivacySafe(jsonEvidence) || !_isPrivacySafe(preview)) {
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
  return result;
}

String _renderPreview(GateResult result) {
  final candidate = result.candidate;
  return <String>[
    '# Release Gate Preview',
    '',
    'Verdict: `${result.verdict.wireValue}`',
    'Candidate: `${candidate?.commit ?? 'unavailable'}`',
    'Inputs: `${candidate?.inputDigests.length ?? 0}` digests',
    '',
    '## Stages',
    ...result.stages.map(
      (stage) => '- `${stage.stage.name}`: `${stage.classification.name}`',
    ),
    '',
  ].join('\n');
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

bool _isPrivacySafe(String value) => !RegExp(
  r'(/users/|/home/|udid|serial|token=|credential=|secret=|password=|api[_-]?key=|sync[_ -]?payload|backup content|financial field|note=|amount=)',
  caseSensitive: false,
).hasMatch(value);

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
