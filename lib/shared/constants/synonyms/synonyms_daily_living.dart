import '../../../features/accounting/domain/models/category_keyword_preference.dart';
import 'synonyms_support.dart';

/// Voice synonym seeds — daily-living L1 families: Food, Daily Necessities,
/// Pet, Transport, Clothing & Beauty, Housing, Utilities, Communication, Car.
/// Phase 50 D-04 (DECOUP-02): every speakable L2 in these families carries at
/// least one zh DIRECT seed AND at least one ja DIRECT seed (full L2 coverage,
/// admin-family-inclusive per the user scope decision). See
/// `default_synonyms.dart` for the aggregation + coverage-gate contract.
final List<CategoryKeywordPreference> kSynonymsDailyLiving = [
  ..._foodAndDaily,
  ..._petAndTransport,
  ..._clothingAndSocial,
  ..._housingUtilitiesCommunicationCar,
];

final List<CategoryKeywordPreference> _foodAndDaily = [
  // ===== Food (ja) — direct L2 + L1 entries =====
  seed('朝ごはん', 'cat_food_dining_out'),
  seed('朝食', 'cat_food_dining_out'),
  seed('昼ごはん', 'cat_food_dining_out'),
  seed('昼食', 'cat_food_dining_out'),
  seed('ランチ', 'cat_food_dining_out'),
  seed('晩ごはん', 'cat_food_dining_out'),
  seed('夕食', 'cat_food_dining_out'),
  seed('夕飯', 'cat_food_dining_out'),
  seed('食事', 'cat_food'), // L1 → resolver _ensureL2 routes to cat_food_other
  seed('ご飯', 'cat_food'), // L1 → cat_food_other
  seed('弁当', 'cat_food'), // L1 → cat_food_other
  seed('コーヒー', 'cat_food_cafe'),
  seed('カフェ', 'cat_food_cafe'),
  seed('おやつ', 'cat_food'), // L1 → cat_food_other
  seed('外食', 'cat_food_dining_out'),
  seed('レストラン', 'cat_food_dining_out'),
  seed('居酒屋', 'cat_food_dining_out'),
  seed('飲み会', 'cat_food_dining_out'),

  // ===== Food (zh) =====
  seed('早饭', 'cat_food_dining_out'),
  seed('早餐', 'cat_food_dining_out'),
  seed('午饭', 'cat_food_dining_out'),
  seed('午餐', 'cat_food_dining_out'),
  seed('晚饭', 'cat_food_dining_out'),
  seed('晚餐', 'cat_food_dining_out'),
  seed('吃饭', 'cat_food'), // L1 → cat_food_other
  seed('外卖', 'cat_food'), // L1 → cat_food_other
  seed('咖啡', 'cat_food_cafe'),
  seed('外出就餐', 'cat_food_dining_out'),
  // 外食 (shared Han word) is seeded once in the ja section above (IN-01).
  seed('聚餐', 'cat_food_dining_out'),
  seed('餐厅', 'cat_food_dining_out'),
  seed('饭店', 'cat_food_dining_out'),
  seed('下馆子', 'cat_food_dining_out'),
  seed('堂食', 'cat_food_dining_out'),
  seed('点外卖', 'cat_food'), // L1 → cat_food_other
  // ===== Food — speakable-L2 direct coverage =====
  seed('买菜', 'cat_food_groceries'), // zh — grocery run
  seed('超市', 'cat_food_groceries'), // zh — supermarket
  seed('食材', 'cat_food_groceries'), // zh — ingredients
  seed('スーパー', 'cat_food_groceries'), // ja — supermarket
  seed('食料品', 'cat_food_groceries'), // ja — groceries
  seed('外卖配送', 'cat_food_delivery'), // zh — delivery
  seed('送餐', 'cat_food_delivery'), // zh — meal delivery
  seed('デリバリー', 'cat_food_delivery'), // ja — delivery
  seed('出前', 'cat_food_delivery'), // ja/zh — takeout delivery (Han)
  seed('ウーバー', 'cat_food_delivery'), // ja — Uber (katakana, D2 refinement)
  seed('饮料', 'cat_food_drinks'), // zh — drinks
  seed('喝酒', 'cat_food_drinks'), // zh — drinking (alcohol)
  seed('ドリンク', 'cat_food_drinks'), // ja — drinks
  seed('お酒', 'cat_food_drinks'), // ja — alcohol
  // ===== Food — _other bucket direct coverage (full-L2 scope) =====
  seed('其他餐饮', 'cat_food_other'), // zh — other food/dining
  seed('その他食費', 'cat_food_other'), // ja — other food cost (kana その他)
  // ===== Daily Necessities — direct coverage =====
  seed('日用品', 'cat_daily_household'), // zh — household goods
  seed('家居用品', 'cat_daily_household'), // zh — household items
  seed('日用品費', 'cat_daily_household'), // ja — daily-goods cost (Han)
  seed('せっけん', 'cat_daily_household'), // ja — soap (kana)
  seed('育儿', 'cat_daily_children'), // zh — childcare goods
  seed('婴儿用品', 'cat_daily_children'), // zh — baby supplies
  seed('おむつ', 'cat_daily_children'), // ja — diapers (kana)
  seed('ベビー用品', 'cat_daily_children'), // ja — baby goods
  seed('香烟', 'cat_daily_tobacco'), // zh — cigarettes
  seed('烟', 'cat_daily_tobacco'), // zh — tobacco
  seed('タバコ', 'cat_daily_tobacco'), // ja — cigarettes
  seed('たばこ', 'cat_daily_tobacco'), // ja — cigarettes (hiragana)
  seed('药妆店', 'cat_daily_drugstore'), // zh — drugstore
  seed('药妆', 'cat_daily_drugstore'), // zh — drug & cosmetics store
  seed('ドラッグストア', 'cat_daily_drugstore'), // ja — drugstore
  seed('薬局', 'cat_daily_drugstore'), // ja — pharmacy/drugstore (Han)
  seed('くすりや', 'cat_daily_drugstore'), // ja — drugstore (hiragana)
  seed('订阅', 'cat_daily_subscription'), // zh — subscription
  seed('会员订阅', 'cat_daily_subscription'), // zh — membership subscription
  seed('サブスク', 'cat_daily_subscription'), // ja — subscription
  seed('定期購読', 'cat_daily_subscription'), // ja — periodical subscription (Han)
  seed('さぶすく', 'cat_daily_subscription'), // ja — subscription (hiragana)
  seed('其他日用', 'cat_daily_other'), // zh — other daily goods
  seed('その他日用品', 'cat_daily_other'), // ja — other daily goods (kana)
  // ===== Food & Daily Necessities (en) — VEN-01 / D-12 lowercase seeds =====
  // Authored lowercase: pairs with the 52-01 en-residual lowercasing so a
  // capitalized iOS STT keyword ("Coffee") still matches via findByKeyword.
  seed('breakfast', 'cat_food_dining_out'), // en — breakfast
  seed('lunch', 'cat_food_dining_out'), // en — lunch
  seed('dinner', 'cat_food_dining_out'), // en — dinner
  seed('restaurant', 'cat_food_dining_out'), // en — eating out
  seed('food', 'cat_food'), // en — L1 → cat_food_other
  seed('coffee', 'cat_food_cafe'), // en — coffee
  seed('cafe', 'cat_food_cafe'), // en — cafe
  seed('groceries', 'cat_food_groceries'), // en — groceries
  seed('supermarket', 'cat_food_groceries'), // en — supermarket
  seed('delivery', 'cat_food_delivery'), // en — food delivery
  seed('takeout', 'cat_food_delivery'), // en — takeout delivery
  seed('drinks', 'cat_food_drinks'), // en — drinks
  seed('alcohol', 'cat_food_drinks'), // en — alcohol
  seed('other food', 'cat_food_other'), // en — other food/dining
  seed('household goods', 'cat_daily_household'), // en — household goods
  seed('soap', 'cat_daily_household'), // en — soap / daily goods
  seed('baby supplies', 'cat_daily_children'), // en — baby supplies
  seed('diapers', 'cat_daily_children'), // en — diapers
  seed('cigarettes', 'cat_daily_tobacco'), // en — cigarettes
  seed('tobacco', 'cat_daily_tobacco'), // en — tobacco
  seed('drugstore', 'cat_daily_drugstore'), // en — drugstore
  seed('pharmacy goods', 'cat_daily_drugstore'), // en — drugstore goods
  seed('subscription', 'cat_daily_subscription'), // en — subscription
  seed('other daily', 'cat_daily_other'), // en — other daily goods
];

final List<CategoryKeywordPreference> _petAndTransport = [
  // ===== Pet — direct coverage =====
  seed('宠物食品', 'cat_pet_food'), // zh — pet food
  seed('猫粮', 'cat_pet_food'), // zh — cat food
  seed('狗粮', 'cat_pet_food'), // zh — dog food
  seed('ペットフード', 'cat_pet_food'), // ja — pet food
  seed('えさ', 'cat_pet_food'), // ja — feed (hiragana)
  seed('宠物用品', 'cat_pet_supplies'), // zh — pet supplies
  seed('猫砂', 'cat_pet_supplies'), // zh — cat litter
  seed('ペット用品', 'cat_pet_supplies'), // ja — pet supplies
  seed('ペットグッズ', 'cat_pet_supplies'), // ja — pet goods
  seed('宠物医院', 'cat_pet_medical'), // zh — vet clinic
  seed('兽医', 'cat_pet_medical'), // zh — veterinarian
  seed('動物病院', 'cat_pet_medical'), // ja — animal hospital (Han)
  seed('ペット病院', 'cat_pet_medical'), // ja — pet hospital
  seed('宠物美容', 'cat_pet_grooming'), // zh — pet grooming
  seed('宠物洗澡', 'cat_pet_grooming'), // zh — pet bath
  seed('トリミング', 'cat_pet_grooming'), // ja — grooming
  seed('ペット美容', 'cat_pet_grooming'), // ja — pet beauty
  seed('宠物酒店', 'cat_pet_hotel'), // zh — pet hotel
  seed('宠物寄养', 'cat_pet_hotel'), // zh — pet boarding
  seed('ペットホテル', 'cat_pet_hotel'), // ja — pet hotel
  seed('ペット預かり', 'cat_pet_hotel'), // ja — pet boarding (mixed)
  seed('宠物保险', 'cat_pet_insurance'), // zh — pet insurance
  seed('ペット保険', 'cat_pet_insurance'), // ja — pet insurance
  seed('其他宠物', 'cat_pet_other'), // zh — other pet expense
  seed('その他ペット', 'cat_pet_other'), // ja — other pet (kana その他)
  // ===== Transport =====
  seed('電車', 'cat_transport_train'),
  seed('電車代', 'cat_transport_train'),
  seed('でんしゃ', 'cat_transport_train'), // ja — train (hiragana)
  seed('バス', 'cat_transport_bus'),
  seed('バス代', 'cat_transport_bus'),
  seed('タクシー', 'cat_transport_taxi'),
  seed('交通費', 'cat_transport'), // L1 → cat_transport_other
  seed('定期', 'cat_transport'), // L1 → cat_transport_other
  seed('Suica', 'cat_transport'), // L1 → cat_transport_other
  seed('PASMO', 'cat_transport'), // L1 → cat_transport_other
  seed('地铁', 'cat_transport_train'),
  seed('公交', 'cat_transport_bus'),
  seed('打车', 'cat_transport_taxi'),
  // ===== extended transport synonyms =====
  seed('新干线', 'cat_transport_shinkansen'), // zh — bullet train
  seed('新幹線', 'cat_transport_shinkansen'), // ja — bullet train
  seed('しんかんせん', 'cat_transport_shinkansen'), // ja kana reading
  seed('飞机', 'cat_transport_flights'), // zh — plane
  seed('飞机票', 'cat_transport_flights'),
  seed('機票', 'cat_transport_flights'), // zh-TW
  seed('飛行機', 'cat_transport_flights'), // ja
  seed('ひこうき', 'cat_transport_flights'), // ja — plane (hiragana)
  seed('地下鉄', 'cat_transport_train'), // ja
  seed('巴士', 'cat_transport_bus'), // zh
  seed('出租车', 'cat_transport_taxi'), // zh
  seed('出租', 'cat_transport_taxi'), // zh shortened
  seed('的士', 'cat_transport_taxi'), // zh-HK
  seed('高速バス', 'cat_transport_highway_bus'), // ja
  seed('高速大巴', 'cat_transport_highway_bus'), // zh — highway bus
  seed('長途巴士', 'cat_transport_highway_bus'), // zh — long-distance coach
  seed('其他交通', 'cat_transport_other'), // zh — other transport
  seed('その他交通費', 'cat_transport_other'), // ja — other transport (kana)
  // ===== Pet & Transport (en) — VEN-01 / D-12 lowercase seeds =====
  seed('pet food', 'cat_pet_food'), // en — pet food
  seed('cat food', 'cat_pet_food'), // en — cat food
  seed('pet supplies', 'cat_pet_supplies'), // en — pet supplies
  seed('cat litter', 'cat_pet_supplies'), // en — cat litter
  seed('vet', 'cat_pet_medical'), // en — veterinarian
  seed('animal hospital', 'cat_pet_medical'), // en — vet clinic
  seed('pet grooming', 'cat_pet_grooming'), // en — pet grooming
  seed('pet hotel', 'cat_pet_hotel'), // en — pet boarding
  seed('pet insurance', 'cat_pet_insurance'), // en — pet insurance
  seed('other pet', 'cat_pet_other'), // en — other pet expense
  seed('train', 'cat_transport_train'), // en — train
  seed('subway', 'cat_transport_train'), // en — subway / metro
  seed('bus', 'cat_transport_bus'), // en — bus
  seed('taxi', 'cat_transport_taxi'), // en — taxi
  seed('transport', 'cat_transport'), // en — L1 → cat_transport_other
  seed('bullet train', 'cat_transport_shinkansen'), // en — shinkansen
  seed('flight', 'cat_transport_flights'), // en — flight
  seed('plane ticket', 'cat_transport_flights'), // en — plane ticket
  seed('highway bus', 'cat_transport_highway_bus'), // en — highway bus
  seed('other transport', 'cat_transport_other'), // en — other transport
];

final List<CategoryKeywordPreference> _clothingAndSocial = [
  // ===== Clothing =====
  seed('服', 'cat_clothing'), // L1 → cat_clothing_other
  seed('洋服', 'cat_clothing'), // L1 → cat_clothing_other
  seed('靴', 'cat_clothing_shoes'),
  seed('衣服', 'cat_clothing'), // L1 → cat_clothing_other
  seed('鞋子', 'cat_clothing_shoes'),
  seed('くつ', 'cat_clothing_shoes'), // ja — shoes (hiragana)
  seed('スニーカー', 'cat_clothing_shoes'), // ja — sneakers
  // ===== Clothing & Beauty — direct coverage =====
  seed('买衣服', 'cat_clothing_clothes'), // zh — buy clothes
  seed('上衣', 'cat_clothing_clothes'), // zh — top / garment
  seed('ふく', 'cat_clothing_clothes'), // ja — clothes (hiragana)
  seed('シャツ', 'cat_clothing_clothes'), // ja — shirt
  seed('饰品', 'cat_clothing_accessories'), // zh — accessories
  seed('首饰', 'cat_clothing_accessories'), // zh — jewelry
  seed('アクセサリー', 'cat_clothing_accessories'), // ja — accessories
  seed('腕時計', 'cat_clothing_accessories'), // ja — wristwatch (Han)
  seed('とけい', 'cat_clothing_accessories'), // ja — watch (hiragana)
  seed('内衣', 'cat_clothing_underwear'), // zh — underwear
  seed('内裤', 'cat_clothing_underwear'), // zh — undergarment
  seed('下着', 'cat_clothing_underwear'), // ja — underwear (Han)
  seed('インナー', 'cat_clothing_underwear'), // ja — innerwear
  seed('理发', 'cat_clothing_hair'), // zh — haircut
  seed('美发', 'cat_clothing_hair'), // zh — hairdressing
  seed('美容院', 'cat_clothing_hair'), // ja/zh — hair salon (Han)
  seed('カット', 'cat_clothing_hair'), // ja — haircut
  seed('びよういん', 'cat_clothing_hair'), // ja — beauty salon (hiragana)
  seed('化妆品', 'cat_clothing_cosmetics'), // zh — cosmetics
  seed('彩妆', 'cat_clothing_cosmetics'), // zh — makeup
  seed('コスメ', 'cat_clothing_cosmetics'), // ja — cosmetics
  seed('けしょうひん', 'cat_clothing_cosmetics'), // ja — cosmetics (hiragana)
  seed('美容护理', 'cat_clothing_esthetic'), // zh — esthetic care
  seed('美容', 'cat_clothing_esthetic'), // zh — beauty treatment
  seed('エステ', 'cat_clothing_esthetic'), // ja — esthetic salon
  seed('まつげ', 'cat_clothing_esthetic'), // ja — eyelash (hiragana)
  seed('干洗', 'cat_clothing_cleaning'), // zh — dry cleaning
  seed('洗衣', 'cat_clothing_cleaning'), // zh — laundry
  seed('クリーニング', 'cat_clothing_cleaning'), // ja — cleaning
  seed('せんたく', 'cat_clothing_cleaning'), // ja — laundry (hiragana)
  seed('包', 'cat_clothing_bags'), // zh — bag
  seed('包包', 'cat_clothing_bags'), // zh — handbag (colloquial)
  seed('カバン', 'cat_clothing_bags'), // ja — bag
  seed('バッグ', 'cat_clothing_bags'), // ja — bag
  seed('其他服饰', 'cat_clothing_other'), // zh — other clothing
  seed('その他衣類', 'cat_clothing_other'), // ja — other clothing (kana)
  // ===== Socializing — direct coverage =====
  seed('应酬', 'cat_social_drinks'), // zh — social drinking
  seed('请客', 'cat_social_drinks'), // zh — treating others
  seed('飲み代', 'cat_social_drinks'), // ja — drink expenses (mixed)
  seed('のみかい', 'cat_social_drinks'), // ja — drinking party (hiragana)
  seed('送礼', 'cat_social_gifts'), // zh — gift giving
  seed('礼物', 'cat_social_gifts'), // zh — gift
  seed('プレゼント', 'cat_social_gifts'), // ja — present
  seed('おくりもの', 'cat_social_gifts'), // ja — gift (hiragana)
  seed('随礼', 'cat_social_ceremonial'), // zh — ceremonial cash gift
  seed('份子钱', 'cat_social_ceremonial'), // zh — wedding/funeral money
  seed('ご祝儀', 'cat_social_ceremonial'), // ja — congratulatory gift (mixed)
  seed('こうでん', 'cat_social_ceremonial'), // ja — condolence money (hiragana)
  seed('会费', 'cat_social_fees'), // zh — membership fee
  seed('社团费', 'cat_social_fees'), // zh — club dues
  seed('会費', 'cat_social_fees'), // ja — fee (Han)
  seed('かいひ', 'cat_social_fees'), // ja — membership fee (hiragana)
  seed('其他交际', 'cat_social_other'), // zh — other socializing
  seed('その他交際費', 'cat_social_other'), // ja — other socializing (kana)
  // ===== Clothing & Beauty / Socializing (en) — VEN-01 / D-12 seeds =====
  seed('clothes', 'cat_clothing'), // en — L1 → cat_clothing_other
  seed('shoes', 'cat_clothing_shoes'), // en — shoes
  seed('sneakers', 'cat_clothing_shoes'), // en — sneakers
  seed('shirt', 'cat_clothing_clothes'), // en — clothes/garment
  seed('accessories', 'cat_clothing_accessories'), // en — accessories
  seed('jewelry', 'cat_clothing_accessories'), // en — jewelry
  seed('underwear', 'cat_clothing_underwear'), // en — underwear
  seed('haircut', 'cat_clothing_hair'), // en — haircut
  seed('hair salon', 'cat_clothing_hair'), // en — hair salon
  seed('cosmetics', 'cat_clothing_cosmetics'), // en — cosmetics
  seed('makeup', 'cat_clothing_cosmetics'), // en — makeup
  seed('esthetic', 'cat_clothing_esthetic'), // en — esthetic care
  seed('dry cleaning', 'cat_clothing_cleaning'), // en — dry cleaning
  seed('laundry', 'cat_clothing_cleaning'), // en — laundry
  seed('bag', 'cat_clothing_bags'), // en — bag
  seed('other clothing', 'cat_clothing_other'), // en — other clothing
  seed('social drinks', 'cat_social_drinks'), // en — social drinking
  seed('gift', 'cat_social_gifts'), // en — gift
  seed('ceremonial gift', 'cat_social_ceremonial'), // en — ceremonial cash gift
  seed('membership fee', 'cat_social_fees'), // en — membership/club fee
  seed('other socializing', 'cat_social_other'), // en — other socializing
];

final List<CategoryKeywordPreference> _housingUtilitiesCommunicationCar = [
  // ===== Housing & Utilities =====
  seed('家賃', 'cat_housing_rent'),
  seed('水道', 'cat_utilities_water'),
  seed('電気', 'cat_utilities_electricity'),
  seed('ガス', 'cat_utilities_gas'),
  seed('房租', 'cat_housing_rent'),
  seed('水费', 'cat_utilities_water'),
  seed('电费', 'cat_utilities_electricity'),
  seed('やちん', 'cat_housing_rent'), // ja — rent (hiragana reading; 家賃 is Han)
  seed('でんきだい', 'cat_utilities_electricity'), // ja — electricity bill (hiragana)
  seed('すいどう', 'cat_utilities_water'), // ja — water (hiragana)
  seed('燃气费', 'cat_utilities_gas'), // zh — gas bill
  seed('天然气', 'cat_utilities_gas'), // zh — natural gas
  // ===== Utilities — direct coverage =====
  seed('煤油', 'cat_utilities_kerosene'), // zh — kerosene
  seed('取暖油', 'cat_utilities_kerosene'), // zh — heating oil
  seed('灯油', 'cat_utilities_kerosene'), // ja — kerosene (Han)
  seed('とうゆ', 'cat_utilities_kerosene'), // ja — kerosene (hiragana)
  seed('其他水电', 'cat_utilities_other'), // zh — other utilities
  seed('その他光熱費', 'cat_utilities_other'), // ja — other utilities (kana)
  // ===== Housing — direct coverage =====
  seed('房贷', 'cat_housing_mortgage'), // zh — mortgage
  seed('按揭', 'cat_housing_mortgage'), // zh — home loan
  seed('住宅ローン', 'cat_housing_mortgage'), // ja — housing loan (katakana ローン)
  seed('物业费', 'cat_housing_management'), // zh — property management fee
  seed('管理费', 'cat_housing_management'), // zh — management fee
  seed('管理費', 'cat_housing_management'), // ja — management fee (Han)
  seed('かんりひ', 'cat_housing_management'), // ja — management fee (hiragana)
  seed('家具', 'cat_housing_furniture'), // zh — furniture
  seed('家私', 'cat_housing_furniture'), // zh — furniture (colloquial)
  seed('かぐ', 'cat_housing_furniture'), // ja — furniture (hiragana)
  seed('ソファ', 'cat_housing_furniture'), // ja — sofa
  seed('家电', 'cat_housing_appliances'), // zh — home appliances
  seed('电器', 'cat_housing_appliances'), // zh — electrical appliances
  seed('家電', 'cat_housing_appliances'), // ja — appliances (Han)
  seed('かでん', 'cat_housing_appliances'), // ja — appliances (hiragana)
  seed('装修', 'cat_housing_renovation'), // zh — renovation
  seed('翻新', 'cat_housing_renovation'), // zh — refurbishment
  seed('リフォーム', 'cat_housing_renovation'), // ja — renovation
  seed('改装', 'cat_housing_renovation'), // ja/zh — remodel (Han)
  seed('搬家费用', 'cat_housing_utilities_setup'), // zh — moving setup cost
  seed('开通费', 'cat_housing_utilities_setup'), // zh — utility activation fee
  seed('引越し費用', 'cat_housing_utilities_setup'), // ja — moving cost (mixed)
  seed('かいせつ', 'cat_housing_utilities_setup'), // ja — opening/setup (hiragana)
  seed('房屋保险', 'cat_housing_insurance'), // zh — home insurance
  seed('かさいほけん', 'cat_housing_insurance'), // ja — fire insurance (hiragana reading; 火災保険 is Han)
  seed('房产税', 'cat_housing_property_tax'), // zh — property tax
  seed('こていしさんぜい', 'cat_housing_property_tax'), // ja — property tax (hiragana reading; 固定資産税 is Han)
  seed('其他住房', 'cat_housing_other'), // zh — other housing
  seed('その他住居', 'cat_housing_other'), // ja — other housing (kana)
  // ===== Communication — direct coverage =====
  seed('手机费', 'cat_communication_mobile'), // zh — mobile phone bill
  seed('话费', 'cat_communication_mobile'), // zh — phone charges
  seed('携帯代', 'cat_communication_mobile'), // ja — mobile bill (Han)
  seed('けいたい', 'cat_communication_mobile'), // ja — mobile phone (hiragana)
  seed('座机', 'cat_communication_landline'), // zh — landline
  seed('固定电话', 'cat_communication_landline'), // zh — fixed-line phone
  seed('固定電話', 'cat_communication_landline'), // ja — landline (Han)
  seed('こていでんわ', 'cat_communication_landline'), // ja — landline (hiragana)
  seed('网费', 'cat_communication_internet'), // zh — internet fee
  seed('宽带', 'cat_communication_internet'), // zh — broadband
  seed('ネット代', 'cat_communication_internet'), // ja — internet fee (mixed)
  seed('プロバイダ', 'cat_communication_internet'), // ja — provider
  seed('有线电视', 'cat_communication_broadcast'), // zh — cable TV
  seed('卫星电视', 'cat_communication_broadcast'), // zh — satellite TV
  seed('放送', 'cat_communication_broadcast'), // ja — broadcast (Han)
  seed('ほうそう', 'cat_communication_broadcast'), // ja — broadcast (hiragana)
  seed('快递', 'cat_communication_delivery'), // zh — courier / delivery
  seed('快递费', 'cat_communication_delivery'), // zh — shipping fee
  seed('宅配', 'cat_communication_delivery'), // ja — home delivery (Han)
  seed('たくはい', 'cat_communication_delivery'), // ja — delivery (hiragana)
  seed('NHK受信料', 'cat_communication_nhk'), // zh/ja — NHK fee (mixed)
  seed('电视台费', 'cat_communication_nhk'), // zh — broadcaster fee
  seed('受信料', 'cat_communication_nhk'), // ja — reception fee (Han)
  seed('じゅしんりょう', 'cat_communication_nhk'), // ja — reception fee (hiragana)
  seed('邮费', 'cat_communication_postage'), // zh — postage
  seed('邮寄', 'cat_communication_postage'), // zh — mailing
  seed('郵便', 'cat_communication_postage'), // ja — mail (Han)
  seed('ゆうびん', 'cat_communication_postage'), // ja — postal (hiragana)
  seed('其他通讯', 'cat_communication_other'), // zh — other communication
  seed('その他通信', 'cat_communication_other'), // ja — other communication (kana)
  // ===== Car & Motorcycle — direct coverage =====
  seed('加油', 'cat_car_fuel'), // zh — refuel (SC4 fuel gap)
  seed('给油', 'cat_car_fuel'), // zh-variant — refuel (SC4 fuel gap)
  seed('給油', 'cat_car_fuel'), // ja — refuel (Han) (SC4 fuel gap)
  seed('ガソリン', 'cat_car_fuel'), // ja — gasoline (SC4 fuel gap)
  seed('停车费', 'cat_car_parking'), // zh — parking fee
  seed('停车', 'cat_car_parking'), // zh — parking
  seed('駐車場', 'cat_car_parking'), // ja — parking lot (Han)
  seed('ちゅうしゃ', 'cat_car_parking'), // ja — parking (hiragana)
  seed('过路费', 'cat_car_toll'), // zh — toll
  seed('高速费', 'cat_car_toll'), // zh — highway toll
  seed('高速代', 'cat_car_toll'), // ja — expressway toll (Han)
  seed('こうそくだい', 'cat_car_toll'), // ja — expressway toll (hiragana)
  seed('车贷', 'cat_car_loan'), // zh — car loan
  seed('购车贷款', 'cat_car_loan'), // zh — auto loan
  seed('車のローン', 'cat_car_loan'), // ja — car loan (katakana ローン)
  seed('カーローン', 'cat_car_loan'), // ja — car loan (katakana, D2 refinement)
  seed('车辆保养', 'cat_car_maintenance'), // zh — car maintenance
  seed('修车', 'cat_car_maintenance'), // zh — car repair
  seed('車検', 'cat_car_maintenance'), // ja — vehicle inspection (Han)
  seed('せいび', 'cat_car_maintenance'), // ja — maintenance (hiragana)
  seed('共享汽车', 'cat_car_car_share'), // zh — car share
  seed('租车', 'cat_car_car_share'), // zh — car rental
  seed('カーシェア', 'cat_car_car_share'), // ja — car share
  seed('レンタカー', 'cat_car_car_share'), // ja — rental car
  seed('驾校', 'cat_car_driving_school'), // zh — driving school
  seed('考驾照', 'cat_car_driving_school'), // zh — getting a license
  seed('教習所', 'cat_car_driving_school'), // ja — driving school (Han)
  seed('きょうしゅうじょ', 'cat_car_driving_school'), // ja — driving school (hiragana)
  seed('车险', 'cat_car_insurance'), // zh — car insurance
  seed('じどうしゃほけん', 'cat_car_insurance'), // ja — auto insurance (hiragana reading; 自動車保険 is Han)
  seed('汽车税', 'cat_car_tax'), // zh — automobile tax
  seed('じどうしゃぜい', 'cat_car_tax'), // ja — automobile tax (hiragana reading; 自動車税 is Han)
  seed('其他车辆', 'cat_car_other'), // zh — other car expense
  seed('その他車両', 'cat_car_other'), // ja — other car (kana その他)
  // ===== Housing / Utilities / Communication / Car (en) — VEN-01 / D-12 =====
  seed('rent', 'cat_housing_rent'), // en — rent
  seed('water bill', 'cat_utilities_water'), // en — water bill
  seed('electricity', 'cat_utilities_electricity'), // en — electricity bill
  seed('gas bill', 'cat_utilities_gas'), // en — gas bill
  seed('kerosene', 'cat_utilities_kerosene'), // en — kerosene
  seed('other utilities', 'cat_utilities_other'), // en — other utilities
  seed('mortgage', 'cat_housing_mortgage'), // en — mortgage
  seed('management fee', 'cat_housing_management'), // en — property management fee
  seed('furniture', 'cat_housing_furniture'), // en — furniture
  seed('appliances', 'cat_housing_appliances'), // en — home appliances
  seed('renovation', 'cat_housing_renovation'), // en — renovation
  seed('moving cost', 'cat_housing_utilities_setup'), // en — moving setup cost
  seed('home insurance', 'cat_housing_insurance'), // en — home insurance
  seed('property tax', 'cat_housing_property_tax'), // en — property tax
  seed('other housing', 'cat_housing_other'), // en — other housing
  seed('mobile phone', 'cat_communication_mobile'), // en — mobile phone bill
  seed('landline', 'cat_communication_landline'), // en — landline
  seed('internet', 'cat_communication_internet'), // en — internet fee
  seed('cable tv', 'cat_communication_broadcast'), // en — cable/satellite TV
  seed('courier', 'cat_communication_delivery'), // en — courier / shipping
  seed('nhk fee', 'cat_communication_nhk'), // en — NHK / broadcaster fee
  seed('postage', 'cat_communication_postage'), // en — postage
  seed('other communication', 'cat_communication_other'), // en — other comms
  seed('fuel', 'cat_car_fuel'), // en — fuel / gasoline
  seed('parking', 'cat_car_parking'), // en — parking
  seed('toll', 'cat_car_toll'), // en — toll
  seed('car loan', 'cat_car_loan'), // en — car loan
  seed('car maintenance', 'cat_car_maintenance'), // en — car maintenance
  seed('car share', 'cat_car_car_share'), // en — car share / rental
  seed('driving school', 'cat_car_driving_school'), // en — driving school
  seed('car insurance', 'cat_car_insurance'), // en — car insurance
  seed('car tax', 'cat_car_tax'), // en — automobile tax
  seed('other car', 'cat_car_other'), // en — other car expense
];
