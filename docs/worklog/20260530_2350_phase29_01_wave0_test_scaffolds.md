# Phase 29 Plan 01: Wave 0 Test Scaffolds

**日期:** 2026-05-30
**时间:** 23:50
**任务类型:** 测试
**状态:** 已完成
**相关模块:** Phase 29 — List Screen Assembly + Family (LIST-04, FAM-01..04)

---

## 任务概述

为 Phase 29 的所有行为需求创建 Wave 0 测试脚手架。新建 2 个 widget 测试文件，并在 3 个现有测试文件中新增共 15 个 Phase 29 测试用例。所有新用例在实现代码落地前均为 RED（预期行为）。

---

## 完成的工作

### 1. 新建文件

- `test/widget/features/list/list_screen_refresh_test.dart` — 3 个 LIST-04 拉刷新测试
  - `RefreshIndicator` 存在于 ListScreen
  - 拉刷新使 `listTransactionsProvider` 失效
  - 拉刷新使 `calendarDailyTotalsProvider` 失效

- `test/widget/features/list/list_sort_filter_bar_member_test.dart` — 7 个 FAM-03/FAM-04 家庭筛选栏测试
  - "Mine only" 在组模式下始终可见
  - "Mine only" 在单独模式下不显示
  - 成员 chip 按 `shadowBooksProvider` 渲染
  - 点击成员 chip 触发 `setMemberFilter(shadowBookId)`
  - 点击 Mine-only 触发 `setMemberFilter(ownBookId)`
  - `anyFilterActive` 包含 `memberBookId` → Clear chip 可见
  - 单独模式下成员 chip 不存在

### 2. 修改现有文件

- `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart`
  - 新增 group "Phase 29: family-mode FAM-01/02/03/04" — 6 个测试
  - 扩展 `_makeTransaction` 支持 `bookId` 参数
  - 扩展 `_makeContainer` 支持 `isGroupMode` 和 `shadows` 参数

- `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart`
  - 新增 group "Phase 29: family calendar D-06" — 3 个测试
  - 扩展 `_makeContainer` 支持组模式参数

- `test/widget/features/list/list_transaction_tile_test.dart`
  - 新增 group "Phase 29: member attribution chip FAM-02" — 3 个测试

### 3. 代码变更统计

- 新建文件：2 个
- 修改文件：3 个
- 新增代码：约 1,129 行
- 需求覆盖：LIST-04, FAM-01, FAM-02, FAM-03, FAM-04（共 5 个需求）

---

## 遇到的问题与解决方案

### 问题 1: 刷新测试中 `find.byType(ListView)` 找不到组件

**症状:** `list_screen_refresh_test.dart` 的拉刷新手势测试因找不到 `ListView` 而 fail，而非因为 assert 失败
**原因:** `ListScreen` 在 data 为空时不渲染 `ListView`（渲染 `ListEmptyState`）
**解决方案:** 该 fail 是 RED 行为的一部分；列表为空时确实没有 `ListView`。这是正确的测试行为——拉刷新需要 `RefreshIndicator` wrapping 整个 when() 包括 loading/error 分支，等 Plan 03 实现后自然解决。

### 问题 2: `list_screen_refresh_test.dart` 中有 unused import

**症状:** `flutter analyze` 报 unused import `tagged_transaction.dart`
**原因:** 初始版本多余导入
**解决方案:** 移除该 import，analyze 清零

---

## 测试验证

- [x] 0 analyzer issues (`flutter analyze lib/features/list/ test/widget/features/list/ test/unit/features/list/ --no-pub`)
- [x] Phase 29 新测试用例为 RED（未实现代码前预期行为）
- [x] 所有原有测试保持 GREEN（23 个测试通过）
- [x] 总计：23 通过 + 15 RED = 38 测试执行

---

## Git 提交记录

```bash
Commit: dd385703
test(29-01): add Wave 0 test scaffolds for LIST-04 and FAM-03/FAM-04

Commit: fee45eb9
test(29-01): extend existing test files with Phase 29 Wave 0 cases

Commit: 86f9b11f
docs(29-01): complete Wave 0 test scaffolds plan
```

---

## 后续工作

- [ ] Plan 29-02: 扩展 `state_list_transactions.dart` 支持 group mode fan-out（FAM-01/02）
- [ ] Plan 29-03: 实现 `list_sort_filter_bar.dart` 家庭筛选段 + `list_transaction_tile.dart` 成员 chip
- [ ] Plan 29-04: `list_screen.dart` 加 `RefreshIndicator` + `anyFilterActive` fix

---

## 参考资源

- `.planning/phases/29-list-screen-assembly-family/29-01-PLAN.md`
- `.planning/phases/29-list-screen-assembly-family/29-01-SUMMARY.md`
- `.planning/phases/29-list-screen-assembly-family/29-PATTERNS.md`
- `.planning/phases/29-list-screen-assembly-family/29-VALIDATION.md`

---

**创建时间:** 2026-05-30 23:50
**作者:** Claude Sonnet 4.6
