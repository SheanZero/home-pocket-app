# Phase 27: Calendar Header + Month Summary - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的 **日历头部 widget**：一个可独立测试的 calendar header，挂在 List tab 顶部、列表（Phase 28/29）之上。本 phase 交付四件事，全部可在 widget 隔离下观察：

1. **月份导航**（CAL-01 / SC#1）—— prev/next chevron + 横向 swipe 切月；切月后日历网格重渲染、月份标签更新（如 ja `2026年5月`）。
2. **每日支出网格**（CAL-02 / SC#2）—— `table_calendar` 月网格，每个有支出的日单元格显示当天**仅支出**合计；无支出的日不显示金额。**v1.4 own-book only**。
3. **点日过滤**（CAL-03 / SC#3）—— 点某日 → 过滤列表到当天 + 该日高亮；再点同一日 → 清除日过滤、回到整月。接 Phase 26 已建的 `ListFilter.selectDay(DateTime?)`。
4. **月度摘要行**（CAL-04 / SC#4）—— 日历下方一行显示当月**仅支出**总额，`NumberFormatter` + `AppTextStyles.amountSmall`（tabular figures），排除收入。

**依赖包**：`table_calendar: ^3.2.0` 加入 `pubspec.yaml`（SC#5：`flutter build ios --debug --no-codesign` 必须通过，`intl: 0.20.2` pin 不可破）。

**已经满足 / 既成事实（不重复建）：**
- ✅ `ListFilter` Notifier（`listFilterProvider`，keepAlive:true）+ `selectMonth(year,month)` / `selectDay(DateTime?)` / `clearAll()` mutator 已在 `lib/features/list/presentation/providers/state_list_filter.dart`（Phase 26）。日历**接线进这些 mutator**，不新建 filter state。
- ✅ `ListFilterState`（含 `selectedYear`/`selectedMonth`/`activeDayFilter`）已建（Phase 25）。
- ✅ `AnalyticsRepository.getDailyTotals(bookId, startDate, endDate, type='expense')` 已存在（`lib/data/daos/analytics_dao.dart:226` + `lib/data/repositories/analytics_repository_impl.dart:68`）—— 已是 expense-only、`DATE(...,'localtime') GROUP BY day`、localtime 边界。**日历数据源复用它，不新建 DAO 查询**。
- ✅ `DateBoundaries`（Phase 24）—— 月/日范围推导。
- ✅ `analyticsRepositoryProvider` 已在 `lib/features/analytics/presentation/providers/repository_providers.dart`（日历 provider 注入它）。

**不在本 phase：**
- transaction tile / sort-filter bar（Phase 28）；列表组装 / pull-to-refresh / family member 归属（Phase 29）。
- **family 多-book 每日合计**（CAL-02 的「家庭模式合并成员支出」）—— 推到 Phase 29（own-book only 是 v1.4 锚，Phase 26 D-08）。本 phase calendar provider own-book only，预留 seam。
- ARB key 落地 + 三语 copy + golden baseline —— Phase 30（本 phase 用占位/英文或既有 key，新 copy 在 Phase 30 收口）。

</domain>

<decisions>
## Implementation Decisions

### 每日单元格显示（CAL-02 / SC#2）
- **D-01:** 每个有支出的日单元格在日期数字下方显示 **compact 金额**（无 dot/marker）。复用 `NumberFormatter` compact（ja/zh `1.2万`、en `1.2k`）+ 微型字号。无支出的日不显示任何金额指示（SC#2 原话「days with no expenses show no amount indicator」）。
  - **理由:** 用户初选「dot only」，但 SC#2 明写「cell **shows the total expense**」+「no **amount** indicator for empty days」—— dot-only 只表「有/无」不表「合计」，会 fail SC#2。用户改选 compact-amount-no-dot：既满足 SC#2，又在 ~40dp 小单元格里可读（full `¥12,345` 在 JPY 5+ 位会溢出/缩字）。research STACK §"Capability 1" 推荐的正是 `AppTextStyles.micro` compact 金额。
- **D-02:** 单元格 **today / 选中日的视觉态由实现裁量**（Claude's Discretion）—— 倾向：选中/过滤日 = accent-color ring（`AppColors.accentPrimary`），today = 淡背景/描边；compact 金额文本保持中性色。
  - **理由:** 用户选「You decide」，按 Wa-Modern 主题 + research §"Design fit"（selected-day ring 复用 `AppColors.accentPrimary`）裁量即可，非视觉关键决策。

### 月份导航（CAL-01 / SC#1）
- **D-03:** 切月 = **prev/next chevron + 横向 swipe**（`table_calendar` 原生 swipe，零成本）。**不**做跳转任意月的 month picker。
  - **理由:** ROADMAP SC#1 只要求 arrows；REQUIREMENTS CAL-01 提到「month picker」。用户选 arrows+swipe → v1.4 不 ship 任意月跳转 picker（见 Deferred）。swipe 是 table_calendar 默认行为，主动禁用反而费力。
- **D-04:** **点月份标签 = 跳回当前真实月**（today's month）。导航走远后的「回到本月」快捷方式，复用月标签本身、不加额外 picker UI。
  - **理由:** 用户选「Tap month label = today」。常见、可发现、廉价；不引入 picker 面。

### 日历高度 / 格式
- **D-05:** 日历 **始终全月网格**（always full month）。列表（Phase 28/29）在其下方滚动 / 整屏滚动吸收固定头部高度。**不**做 week/month collapsible format toggle。
  - **理由:** 用户选「Always full month」= table_calendar 默认、最可预测、无 format 状态管理。collapsible 推到 v1.5（见 Deferred）。

### 日过滤 ↔ 月度摘要联动（CAL-03 / CAL-04）
- **D-06:** 摘要行 **始终显示当月总额**（满足 SC#4）；当选中某日时，**额外加一条 day-total subline** 显示该日合计。两者并存（month total 不被日选中替换）。
  - **理由:** 用户选「Month total + day subline」。SC#4 原话「current-month summary」—— 月总额恒在即满足；day subline 是增益信息，比「选中日时整行切成日总额」更不易被误读成另一指标。
- **D-07:** day subline 的日合计 **复用 calendar 的 `Map<DateTime,int>` per-day 数据**（取选中日那项），**不另起查询**。
  - **理由:** calendar provider 已按日聚合（D-08），subline 直接索引选中日，零额外 DB 往返；seam-friendly。
- **D-08:** 摘要两行的 **label/copy + ARB key 由实现裁量**（Claude's Discretion）—— 遵循既有 `NumberFormatter` + `DateFormatter` + `S.of(context)` 模式；新 copy 在 Phase 30 三语收口。
  - **理由:** 用户选「You decide」。具体「今月の支出」vs amount-only、subline 日期格式等按可读性定，i18n 收口在 Phase 30。

### 日历数据 provider（Phase 26 D-10 推到本 phase 建）
- **D-09:** 新建 **独立** `@riverpod` provider `calendarDailyTotals(bookId, year, month)` → `Map<DateTime, int>`（date → 当日 expense-only sub-units），读 `analyticsRepositoryProvider.getDailyTotals`。**与 `listTransactionsProvider` 分开**（research Pitfall 3：日历合计只 watch `(bookId, month)`，不随 ledger filter / 文本搜索重算，否则每次搜索 keystroke 都重渲染 31 个日单元格）。
  - **理由:** Phase 26 D-10 明确把 calendar provider 推到本 phase 建（与日历 UI 同 phase 更内聚）。research STACK §line 54 给出 provider 形态；PITFALLS Pitfall 3 给出「必须分开」的硬依据。
- **D-10:** calendar provider **own-book only**：`bookId` 单值；family 多-book 每日合计合并推到 Phase 29。结构预留 seam（注释标 `// Phase 29: combine shadow books for family per-day totals`）。
  - **理由:** v1.4 own-book only 锚（Phase 26 D-08）。CAL-02 family 合并是 Phase 29 FAM 范围；本 phase 不接 `shadowBooksProvider`。
- **D-11:** 月度摘要总额 = **calendar `Map<DateTime,int>` 的 values 求和**（同一 month 范围、同一 expense-only 口径），保证摘要与日单元格口径一致、单一数据源。
  - **理由:** 避免「摘要走一条 query、日单元格走另一条」导致口径漂移；同一 provider 派生既满足 SC#2 又满足 SC#4，且天然 expense-only。

### Claude's Discretion
- **today/选中日单元格视觉态**（D-02）—— accent ring + 淡 today 标记方向，细节按 Wa-Modern 主题定。
- **摘要 label/copy + ARB key**（D-08）—— Phase 30 三语收口前可用占位。
- **`calendarDailyTotals` 是否用 `(bookId, year, month)` 还是 `(bookId, DateTime focusedMonth)` 入参** —— 按 `@riverpod` family 可读性定；务必只依赖 `(bookId, month)` 不依赖 filter（D-09）。
- **日历 `startingDayOfWeek`（周起始日）** —— locale-aware（ja/zh 周日起 vs ISO 周一起），由 `currentLocaleProvider` / table_calendar `locale` 驱动；具体默认按 research §line 47 与既有 locale 约定裁量。
- **day-tap toggle 逻辑位置**（再点同日清除）—— 放 widget 回调或包成 `ListFilter` 的 toggle helper，由实现按可读性定；`selectDay(null)` 已是清除路径。
- **widget 测试构造** —— `ProviderContainer.test()` + `waitForFirstValue<T>`（CLAUDE.md Riverpod 3 异步测试约定），mock `AnalyticsRepository` 用 Mocktail。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求（权威验收）
- `.planning/ROADMAP.md` §"Phase 27: Calendar Header + Month Summary" — Goal + 5 条 Success Criteria（SC#1 月导航、SC#2 每日 expense-only 合计 own-book、SC#3 点日过滤 + 高亮 + 再点清除、SC#4 月摘要 expense-only via NumberFormatter+amountSmall、SC#5 `table_calendar ^3.2.0` + iOS build + intl 0.20.2 pin）
- `.planning/REQUIREMENTS.md` §"Calendar (CAL)" — CAL-01（切月：prev/next + month picker —— **本 phase 仅 arrows+swipe，picker 见 Deferred**）、CAL-02（每日合计；family 合并 → Phase 29）、CAL-03（点日过滤 + toggle 清除）、CAL-04（当月 expense-only 摘要）

### v1.4 上游 research（已锁定裁决）
- `.planning/research/STACK.md` §"Capability 1 — Month calendar grid with per-day expense totals"（line 41+、line 52/54/56 `calendarDailyTotals` provider 形态 + 复用 `getDailyTotals` + custom cell builder 设计）、§line 113/119/121/243/246（`table_calendar ^3.2.0` 版本/intl/win32 兼容裁决，SC#5 依据）、§line 200-217（建议文件布局 `state_calendar_totals.dart` / `list_calendar_header.dart`）
- `.planning/research/PITFALLS.md` §"Pitfall 3"（line 62-74：日历合计必须是**独立** provider、只 watch `(bookId, month)`、不随 filter/search 重算 —— D-09 直接依据）、§"Pitfall 4: Date-Range Boundary Errors"（line 81-107：边界 utility 已在 Phase 24 建并测；点日 23:00 后交易不漏）、§line 137（month summary + day totals 必须 **expense-only**，不混收入/不混 Soul 分数 —— D-01/D-06/D-11 依据）
- `.planning/research/SUMMARY.md` — v1.4 跨文件分歧裁决（family own-book only 等）

### 上游 phase context（直接依赖）
- `.planning/phases/26-providers-shell-wiring/26-CONTEXT.md` — Phase 26 全部决策；尤其 **D-10**（calendar provider 推到本 phase 建、与 list provider 分开）、**D-08**（own-book only seam）、`listFilterProvider` + `selectMonth`/`selectDay`/`clearAll` mutator（本 phase 接线对象）、`ListScreen` 现为纯 loading scaffold（本 phase 在其上挂 calendar header）
- `.planning/phases/25-domain-models-use-case/25-CONTEXT.md` — `ListFilterState` 7 字段（`selectedYear`/`selectedMonth`/`activeDayFilter`）形态
- `.planning/phases/24-data-layer-extension/24-CONTEXT.md` — `DateBoundaries` + localtime 边界契约（Pitfall 4 已治理）

### 既有代码（直接引用 / 对照模板）
- `lib/features/list/presentation/screens/list_screen.dart` — 现为纯 loading scaffold（`ConsumerWidget` 消费 `listTransactionsProvider`）；本 phase 在此挂 calendar header（List tab index 1，`main_shell_screen.dart` IndexedStack）
- `lib/features/list/presentation/providers/state_list_filter.dart` — `ListFilter` Notifier（`listFilterProvider`，keepAlive:true）+ `selectMonth(year,month)`（已含「切月重置 day filter」）/ `selectDay(DateTime?)`（已含「null = 清除」，支撑 CAL-03 toggle）/ `clearAll()`；**日历导航 + 点日接线进这些 mutator**
- `lib/data/daos/analytics_dao.dart:226` `getDailyTotals` — expense-only（`type='expense'` 默认）+ `DATE(timestamp,'unixepoch','localtime') GROUP BY day` + localtime 边界；**calendar 数据源（D-09），不新建查询**
- `lib/features/analytics/domain/repositories/analytics_repository.dart:26` + `lib/data/repositories/analytics_repository_impl.dart:68` `getDailyTotals` 接口/实现 — provider 调用对象；返回 `List<DailyTotal>`（`lib/features/analytics/domain/models/analytics_aggregate.dart:21`）
- `lib/features/analytics/presentation/providers/repository_providers.dart:34` `analyticsRepositoryProvider` — calendar provider 注入它（**复用，禁止为 list 重复建 repository provider** —— provider_graph_hygiene_test 会挂；list feature 已有自己的 `repository_providers.dart` 只放 transaction repo）
- `lib/features/analytics/presentation/providers/state_analytics.dart` — 现有 analytics provider 消费 `getDailyTotals` 的模式参照
- `lib/core/theme/app_text_styles.dart` — `AppTextStyles.amountSmall`（月摘要，SC#4 tabular figures）+ micro 级字号（每日 compact 金额，D-01）
- `lib/core/theme/app_colors.dart` — `AppColors.accentPrimary`（选中日 ring，D-02）；ledger 色 survival/soul 本 phase 不用（每日是合并 expense 合计，不分账本色）
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — compact 金额（D-01 每日）+ 月摘要金额（SC#4）；`date_formatter.dart` — 月标签 / day subline 日期
- `lib/features/home/presentation/screens/main_shell_screen.dart` — List tab 挂载点（IndexedStack index 1）；现有 sync listener + FAB 回调已对 list provider invalidate（Phase 26 D-03）

### 约定 / 工具链约束
- `CLAUDE.md` §"iOS Build" + §"Dependency pins to leave alone" — `table_calendar` 加包后必须 `flutter build ios --debug --no-codesign` 通过（SC#5）；`intl: 0.20.2` 精确 pin 不可破（table_calendar 要 `^0.20.0`，兼容）；不碰 file_picker/package_info_plus/share_plus 三件套
- `CLAUDE.md` §"Riverpod 3 conventions" — `@riverpod` 生成 family provider；`AsyncValue.value` nullable；`ProviderContainer.test()` + `waitForFirstValue`（widget/provider 测试）；**ONE repository_providers.dart per feature**（复用 analyticsRepositoryProvider）
- `CLAUDE.md` §"i18n Rules" — UI 文本 `S.of(context)`、金额 `NumberFormatter`、日期 `DateFormatter`、locale 从 `currentLocaleProvider`；新 ARB key 三语同步 + `flutter gen-l10n`（本 phase 占位、Phase 30 收口）
- `CLAUDE.md` §"Amount Display Style" — 货币值用 `AppTextStyles.amountLarge/Medium/Small`（含 tabular figures），SC#4 月摘要用 `amountSmall`
- `CLAUDE.md` §"Common Pitfalls" #8（analyze 0）、#10（不重复 repo provider）、#13（改注解后 build_runner 重生成）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AnalyticsRepository.getDailyTotals`（已存在）:** 已是 expense-only + per-day GROUP BY + localtime 边界 —— calendar 数据源直接复用（D-09），月摘要由其 values 求和（D-11），零新查询、口径天然一致。
- **`ListFilter` mutator（Phase 26 已建）:** `selectMonth`/`selectDay`/`clearAll` 已就绪；日历导航 + 点日只接线，不动 filter state 形态。`selectDay(null)` 即 CAL-03 清除路径。
- **`analyticsRepositoryProvider`（analytics feature）:** calendar provider 注入它，复用单一 repo provider。
- **`AppTextStyles` / `AppColors` / `NumberFormatter` / `DateFormatter`:** 单元格金额、选中 ring、月标签、摘要金额全部用既有设计系统组件。

### Established Patterns
- **`@riverpod` family provider:** `calendarDailyTotals(bookId, year, month)` 同 analytics 既有 `state_*.dart` 款；改注解后 `build_runner build --delete-conflicting-outputs`（SC#5 build clean）。
- **`CalendarBuilders.defaultBuilder` 自定义单元格:** research 确认 `table_calendar 3.2.0` 暴露此 API，整格替换 → 注入 compact 金额 + 选中 ring，不被包的视觉 chrome 限制。
- **feature provider 组织:** `lib/features/list/presentation/providers/state_*.dart`（calendar provider 落此）+ `widgets/`（calendar header widget）+ `screens/list_screen.dart`（挂载）。
- **Riverpod 3 widget/provider 测试:** `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail mock repo。

### Integration Points
- `calendarDailyTotals(bookId, year, month)` → calendar header widget 的单元格 builder + 月摘要行（D-09/D-11）；只 watch `(bookId, month)`，不随 filter/search 重算（Pitfall 3）。
- calendar header → `listFilterProvider`：导航调 `selectMonth`、点日调 `selectDay`（CAL-01/CAL-03）；月切换时 `selectMonth` 已自动重置 day filter。
- calendar header 挂在 `ListScreen` 顶部（替/扩现 loading scaffold），List tab via `main_shell_screen.dart` IndexedStack index 1。
- family seam：calendar provider `bookId` 单值，注释标 Phase 29 多-book 合并扩展点（own-book only 本 phase）。

</code_context>

<specifics>
## Specific Ideas

- **SC#2 vs 用户初选的张力（已 reconcile）:** 用户先选「dot only」，但 SC#2 明写单元格须「shows the total expense」—— 改定为 **compact 金额、无 dot**（D-01），既满足验收又保留克制的网格观感。
- **摘要 month-total 恒在 + day subline 增益（D-06）:** 选中日时月总额**不**被替换，另加一条该日小计 —— 避免把「日总额」误读成 SC#4 的「当月摘要」。
- **calendar provider 必须独立于 list provider（D-09，Pitfall 3 硬性）:** 日历合计只依赖 `(bookId, month)`；若与 filterable list 共用 provider，每次搜索 keystroke 会重算 31 个日单元格 + loading 闪烁。
- **单一口径来源（D-11）:** 月摘要 = calendar per-day map values 求和，确保摘要与日单元格同口径（都 expense-only、同月范围）。
- **table_calendar swipe 是默认行为:** arrows+swipe（D-03）顺势而为；若选 arrows-only 反而要主动禁 swipe。

</specifics>

<deferred>
## Deferred Ideas

- **任意月跳转 month picker（CAL-01 字面「month picker」）** —— v1.4 仅 arrows+swipe + 点标签回本月（D-03/D-04）。点月标签弹月/年 picker 跳任意月推到后续 milestone。
- **family 多-book 每日合计合并（CAL-02 家庭模式）** —— Phase 29（FAM）：calendar provider `bookId` 扩成 own + shadow books 合并，预留 seam（D-10）。
- **collapsible week/month format toggle** —— v1.5：本 phase 始终全月（D-05）；若 Phase 28/29 列表垂直空间紧张再引入 `CalendarFormat` 切换。
- **ARB key 三语 copy + golden baseline** —— Phase 30（~20-25 key × 3 locale + golden）：本 phase 摘要 label / day subline copy 用占位，Phase 30 收口（D-08）。
- **per-day 按账本色拆分（survival/soul）** —— 非本 phase：每日单元格是合并 expense 合计，不分账本色；若未来要日内双色条另议。

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 27-Calendar Header + Month Summary*
*Context gathered: 2026-05-30*
