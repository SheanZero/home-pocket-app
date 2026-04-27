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

  /// Generic cancel button label
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

  /// Placeholder shown when no category is selected in confirm screen
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
  /// **'日本語'**
  String get languageJapanese;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// Confirm delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Delete transaction confirmation message
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTransactionConfirmation;

  /// Generic error title for error screens
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message when app initialization fails
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String initializationError(String error);

  /// No description provided for @profileSetup.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you!'**
  String get profileSetup;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Home Pocket'**
  String get profileSetupSubtitle;

  /// No description provided for @profileNickname.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get profileNickname;

  /// No description provided for @profileNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get profileNicknamePlaceholder;

  /// No description provided for @profileStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get profileStart;

  /// No description provided for @profileSelectAvatar.
  ///
  /// In en, this message translates to:
  /// **'Select Avatar'**
  String get profileSelectAvatar;

  /// No description provided for @profileEmojiTab.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get profileEmojiTab;

  /// No description provided for @profilePhotoTab.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get profilePhotoTab;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileDone;

  /// No description provided for @profilePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get profilePreview;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Home Pocket'**
  String get welcomeTo;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get profileNameRequired;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Tap to change avatar'**
  String get profileChangeAvatar;

  /// No description provided for @profilePhotoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access denied'**
  String get profilePhotoPermissionDenied;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load photo'**
  String get profilePhotoFailed;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get profileSaveFailed;

  /// No description provided for @profileNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be 50 characters or less'**
  String get profileNameTooLong;

  /// No description provided for @profileUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get profileUploadPhoto;

  /// Home card title for monthly expense overview
  ///
  /// In en, this message translates to:
  /// **'Monthly Expenses'**
  String get homeMonthlyExpense;

  /// Survival ledger expense label
  ///
  /// In en, this message translates to:
  /// **'Living Expenses'**
  String get homeSurvivalExpense;

  /// Soul ledger expense label
  ///
  /// In en, this message translates to:
  /// **'Joy Expenses'**
  String get homeSoulExpense;

  /// Month-over-month comparison header
  ///
  /// In en, this message translates to:
  /// **'vs Last Month'**
  String get homeMonthComparison;

  /// Previous month amount subtitle for home ledger rows
  ///
  /// In en, this message translates to:
  /// **'Last month {amount}'**
  String homePreviousMonthAmount(String amount);

  /// Compact home ledger row tag for survival ledger
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get homeSurvivalLedgerTag;

  /// Compact home ledger row tag for soul/joy ledger
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get homeSoulLedgerTag;

  /// Compact home ledger row tag for shared family ledger
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get homeSharedLedgerTag;

  /// Home ledger row title for a family member shadow book
  ///
  /// In en, this message translates to:
  /// **'{memberName}\'s Ledger'**
  String homeShadowBookTitle(String memberName);

  /// Soul fullness section title
  ///
  /// In en, this message translates to:
  /// **'Soul Fullness'**
  String get homeSoulFullness;

  /// Soul spending percentage metric label
  ///
  /// In en, this message translates to:
  /// **'Soul spending ratio'**
  String get homeSoulPercentLabel;

  /// Happiness ROI metric label
  ///
  /// In en, this message translates to:
  /// **'Happiness ROI'**
  String get homeHappinessROI;

  /// Family invite banner title
  ///
  /// In en, this message translates to:
  /// **'Invite Family'**
  String get homeFamilyInviteTitle;

  /// Family invite banner description
  ///
  /// In en, this message translates to:
  /// **'Share your ledger with your partner'**
  String get homeFamilyInviteDesc;

  /// Today's transaction section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Records'**
  String get homeTodayTitle;

  /// Transaction count for today
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String homeTodayCount(int count);

  /// Mode badge for personal/solo mode
  ///
  /// In en, this message translates to:
  /// **'Personal Mode'**
  String get homePersonalMode;

  /// Mode badge for family/group mode
  ///
  /// In en, this message translates to:
  /// **'Family Mode'**
  String get homeFamilyMode;

  /// Bottom nav home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabHome;

  /// Bottom nav list tab label
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get homeTabList;

  /// Bottom nav charts tab label
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get homeTabChart;

  /// Bottom nav todo tab label
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get homeTabTodo;

  /// Year and month display format
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}'**
  String homeMonthFormat(int year, int month);

  /// Short month label for bar chart
  ///
  /// In en, this message translates to:
  /// **'M{month}'**
  String homeMonthLabel(int month);

  /// Recent soul transaction summary
  ///
  /// In en, this message translates to:
  /// **'Recent: {merchant} ¥{amount}'**
  String homeRecentSoulTransaction(String merchant, int amount);

  /// Soul charge card status line
  ///
  /// In en, this message translates to:
  /// **'Soul Fullness {fullness}% · Happiness ROI {roi}x'**
  String homeSoulChargeStatus(int fullness, double roi);

  /// Soul fullness month badge
  ///
  /// In en, this message translates to:
  /// **'This month {percent}%'**
  String homeMonthBadge(int percent);

  /// Transaction entry screen title
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// Manual input mode tab label
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualInput;

  /// Future OCR/MOD-005 stub
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get ocrScan;

  /// Voice input mode tab label
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceInput;

  /// Category selection screen title
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Category search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategory;

  /// Confirm screen title
  ///
  /// In en, this message translates to:
  /// **'Expense Detail'**
  String get expenseDetail;

  /// Back navigation label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Save/record transaction button
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// Store input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter store'**
  String get enterStore;

  /// Memo input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter memo...'**
  String get enterMemo;

  /// Ledger type section title
  ///
  /// In en, this message translates to:
  /// **'Expense Type'**
  String get expenseClassification;

  /// Survival ledger chip label
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get survivalExpense;

  /// Soul ledger chip label
  ///
  /// In en, this message translates to:
  /// **'Soul'**
  String get soulExpense;

  /// Soul satisfaction slider label
  ///
  /// In en, this message translates to:
  /// **'Soul Fullness'**
  String get soulSatisfaction;

  /// Add photo button label
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// Future OCR/MOD-005 stub
  ///
  /// In en, this message translates to:
  /// **'OCR Scan'**
  String get ocrScanTitle;

  /// Future OCR/MOD-005 stub
  ///
  /// In en, this message translates to:
  /// **'Place receipt in frame'**
  String get ocrHint;

  /// Label shown above the recognized voice transcript
  ///
  /// In en, this message translates to:
  /// **'Recognition Result'**
  String get voiceRecognitionResult;

  /// Section label shown above the parsed voice recognition card
  ///
  /// In en, this message translates to:
  /// **'Recognition result'**
  String get recognitionResult;

  /// Header label for the emoji satisfaction picker
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get satisfactionLevel;

  /// Lowest satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get satisfactionBad;

  /// Second lowest satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Slightly bad'**
  String get satisfactionSlightlyBad;

  /// Neutral satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get satisfactionNormal;

  /// Positive satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get satisfactionGood;

  /// High satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get satisfactionVeryGood;

  /// Highest satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get satisfactionExcellent;

  /// Action chip label to add a subcategory
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSubcategory;

  /// Bottom action button label to add a category
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// AppBar title during category reorder edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit category order'**
  String get editCategoryOrder;

  /// Hint banner shown in category reorder edit mode
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// SnackBar shown after successfully saving category reorder
  ///
  /// In en, this message translates to:
  /// **'Order updated'**
  String get orderUpdated;

  /// SnackBar shown when saving category reorder fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save order. Please retry'**
  String get orderSaveFailed;

  /// Dialog title when cancelling reorder with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discardUnsavedChanges;

  /// Dialog cancel button: keep editing
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// Dialog confirm button: discard unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Voice input hint
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get tapToRecord;

  /// Today date chip label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayDate;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Voice input settings section title
  ///
  /// In en, this message translates to:
  /// **'Voice Recognition'**
  String get voiceInputSettings;

  /// Voice recognition language setting label
  ///
  /// In en, this message translates to:
  /// **'Recognition Language'**
  String get voiceLanguage;

  /// Subtitle for voice language setting
  ///
  /// In en, this message translates to:
  /// **'Language used for speech-to-text'**
  String get voiceLanguageSubtitle;

  /// Title for the family sync feature
  ///
  /// In en, this message translates to:
  /// **'Family Sync'**
  String get familySync;

  /// Tab label to show pairing code
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get familySyncShowMyCode;

  /// Tab label to enter partner's pairing code
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get familySyncEnterPartnerCode;

  /// Label for the pairing code
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get familySyncPairCode;

  /// Instructions for sharing the pairing code
  ///
  /// In en, this message translates to:
  /// **'Share this invite code or QR with a family member to let them join your group'**
  String get familySyncScanOrEnter;

  /// Shown when pairing code has expired
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get familySyncCodeExpired;

  /// Button to regenerate pairing code
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get familySyncRegenerate;

  /// Placeholder for pairing code input field
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit invite code'**
  String get familySyncEnterDigitCode;

  /// Submit button for pairing code
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get familySyncSubmit;

  /// Section title for paired device info
  ///
  /// In en, this message translates to:
  /// **'Family Group'**
  String get familySyncPairedDevice;

  /// Section title for pair details
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get familySyncPairInfo;

  /// Label for pair ID
  ///
  /// In en, this message translates to:
  /// **'Group ID'**
  String get familySyncPairId;

  /// Label for paired date
  ///
  /// In en, this message translates to:
  /// **'Paired since'**
  String get familySyncPairedSince;

  /// Label for associated book ID
  ///
  /// In en, this message translates to:
  /// **'Book ID'**
  String get familySyncBookId;

  /// Button to unpair devices
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get familySyncUnpair;

  /// Title for unpair confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Unpair Device'**
  String get familySyncUnpairDevice;

  /// Confirmation message for unpair action
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unpair from {deviceName}? Sync will stop until you pair again.'**
  String familySyncUnpairConfirm(String deviceName);

  /// Error message when unpair fails
  ///
  /// In en, this message translates to:
  /// **'Unpair failed: {message}'**
  String familySyncUnpairFailed(String message);

  /// Shown when no device is paired
  ///
  /// In en, this message translates to:
  /// **'No family group'**
  String get familySyncNoDevicePaired;

  /// Prompt to pair with a family member
  ///
  /// In en, this message translates to:
  /// **'Create or join a family group to sync transactions'**
  String get familySyncPairPrompt;

  /// Sync status description when synced
  ///
  /// In en, this message translates to:
  /// **'Connected and up to date'**
  String get familySyncStatusSynced;

  /// Sync status description when syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing with group...'**
  String get familySyncStatusSyncing;

  /// Sync status description when offline
  ///
  /// In en, this message translates to:
  /// **'Offline - will sync when connected'**
  String get familySyncStatusOffline;

  /// Sync status description when error
  ///
  /// In en, this message translates to:
  /// **'Sync error occurred'**
  String get familySyncStatusError;

  /// Sync status description when pairing
  ///
  /// In en, this message translates to:
  /// **'Group setup in progress...'**
  String get familySyncStatusPairing;

  /// Loading text while checking whether the device is already in a group
  ///
  /// In en, this message translates to:
  /// **'Checking group status...'**
  String get familySyncCheckingGroup;

  /// Error shown when verifying current group membership fails
  ///
  /// In en, this message translates to:
  /// **'Could not check group status: {message}'**
  String familySyncCheckFailed(String message);

  /// Sync status description when unpaired
  ///
  /// In en, this message translates to:
  /// **'Tap to create or join a family group'**
  String get familySyncStatusUnpaired;

  /// Badge label for synced status
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get familySyncBadgeSynced;

  /// Badge label for syncing status
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get familySyncBadgeSyncing;

  /// Badge label for offline status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get familySyncBadgeOffline;

  /// Badge label for error status
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get familySyncBadgeError;

  /// Badge label for pairing status
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get familySyncBadgePairing;

  /// Loading text while creating a group
  ///
  /// In en, this message translates to:
  /// **'Creating group...'**
  String get familySyncCreatingGroup;

  /// Button label for joining a group
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get familySyncJoinGroup;

  /// Snackbar text shown after joining a group
  ///
  /// In en, this message translates to:
  /// **'Joined the group. Waiting for owner confirmation...'**
  String get familySyncJoinSuccess;

  /// Button label to leave a group
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get familySyncLeaveGroup;

  /// Button label to deactivate a group
  ///
  /// In en, this message translates to:
  /// **'Deactivate Group'**
  String get familySyncDeactivateGroup;

  /// Confirmation message for leaving a group
  ///
  /// In en, this message translates to:
  /// **'Leave this family group? Sync will stop on this device until you join again.'**
  String get familySyncLeaveGroupConfirm;

  /// Confirmation message for deactivating a group
  ///
  /// In en, this message translates to:
  /// **'Deactivate this family group for everyone? Sync will stop for all members until a new group is created.'**
  String get familySyncDeactivateGroupConfirm;

  /// Error message when leaving a group fails
  ///
  /// In en, this message translates to:
  /// **'Leave group failed: {message}'**
  String familySyncLeaveGroupFailed(String message);

  /// Error message when deactivating a group fails
  ///
  /// In en, this message translates to:
  /// **'Deactivate group failed: {message}'**
  String familySyncDeactivateGroupFailed(String message);

  /// Button label to regenerate the group invite code
  ///
  /// In en, this message translates to:
  /// **'Regenerate Invite'**
  String get familySyncRegenerateInvite;

  /// Error message when regenerating an invite fails
  ///
  /// In en, this message translates to:
  /// **'Regenerate invite failed: {message}'**
  String familySyncRegenerateInviteFailed(String message);

  /// Section title for group members
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get familySyncMembers;

  /// Label showing the number of group members
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String familySyncMemberCount(int count);

  /// Role label for the group owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get familySyncRoleOwner;

  /// Role label for a regular group member
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get familySyncRoleMember;

  /// Status label for an active group member
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get familySyncMemberStatusActive;

  /// Status label for a pending group member
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get familySyncMemberStatusPending;

  /// Button label to remove a member from the group
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get familySyncRemoveMember;

  /// Confirmation message for removing a member
  ///
  /// In en, this message translates to:
  /// **'Remove {deviceName} from this family group?'**
  String familySyncRemoveMemberConfirm(String deviceName);

  /// Error message when removing a member fails
  ///
  /// In en, this message translates to:
  /// **'Remove member failed: {message}'**
  String familySyncRemoveMemberFailed(String message);

  /// Badge label for unpaired status
  ///
  /// In en, this message translates to:
  /// **'Unpaired'**
  String get familySyncBadgeUnpaired;

  /// Button label to share an invite code
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get familySyncShare;

  /// Label for invite code expiry time
  ///
  /// In en, this message translates to:
  /// **'Expires: {time}'**
  String familySyncExpiryLabel(String time);

  /// Title for the join group panel
  ///
  /// In en, this message translates to:
  /// **'Join Family'**
  String get familySyncJoinTitle;

  /// Description shown on the join group panel
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit invite code you received from a family member.'**
  String get familySyncJoinDescription;

  /// Divider text between join actions
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get familySyncOrDivider;

  /// Button label to scan a QR code
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get familySyncScanQr;

  /// Title shown while waiting for owner approval
  ///
  /// In en, this message translates to:
  /// **'Waiting for Approval...'**
  String get familySyncWaitingTitle;

  /// Description shown while waiting for owner approval
  ///
  /// In en, this message translates to:
  /// **'The group owner is reviewing your join request. Please wait until approval is complete.'**
  String get familySyncWaitingDescription;

  /// Label for the group name row
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get familySyncGroupLabel;

  /// Label for the status row
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get familySyncStatusLabel;

  /// Title for the member approval screen
  ///
  /// In en, this message translates to:
  /// **'Member Approval'**
  String get familySyncApprovalTitle;

  /// Heading for a new join request card
  ///
  /// In en, this message translates to:
  /// **'New Join Request'**
  String get familySyncNewRequest;

  /// Body text for a foreground notification about a new join request
  ///
  /// In en, this message translates to:
  /// **'A family member wants to join your group. Review the request to continue.'**
  String get familySyncJoinRequestNotificationBody;

  /// Body text for a foreground notification about a new join request with device name
  ///
  /// In en, this message translates to:
  /// **'{deviceName} wants to join your family ledger'**
  String familySyncJoinRequestWithName(String deviceName);

  /// Title for a foreground notification after a member is confirmed
  ///
  /// In en, this message translates to:
  /// **'Group Ready'**
  String get familySyncMemberConfirmedNotificationTitle;

  /// Body text for a foreground notification after a member is confirmed
  ///
  /// In en, this message translates to:
  /// **'Your family sync group is ready. Open group management to review the latest status.'**
  String get familySyncMemberConfirmedNotificationBody;

  /// Text indicating a request was received just now
  ///
  /// In en, this message translates to:
  /// **'Requested just now'**
  String get familySyncJustNow;

  /// Security verification helper text for approval screen
  ///
  /// In en, this message translates to:
  /// **'This device public key has been verified.'**
  String get familySyncSecurityVerified;

  /// Reject button label on the approval screen
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get familySyncReject;

  /// Approve button label on the approval screen
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get familySyncApprove;

  /// Section title for the current members list
  ///
  /// In en, this message translates to:
  /// **'Current Members'**
  String get familySyncCurrentMembers;

  /// Informational tip shown on the approval screen
  ///
  /// In en, this message translates to:
  /// **'Approving this request will sync the device and data with encryption enabled.'**
  String get familySyncApprovalTip;

  /// Title for the group management screen
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get familySyncGroupManagement;

  /// Short status label indicating the group is synced
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get familySyncSynced;

  /// Label for the synced entries statistic
  ///
  /// In en, this message translates to:
  /// **'Synced Entries'**
  String get familySyncSyncedEntries;

  /// Label for the last sync statistic
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get familySyncLastSync;

  /// Suffix appended to the current user's device name
  ///
  /// In en, this message translates to:
  /// **' (You)'**
  String get familySyncYouSuffix;

  /// Button label to dissolve the family group
  ///
  /// In en, this message translates to:
  /// **'Dissolve Group'**
  String get familySyncDissolveGroup;

  /// Relative time label in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String familySyncMinutesAgo(int minutes);

  /// No description provided for @groupDefaultName.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Family'**
  String groupDefaultName(String name);

  /// No description provided for @groupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get groupCreate;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupOwner;

  /// No description provided for @groupMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupMember;

  /// No description provided for @groupInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get groupInviteCode;

  /// No description provided for @groupInviteExpiry.
  ///
  /// In en, this message translates to:
  /// **'Valid for {minutes} minutes'**
  String groupInviteExpiry(int minutes);

  /// No description provided for @groupShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Invite Code'**
  String get groupShareCode;

  /// No description provided for @groupEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Code'**
  String get groupEnterCode;

  /// No description provided for @groupVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get groupVerify;

  /// No description provided for @groupConfirmJoin.
  ///
  /// In en, this message translates to:
  /// **'Confirm Join'**
  String get groupConfirmJoin;

  /// No description provided for @groupJoinTarget.
  ///
  /// In en, this message translates to:
  /// **'Group to Join'**
  String get groupJoinTarget;

  /// No description provided for @groupWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Owner approval...'**
  String get groupWaitingApproval;

  /// No description provided for @groupWaitingDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} is reviewing your request'**
  String groupWaitingDesc(String name);

  /// No description provided for @groupJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'Join request received'**
  String get groupJoinRequest;

  /// No description provided for @groupJoinRequestDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to join'**
  String groupJoinRequestDesc(String name);

  /// No description provided for @groupApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get groupApprove;

  /// No description provided for @groupReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get groupReject;

  /// No description provided for @groupJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get groupJoinSuccess;

  /// No description provided for @groupRename.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get groupRename;

  /// No description provided for @groupRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename'**
  String get groupRenameFailed;

  /// No description provided for @groupSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get groupSyncing;

  /// No description provided for @groupInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get groupInvalidCode;

  /// No description provided for @groupCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Invite code expired'**
  String get groupCodeExpired;

  /// No description provided for @groupMyName.
  ///
  /// In en, this message translates to:
  /// **'My Name'**
  String get groupMyName;

  /// No description provided for @groupEnterGroup.
  ///
  /// In en, this message translates to:
  /// **'Enter Group'**
  String get groupEnterGroup;

  /// No description provided for @groupChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with family'**
  String get groupChoiceTitle;

  /// No description provided for @groupChoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your household budget together'**
  String get groupChoiceSubtitle;

  /// No description provided for @groupCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new family group and invite members'**
  String get groupCreateDesc;

  /// No description provided for @groupJoinDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code to join an existing group'**
  String get groupJoinDesc;

  /// No description provided for @groupE2eeHint.
  ///
  /// In en, this message translates to:
  /// **'Privacy protected with E2E encryption'**
  String get groupE2eeHint;

  /// No description provided for @groupInviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite new member'**
  String get groupInviteMembers;

  /// No description provided for @groupDisband.
  ///
  /// In en, this message translates to:
  /// **'Disband Group'**
  String get groupDisband;

  /// No description provided for @groupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupCancel;

  /// No description provided for @groupWaitingHint1.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the notification'**
  String get groupWaitingHint1;

  /// No description provided for @groupWaitingHint2.
  ///
  /// In en, this message translates to:
  /// **'It\'s safe to close the app'**
  String get groupWaitingHint2;

  /// No description provided for @groupCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the group owner for the invite code'**
  String get groupCodeHint;

  /// No description provided for @groupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get groupBack;

  /// Sync in progress status
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncInProgress;

  /// Sync completed status
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncCompleted;

  /// Sync failed status
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// Retry sync button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncRetry;

  /// Manual sync button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncManual;

  /// Last sync time
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String syncLastTime(String time);

  /// Offline queue count
  ///
  /// In en, this message translates to:
  /// **'{count} changes pending'**
  String syncOfflineQueued(int count);

  /// Initial sync in progress
  ///
  /// In en, this message translates to:
  /// **'Initial sync...'**
  String get syncInitialProgress;

  /// Profile update notification
  ///
  /// In en, this message translates to:
  /// **'{name} updated their profile'**
  String syncProfileUpdated(String name);

  /// Manual sync button label
  ///
  /// In en, this message translates to:
  /// **'Sync Ledger'**
  String get familySyncManualSync;

  /// Manual sync button description
  ///
  /// In en, this message translates to:
  /// **'Manually sync data'**
  String get familySyncManualSyncDesc;

  /// List tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listTab;

  /// Todo tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get todoTab;

  /// Placeholder message for date picker feature
  ///
  /// In en, this message translates to:
  /// **'Date picker coming soon'**
  String get datePickerComingSoon;

  /// Title of language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Option to follow system language setting
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageSystem;

  /// Title shown on the AppInitializer failure fallback screen rendered before the main app mounts
  ///
  /// In en, this message translates to:
  /// **'Initialization failed'**
  String get initFailedTitle;

  /// Body message on the AppInitializer failure fallback screen — explains the failure plainly and points to the retry action. Must NOT include technical error details (those go to console logs)
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while starting the app. Tap retry to try again.'**
  String get initFailedMessage;

  /// Button label on the AppInitializer failure fallback screen. Re-invokes AppInitializer.initialize()
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get initFailedRetry;

  /// Home section title for ledger cards
  ///
  /// In en, this message translates to:
  /// **'Ledgers'**
  String get homeLedgersSection;

  /// Home section title for recent transactions
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get homeRecentTransactions;

  /// Button label to view all transactions from home
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAllTransactions;

  /// Soul card label for the most recent soul ledger expense
  ///
  /// In en, this message translates to:
  /// **'Recent Soul Expense'**
  String get homeRecentSoulExpense;

  /// Voice input permission message shown when microphone access is unavailable
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access'**
  String get voiceMicrophonePermissionRequired;

  /// Analytics section title for budget progress
  ///
  /// In en, this message translates to:
  /// **'Budget Progress'**
  String get analyticsBudgetProgress;

  /// Analytics empty state shown when no budgets are configured
  ///
  /// In en, this message translates to:
  /// **'No budgets set'**
  String get analyticsNoBudgetsSet;

  /// Analytics income summary label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get analyticsIncome;

  /// Analytics expense summary label
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get analyticsExpenses;

  /// Analytics savings summary label
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get analyticsSavings;

  /// Analytics savings rate summary label
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get analyticsSavingsRate;

  /// Analytics category details section title
  ///
  /// In en, this message translates to:
  /// **'Category Details'**
  String get analyticsCategoryDetails;

  /// Analytics transaction count label
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String analyticsTransactionCount(int count);

  /// Analytics daily expenses chart title
  ///
  /// In en, this message translates to:
  /// **'Daily Expenses'**
  String get analyticsDailyExpenses;

  /// Analytics empty state shown when ledger data is unavailable
  ///
  /// In en, this message translates to:
  /// **'No ledger data'**
  String get analyticsNoLedgerData;

  /// Analytics label comparing survival and soul ledger spending
  ///
  /// In en, this message translates to:
  /// **'Survival vs Soul'**
  String get analyticsSurvivalVsSoul;

  /// Analytics six-month trend chart title
  ///
  /// In en, this message translates to:
  /// **'Six-month Trend'**
  String get analyticsSixMonthTrend;

  /// Analytics day number label
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String analyticsDayNumberLabel(int day);

  /// Analytics month number label
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String analyticsMonthNumberLabel(int month);

  /// Budget remaining amount label
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String budgetRemainingAmount(String amount);

  /// Budget exceeded amount label
  ///
  /// In en, this message translates to:
  /// **'Exceeded: {amount}'**
  String budgetExceededAmount(String amount);
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
