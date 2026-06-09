# 购物清单交互与样式升级 (参考第三方 to-do 应用)

**日期:** 2026-06-09
**时间:** 11:06
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-008] Shopping List (shopping_list feature)
**Quick Task:** 260609-ec2

---

## 任务概述

借鉴第三方 to-do 应用的样式升级购物清单交互，同时保留 home-pocket 既有的「全部 / 日常·悦己 / 分类」双轨账本过滤体系。四项需求：① 左侧圆形完成图标（点击 toggle 完成）；② filter 左对齐 + 右侧 ≡ 进入手动拖拽排序模式；③ 点击 item 本体进入编辑；④ 右侧显示数量（quantity>1 才显示）。改动集中在 presentation 层，schema 保持 v20，无 Drift migration。

---

## 完成的工作

### 1. 主要变更

**新增排序模式 provider（Task 1）**
- `lib/features/shopping_list/presentation/providers/state_shopping_reorder.dart`：`@Riverpod(keepAlive: true) class ShoppingReorderMode`，`bool build() => false`，方法 `toggle()` / `exit()`。生成 `shoppingReorderModeProvider`（Riverpod 3 去 Notifier 后缀）。keepAlive 与 `ShoppingFilter` / `ListType` 一致，跨 IndexedStack tab 持久；纯 UI 状态，不入库。

**重构 tile（Task 1）** `shopping_item_tile.dart`
- 左侧圆形完成图标（24px 视觉 / 44px 命中区）：未完成 = 中性描边空心圆 + 极淡对勾；已完成 = ledger accent 填充圆（daily 绿 / joy 粉 / null 中性绿）+ 白色对勾。点击圆圈 = `toggleItemCompletedUseCase.execute(item.id)`，加 `ValueKey('toggle-<id>')` 稳定测试定位。
- 整行 onTap 改为打开 `ShoppingItemFormScreen`（替换原整行 toggle，D-domain#3）。
- 移除编辑 chevron；数量徽章从名称下方副行移至右侧 trailing（`${quantity}×`，quantity>1 才渲染，D-1）；estimatedPrice 保留在副行。
- 拖拽手柄门控：仅 `reorderMode && isActive` 时渲染 `ReorderableDragStartListener`（D-2）；平时隐藏不可拖。
- 排序模式 / batch 模式锁定其他手势：`gesturesLocked` 时 Dismissible.direction=none、圆圈 onTap=null、整行 onTap=null。

**改造 filter bar（Task 2）** `shopping_filter_bar.dart`
- 外层 `Row`：`Expanded(SingleChildScrollView(chips))` 左对齐 + 右侧固定 ≡/✓ 切换。
- 右侧 `InkWell`（44px 命中区）：非排序 `Icons.reorder`（textSecondary），排序 `Icons.check`（palette.error 红）；onTap → `shoppingReorderModeProvider.notifier.toggle()`；Semantics/Tooltip 用新 ARB key。
- 排序模式下每个 chip 加 `Icons.drag_indicator` 前缀（全部 / segmented control / 分类）。

**i18n（Task 1+2）**
- 3 个 ARB（en/ja/zh）新增 `shoppingToggleComplete` / `shoppingEnterReorderMode` / `shoppingExitReorderMode`，`flutter gen-l10n` 成功。

**测试与 golden（Task 3）**
- `shopping_item_tile_test.dart`：改 DONE-01 为圆圈触发 toggle；新增「body 不 toggle / body 打开编辑表单 / chevron 已删 / quantity×N 徽章 / quantity==1 无徽章 / 排序模式下手柄可见 / 排序模式锁 toggle / 排序模式 Dismissible=none」共 19 项全绿。
- `shopping_filter_bar_test.dart`：新增「≡ 进入排序变 ✓ / 排序模式 chip 前缀」共 9 项全绿。
- 24 个受影响 golden（18 tile + 6 filter bar）`--update-goldens` 重基线。

### 2. 技术决策

- 完成圆圈填充用 item 的 ledger accent（daily/joy），null fallback 到中性绿；走 `context.palette`（ADR-019），未硬编码 hex。
- 排序模式纯 UI bool provider，keepAlive 复用现有 filter provider 模式，避免额外 schema/DAO 改动。
- 排序模式禁用 toggle/编辑/滑删（Claude's Discretion）以避免误操作，仅允许拖拽。
- 屏幕 `SliverReorderableList` 结构无需改：拖拽手柄只在排序模式渲染，非排序模式无法发起拖拽。

### 3. 代码变更统计

- 修改文件：tile、filter bar、3 ARB、4 generated l10n、2 widget test、24 golden PNG；新增 reorder provider (+.g.dart)、2 个 stale provider .g.dart 重生成。
- 提交：3 个原子提交（feat tile / feat filter bar / test+golden）+ docs 提交。

---

## 遇到的问题与解决方案

### 问题 1: stale 生成文件
**症状:** build_runner 后 `repository_providers.g.dart` / `state_shopping_filter.g.dart` 出现 docstring diff。
**原因:** base 提交里这两个生成文件的 docstring 与源不同步（未重新生成）。
**解决方案:** 随 Task 1 一并提交重生成结果（避免 AUDIT-10 stale-generated 拦截）。

### 问题 2: 全量测试 1 项失败（out-of-scope flake）
**症状:** `test/scripts/merge_findings_test.dart` 的 idempotency 子用例在全量并行下失败；单独运行该文件 8/8 全绿。
**原因:** 审计脚本子进程在并行执行下的 byte-identical 输出 flake，与本任务（presentation 层）零耦合。
**解决方案:** 按 scope boundary 不修复，记入 `deferred-items.md`。本任务自身面（analyze 0、shopping widget tests、24 golden、provider_graph_hygiene、hardcoded_cjk_ui_scan）全绿。

---

## 测试验证

- [x] `flutter analyze` 全项目 0 issue
- [x] shopping tile widget test 19/19 绿
- [x] shopping filter bar widget test 9/9 绿
- [x] 24 个受影响 golden 重基线并通过
- [x] `provider_graph_hygiene_test` / `hardcoded_cjk_ui_scan_test` 绿
- [x] `grep 0xFF` tile/filter bar = 0（无硬编码 hex）
- [ ] 全量 `flutter test`：2513 绿 / 1 out-of-scope 审计脚本 flake（见 deferred-items.md）

---

## Git 提交记录

```bash
13055cbd feat: shopping tile leading toggle circle + tap-to-edit + right qty + gated drag handle
22bd25a8 feat: shopping filter bar left-aligned chips + trailing reorder toggle
(Task 3 commit follows: test + golden re-baseline + worklog)
```

---

## 后续工作

- [ ] 审计脚本 `merge_findings.dart` 并行幂等性 flake 稳定化（独立任务，见 deferred-items.md）
- [ ] 可选：为排序模式新增专门的 golden 变体（本次未做，非强制）

---

## 参考资源

- `.planning/quick/260609-ec2-shopping-list-ui-upgrade/260609-ec2-PLAN.md`
- `.planning/quick/260609-ec2-shopping-list-ui-upgrade/260609-ec2-CONTEXT.md`
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`

---

**创建时间:** 2026-06-09 11:06
**作者:** Claude Opus 4.8
