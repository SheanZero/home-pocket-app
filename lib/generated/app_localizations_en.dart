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
  String get themeSystem => 'System';

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
  String get homeFamilyInviteTitle => 'Invite Family';

  @override
  String get homeFamilyInviteDesc => 'Share your ledger with your partner';

  @override
  String get homeFamilyBannerTitle => 'Manage Together';

  @override
  String get homeFamilyBannerSubtitle =>
      'Invite your partner to share your ledger in real time';

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
  String get homeRingSectionTitleSingle => 'Joy Index';

  @override
  String get homeRingSectionTitleGroup => 'Family Joy';

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

  @override
  String groupDefaultName(String name) {
    return '$name\'s Family';
  }

  @override
  String get groupCreate => 'Create Group';

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
  String get groupShareCode => 'Share Invite Code';

  @override
  String get groupEnterCode => 'Enter Invite Code';

  @override
  String get groupVerify => 'Verify';

  @override
  String get groupConfirmJoin => 'Confirm Join';

  @override
  String get groupJoinTarget => 'Group to Join';

  @override
  String get groupWaitingApproval => 'Waiting for Owner approval...';

  @override
  String groupWaitingDesc(String name) {
    return '$name is reviewing your request';
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
  String get groupChoiceTitle => 'Connect with family';

  @override
  String get groupChoiceSubtitle => 'Manage your household budget together';

  @override
  String get groupCreateDesc => 'Create a new family group and invite members';

  @override
  String get groupJoinDesc => 'Enter an invite code to join an existing group';

  @override
  String get groupE2eeHint => 'Privacy protected with E2E encryption';

  @override
  String get groupInviteMembers => 'Invite new member';

  @override
  String get groupDisband => 'Disband Group';

  @override
  String get groupCancel => 'Cancel';

  @override
  String get groupWaitingHint1 => 'Please wait for the notification';

  @override
  String get groupWaitingHint2 => 'It\'s safe to close the app';

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
  String get analyticsJoyMetricVariantChipLabel => 'Entries';

  @override
  String get analyticsJoyMetricVariantSheetTitle => 'Joy metric variant';

  @override
  String get analyticsJoyMetricVariantOptionAll => 'All entries';

  @override
  String get analyticsJoyMetricVariantOptionManualOnly => 'Manual entries only';

  @override
  String get analyticsJoyMetricVariantManualOnlyExplain =>
      'Manual entries only · excludes voice-estimated entries';

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
  String get analyticsGroupHeaderTime => '━ Time ━';

  @override
  String get analyticsGroupHeaderDistribution => '━ Distribution ━';

  @override
  String get analyticsGroupHeaderStories => '━ Stories ━';

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
  String get analyticsCategoryDonutOther => 'Other';

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
  String get calMonthTotal => 'Monthly Spend';

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
    return 'Categories ($n)';
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
  String get shoppingFormQuantityLabel => 'Quantity';

  @override
  String get shoppingFormPrice => 'Estimated price';

  @override
  String get shoppingFormSaveError => 'Failed to save. Please try again.';

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
}
