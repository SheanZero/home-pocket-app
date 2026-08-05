import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verify_tooling_guards.dart' as tooling;

const _packageFixturePath =
    'lib/features/accounting/domain/phase58_package_import_fixture.dart';

void main() {
  group('tooling guard negative fixtures', () {
    test(
      'package import fixture is rejected by import_guard and cleaned',
      () async {
        final result = await tooling.verifyToolingGuards(
          cases: const [tooling.ToolingGuardCase.importGuardPackage()],
          runCommand: tooling.runToolingGuardCommand,
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isTrue, reason: result.describe());
        expect(result.cases, hasLength(1));
        expect(result.cases.single.isPassing, isTrue);
        expect(result.cases.single.output, contains('import_guard'));
        expect(result.cases.single.output, contains(_packageFixturePath));
        expect(File(_packageFixturePath).existsSync(), isFalse);
      },
    );

    test('pre-existing sentinel is refused without deleting it', () async {
      final fixture = File(_packageFixturePath);
      await fixture.writeAsString('// preserved stale sentinel\n');
      addTearDown(() async {
        if (fixture.existsSync()) await fixture.delete();
      });

      final result = await tooling.verifyToolingGuards(
        cases: const [tooling.ToolingGuardCase.importGuardPackage()],
        runCommand: tooling.runToolingGuardCommand,
        runValidTreeChecks: false,
      );

      expect(result.isPassing, isFalse);
      expect(result.describe(), contains('pre-existing fixture'));
      expect(await fixture.readAsString(), '// preserved stale sentinel\n');
    });

    test(
      'finally cleanup runs when a command returns unexpected success',
      () async {
        final result = await tooling.verifyToolingGuards(
          cases: const [tooling.ToolingGuardCase.importGuardPackage()],
          runCommand: (guardCase, workingDirectory) async =>
              const tooling.ToolingGuardCommandResult(
                exitCode: 0,
                stdout: 'unexpected pass',
                stderr: '',
              ),
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isFalse);
        expect(result.describe(), contains('expected a nonzero exit'));
        expect(File(_packageFixturePath).existsSync(), isFalse);
      },
    );
  });
}
