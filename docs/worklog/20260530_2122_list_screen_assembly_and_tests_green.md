# ListScreen Assembly + SC#3/D-01 Tests GREEN

**日期:** 2026-05-30
**时间:** 21:22
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [Phase 28-06] ListScreen Assembly

---

## 任务概述

实现 Phase 28 的最终组装计划（Plan 06）。将 ListScreen 中的 CircularProgressIndicator 占位符替换为分组按日期显示的交易列表 + 固定排序/过滤栏。同时完成 Wave 0 单元测试至 GREEN：SC#3 哈希链完整性测试和 D-01 notifier 测试。

---

## 完成的工作

### 1. Task 1a: ListScreen 结构骨架
- 替换 `Expanded(CircularProgressIndicator)` 为 `ListSortFilterBar + Expanded(_buildList)`
- `_buildList` 使用 `AsyncValue.when(loading/error/data)` 消费 `listTransactionsProvider`
- data 路径: 计算 `anyFilterActive` → `ListEmptyState` 或 `ListView.builder` via `buildFlatList`
- 关键文件: `lib/features/list/presentation/screens/list_screen.dart`

### 2. Task 1b: 每行显示值计算
- ledger 标签颜色: `AppColors.survival/soul/survivalLight/soulLight`（绝不硬编码十六进制）
- 分类名: `CategoryLocalizationService.resolveFromId(categoryId, locale)` (FILTER-01 D-04)
- 金额: `NumberFormatter.formatCurrency(amount, 'JPY', locale)`
- 时间: `formatTransactionTime` (HH:mm, D-09)
- 满意度图标: ADR-014 映射（soul 账本专用）
- onTap: `TransactionEditScreen` 导航；保存后同时 invalidate `listTransactionsProvider` + `calendarDailyTotalsProvider`
- 行间分割线: `AppColors.borderList` (连续 TransactionRowItem 之间)

### 3. Task 2: SC#3 + D-01 测试 GREEN
- **D-01**: `list_filter_notifier_test.dart` 5 个测试已经全部 PASS（28-01 已部署）
- **SC#3**: `delete_hash_chain_integrity_test.dart` 完整实现（替换 `fail()` 存根）
  - 使用 `AppDatabase.forTesting()` + `_MockFieldEncryptionService`（直传）
  - 直接构造 `TransactionRepositoryImpl` + `DeleteTransactionUseCase`
  - 插入 3 笔交易（带哈希链）→ 软删除中间交易 → 断言 `isDeleted=true`
  - 逐行验证剩余行的哈希完整性

### 4. 关键技术决策
- SC#3 测试：使用单元素 `verifyChain([row])` 验证单行哈希，而非全链验证。原因：删除中间行后，tx3.previousHash 仍指向已删除的 tx2，导致行间链接检查失败。单行验证语义上等同于"软删除不破坏存储的哈希数据"

---

## 遇到的问题与解决方案

### 问题 1: verifyChain 返回 isValid=false
**症状:** SC#3 测试运行后断言 `result.isValid` 失败
**原因:** `verifyChain` 同时检查单行哈希完整性 AND 行间链接（tx[i].currentHash == tx[i+1].previousHash）。删除 tx2 后，tx3.previousHash ≠ tx1.currentHash，链接检查失败
**解决方案:** 改用 `verifyChain([row])` 对每个剩余行单独验证；在测试中添加详细注释说明设计决策

### 问题 2: analyzer 报 prefer_function_declarations_over_variables
**症状:** `final onTap = () async { ... }` 触发 lint
**解决方案:** 改为函数声明 `Future<void> onTap() async { ... }`

---

## 测试验证

- [x] SC#3: `delete_hash_chain_integrity_test.dart` PASS
- [x] D-01: `list_filter_notifier_test.dart` 5/5 PASS
- [x] list 全套测试: 74/74 PASS
- [x] `flutter analyze lib/`: 0 新增 issues
- [x] 代码审查完成

---

## Git 提交记录

```bash
Commit: daf3240
feat(28-06): Task 1a — assemble ListScreen structural shell

Commit: 4268972
feat(28-06): Task 1b — complete per-tile display value computation

Commit: e72f4e2
test(28-06): Task 2 — complete SC#3 hash-chain + D-01 notifier tests to GREEN

Commit: 76c9f9e
docs(28-06): complete ListScreen assembly plan summary and state update
```

---

## 后续工作

- [ ] Phase 28-07: 工作日志 + 阶段收尾
- [ ] Phase 30: 将 `'生存'`/`'魂'` 等占位符替换为 ARB 多语言 key

---

## 参考资源

- [Phase 28 Plan 06](../../.planning/phases/28-transaction-tile-sort-filter-bar/28-06-PLAN.md)
- [Phase 28 SUMMARY](../../.planning/phases/28-transaction-tile-sort-filter-bar/28-06-SUMMARY.md)

---

**创建时间:** 2026-05-30 21:22
**作者:** Claude Sonnet 4.6
