// scripts/coverage_baseline.dart
// Reads coverage/lcov_clean.info, writes 4 .planning/audit/coverage-* artifacts.
// Mirror of scripts/merge_findings.dart shape. CONTEXT.md D-10..D-12.
//
// Outputs (all under .planning/audit/):
//   coverage-baseline.txt      — TSV: path \t covered/total \t percentage
//   coverage-baseline.json     — full per-file record + top-level metadata
//   files-needing-tests.txt    — bare paths where percentage < threshold
//   files-needing-tests.json   — same metadata + filtered entries
//
// Determinism (D-12): re-running against the same lcov_clean.info produces
// byte-identical .txt outputs and .json outputs that differ only in the
// `generated_at` metadata field. Phase 8 byte-compare normalizes that field.

import 'dart:convert';
import 'dart:io';

import 'coverage/lcov_parser.dart';

const _defaultLcov = 'coverage/lcov_clean.info';
const _threshold = 70;
const _flutterTestCommand = 'flutter test --coverage';
const _outDir = '.planning/audit';

Future<void> main(List<String> args) async {
  var lcovPath = _defaultLcov;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--lcov':
        if (i + 1 >= args.length) {
          stderr.writeln('[coverage:baseline] ERROR: --lcov requires a path');
          exit(2);
        }
        lcovPath = args[++i];
      default:
        if (a.startsWith('--')) {
          stderr.writeln('[coverage:baseline] ERROR: unknown flag: $a');
          exit(2);
        }
        // Allow a single bare positional as lcov path override.
        lcovPath = a;
    }
  }

  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln('[coverage:baseline] ERROR: $lcovPath not found.');
    stderr.writeln(
      '  Run: flutter test --coverage && coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info ...',
    );
    exit(2);
  }

  final raw = lcovFile.readAsStringSync();
  final parsed = parseLcov(raw);

  // Defense-in-depth: drop generated files even though `coverde filter`
  // upstream should already have stripped them (matches Phase 1 D-09 idempotency).
  final filtered = parsed.where((r) => !isGeneratedPath(r.filePath)).toList();

  // D-10: lex-sort by file_path ASC.
  filtered.sort((a, b) => a.filePath.compareTo(b.filePath));

  final belowCount = filtered.where((r) => r.percentage < _threshold).length;

  // Ensure output directory exists.
  final outDir = Directory(_outDir);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // Build top-level metadata (D-11).
  final metadata = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'flutter_test_command': _flutterTestCommand,
    'lcov_source': lcovPath,
    'threshold': _threshold,
    'total_files': filtered.length,
    'files_below_threshold': belowCount,
  };

  // 1. coverage-baseline.json
  final baselineEntries = filtered
      .map(
        (r) => {
          'file_path': r.filePath,
          'lines_covered': r.linesCovered,
          'lines_total': r.linesTotal,
          'percentage': r.percentage,
          'threshold_met': r.percentage >= _threshold,
        },
      )
      .toList();
  final baselineJson = <String, dynamic>{
    ...metadata,
    'entries': baselineEntries,
  };
  File(
    '$_outDir/coverage-baseline.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(baselineJson));

  // 2. coverage-baseline.txt (TSV; trailing newline)
  final txtBuf = StringBuffer();
  for (final r in filtered) {
    txtBuf
      ..write(r.filePath)
      ..write('\t')
      ..write(r.linesCovered)
      ..write('/')
      ..write(r.linesTotal)
      ..write('\t')
      ..write(r.percentage.toStringAsFixed(2))
      ..write('\n');
  }
  File('$_outDir/coverage-baseline.txt').writeAsStringSync(txtBuf.toString());

  // 3. files-needing-tests.txt + .json (filter: percentage < threshold)
  final below = filtered.where((r) => r.percentage < _threshold).toList();

  final needTxtBuf = StringBuffer();
  for (final r in below) {
    needTxtBuf
      ..write(r.filePath)
      ..write('\n');
  }
  File(
    '$_outDir/files-needing-tests.txt',
  ).writeAsStringSync(needTxtBuf.toString());

  final needEntries = below
      .map(
        (r) => {
          'file_path': r.filePath,
          'percentage': r.percentage,
          'lines_below_threshold': r.linesTotal - r.linesCovered,
        },
      )
      .toList();
  final needJson = <String, dynamic>{
    ...metadata,
    'total_files':
        below.length, // override: this artifact's scope is the below-list
    'entries': needEntries,
  };
  File(
    '$_outDir/files-needing-tests.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(needJson));

  stdout.writeln(
    '[coverage:baseline] wrote ${filtered.length} entries ($belowCount below threshold) to $_outDir/',
  );
}
