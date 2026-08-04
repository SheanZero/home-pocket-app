---
quick_id: 260804-rjw
title: 最近支出与明细同日账目按创建时间倒序
type: fix
scope: transaction-ordering
status: complete
branch: main
worktree: false
commit: 9cacf498
---

# 260804-rjw · 最近支出与明细同日账目按创建时间倒序

## What changed

- 首页个人账本查询改为 `created_at DESC, id DESC`，最近创建的账目优先显示。
- 首页家庭模式跨主账本/影子账本合并后同样按 `createdAt DESC` 排序，并以 id
  倒序作稳定兜底。
- 明细默认日期排序改为“自然日按用户选择的升/降方向排列，日内固定按
  `created_at DESC, id DESC`”；金额排序保持原样。

## TDD

- RED：构造账目时间与创建时间相反的数据，单账本、家庭合并、明细日内排序共
  3 条断言在旧实现下失败。
- GREEN：实现后 DAO + 首页 provider 定向测试 27/27 通过；相关仓储、列表用例
  36/36 通过。

## Verification

- `flutter analyze`：0 issues。
- 相关测试：63 passed / 0 failed。
- 全量 `flutter test -r expanded`：4417 passed / 11 skipped / 7 failed；7 个失败均位于
  本任务开始前或执行期间已有未提交改动覆盖的路径（5× voice PTT、1× settings
  golden、1× shopping mock architecture），与本次交易排序文件无交集。
- 无 schema、generated、ARB、golden 或依赖变更。
