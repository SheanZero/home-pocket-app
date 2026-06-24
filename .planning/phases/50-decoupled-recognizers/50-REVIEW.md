---
phase: 50-decoupled-recognizers
reviewed: 2026-06-24T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/application/voice/recognition/category_recognizer.dart
  - lib/application/voice/recognition/merchant_recognizer.dart
  - lib/application/voice/voice_text_parser.dart
  - lib/data/repositories/merchant_repository_impl.dart
  - lib/features/accounting/domain/models/merchant_candidate.dart
  - lib/features/accounting/domain/models/merchant_match_entry.dart
  - lib/features/accounting/domain/models/voice_parse_result.dart
  - lib/features/accounting/domain/repositories/merchant_repository.dart
  - lib/features/accounting/presentation/providers/repository_providers.dart
  - lib/shared/constants/default_synonyms.dart
  - lib/shared/constants/synonyms/synonyms_admin.dart
  - lib/shared/constants/synonyms/synonyms_daily_living.dart
  - lib/shared/constants/synonyms/synonyms_health_education_hobbies.dart
  - lib/shared/constants/synonyms/synonyms_support.dart
  - lib/shared/constants/voice_currency_suffixes.dart
  - test/architecture/hardcoded_cjk_ui_scan_test.dart
  - test/fixtures/merchant_false_positive_corpus.dart
  - test/unit/application/voice/recognition/category_recognizer_test.dart
  - test/unit/application/voice/recognition/merchant_false_positive_test.dart
  - test/unit/application/voice/recognition/merchant_recognizer_test.dart
  - test/unit/data/repositories/merchant_repository_loadallformatching_test.dart
  - test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart
  - lib/infrastructure/ml/merchant_name_normalizer.dart
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: resolved
---

# Phase 50: Code Review Report

**Reviewed:** 2026-06-24
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 50 split the voice pipeline into two independent engines (`MerchantRecognizer`, `CategoryRecognizer`) merged by `ParseVoiceInputUseCase` with a keyword-priority rule and a 0.85 merchant auto-fill floor. The decoupling, provider rewiring, `loadAllForMatching` read path, and L2 normalization are all structurally sound and well-tested at the unit level. The seed data files are clean (one benign duplicate, no orphan-categoryId risk surfaced by grep, coverage gate is real).

The serious problem is an **input-contract mismatch between the orchestrator and the recognizer that the test suite does not cover**: the orchestrator feeds the *full raw transcript* into `MerchantRecognizer.recognize()`, but the recognizer's prefix-tier coverage guard rejects the merchant whenever the merchant name is a short prefix of a longer utterance. The net effect is that realistic utterances like 「スタバでコーヒー」 or 「スタバで500円」 return **no candidate at all** — merchant auto-fill silently never fires for the most common phrasing. Every recognizer test passes a pre-cleaned single token, and the use-case test *mocks* the recognizer, so this gap is entirely untested. This is the headline BLOCKER (CR-01).

I verified CR-01 empirically by running the real `MerchantRecognizer` against raw utterances (see CR-01 evidence). The remaining findings are robustness/quality issues.

## Critical Issues

### CR-01: Merchant recognizer returns NO candidate for the common "merchant-then-words" utterance — auto-fill silently never fires

**File:** `lib/application/voice/parse_voice_input_use_case.dart:96-98` (call site) + `lib/application/voice/recognition/merchant_recognizer.dart:118-139` (`_scoreOf`)

**Issue:**
The orchestrator passes the **full raw transcript** to the merchant engine:

```dart
final merchantCandidates = await _merchantRecognizer.recognize(
  recognizedText,   // <-- raw, NOT the extracted keyword
);
```

Inside `_scoreOf`, the prefix tier is evaluated *before* the reverse-containment tier:

```dart
if (mk.startsWith(nq) || nq.startsWith(mk)) {        // line 120
  ...
  if (shorterRunes * 2 <= longerRunes) return null;  // line 131 — must cover >50%
  return _scoreAnchoredPrefix;
}
if (mk.contains(nq) && _passesScriptMinLength(nq)) ... // 0.60 — unreachable when nq starts with mk
if (nq.contains(mk) && _passesScriptMinLength(mk)) ... // 0.55 — unreachable when nq starts with mk
```

When the utterance *begins* with the merchant token (the dominant Japanese/Chinese word order: 「スタバで…」「マクドで…」), `nq.startsWith(mk)` is true, so control enters the prefix branch. For a short alias against a long sentence the `>50%` coverage guard fails and the method `return null`s — it never falls through to the reverse-containment tier (0.55) that the design intended for "matchKey embedded in a longer query." The merchant is dropped entirely.

The coverage guard was written to reject a generic prefix word against a long *brand* surface (e.g. 「大阪」⊂「大阪王将」). But it cannot distinguish that case from "real merchant alias is a prefix of a longer *utterance*," because the recognizer is fed the whole utterance instead of an isolated token. Both look identical to `_scoreOf`.

**Evidence (real `MerchantRecognizer`, seeded with スタバ/マクド aliases):**
```
RAW="スタバ"                 -> m_sb@1.0     ✅ (the only shape the tests cover)
RAW="スタバでコーヒー"        -> NONE         ❌ merchant lost
RAW="スタバで500円"          -> NONE         ❌ merchant lost
RAW="スタバに行った"          -> NONE         ❌ merchant lost
RAW="マクドでポテト食べた"     -> NONE         ❌ merchant lost
RAW="マクドナルドで昼ごはん"   -> m_mc@0.85    ✅ (long name happens to clear >50%)
```

So merchant auto-fill works only when the user speaks the bare merchant name, or when the merchant's full name dominates the sentence. The most natural phrasings silently fall through to keyword-only (or to nothing), defeating the merchant engine's purpose.

**Why the tests miss it:** `merchant_recognizer_test.dart` and `merchant_false_positive_test.dart` only ever call `recognize()` with a clean token ('スタバ', 'マクド', 'お米', …) — never a token embedded in surrounding words. `parse_voice_input_use_case_test.dart` stubs `MerchantRecognizer` with a mock that returns a 0.95 candidate for `any()` input, so the real scorer is never exercised end-to-end. The false-positive corpus (SC2) is all *standalone* generic words, so it cannot catch a false *negative* on a compound utterance.

**Fix (choose one; option A is the smaller change):**

A. Reorder `_scoreOf` so the prefix coverage guard cannot swallow an embedded match — when the prefix coverage guard fails, fall through to containment/reverse-containment instead of `return null`:
```dart
double? _scoreOf(String nq, String mk) {
  if (nq == mk) return _scoreExact;
  if (mk.startsWith(nq) || nq.startsWith(mk)) {
    final shorterRunes = nq.runes.length <= mk.runes.length ? nq.runes.length : mk.runes.length;
    final longerRunes  = nq.runes.length >= mk.runes.length ? nq.runes.length : mk.runes.length;
    final shorter      = nq.length <= mk.length ? nq : mk;
    if (_passesScriptMinLength(shorter) && shorterRunes * 2 > longerRunes) {
      return _scoreAnchoredPrefix;
    }
    // fall through — do NOT return null; let containment/reverse decide
  }
  if (mk.contains(nq) && _passesScriptMinLength(nq)) return _scoreContainment;
  if (nq.contains(mk) && _passesScriptMinLength(mk)) return _scoreReverseContainment;
  return null;
}
```
This still does not auto-fill (0.55 < 0.85), so the SC2 false-positive gate stays green — but the candidate is now *surfaced* (recall-first, D-01) for Phase-52 chips instead of being silently dropped. If the product intent is that 「スタバでコーヒー」 *should* auto-fill Starbucks, this is insufficient on its own (see B).

B. Recognize the merchant token, not the whole sentence: have the orchestrator scan/segment the transcript (or run the recognizer over the extracted keyword + a windowed scan) so an isolated alias matches at the exact/anchored-prefix tier. This is the behaviorally-correct fix but a larger design change — confirm with the phase owner which behavior is intended (surface-only vs. auto-fill on compound utterances).

**Required regardless of option:** add a regression test that drives the *real* `MerchantRecognizer` (and ideally the real `ParseVoiceInputUseCase` with a real recognizer over a small fixture seed) with compound utterances like 「スタバでコーヒー」「マクドで昼」, asserting the merchant is at least surfaced (and, if intended, auto-filled). The current mock-only use-case test gives false confidence.

## Warnings

### WR-01: `_cache` is never invalidated and can latch an empty seed permanently

**File:** `lib/application/voice/recognition/merchant_recognizer.dart:31,57`

**Issue:** `_cache ??= await _merchantRepository.loadAllForMatching()` warms once and is never invalidated, and the provider is `@Riverpod(keepAlive: true)` (`repository_providers.dart:279`). If `recognize()` is ever called before merchant seeding has completed/succeeded (e.g. seed retried after an init failure, or a future code path that touches the recognizer during startup), the cache latches `[]` for the entire app session and every merchant lookup silently returns empty until restart. Today seeding runs in `AppInitializer` Stage 3 before any user interaction, so the window is narrow — but the "never invalidated" guarantee is load-bearing and undefended.

**Fix:** Either don't cache an empty result (`final entries = _cache ?? await load(); if (entries.isNotEmpty) _cache = entries;`), or expose an invalidation hook the seed path calls after `insertBatch`, or drop `keepAlive` so a re-seed naturally re-warms. At minimum add a test asserting an empty first load does not poison a subsequent non-empty load.

### WR-02: Concurrent first-call cache warm double-loads (benign but unguarded)

**File:** `lib/application/voice/recognition/merchant_recognizer.dart:57`

**Issue:** `_cache ??= await loadAllForMatching()` is not atomic across the `await`. Two `recognize()` calls racing on the first invocation both observe `_cache == null` and both issue `loadAllForMatching()`; the second assignment overwrites the first. Data is identical so the result is correct, but it doubles the (transactional) DB read. Low impact given single-threaded UI dispatch, but worth a guard if the recognizer is ever shared across isolates/futures.

**Fix:** Cache the `Future` instead of the value: `_cacheFuture ??= _merchantRepository.loadAllForMatching(); final entries = await _cacheFuture!;` so concurrent callers share one in-flight load.

### WR-03: Merchant recognizer scores over the *raw* transcript, polluting matchKeys with amount/date noise

**File:** `lib/application/voice/parse_voice_input_use_case.dart:96-98`

**Issue:** Passing `recognizedText` (which still contains the amount, currency suffix, and date words) into the normalizer means the normalized query key carries digits and unrelated runes (e.g. 「スタバで500円」 → `すたばで500円`). This is the upstream cause of CR-01's prefix-coverage failure and also means containment matches are computed against noisy keys. Even after CR-01 is fixed, scoring against unstripped text makes the coverage/length heuristics behave unpredictably (a long noisy suffix shrinks the prefix coverage ratio).

**Fix:** Feed the recognizer the same stripped surface the keyword engine uses (or a lightly-stripped variant that removes the matched amount/currency/date spans) rather than the full raw text. Keep `rawText` only for display. Coordinate with the CR-01 fix.

### WR-04: Auto-fill falls back to a possibly non-L2 categoryId when `normalizeToL2` returns null

**File:** `lib/application/voice/parse_voice_input_use_case.dart:118-121`

**Issue:**
```dart
final l2 = await _categoryRecognizer.normalizeToL2(best.categoryId);
finalCategory = CategoryMatchResult(
  categoryId: l2 ?? best.categoryId,   // <-- falls back to the raw merchant categoryId
  ...
);
```
`normalizeToL2` returns null when the category resolves to nothing or has no L2 child (`category_recognizer.dart:168-182`). The `l2 ?? best.categoryId` fallback then stamps the *un-normalized* merchant categoryId as the final category, violating the "always-L2" contract the rest of the pipeline assumes, and `resolveLedgerType` is then called on a potentially-L1 id. Today all seeded merchant categoryIds are L2 (verified across `lib/shared/constants/merchants/*.dart`), so this is latent — but a future merchant row with an L1/typo categoryId would leak a non-L2 id into the transaction.

**Fix:** Treat a null `normalizeToL2` result as "no auto-fill" — skip the merchant fill and leave the category null (surfacing the candidate for manual pick) rather than committing an unnormalized id:
```dart
final l2 = await _categoryRecognizer.normalizeToL2(best.categoryId);
if (l2 != null) {
  finalCategory = CategoryMatchResult(categoryId: l2, confidence: best.score, source: MatchSource.merchant);
  ledgerType = await _categoryRecognizer.resolveLedgerType(l2);
}
```

### WR-05: Substring-fallback `isLearned` re-derived from `hitCount > 0` contradicts the seed sentinel and the `isLearned` model rule

**File:** `lib/application/voice/recognition/category_recognizer.dart:138`

**Issue:** In step 2.5 the code recomputes `final isLearned = winner.hitCount > 0;`, but seed rows carry `hitCount = 0` and learned rows are promoted at `hitCount >= kLearnedPromotionThreshold (3)`. A learned row with `hitCount` 1 or 2 cannot reach step 2.5 (it's excluded by `findLearnedRowsAtOrAbove(3)`), so in practice `hitCount > 0` here only ever sees promoted (>=3) rows or seeds (0) — accidentally correct today. But `hitCount > 0` is a *different* predicate than the model's `isLearned` (hitCount >= 2) used in step 2 (line 90), so the two steps classify the same row differently. This is fragile: lower the promotion threshold and the `MatchSource`/confidence branch silently mislabels. Use the model's own `winner.isLearned` for consistency, or compare against `kLearnedPromotionThreshold` explicitly.

**Fix:** `final isLearned = winner.isLearned;` (single source of truth), or `final isLearned = winner.hitCount >= kLearnedPromotionThreshold;` to match the promotion gate exactly.

## Info

### IN-01: Duplicate seed pair `外食 → cat_food_dining_out`

**File:** `lib/shared/constants/synonyms/synonyms_daily_living.dart:33` and `:49`

**Issue:** `seed('外食', 'cat_food_dining_out')` appears twice (ja section line 33, zh section line 49) — 外食 is a shared Han word. It maps to the same categoryId both times, so it's harmless (the DAO's `INSERT OR IGNORE`/exact-keyword lookup dedupes), but it's redundant authored data. Grep confirms this is the *only* duplicate keyword across all four synonym files, and the only keyword mapping to multiple categoryIds is none (no conflicting mappings).

**Fix:** Delete one of the two lines (keep it in whichever section reads more naturally) to keep the seed list honest.

### IN-02: `merchantLedgerType` field is dead in production

**File:** `lib/features/accounting/domain/models/voice_parse_result.dart:26`

**Issue:** `merchantLedgerType` is declared and documented as "retained for backward compatibility but no longer populated." Grep confirms it is never set or read anywhere outside generated `.freezed.dart` boilerplate. Dead field on a domain model.

**Fix:** Remove it if no external/sync consumer depends on the field name; otherwise leave the explicit comment (already present) and add it to a deprecation tracker.

### IN-03: Reverse-containment / containment tiers are effectively unreachable given the current call contract

**File:** `lib/application/voice/recognition/merchant_recognizer.dart:134-137`

**Issue:** Related to CR-01: because the recognizer is fed whole utterances and the prefix branch (`startsWith`) fires first and `return null`s on coverage failure, the `_scoreContainment` (0.60) and `_scoreReverseContainment` (0.55) tiers are unreachable for the prefix-of-utterance case — the dominant real input shape. They're only reachable when the query is a non-prefix infix (the synthetic `すばーが` test). So two of the four advertised tiers carry almost no real traffic. Fixing CR-01 (option A fall-through) restores them. Flagging so the tier design is re-validated against real input, not just the toy fixtures.

**Fix:** Covered by CR-01 fix; add a tier-coverage assertion over realistic utterances.

### IN-04: Use-case test mocks the merchant engine, so the four-quadrant "acceptance gate" does not exercise real merchant scoring

**File:** `test/unit/application/voice/parse_voice_input_use_case_test.dart` (whole file; `_MockMerchantRecognizer`)

**Issue:** The four-quadrant regression is described as the "phase acceptance gate," but `MerchantRecognizer` is mocked to return a fixed 0.95 candidate for `any()` input. The merge/floor logic is validated, but the gate cannot catch CR-01 because the real scorer never runs. This is the structural reason a BLOCKER shipped green.

**Fix:** Add at least one quadrant variant wired to a *real* `MerchantRecognizer` over a tiny in-memory seed, asserting compound utterances resolve as intended. Keep the mocked tests for the merge-rule matrix.

---

## Fixes Applied (post-review)

**Applied:** 2026-06-24 · **Status:** resolved · all whole-project `flutter analyze` = 0 issues, full `flutter test` = 3258 passed.

Approved scope: BLOCKER (CR-01) + all warnings (WR-01…WR-05) + IN-01. IN-02 and IN-03 left as documented (IN-02 deferred — sync-format compat; IN-03 auto-covered by the CR-01 fix).

| Finding | Resolution | Commit |
|---|---|---|
| **CR-01** (BLOCKER) | `MerchantRecognizer._scoreOf` now scores the two prefix directions separately. A seeded alias that is a prefix of the (stripped) utterance — `nq.startsWith(mk)`, the dominant 「スタバで…」 shape — resolves at the alias-at-start tier (0.85) gated only by script-min-length, **no** coverage guard. A short query prefixing a long brand — `mk.startsWith(nq)` — keeps the `>50%` coverage guard (SC2). A failed guard in either branch falls **through** to containment instead of `return null`. Real-recognizer evidence below. | `5778bf28` (RED test), `72b3f4f7` (GREEN) |
| **WR-03** | Orchestrator feeds the recognizer the amount/currency/date/particle-**stripped** surface (the same `_extractKeyword` output the category engine uses), not the raw transcript. `rawText` retained for display only. | `72b3f4f7` |
| **WR-04** | A null `normalizeToL2(best.categoryId)` result is now treated as "no auto-fill" — the un-normalized (possibly L1) merchant categoryId is never stamped; category stays null and the candidate surfaces for manual pick. New unit test pins it. | `72b3f4f7` |
| **IN-04** | De-mocked the use-case acceptance gate: a new group drives the **real** `MerchantRecognizer` over a tiny seed end-to-end through the real `ParseVoiceInputUseCase` for all five headline compound utterances, so this class of false-negative cannot ship green again. Mocked merge-matrix tests retained. | `72b3f4f7` |
| **WR-01** | Empty first load no longer latches — the cached future is cleared when the load is empty, so a later call re-loads once seeding has populated the table. | `cee36a44` |
| **WR-02** | Cache the in-flight **Future** (not the resolved value) so concurrent first-calls share one (transactional) DB read. Both behaviors covered by new tests (empty-then-nonempty re-load; loaded-once; concurrent share-one). | `cee36a44` |
| **WR-05** | Substring-fallback `isLearned` now uses the model's single source of truth `winner.isLearned` (hitCount >= 2) instead of the divergent `hitCount > 0`. | `5437de48` |
| **IN-01** | Removed the duplicate `外食 → cat_food_dining_out` seed (kept the ja occurrence). Coverage + categoryId gates stay green. | `d15f3bf0` |

**Real-recognizer evidence (CR-01 / SC3) — after fix, with the orchestrator strip applied:**

```
RAW="スタバ"               STRIP="スタバ"          -> mer_sb@1.00  ✅
RAW="スタバでコーヒー"      STRIP="スタバコーヒー"    -> mer_sb@0.85  ✅ (was NONE ❌)
RAW="スタバで500円"        STRIP="スタバ"          -> mer_sb@1.00  ✅ (was NONE ❌)
RAW="スタバに行った"       STRIP="スタバ行った"     -> mer_sb@0.85  ✅ (was NONE ❌)
RAW="マクドでポテト食べた"  STRIP="マクドポテト食べた" -> mer_mc@0.85  ✅ (was NONE ❌)
RAW="マクドナルドで昼ごはん" STRIP="マクドナルド昼ごん" -> mer_mc@0.85  ✅
```

**SC2 hard constraint:** the full ~400-merchant adversarial corpus (`merchant_false_positive_test.dart`) re-run against the real recognizer stays entirely **below** the 0.85 floor — no false auto-fill introduced.

---

_Reviewed: 2026-06-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Fixes applied: 2026-06-24 — see "Fixes Applied (post-review)" above._
