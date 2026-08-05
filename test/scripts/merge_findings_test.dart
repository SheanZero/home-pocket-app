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
  'scan_state': 'ran',
  'generated_at': '2026-04-25T00:00:00.000Z',
  'findings': findings.map((f) => f.toJson()).toList(),
};

Future<ProcessResult> _runMerger(
  Directory cwd, {
  Map<String, String>? environment,
  bool repairPairTransaction = false,
}) async {
  return Process.run(
    'dart',
    [
      'run',
      '$_projectRoot/scripts/merge_findings.dart',
      if (repairPairTransaction) '--repair-pair-transaction',
    ],
    runInShell: true,
    workingDirectory: cwd.path,
    environment: environment,
  );
}

Future<Process> _startMerger(
  Directory cwd, {
  Map<String, String>? environment,
}) => Process.start(
  'dart',
  ['run', '$_projectRoot/scripts/merge_findings.dart'],
  runInShell: true,
  workingDirectory: cwd.path,
  environment: environment,
);

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for subprocess state');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

List<FileSystemEntity> _pairTransactionArtifacts(Directory root) => root
    .listSync()
    .where(
      (entity) => entity.path
          .split(Platform.pathSeparator)
          .last
          .startsWith('.merge-findings-'),
    )
    .toList();

File _transactionArtifact(Directory root, String suffix) {
  final matches = root
      .listSync()
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith(suffix) ||
            file.path.endsWith(
              '.merge-findings-${suffix.substring(1).replaceAll('-', '.')}',
            ),
      )
      .toList();
  expect(
    matches,
    hasLength(1),
    reason: 'expected one transaction artifact $suffix',
  );
  return matches.single;
}

Directory _initShardLayout(Directory tmp) {
  final root = Directory('${tmp.path}/.planning/audit');
  final shards = Directory('${root.path}/shards')..createSync(recursive: true);
  Directory('${root.path}/agent-shards').createSync(recursive: true);
  const canonicalTools = {
    'layer.json': 'import_guard',
    'dead_code.json': 'dart_code_linter',
    'providers.json': 'owned_provider_contract',
    'duplication.json': 'owned_duplication_detector',
  };
  for (final entry in canonicalTools.entries) {
    File(
      '${shards.path}/${entry.key}',
    ).writeAsStringSync(jsonEncode(_shardWith([], entry.value)));
  }
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
                toolSource: 'owned_provider_contract',
              ),
            ], 'owned_provider_contract'),
          ),
        );

        final r1 = await _runMerger(tmp);
        expect(r1.exitCode, equals(0), reason: r1.stderr.toString());
        final out1 = File('${shardRoot.path}/issues.json').readAsStringSync();

        final r2 = await _runMerger(tmp);
        expect(r2.exitCode, equals(0), reason: r2.stderr.toString());
        final out2 = File('${shardRoot.path}/issues.json').readAsStringSync();

        expect(out2, equals(out1));
        expect(
          _pairTransactionArtifacts(shardRoot),
          isEmpty,
          reason: 'a successful merge must not leave pair journal artifacts',
        );
      },
    );

    test(
      'ignores agent-shard findings when an authoritative shard reports the same candidate',
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
                toolSource: 'owned_provider_contract',
              ),
            ], 'owned_provider_contract'),
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
      'does not reopen a closed historical agent finding from an agent shard',
      () async {
        final historical = _f(
          filePath: 'lib/historical.dart',
          line: 12,
          toolSource: 'agent:layer',
          confidence: 'medium',
          description: 'historical semantic finding',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {
                ...historical.toJson(),
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
        ).writeAsStringSync(jsonEncode(_shardWith([], 'import_guard')));
        File('${shardRoot.path}/agent-shards/layer.json').writeAsStringSync(
          jsonEncode(_shardWith([historical], 'agent:layer')),
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
        expect(finding['id'], 'LV-001');
        expect(finding['status'], 'closed');
        expect(finding['closed_commit'], 'abc123');
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

    test('fails closed when a required canonical shard is missing', () async {
      File('${shardRoot.path}/shards/layer.json').deleteSync();

      final result = await _runMerger(tmp);

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('missing required canonical shard'));
      expect(result.stderr, contains('layer.json'));
      expect(
        File('${shardRoot.path}/ISSUES.md').readAsStringSync(),
        contains('## Scan Status: INCOMPLETE'),
      );
    });

    test(
      'fails closed on malformed canonical JSON without closing lifecycle',
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
        ).writeAsStringSync('{not valid json');

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('failed to parse'));
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
      'fails closed when one canonical finding is malformed without observing any of that shard',
      () async {
        final open = _f(
          filePath: 'lib/open.dart',
          line: 7,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
          description: 'still open dead code',
        );
        final closed = _f(
          filePath: 'lib/closed.dart',
          line: 8,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
          description: 'already closed dead code',
        );
        final validButUntrusted = _f(
          filePath: 'lib/new.dart',
          line: 9,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
          description: 'must not become an observation',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...open.toJson(), 'id': 'DC-001'},
              {...closed.toJson(), 'id': 'DC-002', 'status': 'closed'},
            ],
          }),
        );
        File('${shardRoot.path}/shards/dead_code.json').writeAsStringSync(
          jsonEncode({
            ..._shardWith([validButUntrusted], 'dart_code_linter'),
            'findings': [validButUntrusted.toJson(), 'malformed finding'],
          }),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('malformed finding'));
        final findings =
            (jsonDecode(
                      File('${shardRoot.path}/issues.json').readAsStringSync(),
                    )['findings']
                    as List)
                .cast<Map>();
        expect(findings, hasLength(2));
        expect(
          findings.singleWhere(
            (finding) => finding['id'] == 'DC-001',
          )['status'],
          equals('open'),
        );
        expect(
          findings.singleWhere(
            (finding) => finding['id'] == 'DC-002',
          )['status'],
          equals('closed'),
        );
      },
    );

    test(
      'allows other valid canonical tools to transition their own findings when one shard is structurally malformed',
      () async {
        final deadCode = _f(
          filePath: 'lib/dead_code.dart',
          line: 7,
          category: 'dead_code',
          severity: 'LOW',
          toolSource: 'dart_code_linter',
        );
        final layer = _f(filePath: 'lib/layer.dart', line: 8);
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...deadCode.toJson(), 'id': 'DC-001'},
              {...layer.toJson(), 'id': 'LV-001'},
            ],
          }),
        );
        File('${shardRoot.path}/shards/dead_code.json').writeAsStringSync(
          jsonEncode({
            ..._shardWith([deadCode], 'dart_code_linter'),
            'findings': [deadCode.toJson(), 42],
          }),
        );
        File(
          '${shardRoot.path}/shards/layer.json',
        ).writeAsStringSync(jsonEncode(_shardWith([], 'import_guard')));

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        final findings =
            (jsonDecode(
                      File('${shardRoot.path}/issues.json').readAsStringSync(),
                    )['findings']
                    as List)
                .cast<Map>();
        expect(
          findings.singleWhere(
            (finding) => finding['id'] == 'DC-001',
          )['status'],
          equals('open'),
        );
        expect(
          findings.singleWhere(
            (finding) => finding['id'] == 'LV-001',
          )['status'],
          equals('closed'),
        );
      },
    );

    test(
      'rejects semantically invalid canonical findings without writing either output',
      () async {
        final existingIssues = '''{\n  "findings": []\n}\n''';
        const existingMarkdown = '# Existing audit report\n';
        final issuesFile = File('${shardRoot.path}/issues.json')
          ..writeAsStringSync(existingIssues);
        final markdownFile = File('${shardRoot.path}/ISSUES.md')
          ..writeAsStringSync(existingMarkdown);

        final invalidFindings = <String, Map<String, dynamic>>{
          'mismatched source': _f(
            filePath: 'lib/source.dart',
            toolSource: 'dart_code_linter',
          ).toJson(),
          'mismatched category': _f(
            filePath: 'lib/category.dart',
            category: 'dead_code',
          ).toJson(),
          'closed scanner observation': {
            ..._f(filePath: 'lib/closed.dart').toJson(),
            'status': 'closed',
          },
          'invalid severity': {
            ..._f(filePath: 'lib/severity.dart').toJson(),
            'severity': 'URGENT',
          },
          'invalid confidence': {
            ..._f(filePath: 'lib/confidence.dart').toJson(),
            'confidence': 'certain',
          },
          'unsafe path': {
            ..._f(filePath: 'lib/path.dart').toJson(),
            'file_path': '../outside.dart',
          },
          'invalid line range': {
            ..._f(filePath: 'lib/range.dart').toJson(),
            'line_start': 4,
            'line_end': 3,
          },
        };

        for (final entry in invalidFindings.entries) {
          File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
            jsonEncode({
              ..._shardWith([], 'import_guard'),
              'findings': [entry.value],
            }),
          );

          final result = await _runMerger(tmp);

          expect(result.exitCode, equals(1), reason: entry.key);
          expect(
            issuesFile.readAsStringSync(),
            equals(existingIssues),
            reason: '${entry.key} must not rewrite issues.json',
          );
          expect(
            markdownFile.readAsStringSync(),
            equals(existingMarkdown),
            reason: '${entry.key} must not rewrite ISSUES.md',
          );
        }
      },
    );

    test(
      'recovers a journal prepared before the first replacement as one new pair',
      () async {
        const oldIssues = '{"findings":[]}';
        const oldMarkdown = '# Old report\n';
        final issuesFile = File('${shardRoot.path}/issues.json')
          ..writeAsStringSync(oldIssues);
        final markdownFile = File('${shardRoot.path}/ISSUES.md')
          ..writeAsStringSync(oldMarkdown);
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/new.dart')], 'import_guard'),
          ),
        );

        final interrupted = await _runMerger(
          tmp,
          environment: {'AUDIT_MERGE_FAILPOINT': 'before_first_replace'},
        );

        expect(interrupted.exitCode, equals(91));
        expect(issuesFile.readAsStringSync(), oldIssues);
        expect(markdownFile.readAsStringSync(), oldMarkdown);

        final recovered = await _runMerger(tmp);
        expect(
          recovered.exitCode,
          equals(0),
          reason: recovered.stderr.toString(),
        );
        expect(issuesFile.readAsStringSync(), contains('lib/new.dart'));
        expect(markdownFile.readAsStringSync(), contains('lib/new.dart'));
        expect(_pairTransactionArtifacts(shardRoot), isEmpty);
      },
    );

    test(
      'recovers an interruption after JSON replacement without mixing generations',
      () async {
        const oldIssues = '{"findings":[]}';
        const oldMarkdown = '# Old report\n';
        final issuesFile = File('${shardRoot.path}/issues.json')
          ..writeAsStringSync(oldIssues);
        final markdownFile = File('${shardRoot.path}/ISSUES.md')
          ..writeAsStringSync(oldMarkdown);
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/new.dart')], 'import_guard'),
          ),
        );

        final interrupted = await _runMerger(
          tmp,
          environment: {'AUDIT_MERGE_FAILPOINT': 'after_json_replace'},
        );

        expect(interrupted.exitCode, equals(91));
        expect(issuesFile.readAsStringSync(), isNot(oldIssues));
        expect(markdownFile.readAsStringSync(), oldMarkdown);

        final recovered = await _runMerger(tmp);
        expect(
          recovered.exitCode,
          equals(0),
          reason: recovered.stderr.toString(),
        );
        expect(issuesFile.readAsStringSync(), contains('lib/new.dart'));
        expect(markdownFile.readAsStringSync(), contains('lib/new.dart'));
        expect(_pairTransactionArtifacts(shardRoot), isEmpty);
      },
    );

    test(
      'rolls back both outputs when a torn transaction is missing its markdown temp',
      () async {
        const oldIssues = '{"findings":[]}';
        const oldMarkdown = '# Old report\n';
        final issuesFile = File('${shardRoot.path}/issues.json')
          ..writeAsStringSync(oldIssues);
        final markdownFile = File('${shardRoot.path}/ISSUES.md')
          ..writeAsStringSync(oldMarkdown);
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/new.dart')], 'import_guard'),
          ),
        );

        final interrupted = await _runMerger(
          tmp,
          environment: {'AUDIT_MERGE_FAILPOINT': 'after_json_replace'},
        );
        expect(interrupted.exitCode, equals(91));
        _transactionArtifact(shardRoot, '-markdown-next').deleteSync();
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode({
            ..._shardWith([], 'import_guard'),
            'findings': [
              _f(
                filePath: 'lib/invalid.dart',
                toolSource: 'dart_code_linter',
              ).toJson(),
            ],
          }),
        );

        final recovered = await _runMerger(tmp);
        expect(recovered.exitCode, equals(1));
        expect(issuesFile.readAsStringSync(), oldIssues);
        expect(markdownFile.readAsStringSync(), oldMarkdown);
        expect(_pairTransactionArtifacts(shardRoot), isEmpty);
      },
    );

    test(
      'fails closed on a corrupt pair journal without overwriting outputs',
      () async {
        const oldIssues = '{"findings":[]}';
        const oldMarkdown = '# Old report\n';
        final issuesFile = File('${shardRoot.path}/issues.json')
          ..writeAsStringSync(oldIssues);
        final markdownFile = File('${shardRoot.path}/ISSUES.md')
          ..writeAsStringSync(oldMarkdown);
        File(
          '${shardRoot.path}/.merge-findings-pair.json',
        ).writeAsStringSync('{corrupt journal');
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/new.dart')], 'import_guard'),
          ),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('pair transaction journal'));
        expect(issuesFile.readAsStringSync(), oldIssues);
        expect(markdownFile.readAsStringSync(), oldMarkdown);
        expect(
          File('${shardRoot.path}/.merge-findings-pair.json').existsSync(),
          isTrue,
        );
      },
    );

    test(
      'recovers every interruption before the initial journal rename',
      () async {
        const failpoints = [
          'prepare_issues_next',
          'prepare_issues_backup',
          'prepare_markdown_next',
          'prepare_markdown_backup',
          'before_journal_publish',
          'journal_before_rename_prepared',
        ];

        for (final point in failpoints) {
          final caseTmp = Directory.systemTemp.createTempSync('merger_crash_');
          addTearDown(() {
            if (caseTmp.existsSync()) caseTmp.deleteSync(recursive: true);
          });
          final caseRoot = _initShardLayout(caseTmp);
          Directory(
            '${caseTmp.path}/scripts/audit',
          ).createSync(recursive: true);
          File(
            '${_absoluteProjectRoot()}/scripts/audit/finding.dart',
          ).copySync('${caseTmp.path}/scripts/audit/finding.dart');
          File(
            '${_absoluteProjectRoot()}/scripts/merge_findings.dart',
          ).copySync('${caseTmp.path}/scripts/merge_findings.dart');
          File(
            '${_absoluteProjectRoot()}/pubspec.yaml',
          ).copySync('${caseTmp.path}/pubspec.yaml');
          Link(
            '${caseTmp.path}/.dart_tool',
          ).createSync('${_absoluteProjectRoot()}/.dart_tool', recursive: true);
          File(
            '${caseRoot.path}/issues.json',
          ).writeAsStringSync('{"findings":[]}');
          File(
            '${caseRoot.path}/ISSUES.md',
          ).writeAsStringSync('# Old report\n');
          File('${caseRoot.path}/shards/layer.json').writeAsStringSync(
            jsonEncode(
              _shardWith([_f(filePath: 'lib/$point.dart')], 'import_guard'),
            ),
          );

          final interrupted = await _runMerger(
            caseTmp,
            environment: {'AUDIT_MERGE_FAILPOINT': point},
          );
          expect(interrupted.exitCode, 91, reason: point);

          final restarted = await _runMerger(caseTmp);
          expect(restarted.exitCode, 0, reason: '$point: ${restarted.stderr}');
          expect(
            _pairTransactionArtifacts(caseRoot),
            isEmpty,
            reason: '$point must not permanently strand preparation files',
          );
        }
      },
    );

    test(
      'recovers journal publication updates without self-corruption',
      () async {
        File(
          '${shardRoot.path}/issues.json',
        ).writeAsStringSync('{"findings":[]}');
        File('${shardRoot.path}/ISSUES.md').writeAsStringSync('# Old report\n');
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/journal.dart')], 'import_guard'),
          ),
        );

        final interrupted = await _runMerger(
          tmp,
          environment: {
            'AUDIT_MERGE_FAILPOINT': 'journal_before_rename_json_replaced',
          },
        );
        expect(interrupted.exitCode, 91);

        final restarted = await _runMerger(tmp);
        expect(restarted.exitCode, 0, reason: restarted.stderr.toString());
        expect(_pairTransactionArtifacts(shardRoot), isEmpty);
      },
    );

    test(
      'recovers a committed pair across every cleanup interruption',
      () async {
        const failpoints = [
          'after_committed_new_journal',
          'cleanup_after_issues_next',
          'cleanup_after_markdown_next',
          'cleanup_after_issues_backup',
          'cleanup_after_markdown_backup',
          'cleanup_after_journal',
        ];

        for (final point in failpoints) {
          final caseTmp = Directory.systemTemp.createTempSync(
            'merger_cleanup_',
          );
          addTearDown(() {
            if (caseTmp.existsSync()) caseTmp.deleteSync(recursive: true);
          });
          final caseRoot = _initShardLayout(caseTmp);
          Directory(
            '${caseTmp.path}/scripts/audit',
          ).createSync(recursive: true);
          File(
            '${_absoluteProjectRoot()}/scripts/audit/finding.dart',
          ).copySync('${caseTmp.path}/scripts/audit/finding.dart');
          File(
            '${_absoluteProjectRoot()}/scripts/merge_findings.dart',
          ).copySync('${caseTmp.path}/scripts/merge_findings.dart');
          File(
            '${_absoluteProjectRoot()}/pubspec.yaml',
          ).copySync('${caseTmp.path}/pubspec.yaml');
          Link(
            '${caseTmp.path}/.dart_tool',
          ).createSync('${_absoluteProjectRoot()}/.dart_tool', recursive: true);
          File(
            '${caseRoot.path}/issues.json',
          ).writeAsStringSync('{"findings":[]}');
          File(
            '${caseRoot.path}/ISSUES.md',
          ).writeAsStringSync('# Old report\n');
          File('${caseRoot.path}/shards/layer.json').writeAsStringSync(
            jsonEncode(
              _shardWith([_f(filePath: 'lib/$point.dart')], 'import_guard'),
            ),
          );

          final interrupted = await _runMerger(
            caseTmp,
            environment: {'AUDIT_MERGE_FAILPOINT': point},
          );
          expect(interrupted.exitCode, 91, reason: point);
          expect(
            File('${caseRoot.path}/issues.json').readAsStringSync(),
            contains('lib/$point.dart'),
          );
          expect(
            File('${caseRoot.path}/ISSUES.md').readAsStringSync(),
            contains('lib/$point.dart'),
          );
          if (point != 'cleanup_after_journal') {
            final journal =
                jsonDecode(
                      File(
                        '${caseRoot.path}/.merge-findings-pair.json',
                      ).readAsStringSync(),
                    )
                    as Map<String, dynamic>;
            expect(journal['state'], 'committed_new');
          }

          final restarted = await _runMerger(caseTmp);
          expect(restarted.exitCode, 0, reason: '$point: ${restarted.stderr}');
          expect(_pairTransactionArtifacts(caseRoot), isEmpty);
        }
      },
    );

    test(
      'rejects an unallowlisted accepted duplication observation without writing outputs',
      () async {
        const existingIssues = '{"findings":[]}';
        const existingMarkdown = '# Existing\n';
        File('${shardRoot.path}/issues.json').writeAsStringSync(existingIssues);
        File('${shardRoot.path}/ISSUES.md').writeAsStringSync(existingMarkdown);
        final accepted = _f(
          filePath: 'lib/clone.dart',
          category: 'redundant_code',
          severity: 'LOW',
          toolSource: 'owned_duplication_detector',
          confidence: 'medium',
          description: 'clone also appears at lib/other.dart:1.',
          rationale:
              'Accepted duplicate clone: forged. Fingerprint: 1111111111111111.',
        );
        File('${shardRoot.path}/shards/duplication.json').writeAsStringSync(
          jsonEncode({
            ..._shardWith([], 'owned_duplication_detector'),
            'findings': [
              {...accepted.toJson(), 'status': 'accepted'},
            ],
          }),
        );

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(1));
        expect(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
          existingIssues,
        );
        expect(
          File('${shardRoot.path}/ISSUES.md').readAsStringSync(),
          existingMarkdown,
        );
      },
    );

    test('accepts only the exact duplication allowlist observation', () async {
      final accepted = _f(
        filePath: 'lib/clone.dart',
        category: 'redundant_code',
        severity: 'LOW',
        toolSource: 'owned_duplication_detector',
        confidence: 'medium',
        description: 'clone also appears at lib/other.dart:1.',
        rationale:
            'Accepted duplicate clone: reviewed fixture Fingerprint: 1111111111111111.',
      );
      File('${shardRoot.path}/duplication_allowlist.json').writeAsStringSync(
        jsonEncode({
          'accepted': [
            {
              'files': ['lib/clone.dart', 'lib/other.dart'],
              'fingerprint': '1111111111111111',
              'rationale': 'reviewed fixture',
            },
          ],
        }),
      );
      File('${shardRoot.path}/shards/duplication.json').writeAsStringSync(
        jsonEncode({
          ..._shardWith([], 'owned_duplication_detector'),
          'findings': [
            {...accepted.toJson(), 'status': 'accepted'},
          ],
        }),
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
      expect(finding['status'], 'accepted');
      expect(finding['id'], 'RD-001');
    });

    test(
      'retains accepted historical agent findings with a noncanonical source',
      () async {
        final historical = _f(
          filePath: 'lib/historical_agent.dart',
          toolSource: 'agent:layer',
          confidence: 'medium',
          description: 'accepted agent history',
        );
        File('${shardRoot.path}/issues.json').writeAsStringSync(
          jsonEncode({
            'findings': [
              {...historical.toJson(), 'id': 'LV-001', 'status': 'accepted'},
            ],
          }),
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
        expect(finding['tool_source'], 'agent:layer');
        expect(finding['status'], 'accepted');
      },
    );

    test(
      'rejects corrupt or invalid existing history before valid scans can write outputs',
      () async {
        final histories = <String, String>{
          'corrupt JSON': '{not JSON',
          'malformed finding': jsonEncode({
            'findings': ['not a finding'],
          }),
          'duplicate IDs': jsonEncode({
            'findings': [
              {..._f(filePath: 'lib/one.dart').toJson(), 'id': 'LV-001'},
              {..._f(filePath: 'lib/two.dart').toJson(), 'id': 'LV-001'},
            ],
          }),
        };
        const existingMarkdown = '# Preserved report\n';
        final validLayer = _f(filePath: 'lib/valid.dart');

        for (final entry in histories.entries) {
          final issuesFile = File('${shardRoot.path}/issues.json')
            ..writeAsStringSync(entry.value);
          final markdownFile = File('${shardRoot.path}/ISSUES.md')
            ..writeAsStringSync(existingMarkdown);
          File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
            jsonEncode(_shardWith([validLayer], 'import_guard')),
          );

          final result = await _runMerger(tmp);

          expect(result.exitCode, equals(1), reason: entry.key);
          expect(
            issuesFile.readAsStringSync(),
            entry.value,
            reason: '${entry.key} must preserve issues.json bytes',
          );
          expect(
            markdownFile.readAsStringSync(),
            existingMarkdown,
            reason: '${entry.key} must preserve ISSUES.md bytes',
          );
        }
      },
    );

    test(
      'ignores malformed historical agent shards without crashing',
      () async {
        File(
          '${shardRoot.path}/agent-shards/layer.json',
        ).writeAsStringSync('{not valid json');

        final result = await _runMerger(tmp);

        expect(result.exitCode, equals(0), reason: result.stderr.toString());
      },
    );

    test('fails closed when canonical scan_state is absent', () async {
      File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
        jsonEncode({'tool_source': 'import_guard', 'findings': []}),
      );

      final result = await _runMerger(tmp);

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('layer.json was not run successfully'));
      expect(result.stderr, contains('invalid scan_state'));
    });

    test(
      'uses an explicit successful canonical scan as lifecycle evidence',
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
            'scan_state': 'ran',
            'findings': [],
          }),
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
        expect(finding['status'], equals('closed'));
      },
    );

    test(
      'serializes real merger subprocesses before unjournaled cleanup',
      () async {
        File('${shardRoot.path}/shards/layer.json').writeAsStringSync(
          jsonEncode(
            _shardWith([_f(filePath: 'lib/locked.dart')], 'import_guard'),
          ),
        );
        final first = await _startMerger(
          tmp,
          environment: {
            'AUDIT_MERGE_HOLDPOINT': 'after_prepare_before_journal',
            'AUDIT_MERGE_HOLD_MS': '1200',
          },
        );
        await _waitFor(() => _pairTransactionArtifacts(shardRoot).isNotEmpty);
        final transientBefore = _pairTransactionArtifacts(
          shardRoot,
        ).map((entity) => entity.path).toSet();

        final second = await _runMerger(
          tmp,
          environment: {'AUDIT_MERGE_LOCK_WAIT_MS': '50'},
        );
        expect(second.exitCode, equals(1));
        expect(second.stderr, contains('another merger holds the audit lock'));
        expect(
          _pairTransactionArtifacts(shardRoot).map((entity) => entity.path),
          containsAll(transientBefore),
          reason:
              'a concurrent merger must not clean another process artifacts',
        );
        expect(await first.exitCode, equals(0));
        final restarted = await _runMerger(tmp);
        expect(restarted.exitCode, equals(0), reason: restarted.stderr);
      },
    );

    test(
      'recovers a dead stale lock but never steals a live owner lock',
      () async {
        final lock = File('${shardRoot.path}/.merge-findings.lock')
          ..writeAsStringSync(
            jsonEncode({
              'schema_version': 1,
              'pid': 99999999,
              'token': 'dead-owner-token',
              'created_at_micros': 1,
            }),
          )
          ..setLastModifiedSync(
            DateTime.now().subtract(const Duration(minutes: 1)),
          );

        final recovered = await _runMerger(
          tmp,
          environment: {'AUDIT_MERGE_LOCK_GRACE_MS': '0'},
        );
        expect(recovered.exitCode, equals(0), reason: recovered.stderr);
        expect(
          lock.existsSync(),
          isFalse,
          reason: 'new owner releases its lock',
        );

        lock.writeAsStringSync(
          jsonEncode({
            'schema_version': 1,
            'pid': pid,
            'token': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            'created_at_micros': 1,
          }),
        );
        lock.setLastModifiedSync(
          DateTime.now().subtract(const Duration(minutes: 1)),
        );
        final liveOwner = await _runMerger(
          tmp,
          environment: {
            'AUDIT_MERGE_LOCK_GRACE_MS': '0',
            'AUDIT_MERGE_LOCK_WAIT_MS': '25',
          },
        );
        expect(liveOwner.exitCode, equals(1));
        expect(
          liveOwner.stderr,
          contains('another merger holds the audit lock'),
        );
        expect(lock.existsSync(), isTrue);
        lock.deleteSync();
      },
    );

    test(
      'quarantines a corrupt transaction only with explicit repair and is idempotent',
      () async {
        const oldIssues = '{"findings":[]}';
        const oldMarkdown = '# Old report\n';
        File('${shardRoot.path}/issues.json').writeAsStringSync(oldIssues);
        File('${shardRoot.path}/ISSUES.md').writeAsStringSync(oldMarkdown);
        File(
          '${shardRoot.path}/.merge-findings-pair.json',
        ).writeAsStringSync('{corrupt journal');
        File(
          '${shardRoot.path}/.merge-findings-tmp-1-1-issues-next',
        ).writeAsStringSync('recognised staged bytes');
        final unrecognised = File('${shardRoot.path}/.merge-findings-unrelated')
          ..writeAsStringSync('do not delete');

        final closed = await _runMerger(tmp);
        expect(closed.exitCode, equals(1));
        expect(
          File('${shardRoot.path}/.merge-findings-pair.json').existsSync(),
          isTrue,
        );
        expect(unrecognised.existsSync(), isTrue);

        final repaired = await _runMerger(tmp, repairPairTransaction: true);
        expect(repaired.exitCode, equals(0), reason: repaired.stderr);
        expect(unrecognised.existsSync(), isTrue);
        final forensicRoot = Directory(
          '${shardRoot.path}/.merge-findings-forensics',
        );
        final manifests = forensicRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('/manifest.json'))
            .toList();
        expect(manifests, hasLength(1));
        final manifest = jsonDecode(manifests.single.readAsStringSync()) as Map;
        expect(manifest['reason'], contains('pair transaction journal'));
        expect(
          (manifest['files'] as List)
              .map((entry) => (entry as Map)['name'])
              .toList(),
          containsAll([
            '.merge-findings-pair.json',
            '.merge-findings-tmp-1-1-issues-next',
          ]),
        );
        expect(
          File('${shardRoot.path}/issues.json').readAsStringSync(),
          isNot(oldIssues),
        );
        expect(
          File('${shardRoot.path}/ISSUES.md').readAsStringSync(),
          isNot(oldMarkdown),
        );

        final repeated = await _runMerger(tmp, repairPairTransaction: true);
        expect(repeated.exitCode, equals(0), reason: repeated.stderr);
        expect(
          forensicRoot
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('/manifest.json')),
          hasLength(1),
        );
      },
    );

    test('repair never rebuilds from incomplete canonical evidence', () async {
      const oldIssues = '{"findings":[]}';
      const oldMarkdown = '# Old report\n';
      File('${shardRoot.path}/issues.json').writeAsStringSync(oldIssues);
      File('${shardRoot.path}/ISSUES.md').writeAsStringSync(oldMarkdown);
      File(
        '${shardRoot.path}/.merge-findings-pair.json',
      ).writeAsStringSync('{corrupt journal');
      File('${shardRoot.path}/shards/layer.json').deleteSync();

      final repaired = await _runMerger(tmp, repairPairTransaction: true);

      expect(repaired.exitCode, equals(1));
      expect(
        repaired.stderr,
        contains('repair requires every canonical shard'),
      );
      expect(
        File('${shardRoot.path}/issues.json').readAsStringSync(),
        oldIssues,
      );
      expect(
        File('${shardRoot.path}/ISSUES.md').readAsStringSync(),
        oldMarkdown,
      );
      expect(
        File('${shardRoot.path}/.merge-findings-pair.json').existsSync(),
        isFalse,
      );
      expect(
        Directory('${shardRoot.path}/.merge-findings-forensics')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('/manifest.json')),
        hasLength(1),
      );
    });
  });
}
