# 首页/记账 UI 优化 + 反应式刷新修复 + 编辑页删除 (quick 260603-nr1)

**日期:** 2026-06-03
**时间:** 17:42
**任务类型:** 功能开发 / Bug修复
**状态:** 已完成
**相关模块:** MOD-001 BasicAccounting / 首页 / List

---

## 任务概述

6 项已锁定 UI/反应式修改：① 记账反馈重设计（统一顶部成功/错误胶囊 + 金额校验 + 连续记账不关页 + 共享暖色确认对话框）；② 首页标题图标替换；③ 悦己 bar 去渐变；④ 月度列表项 padding + chevron；⑤ 删除/编辑后首页+分析页反应式刷新；⑥ 编辑页删除功能。

---

## 完成的工作

### 1. 主要变更

**Task 1（#1，commit 92227367）**
- `soft_toast.dart`：新增 `FeedbackTone {success, error}` 变体（success=palette.success/successLight，border/shadow 由 success alpha 派生；默认 error 向后兼容）。
- 新增 `feedback_toast.dart`：顶部 Overlay 统一入口 `showSuccessFeedback`/`showErrorFeedback`。
- 新增 `soft_confirm_dialog.dart`（lib/shared/widgets/）：共享暖色圆角确认对话框。
- `manual_one_step_screen.dart`：空/零金额校验拒绝保存 + 顶部错误吐司；成功后不 popUntil，改为成功吐司 + 表单复位连续记账；移除内联 toast 系统。
- `list_transaction_tile.dart`：滑删确认改用 showSoftConfirmDialog。
- 三语 ARB 新增 `pleaseEnterAmount` + `successKeepGoing` + gen-l10n。

**Task 2（#2 #3，commit bea205f8）**
- home_hero_card：悦己充盈 header → `Icons.eco`，本月最爱 header → `Icons.workspace_premium`。
- `_splitBar` 悦己段去 LinearGradient → 纯色 palette.joy。
- 10 个 home_hero_card golden 重拍。

**Task 3（#4 #5 #6，commit 618ba6cf）**
- list_transaction_tile：padding horizontal 10→16，金额后加 chevron_right(18px/textSecondary)。
- 新增 `invalidate_transaction_dependents.dart`（lib/shared/utils/，普通函数）：失效 list+calendar（keyed）+ today/monthly/happiness/bestJoy（family）。
- list_screen.invalidateAfterMutation 委托共享 helper。
- transaction_edit_screen：AppBar 红色删除按钮 → 确认对话框 → 删除 → pop(true)。
- 6 个 list_transaction_tile golden 重拍。

### 2. 技术决策
- success 吐司不新增 palette token，由 success alpha 派生 border/shadow（最小改动）。
- 连续记账复位需把默认类目显式 push 入 form（GlobalKey 保留 form 内部 state，仅改 config 不会复位）。
- Home/Analytics provider 整族 invalidate，list/calendar keyed invalidate。
- 编辑页无 active year/month，靠 caller pop(true) 触发失效。

### 3. 代码变更统计
- 修改/新增 ~17 个文件（3 新建 helper + 6 生产文件 + 3 ARB + 2 测试 + 16 golden PNG）。

---

## 遇到的问题与解决方案

### 问题 1: 2 个既有测试断言旧行为
**症状:** manual_one_step 测试断言保存后 pop；list tile 测试断言 AlertDialog。
**原因:** 锁定决策 #1 移除了 popUntil 并把对话框换成自定义 Dialog。
**解决方案:** Rule 1 更新测试断言——页面保持打开 / `find.byType(Dialog)` + 2 TextButton。核心断言（use case 调用一次）保留。

---

## 测试验证

- [x] flutter analyze 0 issues（touched files）；全项目 4 遗留非本次 issue
- [x] flutter gen-l10n 通过
- [x] flutter test 2297/2297 全绿（含 golden）
- [x] Task 2/3 golden --update-goldens 重拍并复跑确认

---

## Git 提交记录

```
92227367  feat(quick-260603-nr1): unified top feedback toast + soft confirm dialog + amount guard
bea205f8  feat(quick-260603-nr1): home title icons + flat joy bar (#2 #3)
618ba6cf  feat(quick-260603-nr1): list padding+chevron + reactive invalidation + edit-screen delete (#4 #5 #6)
```

---

## 后续工作

- 手验（设备）：连续记账不关页观感、删除/编辑后首页+分析页即时刷新、编辑页删除流。

---

## 参考资源

- PLAN/CONTEXT: `.planning/quick/260603-nr1-ui-feedback-icons-list-fixes/`
- 配色权威: `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`

---

**创建时间:** 2026-06-03 17:42
**作者:** Claude Opus 4.8
