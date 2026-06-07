# Phase 36 Plan 03: LedgerTypeSelector Move + shopping_list Import Guards

**日期:** 2026-06-07
**时间:** 21:08
**任务类型:** 重构
**状态:** 已完成
**相关模块:** Phase 36 — Data Layer + Domain + Import Guard

---

## 任务概述

执行 Phase 36 Plan 03：将 `LedgerTypeSelector` 从 `lib/features/accounting/presentation/widgets/` 移动到 `lib/shared/widgets/`，更新所有消费方导入路径（包括 2 个测试文件），并为 `shopping_list` 功能树创建 3 个 `import_guard.yaml` 文件以在任何 shopping_list 源文件创建之前建立层边界执行。

---

## 完成的工作

### 1. 主要变更

**Task 1 — 移动 LedgerTypeSelector:**
- 创建 `lib/shared/widgets/ledger_type_selector.dart` — 内部导入路径更新为新位置的相对路径
- 更新 `lib/features/accounting/presentation/widgets/transaction_details_form.dart` 第36行导入
- 更新 `test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart` 导入
- 更新 `test/widget/features/accounting/presentation/widgets/transaction_details_form_smoke_test.dart` 导入
- 删除旧文件 `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`

**Task 2 — 创建 shopping_list import_guard YAML 文件:**
- `lib/features/shopping_list/domain/import_guard.yaml`: 5条拒绝规则 (data/infra/app/presentation/flutter)
- `lib/features/shopping_list/domain/models/import_guard.yaml`: 允许列表 (dart:core, freezed_annotation, LedgerType)
- `lib/features/shopping_list/presentation/import_guard.yaml`: 允许 CategorySelectionScreen + 拒绝 infra/daos/tables

### 2. 技术决策

- **相对导入路径**: 使用 `../../features/accounting/domain/models/transaction.dart` 而非 package-absolute path，遵守 `prefer_relative_imports` analyzer 规则
- **CategorySelectionScreen allow-list**: 该 screen 依赖 accounting 专有 providers，不能移至 shared/，因此通过 allow-list 使依赖明确可审计
- **发现额外消费者**: 全项目 analyze 发现 2 个测试文件也导入了旧路径，已一并修复

### 3. 代码变更统计

- 创建文件: 4 个 (1 dart + 3 yaml)
- 修改文件: 3 个
- 删除文件: 1 个

---

## 遇到的问题与解决方案

### 问题 1: package-absolute 导入触发 prefer_relative_imports 警告

**症状:** `flutter analyze` 报 1 个 info: `Use relative imports for files in the 'lib' directory`
**原因:** 初始使用了 `package:home_pocket/features/accounting/domain/models/transaction.dart`
**解决方案:** 改为相对路径 `../../features/accounting/domain/models/transaction.dart`

### 问题 2: 两个测试文件导入旧路径

**症状:** `flutter analyze` 报 `Target of URI doesn't exist: 'package:home_pocket/features/accounting/presentation/widgets/ledger_type_selector.dart'`
**原因:** `entry_widgets_dark_mode_test.dart` 和 `transaction_details_form_smoke_test.dart` 使用旧 package path
**解决方案:** 更新两个测试文件导入为 `package:home_pocket/shared/widgets/ledger_type_selector.dart`

---

## 测试验证

- [x] `dart run custom_lint --no-fatal-infos` → 0 violations
- [x] `flutter analyze` on modified files → 0 issues
- [x] All 4 consumer import sites updated (1 source + 2 tests + old file deleted)
- [ ] Full project `flutter analyze` → 17 issues (全部来自 Plan 36-01/02 的 test scaffold 文件，引用尚未创建的 shopping_item 类，非本计划引入)

---

## Git 提交记录

```
d4935ebc feat(36-03): move LedgerTypeSelector to lib/shared/widgets/
bad0eff5 feat(36-03): create import_guard.yaml files for shopping_list feature tree
44e421cb docs(36-03): complete LedgerTypeSelector move + shopping_list import guards plan
```

---

## 后续工作

- [ ] Plan 36-04: 创建 shopping_list domain models (ShoppingItem, ShoppingListFilter, ShoppingItemParams)
- [ ] Plan 36-05: 创建 shopping_item_repository.dart 接口
- [ ] Plan 36-06: 创建 ShoppingItemDao + ShoppingItemRepositoryImpl
- [ ] Plan 36-07: 完成 Phase 36 验证

---

## 参考资源

- `.planning/phases/36-data-layer-domain-import-guard/36-03-PLAN.md`
- `.planning/phases/36-data-layer-domain-import-guard/36-03-SUMMARY.md`

---

**创建时间:** 2026-06-07 21:08
**作者:** Claude Sonnet 4.6
