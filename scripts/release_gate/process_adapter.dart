import 'dart:async';
import 'dart:io';

const _maxDiagnosticCharacters = 512;

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
    final output = await Future.wait<String>(<Future<String>>[
      process.stdout.transform(systemEncoding.decoder).join(),
      process.stderr.transform(systemEncoding.decoder).join(),
    ]);
    try {
      final code = await process.exitCode.timeout(timeout);
      return ProcessOutcome(
        exitCode: code,
        diagnostic: scrubDiagnostic(
          output.where((item) => item.isNotEmpty).join('\n'),
          preserveJson: preserveJson,
        ),
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      return const ProcessOutcome(
        exitCode: 124,
        diagnostic: 'process timed out',
      );
    }
  }
}

/// Scrubs diagnostics before a normalized evidence object receives them.
String scrubDiagnostic(String value, {bool preserveJson = false}) {
  final scrubbed = value
      .replaceAll(RegExp(r'/Users/[^\s]+'), '<redacted-path>')
      .replaceAll(RegExp(r'/home/[^\s]+'), '<redacted-path>')
      .replaceAll(
        RegExp(r'"udid"\s*:\s*"[^"]+"', caseSensitive: false),
        '"udid":"<redacted>"',
      )
      .replaceAll(
        RegExp(
          r'(?:token|credential|secret|password|api[_-]?key)=[^\s]+',
          caseSensitive: false,
        ),
        '<redacted>',
      )
      .replaceAll(RegExp(r'udid=[^\s]+', caseSensitive: false), '<redacted>');
  final limit = preserveJson ? 32768 : _maxDiagnosticCharacters;
  return scrubbed.length <= limit
      ? scrubbed
      : '${scrubbed.substring(0, limit)}…';
}
