/// Authoritative Phase 62 result validation, verdict derivation, and stable
/// human preview. This library deliberately has no process or device access.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';

const _maxReportTextChars = 320;
final _prohibitedEvidence = RegExp(
  r'(/users/|/home/|udid|serial|token=|credential=|secret=|password=|api[_-]?key=|sync[_ -]?payload|backup content|financial field|note=|amount=|keystore)',
  caseSensitive: false,
);

/// Validates the normalized authority before JSON or Markdown persistence.
/// Returning issues rather than throwing keeps verdict computation pure.
List<String> validateGateResult(GateResult result) {
  final issues = <String>[];
  final candidate = result.candidate;
  if (candidate == null ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(candidate.commit) ||
      candidate.inputDigests.isEmpty) {
    issues.add('candidate identity is incomplete');
  }
  if (result.stages.isEmpty) issues.add('at least one stage is required');
  final stageNames = result.stages.map((stage) => stage.stage).toSet();
  if (stageNames.length != result.stages.length) {
    issues.add('stage records must be unique');
  }
  if (result.stages.any(
    (stage) =>
        stage.command.isEmpty ||
        stage.finishedAtUtc.isBefore(stage.startedAtUtc),
  )) {
    issues.add('stage records are invalid');
  }
  if (result.limitations.contains(ReleaseLimitation.unclassified)) {
    issues.add('unclassified limitation is not accepted');
  }
  if (result.failureFixes.any(
    (record) =>
        !record.isComplete ||
        record.failureSummary.length > _maxReportTextChars ||
        record.finalFix.length > _maxReportTextChars,
  )) {
    issues.add('failure-fix record is invalid');
  }
  issues.addAll(validateEvidencePrivacy(result.toJson()));
  return List<String>.unmodifiable(issues);
}

/// Scan before every write. Sensitive categories are rejected rather than
/// collected then redacted, so reports never become a source of raw evidence.
List<String> validateEvidencePrivacy(Object? evidence) {
  final encoded = jsonEncode(evidence);
  if (_prohibitedEvidence.hasMatch(encoded)) {
    return const <String>['evidence contains a prohibited sensitive category'];
  }
  if (encoded.length > 128 * 1024) {
    return const <String>['evidence exceeds the bounded report limit'];
  }
  return const <String>[];
}

/// The only release verdict derivation. Neither a CLI flag nor JSON field can
/// override a mandatory non-green stage, identity failure, schema failure, or
/// manual override.
ReleaseVerdict computeVerdict(GateResult result) {
  if (result.manualOverride ||
      validateGateResult(result).isNotEmpty ||
      result.stages.any((stage) => !stage.succeeded)) {
    return ReleaseVerdict.blocked;
  }
  if (result.limitations.isEmpty) return ReleaseVerdict.pass;
  if (result.limitations.every(
    (limitation) =>
        limitation == ReleaseLimitation.supplementalX86 ||
        limitation == ReleaseLimitation.acceptedHistoricalDebt,
  )) {
    return ReleaseVerdict.passWithLimitations;
  }
  return ReleaseVerdict.blocked;
}

/// Deterministic Markdown preview from already-normalized authority. It omits
/// raw retry attempts and forces the physical Android scope disclaimer.
String renderCompatibilityReport(GateResult result) {
  final issues = validateGateResult(result);
  if (issues.isNotEmpty) {
    throw StateError(
      'cannot render invalid release result: ${issues.join('; ')}',
    );
  }
  final verdict = computeVerdict(result);
  final candidate = result.candidate!;
  final digests = candidate.inputDigests.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  final lines = <String>[
    '# Release Compatibility Report',
    '',
    'Verdict: `${verdict.wireValue}`',
    'Candidate commit: `${candidate.commit}`',
    'Candidate input digests:',
    ...digests.map((entry) => '- `${entry.key}`: `${entry.value}`'),
    '',
    '## Mandatory stages',
    ...result.stages.map(
      (stage) => '- `${stage.stage.name}`: `${stage.classification.name}`',
    ),
    '',
    '## Commands',
    ...result.stages.map(
      (stage) => '- `${stage.stage.name}`: `${stage.command.join(' ')}`',
    ),
    '',
    '## Environment',
    '- Environment availability is established only by the validated candidate-bound JSON and retained CI artifact; this rendering never claims that a runner is online.',
    '',
    '## Candidate deltas',
    '- No source or configuration delta is accepted after the tested candidate. RPT-A permits only this report as a metadata-only successor.',
    '',
    'Android physical-device validation: not performed or claimed.',
    '',
    '## Holds and limitations',
    if (result.limitations.isEmpty) '- None',
    ...result.limitations.map((limitation) => '- `${limitation.name}`'),
    '',
    '## Failure fixes',
    if (result.failureFixes.isEmpty) '- None encountered',
    ...result.failureFixes.map(
      (record) =>
          '- `${record.stage}`: ${record.failureSummary} → '
          '${record.finalFix}; candidate changed: ${record.candidateChanged}; '
          'complete rerun: `${record.completeRerunOutcome}`',
    ),
    '',
  ];
  final rendered = lines.join('\n');
  if (validateEvidencePrivacy(rendered).isNotEmpty) {
    throw StateError('rendered release result violates privacy policy');
  }
  return rendered;
}

/// Adds one sanitized operational record beside the ignored JSON authority.
/// The command interface accepts facts only; it has no raw-log argument.
Future<void> recordFailureFix({
  required Directory root,
  required String resultPath,
  required CandidateFingerprint candidate,
  required FailureFixRecord record,
}) async {
  if (!record.isComplete ||
      validateEvidencePrivacy(record.toJson()).isNotEmpty ||
      resultPath.contains('..') ||
      !resultPath.startsWith('build/release_gate/') ||
      !resultPath.endsWith('.json')) {
    throw ArgumentError('failure-fix record is invalid');
  }
  final file = File(
    '${root.path}/${resultPath.replaceFirst(RegExp(r'\.json$'), '.fixes.json')}',
  );
  final rows = <Object>[];
  if (file.existsSync()) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['records'] is! List) {
      throw const FormatException('existing failure-fix ledger is invalid');
    }
    for (final raw in decoded['records'] as List) {
      if (raw is! Map) {
        throw const FormatException('existing failure-fix ledger is invalid');
      }
      rows.add(Map<String, Object?>.from(raw));
    }
  }
  rows.add(<String, Object>{
    'candidate': candidate.toJson(),
    ...record.toJson(),
  });
  final payload = <String, Object>{'schema_version': 1, 'records': rows};
  if (validateEvidencePrivacy(payload).isNotEmpty) {
    throw StateError('failure-fix ledger violates privacy policy');
  }
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
}
