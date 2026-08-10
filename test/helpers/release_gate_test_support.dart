/// Test-only fixtures for the Phase 62 release-gate contract.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const maxSyntheticDiagnosticChars = 160;

enum SyntheticOutcomeClassification {
  success,
  infrastructureFailure,
  contractFailure,
}

class ReleaseGateCandidateFixture {
  ReleaseGateCandidateFixture._(this.root);

  final Directory root;

  static Future<ReleaseGateCandidateFixture> create() async {
    final root = await Directory.systemTemp.createTemp('release_gate_fixture_');
    final fixture = ReleaseGateCandidateFixture._(root);
    fixture._runGit(<String>['init']);
    fixture._runGit(<String>[
      'config',
      'user.email',
      'fixture@example.invalid',
    ]);
    fixture._runGit(<String>['config', 'user.name', 'Release Gate Fixture']);
    fixture._write('lib/candidate.dart', 'const candidate = 1;\n');
    fixture._write('pubspec.lock', 'packages:\n  fixture: 1.0.0\n');
    fixture._write(
      'config/release_gate_input.txt',
      'stable-toolchain-fixture\n',
    );
    fixture._runGit(<String>['add', '.']);
    fixture._runGit(<String>['commit', '-m', 'fixture candidate']);
    return fixture;
  }

  ReleaseGateCandidateIdentity captureIdentity() {
    final status = _runGit(<String>['status', '--porcelain']).stdout.toString();
    return ReleaseGateCandidateIdentity(
      commit: _runGit(<String>['rev-parse', 'HEAD']).stdout.toString().trim(),
      lockDigest: _digest('pubspec.lock'),
      configDigest: _digest('config/release_gate_input.txt'),
      isClean: status.trim().isEmpty,
    );
  }

  void dirtySource() => _write('lib/candidate.dart', 'const candidate = 2;\n');

  void mutateTrackedInput() => _write(
    'config/release_gate_input.txt',
    'stable-toolchain-fixture-mutated\n',
  );

  Future<void> dispose() => root.delete(recursive: true);

  ProcessResult _runGit(List<String> arguments) {
    final result = Process.runSync(
      'git',
      arguments,
      workingDirectory: root.path,
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw StateError('fixture git command failed: ${arguments.join(' ')}');
    }
    return result;
  }

  void _write(String relativePath, String contents) {
    final file = File('${root.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  String _digest(String relativePath) => sha256
      .convert(
        utf8.encode(File('${root.path}/$relativePath').readAsStringSync()),
      )
      .toString();
}

class ReleaseGateCandidateIdentity {
  const ReleaseGateCandidateIdentity({
    required this.commit,
    required this.lockDigest,
    required this.configDigest,
    required this.isClean,
  });

  final String commit;
  final String lockDigest;
  final String configDigest;
  final bool isClean;

  bool matches(ReleaseGateCandidateIdentity other) =>
      commit == other.commit &&
      lockDigest == other.lockDigest &&
      configDigest == other.configDigest &&
      isClean == other.isClean;
}

class SyntheticCommandOutcome {
  SyntheticCommandOutcome({
    required List<String> arguments,
    required this.exitCode,
    required this.classification,
    required String diagnostic,
    required this.candidate,
  }) : arguments = List<String>.unmodifiable(arguments),
       diagnostic = _boundedDiagnostic(diagnostic);

  final List<String> arguments;
  final int exitCode;
  final SyntheticOutcomeClassification classification;
  final String diagnostic;
  final ReleaseGateCandidateIdentity candidate;
}

class SyntheticCommandRunner {
  SyntheticCommandRunner(Iterable<SyntheticCommandOutcome> outcomes)
    : _remaining = List<SyntheticCommandOutcome>.of(outcomes);

  final List<SyntheticCommandOutcome> _remaining;
  final List<SyntheticCommandOutcome> attempts = <SyntheticCommandOutcome>[];

  SyntheticCommandOutcome run(List<String> arguments) {
    if (_remaining.isEmpty) {
      throw StateError('no synthetic outcome remains');
    }
    final outcome = _remaining.removeAt(0);
    if (!_sameArguments(outcome.arguments, arguments)) {
      throw StateError('unexpected command arguments');
    }
    attempts.add(outcome);
    return outcome;
  }
}

String _boundedDiagnostic(String value) {
  final redacted = value
      .replaceAll(RegExp(r'/Users/[^\s]+'), '<redacted-path>')
      .replaceAll(RegExp(r'(?:token|credential|secret)=[^\s]+'), '<redacted>');
  return redacted.length <= maxSyntheticDiagnosticChars
      ? redacted
      : '${redacted.substring(0, maxSyntheticDiagnosticChars)}…';
}

bool _sameArguments(List<String> left, List<String> right) =>
    left.length == right.length &&
    List<int>.generate(
      left.length,
      (index) => index,
    ).every((index) => left[index] == right[index]);
