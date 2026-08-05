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

    test(
      'provider scope lookalike fixtures are rejected and cleaned',
      () async {
        const cases = <tooling.ToolingGuardCase>[
          tooling.ToolingGuardCase.providerScopeLocalCollision(),
          tooling.ToolingGuardCase.providerScopeImportedShadow(),
          tooling.ToolingGuardCase.providerScopeCommentLookalike(),
          tooling.ToolingGuardCase.providerScopeStringLookalike(),
          tooling.ToolingGuardCase.providerScopeUnrelatedAlias(),
          tooling.ToolingGuardCase.providerScopeQualifiedAliasShadow(),
        ];

        final result = await tooling.verifyToolingGuards(
          cases: cases,
          runCommand: tooling.runToolingGuardCommand,
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isTrue, reason: result.describe());
        expect(result.cases, hasLength(cases.length));
        for (final caseResult in result.cases) {
          expect(caseResult.output, contains('missing_provider_scope'));
          expect(File(caseResult.guardCase.fixturePath).existsSync(), isFalse);
        }
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

    test(
      'runValidTreeChecks runs the owned production checks only when set',
      () async {
        final skipped = await tooling.verifyToolingGuards(
          cases: const [],
          runCommand: (guardCase, workingDirectory) async =>
              const tooling.ToolingGuardCommandResult(
                exitCode: 0,
                stdout: 'valid tree',
                stderr: '',
              ),
          runValidTreeChecks: false,
        );
        final checked = await tooling.verifyToolingGuards(
          cases: const [],
          runCommand: (guardCase, workingDirectory) async =>
              const tooling.ToolingGuardCommandResult(
                exitCode: 0,
                stdout: 'valid tree',
                stderr: '',
              ),
          runValidTreeChecks: true,
        );

        expect(skipped.cases, isEmpty);
        expect(checked.isPassing, isTrue, reason: checked.describe());
        expect(
          checked.cases.map((result) => result.guardCase.name),
          containsAll(<String>[
            'valid production flutter analyze',
            'valid production custom_lint',
            'valid production layer scanner',
            'valid production provider contract',
          ]),
        );
      },
    );

    test(
      'valid tree checks fail closed on analyzer plugin protocol output',
      () async {
        final result = await tooling.verifyToolingGuards(
          cases: const [],
          runCommand: (guardCase, workingDirectory) async =>
              const tooling.ToolingGuardCommandResult(
                exitCode: 0,
                stdout: 'PluginEx: UNKNOWN_REQUEST while parsing version',
                stderr: '',
              ),
        );

        expect(result.isPassing, isFalse);
        expect(result.describe(), contains('analyzer plugin failure detected'));
      },
    );
  });
}
