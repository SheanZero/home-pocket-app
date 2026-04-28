---
phase: 08-re-audit-exit-verification
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/08-re-audit-exit-verification/08-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: all_fixed
---

# Phase 8: Code Review Fix Report

**Fixed at:** 2026-04-28
**Source review:** `.planning/phases/08-re-audit-exit-verification/08-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (1 BLOCKER + 8 WARNING)
- Fixed: 9
- Skipped: 0

All Critical + Warning findings from the Phase 8 adversarial review were addressed. Each fix was committed atomically with `fix(08): <ID> <description>` and verified with `dart analyze` (Dart sources), `flutter test test/scripts/<file>_test.dart` (Dart tests), or `python3 -c yaml.safe_load` (workflow YAML). Note: WR-06 affects ID-stamping logic in `merge_findings.dart`; the existing test suite covers the surrounding behaviour and passes, but the new collision path is not yet exercised by a dedicated regression test — flag for human verification before phase exit.

## Fixed Issues

### CR-01: `reaudit_diff.dart` `_isClosed()` does not match its documented contract

**Files modified:** `scripts/reaudit_diff.dart`
**Commit:** `1c3db6f`
**Applied fix:** Option B from the review — rewrote the docstring above `_isClosed` so it accurately describes the implementation (`status == 'closed'` only). The Phase 1 D-08 "duplicate child" merge semantics are realized in `merge_findings.dart` by stamping `status:'closed'` directly; no separate `closed_as_duplicate_of` marker is read here. This eliminates the documentation/code drift that could mislead future maintainers about the strict-exit gate semantics.

### WR-01: `coverage_baseline.dart` switch silently lets bare positional override `--lcov`

**Files modified:** `scripts/coverage_baseline.dart`
**Commit:** `75a9f9f`
**Applied fix:** Added `lcovExplicit` and `lcovPositional` tracking flags; both `--lcov` and bare-positional branches now reject conflicting subsequent input with `exit(2)` and a stderr message naming the conflicting source. Restores principle of least surprise.

### WR-02: `build_cleanup_touched_files.sh` awk top-level-key regex is fragile

**Files modified:** `scripts/build_cleanup_touched_files.sh`
**Commit:** `c152abd`
**Applied fix:** Broadened the block-terminator regex to match any non-list, non-frontmatter, non-whitespace start-of-line pattern. Now correctly closes the `files_modified:` block when the next top-level YAML key contains digits, hyphens, or leading digits.

### WR-03: `coverage_gate.dart` deferred-list parser breaks if path contains `#`

**Files modified:** `scripts/coverage_gate.dart`
**Commit:** `fca80bd`
**Applied fix:** Replaced `line.indexOf('#')` with `line.indexOf('  #')` (two spaces + hash), matching the documented `<path>  # <rationale>` separator. Lines without the literal separator now exit 2 with a clear error, preventing silent path-truncation when a Unix path contains `#`.

### WR-04: `coverage_gate.dart` does not detect duplicate paths in deferred file

**Files modified:** `scripts/coverage_gate.dart`
**Commit:** `45cd9cb`
**Applied fix:** Used `deferredPaths.add(path)` return value (Set semantics) to detect duplicates; second occurrence of the same path now exits 2 with a stderr message naming the offending line. Closes the data-integrity gap where a duplicate rationale would silently be lost.

### WR-05: `coverage_gate.dart` deferred lookup is O(N·M) with a Set+Map already in hand

**Files modified:** `scripts/coverage_gate.dart`
**Commit:** `6e528e1`
**Applied fix:** Replaced `firstWhere` linear scan with a `Map<String, _DeferredEntry>` lookup. Constructed the map during parse; per-input-file lookup is now O(1). Also implicitly tightens WR-04's duplicate-detection (a single map slot per path).

### WR-06: `merge_findings.dart` `--root` plumbing surfaces a pre-existing ID-collision risk

**Files modified:** `scripts/merge_findings.dart`
**Commit:** `39af638`
**Applied fix:** Restructured the stamping pipeline so `retainedClosed` is computed first and its existing IDs are collected into `reservedIds`. The new `nextId(prefix)` helper increments the per-category counter and skips any candidate ID already in `reservedIds`, guaranteeing the merged catalogue has unique IDs across freshly-stamped findings and retained closed findings. Verified via `flutter test test/scripts/merge_findings_test.dart` — all 8 existing tests pass. Note: this fix changes ID-stamping logic; a dedicated regression test for the collision path was not added in this iteration. **Requires human verification** before Phase 8 exit to confirm the ordering / counter behaviour matches the operator's expectations under collision.

### WR-07: `reaudit_diff.dart` no validation that catalogues have non-overlapping `_diffKey`

**Files modified:** `scripts/reaudit_diff.dart`
**Commit:** `94ee4e4`
**Applied fix:** Added a `byKey.containsKey(key)` check inside the parsing loop in `_readCatalogue`; duplicate diff keys now exit 2 with a stderr message naming the colliding `(category|file_path|description)` tuple. This forces the operator to either reword a description or fix the upstream merger before the diff can produce a verdict, restoring gate strictness. Verified via `flutter test test/scripts/reaudit_diff_test.dart` — all 9 existing tests pass.

### WR-08: `audit.yml` `coverage` job has no failure-cleanup; stale `lcov_clean.info` could persist

**Files modified:** `.github/workflows/audit.yml`
**Commit:** `b16708a`
**Applied fix:** Added `set -euo pipefail` and `rm -f coverage/lcov_clean.info` to the "Strip generated files from lcov" step. Strict-mode ensures any failure mid-script aborts the step; pre-cleaning ensures a partial write from a prior run cannot poison the downstream coverage gate. Defense-in-depth for the (now-non-PR-only) coverage job. Verified via `python3 -c yaml.safe_load` — workflow YAML parses cleanly.

---

_Fixed: 2026-04-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
