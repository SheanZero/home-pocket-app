import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/release_gate/process_adapter.dart';

void main() {
  group('SystemProcessAdapter', () {
    test('timeout remains armed while child output pipes stay open', () async {
      final marker = File(
        '${Directory.systemTemp.path}/release-gate-child-${DateTime.now().microsecondsSinceEpoch}.pid',
      );
      int? childPid;
      try {
        final outcome = await const SystemProcessAdapter()
            .run(
              '/bin/sh',
              <String>[
                '-c',
                'printf "%s" "\$\$" > "\$1"; printf "ready\\n"; exec sleep 60',
                'release-gate-child',
                marker.path,
              ],
              timeout: const Duration(milliseconds: 100),
              workingDirectory: Directory.current.path,
            )
            .timeout(const Duration(seconds: 2));

        childPid = int.tryParse(await marker.readAsString());
        expect(outcome.exitCode, 124);
        expect(outcome.diagnostic, contains('process timed out'));
        expect(outcome.diagnostic, contains('ready'));
        expect(Process.killPid(childPid!, ProcessSignal.sigterm), isFalse);
      } finally {
        childPid ??= marker.existsSync()
            ? int.tryParse(await marker.readAsString())
            : null;
        if (childPid != null) {
          Process.killPid(childPid, ProcessSignal.sigkill);
        }
        if (marker.existsSync()) await marker.delete();
      }
    });

    test(
      'normal completion retains its exit code and scrubbed output',
      () async {
        final outcome = await const SystemProcessAdapter().run(
          '/bin/sh',
          const <String>[
            '-c',
            'printf "token=not-retained\\n"; printf "complete\\n" >&2; exit 7',
          ],
          timeout: const Duration(seconds: 1),
          workingDirectory: Directory.current.path,
        );

        expect(outcome.exitCode, 7);
        expect(outcome.diagnostic, contains('complete'));
        expect(outcome.diagnostic, isNot(contains('not-retained')));
      },
    );
  });
}
