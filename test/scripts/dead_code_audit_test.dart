// Contract tests for the repository-owned dead-code audit wrapper.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/dead_code.dart' as dead_code;

void main() {
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
      'fails closed when a mixed report contains a malformed record',
      () async {
        final run = await dead_code.runDeadCodeAudit(
          commandRunner: (_, _) async => result(
            stdout: jsonEncode({
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
            stdout: jsonEncode({
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
                stdout: jsonEncode({
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
  });
}
