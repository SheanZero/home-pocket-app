import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

  group('Phase 62 release-gate authority contract (intentional RED)', () {
    final source = File('scripts/release_gate.dart');

    test('requires the repository-owned sole authority', () {
      expect(
        source.existsSync(),
        isTrue,
        reason:
            'Missing Phase 62 release-gate authority: scripts/release_gate.dart',
      );
    });

    test(
      'requires a candidate identity model for clean and mutated checkout rejection',
      () {
        final contents = source.existsSync() ? source.readAsStringSync() : '';
        expect(
          contents,
          contains('ReleaseGateCandidate'),
          reason:
              'Missing Phase 62 candidate identity contract: ReleaseGateCandidate',
        );
        expect(
          contents,
          contains('validateCandidate'),
          reason: 'Missing Phase 62 dirty/mutated candidate rejection contract',
        );
      },
    );

    test('requires closed retry and resume invalidation contracts', () {
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
        contains('ReleaseGateVerdict'),
        reason: 'Missing Phase 62 final verdict contract: ReleaseGateVerdict',
      );
      expect(
        contents,
        contains('redact'),
        reason: 'Missing Phase 62 privacy-safe evidence contract: redact',
      );
    });
  });
}
