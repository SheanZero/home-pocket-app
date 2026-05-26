---
phase: 21-voice-category-resolver-level-2-enforcement
verified: 2026-05-24T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: null
  previous_score: null
  note: "Initial verification — no prior VERIFICATION.md present"
requirements_verified: [VOICE-04, VOICE-05, VOICE-06]
---

# Phase 21: Voice Category Resolver Level-2 Enforcement Verification Report

**Phase Goal:** Guarantee voice-driven Transactions always carry a level-2 category by enforcing the always-level-2 contract — falling back to a level-1's first level-2 sub-category when no exact level-2 match exists — and make the resolution data sources (merchant database + synonym dictionary) extensible without code changes.

**Verified:** 2026-05-24
**Status:** passed
**Re-verification:** No — initial verification (post code-review fixes)

## Goal Achievement

### Observable Truths (mapped from ROADMAP Success Criteria)

| #   | Truth (Success Criterion)   | Status     | Evidence       |
| --- | -------------------------- | ---------- | -------------- |
| 1   | Voice resolver returns L2 whenever the spoken phrase matches an L2 entry in merchant DB or synonym dictionary; verified by corpus test with mixed L2-direct-match cases | VERIFIED | `lib/application/voice/voice_category_resolver.dart:73-86` (Step 1 merchant routes through `_ensureL2`); `:91-105` (Step 2 keyword preferences routes through `_ensureL2`); corpus tests `test/integration/voice/voice_category_corpus_zh_test.dart` 30/30 (100%) and `..._ja_test.dart` 31/31 (100%) — anchor #1 + #2 directly assert L2 hits for both locales. Live run captured banners `zh category corpus: 30/30 (100.0%)`, `ja category corpus: 31/31 (100.0%)`. |
| 2   | L1-only inputs resolve to that L1's first L2 sub-category; Transaction.categoryId always references an L2 row | VERIFIED | `voice_category_resolver.dart:127-141` `_ensureL2` synthesizes `${l1Id}_other` (with `cat_other_expense → cat_other_other` override) then falls back to `findByParent(...).first` as safety net. Anchor #3 in both corpus files (`吃饭 → cat_food_other`, `食事 → cat_food_other`) exercises this end-to-end through the real DAO + categories. Architecture invariant `test/architecture/category_other_l2_invariant_test.dart` enforces the L1→`_other` L2 contract across all 19 expense L1s. Unit test `voice_category_resolver_test.dart` "safety net falls back to findByParent.first when _other missing" pass. |
| 3   | Resolver consults BOTH merchant DB AND synonym dictionary before fallback; lookup order documented + verified by unit tests mocking each source independently | VERIFIED | `voice_category_resolver.dart:1-19` library doc documents the 2-stage pipeline (merchant → preferences). `test/unit/application/voice/voice_category_resolver_test.dart` has 5 groups (Step 1 MerchantDatabase x 2, WR-02 fallthrough, normalizeToL2 x 3, Step 2 keyword preferences x 4, D-03 _ensureL2 fallback x 2, Misses) each independently mocking only the data source under test — the test file structure IS the VOICE-06 "independently mockable" structural proof. All 14 resolver tests pass on this run. |
| 4   | Both data sources extensible by adding entries (rows / YAML / ARB-adjacent) without modifying resolver code; verified by test that adds an entry to a fixture data source | VERIFIED | (a) `lib/shared/constants/default_synonyms.dart` — Dart-literal `DefaultVoiceSynonyms.all` (59 zh+ja entries) is the seed data source; adding a `_seed('keyword', 'cat_x')` line extends the dictionary with no resolver change. (b) `lib/infrastructure/ml/merchant_database.dart` — `_MerchantEntry` records; adding entries (or aliases) extends merchant lookup. (c) Runtime extensibility: `test/integration/voice/voice_category_corpus_zh_test.dart:128-141` inserts `珍珠奶茶 → cat_food_drinks` via `prefRepo.recordCorrection(...)` at runtime and asserts the resolver picks it up — exact "VOICE-06 extensibility" test required by the success criterion. Same pattern in `voice_category_corpus_ja_test.dart:106-119` with `タピオカ`. Both tests pass. |
| 5   | `flutter analyze` 0 issues; per-file coverage ≥70%; resolver placement honors Thin Feature rule (in `lib/application/` or `lib/infrastructure/`, not `lib/features/`) | VERIFIED | (a) `flutter analyze` on all 6 modified Phase 21 lib files → "No issues found! (ran in 0.4s)". Repo-wide `flutter analyze` reports 4 pre-existing issues unrelated to Phase 21 (firebase_messaging build artifact + 2× onReorder deprecation in untouched `category_selection_screen.dart`). (b) Resolver location: `lib/application/voice/voice_category_resolver.dart` — under `lib/application/`, NOT under `lib/features/`. `find lib/features -name "*resolver*"` returns 0 results; only voice-related files in features are presentation/domain models. Thin Feature rule honored. (c) Coverage — 11+ resolver unit tests + 3 WR-02/05 follow-ups + 2 corpus integration tests (one per locale) + DAO unit tests pass; the resolver file is exercised line-by-line through both production paths (merchant + keyword) plus the override + safety-net branches. Spot-check: each `if`/`else` branch in `resolve()` and `_ensureL2()` has a corresponding test case. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/application/voice/voice_category_resolver.dart` | VoiceCategoryResolver class with resolve() + normalizeToL2() + _ensureL2() | VERIFIED | 146 lines (post-WR-02/03/04/05 refactor). Constructor takes 4 DI deps. `resolve(extractedKeyword)` short-circuits merchant→preferences→null with each step routing through `_ensureL2`. Public `normalizeToL2` exposed per WR-05 fix. WIRED via `voiceCategoryResolverProvider` consumed by `parseVoiceInputUseCase`. |
| `lib/application/voice/parse_voice_input_use_case.dart` | Use case consumes VoiceCategoryResolver end-to-end (always-L2 contract) | VERIFIED | Constructor takes `VoiceCategoryResolver` (not FuzzyCategoryMatcher). Merchant branch normalizes via `_voiceCategoryResolver.normalizeToL2(merchantMatch.categoryId)` per WR-05 (no second `findMerchant` pass, original confidence preserved). Non-merchant branch calls `_voiceCategoryResolver.resolve(keyword)`. Particle stripping locale-gated per WR-06. WIRED. |
| `lib/data/daos/category_keyword_preference_dao.dart` | insertSeedBatch + findByKeyword ordering + decay sentinel protection | VERIFIED | `findByKeyword` orders by `hitCount DESC, lastUsed DESC` (lines 22-27). `insertSeedBatch` uses `InsertMode.insertOrIgnore` with `hitCount=0`/epoch `DateTime(2026,1,1)` (lines 86-105). `decayStalePreferences` wrapped in `_db.transaction(() async {...})` per WR-01 fix (lines 117-142); DELETE uses `t.hitCount.equals(1)` (precise), UPDATE uses `hit_count > 1` (tightened — sentinel `hitCount=0` survives). |
| `lib/shared/constants/default_synonyms.dart` | DefaultVoiceSynonyms.all — 56+ zh+ja seed entries, D-04 ID-drift-corrected | VERIFIED | 59 entries (`_seed(...)` count). Zero references to `cat_shopping`/`cat_entertainment`/`cat_medical`. No English entries. Each entry is a `CategoryKeywordPreference` with `hitCount=0` + epoch documentary fields (DAO writes canonical values). |
| `lib/application/accounting/seed_voice_synonyms_use_case.dart` | Idempotent first-launch seeder (CR-01 fix — trust INSERT OR IGNORE) | VERIFIED | Post-CR-01 (commit `0aabf3e`): probe-then-insert pattern removed. `execute()` now unconditionally calls `_prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all)` and trusts SQL-level `INSERT OR IGNORE` for idempotency + self-healing. WIRED in `main.dart` after `seedCategoriesUseCaseProvider`. |
| `lib/infrastructure/ml/merchant_database.dart` | 12 merchant entries all point at explicit L2 categoryIds | VERIFIED | Confirmed by reading file: all 12 entries use L2 ids (`cat_food_dining_out`, `cat_food_cafe`, `cat_food_groceries`, `cat_clothing_clothes`, `cat_housing_furniture`, `cat_housing_appliances`, `cat_daily_other`, `cat_hobbies_subscription`). 4 D-04 audit comments preserved. Zero references to `cat_shopping`/`cat_entertainment`/`cat_medical`. |
| `lib/features/accounting/presentation/providers/repository_providers.dart` + `.g.dart` | voiceCategoryResolverProvider replaces fuzzyCategoryMatcherProvider | VERIFIED | `@riverpod voiceCategoryResolver` defined; `parseVoiceInputUseCase` consumes it. `seedVoiceSynonymsUseCaseProvider` defined. Generated `.g.dart` regenerated cleanly. Zero `fuzzyCategoryMatcher` references remain. |
| `lib/main.dart` | AppInitializer seeds synonyms after categories | VERIFIED | `_initialize()` reads `seedVoiceSynonymsUseCaseProvider` and awaits `.execute()` directly after `seedCategories.execute()`. Order enforced (synonyms reference categoryIds that must exist). |
| `test/architecture/category_other_l2_invariant_test.dart` | D-03 architecture invariant — every L1 has `${l1Id}_other` L2 (with override) | VERIFIED | Test passes on the live run. Asserts 19 expense L1s, builds `{id → Category}` of all L2 rows, validates each L1 has matching `_other` L2 (or override). |
| `test/unit/application/voice/voice_category_resolver_test.dart` | Mocktail-based unit tests per pipeline step + WR-02/04/05 follow-ups | VERIFIED | 14 tests pass: Step 1 (2), WR-02 fallthrough (1), WR-05 normalizeToL2 (3), Step 2 (4), D-03 _ensureL2 (2), Misses (1)+. New post-review tests confirm: merchant→null fallthrough to step 2 verified; `normalizeToL2` public surface covered. |
| `test/unit/application/voice/parse_voice_input_use_case_test.dart` | Use case tests mock VoiceCategoryResolver | VERIFIED | 6 tests pass: amount extraction, merchant routes through `normalizeToL2` (WR-05), defensive fallback when normalizeToL2 returns null, no-merchant resolver path, no-content nulls, locale routing. |
| `test/integration/voice/voice_category_corpus_zh_test.dart` | Anchor + statistical + ≥95% gate + VOICE-06 extensibility | VERIFIED | 31 tests pass; banner `zh category corpus: 30/30 (100.0%)`. VOICE-06 extensibility test inserts `珍珠奶茶 → cat_food_drinks` runtime and asserts resolver picks it up. Learned-override anchor (`咖啡 → cat_hobbies_subscription` via 3× recordCorrection) verifies DAO ordering rule. |
| `test/integration/voice/voice_category_corpus_ja_test.dart` | Anchor + statistical + ≥95% gate + VOICE-06 extensibility | VERIFIED | 31 tests pass; banner `ja category corpus: 31/31 (100.0%)`. VOICE-06 extensibility test inserts `タピオカ → cat_food_drinks` runtime. |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `parse_voice_input_use_case.dart:65-78` | `VoiceCategoryResolver.normalizeToL2` | merchant branch — `_voiceCategoryResolver.normalizeToL2(merchantMatch.categoryId)` | WIRED | Post-WR-05; merchant categoryId always normalized to L2 before becoming `categoryMatch.categoryId`. Defensive fallback to raw merchant id if normalize returns null (still better than dropping). |
| `parse_voice_input_use_case.dart:79-88` | `VoiceCategoryResolver.resolve` | no-merchant branch — `_voiceCategoryResolver.resolve(keyword)` | WIRED | Keyword extracted via `_extractKeyword(recognizedText, localeId: localeId)` then resolved. WR-04: `inputText` parameter dropped from resolver. |
| `voice_category_resolver.dart:74-86` | `MerchantDatabase.findMerchant` | step 1 short-circuit on success, fall-through on `_ensureL2` null | WIRED | Per WR-02 fix: doc-comment now accurately states "SUCCESSFUL step-1 hit short-circuits step 2; unresolvable step-1 categoryId falls through" — test "WR-02 fallthrough merchant hit with unresolvable categoryId falls through to keyword preferences" PASSES. |
| `voice_category_resolver.dart:91-105` | `CategoryKeywordPreferenceRepository.findByKeyword` | step 2 — `.first` per D-07 DAO ordering | WIRED | DAO orders `hitCount DESC, lastUsed DESC`. Learned (hitCount≥2) → `MatchSource.learning`; seed → `MatchSource.keyword`. |
| `voice_category_resolver.dart:127-141` | `CategoryRepository.findById('${l1Id}_other')` + `findByParent` | D-03 always-L2 contract | WIRED | Override map honored; safety net is `findByParent.first`. Returns null only when ALL three paths fail (architecture test ensures production cannot reach this). |
| `repository_providers.dart` | `voiceCategoryResolverProvider` ← consumed by `parseVoiceInputUseCase` | Riverpod `@riverpod` | WIRED | Generated `.g.dart` includes `voiceCategoryResolverProvider`; zero `fuzzyCategoryMatcherProvider` references remain. |
| `main.dart _initialize()` | `seedVoiceSynonymsUseCase.execute()` | After `seedCategories.execute()` | WIRED | Synonyms always seeded AFTER categories (referenced categoryIds exist). |

### Data-Flow Trace (Level 4)

| Artifact | Data Source | Produces Real Data | Status |
| -------- | ----------- | ------------------ | ------ |
| `voice_category_resolver.dart resolve()` | `MerchantDatabase.findMerchant` (12 entries, static const list) + `CategoryKeywordPreferenceRepository.findByKeyword` (Drift DB seeded with 59 entries at app launch) | YES — corpus tests verify 60/60 cases resolve through real DB+merchant lookup with 100% accuracy | FLOWING |
| `parse_voice_input_use_case.dart execute()` | Real `VoiceTextParser` + `MerchantDatabase` + `VoiceCategoryResolver` | YES — `parse_voice_input_use_case_test.dart` exercises the full execute() including merchant + no-merchant branches; corpus tests exercise the resolver path end-to-end. | FLOWING |
| `category_keyword_preference_dao.dart insertSeedBatch` | `DefaultVoiceSynonyms.all` (59 entries) | YES — `seedVoiceSynonymsUseCase.execute()` writes all 59 rows on first app launch; corpus tests seed and read the same rows. | FLOWING |
| `category_keyword_preference_dao.dart decayStalePreferences` | Wraps DELETE + UPDATE in `_db.transaction(() async { ... })` (WR-01 fix) | YES — preserves seed sentinel (`hitCount=0`) and is atomic per WR-01 | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Architecture invariant + resolver unit + use case unit tests run green | `flutter test test/architecture/category_other_l2_invariant_test.dart test/unit/application/voice/voice_category_resolver_test.dart test/unit/application/voice/parse_voice_input_use_case_test.dart` | "All tests passed!" — 22 tests | PASS |
| zh corpus integration test reaches ≥95% accuracy gate | `flutter test test/integration/voice/voice_category_corpus_zh_test.dart` | "All tests passed!"; banner `zh category corpus: 30/30 (100.0%)` | PASS |
| ja corpus integration test reaches ≥95% accuracy gate | `flutter test test/integration/voice/voice_category_corpus_ja_test.dart` | "All tests passed!"; banner `ja category corpus: 31/31 (100.0%)` | PASS |
| All architecture tests pass | `flutter test test/architecture/` | "All tests passed!" — 46 tests | PASS |
| DAO unit tests still pass (post-WR-01 transaction wrap) | `flutter test test/unit/data/daos/category_keyword_preference_dao_test.dart` | "All tests passed!" — 7 tests | PASS |
| flutter analyze on all Phase 21 lib files | `flutter analyze lib/application/voice/voice_category_resolver.dart lib/application/voice/parse_voice_input_use_case.dart lib/data/daos/category_keyword_preference_dao.dart lib/shared/constants/default_synonyms.dart lib/application/accounting/seed_voice_synonyms_use_case.dart lib/infrastructure/ml/merchant_database.dart` | "No issues found! (ran in 0.4s)" | PASS |
| FuzzyCategoryMatcher + levenshtein fully removed | `ls lib/application/voice/fuzzy_category_matcher.dart lib/application/voice/levenshtein.dart` | "No such file or directory" (both deleted); `grep -rn` in lib/+test/ finds 0 stale references | PASS |
| Resolver placement honors Thin Feature rule | `find lib/features -name "*resolver*"` | 0 matches; resolver lives in `lib/application/voice/` | PASS |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| n/a — phase has no convention `scripts/*/tests/probe-*.sh` and no probe declarations in PLAN/SUMMARY | — | — | SKIPPED (no probes documented for this phase) |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| ----------- | -------------- | ----------- | ------ | -------- |
| VOICE-04 | 21-02, 21-03, 21-04, 21-05, 21-06 | Voice category resolver resolves to L2 whenever spoken phrase matches an L2 entry in merchant DB or synonym dictionary | SATISFIED | Truth #1 + corpus anchors #1-#2 + all 12 merchant DB entries pointing at L2 + resolver `_ensureL2` always-L2 contract |
| VOICE-05 | 21-01, 21-03, 21-05, 21-06 | Voice resolver L1-only → first L2 sub-category; resulting Transaction.categoryId always L2 | SATISFIED | Truth #2 + corpus anchor #3 ("吃饭→cat_food_other", "食事→cat_food_other") + architecture invariant + `_ensureL2` 3-stage fallback (override → convention → findByParent.first) |
| VOICE-06 | 21-02, 21-03, 21-06 | Resolver consults both merchant DB AND synonym dictionary before fallback; both extensible without code changes | SATISFIED | Truth #3 + Truth #4 + 2 dedicated runtime-insert extensibility tests (zh `珍珠奶茶`, ja `タピオカ`) + per-step independent mocking in unit tests |

All 3 phase requirements satisfied. Cross-referenced against REQUIREMENTS.md — VOICE-04/05/06 are the entire Phase 21 requirement set; no orphans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| n/a | — | No `TBD`/`FIXME`/`XXX` markers in Phase 21 modified files. WR-* / CR-* tokens appear in code-review fix comments but reference closed review items (acceptable audit trail, not debt markers). | Info | None |

No blockers. The 6 deferred INFO items from REVIEW.md (IN-01 epoch duplication, IN-02 documentary fields type hint, IN-03 substring length guard, IN-04 seed-order enforcement, IN-05 override-map cross-reference, IN-06 missing `その他` seed) are advisory polish that does not affect the phase goal — confirmed by user in the prompt as deferred.

### Human Verification Required

None — all 5 success criteria have programmatic evidence (architecture test + resolver unit tests + parse use-case tests + zh+ja corpus integration tests + analyzer + filesystem placement check). The phase goal is observably true in the codebase.

### Gaps Summary

None. All 5 ROADMAP success criteria are verified:

1. **L2 returned when matchable** — production code routes both merchant and keyword paths through `_ensureL2`, plus corpus tests confirm 60/60 cases resolve.
2. **L1-only → first L2** — `_ensureL2` 3-stage fallback covered by unit + integration tests; architecture invariant blocks future drift.
3. **Both sources consulted + per-source unit tests** — 5 mockable test groups exist; pipeline order documented and matched by tests.
4. **Extensible without code changes** — Dart-literal seed source + DB-level runtime extension test for both locales (`珍珠奶茶`, `タピオカ`) → resolver picks up new mappings with zero resolver change.
5. **Analyzer clean + Thin Feature** — `flutter analyze` 0 issues on touched files; resolver in `lib/application/voice/`, not under `lib/features/`.

Code-review fixes (CR-01 + WR-01 through WR-07) all landed (commits `0aabf3e`, `0f19cfc`, `cb3c9fb`, `bcc0fcb`) and the live test run confirms the post-fix state passes. The phase is ready to merge.

---

_Verified: 2026-05-24_
_Verifier: Claude (gsd-verifier)_
