# Phase 26: Providers + Shell Wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 26-Providers + Shell Wiring
**Areas discussed:** keepAlive + 月份持久, 文本搜索语义 (FILTER-01), TaggedTransaction 模型形态, family 分支 + ListScreen 范围

---

## keepAlive + 月份持久

### Q1: filter state 跨 tab 切换的持久策略

| Option | Description | Selected |
|--------|-------------|----------|
| keepAlive:true 全持久 | provider 标 keepAlive:true，所有 filter 跨 tab 持久；对齐 SC#2 原话，IndexedStack 下最自然；策略编码于注解 | ✓ |
| reset-on-tab-leave | ref.listen(selectedTabIndexProvider) 离开时 invalidate；与 SC#2 相迫且需额外样板 | |

**User's choice:** keepAlive:true 全持久

### Q2: selectedMonth/year 是否也持久

| Option | Description | Selected |
|--------|-------------|----------|
| 所有字段一起持久 | month/day/sort/filter 都随 provider 保留；语义最一致，实现最简 | ✓ |
| month 重回时重锚当前月 | 仅 month 重置；需额外逻辑且与 keepAlive 语义矛盾 | |

**User's choice:** 所有字段一起持久

### Q3: MainShellScreen list invalidation 接线时机

| Option | Description | Selected |
|--------|-------------|----------|
| 本 phase 就接上 | sync listener + FAB 返回回调加 invalidate(listTransactionsProvider)；接线廉价且反正 Phase 28 要用 | ✓ |
| 推后到 Phase 28 | 等 tile 显示后再接；更贴"最小变更"但会再动一次 shell | |

**User's choice:** 本 phase 就接上

**Notes:** keepAlive 编码于 `@Riverpod(keepAlive: true)` 注解（SC#2 硬性「encoded in code, not just a comment」）。invalidate 本 phase loading 看不到效果，属前瞻接线，仍接以避免 Phase 28/29 回头改 shell。

---

## 文本搜索语义 (FILTER-01)

### Q1: category 字段搜什么

| Option | Description | Selected |
|--------|-------------|----------|
| 本地化 category name | 注入 CategoryLocalizationService + currentLocaleProvider，把 categoryId 解为 locale 显示名再匹配；SC#3「category name」真意 | ✓ |
| 照 research 草稿用 categoryId | 直接匹配 categoryId 字符串；语义错（搜「餐饮」匹配不到 food_other），不满足 SC#3 | |

**User's choice:** 本地化 category name

### Q2: 匹配方式

| Option | Description | Selected |
|--------|-------------|----------|
| 大小写无关子串 | query.toLowerCase().trim() 对 category name/merchant/note 做 contains | ✓ |
| 其他匹配策略 | 前缀/分词/模糊——成本高且 v1.4 不需要 | |

**User's choice:** 大小写无关子串

### Q3: shadow-book note 加密返回 null 的搜索处理

| Option | Description | Selected |
|--------|-------------|----------|
| 优雅降级，不报错 | note=null 自然不匹配 (?? false)；category name + merchant 仍跨成员可搜；不特殊处理 | ✓ |
| 本 phase 不处理 family (own-book only) | 与 Area 4 联动；本人账 note 均可解密 | |

**User's choice:** 优雅降级，不报错

**Notes:** D-04 修正 research/ARCHITECTURE 草案的 `t.categoryId.contains(q)` shortcut bug。搜索用 `note?...?? false` 写法即天然 shadow-note-safe，Phase 29 接 family 时不改搜索逻辑。与 Phase 25 D-05（搜索归 provider，依赖 locale-aware category name + 解密 note）一致。

---

## TaggedTransaction 模型形态

### Q1: 建多全

| Option | Description | Selected |
|--------|-------------|----------|
| 一次建全含成员属性 | TaggedTransaction { Transaction; MemberTag? memberTag }；延续 Phase 24/25 哲学；own-book 时 memberTag=null，Phase 29 填值不改型 | ✓ |
| 最小包装，Phase 29 再扩 | 仅 { Transaction }；Phase 29 加字段，与前两 phase 哲学不一致 | |

**User's choice:** 一次建全含成员属性

### Q2: 成员标记字段形态

| Option | Description | Selected |
|--------|-------------|----------|
| MemberTag VO(emoji+name) | Freezed { emoji; name }；ShadowBookInfo 已有两值，Phase 28 tile 要 emoji+名一起显示 | ✓ |
| 简单 String? memberLabel | 仅名字符串；emoji 要另外传，与 tile 显示需求不合 | |

**User's choice:** MemberTag VO(emoji+name)

### Q3: 放哪

| Option | Description | Selected |
|--------|-------------|----------|
| features/list/domain/models/ | 与 ListFilterState/ListSortConfig 同目录，Thin Feature domain 只放 models；research NEW 清单一致 | ✓ |
| 其他位置 | shared/ 或 application/list/ | |

**User's choice:** features/list/domain/models/

**Notes:** research 两处不一（ARCHITECTURE memberLabel:String? vs FEATURES MemberTag(emoji+name)）—— 采纳 FEATURES 的 MemberTag。

---

## family 分支 + ListScreen 范围

### Q1: listTransactionsProvider 接 family 多-book 到哪一步

| Option | Description | Selected |
|--------|-------------|----------|
| own-book only + 预留 seam | bookIds=[bookId]，memberTag=null，不接 isGroupMode/shadowBooks/合并；预留 Phase 29 seam | ✓ |
| 本 phase 就接全 family 分支 | 接 shadowBooks → 多 book + memberTag 填值；与 Phase 25 D-01 延迟冲突，把 FAM 测试提前 | |

**User's choice:** own-book only + 预留 seam

### Q2: ListScreen 多薄

| Option | Description | Selected |
|--------|-------------|----------|
| 纯 loading scaffold | 消费 listTransactionsProvider，AsyncValue.when 显 loading；不建 header/tile/bar；替占位 | ✓ |
| 预留结构骨架 | 预列 calendar/tile/bar 占位；超出 SC#4「loading state」范围 | |

**User's choice:** 纯 loading scaffold

### Q3: listCalendarProvider 本 phase 建吗

| Option | Description | Selected |
|--------|-------------|----------|
| 推后到 Phase 27 | calendar provider 是 Phase 27 核心，随那 phase 建更内聚；本 phase SC 不点名 | ✓ |
| 本 phase 一并建 | 三 provider 一次建全；但无 UI 消费无法在本 phase 验证 | |

**User's choice:** 推后到 Phase 27

**Notes:** SC#3 只验 own-book 搜索 AND 合成，不提 family。Phase 29 把 bookIds 扩成 [bookId, ...shadowBooks]、填 memberTag、加 memberBookId 过滤——TaggedTransaction/MemberTag 型不变。SC#4 原话「reachable but shows a loading state」= 最小变更。

---

## Claude's Discretion

- `listFilterStateProvider` mutator 命名/粒度（参照 research 草案，须有 clearAll()）。
- **provider 命名碰撞**：domain 已有 `ListFilterState` 类型 —— Notifier 须取不同类名（如 `ListFilter`/`ListFilterController`）使生成 provider 名不冲突（planner 必解的真实约束）。
- loading 指示样式（CircularProgressIndicator vs skeleton——skeleton 是 post-v1.4）。
- provider 测试构造：ProviderContainer.test() + waitForFirstValue + Mocktail。

## Deferred Ideas

- family 多-book 接线（isGroupMode + shadowBooks + memberTag + memberBookId 过滤 + FAM-01..04）→ Phase 29。
- listCalendarProvider（日历每日合计）→ Phase 27。
- 多选类目过滤（FILTER-03 Set<String>）→ Phase 28。
- sort/filter bar + transaction tile UI → Phase 28；calendar header UI → Phase 27。
- loading skeleton / undo-delete SnackBar → post-v1.4；分页 → v1.5。
