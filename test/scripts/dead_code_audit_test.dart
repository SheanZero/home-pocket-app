// Contract tests for the repository-owned dead-code audit wrapper.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/dead_code.dart' as dead_code;

void main() {
  const metricsCompletionLine =
      '✔ Analysis is completed. Preparing the results: 7.3s';

  String metricsJson(Map<String, dynamic> report) =>
      '$metricsCompletionLine\n\n${jsonEncode(report)}';

  String metricsUpdateFooter({
    String currentVersion = '3.2.0',
    String targetVersion = '4.1.9',
    String? changelogTagVersion,
  }) =>
      '\n\n\n🆕 Update available! $currentVersion -> $targetVersion\n'
      '🆕 Changelog: https://github.com/bancolombia/dart-code-linter/'
      'releases/tag/v${changelogTagVersion ?? targetVersion}';

  ProcessResult result({
    int exitCode = 0,
    String stdout = '✔ Analysis is completed. Preparing the results: 7.3s',
    String stderr = '',
  }) => ProcessResult(1, exitCode, stdout, stderr);

  group('dead-code audit', () {
    test('fails closed when the scanner exits nonzero', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, _) async =>
            result(exitCode: 1, stderr: 'SECRET_TOKEN=must-not-be-recorded'),
      );

      expect(run.exitCode, 1);
      expect(run.envelope['scan_state'], 'not_run');
      expect(run.envelope['scan_failed'], isTrue);
      expect(run.envelope['findings'], isEmpty);
      expect(run.envelope['error'], contains('check-unused-code'));
      expect(run.envelope['error'], isNot(contains('SECRET_TOKEN')));
    });

    test('fails closed when the scanner process cannot start', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, _) => throw ProcessException('dart', const [
          'run',
          'dart_code_linter:metrics',
        ], 'SECRET_TOKEN=must-not-be-recorded'),
      );

      expect(run.exitCode, 1);
      expect(run.envelope['scan_state'], 'not_run');
      expect(run.envelope['scan_failed'], isTrue);
      expect(run.envelope['findings'], isEmpty);
      expect(run.envelope['error'], contains('could not be run'));
      expect(run.envelope['error'], isNot(contains('SECRET_TOKEN')));
    });

    test('fails closed when the scanner emits malformed output', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, _) async => result(
          stdout: 'unexpected output SECRET_TOKEN=must-not-be-recorded',
        ),
      );

      expect(run.exitCode, 1);
      expect(run.envelope['scan_state'], 'not_run');
      expect(run.envelope['scan_failed'], isTrue);
      expect(run.envelope['findings'], isEmpty);
      expect(run.envelope['error'], contains('malformed JSON'));
      expect(run.envelope['error'], isNot(contains('SECRET_TOKEN')));
    });

    test('records a successful genuine zero-finding scan', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, _) async => result(),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['scan_state'], 'ran');
      expect(run.envelope.containsKey('scan_failed'), isFalse);
      expect(run.envelope['findings'], isEmpty);
    });

    test('recognizes the metrics tool zero-finding completion output', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, _) async => result(
          stdout:
              '\u001b[2K\r✔ Analysis is completed. Preparing the results: 7.3s\n',
        ),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['scan_state'], 'ran');
      expect(run.envelope['findings'], isEmpty);
    });

    test(
      'recognizes only the metrics-owned update footer after a clean scan',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, _) async =>
              result(stdout: '$metricsCompletionLine${metricsUpdateFooter()}'),
        );

        expect(run.exitCode, 0);
        expect(run.envelope['scan_state'], 'ran');
        expect(run.envelope['findings'], isEmpty);
      },
    );

    test(
      'fails closed when a mixed report contains a malformed record',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, _) async => result(
            stdout: metricsJson({
              'formatVersion': 2,
              'timestamp': '2026-08-06T00:00:00.000Z',
              'unusedCode': [
                {
                  'path': 'lib/valid.dart',
                  'issues': [
                    {'declarationName': 'valid', 'declarationType': 'method'},
                  ],
                },
                {'issues': []},
              ],
            }),
          ),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
      },
    );

    test(
      'fails closed when an unused-code issue has an invalid shape',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, _) async => result(
            stdout: metricsJson({
              'formatVersion': 2,
              'timestamp': '2026-08-06T00:00:00.000Z',
              'unusedCode': [
                {
                  'path': 'lib/valid.dart',
                  'issues': ['not an issue object'],
                },
              ],
            }),
          ),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
      },
    );

    test('parses a valid unused-code finding', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, arguments) async =>
            arguments.contains('check-unused-files')
            ? result()
            : result(
                stdout: metricsJson({
                  'formatVersion': 2,
                  'timestamp': '2026-08-06T00:00:00.000Z',
                  'unusedCode': [
                    {
                      'path': 'lib/valid.dart',
                      'issues': [
                        {
                          'declarationName': 'valid',
                          'declarationType': 'method',
                          'column': 1,
                          'line': 4,
                          'offset': 12,
                        },
                      ],
                    },
                  ],
                }),
              ),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['findings'], hasLength(1));
    });

    test(
      'parses the captured metrics completion line followed by one report',
      () async {
        final report = jsonEncode({
          'formatVersion': 2,
          'timestamp': '2026-08-06T00:00:00.000Z',
          'unusedCode': [
            {
              'path': 'lib/real_unused.dart',
              'issues': [
                {
                  'declarationName': 'realUnused',
                  'declarationType': 'function',
                  'column': 1,
                  'line': 2,
                  'offset': 14,
                },
              ],
            },
          ],
        });
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, arguments) async =>
              arguments.contains('check-unused-files')
              ? result()
              : result(
                  stdout:
                      '\u001b[2K\r⠙ Checking unused code...'
                      '\u001b[2K\r'
                      '\u001b[2K\r⠹ Checking unused code for 1 file(s)... 0.1s'
                      '\u001b[2K\r$metricsCompletionLine\n\n$report',
                ),
        );

        expect(run.exitCode, 0);
        expect(run.envelope['scan_state'], 'ran');
        expect(run.envelope['findings'], hasLength(1));
        expect(
          (run.envelope['findings'] as List).single['file_path'],
          'lib/real_unused.dart',
        );
      },
    );

    test(
      'recognizes only the metrics-owned update footer after a JSON report',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, arguments) async =>
              arguments.contains('check-unused-files')
              ? result()
              : result(
                  stdout:
                      '${metricsJson({'formatVersion': 2, 'timestamp': '2026-08-06T00:00:00.000Z', 'unusedCode': const []})}${metricsUpdateFooter()}',
                ),
        );

        expect(run.exitCode, 0);
        expect(run.envelope['scan_state'], 'ran');
        expect(run.envelope['findings'], isEmpty);
      },
    );

    test('parses a nonempty unused-files metrics report', () async {
      final run = await dead_code.runDeadCodeAudit(
        commandRunner: (_, arguments) async =>
            arguments.contains('check-unused-files')
            ? result(
                stdout: metricsJson({
                  'formatVersion': 2,
                  'timestamp': '2026-08-06T00:00:00.000Z',
                  'unusedFiles': [
                    {'path': 'lib/real_unused_file.dart'},
                  ],
                  'automaticallyDeleted': false,
                }),
              )
            : result(),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['findings'], hasLength(1));
      final finding = (run.envelope['findings'] as List).single as Map;
      expect(finding['file_path'], 'lib/real_unused_file.dart');
      expect(finding['line_start'], 1);
      expect(finding['description'], contains('Unused file'));
    });

    test(
      'fails closed for noncanonical or mixed completion-plus-report output',
      () async {
        final report = jsonEncode({
          'formatVersion': 2,
          'timestamp': '2026-08-06T00:00:00.000Z',
          'unusedCode': const [],
        });
        final invalidOutputs = [
          'notice\n$metricsCompletionLine\n\n$report',
          '$metricsCompletionLine\n\n$report\ntrailing text',
          '$metricsCompletionLine\n\n$report\n$report',
          '$metricsCompletionLine\n\n{"formatVersion":2',
          'unexpected completion\n$report',
          '$metricsCompletionLine${metricsUpdateFooter()}\ntrailing text',
          '$metricsCompletionLine${metricsUpdateFooter(changelogTagVersion: '4.1.8')}',
          '$metricsCompletionLine\n\n\n🆕 Update available! 3.2 -> 4.1.9\n'
              '🆕 Changelog: https://github.com/bancolombia/dart-code-linter/releases/tag/v4.1.9',
          '$metricsCompletionLine\n\n\n🆕 Update available! 3.2.0 -> 4.1.9\n'
              '🆕 Changelog: https://example.com/releases/tag/v4.1.9',
          '$metricsCompletionLine\n\n\n🆕 Update available! 3.2.0 -> 4.1.9\n'
              '🆕 Changelog: https://github.com/bancolombia/dart-code-linter/releases/tag/v4.1.9\n'
              'notice',
        ];

        for (final stdout in invalidOutputs) {
          final run = await dead_code.runDeadCodeAudit(
            commandRunner: (_, _) async => result(stdout: stdout),
          );

          expect(run.exitCode, 1, reason: stdout);
          expect(run.envelope['scan_state'], 'not_run', reason: stdout);
          expect(run.envelope['findings'], isEmpty, reason: stdout);
        }
      },
    );

    test(
      'accepts completion-only output only when it is the whole output',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, _) async =>
              result(stdout: 'notice\n$metricsCompletionLine'),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['findings'], isEmpty);
      },
    );
  });
}
