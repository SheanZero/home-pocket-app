# Phase 02: Coverage Baseline - Pattern Map

**Mapped:** 2026-04-25
**Files analyzed:** 8 (6 NEW, 1 MODIFIED, 1 OPTIONAL doc)
**Analogs found:** 8 / 8 (lcov-parsing has no prior art — pure new code, but envelope/emission patterns covered)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/coverage_baseline.dart` | utility (Dart script) | file-I/O → transform → file-I/O | `scripts/merge_findings.dart` | exact |
| `scripts/coverage_gate.dart` | utility (Dart script + CLI gate) | file-I/O → predicate → exit-code | `scripts/audit/dead_code.dart` (envelope + Process.run shape) + `scripts/merge_findings.dart` (sort/emit) | role-match (CLI parsing — no prior art) |
| `scripts/build_coverage_baseline.sh` | shell wrapper | command composition | `scripts/test_audit_pipeline.sh` | exact |
| `.planning/audit/coverage-baseline.txt` | data artifact (TSV) | emitted | `.planning/audit/ISSUES.md` (twin-of-json human view) | role-match |
| `.planning/audit/coverage-baseline.json` | data artifact (JSON) | emitted | `.planning/audit/issues.json` | exact |
| `.planning/audit/files-needing-tests.txt` | data artifact (path list) | emitted | (no exact analog — derived view) | role-match |
| `.planning/audit/files-needing-tests.json` | data artifact (JSON) | emitted | `.planning/audit/issues.json` | role-match |
| `.planning/audit/COVERAGE-SCHEMA.md` (optional) | documentation | static | `.planning/audit/SCHEMA.md` | exact |
| `.github/workflows/audit.yml` (MODIFIED) | CI config | yaml | (self — modify existing `coverage` job) | exact |

---

## Pattern Assignments

### `scripts/coverage_baseline.dart` (utility, file-I/O → transform → file-I/O)

**Analog:** `scripts/merge_findings.dart`

**Entry-point shape** (`scripts/merge_findings.dart` lines 1-22):
```dart
// scripts/merge_findings.dart
// Reads .planning/audit/{shards,agent-shards}/*.json, dedupes,
// stamps stable IDs, writes issues.json + ISSUES.md.

import 'dart:convert';
import 'dart:io';

import 'audit/finding.dart';

const _generatedFileGlobs = ['.g.dart', '.freezed.dart', '.mocks.dart'];

bool _isGenerated(String path) =>
    _generatedFileGlobs.any(path.endsWith) || path.contains('lib/generated/');

Future<void> main(List<String> args) async {
  // ...
}
```
Apply to `coverage_baseline.dart`:
- Top-level header comment describing inputs/outputs
- `dart:convert` + `dart:io` only (no library exports, no extra deps)
- `Future<void> main(List<String> args) async`
- Same `_isGenerated` predicate — defense-in-depth even though `coverde filter` upstream already strips generated files (matches Phase 1 D-09 / Phase 2 D-11 idempotency invariant)

**Deterministic sort + JSON emit** (`scripts/merge_findings.dart` lines 69-117):
```dart
// 3. Sort deterministically: file_path asc, line_start asc, category prefix.
final sorted = byKey.values.toList()
  ..sort((a, b) {
    final fp = a.filePath.compareTo(b.filePath);
    if (fp != 0) return fp;
    // ...
  });

// 5. Emit issues.json (machine-readable; no top-level timestamp so the
//    file is byte-identical across re-runs — see merger_findings_test.dart).
final issuesPath = '.planning/audit/issues.json';
final issuesDir = Directory('.planning/audit');
if (!issuesDir.existsSync()) issuesDir.createSync(recursive: true);
await File(issuesPath).writeAsString(
  const JsonEncoder.withIndent(
    '  ',
  ).convert({'findings': stamped.map((f) => f.toJson()).toList()}),
);

// 6. Emit ISSUES.md (human-readable, severity-then-category, table per group).
final md = _renderMarkdown(stamped);
await File('.planning/audit/ISSUES.md').writeAsString(md);

print('[audit:merge] wrote ${stamped.length} findings to $issuesPath');
```
Apply to `coverage_baseline.dart`:
- Sort by `file_path` ascending (D-10) — single comparator, no ties expected since one record per file
- `JsonEncoder.withIndent('  ')` — 2-space indent, matches `issues.json`
- `mkdir -p` equivalent: `if (!dir.existsSync()) dir.createSync(recursive: true)`
- `print('[coverage:baseline] wrote N entries to ...')` — `[scope:script]` log prefix convention
- D-12 idempotency: do NOT include a top-level timestamp in JSON. Phase 1 explicitly omits it ("file is byte-identical across re-runs"). For Phase 2, capture `generated_at` in metadata BUT planner should decide whether to omit it for byte-equality OR store `flutter_test_command` / `lcov_source` / `threshold` / `total_files` / `files_below_threshold` per CONTEXT D-11 and accept that timestamp breaks byte-equality (CONTEXT D-11 lists `generated_at` in metadata; Phase 8 byte-compare can normalize this field if needed)

**Twin-artifact emission pattern** — same script writes 4 files in one pass (extends Phase 1 pattern of merge_findings emitting both `issues.json` and `ISSUES.md`):
- `coverage-baseline.txt` (TSV, human-grep-friendly)
- `coverage-baseline.json` (machine, full record)
- `files-needing-tests.txt` (filtered view, bare paths)
- `files-needing-tests.json` (filtered view, structured)

**lcov.info input shape** (no prior art in repo — sample from `coverage/lcov.info` lines 1-12):
```
SF:lib/core/theme/app_theme.dart
DA:6,2
DA:17,1
DA:20,1
DA:22,1
DA:27,0
DA:33,0
DA:38,0
DA:41,0
DA:43,0
LF:9
LH:4
end_of_record
```
- Records separated by `end_of_record`
- `SF:<path>` — source file (one per record)
- `DA:<line>,<hits>` — per-line hit count (zero hits = uncovered)
- `LF:<n>` — total lines instrumented
- `LH:<n>` — lines hit
- Per-file percentage = `LH / LF * 100`
- The script can either (a) parse `LF`/`LH` directly (faster, simpler) or (b) recompute from `DA` lines (defense if `LF`/`LH` desync). Phase 1 precedent: prefer simpler parsing first, add defense if a real bug surfaces.

**Error-handling pattern** (`scripts/merge_findings.dart` lines 33-50):
```dart
try {
  data = jsonDecode(raw) as Map<String, dynamic>;
} catch (e) {
  stderr.writeln('[audit:merge] WARNING: failed to parse ${f.path}: $e');
  continue;
}
```
Apply: `stderr.writeln('[coverage:baseline] WARNING: ...')` for malformed lcov records; skip the record, continue. Never throw on a single bad record (same as Phase 1 P1-10).

---

### `scripts/coverage_gate.dart` (utility, file-I/O → predicate → exit-code)

**Analog:** `scripts/audit/dead_code.dart` (envelope shape) + `scripts/merge_findings.dart` (deterministic sort + emit)

**No prior art for CLI argument parsing in this repo.** All existing scripts take either zero args (`arb_to_csv.dart`, `merge_findings.dart`) or pass-through args (`audit_*.sh`). The hybrid CLI (`[<file>...] [--list <path>] [--threshold N] [--lcov <path>] [--json]`) is new code. Recommended approach (planner decision):
- Use `package:args` from the SDK (zero new deps — shipped with Dart) **OR**
- Hand-roll a small parser since the CLI surface is small (5 flags + positional). `dart:io` `args` parameter is `List<String>` — no auto-parsing.

The hand-roll version is consistent with the lightweight `dart:convert` + `dart:io`-only style of `merge_findings.dart` and `arb_to_csv.dart`. Recommend hand-roll.

**CLI parsing skeleton** (greenfield, no analog — derived from D-01..D-04 contract):
```dart
Future<void> main(List<String> args) async {
  // Defaults from D-02/D-03.
  var threshold = 80;
  var lcovPath = 'coverage/lcov_clean.info';
  var emitJson = false;
  String? listPath;
  final positionals = <String>[];

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--threshold':
        threshold = int.parse(args[++i]);
      case '--lcov':
        lcovPath = args[++i];
      case '--list':
        listPath = args[++i];
      case '--json':
        emitJson = true;
      default:
        if (a.startsWith('--')) {
          stderr.writeln('[coverage:gate] ERROR: unknown flag: $a');
          exit(2);
        }
        positionals.add(a);
    }
  }

  // D-01 fallback chain: positionals ∪ --list ∪ files-needing-tests.txt
  final files = <String>{...positionals};
  if (listPath != null) {
    files.addAll(File(listPath).readAsLinesSync().where((l) => l.trim().isNotEmpty));
  }
  if (files.isEmpty) {
    final fallback = File('.planning/audit/files-needing-tests.txt');
    if (fallback.existsSync()) {
      files.addAll(fallback.readAsLinesSync().where((l) => l.trim().isNotEmpty));
    }
  }
  if (files.isEmpty) {
    stderr.writeln('[coverage:gate] ERROR: no files supplied (positional, --list, or fallback list all empty)');
    exit(2);
  }

  // D-03 actionable error if lcov source missing.
  if (!File(lcovPath).existsSync()) {
    stderr.writeln('[coverage:gate] ERROR: $lcovPath not found.');
    stderr.writeln('  Run: flutter test --coverage && coverde filter ...');
    exit(2);
  }
  // ... per-file percentage extraction reuses coverage_baseline.dart parser
}
```

**Process exit + error pattern** (`scripts/audit/dead_code.dart` lines 36-48):
```dart
final stdoutText = (result.stdout as String).trim();
if (stdoutText.isEmpty) {
  stderr.writeln(
    '[audit:dead_code] WARNING: $mode produced empty stdout; skipping',
  );
  return findings;
}
```
Apply: `[coverage:gate]` log prefix. Exit codes:
- `0` — all supplied files met threshold (D-04)
- `1` — at least one file failed (D-04 "Exit is non-zero whenever any supplied file falls below the threshold")
- `2` — invocation error (missing lcov, unknown flag, no files supplied) — distinct from threshold failure so CI can differentiate

**Output pattern (D-04 dual-track)**:
- Default human stdout: `path | covered/total | % | PASS|FAIL` table
- `--json` flag emits structured JSON to stdout (NOT to a file — the caller redirects). Schema: `{checked: [...], failures: [...], threshold: N, lcov_source: "..."}`. Reusing the `coverage_baseline.json` per-file record shape is the cleanest contract — same `{file_path, lines_covered, lines_total, percentage, threshold_met}` shape, no new vocabulary.

**Code reuse:** the lcov parser and per-file `% ` computation are identical to `coverage_baseline.dart`. Planner should extract a shared parser into a third file (e.g., `scripts/coverage/lcov_parser.dart`) consumed by both — mirrors Phase 1 `scripts/audit/finding.dart` shared model. **Without this extraction, the parser will be duplicated, violating coding-style.md "many small files" + dead_code/redundancy concerns from Phase 1.**

---

### `scripts/build_coverage_baseline.sh` (shell wrapper, command composition)

**Analog:** `scripts/test_audit_pipeline.sh`

**Full file pattern** (`scripts/test_audit_pipeline.sh` lines 1-19):
```bash
#!/usr/bin/env bash
# scripts/test_audit_pipeline.sh
# Local end-to-end run of the audit pipeline (mirrors `audit.yml` static-analysis job).
# Used by Plan 08 to verify the pipeline pre-commit and during /gsd-verify-work.
set -euo pipefail

echo "[audit:pipeline] running 4 tooling scanners..."
bash scripts/audit_layer.sh
bash scripts/audit_dead_code.sh
bash scripts/audit_providers.sh
bash scripts/audit_duplication.sh

echo "[audit:pipeline] merging shards..."
dart run scripts/merge_findings.dart

echo "[audit:pipeline] verifying outputs..."
test -f .planning/audit/issues.json
test -f .planning/audit/ISSUES.md
```

Apply to `build_coverage_baseline.sh`:
- `#!/usr/bin/env bash` shebang
- Header comment naming the local-equivalent CI job
- `set -euo pipefail` — fail fast (Phase 1 standard)
- `[coverage:baseline] ...` echo prefix
- Compose: `flutter test --coverage` → `coverde filter ...` → `dart run scripts/coverage_baseline.dart`
- `test -f .planning/audit/coverage-baseline.json` — verify outputs at end (Phase 1 P1-style verification)

**Simpler `audit_*.sh` exec-handoff pattern** (`scripts/audit_layer.sh` full file):
```bash
#!/usr/bin/env bash
# scripts/audit_layer.sh
# Runs custom_lint, filters to import_guard codes, emits .planning/audit/shards/layer.json
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
```
Useful pattern if the planner decides `build_coverage_baseline.sh` should be a thin wrapper around a single Dart command. CONTEXT calls this wrapper "optional" — if the planner judges the composition is simple enough (3 commands), a wrapper script may be unnecessary.

**File permissions:** `scripts/audit_*.sh` are `chmod +x` (`-rwxr-xr-x` per the `ls -la`). Planner must `chmod +x scripts/build_coverage_baseline.sh` if created.

---

### `.planning/audit/coverage-baseline.txt` (data artifact, TSV)

**Analog:** `.planning/audit/ISSUES.md` (twin-of-json human view, Phase 1 D-09 / D-10 lock)

**Format per CONTEXT D-11:** `path\tlines_covered/lines_total\tpercentage` per line, lex-sorted by path.

Example:
```
lib/core/theme/app_theme.dart	4/9	44.44
lib/features/accounting/domain/models/category.dart	2/2	100.00
lib/features/accounting/domain/models/transaction.dart	2/2	100.00
```

Conventions:
- Tab-separated (literal `\t`, not spaces) — keeps it grep/awk-friendly
- Percentage: 2-decimal precision (string formatting `.toStringAsFixed(2)`)
- No header row (machine-friendly; `coverage-baseline.json` is the schema-of-record)
- Trailing newline on the last line
- Lex-sorted by path (D-10)

---

### `.planning/audit/coverage-baseline.json` (data artifact, JSON)

**Analog:** `.planning/audit/issues.json`

**Issues.json structure** (`.planning/audit/issues.json` lines 1-16):
```json
{
  "findings": [
    {
      "id": "RD-001",
      "category": "redundant_code",
      "severity": "MEDIUM",
      "file_path": "lib/application/accounting/category_service.dart",
      "line_start": 1,
      "line_end": 1,
      "description": "...",
      ...
      "status": "open"
    },
```
Apply per CONTEXT D-11:
- Top-level metadata: `generated_at`, `flutter_test_command`, `lcov_source`, `threshold`, `total_files`, `files_below_threshold`
- Top-level array key: `entries` (or `coverage` — planner's call; recommend `entries` for symmetry with Phase 1's `findings`)
- Per-record fields: `file_path`, `lines_covered`, `lines_total`, `percentage`, `threshold_met`
- 2-space indent (`JsonEncoder.withIndent('  ')`)
- `snake_case` keys (Phase 1 SCHEMA.md §1 explicit rule)

**D-12 cross-link decoupling:** Do NOT add `issue_ids` cross-references to `issues.json`. Planner joins on `file_path` lazily.

---

### `.planning/audit/files-needing-tests.txt` (data artifact, path list)

**Analog:** No exact analog — derived view filtered from `coverage-baseline.txt`.

**Format per CONTEXT D-11:** bare path per line (no other columns), only files where `percentage < threshold`, lex-sorted.

Example:
```
lib/core/initialization/app_initializer.dart
lib/features/accounting/data/repositories/transaction_repository_impl.dart
lib/features/family_sync/use_cases/sync_now_use_case.dart
```

The planner reads this file directly during fix-phase scoping (D-09).

---

### `.planning/audit/files-needing-tests.json` (data artifact, JSON)

**Analog:** `.planning/audit/issues.json`

Apply per CONTEXT D-11:
- Same top-level metadata as `coverage-baseline.json`
- Per-record fields: `file_path`, `percentage`, `lines_below_threshold`
- `lines_below_threshold = lines_total - lines_covered`
- 2-space indent, `snake_case` keys, lex-sorted by `file_path`

---

### `.planning/audit/COVERAGE-SCHEMA.md` (optional, documentation)

**Analog:** `.planning/audit/SCHEMA.md`

**Header pattern** (`.planning/audit/SCHEMA.md` lines 1-9):
```markdown
# Audit Finding Schema

**Locked:** 2026-04-25
**Phase 1**

This document is the source-of-truth contract for every audit finding emitted in Phase 1 and consumed by every subsequent fix phase (Phases 3–6) and the Phase-8 re-audit. The Dart code mirror is [`scripts/audit/finding.dart`](../../scripts/audit/finding.dart) — field names match 1:1 between this doc and that file.
```
Apply: `# Coverage Baseline Schema` + `**Locked:** 2026-04-25` + `**Phase 2**` + intro pointing at `scripts/coverage_baseline.dart` as the code mirror.

**Field-table pattern** (`.planning/audit/SCHEMA.md` lines 14-29) — markdown table with `| Field | Type | Required | Valid Values / Notes | Example |` columns. Apply same shape to document the 5 per-record fields and 6 metadata fields.

**Decision:** Planner may inline a `## Coverage Baseline Schema` section into existing `SCHEMA.md` instead of creating a new file. CONTEXT calls this file "optional" — recommend the inline option to avoid doc proliferation, unless the schema doc grows >50 lines.

---

### `.github/workflows/audit.yml` (MODIFIED, CI config)

**Analog:** Self — modify the existing `coverage` job in place.

**Current `coverage` job** (`.github/workflows/audit.yml` lines 88-109):
```yaml
  coverage:
    runs-on: ubuntu-latest
    needs: static-analysis
    if: ${{ github.event_name == 'pull_request' }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: VeryGoodOpenSource/very_good_coverage@v2
        continue-on-error: true   # Phase 2 BASE-06 flips this blocking
        with:
          path: coverage/lcov.info
          min_coverage: 80
          exclude: |
            **/*.g.dart
            **/*.freezed.dart
            **/*.mocks.dart
            lib/generated/**
```

**Required modifications** (per CONTEXT canonical_refs line 100 and D-05):

1. **Add `coverde` activation in `coverage` job** (currently only in `static-analysis` line 29):
```yaml
      - run: dart pub global activate coverde 0.3.0+1
```
Insert after `flutter pub get`. The `coverage` job runs in a separate runner from `static-analysis` so the activation does not carry over. Alternative: factor into a composite action (declined per CONTEXT — keep duplication minimal and explicit).

2. **Add `coverde filter` step** producing `lcov_clean.info` (BEFORE `very_good_coverage`):
```yaml
      - name: Strip generated files from lcov
        run: |
          coverde filter \
            --input coverage/lcov.info \
            --output coverage/lcov_clean.info \
            --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
```
The exact `coverde filter` flag syntax must be verified during planning against `coverde 0.3.0+1` docs (CONTEXT canonical_refs line 103 explicitly notes "verify versions during planning"). Patterns must match the `analysis_options.yaml` exclude list + the existing `very_good_coverage` exclude list (the latter is the source of truth per CONTEXT code_context line 122).

3. **Update `very_good_coverage` `path:` to consume `lcov_clean.info`** (line 103):
```yaml
        with:
          path: coverage/lcov_clean.info   # was: coverage/lcov.info
```

4. **Remove `continue-on-error: true` from `very_good_coverage` step** (line 101) — D-05 flip-blocking. Update the inline comment to reflect the change:
```yaml
      - uses: VeryGoodOpenSource/very_good_coverage@v2
        # Phase 2 close: blocking. Threshold 80 against lcov_clean.info.
        with:
          path: coverage/lcov_clean.info
          min_coverage: 80
          exclude: |
            ...
```
The `exclude:` list inside `very_good_coverage` becomes redundant once `coverde filter` runs upstream — but keep it as defense-in-depth (mirrors Phase 1 D-09 idempotency: scanners filter, merger filters again). Optional planner choice: drop the `exclude:` block since `lcov_clean.info` is already filtered, OR keep it explicit for future readers.

5. **Add `dart run scripts/coverage_baseline.dart` step** (after `coverde filter`, before or after `very_good_coverage`):
```yaml
      - name: Generate coverage baseline artifacts
        run: dart run scripts/coverage_baseline.dart
```

6. **Upload the four `.planning/audit/coverage-*` artifacts** (mirrors `audit-issues` upload at lines 52-59):
```yaml
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-baseline
          path: |
            .planning/audit/coverage-baseline.txt
            .planning/audit/coverage-baseline.json
            .planning/audit/files-needing-tests.txt
            .planning/audit/files-needing-tests.json
```

7. **DO NOT add `coverage_gate.dart` step** in this phase (D-06 explicit defer to Phase 7/8).

**Inline-comment convention** for staged-blocking flips (Phase 1 D-04 marker, see `audit.yml` line 38):
```yaml
        continue-on-error: true   # Phase X exit gate flips this blocking (D-04)
```
Phase 2 removes the marker entirely once the flip happens. Other staged flips elsewhere in the file (lines 38, 41, 44) keep their markers — they are owned by Phases 3/4/6.

---

## Shared Patterns

### Logging prefix convention
**Source:** all `scripts/*.dart` and `scripts/*.sh` files
**Apply to:** every `coverage_baseline.dart` / `coverage_gate.dart` / `build_coverage_baseline.sh` log line
```dart
print('[coverage:baseline] wrote N entries to ...');
stderr.writeln('[coverage:baseline] WARNING: ...');
print('[coverage:gate] PASS lib/foo.dart 85.00%');
```
Format: `[<scope>:<script>]` — observed in `[audit:merge]`, `[audit:dead_code]`, `[audit:layer]`, `[audit:pipeline]`, `[audit:idempotency]`, `[audit:install]`. Phase 2 introduces the `coverage:` scope.

### Generated-file exclusion list
**Source:** `analysis_options.yaml` lines 22-24 (`**/*.g.dart`, `**/*.freezed.dart`) + `audit.yml` lines 105-109 (adds `**/*.mocks.dart`, `lib/generated/**`)
**Apply to:** `coverde filter` patterns AND `coverage_baseline.dart` defense-in-depth predicate
**Source of truth:** the four-pattern list in `audit.yml` `very_good_coverage.exclude` (CONTEXT code_context line 122):
```
**/*.g.dart
**/*.freezed.dart
**/*.mocks.dart
lib/generated/**
```
**Phase 2 D-stretch:** discover any `.drift.dart` files via `find lib -name '*.drift.dart'` during planning. If found, add to the exclusion list across `coverde filter`, `analysis_options.yaml` (suggested follow-up; out of scope for Phase 2), and the Dart-side `_isGenerated` predicate.

### Deterministic ordering for byte-identical reruns
**Source:** `scripts/merge_findings.dart` lines 70-79 (sort), 109-113 (`JsonEncoder.withIndent('  ')`); `scripts/test_idempotency.sh` (the test that proves the invariant)
**Apply to:** all four Phase-2 artifacts. CONTEXT D-12 ("Phase 2 idempotency") and CONTEXT specifics line 138 ("Idempotent reruns") make this a hard requirement Phase 8 depends on.
- Sort by `file_path` ascending using `String.compareTo` (stable, Unicode-defined)
- 2-space JSON indent
- `snake_case` JSON keys
- No `DateTime.now()` in artifacts EXCEPT the documented metadata field `generated_at` (CONTEXT D-11). Phase 8 byte-compare normalizes this field.
- **Optional Phase-2 add:** `scripts/test_coverage_idempotency.sh` mirroring `scripts/test_idempotency.sh` (run script twice, diff outputs, fail on diff). Strongly recommended given D-12.

### Twin-artifact (txt + json) emission
**Source:** Phase 1 D-09 / D-10 (`issues.json` + `ISSUES.md`)
**Apply to:** `coverage_baseline.dart` emits all 4 files (`*.txt` + `*.json` × 2 lists) in a single pass. Single source of truth: the in-memory list of per-file records is computed once, then projected to (a) full TSV, (b) full JSON, (c) filtered TSV, (d) filtered JSON.

### `.planning/audit/` artifact commit pattern
**Source:** Phase 1 — `.planning/audit/issues.json`, `.planning/audit/ISSUES.md`, `.planning/audit/SCHEMA.md` are checked into git (verified via `ls -la .planning/audit/`)
**Apply to:** all four `coverage-*` artifacts and `files-needing-tests-*` artifacts are committed. The `coverage/` directory itself stays gitignored (CONTEXT discretion line 54: "keep current behavior").

### Error-handling philosophy
**Source:** `scripts/merge_findings.dart` lines 33-50, `scripts/audit/dead_code.dart` lines 36-48, 132-135
**Apply to:** Phase-2 scripts
- Single bad input record → `stderr.writeln('[coverage:...] WARNING: ...')` + skip; never throw
- Whole-script error → `stderr.writeln('[coverage:...] ERROR: ...')` + non-zero exit
- Distinguish exit codes 1 (assertion failure / threshold not met) vs 2 (invocation error)
- Always include actionable next-step in error messages (D-03 example: `Run: flutter test --coverage && coverde filter ...`)

### Process exit codes for CI gate
**Source:** `scripts/audit/dead_code.dart` returns findings via `exit 0` always; the calling shell decides via merger output
**Apply to:** `coverage_gate.dart` — different model (it IS the gate, not a producer):
- `0` — pass (all files met threshold)
- `1` — gate failure (one+ files under threshold) — D-04
- `2` — invocation error (missing lcov, bad flag, no files)

---

## No Analog Found

Files / sub-patterns with no close match in the codebase:

| Pattern | Reason | Recommended approach |
|---|---|---|
| **lcov.info parsing** | No prior code in repo parses lcov format. Closest tool is `coverde` (CLI, used in CI). | Hand-roll a small parser inside `coverage_baseline.dart` (~50 LOC). Format is line-oriented, no edge cases beyond `LF`/`LH` desync defense. Reference: `coverage/lcov.info` lines 1-12 (sample shape captured above). |
| **Dart CLI flag parsing** | All existing scripts use either zero args or pass-through. | Hand-roll a small switch-based parser (sample skeleton above). Avoids adding `package:args` to `pubspec.yaml` (Phase 2 has zero-new-deps constraint per CONTEXT discretion / pubspec.yaml note in canonical_refs line 97). |
| **Bare-path-list output** (`files-needing-tests.txt`) | Every Phase-1 artifact is either rich-format markdown or rich-format JSON. | Trivial `outFile.writeAsString(paths.join('\n') + '\n')`. Lex-sorted (D-10). |

---

## Metadata

**Analog search scope:**
- `/Users/xinz/Development/home-pocket-app/scripts/` (12 files)
- `/Users/xinz/Development/home-pocket-app/scripts/audit/` (5 files)
- `/Users/xinz/Development/home-pocket-app/.planning/audit/` (committed Phase-1 artifacts)
- `/Users/xinz/Development/home-pocket-app/.github/workflows/` (1 file)
- `/Users/xinz/Development/home-pocket-app/coverage/` (lcov sample)
- `/Users/xinz/Development/home-pocket-app/analysis_options.yaml` (exclude list)

**Files scanned:** 18 total (12 scripts + 5 audit shards' source + 1 workflow)
**Pattern extraction date:** 2026-04-25
**CONTEXT.md analog claims validated:** 4/4 (all 4 analogs cited in CONTEXT exist at the cited paths and contain the expected patterns)
