---
quick_id: 260804-rjw
title: 最近支出与明细同日账目按创建时间倒序
type: fix
scope: transaction-ordering
branch: main
worktree: false
---

# Quick Task 260804-rjw — 最近支出与明细同日账目按创建时间倒序

## Task

修复交易展示顺序：

- 首页“最近支出”按 `createdAt` 从最近到最远排列，个人账本和家庭合并模式一致。
- 明细默认日期排序仍按账目日期分组；同一自然日内按 `createdAt` 从最近到最远排列。
- 明细的金额排序保持原有行为。

## Tasks

### T1 — 写回归测试并修正数据查询排序

- files: `lib/data/daos/transaction_dao.dart`,
  `test/unit/data/daos/transaction_dao_test.dart`,
  `test/unit/data/daos/transaction_dao_multi_book_test.dart`
- action: 单账本查询改为 `created_at DESC, id DESC`；多账本日期排序改为
  “自然日按选择方向、日内 `created_at DESC, id DESC`”，金额排序不变。
- verify: DAO 定向测试覆盖账目时间与创建时间相反、跨日及金额排序场景。
- done: 两个 DAO 测试文件全绿。

### T2 — 修正家庭首页跨账本合并顺序

- files: `lib/features/home/presentation/providers/state_today_transactions.dart`,
  `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart`
- action: 家庭首页合并后按 `createdAt DESC`，并以 id 倒序作稳定兜底。
- verify: provider 测试构造账目时间与创建时间相反的数据，断言较晚创建的账目在前。
- done: 首页 provider 定向测试全绿。

## Verification gate

- `dart format` 仅格式化本任务 Dart 文件。
- 三组定向测试全绿。
- `flutter analyze` 0 issues。
