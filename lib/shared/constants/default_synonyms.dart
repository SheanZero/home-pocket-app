import '../../features/accounting/domain/models/category_keyword_preference.dart';

/// System default voice synonyms — seed source for VOICE-04 / VOICE-06.
///
/// Phase 21 D-01: seed rows are written into the existing
/// `category_keyword_preferences` Drift table with `hitCount = 0` (sentinel
/// distinguishing seed-source rows from user-learned ones). The same table
/// participates in P2P sync and incremental learning; seed and learned rows
/// share a single lookup surface.
///
/// Phase 21 Claude's-Discretion option (a): Dart-literal seed source (not
/// YAML) per 21-PATTERNS.md §2. Adding a new keyword/categoryId pair below
/// is sufficient to extend the synonym dictionary — no resolver code change
/// is required (VOICE-06 extensibility contract).
///
/// English (en) entries are deferred to v1.4+ — do NOT add `breakfast`,
/// `lunch`, `coffee`, `food`, `clothes`, `shoes`, `book`, `hospital`,
/// `medicine`, `rent`, `utilities`, `movie`, `game`, `train`, `bus`, `taxi`.
/// REQUIREMENTS.md §Out of scope defers English voice input to v1.4+.
abstract final class DefaultVoiceSynonyms {
  /// Fixed epoch used as `lastUsed` for all seed rows.
  ///
  /// Mirrors the value the DAO writes when persisting seeds (see
  /// `CategoryKeywordPreferenceDao.insertSeedBatch`). The model field is
  /// documentary only — the DAO ignores it and writes this constant.
  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// All built-in voice synonym seeds (zh + ja, no en).
  static List<CategoryKeywordPreference> get all => _all;

  static final List<CategoryKeywordPreference> _all = [
    // ===== Food (ja) — direct L2 + L1 entries =====
    _seed('朝ごはん', 'cat_food_dining_out'),
    _seed('朝食', 'cat_food_dining_out'),
    _seed('昼ごはん', 'cat_food_dining_out'),
    _seed('昼食', 'cat_food_dining_out'),
    _seed('ランチ', 'cat_food_dining_out'),
    _seed('晩ごはん', 'cat_food_dining_out'),
    _seed('夕食', 'cat_food_dining_out'),
    _seed('夕飯', 'cat_food_dining_out'),
    _seed('食事', 'cat_food'), // L1 → resolver _ensureL2 routes to cat_food_other
    _seed('ご飯', 'cat_food'), // L1 → cat_food_other
    _seed('弁当', 'cat_food'), // L1 → cat_food_other
    _seed('コーヒー', 'cat_food_cafe'),
    _seed('カフェ', 'cat_food_cafe'),
    _seed('おやつ', 'cat_food'), // L1 → cat_food_other

    // ===== Food (zh) =====
    _seed('早饭', 'cat_food_dining_out'),
    _seed('早餐', 'cat_food_dining_out'),
    _seed('午饭', 'cat_food_dining_out'),
    _seed('午餐', 'cat_food_dining_out'),
    _seed('晚饭', 'cat_food_dining_out'),
    _seed('晚餐', 'cat_food_dining_out'),
    _seed('吃饭', 'cat_food'), // L1 → cat_food_other
    _seed('外卖', 'cat_food'), // L1 → cat_food_other
    _seed('咖啡', 'cat_food_cafe'),

    // ===== Transport =====
    _seed('電車', 'cat_transport_train'),
    _seed('電車代', 'cat_transport_train'),
    _seed('バス', 'cat_transport_bus'),
    _seed('バス代', 'cat_transport_bus'),
    _seed('タクシー', 'cat_transport_taxi'),
    _seed('交通費', 'cat_transport'), // L1 → cat_transport_other
    _seed('定期', 'cat_transport'), // L1 → cat_transport_other
    _seed('Suica', 'cat_transport'), // L1 → cat_transport_other
    _seed('PASMO', 'cat_transport'), // L1 → cat_transport_other
    _seed('地铁', 'cat_transport_train'),
    _seed('公交', 'cat_transport_bus'),
    _seed('打车', 'cat_transport_taxi'),

    // ===== Clothing — D-04 ID-drift fix: prior placeholder L1 corrected to cat_clothing* =====
    _seed('服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('洋服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('靴', 'cat_clothing_shoes'),
    _seed('衣服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('鞋子', 'cat_clothing_shoes'),

    // ===== Hobbies — D-04 ID-drift fix: prior placeholder L1 corrected to cat_hobbies* =====
    _seed('映画', 'cat_hobbies_movies'),
    _seed('ゲーム', 'cat_hobbies_games'),
    _seed('カラオケ', 'cat_hobbies'), // L1 → cat_hobbies_other
    _seed('電影', 'cat_hobbies_movies'),
    _seed('电影', 'cat_hobbies_movies'),
    _seed('游戏', 'cat_hobbies_games'),

    // ===== Health — D-04 ID-drift fix: prior placeholder L1 corrected to cat_health* =====
    _seed('病院', 'cat_health_hospital'),
    _seed('薬', 'cat_health_medicine'),
    _seed('医院', 'cat_health_hospital'),
    _seed('药', 'cat_health_medicine'),

    // ===== Housing & Utilities =====
    _seed('家賃', 'cat_housing_rent'),
    _seed('水道', 'cat_utilities_water'),
    _seed('電気', 'cat_utilities_electricity'),
    _seed('ガス', 'cat_utilities_gas'),
    _seed('房租', 'cat_housing_rent'),
    _seed('水费', 'cat_utilities_water'),
    _seed('电费', 'cat_utilities_electricity'),

    // ===== Education =====
    _seed('本', 'cat_education_books'),
    _seed('书', 'cat_education_books'),
  ];

  /// Helper factory — builds a documentary `CategoryKeywordPreference` carrying
  /// the seed values. The downstream DAO writes its own `hitCount=0` and epoch
  /// (Phase 21 D-01 sentinel) regardless of what is set here.
  static CategoryKeywordPreference _seed(String keyword, String categoryId) =>
      CategoryKeywordPreference(
        keyword: keyword,
        categoryId: categoryId,
        hitCount: 0,
        lastUsed: _epoch,
      );
}
