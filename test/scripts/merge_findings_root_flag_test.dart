// test/scripts/merge_findings_root_flag_test.dart
// Subprocess tests for the --root <path> flag added to scripts/merge_findings.dart
// in Phase 8 Plan 08-05 Task 1.
//
// Locks the behavioral contract:
//   1. Default invocation (no flag) reads from .planning/audit/{shards,
//      agent-shards}/ and writes .planning/audit/{issues.json,ISSUES.md}.
//      Already covered by merge_findings_test.dart — out of scope here.
//   2. --root <path> redirects ALL reads + writes to <path>:
//        reads:  <path>/shards/*.json + <path>/agent-shards/*.json
//        writes: <path>/issues.json + <path>/ISSUES.md
//      and does NOT touch the default .planning/audit/* tree.
//   3. --root with no value exits 2 (invocation error).
//   4. Unknown flag exits 2.
//
// Mirrors the merge_findings_test.dart subprocess + temp-dir + symlink-
// .dart_tool pattern.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/finding.dart';

const _projectRoot = '.';

String _absoluteProjectRoot() => Directory.current.path;

Map<String, dynamic> _shardWith(List<Finding> findings, String toolSource) => {
  'tool_source': toolSource,
  'generated_at': '2026-04-25T00:00:00.000Z',
  'findings': findings.map((f) => f.toJson()).toList(),
};

Finding _f({
  required String filePath,
  int line = 1,
  String category = 'layer_violation',
  String severity = 'CRITICAL',
  String toolSource = 'import_guard',
  String confidence = 'high',
  String description = 'desc',
  String rationale = 'why',
  String suggestedFix = 'fix',
}) => Finding(
  category: category,
  severity: severity,
  filePath: filePath,
  lineStart: line,
  lineEnd: line,
  description: description,
  rationale: rationale,
  suggestedFix: suggestedFix,
  toolSource: toolSource,
  confidence: confidence,
);

Future<ProcessResult> _runMerger(Directory cwd, List<String> extra) {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/merge_findings.dart', ...extra],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

/// Sets up a temp project that mirrors the project layout merge_findings.dart
/// expects: scripts/merge_findings.dart + scripts/audit/finding.dart relative
/// to cwd, plus pubspec.yaml + symlinked .dart_tool.
Directory _setupTempProject() {
  final tmp = Directory.systemTemp.createTempSync('merger_root_test_');
  final root = _absoluteProjectRoot();
  Directory('${tmp.path}/scripts/audit').createSync(recursive: true);
  File('$root/scripts/audit/finding.dart')
      .copySync('${tmp.path}/scripts/audit/finding.dart');
  File('$root/scripts/merge_findings.dart')
      .copySync('${tmp.path}/scripts/merge_findings.dart');
  File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
  Link('${tmp.path}/.dart_tool')
      .createSync('$root/.dart_tool', recursive: true);
  return tmp;
}

void main() {
  group('merge_findings.dart --root flag', () {
    late Directory tmp;

    setUp(() {
      tmp = _setupTempProject();
    });

    tearDown(() {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {/* ignore */}
    });

    test(
      '--root <path> reads <path>/shards/ + <path>/agent-shards/ and writes '
      '<path>/issues.json + <path>/ISSUES.md',
      () async {
        // Lay out the re-audit tree the way Phase 8 Plan 08-05 produces it.
        final reauditRoot = '${tmp.path}/.planning/audit/re-audit';
        Directory('$reauditRoot/shards').createSync(recursive: true);
        Directory('$reauditRoot/agent-shards').createSync(recursive: true);

        File('$reauditRoot/shards/layer.json').writeAsStringSync(
          jsonEncode(_shardWith(
            [_f(filePath: 'lib/foo.dart', line: 7)],
            'import_guard',
          )),
        );
        File('$reauditRoot/agent-shards/layer.json').writeAsStringSync(
          jsonEncode(_shardWith(
            [_f(filePath: 'lib/bar.dart', line: 3, toolSource: 'agent:layer',
                confidence: 'medium')],
            'agent:layer',
          )),
        );

        final r = await _runMerger(
          tmp,
          ['--root', '.planning/audit/re-audit'],
        );
        expect(r.exitCode, equals(0), reason: r.stderr.toString());

        // Outputs at the re-audit root.
        final issuesFile = File('$reauditRoot/issues.json');
        final issuesMd = File('$reauditRoot/ISSUES.md');
        expect(issuesFile.existsSync(), isTrue,
            reason: 'issues.json must be written under --root');
        expect(issuesMd.existsSync(), isTrue,
            reason: 'ISSUES.md must be written under --root');

        // The catalogue contains both the tool-shard and agent-shard findings.
        final issues = jsonDecode(issuesFile.readAsStringSync())
            as Map<String, dynamic>;
        final findings = (issues['findings'] as List).cast<Map>();
        expect(findings.length, equals(2));
        final paths = findings.map((f) => f['file_path']).toSet();
        expect(paths, equals({'lib/foo.dart', 'lib/bar.dart'}));

        // Default-root tree must NOT have been touched: no
        // .planning/audit/issues.json (or ISSUES.md) created at the
        // default location during a --root invocation.
        expect(
          File('${tmp.path}/.planning/audit/issues.json').existsSync(),
          isFalse,
          reason:
              '--root must redirect writes; default .planning/audit/issues.json '
              'must NOT be created when --root is provided',
        );
        expect(
          File('${tmp.path}/.planning/audit/ISSUES.md').existsSync(),
          isFalse,
        );
      },
    );

    test('--root with no value exits 2 with stderr error', () async {
      final r = await _runMerger(tmp, ['--root']);
      expect(r.exitCode, equals(2),
          reason: 'missing --root value must exit 2');
      expect(
        r.stderr.toString(),
        contains('--root requires a path argument'),
        reason: 'stderr must explain the missing value',
      );
    });

    test('unknown flag exits 2 with stderr error', () async {
      final r = await _runMerger(tmp, ['--bogus-flag']);
      expect(r.exitCode, equals(2),
          reason: 'unknown flag must exit 2');
      expect(
        r.stderr.toString(),
        contains('unknown flag'),
        reason: 'stderr must explain the rejected flag',
      );
    });

    test('unexpected positional arg exits 2 with stderr error', () async {
      final r = await _runMerger(tmp, ['some-positional']);
      expect(r.exitCode, equals(2),
          reason: 'unexpected positional arg must exit 2');
      expect(
        r.stderr.toString().toLowerCase(),
        contains('unexpected'),
        reason: 'stderr must explain the rejected positional arg',
      );
    });
  });
}
