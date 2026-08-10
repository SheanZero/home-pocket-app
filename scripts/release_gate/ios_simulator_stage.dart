/// Candidate-bound iOS Simulator preparation for the Phase 62 release gate.
///
/// This adapter is deliberately narrower than Phase 60's native-safety lane:
/// it prepares a redacted Simulator session for the full integration inventory;
/// it does not claim SQLCipher compile or runtime evidence and it never targets
/// a physical device.
library;

import 'dart:convert';
import 'dart:io';

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
  inventoryInvalid,
  integrationFailure,
  unexpectedSkip,
  preflightFailure,
}

class IosSimulatorOptions {
  IosSimulatorOptions({
    required this.candidate,
    this.workingDirectory = '.',
    this.integrationDirectory = 'integration_test',
    this.allowedSkips = const <String, IosAllowedSkip>{},
  });

  final CandidateFingerprint candidate;
  final String workingDirectory;
  final String integrationDirectory;
  final Map<String, IosAllowedSkip> allowedSkips;
}

class IosAllowedSkip {
  const IosAllowedSkip({
    required this.reason,
    required this.ownerPhase,
    required this.exitCondition,
  });

  final String reason;
  final String ownerPhase;
  final String exitCondition;

  bool get isComplete =>
      reason.isNotEmpty && ownerPhase.isNotEmpty && exitCondition.isNotEmpty;
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
  IosSimulatorEvidence({
    required this.candidate,
    required this.profile,
    required this.appDataIsolated,
    this.failure,
    List<String> discoveredTests = const <String>[],
    List<String> executedTests = const <String>[],
    Map<String, IosAllowedSkip> allowedSkips = const <String, IosAllowedSkip>{},
    this.preflightRan = false,
    List<List<String>> commands = const <List<String>>[],
    List<IosIntegrationRecord> testRecords = const <IosIntegrationRecord>[],
  }) : discoveredTests = List<String>.unmodifiable(discoveredTests),
       executedTests = List<String>.unmodifiable(executedTests),
       allowedSkips = Map<String, IosAllowedSkip>.unmodifiable(allowedSkips),
       commands = List<List<String>>.unmodifiable(
         commands.map(List<String>.unmodifiable),
       ),
       testRecords = List<IosIntegrationRecord>.unmodifiable(testRecords);

  final CandidateFingerprint candidate;
  final IosSimulatorProfile profile;
  final bool appDataIsolated;
  final IosSimulatorFailure? failure;
  final List<String> discoveredTests;
  final List<String> executedTests;
  final Map<String, IosAllowedSkip> allowedSkips;
  final bool preflightRan;
  final List<List<String>> commands;
  final List<IosIntegrationRecord> testRecords;

  bool get isReady => failure == null;

  /// The aggregate graph owns the single retry. This only exposes the closed
  /// infrastructure classification rather than retrying a destructive action.
  bool get retryEligible => switch (failure) {
    IosSimulatorFailure.startupReadiness ||
    IosSimulatorFailure.deviceTransport => true,
    _ => false,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'candidate': candidate.toJson(),
    'profile': profile.toJson(),
    'app_data_isolated': appDataIsolated,
    'ready': isReady,
    'failure': failure?.name,
    'retry_eligible': retryEligible,
    'discovered_tests': discoveredTests,
    'executed_tests': executedTests,
    'allowed_skips': allowedSkips.map(
      (path, skip) => MapEntry(path, <String, String>{
        'reason': skip.reason,
        'owner_phase': skip.ownerPhase,
        'exit_condition': skip.exitCondition,
      }),
    ),
    'preflight_ran': preflightRan,
    'commands': commands,
    'test_records': testRecords.map((record) => record.toJson()).toList(),
  };
}

class IosIntegrationRecord {
  const IosIntegrationRecord({
    required this.testPath,
    required this.candidateCommit,
    required this.exitCode,
  });

  final String testPath;
  final String candidateCommit;
  final int exitCode;

  Map<String, Object> toJson() => <String, Object>{
    'test_path': testPath,
    'candidate_commit': candidateCommit,
    'exit_code': exitCode,
  };
}

abstract interface class IosSimulatorAdapter {
  Future<IosSimulatorEvidence> prepare(IosSimulatorOptions options);

  Future<IosSimulatorEvidence> runFullSuite(IosSimulatorOptions options);
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

  @override
  Future<IosSimulatorEvidence> runFullSuite(IosSimulatorOptions options) async {
    if (!_candidateProvider().matches(options.candidate)) {
      return _blocked(options, IosSimulatorFailure.candidateDrift);
    }

    final commands = <List<String>>[];
    final inventory = await _runLogged(
      const <String>['xcrun', 'simctl', 'list', 'devices', 'available', '-j'],
      options,
      commands,
    );
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
    final discovered = discoverIosIntegrationTests(
      Directory('${options.workingDirectory}/${options.integrationDirectory}'),
      workingDirectory: options.workingDirectory,
    );
    final executed = <String>[];
    final testRecords = <IosIntegrationRecord>[];
    var preflightRan = false;
    IosSimulatorFailure? failure;

    try {
      if (discovered.isEmpty ||
          !_validSkipManifest(discovered, options.allowedSkips)) {
        failure = IosSimulatorFailure.inventoryInvalid;
      } else {
        failure = await _prepareColdSimulatorLogged(
          selection.identifier,
          options,
          commands,
        );
        if (failure == null) {
          for (final testPath in discovered) {
            if (options.allowedSkips.containsKey(testPath)) continue;
            final result = await _runLogged(
              <String>[
                'flutter',
                'test',
                testPath,
                '-d',
                selection.identifier,
                '-r',
                'expanded',
                '--dart-define=RELEASE_GATE_SYNTHETIC=true',
              ],
              options,
              commands,
              identifier: selection.identifier,
            );
            executed.add(testPath);
            testRecords.add(
              IosIntegrationRecord(
                testPath: testPath,
                candidateCommit: options.candidate.commit,
                exitCode: result.exitCode,
              ),
            );
            if (result.exitCode != 0 && failure == null) {
              failure = IosSimulatorFailure.integrationFailure;
            }
          }
          final preflight = await _runLogged(
            const <String>[
              'bash',
              'scripts/release_preflight.sh',
              '--platform',
              'ios',
            ],
            options,
            commands,
          );
          preflightRan = true;
          if (preflight.exitCode != 0 && failure == null) {
            failure = IosSimulatorFailure.preflightFailure;
          }
        }
      }
    } finally {
      final cleanupFailure = await _eraseAndShutdownLogged(
        selection.identifier,
        options,
        commands,
      );
      if (failure == null && cleanupFailure != null) {
        failure = cleanupFailure;
      }
    }

    if (!_candidateProvider().matches(options.candidate)) {
      failure = IosSimulatorFailure.candidateDrift;
    }
    if (!validateIosIntegrationMatrix(
      discovered: discovered,
      executed: executed,
      allowedSkips: options.allowedSkips,
    )) {
      failure ??= IosSimulatorFailure.unexpectedSkip;
    }
    final evidence = IosSimulatorEvidence(
      candidate: options.candidate,
      profile: profile,
      appDataIsolated: true,
      failure: failure,
      discoveredTests: discovered,
      executedTests: executed,
      allowedSkips: options.allowedSkips,
      preflightRan: preflightRan,
      commands: commands,
      testRecords: testRecords,
    );
    return evidence;
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

  Future<IosSimulatorFailure?> _prepareColdSimulatorLogged(
    String identifier,
    IosSimulatorOptions options,
    List<List<String>> commands,
  ) async {
    final shutdown = await _runLogged(
      <String>['xcrun', 'simctl', 'shutdown', identifier],
      options,
      commands,
      identifier: identifier,
    );
    if (shutdown.exitCode != 0) return IosSimulatorFailure.deviceTransport;
    final erase = await _runLogged(
      <String>['xcrun', 'simctl', 'erase', identifier],
      options,
      commands,
      identifier: identifier,
    );
    if (erase.exitCode != 0) return IosSimulatorFailure.deviceTransport;
    final boot = await _runLogged(
      <String>['xcrun', 'simctl', 'boot', identifier],
      options,
      commands,
      identifier: identifier,
    );
    if (boot.exitCode != 0) return IosSimulatorFailure.startupReadiness;
    final ready = await _runLogged(
      <String>['xcrun', 'simctl', 'bootstatus', identifier, '-b'],
      options,
      commands,
      identifier: identifier,
    );
    return ready.exitCode == 0 ? null : IosSimulatorFailure.startupReadiness;
  }

  Future<IosSimulatorFailure?> _eraseAndShutdownLogged(
    String identifier,
    IosSimulatorOptions options,
    List<List<String>> commands,
  ) async {
    final shutdown = await _runLogged(
      <String>['xcrun', 'simctl', 'shutdown', identifier],
      options,
      commands,
      identifier: identifier,
    );
    final erase = await _runLogged(
      <String>['xcrun', 'simctl', 'erase', identifier],
      options,
      commands,
      identifier: identifier,
    );
    return shutdown.exitCode == 0 && erase.exitCode == 0
        ? null
        : IosSimulatorFailure.cleanup;
  }

  Future<ProcessOutcome> _runLogged(
    List<String> command,
    IosSimulatorOptions options,
    List<List<String>> commands, {
    String? identifier,
  }) {
    commands.add(
      List<String>.unmodifiable(
        command.map((value) => value == identifier ? '<simulator>' : value),
      ),
    );
    return _run(command, options);
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
}) => adapter.runFullSuite(options);

bool validateIosSimulatorEvidence(IosSimulatorEvidence evidence) {
  final profile = evidence.profile;
  final recordedPaths = evidence.testRecords.map((record) => record.testPath);
  return profile.deviceKind == 'simulator' &&
      profile.model.startsWith('iPhone') &&
      profile.runtime.startsWith('com.apple.CoreSimulator.SimRuntime.iOS-') &&
      RegExp(r'^simulator-[a-f0-9]{16}$').hasMatch(profile.redactedToken) &&
      evidence.appDataIsolated &&
      evidence.testRecords.length == evidence.executedTests.length &&
      recordedPaths.toSet().length == evidence.testRecords.length &&
      evidence.testRecords.every(
        (record) =>
            record.candidateCommit == evidence.candidate.commit &&
            evidence.executedTests.contains(record.testPath),
      ) &&
      evidence.commands.every(
        (command) => command.every((value) => !value.contains('UDID')),
      );
}

List<String> discoverIosIntegrationTests(
  Directory integrationDirectory, {
  required String workingDirectory,
}) {
  if (!integrationDirectory.existsSync()) return const <String>[];
  final rootPrefix = '${Directory(workingDirectory).absolute.path}/';
  final discovered =
      integrationDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_test.dart'))
          .map((file) => file.absolute.path.replaceFirst(rootPrefix, ''))
          .map((path) => path.replaceAll('\\', '/'))
          .where((path) => path.startsWith('integration_test/'))
          .toList()
        ..sort();
  return List<String>.unmodifiable(discovered);
}

bool validateIosIntegrationMatrix({
  required List<String> discovered,
  required List<String> executed,
  required Map<String, IosAllowedSkip> allowedSkips,
}) {
  final discoveredSet = discovered.toSet();
  final executedSet = executed.toSet();
  if (discovered.isEmpty ||
      discoveredSet.length != discovered.length ||
      executedSet.length != executed.length ||
      !allowedSkips.values.every((skip) => skip.isComplete) ||
      !allowedSkips.keys.every(discoveredSet.contains) ||
      executedSet.any(allowedSkips.containsKey)) {
    return false;
  }
  return discoveredSet.length == executedSet.length + allowedSkips.length &&
      discoveredSet.containsAll(executedSet) &&
      discoveredSet.containsAll(allowedSkips.keys);
}

bool _validSkipManifest(
  List<String> discovered,
  Map<String, IosAllowedSkip> allowedSkips,
) =>
    discovered.isNotEmpty &&
    allowedSkips.values.every((skip) => skip.isComplete) &&
    allowedSkips.keys.every(discovered.toSet().contains);

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
    if (candidates.isEmpty) return null;
    candidates.sort(_compareSimulatorSelection);
    return candidates.first;
  } on FormatException {
    return null;
  }
}

/// Selects a reproducible iPhone destination from real `simctl` inventories:
/// newest iOS runtime first, then model and identifier in stable ascending order.
int _compareSimulatorSelection(
  _SimulatorSelection left,
  _SimulatorSelection right,
) {
  final runtime = _compareRuntimeDescending(left.runtime, right.runtime);
  if (runtime != 0) return runtime;
  final model = left.model.compareTo(right.model);
  if (model != 0) return model;
  return left.identifier.compareTo(right.identifier);
}

int _compareRuntimeDescending(String left, String right) {
  List<int> parts(String runtime) => RegExp(r'\d+')
      .allMatches(runtime)
      .map((match) => int.parse(match.group(0)!))
      .toList(growable: false);
  final leftParts = parts(left);
  final rightParts = parts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < length; index++) {
    final leftPart = index < leftParts.length ? leftParts[index] : 0;
    final rightPart = index < rightParts.length ? rightParts[index] : 0;
    final comparison = rightPart.compareTo(leftPart);
    if (comparison != 0) return comparison;
  }
  return left.compareTo(right);
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
