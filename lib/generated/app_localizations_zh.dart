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
  String get survivalLedger => '生存账本';

  @override
  String get soulLedger => '灵魂账本';

  @override
  String get survival => '生存';

  @override
  String get soul => '灵魂';

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
  String get noTransactionsYet => '暂无交易记录';

  @override
  String get tapToAddFirstTransaction => '点击 + 添加第一笔交易';

  @override
  String get transactionSaved => '交易已保存';

  @override
  String get failedToSave => '保存失败';

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
  String get initializationError => '应用初始化失败';

  @override
  String get homeMonthlyExpense => '本月支出';

  @override
  String get homeSurvivalExpense => '生存支出';

  @override
  String get homeSoulExpense => '灵魂支出';

  @override
  String get homeMonthComparison => '较上月';

  @override
  String get homeSoulFullness => '灵魂充盈度';

  @override
  String get homeSoulPercentLabel => '本月灵魂支出占比';

  @override
  String get homeHappinessROI => '快乐 ROI';

  @override
  String get homeFamilyInviteTitle => '邀请家人';

  @override
  String get homeFamilyInviteDesc => '与伴侣共享家计簿';

  @override
  String get homeTodayTitle => '今日记录';

  @override
  String homeTodayCount(int count) {
    return '$count条';
  }

  @override
  String get homePersonalMode => '个人模式';

  @override
  String get homeTabHome => '主页';

  @override
  String get homeTabList => '列表';

  @override
  String get homeTabChart => '图表';

  @override
  String get homeTabTodo => '待办事项';

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
    return '最近一笔: $merchant ¥$amount';
  }

  @override
  String homeSoulChargeStatus(int fullness, double roi) {
    return '灵魂充盈度 $fullness% · 快乐ROI ${roi}x';
  }

  @override
  String homeMonthBadge(int percent) {
    return '本月 $percent%';
  }

  @override
  String get addTransaction => '添加账目';

  @override
  String get manualInput => '手动输入';

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
  String get enterStore => '输入店铺';

  @override
  String get enterMemo => '输入备注...';

  @override
  String get expenseClassification => '支出分类';

  @override
  String get survivalExpense => '生存支出';

  @override
  String get soulExpense => '灵魂支出';

  @override
  String get soulSatisfaction => '灵魂充盈度';

  @override
  String get addPhoto => '添加照片';

  @override
  String get ocrScanTitle => 'OCR扫描录入';

  @override
  String get ocrHint => '将票据完整放入框内';

  @override
  String get voiceRecognitionResult => '识别结果';

  @override
  String get tapToRecord => '点击开始录音';

  @override
  String get todayDate => '今天';

  @override
  String get next => 'Next';

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
}
