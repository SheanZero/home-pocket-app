---
phase: 50-decoupled-recognizers
verified: 2026-06-24T00:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 50: Decoupled Recognizers Verification Report

**Phase Goal:** 把商家识别与类目识别拆成两个互不调用的纯 Dart 引擎；商家命中不再直接决定类目，类目引擎无条件运行——这是里程碑解耦前提的落地。
**Verified:** 2026-06-24
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `CategoryRecognizer` 与 `MerchantRecognizer` 互不调用（构造独立、各自可单测）；「商家优先短路关键词」逻辑被移除；四象限 (merchant✓ keyword✓) 用例同时产出两路引擎输出，不再短路 | ✓ VERIFIED | Bidirectional grep: `MerchantRecognizer` refs CategoryRecognizer = 0; `CategoryRecognizer` refs merchant = 0 (any merchant token = 0). Constructors are merchant-free (cat) / merchant-only (merchant). Orchestrator `parse_voice_input_use_case.dart:95,104` runs both independently; no `merchantMatch.ledgerType` short-circuit (grep = 0). Four-quadrant test `:140-174` asserts keyword wins for category AND `merchantCandidates`/`merchantName` still surfaced (both outputs). All 78 voice tests pass empirically. |
| 2 | `MerchantRecognizer` 用锚定/归一化匹配（NFKC + 假名折叠 + 全角/小写、按字种最小别名长度），返回带分数排序候选——不再双向子串；对抗语料 (~39) 断言无误命中或低分 (SC2) | ✓ VERIFIED | `merchant_recognizer.dart:62-170` — anchored tiers (exact 1.00 / anchored-prefix 0.85 / containment 0.60 / reverse 0.55), `_passesScriptMinLength` per-script floors, reuses `normalizeMerchantKey` (grep=2). No bidirectional `contains\|\|contains`. Corpus 39 entries (お米×2, 杉並区×1). `merchant_false_positive_test.dart` SC2 gate passes empirically (every entry empty OR < 0.85). |
| 3 | 单说「スタバ」(及 ｽﾀﾊﾞ、マクド、Starbucks) 独立解析为星巴克 → 咖啡; CR-01 compound 「スタバでコーヒー」 fix holds | ✓ VERIFIED | `merchant_recognizer_test.dart` four surface forms ≥0.85 pass. `merchant_recognizer_compound_utterance_test.dart` (CR-01 regression) + IN-04 e2e in use-case test: compound 「スタバでコーヒー」「スタバで500円」「マクドでポテト食べた」 all auto-fill via real scorer (5 cases pass). CR-01 fix commits `5778bf28`/`72b3f4f7` exist. SC2 stays green. |
| 4 | `CategoryRecognizer` 无条件运行：即使无商家也能从活动/物品关键词解析出 L2——「加油用了400块」→ cat_car_fuel (Case B) | ✓ VERIFIED | `category_recognizer.dart:79` runs unconditionally (no merchant gate). Fuel seed 加油/给油/給油/ガソリン → cat_car_fuel in `synonyms_daily_living.dart:313-316`. Four-quadrant merchant✗keyword✓ test `加油用了400块 → cat_car_fuel (no merchant auto-fill)` passes empirically. Speakable-L2 coverage gate green (every speakable L2 has ≥1 zh + ≥1 ja seed). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/application/voice/recognition/merchant_recognizer.dart` | Anchored normalized scorer (DECOUP-03) | ✓ VERIFIED | 200 lines; anchored tiers + script-min-length; no merchant→category coupling; no-log (print/log=0); reuses normalizeMerchantKey |
| `lib/application/voice/recognition/category_recognizer.dart` | Keyword-only engine (DECOUP-01/02) | ✓ VERIFIED | 195 lines; zero merchant mention; runs unconditionally; resolve/normalizeToL2/resolveLedgerType public surface preserved |
| `lib/features/accounting/domain/models/merchant_candidate.dart` | @freezed verdict, raw score | ✓ VERIFIED | 32 lines; score/categoryId/ledgerHint; no banding |
| `lib/features/accounting/domain/models/merchant_match_entry.dart` | flat join record | ✓ VERIFIED | 27 lines; matchKey/surface/merchantId/categoryId/ledgerHint |
| `lib/application/voice/parse_voice_input_use_case.dart` | Two-engine merge + 0.85 floor | ✓ VERIFIED | kMerchantAutoFillFloor=0.85; both engines run independently; ledger from category; WR-04 null-L2 guard |
| `lib/shared/constants/synonyms/synonyms_daily_living.dart` (seed expansion) | Full speakable-L2 zh+ja + fuel | ✓ VERIFIED | cat_car_fuel 4 surfaces; speakable-L2 coverage gate green |

### Retirement of Old Path (D-05 + resolver deletion)

| Deleted Artifact | Status | Dangling Refs |
|------------------|--------|---------------|
| `lib/infrastructure/ml/merchant_database.dart` | ✓ DELETED | Only dead TODO comment in classification_service.dart:33 (no import) |
| `lib/application/ml/lookup_merchant_use_case.dart` | ✓ DELETED | 0 references (incl. test) |
| `lib/application/voice/voice_category_resolver.dart` | ✓ DELETED | Only doc-comment/test-comment mentions; 0 live imports/constructions |
| `test/unit/application/voice/voice_category_resolver_test.dart` | ✓ DELETED | n/a |
| `test/unit/application/ml/lookup_merchant_use_case_test.dart` | ✓ DELETED | n/a |
| merchant-ledger short-circuit (`= merchantMatch.ledgerType`) | ✓ REMOVED | grep = 0 in orchestrator |
| parser `extractAndMatchMerchant` / `_extractPotentialMerchantNames` | ✓ REMOVED | grep = 0 in voice_text_parser.dart |

Verified: no live `import` of any deleted file; no `VoiceCategoryResolver(`/`MerchantDatabase(`/`LookupMerchantUseCase(` construction anywhere in lib/+test/ (non-comment grep = 0).

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `repository_providers.dart` | `merchant_recognizer.dart` | `merchantRecognizerProvider` → `MerchantRecognizer(...)` | ✓ WIRED (line 281) |
| `repository_providers.dart` | `category_recognizer.dart` | `categoryRecognizerProvider` → `CategoryRecognizer(...)` (no merchantDatabase arg) | ✓ WIRED (line 264; merchantDatabase: arg count = 0) |
| `parse_voice_input_use_case.dart` | both recognizers | provider passes both into use case | ✓ WIRED (lines 296-297) |
| `parse_voice_input_use_case.dart` | `category_recognizer.dart` | `resolveLedgerType(finalCategoryId)` | ✓ WIRED (lines 115, 142) |
| `merchant_recognizer.dart` | `merchant_repository.dart` | `loadAllForMatching()` warm cache | ✓ WIRED (line 68) |
| `merchant_repository_impl.dart` | `merchant_dao.dart` | join in one read transaction | ✓ WIRED (loadAllForMatching test passes) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full analyze | `flutter analyze` | No issues found | ✓ PASS |
| Phase-50 voice + seed tests (8 files) | `flutter test ...` | All 78 tests passed | ✓ PASS |
| Provider hygiene + CJK scan + coverage gate | `flutter test test/architecture/...` | All passed | ✓ PASS |
| Four-quadrant gate (merchant✓kw✓ / floor-auto-fill / fuel / both-miss) | use-case test | All quadrants pass | ✓ PASS |
| CR-01 compound utterance e2e (real recognizer) | IN-04 + compound test | 5 compound cases auto-fill correctly | ✓ PASS |
| SC2 adversarial corpus (39 entries) | false-positive test | all empty OR < 0.85 | ✓ PASS |
| SC3 surface forms (スタバ/ｽﾀﾊﾞ/マクド/Starbucks) | recognizer test | all ≥ 0.85 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DECOUP-01 | 50-04, 50-05 | 两引擎互不调用 + 短路逻辑移除 | ✓ SATISFIED | Bidirectional independence grep = 0; short-circuit removed; SC1 verified |
| DECOUP-02 | 50-02, 50-04, 50-05 | CategoryRecognizer 无条件运行 → cat_car_fuel | ✓ SATISFIED | Unconditional run; fuel seed; Case B four-quadrant pass; SC4 verified |
| DECOUP-03 | 50-01, 50-03, 50-05 | MerchantRecognizer 独立识别商家 + 弱默认类目 | ✓ SATISFIED | Anchored scorer; スタバ→星巴克→咖啡; SC2/SC3 verified |

All three requirement IDs accounted for in REQUIREMENTS.md (marked Complete) and ROADMAP. No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| (none) | TBD/FIXME/XXX/TODO/HACK in phase-50 source | — | Modified source files clean. classification_service.dart:33 TODO is a pre-existing dead comment, not phase-50 debt. |

### Code Review Closure (50-REVIEW.md)

- CR-01 (BLOCKER): merchant lost on compound "merchant-then-words" utterances → FIXED (`_scoreOf` scores prefix directions separately; alias-at-start tier no coverage guard; falls through instead of `return null`). Real-recognizer evidence + new regression test confirm. Commits `5778bf28`/`72b3f4f7` exist.
- WR-01…WR-05 + IN-01: all resolved (commits `cee36a44`/`5437de48`/`d15f3bf0` exist).
- IN-02/IN-03: documented as accepted (IN-02 sync-format compat deferred; IN-03 auto-covered by CR-01 fix).

### Human Verification Required

None. The Plan 02 blocking `checkpoint:human-verify` (D-04 authored-keyword spot-check) was satisfied by user approval during execution (50-02-SUMMARY.md:76). Machine coverage gate proves set-completeness; word-quality approval recorded.

### Gaps Summary

No gaps. All four ROADMAP success criteria are verified against the actual codebase (not SUMMARY claims): the two engines are constructionally independent (bidirectional grep), the old path (MerchantDatabase / LookupMerchantUseCase / VoiceCategoryResolver / merchant-ledger short-circuit) is fully retired with zero dangling live references, the anchored scorer + SC2 adversarial gate + SC3 surface forms + SC4 keyword-only fuel path all pass empirically, and the CR-01 blocker fix holds (compound utterances resolve while SC2 stays green). Full `flutter analyze` = 0 issues; 78 phase-50 tests + architecture gates green.

---

_Verified: 2026-06-24_
_Verifier: Claude (gsd-verifier)_
