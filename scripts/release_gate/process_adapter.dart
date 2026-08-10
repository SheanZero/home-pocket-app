import 'dart:async';
import 'dart:io';

const _maxDiagnosticCharacters = 512;
const _terminationGrace = Duration(seconds: 1);
const _drainGrace = Duration(seconds: 1);

class ProcessOutcome {
  const ProcessOutcome({required this.exitCode, required this.diagnostic});

  final int exitCode;
  final String diagnostic;
}

abstract interface class ProcessAdapter {
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
    required String workingDirectory,
    bool preserveJson = false,
  });
}

class SystemProcessAdapter implements ProcessAdapter {
  const SystemProcessAdapter();

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
    required String workingDirectory,
    bool preserveJson = false,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
    final outputDrains = <Future<String>>[
      process.stdout.transform(systemEncoding.decoder).join(),
      process.stderr.transform(systemEncoding.decoder).join(),
    ];
    var timedOut = false;
    int code;
    try {
      code = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      timedOut = true;
      process.kill(ProcessSignal.sigterm);
      try {
        await process.exitCode.timeout(_terminationGrace);
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode.timeout(_terminationGrace, onTimeout: () => 124);
      }
      code = 124;
    }

    List<String> output;
    try {
      output = await Future.wait<String>(outputDrains).timeout(_drainGrace);
    } on TimeoutException {
      output = const <String>['output drain timed out'];
    }
    final diagnostic = <String>[
      if (timedOut) 'process timed out',
      ...output.where((item) => item.isNotEmpty),
    ].join('\n');
    return ProcessOutcome(
      exitCode: timedOut ? 124 : code,
      diagnostic: scrubDiagnostic(diagnostic, preserveJson: preserveJson),
    );
  }
}

/// Scrubs diagnostics before a normalized evidence object receives them.
String scrubDiagnostic(String value, {bool preserveJson = false}) {
  var scrubbed = value
      .replaceAll(RegExp(r'/Users/[^\s]+'), '<redacted-path>')
      .replaceAll(RegExp(r'/home/[^\s]+'), '<redacted-path>')
      .replaceAll(
        RegExp(
          r'(?:token|credential|secret|password|api[_-]?key)=[^\s]+',
          caseSensitive: false,
        ),
        '<redacted>',
      )
      .replaceAll(RegExp(r'udid=[^\s]+', caseSensitive: false), '<redacted>');
  if (!preserveJson) {
    scrubbed = scrubbed.replaceAll(
      RegExp(r'"udid"\s*:\s*"[^"]+"', caseSensitive: false),
      '"udid":"<redacted>"',
    );
  }
  final limit = preserveJson ? 32768 : _maxDiagnosticCharacters;
  return scrubbed.length <= limit
      ? scrubbed
      : '${scrubbed.substring(0, limit)}…';
}
