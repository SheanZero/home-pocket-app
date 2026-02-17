# Home Page 数据服务工作流计划（独立文件）

> 范围声明：本计划只负责 Home 页数据层编排（provider/use case 接口、数据映射、状态模型），不包含 UI 组件实现与页面导航整合；不包含 i18n。

## 1. 目标

为 Home 页面提供稳定的数据输入接口，使 UI 层只做渲染，不承担查询和聚合逻辑。

## 2. 边界

- 包含：Riverpod providers、参数构建、数据过滤/映射、provider 单元测试。
- 不包含：Widget 视觉实现、`MainShellScreen`/`HomeScreen` 布局组装。
- 依赖来源：复用现有 application 层 use case（analytics/accounting）。

## 3. 交付文件

- `lib/features/home/presentation/providers/home_providers.dart`
- `lib/features/home/presentation/providers/today_transactions_provider.dart`
- `lib/features/home/presentation/providers/home_dashboard_provider.dart`（可选，推荐）

对应测试：

- `test/unit/features/home/presentation/providers/home_providers_test.dart`
- `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart`
- `test/unit/features/home/presentation/providers/home_dashboard_provider_test.dart`（若实现）

## 4. 任务拆解

### DATA-1 页面状态 provider

- `selectedTabIndexProvider`：全局底部导航当前 tab。
- `ohtaniConverterVisibleProvider`：Ohtani 提示条显示状态。
- 只维护页面状态，不读取仓储。

### DATA-2 今日交易 provider（核心）

- 新建 `todayTransactionsProvider(bookId)`。
- 使用 `GetTransactionsUseCase.execute(GetTransactionsParams(...))`，必须传：
  - `bookId`
  - `startDate = 当天 00:00:00`
  - `endDate = 当天 23:59:59`
- 过滤 `isDeleted`，输出 `List<Transaction>`。

### DATA-3 月报聚合 provider（推荐）

- 新建 `homeDashboardProvider(bookId, year, month)`，内部组合：
  - `monthlyReportProvider(...)`
  - `todayTransactionsProvider(bookId: ...)`
- 对外返回单一 ViewModel（例如：`HomeDashboardData`），减少 `HomeScreen` 多 provider 监听复杂度。

## 5. 数据契约（给 UI/整合工作流）

- `todayTransactionsProvider(bookId)` 返回按时间范围过滤后的当日交易列表。
- `selectedTabIndexProvider` 提供 `select(int)`。
- `ohtaniConverterVisibleProvider` 提供 `dismiss()`。
- 若有 `homeDashboardProvider`，需至少包含：
  - `monthlyReport`
  - `todayTransactions`
  - `soulPercentage`
  - `previousMonthNumber`

## 6. 测试重点

- 验证 `GetTransactionsUseCase` 调用参数（尤其是 `GetTransactionsParams`）。
- 验证 deleted 记录不会出现在结果中。
- 验证 provider 在 `success/error/empty` 三种路径输出稳定。
- 验证状态 provider 默认值：
  - `selectedTabIndex == 0`
  - `ohtaniConverterVisible == true`

## 7. 完成标准（DoD）

- 数据 provider 可独立运行，无 widget 依赖。
- 所有 provider 均有单元测试覆盖关键路径。
- 运行通过：
  - `flutter pub run build_runner build --delete-conflicting-outputs`
  - `flutter analyze`
  - `flutter test test/unit/features/home/presentation/providers`

