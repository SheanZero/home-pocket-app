// scripts/audit/dead_code.dart
// Runs dart_code_linter:metrics check-unused-{code,files}, emits .planning/audit/shards/dead_code.json.
import 'dart:convert';
import 'dart:io';

import 'finding.dart';

const _generatedFileSuffixes = ['.g.dart', '.freezed.dart', '.mocks.dart'];

bool _isGenerated(String path) =>
    _generatedFileSuffixes.any(path.endsWith) ||
    path.contains('lib/generated/');

typedef DeadCodeCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class DeadCodeAuditRun {
  const DeadCodeAuditRun({required this.envelope, required this.exitCode});

  final Map<String, dynamic> envelope;
  final int exitCode;
}

class _UnusedScan {
  const _UnusedScan.success(this.findings) : diagnostic = null;

  const _UnusedScan.failure(this.diagnostic) : findings = const [];

  final List<Finding> findings;
  final String? diagnostic;

  bool get failed => diagnostic != null;
}

String _relPath(String absPath) {
  final cwd = Directory.current.path;
  if (absPath.startsWith('$cwd/')) {
    return absPath.substring(cwd.length + 1);
  }
  return absPath;
}

Future<_UnusedScan> _runUnused(
  String mode,
  DeadCodeCommandRunner commandRunner,
) async {
  // mode: 'check-unused-code' | 'check-unused-files'
  final findings = <Finding>[];

  final arguments = [
    'run',
    'dart_code_linter:metrics',
    mode,
    'lib',
    '--reporter=json',
  ];
  ProcessResult result;
  try {
    result = await commandRunner('dart', arguments);
  } on ProcessException {
    return _UnusedScan.failure('$mode could not be run');
  } catch (_) {
    return _UnusedScan.failure('$mode could not be run');
  }

  if (result.exitCode != 0) {
    return _UnusedScan.failure('$mode exited with status ${result.exitCode}');
  }

  try {
    final stdout = result.stdout;
    final normalizedOutput = _stripAnsi(
      stdout is String ? stdout : '',
    ).replaceAll('\r', '\n').trim();
    if (_isConfirmedZeroFindingOutput(normalizedOutput)) {
      return _UnusedScan.success(findings);
    }
    final stdoutText = _extractJsonPayload(normalizedOutput);
    if (stdoutText.isEmpty) {
      return _UnusedScan.failure('$mode emitted empty output');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(stdoutText);
    } on FormatException {
      return _UnusedScan.failure('$mode emitted malformed JSON');
    } catch (_) {
      return _UnusedScan.failure('$mode emitted malformed JSON');
    }

    Iterable<dynamic>? records;
    if (decoded is List) {
      records = decoded;
    } else if (decoded is Map) {
      // common shapes: {records: [...]} or {issues: [...]} or {files: [...]}
      for (final key in const [
        'records',
        'issues',
        'files',
        'unusedCode',
        'unusedFiles',
      ]) {
        final v = decoded[key];
        if (v is List) {
          records = v;
          break;
        }
      }
    }

    if (records == null) {
      return _UnusedScan.failure('$mode emitted an unrecognized JSON report');
    }

    for (final r in records) {
      if (r is! Map) continue;
      final filePath =
          (r['path'] as String?) ??
          (r['file'] as String?) ??
          (r['filePath'] as String?) ??
          '';
      final relFile = _relPath(filePath);
      if (relFile.isEmpty) continue;
      if (_isGenerated(relFile)) continue;

      final issues = r['issues'];
      if (issues is List && issues.isNotEmpty) {
        for (final iss in issues) {
          if (iss is! Map) continue;
          final loc = iss['location'];
          var lineStart = (iss['line'] as int?) ?? 1;
          var lineEnd = lineStart;
          if (loc is Map) {
            final start = loc['start'];
            final end = loc['end'];
            if (start is Map && start['line'] is int) {
              lineStart = start['line'] as int;
            }
            if (end is Map && end['line'] is int) {
              lineEnd = end['line'] as int;
            }
          }
          final desc =
              (iss['message'] as String?) ??
              (iss['ruleId'] as String?) ??
              _formatUnusedDeclaration(iss) ??
              'Unused code element';
          findings.add(
            Finding(
              category: 'dead_code',
              severity: 'LOW',
              filePath: relFile,
              lineStart: lineStart,
              lineEnd: lineEnd,
              description: desc,
              rationale: 'dart_code_linter:metrics $mode',
              suggestedFix: mode == 'check-unused-files'
                  ? 'Delete the file if truly unused.'
                  : 'Remove the unused declaration or export it.',
              toolSource: 'dart_code_linter',
              confidence: 'high',
            ),
          );
        }
      } else if (mode == 'check-unused-files') {
        // unused-files reports may have only the path
        findings.add(
          Finding(
            category: 'dead_code',
            severity: 'LOW',
            filePath: relFile,
            lineStart: 1,
            lineEnd: 1,
            description: 'Unused file (no incoming imports detected)',
            rationale: 'dart_code_linter:metrics check-unused-files',
            suggestedFix: 'Delete the file if truly unused.',
            toolSource: 'dart_code_linter',
            confidence: 'high',
          ),
        );
      }
    }
  } catch (_) {
    return _UnusedScan.failure('$mode report could not be processed');
  }
  return _UnusedScan.success(findings);
}

String _extractJsonPayload(String output) {
  final firstObject = output.indexOf('{');
  final firstArray = output.indexOf('[');
  final starts = [firstObject, firstArray].where((index) => index >= 0);
  if (starts.isEmpty) {
    return output;
  }
  final start = starts.reduce((a, b) => a < b ? a : b);
  final end = output[start] == '{'
      ? output.lastIndexOf('}')
      : output.lastIndexOf(']');
  if (end < start) return output;
  return output.substring(start, end + 1);
}

String _stripAnsi(String output) =>
    output.replaceAll(RegExp('\u001b\\[[0-?]*[ -/]*[@-~]'), '');

bool _isConfirmedZeroFindingOutput(String output) {
  // dart_code_linter 3.x ignores --reporter=json for a clean scan and emits
  // only this completion line (plus optional update notices). Treat that exact
  // tool-owned success signal as zero findings; arbitrary non-JSON output is
  // still a failed scan.
  return !output.contains('{') &&
      !output.contains('[') &&
      RegExp(
        r'(^|\n)✔ Analysis is completed\. Preparing the results: [^\n]+',
      ).hasMatch(output);
}

String? _formatUnusedDeclaration(Map<dynamic, dynamic> issue) {
  final type = issue['declarationType'] as String?;
  final name = issue['declarationName'] as String?;
  if (type == null && name == null) return null;
  if (type == null) return 'Unused declaration `$name`';
  if (name == null) return 'Unused $type';
  return 'Unused $type `$name`';
}

Future<DeadCodeAuditRun> runDeadCodeAudit({
  DeadCodeCommandRunner? commandRunner,
  DateTime? generatedAt,
}) async {
  final runCommand =
      commandRunner ??
      (executable, arguments) =>
          Process.run(executable, arguments, runInShell: true);
  final envelope = <String, dynamic>{
    'tool_source': 'dart_code_linter',
    'scan_state': 'ran',
    'generated_at': (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'findings': <Map<String, dynamic>>[],
  };

  try {
    final unusedCode = await _runUnused('check-unused-code', runCommand);
    if (unusedCode.failed) {
      return _failedRun(envelope, unusedCode.diagnostic!);
    }
    final unusedFiles = await _runUnused('check-unused-files', runCommand);
    if (unusedFiles.failed) {
      return _failedRun(envelope, unusedFiles.diagnostic!);
    }
    final all = [...unusedCode.findings, ...unusedFiles.findings];
    envelope['findings'] = all.map((f) => f.toJson()).toList();
  } catch (_) {
    return _failedRun(envelope, 'dead-code scan could not be completed');
  }
  return DeadCodeAuditRun(envelope: envelope, exitCode: 0);
}

DeadCodeAuditRun _failedRun(Map<String, dynamic> envelope, String diagnostic) {
  envelope['scan_state'] = 'not_run';
  envelope['scan_failed'] = true;
  // Never include scanner stdout/stderr or exception text in the shard: source
  // scans can encounter sensitive user-facing literals.
  envelope['error'] = diagnostic;
  return DeadCodeAuditRun(envelope: envelope, exitCode: 1);
}

Future<void> main(List<String> args) async {
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = '.planning/audit/shards/dead_code.json';
  final run = await runDeadCodeAudit();

  await File(
    shardPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(run.envelope));
  final n = (run.envelope['findings'] as List).length;
  stdout.writeln('[audit:dead_code] wrote $n findings to $shardPath');
  if (run.exitCode != 0) {
    stderr.writeln('[audit:dead_code] ERROR: ${run.envelope['error']}');
    exitCode = run.exitCode;
  }
}
