# Phase 62: Automated Release-Gate Lock - Pattern Map

**Mapped:** 2026-08-10  
**Files analyzed:** 7 planned files (plus one optional manifest)  
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/release_gate.dart` | service / CLI orchestrator | batch, event-driven | `scripts/verify_android_safety_lane.dart` | exact role + orchestration flow |
| `test/scripts/release_gate_test.dart` | test | transform, batch | `test/scripts/release_preflight_test.dart` | role-match |
| `test/architecture/release_gate_ci_contract_test.dart` | test | transform | `test/architecture/codegen_reproducibility_contract_test.dart` | exact contract-test role |
| `.github/workflows/audit.yml` | config / CI | request-response | `.github/workflows/audit.yml` (existing jobs) | modification of existing pattern |
| `.github/workflows/device-e2e.yml` | config / CI | event-driven | `.github/workflows/device-e2e.yml` (existing jobs) | modification of existing pattern |
| `docs/testing/RELEASE_COMPATIBILITY.md` | report / documentation | transform | Phase 61 embedded evidence renderer in `scripts/verify_android_safety_lane.dart` | partial: output is Markdown, source is a Dart renderer |
| `scripts/release_gate/expected_skips.json` (name/location at planner discretion) | config / manifest | transform | `docs/testing/STABLE_BASELINE.json` + integration matrix validation | role/data-flow match |
| `build/release_gate/` raw JSON/checkpoints (ignored output, not committed) | generated evidence artifact | file-I/O, batch | `build/native_safety_evidence.json` from `scripts/verify_ios_native_safety_lane.dart` | exact artifact pattern |

The recommended `scripts/release_gate/` module directory is discretionary. Keep pure types, candidate snapshotting, retry classification, sanitization, and Markdown rendering in that directory only if splitting `scripts/release_gate.dart` improves testability; do not create a second executable authority.

## Pattern Assignments

### `scripts/release_gate.dart` (service / CLI orchestrator, batch + event-driven)

**Analog:** `scripts/verify_android_safety_lane.dart`

Use a standalone Dart `library;` script with only `dart:*` imports and the existing `package:crypto` direct dependency. Model options and machine-readable result records as immutable classes/enums; parse arguments strictly and exit nonzero on any unknown/duplicate/invalid option.

**Imports and result-model pattern** (`scripts/verify_android_safety_lane.dart:1-13,53-103`):

```dart
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum AndroidSafetyMode { verify, candidateProbe, release, emulator }

class AndroidSafetyOptions {
  const AndroidSafetyOptions({
    required this.mode,
    required this.allowNotRun,
    required this.prepareOnly,
  });
```

**Strict CLI and top-level failure boundary** (`scripts/verify_android_safety_lane.dart:65-153`):

```dart
for (final argument in arguments) {
  if (argument.startsWith('--mode=')) {
    if (mode != null) throw ArgumentError('mode supplied more than once');
    mode = switch (argument.substring('--mode='.length)) {
      'verify' => AndroidSafetyMode.verify,
      'candidate-probe' => AndroidSafetyMode.candidateProbe,
      'release' => AndroidSafetyMode.release,
      'emulator' => AndroidSafetyMode.emulator,
      _ => throw ArgumentError('unknown Android safety mode'),
    };
  } else {
    throw ArgumentError('unknown argument: $argument');
  }
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseAndroidSafetyOptions(arguments);
    // Dispatch exactly one release-lock graph from here.
  } on Object catch (error) {
    stderr.writeln('ERROR: $error');
    exitCode = 2;
  }
}
```

**Candidate identity and non-mutating status proof** (`scripts/verify_ios_native_safety_lane.dart:813-831`):

```dart
Future<String> _statusSnapshot() async {
  final status = await _run('git', <String>['status', '--short']);
  if (status.exitCode != 0) {
    throw const _RunnerFailure('cannot snapshot repository status');
  }
  return status.stdout.toString();
}

Future<void> _assertStatusRestored() async {
  final after = await _statusSnapshot();
  if (_beforeStatus != after) {
    throw const _RunnerFailure(
      'main-tree status changed during native safety run',
    );
  }
}

String _statusDigest(String status) =>
    sha256.convert(utf8.encode(status)).toString();
```

Extend the snapshot to include `HEAD`, `pubspec.lock`, the selected native/toolchain inputs, and an allowlisted environment fingerprint. Compare it before resume, before irreversible stages, and after the final post-device preflight. A mismatch is terminal `BLOCKED`, never retryable.

**Bounded command/process pattern** (`scripts/verify_ios_native_safety_lane.dart:780-810`):

```dart
process = await Process.start(
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
```

Use this adapter for lower-level scripts and Flutter invocations. Preserve a bounded, already-scrubbed diagnostic and raw-attempt metadata for both the original result and the one allowed infrastructure retry. Do not use shell interpolation for commands.

**Recursive discovery/executed-set proof** (`scripts/verify_android_safety_lane.dart:1243-1301`):

```dart
final files = discoverIntegrationTestFiles(
  Directory('${root.path}/integration_test'),
);
if (files.isEmpty) {
  throw StateError('no integration_test files were discovered');
}
for (final file in files) {
  final command = await runBoundedCommand(
    '$flutterRoot/bin/flutter',
    ['test', 'integration_test/$file', '-d', session.serial, '-r', 'expanded'],
    workingDirectory: root,
    environment: environment,
    timeout: const Duration(minutes: 30),
    durableCommand:
        'flutter test integration_test/$file -d <emulator-redacted> -r expanded',
  );
  records.add({'file': file, 'exit_code': command.exitCode});
}
final issues = validatePrimaryIntegrationMatrix(files, records);
if (issues.isNotEmpty) throw StateError(issues.join('; '));
```

Retain recursive discovery, canonical relative paths, an empty-set failure, and the equality proof `discovered == executed + explicitly allowlisted skips` on both platforms. The iOS Phase 60 hard-coded two-test allowlist (`scripts/verify_ios_native_safety_lane.dart:35-39`) is not an analog for Phase 62 execution scope.

**Privacy-safe JSON evidence pattern** (`scripts/verify_ios_native_safety_lane.dart:833-881` and `scripts/verify_android_safety_lane.dart:850-862`):

```dart
final payload = <String, Object?>{
  'started_at_utc': _startedAt.toIso8601String(),
  'source_commit': _sourceCommit,
  'status_digest_redacted': _beforeStatus == null
      ? null
      : _statusDigest(_beforeStatus!),
  'outcome': _firstFailure != null ? 'FAIL' : 'PASS',
  'records': _records.map((_RunRecord record) => record.toJson()).toList(),
};
await evidence.writeAsString(
  const JsonEncoder.withIndent('  ').convert(payload),
);

var scrubbed = raw
    .replaceAll(RegExp(r'/Users/[^\s]+'), '<local-path>')
    .replaceAll(RegExp(r'/private/(?:tmp|var)/[^\s]+'), '<temp-path>')
    .replaceAll(RegExp(r'emulator-\d{4}'), '<emulator-redacted>');
```

Phase 62 must improve this to allowlisted collection: never place signing material, credentials, serial/UDID, home paths, financial data, notes, backups, or sync payloads in a result object. Run a reject-list privacy scan over JSON and rendered Markdown before writing either. Use `PASS`, `PASS_WITH_LIMITATIONS`, and `BLOCKED` as typed verdict values computed after mandatory-gate and schema checks.

**Reuse rather than reimplement lower-level stages:** invoke `bash scripts/verify_codegen_reproducibility.sh` (its ordered contract is at `scripts/verify_codegen_reproducibility.sh:53-77`), the cleaned-LCOV `scripts/coverage_gate.dart` interface, `bash scripts/release_preflight.sh`, and the platform lane mechanics. The release gate owns ordering, retries, checkpoint validity, verdict, and evidence—not duplicate dependency or native scans.

---

### `test/scripts/release_gate_test.dart` (test, transform + batch)

**Analog:** `test/scripts/release_preflight_test.dart`

Use `flutter_test`, real temporary filesystem fixtures, and `Process.run` only for small, deterministic fixture paths. Do not boot simulators/emulators from unit tests; inject command results/process adapters into pure runner functions instead.

**Fixture/process helper pattern** (`test/scripts/release_preflight_test.dart:1-31`):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/release_preflight.sh';

Future<ProcessResult> _runScript(
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.run('bash', [
    _scriptPath,
    ...arguments,
  ], workingDirectory: workingDirectory ?? Directory.current.path);
}
```

**Temporary isolated fixture and cleanup pattern** (`test/scripts/release_preflight_test.dart:76-109`):

```dart
final fixture = await Directory.systemTemp.createTemp(
  'release-preflight-manifest-',
);
addTearDown(() => fixture.delete(recursive: true));
final input = File('${fixture.path}/pubspec.yaml');
await input.writeAsString('''
name: fixture
dev_dependencies:
  integration_test:
    sdk: flutter
''');
```

Cover candidate snapshot mismatch/dirty status; prerequisite fail-fast; one-and-only-one retry for closed infrastructure categories; timeout diagnosis then complete serial confirmation; checkpoint invalidation; skip-manifest schema and exact discovery accounting; mandatory-vs-supplemental verdict mutations; JSON/Markdown privacy rejects; and post-run drift failure. Test the renderer from synthetic normalized results, not real logs.

---

### `test/architecture/release_gate_ci_contract_test.dart` (architecture test, transform)

**Analog:** `test/architecture/codegen_reproducibility_contract_test.dart`

Read scripts/workflows as source text, strip comments where ordering/counts matter, and mutation-test contract violations. This is the appropriate enforcement seam for D-01 and D-11—not an end-to-end device test.

**Executable-source normalization and exact-step helper** (`test/architecture/codegen_reproducibility_contract_test.dart:5-26`):

```dart
List<String> _executableLines(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

int _onlyIndexOf(String source, String value) {
  expect(
    RegExp(RegExp.escape(value)).allMatches(source),
    hasLength(1),
    reason: '$value must appear exactly once as an executable contract step',
  );
  return source.indexOf(value);
}
```

**Ordering and negative-mutation pattern** (`test/architecture/codegen_reproducibility_contract_test.dart:120-144,226-259`):

```dart
if (analyzer < pass2Diff || importLint < analyzer) {
  violations.add('quality gates must run once after the second clean pass');
}
if (executable.contains('|| true')) {
  violations.add('no command may swallow a failing exit status');
}

expect(_twoPassContractViolations(source), isEmpty);
expect(
  _twoPassContractViolations(source.replaceFirst(buildRunner, shortenedBuildRunner)),
  isNotEmpty,
  reason: 'pass 1 must use the complete conflict-deleting command',
);
```

Assert every Phase 62 workflow path invokes `dart run scripts/release_gate.dart` (or the single selected spelling) and does not reproduce an independently authoritative command graph. Assert PR fast-gate routing, `main` dual-device routing, locked Flutter acquisition, supplemental x86 classification, artifact retention, and no direct sensitive environment/report writes.

---

### `.github/workflows/audit.yml` and `.github/workflows/device-e2e.yml` (config / CI, request-response + event-driven)

**Analogs:** their existing jobs and `.github/workflows/device-e2e.yml`

Keep standard checkout, pinned Flutter, locked dependency retrieval, and artifact upload forms. Replace Phase 62-authoritative direct lower-level invocations with the selected single release-gate entrypoint; preserve lower-level commands only inside that runner.

**PR/push trigger and pinned-toolchain form** (`.github/workflows/audit.yml:11-42`):

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.44.8
      - name: Reproducible generation and architecture contract
        run: bash scripts/verify_codegen_reproducibility.sh
```

**Platform job and explicit post-integration hygiene form** (`.github/workflows/device-e2e.yml:36-75,77-108`):

```yaml
android-device-e2e:
  name: Android Emulator supplemental suite (API 36 x86_64 GitHub/Intel)
  runs-on: ubuntu-latest
  steps:
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: "17"
    - run: flutter pub get --enforce-lockfile
    - name: Run device integration suite
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 36
        arch: x86_64
        script: flutter test integration_test/ -d emulator-5554 -r expanded
    - run: bash scripts/release_preflight.sh --platform android
```

The planner must include a release-owner checkpoint before final CI topology: the required Apple-Silicon local arm64 Android primary lane cannot be assumed available on current GitHub-hosted runners. The existing GitHub x86_64 job is supplemental evidence only. Ensure it cannot block a candidate verdict yet is retained as a named limitation when unavailable/failing.

---

### `scripts/release_gate/expected_skips.json` (manifest/config, transform)

**Analog:** discovered inventory validation in `test/architecture/device_e2e_contract_test.dart`

Use a versioned, strict schema with only normalized test path, reason, owning phase, and exit condition. Reject duplicate paths, paths outside `integration_test/`, stale entries, missing required fields, and any discovered-but-unexecuted test without a manifest entry.

**Recursive normalized inventory pattern** (`test/architecture/device_e2e_contract_test.dart:101-122`):

```dart
final actual = Directory('integration_test')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('_test.dart'))
    .map(
      (file) => file.path
          .replaceFirst('${Directory('integration_test').path}/', '')
          .replaceAll('\\', '/'),
    )
    .toSet();

expect(actual, expected);
```

If no skips are required, commit an empty valid manifest rather than making absence mean an implicit skip allowlist.

---

### `docs/testing/RELEASE_COMPATIBILITY.md` (report/documentation, transform)

**Analog:** structured JSON-to-Markdown replacement in `scripts/verify_android_safety_lane.dart`

Treat the JSON result as authority and Markdown as a concise deterministic render. The committed report must contain final verdict, candidate commit/digests, gate summary, redacted reproducibility metadata, named limitations/debt, and the concise Phase 62 failure → fix → rerun summary required by D-14—never raw command logs.

**Bounded deterministic renderer insertion pattern** (`scripts/verify_android_safety_lane.dart:1371-1377`):

```dart
final rendered = const JsonEncoder.withIndent('  ').convert(evidence);
final start = markdown.indexOf(_evidenceStart) + _evidenceStart.length;
final end = markdown.indexOf(_evidenceEnd);
file.writeAsStringSync(
  '${markdown.substring(0, start)}\n```json\n$rendered\n```\n'
  '${markdown.substring(end)}',
);
```

Do not directly copy Phase 61’s in-place checked-in evidence mutation: D-02/D-04 conflict with a renderer modifying the tested checkout. The planner must resolve the documented report-publication lifecycle with the release owner before implementation, then test that only the chosen report-only publication step is allowed and it cannot conceal source/lock/config drift.

## Shared Patterns

### Fail-closed lower-level contracts

**Sources:** `scripts/verify_codegen_reproducibility.sh:53-77`, `scripts/coverage_gate.dart:210-273`, and `scripts/release_preflight.sh:333-365`  
**Apply to:** release orchestrator stage adapters and CI invocation.

```bash
assert_clean_generation_scope 'before generation'
flutter pub get --enforce-lockfile
dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
git diff --check
```

```dart
if (found == null) {
  missing.add(path);
  stderr.writeln(
    '[coverage:gate] MISSING: $path not in lcov source — required coverage input drift',
  );
}
exit(failures.isEmpty && missing.isEmpty ? 0 : 1);
```

```bash
run_flutter clean
remove_generated_registrants
run_flutter pub get
regenerate_if_required
run_smoke_compile
assert_expected_registrants_exist
assert_release_registrants_clean
```

The Phase 62 runner should classify these prerequisite failures as terminal and not call later device stages.

### Privacy-by-collection and bounded diagnostics

**Sources:** `scripts/verify_android_safety_lane.dart:417-434,850-862`; `scripts/verify_ios_native_safety_lane.dart:862-881`  
**Apply to:** every persisted JSON result, checkpoint, report, and CI artifact metadata.

```dart
for (final pattern in <RegExp>[
  RegExp(r'/Users/[^/\s"]+'),
  RegExp(r'/home/[^/\s"]+'),
  RegExp(r'(storePassword|keyPassword|keystore_password|secret)\s*[:=]',
      caseSensitive: false),
  RegExp(r'emulator-\d{4}'),
]) {
  if (pattern.hasMatch(encoded)) {
    issues.add('evidence contains prohibited sensitive value: ${pattern.pattern}');
  }
}
```

Use this as a backstop, not a reason to collect forbidden values before filtering.

### Host/device test distinction and deterministic device cleanup

**Sources:** `scripts/verify_android_safety_lane.dart:1198-1241`; `.github/workflows/device-e2e.yml:89-108`  
**Apply to:** platform adapters only.

```dart
await _withPreparedEmulator(root, (session) async {
  prepared = session;
  if (!prepareOnly) {
    integrationMatrix = await _runPrimaryIntegrationMatrix(root, session);
  }
});
if (!prepareOnly && integrationMatrix != null) {
  final release = await runReleaseEvidence(root);
  if (!release.completed) throw StateError(release.message);
}
```

Every formal iOS/Android run must erase test/app data, cold boot without snapshot restoration, check readiness, execute the shared discovered suite, record only redacted profiles, then invoke post-device release preflight.

## No Analog Found

| File / Concern | Role | Data Flow | Reason / Planner Direction |
|---|---|---|---|
| Candidate checkpoint schema and earliest-invalidated-stage calculation | model / utility | transform | Existing runners have status/digest proofs but no Phase-62 resume graph. Keep this pure, immutable, and heavily mutation-tested in the release-gate module. |
| Formal `PASS_WITH_LIMITATIONS` verdict semantics | model / utility | transform | Existing evidence has `PASS`/`UNAVAILABLE`, not the required three-state aggregate verdict. Implement as an exhaustive enum and test that mandatory failures always yield `BLOCKED`. |
| Clean committed candidate versus checked-in final report lifecycle | release-owner decision | event-driven | Research records a real D-02/D-04 versus D-13 ambiguity. Add a blocking planner checkpoint; do not make report drift an implicit exception. |
| CI execution of current-host Apple-Silicon arm64 Android primary lane | CI topology | event-driven | Current hosted Android workflow is Ubuntu x86_64 supplemental. A self-hosted macOS arm64 runner/trigger needs explicit release-owner authorization. |

## Metadata

**Analog search scope:** `scripts/`, `test/scripts/`, `test/architecture/`, `.github/workflows/`, `docs/testing/`, `.gitignore`  
**Files scanned:** 13  
**Pattern extraction date:** 2026-08-10
