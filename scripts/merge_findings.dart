// scripts/merge_findings.dart
// Reads <root>/{shards,agent-shards}/*.json, dedupes,
// stamps stable IDs, writes <root>/issues.json + <root>/ISSUES.md.
// Default root: .planning/audit (backwards-compatible with Phase 1 invocation).
//
// Usage:
//   dart run scripts/merge_findings.dart                            # baseline (root = .planning/audit)
//   dart run scripts/merge_findings.dart --root <path>              # re-audit (e.g. .planning/audit/re-audit)
//
// Exit codes:
//   0 — merge succeeded
//   2 — invocation error (missing --root value, unknown flag, unexpected arg)

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

String _resolveRoot(List<String> args) {
  var root = '.planning/audit';
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--root':
        if (i + 1 >= args.length) {
          stderr.writeln('[audit:merge] ERROR: --root requires a path argument');
          exit(2);
        }
        root = args[i + 1];
        i++;
        break;
      default:
        if (a.startsWith('--')) {
          stderr.writeln('[audit:merge] ERROR: unknown flag: $a');
          exit(2);
        }
        stderr.writeln('[audit:merge] ERROR: unexpected positional arg: $a');
        exit(2);
    }
  }
  return root;
}

Future<void> main(List<String> args) async {
  final root = _resolveRoot(args);
  final existingLifecycle = await _readExistingLifecycle(root);
  final shards = <Finding>[];
  for (final dir in const ['shards', 'agent-shards']) {
    final shardDir = Directory('$root/$dir');
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

  // 4. Compute retainedClosed first so we can reserve their IDs and avoid
  //    duplicate-ID collisions with freshly stamped findings (WR-06).
  final sortedKeys = sorted.map(_lifecycleKey).toSet();
  final retainedClosed = existingLifecycle.values
      .where((finding) => !sortedKeys.contains(_lifecycleKey(finding)))
      .toList();
  final reservedIds = retainedClosed
      .where((f) => f.id != null)
      .map((f) => f.id!)
      .toSet();

  // 5. Stamp IDs per category in sort order, skipping any IDs already
  //    reserved by retainedClosed so the merged catalogue has unique IDs.
  final counters = <String, int>{};
  String nextId(String prefix) {
    while (true) {
      final n = (counters[prefix] = (counters[prefix] ?? 0) + 1);
      final candidate = '$prefix-${n.toString().padLeft(3, '0')}';
      if (!reservedIds.contains(candidate)) return candidate;
    }
  }

  final stamped = sorted.map((f) {
    final prefix = _categoryPrefix[f.category]!;
    final previous = existingLifecycle[_lifecycleKey(f)];
    return Finding(
      id: nextId(prefix),
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
      status: previous?.status ?? f.status,
      closedInPhase: previous?.closedInPhase ?? f.closedInPhase,
      closedCommit: previous?.closedCommit ?? f.closedCommit,
    );
  }).toList();
  final catalogue = [...stamped, ...retainedClosed]..sort(_compareFindings);

  // 5. Emit issues.json (machine-readable; no top-level timestamp so the
  //    file is byte-identical across re-runs — see merger_findings_test.dart).
  final issuesPath = '$root/issues.json';
  final issuesDir = Directory(root);
  if (!issuesDir.existsSync()) issuesDir.createSync(recursive: true);
  await File(issuesPath).writeAsString(
    const JsonEncoder.withIndent(
      '  ',
    ).convert({'findings': catalogue.map((f) => f.toJson()).toList()}),
  );

  // 6. Emit ISSUES.md (human-readable, severity-then-category, table per group).
  final md = _renderMarkdown(catalogue);
  await File('$root/ISSUES.md').writeAsString(md);

  stdout.writeln(
    '[audit:merge] wrote ${catalogue.length} findings to $issuesPath',
  );
}

Future<Map<String, Finding>> _readExistingLifecycle(String root) async {
  final file = File('$root/issues.json');
  if (!file.existsSync()) return const {};

  try {
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final findings = decoded['findings'];
    if (findings is! List) return const {};

    return {
      for (final entry in findings.whereType<Map>())
        if (_hasLifecycle(entry))
          _lifecycleKey(Finding.fromJson(entry.cast<String, dynamic>())):
              Finding.fromJson(entry.cast<String, dynamic>()),
    };
  } catch (e) {
    stderr.writeln(
      '[audit:merge] WARNING: failed to read existing lifecycle metadata: $e',
    );
    return const {};
  }
}

bool _hasLifecycle(Map<dynamic, dynamic> entry) =>
    entry['status'] == 'closed' ||
    entry['closed_in_phase'] != null ||
    entry['closed_commit'] != null;

String _lifecycleKey(Finding finding) =>
    '${finding.category}|${finding.filePath}|${finding.lineStart}|${finding.description}';

int _compareFindings(Finding a, Finding b) {
  final fp = a.filePath.compareTo(b.filePath);
  if (fp != 0) return fp;
  final ln = a.lineStart.compareTo(b.lineStart);
  if (ln != 0) return ln;
  return _categoryPrefix[a.category]!.compareTo(_categoryPrefix[b.category]!);
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
