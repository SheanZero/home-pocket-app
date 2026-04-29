# Phase 8: Re-Audit + Exit Verification — Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 12 (5 new, 5 modified, 2 regenerated)
**Analogs found:** 12 / 12 (every Phase 8 deliverable has a strong existing precedent in this repo)

Phase 8 is documentation-, configuration-, and tooling-heavy: the only `lib/` impact is **none**, the only `test/` impact is widget golden tests, and the bulk of work is `scripts/`, `.planning/`, `.github/workflows/`, and `docs/arch/`. Every new file has a same-repo analog because Phases 1–7 already exercised every relevant pattern.

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `scripts/reaudit_diff.dart` (full impl) | script (Dart CLI) | file-I/O + transform + classified output | `scripts/merge_findings.dart` | exact (sibling Dart CLI in same dir, same JSON read/write contract) |
| `test/scripts/reaudit_diff_test.dart` | test (subprocess CLI) | spawned process → stdout/stderr/file | `test/scripts/merge_findings_test.dart` and `coverage_gate_test.dart` | exact (same `Process.run` + temp-dir + symlink `.dart_tool` pattern) |
| `.planning/audit/cleanup-touched-files.txt` | data artifact | newline-delimited list | `.planning/audit/phase6-touched-files.txt` | exact (literal format mirror, just larger union scope) |
| `scripts/build_cleanup_touched_files.{sh,dart}` (generator) | script (wrapper or Dart CLI) | git/yaml read → file write | `scripts/build_coverage_baseline.sh` (shell) + `scripts/coverage_baseline.dart` (Dart) | exact (two precedents — pick one shape) |
| `test/golden/*.dart` (5–8 widget golden tests) | test (widget golden) | widget tree → PNG match | `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` | role-match (existing widget tests; goldens add `matchesGoldenFile`) |
| `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` | doc (manual checklist) | static markdown | `.planning/audit/REPO-LOCK-POLICY.md` (similar structured policy doc) | role-match (no exact precedent — first manual checklist) |
| `.planning/audit/re-audit/` directory tree | output (generated) | filesystem | `.planning/audit/{shards,agent-shards,issues.json,ISSUES.md}/` | exact (mirrors Phase-1 layout; produced by `merge_findings.dart` re-invoked) |
| `.github/workflows/audit.yml` (modify) | CI workflow | YAML | `.github/workflows/audit.yml` itself (current `coverage` job) | exact (self-extension — D-04 + D-05 surgical edits) |
| `.planning/audit/REPO-LOCK-POLICY.md` (append) | doc (policy) | markdown append | `docs/arch/03-adr/ADR-002_Database_Solution.md` `## Update 2026-04-27:` block at line 636 | exact (append-only section with cross-reference) |
| `docs/arch/03-adr/ADR-011_*.md` (append `## Update YYYY-MM-DD:`) | doc (ADR append) | markdown append | `docs/arch/03-adr/ADR-002_*.md` line 636 / ADR-007 line 960 / ADR-008 line 1192 | exact (three precedents from Phase 7) |
| `.planning/audit/coverage-baseline.{txt,json}` (regenerate) | output (regenerated) | JSON / TSV | itself (current `coverage-baseline.txt`) | exact (re-running `scripts/coverage_baseline.dart` produces same shape) |
| `.planning/audit/files-needing-tests.{txt,json}` (regenerate) | output (regenerated) | JSON / text | itself | exact (same generator) |

---

## Pattern Assignments

### `scripts/reaudit_diff.dart` (script, file-I/O + classified-output CLI)

**Analog:** `scripts/merge_findings.dart` (the only sibling Dart-CLI in `scripts/` with the same JSON-read / JSON-write / Markdown-write contract).

**Imports + entry-point pattern** (`scripts/merge_findings.dart` lines 1–8, 22):
```dart
// scripts/reaudit_diff.dart
// Diffs the re-audit issues.json against the Phase-1 baseline by
// (category, normalized_file_path, description). Produces classified
// counters {resolved, regression, new} + REAUDIT-DIFF.{json,md}.

import 'dart:convert';
import 'dart:io';

import 'audit/finding.dart';

Future<void> main(List<String> args) async { ... }
```
Pattern to copy:
- Top-level header comment block declaring purpose, inputs, outputs.
- Imports: `dart:convert`, `dart:io`, relative `audit/finding.dart` for the schema model.
- `Future<void> main(List<String> args) async`.
- All paths default to project root (`.planning/audit/...`); no path flags required for happy path. Optional flags follow the `coverage_gate.dart` style if needed.

**Reading existing JSON catalogue** (`scripts/merge_findings.dart` lines 131–153):
```dart
Future<Map<String, Finding>> _readExistingLifecycle() async {
  final file = File('.planning/audit/issues.json');
  if (!file.existsSync()) return const {};
  try {
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final findings = decoded['findings'];
    if (findings is! List) return const {};
    return {
      for (final entry in findings.whereType<Map>())
        if (_hasLifecycle(entry))
          _lifecycleKey(Finding.fromJson(entry.cast<String, dynamic>())):
              Finding.fromJson(entry.cast<String, dynamic>()),
    };
  } catch (e) {
    stderr.writeln('[audit:merge] WARNING: failed to read existing lifecycle metadata: $e');
    return const {};
  }
}
```
Pattern to copy:
- Read `.planning/audit/issues.json` (baseline) and `.planning/audit/re-audit/issues.json` (re-audit) the same way.
- `Finding.fromJson(entry.cast<String, dynamic>())` is the canonical decode.
- Wrap in try/catch with `[reaudit:diff] WARNING:` stderr line on parse failure.

**Stable-ID match key** (`scripts/merge_findings.dart` line 160–161):
```dart
String _lifecycleKey(Finding finding) =>
    '${finding.category}|${finding.filePath}|${finding.lineStart}|${finding.description}';
```
Pattern to copy with adjustment per Phase 1 D-07 + Phase 8 D-02:
- Match key for `reaudit_diff` is `(category, normalized_file_path, description)` — drop `lineStart` from the match key (line numbers may shift post-cleanup) but otherwise reuse this private-helper shape.
- Honor Phase 1 D-08 split/merge fields (`split_from`, `closed_as_duplicate_of`) when building the baseline ID set.

**JSON output emission** (`scripts/merge_findings.dart` lines 113–120):
```dart
final issuesPath = '.planning/audit/issues.json';
final issuesDir = Directory('.planning/audit');
if (!issuesDir.existsSync()) issuesDir.createSync(recursive: true);
await File(issuesPath).writeAsString(
  const JsonEncoder.withIndent('  ').convert({'findings': catalogue.map((f) => f.toJson()).toList()}),
);
```
Pattern to copy:
- Write to `.planning/audit/re-audit/REAUDIT-DIFF.json` with `JsonEncoder.withIndent('  ')`.
- No top-level `generated_at` field in JSON output — keeps file byte-stable across re-runs (Phase 1 D-09 idempotency).
- Top-level shape: `{ "summary": { "resolved": N, "regression": N, "new": N, "open_in_baseline": N }, "buckets": { ... } }`.

**Markdown output emission** (`scripts/merge_findings.dart` lines 184–231 — full `_renderMarkdown` function):
```dart
String _renderMarkdown(List<Finding> findings) {
  final buf = StringBuffer();
  buf.writeln('# Audit Findings');
  buf.writeln();
  buf.writeln('**Total findings:** ${findings.length}');
  ...
  for (final sev in severities) {
    final inSev = findings.where((f) => f.severity == sev).toList();
    if (inSev.isEmpty) continue;
    buf.writeln('## $sev');
    ...
  }
}
```
Pattern to copy:
- `REAUDIT-DIFF.md` follows the same severity-then-category section structure.
- Use the same severity order: `['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']`.
- Use the same category order: `['layer_violation', 'provider_hygiene', 'dead_code', 'redundant_code']`.
- Per Phase 1 D-10/D-11: human-readable; bucket the findings into `Resolved` / `Regression` / `New` / `Still Open in Baseline`; include the `summary` counters block at the top.

**Exit codes (D-01 strict-exit contract):**
```dart
// stdout summary first
stdout.writeln('[reaudit:diff] resolved=$resolvedCount regression=$regressionCount new=$newCount open_in_baseline=$openInBaselineCount');

if (regressionCount == 0 && newCount == 0 && openInBaselineCount == 0) {
  exit(0);
} else {
  exit(1);
}
```
Pattern to copy from `scripts/coverage_gate.dart` lines 96–98 / 165–166 (idiomatic exit shape used elsewhere in this repo):
```dart
stderr.writeln('[coverage:gate] ERROR: no files supplied (...)');
exit(2);
...
exit(failures.isEmpty ? 0 : 1);
```
- Exit `0` only when **all three** counters are zero AND no baseline finding has `status == 'open'`.
- Exit `1` for any non-zero counter (the project's "gate failure" exit code).
- Reserve `2` for invocation errors (missing baseline, malformed JSON), per `coverage_gate.dart` convention.

---

### `test/scripts/reaudit_diff_test.dart` (test, subprocess CLI)

**Analog:** `test/scripts/merge_findings_test.dart` and `test/scripts/coverage_gate_test.dart` — both use the same temp-dir + symlink-`.dart_tool` pattern that Phase 1 standardized.

**Subprocess runner pattern** (`test/scripts/merge_findings_test.dart` lines 20–27):
```dart
Future<ProcessResult> _runMerger(Directory cwd) async {
  return Process.run(
    'dart',
    ['run', '$_projectRoot/scripts/merge_findings.dart'],
    runInShell: true,
    workingDirectory: cwd.path,
  );
}
```

**Temp project setup** (`test/scripts/coverage_gate_test.dart` lines 25–45):
```dart
Directory _setupTempProject() {
  final tmp = Directory.systemTemp.createTempSync('cov_gate_test_');
  final root = _absoluteProjectRoot();

  Directory('${tmp.path}/scripts/coverage').createSync(recursive: true);
  File('$root/scripts/coverage_gate.dart').copySync('${tmp.path}/scripts/coverage_gate.dart');
  File('$root/scripts/coverage/lcov_parser.dart').copySync('${tmp.path}/scripts/coverage/lcov_parser.dart');

  File('$root/pubspec.yaml').copySync('${tmp.path}/pubspec.yaml');
  Link('${tmp.path}/.dart_tool').createSync('$root/.dart_tool', recursive: true);

  Directory('${tmp.path}/coverage').createSync(recursive: true);
  Directory('${tmp.path}/.planning/audit').createSync(recursive: true);
  return tmp;
}
```
Pattern to copy:
- `Directory.systemTemp.createTempSync('reaudit_diff_test_')`.
- Copy `scripts/reaudit_diff.dart` + `scripts/audit/finding.dart` + `pubspec.yaml` into the temp tree.
- `Link('${tmp.path}/.dart_tool').createSync('$root/.dart_tool', recursive: true)` — symlink instead of `pub get` (huge speedup on CI).
- Pre-create `.planning/audit/` and `.planning/audit/re-audit/` inside `tmp`.

**Test cases — required coverage per D-01** (`test/scripts/coverage_gate_test.dart` lines 82–192 for shape):
```dart
void main() {
  group('reaudit_diff.dart (subprocess)', () {
    late Directory tmp;
    setUp(() { tmp = _setupTempProject(); });
    tearDown(() { try { tmp.deleteSync(recursive: true); } catch (_) {} });

    test('exit 0 happy path: re-audit catalogue identical to baseline (all closed)', () async { ... });
    test('exit 1 branch A: regression > 0 (closed baseline ID re-opens in re-audit)', () async { ... });
    test('exit 1 branch B: new > 0 (re-audit ID with no baseline match)', () async { ... });
    test('exit 1 branch C: open_in_baseline > 0 (baseline has status=open finding)', () async { ... });
    test('classified counters appear in stdout AND REAUDIT-DIFF.json on every exit-1 path', () async { ... });
  });
}
```
Pattern to copy:
- Each test fixture writes a minimal `issues.json` (baseline) + `re-audit/issues.json` (re-audit) into the temp dir, runs the script, asserts `exitCode` and stdout/file contents.
- `Process.run` returns `r.exitCode`, `r.stdout`, `r.stderr` — assert all three.

---

### `.planning/audit/cleanup-touched-files.txt` (data artifact, newline list)

**Analog:** `.planning/audit/phase6-touched-files.txt` — exact same format, just a larger union of files.

**Format pattern** (full file, 19 lines):
```
lib/data/tables/audit_logs_table.dart
lib/data/tables/user_profiles_table.dart
lib/data/tables/category_ledger_configs_table.dart
lib/data/app_database.dart
lib/main.dart
lib/core/initialization/app_initializer.dart
lib/application/accounting/create_transaction_use_case.dart
...
```
Pattern to copy:
- One absolute-from-repo-root path per line (no leading `./`).
- `lib/`-prefixed only (no `test/`, no `scripts/`).
- No comments (pure data file consumed by `coverage_gate.dart --list`).
- No trailing blank line — file ends with `\n` after the last entry.
- Phase 8 D-04: union of files from Phase 3-6 plan `files_modified:` frontmatter (filtered to `lib/**`).

**Optional one-line header** (per Phase 8 D-04 "How to apply" — kept on disk note for `phase6-touched-files.txt`):
- The historical `phase6-touched-files.txt` may add a one-line header comment `# Superseded by cleanup-touched-files.txt in Phase 8` BUT must NOT be deleted/renamed. Note: `coverage_gate.dart` already has `f.readAsLinesSync().where((l) => l.trim().isNotEmpty)` (line 84) so blank-line tolerance exists; comment lines starting with `#` would currently be passed through as filenames — so keep the new `cleanup-touched-files.txt` comment-free.

---

### `scripts/build_cleanup_touched_files.{sh,dart}` (generator script)

**Analog A — shell wrapper:** `scripts/build_coverage_baseline.sh` (the one-shot pipeline orchestrator pattern).

**Header + set + step structure** (full file):
```bash
#!/usr/bin/env bash
# scripts/build_coverage_baseline.sh
# Local end-to-end run of the Phase 2 coverage baseline pipeline ...
#
# Steps:
#   1. flutter test --coverage              → coverage/lcov.info
#   2. coverde filter (strip generated)     → coverage/lcov_clean.info
#   3. dart run scripts/coverage_baseline   → 4 .planning/audit/ artifacts
#   4. Verify all four artifact files exist

set -euo pipefail

echo "[coverage:baseline] running flutter test --coverage..."
flutter test --coverage

...

echo "[coverage:baseline] OK"
```
Pattern to copy:
- `#!/usr/bin/env bash` shebang.
- Header comment block listing numbered steps.
- `set -euo pipefail`.
- Each step has a `[<tag>] message...` echo line for log clarity.
- Trailing `OK` echo on success.

**Analog B — Dart CLI:** `scripts/coverage_baseline.dart` (the file-I/O + parse + write pipeline).

**Header + arg-parse + write pattern** (`scripts/coverage_baseline.dart` lines 1–44, 67–69, 114):
```dart
// scripts/coverage_baseline.dart
// Reads coverage/lcov_clean.info, writes 4 .planning/audit/coverage-* artifacts.

import 'dart:convert';
import 'dart:io';

const _outDir = '.planning/audit';

Future<void> main(List<String> args) async {
  // arg parse loop here (see coverage_gate.dart lines 33-74 for full pattern)
  ...
  final outDir = Directory(_outDir);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  ...
  File('$_outDir/coverage-baseline.txt').writeAsStringSync(txtBuf.toString());
}
```
Pattern to copy:
- Header comment block declaring output paths.
- `const _outDir = '.planning/audit'` named constant.
- `if (!outDir.existsSync()) outDir.createSync(recursive: true)` defensive directory creation.
- `writeAsStringSync` for the final output (atomic enough for our use).
- Discretion (per CONTEXT D-04 "How to apply"): planner picks shell vs Dart based on whether YAML frontmatter parsing is involved. Bash + `grep` is enough if the source is git-log diffs; Dart + `package:yaml` is cleaner if reading `files_modified:` frontmatter directly. **Prefer Bash** to match the existing `scripts/audit_*.sh` precedent — frontmatter can be extracted via `awk` or a small Dart helper invoked from the shell wrapper.

---

### `test/golden/*.dart` (5–8 widget golden tests, D-07)

**Analog:** `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` — the closest existing widget tests with monetary rendering, `FontFeature.tabularFigures()` enforcement, and explicit `Locale` switching.

**Imports + helper widget pattern** (lines 1–13, 167–179):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/i18n/formatter_service.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/summary_cards.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _localizedApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}
```
Pattern to copy:
- Import the production widget under test from `package:home_pocket/...`.
- Always wrap in `MaterialApp` with `S.delegate` + global Material/Widgets/Cupertino delegates.
- Pass `Locale` explicitly per test (each locale of interest gets its own test).
- For golden tests, use `test/helpers/test_localizations.dart` `createLocalizedWidget()` — already imports the same delegate set:
  ```dart
  Widget createLocalizedWidget(Widget child, {Locale locale = const Locale('en'), List<Override> overrides = const []})
  ```

**testWidgets shape with FontFeature assertion** (`analytics_money_widgets_test.dart` lines 17–47, 181–187):
```dart
testWidgets(
  'SummaryCards renders localized English labels, formatted yen, and tabular amount styles',
  (tester) async {
    const locale = Locale('en');
    await tester.pumpWidget(
      _localizedApp(locale: locale, child: const SummaryCards(report: _summaryReport)),
    );
    expect(find.text('Income'), findsOneWidget);
    _expectMoneyText(tester, const FormatterService().formatCurrency(123456, 'JPY', locale));
  },
);

void _expectMoneyText(WidgetTester tester, String value) {
  final finder = find.text(value);
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.style?.fontFeatures, contains(FontFeature.tabularFigures()));
}
```
Pattern to copy and **extend with `matchesGoldenFile`** for true golden tests:
```dart
testWidgets('AmountDisplay golden — JPY ¥1,235', (tester) async {
  await tester.pumpWidget(_localizedApp(
    locale: const Locale('ja'),
    child: const AmountDisplay(amount: '1235', currencyLabel: 'JPY'),
  ));
  await expectLater(
    find.byType(AmountDisplay),
    matchesGoldenFile('goldens/amount_display_jpy.png'),
  );
});
```
- Goldens stored in `test/golden/goldens/<name>.png` (sibling subfolder; standard Flutter convention).
- Generate with: `flutter test --update-goldens test/golden/`.
- Required minimum set per D-07: (1) AmountDisplay JPY/CNY/USD, (2) monthly report summary card, (3) transaction form with currency-formatted preview, (4) soul fullness card with localized labels. Planner picks 5–8 from this set based on Phase 3-5 diff impact.

---

### `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` (manual checklist)

**Analog:** No exact precedent in this repo for a user-filled checkbox manual checklist. Closest structural analogs are `.planning/audit/REPO-LOCK-POLICY.md` (structured policy doc with sectioned headings) and the `## Update YYYY-MM-DD:` sections in ADR-002/007/008 (dated update blocks).

**Recommended structure** (D-06 dictates the eight sections; format follows REPO-LOCK-POLICY.md heading conventions):
```markdown
# Phase 8 Smoke Test — User-Filled Checklist

**Created:** 2026-MM-DD
**Phase 8** — Codebase Cleanup Initiative exit verification
**Source of Truth:** `.planning/phases/08-re-audit-exit-verification/08-CONTEXT.md` D-06

> All items must be checked before Phase 8 closes. Each unchecked or failing item is a blocking finding (record as new entry in `.planning/audit/re-audit/issues.json`).

## 1. Transaction CRUD on both ledgers
- [ ] Create transaction on Survival ledger; amount/date/category persisted
- [ ] Edit transaction on Survival ledger; changes reflect in monthly report
- [ ] Delete transaction on Survival ledger; removed from list and totals
- [ ] Create transaction on Soul ledger; amount/date/category persisted
- [ ] Edit transaction on Soul ledger; changes reflect in monthly report
- [ ] Delete transaction on Soul ledger; removed from list and totals

## 2. Ledger switch (Survival ↔ Soul)
- [ ] Switch from Survival to Soul; UI theme changes (blue → green)
- [ ] Switch from Soul to Survival; UI theme changes back

## 3. Monthly report screen with currency formatting
- [ ] Switch locale to ja; report shows ¥1,235 (no decimals, JPY)
- [ ] Switch locale to en; report shows $12.35 (2 decimals, USD)
- [ ] Switch locale to zh; report shows ¥12.35 (2 decimals, CNY) where applicable

## 4. Settings: backup export + import
- [ ] Export backup; file produced; size > 0
- [ ] Import backup on a fresh install; transactions restore identically

## 5. Family sync push + pull
- [ ] Push: device A creates transaction, device B receives it
- [ ] Pull: device B creates transaction, device A receives it

## 6. Voice input
- [ ] Voice input parses currency amount correctly (¥1,235 → "1235")
- [ ] Voice input populates transaction form

## 7. Language switch (ja → zh → en) with locale-specific formatting
- [ ] ja: amount "¥1,235" + date "2026/04/28"
- [ ] zh: amount "¥1,235.00" + date "2026年04月28日"
- [ ] en: amount "$1,235.00" + date "04/28/2026"

## 8. ARB-driven UI text spot-check on Phase-5-touched screens
- [ ] Home screen labels match locale (no hardcoded CJK)
- [ ] Analytics screen labels match locale
- [ ] Settings screen labels match locale

## Sign-off
- [ ] All checks pass — Phase 8 close eligible.
- [ ] Tester:
- [ ] Date:
- [ ] Build commit hash:
```
Pattern to copy:
- Header block with `**Created:**`, `**Phase 8**`, `**Source of Truth:**` lines (mirrors REPO-LOCK-POLICY.md lines 1–4).
- Eight numbered `## N. <Section>` headings matching D-06 (a)–(h).
- Markdown task lists (`- [ ]`) per item.
- Trailing `## Sign-off` section captures tester name + date + commit hash.

---

### `.planning/audit/re-audit/` directory tree (output, generated)

**Analog:** `.planning/audit/{shards/, agent-shards/, issues.json, ISSUES.md}` — Phase 1 created this layout; Phase 8 mirrors it under `re-audit/`.

**Layout pattern** (`ls .planning/audit/`):
```
.planning/audit/
├── shards/                 # 4 tooling scanner outputs (layer.json, dead_code.json, providers.json, duplication.json)
├── agent-shards/           # 4 AI agent outputs (drift_col.json, duplication.json, layer.json, transitive.json)
├── issues.json             # merger output, machine-readable
└── ISSUES.md               # merger output, human-readable (severity-then-category sections)
```
Pattern to copy verbatim — Phase 8 produces:
```
.planning/audit/re-audit/
├── shards/
├── agent-shards/
├── issues.json             # produced by `dart run scripts/merge_findings.dart` after re-running scanners + agents into re-audit/{shards,agent-shards}
├── ISSUES.md               # produced by the same merger run
├── REAUDIT-DIFF.json       # produced by `dart run scripts/reaudit_diff.dart`
└── REAUDIT-DIFF.md         # produced by the same reaudit_diff run
```
Per CONTEXT D-03 "How to apply": the existing `scripts/merge_findings.dart` is reused unchanged but invoked with the re-audit shard root. The merger currently hardcodes `.planning/audit/` paths (lines 26 + 113) — Phase 8 plan must either (a) add a `--root` flag to `merge_findings.dart` (smallest patch) or (b) `cd .planning/audit/re-audit && dart run` with symlinks. **Prefer (a) — add a `--root <path>` arg** so the same script works for both baseline and re-audit invocations. This is the only modification to `merge_findings.dart` Phase 8 needs.

---

### `.github/workflows/audit.yml` (modify, D-04 + D-05)

**Analog:** itself — current `audit.yml` (128 lines).

**D-04 — switch coverage gate `--list` argument** (current `audit.yml` line 107):
```yaml
- name: Per-file coverage gate
  run: dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info
```
Pattern to apply:
```yaml
- name: Per-file coverage gate
  run: dart run scripts/coverage_gate.dart --list .planning/audit/cleanup-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info
```
Single-line edit. Preserve `--threshold 80` and `--lcov coverage/lcov_clean.info`.

**D-05 #1 — Top-of-file warning comment block** (insert at line 1, before `name: audit`):
```yaml
# ⚠️ Permanent gate — do not weaken without ADR amendment.
# See docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md.
# Phase 8 D-05: the four guardrails below (import_guard / custom_lint /
# coverde per-file ≥80% / sqlite3_flutter_libs reject) are blocking on
# every PR + push to main. Removing `if: pull_request` from the coverage
# job and any `continue-on-error: true` flag is intentional.

name: audit
```
Pattern: matches the comment voice already used in the file (line 40: `# Made blocking at Phase 3 close per D-17 (previously non-blocking)`; line 69: `# AUDIT-09 — sqlite3_flutter_libs reject. BLOCKING from end of Phase 1.`).

**D-05 #2 — sweep `continue-on-error`** — verify (do not assume):
```bash
grep -n "continue-on-error" .github/workflows/audit.yml
# Current main: zero hits — verify post-cleanup, remove any that crept in.
```
Pattern: each guardrail step is a plain `run:` with no soft-fail flag. Examples already in compliance:
- `flutter analyze` (line 38): plain `run:`, no continue-on-error.
- `dart run custom_lint` (lines 40-41): plain `run:`, comment notes Phase 3 D-17 made it blocking.
- AUDIT-09 sqlite3 reject (lines 70-75): plain `run:`, exit 1 on detection.
- AUDIT-10 build_runner stale-diff (lines 78-84): plain `run:`, exit 1 on detection.

**D-05 #3 — lift coverage job's `if: pull_request`** (current `audit.yml` line 89):
```yaml
  coverage:
    runs-on: ubuntu-latest
    needs: static-analysis
    if: ${{ github.event_name == 'pull_request' }}   # ← REMOVE THIS LINE
    steps:
```
Pattern to apply:
```yaml
  coverage:
    runs-on: ubuntu-latest
    needs: static-analysis
    steps:
```
Single-line removal. Result: coverage gate runs on both `pull_request` (existing) and `push: branches: [main]` (already declared at the top of the file in lines 4-7) — direct-to-main pushes can no longer bypass the 80% gate.

---

### `.planning/audit/REPO-LOCK-POLICY.md` (append `## Phase 8 Close — Permanent Gates`)

**Analog:** itself — file ends at line 69 with `## References`. The "## Lifecycle" table at lines 30-37 already has a "Phase 8" row (`Coverage baseline regenerated; gate stays blocking permanently`).

**Pattern to apply** — append a new closing section after `## References`:
```markdown
## References

- `.planning/phases/02-coverage-baseline/02-CONTEXT.md` — D-05, D-07, D-08 source-of-truth
- ...

## Phase 8 Close — Permanent Gates

**Locked:** 2026-MM-DD
**Phase 8** — Codebase Cleanup Initiative terminal phase
**Cross-reference:** [ADR-011](../../docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md) `## Update 2026-MM-DD: Re-audit Outcome`

The cleanup runway lock window CLOSES at Phase 8 close. The four CI guardrails are now permanent and blocking on every PR and direct push to `main`:

1. **`import_guard`** (custom_lint plugin host) — runs in `.github/workflows/audit.yml` `static-analysis` job, `dart run custom_lint` step.
2. **`riverpod_lint`** (custom_lint plugin host, same step as `import_guard`) — provider hygiene gate.
3. **`coverde` per-file ≥80%** — runs in the `coverage` job; `if: pull_request` lifted per Phase 8 D-05 so push-to-main also gated.
4. **`sqlite3_flutter_libs` reject** — runs in `guardrails` job; greps `pubspec.lock`, exits 1 on detection.

`audit.yml` carries a top-of-file warning comment block recording these as permanent. Weakening any guardrail (adding `continue-on-error: true`, restoring `if: pull_request` on coverage, removing the warning block) requires an ADR-011 amendment.

The non-cleanup PR lock from "## The Policy" (above) is LIFTED at Phase 6 close per the lifecycle table; the **gate-permanence** lock added by this section is independent and remains in force indefinitely.
```
Pattern to copy: matches the doc's existing voice — bold-headed metadata block, numbered list, cross-reference to ADR-011.

---

### `docs/arch/03-adr/ADR-011_*.md` (append `## Update YYYY-MM-DD: Re-audit Outcome`)

**Analog:** `docs/arch/03-adr/ADR-002_Database_Solution.md` line 636, `ADR-007_Layer_Responsibilities.md` line 960, `ADR-008_Book_Balance_Update_Strategy.md` line 1192 — all three appended `## Update 2026-04-27: Cleanup Initiative Outcome` during Phase 7 plan 02 (07-02-adr-drift-PLAN).

**Append-only pattern** (`ADR-002_Database_Solution.md` lines 632–653):
```markdown
**下次Review日期:** 2026-08-03

---

## Update 2026-04-27: Cleanup Initiative Outcome

**Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

Phases 3–6 of the codebase cleanup initiative changed how this decision is enforced
in production:

- `sqlite3_flutter_libs` is now actively rejected by CI gate AUDIT-09
  (`.github/workflows/audit.yml:69-75`) and by `lib/import_guard.yaml:6`
  (`package:sqlite3_flutter_libs/**` deny rule).
- ...

The original decision body above is preserved verbatim per ADR append-only convention
(`.claude/rules/arch.md:157-162`).
```
Pattern to copy verbatim:
- `---` separator before the new section.
- `## Update YYYY-MM-DD: <topic>` heading.
- `**Cross-reference:**` line on first line of section body when applicable (Phase 8: cross-reference `.planning/audit/re-audit/REAUDIT-DIFF.md`, `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md`, `.planning/audit/cleanup-touched-files.txt`).
- Bullet list of concrete changes with line/file references.
- Trailing paragraph confirming append-only convention.

**Required content per Phase 8 D-08** (four items must appear):
1. Re-audit delta — `resolved`/`regression`/`new` counters from `REAUDIT-DIFF.json` + cross-reference to `.planning/audit/re-audit/issues.json`.
2. Smoke test outcome — link to `08-SMOKE-TEST.md` + one-line PASS / DISCREPANCIES_FOUND status.
3. Coverage gate change — note that `audit.yml` reads `cleanup-touched-files.txt` + that `coverage-baseline.txt` was regenerated.
4. Guardrails permanence — confirm the four code-side D-05 changes landed (warning comment, no soft-fail, `if: pull_request` lifted, REPO-LOCK-POLICY §"Phase 8 Close" added).

---

### `.planning/audit/coverage-baseline.{txt,json}` + `files-needing-tests.{txt,json}` (regenerate)

**Analog:** itself — `scripts/coverage_baseline.dart` already produces all four files atomically.

**Regeneration command** (`scripts/build_coverage_baseline.sh` lines 14-28):
```bash
flutter test --coverage
coverde filter \
  --input coverage/lcov.info \
  --output coverage/lcov_clean.info \
  --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
dart run scripts/coverage_baseline.dart
```
Pattern: re-invoke the existing pipeline. No code changes to `coverage_baseline.dart`. Output diff vs current frozen baseline goes into ADR-011 `## Update` section.

**Determinism note** (`scripts/coverage_baseline.dart` lines 11-13):
> Determinism (D-12): re-running against the same lcov_clean.info produces byte-identical .txt outputs and .json outputs that differ only in the `generated_at` metadata field. Phase 8 byte-compare normalizes that field.

Pattern to apply: Phase 8 plan that regenerates these files should mention this determinism guarantee in its acceptance criteria — diff between old and new should be attributable to coverage-shifts only, not script churn.

---

## Shared Patterns

### Shared Pattern A — Dart CLI in `scripts/` (file-I/O + JSON contract)

**Sources:**
- `scripts/merge_findings.dart` (Phase 1)
- `scripts/coverage_gate.dart` (Phase 2)
- `scripts/coverage_baseline.dart` (Phase 2)

**Apply to:** `scripts/reaudit_diff.dart`, `scripts/build_cleanup_touched_files.dart` (if Dart variant chosen).

**Header pattern** (`scripts/coverage_gate.dart` lines 1-16):
```dart
// scripts/coverage_gate.dart
// Per-file coverage gate. Hybrid CLI: positional + --list + fallback.
// CONTEXT.md D-01..D-04. ...
//
// Usage:
//   dart run scripts/coverage_gate.dart [<file>...]
//                                       [--list <path>]
//                                       [--threshold N]
//                                       [--lcov <path>]
//                                       [--json]
//
// Exit codes (D-04):
//   0 — every supplied file met threshold
//   1 — at least one file below threshold (gate failure)
//   2 — invocation error (missing lcov, unknown flag, no files supplied)

import 'dart:convert';
import 'dart:io';
```

**Arg-parse loop** (`scripts/coverage_gate.dart` lines 33-74):
```dart
for (var i = 0; i < args.length; i++) {
  final a = args[i];
  switch (a) {
    case '--threshold':
      if (i + 1 >= args.length) {
        stderr.writeln('[coverage:gate] ERROR: --threshold requires an integer');
        exit(2);
      }
      ...
    default:
      if (a.startsWith('--')) {
        stderr.writeln('[coverage:gate] ERROR: unknown flag: $a');
        exit(2);
      }
      positionals.add(a);
  }
}
```
- `[<tag>] ERROR: ...` stderr prefix is the project standard.
- Unknown flag → exit 2.
- Missing required flag value → exit 2.

### Shared Pattern B — Subprocess test in `test/scripts/`

**Sources:** `test/scripts/merge_findings_test.dart`, `coverage_gate_test.dart`, `coverage_baseline_test.dart`, `lcov_parser_test.dart`.

**Apply to:** `test/scripts/reaudit_diff_test.dart`.

**Setup/teardown skeleton** (`test/scripts/coverage_gate_test.dart` lines 67-81):
```dart
void main() {
  group('coverage_gate.dart (subprocess)', () {
    late Directory tmp;
    setUp(() { tmp = _setupTempProject(); });
    tearDown(() {
      try { tmp.deleteSync(recursive: true); } catch (_) { /* ignore */ }
    });
    ...
  });
}
```

**Symlinked `.dart_tool` for fast subprocess invocation:**
```dart
Link('${tmp.path}/.dart_tool').createSync('$root/.dart_tool', recursive: true);
```
- Avoids `dart pub get` in every test (saves ~5s per test).
- Symlink semantics: child writes are isolated; reads pierce through to project pub cache.

### Shared Pattern C — Append-only doc updates with cross-reference

**Sources:** `docs/arch/03-adr/ADR-002_*.md` line 636, ADR-007 line 960, ADR-008 line 1192 (Phase 7 plan 02). Project rule `.claude/rules/arch.md` line 157-162: "ADR append-only ... append to file end with `## Update YYYY-MM-DD: <topic>` block."

**Apply to:** ADR-011 amendment, REPO-LOCK-POLICY.md "Phase 8 Close" section.

**Verbatim shape:**
```markdown
---

## Update YYYY-MM-DD: <Topic>

**Cross-reference:** [<other doc>](relative/path.md)

<one-paragraph context — what changed, why this section exists>

- <bullet 1 with concrete file:line references>
- <bullet 2 with concrete file:line references>
...

The original decision body above is preserved verbatim per ADR append-only convention
(`.claude/rules/arch.md:157-162`).
```

### Shared Pattern D — Architecture test for issues.json closure assertion

**Source:** `test/architecture/low_findings_closed_test.dart` (full 34-line file).

**Apply to:** Phase 8 may add `test/architecture/all_findings_closed_test.dart` (or similar) that asserts every severity has zero open findings. Phase 6 already provides `low_findings_closed_test.dart`; Phase 5 has `medium_findings_closed_test.dart`. Phase 8 plan can either (a) extend the existing tests or (b) add a single all-severities aggregate test using the same shape.

**Skeleton:**
```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('All-findings audit closure gate (Phase 8)', () {
    test('issues.json has no open findings of any severity', () {
      final catalogue =
          jsonDecode(File('.planning/audit/issues.json').readAsStringSync())
              as Map<String, Object?>;
      final findings = catalogue['findings']! as List<Object?>;
      final open = findings
          .whereType<Map<String, Object?>>()
          .where((f) => f['status'] == 'open')
          .map((f) => f['id'])
          .toList();
      expect(open, isEmpty, reason: 'Open findings remain: $open');
    });
  });
}
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Every Phase 8 deliverable has a strong analog in the existing codebase. |

Notes:
- `08-SMOKE-TEST.md` does not have an exact precedent — it is the first user-filled checklist artifact in `.planning/`. Format is derived from REPO-LOCK-POLICY.md (header voice) + ADR `## Update` block (dated section convention) + standard markdown task lists (`- [ ]`).
- `.planning/audit/cleanup-touched-files.txt` content scope is new (Phase 3-6 union) but the file format is a literal mirror of `phase6-touched-files.txt`.

## Metadata

**Analog search scope:**
- `scripts/` (all Dart + shell scripts)
- `scripts/audit/` (Dart core libraries)
- `test/scripts/` (subprocess CLI tests)
- `test/architecture/` (issues.json closure tests)
- `test/widget/features/analytics/` (widget tests with monetary rendering, FontFeature)
- `test/helpers/` (test_localizations.dart, test_provider_scope.dart)
- `.github/workflows/audit.yml`
- `.planning/audit/` (REPO-LOCK-POLICY, issues.json, ISSUES.md, phase6-touched-files.txt, schema)
- `docs/arch/03-adr/` (ADR-002, ADR-007, ADR-008, ADR-011 — append-only precedents)

**Files scanned:** 27 (12 source + 15 reference)
**Pattern extraction date:** 2026-04-28
