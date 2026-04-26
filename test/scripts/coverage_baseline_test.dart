// test/scripts/coverage_baseline_test.dart
// Subprocess tests for scripts/coverage_baseline.dart.
//
// Mirrors the temp-dir + symlinked-.dart_tool harness from
// test/scripts/merge_findings_test.dart so the script runs against a real
// `dart run` invocation (same surface CI uses) without polluting the project
// tree.
//
// Covers CONTEXT.md decisions D-10 (lex sort), D-11 (artifact schemas),
// D-12 (idempotency invariant — byte-identical .json modulo `generated_at`).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _projectRoot = '.';

String _absoluteProjectRoot() => Directory.current.path;

Future<ProcessResult> _runBaseline(Directory cwd, [List<String> extra = const []]) {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/coverage_baseline.dart', ...extra],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

Directory _setupTempProject() {
  final tmp = Directory.systemTemp.createTempSync('cov_baseline_test_');
  final root = _absoluteProjectRoot();

  // Copy the script and the parser it imports.
  Directory('${tmp.path}/scripts/coverage').createSync(recursive: true);
  File('$root/scripts/coverage_baseline.dart')
      .copySync('${tmp.path}/scripts/coverage_baseline.dart');
  File('$root/scripts/coverage/lcov_parser.dart')
      .copySync('${tmp.path}/scripts/coverage/lcov_parser.dart');

  // Copy pubspec + symlink .dart_tool so `dart run` picks up the package
  // config without a fresh pub get.
  File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
  Link('${tmp.path}/.dart_tool')
      .createSync('$root/.dart_tool', recursive: true);

  // Ensure target directories exist.
  Directory('${tmp.path}/coverage').createSync(recursive: true);
  Directory('${tmp.path}/.planning/audit').createSync(recursive: true);
  return tmp;
}

void _writeLcov(Directory tmp, String content) {
  File('${tmp.path}/coverage/lcov_clean.info').writeAsStringSync(content);
}

const _threeRecordFixture = '''
SF:lib/b.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
SF:lib/a.dart
DA:1,0
DA:2,1
LF:2
LH:1
end_of_record
SF:lib/c.dart
DA:1,0
DA:2,0
LF:2
LH:0
end_of_record
''';

const _withGeneratedFixture = '''
SF:lib/foo.g.dart
DA:1,0
LF:1
LH:0
end_of_record
SF:lib/real.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
''';

void main() {
  group('coverage_baseline.dart (subprocess)', () {
    late Directory tmp;

    setUp(() {
      tmp = _setupTempProject();
    });

    tearDown(() {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {
        /* tmp may be locked on slow CI */
      }
    });

    test('writes all 4 artifacts with correct shape', () async {
      _writeLcov(tmp, _threeRecordFixture);
      final r = await _runBaseline(tmp);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final txt = File('${tmp.path}/.planning/audit/coverage-baseline.txt');
      final json = File('${tmp.path}/.planning/audit/coverage-baseline.json');
      final needTxt =
          File('${tmp.path}/.planning/audit/files-needing-tests.txt');
      final needJson =
          File('${tmp.path}/.planning/audit/files-needing-tests.json');

      expect(txt.existsSync(), isTrue);
      expect(json.existsSync(), isTrue);
      expect(needTxt.existsSync(), isTrue);
      expect(needJson.existsSync(), isTrue);

      final txtLines = txt
          .readAsStringSync()
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      expect(txtLines.length, equals(3));
      // Format: path \t covered/total \t pct
      expect(txtLines.first.split('\t').length, equals(3));

      final j = jsonDecode(json.readAsStringSync()) as Map<String, dynamic>;
      expect(j['threshold'], equals(80));
      expect(j['total_files'], equals(3));
      expect(j['files_below_threshold'], equals(2)); // a.dart 50%, c.dart 0%
      expect(j['flutter_test_command'], equals('flutter test --coverage'));
      expect(j['lcov_source'], equals('coverage/lcov_clean.info'));
      expect(j.containsKey('generated_at'), isTrue);

      final entries = (j['entries'] as List).cast<Map>();
      expect(entries.length, equals(3));
      // Per-record schema fields
      final first = entries.first;
      expect(first.keys.toSet(), contains('file_path'));
      expect(first.keys.toSet(), contains('lines_covered'));
      expect(first.keys.toSet(), contains('lines_total'));
      expect(first.keys.toSet(), contains('percentage'));
      expect(first.keys.toSet(), contains('threshold_met'));

      // files-needing-tests.txt: only the <80% files (a.dart 50%, c.dart 0%)
      final needLines = needTxt
          .readAsStringSync()
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      expect(needLines.length, equals(2));
      expect(needLines, equals(['lib/a.dart', 'lib/c.dart']));

      final needJ =
          jsonDecode(needJson.readAsStringSync()) as Map<String, dynamic>;
      final needEntries = (needJ['entries'] as List).cast<Map>();
      expect(needEntries.length, equals(2));
      expect(needEntries.first['file_path'], equals('lib/a.dart'));
      expect(needEntries.first['lines_below_threshold'], equals(1));
      expect(needEntries.last['file_path'], equals('lib/c.dart'));
      expect(needEntries.last['lines_below_threshold'], equals(2));
    });

    test('lex-sorts entries by file_path ascending', () async {
      _writeLcov(tmp, _threeRecordFixture); // input order b, a, c
      final r = await _runBaseline(tmp);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final j = jsonDecode(
        File('${tmp.path}/.planning/audit/coverage-baseline.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final paths =
          (j['entries'] as List).map((e) => (e as Map)['file_path']).toList();
      expect(paths, equals(['lib/a.dart', 'lib/b.dart', 'lib/c.dart']));

      final txt = File('${tmp.path}/.planning/audit/coverage-baseline.txt')
          .readAsStringSync()
          .split('\n')
          .where((l) => l.isNotEmpty)
          .map((l) => l.split('\t').first)
          .toList();
      expect(txt, equals(['lib/a.dart', 'lib/b.dart', 'lib/c.dart']));
    });

    test('idempotent: two runs produce byte-identical artifacts modulo generated_at',
        () async {
      _writeLcov(tmp, _threeRecordFixture);
      final r1 = await _runBaseline(tmp);
      expect(r1.exitCode, equals(0), reason: r1.stderr.toString());
      final json1 = jsonDecode(
        File('${tmp.path}/.planning/audit/coverage-baseline.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final txt1 = File('${tmp.path}/.planning/audit/coverage-baseline.txt')
          .readAsStringSync();
      final needJson1 = jsonDecode(
        File('${tmp.path}/.planning/audit/files-needing-tests.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final needTxt1 =
          File('${tmp.path}/.planning/audit/files-needing-tests.txt')
              .readAsStringSync();

      final r2 = await _runBaseline(tmp);
      expect(r2.exitCode, equals(0), reason: r2.stderr.toString());
      final json2 = jsonDecode(
        File('${tmp.path}/.planning/audit/coverage-baseline.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final txt2 = File('${tmp.path}/.planning/audit/coverage-baseline.txt')
          .readAsStringSync();
      final needJson2 = jsonDecode(
        File('${tmp.path}/.planning/audit/files-needing-tests.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final needTxt2 =
          File('${tmp.path}/.planning/audit/files-needing-tests.txt')
              .readAsStringSync();

      // .txt files are byte-identical (no timestamp embedded).
      expect(txt2, equals(txt1));
      expect(needTxt2, equals(needTxt1));

      // .json: normalize generated_at, then compare.
      json1.remove('generated_at');
      json2.remove('generated_at');
      expect(json2, equals(json1));
      needJson1.remove('generated_at');
      needJson2.remove('generated_at');
      expect(needJson2, equals(needJson1));
    });

    test('missing lcov input exits 2 with actionable stderr', () async {
      // Do NOT write coverage/lcov_clean.info.
      final r = await _runBaseline(tmp);
      expect(r.exitCode, equals(2));
      final err = r.stderr.toString();
      expect(err, contains('flutter test --coverage'));
      expect(err, contains('coverde filter'));
    });

    test('generated files are excluded from all 4 outputs', () async {
      _writeLcov(tmp, _withGeneratedFixture);
      final r = await _runBaseline(tmp);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final txt =
          File('${tmp.path}/.planning/audit/coverage-baseline.txt')
              .readAsStringSync();
      expect(txt, isNot(contains('lib/foo.g.dart')));
      expect(txt, contains('lib/real.dart'));

      final j = jsonDecode(
        File('${tmp.path}/.planning/audit/coverage-baseline.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(j['total_files'], equals(1));
      final paths =
          (j['entries'] as List).map((e) => (e as Map)['file_path']).toList();
      expect(paths, equals(['lib/real.dart']));
    });

    test('--lcov flag overrides default path', () async {
      File('${tmp.path}/custom.info').writeAsStringSync(_threeRecordFixture);
      final r =
          await _runBaseline(tmp, ['--lcov', 'custom.info']);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());

      final j = jsonDecode(
        File('${tmp.path}/.planning/audit/coverage-baseline.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(j['lcov_source'], equals('custom.info'));
      expect(j['total_files'], equals(3));
    });

    test('unknown flag exits 2', () async {
      _writeLcov(tmp, _threeRecordFixture);
      final r = await _runBaseline(tmp, ['--banana']);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('--banana'));
    });
  });
}
