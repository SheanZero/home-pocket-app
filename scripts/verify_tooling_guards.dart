import 'dart:convert';
import 'dart:io';

typedef ToolingGuardCommand =
    Future<ToolingGuardCommandResult> Function(
      ToolingGuardCase guardCase,
      String workingDirectory,
    );

class ToolingGuardCase {
  const ToolingGuardCase({
    required this.name,
    required this.fixturePath,
    required this.source,
    required this.command,
    required this.arguments,
    required this.diagnosticCode,
  });

  const ToolingGuardCase.importGuardPackage()
    : this(
        name: 'import_guard package import',
        fixturePath:
            'lib/features/accounting/domain/phase58_package_import_fixture.dart',
        source:
            "import 'package:home_pocket/data/app_database.dart';\n\n"
            'void phase58ForbiddenPackageImport(AppDatabase database) {}\n',
        command: 'dart',
        arguments: const [
          'run',
          'custom_lint',
          '--format=json',
          '--no-fatal-infos',
        ],
        diagnosticCode: 'import_guard',
      );

  final String name;
  final String fixturePath;
  final String source;
  final String command;
  final List<String> arguments;
  final String diagnosticCode;
}

class ToolingGuardCommandResult {
  const ToolingGuardCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  String get combinedOutput => '$stdout\n$stderr';
}

class ToolingGuardCaseResult {
  const ToolingGuardCaseResult({
    required this.guardCase,
    required this.messages,
    required this.output,
  });

  final ToolingGuardCase guardCase;
  final List<String> messages;
  final String output;

  bool get isPassing => messages.isEmpty;
}

class ToolingGuardResult {
  const ToolingGuardResult(this.cases);

  final List<ToolingGuardCaseResult> cases;

  bool get isPassing => cases.every((result) => result.isPassing);

  String describe() => cases.expand((result) => result.messages).join('\n');
}

Future<ToolingGuardCommandResult> runToolingGuardCommand(
  ToolingGuardCase guardCase,
  String workingDirectory,
) async {
  final result = await Process.run(
    guardCase.command,
    guardCase.arguments,
    workingDirectory: workingDirectory,
  );
  return ToolingGuardCommandResult(
    exitCode: result.exitCode,
    stdout: result.stdout.toString(),
    stderr: result.stderr.toString(),
  );
}

Future<ToolingGuardResult> verifyToolingGuards({
  List<ToolingGuardCase> cases = const [ToolingGuardCase.importGuardPackage()],
  ToolingGuardCommand runCommand = runToolingGuardCommand,
  bool runValidTreeChecks = true,
  String workingDirectory = '.',
}) async {
  final root = Directory(workingDirectory).absolute;
  final stale = <ToolingGuardCaseResult>[];
  for (final guardCase in cases) {
    if (File('${root.path}/${guardCase.fixturePath}').existsSync()) {
      stale.add(
        ToolingGuardCaseResult(
          guardCase: guardCase,
          messages: ['pre-existing fixture: ${guardCase.fixturePath}'],
          output: '',
        ),
      );
    }
  }
  if (stale.isNotEmpty) return ToolingGuardResult(stale);

  final results = <ToolingGuardCaseResult>[];
  for (final guardCase in cases) {
    results.add(await _verifyCase(guardCase, root.path, runCommand));
  }
  return ToolingGuardResult(results);
}

Future<ToolingGuardCaseResult> _verifyCase(
  ToolingGuardCase guardCase,
  String workingDirectory,
  ToolingGuardCommand runCommand,
) async {
  final fixture = File('$workingDirectory/${guardCase.fixturePath}');
  final messages = <String>[];
  var output = '';
  try {
    await fixture.writeAsString(guardCase.source, flush: true);
    final commandResult = await runCommand(guardCase, workingDirectory);
    output = commandResult.combinedOutput;
    if (commandResult.exitCode == 0) {
      messages.add('${guardCase.name}: expected a nonzero exit');
    }
    if (!_hasDiagnostic(output, guardCase.diagnosticCode)) {
      messages.add(
        '${guardCase.name}: missing diagnostic ${guardCase.diagnosticCode}',
      );
    }
    if (!_hasFixturePath(output, guardCase.fixturePath)) {
      messages.add(
        '${guardCase.name}: missing fixture ${guardCase.fixturePath}',
      );
    }
  } on ProcessException catch (error) {
    messages.add('${guardCase.name}: command spawn failed: ${error.message}');
  } on FileSystemException catch (error) {
    messages.add('${guardCase.name}: fixture write failed: ${error.message}');
  } finally {
    try {
      if (fixture.existsSync()) await fixture.delete();
    } on FileSystemException catch (error) {
      messages.add('${guardCase.name}: cleanup failed: ${error.message}');
    }
  }
  return ToolingGuardCaseResult(
    guardCase: guardCase,
    messages: messages,
    output: output,
  );
}

bool _hasDiagnostic(String output, String diagnosticCode) {
  try {
    final decoded = jsonDecode(output);
    final diagnostics = decoded is Map<String, dynamic>
        ? decoded['diagnostics']
        : null;
    if (diagnostics is List) {
      return diagnostics.any(
        (diagnostic) =>
            diagnostic is Map && diagnostic['code'] == diagnosticCode,
      );
    }
  } on FormatException {
    // The expected custom_lint JSON was not emitted, so the stable code check
    // below will correctly fail.
  }
  return false;
}

bool _hasFixturePath(String output, String fixturePath) {
  final normalizedPath = fixturePath.replaceAll('\\', '/');
  return output.replaceAll('\\', '/').contains(normalizedPath);
}

Future<void> main() async {
  final result = await verifyToolingGuards();
  for (final caseResult in result.cases) {
    final status = caseResult.isPassing ? 'PASS' : 'FAIL';
    stdout.writeln('[tooling-guards] $status ${caseResult.guardCase.name}');
    if (!caseResult.isPassing) stderr.writeln(caseResult.messages.join('\n'));
  }
  if (!result.isPassing) exitCode = 1;
}
