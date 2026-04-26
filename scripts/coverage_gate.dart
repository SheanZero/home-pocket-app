// scripts/coverage_gate.dart
// Per-file coverage gate. Hybrid CLI: positional + --list + fallback.
// CONTEXT.md D-01..D-04. NOT wired into CI in Phase 2 (D-06); local + fix-phase
// verify only.
//
// Usage:
//   dart run scripts/coverage_gate.dart [<file>...]
//                                       [--list <path>]
//                                       [--threshold N]
//                                       [--lcov <path>]
//                                       [--json]
//
// Exit codes (D-04):
//   0 — every supplied file met threshold
//   1 — at least one file below threshold (gate failure)
//   2 — invocation error (missing lcov, unknown flag, no files supplied)

import 'dart:convert';
import 'dart:io';

import 'coverage/lcov_parser.dart';

const _defaultLcov = 'coverage/lcov_clean.info';
const _fallbackList = '.planning/audit/files-needing-tests.txt';

Future<void> main(List<String> args) async {
  // Defaults from D-02 (threshold) / D-03 (lcov path).
  var threshold = 80;
  var lcovPath = _defaultLcov;
  var emitJson = false;
  String? listPath;
  final positionals = <String>[];

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--threshold':
        if (i + 1 >= args.length) {
          stderr.writeln(
            '[coverage:gate] ERROR: --threshold requires an integer',
          );
          exit(2);
        }
        final raw = args[++i];
        final parsed = int.tryParse(raw);
        if (parsed == null) {
          stderr.writeln(
            '[coverage:gate] ERROR: --threshold requires integer, got: $raw',
          );
          exit(2);
        }
        threshold = parsed;
      case '--lcov':
        if (i + 1 >= args.length) {
          stderr.writeln('[coverage:gate] ERROR: --lcov requires a path');
          exit(2);
        }
        lcovPath = args[++i];
      case '--list':
        if (i + 1 >= args.length) {
          stderr.writeln('[coverage:gate] ERROR: --list requires a path');
          exit(2);
        }
        listPath = args[++i];
      case '--json':
        emitJson = true;
      default:
        if (a.startsWith('--')) {
          stderr.writeln('[coverage:gate] ERROR: unknown flag: $a');
          exit(2);
        }
        positionals.add(a);
    }
  }

  // D-01 input resolution chain.
  final files = <String>{...positionals};
  if (listPath != null) {
    final f = File(listPath);
    if (!f.existsSync()) {
      stderr.writeln('[coverage:gate] ERROR: --list path not found: $listPath');
      exit(2);
    }
    files.addAll(f.readAsLinesSync().where((l) => l.trim().isNotEmpty));
  }
  if (files.isEmpty) {
    final fallback = File(_fallbackList);
    if (fallback.existsSync()) {
      files.addAll(
        fallback.readAsLinesSync().where((l) => l.trim().isNotEmpty),
      );
    }
  }
  if (files.isEmpty) {
    stderr.writeln(
      '[coverage:gate] ERROR: no files supplied (positional, --list, and fallback list all empty)',
    );
    exit(2);
  }

  // D-03 actionable error if lcov source missing.
  if (!File(lcovPath).existsSync()) {
    stderr.writeln('[coverage:gate] ERROR: $lcovPath not found.');
    stderr.writeln(
      '  Run: flutter test --coverage && coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info ...',
    );
    exit(2);
  }

  // Parse lcov once → map by file_path for O(1) lookup.
  final raw = File(lcovPath).readAsStringSync();
  final records = parseLcov(raw);
  final byPath = <String, LcovRecord>{for (final r in records) r.filePath: r};

  // For each input file, look up the record (or synthesize a 0% one and warn).
  final checked = <_GateRow>[];
  for (final path in files) {
    final found = byPath[path];
    final row = found != null
        ? _GateRow(
            filePath: path,
            linesCovered: found.linesCovered,
            linesTotal: found.linesTotal,
            percentage: found.percentage,
            thresholdMet: found.percentage >= threshold,
          )
        : _GateRow(
            filePath: path,
            linesCovered: 0,
            linesTotal: 0,
            percentage: 0.0,
            thresholdMet: false,
          );
    if (found == null) {
      stderr.writeln(
        '[coverage:gate] WARNING: $path not in lcov source — treating as 0%',
      );
    }
    checked.add(row);
  }

  // Sort lex-ASC by file_path (D-10 mirror for downstream consumers).
  checked.sort((a, b) => a.filePath.compareTo(b.filePath));
  final failures = checked.where((r) => !r.thresholdMet).toList();

  if (emitJson) {
    final body = <String, dynamic>{
      'checked': checked.map((r) => r.toJson()).toList(),
      'failures': failures.map((r) => r.toJson()).toList(),
      'threshold': threshold,
      'lcov_source': lcovPath,
    };
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(body));
  } else {
    stdout.writeln('path | covered/total | % | PASS|FAIL');
    for (final r in checked) {
      stdout.writeln(
        '${r.filePath} | ${r.linesCovered}/${r.linesTotal} | ${r.percentage.toStringAsFixed(2)} | ${r.thresholdMet ? 'PASS' : 'FAIL'}',
      );
    }
    stdout.writeln(
      '[coverage:gate] ${checked.length} checked, ${failures.length} failed (threshold: $threshold)',
    );
  }

  exit(failures.isEmpty ? 0 : 1);
}

class _GateRow {
  final String filePath;
  final int linesCovered;
  final int linesTotal;
  final double percentage;
  final bool thresholdMet;

  const _GateRow({
    required this.filePath,
    required this.linesCovered,
    required this.linesTotal,
    required this.percentage,
    required this.thresholdMet,
  });

  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    'lines_covered': linesCovered,
    'lines_total': linesTotal,
    'percentage': percentage,
    'threshold_met': thresholdMet,
  };
}
