// scripts/audit/layer.dart
// Runs custom_lint, filters to import_guard codes, emits .planning/audit/shards/layer.json.
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

// Text-reporter line: "  <relpath>:<line>:<col> • <message> • <code> • <SEVERITY>"
final _textLine = RegExp(
  r'^\s*([^:]+\.dart):(\d+):(\d+)\s+•\s+(.+?)\s+•\s+(\S+)\s+•\s+(INFO|WARNING|ERROR)\s*$',
);

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

Future<_LayerScan> _runJsonReporter(LayerCommandRunner commandRunner) async {
  final result = await commandRunner('dart', [
    'run',
    'custom_lint',
    '--reporter=json',
    '--no-fatal-infos',
  ]);
  if (result.exitCode > 1) {
    return const _LayerScan.failure(
      'layer JSON reporter exited unsuccessfully',
    );
  }

  final output = _normalizeOutput(result.stdout);
  if (output.isEmpty) {
    // custom_lint's JSON reporter normally emits a versioned envelope. Retain
    // the legacy text fallback only for this precise absent-output condition.
    return const _LayerScan.failure('layer JSON reporter emitted no output');
  }

  try {
    return _parseJsonReporter(output);
  } on FormatException {
    return const _LayerScan.failure(
      'layer JSON reporter emitted malformed JSON',
    );
  } catch (_) {
    return const _LayerScan.failure(
      'layer JSON reporter emitted malformed JSON',
    );
  }
}

_LayerScan _parseJsonReporter(String output) {
  final decoded = jsonDecode(output);
  if (decoded is! Map ||
      decoded.length != 2 ||
      decoded['version'] != 1 ||
      decoded['diagnostics'] is! List) {
    return const _LayerScan.failure(
      'layer JSON reporter emitted an unrecognized report',
    );
  }

  final findings = <Finding>[];
  for (final diagnostic in decoded['diagnostics'] as List) {
    final parsed = _parseJsonDiagnostic(diagnostic);
    if (parsed == null) {
      return const _LayerScan.failure(
        'layer JSON reporter emitted a malformed diagnostic',
      );
    }
    if (!parsed.code.startsWith('import_guard') || _isGenerated(parsed.file)) {
      continue;
    }
    findings.add(
      Finding(
        category: 'layer_violation',
        severity: 'CRITICAL',
        filePath: parsed.file,
        lineStart: parsed.lineStart,
        lineEnd: parsed.lineEnd,
        description: parsed.message,
        rationale: 'Layer violation flagged by ${parsed.code}',
        suggestedFix:
            parsed.correction ?? 'Move/refactor to satisfy the layer rule.',
        toolSource: 'import_guard',
        confidence: 'high',
      ),
    );
  }
  return _LayerScan.success(findings);
}

class _LayerDiagnostic {
  const _LayerDiagnostic({
    required this.code,
    required this.file,
    required this.lineStart,
    required this.lineEnd,
    required this.message,
    required this.correction,
  });

  final String code;
  final String file;
  final int lineStart;
  final int lineEnd;
  final String message;
  final String? correction;
}

_LayerDiagnostic? _parseJsonDiagnostic(dynamic value) {
  if (value is! Map ||
      !_hasOnlyKeys(value, const {
        'code',
        'severity',
        'type',
        'location',
        'problemMessage',
        'correctionMessage',
        'contextMessages',
        'documentation',
      }) ||
      value['code'] is! String ||
      value['severity'] is! String ||
      value['type'] is! String ||
      value['problemMessage'] is! String ||
      (value['code'] as String).isEmpty ||
      (value['severity'] as String).isEmpty ||
      (value['type'] as String).isEmpty ||
      (value['problemMessage'] as String).isEmpty ||
      (value.containsKey('correctionMessage') &&
          value['correctionMessage'] is! String) ||
      (value.containsKey('documentation') &&
          value['documentation'] is! String) ||
      !_isLocation(value['location']) ||
      !_areContextMessagesValid(value['contextMessages'])) {
    return null;
  }

  final location = value['location'] as Map;
  final range = location['range'] as Map;
  final start = range['start'] as Map;
  final end = range['end'] as Map;
  final file = _relPath(location['file'] as String);
  if (file.isEmpty) return null;
  return _LayerDiagnostic(
    code: value['code'] as String,
    file: file,
    lineStart: (start['line'] as int) + 1,
    lineEnd: (end['line'] as int) + 1,
    message: value['problemMessage'] as String,
    correction: value['correctionMessage'] as String?,
  );
}

bool _hasOnlyKeys(Map value, Set<String> allowed) =>
    value.keys.every((key) => key is String && allowed.contains(key));

bool _isLocation(dynamic value) {
  if (value is! Map ||
      value.length != 2 ||
      value['file'] is! String ||
      (value['file'] as String).isEmpty ||
      value['range'] is! Map) {
    return false;
  }
  final range = value['range'] as Map;
  return range.length == 2 &&
      _isPosition(range['start']) &&
      _isPosition(range['end']);
}

bool _isPosition(dynamic value) =>
    value is Map &&
    value.length == 3 &&
    value['offset'] is int &&
    value['line'] is int &&
    value['column'] is int;

bool _areContextMessagesValid(dynamic value) {
  if (value == null) return true;
  if (value is! List) return false;
  return value.every(
    (message) =>
        message is Map &&
        message.length == 2 &&
        message['message'] is String &&
        _isLocation(message['location']),
  );
}

Future<_LayerScan> _runTextReporter(LayerCommandRunner commandRunner) async {
  final result = await commandRunner('dart', [
    'run',
    'custom_lint',
    '--no-fatal-infos',
  ]);
  if (result.exitCode > 1) {
    return const _LayerScan.failure(
      'layer text reporter exited unsuccessfully',
    );
  }
  return _parseTextReporter(_normalizeOutput(result.stdout));
}

_LayerScan _parseTextReporter(String output) {
  if (output == 'No issues found!' ||
      output == 'Analyzing...\n\nNo issues found!') {
    return const _LayerScan.success([]);
  }
  if (output.isEmpty) {
    return const _LayerScan.failure('layer text reporter emitted no output');
  }

  final lines = const LineSplitter().convert(output);
  if (lines.length < 3 || lines[lines.length - 2].isNotEmpty) {
    return const _LayerScan.failure(
      'layer text reporter emitted an unrecognized report',
    );
  }
  final summary = RegExp(r'^(\d+) issue(s)? found\.$').firstMatch(lines.last);
  if (summary == null) {
    return const _LayerScan.failure(
      'layer text reporter emitted an unrecognized report',
    );
  }
  final declaredCount = int.parse(summary.group(1)!);
  final usesPlural = summary.group(2) != null;
  final diagnosticLines = lines.sublist(0, lines.length - 2);
  if (declaredCount != diagnosticLines.length ||
      (declaredCount == 1 && usesPlural) ||
      (declaredCount != 1 && !usesPlural)) {
    return const _LayerScan.failure(
      'layer text reporter emitted an unrecognized report',
    );
  }

  final findings = <Finding>[];
  for (final line in diagnosticLines) {
    final match = _textLine.firstMatch(line);
    if (match == null ||
        int.parse(match.group(2)!) < 1 ||
        int.parse(match.group(3)!) < 1) {
      return const _LayerScan.failure(
        'layer text reporter emitted a malformed diagnostic',
      );
    }
    final code = match.group(5)!;
    final file = match.group(1)!;
    if (!code.startsWith('import_guard') || _isGenerated(file)) continue;
    final lineNumber = int.parse(match.group(2)!);
    findings.add(
      Finding(
        category: 'layer_violation',
        severity: 'CRITICAL',
        filePath: file,
        lineStart: lineNumber,
        lineEnd: lineNumber,
        description: match.group(4)!,
        rationale: 'Layer violation flagged by $code',
        suggestedFix: 'Move/refactor to satisfy the layer rule.',
        toolSource: 'import_guard',
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
    'tool_source': 'import_guard',
    'scan_state': 'ran',
    'generated_at': (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'findings': <Map<String, dynamic>>[],
  };

  try {
    final json = await _runJsonReporter(runCommand);
    final scan = json.diagnostic == 'layer JSON reporter emitted no output'
        ? await _runTextReporter(runCommand)
        : json;
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
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = '.planning/audit/shards/layer.json';
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
