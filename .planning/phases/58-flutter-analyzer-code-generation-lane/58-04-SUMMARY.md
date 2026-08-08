---
phase: 58-flutter-analyzer-code-generation-lane
plan: "04"
subsystem: ci-tooling
tags: [github-actions, flutter, analyzer, import_lint, riverpod_lint, code-generation]
requires:
  - phase: 57-stable-baseline-compatibility-contract
    provides: Stable Flutter/Dart identity and fail-closed baseline validator
  - plan: 58-02
    provides: Exact analyzer 12.1.0/import_lint 2.0.0/Riverpod 3.1.4 compatibility graph
  - plan: 58-03
    provides: Source-tested two-pass reproducible-generation wrapper
provides:
  - Stable CI invokes one authoritative reproducibility, lint, architecture, and negative-tooling wrapper
  - Guardrails retains only lock-enforced release and security contracts without a generator duplicate
  - Baseline validation recognizes the authoritative wrapper and rejects comment-only proof
affects: [58-05, Stable CI, architecture enforcement, release gates]
actuals:
  tokens: 3825
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Stable YAML source contracts inspect active commands, invocation uniqueness, ordering, and hard-failure semantics.
    - The baseline validator accepts the wrapper as the sole Stable SDK-verification route while beta probes remain separate.
key-files:
  created: []
  modified:
    - .github/workflows/audit.yml
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
key-decisions:
  - "Stable static-analysis owns exactly one call to verify_codegen_reproducibility.sh after the exact Flutter setup; all generation, analyzer/import_lint/Riverpod, architecture, and negative-tooling evidence stays inside that wrapper."
  - "Guardrails uses flutter pub get --enforce-lockfile only for its release/security checks and does not repeat generation or lint gates."
  - "The dependency compatibility validator treats an active wrapper call—not a duplicate inline SDK-validator command—as the required Stable CI baseline proof."
patterns-established:
  - "Reject comment-only, duplicated, reordered, inline, and soft-failed CI gate mutations in source contracts."
requirements-completed: [GEN-01, GEN-02, GEN-03, GEN-04]
coverage:
  - id: D1
    description: Stable static-analysis invokes one hard-failing authoritative wrapper after the exact Flutter setup and before audit-only scanners.
    requirement: GEN-01
    verification:
      - kind: integration
        ref: "test/architecture/dependency_compatibility_contract_test.dart#Stable CI routes post-generation lint and architecture gates through one wrapper"
        status: pass
    human_judgment: false
  - id: D2
    description: The Stable workflow has no alternate inline generator, analyzer, import_lint, tooling-guard, or direct architecture route; guardrails retains lock-enforced retrieval for release/security checks.
    requirement: GEN-03
    verification:
      - kind: integration
        ref: "test/architecture/dependency_compatibility_contract_test.dart#Stable CI keeps one authoritative codegen wrapper without guardrails duplicates"
        status: pass
      - kind: integration
        ref: "test/architecture/codegen_reproducibility_contract_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: The exact analyzer 12.1.0/import_lint 2.0.0/Riverpod 3.1.4 graph remains validated through the active wrapper-only Stable CI path.
    requirement: GEN-02
    verification:
      - kind: integration
        ref: "flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/codegen_reproducibility_contract_test.dart"
        status: pass
      - kind: integration
        ref: "dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk"
        status: pass
    human_judgment: false
  - id: D4
    description: Reproducible two-pass generation, post-generation quality order, and reversible tooling guards remain source-tested for the wrapper used by Stable CI.
    requirement: GEN-04
    verification:
      - kind: integration
        ref: "test/architecture/codegen_reproducibility_contract_test.dart"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-08
status: complete
---

# Phase 58 Plan 04: Stable CI Wrapper Gate Summary

**Stable CI now runs the exact locked, two-pass generation, analyzer/import_lint/Riverpod, architecture, and negative-tooling contract through one source-tested wrapper.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-08T17:49:34+09:00
- **Completed:** 2026-08-08T17:55:00+09:00
- **Tasks:** 2
- **Files modified:** 3 implementation files, plus planning evidence

## Accomplishments

- Replaced Stable static-analysis's direct dependency-resolution, baseline-validation, analyzer, and import-lint path with one ordered wrapper invocation after the Flutter 3.44.8 setup.
- Removed guardrails' stale one-pass build_runner block and made its release/security-only dependency retrieval lock-enforced.
- Added fail-first source contracts for missing, commented, duplicate, reordered, inline, and soft-failed wrapper paths; corrected the baseline validator to validate the wrapper route itself.

## Task Commits

1. **Task 1: Route Stable analysis and architecture proof through the authoritative wrapper** — `bacd9f22` (test RED), `4035e4b4` (feat GREEN)
2. **Task 2: Remove the alternate guardrails generator path and lock wrapper uniqueness** — `c5b1d532` (test RED), `e36f2786` (feat GREEN), `265f553b` (fix: lint-clean validator correction)

## Files Created/Modified

- `.github/workflows/audit.yml` — one Stable wrapper call in static-analysis; no guardrails generator duplicate.
- `scripts/dependency_compatibility.dart` — recognizes the active wrapper as Stable baseline evidence and ignores YAML comments.
- `test/architecture/dependency_compatibility_contract_test.dart` — mutation contracts for wrapper ownership, uniqueness, ordering, and failure propagation.

## Decisions Made

- Stable static-analysis is the sole CI owner of the authoritative wrapper; its scanners, finding merge, and artifact upload remain after that gate.
- Guardrails preserves release-signing, preflight, and SQLCipher-package rejection checks but has no parallel code-generation or architecture path.
- The active analyzer 12.1.0/import_lint 2.0.0/Riverpod 3.1.4 graph remains canonical; obsolete custom_lint/import_guard tooling was not restored.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Align baseline CI validation with the wrapper-only gate**
- **Found during:** Task 2
- **Issue:** `scripts/dependency_compatibility.dart` required a direct inline baseline-validator command in `audit.yml`, so the wrapper-only Stable gate made the exact-graph validator fail even though the wrapper runs that validator first.
- **Fix:** Required one active `verify_codegen_reproducibility.sh` invocation instead, rejected comment-only YAML markers, and updated its source-contract regression test.
- **Files modified:** `scripts/dependency_compatibility.dart`, `test/architecture/dependency_compatibility_contract_test.dart`
- **Verification:** 49 targeted workflow/wrapper-contract tests and the baseline validator passed.
- **Committed in:** `e36f2786`, `265f553b`

---

**Total deviations:** 1 auto-fixed Rule 2 correction.
**Impact on plan:** The Stable gate is now internally consistent without reintroducing an alternate inline validation path.

## Issues Encountered

- The repository-wide analyzer exits zero with its existing informational backlog. The two files changed by this plan have no analyzer findings; no unrelated production lint cleanup was included.

## User Setup Required

None.

## Next Phase Readiness

- Plan 58-05 can execute the live wrapper plus the full targeted, full-suite, coverage, and whitespace evidence matrix.
- GEN-01 through GEN-04 remain globally pending until shared-ID readiness is reconciled; this plan does not claim native, platform, beta, simulator, device, or full-suite evidence.

## Self-Check: PASSED

Confirmed all three implementation files and all planning artifacts exist; each of the five TDD/task commits is present. The future-beta workflow hash remains `68a5c3114e23dafa823d5c1a5cfb6248e871b82b9b68c515203e6b72c0429e49`, and the implementation diff contains no native, platform, or product-source files.

---
*Phase: 58-flutter-analyzer-code-generation-lane*
*Completed: 2026-08-08*
