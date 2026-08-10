import 'dart:collection';

enum ReleaseVerdict {
  pass,
  passWithLimitations,
  blocked;

  String get wireValue => switch (this) {
    ReleaseVerdict.pass => 'PASS',
    ReleaseVerdict.passWithLimitations => 'PASS_WITH_LIMITATIONS',
    ReleaseVerdict.blocked => 'BLOCKED',
  };
}

/// The configured release-lock order. Do not sort stage results by timestamps:
/// equal timestamps must retain this deterministic graph order.
enum GateStage {
  candidate,
  prerequisite,
  targetRegressions,
  hostSuite,
  timeoutDiagnosis,
  serialHostSuite,
  coverageFilter,
  coverageGate,
  finalDrift,
  privacy,
}

enum StageClassification {
  succeeded,
  commandFailed,
  invalidCandidate,
  driftDetected,
  privacyViolation,
  unknown,
}

/// Legacy compatibility enum retained for the tracer's public export.
/// Plan 62-04's executable retry policy lives in execution.dart.
enum ReleaseGateRetry { notEligible }

/// Resume is deliberately unavailable until Plan 62-04 supplies its complete
/// candidate/environment proof. Returning false is fail-closed by design.
bool validateResume(CandidateFingerprint candidate) => false;

class CandidateFingerprint {
  CandidateFingerprint({
    required this.commit,
    required Map<String, String> inputDigests,
  }) : inputDigests = UnmodifiableMapView(
         Map<String, String>.from(inputDigests),
       );

  final String commit;
  final Map<String, String> inputDigests;

  bool matches(CandidateFingerprint other) =>
      commit == other.commit && _mapsEqual(inputDigests, other.inputDigests);

  Map<String, Object> toJson() => <String, Object>{
    'commit': commit,
    'input_digests': inputDigests,
  };
}

class StageResult {
  const StageResult({
    required this.stage,
    required this.command,
    required this.startedAtUtc,
    required this.finishedAtUtc,
    required this.exitCode,
    required this.classification,
    required this.diagnostic,
    this.attempts = const <StageAttemptRecord>[],
  });

  final GateStage stage;
  final List<String> command;
  final DateTime startedAtUtc;
  final DateTime finishedAtUtc;
  final int exitCode;
  final StageClassification classification;
  final String diagnostic;
  final List<StageAttemptRecord> attempts;

  bool get succeeded => classification == StageClassification.succeeded;

  Map<String, Object> toJson() => <String, Object>{
    'stage': stage.name,
    'command': command,
    'started_at_utc': startedAtUtc.toIso8601String(),
    'finished_at_utc': finishedAtUtc.toIso8601String(),
    'exit_code': exitCode,
    'classification': classification.name,
    'diagnostic': diagnostic,
    if (attempts.isNotEmpty)
      'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
  };
}

/// Privacy-safe, normalized retry evidence retained only in ignored artifacts.
class StageAttemptRecord {
  const StageAttemptRecord({
    required this.ordinal,
    required this.exitCode,
    required this.failureClass,
    required this.diagnostic,
  });

  final int ordinal;
  final int exitCode;
  final String failureClass;
  final String diagnostic;

  Map<String, Object> toJson() => <String, Object>{
    'ordinal': ordinal,
    'exit_code': exitCode,
    'failure_class': failureClass,
    'diagnostic': diagnostic,
  };
}

class GateResult {
  GateResult({
    required this.candidate,
    required this.verdict,
    required Iterable<StageResult> stages,
  }) : stages = List<StageResult>.unmodifiable(stages);

  final CandidateFingerprint? candidate;
  final ReleaseVerdict verdict;
  final List<StageResult> stages;

  bool get isSchemaValid {
    if (stages.isEmpty ||
        (candidate == null && verdict != ReleaseVerdict.blocked)) {
      return false;
    }
    return stages.every(
      (stage) =>
          stage.finishedAtUtc.isAfter(stage.startedAtUtc) ||
          stage.finishedAtUtc == stage.startedAtUtc,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': 1,
    'verdict': verdict.wireValue,
    'candidate': candidate?.toJson(),
    'stages': stages.map((stage) => stage.toJson()).toList(),
  };
}

bool _mapsEqual(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
