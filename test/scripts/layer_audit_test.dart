import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/layer.dart' as layer;

void main() {
  ProcessResult result({
    int exitCode = 0,
    String stdout = 'Analyzing...\nNo issues found! 🎉',
    String stderr = '',
  }) => ProcessResult(1, exitCode, stdout, stderr);

  group('layer audit', () {
    test('uses import_lint CLI for a clean result', () async {
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
        ['run', 'import_lint'],
      ]);
    });

    test('parses a valid import_lint diagnostic', () async {
      final run = await layer.runLayerAudit(
        commandRunner: (_, _) async => result(
          exitCode: 1,
          stdout:
              'Analyzing...\n'
              ' error • /repo/lib/features/example/domain/value.dart:4:2 '
              '• package:home_pocket/data/app_database.dart • domain_to_data\n'
              '1 issue found.',
        ),
      );

      expect(run.exitCode, 0);
      expect(run.envelope['findings'], hasLength(1));
    });

    test(
      'fails closed when the issue summary exceeds parsed diagnostics',
      () async {
        final run = await layer.runLayerAudit(
          commandRunner: (_, _) async => result(
            exitCode: 1,
            stdout:
                'Analyzing...\n'
                ' error • lib/valid.dart:1:1 • package:x/y.dart • rule\n'
                '2 issues found.',
          ),
        );

        expect(run.exitCode, 1);
        expect(run.envelope['scan_state'], 'not_run');
        expect(run.envelope['scan_failed'], isTrue);
        expect(run.envelope['findings'], isEmpty);
      },
    );

    test('fails closed when import_lint emits no output', () async {
      final invocations = <List<String>>[];
      final run = await layer.runLayerAudit(
        commandRunner: (_, arguments) async {
          invocations.add(arguments);
          return result(stdout: '');
        },
      );

      expect(run.exitCode, 1);
      expect(run.envelope['scan_state'], 'not_run');
      expect(run.envelope['scan_failed'], isTrue);
      expect(run.envelope['findings'], isEmpty);
      expect(invocations, [
        ['run', 'import_lint'],
      ]);
    });

    test(
      'fails closed for malformed output without leaking scanner output',
      () async {
        final run = await layer.runLayerAudit(
          commandRunner: (_, _) async => result(
            exitCode: 1,
            stdout: 'Analyzing...\nSECRET_TOKEN\n1 issue found.',
          ),
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
