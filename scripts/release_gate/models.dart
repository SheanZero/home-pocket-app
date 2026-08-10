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

enum GateStage { candidate, prerequisite, finalDrift, privacy }

enum StageClassification {
  succeeded,
  commandFailed,
  invalidCandidate,
  driftDetected,
  privacyViolation,
  unknown,
}

/// Conservative placeholder for the closed retry policy added by Plan 62-04.
/// Until that policy exists, no failed stage is retryable.
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
  });

  final GateStage stage;
  final List<String> command;
  final DateTime startedAtUtc;
  final DateTime finishedAtUtc;
  final int exitCode;
  final StageClassification classification;
  final String diagnostic;

  bool get succeeded => classification == StageClassification.succeeded;

  Map<String, Object> toJson() => <String, Object>{
    'stage': stage.name,
    'command': command,
    'started_at_utc': startedAtUtc.toIso8601String(),
    'finished_at_utc': finishedAtUtc.toIso8601String(),
    'exit_code': exitCode,
    'classification': classification.name,
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
