# UI-001 页面清单 (Page Inventory)

**文档编号:** UI-001
**文档版本:** 1.0
**创建日期:** 2026-02-09
**最后更新:** 2026-02-09
**状态:** 已批准
**作者:** Claude Opus 4.6

---

## 1. 概述

Home Pocket (まもる家計簿) 全部 UI 页面、对话框、共享组件的完整清单。
覆盖所有模块：MOD-001 ~ MOD-009、MOD-014。

**统计:**
- 页面 (Screen/Page): **37**
- 对话框 & BottomSheet: **15**
- 共享组件 (Shared Widget): **8**
- 已实现: **8** / 37 (22%)

---

## 2. 页面清单

### A. 全局导航 (Global Navigation) — 3 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| NAV-01 | **SplashScreen** | `features/home/presentation/screens/splash_screen.dart` | 启动画面：品牌 Logo + 初始化进度（加密密钥加载、数据库连接） | 未实现 |
| NAV-02 | **MainShellScreen** | `features/home/presentation/screens/main_shell_screen.dart` | 底部导航主框架，3 个 Tab：账本 / 分析 / 设置 | ✅ 已实现 |
| NAV-03 | **OnboardingFlow** | `features/onboarding/presentation/screens/onboarding_flow_screen.dart` | 首次启动引导：3 页隐私宣言 (SEC-01) → 密钥生成 → 生物识别设置 | 未实现 |

**导航流:**
```
App Launch
  → SplashScreen (NAV-01)
    → [首次] OnboardingFlow (NAV-03) → MainShellScreen (NAV-02)
    → [非首次] BiometricLockScreen (SEC-02) → MainShellScreen (NAV-02)
```

---

### B. 记账模块 (MOD-001 / MOD-002) — 6 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| ACC-01 | **TransactionListScreen** | `features/accounting/presentation/screens/transaction_list_screen.dart` | 交易列表。分页加载 (50条/页)、滑动删除、按日期分组、余额头部 | ✅ 已实现 |
| ACC-02 | **TransactionFormScreen** | `features/accounting/presentation/screens/transaction_form_screen.dart` | 新增/编辑交易。金额输入、收支切换、分类选择器、日期选择、备注 | ✅ 已实现 |
| ACC-03 | **TransactionDetailScreen** | `features/accounting/presentation/screens/transaction_detail_screen.dart` | 交易详情。完整信息展示、收据照片预览、编辑/删除操作、哈希信息 | 未实现 |
| ACC-04 | **CategoryManagementScreen** | `features/accounting/presentation/screens/category_management_screen.dart` | 分类管理。增删改查自定义分类、图标/颜色选择、排序、使用统计 | 未实现 |
| ACC-05 | **CategoryPickerSheet** | `features/accounting/presentation/widgets/category_picker_sheet.dart` | 三级分类选择器 (BottomSheet)。面包屑导航、搜索、最近使用 | 未实现 |
| ACC-06 | **TransactionSearchScreen** | `features/accounting/presentation/screens/transaction_search_screen.dart` | 高级搜索。多条件筛选：金额范围、日期范围、分类、关键词、账本类型 | 未实现 |

**关键交互:**
- ACC-02 → ACC-05: 点击分类字段弹出三级选择器
- ACC-01 → ACC-03: 点击列表项进入详情
- ACC-03 → ACC-02: 点击编辑进入表单 (编辑模式)
- ACC-01 → ACC-06: 点击搜索图标进入搜索

---

### C. 双轨账本 (MOD-002 / MOD-003) — 3 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| DL-01 | **DualLedgerScreen** | `features/dual_ledger/presentation/screens/dual_ledger_screen.dart` | 双轨视图。Tab 切换 (生存 🛡️ / 灵魂 ✨)、独立余额显示、分类筛选列表 | ✅ 已实现 |
| DL-02 | **SoulAccountConfigScreen** | `features/dual_ledger/presentation/screens/soul_account_config_screen.dart` | 灵魂账户个性化。自定义名称 ("高达基金")、图标 emoji、颜色、月预算 | 未实现 |
| DL-03 | **ClassificationFeedbackDialog** | `features/dual_ledger/presentation/widgets/classification_feedback_dialog.dart` | 分类修正。用户纠正自动分类结果，反馈用于优化 ML 模型 | 未实现 |

**视觉设计:**
- 生存账户：冷静蓝 `#4A90D9`、图标 🏠、超支提示 "⚠️ 本月超支"
- 灵魂账户：活力橙 `#FF8C42`、图标 💖、超支提示 "灵魂太过充实了呢～"

---

### D. OCR 扫描 (MOD-004 / MOD-005) — 3 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| OCR-01 | **OcrScanScreen** | `features/ocr/presentation/screens/ocr_scan_screen.dart` | 扫描入口。两个大按钮：拍照 📷 / 相册 🖼️、光线提示、加载遮罩 | 未实现 |
| OCR-02 | **OcrConfirmationScreen** | `features/ocr/presentation/screens/ocr_confirmation_screen.dart` | 识别结果确认。照片预览、置信度徽章 (%)、可编辑：金额/商家/日期/分类/账本类型、重新扫描/确认按钮 | 未实现 |
| OCR-03 | **ReceiptPhotoViewerScreen** | `features/ocr/presentation/screens/receipt_photo_viewer_screen.dart` | 收据查看。全屏缩放照片、关联交易信息、分享按钮 | 未实现 |

**OCR 流程:**
```
OCR-01 (拍照/选择) → 图像预处理 → OCR 识别 → OCR-02 (确认/编辑) → 保存交易
                                                      ↓
                                                OCR-03 (随时从详情页查看)
```

---

### E. 安全模块 (MOD-005 / MOD-006) — 5 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| SEC-01 | **PrivacyOnboardingScreen** | `features/onboarding/presentation/screens/privacy_onboarding_screen.dart` | 隐私宣言 3 页引导 (PageView)：① 数据仅属于你 ② 防篡改记录 ③ 开源透明 | 未实现 |
| SEC-02 | **BiometricLockScreen** | `features/security/presentation/screens/biometric_lock_screen.dart` | 解锁页。锁图标 + 品牌名、"需要认证" 文案、Face ID/指纹按钮、PIN 备用入口 | 未实现 |
| SEC-03 | **RecoveryKitSetupScreen** | `features/security/presentation/screens/recovery_kit_setup_screen.dart` | 助记词设置。24 词网格展示、复制/导出 PDF、安全存储警告、3 词验证挑战 | 未实现 |
| SEC-04 | **RecoveryKitRestoreScreen** | `features/security/presentation/screens/recovery_kit_restore_screen.dart` | 密钥恢复。24 个输入框逐词输入、自动补全建议、验证反馈 | 未实现 |
| SEC-05 | **HashChainVerificationScreen** | `features/security/presentation/screens/hash_chain_verification_screen.dart` | 哈希链验证。验证结果 (✅完整 / ❌篡改)、交易总数、篡改列表、导出审计报告 PDF | 未实现 |

**安全流程:**
```
首次启动 → SEC-01 (隐私宣言) → SEC-03 (助记词备份) → SEC-02 设置
每次启动 → SEC-02 (生物识别/PIN) → 主页
恢复密钥 → SEC-04 (输入助记词) → 验证 → 重建密钥
设置入口 → SEC-05 (哈希链验证)
```

---

### F. 数据分析 (MOD-006 / MOD-007) — 4 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| ANA-01 | **AnalyticsScreen** | `features/analytics/presentation/screens/analytics_screen.dart` | 月度仪表盘。月选择器、汇总卡片 (收入/支出/余额/储蓄率)、饼图、折线图、分类明细列表 | ✅ 已实现 |
| ANA-02 | **BudgetManagementScreen** | `features/analytics/presentation/screens/budget_management_screen.dart` | 预算管理。按分类设置月预算上限、进度条 (绿/橙/红)、剩余金额、历史达成率 | 未实现 |
| ANA-03 | **DateRangeReportScreen** | `features/analytics/presentation/screens/date_range_report_screen.dart` | 自定义报表。任意日期范围查询、PDF 导出、图表 + 明细表 | 未实现 |
| ANA-04 | **MonthComparisonScreen** | `features/analytics/presentation/screens/month_comparison_screen.dart` | 月度对比。当月 vs 上月并排对比、同比/环比增减、分类级别变化 | 未实现 |

**已实现的分析子组件 (ANA-01 内):**
- SummaryCards — 汇总卡片
- CategoryPieChart — 分类饼图
- CategoryBreakdownList — 分类明细
- LedgerRatioChart — 生存/灵魂比例
- BudgetProgressList — 预算进度
- DailyExpenseChart — 日支出趋势
- ExpenseTrendChart — 月趋势
- MonthComparisonCard — 月对比卡片

---

### G. 设置 (MOD-007 / MOD-008) — 5 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| SET-01 | **SettingsScreen** | `features/settings/presentation/screens/settings_screen.dart` | 设置主页。4 个区块：外观 / 安全 / 数据管理 / 关于 | ✅ 已实现 |
| SET-02 | **BackupExportScreen** | `features/settings/presentation/screens/backup_export_screen.dart` | 导出备份。设置密码 → AES-GCM 加密 → 进度条 → 分享文件 | 未实现 |
| SET-03 | **BackupImportScreen** | `features/settings/presentation/screens/backup_import_screen.dart` | 导入备份。选择文件 → 输入密码 → 验证 → 解密 → 进度条 → 完成 | 未实现 |
| SET-04 | **AboutScreen** | `features/settings/presentation/screens/about_screen.dart` | 关于页面。应用版本、设备信息、隐私协议内容、开源许可列表 | 未实现 |
| SET-05 | **NotificationSettingsScreen** | `features/settings/presentation/screens/notification_settings_screen.dart` | 通知设置。预算警告开关、同步通知开关、提醒时间设置 | 未实现 |

**已实现的设置子组件 (SET-01 内):**
- AppearanceSection — 主题模式选择
- SecuritySection — 生物识别/密码
- DataManagementSection — 备份/导出/清除
- AboutSection — 版本/许可
- PasswordDialog — 密码输入对话框

---

### H. 家庭同步 (MOD-003 / MOD-004) — 5 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| FAM-01 | **FamilyPairingScreen** | `features/family/presentation/screens/family_pairing_screen.dart` | 配对入口。两个选项：发起配对 (生成 QR) / 加入配对 (扫描 QR) | 未实现 |
| FAM-02 | **QrCodeGeneratorScreen** | `features/family/presentation/screens/qr_code_generator_screen.dart` | QR 码生成。展示含公钥 + book_id 的 QR 码、等待对方扫描状态 | 未实现 |
| FAM-03 | **QrCodeScannerScreen** | `features/family/presentation/screens/qr_code_scanner_screen.dart` | QR 码扫描。相机取景框、扫描后显示指纹 (公钥后 4 位) 供电话核对 | 未实现 |
| FAM-04 | **FamilyDashboardScreen** | `features/family/presentation/screens/family_dashboard_screen.dart` | 家庭总览。家庭支出/收入汇总、双方对比卡片、融合交易流、灵魂预算进度 (仅看进度条) | 未实现 |
| FAM-05 | **SyncStatusScreen** | `features/family/presentation/screens/sync_status_screen.dart` | 同步管理。同步状态指示、历史记录列表、手动同步按钮、设备信息 | 未实现 |

**配对流程:**
```
FAM-01 (选择角色)
  ├→ [发起方] FAM-02 (生成 QR) → 等待 → DLG-10 (确认指纹) → 完成
  └→ [加入方] FAM-03 (扫描 QR) → DLG-10 (确认指纹) → 完成
                                                        ↓
                                               FAM-04 (家庭总览)
```

**同步状态图标:**
- 🟢 同步正常 — 数据一致
- 🟡 同步中 — 请等待
- 🔴 同步失败 — 需手动处理
- ⚫ 未配对/离线

---

### I. 趣味功能 (MOD-008 / MOD-009) — 3 页面

| ID | 页面 | 文件路径 | 说明 | 状态 |
|----|------|----------|------|------|
| FUN-01 | **OhtaniConverterSheet** | `features/gamification/presentation/widgets/ohtani_converter_sheet.dart` | 大谷换算 Toast。交易保存后 0.5s 弹出、3s 自动消失、趣味换算文案 (如 "大谷 3 秒的工资") | 未实现 |
| FUN-02 | **OmikujiScreen** | `features/gamification/presentation/screens/omikuji_screen.dart` | 运势占卜。卡片 3D 翻转动画、7 级运势 (大吉～大凶)、撒花特效、个性化解读 | 未实现 |
| FUN-03 | **SoulCelebrationOverlay** | `features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart` | 灵魂庆祝。粒子爆发 + 彩虹光晕 + 正向文案 ("精神资产 +1 💖")、2s 可跳过 | ✅ 已实现 |

**触发条件:**
- FUN-01: 任意交易保存成功 + 设置开启
- FUN-02: 首页入口点击 / OCR 小票触发
- FUN-03: 灵魂账户交易保存成功 + 设置开启

---

## 3. 对话框 & BottomSheet

| ID | 组件 | 类型 | 说明 | 触发位置 |
|----|------|------|------|----------|
| DLG-01 | **ThemeModeDialog** | AlertDialog | 主题选择：系统 / 浅色 / 深色 (Radio) | SET-01 外观区 |
| DLG-02 | **LanguageSelectorDialog** | AlertDialog | 语言选择：日本語 / English / 中文 (Radio) | SET-01 外观区 |
| DLG-03 | **PasswordInputDialog** | AlertDialog | 密码输入 (加密/解密备份用) | SET-02, SET-03 |
| DLG-04 | **DeleteConfirmationDialog** | AlertDialog | 数据全删除二次确认，含 "DELETE" 输入验证 | SET-01 数据管理区 |
| DLG-05 | **MonthPickerDialog** | BottomSheet | 月份选择器 (年+月滚轮) | ANA-01, ANA-04 |
| DLG-06 | **DateRangePickerDialog** | BottomSheet | 日期范围选择 (开始～结束) | ANA-03, ACC-06 |
| DLG-07 | **TransactionDeleteDialog** | AlertDialog | 单笔交易删除确认 | ACC-01 滑动, ACC-03 |
| DLG-08 | **SyncConflictDialog** | AlertDialog | 同步冲突解决：显示双方版本、选择保留哪个 | FAM-05 自动触发 |
| DLG-09 | **FamilyTransferDialog** | BottomSheet | 家庭内部转账：金额输入 → 发送请求 / 确认请求 | FAM-04 |
| DLG-10 | **PairConfirmDialog** | AlertDialog | 配对指纹核对：显示公钥后 4 位，要求电话/当面确认 | FAM-02, FAM-03 |
| DLG-11 | **BudgetAlertDialog** | AlertDialog | 预算预警：80% 提醒 / 100% 超支警告 | 交易保存后自动触发 |
| DLG-12 | **RecoveryWordVerifyDialog** | AlertDialog | 3 词验证挑战：随机选 3 个位置要求用户回填 | SEC-03 |
| DLG-13 | **OcrErrorDialog** | AlertDialog | OCR 识别失败：错误原因 + 重试/手动输入选项 | OCR-01 |
| DLG-14 | **ExportFormatSheet** | BottomSheet | 导出格式选择：PDF / CSV | ANA-01, ANA-03 |
| DLG-15 | **QuickAmountSheet** | BottomSheet | 快速金额面板：常用金额按钮 (¥100/500/1000/5000/10000) | ACC-02 |

---

## 4. 共享组件 (Shared Widgets)

放置于 `lib/shared/widgets/`，跨 feature 复用。

| ID | 组件 | 文件路径 | 说明 | 使用场景 |
|----|------|----------|------|----------|
| SW-01 | **AmountInputWidget** | `shared/widgets/amount_input_widget.dart` | 金额输入：大数字键盘 + 快捷金额按钮 (10/50/100/500) | ACC-02, OCR-02, DLG-09 |
| SW-02 | **LedgerTypeBadge** | `shared/widgets/ledger_type_badge.dart` | 生存/灵魂标识：颜色 + 图标 + 文字 | ACC-01, ACC-03, DL-01 |
| SW-03 | **SyncStatusIndicator** | `shared/widgets/sync_status_indicator.dart` | 同步状态：🟢🟡🔴⚫ 圆点 + 文字 | NAV-02 顶栏, FAM-04, FAM-05 |
| SW-04 | **EmptyStateWidget** | `shared/widgets/empty_state_widget.dart` | 空状态：图标 + 主文案 + 副文案 + 操作按钮 | 全部列表页面 |
| SW-05 | **LoadingOverlayWidget** | `shared/widgets/loading_overlay_widget.dart` | 加载遮罩：半透明背景 + 圆形进度 + 文案 | OCR-01, SET-02, SET-03 |
| SW-06 | **ErrorRetryWidget** | `shared/widgets/error_retry_widget.dart` | 错误重试：错误图标 + 消息 + 重试按钮 | 全部异步加载页面 |
| SW-07 | **ConfidenceBadge** | `shared/widgets/confidence_badge.dart` | 置信度百分比：颜色渐变徽章 (红<60% / 橙60-80% / 绿>80%) | OCR-02 |
| SW-08 | **AnimatedCounter** | `shared/widgets/animated_counter.dart` | 数字滚动动画：金额变动时 countUp 效果 | ANA-01, FAM-04, DL-01 |

---

## 5. 导航关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                         App Launch                               │
│                            ↓                                     │
│                      NAV-01 Splash                               │
│                       ↙        ↘                                │
│              [首次启动]        [非首次]                           │
│                 ↓                 ↓                               │
│         NAV-03 Onboarding   SEC-02 BiometricLock                │
│           ↓                      ↓                               │
│    SEC-01 Privacy → SEC-03 RecoveryKit                          │
│                            ↓                                     │
│                    ┌───────────────────┐                        │
│                    │  NAV-02 MainShell │                        │
│                    │  ┌─────┬─────┬─────┐                      │
│                    │  │Tab1 │Tab2 │Tab3 │                      │
│                    │  │账本 │分析 │设置 │                      │
│                    └──┴─────┴─────┴─────┘                      │
│                       │      │      │                           │
│           ┌───────────┘      │      └──────────┐               │
│           ↓                  ↓                  ↓               │
│     DL-01 DualLedger   ANA-01 Analytics   SET-01 Settings      │
│       ↓                  ↓                  ↓                   │
│     ACC-01 List        ANA-02 Budget      SET-02 Backup        │
│       ↓                ANA-03 Report      SET-03 Import        │
│     ACC-02 Form        ANA-04 Compare     SET-04 About         │
│     ACC-03 Detail                         SET-05 Notification  │
│     ACC-04 Category                       SEC-05 HashChain     │
│     ACC-05 Picker                         FAM-01 Pairing       │
│     ACC-06 Search                           ↓                   │
│       ↓                                FAM-02/03 QR            │
│   OCR-01 Scan                           FAM-04 Dashboard       │
│   OCR-02 Confirm                        FAM-05 SyncStatus      │
│   OCR-03 Photo                                                  │
│                                                                  │
│   [Overlay] FUN-01 Ohtani | FUN-03 SoulCelebration             │
│   [独立页] FUN-02 Omikuji | DL-02 SoulConfig                   │
│   [独立页] SEC-04 RecoveryRestore                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. 开发优先级

按项目开发计划 (Phase 1-4) 排列实现顺序。

### Phase 1: 基础设施 (Week 1-2)
| 优先级 | 页面 | 说明 |
|--------|------|------|
| P0 | NAV-01 SplashScreen | 启动流程入口 |
| P0 | SEC-01 PrivacyOnboardingScreen | 首次启动必需 |
| P0 | SEC-02 BiometricLockScreen | 每次启动必需 |
| P0 | SEC-03 RecoveryKitSetupScreen | 密钥备份必需 |
| P0 | NAV-03 OnboardingFlow | 串联首次启动流程 |

### Phase 2: 核心记账 (Week 3-5)
| 优先级 | 页面 | 说明 |
|--------|------|------|
| P0 | ACC-03 TransactionDetailScreen | 查看交易完整信息 |
| P0 | ACC-04 CategoryManagementScreen | 自定义分类 |
| P0 | ACC-05 CategoryPickerSheet | 改进分类选择体验 |
| P1 | ACC-06 TransactionSearchScreen | 搜索筛选 |
| P0 | DL-02 SoulAccountConfigScreen | 灵魂账户个性化 |
| P1 | DL-03 ClassificationFeedbackDialog | ML 反馈 |
| P0 | ANA-02 BudgetManagementScreen | 预算设置 |

### Phase 3: 同步 & 分析 (Week 6-9)
| 优先级 | 页面 | 说明 |
|--------|------|------|
| P0 | FAM-01 FamilyPairingScreen | 家庭配对入口 |
| P0 | FAM-02 QrCodeGeneratorScreen | QR 码生成 |
| P0 | FAM-03 QrCodeScannerScreen | QR 码扫描 |
| P0 | FAM-04 FamilyDashboardScreen | 家庭总览 |
| P1 | FAM-05 SyncStatusScreen | 同步管理 |
| P1 | ANA-03 DateRangeReportScreen | 自定义报表 |
| P1 | ANA-04 MonthComparisonScreen | 月度对比 |
| P0 | SET-02 BackupExportScreen | 数据备份 |
| P0 | SET-03 BackupImportScreen | 数据恢复 |
| P1 | SET-04 AboutScreen | 关于页 |
| P2 | SET-05 NotificationSettingsScreen | 通知设置 |

### Phase 4: 增强功能 (Week 10-12)
| 优先级 | 页面 | 说明 |
|--------|------|------|
| P1 | OCR-01 OcrScanScreen | 扫描入口 |
| P1 | OCR-02 OcrConfirmationScreen | OCR 确认 |
| P1 | OCR-03 ReceiptPhotoViewerScreen | 收据查看 |
| P1 | SEC-04 RecoveryKitRestoreScreen | 密钥恢复 |
| P1 | SEC-05 HashChainVerificationScreen | 审计验证 |
| P2 | FUN-01 OhtaniConverterSheet | 大谷换算 (A/B) |
| P2 | FUN-02 OmikujiScreen | 运势占卜 (A/B) |

---

## 7. 实现状态汇总

| 模块 | 总页面 | 已实现 | 完成率 |
|------|--------|--------|--------|
| 全局导航 | 3 | 1 | 33% |
| 记账 MOD-001/002 | 6 | 2 | 33% |
| 双轨账本 MOD-002/003 | 3 | 1 | 33% |
| OCR MOD-004/005 | 3 | 0 | 0% |
| 安全 MOD-005/006 | 5 | 0 | 0% |
| 分析 MOD-006/007 | 4 | 1 | 25% |
| 设置 MOD-007/008 | 5 | 1 | 20% |
| 家庭同步 MOD-003/004 | 5 | 0 | 0% |
| 趣味功能 MOD-008/009 | 3 | 1 | 33% |
| **合计** | **37** | **7** | **19%** |

**已实现页面清单:**
1. ✅ NAV-02 MainShellScreen
2. ✅ ACC-01 TransactionListScreen
3. ✅ ACC-02 TransactionFormScreen
4. ✅ DL-01 DualLedgerScreen
5. ✅ ANA-01 AnalyticsScreen
6. ✅ SET-01 SettingsScreen
7. ✅ FUN-03 SoulCelebrationOverlay

---

## 8. 双主题系统

所有页面须同时支持两套主题：

| 属性 | 和风治愈系 (Warm Japanese) | 赛博可爱风 (Cyber Kawaii) |
|------|---------------------------|--------------------------|
| 适用 | 生存账户、设置、家庭模式 | 灵魂账户、趣味功能、成就 |
| 背景 | 暖米色 | 深空紫 |
| 主色 | 深棕木色 | 霓虹粉 |
| 警示 | 朱红 | 电子蓝 |
| 字体 | Noto Serif JP (标题) + Noto Sans JP (正文) | M PLUS Rounded 1c |
| 圆角 | 16px、柔和阴影 | 8px、霓虹发光、渐变边框 |
| 动效 | 淡入淡出、弹性回弹 | 粒子爆发、像素展开、光晕 |

---

## 9. 参考文档

- [ARCH-001 Complete Guide](../01-core-architecture/ARCH-001_Complete_Guide.md)
- [ARCH-004 State Management](../01-core-architecture/ARCH-004_State_Management.md)
- [MOD-001 BasicAccounting](../02-module-specs/MOD-001_BasicAccounting.md)
- [MOD-002 DualLedger](../02-module-specs/MOD-002_DualLedger.md)
- [MOD-004 OCR](../02-module-specs/MOD-004_OCR.md)
- [MOD-005 Security](../02-module-specs/MOD-005_Security.md)
- [MOD-006 Analytics](../02-module-specs/MOD-006_Analytics.md)
- [MOD-007 Settings](../02-module-specs/MOD-007_Settings.md)
- [MOD-008 Gamification](../02-module-specs/MOD-008_Gamification.md)
- [MOD-014 i18n](../02-module-specs/MOD-014_i18n.md)
- [PRD_MVP_App](../../requirement/PRD_MVP_App.md)
- [PRD_MVP_Global](../../requirement/PRD_MVP_Global.md)

---

**创建时间:** 2026-02-09
**作者:** Claude Opus 4.6
