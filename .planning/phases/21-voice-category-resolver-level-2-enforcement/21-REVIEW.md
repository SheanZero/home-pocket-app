---
phase: 21-voice-category-resolver-level-2-enforcement
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/application/accounting/seed_voice_synonyms_use_case.dart
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/application/voice/voice_category_resolver.dart
  - lib/data/daos/category_keyword_preference_dao.dart
  - lib/data/repositories/category_keyword_preference_repository_impl.dart
  - lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart
  - lib/features/accounting/presentation/providers/repository_providers.dart
  - lib/features/accounting/presentation/providers/repository_providers.g.dart
  - lib/infrastructure/ml/merchant_database.dart
  - lib/main.dart
  - lib/shared/constants/default_synonyms.dart
  - test/architecture/category_other_l2_invariant_test.dart
  - test/architecture/hardcoded_cjk_ui_scan_test.dart
  - test/architecture/stale_suppressions_scan_test.dart
  - test/fixtures/voice_category_corpus_ja.dart
  - test/fixtures/voice_category_corpus_zh.dart
  - test/integration/voice/voice_category_corpus_ja_test.dart
  - test/integration/voice/voice_category_corpus_zh_test.dart
  - test/unit/application/voice/parse_voice_input_use_case_test.dart
  - test/unit/application/voice/voice_category_resolver_test.dart
  - test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart
findings:
  critical: 1
  warning: 7
  info: 6
  total: 14
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-05-24
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Phase 21 swaps `FuzzyCategoryMatcher` for the new `VoiceCategoryResolver` — a deterministic short-circuit pipeline backed by the existing `category_keyword_preferences` Drift table (no schema migration). The data-layer plumbing (DAO, repository, providers) is structurally sound, and the always-L2 invariant is well-defended (resolver `_ensureL2` + architecture test trapping convention drift + caveat that re-routes merchant matches through the resolver too).

The most consequential defects are around **idempotency of the seed step** and **transactional integrity of decay**:

1. The seed idempotency probe couples to `DefaultVoiceSynonyms.all.first` and short-circuits the entire batch on a single existing row — a user correcting that one keyword before the next launch suppresses every other seed. The DAO already uses `INSERT OR IGNORE` so the probe is unnecessary and harmful.
2. `decayStalePreferences` issues a separate `DELETE` and `UPDATE` outside a transaction — a concurrent `recordCorrection` between them can corrupt counts.
3. The resolver's documented "STRICT short-circuit" claim is slightly misleading: a merchant hit whose `_ensureL2` returns null falls through to keyword preferences (acceptable, but the comment overstates the guarantee).
4. The docstring on the resolver claims a "4-stage pipeline" but the implementation has 3 stages (merchant → preferences → null) plus `_ensureL2`. The phase prompt's "exact synonym → fuzzy synonym → merchant DB" wording does not match either the code or the resolver's own comments — fuzzy matching does not exist anywhere in this phase. This is doc drift, not a bug, but it indicates plan-vs-code drift that warrants tightening.

No crypto/PII boundary violations were found in the modified files. The CJK seed data is correctly whitelisted in `hardcoded_cjk_ui_scan_test.dart`. Riverpod 3 import boundaries are respected (`flutter_riverpod.dart` only; no leakage from `legacy.dart` / `misc.dart`).

## Critical Issues

### CR-01: Seed idempotency probe defeats `INSERT OR IGNORE` safety net and depends on list ordering

**File:** `lib/application/accounting/seed_voice_synonyms_use_case.dart:23-39`
**Issue:** The probe pattern reads:

```dart
final probeKeyword = DefaultVoiceSynonyms.all.first.keyword;
final existing = await _prefRepo.findByKeyword(probeKeyword);
if (existing.isNotEmpty) {
  return Result.success(null);
}
await _prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all);
```

This is unsafe for two reasons:

1. **Coupling to list ordering.** `DefaultVoiceSynonyms.all.first` is currently `'朝ごはん'` (ja food). Reordering the list — a refactor with no semantic meaning — silently changes which keyword is probed. The DAO never enforces that the probe keyword exists.

2. **Probe shortcut destroys recovery.** Imagine a fresh install where seeding ran successfully, then the user corrects `'朝ごはん'` → some non-default category (upsert increments hitCount of an EXISTING seed row to 1 OR inserts a new row with hitCount=1). On the next app launch, the probe finds `existing.isNotEmpty == true` and returns — **even though many other seed rows might have been deleted by `decayStalePreferences`** during the long idle, or never inserted because of an earlier partial failure. The DAO's `INSERT OR IGNORE` is specifically designed to be safe to call unconditionally; the probe layer above it removes that safety.

   The pathological case isn't purely theoretical: if a future migration ever runs `decayStalePreferences` aggressively (or if a sync conflict deletes some rows), the seed batch should self-heal on next boot — which it cannot, because the probe still passes.

**Fix:**

```dart
Future<Result<void>> execute() async {
  // Trust the DAO's INSERT OR IGNORE semantics — it is the SQL-level
  // idempotency guarantee. Self-heals from any partial-seed state.
  await _prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all);
  return Result.success(null);
}
```

If the cost of unconditionally batching ~60 rows is a concern, gate on a SharedPreferences/secure_storage flag rather than on a single data-coupled probe row.

## Warnings

### WR-01: `decayStalePreferences` is not atomic — race window between DELETE and UPDATE

**File:** `lib/data/daos/category_keyword_preference_dao.dart:113-136`
**Issue:** The method runs two separate awaited statements:

```dart
await (_db.delete(...)..where(... hit_count = 1 AND stale ...)).go();
await _db.customUpdate('UPDATE ... SET hit_count = hit_count - 1 WHERE last_used < ? AND hit_count > 0', ...);
```

Between the DELETE and the UPDATE, a concurrent `recordCorrection` (called from `RecordCategoryCorrectionUseCase` whenever the user accepts a voice category) can:
1. Insert a brand-new row with `hitCount = 1` and `lastUsed = now` — survives both statements (correct).
2. Increment an existing row whose old `lastUsed` was < cutoff but whose new `lastUsed` is now — the UPDATE will STILL match the OLD WHERE check because `lastUsed` is now `now`, so it skips (correct).
3. **But:** any row that was at `hit_count = 2` and got deleted by another path between the two statements is benign. The real subtle hazard is the second statement updating rows whose `lastUsed` was just refreshed between DELETE and UPDATE — those would now NOT match `last_used < cutoff`, so they're fine.

The actual risk is smaller than initially apparent (SQLite is single-writer), but the **two statements are not in a transaction**, meaning if the app is killed between them, you can leave the table in a partial state (the `hit_count=1` rows deleted but the rest not decremented — next decay pass loses an additional ply).

**Fix:** wrap in `_db.transaction((b) async { ... })`:

```dart
Future<void> decayStalePreferences(Duration staleDuration) async {
  final cutoff = DateTime.now().subtract(staleDuration);
  await _db.transaction(() async {
    await (_db.delete(_db.categoryKeywordPreferences)..where(
          (t) => t.lastUsed.isSmallerThan(Variable(cutoff)) &
              t.hitCount.equals(1),
        ))
        .go();
    await _db.customUpdate(
      'UPDATE category_keyword_preferences '
      'SET hit_count = hit_count - 1 '
      'WHERE last_used < ? AND hit_count > 1',
      variables: [Variable(cutoff)],
      updates: {_db.categoryKeywordPreferences},
    );
  });
}
```

(Bonus: tightened the WHERE clauses — the original `hit_count <= 1 AND hit_count > 0` is logically `= 1`, and the UPDATE's `hit_count > 0` is incorrect after the DELETE removed hit_count=1 rows; using `> 1` makes intent explicit and prevents the UPDATE from re-decrementing any rows that the prior DELETE would have already removed.)

### WR-02: Resolver docstring claims "STRICT short-circuit" but merchant→null path silently falls through to step 2

**File:** `lib/application/voice/voice_category_resolver.dart:52-72`
**Issue:** The comment says:

```
/// Pipeline order is STRICT — a hit in step 1 short-circuits step 2.
```

But the actual control flow is:

```dart
final merchantMatch = _merchantDatabase.findMerchant(extractedKeyword);
if (merchantMatch != null) {
  final l2 = await _ensureL2(merchantMatch.categoryId);
  if (l2 != null) {
    return CategoryMatchResult(...);
  }
}
// Step 2 runs even when merchantMatch was non-null but _ensureL2 failed
```

If MerchantDatabase yields a match whose `categoryId` cannot be normalized to L2 (e.g. a stale/typo'd merchant entry pointing at a category that no longer exists), the resolver silently tries keyword preferences against the same `extractedKeyword`. This is probably the desired defensive behavior, but it contradicts the comment.

The unit test at `voice_category_resolver_test.dart:73-94` ("L2 hit returns categoryId... Preference repo MUST NOT be consulted when step 1 hits.") asserts the strict behavior only for the *successful* L2 path. There is no test covering the merchant-hit-but-`_ensureL2`-null fallthrough — meaning a future regression could mute merchant signals entirely without any test catching it.

**Fix:** Reword the docstring to "step 1 success short-circuits step 2; an unresolvable step-1 categoryId falls through to step 2" AND add a unit test:

```dart
test('merchant match with unresolvable categoryId falls through to keyword preferences', () async {
  when(() => mockMerchantDb.findMerchant(any())).thenReturn(
    const MerchantMatch(merchantName: 'X', categoryId: 'cat_nonexistent', confidence: 0.9, ledgerType: LedgerType.survival),
  );
  when(() => mockCategoryRepo.findById('cat_nonexistent')).thenAnswer((_) async => null);
  when(() => mockPrefRepo.findByKeyword('X')).thenAnswer((_) async => [_pref('X', 'cat_food_dining_out')]);
  when(() => mockCategoryRepo.findById('cat_food_dining_out')).thenAnswer(
    (_) async => _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
  );
  final result = await resolver.resolve('X', 'X');
  expect(result?.categoryId, 'cat_food_dining_out');
  expect(result?.source, MatchSource.keyword);
});
```

### WR-03: Resolver docstring says "4-stage pipeline" but implementation has 3 effective stages — plan/prompt also drift

**File:** `lib/application/voice/voice_category_resolver.dart:2-11`
**Issue:** The library doc lists:

```
///   1. MerchantDatabase
///   2. category_keyword_preferences (seed `hitCount=0` + learned, ...)
///   3. L1 → `${l1Id}_other` fallback (D-03; ...)
///   4. miss → null
```

Step 3 is not a pipeline stage — it's a transform applied inside `_ensureL2` to the output of steps 1 and 2. Step 4 ("miss → null") is a default, not a stage. The provider's docstring at `repository_providers.dart:228-233` similarly calls it a "4-stage lookup pipeline" using the same misleading framing.

Worse, the **phase prompt** describes the pipeline as `"exact synonym → fuzzy synonym → merchant DB → L1→${l1Id}_other fallback"` — but the code has:
- no fuzzy stage at all
- merchant first, then keyword/synonym (the inverse order vs. the prompt)

The prompt describes intent that does not match the code. This is doc drift somewhere in the planning chain.

**Fix:** Either reconcile the docstring to "2 lookups + L2 normalization" (truth) or commit to a 4-stage design (e.g. add a fuzzy stage). At minimum, fix the comment to:

```dart
/// 1. MerchantDatabase lookup (extracted keyword → MerchantMatch)
/// 2. category_keyword_preferences lookup (extracted keyword → first row by hitCount DESC, lastUsed DESC)
/// Each successful lookup is normalized to L2 via `_ensureL2` (D-03).
/// Miss → null.
```

### WR-04: `resolve()` accepts `inputText` but only uses it in the empty guard — dead parameter is API noise

**File:** `lib/application/voice/voice_category_resolver.dart:55-95`
**Issue:**

```dart
Future<CategoryMatchResult?> resolve(
  String inputText,
  String extractedKeyword,
) async {
  if (extractedKeyword.isEmpty && inputText.isEmpty) return null;
  // ... inputText is never used again
```

The two-argument signature suggests `inputText` matters semantically (the full sentence vs. the extracted token), but in practice the resolver only looks up by `extractedKeyword`. Callers passing the wrong value to `inputText` will see no behavioral change — that's a footgun for the next refactor.

**Fix:** drop `inputText` and update both call sites in `ParseVoiceInputUseCase`:

```dart
Future<CategoryMatchResult?> resolve(String extractedKeyword) async {
  if (extractedKeyword.isEmpty) return null;
  // ...
}
```

If a future stage needs the full input (e.g. for context-aware disambiguation), add it back then — not preemptively.

### WR-05: Merchant branch re-runs `findMerchant` against canonical name — wasteful and yields stale `confidence`

**File:** `lib/application/voice/parse_voice_input_use_case.dart:59-76`
**Issue:** The flow is:

1. `extractAndMatchMerchant(recognizedText, _merchantDatabase)` → returns `MerchantMatch(merchantName: 'スターバックス', ...)` (canonical name) from input `'スタバ'`.
2. `_voiceCategoryResolver.resolve(recognizedText, merchantMatch.merchantName)` — passes `'スターバックス'` as extractedKeyword.
3. Inside resolver, step 1 calls `_merchantDatabase.findMerchant('スターバックス')` — a second lookup, this time exact-match against the canonical name. Returns a fresh `MerchantMatch` with `confidence = 0.90` (hard-coded in `_toMatch`).

This is correct but wasteful. More subtly: the original alias-derived match might have come from substring match (lowest priority), but the second-pass exact-name match always reports `confidence = 0.90`. The confidence the user sees is decoupled from how well the input actually matched.

**Fix:** Pass the *original* merchantMatch through instead of re-deriving it:

```dart
if (merchantMatch != null) {
  // Normalize the categoryId to L2 directly — no need to re-run MerchantDatabase.
  final normalizedId = await _voiceCategoryResolver.normalizeToL2(merchantMatch.categoryId);
  categoryMatch = CategoryMatchResult(
    categoryId: normalizedId ?? merchantMatch.categoryId,
    confidence: merchantMatch.confidence,
    source: MatchSource.merchant,
  );
  ledgerType = merchantMatch.ledgerType;
}
```

Requires exposing `_ensureL2` as a public method on `VoiceCategoryResolver` (e.g. `normalizeToL2`). The PATTERNS.md §9 caveat is preserved — the merchant categoryId still cannot bypass `_ensureL2`.

### WR-06: `_extractKeyword` strips both Japanese AND Chinese particles unconditionally — over-strips mixed-language input

**File:** `lib/application/voice/parse_voice_input_use_case.dart:112-128`
**Issue:**

```dart
remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');
remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');
```

There's no locale gating. For a JP user saying `'本を買った'`, the Chinese strip is inert. But for a ZH user mixing katakana/hiragana (which happens with imported product names), Japanese particles will be removed. More importantly — the use case receives `localeId` as a parameter but never propagates it to keyword extraction. The locale signal is dropped.

**Fix:** Gate the strips on `localeId` when available, or accept the over-stripping but document it explicitly. At minimum, pass `localeId` into `_extractKeyword` so a future fix has a hook.

### WR-07: `_extractKeyword` regex `(円|元|ドル)` is incomplete vs `voice_text_parser`'s currency list

**File:** `lib/application/voice/parse_voice_input_use_case.dart:116-119`
**Issue:** The amount-stripping regex:

```dart
remaining = remaining.replaceAll(
  RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
  '',
);
```

handles `円|元|ドル` but `voice_text_parser._extractPotentialMerchantNames` (line 438-439) ALSO recognizes `块|yen`:

```dart
.replaceAll(RegExp(r'\d[\d,.]*\s*(?:円|元|块|yen)'), '')
```

Inconsistent currency suffix sets between two functions in the same use case path. A user saying `'5块钱'` will have `5` stripped but `块` left behind as part of the keyword fed to the resolver, possibly corrupting the lookup.

**Fix:** Extract the currency-suffix list to a shared constant and use it in both places. This is also a maintainability concern — currency markers should be centralized once.

## Info

### IN-01: `DefaultVoiceSynonyms._epoch` constant is a magic value duplicated in DAO

**File:** `lib/shared/constants/default_synonyms.dart:26`, `lib/data/daos/category_keyword_preference_dao.dart:90`
**Issue:** Both files independently declare `DateTime(2026, 1, 1)` as the seed epoch. The DAO comment says "matched by `DefaultVoiceSynonyms._epoch`" but there's no compile-time enforcement — if one drifts, audit queries that look for "untouched seeds" break silently.

**Fix:** Define the epoch ONCE (e.g. in `default_synonyms.dart` as a `public static final`) and import it in the DAO.

### IN-02: Documentary `CategoryKeywordPreference.hitCount` / `lastUsed` are ignored by repo — risk of future "but I set it" bugs

**File:** `lib/data/repositories/category_keyword_preference_repository_impl.dart:29-37`, `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart:15-20`
**Issue:** `insertSeedBatch(List<CategoryKeywordPreference> seeds)` accepts model objects but only forwards `keyword` and `categoryId` to the DAO. The repo comment says "model fields are ignored intentionally" — but the type signature gives no hint of this.

A future caller who pulls a `CategoryKeywordPreference` with `hitCount = 42` and passes it to `insertSeedBatch` will be surprised when the row lands with `hitCount = 0`. The signature lies.

**Fix:** Change the parameter type to a record or a dedicated `SeedSpec({keyword, categoryId})` type — the same shape the DAO already uses internally:

```dart
Future<void> insertSeedBatch(List<({String keyword, String categoryId})> seeds);
```

### IN-03: `MerchantDatabase.findMerchant` substring match is O(n × m) — potential miscategorization on common substrings

**File:** `lib/infrastructure/ml/merchant_database.dart:150-162`
**Issue:** Step 3 substring match:

```dart
if (lowerQuery.contains(entry.name.toLowerCase()) ||
    entry.name.toLowerCase().contains(lowerQuery)) {
  return _toMatch(entry);
}
```

Both directions are problematic for short tokens. With `query = 'Mac'`, every alias check runs `'mac'.contains('mac')` AND `'mac'.contains(...)`. The entry list has `'マック', 'Mac', 'McDonald', 'mcdonalds'` — `lowerQuery = 'mac'` would match `'McDonald'.contains('mac')` → false, but `'Mac'.contains('mac')` → true → returns McDonald. OK in this case.

But with `query = 'a'` (a single letter — rare but possible after `_extractKeyword` over-strips), the contains check would match Amazon's `'a'.contains('amazon')` → false but `'amazon'.contains('a')` → true → match. This is a footgun.

**Fix:** Add a minimum-length guard to the substring pass:

```dart
if (lowerQuery.length < 3) return null; // too ambiguous for substring match
```

Performance is out of v1 scope but correctness is in scope.

### IN-04: `seedVoiceSynonymsUseCase` and `seedCategoriesUseCase` ordering is enforced by comment only

**File:** `lib/main.dart:108-114`
**Issue:**

```dart
final seedCategories = ref.read(seedCategoriesUseCaseProvider);
await seedCategories.execute();
// Phase 21 D-01: synonyms must run AFTER categories.
final seedVoiceSynonyms = ref.read(seedVoiceSynonymsUseCaseProvider);
await seedVoiceSynonyms.execute();
```

The dependency (synonyms reference categoryIds that must exist) is enforced only by code ordering and a comment. If the seed runs ahead of categories, the DAO's `INSERT OR IGNORE` will happily write rows pointing at non-existent categoryIds — there's no FK constraint validating this (`category_keyword_preferences` schema doesn't reference categories.id).

**Fix:** Either:
- Add a sanity check inside `SeedVoiceSynonymsUseCase.execute` that the first seed's categoryId resolves via `CategoryRepository.findById`, OR
- Fold the two seed calls into a single `SeedAllUseCase` that owns the ordering contract.

### IN-05: `_otherIdOverrides` duplicated between resolver and architecture test — drift risk

**File:** `lib/application/voice/voice_category_resolver.dart:24-26`, `test/architecture/category_other_l2_invariant_test.dart:35-37`
**Issue:** Both files define:

```dart
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

The resolver's comment says "When adding entries here, update the architecture test allowlist atomically" — pure manual discipline. The architecture test's comment makes the same request in reverse. There is no automated cross-check.

**Fix:** Export the map from one location (resolver, or a shared `lib/shared/constants/category_other_id_overrides.dart`) and import it in the test. Eliminates the drift class entirely.

### IN-06: Phase 21 seed lacks an L1 `_other` keyword for `cat_other_expense` — corpus cannot exercise the documented override

**File:** `lib/shared/constants/default_synonyms.dart`
**Issue:** The `_otherIdOverrides` map handles `cat_other_expense → cat_other_other`, and `voice_category_resolver_test.dart:213-237` exercises this override via a mock. But `DefaultVoiceSynonyms.all` has **no seed** that would route a real user utterance through this path — none of `その他`, `他`, `etc.`, `etc` are seeded. The override exists but cannot be triggered by any seed-only path; it can only fire after a user explicitly trains a row pointing at `cat_other_expense`.

This isn't a bug, but it's a coverage gap: the override is exercised by a mock test and the architecture invariant, but never by a corpus case. If a future refactor breaks the override mapping in ways the architecture test doesn't catch (e.g. typo'd key), the corpus would not notice.

**Fix:** Add a single seed row `_seed('その他', 'cat_other_expense')` (and possibly `_seed('其他', 'cat_other_expense')`) and a corresponding corpus case asserting it resolves to `cat_other_other`. Now the override is covered by both unit and corpus tests.

---

_Reviewed: 2026-05-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
