// scripts/coverage_gate.dart
// Per-file coverage gate. Hybrid CLI: positional + --list + fallback.
// CONTEXT.md D-01..D-04. NOT wired into CI in Phase 2 (D-06); local + fix-phase
// verify only.
//
// Usage:
//   dart run scripts/coverage_gate.dart [<file>...]
//                                       [--list <path>]
//                                       [--deferred <path>]
//                                       [--threshold N]
//                                       [--lcov <path>]
//                                       [--json]
//
// --deferred <path>: file listing paths explicitly deferred from the gate.
//   Each non-blank non-comment line must be: <relative_path>  # <rationale>
//   The rationale (text after `#`) is REQUIRED — entries without it cause
//   exit 2 (invocation error). Deferred files are removed from threshold
//   checking, surfaced on stderr as DEFERRED, and reported in JSON output
//   under the `deferred` key. Mechanism added 2026-04-28 by Phase 8 amendment
//   to support FUTURE-TOOL-03 (coverage-baseline-review): explicit, reasoned,
//   file-scoped scope reduction with each entry justified — CI still hard-fails
//   on any failure NOT in the deferral list.
//
// Exit codes (D-04, amended 2026-04-28):
//   0 — every supplied file present in lcov met threshold
//   1 — at least one file present in lcov fell below threshold (gate failure)
//   2 — invocation error (missing lcov, unknown flag, no files supplied)
//
// Files supplied to the gate but NOT present in the lcov source are reported
// as MISSING (separate from real failures). They emit a WARNING line on stderr
// and appear in JSON output under the `missing` key, but do NOT influence
// exit code. Rationale: cleanup-touched-files.txt is generated from PLAN.md
// `files_modified:` frontmatter and includes generated/non-Dart entries
// (`.g.dart`, `.freezed.dart`, `import_guard.yaml`) that coverde filters
// from lcov_clean.info. Those are scope boundary issues, not coverage
// failures. Real <threshold% files (in lcov but below threshold) still
// fail exit code as before — see Phase 8 amendment in REPO-LOCK-POLICY.md.

import 'dart:convert';
import 'dart:io';

import 'coverage/lcov_parser.dart';

const _defaultLcov = 'coverage/lcov_clean.info';
const _fallbackList = '.planning/audit/files-needing-tests.txt';

Future<void> main(List<String> args) async {
  // Defaults from D-02 (threshold) / D-03 (lcov path).
  // Threshold lowered 80 → 70 by Phase 8 amendment 2026-04-28; CI invocations
  // pass --threshold explicitly so this default only affects local runs.
  var threshold = 70;
  var lcovPath = _defaultLcov;
  var emitJson = false;
  String? listPath;
  String? deferredPath;
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
      case '--deferred':
        if (i + 1 >= args.length) {
          stderr.writeln('[coverage:gate] ERROR: --deferred requires a path');
          exit(2);
        }
        deferredPath = args[++i];
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

  // Phase 8 amendment 2026-04-28: parse --deferred file. Each non-blank
  // non-comment line must be `<path>  # <rationale>`; rationale is REQUIRED.
  final deferredEntries = <_DeferredEntry>[];
  final deferredPaths = <String>{};
  if (deferredPath != null) {
    final f = File(deferredPath);
    if (!f.existsSync()) {
      stderr.writeln(
        '[coverage:gate] ERROR: --deferred path not found: $deferredPath',
      );
      exit(2);
    }
    var lineNo = 0;
    for (final raw in f.readAsLinesSync()) {
      lineNo++;
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      // WR-03: split on the literal `  #` (two spaces + hash) sentinel rather
      // than the first `#` so that paths legitimately containing `#` (e.g.
      // `lib/feature/v1#alpha/foo.dart`) are not silently truncated.
      final hashIdx = line.indexOf('  #');
      if (hashIdx <= 0) {
        stderr.writeln(
          '[coverage:gate] ERROR: $deferredPath line $lineNo missing rationale (expected: <path>  # <rationale>): $line',
        );
        exit(2);
      }
      final path = line.substring(0, hashIdx).trim();
      final rationale = line.substring(hashIdx + 3).trim();
      if (path.isEmpty) {
        stderr.writeln(
          '[coverage:gate] ERROR: $deferredPath line $lineNo empty path before #',
        );
        exit(2);
      }
      if (rationale.isEmpty) {
        stderr.writeln(
          '[coverage:gate] ERROR: $deferredPath line $lineNo empty rationale after # — rationale is required for deferral discipline',
        );
        exit(2);
      }
      // WR-04: reject duplicate paths so the on-disk record can never disagree
      // with the JSON output (Set.add returns false if the element was already
      // present — clean idiom for first-write-wins detection).
      if (!deferredPaths.add(path)) {
        stderr.writeln(
          '[coverage:gate] ERROR: $deferredPath line $lineNo duplicate path: $path',
        );
        exit(2);
      }
      deferredEntries.add(
        _DeferredEntry(filePath: path, rationale: rationale),
      );
    }
  }

  // Parse lcov once → map by file_path for O(1) lookup.
  final raw = File(lcovPath).readAsStringSync();
  final records = parseLcov(raw);
  final byPath = <String, LcovRecord>{for (final r in records) r.filePath: r};

  // For each input file, classify as one of:
  //   - deferred : in --deferred list → SKIP threshold check, record reasoning
  //   - checked  : present in lcov  → contributes to threshold gate + exit code
  //   - missing  : not in lcov      → WARN-only (scope boundary)
  // Phase 8 amendment 2026-04-28: missing + deferred no longer fail exit code.
  final checked = <_GateRow>[];
  final missing = <String>[];
  final deferredHits = <_DeferredEntry>[];
  for (final path in files) {
    if (deferredPaths.contains(path)) {
      final entry = deferredEntries.firstWhere((e) => e.filePath == path);
      deferredHits.add(entry);
      stderr.writeln(
        '[coverage:gate] DEFERRED: $path — ${entry.rationale}',
      );
      continue;
    }
    final found = byPath[path];
    if (found == null) {
      missing.add(path);
      stderr.writeln(
        '[coverage:gate] WARNING: $path not in lcov source — skipped (likely generated or filtered)',
      );
      continue;
    }
    checked.add(
      _GateRow(
        filePath: path,
        linesCovered: found.linesCovered,
        linesTotal: found.linesTotal,
        percentage: found.percentage,
        thresholdMet: found.percentage >= threshold,
      ),
    );
  }

  // Sort lex-ASC by file_path (D-10 mirror for downstream consumers).
  checked.sort((a, b) => a.filePath.compareTo(b.filePath));
  missing.sort();
  deferredHits.sort((a, b) => a.filePath.compareTo(b.filePath));
  final failures = checked.where((r) => !r.thresholdMet).toList();

  if (emitJson) {
    final body = <String, dynamic>{
      'checked': checked.map((r) => r.toJson()).toList(),
      'failures': failures.map((r) => r.toJson()).toList(),
      'missing': missing,
      'deferred': deferredHits.map((e) => e.toJson()).toList(),
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
      '[coverage:gate] ${checked.length} checked, ${failures.length} failed, ${missing.length} missing-from-lcov (skipped), ${deferredHits.length} deferred (skipped) (threshold: $threshold)',
    );
  }

  exit(failures.isEmpty ? 0 : 1);
}

class _DeferredEntry {
  final String filePath;
  final String rationale;
  const _DeferredEntry({required this.filePath, required this.rationale});
  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    'rationale': rationale,
  };
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
