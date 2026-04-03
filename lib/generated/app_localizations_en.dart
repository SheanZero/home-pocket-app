// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Home Pocket';

  @override
  String get home => 'Home';

  @override
  String get transactions => 'Transactions';

  @override
  String get analytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get ledger => 'Ledger';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get note => 'Note';

  @override
  String get merchant => 'Merchant';

  @override
  String get date => 'Date';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryOther => 'Other';

  @override
  String get survivalLedger => 'Survival Ledger';

  @override
  String get soulLedger => 'Soul Ledger';

  @override
  String get survival => 'Survival';

  @override
  String get soul => 'Soul';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get errorInvalidAmount => 'Invalid amount';

  @override
  String get errorRequired => 'This field is required';

  @override
  String get errorInvalidDate => 'Invalid date';

  @override
  String get errorDatabaseWrite => 'Database write error';

  @override
  String get errorDatabaseRead => 'Database read error';

  @override
  String get errorEncryption => 'Encryption error';

  @override
  String get errorSync => 'Sync error';

  @override
  String get errorBiometric => 'Biometric error';

  @override
  String get errorPermission => 'Permission error';

  @override
  String errorMinAmount(double min) {
    return 'Please enter an amount of at least $min';
  }

  @override
  String errorMaxAmount(double max) {
    return 'Please enter an amount no greater than $max';
  }

  @override
  String get successSaved => 'Saved successfully';

  @override
  String get successDeleted => 'Deleted successfully';

  @override
  String get successSynced => 'Synced successfully';

  @override
  String get merchantPlaceholder => 'Enter merchant name';

  @override
  String get notePlaceholder => 'Enter a note';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get amountMustBeGreaterThanZero => 'Amount must be greater than zero';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get tapToAddFirstTransaction => 'Tap + to add your first transaction';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get security => 'Security';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get biometricLockDescription => 'Use Face ID / fingerprint to unlock';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription => 'Budget alerts and sync notifications';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupDescription => 'Create encrypted backup file';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupDescription => 'Restore from backup file';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataDescription => 'Permanently delete all records';

  @override
  String get deleteAllDataConfirmation =>
      'This action cannot be undone. Are you sure you want to delete all data?';

  @override
  String get allDataDeleted => 'All data deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get backupExportedSuccessfully => 'Backup exported successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get backupImportedSuccessfully => 'Backup imported successfully';

  @override
  String get importFailed => 'Import failed';

  @override
  String get setBackupPassword => 'Set Backup Password';

  @override
  String get enterBackupPassword => 'Enter Backup Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get generateDemoData => 'Generate Demo Data';

  @override
  String get generateDemoDataDescription =>
      'This will create sample transactions for the last 3 months to showcase analytics features.';

  @override
  String get generate => 'Generate';

  @override
  String get demoDataGenerated => 'Demo data generated! Pull to refresh.';

  @override
  String get language => 'Language';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteTransactionConfirmation => 'Delete this transaction?';

  @override
  String get error => 'Error';

  @override
  String get initializationError => 'Failed to initialize app';

  @override
  String get homeMonthlyExpense => 'Monthly Expenses';

  @override
  String get homeSurvivalExpense => 'Living Expenses';

  @override
  String get homeSoulExpense => 'Joy Expenses';

  @override
  String get homeMonthComparison => 'vs Last Month';

  @override
  String get homeSoulFullness => 'Soul Fullness';

  @override
  String get homeSoulPercentLabel => 'Soul spending ratio';

  @override
  String get homeHappinessROI => 'Happiness ROI';

  @override
  String get homeFamilyInviteTitle => 'Invite Family';

  @override
  String get homeFamilyInviteDesc => 'Share your ledger with your partner';

  @override
  String get homeTodayTitle => 'Today\'s Records';

  @override
  String homeTodayCount(int count) {
    return '$count items';
  }

  @override
  String get homePersonalMode => 'Personal Mode';

  @override
  String get homeFamilyMode => 'Family Mode';

  @override
  String get homeTabHome => 'Home';

  @override
  String get homeTabList => 'List';

  @override
  String get homeTabChart => 'Charts';

  @override
  String get homeTabTodo => 'Todo';

  @override
  String homeMonthFormat(int year, int month) {
    return '$year/$month';
  }

  @override
  String homeMonthLabel(int month) {
    return 'M$month';
  }

  @override
  String homeRecentSoulTransaction(String merchant, int amount) {
    return 'Recent: $merchant ¥$amount';
  }

  @override
  String homeSoulChargeStatus(int fullness, double roi) {
    return 'Soul Fullness $fullness% · Happiness ROI ${roi}x';
  }

  @override
  String homeMonthBadge(int percent) {
    return 'This month $percent%';
  }

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get manualInput => 'Manual';

  @override
  String get ocrScan => 'OCR';

  @override
  String get voiceInput => 'Voice';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get searchCategory => 'Search categories...';

  @override
  String get expenseDetail => 'Expense Detail';

  @override
  String get back => 'Back';

  @override
  String get record => 'Record';

  @override
  String get enterStore => 'Enter store';

  @override
  String get enterMemo => 'Enter memo...';

  @override
  String get expenseClassification => 'Expense Type';

  @override
  String get survivalExpense => 'Survival';

  @override
  String get soulExpense => 'Soul';

  @override
  String get soulSatisfaction => 'Soul Fullness';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get ocrScanTitle => 'OCR Scan';

  @override
  String get ocrHint => 'Place receipt in frame';

  @override
  String get voiceRecognitionResult => 'Recognition Result';

  @override
  String get recognitionResult => 'Recognition result';

  @override
  String get satisfactionLevel => 'Satisfaction';

  @override
  String get satisfactionBad => 'Bad';

  @override
  String get satisfactionSlightlyBad => 'Slightly bad';

  @override
  String get satisfactionNormal => 'Normal';

  @override
  String get satisfactionGood => 'Good';

  @override
  String get satisfactionVeryGood => 'Very good';

  @override
  String get satisfactionExcellent => 'Excellent!';

  @override
  String get addSubcategory => 'Add';

  @override
  String get addCategory => 'Add category';

  @override
  String get tapToRecord => 'Tap to record';

  @override
  String get todayDate => 'Today';

  @override
  String get next => 'Next';

  @override
  String get voiceInputSettings => 'Voice Recognition';

  @override
  String get voiceLanguage => 'Recognition Language';

  @override
  String get voiceLanguageSubtitle => 'Language used for speech-to-text';

  @override
  String get familySync => 'Family Sync';

  @override
  String get familySyncShowMyCode => 'Create Group';

  @override
  String get familySyncEnterPartnerCode => 'Join Group';

  @override
  String get familySyncPairCode => 'Invite Code';

  @override
  String get familySyncScanOrEnter =>
      'Share this invite code or QR with a family member to let them join your group';

  @override
  String get familySyncCodeExpired => 'Code expired';

  @override
  String get familySyncRegenerate => 'Regenerate';

  @override
  String get familySyncEnterDigitCode => 'Enter 6-digit invite code';

  @override
  String get familySyncSubmit => 'Submit';

  @override
  String get familySyncPairedDevice => 'Family Group';

  @override
  String get familySyncPairInfo => 'Group Info';

  @override
  String get familySyncPairId => 'Group ID';

  @override
  String get familySyncPairedSince => 'Paired since';

  @override
  String get familySyncBookId => 'Book ID';

  @override
  String get familySyncUnpair => 'Unpair';

  @override
  String get familySyncUnpairDevice => 'Unpair Device';

  @override
  String familySyncUnpairConfirm(String deviceName) {
    return 'Are you sure you want to unpair from $deviceName? Sync will stop until you pair again.';
  }

  @override
  String familySyncUnpairFailed(String message) {
    return 'Unpair failed: $message';
  }

  @override
  String get familySyncNoDevicePaired => 'No family group';

  @override
  String get familySyncPairPrompt =>
      'Create or join a family group to sync transactions';

  @override
  String get familySyncStatusSynced => 'Connected and up to date';

  @override
  String get familySyncStatusSyncing => 'Syncing with group...';

  @override
  String get familySyncStatusOffline => 'Offline - will sync when connected';

  @override
  String get familySyncStatusError => 'Sync error occurred';

  @override
  String get familySyncStatusPairing => 'Group setup in progress...';

  @override
  String get familySyncCheckingGroup => 'Checking group status...';

  @override
  String familySyncCheckFailed(String message) {
    return 'Could not check group status: $message';
  }

  @override
  String get familySyncStatusUnpaired => 'Tap to create or join a family group';

  @override
  String get familySyncBadgeSynced => 'Synced';

  @override
  String get familySyncBadgeSyncing => 'Syncing';

  @override
  String get familySyncBadgeOffline => 'Offline';

  @override
  String get familySyncBadgeError => 'Error';

  @override
  String get familySyncBadgePairing => 'Setup';

  @override
  String get familySyncCreatingGroup => 'Creating group...';

  @override
  String get familySyncJoinGroup => 'Join Group';

  @override
  String get familySyncJoinSuccess =>
      'Joined the group. Waiting for owner confirmation...';

  @override
  String get familySyncLeaveGroup => 'Leave Group';

  @override
  String get familySyncDeactivateGroup => 'Deactivate Group';

  @override
  String get familySyncLeaveGroupConfirm =>
      'Leave this family group? Sync will stop on this device until you join again.';

  @override
  String get familySyncDeactivateGroupConfirm =>
      'Deactivate this family group for everyone? Sync will stop for all members until a new group is created.';

  @override
  String familySyncLeaveGroupFailed(String message) {
    return 'Leave group failed: $message';
  }

  @override
  String familySyncDeactivateGroupFailed(String message) {
    return 'Deactivate group failed: $message';
  }

  @override
  String get familySyncRegenerateInvite => 'Regenerate Invite';

  @override
  String familySyncRegenerateInviteFailed(String message) {
    return 'Regenerate invite failed: $message';
  }

  @override
  String get familySyncMembers => 'Members';

  @override
  String familySyncMemberCount(int count) {
    return '$count members';
  }

  @override
  String get familySyncRoleOwner => 'Owner';

  @override
  String get familySyncRoleMember => 'Member';

  @override
  String get familySyncMemberStatusActive => 'Active';

  @override
  String get familySyncMemberStatusPending => 'Pending';

  @override
  String get familySyncRemoveMember => 'Remove Member';

  @override
  String familySyncRemoveMemberConfirm(String deviceName) {
    return 'Remove $deviceName from this family group?';
  }

  @override
  String familySyncRemoveMemberFailed(String message) {
    return 'Remove member failed: $message';
  }

  @override
  String get familySyncBadgeUnpaired => 'Unpaired';

  @override
  String get familySyncShare => 'Share';

  @override
  String familySyncExpiryLabel(String time) {
    return 'Expires: $time';
  }

  @override
  String get familySyncJoinTitle => 'Join Family';

  @override
  String get familySyncJoinDescription =>
      'Enter the 6-digit invite code you received from a family member.';

  @override
  String get familySyncOrDivider => 'or';

  @override
  String get familySyncScanQr => 'Scan QR Code';

  @override
  String get familySyncWaitingTitle => 'Waiting for Approval...';

  @override
  String get familySyncWaitingDescription =>
      'The group owner is reviewing your join request. Please wait until approval is complete.';

  @override
  String get familySyncGroupLabel => 'Group';

  @override
  String get familySyncStatusLabel => 'Status';

  @override
  String get familySyncApprovalTitle => 'Member Approval';

  @override
  String get familySyncNewRequest => 'New Join Request';

  @override
  String get familySyncJoinRequestNotificationBody =>
      'A family member wants to join your group. Review the request to continue.';

  @override
  String familySyncJoinRequestWithName(String deviceName) {
    return '$deviceName wants to join your family ledger';
  }

  @override
  String get familySyncMemberConfirmedNotificationTitle => 'Group Ready';

  @override
  String get familySyncMemberConfirmedNotificationBody =>
      'Your family sync group is ready. Open group management to review the latest status.';

  @override
  String get familySyncJustNow => 'Requested just now';

  @override
  String get familySyncSecurityVerified =>
      'This device public key has been verified.';

  @override
  String get familySyncReject => 'Reject';

  @override
  String get familySyncApprove => 'Approve';

  @override
  String get familySyncCurrentMembers => 'Current Members';

  @override
  String get familySyncApprovalTip =>
      'Approving this request will sync the device and data with encryption enabled.';

  @override
  String get familySyncGroupManagement => 'Group Management';

  @override
  String get familySyncSynced => 'Synced';

  @override
  String get familySyncSyncedEntries => 'Synced Entries';

  @override
  String get familySyncLastSync => 'Last Sync';

  @override
  String get familySyncYouSuffix => ' (You)';

  @override
  String get familySyncDissolveGroup => 'Dissolve Group';

  @override
  String familySyncMinutesAgo(int minutes) {
    return '$minutes min ago';
  }
}
