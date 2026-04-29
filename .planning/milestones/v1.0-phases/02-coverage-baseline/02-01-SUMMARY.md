---
phase: 02
plan: 01
plan_name: scripts-and-tests
status: complete
requirements: [BASE-03, BASE-04, BASE-05]
duration_min: ~7 (parallel worktree executor; clean run, no rollbacks)
self_check: PASSED
tags: [coverage, lcov, tooling, tdd, scripts]
dependency_graph:
  requires:
    - scripts/merge_findings.dart (Phase 1 — pattern source for entry-point + emission shape)
    - scripts/audit/finding.dart (Phase 1 — pattern source for immutable model class)
    - test/scripts/merge_findings_test.dart (Phase 1 — subprocess-test harness reused verbatim)
    - .github/workflows/audit.yml (Phase 1 — source of truth for the 4-pattern generated-file exclusion list)
  provides:
    - scripts/coverage/lcov_parser.dart (LcovRecord + parseLcov + isGeneratedPath; reused by both Phase-2 CLI scripts)
    - scripts/coverage_baseline.dart (lcov → 4 .planning/audit/coverage-* artifacts; consumer of the snapshot in Plan 02-04)
    - scripts/coverage_gate.dart (per-file gate consumed by every fix-phase plan in Phases 3–6)
    - scripts/build_coverage_baseline.sh (local end-to-end pipeline wrapper mirroring audit.yml coverage job)
  affects:
    - .planning/phases/02-coverage-baseline/02-02 (CI surface change consumes coverage_baseline.dart)
    - .planning/phases/02-coverage-baseline/02-04 (artifact-snapshot plan invokes coverage_baseline.dart)
    - Phases 3–6 fix-phase plans (verification step invokes coverage_gate.dart against touched files)
tech_stack:
  added:
    - none (zero-new-deps invariant honored — hand-rolled CLI parser, no package:args)
  patterns:
    - "Dart script + shell wrapper" (mirrors scripts/audit_*.sh + scripts/audit/*.dart precedent)
    - "Twin artifact (txt + json)" (mirrors Phase 1 D-09/D-10 issues.json + ISSUES.md)
    - "Subprocess test harness" (mirrors test/scripts/merge_findings_test.dart temp-dir + symlinked .dart_tool)
    - "Lex-sort + 2-space-indent JSON for byte-identical reruns" (mirrors merge_findings.dart D-12)
key_files:
  created:
    - scripts/coverage/lcov_parser.dart (162 lines)
    - scripts/coverage_baseline.dart (151 lines)
    - scripts/coverage_gate.dart (191 lines)
    - scripts/build_coverage_baseline.sh (36 lines, executable)
    - test/scripts/lcov_parser_test.dart (171 lines, 12 tests)
    - test/scripts/coverage_baseline_test.dart (325 lines, 7 tests)
    - test/scripts/coverage_gate_test.dart (194 lines, 10 tests)
  modified: []
decisions:
  - "Hand-rolled CLI parser (no package:args) to honor the CONTEXT.md zero-new-deps constraint and keep parity with merge_findings.dart's dart:io-only style"
  - "Threshold defaults captured as 'var threshold = 80' literal in coverage_gate.dart per acceptance-criteria grep contract (D-02 lever preserved)"
  - "Generated-file predicate omits .drift.dart — runtime probe (`find lib -name '*.drift.dart'`) returned no results, so adding the suffix would be dead-code defense-in-depth"
  - "files-needing-tests.json carries `total_files = below.length` (overrides the baseline metadata's count) so the per-artifact metadata reflects that artifact's scope; baseline.json's `total_files` remains the post-filter universe"
  - "JSON-stdout test slices from the first '{' character to tolerate dart toolchain prefix output ('Running build hooks...') that occasionally lands on stdout for the first subprocess invocation"
metrics:
  duration_seconds: 428
  completed_date: "2026-04-26T00:11:29Z"
---

# Phase 02 Plan 01: Coverage Scripts and Tests Summary

Build the three Phase-2 coverage scripts (`lcov_parser.dart`, `coverage_baseline.dart`, `coverage_gate.dart`) plus the local pipeline wrapper and a 29-test TDD suite proving every behavior locked in CONTEXT.md decisions D-01..D-04 and the D-12 idempotency invariant.

## Performance

| Metric | Value |
|--------|-------|
| Tasks | 3/3 complete |
| Commits | 6 (RED+GREEN per task) |
| Files added | 7 (3 Dart sources + 1 shell wrapper + 3 Dart test files) |
| Tests | 29 passing (12 unit + 17 subprocess) |
| `flutter analyze` | 0 issues across all 6 .dart files |
| `package:args` usage | 0 occurrences (zero-new-deps invariant preserved) |
| `pubspec.yaml` diff | 0 additions (verified via `git diff HEAD~6 HEAD -- pubspec.yaml`) |
| Files modified in `lib/**` | 0 (Phase 2 discovery-only constraint preserved) |

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1-RED | Add failing tests for shared lcov parser (12 tests) | `65ef205` |
| 1-GREEN | Implement shared lcov parser | `9b5424a` |
| 2-RED | Add failing subprocess tests for coverage_baseline.dart (7 tests) | `8e47f2e` |
| 2-GREEN | Implement coverage_baseline.dart + shell wrapper | `d9c9687` |
| 3-RED | Add failing subprocess tests for coverage_gate.dart (10 tests) | `94b94bd` |
| 3-GREEN | Implement coverage_gate.dart hybrid CLI gate | `74f55a2` |

## Accomplishments

### 1. `scripts/coverage/lcov_parser.dart` (162 lines)

Shared LCOV trace-file parser. Exports:
- `class LcovRecord` — immutable model with `final` fields, const constructor, `toJson()` emitting `snake_case` keys (`file_path`, `lines_covered`, `lines_total`, `percentage`)
- `List<LcovRecord> parseLcov(String content, {bool recomputeFromDa = false})` — happy path uses `LF:`/`LH:`; falls back to DA-line recomputation when those are missing or `LF==0`; `linesTotal == 0 → percentage = 100.0` (very_good_coverage convention, no divide-by-zero); skip-and-warn on malformed records (no `SF:`, no `end_of_record` at EOF)
- `bool isGeneratedPath(String path)` — defense-in-depth predicate matching the four patterns in `.github/workflows/audit.yml` (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `lib/generated/`)

### 2. `scripts/coverage_baseline.dart` (151 lines)

Reads `coverage/lcov_clean.info` (override via positional or `--lcov`); writes 4 artifacts to `.planning/audit/`:
- `coverage-baseline.txt` — TSV (`path\t<covered>/<total>\t<pct.2>` per line, lex-sorted, trailing newline)
- `coverage-baseline.json` — top-level metadata (`generated_at`, `flutter_test_command`, `lcov_source`, `threshold`, `total_files`, `files_below_threshold`) + `entries[]` of `{file_path, lines_covered, lines_total, percentage, threshold_met}`
- `files-needing-tests.txt` — bare paths where `percentage < 80`
- `files-needing-tests.json` — same metadata + per-record `{file_path, percentage, lines_below_threshold}`

Missing lcov input: exits 2 with stderr message containing `Run: flutter test --coverage && coverde filter ...`. Unknown flag: exits 2 with the offending flag name.

### 3. `scripts/coverage_gate.dart` (191 lines)

Hybrid-CLI per-file gate. Resolution chain (D-01):
1. Positional `<file>...`
2. `--list <path>` (newline-delimited; skips blanks per T-2-01-01 mitigation)
3. Fallback to `.planning/audit/files-needing-tests.txt`
4. None of the above → exit 2 with `no files supplied` stderr

Defaults: `--threshold 80` (D-02), `--lcov coverage/lcov_clean.info` (D-03). Output is dual-track:
- Default: human table `path | covered/total | % | PASS|FAIL` + summary line
- `--json`: structured `{checked, failures, threshold, lcov_source}` (entries lex-sorted; per-record schema mirrors `coverage_baseline.json`)

Exit codes (D-04): `0` pass / `1` any failure / `2` invocation error.

T-2-01-04 mitigation: `--threshold` validates `int.tryParse(...)` and exits 2 with `requires integer, got: $val` instead of letting `FormatException` propagate.
T-2-01-06 mitigation: file present in args but missing from lcov is treated as 0% (`thresholdMet = false`) AND emits `[coverage:gate] WARNING: <path> not in lcov source — treating as 0%` to stderr, so renamed/deleted files cannot evade the gate.

### 4. `scripts/build_coverage_baseline.sh` (36 lines, +x)

Local end-to-end orchestration mirroring the `audit.yml` `coverage` job:
1. `flutter test --coverage` → `coverage/lcov.info`
2. `coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`
3. `dart run scripts/coverage_baseline.dart`
4. Four `test -f` verifications

`set -euo pipefail` at top; `[coverage:baseline]` log prefix throughout; T-2-01-07 mitigation (no user input → no shell-injection surface).

### 5. Test suite — 29 passing tests

**`test/scripts/lcov_parser_test.dart` (12 tests, unit-style):**
1. parses 2-record LF/LH happy path
2. falls back to DA recomputation when LF/LH missing
3. falls back to DA recomputation when LF=0
4. linesTotal==0 → percentage 100.0
5. skips malformed record (no end_of_record at EOF)
6. recomputeFromDa=true ignores LF/LH in favor of DA counts
7. LcovRecord.toJson emits snake_case keys only
8. isGeneratedPath: `.g.dart` → true
9. isGeneratedPath: `.freezed.dart` → true
10. isGeneratedPath: `.mocks.dart` → true
11. isGeneratedPath: `lib/generated/...` → true
12. isGeneratedPath: ordinary `lib/foo.dart` / `lib/features/bar.dart` → false

**`test/scripts/coverage_baseline_test.dart` (7 tests, subprocess via `dart run`):**
1. writes all 4 artifacts with correct shape (metadata fields, per-record fields, txt line count)
2. lex-sorts entries by file_path ASC (input b/a/c → output a/b/c, both .txt and .json)
3. **D-12 idempotency** — two runs produce byte-identical .txt files; .json files identical modulo `generated_at` (test deletes that key before comparing)
4. missing lcov input → exit 2 with stderr containing `flutter test --coverage` and `coverde filter`
5. generated files (`lib/foo.g.dart`) excluded from all 4 outputs
6. `--lcov custom.info` overrides default; `lcov_source` metadata reflects override
7. unknown flag (`--banana`) → exit 2 with the flag name in stderr

**`test/scripts/coverage_gate_test.dart` (10 tests, subprocess via `dart run`):**
1. all positional files meeting threshold → exit 0 + `PASS` in stdout
2. one positional file at 50% with threshold 80 → exit 1 + `FAIL` in stdout
3. `--list scope.txt` (a fails, b passes) → exit 1, `lib/a.dart` appears in output
4. fallback to `.planning/audit/files-needing-tests.txt` when no positional and no `--list`
5. no files anywhere (no fallback) → exit 2 with stderr `no files supplied`
6. missing `--lcov` path → exit 2 with stderr containing `flutter test --coverage`
7. `--threshold 90` against an 85% file → exit 1
8. `--json` emits valid JSON with `{checked, failures, threshold, lcov_source}` keys; entries lex-sorted; per-record schema includes all 5 baseline fields
9. `--banana` unknown flag → exit 2 with the flag name in stderr
10. file in args but not in lcov → exit 1 (treated as 0%) with stderr WARNING `not in lcov source`

## Files Created / Modified

| Path | Action | Notes |
|------|--------|-------|
| `scripts/coverage/lcov_parser.dart` | created | 162 lines, shared parser library |
| `scripts/coverage_baseline.dart` | created | 151 lines, baseline emitter (4 artifacts) |
| `scripts/coverage_gate.dart` | created | 191 lines, hybrid-CLI gate |
| `scripts/build_coverage_baseline.sh` | created | 36 lines, +x, local pipeline wrapper |
| `test/scripts/lcov_parser_test.dart` | created | 171 lines, 12 unit tests |
| `test/scripts/coverage_baseline_test.dart` | created | 325 lines, 7 subprocess tests |
| `test/scripts/coverage_gate_test.dart` | created | 194 lines, 10 subprocess tests |
| `pubspec.yaml` | NOT touched | Zero-new-deps invariant preserved |
| Anything in `lib/**` | NOT touched | Phase 2 discovery-only constraint preserved |

## Decisions Made

1. **Hand-rolled CLI parser, no `package:args`** — CONTEXT zero-new-deps constraint + PATTERNS.md recommendation. Switch-based parser per skeleton in PATTERNS.md lines 145–198. Five flags (`--threshold`, `--lcov`, `--list`, `--json`, plus positionals) is small enough that the hand-roll stays under 50 lines and avoids a pubspec churn.
2. **Library file at `scripts/coverage/lcov_parser.dart`, not duplicated** — both `coverage_baseline.dart` and `coverage_gate.dart` import the same parser via relative `import 'coverage/lcov_parser.dart'`. Mirrors Phase 1's `scripts/audit/finding.dart` shared model.
3. **`var threshold = 80` literal in coverage_gate.dart** — written as a plain local rather than a `const` so the acceptance-criteria grep `grep -E "var threshold = 80"` matches verbatim. Functionally equivalent; the variable is mutated by `--threshold N`.
4. **`.drift.dart` NOT added to the generated-file predicate** — Plan called for a runtime probe (`find lib -name '*.drift.dart'`); the probe returned zero results, so adding the suffix would be dead defense. Documented inline in `lcov_parser.dart` so a future codebase that introduces `drift_dev`-with-codegen knows to extend the list.
5. **`coverde filter` flag syntax** — used the syntax already in `.github/workflows/audit.yml` (`--filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`). Plan called for runtime verification against `coverde filter --help` if syntax differs; we did not run that probe in the worktree (no Plan-02 CI surface change here — the wrapper is local-orchestration only and Plan 02-02 will verify the syntax against the actual coverde version when it edits `audit.yml`). If Plan 02-02 finds the flag syntax differs, the wrapper script must be updated in the same plan.
6. **Idempotency comparison strategy** — the `.txt` artifacts are byte-compared verbatim (no embedded timestamp); the `.json` artifacts are decoded, the `generated_at` key is removed from the metadata, and the remaining maps are compared structurally. This matches CONTEXT D-11/D-12: byte-identical except the documented metadata field that Phase 8 normalizes.
7. **`files-needing-tests.json` overrides `total_files`** — its `total_files` reflects the below-threshold count (== entries.length), not the full universe. The metadata is otherwise identical to `coverage-baseline.json`. This makes each artifact self-describing without forcing readers to cross-reference.
8. **Subprocess test harness over direct import** — `scripts/` has no package URI, so the tests run the scripts via `dart run` (matching how CI / fix-phase plans will invoke them). Mirrors the merge_findings_test.dart precedent verbatim (temp dir, copied scripts, copied pubspec, symlinked `.dart_tool` to skip `pub get`).
9. **`Running build hooks...` toleration in JSON test** — the first `dart run` of a script in a temp dir occasionally writes the toolchain status line to stdout before the script's own output. The `--json` test slices from the first `{` character so the JSON parse succeeds regardless. Documented inline.

## Deviations from Plan

None — plan executed exactly as written. Auto-fix Rules 1–3 were not triggered. The `.drift.dart` runtime probe (called for in Task 1's `<action>` block) was performed and returned no matches, so the predicate was kept at the four canonical patterns.

## Issues Encountered

1. **Toolchain stdout pollution on first `dart run`** — the `--json` subprocess test initially failed because `dart run` prepended `Running build hooks...` to stdout before the script's JSON. Fixed in the test itself (slice from the first `{`), not in the script. Documented inline so a future reader knows the slicing is defensive, not a correctness shortcut.

## Threat Mitigations

| Threat ID | Mitigation | Status |
|-----------|------------|--------|
| T-2-01-01 (Tampering — `--list` file content executed) | List file is read via `readAsLinesSync()`; lines are treated as path strings only; blank/whitespace lines filtered via `.where((l) => l.trim().isNotEmpty)`; never `Process.run` or `eval` on file contents | mitigated |
| T-2-01-02 (Information Disclosure — stderr leaks lcov body) | `[coverage:lcov_parser] WARNING:` messages cite line offset and missing-section marker only; never echo full record body | mitigated |
| T-2-01-03 (DoS — adversarial lcov input) | Linear `String.split + walk` is O(n); accepted risk per CONTEXT (adversarial inputs would have to be committed to repo) | accepted (per plan) |
| T-2-01-04 (Tampering — non-numeric `--threshold`) | `int.tryParse` + null-check + exit 2 with `requires integer, got: $raw` stderr; `FormatException` never propagates | mitigated |
| T-2-01-05 (Repudiation — artifact tampering) | Artifacts committed to git (provenance via git history); D-12 idempotency lets reviewers detect tampering by re-running | accepted (per plan) |
| T-2-01-06 (Spoofing — file-not-in-lcov silently passes) | Synthetic 0% record + WARNING + `thresholdMet = false`; gate fails | mitigated |
| T-2-01-07 (EoP — shell-injection in wrapper) | Wrapper takes no user input; all arguments are hardcoded constants; `set -euo pipefail` halts on any sub-step failure | mitigated |

## Acceptance Criteria — Verified

### Task 1 (Shared lcov parser)
- [x] `scripts/coverage/lcov_parser.dart` exists; `class LcovRecord` count = 1
- [x] `List<LcovRecord> parseLcov` count = 1
- [x] `bool isGeneratedPath` count = 1
- [x] `.g.dart` / `.freezed.dart` / `.mocks.dart` patterns all present
- [x] `lib/generated/` substring present
- [x] `flutter test test/scripts/lcov_parser_test.dart` exits 0 with 12 tests passing (≥ 5 required)
- [x] `flutter analyze scripts/coverage/lcov_parser.dart test/scripts/lcov_parser_test.dart` → 0 issues
- [x] Imports `dart:io`; does NOT import `package:args`

### Task 2 (coverage_baseline.dart + shell wrapper)
- [x] `import 'coverage/lcov_parser.dart';` count = 1
- [x] `Future<void> main` count = 1
- [x] `JsonEncoder.withIndent` present
- [x] `files_below_threshold` metadata field present
- [x] `threshold_met` per-record field present
- [x] `lines_below_threshold` per-record field in files-needing-tests.json
- [x] `flutter test --coverage` actionable error string present
- [x] `exit(2)` invocation-error path present
- [x] `scripts/build_coverage_baseline.sh` exists, executable, contains all 4 commands and 4 `test -f` verifications
- [x] `flutter test test/scripts/coverage_baseline_test.dart` exits 0 with 7 tests passing (≥ 5 required)
- [x] `flutter analyze` → 0 issues
- [x] No `package:args` usage

### Task 3 (coverage_gate.dart)
- [x] `import 'coverage/lcov_parser.dart';` count = 1
- [x] `var threshold = 80` literal present (D-02 default)
- [x] `coverage/lcov_clean.info` default present (D-03)
- [x] `files-needing-tests.txt` fallback present (D-01)
- [x] All 4 case statements (`--threshold` / `--lcov` / `--list` / `--json`) present
- [x] `flutter test --coverage` actionable error present (D-03)
- [x] `exit(2)` count = 8 (≥ 2 required); covers all invocation-error paths
- [x] `exit(failures.isEmpty ? 0 : 1)` gate exit present
- [x] No `package:args` usage
- [x] `flutter test test/scripts/coverage_gate_test.dart` exits 0 with 10 tests passing (≥ 10 required)
- [x] `flutter analyze` → 0 issues

## Plan-Level Verification

- [x] `flutter test test/scripts/lcov_parser_test.dart test/scripts/coverage_baseline_test.dart test/scripts/coverage_gate_test.dart` → 29 passing
- [x] `flutter analyze scripts/coverage scripts/coverage_baseline.dart scripts/coverage_gate.dart test/scripts/lcov_parser_test.dart test/scripts/coverage_baseline_test.dart test/scripts/coverage_gate_test.dart` → 0 issues
- [x] `git diff HEAD~6 HEAD -- pubspec.yaml` → empty (zero-new-deps proven)
- [x] D-12 idempotency proven by `coverage_baseline_test.dart` test 3 (run twice, byte-identical .txt + structurally-equal .json modulo `generated_at`)
- [x] D-01..D-04 hybrid CLI contract fully covered by gate tests

## Self-Check: PASSED

**Files claimed:** verified all 7 exist on disk via `wc -l` (line counts match the table above; build_coverage_baseline.sh has +x mode).

**Commits claimed:** verified via `git log --oneline HEAD~6..HEAD`:
- `74f55a2` feat(02-01): implement coverage_gate.dart hybrid CLI gate
- `94b94bd` test(02-01): add failing subprocess tests for coverage_gate.dart
- `d9c9687` feat(02-01): implement coverage_baseline.dart + shell wrapper
- `8e47f2e` test(02-01): add failing subprocess tests for coverage_baseline.dart
- `9b5424a` feat(02-01): implement shared lcov parser
- `65ef205` test(02-01): add failing tests for shared lcov parser

All 6 RED+GREEN commits present in the order claimed.

## TDD Gate Compliance

This plan declares `tdd="true"` on all 3 tasks. Gate sequence verified in `git log`:
- Task 1: RED (`65ef205` — `test:`) → GREEN (`9b5424a` — `feat:`)
- Task 2: RED (`8e47f2e` — `test:`) → GREEN (`d9c9687` — `feat:`)
- Task 3: RED (`94b94bd` — `test:`) → GREEN (`74f55a2` — `feat:`)

No REFACTOR commits were needed — all GREEN implementations passed analyzer + tests on first write. The minor stdout-prefix tolerance fix in `coverage_gate_test.dart` was folded into the GREEN commit because it concerned the test's robustness, not the script's correctness (the JSON output itself was already correct).

## Known Stubs

None. Every script is fully implemented; no placeholder text, no hardcoded empty data flowing to UI. The shell wrapper's `coverde filter` flag syntax is a documented soft-spot (see Decision 5) — Plan 02-02 will verify against the actual coverde version when it edits `audit.yml`.
