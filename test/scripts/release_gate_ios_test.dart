import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/release_gate/ios_simulator_stage.dart';
import '../../scripts/release_gate/models.dart';
import '../../scripts/release_gate/process_adapter.dart';

void main() {
  group('Phase 62 iOS Simulator stage', () {
    final candidate = CandidateFingerprint(
      commit: 'a' * 40,
      inputDigests: <String, String>{'pubspec.lock': 'lock'},
    );

    test('prepares only an available iPhone Simulator with redacted evidence',
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
      expect(evidence.profile.runtime, 'com.apple.CoreSimulator.SimRuntime.iOS-18-2');
      expect(evidence.profile.redactedToken, isNot(contains('SIMULATOR-UDID')));
      expect(evidence.profile.redactedToken, startsWith('simulator-'));
      expect(jsonEncode(evidence.toJson()), isNot(contains('SIMULATOR-UDID')));
      expect(process.invocations, <List<String>>[
        const <String>['xcrun', 'simctl', 'list', 'devices', 'available', '-j'],
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
    });

    test('rejects a physical or ambiguous destination before destructive work',
        () async {
      final process = _RecordingProcessAdapter(<ProcessOutcome>[
        ProcessOutcome(exitCode: 0, diagnostic: jsonEncode(_physicalInventory)),
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
    });

    test('candidate mismatch before boot blocks without destructive commands',
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
      throw StateError('unexpected invocation: $executable ${arguments.join(' ')}');
    }
    return _outcomes.removeAt(0);
  }
}
