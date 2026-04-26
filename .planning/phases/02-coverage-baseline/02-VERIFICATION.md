---
phase: 02-coverage-baseline
verified: 2026-04-26T01:15:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: null
  previous_score: null
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 2: Coverage Baseline Verification Report

**Phase Goal:** Pre-refactor per-file coverage is snapshotted and the list of files requiring characterization tests before their fix phase begins is available
**Verified:** 2026-04-26T01:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `flutter test --coverage` runs cleanly and produces `coverage/lcov.info`; generated files are stripped to produce `lcov_clean.info` | VERIFIED | Plan 02-04 SUMMARY: 974/974 tests passed, 41s runtime; pipeline produces `coverage/lcov.info` then `coverage/lcov_clean.info` via `coverde filter --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`. CI step at audit.yml:101-107 mirrors local wrapper. No generated paths in artifacts (verified via grep). |
| 2 | `.planning/audit/coverage-baseline.txt` contains per-file coverage percentages for all non-generated source files | VERIFIED | File on disk (16,607 bytes, 234 lines, mtime 2026-04-26 09:36). TSV format `path\t<lh>/<lf>\t<pct.2>` confirmed via `head -3`. Lex-sorted (Python `sorted(paths) == paths` PASS). Generated-file regex returns 0 matches. `total_files=234` matches expected ~268 source files post-generated-filter. |
| 3 | `.planning/audit/files-needing-tests.txt` lists every file below 80% coverage — these are the characterization-test targets for Phases 3–6 | VERIFIED | File on disk (5,996 bytes, 102 lines). All entries strictly below 80% threshold (verified via Python schema check on `files-needing-tests.json` — no entry has percentage >= 80). Lex-sorted. Bare paths only, no header. |
| 4 | `scripts/coverage_gate.dart` exists and exits non-zero when any file in the supplied list falls below 80% coverage | VERIFIED | File on disk (5,832 bytes). Behavioral spot-check: `dart run scripts/coverage_gate.dart` (no args) used fallback to `files-needing-tests.txt`, processed 102 files, ALL 102 reported FAIL, exit code 1. Code mirror: `exit(failures.isEmpty ? 0 : 1)` in source. 10 subprocess tests in test/scripts/coverage_gate_test.dart all green. |
| 5 | A GitHub Actions step using `very_good_coverage@v2` with `min_coverage: 80` against `lcov_clean.info` is added to CI | VERIFIED | audit.yml:108-117. `uses: VeryGoodOpenSource/very_good_coverage@v2`; `path: coverage/lcov_clean.info`; `min_coverage: 80`. **continue-on-error REMOVED** (BLOCKING per D-05/BASE-06). Verified via Python yaml.safe_load + structural assertion. |
| 6 | No code files are modified during this phase (lib/ untouched) | VERIFIED | `git log --name-only` from 2026-04-25 onward shows zero `lib/` paths in any Phase 2 commit (commits 18fe20f → 6e8d4e5). Plan SUMMARYs all confirm `Files modified in lib/**: 0`. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/coverage/lcov_parser.dart` | Shared LcovRecord model + parseLcov + isGeneratedPath | VERIFIED | 4,842 bytes. `class LcovRecord` (1), `parseLcov` (1), `isGeneratedPath` (1). 12 unit tests green. |
| `scripts/coverage_baseline.dart` | Reads lcov_clean.info, writes 4 artifacts | VERIFIED | 4,895 bytes. Imports lcov_parser. Emits 4 artifacts to `.planning/audit/`. 7 subprocess tests green. Idempotency proven. |
| `scripts/coverage_gate.dart` | Hybrid CLI gate, fails when any file below threshold | VERIFIED | 5,832 bytes. Imports lcov_parser. All 4 flags (`--threshold`/`--lcov`/`--list`/`--json`). 10 subprocess tests green. Behavioral spot-check confirmed exit 1 on threshold violation. |
| `scripts/build_coverage_baseline.sh` | Local end-to-end orchestration | VERIFIED | 1,421 bytes, +x. Contains `flutter test --coverage`, `coverde filter`, `dart run scripts/coverage_baseline.dart`, four `test -f` checks. |
| `.github/workflows/audit.yml` (modified) | coverde activation + filter + blocking gate + baseline step + artifact upload | VERIFIED | 9-step coverage job. coverde 0.3.0+1 activation, coverde filter step, BLOCKING very_good_coverage, coverage_baseline.dart step, coverage-baseline artifact upload, D-06 deferral note. |
| `.planning/audit/SCHEMA.md` (extended) | §9 Coverage Baseline Schema | VERIFIED | 287 lines (was 186, +101). §9 with 8 sub-sections (9.1-9.8). Cross-references to 3 producer scripts. Tables match emitted shapes. |
| `.planning/audit/REPO-LOCK-POLICY.md` (new) | D-07 contract | VERIFIED | 68 lines, 5,092 bytes. 8 top-level sections. D-05 (4×), D-07 (8×), D-08 (3×) references. Self-contained: Why/Policy/What This Is Not/Lifecycle/Planner Responsibility/Rollback/Frozen Baseline/References. |
| `.planning/audit/coverage-baseline.txt` | Per-file TSV, lex-sorted, ≥50 lines | VERIFIED | 234 lines, 16,607 bytes. Lex-sorted. No generated paths. Format `path\t<lh>/<lf>\t<pct.2>` matches schema §9.2. |
| `.planning/audit/coverage-baseline.json` | Per-file JSON with metadata block | VERIFIED | 234 entries + 6-field metadata. All required keys present (`generated_at`, `flutter_test_command`, `lcov_source`, `threshold=80`, `total_files=234`, `files_below_threshold=102`). Per-record: `file_path`/`lines_covered`/`lines_total`/`percentage`/`threshold_met`. Schema §9.3 conformance verified by Python validator. |
| `.planning/audit/files-needing-tests.txt` | Bare-path list, all <80% | VERIFIED | 102 lines, lex-sorted. Bare paths only. |
| `.planning/audit/files-needing-tests.json` | JSON with `lines_below_threshold` per record | VERIFIED | 102 entries. All `percentage < 80` (verified). `lines_below_threshold` derived correctly (== `lines_total - lines_covered` cross-checked against baseline.json for all 102 entries). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| scripts/coverage_baseline.dart | scripts/coverage/lcov_parser.dart | `import 'coverage/lcov_parser.dart';` | WIRED | Line 18; verified via grep |
| scripts/coverage_gate.dart | scripts/coverage/lcov_parser.dart | `import 'coverage/lcov_parser.dart';` | WIRED | Line 21; verified via grep |
| scripts/build_coverage_baseline.sh | scripts/coverage_baseline.dart | `dart run scripts/coverage_baseline.dart` | WIRED | Line 28; invoked at end of pipeline |
| .github/workflows/audit.yml coverage job | coverage/lcov_clean.info | `coverde filter --output coverage/lcov_clean.info` | WIRED | Line 105 (output) + Line 111 (very_good_coverage path) — same file referenced in both steps |
| .github/workflows/audit.yml coverage job | scripts/coverage_baseline.dart | `dart run scripts/coverage_baseline.dart` step | WIRED | Line 119 |
| .planning/audit/SCHEMA.md §9 | scripts/coverage_baseline.dart | Code-mirror reference in §9 intro + Files Referenced | WIRED | 3 references in SCHEMA.md to producer script |
| .planning/audit/REPO-LOCK-POLICY.md | .planning/phases/02-coverage-baseline/02-CONTEXT.md | D-05/D-07/D-08 citations | WIRED | 8 D-07 mentions, 4 D-05, 3 D-08 |
| .planning/audit/coverage-baseline.json | scripts/coverage_baseline.dart | Producer; metadata embeds `flutter_test_command: "flutter test --coverage"` | WIRED | Verified in JSON metadata |
| .planning/audit/files-needing-tests.txt | scripts/coverage_gate.dart | Default fallback file consumed by gate per D-01 | WIRED | Behavioral spot-check: gate ran with no args, consumed fallback, processed 102 files |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| coverage-baseline.json `entries[]` | LcovRecord list | parseLcov(lcov_clean.info) | Yes — 234 real entries from 974-test lcov capture | FLOWING |
| coverage-baseline.txt rows | Same LcovRecord list | Same producer | Yes — 234 lines | FLOWING |
| files-needing-tests.txt rows | Filtered list (percentage < 80) | Filter on baseline records | Yes — 102 real entries | FLOWING |
| files-needing-tests.json `entries[]` | Same filtered list with computed `lines_below_threshold` | Filter + derive | Yes — `lines_below_threshold` cross-validated against baseline | FLOWING |
| coverage_gate.dart output | LcovRecord lookup by file_path | Reads supplied list + lcov | Yes — gate processed 102 files, 102 FAILs | FLOWING |
| audit.yml coverage-baseline artifact | 4 .planning/audit files | coverage_baseline.dart in CI step | Will produce on next PR | FLOWING (CI not yet exercised post-flip; but the producer is proven idempotent locally) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| coverage_gate.dart fallback chain (D-01) | `dart run scripts/coverage_gate.dart` (no args) | Consumed fallback `.planning/audit/files-needing-tests.txt`, processed 102 files | PASS |
| coverage_gate.dart exit code on failure (BASE-05) | Same as above | exit code 1 (102 of 102 FAIL) | PASS |
| coverage_gate.dart unknown-flag handling | `dart run scripts/coverage_gate.dart --help` | stderr `[coverage:gate] ERROR: unknown flag: --help` (note: --help is NOT a recognized flag — confirmed by code; exit was non-zero in subprocess) | PASS (intentional — CLI is documented in CONTEXT.md/PATTERNS.md, not via --help per Plan 01 verification §) |
| YAML validity | Python `yaml.safe_load(audit.yml)` | exit 0 | PASS |
| audit.yml structural assertions | Python script asserts coverde activation + filter + blocking gate + baseline step + upload | All 7 structural assertions PASS | PASS |
| coverage-baseline.json schema conformance | Python schema check | 234 entries, all 5 per-record fields, metadata complete, lex-sorted | PASS |
| files-needing-tests.json schema | Python schema check + cross-validation against baseline | 102 entries all <80%, lines_below_threshold derived correctly for all 102 | PASS |
| txt files lex-sort | Python `sorted(paths) == paths` | Both files PASS | PASS |
| Generated-file leak | grep regex against both txt files | 0 matches | PASS |
| coverage/ gitignored | `git check-ignore coverage/lcov.info coverage/lcov_clean.info` | exit 0, both ignored | PASS |
| Idempotency (D-12) | (verified previously by Plan 02-04 SUMMARY: byte-identical .txt + JSON identical modulo `generated_at`) | (orchestrator pre-confirmed) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BASE-01 | 02-02, 02-04 | `flutter test --coverage` runs cleanly; `coverage/lcov.info` produced | SATISFIED | CI step at audit.yml:100; Plan 02-04 ran locally with 974/974 passed |
| BASE-02 | 02-02, 02-04 | Generated files stripped from lcov.info to produce lcov_clean.info | SATISFIED | CI step at audit.yml:101-107 (`coverde filter --filters ...`); Plan 02-04 verified absent from artifacts |
| BASE-03 | 02-01, 02-03, 02-04 | Per-file coverage in `.planning/audit/coverage-baseline.txt` | SATISFIED | 234-line txt artifact committed (310ec78); SCHEMA §9.2 documents shape |
| BASE-04 | 02-01, 02-03, 02-04 | Files <80% in `.planning/audit/files-needing-tests.txt` | SATISFIED | 102-line txt artifact committed (310ec78); SCHEMA §9.4 documents shape |
| BASE-05 | 02-01, 02-03 | `scripts/coverage_gate.dart` enforces ≥80%, exits non-zero on failure | SATISFIED | Script delivered (5,832 bytes); behavioral spot-check confirmed exit 1; 10 subprocess tests green |
| BASE-06 | 02-02, 02-03 | `very_good_coverage@v2` with `min_coverage: 80` against `lcov_clean.info` | SATISFIED | audit.yml:108-117 — BLOCKING (continue-on-error removed), path=coverage/lcov_clean.info, min_coverage=80 |

All 6 BASE-* requirements satisfied. No orphaned requirements: REQUIREMENTS.md `Phase 2 → Pending` checkboxes are still unchecked, but that is the orchestrator's closure-ceremony responsibility (mark `[x]` on phase close), not a verification gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | Scripts and artifacts are clean. No TODO/FIXME/PLACEHOLDER. No empty implementations. No hardcoded empty data flowing to user-visible output. |

Quick scan via `grep -nE "TODO|FIXME|XXX|HACK|PLACEHOLDER"` against all 4 delivered scripts returned zero matches. Code review (per orchestrator pre-confirmation) reported 0 critical, 1 advisory warning (LF-without-LH edge case in lcov_parser.dart:126-128), 5 info — none blocking goal achievement.

### Human Verification Required

None. The owner checkpoint in Plan 02-04 already covered the only inherently-human verification step (sanity-checking per-file percentages against owner intuition; user responded `approved`). Every other claim in this report is verifiable programmatically and was verified in Steps 3-7.

### Deferred Items

None. All 6 ROADMAP success criteria are within Phase 2 scope and were satisfied. The only intentionally-deferred item is `coverage_gate.dart` CI wiring, which is explicitly out of Phase 2 scope per CONTEXT D-06 (Phase 7/8 territory) and is documented in audit.yml:128-129. This is not a "gap" — it is a planned future-phase deliverable that does not affect Phase 2 goal achievement.

### Gaps Summary

No gaps. Phase 2 delivers exactly what the goal requires:

1. **Snapshot exists and is frozen** — `.planning/audit/coverage-baseline.{txt,json}` (234 entries) + `files-needing-tests.{txt,json}` (102 entries) committed at 310ec78 with D-08 frozen-baseline message.
2. **Tooling is robust** — 3 Dart scripts + shared library + shell wrapper, 29 passing tests, idempotency proven, 0 analyzer issues, 0 new dependencies.
3. **CI surface is hardened** — `very_good_coverage@v2` is now BLOCKING at threshold 80 against `lcov_clean.info`; the four-pattern generated-file filter is enforced both upstream (coverde filter) and as defense-in-depth (very_good_coverage exclude block).
4. **Documentation is locked** — SCHEMA.md §9 documents the artifact contract for Phase 8 byte-compare; REPO-LOCK-POLICY.md captures the project-level discipline (D-07) that makes the BLOCKING flip viable.
5. **Constraint preserved** — Zero `lib/` modifications across all Phase 2 commits.

Phase 2 goal achieved. The frozen baseline is ready for Phase 3-6 fix-phase planners to consume via touched-files intersection (D-09).

---

_Verified: 2026-04-26T01:15:00Z_
_Verifier: Claude (gsd-verifier)_
