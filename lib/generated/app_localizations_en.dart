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
  String get settingsJoyTargetTitle => 'Joy target';

  @override
  String settingsJoyTargetCurrentConfigured(int target) {
    return 'Current target: $target';
  }

  @override
  String settingsJoyTargetCurrentRecommended(int target) {
    return 'Active reference: $target';
  }

  @override
  String settingsJoyTargetRecommendation(int target) {
    return 'Reference from recent Joy patterns: $target';
  }

  @override
  String get settingsJoyTargetFallback =>
      'Reference target is available after more Joy entries. Using the starter reference for now.';

  @override
  String get settingsJoyTargetInputLabel => 'Monthly Joy target';

  @override
  String get settingsJoyTargetInputHint => 'Enter a positive whole number';

  @override
  String get settingsJoyTargetInvalid =>
      'Enter a whole number greater than zero.';

  @override
  String get settingsJoyTargetUseRecommendation => 'Use reference';

  @override
  String get settingsJoyTargetSave => 'Save';

  @override
  String get settingsJoyTargetCancel => 'Cancel';

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
  String get dailyLedger => 'Daily';

  @override
  String get joyLedger => 'Joy';

  @override
  String get daily => 'Daily';

  @override
  String get joy => 'Joy';

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
  String get successKeepGoing => 'Saved — you can keep recording';

  @override
  String get recordingExitLink => 'Exit';

  @override
  String get entrySavedDone => 'Got it — recorded!';

  @override
  String get continuousKeepGoing => 'Saved — keep going!';

  @override
  String get continuousExitHint => 'Tap exit anytime to finish';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get tapToAddFirstTransaction => 'Tap + to add your first transaction';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get transactionEditTitle => 'Edit Entry';

  @override
  String get ocrReviewTitle => 'Review Receipt';

  @override
  String get ocrReviewEmptyDraftBanner =>
      'OCR is not implemented yet — please fill in the fields manually.';

  @override
  String get transactionUpdated => 'Transaction updated';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeSystem => 'Follow device settings';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get settingsWeekStartMonday => 'Monday';

  @override
  String get settingsWeekStartSunday => 'Sunday';

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
  String get settingsGeneral => 'General';

  @override
  String get settingsFamily => 'Family';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsThisApp => 'This App';

  @override
  String get settingsAdditional => 'Other settings';

  @override
  String get settingsAdditionalDescription =>
      'Week start, voice recognition, and notifications';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String settingsJoyTargetValue(int value) {
    return '$value Joy';
  }

  @override
  String get settingsLocalDataProtected =>
      'Your data is protected on this device';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get backupAndRestoreDescription => 'Encrypted file';

  @override
  String get backupHeroTitle => 'Keep your data safely in your hands';

  @override
  String get backupHeroDescription =>
      'Encrypt your records and settings with a password, then save them on your device or in a cloud drive you choose.';

  @override
  String get backupEncryptionChip => 'AES-256-GCM';

  @override
  String get backupCompressedChip => 'Compressed';

  @override
  String get backupNoUploadChip => 'No automatic upload';

  @override
  String get backupSectionTitle => 'Backup';

  @override
  String get restoreSectionTitle => 'Restore';

  @override
  String get backupPasswordNotStored =>
      'The password is not stored in this app. If you forget it, the backup cannot be restored.';

  @override
  String get restoreReplacesData =>
      'Choose an .hpb file and replace current data';

  @override
  String get restoreWarningTitle => 'Your current data will be replaced';

  @override
  String get restoreWarningBody =>
      'If restoration fails, your current data will remain unchanged.';

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
  String get deleteAllDataDescription =>
      'Permanently delete data on this device';

  @override
  String get deleteAllDataConfirmation =>
      'This permanently deletes Home Pocket data on this device. It does not delete family data from other devices or send a server deletion request.';

  @override
  String get allDataDeleted => 'Local data deleted';

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
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteTransactionConfirmation => 'Delete this transaction?';

  @override
  String get error => 'Error';

  @override
  String initializationError(String error) {
    return 'Initialization failed: $error';
  }

  @override
  String get profileSetup => 'Nice to meet you!';

  @override
  String get profileSetupSubtitle => 'Welcome to Home Pocket';

  @override
  String get profileNickname => 'Your nickname';

  @override
  String get profileNicknamePlaceholder => 'Enter your nickname';

  @override
  String get profileStart => 'Get Started';

  @override
  String get profileSelectAvatar => 'Select Avatar';

  @override
  String get profileEmojiTab => 'Emoji';

  @override
  String get profilePhotoTab => 'Photo';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileEditPersonalInfo => 'Edit personal information';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileDone => 'Done';

  @override
  String get profilePreview => 'Preview';

  @override
  String get welcomeTo => 'Welcome to Home Pocket';

  @override
  String get profileNameRequired => 'Please enter a nickname';

  @override
  String get profileSave => 'Save';

  @override
  String get profileChangeAvatar => 'Tap to change avatar';

  @override
  String get profilePhotoPermissionDenied => 'Photo access denied';

  @override
  String get profilePhotoFailed => 'Failed to load photo';

  @override
  String get profileSaveFailed => 'Failed to save';

  @override
  String get profileNameTooLong => 'Nickname must be 50 characters or less';

  @override
  String get profileUploadPhoto => 'Upload Photo';

  @override
  String get homeMonthlyExpense => 'Monthly Expenses';

  @override
  String get homeDailyExpense => 'Daily Expenses';

  @override
  String get homeJoyExpense => 'Joy Expenses';

  @override
  String get homeMonthComparison => 'vs Last Month';

  @override
  String homePreviousMonthAmount(String amount) {
    return 'Last month $amount';
  }

  @override
  String get homeDailyLedgerTag => 'D';

  @override
  String get homeJoyLedgerTag => 'J';

  @override
  String get homeSharedLedgerTag => 'G';

  @override
  String homeShadowBookTitle(String memberName) {
    return '$memberName\'s Ledger';
  }

  @override
  String get homeJoyFullness => 'Joy Index';

  @override
  String get homeJoyPercentLabel => 'Joy spending ratio';

  @override
  String get homeFamilyInviteTitle => 'Add Family';

  @override
  String get homeFamilyInviteDesc => 'Share your ledger with your partner';

  @override
  String get homeFamilyInviteDismissLabel => 'Dismiss family invite';

  @override
  String get homeFamilyInviteSettingsPath => 'Settings › Family';

  @override
  String get homeFamilyBannerTitle => 'Share your budget';

  @override
  String get homeFamilyBannerSubtitle => 'Add anytime from Settings';

  @override
  String get homeTodayTitle => 'Today\'s Records';

  @override
  String homeTodayCount(int count) {
    return '$count items';
  }

  @override
  String get homePersonalMode => 'Personal';

  @override
  String get homeFamilyMode => 'Family';

  @override
  String get homeTabHome => 'Home';

  @override
  String get homeTabList => 'List';

  @override
  String get homeTabChart => 'Charts';

  @override
  String get homeTabShopping => 'Shopping';

  @override
  String homeMonthFormat(int year, int month) {
    return '$year/$month';
  }

  @override
  String homeMonthLabel(int month) {
    return 'M$month';
  }

  @override
  String homeRecentJoyTransaction(String merchant, int amount) {
    return 'Recent: $merchant ¥$amount';
  }

  @override
  String homeJoyChargeStatus(int fullness, double roi) {
    return 'Joy Fullness $fullness% · Joy Index $roi';
  }

  @override
  String homeMonthBadge(int percent) {
    return 'This month $percent%';
  }

  @override
  String get homeJoyIndexTooltip =>
      'Outer ring is monthly Joy Index toward your active target; middle is average satisfaction; inner is highlights count (satisfaction >= 6).';

  @override
  String get homeJoyContributionTooltip =>
      'Outer ring is monthly Joy Index toward your active target; middle is average satisfaction; inner is highlights count.';

  @override
  String homeJoyTargetReference(int target) {
    return 'of $target';
  }

  @override
  String homeJoyTargetSemantics(String value, int target) {
    return 'Joy Index $value of target $target';
  }

  @override
  String get homeHeroCardLabelSingle => 'This Month';

  @override
  String get homeHeroCardLabelGroup => 'Family This Month';

  @override
  String homeHeroPreviousMonthSubline(String amount) {
    return 'Last month (same period) $amount';
  }

  @override
  String get homeJoyEmptyTitleSingle => 'What made you smile today?';

  @override
  String get homeJoyEmptyTitleGroup => 'Family joy today?';

  @override
  String get homeJoyEmptySubtitle => 'Start with one small pleasure';

  @override
  String get homeJoyEmptyFree => 'Add your own';

  @override
  String get homeJoyEmptyCoffee => 'A drink';

  @override
  String get homeJoyEmptyBook => 'A book';

  @override
  String get homeJoyEmptyRest => 'A breather';

  @override
  String get homeRingSectionTitleSingle => 'Joy Index';

  @override
  String get homeRingSectionTitleGroup => 'Family Joy';

  @override
  String get homeViewMonthlyAnalysis => 'View monthly analysis';

  @override
  String get homeViewDetails => 'View details';

  @override
  String get homeMetricJoyUnit => 'Joy';

  @override
  String get homeMetricCountUnit => '';

  @override
  String get homeBestJoyTagSingle => 'Top of the Month';

  @override
  String get homeBestJoyTagGroup => 'Top of the Month';

  @override
  String homeBestJoyAmountSat(String amount, int sat) {
    return '$amount · Satisfaction $sat/10 ✨';
  }

  @override
  String get homeMembersSectionTitle => 'Members';

  @override
  String get homeNoJoyDataLegend => 'No data yet';

  @override
  String get homeBestJoyEmptyTagPrimary => 'Top of the Month';

  @override
  String get homeBestJoyEmptyBig => 'Record your first joy-ledger entry';

  @override
  String get homeBestJoyEmptySmall =>
      'Your monthly favorite will appear here →';

  @override
  String get homeBestJoyAllNeutralBig => 'Rate your biggest spend';

  @override
  String get homeBestJoyAllNeutralSmall => 'Make it your monthly favorite';

  @override
  String get homeAvgSatisfactionLegend => 'Avg satisfaction';

  @override
  String get homeJoyContributionLegend => 'Joy Index target';

  @override
  String get homeHighlightsCountLegend => 'Highlights';

  @override
  String get homeFamilyHighlightsLegend => 'Family highlights';

  @override
  String get homeSharedJoyLegend => 'Shared joy';

  @override
  String get homeMedianSatisfactionLegend => 'Median satisfaction';

  @override
  String get addTransaction => 'Add Transaction';

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
  String get keyboardToolbarDone => 'Done';

  @override
  String get enterStore => 'Enter store';

  @override
  String get enterMemo => 'Enter memo...';

  @override
  String get expenseClassification => 'Purpose';

  @override
  String get dailyExpense => 'Daily';

  @override
  String get joyExpense => 'Joy';

  @override
  String get joyFullness => 'Joy Fullness';

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
  String get satisfactionBad => 'Neutral';

  @override
  String get satisfactionSlightlyBad => 'OK';

  @override
  String get satisfactionNormal => 'Good';

  @override
  String get satisfactionGood => 'Great';

  @override
  String get satisfactionVeryGood => 'Amazing';

  @override
  String get satisfactionExcellent => 'Amazing!';

  @override
  String get satisfactionLabelNeutral => 'Neutral';

  @override
  String get satisfactionLabelOK => 'OK';

  @override
  String get satisfactionLabelGood => 'Good';

  @override
  String get satisfactionLabelGreat => 'Great';

  @override
  String get satisfactionLabelAmazing => 'Amazing';

  @override
  String get addSubcategory => 'Add';

  @override
  String get addCategory => 'Add category';

  @override
  String get noMatchingCategories => 'No matching categories';

  @override
  String get addL1CategoryTitle => 'Add category';

  @override
  String addL2CategoryTitle(String parentName) {
    return 'Add under $parentName';
  }

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Weekend projects';

  @override
  String get categoryAppearanceLabel => 'Appearance';

  @override
  String get categoryAppearanceDescription =>
      'Makes it easy to spot in lists and charts.';

  @override
  String get categoryPreviewName => 'New category';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryNameRequired => 'Enter a category name';

  @override
  String get categoryNameTooLong => 'Use 50 characters or fewer';

  @override
  String get categoryNameExists => 'A category with this name already exists';

  @override
  String get categoryLedgerLabel => 'Ledger';

  @override
  String get categoryLedgerDescription =>
      'Choose where expenses in this category are recorded.';

  @override
  String get createCategory => 'Add';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get categoryAddFailed => 'Couldn\'t add the category. Please retry.';

  @override
  String get editCategoryOrder => 'Edit category order';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get orderUpdated => 'Order updated';

  @override
  String get orderSaveFailed => 'Failed to save order. Please retry';

  @override
  String get discardUnsavedChanges => 'Discard unsaved changes?';

  @override
  String get discardUnsavedChangesBody =>
      'Your reordering will not be saved and will revert.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get holdToRecord => 'Hold to speak';

  @override
  String get recording => 'Recording…';

  @override
  String get voiceRecordBar => 'Voice entry';

  @override
  String get listeningTitle => 'Listening…';

  @override
  String get voiceTapToExit => 'Tap anywhere to exit';

  @override
  String get voiceStatusProcessing => 'Parsing…';

  @override
  String get voiceStatusStopped => 'Stopped';

  @override
  String get voiceTapResetToRerecord => 'Tap Reset to record again';

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
  String get voiceOnDeviceRecognitionTitle => 'On-device recognition';

  @override
  String get voiceAllowCloudFallbackTitle => 'Allow cloud fallback';

  @override
  String get voiceAllowCloudFallbackSubtitle =>
      'When off, recognition stays on-device and a failure is shown instead of using cloud recognition.';

  @override
  String get familySync => 'Family Sync';

  @override
  String get familySyncShowMyCode => 'Create Group';

  @override
  String get familySyncEnterPartnerCode => 'Join with an invite code';

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
  String get familySyncRegenerateInviteFailed =>
      'Couldn\'t generate a new invite code. Please try again in a moment.';

  @override
  String get familySyncInviteTitle => 'Invite a family member';

  @override
  String get familySyncInviteDescription =>
      'Share this code with the person you want to invite.';

  @override
  String get familySyncInviteCopy => 'Copy code';

  @override
  String get familySyncInviteCopied => 'Invite code copied';

  @override
  String get familySyncInviteRefreshHint =>
      'Refreshing invalidates the previous code immediately.';

  @override
  String get familySyncInviteApprovalWindowHint =>
      'Code expiry only controls new applications. After applying, the owner has 24 hours to approve the request.';

  @override
  String familySyncInviteShareMessage(String groupName, String inviteCode) {
    return 'I saved you a place in “$groupName”.\nLet’s keep track of everyday life and make managing our home a little easier—together.\n\nInvite code: $inviteCode\nPlease use it within 10 minutes.';
  }

  @override
  String get familySyncInviteOwnerOnly =>
      'Only the group owner can manage invite codes.';

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
  String get familySyncGroupManagement => 'Family Management';

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

  @override
  String groupDefaultName(String name) {
    return '$name\'s Family';
  }

  @override
  String get groupCreate => 'Create a new family';

  @override
  String get groupCreateConfirmationHint =>
      'Your group and invite code are created only after you confirm.';

  @override
  String groupCreateFailed(String message) {
    return 'Could not create the group: $message';
  }

  @override
  String get familySyncSingleGroupConflict =>
      'This device already has a family group or a pending join request. Leave or cancel it before creating or joining another group.';

  @override
  String get familySyncNetworkUnavailableTitle => 'No internet connection';

  @override
  String get familySyncNetworkUnavailableMessage =>
      'Family sharing needs an internet connection. Check your connection and make sure Home Pocket can use mobile data, then try again.';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupOwner => 'Owner';

  @override
  String get groupMember => 'Member';

  @override
  String get groupInviteCode => 'Invite Code';

  @override
  String groupInviteExpiry(int minutes) {
    return 'Valid for $minutes minutes';
  }

  @override
  String groupInviteCountdown(String time) {
    return 'Valid for $time';
  }

  @override
  String get groupInviteExpired => 'Expired';

  @override
  String get groupShareCode => 'Share Invite Code';

  @override
  String get groupEnterCode => 'Enter Invite Code';

  @override
  String get groupVerify => 'Verify';

  @override
  String get groupConfirmJoin => 'Request to join';

  @override
  String get groupJoinTarget => 'Group to Join';

  @override
  String get groupWaitingApproval => 'Waiting for owner approval';

  @override
  String groupWaitingDesc(String name) {
    return '$name is reviewing your join request.';
  }

  @override
  String get groupJoinRequest => 'Join request received';

  @override
  String groupJoinRequestDesc(String name) {
    return '$name wants to join';
  }

  @override
  String get groupApprove => 'Approve';

  @override
  String get groupReject => 'Reject';

  @override
  String get groupJoinSuccess => 'Welcome!';

  @override
  String get groupRename => 'Rename Group';

  @override
  String get groupRenameFailed => 'Failed to rename';

  @override
  String get groupSyncing => 'Syncing';

  @override
  String get groupInvalidCode => 'Invalid invite code';

  @override
  String get groupCodeExpired => 'Invite code expired';

  @override
  String get groupMyName => 'My Name';

  @override
  String get groupEnterGroup => 'Enter Group';

  @override
  String get groupChoiceTitle => 'How would you like to start?';

  @override
  String get groupChoiceSubtitle => 'You can join one family at a time.';

  @override
  String get groupCreateDesc => 'Issue an invite code and approve each member';

  @override
  String get groupJoinDesc => 'Approval from the family owner is required';

  @override
  String get groupE2eeHint =>
      'Shared family ledgers sync with encryption. Private ledgers stay on this device.';

  @override
  String get familyFlowCreateStepCreate => 'Create';

  @override
  String get familyFlowCreateHeader => 'Create family';

  @override
  String get familyFlowJoinHeader => 'Join family';

  @override
  String get familyFlowReviewFamily => 'Review family details';

  @override
  String get familyFlowCreateStepInvite => 'Invite';

  @override
  String get familyFlowCreateStepApprove => 'Approval';

  @override
  String get familyFlowJoinStepCode => 'Code';

  @override
  String get familyFlowJoinStepConfirm => 'Confirm';

  @override
  String get familyFlowJoinStepWait => 'Wait';

  @override
  String familyFlowOwnerSummary(String name) {
    return '$name · Owner';
  }

  @override
  String get familyFlowCreateTitle => 'Create a new family';

  @override
  String get familyFlowCreateSubtitle =>
      'Name your family to issue a secure invite code.';

  @override
  String get familyFlowCreateInviteHelper =>
      'When someone requests to join, you will approve them in the next step.';

  @override
  String get familyFlowRegenerateInvite => 'Reissue';

  @override
  String get familySyncInviteRegenerated => 'Invite code reissued';

  @override
  String get familyFlowJoinCodeTitle => 'Enter the 6-digit invite code';

  @override
  String get familyFlowJoinCodeSubtitle =>
      'Enter the digits you received from the family owner.';

  @override
  String get familyFlowJoinBeforeApprovalHelper =>
      'No ledgers sync until your request is approved.';

  @override
  String get familyFlowJoinConfirmHeader => 'Confirm family';

  @override
  String get familyFlowJoinConfirmTitle => 'Confirm the family you are joining';

  @override
  String get familyFlowJoinConfirmSubtitle =>
      'Your join request will be sent to this family.';

  @override
  String get familyFlowPublicKeyVerified => 'Public key verified';

  @override
  String get familyFlowPrivateLedgerHelper =>
      'Your private ledgers are never shared with the family.';

  @override
  String get familyFlowWaitingHeader => 'Waiting for approval';

  @override
  String familyFlowWaitingFamily(String groupName) {
    return 'Joining: $groupName';
  }

  @override
  String get familyFlowApprovalTitle => 'New join request';

  @override
  String get familyFlowApprovalSubtitle =>
      'Confirm the person and device before approving.';

  @override
  String familyFlowApprovalDevice(String deviceName) {
    return 'Request from $deviceName';
  }

  @override
  String get familyFlowDeviceKeyVerified => 'Device public key verified';

  @override
  String get familyFlowApprovalHelper =>
      'After approval, this device securely syncs the family\'s shared ledgers.';

  @override
  String get familyFlowApprovalEmptyTitle => 'No requests to review';

  @override
  String familyFlowPendingRequests(int count) {
    return 'New join requests · $count';
  }

  @override
  String get familyFlowViewRequests => 'Review requests';

  @override
  String get familyFlowSyncSettings => 'Sync settings';

  @override
  String familyFlowManagementSummary(
    String ownerName,
    int count,
    String syncStatus,
  ) {
    return 'Owner: $ownerName · $count members · $syncStatus';
  }

  @override
  String get groupInviteMembers => 'Invite new member';

  @override
  String get groupDisband => 'Disband Family';

  @override
  String get groupCancel => 'Cancel';

  @override
  String get groupCancelRequest => 'Cancel join request';

  @override
  String groupRejectRequestFailed(String message) {
    return 'Failed to reject join request: $message';
  }

  @override
  String get groupRequestRejectedTitle => 'Join request declined';

  @override
  String get groupRequestRejectedDescription =>
      'The group owner declined this request. You can try another invite code.';

  @override
  String get groupRequestCancelledTitle => 'Join request cancelled';

  @override
  String get groupRequestCancelledDescription =>
      'Your request was cancelled. You can submit a new request at any time.';

  @override
  String get groupRequestExpiredTitle => 'Join request expired';

  @override
  String get groupRequestExpiredDescription =>
      'The request was not reviewed within 24 hours. Ask for a current invite code and try again.';

  @override
  String get groupTryAnotherInvite => 'Enter another invite code';

  @override
  String get groupKeyRecoveryTitle => 'Restoring the family key';

  @override
  String get groupKeyRecoveryWaiting =>
      'Your membership is active. Another active family device must securely re-seal the current key for this device. The relay cannot read or recreate it.';

  @override
  String get groupKeyRecoveryUnavailable =>
      'No active device supplied the current key before the request expired. Because the relay is zero-knowledge, it cannot recover the key. You can retry or safely leave/dissolve this family and create a new one.';

  @override
  String get groupKeyRecoveryRateLimited =>
      'A recovery request was sent recently. Wait a moment before notifying the other devices again.';

  @override
  String get groupKeyRecoveryRetry => 'Retry key recovery';

  @override
  String get groupKeyRecoveryRebuild => 'Leave and set up a new family';

  @override
  String get groupWaitingHint1 => 'It\'s safe to close the app.';

  @override
  String get groupWaitingHint2 => 'Sync starts automatically after approval.';

  @override
  String get groupCodeHint => 'Ask the group owner for the invite code';

  @override
  String get groupBack => 'Back';

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncCompleted => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncManual => 'Sync Now';

  @override
  String syncLastTime(String time) {
    return 'Last sync: $time';
  }

  @override
  String syncOfflineQueued(int count) {
    return '$count changes pending';
  }

  @override
  String get syncInitialProgress => 'Initial sync...';

  @override
  String syncProfileUpdated(String name) {
    return '$name updated their profile';
  }

  @override
  String get familySyncManualSync => 'Sync Ledger';

  @override
  String get familySyncManualSyncDesc => 'Manually sync data';

  @override
  String get listTab => 'List';

  @override
  String get datePickerComingSoon => 'Date picker coming soon';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get initFailedTitle => 'Initialization failed';

  @override
  String get initFailedMessage =>
      'Something went wrong while starting the app. Tap retry to try again.';

  @override
  String get initFailedRetry => 'Retry';

  @override
  String get homeLedgersSection => 'Ledgers';

  @override
  String get homeRecentTransactions => 'Recent Transactions';

  @override
  String get homeViewAllTransactions => 'View All';

  @override
  String get homeRecentJoyExpense => 'Recent Joy Expense';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Please allow microphone access';

  @override
  String get voiceRecognitionErrorNetwork =>
      'Can\'t reach the network. Please check your connection and try again';

  @override
  String get voiceRecognitionErrorNoMatch =>
      'Didn\'t catch that. Please try again';

  @override
  String get voiceRecognitionErrorAudio =>
      'Couldn\'t read audio from the microphone';

  @override
  String get voiceRecognitionErrorUnknown => 'Voice recognition error occurred';

  @override
  String voiceCurrencyConverted(
    String original,
    String converted,
    String rate,
  ) {
    return 'Detected foreign currency: $original → $converted (rate $rate)';
  }

  @override
  String get voiceCurrencyConvertedUndo => 'Undo';

  @override
  String voiceAmountRepairSuspect(String original, String candidate) {
    return 'Recognized amount $original — did you mean $candidate?';
  }

  @override
  String voiceAmountRepairApply(String candidate) {
    return 'Use $candidate';
  }

  @override
  String voiceLargeAmountNotice(String amount) {
    return 'Large amount: $amount. Please double-check before saving';
  }

  @override
  String get analyticsBudgetProgress => 'Budget Progress';

  @override
  String get analyticsNoBudgetsSet => 'No budgets set';

  @override
  String get analyticsIncome => 'Income';

  @override
  String get analyticsExpenses => 'Expenses';

  @override
  String get analyticsSavings => 'Savings';

  @override
  String get analyticsSavingsRate => 'Savings Rate';

  @override
  String get analyticsCategoryDetails => 'Category Details';

  @override
  String analyticsTransactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get analyticsDailyExpenses => 'Daily Expenses';

  @override
  String get analyticsNoLedgerData => 'No ledger data';

  @override
  String get analyticsDailyVsJoy => 'Daily vs Joy';

  @override
  String get analyticsSixMonthTrend => 'Six-month Trend';

  @override
  String analyticsDayNumberLabel(int day) {
    return 'Day $day';
  }

  @override
  String analyticsMonthNumberLabel(int month) {
    return 'Month $month';
  }

  @override
  String get analyticsTitle => 'Statistics';

  @override
  String get analyticsTimeWindowChipTooltip => 'Pick a time window';

  @override
  String analyticsTimeWindowChipLabelWeek(String monday) {
    return 'Week of $monday';
  }

  @override
  String analyticsTimeWindowChipLabelQuarter(String q, String year) {
    return 'Q$q $year';
  }

  @override
  String analyticsTimeWindowChipLabelYear(String year) {
    return '$year';
  }

  @override
  String analyticsTimeWindowChipLabelCustom(String start, String end) {
    return '$start – $end';
  }

  @override
  String get analyticsTimeWindowSheetTitle => 'Time window';

  @override
  String get analyticsTimeWindowTypeWeek => 'Week';

  @override
  String get analyticsTimeWindowTypeMonth => 'Month';

  @override
  String get analyticsTimeWindowTypeQuarter => 'Quarter';

  @override
  String get analyticsTimeWindowTypeYear => 'Year';

  @override
  String get analyticsTimeWindowTypeCustom => 'Custom';

  @override
  String get analyticsTimeWindowCustomCta => 'Pick a date range';

  @override
  String get analyticsTimeWindowErrorTooLong =>
      'Range cannot exceed 12 months. Pick a shorter range.';

  @override
  String get analyticsTimeWindowErrorInverted =>
      'Start date must be before end date.';

  @override
  String get analyticsTimeWindowErrorFutureEnd =>
      'End date cannot be in the future.';

  @override
  String get analyticsTimeWindowEmptyPreset =>
      'No data yet for this view. Add a transaction to begin.';

  @override
  String get analyticsKpiTotalLabel => 'Total spending';

  @override
  String get analyticsTrendTabAll => 'All';

  @override
  String get analyticsKpiJoyLabel => 'Avg satisfaction';

  @override
  String analyticsKpiJoySubMedianCoverage(String median, int k, int N) {
    return 'Median $median · n=$k/$N';
  }

  @override
  String analyticsKpiJoySemantics(
    String label,
    String value,
    int rated,
    int total,
  ) {
    return 'Joy $label $value n=$rated/$total';
  }

  @override
  String get analyticsKpiJoyEmptyCaption => 'Gathering data...';

  @override
  String get analyticsKpiJoyIndexLabel => 'Joy Index';

  @override
  String get analyticsKpiJoyIndexEmptyCaption =>
      'Joy Index appears after you rate joy-ledger entries.';

  @override
  String analyticsKpiJoyIndexSemantics(
    String label,
    String value,
    int ratedCount,
    int totalCount,
  ) {
    return '$label $value, $ratedCount rated of $totalCount joy entries';
  }

  @override
  String analyticsKpiJoyIndexSubMedianCoverage(
    String median,
    int ratedCount,
    int totalCount,
  ) {
    return 'Median $median · rated $ratedCount/$totalCount';
  }

  @override
  String get analyticsCardTitleTotalSixMonth => 'Total · 6-month trend';

  @override
  String get analyticsCardCaptionTotalSixMonth =>
      'BarChart · current month highlighted';

  @override
  String get analyticsCardTitleCategoryDonut => 'Total · Category breakdown';

  @override
  String get analyticsCardCaptionCategoryDonut =>
      'Donut/PieChart · top-N + Other';

  @override
  String get analyticsCardTitleWithinMonthTrend => 'Spending trend';

  @override
  String get analyticsCardCaptionWithinMonthTrend =>
      'Cumulative spend by day this month';

  @override
  String get analyticsTrendSeriesThisMonth => 'This month';

  @override
  String get analyticsTrendSeriesLastMonth => 'Last month';

  @override
  String get analyticsCardTitleJoySpend => 'Joy · Where it went';

  @override
  String get analyticsCardCaptionJoySpend =>
      'How your joy spending breaks down';

  @override
  String get analyticsJoySpendHeaderLabel => 'Joy spend';

  @override
  String get analyticsJoySpendEmpty => 'No joy spending in this window yet';

  @override
  String get analyticsCardTitleJoyCalendar => 'Little joys · Calendar';

  @override
  String get analyticsCardCaptionJoyCalendar =>
      'The texture of your joyful days';

  @override
  String get analyticsJoyCalendarDayEmpty => 'No little joys recorded this day';

  @override
  String get analyticsSectionTrend => 'Spending trend';

  @override
  String get analyticsSectionCategory => 'Category spending';

  @override
  String get analyticsSectionJoyCalendar => 'Little joys calendar';

  @override
  String get analyticsSectionSatisfaction => 'Joy satisfaction';

  @override
  String analyticsJoyDrawerTitle(String amount) {
    return 'Joy $amount';
  }

  @override
  String analyticsJoyDrawerCount(int count) {
    return '$count categories';
  }

  @override
  String analyticsJoyDrawerMemberCount(int count) {
    return '$count members';
  }

  @override
  String get analyticsCalLegendLow => 'Light';

  @override
  String get analyticsCalLegendHigh => 'Deep';

  @override
  String get analyticsCalLegendNote =>
      'The deeper the color, the more joy entries that day';

  @override
  String analyticsHistogramMedianPill(int value) {
    return 'Median satisfaction $value';
  }

  @override
  String analyticsHistogramCountFooter(int count) {
    return 'Satisfaction of $count joy expenses';
  }

  @override
  String analyticsHistogramNarrative(int value) {
    return 'This month’s Joy-purchase satisfaction midpoint was $value';
  }

  @override
  String get analyticsCategoryDonutOther => 'Other';

  @override
  String get analyticsDonutDimensionCategory => 'Category';

  @override
  String get analyticsDonutDimensionMember => 'Member';

  @override
  String get analyticsDonutMemberFilterAll => 'All members';

  @override
  String get analyticsDonutMemberFilterLabel => 'Member';

  @override
  String get analyticsDonutMemberFilterSelf => 'Me';

  @override
  String get analyticsDonutCenterLabel => 'This month';

  @override
  String get analyticsDrillSubtotalLabel => 'Subtotal';

  @override
  String get analyticsDrillCountLabel => 'Count';

  @override
  String get analyticsDrillAvgPerDayLabel => 'Per day';

  @override
  String get analyticsDrillEmpty => 'No records for this period';

  @override
  String get analyticsDrillLoadError => 'Failed to load';

  @override
  String get analyticsCardTitleSatisfactionHistogram =>
      'Joy · Satisfaction distribution 1–10';

  @override
  String get analyticsCardCaptionHistogram =>
      'Histogram · cool→warm · 5-bar trilingual annotation';

  @override
  String get analyticsHistogramBarFiveAnnotation => 'Median + unrated';

  @override
  String get analyticsHistogramColorCaption => 'Colors are ordinal only';

  @override
  String get analyticsCardTitleLargestExpense => 'Total · Largest expense';

  @override
  String analyticsCardLargestExpenseBody(
    String categoryName,
    String amount,
    String date,
  ) {
    return '$categoryName · $amount · $date';
  }

  @override
  String get analyticsCardEmptyLargestExpense =>
      'No data — no expenses logged yet';

  @override
  String get analyticsCardTitleBestJoy => 'Joy · Best Joy moment';

  @override
  String analyticsCardBestJoyBig(String categoryName, String date) {
    return '$categoryName · $date';
  }

  @override
  String analyticsCardSmallBestJoy(String amount, int sat) {
    return '$amount · sat $sat/10 ✨';
  }

  @override
  String get analyticsCardEmptyBestJoy => 'No standout Joy yet';

  @override
  String get analyticsCardTitleFamilyInsight => 'Family · Highlights Summary';

  @override
  String analyticsFamilyHighlightsSentence(int N) {
    return '$N family Highlights';
  }

  @override
  String analyticsFamilySharedJoySentence(
    String categoryName,
    int count,
    String avg,
  ) {
    return 'You all love [$categoryName] (n=$count, avg $avg/10)';
  }

  @override
  String get analyticsFamilyEmpty =>
      'No shared favorite yet — keep logging Joy entries';

  @override
  String get analyticsThinSampleFallbackHeading => 'Not enough Joy entries yet';

  @override
  String get analyticsThinSampleFallbackBody =>
      'Keep logging — your Joy pattern shows up after a few days';

  @override
  String get analyticsThinSampleFallbackCta => 'Add an entry »';

  @override
  String get analyticsCardErrorHeading => 'Could not load data';

  @override
  String get analyticsCardErrorBody => 'Please try again in a moment';

  @override
  String get analyticsCardErrorRetry => 'Retry';

  @override
  String get analyticsCardTitlePerCategoryJoy => 'Joy · Categories';

  @override
  String get analyticsCardTitlePerCategoryJoyYou => 'Joy · Your categories';

  @override
  String get analyticsCardTitlePerCategoryJoyFamily =>
      'Joy · Family categories';

  @override
  String analyticsPerCategoryRow(
    String categoryName,
    String avgSat,
    int count,
  ) {
    return '$categoryName · $avgSat avg / $count entries';
  }

  @override
  String analyticsPerCategoryOtherFold(int totalCount, int categoryCount) {
    return 'Other: $totalCount entries across $categoryCount categories';
  }

  @override
  String get analyticsPerCategoryShowAll => 'Show all';

  @override
  String get analyticsPerCategoryShowLess => 'Show less';

  @override
  String get analyticsCardTitleLedgerThisWindow => 'Ledger · This window';

  @override
  String get analyticsLedgerColumnJoy => 'Joy';

  @override
  String get analyticsLedgerColumnDaily => 'Daily';

  @override
  String get analyticsLedgerRowYou => 'You';

  @override
  String get analyticsLedgerRowFamily => 'Family';

  @override
  String analyticsLedgerCellEntries(int count) {
    return '$count entries';
  }

  @override
  String analyticsLedgerCellAvgSat(String avgSat) {
    return '$avgSat avg satisfaction';
  }

  @override
  String get analyticsPerCategoryEmpty => 'No category data this window';

  @override
  String get analyticsLedgerEmpty => 'No data this window';

  @override
  String get analyticsLedgerFamilyEmpty =>
      'Family data not available this window';

  @override
  String get analyticsLedgerFamilyError => 'Family data unavailable';

  @override
  String budgetRemainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String budgetExceededAmount(String amount) {
    return 'Exceeded: $amount';
  }

  @override
  String get calMonthTotal => 'Monthly total';

  @override
  String get calMonthTotalDaily => 'Daily total';

  @override
  String get calMonthTotalJoy => 'Joy total';

  @override
  String calDayTotal(String date) {
    return '$date Spend';
  }

  @override
  String get calLoadError => 'Unable to load data';

  @override
  String get listSortDate => 'Date';

  @override
  String get listSortEditTime => 'Edit time';

  @override
  String get listSortAmount => 'Amount';

  @override
  String get listLedgerAll => 'All';

  @override
  String get listLedgerDaily => 'Daily';

  @override
  String get listLedgerJoy => 'Joy';

  @override
  String get listCategoryChip => 'Categories';

  @override
  String listCategoryChipN(int n) {
    return 'Categories $n';
  }

  @override
  String get listSearchHint => 'Search...';

  @override
  String get listClearAll => 'Clear';

  @override
  String get listMineOnly => 'Mine only';

  @override
  String get listDeleteConfirmTitle => 'Delete entry?';

  @override
  String get listDeleteConfirmBody =>
      'This entry will be deleted and cannot be undone.';

  @override
  String get listDeleteCancelButton => 'Cancel';

  @override
  String get listDeleteConfirmButton => 'Delete';

  @override
  String get listDeletedSnackBar => 'Deleted';

  @override
  String get listCategorySheetTitle => 'Filter by category';

  @override
  String get listCategorySheetClear => 'Clear';

  @override
  String get listCategorySheetApply => 'Apply';

  @override
  String listCategorySheetApplyN(int n) {
    return 'Apply ($n)';
  }

  @override
  String get listEmptyMonth => 'No records yet this month';

  @override
  String get listEmptyFiltered => 'No records match your filters';

  @override
  String get listEmptyFilteredClear => 'Clear filters';

  @override
  String get listEmptyDay => 'No records on this day';

  @override
  String get listEmptyDayClear => 'Show full month';

  @override
  String get listLoadError => 'Unable to load data';

  @override
  String get listCalNavPrev => 'Previous month';

  @override
  String get listCalNavNext => 'Next month';

  @override
  String get listCalNavCurrentMonth => 'Return to current month';

  @override
  String get listMonthPickerLabel => 'Select month';

  @override
  String get listSortDirectionDesc => 'Descending';

  @override
  String get listSortDirectionAsc => 'Ascending';

  @override
  String listSortPillLabel(String field, String direction) {
    return '$field・$direction';
  }

  @override
  String get shoppingDeleteConfirmTitle => 'Delete this item?';

  @override
  String get shoppingDeleteConfirmBody =>
      'This item will be removed from your shopping list.';

  @override
  String get shoppingDeleteConfirmButton => 'Delete';

  @override
  String get shoppingDeleteCancelButton => 'Cancel';

  @override
  String get shoppingDeletedSnackBar => 'Item deleted';

  @override
  String get shoppingEditItem => 'Edit item';

  @override
  String get shoppingActionEdit => 'Edit';

  @override
  String get shoppingReorderItem => 'Reorder item';

  @override
  String get shoppingToggleComplete => 'Toggle complete';

  @override
  String get shoppingEnterReorderMode => 'Reorder list';

  @override
  String get shoppingExitReorderMode => 'Done reordering';

  @override
  String get shoppingMoveToTop => 'Move to top';

  @override
  String get shoppingMoveToBottom => 'Move to bottom';

  @override
  String get shoppingEmptyPrivateHeading => 'Your shopping list is empty';

  @override
  String get shoppingEmptyPrivateBody => 'Tap + to add your first item';

  @override
  String get shoppingEmptyPublicSoloHeading => 'Your public list is empty';

  @override
  String get shoppingEmptyPublicSoloBody => 'Add items to share with family';

  @override
  String get shoppingEmptyPublicFamilyHeading => 'Nothing here yet';

  @override
  String get shoppingEmptyPublicFamilyBody => 'Anyone can add — be the first';

  @override
  String get shoppingEmptyCta => 'Add an item';

  @override
  String get shoppingFilterLedgerAll => 'All';

  @override
  String get shoppingFilterStatusActive => 'Active only';

  @override
  String get shoppingFilterStatusAll => 'All items';

  @override
  String get shoppingFilterCategory => 'Category';

  @override
  String get shoppingSegmentPublic => 'Public';

  @override
  String get shoppingSectionToBuy => 'To Buy';

  @override
  String get shoppingListScreenTitle => 'Shopping List';

  @override
  String get shoppingSegmentAll => 'All';

  @override
  String get shoppingSegmentPrivate => 'Private';

  @override
  String get shoppingFilterPrivate => 'Private';

  @override
  String get shoppingFormListTypeLabel => 'Type';

  @override
  String get shoppingListTypeLockedHint => 'Cannot be changed after creation';

  @override
  String get shoppingCompletedDivider => 'Completed';

  @override
  String get shoppingScopeAll => 'All';

  @override
  String get shoppingScopePersonal => 'Personal';

  @override
  String get shoppingClearCompletedAction => 'Clear all';

  @override
  String get shoppingFilteredEmpty => 'No shopping items match your filters';

  @override
  String get shoppingClearCompletedTitle => 'Clear all completed?';

  @override
  String get shoppingClearCompletedBody =>
      'All completed items will be removed from the list.';

  @override
  String get shoppingClearCompletedConfirm => 'Clear';

  @override
  String get shoppingClearCompletedSnackBar => 'Completed items cleared';

  @override
  String get shoppingListLoadError => 'Couldn\'t load your list';

  @override
  String get shoppingRetry => 'Retry';

  @override
  String get shoppingBatchDeleteTitle => 'Delete items?';

  @override
  String shoppingBatchDeleteBody(int count) {
    return 'Delete $count selected items?';
  }

  @override
  String get shoppingBatchDeleteConfirm => 'Delete';

  @override
  String get shoppingBatchDeletedSnackBar => 'Items deleted';

  @override
  String get shoppingBatchDeleteAction => 'Delete';

  @override
  String get shoppingBatchCancel => 'Cancel';

  @override
  String get shoppingBatchSelectAll => 'Select All';

  @override
  String shoppingSelectionCount(int count) {
    return '$count';
  }

  @override
  String shoppingBatchSelectingCount(int count) {
    return '$count selected';
  }

  @override
  String get shoppingFormAddTitle => 'Add item';

  @override
  String get shoppingFormEditTitle => 'Edit item';

  @override
  String get shoppingFormSave => 'Save';

  @override
  String get shoppingFormNameLabel => 'Item name';

  @override
  String get shoppingFormNameRequired => 'Name is required';

  @override
  String get shoppingFormLedgerLabel => 'Ledger';

  @override
  String get shoppingFormLedgerDaily => 'Daily';

  @override
  String get shoppingFormLedgerJoy => 'Joy';

  @override
  String get shoppingFormCategoryLabel => 'Category';

  @override
  String get shoppingFormNoCategorySelected => 'No category';

  @override
  String get shoppingFormChangeCategory => 'Change';

  @override
  String get shoppingFormTagsLabel => 'Tags (comma-separated)';

  @override
  String get shoppingFormNoteLabel => 'Note';

  @override
  String get shoppingFormNotePlaceholder => 'Add any needed note';

  @override
  String get shoppingFormQuantityLabel => 'Quantity';

  @override
  String get shoppingFormPrice => 'Estimated price';

  @override
  String get shoppingFormSaveError => 'Failed to save. Please try again.';

  @override
  String get shoppingListTypeCreateHint =>
      'Type cannot be changed after saving';

  @override
  String get shoppingFormSaving => 'Saving…';

  @override
  String get shoppingFormPricePlaceholder => 'Not entered';

  @override
  String get shoppingVoiceManualTitle => 'Enter by voice';

  @override
  String get shoppingVoiceManualHelp =>
      'Say the item, quantity, purpose, category, and estimated price together';

  @override
  String get shoppingVoicePrivacy => 'On-device recognition preferred';

  @override
  String get shoppingVoiceListeningStatus => 'Listening';

  @override
  String get shoppingVoiceProcessingStatus => 'Analyzing';

  @override
  String get shoppingVoiceReviewStatus => 'Filled into the form';

  @override
  String get shoppingVoiceUnavailableStatus => 'Microphone unavailable';

  @override
  String get shoppingVoiceKeyboardAction => 'Return to manual input';

  @override
  String get shoppingVoiceListeningPlaceholder =>
      '“Two bottles of milk, daily, estimated price ¥500…”';

  @override
  String get shoppingVoiceProcessingPlaceholder =>
      '“Two bottles of milk, daily, estimated price ¥500”';

  @override
  String get shoppingVoiceReviewPlaceholder =>
      'Review the information added to the form';

  @override
  String get shoppingVoiceStopAction => 'Stop now and analyze';

  @override
  String get shoppingVoiceRerecordAction => 'Record again';

  @override
  String get shoppingVoiceListeningHelp =>
      'Pause for about 3 seconds to analyze automatically · Tap the square to stop now';

  @override
  String get shoppingVoiceProcessingHelp =>
      'Organizing your speech into shopping item fields';

  @override
  String get shoppingVoiceReviewHelp =>
      'Review the details, then tap Save at the top right to add';

  @override
  String get shoppingVoiceUnavailableHelp => 'Manual input remains available';

  @override
  String get shoppingVoiceSettingsAction => 'Microphone help';

  @override
  String get entryVoiceLaunchHelp =>
      'Say the amount, merchant, category, and date in one go';

  @override
  String get entryVoicePrivacy => 'Processed only on this device';

  @override
  String get entryVoiceIdleStatus => 'Waiting for voice input';

  @override
  String get entryVoiceListeningStatus => 'Listening';

  @override
  String get entryVoiceProcessingStatus => 'Organizing the details';

  @override
  String get entryVoiceReviewStatus => 'Added to this entry';

  @override
  String get entryVoiceUnavailableStatus => 'Voice input unavailable';

  @override
  String get entryVoiceIdleTranscript => 'Ready when you are';

  @override
  String get entryVoiceListeningPlaceholder =>
      '“Forest Café, lunch, 2,380 yen…”';

  @override
  String get entryVoiceProcessingPlaceholder =>
      '“Forest Café, lunch, 2,380 yen”';

  @override
  String get entryVoiceIdleHelp =>
      'Tap the microphone to start voice recording';

  @override
  String get entryVoiceListeningHelp =>
      'Pause to recognize automatically, or tap to finish now';

  @override
  String get entryVoiceProcessingHelp =>
      'Adding the recognition result to this form';

  @override
  String get entryVoiceReviewHelp =>
      'Tap the microphone to record again, or edit and record';

  @override
  String get entryVoiceUnavailableHelp =>
      'Allow microphone access in system Settings, or continue with manual input';

  @override
  String get entryVoiceKeyboardAction => 'Switch to keyboard input';

  @override
  String get entryVoiceStartAction => 'Start voice input';

  @override
  String get entryVoiceStopAction => 'Finish now and analyze';

  @override
  String get entryVoiceRerecordAction => 'Record again';

  @override
  String get entryVoiceSourceBadge => 'Voice filled';

  @override
  String get entryCategorySelectRequired => 'Select required';

  @override
  String get entryContinuousReturnHome => 'Return home after recording';

  @override
  String get entryContinuousKeepNext =>
      'Continue to the next entry after recording';

  @override
  String get entryContinuousEnable => 'Continuous entry';

  @override
  String get entryContinuousDisable => 'Turn off continuous entry';

  @override
  String get currencySelectorTitle => 'Select currency';

  @override
  String get currencySelectorMore => 'More';

  @override
  String get currencySelectorSearchHint => 'Search by code or name';

  @override
  String get currencySelectorNoResults => 'No matching currency';

  @override
  String get currencyNameJpy => 'Japanese Yen';

  @override
  String get currencyNameUsd => 'US Dollar';

  @override
  String get currencyNameEur => 'Euro';

  @override
  String get currencyNameCny => 'Chinese Yuan';

  @override
  String get currencyNameHkd => 'Hong Kong Dollar';

  @override
  String get currencyNameGbp => 'British Pound';

  @override
  String get currencyNameKrw => 'South Korean Won';

  @override
  String get currencyNameTwd => 'New Taiwan Dollar';

  @override
  String get currencyNameSgd => 'Singapore Dollar';

  @override
  String get currencyNameAud => 'Australian Dollar';

  @override
  String get currencyNameCad => 'Canadian Dollar';

  @override
  String get currencyNameChf => 'Swiss Franc';

  @override
  String get currencyNameThb => 'Thai Baht';

  @override
  String get currencyNameInr => 'Indian Rupee';

  @override
  String get currencyNameIdr => 'Indonesian Rupiah';

  @override
  String get currencyNameMyr => 'Malaysian Ringgit';

  @override
  String get currencyNamePhp => 'Philippine Peso';

  @override
  String get currencyNameVnd => 'Vietnamese Dong';

  @override
  String get currencyNameNzd => 'New Zealand Dollar';

  @override
  String get currencyNameBrl => 'Brazilian Real';

  @override
  String get currencyNameRub => 'Russian Ruble';

  @override
  String get currencyNameZar => 'South African Rand';

  @override
  String get currencyNameSek => 'Swedish Krona';

  @override
  String get currencyNameNok => 'Norwegian Krone';

  @override
  String get currencyNameDkk => 'Danish Krone';

  @override
  String get currencyNameMxn => 'Mexican Peso';

  @override
  String get currencyNameTry => 'Turkish Lira';

  @override
  String get currencyNameAed => 'UAE Dirham';

  @override
  String get currencyNameSar => 'Saudi Riyal';

  @override
  String get currencyNamePln => 'Polish Zloty';

  @override
  String conversionPreviewRateRow(String code, String rate, String date) {
    return '$code 1 = ¥$rate · $date';
  }

  @override
  String conversionStalenessCached(String date) {
    return 'Using cached rate from $date';
  }

  @override
  String conversionStalenessWeekend(String date) {
    return '$date (most recent business day)';
  }

  @override
  String get conversionRateRequired =>
      'Rate unavailable — please enter a rate manually';

  @override
  String get editOriginalAmountLabel => 'Original amount';

  @override
  String get editRateLabel => 'Rate';

  @override
  String get editJpyDerivedLabel => 'JPY (derived)';

  @override
  String get currencyRateDateLabel => 'Rate date';

  @override
  String get editRateRequired => 'Please enter a rate';

  @override
  String get editRateInvalid => 'Enter a positive number';

  @override
  String get editAmountRequired => 'Please enter an amount';

  @override
  String get editAmountInvalid => 'Enter a positive number';

  @override
  String get changeRateDialogTitle => 'Rate confirmation';

  @override
  String get changeRateDialogBody =>
      'You set the rate manually. Re-fetch the rate for the new date?';

  @override
  String get changeRateKeepManual => 'Keep manual rate';

  @override
  String get changeRateRefetch => 'Re-fetch for new date';

  @override
  String rateChangedToast(String oldJpy, String newJpy) {
    return 'JPY adjusted: $oldJpy → $newJpy (rate updated)';
  }

  @override
  String get rateChangedUndo => 'Undo';

  @override
  String get analyticsDonutHeroCap => 'Where your money went this month';

  @override
  String analyticsDonutHeroTag(int count, int month) {
    return '$count entries · month $month';
  }

  @override
  String analyticsDonutCenterCount(int count) {
    return '$count entries';
  }

  @override
  String get analyticsCalWeekdayMon => 'M';

  @override
  String get analyticsCalWeekdayTue => 'T';

  @override
  String get analyticsCalWeekdayWed => 'W';

  @override
  String get analyticsCalWeekdayThu => 'T';

  @override
  String get analyticsCalWeekdayFri => 'F';

  @override
  String get analyticsCalWeekdaySat => 'S';

  @override
  String get analyticsCalWeekdaySun => 'S';

  @override
  String get recognitionBandSuggestedCategory => 'Suggested category';

  @override
  String get recognitionAlternatesMore => 'More';

  @override
  String get onboardingIntroTitle => 'Home Pocket';

  @override
  String get onboardingWelcomeBadge => 'Budgeting that keeps you smiling';

  @override
  String get onboardingWelcomeBrand => 'HOME POCKET';

  @override
  String get onboardingWelcomeTagline =>
      'Every entry brings a little joy.\nBuild a brighter relationship with money.';

  @override
  String get onboardingPrivacyTitle => 'Your data,\nin your hands.';

  @override
  String get onboardingPrivacySubtitle =>
      'Everything stays on your device. No account, no server needed.';

  @override
  String get onboardingPrivacyCardLocalTitle => 'Stored on device';

  @override
  String get onboardingPrivacyCardLocalBody => 'Never sent to the cloud';

  @override
  String get onboardingPrivacyCardE2eTitle => 'End-to-end encryption';

  @override
  String get onboardingPrivacyCardE2eBody => 'Only you hold the key';

  @override
  String get onboardingPrivacyCardTamperTitle => 'Tamper-proof';

  @override
  String get onboardingPrivacyCardTamperBody =>
      'Records protected by a hash chain';

  @override
  String get onboardingJoyTitle => 'Add a feeling to every expense.';

  @override
  String get onboardingJoySubtitle =>
      'Tracking is not a chore. Capture how satisfied you felt, too.';

  @override
  String get onboardingJoyCaption => 'Record satisfaction with one tap.';

  @override
  String get onboardingJoyAccent => 'Money is for filling your own life.';

  @override
  String get onboardingIntroContinue => 'Get started';

  @override
  String get onboardingIntroSkip => 'Skip';

  @override
  String get onboardingSetupEyebrow => 'Final step';

  @override
  String get onboardingSetupTopbar => 'Initial setup';

  @override
  String get onboardingSetupTitle => 'Basic setup';

  @override
  String get onboardingRowName => 'Name · Required';

  @override
  String get onboardingRowLanguage => 'Display language';

  @override
  String get onboardingLanguageAuto => 'Auto';

  @override
  String get onboardingLanguageAutoNote =>
      'With “Auto”, unsupported system languages fall back to Japanese.';

  @override
  String get onboardingRowCurrency => 'Currency';

  @override
  String get onboardingRowVoice => 'Voice input language';

  @override
  String get onboardingStart => 'Start with these settings';

  @override
  String get onboardingPreparingHome => 'Preparing your home…';

  @override
  String get onboardingPrivacyTagLocal => 'LOCAL';

  @override
  String get onboardingPrivacyTagE2ee => 'E2EE';

  @override
  String get onboardingPrivacyTagSafe => 'SAFE';

  @override
  String get onboardingAvatarChange => 'Change image';

  @override
  String get onboardingSecurityTitle => 'Protect your ledger';

  @override
  String get onboardingSecurityDescription =>
      'When enabled, identity verification is required whenever you open the app.';

  @override
  String get onboardingSecurityEnable => 'Enable security protection';

  @override
  String get onboardingSecurityDeferTitle => 'Decide later';

  @override
  String get onboardingSecurityDeferBody =>
      'You can enable it anytime in Settings';

  @override
  String get onboardingSecurityMethodLabel => 'Unlock method';

  @override
  String get onboardingSecurityBiometric => 'Biometrics';

  @override
  String get onboardingSecurityBiometricDescription =>
      'Unlock quickly with Face ID or fingerprint';

  @override
  String get onboardingSecurityRecommended => 'Recommended';

  @override
  String get onboardingSecurityPin => 'App lock';

  @override
  String get onboardingSecurityPinDescription => 'Unlock with a 4-digit PIN';

  @override
  String get onboardingSecurityPinMissing => 'PIN has not been set';

  @override
  String get onboardingSecurityPinSetupHint => 'Enter it twice to enable';

  @override
  String get onboardingSecurityPinSetup => 'Set a 4-digit PIN';

  @override
  String get onboardingSecurityPinComplete => 'PIN is set';

  @override
  String get onboardingSecurityPinCompleteDescription =>
      'Protected by a 4-digit PIN';

  @override
  String get onboardingSecurityPinChange => 'Change PIN';

  @override
  String get onboardingSetupNameRequiredHint => 'Enter your name to continue';

  @override
  String get onboardingSetupPinRequiredHint => 'Set a PIN to continue';

  @override
  String get onboardingSetupChangeLaterHint =>
      'You can change these anytime in Settings';

  @override
  String get onboardingLockTitle => 'Set up an app lock?';

  @override
  String get onboardingLockDescription =>
      'An app lock keeps your ledger extra safe.';

  @override
  String get onboardingLockSkip => 'Skip';

  @override
  String get onboardingLockSetupNow => 'Set up now';

  @override
  String get appLockPinTitle => 'Enter passcode';

  @override
  String get appLockFaceIdPrompt => 'Look at your device to use Face ID';

  @override
  String get appLockFaceIdRetry => 'Retry';

  @override
  String get appLockUsePasscode => 'Use passcode';

  @override
  String get appLockForgotPin => 'Forgot your passcode?';

  @override
  String get appLockForgotPinExplanation =>
      'If you forget your passcode, it cannot be recovered. You will need to reinstall the app, which will erase any local data that has not yet been synced.';

  @override
  String get appLockSetPinTitle => 'Set a passcode';

  @override
  String get appLockConfirmPinTitle => 'Re-enter passcode';

  @override
  String get appLockPinMismatch => 'Passcodes don\'t match';

  @override
  String get appLockReauthReason => 'Verify your identity to continue';

  @override
  String get securityAppLock => 'App lock';

  @override
  String get securityAppLockDescription =>
      'Protect the app with a passcode on launch and when returning to the foreground.';

  @override
  String get securityAppLockOff => 'Off';

  @override
  String get securityAppLockPinOnly => 'PIN';

  @override
  String securityAppLockBiometricAndPin(String biometric) {
    return '$biometric + PIN';
  }

  @override
  String get securityFaceId => 'Face ID';

  @override
  String get securityFingerprint => 'Fingerprint';

  @override
  String get securityBiometricUnlock => 'Unlock with biometrics';

  @override
  String get securityBiometricUnlockDescription =>
      'Unlock the app with Face ID or your fingerprint.';

  @override
  String get securityChangePin => 'Change passcode';

  @override
  String get legalSponsorSectionTitle => 'Legal & Support';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get tokushoNotice => 'Commercial Transaction Notice';

  @override
  String get tokushoNoticeSubtitle =>
      'Required for offering the service in Japan';

  @override
  String get sponsorRow => 'Support Development';

  @override
  String get sponsorRowSubtitle => 'To keep the app running ad-free';

  @override
  String get sponsorLaunchError => 'Couldn\'t open the browser';

  @override
  String get legalNavigationSubtitle =>
      'Privacy, terms, and open-source licenses';

  @override
  String get privacyPolicyDescription => 'How your data is handled';

  @override
  String get termsOfUseDescription => 'Service terms and conditions';

  @override
  String get openSourceLicensesDescription => 'Libraries used by the app';

  @override
  String get sponsorSectionTitle => 'Support Development';

  @override
  String get sponsorCardTitle => 'Help this quiet household ledger grow';

  @override
  String get sponsorCardBody =>
      'The support and contact page opens in your external browser. It does not affect app features or access to your data.';

  @override
  String get sponsorButton => 'About supporting us';

  @override
  String get legalLinkLaunchError => 'Couldn\'t open the link';

  @override
  String analyticsTrendInsightTotal(String amount) {
    return 'This month $amount';
  }

  @override
  String analyticsTrendInsightTotalDelta(
    String amount,
    int pct,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'less': 'lower',
      'more': 'higher',
      'other': '',
    });
    return 'This month $amount · $pct% $_temp0 than last month';
  }

  @override
  String analyticsTrendInsightTotalSame(String amount) {
    return 'This month $amount · about the same as last month';
  }

  @override
  String analyticsTrendInsightDaily(String amount) {
    return 'Daily spending $amount';
  }

  @override
  String analyticsTrendInsightDailyDelta(
    String amount,
    int pct,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'less': 'lower',
      'more': 'higher',
      'other': '',
    });
    return 'Daily spending $amount · $pct% $_temp0 than last month';
  }

  @override
  String analyticsTrendInsightDailySame(String amount) {
    return 'Daily spending $amount · about the same as last month';
  }

  @override
  String analyticsTrendInsightJoy(String amount) {
    return 'This month\'s joy spending $amount';
  }

  @override
  String analyticsCalSummary(int count, int days) {
    return '$count this month · logged across $days days';
  }

  @override
  String analyticsJoyCalendarDayHead(int month, int day, int count) {
    return '$month/$day · $count joy moments';
  }

  @override
  String get analyticsJoyDrawerToggleExpand => 'Expand joy spending breakdown';

  @override
  String get analyticsJoyDrawerToggleCollapse =>
      'Collapse joy spending breakdown';

  @override
  String get syncQueueNeedsAttentionBadge => 'Needs attention';

  @override
  String get syncQueueNeedsAttentionDescription =>
      'Some changes need your attention';

  @override
  String get syncQueueNeedsAttentionTitle => 'Sync needs attention';

  @override
  String get syncQueuePendingTitle => 'Changes waiting to sync';

  @override
  String syncQueueCounts(int pendingCount, int deadLetterCount) {
    return '$pendingCount waiting · $deadLetterCount need attention';
  }

  @override
  String get syncQueueReconcileHint =>
      'The encrypted changes are preserved. Retry them first; a full reconciliation is still recommended afterward.';

  @override
  String get syncQueueRetryAll => 'Retry all';

  @override
  String get syncQueueDiscardAll => 'Discard';

  @override
  String get syncQueueRetryFailed => 'Some changes still need attention';

  @override
  String get syncQueueRetrySucceeded =>
      'Queued changes sent. Reconciliation is still recommended.';

  @override
  String get syncQueueDiscardConfirmTitle => 'Discard unsent changes?';

  @override
  String get syncQueueDiscardConfirmBody =>
      'This permanently removes the preserved outbound changes from this device. This cannot be undone.';

  @override
  String get syncQueueCancel => 'Cancel';

  @override
  String get syncQueueDiscardConfirmAction => 'Discard permanently';

  @override
  String get syncQueueDiscardFailed =>
      'The unsent changes could not be discarded';

  @override
  String get inboundSyncSectionTitle => 'Received changes held for review';

  @override
  String inboundSyncCount(int count) {
    return '$count received changes quarantined';
  }

  @override
  String inboundSyncErrorCode(String errorCode) {
    return 'Safe code: $errorCode';
  }

  @override
  String get inboundSyncRetryOne => 'Retry';

  @override
  String get inboundSyncDiscardOne => 'Discard received change';

  @override
  String get inboundSyncDiscardConfirmTitle => 'Discard this received change?';

  @override
  String get inboundSyncDiscardConfirmBody =>
      'This permanently removes the quarantined received change from this device. The relay copy was already acknowledged and this cannot be undone.';

  @override
  String get syncAttentionDiscardConfirmTitle =>
      'Discard preserved sync changes?';

  @override
  String get syncAttentionDiscardConfirmBody =>
      'This permanently removes all preserved outbound failures and quarantined received changes from this device. This cannot be undone.';

  @override
  String get familySyncTransferOwner => 'Transfer ownership';

  @override
  String get familySyncTransferOwnerSelect => 'Choose the new owner';

  @override
  String get familySyncTransferOwnerConfirmTitle => 'Transfer ownership?';

  @override
  String familySyncTransferOwnerConfirmBody(String memberName) {
    return '$memberName will manage members, invitations, and the family group.';
  }

  @override
  String get familySyncTransferOwnerFinalTitle => 'Final confirmation';

  @override
  String familySyncTransferOwnerFinalBody(String memberName) {
    return 'A new encryption key will be issued to every active device. After transfer, you become a regular member. Transfer ownership to $memberName?';
  }

  @override
  String get familySyncTransferOwnerSuccess => 'Ownership transferred securely';

  @override
  String get familySyncTransferOwnerNotReady =>
      'Ownership actions are unavailable until the current encryption key is ready';

  @override
  String get familySyncTransferOwnerInvalidTarget =>
      'Choose a different active member';

  @override
  String familySyncTransferOwnerFailed(String message) {
    return 'Could not transfer ownership: $message';
  }

  @override
  String get transactionPhotoBoundaryTitle => 'Receipt photo';

  @override
  String get transactionPhotoLocalOnlyBody =>
      'This receipt photo stays on this device and is not included in family sync or backups.';

  @override
  String get transactionPhotoUnavailableBody =>
      'The receipt photo is available only on the device that recorded this transaction and is not included in family sync or backups.';

  @override
  String get familySyncMemberHistory => 'MEMBER HISTORY';

  @override
  String familySyncRequestedAt(String date) {
    return 'Requested $date';
  }

  @override
  String familySyncJoinedAt(String role, String date) {
    return '$role · Joined $date';
  }

  @override
  String familySyncConfirmedAt(String role, String date) {
    return '$role · Confirmed $date';
  }

  @override
  String familySyncRemovedAtReason(String reason, String date) {
    return '$reason · $date';
  }

  @override
  String get familySyncRemovalReasonLeft => 'Left the family';

  @override
  String get familySyncRemovalReasonRemoved => 'Removed by owner';

  @override
  String get familySyncRemovalReasonDissolved => 'Family dissolved';

  @override
  String get familySyncRemovalReasonRejected => 'Request rejected';

  @override
  String get familySyncRemovalReasonCancelled => 'Request cancelled';

  @override
  String get familySyncRemovalReasonExpired => 'Request expired';

  @override
  String get familySyncRemovalReasonUnknown => 'Membership ended';
}
