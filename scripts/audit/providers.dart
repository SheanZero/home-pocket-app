// Emits provider-hygiene findings from the repository-owned Riverpod contract.
//
// riverpod_lint 3.1.4 is active on analyzer 12; this scanner supplies the
// repository-owned app-root contract as defense in depth.
import 'dart:convert';
import 'dart:io';

import 'finding.dart';
import 'provider_contract.dart';

Map<String, dynamic> buildProviderAuditEnvelope(
  ProviderContractReport report, {
  DateTime? generatedAt,
}) => {
  'tool_source': 'owned_provider_contract',
  'scan_state': 'ran',
  'generated_at': (generatedAt ?? DateTime.now().toUtc()).toIso8601String(),
  'findings': report.violations
      .map(_toFinding)
      .map((finding) => finding.toJson())
      .toList(),
};

Finding _toFinding(ProviderContractViolation violation) => Finding(
  category: 'provider_hygiene',
  severity: 'HIGH',
  filePath: violation.path,
  lineStart: violation.line,
  lineEnd: violation.line,
  description: violation.message,
  rationale: 'Repository-owned Riverpod contract flagged ${violation.code}.',
  suggestedFix: _suggestedFix(violation.code),
  toolSource: 'owned_provider_contract',
  confidence: 'high',
);

String _suggestedFix(String code) => switch (code) {
  'missing_provider_scope' =>
    'Wrap the app root in ProviderScope or UncontrolledProviderScope.',
  'riverpod_lint_plugin_missing' =>
    'Restore the active riverpod_lint 3.1.4 analysis-server plugin.',
  _ => 'Restore the documented active riverpod_lint lockfile contract.',
};

Future<void> main(List<String> args) async {
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = '.planning/audit/shards/providers.json';
  Map<String, dynamic> envelope;
  try {
    envelope = buildProviderAuditEnvelope(checkProviderContract('.'));
  } catch (error, stackTrace) {
    envelope = {
      'tool_source': 'owned_provider_contract',
      'scan_state': 'not_run',
      'scan_failed': true,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'findings': <Map<String, dynamic>>[],
      'error': error.toString(),
    };
    stderr.writeln(
      '[audit:providers] ERROR: owned contract failed: $error\n$stackTrace',
    );
  }

  await File(
    shardPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(envelope));
  final findingCount = (envelope['findings'] as List).length;
  stdout.writeln(
    '[audit:providers] wrote $findingCount findings to $shardPath',
  );
  if (envelope['scan_failed'] == true) exitCode = 1;
}
