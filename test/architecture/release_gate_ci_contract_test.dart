import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _authorityCommand = 'dart run scripts/release_gate.dart';
const _auditWorkflowPath = '.github/workflows/audit.yml';
const _deviceWorkflowPath = '.github/workflows/device-e2e.yml';
const _decisionLedgerPath =
    '.planning/phases/62-automated-release-gate-lock/62-02-SUMMARY.md';
const _reportPath = 'docs/testing/RELEASE_COMPATIBILITY.md';

List<String> _executableLines(String source) => source
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty && !line.startsWith('#'))
    .toList();

String _decisionCode(String prefix) {
  final ledger = File(_decisionLedgerPath);
  if (!ledger.existsSync()) {
    throw StateError(
      'Missing Phase 62 release-owner decision ledger: $_decisionLedgerPath',
    );
  }
  final matches = RegExp(
    '$prefix-(?:A|B|HOLD)',
  ).allMatches(ledger.readAsStringSync());
  final codes = matches.map((match) => match.group(0)!).toSet();
  if (codes.length != 1) {
    throw StateError(
      'Expected exactly one $prefix decision code in 62-02-SUMMARY',
    );
  }
  return codes.single;
}

void main() {
  test('Phase 62 CI routes PR and main through the sole repository authority', () {
    final audit = File(_auditWorkflowPath).readAsStringSync();
    final device = File(_deviceWorkflowPath).readAsStringSync();
    final auditLines = _executableLines(audit);
    final deviceLines = _executableLines(device);

    expect(
      File('scripts/release_gate.dart').existsSync(),
      isTrue,
      reason:
          'Missing Phase 62 release-gate authority: scripts/release_gate.dart',
    );
    expect(
      auditLines,
      contains('pull_request:'),
      reason: 'PR routing is required',
    );
    expect(
      auditLines.where(
        (line) => line == 'run: $_authorityCommand --scope=host',
      ),
      hasLength(1),
      reason: 'PR sampling must call the sole authority once with --scope=host',
    );
    expect(
      deviceLines,
      contains('push:'),
      reason: 'main-merge routing is required',
    );
    expect(
      deviceLines.where(
        (line) => line == 'run: $_authorityCommand --scope=full',
      ),
      hasLength(1),
      reason:
          'every main merge must call the sole authority once with --scope=full',
    );
  });

  test(
    'Phase 62 CI keeps the locked Flutter graph and selected topology explicit',
    () {
      final audit = File(_auditWorkflowPath).readAsStringSync();
      final device = File(_deviceWorkflowPath).readAsStringSync();
      final topology = _decisionCode('CI');

      expect(
        RegExp(
          r'^\s*flutter-version:\s*3\.44\.8\s*$',
          multiLine: true,
        ).allMatches('$audit\n$device'),
        isNotEmpty,
        reason: 'Phase 62 CI must retain the selected Flutter 3.44.8 pin',
      );
      expect(
        '$audit\n$device',
        contains('flutter pub get --enforce-lockfile'),
        reason: 'Phase 62 CI must retain locked dependency retrieval',
      );
      expect(
        topology,
        isNot('CI-HOLD'),
        reason: 'an unselected topology cannot pass',
      );
      expect(
        _executableLines(device),
        contains('PHASE62_CI_TOPOLOGY: $topology'),
        reason:
            'main workflow must declare the owner-selected $topology topology',
      );
    },
  );

  test(
    'Phase 62 marks x86_64 as supplemental evidence, never a mandatory verdict',
    () {
      final workflow = File(_deviceWorkflowPath).readAsStringSync();
      final lines = _executableLines(workflow);

      expect(
        workflow,
        contains(
          'Android Emulator supplemental suite (API 36 x86_64 GitHub/Intel)',
        ),
        reason: 'the x86_64 job must remain visibly supplemental',
      );
      expect(lines, contains('continue-on-error: true'));
      expect(lines, contains('PHASE62_X86_CLASSIFICATION: supplemental'));
      expect(lines, contains('name: release-gate-supplemental-x86'));
      expect(
        workflow,
        isNot(contains('PHASE62_X86_CLASSIFICATION: mandatory')),
        reason: 'x86_64 cannot become a passing mandatory result',
      );
    },
  );

  test('Phase 62 report lifecycle follows the selected exact-path decision', () {
    final source = File('scripts/release_gate.dart');
    final reportDecision = _decisionCode('RPT');
    final contents = source.existsSync() ? source.readAsStringSync() : '';

    expect(
      reportDecision,
      isNot('RPT-HOLD'),
      reason: 'an unselected report lifecycle cannot pass',
    );
    expect(
      contents,
      contains("selectedReportLifecycle = '$reportDecision'"),
      reason:
          'release authority must record the owner-selected $reportDecision lifecycle',
    );
    expect(
      contents,
      contains(_reportPath),
      reason:
          'only the exact compatibility-report path may receive publication handling',
    );
    expect(
      contents,
      contains('candidateScope'),
      reason: 'candidate-scoped changes cannot be hidden by report publication',
    );
    expect(
      contents,
      isNot(contains('allowAnyDirtyPath')),
      reason: 'a broad candidate-drift exclusion is forbidden',
    );
  });
}
