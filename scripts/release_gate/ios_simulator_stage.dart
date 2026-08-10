/// Candidate-bound iOS Simulator preparation for the Phase 62 release gate.
///
/// This adapter is deliberately narrower than Phase 60's native-safety lane:
/// it prepares a redacted Simulator session for the full integration inventory;
/// it does not claim SQLCipher compile or runtime evidence and it never targets
/// a physical device.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'process_adapter.dart';

const _simulatorTimeout = Duration(minutes: 2);

enum IosSimulatorFailure {
  invalidDestination,
  candidateDrift,
  startupReadiness,
  deviceTransport,
  cleanup,
}

class IosSimulatorOptions {
  IosSimulatorOptions({required this.candidate, this.workingDirectory = '.'});

  final CandidateFingerprint candidate;
  final String workingDirectory;
}

class IosSimulatorProfile {
  const IosSimulatorProfile({
    required this.deviceKind,
    required this.model,
    required this.runtime,
    required this.redactedToken,
  });

  const IosSimulatorProfile.unavailable()
    : deviceKind = 'unavailable',
      model = 'unavailable',
      runtime = 'unavailable',
      redactedToken = 'unavailable';

  final String deviceKind;
  final String model;
  final String runtime;
  final String redactedToken;

  Map<String, String> toJson() => <String, String>{
    'device_kind': deviceKind,
    'model': model,
    'runtime': runtime,
    'redacted_token': redactedToken,
  };
}

class IosSimulatorEvidence {
  const IosSimulatorEvidence({
    required this.candidate,
    required this.profile,
    required this.appDataIsolated,
    this.failure,
  });

  final CandidateFingerprint candidate;
  final IosSimulatorProfile profile;
  final bool appDataIsolated;
  final IosSimulatorFailure? failure;

  bool get isReady => failure == null;

  /// The aggregate graph owns the single retry. This only exposes the closed
  /// infrastructure classification rather than retrying a destructive action.
  bool get retryEligible => switch (failure) {
    IosSimulatorFailure.startupReadiness ||
    IosSimulatorFailure.deviceTransport ||
    IosSimulatorFailure.cleanup => true,
    _ => false,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'candidate': candidate.toJson(),
    'profile': profile.toJson(),
    'app_data_isolated': appDataIsolated,
    'ready': isReady,
    'failure': failure?.name,
    'retry_eligible': retryEligible,
  };
}

abstract interface class IosSimulatorAdapter {
  Future<IosSimulatorEvidence> prepare(IosSimulatorOptions options);
}

/// Apple-tooling implementation with argument vectors only. Raw simulator IDs
/// remain local to this method and are replaced with an irreversible token
/// before any normalized evidence object is created.
class SimctlIosSimulatorAdapter implements IosSimulatorAdapter {
  factory SimctlIosSimulatorAdapter({
    required ProcessAdapter processAdapter,
    required CandidateFingerprint Function() candidateProvider,
  }) => SimctlIosSimulatorAdapter._(processAdapter, candidateProvider);

  SimctlIosSimulatorAdapter._(this._processAdapter, this._candidateProvider);

  final ProcessAdapter _processAdapter;
  final CandidateFingerprint Function() _candidateProvider;

  @override
  Future<IosSimulatorEvidence> prepare(IosSimulatorOptions options) async {
    if (!_candidateProvider().matches(options.candidate)) {
      return _blocked(options, IosSimulatorFailure.candidateDrift);
    }

    final inventory = await _run(const <String>[
      'xcrun',
      'simctl',
      'list',
      'devices',
      'available',
      '-j',
    ], options);
    if (inventory.exitCode != 0) {
      return _blocked(options, IosSimulatorFailure.deviceTransport);
    }

    final selection = _selectIphoneSimulator(inventory.diagnostic);
    if (selection == null) {
      return _blocked(options, IosSimulatorFailure.invalidDestination);
    }
    if (!_candidateProvider().matches(options.candidate)) {
      return _blocked(options, IosSimulatorFailure.candidateDrift);
    }

    final profile = IosSimulatorProfile(
      deviceKind: 'simulator',
      model: selection.model,
      runtime: selection.runtime,
      redactedToken: _redactedToken(selection.identifier),
    );
    IosSimulatorFailure? failure;
    try {
      failure = await _prepareColdSimulator(selection.identifier, options);
    } finally {
      final cleanupFailure = await _eraseAndShutdown(
        selection.identifier,
        options,
      );
      if (failure == null && cleanupFailure != null) {
        failure = cleanupFailure;
      }
    }

    if (!_candidateProvider().matches(options.candidate)) {
      failure = IosSimulatorFailure.candidateDrift;
    }
    final evidence = IosSimulatorEvidence(
      candidate: options.candidate,
      profile: profile,
      appDataIsolated: true,
      failure: failure,
    );
    return validateIosSimulatorEvidence(evidence)
        ? evidence
        : _blocked(options, IosSimulatorFailure.invalidDestination);
  }

  Future<IosSimulatorFailure?> _prepareColdSimulator(
    String identifier,
    IosSimulatorOptions options,
  ) async {
    final shutdown = await _run(<String>[
      'xcrun',
      'simctl',
      'shutdown',
      identifier,
    ], options);
    if (shutdown.exitCode != 0) return IosSimulatorFailure.deviceTransport;
    final erase = await _run(<String>[
      'xcrun',
      'simctl',
      'erase',
      identifier,
    ], options);
    if (erase.exitCode != 0) return IosSimulatorFailure.deviceTransport;
    final boot = await _run(<String>[
      'xcrun',
      'simctl',
      'boot',
      identifier,
    ], options);
    if (boot.exitCode != 0) return IosSimulatorFailure.startupReadiness;
    final ready = await _run(<String>[
      'xcrun',
      'simctl',
      'bootstatus',
      identifier,
      '-b',
    ], options);
    return ready.exitCode == 0 ? null : IosSimulatorFailure.startupReadiness;
  }

  Future<IosSimulatorFailure?> _eraseAndShutdown(
    String identifier,
    IosSimulatorOptions options,
  ) async {
    final shutdown = await _run(<String>[
      'xcrun',
      'simctl',
      'shutdown',
      identifier,
    ], options);
    final erase = await _run(<String>[
      'xcrun',
      'simctl',
      'erase',
      identifier,
    ], options);
    return shutdown.exitCode == 0 && erase.exitCode == 0
        ? null
        : IosSimulatorFailure.cleanup;
  }

  Future<ProcessOutcome> _run(
    List<String> command,
    IosSimulatorOptions options,
  ) {
    return _processAdapter.run(
      command.first,
      command.skip(1).toList(growable: false),
      timeout: _simulatorTimeout,
      workingDirectory: options.workingDirectory,
    );
  }
}

Future<IosSimulatorEvidence> runIosSimulatorStage({
  required IosSimulatorOptions options,
  required IosSimulatorAdapter adapter,
}) => adapter.prepare(options);

bool validateIosSimulatorEvidence(IosSimulatorEvidence evidence) {
  final profile = evidence.profile;
  return profile.deviceKind == 'simulator' &&
      profile.model.startsWith('iPhone') &&
      profile.runtime.startsWith('com.apple.CoreSimulator.SimRuntime.iOS-') &&
      RegExp(r'^simulator-[a-f0-9]{16}$').hasMatch(profile.redactedToken) &&
      evidence.appDataIsolated;
}

class _SimulatorSelection {
  const _SimulatorSelection({
    required this.identifier,
    required this.model,
    required this.runtime,
  });

  final String identifier;
  final String model;
  final String runtime;
}

_SimulatorSelection? _selectIphoneSimulator(String rawInventory) {
  try {
    final decoded = jsonDecode(rawInventory);
    if (decoded is! Map<String, Object?>) return null;
    final devices = decoded['devices'];
    if (devices is! Map<String, Object?>) return null;
    final candidates = <_SimulatorSelection>[];
    for (final entry in devices.entries) {
      final entries = entry.value;
      if (entries is! List<Object?>) continue;
      for (final device in entries) {
        if (device is! Map<String, Object?>) continue;
        final model = device['name'];
        final identifier = device['udid'];
        final available = device['isAvailable'];
        if (model is String &&
            identifier is String &&
            available == true &&
            model.startsWith('iPhone') &&
            entry.key.startsWith('com.apple.CoreSimulator.SimRuntime.iOS-')) {
          candidates.add(
            _SimulatorSelection(
              identifier: identifier,
              model: model,
              runtime: entry.key,
            ),
          );
        }
      }
    }
    if (candidates.length != 1) return null;
    return candidates.single;
  } on FormatException {
    return null;
  }
}

String _redactedToken(String identifier) =>
    'simulator-${sha256.convert(utf8.encode(identifier)).toString().substring(0, 16)}';

IosSimulatorEvidence _blocked(
  IosSimulatorOptions options,
  IosSimulatorFailure failure,
) => IosSimulatorEvidence(
  candidate: options.candidate,
  profile: const IosSimulatorProfile.unavailable(),
  appDataIsolated: false,
  failure: failure,
);
