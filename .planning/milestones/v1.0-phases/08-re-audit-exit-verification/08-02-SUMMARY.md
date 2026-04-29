---
phase: 08-re-audit-exit-verification
plan: 02
subsystem: ci-coverage-gate
tags: [coverage_gate, audit-yml, cleanup-touched-files, bash-generator, awk-frontmatter-parser]

# Dependency graph
requires:
  - phase: 03-critical-fixes
    provides: PLAN.md frontmatter `files_modified:` discipline (source of truth for the union)
  - phase: 04-high-fixes
    provides: PLAN.md frontmatter `files_modified:` discipline
  - phase: 05-medium-fixes
    provides: PLAN.md frontmatter `files_modified:` discipline
  - phase: 06-low-fixes
    provides: phase6-touched-files.txt (legacy gate input + format analog)
provides:
  - scripts/build_cleanup_touched_files.sh — deterministic Bash generator parsing Phase 3-6 PLAN.md frontmatter
  - .planning/audit/cleanup-touched-files.txt — 170-entry Phase 3-6 union of lib/ files (per-file ≥80% coverage gate input)
  - audit.yml line 107 swap — coverage_gate.dart --list now points at cleanup-touched-files.txt
  - phase6-touched-files.txt header comment marking it as historical artifact (D-04 compliance)
affects: [08-03 (audit.yml hardening), 08-08 (ADR-011 amendment cites cleanup-touched-files.txt path)]

# Tech tracking
tech-stack:
  added: [bash awk frontmatter parser]
  patterns: [audit_*.sh precedent (set -euo pipefail, [tag] echo lines, OK trailer), sort -u byte-stable output]

key-files:
  created:
    - scripts/build_cleanup_touched_files.sh
    - .planning/audit/cleanup-touched-files.txt
  modified:
    - .github/workflows/audit.yml
    - .planning/audit/phase6-touched-files.txt

key-decisions:
  - "Bash generator chosen over Dart per CONTEXT D-04 'How to apply' note — matches existing scripts/audit_*.sh + scripts/build_coverage_baseline.sh precedent."
  - "Generated list does NOT filter .g.dart / .arb files — coverde filter (audit.yml line 105) and lcov source set already exclude them; coverage_gate.dart silently treats missing-from-lcov entries as 0% with a WARNING. Filtering at generation time would diverge from the literal 'files_modified' frontmatter."
  - "phase6-touched-files.txt kept on disk with prepended header comment (per D-04 'How to apply'). Comment is harmless because audit.yml no longer references the file; manual local invocations would see the warning, deemed acceptable."
  - "Touched audit.yml only at line 107 (--list arg swap) — top-of-file warning block, continue-on-error sweep, and `if: pull_request` lift are 08-03's job to keep merges clean."

patterns-established:
  - "Pattern: audit list generators emit byte-stable output via sort -u + Bash awk frontmatter parsing. Reproducible by anyone with `bash scripts/build_cleanup_touched_files.sh`."
  - "Pattern: legacy gate-input artifacts kept on disk with single-line header comment (`# Superseded by ...`) when superseded; never renamed/deleted."

requirements-completed: [EXIT-04]

# Metrics
duration: ~10min
completed: 2026-04-28
---

# Phase 08 Plan 02: Cleanup-Touched-Files Generator + Audit Gate Swap Summary

**Deterministic Bash generator produces a 170-entry Phase 3-6 union of `lib/` files (cleanup-touched-files.txt) and audit.yml line 107 now consumes it as the per-file ≥80% coverage gate input — replacing the 19-entry phase6-touched-files.txt that previously let regressions slip through any non-Phase-6 cleanup file.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-28T06:16:00Z (approx)
- **Completed:** 2026-04-28T06:26:04Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- Authored `scripts/build_cleanup_touched_files.sh` — a 58-line, deterministic Bash generator that globs `.planning/phases/0[3-6]-*/*-PLAN.md`, awk-parses each plan's `files_modified:` frontmatter (handling bare `- path` and quoted `- "path"` / `- 'path'` forms), filters to `lib/` paths via `grep -E '^lib/'`, then `sort -u` for byte-stable, deduped output.
- Generated `.planning/audit/cleanup-touched-files.txt` — **170 entries** (vs 19 in the legacy phase6-touched-files.txt). All entries `lib/`-prefixed, comment-free, sorted, deduped, trailing-newline-terminated.
- Swapped `.github/workflows/audit.yml` line 107 — `coverage_gate.dart --list .planning/audit/cleanup-touched-files.txt` (replacing `phase6-touched-files.txt`). `--threshold 80` and `--lcov coverage/lcov_clean.info` preserved unchanged. Single-line edit, minimal merge surface for 08-03.
- Prepended a one-line historical-artifact header comment to `.planning/audit/phase6-touched-files.txt` per D-04 "How to apply"; original 19 paths preserved verbatim.

## Task Commits

Each task was committed atomically:

1. **Task 1: build_cleanup_touched_files.sh + cleanup-touched-files.txt** — `a990700` (feat)
2. **Task 2: audit.yml swap + phase6-touched-files.txt header** — `d329c1b` (chore)

## Files Created/Modified

- `scripts/build_cleanup_touched_files.sh` (created, 58 lines, executable) — Bash generator producing cleanup-touched-files.txt deterministically from Phase 3-6 PLAN.md frontmatter.
- `.planning/audit/cleanup-touched-files.txt` (created, 170 lines) — Union of lib/ files modified across Phases 3-6; per-file ≥80% coverage gate input.
- `.github/workflows/audit.yml` (modified, 1 line) — Line 107 `--list` argument swapped from phase6-touched-files.txt to cleanup-touched-files.txt.
- `.planning/audit/phase6-touched-files.txt` (modified, +1 line) — Prepended historical-artifact header comment; 19 original lib/ paths preserved verbatim.

## Decisions Made

- **Bash over Dart for the generator** — CONTEXT D-04 "How to apply" explicitly preferred Bash to match `scripts/audit_*.sh` + `scripts/build_coverage_baseline.sh` precedent; awk handles YAML frontmatter parsing without needing `package:yaml`.
- **Did not filter `.g.dart` / `.arb` from the generated list** — These appear in `files_modified:` frontmatter (legitimately, since plans regenerate them) but are filtered out downstream by `coverde filter` (audit.yml line 105 patterns) and never appear in lcov source. `coverage_gate.dart` will emit `WARNING: ... not in lcov source — treating as 0%` for them, but since coverage_gate's exit semantic is "fail if any file with lcov data is below threshold", missing-from-lcov entries do not block CI. This keeps the generator output a literal mirror of plan frontmatter and avoids divergence.
- **No `# header` in cleanup-touched-files.txt itself** — `coverage_gate.dart` at line 84 (`f.readAsLinesSync().where((l) => l.trim().isNotEmpty)`) does NOT skip `#`-prefixed lines; they would be passed through as fictitious paths. Kept the file comment-free (per Plan acceptance criterion `grep -c '^#' ... = 0`).
- **Touched audit.yml only at line 107** — Plan 08-03 explicitly owns the top-of-file warning block, `continue-on-error` sweep, and the `if: pull_request` lift on the coverage job. Pre-applying any of those here would create avoidable merge churn for 08-03.

## Deviations from Plan

None - plan executed exactly as written.

The generator script, output file, audit.yml swap, and phase6-touched-files.txt header comment all match their respective plan specs verbatim. All acceptance criteria (per-line invariants, line counts, sanity-check path presence, audit.yml grep counts, phase6 body diff) verified empty/zero where expected.

## Issues Encountered

None. The awk frontmatter parser handled all four phases' PLAN.md formats on first run (no quoting variants encountered; all entries used the bare `- path` form). All sanity-check paths (`lib/main.dart`, `lib/application/i18n/formatter_service.dart`, `lib/application/family_sync/sync_engine.dart`) appeared exactly once each.

## Self-Check: PASSED

Verified after writing:
- `scripts/build_cleanup_touched_files.sh` exists, 58 lines, executable (`-x`), shebang `#!/usr/bin/env bash`, contains `set -euo pipefail` (1 hit), 7 `[cleanup:touched]` log tag occurrences.
- `.planning/audit/cleanup-touched-files.txt` exists, 170 lines, 0 non-`lib/` lines, 0 `#`-prefix lines, 0 trailing-whitespace lines, sorted unique (`diff <(sort -u file) file` empty), trailing newline present.
- `.planning/audit/phase6-touched-files.txt` 20 lines (1 header + 19 paths), `head -1` matches "Superseded by ..." comment, `diff` of body (lines 2-20) vs `git show HEAD~1:.planning/audit/phase6-touched-files.txt` is empty.
- `.github/workflows/audit.yml`: 0 `phase6-touched-files.txt` references, 1 `cleanup-touched-files.txt` reference, full coverage_gate line `coverage_gate.dart --list .planning/audit/cleanup-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info` present once, `name: audit` and `very_good_coverage` each present once (no other content disturbed).
- Both task commits (`a990700`, `d329c1b`) found in `git log --oneline`.

## Threat Surface Scan

No new threat surface beyond plan's `<threat_model>`. The two mitigations from the plan (T-08-02-01, T-08-02-03) are wired:
- T-08-02-01 (Tampering of generator): `grep -E '^lib/'` filter + `sort -u` byte-stable output as planned.
- T-08-02-03 (DoS via wrong list path): single-line audit.yml edit; `coverage_gate.dart` exits 2 with explicit error if list path missing.

No omitted threats from the threat register.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 08-03 can proceed without conflict: `.github/workflows/audit.yml` line 107 is committed and stable; 08-03 will edit different lines (top-of-file comment block, line 89 `if: pull_request` removal, residual `continue-on-error` sweep).
- Plan 08-08 (ADR-011 amendment) can cite `cleanup-touched-files.txt` path + line count (170) directly from this committed state.
- The generator script is reproducible by anyone with `bash scripts/build_cleanup_touched_files.sh` — no hidden state. If Phase 3-6 PLAN.md frontmatter ever changes, re-running the script regenerates the artifact deterministically.

---
*Phase: 08-re-audit-exit-verification*
*Completed: 2026-04-28*
