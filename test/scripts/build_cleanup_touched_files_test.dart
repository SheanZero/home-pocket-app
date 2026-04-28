// test/scripts/build_cleanup_touched_files_test.dart
// Subprocess tests for scripts/build_cleanup_touched_files.sh.
//
// Phase 8 Plan 08-02 Task 1 (EXIT-04). Locks the behavioral contract of the
// generator that produces .planning/audit/cleanup-touched-files.txt:
//   1. Bash script parses Phase 3-6 PLAN.md frontmatter `files_modified:`
//      blocks, filters to `lib/...` paths, sorts + dedupes.
//   2. Output: every line `lib/`-prefixed, no `#` comments, sorted unique,
//      trailing newline.
//   3. Determinism: re-running the script produces byte-identical output.
//   4. Sanity-check anchors (per Plan 08-02 acceptance):
//      - lib/main.dart exactly once
//      - lib/application/i18n/formatter_service.dart exactly once
//
// The tests run the real script against the real .planning/phases tree
// (no fixture directory needed — the post-Phase-6 plan tree is stable). Two
// invocations into separate temp output paths are diffed byte-for-byte to
// prove determinism.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _absoluteProjectRoot() => Directory.current.path;

/// Runs `bash scripts/build_cleanup_touched_files.sh` from the project root
/// with $OUT pointing at [outPath] (the script reads OUT as the output target
/// — note: the current implementation hardcodes OUT to the canonical artifact
/// location, so we instead capture the artifact post-run and copy it).
///
/// Returns the ProcessResult so the caller can assert exit code + stderr.
Future<ProcessResult> _runGenerator() async {
  return Process.run(
    'bash',
    ['scripts/build_cleanup_touched_files.sh'],
    runInShell: true,
    workingDirectory: _absoluteProjectRoot(),
  );
}

void main() {
  const generatedPath = '.planning/audit/cleanup-touched-files.txt';

  group('build_cleanup_touched_files.sh (subprocess against real plan tree)', () {
    test('script exists, is executable, and uses /usr/bin/env bash shebang',
        () {
      final scriptPath =
          '${_absoluteProjectRoot()}/scripts/build_cleanup_touched_files.sh';
      final f = File(scriptPath);
      expect(f.existsSync(), isTrue, reason: 'Script must exist on disk');
      final stat = f.statSync();
      // Owner-execute bit (0o100 == 64) — script must be runnable.
      expect(
        stat.mode & 64 != 0,
        isTrue,
        reason: 'Script must have owner-execute permission set',
      );
      final firstLine = f.readAsLinesSync().first;
      expect(firstLine, equals('#!/usr/bin/env bash'));
    });

    test('exits 0 against real .planning/phases/03-06 tree', () async {
      final r = await _runGenerator();
      expect(
        r.exitCode,
        equals(0),
        reason:
            'Script exited non-zero. stderr=${r.stderr} stdout=${r.stdout}',
      );
    });

    test('output file conforms to per-line invariants (lib/-prefix, no '
        'comments, sorted+deduped, trailing newline, ≥50 lines)', () async {
      final r = await _runGenerator();
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final outFile = File('${_absoluteProjectRoot()}/$generatedPath');
      expect(outFile.existsSync(), isTrue);

      final raw = outFile.readAsStringSync();
      // 1. trailing newline.
      expect(
        raw.endsWith('\n'),
        isTrue,
        reason: 'Output must end with trailing newline',
      );

      final lines = raw.split('\n').where((l) => l.isNotEmpty).toList();
      // 2. Per Plan 08-02 acceptance: ≥50 entries.
      expect(
        lines.length,
        greaterThanOrEqualTo(50),
        reason: 'Phase 3-6 union must contain ≥50 entries (got ${lines.length})',
      );

      // 3. Every line begins with `lib/`.
      final nonLib = lines.where((l) => !l.startsWith('lib/')).toList();
      expect(
        nonLib,
        isEmpty,
        reason:
            'Every line must start with lib/. Offenders: ${nonLib.take(5).toList()}',
      );

      // 4. Zero `#` comment lines.
      final comments = lines.where((l) => l.startsWith('#')).toList();
      expect(
        comments,
        isEmpty,
        reason:
            'No `#` comment lines allowed (coverage_gate.dart treats them as paths). '
            'Offenders: ${comments.take(5).toList()}',
      );

      // 5. Sorted + deduped: `sort -u` (the script's primitive) over the
      //    output yields the output unchanged. We invoke /usr/bin/sort
      //    rather than Dart's String.compareTo so the comparator matches
      //    the script's locale-aware sort exactly.
      final sortResult = await Process.run(
        'sort',
        ['-u', generatedPath],
        runInShell: true,
        workingDirectory: _absoluteProjectRoot(),
      );
      expect(sortResult.exitCode, equals(0),
          reason: 'sort -u must exit 0: ${sortResult.stderr}');
      expect(
        sortResult.stdout.toString(),
        equals(raw),
        reason: 'Output must be sorted (sort -u) and deduplicated — '
            '`sort -u` over the file must equal the file itself',
      );

      // 6. No duplicate lines (independent check on top of #5).
      final seen = <String>{};
      final dupes = <String>[];
      for (final l in lines) {
        if (!seen.add(l)) dupes.add(l);
      }
      expect(dupes, isEmpty,
          reason: 'No duplicate lines allowed. Offenders: ${dupes.take(5)}');
    });

    test('sanity-check anchors: lib/main.dart and '
        'lib/application/i18n/formatter_service.dart each appear exactly once',
        () async {
      final r = await _runGenerator();
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final lines = File('${_absoluteProjectRoot()}/$generatedPath')
          .readAsLinesSync()
          .where((l) => l.isNotEmpty)
          .toList();

      expect(
        lines.where((l) => l == 'lib/main.dart').length,
        equals(1),
        reason: 'lib/main.dart must appear exactly once (Phase 3 + 6 union)',
      );
      expect(
        lines
            .where((l) => l == 'lib/application/i18n/formatter_service.dart')
            .length,
        equals(1),
        reason:
            'lib/application/i18n/formatter_service.dart must appear exactly once (Phase 4 + 5 union)',
      );
    });

    test('determinism: two invocations produce byte-identical output',
        () async {
      final outFile = File('${_absoluteProjectRoot()}/$generatedPath');

      final r1 = await _runGenerator();
      expect(r1.exitCode, equals(0), reason: r1.stderr.toString());
      final bytes1 = outFile.readAsBytesSync();

      final r2 = await _runGenerator();
      expect(r2.exitCode, equals(0), reason: r2.stderr.toString());
      final bytes2 = outFile.readAsBytesSync();

      expect(
        bytes2,
        equals(bytes1),
        reason:
            'Re-running the generator must produce byte-identical output '
            '(determinism — sort -u is the load-bearing primitive).',
      );
    });
  });
}
