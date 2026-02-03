/// Application Configuration
class AppConfig {
  // App Info
  static const String appName = 'Home Pocket';
  static const String appVersion = '0.1.0';

  // Database
  static const String databaseName = 'home_pocket.db';
  static const int databaseSchemaVersion = 1;

  // Security
  static const int pbkdf2Iterations = 256000;
  static const int cipherPageSize = 4096;

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;

  // Cache
  static const Duration defaultCacheDuration = Duration(seconds: 60);

  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelayS = Duration(milliseconds: 500);

  // File
  static const int maxPhotoSizeMB = 10;
  static const List<String> allowedPhotoFormats = ['jpg', 'jpeg', 'png'];
}
