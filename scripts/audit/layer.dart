// scripts/audit/layer.dart
// Runs import_lint and emits tool/audit/shards/layer.json.
import 'dart:convert';
import 'dart:io';

import 'finding.dart';

const _generatedFileSuffixes = ['.g.dart', '.freezed.dart', '.mocks.dart'];

bool _isGenerated(String path) =>
    _generatedFileSuffixes.any(path.endsWith) ||
    path.contains('lib/generated/');

String _relPath(String absPath) {
  final cwd = Directory.current.path;
  if (absPath.startsWith('$cwd/')) {
    return absPath.substring(cwd.length + 1);
  }
  return absPath;
}

typedef LayerCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class LayerAuditRun {
  const LayerAuditRun({required this.envelope, required this.exitCode});

  final Map<String, dynamic> envelope;
  final int exitCode;
}

class _LayerScan {
  const _LayerScan.success(this.findings) : diagnostic = null;

  const _LayerScan.failure(this.diagnostic) : findings = const [];

  final List<Finding> findings;
  final String? diagnostic;

  bool get failed => diagnostic != null;
}

String _normalizeOutput(Object? output) => (output is String ? output : '')
    .replaceAll(RegExp('\u001b\\[[0-?]*[ -/]*[@-~]'), '')
    .replaceAll('\r', '\n')
    .trim();

Future<_LayerScan> _runImportLint(LayerCommandRunner commandRunner) async {
  final result = await commandRunner('dart', ['run', 'import_lint']);
  if (result.exitCode > 1) {
    return const _LayerScan.failure('import_lint exited unsuccessfully');
  }

  final output = _normalizeOutput(result.stdout);
  if (output.isEmpty) {
    return const _LayerScan.failure('import_lint emitted no output');
  }
  if (result.exitCode == 0) {
    return output.contains('No issues found!')
        ? const _LayerScan.success([])
        : const _LayerScan.failure('import_lint clean output was unrecognized');
  }
  return _parseImportLintOutput(output);
}

_LayerScan _parseImportLintOutput(String output) {
  final pattern = RegExp(
    r'^\s*(error|warning|info)\s+•\s+(.+):(\d+):(\d+)\s+•\s+(.+)\s+•\s+([A-Za-z0-9_]+)\s*$',
    multiLine: true,
  );
  final matches = pattern.allMatches(output).toList();
  final reportedCount = RegExp(
    r'^(\d+) issues? found\.$',
    multiLine: true,
  ).firstMatch(output);
  if (!output.contains('Analyzing...') ||
      reportedCount == null ||
      int.parse(reportedCount.group(1)!) != matches.length ||
      matches.isEmpty) {
    return const _LayerScan.failure('import_lint output was malformed');
  }
  final findings = <Finding>[];
  for (final match in matches) {
    final file = _relPath(match.group(2)!);
    if (_isGenerated(file)) continue;
    final line = int.parse(match.group(3)!);
    final importedUri = match.group(5)!;
    final rule = match.group(6)!;
    findings.add(
      Finding(
        category: 'layer_violation',
        severity: 'CRITICAL',
        filePath: file,
        lineStart: line,
        lineEnd: line,
        description: 'Forbidden import $importedUri',
        rationale: 'Layer violation flagged by import_lint rule $rule',
        suggestedFix: 'Move/refactor the dependency to satisfy $rule.',
        toolSource: 'import_lint',
        confidence: 'high',
      ),
    );
  }
  return _LayerScan.success(findings);
}

Future<LayerAuditRun> runLayerAudit({
  LayerCommandRunner? commandRunner,
  DateTime? generatedAt,
}) async {
  final runCommand =
      commandRunner ??
      (executable, arguments) =>
          Process.run(executable, arguments, runInShell: true);
  final envelope = <String, dynamic>{
    'tool_source': 'import_lint',
    'scan_state': 'ran',
    'generated_at': (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'findings': <Map<String, dynamic>>[],
  };

  try {
    final scan = await _runImportLint(runCommand);
    if (scan.failed) {
      return _failedRun(envelope, scan.diagnostic!);
    }
    envelope['findings'] = scan.findings.map((f) => f.toJson()).toList();
  } catch (_) {
    return _failedRun(envelope, 'layer scan could not be completed');
  }
  return LayerAuditRun(envelope: envelope, exitCode: 0);
}

LayerAuditRun _failedRun(Map<String, dynamic> envelope, String diagnostic) {
  envelope['scan_state'] = 'not_run';
  envelope['scan_failed'] = true;
  // Do not include tool stdout, stderr, or thrown exception text in the shard.
  envelope['error'] = diagnostic;
  return LayerAuditRun(envelope: envelope, exitCode: 1);
}

Future<void> main(List<String> args) async {
  final shardDir = Directory('tool/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = 'tool/audit/shards/layer.json';
  final run = await runLayerAudit();

  await File(
    shardPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(run.envelope));
  final n = (run.envelope['findings'] as List).length;
  stdout.writeln('[audit:layer] wrote $n findings to $shardPath');
  if (run.exitCode != 0) {
    stderr.writeln('[audit:layer] ERROR: ${run.envelope['error']}');
    exitCode = run.exitCode;
  }
}
