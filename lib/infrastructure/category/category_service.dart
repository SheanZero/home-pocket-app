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
    'category_hobbies_books': '本',
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
    'category_social_ceremonial': '冠婚葬祭',
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
    'category_hobbies_books': '图书',
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
    'category_social_ceremonial': '红白喜丧',
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
    'category_hobbies_games': 'Music, Games & Manga',
    'category_hobbies_books': 'Books',
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
  };
}
