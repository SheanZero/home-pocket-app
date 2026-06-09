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

  /// Settings section title for monthly Joy target configuration
  ///
  /// In en, this message translates to:
  /// **'Joy target'**
  String get settingsJoyTargetTitle;

  /// Configured monthly Joy target value in Settings
  ///
  /// In en, this message translates to:
  /// **'Current target: {target}'**
  String settingsJoyTargetCurrentConfigured(int target);

  /// Active recommended monthly Joy target value in Settings
  ///
  /// In en, this message translates to:
  /// **'Active reference: {target}'**
  String settingsJoyTargetCurrentRecommended(int target);

  /// Neutral recommendation copy for monthly Joy target
  ///
  /// In en, this message translates to:
  /// **'Reference from recent Joy patterns: {target}'**
  String settingsJoyTargetRecommendation(int target);

  /// Fallback copy when monthly Joy target recommendation has insufficient data
  ///
  /// In en, this message translates to:
  /// **'Reference target is available after more Joy entries. Using the starter reference for now.'**
  String get settingsJoyTargetFallback;

  /// Input label for monthly Joy target dialog
  ///
  /// In en, this message translates to:
  /// **'Monthly Joy target'**
  String get settingsJoyTargetInputLabel;

  /// Input hint for monthly Joy target dialog
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number'**
  String get settingsJoyTargetInputHint;

  /// Validation error for invalid monthly Joy target input
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number greater than zero.'**
  String get settingsJoyTargetInvalid;

  /// Button to clear configured target and use the recommended or fallback target
  ///
  /// In en, this message translates to:
  /// **'Use reference'**
  String get settingsJoyTargetUseRecommendation;

  /// Save button for monthly Joy target dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsJoyTargetSave;

  /// Cancel button for monthly Joy target dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsJoyTargetCancel;

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

  /// Daily ledger label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyLedger;

  /// Joy ledger label
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get joyLedger;

  /// Short daily label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Short joy label
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get joy;

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

  /// Success feedback shown after saving when the entry screen stays open for continuous entry
  ///
  /// In en, this message translates to:
  /// **'Saved — you can keep recording'**
  String get successKeepGoing;

  /// Inline link in the success toast that exits the entry screen back to the page before recording
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get recordingExitLink;

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

  /// AppBar title for TransactionEditScreen (Phase 18 EDIT-01)
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get transactionEditTitle;

  /// AppBar title for OcrReviewScreen (Phase 18 INPUT-04 architectural slot)
  ///
  /// In en, this message translates to:
  /// **'Review Receipt'**
  String get ocrReviewTitle;

  /// Banner shown on OcrReviewScreen when draft is empty (Phase 18 — MOD-005 writer not landed)
  ///
  /// In en, this message translates to:
  /// **'OCR is not implemented yet — please fill in the fields manually.'**
  String get ocrReviewEmptyDraftBanner;

  /// Snackbar after successful edit save (sibling to transactionSaved)
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionUpdated;

  /// Error snackbar on edit save failure (sibling to failedToSave)
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

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

  /// Week start day setting label
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

  /// Monday option for week start
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settingsWeekStartMonday;

  /// Sunday option for week start
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settingsWeekStartSunday;

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

  /// Daily ledger expense label
  ///
  /// In en, this message translates to:
  /// **'Daily Expenses'**
  String get homeDailyExpense;

  /// Joy ledger expense label
  ///
  /// In en, this message translates to:
  /// **'Joy Expenses'**
  String get homeJoyExpense;

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

  /// Compact home ledger row tag for daily ledger
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get homeDailyLedgerTag;

  /// Compact home ledger row tag for joy ledger
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get homeJoyLedgerTag;

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

  /// Joy fullness section title
  ///
  /// In en, this message translates to:
  /// **'Joy Index'**
  String get homeJoyFullness;

  /// Joy spending percentage metric label
  ///
  /// In en, this message translates to:
  /// **'Joy spending ratio'**
  String get homeJoyPercentLabel;

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

  /// Family invite banner heading text
  ///
  /// In en, this message translates to:
  /// **'Manage Together'**
  String get homeFamilyBannerTitle;

  /// Family invite banner subtitle text
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to share your ledger in real time'**
  String get homeFamilyBannerSubtitle;

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

  /// Bottom nav shopping tab label
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get homeTabShopping;

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

  /// Recent joy transaction summary
  ///
  /// In en, this message translates to:
  /// **'Recent: {merchant} ¥{amount}'**
  String homeRecentJoyTransaction(String merchant, int amount);

  /// Joy charge card status line
  ///
  /// In en, this message translates to:
  /// **'Joy Fullness {fullness}% · Joy Index {roi}'**
  String homeJoyChargeStatus(int fullness, double roi);

  /// Joy fullness month badge
  ///
  /// In en, this message translates to:
  /// **'This month {percent}%'**
  String homeMonthBadge(int percent);

  /// Tooltip explaining the 3-ring system on the HomeHeroCard (D-10 tooltip 1)
  ///
  /// In en, this message translates to:
  /// **'Outer ring is monthly Joy Index toward your active target; middle is average satisfaction; inner is highlights count (satisfaction >= 6).'**
  String get homeJoyIndexTooltip;

  /// Tooltip explaining the HomeHero three-ring system after ADR-016
  ///
  /// In en, this message translates to:
  /// **'Outer ring is monthly Joy Index toward your active target; middle is average satisfaction; inner is highlights count.'**
  String get homeJoyContributionTooltip;

  /// Compact HomeHero target reference under cumulative Joy value
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String homeJoyTargetReference(int target);

  /// Screen reader label for HomeHero cumulative Joy and active target
  ///
  /// In en, this message translates to:
  /// **'Joy Index {value} of target {target}'**
  String homeJoyTargetSemantics(String value, int target);

  /// Hero header label — single mode (D-02)
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get homeHeroCardLabelSingle;

  /// Hero header label — group mode (D-02)
  ///
  /// In en, this message translates to:
  /// **'Family This Month'**
  String get homeHeroCardLabelGroup;

  /// Hero header previous-month sub-line
  ///
  /// In en, this message translates to:
  /// **'Last month (same period) {amount}'**
  String homeHeroPreviousMonthSubline(String amount);

  /// Ring section title — single mode (fallback if reusing homeJoyFullness is rejected)
  ///
  /// In en, this message translates to:
  /// **'Joy Index'**
  String get homeRingSectionTitleSingle;

  /// Ring section title — group mode
  ///
  /// In en, this message translates to:
  /// **'Family Joy'**
  String get homeRingSectionTitleGroup;

  /// Best Joy tag — single mode (D-04)
  ///
  /// In en, this message translates to:
  /// **'Top of the Month'**
  String get homeBestJoyTagSingle;

  /// Best Joy tag — group mode (same copy as Single per D-04, separate key for future flexibility)
  ///
  /// In en, this message translates to:
  /// **'Top of the Month'**
  String get homeBestJoyTagGroup;

  /// Best Joy strip small line composing amount and satisfaction (D-04)
  ///
  /// In en, this message translates to:
  /// **'{amount} · Satisfaction {sat}/10 ✨'**
  String homeBestJoyAmountSat(String amount, int sat);

  /// Group-mode member rows subheader
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get homeMembersSectionTitle;

  /// Legend rows when totalJoyTx == 0 (D-09)
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get homeNoJoyDataLegend;

  /// Best Joy CTA variant tag (same copy as homeBestJoyTagSingle but separate key)
  ///
  /// In en, this message translates to:
  /// **'Top of the Month'**
  String get homeBestJoyEmptyTagPrimary;

  /// Best Joy BIG line — totalJoyTx == 0 empty state (D-09)
  ///
  /// In en, this message translates to:
  /// **'Record your first joy-ledger entry'**
  String get homeBestJoyEmptyBig;

  /// Best Joy small line — totalJoyTx == 0 empty state (D-09)
  ///
  /// In en, this message translates to:
  /// **'Your monthly favorite will appear here →'**
  String get homeBestJoyEmptySmall;

  /// Best Joy BIG line — all-neutral state (topJoy joyFullness <= 2) (D-09)
  ///
  /// In en, this message translates to:
  /// **'Rate your biggest spend'**
  String get homeBestJoyAllNeutralBig;

  /// Best Joy small line — all-neutral state (D-09)
  ///
  /// In en, this message translates to:
  /// **'Make it your monthly favorite'**
  String get homeBestJoyAllNeutralSmall;

  /// Single-mode mid-ring legend label
  ///
  /// In en, this message translates to:
  /// **'Avg satisfaction'**
  String get homeAvgSatisfactionLegend;

  /// Single-mode outer-ring legend label for monthly Joy target progress
  ///
  /// In en, this message translates to:
  /// **'Joy Index target'**
  String get homeJoyContributionLegend;

  /// Single-mode inner-ring legend label (count is shown on the right column in UI)
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get homeHighlightsCountLegend;

  /// Group-mode outer-ring legend label
  ///
  /// In en, this message translates to:
  /// **'Family highlights'**
  String get homeFamilyHighlightsLegend;

  /// Group-mode mid-ring legend label
  ///
  /// In en, this message translates to:
  /// **'Shared joy'**
  String get homeSharedJoyLegend;

  /// Group-mode inner-ring legend label
  ///
  /// In en, this message translates to:
  /// **'Median satisfaction'**
  String get homeMedianSatisfactionLegend;

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

  /// Soft-keyboard accessory toolbar dismiss button (Phase 19)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keyboardToolbarDone;

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
  /// **'Purpose'**
  String get expenseClassification;

  /// Daily ledger chip label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyExpense;

  /// Joy ledger chip label
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get joyExpense;

  /// Joy fullness slider label
  ///
  /// In en, this message translates to:
  /// **'Joy Fullness'**
  String get joyFullness;

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
  /// **'Neutral'**
  String get satisfactionBad;

  /// Second lowest satisfaction label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get satisfactionSlightlyBad;

  /// Neutral satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get satisfactionNormal;

  /// Positive satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get satisfactionGood;

  /// High satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get satisfactionVeryGood;

  /// Highest satisfaction label
  ///
  /// In en, this message translates to:
  /// **'Amazing!'**
  String get satisfactionExcellent;

  /// Variant A pill label: val 2, unipolar positive baseline (ADR-014)
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get satisfactionLabelNeutral;

  /// Variant A pill label: val 4
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get satisfactionLabelOK;

  /// Variant A pill label: val 6
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get satisfactionLabelGood;

  /// Variant A pill label: val 8
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get satisfactionLabelGreat;

  /// Variant A pill label: val 10, top tier
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get satisfactionLabelAmazing;

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

  /// Dialog body when cancelling reorder with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Your reordering will not be saved and will revert.'**
  String get discardUnsavedChangesBody;

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

  /// Voice idle caption: hold to speak (push-to-talk)
  ///
  /// In en, this message translates to:
  /// **'Hold to speak'**
  String get holdToRecord;

  /// Voice recording-state caption
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get recording;

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

  /// Joy card label for the most recent joy ledger expense
  ///
  /// In en, this message translates to:
  /// **'Recent Joy Expense'**
  String get homeRecentJoyExpense;

  /// Voice input permission message shown when microphone access is unavailable
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access'**
  String get voiceMicrophonePermissionRequired;

  /// Voice recognition error: network unavailable (platform error_network / error_network_timeout)
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the network. Please check your connection and try again'**
  String get voiceRecognitionErrorNetwork;

  /// Voice recognition error: no transcription returned (platform error_no_match)
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Please try again'**
  String get voiceRecognitionErrorNoMatch;

  /// Voice recognition error: audio capture failure (platform error_audio)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read audio from the microphone'**
  String get voiceRecognitionErrorAudio;

  /// Voice recognition error: unknown / fallback (platform error_speech_timeout / error_client / other)
  ///
  /// In en, this message translates to:
  /// **'Voice recognition error occurred'**
  String get voiceRecognitionErrorUnknown;

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

  /// Analytics label comparing daily and joy ledger spending
  ///
  /// In en, this message translates to:
  /// **'Daily vs Joy'**
  String get analyticsDailyVsJoy;

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

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get analyticsTitle;

  /// Analytics screen time-window selector chip tooltip
  ///
  /// In en, this message translates to:
  /// **'Pick a time window'**
  String get analyticsTimeWindowChipTooltip;

  /// AppBar chip label for manual-vs-all entries audit toggle (Phase 17)
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get analyticsJoyMetricVariantChipLabel;

  /// Bottom sheet title for the entries-source filter
  ///
  /// In en, this message translates to:
  /// **'Joy metric variant'**
  String get analyticsJoyMetricVariantSheetTitle;

  /// Option label: include voice and manual entries
  ///
  /// In en, this message translates to:
  /// **'All entries'**
  String get analyticsJoyMetricVariantOptionAll;

  /// Option label: exclude voice-estimated entries for audit mode
  ///
  /// In en, this message translates to:
  /// **'Manual entries only'**
  String get analyticsJoyMetricVariantOptionManualOnly;

  /// One-line explanation appended to the manualOnly option; descriptive copy, not judgmental
  ///
  /// In en, this message translates to:
  /// **'Manual entries only · excludes voice-estimated entries'**
  String get analyticsJoyMetricVariantManualOnlyExplain;

  /// Analytics screen time-window selector week chip label
  ///
  /// In en, this message translates to:
  /// **'Week of {monday}'**
  String analyticsTimeWindowChipLabelWeek(String monday);

  /// Analytics screen time-window selector quarter chip label
  ///
  /// In en, this message translates to:
  /// **'Q{q} {year}'**
  String analyticsTimeWindowChipLabelQuarter(String q, String year);

  /// Analytics screen time-window selector year chip label
  ///
  /// In en, this message translates to:
  /// **'{year}'**
  String analyticsTimeWindowChipLabelYear(String year);

  /// Analytics screen time-window selector custom range chip label
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String analyticsTimeWindowChipLabelCustom(String start, String end);

  /// Analytics screen time-window picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get analyticsTimeWindowSheetTitle;

  /// Analytics screen time-window type option for week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsTimeWindowTypeWeek;

  /// Analytics screen time-window type option for month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get analyticsTimeWindowTypeMonth;

  /// Analytics screen time-window type option for quarter
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get analyticsTimeWindowTypeQuarter;

  /// Analytics screen time-window type option for year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get analyticsTimeWindowTypeYear;

  /// Analytics screen time-window type option for custom range
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get analyticsTimeWindowTypeCustom;

  /// Analytics screen time-window custom range picker call to action
  ///
  /// In en, this message translates to:
  /// **'Pick a date range'**
  String get analyticsTimeWindowCustomCta;

  /// Analytics screen time-window validation error for overlong ranges
  ///
  /// In en, this message translates to:
  /// **'Range cannot exceed 12 months. Pick a shorter range.'**
  String get analyticsTimeWindowErrorTooLong;

  /// Analytics screen time-window validation error for inverted date ranges
  ///
  /// In en, this message translates to:
  /// **'Start date must be before end date.'**
  String get analyticsTimeWindowErrorInverted;

  /// Analytics screen time-window validation error for future end dates
  ///
  /// In en, this message translates to:
  /// **'End date cannot be in the future.'**
  String get analyticsTimeWindowErrorFutureEnd;

  /// Analytics screen time-window picker empty preset list message
  ///
  /// In en, this message translates to:
  /// **'No data yet for this view. Add a transaction to begin.'**
  String get analyticsTimeWindowEmptyPreset;

  /// No description provided for @analyticsKpiTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total spending'**
  String get analyticsKpiTotalLabel;

  /// No description provided for @analyticsKpiJoyLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg satisfaction'**
  String get analyticsKpiJoyLabel;

  /// KPI mini-hero 悦己平均 sub-line: median + coverage (STATSUI-03)
  ///
  /// In en, this message translates to:
  /// **'Median {median} · n={k}/{N}'**
  String analyticsKpiJoySubMedianCoverage(String median, int k, int N);

  /// Screen reader label for the joy headline KPI tile
  ///
  /// In en, this message translates to:
  /// **'Joy {label} {value} n={rated}/{total}'**
  String analyticsKpiJoySemantics(
    String label,
    String value,
    int rated,
    int total,
  );

  /// No description provided for @analyticsKpiJoyEmptyCaption.
  ///
  /// In en, this message translates to:
  /// **'Gathering data...'**
  String get analyticsKpiJoyEmptyCaption;

  /// Analytics KPI label for cumulative Joy Index
  ///
  /// In en, this message translates to:
  /// **'Joy Index'**
  String get analyticsKpiJoyIndexLabel;

  /// Empty state caption for Analytics Joy Index KPI
  ///
  /// In en, this message translates to:
  /// **'Joy Index appears after you rate joy-ledger entries.'**
  String get analyticsKpiJoyIndexEmptyCaption;

  /// Screen reader label for Analytics Joy Index KPI
  ///
  /// In en, this message translates to:
  /// **'{label} {value}, {ratedCount} rated of {totalCount} joy entries'**
  String analyticsKpiJoyIndexSemantics(
    String label,
    String value,
    int ratedCount,
    int totalCount,
  );

  /// Supporting median and coverage copy for Analytics Joy Index KPI
  ///
  /// In en, this message translates to:
  /// **'Median {median} · rated {ratedCount}/{totalCount}'**
  String analyticsKpiJoyIndexSubMedianCoverage(
    String median,
    int ratedCount,
    int totalCount,
  );

  /// No description provided for @analyticsGroupHeaderTime.
  ///
  /// In en, this message translates to:
  /// **'━ Time ━'**
  String get analyticsGroupHeaderTime;

  /// No description provided for @analyticsGroupHeaderDistribution.
  ///
  /// In en, this message translates to:
  /// **'━ Distribution ━'**
  String get analyticsGroupHeaderDistribution;

  /// No description provided for @analyticsGroupHeaderStories.
  ///
  /// In en, this message translates to:
  /// **'━ Stories ━'**
  String get analyticsGroupHeaderStories;

  /// No description provided for @analyticsCardTitleTotalSixMonth.
  ///
  /// In en, this message translates to:
  /// **'Total · 6-month trend'**
  String get analyticsCardTitleTotalSixMonth;

  /// No description provided for @analyticsCardCaptionTotalSixMonth.
  ///
  /// In en, this message translates to:
  /// **'BarChart · current month highlighted'**
  String get analyticsCardCaptionTotalSixMonth;

  /// No description provided for @analyticsCardTitleCategoryDonut.
  ///
  /// In en, this message translates to:
  /// **'Total · Category breakdown'**
  String get analyticsCardTitleCategoryDonut;

  /// No description provided for @analyticsCardCaptionCategoryDonut.
  ///
  /// In en, this message translates to:
  /// **'Donut/PieChart · top-N + Other'**
  String get analyticsCardCaptionCategoryDonut;

  /// No description provided for @analyticsCategoryDonutOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get analyticsCategoryDonutOther;

  /// No description provided for @analyticsCardTitleSatisfactionHistogram.
  ///
  /// In en, this message translates to:
  /// **'Joy · Satisfaction distribution 1–10'**
  String get analyticsCardTitleSatisfactionHistogram;

  /// No description provided for @analyticsCardCaptionHistogram.
  ///
  /// In en, this message translates to:
  /// **'Histogram · cool→warm · 5-bar trilingual annotation'**
  String get analyticsCardCaptionHistogram;

  /// Permanent annotation above bar 5 of satisfaction histogram acknowledging default-5 cluster + East-Asian central-tendency clustering (STATSUI-02 HARD-LOCKED)
  ///
  /// In en, this message translates to:
  /// **'Median + unrated'**
  String get analyticsHistogramBarFiveAnnotation;

  /// No description provided for @analyticsHistogramColorCaption.
  ///
  /// In en, this message translates to:
  /// **'Colors are ordinal only'**
  String get analyticsHistogramColorCaption;

  /// No description provided for @analyticsCardTitleLargestExpense.
  ///
  /// In en, this message translates to:
  /// **'Total · Largest expense'**
  String get analyticsCardTitleLargestExpense;

  /// Largest monthly expense story card body
  ///
  /// In en, this message translates to:
  /// **'{categoryName} · {amount} · {date}'**
  String analyticsCardLargestExpenseBody(
    String categoryName,
    String amount,
    String date,
  );

  /// No description provided for @analyticsCardEmptyLargestExpense.
  ///
  /// In en, this message translates to:
  /// **'No data — no expenses logged yet'**
  String get analyticsCardEmptyLargestExpense;

  /// No description provided for @analyticsCardTitleBestJoy.
  ///
  /// In en, this message translates to:
  /// **'Joy · Best Joy moment'**
  String get analyticsCardTitleBestJoy;

  /// Best Joy story strip big line
  ///
  /// In en, this message translates to:
  /// **'{categoryName} · {date}'**
  String analyticsCardBestJoyBig(String categoryName, String date);

  /// Best Joy story strip small line
  ///
  /// In en, this message translates to:
  /// **'{amount} · sat {sat}/10 ✨'**
  String analyticsCardSmallBestJoy(String amount, int sat);

  /// No description provided for @analyticsCardEmptyBestJoy.
  ///
  /// In en, this message translates to:
  /// **'No standout Joy yet'**
  String get analyticsCardEmptyBestJoy;

  /// No description provided for @analyticsCardTitleFamilyInsight.
  ///
  /// In en, this message translates to:
  /// **'Family · Highlights Summary'**
  String get analyticsCardTitleFamilyInsight;

  /// Family highlights aggregate sentence
  ///
  /// In en, this message translates to:
  /// **'{N} family Highlights'**
  String analyticsFamilyHighlightsSentence(int N);

  /// Family shared joy insight sentence
  ///
  /// In en, this message translates to:
  /// **'You all love [{categoryName}] (n={count}, avg {avg}/10)'**
  String analyticsFamilySharedJoySentence(
    String categoryName,
    int count,
    String avg,
  );

  /// No description provided for @analyticsFamilyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared favorite yet — keep logging Joy entries'**
  String get analyticsFamilyEmpty;

  /// No description provided for @analyticsThinSampleFallbackHeading.
  ///
  /// In en, this message translates to:
  /// **'Not enough Joy entries yet'**
  String get analyticsThinSampleFallbackHeading;

  /// No description provided for @analyticsThinSampleFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Keep logging — your Joy pattern shows up after a few days'**
  String get analyticsThinSampleFallbackBody;

  /// No description provided for @analyticsThinSampleFallbackCta.
  ///
  /// In en, this message translates to:
  /// **'Add an entry »'**
  String get analyticsThinSampleFallbackCta;

  /// No description provided for @analyticsCardErrorHeading.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get analyticsCardErrorHeading;

  /// No description provided for @analyticsCardErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment'**
  String get analyticsCardErrorBody;

  /// No description provided for @analyticsCardErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get analyticsCardErrorRetry;

  /// No description provided for @analyticsCardTitlePerCategoryJoy.
  ///
  /// In en, this message translates to:
  /// **'Joy · Categories'**
  String get analyticsCardTitlePerCategoryJoy;

  /// No description provided for @analyticsCardTitlePerCategoryJoyYou.
  ///
  /// In en, this message translates to:
  /// **'Joy · Your categories'**
  String get analyticsCardTitlePerCategoryJoyYou;

  /// No description provided for @analyticsCardTitlePerCategoryJoyFamily.
  ///
  /// In en, this message translates to:
  /// **'Joy · Family categories'**
  String get analyticsCardTitlePerCategoryJoyFamily;

  /// Per-category breakdown row format: category name, average satisfaction, entry count
  ///
  /// In en, this message translates to:
  /// **'{categoryName} · {avgSat} avg / {count} entries'**
  String analyticsPerCategoryRow(String categoryName, String avgSat, int count);

  /// Per-category breakdown 'Other' fold row (entries beyond top-N)
  ///
  /// In en, this message translates to:
  /// **'Other: {totalCount} entries across {categoryCount} categories'**
  String analyticsPerCategoryOtherFold(int totalCount, int categoryCount);

  /// No description provided for @analyticsPerCategoryShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get analyticsPerCategoryShowAll;

  /// No description provided for @analyticsPerCategoryShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get analyticsPerCategoryShowLess;

  /// No description provided for @analyticsCardTitleLedgerThisWindow.
  ///
  /// In en, this message translates to:
  /// **'Ledger · This window'**
  String get analyticsCardTitleLedgerThisWindow;

  /// No description provided for @analyticsLedgerColumnJoy.
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get analyticsLedgerColumnJoy;

  /// No description provided for @analyticsLedgerColumnDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get analyticsLedgerColumnDaily;

  /// No description provided for @analyticsLedgerRowYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get analyticsLedgerRowYou;

  /// No description provided for @analyticsLedgerRowFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get analyticsLedgerRowFamily;

  /// Ledger card cell metric: entry count
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String analyticsLedgerCellEntries(int count);

  /// Ledger card cell metric: average satisfaction (Joy column only). avgSat is a pre-formatted decimal string.
  ///
  /// In en, this message translates to:
  /// **'{avgSat} avg satisfaction'**
  String analyticsLedgerCellAvgSat(String avgSat);

  /// No description provided for @analyticsPerCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No category data this window'**
  String get analyticsPerCategoryEmpty;

  /// No description provided for @analyticsLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data this window'**
  String get analyticsLedgerEmpty;

  /// No description provided for @analyticsLedgerFamilyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Family data not available this window'**
  String get analyticsLedgerFamilyEmpty;

  /// No description provided for @analyticsLedgerFamilyError.
  ///
  /// In en, this message translates to:
  /// **'Family data unavailable'**
  String get analyticsLedgerFamilyError;

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

  /// Calendar header: monthly expense total label (Phase 27 placeholder)
  ///
  /// In en, this message translates to:
  /// **'Monthly Spend'**
  String get calMonthTotal;

  /// Calendar day-tap summary: daily expense total label (Phase 27 placeholder)
  ///
  /// In en, this message translates to:
  /// **'{date} Spend'**
  String calDayTotal(String date);

  /// Calendar error state: unable to load data (Phase 27 placeholder)
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get calLoadError;

  /// Sort chip label: sort by transaction date (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get listSortDate;

  /// Sort chip label: sort by edit/created time (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Edit time'**
  String get listSortEditTime;

  /// Sort chip label: sort by amount (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get listSortAmount;

  /// Ledger filter chip: show all ledger types (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get listLedgerAll;

  /// Ledger filter chip: show Daily ledger only (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get listLedgerDaily;

  /// Ledger filter chip: show Joy ledger only (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get listLedgerJoy;

  /// Category filter chip label when no categories selected (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get listCategoryChip;

  /// Category filter chip label when N categories selected (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Categories ({n})'**
  String listCategoryChipN(int n);

  /// Search field hint text in sort/filter bar (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get listSearchHint;

  /// Clear all filters chip label in sort/filter bar (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get listClearAll;

  /// Mine-only filter chip label in family group mode (Phase 29)
  ///
  /// In en, this message translates to:
  /// **'Mine only'**
  String get listMineOnly;

  /// Swipe-to-delete confirmation dialog title (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get listDeleteConfirmTitle;

  /// Swipe-to-delete confirmation dialog body text (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'This entry will be deleted and cannot be undone.'**
  String get listDeleteConfirmBody;

  /// Cancel button in swipe-to-delete confirmation dialog (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get listDeleteCancelButton;

  /// Confirm delete button in swipe-to-delete confirmation dialog (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get listDeleteConfirmButton;

  /// Post-delete SnackBar message (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get listDeletedSnackBar;

  /// Category filter sheet title (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get listCategorySheetTitle;

  /// Clear all selections button in category filter sheet (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get listCategorySheetClear;

  /// Apply button in category filter sheet when 0 categories selected (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get listCategorySheetApply;

  /// Apply button with count in category filter sheet (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Apply ({n})'**
  String listCategorySheetApplyN(int n);

  /// Empty state when no transactions in selected month (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'No records yet this month'**
  String get listEmptyMonth;

  /// Empty state when filters return no results (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'No records match your filters'**
  String get listEmptyFiltered;

  /// Clear filters action in filtered-empty state (Phase 28)
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get listEmptyFilteredClear;

  /// Empty state when day filter active and no transactions on that day (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'No records on this day'**
  String get listEmptyDay;

  /// Clear day filter action in day-empty state (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'Show full month'**
  String get listEmptyDayClear;

  /// Error state when list data fails to load (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get listLoadError;

  /// Semantics label for previous month button in calendar header (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get listCalNavPrev;

  /// Semantics label for next month button in calendar header (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get listCalNavNext;

  /// Semantics label for return to current month gesture in calendar header (Phase 30)
  ///
  /// In en, this message translates to:
  /// **'Return to current month'**
  String get listCalNavCurrentMonth;

  /// Title of the confirm dialog when swiping to delete a shopping item (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get shoppingDeleteConfirmTitle;

  /// Body text of the confirm dialog when swiping to delete a shopping item (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'This item will be removed from your shopping list.'**
  String get shoppingDeleteConfirmBody;

  /// Confirm button label in the delete shopping item dialog (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shoppingDeleteConfirmButton;

  /// Cancel button label in the delete shopping item dialog (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shoppingDeleteCancelButton;

  /// Success toast shown after deleting a shopping item (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get shoppingDeletedSnackBar;

  /// Semantics label for the edit chevron button on a shopping item tile (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shoppingEditItem;

  /// Semantics label for the drag handle on a shopping item tile (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Reorder item'**
  String get shoppingReorderItem;

  /// Semantics label for the leading circular completion toggle on a shopping item tile (EC2)
  ///
  /// In en, this message translates to:
  /// **'Toggle complete'**
  String get shoppingToggleComplete;

  /// Semantics/tooltip for the filter-bar reorder entry (≡) that enters manual drag-reorder mode (EC2 D-2)
  ///
  /// In en, this message translates to:
  /// **'Reorder list'**
  String get shoppingEnterReorderMode;

  /// Semantics/tooltip for the filter-bar reorder exit (✓) that leaves manual drag-reorder mode (EC2 D-2)
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get shoppingExitReorderMode;

  /// Tooltip/semantics label for the move-item-to-top button in sort mode (quick-260609-pmc)
  ///
  /// In en, this message translates to:
  /// **'Move to top'**
  String get shoppingMoveToTop;

  /// Tooltip/semantics label for the move-item-to-bottom button in sort mode (quick-260609-pmc)
  ///
  /// In en, this message translates to:
  /// **'Move to bottom'**
  String get shoppingMoveToBottom;

  /// Shopping empty state heading — private list (Phase 38; values Phase 39)
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingEmptyPrivateHeading;

  /// Shopping empty state body — private list (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first item'**
  String get shoppingEmptyPrivateBody;

  /// Shopping empty state heading — public list, no family group (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Your public list is empty'**
  String get shoppingEmptyPublicSoloHeading;

  /// Shopping empty state body — public list, no family (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Add items to share with family'**
  String get shoppingEmptyPublicSoloBody;

  /// Shopping empty state heading — public list, family joined (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get shoppingEmptyPublicFamilyHeading;

  /// Shopping empty state body — public list, family joined (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Anyone can add — be the first'**
  String get shoppingEmptyPublicFamilyBody;

  /// Shopping empty state CTA button label (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get shoppingEmptyCta;

  /// Shopping filter bar — show all ledger types chip (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shoppingFilterLedgerAll;

  /// Shopping filter bar — active items only chip (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Active only'**
  String get shoppingFilterStatusActive;

  /// Shopping filter bar — all items including completed (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get shoppingFilterStatusAll;

  /// Shopping filter bar — category chip label (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shoppingFilterCategory;

  /// Shopping item form — public (shared) list option label
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get shoppingSegmentPublic;

  /// Shopping list view toggle — All segment (merges private + public)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shoppingSegmentAll;

  /// Shopping filter chip and form selector — private (local-only) list label
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get shoppingSegmentPrivate;

  /// Shopping filter bar chip — shows only private (local-only) items
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get shoppingFilterPrivate;

  /// Shopping item form — list-type (private/public) selector label
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get shoppingFormListTypeLabel;

  /// Shopping item form — caption shown under the disabled list-type selector in edit mode
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed after creation'**
  String get shoppingListTypeLockedHint;

  /// Divider label between active and completed shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get shoppingCompletedDivider;

  /// Confirmation dialog title for clear-all-completed shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Clear all completed?'**
  String get shoppingClearCompletedTitle;

  /// Confirmation dialog body for clear-all-completed shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'All completed items will be removed from the list.'**
  String get shoppingClearCompletedBody;

  /// Confirmation button label for clear-all-completed shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get shoppingClearCompletedConfirm;

  /// Success toast shown after clearing all completed shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Completed items cleared'**
  String get shoppingClearCompletedSnackBar;

  /// Error message shown when shopping list fails to load (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your list'**
  String get shoppingListLoadError;

  /// Retry button label for shopping list load error (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shoppingRetry;

  /// Batch delete confirmation dialog title (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete items?'**
  String get shoppingBatchDeleteTitle;

  /// Batch delete confirmation dialog body with item count (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected items?'**
  String shoppingBatchDeleteBody(int count);

  /// Confirm button label for batch delete (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shoppingBatchDeleteConfirm;

  /// Success toast shown after batch deleting shopping items (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Items deleted'**
  String get shoppingBatchDeletedSnackBar;

  /// Batch action bar delete button label (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shoppingBatchDeleteAction;

  /// Cancel button in the batch selection header (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shoppingBatchCancel;

  /// Select-all button in the batch selection header (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get shoppingBatchSelectAll;

  /// Selected item count shown in the batch selection header (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String shoppingSelectionCount(int count);

  /// Selected item count label in the batch action bar (Phase 38)
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String shoppingBatchSelectingCount(int count);

  /// AppBar title for the shopping item form in create mode (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingFormAddTitle;

  /// AppBar title for the shopping item form in edit mode (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shoppingFormEditTitle;

  /// Save button label in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get shoppingFormSave;

  /// Label for the item name field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get shoppingFormNameLabel;

  /// Validation error when item name is empty in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get shoppingFormNameRequired;

  /// Section label for the ledger type selector in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get shoppingFormLedgerLabel;

  /// Label for the category field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shoppingFormCategoryLabel;

  /// Placeholder when no category is selected in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get shoppingFormNoCategorySelected;

  /// Button label to open the category picker in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get shoppingFormChangeCategory;

  /// Label for the tags field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get shoppingFormTagsLabel;

  /// Label for the note field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get shoppingFormNoteLabel;

  /// Label for the quantity field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shoppingFormQuantityLabel;

  /// Label for the estimated price field in the shopping item form (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get shoppingFormPrice;

  /// Error message shown when saving a shopping item fails (Phase 38-07)
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get shoppingFormSaveError;
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
