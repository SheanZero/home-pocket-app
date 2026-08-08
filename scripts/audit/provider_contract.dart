import 'dart:io';

/// Repository-owned Riverpod checks for the analyzer-12 production graph.
///
/// `riverpod_lint` 3.1.4 is active through the analysis-server plugin protocol.
/// This defense-in-depth contract also protects the app-root invariant.
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
  _checkRiverpodLintConfiguration(root, violations);
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
    final flutterRunAppPrefixes = _flutterRunAppPrefixes(source);
    for (final call in _findCalls(
      source,
      'runApp',
      allowedQualifiedPrefixes: flutterRunAppPrefixes,
    )) {
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

void _checkRiverpodLintConfiguration(
  Directory root,
  List<ProviderContractViolation> violations,
) {
  final options = File('${root.path}/analysis_options.yaml');
  if (!options.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_plugin_unverifiable',
        path: 'analysis_options.yaml',
        line: 1,
        message:
            'Missing analysis options; cannot verify the riverpod_lint plugin.',
      ),
    );
  } else {
    final source = options.readAsStringSync();
    final activePlugin = RegExp(
      r'^\s*riverpod_lint\s*:\s*3\.1\.4\s*(?:#.*)?$',
      multiLine: true,
    ).firstMatch(source);
    if (activePlugin == null) {
      violations.add(
        const ProviderContractViolation(
          code: 'riverpod_lint_plugin_missing',
          path: 'analysis_options.yaml',
          line: 1,
          message:
              'riverpod_lint 3.1.4 must remain active on the analyzer-12 graph.',
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
            'Missing lockfile; cannot verify the active riverpod_lint version.',
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
        message: 'Active riverpod_lint version is missing or not parseable.',
      ),
    );
  } else if (version != '3.1.4') {
    violations.add(
      ProviderContractViolation(
        code: 'riverpod_lint_version_mismatch',
        path: 'pubspec.lock',
        line: _lineAt(lockSource, package!.start),
        message:
            'Expected active riverpod_lint 3.1.4 for the analyzer-12 graph, found $version.',
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
      ? bindings.allowsUnqualified(constructor, call.offset)
      : bindings.allowsQualified(importAlias, constructor, call.offset);
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
  // Imports are not enough to establish an unqualified binding. A declaration
  // in the library or an enclosing lexical scope wins over an imported name.
  // This scanner intentionally fails closed for those declarations instead of
  // attempting analyzer-style resolution from a standalone Dart script.
  final scopeShadows = _scopeShadows(tokens);
  return _RiverpodScopeBindings(
    unqualified,
    qualified,
    qualifiedAliasShadows: scopeShadows,
  );
}

List<_ScopeShadow> _scopeShadows(List<_Token> tokens) {
  final shadows = <String>{};
  final records = <_ScopeShadow>[];
  for (var index = 0; index < tokens.length; index++) {
    final name = tokens[index].text;
    if (_isScopeDeclaration(tokens, index) ||
        _isFormalParameterDeclaration(tokens, index) ||
        _isPatternBinding(tokens, index)) {
      if (!shadows.add('${tokens[index].offset}:$name')) continue;
      records.add(_scopeShadowFor(tokens, index));
    }
  }
  return records;
}

_ScopeShadow _scopeShadowFor(List<_Token> tokens, int declaration) {
  final token = tokens[declaration];
  if (_isFormalParameterDeclaration(tokens, declaration)) {
    final open = _enclosingParenthesis(tokens, declaration)!;
    final close = _matchingParenthesis(tokens, open)!;
    return _ScopeShadow(
      name: token.text,
      offset: token.offset,
      start: tokens[close].offset,
      end: _functionBodyEnd(tokens, close),
    );
  }
  if (_isAtLibraryScope(tokens, declaration)) {
    return _ScopeShadow.libraryWide(name: token.text, offset: token.offset);
  }
  final block = _enclosingBlock(tokens, declaration);
  return _ScopeShadow(
    name: token.text,
    offset: token.offset,
    start: token.offset,
    end: block == null ? token.offset : tokens[block.$2].offset,
  );
}

bool _isAtLibraryScope(List<_Token> tokens, int index) {
  final braces = <bool>[];
  for (var cursor = 0; cursor < index; cursor++) {
    if (tokens[cursor].text == '{') braces.add(_isScopeBrace(tokens, cursor));
    if (tokens[cursor].text == '}' && braces.isNotEmpty) braces.removeLast();
  }
  return !braces.contains(true);
}

(int, int)? _enclosingBlock(List<_Token> tokens, int index) {
  final braces = <int>[];
  final opens = <int>[];
  for (var cursor = 0; cursor < index; cursor++) {
    if (tokens[cursor].text == '{') {
      braces.add(cursor);
      if (_isScopeBrace(tokens, cursor)) opens.add(cursor);
    }
    if (tokens[cursor].text == '}' && braces.isNotEmpty) {
      final open = braces.removeLast();
      if (opens.isNotEmpty && opens.last == open) opens.removeLast();
    }
  }
  if (opens.isEmpty) return null;
  final open = opens.last;
  final close = _matchingBrace(tokens, open);
  return close == null ? null : (open, close);
}

bool _isScopeBrace(List<_Token> tokens, int index) {
  if (tokens[index].text != '{' || index == 0) return false;
  final previous = tokens[index - 1].text;
  return previous == ')' ||
      previous == 'else' ||
      previous == 'try' ||
      previous == 'finally' ||
      previous == 'do';
}

int _functionBodyEnd(List<_Token> tokens, int close) {
  var index = close + 1;
  while (index < tokens.length &&
      (tokens[index].text == 'async' || tokens[index].text == '*')) {
    index++;
  }
  if (index < tokens.length && tokens[index].text == '{') {
    return tokens[_matchingBrace(tokens, index) ?? index].offset;
  }
  for (; index < tokens.length; index++) {
    if (tokens[index].text == ';') return tokens[index].offset;
  }
  return tokens.last.offset;
}

/// Detects names introduced by Dart's destructuring patterns without trying to
/// resolve an entire Dart AST. This is deliberately conservative: the contract
/// must never accept a locally bound value as a Riverpod constructor or import
/// prefix. It still distinguishes bindings from initializers, comments,
/// strings, and import directives so ordinary occurrences do not shadow an
/// import.
bool _isPatternBinding(List<_Token> tokens, int index) {
  if (_isImportOrExportDirective(tokens, index) ||
      !_isPatternBindingPosition(tokens, index)) {
    return false;
  }
  return _isDeclarationPatternBinding(tokens, index) ||
      _isCasePatternBinding(tokens, index);
}

bool _isPatternBindingPosition(List<_Token> tokens, int index) {
  if (index == 0 || index + 1 >= tokens.length) return false;
  const leadingPatternTokens = {'(', '[', '{', ',', ':'};
  const trailingPatternTokens = {',', ')', ']', '}', ':', '='};
  return leadingPatternTokens.contains(tokens[index - 1].text) &&
      trailingPatternTokens.contains(tokens[index + 1].text);
}

bool _isDeclarationPatternBinding(List<_Token> tokens, int index) {
  final declaration = _nearestStatementDeclaration(tokens, index);
  if (declaration == null) return false;

  // A binding lives on the left side of its declaration assignment. This keeps
  // `final value = (ProviderScope, other);` an ordinary use instead of a
  // false-positive shadow.
  return !_hasAssignmentBetween(tokens, declaration, index);
}

int? _nearestStatementDeclaration(List<_Token> tokens, int index) {
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final token = tokens[cursor].text;
    // Braces can be part of an object or map pattern, so only a statement
    // terminator conclusively ends the declaration search.
    if (token == ';') return null;
    if (token == 'final' || token == 'var') return cursor;
  }
  return null;
}

bool _hasAssignmentBetween(List<_Token> tokens, int start, int end) {
  for (var cursor = start + 1; cursor < end; cursor++) {
    if (tokens[cursor].text != '=') continue;
    final previous = cursor == 0 ? null : tokens[cursor - 1].text;
    final next = cursor + 1 < tokens.length ? tokens[cursor + 1].text : null;
    if (previous != '=' && previous != '!' && previous != '>' && next != '=') {
      return true;
    }
  }
  return false;
}

bool _isCasePatternBinding(List<_Token> tokens, int index) {
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final token = tokens[cursor].text;
    if (token == ';' || token == '{' || token == '}') return false;
    if (token == 'case') return true;
  }
  return false;
}

bool _isScopeDeclaration(List<_Token> tokens, int index) {
  if (_isImportOrExportDirective(tokens, index)) return false;
  final previous = index == 0 ? null : tokens[index - 1].text;
  if (const {
    'class',
    'mixin',
    'enum',
    'extension',
    'typedef',
    'var',
    'final',
  }.contains(previous)) {
    return true;
  }

  // `extension type Name(...)` introduces a library declaration just like a
  // class or typedef. The declaration name follows `type`, so the generic
  // declaration check above cannot see it. Treat it as a shadow before
  // considering calls or member accesses; only the exact `extension type`
  // token pair qualifies, so ordinary extension members remain untouched.
  if (previous == 'type' &&
      index >= 2 &&
      tokens[index - 2].text == 'extension') {
    return true;
  }

  if (_isTypedVariableDeclaration(tokens, index)) return true;

  if (index + 1 >= tokens.length || tokens[index + 1].text != '(') {
    return false;
  }
  final close = _matchingParenthesis(tokens, index + 1);
  if (close == null || close + 1 >= tokens.length) return false;
  return _isFunctionBodyStart(tokens, close + 1);
}

bool _isImportOrExportDirective(List<_Token> tokens, int index) {
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final token = tokens[cursor].text;
    if (token == ';') return false;
    if (token == 'import' || token == 'export') return true;
  }
  return false;
}

bool _isTypedVariableDeclaration(List<_Token> tokens, int index) {
  if (index == 0 || index + 1 >= tokens.length) return false;
  final previous = tokens[index - 1];
  final next = tokens[index + 1];
  final couldEndType =
      previous.kind == _TokenKind.identifier ||
      previous.text == '?' ||
      previous.text == '>';
  if (!couldEndType || previous.text == '.') return false;

  return next.text == ';' ||
      next.text == ',' ||
      (next.text == '=' &&
          (index + 2 >= tokens.length || tokens[index + 2].text != '='));
}

bool _isFormalParameterDeclaration(List<_Token> tokens, int index) {
  final open = _enclosingParenthesis(tokens, index);
  if (open == null) return false;
  final close = _matchingParenthesis(tokens, open);
  if (close == null || index >= close || close + 1 >= tokens.length) {
    return false;
  }

  if (!_isFunctionBodyStart(tokens, close + 1)) {
    return false;
  }

  final next = tokens[index + 1].text;
  return next == ',' ||
      next == ')' ||
      next == ']' ||
      next == '}' ||
      next == '=';
}

bool _isFunctionBodyStart(List<_Token> tokens, int index) {
  final token = tokens[index].text;
  return token == '{' ||
      token == 'async' ||
      (token == '=' &&
          index + 1 < tokens.length &&
          tokens[index + 1].text == '>');
}

int? _enclosingParenthesis(List<_Token> tokens, int index) {
  final opens = <int>[];
  for (var cursor = 0; cursor < index; cursor++) {
    if (tokens[cursor].text == '(') {
      opens.add(cursor);
    } else if (tokens[cursor].text == ')' && opens.isNotEmpty) {
      opens.removeLast();
    }
  }
  return opens.isEmpty ? null : opens.last;
}

int? _matchingParenthesis(List<_Token> tokens, int open) {
  var depth = 0;
  for (var index = open; index < tokens.length; index++) {
    if (tokens[index].text == '(') depth++;
    if (tokens[index].text == ')' && --depth == 0) return index;
  }
  return null;
}

int? _matchingBrace(List<_Token> tokens, int open) {
  var depth = 0;
  for (var index = open; index < tokens.length; index++) {
    if (tokens[index].text == '{') depth++;
    if (tokens[index].text == '}' && --depth == 0) return index;
  }
  return null;
}

List<_Call> _findCalls(
  String source,
  String name, {
  Set<String> allowedQualifiedPrefixes = const {},
}) {
  final calls = <_Call>[];
  final tokens = _tokens(source);
  for (var index = 0; index + 1 < tokens.length; index++) {
    if (tokens[index].text != name || tokens[index + 1].text != '(') continue;
    if (index > 0 && tokens[index - 1].text == '.') {
      final receiver = index >= 2 ? tokens[index - 2] : null;
      final hasVerifiedReceiver =
          receiver?.kind == _TokenKind.identifier &&
          allowedQualifiedPrefixes.contains(receiver!.text) &&
          (index < 3 || tokens[index - 3].text != '.');
      if (!hasVerifiedReceiver) continue;
    }
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

/// Finds import prefixes explicitly attached to Flutter UI libraries exposing
/// the framework app root. Other dotted receivers remain excluded.
Set<String> _flutterRunAppPrefixes(String source) {
  const uiLibraries = {
    'package:flutter/widgets.dart',
    'package:flutter/material.dart',
    'package:flutter/cupertino.dart',
  };
  final tokens = _tokens(source);
  final prefixes = <String>{};
  for (var index = 0; index + 1 < tokens.length; index++) {
    if (tokens[index].text != 'import' ||
        tokens[index + 1].kind != _TokenKind.string ||
        !uiLibraries.contains(tokens[index + 1].text)) {
      continue;
    }
    for (
      var cursor = index + 2;
      cursor + 1 < tokens.length && tokens[cursor].text != ';';
      cursor++
    ) {
      if (tokens[cursor].text == 'as' &&
          tokens[cursor + 1].kind == _TokenKind.identifier) {
        prefixes.add(tokens[cursor + 1].text);
        break;
      }
    }
  }
  return prefixes;
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
  const _RiverpodScopeBindings(
    this.unqualified,
    this.qualified, {
    required this.qualifiedAliasShadows,
  });

  final Set<String> unqualified;
  final Map<String, Set<String>> qualified;
  final List<_ScopeShadow> qualifiedAliasShadows;

  bool allowsUnqualified(String constructor, int callOffset) =>
      unqualified.contains(constructor) &&
      !_isShadowedAtCall(constructor, callOffset);

  bool allowsQualified(String alias, String constructor, int callOffset) {
    if (qualified[alias]?.contains(constructor) != true) return false;
    return !_isShadowedAtCall(alias, callOffset);
  }

  bool _isShadowedAtCall(String name, int callOffset) => qualifiedAliasShadows
      .any((shadow) => shadow.name == name && shadow.contains(callOffset));
}

class _ScopeShadow {
  const _ScopeShadow({
    required this.name,
    required this.offset,
    required this.start,
    required this.end,
    this.libraryWide = false,
  });

  const _ScopeShadow.libraryWide({required String name, required int offset})
    : this(name: name, offset: offset, start: 0, end: 0, libraryWide: true);

  final String name;
  final int offset;
  final int start;
  final int end;
  final bool libraryWide;

  bool contains(int callOffset) =>
      libraryWide || (start <= callOffset && callOffset <= end);
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
