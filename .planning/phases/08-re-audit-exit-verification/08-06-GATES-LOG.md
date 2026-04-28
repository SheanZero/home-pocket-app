# Phase 8 — EXIT-04 Gate Verification Log

**Run date:** 2026-04-28T07:01:48Z
**Branch:** main
**Commit:** 2f206ba93bf5133d8bef581672f9535eb1a70c12
**Status:** 4 GATE(S) FAILED

| Gate | Command | Exit | Verdict |
|------|---------|------|---------|
| 1 | `flutter analyze` | 0 | PASS |
| 2 | `dart run custom_lint` | 1 | FAIL |
| 3 | `flutter test --coverage` global ≥80% (actual 74.6%) | 1 | FAIL |
| 4 | very_good_coverage@v2 (min_coverage: 80, actual 74.6%) | 1 | FAIL |
| 5 | import_guard via custom_lint (re-derived from gate 2 stdout, 0 violations) | 0 | PASS |
| 6 | `dart_code_linter:metrics check-unused-code lib` | 0 | PASS |
| 7 | `build_runner build && git diff lib/` (no stale generated files) | 0 | PASS |
| 8 | `coverage_gate.dart --list cleanup-touched-files.txt --threshold 80` | 1 | FAIL |

---

## Failure Details

### Gate 2: `dart run custom_lint` — 28 INFO findings (non-blocking severity but blocking exit code)

**Severity breakdown:** all 28 findings are `INFO` level (no WARNING, no ERROR).

**Rule breakdown:**
- 25 × `avoid_manual_providers_as_generated_provider_dependency` (riverpod_lint) — generated `@riverpod` providers depending on manual providers
- 3 × `scoped_providers_should_specify_dependencies` (riverpod_lint) — test-only ProviderScope overrides

**Files affected (lib/):**
- `lib/application/family_sync/repository_providers.dart`
- `lib/features/accounting/presentation/providers/repository_providers.dart`
- `lib/features/analytics/presentation/providers/repository_providers.dart`
- `lib/features/family_sync/presentation/providers/repository_providers.dart`
- `lib/features/family_sync/presentation/providers/state_sync.dart`
- `lib/infrastructure/crypto/providers.dart`
- `lib/infrastructure/security/providers.dart`

**Files affected (test/):**
- `test/features/home/presentation/screens/home_screen_test.dart`
- `test/widget/features/home/presentation/screens/home_screen_test.dart`

**`import_guard` violations:** 0 (Gate 5 PASS)

**Provenance:** All affected `lib/` files were last touched in Phase 4 commits (`refactor(04-02): family_sync ...`, `refactor(04-02): profile ...`). The findings are pre-existing INFO-level riverpod_lint warnings that audit.yml CI would fail on `dart run custom_lint` (no `--no-fatal-infos`).

**Plan position:** This is a Phase 8 DISCOVERY. Plan 08-06 says "If any gate fails, STOP — document precisely what failed. Do not 'fix' by editing the gate — document and let user decide." Per Rule 4 (architectural), surfacing for user review.

**Open question for user:** Two paths to gate-pass:
1. Add `--no-fatal-infos` to `dart run custom_lint` in audit.yml (CI parity with the other guardrails using same flag in `audit/layer.dart` and `audit/providers.dart`).
2. Resolve the 28 INFO findings by refactoring the manual-provider dependencies to use proper `@riverpod` annotations (Phase 4-style fix; significant scope expansion).

### Gate 3: Global coverage 74.6% — below 80% threshold

**Computation:** `awk -F: '/^LF:/ { lf += $2 } /^LH:/ { lh += $2 } END { print lh/lf*100 }' coverage/lcov_clean.info` → `74.6%`.

**Pre-Phase-8 gap:** Even after Phases 3-6 cleanup + Plan 08-04 widget goldens, the test suite's coverage of `lib/` is still under 80% globally. The Phase 2 baseline was likewise below 80% (per CONCERNS.md "~68% naive coverage ratio" anticipation; current 74.6% reflects the cleanup-driven improvements).

**Files-needing-tests count:** 67 (down from Phase 2 baseline of 102 — 35 file improvement).

**Plan position:** Plan 08-04 widget goldens did not move the global needle far enough. To reach 80% global, an additional ~5 percentage points of coverage is needed across `lib/`. This is a multi-plan effort.

### Gate 4: very_good_coverage@v2 — same as Gate 3

`min_coverage: 80` in audit.yml is the GLOBAL threshold, computed against `lcov_clean.info`. Same arithmetic as Gate 3 → 74.6% → FAIL. Note: my initial attempt at this gate misinterpreted it as per-file (corrected before logging).

### Gate 8: coverage_gate.dart per-file ≥80% on cleanup-touched-files.txt

**170 files checked, 107 reported as FAIL:**
- **96 of 107 are WARNINGs:** entries in `cleanup-touched-files.txt` that are not in `coverage/lcov_clean.info`. These are:
  - Generated `*.g.dart` files (filtered by `coverde filter`)
  - `*.arb` localization files (3 files, no Dart code)
  - `import_guard.yaml` config files
  - Files with no dart test execution (e.g., `lib/main.dart` IS in lcov, but `lib/core/initialization/init_result.dart` is not — no test exercises it)
  - The CLI's policy: "treat missing-from-lcov as 0% and FAIL".
- **11 of 107 are real failures:** Dart source files actually under 80%:
  - `lib/application/accounting/repository_providers.dart` — 75.00%
  - `lib/application/ml/repository_providers.dart` — 40.00%
  - `lib/application/profile/repository_providers.dart` — 0.00%
  - `lib/application/voice/repository_providers.dart` — 40.00%
  - `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — 63.28%
  - `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` — 45.96%
  - `lib/features/analytics/presentation/screens/analytics_screen.dart` — 52.73%
  - `lib/features/family_sync/presentation/providers/state_sync.dart` — 61.90%
  - `lib/features/family_sync/presentation/screens/create_group_screen.dart` — 17.71%
  - `lib/features/home/presentation/providers/state_shadow_books.dart` — 34.62%
  - `lib/features/settings/presentation/widgets/appearance_section.dart` — 60.00%

**Provenance:** Plan 08-02 D-04 acknowledged `cleanup-touched-files.txt` does NOT pre-filter `.g.dart`/`.arb`/`yaml`/non-test-exercised files — `coverage_gate.dart` emits WARNINGs but treats them as 0% (FAIL). The intent was that the union list mirrors plan `files_modified` frontmatter literally; downstream `coverage_gate.dart` policy is what produces the 96 WARNING-level FAILs.

**Plan position:** Two issues to surface:
1. **Filter discipline** — Should `cleanup-touched-files.txt` exclude `.g.dart`, `.arb`, `.yaml`? (Plan 08-02 explicitly said no — kept literal mirror of plan frontmatter.) If not, should `coverage_gate.dart` skip entries it can't measure (WARNING-only, no FAIL contribution)?
2. **Real-failure remediation** — The 11 real failures are 4 missing repository_providers (low-line, high-impact-on-percentage), 4 large UI screens, 2 providers, 1 widget. Substantive test coverage work needed.

### Gate 5, 6, 7: PASS (no findings to detail)

- Gate 5: `import_guard` 0 violations.
- Gate 6: `check-unused-code lib` 0 unused symbols across 324 files.
- Gate 7: `build_runner build` zero stale generated files in `lib/`.

---

## Re-run 2026-04-28T08:05:43Z — 70% threshold (per amendment commit `03b1a06`)

**Run date:** 2026-04-28T08:05:43Z
**Branch:** main
**Commit:** 03b1a06900693646b053658a0cc2ba22b15ff58d ("docs(08-amend): lower coverage threshold 80→70")
**Status:** 2 GATE(S) STILL FAILED (Gate 2 + Gate 8)
**Coverage source:** `coverage/lcov_clean.info` from prior run (16:00 UTC, same tree)
**Methodology:** Re-executed only threshold-dependent gates (3, 4, 8). Gates 1/5/6/7 cited as already-passing (unaffected by threshold). Gate 2 cited as already-failing (unaffected by threshold; INFO findings independent of coverage).

| Gate | Command | Exit | Verdict | Δ vs 80% run |
|------|---------|------|---------|--------------|
| 1 | `flutter analyze` | (cited) 0 | PASS | unchanged |
| 2 | `dart run custom_lint` | (cited) 1 | FAIL | unchanged — INFO findings independent of threshold |
| 3 | global LH/LF on `lcov_clean.info` ≥70% (actual 74.6336%) | 0 | **PASS** | flipped FAIL→PASS |
| 4 | very_good_coverage@v2 (`min_coverage: 70`, actual 74.6336%) | 0 | **PASS** | flipped FAIL→PASS |
| 5 | import_guard via custom_lint (0 violations) | (cited) 0 | PASS | unchanged |
| 6 | `dart_code_linter:metrics check-unused-code lib` | (cited) 0 | PASS | unchanged |
| 7 | `build_runner build && git diff lib/` (no stale files) | (cited) 0 | PASS | unchanged |
| 8 | `coverage_gate.dart --list cleanup-touched-files.txt --threshold 70` | 1 | **FAIL** | partial improvement — 11→10 real failures, 96 WARNINGs unchanged |

### Gate 3 — global coverage 74.6336% ≥ 70% → PASS

```bash
$ awk -F: '/^LF:/ { lf += $2 } /^LH:/ { lh += $2 } END { printf "%.4f\n", lh/lf*100 }' coverage/lcov_clean.info
74.6336
```

Threshold met (74.6336 > 70.0000). EXIT-03 success criterion ("≥70% global coverage" per 2026-04-28 amendment) is satisfied by this result.

### Gate 4 — very_good_coverage@v2 at 70% → PASS

`very_good_coverage@v2` action computes the same arithmetic (sum-of-LH / sum-of-LF on the supplied `path: coverage/lcov_clean.info`). With `min_coverage: 70` (per `audit.yml` line 121 post-amendment), 74.6336% clears the bar.

### Gate 8 — coverage_gate.dart per-file ≥70% → STILL FAIL (exit 1)

```
[coverage:gate] 170 checked, 106 failed (threshold: 70)
```

Decomposition of the 106 failures:

**(A) 10 real failures** — Dart source files actually under 70% coverage:

| File | covered/total | % |
|---|---|---|
| `lib/application/profile/repository_providers.dart` | 0/4 | 0.00 |
| `lib/application/ml/repository_providers.dart` | 2/5 | 40.00 |
| `lib/application/voice/repository_providers.dart` | 2/5 | 40.00 |
| `lib/features/family_sync/presentation/screens/create_group_screen.dart` | 31/175 | 17.71 |
| `lib/features/home/presentation/providers/state_shadow_books.dart` | 9/26 | 34.62 |
| `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` | 74/161 | 45.96 |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | 58/110 | 52.73 |
| `lib/features/settings/presentation/widgets/appearance_section.dart` | 45/75 | 60.00 |
| `lib/features/family_sync/presentation/providers/state_sync.dart` | 26/42 | 61.90 |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | 193/305 | 63.28 |

Down from 11 at the 80% threshold — `lib/application/accounting/repository_providers.dart` (75.00%) flipped FAIL→PASS at 70%.

**(B) 96 missing-from-lcov WARNINGs** — Entries in `cleanup-touched-files.txt` that are not present in `coverage/lcov_clean.info`. Composition unchanged from 80% run:
- `*.g.dart` files (filtered by `coverde filter`)
- `*.freezed.dart` files (filtered by `coverde filter`)
- `*.arb` localization files (3 files, no Dart code)
- `import_guard.yaml` config files
- Dart files not exercised by any test (e.g., `init_result.dart`, `home/presentation/providers/*.dart`, `family_sync/use_cases/*.dart`)

`coverage_gate.dart` lines 130-138 + 144 + 166 emit a WARNING but treat each missing entry as 0% and FAIL — so the WARNINGs contribute to exit-1 even though they are non-Dart or generated files.

**Threshold-change effect:** The threshold reduction did not eliminate the missing-from-lcov class — those entries are 0%/0% regardless of threshold. The per-file gate's exit code is dominated by the 96 WARNINGs, not by the 10 real failures. Lowering further would not flip Gate 8 to PASS; only `cleanup-touched-files.txt` filtering or `coverage_gate.dart` policy change would.

### Cited gates (unchanged from 80% run; not re-executed)

| Gate | Original verdict | Reason not re-run |
|------|-----------------|-------------------|
| 1 (`flutter analyze`) | PASS | Threshold-independent. No source changes since 80% run on this tree. |
| 2 (`dart run custom_lint`) | FAIL — 28 INFO findings | Threshold-independent. Discovery 1 from 08-06 SUMMARY remains open. |
| 5 (`import_guard`) | PASS | Threshold-independent. |
| 6 (`check-unused-code lib`) | PASS | Threshold-independent. |
| 7 (`build_runner` clean diff) | PASS | Threshold-independent. |

### Net status after threshold amendment

- **EXIT-03 (≥70% global coverage):** SATISFIED by Gate 3/4 PASS at 74.6336%.
- **EXIT-04 (all 8 gates simultaneously):** **NOT SATISFIED** — Gate 2 and Gate 8 still fail.
  - Gate 2: 28 INFO findings from `riverpod_lint` (Phase 4-introduced, pre-existing).
  - Gate 8: 96 WARNING-class FAILs from non-Dart entries in `cleanup-touched-files.txt` + 10 real failures.

Threshold reduction closed the global-coverage gap (Gates 3 + 4) but did **not** address Gate 2's INFO findings or Gate 8's input-list filtering issue. Per success-criteria: marking EXIT-03 complete; leaving EXIT-04 pending with the two remaining blockers documented.

