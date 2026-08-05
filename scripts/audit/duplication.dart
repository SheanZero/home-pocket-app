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
  const _CloneOccurrence({required this.path, required this.lineNumber});

  final String path;
  final int lineNumber;
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
  final findings = _findCrossFileClones(source, root);
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

List<Finding> _findCrossFileClones(Directory source, String projectRoot) {
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
            _CloneOccurrence(
              path: relativePath,
              lineNumber: window.first.lineNumber,
            ),
          );
    }
  }

  final findingsByFilePair = <String, Finding>{};
  final keys = windows.keys.toList()..sort();
  for (final key in keys) {
    final occurrences = windows[key]!;
    for (var index = 1; index < occurrences.length; index++) {
      final original = occurrences.first;
      final duplicate = occurrences[index];
      if (original.path == duplicate.path) continue;
      final pair = _filePairKey(original.path, duplicate.path);
      final candidate = Finding(
        category: 'redundant_code',
        severity: 'LOW',
        filePath: duplicate.path,
        lineStart: duplicate.lineNumber,
        lineEnd: duplicate.lineNumber + _minimumCloneLines - 1,
        description:
            'Exact $_minimumCloneLines-line structural clone also appears at ${original.path}:${original.lineNumber}.',
        rationale:
            'Repository-owned duplication detector found identical normalized Dart source across files.',
        suggestedFix:
            'Extract a shared helper only if the duplicated behavior has the same domain responsibility.',
        toolSource: _toolSource,
        confidence: 'medium',
      );
      final existing = findingsByFilePair[pair];
      if (existing == null || candidate.lineStart < existing.lineStart) {
        findingsByFilePair[pair] = candidate;
      }
    }
  }
  final findings = findingsByFilePair.values.toList()
    ..sort((a, b) {
      final path = a.filePath.compareTo(b.filePath);
      return path != 0 ? path : a.lineStart.compareTo(b.lineStart);
    });
  return findings;
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
