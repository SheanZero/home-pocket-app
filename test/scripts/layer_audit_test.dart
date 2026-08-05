import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/layer.dart' as layer;

void main() {
  ProcessResult result({
    int exitCode = 0,
    String stdout = '{"version":1,"diagnostics":[]}',
    String stderr = '',
  }) => ProcessResult(1, exitCode, stdout, stderr);

  group('layer audit', () {
    test('uses custom_lint 0.8.1 JSON arguments for a clean result', () async {
      final invocations = <List<String>>[];
      final run = await layer.runLayerAudit(
        commandRunner: (_, arguments) async {
          invocations.add(arguments);
          return result();
        },
      );

      expect(run.exitCode, 0);
      expect(run.envelope['scan_state'], 'ran');
      expect(run.envelope['findings'], isEmpty);
      expect(invocations, [
        ['run', 'custom_lint', '--format=json', '--no-fatal-infos'],
      ]);
    });

    test('parses a valid import_guard JSON diagnostic', () async {
      final run = await layer.runLayerAudit(
        commandRunner: (_, _) async => result(
          stdout: jsonEncode({
            'version': 1,
            'diagnostics': [
              {
                'code': 'import_guard.domain',
                'severity': 'WARNING',
                'type': 'LINT',
                'location': {
                  'file': '/repo/lib/features/example/domain/value.dart',
                  'range': {
                    'start': {'offset': 1, 'line': 3, 'column': 1},
                    'end': {'offset': 2, 'line': 3, 'column': 2},
                  },
                },
                'problemMessage': 'Domain imports data.',
                'correctionMessage': 'Remove the data import.',
              },
            ],
          }),
        ),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['findings'], hasLength(1));
    });

    test(
      'fails closed for mixed valid and malformed JSON diagnostics',
      () async {
        final run = await layer.runLayerAudit(
          commandRunner: (_, _) async => result(
            stdout: jsonEncode({
              'version': 1,
              'diagnostics': [
                {
                  'code': 'import_guard.domain',
                  'severity': 'WARNING',
                  'type': 'LINT',
                  'location': {
                    'file': 'lib/valid.dart',
                    'range': {
                      'start': {'offset': 1, 'line': 0, 'column': 1},
                      'end': {'offset': 2, 'line': 0, 'column': 2},
                    },
                  },
                  'problemMessage': 'Valid.',
                },
                'not a diagnostic',
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
      'fails closed instead of falling back after the old flag signature',
      () async {
        final invocations = <List<String>>[];
        final run = await layer.runLayerAudit(
          commandRunner: (_, arguments) async {
            invocations.add(arguments);
            // `custom_lint --reporter=json` on 0.8.1 exits successfully without
            // output. Treat the matching absence as a scanner failure, never as
            // a reason to run the text command and hide the contract problem.
            return result(stdout: '');
          },
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
        expect(invocations, [
          ['run', 'custom_lint', '--format=json', '--no-fatal-infos'],
        ]);
      },
    );

    test(
      'fails closed for truncated JSON without leaking scanner output',
      () async {
        final run = await layer.runLayerAudit(
          commandRunner: (_, _) async =>
              result(stdout: '{"version":1,"diagnostics":["SECRET_TOKEN'),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
        expect(run.envelope['error'], isNot(contains('SECRET_TOKEN')));
      },
    );
  });
}
