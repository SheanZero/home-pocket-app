# 修复 IME dismiss 与 KeyboardToolbar 视觉问题

**日期:** 2026-05-26
**时间:** 13:31
**任务类型:** Bug修复
**状态:** 已完成（代码层）／待人工设备验证（Task 3 checkpoint:human-verify blocking）
**相关模块:** MOD-001 BasicAccounting / ManualOneStepScreen
**Quick Task ID:** 260526-inb

---

## 任务概述

修复 ManualOneStepScreen（添加账目）截图 260526-inb-2/3/4 反馈的三个缺陷：(1) 系统 IME 通过工具栏 `完成` 或 IME ✓ 键关闭时不会恢复 SmartKeyboard，底部留下 ~40% 灰色空白；(2) IME 工具栏看起来像漂浮的深灰色 pill，应该是平面白色 edge-to-edge；(3) `完成` 按钮纯文字，没有可点击的外框，无法与右侧 `记录` pill 配对识别。范围严格 surgical — 只动 2 个文件，不重构 TransactionDetailsForm，不动 SmartKeyboard / ManualOneStepScreen / 其他 entry hosts。

---

## 完成的工作

### 1. 主要变更

**Task 1 — `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (+4 行)**

- 商家 TextField (`ValueKey('merchant-textfield')`, 第 530 行附近) 新增三个 props：
  - `textInputAction: TextInputAction.done` — 强制 iOS/Android IME 渲染 "Done" / "完了" / "完成" 键
  - `onSubmitted: (_) => FocusScope.of(context).unfocus()` — IME ✓ 键触发 unfocus → ManualOneStepScreen._handleFocusChange 自动恢复 SmartKeyboard
  - `onTapOutside: (_) => FocusScope.of(context).unfocus()` — 点击 TextField 外部任何位置同样恢复
- 备注 TextField (`ValueKey('note-textfield')`, 第 611 行附近) 只新增 `onTapOutside`：
  - 保留多行 Return 换行行为（iOS/Android 多行字段标准约定），不破坏
  - 用户通过工具栏 `完成` 或外部点击关闭 IME

**Task 2 — `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` (+30 / -11 行)**

- 外层 `Material.elevation: 8 → 0` — 去掉投射在 IME 灰色背景上的阴影晕（这是 "深灰色 pill" 错觉的根源）
- 左侧 `Expanded` 完成按钮：裸 `InkWell → Center(Text)` 替换为
  `Padding(horizontal: 12, vertical: 6) → DecoratedBox(card + 1px borderDefault border + 10dp radius) → Material(transparent) → InkWell(onDone, borderRadius: 10) → Center(Text)`
- 文字色 `textSecondary → textPrimary` 以保证白底对比度
- 右侧 `记录` 渐变 pill、顶部 hairline border、44dp 高度、Row 结构完全不动

### 2. 技术决策

- **Issue 1 根因定位（upstream vs downstream）**：`ManualOneStepScreen._handleFocusChange` FocusNode 监听器和 `_showSmartKeypad = _amountFocused && !_isTextFieldFocused` 状态机本身完全正确，问题在 TextField 没设 `textInputAction`，IME 不发 done action，FocusNode 不掉焦。修最上游一处比改下游状态机干净得多。
- **备注字段不加 `textInputAction.done`**：多行 Return 换行是平台标准，强行覆盖会破坏文本编辑体验。保留双通道关闭（toolbar 完成 + onTapOutside）已经覆盖所有用户路径。
- **完成按钮 inline 而非 extract**：当前只有一个调用点，提取 `OutlinedToolbarButton` 是过度抽象。等到第二个调用点出现再提取。
- **不引入新色板/ARB key**：全部复用 `AppColors.card / borderDefault / textPrimary` + `keyboardToolbarDone`（已在 zh/ja/en 三语 ARB 文件 line 909）。

### 3. 代码变更统计

- 修改文件数：2
- 新增行数：+34
- 删除行数：-11
- 净增：+23 行
- 主要文件路径：
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
  - `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart`

---

## 遇到的问题与解决方案

### 问题 1: IME ✓/Done 键不掉焦
**症状:** 用户点 IME 的 ✓ 键，IME 关闭了，但 SmartKeyboard 不恢复，底部留 ~40% 灰色空白。
**原因:** TextField 缺 `textInputAction`，iOS 默认渲染 Return 而不是 Done，Return 不发 onSubmitted 也不掉焦。
**解决方案:** 商家字段加 `textInputAction: TextInputAction.done` + `onSubmitted: unfocus`。备注字段因多行约定不加 textInputAction，靠 `onTapOutside` + toolbar 完成兜底。

### 问题 2: KeyboardToolbar 看起来像深灰色 pill
**症状:** IME 打开时，工具栏看着像漂浮的圆角深灰色岛屿。
**原因:** `Material.elevation: 8` 投射的阴影叠加 IME 自身的灰色背景，视觉上形成 "暗边圆角 pill"。
**解决方案:** `elevation: 0`，保留已有的 `BorderSide(borderDefault)` hairline top 提供分隔，去掉阴影晕。

### 问题 3: 完成按钮看不出是可点的
**症状:** 完成只是裸文字，眼睛只识别右侧 `记录` 渐变 pill，左半边读成 "工具栏背景"。
**解决方案:** 套上 `Padding + DecoratedBox` outlined ghost 框架（1px border + 10dp radius），高度信封与 `记录` 配对。

---

## 测试验证

- [x] `flutter analyze lib/features/accounting/presentation/widgets/transaction_details_form.dart` — 0 issues
- [x] `flutter analyze lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` — 0 issues
- [x] `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` — 10/10 通过（含 SmartKeyboard slide-out、KeyboardToolbar appear-on-focus、Save 行为等关键测试，全部回归通过）
- [x] `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — 6/6 通过（ja/zh/en × light/dark；SmartKeyboard 未改动，golden 未更新）
- [ ] **设备真机/模拟器 UAT 待执行**（Task 3 checkpoint:human-verify blocking gate；本任务已交回 orchestrator → 用户）

---

## Git 提交记录

```bash
Commit: f29a6ef
Date: 2026-05-26
Message: fix(260526-inb): wire IME-done/unfocus on merchant + note TextFields to restore SmartKeyboard

Commit: c57fda6
Date: 2026-05-26
Message: fix(260526-inb): flatten KeyboardToolbar to elevation 0 and add outlined frame to 完成 button
```

---

## 后续工作

- [ ] 用户在真机/模拟器执行 Task 3 的 A/B/C/D/E 验证清单，确认三个 issue 视觉/行为修复成立
- [ ] 若验证通过，回复 "approved"，orchestrator 收尾
- [ ] （可选未来）如出现第二个 outlined toolbar button 调用点，再提取 `OutlinedToolbarButton`

---

## 参考资源

- 计划: `.planning/quick/260526-inb-ime-dismiss-restore-keypad-and-action-ba/260526-inb-PLAN.md`
- 摘要: `.planning/quick/260526-inb-ime-dismiss-restore-keypad-and-action-ba/260526-inb-SUMMARY.md`
- 截图依据: 260526-inb-2/3/4（用户反馈）
- 焦点状态机参考: `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` 第 92, 169–179 行（`_showSmartKeypad` getter + `_handleFocusChange`）
- ARB key: `keyboardToolbarDone` (zh=完成 / ja=完了 / en=Done) @ app_*.arb:909

---

**创建时间:** 2026-05-26 13:31
**作者:** Claude Opus 4.7
