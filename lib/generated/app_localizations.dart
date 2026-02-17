import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Home Pocket'**
  String get appName;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Transactions tab/screen label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Analytics tab/screen label
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Settings tab/screen label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Ledger tab label
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// New transaction screen title
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransaction;

  /// Amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Note field label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Merchant field label
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Expense transaction type
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// Income transaction type
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// Food category
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Housing category
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// Transport category
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// Utilities category
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// Entertainment category
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// Education category
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// Health category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// Shopping category
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// Other category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Survival ledger label
  ///
  /// In en, this message translates to:
  /// **'Survival Ledger'**
  String get survivalLedger;

  /// Soul ledger label
  ///
  /// In en, this message translates to:
  /// **'Soul Ledger'**
  String get soulLedger;

  /// Short survival label
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get survival;

  /// Short soul label
  ///
  /// In en, this message translates to:
  /// **'Soul'**
  String get soul;

  /// Save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// OK action
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter action
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort action
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Refresh action
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Loading state text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// N days ago relative date
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Network error
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// Unknown error
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// Invalid amount error
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get errorInvalidAmount;

  /// Required field error
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errorRequired;

  /// Invalid date error
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get errorInvalidDate;

  /// Database write error
  ///
  /// In en, this message translates to:
  /// **'Database write error'**
  String get errorDatabaseWrite;

  /// Database read error
  ///
  /// In en, this message translates to:
  /// **'Database read error'**
  String get errorDatabaseRead;

  /// Encryption error
  ///
  /// In en, this message translates to:
  /// **'Encryption error'**
  String get errorEncryption;

  /// Sync error
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get errorSync;

  /// Biometric error
  ///
  /// In en, this message translates to:
  /// **'Biometric error'**
  String get errorBiometric;

  /// Permission error
  ///
  /// In en, this message translates to:
  /// **'Permission error'**
  String get errorPermission;

  /// Minimum amount error
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount of at least {min}'**
  String errorMinAmount(double min);

  /// Maximum amount error
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount no greater than {max}'**
  String errorMaxAmount(double max);

  /// Save success
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get successSaved;

  /// Delete success
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get successDeleted;

  /// Sync success
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get successSynced;

  /// Merchant placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter merchant name'**
  String get merchantPlaceholder;

  /// Note placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter a note'**
  String get notePlaceholder;

  /// Optional note label
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// Amount prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// Amount validation
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get amountMustBeGreaterThanZero;

  /// Category prompt
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// Empty transaction list
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// Empty state hint
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction'**
  String get tapToAddFirstTransaction;

  /// Transaction save success
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionSaved;

  /// Save failure
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// System theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Security section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Biometric lock setting
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// Biometric lock subtitle
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / fingerprint to unlock'**
  String get biometricLockDescription;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Budget alerts and sync notifications'**
  String get notificationsDescription;

  /// Data management section
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// Export backup action
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// Export subtitle
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup file'**
  String get exportBackupDescription;

  /// Import backup action
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// Import subtitle
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file'**
  String get importBackupDescription;

  /// Delete all data action
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Delete all subtitle
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all records'**
  String get deleteAllDataDescription;

  /// Delete all confirmation
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure you want to delete all data?'**
  String get deleteAllDataConfirmation;

  /// Delete all success
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDataDeleted;

  /// Delete failure
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// Export success
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupExportedSuccessfully;

  /// Export failure
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// Import success
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get backupImportedSuccessfully;

  /// Import failure
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// Export password dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Backup Password'**
  String get setBackupPassword;

  /// Import password dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Backup Password'**
  String get enterBackupPassword;

  /// Password hint
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// Confirm password hint
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Password validation
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Password mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Licenses link
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Demo data action
  ///
  /// In en, this message translates to:
  /// **'Generate Demo Data'**
  String get generateDemoData;

  /// Demo data dialog text
  ///
  /// In en, this message translates to:
  /// **'This will create sample transactions for the last 3 months to showcase analytics features.'**
  String get generateDemoDataDescription;

  /// Generate action
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// Demo data success
  ///
  /// In en, this message translates to:
  /// **'Demo data generated! Pull to refresh.'**
  String get demoDataGenerated;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Japanese language option
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Init error message
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize app'**
  String get initializationError;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ja':
      return SJa();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
