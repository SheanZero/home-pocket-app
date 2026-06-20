// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'まもる家計簿';

  @override
  String get home => 'ホーム';

  @override
  String get transactions => '取引';

  @override
  String get analytics => '分析';

  @override
  String get settings => '設定';

  @override
  String get settingsJoyTargetTitle => 'ときめき目標';

  @override
  String settingsJoyTargetCurrentConfigured(int target) {
    return '現在の目標: $target';
  }

  @override
  String settingsJoyTargetCurrentRecommended(int target) {
    return '参照値: $target';
  }

  @override
  String settingsJoyTargetRecommendation(int target) {
    return '最近のときめき記録からの参照値: $target';
  }

  @override
  String get settingsJoyTargetFallback => '記録が増えると参照値を表示できます。今は初期の参照値を使います。';

  @override
  String get settingsJoyTargetInputLabel => '月間ときめき目標';

  @override
  String get settingsJoyTargetInputHint => '正の整数を入力';

  @override
  String get settingsJoyTargetInvalid => '0より大きい整数を入力してください。';

  @override
  String get settingsJoyTargetUseRecommendation => '参照値を使う';

  @override
  String get settingsJoyTargetSave => '保存';

  @override
  String get settingsJoyTargetCancel => 'キャンセル';

  @override
  String get ledger => '帳簿';

  @override
  String get newTransaction => '新しい取引';

  @override
  String get amount => '金額';

  @override
  String get category => 'カテゴリ';

  @override
  String get note => 'メモ';

  @override
  String get merchant => '店舗';

  @override
  String get date => '日付';

  @override
  String get transactionTypeExpense => '支出';

  @override
  String get transactionTypeIncome => '収入';

  @override
  String get categoryFood => '食費';

  @override
  String get categoryHousing => '住居';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryUtilities => '光熱費';

  @override
  String get categoryEntertainment => '娯楽';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryHealth => '医療';

  @override
  String get categoryShopping => '買物';

  @override
  String get categoryOther => 'その他';

  @override
  String get dailyLedger => '日々の帳';

  @override
  String get joyLedger => 'ときめき帳';

  @override
  String get daily => '日常';

  @override
  String get joy => 'ときめき';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get confirm => '確認';

  @override
  String get ok => 'OK';

  @override
  String get retry => '再試行';

  @override
  String get search => '検索';

  @override
  String get filter => 'フィルター';

  @override
  String get sort => '並び替え';

  @override
  String get refresh => '更新';

  @override
  String get loading => '読み込み中...';

  @override
  String get noData => 'データがありません';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get errorNetwork => 'ネットワークエラー';

  @override
  String get errorUnknown => '不明なエラーが発生しました';

  @override
  String get errorInvalidAmount => '無効な金額です';

  @override
  String get errorRequired => '必須項目です';

  @override
  String get errorInvalidDate => '無効な日付です';

  @override
  String get errorDatabaseWrite => 'データベース書込エラー';

  @override
  String get errorDatabaseRead => 'データベース読取エラー';

  @override
  String get errorEncryption => '暗号化エラー';

  @override
  String get errorSync => '同期エラー';

  @override
  String get errorBiometric => '生体認証エラー';

  @override
  String get errorPermission => '権限エラー';

  @override
  String errorMinAmount(double min) {
    return '$min以上の金額を入力してください';
  }

  @override
  String errorMaxAmount(double max) {
    return '$max以下の金額を入力してください';
  }

  @override
  String get successSaved => '保存しました';

  @override
  String get successDeleted => '削除しました';

  @override
  String get successSynced => '同期しました';

  @override
  String get merchantPlaceholder => '店舗名を入力';

  @override
  String get notePlaceholder => 'メモを入力';

  @override
  String get noteOptional => 'メモ（任意）';

  @override
  String get pleaseEnterAmount => '金額を入力してください';

  @override
  String get amountMustBeGreaterThanZero => '金額は0より大きくしてください';

  @override
  String get pleaseSelectCategory => 'カテゴリを選択してください';

  @override
  String get successKeepGoing => '記録しました。続けて記録できます';

  @override
  String get recordingExitLink => '記録を終了';

  @override
  String get entrySavedDone => '記録できました！';

  @override
  String get continuousKeepGoing => '記録しました。続けてどうぞ';

  @override
  String get continuousExitHint => '終了ボタンでいつでも戻れます';

  @override
  String get noTransactionsYet => '取引がまだありません';

  @override
  String get tapToAddFirstTransaction => '＋をタップして最初の取引を追加';

  @override
  String get transactionSaved => '取引を保存しました';

  @override
  String get failedToSave => '保存に失敗しました';

  @override
  String get transactionEditTitle => '明細編集';

  @override
  String get ocrReviewTitle => 'レシート確認';

  @override
  String get ocrReviewEmptyDraftBanner => 'OCRはまだ実装されていません。手動で入力してください。';

  @override
  String get transactionUpdated => '明細を更新しました';

  @override
  String get failedToUpdate => '更新に失敗しました';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsWeekStart => '週の開始日';

  @override
  String get settingsWeekStartMonday => '月曜日';

  @override
  String get settingsWeekStartSunday => '日曜日';

  @override
  String get security => 'セキュリティ';

  @override
  String get biometricLock => '生体認証ロック';

  @override
  String get biometricLockDescription => 'Face ID / 指紋認証でロック解除';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDescription => '予算アラートと同期通知';

  @override
  String get dataManagement => 'データ管理';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get exportBackupDescription => '暗号化バックアップファイルを作成';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String get importBackupDescription => 'バックアップファイルから復元';

  @override
  String get deleteAllData => '全データを削除';

  @override
  String get deleteAllDataDescription => 'すべての記録を完全に削除';

  @override
  String get deleteAllDataConfirmation => 'この操作は取り消せません。すべてのデータを削除してもよろしいですか？';

  @override
  String get allDataDeleted => '全データを削除しました';

  @override
  String get deleteFailed => '削除に失敗しました';

  @override
  String get backupExportedSuccessfully => 'バックアップをエクスポートしました';

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String get backupImportedSuccessfully => 'バックアップをインポートしました';

  @override
  String get importFailed => 'インポートに失敗しました';

  @override
  String get setBackupPassword => 'バックアップパスワードを設定';

  @override
  String get enterBackupPassword => 'バックアップパスワードを入力';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get confirmPassword => 'パスワードを確認';

  @override
  String get passwordMinLength => 'パスワードは8文字以上にしてください';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get about => 'このアプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get generateDemoData => 'デモデータを生成';

  @override
  String get generateDemoDataDescription => '過去3か月分のサンプル取引を作成し、分析機能をデモします。';

  @override
  String get generate => '生成';

  @override
  String get demoDataGenerated => 'デモデータを生成しました！引っ張って更新してください。';

  @override
  String get language => '言語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String get deleteTransactionConfirmation => 'この取引を削除しますか？';

  @override
  String get error => 'エラー';

  @override
  String initializationError(String error) {
    return '初期化に失敗しました: $error';
  }

  @override
  String get profileSetup => 'はじめまして！';

  @override
  String get profileSetupSubtitle => 'まもる家計簿へようこそ';

  @override
  String get profileNickname => 'あなたの呼び名';

  @override
  String get profileNicknamePlaceholder => 'ニックネームを入力';

  @override
  String get profileStart => 'はじめる';

  @override
  String get profileSelectAvatar => 'アバターを選択';

  @override
  String get profileEmojiTab => 'Emoji';

  @override
  String get profilePhotoTab => '写真';

  @override
  String get profileEdit => 'プロフィールを編集';

  @override
  String get profileCancel => 'キャンセル';

  @override
  String get profileDone => '完了';

  @override
  String get profilePreview => 'プレビュー';

  @override
  String get welcomeTo => 'まもる家計簿へようこそ';

  @override
  String get profileNameRequired => 'ニックネームを入力してください';

  @override
  String get profileSave => '保存';

  @override
  String get profileChangeAvatar => 'タップしてアバターを変更';

  @override
  String get profilePhotoPermissionDenied => '写真へのアクセスが拒否されました';

  @override
  String get profilePhotoFailed => '写真の読み込みに失敗しました';

  @override
  String get profileSaveFailed => '保存に失敗しました';

  @override
  String get profileNameTooLong => 'ニックネームは50文字以内で入力してください';

  @override
  String get profileUploadPhoto => '写真をアップロード';

  @override
  String get homeMonthlyExpense => '今月の出費';

  @override
  String get homeDailyExpense => '日常の支出';

  @override
  String get homeJoyExpense => 'ときめき支出';

  @override
  String get homeMonthComparison => '先月比';

  @override
  String homePreviousMonthAmount(String amount) {
    return '先月 $amount';
  }

  @override
  String get homeDailyLedgerTag => '日';

  @override
  String get homeJoyLedgerTag => '悦';

  @override
  String get homeSharedLedgerTag => '共';

  @override
  String homeShadowBookTitle(String memberName) {
    return '$memberNameの帳本';
  }

  @override
  String get homeJoyFullness => 'ときめき度';

  @override
  String get homeJoyPercentLabel => '今月のときめき支出の割合';

  @override
  String get homeFamilyInviteTitle => '家族を招待する';

  @override
  String get homeFamilyInviteDesc => 'パートナーと家計簿を共有しよう';

  @override
  String get homeFamilyBannerTitle => '家族と一緒に管理しよう';

  @override
  String get homeFamilyBannerSubtitle => 'パートナーを招待して、家計簿をリアルタイムで共有しよう';

  @override
  String get homeTodayTitle => '今日の記録';

  @override
  String homeTodayCount(int count) {
    return '$count件';
  }

  @override
  String get homePersonalMode => '個人モード';

  @override
  String get homeFamilyMode => '家族モード';

  @override
  String get homeTabHome => 'ホーム';

  @override
  String get homeTabList => '一覧';

  @override
  String get homeTabChart => 'チャート';

  @override
  String get homeTabShopping => '買い物';

  @override
  String homeMonthFormat(int year, int month) {
    return '$year年$month月';
  }

  @override
  String homeMonthLabel(int month) {
    return '$month月';
  }

  @override
  String homeRecentJoyTransaction(String merchant, int amount) {
    return '直近: $merchant ¥$amount';
  }

  @override
  String homeJoyChargeStatus(int fullness, double roi) {
    return 'ときめきの充実度 $fullness% · ときめき指数 $roi';
  }

  @override
  String homeMonthBadge(int percent) {
    return '今月 $percent%';
  }

  @override
  String get homeJoyIndexTooltip =>
      '外輪は有効な目標に向かう月間ときめき指数、中輪は満足度の平均、内輪は小確幸の回数（満足度6以上）。';

  @override
  String get homeJoyContributionTooltip =>
      '外輪は有効な目標に向かう月間ときめき指数、中輪は満足度の平均、内輪は小確幸の数です。';

  @override
  String homeJoyTargetReference(int target) {
    return '目標 $target';
  }

  @override
  String homeJoyTargetSemantics(String value, int target) {
    return 'ときめき指数 $value、目標 $target';
  }

  @override
  String get homeHeroCardLabelSingle => '今月の支出';

  @override
  String get homeHeroCardLabelGroup => '家族の支出';

  @override
  String homeHeroPreviousMonthSubline(String amount) {
    return '先月同期 $amount';
  }

  @override
  String get homeRingSectionTitleSingle => 'ときめき度';

  @override
  String get homeRingSectionTitleGroup => '家族の小確幸';

  @override
  String get homeBestJoyTagSingle => '今月の最愛';

  @override
  String get homeBestJoyTagGroup => '今月の最愛';

  @override
  String homeBestJoyAmountSat(String amount, int sat) {
    return '$amount・満足 $sat/10 ✨';
  }

  @override
  String get homeMembersSectionTitle => 'メンバー';

  @override
  String get homeNoJoyDataLegend => 'まだ記録なし';

  @override
  String get homeBestJoyEmptyTagPrimary => '今月の最愛';

  @override
  String get homeBestJoyEmptyBig => '初めてのときめき記録をつけよう';

  @override
  String get homeBestJoyEmptySmall => '今月の最愛がここに表示されます →';

  @override
  String get homeBestJoyAllNeutralBig => '一番大きな支出を評価して';

  @override
  String get homeBestJoyAllNeutralSmall => 'あなたの今月の最愛にしよう';

  @override
  String get homeAvgSatisfactionLegend => '満足度の平均';

  @override
  String get homeJoyContributionLegend => 'ときめき目標';

  @override
  String get homeHighlightsCountLegend => '小確幸';

  @override
  String get homeFamilyHighlightsLegend => '家族の小確幸';

  @override
  String get homeSharedJoyLegend => '共に好き';

  @override
  String get homeMedianSatisfactionLegend => '満足度の中央値';

  @override
  String get addTransaction => '取引を追加';

  @override
  String get manualInput => '手動';

  @override
  String get ocrScan => 'OCR';

  @override
  String get voiceInput => '音声';

  @override
  String get selectCategory => '分類を選択';

  @override
  String get searchCategory => '分類を検索...';

  @override
  String get expenseDetail => '支出の詳細';

  @override
  String get back => '戻る';

  @override
  String get record => '記録する';

  @override
  String get keyboardToolbarDone => '完了';

  @override
  String get enterStore => 'お店を入力';

  @override
  String get enterMemo => 'メモを入力...';

  @override
  String get expenseClassification => '用途';

  @override
  String get dailyExpense => '日常支出';

  @override
  String get joyExpense => 'ときめき支出';

  @override
  String get joyFullness => 'ときめき充盈度';

  @override
  String get addPhoto => '写真を追加';

  @override
  String get ocrScanTitle => 'OCRスキャン入力';

  @override
  String get ocrHint => 'レシートを枠内に収めてください';

  @override
  String get voiceRecognitionResult => '認識結果';

  @override
  String get recognitionResult => '認識結果';

  @override
  String get satisfactionLevel => '満足度';

  @override
  String get satisfactionBad => '無難';

  @override
  String get satisfactionSlightlyBad => '快適';

  @override
  String get satisfactionNormal => '順調';

  @override
  String get satisfactionGood => '満足';

  @override
  String get satisfactionVeryGood => '至福';

  @override
  String get satisfactionExcellent => '至福！';

  @override
  String get satisfactionLabelNeutral => '無難';

  @override
  String get satisfactionLabelOK => '快適';

  @override
  String get satisfactionLabelGood => '順調';

  @override
  String get satisfactionLabelGreat => '満足';

  @override
  String get satisfactionLabelAmazing => '至福';

  @override
  String get addSubcategory => '追加';

  @override
  String get addCategory => 'カテゴリを追加';

  @override
  String get editCategoryOrder => '順序を編集';

  @override
  String get dragToReorder => 'ドラッグして並べ替え';

  @override
  String get orderUpdated => '順序を更新しました';

  @override
  String get orderSaveFailed => '保存に失敗しました。再試行してください';

  @override
  String get discardUnsavedChanges => '未保存の変更を破棄しますか？';

  @override
  String get discardUnsavedChangesBody => '並び替えた内容は保存されず、元に戻ります。';

  @override
  String get keepEditing => '編集を続ける';

  @override
  String get discard => '破棄';

  @override
  String get holdToRecord => '押して話す';

  @override
  String get recording => '録音中…';

  @override
  String get todayDate => '今日';

  @override
  String get next => '次へ';

  @override
  String get voiceInputSettings => '音声認識';

  @override
  String get voiceLanguage => '認識言語';

  @override
  String get voiceLanguageSubtitle => '音声入力に使用する言語';

  @override
  String get familySync => 'ファミリー同期';

  @override
  String get familySyncShowMyCode => 'グループを作成';

  @override
  String get familySyncEnterPartnerCode => 'グループに参加';

  @override
  String get familySyncPairCode => '招待コード';

  @override
  String get familySyncScanOrEnter => 'この招待コードまたはQRを家族に共有して、グループに参加してもらいましょう';

  @override
  String get familySyncCodeExpired => 'コードの有効期限が切れました';

  @override
  String get familySyncRegenerate => '再生成';

  @override
  String get familySyncEnterDigitCode => '6桁の招待コードを入力';

  @override
  String get familySyncSubmit => '送信';

  @override
  String get familySyncPairedDevice => 'ファミリーグループ';

  @override
  String get familySyncPairInfo => 'グループ情報';

  @override
  String get familySyncPairId => 'グループID';

  @override
  String get familySyncPairedSince => 'ペアリング日';

  @override
  String get familySyncBookId => '帳簿ID';

  @override
  String get familySyncUnpair => 'ペアリング解除';

  @override
  String get familySyncUnpairDevice => 'デバイスのペアリング解除';

  @override
  String familySyncUnpairConfirm(String deviceName) {
    return '$deviceNameとのペアリングを解除しますか？再度ペアリングするまで同期は停止します。';
  }

  @override
  String familySyncUnpairFailed(String message) {
    return 'ペアリング解除に失敗: $message';
  }

  @override
  String get familySyncNoDevicePaired => '参加中のファミリーグループはありません';

  @override
  String get familySyncPairPrompt => 'ファミリーグループを作成または参加して取引を同期しましょう';

  @override
  String get familySyncStatusSynced => '接続済み・最新';

  @override
  String get familySyncStatusSyncing => 'グループと同期中...';

  @override
  String get familySyncStatusOffline => 'オフライン - 接続時に同期します';

  @override
  String get familySyncStatusError => '同期エラーが発生しました';

  @override
  String get familySyncStatusPairing => 'グループ設定中...';

  @override
  String get familySyncCheckingGroup => 'グループ状況を確認中...';

  @override
  String familySyncCheckFailed(String message) {
    return 'グループ状況を確認できません: $message';
  }

  @override
  String get familySyncStatusUnpaired => 'タップしてファミリーグループを作成または参加';

  @override
  String get familySyncBadgeSynced => '同期済み';

  @override
  String get familySyncBadgeSyncing => '同期中';

  @override
  String get familySyncBadgeOffline => 'オフライン';

  @override
  String get familySyncBadgeError => 'エラー';

  @override
  String get familySyncBadgePairing => '設定中';

  @override
  String get familySyncCreatingGroup => 'グループを作成しています...';

  @override
  String get familySyncJoinGroup => 'グループに参加';

  @override
  String get familySyncJoinSuccess => 'グループに参加しました。オーナーの承認を待っています...';

  @override
  String get familySyncLeaveGroup => 'グループを退出';

  @override
  String get familySyncDeactivateGroup => 'グループを無効化';

  @override
  String get familySyncLeaveGroupConfirm =>
      'このファミリーグループを退出しますか？再参加するまでこの端末での同期は停止します。';

  @override
  String get familySyncDeactivateGroupConfirm =>
      'このファミリーグループを全員に対して無効化しますか？新しいグループを作成するまで同期は停止します。';

  @override
  String familySyncLeaveGroupFailed(String message) {
    return 'グループ退出に失敗: $message';
  }

  @override
  String familySyncDeactivateGroupFailed(String message) {
    return 'グループ無効化に失敗: $message';
  }

  @override
  String get familySyncRegenerateInvite => '招待コードを再生成';

  @override
  String familySyncRegenerateInviteFailed(String message) {
    return '招待コードの再生成に失敗: $message';
  }

  @override
  String get familySyncMembers => 'メンバー';

  @override
  String familySyncMemberCount(int count) {
    return '$count人のメンバー';
  }

  @override
  String get familySyncRoleOwner => 'オーナー';

  @override
  String get familySyncRoleMember => 'メンバー';

  @override
  String get familySyncMemberStatusActive => '有効';

  @override
  String get familySyncMemberStatusPending => '承認待ち';

  @override
  String get familySyncRemoveMember => 'メンバーを削除';

  @override
  String familySyncRemoveMemberConfirm(String deviceName) {
    return '$deviceName をこのファミリーグループから削除しますか？';
  }

  @override
  String familySyncRemoveMemberFailed(String message) {
    return 'メンバー削除に失敗: $message';
  }

  @override
  String get familySyncBadgeUnpaired => '未ペアリング';

  @override
  String get familySyncShare => 'シェア';

  @override
  String familySyncExpiryLabel(String time) {
    return '有効期限: $time';
  }

  @override
  String get familySyncJoinTitle => '家族に参加する';

  @override
  String get familySyncJoinDescription => '家族から受け取った6桁の招待コードを入力してください';

  @override
  String get familySyncOrDivider => 'または';

  @override
  String get familySyncScanQr => 'QRコードをスキャン';

  @override
  String get familySyncWaitingTitle => '承認を待っています...';

  @override
  String get familySyncWaitingDescription =>
      'グループオーナーがあなたの参加リクエストを確認中です。確認されるまでお待ちください。';

  @override
  String get familySyncGroupLabel => 'グループ';

  @override
  String get familySyncStatusLabel => 'ステータス';

  @override
  String get familySyncApprovalTitle => 'メンバー承認';

  @override
  String get familySyncNewRequest => '新しい参加リクエスト';

  @override
  String get familySyncJoinRequestNotificationBody =>
      '家族メンバーがグループ参加を希望しています。続行するにはリクエストを確認してください。';

  @override
  String familySyncJoinRequestWithName(String deviceName) {
    return '$deviceName があなたの家計簿に参加したいです';
  }

  @override
  String get familySyncMemberConfirmedNotificationTitle => 'グループの準備ができました';

  @override
  String get familySyncMemberConfirmedNotificationBody =>
      'ファミリー同期グループの準備ができました。最新の状態を確認するにはグループ管理を開いてください。';

  @override
  String get familySyncJustNow => 'たった今リクエスト';

  @override
  String get familySyncSecurityVerified => 'デバイスの公開鍵が検証済みです';

  @override
  String get familySyncReject => '拒否';

  @override
  String get familySyncApprove => '承認する';

  @override
  String get familySyncCurrentMembers => '現在のメンバー';

  @override
  String get familySyncApprovalTip => '承認すると、このデバイスとデータが暗号化して同期されます。';

  @override
  String get familySyncGroupManagement => 'グループ管理';

  @override
  String get familySyncSynced => '同期済';

  @override
  String get familySyncSyncedEntries => '同期済帳票';

  @override
  String get familySyncLastSync => '最終同期';

  @override
  String get familySyncYouSuffix => ' (あなた)';

  @override
  String get familySyncDissolveGroup => 'グループを解散';

  @override
  String familySyncMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String groupDefaultName(String name) {
    return '$nameの家庭';
  }

  @override
  String get groupCreate => 'グループを作成';

  @override
  String get groupName => 'グループ名';

  @override
  String get groupOwner => 'オーナー';

  @override
  String get groupMember => 'メンバー';

  @override
  String get groupInviteCode => '招待コード';

  @override
  String groupInviteExpiry(int minutes) {
    return '$minutes分以内に有効';
  }

  @override
  String get groupShareCode => '招待コードを共有';

  @override
  String get groupEnterCode => '招待コードを入力';

  @override
  String get groupVerify => '検証';

  @override
  String get groupConfirmJoin => '参加を確認';

  @override
  String get groupJoinTarget => '参加するグループ';

  @override
  String get groupWaitingApproval => 'オーナーの承認を待っています...';

  @override
  String groupWaitingDesc(String name) {
    return '$name があなたのリクエストを確認中';
  }

  @override
  String get groupJoinRequest => '参加リクエストを受信';

  @override
  String groupJoinRequestDesc(String name) {
    return '$name が参加を申請しています';
  }

  @override
  String get groupApprove => '承認';

  @override
  String get groupReject => '拒否';

  @override
  String get groupJoinSuccess => 'ようこそ！';

  @override
  String get groupRename => 'グループ名を変更';

  @override
  String get groupRenameFailed => '名前の変更に失敗しました';

  @override
  String get groupSyncing => '同期中';

  @override
  String get groupInvalidCode => '無効な招待コードです';

  @override
  String get groupCodeExpired => '招待コードの有効期限が切れました';

  @override
  String get groupMyName => '自分の名前';

  @override
  String get groupEnterGroup => 'グループへ';

  @override
  String get groupChoiceTitle => '家族とつながろう';

  @override
  String get groupChoiceSubtitle => '家計簿を一緒に管理しましょう';

  @override
  String get groupCreateDesc => '新しい家族グループを作って、メンバーを招待しましょう';

  @override
  String get groupJoinDesc => '招待コードを入力して、既存のグループに参加しましょう';

  @override
  String get groupE2eeHint => 'E2E暗号化でプライバシーを保護';

  @override
  String get groupInviteMembers => '新しいメンバーを招待';

  @override
  String get groupDisband => 'グループを解散';

  @override
  String get groupCancel => 'キャンセル';

  @override
  String get groupWaitingHint1 => '通知が届くまでお待ちください';

  @override
  String get groupWaitingHint2 => 'アプリを閉じても大丈夫です';

  @override
  String get groupCodeHint => '招待コードはグループのオーナーに聞いてください';

  @override
  String get groupBack => '戻る';

  @override
  String get syncInProgress => '同期中...';

  @override
  String get syncCompleted => '同期完了';

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String get syncRetry => '再試行';

  @override
  String get syncManual => '手動で同期';

  @override
  String syncLastTime(String time) {
    return '最終同期: $time';
  }

  @override
  String syncOfflineQueued(int count) {
    return '$count件の変更が��信待ち';
  }

  @override
  String get syncInitialProgress => '初回同期中...';

  @override
  String syncProfileUpdated(String name) {
    return '$nameがプロフィール���更新しました';
  }

  @override
  String get familySyncManualSync => '帳簿を同期';

  @override
  String get familySyncManualSyncDesc => '手動でデータを同期';

  @override
  String get listTab => 'リスト';

  @override
  String get datePickerComingSoon => '日付選択は近日公開';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get languageSystem => 'システム設定に従う';

  @override
  String get initFailedTitle => '初期化に失敗しました';

  @override
  String get initFailedMessage => 'アプリの起動中に問題が発生しました。再試行ボタンをタップしてください。';

  @override
  String get initFailedRetry => '再試行';

  @override
  String get homeLedgersSection => '帳簿';

  @override
  String get homeRecentTransactions => '最近の取引';

  @override
  String get homeViewAllTransactions => 'すべて見る';

  @override
  String get homeRecentJoyExpense => '最近のときめき支出';

  @override
  String get voiceMicrophonePermissionRequired => 'マイクへのアクセスを許可してください';

  @override
  String get voiceRecognitionErrorNetwork => 'ネットワークに接続できません。通信状況を確認してください';

  @override
  String get voiceRecognitionErrorNoMatch => '音声を認識できませんでした。もう一度お試しください';

  @override
  String get voiceRecognitionErrorAudio => 'マイクの音声を取得できませんでした';

  @override
  String get voiceRecognitionErrorUnknown => '音声認識でエラーが発生しました';

  @override
  String get analyticsBudgetProgress => '予算の進捗';

  @override
  String get analyticsNoBudgetsSet => '予算が設定されていません';

  @override
  String get analyticsIncome => '収入';

  @override
  String get analyticsExpenses => '支出';

  @override
  String get analyticsSavings => '貯蓄';

  @override
  String get analyticsSavingsRate => '貯蓄率';

  @override
  String get analyticsCategoryDetails => 'カテゴリ詳細';

  @override
  String analyticsTransactionCount(int count) {
    return '$count件の取引';
  }

  @override
  String get analyticsDailyExpenses => '日別支出';

  @override
  String get analyticsNoLedgerData => '帳簿データがありません';

  @override
  String get analyticsDailyVsJoy => '日常 vs ときめき';

  @override
  String get analyticsSixMonthTrend => '6か月推移';

  @override
  String analyticsDayNumberLabel(int day) {
    return '$day日';
  }

  @override
  String analyticsMonthNumberLabel(int month) {
    return '$month月';
  }

  @override
  String get analyticsTitle => '統計';

  @override
  String get analyticsTimeWindowChipTooltip => '期間を選ぶ';

  @override
  String get analyticsJoyMetricVariantChipLabel => 'エントリ';

  @override
  String get analyticsJoyMetricVariantSheetTitle => 'Joy 指標バリアント';

  @override
  String get analyticsJoyMetricVariantOptionAll => 'すべてのエントリ';

  @override
  String get analyticsJoyMetricVariantOptionManualOnly => '手動入力のみ';

  @override
  String get analyticsJoyMetricVariantManualOnlyExplain => '手動入力のみ · 音声推定を除外';

  @override
  String analyticsTimeWindowChipLabelWeek(String monday) {
    return '$mondayの週';
  }

  @override
  String analyticsTimeWindowChipLabelQuarter(String q, String year) {
    return '$year年 第$q四半期';
  }

  @override
  String analyticsTimeWindowChipLabelYear(String year) {
    return '$year年';
  }

  @override
  String analyticsTimeWindowChipLabelCustom(String start, String end) {
    return '$start 〜 $end';
  }

  @override
  String get analyticsTimeWindowSheetTitle => '期間';

  @override
  String get analyticsTimeWindowTypeWeek => '週';

  @override
  String get analyticsTimeWindowTypeMonth => '月';

  @override
  String get analyticsTimeWindowTypeQuarter => '四半期';

  @override
  String get analyticsTimeWindowTypeYear => '年';

  @override
  String get analyticsTimeWindowTypeCustom => 'カスタム';

  @override
  String get analyticsTimeWindowCustomCta => '日付範囲を選ぶ';

  @override
  String get analyticsTimeWindowErrorTooLong => '期間は12ヶ月を超えられません。短い期間を選んでください。';

  @override
  String get analyticsTimeWindowErrorInverted => '開始日は終了日より前にしてください。';

  @override
  String get analyticsTimeWindowErrorFutureEnd => '終了日に未来の日付は選べません。';

  @override
  String get analyticsTimeWindowEmptyPreset => 'このビュー用のデータがありません。取引を追加してください。';

  @override
  String get analyticsKpiTotalLabel => '支出合計';

  @override
  String get analyticsKpiJoyLabel => '平均満足度';

  @override
  String analyticsKpiJoySubMedianCoverage(String median, int k, int N) {
    return '中央値 $median · n=$k/$N';
  }

  @override
  String analyticsKpiJoySemantics(
    String label,
    String value,
    int rated,
    int total,
  ) {
    return '悦己 $label $value n=$rated/$total';
  }

  @override
  String get analyticsKpiJoyEmptyCaption => 'データを集計中...';

  @override
  String get analyticsKpiJoyIndexLabel => 'ときめき指数';

  @override
  String get analyticsKpiJoyIndexEmptyCaption =>
      'ときめきの記録に満足度をつけると、ときめき指数が表示されます。';

  @override
  String analyticsKpiJoyIndexSemantics(
    String label,
    String value,
    int ratedCount,
    int totalCount,
  ) {
    return '$label $value、評価済み $ratedCount/$totalCount';
  }

  @override
  String analyticsKpiJoyIndexSubMedianCoverage(
    String median,
    int ratedCount,
    int totalCount,
  ) {
    return '中央値 $median · 評価 $ratedCount/$totalCount';
  }

  @override
  String get analyticsCardTitleTotalSixMonth => '総 · 6 か月支出推移';

  @override
  String get analyticsCardCaptionTotalSixMonth => 'BarChart · 当月 highlighted';

  @override
  String get analyticsCardTitleCategoryDonut => '総 · 類別支出分布';

  @override
  String get analyticsCardCaptionCategoryDonut =>
      'Donut/PieChart · top-N + その他';

  @override
  String get analyticsCardTitleWithinMonthTrend => '支出の推移';

  @override
  String get analyticsCardCaptionWithinMonthTrend => '今月の日ごとの累計支出';

  @override
  String get analyticsTrendSeriesThisMonth => '今月';

  @override
  String get analyticsTrendSeriesLastMonth => '先月';

  @override
  String get analyticsCardTitleJoySpend => '悦己 · どこへ使った';

  @override
  String get analyticsCardCaptionJoySpend => 'あなたの悦己支出の内訳';

  @override
  String get analyticsJoySpendHeaderLabel => '悦己支出';

  @override
  String get analyticsJoySpendEmpty => 'この期間の悦己支出はまだありません';

  @override
  String get analyticsCardTitleJoyCalendar => '小确幸 · カレンダー';

  @override
  String get analyticsCardCaptionJoyCalendar => '悦己の日々の手ざわり';

  @override
  String get analyticsJoyCalendarDayEmpty => 'この日の小确幸の記録はありません';

  @override
  String get analyticsSectionTrend => '支出の推移';

  @override
  String get analyticsSectionCategory => 'カテゴリ支出';

  @override
  String get analyticsSectionJoyCalendar => '小さな幸せカレンダー';

  @override
  String get analyticsSectionSatisfaction => '悦びの満足度';

  @override
  String get analyticsSectionTagPractical => '実用';

  @override
  String get analyticsSectionTagJoy => '悦び';

  @override
  String get analyticsJoyDrawerConnector => '悦びの内訳を見る';

  @override
  String analyticsJoyDrawerTitle(String amount) {
    return '悦び $amount は、どんな嬉しいことに';
  }

  @override
  String analyticsJoyDrawerCount(int count) {
    return '$count カテゴリ';
  }

  @override
  String get analyticsJoyDrawerSubtitle => '使い道だけ、優劣なし';

  @override
  String get analyticsJoyDrawerCaption =>
      '割合は悦び自身の中での比率です · 目標もなく、過去と引き比べることもありません';

  @override
  String get analyticsCalLegendLow => '淡';

  @override
  String get analyticsCalLegendHigh => '濃';

  @override
  String get analyticsCalLegendNote => '色が濃いほど、その日の悦びの記録が多いという意味です';

  @override
  String analyticsHistogramMedianPill(int value) {
    return '中央の満足度 $value';
  }

  @override
  String analyticsHistogramCountFooter(int count) {
    return '悦び支出 $count 件の満足度';
  }

  @override
  String get analyticsCategoryDonutOther => 'その他';

  @override
  String get analyticsDonutCenterLabel => '今月の支出';

  @override
  String get analyticsDrillSubtotalLabel => '小計';

  @override
  String get analyticsDrillCountLabel => '件数';

  @override
  String get analyticsDrillAvgPerDayLabel => '日均';

  @override
  String get analyticsDrillEmpty => 'この期間の記録はありません';

  @override
  String get analyticsDrillLoadError => '読み込みに失敗しました';

  @override
  String get analyticsCardTitleSatisfactionHistogram => '悦己 · 満足度の分布 1–10';

  @override
  String get analyticsCardCaptionHistogram =>
      'Histogram · cool→warm · bar 5 三語注記';

  @override
  String get analyticsHistogramBarFiveAnnotation => '中央値・含未評価';

  @override
  String get analyticsHistogramColorCaption => '色は ordinal 表現です';

  @override
  String get analyticsCardTitleLargestExpense => '総 · 最大支出';

  @override
  String analyticsCardLargestExpenseBody(
    String categoryName,
    String amount,
    String date,
  ) {
    return '$categoryName · $amount · $date';
  }

  @override
  String get analyticsCardEmptyLargestExpense => 'データなし — まだ記録がありません';

  @override
  String get analyticsCardTitleBestJoy => '悦己 · ベスト ジョイ';

  @override
  String analyticsCardBestJoyBig(String categoryName, String date) {
    return '$categoryName · $date';
  }

  @override
  String analyticsCardSmallBestJoy(String amount, int sat) {
    return '$amount · 満足 $sat/10 ✨';
  }

  @override
  String get analyticsCardEmptyBestJoy => '最大ハイライトはまだ見つからない';

  @override
  String get analyticsCardTitleFamilyInsight => '家族 · ハイライトサマリー';

  @override
  String analyticsFamilyHighlightsSentence(int N) {
    return '家族の小確幸 $N回';
  }

  @override
  String analyticsFamilySharedJoySentence(
    String categoryName,
    int count,
    String avg,
  ) {
    return 'みんなで [$categoryName] が好きみたい (n=$count, 平均$avg/10)';
  }

  @override
  String get analyticsFamilyEmpty => '共通のお気に入り品目はまだ集計できません — もう少し記録してみよう';

  @override
  String get analyticsThinSampleFallbackHeading => 'ときめき帳の記録がまだ少ないよ';

  @override
  String get analyticsThinSampleFallbackBody => 'あと数日記録を続けたら、Joy の流れが見えてくる';

  @override
  String get analyticsThinSampleFallbackCta => '記録する »';

  @override
  String get analyticsCardErrorHeading => 'データが読み込めなかった';

  @override
  String get analyticsCardErrorBody => 'しばらくしてから、もう一度試してください';

  @override
  String get analyticsCardErrorRetry => '再試行';

  @override
  String get analyticsCardTitlePerCategoryJoy => 'ときめき · カテゴリ';

  @override
  String get analyticsCardTitlePerCategoryJoyYou => 'ときめき · あなたのカテゴリ';

  @override
  String get analyticsCardTitlePerCategoryJoyFamily => 'ときめき · 家族のカテゴリ';

  @override
  String analyticsPerCategoryRow(
    String categoryName,
    String avgSat,
    int count,
  ) {
    return '$categoryName · 平均 $avgSat / $count 件';
  }

  @override
  String analyticsPerCategoryOtherFold(int totalCount, int categoryCount) {
    return 'その他：$totalCount 件、$categoryCount カテゴリ';
  }

  @override
  String get analyticsPerCategoryShowAll => 'すべて表示';

  @override
  String get analyticsPerCategoryShowLess => '折りたたむ';

  @override
  String get analyticsCardTitleLedgerThisWindow => '今期の家計簿';

  @override
  String get analyticsLedgerColumnJoy => 'ときめき';

  @override
  String get analyticsLedgerColumnDaily => '日常';

  @override
  String get analyticsLedgerRowYou => 'あなた';

  @override
  String get analyticsLedgerRowFamily => '家族';

  @override
  String analyticsLedgerCellEntries(int count) {
    return '$count 件';
  }

  @override
  String analyticsLedgerCellAvgSat(String avgSat) {
    return '平均満足 $avgSat';
  }

  @override
  String get analyticsPerCategoryEmpty => '今期はカテゴリデータがありません';

  @override
  String get analyticsLedgerEmpty => '今期はデータがありません';

  @override
  String get analyticsLedgerFamilyEmpty => '今期は家族データがありません';

  @override
  String get analyticsLedgerFamilyError => '家族データを取得できません';

  @override
  String budgetRemainingAmount(String amount) {
    return '残り: $amount';
  }

  @override
  String budgetExceededAmount(String amount) {
    return '超過: $amount';
  }

  @override
  String get calMonthTotal => '今月の支出';

  @override
  String calDayTotal(String date) {
    return '$dateの支出';
  }

  @override
  String get calLoadError => 'データを読み込めません';

  @override
  String get listSortDate => '日付';

  @override
  String get listSortEditTime => '更新日時';

  @override
  String get listSortAmount => '金額';

  @override
  String get listLedgerAll => 'すべて';

  @override
  String get listLedgerDaily => '日常';

  @override
  String get listLedgerJoy => 'ときめき';

  @override
  String get listCategoryChip => 'カテゴリ';

  @override
  String listCategoryChipN(int n) {
    return 'カテゴリ ($n)';
  }

  @override
  String get listSearchHint => '検索...';

  @override
  String get listClearAll => 'クリア';

  @override
  String get listMineOnly => '自分のみ';

  @override
  String get listDeleteConfirmTitle => '削除しますか？';

  @override
  String get listDeleteConfirmBody => 'この記録を削除します。元に戻せません。';

  @override
  String get listDeleteCancelButton => 'キャンセル';

  @override
  String get listDeleteConfirmButton => '削除';

  @override
  String get listDeletedSnackBar => '削除しました';

  @override
  String get listCategorySheetTitle => 'カテゴリで絞り込む';

  @override
  String get listCategorySheetClear => 'クリア';

  @override
  String get listCategorySheetApply => '適用';

  @override
  String listCategorySheetApplyN(int n) {
    return '適用 ($n)';
  }

  @override
  String get listEmptyMonth => 'この月にはまだ記録がありません';

  @override
  String get listEmptyFiltered => '条件に合う記録が見つかりません';

  @override
  String get listEmptyFilteredClear => 'フィルターをクリア';

  @override
  String get listEmptyDay => 'この日の記録はありません';

  @override
  String get listEmptyDayClear => '月全体を表示';

  @override
  String get listLoadError => 'データを読み込めません';

  @override
  String get listCalNavPrev => '前の月';

  @override
  String get listCalNavNext => '次の月';

  @override
  String get listCalNavCurrentMonth => '今月に戻る';

  @override
  String get shoppingDeleteConfirmTitle => 'アイテムを削除しますか？';

  @override
  String get shoppingDeleteConfirmBody => 'このアイテムを買い物リストから削除します。';

  @override
  String get shoppingDeleteConfirmButton => '削除';

  @override
  String get shoppingDeleteCancelButton => 'キャンセル';

  @override
  String get shoppingDeletedSnackBar => 'アイテムを削除しました';

  @override
  String get shoppingEditItem => 'アイテムを編集';

  @override
  String get shoppingReorderItem => 'アイテムを並べ替え';

  @override
  String get shoppingToggleComplete => '完了を切り替え';

  @override
  String get shoppingEnterReorderMode => '並べ替え';

  @override
  String get shoppingExitReorderMode => '完了';

  @override
  String get shoppingMoveToTop => '一番上に移動';

  @override
  String get shoppingMoveToBottom => '一番下に移動';

  @override
  String get shoppingEmptyPrivateHeading => '買うものリストは空です';

  @override
  String get shoppingEmptyPrivateBody => '「+」で最初のアイテムを追加';

  @override
  String get shoppingEmptyPublicSoloHeading => '公開リストは空です';

  @override
  String get shoppingEmptyPublicSoloBody => '家族と共有する買い物を追加';

  @override
  String get shoppingEmptyPublicFamilyHeading => 'まだアイテムがありません';

  @override
  String get shoppingEmptyPublicFamilyBody => '誰でも追加できます。最初の1つをどうぞ';

  @override
  String get shoppingEmptyCta => 'アイテムを追加';

  @override
  String get shoppingFilterLedgerAll => 'すべて';

  @override
  String get shoppingFilterStatusActive => 'アクティブのみ';

  @override
  String get shoppingFilterStatusAll => 'すべてのアイテム';

  @override
  String get shoppingFilterCategory => 'カテゴリ';

  @override
  String get shoppingSegmentPublic => '公開';

  @override
  String get shoppingListScreenTitle => '買い物リスト';

  @override
  String get shoppingSegmentAll => 'すべて';

  @override
  String get shoppingSegmentPrivate => '私有';

  @override
  String get shoppingFilterPrivate => '私有';

  @override
  String get shoppingFormListTypeLabel => 'タイプ';

  @override
  String get shoppingListTypeLockedHint => '作成後は変更できません';

  @override
  String get shoppingCompletedDivider => '完了済み';

  @override
  String get shoppingClearCompletedTitle => '完了済みをすべて削除しますか？';

  @override
  String get shoppingClearCompletedBody => '完了済みのすべてのアイテムを削除します。';

  @override
  String get shoppingClearCompletedConfirm => '削除';

  @override
  String get shoppingClearCompletedSnackBar => '完了済みアイテムを削除しました';

  @override
  String get shoppingListLoadError => 'リストを読み込めませんでした';

  @override
  String get shoppingRetry => '再試行';

  @override
  String get shoppingBatchDeleteTitle => 'アイテムを削除しますか？';

  @override
  String shoppingBatchDeleteBody(int count) {
    return '$count 件のアイテムを削除します。';
  }

  @override
  String get shoppingBatchDeleteConfirm => '削除';

  @override
  String get shoppingBatchDeletedSnackBar => 'アイテムを削除しました';

  @override
  String get shoppingBatchDeleteAction => '削除';

  @override
  String get shoppingBatchCancel => 'キャンセル';

  @override
  String get shoppingBatchSelectAll => 'すべて選択';

  @override
  String shoppingSelectionCount(int count) {
    return '$count件';
  }

  @override
  String shoppingBatchSelectingCount(int count) {
    return '$count件選択中';
  }

  @override
  String get shoppingFormAddTitle => 'アイテムを追加';

  @override
  String get shoppingFormEditTitle => 'アイテムを編集';

  @override
  String get shoppingFormSave => '保存';

  @override
  String get shoppingFormNameLabel => 'アイテム名';

  @override
  String get shoppingFormNameRequired => '名前を入力してください';

  @override
  String get shoppingFormLedgerLabel => '帳簿';

  @override
  String get shoppingFormCategoryLabel => 'カテゴリ';

  @override
  String get shoppingFormNoCategorySelected => 'カテゴリなし';

  @override
  String get shoppingFormChangeCategory => '変更';

  @override
  String get shoppingFormTagsLabel => 'タグ（カンマ区切り）';

  @override
  String get shoppingFormNoteLabel => 'メモ';

  @override
  String get shoppingFormQuantityLabel => '数量';

  @override
  String get shoppingFormPrice => '参考価格';

  @override
  String get shoppingFormSaveError => '保存に失敗しました。もう一度お試しください。';

  @override
  String get currencySelectorTitle => '通貨を選択';

  @override
  String get currencySelectorMore => 'もっと見る';

  @override
  String get currencySelectorSearchHint => 'コードまたは名称で検索';

  @override
  String get currencySelectorNoResults => '該当する通貨がありません';

  @override
  String get currencyNameJpy => '日本円';

  @override
  String get currencyNameUsd => '米ドル';

  @override
  String get currencyNameEur => 'ユーロ';

  @override
  String get currencyNameCny => '人民元';

  @override
  String get currencyNameHkd => '香港ドル';

  @override
  String get currencyNameGbp => '英ポンド';

  @override
  String get currencyNameKrw => '韓国ウォン';

  @override
  String get currencyNameTwd => '台湾ドル';

  @override
  String get currencyNameSgd => 'シンガポールドル';

  @override
  String get currencyNameAud => '豪ドル';

  @override
  String get currencyNameCad => 'カナダドル';

  @override
  String get currencyNameChf => 'スイス・フラン';

  @override
  String get currencyNameThb => 'タイ・バーツ';

  @override
  String get currencyNameInr => 'インド・ルピー';

  @override
  String get currencyNameIdr => 'インドネシア・ルピア';

  @override
  String get currencyNameMyr => 'マレーシア・リンギット';

  @override
  String get currencyNamePhp => 'フィリピン・ペソ';

  @override
  String get currencyNameVnd => 'ベトナム・ドン';

  @override
  String get currencyNameNzd => 'ニュージーランド・ドル';

  @override
  String get currencyNameBrl => 'ブラジル・レアル';

  @override
  String get currencyNameRub => 'ロシア・ルーブル';

  @override
  String get currencyNameZar => '南アフリカ・ランド';

  @override
  String get currencyNameSek => 'スウェーデン・クローナ';

  @override
  String get currencyNameNok => 'ノルウェー・クローネ';

  @override
  String get currencyNameDkk => 'デンマーク・クローネ';

  @override
  String get currencyNameMxn => 'メキシコ・ペソ';

  @override
  String get currencyNameTry => 'トルコ・リラ';

  @override
  String get currencyNameAed => 'UAE ディルハム';

  @override
  String get currencyNameSar => 'サウジ・リヤル';

  @override
  String get currencyNamePln => 'ポーランド・ズウォティ';

  @override
  String conversionPreviewRateRow(String code, String rate, String date) {
    return '$code 1 = ¥$rate · $date';
  }

  @override
  String conversionStalenessCached(String date) {
    return '$date のレート（キャッシュ）を使用';
  }

  @override
  String conversionStalenessWeekend(String date) {
    return '$date（直近の営業日）のレート';
  }

  @override
  String get conversionRateRequired => 'レートが取得できません。手動でレートを入力してください';

  @override
  String get editOriginalAmountLabel => '原通貨の金額';

  @override
  String get editRateLabel => 'レート';

  @override
  String get editJpyDerivedLabel => '円（換算後）';

  @override
  String get currencyRateDateLabel => 'レート日付';

  @override
  String get editRateRequired => 'レートを入力してください';

  @override
  String get editRateInvalid => '正の数を入力してください';

  @override
  String get editAmountRequired => '金額を入力してください';

  @override
  String get editAmountInvalid => '正の数を入力してください';

  @override
  String get changeRateDialogTitle => 'レート確認';

  @override
  String get changeRateDialogBody => 'レートを手動で設定しました。新しい日付でレートを再取得しますか？';

  @override
  String get changeRateKeepManual => '手動レートを保持';

  @override
  String get changeRateRefetch => '新しい日付で再取得';

  @override
  String rateChangedToast(String oldJpy, String newJpy) {
    return '円を調整しました：$oldJpy → $newJpy（レート更新）';
  }

  @override
  String get rateChangedUndo => '元に戻す';

  @override
  String get analyticsDonutHeroCap => '今月、お金はどこへ';

  @override
  String analyticsDonutHeroTag(int count, int month) {
    return '$count件 · $month月';
  }

  @override
  String analyticsDonutCenterCount(int count) {
    return '$count件';
  }

  @override
  String analyticsCalCap(int days) {
    return '今月は $days 日、自分のための小さな幸せ · 「あった日」を見るだけ';
  }

  @override
  String get analyticsCalWeekdayMon => '月';

  @override
  String get analyticsCalWeekdayTue => '火';

  @override
  String get analyticsCalWeekdayWed => '水';

  @override
  String get analyticsCalWeekdayThu => '木';

  @override
  String get analyticsCalWeekdayFri => '金';

  @override
  String get analyticsCalWeekdaySat => '土';

  @override
  String get analyticsCalWeekdaySun => '日';
}
