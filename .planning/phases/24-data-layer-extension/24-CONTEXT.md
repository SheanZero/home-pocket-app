# Phase 24: Data Layer Extension - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

列表功能 (v1.4) 的数据层基础。在写任何 UI 之前，建立三个共享、可测试、安全的数据原语：

1. `TransactionDao.findByBookIds(bookIds, startDate, endDate, ...)` —— 单条 SQL 跨多个 `book_id` 查询，排除软删除行，支持 `ledgerType` / `categoryId` 过滤，按请求的 `SortField` 排序。
2. 基于 `findByBookIds` 的 Drift `.watch()` 响应式流 —— insert / soft-delete / sync-applied 写入后一个 Riverpod rebuild 周期内自动 emit，调用方无需 `ref.invalidate`。
3. `DateBoundaries.monthRange(year, month)` / `DateBoundaries.dayRange(day)` 月/日边界工具，边界包含当天 `00:00:00` 与 `23:59:59`。

并确认两条既有契约：软删除只走 `DeleteTransactionUseCase`（保护 hash chain）；shadow-book `note` 解密失败返回 `note: null` 且其余字段完好。

**不在本 phase：** 任何 UI、provider、domain model、use case（属 Phase 25+）；分页（明确推到 v1.5）；family 模式日历合计（own-book only 已定）。

</domain>

<decisions>
## Implementation Decisions

### 排序依赖（SortField enum 时序）
- **D-01:** `SortField`（timestamp / updatedAt / amount）与 `SortDirection`（asc / desc）enum **提前到 Phase 24 创建**，落在 `lib/shared/constants/sort_config.dart`。`findByBookIds` 直接用类型安全枚举做 ORDER BY。Phase 25 只 **引用** 该文件，不再新建。
- **理由:** Roadmap SC#1 要求 DAO "orders by the requested SortField"，若 enum 留在 Phase 25 则本 phase 的 SC#1 不可测。提前创建使 SC#1 在 Phase 24 内完全可验证，且 enum 放 `shared/constants/` 不触发 `import_guard`（domain 与 data 层都可 import）。

### 查询上限（limit 策略）
- **D-02:** **月范围查询不设 limit** —— 保证单月内所有条目都显示。`findByBookId` 现有的 `limit=100` 默认值不适用于列表月查询。
- **实现指引:** `findByBookIds` 可保留 limit 参数以备复用，但列表层对月范围查询不传 limit（或传 null/不限）。分页是明确的 v1.5 增强，本 phase 不实现。
- **权衡已知:** 极端情况下单月多账本数据量很大时一次性加载全部 —— 可接受，家庭多人单月一般远低于此规模。

### watch 流过滤粒度
- **D-03:** **全部过滤进 SQL watch** —— watch 查询绑定所有过滤条件：`bookIds` + `dateRange` + `ledgerType?` + `categoryId?` + ORDER BY。任一过滤变化触发新的 SQL 查询，由数据库做活，provider 层保持薄。
- **理由:** 与 SC#2 的"reactive without ref.invalidate"契合；过滤逻辑集中在 SQL 一处，避免 provider 层重复内存过滤逻辑。

### DateBoundaries 时区基准
- **D-04:** 月/日边界按 **设备本地时间 (local time)** 计算，与现有 `AnalyticsDao.getDailyTotals()` 的 `DATE(timestamp, 'unixepoch', 'localtime')` 分组保持一致。23:30 的交易归当天。
- **理由:** 若用 UTC 会与 AnalyticsDao 的 localtime 分组错位，导致日历每日合计与列表分组落在不同日。一致性优先。
- **注意:** 边界须包含 `00:00:00` 与 `23:59:59`（SC#3），用 `isBiggerOrEqualValue` / `isSmallerOrEqualValue`（与现有 `findByBookId` 一致），避免半开区间漏掉边界秒。

### Claude's Discretion
- `findByBookIds` 的多值 `book_id` SQL 实现方式（Drift `isIn()` DSL vs `customSelect` 的 `IN (?)` 展开）—— 由实现时按可读性与类型安全选择，但必须是 **单条 SQL**（SC#1），不得 N+1。
- 软删除 / hash chain 契约的测试构造（SC#4：软删一条中链交易后 `verifyChain()` 仍 valid）与 shadow-book 解密失败 fixture（SC#5）的具体测试组织。
- watch 流去重 / distinct 处理（避免无关写入触发多余 rebuild）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 范围与需求
- `.planning/ROADMAP.md` §"Phase 24: Data Layer Extension" — Goal + 5 条 Success Criteria（权威验收标准）
- `.planning/REQUIREMENTS.md` — LIST-02（响应式更新，新 `watchByBookId(s)` 流）

### v1.4 上游 research（已锁定的跨文件分歧裁决）
- `.planning/research/SUMMARY.md` — 4 条 Cross-File Divergence Resolutions：①日历合计复用 `AnalyticsDao.getDailyTotals`（不新建 DAO 方法）②`table_calendar` 决策 ③family 日历 own-book only ④ledger 颜色须核对常量
- `.planning/research/ARCHITECTURE.md` §"Feature Placement" / DAO 层 — `findByBookIds` 签名草案、shadow-book note 解密处理、family 数据来源（`shadowBooksProvider`）
- `.planning/research/PITFALLS.md` — hash chain 软删除契约、ledger 颜色反转风险、IndexedStack keepAlive（后者属 Phase 26）

### 安全 / 架构约束
- `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` — hash chain 完整性；软删除只能走 `DeleteTransactionUseCase`
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` — Drift / SQLCipher 数据层约定
- `CLAUDE.md` §"Drift TableIndex Syntax" — 若需新增索引，用 `TableIndex` + `{#column}` Symbol 语法

### 既有代码（直接复用 / 对照）
- `lib/data/daos/transaction_dao.dart` — 现有 `findByBookId`（单账本，limit=100）是 `findByBookIds` 的直接模板；`softDelete` 已存在
- `lib/data/daos/analytics_dao.dart` — `getDailyTotals` 的 `localtime` 分组（D-04 时区基准对齐对象）
- `lib/data/repositories/transaction_repository_impl.dart` — `_toModel()` 的 note 解密路径（SC#5：解密失败 → `note: null`）
- `lib/application/accounting/delete_transaction_use_case.dart` — 软删除唯一入口（swipe-delete 契约）
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — `verifyChain()`（SC#4 验证）
- `lib/data/daos/group_member_dao.dart` — 现有 `.watch()` 用法示例（响应式流 D-03 参考）
- `lib/core/theme/app_colors.dart` — `survival = #5A9CC8`（蓝）、`soul = #47B88A`（绿）已核实；颜色 tile 逻辑须引用常量名而非 hex（属 Phase 28，但 ledger 颜色 ground truth 在此）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TransactionDao.findByBookId`（`lib/data/daos/transaction_dao.dart:67`）：现有单账本查询，已有 `ledgerType` / `categoryId` / `startDate` / `endDate` 过滤与 `isDeleted.equals(false)` 排除 + `OrderingTerm.desc(timestamp)` + `id` tiebreaker。`findByBookIds` 在此基础上把 `bookId.equals` 改为多值 IN，加入 SortField 驱动的 ORDER BY，去掉/放宽 limit。
- `GroupMemberDao` 的 `.watch()`（`group_member_dao.dart:23`）：项目内已有 Drift watch 流用法，作为 `findByBookIds` watch 版本的参照。
- `AnalyticsDao.getDailyTotals`：`localtime` 分组基准，D-04 对齐目标。

### Established Patterns
- 边界比较用 `isBiggerOrEqualValue` / `isSmallerOrEqualValue`（闭区间，含边界秒）—— 现有 `findByBookId` 同款，DateBoundaries 须配合产出含 `23:59:59` 的 end 边界。
- 软删除 = `isDeleted = true` + `updatedAt`（`softDelete`），物理行保留以维持 hash chain 链。
- Result/repository 模式：DAO 返回 `TransactionRow`，repository `_toModel()` 负责解密与转换。

### Integration Points
- `lib/shared/constants/sort_config.dart`（新建，D-01）：被 DAO（data 层）与 Phase 25 domain 层共同 import 的中立位置。
- `findByBookIds` 将被 Phase 25 的 `TransactionRepository.findByBookIds` 接口 + Phase 26 的 `listTransactionsProvider` 消费；watch 版本支撑 LIST-02 的"无需手动刷新"。

</code_context>

<specifics>
## Specific Ideas

- watch 流的验收锚点（SC#2）：insert / soft-delete / sync-applied 三种写入都要在"一个 Riverpod rebuild 周期内"触发 emit。测试用 `ProviderContainer.test()` + `waitForFirstValue<T>`（见 CLAUDE.md Riverpod 3 异步测试约定），不要裸 `await container.read(provider.future)`。
- SortField 含 `updatedAt`（edit-time 排序）—— enum 三值（timestamp / updatedAt / amount）一次建全，即便 Phase 24 只需 timestamp 即可验证，避免 Phase 25 回头改 enum。

</specifics>

<deferred>
## Deferred Ideas

- **分页 / 无限滚动** —— 明确推到 v1.5。本 phase 月范围不设 limit（D-02）。
- **family 模式日历每日合计（combined）** —— v1.4 默认 own-book only（research Resolution 3 已裁决）；若用户要求合并家庭日历合计，作为 v1.5 独立增强（需新的跨 book_id `AnalyticsDao` 变体）。
- **undo-delete SnackBar / loading skeleton** —— research SUMMARY 列为 post-v1.4，不在本 phase。

</deferred>

---

*Phase: 24-Data Layer Extension*
*Context gathered: 2026-05-29*
