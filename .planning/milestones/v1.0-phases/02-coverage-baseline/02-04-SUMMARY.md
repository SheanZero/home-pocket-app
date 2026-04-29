---
phase: 02-coverage-baseline
plan: 04
plan_name: freeze-baseline
status: complete
requirements: [BASE-01, BASE-02, BASE-03, BASE-04]
duration_min: ~10 (sequential executor; 41 s flutter test --coverage + verification + commit)
self_check: PASSED
tags: [snapshot, baseline, artifacts, frozen]
dependency_graph:
  requires:
    - scripts/build_coverage_baseline.sh (Plan 02-01 — pipeline orchestration wrapper)
    - scripts/coverage_baseline.dart (Plan 02-01 — lcov-to-artifact producer)
    - scripts/coverage/lcov_parser.dart (Plan 02-01 — shared parser)
    - .github/workflows/audit.yml (Plan 02-02 — coverde filter syntax confirmed identical to wrapper)
    - .planning/audit/SCHEMA.md §9 (Plan 02-03 — schema the artifacts conform to)
    - .planning/audit/REPO-LOCK-POLICY.md (Plan 02-03 — D-07 contract referenced in commit message)
    - coverde 0.3.0+1 (globally activated; pinned by `dart pub global activate coverde 0.3.0+1`)
  provides:
    - .planning/audit/coverage-baseline.txt (FROZEN per-file coverage TSV, 234 entries, lex-sorted)
    - .planning/audit/coverage-baseline.json (FROZEN machine-readable baseline + 6-field metadata block)
    - .planning/audit/files-needing-tests.txt (FROZEN <80% target list, 102 paths, lex-sorted)
    - .planning/audit/files-needing-tests.json (FROZEN <80% list with lines_below_threshold sizing signal)
  affects:
    - Phases 3-6 fix-phase planners (consume files-needing-tests.txt via touched-files intersection per D-09)
    - Phase 8 re-audit (will overwrite all 4 files; the diff is the empirical evidence cleanup raised coverage)
    - Repo-lock window (D-07): now OPERATIONALLY ACTIVE — only cleanup-roadmap PRs merge until Phase 6 close
tech_stack:
  added: []
  patterns:
    - "End-to-end pipeline execution via the Plan-01 shell wrapper (mirrors audit.yml coverage job)"
    - "FROZEN artifact pattern (D-08): commit once, do not regenerate until Phase 8 re-audit"
    - "Idempotency-proven baseline (D-12): re-running coverage_baseline.dart yields byte-identical .txt and JSON-modulo-generated_at"
key_files:
  created:
    - .planning/audit/coverage-baseline.txt (234 lines)
    - .planning/audit/coverage-baseline.json (2,109 lines, 234 entries + metadata)
    - .planning/audit/files-needing-tests.txt (102 lines)
    - .planning/audit/files-needing-tests.json (515 lines, 102 entries + metadata)
  modified: []
decisions:
  - "Did NOT halt-and-investigate the macOS sort -c locale-disorder warning at line 46 (app_theme.dart vs app_theme_colors.dart): the artifacts ARE byte-level lex-sorted (matching Dart's String.compareTo), proven by Python sorted(paths) == paths on both JSONs. The macOS default-locale sort treats `_` and `.` differently than ASCII; LC_ALL=C sort -c passes cleanly. Documented as a tooling quirk, not a real disorder."
  - "Used the SECOND (idempotency) run's outputs as the committed artifacts (the first-run files were copied to /tmp for the diff comparison; the diff was clean, then the second-run outputs remained in place). Functionally indistinguishable from first-run outputs except for the `generated_at` metadata timestamp, which Phase 8 byte-compare normalizes per D-12."
  - "Activated coverde 0.3.0+1 locally via `dart pub global activate` (was missing from the local environment though pinned in CI). The activation is idempotent — coverde was already-activated per pub-cache state but not on the shell PATH; exported `$HOME/.pub-cache/bin` for the pipeline run."
metrics:
  total_files: 234
  files_below_threshold: 102
  ratio: 43.59%
  flutter_test_runtime_seconds: 41
  flutter_tests_passed: 974
  flutter_tests_failed: 0
  duration_seconds: ~600
  completed_date: "2026-04-26T00:40:34Z"
---

# Phase 02 Plan 04: Freeze Coverage Baseline Summary

Ran the Phase 2 baseline pipeline end-to-end against the unmodified codebase (974 tests, all green) and committed the four FROZEN `.planning/audit/coverage-*` artifacts as the canonical "before" image (D-08). The committed baseline now drives every Phases 3–6 fix-phase plan via touched-files intersection (D-09) and is the comparison target for the Phase 8 re-audit diff.

## Frozen Baseline Numbers

| Metric | Value | Expected Range | Status |
|---|---|---|---|
| `total_files` | **234** | 200–300 | IN RANGE |
| `files_below_threshold` | **102** | 80–220 | IN RANGE |
| ratio (below / total) | **43.59%** | 30–80% | IN RANGE |
| `threshold` | 80 | (locked at 80) | matches |
| `flutter_test_command` | `flutter test --coverage` | (locked) | matches |
| `lcov_source` | `coverage/lcov_clean.info` | (locked, post-coverde-filter) | matches |

No magnitude divergence. No halt-and-investigate triggered.

## Pipeline Execution

| Stage | Command | Result |
|---|---|---|
| 1. Test suite + lcov | `flutter test --coverage` | 974 passed, 0 failed, 41 s |
| 2. Generated-file strip | `coverde filter --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'` | `coverage/lcov_clean.info` produced |
| 3. Artifact emission | `dart run scripts/coverage_baseline.dart` | 4 files written to `.planning/audit/`, "234 entries (102 below threshold)" |
| 4. Existence check | `test -f` × 4 | all pass |
| 5. Idempotency re-run | `dart run scripts/coverage_baseline.dart` | byte-identical .txt; JSON identical modulo `generated_at` |

The wrapper (`scripts/build_coverage_baseline.sh`) handled steps 1–4 in one invocation; step 5 was a manual re-run for the D-12 idempotency proof.

## Pre-flight Checks (all PASS)

| Check | Result |
|---|---|
| Plan 01 deliverables present (3 .dart files + executable wrapper) | OK |
| `audit.yml` references `coverage_baseline.dart` | 1 match |
| `SCHEMA.md` §9 present | 1 match |
| `REPO-LOCK-POLICY.md` exists | OK |
| `coverde --version` (after activation) | works (responds to subcommands) |
| Stale outputs cleaned (lcov + 4 artifacts) | OK |

## Post-run Sanity Checks (all PASS)

| Check | Result |
|---|---|
| All 4 artifacts exist | OK |
| `coverage-baseline.txt` line count ≥ 50 | 234 |
| `coverage-baseline.json` schema (Python validation) | 234 entries, all 5 per-record fields present, metadata complete |
| `files-needing-tests.json` schema (Python validation) | 102 entries, all percentages strictly < 80, `lines_below_threshold` present |
| No generated paths leaked (`grep -E '\.g\.dart\|\.freezed\.dart\|\.mocks\.dart\|lib/generated/'`) | 0 matches in either txt |
| Lex-sort on JSON entries (`sorted(paths) == paths`) | OK on both JSONs |
| Idempotency: txt files byte-identical across runs | `diff` exits 0 for both txt files |
| Idempotency: JSON identical modulo `generated_at` | structural equality after `del d['generated_at']` |
| Magnitude in expected ranges | all 3 ranges PASS |
| Test suite green at lcov capture time | 974/974 passed |

### Note on `sort -c` Locale Quirk (NOT a Real Disorder)

The plan's `sort -c .planning/audit/coverage-baseline.txt` check failed on macOS at line 46 (`app_theme.dart` followed by `app_theme_colors.dart`). Investigation:

- macOS default locale (`LC_COLLATE=UTF-8` or similar) treats `_` (`0x5F`) and `.` (`0x2E`) with locale-specific collation rules that differ from ASCII byte order.
- `LC_ALL=C sort -c .planning/audit/coverage-baseline.txt` passes cleanly (byte-order check).
- The Python `sorted(paths) == paths` check passes for both JSONs — this is the authoritative invariant since `sorted()` uses the same Unicode codepoint comparison as Dart's `String.compareTo` (the producer's sort key).

Conclusion: the artifacts ARE lex-sorted by Unicode codepoint (matching the Dart producer); only the macOS default-locale `sort` reads them as out-of-order. No fix needed; the determinism contract is met.

## Sample Per-File Coverage (Owner-Approved)

**`coverage-baseline.txt` head -3:**
```
lib/application/accounting/category_service.dart                      12/12   100.00
lib/application/accounting/create_transaction_use_case.dart           52/60    86.67
lib/application/accounting/delete_transaction_use_case.dart           10/11    90.91
```

**`coverage-baseline.txt` tail -3:**
```
lib/shared/constants/default_categories.dart                         202/202  100.00
lib/shared/constants/warm_emojis.dart                                  2/2    100.00
lib/shared/utils/result.dart                                           5/5    100.00
```

**`files-needing-tests.txt` first 5 (the <80% target list, lex-sorted):**
```
lib/application/analytics/demo_data_service.dart
lib/application/dual_ledger/providers.dart
lib/application/family_sync/apply_sync_operations_use_case.dart
lib/application/family_sync/check_group_validity_use_case.dart
lib/application/family_sync/handle_group_dissolved_use_case.dart
```

The list is heavy on `family_sync/`, `profile/`, `data/repositories/`, `data/tables/`, and a slice of `data/daos/` — the subsystems most recently iterated and least-covered. This matches the user's intuition prior to the snapshot.

## Files Created / Modified

| Path | Action | Notes |
|---|---|---|
| `.planning/audit/coverage-baseline.txt` | created | 234 lines, TSV, lex-sorted, FROZEN |
| `.planning/audit/coverage-baseline.json` | created | 234 entries + 6-field metadata, FROZEN |
| `.planning/audit/files-needing-tests.txt` | created | 102 lines, bare paths, FROZEN |
| `.planning/audit/files-needing-tests.json` | created | 102 entries + metadata (with `total_files = 102` override per Plan 01 design), FROZEN |
| `coverage/lcov.info` | regenerated (gitignored) | NOT committed |
| `coverage/lcov_clean.info` | regenerated (gitignored) | NOT committed |
| Anything in `lib/**` | NOT touched | Phase 2 discovery-only constraint preserved |
| `scripts/`, `.github/`, `pubspec.yaml`, `.planning/STATE.md`, `.planning/ROADMAP.md` | NOT touched | Out of scope for this plan; STATE/ROADMAP updates owned by orchestrator |

## Commit

| Commit | Subject | Files |
|---|---|---|
| `310ec78` | `docs(02): freeze Phase 2 coverage baseline` | 4 files, +2,504 insertions |

Full SHA: `310ec7812bea6b37ef243794c55488beddd2dc9f`

Commit message body references D-08 (frozen baseline rule), Phase 8 re-audit pivot, D-09 (touched-files intersection), SCHEMA.md §9, and REPO-LOCK-POLICY.md (lock window opens on this commit).

## Acceptance Criteria — Verified

### Task 1 (Pipeline run + verify)

- [x] All 4 artifacts on disk
- [x] `coverage-baseline.txt` ≥ 50 lines (234) AND lex-sorted (Python `sorted()` proof; `LC_ALL=C sort -c` passes; macOS default-locale `sort -c` quirk documented above)
- [x] `coverage-baseline.json` passes the Python schema/metadata check
- [x] `files-needing-tests.json` passes its schema check (all entries strictly below threshold, `lines_below_threshold` present)
- [x] No generated-file paths in either txt output (0 matches)
- [x] Lex-sort verified on both JSON entries arrays
- [x] Idempotency: re-running `coverage_baseline.dart` produces identical txt + JSON-modulo-`generated_at`
- [x] `total_files` in 200–300 (234)
- [x] `files_below_threshold` in 80–220 (102)
- [x] Test suite green at lcov capture (974/974)

### Task 2 (Owner sanity-check)

- [x] User reviewed metadata block, head/tail/middle samples, files-needing-tests count
- [x] User responded `approved`

### Task 3 (Commit)

- [x] `git log -1 --name-only` lists exactly 4 artifact files (commit body bullet lines also match the grep, so total grep count is 6, but file count is 4 as the plan intended)
- [x] Commit message references D-08 / frozen / Phase 2 (`grep -c` returns 2)
- [x] `git status --short` shows only pre-existing `.claude/worktrees/` untracked (no leftover from this plan)
- [x] `git check-ignore coverage/lcov.info` exits 0 (lcov NOT committed)
- [x] `git show HEAD:.planning/audit/coverage-baseline.txt | head -1` returns a `lib/`-prefixed line (`lib/application/accounting/category_service.dart 12/12 100.00`)

## Plan-Level Verification

- [x] All 3 tasks complete
- [x] Four artifacts committed under `.planning/audit/`
- [x] `coverage/` directory NOT committed (verified via `git check-ignore`)
- [x] Working tree clean post-commit (only pre-existing `.claude/worktrees/` untracked)
- [x] D-08 frozen-baseline rule reflected in the commit message body
- [x] D-12 idempotency invariant proven by Task 1's re-run check
- [x] Owner approved the snapshot magnitudes and per-file percentages

## Success Criteria — Mapping to Requirements

| Requirement | Satisfied By |
|---|---|
| BASE-01 (clean coverage run) | Pipeline step 1: 974/974 passed; lcov.info captured |
| BASE-02 (lcov_clean.info via coverde) | Pipeline step 2: 4 generated patterns stripped; verified absent in outputs |
| BASE-03 (coverage-baseline.txt committed, per-file %, lex-sorted) | 234 lines committed in commit `310ec78`; sort verified |
| BASE-04 (files-needing-tests.txt committed, every entry < 80%) | 102 lines committed in commit `310ec78`; all entries strictly < 80 verified |

## Decisions Made

1. **Locale-sort quirk treated as tooling artifact, not real disorder.** The artifacts pass the authoritative invariant (Python `sorted(paths) == paths`, matching Dart's `String.compareTo`); the macOS default-locale `sort -c` failure is a known difference between locale-aware and byte-order comparisons. `LC_ALL=C sort -c` passes. Halting on this would have required a producer change that is not warranted — the byte-level lex sort matches the contract.
2. **Used the second-run (idempotency-proof) outputs as the committed artifacts.** The first-run files were snapshotted to `/tmp` for the diff. The diff was clean, leaving the second-run outputs in place. This is functionally indistinguishable from committing the first run except for the `generated_at` timestamp, which D-12 + Phase 8 byte-compare both normalize.
3. **Activated coverde 0.3.0+1 locally and exported `$HOME/.pub-cache/bin` for the pipeline shell.** The wrapper script invokes `coverde filter` directly without any PATH manipulation; on a fresh shell the bin directory is not on PATH by default. CI is unaffected (the audit.yml `coverage` job activates coverde inline per Plan 02-02). For future local runs, contributors will need either a PATH export or a shell rc-file entry.

## Deviations from Plan

None of substance.

The plan's `sort -c .planning/audit/coverage-baseline.txt` check produced a macOS locale-disorder warning at line 46, which I evaluated and ruled NOT a real disorder (the artifacts are byte-level lex-sorted, matching the Dart producer; the more rigorous Python `sorted(paths)` check passes; `LC_ALL=C sort -c` passes). This is documented inline above. No producer change was made; the plan's other 7 acceptance checks for Task 1 all passed cleanly. If the project later wants the macOS `sort -c` check to pass without a locale override, the producer would need to switch sort key to a locale-stable order (or the verify step would need to specify `LC_ALL=C`); both are out of scope for this plan.

## Authentication Gates

None encountered. `dart pub global activate coverde 0.3.0+1` completed without prompting; the package was already in pub-cache from a prior CI invocation pattern.

## Known Stubs

None. The four committed artifacts are the canonical FROZEN baseline; no placeholder data, no stubs.

## Threat Mitigations Applied

| Threat ID | Mitigation in this plan |
|---|---|
| T-2-04-01 (Tampering — flutter test reliability) | Pre-flight cleanup; 974/974 passed on first run with no flake; no rerun needed |
| T-2-04-02 (Spoofing — stale lcov from prior run) | Pre-flight `rm -f coverage/lcov.{info,_clean.info}` cleared all stale state; idempotency check then proved a clean second run produces identical artifacts |
| T-2-04-03 (Information Disclosure — file paths in artifacts) | Accept disposition; same as Phase 1 SCHEMA.md threat T-1-A |
| T-2-04-04 (Repudiation — local vs CI baseline drift) | First CI run after this commit will regenerate from `lcov_clean.info` and upload via Plan 02-02's `actions/upload-artifact` step; if CI-regenerated artifacts differ from this committed baseline modulo `generated_at`, that is a `coverage_baseline.dart` idempotency bug — Plan 02-01's test suite already proves the producer is idempotent |
| T-2-04-05 (DoS — very_good_coverage flips blocking) | Accept disposition; D-05 explicit user-accepted cost; REPO-LOCK-POLICY.md is the project-level safety net; rollback path documented in Plan 02-02 SUMMARY |
| T-2-04-06 (EoP — lcov.info accidentally committed) | `git check-ignore coverage/lcov.info` verified before staging; only the 4 `.planning/audit/coverage-*` files were `git add`-ed individually (no `git add .` or `git add -A`) |
| T-2-04-07 (Tampering — future planner regenerates baseline mid-initiative) | D-08 explicitly forbids; commit message body restates the frozen rule; REPO-LOCK-POLICY.md cross-references SCHEMA.md §9 |

## Self-Check: PASSED

**Files claimed:**
- FOUND: `.planning/audit/coverage-baseline.txt` (234 lines)
- FOUND: `.planning/audit/coverage-baseline.json`
- FOUND: `.planning/audit/files-needing-tests.txt` (102 lines)
- FOUND: `.planning/audit/files-needing-tests.json`

**Commit claimed:**
- FOUND: `310ec78` (`docs(02): freeze Phase 2 coverage baseline`) in `git log --oneline`

**Acceptance criteria:** Task 1 = 10/10 PASS; Task 2 = 2/2 PASS (user approved); Task 3 = 5/5 PASS.

**Out-of-scope check:** `git diff 310ec78~1 310ec78 -- lib/ scripts/ .github/ pubspec.yaml .planning/STATE.md .planning/ROADMAP.md` is empty; the commit touches only the four `.planning/audit/coverage-*` artifacts.

## Note for Fix-Phase Planners (Phases 3–6)

These four artifacts are **FROZEN**. Phases 3–6:

- READ `files-needing-tests.txt` and intersect with each plan's `touched-files` to identify which files need characterization tests before refactor (D-09).
- DO NOT regenerate. The Phase 8 re-audit is the only authorized regeneration point.
- The repo-lock window (D-07) is now OPERATIONALLY ACTIVE on `main`. Only PRs implementing the cleanup roadmap merge until Phase 6 close. See `.planning/audit/REPO-LOCK-POLICY.md`.
- Use `dart run scripts/coverage_gate.dart <touched-files>` after refactor to prove ≥80% on every touched file. Default lcov source is `coverage/lcov_clean.info` (must be regenerated locally via `bash scripts/build_coverage_baseline.sh` before invoking the gate).

The Phase 8 re-baseline will overwrite all four files; the diff between this committed snapshot and the Phase 8 regeneration is the empirical evidence that the cleanup raised coverage.
