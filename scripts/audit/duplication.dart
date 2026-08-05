// Repository-owned, exact structural duplication audit for Dart source.
//
// This deliberately detects only cross-file clones of at least sixteen
// meaningful, normalized lines. It is conservative by design: a small, exact
// signal is more actionable than a broad heuristic that fills the audit with
// framework boilerplate or coincidental snippets.
import 'dart:convert';
import 'dart:io';

import 'finding.dart';

const _toolSource = 'owned_duplication_detector';
const _minimumCloneLines = 16;
const _generatedFileSuffixes = ['.g.dart', '.freezed.dart', '.mocks.dart'];

bool _isGenerated(String path) =>
    _generatedFileSuffixes.any(path.endsWith) ||
    path.replaceAll('\\', '/').contains('/generated/');

class _CodeLine {
  const _CodeLine({required this.lineNumber, required this.normalized});

  final int lineNumber;
  final String normalized;
}

class _CloneOccurrence {
  const _CloneOccurrence({
    required this.path,
    required this.start,
    required this.lines,
  });

  final String path;
  final int start;
  final List<_CodeLine> lines;
}

class _CloneCluster {
  _CloneCluster(this.first, this.second)
    : firstStart = first.start,
      firstEnd = first.start + _minimumCloneLines,
      secondStart = second.start,
      secondEnd = second.start + _minimumCloneLines;

  final _CloneOccurrence first;
  final _CloneOccurrence second;
  final int firstStart;
  int firstEnd;
  final int secondStart;
  int secondEnd;

  bool overlaps(_CloneOccurrence nextFirst, _CloneOccurrence nextSecond) =>
      nextFirst.start < firstEnd && nextSecond.start < secondEnd;

  void extend(_CloneOccurrence nextFirst, _CloneOccurrence nextSecond) {
    firstEnd = firstEnd < nextFirst.start + _minimumCloneLines
        ? nextFirst.start + _minimumCloneLines
        : firstEnd;
    secondEnd = secondEnd < nextSecond.start + _minimumCloneLines
        ? nextSecond.start + _minimumCloneLines
        : secondEnd;
  }
}

/// Builds a complete shard envelope for the structural duplication scan.
///
/// [projectRoot] makes fixture use deterministic and defaults to the current
/// directory for normal repository runs.
Map<String, dynamic> buildDuplicationAuditEnvelope({
  String sourcePath = 'lib',
  String? projectRoot,
  DateTime? generatedAt,
}) {
  final root = _normalizedAbsolutePath(projectRoot ?? '.');
  final source = Directory(_normalizedAbsolutePath(sourcePath));
  final findings = _findCrossFileClones(source, root, _readAllowlist(root));
  return {
    'tool_source': _toolSource,
    'scan_state': 'ran',
    'generated_at': (generatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'findings': findings.map((finding) => finding.toJson()).toList(),
    'detector': {
      'kind': 'exact_normalized_line_clone',
      'minimum_lines': _minimumCloneLines,
      'scope': _relativePath(source.path, root),
    },
  };
}

List<Finding> _findCrossFileClones(
  Directory source,
  String projectRoot,
  Map<String, String> allowlist,
) {
  if (!source.existsSync()) {
    throw FileSystemException('Source directory does not exist', source.path);
  }

  final windows = <String, List<_CloneOccurrence>>{};
  final files =
      source
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !_isGenerated(file.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relativePath = _relativePath(file.path, projectRoot);
    final lines = _meaningfulLines(file);
    for (var start = 0; start <= lines.length - _minimumCloneLines; start++) {
      final window = lines.sublist(start, start + _minimumCloneLines);
      final key = window.map((line) => line.normalized).join('\n');
      windows
          .putIfAbsent(key, () => [])
          .add(
            _CloneOccurrence(path: relativePath, start: start, lines: lines),
          );
    }
  }

  final clustersByFilePair = <String, List<_CloneCluster>>{};
  final keys = windows.keys.toList()..sort();
  for (final key in keys) {
    final occurrences = windows[key]!;
    for (var firstIndex = 0; firstIndex < occurrences.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < occurrences.length;
        secondIndex++
      ) {
        final first = occurrences[firstIndex];
        final second = occurrences[secondIndex];
        if (first.path == second.path) continue;
        final pair = _filePairKey(first.path, second.path);
        clustersByFilePair
            .putIfAbsent(pair, () => [])
            .add(_CloneCluster(first, second));
      }
    }
  }

  final findings = <Finding>[];
  final pairs = clustersByFilePair.keys.toList()..sort();
  for (final pair in pairs) {
    final candidates = clustersByFilePair[pair]!
      ..sort((a, b) {
        final first = a.firstStart.compareTo(b.firstStart);
        return first != 0 ? first : a.secondStart.compareTo(b.secondStart);
      });
    final clusters = <_CloneCluster>[];
    for (final candidate in candidates) {
      final previous = clusters.isEmpty ? null : clusters.last;
      if (previous != null &&
          previous.overlaps(candidate.first, candidate.second)) {
        previous.extend(candidate.first, candidate.second);
      } else {
        clusters.add(candidate);
      }
    }
    for (final cluster in clusters) {
      final firstLines = cluster.first.lines.sublist(
        cluster.firstStart,
        cluster.firstEnd,
      );
      final secondLines = cluster.second.lines.sublist(
        cluster.secondStart,
        cluster.secondEnd,
      );
      final fingerprint = _fingerprint(
        firstLines.map((line) => line.normalized),
      );
      final allowlistRationale = allowlist['$pair|$fingerprint'];
      final firstStart = firstLines.first.lineNumber;
      final secondStart = secondLines.first.lineNumber;
      findings.add(
        Finding(
          category: 'redundant_code',
          severity: 'LOW',
          filePath: cluster.second.path,
          lineStart: secondStart,
          lineEnd: secondLines.last.lineNumber,
          description:
              'Exact $_minimumCloneLines-line structural clone also appears at ${cluster.first.path}:$firstStart.',
          rationale: allowlistRationale == null
              ? 'Repository-owned duplication detector found identical normalized Dart source across files. Fingerprint: $fingerprint.'
              : 'Accepted duplicate clone: $allowlistRationale Fingerprint: $fingerprint.',
          suggestedFix:
              'Extract a shared helper only if the duplicated behavior has the same domain responsibility.',
          toolSource: _toolSource,
          confidence: 'medium',
          status: allowlistRationale == null ? 'open' : 'accepted',
        ),
      );
    }
  }
  findings.sort((a, b) {
    final path = a.filePath.compareTo(b.filePath);
    return path != 0 ? path : a.lineStart.compareTo(b.lineStart);
  });
  return findings;
}

Map<String, String> _readAllowlist(String projectRoot) {
  final file = File('$projectRoot/.planning/audit/duplication_allowlist.json');
  if (!file.existsSync()) return const {};
  try {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entries = decoded['accepted'];
    if (entries is! List) return const {};
    return {
      for (final entry in entries.whereType<Map>())
        if (entry['files'] is List &&
            (entry['files'] as List).length == 2 &&
            entry['fingerprint'] is String &&
            entry['rationale'] is String)
          '${_filePairKey((entry['files'] as List)[0] as String, (entry['files'] as List)[1] as String)}|${entry['fingerprint']}':
              entry['rationale'] as String,
    };
  } catch (_) {
    return const {};
  }
}

String _fingerprint(Iterable<String> lines) {
  // FNV-1a 64-bit is deterministic without a package dependency and is used
  // only as an exact review key, never as a security primitive.
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final codeUnit in lines.join('\n').codeUnits) {
    hash = (hash ^ BigInt.from(codeUnit)) * prime & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

List<_CodeLine> _meaningfulLines(File file) {
  final lines = file.readAsLinesSync();
  final result = <_CodeLine>[];
  var inBlockComment = false;
  for (var index = 0; index < lines.length; index++) {
    var line = lines[index].trim();
    if (inBlockComment) {
      if (line.contains('*/')) inBlockComment = false;
      continue;
    }
    if (line.startsWith('/*')) {
      if (!line.contains('*/')) inBlockComment = true;
      continue;
    }
    if (line.isEmpty ||
        line.startsWith('//') ||
        line.startsWith('import ') ||
        line.startsWith('export ') ||
        line.startsWith('part ') ||
        line.startsWith('@')) {
      continue;
    }

    final commentStart = line.indexOf('//');
    if (commentStart >= 0) line = line.substring(0, commentStart).trimRight();
    if (line.isEmpty) continue;
    result.add(
      _CodeLine(
        lineNumber: index + 1,
        normalized: line.replaceAll(RegExp(r'\s+'), ''),
      ),
    );
  }
  return result;
}

String _filePairKey(String first, String second) =>
    first.compareTo(second) <= 0 ? '$first|$second' : '$second|$first';

String _relativePath(String path, String root) {
  final normalizedPath = _normalizedAbsolutePath(path);
  final normalizedRoot = _normalizedAbsolutePath(root);
  if (normalizedPath.startsWith('$normalizedRoot/')) {
    return normalizedPath.substring(normalizedRoot.length + 1);
  }
  return normalizedPath;
}

String _normalizedAbsolutePath(String path) {
  var normalized = Directory(path).absolute.path.replaceAll('\\', '/');
  while (normalized.endsWith('/.')) {
    normalized = normalized.substring(0, normalized.length - 2);
  }
  return normalized;
}

class _Arguments {
  const _Arguments({required this.sourcePath, required this.outputPath});

  final String sourcePath;
  final String outputPath;
}

_Arguments _parseArguments(List<String> args) {
  var sourcePath = 'lib';
  var outputPath = '.planning/audit/shards/duplication.json';
  for (var index = 0; index < args.length; index++) {
    final argument = args[index];
    if (argument != '--source' && argument != '--output') {
      throw ArgumentError('Unknown argument: $argument');
    }
    if (++index >= args.length) {
      throw ArgumentError('$argument requires a value');
    }
    if (argument == '--source') sourcePath = args[index];
    if (argument == '--output') outputPath = args[index];
  }
  return _Arguments(sourcePath: sourcePath, outputPath: outputPath);
}

Future<void> main(List<String> args) async {
  const defaultOutput = '.planning/audit/shards/duplication.json';
  var outputPath = defaultOutput;
  Map<String, dynamic> envelope;

  try {
    final parsed = _parseArguments(args);
    outputPath = parsed.outputPath;
    envelope = buildDuplicationAuditEnvelope(sourcePath: parsed.sourcePath);
  } catch (error, stackTrace) {
    envelope = {
      'tool_source': _toolSource,
      'scan_state': 'not_run',
      'scan_failed': true,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'findings': <Map<String, dynamic>>[],
      'error': error.toString(),
    };
    stderr.writeln('[audit:duplication] ERROR: scan did not run: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }

  final output = File(outputPath);
  if (!output.parent.existsSync()) output.parent.createSync(recursive: true);
  await output.writeAsString(
    const JsonEncoder.withIndent('  ').convert(envelope),
  );
  final count = (envelope['findings'] as List).length;
  stdout.writeln('[audit:duplication] wrote $count findings to $outputPath');
}
