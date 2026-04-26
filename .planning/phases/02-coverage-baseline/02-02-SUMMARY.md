---
phase: 02-coverage-baseline
plan: 02
subsystem: ci
tags:
  - ci
  - coverage
  - guardrails
requires:
  - .github/workflows/audit.yml (existing coverage job stub from Phase 1)
  - scripts/coverage_baseline.dart (delivered by Plan 02-01)
  - coverde 0.3.0+1 (already pinned in static-analysis job line 29)
provides:
  - Modified `coverage` job with coverde filter + lcov_clean.info path + blocking very_good_coverage + coverage-baseline artifact upload
  - Tracked-file CI surface for BASE-01 / BASE-02 / BASE-06
affects:
  - Every PR going forward: coverage gate flips from advisory to BLOCKING (D-05)
  - Repo-lock policy (Plan 02-03) becomes operationally necessary from this commit forward
tech-stack:
  added: []
  patterns:
    - "Inline-comment convention for staged-blocking flips: removed marker on flip; preserved markers for Phases 3/4/6"
    - "Defense-in-depth: very_good_coverage `exclude:` block kept BYTE-IDENTICAL to coverde filter patterns (D-09 idempotency precedent from Phase 1)"
    - "coverde filter --mode w for deterministic overwrite (avoids append-mode contamination across reruns)"
key-files:
  created: []
  modified:
    - .github/workflows/audit.yml
decisions:
  - "Used `--filters` (the official coverde 0.3.0+1 flag, confirmed via `coverde filter --help` after global activation) — not `--patterns` / `--exclude` / `-f`"
  - "Added `--mode w` to the coverde filter step so reruns overwrite (not append) the output file, preserving idempotency"
  - "Kept very_good_coverage `exclude:` block instead of dropping it; defense-in-depth per CONTEXT line 122 (source of truth) and PATTERNS.md `audit.yml` step 4 note"
  - "Placed `coverage_baseline.dart` step AFTER the gate (data extraction, not gating); placed artifact upload at end of job"
  - "Did NOT touch static-analysis or guardrails jobs; their staged-blocking markers (Phases 3/4/6 on lines 38/41/44) are intact"
metrics:
  duration: "~2 min (single-task plan, single file modified)"
  completed: "2026-04-26"
---

# Phase 02 Plan 02: Coverage CI Activation Summary

**Modified `.github/workflows/audit.yml` `coverage` job** to: activate coverde inside the job, strip generated files from lcov via `coverde filter` to produce `coverage/lcov_clean.info`, flip `very_good_coverage@v2` from advisory to BLOCKING (D-05), invoke `dart run scripts/coverage_baseline.dart`, and upload the four `.planning/audit/coverage-*` artifacts. `coverage_gate.dart` is intentionally NOT wired (D-06 — Phase 7/8 territory).

## Confirmed `coverde filter` Flag Syntax

PATTERNS.md flagged this for runtime confirmation. Resolved via `dart pub global activate coverde 0.3.0+1 && coverde filter --help`:

```
-i, --input=<INPUT_LCOV_FILE>      (default: coverage/lcov.info)
-o, --output=<OUTPUT_LCOV_FILE>    (default: coverage/filtered.lcov.info)
-f, --filters=<FILTERS>            comma-separated path patterns (REGEX, not glob)
-m, --mode=<a|w>                   a=append (default), w=overwrite
-b, --base-directory               base for relative path resolution
```

**Used:** `--filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'` with `--mode w`.

Two non-obvious facts the help output revealed:

1. **`--filters` patterns are REGEX, not globs.** PATTERNS.md correctly conjectured the regex flavor; this was confirmed before edit. The four patterns expressed as regex match the four globs in the `very_good_coverage` exclude list 1:1 (defense-in-depth invariant preserved).
2. **Default mode is APPEND (`a`), not overwrite (`w`).** Without `--mode w`, reruns of the filter step would append to `lcov_clean.info` rather than replace it, contaminating the gate input on retried CI runs. Added `--mode w` to enforce idempotency (CONTEXT D-12 invariant).

No fallback to awk was required — the four patterns all parse cleanly as regex.

## Diff Applied

```diff
diff --git a/.github/workflows/audit.yml b/.github/workflows/audit.yml
index b6d6ea3..34bec48 100644
--- a/.github/workflows/audit.yml
+++ b/.github/workflows/audit.yml
@@ -96,14 +96,34 @@ jobs:
           channel: stable
           flutter-version-file: pubspec.yaml
       - run: flutter pub get
+      - run: dart pub global activate coverde 0.3.0+1
       - run: flutter test --coverage
+      - name: Strip generated files from lcov
+        run: |
+          coverde filter \
+            --input coverage/lcov.info \
+            --output coverage/lcov_clean.info \
+            --mode w \
+            --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
       - uses: VeryGoodOpenSource/very_good_coverage@v2
-        continue-on-error: true   # Phase 2 BASE-06 flips this blocking
+        # Phase 2 close (BASE-06 / D-05): blocking. Threshold 80 against lcov_clean.info.
         with:
-          path: coverage/lcov.info
+          path: coverage/lcov_clean.info   # Phase 2 BASE-02: cleaned by coverde filter upstream
           min_coverage: 80
           exclude: |
             **/*.g.dart
             **/*.freezed.dart
             **/*.mocks.dart
             lib/generated/**
+      - name: Generate coverage baseline artifacts
+        run: dart run scripts/coverage_baseline.dart
+      - uses: actions/upload-artifact@v4
+        with:
+          name: coverage-baseline
+          path: |
+            .planning/audit/coverage-baseline.txt
+            .planning/audit/coverage-baseline.json
+            .planning/audit/files-needing-tests.txt
+            .planning/audit/files-needing-tests.json
+      # NOTE: scripts/coverage_gate.dart per-file step is intentionally NOT wired here in Phase 2 (CONTEXT D-06).
+      #       It joins this job at Phase 7/8 close (CI tightening) and is blocking from the moment it is added.
```

24 substantive line changes (22 insertions, 2 deletions).

## Verification

All 11 plan acceptance criteria PASS:

| # | Check | Result |
|---|-------|--------|
| 1 | YAML parses (`python3 -c "import yaml; yaml.safe_load(...)"`) | exit 0 |
| 2 | `coverde 0.3.0+1` activation present in coverage job | 1 match |
| 3 | `coverde filter` step present | 2 matches (name + body) |
| 4 | `lcov_clean.info` referenced ≥2 times | 3 matches |
| 5 | `continue-on-error: true` within 2 lines of `very_good_coverage@v2` | 0 matches (correctly removed) |
| 6 | `dart run scripts/coverage_baseline.dart` step present | 1 match |
| 7 | `name: coverage-baseline` artifact present | 1 match |
| 8 | Both `files-needing-tests.{txt,json}` in upload list | 2 matches |
| 9 | D-06 / coverage_gate.dart deferral note present | 1 match |
| 10 | `static-analysis` Phase 4 marker untouched (`grep -B 1 "dart run custom_lint" \| grep "Phase 4"`) | 1 match |
| 11 | `static-analysis` Phase 6 marker untouched (`grep -B 1 "flutter analyze" \| grep "Phase 6"`) | 1 match |

Plan automated verification (single-line Python script in plan):

```
audit.yml coverage job: all 5 modifications confirmed
```

## Threat Mitigations Applied

| Threat ID | Mitigation in this commit |
|-----------|---------------------------|
| T-2-02-01 | coverde activation pinned to `0.3.0+1` (matches static-analysis line 29) |
| T-2-02-05 | Rollback path is one-line (re-add `continue-on-error: true` to the very_good_coverage step) — see "Rollback" section below |
| T-2-02-06 | very_good_coverage `exclude:` list kept BYTE-IDENTICAL to coverde filter patterns; the four patterns appear twice in the YAML for defense-in-depth |
| T-2-02-07 | `coverage-baseline` artifact upload preserves per-file evidence on every PR run (the four artifacts have `generated_at`, `lcov_source`, `threshold` metadata via Plan 02-01's `coverage_baseline.dart`) |

T-2-02-02, T-2-02-03, T-2-02-04 are `accept` dispositions per the plan's threat model — no implementation change required.

## Rollback Instructions (D-05 Flip)

If the global blocking gate proves untenable during the cleanup window (Phases 3–6), the flip is reversible by reverting `.github/workflows/audit.yml` lines 108-117 to:

```yaml
      - uses: VeryGoodOpenSource/very_good_coverage@v2
        continue-on-error: true   # Phase 2 BASE-06 flips this blocking
        with:
          path: coverage/lcov_clean.info
          min_coverage: 80
          exclude:
            ...
```

That single 1-line change (re-adding `continue-on-error: true`) restores advisory behavior. The coverde filter step, lcov_clean.info path, coverage_baseline.dart step, and artifact upload all remain valuable independently and should be kept. The repo-lock policy (Plan 02-03) is the project-level safety net that makes D-05 viable; if the lock is released without the cleanup completing, this is the immediate operational lever.

## Untouched Confirmation

| Job | Status | Evidence |
|-----|--------|----------|
| `static-analysis` | Untouched | `grep -B 1 "flutter analyze" .github/workflows/audit.yml \| grep "Phase 6"` returns 1; `grep -B 1 "dart run custom_lint" .github/workflows/audit.yml \| grep "Phase 4"` returns 1 |
| `guardrails` | Untouched | `git diff HEAD~1 HEAD .github/workflows/audit.yml` shows zero hunks in lines 61-86 |

Markers for Phases 3, 4, 6 staged-blocking flips remain in place on lines 38, 41, 44 of the modified file.

## Deviations from Plan

None — plan executed exactly as written. All 7 modification steps applied via a single `Edit` tool call (one contiguous block in the `coverage` job), which the plan permitted ("Apply six edits ... Make each edit individually" — taken as guidance; the contiguous block matched the exact target output and produced an atomically reviewable diff). Post-edit verification confirmed every grep acceptance criterion individually.

The `coverde filter --help` runtime confirmation (PATTERNS.md flagged this as unverified at planning time) revealed the official flag is `--filters` (the plan's primary guess). No fallback to alternate flag names or awk was needed.

One minor enhancement applied (Rule 2 — auto-add missing critical functionality): added `--mode w` to the coverde filter step. Without this, the default `--mode a` (append) would contaminate `lcov_clean.info` across CI retries on the same runner-cached workspace, breaking idempotency (CONTEXT D-12). This is a correctness requirement, not a feature.

## Authentication Gates

None encountered. The `dart pub global activate coverde 0.3.0+1` invocation runs unauthenticated against pub.dev; the only network access is the existing GitHub Actions checkout/flutter-action/cache flow.

## Stub / Threat Surface Scan

- **Stubs:** None. The modified file is a CI workflow with no UI rendering surface.
- **New threat surface:** None. The new steps invoke already-vetted tools (coverde already used in static-analysis; very_good_coverage already used in coverage; actions/upload-artifact already used elsewhere). No new endpoints, no new auth paths, no new file access patterns at trust boundaries.

## Self-Check: PASSED

- Modified file present:
  - `.github/workflows/audit.yml` — FOUND (commit 7b1bf63, 130 lines)
- Commit exists:
  - `7b1bf63` — FOUND in `git log --oneline`
- Verification commands re-runnable post-commit:
  - YAML validity, all 11 grep acceptance criteria, plan automated assertion — all confirmed PASS post-commit

## Commits

| Commit | Subject |
|--------|---------|
| `7b1bf63` | `ci(02-02): evolve coverage job — coverde filter + lcov_clean + flip blocking` |

(SUMMARY.md commit appended after this file is written.)
