import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/release_gate/ios_simulator_stage.dart';
import '../../scripts/release_gate/models.dart';
import '../../scripts/release_gate/process_adapter.dart';

void main() {
  test('preserves a complete simulator inventory for local parsing', () {
    final inventory = jsonEncode(<String, Object>{
      'devices': <String, Object>{
        'com.apple.CoreSimulator.SimRuntime.iOS-26-2': List<Object>.generate(
          10,
          (index) => <String, Object>{
            'name': 'iPhone diagnostic ${'x' * 80} $index',
            'udid': 'SIMULATOR-UDID-$index',
            'isAvailable': true,
          },
        ),
      },
    });

    final preserved = scrubDiagnostic(inventory, preserveJson: true);

    expect(jsonDecode(preserved), isA<Map<Object?, Object?>>());
    expect(preserved, contains('iPhone diagnostic ${'x' * 80} 9'));
    expect(preserved, contains('SIMULATOR-UDID-9'));
  });

  group('Phase 62 iOS Simulator stage', () {
    final candidate = CandidateFingerprint(
      commit: 'a' * 40,
      inputDigests: <String, String>{'pubspec.lock': 'lock'},
    );

    test(
      'prepares only an available iPhone Simulator with redacted evidence',
      () async {
        final process = _RecordingProcessAdapter(<ProcessOutcome>[
          ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        ]);
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: process,
          candidateProvider: () => candidate,
        );

        final evidence = await adapter.prepare(
          IosSimulatorOptions(candidate: candidate),
        );

        expect(evidence.isReady, isTrue);
        expect(evidence.profile.deviceKind, 'simulator');
        expect(evidence.profile.model, 'iPhone 16');
        expect(
          evidence.profile.runtime,
          'com.apple.CoreSimulator.SimRuntime.iOS-18-2',
        );
        expect(
          evidence.profile.redactedToken,
          isNot(contains('SIMULATOR-UDID')),
        );
        expect(evidence.profile.redactedToken, startsWith('simulator-'));
        expect(
          jsonEncode(evidence.toJson()),
          isNot(contains('SIMULATOR-UDID')),
        );
        expect(process.invocations, <List<String>>[
          const <String>[
            'xcrun',
            'simctl',
            'list',
            'devices',
            'available',
            '-j',
          ],
          const <String>['xcrun', 'simctl', 'shutdown', 'SIMULATOR-UDID-123'],
          const <String>['xcrun', 'simctl', 'erase', 'SIMULATOR-UDID-123'],
          const <String>['xcrun', 'simctl', 'boot', 'SIMULATOR-UDID-123'],
          const <String>[
            'xcrun',
            'simctl',
            'bootstatus',
            'SIMULATOR-UDID-123',
            '-b',
          ],
          const <String>['xcrun', 'simctl', 'shutdown', 'SIMULATOR-UDID-123'],
          const <String>['xcrun', 'simctl', 'erase', 'SIMULATOR-UDID-123'],
        ]);
      },
    );

    test('tolerates an already-shutdown iPhone Simulator', () async {
      final process = _RecordingProcessAdapter(<ProcessOutcome>[
        ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
        const ProcessOutcome(exitCode: 148, diagnostic: 'already shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
        const ProcessOutcome(exitCode: 148, diagnostic: 'already shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
      ]);
      final adapter = SimctlIosSimulatorAdapter(
        processAdapter: process,
        candidateProvider: () => candidate,
      );

      final evidence = await adapter.prepare(
        IosSimulatorOptions(candidate: candidate),
      );

      expect(evidence.isReady, isTrue);
      expect(evidence.failure, isNull);
    });

    test('tolerates Xcode current-state shutdown responses', () async {
      final process = _RecordingProcessAdapter(<ProcessOutcome>[
        ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
        const ProcessOutcome(
          exitCode: 149,
          diagnostic: 'Unable to shutdown device in current state: Shutdown',
        ),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
        const ProcessOutcome(
          exitCode: 149,
          diagnostic: 'Unable to shutdown device in current state: Shutdown',
        ),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
      ]);
      final adapter = SimctlIosSimulatorAdapter(
        processAdapter: process,
        candidateProvider: () => candidate,
      );

      final evidence = await adapter.prepare(
        IosSimulatorOptions(candidate: candidate),
      );

      expect(evidence.failure, isNull);
    });

    test(
      'rejects a physical or ambiguous destination before destructive work',
      () async {
        final process = _RecordingProcessAdapter(<ProcessOutcome>[
          ProcessOutcome(
            exitCode: 0,
            diagnostic: jsonEncode(_physicalInventory),
          ),
        ]);
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: process,
          candidateProvider: () => candidate,
        );

        final evidence = await adapter.prepare(
          IosSimulatorOptions(candidate: candidate),
        );

        expect(evidence.isReady, isFalse);
        expect(evidence.failure, IosSimulatorFailure.invalidDestination);
        expect(process.invocations, hasLength(1));
      },
    );

    test(
      'selects one available iPhone deterministically from multiple devices',
      () async {
        final process = _RecordingProcessAdapter(<ProcessOutcome>[
          ProcessOutcome(
            exitCode: 0,
            diagnostic: jsonEncode(_multipleIphoneInventory),
          ),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        ]);
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: process,
          candidateProvider: () => candidate,
        );

        final evidence = await adapter.prepare(
          IosSimulatorOptions(candidate: candidate),
        );

        expect(evidence.isReady, isTrue);
        expect(
          evidence.profile.runtime,
          'com.apple.CoreSimulator.SimRuntime.iOS-18-2',
        );
        expect(evidence.profile.model, 'iPhone 16');
        expect(process.invocations[1], const <String>[
          'xcrun',
          'simctl',
          'shutdown',
          'IPHONE-16-A',
        ]);
      },
    );

    test(
      'candidate mismatch before boot blocks without destructive commands',
      () async {
        final process = _RecordingProcessAdapter(const <ProcessOutcome>[]);
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: process,
          candidateProvider: () => CandidateFingerprint(
            commit: 'b' * 40,
            inputDigests: <String, String>{'pubspec.lock': 'lock'},
          ),
        );

        final evidence = await adapter.prepare(
          IosSimulatorOptions(candidate: candidate),
        );

        expect(evidence.failure, IosSimulatorFailure.candidateDrift);
        expect(evidence.retryEligible, isFalse);
        expect(process.invocations, isEmpty);
      },
    );

    test('candidate mismatch after cleanup is terminal', () async {
      var candidateChecks = 0;
      final process = _RecordingProcessAdapter(<ProcessOutcome>[
        ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
        const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
      ]);
      final adapter = SimctlIosSimulatorAdapter(
        processAdapter: process,
        candidateProvider: () {
          candidateChecks++;
          return candidateChecks < 3
              ? candidate
              : CandidateFingerprint(
                  commit: 'b' * 40,
                  inputDigests: const <String, String>{'pubspec.lock': 'lock'},
                );
        },
      );

      final evidence = await adapter.prepare(
        IosSimulatorOptions(candidate: candidate),
      );

      expect(evidence.failure, IosSimulatorFailure.candidateDrift);
      expect(evidence.retryEligible, isFalse);
      expect(process.invocations.last, <String>[
        'xcrun',
        'simctl',
        'erase',
        'SIMULATOR-UDID-123',
      ]);
    });

    test('readiness failures are retry eligible but drift is not', () async {
      final readinessProcess = _RecordingProcessAdapter(<ProcessOutcome>[
        ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
        const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
        const ProcessOutcome(exitCode: 1, diagnostic: 'bootstatus timed out'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
        const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
      ]);
      final readinessAdapter = SimctlIosSimulatorAdapter(
        processAdapter: readinessProcess,
        candidateProvider: () => candidate,
      );

      final readinessEvidence = await readinessAdapter.prepare(
        IosSimulatorOptions(candidate: candidate),
      );

      expect(readinessEvidence.failure, IosSimulatorFailure.startupReadiness);
      expect(readinessEvidence.retryEligible, isTrue);
    });

    test(
      'recursively executes every discovered test then runs iOS preflight',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'ios-stage-inventory-',
        );
        addTearDown(() => root.delete(recursive: true));
        await File(
          '${root.path}/integration_test/root_test.dart',
        ).create(recursive: true);
        await File(
          '${root.path}/integration_test/nested/child_test.dart',
        ).create(recursive: true);
        final process = _RecordingProcessAdapter(<ProcessOutcome>[
          ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_iphoneInventory)),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'booted'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'ready'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'child passed'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'root passed'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'preflight passed'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'shutdown'),
          const ProcessOutcome(exitCode: 0, diagnostic: 'erased'),
        ]);
        final adapter = SimctlIosSimulatorAdapter(
          processAdapter: process,
          candidateProvider: () => candidate,
        );

        final evidence = await adapter.runFullSuite(
          IosSimulatorOptions(
            candidate: candidate,
            workingDirectory: root.path,
          ),
        );

        expect(evidence.isReady, isTrue);
        expect(evidence.discoveredTests, <String>[
          'integration_test/nested/child_test.dart',
          'integration_test/root_test.dart',
        ]);
        expect(evidence.executedTests, evidence.discoveredTests);
        expect(
          evidence.testRecords.map((record) => record.candidateCommit),
          everyElement(candidate.commit),
        );
        expect(evidence.allowedSkips, isEmpty);
        expect(evidence.preflightRan, isTrue);
        expect(
          evidence.commands.any(
            (command) =>
                command.join(' ') ==
                'bash scripts/release_preflight.sh --platform ios',
          ),
          isTrue,
        );
        expect(
          evidence.commands.expand((command) => command),
          isNot(contains('SIMULATOR-UDID-123')),
        );
      },
    );

    test('empty, omitted, duplicate, and unexpected-skip matrices block', () {
      expect(
        validateIosIntegrationMatrix(
          discovered: const <String>['integration_test/only_test.dart'],
          executed: const <String>[],
          allowedSkips: const <String, IosAllowedSkip>{},
        ),
        isFalse,
      );
      expect(
        validateIosIntegrationMatrix(
          discovered: const <String>['integration_test/only_test.dart'],
          executed: const <String>[
            'integration_test/only_test.dart',
            'integration_test/only_test.dart',
          ],
          allowedSkips: const <String, IosAllowedSkip>{},
        ),
        isFalse,
      );
      expect(
        validateIosIntegrationMatrix(
          discovered: const <String>['integration_test/only_test.dart'],
          executed: const <String>[],
          allowedSkips: <String, IosAllowedSkip>{
            'integration_test/unknown_test.dart': const IosAllowedSkip(
              reason: 'not in inventory',
              ownerPhase: '62',
              exitCondition: 'remove the skip',
            ),
          },
        ),
        isFalse,
      );
    });

    test(
      'iOS evidence validator requires successful records and preflight',
      () {
        const path = 'integration_test/critical_journey_test.dart';
        IosSimulatorEvidence evidence({
          IosSimulatorFailure? failure,
          bool preflightRan = true,
          List<String> executedTests = const <String>[path],
          List<IosIntegrationRecord>? records,
          IosSimulatorProfile profile = const IosSimulatorProfile(
            deviceKind: 'simulator',
            model: 'iPhone 16',
            runtime: 'com.apple.CoreSimulator.SimRuntime.iOS-18-2',
            redactedToken: 'simulator-aaaaaaaaaaaaaaaa',
          ),
        }) => IosSimulatorEvidence(
          candidate: candidate,
          profile: profile,
          appDataIsolated: true,
          failure: failure,
          discoveredTests: const <String>[path],
          executedTests: executedTests,
          preflightRan: preflightRan,
          testRecords:
              records ??
              <IosIntegrationRecord>[
                IosIntegrationRecord(
                  testPath: path,
                  candidateCommit: candidate.commit,
                  exitCode: 0,
                ),
              ],
        );

        expect(validateIosSimulatorEvidence(evidence()), isTrue);
        expect(
          validateIosSimulatorEvidence(
            evidence(failure: IosSimulatorFailure.integrationFailure),
          ),
          isFalse,
        );
        expect(
          validateIosSimulatorEvidence(evidence(preflightRan: false)),
          isFalse,
        );
        expect(
          validateIosSimulatorEvidence(
            evidence(records: const <IosIntegrationRecord>[]),
          ),
          isFalse,
        );
        expect(
          validateIosSimulatorEvidence(
            evidence(
              records: <IosIntegrationRecord>[
                IosIntegrationRecord(
                  testPath: path,
                  candidateCommit: candidate.commit,
                  exitCode: 1,
                ),
              ],
            ),
          ),
          isFalse,
        );
        expect(
          validateIosSimulatorEvidence(
            evidence(
              records: <IosIntegrationRecord>[
                const IosIntegrationRecord(
                  testPath: path,
                  candidateCommit: 'b',
                  exitCode: 0,
                ),
              ],
            ),
          ),
          isFalse,
        );
      },
    );
  });
}

const _iphoneInventory = <String, Object>{
  'devices': <String, Object>{
    'com.apple.CoreSimulator.SimRuntime.iOS-18-2': <Object>[
      <String, Object>{
        'name': 'iPhone 16',
        'udid': 'SIMULATOR-UDID-123',
        'isAvailable': true,
      },
    ],
  },
};

const _physicalInventory = <String, Object>{
  'devices': <String, Object>{
    'com.apple.CoreSimulator.SimRuntime.iOS-18-2': <Object>[
      <String, Object>{
        'name': 'iPad Pro',
        'udid': 'NOT-AN-IPHONE',
        'isAvailable': true,
      },
    ],
  },
};

const _multipleIphoneInventory = <String, Object>{
  'devices': <String, Object>{
    'com.apple.CoreSimulator.SimRuntime.iOS-18-1': <Object>[
      <String, Object>{
        'name': 'iPhone 17 Pro',
        'udid': 'OLDER-RUNTIME',
        'isAvailable': true,
      },
    ],
    'com.apple.CoreSimulator.SimRuntime.iOS-18-2': <Object>[
      <String, Object>{
        'name': 'iPhone 16 Pro',
        'udid': 'IPHONE-16-PRO',
        'isAvailable': true,
      },
      <String, Object>{
        'name': 'iPhone 16',
        'udid': 'IPHONE-16-B',
        'isAvailable': true,
      },
      <String, Object>{
        'name': 'iPhone 16',
        'udid': 'IPHONE-16-A',
        'isAvailable': true,
      },
    ],
  },
};

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
    bool preserveJson = false,
  }) async {
    invocations.add(<String>[executable, ...arguments]);
    if (_outcomes.isEmpty) {
      throw StateError(
        'unexpected invocation: $executable ${arguments.join(' ')}',
      );
    }
    return _outcomes.removeAt(0);
  }
}
