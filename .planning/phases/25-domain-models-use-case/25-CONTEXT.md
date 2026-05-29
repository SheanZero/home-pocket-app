# Phase 25: Domain Models + Use Case - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的**纯 Dart domain 层**。在写任何 provider / UI 之前，用 Freezed 值对象描述全部 filter/sort 状态，并交付一个不依赖 Riverpod、可单元测试的 use case：

1. **`ListSortConfig`** Freezed 值对象 —— 包裹 `SortField` + `SortDirection`（两个 enum 已在 Phase 24 创建于 `lib/shared/constants/sort_config.dart`，本 phase 只引用）。
2. **`ListFilterState`** Freezed 值对象 —— 一次建全列表功能的全部过滤状态（见 D-01）。
3. **`GetListTransactionsUseCase`** —— `execute()`（Future + Result）+ `watch()`（Stream），把已声明的 `TransactionRepository.findByBookIds / watchByBookIds`（Phase 24 已加在 accounting domain 接口上）封装成应用层入口。

**已经满足 / 既成事实（不重复建）：**
- ✅ `SortField`（timestamp/updatedAt/amount）+ `SortDirection`（asc/desc）已在 `lib/shared/constants/sort_config.dart`（Phase 24 D-01）—— Roadmap SC#1 基本已满足，本 phase 只 **import 验证**，不新建。
- ✅ `TransactionRepository.findByBookIds(...)` 与 `watchByBookIds(...)` 接口已在 `lib/features/accounting/domain/repositories/transaction_repository.dart`（Phase 24）声明，签名含 `categoryId: String?` 单值 + `SortField`/`SortDirection`。Roadmap SC「repository interface is declared」即指这两个方法，**已存在**，本 phase 不再新建 repo 接口，只消费它。

**不在本 phase：** 任何 Riverpod provider（属 Phase 26）；任何 UI（Phase 27+）；文本搜索的实际匹配逻辑（留 Phase 26 provider，见 D-05）；多选类目过滤（FILTER-03，推到 Phase 28，见 D-02）；family 成员归属/过滤的实现（memberBookId 字段建好但消费在 Phase 29）。

</domain>

<decisions>
## Implementation Decisions

### ListFilterState 字段形态（前瞻性）
- **D-01:** `ListFilterState` **一次建全 7 字段**，与 Phase 26 SC#1 的 composed-state 规格对齐：`selectedMonth`、`activeDayFilter`（nullable，null = 整月）、`sortConfig`（= `ListSortConfig`，嵌入而非散开）、`ledgerType?`、`categoryId?`、`searchQuery`、`memberBookId?`。并定义 `clearAll()` 一次重置所有过滤到初始值。
  - **理由:** Phase 26 SC#1 明确要求「单个 Freezed 值对象持有全部 composed filter state」且字段列表就是这 7 个。一次建全使后续 phase 只做 wiring 不改型。延续 Phase 24「SortField 一次建全 3 值，避免回头改 enum」的同一哲学。
  - **注意:** `searchQuery` 与 `memberBookId?` 是建好但本 phase use case 不消费的前瞻字段（消费分别在 Phase 26 / Phase 29）。`sortConfig` **嵌入** `ListFilterState` 内（而非作为 use case 的独立参数），保持单一状态来源。

### 类目过滤基数（categoryId）
- **D-02:** `categoryId` 用**单值 `String?`**，对齐现有 `repo.findByBookIds(categoryId: String?)` 与 Phase 26 SC#1 本身的 `categoryId?` 规格。
  - **理由:** Roadmap Phase 26 SC#1 的 composed-state 规格用的就是单值 `categoryId?`；repo 已 ship 的 SQL 过滤也是单值。本 phase 不为 FILTER-03 提前引入跨层改动。
  - **前瞻张力（deferred）:** FILTER-03「一个或多个类目」是 Phase 28 的 UI 需求 —— 到时再决定是把字段扩成 `Set<String>`（改 repo 为 `IN(...)`）还是在 provider/use case 层做多类目内存合成。见 Deferred Ideas。

### UseCase 接口面
- **D-03:** `GetListTransactionsUseCase` **同时提供 `execute()` 和 `watch()`**：
  - `execute(GetListParams)` → `Future<Result<List<Transaction>>>`（SC#3 的硬性契约，空 bookIds 返回 `Result.error`）。
  - `watch(GetListParams)` → `Stream<List<Transaction>>`，包 `repo.watchByBookIds(...)`，支撑 LIST-02 响应式（Phase 24 已建 watch 流）。两条路共用同一份参数校验与 filter→query 转发逻辑，使 Phase 26 的 `listTransactionsProvider` 保持薄。
  - **watch 路径的非法输入:** 因 `Stream` 无法返回 `Result.error`，`watch()` 对空 bookIds 采用**同步 `throw ArgumentError`**（provider 在调用前已保证 bookIds 非空，属编程错误而非用户错误）。

### GetListParams 组合 + dateRange 推导
- **D-04:** `GetListParams = { List<String> bookIds, ListFilterState filter }`（**传组合值对象**，非扁平标量）。use case 内部：
  - 从 `filter.selectedMonth` / `filter.activeDayFilter` 经 `DateBoundaries`（Phase 24 已建于 `lib/shared/utils/`）推出 `startDate` / `endDate`；
  - 从 `filter` 取 `ledgerType` / `categoryId`；
  - 从 `filter.sortConfig` 取 `sortField` / `sortDirection`；
  - 转发给 `repo.findByBookIds / watchByBookIds`。
  - **理由:** filter→query 的映射集中在 use case，恰好是 SC#3「不依赖 Riverpod 可单元测试」的验证点；Phase 26 provider 只需组装 `bookIds + filter`，状态形态单一来源。

### 文本搜索归属
- **D-05:** `searchQuery` 的**实际匹配留在 Phase 26 provider**，use case 不消费它。use case 只转发**可 SQL 化**的过滤（ledgerType/categoryId/date/sort）给 repo。
  - **理由:** 搜索要匹配 category name（需 locale-aware 解析，依赖 `CategoryLocalizationService` + locale）、merchant、note（加密字段，repo `_toModel` 解密后才可读），且 Phase 26 SC#3 把搜索结果定义在 `List<TaggedTransaction>`（provider 层概念）上 —— 这些都不可 SQL 化，天然落在 provider 内存层。与 Phase 24 D-03「可 SQL 化过滤进 SQL」一致；use case 保持纯 domain，单测不需注入 localization。
  - **注意:** `searchQuery` 仍是 `ListFilterState` 的字段（D-01），只是本 phase use case 透传/忽略。

### UseCase 校验范围
- **D-06:** **校验最小化** —— `execute()` 只对 empty `bookIds` 返回 `Result.error`（SC#3 硬性）。其余不变式靠 Freezed 不可变构造 + `DateBoundaries` 内部推导天然保证（dateRange `start<=end` 恒成立，额外校验多为死代码）。`watch()` 空 bookIds 同步 throw（见 D-03）。

### Claude's Discretion
- **`ListSortConfig` 默认值:** 推荐默认 `sortField = updatedAt`、`sortDirection = desc`，呼应 SORT-02「edit/created time (reference default)」。实现时按可读性定。
- **`ListFilterState` 初始/默认值与 `clearAll()` 的目标态:** 初始 = 当前月、无 day filter、默认 `ListSortConfig`、其余过滤为 null/空。`clearAll()` 重置到该初始态（`selectedMonth` 是否一并复位到当前月由实现按 UX 判断，但本 phase 不接 UI，先保守复位过滤项）。
- **文件放置:** Freezed 值对象 → `lib/features/list/domain/models/`（新建 list 模块，Thin Feature）；`GetListTransactionsUseCase` + `GetListParams` → `lib/application/list/`（新建，镜像 application 按 domain 组织的惯例）。具体 use case 是否与 params 同文件由实现定。
- **Freezed `copyWith` 不变性测试（SC#4）的组织:** 改 sortField timestamp→amount 后断言原对象未变、新对象为不同实例 —— 测试用例结构由实现定。
- **`MockTransactionRepository`（SC#3）的构造:** 用 Mocktail（项目标准），mock `findByBookIds`/`watchByBookIds`，断言空 bookIds 不触达 repo、合法参数被原样转发。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求（权威验收）
- `.planning/ROADMAP.md` §"Phase 25: Domain Models + Use Case" — Goal + 4 条 Success Criteria
- `.planning/REQUIREMENTS.md` — SORT-01/02/03/04（排序需求）；并注意 FILTER-01（搜索，归属 Phase 26）、FILTER-03（多类目，归属 Phase 28）作为前瞻字段的来源
- `.planning/ROADMAP.md` §"Phase 26" SC#1 — `listFilterStateProvider` 的 7 字段 composed-state 规格（D-01 的直接依据，含 `categoryId?` 单值规格 = D-02 依据）
- `.planning/ROADMAP.md` §"Phase 26" SC#3 — 文本搜索定义在 `List<TaggedTransaction>` + AND 合成（D-05 依据）
- `.planning/ROADMAP.md` §"Phase 29" FAM-01..04 — `memberBookId?` / family 字段的最终消费方（D-01 前瞻字段）

### 上游 research（已锁定裁决）
- `.planning/research/SUMMARY.md` — v1.4 跨文件分歧裁决（family own-book only 等）
- `.planning/research/ARCHITECTURE.md` §"Feature Placement" — `lib/features/list/` 新模块定位（read-biased，镜像 `features/analytics/`）

### 既有代码（直接引用 / 对照模板）
- `lib/shared/constants/sort_config.dart` — `SortField` / `SortDirection`（Phase 24 D-01 已建，本 phase import 引用，SC#1）
- `lib/features/accounting/domain/repositories/transaction_repository.dart` — `findByBookIds` / `watchByBookIds` 接口签名（Phase 24 已声明，use case 消费对象）
- `lib/application/accounting/get_transactions_use_case.dart` — 现有 `GetTransactionsUseCase` + `GetTransactionsParams` 是 use case 形态与 empty-id `Result.error` 校验的直接模板
- `lib/shared/utils/result.dart` — `Result<T>`（`Result.success` / `Result.error`，SC#3 返回类型）
- `lib/shared/utils/` 的 `DateBoundaries`（Phase 24 已建）— `monthRange(year,month)` / `dayRange(day)`，D-04 由 use case 调用推 dateRange
- `lib/features/accounting/domain/models/transaction.dart` — `Transaction` 模型 + `LedgerType` enum（filter 字段类型来源；既有 Freezed 模型风格参照）
- `lib/application/accounting/delete_transaction_use_case.dart` — 另一 use case 风格参照

### 约定 / 工具链约束
- `CLAUDE.md` §"Riverpod 3 conventions" + §"Key Patterns" — Freezed `@freezed` + `copyWith`、`build_runner` 代码生成约定（SC#2 要求 `.freezed.dart`/`.g.dart` 生成无错 + `flutter analyze` 0 issues）
- `CLAUDE.md` §"Common Pitfalls" #2/#4 — Domain 不得 import Data（`import_guard` 结构性强制）；immutability 用 `copyWith`
- `.planning/phases/24-data-layer-extension/24-CONTEXT.md` — Phase 24 全部决策（D-01 sort enum 提前、D-02 无 limit、D-03 全过滤进 SQL、D-04 localtime 边界），本 phase 的直接上游

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`sort_config.dart`（已存在）:** `SortField`/`SortDirection` 直接 import；放在 `lib/shared/constants/` 是 domain 与 data 都可 import 的中立位置（import_guard allow-list），`ListSortConfig` 包裹它。
- **`GetTransactionsUseCase` / `GetTransactionsParams`:** 同构模板 —— params 类 + use case 类 + `if (params.bookId.isEmpty) return Result.error(...)` 校验 + 转发 repo + `Result.success`。本 phase 的 `GetListTransactionsUseCase` 按此扩成多 book + filter 组合 + 增 `watch()`。
- **`DateBoundaries`（Phase 24 已建）:** use case 内 `filter.selectedMonth`/`activeDayFilter` → dateRange 的推导工具，避免 use case 自己写月末边界算术。
- **`Result<T>`:** 既有 `Result.success/error`，SC#3 直接复用。

### Established Patterns
- **Freezed 值对象:** 项目大量 `@freezed`（如 v1.3 `TransactionDetailsFormConfig`、v1.2 `TimeWindow` sealed VO）—— `ListFilterState`/`ListSortConfig` 同款，`copyWith` 不可变（SC#4）。
- **use case 不依赖 Riverpod:** 纯构造注入 `TransactionRepository`，单测用 Mocktail mock（SC#3）。`waitForFirstValue` 等 Riverpod 测试约定本 phase 用不到（无 provider）。
- **Thin Feature:** `lib/features/list/` 只放 `domain/models/`（+ 后续 presentation）；use case 在 `lib/application/list/`；repo 接口已在 accounting domain（不在 list feature 内重复声明）。

### Integration Points
- `ListFilterState` / `ListSortConfig` 将被 Phase 26 的 `listFilterStateProvider`（持有 state）+ `listTransactionsProvider`（消费）引用。
- `GetListTransactionsUseCase.execute()/watch()` 将被 Phase 26 provider 调用；`watch()` 支撑 LIST-02「无需手动刷新」。
- `searchQuery` 字段（建于此）→ Phase 26 provider 内存匹配；`memberBookId?` 字段（建于此）→ Phase 29 family 过滤。

</code_context>

<specifics>
## Specific Ideas

- `sortConfig` **嵌入** `ListFilterState`（不作为 use case 的并列独立参数）—— 单一状态来源，Phase 26 `listFilterStateProvider` 持有一个对象即覆盖全部 sort+filter。
- `watch()` 与 `execute()` 共用同一 `GetListParams` 与同一 filter→query 转发，避免两条路逻辑漂移。
- SC#4 不可变性测试锚点：`config.copyWith(sortField: amount)` 后 `identical(original, copy) == false` 且 `original.sortField == timestamp` 未变。

</specifics>

<deferred>
## Deferred Ideas

- **多选类目过滤（FILTER-03）** —— 本 phase `categoryId` 用单值 `String?`（D-02）。到 Phase 28 再决定扩 `Set<String>`（改 repo 为 `categoryId IN (...)`）还是 provider/use case 内存合成多类目。字段升级对 Freezed 是 `copyWith` 调用点的小改。
- **`searchQuery` 实际匹配逻辑** —— 字段建于本 phase，匹配实现（category name locale 解析 + 解密 note + merchant，AND 合成）在 Phase 26 provider（D-05）。
- **`memberBookId?` 消费 / family 归属** —— 字段建于本 phase，family 成员过滤 + 行归属在 Phase 29（FAM-01..04）。
- **分页 / 无限滚动** —— 沿用 Phase 24 D-02，明确推到 v1.5；本 phase use case 不引入 limit/offset 参数（月范围全量）。

</deferred>

---

*Phase: 25-Domain Models + Use Case*
*Context gathered: 2026-05-29*
