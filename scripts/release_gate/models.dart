import 'dart:collection';
import 'dart:convert';

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

/// Limitations may describe only evidence outside the mandatory local release
/// graph. `unclassified` exists so that a newly observed limitation fails
/// closed instead of inheriting a passing result.
enum ReleaseLimitation { supplementalX86, acceptedHistoricalDebt, unclassified }

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
  ios,
  android,
  postDevicePreflight,
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

/// Concise, privacy-safe history of a real Phase 62 failure. Raw command
/// transcripts stay in ignored CI artifacts and are intentionally absent.
class FailureFixRecord {
  const FailureFixRecord({
    required this.stage,
    required this.failureSummary,
    required this.finalFix,
    required this.candidateChanged,
    required this.completeRerunOutcome,
  });

  final String stage;
  final String failureSummary;
  final String finalFix;
  final bool candidateChanged;
  final String completeRerunOutcome;

  bool get isComplete =>
      stage.isNotEmpty &&
      failureSummary.isNotEmpty &&
      finalFix.isNotEmpty &&
      (completeRerunOutcome == 'PASS' || completeRerunOutcome == 'BLOCKED');

  Map<String, Object> toJson() => <String, Object>{
    'stage': stage,
    'failure_summary': failureSummary,
    'final_fix': finalFix,
    'candidate_changed': candidateChanged,
    'complete_rerun_outcome': completeRerunOutcome,
  };
}

class GateResult {
  GateResult({
    required this.candidate,
    required this.verdict,
    required Iterable<StageResult> stages,
    this.manualOverride = false,
    Iterable<ReleaseLimitation> limitations = const <ReleaseLimitation>[],
    Iterable<FailureFixRecord> failureFixes = const <FailureFixRecord>[],
  }) : stages = List<StageResult>.unmodifiable(stages),
       limitations = List<ReleaseLimitation>.unmodifiable(limitations),
       failureFixes = List<FailureFixRecord>.unmodifiable(failureFixes);

  final CandidateFingerprint? candidate;
  final ReleaseVerdict verdict;
  final List<StageResult> stages;
  final bool manualOverride;
  final List<ReleaseLimitation> limitations;
  final List<FailureFixRecord> failureFixes;

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
    'manual_override': manualOverride,
    'limitations': limitations.map((limitation) => limitation.name).toList(),
    'failure_fixes': failureFixes.map((record) => record.toJson()).toList(),
  };
}

/// A checked-in exception to a platform execution.  The aggregate gate treats
/// it as accounting data only: it never converts an unavailable mandatory
/// journey into a passing platform result.
class ReleaseSkip {
  const ReleaseSkip({
    required this.path,
    required this.reason,
    required this.ownerPhase,
    required this.exitCondition,
  });

  final String path;
  final String reason;
  final String ownerPhase;
  final String exitCondition;

  bool get isComplete =>
      _isNormalizedIntegrationPath(path) &&
      reason.trim().isNotEmpty &&
      ownerPhase.trim().isNotEmpty &&
      exitCondition.trim().isNotEmpty;
}

/// Strict, versioned expected-skip allowlist.  Its absence is deliberately
/// not equivalent to an empty list: callers must load the committed manifest.
class ReleaseSkipManifest {
  ReleaseSkipManifest._(Iterable<ReleaseSkip> entries)
    : entries = List<ReleaseSkip>.unmodifiable(entries);

  factory ReleaseSkipManifest.empty() =>
      ReleaseSkipManifest._(const <ReleaseSkip>[]);

  factory ReleaseSkipManifest.parse(
    Map<String, Object?> value, {
    required Iterable<String> discovered,
  }) {
    if (value.length != 2 || value['schema_version'] != 1) {
      throw const FormatException('expected skip manifest schema is invalid');
    }
    final rawEntries = value['skips'];
    if (rawEntries is! List) {
      throw const FormatException('expected skip manifest skips is invalid');
    }
    final canonicalDiscovered = _canonicalInventory(discovered);
    if (canonicalDiscovered == null) {
      throw const FormatException('integration inventory is invalid');
    }
    final entries = <ReleaseSkip>[];
    final paths = <String>{};
    for (final raw in rawEntries) {
      if (raw is! Map || raw.length != 4) {
        throw const FormatException('expected skip entry is invalid');
      }
      String field(String name) {
        final entry = raw[name];
        if (entry is! String) {
          throw FormatException('expected skip $name is invalid');
        }
        return entry;
      }

      final entry = ReleaseSkip(
        path: field('path'),
        reason: field('reason'),
        ownerPhase: field('owner_phase'),
        exitCondition: field('exit_condition'),
      );
      if (!entry.isComplete ||
          !canonicalDiscovered.contains(entry.path) ||
          !paths.add(entry.path)) {
        throw const FormatException('expected skip entry is stale or invalid');
      }
      entries.add(entry);
    }
    return ReleaseSkipManifest._(entries);
  }

  factory ReleaseSkipManifest.fromJsonText(
    String value, {
    required Iterable<String> discovered,
  }) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException(
        'expected skip manifest must be a JSON object',
      );
    }
    return ReleaseSkipManifest.parse(
      Map<String, Object?>.from(decoded),
      discovered: discovered,
    );
  }

  final List<ReleaseSkip> entries;

  Map<String, ReleaseSkip> get byPath => Map<String, ReleaseSkip>.unmodifiable({
    for (final entry in entries) entry.path: entry,
  });
}

/// Returns a human-readable issue for every incomplete relationship between a
/// recursive inventory and a single platform's recorded execution.
List<String> validatePlatformInventory({
  required Iterable<String> discovered,
  required Iterable<String> executed,
  required ReleaseSkipManifest skips,
}) {
  final canonicalDiscovered = _canonicalInventory(discovered);
  final canonicalExecuted = _canonicalInventory(executed);
  if (canonicalDiscovered == null || canonicalDiscovered.isEmpty) {
    return const <String>['integration discovery must be nonempty and unique'];
  }
  if (canonicalExecuted == null) {
    return const <String>[
      'executed integration paths must be normalized and unique',
    ];
  }
  final skipPaths = skips.byPath.keys.toSet();
  if (skipPaths.length != skips.entries.length ||
      !canonicalDiscovered.containsAll(skipPaths)) {
    return const <String>['expected skips must be unique discovered paths'];
  }
  final accounted = <String>{...canonicalExecuted, ...skipPaths};
  if (canonicalExecuted.any(skipPaths.contains) ||
      accounted.length != canonicalDiscovered.length ||
      !accounted.containsAll(canonicalDiscovered)) {
    return const <String>[
      'platform execution plus expected skips must equal discovery',
    ];
  }
  return const <String>[];
}

Set<String>? _canonicalInventory(Iterable<String> paths) {
  final result = <String>{};
  for (final path in paths) {
    if (!_isNormalizedIntegrationPath(path) || !result.add(path)) return null;
  }
  return result;
}

bool _isNormalizedIntegrationPath(String path) =>
    path.startsWith('integration_test/') &&
    path.endsWith('_test.dart') &&
    !path.contains('..') &&
    !path.contains('\\') &&
    !path.contains('//');

bool _mapsEqual(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
