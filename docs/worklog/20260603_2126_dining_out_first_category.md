# 外出就餐提为食費第一子类目（v19 Migration）

**日期:** 2026-06-03
**时间:** 21:26
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-001] Basic Accounting — Default Categories + DB Migration

---

## 任务概述

将「外出就餐」(`cat_food_dining_out`) 调整为食費 (`cat_food`) 一级类目下的第一个二级类目 (`sortOrder=1`)，
使手动记账页打开时默认选中「食費 → 外出就餐」，减少用户最常见记账场景的操作步骤。

---

## 完成的工作

### 1. 主要变更

- `lib/shared/constants/default_categories.dart`: `cat_food_dining_out` sortOrder 2→1，`cat_food_groceries` sortOrder 1→2
- `lib/data/app_database.dart`: schemaVersion 18→19，新增 `if (from < 19)` 升级路径
- 新建 `test/unit/data/migrations/category_v19_dining_out_first_test.dart`（9 tests）
- Bug fix（Rule 1）: 修复 5 个已有迁移测试文件中 `equals(18)` → `greaterThanOrEqualTo(minimum_version)`

### 2. 技术决策

- sortOrder 数值直接修改，不调整 Dart 列表顺序（运行时按 `sort_order ASC` 排序）
- `is_system = 1` 过滤保护用户自定义类目不受迁移影响
- 两条独立幂等 UPDATE，无需事务包裹

### 3. 代码变更统计

- 修改文件: 7
- 新建文件: 1
- 净增测试: +9

---

## 遇到的问题与解决方案

### 问题 1: 已有迁移测试在 schemaVersion 升至 19 后全部失败

**症状:** 全量测试出现 5 个失败，错误信息 "expected: <18>, actual: <19>"
**原因:** 5 个已有迁移测试文件均将 `_targetSchemaVersion = 18` 与 `equals()` 配合使用，而非 `greaterThanOrEqualTo`
**解决方案:** 将各文件的 `_targetSchemaVersion` 改回对应迁移的最低版本号（15/16/17/17/18），并改用 `greaterThanOrEqualTo` 断言

---

## 测试验证

- [x] 单元测试通过 (2312/2312)
- [x] 迁移测试全绿（含新建 9 个）
- [ ] 手动测试验证（需在设备上打开手动记账页确认默认「食費→外出就餐」）
- [x] flutter analyze 0 new issues
- [ ] 文档已更新（worklog 本文件）

---

## Git 提交记录

```
Commit: 77a4833a
test(260603-ti2): swap cat_food sortOrder + add v19 migration test (RED)

Commit: 9a555830
feat(260603-ti2): schemaVersion 18→19 + v19 dining_out sort_order migration (GREEN)
```

---

## 后续工作

- [ ] 手动验证：在设备/模拟器上运行 App，打开手动记账页，确认默认「食費 → 外出就餐」
- [ ] 验证升级路径：数据库从 v18 升级后 sort_order 正确更新

---

## 参考资源

- Plan: `.planning/quick/260603-ti2-category/260603-ti2-PLAN.md`
- Summary: `.planning/quick/260603-ti2-category/260603-ti2-SUMMARY.md`

---

**创建时间:** 2026-06-03 21:26
**作者:** Claude Sonnet 4.6
