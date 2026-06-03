# 全局弹窗/提示统一 + 记账成功 toast 增强

**日期:** 2026-06-03
**时间:** 19:05
**任务类型:** 重构（UI 一致性）+ 功能增强
**状态:** 已完成
**相关模块:** 跨模块（accounting / list / home / analytics / settings / family_sync / profile）

---

## 任务概述

用户两点要求：
1. 删除确认弹窗与「已删除」提示仍是旧样式 → 改成新统一样式；并检查全局所有还没改的弹窗/提示，一起改掉。范围 = **全局全部**；输入类弹窗（密码/重命名/选择器）**只换外壳风格**。
2. 记账成功后：toast 时长增长一点、文案改「可以继续记账」、增加「退出记账」link → 点击返回进入记账前的页面。

---

## 完成的工作

### 基础设施（commit 11d8a069）
- `soft_toast.dart` / `feedback_toast.dart` 从 `accounting/presentation/widgets/` 迁到 **`lib/shared/widgets/`**，全局可用、消除跨 feature 依赖。
- `SoftToast` 新增可选 `actionLabel` + `onAction`（内联下划线 link）；`feedback_toast` 的 `showSuccessFeedback/showErrorFeedback` 透传 `duration` / `actionLabel` / `onAction`。
- `app_theme.dart` 新增 **`dialogTheme`**（light+dark：圆角 20、暖卡片、描边、title/content 文字）→ 全局所有 `AlertDialog` 外壳自动统一，输入/选择器弹窗无需逐个改写即获得 soft 外壳。

### Ask 2 — 记账成功反馈增强（commit 11d8a069）
- `manual_one_step_screen` 成功分支：toast 时长 3s→**5s**；文案 `successKeepGoing` 改为「已记录，可以继续记账」(ja/en 同步)；新增 `recordingExitLink`「退出记账」(三语) 作为 link，点击 `Navigator.popUntil(isFirst)` 回到记账前页面。
- 顺手修复 nr1 遗留的 `pleaseEnterAmount` **ARB 重复 key**。

### Ask 1 — 全局反馈/弹窗统一（commits 04242adb / 87d984e8 / 85bb0dc4）
转换规则：成功类 snackbar→`showSuccessFeedback`、错误类→`showErrorFeedback`、确认弹窗→`showSoftConfirmDialog`、输入/选择/单 OK 信息弹窗→保留 AlertDialog（已被 dialogTheme 统一外壳）。

- **part1（交易流程）**：transaction_edit（更新/校验/持久化）、voice_input（保存/错误，保留庆祝禁用后的 pop 流程）、ocr_review、category_selection（排序成功/失败 + 丢弃确认→soft_confirm）、list_transaction_tile（「已删除」→success toast）、home_screen。新增 `discardUnsavedChangesBody` 三语 key。
- **part2（settings/family_sync/profile）**：data_management（导出/导入成功失败 + 删除全部确认→soft_confirm + 删除结果）、group_management（重命名/离开/移除失败→error + 两处确认→soft_confirm）、member_approval、create_group、confirm_join、family_sync_settings、notification_route_listener、profile_edit/onboarding、avatar_picker。
- **cleanup**：analytics `time_window_picker_sheet` 自定义区间校验错误→`showErrorFeedback`。
- 输入/选择器弹窗（password_dialog / group_rename_dialog / joy_target / appearance / voice_section）确认无硬编码 shape/bg，全部由 dialogTheme 覆盖，未改结构。

### 测试同步
- 关键 gotcha：`SoftToast` 启动 `Timer(duration)`，触发 toast 的 widget 测试结尾必须推进时间（`pump(6s)+pumpAndSettle`）否则 teardown 报 pending timer。
- 更新：voice_input_screen_test、member_approval_screen_test、family_sync_notification_route_listener_test（`SnackBar`→`SoftToast`）、time_window_picker_sheet_test（3 个 error-path 加 timer advance）。

---

## 测试验证

- [x] `flutter analyze lib test` → 仅 2 个 pre-existing `onReorder` info（category_selection_screen，非本次），0 新增
- [x] `flutter gen-l10n` 通过（新增 recordingExitLink / discardUnsavedChangesBody，去重 pleaseEnterAmount）
- [x] `flutter test` → **2297/2297 全绿**
- [x] `grep showSnackBar lib` → **0**（反馈全部统一为 toast）

---

## Git 提交记录

```
11d8a069 feat(accounting): 统一反馈基础设施 + 记账成功 toast 增强（Ask 2）
04242adb refactor(feedback): 统一反馈为 toast/soft dialog (全局 sweep part1)
87d984e8 refactor(feedback): 统一反馈为 toast/soft dialog (全局 sweep part2)
85bb0dc4 refactor(feedback): analytics time-window error → toast (sweep cleanup)
```

---

## 后续工作

- [ ] 真机视觉走查：删除/保存/导入导出/家庭同步各反馈的顶部 toast + 输入弹窗新外壳，浅深色各一遍。
- [ ] 可选：toast 连续触发时的堆叠抑制（当前 5s 时长下快速连记可能短暂重叠），如需要可加单例 toast 管理器。

---

**创建时间:** 2026-06-03 19:05
