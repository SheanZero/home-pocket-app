# Phase 26: Providers + Shell Wiring - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的 **Riverpod provider 接线 + shell 落地**。把 Phase 24（data 层 `findByBookIds`/`watch`）与 Phase 25（domain `ListFilterState`/`ListSortConfig` + `GetListTransactionsUseCase`）的产物组装成可被 UI 消费的 provider 图，并把 List tab 占位替换成可达的 `ListScreen`（仅 loading）。

本 phase 交付：
1. **`listFilterStateProvider`** —— Riverpod 3 `@riverpod` Notifier，持有 Phase 25 已建的 `ListFilterState`（7 字段 composed VO），`keepAlive: true` 编码于注解（不只是注释）。提供 `selectMonth/selectDay/setSort/setLedgerFilter/setCategoryFilter/setSearch/setMemberFilter/clearAll` 等 mutator。
2. **`listTransactionsProvider(bookId)`** —— `@riverpod` Future provider，返回 `List<TaggedTransaction>`：读 filter → 经 use case 取月范围 own-book 数据 → Dart 侧做 day filter + 文本搜索（FILTER-01）+ AND 合成（FILTER-04），包成 `TaggedTransaction`。
3. **`TaggedTransaction` + `MemberTag`** Freezed 值对象（SC#3 返回类型，本 phase 新建）。
4. **`getListTransactionsUseCaseProvider`** —— wiring Phase 25 use case，注入 `transactionRepositoryProvider`（**不**新建第二个 `repository_providers.dart`，复用 accounting feature 的单一来源）。
5. **`ListScreen`（纯 loading scaffold）** 替换 `main_shell_screen.dart:111` 的 `Center(child: Text(...))` 占位；MainShellScreen 的 sync listener + FAB-返回回调接上 `ref.invalidate(listTransactionsProvider(...))`。

**FILTER-01..04 在本 phase 被「编码进 provider」**：FILTER-01（文本搜索）+ FILTER-02（ledger）+ FILTER-03（categoryId 单值）+ FILTER-04（AND 合成 + `clearAll()`）的逻辑落在 provider/state；但其 **UI 控件**（sort/filter bar）在 Phase 28 才可用户观察（见 STATE.md 的 traceability note）。

**已经满足 / 既成事实（不重复建）：**
- ✅ `ListFilterState`（7 字段）+ `ListSortConfig` + `clearAll()` 已在 `lib/features/list/domain/models/`（Phase 25 D-01）。本 phase provider 直接持有，不改型。
- ✅ `GetListTransactionsUseCase.execute()/watch()` + `GetListParams` 已在 `lib/application/list/`（Phase 25 D-03/D-04）。provider 只组装 `bookIds + filter`，保持薄。
- ✅ `TransactionDao.findByBookIds` / `watchByBookIds` + repository 接口（Phase 24）—— use case 已封装，本 phase 不直接触达 DAO。
- ✅ `DateBoundaries`（Phase 24）—— 月范围推导已在 use case 内（Phase 25 D-04）。

**不在本 phase：**
- 任何 UI 控件实现（calendar header → Phase 27；transaction tile + sort/filter bar → Phase 28）。
- **family 多-book 分支的实际接线**（`isGroupMode` + `shadowBooksProvider` 合并 + `memberTag` 填值 + FAM-01..04）—— 推到 Phase 29（见 D-08）。本 phase own-book only + 预留 seam。
- `listCalendarProvider`（日历每日合计）—— 推到 Phase 27（见 D-10），随 Calendar Header 同 phase 建更内聚。
- 多选类目过滤（FILTER-03 `Set<String>`）—— Phase 28 再决定（Phase 25 D-02 已 defer）。
- 分页 / 无限滚动 —— v1.5（Phase 24 D-02）。

</domain>

<decisions>
## Implementation Decisions

### keepAlive 策略（IndexedStack 下，SC#2）
- **D-01:** `listFilterStateProvider` 标 **`keepAlive: true`**，全部 filter（含 month/day/sort/search/ledger/category）跨 tab 切换持久。策略 **编码于 `@Riverpod(keepAlive: true)` 注解**（不只是注释，满足 SC#2「encoded in code, not just a comment」）。
  - **理由:** Roadmap SC#2 原话即「filter state persists across tab switches under IndexedStack (keepAlive: true)」。IndexedStack 下所有 tab widget 常驻、订阅永不掉（research Pitfall 2），keepAlive:true 是最自然且与 SC 一致的行为。
- **D-02:** `selectedYear`/`selectedMonth` **与所有字段一起持久** —— 用户在 List tab 看 3 月、切去 Home 再回来仍是 3 月。`ListFilterState.initial()`（Phase 25 已建）仅作首次初始值与 `clearAll()` 的目标态。
  - **理由:** keepAlive 语义就是 keep 整个 state；「部分 keep 部分 reset month」会引入额外逻辑且语义矛盾（research Pitfall 2 的反模式）。

### MainShellScreen invalidation 接线（本 phase 接上）
- **D-03:** 本 phase 在 `main_shell_screen.dart` 的 **`syncStatusStreamProvider` listener**（现 line 34–91）与 **FAB-返回回调**（现 line 125+）中加 `ref.invalidate(listTransactionsProvider(bookId: bookId))`。
  - **理由:** provider 此 phase 已存在，接线廉价；反正 Phase 28 显示数据时必须接（research Pitfall 表「Family sync + list refresh」「Drift watch + auto-dispose」均要求），现在接避免 Phase 28/29 回头改 shell。与现有 home provider 的 invalidate 群组同模式（一致性）。
  - **注意:** 本 phase ListScreen 仅 loading，invalidate 暂无肉眼可见效果，属前瞻接线；不要因「看不到效果」而省略。

### 文本搜索语义（FILTER-01，SC#3）
- **D-04:** 搜索匹配 **本地化 category name**，**不是** `categoryId`。`listTransactionsProvider` 注入 `CategoryLocalizationService`（`lib/application/accounting/category_localization_service.dart`）+ `currentLocaleProvider`，把每行 `categoryId` 解析成当前 locale 的显示名再参与匹配。
  - **理由:** Roadmap SC#3 明写「match on category name」。research/ARCHITECTURE 草稿用 `t.categoryId.toLowerCase().contains(q)` 是 **shortcut bug**（用户搜「餐饮」匹配不到 `food_other`），不满足 SC#3。这使 provider 不再 thin，但是 FILTER-01 正确性所必需 —— 与 Phase 25 D-05「搜索匹配天然落在 provider 内存层（依赖 locale-aware category name + 解密 note）」一致。
- **D-05:** 匹配方式 = **大小写无关子串**：`query.toLowerCase().trim()` 对「category name / merchant / note」三字段做 `contains`，任一命中即保留（OR within search），search 整体再与 ledger/category 过滤 **AND 合成**（FILTER-04）。
  - **理由:** 与 research 草稿一致、贴合账本搜索直觉；CJK 文本无大小写问题也不受影响。前缀/分词/模糊 v1.4 不需要。
- **D-06:** shadow-book（家庭成员）的 note 解密返回 `null`（Phase 24 已定契约）→ 搜索 **优雅降级**：`(t.note?.toLowerCase().contains(q) ?? false)` 天然不匹配，不报错、不特殊处理；category name + merchant 仍跨成员可搜。
  - **注意:** 本 phase own-book only（D-08），实际 shadow 数据消费在 Phase 29 —— 但搜索代码用 `?? false` 写法即天然支持，无需 Phase 29 回头改搜索逻辑（seam-friendly）。

### TaggedTransaction 模型形态（SC#3 返回类型，本 phase 新建）
- **D-07:** **一次建全** `TaggedTransaction { Transaction transaction; MemberTag? memberTag }`，且 `MemberTag` = Freezed VO `{ String emoji; String name }`。放 `lib/features/list/domain/models/`（与 `ListFilterState`/`ListSortConfig` 同目录，Thin Feature domain 只放 models）。
  - **理由:** 延续 Phase 24/25「一次建全字段、避免回头改型」哲学。`ShadowBookInfo` 已有 `memberAvatarEmoji` + `memberDisplayName` 两值，Phase 28 tile 要 emoji+名一起显示 —— 用 `MemberTag` VO 比 `String? memberLabel` 更贴合（避免 Phase 29 拆字段）。research 两处不一致（ARCHITECTURE 用 `memberLabel:String?`、FEATURES 用 `MemberTag(emoji+name)`）—— **采纳 FEATURES 的 MemberTag**。
  - **注意:** 本 phase own-book only → `memberTag` 一律 `null`；Phase 29 填值，不改型。

### family 多-book 分支 + ListScreen 范围
- **D-08:** `listTransactionsProvider` 本 phase **own-book only**：`bookIds = [bookId]`，`memberTag = null`，**不**接 `isGroupModeProvider` / `shadowBooksProvider` / 合并逻辑。provider 结构预留多-book seam（注释标 `// Phase 29: merge shadow books → bookIds + memberTag`）。
  - **理由:** Phase 25 D-01 已把 `memberBookId` 消费与 family 归属推到 Phase 29（FAM-01..04）。SC#3 只验 own-book 搜索 AND 合成，不提 family。把 `shadowBooksProvider` 接线 + family 测试 fixture 拖进本 phase 会越界且使 SC#3 验证复杂化。
  - **前瞻张力（deferred）:** Phase 29 把 `bookIds` 扩成 `[bookId, ...shadowBooks]`、填 `memberTag`、加 `memberBookId` 过滤。属 provider 内部 + 入参的局部改，TaggedTransaction/MemberTag 型不变（D-07 已建全）。
- **D-09:** `ListScreen` = **纯 loading scaffold**：`ConsumerWidget` 消费 `listTransactionsProvider(bookId)`，`AsyncValue.when` 显 loading 指示；**不**建 calendar header / tile / sort-filter bar（那些是 Phase 27/28）。替换 `main_shell_screen.dart:111` 占位，List tab 可达。
  - **理由:** Roadmap SC#4 原话「list tab is reachable but shows a loading state」—— 最小变更。
- **D-10:** `listCalendarProvider`（日历每日合计，独立于 list provider）**推到 Phase 27**（Calendar Header）建，更内聚。本 phase 不建。
  - **理由:** Phase 26 SC 只点名 `listFilterStateProvider` + `listTransactionsProvider`。calendar provider 无 UI 消费无法在本 phase 验证（research Pitfall 3 已定「calendar 与 list 必须是分开的 provider」—— 分开建、各随其 phase）。

### Claude's Discretion
- **`listFilterStateProvider` 的 mutator 命名/粒度:** 参照 research/ARCHITECTURE §"state_list_filter.dart" 草案（`selectMonth/selectDay/setSort/...`），具体方法名与是否合并由实现按可读性定；但必须有 `clearAll()` 转发到 `ListFilterState.clearAll()`（FILTER-04）。
- **`@riverpod` 生成的 provider 名:** 按 Riverpod 3 约定（CLAUDE.md：`class ListFilterState` annotated → `listFilterStateProvider`，strip Notifier 后缀）。**注意命名碰撞**：Phase 25 已有 domain 层 Freezed 类 `ListFilterState`（`lib/features/list/domain/models/list_filter_state.dart`）—— Notifier 类不能也叫 `ListFilterState`，否则生成的 `listFilterStateProvider` 与类型同名/import 冲突。实现时给 Notifier 取不同类名（如 `ListFilter` Notifier → `listFilterProvider`，或 `ListFilterController`）并在 CONTEXT 决策外按可读性定 —— 这是 planner 必须解的真实约束。
- **loading 指示样式:** `CircularProgressIndicator` vs skeleton —— 本 phase 纯占位，按可读性；skeleton 是 post-v1.4（Phase 24 deferred）。
- **provider 测试构造（SC#3）:** `ProviderContainer.test()` + `waitForFirstValue<T>`（CLAUDE.md Riverpod 3 异步测试约定，**不要**裸 `await container.read(provider.future)`）；mock repo / use case 用 Mocktail；验文本搜索对 category name + merchant + note 的 AND 合成。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求（权威验收）
- `.planning/ROADMAP.md` §"Phase 26: Providers + Shell Wiring" — Goal + 4 条 Success Criteria（SC#1 composed-state、SC#2 keepAlive 编码、SC#3 `List<TaggedTransaction>` + 文本搜索 AND 合成、SC#4 ListScreen 替占位 + analyze 0 + build_runner clean）
- `.planning/REQUIREMENTS.md` §"Search & Filter (FILTER)" — FILTER-01（搜 category name/merchant/note）、FILTER-02（ledger 过滤）、FILTER-03（单/多类目）、FILTER-04（AND 合成 + 一键 clear）；注意 STATE.md 的 traceability note：FILTER-01..04 在本 phase 编码、Phase 28 首次用户可观察

### v1.4 上游 research（已锁定裁决）
- `.planning/research/ARCHITECTURE.md` §"Provider Dependency Graph"（line 212+）、§"Riverpod Provider Design"（line 337+ `state_list_filter.dart`/`state_list_transactions.dart` 草案）、§"Family Data Sourcing"（line 183+ `TaggedTransaction` + shadow note 解密 → null）——**注意 D-04 已修正草案的 categoryId shortcut bug**
- `.planning/research/PITFALLS.md` §"Pitfall 2: IndexedStack Keeps List Provider State Alive"（D-01/D-02 直接依据）、§"Pitfall 3: 日历与 list 必须分开 provider"（D-10 依据）、§"Anti-Patterns" 表（D-03 sync/FAB invalidation + 禁止重复 `repository_providers.dart`）
- `.planning/research/SUMMARY.md` — v1.4 跨文件分歧裁决（family own-book only 等）；§Freezed 3 值类型清单含 `TaggedTransaction`
- `.planning/research/FEATURES.md` line 123/124/139/261 — `MemberTag(emoji+name)` 形态（D-07 依据）、`ShadowBookInfo` 提供 emoji+name、family merge pattern（Phase 29 用）

### 上游 phase context（直接依赖）
- `.planning/phases/25-domain-models-use-case/25-CONTEXT.md` — Phase 25 全部决策（D-01 ListFilterState 7 字段一次建全、D-03 use case execute/watch、D-04 GetListParams + DateBoundaries 推导、D-05 搜索归属 provider、D-02 categoryId 单值）—— 本 phase 的直接上游
- `.planning/phases/24-data-layer-extension/24-CONTEXT.md` — Phase 24 决策（D-03 全过滤进 SQL、D-04 localtime 边界）

### 既有代码（直接引用 / 对照模板）
- `lib/features/home/presentation/screens/main_shell_screen.dart` — **line 97 IndexedStack、line 111 List 占位（替换目标）**、line 34–91 sync listener + line 125+ FAB 回调（D-03 invalidation 接线点）；现有 home provider invalidate 群组是同模式参照
- `lib/features/list/domain/models/list_filter_state.dart` — Phase 25 已建 `ListFilterState`（7 字段 + `clearAll()`）；provider 持有它；**命名碰撞警示**（见 Claude's Discretion）
- `lib/features/list/domain/models/list_sort_config.dart` — `ListSortConfig`（嵌入 ListFilterState）
- `lib/application/list/get_list_transactions_use_case.dart` — Phase 25 `GetListTransactionsUseCase.execute()/watch()` + `GetListParams`；provider 调用对象
- `lib/application/accounting/category_localization_service.dart` — **D-04 category name 解析依赖**；`category_display_utils.dart`、`home_screen.dart`、`per_category_breakdown_card.dart` 等是其消费示例
- `lib/features/accounting/presentation/providers/repository_providers.dart` — `transactionRepositoryProvider`（use case provider 注入对象）+ `deleteTransactionUseCaseProvider`/`updateTransactionUseCaseProvider`（Phase 28 用）；**禁止为 list 重复建 repository_providers.dart**（provider_graph_hygiene_test 会挂）
- `lib/features/analytics/presentation/providers/` — 现有 feature provider 组织（`state_*.dart` 命名）作为 list provider 文件组织参照
- `lib/features/home/presentation/providers/state_shadow_books.dart` — `shadowBooksProvider`（Phase 29 family seam 消费对象，本 phase 不接）
- `lib/features/family_sync/presentation/providers/state_active_group.dart` — `isGroupModeProvider`（Phase 29 family seam，本 phase 不接）
- `lib/features/accounting/domain/models/transaction.dart` — `Transaction`（`categoryId`/`note?`/`merchant?` 字段，D-04/D-05 搜索字段来源）+ `LedgerType`

### 约定 / 工具链约束
- `CLAUDE.md` §"Riverpod 3 conventions" — provider 命名 strip Notifier 后缀、`AsyncValue.value` nullable、`ref.listen` 用于副作用、`ProviderContainer.test()` + `waitForFirstValue`（SC#3 测试）、**ONE repository_providers.dart per feature**
- `CLAUDE.md` §"Riverpod Provider Rules" — use case provider 在 feature presentation/providers、`ref.watch` 引 repository、不重复 repo provider、不 throw UnimplementedError
- `CLAUDE.md` §"Common Pitfalls" #2（Domain 不 import Data）、#10（不重复 repo provider，结构性 enforced）、#8（analyze 0，SC#4）
- `CLAUDE.md` §"i18n Rules" — `currentLocaleProvider`（D-04 locale 来源）、`S.of(context)`（ListScreen loading 文案若需）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`ListFilterState` / `ListSortConfig` / `GetListTransactionsUseCase`（Phase 25 已建）:** provider 直接持有 + 调用，本 phase 不重建 domain/use case。
- **`CategoryLocalizationService`（已存在）:** D-04 把 categoryId → locale 显示名；多处（home/analytics）已消费，注入模式有现成参照。
- **`transactionRepositoryProvider`（accounting feature）:** `getListTransactionsUseCaseProvider` 注入它（复用单一 repo provider，不另起）。
- **`main_shell_screen.dart` 现有 invalidate 群组:** sync listener + FAB 回调里已对 home 系列 provider 做 invalidate，D-03 加 list 一行同模式。

### Established Patterns
- **`@riverpod` 代码生成:** Notifier provider（`listFilterStateProvider`）+ Future provider（`listTransactionsProvider`）；改注解后须 `build_runner build --delete-conflicting-outputs`（SC#4 build_runner diff clean）。
- **feature provider 组织:** `lib/features/{f}/presentation/providers/state_*.dart` + 单一 `repository_providers.dart`（analytics/home 现状参照）。
- **Freezed 值对象:** `TaggedTransaction`/`MemberTag` 同 `ListFilterState` 款（`@freezed` + `copyWith`）。
- **Riverpod 3 异步测试:** `ProviderContainer.test()` + `waitForFirstValue<T>`（test/helpers），不裸 `read(provider.future)`。

### Integration Points
- `listFilterStateProvider`（持 state，keepAlive:true）→ 被 `listTransactionsProvider` watch；Phase 27 calendar / Phase 28 sort-filter bar 也将读/改它。
- `listTransactionsProvider(bookId)` → `ListScreen` 消费（本 phase loading）；Phase 28 tile 渲染 `List<TaggedTransaction>`；MainShellScreen sync/FAB 接 invalidate（D-03）。
- `ListScreen` 替换 `main_shell_screen.dart:111`，挂在 IndexedStack index 1（List tab）。
- family seam：`listTransactionsProvider` 内 `bookIds` / `memberTag` 预留 Phase 29 扩展点（own-book only 本 phase）。

</code_context>

<specifics>
## Specific Ideas

- **keepAlive 编码而非注释（SC#2 硬性）:** `@Riverpod(keepAlive: true)` 写在注解上，不是 `// keepAlive` 注释。
- **D-04 修正 research 草案:** research/ARCHITECTURE 的 `t.categoryId.toLowerCase().contains(q)` 是 bug —— 必须经 `CategoryLocalizationService` 解析成 locale 显示名再匹配，否则 FILTER-01 不达 SC#3「category name」。
- **命名碰撞（planner 必解）:** domain 已有 `ListFilterState` 类型；Notifier 不能同名 —— 用不同类名（如 `ListFilter`/`ListFilterController`）使生成的 provider 名与 import 不冲突。
- **own-book seam:** `bookIds = [bookId]` + `memberTag = null` + 注释标 Phase 29 扩展点；搜索用 `note?...?? false` 即 shadow-note-safe，Phase 29 不改搜索逻辑。
- **invalidate 前瞻接线:** 本 phase loading 看不到效果，仍接 —— 反正 Phase 28 要用，避免回头改 shell。

</specifics>

<deferred>
## Deferred Ideas

- **family 多-book 接线（D-08）** —— `isGroupMode` + `shadowBooksProvider` 合并 + `memberTag` 填值 + `memberBookId` 过滤 + FAM-01..04，推到 Phase 29。本 phase own-book only + seam，`TaggedTransaction`/`MemberTag` 型已建全（D-07）不改型。
- **`listCalendarProvider`（日历每日合计）（D-10）** —— 推到 Phase 27（Calendar Header），与日历 UI 同 phase 更内聚；research Pitfall 3 已定「与 list provider 分开」。
- **多选类目过滤（FILTER-03 `Set<String>`）** —— Phase 28（Phase 25 D-02 已 defer）：扩 `categoryId` 为 `Set` 改 repo `IN(...)` vs provider 内存合成。
- **sort/filter bar + transaction tile UI** —— Phase 28（本 phase 只编码 provider 逻辑，无 UI 控件）。
- **calendar header UI（month nav + per-day totals + day-tap）** —— Phase 27。
- **loading skeleton / undo-delete SnackBar** —— post-v1.4（Phase 24 deferred）。
- **分页 / 无限滚动** —— v1.5（Phase 24 D-02）。

</deferred>

---

*Phase: 26-Providers + Shell Wiring*
*Context gathered: 2026-05-29*
