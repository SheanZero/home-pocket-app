# Home Page 整合工作流计划（独立文件）

> 范围声明：本计划只负责把 UI 工作流与数据服务工作流整合为可运行页面；不再新增复杂 UI 组件和底层数据能力；不包含 i18n 改造。

## 1. 目标

完成 Home 页端到端落地：

- `MainShellScreen` 持有全局底部导航 + `IndexedStack`
- `HomeScreen` 作为 Tab 0 内容页接入真实数据 provider
- FAB 与设置等关键交互可触达目标页面

## 2. 依赖前置

- UI 工作流已完成并通过测试。
- 数据服务工作流已完成并通过测试。
- 组件 API 与 provider 契约已冻结（避免整合期频繁改签名）。

## 3. 交付文件

- `lib/features/home/presentation/screens/main_shell_screen.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `test/widget/features/home/presentation/screens/main_shell_screen_test.dart`
- `test/widget/features/home/presentation/screens/home_screen_test.dart`

## 4. 任务拆解

### INT-1 Shell 层整合

- `MainShellScreen` 改为全局壳：
  - `Scaffold`
  - `body: IndexedStack`
  - `bottomNavigationBar: HomeBottomNavBar`
- 使用 `selectedTabIndexProvider` 控制 tab 状态。
- `onFabTap` 跳转 `TransactionFormScreen`。

### INT-2 Home 内容页整合

- `HomeScreen` 仅渲染内容（不持有 bottom nav）。
- 监听：
  - `monthlyReportProvider(bookId, year, month)` 或 `homeDashboardProvider`
  - `todayTransactionsProvider(bookId)`
  - `ohtaniConverterVisibleProvider`
- 将 provider 数据映射到 UI 组件入参（金额、比例、列表、标签）。

### INT-3 交互整合

- 设置按钮：跳转 `SettingsScreen`。
- 日期点击：预留回调（可先弹占位选择器）。
- 切 tab：仅由 shell 改变 index，不在 Home 内部处理路由。

### INT-4 联调与回归

- Widget tests 使用 `ProviderScope(overrides: [...])` 注入稳定 mock 数据。
- 增加至少两类用例：
  - 壳层导航持久化（切 tab 后 bottom nav 仍在）
  - Home 页面真实 provider 渲染（loading/data/empty）

## 5. 验收标准

- 打开应用默认进入 Home（Tab 0）。
- 切换 Tab 1/2/3 时，底部栏始终可见。
- Home 卡片与今日记录来自 provider，而非静态硬编码。
- FAB 点击可进入交易录入页。
- 设置入口可进入设置页。

## 6. 风险与控制

- 风险：UI/API 签名临时变更导致整合反复冲突。  
  控制：整合前冻结 UI 和 provider 契约。
- 风险：测试依赖 `DateTime.now()` 导致不稳定。  
  控制：整合测试统一通过 provider override 固定时间与数据。
- 风险：最终阶段一次性改动过大。  
  控制：按 `INT-1 -> INT-2 -> INT-3 -> INT-4` 分 4 次小提交。

## 7. 建议提交节奏

1. `refactor(home): move global bottom nav to MainShellScreen`
2. `feat(home): wire HomeScreen with monthly and today providers`
3. `feat(home): connect settings/fab navigation from shell and header`
4. `test(home): add shell+home integration widget tests`
5. `chore(home): pass analyze and full test suite`

## 8. 最终验证命令

- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

