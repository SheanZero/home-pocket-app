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
    test('records an exact JSON clean result', () async {
      final run = await layer.runLayerAudit(
        commandRunner: (_, _) async => result(),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['scan_state'], 'ran');
      expect(run.envelope['findings'], isEmpty);
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
      'fails closed for unrecognized text reporter output without leaking it',
      () async {
        final run = await layer.runLayerAudit(
          commandRunner: (_, arguments) async =>
              arguments.contains('--reporter=json')
              ? result(stdout: '')
              : result(stdout: 'unexpected SECRET_TOKEN=must-not-be-recorded'),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
        expect(run.envelope['error'], isNot(contains('SECRET_TOKEN')));
      },
    );

    test('preserves the text fallback for the exact clean signature', () async {
      final run = await layer.runLayerAudit(
        commandRunner: (_, arguments) async =>
            arguments.contains('--reporter=json')
            ? result(stdout: '')
            : result(stdout: 'No issues found!'),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['scan_state'], 'ran');
      expect(run.envelope['findings'], isEmpty);
    });

    test('parses the exact text-reporter finding format in fallback', () async {
      final run = await layer.runLayerAudit(
        commandRunner: (_, arguments) async =>
            arguments.contains('--reporter=json')
            ? result(stdout: '')
            : result(
                stdout:
                    '  lib/example.dart:4:2 • Invalid import • import_guard.domain • WARNING\n\n1 issue found.',
              ),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['findings'], hasLength(1));
    });

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
