// scripts/audit/dead_code.dart
// Runs dart_code_linter:metrics check-unused-{code,files}, emits .planning/audit/shards/dead_code.json.
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

Future<List<Finding>> _runUnused(String mode) async {
  // mode: 'check-unused-code' | 'check-unused-files'
  final findings = <Finding>[];
  try {
    final result = await Process.run('dart', [
      'run',
      'dart_code_linter:metrics',
      mode,
      'lib',
      '--reporter=json',
    ], runInShell: true);

    final stdoutText = _extractJsonPayload((result.stdout as String).trim());
    if (stdoutText.isEmpty) {
      stderr.writeln(
        '[audit:dead_code] WARNING: $mode produced empty stdout; skipping',
      );
      return findings;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(stdoutText);
    } catch (e) {
      if (result.exitCode == 0 ||
          (result.stdout as String).contains('no unused')) {
        return findings;
      }
      // Assumption A3 fallback: non-JSON output. Skip and return empty.
      stderr.writeln(
        '[audit:dead_code] WARNING: $mode emitted non-JSON output; skipping ($e)',
      );
      return findings;
    }

    Iterable<dynamic> records = const [];
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
  } catch (e, st) {
    stderr.writeln('[audit:dead_code] WARNING: $mode failed: $e\n$st');
  }
  return findings;
}

String _extractJsonPayload(String output) {
  final firstBrace = output.indexOf('{');
  final lastBrace = output.lastIndexOf('}');
  if (firstBrace == -1 || lastBrace == -1 || lastBrace < firstBrace) {
    return output;
  }
  return output.substring(firstBrace, lastBrace + 1);
}

String? _formatUnusedDeclaration(Map<dynamic, dynamic> issue) {
  final type = issue['declarationType'] as String?;
  final name = issue['declarationName'] as String?;
  if (type == null && name == null) return null;
  if (type == null) return 'Unused declaration `$name`';
  if (name == null) return 'Unused $type';
  return 'Unused $type `$name`';
}

Future<void> main(List<String> args) async {
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = '.planning/audit/shards/dead_code.json';
  Map<String, dynamic> envelope = {
    'tool_source': 'dart_code_linter',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'findings': <Map<String, dynamic>>[],
  };

  try {
    final unusedCode = await _runUnused('check-unused-code');
    final unusedFiles = await _runUnused('check-unused-files');
    final all = [...unusedCode, ...unusedFiles];
    envelope['findings'] = all.map((f) => f.toJson()).toList();
  } catch (e, st) {
    envelope['scan_failed'] = true;
    envelope['error'] = e.toString();
    stderr.writeln('[audit:dead_code] WARNING: scan failed: $e\n$st');
  }

  await File(
    shardPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(envelope));
  final n = (envelope['findings'] as List).length;
  stdout.writeln('[audit:dead_code] wrote $n findings to $shardPath');
}
