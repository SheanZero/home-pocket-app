---
phase: 21-voice-category-resolver-level-2-enforcement
plan: "03"
subsystem: application-voice
tags: [flutter, dart, voice, category, resolver, application-layer, mocktail, tdd, d-07, d-03, d-08, d-09]

requires:
  - "21-01: D-03 architecture invariant + _otherIdOverrides convention"
  - "21-02: CategoryKeywordPreferenceRepository.findByKeyword DAO ordering (hitCount DESC, lastUsed DESC)"

provides:
  - "VoiceCategoryResolver (lib/application/voice/voice_category_resolver.dart) — short-circuit pipeline (D-07) with strict MerchantDatabase → category_keyword_preferences ordering"
  - "_otherIdOverrides const map shared shape — mirrors test/architecture/category_other_l2_invariant_test.dart::_otherIdOverrides (cat_other_expense → cat_other_other) for the D-03 L1→${l1Id}_other fallback"
  - "_ensureL2 private method — D-03 always-L2 contract: L2 input returned unchanged; L1 input synthesized via _otherIdOverrides or ${l1Id}_other; safety net via findByParent.first when both fail"
  - "resolveLedgerType pass-through — thin delegate to CategoryService.resolveLedgerType (used by Plan 05 ParseVoiceInputUseCase rewire)"
  - "11-test mocktail suite (test/unit/application/voice/voice_category_resolver_test.dart) — VOICE-06 structural assertion: every group stubs only its target data source"

affects:
  - "21-05 (FuzzyCategoryMatcher deletion + ParseVoiceInputUseCase rewire): the resolver compiles standalone today and will become the consumed dependency once Plan 05 swaps the use case off FuzzyCategoryMatcher."
  - "21-06 (Voice category corpus integration tests): corpus tests will consume the resolver against a seeded in-memory Drift DB."

tech-stack:
  added: []
  patterns:
    - "Short-circuit pipeline orchestrator — strict step ordering, no score-merge, no edit-distance (inverts FuzzyCategoryMatcher's 3-signal merge)."
    - "L1→L2 contract enforcement via centralized _ensureL2 helper — both pipeline steps route through it, so the public surface always returns L2."
    - "Override map mirrored from architecture test — single source of convention shared between runtime and CI invariant."
    - "Mocktail per-step isolation as the VOICE-06 structural proof — each group() stubs only the source it tests; verifyNever on earlier-step sources where applicable."

key-files:
  created:
    - lib/application/voice/voice_category_resolver.dart
    - test/unit/application/voice/voice_category_resolver_test.dart
  modified: []

key-decisions:
  - "Kept _extractKeyword in ParseVoiceInputUseCase (Plan 05 scope) — resolver takes a pre-extracted keyword. Rationale: keeps the resolver's surface lookup-focused and testable without text-cleanup mocks (per PATTERNS.md §9 recommendation)."
  - "_otherIdOverrides duplicated as a top-level const map (NOT exported) — duplicates the architecture test's map shape. Single source-of-convention enforced by the architecture test failing if the runtime forgets to mirror a new entry; explicit cross-file comment on both sides."
  - "_ensureL2 returns null when L1 has neither _other nor children — the resolver's public method then returns null and the screen surfaces a manual-pick affordance. Avoids returning bare L1 (D-03 violation) or silently picking an unrelated L2."
  - "Confidence formula `(0.85 + scoreBonus).clamp(0.0, 1.0)` — preserved verbatim from FuzzyCategoryMatcher._matchLearned; both seed (bonus=0.15) and learned (bonus=0.30) end at the 1.0 ceiling. Documented in the test 'confidence formula clamps to 1.0' assertion."

requirements-completed: [VOICE-04, VOICE-05, VOICE-06]

duration: ~12 min
completed: 2026-05-24
---

# Phase 21 Plan 03: Voice Category Resolver Implementation Summary

**One-liner:** Implements `VoiceCategoryResolver` — the application-layer short-circuit pipeline that always returns an L2 categoryId by routing MerchantDatabase and category_keyword_preferences hits through `_ensureL2` (D-03 + D-07 + D-08 + D-09), plus 11 mocktail unit tests structurally proving VOICE-06's "independently mockable data sources" contract.

## Performance

- **Duration:** ~12 min
- **Tasks:** 2 (both `tdd="true"`)
- **Commits:** 2 (1 per task)
- **Files created:** 2 (1 lib, 1 test)
- **Files modified:** 0

## Accomplishments

- **Resolver class (`lib/application/voice/voice_category_resolver.dart`, 121 lines)** — Dependency-injects 4 sources (CategoryRepository, CategoryKeywordPreferenceRepository, CategoryService, MerchantDatabase). Public `resolve(inputText, extractedKeyword)` runs the strict-short-circuit D-07 pipeline:
  1. `MerchantDatabase.findMerchant(extractedKeyword)` → if hit, route through `_ensureL2` → `MatchSource.merchant` + merchant confidence.
  2. `CategoryKeywordPreferenceRepository.findByKeyword(extractedKeyword)` → take `.first` (DAO orders hitCount DESC, lastUsed DESC per Plan 02) → route through `_ensureL2` → `MatchSource.learning` when `isLearned` (hitCount ≥ 2), else `MatchSource.keyword`. Confidence `(0.85 + scoreBonus).clamp(0.0, 1.0)`.
  3. Miss → `null` (screen surfaces manual-pick affordance, Phase 22).
- **Private `_ensureL2(categoryId)` (D-03 always-L2 contract)** — L2 input returned unchanged; L1 input synthesized via `_otherIdOverrides[id] ?? '${id}_other'` and validated via `findById`; falls back to `findByParent(id).first` as the documented safety net; returns `null` only when neither path resolves (rare — architecture test in Plan 01 prevents this in production).
- **`_otherIdOverrides` const map** — Single key `{'cat_other_expense': 'cat_other_other'}`, mirrors the override map installed by Plan 01's architecture test. File-level doc comment references the architecture test by path so future maintainers see the cross-file invariant.
- **`resolveLedgerType` thin pass-through** — Delegates to `CategoryService.resolveLedgerType`, preserving the public surface FuzzyCategoryMatcher exposes today; consumed by Plan 05's ParseVoiceInputUseCase rewire.
- **D-08 honored** — Zero references to `levenshtein`, `normalizedSimilarity`, `_matchEditDistance`, `_KeywordMapping`, `_ScoredCandidate`, or `_seedKeywordMap` in the resolver source (grep-verified == 0 per done-criteria).
- **D-09 honored** — Resolver lives at `lib/application/voice/voice_category_resolver.dart`, alongside `voice_text_parser.dart` / `voice_chunk_merger.dart` / `parse_voice_input_use_case.dart`. Thin Feature rule respected (never under `lib/features/`).
- **Unit tests (`test/unit/application/voice/voice_category_resolver_test.dart`, 296 lines, 11 tests / 5 groups, all green)** —
  - `Step 1: MerchantDatabase` (2 tests): L2 hit returns merchant source + correct confidence + `verifyNever` on preference repo; L1 merchant result defensively routed through `_ensureL2` to `${l1Id}_other`.
  - `Step 2: keyword preferences` (4 tests): direct L2 hit (source=keyword, hitCount=0 → bonus=0.15); L1 → `_other` fallback; learned-override-wins simulating the DAO's hitCount-DESC ordering (source=learning); confidence formula clamping verified for both seed and learned paths.
  - `D-03 _ensureL2 fallback` (2 tests): `cat_other_expense` → `cat_other_other` override map honored when synthesized id is null; `findByParent.first` safety net when both override and `${l1Id}_other` are null.
  - `Misses` (2 tests): all-miss returns null; empty input guard returns null AND `verifyNever` on both merchantDb and prefRepo (proves the guard short-circuits before any source call).
  - `resolveLedgerType pass-through` (1 test): `verify(...).called(1)` against `CategoryService.resolveLedgerType` with the resolver-forwarded categoryId.
- **VOICE-06 structural assertion** — Each test group stubs ONLY the data source it exercises. Step 1 tests don't touch the prefRepo (and assert `verifyNever`); Step 2 tests stub `findMerchant` to return null then stub `findByKeyword`; D-03 tests isolate the `_ensureL2` lookups by chaining `findById` stubs per categoryId; misses test asserts both sources are skipped. This pattern itself proves each source is independently mockable (the test FILE is the structural proof).

## Task Commits

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 | Implement VoiceCategoryResolver — short-circuit pipeline + _ensureL2 with override map | `522d4ad` |
| 2 | VoiceCategoryResolver unit tests (mocktail, per-step VOICE-06 coverage) | `718677f` |

## Files Created

- `lib/application/voice/voice_category_resolver.dart` (121 lines) — `library;` header + 6 imports + `_otherIdOverrides` const map + `class VoiceCategoryResolver` with private fields, the 4-source constructor, `resolve()`, `_ensureL2()`, and `resolveLedgerType()`.
- `test/unit/application/voice/voice_category_resolver_test.dart` (296 lines) — 4 mocktail mocks + `_makeCategory` factory + `_pref` factory helper + 5 groups × total 11 tests.

## Decisions Made

1. **`_extractKeyword` stays in ParseVoiceInputUseCase** (not relocated into the resolver). Rationale: resolver takes a pre-extracted keyword so its surface stays lookup-focused. Plan 05 handles the use-case rewire and decides whether to relocate text-cleanup at that point.
2. **`_otherIdOverrides` duplicated, NOT shared via import.** The architecture test (Plan 01) owns one copy; the resolver owns its own. Cross-file comments on both sides anchor the convention. Centralizing into a shared constants file is possible but would coupled `lib/application/voice/` to either `lib/shared/constants/` or a new `lib/application/voice/constants.dart`; the current duplication is small (2 entries max envisioned in v1.3) and the architecture test fails loud if either side drifts.
3. **`(0.85 + scoreBonus).clamp(0.0, 1.0)` formula preserved verbatim** from FuzzyCategoryMatcher._matchLearned. Both seed (bonus=0.15) and learned (bonus=0.30) land at 1.0 after clamp — documented explicitly in the 'confidence formula clamps to 1.0 for both seed and learned' test so the design isn't subtly broken by a future refactor.
4. **Empty-input guard runs before any data-source call.** `if (extractedKeyword.isEmpty && inputText.isEmpty) return null;` — both `mockMerchantDb.findMerchant` and `mockPrefRepo.findByKeyword` are protected by `verifyNever` in the corresponding test, so the guard is structurally verified.
5. **No `score-merge` logic.** Strictly short-circuit (per D-07): merchantDb hit short-circuits step 2 entirely, no candidate merging. This is the documented inversion of FuzzyCategoryMatcher's 3-signal merge that D-07 mandates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Done-criteria literal compliance] Doc-comment substring `_matchEditDistance` initially appeared in resolver header.**
- **Found during:** Task 1 verification (done-criteria grep for D-08 forbidden tokens returned 1 instead of 0).
- **Issue:** Plan's `<action>` step 1 quoted a doc-comment line "Replaces FuzzyCategoryMatcher (D-06/D-08 removed _matchSeedKeywords + _matchEditDistance)". Quoting the dead method names verbatim made the literal grep `grep -c "levenshtein\|normalizedSimilarity\|_matchEditDistance\|_KeywordMapping\|_ScoredCandidate\|_seedKeywordMap"` return 1 (the `_matchEditDistance` substring in the comment), failing the truths invariant "grep returns 0 references in the new file".
- **Fix:** Rephrased the doc-comment without literal forbidden identifiers — "D-06 dropped the hardcoded seed map and D-08 dropped edit-distance scoring". Same semantic content, no dead identifiers re-introduced. Pattern mirrors Plan 02's identical deviation (where literal `cat_shopping`/`cat_entertainment`/`cat_medical`/`recordCorrection` were rephrased for the same reason).
- **Files modified:** `lib/application/voice/voice_category_resolver.dart`
- **Commit:** Folded into `522d4ad` (single Task 1 commit, before staging).

**2. [Rule 3 — Worktree environment] Worktree missing `.dart_tool/` for analyzer/test infrastructure.**
- **Found during:** Initial verification.
- **Issue:** Fresh worktree did not have `.dart_tool/`; `dart analyze` and `flutter test` both require it.
- **Fix:** Ran `flutter pub get` once. No code changes (`.dart_tool/` is gitignored). This is the same setup step Plan 02 and Plan 04 documented; the orchestrator may want to pre-populate worktrees in future waves to avoid the per-plan re-run.
- **Files modified:** None committed.
- **Commit:** n/a.

No Rule 1 / Rule 2 / Rule 4 deviations. No checkpoints hit. No auth gates.

## Verification

| Check | Command | Result |
| ----- | ------- | ------ |
| Resolver static analysis | `dart analyze lib/application/voice/voice_category_resolver.dart` | "No issues found!" |
| Test static analysis | `dart analyze test/unit/application/voice/voice_category_resolver_test.dart` | "No issues found!" |
| Both files together | `flutter analyze lib/application/voice/voice_category_resolver.dart test/unit/application/voice/voice_category_resolver_test.dart` | "No issues found! (ran in 0.7s)" |
| Test suite | `flutter test test/unit/application/voice/voice_category_resolver_test.dart` | "11/11 tests passed" |
| Resolver class count | `grep -c "class VoiceCategoryResolver"` | 1 (expected 1) |
| Override map refs | `grep -c "_otherIdOverrides"` resolver | 4 (expected ≥ 2) |
| cat_other_expense key | `grep -c "cat_other_expense"` resolver | 2 (expected ≥ 1) |
| D-08 forbidden tokens | `grep -c "levenshtein\|normalizedSimilarity\|_matchEditDistance\|_KeywordMapping\|_ScoredCandidate\|_seedKeywordMap"` resolver | 0 (expected 0) |
| Pipeline method refs | `grep -c "findMerchant\|findByKeyword\|_ensureL2\|findById\|findByParent\|resolveLedgerType"` resolver | 13 (expected ≥ 6) |
| Test group count | `grep -c "group("` test | 5 (expected ≥ 5) |
| cat_other_other in tests | `grep -c "cat_other_other"` test | 5 (expected ≥ 1) |
| Mock class refs | `grep -c "_MockMerchantDatabase\|_MockCategoryRepository\|_MockCategoryKeywordPreferenceRepository\|_MockCategoryService"` test | 12 (expected ≥ 4) |
| Post-commit deletions | `git diff --diff-filter=D --name-only HEAD~1 HEAD` (each commit) | empty (no deletions) |

## TDD Gate Compliance

Both tasks were marked `tdd="true"` in the plan, but the plan ordered Task 1 (implementation) before Task 2 (tests) — a structural-then-behavioral split rather than the canonical RED→GREEN→REFACTOR. The plan's `<verify>` block for Task 1 is `dart analyze` (structural), and Task 2's is `flutter test` (behavioral), so the gate sequence within Plan 03 is:

- **Task 1 commit (`522d4ad`):** `feat(...)` — implementation passes `dart analyze` (structural verification only).
- **Task 2 commit (`718677f`):** `test(...)` — 11 tests written against the implementation; all pass on first run, validating the implementation behaviorally.

No `refactor(...)` commit was needed — the implementation passed all 11 behavioral tests without modification. The Task 2 commit serves as the GREEN gate for the resolver's behavioral contract; the Task 1 commit serves as the structural gate. The two-commit split (rather than RED→GREEN interleave) matches the plan's explicit ordering.

## Known Stubs

None. The resolver is wired to four real interfaces (CategoryRepository, CategoryKeywordPreferenceRepository, CategoryService, MerchantDatabase); no placeholder values, no `UnimplementedError`, no hardcoded empty literals flowing to UI. The class compiles standalone — Plan 05 will wire the resolver into the Riverpod provider graph by replacing `fuzzyCategoryMatcherProvider` with `voiceCategoryResolverProvider` in `repository_providers.dart`.

## Threat Flags

None. The resolver consumes existing repositories and an existing infrastructure service. No new network endpoints, no new auth surface, no new file-access patterns, no schema changes. The only new surface is the in-memory `_otherIdOverrides` const map (single static key), which is data-only and not a trust-boundary concern.

## Self-Check: PASSED

- FOUND: `lib/application/voice/voice_category_resolver.dart` (121 lines, contains `class VoiceCategoryResolver`).
- FOUND: `test/unit/application/voice/voice_category_resolver_test.dart` (296 lines, 5 groups, 11 tests).
- FOUND commit `522d4ad` (Task 1 — feat resolver) on branch `worktree-agent-a00dde9d7da5005ab`.
- FOUND commit `718677f` (Task 2 — test resolver) on branch `worktree-agent-a00dde9d7da5005ab`.
- VERIFIED: `flutter test test/unit/application/voice/voice_category_resolver_test.dart` → 11/11 pass.
- VERIFIED: `flutter analyze lib/application/voice/voice_category_resolver.dart test/unit/application/voice/voice_category_resolver_test.dart` → 0 issues.
- VERIFIED: Each commit's `git diff --diff-filter=D --name-only HEAD~1 HEAD` is empty (no deletions).
- VERIFIED: No untracked files left in the working tree after both commits.
- VERIFIED: All 12 grep-based done-criteria pass with the expected counts.
