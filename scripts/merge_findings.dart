// scripts/merge_findings.dart
// Reads .planning/audit/{shards,agent-shards}/*.json, dedupes,
// stamps stable IDs, writes issues.json + ISSUES.md.

import 'dart:convert';
import 'dart:io';

import 'audit/finding.dart';

const _categoryPrefix = {
  'layer_violation': 'LV',
  'provider_hygiene': 'PH',
  'dead_code': 'DC',
  'redundant_code': 'RD',
};

const _generatedFileGlobs = ['.g.dart', '.freezed.dart', '.mocks.dart'];

bool _isGenerated(String path) =>
    _generatedFileGlobs.any(path.endsWith) || path.contains('lib/generated/');

Future<void> main(List<String> args) async {
  final shards = <Finding>[];
  for (final dir in const ['shards', 'agent-shards']) {
    final shardDir = Directory('.planning/audit/$dir');
    if (!shardDir.existsSync()) continue;
    final files = shardDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (!f.path.endsWith('.json')) continue;
      final raw = await f.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (e) {
        stderr.writeln('[audit:merge] WARNING: failed to parse ${f.path}: $e');
        continue;
      }
      final findingsRaw = data['findings'];
      if (findingsRaw is! List) continue;
      for (final entry in findingsRaw) {
        if (entry is! Map) continue;
        try {
          shards.add(Finding.fromJson(entry.cast<String, dynamic>()));
        } catch (e) {
          // Pitfall P1-10: skip malformed entries with stderr warning.
          stderr.writeln(
            '[audit:merge] WARNING: malformed finding in ${f.path}: $e',
          );
        }
      }
    }
  }

  // 1. Drop generated-file findings (defense-in-depth — Pitfall P1-6 echo).
  final filtered = shards.where((f) => !_isGenerated(f.filePath)).toList();

  // 2. Dedupe by (file_path, line_start, category) — prefer high confidence;
  //    tool > agent on tie.
  final byKey = <String, Finding>{};
  for (final f in filtered) {
    final k = '${f.filePath}|${f.lineStart}|${f.category}';
    final existing = byKey[k];
    if (existing == null || _isPreferred(f, over: existing)) {
      byKey[k] = f;
    }
  }

  // 3. Sort deterministically: file_path asc, line_start asc, category prefix.
  final sorted = byKey.values.toList()
    ..sort((a, b) {
      final fp = a.filePath.compareTo(b.filePath);
      if (fp != 0) return fp;
      final ln = a.lineStart.compareTo(b.lineStart);
      if (ln != 0) return ln;
      return _categoryPrefix[a.category]!.compareTo(
        _categoryPrefix[b.category]!,
      );
    });

  // 4. Stamp IDs per category in sort order.
  final counters = <String, int>{};
  final stamped = sorted.map((f) {
    final prefix = _categoryPrefix[f.category]!;
    final n = (counters[prefix] = (counters[prefix] ?? 0) + 1);
    return Finding(
      id: '$prefix-${n.toString().padLeft(3, '0')}',
      category: f.category,
      severity: f.severity,
      filePath: f.filePath,
      lineStart: f.lineStart,
      lineEnd: f.lineEnd,
      description: f.description,
      rationale: f.rationale,
      suggestedFix: f.suggestedFix,
      toolSource: f.toolSource,
      confidence: f.confidence,
      status: f.status,
      closedInPhase: f.closedInPhase,
      closedCommit: f.closedCommit,
    );
  }).toList();

  // 5. Emit issues.json (machine-readable; no top-level timestamp so the
  //    file is byte-identical across re-runs — see merger_findings_test.dart).
  final issuesPath = '.planning/audit/issues.json';
  final issuesDir = Directory('.planning/audit');
  if (!issuesDir.existsSync()) issuesDir.createSync(recursive: true);
  await File(issuesPath).writeAsString(
    const JsonEncoder.withIndent(
      '  ',
    ).convert({'findings': stamped.map((f) => f.toJson()).toList()}),
  );

  // 6. Emit ISSUES.md (human-readable, severity-then-category, table per group).
  final md = _renderMarkdown(stamped);
  await File('.planning/audit/ISSUES.md').writeAsString(md);

  print('[audit:merge] wrote ${stamped.length} findings to $issuesPath');
}

bool _isPreferred(Finding a, {required Finding over}) {
  // Higher-confidence wins; tie-broken by preferring tool_source over agent:*
  const order = {'high': 3, 'medium': 2, 'low': 1};
  final aRank = order[a.confidence] ?? 0;
  final overRank = order[over.confidence] ?? 0;
  if (aRank > overRank) return true;
  if (aRank < overRank) return false;
  final aIsAgent = a.toolSource.startsWith('agent:');
  final overIsAgent = over.toolSource.startsWith('agent:');
  if (!aIsAgent && overIsAgent) return true;
  return false;
}

String _renderMarkdown(List<Finding> findings) {
  final buf = StringBuffer();
  buf.writeln('# Audit Findings');
  buf.writeln();
  buf.writeln('**Total findings:** ${findings.length}');
  buf.writeln();

  const severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
  const categoryLabels = {
    'layer_violation': 'Layer Violations',
    'provider_hygiene': 'Provider Hygiene',
    'dead_code': 'Dead Code',
    'redundant_code': 'Redundant Code',
  };
  const categoryOrder = [
    'layer_violation',
    'provider_hygiene',
    'dead_code',
    'redundant_code',
  ];

  for (final sev in severities) {
    final inSev = findings.where((f) => f.severity == sev).toList();
    if (inSev.isEmpty) continue;
    buf.writeln('## $sev');
    buf.writeln();
    for (final cat in categoryOrder) {
      final inCat = inSev.where((f) => f.category == cat).toList();
      if (inCat.isEmpty) continue;
      buf.writeln('### ${categoryLabels[cat]}');
      buf.writeln();
      buf.writeln(
        '| ID | File:Line | Description | Suggested Fix | tool_source |',
      );
      buf.writeln(
        '|----|-----------|-------------|---------------|-------------|',
      );
      for (final f in inCat) {
        buf.writeln(
          '| ${f.id} | ${f.filePath}:${f.lineStart} | ${_md(f.description)} | ${_md(f.suggestedFix)} | ${f.toolSource} |',
        );
      }
      buf.writeln();
    }
  }

  return buf.toString();
}

String _md(String s) => s.replaceAll('|', r'\|').replaceAll('\n', ' ');
