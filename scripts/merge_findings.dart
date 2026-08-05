// scripts/merge_findings.dart
// Reads <root>/{shards,agent-shards}/*.json, dedupes,
// stamps stable IDs, writes <root>/issues.json + <root>/ISSUES.md.
// Default root: .planning/audit (backwards-compatible with Phase 1 invocation).
//
// Usage:
//   dart run scripts/merge_findings.dart                            # baseline (root = .planning/audit)
//   dart run scripts/merge_findings.dart --root <path>              # re-audit (e.g. .planning/audit/re-audit)
//
// Exit codes:
//   0 — merge succeeded
//   2 — invocation error (missing --root value, unknown flag, unexpected arg)

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'audit/finding.dart';

const _categoryPrefix = {
  'layer_violation': 'LV',
  'provider_hygiene': 'PH',
  'dead_code': 'DC',
  'redundant_code': 'RD',
};

/// Only these scanner outputs are fresh, authoritative lifecycle evidence.
/// Agent shards intentionally remain historical context; a stale semantic
/// report must never close or reopen a finding.
const _canonicalShardTools = {
  'layer.json': 'import_guard',
  'dead_code.json': 'dart_code_linter',
  'providers.json': 'owned_provider_contract',
  'duplication.json': 'owned_duplication_detector',
};

const _canonicalShardCategories = {
  'layer.json': 'layer_violation',
  'dead_code.json': 'dead_code',
  'providers.json': 'provider_hygiene',
  'duplication.json': 'redundant_code',
};

const _categories = {
  'layer_violation',
  'provider_hygiene',
  'dead_code',
  'redundant_code',
};
const _severities = {'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'};
const _confidences = {'high', 'medium', 'low'};
const _statuses = {'open', 'closed', 'accepted'};

const _generatedFileGlobs = ['.g.dart', '.freezed.dart', '.mocks.dart'];

const _pairJournalName = '.merge-findings-pair.json';
const _legacyIssuesNextName = '.merge-findings-issues.next';
const _legacyMarkdownNextName = '.merge-findings-markdown.next';
const _legacyIssuesBackupName = '.merge-findings-issues.backup';
const _legacyMarkdownBackupName = '.merge-findings-markdown.backup';
const _pairFailureInjectionEnv = 'AUDIT_MERGE_FAILPOINT';

bool _isGenerated(String path) =>
    _generatedFileGlobs.any(path.endsWith) || path.contains('lib/generated/');

String _resolveRoot(List<String> args) {
  var root = '.planning/audit';
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--root':
        if (i + 1 >= args.length) {
          stderr.writeln(
            '[audit:merge] ERROR: --root requires a path argument',
          );
          exit(2);
        }
        root = args[i + 1];
        i++;
        break;
      default:
        if (a.startsWith('--')) {
          stderr.writeln('[audit:merge] ERROR: unknown flag: $a');
          exit(2);
        }
        stderr.writeln('[audit:merge] ERROR: unexpected positional arg: $a');
        exit(2);
    }
  }
  return root;
}

Future<void> main(List<String> args) async {
  final root = _resolveRoot(args);
  final recoveryError = await _recoverPairTransaction(root);
  if (recoveryError != null) {
    stderr.writeln('[audit:merge] ERROR: $recoveryError');
    exitCode = 1;
    return;
  }
  final history = await _readExistingFindings(root);
  if (history.error != null) {
    stderr.writeln('[audit:merge] ERROR: ${history.error}');
    exitCode = 1;
    return;
  }
  final existingFindings = history.findings;
  final acceptedDuplicationAllowlist = _readDuplicationAllowlist();
  final shards = <Finding>[];
  final incompleteScans = <String>[];
  final completedAuthoritativeTools = <String>{};
  final semanticErrors = <String>[];

  for (final entry in _canonicalShardTools.entries) {
    final shardPath = '$root/shards/${entry.key}';
    final shardFile = File(shardPath);
    if (!shardFile.existsSync()) {
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath (missing required canonical shard)',
      );
      continue;
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(await shardFile.readAsString());
      if (decoded is! Map) throw const FormatException('expected JSON object');
      data = decoded.cast<String, dynamic>();
    } catch (error) {
      stderr.writeln(
        '[audit:merge] WARNING: failed to parse $shardPath: $error',
      );
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath (malformed canonical JSON)',
      );
      continue;
    }

    if (data['tool_source'] != entry.value) {
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath (unexpected tool_source)',
      );
      continue;
    }
    if (data['scan_state'] != 'ran') {
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath was not run successfully (invalid scan_state)',
      );
      continue;
    }
    if (data['scan_failed'] == true) {
      _recordIncompleteScan(incompleteScans, '$shardPath (scan failed)');
      continue;
    }
    final findingsRaw = data['findings'];
    if (findingsRaw is! List) {
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath (missing findings list)',
      );
      continue;
    }

    // A canonical shard is lifecycle evidence only if every finding in it is
    // valid. Accepting its tool identity before validating individual entries
    // would let a truncated/corrupt shard close unrelated historical findings.
    final validatedFindings = <Finding>[];
    var hasMalformedFinding = false;
    for (final findingRaw in findingsRaw) {
      if (findingRaw is! Map) {
        stderr.writeln(
          '[audit:merge] WARNING: malformed finding in $shardPath',
        );
        hasMalformedFinding = true;
        break;
      }
      try {
        final finding = Finding.fromJson(findingRaw.cast<String, dynamic>());
        final semanticError = _validateCanonicalFinding(
          finding,
          expectedToolSource: entry.value,
          expectedCategory: _canonicalShardCategories[entry.key]!,
          acceptedDuplicationAllowlist: acceptedDuplicationAllowlist,
        );
        if (semanticError != null) {
          semanticErrors.add('$shardPath ($semanticError)');
          break;
        }
        validatedFindings.add(finding);
      } catch (error) {
        stderr.writeln(
          '[audit:merge] WARNING: malformed finding in $shardPath: $error',
        );
        hasMalformedFinding = true;
        break;
      }
    }
    if (hasMalformedFinding) {
      _recordIncompleteScan(
        incompleteScans,
        '$shardPath (malformed finding entry)',
      );
      continue;
    }
    if (semanticErrors.isNotEmpty &&
        semanticErrors.last.startsWith('$shardPath (')) {
      continue;
    }

    completedAuthoritativeTools.add(entry.value);
    shards.addAll(validatedFindings);
  }

  // Semantic corruption is a global transaction failure. Unlike a scanner
  // that merely did not run, a shard with an invalid observation cannot be
  // safely merged alongside the valid shards: doing so could write lifecycle
  // transitions while concealing tampered evidence. Leave both outputs byte
  // for byte unchanged until a complete valid input set is available.
  if (semanticErrors.isNotEmpty) {
    for (final error in semanticErrors) {
      stderr.writeln('[audit:merge] ERROR: invalid canonical finding: $error');
    }
    exitCode = 1;
    return;
  }

  // 1. Drop generated-file findings (defense-in-depth — Pitfall P1-6 echo).
  final filtered = shards.where((f) => !_isGenerated(f.filePath)).toList();

  // 2. Dedupe exact candidates — prefer high confidence; tool > agent on tie.
  // Clone relationships can share a file/line while referring to different
  // counterpart files, so collapsing solely by location loses real evidence.
  final byKey = <String, Finding>{};
  for (final f in filtered) {
    final k = _lifecycleKey(f);
    final existing = byKey[k];
    if (existing == null || _isPreferred(f, over: existing)) {
      byKey[k] = f;
    }
  }

  // 3. Sort deterministically: file_path asc, line_start asc, category prefix.
  final sorted = byKey.values.toList()
    ..sort((a, b) {
      final fp = a.filePath.compareTo(b.filePath);
      if (fp != 0) return fp;
      final ln = a.lineStart.compareTo(b.lineStart);
      if (ln != 0) return ln;
      return _categoryPrefix[a.category]!.compareTo(
        _categoryPrefix[b.category]!,
      );
    });

  // 4. Reconcile lifecycle against only successful authoritative observations.
  // Closed/accepted history is retained even when absent. An open finding is
  // resolved only when its own detector completed cleanly; a failed or missing
  // scan is never evidence of a fix.
  final observedExistingIds = sorted
      .map((finding) => _previousFor(finding, existingFindings)?.id)
      .whereType<String>()
      .toSet();
  final retainedHistory = existingFindings.values
      .where(
        (finding) =>
            finding.id == null || !observedExistingIds.contains(finding.id),
      )
      .map((finding) {
        if (finding.status == 'open' &&
            completedAuthoritativeTools.contains(finding.toolSource)) {
          return _withLifecycle(
            finding,
            status: 'closed',
            closedInPhase: 'audit',
          );
        }
        return finding;
      })
      .toList();
  // IDs are permanent for open findings too. Reserve every existing ID before
  // allocating new findings so an inserted shard cannot renumber prior work.
  final reservedIds = existingFindings.values
      .where((f) => f.id != null)
      .map((f) => f.id!)
      .toSet();

  // 5. Stamp IDs per category in sort order, skipping any IDs already
  //    reserved by retained history so the merged catalogue has unique IDs.
  final counters = <String, int>{};
  String nextId(String prefix) {
    while (true) {
      final n = (counters[prefix] = (counters[prefix] ?? 0) + 1);
      final candidate = '$prefix-${n.toString().padLeft(3, '0')}';
      if (!reservedIds.contains(candidate)) return candidate;
    }
  }

  final stamped = sorted.map((f) {
    final prefix = _categoryPrefix[f.category]!;
    final previous = _previousFor(f, existingFindings);
    final isAcceptedObservation = f.status == 'accepted';
    final isReopened =
        previous != null && !isAcceptedObservation && previous.status != 'open';
    return Finding(
      id: previous?.id ?? nextId(prefix),
      category: f.category,
      severity: f.severity,
      filePath: f.filePath,
      lineStart: f.lineStart,
      lineEnd: f.lineEnd,
      description: f.description,
      rationale: f.rationale,
      suggestedFix: f.suggestedFix,
      toolSource: f.toolSource,
      confidence: f.confidence,
      // Exact allowlist entries are accepted observations. Any non-accepted
      // reappearance reopens closed/accepted history, including source drift
      // that invalidates an allowlist fingerprint.
      status: isAcceptedObservation
          ? 'accepted'
          : (isReopened ? 'open' : f.status),
      closedInPhase: isAcceptedObservation || isReopened
          ? null
          : previous?.closedInPhase ?? f.closedInPhase,
      closedCommit: isAcceptedObservation || isReopened
          ? null
          : previous?.closedCommit ?? f.closedCommit,
    );
  }).toList();
  final catalogue = [...stamped, ...retainedHistory]..sort(_compareFindings);

  // 5. Emit issues.json (machine-readable; no top-level timestamp so the
  //    file is byte-identical across re-runs — see merger_findings_test.dart).
  final issuesPath = '$root/issues.json';
  final issuesContent = const JsonEncoder.withIndent(
    '  ',
  ).convert({'findings': catalogue.map((f) => f.toJson()).toList()});

  // Validation above completes before this point. Commit both catalogue views
  // as a durable pair so lifecycle readers never advance from one generation
  // of issues.json and another generation of ISSUES.md.
  final issuesDir = Directory(root);
  if (!issuesDir.existsSync()) issuesDir.createSync(recursive: true);
  final md = _renderMarkdown(catalogue, incompleteScans: incompleteScans);
  try {
    await _writeCataloguePair(root, issuesContent: issuesContent, markdown: md);
  } catch (error) {
    stderr.writeln(
      '[audit:merge] ERROR: failed to commit catalogue pair: $error',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    '[audit:merge] wrote ${catalogue.length} findings to $issuesPath',
  );
  if (incompleteScans.isNotEmpty) exitCode = 1;
}

void _recordIncompleteScan(List<String> incompleteScans, String detail) {
  incompleteScans.add(detail);
  stderr.writeln('[audit:merge] ERROR: $detail');
}

class _ExistingHistory {
  const _ExistingHistory({required this.findings, this.error});

  final Map<String, Finding> findings;
  final String? error;
}

Future<_ExistingHistory> _readExistingFindings(String root) async {
  final file = File('$root/issues.json');
  if (!file.existsSync()) return const _ExistingHistory(findings: {});

  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      return const _ExistingHistory(
        findings: {},
        error: 'existing issues.json must be a JSON object',
      );
    }
    final data = decoded.cast<String, dynamic>();
    final findings = data['findings'];
    if (findings is! List) {
      return const _ExistingHistory(
        findings: {},
        error: 'existing issues.json must contain a findings list',
      );
    }

    final existing = <String, Finding>{};
    final ids = <String>{};
    for (var index = 0; index < findings.length; index++) {
      final entry = findings[index];
      if (entry is! Map) {
        return _ExistingHistory(
          findings: const {},
          error: 'malformed existing finding at index $index',
        );
      }
      try {
        final finding = Finding.fromJson(entry.cast<String, dynamic>());
        final semanticError = _validateHistoricalFinding(finding);
        if (semanticError != null) {
          return _ExistingHistory(
            findings: const {},
            error: 'invalid existing finding at index $index ($semanticError)',
          );
        }
        if (!ids.add(finding.id!)) {
          return _ExistingHistory(
            findings: const {},
            error: 'duplicate existing finding ID: ${finding.id}',
          );
        }
        final lifecycleKey = _lifecycleKey(finding);
        if (existing.containsKey(lifecycleKey)) {
          return _ExistingHistory(
            findings: const {},
            error: 'duplicate existing finding lifecycle key at index $index',
          );
        }
        existing[lifecycleKey] = finding;
      } catch (error) {
        return _ExistingHistory(
          findings: const {},
          error: 'malformed existing finding at index $index: $error',
        );
      }
    }
    return _ExistingHistory(findings: existing);
  } catch (e) {
    return _ExistingHistory(
      findings: const {},
      error: 'failed to read existing lifecycle metadata: $e',
    );
  }
}

String? _validateCanonicalFinding(
  Finding finding, {
  required String expectedToolSource,
  required String expectedCategory,
  required Set<String> acceptedDuplicationAllowlist,
}) {
  final commonError = _validateCommonFinding(finding);
  if (commonError != null) return commonError;
  if (finding.id != null) return 'raw scanner finding must not include an ID';
  if (finding.toolSource != expectedToolSource) {
    return 'tool_source must be $expectedToolSource';
  }
  if (finding.category != expectedCategory) {
    return 'category must be $expectedCategory';
  }
  if (finding.status == 'open') return null;
  if (finding.status == 'accepted' &&
      _isExactAcceptedDuplication(finding, acceptedDuplicationAllowlist)) {
    return null;
  }
  return 'scanner observation status must be open'
      ' (except an exact duplication allowlist acceptance)';
}

String? _validateHistoricalFinding(Finding finding) {
  final commonError = _validateCommonFinding(finding);
  if (commonError != null) return commonError;
  if (finding.id == null || !_hasValidFindingId(finding)) {
    return 'missing or invalid permanent finding ID';
  }
  if (!_statuses.contains(finding.status)) return 'invalid status';
  if (!_isMeaningful(finding.toolSource)) return 'empty tool_source';
  return null;
}

String? _validateCommonFinding(Finding finding) {
  if (!_categories.contains(finding.category)) return 'invalid category';
  if (!_severities.contains(finding.severity)) return 'invalid severity';
  if (!_confidences.contains(finding.confidence)) return 'invalid confidence';
  if (!_isSafeRepoRelativePath(finding.filePath)) {
    return 'file_path must be a safe repo-relative path';
  }
  if (finding.lineStart < 1 || finding.lineEnd < finding.lineStart) {
    return 'line range must start at 1 or later and not be inverted';
  }
  if (!_isMeaningful(finding.description) ||
      !_isMeaningful(finding.rationale) ||
      !_isMeaningful(finding.suggestedFix)) {
    return 'description, rationale, and suggested_fix must be nonempty';
  }
  return null;
}

bool _hasValidFindingId(Finding finding) {
  final expectedPrefix = _categoryPrefix[finding.category];
  return expectedPrefix != null &&
      RegExp(
        '^${RegExp.escape(expectedPrefix)}-[0-9]{3,}\$',
      ).hasMatch(finding.id!);
}

bool _isSafeRepoRelativePath(String path) {
  if (!_isMeaningful(path) ||
      path != path.trim() ||
      path.contains('\u0000') ||
      path.startsWith('/') ||
      path.startsWith('\\\\') ||
      path.contains('\\')) {
    return false;
  }
  if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return false;
  final segments = path.split('/');
  return segments.every(
    (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
  );
}

bool _isMeaningful(String value) => value.trim().isNotEmpty;

Set<String> _readDuplicationAllowlist() {
  final file = File('.planning/audit/duplication_allowlist.json');
  if (!file.existsSync()) return const {};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map || decoded['accepted'] is! List) return const {};
    return {
      for (final entry in (decoded['accepted'] as List))
        if (entry is Map &&
            entry['files'] is List &&
            (entry['files'] as List).length == 2 &&
            (entry['files'] as List).every((file) => file is String) &&
            entry['fingerprint'] is String &&
            entry['rationale'] is String)
          _duplicationAllowlistKey(
            (entry['files'] as List).cast<String>(),
            entry['fingerprint'] as String,
            entry['rationale'] as String,
          ),
    };
  } catch (_) {
    return const {};
  }
}

bool _isExactAcceptedDuplication(
  Finding finding,
  Set<String> acceptedDuplicationAllowlist,
) {
  if (finding.toolSource != 'owned_duplication_detector' ||
      finding.category != 'redundant_code') {
    return false;
  }
  final counterpart = _cloneCounterpart(finding);
  final fingerprint = RegExp(
    r'Fingerprint: ([0-9a-f]{16})\.$',
  ).firstMatch(finding.rationale);
  if (counterpart == null || fingerprint == null) return false;
  final prefix = 'Accepted duplicate clone: ';
  if (!finding.rationale.startsWith(prefix)) return false;
  final rationale = finding.rationale.substring(
    prefix.length,
    finding.rationale.length - ' Fingerprint: ${fingerprint[1]}.'.length,
  );
  return acceptedDuplicationAllowlist.contains(
    _duplicationAllowlistKey(
      [finding.filePath, counterpart],
      fingerprint[1]!,
      rationale,
    ),
  );
}

String _duplicationAllowlistKey(
  List<String> files,
  String fingerprint,
  String rationale,
) {
  final sortedFiles = [...files]..sort();
  return '${sortedFiles.join('|')}|$fingerprint|$rationale';
}

class _PairFile {
  const _PairFile({
    required this.targetName,
    required this.nextName,
    required this.backupName,
    required this.oldExists,
    required this.oldDigest,
    required this.newDigest,
  });

  final String targetName;
  final String nextName;
  final String backupName;
  final bool oldExists;
  final String? oldDigest;
  final String newDigest;

  Map<String, Object?> toJson() => {
    'target': targetName,
    'next': nextName,
    'backup': backupName,
    'old_exists': oldExists,
    'old_digest': oldDigest,
    'new_digest': newDigest,
  };

  static _PairFile? fromJson(Object? value, {required String targetName}) {
    if (value is! Map) return null;
    final data = value.cast<String, dynamic>();
    final oldExists = data['old_exists'];
    final oldDigest = data['old_digest'];
    final newDigest = data['new_digest'];
    final nextName = data['next'];
    final backupName = data['backup'];
    if (data['target'] != targetName ||
        nextName is! String ||
        backupName is! String ||
        !_isStageArtifactName(nextName, targetName, 'next') ||
        !_isStageArtifactName(backupName, targetName, 'backup') ||
        nextName == backupName ||
        oldExists is! bool ||
        newDigest is! String ||
        !_isDigest(newDigest) ||
        (oldExists && (oldDigest is! String || !_isDigest(oldDigest))) ||
        (!oldExists && oldDigest != null)) {
      return null;
    }
    return _PairFile(
      targetName: targetName,
      nextName: nextName,
      backupName: backupName,
      oldExists: oldExists,
      oldDigest: oldDigest as String?,
      newDigest: newDigest,
    );
  }
}

class _PairTransaction {
  const _PairTransaction({
    required this.state,
    required this.issues,
    required this.markdown,
  });

  final String state;
  final _PairFile issues;
  final _PairFile markdown;

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'state': state,
    'issues': issues.toJson(),
    'markdown': markdown.toJson(),
  };

  _PairTransaction withState(String value) =>
      _PairTransaction(state: value, issues: issues, markdown: markdown);

  static _PairTransaction? fromJson(Object? value) {
    if (value is! Map) return null;
    final data = value.cast<String, dynamic>();
    final state = data['state'];
    if (data['schema_version'] != 1 ||
        state is! String ||
        !{
          'prepared',
          'json_replaced',
          'markdown_replaced',
          'committed_new',
          'committed_old',
        }.contains(state)) {
      return null;
    }
    final issues = _PairFile.fromJson(
      data['issues'],
      targetName: 'issues.json',
    );
    final markdown = _PairFile.fromJson(
      data['markdown'],
      targetName: 'ISSUES.md',
    );
    if (issues == null || markdown == null) return null;
    return _PairTransaction(state: state, issues: issues, markdown: markdown);
  }
}

bool _isDigest(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

String _digest(List<int> bytes) => sha256.convert(bytes).toString();

String _transactionPath(String root, String name) => '$root/$name';

Future<List<int>?> _readBytesIfPresent(File file) async =>
    file.existsSync() ? file.readAsBytes() : null;

Future<bool> _matchesDigest(File file, String digest) async {
  final bytes = await _readBytesIfPresent(file);
  return bytes != null && _digest(bytes) == digest;
}

Future<void> _writeBytesDurably(File file, List<int> bytes) =>
    file.writeAsBytes(bytes, flush: true);

String _newArtifactName(String targetName, String kind) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final random = Random.secure().nextInt(1 << 32);
  final encodedTarget = targetName == 'issues.json' ? 'issues' : 'markdown';
  return '.merge-findings-tmp-$stamp-$random-$encodedTarget-$kind';
}

bool _isStageArtifactName(String name, String targetName, String kind) {
  final encodedTarget = targetName == 'issues.json' ? 'issues' : 'markdown';
  return RegExp(
    '^\\.merge-findings-tmp-[0-9]+-[0-9]+-$encodedTarget-$kind\$',
  ).hasMatch(name);
}

bool _isTransientArtifactName(String name) => RegExp(
  r'^\.merge-findings-tmp-[0-9]+-[0-9]+-(?:issues|markdown)-(?:next|backup|journal)$',
).hasMatch(name);

Future<void> _writeJournal(String root, _PairTransaction transaction) async {
  final journal = File(_transactionPath(root, _pairJournalName));
  final temp = File(
    _transactionPath(root, _newArtifactName('issues.json', 'journal')),
  );
  try {
    await _writeBytesDurably(
      temp,
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(transaction.toJson()),
      ),
    );
    _injectFailure('journal_before_rename_${transaction.state}');
    await _replaceFrom(temp, journal);
    _injectFailure('journal_after_rename_${transaction.state}');
  } finally {
    if (temp.existsSync()) await temp.delete();
  }
}

Future<void> _replaceFrom(File source, File destination) async {
  await source.rename(destination.path);
}

Future<void> _replaceWithBytes(File destination, List<int> bytes) async {
  final restore = File('${destination.path}.restore');
  try {
    await _writeBytesDurably(restore, bytes);
    await _replaceFrom(restore, destination);
  } finally {
    if (restore.existsSync()) await restore.delete();
  }
}

Future<void> _deleteIfPresent(File file) async {
  if (file.existsSync()) await file.delete();
}

void _injectFailure(String point) {
  if (Platform.environment[_pairFailureInjectionEnv] == point) {
    stderr.writeln('[audit:merge] injected interruption at $point');
    exit(91);
  }
}

Future<String?> _recoverPairTransaction(String root) async {
  final journal = File(_transactionPath(root, _pairJournalName));
  if (!journal.existsSync()) {
    await _cleanupUnjournaledTransientArtifacts(root);
    return null;
  }

  _PairTransaction transaction;
  try {
    transaction =
        _PairTransaction.fromJson(jsonDecode(await journal.readAsString())) ??
        (throw const FormatException('invalid transaction schema'));
  } catch (error) {
    return 'pair transaction journal is corrupt; refusing to overwrite catalogue outputs ($error)';
  }

  if (transaction.state == 'committed_new' ||
      transaction.state == 'committed_old') {
    final expected = transaction.state == 'committed_new' ? 'new' : 'old';
    if (!await _pairMatches(root, transaction, version: expected)) {
      return 'terminal pair transaction journal does not match its committed generation; refusing to overwrite catalogue outputs';
    }
    await _cleanupTransactionFiles(root, transaction);
    return null;
  }

  final validationError = await _validateTransactionFiles(root, transaction);
  if (validationError != null) {
    return 'pair transaction journal cannot be recovered; refusing to overwrite catalogue outputs ($validationError)';
  }

  final issuesVersion = await _versionOf(root, transaction.issues);
  final markdownVersion = await _versionOf(root, transaction.markdown);
  if (issuesVersion == null || markdownVersion == null) {
    return 'pair transaction outputs do not match their recorded old or new digests; refusing to overwrite catalogue outputs';
  }

  if (issuesVersion != 'new' || markdownVersion != 'new') {
    final canComplete =
        await _canCompleteNewPair(root, transaction.issues, issuesVersion) &&
        await _canCompleteNewPair(root, transaction.markdown, markdownVersion);
    if (canComplete) {
      await _finishNewPair(root, transaction.issues, issuesVersion);
      await _writeJournal(root, transaction.withState('json_replaced'));
      await _finishNewPair(root, transaction.markdown, markdownVersion);
    } else {
      await _restoreOldPair(root, transaction.issues);
      await _writeJournal(root, transaction.withState('json_replaced'));
      await _restoreOldPair(root, transaction.markdown);
    }
  }

  final recoveredIssuesVersion = await _versionOf(root, transaction.issues);
  final recoveredMarkdownVersion = await _versionOf(root, transaction.markdown);
  final recoveredNew =
      recoveredIssuesVersion == 'new' && recoveredMarkdownVersion == 'new';
  final recoveredOld =
      recoveredIssuesVersion == 'old' && recoveredMarkdownVersion == 'old';
  if (!recoveredNew && !recoveredOld) {
    return 'pair transaction recovery left mixed catalogue generations; refusing to continue';
  }
  final expected = recoveredNew ? 'new' : 'old';
  if (!await _pairMatches(root, transaction, version: expected)) {
    return 'pair transaction recovery verification failed; refusing to continue';
  }
  await _writeJournal(
    root,
    transaction.withState(recoveredNew ? 'committed_new' : 'committed_old'),
  );
  await _cleanupTransactionFiles(root, transaction);
  return null;
}

Future<String?> _validateTransactionFiles(
  String root,
  _PairTransaction transaction,
) async {
  for (final file in [transaction.issues, transaction.markdown]) {
    if (file.oldExists &&
        !await _matchesDigest(
          File(_transactionPath(root, file.backupName)),
          file.oldDigest!,
        )) {
      return 'backup for ${file.targetName} is missing or has the wrong digest';
    }
  }
  return null;
}

Future<String?> _versionOf(String root, _PairFile file) async {
  final target = File(_transactionPath(root, file.targetName));
  final bytes = await _readBytesIfPresent(target);
  if (bytes == null) return file.oldExists ? null : 'old';
  final digest = _digest(bytes);
  if (digest == file.newDigest) return 'new';
  if (file.oldExists && digest == file.oldDigest) return 'old';
  return null;
}

Future<bool> _canCompleteNewPair(
  String root,
  _PairFile file,
  String currentVersion,
) async =>
    currentVersion == 'new' ||
    await _matchesDigest(
      File(_transactionPath(root, file.nextName)),
      file.newDigest,
    );

Future<void> _finishNewPair(
  String root,
  _PairFile file,
  String currentVersion,
) async {
  if (currentVersion == 'new') return;
  await _replaceFrom(
    File(_transactionPath(root, file.nextName)),
    File(_transactionPath(root, file.targetName)),
  );
}

Future<void> _restoreOldPair(String root, _PairFile file) async {
  final target = File(_transactionPath(root, file.targetName));
  if (!file.oldExists) {
    await _deleteIfPresent(target);
    return;
  }
  final bytes = await File(
    _transactionPath(root, file.backupName),
  ).readAsBytes();
  await _replaceWithBytes(target, bytes);
}

Future<bool> _pairMatches(
  String root,
  _PairTransaction transaction, {
  required String version,
}) async {
  for (final file in [transaction.issues, transaction.markdown]) {
    final target = File(_transactionPath(root, file.targetName));
    if (version == 'new') {
      if (!await _matchesDigest(target, file.newDigest)) return false;
    } else if (file.oldExists) {
      if (!await _matchesDigest(target, file.oldDigest!)) return false;
    } else if (target.existsSync()) {
      return false;
    }
  }
  return true;
}

Future<void> _cleanupTransactionFiles(
  String root,
  _PairTransaction transaction,
) async {
  final entries = [
    ('issues_next', transaction.issues.nextName),
    ('markdown_next', transaction.markdown.nextName),
    ('issues_backup', transaction.issues.backupName),
    ('markdown_backup', transaction.markdown.backupName),
  ];
  for (final entry in entries) {
    await _deleteIfPresent(File(_transactionPath(root, entry.$2)));
    _injectFailure('cleanup_after_${entry.$1}');
  }
  await _deleteIfPresent(File(_transactionPath(root, _pairJournalName)));
  _injectFailure('cleanup_after_journal');
  await _cleanupUnjournaledTransientArtifacts(root);
}

Future<void> _cleanupUnjournaledTransientArtifacts(String root) async {
  final directory = Directory(root);
  if (!directory.existsSync()) return;
  for (final entity in await directory.list().toList()) {
    if (entity is File &&
        _isTransientArtifactName(entity.uri.pathSegments.last)) {
      await _deleteIfPresent(entity);
    }
  }
}

Future<void> _writeCataloguePair(
  String root, {
  required String issuesContent,
  required String markdown,
}) async {
  final orphanError = _orphanedTransactionArtifactError(root);
  if (orphanError != null) throw StateError(orphanError);

  late final _PairFile issues;
  late final _PairFile markdownFile;
  try {
    issues = await _preparePairFile(
      root,
      targetName: 'issues.json',
      content: utf8.encode(issuesContent),
    );
    markdownFile = await _preparePairFile(
      root,
      targetName: 'ISSUES.md',
      content: utf8.encode(markdown),
    );
  } catch (_) {
    // No journal exists yet, so these files cannot be recovered on a future
    // invocation. Remove only the transaction artifacts we created.
    await _cleanupUnjournaledTransientArtifacts(root);
    rethrow;
  }
  final transaction = _PairTransaction(
    state: 'prepared',
    issues: issues,
    markdown: markdownFile,
  );
  _injectFailure('before_journal_publish');
  await _writeJournal(root, transaction);
  _injectFailure('before_first_replace');
  await _finishNewPair(root, issues, 'old');
  await _writeJournal(root, transaction.withState('json_replaced'));
  _injectFailure('after_json_replace');
  await _finishNewPair(root, markdownFile, 'old');
  await _writeJournal(root, transaction.withState('markdown_replaced'));
  if (!await _pairMatches(root, transaction, version: 'new')) {
    throw const FileSystemException('pair commit verification failed');
  }
  await _writeJournal(root, transaction.withState('committed_new'));
  _injectFailure('after_committed_new_journal');
  await _cleanupTransactionFiles(root, transaction);
}

Future<_PairFile> _preparePairFile(
  String root, {
  required String targetName,
  required List<int> content,
}) async {
  final target = File(_transactionPath(root, targetName));
  final previous = await _readBytesIfPresent(target);
  final nextName = _newArtifactName(targetName, 'next');
  final backupName = _newArtifactName(targetName, 'backup');
  final next = File(_transactionPath(root, nextName));
  await _writeBytesDurably(next, content);
  _injectFailure(
    'prepare_${targetName == 'issues.json' ? 'issues' : 'markdown'}_next',
  );
  if (!await _matchesDigest(next, _digest(content))) {
    throw FileSystemException('could not verify prepared $nextName');
  }
  if (previous != null) {
    final backup = File(_transactionPath(root, backupName));
    await _writeBytesDurably(backup, previous);
    _injectFailure(
      'prepare_${targetName == 'issues.json' ? 'issues' : 'markdown'}_backup',
    );
    if (!await _matchesDigest(backup, _digest(previous))) {
      throw FileSystemException('could not verify backup $backupName');
    }
  }
  return _PairFile(
    targetName: targetName,
    nextName: nextName,
    backupName: backupName,
    oldExists: previous != null,
    oldDigest: previous == null ? null : _digest(previous),
    newDigest: _digest(content),
  );
}

String? _orphanedTransactionArtifactError(String root) {
  for (final name in [
    _legacyIssuesNextName,
    _legacyMarkdownNextName,
    _legacyIssuesBackupName,
    _legacyMarkdownBackupName,
  ]) {
    if (File(_transactionPath(root, name)).existsSync()) {
      return 'orphaned pair transaction artifact $name without a journal';
    }
  }
  return null;
}

String _lifecycleKey(Finding finding) =>
    '${finding.category}|${finding.filePath}|${finding.lineStart}|${finding.description}';

Finding? _previousFor(Finding incoming, Map<String, Finding> existing) {
  final exact = existing[_lifecycleKey(incoming)];
  if (exact != null) return exact;
  if (incoming.toolSource != 'owned_duplication_detector') return null;

  final counterpart = _cloneCounterpart(incoming);
  if (counterpart == null) return null;
  final candidates = existing.values
      .where(
        (existingFinding) =>
            existingFinding.toolSource == 'owned_duplication_detector' &&
            existingFinding.filePath == incoming.filePath &&
            _cloneCounterpart(existingFinding) == counterpart,
      )
      .toList();
  if (candidates.isEmpty) return null;

  // A same-line candidate is the same clone after source drift, including a
  // changed fingerprint. Historical detector records lack fingerprints, so a
  // sole pair candidate remains the stable ID when window clustering corrects
  // its start line.
  for (final candidate in candidates) {
    if (candidate.lineStart == incoming.lineStart) return candidate;
  }
  if (candidates.length == 1 && !_hasFingerprint(candidates.single)) {
    return candidates.single;
  }
  return null;
}

String? _cloneCounterpart(Finding finding) {
  final match = RegExp(
    r'also appears at ([^:]+):\d+\.$',
  ).firstMatch(finding.description);
  return match?[1];
}

bool _hasFingerprint(Finding finding) =>
    finding.rationale.contains('Fingerprint:');

Finding _withLifecycle(
  Finding finding, {
  required String status,
  String? closedInPhase,
}) => Finding(
  id: finding.id,
  category: finding.category,
  severity: finding.severity,
  filePath: finding.filePath,
  lineStart: finding.lineStart,
  lineEnd: finding.lineEnd,
  description: finding.description,
  rationale: finding.rationale,
  suggestedFix: finding.suggestedFix,
  toolSource: finding.toolSource,
  confidence: finding.confidence,
  status: status,
  closedInPhase: closedInPhase,
);

int _compareFindings(Finding a, Finding b) {
  final fp = a.filePath.compareTo(b.filePath);
  if (fp != 0) return fp;
  final ln = a.lineStart.compareTo(b.lineStart);
  if (ln != 0) return ln;
  return _categoryPrefix[a.category]!.compareTo(_categoryPrefix[b.category]!);
}

bool _isPreferred(Finding a, {required Finding over}) {
  // Higher-confidence wins; tie-broken by preferring tool_source over agent:*
  const order = {'high': 3, 'medium': 2, 'low': 1};
  final aRank = order[a.confidence] ?? 0;
  final overRank = order[over.confidence] ?? 0;
  if (aRank > overRank) return true;
  if (aRank < overRank) return false;
  final aIsAgent = a.toolSource.startsWith('agent:');
  final overIsAgent = over.toolSource.startsWith('agent:');
  if (!aIsAgent && overIsAgent) return true;
  return false;
}

String _renderMarkdown(
  List<Finding> findings, {
  List<String> incompleteScans = const [],
}) {
  final buf = StringBuffer();
  final active = findings.where((f) => f.status == 'open').toList();
  final resolved = findings.where((f) => f.status == 'closed').toList();
  final accepted = findings.where((f) => f.status == 'accepted').toList();
  buf.writeln('# Audit Findings');
  buf.writeln();
  buf.writeln('**Total findings:** ${findings.length}');
  buf.writeln('**Active findings:** ${active.length}');
  buf.writeln('**Resolved findings:** ${resolved.length}');
  buf.writeln('**Accepted findings:** ${accepted.length}');
  buf.writeln();

  if (incompleteScans.isNotEmpty) {
    buf.writeln('## Scan Status: INCOMPLETE');
    buf.writeln();
    buf.writeln(
      'The following scanner shards were not run successfully; this report must not be interpreted as a clean audit:',
    );
    for (final scan in incompleteScans) {
      buf.writeln('- `$scan`');
    }
    buf.writeln();
  }

  const severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
  const categoryLabels = {
    'layer_violation': 'Layer Violations',
    'provider_hygiene': 'Provider Hygiene',
    'dead_code': 'Dead Code',
    'redundant_code': 'Redundant Code',
  };
  const categoryOrder = [
    'layer_violation',
    'provider_hygiene',
    'dead_code',
    'redundant_code',
  ];

  void renderCatalogue(String title, List<Finding> catalogue) {
    buf.writeln('## $title');
    buf.writeln();
    for (final sev in severities) {
      final inSev = catalogue.where((f) => f.severity == sev).toList();
      if (inSev.isEmpty) continue;
      buf.writeln('### $sev');
      buf.writeln();
      for (final cat in categoryOrder) {
        final inCat = inSev.where((f) => f.category == cat).toList();
        if (inCat.isEmpty) continue;
        buf.writeln('#### ${categoryLabels[cat]}');
        buf.writeln();
        buf.writeln(
          '| ID | File:Line | Description | Suggested Fix | tool_source |',
        );
        buf.writeln(
          '|----|-----------|-------------|---------------|-------------|',
        );
        for (final f in inCat) {
          buf.writeln(
            '| ${f.id} | ${f.filePath}:${f.lineStart} | ${_md(f.description)} | ${_md(f.suggestedFix)} | ${f.toolSource} |',
          );
        }
        buf.writeln();
      }
    }
  }

  renderCatalogue('Active Findings', active);
  renderCatalogue('Resolved Findings', resolved);
  renderCatalogue('Accepted Findings', accepted);

  return buf.toString();
}

String _md(String s) => s.replaceAll('|', r'\|').replaceAll('\n', ' ');
