---
quick_id: 260707-wq1
slug: main-ci-run-28872322982-build-runner-ana
date: 2026-07-07
status: complete
commits:
  - 0157a25d  # fix: regenerate stale .g.dart (guardrails)
  - 6f692592  # test: defer analytics repository_providers (coverage)
---

# Quick Task 260707-wq1 — SUMMARY

**Goal:** Make `main` CI run 28872322982 green. Two independent job failures.

## What was wrong

| Job | Step | Failure |
|-----|------|---------|
| guardrails | Build runner clean diff | committed `.g.dart` stale vs. source |
| coverage | Per-file coverage gate | 1 file `68.97% (40/58)` < 70 threshold |

Failing commit `d6e05ebd` == local HEAD with a clean tree, so both reproduced
locally. Local Flutter **3.44.0 / Dart 3.12.0** is byte-identical to CI
`stable-3.44.0`, so regeneration is faithful to what CI expects.

## Root cause

- **Staleness** — introduced by **quick-260707-hb8**, source edited without a
  `build_runner` regen:
  - `95b12c18` wrapped a `state_list_transactions.dart` dartdoc token
    `Set<String>` → `` `Set<String>` ``; riverpod copies leading dartdoc onto
    generated elements → `state_list_transactions.g.dart` drifted (5 doc lines).
  - `bfb73107` pushed `memberFilteredCategoryBreakdown` to SQL, changing its
    provider signature → its `_$…Hash()` drifted in `state_analytics.g.dart`.
  - Net diff: **6 lines, doc-comment + hash only, zero behaviour.**
- **Coverage** — `lib/features/analytics/presentation/providers/repository_providers.dart`
  is pure provider-wiring: 20 `@riverpod` use-case getters, zero branching. Its
  gap **cascades** from the already-deferred `analytics_screen.dart` (53%),
  which is the only transitive exerciser. Structurally identical to the 3
  `application/*/repository_providers.dart` entries already deferred.

## Changes

1. **`0157a25d` (fix)** — regenerated `state_analytics.g.dart` +
   `state_list_transactions.g.dart` via `build_runner build`. No source/behaviour change.
2. **`6f692592` (test)** — appended a dated block to
   `.planning/audit/coverage-gate-deferred.txt` deferring the analytics
   presentation `repository_providers.dart` with required rationale under
   FUTURE-TOOL-03. Phase-8 provenance left intact (append-only).

No production code changed. No new tests (the deferred-list rationale is
explicit that tests for these plumbing files "add noise without catching real
bugs"). Not pushed — GSD-quick leaves merge/push to the user.

## Verification (evidence)

```
# guardrails
$ git diff --exit-code lib/          → clean ✓ (deterministic regen @ 3.44.0)

# coverage — full CI job reproduced locally with the updated deferred list
$ flutter test --coverage            → All tests passed! (3733 passed, 11 skipped, 0 failed)
$ coverde filter … lcov_clean.info   → ok
$ dart run scripts/coverage_gate.dart --list … --deferred … --threshold 70 …
  [coverage:gate] DEFERRED: …/analytics/presentation/providers/repository_providers.dart — 69% …
  [coverage:gate] 54 checked, 0 failed, 105 missing-from-lcov (skipped), 11 deferred (skipped)
  GATE EXIT: 0 ✓   (was: 55 checked, 1 failed)
```

## Follow-ups
- **Push required** to turn CI green (2 code commits + 1 docs commit on `main`).
- FUTURE-TOOL-03 now carries 11 entries; the analytics provider file lifts for
  free once `analytics_screen.dart` gets its deferred widget test.
- Optional alternative (not taken): a small provider test to nudge the file
  ≥70% instead of deferring — rejected as fragile (1-line miss) and contrary to
  the project's documented stance on plumbing tests.
