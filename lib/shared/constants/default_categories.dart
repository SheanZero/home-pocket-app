import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/category_ledger_config.dart';
import '../../features/accounting/domain/models/transaction.dart';

/// System default categories per PRD BASIC-004 \u00a710.
abstract final class DefaultCategories {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  static List<Category> get all => [
        ...expenseL1,
        ..._expenseL2,
        ...incomeL1,
      ];

  static List<Category> get expenseL1 => _expenseL1;
  static List<Category> get incomeL1 => _incomeL1;
  static List<CategoryLedgerConfig> get defaultLedgerConfigs =>
      _defaultLedgerConfigs;

  // ─── Expense L1 (PRD \u00a710.0 sort order) ───

  static final List<Category> _expenseL1 = [
    _l1('cat_food', 'category_food', 'restaurant', '#FF5722', 1),
    _l1('cat_daily', 'category_daily', 'local_mall', '#00BCD4', 2),
    _l1('cat_transport', 'category_transport', 'directions_bus', '#2196F3', 3),
    _l1('cat_hobbies', 'category_hobbies', 'sports_esports', '#9C27B0', 4),
    _l1('cat_clothing', 'category_clothing', 'checkroom', '#E91E63', 5),
    _l1('cat_social', 'category_social', 'people', '#FF9800', 6),
    _l1('cat_health', 'category_health', 'local_hospital', '#F44336', 7),
    _l1('cat_education', 'category_education', 'school', '#3F51B5', 8),
    _l1('cat_cash_card', 'category_cash_card', 'credit_card', '#546E7A', 9),
    _l1('cat_utilities', 'category_utilities', 'flash_on', '#FFC107', 10),
    _l1('cat_communication', 'category_communication', 'phone_iphone', '#00ACC1', 11),
    _l1('cat_housing', 'category_housing', 'home', '#795548', 12),
    _l1('cat_car', 'category_car', 'directions_car', '#455A64', 13),
    _l1('cat_tax', 'category_tax', 'account_balance', '#5D4037', 14),
    _l1('cat_insurance', 'category_insurance', 'security', '#827717', 15),
    _l1('cat_special', 'category_special', 'star', '#AD1457', 16),
    _l1('cat_asset', 'category_asset', 'savings', '#1B5E20', 17),
    _l1('cat_other_expense', 'category_other_expense', 'more_horiz', '#607D8B', 18),
    _l1('cat_uncategorized', 'category_uncategorized', 'help_outline', '#9E9E9E', 19),
  ];

  // ─── Expense L2 (PRD \u00a710.1\u201310.16, 103 items) ───

  static final List<Category> _expenseL2 = [
    // \u00a710.16 Food (8 L2s)
    _l2('cat_food_general', 'category_food_general', 'restaurant', '#FF5722', 'cat_food', 0),
    _l2('cat_food_groceries', 'category_food_groceries', 'shopping_basket', '#FF5722', 'cat_food', 1),
    _l2('cat_food_dining_out', 'category_food_dining_out', 'restaurant_menu', '#FF5722', 'cat_food', 2),
    _l2('cat_food_breakfast', 'category_food_breakfast', 'free_breakfast', '#FF5722', 'cat_food', 3),
    _l2('cat_food_lunch', 'category_food_lunch', 'lunch_dining', '#FF5722', 'cat_food', 4),
    _l2('cat_food_dinner', 'category_food_dinner', 'dinner_dining', '#FF5722', 'cat_food', 5),
    _l2('cat_food_cafe', 'category_food_cafe', 'local_cafe', '#FF5722', 'cat_food', 6),
    _l2('cat_food_other', 'category_food_other', 'more_horiz', '#FF5722', 'cat_food', 99),

    // \u00a710.15 Daily Necessities (6 L2s)
    _l2('cat_daily_general', 'category_daily_general', 'local_mall', '#00BCD4', 'cat_daily', 0),
    _l2('cat_daily_household', 'category_daily_household', 'cleaning_services', '#00BCD4', 'cat_daily', 1),
    _l2('cat_daily_children', 'category_daily_children', 'child_care', '#00BCD4', 'cat_daily', 2),
    _l2('cat_daily_pets', 'category_daily_pets', 'pets', '#00BCD4', 'cat_daily', 3),
    _l2('cat_daily_tobacco', 'category_daily_tobacco', 'smoking_rooms', '#00BCD4', 'cat_daily', 4),
    _l2('cat_daily_other', 'category_daily_other', 'more_horiz', '#00BCD4', 'cat_daily', 99),

    // \u00a710.1 Transport (6 L2s)
    _l2('cat_transport_general', 'category_transport_general', 'directions_bus', '#2196F3', 'cat_transport', 0),
    _l2('cat_transport_train', 'category_transport_train', 'train', '#2196F3', 'cat_transport', 1),
    _l2('cat_transport_bus', 'category_transport_bus', 'directions_bus', '#2196F3', 'cat_transport', 2),
    _l2('cat_transport_taxi', 'category_transport_taxi', 'local_taxi', '#2196F3', 'cat_transport', 3),
    _l2('cat_transport_flights', 'category_transport_flights', 'flight', '#2196F3', 'cat_transport', 4),
    _l2('cat_transport_other', 'category_transport_other', 'more_horiz', '#2196F3', 'cat_transport', 99),

    // \u00a710.12 Hobbies & Entertainment (7 L2s)
    _l2('cat_hobbies_leisure', 'category_hobbies_leisure', 'sports_tennis', '#9C27B0', 'cat_hobbies', 1),
    _l2('cat_hobbies_events', 'category_hobbies_events', 'event', '#9C27B0', 'cat_hobbies', 2),
    _l2('cat_hobbies_movies', 'category_hobbies_movies', 'movie', '#9C27B0', 'cat_hobbies', 3),
    _l2('cat_hobbies_games', 'category_hobbies_games', 'videogame_asset', '#9C27B0', 'cat_hobbies', 4),
    _l2('cat_hobbies_books', 'category_hobbies_books', 'menu_book', '#9C27B0', 'cat_hobbies', 5),
    _l2('cat_hobbies_travel', 'category_hobbies_travel', 'luggage', '#9C27B0', 'cat_hobbies', 6),
    _l2('cat_hobbies_other', 'category_hobbies_other', 'more_horiz', '#9C27B0', 'cat_hobbies', 99),

    // \u00a710.10 Clothing & Beauty (8 L2s)
    _l2('cat_clothing_clothes', 'category_clothing_clothes', 'checkroom', '#E91E63', 'cat_clothing', 1),
    _l2('cat_clothing_accessories', 'category_clothing_accessories', 'watch', '#E91E63', 'cat_clothing', 2),
    _l2('cat_clothing_underwear', 'category_clothing_underwear', 'dry_cleaning', '#E91E63', 'cat_clothing', 3),
    _l2('cat_clothing_hair', 'category_clothing_hair', 'content_cut', '#E91E63', 'cat_clothing', 4),
    _l2('cat_clothing_cosmetics', 'category_clothing_cosmetics', 'face_retouching_natural', '#E91E63', 'cat_clothing', 5),
    _l2('cat_clothing_esthetic', 'category_clothing_esthetic', 'spa', '#E91E63', 'cat_clothing', 6),
    _l2('cat_clothing_cleaning', 'category_clothing_cleaning', 'local_laundry_service', '#E91E63', 'cat_clothing', 7),
    _l2('cat_clothing_other', 'category_clothing_other', 'more_horiz', '#E91E63', 'cat_clothing', 99),

    // \u00a710.7 Socializing (5 L2s)
    _l2('cat_social_general', 'category_social_general', 'people', '#FF9800', 'cat_social', 0),
    _l2('cat_social_drinks', 'category_social_drinks', 'local_bar', '#FF9800', 'cat_social', 1),
    _l2('cat_social_gifts', 'category_social_gifts', 'card_giftcard', '#FF9800', 'cat_social', 2),
    _l2('cat_social_ceremonial', 'category_social_ceremonial', 'celebration', '#FF9800', 'cat_social', 3),
    _l2('cat_social_other', 'category_social_other', 'more_horiz', '#FF9800', 'cat_social', 99),

    // \u00a710.5 Health & Medical (5 L2s)
    _l2('cat_health_fitness', 'category_health_fitness', 'fitness_center', '#F44336', 'cat_health', 1),
    _l2('cat_health_massage', 'category_health_massage', 'self_improvement', '#F44336', 'cat_health', 2),
    _l2('cat_health_hospital', 'category_health_hospital', 'local_hospital', '#F44336', 'cat_health', 3),
    _l2('cat_health_medicine', 'category_health_medicine', 'medication', '#F44336', 'cat_health', 4),
    _l2('cat_health_other', 'category_health_other', 'more_horiz', '#F44336', 'cat_health', 99),

    // \u00a710.6 Education & Self-Improvement (7 L2s)
    _l2('cat_education_books', 'category_education_books', 'menu_book', '#3F51B5', 'cat_education', 1),
    _l2('cat_education_newspapers', 'category_education_newspapers', 'newspaper', '#3F51B5', 'cat_education', 2),
    _l2('cat_education_classes', 'category_education_classes', 'cast_for_education', '#3F51B5', 'cat_education', 3),
    _l2('cat_education_textbooks', 'category_education_textbooks', 'auto_stories', '#3F51B5', 'cat_education', 4),
    _l2('cat_education_tuition', 'category_education_tuition', 'school', '#3F51B5', 'cat_education', 5),
    _l2('cat_education_cram_school', 'category_education_cram_school', 'edit_note', '#3F51B5', 'cat_education', 6),
    _l2('cat_education_other', 'category_education_other', 'more_horiz', '#3F51B5', 'cat_education', 99),

    // \u00a710.4 Utilities (5 L2s)
    _l2('cat_utilities_general', 'category_utilities_general', 'flash_on', '#FFC107', 'cat_utilities', 0),
    _l2('cat_utilities_electricity', 'category_utilities_electricity', 'bolt', '#FFC107', 'cat_utilities', 1),
    _l2('cat_utilities_water', 'category_utilities_water', 'water_drop', '#FFC107', 'cat_utilities', 2),
    _l2('cat_utilities_gas', 'category_utilities_gas', 'local_fire_department', '#FFC107', 'cat_utilities', 3),
    _l2('cat_utilities_other', 'category_utilities_other', 'more_horiz', '#FFC107', 'cat_utilities', 99),

    // \u00a710.13 Communication (7 L2s)
    _l2('cat_communication_mobile', 'category_communication_mobile', 'smartphone', '#00ACC1', 'cat_communication', 1),
    _l2('cat_communication_landline', 'category_communication_landline', 'phone', '#00ACC1', 'cat_communication', 2),
    _l2('cat_communication_internet', 'category_communication_internet', 'wifi', '#00ACC1', 'cat_communication', 3),
    _l2('cat_communication_broadcast', 'category_communication_broadcast', 'live_tv', '#00ACC1', 'cat_communication', 4),
    _l2('cat_communication_info', 'category_communication_info', 'info', '#00ACC1', 'cat_communication', 5),
    _l2('cat_communication_delivery', 'category_communication_delivery', 'local_shipping', '#00ACC1', 'cat_communication', 6),
    _l2('cat_communication_other', 'category_communication_other', 'more_horiz', '#00ACC1', 'cat_communication', 99),

    // \u00a710.14 Housing (8 L2s)
    _l2('cat_housing_rent', 'category_housing_rent', 'apartment', '#795548', 'cat_housing', 1),
    _l2('cat_housing_mortgage', 'category_housing_mortgage', 'real_estate_agent', '#795548', 'cat_housing', 2),
    _l2('cat_housing_management', 'category_housing_management', 'corporate_fare', '#795548', 'cat_housing', 3),
    _l2('cat_housing_furniture', 'category_housing_furniture', 'chair', '#795548', 'cat_housing', 4),
    _l2('cat_housing_appliances', 'category_housing_appliances', 'kitchen', '#795548', 'cat_housing', 5),
    _l2('cat_housing_renovation', 'category_housing_renovation', 'construction', '#795548', 'cat_housing', 6),
    _l2('cat_housing_insurance', 'category_housing_insurance', 'shield', '#795548', 'cat_housing', 7),
    _l2('cat_housing_other', 'category_housing_other', 'more_horiz', '#795548', 'cat_housing', 99),

    // \u00a710.9 Car & Motorcycle (8 L2s)
    _l2('cat_car_fuel', 'category_car_fuel', 'local_gas_station', '#455A64', 'cat_car', 1),
    _l2('cat_car_parking', 'category_car_parking', 'local_parking', '#455A64', 'cat_car', 2),
    _l2('cat_car_toll', 'category_car_toll', 'toll', '#455A64', 'cat_car', 3),
    _l2('cat_car_loan', 'category_car_loan', 'payments', '#455A64', 'cat_car', 4),
    _l2('cat_car_insurance', 'category_car_insurance', 'security', '#455A64', 'cat_car', 5),
    _l2('cat_car_tax', 'category_car_tax', 'receipt_long', '#455A64', 'cat_car', 6),
    _l2('cat_car_maintenance', 'category_car_maintenance', 'build', '#455A64', 'cat_car', 7),
    _l2('cat_car_other', 'category_car_other', 'more_horiz', '#455A64', 'cat_car', 99),

    // \u00a710.3 Taxes & Social Security (4 L2s)
    _l2('cat_tax_income', 'category_tax_income', 'receipt', '#5D4037', 'cat_tax', 1),
    _l2('cat_tax_pension', 'category_tax_pension', 'elderly', '#5D4037', 'cat_tax', 2),
    _l2('cat_tax_health_insurance', 'category_tax_health_insurance', 'health_and_safety', '#5D4037', 'cat_tax', 3),
    _l2('cat_tax_other', 'category_tax_other', 'more_horiz', '#5D4037', 'cat_tax', 99),

    // \u00a710.2 Insurance (4 L2s)
    _l2('cat_insurance_general', 'category_insurance_general', 'security', '#827717', 'cat_insurance', 0),
    _l2('cat_insurance_life', 'category_insurance_life', 'favorite', '#827717', 'cat_insurance', 1),
    _l2('cat_insurance_medical', 'category_insurance_medical', 'medical_services', '#827717', 'cat_insurance', 2),
    _l2('cat_insurance_other', 'category_insurance_other', 'more_horiz', '#827717', 'cat_insurance', 99),

    // \u00a710.8 Special Expenses (7 L2s)
    _l2('cat_special_general', 'category_special_general', 'star', '#AD1457', 'cat_special', 0),
    _l2('cat_special_furniture', 'category_special_furniture', 'weekend', '#AD1457', 'cat_special', 1),
    _l2('cat_special_housing', 'category_special_housing', 'home_repair_service', '#AD1457', 'cat_special', 2),
    _l2('cat_special_wedding', 'category_special_wedding', 'favorite_border', '#AD1457', 'cat_special', 3),
    _l2('cat_special_fertility', 'category_special_fertility', 'child_friendly', '#AD1457', 'cat_special', 4),
    _l2('cat_special_nursing', 'category_special_nursing', 'accessible', '#AD1457', 'cat_special', 5),
    _l2('cat_special_other', 'category_special_other', 'more_horiz', '#AD1457', 'cat_special', 99),

    // \u00a710.11 Other (8 L2s)
    _l2('cat_other_advances', 'category_other_advances', 'swap_horiz', '#607D8B', 'cat_other_expense', 1),
    _l2('cat_other_remittance', 'category_other_remittance', 'send', '#607D8B', 'cat_other_expense', 2),
    _l2('cat_other_allowance', 'category_other_allowance', 'wallet', '#607D8B', 'cat_other_expense', 3),
    _l2('cat_other_business', 'category_other_business', 'business_center', '#607D8B', 'cat_other_expense', 4),
    _l2('cat_other_debt', 'category_other_debt', 'money_off', '#607D8B', 'cat_other_expense', 5),
    _l2('cat_other_misc', 'category_other_misc', 'category', '#607D8B', 'cat_other_expense', 6),
    _l2('cat_other_unclassified', 'category_other_unclassified', 'help_outline', '#607D8B', 'cat_other_expense', 7),
    _l2('cat_other_other', 'category_other_other', 'more_horiz', '#607D8B', 'cat_other_expense', 99),
  ];

  // ─── Income L1 ───

  static final List<Category> _incomeL1 = [
    _l1('cat_salary', 'category_salary', 'account_balance', '#4CAF50', 1),
    _l1('cat_bonus', 'category_bonus', 'stars', '#FFC107', 2),
    _l1('cat_investment', 'category_investment', 'trending_up', '#009688', 3),
    _l1('cat_other_income', 'category_other_income', 'attach_money', '#8BC34A', 99),
  ];

  // ─── Default Ledger Configs ───

  static final List<CategoryLedgerConfig> _defaultLedgerConfigs = [
    _config('cat_food', LedgerType.survival),
    _config('cat_daily', LedgerType.survival),
    _config('cat_transport', LedgerType.survival),
    _config('cat_hobbies', LedgerType.soul),
    _config('cat_clothing', LedgerType.soul),
    _config('cat_social', LedgerType.survival),
    _config('cat_health', LedgerType.survival),
    _config('cat_education', LedgerType.soul),
    _config('cat_cash_card', LedgerType.survival),
    _config('cat_utilities', LedgerType.survival),
    _config('cat_communication', LedgerType.survival),
    _config('cat_housing', LedgerType.survival),
    _config('cat_car', LedgerType.survival),
    _config('cat_tax', LedgerType.survival),
    _config('cat_insurance', LedgerType.survival),
    _config('cat_special', LedgerType.survival),
    _config('cat_asset', LedgerType.soul),
    _config('cat_other_expense', LedgerType.survival),
    _config('cat_uncategorized', LedgerType.survival),
  ];

  // ─── Factory helpers ───

  static Category _l1(
    String id, String name, String icon, String color, int sortOrder,
  ) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: color,
        level: 1,
        isSystem: true,
        sortOrder: sortOrder,
        createdAt: _epoch,
      );

  static Category _l2(
    String id, String name, String icon, String color,
    String parentId, int sortOrder,
  ) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: color,
        parentId: parentId,
        level: 2,
        isSystem: true,
        sortOrder: sortOrder,
        createdAt: _epoch,
      );

  static CategoryLedgerConfig _config(String categoryId, LedgerType type) =>
      CategoryLedgerConfig(
        categoryId: categoryId,
        ledgerType: type,
        updatedAt: _epoch,
      );
}
