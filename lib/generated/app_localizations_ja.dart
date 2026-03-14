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
  String get survivalLedger => '生存帳簿';

  @override
  String get soulLedger => '魂帳簿';

  @override
  String get survival => '生存';

  @override
  String get soul => '魂';

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
  String get noTransactionsYet => '取引がまだありません';

  @override
  String get tapToAddFirstTransaction => '＋をタップして最初の取引を追加';

  @override
  String get transactionSaved => '取引を保存しました';

  @override
  String get failedToSave => '保存に失敗しました';

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
  String get initializationError => 'アプリの初期化に失敗しました';

  @override
  String get homeMonthlyExpense => '今月の出費';

  @override
  String get homeSurvivalExpense => '暮らしの支出';

  @override
  String get homeSoulExpense => 'ときめき支出';

  @override
  String get homeMonthComparison => '先月比';

  @override
  String get homeSoulFullness => '魂の充実度';

  @override
  String get homeSoulPercentLabel => '今月の魂支出の割合';

  @override
  String get homeHappinessROI => '幸せROI';

  @override
  String get homeFamilyInviteTitle => '家族を招待する';

  @override
  String get homeFamilyInviteDesc => 'パートナーと家計簿を共有しよう';

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
  String get homeTabTodo => 'やること';

  @override
  String homeMonthFormat(int year, int month) {
    return '$year年$month月';
  }

  @override
  String homeMonthLabel(int month) {
    return '$month月';
  }

  @override
  String homeRecentSoulTransaction(String merchant, int amount) {
    return '直近: $merchant ¥$amount';
  }

  @override
  String homeSoulChargeStatus(int fullness, double roi) {
    return '魂の充実度 $fullness% · 幸せROI ${roi}x';
  }

  @override
  String homeMonthBadge(int percent) {
    return '今月 $percent%';
  }

  @override
  String get addTransaction => '添加账目';

  @override
  String get manualInput => '手動入力';

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
  String get enterStore => 'お店を入力';

  @override
  String get enterMemo => 'メモを入力...';

  @override
  String get expenseClassification => '支出分類';

  @override
  String get survivalExpense => '生存支出';

  @override
  String get soulExpense => '魂支出';

  @override
  String get soulSatisfaction => '魂の充盈度';

  @override
  String get addPhoto => '写真を追加';

  @override
  String get ocrScanTitle => 'OCRスキャン入力';

  @override
  String get ocrHint => 'レシートを枠内に収めてください';

  @override
  String get voiceRecognitionResult => '認識結果';

  @override
  String get tapToRecord => 'タップして録音開始';

  @override
  String get todayDate => '今日';

  @override
  String get next => 'Next';

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
}
