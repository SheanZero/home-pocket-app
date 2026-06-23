import '../../features/accounting/domain/models/category_keyword_preference.dart';

/// Phase 21 D-01 / Phase 23 D-12 IN-01: Fixed epoch used as `lastUsed`
/// sentinel for all voice synonym seed rows. Single source of truth —
/// imported by both [DefaultVoiceSynonyms._seed] and
/// [CategoryKeywordPreferenceDao.insertSeedBatch] so that audit queries
/// filtering on `lastUsed = epoch` see consistent row counts across
/// both write paths.
final DateTime kVoiceSynonymSeedEpoch = DateTime(2026, 1, 1);

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
/// Phase 50 D-04 (DECOUP-02): EXPANDED from ~16-L2 coverage to full
/// speakable-L2 coverage. Every speakable L2 (90 ids = level-2 categories
/// MINUS pure `_other`/fallback buckets + admin families cat_tax_* / cat_asset_*
/// / cat_insurance_* / *_insurance / *_tax / cat_special_*) now carries at least
/// one zh DIRECT seed AND at least one ja DIRECT seed. Set-completeness is
/// machine-proven by `default_synonyms_speakable_coverage_test.dart`; every
/// categoryId is gated against the real-L2 / L1-with-child legal set by
/// `default_synonyms_categoryid_test.dart`. The exclusion families are
/// documented (and reviewable) in the coverage test source.
///
/// Direct-seed rule (set-completeness): each speakable L2 needs a seed whose
/// `categoryId` is that EXACT L2 id. An L1 seed (e.g. `食事`->`cat_food`) only
/// routes to that L1's `_other` bucket via the resolver's `_ensureL2`, never to
/// an arbitrary sibling L2 — so L1 catch-alls do NOT satisfy coverage.
///
/// English (en) entries are deferred to v1.4+ — do NOT add `breakfast`,
/// `lunch`, `coffee`, `food`, `clothes`, `shoes`, `book`, `hospital`,
/// `medicine`, `rent`, `utilities`, `movie`, `game`, `train`, `bus`, `taxi`.
/// REQUIREMENTS.md §Out of scope defers English voice input to v1.4+.
abstract final class DefaultVoiceSynonyms {
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
    _seed('外食', 'cat_food_dining_out'),
    _seed('レストラン', 'cat_food_dining_out'),
    _seed('居酒屋', 'cat_food_dining_out'),
    _seed('飲み会', 'cat_food_dining_out'),

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
    _seed('外出就餐', 'cat_food_dining_out'),
    _seed('外食', 'cat_food_dining_out'),
    _seed('聚餐', 'cat_food_dining_out'),
    _seed('餐厅', 'cat_food_dining_out'),
    _seed('饭店', 'cat_food_dining_out'),
    _seed('下馆子', 'cat_food_dining_out'),
    _seed('堂食', 'cat_food_dining_out'),
    _seed('点外卖', 'cat_food'), // L1 → cat_food_other
    // ===== Food — D-04 speakable-L2 direct coverage =====
    _seed('买菜', 'cat_food_groceries'), // zh — grocery run
    _seed('超市', 'cat_food_groceries'), // zh — supermarket
    _seed('食材', 'cat_food_groceries'), // zh — ingredients
    _seed('スーパー', 'cat_food_groceries'), // ja — supermarket
    _seed('食料品', 'cat_food_groceries'), // ja — groceries
    _seed('外卖配送', 'cat_food_delivery'), // zh — delivery
    _seed('送餐', 'cat_food_delivery'), // zh — meal delivery
    _seed('デリバリー', 'cat_food_delivery'), // ja — delivery
    _seed(
      '出前',
      'cat_food_delivery',
    ), // ja — takeout delivery (Han, but…) keep zh too
    _seed('うーばー', 'cat_food_delivery'), // ja — Uber (kana)
    _seed('饮料', 'cat_food_drinks'), // zh — drinks
    _seed('喝酒', 'cat_food_drinks'), // zh — drinking (alcohol)
    _seed('ドリンク', 'cat_food_drinks'), // ja — drinks
    _seed('お酒', 'cat_food_drinks'), // ja — alcohol
    // ===== Daily Necessities — D-04 direct coverage =====
    _seed('日用品', 'cat_daily_household'), // zh — household goods
    _seed('家居用品', 'cat_daily_household'), // zh — household items
    _seed('日用品費', 'cat_daily_household'), // ja — daily-goods cost (Han)
    _seed('せっけん', 'cat_daily_household'), // ja — soap (kana)
    _seed('育儿', 'cat_daily_children'), // zh — childcare goods
    _seed('婴儿用品', 'cat_daily_children'), // zh — baby supplies
    _seed('おむつ', 'cat_daily_children'), // ja — diapers (kana)
    _seed('ベビー用品', 'cat_daily_children'), // ja — baby goods
    _seed('香烟', 'cat_daily_tobacco'), // zh — cigarettes
    _seed('烟', 'cat_daily_tobacco'), // zh — tobacco
    _seed('タバコ', 'cat_daily_tobacco'), // ja — cigarettes
    _seed('たばこ', 'cat_daily_tobacco'), // ja — cigarettes (hiragana)
    _seed('药妆店', 'cat_daily_drugstore'), // zh — drugstore
    _seed('药妆', 'cat_daily_drugstore'), // zh — drug & cosmetics store
    _seed('ドラッグストア', 'cat_daily_drugstore'), // ja — drugstore
    _seed(
      '薬局',
      'cat_daily_drugstore',
    ), // ja — pharmacy/drugstore (Han) keep kana too
    _seed('くすりや', 'cat_daily_drugstore'), // ja — drugstore (hiragana)
    _seed('订阅', 'cat_daily_subscription'), // zh — subscription
    _seed('会员订阅', 'cat_daily_subscription'), // zh — membership subscription
    _seed('サブスク', 'cat_daily_subscription'), // ja — subscription
    _seed(
      '定期購読',
      'cat_daily_subscription',
    ), // ja — periodical subscription (Han) keep kana
    _seed('さぶすく', 'cat_daily_subscription'), // ja — subscription (hiragana)
    // ===== Pet — D-04 direct coverage =====
    _seed('宠物食品', 'cat_pet_food'), // zh — pet food
    _seed('猫粮', 'cat_pet_food'), // zh — cat food
    _seed('狗粮', 'cat_pet_food'), // zh — dog food
    _seed('ペットフード', 'cat_pet_food'), // ja — pet food
    _seed('えさ', 'cat_pet_food'), // ja — feed (hiragana)
    _seed('宠物用品', 'cat_pet_supplies'), // zh — pet supplies
    _seed('猫砂', 'cat_pet_supplies'), // zh — cat litter
    _seed('ペット用品', 'cat_pet_supplies'), // ja — pet supplies
    _seed('ペットグッズ', 'cat_pet_supplies'), // ja — pet goods
    _seed('宠物医院', 'cat_pet_medical'), // zh — vet clinic
    _seed('兽医', 'cat_pet_medical'), // zh — veterinarian
    _seed('動物病院', 'cat_pet_medical'), // ja — animal hospital (Han) keep kana
    _seed('ペット病院', 'cat_pet_medical'), // ja — pet hospital
    _seed('宠物美容', 'cat_pet_grooming'), // zh — pet grooming
    _seed('宠物洗澡', 'cat_pet_grooming'), // zh — pet bath
    _seed('トリミング', 'cat_pet_grooming'), // ja — grooming
    _seed('ペット美容', 'cat_pet_grooming'), // ja — pet beauty
    _seed('宠物酒店', 'cat_pet_hotel'), // zh — pet hotel
    _seed('宠物寄养', 'cat_pet_hotel'), // zh — pet boarding
    _seed('ペットホテル', 'cat_pet_hotel'), // ja — pet hotel
    _seed('ペット預かり', 'cat_pet_hotel'), // ja — pet boarding (mixed) has kana
    // ===== Transport =====
    _seed('電車', 'cat_transport_train'),
    _seed('電車代', 'cat_transport_train'),
    _seed('でんしゃ', 'cat_transport_train'), // ja — train (hiragana, D-04 ja gap)
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

    // ===== Quick task 260526-l0o (Issue 2) — extended transport synonyms ====
    _seed('新干线', 'cat_transport_shinkansen'), // zh — bullet train
    _seed('新幹線', 'cat_transport_shinkansen'), // ja — bullet train
    _seed('しんかんせん', 'cat_transport_shinkansen'), // ja kana reading
    _seed('飞机', 'cat_transport_flights'), // zh — plane
    _seed('飞机票', 'cat_transport_flights'),
    _seed('機票', 'cat_transport_flights'), // zh-TW
    _seed('飛行機', 'cat_transport_flights'), // ja
    _seed(
      'ひこうき',
      'cat_transport_flights',
    ), // ja — plane (hiragana, D-04 ja gap)
    _seed('地下鉄', 'cat_transport_train'), // ja
    _seed('巴士', 'cat_transport_bus'), // zh
    _seed('出租车', 'cat_transport_taxi'), // zh
    _seed('出租', 'cat_transport_taxi'), // zh shortened
    _seed('的士', 'cat_transport_taxi'), // zh-HK
    _seed('高速バス', 'cat_transport_highway_bus'), // ja
    _seed(
      '高速大巴',
      'cat_transport_highway_bus',
    ), // zh — highway bus (D-04 zh gap)
    _seed('長途巴士', 'cat_transport_highway_bus'), // zh — long-distance coach
    // ===== Clothing — D-04 ID-drift fix: prior placeholder L1 corrected to cat_clothing* =====
    _seed('服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('洋服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('靴', 'cat_clothing_shoes'),
    _seed('衣服', 'cat_clothing'), // L1 → cat_clothing_other
    _seed('鞋子', 'cat_clothing_shoes'),
    _seed('くつ', 'cat_clothing_shoes'), // ja — shoes (hiragana, D-04 ja gap)
    _seed('スニーカー', 'cat_clothing_shoes'), // ja — sneakers
    // ===== Clothing & Beauty — D-04 direct coverage =====
    _seed('买衣服', 'cat_clothing_clothes'), // zh — buy clothes
    _seed('上衣', 'cat_clothing_clothes'), // zh — top / garment
    _seed('ふく', 'cat_clothing_clothes'), // ja — clothes (hiragana)
    _seed('シャツ', 'cat_clothing_clothes'), // ja — shirt
    _seed('饰品', 'cat_clothing_accessories'), // zh — accessories
    _seed('首饰', 'cat_clothing_accessories'), // zh — jewelry
    _seed('アクセサリー', 'cat_clothing_accessories'), // ja — accessories
    _seed('腕時計', 'cat_clothing_accessories'), // ja — wristwatch (Han) keep kana
    _seed('とけい', 'cat_clothing_accessories'), // ja — watch (hiragana)
    _seed('内衣', 'cat_clothing_underwear'), // zh — underwear
    _seed('内裤', 'cat_clothing_underwear'), // zh — undergarment
    _seed('下着', 'cat_clothing_underwear'), // ja — underwear (Han) keep kana
    _seed('インナー', 'cat_clothing_underwear'), // ja — innerwear
    _seed('理发', 'cat_clothing_hair'), // zh — haircut
    _seed('美发', 'cat_clothing_hair'), // zh — hairdressing
    _seed('美容院', 'cat_clothing_hair'), // ja/zh — hair salon (Han) keep kana
    _seed('カット', 'cat_clothing_hair'), // ja — haircut
    _seed('びよういん', 'cat_clothing_hair'), // ja — beauty salon (hiragana)
    _seed('化妆品', 'cat_clothing_cosmetics'), // zh — cosmetics
    _seed('彩妆', 'cat_clothing_cosmetics'), // zh — makeup
    _seed('コスメ', 'cat_clothing_cosmetics'), // ja — cosmetics
    _seed('けしょうひん', 'cat_clothing_cosmetics'), // ja — cosmetics (hiragana)
    _seed('美容护理', 'cat_clothing_esthetic'), // zh — esthetic care
    _seed('美容', 'cat_clothing_esthetic'), // zh — beauty treatment
    _seed('エステ', 'cat_clothing_esthetic'), // ja — esthetic salon
    _seed('まつげ', 'cat_clothing_esthetic'), // ja — eyelash (hiragana)
    _seed('干洗', 'cat_clothing_cleaning'), // zh — dry cleaning
    _seed('洗衣', 'cat_clothing_cleaning'), // zh — laundry
    _seed('クリーニング', 'cat_clothing_cleaning'), // ja — cleaning
    _seed('せんたく', 'cat_clothing_cleaning'), // ja — laundry (hiragana)
    _seed('包', 'cat_clothing_bags'), // zh — bag
    _seed('包包', 'cat_clothing_bags'), // zh — handbag (colloquial)
    _seed('カバン', 'cat_clothing_bags'), // ja — bag
    _seed('バッグ', 'cat_clothing_bags'), // ja — bag
    // ===== Socializing — D-04 direct coverage =====
    _seed('应酬', 'cat_social_drinks'), // zh — social drinking
    _seed('请客', 'cat_social_drinks'), // zh — treating others
    _seed('飲み代', 'cat_social_drinks'), // ja — drink expenses (Han) keep kana
    _seed('のみかい', 'cat_social_drinks'), // ja — drinking party (hiragana)
    _seed('送礼', 'cat_social_gifts'), // zh — gift giving
    _seed('礼物', 'cat_social_gifts'), // zh — gift
    _seed('プレゼント', 'cat_social_gifts'), // ja — present
    _seed('おくりもの', 'cat_social_gifts'), // ja — gift (hiragana)
    _seed('随礼', 'cat_social_ceremonial'), // zh — ceremonial cash gift
    _seed('份子钱', 'cat_social_ceremonial'), // zh — wedding/funeral money
    _seed(
      'ご祝儀',
      'cat_social_ceremonial',
    ), // ja — congratulatory gift (mixed) has kana
    _seed('こうでん', 'cat_social_ceremonial'), // ja — condolence money (hiragana)
    _seed('会费', 'cat_social_fees'), // zh — membership fee
    _seed('社团费', 'cat_social_fees'), // zh — club dues
    _seed('会費', 'cat_social_fees'), // ja — fee (Han) keep kana
    _seed('かいひ', 'cat_social_fees'), // ja — membership fee (hiragana)
    // ===== Health — D-04 ID-drift fix: prior placeholder L1 corrected to cat_health* =====
    _seed('病院', 'cat_health_hospital'),
    _seed('薬', 'cat_health_medicine'),
    _seed('医院', 'cat_health_hospital'),
    _seed('药', 'cat_health_medicine'),
    _seed(
      'びょういん',
      'cat_health_hospital',
    ), // ja — hospital (hiragana, D-04 ja gap)
    _seed(
      'くすり',
      'cat_health_medicine',
    ), // ja — medicine (hiragana, D-04 ja gap)
    // ===== Health & Medical — D-04 direct coverage =====
    _seed('健身', 'cat_health_fitness'), // zh — fitness
    _seed('健身房', 'cat_health_fitness'), // zh — gym
    _seed('ジム', 'cat_health_fitness'), // ja — gym
    _seed('フィットネス', 'cat_health_fitness'), // ja — fitness
    _seed('按摩', 'cat_health_massage'), // zh — massage
    _seed('推拿', 'cat_health_massage'), // zh — therapeutic massage
    _seed('マッサージ', 'cat_health_massage'), // ja — massage
    _seed('せいたい', 'cat_health_massage'), // ja — body adjustment (hiragana)
    _seed('看牙', 'cat_health_dental'), // zh — dental visit
    _seed('牙科', 'cat_health_dental'), // zh — dentistry
    _seed('歯医者', 'cat_health_dental'), // ja — dentist (Han) keep kana
    _seed('はいしゃ', 'cat_health_dental'), // ja — dentist (hiragana)
    _seed('保健品', 'cat_health_supplements'), // zh — supplements
    _seed('营养品', 'cat_health_supplements'), // zh — nutrition supplement
    _seed('サプリ', 'cat_health_supplements'), // ja — supplement
    _seed('サプリメント', 'cat_health_supplements'), // ja — supplement
    _seed('体检', 'cat_health_dock'), // zh — medical checkup
    _seed('健康检查', 'cat_health_dock'), // zh — health examination
    _seed(
      '人間ドック',
      'cat_health_dock',
    ), // ja — comprehensive checkup (mixed) has kana
    _seed('けんしん', 'cat_health_dock'), // ja — health checkup (hiragana)
    // ===== Education =====
    _seed('本', 'cat_education_books'),
    _seed('书', 'cat_education_books'),
    _seed('ほん', 'cat_education_books'), // ja — book (hiragana, D-04 ja gap)
    _seed('書籍', 'cat_education_books'), // ja — books (Han) keep kana above
    // ===== Education & Self-Improvement — D-04 direct coverage =====
    _seed('报纸', 'cat_education_newspapers'), // zh — newspaper
    _seed('订报', 'cat_education_newspapers'), // zh — newspaper subscription
    _seed('新聞', 'cat_education_newspapers'), // ja — newspaper (Han) keep kana
    _seed('しんぶん', 'cat_education_newspapers'), // ja — newspaper (hiragana)
    _seed('上课', 'cat_education_classes'), // zh — classes / lessons
    _seed('培训', 'cat_education_classes'), // zh — training course
    _seed('習い事', 'cat_education_classes'), // ja — lessons (mixed) has kana
    _seed('レッスン', 'cat_education_classes'), // ja — lesson
    _seed('教材', 'cat_education_textbooks'), // zh — teaching material
    _seed('课本', 'cat_education_textbooks'), // zh — textbook
    _seed('教科書', 'cat_education_textbooks'), // ja — textbook (Han) keep kana
    _seed('テキスト', 'cat_education_textbooks'), // ja — textbook
    _seed('学费', 'cat_education_tuition'), // zh — tuition
    _seed('学杂费', 'cat_education_tuition'), // zh — school fees
    _seed('学費', 'cat_education_tuition'), // ja — tuition (Han) keep kana
    _seed('がくひ', 'cat_education_tuition'), // ja — tuition (hiragana)
    _seed('补习班', 'cat_education_cram_school'), // zh — cram school
    _seed('辅导班', 'cat_education_cram_school'), // zh — tutoring class
    _seed(
      '塾',
      'cat_education_cram_school',
    ), // ja/zh — cram school (Han) keep kana
    _seed('じゅく', 'cat_education_cram_school'), // ja — cram school (hiragana)
    _seed('升学考试', 'cat_education_entrance_exam'), // zh — entrance exam
    _seed('考试报名', 'cat_education_entrance_exam'), // zh — exam registration
    _seed(
      '受験',
      'cat_education_entrance_exam',
    ), // ja — entrance exam (Han) keep kana
    _seed(
      'じゅけん',
      'cat_education_entrance_exam',
    ), // ja — taking exams (hiragana)
    _seed('学资保险', 'cat_education_gakushi_hoken'), // zh — education insurance
    _seed(
      '教育金保险',
      'cat_education_gakushi_hoken',
    ), // zh — education savings insurance
    _seed(
      '学資保険',
      'cat_education_gakushi_hoken',
    ), // ja — gakushi hoken (Han) keep kana
    _seed(
      'がくしほけん',
      'cat_education_gakushi_hoken',
    ), // ja — education insurance (hiragana)
    _seed('讲座', 'cat_education_seminar'), // zh — seminar
    _seed('研讨会', 'cat_education_seminar'), // zh — workshop
    _seed('セミナー', 'cat_education_seminar'), // ja — seminar
    _seed('こうざ', 'cat_education_seminar'), // ja — course / lecture (hiragana)
    // ===== Housing & Utilities =====
    _seed('家賃', 'cat_housing_rent'),
    _seed('水道', 'cat_utilities_water'),
    _seed('電気', 'cat_utilities_electricity'),
    _seed('ガス', 'cat_utilities_gas'),
    _seed('房租', 'cat_housing_rent'),
    _seed('水费', 'cat_utilities_water'),
    _seed('电费', 'cat_utilities_electricity'),
    _seed('やちん', 'cat_housing_rent'), // ja — rent (hiragana, D-04 ja gap)
    _seed(
      'でんきだい',
      'cat_utilities_electricity',
    ), // ja — electricity bill (hiragana, D-04 ja gap)
    _seed('すいどう', 'cat_utilities_water'), // ja — water (hiragana, D-04 ja gap)
    _seed('燃气费', 'cat_utilities_gas'), // zh — gas bill (D-04 zh gap)
    _seed('天然气', 'cat_utilities_gas'), // zh — natural gas
    // ===== Utilities — D-04 direct coverage =====
    _seed('煤油', 'cat_utilities_kerosene'), // zh — kerosene
    _seed('取暖油', 'cat_utilities_kerosene'), // zh — heating oil
    _seed('灯油', 'cat_utilities_kerosene'), // ja — kerosene (Han) keep kana
    _seed('とうゆ', 'cat_utilities_kerosene'), // ja — kerosene (hiragana)
    // ===== Housing — D-04 direct coverage =====
    _seed('房贷', 'cat_housing_mortgage'), // zh — mortgage
    _seed('按揭', 'cat_housing_mortgage'), // zh — home loan
    _seed(
      '住宅ローン',
      'cat_housing_mortgage',
    ), // ja — housing loan (mixed) has kana
    _seed('じゅうたくろーん', 'cat_housing_mortgage'), // ja — housing loan (hiragana)
    _seed('物业费', 'cat_housing_management'), // zh — property management fee
    _seed('管理费', 'cat_housing_management'), // zh — management fee
    _seed(
      '管理費',
      'cat_housing_management',
    ), // ja — management fee (Han) keep kana
    _seed('かんりひ', 'cat_housing_management'), // ja — management fee (hiragana)
    _seed('家具', 'cat_housing_furniture'), // zh — furniture
    _seed('家私', 'cat_housing_furniture'), // zh — furniture (colloquial)
    _seed('かぐ', 'cat_housing_furniture'), // ja — furniture (hiragana)
    _seed('ソファ', 'cat_housing_furniture'), // ja — sofa
    _seed('家电', 'cat_housing_appliances'), // zh — home appliances
    _seed('电器', 'cat_housing_appliances'), // zh — electrical appliances
    _seed('家電', 'cat_housing_appliances'), // ja — appliances (Han) keep kana
    _seed('かでん', 'cat_housing_appliances'), // ja — appliances (hiragana)
    _seed('装修', 'cat_housing_renovation'), // zh — renovation
    _seed('翻新', 'cat_housing_renovation'), // zh — refurbishment
    _seed('リフォーム', 'cat_housing_renovation'), // ja — renovation
    _seed(
      '改装',
      'cat_housing_renovation',
    ), // ja/zh — remodel (Han) keep kana above
    _seed('搬家费用', 'cat_housing_utilities_setup'), // zh — moving setup cost
    _seed('开通费', 'cat_housing_utilities_setup'), // zh — utility activation fee
    _seed(
      '引越し費用',
      'cat_housing_utilities_setup',
    ), // ja — moving cost (mixed) has kana
    _seed(
      'かいせつ',
      'cat_housing_utilities_setup',
    ), // ja — opening/setup (hiragana)
    // ===== Communication — D-04 direct coverage =====
    _seed('手机费', 'cat_communication_mobile'), // zh — mobile phone bill
    _seed('话费', 'cat_communication_mobile'), // zh — phone charges
    _seed(
      '携帯代',
      'cat_communication_mobile',
    ), // ja — mobile bill (Han) keep kana
    _seed('けいたい', 'cat_communication_mobile'), // ja — mobile phone (hiragana)
    _seed('座机', 'cat_communication_landline'), // zh — landline
    _seed('固定电话', 'cat_communication_landline'), // zh — fixed-line phone
    _seed(
      '固定電話',
      'cat_communication_landline',
    ), // ja — landline (Han) keep kana
    _seed('こていでんわ', 'cat_communication_landline'), // ja — landline (hiragana)
    _seed('网费', 'cat_communication_internet'), // zh — internet fee
    _seed('宽带', 'cat_communication_internet'), // zh — broadband
    _seed(
      'ネット代',
      'cat_communication_internet',
    ), // ja — internet fee (mixed) has kana
    _seed('プロバイダ', 'cat_communication_internet'), // ja — provider
    _seed('有线电视', 'cat_communication_broadcast'), // zh — cable TV
    _seed('卫星电视', 'cat_communication_broadcast'), // zh — satellite TV
    _seed(
      '放送',
      'cat_communication_broadcast',
    ), // ja — broadcast (Han) keep kana
    _seed('ほうそう', 'cat_communication_broadcast'), // ja — broadcast (hiragana)
    _seed('快递', 'cat_communication_delivery'), // zh — courier / delivery
    _seed('快递费', 'cat_communication_delivery'), // zh — shipping fee
    _seed(
      '宅配',
      'cat_communication_delivery',
    ), // ja — home delivery (Han) keep kana
    _seed('たくはい', 'cat_communication_delivery'), // ja — delivery (hiragana)
    _seed(
      'NHK受信料',
      'cat_communication_nhk',
    ), // zh/ja — NHK fee (mixed) has kana
    _seed('电视台费', 'cat_communication_nhk'), // zh — broadcaster fee
    _seed('受信料', 'cat_communication_nhk'), // ja — reception fee (Han) keep kana
    _seed('じゅしんりょう', 'cat_communication_nhk'), // ja — reception fee (hiragana)
    _seed('邮费', 'cat_communication_postage'), // zh — postage
    _seed('邮寄', 'cat_communication_postage'), // zh — mailing
    _seed('郵便', 'cat_communication_postage'), // ja — mail (Han) keep kana
    _seed('ゆうびん', 'cat_communication_postage'), // ja — postal (hiragana)
    // ===== Car & Motorcycle — D-04 direct coverage =====
    _seed('加油', 'cat_car_fuel'), // zh — refuel (SC4 fuel gap)
    _seed('给油', 'cat_car_fuel'), // zh-variant — refuel (SC4 fuel gap)
    _seed('給油', 'cat_car_fuel'), // ja — refuel (Han) (SC4 fuel gap)
    _seed('ガソリン', 'cat_car_fuel'), // ja — gasoline (SC4 fuel gap)
    _seed('停车费', 'cat_car_parking'), // zh — parking fee
    _seed('停车', 'cat_car_parking'), // zh — parking
    _seed('駐車場', 'cat_car_parking'), // ja — parking lot (Han) keep kana
    _seed('ちゅうしゃ', 'cat_car_parking'), // ja — parking (hiragana)
    _seed('过路费', 'cat_car_toll'), // zh — toll
    _seed('高速费', 'cat_car_toll'), // zh — highway toll
    _seed('高速代', 'cat_car_toll'), // ja — expressway toll (Han) keep kana
    _seed('こうそくだい', 'cat_car_toll'), // ja — expressway toll (hiragana)
    _seed('车贷', 'cat_car_loan'), // zh — car loan
    _seed('购车贷款', 'cat_car_loan'), // zh — auto loan
    _seed('車のローン', 'cat_car_loan'), // ja — car loan (mixed) has kana
    _seed('くるまろーん', 'cat_car_loan'), // ja — car loan (hiragana)
    _seed('车辆保养', 'cat_car_maintenance'), // zh — car maintenance
    _seed('修车', 'cat_car_maintenance'), // zh — car repair
    _seed(
      '車検',
      'cat_car_maintenance',
    ), // ja — vehicle inspection (Han) keep kana
    _seed('せいび', 'cat_car_maintenance'), // ja — maintenance (hiragana)
    _seed('共享汽车', 'cat_car_car_share'), // zh — car share
    _seed('租车', 'cat_car_car_share'), // zh — car rental
    _seed('カーシェア', 'cat_car_car_share'), // ja — car share
    _seed('レンタカー', 'cat_car_car_share'), // ja — rental car
    _seed('驾校', 'cat_car_driving_school'), // zh — driving school
    _seed('考驾照', 'cat_car_driving_school'), // zh — getting a license
    _seed(
      '教習所',
      'cat_car_driving_school',
    ), // ja — driving school (Han) keep kana
    _seed(
      'きょうしゅうじょ',
      'cat_car_driving_school',
    ), // ja — driving school (hiragana)
    // ===== Allowance — D-04 direct coverage =====
    _seed('零花钱', 'cat_allowance_self'), // zh — own pocket money
    _seed('我的零花', 'cat_allowance_self'), // zh — my allowance
    _seed('お小遣い', 'cat_allowance_self'), // ja — pocket money (mixed) has kana
    _seed('こづかい', 'cat_allowance_self'), // ja — allowance (hiragana)
    _seed('配偶零花钱', 'cat_allowance_spouse'), // zh — spouse allowance
    _seed(
      '老婆零花',
      'cat_allowance_spouse',
    ), // zh — partner allowance (colloquial)
    _seed(
      '配偶のお小遣い',
      'cat_allowance_spouse',
    ), // ja — spouse allowance (mixed) has kana
    _seed(
      'つまのこづかい',
      'cat_allowance_spouse',
    ), // ja — wife's allowance (hiragana)
    _seed('孩子零花钱', 'cat_allowance_kids'), // zh — kids allowance
    _seed('儿童零花', 'cat_allowance_kids'), // zh — children's allowance
    _seed(
      '子供のお小遣い',
      'cat_allowance_kids',
    ), // ja — kids allowance (mixed) has kana
    _seed('こどものこづかい', 'cat_allowance_kids'), // ja — child allowance (hiragana)
    // ===== Other — D-04 direct coverage =====
    _seed('汇款', 'cat_other_remittance'), // zh — remittance
    _seed('转账', 'cat_other_remittance'), // zh — money transfer
    _seed('送金', 'cat_other_remittance'), // ja — remittance (Han) keep kana
    _seed('そうきん', 'cat_other_remittance'), // ja — remittance (hiragana)
    _seed('杂费', 'cat_other_misc'), // zh — miscellaneous
    _seed('杂项', 'cat_other_misc'), // zh — sundries
    _seed('雑費', 'cat_other_misc'), // ja — misc expense (Han) keep kana
    _seed('ざっぴ', 'cat_other_misc'), // ja — misc expense (hiragana)
    _seed('未分类', 'cat_other_unclassified'), // zh — unclassified
    _seed('其它支出', 'cat_other_unclassified'), // zh — other spending
    _seed('未分類', 'cat_other_unclassified'), // ja — unclassified (Han) keep kana
    _seed('みぶんるい', 'cat_other_unclassified'), // ja — unclassified (hiragana)
    // ===== Hobbies — D-04 ID-drift fix: prior placeholder L1 corrected to cat_hobbies* =====
    _seed('映画', 'cat_hobbies_movies'),
    _seed('ゲーム', 'cat_hobbies_games'),
    _seed('カラオケ', 'cat_hobbies'), // L1 → cat_hobbies_other
    _seed('電影', 'cat_hobbies_movies'),
    _seed('电影', 'cat_hobbies_movies'),
    _seed('游戏', 'cat_hobbies_games'),
    _seed('えいが', 'cat_hobbies_movies'), // ja — movie (hiragana, D-04 ja gap)
    // ===== Hobbies & Entertainment — D-04 direct coverage =====
    _seed('休闲', 'cat_hobbies_leisure'), // zh — leisure
    _seed('娱乐', 'cat_hobbies_leisure'), // zh — entertainment
    _seed('レジャー', 'cat_hobbies_leisure'), // ja — leisure
    _seed('あそび', 'cat_hobbies_leisure'), // ja — play / leisure (hiragana)
    _seed('活动', 'cat_hobbies_events'), // zh — event
    _seed('演唱会', 'cat_hobbies_events'), // zh — concert
    _seed('イベント', 'cat_hobbies_events'), // ja — event
    _seed('ライブ', 'cat_hobbies_events'), // ja — live show
    _seed('漫画', 'cat_hobbies_books'), // zh — comics / manga
    _seed('小说', 'cat_hobbies_books'), // zh — novel
    _seed('まんが', 'cat_hobbies_books'), // ja — manga (hiragana)
    _seed('コミック', 'cat_hobbies_books'), // ja — comic
    _seed('旅游', 'cat_hobbies_travel'), // zh — travel
    _seed('旅行', 'cat_hobbies_travel'), // zh — trip
    _seed('りょこう', 'cat_hobbies_travel'), // ja — travel (hiragana)
    _seed('ツアー', 'cat_hobbies_travel'), // ja — tour
    _seed('音乐', 'cat_hobbies_music'), // zh — music
    _seed('演唱', 'cat_hobbies_music'), // zh — singing / vocal
    _seed('音楽', 'cat_hobbies_music'), // ja — music (Han) keep kana
    _seed('おんがく', 'cat_hobbies_music'), // ja — music (hiragana)
    _seed('兴趣订阅', 'cat_hobbies_subscription'), // zh — hobby subscription
    _seed('视频会员', 'cat_hobbies_subscription'), // zh — streaming membership
    _seed(
      '動画サブスク',
      'cat_hobbies_subscription',
    ), // ja — video subscription (mixed) has kana
    _seed('はいしん', 'cat_hobbies_subscription'), // ja — streaming (hiragana)
    _seed('追星', 'cat_hobbies_oshikatsu'), // zh — idol fandom
    _seed('应援', 'cat_hobbies_oshikatsu'), // zh — cheering / support spending
    _seed('推し活', 'cat_hobbies_oshikatsu'), // ja — oshikatsu (mixed) has kana
    _seed('おしかつ', 'cat_hobbies_oshikatsu'), // ja — oshikatsu (hiragana)
    // ===== Other-expense override seeds (Phase 23 D-15 / IN-06) =====
    // Exercises the cat_other_expense → cat_other_other override in
    // VoiceCategoryResolver._ensureL2 via real corpus utterances.
    // 'other' is added as a v1.4+ en-voice hedge — voice gating in v1.3 is
    // zh/ja only, but the override is exercised in case en voice activates.
    // Warning for v1.4+ en voice: 'other' is a common English word that may
    // collide with contextual utterances like "the other day…". Add corpus
    // regression cases before enabling full en voice support.
    _seed('その他', 'cat_other_expense'),
    _seed('其他', 'cat_other_expense'),
    _seed('other', 'cat_other_expense'),
  ];

  /// Helper factory — builds a documentary `CategoryKeywordPreference` carrying
  /// the seed values. The downstream DAO writes its own `hitCount=0` and epoch
  /// (Phase 21 D-01 sentinel) regardless of what is set here.
  static CategoryKeywordPreference _seed(String keyword, String categoryId) =>
      CategoryKeywordPreference(
        keyword: keyword,
        categoryId: categoryId,
        hitCount: 0,
        lastUsed: kVoiceSynonymSeedEpoch,
      );
}
