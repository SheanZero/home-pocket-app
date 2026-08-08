import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verify_tooling_guards.dart' as tooling;

const _packageFixturePath =
    'lib/features/accounting/domain/models/phase58_package_import_fixture.dart';
const _staleFixturePath = 'lib/phase58_stale_only_fixture.dart';

void main() {
  group('tooling guard negative fixtures', () {
    test(
      'package import fixture is rejected by import_lint and cleaned',
      () async {
        final result = await tooling.verifyToolingGuards(
          cases: const [tooling.ToolingGuardCase.importGuardPackage()],
          runCommand: tooling.runToolingGuardCommand,
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isTrue, reason: result.describe());
        expect(result.cases, hasLength(1));
        expect(result.cases.single.isPassing, isTrue);
        expect(result.cases.single.output, contains('domain_to_data'));
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

    test('qualified Flutter runApp fixture is rejected and cleaned', () async {
      const guardCase =
          tooling.ToolingGuardCase.providerScopeQualifiedRunAppMissing();

      final result = await tooling.verifyToolingGuards(
        cases: const [guardCase],
        runCommand: tooling.runToolingGuardCommand,
        runValidTreeChecks: false,
      );

      expect(result.isPassing, isTrue, reason: result.describe());
      expect(result.cases, hasLength(1));
      expect(result.cases.single.output, contains('missing_provider_scope'));
      expect(result.cases.single.output, contains(guardCase.fixturePath));
      expect(File(guardCase.fixturePath).existsSync(), isFalse);
    });

    test(
      'record-pattern alias shadow fixture is rejected and cleaned',
      () async {
        const guardCase =
            tooling.ToolingGuardCase.providerScopeRecordPatternAliasShadow();

        final result = await tooling.verifyToolingGuards(
          cases: const [guardCase],
          runCommand: tooling.runToolingGuardCommand,
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isTrue, reason: result.describe());
        expect(result.cases, hasLength(1));
        expect(result.cases.single.output, contains('missing_provider_scope'));
        expect(File(guardCase.fixturePath).existsSync(), isFalse);
      },
    );

    test('record-pattern alias shadow fixture compiles as Dart', () async {
      const guardCase =
          tooling.ToolingGuardCase.providerScopeRecordPatternAliasShadow();
      final fixture = File(guardCase.fixturePath);
      await tooling.withToolingGuardFixtureLock(() async {
        await fixture.writeAsString(guardCase.source!);
        try {
          final result = await Process.run('flutter', [
            'analyze',
            '--no-fatal-infos',
            guardCase.fixturePath,
          ], workingDirectory: Directory.current.path);

          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}\n${result.stderr}',
          );
        } finally {
          if (fixture.existsSync()) await fixture.delete();
        }
      });
    });

    test('extension-type shadow fixtures compile as Dart', () async {
      const cases = <tooling.ToolingGuardCase>[
        tooling.ToolingGuardCase.providerScopeExtensionTypeShadow(),
        tooling.ToolingGuardCase.providerScopeExtensionTypeAliasControl(),
      ];
      final fixtures = cases
          .map((guardCase) => File(guardCase.fixturePath))
          .toList(growable: false);
      await tooling.withToolingGuardFixtureLock(() async {
        for (var index = 0; index < cases.length; index++) {
          await fixtures[index].writeAsString(cases[index].source!);
        }
        try {
          for (final fixture in fixtures) {
            final result = await Process.run('flutter', [
              'analyze',
              '--no-fatal-infos',
              fixture.path,
            ], workingDirectory: Directory.current.path);
            expect(
              result.exitCode,
              0,
              reason: '${fixture.path}: ${result.stdout}\n${result.stderr}',
            );
          }
        } finally {
          for (final fixture in fixtures) {
            if (fixture.existsSync()) await fixture.delete();
          }
        }
      });
    });

    test(
      'extension-type constructor shadow is rejected and alias control passes',
      () async {
        const negative =
            tooling.ToolingGuardCase.providerScopeExtensionTypeShadow();
        const control =
            tooling.ToolingGuardCase.providerScopeExtensionTypeAliasControl();

        final result = await tooling.verifyToolingGuards(
          cases: const [negative, control],
          runCommand: tooling.runToolingGuardCommand,
          runValidTreeChecks: false,
        );

        expect(result.isPassing, isTrue, reason: result.describe());
        expect(result.cases[0].output, contains('missing_provider_scope'));
        expect(
          result.cases[1].output,
          contains('PASS owned provider contract'),
        );
        for (final caseResult in result.cases) {
          expect(File(caseResult.guardCase.fixturePath).existsSync(), isFalse);
        }
      },
    );

    test('pre-existing sentinel is refused without deleting it', () async {
      const staleCase = tooling.ToolingGuardCase(
        name: 'stale fixture control',
        fixturePath: _staleFixturePath,
        source: '// stale-only fixture\n',
        command: 'dart',
        arguments: const [],
      );
      final fixture = File(_staleFixturePath);
      await tooling.withToolingGuardFixtureLock(
        () => fixture.writeAsString('// preserved stale sentinel\n'),
      );
      addTearDown(() async {
        if (fixture.existsSync()) await fixture.delete();
      });

      final result = await tooling.verifyToolingGuards(
        cases: const [staleCase],
        runCommand: tooling.runToolingGuardCommand,
        runValidTreeChecks: false,
      );

      expect(result.isPassing, isFalse);
      expect(result.describe(), contains('pre-existing fixture'));
      expect(await fixture.readAsString(), '// preserved stale sentinel\n');
    });

    test('concurrent guard invocations serialize fixture ownership', () async {
      var active = 0;
      var maximumActive = 0;
      Future<tooling.ToolingGuardCommandResult> delayedFailure(
        tooling.ToolingGuardCase guardCase,
        String workingDirectory,
      ) async {
        active++;
        maximumActive = maximumActive < active ? active : maximumActive;
        await Future<void>.delayed(const Duration(milliseconds: 25));
        active--;
        return tooling.ToolingGuardCommandResult(
          exitCode: 1,
          stdout: '${guardCase.diagnosticCode} ${guardCase.fixturePath}',
          stderr: '',
        );
      }

      final results = await Future.wait([
        tooling.verifyToolingGuards(
          cases: const [tooling.ToolingGuardCase.importGuardPackage()],
          runCommand: delayedFailure,
          runValidTreeChecks: false,
        ),
        tooling.verifyToolingGuards(
          cases: const [tooling.ToolingGuardCase.importGuardPackage()],
          runCommand: delayedFailure,
          runValidTreeChecks: false,
        ),
      ]);

      expect(results.every((result) => result.isPassing), isTrue);
      expect(maximumActive, 1);
      expect(File(_packageFixturePath).existsSync(), isFalse);
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
            'valid production import_lint',
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
