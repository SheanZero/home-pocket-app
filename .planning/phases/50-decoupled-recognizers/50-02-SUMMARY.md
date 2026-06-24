---
phase: 50-decoupled-recognizers
plan: 02
subsystem: voice
tags: [voice, category-recognizer, keyword-seed, l2-coverage, i18n, drift-seed]

# Dependency graph
requires:
  - phase: 49-merchant-data-foundation
    provides: DefaultCategories L2 taxonomy + seed-categoryId integrity test pattern (cloned for the synonym gate)
provides:
  - DefaultVoiceSynonyms full-L2 keyword seed (138 of 138 L2 ids, each with >=1 zh + >=1 ja direct seed; 515 rows)
  - seed-keyword-categoryId hard gate (orphan-categoryId build break)
  - full-L2 coverage gate (every L2 proven to have a zh+ja direct seed; names any gap)
  - SC4 fuel gap closed (加油/给油/給油/ガソリン -> cat_car_fuel)
affects: [50-decoupled-recognizers wave-1 CategoryRecognizer, 51 cross-validation/ledger, 52 RECUX/VEN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Synonym seed split into synonyms/synonyms_*.dart per-family group files aggregated by default_synonyms.dart (800-line rule), shared seed() factory in synonyms_support.dart"
    - "Two-gate protection for authored DATA: categoryId orphan gate (no silent-null) + full-L2 coverage gate (no partial-seed gap), kana-presence script inference (no lang field)"

key-files:
  created:
    - lib/shared/constants/synonyms/synonyms_support.dart
    - lib/shared/constants/synonyms/synonyms_daily_living.dart
    - lib/shared/constants/synonyms/synonyms_health_education_hobbies.dart
    - lib/shared/constants/synonyms/synonyms_admin.dart
  modified:
    - lib/shared/constants/default_synonyms.dart
    - test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart

key-decisions:
  - "SCOPE: full L2 coverage (all 138 L2, admin families included) per user decision + RESEARCH A4, dropping the 48-id speakable-exclusion list"
  - "WORD QUALITY: applied all refinements — うーばー→ウーバー, 老婆零花→伴侣零花钱, hiragana-phonetic→natural katakana where it reads better; Han-only admin terms keep natural kana readings (no forced wrong loanword)"
  - "File split into per-family group files to respect the 800-line project rule (default_synonyms.dart now a 57-line aggregator)"

patterns-established:
  - "Per-family synonym group files under lib/shared/constants/synonyms/, CJK-scan-excluded by directory prefix (mirrors the merchants/ precedent)"

requirements-completed: [DECOUP-02]

# Metrics
duration: ~25min
completed: 2026-06-24
status: complete
---

# Phase 50 Plan 02: Decoupled Recognizers — Full-L2 Keyword Seed Summary

**Extended the category-only voice keyword seed from 90 speakable-L2 to the FULL 138 L2 set (admin families included), 515 zh+ja direct-seed rows, with two machine gates (orphan-categoryId + full-L2 coverage) green and the SC4 fuel gap closed.**

## Performance

- **Duration:** ~25 min (continuation from checkpoint)
- **Tasks:** 4 (1–3 from prior executor; 4 = human-verify, satisfied by user approval this session)
- **Files modified:** 7 (4 created, 3 modified)

## Accomplishments

- **Full L2 coverage:** every one of the 138 level-2 categories now carries at least one zh DIRECT seed AND one ja DIRECT seed (verified: 0 uncovered, 515 seed rows, 143 distinct categoryIds = 138 L2 + 5 L1 catch-alls). The 48 previously-excluded admin ids (19 `*_other` buckets + 29 `cat_tax_*`/`cat_asset_*`/`cat_insurance_*`/`*_insurance`/`*_tax`/`cat_special_*`) are now seeded.
- **Coverage gate widened:** `default_synonyms_speakable_coverage_test.dart` dropped its speakable-exclusion list — target set is now every L2; gate purpose unchanged (prove zh+ja direct seed per id), still names any gap. Green.
- **Word-quality refinements applied** (Decision 2): `うーばー`→`ウーバー` (katakana), `老婆零花`→`伴侣零花钱` (neutral register, alongside the already-present `配偶零花钱`), `じゅうたくろーん`/`くるまろーん`→ rely on the natural katakana `住宅ローン`/added `カーローン`. Han-only admin terms (所得税, 年金, 生命保険…) use their natural kana readings (しょとくぜい, ねんきん, せいめいほけん) rather than forced wrong loanwords.
- **File split** to respect the 800-line rule: seed lists moved into `synonyms/synonyms_{daily_living,health_education_hobbies,admin}.dart` (347/130/153 lines) built via a shared `seed()` factory; `default_synonyms.dart` is now a 57-line aggregator re-exporting `kVoiceSynonymSeedEpoch` (DAO import path preserved).

## Task Commits

1. **Task 1: seed-keyword-categoryId hard gate (RED-first)** - `c5a38fb5` (test) — prior executor
2. **Task 2+3: expand to speakable-L2 + coverage gate** - `974387c5` (feat) — prior executor
3. **Full-L2 extension + word refinements** - `0e2b37e8` (feat) — this session
4. **Coverage-gate widening + CJK-scan whitelist** - `e87dc1bd` (test) — this session

Task 4 (checkpoint:human-verify) was satisfied by the user's two-part decision (full L2 scope + all word refinements) supplied at resume — no further pause needed.

## Files Created/Modified

- `lib/shared/constants/synonyms/synonyms_support.dart` - shared `seed()` factory + `kVoiceSynonymSeedEpoch`
- `lib/shared/constants/synonyms/synonyms_daily_living.dart` - food/daily/pet/transport/clothing/social/housing/utilities/communication/car seeds
- `lib/shared/constants/synonyms/synonyms_health_education_hobbies.dart` - health/education/hobbies seeds
- `lib/shared/constants/synonyms/synonyms_admin.dart` - tax/insurance/asset/special/allowance/other admin-family seeds
- `lib/shared/constants/default_synonyms.dart` - slim aggregator + re-export of the epoch sentinel
- `test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` - target set widened to all L2
- `test/architecture/hardcoded_cjk_ui_scan_test.dart` - `synonyms/` excluded by prefix (seed DATA, not UI text)

## Decisions Made

- **Full L2 coverage (Decision 1):** included all 138 L2 ids, dropping the speakable-exclusion list, per the user scope decision + RESEARCH A4 ("err toward including admin buckets"). The orphan gate guards typos regardless of scope.
- **Word quality (Decision 2):** applied all refinements; for Han-only ja terms with no natural katakana loanword, used the natural kana reading (a real spoken form giving the kana-based ja classifier its non-Han signal) rather than inventing a wrong loanword.
- **Split files:** chose a `synonyms/` group-file layout (consistent with the `merchants/` seed precedent) over one oversized file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Whitelisted `synonyms/` in the hardcoded-CJK UI scan**
- **Found during:** Task 2/3 re-run after the file split
- **Issue:** The new `synonyms/synonyms_*.dart` group files hold CJK seed literals; `hardcoded_cjk_ui_scan_test.dart` would flag them as user-visible UI strings (only the old single `default_synonyms.dart` was whitelisted).
- **Fix:** Added a directory-prefix exclusion for `lib/shared/constants/synonyms/` (same rationale + mechanism as the existing `merchants/` prefix exclusion — seed DATA, not ARB-keyable UI text).
- **Files modified:** test/architecture/hardcoded_cjk_ui_scan_test.dart
- **Verification:** CJK scan green (29/29 across the gate run).
- **Committed in:** e87dc1bd

---

**Total deviations:** 1 auto-fixed (1 blocking). The file split is a CLAUDE.md 800-line-rule mandate (treated as planned, allowed by VOICE-06).
**Impact on plan:** No scope creep — split + whitelist are mechanical consequences of the file-size rule.

## Issues Encountered

- The `category_*` L2 l10n keys are not present in the main ARB files by their exact ids; confirmed this is irrelevant — voice synonym seeds are deliberately hardcoded spoken-token DATA (Phase 21 D-01), independent of UI ARB text. Seed correctness is enforced by the categoryId orphan gate (every id is a real L2), not by ARB parity.

## Verification

- `flutter analyze lib/shared/constants/` → No issues found
- `flutter test` (both gates + resolver + CJK scan) → 29/29 pass; resolver 21/21 (no regression)
- seed use-case + DAO + accounting suite → 93/93 pass
- Full L2 coverage proven: 138 L2, 0 uncovered, 515 rows
- No English keyword leakage; no leftover `うーばー`/`老婆零花`/`じゅうたくろーん`/`くるまろーん`
- All split files < 800 lines (max 347)

## Next Phase Readiness

- The category-only keyword path now covers every L2 → CategoryRecognizer (Plan 50-04) has full keyword reach for everyday utterances. SC4 (`加油用了400块` → `cat_car_fuel`) resolves.
- No blockers. Plan 50-03 (VALIDATION) and the Wave-3 resolver deletion (Plan 50-05) are unaffected by this DATA expansion.

## Self-Check: PASSED

- All 4 created files present on disk; SUMMARY present.
- Both new commits (`0e2b37e8`, `e87dc1bd`) found in git history.

---
*Phase: 50-decoupled-recognizers*
*Completed: 2026-06-24*
