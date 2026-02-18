# Presentation Layer (页面层)

> Screens, Widgets, Providers, Navigation, Theme

---

## 目录

- [1. 主题系统](#1-主题系统)
- [2. 页面总览](#2-页面总览)
- [3. Home 功能模块](#3-home-功能模块)
- [4. Accounting 功能模块](#4-accounting-功能模块)
- [5. Analytics 功能模块](#5-analytics-功能模块)
- [6. Settings 功能模块](#6-settings-功能模块)
- [7. Dual Ledger 功能模块](#7-dual-ledger-功能模块)
- [8. Providers 总览](#8-providers-总览)
- [9. 导航架构](#9-导航架构)
- [10. 状态管理模式](#10-状态管理模式)

---

## 1. 主题系统

### 1.1 颜色系统 (`lib/core/theme/app_colors.dart`)

| 类别 | 名称 | 色值 | 用途 |
|------|------|------|------|
| 品牌色 | `primary` | `#8AB8DA` | 天蓝色主色调 |
| 生存账本 | `survival` | `#5A9CC8` | 蓝色系 |
| 灵魂账本 | `soul` | `#47B88A` | 绿色系 |
| 背景 | `background` | `#F1F7FD` | 页面背景 |
| 卡片 | `card` | `#FFFFFF` | 卡片背景 |
| 文字主色 | `textPrimary` | `#2C2C2C` | 主要文字 |
| 文字次色 | `textSecondary` | `#9A9A9A` | 次要文字 |

另有灵魂账本专属色系（浅底、卡片背景、进度条、徽章等）、月度对比色系、FAB 渐变色等。

### 1.2 字体系统 (`lib/core/theme/app_text_styles.dart`)

字体族：IBM Plex Sans

| 样式 | 尺寸 | 粗细 | 用途 |
|------|------|------|------|
| `headlineLarge` | 24px | w600 | 大标题 |
| `headlineMedium` | 18px | w600 | 中标题 |
| `titleLarge` | 16px | w700 | 大标题行 |
| `titleMedium` | 14px | w600 | 中标题行 |
| `titleSmall` | 13px | normal | 小标题 |
| `bodyMedium` | 14px | w500 | 正文 |
| `bodySmall` | 12px | normal | 小正文 |
| `labelMedium` | 12px | w600 | 标签 |
| `labelSmall` | 10px | w500 | 小标签 |
| **`amountLarge`** | 24px | w600 | 金额大号（等宽数字） |
| **`amountMedium`** | 14px | w600 | 金额中号（等宽数字） |
| **`amountSmall`** | 10px | w500 | 金额小号（等宽数字） |

**金额样式特别说明**：所有 `amount*` 样式使用 `FontFeature.tabularFigures()` 确保数字等宽对齐。

### 1.3 主题配置 (`lib/core/theme/app_theme.dart`)

- Material 3 Light 主题
- 基于 `AppColors.primary` 的 ColorScheme
- 自定义 AppBar、Card 主题样式

---

## 2. 页面总览

```
MainShellScreen (根导航容器)
├── Tab 0: HomeScreen (首页仪表盘)
├── Tab 1: Placeholder (列表页，待开发)
├── Tab 2: AnalyticsScreen (分析页)
├── Tab 3: Placeholder (待办页，待开发)
├── FAB → TransactionEntryScreen (记账入口)
└── Settings → SettingsScreen (设置页)

TransactionEntryScreen (记账流程)
├── Manual → SmartKeyboard → CategorySelectionScreen → TransactionConfirmScreen
├── OCR → OcrScannerScreen (桩)
└── Voice → VoiceInputScreen (桩)

DualLedgerScreen (双账本对比，从 Tab 1 或其他入口)
└── Tab: Survival / Soul → TransactionListScreen (带 ledgerType 过滤)
```

---

## 3. Home 功能模块

### 3.1 MainShellScreen

**文件**: `lib/features/home/presentation/screens/main_shell_screen.dart`

**功能**: 根级导航容器，4 个 Tab + FAB

**核心实现**:
- `IndexedStack` 保持 4 个 Tab 页面状态
- 自定义 `HomeBottomNavBar` 底部导航栏（含悬浮 FAB）
- FAB 跳转至 `TransactionEntryScreen`，返回后刷新 Provider 数据
- Tab 状态由 `selectedTabIndexProvider` (keepAlive) 管理

**Provider 依赖**:
- `selectedTabIndexProvider` — 当前 Tab 索引
- `monthlyReportProvider` — 月报数据（刷新用）
- `todayTransactionsProvider` — 今日交易（刷新用）

### 3.2 HomeScreen

**文件**: `lib/features/home/presentation/screens/home_screen.dart`

**功能**: 首页仪表盘，月度概览 + 今日交易 + 灵魂指标

**页面结构**:

```
Stack (Hero 区域)
├── 蓝色背景容器 (高度 = 屏幕宽度)
└── Column
    ├── HeroHeader (月份选择器 + 设置按钮)
    ├── MonthOverviewCard (月度总览，与蓝色区域重叠)
    │   └── SoulFullnessCard (灵魂充盈度)
    ├── FamilyInviteBanner (家庭同步邀请，桩)
    ├── Today's Transactions Section
    │   ├── 标题 + 笔数
    │   └── HomeTransactionTile × N
    └── OhtaniConverter (大谷翔平转换器，可关闭)
```

**关键数据**:
- 月报: `monthlyReportProvider(bookId, year, month)` — 总收支、生存/灵魂分布
- 今日交易: `todayTransactionsProvider(bookId)` — 过滤当天记录
- 灵魂指标: 由月报数据计算灵魂百分比、幸福 ROI

**格式化**:
- 金额: `NumberFormatter.formatCurrency(amount, 'JPY', locale)`
- 日期: `DateFormatter.formatDate(timestamp, locale)`

### 3.3 Home Widgets

#### HeroHeader (`widgets/hero_header.dart`)
- 蓝色背景顶部区域
- 月份显示（带下拉箭头）+ 设置图标
- 纯 UI 组件，无 Provider 依赖

#### MonthOverviewCard (`widgets/month_overview_card.dart`)
- 总支出（`amountLarge` 样式）
- 生存/灵魂分项显示
- 月度对比：当前 vs 上月柱状图（生存蓝 + 灵魂绿段）
- 图例说明

#### SoulFullnessCard (`widgets/soul_fullness_card.dart`)
- 灵魂充盈度百分比 + 幸福 ROI
- 电池充电动画（绿色进度条）
- 最近灵魂交易展示（商户、金额、备注引用）

#### HomeTransactionTile (`widgets/home_transaction_tile.dart`)
- 单条交易行：图标 + 商户/分类 + 金额
- 灵魂交易分类名显示为绿色

#### HomeBottomNavBar (`widgets/home_bottom_nav_bar.dart`)
- 4 Tab 自定义底部导航（首页/列表/图表/待办）
- 右侧悬浮 FAB（渐变蓝色，编辑图标）

#### FamilyInviteBanner (`widgets/family_invite_banner.dart`)
- 家庭同步邀请横幅（桩功能）

#### OhtaniConverter (`widgets/ohtani_converter.dart`)
- 消费转换为食物的趣味显示
- 深蓝色背景，可关闭

---

## 4. Accounting 功能模块

### 4.1 TransactionEntryScreen (主记账入口)

**文件**: `lib/features/accounting/presentation/screens/transaction_entry_screen.dart`

**功能**: 5 屏记账流程入口，支持手动/OCR/语音三种输入模式

**页面结构**:
```
Scaffold
├── InputModeTabs (手动 / OCR / 语音)
├── AmountDisplay (格式化金额 + 货币徽章 + 清除按钮)
├── SelectorChip × 2 (日期选择器, 分类选择器)
└── SmartKeyboard (4×4 自定义数字键盘)
```

**状态管理**:
- `_amount: String` — 原始数字字符串（最多 7 位）
- `_selectedCategory: Category?` — 已选分类
- `_selectedDate: DateTime` — 日期（默认今天）

**导航**:
- Next → `CategorySelectionScreen` (如未选分类)
- Next → `TransactionConfirmScreen` (如已选分类)
- OCR Tab → `OcrScannerScreen`
- Voice Tab → `VoiceInputScreen`

### 4.2 CategorySelectionScreen (分类选择)

**文件**: `lib/features/accounting/presentation/screens/category_selection_screen.dart`

**功能**: 全屏分层分类选择器（L1 父分类 + L2 子分类）

**核心逻辑**:
- 从 Repository 加载所有分类，按 `parentId` 分组
- L1 展开时显示 L2 子项 Chips
- 搜索支持 L1 和 L2（本地化名称匹配）
- 自动展开已选中分类的父级
- 50+ 图标映射（`_resolveIcon()`）

### 4.3 TransactionConfirmScreen (确认页)

**文件**: `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`

**功能**: 保存前最终确认，可编辑商户/备注 + 账本类型选择

**页面结构**:
```
SingleChildScrollView
├── 详情卡片
│   ├── 金额行 (NumberFormatter 格式化)
│   ├── 分类行 (图标 + 颜色 + 名称)
│   ├── 日期行 (DateFormatter 格式化)
│   ├── 商户行 (可编辑 TextField)
│   └── 备注区 (3 行 TextArea)
├── 账本选择卡片
│   ├── LedgerTypeSelector (生存/灵魂切换)
│   └── SoulSatisfactionSlider (灵魂满意度 1-10, 仅灵魂账本)
├── 添加照片按钮 (桩)
└── 记录按钮 (渐变蓝)
```

**保存流程**:
1. 创建 `CreateTransactionParams`
2. 调用 `createTransactionUseCase.execute()`
3. 灵魂交易显示 `SoulCelebrationOverlay`
4. Pop 返回 Shell

### 4.4 Accounting Widgets

#### SmartKeyboard (`widgets/smart_keyboard.dart`)
- 4×3 数字键盘 + 底部操作行（删除/0/下一步）
- 下一步按钮渐变蓝色

#### AmountDisplay (`widgets/amount_display.dart`)
- 货币徽章（¥ JPY + 下拉图标）
- 格式化金额显示（千位分隔符）
- 清除按钮

#### InputModeTabs (`widgets/input_mode_tabs.dart`)
- 手动/OCR/语音三选一
- 带图标和标签，200ms 动画切换

#### LedgerTypeSelector (`widgets/ledger_type_selector.dart`)
- 生存/灵魂两个 Chip 切换
- 生存: 盾牌图标 + 蓝色；灵魂: 星光图标 + 绿色

#### SoulSatisfactionSlider (`widgets/soul_satisfaction_slider.dart`)
- 10 段满意度选择器（1-10）
- 10 色绿色渐变

#### TransactionListTile (`widgets/transaction_list_tile.dart`)
- 单行交易显示 + 左滑删除（Dismissible）

### 4.5 桩页面

#### OcrScannerScreen (`screens/ocr_scanner_screen.dart`)
- 深色相机 UI 风格
- 取景框 + 状态提示 + 快门/闪光/相册按钮
- **未实现实际 OCR 功能**

#### VoiceInputScreen (`screens/voice_input_screen.dart`)
- 麦克风按钮 + 波形动画（12 根柱状条）
- 录音脉冲动画（AnimationController, 1.2s 循环）
- **未实现实际语音识别功能**

### 4.6 TransactionFormScreen (简易表单，旧版)

**文件**: `lib/features/accounting/presentation/screens/transaction_form_screen.dart`

- 基础记账表单：金额 + 类型 + 分类 + 备注
- 使用 SegmentedButton 切换支出/收入
- ChoiceChips 分类选择
- **旧版路径，主流程使用 TransactionEntryScreen**

---

## 5. Analytics 功能模块

### 5.1 AnalyticsScreen

**文件**: `lib/features/analytics/presentation/screens/analytics_screen.dart`

**功能**: 综合财务分析仪表盘，8 个子组件

**页面结构**:
```
Scaffold
├── AppBar (← 月份名称 →, demo 数据按钮)
└── RefreshIndicator → SingleChildScrollView
    ├── 1. SummaryCards (2×2 收支/储蓄/储蓄率)
    ├── 2. CategoryPieChart (Top 7 分类饼图)
    ├── 3. DailyExpenseChart (每日支出柱状图)
    ├── 4. LedgerRatioChart (生存/灵魂占比)
    ├── 5. BudgetProgressList (预算进度, 桩)
    ├── 6. ExpenseTrendChart (6 月趋势线图)
    ├── 7. CategoryBreakdownList (分类明细列表)
    └── 8. MonthComparisonCard (月度同比)
```

**Provider 依赖**:
- `selectedMonthProvider` — 当前选中月份
- `monthlyReportProvider(bookId, year, month)` — 月报主数据
- `budgetProgressProvider(bookId, year, month)` — 预算数据
- `expenseTrendProvider(bookId)` — 趋势数据

**Demo 数据**:
- 按钮触发 `DemoDataService.generateDemoData()` 生成模拟交易

### 5.2 Analytics Widgets

| Widget | 文件 | 功能 | 状态 |
|--------|------|------|------|
| `SummaryCards` | `summary_cards.dart` | 2×2 收入/支出/储蓄/储蓄率 | 完整实现 |
| `CategoryPieChart` | `category_pie_chart.dart` | Top 7 分类饼图 (fl_chart) | 完整实现 |
| `DailyExpenseChart` | `daily_expense_chart.dart` | 每日支出柱状图 | 桩 |
| `LedgerRatioChart` | `ledger_ratio_chart.dart` | 生存/灵魂占比图 | 桩 |
| `BudgetProgressList` | `budget_progress_list.dart` | 预算进度列表 | 桩 |
| `ExpenseTrendChart` | `expense_trend_chart.dart` | 6 月趋势线图 | 桩 |
| `CategoryBreakdownList` | `category_breakdown_list.dart` | 分类明细表 | 桩 |
| `MonthComparisonCard` | `month_comparison_card.dart` | 月度同比卡片 | 桩 |

---

## 6. Settings 功能模块

### 6.1 SettingsScreen

**文件**: `lib/features/settings/presentation/screens/settings_screen.dart`

**功能**: 应用设置（外观/数据/安全/关于）

**子组件**:
| Section | 文件 | 功能 | 状态 |
|---------|------|------|------|
| `AppearanceSection` | `appearance_section.dart` | 主题模式选择（系统/浅色/深色） | 完整实现 |
| `DataManagementSection` | `data_management_section.dart` | 备份导出/导入 | 桩 |
| `SecuritySection` | `security_section.dart` | 密码/生物识别/审计日志 | 桩 |
| `AboutSection` | `about_section.dart` | 版本/致谢 | 桩 |

---

## 7. Dual Ledger 功能模块

### 7.1 DualLedgerScreen

**文件**: `lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart`

**功能**: 生存/灵魂双账本对比视图

- `DefaultTabController` 2 个 Tab（生存/灵魂）
- 每个 Tab 显示过滤后的 `TransactionListScreen`
- 使用 `ValueKey` 强制 Tab 切换时重建列表

### 7.2 SoulCelebrationOverlay

**文件**: `lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart`

**功能**: 灵魂交易保存成功庆祝动画

- 紫色渐变全屏覆盖
- 7 个星光图标随机分布 + 缩放动画
- 中央 "Soul!" 文字 + 缩放/透明度动画
- 1.5 秒后自动消失

---

## 8. Providers 总览

### 8.1 Repository Providers (单一数据源)

**文件**: `lib/features/accounting/presentation/providers/repository_providers.dart`

```
bookRepositoryProvider         → BookRepositoryImpl(BookDao)
categoryRepositoryProvider     → CategoryRepositoryImpl(CategoryDao)
categoryLedgerConfigProvider   → CategoryLedgerConfigRepositoryImpl(dao)
transactionRepositoryProvider  → TransactionRepositoryImpl(dao, encryptionService)
deviceIdentityRepositoryProvider → DeviceIdentityRepositoryImpl(keyManager)
```

### 8.2 Use Case Providers

**文件**: `lib/features/accounting/presentation/providers/use_case_providers.dart`

```
createTransactionUseCaseProvider  → 依赖 5 个 Provider
getTransactionsUseCaseProvider    → 依赖 transactionRepository
deleteTransactionUseCaseProvider  → 依赖 transactionRepository
seedCategoriesUseCaseProvider     → 依赖 category + ledgerConfig repos
resolveLedgerTypeServiceProvider  → 依赖 category + ledgerConfig repos
ensureDefaultBookUseCaseProvider  → 依赖 book + deviceIdentity repos
```

### 8.3 状态 Providers

| Provider | 类型 | keepAlive | 用途 |
|----------|------|-----------|------|
| `selectedTabIndexProvider` | Notifier\<int\> | Yes | 底部 Tab 索引 |
| `ohtaniConverterVisibleProvider` | Notifier\<bool\> | Yes | 转换器可见性 |
| `selectedMonthProvider` | Notifier\<DateTime\> | No | 分析月份选择 |
| `ledgerViewProvider` | Notifier\<LedgerType\> | Yes | 当前账本视图 |
| `localeNotifierProvider` | Notifier\<LocaleSettings\> | No | 语言设置 |
| `currentLocaleProvider` | Provider\<Locale\> | No | 当前语言（便捷） |

### 8.4 异步数据 Providers

| Provider | 参数 | 返回类型 |
|----------|------|----------|
| `todayTransactionsProvider` | bookId | `Future<List<Transaction>>` |
| `monthlyReportProvider` | bookId, year, month | `Future<MonthlyReport>` |
| `budgetProgressProvider` | bookId, year, month | `Future<List<BudgetProgress>>` |
| `expenseTrendProvider` | bookId | `Future<ExpenseTrendData>` |
| `appSettingsProvider` | — | `Future<AppSettings>` |

---

## 9. 导航架构

### 9.1 底部 Tab 导航

```
MainShellScreen
├── IndexedStack (保持页面状态)
│   ├── [0] HomeScreen
│   ├── [1] Placeholder
│   ├── [2] AnalyticsScreen
│   └── [3] Placeholder
└── HomeBottomNavBar + FAB
```

### 9.2 记账流程导航

```
FAB → TransactionEntryScreen
       ├── Next → CategorySelectionScreen → pop(category)
       └── Next → TransactionConfirmScreen → save → pop(true) → MainShell
```

### 9.3 模态导航

```
HomeScreen
├── Settings 图标 → MaterialPageRoute → SettingsScreen
└── 交易 Tile → (未实现详情页)

AnalyticsScreen
└── Demo 按钮 → 对话框 → 生成数据 → 刷新
```

---

## 10. 状态管理模式

### 10.1 keepAlive Providers

```dart
@Riverpod(keepAlive: true)
class SelectedTabIndex extends _$SelectedTabIndex {
  @override
  int build() => 0;
  void select(int index) => state = index;
}
```

跨导航持久化，用户切换页面不会丢失状态。

### 10.2 异步数据加载

```dart
monthlyReportProvider.when(
  data: (report) => buildContent(report),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => ErrorWidget(e),
)
```

### 10.3 手动刷新

```dart
// 保存交易后刷新数据
ref.invalidate(monthlyReportProvider(bookId, year, month));
ref.invalidate(todayTransactionsProvider(bookId));
```

### 10.4 Repository 单一数据源

所有 Use Case Provider 通过 `ref.watch(xxxRepositoryProvider)` 引用，确保同一 Repository 实例。

---

## 文件清单

### Screens (11 个)

| 文件 | 功能 | 状态 |
|------|------|------|
| `home/screens/main_shell_screen.dart` | 根导航容器 | 完整 |
| `home/screens/home_screen.dart` | 首页仪表盘 | 完整 |
| `accounting/screens/transaction_entry_screen.dart` | 记账入口 | 完整 |
| `accounting/screens/category_selection_screen.dart` | 分类选择 | 完整 |
| `accounting/screens/transaction_confirm_screen.dart` | 确认页 | 完整 |
| `accounting/screens/transaction_form_screen.dart` | 简易表单（旧版） | 完整 |
| `accounting/screens/transaction_list_screen.dart` | 交易列表 | 完整 |
| `accounting/screens/ocr_scanner_screen.dart` | OCR 扫描 | 桩 |
| `accounting/screens/voice_input_screen.dart` | 语音输入 | 桩 |
| `analytics/screens/analytics_screen.dart` | 分析仪表盘 | 完整 |
| `settings/screens/settings_screen.dart` | 设置页 | 部分完整 |

### Widgets (20+ 个)

| 分类 | 数量 | 关键组件 |
|------|------|----------|
| Home | 7 | HeroHeader, MonthOverviewCard, SoulFullnessCard, HomeTransactionTile, HomeBottomNavBar, FamilyInviteBanner, OhtaniConverter |
| Accounting | 6 | SmartKeyboard, AmountDisplay, InputModeTabs, LedgerTypeSelector, SoulSatisfactionSlider, TransactionListTile |
| Analytics | 8 | SummaryCards, CategoryPieChart, DailyExpenseChart, LedgerRatioChart, BudgetProgressList, ExpenseTrendChart, CategoryBreakdownList, MonthComparisonCard |
| Settings | 5 | AppearanceSection, SecuritySection, DataManagementSection, AboutSection, PasswordDialog |
| Dual Ledger | 1 | SoulCelebrationOverlay |

### Providers (30+ 个)

| 分类 | 数量 | 关键 Provider |
|------|------|--------------|
| Repository | 5 | book, category, categoryLedgerConfig, transaction, deviceIdentity |
| Use Case | 6 | create/get/delete transaction, seedCategories, resolveLedgerType, ensureDefaultBook |
| State | 5 | selectedTabIndex, ohtaniConverterVisible, selectedMonth, ledgerView, locale |
| Async Data | 5 | todayTransactions, monthlyReport, budgetProgress, expenseTrend, appSettings |
| Analytics Repo | 1 | analyticsRepository |

---

*最后更新: 2026-02-18*
