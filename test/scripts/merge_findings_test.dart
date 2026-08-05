// test/scripts/merge_findings_test.dart
// Idempotency / dedupe / sort / ID-stamping tests for scripts/merge_findings.dart.
// The merger is invoked as a subprocess after writing fixture shards into a
// temp directory, so we exercise the same CLI surface CI uses.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/finding.dart';

const _projectRoot = '.';

Map<String, dynamic> _shardWith(List<Finding> findings, String toolSource) => {
  'tool_source': toolSource,
  'generated_at': '2026-04-25T00:00:00.000Z',
  'findings': findings.map((f) => f.toJson()).toList(),
};

Future<ProcessResult> _runMerger(Directory cwd) async {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/merge_findings.dart'],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}

Directory _initShardLayout(Directory tmp) {
  final root = Directory('${tmp.path}/.planning/audit');
  Directory('${root.path}/shards').createSync(recursive: true);
  Directory('${root.path}/agent-shards').createSync(recursive: true);
  return root;
}

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

String _absoluteProjectRoot() {
  // Tests run with cwd at project root via flutter test; resolve scripts/ as
  // an absolute path so the subprocess can find it from a temp cwd.
  return Directory.current.path;
}

void main() {
  group('Finding model round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final f = _f(filePath: 'lib/foo.dart', line: 10);
      final json = f.toJson();
      final f2 = Finding.fromJson(json);
      expect(f2.toJson(), equals(json));
    });
  });

  group('merge_findings.dart (subprocess)', () {
    late Directory tmp;
    late Directory shardRoot;
    late String mergerPath;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('merger_test_');
      shardRoot = _initShardLayout(tmp);
      // Copy scripts/audit/finding.dart + scripts/merge_findings.dart into the
      // temp tree so `dart run scripts/merge_findings.dart` resolves the
      // relative `audit/finding.dart` import from the temp cwd.
      final root = _absoluteProjectRoot();
      Directory('${tmp.path}/scripts/audit').createSync(recursive: true);
      File(
        '$root/scripts/audit/finding.dart',
      ).copySync('${tmp.path}/scripts/audit/finding.dart');
      File(
        '$root/scripts/merge_findings.dart',
      ).copySync('${tmp.path}/scripts/merge_findings.dart');
      // Copy pubspec + analysis options so `dart run` resolves package config
      // (a minimal pubspec is enough — the merger has no external deps).
      File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
      // Symlink .dart_tool so `dart run` picks up the package config without
      // a fresh pub get.
      Link(
        '${tmp.path}/.dart_tool',
      ).createSync('$root/.dart_tool', recursive: true);
      mergerPath = '${tmp.path}/scripts/merge_findings.dart';
      expect(File(mergerPath).existsSync(), isTrue);
    });

    tearDown(() {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {
        /* tmp may be locked on slow CI */
      }
    });

    test(
      'idempotency: identical shards produce byte-identical issues.json',
      () async {
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(filePath: 'lib/a.dart', line: 1),
              _f(filePath: 'lib/b.dart', line: 5),
            ], 'import_guard'),
          ),
        );
        File('${shardRoot.path}/shards/providers.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: 'lib/c.dart',
                line: 2,
                category: 'provider_hygiene',
                severity: 'HIGH',
                toolSource: 'riverpod_lint',
              ),
            ], 'riverpod_lint'),
          ),
        );

        final r1 = await _runMerger(tmp);
        expect(r1.exitCode, equals(0), reason: r1.stderr.toString());
        final out1 = File('${shardRoot.path}/issues.json').readAsStringSync();

        final r2 = await _runMerger(tmp);
        expect(r2.exitCode, equals(0), reason: r2.stderr.toString());
        final out2 = File('${shardRoot.path}/issues.json').readAsStringSync();

        expect(out2, equals(out1));
      },
    );

    test(
      'dedupe: same (file,line,category) collapses; tool > agent on tie',
      () async {
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: 'lib/foo.dart',
                line: 10,
                toolSource: 'import_guard',
                confidence: 'high',
              ),
            ], 'import_guard'),
          ),
        );
        File('${shardRoot.path}/agent-shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: 'lib/foo.dart',
                line: 10,
                toolSource: 'agent:layer',
                confidence: 'medium',
              ),
            ], 'agent:layer'),
          ),
        );

        final r = await _runMerger(tmp);
        expect(r.exitCode, equals(0), reason: r.stderr.toString());
        final issues = jsonDecode(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
        );
        final findings = (issues['findings'] as List).cast<Map>();
        expect(findings.length, equals(1));
        expect(findings.first['tool_source'], equals('import_guard'));
        expect(findings.first['id'], equals('LV-001'));
      },
    );

    test(
      'keeps distinct clone relationships that share a file and line',
      () async {
        File('${shardRoot.path}/shards/duplication.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: 'lib/shared.dart',
                line: 10,
                category: 'redundant_code',
                severity: 'LOW',
                toolSource: 'owned_duplication_detector',
                confidence: 'medium',
                description: 'clone also appears at lib/first.dart:1.',
              ),
              _f(
                filePath: 'lib/shared.dart',
                line: 10,
                category: 'redundant_code',
                severity: 'LOW',
                toolSource: 'owned_duplication_detector',
                confidence: 'medium',
                description: 'clone also appears at lib/second.dart:1.',
              ),
            ], 'owned_duplication_detector'),
          ),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final findings =
            (jsonDecode(
                      File('${shardRoot.path}/issues.json').readAsStringSync(),
                    )['findings']
                    as List)
                .cast<Map>();
        expect(findings, hasLength(2));
        expect(findings.map((finding) => finding['id']), ['RD-001', 'RD-002']);
      },
    );

    test(
      'sort determinism: scrambled inputs produce same ordered IDs',
      () async {
        // Three findings out of order in input; sort by (file_path, line,
        // category prefix) gives lib/a:1 → lib/a:2 → lib/b:1.
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(filePath: 'lib/b.dart', line: 1),
              _f(filePath: 'lib/a.dart', line: 2),
              _f(filePath: 'lib/a.dart', line: 1),
            ], 'import_guard'),
          ),
        );
        final r = await _runMerger(tmp);
        expect(r.exitCode, equals(0));
        final issues = jsonDecode(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
        );
        final findings = (issues['findings'] as List).cast<Map>();
        expect(findings.length, equals(3));
        expect(findings[0]['file_path'], equals('lib/a.dart'));
        expect(findings[0]['line_start'], equals(1));
        expect(findings[0]['id'], equals('LV-001'));
        expect(findings[1]['file_path'], equals('lib/a.dart'));
        expect(findings[1]['line_start'], equals(2));
        expect(findings[1]['id'], equals('LV-002'));
        expect(findings[2]['file_path'], equals('lib/b.dart'));
        expect(findings[2]['id'], equals('LV-003'));
      },
    );

    test(
      'id stamping: per-category counters reset; LV/PH/DC/RD prefixes',
      () async {
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(filePath: 'lib/a.dart', line: 1),
              _f(filePath: 'lib/b.dart', line: 1),
            ], 'import_guard'),
          ),
        );
        File('${shardRoot.path}/shards/providers.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: 'lib/c.dart',
                line: 1,
                category: 'provider_hygiene',
                severity: 'HIGH',
                toolSource: 'riverpod_lint',
              ),
            ], 'riverpod_lint'),
          ),
        );
        final r = await _runMerger(tmp);
        expect(r.exitCode, equals(0));
        final issues = jsonDecode(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
        );
        final findings = (issues['findings'] as List).cast<Map>();
        final layerIds = findings
            .where((f) => f['category'] == 'layer_violation')
            .map((f) => f['id'])
            .toList();
        final providerIds = findings
            .where((f) => f['category'] == 'provider_hygiene')
            .map((f) => f['id'])
            .toList();
        expect(layerIds, equals(['LV-001', 'LV-002']));
        expect(providerIds, equals(['PH-001']));
      },
    );

    test(
      'generated-file exclusion: .g.dart / .freezed.dart / lib/generated/ dropped',
      () async {
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(filePath: 'lib/foo.g.dart', line: 1),
              _f(filePath: 'lib/foo.freezed.dart', line: 1),
              _f(filePath: 'lib/generated/bar.dart', line: 1),
              _f(filePath: 'lib/bar.dart', line: 1),
            ], 'import_guard'),
          ),
        );
        final r = await _runMerger(tmp);
        expect(r.exitCode, equals(0));
        final issues = jsonDecode(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
        );
        final findings = (issues['findings'] as List).cast<Map>();
        expect(findings.length, equals(1));
        expect(findings.first['file_path'], equals('lib/bar.dart'));
        expect(findings.first['id'], equals('LV-001'));
      },
    );

    test(
      'reopens a closed finding when a successful authoritative scan reports it again',
      () async {
        final original = _f(
          filePath: 'lib/closed.dart',
          line: 12,
          description: 'previously closed',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {
                ...original.toJson(),
                'id': 'LV-001',
                'status': 'closed',
                'closed_in_phase': 3,
                'closed_commit': 'abc123',
              },
            ],
          }),
        );
        File(
          '${shardRoot.path}/shards/layer.json',
        ).writeAsStringSync(jsonEncode(_shardWith([original], 'import_guard')));

        final r = await _runMerger(tmp);
        expect(r.exitCode, equals(0), reason: r.stderr.toString());
        final issues = jsonDecode(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
        );
        final findings = (issues['findings'] as List).cast<Map>();

        expect(findings.single['status'], equals('open'));
        expect(findings.single.containsKey('closed_in_phase'), isFalse);
        expect(findings.single.containsKey('closed_commit'), isFalse);
      },
    );

    test(
      'reopens an accepted clone when its fingerprint no longer matches',
      () async {
        final clone = _f(
          filePath: 'lib/clone.dart',
          line: 12,
          category: 'redundant_code',
          severity: 'LOW',
          toolSource: 'owned_duplication_detector',
          confidence: 'medium',
          description: 'clone also appears at lib/source.dart:4.',
          rationale: 'Accepted duplicate clone. Fingerprint: 1111111111111111.',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...clone.toJson(), 'id': 'RD-001', 'status': 'accepted'},
            ],
          }),
        );
        File('${shardRoot.path}/shards/duplication.json').writeAsStringSync(
          jsonEncode(
            _shardWith([
              _f(
                filePath: clone.filePath,
                line: clone.lineStart,
                category: clone.category,
                severity: clone.severity,
                toolSource: clone.toolSource,
                confidence: clone.confidence,
                description: clone.description,
                rationale:
                    'Detector re-reported. Fingerprint: 2222222222222222.',
              ),
            ], 'owned_duplication_detector'),
          ),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final finding =
            ((jsonDecode(
                          File(
                            '${shardRoot.path}/issues.json',
                          ).readAsStringSync(),
                        )['findings']
                        as List)
                    .single
                as Map);
        expect(finding['id'], 'RD-001');
        expect(finding['status'], 'open');
      },
    );

    test('retains closed findings that are absent from clean shards', () async {
      final closed = _f(
        filePath: 'lib/fixed.dart',
        line: 7,
        category: 'dead_code',
        severity: 'LOW',
        toolSource: 'dart_code_linter',
        description: 'fixed dead code',
      );
      File('${shardRoot.path}/issues.json').writeAsStringSync(
        jsonEncode({
          'findings': [
            {
              ...closed.toJson(),
              'id': 'DC-001',
              'status': 'closed',
              'closed_in_phase': '6',
              'closed_commit': 'def456',
            },
          ],
        }),
      );
      File(
        '${shardRoot.path}/shards/dead_code.json',
      ).writeAsStringSync(jsonEncode(_shardWith([], 'dart_code_linter')));

      final r = await _runMerger(tmp);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());
      final issues = jsonDecode(
        File('${shardRoot.path}/issues.json').readAsStringSync(),
      );
      final findings = (issues['findings'] as List).cast<Map>();

      expect(findings.single['id'], equals('DC-001'));
      expect(findings.single['status'], equals('closed'));
      expect(findings.single['closed_commit'], equals('def456'));
    });

    test(
      'closes an absent open finding only after its authoritative shard ran',
      () async {
        final open = _f(
          filePath: 'lib/open.dart',
          line: 7,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
          description: 'stale dead code',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...open.toJson(), 'id': 'DC-001'},
            ],
          }),
        );
        File(
          '${shardRoot.path}/shards/dead_code.json',
        ).writeAsStringSync(jsonEncode(_shardWith([], 'dart_code_linter')));

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final finding =
            ((jsonDecode(
                          File(
                            '${shardRoot.path}/issues.json',
                          ).readAsStringSync(),
                        )['findings']
                        as List)
                    .single
                as Map);
        expect(finding['status'], equals('closed'));
        expect(finding['closed_in_phase'], equals('audit'));
      },
    );

    test(
      'does not transition missing open findings after an incomplete scan',
      () async {
        final open = _f(
          filePath: 'lib/open.dart',
          line: 7,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
          description: 'stale dead code',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...open.toJson(), 'id': 'DC-001'},
            ],
          }),
        );
        File('${shardRoot.path}/shards/dead_code.json').writeAsStringSync(
          jsonEncode({
            'tool_source': 'dart_code_linter',
            'scan_state': 'not_run',
            'findings': [],
          }),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        final finding =
            ((jsonDecode(
                          File(
                            '${shardRoot.path}/issues.json',
                          ).readAsStringSync(),
                        )['findings']
                        as List)
                    .single
                as Map);
        expect(finding['status'], equals('open'));
      },
    );

    test(
      'renders separate active, resolved, and accepted catalogues',
      () async {
        final active = _f(filePath: 'lib/active.dart');
        final resolved = _f(filePath: 'lib/resolved.dart');
        final accepted = _f(filePath: 'lib/accepted.dart');
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...active.toJson(), 'id': 'LV-001'},
              {...resolved.toJson(), 'id': 'LV-002', 'status': 'closed'},
              {...accepted.toJson(), 'id': 'LV-003', 'status': 'accepted'},
            ],
          }),
        );
        File(
          '${shardRoot.path}/shards/layer.json',
        ).writeAsStringSync(jsonEncode(_shardWith([active], 'import_guard')));

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final markdown = File('${shardRoot.path}/ISSUES.md').readAsStringSync();
        expect(markdown, contains('**Active findings:** 1'));
        expect(markdown, contains('**Resolved findings:** 1'));
        expect(markdown, contains('**Accepted findings:** 1'));
        expect(markdown, contains('## Active Findings'));
        expect(markdown, contains('## Resolved Findings'));
        expect(markdown, contains('## Accepted Findings'));
      },
    );

    test(
      'preserves an open finding ID when new findings sort before it',
      () async {
        final existing = _f(
          filePath: 'lib/z_existing.dart',
          line: 7,
          description: 'existing open finding',
        );
        final inserted = _f(
          filePath: 'lib/a_inserted.dart',
          line: 1,
          description: 'new finding',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...existing.toJson(), 'id': 'LV-001'},
            ],
          }),
        );
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(_shardWith([inserted, existing], 'import_guard')),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
        final findings =
            (jsonDecode(
                      File('${shardRoot.path}/issues.json').readAsStringSync(),
                    )['findings']
                    as List)
                .cast<Map>();
        expect(
          findings.singleWhere(
            (finding) => finding['description'] == 'existing open finding',
          )['id'],
          'LV-001',
        );
        expect(
          findings.singleWhere(
            (finding) => finding['description'] == 'new finding',
          )['id'],
          'LV-002',
        );
      },
    );

    test('fails explicitly when a scanner shard says it was not run', () async {
      File('${shardRoot.path}/shards/duplication.json').writeAsStringSync(
        jsonEncode({
          'tool_source': 'owned_duplication_detector',
          'scan_state': 'not_run',
          'scan_failed': true,
          'findings': [],
          'error': 'fixture scanner failure',
        }),
      );

      final result = await _runMerger(tmp);

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('duplication.json was not run'));
      expect(
        File('${shardRoot.path}/ISSUES.md').readAsStringSync(),
        contains('## Scan Status: INCOMPLETE'),
      );
    });
  });
}
