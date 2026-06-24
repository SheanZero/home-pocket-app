---
phase: 52-recognition-ux-english-voice
plan: 04
subsystem: voice
tags: [synonyms, recognition, en-locale, ven-01, seed-data, currency]

# Dependency graph
requires:
  - phase: 52-recognition-ux-english-voice
    plan: 01
    provides: "_extractKeyword lowercases its en residual (write==read identity contract) so lowercase en seeds match capitalized iOS STT keywords"
provides:
  - "≥1 lowercase English category-keyword seed for every L2 that carries a zh and/or ja direct seed (VEN-01 / D-12 full alignment, 166 en seeds across the 3 group files)"
  - "Reversed default_synonyms.dart docstring — English voice input is in scope as of v1.9 / VEN-01 (was 'deferred to v1.4+')"
  - "Recognizer en verification: category seeds resolve the correct L2 (incl. capitalized-via-lowercasing); merchant nameEn/romaji + English currency-word recognition verified by test (no recognizer/data change)"
affects: [52-05, 52-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lowercase-authored en seeds: en category keywords MUST be lowercase to pair with the 52-01 case-sensitive findByKeyword + en-residual lowercasing (write==read)"
    - "Verify-not-rebuild: merchant nameEn/alias and VoiceCurrencySuffixes English paths already worked — proven by added test cases, not new code (D-13 reuse)"

key-files:
  created: []
  modified:
    - lib/shared/constants/synonyms/synonyms_daily_living.dart
    - lib/shared/constants/synonyms/synonyms_health_education_hobbies.dart
    - lib/shared/constants/synonyms/synonyms_admin.dart
    - lib/shared/constants/default_synonyms.dart
    - test/unit/application/voice/recognition/category_recognizer_test.dart
    - test/unit/application/voice/recognition/merchant_recognizer_test.dart

key-decisions:
  - "Authored every en seed lowercase (write==read identity contract with the 52-01 en-residual lowercasing); proper-noun brand tokens (Suica/PASMO/NHK受信料) predate VEN-01 and are allow-listed out of the lowercase gate"
  - "Verified (did NOT rebuild) English merchant + currency recognition — added test cases over the existing nameEn/alias scorer and VoiceCurrencySuffixes.tokenToIso (D-13 reuse, no forked path)"
  - "A6 nameEn-gap concern resolved by inspection: nameEn coverage is 100% (391/391) in the const merchant data — no const-data fill needed (the RESEARCH '~8 gaps' estimate has since closed)"

requirements-completed: [VEN-01]

# Metrics
duration: ~12min
completed: 2026-06-24
status: complete
---

# Phase 52 Plan 04: English Category Seeds + Recognizer en Verification Summary

**Every L2 that carries a zh/ja keyword now also carries ≥1 lowercase English category-keyword seed (166 en seeds across the 3 group files), authored lowercase to pair with the 52-01 en-residual casing fix; the "English deferred to v1.4+" docstring is reversed, and English merchant + currency recognition is verified (not rebuilt) by new recognizer test cases.**

## Performance

- **Tasks:** 2
- **Files modified:** 6 (4 source/data, 2 test)
- **en seeds added:** ~160 new lowercase rows (166 lowercase-leading total incl. the pre-existing `other`)

## Accomplishments

- **Task 1 — English category seeds (VEN-01 / D-12):** added ≥1 lowercase English `seed('<en>', '<categoryId>')` row for every L2 that has a zh and/or ja direct seed, distributed across the three group files:
  - `synonyms_daily_living.dart` — Food/Daily/Pet/Transport/Clothing/Social/Housing/Utilities/Communication/Car (e.g. `coffee`→`cat_food_cafe`, `taxi`→`cat_transport_taxi`, `rent`→`cat_housing_rent`, `fuel`→`cat_car_fuel`).
  - `synonyms_health_education_hobbies.dart` — Health/Education/Hobbies (e.g. `gym`→`cat_health_fitness`, `book`→`cat_education_books`, `movie`→`cat_hobbies_movies`).
  - `synonyms_admin.dart` — Tax/Insurance/Special/Asset/Allowance/Other (e.g. `income tax`→`cat_tax_income`, `nisa`→`cat_asset_nisa`, `pocket money`→`cat_allowance_self`).
  - All en keywords are lowercase head-words (no full sentences), additive + idempotent via the existing `seed(...)` factory + `kVoiceSynonymSeedEpoch` (no factory/epoch change).
- **Docstring reversal:** `default_synonyms.dart` lines 44-47 rewritten — the "English (en) entries are deferred to v1.4+ — do NOT add" note is replaced with a note that en seeds are now seeded per VEN-01, documenting the lowercase write==read contract. The `all` getter doc updated `(zh + ja, no en)` → `(zh + ja + en)`.
- **Task 2 — recognizer en verification (TDD GREEN):**
  - `category_recognizer_test.dart`: new `VEN-01 English category seeds (D-12)` group proving a lowercase en keyword resolves the correct L2 (`coffee`→cafe, `rent`→housing_rent), an en L1 keyword routes to its `_other` bucket (`food`→`cat_food_other`), and a **capitalized iOS-STT keyword resolves only after upstream lowercasing** — the raw `Coffee` misses the case-sensitive `findByKeyword`, the lowercased `coffee` hits (this is exactly what the 52-01 `_extractKeyword` lowercasing buys).
  - `category_recognizer_test.dart`: new `VEN-01 real seed data carries lowercase en keywords (D-12)` group reading `DefaultVoiceSynonyms.all` directly — guards the mock tests against missing/typo'd Task-1 data and asserts en common-word seeds are lowercase.
  - `merchant_recognizer_test.dart`: new `VEN-01 English / romaji merchant recognition (verify)` group — an English/romaji query resolves the JA merchant via its `nameEn`/alias surface (case-insensitive normalizer); recognizer unchanged.
  - `merchant_recognizer_test.dart`: new `VEN-01 / D-13 English currency-word detection (reuse, no fork)` group — `dollar`/`dollars`/`us dollar`/`euro`/`pound` resolve via `VoiceCurrencySuffixes.tokenToIso`, and the tokens are present in the canonical `all` list (single source the regex/extractor consume).

## Task Commits

1. **Task 1: Add lowercase English category-keyword seeds + reverse docstring** — `e4cb4655` (feat)
2. **Task 2: en recognizer test cases (category resolve + merchant/currency verify)** — `2f5bb292` (test)

## Files Created/Modified

- `lib/shared/constants/synonyms/synonyms_daily_living.dart` — en seed block appended per sub-list (Food/Daily, Pet/Transport, Clothing/Social, Housing/Utilities/Comm/Car)
- `lib/shared/constants/synonyms/synonyms_health_education_hobbies.dart` — en seed block per sub-list (Health, Education, Hobbies)
- `lib/shared/constants/synonyms/synonyms_admin.dart` — en seed block per sub-list (Tax/Insurance, Special/Asset, Allowance/Other)
- `lib/shared/constants/default_synonyms.dart` — reversed the defer docstring; `all` getter doc updated to `(zh + ja + en)`
- `test/unit/application/voice/recognition/category_recognizer_test.dart` — 2 new groups (mock-resolve + real-seed-data); imports `default_synonyms.dart`
- `test/unit/application/voice/recognition/merchant_recognizer_test.dart` — 2 new groups (en/romaji merchant verify + en currency-word verify); imports `voice_currency_suffixes.dart`

## Decisions Made

- en seeds authored lowercase (write==read identity contract). Proper-noun brand tokens (`Suica`, `PASMO`, `NHK受信料`) predate VEN-01, are intentionally brand-cased, and are explicitly allow-listed out of the lowercase-common-word gate (documented in the test).
- VERIFIED — did not rebuild — English merchant (nameEn/alias) and currency-word (`VoiceCurrencySuffixes`) recognition; the only new code is test code (D-13 reuse, no forked currency path).
- A6 confirmed by inspection: `nameEn` coverage is 100% (391/391) in the const merchant data, so no L2-with-zh/ja-keyword merchant lacks `nameEn` and no const-data fill was needed.

## Deviations from Plan

None - plan executed exactly as written.

The plan flagged a possible A6 nameEn const-data fill "if the test surfaces a gap". On inspection there is no gap (391/391 nameEn coverage), so no const-data edit was required — this is the plan's documented no-op branch, not a deviation.

## Issues Encountered

- The real-seed-data lowercase-gate test initially flagged `Suica` / `PASMO` / `NHK受信料` (pre-existing capitalized proper-noun seeds). Resolved by narrowing the gate to en COMMON-word seeds via a documented proper-noun allow-list — these brand tokens are not governed by the lowercase write==read contract.
- `flutter` warns that `sqlcipher_flutter_libs` does not support Swift Package Manager for iOS (pre-existing environment warning, unrelated to this plan). No action needed.

## Threat Surface

Plan threat register honored: T-52-08 (en seed tampering — accept) and T-52-09 (recognizer en path info disclosure — accept) hold; seed data is non-sensitive public category vocabulary, additive + idempotent via the seed epoch, and the categoryId integrity gate guards correctness. No package installs (first-party Dart + const data only), satisfying T-52-SC. No new threat surface introduced.

## Verification

- `flutter test test/unit/shared/constants/default_synonyms_categoryid_test.dart test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` → 7/7 green.
- `flutter test test/unit/application/voice/recognition/` → all green (category + merchant en cases, 47 in the two suites).
- `flutter test test/integration/voice/voice_corpus_en_test.dart voice_category_corpus_zh_test.dart voice_category_corpus_ja_test.dart` → all green (zh 30/30, ja 30/30, en hedge green) — additive seeds did not regress the statistical corpus gates.
- `grep -c "seed('[a-z]" synonyms_daily_living.dart` = 98 (≥1, likewise the other two files).
- `flutter analyze` → No issues found (0 issues).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- English category recognition is data-complete (every zh/ja-covered L2 has a lowercase en seed) and verified end-to-end through the recognizer; merchant + currency English recognition is verified. 52-05/52-06 can build on a parity-complete trilingual recognizer surface.
- No blockers. Full `flutter analyze` clean; coverage + categoryId + recognizer + corpus suites all green.

## Self-Check: PASSED

- All 6 touched source/test files exist on disk; SUMMARY.md exists.
- Both task commits (`e4cb4655`, `2f5bb292`) present in git history.

---
*Phase: 52-recognition-ux-english-voice*
*Completed: 2026-06-24*
