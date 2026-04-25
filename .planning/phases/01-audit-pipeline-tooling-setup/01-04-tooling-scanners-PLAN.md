---
phase: 01-audit-pipeline-tooling-setup
plan: 04
type: execute
wave: 2
depends_on: [01, 03]
files_modified:
  - scripts/audit/layer.dart
  - scripts/audit/dead_code.dart
  - scripts/audit/providers.dart
  - scripts/audit/duplication.dart
  - scripts/audit_layer.sh
  - scripts/audit_dead_code.sh
  - scripts/audit_providers.sh
  - scripts/audit_duplication.sh
autonomous: true
requirements: [AUDIT-02, AUDIT-06]
tags: [scanners, audit-cli, dart-script, custom-lint]

must_haves:
  truths:
    - "Each of the 4 audit scripts (`audit_layer.sh`, `audit_dead_code.sh`, `audit_providers.sh`, `audit_duplication.sh`) is individually invocable from project root"
    - "Each `.sh` wrapper is a single-line `exec dart run scripts/audit/<dim>.dart \"$@\"` per RESEARCH Pattern 1"
    - "Each Dart core writes a JSON shard to `.planning/audit/shards/<dim>.json` matching the schema in scripts/audit/finding.dart (snake_case keys; tool_source set; status defaults to 'open')"
    - "Each scanner reads result.stdout ONLY (Pitfall P1-8 — custom_lint prints status to stderr)"
    - "Each scanner respects generated-file exclusion (skips `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`)"
    - "audit_duplication.sh is a Phase-1 stub emitting an empty findings array (D-01.b — duplication is delegated to Plan 06's AI agent; jscpd / native CPD not adopted)"
    - "Each `.sh` is `chmod +x` and passes `bash -n` syntax check"
  artifacts:
    - path: "scripts/audit_layer.sh"
      provides: "Layer-violation scanner CLI wrapper"
      contains: "exec dart run scripts/audit/layer.dart"
    - path: "scripts/audit_dead_code.sh"
      provides: "Dead-code scanner CLI wrapper"
    - path: "scripts/audit_providers.sh"
      provides: "Provider-hygiene scanner CLI wrapper"
    - path: "scripts/audit_duplication.sh"
      provides: "Duplication scanner CLI wrapper (stub in Phase 1)"
    - path: "scripts/audit/layer.dart"
      provides: "Dart core for layer scan; runs `dart run custom_lint --reporter=json` and filters to import_guard codes"
      contains: "import_guard"
    - path: "scripts/audit/dead_code.dart"
      provides: "Dart core for dead-code scan; runs `dart_code_linter:metrics check-unused-{code,files}` with JSON reporter"
    - path: "scripts/audit/providers.dart"
      provides: "Dart core for provider-hygiene scan; runs `dart run custom_lint --reporter=json` filtered to riverpod_lint codes"
    - path: "scripts/audit/duplication.dart"
      provides: "Dart core for duplication scan (Phase 1 stub — emits empty findings array)"
  key_links:
    - from: "scripts/audit_<dim>.sh"
      to: "scripts/audit/<dim>.dart"
      via: "exec'd via `dart run scripts/audit/<dim>.dart`"
      pattern: "exec dart run"
    - from: "scripts/audit/<dim>.dart"
      to: "scripts/audit/finding.dart (Plan 03)"
      via: "Relative import `import 'finding.dart';`"
      pattern: "import 'finding.dart'"
    - from: "scripts/audit/<dim>.dart"
      to: ".planning/audit/shards/<dim>.json"
      via: "Writes the shard via `File(...).writeAsString(jsonEncode(...))`"
      pattern: "shards/.*\\.json"
---

<objective>
Build the 4 tooling scanners that AUDIT-06 names. Each scanner is a thin POSIX shell wrapper around a Dart core (RESEARCH Pattern 1 + PATTERNS Group C), writes a JSON shard to `.planning/audit/shards/<dim>.json` in the schema locked by Plan 03's `scripts/audit/finding.dart`, and is invocable individually from the project root.

Three of the four scanners wrap real tools:
- `audit_layer.sh` → `dart run custom_lint --reporter=json`, filter to `import_guard*` codes
- `audit_providers.sh` → `dart run custom_lint --reporter=json`, filter to `riverpod_lint*` codes
- `audit_dead_code.sh` → `dart run dart_code_linter:metrics check-unused-code lib --reporter=json` AND `check-unused-files lib --reporter=json`

The fourth (`audit_duplication.sh`) is a Phase-1 stub. Per CONTEXT.md D-01.b ("semantic duplication / parallel implementations") + RESEARCH §"Standard Stack — 1. Tooling Verification" alternatives table, native Dart duplication tooling is not adopted; the AI agent in Plan 06 handles this dimension. The scanner exists to satisfy AUDIT-06's "individually invocable" requirement and to keep the merger's input-set static — it emits an empty findings array.

Purpose:
- AUDIT-06: scanners exist and are individually invocable
- AUDIT-02 (final piece): the layer scanner is what surfaces `import_guard*` findings into the shard set; rules from Plan 02 are wired to a producer here

Output:
- 4 `.sh` wrappers in `scripts/`
- 4 `.dart` cores in `scripts/audit/`
- Each Dart core uses plain Dart classes (NO `@freezed` — Plan 03's Pitfall P1-7 echo)
- Each Dart core writes to `.planning/audit/shards/<dim>.json` with the schema from `scripts/audit/finding.dart`
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@.planning/audit/SCHEMA.md
@scripts/audit/finding.dart
@scripts/arb_to_csv.dart
@analysis_options.yaml
@.planning/phases/01-audit-pipeline-tooling-setup/01-01-SUMMARY.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-02-SUMMARY.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-03-SUMMARY.md

<interfaces>
<!-- Verbatim wrapper template + Dart core skeleton from RESEARCH §"Code Examples — Example 1" + Pattern 1. -->

POSIX wrapper template (RESEARCH §"Architecture Patterns — Pattern 1"; PATTERNS Group C, all 4 wrappers identical except dimension name):
```bash
#!/usr/bin/env bash
# scripts/audit_<dim>.sh
# <one-line description>
set -euo pipefail
exec dart run scripts/audit/<dim>.dart "$@"
```

Dart core skeleton (RESEARCH §"Code Examples — Example 1" — `audit/layer.dart` shape):
```dart
// scripts/audit/<dim>.dart
import 'dart:convert';
import 'dart:io';

import 'finding.dart';

const _generatedFileGlobs = [
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
];

bool _isGenerated(String path) =>
    _generatedFileGlobs.any(path.endsWith) ||
    path.contains('lib/generated/');

Future<void> main(List<String> args) async {
  // 1. Run the underlying tool with JSON output.
  final result = await Process.run(
    'dart',
    ['run', 'custom_lint', '--reporter=json'],
    runInShell: true,
  );

  // 2. Parse stdout ONLY (Pitfall P1-8 — custom_lint prints status to stderr).
  final stdout = result.stdout as String;
  final lints = jsonDecode(stdout) as List<dynamic>;

  // 3. Filter to this dimension's lint codes + drop generated files.
  final findings = lints
      .where((d) => _isLayerCode((d as Map)['code'] as String))
      .where((d) => !_isGenerated(((d as Map)['location'] as Map)['file'] as String))
      .map(_toFinding)
      .toList();

  // 4. Ensure output dir exists (RESEARCH Pattern from arb_to_csv.dart lines 31–33).
  final shardDir = Directory('.planning/audit/shards');
  if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

  // 5. Write shard.
  final shardPath = '.planning/audit/shards/<dim>.json';
  await File(shardPath).writeAsString(JsonEncoder.withIndent('  ').convert({
    'tool_source': '<tool_source>',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'findings': findings.map((f) => f.toJson()).toList(),
  }));

  print('[audit:<dim>] wrote ${findings.length} findings to $shardPath');
}

bool _isLayerCode(String code) => code.startsWith('import_guard');

Finding _toFinding(dynamic diag) {
  final d = diag as Map<String, dynamic>;
  final loc = d['location'] as Map<String, dynamic>;
  return Finding(
    category: 'layer_violation',
    severity: 'CRITICAL',
    filePath: (loc['file'] as String).replaceFirst('${Directory.current.path}/', ''),
    lineStart: (loc['range']['start']['line'] as int) + 1,
    lineEnd: (loc['range']['end']['line'] as int) + 1,
    description: d['problemMessage'] as String,
    rationale: 'Layer violation flagged by ${d['code']}',
    suggestedFix: d['correctionMessage'] as String? ?? 'Move/refactor to satisfy the layer rule.',
    toolSource: 'import_guard',
    confidence: 'high',
  );
}
```

Tool-source / category / severity defaults per scanner (must mirror SCHEMA.md §6):
| Scanner | tool_source | category | severity default | confidence default |
|---------|-------------|----------|------------------|---------------------|
| layer.dart | `import_guard` | `layer_violation` | `CRITICAL` (per RESEARCH severity-classification table) | `high` |
| providers.dart | `riverpod_lint` | `provider_hygiene` | `HIGH` | `high` |
| dead_code.dart | `dart_code_linter` | `dead_code` | `LOW` (raise to MEDIUM if unused-files match orphan pattern) | `high` |
| duplication.dart (stub) | `dart_code_linter` | `redundant_code` | `MEDIUM` | `high` (zero entries in stub) |

Pitfall P1-9 (severity drift): each scanner locks severity at the scanner level via these defaults. The merger does NOT recompute severity from descriptions.

Pitfall P1-8: read `result.stdout` only; `result.stderr` contains plugin-discovery and timing logs.

Pitfall A2 in RESEARCH "Assumptions Log": `dart run custom_lint --reporter=json` is supported per pub.dev README but version-specific verification is at execution time. If the JSON reporter doesn't return a parseable stdout (returns empty list, returns non-JSON, etc.), fall back to a graceful empty array (the scanner emits `{"findings": []}`) and prints a stderr warning. The shard file MUST always be written so the merger sees it.

`dart_code_linter:metrics` JSON reporter (Assumption A3): if the `--reporter=json` flag returns malformed output in 3.0.0, fall back to the plain-text reporter and parse the human-readable lines. The shard file MUST always be written.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create the 4 POSIX shell wrappers (audit_layer.sh, audit_dead_code.sh, audit_providers.sh, audit_duplication.sh)</name>
  <files>scripts/audit_layer.sh, scripts/audit_dead_code.sh, scripts/audit_providers.sh, scripts/audit_duplication.sh</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Architecture Patterns — Pattern 1" + §"Code Examples — Example 1"
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group C — POSIX wrapper" (5-line template)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Shared Patterns — Shell script header"
    - scripts/install_audit_tools.sh (Plan 01 Task 3 — confirms scripts/ shell-script style for the project)
  </read_first>
  <action>
    Create 4 shell wrappers at `scripts/audit_<dim>.sh`. Each is exactly the 5-line template from RESEARCH §"Code Examples — Example 1":

    **scripts/audit_layer.sh:**
    ```bash
    #!/usr/bin/env bash
    # scripts/audit_layer.sh
    # Runs custom_lint, filters to import_guard codes, emits .planning/audit/shards/layer.json
    set -euo pipefail
    exec dart run scripts/audit/layer.dart "$@"
    ```

    **scripts/audit_dead_code.sh:**
    ```bash
    #!/usr/bin/env bash
    # scripts/audit_dead_code.sh
    # Runs dart_code_linter check-unused-{code,files}, emits .planning/audit/shards/dead_code.json
    set -euo pipefail
    exec dart run scripts/audit/dead_code.dart "$@"
    ```

    **scripts/audit_providers.sh:**
    ```bash
    #!/usr/bin/env bash
    # scripts/audit_providers.sh
    # Runs custom_lint, filters to riverpod_lint codes, emits .planning/audit/shards/providers.json
    set -euo pipefail
    exec dart run scripts/audit/providers.dart "$@"
    ```

    **scripts/audit_duplication.sh:**
    ```bash
    #!/usr/bin/env bash
    # scripts/audit_duplication.sh
    # Phase-1 stub: duplication detection is delegated to AI agent (CONTEXT.md D-01.b).
    # Emits empty findings array to keep the merger's input-set static.
    set -euo pipefail
    exec dart run scripts/audit/duplication.dart "$@"
    ```

    Then make all 4 executable:
    ```bash
    chmod +x scripts/audit_layer.sh scripts/audit_dead_code.sh scripts/audit_providers.sh scripts/audit_duplication.sh
    ```

    Validate syntax:
    ```bash
    for f in scripts/audit_layer.sh scripts/audit_dead_code.sh scripts/audit_providers.sh scripts/audit_duplication.sh; do
      bash -n "$f" || exit 1
    done
    ```

    DO NOT add additional logic to the wrappers. RESEARCH Pattern 1 specifies single-line `exec` only — every Dart core does the real work. No flag parsing, no env-var setup, no preprocessing in the shell wrapper.
  </action>
  <verify>
    <automated>for f in scripts/audit_layer.sh scripts/audit_dead_code.sh scripts/audit_providers.sh scripts/audit_duplication.sh; do test -x "$f" && bash -n "$f" && grep -q "^set -euo pipefail$" "$f" && grep -q "^exec dart run" "$f" || exit 1; done</automated>
  </verify>
  <acceptance_criteria>
    - 4 wrapper files exist
    - All 4 are executable: `for f in scripts/audit_{layer,dead_code,providers,duplication}.sh; do [ -x "$f" ] || exit 1; done`
    - All 4 have shebang `#!/usr/bin/env bash` on line 1
    - All 4 use `set -euo pipefail`
    - All 4 use `exec dart run scripts/audit/<dim>.dart "$@"` (no other logic)
    - `bash -n` parses each cleanly
    - Wrapper-to-Dart name mapping correct: `audit_layer.sh → layer.dart`, `audit_dead_code.sh → dead_code.dart`, `audit_providers.sh → providers.dart`, `audit_duplication.sh → duplication.dart`
  </acceptance_criteria>
  <done>
    All 4 POSIX wrappers exist, are executable, parse cleanly, and follow the locked single-line `exec dart run` pattern. Plan 04 Task 2 fills in the Dart cores.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create the 4 Dart cores (layer.dart, providers.dart, dead_code.dart, duplication.dart)</name>
  <files>scripts/audit/layer.dart, scripts/audit/providers.dart, scripts/audit/dead_code.dart, scripts/audit/duplication.dart</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Code Examples — Example 1" (audit/layer.dart skeleton, lines 397–423) AND §"Common Pitfalls — P1-8" (stdout-only) AND §"Common Pitfalls — P1-9" (severity lock at scanner level) AND §"Assumptions Log A2/A3" (JSON reporter fallback)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group C" (Dart core pattern derived from arb_to_csv.dart) + §"Shared Patterns — Process invocation pattern"
    - scripts/audit/finding.dart (Plan 03 Task 1 output — the canonical Finding class to import relatively)
    - .planning/audit/SCHEMA.md (Plan 03 Task 2 output — tool-source inventory + severity defaults table)
    - scripts/arb_to_csv.dart (sole precedent for `Directory(...).createSync(recursive: true)` + `print(...)` summary line)
  </read_first>
  <action>
    Create 4 Dart cores in `scripts/audit/`. Each follows the skeleton in this plan's `<interfaces>` block (RESEARCH §"Code Examples — Example 1") with these per-scanner specializations:

    **scripts/audit/layer.dart** (uses `dart run custom_lint --reporter=json`, filters to `import_guard*` codes):
    - tool_source: `'import_guard'`
    - category: `'layer_violation'`
    - severity: `'CRITICAL'`
    - confidence: `'high'`
    - shard path: `.planning/audit/shards/layer.json`
    - Code filter: `code.startsWith('import_guard')`

    **scripts/audit/providers.dart** (same custom_lint invocation, filters to `riverpod*` codes):
    - tool_source: `'riverpod_lint'`
    - category: `'provider_hygiene'`
    - severity: `'HIGH'`
    - confidence: `'high'`
    - shard path: `.planning/audit/shards/providers.json`
    - Code filter: `code.startsWith('riverpod')`

    **scripts/audit/dead_code.dart** (runs `dart_code_linter:metrics check-unused-code lib --reporter=json` and `check-unused-files lib --reporter=json`; merges results):
    - tool_source: `'dart_code_linter'`
    - category: `'dead_code'`
    - severity: `'LOW'` (Phase 6 territory)
    - confidence: `'high'`
    - shard path: `.planning/audit/shards/dead_code.json`
    - Implementation:
      ```dart
      final unusedCode = await Process.run('dart', ['run', 'dart_code_linter:metrics', 'check-unused-code', 'lib', '--reporter=json'], runInShell: true);
      final unusedFiles = await Process.run('dart', ['run', 'dart_code_linter:metrics', 'check-unused-files', 'lib', '--reporter=json'], runInShell: true);
      // Concat findings from both invocations, drop generated-file matches, write shard.
      ```
    - Per Assumption A3, if `--reporter=json` produces malformed output in `dart_code_linter 3.0.0`, fall back to plain-text parsing. The shard MUST always be written; on parse failure, write `{"findings": []}` and emit a stderr warning prefixed `[audit:dead_code] WARNING:`.

    **scripts/audit/duplication.dart** (Phase-1 stub):
    - tool_source: `'dart_code_linter'` (matches SCHEMA.md inventory)
    - category: `'redundant_code'`
    - severity: default not used (zero findings)
    - confidence: default not used
    - shard path: `.planning/audit/shards/duplication.json`
    - Implementation:
      ```dart
      // scripts/audit/duplication.dart
      // Phase 1 stub: duplication detection delegated to AI agent (CONTEXT.md D-01.b).
      import 'dart:convert';
      import 'dart:io';

      Future<void> main(List<String> args) async {
        final shardDir = Directory('.planning/audit/shards');
        if (!shardDir.existsSync()) shardDir.createSync(recursive: true);

        final shardPath = '.planning/audit/shards/duplication.json';
        await File(shardPath).writeAsString(JsonEncoder.withIndent('  ').convert({
          'tool_source': 'dart_code_linter',
          'generated_at': DateTime.now().toUtc().toIso8601String(),
          'findings': <Map<String, dynamic>>[],
          'note': 'Phase 1 stub — duplication detection delegated to AI agent per CONTEXT.md D-01.b',
        }));

        print('[audit:duplication] wrote 0 findings (Phase-1 stub) to $shardPath');
      }
      ```

    **All 4 cores must:**
    1. Start with file-path comment: `// scripts/audit/<dim>.dart`
    2. Imports ordered per CONVENTIONS.md: `dart:convert` + `dart:io` first; blank line; `import 'finding.dart';` (relative) — except duplication.dart stub which doesn't need Finding
    3. Read `result.stdout` ONLY — never concatenate `result.stderr` (Pitfall P1-8)
    4. Apply generated-file filter (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`) before mapping to Finding
    5. Use `Directory(...).createSync(recursive: true)` to ensure shard dir exists (defense-in-depth — Plan 03 already creates it)
    6. Use `JsonEncoder.withIndent('  ')` for the shard output (matches Plan 05 merger style)
    7. Convert absolute file paths to repo-relative (strip `Directory.current.path` prefix)
    8. End with `print('[audit:<dim>] wrote <N> findings to <path>');` (RESEARCH Pattern from arb_to_csv.dart line 34)
    9. **NO `@freezed`, NO `@JsonSerializable`** — keeps `scripts/` build-runner-free (Pitfall P1-7)
    10. Format with `dart format` after writing

    **Error handling:** wrap the Process.run + JSON parse in try/catch. On any exception, write the shard with `{"findings": [], "scan_failed": true, "error": "<message>"}` and exit 0 (per RESEARCH §"Security Domain — V7" — never silently swallow; logged failures keep the merger working). Exit 1 only on truly unrecoverable filesystem errors.

    Run a smoke check to verify each scanner is invocable from the project root:
    ```bash
    bash scripts/audit_layer.sh
    bash scripts/audit_dead_code.sh
    bash scripts/audit_providers.sh
    bash scripts/audit_duplication.sh
    ```

    After each invocation, the corresponding shard file should exist:
    ```bash
    test -f .planning/audit/shards/layer.json
    test -f .planning/audit/shards/dead_code.json
    test -f .planning/audit/shards/providers.json
    test -f .planning/audit/shards/duplication.json
    ```

    Each shard file must be valid JSON with a top-level `findings` array:
    ```bash
    for f in .planning/audit/shards/{layer,dead_code,providers,duplication}.json; do
      python3 -c "import json; assert isinstance(json.load(open('$f'))['findings'], list)" || exit 1
    done
    ```

    DO NOT modify any `lib/**/*.dart` file (discovery-only constraint).
  </action>
  <verify>
    <automated>for f in scripts/audit/layer.dart scripts/audit/providers.dart scripts/audit/dead_code.dart scripts/audit/duplication.dart; do test -f "$f" && dart analyze "$f" || exit 1; done && bash scripts/audit_layer.sh && bash scripts/audit_dead_code.sh && bash scripts/audit_providers.sh && bash scripts/audit_duplication.sh && for s in layer dead_code providers duplication; do test -f .planning/audit/shards/$s.json && python3 -c "import json; d=json.load(open('.planning/audit/shards/$s.json')); assert isinstance(d['findings'],list); assert d['tool_source']" || exit 1; done</automated>
  </verify>
  <acceptance_criteria>
    - 4 Dart cores exist: `for f in scripts/audit/{layer,providers,dead_code,duplication}.dart; do test -f "$f" || exit 1; done`
    - Each Dart file passes `dart analyze`: `for f in <list>; do dart analyze "$f" || exit 1; done`
    - Each Dart file is dart-formatted: `dart format --output=none --set-exit-if-changed scripts/audit/`
    - NO `@freezed` / `@JsonSerializable` in any: `! grep -r "@freezed\\|@JsonSerializable" scripts/audit/`
    - layer.dart imports finding.dart: `grep -q "import 'finding.dart'" scripts/audit/layer.dart`
    - layer.dart filters import_guard codes: `grep -q "import_guard" scripts/audit/layer.dart`
    - providers.dart filters riverpod codes: `grep -q "riverpod" scripts/audit/providers.dart`
    - dead_code.dart invokes dart_code_linter: `grep -q "dart_code_linter:metrics" scripts/audit/dead_code.dart`
    - duplication.dart is the explicit Phase-1 stub: `grep -q "Phase 1 stub\\|Phase-1 stub" scripts/audit/duplication.dart`
    - Each scanner runs end-to-end: `bash scripts/audit_<dim>.sh` exits 0 for all 4 (with possibly an error written to the shard's `scan_failed` field — see Action point on error handling — but the script itself exits 0)
    - Each scanner produces a shard file with valid JSON containing a `findings` array (possibly empty for duplication.dart and possibly empty for the others if zero violations)
    - Each shard has the canonical `tool_source` value matching SCHEMA.md §6 inventory
    - layer.json `tool_source == "import_guard"`, providers.json `tool_source == "riverpod_lint"`, dead_code.json `tool_source == "dart_code_linter"`, duplication.json `tool_source == "dart_code_linter"`
    - No `lib/**/*.dart` modified
  </acceptance_criteria>
  <done>
    The 4 Dart cores invoke their underlying tools, filter findings, drop generated files, write valid JSON shards in the locked schema, and the corresponding `.sh` wrappers run end-to-end with the shards landing in `.planning/audit/shards/`. Plan 05's merger has 4 deterministic shard files to consume.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| External tool stdout (custom_lint, dart_code_linter) → scanner | Untrusted text input; parsed as JSON |
| Scanner → JSON shard file (`.planning/audit/shards/`) | File integrity boundary; CI consumes these |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-04-01 | Input Validation | Malformed JSON from `dart run custom_lint --reporter=json` | mitigate | try/catch around `jsonDecode`; on failure, write `{"findings": [], "scan_failed": true}` shard and emit stderr warning. RESEARCH §"V7 Error Handling" + Pitfall P1-8. |
| T-1-04-02 | Information Disclosure | Findings emitted with absolute paths revealing developer machine layout | mitigate | Strip `Directory.current.path` prefix from all `file_path` values before writing — defense-in-depth alongside SCHEMA.md §1 documentation |
| T-1-04-03 | Tampering | Generated-file findings (e.g., `.g.dart`) leaking into shards and confusing fix planners | mitigate | Each Dart core applies the `_isGenerated()` filter (RESEARCH §"Generated-file & ARB exclusions") in addition to the merger's defense-in-depth filter (Plan 05) |
| T-1-04-04 | Denial of Service | Long-running scanner hanging CI | accept | `dart run custom_lint` typical wall-clock <60s; if a scanner hangs, the GitHub Actions job timeout (default 6h, can lower to 10min in Plan 07) catches it. Phase 1 does not introduce per-scanner timeouts; revisit if Plan 08 dry-run shows real hang risk. |
| T-1-04-05 | Pitfall P1-9 (severity drift) | Scanner emitting wrong severity for known lint codes | mitigate | Each scanner hard-codes its severity default (locked at scanner level per RESEARCH Pitfall P1-9). The merger does NOT recompute severity. |

T-1-A (audit shards revealing sensitive paths): scanners only scan `lib/` Dart code; no secrets, API keys, or PII enter findings. Confirmed.
</threat_model>

<verification>
1. All 4 wrappers + 4 Dart cores exist, are executable / dart-analyzable
2. All 4 wrappers run end-to-end, producing shard files in `.planning/audit/shards/`
3. Each shard is valid JSON with a `findings` array and the canonical `tool_source` field
4. Each scanner respects generated-file exclusion
5. Each scanner reads `result.stdout` only (Pitfall P1-8 satisfied)
6. layer.dart's findings reflect Plan 02's `import_guard.yaml` rules (the Thin-Feature rule should surface the live `lib/features/family_sync/use_cases/` violation per CONCERNS.md)
7. providers.dart's findings reflect any live `riverpod_lint` violations on the unmodified codebase
8. duplication.dart emits the explicit Phase-1 stub message
9. No `lib/**/*.dart` modified
</verification>

<success_criteria>
- AUDIT-06 satisfied: each of `audit_layer.sh`, `audit_dead_code.sh`, `audit_providers.sh`, `audit_duplication.sh` is individually invocable from project root and produces a JSON shard in the locked schema
- AUDIT-02 fully wired: Plan 02's `import_guard.yaml` rules now have a producer (`audit_layer.sh`) that surfaces findings into the shard set; the layer-rule encoding is complete and observable
- 4 deterministic shards in `.planning/audit/shards/` are ready inputs for Plan 05's `merge_findings.dart`
- Plan 06 (AI agents) and Plan 05 (merger) can independently start work because the shard format / category / severity defaults are locked
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-04-SUMMARY.md` describing:
- The 4 wrappers + 4 Dart cores added
- The actual finding counts each scanner produces on the unmodified codebase (e.g., "audit_layer.sh produced 14 findings; audit_providers.sh produced 6; …")
- Any deviations from the JSON-reporter fallback (RESEARCH Assumption A2/A3) — if `custom_lint --reporter=json` failed and required plain-text parsing, document the parser path
- Any rule misconfigurations surfaced from Plan 02 (e.g., a Domain whitelist that needed to extend to `package:ulid/**`)
</output>
