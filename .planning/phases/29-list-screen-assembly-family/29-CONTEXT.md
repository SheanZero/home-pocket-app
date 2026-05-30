# Phase 29: List Screen Assembly + Family - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的 **最终组装 + family-aware 层**。把 Phase 26–28 留下的全部 `// Phase 29` seam 翻成可用功能，交付 5 件事：

1. **Pull-to-refresh（LIST-04 / SC#1）** —— 列表下拉刷新：重新查询本地 DB 并反映自上次同步以来其它设备已落地的新条目。
2. **Family 多-book 合并（FAM-01 / SC#2）** —— group mode 下，`listTransactionsProvider` 的 `bookIds` 从 own-only 扩成 `[ownBookId, ...shadowBooks]`，经 `findByBookIds` 单查询合并；月总额 + 日历每日合计反映全家庭合并支出。
3. **Per-row member 归属（FAM-02 / SC#3）** —— 每条属于家庭成员的行渲染一个 member 归属 chip（emoji + 名）；**自己的行不带任何归属标签**。`TaggedTransaction.memberTag` 在 provider 内按 `tx.bookId → ShadowBookInfo` 查表填值。
4. **Member filter（FAM-03 / SC#4）** —— filter bar 加 per-member chip，单选某成员；与 active ledger + category filter **AND 合成**。接 Phase 26 已建的 `ListFilter.setMemberFilter(String? bookId)`（写 `memberBookId`）。
5. **"Mine only" 快捷（FAM-04 / SC#5）** —— filter 区一个 prominent toggle chip，瞬时切到仅自己的条目；再点回全家庭视图；**即使没有任何 member filter 激活时也可见**（在 group mode 内）。

**已经满足 / 既成事实（不重复建，全部已带 `// Phase 29` 标记）：**
- ✅ `TaggedTransaction { Transaction transaction; MemberTag? memberTag }` + `MemberTag { String emoji; String name }`（Phase 26 D-07 一次建全，`lib/features/list/domain/models/tagged_transaction.dart`）—— 本 phase **填 `memberTag`，不改型**。
- ✅ `ListFilterState.memberBookId: String?`（**单值** forward 字段，Phase 25/26）+ `ListFilter.setMemberFilter(String? bookId)` mutator（`state_list_filter.dart:72`）—— member filter / Mine-only 接线对象，不新建 state。
- ✅ `listTransactionsProvider(bookId)`（`state_list_transactions.dart`）—— seam 在 line 44–45（`bookIds = [bookId]`）+ line 103–105（`memberTag: null`）；本 phase 在此扩 bookIds + 填 memberTag。`Transaction.bookId` 存在（line 16），归属按 bookId 查表。
- ✅ `shadowBooksProvider` → `List<ShadowBookInfo>`（`state_shadow_books.dart`）；`ShadowBookInfo { Book book; String memberDisplayName; String memberAvatarEmoji }`。
- ✅ `isGroupModeProvider`（`state_active_group.dart:22`）—— gating family UI 的开关。
- ✅ `calendarDailyTotals(bookId, year, month)`（`state_calendar_totals.dart`）—— seam 在 line 22/30（own-book only + `// Phase 29: combine shadow books`）；月摘要 = 其 values 求和（Phase 27 D-11），故月总额自动跟随。
- ✅ `findByBookIds(bookIds, ...)` 单 SQL 跨多 book 查询 + ORDER BY（Phase 24）—— 合并 + 跨成员排序天然支持，无需 Dart 侧手工 merge/sort。
- ✅ `ListScreen` + `ListSortFilterBar` + `ListTransactionTile` + `ListEmptyState`（Phase 27/28）—— 挂载点 + 接线点已就位。MainShellScreen sync-listener + FAB 回调已对 `listTransactionsProvider` invalidate（Phase 26 D-03）。

**不在本 phase（明确推迟）：**
- ARB key 三语 copy + empty-state 文案精修 + golden baseline —— Phase 30（LIST-03）。本 phase 用占位/英文/既有 key（含 member chip / Mine-only / Mine 标签文案）。
- family 隐私加固（FAMILY-V2-01/02/03）—— v2 backlog。
- 分页 / 无限滚动 —— v1.5（Phase 24 D-02）。
- 多选 member filter —— `memberBookId` 是单值；多成员同时选推到后续 milestone（见 Deferred）。

</domain>

<decisions>
## Implementation Decisions

### Member 行归属（FAM-02 / SC#3）
- **D-01:** member 归属 = **trailing chip：avatar emoji + 短名**（如 `🐻 太郎`），用与 ledger tag **相同的 chip 容器样式但不同配色**以可区分（research line 76/258）。**自己的行不带任何归属 chip**（SC#3「own entries show no attribution label」字面要求）—— 即使在 group mode 内，own row 仍 bare。
  - **理由:** 用户选「Trailing chip: emoji + name」。最可读 —— 一眼既知「是谁」又知「是家庭条目」。`ListTransactionTile` 已有 `tagText`/`tagBgColor`/`tagTextColor` 三参驱动 ledger tag；member chip 是**第二个**视觉元素，沿用同一 chip 容器构造、由 caller 按 `taggedTx.memberTag` 是否非空决定渲染。
  - **planner 注意:** memberTag 非空 ⟺ 该行来自 shadow book ⟺ group mode。own row 的 `memberTag` 恒 null（provider 不为 own-book 行填 tag），故「own 不带标签」由数据驱动、无需 UI 侧额外判断。

### Member filter + Mine-only 控件（FAM-03 / FAM-04 / SC#4 / SC#5）
- **D-02:** filter bar 加 **per-member chip + 一个 prominent「Mine only」chip**，同处单行横向滚动 chip row（Phase 28 D-08 的 pinned bar 内）。**单选语义**：点某 member chip = `setMemberFilter(thatShadowBookId)`，自动取消其它选中（`memberBookId` 单值天然单选）；点「Mine only」= `setMemberFilter(ownBookId)`；点已选中的 chip 或某「All」态 = `setMemberFilter(null)` 回全家庭。member filter 与 ledger + category filter **AND 合成**（`listTransactionsProvider` 已对 ledger/category AND，member 再叠一层 bookId 过滤）。
  - **理由:** 用户选「Per-member chips + Mine chip」。最简单、匹配 research line 77/78、贴合 `memberBookId` 单值 state。Mine-only 复用同一 `setMemberFilter` 路径（= own bookId），**不引入第二个状态字段**。
  - **planner 注意:** 「Mine only」与 member filter 是**同一互斥单选组**（Mine = 选中 own book，member chip = 选中该 shadow book，All = null）。SC#5「Mine-only 即使无 member filter 激活也可见」= Mine chip 在 group mode 内**常驻可见**（不依赖先选某 member 才出现）。member filter 与 active member 的 bookId 过滤落在哪一层（SQL `findByBookIds` 入参收窄成单 book vs Dart 侧 `where(tx.bookId==memberBookId)`）由 planner 按性能/一致性定 —— 倾向收窄 `bookIds` 入参（让 SQL 只查选中 book），但须保证 own row 归属仍正确（own book 选中时无 shadow → memberTag 全 null）。
- **D-03:** 进入 group-mode 列表的 **默认视图 = All members combined**（`memberBookId = null`，own + 全部 shadow 合并）。「Mine only」是 opt-in 一点。
  - **理由:** 用户选「All members combined」。FAM-01 的头牌行为就是「一处看到全家」—— 默认合并视图让 family-merge 成为可见默认，是本特性的核心卖点。
- **D-04:** **Solo（非 group）模式 = 与 Phase 28 完全一致**：own-book only、**无** member chip、**无** Mine-only toggle、**无** 行归属。整个 family cluster（member chips + Mine-only + attribution）**仅当 `isGroupMode == true` 渲染**。Pull-to-refresh 在 solo 模式照常工作。
  - **理由:** 用户选「Exactly as Phase 28」。避免 dead control（cf. Phase 28 D-07 条件 clear-chip 同理）。`isGroupModeProvider` 是 gating 开关；solo 模式 `listTransactionsProvider` 的 `bookIds` 仍 `[ownBookId]`、`memberTag` 全 null，bar 不渲染 family chip 段。

### Pull-to-refresh（LIST-04 / SC#1）
- **D-05:** pull-to-refresh = **仅重载本地 DB**（`ref.invalidate` 列表 provider，重新查询本地）。**不**强制触发 P2P 同步轮。依赖后台 P2P sync 已把新条目落地（reactive Drift watch + shell sync-listener 已自动传播，Phase 24 SC#2 / Phase 26 D-03）。
  - **理由:** 用户选「Reload local DB only」。诚实反映手势实际作用、廉价、无 P2P 连接/邻近性悬挂风险。SC#1「reflects any new entries added on another device since the last sync」由读取当前本地态满足（后台 sync 已落地）；pull 是 reassurance + 兜底任何漏掉的 rebuild。
  - **planner 注意:** pull 应 invalidate **列表 provider + 日历 totals provider**（family 合并模式下日历也需反映合并新值，D-06）。`RefreshIndicator` 包裹列表的可滚动体（现 `ListScreen` 的 `ListView.builder`，挂在 calendar header 之下的 `Expanded` 内）；具体宿主结构由 planner 按 widget 树定。

### Calendar / 月总额 ↔ member filter（FAM-01 / SC#2）
- **D-06:** 日历每日合计 + 月总额 **始终显示全家庭合并**（own + 全部 shadow books 求和），**不**随 active member filter / Mine-only 变化。`calendarDailyTotals` 保持与 `listFilterProvider` filter state **隔离**（Phase 27 D-09 / Pitfall 3 —— 否则每次过滤/搜索重算 31 个日单元格）。下方列表照常按 member filter 收窄。
  - **理由:** 用户选「Always full-family combined」。匹配 SC#2 字面「reflect all members' combined expenses」；保持 calendar provider 不耦合 filter state（避免 re-render 风暴）。
  - **planner 注意:** `calendarDailyTotals(bookId, year, month)` 需扩成消费 own + shadow bookIds 求和（group mode）—— 入参从单 `bookId` 扩成 multi-book 或内部 `ref.watch(shadowBooksProvider)` 合并；**只 watch `(bookIds, year, month)`，绝不 watch `memberBookId`/search/ledger**（Pitfall 3 硬性）。月摘要 = calendar map values 求和（Phase 27 D-11），故月总额自动跟随合并值、单一口径。`AnalyticsRepository.getDailyTotals` 是单 book —— 多 book 需 per-book 调用后按日合并，或确认 DAO 支持 multi-book（planner research 确认；倾向 per-book 求和，行数小）。

### Claude's Discretion
- **member chip 配色** —— 与 ledger tag（survival/soul）可区分即可；按 Wa-Modern 主题 + `AppColors` 既有 token 裁量（不 hardcode hex）。可考虑 member-neutral accent 或按成员稳定派生色。
- **member chip 在 bar 内的顺序/位置** —— 单行横向滚动内相对 sort/ledger/category/search/clear chip 的排布按可读性定（倾向 family 段集中放在 ledger chips 附近或末段）；Mine-only chip 的视觉强调（如 filled vs outlined）按 prominence 需求裁量。
- **长 member 名 / 重名截断** —— 短名截断策略（如取 displayName 前 N 字或 emoji+首字）按 chip 宽度裁量。
- **member filter 过滤层（SQL `bookIds` 收窄 vs Dart `where`）** —— D-02 注。倾向收窄 `findByBookIds` 入参；planner 按性能/归属正确性定。
- **`RefreshIndicator` 宿主 widget 结构 + 刷新 spinner 观感** —— D-05 注；按既有 list widget 树定。
- **ARB key / 三语 copy（member chip 文案、「Mine only / 自分のみ / 仅我的」、「All」标签）** —— 本 phase 占位/英文/既有 key，Phase 30 三语收口（LIST-03）。
- **widget/provider 测试构造** —— `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail（CLAUDE.md Riverpod 3 约定）；FAM 测试需 mock `shadowBooksProvider` + `isGroupModeProvider`，断言合并条目数、memberTag 填值、own-row tag=null、member filter AND 合成、Mine-only=own、calendar 全家庭合并不随 filter 变。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求（权威验收）
- `.planning/ROADMAP.md` §"Phase 29: List Screen Assembly + Family" — Goal + 5 条 Success Criteria（SC#1 pull-to-refresh 反映同步新条目、SC#2 family 合并 + 月总额/日历每日合计反映全家庭、SC#3 per-row member 归属 + own 行无标签、SC#4 member filter chip + 与 ledger/category AND 合成、SC#5 Mine-only prominent toggle + 无 member filter 时也可见 + 再点回全家庭）
- `.planning/REQUIREMENTS.md` — LIST-04（pull-to-refresh）、FAM-01（合并 shadow books）、FAM-02（per-row 归属 name/emoji）、FAM-03（按成员过滤）、FAM-04（Mine-only 快捷）

### v1.4 上游 research（已锁定裁决）
- `.planning/research/FEATURES.md` §"Category F: Family-Aware Display"（line 71–79：合并 = per shadow book 查同月范围 + tag + merge + sort `timestamp DESC,id DESC`；归属 chip = `ShadowBookInfo.memberAvatarEmoji` + `memberDisplayName`，own 无 chip；member filter 驱动 included books；Mine-only deselect 其它；auto-refresh via syncStatusStreamProvider）、line 104–108/124–125（`TaggedTransaction` 形态 + medium-complexity merge + 单月全量加载 ≤2000 行）、line 139/141/145（model/provider/tile 落点）、line 258/260/261（tile 扩 `memberTag` 而非 fork；`shadowBooksProvider` 给 emoji+name；merge pattern）
- `.planning/research/PITFALLS.md` §"Pitfall 3"（日历合计独立 provider、只 watch `(bookId/s, month)`、不随 filter 重算 —— D-06 直接依据）、family sync + list refresh 接线（Phase 26 D-03 已接 shell invalidation）
- `.planning/research/ARCHITECTURE.md` §"Family Data Sourcing"（shadow note 解密 → null 优雅降级，搜索 `?? ''` 已 seam-safe，Phase 26 D-06）、Provider Dependency Graph
- `.planning/research/SUMMARY.md` — v1.4 跨文件分歧裁决（family own-book only 是 Phase 26-28 锚，本 phase 解锁 family）

### 上游 phase context（直接依赖）
- `.planning/phases/26-providers-shell-wiring/26-CONTEXT.md` — **D-07**（`TaggedTransaction`/`MemberTag` 一次建全，本 phase 填值不改型）、**D-08**（own-book only seam + `// Phase 29: merge shadow books → bookIds + memberTag` 标记）、**D-03**（shell sync/FAB invalidate 已接，D-05 pull-refresh 同模式）、**D-04/D-06**（搜索 locale-aware category name + shadow note `?? ''` seam-safe）、`listFilterProvider` + `setMemberFilter` mutator
- `.planning/phases/27-calendar-header-month-summary/27-CONTEXT.md` — **D-09**（calendar provider 独立、只 watch `(bookId, month)`，D-06 扩 multi-book 须守此约束）、**D-10**（own-book only + `// Phase 29: combine shadow books` seam）、**D-11**（月摘要 = calendar map values 求和，月总额自动跟随合并值）
- `.planning/phases/28-transaction-tile-sort-filter-bar/28-CONTEXT.md` — **D-08**（单行横向滚动 pinned chip bar，member/Mine chip 入此 bar）、**D-07**（条件 clear chip / 无 dead control 哲学，D-04 solo gating 同理）、`ListTransactionTile`（`tagText`/`tagBgColor`/`tagTextColor` 三参驱动 ledger tag，member chip 加第二视觉元素）、`ListSortFilterBar`（member chip 接线点）、`ListEmptyState`
- `.planning/phases/25-domain-models-use-case/25-CONTEXT.md` — `ListFilterState` 7 字段含 `memberBookId: String?`（单值）；`GetListTransactionsUseCase` 接 `bookIds` 列表

### 既有代码（直接引用 / 接线点）
- `lib/features/list/presentation/providers/state_list_transactions.dart` — **核心改点**：line 44–45 `bookIds = [bookId]` → group mode 扩 own + shadow；line 103–105 `memberTag: null` → 按 `tx.bookId → ShadowBookInfo` 查表填值；member filter（`memberBookId`）收窄逻辑加在此（SQL 入参或 Dart where）
- `lib/features/list/presentation/providers/state_calendar_totals.dart` — line 22/30 seam：`calendarDailyTotals(bookId,...)` → group mode 合并 own + shadow per-day（D-06，**不**接 filter state）
- `lib/features/list/presentation/providers/state_list_filter.dart` — `setMemberFilter(String? bookId)`（line 72）member filter / Mine-only 接线对象；单值单选语义
- `lib/features/list/domain/models/tagged_transaction.dart` — `TaggedTransaction` + `MemberTag`（填值目标，不改型）
- `lib/features/list/domain/models/list_filter_state.dart` — `memberBookId: String?`（单值字段，已建）
- `lib/features/home/presentation/providers/state_shadow_books.dart` — `shadowBooksProvider` → `List<ShadowBookInfo>{ Book book; String memberDisplayName; String memberAvatarEmoji }`（合并 + 归属数据源；本 phase provider watch 它）
- `lib/features/family_sync/presentation/providers/state_active_group.dart:22` — `isGroupModeProvider`（D-04 family UI gating 开关）
- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — member chip 渲染点（加第二视觉元素，沿用 chip 容器）
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — member chips + Mine-only chip 接线点（单行滚动 bar）
- `lib/features/list/presentation/screens/list_screen.dart` — `RefreshIndicator` 宿主 + family UI gating（按 `isGroupMode` 决定渲染 family 段）
- `lib/features/home/presentation/screens/main_shell_screen.dart` — sync-listener + FAB invalidate 群组（D-05 pull-refresh 同模式参照；List tab IndexedStack index 1）
- `lib/features/accounting/domain/models/transaction.dart` — `Transaction.bookId`（line 16，归属查表键）
- `lib/data/repositories/.../findByBookIds` + `lib/application/list/get_list_transactions_use_case.dart` — 多 book 单查询 + ORDER BY（合并 + 排序天然支持）
- `lib/features/analytics/presentation/providers/repository_providers.dart` — `analyticsRepositoryProvider.getDailyTotals`（单 book；D-06 multi-book 求和）
- `lib/core/theme/app_colors.dart` / `app_text_styles.dart` — member chip 配色 token（禁 hardcode hex）+ amount 样式

### 约定 / 工具链约束
- `CLAUDE.md` §"Riverpod 3 conventions" — `AsyncValue.value` nullable、`ref.listen` 副作用、`ProviderContainer.test()` + `waitForFirstValue`、ONE repository_providers.dart per feature（复用既有，禁为 list 重复建 —— provider_graph_hygiene_test 会挂）
- `CLAUDE.md` §"i18n Rules" — `S.of(context)`、`NumberFormatter`、`DateFormatter`、`currentLocaleProvider`；member chip / Mine-only 文案本 phase 占位，Phase 30 三语 + `flutter gen-l10n`
- `CLAUDE.md` §"Widget Parameter Pattern" — nullable param + provider fallback（`bookId ?? currentBookIdProvider`）
- `CLAUDE.md` §"Amount Display Style" — 月总额/日历金额用 `AppTextStyles.amount*`（tabular figures）
- `CLAUDE.md` §"Common Pitfalls" #2（Domain 不 import Data）、#8（analyze 0）、#10（不重复 repo provider）、#13（改注解/Freezed 后 `build_runner build --delete-conflicting-outputs`）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`TaggedTransaction` / `MemberTag`（Phase 26 D-07 已建全）:** 本 phase 只填 `memberTag`，不改型 —— provider 按 `tx.bookId → ShadowBookInfo` 查表造 `MemberTag(emoji, name)`。
- **`shadowBooksProvider` + `ShadowBookInfo`:** 同步给 `book.id`（查交易）+ `memberDisplayName` + `memberAvatarEmoji`（归属）—— 合并 + chip 数据一站式。
- **`findByBookIds(bookIds,...)` 单查询（Phase 24）:** own + shadow 合并 = 一个 SQL，ORDER BY 跨成员排序天然成立，**无需 Dart 手工 merge/sort**（比 research line 75 的「per-book 查询后 merge」更简）。
- **`setMemberFilter(String? bookId)`（Phase 26 已建）:** member filter + Mine-only 同一接线，单值单选，**不新增 state 字段**。
- **`isGroupModeProvider`:** D-04 family UI gating 现成开关。
- **`ListTransactionTile` / `ListSortFilterBar` / `RefreshIndicator`-able `ListScreen`（Phase 27/28）:** 挂载/接线点全就位；member chip = tile 第二视觉元素 + bar 加 family chip 段。
- **shell sync/FAB invalidate 群组（Phase 26 D-03）:** D-05 pull-refresh 复用同一 invalidate 模式。

### Established Patterns
- **own-book seam → multi-book 扩展:** `bookIds = [bookId]` → `[ownBookId, ...shadowBookIds]`（group mode）；`memberTag: null` → 查表填值。型不变（D-07），属 provider 内部局部改。
- **provider 与 filter state 隔离（Pitfall 3）:** `calendarDailyTotals` 只 watch `(bookIds, month)`，**绝不** watch `memberBookId`/search/ledger —— D-06 守此约束。
- **AND 合成过滤链:** `listTransactionsProvider` 已对 day/category/ledger/search AND；member filter 再叠一层 bookId 收窄。
- **`@riverpod` Notifier mutator → copyWith:** `setMemberFilter` 写 `memberBookId`；单值即单选。
- **Riverpod 3 测试:** `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail（mock shadowBooks + isGroupMode）。

### Integration Points
- `listTransactionsProvider`：group mode 时 watch `isGroupModeProvider` + `shadowBooksProvider` → 扩 `bookIds`、填 `memberTag`、按 `memberBookId` 收窄。
- `calendarDailyTotals`：group mode 合并 own + shadow per-day（D-06，隔离 filter）；月摘要 = 其 values 求和（Phase 27 D-11）。
- `ListSortFilterBar`：`isGroupMode` 时追加 member chips（per `shadowBooksProvider`）+ Mine-only chip → 各 `setMemberFilter(bookId / ownBookId / null)`。
- `ListTransactionTile`：`taggedTx.memberTag != null` → 渲染 member chip（emoji+名）；null（own/solo）→ bare。
- `ListScreen`：`RefreshIndicator` 包列表 → `onRefresh` invalidate 列表 + 日历 provider（D-05）；family 段按 `isGroupMode` gating（D-04）。
- shell：sync-listener + FAB invalidate 已覆盖列表 provider（Phase 26 D-03）；family 合并模式新增条目经后台 sync + watch 自动传播。

</code_context>

<specifics>
## Specific Ideas

- **own 行无归属是数据驱动（D-01）:** provider 不为 own-book 行填 `memberTag`（恒 null）→ tile 天然 bare，无需 UI 侧 isOwn 判断。SC#3 字面满足。
- **Mine-only = own bookId，不是第二状态（D-02）:** 复用 `setMemberFilter(ownBookId)`；member chip / Mine / All 是同一互斥单选组（shadow bookId / own bookId / null）。避免引入并行 `mineOnly: bool` 字段与 `memberBookId` 的状态冲突。
- **默认全家庭合并（D-03）:** 进入 group 列表 `memberBookId=null` —— FAM-01 头牌行为「一处看全家」即默认可见。
- **solo = Phase 28 不变（D-04）:** `isGroupMode==false` 时 family cluster 整体不渲染，避免 dead control（Phase 28 D-07 同哲学）。
- **pull-refresh 诚实化（D-05）:** 仅本地重载，不强制 P2P 轮（避免 peer 离线悬挂）；后台 sync + reactive watch 已传播新条目，pull 是 reassurance + 兜底。
- **日历全家庭恒定、隔离 filter（D-06，Pitfall 3 硬性）:** 日历/月总额不随 member filter 变 —— 既符 SC#2「all members combined」又守住 calendar-provider 不耦合 filter 的性能约束。
- **合并用单 SQL 而非 Dart merge:** `findByBookIds` 已跨 book 单查询 + 排序，比 research line 75 描述的 per-book 查询后 merge 更简、更一致。

</specifics>

<deferred>
## Deferred Ideas

- **多选 member filter（同时选多个成员）** —— `memberBookId` 是单值；本 phase 单成员单选。多成员子集过滤推到后续 milestone（若需，扩 `Set<String> memberBookIds` + bar 多选 chip，类比 Phase 28 D-01 category 多选改造）。
- **ARB 三语 copy + member chip / Mine-only / empty-state 文案 + golden baseline** —— Phase 30（LIST-03）：family 文案三语 + golden。本 phase 占位。
- **pull-to-refresh 触发真实 P2P 同步轮 / hybrid（peer 可达则 sync）** —— 本 phase 仅本地重载（D-05）；主动 P2P 拉取推到后续（需 peer 连接状态机 + 超时/离线处理）。
- **family 隐私加固（FAMILY-V2-01/02/03）** —— v2 backlog（PROJECT.md 候选主题）。
- **per-day 按成员色拆分 / 日历内多成员可视化** —— 本 phase 日历是全家庭合并合计（D-06），不分成员色；若未来要日内成员拆分另议。
- **分页 / 无限滚动** —— v1.5（Phase 24 D-02）；本 phase 单月全量加载（research line 125：≤2000 行，4 成员家庭可承受）。

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 29-List Screen Assembly + Family*
*Context gathered: 2026-05-30*
