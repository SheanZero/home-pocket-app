---
phase: 01
plan: 07
plan_name: ci-workflow
status: complete
requirements: [AUDIT-08, AUDIT-09, AUDIT-10]
duration_min: ~3
self_check: PASSED
---

# Plan 01-07: CI Workflow — SUMMARY

## Performance

| Metric | Value |
|--------|-------|
| Tasks | 2/2 complete |
| Commits | 2 (1 per task, atomic) |
| Files added | 3 |
| Files modified in `lib/**` | 0 (Phase 1 discovery-only constraint preserved) |

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add audit CI workflow with staged enablement | feat(01-07): add audit CI workflow with staged enablement |
| 2 | Add local test_audit_pipeline.sh + test_idempotency.sh | feat(01-07): add local test_audit_pipeline.sh + test_idempotency.sh |

## Accomplishments

1. **Greenfield `.github/workflows/audit.yml`** (109 lines) — 3-job CI workflow:

   **Job 1: `static-analysis`** (heavy, report-only on D-04 staged-flip gates)
   - Flutter setup with version-pinned action (`subosito/flutter-action@v2`)
   - `actions/cache@v4` keyed on `hashFiles('pubspec.lock')` (Pitfall P1-11 cold-start mitigation)
   - `dart pub global activate coverde 0.3.0+1` (matches `scripts/install_audit_tools.sh` from Plan 01)
   - Analyzer-pin smoke check — emits `::warning::` (NOT error) on drift; FUTURE-TOOL-01 deferral
   - `flutter analyze --no-fatal-infos` (continue-on-error: flips blocking at end of Phase 6)
   - `dart run custom_lint` (continue-on-error: flips blocking at end of Phase 4)
   - 4 audit scanners (continue-on-error: flips blocking at Phases 3/4/6)
   - `dart run scripts/merge_findings.dart` (BLOCKING — must succeed for artifact upload)
   - `actions/upload-artifact@v4` packages `issues.json`, `ISSUES.md`, all shards

   **Job 2: `guardrails`** (BLOCKING from day one per D-04)
   - **AUDIT-09**: `grep -q sqlite3_flutter_libs pubspec.lock && exit 1` — no `continue-on-error`
   - **AUDIT-10**: `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` — no `continue-on-error`

   **Job 3: `coverage`** (PR-only, report-only)
   - `if: ${{ github.event_name == 'pull_request' }}` — saves CI on `main` push
   - `flutter test --coverage` + `VeryGoodOpenSource/very_good_coverage@v2` with `continue-on-error: true` (flips blocking at end of Phase 2 BASE-06)
   - 80% threshold with generated-file exclusions

2. **`scripts/test_audit_pipeline.sh`** (35 lines, executable) — local mirror of CI's static-analysis job. Runs all 4 scanners + merger + a Python heredoc schema check that asserts every finding has the 11 required fields and an ID matching `^(LV|PH|DC|RD)-\d{3}$`. Used by Plan 08 for pre-commit verification.

3. **`scripts/test_idempotency.sh`** (15 lines, executable) — Wave-0 Gap from VALIDATION.md. Runs `test_audit_pipeline.sh` twice and diffs `issues.json` to prove byte-identical output across runs (stable-ID guarantee from Plan 05).

4. **Smoke checks against the unmodified codebase:**
   - `bash scripts/test_audit_pipeline.sh` → exit 0, "19 findings validated"
   - `bash scripts/test_idempotency.sh` → exit 0, "issues.json byte-identical across runs"

## Files Created / Modified

| Path | Action |
|------|--------|
| `.github/workflows/audit.yml` | created — 109 lines, 3 jobs, staged enablement |
| `scripts/test_audit_pipeline.sh` | created — 35 lines, mode 755 |
| `scripts/test_idempotency.sh` | created — 15 lines, mode 755 |

## Decisions Made

1. **`Merge findings` step is BLOCKING (no `continue-on-error: true`)** — the merger's failure means the pipeline is broken, not that findings exist. Without successful merge there's nothing to upload. This is per the plan's explicit guidance.
2. **`coverage` job runs only on PRs** — main-branch coverage is enforced by the `static-analysis` job's static analysis; running `flutter test --coverage` on every push doubles CI time without adding signal.
3. **All `continue-on-error: true` lines have inline phase comments** (D-04 staged-flip bookkeeping). 4 such lines, 4 phase comments — `grep -E "continue-on-error: true.*Phase" .github/workflows/audit.yml | wc -l = 4`.
4. **Action pins use major-version tags (`@v4`, `@v2`)**, NOT immutable SHAs — matches RESEARCH §"CI Workflow" recommendation. Major-version tags balance security (auto-pulls security patches within major) with stability (no breaking-change auto-bumps).
5. **`coverde` version pinned `0.3.0+1`** — exact match with `scripts/install_audit_tools.sh` so local + CI run the same coverde release.
6. **Analyzer-pin verification emits `::warning::`, not `::error::`** — analyzer drift is a heads-up signal, not a blocking event. FUTURE-TOOL-01 (riverpod_lint 3.x upgrade) is deferred until json_serializable analyzer-conflict is resolved upstream.

## Deviations from Plan

None — both task files match the plan's verbatim `<interfaces>` content with no edits.

## Issues Encountered

1. **`pyyaml` not available system-wide** — could not run `python3 -c "import yaml; yaml.safe_load(...)"` parse check. Worked around with structural string-based assertions; CI itself will reject malformed YAML on first run, providing the ultimate validation.

## Threat Mitigations

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-1-07-01 (sqlite3_flutter_libs creeps in) | AUDIT-09 BLOCKING gate from day one — no continue-on-error | mitigated |
| T-1-07-02 (stale generated files) | AUDIT-10 BLOCKING gate from day one — no continue-on-error | mitigated |
| T-1-07-03 (CI cold-start cost) | actions/cache@v4 keyed on pubspec.lock | mitigated |
| T-1-07-04 (forgotten staged-flip) | Each continue-on-error: true has inline phase comment naming the verify-work checklist that removes it | mitigated |
| T-1-07-05 (action supply-chain compromise) | All actions pinned to major-version tags from trusted publishers (actions/*, subosito, VeryGoodOpenSource) | mitigated |

## Acceptance Criteria — Verified

**Task 1 — `.github/workflows/audit.yml`:**
- [x] File exists
- [x] Three jobs (`static-analysis`, `guardrails`, `coverage`)
- [x] AUDIT-09 step (`Reject sqlite3_flutter_libs in pubspec.lock`) BLOCKING — no `continue-on-error` on this step
- [x] AUDIT-10 step (`Build runner clean diff`) BLOCKING — no `continue-on-error` on this step
- [x] 4 `continue-on-error: true` lines (matches D-04 staged-flip count)
- [x] All 4 lines have inline phase comments
- [x] Cache step pinned (`actions/cache@v4`)
- [x] coverde pinned (`coverde 0.3.0+1`)
- [x] Coverage job is PR-only (`if: ${{ github.event_name == 'pull_request' }}`)
- [x] Artifact upload step (`actions/upload-artifact@v4`)
- [x] All action pins use major-version tags (5 distinct actions)
- [x] No `.dart` modified

**Task 2 — local mirror scripts:**
- [x] Both files exist and are executable (mode 755)
- [x] Both have `#!/usr/bin/env bash` shebang and `set -euo pipefail`
- [x] `bash -n` parses both cleanly
- [x] `test_audit_pipeline.sh` runs all 4 scanners + merger + schema check
- [x] `test_idempotency.sh` invokes `test_audit_pipeline.sh` (no logic duplication)
- [x] Smoke check on real codebase: pipeline produces 19 validated findings; idempotency proven

## Next Phase Readiness

| Plan | Unblocked by 01-07 | Reason |
|------|--------------------|--------|
| 01-08 (e2e pipeline run) | yes | Both helper scripts exist; Plan 08's owner sanity-check checkpoint can use them directly |
| Phase 2 (coverage baseline) | yes | `coverage` CI job is in place; flips blocking via remove-`continue-on-error` at Phase 2 exit |
| Phases 3+ (fix phases) | yes | Each phase's verify-work removes its `continue-on-error: true` line per the inline phase comments |

## Self-Check

- [x] All tasks executed (2/2)
- [x] Two atomic commits (1 per task)
- [x] AUDIT-08 final delivery surface — CI uploads issues.json + ISSUES.md + shards
- [x] AUDIT-09 BLOCKING on day one
- [x] AUDIT-10 BLOCKING on day one
- [x] Both helper scripts pass `bash -n` and run end-to-end
- [x] Pipeline produces real findings (19) on the unmodified codebase
- [x] Idempotency proven via diff
- [x] No `lib/**/*.dart` modified
- [x] All threat-model mitigations verified

**Self-Check: PASSED**
