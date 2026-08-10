import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/release_gate.dart';
import '../../scripts/release_gate/execution.dart';
import '../../scripts/release_gate/models.dart';
import '../../scripts/release_gate/process_adapter.dart';
import '../helpers/release_gate_test_support.dart';

void main() {
  group('release-gate fixture support', () {
    late ReleaseGateCandidateFixture fixture;

    setUp(() async {
      fixture = await ReleaseGateCandidateFixture.create();
    });

    tearDown(() => fixture.dispose());

    test('temporary Git candidate starts committed, clean, and isolated', () {
      final identity = fixture.captureIdentity();

      expect(identity.isClean, isTrue);
      expect(identity.commit, matches(RegExp(r'^[a-f0-9]{40}$')));
      expect(fixture.root.absolute.path, startsWith(Directory.systemTemp.path));
      expect(
        fixture.root.absolute.path,
        isNot(Directory.current.absolute.path),
      );
    });

    test(
      'source dirt and tracked-input mutation invalidate candidate identity',
      () {
        final original = fixture.captureIdentity();
        fixture.dirtySource();
        final dirty = fixture.captureIdentity();
        fixture.mutateTrackedInput();
        final mutated = fixture.captureIdentity();

        expect(dirty.isClean, isFalse);
        expect(original.matches(dirty), isFalse);
        expect(mutated.configDigest, isNot(original.configDigest));
        expect(original.matches(mutated), isFalse);
      },
    );

    test(
      'synthetic outcomes preserve invocation order and bounded diagnostics',
      () {
        final candidate = fixture.captureIdentity();
        final runner = SyntheticCommandRunner(<SyntheticCommandOutcome>[
          SyntheticCommandOutcome(
            arguments: const <String>['flutter', 'test', 'target.dart'],
            exitCode: 124,
            classification:
                SyntheticOutcomeClassification.infrastructureFailure,
            diagnostic: 'timeout at /Users/example/private token=not-retained',
            candidate: candidate,
          ),
          SyntheticCommandOutcome(
            arguments: const <String>['flutter', 'test', 'target.dart'],
            exitCode: 0,
            classification: SyntheticOutcomeClassification.success,
            diagnostic: 'pass',
            candidate: candidate,
          ),
        ]);

        final first = runner.run(const <String>[
          'flutter',
          'test',
          'target.dart',
        ]);
        final second = runner.run(const <String>[
          'flutter',
          'test',
          'target.dart',
        ]);

        expect(first.exitCode, 124);
        expect(
          first.classification,
          SyntheticOutcomeClassification.infrastructureFailure,
        );
        expect(first.diagnostic, isNot(contains('/Users/example')));
        expect(first.diagnostic, isNot(contains('not-retained')));
        expect(
          first.diagnostic.length,
          lessThanOrEqualTo(maxSyntheticDiagnosticChars + 1),
        );
        expect(
          runner.attempts,
          orderedEquals(<SyntheticCommandOutcome>[first, second]),
        );
        expect(second.candidate.matches(candidate), isTrue);
      },
    );
  });

  group('Phase 62 release-gate authority tracer', () {
    final source = File('scripts/release_gate.dart');

    late ReleaseGateCandidateFixture fixture;

    setUp(() async {
      fixture = await ReleaseGateCandidateFixture.create();
      File('${fixture.root.path}/.gitignore').writeAsStringSync('build/\n');
      _runFixtureGit(fixture.root, const <String>['add', '.gitignore']);
      _runFixtureGit(fixture.root, const <String>[
        'commit',
        '-m',
        'ignore release-gate artifacts',
      ]);
    });

    tearDown(() => fixture.dispose());

    test(
      'a clean committed candidate produces bound JSON and Markdown evidence',
      () async {
        final expected = fixture.captureIdentity();
        final adapter = _RecordingProcessAdapter(<ProcessOutcome>[
          const ProcessOutcome(
            exitCode: 0,
            diagnostic:
                'wrapper passed at /Users/fixture/private token=discard',
          ),
        ]);

        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: adapter,
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/tracer.json',
        );

        expect(result.verdict, ReleaseVerdict.pass);
        expect(result.candidate!.commit, expected.commit);
        expect(result.stages, hasLength(3));
        expect(adapter.invocations, <List<String>>[
          const <String>['bash', 'scripts/verify_codegen_reproducibility.sh'],
        ]);
        expect(
          result.stages
              .singleWhere((stage) => stage.stage == GateStage.prerequisite)
              .diagnostic,
          isNot(contains('/Users/fixture')),
        );
        expect(
          result.stages
              .singleWhere((stage) => stage.stage == GateStage.prerequisite)
              .diagnostic,
          isNot(contains('discard')),
        );

        final json = File(
          '${fixture.root.path}/build/release_gate/tracer.json',
        );
        final markdown = File(
          '${fixture.root.path}/build/release_gate/tracer.preview.md',
        );
        expect(json.existsSync(), isTrue);
        expect(markdown.existsSync(), isTrue);
        expect(json.readAsStringSync(), contains(expected.commit));
        expect(markdown.readAsStringSync(), contains(expected.commit));
        expect(result.isSchemaValid, isTrue);
      },
    );

    test(
      'a failed prerequisite stops before later stages with BLOCKED',
      () async {
        final adapter = _RecordingProcessAdapter(<ProcessOutcome>[
          const ProcessOutcome(exitCode: 1, diagnostic: 'prerequisite failed'),
        ]);

        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: adapter,
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/blocked.json',
        );

        expect(result.verdict, ReleaseVerdict.blocked);
        expect(result.stages.map((stage) => stage.stage), <GateStage>[
          GateStage.candidate,
          GateStage.prerequisite,
        ]);
        expect(
          result.stages.last.classification,
          StageClassification.commandFailed,
        );
      },
    );

    test(
      'strict arguments and candidate state fail closed before process launch',
      () async {
        fixture.dirtySource();
        final adapter = _RecordingProcessAdapter(const <ProcessOutcome>[]);

        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: adapter,
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/dirty.json',
        );

        expect(result.verdict, ReleaseVerdict.blocked);
        expect(adapter.invocations, isEmpty);
        expect(
          () => parseReleaseGateOptions(const <String>[
            '--scope=tracer',
            '--bad',
          ]),
          throwsArgumentError,
        );
      },
    );

    test(
      'a prerequisite mutation fails the final candidate drift proof',
      () async {
        final adapter = _MutatingProcessAdapter(
          fixture.root,
          'config/release_gate_input.txt',
          'mutated by child process\n',
        );

        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: adapter,
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/mutated.json',
        );

        expect(result.verdict, ReleaseVerdict.blocked);
        expect(result.stages.last.stage, GateStage.finalDrift);
        expect(
          result.stages.last.classification,
          StageClassification.driftDetected,
        );
      },
    );

    test(
      'ignored raw artifacts do not alter the candidate fingerprint',
      () async {
        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: _MutatingProcessAdapter(
            fixture.root,
            'build/release_gate/child.raw.log',
            'ignored child artifact\n',
          ),
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/ignored.json',
        );

        expect(result.verdict, ReleaseVerdict.pass);
        expect(
          result.stages.last.classification,
          StageClassification.succeeded,
        );
      },
    );

    test(
      'untracked generated output blocks before the prerequisite launches',
      () async {
        File('${fixture.root.path}/lib/generated/rogue.g.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('generated residue\n');
        final adapter = _RecordingProcessAdapter(const <ProcessOutcome>[]);

        final result = await runReleaseGate(
          workingDirectory: fixture.root,
          processAdapter: adapter,
          trackedInputPaths: const <String>[
            'pubspec.lock',
            'config/release_gate_input.txt',
          ],
          resultPath: 'build/release_gate/generated-residue.json',
        );

        expect(result.verdict, ReleaseVerdict.blocked);
        expect(adapter.invocations, isEmpty);
      },
    );

    test('only RPT-A metadata and ignored raw artifacts are outside scope', () {
      expect(
        isCandidateScopedPath('docs/testing/RELEASE_COMPATIBILITY.md'),
        isFalse,
      );
      expect(isCandidateScopedPath('build/release_gate/raw.log'), isFalse);
      expect(isCandidateScopedPath('docs/testing/other_report.md'), isTrue);
      expect(isCandidateScopedPath('lib/main.dart'), isTrue);
    });

    test('requires the repository-owned sole authority', () {
      expect(source.existsSync(), isTrue);
    });

    test(
      'requires a candidate identity model for clean and mutated checkout rejection',
      () {
        final contents = source.existsSync() ? source.readAsStringSync() : '';
        expect(
          contents,
          contains('CandidateFingerprint'),
          reason:
              'Missing Phase 62 candidate identity contract: CandidateFingerprint',
        );
        expect(
          contents,
          contains('validateCandidate'),
          reason: 'Missing Phase 62 dirty/mutated candidate rejection contract',
        );
      },
    );

    test('reserves closed retry and resume invalidation contracts', () {
      final contents = source.existsSync() ? source.readAsStringSync() : '';
      expect(
        contents,
        contains('ReleaseGateRetry'),
        reason: 'Missing Phase 62 closed retry contract: ReleaseGateRetry',
      );
      expect(
        contents,
        contains('validateResume'),
        reason: 'Missing Phase 62 resume invalidation contract: validateResume',
      );
    });

    test('requires verdict and privacy-safe result contracts', () {
      final contents = source.existsSync() ? source.readAsStringSync() : '';
      expect(
        contents,
        contains('ReleaseVerdict'),
        reason: 'Missing Phase 62 final verdict contract: ReleaseGateVerdict',
      );
      expect(
        contents,
        contains('scrub'),
        reason: 'Missing Phase 62 privacy-safe evidence contract: redact',
      );
    });
  });

  group('Phase 62 host execution graph contracts', () {
    final candidate = CandidateFingerprint(
      commit: 'a' * 40,
      inputDigests: const <String, String>{'pubspec.lock': 'lock'},
    );

    test('only closed infrastructure classes receive one retry', () {
      for (final failure in <FailureClass>[
        FailureClass.startupReadiness,
        FailureClass.deviceTransport,
        FailureClass.dependencyNetwork,
        FailureClass.runnerTimeout,
      ]) {
        expect(
          retryDecisionFor(failure, priorAttempts: 0),
          RetryDecision.retry,
        );
        expect(retryDecisionFor(failure, priorAttempts: 1), RetryDecision.stop);
      }
      for (final failure in <FailureClass>[
        FailureClass.assertion,
        FailureClass.compilation,
        FailureClass.signingHygiene,
        FailureClass.privacy,
        FailureClass.coverage,
        FailureClass.drift,
        FailureClass.schema,
        FailureClass.unknown,
      ]) {
        expect(retryDecisionFor(failure, priorAttempts: 0), RetryDecision.stop);
      }
    });

    test('classifier is conservative and terminal for unknown output', () {
      expect(
        classifyFailure(
          const ProcessOutcome(exitCode: 124, diagnostic: 'process timed out'),
        ),
        FailureClass.runnerTimeout,
      );
      expect(
        classifyFailure(
          const ProcessOutcome(exitCode: 1, diagnostic: 'assertion failed'),
        ),
        FailureClass.assertion,
      );
      expect(
        classifyFailure(
          const ProcessOutcome(exitCode: 1, diagnostic: 'mystery'),
        ),
        FailureClass.unknown,
      );
    });

    test('checkpoint rejects every identity and integrity mutation', () {
      final checkpoint = ResumeCheckpoint.create(
        candidate: candidate,
        configurationDigests: const <String, String>{'workflow': 'cfg'},
        environmentFingerprint: const <String, String>{'os': 'macos'},
        completedStageDigests: const <GateStage, String>{
          GateStage.prerequisite: 'pre',
        },
      );
      expect(
        checkpoint.isValidFor(
          candidate: candidate,
          configurationDigests: const <String, String>{'workflow': 'cfg'},
          environmentFingerprint: const <String, String>{'os': 'macos'},
          stageGraphVersion: releaseGraphVersion,
        ),
        isTrue,
      );
      expect(
        checkpoint.isValidFor(
          candidate: CandidateFingerprint(
            commit: 'b' * 40,
            inputDigests: const <String, String>{'pubspec.lock': 'lock'},
          ),
          configurationDigests: const <String, String>{'workflow': 'cfg'},
          environmentFingerprint: const <String, String>{'os': 'macos'},
          stageGraphVersion: releaseGraphVersion,
        ),
        isFalse,
      );
      expect(
        checkpoint
            .copyWith(integrity: 'tampered')
            .isValidFor(
              candidate: candidate,
              configurationDigests: const <String, String>{'workflow': 'cfg'},
              environmentFingerprint: const <String, String>{'os': 'macos'},
              stageGraphVersion: releaseGraphVersion,
            ),
        isFalse,
      );
    });

    test('resume restarts at earliest invalidated stable stage', () {
      expect(
        earliestInvalidatedStage(
          const <GateStage, String>{
            GateStage.prerequisite: 'old',
            GateStage.targetRegressions: 'same',
          },
          const <GateStage, String>{
            GateStage.prerequisite: 'new',
            GateStage.targetRegressions: 'same',
          },
        ),
        GateStage.prerequisite,
      );
      expect(
        earliestInvalidatedStage(
          const <GateStage, String>{
            GateStage.prerequisite: 'same',
            GateStage.targetRegressions: 'same',
          },
          const <GateStage, String>{
            GateStage.prerequisite: 'same',
            GateStage.targetRegressions: 'same',
          },
        ),
        isNull,
      );
    });
  });
}

class _RecordingProcessAdapter implements ProcessAdapter {
  _RecordingProcessAdapter(this._outcomes);

  final List<ProcessOutcome> _outcomes;
  final List<List<String>> invocations = <List<String>>[];

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
    required String workingDirectory,
  }) async {
    invocations.add(<String>[executable, ...arguments]);
    if (_outcomes.isEmpty) {
      throw StateError('no process outcome configured');
    }
    return _outcomes.removeAt(0);
  }
}

class _MutatingProcessAdapter implements ProcessAdapter {
  _MutatingProcessAdapter(this.root, this.relativePath, this.contents);

  final Directory root;
  final String relativePath;
  final String contents;

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
    required String workingDirectory,
  }) async {
    final file = File('${root.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    return const ProcessOutcome(
      exitCode: 0,
      diagnostic: 'child process passed',
    );
  }
}

void _runFixtureGit(Directory root, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw StateError('fixture git command failed: ${arguments.join(' ')}');
  }
}
