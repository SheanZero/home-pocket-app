// test/scripts/coverage_gate_test.dart
// Subprocess tests for scripts/coverage_gate.dart.
//
// Covers CONTEXT.md decisions D-01 (hybrid input chain),
// D-02 (--threshold default 70 since Phase 8 amendment 2026-04-28; was 80), D-03 (--lcov default + missing-lcov
// actionable error), D-04 (table + --json output, exit-code triple).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _projectRoot = '.';

String _absoluteProjectRoot() => Directory.current.path;

Future<ProcessResult> _runGate(Directory cwd, [List<String> extra = const []]) {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/coverage_gate.dart', ...extra],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

Directory _setupTempProject() {
  final tmp = Directory.systemTemp.createTempSync('cov_gate_test_');
  final root = _absoluteProjectRoot();

  Directory('${tmp.path}/scripts/coverage').createSync(recursive: true);
  File(
    '$root/scripts/coverage_gate.dart',
  ).copySync('${tmp.path}/scripts/coverage_gate.dart');
  File(
    '$root/scripts/coverage/lcov_parser.dart',
  ).copySync('${tmp.path}/scripts/coverage/lcov_parser.dart');

  File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
  Link(
    '${tmp.path}/.dart_tool',
  ).createSync('$root/.dart_tool', recursive: true);

  Directory('${tmp.path}/coverage').createSync(recursive: true);
  Directory('${tmp.path}/.planning/audit').createSync(recursive: true);
  return tmp;
}

/// Writes coverage/lcov_clean.info given { filePath: (lh, lf) }.
void _writeLcov(Directory tmp, Map<String, (int, int)> records) {
  final buf = StringBuffer();
  records.forEach((path, lhLf) {
    final (lh, lf) = lhLf;
    buf.writeln('SF:$path');
    // Synthesize DA lines so the parser also has DA fallback data.
    for (var i = 1; i <= lf; i++) {
      buf.writeln('DA:$i,${i <= lh ? 1 : 0}');
    }
    buf.writeln('LF:$lf');
    buf.writeln('LH:$lh');
    buf.writeln('end_of_record');
  });
  File(
    '${tmp.path}/coverage/lcov_clean.info',
  ).writeAsStringSync(buf.toString());
}

void main() {
  group('coverage_gate.dart (subprocess)', () {
    late Directory tmp;

    setUp(() {
      tmp = _setupTempProject();
    });

    tearDown(() {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {
        /* ignore */
      }
    });

    test('exits 0 when all positional files meet threshold', () async {
      _writeLcov(tmp, {'lib/a.dart': (10, 10), 'lib/b.dart': (9, 10)});
      final r = await _runGate(tmp, ['lib/a.dart', 'lib/b.dart']);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('PASS'));
    });

    test('exits 1 when any positional file falls below threshold', () async {
      _writeLcov(tmp, {'lib/a.dart': (5, 10), 'lib/b.dart': (10, 10)});
      final r = await _runGate(tmp, ['lib/a.dart', 'lib/b.dart']);
      expect(r.exitCode, equals(1));
      expect(r.stdout.toString(), contains('FAIL'));
    });

    test(
      '--list <file> reads newline-delimited paths and gates them',
      () async {
        _writeLcov(tmp, {'lib/a.dart': (5, 10), 'lib/b.dart': (10, 10)});
        File(
          '${tmp.path}/scope.txt',
        ).writeAsStringSync('lib/a.dart\nlib/b.dart\n');
        final r = await _runGate(tmp, ['--list', 'scope.txt']);
        expect(r.exitCode, equals(1));
        expect(r.stdout.toString(), contains('lib/a.dart'));
      },
    );

    test(
      'falls back to .planning/audit/files-needing-tests.txt when no positional/--list',
      () async {
        _writeLcov(tmp, {'lib/a.dart': (10, 10)});
        File(
          '${tmp.path}/.planning/audit/files-needing-tests.txt',
        ).writeAsStringSync('lib/a.dart\n');
        final r = await _runGate(tmp);
        expect(r.exitCode, equals(0), reason: r.stderr.toString());
        expect(r.stdout.toString(), contains('lib/a.dart'));
      },
    );

    test('exits 2 when no files supplied and no fallback exists', () async {
      _writeLcov(tmp, {'lib/a.dart': (10, 10)});
      // Do NOT write files-needing-tests.txt.
      final r = await _runGate(tmp);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('no files supplied'));
    });

    test('exits 2 when --lcov path missing with actionable stderr', () async {
      // Do NOT write coverage/lcov_clean.info.
      final r = await _runGate(tmp, ['lib/a.dart']);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('flutter test --coverage'));
    });

    test('--threshold N respected (90 against 85% file fails)', () async {
      _writeLcov(tmp, {'lib/a.dart': (85, 100)});
      final r = await _runGate(tmp, ['--threshold', '90', 'lib/a.dart']);
      expect(r.exitCode, equals(1));
    });

    test('--json emits valid JSON with required keys lex-sorted', () async {
      _writeLcov(tmp, {'lib/b.dart': (10, 10), 'lib/a.dart': (5, 10)});
      final r = await _runGate(tmp, ['--json', 'lib/b.dart', 'lib/a.dart']);
      expect(r.exitCode, equals(1)); // a.dart fails
      // `dart run` may prepend "Running build hooks..." to stdout on first
      // invocation; slice from the first '{' to be robust.
      final out = r.stdout.toString();
      final start = out.indexOf('{');
      expect(start, greaterThanOrEqualTo(0));
      final j = jsonDecode(out.substring(start)) as Map<String, dynamic>;
      expect(
        j.keys.toSet(),
        containsAll(['checked', 'failures', 'threshold', 'lcov_source']),
      );
      final checked = (j['checked'] as List).cast<Map>();
      expect(checked.length, equals(2));
      expect(checked.first['file_path'], equals('lib/a.dart')); // lex-sorted
      expect(checked.last['file_path'], equals('lib/b.dart'));
      final failures = (j['failures'] as List).cast<Map>();
      expect(failures.length, equals(1));
      expect(failures.first['file_path'], equals('lib/a.dart'));
      // Per-record schema mirrors coverage_baseline.json
      expect(
        checked.first.keys.toSet(),
        containsAll([
          'file_path',
          'lines_covered',
          'lines_total',
          'percentage',
          'threshold_met',
        ]),
      );
    });

    test('unknown flag exits 2 with the flag name in stderr', () async {
      _writeLcov(tmp, {'lib/a.dart': (10, 10)});
      final r = await _runGate(tmp, ['--banana', 'lib/a.dart']);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('--banana'));
    });

    test(
      'file in args but missing from lcov is WARN-only (does NOT fail gate) — Phase 8 amendment 2026-04-28',
      () async {
        // Pre-amendment behavior: missing-from-lcov treated as 0% → exit 1.
        // Post-amendment: missing files are reported as WARNINGs and listed
        // separately; only files present in lcov below threshold fail exit code.
        _writeLcov(tmp, {'lib/exists.dart': (10, 10)});
        final r = await _runGate(tmp, ['lib/missing.dart', 'lib/exists.dart']);
        expect(r.exitCode, equals(0), reason: r.stderr.toString());
        expect(r.stderr.toString(), contains('not in lcov source'));
        expect(r.stdout.toString(), contains('missing-from-lcov'));
      },
    );

    test(
      '--json output includes a "missing" key listing files absent from lcov',
      () async {
        _writeLcov(tmp, {'lib/exists.dart': (10, 10)});
        final r = await _runGate(tmp, [
          '--json',
          'lib/missing.dart',
          'lib/exists.dart',
        ]);
        expect(r.exitCode, equals(0));
        final out = r.stdout.toString();
        final start = out.indexOf('{');
        expect(start, greaterThanOrEqualTo(0));
        final j = jsonDecode(out.substring(start)) as Map<String, dynamic>;
        expect(j.keys.toSet(), contains('missing'));
        expect((j['missing'] as List), equals(['lib/missing.dart']));
      },
    );
  });
}
