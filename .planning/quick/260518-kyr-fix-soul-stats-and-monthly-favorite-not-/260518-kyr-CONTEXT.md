---
quick_id: 260518-kyr
description: Fix soul stats and monthly favorite not refreshing after new soul ledger entry
gathered: 2026-05-18
status: ready_for_planning
---

# Quick Task 260518-kyr: 修复悦己统计 / 本月最爱不刷新 — Context

<domain>
## Task Boundary

**用户原话：** 修复 bug：当有新的 soul 记账的时候，首页的总支出有更新，但悦己统计和本月最爱都没有更新。

**已知的 ground truth：**
- 同一次插入操作，首页总支出能感知到（总支出 widget 正确刷新）
- 「悦己统计」widget 不刷新
- 「本月最爱」widget 不刷新
- 三者位于同一首页（很可能是同一 screen 的不同子组件）

**这意味着：**
插入 transaction 时，数据库写入和至少一条 provider 链路（总支出走的那条）是工作的。「悦己统计」和「本月最爱」要么 watch 了错误的 provider，要么有独立缓存没失效，要么干脆没监听任何 reactive source — 区别就在 provider wiring 上。
</domain>

<decisions>
## Implementation Decisions

### 修复范围 — 「修这两个 + 服务层一致性检查」
- 主体只改这两个 widget 及其上游 provider 链；不主动扩散到首页其他组件
- 但 SoulStats / MonthlyFavorite 的 service / repository 层要顺手核对一次：
  - 是否还存在别的入口（例如别的 screen / use case）也依赖同一服务并且会遇到相同 cache/refresh 问题
  - 如果发现，列在 SUMMARY 的 "Related Risk" 里 — 本次不修，但要让用户能看到
- **明确不做：** 全首页 widget 的 refresh 行为审计

### 根因深度 — 「深挖为什么不一致」
- 必须先回答清楚：**为什么"首页总支出"这条 provider 链能感知插入，而这两个不能**
- 路径：
  1. 找到首页总支出 widget 的 provider 链路 — 它 watch 什么？上游怎么在插入时自动失效（stream? FutureProvider depending on Notifier? ref.invalidate?）
  2. 找到悦己统计 / 本月最爱 widget 的 provider 链路 — 同上
  3. diff 两条链路，把"断在哪一环"明确写出来
- 修复时按照"总支出那条已验证可工作"的模式对齐，而不是临时拼一个新机制
- 根因记录写进 PLAN.md（must_haves）和 SUMMARY.md（Root Cause 段）

### Claude's Discretion
- 测试策略：未在讨论中锁定。默认按 TDD：能加 widget test / unit test 就加，不能就在 SUMMARY 注明手测步骤；不强制 80% 覆盖率（本次是 bug fix，不是新功能）
- iOS 真机/模拟器验证：默认跑一次 `flutter analyze` 必须 0 issue；如改动只在 Dart 层、不涉及 native，跳过 iOS 重新构建
- "服务层一致性检查"的具体边界：检查 repository / DAO / use case 层是否有缓存层；不下探到 Drift schema 层

</decisions>

<specifics>
## Specific Ideas / Hypothesis Pool

待研究阶段验证，**不是结论**：

1. **DAO 流没监听** — 总支出可能用 `watchAll()` 或 stream provider，自动 emit；悦己统计/本月最爱可能用 `FutureProvider` 一次性 fetch
2. **wrong filter** — 悦己统计可能 watch 了带 `ledgerType=soul` 过滤的 provider，但插入路径没触发该 provider 的 invalidation（family 参数不命中）
3. **本月最爱有内部 cache** — 可能是 application 层服务里有 in-memory cache，没在写入时清理
4. **autoDispose 误用** — `autoDispose` provider 在 widget 重建之间被销毁并重新计算，看似刷新，但实际 keepAlive 配置不当导致结果被缓存
5. **MonthlyFavorite 计算窗口** — "本月最爱"如果是按月聚合的 expensive 查询，可能加了节流/防抖

</specifics>

<canonical_refs>
## Canonical References

- `CLAUDE.md` — Riverpod 3 conventions section（特别注意 `valueOrNull` → `value`、`StateNotifierProvider` 的 ref.listen 规则、ProviderException 包裹）
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — state mgmt 决策（如存在）
- `lib/data/repositories/` — repository 层实现
- `lib/application/accounting/` — transaction 写入 use case
- `lib/application/analytics/` — 本月最爱/悦己统计很可能在此（per CLAUDE.md "MOD-007 Analytics" 描述）
- `lib/features/home/` 或 `lib/features/dashboard/` — 首页 widget 实际位置（待 researcher 确认）

</canonical_refs>
