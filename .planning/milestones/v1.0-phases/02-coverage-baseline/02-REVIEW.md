---
phase: 02-coverage-baseline
reviewed: 2026-04-26T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - scripts/coverage/lcov_parser.dart
  - scripts/coverage_baseline.dart
  - scripts/coverage_gate.dart
  - scripts/build_coverage_baseline.sh
  - test/scripts/lcov_parser_test.dart
  - test/scripts/coverage_baseline_test.dart
  - test/scripts/coverage_gate_test.dart
  - .github/workflows/audit.yml
findings:
  critical: 0
  warning: 1
  info: 5
  total: 6
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-04-26
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found (1 warning, 5 info)

## Summary

Phase 02 (coverage-baseline) introduces the LCOV parsing pipeline, a deterministic
baseline-snapshot generator, a hybrid CLI gate, a shell pipeline wrapper, and
flips `very_good_coverage` to BLOCKING in CI. Implementation quality is high:
clear module boundaries, well-documented decisions (D-01..D-12 referenced
inline), defense-in-depth on generated-file exclusion (`coverde filter` AND
`very_good_coverage.exclude` AND `isGeneratedPath()` — three independent
gates), and a thorough subprocess test harness covering schemas, idempotency,
and exit-code contracts.

No security issues. No correctness bugs that affect production code paths or
the locked decisions. The single Warning is an LCOV-edge-case fragility in
`lcov_parser.dart` where a non-zero `LF:` paired with a missing `LH:` would
report `0/total` (matches no real-world LCOV producer, but worth a defensive
guard or comment). Info items are stylistic / robustness suggestions —
optional.

All 35 tests pass; `flutter analyze` is 0 issues; pre-existing macOS `sort -c`
locale quirk is documented in 02-04-SUMMARY.md (out of scope).

## Warnings

### WR-01: LF-without-LH edge case yields silently wrong percentage

**File:** `scripts/coverage/lcov_parser.dart:126-128`
**Issue:** When a record contains `LF:N` (N > 0) but no `LH:` line at all, the
parser takes the `useDa = false` branch (because `lf != null && lf != 0`) and
then computes `covered = lh ?? 0`. Result: `0 / N = 0.0%` is reported for a
file that may actually be fully covered. This is undefined-behavior territory
in the LCOV spec — no real producer (lcov, coverde, flutter test) emits LF
without LH — but the silent-zero outcome is worse than the documented
fallback path.

Two reasonable fixes (pick one):

**Fix A — extend the DA fallback to also trigger when `lh == null`:**
```dart
final useDa = recomputeFromDa || lf == null || lf == 0 || lh == null;
final total = useDa ? daTotal : lf!;
final covered = useDa ? daCovered : lh!;
final pct = total == 0 ? 100.0 : (covered / total) * 100.0;
```

**Fix B — emit a stderr WARNING and skip the record:**
```dart
if (lf != null && lf! > 0 && lh == null) {
  stderr.writeln(
    '[coverage:lcov_parser] WARNING: skipping record for $currentPath (LF:$lf without LH)',
  );
  resetState();
  continue;
}
```

Fix A is preferred: it preserves data when DA lines are present and degrades
gracefully when they are not (DA-only → linesTotal == 0 → 100%, the existing
empty-file convention).

## Info

### IN-01: `coverage_baseline.dart` silently accepts multiple positional args

**File:** `scripts/coverage_baseline.dart:36-43`
**Issue:** The arg-parser `default:` branch overwrites `lcovPath` for every
non-flag positional. Invoking `dart run scripts/coverage_baseline.dart a.info
b.info` silently uses `b.info` and discards `a.info` with no error. The
docstring says "Allow a single bare positional as lcov path override" but
nothing enforces "single."

**Fix:** Track whether a positional was already seen and exit(2) on the
second:
```dart
var sawPositional = false;
// ...
default:
  if (a.startsWith('--')) {
    stderr.writeln('[coverage:baseline] ERROR: unknown flag: $a');
    exit(2);
  }
  if (sawPositional) {
    stderr.writeln('[coverage:baseline] ERROR: only one positional arg allowed');
    exit(2);
  }
  lcovPath = a;
  sawPositional = true;
```

### IN-02: Coverage job runs only on pull_request, never on push to main

**File:** `.github/workflows/audit.yml:88-91`
**Issue:** `if: ${{ github.event_name == 'pull_request' }}` means the
coverage gate (and baseline-artifact upload) does not run on direct pushes to
`main`. If a PR is merged via squash and the merge commit changes coverage
(unlikely but possible if main moved between PR-CI and merge), there is no
post-merge backstop. Also means baseline artifacts are not uploaded for
`main` builds — anyone consuming "latest baseline from main" via Actions
artifacts will see only PR snapshots.

**Fix (optional, per Phase 2 scope):** If the artifact-on-main use case
matters, drop the conditional and let the job run on both events. Otherwise
add a one-line code-comment so a future reader does not "fix" it accidentally:
```yaml
# Coverage is PR-only by design (Phase 2 D-06): main-branch coverage is
# already enforced by the PR gate before merge.
if: ${{ github.event_name == 'pull_request' }}
```

### IN-03: Fallback test in coverage_gate_test only exercises the PASS path

**File:** `test/scripts/coverage_gate_test.dart:109-120`
**Issue:** The test "falls back to .planning/audit/files-needing-tests.txt
when no positional/--list" writes a file at 100% coverage to the fallback
list. The gate exits 0 — fallback resolution is verified, but the realistic
"fallback contains failing files → exit 1" path is not. A regression that
makes the fallback feed the gate but skip the threshold check would still
pass this test.

**Fix:** Add one extra assertion in the same test or a sibling test:
```dart
test('fallback list with failing file → exit 1', () async {
  _writeLcov(tmp, {'lib/a.dart': (5, 10)}); // 50%
  File('${tmp.path}/.planning/audit/files-needing-tests.txt')
      .writeAsStringSync('lib/a.dart\n');
  final r = await _runGate(tmp);
  expect(r.exitCode, equals(1));
});
```

### IN-04: `_GateRow` could be promoted to share schema with LcovRecord

**File:** `scripts/coverage_gate.dart:169-191`
**Issue:** `_GateRow` duplicates four of `LcovRecord`'s fields and adds one
(`thresholdMet`). Per CLAUDE.md "MANY SMALL FILES > FEW LARGE FILES" and the
DRY principle, this could either (a) compose `LcovRecord` + threshold flag,
or (b) live alongside `LcovRecord` in `lcov_parser.dart` if it has cross-file
utility. Not urgent — the current shape is also defensible because `_GateRow`
is gate-specific (carries the synthetic 0% rows for missing files).

**Fix (optional):**
```dart
class _GateRow {
  final LcovRecord record;
  final bool thresholdMet;
  const _GateRow(this.record, this.thresholdMet);

  Map<String, dynamic> toJson() => {
    ...record.toJson(),
    'threshold_met': thresholdMet,
  };
}
```

### IN-05: Shell script does not verify coverde availability up front

**File:** `scripts/build_coverage_baseline.sh:18-25`
**Issue:** If `coverde` is not on PATH (e.g., user forgot
`dart pub global activate coverde 0.3.0+1`), step 2 fails with a generic
`coverde: command not found` after `flutter test --coverage` already burned
~1 minute. Better to fail fast.

**Fix:** Add a preflight at the top of the script:
```bash
if ! command -v coverde >/dev/null 2>&1; then
  echo "[coverage:baseline] ERROR: coverde not on PATH"
  echo "  Run: dart pub global activate coverde 0.3.0+1"
  echo "  Then ensure ~/.pub-cache/bin is on PATH"
  exit 2
fi
```

---

_Reviewed: 2026-04-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
