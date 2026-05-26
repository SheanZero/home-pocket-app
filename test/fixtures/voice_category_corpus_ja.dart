/// Voice category corpus for ja resolver (Phase 21 / VOICE-04 / VOICE-05 / VOICE-06).
///
/// ~30 cases covering 5 anchor categories (D-10):
///   1. Direct L2 synonym hit       (e.g. 朝ごはん -> cat_food_dining_out)
///   2. Merchant DB -> L2 hit        (e.g. スタバ alias -> cat_food_cafe)
///   3. L1 -> ${l1Id}_other fallback (e.g. 食事 -> cat_food_other)
///   4. ID drift regression (cat_entertainment -> cat_hobbies)
///   5. ID drift regression (cat_medical -> cat_health)
///
/// Used by:
///   - test/integration/voice/voice_category_corpus_ja_test.dart
///
/// Conventions (mirror test/fixtures/voice_corpus_ja.dart):
///   - All entries are pure const (no IO, no DateTime.now()).
///   - `const` records, no class wrapper.
///   - No imports from project source (test fixture is data-only).
///
/// Honesty contract: every keyword below MUST resolve via the resolver
/// against the live `DefaultVoiceSynonyms.all` + `MerchantDatabase` seeds.
/// The ja fixture does NOT use the learned-override setUp (the zh fixture
/// owns that anchor). All 5 ja anchors resolve via static seed lookups.
library;

/// Record type for a single voice category corpus test case.
///
/// Intentionally redeclared here (not imported from voice_category_corpus_zh.dart).
/// Fixture files are siblings; keeping each self-contained avoids cross-fixture
/// coupling for a trivial record shape. Signature is identical so consumers
/// can use either fixture interchangeably.
typedef VoiceCategoryCorpusCase = ({
  String input,
  String keyword,
  String expectedCategoryId,
  String? note,
});

/// Japanese voice category corpus — 30 const test cases.
///
/// Split: 5 anchor + 25 statistical bucket.
const List<VoiceCategoryCorpusCase> voiceCategoryCorpusJa = [
  // ---------------------------------------------------------------------------
  // Anchor cases (5) — note must start with "anchor:"
  // ---------------------------------------------------------------------------
  (
    input: '朝ごはん500円',
    keyword: '朝ごはん',
    expectedCategoryId: 'cat_food_dining_out',
    note: 'anchor: direct L2 synonym hit VOICE-04',
  ),
  (
    input: 'スタバでコーヒー',
    keyword: 'スタバ',
    expectedCategoryId: 'cat_food_cafe',
    note: 'anchor: merchant DB alias -> L2 hit VOICE-04',
  ),
  (
    input: '何か食べた',
    keyword: '食事',
    expectedCategoryId: 'cat_food_other',
    note: 'anchor: L1 -> _other fallback VOICE-05',
  ),
  (
    input: '映画を見た',
    keyword: '映画',
    expectedCategoryId: 'cat_hobbies_movies',
    note: 'anchor: ID drift regression — cat_entertainment does NOT exist',
  ),
  (
    input: '病院に行った',
    keyword: '病院',
    expectedCategoryId: 'cat_health_hospital',
    note: 'anchor: ID drift regression — cat_medical does NOT exist',
  ),

  // ---------------------------------------------------------------------------
  // Statistical bucket (25) — non-anchor cases
  // ---------------------------------------------------------------------------
  // Food (direct L2 synonyms)
  (
    input: '昼ごはん 800円',
    keyword: '昼ごはん',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: 'ランチ',
    keyword: 'ランチ',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '夕食 1200円',
    keyword: '夕食',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  (
    input: '朝食',
    keyword: '朝食',
    expectedCategoryId: 'cat_food_dining_out',
    note: null,
  ),
  // Food (L1 fallback)
  (
    input: '弁当',
    keyword: '弁当',
    expectedCategoryId: 'cat_food_other',
    note: 'L1 fallback via _ensureL2',
  ),
  (
    input: 'ご飯',
    keyword: 'ご飯',
    expectedCategoryId: 'cat_food_other',
    note: 'L1 fallback',
  ),
  // Food (cafe / drinks)
  (
    input: 'コーヒー 500円',
    keyword: 'コーヒー',
    expectedCategoryId: 'cat_food_cafe',
    note: null,
  ),
  (
    input: 'カフェ',
    keyword: 'カフェ',
    expectedCategoryId: 'cat_food_cafe',
    note: null,
  ),
  // Transport
  (
    input: '電車で会社',
    keyword: '電車',
    expectedCategoryId: 'cat_transport_train',
    note: null,
  ),
  (
    input: 'バス',
    keyword: 'バス',
    expectedCategoryId: 'cat_transport_bus',
    note: null,
  ),
  (
    input: 'タクシー',
    keyword: 'タクシー',
    expectedCategoryId: 'cat_transport_taxi',
    note: null,
  ),
  (
    input: '交通費 1000円',
    keyword: '交通費',
    expectedCategoryId: 'cat_transport_other',
    note: 'L1 fallback',
  ),
  // Clothing (D-04 ID drift fixed)
  (
    input: '服',
    keyword: '服',
    expectedCategoryId: 'cat_clothing_other',
    note: 'L1 fallback (D-04 cat_shopping ID drift fixed)',
  ),
  (
    input: '靴',
    keyword: '靴',
    expectedCategoryId: 'cat_clothing_shoes',
    note: null,
  ),
  // Hobbies (D-04 ID drift fixed)
  (
    input: 'ゲーム',
    keyword: 'ゲーム',
    expectedCategoryId: 'cat_hobbies_games',
    note: 'D-04 cat_entertainment ID drift fixed',
  ),
  (
    input: 'カラオケ',
    keyword: 'カラオケ',
    expectedCategoryId: 'cat_hobbies_other',
    note: 'L1 -> _other fallback',
  ),
  // Health (D-04 ID drift fixed)
  (
    input: '薬',
    keyword: '薬',
    expectedCategoryId: 'cat_health_medicine',
    note: 'D-04 cat_medical ID drift fixed',
  ),
  // Housing & Utilities
  (
    input: '家賃 50000',
    keyword: '家賃',
    expectedCategoryId: 'cat_housing_rent',
    note: null,
  ),
  (
    input: '水道',
    keyword: '水道',
    expectedCategoryId: 'cat_utilities_water',
    note: null,
  ),
  (
    input: '電気',
    keyword: '電気',
    expectedCategoryId: 'cat_utilities_electricity',
    note: null,
  ),
  (
    input: 'ガス',
    keyword: 'ガス',
    expectedCategoryId: 'cat_utilities_gas',
    note: null,
  ),
  // Education
  (
    input: '本',
    keyword: '本',
    expectedCategoryId: 'cat_education_books',
    note: null,
  ),
  // Merchant DB hits
  (
    input: 'スターバックスでコーヒー',
    keyword: 'スターバックス',
    expectedCategoryId: 'cat_food_cafe',
    note: 'merchant exact-name',
  ),
  (
    input: 'ニトリで家具',
    keyword: 'ニトリ',
    expectedCategoryId: 'cat_housing_furniture',
    note: 'merchant exact-name',
  ),
  (
    input: 'ユニクロで服',
    keyword: 'ユニクロ',
    expectedCategoryId: 'cat_clothing_clothes',
    note: 'merchant (D-04 cat_shopping ID drift fixed)',
  ),
  (
    input: 'Netflix月額',
    keyword: 'Netflix',
    expectedCategoryId: 'cat_hobbies_subscription',
    note: 'merchant (D-04 cat_entertainment ID drift fixed)',
  ),

  // ---------------------------------------------------------------------------
  // Quick task 260526-l0o (Issue 2) — extended transport synonyms + substring
  // ---------------------------------------------------------------------------
  (
    input: '新幹線で東京へ',
    keyword: '新幹線で東京へ',
    expectedCategoryId: 'cat_transport_shinkansen',
    note: 'l0o Issue 2: ja 新幹線 substring scan',
  ),
  (
    input: '飛行機の予約',
    keyword: '飛行機の予約',
    expectedCategoryId: 'cat_transport_flights',
    note: 'l0o Issue 2: ja 飛行機 substring scan via new seed',
  ),
  (
    input: '地下鉄の定期',
    keyword: '地下鉄の定期',
    expectedCategoryId: 'cat_transport_train',
    note: 'l0o Issue 2: ja 地下鉄 substring scan via new seed',
  ),
];
