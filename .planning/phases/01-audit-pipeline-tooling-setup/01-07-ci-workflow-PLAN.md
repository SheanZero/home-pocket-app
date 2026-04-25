---
phase: 01-audit-pipeline-tooling-setup
plan: 07
type: execute
wave: 4
depends_on: [04, 05, 06]
files_modified:
  - .github/workflows/audit.yml
  - scripts/test_audit_pipeline.sh
  - scripts/test_idempotency.sh
autonomous: true
requirements: [AUDIT-08, AUDIT-09, AUDIT-10]
tags: [ci, github-actions, guardrails, blocking-gates]

must_haves:
  truths:
    - "`.github/workflows/audit.yml` exists; greenfield (`.github/` did not exist before this plan per RESEARCH §1)"
    - "Workflow defines 3 jobs: `static-analysis` (heavy, report-only on every gate that flips later), `guardrails` (blocking AUDIT-09 + AUDIT-10), `coverage` (PR-only, report-only)"
    - "AUDIT-09 gate is BLOCKING: `grep -q sqlite3_flutter_libs pubspec.lock && exit 1` — no `continue-on-error` on this step"
    - "AUDIT-10 gate is BLOCKING: `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` — no `continue-on-error` on this step"
    - "All other audit steps (flutter analyze, custom_lint, 4 audit scanners, merger, very_good_coverage) ship with `continue-on-error: true` per D-04 staged enablement"
    - "Workflow caches `~/.pub-cache` keyed on `pubspec.lock` (Pitfall P1-11 cold-start mitigation)"
    - "Workflow pins `dart pub global activate coverde 0.3.0+1` (RESEARCH §1 + Pitfall P1-11 supply-chain hygiene)"
    - "Workflow uploads `.planning/audit/issues.json`, `ISSUES.md`, and all shard files as a CI artifact"
    - "`scripts/test_audit_pipeline.sh` orchestrates the full pipeline locally (4 scanners + merger) and exits 0 on success"
    - "`scripts/test_idempotency.sh` runs the full pipeline twice and diffs `issues.json` to confirm stable IDs (Wave-0 Gap from VALIDATION.md)"
  artifacts:
    - path: ".github/workflows/audit.yml"
      provides: "GitHub Actions audit pipeline with 3 jobs + staged enablement"
      contains: "audit"
    - path: "scripts/test_audit_pipeline.sh"
      provides: "Local end-to-end pipeline runner — orchestrates scanners + merger and asserts outputs"
    - path: "scripts/test_idempotency.sh"
      provides: "Idempotency check — runs pipeline twice and diffs issues.json"
  key_links:
    - from: ".github/workflows/audit.yml `guardrails` job"
      to: "AUDIT-09 + AUDIT-10 (blocking gates)"
      via: "Steps without `continue-on-error: true`"
      pattern: "Reject sqlite3_flutter_libs"
    - from: ".github/workflows/audit.yml `static-analysis` job"
      to: "Plan 04 audit scanners + Plan 05 merger"
      via: "Step invokes `bash scripts/audit_*.sh` then `dart run scripts/merge_findings.dart`"
      pattern: "audit_layer.sh"
    - from: ".github/workflows/audit.yml `coverage` job"
      to: "Phase 2 BASE-06 (the very_good_coverage gate flips blocking at end of Phase 2)"
      via: "VeryGoodOpenSource/very_good_coverage@v2 with continue-on-error: true"
      pattern: "very_good_coverage"
---

<objective>
Stand up the greenfield CI workflow that:
1. Runs the full audit pipeline on every PR + push to `main` (report-only on the gates that flip blocking later, per D-04 staged enablement)
2. Enforces the two CI guardrails AUDIT-09 (`sqlite3_flutter_libs` reject) and AUDIT-10 (`build_runner` stale-diff) as BLOCKING from end of Phase 1
3. Uploads the audit artifacts (`.planning/audit/issues.json`, `ISSUES.md`, all shards) for human review

Also create two helper bash scripts that mirror the CI pipeline locally:
- `scripts/test_audit_pipeline.sh` — runs all 4 scanners + merger + verifies outputs (Wave-0 Gap from VALIDATION.md)
- `scripts/test_idempotency.sh` — runs the full pipeline twice and diffs `issues.json` (Wave-0 Gap from VALIDATION.md)

These local scripts are how Plan 08 (Wave 4) verifies the end-to-end pipeline pre-commit.

Per D-04, this CI workflow ships with `continue-on-error: true` on every step EXCEPT the two blocking guardrails. Each `continue-on-error: true` becomes a TODO comment marker `# Phase X exit gate flips this blocking` so future-phase verifiers know exactly what to flip.

Per CONTEXT.md `<specifics>` "Pre-Phase 8 dry-run": the pipeline is runnable from the end of Phase 1 against the unchanged codebase to verify it produces a stable shard set. Plan 08 is the dry-run; this plan provides the orchestration scripts.

Purpose:
- AUDIT-08 final delivery surface: CI workflow runs the pipeline + uploads `issues.json`
- AUDIT-09: CI guardrail rejects `sqlite3_flutter_libs` in `pubspec.lock` (BLOCKING from day one)
- AUDIT-10: CI guardrail rejects stale generated files (BLOCKING from day one)

Output:
- `.github/workflows/audit.yml` (greenfield — `.github/` directory did not exist; this plan creates the dir + the single workflow file)
- `scripts/test_audit_pipeline.sh` (greenfield Wave-0 Gap)
- `scripts/test_idempotency.sh` (greenfield Wave-0 Gap)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-VALIDATION.md
@CLAUDE.md
@scripts/install_audit_tools.sh
@scripts/audit_layer.sh
@scripts/audit_dead_code.sh
@scripts/audit_providers.sh
@scripts/audit_duplication.sh
@scripts/merge_findings.dart
@.planning/phases/01-audit-pipeline-tooling-setup/01-04-SUMMARY.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-05-SUMMARY.md

<interfaces>
<!-- Verbatim CI workflow from RESEARCH §"CI Workflow", lines 791–908. Executor copies this. -->

`.github/workflows/audit.yml` content (RESEARCH §"CI Workflow"):
```yaml
name: audit

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: audit-${{ github.ref }}
  cancel-in-progress: true

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - uses: actions/cache@v4
        with:
          path: |
            ~/.pub-cache
            .dart_tool/
          key: pub-${{ hashFiles('pubspec.lock') }}
      - run: flutter pub get
      - run: dart pub global activate coverde 0.3.0+1
      - name: Verify analyzer pin (smoke check)
        run: |
          if grep -A 1 '^  analyzer:' pubspec.lock | grep -q 'version: "7'; then
            echo "analyzer 7.x confirmed"
          else
            echo "::warning::analyzer pin moved off 7.x — verify FUTURE-TOOL-01 readiness"
          fi
      - name: flutter analyze
        continue-on-error: true   # Phase 6 exit gate flips this blocking (D-04)
        run: flutter analyze --no-fatal-infos
      - name: dart run custom_lint
        continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)
        run: dart run custom_lint
      - name: Audit scanners
        continue-on-error: true   # Phases 3/4/6 exit gates flip individual scanners blocking (D-04)
        run: |
          bash scripts/audit_layer.sh
          bash scripts/audit_dead_code.sh
          bash scripts/audit_providers.sh
          bash scripts/audit_duplication.sh
      - name: Merge findings
        run: dart run scripts/merge_findings.dart
      - uses: actions/upload-artifact@v4
        with:
          name: audit-issues
          path: |
            .planning/audit/issues.json
            .planning/audit/ISSUES.md
            .planning/audit/shards/*.json
            .planning/audit/agent-shards/*.json

  guardrails:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - run: flutter pub get

      # AUDIT-09 — sqlite3_flutter_libs reject. BLOCKING from end of Phase 1.
      - name: Reject sqlite3_flutter_libs in pubspec.lock
        run: |
          if grep -q sqlite3_flutter_libs pubspec.lock; then
            echo "::error::sqlite3_flutter_libs detected in pubspec.lock — conflicts with sqlcipher_flutter_libs"
            exit 1
          fi

      # AUDIT-10 — build_runner stale-diff. BLOCKING from end of Phase 1.
      - name: Build runner clean diff
        run: |
          flutter pub run build_runner build --delete-conflicting-outputs
          if ! git diff --exit-code lib/; then
            echo "::error::Generated files in lib/ are stale — run build_runner locally and commit"
            exit 1
          fi

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

scripts/test_audit_pipeline.sh local orchestrator (greenfield Wave-0 Gap from VALIDATION.md):
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

# Schema sanity check on issues.json
python3 - <<'EOF'
import json
import sys
data = json.load(open('.planning/audit/issues.json'))
findings = data.get('findings', [])
required = {'category', 'severity', 'file_path', 'line_start', 'line_end',
            'description', 'rationale', 'suggested_fix', 'tool_source',
            'confidence', 'status'}
for i, f in enumerate(findings):
    missing = required - set(f.keys())
    if missing:
        print(f'finding[{i}] missing fields: {missing}', file=sys.stderr)
        sys.exit(1)
    if not (f['id'].startswith('LV-') or f['id'].startswith('PH-')
            or f['id'].startswith('DC-') or f['id'].startswith('RD-')):
        print(f'finding[{i}] invalid id: {f["id"]}', file=sys.stderr)
        sys.exit(1)
print(f'[audit:pipeline] {len(findings)} findings validated.')
EOF

echo "[audit:pipeline] OK"
```

scripts/test_idempotency.sh (greenfield Wave-0 Gap):
```bash
#!/usr/bin/env bash
# scripts/test_idempotency.sh
# Runs the full audit pipeline twice and diffs issues.json — proves stable IDs.
set -euo pipefail

bash scripts/test_audit_pipeline.sh
cp .planning/audit/issues.json /tmp/audit_run1.json

bash scripts/test_audit_pipeline.sh

if ! diff -q /tmp/audit_run1.json .planning/audit/issues.json; then
  echo "[audit:idempotency] FAIL: issues.json differs across runs (stable-ID guarantee broken)" >&2
  diff /tmp/audit_run1.json .planning/audit/issues.json | head -40 >&2
  exit 1
fi

echo "[audit:idempotency] OK — issues.json byte-identical across runs"
```

Pinned action versions (RESEARCH §"CI Workflow"; PATTERNS Group G):
- `actions/checkout@v4`
- `subosito/flutter-action@v2`
- `actions/cache@v4`
- `actions/upload-artifact@v4`
- `VeryGoodOpenSource/very_good_coverage@v2`
- `coverde 0.3.0+1` (pin via `dart pub global activate`)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create .github/workflows/audit.yml (3-job CI workflow with staged enablement)</name>
  <files>.github/workflows/audit.yml</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"CI Workflow" (verbatim 3-job workflow body) AND §"Common Pitfalls — P1-11" (cache strategy)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group G — CI Workflow"
    - .planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md (D-04 staged-enablement table; D-05 GitHub Actions choice)
    - CLAUDE.md (`sqlite3_flutter_libs` only — AUDIT-09 prevents accidental adoption; build_runner is mandatory — AUDIT-10 catches stale generation)
  </read_first>
  <action>
    Create the directory and workflow file:
    ```bash
    mkdir -p .github/workflows
    ```

    Write `.github/workflows/audit.yml` with the verbatim content from this plan's `<interfaces>` block (RESEARCH §"CI Workflow"). Critical structural points:

    1. **Three jobs:** `static-analysis`, `guardrails`, `coverage`
    2. **Trigger:** `pull_request: branches: [main]` + `push: branches: [main]`
    3. **Concurrency control:** `concurrency.group: audit-${{ github.ref }}` + `cancel-in-progress: true` (avoids stacking PR runs)
    4. **Cache:** `actions/cache@v4` keyed on `hashFiles('pubspec.lock')` (Pitfall P1-11 — avoids 60+s pub-cache cold-start)
    5. **`coverde` pin:** `dart pub global activate coverde 0.3.0+1` (matches scripts/install_audit_tools.sh from Plan 01)
    6. **Analyzer pin verification step:** `grep -A 1 '^  analyzer:' pubspec.lock | grep -q 'version: "7'` — emits `::warning::` (NOT error) on drift; FUTURE-TOOL-01 deferral

    **`continue-on-error: true` (NON-blocking, report-only) on these steps per D-04 staged enablement:**
    - `flutter analyze` step (flips blocking at end of Phase 6)
    - `dart run custom_lint` step (flips blocking at end of Phase 4)
    - `Audit scanners` step (the 4 audit_*.sh runs; flips blocking at end of Phases 3/4/6)
    - `VeryGoodOpenSource/very_good_coverage@v2` step (flips blocking at end of Phase 2)

    **NO `continue-on-error: true` (BLOCKING) on these steps:**
    - `Reject sqlite3_flutter_libs in pubspec.lock` (AUDIT-09 — blocking from day one per D-04)
    - `Build runner clean diff` (AUDIT-10 — blocking from day one per D-04)
    - `Merge findings` (in `static-analysis` job — the merger MUST succeed for the artifact upload to be meaningful; failure here means the pipeline is broken, not that findings exist)

    **Each `continue-on-error: true` line MUST be commented with the phase that flips it blocking** (per RESEARCH §"CI Workflow — How the blocking flip is implemented" — every fix-phase's `/gsd-verify-work` checklist removes the corresponding `continue-on-error` line, so the comment is the bookkeeping aid).

    **Artifact upload:** `actions/upload-artifact@v4` uploads `.planning/audit/issues.json`, `ISSUES.md`, `shards/*.json`, `agent-shards/*.json` so PR reviewers can see the audit deltas.

    **Coverage job condition:** `if: ${{ github.event_name == 'pull_request' }}` — only runs on PRs, not on `main` push (saves CI time; main-branch coverage is enforced by the `static-analysis` job's static analysis).

    Validate the workflow syntactically. Run a YAML parse check:
    ```bash
    python3 -c "import yaml; yaml.safe_load(open('.github/workflows/audit.yml'))"
    ```
    If `actionlint` is available locally, run it:
    ```bash
    actionlint .github/workflows/audit.yml || echo "(actionlint not installed — skipping; CI will catch issues)"
    ```

    DO NOT add other workflows in this plan. The `.github/workflows/` directory should contain ONLY `audit.yml` after this task. (Phase 2 BASE-06 lives in this same file via the `coverage` job; subsequent phases edit the existing file rather than adding new ones.)

    DO NOT modify any `.dart` file. DO NOT modify `pubspec.yaml` or `analysis_options.yaml` (those were Plan 01's domain).
  </action>
  <verify>
    <automated>test -f .github/workflows/audit.yml && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/audit.yml'))" && grep -q "static-analysis:" .github/workflows/audit.yml && grep -q "guardrails:" .github/workflows/audit.yml && grep -q "coverage:" .github/workflows/audit.yml && grep -q "Reject sqlite3_flutter_libs" .github/workflows/audit.yml && grep -q "Build runner clean diff" .github/workflows/audit.yml && grep -c "continue-on-error: true" .github/workflows/audit.yml | grep -q '^[1-9][0-9]*$'</automated>
  </verify>
  <acceptance_criteria>
    - `.github/workflows/audit.yml` exists
    - File parses as valid YAML: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/audit.yml'))"` exits 0
    - Three jobs declared: `grep -q "^  static-analysis:" .github/workflows/audit.yml && grep -q "^  guardrails:" .github/workflows/audit.yml && grep -q "^  coverage:" .github/workflows/audit.yml`
    - AUDIT-09 step present and BLOCKING (no `continue-on-error: true` in the same step block): the `Reject sqlite3_flutter_libs in pubspec.lock` step contains `exit 1` on positive grep match
    - AUDIT-10 step present and BLOCKING: the `Build runner clean diff` step contains `git diff --exit-code lib/`
    - At least 4 `continue-on-error: true` lines exist (the report-only gates per D-04): `grep -c "continue-on-error: true" .github/workflows/audit.yml` ≥ 4
    - Each `continue-on-error: true` has an inline comment indicating its flip-phase: `grep -E "continue-on-error: true.*Phase" .github/workflows/audit.yml | wc -l` ≥ 4
    - Cache step pinned: `grep -q "actions/cache@v4" .github/workflows/audit.yml && grep -q "hashFiles('pubspec.lock')" .github/workflows/audit.yml`
    - coverde pinned: `grep -q "dart pub global activate coverde 0.3.0+1" .github/workflows/audit.yml`
    - Coverage job is PR-only: `grep -E "if: \\\$\\{\\{ github.event_name == 'pull_request' \\}\\}" .github/workflows/audit.yml`
    - Artifact upload step present: `grep -q "upload-artifact@v4" .github/workflows/audit.yml && grep -q "audit-issues" .github/workflows/audit.yml`
    - All action pins use major-version tags: `grep -E "uses: [^@]+@v[0-9]+" .github/workflows/audit.yml | wc -l` ≥ 5
    - No `.dart` modified: `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0
  </acceptance_criteria>
  <done>
    `.github/workflows/audit.yml` exists with the 3-job staged-enablement workflow. AUDIT-09 + AUDIT-10 gates are blocking; all other gates ship with `continue-on-error: true` per D-04. Cache + coverde pin + analyzer-pin smoke check + artifact upload all in place.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create scripts/test_audit_pipeline.sh + scripts/test_idempotency.sh local-mirror scripts (Wave-0 Gaps)</name>
  <files>scripts/test_audit_pipeline.sh, scripts/test_idempotency.sh</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-VALIDATION.md §"Wave 0 Requirements" (these 2 scripts are flagged as Wave-0 Gaps)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Shared Patterns — Shell script header" (`set -euo pipefail`)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Validation Architecture — Sampling Rate" (full suite command — what test_audit_pipeline.sh should run)
    - scripts/install_audit_tools.sh (Plan 01 Task 3 — confirms shell-script style)
    - scripts/audit_layer.sh, audit_dead_code.sh, audit_providers.sh, audit_duplication.sh (Plan 04 Task 1 — runners)
    - scripts/merge_findings.dart (Plan 05 Task 1 — merger)
  </read_first>
  <action>
    **File 1: `scripts/test_audit_pipeline.sh`** — verbatim from this plan's `<interfaces>` block.

    Critical content:
    - Shebang `#!/usr/bin/env bash`
    - `set -euo pipefail`
    - Run all 4 audit_*.sh scanners
    - Run `dart run scripts/merge_findings.dart`
    - Verify `.planning/audit/issues.json` and `ISSUES.md` exist
    - Use a small Python heredoc to validate the `issues.json` schema (every finding has the 11 required fields + an ID matching `^(LV|PH|DC|RD)-[0-9]{3}$`)
    - Final summary `print` line counting findings

    **File 2: `scripts/test_idempotency.sh`** — verbatim from this plan's `<interfaces>` block.

    Critical content:
    - Shebang + `set -euo pipefail`
    - Invoke `bash scripts/test_audit_pipeline.sh` (don't duplicate logic)
    - Snapshot `cp .planning/audit/issues.json /tmp/audit_run1.json`
    - Run pipeline AGAIN
    - `diff -q /tmp/audit_run1.json .planning/audit/issues.json` — exit 1 if differs (`set -e` propagates)
    - Final OK message

    Then make both executable:
    ```bash
    chmod +x scripts/test_audit_pipeline.sh scripts/test_idempotency.sh
    ```

    Validate syntax:
    ```bash
    bash -n scripts/test_audit_pipeline.sh
    bash -n scripts/test_idempotency.sh
    ```

    Smoke run BOTH scripts end-to-end (Wave 4 — Plans 04, 05 already produced their outputs in Waves 2/3, so this can run now):
    ```bash
    bash scripts/test_audit_pipeline.sh
    bash scripts/test_idempotency.sh
    ```

    Both must exit 0. If `test_idempotency.sh` fails, the merger has a non-determinism bug (Plan 05's TDD test should have caught this; if surfacing here, file an amendment to fix Plan 05).

    DO NOT duplicate Plan 05's TDD logic. The two scripts here are local mirrors of the CI pipeline — they exercise the integrated whole, not unit-test individual functions.

    DO NOT execute `/gsd-audit-semantic` here. The AI-agent shards are NOT consumed by these scripts in Phase 1; the scripts only exercise the 4 tooling shards + merger. Plan 08's end-to-end run (which is the next plan) is where the AI-agent dry-run + full pipeline integration happens.

    DO NOT modify any `.dart` file.
  </action>
  <verify>
    <automated>test -x scripts/test_audit_pipeline.sh && test -x scripts/test_idempotency.sh && bash -n scripts/test_audit_pipeline.sh && bash -n scripts/test_idempotency.sh && bash scripts/test_audit_pipeline.sh && bash scripts/test_idempotency.sh</automated>
  </verify>
  <acceptance_criteria>
    - Both scripts exist and are executable: `for f in scripts/test_audit_pipeline.sh scripts/test_idempotency.sh; do [ -x "$f" ] || exit 1; done`
    - Both have correct shebang + strict mode: `for f in <list>; do head -1 "$f" | grep -q '^#!/usr/bin/env bash$' && grep -q '^set -euo pipefail$' "$f" || exit 1; done`
    - Both pass `bash -n`: `for f in <list>; do bash -n "$f" || exit 1; done`
    - `test_audit_pipeline.sh` invokes all 4 scanners + merger: `for s in audit_layer.sh audit_dead_code.sh audit_providers.sh audit_duplication.sh merge_findings.dart; do grep -q "$s" scripts/test_audit_pipeline.sh || exit 1; done`
    - `test_audit_pipeline.sh` validates the issues.json schema (Python heredoc presence): `grep -q "python3" scripts/test_audit_pipeline.sh && grep -q "issues.json" scripts/test_audit_pipeline.sh`
    - `test_idempotency.sh` runs the pipeline twice + diffs: `grep -q "test_audit_pipeline.sh" scripts/test_idempotency.sh && grep -q "diff " scripts/test_idempotency.sh`
    - End-to-end smoke: `bash scripts/test_audit_pipeline.sh` exits 0
    - Idempotency smoke: `bash scripts/test_idempotency.sh` exits 0 (proves stable IDs)
    - No `.dart` file modified
  </acceptance_criteria>
  <done>
    `scripts/test_audit_pipeline.sh` and `scripts/test_idempotency.sh` exist, are executable, and pass end-to-end smoke locally. Plan 08 will use these scripts to verify the full pipeline + AI-agent dry-run.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| GitHub Actions runner → external action versions | Untrusted action code; mitigated by major-version pinning |
| Pull-request title / branch name → workflow shell | Potential injection if eval'd; mitigated by quoting |
| pubspec.lock → AUDIT-09 grep | Untrusted file content; the grep is a defensive check |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-09 (phase-level) | Tampering | Transitive `sqlite3_flutter_libs` dependency creeping into `pubspec.lock` | mitigate | The AUDIT-09 step `grep -q sqlite3_flutter_libs pubspec.lock && exit 1` IS the mitigation. BLOCKING from end of Phase 1 per D-04. (Plan 01 Task 1 acceptance criterion already verified absence locally; this is the long-term CI enforcement.) |
| T-1-10 (phase-level) | Tampering | Stale `.g.dart` / `.freezed.dart` files committed | mitigate | The AUDIT-10 step `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` IS the mitigation. BLOCKING from end of Phase 1 per D-04. |
| T-1-07-01 | Injection | Workflow command injection via PR title or branch name | mitigate | Workflow does NOT use `${{ github.event.pull_request.title }}` or branch names in shell `run:` blocks. Standard GitHub Actions hygiene per RESEARCH §"Known Threat Patterns". |
| T-1-07-02 | Supply Chain | Malicious `coverde` version pulled by `dart pub global activate` | mitigate | Pin to `0.3.0+1` exactly (RESEARCH §"Known Threat Patterns" + Pitfall P1-11). |
| T-1-07-03 | Supply Chain | Action version drift (e.g., `actions/checkout@v4` updated to a malicious tag) | accept | GitHub's `@v4` major-version moving tag is the standard practice; full SHA pinning would harden further but is out of Phase 1 scope. Phase 8's exit verification re-checks. |
| T-1-07-04 | Tampering | Hand-edited `.planning/audit/agent-shards/*.json` committed by a contributor to mask findings | mitigate | RESEARCH §"Known Threat Patterns" + Plan 05 already mitigates: CI re-runs scanners + merger from a clean checkout, never trusts committed shards. (The `audit-issues` artifact upload is for human review only — not a trust input.) |

T-1-A (audit shards revealing sensitive paths): no new exposure — CI uploads the same artifacts that Phase 1 already commits to `.planning/audit/`. Repo-relative paths only.
</threat_model>

<verification>
1. `.github/workflows/audit.yml` exists, parses as valid YAML, 3 jobs declared
2. AUDIT-09 + AUDIT-10 gates are BLOCKING (no `continue-on-error` on those steps)
3. All other audit gates ship report-only with phase-flip comments per D-04
4. `scripts/test_audit_pipeline.sh` runs end-to-end locally and exits 0
5. `scripts/test_idempotency.sh` runs the pipeline twice and proves byte-identical `issues.json`
6. No `.dart` file modified
</verification>

<success_criteria>
- AUDIT-08 final delivery surface: CI workflow runs the merger + uploads `issues.json`/`ISSUES.md`/shards
- AUDIT-09 satisfied: BLOCKING gate `grep sqlite3_flutter_libs pubspec.lock` exits non-zero
- AUDIT-10 satisfied: BLOCKING gate `build_runner build && git diff --exit-code lib/` exits non-zero on stale generated files
- D-04 staged enablement contract honored: 4+ `continue-on-error: true` lines with phase-flip comments
- `scripts/test_audit_pipeline.sh` + `scripts/test_idempotency.sh` provide local mirror for Plan 08's end-to-end verification
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-07-SUMMARY.md` describing:
- The 3-job CI workflow structure
- The list of `continue-on-error: true` lines (4+) and which phase flips each one blocking
- The two BLOCKING guardrails and what they catch
- Local-mirror scripts and which Wave-0 Gaps they close
- Any deviations from RESEARCH §"CI Workflow"
</output>
