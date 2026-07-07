# Quick 260707-hb8 — 列表搜索性能 (B) + 架构执法对齐 (C)

**日期:** 2026-07-07
**时间:** 22:48
**任务类型:** [重构 / 性能 / 测试 / 架构决策]
**状态:** 已完成
**相关模块:** MOD-001 (List)、MOD-007 (Analytics)、架构测试

---

## 任务概述

承接上个 session 中断的技术债修复（接力包 `260707-hb8-HANDOFF.md`）。上个 session 走
gsd-quick 时派出的 gsd-executor 因工具间歇 no-op 两次「幻觉完成」（编造 commit、零落盘）。
本 session 由主 Claude 直接读接力包、亲手 TDD 实现，不派任何 subagent 写代码，每步 git 核验落盘。

范围（用户已锁定）：
- **B 性能**：P2-1 列表搜索防抖 + select 分层；P2-3 成员聚合 SQL 下沉。（P2-2 分页明确排除）
- **C 架构执法**：补 `application→data` 方向的架构测试；对齐 import_guard yaml 声明。

---

## 完成的工作

### 1. B / P2-1 — 列表搜索从 SQL 路径剥离 + 输入防抖 (commit `95b12c18`)

真实浪费不在内存过滤，而在 `state_list_transactions.dart` `ref.watch(listFilterProvider)`
watch 整个对象 → searchQuery 每变一次整个 provider 重建（Step 4 SQL + 全行 ChaCha20 解密白跑），
而 searchQuery 只在内存搜索（Step 6b）用到。

- 拆两层 provider：`listTransactionsBase`（SQL + 结构管线，对 search 免疫）+ `listTransactions`
  （只叠加 locale-aware 内存搜索）。
- searchQuery 剥离用两个 Freezed 值等价投影 provider（`listFilterSansSearch` / `listSearchQuery`）
  实现——search-only 变更产出 `==` 相等值，Riverpod 跳过通知 → base 不重建。
- 5 处 refresh/invalidate 站点（下拉刷新、增改删后、全量重置）改为 invalidate base；watch/read 仍在 main。
- 搜索输入框 300ms 防抖；显式清除（X / 清空 / 提交）绕过并取消挂起的 debounce。

### 2. B / P2-3 — 成员分类聚合 SQL 下沉 (commit `bfb73107`)

`memberFilteredCategoryBreakdown` 原走 `findByBookIds` 拉全窗口所有行 + Dart 循环累加。

- 新 DAO `getMemberCategoryTotals`：`GROUP BY category_id`，条件 `device_id = ?` 子句
  （deviceId 为 null 时整段省略，绝不与 NULL 比较）。
- 贯通 AnalyticsRepository 接口 + impl（映射到 `CategoryTotal`）。
- provider 折叠行为 `MemberFilteredCategoryBreakdown`（total / entryCount / 百分比）。

### 3. C / Task 2 — application→data 架构测试 + demo 豁免 (commit `ff3ac7ad`)

`layer_import_rules_test.dart` 加第 4 条规则：application 层（组合根 `*_providers.dart` 除外）
不得 import `lib/data/`。4 个组合根合法放行；`demo_data_service.dart` 经 `_allowlist` 正式豁免。

### 4. C / Task 3 — import_guard yaml 对齐 + 补 applock/onboarding 守卫 (commit `ea3ce6a7`)

- application/data/infrastructure 三个层界 yaml 加 INERT 头注释（指向架构测试为真执法点），保留 deny 规则不删。
- 补 applock/onboarding 的 presentation 层 import_guard.yaml（补齐覆盖缺口）。
- CLAUDE.md Pitfall #2 措辞更新，注明架构测试现覆盖 application→data 方向。

---

## 技术决策

1. **P2-1 分层必须拆两个 provider**：Riverpod 单 provider 无法「部分重建」，整个 build 重跑。
   要让 searchQuery 变更跳过 SQL，必须把 SQL 隔离进一个 search 不 invalidate 的 provider。
2. **用值等价投影而非 `.select`**：本仓库生成的 `$NotifierProvider` 不暴露 `.select`，且全仓零先例。
   改用两个 `@riverpod` 投影 provider + Riverpod「重建到 `==` 相等值即跳过通知」的核心语义——
   更稳、更贴合本仓已依赖的模式。
3. **刷新改指向 base**：拆 provider 后「刷新数据」语义应打在数据层（base），main 因 watch base 级联刷新。
4. **deviceId=null 的 SQL 空值安全**：条件省略 `device_id` 子句，绝不 `device_id = NULL`（SQL 恒 false 陷阱）。
5. **demo_data_service 正式豁免（用户拍板）**：零调用者、固定种子、0 测试的非生产演示生成器；
   重构需动 CategoryRepository 接口（invalid_override 连锁）+ 手工 hash 链，无保护网，收益倒挂。

---

## 遇到的问题与解决方案

### 问题 1: `.select` 在生成的 NotifierProvider 上不可用
**症状:** `listFilterProvider.select(...)` 编译报错 `The method 'select' isn't defined`。
**原因:** Riverpod 3 代码生成的 `ListFilterProvider extends $NotifierProvider` 未暴露 `.select`；全仓无先例。
**解决:** 改用两个投影 provider（`listFilterSansSearch` / `listSearchQuery`）+ 值等价跳过通知。

### 问题 2: 拆 provider 破坏了下拉刷新 (LIST-04 回归)
**症状:** 既有测试 `LIST-04 pull-to-refresh ... use case called again` 失败——invalidate `listTransactionsProvider` 不再重跑 SQL。
**原因:** SQL 移到 base；invalidate main（搜索层）只重读缓存的 base。
**解决:** 5 处 invalidate 站点改指向 `listTransactionsBaseProvider`（既有测试即为此 fix 的 RED）。

### 问题 3: 接口新增方法波及手写 fake (invalid_override 连锁)
**症状:** AnalyticsRepository 加 `getMemberCategoryTotals` 后，两个手写 `implements` fake 报缺实现 error。
**原因:** 手写 fake（非 mocktail）必须实现接口全部方法。
**解决:** 两个 screen 测试的 fake 各补一个 `throw UnimplementedError()` 桩（这两个测试不走成员筛选路径）。

### 备注: 接力包方法名/行号不可靠
接力包引用的 `getCategoryTotalsByLedger` / `getMemberSpending` 在 DAO 中不存在（上个 session 工具故障产物），
且 analytics DAO 零 device_id SQL——实为首次新增。已亲自核验列名 `device_id`、边界 `>= AND <=` 与旧路径等价后落地。

---

## 测试验证

- [x] TDD RED-first：每个行为先写失败测试并亲眼看它按预期失败，再实现
- [x] 全量 `flutter analyze` = 0 issues
- [x] 全量 `flutter test` = 3733 passed + 11 skipped, 0 failed（较基线 +5 新测试）
- [x] `dart run custom_lint` = No issues found
- [x] 每步 git 核验落盘（未 tail flutter test，看退出码）
- 新增测试：搜索分层（execute 计数）、防抖 widget 测试、DAO 成员聚合（成员/deviceId=null/entrySource/排序）、
  provider 装配、扩展的架构测试第 4 条规则

---

## Git 提交记录

```
ea3ce6a7 chore(quick-260707-hb8): mark layer-boundary import_guard yamls INERT + add applock/onboarding guards
ff3ac7ad test(quick-260707-hb8): enforce application->data layer rule + exempt demo_data_service
bfb73107 perf(quick-260707-hb8): push member category breakdown aggregation to SQL
95b12c18 perf(quick-260707-hb8): layer list search off the SQL path + debounce input
```

（基线 HEAD `6a517ec4`，均直接顺序原子 commit 于 main，`use_worktrees=false`）

---

## 后续工作

- [ ] P2-2 列表分页：本次明确排除，另排正式 phase。
- [ ] import_guard yaml 全量 reconciliation（P2 残余）：其余 ~40 个 feature 守卫仍为 deny-mode inert，
      未逐一标注；本次只对齐层界三 yaml + 补 applock/onboarding。
- [ ] 架构测试盲区：`layer_import_rules_test.dart` 仍不查 `*→data` 之外的 `→data` 方向
      （如 infrastructure→data）——审计该方向仍需手动 grep。
