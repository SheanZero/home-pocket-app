# Home Page UI 工作流计划（独立文件）

> 范围声明：本计划只负责 UI 组件与视觉实现，不包含 i18n、数据拉取、业务 provider、页面路由整合。

## 1. 目标

交付 Home 页面全部视觉层组件，确保可以用静态 mock 数据完整渲染设计稿结构，并具备可复用的组件 API。

## 2. 边界

- 包含：`theme`、`widgets`、纯渲染逻辑、UI 层 widget tests。
- 不包含：`todayTransactionsProvider`、`monthlyReportProvider` 接入、`MainShellScreen` 导航逻辑。
- 输入数据：通过构造参数注入（`int/String/enum/callback`），不直接依赖 Riverpod。

## 3. 交付文件

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/features/home/presentation/widgets/hero_header.dart`
- `lib/features/home/presentation/widgets/month_overview_card.dart`
- `lib/features/home/presentation/widgets/soul_fullness_card.dart`
- `lib/features/home/presentation/widgets/family_invite_banner.dart`
- `lib/features/home/presentation/widgets/home_transaction_tile.dart`
- `lib/features/home/presentation/widgets/ohtani_converter.dart`
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart`

对应测试：

- `test/unit/core/theme/*`
- `test/widget/features/home/presentation/widgets/*`

## 4. 任务拆解

### UI-1 Theme 基础

- 建立 Home 页专用色板与文本样式（与现有项目主题兼容）。
- 在 `app_theme.dart` 提供可直接在 `MaterialApp` 使用的 `light/dark`。
- 验证：颜色常量、字号/字重、`useMaterial3`、`scaffoldBackgroundColor`。

### UI-2 基础组件

- `HeroHeader`：顶部蓝色区域 + 月份显示 + 设置按钮回调。
- `HomeBottomNavBar`：4 tab + FAB（仅视觉与回调，不负责切页）。
- `FamilyInviteBanner`：信息卡 + 点击回调。

### UI-3 业务展示组件

- `MonthOverviewCard`：总支出、生存/灵魂分解、先月比条形图。
- `SoulFullnessCard`：灵魂占比、ROI、充盈度进度条、最近消费展示。
- `HomeTransactionTile`：图标、商户名、标签、金额（建议入参使用 `formattedAmount`）。
- `OhtaniConverter`：底部趣味提示条 + 关闭回调。

## 5. 组件契约（供整合工作流使用）

- `HeroHeader(year, month, onSettingsTap, onDateTap)`
- `MonthOverviewCard(totalExpense, survivalExpense, soulExpense, previousMonthTotal, currentMonthNumber, previousMonthNumber, modeBadgeText)`
- `SoulFullnessCard(soulPercentage, happinessROI, fullnessLevel, recentMerchant, recentAmount, recentQuote)`
- `FamilyInviteBanner(onTap)`
- `HomeTransactionTile(merchant, categoryLabel, formattedAmount, ledgerType, iconData, {onTap})`
- `OhtaniConverter(emoji, text, onDismiss)`
- `HomeBottomNavBar(currentIndex, onTap, onFabTap)`

## 6. 完成标准（DoD）

- 所有 UI 组件可在 `Scaffold` 下独立渲染并通过测试。
- 组件无 provider 读取、副作用、导航跳转。
- 运行通过：
  - `dart format .`
  - `flutter analyze`
  - `flutter test test/unit/core/theme`
  - `flutter test test/widget/features/home/presentation/widgets`

