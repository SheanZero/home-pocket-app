// scripts/coverage/lcov_parser.dart
// Shared lcov.info parser. Reused by scripts/coverage_baseline.dart and
// scripts/coverage_gate.dart.
//
// Format reference (LCOV trace file):
//   SF:<source-file-path>
//   DA:<line>,<hits>            // per-instrumented-line hit count
//   LF:<n>                       // total lines instrumented in file
//   LH:<n>                       // lines hit at least once
//   end_of_record                // record terminator
//
// Per-file percentage = LH / LF * 100. If LF/LH are missing, zero, or the
// caller passes recomputeFromDa=true, the parser recomputes from DA lines:
//   linesTotal   = count of DA: lines
//   linesCovered = count of DA: lines whose hits > 0
//
// Edge cases:
//   - linesTotal == 0 → percentage == 100.0 (very_good_coverage convention;
//     avoids divide-by-zero and matches "fully-covered empty file" semantics).
//   - Malformed records (missing SF, missing end_of_record at EOF) are skipped
//     with a stderr WARNING; never throws.
//
// Defense-in-depth: isGeneratedPath() mirrors the four exclusion patterns in
// .github/workflows/audit.yml (the source of truth) so that even if upstream
// `coverde filter` is misconfigured, generated files never reach the baseline.

import 'dart:io';

class LcovRecord {
  final String filePath;
  final int linesCovered;
  final int linesTotal;
  final double percentage;

  const LcovRecord({
    required this.filePath,
    required this.linesCovered,
    required this.linesTotal,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    'lines_covered': linesCovered,
    'lines_total': linesTotal,
    'percentage': percentage,
  };
}

/// Parse an lcov.info string into a list of [LcovRecord]s.
///
/// One record per `SF:...end_of_record` block. Records that lack an `SF:`
/// header or that are not closed by `end_of_record` before EOF are skipped
/// (with a stderr WARNING).
///
/// When [recomputeFromDa] is true, the parser ignores `LF:`/`LH:` summary
/// lines and recomputes line totals from the `DA:` lines themselves. This
/// is also the automatic fallback when `LF:` is missing or zero.
List<LcovRecord> parseLcov(String content, {bool recomputeFromDa = false}) {
  final records = <LcovRecord>[];
  final lines = content.split('\n');

  String? currentPath;
  int? lf;
  int? lh;
  var daTotal = 0;
  var daCovered = 0;
  var recordOpened = false;

  void resetState() {
    currentPath = null;
    lf = null;
    lh = null;
    daTotal = 0;
    daCovered = 0;
    recordOpened = false;
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty) continue;

    if (line.startsWith('SF:')) {
      currentPath = line.substring(3).trim();
      lf = null;
      lh = null;
      daTotal = 0;
      daCovered = 0;
      recordOpened = true;
      continue;
    }

    if (!recordOpened) continue;

    if (line.startsWith('DA:')) {
      final body = line.substring(3);
      final comma = body.indexOf(',');
      if (comma <= 0) continue;
      final hitsText = body.substring(comma + 1).trim();
      final hits = int.tryParse(hitsText);
      if (hits == null) continue;
      daTotal++;
      if (hits > 0) daCovered++;
      continue;
    }

    if (line.startsWith('LF:')) {
      lf = int.tryParse(line.substring(3).trim());
      continue;
    }

    if (line.startsWith('LH:')) {
      lh = int.tryParse(line.substring(3).trim());
      continue;
    }

    if (line.startsWith('end_of_record')) {
      if (currentPath == null) {
        stderr.writeln(
          '[coverage:lcov_parser] WARNING: skipping malformed record near line ${i + 1} (no SF: header)',
        );
        resetState();
        continue;
      }

      final useDa = recomputeFromDa || lf == null || lf == 0;
      final total = useDa ? daTotal : lf!;
      final covered = useDa ? daCovered : (lh ?? 0);
      final pct = total == 0 ? 100.0 : (covered / total) * 100.0;

      records.add(
        LcovRecord(
          filePath: currentPath!,
          linesCovered: covered,
          linesTotal: total,
          percentage: pct,
        ),
      );
      resetState();
    }
  }

  if (recordOpened) {
    stderr.writeln(
      '[coverage:lcov_parser] WARNING: skipping malformed record (no end_of_record at EOF)',
    );
  }

  return records;
}

/// Returns true if [path] points to a file that should never be counted
/// toward coverage (generated code, localizations, mocks).
///
/// Source of truth for the four patterns: `.github/workflows/audit.yml`
/// `very_good_coverage.exclude`. Keep this list in sync if that source changes.
bool isGeneratedPath(String path) {
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.mocks.dart') ||
      path.contains('lib/generated/');
}
