// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '守护家计簿';

  @override
  String get home => '首页';

  @override
  String get transactions => '交易';

  @override
  String get analytics => '分析';

  @override
  String get settings => '设置';

  @override
  String get settingsJoyTargetTitle => '悦己目标';

  @override
  String settingsJoyTargetCurrentConfigured(int target) {
    return '当前目标：$target';
  }

  @override
  String settingsJoyTargetCurrentRecommended(int target) {
    return '参考值：$target';
  }

  @override
  String settingsJoyTargetRecommendation(int target) {
    return '来自近期悦己记录的参考值：$target';
  }

  @override
  String get settingsJoyTargetFallback => '记录更多悦己条目后会显示参考值。现在使用初始参考值。';

  @override
  String get settingsJoyTargetInputLabel => '月度悦己目标';

  @override
  String get settingsJoyTargetInputHint => '输入正整数';

  @override
  String get settingsJoyTargetInvalid => '请输入大于零的整数。';

  @override
  String get settingsJoyTargetUseRecommendation => '使用参考值';

  @override
  String get settingsJoyTargetSave => '保存';

  @override
  String get settingsJoyTargetCancel => '取消';

  @override
  String get ledger => '账本';

  @override
  String get newTransaction => '新交易';

  @override
  String get amount => '金额';

  @override
  String get category => '分类';

  @override
  String get note => '备注';

  @override
  String get merchant => '商家';

  @override
  String get date => '日期';

  @override
  String get transactionTypeExpense => '支出';

  @override
  String get transactionTypeIncome => '收入';

  @override
  String get categoryFood => '餐饮';

  @override
  String get categoryHousing => '住房';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryUtilities => '水电费';

  @override
  String get categoryEntertainment => '娱乐';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryHealth => '医疗';

  @override
  String get categoryShopping => '购物';

  @override
  String get categoryOther => '其他';

  @override
  String get dailyLedger => '日常';

  @override
  String get joyLedger => '悦己';

  @override
  String get daily => '日常';

  @override
  String get joy => '悦己';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get confirm => '确认';

  @override
  String get ok => '确定';

  @override
  String get retry => '重试';

  @override
  String get search => '搜索';

  @override
  String get filter => '筛选';

  @override
  String get sort => '排序';

  @override
  String get refresh => '刷新';

  @override
  String get loading => '加载中...';

  @override
  String get noData => '暂无数据';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorUnknown => '发生未知错误';

  @override
  String get errorInvalidAmount => '无效金额';

  @override
  String get errorRequired => '必填项';

  @override
  String get errorInvalidDate => '无效日期';

  @override
  String get errorDatabaseWrite => '数据库写入错误';

  @override
  String get errorDatabaseRead => '数据库读取错误';

  @override
  String get errorEncryption => '加密错误';

  @override
  String get errorSync => '同步错误';

  @override
  String get errorBiometric => '生物识别错误';

  @override
  String get errorPermission => '权限错误';

  @override
  String errorMinAmount(double min) {
    return '请输入至少$min的金额';
  }

  @override
  String errorMaxAmount(double max) {
    return '请输入不超过$max的金额';
  }

  @override
  String get successSaved => '保存成功';

  @override
  String get successDeleted => '删除成功';

  @override
  String get successSynced => '同步成功';

  @override
  String get merchantPlaceholder => '请输入商家名称';

  @override
  String get notePlaceholder => '请输入备注';

  @override
  String get noteOptional => '备注（可选）';

  @override
  String get pleaseEnterAmount => '请输入金额';

  @override
  String get amountMustBeGreaterThanZero => '金额必须大于零';

  @override
  String get pleaseSelectCategory => '请选择类别';

  @override
  String get successKeepGoing => '已记录，可以继续记账';

  @override
  String get recordingExitLink => '退出记账';

  @override
  String get noTransactionsYet => '暂无交易记录';

  @override
  String get tapToAddFirstTransaction => '点击 + 添加第一笔交易';

  @override
  String get transactionSaved => '交易已保存';

  @override
  String get failedToSave => '保存失败';

  @override
  String get transactionEditTitle => '明细编辑';

  @override
  String get ocrReviewTitle => '票据复核';

  @override
  String get ocrReviewEmptyDraftBanner => 'OCR 尚未实现，请手动填写各字段。';

  @override
  String get transactionUpdated => '明细已更新';

  @override
  String get failedToUpdate => '更新失败';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get selectTheme => '选择主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsWeekStart => '每周起始日';

  @override
  String get settingsWeekStartMonday => '周一';

  @override
  String get settingsWeekStartSunday => '周日';

  @override
  String get security => '安全';

  @override
  String get biometricLock => '生物识别锁';

  @override
  String get biometricLockDescription => '使用面容/指纹解锁';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDescription => '预算提醒和同步通知';

  @override
  String get dataManagement => '数据管理';

  @override
  String get exportBackup => '导出备份';

  @override
  String get exportBackupDescription => '创建加密备份文件';

  @override
  String get importBackup => '导入备份';

  @override
  String get importBackupDescription => '从备份文件恢复';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataDescription => '永久删除所有记录';

  @override
  String get deleteAllDataConfirmation => '此操作无法撤销。您确定要删除所有数据吗？';

  @override
  String get allDataDeleted => '所有数据已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get backupExportedSuccessfully => '备份导出成功';

  @override
  String get exportFailed => '导出失败';

  @override
  String get backupImportedSuccessfully => '备份导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get setBackupPassword => '设置备份密码';

  @override
  String get enterBackupPassword => '输入备份密码';

  @override
  String get enterPassword => '输入密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordMinLength => '密码至少需要8个字符';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get generateDemoData => '生成演示数据';

  @override
  String get generateDemoDataDescription => '将创建过去3个月的示例交易，以展示分析功能。';

  @override
  String get generate => '生成';

  @override
  String get demoDataGenerated => '演示数据已生成！下拉刷新查看。';

  @override
  String get language => '语言';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get deleteTransactionConfirmation => '删除此交易？';

  @override
  String get error => '错误';

  @override
  String initializationError(String error) {
    return '初始化失败: $error';
  }

  @override
  String get profileSetup => '初次见面！';

  @override
  String get profileSetupSubtitle => '欢迎使用守护家计簿';

  @override
  String get profileNickname => '你的昵称';

  @override
  String get profileNicknamePlaceholder => '请输入昵称';

  @override
  String get profileStart => '开始';

  @override
  String get profileSelectAvatar => '选择头像';

  @override
  String get profileEmojiTab => '表情';

  @override
  String get profilePhotoTab => '照片';

  @override
  String get profileEdit => '编辑个人资料';

  @override
  String get profileCancel => '取消';

  @override
  String get profileDone => '完成';

  @override
  String get profilePreview => '预览';

  @override
  String get welcomeTo => '欢迎使用守护家计簿';

  @override
  String get profileNameRequired => '请输入昵称';

  @override
  String get profileSave => '保存';

  @override
  String get profileChangeAvatar => '点击更换头像';

  @override
  String get profilePhotoPermissionDenied => '照片访问被拒绝';

  @override
  String get profilePhotoFailed => '照片加载失败';

  @override
  String get profileSaveFailed => '保存失败';

  @override
  String get profileNameTooLong => '昵称不能超过50个字符';

  @override
  String get profileUploadPhoto => '上传照片';

  @override
  String get homeMonthlyExpense => '本月支出';

  @override
  String get homeDailyExpense => '日常支出';

  @override
  String get homeJoyExpense => '悦己支出';

  @override
  String get homeMonthComparison => '较上月';

  @override
  String homePreviousMonthAmount(String amount) {
    return '上月 $amount';
  }

  @override
  String get homeDailyLedgerTag => '日';

  @override
  String get homeJoyLedgerTag => '悦';

  @override
  String get homeSharedLedgerTag => '共';

  @override
  String homeShadowBookTitle(String memberName) {
    return '$memberName的账本';
  }

  @override
  String get homeJoyFullness => '悦己充盈';

  @override
  String get homeJoyPercentLabel => '本月悦己支出占比';

  @override
  String get homeFamilyInviteTitle => '邀请家人';

  @override
  String get homeFamilyInviteDesc => '与伴侣共享家计簿';

  @override
  String get homeFamilyBannerTitle => '一起管理家庭账本';

  @override
  String get homeFamilyBannerSubtitle => '邀请伴侣，实时共享家庭账本';

  @override
  String get homeTodayTitle => '今日记录';

  @override
  String homeTodayCount(int count) {
    return '$count条';
  }

  @override
  String get homePersonalMode => '个人模式';

  @override
  String get homeFamilyMode => '家庭模式';

  @override
  String get homeTabHome => '主页';

  @override
  String get homeTabList => '列表';

  @override
  String get homeTabChart => '图表';

  @override
  String get homeTabTodo => '购物清单';

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
    return '最近一笔: $merchant ¥$amount';
  }

  @override
  String homeJoyChargeStatus(int fullness, double roi) {
    return '悦己充盈度 $fullness% · 悦己指数 $roi';
  }

  @override
  String homeMonthBadge(int percent) {
    return '本月 $percent%';
  }

  @override
  String get homeJoyIndexTooltip => '外环是朝向当前目标的月度悦己指数，中环是满足度均值，内环是小确幸数（满足度≥6）。';

  @override
  String get homeJoyContributionTooltip => '外环是朝向当前目标的月度悦己指数，中环是满足度均值，内环是小确幸数。';

  @override
  String homeJoyTargetReference(int target) {
    return '目标 $target';
  }

  @override
  String homeJoyTargetSemantics(String value, int target) {
    return '悦己指数 $value，目标 $target';
  }

  @override
  String get homeHeroCardLabelSingle => '本月支出';

  @override
  String get homeHeroCardLabelGroup => '家庭支出';

  @override
  String homeHeroPreviousMonthSubline(String amount) {
    return '上月同期 $amount';
  }

  @override
  String get homeRingSectionTitleSingle => '悦己充盈';

  @override
  String get homeRingSectionTitleGroup => '家族的小确幸';

  @override
  String get homeBestJoyTagSingle => '本月最爱';

  @override
  String get homeBestJoyTagGroup => '本月最爱';

  @override
  String homeBestJoyAmountSat(String amount, int sat) {
    return '$amount · 满足 $sat/10 ✨';
  }

  @override
  String get homeMembersSectionTitle => '群组成员';

  @override
  String get homeNoJoyDataLegend => '尚未记录';

  @override
  String get homeBestJoyEmptyTagPrimary => '本月最爱';

  @override
  String get homeBestJoyEmptyBig => '记录第一笔悦己账';

  @override
  String get homeBestJoyEmptySmall => '你的本月最爱会出现在这里 →';

  @override
  String get homeBestJoyAllNeutralBig => '回去给最大那笔评个分';

  @override
  String get homeBestJoyAllNeutralSmall => '让它变成你的本月最爱';

  @override
  String get homeAvgSatisfactionLegend => '满足度均值';

  @override
  String get homeJoyContributionLegend => '悦己目标';

  @override
  String get homeHighlightsCountLegend => '小确幸';

  @override
  String get homeFamilyHighlightsLegend => '家族小确幸';

  @override
  String get homeSharedJoyLegend => '共爱品类';

  @override
  String get homeMedianSatisfactionLegend => '满足度中位数';

  @override
  String get addTransaction => '添加账目';

  @override
  String get manualInput => '手动';

  @override
  String get ocrScan => 'OCR';

  @override
  String get voiceInput => '语音';

  @override
  String get selectCategory => '选择分类';

  @override
  String get searchCategory => '搜索分类...';

  @override
  String get expenseDetail => '支出详情';

  @override
  String get back => '返回';

  @override
  String get record => '记录';

  @override
  String get keyboardToolbarDone => '完成';

  @override
  String get enterStore => '输入店铺';

  @override
  String get enterMemo => '输入备注...';

  @override
  String get expenseClassification => '用途';

  @override
  String get dailyExpense => '日常支出';

  @override
  String get joyExpense => '悦己支出';

  @override
  String get joyFullness => '悦己充盈度';

  @override
  String get addPhoto => '添加照片';

  @override
  String get ocrScanTitle => 'OCR扫描录入';

  @override
  String get ocrHint => '将票据完整放入框内';

  @override
  String get voiceRecognitionResult => '识别结果';

  @override
  String get recognitionResult => '识别结果';

  @override
  String get satisfactionLevel => '满足度';

  @override
  String get satisfactionBad => '平和';

  @override
  String get satisfactionSlightlyBad => 'OK';

  @override
  String get satisfactionNormal => '不错';

  @override
  String get satisfactionGood => '满足';

  @override
  String get satisfactionVeryGood => '最爱';

  @override
  String get satisfactionExcellent => '最爱！';

  @override
  String get satisfactionLabelNeutral => '中性';

  @override
  String get satisfactionLabelOK => 'OK';

  @override
  String get satisfactionLabelGood => '不错';

  @override
  String get satisfactionLabelGreat => '满足';

  @override
  String get satisfactionLabelAmazing => '最爱';

  @override
  String get addSubcategory => '添加';

  @override
  String get addCategory => '添加分类';

  @override
  String get editCategoryOrder => '编辑分类顺序';

  @override
  String get dragToReorder => '拖拽重排';

  @override
  String get orderUpdated => '顺序已更新';

  @override
  String get orderSaveFailed => '保存失败，请重试';

  @override
  String get discardUnsavedChanges => '放弃未保存的修改？';

  @override
  String get discardUnsavedChangesBody => '排序的修改将不会保存，并恢复原状。';

  @override
  String get keepEditing => '继续编辑';

  @override
  String get discard => '放弃';

  @override
  String get holdToRecord => '按住说话';

  @override
  String get recording => '录音中…';

  @override
  String get todayDate => '今天';

  @override
  String get next => '下一步';

  @override
  String get voiceInputSettings => '语音识别';

  @override
  String get voiceLanguage => '识别语言';

  @override
  String get voiceLanguageSubtitle => '语音转文字所使用的语言';

  @override
  String get familySync => '家庭同步';

  @override
  String get familySyncShowMyCode => '创建分组';

  @override
  String get familySyncEnterPartnerCode => '加入分组';

  @override
  String get familySyncPairCode => '邀请码';

  @override
  String get familySyncScanOrEnter => '将此邀请码或二维码分享给家人，让他们加入你的分组';

  @override
  String get familySyncCodeExpired => '配对码已过期';

  @override
  String get familySyncRegenerate => '重新生成';

  @override
  String get familySyncEnterDigitCode => '输入6位邀请码';

  @override
  String get familySyncSubmit => '提交';

  @override
  String get familySyncPairedDevice => '家庭分组';

  @override
  String get familySyncPairInfo => '分组信息';

  @override
  String get familySyncPairId => '分组ID';

  @override
  String get familySyncPairedSince => '配对时间';

  @override
  String get familySyncBookId => '账本ID';

  @override
  String get familySyncUnpair => '解除配对';

  @override
  String get familySyncUnpairDevice => '解除设备配对';

  @override
  String familySyncUnpairConfirm(String deviceName) {
    return '确定要与$deviceName解除配对吗？解除后将停止同步，直到重新配对。';
  }

  @override
  String familySyncUnpairFailed(String message) {
    return '解除配对失败: $message';
  }

  @override
  String get familySyncNoDevicePaired => '尚未加入任何家庭分组';

  @override
  String get familySyncPairPrompt => '创建或加入家庭分组以同步交易记录';

  @override
  String get familySyncStatusSynced => '已连接，数据已同步';

  @override
  String get familySyncStatusSyncing => '正在与分组同步...';

  @override
  String get familySyncStatusOffline => '离线中 - 连接后将自动同步';

  @override
  String get familySyncStatusError => '同步发生错误';

  @override
  String get familySyncStatusPairing => '分组设置中...';

  @override
  String get familySyncCheckingGroup => '正在检查群组状态...';

  @override
  String familySyncCheckFailed(String message) {
    return '无法检查群组状态: $message';
  }

  @override
  String get familySyncStatusUnpaired => '点击创建或加入家庭分组';

  @override
  String get familySyncBadgeSynced => '已同步';

  @override
  String get familySyncBadgeSyncing => '同步中';

  @override
  String get familySyncBadgeOffline => '离线';

  @override
  String get familySyncBadgeError => '错误';

  @override
  String get familySyncBadgePairing => '设置中';

  @override
  String get familySyncCreatingGroup => '正在创建分组...';

  @override
  String get familySyncJoinGroup => '加入分组';

  @override
  String get familySyncJoinSuccess => '已加入分组，正在等待所有者确认...';

  @override
  String get familySyncLeaveGroup => '退出分组';

  @override
  String get familySyncDeactivateGroup => '停用分组';

  @override
  String get familySyncLeaveGroupConfirm => '确定要退出这个家庭分组吗？此设备将停止同步，直到再次加入。';

  @override
  String get familySyncDeactivateGroupConfirm =>
      '确定要为所有成员停用这个家庭分组吗？在创建新分组前，同步将全部停止。';

  @override
  String familySyncLeaveGroupFailed(String message) {
    return '退出分组失败: $message';
  }

  @override
  String familySyncDeactivateGroupFailed(String message) {
    return '停用分组失败: $message';
  }

  @override
  String get familySyncRegenerateInvite => '重新生成邀请码';

  @override
  String familySyncRegenerateInviteFailed(String message) {
    return '重新生成邀请码失败: $message';
  }

  @override
  String get familySyncMembers => '成员';

  @override
  String familySyncMemberCount(int count) {
    return '$count 位成员';
  }

  @override
  String get familySyncRoleOwner => '所有者';

  @override
  String get familySyncRoleMember => '成员';

  @override
  String get familySyncMemberStatusActive => '已激活';

  @override
  String get familySyncMemberStatusPending => '待确认';

  @override
  String get familySyncRemoveMember => '移除成员';

  @override
  String familySyncRemoveMemberConfirm(String deviceName) {
    return '确定要将 $deviceName 移出这个家庭分组吗？';
  }

  @override
  String familySyncRemoveMemberFailed(String message) {
    return '移除成员失败: $message';
  }

  @override
  String get familySyncBadgeUnpaired => '未配对';

  @override
  String get familySyncShare => '分享';

  @override
  String familySyncExpiryLabel(String time) {
    return '有效期: $time';
  }

  @override
  String get familySyncJoinTitle => '加入家庭';

  @override
  String get familySyncJoinDescription => '请输入从家人那里收到的 6 位邀请码';

  @override
  String get familySyncOrDivider => '或';

  @override
  String get familySyncScanQr => '扫描二维码';

  @override
  String get familySyncWaitingTitle => '等待批准...';

  @override
  String get familySyncWaitingDescription => '分组所有者正在确认你的加入请求。请等待对方完成确认。';

  @override
  String get familySyncGroupLabel => '分组';

  @override
  String get familySyncStatusLabel => '状态';

  @override
  String get familySyncApprovalTitle => '成员审批';

  @override
  String get familySyncNewRequest => '新的加入请求';

  @override
  String get familySyncJoinRequestNotificationBody => '有家庭成员想加入你的分组。请查看请求后继续。';

  @override
  String familySyncJoinRequestWithName(String deviceName) {
    return '$deviceName 想要加入你的家庭账本';
  }

  @override
  String get familySyncMemberConfirmedNotificationTitle => '分组已就绪';

  @override
  String get familySyncMemberConfirmedNotificationBody =>
      '家庭同步分组已经准备好。打开分组管理查看最新状态。';

  @override
  String get familySyncJustNow => '刚刚发出请求';

  @override
  String get familySyncSecurityVerified => '该设备的公钥已完成校验';

  @override
  String get familySyncReject => '拒绝';

  @override
  String get familySyncApprove => '批准';

  @override
  String get familySyncCurrentMembers => '当前成员';

  @override
  String get familySyncApprovalTip => '批准后，这台设备与相关数据将以加密方式同步。';

  @override
  String get familySyncGroupManagement => '分组管理';

  @override
  String get familySyncSynced => '已同步';

  @override
  String get familySyncSyncedEntries => '已同步条目';

  @override
  String get familySyncLastSync => '上次同步';

  @override
  String get familySyncYouSuffix => '（你）';

  @override
  String get familySyncDissolveGroup => '解散分组';

  @override
  String familySyncMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String groupDefaultName(String name) {
    return '$name的家';
  }

  @override
  String get groupCreate => '创建群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupOwner => '群主';

  @override
  String get groupMember => '成员';

  @override
  String get groupInviteCode => '邀请码';

  @override
  String groupInviteExpiry(int minutes) {
    return '$minutes分钟内有效';
  }

  @override
  String get groupShareCode => '分享邀请码';

  @override
  String get groupEnterCode => '输入邀请码';

  @override
  String get groupVerify => '验证';

  @override
  String get groupConfirmJoin => '确认加入';

  @override
  String get groupJoinTarget => '你要加入的群组';

  @override
  String get groupWaitingApproval => '等待群主审批...';

  @override
  String groupWaitingDesc(String name) {
    return '$name 正在确认你的请求';
  }

  @override
  String get groupJoinRequest => '收到加入请求';

  @override
  String groupJoinRequestDesc(String name) {
    return '$name 申请加入';
  }

  @override
  String get groupApprove => '批准';

  @override
  String get groupReject => '拒绝';

  @override
  String get groupJoinSuccess => '欢迎加入！';

  @override
  String get groupRename => '修改群组名称';

  @override
  String get groupRenameFailed => '修改名称失败';

  @override
  String get groupSyncing => '同步中';

  @override
  String get groupInvalidCode => '邀请码无效';

  @override
  String get groupCodeExpired => '邀请码已过期';

  @override
  String get groupMyName => '我的名称';

  @override
  String get groupEnterGroup => '进入群组';

  @override
  String get groupChoiceTitle => '与家人连接';

  @override
  String get groupChoiceSubtitle => '一起管理家庭账本';

  @override
  String get groupCreateDesc => '创建新的家庭群组，邀请家庭成员加入';

  @override
  String get groupJoinDesc => '输入邀请码，加入已有的家庭群组';

  @override
  String get groupE2eeHint => '端到端加密保护隐私';

  @override
  String get groupInviteMembers => '邀请新成员';

  @override
  String get groupDisband => '解散群组';

  @override
  String get groupCancel => '取消';

  @override
  String get groupWaitingHint1 => '请等待通知';

  @override
  String get groupWaitingHint2 => '关闭应用也没有关系';

  @override
  String get groupCodeHint => '请向群组的群主索取邀请码';

  @override
  String get groupBack => '返回';

  @override
  String get syncInProgress => '同步中...';

  @override
  String get syncCompleted => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get syncRetry => '重试';

  @override
  String get syncManual => '手动同步';

  @override
  String syncLastTime(String time) {
    return '上次同步: $time';
  }

  @override
  String syncOfflineQueued(int count) {
    return '$count条变更待发送';
  }

  @override
  String get syncInitialProgress => '首次同步中...';

  @override
  String syncProfileUpdated(String name) {
    return '$name更新了个人资料';
  }

  @override
  String get familySyncManualSync => '同步账本';

  @override
  String get familySyncManualSyncDesc => '手动同步数据';

  @override
  String get listTab => '列表';

  @override
  String get todoTab => '待办';

  @override
  String get datePickerComingSoon => '日期选择即将推出';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get languageSystem => '跟随系统设置';

  @override
  String get initFailedTitle => '初始化失败';

  @override
  String get initFailedMessage => '应用启动时出现问题。请点击重试按钮。';

  @override
  String get initFailedRetry => '重试';

  @override
  String get homeLedgersSection => '账本';

  @override
  String get homeRecentTransactions => '最近交易';

  @override
  String get homeViewAllTransactions => '查看全部';

  @override
  String get homeRecentJoyExpense => '最近悦己支出';

  @override
  String get voiceMicrophonePermissionRequired => '请允许访问麦克风';

  @override
  String get voiceRecognitionErrorNetwork => '无法连接到网络，请检查网络状态后重试';

  @override
  String get voiceRecognitionErrorNoMatch => '未识别到语音内容，请再试一次';

  @override
  String get voiceRecognitionErrorAudio => '无法获取麦克风音频';

  @override
  String get voiceRecognitionErrorUnknown => '语音识别出现错误';

  @override
  String get analyticsBudgetProgress => '预算进度';

  @override
  String get analyticsNoBudgetsSet => '尚未设置预算';

  @override
  String get analyticsIncome => '收入';

  @override
  String get analyticsExpenses => '支出';

  @override
  String get analyticsSavings => '结余';

  @override
  String get analyticsSavingsRate => '结余率';

  @override
  String get analyticsCategoryDetails => '分类详情';

  @override
  String analyticsTransactionCount(int count) {
    return '$count笔交易';
  }

  @override
  String get analyticsDailyExpenses => '每日支出';

  @override
  String get analyticsNoLedgerData => '暂无账本数据';

  @override
  String get analyticsDailyVsJoy => '日常 vs 悦己';

  @override
  String get analyticsSixMonthTrend => '六个月趋势';

  @override
  String analyticsDayNumberLabel(int day) {
    return '$day日';
  }

  @override
  String analyticsMonthNumberLabel(int month) {
    return '$month月';
  }

  @override
  String get analyticsTitle => '统计';

  @override
  String get analyticsTimeWindowChipTooltip => '选择时间范围';

  @override
  String get analyticsJoyMetricVariantChipLabel => '条目';

  @override
  String get analyticsJoyMetricVariantSheetTitle => 'Joy 指标变体';

  @override
  String get analyticsJoyMetricVariantOptionAll => '全部条目';

  @override
  String get analyticsJoyMetricVariantOptionManualOnly => '仅手动输入';

  @override
  String get analyticsJoyMetricVariantManualOnlyExplain => '仅手动输入 · 不含语音估算条目';

  @override
  String analyticsTimeWindowChipLabelWeek(String monday) {
    return '$monday的一周';
  }

  @override
  String analyticsTimeWindowChipLabelQuarter(String q, String year) {
    return '$year年 第$q季度';
  }

  @override
  String analyticsTimeWindowChipLabelYear(String year) {
    return '$year年';
  }

  @override
  String analyticsTimeWindowChipLabelCustom(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String get analyticsTimeWindowSheetTitle => '时间范围';

  @override
  String get analyticsTimeWindowTypeWeek => '周';

  @override
  String get analyticsTimeWindowTypeMonth => '月';

  @override
  String get analyticsTimeWindowTypeQuarter => '季度';

  @override
  String get analyticsTimeWindowTypeYear => '年';

  @override
  String get analyticsTimeWindowTypeCustom => '自定义';

  @override
  String get analyticsTimeWindowCustomCta => '选择日期范围';

  @override
  String get analyticsTimeWindowErrorTooLong => '时间范围不能超过 12 个月。请选择较短的范围。';

  @override
  String get analyticsTimeWindowErrorInverted => '开始日期必须早于结束日期。';

  @override
  String get analyticsTimeWindowErrorFutureEnd => '结束日期不能晚于今天。';

  @override
  String get analyticsTimeWindowEmptyPreset => '此视图暂无数据。请先添加一笔交易。';

  @override
  String get analyticsKpiTotalLabel => '支出合计';

  @override
  String get analyticsKpiJoyLabel => '平均满足度';

  @override
  String analyticsKpiJoySubMedianCoverage(String median, int k, int N) {
    return '中位数 $median · n=$k/$N';
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
  String get analyticsKpiJoyEmptyCaption => '数据收集中...';

  @override
  String get analyticsKpiJoyIndexLabel => '悦己指数';

  @override
  String get analyticsKpiJoyIndexEmptyCaption => '给悦己账条目标记满足度后，会显示悦己指数。';

  @override
  String analyticsKpiJoyIndexSemantics(
    String label,
    String value,
    int ratedCount,
    int totalCount,
  ) {
    return '$label $value，已评分 $ratedCount/$totalCount';
  }

  @override
  String analyticsKpiJoyIndexSubMedianCoverage(
    String median,
    int ratedCount,
    int totalCount,
  ) {
    return '中位数 $median · 已评分 $ratedCount/$totalCount';
  }

  @override
  String get analyticsGroupHeaderTime => '━ 时间 / Time ━';

  @override
  String get analyticsGroupHeaderDistribution => '━ 分布 / Distribution ━';

  @override
  String get analyticsGroupHeaderStories => '━ 故事 / Stories ━';

  @override
  String get analyticsCardTitleTotalSixMonth => '总 · 6 个月支出推移';

  @override
  String get analyticsCardCaptionTotalSixMonth => 'BarChart · 当月高亮';

  @override
  String get analyticsCardTitleCategoryDonut => '总 · 类别支出分布';

  @override
  String get analyticsCardCaptionCategoryDonut => 'Donut/PieChart · top-N + 其他';

  @override
  String get analyticsCategoryDonutOther => '其他';

  @override
  String get analyticsCardTitleSatisfactionHistogram => '悦己 · 满足度分布 1–10';

  @override
  String get analyticsCardCaptionHistogram =>
      'Histogram · cool→warm · 5 bar 三语注释';

  @override
  String get analyticsHistogramBarFiveAnnotation => '中位数·含未评分';

  @override
  String get analyticsHistogramColorCaption => '色彩仅为 ordinal 视觉区分';

  @override
  String get analyticsCardTitleLargestExpense => '总 · 最大支出';

  @override
  String analyticsCardLargestExpenseBody(
    String categoryName,
    String amount,
    String date,
  ) {
    return '$categoryName · $amount · $date';
  }

  @override
  String get analyticsCardEmptyLargestExpense => '暂无数据 — 还没有支出记录';

  @override
  String get analyticsCardTitleBestJoy => '悦己 · 最美时刻';

  @override
  String analyticsCardBestJoyBig(String categoryName, String date) {
    return '$categoryName · $date';
  }

  @override
  String analyticsCardSmallBestJoy(String amount, int sat) {
    return '$amount · 满足 $sat/10 ✨';
  }

  @override
  String get analyticsCardEmptyBestJoy => '最值还没出现';

  @override
  String get analyticsCardTitleFamilyInsight => '家族 · 小确幸总结';

  @override
  String analyticsFamilyHighlightsSentence(int N) {
    return '家族小确幸 $N 次';
  }

  @override
  String analyticsFamilySharedJoySentence(
    String categoryName,
    int count,
    String avg,
  ) {
    return '你们都偏爱 [$categoryName] (n=$count, 平均 $avg/10)';
  }

  @override
  String get analyticsFamilyEmpty => '还没有共同最爱品类——多记几笔悦己账试试';

  @override
  String get analyticsThinSampleFallbackHeading => '悦己账记录不足 5 笔';

  @override
  String get analyticsThinSampleFallbackBody => '多记录一周后回来看 Joy 趋势';

  @override
  String get analyticsThinSampleFallbackCta => '去记录 »';

  @override
  String get analyticsCardErrorHeading => '数据加载失败';

  @override
  String get analyticsCardErrorBody => '请稍后再试';

  @override
  String get analyticsCardErrorRetry => '重试';

  @override
  String get analyticsCardTitlePerCategoryJoy => '悦己 · 类别';

  @override
  String get analyticsCardTitlePerCategoryJoyYou => '悦己 · 你的类别';

  @override
  String get analyticsCardTitlePerCategoryJoyFamily => '悦己 · 家庭类别';

  @override
  String analyticsPerCategoryRow(
    String categoryName,
    String avgSat,
    int count,
  ) {
    return '$categoryName · 平均 $avgSat / $count 条';
  }

  @override
  String analyticsPerCategoryOtherFold(int totalCount, int categoryCount) {
    return '其他：$totalCount 条，跨 $categoryCount 个类别';
  }

  @override
  String get analyticsPerCategoryShowAll => '展开全部';

  @override
  String get analyticsPerCategoryShowLess => '收起';

  @override
  String get analyticsCardTitleLedgerThisWindow => '本期账本描述';

  @override
  String get analyticsLedgerColumnJoy => '悦己';

  @override
  String get analyticsLedgerColumnDaily => '日常';

  @override
  String get analyticsLedgerRowYou => '你';

  @override
  String get analyticsLedgerRowFamily => '家庭';

  @override
  String analyticsLedgerCellEntries(int count) {
    return '$count 条';
  }

  @override
  String analyticsLedgerCellAvgSat(String avgSat) {
    return '平均满意 $avgSat';
  }

  @override
  String get analyticsPerCategoryEmpty => '本期暂无类别数据';

  @override
  String get analyticsLedgerEmpty => '本期暂无数据';

  @override
  String get analyticsLedgerFamilyEmpty => '本期暂无家庭数据';

  @override
  String get analyticsLedgerFamilyError => '无法获取家庭数据';

  @override
  String budgetRemainingAmount(String amount) {
    return '剩余: $amount';
  }

  @override
  String budgetExceededAmount(String amount) {
    return '超出: $amount';
  }

  @override
  String get calMonthTotal => '本月支出';

  @override
  String calDayTotal(String date) {
    return '$date支出';
  }

  @override
  String get calLoadError => '无法加载数据';

  @override
  String get listSortDate => '日期';

  @override
  String get listSortEditTime => '更新时间';

  @override
  String get listSortAmount => '金额';

  @override
  String get listLedgerAll => '全部';

  @override
  String get listLedgerDaily => '日常';

  @override
  String get listLedgerJoy => '悦己';

  @override
  String get listCategoryChip => '分类';

  @override
  String listCategoryChipN(int n) {
    return '分类 ($n)';
  }

  @override
  String get listSearchHint => '搜索...';

  @override
  String get listClearAll => '清除';

  @override
  String get listMineOnly => '仅自己';

  @override
  String get listDeleteConfirmTitle => '确认删除？';

  @override
  String get listDeleteConfirmBody => '此记录将被删除，无法恢复。';

  @override
  String get listDeleteCancelButton => '取消';

  @override
  String get listDeleteConfirmButton => '删除';

  @override
  String get listDeletedSnackBar => '已删除';

  @override
  String get listCategorySheetTitle => '按分类筛选';

  @override
  String get listCategorySheetClear => '清除';

  @override
  String get listCategorySheetApply => '应用';

  @override
  String listCategorySheetApplyN(int n) {
    return '应用 ($n)';
  }

  @override
  String get listEmptyMonth => '本月还没有记录';

  @override
  String get listEmptyFiltered => '没有符合条件的记录';

  @override
  String get listEmptyFilteredClear => '清除筛选';

  @override
  String get listEmptyDay => '这一天没有记录';

  @override
  String get listEmptyDayClear => '显示整月';

  @override
  String get listLoadError => '无法加载数据';

  @override
  String get listCalNavPrev => '上个月';

  @override
  String get listCalNavNext => '下个月';

  @override
  String get listCalNavCurrentMonth => '返回本月';

  @override
  String get shoppingEmptyPrivateHeading => '购物清单是空的';

  @override
  String get shoppingEmptyPrivateBody => '点「+」添加第一个商品';

  @override
  String get shoppingEmptyPublicSoloHeading => '公共清单是空的';

  @override
  String get shoppingEmptyPublicSoloBody => '添加要和家人共享的商品';

  @override
  String get shoppingEmptyPublicFamilyHeading => '还没有商品';

  @override
  String get shoppingEmptyPublicFamilyBody => '谁都可以添加，来加第一个吧';

  @override
  String get shoppingEmptyCta => '添加商品';

  @override
  String get shoppingFilterLedgerAll => '全部';

  @override
  String get shoppingFilterStatusActive => '仅活跃';

  @override
  String get shoppingFilterStatusAll => '所有商品';

  @override
  String get shoppingFilterCategory => '分类';
}
