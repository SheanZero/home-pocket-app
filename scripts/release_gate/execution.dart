/// Fail-closed host execution primitives for the Phase 62 release gate.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'process_adapter.dart';

const releaseGraphVersion = 1;

/// A closed classification vocabulary. Adding a class requires explicitly
/// deciding whether it is retryable; unknown output is always terminal.
enum FailureClass {
  succeeded,
  startupReadiness,
  deviceTransport,
  dependencyNetwork,
  runnerTimeout,
  assertion,
  compilation,
  signingHygiene,
  privacy,
  coverage,
  drift,
  schema,
  unknown,
}

enum RetryDecision { retry, stop }

RetryDecision retryDecisionFor(
  FailureClass failure, {
  required int priorAttempts,
}) {
  if (priorAttempts != 0) return RetryDecision.stop;
  return switch (failure) {
    FailureClass.startupReadiness ||
    FailureClass.deviceTransport ||
    FailureClass.dependencyNetwork ||
    FailureClass.runnerTimeout => RetryDecision.retry,
    _ => RetryDecision.stop,
  };
}

FailureClass classifyFailure(ProcessOutcome outcome) {
  if (outcome.exitCode == 0) return FailureClass.succeeded;
  final output = outcome.diagnostic.toLowerCase();
  if (outcome.exitCode == 124 ||
      RegExp(r'(?:timed? out|timeout|subprocess.*deadline)').hasMatch(output)) {
    return FailureClass.runnerTimeout;
  }
  if (RegExp(
    r'(?:device.*offline|transport|adb.*not found|lost connection)',
  ).hasMatch(output)) {
    return FailureClass.deviceTransport;
  }
  if (RegExp(
    r'(?:simulator|emulator).*(?:boot|ready|start)|readiness',
  ).hasMatch(output)) {
    return FailureClass.startupReadiness;
  }
  if (RegExp(
    r'(?:network|socket|download|pub get|connection reset|dns)',
  ).hasMatch(output)) {
    return FailureClass.dependencyNetwork;
  }
  if (RegExp(r'(?:assertion|expect\(|expected:)').hasMatch(output)) {
    return FailureClass.assertion;
  }
  if (RegExp(
    r'(?:compile|compilation|undefined (?:class|name)|build failed)',
  ).hasMatch(output)) {
    return FailureClass.compilation;
  }
  if (RegExp(r'(?:signing|provisioning|hygiene)').hasMatch(output)) {
    return FailureClass.signingHygiene;
  }
  if (RegExp(r'(?:privacy|secret|credential|token)').hasMatch(output)) {
    return FailureClass.privacy;
  }
  if (RegExp(r'(?:coverage|lcov|coverde)').hasMatch(output)) {
    return FailureClass.coverage;
  }
  if (RegExp(r'(?:drift|dirty checkout|candidate identity)').hasMatch(output)) {
    return FailureClass.drift;
  }
  if (RegExp(r'(?:schema|malformed|missing field)').hasMatch(output)) {
    return FailureClass.schema;
  }
  return FailureClass.unknown;
}

/// Stable, candidate-bound resume state. Its integrity digest detects any
/// mutation before a child command is permitted to run.
class ResumeCheckpoint {
  ResumeCheckpoint._({
    required this.candidate,
    required Map<String, String> configurationDigests,
    required Map<String, String> environmentFingerprint,
    required this.stageGraphVersion,
    required Map<GateStage, String> completedStageDigests,
    required this.integrity,
  }) : configurationDigests = UnmodifiableMapView(
         Map<String, String>.from(configurationDigests),
       ),
       environmentFingerprint = UnmodifiableMapView(
         Map<String, String>.from(environmentFingerprint),
       ),
       completedStageDigests = UnmodifiableMapView(
         Map<GateStage, String>.from(completedStageDigests),
       );

  factory ResumeCheckpoint.create({
    required CandidateFingerprint candidate,
    required Map<String, String> configurationDigests,
    required Map<String, String> environmentFingerprint,
    required Map<GateStage, String> completedStageDigests,
    int stageGraphVersion = releaseGraphVersion,
  }) {
    final integrity = _checkpointIntegrity(
      candidate: candidate,
      configurationDigests: configurationDigests,
      environmentFingerprint: environmentFingerprint,
      stageGraphVersion: stageGraphVersion,
      completedStageDigests: completedStageDigests,
    );
    return ResumeCheckpoint._(
      candidate: candidate,
      configurationDigests: configurationDigests,
      environmentFingerprint: environmentFingerprint,
      stageGraphVersion: stageGraphVersion,
      completedStageDigests: completedStageDigests,
      integrity: integrity,
    );
  }

  final CandidateFingerprint candidate;
  final Map<String, String> configurationDigests;
  final Map<String, String> environmentFingerprint;
  final int stageGraphVersion;
  final Map<GateStage, String> completedStageDigests;
  final String integrity;

  ResumeCheckpoint copyWith({String? integrity}) => ResumeCheckpoint._(
    candidate: candidate,
    configurationDigests: configurationDigests,
    environmentFingerprint: environmentFingerprint,
    stageGraphVersion: stageGraphVersion,
    completedStageDigests: completedStageDigests,
    integrity: integrity ?? this.integrity,
  );

  bool isValidFor({
    required CandidateFingerprint candidate,
    required Map<String, String> configurationDigests,
    required Map<String, String> environmentFingerprint,
    required int stageGraphVersion,
  }) =>
      this.candidate.matches(candidate) &&
      _mapsEqual(this.configurationDigests, configurationDigests) &&
      _mapsEqual(this.environmentFingerprint, environmentFingerprint) &&
      this.stageGraphVersion == stageGraphVersion &&
      integrity ==
          _checkpointIntegrity(
            candidate: this.candidate,
            configurationDigests: this.configurationDigests,
            environmentFingerprint: this.environmentFingerprint,
            stageGraphVersion: this.stageGraphVersion,
            completedStageDigests: completedStageDigests,
          );

  Map<String, Object> toJson() => <String, Object>{
    'schema_version': 1,
    'candidate': candidate.toJson(),
    'configuration_digests': configurationDigests,
    'environment_fingerprint': environmentFingerprint,
    'stage_graph_version': stageGraphVersion,
    'completed_stage_digests': <String, String>{
      for (final entry in completedStageDigests.entries)
        entry.key.name: entry.value,
    },
    'integrity': integrity,
  };
}

String _checkpointIntegrity({
  required CandidateFingerprint candidate,
  required Map<String, String> configurationDigests,
  required Map<String, String> environmentFingerprint,
  required int stageGraphVersion,
  required Map<GateStage, String> completedStageDigests,
}) {
  Map<String, String> sorted(Map<String, String> source) =>
      Map<String, String>.fromEntries(
        source.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      );
  final payload = <String, Object>{
    'candidate': candidate.toJson(),
    'configuration_digests': sorted(configurationDigests),
    'environment_fingerprint': sorted(environmentFingerprint),
    'stage_graph_version': stageGraphVersion,
    'completed_stage_digests': sorted(<String, String>{
      for (final entry in completedStageDigests.entries)
        entry.key.name: entry.value,
    }),
  };
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

/// Returns the first configured gate whose completed digest is not current.
/// Null means all completed stage digests are still valid.
GateStage? earliestInvalidatedStage(
  Map<GateStage, String> prior,
  Map<GateStage, String> current,
) {
  for (final stage in GateStage.values) {
    if (prior.containsKey(stage) && prior[stage] != current[stage]) {
      return stage;
    }
  }
  return null;
}

bool _mapsEqual(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

/// A repository-owned graph node. Prerequisites stop immediately; later
/// independent nodes aggregate their own final outcomes in configured order.
class ReleaseExecutionNode {
  const ReleaseExecutionNode({
    required this.stage,
    required this.command,
    required this.isPrerequisite,
  });

  final GateStage stage;
  final List<String> command;
  final bool isPrerequisite;
}

/// Executes bounded, normalized child-process stages without using timestamps
/// for ordering. This is deliberately usable with synthetic adapters in tests.
class ReleaseExecutionGraph {
  ReleaseExecutionGraph(Iterable<ReleaseExecutionNode> nodes)
    : nodes = List<ReleaseExecutionNode>.unmodifiable(nodes) {
    if (this.nodes.isEmpty || this.nodes.any((node) => node.command.isEmpty)) {
      throw ArgumentError('release execution graph must contain commands');
    }
    final names = this.nodes.map((node) => node.stage).toSet();
    if (names.length != this.nodes.length) {
      throw ArgumentError('release execution graph stages must be unique');
    }
  }

  final List<ReleaseExecutionNode> nodes;

  Future<List<StageResult>> run({
    required ProcessAdapter processAdapter,
    required String workingDirectory,
    Duration timeout = const Duration(minutes: 20),
  }) async {
    final results = <StageResult>[];
    for (final node in nodes) {
      final attempts = <StageAttemptRecord>[];
      ProcessOutcome? outcome;
      FailureClass failure = FailureClass.unknown;
      for (var attempt = 0; attempt < 2; attempt++) {
        outcome = await processAdapter.run(
          node.command.first,
          node.command.sublist(1),
          timeout: timeout,
          workingDirectory: workingDirectory,
        );
        failure = classifyFailure(outcome);
        attempts.add(
          StageAttemptRecord(
            ordinal: attempt + 1,
            exitCode: outcome.exitCode,
            failureClass: failure.name,
            diagnostic: scrubDiagnostic(outcome.diagnostic),
          ),
        );
        if (failure == FailureClass.succeeded ||
            retryDecisionFor(failure, priorAttempts: attempt) ==
                RetryDecision.stop) {
          break;
        }
      }
      if (outcome == null || attempts.isEmpty) {
        throw StateError('stage execution produced no normalized outcome');
      }
      final now = DateTime.now().toUtc();
      final result = StageResult(
        stage: node.stage,
        command: List<String>.unmodifiable(node.command),
        startedAtUtc: now,
        finishedAtUtc: DateTime.now().toUtc(),
        exitCode: outcome.exitCode,
        classification: failure == FailureClass.succeeded
            ? StageClassification.succeeded
            : StageClassification.commandFailed,
        diagnostic: scrubDiagnostic(outcome.diagnostic),
        attempts: List<StageAttemptRecord>.unmodifiable(attempts),
      );
      results.add(result);
      if (node.isPrerequisite && !result.succeeded) break;
    }
    if (results.isEmpty) {
      throw StateError('stage graph returned no records');
    }
    return List<StageResult>.unmodifiable(results);
  }
}
