/// Voice category corpus for zh resolver (Phase 21 / VOICE-04 / VOICE-05 / VOICE-06).
///
/// ~30 cases covering 5 anchor categories (D-10):
///   1. Direct L2 synonym hit       (e.g. 早餐 -> cat_food_dining_out)
///   2. Merchant DB alias -> L2 hit (e.g. Starbucks alias -> cat_food_cafe)
///   3. L1 -> ${l1Id}_other fallback (e.g. 吃饭 -> cat_food_other)
///   4. Learned override            (e.g. 咖啡 -> cat_hobbies_subscription
///                                   after recordCorrection hitCount=3)
///   5. ID drift regression         (e.g. 洋服 -> cat_clothing_other,
///                                   NOT cat_shopping which does NOT exist)
///
/// Used by:
///   - test/integration/voice/voice_category_corpus_zh_test.dart
///
/// Conventions (mirror test/fixtures/voice_corpus_zh.dart):
///   - All entries are pure const (no IO, no DateTime.now()).
///   - `const` records, no class wrapper.
///   - No imports from project source (test fixture is data-only).
///
/// Honesty contract: every keyword below MUST resolve via the resolver
/// against the live `DefaultVoiceSynonyms.all` + `MerchantDatabase` seeds
/// (or via a setUp insert documented in the test file). The corpus is
/// strictly tied to those data sources — a drift there cascades here.
library;

/// Record type for a single voice category corpus test case.
///
/// Phase 21 shape (extends Phase 20's `VoiceCorpusCase`):
///   - `keyword` is the pre-extracted token fed to `VoiceCategoryResolver.resolve`
///   - `expectedCategoryId` is the L2 categoryId the resolver must return
typedef VoiceCategoryCorpusCase = ({
  String input,
  String keyword,
  String expectedCategoryId,
  String? note,
});

/// Chinese voice category corpus — 30 const test cases.
///
/// Split: 5 anchor + 25 statistical bucket.
const List<VoiceCategoryCorpusCase> voiceCategoryCorpusZh = [
  // ---------------------------------------------------------------------------
  // Anchor cases (5) — note must start with "anchor:"
  // ---------------------------------------------------------------------------
  (
    input: '早餐 100元',
    keyword: '早餐',
    expectedCategoryId: 'cat_food_dining_out',
    note: 'anchor: direct L2 synonym hit VOICE-04',
  ),
  (
    input: '星巴克咖啡',
    keyword: 'starbucks',
    expectedCategoryId: 'cat_food_cafe',
    note: 'anchor: merchant DB alias -> L2 hit VOICE-04',
  ),
  (
    input: '吃饭 300元',
    keyword: '吃饭',
    expectedCategoryId: 'cat_food_other',
    note: 'anchor: L1 -> _other fallback VOICE-05',
  ),
  (
    input: '咖啡 500元',
    keyword: '咖啡',
    expectedCategoryId: 'cat_hobbies_subscription',
    note: 'anchor: learned override (requires-setup) VOICE-06',
  ),
  (
    input: '洋服を買った',
    keyword: '洋服',
    expectedCategoryId: 'cat_clothing_other',
    note: 'anchor: ID drift regression — cat_shopping does NOT exist',
  ),

  // ---------------------------------------------------------------------------
  // Statistical bucket (25) — non-anchor cases (note does NOT start with "anchor:")
  // ---------------------------------------------------------------------------
  // Food (direct L2 synonyms)
  (
    input: '午饭 80元',
    keyword: '午饭',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '午餐',
    keyword: '午餐',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '晚饭',
    keyword: '晚饭',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '晚餐 200',
    keyword: '晚餐',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '外出就餐，用了5000日元',
    keyword: '外出就餐',
    expectedCategoryId: 'cat_food_dining_out',
    note: '260526 real-world utterance — was missing from synonyms',
  ),
  (
    input: '聚餐 3000',
    keyword: '聚餐',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '今晚去餐厅吃饭',
    keyword: '餐厅',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  // Food (L1 fallback)
  (
    input: '外卖 50元',
    keyword: '外卖',
    expectedCategoryId: 'cat_food_other',
    note: 'L1 fallback via _ensureL2',
  ),
  // Merchant DB hits (zh users referencing Japanese/English brands)
  (
    input: 'マクドナルド',
    keyword: 'マクドナルド',
    expectedCategoryId: 'cat_food_dining_out',
    note: 'merchant exact-name match',
  ),
  (
    input: '7-11 便利店',
    keyword: '7-11',
    expectedCategoryId: 'cat_food_groceries',
    note: 'merchant alias zh user typed',
  ),
  // Transport
  (
    input: '地铁 5元',
    keyword: '地铁',
    expectedCategoryId: 'cat_transport_train',
    note: null,
  ),
  (
    input: '公交 5元',
    keyword: '公交',
    expectedCategoryId: 'cat_transport_bus',
    note: null,
  ),
  (
    input: '打车回家',
    keyword: '打车',
    expectedCategoryId: 'cat_transport_taxi',
    note: null,
  ),
  // Clothing (D-04 ID drift fixed)
  (
    input: '衣服',
    keyword: '衣服',
    expectedCategoryId: 'cat_clothing_other',
    note: 'L1 fallback (D-04 cat_shopping ID drift fixed)',
  ),
  (
    input: '鞋子 300',
    keyword: '鞋子',
    expectedCategoryId: 'cat_clothing_shoes',
    note: null,
  ),
  (
    input: '服 200',
    keyword: '服',
    expectedCategoryId: 'cat_clothing_other',
    note: 'L1 fallback (ja-style keyword zh users sometimes type)',
  ),
  // Hobbies (D-04 ID drift fixed)
  (
    input: '电影 60',
    keyword: '电影',
    expectedCategoryId: 'cat_hobbies_movies',
    note: 'D-04 cat_entertainment ID drift fixed',
  ),
  (
    input: '游戏',
    keyword: '游戏',
    expectedCategoryId: 'cat_hobbies_games',
    note: null,
  ),
  // Health (D-04 ID drift fixed)
  (
    input: '医院',
    keyword: '医院',
    expectedCategoryId: 'cat_health_hospital',
    note: 'D-04 cat_medical ID drift fixed',
  ),
  (
    input: '药',
    keyword: '药',
    expectedCategoryId: 'cat_health_medicine',
    note: null,
  ),
  // Housing & Utilities
  (
    input: '房租 5000',
    keyword: '房租',
    expectedCategoryId: 'cat_housing_rent',
    note: null,
  ),
  (
    input: '水费',
    keyword: '水费',
    expectedCategoryId: 'cat_utilities_water',
    note: null,
  ),
  (
    input: '电费 200',
    keyword: '电费',
    expectedCategoryId: 'cat_utilities_electricity',
    note: null,
  ),
  // Education
  (
    input: '书',
    keyword: '书',
    expectedCategoryId: 'cat_education_books',
    note: null,
  ),
  // Merchant DB hits (extra)
  (
    input: '麦当劳',
    keyword: 'mcdonalds',
    expectedCategoryId: 'cat_food_dining_out',
    note: 'merchant alias (lowercase English) for zh user',
  ),
  (
    input: 'Netflix 月费',
    keyword: 'Netflix',
    expectedCategoryId: 'cat_hobbies_subscription',
    note: 'merchant exact-name (D-04 cat_entertainment ID drift fixed)',
  ),
  (
    input: '优衣库',
    keyword: 'Uniqlo',
    expectedCategoryId: 'cat_clothing_clothes',
    note: 'merchant alias (D-04 cat_shopping ID drift fixed)',
  ),
  (
    input: '亚马逊',
    keyword: 'amazon',
    expectedCategoryId: 'cat_daily_other',
    note: 'merchant alias (D-04 cat_shopping ID drift fixed)',
  ),

  // ---------------------------------------------------------------------------
  // Quick task 260526-l0o (Issue 2) — extended transport synonyms + substring
  // ---------------------------------------------------------------------------
  (
    input: '新干线票价',
    keyword: '新干线',
    expectedCategoryId: 'cat_transport_shinkansen',
    note: 'l0o Issue 2: zh 新干线 exact seed',
  ),
  (
    input: '坐新干线去东京',
    keyword: '坐新干线去东京',
    expectedCategoryId: 'cat_transport_shinkansen',
    note: 'l0o Issue 2: zh 新干线 substring scan',
  ),
  (
    input: '飞机票钱',
    keyword: '飞机票',
    expectedCategoryId: 'cat_transport_flights',
    note: 'l0o Issue 2: zh 飞机票 new seed',
  ),
  (
    input: '地铁卡充值',
    keyword: '地铁卡充值',
    expectedCategoryId: 'cat_transport_train',
    note: 'l0o Issue 2: zh 地铁 substring scan',
  ),
  (
    input: '出租车去机场',
    keyword: '出租车',
    expectedCategoryId: 'cat_transport_taxi',
    note: 'l0o Issue 2: zh 出租车 new seed',
  ),
];
