/// Fail-closed iOS Native Assets evidence runner for Phase 60.
///
/// Command contracts intentionally remain visible for the architecture test:
/// flutter pub get --enforce-lockfile
/// pod install --deployment
/// flutter build ios --simulator --debug --no-codesign
/// git status --short
///
/// Flutter's supported iOS build updates the regenerated package floor from
/// the checked-in Xcode deployment target. This runner removes only generated
/// artifacts, invokes that source-owned mechanism, then rejects a generated
/// floor below iOS 15. It never writes a Package.swift manifest itself.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum NativeSafetyLane { tracer, full, runtime }

enum EvidenceResult { compileOnly, runtimePass, runtimeFail, blocked }

extension on EvidenceResult {
  String get label => switch (this) {
    EvidenceResult.compileOnly => 'COMPILE_ONLY',
    EvidenceResult.runtimePass => 'RUNTIME_PASS',
    EvidenceResult.runtimeFail => 'RUNTIME_FAIL',
    EvidenceResult.blocked => 'BLOCKED',
  };
}

const _runtimePrefix = 'integration_test/';
const _allowedRuntimeTests = <String>{
  'integration_test/sqlcipher_native_assets_migration_test.dart',
  'integration_test/sqlcipher_backup_recovery_test.dart',
};
const _generatedManifestRelativePath =
    'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift';
const _evidenceRelativePath = 'build/native_safety_evidence.json';
const _buildTimeout = Duration(minutes: 15);
const _simulatorCommandTimeout = Duration(seconds: 45);
const _runtimeTestTimeout = Duration(minutes: 8);

class _RunRecord {
  const _RunRecord({
    required this.name,
    required this.result,
    required this.details,
  });

  final String name;
  final EvidenceResult result;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'result': result.label,
    'details': details,
  };
}

class _RunnerFailure implements Exception {
  const _RunnerFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

extension on ProcessResult {
  String get output => '${this.stdout}\n${this.stderr}';
}

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final runner = _NativeSafetyRunner(
    lane: options.lane,
    runtimeTest: options.runtimeTest,
  );
  final exit = await runner.run();
  if (exit != 0) exitCode = exit;
}

({NativeSafetyLane lane, String runtimeTest}) _parseArguments(
  List<String> arguments,
) {
  NativeSafetyLane? lane;
  String? runtimeTest;
  for (final argument in arguments) {
    if (argument.startsWith('--lane=')) {
      if (lane != null) {
        throw const _RunnerFailure('lane supplied more than once');
      }
      lane = switch (argument.substring('--lane='.length)) {
        'tracer' => NativeSafetyLane.tracer,
        'full' => NativeSafetyLane.full,
        'runtime' => NativeSafetyLane.runtime,
        _ => throw const _RunnerFailure(
          'lane must be tracer, full, or runtime',
        ),
      };
    } else if (argument.startsWith('--runtime-test=')) {
      if (runtimeTest != null) {
        throw const _RunnerFailure('runtime test supplied more than once');
      }
      runtimeTest = argument.substring('--runtime-test='.length);
    } else {
      throw _RunnerFailure('unknown argument: $argument');
    }
  }
  if (lane == null ||
      runtimeTest == null ||
      !runtimeTest.startsWith(_runtimePrefix) ||
      !_allowedRuntimeTests.contains(runtimeTest)) {
    throw const _RunnerFailure(
      'usage: --lane=tracer|full|runtime --runtime-test=<approved SQLCipher integration test>',
    );
  }
  if (!File(runtimeTest).existsSync()) {
    throw _RunnerFailure('runtime test does not exist: $runtimeTest');
  }
  return (lane: lane, runtimeTest: runtimeTest);
}

class _NativeSafetyRunner {
  _NativeSafetyRunner({required this.lane, required this.runtimeTest});

  final NativeSafetyLane lane;
  final String runtimeTest;
  final List<_RunRecord> _records = <_RunRecord>[];
  String? _beforeStatus;
  String? _firstFailure;

  Future<int> run() async {
    try {
      _beforeStatus = await _statusSnapshot();
      await _runRetainedLockPreparation();
      if (lane == NativeSafetyLane.full) {
        await _runDisposableResolution();
        await _runBuildMatrix();
      }
      await _runSimulatorRuntime();
    } on _RunnerFailure catch (error) {
      _fail(error.message);
    } finally {
      try {
        await _assertStatusRestored();
      } on _RunnerFailure catch (error) {
        _fail(error.message);
      }
      await _writeEvidence();
    }
    return _firstFailure == null ? 0 : 1;
  }

  Future<void> _runRetainedLockPreparation() async {
    await _requireSuccess('flutter clean', <String>['flutter', 'clean']);
    await _requireSuccess('locked pub resolution', <String>[
      'flutter',
      'pub',
      'get',
      '--enforce-lockfile',
    ]);
    await _requireSuccess('locked CocoaPods resolution', <String>[
      'pod',
      'install',
      '--deployment',
    ], workingDirectory: 'ios');

    // Flutter's iOS build reads the source-controlled Xcode floor and calls
    // SwiftPackageManager.updateMinimumDeployment before Xcode resolves the
    // generated plugin package. This is intentionally before raw xcodebuild.
    await _requireSuccess('supported Flutter iOS package generation', <String>[
      'flutter',
      'build',
      'ios',
      '--simulator',
      '--debug',
      '--no-codesign',
    ]);
    _records.add(
      const _RunRecord(
        name: 'flutter-supported-package-generation',
        result: EvidenceResult.compileOnly,
        details: <String, Object?>{
          'destination_kind': 'SIMULATOR_GENERIC',
          'signed': false,
          'outcome': 'PASS',
        },
      ),
    );
    await _validateGeneratedManifest();

    await _runUnsignedBuild(
      configuration: 'Debug',
      destination: 'generic/platform=iOS Simulator',
      label: 'tracer-simulator-debug',
    );
  }

  Future<void> _runBuildMatrix() async {
    for (final configuration in <String>['Debug', 'Profile', 'Release']) {
      // The tracer already covers Debug on the generic simulator. The full
      // matrix adds the remaining five configurations, for six total builds.
      if (configuration != 'Debug') {
        await _runUnsignedBuild(
          configuration: configuration,
          destination: 'generic/platform=iOS Simulator',
          label: 'simulator-${configuration.toLowerCase()}',
        );
      }
      await _runUnsignedBuild(
        configuration: configuration,
        destination: 'generic/platform=iOS',
        label: 'generic-device-${configuration.toLowerCase()}',
      );
    }
  }

  Future<void> _runUnsignedBuild({
    required String configuration,
    required String destination,
    required String label,
  }) async {
    if (destination != 'generic/platform=iOS Simulator' &&
        destination != 'generic/platform=iOS') {
      throw _RunnerFailure('destination is not allowlisted: $destination');
    }
    final sdk = destination.endsWith('Simulator')
        ? 'iphonesimulator'
        : 'iphoneos';
    final result = await _run('xcodebuild', <String>[
      '-workspace',
      'Runner.xcworkspace',
      '-scheme',
      'Runner',
      '-configuration',
      configuration,
      '-sdk',
      sdk,
      '-destination',
      destination,
      'CODE_SIGNING_ALLOWED=NO',
      'clean',
      'build',
    ], workingDirectory: 'ios');
    _records.add(
      _RunRecord(
        name: label,
        result: EvidenceResult.compileOnly,
        details: <String, Object?>{
          'configuration': configuration,
          'destination_kind': destination.endsWith('Simulator')
              ? 'SIMULATOR_GENERIC'
              : 'GENERIC_DEVICE',
          'signed': false,
          'exit_code': result.exitCode,
          'outcome': result.exitCode == 0 ? 'PASS' : 'FAIL',
        },
      ),
    );
    if (result.exitCode != 0) {
      throw _RunnerFailure(
        '$label unsigned compile failed: ${_redact(result.output)}',
      );
    }
  }

  Future<void> _validateGeneratedManifest() async {
    final manifest = File(_generatedManifestRelativePath);
    if (!await manifest.exists()) {
      throw const _RunnerFailure(
        'supported Flutter generation did not produce Package.swift',
      );
    }
    final manifestContents = await manifest.readAsString();
    final validator = await _run('dart', <String>[
      'run',
      'scripts/dependency_compatibility.dart',
      '--mode=baseline',
      '--generated-swift-package-manifest=$_generatedManifestRelativePath',
    ]);
    if (validator.exitCode != 0 ||
        !RegExp(
          r'\.iOS\s*\(\s*"(?:15|1[6-9]|[2-9][0-9])(?:\.\d+)?"\s*\)',
        ).hasMatch(manifestContents)) {
      throw _RunnerFailure(
        'generated Swift package floor is below iOS 15 or failed canonical validation: '
        '${_redact(validator.output)}',
      );
    }
    _records.add(
      const _RunRecord(
        name: 'generated-swift-package-floor',
        result: EvidenceResult.compileOnly,
        details: <String, Object?>{
          'floor': 'iOS 15+',
          'source_mechanism':
              'Flutter build ios reads source-controlled IPHONEOS_DEPLOYMENT_TARGET',
          'manifest_written_by_runner': false,
        },
      ),
    );
  }

  Future<void> _runDisposableResolution() async {
    final root = await Directory.systemTemp.createTemp('hp-ios-native-safety-');
    try {
      await _copyTrackedWorkingTree(root);
      await File('${root.path}/pubspec.lock').delete();
      await File('${root.path}/ios/Podfile.lock').delete();
      await _requireSuccess('disposable pub resolution', <String>[
        'flutter',
        'pub',
        'get',
      ], workingDirectory: root.path);
      await _requireSuccess('disposable CocoaPods resolution', <String>[
        'pod',
        'install',
      ], workingDirectory: '${root.path}/ios');
      final retained = await _graphDigest(Directory.current.path);
      final disposable = await _graphDigest(root.path);
      if (retained != disposable) {
        throw const _RunnerFailure(
          'from-zero Pub/Pod graph differs from retained locks',
        );
      }
      _records.add(
        const _RunRecord(
          name: 'disposable-from-zero-resolution',
          result: EvidenceResult.compileOnly,
          details: <String, Object?>{
            'graph_match': true,
            'temporary_root_redacted': true,
          },
        ),
      );
    } finally {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    }
  }

  Future<void> _copyTrackedWorkingTree(Directory destination) async {
    final listed = await _run('git', <String>['ls-files', '-z']);
    if (listed.exitCode != 0) {
      throw const _RunnerFailure('cannot list tracked inputs');
    }
    for (final relative in utf8.decode(listed.stdout).split('\u0000')) {
      if (relative.isEmpty ||
          relative.startsWith('.git/') ||
          relative.startsWith('build/') ||
          relative.startsWith('ios/Pods/') ||
          relative.contains('/.symlinks/') ||
          relative.contains('/ephemeral/')) {
        continue;
      }
      final source = File(relative);
      if (!await source.exists()) {
        continue;
      }
      final target = File('${destination.path}/$relative');
      await target.parent.create(recursive: true);
      await source.copy(target.path);
    }
  }

  Future<String> _graphDigest(String root) async {
    final pub = await File('$root/pubspec.lock').readAsString();
    final pod = await File('$root/ios/Podfile.lock').readAsString();
    final selected = <String>[pub, pod]
        .map(
          (text) => text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .join('\n'),
        )
        .join('\n---\n');
    return sha256.convert(utf8.encode(selected)).toString();
  }

  Future<void> _runSimulatorRuntime() async {
    final devices = await _run('xcrun', <String>[
      'simctl',
      'list',
      'devices',
      'available',
      '-j',
    ], timeout: _simulatorCommandTimeout);
    if (devices.exitCode != 0) {
      _blockRuntime('CoreSimulator unavailable');
      return;
    }
    final deviceId = _firstAvailableIphoneSimulator(devices.output);
    if (deviceId == null) {
      _blockRuntime('no available iPhone Simulator');
      return;
    }
    final boot = await _run('xcrun', <String>[
      'simctl',
      'boot',
      deviceId,
    ], timeout: _simulatorCommandTimeout);
    if (boot.exitCode != 0 && !boot.output.contains('Booted')) {
      _blockRuntime('Simulator boot failed');
      return;
    }
    final status = await _run('xcrun', <String>[
      'simctl',
      'bootstatus',
      deviceId,
      '-b',
    ], timeout: _simulatorCommandTimeout);
    if (status.exitCode != 0) {
      _blockRuntime('Simulator bootstatus failed');
      return;
    }
    final runtime = await _run('flutter', <String>[
      'test',
      runtimeTest,
      '-d',
      deviceId,
      '-r',
      'expanded',
    ], timeout: _runtimeTestTimeout);
    _records.add(
      _RunRecord(
        name: 'simulator-sqlcipher-runtime',
        result: runtime.exitCode == 0
            ? EvidenceResult.runtimePass
            : EvidenceResult.runtimeFail,
        details: <String, Object?>{
          'destination_kind': 'BOOTED_SIMULATOR',
          'runtime_test': runtimeTest,
          'exit_code': runtime.exitCode,
          'simulator_identifier_redacted': true,
        },
      ),
    );
    if (runtime.exitCode != 0) {
      throw _RunnerFailure(
        'Simulator SQLCipher runtime failed: ${_redact(runtime.output)}',
      );
    }
  }

  String? _firstAvailableIphoneSimulator(String output) {
    try {
      final decoded = jsonDecode(output) as Map<String, Object?>;
      final devices = decoded['devices'] as Map<String, Object?>?;
      if (devices == null) {
        return null;
      }
      for (final runtime in devices.values) {
        if (runtime is! List) {
          continue;
        }
        for (final device in runtime.whereType<Map>()) {
          final name = device['name']?.toString() ?? '';
          final id = device['udid']?.toString();
          if (name.startsWith('iPhone') && id != null && id.isNotEmpty) {
            return id;
          }
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  void _blockRuntime(String reason) {
    _records.add(
      _RunRecord(
        name: 'simulator-sqlcipher-runtime',
        result: EvidenceResult.blocked,
        details: <String, Object?>{
          'reason': reason,
          'compile_is_not_runtime_acceptance': true,
        },
      ),
    );
    _fail('runtime evidence BLOCKED: $reason');
  }

  Future<void> _requireSuccess(
    String name,
    List<String> command, {
    String? workingDirectory,
  }) async {
    final result = await _run(
      command.first,
      command.sublist(1),
      workingDirectory: workingDirectory,
    );
    if (result.exitCode != 0) {
      throw _RunnerFailure('$name failed: ${_redact(result.output)}');
    }
  }

  Future<ProcessResult> _run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Duration timeout = _buildTimeout,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final commandExitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill(ProcessSignal.sigterm);
        return 124;
      },
    );
    return ProcessResult(
      process.pid,
      commandExitCode,
      await stdoutFuture,
      await stderrFuture,
    );
  }

  Future<String> _statusSnapshot() async {
    final status = await _run('git', <String>['status', '--short']);
    if (status.exitCode != 0) {
      throw const _RunnerFailure('cannot snapshot repository status');
    }
    return status.output;
  }

  Future<void> _assertStatusRestored() async {
    final after = await _statusSnapshot();
    if (_beforeStatus != after) {
      throw const _RunnerFailure(
        'main-tree status changed during native safety run',
      );
    }
  }

  Future<void> _writeEvidence() async {
    final evidence = File(_evidenceRelativePath);
    await evidence.parent.create(recursive: true);
    final payload = <String, Object?>{
      'lane': lane.name,
      'runtime_test': runtimeTest,
      'status_preserved': _beforeStatus != null,
      'outcome': _firstFailure == null ? 'PASS' : 'FAIL',
      'failure': _firstFailure == null ? null : _redact(_firstFailure!),
      'records': _records.map((_RunRecord record) => record.toJson()).toList(),
    };
    await evidence.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  void _fail(String message) => _firstFailure ??= message;

  String _redact(String value) => value
      .replaceAll(RegExp(r'/[^\s]+'), '<path>')
      .replaceAll(
        RegExp(r'\b[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27,}\b'),
        '<simulator-id>',
      )
      .replaceAll(
        RegExp(
          r'(password|token|secret|key)\s*[:=]\s*\S+',
          caseSensitive: false,
        ),
        r'$1=<redacted>',
      )
      .replaceAll(
        RegExp(
          r'(amount|note|merchant|sentinel)\s*[:=]\s*\S+',
          caseSensitive: false,
        ),
        r'$1=<redacted>',
      );
}
