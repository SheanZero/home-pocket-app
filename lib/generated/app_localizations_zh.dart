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
  String get entrySavedDone => '记好啦！';

  @override
  String get continuousKeepGoing => '记好啦，继续记吧';

  @override
  String get continuousExitHint => '点退出键可结束连续记账';

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
  String get themeSystem => '跟随设备设置';

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
  String get settingsGeneral => '通用';

  @override
  String get settingsFamily => '家庭';

  @override
  String get settingsData => '数据';

  @override
  String get settingsThisApp => '关于本应用';

  @override
  String get settingsAdditional => '其他设置';

  @override
  String get settingsAdditionalDescription => '每周起始日、语音识别与通知';

  @override
  String get settingsNotSet => '未设置';

  @override
  String settingsJoyTargetValue(int value) {
    return '$value Joy';
  }

  @override
  String get settingsLocalDataProtected => '数据已在设备内受到保护';

  @override
  String get backupAndRestore => '备份与恢复';

  @override
  String get backupAndRestoreDescription => '加密文件';

  @override
  String get backupHeroTitle => '把数据安全地保管在自己手中';

  @override
  String get backupHeroDescription => '使用密码加密记录与设置，并保存到设备或你选择的云盘位置。';

  @override
  String get backupEncryptionChip => 'AES-256-GCM';

  @override
  String get backupCompressedChip => '已压缩';

  @override
  String get backupNoUploadChip => '不会自动上传';

  @override
  String get backupSectionTitle => '备份';

  @override
  String get restoreSectionTitle => '恢复';

  @override
  String get backupPasswordNotStored => '密码不会保存在本应用中。如果忘记密码，将无法恢复备份。';

  @override
  String get restoreReplacesData => '选择 .hpb 文件并替换当前数据';

  @override
  String get restoreWarningTitle => '当前数据将被替换';

  @override
  String get restoreWarningBody => '如果恢复失败，当前数据会保持不变。';

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
  String get deleteAllDataDescription => '永久删除此设备上的数据';

  @override
  String get deleteAllDataConfirmation =>
      '这会永久删除此设备上的家庭口袋数据，但不会删除其他家庭成员设备上的数据，也不会向服务器发送删除请求。';

  @override
  String get allDataDeleted => '本地数据已删除';

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
  String get profileEditPersonalInfo => '编辑个人信息';

  @override
  String get profileDisplayName => '显示名称';

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
  String get homeFamilyInviteTitle => '添加家人';

  @override
  String get homeFamilyInviteDesc => '与伴侣共享家计簿';

  @override
  String get homeFamilyInviteDismissLabel => '关闭家人添加提示';

  @override
  String get homeFamilyInviteSettingsPath => '设置 › 家庭';

  @override
  String get homeFamilyBannerTitle => '与家人共享家计';

  @override
  String get homeFamilyBannerSubtitle => '可随时在设置中添加';

  @override
  String get homeTodayTitle => '今日记录';

  @override
  String homeTodayCount(int count) {
    return '$count条';
  }

  @override
  String get homePersonalMode => '个人';

  @override
  String get homeFamilyMode => '家庭';

  @override
  String get homeTabHome => '主页';

  @override
  String get homeTabList => '列表';

  @override
  String get homeTabChart => '图表';

  @override
  String get homeTabShopping => '购物';

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
  String get homeJoyEmptyTitleSingle => '今天，什么让你开心？';

  @override
  String get homeJoyEmptyTitleGroup => '家人今天有什么小确幸？';

  @override
  String get homeJoyEmptySubtitle => '从一件小享受开始记录';

  @override
  String get homeJoyEmptyFree => '自由记录';

  @override
  String get homeJoyEmptyCoffee => '喜欢的一杯';

  @override
  String get homeJoyEmptyBook => '想读的书';

  @override
  String get homeJoyEmptyRest => '放松片刻';

  @override
  String get homeRingSectionTitleSingle => '悦己充盈';

  @override
  String get homeRingSectionTitleGroup => '我的悦己';

  @override
  String get homeViewMonthlyAnalysis => '查看本月分析';

  @override
  String get homeViewDetails => '查看详情';

  @override
  String get homeMetricJoyUnit => 'Joy';

  @override
  String get homeMetricCountUnit => '件';

  @override
  String get homeBestJoyTagSingle => '本月最爱';

  @override
  String get homeBestJoyTagGroup => '本月最爱';

  @override
  String homeBestJoyAmountSat(String amount, int sat) {
    return '$amount · 满足 $sat/10 ✨';
  }

  @override
  String get homeMembersSectionTitle => '成员支出';

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
  String get satisfactionSheetManualReason => '已设为悦己支出';

  @override
  String satisfactionSheetCategoryReason(String categoryName) {
    return '已根据“$categoryName”设为悦己支出';
  }

  @override
  String get satisfactionSheetTitle => '这笔消费让你有多满足？';

  @override
  String satisfactionSheetCurrent(String level) {
    return '当前为「$level」，选择后可随时修改';
  }

  @override
  String get satisfactionSheetChoiceTwo => '还好';

  @override
  String get satisfactionSheetChoiceFour => '很棒';

  @override
  String get satisfactionSheetAutoReturn => '选择后自动返回记账';

  @override
  String satisfactionSheetKeepCurrent(String level) {
    return '保持「$level」';
  }

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
  String get noMatchingCategories => '没有匹配的分类';

  @override
  String get addL1CategoryTitle => '添加分类';

  @override
  String addL2CategoryTitle(String parentName) {
    return '添加到“$parentName”';
  }

  @override
  String get categoryNameLabel => '分类名称';

  @override
  String get categoryNameHint => '例如：周末项目';

  @override
  String get categoryAppearanceLabel => '外观';

  @override
  String get categoryAppearanceDescription => '便于在分类列表和图表中快速识别。';

  @override
  String get categoryPreviewName => '新分类';

  @override
  String get categoryIconLabel => '图标';

  @override
  String get categoryColorLabel => '颜色';

  @override
  String get categoryNameRequired => '请输入分类名称';

  @override
  String get categoryNameTooLong => '最多输入 50 个字符';

  @override
  String get categoryNameExists => '已存在同名分类';

  @override
  String get categoryLedgerLabel => '账本';

  @override
  String get categoryLedgerDescription => '选择此分类的支出记入哪个账本。';

  @override
  String get createCategory => '添加';

  @override
  String get categoryAdded => '分类已添加';

  @override
  String get categoryAddFailed => '添加失败，请重试';

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
  String get voiceRecordBar => '语音记录';

  @override
  String get listeningTitle => '正在聆听…';

  @override
  String get voiceTapToExit => '轻点空白处退出';

  @override
  String get voiceStatusProcessing => '正在解析…';

  @override
  String get voiceStatusStopped => '停止聆听';

  @override
  String get voiceTapResetToRerecord => '点击重置重新录入';

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
  String get voiceOnDeviceRecognitionTitle => '设备端识别';

  @override
  String get voiceAllowCloudFallbackTitle => '允许云端回退';

  @override
  String get voiceAllowCloudFallbackSubtitle =>
      '关闭后，识别将仅在设备端进行；失败时会提示错误，而不使用云端识别。';

  @override
  String get familySync => '家庭同步';

  @override
  String get familySyncShowMyCode => '创建分组';

  @override
  String get familySyncEnterPartnerCode => '使用邀请码加入';

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
  String get familySyncRestoreFailed => '暂时无法恢复家庭状态，请稍后重试。';

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
  String get familySyncRegenerateInviteFailed => '暂时无法生成新的邀请码，请稍后再试。';

  @override
  String get familySyncInviteTitle => '邀请家庭成员';

  @override
  String get familySyncInviteDescription => '请将此邀请码分享给你想邀请的人。';

  @override
  String get familySyncInviteCopy => '复制邀请码';

  @override
  String get familySyncInviteCopied => '邀请码已复制';

  @override
  String get familySyncInviteRefreshHint => '刷新后，之前的邀请码会立即失效。';

  @override
  String get familySyncInviteApprovalWindowHint =>
      '邀请码有效期仅限制发起新申请；提交申请后，家庭创建者有5分钟进行审批。';

  @override
  String familySyncInviteShareMessage(String groupName, String inviteCode) {
    return '我在「$groupName」为你留了一个位置。\n一起来记录生活，轻松打理我们的小家吧。\n\n邀请码：$inviteCode\n请在 10 分钟内使用。';
  }

  @override
  String get familySyncInviteOwnerOnly => '只有家庭创建者可以管理邀请码。';

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
  String get familySyncGroupManagement => '家庭管理';

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
  String get groupCreate => '创建新家庭';

  @override
  String get groupCreateConfirmationHint => '仅在确认后才会创建群组和邀请码。';

  @override
  String groupCreateFailed(String message) {
    return '无法创建群组：$message';
  }

  @override
  String get familySyncSingleGroupConflict =>
      '此设备已有家庭群组或待审批的加入申请。请先退出当前群组或取消申请，再创建或加入其他群组。';

  @override
  String get familySyncJoinAnotherFamily => '加入其他家庭';

  @override
  String get familySyncNetworkUnavailableTitle => '暂时无法连接网络';

  @override
  String get familySyncNetworkUnavailableMessage =>
      '家庭共享需要网络连接。请检查网络状态，并确认已允许本应用使用无线数据后重试。';

  @override
  String get groupName => '群组名称';

  @override
  String get groupOwner => '群主';

  @override
  String get groupMember => '成员';

  @override
  String get groupInviteCode => '家庭邀请码';

  @override
  String groupInviteExpiry(int minutes) {
    return '$minutes分钟内有效';
  }

  @override
  String groupInviteCountdown(String time) {
    return '$time内有效';
  }

  @override
  String get groupInviteExpired => '已失效';

  @override
  String get groupShareCode => '分享邀请码';

  @override
  String get groupEnterCode => '输入邀请码';

  @override
  String get groupVerify => '验证';

  @override
  String get groupConfirmJoin => '申请加入';

  @override
  String get groupJoinTarget => '你要加入的群组';

  @override
  String get groupWaitingApproval => '等待家庭所有者批准';

  @override
  String groupWaitingDesc(String name) {
    return '$name 正在确认你的加入申请。';
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
  String get groupChoiceTitle => '想从哪里开始？';

  @override
  String get groupChoiceSubtitle => '同一时间只能加入一个家庭。';

  @override
  String get groupCreateDesc => '生成邀请码，由你审批每位成员';

  @override
  String get groupJoinDesc => '加入前需要家庭所有者批准';

  @override
  String get groupE2eeHint => '家庭公开账本会加密同步；个人私密账本只保留在本设备。';

  @override
  String get familyFlowCreateStepCreate => '创建家庭';

  @override
  String get familyFlowCreateHeader => '创建家庭';

  @override
  String get familyFlowJoinHeader => '加入家庭';

  @override
  String get familyFlowReviewFamily => '确认家庭信息';

  @override
  String get familyFlowCreateStepInvite => '分享邀请';

  @override
  String get familyFlowCreateStepApprove => '审批成员';

  @override
  String get familyFlowJoinStepCode => '输入邀请码';

  @override
  String get familyFlowJoinStepConfirm => '确认家庭';

  @override
  String get familyFlowJoinStepWait => '等待批准';

  @override
  String familyFlowOwnerSummary(String name) {
    return '$name · 所有者';
  }

  @override
  String get familyFlowCreateTitle => '创建新家庭';

  @override
  String get familyFlowCreateSubtitle => '设置家庭名称后，将生成安全的邀请码。';

  @override
  String get familyFlowCreateInviteHelper => '家人提交加入申请后，你将在下一步审批成员。';

  @override
  String get familyFlowCopyInvite => '复制';

  @override
  String get familyFlowRegenerateInvite => '重新生成';

  @override
  String get familySyncInviteRegenerated => '邀请码已重新生成';

  @override
  String get familyFlowJoinCodeTitle => '输入 6 位邀请码';

  @override
  String get familyFlowJoinCodeSubtitle => '请输入家庭所有者发给你的数字。';

  @override
  String get familyFlowJoinBeforeApprovalHelper => '申请获批前，不会同步任何账本。';

  @override
  String get familyFlowJoinConfirmHeader => '确认家庭';

  @override
  String get familyFlowJoinConfirmTitle => '确认要加入的家庭';

  @override
  String get familyFlowJoinConfirmSubtitle => '加入申请将发送到这个家庭。';

  @override
  String get familyFlowPublicKeyVerified => '公开密钥已验证';

  @override
  String get familyFlowPrivateLedgerHelper => '个人私密账本不会分享给家庭。';

  @override
  String get familyFlowWaitingHeader => '正在等待批准';

  @override
  String familyFlowWaitingFamily(String groupName) {
    return '申请加入：$groupName';
  }

  @override
  String get familyFlowApprovalTitle => '新的加入申请';

  @override
  String get familyFlowApprovalSubtitle => '批准前，请确认本人和设备。';

  @override
  String familyFlowApprovalDevice(String deviceName) {
    return '来自 $deviceName 的加入申请';
  }

  @override
  String get familyFlowDeviceKeyVerified => '设备公开密钥已验证';

  @override
  String get familyFlowApprovalHelper => '批准后，此设备会与家庭公开账本进行加密同步。';

  @override
  String get familyFlowApprovalEmptyTitle => '没有待处理的申请';

  @override
  String familyFlowPendingRequests(int count) {
    return '新的加入申请 · $count 条';
  }

  @override
  String get familyFlowViewRequests => '查看申请';

  @override
  String get familyFlowSyncSettings => '同步设置';

  @override
  String familyFlowManagementSummary(
    String ownerName,
    int count,
    String syncStatus,
  ) {
    return '所有者：$ownerName · $count 人 · $syncStatus';
  }

  @override
  String get groupInviteMembers => '邀请新成员';

  @override
  String get groupDisband => '解散家庭';

  @override
  String get groupCancel => '取消';

  @override
  String get groupCancelRequest => '撤回加入申请';

  @override
  String groupRejectRequestFailed(String message) {
    return '拒绝加入申请失败: $message';
  }

  @override
  String get groupRequestRejectedTitle => '加入申请已被拒绝';

  @override
  String get groupRequestRejectedDescription => '群主拒绝了本次申请，你可以使用其他邀请码重新申请。';

  @override
  String get groupRequestCancelledTitle => '加入申请已撤回';

  @override
  String get groupRequestCancelledDescription => '申请已撤回，你可以随时重新提交新的申请。';

  @override
  String get groupRequestExpiredTitle => '加入申请已过期';

  @override
  String get groupRequestExpiredDescription => '申请在5分钟内未被处理，请获取当前有效的邀请码后重新申请。';

  @override
  String get groupTryAnotherInvite => '输入其他邀请码';

  @override
  String get groupUnableToJoinTitle => '暂时无法加入家庭';

  @override
  String get groupUnableToJoinDescription => '别担心，你可以重新输入邀请码，或退出后重新选择家庭。';

  @override
  String get groupReenterInvite => '重新输入邀请码';

  @override
  String get groupExitAndChooseAnother => '退出并重新选择家庭';

  @override
  String get groupUnableToJoinActionFailed => '暂时无法完成操作，请稍后重试。';

  @override
  String get groupKeyRecoveryTitle => '正在恢复家庭密钥';

  @override
  String get groupKeyRecoveryWaiting =>
      '成员资格已经生效，需要另一台仍持有密钥的家庭设备为本设备重新密封当前密钥。中继服务器无法读取或重新生成密钥。';

  @override
  String get groupKeyRecoveryUnavailable =>
      '请求过期前没有任何有效设备提供当前密钥。由于采用零知识设计，中继服务器无法恢复密钥。你可以重试，或安全退出／解散该家庭后重新创建。';

  @override
  String get groupKeyRecoveryRateLimited => '刚刚已经发送过恢复请求，请稍后再通知其他设备。';

  @override
  String get groupKeyRecoveryRetry => '重试密钥恢复';

  @override
  String get groupKeyRecoveryRebuild => '退出并重新选择家庭';

  @override
  String get groupWaitingHint1 => '关闭应用也没有关系。';

  @override
  String get groupWaitingHint2 => '批准后将自动开始同步。';

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
  String get homeRecentTransactions => '最近支出';

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
  String voiceCurrencyConverted(
    String original,
    String converted,
    String rate,
  ) {
    return '已识别为外币：$original → $converted（汇率 $rate）';
  }

  @override
  String get voiceCurrencyConvertedUndo => '撤销';

  @override
  String voiceAmountRepairSuspect(String original, String candidate) {
    return '金额识别为 $original，是否应为 $candidate？';
  }

  @override
  String voiceAmountRepairApply(String candidate) {
    return '改为 $candidate';
  }

  @override
  String voiceLargeAmountNotice(String amount) {
    return '金额较大：$amount，保存前请确认';
  }

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
  String get analyticsTrendTabAll => '全部';

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
  String get analyticsCardTitleTotalSixMonth => '总 · 6 个月支出推移';

  @override
  String get analyticsCardCaptionTotalSixMonth => 'BarChart · 当月高亮';

  @override
  String get analyticsCardTitleCategoryDonut => '总 · 类别支出分布';

  @override
  String get analyticsCardCaptionCategoryDonut => 'Donut/PieChart · top-N + 其他';

  @override
  String get analyticsCardTitleWithinMonthTrend => '支出趋势';

  @override
  String get analyticsCardCaptionWithinMonthTrend => '本月按天累计支出';

  @override
  String get analyticsTrendSeriesThisMonth => '本月';

  @override
  String get analyticsTrendSeriesLastMonth => '上月';

  @override
  String get analyticsCardTitleJoySpend => '悦己 · 花在哪';

  @override
  String get analyticsCardCaptionJoySpend => '你的悦己花销去向';

  @override
  String get analyticsJoySpendHeaderLabel => '悦己花销';

  @override
  String get analyticsJoySpendEmpty => '这个时间段还没有悦己花销';

  @override
  String get analyticsCardTitleJoyCalendar => '小确幸 · 日历';

  @override
  String get analyticsCardCaptionJoyCalendar => '悦己日子的纹理';

  @override
  String get analyticsJoyCalendarDayEmpty => '这一天还没有小确幸记录';

  @override
  String get analyticsTabSpending => '支出';

  @override
  String get analyticsTabFamilySpending => '家庭支出';

  @override
  String get analyticsTabJoy => '悦己';

  @override
  String get analyticsTabMyJoy => '我的悦己';

  @override
  String analyticsTabJoyCount(int count) {
    return '$count次';
  }

  @override
  String get analyticsSectionTrend => '支出趋势';

  @override
  String get analyticsSectionCategory => '分类支出';

  @override
  String get analyticsSectionJoyCalendar => '小确幸日历';

  @override
  String get analyticsSectionSatisfaction => '悦己满足度分布';

  @override
  String analyticsJoyDrawerTitle(String amount) {
    return '悦己 $amount';
  }

  @override
  String analyticsJoyDrawerCount(int count) {
    return '$count 类';
  }

  @override
  String analyticsJoyDrawerMemberCount(int count) {
    return '$count 名成员';
  }

  @override
  String get analyticsCalLegendLow => '少';

  @override
  String get analyticsCalLegendHigh => '多';

  @override
  String get analyticsCalLegendNote => '颜色越浓 = 那天的悦己笔数越多';

  @override
  String analyticsHistogramMedianPill(int value) {
    return '中位满足度 $value';
  }

  @override
  String analyticsHistogramCountFooter(int count) {
    return '$count 笔悦己支出的满足度';
  }

  @override
  String analyticsHistogramNarrative(int value) {
    return '本月悦己支出的满足度中位数为 $value 分';
  }

  @override
  String get analyticsCategoryDonutOther => '其他';

  @override
  String get analyticsDonutDimensionCategory => '分类';

  @override
  String get analyticsDonutDimensionMember => '成员';

  @override
  String get analyticsDonutMemberFilterAll => '所有成员';

  @override
  String get analyticsDonutMemberFilterLabel => '成员';

  @override
  String get analyticsDonutMemberFilterSelf => '自己';

  @override
  String get analyticsDonutCenterLabel => '本月支出';

  @override
  String get analyticsDrillSubtotalLabel => '小计';

  @override
  String get analyticsDrillCountLabel => '笔数';

  @override
  String get analyticsDrillAvgPerDayLabel => '日均';

  @override
  String get analyticsDrillEmpty => '此期间没有记录';

  @override
  String get analyticsDrillLoadError => '加载失败';

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
  String get calMonthTotal => '本月合计';

  @override
  String get calFamilyMonthTotal => '家庭合计';

  @override
  String get calMonthTotalDaily => '日常合计';

  @override
  String get calMonthTotalJoy => '悦己合计';

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
    return '分类 $n';
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
  String get listMonthPickerLabel => '选择月份';

  @override
  String get listSortDirectionDesc => '降序';

  @override
  String get listSortDirectionAsc => '升序';

  @override
  String listSortPillLabel(String field, String direction) {
    return '$field・$direction';
  }

  @override
  String get shoppingDeleteConfirmTitle => '删除此商品？';

  @override
  String get shoppingDeleteConfirmBody => '该商品将从购物清单中移除。';

  @override
  String get shoppingDeleteConfirmButton => '删除';

  @override
  String get shoppingDeleteCancelButton => '取消';

  @override
  String get shoppingDeletedSnackBar => '已删除商品';

  @override
  String get shoppingEditItem => '编辑商品';

  @override
  String get shoppingActionEdit => '修改';

  @override
  String get shoppingReorderItem => '重新排序';

  @override
  String get shoppingToggleComplete => '切换完成';

  @override
  String get shoppingEnterReorderMode => '排序';

  @override
  String get shoppingExitReorderMode => '完成';

  @override
  String get shoppingMoveToTop => '置顶';

  @override
  String get shoppingMoveToBottom => '置底';

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

  @override
  String get shoppingSegmentPublic => '公共';

  @override
  String get shoppingSectionToBuy => '购买清单';

  @override
  String get shoppingListScreenTitle => '购物清单';

  @override
  String get shoppingSegmentAll => '全部';

  @override
  String get shoppingSegmentPrivate => '私有';

  @override
  String get shoppingFilterPrivate => '私有';

  @override
  String get shoppingFormListTypeLabel => '类型';

  @override
  String get shoppingListTypeLockedHint => '创建后不可更改';

  @override
  String get shoppingCompletedDivider => '已完成';

  @override
  String get shoppingScopeAll => '全部';

  @override
  String get shoppingScopePersonal => '个人';

  @override
  String get shoppingClearCompletedAction => '全部删除';

  @override
  String get shoppingFilteredEmpty => '没有符合条件的购物项目';

  @override
  String get shoppingClearCompletedTitle => '清除所有已完成？';

  @override
  String get shoppingClearCompletedBody => '将删除所有已完成的商品。';

  @override
  String get shoppingClearCompletedConfirm => '删除';

  @override
  String get shoppingClearCompletedSnackBar => '已删除完成的商品';

  @override
  String get shoppingListLoadError => '无法加载清单，请重试';

  @override
  String get shoppingRetry => '重试';

  @override
  String get shoppingBatchDeleteTitle => '删除商品？';

  @override
  String shoppingBatchDeleteBody(int count) {
    return '将删除选中的 $count 个商品。';
  }

  @override
  String get shoppingBatchDeleteConfirm => '删除';

  @override
  String get shoppingBatchDeletedSnackBar => '已删除选中商品';

  @override
  String get shoppingBatchDeleteAction => '删除';

  @override
  String get shoppingBatchCancel => '取消';

  @override
  String get shoppingBatchSelectAll => '全选';

  @override
  String shoppingSelectionCount(int count) {
    return '$count项';
  }

  @override
  String shoppingBatchSelectingCount(int count) {
    return '已选$count项';
  }

  @override
  String get shoppingFormAddTitle => '添加商品';

  @override
  String get shoppingFormEditTitle => '编辑商品';

  @override
  String get shoppingFormSave => '保存';

  @override
  String get shoppingFormNameLabel => '商品名称';

  @override
  String get shoppingFormNameRequired => '请输入名称';

  @override
  String get shoppingFormLedgerLabel => '账本';

  @override
  String get shoppingFormLedgerDaily => '日常';

  @override
  String get shoppingFormLedgerJoy => '悦己';

  @override
  String get shoppingFormCategoryLabel => '分类';

  @override
  String get shoppingFormNoCategorySelected => '未选择分类';

  @override
  String get shoppingFormChangeCategory => '更改';

  @override
  String get shoppingFormTagsLabel => '标签（逗号分隔）';

  @override
  String get shoppingFormNoteLabel => '备注';

  @override
  String get shoppingFormNotePlaceholder => '输入需要的备注';

  @override
  String get shoppingFormQuantityLabel => '数量';

  @override
  String get shoppingFormQuantityHint => '数值与单位可以分别设置';

  @override
  String get shoppingUnitPickerTitle => '选择单位';

  @override
  String get shoppingUnitPickerHelp => '切换单位不会自动换算数量';

  @override
  String get shoppingUnitCustom => '自定义单位';

  @override
  String get shoppingUnitCustomHint => '例如：杯';

  @override
  String get shoppingUnitCustomError => '请输入 1–12 个字符';

  @override
  String get shoppingUnitApply => '应用';

  @override
  String get shoppingUnitPiece => '件';

  @override
  String get shoppingUnitGram => 'g';

  @override
  String get shoppingUnitKilogram => 'kg';

  @override
  String get shoppingUnitMilliliter => 'ml';

  @override
  String get shoppingUnitLiter => 'L';

  @override
  String get shoppingUnitBag => '袋';

  @override
  String get shoppingUnitBottle => '瓶';

  @override
  String get shoppingUnitPack => '包';

  @override
  String get shoppingFormPrice => '预估价格';

  @override
  String get shoppingFormSaveError => '保存失败，请重试。';

  @override
  String get shoppingListTypeCreateHint => '保存后无法更改类型';

  @override
  String get shoppingFormSaving => '保存中…';

  @override
  String get shoppingFormPricePlaceholder => '未填写';

  @override
  String get shoppingVoiceManualTitle => '语音输入';

  @override
  String get shoppingVoiceManualHelp => '一次说出商品名、数量、用途、分类和参考价格';

  @override
  String get shoppingVoicePrivacy => '优先使用设备端识别';

  @override
  String get shoppingVoiceListeningStatus => '正在聆听';

  @override
  String get shoppingVoiceProcessingStatus => '正在解析';

  @override
  String get shoppingVoiceReviewStatus => '已填写到表单';

  @override
  String get shoppingVoiceUnavailableStatus => '无法使用麦克风';

  @override
  String get shoppingVoiceKeyboardAction => '返回手动输入';

  @override
  String get shoppingVoiceListeningPlaceholder => '“牛奶两瓶，日常，参考价格20元……”';

  @override
  String get shoppingVoiceProcessingPlaceholder => '“牛奶两瓶，日常，参考价格20元”';

  @override
  String get shoppingVoiceReviewPlaceholder => '请检查已填写到表单的内容';

  @override
  String get shoppingVoiceStopAction => '立即结束并解析';

  @override
  String get shoppingVoiceRerecordAction => '重新录音';

  @override
  String get shoppingVoiceListeningHelp => '说完约3秒后自动解析 · 点方块立即结束';

  @override
  String get shoppingVoiceProcessingHelp => '正在将语音整理为购物项内容';

  @override
  String get shoppingVoiceReviewHelp => '请确认内容，然后点击右上角“保存”添加';

  @override
  String get shoppingVoiceUnavailableHelp => '仍可继续使用手动输入';

  @override
  String get shoppingVoiceSettingsAction => '麦克风权限说明';

  @override
  String get entryVoiceLaunchHelp => '一次说出金额、商家、分类和日期';

  @override
  String get entryVoicePrivacy => '仅在设备内处理';

  @override
  String get entryVoiceIdleStatus => '等待语音输入中';

  @override
  String get entryVoiceListeningStatus => '正在聆听';

  @override
  String get entryVoiceProcessingStatus => '正在整理内容';

  @override
  String get entryVoiceReviewStatus => '已填入账目';

  @override
  String get entryVoiceUnavailableStatus => '无法使用语音输入';

  @override
  String get entryVoiceIdleTranscript => '可以开始记录下一笔';

  @override
  String get entryVoiceListeningPlaceholder => '“森林咖啡，午餐两千三百八十日元……”';

  @override
  String get entryVoiceProcessingPlaceholder => '“森林咖啡，午餐两千三百八十日元”';

  @override
  String get entryVoiceIdleHelp => '点击麦克风开始语音记录';

  @override
  String get entryVoiceListeningHelp => '说完稍候将自动识别，也可点按立即完成';

  @override
  String get entryVoiceProcessingHelp => '正在把识别结果填入同一份表单';

  @override
  String get entryVoiceReviewHelp => '点按麦克风重新录音，也可修改后直接记录';

  @override
  String get entryVoiceUnavailableHelp => '请在系统设置中允许麦克风，也可继续手动输入';

  @override
  String get entryVoiceKeyboardAction => '切换到键盘输入';

  @override
  String get entryVoiceStartAction => '开始语音输入';

  @override
  String get entryVoiceStopAction => '立即结束并解析';

  @override
  String get entryVoiceRerecordAction => '重新录音';

  @override
  String get entryVoiceSourceBadge => '语音填入';

  @override
  String get entryCategorySelectRequired => '需选择';

  @override
  String get entryContinuousReturnHome => '记录后返回主页';

  @override
  String get entryContinuousKeepNext => '记录后继续下一笔';

  @override
  String get entryContinuousEnable => '连续记账';

  @override
  String get entryContinuousDisable => '关闭连续记账';

  @override
  String get currencySelectorTitle => '选择货币';

  @override
  String get currencySelectorMore => '更多';

  @override
  String get currencySelectorSearchHint => '按代码或名称搜索';

  @override
  String get currencySelectorNoResults => '没有匹配的货币';

  @override
  String get currencyNameJpy => '日元';

  @override
  String get currencyNameUsd => '美元';

  @override
  String get currencyNameEur => '欧元';

  @override
  String get currencyNameCny => '人民币';

  @override
  String get currencyNameHkd => '港币';

  @override
  String get currencyNameGbp => '英镑';

  @override
  String get currencyNameKrw => '韩元';

  @override
  String get currencyNameTwd => '新台币';

  @override
  String get currencyNameSgd => '新加坡元';

  @override
  String get currencyNameAud => '澳元';

  @override
  String get currencyNameCad => '加元';

  @override
  String get currencyNameChf => '瑞士法郎';

  @override
  String get currencyNameThb => '泰铢';

  @override
  String get currencyNameInr => '印度卢比';

  @override
  String get currencyNameIdr => '印尼盾';

  @override
  String get currencyNameMyr => '马来西亚林吉特';

  @override
  String get currencyNamePhp => '菲律宾比索';

  @override
  String get currencyNameVnd => '越南盾';

  @override
  String get currencyNameNzd => '新西兰元';

  @override
  String get currencyNameBrl => '巴西雷亚尔';

  @override
  String get currencyNameRub => '俄罗斯卢布';

  @override
  String get currencyNameZar => '南非兰特';

  @override
  String get currencyNameSek => '瑞典克朗';

  @override
  String get currencyNameNok => '挪威克朗';

  @override
  String get currencyNameDkk => '丹麦克朗';

  @override
  String get currencyNameMxn => '墨西哥比索';

  @override
  String get currencyNameTry => '土耳其里拉';

  @override
  String get currencyNameAed => '阿联酋迪拉姆';

  @override
  String get currencyNameSar => '沙特里亚尔';

  @override
  String get currencyNamePln => '波兰兹罗提';

  @override
  String conversionPreviewRateRow(String code, String rate, String date) {
    return '$code 1 = ¥$rate · $date';
  }

  @override
  String conversionStalenessCached(String date) {
    return '使用 $date 缓存汇率';
  }

  @override
  String conversionStalenessWeekend(String date) {
    return '周末，采用 $date 汇率';
  }

  @override
  String get conversionRateRequired => '无法获取汇率，请手动输入汇率';

  @override
  String get editOriginalAmountLabel => '原币金额';

  @override
  String get editRateLabel => '汇率';

  @override
  String get editJpyDerivedLabel => '日元（换算）';

  @override
  String get currencyRateDateLabel => '汇率日期';

  @override
  String get editRateRequired => '请输入汇率';

  @override
  String get editRateInvalid => '请输入正数';

  @override
  String get editAmountRequired => '请输入金额';

  @override
  String get editAmountInvalid => '请输入正数';

  @override
  String get changeRateDialogTitle => '汇率确认';

  @override
  String get changeRateDialogBody => '您已手动设置了汇率。是否按新日期重新获取汇率？';

  @override
  String get changeRateKeepManual => '保留手动汇率';

  @override
  String get changeRateRefetch => '按新日期重取';

  @override
  String rateChangedToast(String oldJpy, String newJpy) {
    return '日元已自动调整：$oldJpy → $newJpy（汇率更新）';
  }

  @override
  String get rateChangedUndo => '撤销';

  @override
  String get analyticsDonutHeroCap => '这个月，钱花在哪';

  @override
  String analyticsDonutHeroTag(int count, int month) {
    return '$count 笔 · $month 月';
  }

  @override
  String analyticsDonutCenterCount(int count) {
    return '$count 笔';
  }

  @override
  String get analyticsCalWeekdayMon => '一';

  @override
  String get analyticsCalWeekdayTue => '二';

  @override
  String get analyticsCalWeekdayWed => '三';

  @override
  String get analyticsCalWeekdayThu => '四';

  @override
  String get analyticsCalWeekdayFri => '五';

  @override
  String get analyticsCalWeekdaySat => '六';

  @override
  String get analyticsCalWeekdaySun => '日';

  @override
  String get recognitionBandSuggestedCategory => '推测类目';

  @override
  String get recognitionAlternatesMore => '其他';

  @override
  String get onboardingIntroTitle => '守护家计簿';

  @override
  String get onboardingWelcomeBadge => '快乐记账，轻松坚持';

  @override
  String get onboardingWelcomeBrand => 'HOME POCKET';

  @override
  String get onboardingWelcomeTagline => '每一次记录，都有一点小幸福。\n让你与金钱的关系，更加积极。';

  @override
  String get onboardingPrivacyTitle => '数据，\n掌握在你手中。';

  @override
  String get onboardingPrivacySubtitle => '一切都在设备内完成。无需账号，也无需服务器。';

  @override
  String get onboardingPrivacyCardLocalTitle => '保存在设备内';

  @override
  String get onboardingPrivacyCardLocalBody => '不会上传到云端';

  @override
  String get onboardingPrivacyCardE2eTitle => '端到端加密';

  @override
  String get onboardingPrivacyCardE2eBody => '只有你拥有密钥';

  @override
  String get onboardingPrivacyCardTamperTitle => '防篡改保护';

  @override
  String get onboardingPrivacyCardTamperBody => '用哈希链保护每条记录';

  @override
  String get onboardingJoyTitle => '为每笔支出，记下当时的心情。';

  @override
  String get onboardingJoySubtitle => '记账不是繁琐的任务。把当下的满足感，也一起留下吧。';

  @override
  String get onboardingJoyCaption => '一键记录满足度。';

  @override
  String get onboardingJoyAccent => '花钱，是为了充实自己。';

  @override
  String get onboardingIntroContinue => '开始';

  @override
  String get onboardingIntroSkip => '跳过';

  @override
  String get onboardingSetupEyebrow => '最后一步';

  @override
  String get onboardingSetupTopbar => '初始设置';

  @override
  String get onboardingSetupTitle => '初始设置';

  @override
  String get onboardingRowName => '姓名・必填';

  @override
  String get onboardingRowLanguage => '显示语言';

  @override
  String get onboardingLanguageAuto => '自动';

  @override
  String get onboardingLanguageAutoNote => '选择「自动」时，如果系统语言不受支持，将以日语显示。';

  @override
  String get onboardingRowCurrency => '货币单位';

  @override
  String get onboardingRowVoice => '语音输入语言';

  @override
  String get onboardingStart => '用这些设置开始';

  @override
  String get onboardingPreparingHome => '正在准备首页…';

  @override
  String get onboardingPrivacyTagLocal => 'LOCAL';

  @override
  String get onboardingPrivacyTagE2ee => 'E2EE';

  @override
  String get onboardingPrivacyTagSafe => 'SAFE';

  @override
  String get onboardingAvatarChange => '更换图片';

  @override
  String get onboardingSecurityTitle => '安全保护家计簿';

  @override
  String get onboardingSecurityDescription => '启用后，每次打开应用都需要验证身份。';

  @override
  String get onboardingSecurityEnable => '启用安全保护';

  @override
  String get onboardingSecurityDeferTitle => '现在不设置，稍后再决定';

  @override
  String get onboardingSecurityDeferBody => '可随时在设置中启用';

  @override
  String get onboardingSecurityMethodLabel => '解锁方式';

  @override
  String get onboardingSecurityBiometric => '生物识别';

  @override
  String get onboardingSecurityBiometricDescription => '使用面容 ID 或指纹快速解锁';

  @override
  String get onboardingSecurityRecommended => '推荐';

  @override
  String get onboardingSecurityPin => '应用锁';

  @override
  String get onboardingSecurityPinDescription => '使用4位 PIN 解锁';

  @override
  String get onboardingSecurityPinMissing => '尚未设置 PIN';

  @override
  String get onboardingSecurityPinSetupHint => '输入两次后即可启用';

  @override
  String get onboardingSecurityPinSetup => '设置4位 PIN';

  @override
  String get onboardingSecurityPinSetAction => '设置';

  @override
  String get onboardingSecurityPinComplete => 'PIN 已设置';

  @override
  String get onboardingSecurityPinCompleteDescription => '当前由4位 PIN 保护';

  @override
  String get onboardingSecurityPinChange => '修改 PIN';

  @override
  String get onboardingSecurityPinUpdateAction => '更新';

  @override
  String get onboardingSetupNameRequiredHint => '输入姓名后即可开始';

  @override
  String get onboardingSetupPinRequiredHint => '设置 PIN 后即可开始';

  @override
  String get onboardingSetupChangeLaterHint => '之后可随时在设置中更改';

  @override
  String get onboardingLockTitle => '要设置应用锁吗？';

  @override
  String get onboardingLockDescription => '应用锁能让你的家计簿更安全。';

  @override
  String get onboardingLockSkip => '跳过';

  @override
  String get onboardingLockSetupNow => '现在设置';

  @override
  String get appLockPinTitle => '输入密码';

  @override
  String get appLockFaceIdPrompt => '请注视屏幕以使用 Face ID';

  @override
  String get appLockFaceIdRetry => '重试';

  @override
  String get appLockUsePasscode => '使用密码';

  @override
  String get appLockForgotPin => '忘记密码？';

  @override
  String get appLockForgotPinExplanation =>
      '如果忘记密码，将无法找回。你需要重新安装应用，这会丢失尚未同步的本地数据。';

  @override
  String get appLockSetPinTitle => '设置密码';

  @override
  String get appLockUpdatePinTitle => '更新密码';

  @override
  String get appLockSetPinDescription => '选择一组容易记住的4位数字，用于解锁 Home Pocket。';

  @override
  String get appLockConfirmPinTitle => '再次输入密码';

  @override
  String get appLockConfirmPinDescription => '再次输入相同的4位数字进行确认。';

  @override
  String appLockPinSetupProgress(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get appLockPinMismatch => '密码不一致';

  @override
  String get appLockReauthReason => '需要验证身份以继续';

  @override
  String get securityAppLock => '应用锁';

  @override
  String get securityAppLockDescription => '在启动和返回前台时用密码保护应用。';

  @override
  String get securityAppLockOff => '关闭';

  @override
  String get securityAppLockPinOnly => 'PIN 码';

  @override
  String securityAppLockBiometricAndPin(String biometric) {
    return '$biometric + PIN 码';
  }

  @override
  String get securityFaceId => 'Face ID';

  @override
  String get securityFingerprint => '指纹识别';

  @override
  String get securityBiometricUnlock => '生物识别解锁';

  @override
  String get securityBiometricUnlockDescription => '用 Face ID 或指纹解锁应用。';

  @override
  String get securityChangePin => '修改密码';

  @override
  String get legalSponsorSectionTitle => '法律信息・支持';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get tokushoNotice => '基于特定商业交易法的标示';

  @override
  String get tokushoNoticeSubtitle => '在日本提供服务所需的标示';

  @override
  String get sponsorRow => '支持开发';

  @override
  String get sponsorRowSubtitle => '为了持续无广告运营';

  @override
  String get sponsorLaunchError => '无法打开浏览器';

  @override
  String get legalNavigationSubtitle => '隐私、条款、开源许可';

  @override
  String get privacyPolicyDescription => '了解数据如何处理';

  @override
  String get termsOfUseDescription => '服务使用条件';

  @override
  String get openSourceLicensesDescription => '使用的开源库';

  @override
  String get sponsorSectionTitle => '支持开发';

  @override
  String get sponsorCardTitle => '一起维护这本安静的家庭账本';

  @override
  String get sponsorCardBody => '支持与联系页面将在外部浏览器中打开，不会影响应用功能或数据访问权限。';

  @override
  String get sponsorButton => '了解支持方式';

  @override
  String get legalLinkLaunchError => '无法打开链接';

  @override
  String analyticsTrendInsightTotal(String amount) {
    return '本月 $amount';
  }

  @override
  String analyticsTrendInsightTotalDelta(
    String amount,
    int pct,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'less': '少',
      'more': '多',
      'other': '',
    });
    return '本月 $amount · 较上月$_temp0$pct%';
  }

  @override
  String analyticsTrendInsightTotalSame(String amount) {
    return '本月 $amount · 与上月持平';
  }

  @override
  String analyticsTrendInsightDaily(String amount) {
    return '日常支出 $amount';
  }

  @override
  String analyticsTrendInsightDailyDelta(
    String amount,
    int pct,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'less': '少',
      'more': '多',
      'other': '',
    });
    return '日常支出 $amount · 较上月$_temp0$pct%';
  }

  @override
  String analyticsTrendInsightDailySame(String amount) {
    return '日常支出 $amount · 与上月持平';
  }

  @override
  String analyticsTrendInsightJoy(String amount) {
    return '本月悦己支出 $amount';
  }

  @override
  String analyticsCalSummary(int count, int days) {
    return '本月$count笔 · 记录于$days天';
  }

  @override
  String analyticsJoyCalendarDayHead(int month, int day, int count) {
    return '$month月$day日 · $count笔小确幸';
  }

  @override
  String get analyticsJoyDrawerToggleExpand => '展开悦己花销明细';

  @override
  String get analyticsJoyDrawerToggleCollapse => '收起悦己花销明细';

  @override
  String get syncQueueNeedsAttentionBadge => '需要处理';

  @override
  String get syncQueueNeedsAttentionDescription => '部分变更需要你处理';

  @override
  String get familySyncTransferOwner => '转让家庭所有权';

  @override
  String get familySyncTransferOwnerSelect => '选择新的家庭所有者';

  @override
  String get familySyncTransferOwnerConfirmTitle => '转让家庭所有权？';

  @override
  String familySyncTransferOwnerConfirmBody(String memberName) {
    return '$memberName 将负责成员、邀请和家庭管理。';
  }

  @override
  String get familySyncTransferOwnerFinalTitle => '最终确认';

  @override
  String familySyncTransferOwnerFinalBody(String memberName) {
    return '系统会为每台活跃设备签发新的加密密钥。转让后，你将成为普通成员。确认转让给 $memberName？';
  }

  @override
  String get familySyncTransferOwnerSuccess => '家庭所有权已安全转让';

  @override
  String get familySyncTransferOwnerNotReady => '当前加密密钥就绪前，无法执行家庭所有者操作';

  @override
  String get familySyncTransferOwnerInvalidTarget => '请选择其他活跃成员';

  @override
  String familySyncTransferOwnerFailed(String message) {
    return '无法转让家庭所有权：$message';
  }

  @override
  String get transactionPhotoBoundaryTitle => '票据照片';

  @override
  String get transactionPhotoLocalOnlyBody => '这张票据照片仅保存在本设备，不会包含在家庭同步或备份中。';

  @override
  String get transactionPhotoUnavailableBody =>
      '票据照片仅保存在录入这笔账目的设备上，未包含在家庭同步或备份中。';

  @override
  String get familySyncMemberHistory => '成员记录';

  @override
  String familySyncRequestedAt(String date) {
    return '申请于 $date';
  }

  @override
  String familySyncJoinedAt(String role, String date) {
    return '$role · 加入于 $date';
  }

  @override
  String familySyncConfirmedAt(String role, String date) {
    return '$role · 确认于 $date';
  }

  @override
  String familySyncRemovedAtReason(String reason, String date) {
    return '$reason · $date';
  }

  @override
  String get familySyncRemovalReasonLeft => '主动退出家庭';

  @override
  String get familySyncRemovalReasonRemoved => '被家庭所有者移除';

  @override
  String get familySyncRemovalReasonDissolved => '家庭已解散';

  @override
  String get familySyncRemovalReasonRejected => '申请被拒绝';

  @override
  String get familySyncRemovalReasonCancelled => '申请已取消';

  @override
  String get familySyncRemovalReasonExpired => '申请已过期';

  @override
  String get familySyncRemovalReasonUnknown => '成员关系已结束';

  @override
  String get familyTransactionPayerSelf => '我';
}
