---
phase: 21
plan: 05
subsystem: voice
tags: [voice, resolver, category, refactor, cleanup]
dependency_graph:
  requires:
    - VoiceCategoryResolver (Plan 21-03)
    - explicit-L2 merchant entries (Plan 21-04)
    - SeedVoiceSynonymsUseCase + provider (Plan 21-02)
  provides:
    - "ParseVoiceInputUseCase wired to VoiceCategoryResolver (always-L2 contract end-to-end)"
    - "voiceCategoryResolverProvider as the SOLE category-resolution surface in repository_providers"
    - "PATTERNS.md §9 caveat closed — merchant branch routes through resolver._ensureL2"
  affects:
    - "VOICE-04 + VOICE-05 satisfied through production code paths"
    - "D-06 + D-08 cleanup (no edit-distance, no _seedKeywordMap, no FuzzyCategoryMatcher)"
tech_stack:
  added: []
  patterns:
    - "Defensive null-fallback: when resolver returns null on merchant branch, raw merchant categoryId is surfaced rather than dropped"
key_files:
  modified:
    - lib/application/voice/parse_voice_input_use_case.dart
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - lib/features/accounting/presentation/providers/repository_providers.g.dart
    - lib/application/voice/voice_category_resolver.dart
    - test/unit/application/voice/parse_voice_input_use_case_test.dart
    - test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart
  deleted:
    - lib/application/voice/fuzzy_category_matcher.dart
    - lib/application/voice/levenshtein.dart
    - test/unit/application/voice/fuzzy_category_matcher_test.dart
    - test/unit/application/voice/levenshtein_test.dart
decisions:
  - "Routed the merchant branch through VoiceCategoryResolver.resolve (PATTERNS.md §9 caveat) instead of leaving it as a direct merchantMatch.categoryId pass-through — closes the always-L2 escape hatch"
  - "Kept _extractKeyword in ParseVoiceInputUseCase (CONTEXT discretion #5) — resolver stays focused on lookup, text cleanup stays in the use case"
  - "Added a defensive null-fallback on the merchant branch: if the resolver returns null (e.g. merchant id missing from category repo), surface the raw merchant categoryId with source=merchant rather than dropping the category entirely"
  - "Deleted lib/application/voice/levenshtein.dart together with fuzzy_category_matcher.dart (sole consumer); grep verified no other call sites"
  - "Pruned only fuzzy_category_matcher.dart from hardcoded_cjk_ui_scan_test.dart approvedWhitelist; left default_synonyms.dart and Phase 20 NLP lexicon entries intact per parallel_execution constraint"
metrics:
  duration_minutes: 8
  completed: 2026-05-24
---

# Phase 21 Plan 05: Voice Category Resolver Swap + Cleanup Summary

One-liner: ParseVoiceInputUseCase now consumes VoiceCategoryResolver end-to-end; merchant branch also routed through resolver._ensureL2 (PATTERNS.md §9 caveat closed); FuzzyCategoryMatcher + levenshtein.dart and their tests deleted; CJK allow-list pruned.

## What Changed

Wave 3 / Plan 05 is the production-wiring swap that retires the pre-Phase-21 multi-signal matcher and makes `VoiceCategoryResolver` the sole category-resolution surface for voice input. Four atomic commits, in dependency order:

1. **Task 1 — `refactor(21-05): swap ParseVoiceInputUseCase to VoiceCategoryResolver`** (commit `83193ec`)
   Replaced the `FuzzyCategoryMatcher` dependency with `VoiceCategoryResolver` in the use case. The merchant branch now ALSO calls `resolver.resolve(recognizedText, merchantMatch.merchantName)` so the always-L2 contract has no escape hatch — even if MerchantDatabase regresses and yields an L1 id, the resolver normalizes it to L2. `merchantMatch.ledgerType` continues to win when present. Added a defensive fallback: if the resolver returns null on the merchant branch, surface the raw merchant `categoryId` with `MatchSource.merchant` rather than dropping the category entirely. `_extractKeyword` stays in the use case (CONTEXT discretion #5).

2. **Task 2 — `test(21-05): swap parse_voice_input_use_case_test to VoiceCategoryResolver mock`** (commit `fb19669`)
   Rewrote `parse_voice_input_use_case_test.dart` to use `_MockVoiceCategoryResolver` instead of `_MockFuzzyCategoryMatcher`. Restructured the merchant-branch test to stub `resolver.resolve` (proving the new always-L2 routing), added a new defensive-fallback test (resolver returns null → raw merchant id surfaces), and updated the localeId routing test to mock the resolver instead. 6/6 tests pass.

3. **Task 3 — `refactor(21-05): swap fuzzyCategoryMatcherProvider for voiceCategoryResolverProvider`** (commit `3c5d237`)
   In `lib/features/accounting/presentation/providers/repository_providers.dart`: deleted the `@riverpod fuzzyCategoryMatcher` provider, added `@riverpod voiceCategoryResolver` provider wired to `categoryRepository`, `categoryKeywordPreferenceRepository`, `categoryService`, and `appMerchantDatabaseProvider`. Updated `parseVoiceInputUseCase` provider to consume the new resolver. Regenerated `repository_providers.g.dart` — the `FuzzyCategoryMatcherProvider` class is removed, `VoiceCategoryResolverProvider` is added.

4. **Task 4 — `chore(21-05): delete FuzzyCategoryMatcher + levenshtein + retire stale tests`** (commit `2076608`)
   Deleted `lib/application/voice/fuzzy_category_matcher.dart` (334-line multi-signal scorer + `_seedKeywordMap` + `_KeywordMapping` + `_ScoredCandidate`), `lib/application/voice/levenshtein.dart` (sole consumer was the fuzzy matcher — grep verified no other call sites), and their tests. Updated `voice_providers_characterization_test.dart` to assert `voiceCategoryResolverProvider constructs VoiceCategoryResolver`. Pruned `lib/application/voice/fuzzy_category_matcher.dart` from `test/architecture/hardcoded_cjk_ui_scan_test.dart` approvedWhitelist (left `default_synonyms.dart` and all Phase 20 NLP lexicon entries intact per parallel_execution constraint).

## Architecture Outcomes

D-06 + D-08 satisfied. The pre-Phase-21 multi-signal matcher is fully gone:
- `FuzzyCategoryMatcher` class + its private `_KeywordMapping` / `_ScoredCandidate` helpers — deleted.
- `_seedKeywordMap` (the ~70-entry hardcoded keyword map) — deleted (synonyms now live in `category_keyword_preferences` with `hitCount=0` seed sentinel from Plans 02 + 04).
- `_matchEditDistance` and `levenshtein.dart` — deleted (low signal-to-noise in production; pipeline now relies on canonical merchant names + user-extensible synonyms).

D-09 satisfied. `voiceCategoryResolverProvider` is now the SOLE category-resolution provider in `repository_providers.dart`. The Riverpod graph is consistent with the rest of the codebase:
- Provider def: `@riverpod VoiceCategoryResolver voiceCategoryResolver(Ref ref)` at lines 229-241.
- Consumer: `parseVoiceInputUseCase` watches `voiceCategoryResolverProvider` (line 247).
- All four resolver dependencies (`categoryRepository`, `categoryKeywordPreferenceRepository`, `categoryService`, `appMerchantDatabaseProvider`) are watched via existing provider names from earlier waves.

PATTERNS.md §9 caveat closed. The previously-latent "merchant branch bypasses `_ensureL2`" surface is now closed: both branches in `ParseVoiceInputUseCase.execute` route through `_voiceCategoryResolver.resolve`. If `MerchantDatabase` ever regresses to returning L1 ids, the resolver's `_ensureL2` will rewrite them to `${l1Id}_other` before the result reaches the screen.

## Verification

- `flutter analyze` — 4 pre-existing issues unrelated to this plan (2 in `build/ios/SourcePackages/firebase_messaging-16.2.2/` third-party code; 2 `onReorder` deprecations in `category_selection_screen.dart`). None introduced by 21-05.
- `flutter pub run build_runner build --delete-conflicting-outputs` — clean (228 outputs written; .g.dart has `voiceCategoryResolverProvider`, zero `FuzzyCategoryMatcherProvider` references).
- `flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart` — 6/6 pass.
- `flutter test test/unit/application/voice/voice_category_resolver_test.dart` — passes (resolver tests from Plan 03 remain green; resolver class unchanged here).
- `flutter test test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart` — 7/7 pass (with the new `voiceCategoryResolverProvider` assertion).
- `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` — passes (allow-list consistent with post-delete file tree).
- `flutter test test/unit/application/voice/` (full voice unit suite) — 104/104 pass.
- `grep -rn "FuzzyCategoryMatcher\|fuzzy_category_matcher" lib/ test/` — 0 hits.
- `grep -rn "levenshteinDistance\|normalizedSimilarity" lib/ test/` — 0 hits.

## Deviations from Plan

None of significance. Two minor on-the-fly tweaks worth recording:

1. **[Rule 1 — Bug] Replaced `if (categoryMatch == null) { ... }` with `categoryMatch ??= ...`** in the use case's defensive fallback. The original `if` form drew a `prefer_conditional_assignment` analyzer lint. Equivalent behavior, cleaner expression. Files modified: `lib/application/voice/parse_voice_input_use_case.dart`. Same commit as Task 1 (`83193ec`).

2. **[Rule 2 — Auto-add] Trimmed `FuzzyCategoryMatcher` from the dartdoc comment in `voice_category_resolver.dart`.** The original dartdoc said "Replaces FuzzyCategoryMatcher (deleted in Plan 05 …)" — after the deletion in Task 4, this reference would have failed the plan's done-criterion `grep -rn "FuzzyCategoryMatcher" lib/ test/` returns 0 hits (excluding .planning/*). Replaced with "pre-Phase-21 multi-signal matcher" to keep the historical context without leaving a dangling symbol reference. Same commit as Task 4 (`2076608`).

No CLAUDE.md directives were touched in either case (no provider duplication, no domain→data leakage, no analyzer warnings introduced).

## Known Stubs

None. All resolver call sites return real data; merchant branch defensive fallback uses real `merchantMatch.categoryId`. No empty arrays, no `null` placeholders flowing to UI.

## Self-Check: PASSED

Verified the following claimed artifacts exist on disk and at the recorded commits:
- `lib/application/voice/parse_voice_input_use_case.dart` — FOUND at commit `83193ec`
- `lib/features/accounting/presentation/providers/repository_providers.dart` — FOUND at commit `3c5d237`
- `lib/features/accounting/presentation/providers/repository_providers.g.dart` — FOUND at commit `3c5d237` (regenerated)
- `lib/application/voice/voice_category_resolver.dart` — FOUND at commit `2076608` (dartdoc cleanup)
- `test/unit/application/voice/parse_voice_input_use_case_test.dart` — FOUND at commit `fb19669`
- `test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart` — FOUND at commit `2076608`
- `test/architecture/hardcoded_cjk_ui_scan_test.dart` — FOUND at commit `2076608` (allow-list pruned)
- `lib/application/voice/fuzzy_category_matcher.dart` — VERIFIED DELETED at commit `2076608`
- `lib/application/voice/levenshtein.dart` — VERIFIED DELETED at commit `2076608`
- `test/unit/application/voice/fuzzy_category_matcher_test.dart` — VERIFIED DELETED at commit `2076608`
- `test/unit/application/voice/levenshtein_test.dart` — VERIFIED DELETED at commit `2076608`

All four commits present in `git log --oneline`:
- `83193ec refactor(21-05): swap ParseVoiceInputUseCase to VoiceCategoryResolver`
- `fb19669 test(21-05): swap parse_voice_input_use_case_test to VoiceCategoryResolver mock`
- `3c5d237 refactor(21-05): swap fuzzyCategoryMatcherProvider for voiceCategoryResolverProvider`
- `2076608 chore(21-05): delete FuzzyCategoryMatcher + levenshtein + retire stale tests`
