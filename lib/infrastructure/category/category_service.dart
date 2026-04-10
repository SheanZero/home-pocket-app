import 'dart:ui';

/// Resolves system category localization keys to display names.
///
/// System categories store keys like `category_food` in their `name` field.
/// This service maps those keys to locale-appropriate display names using
/// static maps (Flutter's generated `S` class doesn't support dynamic key
/// lookup). Custom (non-system) category names pass through unchanged.
///
/// Translations sourced from BASIC-004 PRD §10.
abstract final class CategoryService {
  /// Converts a system category ID (e.g. `cat_food`) to its name key
  /// (e.g. `category_food`) and resolves the localized display name.
  ///
  /// Useful when only the category ID is available (e.g. from Transaction).
  static String resolveFromId(String categoryId, Locale locale) {
    if (categoryId.startsWith('cat_')) {
      final nameKey = 'category_${categoryId.substring(4)}';
      return resolve(nameKey, locale);
    }
    return categoryId;
  }

  /// Returns the localized display name for [nameKey].
  ///
  /// If [nameKey] is not found in the map (e.g. a user-created category),
  /// returns [nameKey] unchanged.
  static String resolve(String nameKey, Locale locale) {
    final map = switch (locale.languageCode) {
      'ja' => _ja,
      'zh' => _zh,
      _ => _en,
    };
    return map[nameKey] ?? nameKey;
  }

  // ─── Japanese ───

  static const _ja = <String, String>{
    // L1 Expense
    'category_food': '食費',
    'category_daily': '日用品',
    'category_transport': '交通費',
    'category_hobbies': '趣味・娯楽',
    'category_clothing': '衣服・美容',
    'category_social': '交際費',
    'category_health': '健康・医療',
    'category_education': '教育・教養',
    'category_cash_card': '現金・カード',
    'category_utilities': '水道・光熱費',
    'category_communication': '通信費',
    'category_housing': '住宅',
    'category_car': '車・バイク',
    'category_tax': '税・社会保障',
    'category_insurance': '保険',
    'category_special': '特別な支出',
    'category_asset': '資産形成',
    'category_other_expense': 'その他',
    'category_uncategorized': '未分類',

    // L1 Income
    'category_salary': '給料',
    'category_bonus': '賞与',
    'category_investment': '投資収益',
    'category_other_income': 'その他収入',

    // L2 Food (§10.16)
    'category_food_general': '食費',
    'category_food_groceries': '食料品',
    'category_food_dining_out': '外食',
    'category_food_breakfast': '朝ご飯',
    'category_food_lunch': '昼ご飯',
    'category_food_dinner': '夜ご飯',
    'category_food_cafe': 'カフェ',
    'category_food_other': 'その他食費',

    // L2 Daily Necessities (§10.15)
    'category_daily_general': '日用品',
    'category_daily_household': '生活雑貨',
    'category_daily_children': '子ども関連',
    'category_daily_pets': 'ペット関連',
    'category_daily_tobacco': 'タバコ',
    'category_daily_other': 'その他日用品',

    // L2 Transport (§10.1)
    'category_transport_general': '交通費',
    'category_transport_train': '電車',
    'category_transport_bus': 'バス',
    'category_transport_taxi': 'タクシー',
    'category_transport_flights': '飛行機',
    'category_transport_other': 'その他交通',

    // L2 Hobbies & Entertainment (§10.12)
    'category_hobbies_leisure': 'レジャー・スポーツ',
    'category_hobbies_events': 'イベント',
    'category_hobbies_movies': '映画・動画',
    'category_hobbies_games': '音楽・ゲーム・漫画',
    'category_hobbies_books': '本・漫画',
    'category_hobbies_travel': '旅行',
    'category_hobbies_other': 'その他趣味・娯楽',

    // L2 Clothing & Beauty (§10.10)
    'category_clothing_clothes': '衣服',
    'category_clothing_accessories': 'アクセサリー・小物',
    'category_clothing_underwear': '下着',
    'category_clothing_hair': '美容院、理髪',
    'category_clothing_cosmetics': '化粧品',
    'category_clothing_esthetic': 'エステ・ネイル',
    'category_clothing_cleaning': 'クリーニング',
    'category_clothing_other': 'その他衣服・美容',

    // L2 Socializing (§10.7)
    'category_social_general': '交際費',
    'category_social_drinks': '飲み会',
    'category_social_gifts': 'プレゼント',
    'category_social_ceremonial': '冠婚葬祭・ご祝儀・香典',
    'category_social_other': 'その他交際費',

    // L2 Health & Medical (§10.5)
    'category_health_fitness': 'フィットネス',
    'category_health_massage': 'マッサージ・整体',
    'category_health_hospital': '病院',
    'category_health_medicine': '薬代',
    'category_health_other': 'その他健康・医療',

    // L2 Education & Self-Improvement (§10.6)
    'category_education_books': '書籍',
    'category_education_newspapers': '新聞・雑誌',
    'category_education_classes': '習いごと',
    'category_education_textbooks': '教科書・参考書',
    'category_education_tuition': '学費',
    'category_education_cram_school': '塾',
    'category_education_other': 'その他教育・教養',

    // L2 Utilities (§10.4)
    'category_utilities_general': '光熱費',
    'category_utilities_electricity': '電気代',
    'category_utilities_water': '水道代',
    'category_utilities_gas': 'ガス・灯油代',
    'category_utilities_other': 'その他水道・光熱費',

    // L2 Communication (§10.13)
    'category_communication_mobile': '携帯電話',
    'category_communication_landline': '固定電話',
    'category_communication_internet': 'インターネット',
    'category_communication_broadcast': '放送視聴料',
    'category_communication_info': '情報サービス',
    'category_communication_delivery': '宅配便・運送',
    'category_communication_other': 'その他通信費',

    // L2 Housing (§10.14)
    'category_housing_rent': '家賃',
    'category_housing_mortgage': '住宅ローン',
    'category_housing_management': '管理費・積立金',
    'category_housing_furniture': '家具',
    'category_housing_appliances': '家電',
    'category_housing_renovation': 'リフォーム',
    'category_housing_insurance': '地震・火災保険',
    'category_housing_other': 'その他住宅',

    // L2 Car & Motorcycle (§10.9)
    'category_car_fuel': 'ガソリン',
    'category_car_parking': '駐車場',
    'category_car_toll': '道路料金',
    'category_car_loan': '自動車ローン',
    'category_car_insurance': '自動車保険',
    'category_car_tax': '自動車税',
    'category_car_maintenance': '車検・整備',
    'category_car_other': 'その他車・バイク',

    // L2 Taxes & Social Security (§10.3)
    'category_tax_income': '所得税・住民税',
    'category_tax_pension': '年金',
    'category_tax_health_insurance': '健康保険',
    'category_tax_other': 'その他税・社会保障',

    // L2 Insurance (§10.2)
    'category_insurance_general': '保険',
    'category_insurance_life': '生命保険',
    'category_insurance_medical': '医療保険',
    'category_insurance_other': 'その他保険',

    // L2 Special Expenses (§10.8)
    'category_special_general': '特別な支出',
    'category_special_furniture': '家具・家電',
    'category_special_housing': '住宅・リフォーム',
    'category_special_wedding': '結婚',
    'category_special_fertility': '妊活・出産',
    'category_special_nursing': '介護',
    'category_special_other': 'その他特別な出費',

    // L2 Other (§10.11)
    'category_other_advances': '立替金',
    'category_other_remittance': '仕送り',
    'category_other_allowance': 'おこづかい',
    'category_other_business': '事業費',
    'category_other_debt': '返済',
    'category_other_misc': '雑費',
    'category_other_unclassified': '使途不明金',
    'category_other_other': 'その他',

    // L1 New categories (v2)
    'category_pet': 'ペット',
    'category_allowance': 'お小遣い',

    // L2 Food (v2 additions)
    'category_food_delivery': 'デリバリー',
    'category_food_drinks': '飲料・酒類',

    // L2 Daily (v2 additions)
    'category_daily_drugstore': 'ドラッグストア',
    'category_daily_subscription': 'サブスク雑貨',

    // L2 Transport (v2 additions)
    'category_transport_shinkansen': '新幹線',
    'category_transport_highway_bus': '高速バス',

    // L2 Hobbies (v2 additions)
    'category_hobbies_music': '音楽',
    'category_hobbies_subscription': 'エンタメサブスク',
    'category_hobbies_oshikatsu': '推し活・グッズ',

    // L2 Clothing (v2 additions)
    'category_clothing_shoes': '靴・履物',
    'category_clothing_bags': 'カバン',

    // L2 Social (v2 additions)
    'category_social_fees': '会費・組合費',

    // L2 Health (v2 additions)
    'category_health_dental': '歯科',
    'category_health_supplements': 'サプリメント',
    'category_health_dock': '人間ドック',

    // L2 Education (v2 additions)
    'category_education_entrance_exam': '受験料',
    'category_education_gakushi_hoken': '学資保険',
    'category_education_seminar': 'セミナー・講座',

    // L2 Utilities (v2 additions)
    'category_utilities_kerosene': '灯油',

    // L2 Communication (v2 additions)
    'category_communication_nhk': 'NHK受信料',
    'category_communication_postage': '切手・はがき',

    // L2 Housing (v2 additions)
    'category_housing_property_tax': '固定資産税',
    'category_housing_utilities_setup': '引越し・初期設備',

    // L2 Car (v2 additions)
    'category_car_car_share': 'カーシェア',
    'category_car_driving_school': '免許教習',

    // L2 Tax (v2 additions)
    'category_tax_furusato': 'ふるさと納税',
    'category_tax_consumption': '消費税',
    'category_tax_nursing_insurance': '介護保険',

    // L2 Insurance (v2 additions)
    'category_insurance_cancer': 'がん保険',
    'category_insurance_income': '所得補償保険',

    // L2 Special (v2 additions)
    'category_special_funeral': '葬儀',
    'category_special_life_event': '成人式・七五三・入学式',
    'category_special_newyear': '初詣・お年玉・年末年始',
    'category_special_movement': '引越し',

    // L2 Allowance (all new)
    'category_allowance_self': '本人お小遣い',
    'category_allowance_spouse': '配偶者お小遣い',
    'category_allowance_kids': '子どもお小遣い',
    'category_allowance_other': 'その他お小遣い',

    // L2 Asset (all new)
    'category_asset_nisa': 'NISA',
    'category_asset_ideco': 'iDeCo',
    'category_asset_tsumitate': '積立投資',
    'category_asset_savings': '貯蓄・定期預金',
    'category_asset_stock': '株・投資信託',
    'category_asset_fx': '外貨預金',
    'category_asset_realestate': '不動産投資',
    'category_asset_other': 'その他資産形成',

    // L2 Pet (all new)
    'category_pet_food': 'ペットフード',
    'category_pet_supplies': 'ペット用品・おもちゃ',
    'category_pet_medical': '病院・医療費',
    'category_pet_grooming': 'トリミング',
    'category_pet_insurance': 'ペット保険',
    'category_pet_hotel': 'ペットホテル・預かり',
    'category_pet_other': 'その他ペット',
  };

  // ─── Chinese ───

  static const _zh = <String, String>{
    // L1 Expense
    'category_food': '食费',
    'category_daily': '日用品',
    'category_transport': '交通费',
    'category_hobbies': '兴趣娱乐',
    'category_clothing': '衣服美容',
    'category_social': '交际费',
    'category_health': '健康医疗',
    'category_education': '教育进修',
    'category_cash_card': '现金与刷卡',
    'category_utilities': '水电燃气',
    'category_communication': '通讯费',
    'category_housing': '住宅',
    'category_car': '车与摩托',
    'category_tax': '税费与社会保障',
    'category_insurance': '保险',
    'category_special': '特别支出',
    'category_asset': '资产配置',
    'category_other_expense': '其他',
    'category_uncategorized': '未分类',

    // L1 Income
    'category_salary': '工资',
    'category_bonus': '奖金',
    'category_investment': '投资收益',
    'category_other_income': '其他收入',

    // L2 Food (§10.16)
    'category_food_general': '食费',
    'category_food_groceries': '食材杂货',
    'category_food_dining_out': '外出就餐',
    'category_food_breakfast': '早餐',
    'category_food_lunch': '午餐',
    'category_food_dinner': '晚餐',
    'category_food_cafe': '咖啡馆',
    'category_food_other': '其他食费',

    // L2 Daily Necessities (§10.15)
    'category_daily_general': '日用品',
    'category_daily_household': '生活杂货',
    'category_daily_children': '儿童相关',
    'category_daily_pets': '宠物相关',
    'category_daily_tobacco': '烟草',
    'category_daily_other': '其他日用品',

    // L2 Transport (§10.1)
    'category_transport_general': '交通费',
    'category_transport_train': '电车',
    'category_transport_bus': '公交',
    'category_transport_taxi': '出租车',
    'category_transport_flights': '飞机',
    'category_transport_other': '其他交通',

    // L2 Hobbies & Entertainment (§10.12)
    'category_hobbies_leisure': '休闲运动',
    'category_hobbies_events': '活动',
    'category_hobbies_movies': '电影/视频',
    'category_hobbies_games': '音乐/游戏/漫画',
    'category_hobbies_books': '书籍漫画',
    'category_hobbies_travel': '旅行',
    'category_hobbies_other': '其他兴趣娱乐',

    // L2 Clothing & Beauty (§10.10)
    'category_clothing_clothes': '衣服',
    'category_clothing_accessories': '饰品/小物',
    'category_clothing_underwear': '内衣',
    'category_clothing_hair': '美发/理发',
    'category_clothing_cosmetics': '化妆品',
    'category_clothing_esthetic': '美容护理/美甲',
    'category_clothing_cleaning': '清洗护理',
    'category_clothing_other': '其他衣服美容',

    // L2 Socializing (§10.7)
    'category_social_general': '交际费',
    'category_social_drinks': '聚会饮酒',
    'category_social_gifts': '礼物',
    'category_social_ceremonial': '红白喜丧/礼金',
    'category_social_other': '其他交际费',

    // L2 Health & Medical (§10.5)
    'category_health_fitness': '健身',
    'category_health_massage': '按摩/整骨',
    'category_health_hospital': '医院',
    'category_health_medicine': '药费',
    'category_health_other': '其他健康医疗',

    // L2 Education & Self-Improvement (§10.6)
    'category_education_books': '书籍',
    'category_education_newspapers': '报刊杂志',
    'category_education_classes': '兴趣课程',
    'category_education_textbooks': '教材/参考书',
    'category_education_tuition': '学费',
    'category_education_cram_school': '补习班',
    'category_education_other': '其他教育进修',

    // L2 Utilities (§10.4)
    'category_utilities_general': '水电燃气费',
    'category_utilities_electricity': '电费',
    'category_utilities_water': '水费',
    'category_utilities_gas': '燃气/煤油费',
    'category_utilities_other': '其他水电燃气',

    // L2 Communication (§10.13)
    'category_communication_mobile': '手机通信',
    'category_communication_landline': '固话',
    'category_communication_internet': '网络',
    'category_communication_broadcast': '视听费',
    'category_communication_info': '信息服务',
    'category_communication_delivery': '快递/运输',
    'category_communication_other': '其他通讯费',

    // L2 Housing (§10.14)
    'category_housing_rent': '房租',
    'category_housing_mortgage': '房贷',
    'category_housing_management': '物业/公积管理费',
    'category_housing_furniture': '家具',
    'category_housing_appliances': '家电',
    'category_housing_renovation': '装修',
    'category_housing_insurance': '地震/火灾保险',
    'category_housing_other': '其他住宅',

    // L2 Car & Motorcycle (§10.9)
    'category_car_fuel': '油费',
    'category_car_parking': '停车费',
    'category_car_toll': '过路费',
    'category_car_loan': '车贷',
    'category_car_insurance': '车险',
    'category_car_tax': '车船税',
    'category_car_maintenance': '年检/保养',
    'category_car_other': '其他车与摩托',

    // L2 Taxes & Social Security (§10.3)
    'category_tax_income': '所得税与居民税',
    'category_tax_pension': '年金',
    'category_tax_health_insurance': '健康保险',
    'category_tax_other': '其他税费与社会保障',

    // L2 Insurance (§10.2)
    'category_insurance_general': '保险',
    'category_insurance_life': '人寿保险',
    'category_insurance_medical': '医疗保险',
    'category_insurance_other': '其他保险',

    // L2 Special Expenses (§10.8)
    'category_special_general': '特别支出',
    'category_special_furniture': '家具家电',
    'category_special_housing': '住宅/装修',
    'category_special_wedding': '结婚',
    'category_special_fertility': '备孕与生产',
    'category_special_nursing': '护理',
    'category_special_other': '其他特别支出',

    // L2 Other (§10.11)
    'category_other_advances': '垫付款',
    'category_other_remittance': '汇款/赡养',
    'category_other_allowance': '零花钱',
    'category_other_business': '经营费用',
    'category_other_debt': '还款',
    'category_other_misc': '杂费',
    'category_other_unclassified': '去向不明款',
    'category_other_other': '其他',

    // L1 New categories (v2)
    'category_pet': '宠物',
    'category_allowance': '零花钱',

    // L2 Food (v2 additions)
    'category_food_delivery': '外卖',
    'category_food_drinks': '饮料酒类',

    // L2 Daily (v2 additions)
    'category_daily_drugstore': '药妆店',
    'category_daily_subscription': '日用品订阅',

    // L2 Transport (v2 additions)
    'category_transport_shinkansen': '新干线',
    'category_transport_highway_bus': '高速巴士',

    // L2 Hobbies (v2 additions)
    'category_hobbies_music': '音乐',
    'category_hobbies_subscription': '娱乐订阅',
    'category_hobbies_oshikatsu': '粉丝活动/周边',

    // L2 Clothing (v2 additions)
    'category_clothing_shoes': '鞋履',
    'category_clothing_bags': '包袋',

    // L2 Social (v2 additions)
    'category_social_fees': '会费/组合费',

    // L2 Health (v2 additions)
    'category_health_dental': '牙科',
    'category_health_supplements': '保健品',
    'category_health_dock': '体检',

    // L2 Education (v2 additions)
    'category_education_entrance_exam': '考试费',
    'category_education_gakushi_hoken': '学资保险',
    'category_education_seminar': '研讨会讲座',

    // L2 Utilities (v2 additions)
    'category_utilities_kerosene': '煤油',

    // L2 Communication (v2 additions)
    'category_communication_nhk': 'NHK 收视费',
    'category_communication_postage': '邮票明信片',

    // L2 Housing (v2 additions)
    'category_housing_property_tax': '固定资产税',
    'category_housing_utilities_setup': '搬家初期设置',

    // L2 Car (v2 additions)
    'category_car_car_share': '共享汽车',
    'category_car_driving_school': '驾校',

    // L2 Tax (v2 additions)
    'category_tax_furusato': '故乡税',
    'category_tax_consumption': '消费税',
    'category_tax_nursing_insurance': '介护保险',

    // L2 Insurance (v2 additions)
    'category_insurance_cancer': '癌症保险',
    'category_insurance_income': '所得补偿保险',

    // L2 Special (v2 additions)
    'category_special_funeral': '葬礼',
    'category_special_life_event': '成人礼/七五三/入学式',
    'category_special_newyear': '新年参拜/压岁钱',
    'category_special_movement': '搬家',

    // L2 Allowance (all new)
    'category_allowance_self': '本人零花钱',
    'category_allowance_spouse': '配偶零花钱',
    'category_allowance_kids': '儿童零花钱',
    'category_allowance_other': '其他零花钱',

    // L2 Asset (all new)
    'category_asset_nisa': 'NISA 账户',
    'category_asset_ideco': 'iDeCo 年金',
    'category_asset_tsumitate': '定期投资',
    'category_asset_savings': '储蓄定期',
    'category_asset_stock': '股票信托',
    'category_asset_fx': '外汇存款',
    'category_asset_realestate': '不动产投资',
    'category_asset_other': '其他资产配置',

    // L2 Pet (all new)
    'category_pet_food': '宠物食品',
    'category_pet_supplies': '宠物用品/玩具',
    'category_pet_medical': '宠物医疗',
    'category_pet_grooming': '美容护理',
    'category_pet_insurance': '宠物保险',
    'category_pet_hotel': '宠物寄养',
    'category_pet_other': '其他宠物',
  };

  // ─── English ───

  static const _en = <String, String>{
    // L1 Expense
    'category_food': 'Food',
    'category_daily': 'Daily Necessities',
    'category_transport': 'Transport',
    'category_hobbies': 'Hobbies & Entertainment',
    'category_clothing': 'Clothing & Beauty',
    'category_social': 'Socializing',
    'category_health': 'Health & Medical',
    'category_education': 'Education',
    'category_cash_card': 'Cash & Card',
    'category_utilities': 'Utilities',
    'category_communication': 'Communication',
    'category_housing': 'Housing',
    'category_car': 'Car & Motorcycle',
    'category_tax': 'Taxes & Social Security',
    'category_insurance': 'Insurance',
    'category_special': 'Special Expenses',
    'category_asset': 'Asset Building',
    'category_other_expense': 'Other',
    'category_uncategorized': 'Uncategorized',

    // L1 Income
    'category_salary': 'Salary',
    'category_bonus': 'Bonus',
    'category_investment': 'Investment Returns',
    'category_other_income': 'Other Income',

    // L2 Food (§10.16)
    'category_food_general': 'Food',
    'category_food_groceries': 'Groceries',
    'category_food_dining_out': 'Dining Out',
    'category_food_breakfast': 'Breakfast',
    'category_food_lunch': 'Lunch',
    'category_food_dinner': 'Dinner',
    'category_food_cafe': 'Cafe',
    'category_food_other': 'Other Food',

    // L2 Daily Necessities (§10.15)
    'category_daily_general': 'Daily Necessities',
    'category_daily_household': 'Household Goods',
    'category_daily_children': 'Child-related',
    'category_daily_pets': 'Pet-related',
    'category_daily_tobacco': 'Tobacco',
    'category_daily_other': 'Other Daily Necessities',

    // L2 Transport (§10.1)
    'category_transport_general': 'Transport',
    'category_transport_train': 'Train',
    'category_transport_bus': 'Bus',
    'category_transport_taxi': 'Taxi',
    'category_transport_flights': 'Flights',
    'category_transport_other': 'Other Transport',

    // L2 Hobbies & Entertainment (§10.12)
    'category_hobbies_leisure': 'Leisure & Sports',
    'category_hobbies_events': 'Events',
    'category_hobbies_movies': 'Movies & Videos',
    'category_hobbies_games': 'Games',
    'category_hobbies_books': 'Books & Manga',
    'category_hobbies_travel': 'Travel',
    'category_hobbies_other': 'Other Hobbies & Entertainment',

    // L2 Clothing & Beauty (§10.10)
    'category_clothing_clothes': 'Clothing',
    'category_clothing_accessories': 'Accessories & Small Items',
    'category_clothing_underwear': 'Underwear',
    'category_clothing_hair': 'Hair Salon & Barber',
    'category_clothing_cosmetics': 'Cosmetics',
    'category_clothing_esthetic': 'Esthetic & Nails',
    'category_clothing_cleaning': 'Dry Cleaning',
    'category_clothing_other': 'Other Clothing & Beauty',

    // L2 Socializing (§10.7)
    'category_social_general': 'Socializing',
    'category_social_drinks': 'Drinks & Gatherings',
    'category_social_gifts': 'Gifts',
    'category_social_ceremonial': 'Ceremonial Occasions',
    'category_social_other': 'Other Socializing',

    // L2 Health & Medical (§10.5)
    'category_health_fitness': 'Fitness',
    'category_health_massage': 'Massage & Chiropractic',
    'category_health_hospital': 'Hospital',
    'category_health_medicine': 'Medicine',
    'category_health_other': 'Other Health & Medical',

    // L2 Education & Self-Improvement (§10.6)
    'category_education_books': 'Books',
    'category_education_newspapers': 'Newspapers & Magazines',
    'category_education_classes': 'Classes',
    'category_education_textbooks': 'Textbooks & Reference Books',
    'category_education_tuition': 'Tuition',
    'category_education_cram_school': 'Cram School',
    'category_education_other': 'Other Education',

    // L2 Utilities (§10.4)
    'category_utilities_general': 'Utilities',
    'category_utilities_electricity': 'Electricity',
    'category_utilities_water': 'Water',
    'category_utilities_gas': 'Gas & Kerosene',
    'category_utilities_other': 'Other Utilities',

    // L2 Communication (§10.13)
    'category_communication_mobile': 'Mobile Phone',
    'category_communication_landline': 'Landline',
    'category_communication_internet': 'Internet',
    'category_communication_broadcast': 'Broadcasting Subscription',
    'category_communication_info': 'Information Services',
    'category_communication_delivery': 'Delivery & Shipping',
    'category_communication_other': 'Other Communication',

    // L2 Housing (§10.14)
    'category_housing_rent': 'Rent',
    'category_housing_mortgage': 'Mortgage',
    'category_housing_management': 'Management Fees & Reserve Fund',
    'category_housing_furniture': 'Furniture',
    'category_housing_appliances': 'Home Appliances',
    'category_housing_renovation': 'Renovation',
    'category_housing_insurance': 'Earthquake & Fire Insurance',
    'category_housing_other': 'Other Housing',

    // L2 Car & Motorcycle (§10.9)
    'category_car_fuel': 'Fuel',
    'category_car_parking': 'Parking',
    'category_car_toll': 'Toll Fees',
    'category_car_loan': 'Auto Loan',
    'category_car_insurance': 'Auto Insurance',
    'category_car_tax': 'Vehicle Tax',
    'category_car_maintenance': 'Inspection & Maintenance',
    'category_car_other': 'Other Car & Motorcycle',

    // L2 Taxes & Social Security (§10.3)
    'category_tax_income': 'Income Tax & Resident Tax',
    'category_tax_pension': 'Pension',
    'category_tax_health_insurance': 'Health Insurance',
    'category_tax_other': 'Other Taxes & Social Security',

    // L2 Insurance (§10.2)
    'category_insurance_general': 'Insurance',
    'category_insurance_life': 'Life Insurance',
    'category_insurance_medical': 'Medical Insurance',
    'category_insurance_other': 'Other Insurance',

    // L2 Special Expenses (§10.8)
    'category_special_general': 'Special Expenses',
    'category_special_furniture': 'Furniture & Appliances',
    'category_special_housing': 'Housing & Renovation',
    'category_special_wedding': 'Wedding',
    'category_special_fertility': 'Fertility & Childbirth',
    'category_special_nursing': 'Nursing Care',
    'category_special_other': 'Other Special Expenses',

    // L2 Other (§10.11)
    'category_other_advances': 'Advances',
    'category_other_remittance': 'Remittance',
    'category_other_allowance': 'Allowance',
    'category_other_business': 'Business Expenses',
    'category_other_debt': 'Debt Repayment',
    'category_other_misc': 'Miscellaneous',
    'category_other_unclassified': 'Unclassified Spending',
    'category_other_other': 'Other',

    // L1 New categories (v2)
    'category_pet': 'Pets',
    'category_allowance': 'Allowance',

    // L2 Food (v2 additions)
    'category_food_delivery': 'Delivery',
    'category_food_drinks': 'Drinks & Alcohol',

    // L2 Daily (v2 additions)
    'category_daily_drugstore': 'Drugstore',
    'category_daily_subscription': 'Daily Subscriptions',

    // L2 Transport (v2 additions)
    'category_transport_shinkansen': 'Shinkansen',
    'category_transport_highway_bus': 'Highway Bus',

    // L2 Hobbies (v2 additions)
    'category_hobbies_music': 'Music',
    'category_hobbies_subscription': 'Entertainment Subs',
    'category_hobbies_oshikatsu': 'Fan Activities & Goods',

    // L2 Clothing (v2 additions)
    'category_clothing_shoes': 'Shoes & Footwear',
    'category_clothing_bags': 'Bags',

    // L2 Social (v2 additions)
    'category_social_fees': 'Membership Fees',

    // L2 Health (v2 additions)
    'category_health_dental': 'Dental',
    'category_health_supplements': 'Supplements',
    'category_health_dock': 'Health Check-up',

    // L2 Education (v2 additions)
    'category_education_entrance_exam': 'Entrance Exam Fees',
    'category_education_gakushi_hoken': 'Education Insurance',
    'category_education_seminar': 'Seminars & Workshops',

    // L2 Utilities (v2 additions)
    'category_utilities_kerosene': 'Kerosene',

    // L2 Communication (v2 additions)
    'category_communication_nhk': 'NHK Reception Fee',
    'category_communication_postage': 'Postage & Stamps',

    // L2 Housing (v2 additions)
    'category_housing_property_tax': 'Property Tax',
    'category_housing_utilities_setup': 'Moving & Initial Setup',

    // L2 Car (v2 additions)
    'category_car_car_share': 'Car Share',
    'category_car_driving_school': 'Driving School',

    // L2 Tax (v2 additions)
    'category_tax_furusato': 'Furusato Nozei',
    'category_tax_consumption': 'Consumption Tax',
    'category_tax_nursing_insurance': 'Long-term Care Insurance',

    // L2 Insurance (v2 additions)
    'category_insurance_cancer': 'Cancer Insurance',
    'category_insurance_income': 'Income Protection',

    // L2 Special (v2 additions)
    'category_special_funeral': 'Funeral',
    'category_special_life_event': 'Life Events',
    'category_special_newyear': 'New Year Traditions',
    'category_special_movement': 'Moving',

    // L2 Allowance (all new)
    'category_allowance_self': 'Self Allowance',
    'category_allowance_spouse': 'Spouse Allowance',
    'category_allowance_kids': 'Kids Allowance',
    'category_allowance_other': 'Other Allowance',

    // L2 Asset (all new)
    'category_asset_nisa': 'NISA',
    'category_asset_ideco': 'iDeCo',
    'category_asset_tsumitate': 'Regular Investment',
    'category_asset_savings': 'Savings & Deposits',
    'category_asset_stock': 'Stocks & Funds',
    'category_asset_fx': 'Foreign Currency',
    'category_asset_realestate': 'Real Estate Investment',
    'category_asset_other': 'Other Asset Building',

    // L2 Pet (all new)
    'category_pet_food': 'Pet Food',
    'category_pet_supplies': 'Supplies & Toys',
    'category_pet_medical': 'Vet & Medical',
    'category_pet_grooming': 'Grooming & Salon',
    'category_pet_insurance': 'Pet Insurance',
    'category_pet_hotel': 'Boarding & Pet Sitter',
    'category_pet_other': 'Other Pet Expenses',
  };
}
