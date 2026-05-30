# Family-Aware List Providers — Multi-Book Fan-Out + ARB Key

**日期:** 2026-05-30
**时间:** 23:56
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 29 — List Screen Assembly + Family

---

## 任务概述

实现家庭模式下列表数据提供者的多账本合并逻辑。`state_list_transactions.dart` 扩展为支持 shadow book fan-out、memberTag 填充和 SQL 级别的成员过滤收窄；`state_calendar_totals.dart` 扩展为每账本循环调用 `getDailyTotals` 并合并日计。同时为全部 3 个 ARB 文件添加 `listMineOnly` 键。

---

## 完成的工作

### 1. state_list_transactions.dart — Step 3 + Step 7 扩展

- Step 3: `final bookIds = [bookId]` → 多行扩展: `isGroupModeProvider` watch + `shadowBooksProvider.future` await + bookIds fan-out + `bookIdToShadow` 查找表 + `effectiveBookIds` SQL 级别成员过滤
- Step 4: `GetListParams.bookIds` 改用 `effectiveBookIds`（非原始 `bookIds`）
- Step 7: `.map((tx) => TaggedTransaction(transaction: tx, memberTag: null))` → 基于 `bookIdToShadow[tx.bookId]` 的条件 MemberTag 构造；own-book 行始终 null（D-01/SC#3）
- 新增导入: `state_active_group.dart`、`state_shadow_books.dart`

### 2. state_calendar_totals.dart — 多账本循环

- 替换单账本调用为 per-book loop: `allBookIds` 遍历 + `merged` map 累加
- CRITICAL: 从不 watch `listFilterProvider`（Pitfall 3 / D-06）
- provider 签名 `(bookId, year, month)` 保持不变
- 新增导入: `state_active_group.dart`、`state_shadow_books.dart`

### 3. ARB 文件 — listMineOnly 键

- `app_en.arb`、`app_ja.arb`、`app_zh.arb` 均在 `listClearAll` 之后插入 `listMineOnly: "Mine only"`
- 执行 `flutter gen-l10n` 成功，无警告
- `arb_key_parity_test` 通过

### 4. 代码变更统计

- 修改文件: 5（2 Dart + 3 ARB）
- Dart 新增行: ~70
- 全部分析通过: `flutter analyze lib/features/list/presentation/providers/ — 0 issues`

---

## 遇到的问题与解决方案

### 问题 1: Step 7 中 tx 类型是 Transaction 而非 TaggedTransaction

**症状:** PATTERNS.md 中写的是 `tx.transaction.bookId`，但实际 `txs` 来自 use case，元素类型为 `Transaction`
**原因:** PATTERNS.md 的 Step 7 代码假设了错误的变量类型
**解决方案:** 改用 `tx.bookId`（Transaction 的直接属性）

### 问题 2: lib/generated/ 文件被 .gitignore 排除

**症状:** `git add lib/generated/...` 失败（gitignored）
**原因:** `.gitignore` 包含 `lib/generated/` 规则
**解决方案:** 只提交 source ARB 文件，生成文件本地保留

---

## 测试验证

- [x] 单元测试通过: `list_transactions_provider_test.dart` — 15/15 (含 6 个 Phase 29 FAM-01/02/03/04 测试)
- [x] 单元测试通过: `calendar_totals_provider_test.dart` — 10/10 (含 3 个 Phase 29 D-06 测试)
- [x] 架构测试通过: `arb_key_parity_test.dart` — passed
- [x] 静态分析: 0 issues
- [x] flutter gen-l10n: 成功

---

## Git 提交记录

```bash
Commit: 197ca242
feat(29-02): expand listTransactionsProvider — group-mode bookIds + memberTag + member filter

Commit: 37143115
feat(29-02): expand calendarDailyTotalsProvider + add listMineOnly ARB key

Commit: 7ed8b003
docs(29-02): complete family-aware providers plan — listTransactions + calendarTotals + listMineOnly ARB
```

---

## 后续工作

- [ ] Plan 03: list_transaction_tile.dart — member attribution chip UI (FAM-02 widget layer)
- [ ] Plan 04: list_sort_filter_bar.dart + list_screen.dart — family segment + RefreshIndicator (FAM-03/04 widget layer)

---

## 参考资源

- `.planning/phases/29-list-screen-assembly-family/29-02-PLAN.md`
- `.planning/phases/29-list-screen-assembly-family/29-PATTERNS.md`

---

**创建时间:** 2026-05-30 23:56
**作者:** Claude Sonnet 4.6
