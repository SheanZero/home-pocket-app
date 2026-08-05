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
          stderr.writeln(
            '[audit:merge] ERROR: --root requires a path argument',
          );
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
  final existingFindings = await _readExistingFindings(root);
  final shards = <Finding>[];
  final incompleteScans = <String>[];
  final completedAuthoritativeTools = <String>{};
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
      if (data['scan_state'] == 'not_run' || data['scan_failed'] == true) {
        incompleteScans.add(f.path);
        stderr.writeln(
          '[audit:merge] ERROR: ${f.path} was not run successfully',
        );
      }
      final completed =
          data['scan_state'] != 'not_run' && data['scan_failed'] != true;
      if (dir == 'shards' && completed && data['tool_source'] is String) {
        completedAuthoritativeTools.add(data['tool_source'] as String);
      }
      // Agent shards established the historical baseline. They are deliberately
      // not current observations: otherwise a stale agent report can reopen a
      // resolved finding after the authoritative tool scan is clean.
      if (dir == 'agent-shards') continue;
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

  // 2. Dedupe exact candidates — prefer high confidence; tool > agent on tie.
  // Clone relationships can share a file/line while referring to different
  // counterpart files, so collapsing solely by location loses real evidence.
  final byKey = <String, Finding>{};
  for (final f in filtered) {
    final k = _lifecycleKey(f);
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

  // 4. Reconcile lifecycle against only successful authoritative observations.
  // Closed/accepted history is retained even when absent. An open finding is
  // resolved only when its own detector completed cleanly; a failed or missing
  // scan is never evidence of a fix.
  final observedExistingIds = sorted
      .map((finding) => _previousFor(finding, existingFindings)?.id)
      .whereType<String>()
      .toSet();
  final retainedHistory = existingFindings.values
      .where(
        (finding) =>
            finding.id == null || !observedExistingIds.contains(finding.id),
      )
      .map((finding) {
        if (finding.status == 'open' &&
            completedAuthoritativeTools.contains(finding.toolSource)) {
          return _withLifecycle(
            finding,
            status: 'closed',
            closedInPhase: 'audit',
          );
        }
        return finding;
      })
      .toList();
  // IDs are permanent for open findings too. Reserve every existing ID before
  // allocating new findings so an inserted shard cannot renumber prior work.
  final reservedIds = existingFindings.values
      .where((f) => f.id != null)
      .map((f) => f.id!)
      .toSet();

  // 5. Stamp IDs per category in sort order, skipping any IDs already
  //    reserved by retained history so the merged catalogue has unique IDs.
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
    final previous = _previousFor(f, existingFindings);
    final isAcceptedObservation = f.status == 'accepted';
    final isReopened =
        previous != null && !isAcceptedObservation && previous.status != 'open';
    return Finding(
      id: previous?.id ?? nextId(prefix),
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
      // Exact allowlist entries are accepted observations. Any non-accepted
      // reappearance reopens closed/accepted history, including source drift
      // that invalidates an allowlist fingerprint.
      status: isAcceptedObservation
          ? 'accepted'
          : (isReopened ? 'open' : f.status),
      closedInPhase: isAcceptedObservation || isReopened
          ? null
          : previous?.closedInPhase ?? f.closedInPhase,
      closedCommit: isAcceptedObservation || isReopened
          ? null
          : previous?.closedCommit ?? f.closedCommit,
    );
  }).toList();
  final catalogue = [...stamped, ...retainedHistory]..sort(_compareFindings);

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
  // A non-empty catalogue is never evidence that every scanner completed.
  final md = _renderMarkdown(catalogue, incompleteScans: incompleteScans);
  await File('$root/ISSUES.md').writeAsString(md);

  stdout.writeln(
    '[audit:merge] wrote ${catalogue.length} findings to $issuesPath',
  );
  if (incompleteScans.isNotEmpty) exitCode = 1;
}

Future<Map<String, Finding>> _readExistingFindings(String root) async {
  final file = File('$root/issues.json');
  if (!file.existsSync()) return const {};

  try {
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final findings = decoded['findings'];
    if (findings is! List) return const {};

    final existing = <String, Finding>{};
    for (final entry in findings.whereType<Map>()) {
      try {
        final finding = Finding.fromJson(entry.cast<String, dynamic>());
        existing[_lifecycleKey(finding)] = finding;
      } catch (error) {
        stderr.writeln(
          '[audit:merge] WARNING: malformed existing finding in $root/issues.json: $error',
        );
      }
    }
    return existing;
  } catch (e) {
    stderr.writeln(
      '[audit:merge] WARNING: failed to read existing lifecycle metadata: $e',
    );
    return const {};
  }
}

String _lifecycleKey(Finding finding) =>
    '${finding.category}|${finding.filePath}|${finding.lineStart}|${finding.description}';

Finding? _previousFor(Finding incoming, Map<String, Finding> existing) {
  final exact = existing[_lifecycleKey(incoming)];
  if (exact != null) return exact;
  if (incoming.toolSource != 'owned_duplication_detector') return null;

  final counterpart = _cloneCounterpart(incoming);
  if (counterpart == null) return null;
  final candidates = existing.values
      .where(
        (existingFinding) =>
            existingFinding.toolSource == 'owned_duplication_detector' &&
            existingFinding.filePath == incoming.filePath &&
            _cloneCounterpart(existingFinding) == counterpart,
      )
      .toList();
  if (candidates.isEmpty) return null;

  // A same-line candidate is the same clone after source drift, including a
  // changed fingerprint. Historical detector records lack fingerprints, so a
  // sole pair candidate remains the stable ID when window clustering corrects
  // its start line.
  for (final candidate in candidates) {
    if (candidate.lineStart == incoming.lineStart) return candidate;
  }
  if (candidates.length == 1 && !_hasFingerprint(candidates.single)) {
    return candidates.single;
  }
  return null;
}

String? _cloneCounterpart(Finding finding) {
  final match = RegExp(
    r'also appears at ([^:]+):\d+\.$',
  ).firstMatch(finding.description);
  return match?[1];
}

bool _hasFingerprint(Finding finding) =>
    finding.rationale.contains('Fingerprint:');

Finding _withLifecycle(
  Finding finding, {
  required String status,
  String? closedInPhase,
}) => Finding(
  id: finding.id,
  category: finding.category,
  severity: finding.severity,
  filePath: finding.filePath,
  lineStart: finding.lineStart,
  lineEnd: finding.lineEnd,
  description: finding.description,
  rationale: finding.rationale,
  suggestedFix: finding.suggestedFix,
  toolSource: finding.toolSource,
  confidence: finding.confidence,
  status: status,
  closedInPhase: closedInPhase,
);

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

String _renderMarkdown(
  List<Finding> findings, {
  List<String> incompleteScans = const [],
}) {
  final buf = StringBuffer();
  final active = findings.where((f) => f.status == 'open').toList();
  final resolved = findings.where((f) => f.status == 'closed').toList();
  final accepted = findings.where((f) => f.status == 'accepted').toList();
  buf.writeln('# Audit Findings');
  buf.writeln();
  buf.writeln('**Total findings:** ${findings.length}');
  buf.writeln('**Active findings:** ${active.length}');
  buf.writeln('**Resolved findings:** ${resolved.length}');
  buf.writeln('**Accepted findings:** ${accepted.length}');
  buf.writeln();

  if (incompleteScans.isNotEmpty) {
    buf.writeln('## Scan Status: INCOMPLETE');
    buf.writeln();
    buf.writeln(
      'The following scanner shards were not run successfully; this report must not be interpreted as a clean audit:',
    );
    for (final scan in incompleteScans) {
      buf.writeln('- `$scan`');
    }
    buf.writeln();
  }

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

  void renderCatalogue(String title, List<Finding> catalogue) {
    buf.writeln('## $title');
    buf.writeln();
    for (final sev in severities) {
      final inSev = catalogue.where((f) => f.severity == sev).toList();
      if (inSev.isEmpty) continue;
      buf.writeln('### $sev');
      buf.writeln();
      for (final cat in categoryOrder) {
        final inCat = inSev.where((f) => f.category == cat).toList();
        if (inCat.isEmpty) continue;
        buf.writeln('#### ${categoryLabels[cat]}');
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
  }

  renderCatalogue('Active Findings', active);
  renderCatalogue('Resolved Findings', resolved);
  renderCatalogue('Accepted Findings', accepted);

  return buf.toString();
}

String _md(String s) => s.replaceAll('|', r'\|').replaceAll('\n', ' ');
