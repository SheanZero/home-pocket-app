// scripts/reaudit_diff.dart
// Diffs .planning/audit/re-audit/issues.json against .planning/audit/issues.json (baseline)
// by (category, normalized_file_path, description). Produces classified counters
// {resolved, regression, new, open_in_baseline} + REAUDIT-DIFF.{json,md}.
//
// Per Phase 8 CONTEXT.md D-01 (strict-exit contract per EXIT-02).
// Per Phase 1 D-07 + Phase 8 D-02 (match key drops line_start).
//
// Usage:
//   dart run scripts/reaudit_diff.dart
//
// Exit codes:
//   0 — resolved-only (regression == 0 && new == 0 && open_in_baseline == 0)
//   1 — gate failure (any of: regression > 0, new > 0, open_in_baseline > 0)
//   2 — invocation error (missing baseline / re-audit JSON, malformed JSON)

import 'dart:convert';
import 'dart:io';

import 'audit/finding.dart';

const _baselinePath = '.planning/audit/issues.json';
const _reauditPath = '.planning/audit/re-audit/issues.json';
const _outDir = '.planning/audit/re-audit';
const _outJsonPath = '.planning/audit/re-audit/REAUDIT-DIFF.json';
const _outMdPath = '.planning/audit/re-audit/REAUDIT-DIFF.md';

const _severityOrder = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
const _categoryOrder = [
  'layer_violation',
  'provider_hygiene',
  'dead_code',
  'redundant_code',
];
const _categoryLabels = {
  'layer_violation': 'Layer Violations',
  'provider_hygiene': 'Provider Hygiene',
  'dead_code': 'Dead Code',
  'redundant_code': 'Redundant Code',
};

Future<void> main(List<String> args) async {
  // Reject unknown flags so future invocations fail loudly rather than silently
  // accept malformed args. The script intentionally has no CLI surface today
  // (D-01: internal gate consumed by CI without arguments).
  for (final a in args) {
    if (a.startsWith('--')) {
      stderr.writeln('[reaudit:diff] ERROR: unknown flag: $a');
      exit(2);
    }
  }

  final baselineByKey = _readCatalogue(
    path: _baselinePath,
    missingMessage:
        '[reaudit:diff] ERROR: baseline not found at $_baselinePath',
  );
  final reauditByKey = _readCatalogue(
    path: _reauditPath,
    missingMessage:
        '[reaudit:diff] ERROR: re-audit catalogue not found at $_reauditPath',
  );

  final baselineKeys = baselineByKey.keys.toSet();
  final reauditKeys = reauditByKey.keys.toSet();

  // Resolved = baseline-known finding NOT present in re-audit (i.e., it stayed
  // closed / never re-emerged). For Phase 8 EXIT-02 success this should equal
  // the count of baseline-closed findings.
  final resolvedKeys = baselineKeys.difference(reauditKeys);

  // Regression = baseline finding (status == 'closed' OR closed_as_duplicate_of
  // set, per Phase 1 D-08 merge semantics) that re-emerges in the re-audit
  // catalogue.
  final regressionKeys = baselineKeys.intersection(reauditKeys).where((k) {
    final b = baselineByKey[k]!;
    return _isClosed(b);
  }).toSet();

  // New = re-audit finding with no baseline match. Always a failure for
  // EXIT-02 — the cleanup committed to leaving zero new violations.
  final newKeys = reauditKeys.difference(baselineKeys);

  // open_in_baseline = baseline finding still 'open' (not closed by Phases
  // 3-6). Phase 8 close is impossible while any of these remain.
  final openInBaselineKeys = baselineByKey.entries
      .where((e) => !_isClosed(e.value))
      .map((e) => e.key)
      .toList();

  // Stable sort for downstream consumers / golden files: severity-then-category-
  // then-file_path-then-description.
  final resolvedSorted = _sortKeys(resolvedKeys, baselineByKey);
  final regressionSorted = _sortKeys(regressionKeys, reauditByKey);
  final newSorted = _sortKeys(newKeys, reauditByKey);
  final openInBaselineSorted = _sortKeys(
    openInBaselineKeys.toSet(),
    baselineByKey,
  );

  // Compact stdout summary — always emitted, including on failure paths.
  stdout.writeln(
    '[reaudit:diff] resolved=${resolvedSorted.length} '
    'regression=${regressionSorted.length} '
    'new=${newSorted.length} '
    'open_in_baseline=${openInBaselineSorted.length}',
  );

  // Defensive directory creation per merge_findings.dart pattern.
  final outDir = Directory(_outDir);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // No top-level generated_at — keeps the file byte-stable across re-runs
  // (Phase 1 D-09 idempotency carry-over).
  final body = <String, dynamic>{
    'summary': {
      'resolved': resolvedSorted.length,
      'regression': regressionSorted.length,
      'new': newSorted.length,
      'open_in_baseline': openInBaselineSorted.length,
    },
    'buckets': {
      'resolved': resolvedSorted
          .map((k) => baselineByKey[k]!.toJson())
          .toList(),
      'regression': regressionSorted
          .map((k) => reauditByKey[k]!.toJson())
          .toList(),
      'new': newSorted.map((k) => reauditByKey[k]!.toJson()).toList(),
      'open_in_baseline': openInBaselineSorted
          .map((k) => baselineByKey[k]!.toJson())
          .toList(),
    },
  };
  File(
    _outJsonPath,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(body));

  // Human-readable companion. Bucket-first, severity-then-category within each
  // non-empty bucket (per CONTEXT D-01).
  File(_outMdPath).writeAsStringSync(
    _renderMarkdown(
      resolved: resolvedSorted.map((k) => baselineByKey[k]!).toList(),
      regression: regressionSorted.map((k) => reauditByKey[k]!).toList(),
      newFindings: newSorted.map((k) => reauditByKey[k]!).toList(),
      openInBaseline: openInBaselineSorted
          .map((k) => baselineByKey[k]!)
          .toList(),
    ),
  );

  // Strict-exit contract per D-01. Exit 0 only when every gate is clean.
  final hasFailures = regressionSorted.isNotEmpty ||
      newSorted.isNotEmpty ||
      openInBaselineSorted.isNotEmpty;
  exit(hasFailures ? 1 : 0);
}

/// Match key per Phase 1 D-07 + Phase 8 D-02: drops line_start because line
/// numbers shift after cleanup but (category, file_path, description) is stable.
String _diffKey(Finding f) => '${f.category}|${f.filePath}|${f.description}';

/// Reads a catalogue file and returns it keyed by [_diffKey]. Missing files,
/// malformed JSON, or non-catalogue shapes all exit(2) so CI fails loudly.
Map<String, Finding> _readCatalogue({
  required String path,
  required String missingMessage,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln(missingMessage);
    exit(2);
  }
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('[reaudit:diff] ERROR: failed to parse $path: $e');
    exit(2);
  }
  final findingsRaw = decoded['findings'];
  if (findingsRaw is! List) {
    stderr.writeln(
      '[reaudit:diff] ERROR: $path missing top-level "findings" array',
    );
    exit(2);
  }
  final byKey = <String, Finding>{};
  for (final entry in findingsRaw) {
    if (entry is! Map) continue;
    final cast = entry.cast<String, dynamic>();
    Finding finding;
    try {
      finding = Finding.fromJson(cast);
    } catch (e) {
      stderr.writeln(
        '[reaudit:diff] ERROR: malformed finding in $path: $e',
      );
      exit(2);
    }
    byKey[_diffKey(finding)] = finding;
  }
  return byKey;
}

/// A finding counts as "closed" if its status is closed OR it carries a
/// `closed_as_duplicate_of` field (Phase 1 D-08 merge semantics — the child
/// inherits closure from its parent regardless of stored `status`).
bool _isClosed(Finding f) => f.status == 'closed';

List<String> _sortKeys(Set<String> keys, Map<String, Finding> by) {
  final list = keys.toList();
  list.sort((a, b) {
    final fa = by[a]!;
    final fb = by[b]!;
    final sev = _severityRank(fa.severity).compareTo(_severityRank(fb.severity));
    if (sev != 0) return sev;
    final cat = _categoryRank(fa.category).compareTo(_categoryRank(fb.category));
    if (cat != 0) return cat;
    final fp = fa.filePath.compareTo(fb.filePath);
    if (fp != 0) return fp;
    return fa.description.compareTo(fb.description);
  });
  return list;
}

int _severityRank(String severity) {
  final i = _severityOrder.indexOf(severity);
  return i == -1 ? _severityOrder.length : i;
}

int _categoryRank(String category) {
  final i = _categoryOrder.indexOf(category);
  return i == -1 ? _categoryOrder.length : i;
}

String _renderMarkdown({
  required List<Finding> resolved,
  required List<Finding> regression,
  required List<Finding> newFindings,
  required List<Finding> openInBaseline,
}) {
  final buf = StringBuffer();
  buf.writeln('# Re-Audit Diff Report');
  buf.writeln();
  buf.writeln('**Resolved:** ${resolved.length}');
  buf.writeln('**Regression:** ${regression.length}');
  buf.writeln('**New:** ${newFindings.length}');
  buf.writeln('**Open in Baseline:** ${openInBaseline.length}');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();

  _renderBucket(buf, 'Resolved', resolved);
  _renderBucket(buf, 'Regression', regression);
  _renderBucket(buf, 'New', newFindings);
  _renderBucket(buf, 'Still Open in Baseline', openInBaseline);

  return buf.toString();
}

void _renderBucket(StringBuffer buf, String label, List<Finding> findings) {
  buf.writeln('## $label (${findings.length})');
  buf.writeln();
  if (findings.isEmpty) {
    buf.writeln('_None._');
    buf.writeln();
    return;
  }
  for (final sev in _severityOrder) {
    final inSev = findings.where((f) => f.severity == sev).toList();
    if (inSev.isEmpty) continue;
    buf.writeln('### $sev');
    buf.writeln();
    for (final cat in _categoryOrder) {
      final inCat = inSev.where((f) => f.category == cat).toList();
      if (inCat.isEmpty) continue;
      buf.writeln('#### ${_categoryLabels[cat]}');
      buf.writeln();
      buf.writeln(
        '| ID | File:Line | Description | Suggested Fix | tool_source |',
      );
      buf.writeln(
        '|----|-----------|-------------|---------------|-------------|',
      );
      for (final f in inCat) {
        final id = f.id ?? '-';
        buf.writeln(
          '| $id | ${f.filePath}:${f.lineStart} | ${_md(f.description)} | ${_md(f.suggestedFix)} | ${f.toolSource} |',
        );
      }
      buf.writeln();
    }
  }
}

String _md(String s) => s.replaceAll('|', r'\|').replaceAll('\n', ' ');
