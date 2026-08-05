import 'dart:io';

/// Repository-owned Riverpod checks for the analyzer-8 production graph.
///
/// `riverpod_lint` 3.1.0 remains locked as a compatibility hold, but is not an
/// active analysis-server plugin on Flutter 3.44.8. This contract protects the
/// app-root invariant without treating an unloaded upstream plugin as green.
class ProviderContractViolation {
  const ProviderContractViolation({
    required this.code,
    required this.path,
    required this.line,
    required this.message,
  });

  final String code;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line $code: $message';
}

class ProviderContractReport {
  const ProviderContractReport(this.violations);

  final List<ProviderContractViolation> violations;

  bool get isPassing => violations.isEmpty;

  String describe() => violations.join('\n');
}

ProviderContractReport checkProviderContract(String rootPath) {
  final root = Directory(rootPath).absolute;
  final violations = <ProviderContractViolation>[];
  _checkAppRoots(root, violations);
  _checkRiverpodLintHold(root, violations);
  return ProviderContractReport(violations);
}

void _checkAppRoots(
  Directory root,
  List<ProviderContractViolation> violations,
) {
  final lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'provider_contract_lib_missing',
        path: 'lib',
        line: 1,
        message: 'Cannot inspect app roots because lib/ is missing.',
      ),
    );
    return;
  }

  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') ||
        file.path.endsWith('.g.dart') ||
        file.path.endsWith('.freezed.dart') ||
        file.path.contains(
          '${Platform.pathSeparator}generated${Platform.pathSeparator}',
        )) {
      continue;
    }
    final source = file.readAsStringSync();
    final path = _relativePath(root, file);
    final scopeBindings = _riverpodScopeBindings(source);
    for (final call in _findCalls(source, 'runApp')) {
      if (_isScopedRoot(call, scopeBindings)) continue;
      violations.add(
        ProviderContractViolation(
          code: 'missing_provider_scope',
          path: path,
          line: _lineAt(source, call.offset),
          message:
              'runApp root must be wrapped by ProviderScope or UncontrolledProviderScope.',
        ),
      );
    }

    // Happy Pocket initializes a prebuilt ProviderContainer before rendering;
    // its app-root seam is the AppRunner callback rather than a direct runApp.
    if (path == 'lib/main.dart' &&
        source.contains('typedef AppRunner') &&
        !_hasScopedAppRunner(source, scopeBindings)) {
      violations.add(
        const ProviderContractViolation(
          code: 'missing_provider_scope',
          path: 'lib/main.dart',
          line: 1,
          message:
              'AppRunner success root must use UncontrolledProviderScope with the initialized container.',
        ),
      );
    }
  }
}

void _checkRiverpodLintHold(
  Directory root,
  List<ProviderContractViolation> violations,
) {
  final options = File('${root.path}/analysis_options.yaml');
  if (!options.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_hold_unverifiable',
        path: 'analysis_options.yaml',
        line: 1,
        message:
            'Missing analysis options; cannot verify the riverpod_lint hold.',
      ),
    );
  } else {
    final source = options.readAsStringSync();
    final activePlugin = RegExp(
      r'^\s*(?:-\s*riverpod_lint|riverpod_lint\s*:)\s*(?:#.*)?$',
      multiLine: true,
    ).firstMatch(source);
    if (activePlugin != null) {
      violations.add(
        ProviderContractViolation(
          code: 'riverpod_lint_active',
          path: 'analysis_options.yaml',
          line: _lineAt(source, activePlugin.start),
          message:
              'riverpod_lint is held on Flutter 3.44.8/analyzer 8 and must not be configured as an active plugin without a passing bad/control probe.',
        ),
      );
    }
  }

  final lockfile = File('${root.path}/pubspec.lock');
  if (!lockfile.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_version_unparseable',
        path: 'pubspec.lock',
        line: 1,
        message:
            'Missing lockfile; cannot verify the held riverpod_lint version.',
      ),
    );
    return;
  }

  final lockSource = lockfile.readAsStringSync();
  final package = RegExp(
    r'^  riverpod_lint:\s*$',
    multiLine: true,
  ).firstMatch(lockSource);
  final afterPackage = package == null ? '' : lockSource.substring(package.end);
  final nextPackage = RegExp(r'\n  \S').firstMatch(afterPackage);
  final packageSection = nextPackage == null
      ? afterPackage
      : afterPackage.substring(0, nextPackage.start);
  final version = package == null
      ? null
      : RegExp(
          r'''^    version:\s*["']([^"']+)["']\s*$''',
          multiLine: true,
        ).firstMatch(packageSection)?.group(1);
  if (version == null ||
      !RegExp(r'^\d+\.\d+\.\d+(?:\+\d+)?$').hasMatch(version)) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_version_unparseable',
        path: 'pubspec.lock',
        line: 1,
        message: 'Held riverpod_lint version is missing or not parseable.',
      ),
    );
  } else if (version != '3.1.0') {
    violations.add(
      ProviderContractViolation(
        code: 'riverpod_lint_version_mismatch',
        path: 'pubspec.lock',
        line: _lineAt(lockSource, package!.start),
        message:
            'Expected held riverpod_lint 3.1.0 for the analyzer-8 graph, found $version.',
      ),
    );
  }
}

bool _hasScopedAppRunner(String source, _RiverpodScopeBindings bindings) {
  for (final call in _findCalls(source, 'appRunner')) {
    if (_isScopedRoot(
      call,
      bindings,
      requiredConstructor: 'UncontrolledProviderScope',
    )) {
      return true;
    }
  }
  return false;
}

bool _isScopedRoot(
  _Call call,
  _RiverpodScopeBindings bindings, {
  String? requiredConstructor,
}) {
  final tokens = call.arguments;
  var index = 0;
  while (index < tokens.length &&
      (tokens[index].text == 'const' || tokens[index].text == 'new')) {
    index++;
  }
  if (index >= tokens.length || tokens[index].kind != _TokenKind.identifier) {
    return false;
  }

  final first = tokens[index].text;
  String? constructor;
  String? importAlias;
  if (index + 1 < tokens.length && tokens[index + 1].text == '(') {
    constructor = first;
  } else if (index + 3 < tokens.length &&
      tokens[index + 1].text == '.' &&
      tokens[index + 2].kind == _TokenKind.identifier &&
      tokens[index + 3].text == '(') {
    importAlias = first;
    constructor = tokens[index + 2].text;
  }
  if (constructor == null ||
      (constructor != 'ProviderScope' &&
          constructor != 'UncontrolledProviderScope') ||
      (requiredConstructor != null && constructor != requiredConstructor)) {
    return false;
  }

  return importAlias == null
      ? bindings.allowsUnqualified(constructor)
      : bindings.allowsQualified(importAlias, constructor);
}

_RiverpodScopeBindings _riverpodScopeBindings(String source) {
  final tokens = _tokens(source);
  final unqualified = <String>{};
  final qualified = <String, Set<String>>{};
  for (var index = 0; index < tokens.length; index++) {
    if (tokens[index].text != 'import' ||
        index + 1 >= tokens.length ||
        tokens[index + 1].kind != _TokenKind.string ||
        tokens[index + 1].text !=
            'package:flutter_riverpod/flutter_riverpod.dart') {
      continue;
    }

    String? alias;
    final shown = <String>{};
    final hidden = <String>{};
    var hasShow = false;
    for (
      index += 2;
      index < tokens.length && tokens[index].text != ';';
      index++
    ) {
      final token = tokens[index];
      if (token.text == 'as' &&
          index + 1 < tokens.length &&
          tokens[index + 1].kind == _TokenKind.identifier) {
        alias = tokens[++index].text;
      } else if (token.text == 'show' || token.text == 'hide') {
        final target = token.text == 'show' ? shown : hidden;
        hasShow |= token.text == 'show';
        while (index + 1 < tokens.length && tokens[index + 1].text != ';') {
          final candidate = tokens[++index];
          if (candidate.kind == _TokenKind.identifier) {
            target.add(candidate.text);
          }
          if (candidate.text == 'show' || candidate.text == 'hide') {
            index--;
            break;
          }
        }
      }
    }

    const constructors = {'ProviderScope', 'UncontrolledProviderScope'};
    final allowed = constructors
        .where(
          (name) =>
              (!hasShow || shown.contains(name)) && !hidden.contains(name),
        )
        .toSet();
    if (alias == null) {
      unqualified.addAll(allowed);
    } else {
      qualified[alias] = allowed;
    }
  }
  return _RiverpodScopeBindings(unqualified, qualified);
}

List<_Call> _findCalls(String source, String name) {
  final calls = <_Call>[];
  final tokens = _tokens(source);
  for (var index = 0; index + 1 < tokens.length; index++) {
    if (tokens[index].text != name || tokens[index + 1].text != '(') continue;
    if (index > 0 && tokens[index - 1].text == '.') continue;
    var depth = 1;
    var close = index + 2;
    for (; close < tokens.length; close++) {
      if (tokens[close].text == '(') depth++;
      if (tokens[close].text == ')' && --depth == 0) break;
    }
    if (close == tokens.length) continue;
    calls.add(_Call(tokens[index].offset, tokens.sublist(index + 2, close)));
  }
  return calls;
}

List<_Token> _tokens(String source) {
  final tokens = <_Token>[];
  for (var index = 0; index < source.length;) {
    final char = source[index];
    if (char.trim().isEmpty) {
      index++;
    } else if (char == '/' &&
        index + 1 < source.length &&
        source[index + 1] == '/') {
      final newline = source.indexOf('\n', index + 2);
      index = newline == -1 ? source.length : newline + 1;
    } else if (char == '/' &&
        index + 1 < source.length &&
        source[index + 1] == '*') {
      var depth = 1;
      index += 2;
      while (index + 1 < source.length && depth > 0) {
        if (source[index] == '/' && source[index + 1] == '*') {
          depth++;
          index += 2;
        } else if (source[index] == '*' && source[index + 1] == '/') {
          depth--;
          index += 2;
        } else {
          index++;
        }
      }
      if (depth != 0) return const [];
    } else if (char == "'" || char == '"') {
      final start = index;
      final quote = char;
      final triple =
          index + 2 < source.length &&
          source[index + 1] == quote &&
          source[index + 2] == quote;
      index += triple ? 3 : 1;
      final contentStart = index;
      while (index < source.length) {
        if (triple &&
            index + 2 < source.length &&
            source[index] == quote &&
            source[index + 1] == quote &&
            source[index + 2] == quote) {
          break;
        }
        if (!triple && source[index] == '\\') {
          index += 2;
        } else if (!triple && source[index] == quote) {
          break;
        } else {
          index++;
        }
      }
      if (index >= source.length) {
        return const [];
      }
      tokens.add(
        _Token(_TokenKind.string, source.substring(contentStart, index), start),
      );
      index += triple ? 3 : 1;
    } else if (RegExp(r'[A-Za-z_$]').hasMatch(char)) {
      final start = index++;
      while (index < source.length &&
          RegExp(r'[A-Za-z0-9_$]').hasMatch(source[index])) {
        index++;
      }
      tokens.add(
        _Token(_TokenKind.identifier, source.substring(start, index), start),
      );
    } else {
      tokens.add(_Token(_TokenKind.punctuation, char, index));
      index++;
    }
  }
  return tokens;
}

int _lineAt(String source, int offset) =>
    1 + '\n'.allMatches(source.substring(0, offset)).length;

String _relativePath(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  return file.path.startsWith(prefix)
      ? file.path.substring(prefix.length).replaceAll('\\', '/')
      : file.path.replaceAll('\\', '/');
}

class _Call {
  const _Call(this.offset, this.arguments);

  final int offset;
  final List<_Token> arguments;
}

class _RiverpodScopeBindings {
  const _RiverpodScopeBindings(this.unqualified, this.qualified);

  final Set<String> unqualified;
  final Map<String, Set<String>> qualified;

  bool allowsUnqualified(String constructor) =>
      unqualified.contains(constructor);

  bool allowsQualified(String alias, String constructor) =>
      qualified[alias]?.contains(constructor) ?? false;
}

enum _TokenKind { identifier, string, punctuation }

class _Token {
  const _Token(this.kind, this.text, this.offset);

  final _TokenKind kind;
  final String text;
  final int offset;
}

void main() {
  final report = checkProviderContract('.');
  if (report.isPassing) {
    stdout.writeln('[provider-contract] PASS owned provider contract');
    return;
  }
  for (final violation in report.violations) {
    stderr.writeln('[provider-contract] $violation');
  }
  exitCode = 1;
}
