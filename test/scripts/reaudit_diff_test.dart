// test/scripts/reaudit_diff_test.dart
// Subprocess tests for scripts/reaudit_diff.dart.
// Covers Phase 8 CONTEXT.md D-01 strict-exit contract: exit 0 only when
// regression == 0 && new == 0 && open_in_baseline == 0.
//
// Mirrors the merge_findings_test.dart subprocess + temp-dir + symlink-
// .dart_tool pattern (no real `pub get` per test).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/finding.dart';

const _projectRoot = '.';

String _absoluteProjectRoot() => Directory.current.path;

Map<String, dynamic> _catalogue(List<Finding> findings) => {
  'findings': findings.map((f) => f.toJson()).toList(),
};

Finding _f({
  required String filePath,
  String description = 'desc',
  String category = 'layer_violation',
  String severity = 'CRITICAL',
  String toolSource = 'import_guard',
  String confidence = 'high',
  String status = 'closed',
  String? closedInPhase,
  String? closedCommit,
  int line = 1,
  String? id,
}) => Finding(
  id: id,
  category: category,
  severity: severity,
  filePath: filePath,
  lineStart: line,
  lineEnd: line,
  description: description,
  rationale: 'why',
  suggestedFix: 'fix',
  toolSource: toolSource,
  confidence: confidence,
  status: status,
  closedInPhase: closedInPhase,
  closedCommit: closedCommit,
);

Future<ProcessResult> _runDiff(Directory cwd) async {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/reaudit_diff.dart'],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

Future<ProcessResult> _runDiffWithArgs(
  Directory cwd,
  List<String> extra,
) async {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/reaudit_diff.dart', ...extra],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

Directory _setupTempProject() {
  final tmp = Directory.systemTemp.createTempSync('reaudit_diff_test_');
  final root = _absoluteProjectRoot();
  Directory('${tmp.path}/scripts/audit').createSync(recursive: true);
  File(
    '$root/scripts/audit/finding.dart',
  ).copySync('${tmp.path}/scripts/audit/finding.dart');
  File(
    '$root/scripts/reaudit_diff.dart',
  ).copySync('${tmp.path}/scripts/reaudit_diff.dart');
  File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
  Link(
    '${tmp.path}/.dart_tool',
  ).createSync('$root/.dart_tool', recursive: true);
  Directory('${tmp.path}/.planning/audit').createSync(recursive: true);
  Directory('${tmp.path}/.planning/audit/re-audit').createSync(recursive: true);
  return tmp;
}

void _writeBaseline(Directory tmp, List<Finding> findings) {
  File(
    '${tmp.path}/.planning/audit/issues.json',
  ).writeAsStringSync(jsonEncode(_catalogue(findings)));
}

void _writeReaudit(Directory tmp, List<Finding> findings) {
  File(
    '${tmp.path}/.planning/audit/re-audit/issues.json',
  ).writeAsStringSync(jsonEncode(_catalogue(findings)));
}

void main() {
  group('reaudit_diff.dart (subprocess)', () {
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

    test(
      'exit 0: re-audit empty, baseline all-closed → all resolved',
      () async {
        _writeBaseline(tmp, [
          _f(
            filePath: 'lib/a.dart',
            description: 'fixed1',
            status: 'closed',
            closedInPhase: '3',
            closedCommit: 'abc',
          ),
          _f(
            filePath: 'lib/b.dart',
            description: 'fixed2',
            status: 'closed',
            category: 'provider_hygiene',
            severity: 'HIGH',
            closedInPhase: '4',
            closedCommit: 'def',
          ),
        ]);
        _writeReaudit(tmp, []);
        final r = await _runDiff(tmp);
        expect(r.exitCode, equals(0), reason: r.stderr.toString());
        final out = r.stdout.toString();
        expect(out, contains('resolved=2'));
        expect(out, contains('regression=0'));
        expect(out, contains('new=0'));
        expect(out, contains('open_in_baseline=0'));
        // Output artifacts exist.
        expect(
          File(
            '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.json',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.md',
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'exit 1 — regression: baseline-closed finding re-emerges in re-audit',
      () async {
        final closed = _f(
          filePath: 'lib/regress.dart',
          description: 'reopened',
          status: 'closed',
          closedInPhase: '3',
          closedCommit: 'abc',
        );
        // Same (category, file_path, description) but status: open in re-audit.
        final reEmerged = _f(
          filePath: 'lib/regress.dart',
          description: 'reopened',
          status: 'open',
          line: 5, // line shift OK — match key drops line_start
        );
        _writeBaseline(tmp, [closed]);
        _writeReaudit(tmp, [reEmerged]);
        final r = await _runDiff(tmp);
        expect(r.exitCode, equals(1));
        expect(r.stdout.toString(), contains('regression=1'));
        final diffJson =
            jsonDecode(
                  File(
                    '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(diffJson['summary']['regression'], equals(1));
        expect((diffJson['buckets']['regression'] as List).length, equals(1));
        // Resolved bucket should be empty — the finding re-emerged, not stayed gone.
        expect((diffJson['buckets']['resolved'] as List).length, equals(0));
      },
    );

    test('exit 1 — new: re-audit has finding absent from baseline', () async {
      _writeBaseline(tmp, []);
      _writeReaudit(tmp, [
        _f(
          filePath: 'lib/newone.dart',
          description: 'fresh',
          status: 'open',
        ),
      ]);
      final r = await _runDiff(tmp);
      expect(r.exitCode, equals(1));
      expect(r.stdout.toString(), contains('new=1'));
      final diffJson =
          jsonDecode(
                File(
                  '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(diffJson['summary']['new'], equals(1));
      expect((diffJson['buckets']['new'] as List).length, equals(1));
    });

    test(
      'exit 1 — open_in_baseline: baseline has open finding',
      () async {
        _writeBaseline(tmp, [
          _f(
            filePath: 'lib/leftover.dart',
            description: 'never closed',
            status: 'open',
          ),
        ]);
        _writeReaudit(tmp, []);
        final r = await _runDiff(tmp);
        expect(r.exitCode, equals(1));
        expect(r.stdout.toString(), contains('open_in_baseline=1'));
        final diffJson =
            jsonDecode(
                  File(
                    '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(diffJson['summary']['open_in_baseline'], equals(1));
        expect(
          (diffJson['buckets']['open_in_baseline'] as List).length,
          equals(1),
        );
      },
    );

    test('REAUDIT-DIFF.json shape: summary + buckets keys are well-typed', () async {
      _writeBaseline(tmp, [
        _f(
          filePath: 'lib/s.dart',
          description: 'shape',
          status: 'closed',
          closedInPhase: '3',
        ),
      ]);
      _writeReaudit(tmp, [
        _f(filePath: 'lib/n.dart', description: 'newshape', status: 'open'),
      ]);
      final r = await _runDiff(tmp);
      expect(r.exitCode, equals(1));
      final json =
          jsonDecode(
                File(
                  '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(json['summary'], isA<Map<String, dynamic>>());
      expect(json['summary']['resolved'], isA<int>());
      expect(json['summary']['regression'], isA<int>());
      expect(json['summary']['new'], isA<int>());
      expect(json['summary']['open_in_baseline'], isA<int>());
      expect(json['buckets'], isA<Map<String, dynamic>>());
      expect(json['buckets']['resolved'], isA<List>());
      expect(json['buckets']['regression'], isA<List>());
      expect(json['buckets']['new'], isA<List>());
      expect(json['buckets']['open_in_baseline'], isA<List>());
    });

    test('REAUDIT-DIFF.md shape: title + bucket headings present', () async {
      _writeBaseline(tmp, [
        _f(
          filePath: 'lib/m.dart',
          description: 'md',
          status: 'closed',
          closedInPhase: '3',
        ),
      ]);
      _writeReaudit(tmp, []);
      final r = await _runDiff(tmp);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());
      final md = File(
        '${tmp.path}/.planning/audit/re-audit/REAUDIT-DIFF.md',
      ).readAsStringSync();
      expect(md, contains('# Re-Audit Diff Report'));
      expect(md, contains('**Resolved:**'));
      // At least one of the four bucket headings must appear.
      final anyBucketHeading = md.contains('## Resolved') ||
          md.contains('## Regression') ||
          md.contains('## New') ||
          md.contains('## Still Open in Baseline');
      expect(anyBucketHeading, isTrue);
    });

    test('exit 2: missing baseline file', () async {
      // Do not write baseline. Re-audit exists.
      _writeReaudit(tmp, []);
      final r = await _runDiff(tmp);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('baseline not found'));
    });

    test('exit 2: missing re-audit catalogue', () async {
      _writeBaseline(tmp, [
        _f(
          filePath: 'lib/baseline.dart',
          description: 'b',
          status: 'closed',
        ),
      ]);
      // Do not write re-audit.
      final r = await _runDiff(tmp);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('re-audit catalogue not found'));
    });

    test('exit 2: unknown flag rejected', () async {
      _writeBaseline(tmp, []);
      _writeReaudit(tmp, []);
      final r = await _runDiffWithArgs(tmp, ['--bogus']);
      expect(r.exitCode, equals(2));
      expect(r.stderr.toString(), contains('unknown flag'));
    });
  });
}
