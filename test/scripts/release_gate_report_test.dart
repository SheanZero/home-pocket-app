import 'package:flutter_test/flutter_test.dart';

import '../../scripts/release_gate/models.dart';
import '../../scripts/release_gate/report.dart';

void main() {
  group('release evidence privacy', () {
    test('rejects secret assignment variants before persistence', () {
      const sensitiveEvidence = <Object>[
        'token: colon-secret',
        'credential = spaced-secret',
        'PASSWORD=compact-secret',
        '{"api-key":"json-secret"}',
      ];

      for (final evidence in sensitiveEvidence) {
        expect(validateEvidencePrivacy(evidence), isNotEmpty);
      }
    });

    test(
      'allows serialHostSuite evidence but rejects identifier assignments',
      () {
        final valid = _result(diagnostic: 'serialHostSuite completed');

        expect(validateGateResult(valid), isEmpty);
        expect(renderCompatibilityReport(valid), contains('serialHostSuite'));
        expect(
          validateEvidencePrivacy(<String, String>{
            'stage': 'serialHostSuite',
            'outcome': 'PASS',
          }),
          isEmpty,
        );
        expect(validateEvidencePrivacy('serial=emulator-5554'), isNotEmpty);
        expect(validateEvidencePrivacy('udid: device-identifier'), isNotEmpty);
      },
    );
  });
}

GateResult _result({required String diagnostic}) {
  final now = DateTime.utc(2026, 8, 10);
  return GateResult(
    candidate: CandidateFingerprint(
      commit: 'a' * 40,
      inputDigests: const <String, String>{'pubspec.lock': 'digest'},
    ),
    verdict: ReleaseVerdict.pass,
    stages: <StageResult>[
      StageResult(
        stage: GateStage.serialHostSuite,
        command: const <String>['release-gate'],
        startedAtUtc: now,
        finishedAtUtc: now,
        exitCode: 0,
        classification: StageClassification.succeeded,
        diagnostic: diagnostic,
      ),
    ],
  );
}
