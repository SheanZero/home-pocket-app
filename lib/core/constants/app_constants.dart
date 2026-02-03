/// Application Constants
class AppConstants {
  // Route Names
  static const String homeRoute = '/';
  static const String transactionListRoute = '/transactions';
  static const String transactionFormRoute = '/transactions/new';
  static const String analyticsRoute = '/analytics';
  static const String settingsRoute = '/settings';

  // Storage Keys
  static const String currentBookIdKey = 'current_book_id';
  static const String themeM Mode key = 'theme_mode';
  static const String localeKey = 'locale';

  // Default Values
  static const String defaultCurrency = 'CNY';
  static const String defaultLocale = 'ja';

  // Limits
  static const int maxTransactionAmount = 99999999; // 9999万
  static const int minTransactionAmount = 1;
  static const int maxNoteLength = 500;

  // Category IDs (System)
  static const String catFoodId = 'cat_food';
  static const String catHousingId = 'cat_housing';
  static const String catTransportId = 'cat_transport';
  static const String catMedicalId = 'cat_medical';
  static const String catEntertainmentId = 'cat_entertainment';
  static const String catHobbyId = 'cat_hobby';
}
