# Phase 25: Domain Models + Use Case - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 25-Domain Models + Use Case
**Areas discussed:** ListFilterState 字段形态, UseCase 接口面, GetListParams 组合 + 搜索归属, UseCase 校验范围

---

## ListFilterState 字段形态（前瞻性）

| Option | Description | Selected |
|--------|-------------|----------|
| 一次建全 7 字段 | 按 Phase 26 SC#1 建齐 selectedMonth / activeDayFilter / sortConfig / ledgerType? / categoryId? / searchQuery / memberBookId? + clearAll()；后续 phase 只 wiring | ✓ |
| 最小化 + 增量 | 只建本阶段 SORT 相关 + 基本过滤，searchQuery 留 26、memberBookId 留 29 增量加 | |

**User's choice:** 一次建全 7 字段
**Notes:** 延续 Phase 24「SortField 一次建全 3 值」的同一哲学，避免跨 phase 改型。

## 类目过滤字段基数（categoryId）

| Option | Description | Selected |
|--------|-------------|----------|
| 单值 categoryId? | 对齐现有 repo 签名 + Phase 26 SC#1 本身的 categoryId? 规格；FILTER-03 多选记为 Phase 28 deferred | ✓ |
| Set<String> categoryIds | domain 型直接反映 FILTER-03 多选；需改 Phase 24 已 ship 的 repo 签名或 use case 内存过滤 | |

**User's choice:** 单值 categoryId?
**Notes:** Roadmap Phase 26 SC#1 自身的 composed-state 规格用的就是单值，repo SQL 过滤亦单值；本 phase 不提前引入跨层改动。

---

## UseCase 接口面

| Option | Description | Selected |
|--------|-------------|----------|
| execute() + watch() 都提供 | execute 返 Future<Result>（SC#3），watch 返 Stream 包 watchByBookIds；两路共用校验+转发；watch 空 bookIds 同步 throw ArgumentError | ✓ |
| 只 execute() | 最小满足 SC#3；Phase 26 provider 直接调 repo.watchByBookIds 拿响应式流（但 watch 路绕过 use case 校验） | |
| 只 watch() | 只暴露 Stream，与 SC#3 要求 execute 返 Result.error 冲突 | |

**User's choice:** execute() + watch() 都提供
**Notes:** LIST-02 响应式是核心，Phase 24 专门建了 watch 流；两路统一逻辑使 Phase 26 provider 保持薄。

---

## GetListParams 组合 + 搜索归属

| Option | Description | Selected |
|--------|-------------|----------|
| 传组合值对象 | GetListParams = { bookIds, ListFilterState filter }；use case 内经 DateBoundaries 推 dateRange + 转发可 SQL 化过滤 | ✓ |
| 扁平显式参数 | GetListParams 拆成 bookIds/startDate/endDate/ledgerType?/categoryId?/sortField/sortDirection；provider 先算好再传 | |

**User's choice:** 传组合值对象
**Notes:** filter→query 映射集中在 use case，恰是 SC#3「不依赖 Riverpod 可单测」的验证点。

| Option | Description | Selected |
|--------|-------------|----------|
| 搜索留 Phase 26 provider | use case 只转发可 SQL 化过滤；searchQuery 仍是 ListFilterState 字段但 use case 不消费；匹配在 provider 用解析后 category name + 解密 note + TaggedTransaction 做 | ✓ |
| use case 内存过滤 | execute/watch 拿 repo 结果后按 searchQuery 内存过滤；但需注入 CategoryLocalizationService + locale，污染纯 domain 单测 | |

**User's choice:** 搜索留 Phase 26 provider
**Notes:** 搜索匹配依赖 locale-aware category name + 加密 note 解密 + provider 层 TaggedTransaction，不可 SQL 化，天然落在 provider；与 Phase 24 D-03 一致。

---

## UseCase 校验范围

| Option | Description | Selected |
|--------|-------------|----------|
| 最小化 | 只 empty bookIds → Result.error（SC#3）；其余靠 Freezed 构造 + DateBoundaries 推导天然保证；watch 空 bookIds 同步 throw | ✓ |
| 加防御校验 | 额外校验 bookIds 不含空串、dateRange start<=end 兜底；增测试面但当前设计下多不可达 | |

**User's choice:** 最小化
**Notes:** 因 dateRange 由 use case 内部推导，start<=end 恒成立，额外校验多为死代码。

---

## Claude's Discretion

- `ListSortConfig` 默认值（推荐 updatedAt + desc，呼应 SORT-02 reference default）
- `ListFilterState` 初始值与 `clearAll()` 目标态
- 文件放置（`lib/features/list/domain/models/` + `lib/application/list/`）
- SC#4 copyWith 不变性测试 + SC#3 MockTransactionRepository（Mocktail）的具体测试组织

## Deferred Ideas

- 多选类目过滤（FILTER-03）→ Phase 28
- searchQuery 实际匹配逻辑 → Phase 26 provider
- memberBookId? 消费 / family 归属 → Phase 29
- 分页 / 无限滚动 → v1.5（沿用 Phase 24 D-02）
