# Phase 28: Transaction Tile + Sort/Filter Bar - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的 **列表 UI 层**：单条 transaction tile、行交互（tap-to-edit / swipe-to-delete）、以及 **sort/filter bar 控件**。sort/filter 的**逻辑早已存在**（Phase 26 的 provider、Phase 25 的 `ListSortConfig`/`ListFilterState`）—— 本 phase 把这些既有逻辑**做成用户可操作的 UI**，并把 `ListScreen` 从 Phase 27 的 loading placeholder 换成真正的列表。

本 phase 交付（全部 own-book only）：

1. **Transaction tile（LIST-01 / ROW 显示）** —— 复用/扩展既有 `HomeTransactionTile`：category emoji + name、ledger-color tag（`AppColors.survival` / `AppColors.soul`，禁 hardcode hex）、日期 `DateFormatter`、金额 `NumberFormatter` + `AppTextStyles.amountSmall`（tabular figures 跨行对齐）。
2. **Tap-to-edit（ROW-01）** —— 点行打开既有 `TransactionEditScreen`（预填该 transaction、保留 `entry_source`）；保存后关屏、列表无需手动刷新即反映新值。
3. **Swipe-to-delete（ROW-02）** —— `Dismissible` 左滑 → AlertDialog 确认 → `DeleteTransactionUseCase.execute(id)`（soft-delete，hash-chain 完整）→ SnackBar → 行消失。
4. **Sort bar（SORT-01..04）** —— 字段菜单（date / edit-time / amount）+ 方向切换；active 态可视。
5. **Filter bar（FILTER-01..04）** —— ledger chips（All/生存/魂）、**多选**类目过滤、文本搜索、一键 clear-all（AND 合成）。
6. **Grouped-by-day 列表组装** —— 日期分组 section header + 行；挂在 Phase 27 calendar header 之下。

**已经满足 / 既成事实（不重复建）：**
- ✅ `listTransactionsProvider(bookId)` → `List<TaggedTransaction>`（Phase 26）—— 已含文本搜索（locale-aware category name + merchant + note）+ AND 合成 + day filter。本 phase tile/bar **消费它，不重写过滤逻辑**。
- ✅ `listFilterProvider`（`ListFilter` Notifier，keepAlive:true，Phase 26）+ mutator `selectMonth/selectDay/setSort/setLedgerFilter/setCategoryFilter/setSearch/clearAll`。bar 控件**接线进这些 mutator**。
- ✅ `ListSortConfig`（`SortField` timestamp/updatedAt/amount + `SortDirection` asc/desc，Phase 25）。
- ✅ `HomeTransactionTile`（纯 UI，`lib/features/home/presentation/widgets/`）—— tile 复用/扩展模板。
- ✅ `DeleteTransactionUseCase` / `UpdateTransactionUseCase` + `transactionRepositoryProvider`（accounting feature）。
- ✅ `TransactionEditScreen`（`lib/features/accounting/presentation/screens/`）—— tap-to-edit 直接打开。
- ✅ `CalendarHeaderWidget` 已挂 `ListScreen` 顶部（Phase 27）；本 phase 在其下方放列表 + bar。

**不在本 phase（明确推迟）：**
- **family member 归属 / member filter / "mine only"**（FAM-01..04）—— Phase 29。本 phase `memberTag` 一律 null，tile 不渲染 member chip。
- **pull-to-refresh + 响应式 sync 自动传播**（LIST-04）—— Phase 29（shell invalidation 接线 Phase 26 已做，但 pull-to-refresh UI 是 Phase 29）。
- **ARB key 三语 copy + empty-state 文案 + golden baseline**（LIST-03）—— Phase 30。本 phase 用占位/英文或既有 key。
- **分页 / 无限滚动** —— v1.5（Phase 24 D-02）。

</domain>

<decisions>
## Implementation Decisions

### 类目过滤基数（FILTER-03 / SC#5）
- **D-01:** 类目过滤 **多选**（match ROADMAP SC#5 字面「one or more categories」）。把 `ListFilterState.categoryId: String?` **扩成 `Set<String> categoryIds`**（建议 `@Default({})`），相应改 `ListFilter.setCategoryFilter`（或新增 `toggleCategory`/`setCategories`）+ `listTransactionsProvider` 的类目 AND-合成逻辑（行的 `categoryId ∈ categoryIds` 时保留；空集 = 不过滤）。
  - **理由:** 用户明确选 multi-select。Phase 25 D-02 注释把多选「deferred to Phase 28」—— 本 phase 正是决策点。SC#5 是显式验收项，state 扩展是局部改（一个字段型 + provider 过滤 + sheet UI），不破坏 `TaggedTransaction` 等下游型。
- **D-02:** 类目 sheet 的 **L1（parent）选择级联到其全部 L2（child）**；parent 部分选中时显示 **tristate**（半选）态。`Category` 已有 `parentId` + `level`（`lib/features/accounting/domain/models/category.dart`），可推导父子。
  - **理由:** 用户选「L1 selects all its children」。需要 parent→children 展开逻辑 + tristate UI；transaction 存单一 leaf `categoryId`，所以实际过滤集是被选中的 L2 leaf 集合（L1 勾选 = 把其所有 L2 leaf 加入 set）。
- **D-03:** bar 内类目过滤态 = **单个 count chip**「Categories (N)」（N = 选中 leaf 数）；点 chip 重开 sheet；通过全局 clear-all 清除。**不**为每个类目放独立 chip（避免 bar 溢出）。
  - **理由:** 用户选「Count chip」。bar 高度稳定、可扩展到多选；个别移除在 sheet 内做。

### 排序控件（SORT-01..04 / SC#4）
- **D-04:** 排序交互 = **字段菜单 + 方向箭头**。点 sort chip → 打开小菜单/sheet 列出 3 个字段（date / edit-time / amount）单选；**独立的方向箭头按钮**切 asc↕desc。接线进 `ListFilter.setSort`（写 `ListSortConfig`）。
  - **理由:** 用户选「Menu + direction arrow」。比盲目 cycle 更可发现、active 态更清晰；SC#4 的「cycle through」是一种合法交互而非强制——菜单同样满足「在 3 字段间选择 + 切方向」。
- **D-05:** **active 态双重指示满足 SC#4**：bar 的 sort chip **label 反映当前字段**（如 ja「日付」/「金額」），**方向箭头**显示 asc/desc，**打开的菜单内对 active 字段打勾**。三者并存。
  - **理由:** 用户最初选「chip 保持泛化 'Sort' + 仅菜单内打勾」，但 SC#4 明写「active field **and** direction visually indicated **in the sort bar**」—— 若字段只在菜单内打勾，bar 不开菜单就看不到当前字段，**字面 fail SC#4**。Reconcile 后用户改选「chip 显字段 + 菜单内打勾」：chip 显字段使其 bar-visible（过 SC#4），菜单打勾保留 in-menu 清晰态。**planner/verifier 注意：sort chip 必须显当前字段名，不能停在泛化 'Sort'。**

### Sort/Filter bar 组成 + 搜索（FILTER-01 / FILTER-04 / SC#5）
- **D-06:** 文本搜索 UI = **search icon 展开式**。bar 放一个 search 图标，点击展开 inline 搜索框（空时收起），接 `ListFilter.setSearch`。**不**常驻搜索框。
  - **理由:** 用户选「Search icon expands」。固定的全月 calendar header 下方垂直空间紧张；按需展开既省高度又可达。常驻搜索框会与 calendar 抢高度。
- **D-07:** clear-all = **条件 clear chip**。仅当有任一 filter/search/day-filter 激活时，bar 出现一个「Clear」chip，点击调 `ListFilter.clearAll()`（重置 ledger + categories + search + day filter，re-anchor 当前月）。无激活时不显示（无 dead control）。
  - **理由:** 用户选「Conditional clear chip」。满足 FILTER-04 一键重置，且默认 bar 不被永久控件占用。
- **D-08:**（Claude's Discretion，用户选「You decide」）**bar layout = 单行横向可滚动 chip row，pin 在 calendar header 之下**（不随列表滚走）。含 sort chip + 方向箭头 + ledger chips（All/生存/魂）+ category count chip + search icon +（条件）clear chip。
  - **理由:** 稳定高度、控件在列表滚动时始终可达；chip 增多时横向滚动吸收。wrapped 多行 + 随列表滚走会吃垂直空间且滚动后藏控件。

### 列表结构（LIST-01）
- **D-09:** 列表 **按日分组（grouped by day）**：每日一个 **date section header**（`DateFormatter` 日期），交易行列在其下；行内显示**时间**（而非重复完整日期）。
  - **理由:** 用户选「Grouped by day」。是 kakeibo 标准布局、与 calendar 天然配套、整月可扫读。
  - **SC#1 reconciliation（planner/verifier 注意）:** SC#1 字面要求「each **row** displays ... transaction date formatted via `DateFormatter`」。分组布局下，**`DateFormatter` 日期落在 day header**，行显示时间。视 header-date 为满足 SC#1 的「按行所属日的 DateFormatter 日期」。若 verifier 坚持逐行带日期，回退方案 = 行内也带 compact 日期；但默认按 header-date 实现。
- **D-10:** 日过滤激活（Phase 27 calendar 点日 → `activeDayFilter`）时，列表 = **单个 day group**（该日一个 header + 其行），与多日分组视觉一致。calendar 已高亮选中日，冗余无害。
  - **理由:** 用户选「Single day group」。与 D-09 分组布局一致；不为日过滤单开一种 flat 渲染路径。

### Claude's Discretion
- **bar layout 细节**（D-08）—— 单行横向滚动 pinned 方向已定；chip 间距/顺序/视觉按 Wa-Modern 主题裁量。
- **swipe-delete 具体观感** —— 左滑红色 trash 背景、`confirmDismiss` AlertDialog、右滑 no-op（research line 67 已锁）；动画/阈值/SnackBar 文案细节按可读性 + 既有 `Dismissible` 用例（`data_management_section.dart` / `family_sync_settings_section.dart`）裁量。
- **tile 的 soul-ledger satisfaction icon** —— `HomeTransactionTile` 已支持可选 `satisfactionIcon`（ADR-014 映射）；list tile 是否沿用按一致性裁量（倾向沿用以与 home 一致）。
- **类目 sheet 的具体 widget 构造** —— 可参照/复用 `category_selection_screen.dart`（既有 L1/L2 picker，单选 for entry）改为 filter 多选 + tristate；放 `lib/features/list/presentation/widgets/`。
- **ARB key / 三语 copy** —— 本 phase 占位或英文/既有 key，Phase 30 三语收口（LIST-03）。
- **empty-filter 结果态（过滤后 0 行）** —— 结构上需有 empty 占位，但文案 + golden 收口在 Phase 30；本 phase 可用占位文案。
- **widget/provider 测试构造** —— `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail（CLAUDE.md Riverpod 3 约定）；ROW-02 须有单测断言 `isDeleted=true` 且 `HashChainService.verifyChain()` 仍 valid。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求（权威验收）
- `.planning/ROADMAP.md` §"Phase 28: Transaction Tile + Sort/Filter Bar" — Goal + 5 条 Success Criteria（SC#1 tile 字段/色/格式/tabular 对齐、SC#2 tap-to-edit 预填 + 免手动刷新、SC#3 swipe-delete 确认 + `DeleteTransactionUseCase` soft-delete + hash-chain 单测、SC#4 sort cycle 3 字段 + 方向 + active 态 bar-visible、SC#5 ledger chip + **多选类目** + 与搜索 AND 合成 + 单一 clear-all）
- `.planning/REQUIREMENTS.md` — LIST-01（tile 显示）、ROW-01（tap-to-edit 复用 `TransactionEditScreen` + `TransactionDetailsForm` 保 `entry_source`）、ROW-02（swipe-delete 经 `DeleteTransactionUseCase`）；SORT-01..04 + FILTER-01..04 标记 [x]（逻辑 Phase 25/26 已建，本 phase 出 UI）

### v1.4 上游 research（已锁定裁决）
- `.planning/research/FEATURES.md` line 34（tile 复用/扩展 `HomeTransactionTile` + ledger tag 色 + amountSmall）、line 46（sort 方向 toggle = 小图标/dropdown chip）、line 56（ledger filter chips All/生存/魂）、line 57/239（类目过滤 = bottom sheet L1/L2 tree）、line 67/240（swipe-delete = `Dismissible` 左滑 + AlertDialog confirm + `DeleteTransactionUseCase`）、line 145（`ListTransactionTile` = extended `HomeTransactionTile`）、line 162（右滑-编辑 deferred；tap-to-edit 足够）、line 257（`HomeTransactionTile` 纯 UI，reuse/extend）
- `.planning/research/PITFALLS.md` — swipe-delete / Dismissible 安全实现；list refresh 接线（Phase 26 已接 shell invalidation）
- `.planning/research/ARCHITECTURE.md` — list feature provider/widget 组织、`TaggedTransaction` 消费形态
- `.planning/research/SUMMARY.md` — v1.4 跨文件分歧裁决（family own-book only 锚）

### 上游 phase context（直接依赖）
- `.planning/phases/27-calendar-header-month-summary/27-CONTEXT.md` — calendar header（挂载点、`activeDayFilter` 点日过滤、own-book only seam）；本 phase 列表挂其下
- `.planning/phases/26-providers-shell-wiring/26-CONTEXT.md` — `listTransactionsProvider`（消费对象）、`listFilterProvider` + mutator（bar 接线对象，D-04 `setCategoryFilter` 本 phase 扩多选）、`TaggedTransaction`/`MemberTag`（own-book `memberTag=null`，Phase 29 填值）、shell sync/FAB invalidation 已接（SC#2 免手动刷新依赖它）
- `.planning/phases/25-domain-models-use-case/25-CONTEXT.md` — `ListFilterState` 7 字段（D-01 把 `categoryId:String?` 扩 `Set<String>`）、`ListSortConfig`（D-04 写入对象）、D-02「categoryId 单值，多选 deferred to Phase 28」

### 既有代码（直接引用 / 对照模板）
- `lib/features/home/presentation/widgets/home_transaction_tile.dart` — **tile 复用/扩展模板**（纯 UI：tag + merchant + category + amountSmall + 可选 satisfactionIcon）；list tile 加 onTap(edit) + 包进 Dismissible
- `lib/features/list/presentation/screens/list_screen.dart` — 现为 `CalendarHeaderWidget` + loading `Expanded`；**本 phase 把 placeholder spinner 换成 grouped 列表 + sort/filter bar**
- `lib/features/list/presentation/providers/state_list_transactions.dart` — `listTransactionsProvider(bookId)`，tile 数据源
- `lib/features/list/presentation/providers/state_list_filter.dart` — `ListFilter` Notifier + mutator（bar 接线；D-01 改 `setCategoryFilter` 多选、写 `Set<String>`）
- `lib/features/list/domain/models/list_filter_state.dart` — `categoryId: String?`（**D-01 扩 `Set<String> categoryIds`，改后 `build_runner build --delete-conflicting-outputs`**）
- `lib/features/list/domain/models/list_sort_config.dart` + `lib/shared/constants/sort_config.dart` — `ListSortConfig` + `SortField`/`SortDirection`（D-04 sort 菜单/箭头驱动）
- `lib/application/accounting/delete_transaction_use_case.dart` — ROW-02 删除路径（soft-delete，禁绕过）
- `lib/features/accounting/presentation/providers/repository_providers.dart` — `deleteTransactionUseCaseProvider` / `updateTransactionUseCaseProvider` / `transactionRepositoryProvider`（**禁为 list 重复建 repository_providers.dart**，provider_graph_hygiene_test 会挂）
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` — tap-to-edit 打开目标（ROW-01，预填 + 保 `entry_source`）
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — 既有 L1/L2 类目 picker（单选 for entry）；类目过滤多选 sheet 的对照模板（D-02）
- `lib/features/accounting/domain/models/category.dart` — `Category`（`parentId` + `level`，D-02 L1→L2 级联推导）
- `lib/application/accounting/category_localization_service.dart` — locale-aware category name（tile category 显示 + 搜索匹配，Phase 26 D-04 已用）
- `lib/features/settings/presentation/widgets/data_management_section.dart` + `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart` — 既有 `Dismissible` 用例（swipe-delete 实现参照）
- `lib/core/theme/app_colors.dart` — `AppColors.survival` / `AppColors.soul`（ledger tag 色，禁 hardcode hex）；`lib/core/theme/app_text_styles.dart` — `AppTextStyles.amountSmall`（tabular figures）+ `micro`/`caption`
- `lib/infrastructure/i18n/formatters/number_formatter.dart`（金额）+ `date_formatter.dart`（day header 日期 / 行时间）

### 约定 / 工具链约束
- `CLAUDE.md` §"Amount Display Style" — 金额用 `AppTextStyles.amount*`（tabular figures，SC#1 跨行对齐）
- `CLAUDE.md` §"Widget Parameter Pattern" — nullable param + provider fallback（`bookId ?? currentBookIdProvider`）
- `CLAUDE.md` §"Riverpod 3 conventions" — `AsyncValue.value` nullable、`ref.listen` 副作用、`ProviderContainer.test()` + `waitForFirstValue`、ONE repository_providers.dart per feature
- `CLAUDE.md` §"i18n Rules" — `S.of(context)`、`NumberFormatter`、`DateFormatter`、`currentLocaleProvider`；新 ARB 三语 + `flutter gen-l10n`（本 phase 占位，Phase 30 收口）
- `CLAUDE.md` §"Common Pitfalls" #2（Domain 不 import Data）、#8（analyze 0）、#10（不重复 repo provider）、#13（改注解后 build_runner 重生成）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`HomeTransactionTile`（纯 UI）:** 已具 tag + merchant + category（带色）+ `amountSmall` + 可选 satisfactionIcon —— list tile 直接复用/扩展，加 `onTap`（→edit）并包进 `Dismissible`（→delete）。避免重写显示逻辑（SC#1）。
- **`listTransactionsProvider` + `listFilterProvider`（Phase 26）:** 过滤/搜索/AND-合成/day filter 逻辑全在 provider；bar 控件只调 mutator + tile 消费 `AsyncValue<List<TaggedTransaction>>`。
- **`DeleteTransactionUseCase` / `TransactionEditScreen`（accounting）:** ROW-02 / ROW-01 直接复用既有 use case + 屏，禁自建删除/编辑路径。
- **`category_selection_screen.dart` + `Category(parentId,level)`:** 类目多选 sheet（D-01/D-02）的对照模板 + 父子推导数据。
- **既有 `Dismissible` 用例:** settings / family_sync section 提供 swipe 实现参照。

### Established Patterns
- **Thin Feature:** list feature 只放 `domain/models` + `presentation/{screens,widgets,providers}`；tile/bar widget 落 `lib/features/list/presentation/widgets/`。
- **`@riverpod` Notifier mutator → copyWith state:** `ListFilter.setSort/setLedgerFilter/setCategoryFilter/setSearch/clearAll`；D-01 把 `setCategoryFilter` 改多选（写 `Set<String>`），改 Freezed 字段后须 `build_runner build`。
- **`AsyncValue.when` 消费 + grouped ListView:** `listTransactionsProvider` → 按日 group → `ListView`/`SliverList` + day header（D-09）。
- **Riverpod 3 测试:** `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail；ROW-02 hash-chain 单测（SC#3）。

### Integration Points
- `ListScreen`：`CalendarHeaderWidget`（Phase 27，固定头）→ **sort/filter bar（D-08 pinned chip row）** → grouped 列表（D-09，消费 `listTransactionsProvider`）。
- bar 控件 → `listFilterProvider` mutator（sort 菜单→`setSort`、ledger chip→`setLedgerFilter`、类目 sheet→多选 `setCategoryFilter`、search→`setSearch`、clear chip→`clearAll`）。
- tile `onTap` → push `TransactionEditScreen`（ROW-01）；`Dismissible.confirmDismiss` → AlertDialog → `DeleteTransactionUseCase.execute(id)`（ROW-02）。
- 编辑/删除后列表刷新：依赖 Phase 26 已接的 shell sync/FAB `ref.invalidate(listTransactionsProvider)`（SC#2 免手动刷新）；编辑返回路径若需，planner 确认 invalidate 覆盖。
- family seam：`memberTag=null` → tile 不渲染 member chip；Phase 29 填值 + member filter + mine-only，不改 tile 型（`MemberTag` 已建全）。

</code_context>

<specifics>
## Specific Ideas

- **多选类目 vs 单值 state 的张力（已 reconcile，D-01）:** SC#5 字面「one or more categories」胜出；`categoryId:String?` → `Set<String> categoryIds`，Phase 25 D-02 注释已预告本 phase 决策。L1 勾选级联 L2 + tristate（D-02），bar 用 count chip（D-03）。
- **SC#4 「active field in the bar」（已 reconcile，D-05）:** sort chip **必须显当前字段名**（不能停泛化 'Sort'）+ 方向箭头 + 菜单内打勾；否则 bar 看不到当前字段、字面 fail SC#4。
- **SC#1 「row displays date」vs grouped 布局（D-09 reconciliation）:** 分组下 `DateFormatter` 日期落 day header、行显时间。视 header-date 满足 SC#1；verifier 若坚持逐行日期则行内补 compact 日期为回退。
- **垂直空间约束:** 固定全月 calendar header（Phase 27 D-05）已占高度 → 搜索按需展开（D-06）+ 单行 pinned chip bar（D-08）以省高度。
- **swipe-delete 必走 use case:** ROW-02 / SC#3 硬性 `DeleteTransactionUseCase.execute(id)`（soft-delete + hash-chain），禁直接删 DAO；单测断言 `isDeleted=true` + `verifyChain()` valid。

</specifics>

<deferred>
## Deferred Ideas

- **family member 归属 chip + member filter + "mine only"**（FAM-01..04）—— Phase 29：tile 渲染 `memberTag`、bar 加 member chip + mine-only toggle。本 phase `memberTag=null`、tile 不渲染 member chip（型已建全，不回头改）。
- **pull-to-refresh + 响应式 sync 自动传播**（LIST-04）—— Phase 29。
- **ARB 三语 copy + empty-state 文案 + golden baseline**（LIST-03）—— Phase 30：sort/ledger/类目/clear/empty 文案三语 + golden。本 phase 占位。
- **右滑-编辑（swipe-right-to-edit）** —— research line 162 已 defer；tap-to-edit 足够，避免双向 swipe 歧义。
- **类目过滤 L1-cascade 的 tristate 之外更复杂的层级交互**（如跨 L1 mixed 选择的高级 UI）—— 本 phase 仅 L1→全 L2 级联 + tristate；更复杂层级 UI 后续 milestone 再议。
- **分页 / 无限滚动** —— v1.5（Phase 24 D-02）；本 phase 整月一次性渲染。
- **过滤后 0 行的精修 empty-state（插画/引导）** —— Phase 30 收口；本 phase 结构占位即可。

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 28-Transaction Tile + Sort/Filter Bar*
*Context gathered: 2026-05-30*
