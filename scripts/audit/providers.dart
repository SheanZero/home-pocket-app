// scripts/audit/providers.dart
// Runs custom_lint, filters to riverpod_lint codes, emits .planning/audit/shards/providers.json.
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

List<Finding> _parseTextReporter(String text) {
  final findings = <Finding>[];
  for (final line in const LineSplitter().convert(text)) {
    final m = _textLine.firstMatch(line);
    if (m == null) continue;
    final code = m.group(5)!;
    if (!code.startsWith('riverpod')) continue;
    final relFile = m.group(1)!;
    if (_isGenerated(relFile)) continue;
    final lineNum = int.tryParse(m.group(2)!) ?? 1;
    final desc = m.group(4)!;
    findings.add(
      Finding(
        category: 'provider_hygiene',
        severity: 'HIGH',
        filePath: relFile,
        lineStart: lineNum,
        lineEnd: lineNum,
        description: desc,
        rationale: 'Provider hygiene flagged by $code',
        suggestedFix: 'Apply the riverpod_lint suggested change.',
        toolSource: 'riverpod_lint',
        confidence: 'high',
      ),
    );
  }
  return findings;
}

Future<void> main(List<String> args) async {
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  final shardPath = '.planning/audit/shards/providers.json';
  Map<String, dynamic> envelope = {
    'tool_source': 'riverpod_lint',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'findings': <Map<String, dynamic>>[],
  };

  try {
    final jsonResult = await Process.run('dart', [
      'run',
      'custom_lint',
      '--reporter=json',
      '--no-fatal-infos',
    ], runInShell: true);

    final jsonOut = (jsonResult.stdout as String).trim();
    final findings = <Finding>[];

    if (jsonOut.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonOut);
        List<dynamic> diagnostics = const [];
        if (decoded is List) {
          diagnostics = decoded;
        } else if (decoded is Map && decoded['diagnostics'] is List) {
          diagnostics = decoded['diagnostics'] as List<dynamic>;
        }

        for (final d in diagnostics) {
          if (d is! Map) continue;
          final code = (d['code'] as String?) ?? '';
          if (!code.startsWith('riverpod')) continue;

          final loc = d['location'];
          if (loc is! Map) continue;
          final file = (loc['file'] as String?) ?? '';
          final relFile = _relPath(file);
          if (_isGenerated(relFile)) continue;

          int lineStart = 1;
          int lineEnd = 1;
          final range = loc['range'];
          if (range is Map) {
            final start = range['start'];
            final end = range['end'];
            if (start is Map && start['line'] is int) {
              lineStart = (start['line'] as int) + 1;
            }
            if (end is Map && end['line'] is int) {
              lineEnd = (end['line'] as int) + 1;
            }
          }

          final desc =
              (d['problemMessage'] as String?) ??
              'riverpod_lint violation: $code';
          final fix =
              (d['correctionMessage'] as String?) ??
              'Apply the riverpod_lint suggested change.';

          findings.add(
            Finding(
              category: 'provider_hygiene',
              severity: 'HIGH',
              filePath: relFile,
              lineStart: lineStart,
              lineEnd: lineEnd,
              description: desc,
              rationale: 'Provider hygiene flagged by $code',
              suggestedFix: fix,
              toolSource: 'riverpod_lint',
              confidence: 'high',
            ),
          );
        }
      } catch (e) {
        stderr.writeln('[audit:providers] WARNING: jsonDecode failed: $e');
      }
    }

    if (findings.isEmpty) {
      stderr.writeln(
        '[audit:providers] INFO: --reporter=json yielded no findings; falling back to text reporter',
      );
      final textResult = await Process.run('dart', [
        'run',
        'custom_lint',
        '--no-fatal-infos',
      ], runInShell: true);
      findings.addAll(_parseTextReporter(textResult.stdout as String));
    }

    envelope['findings'] = findings.map((f) => f.toJson()).toList();
  } catch (e, st) {
    envelope['scan_failed'] = true;
    envelope['error'] = e.toString();
    stderr.writeln('[audit:providers] WARNING: scan failed: $e\n$st');
  }

  await File(
    shardPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(envelope));
  final n = (envelope['findings'] as List).length;
  print('[audit:providers] wrote $n findings to $shardPath');
}
