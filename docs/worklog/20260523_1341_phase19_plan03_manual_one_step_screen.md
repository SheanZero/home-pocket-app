# Phase 19 Plan 03: ManualOneStepScreen Single-Screen Manual Entry

**日期:** 2026-05-23
**时间:** 13:41
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-001] Basic Accounting — Manual Entry

---

## 任务概述

实现 Phase 19 的核心 artifact：`ManualOneStepScreen`，将原先分散的 `TransactionEntryScreen` + `TransactionConfirmScreen` 两步流合并为单屏幕体验。同时实现零依赖的 `KeyboardToolbar` 浮动工具栏、将语音/路由/Shell 入口改点到新屏幕，并在同一波次删除已废弃的旧屏幕（P19-B1 编译窗口修复）。

---

## 完成的工作

### 1. 主要变更

**新建文件 (2):**
- `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` (114 lines)
  - 44dp 高度浮动工具栏，零新依赖，深色模式适配
  - 渐变 Record 按钮 (`AppColors.actionGradientStart/End`)，isSubmitting 状态显示 `CircularProgressIndicator`
  - Done / Record 按钮使用 ARB i18n key (`keyboardToolbarDone`, `record`)

- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` (455 lines)
  - `ConsumerStatefulWidget`，10 个构造函数参数（`bookId` required + 9 optional initial values）
  - `_canSave` gate (P19-W1): `_selectedCategory != null && !_isSubmitting`
  - `_showSmartKeypad` gate (D-05): `_amountFocused && !_isTextFieldFocused`
  - 每个文本字段独立 FocusNode 监听器 (P19-W3)，equality guard 防重复 setState
  - `AnimatedSlide(offset: Offset(0, _showSmartKeypad ? 0 : 1), duration: 220ms)` for SmartKeyboard
  - `Stack+Positioned(bottom: viewInsetsBottom)` 浮动 KeyboardToolbar (D-11/D-13)
  - `Scaffold(resizeToAvoidBottomInset: false)` 阻止系统自动上推
  - `_initializeDefaultCategory` 从旧 TransactionEntryScreen 原样移植 (D-24)
  - `_save` 使用 `GlobalKey<TransactionDetailsFormState>` + `submit()` + `Navigator.popUntil`

**修改文件 (3):**
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`
  - 导入换 `manual_one_step_screen.dart`，push 目标换 `ManualOneStepScreen`（带 voice 参数）

- `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart`
  - 导入换 `manual_one_step_screen.dart`，builder 换 `ManualOneStepScreen`

- `lib/features/home/presentation/screens/main_shell_screen.dart`
  - 导入换 `manual_one_step_screen.dart`，FAB push 目标换 `ManualOneStepScreen`

**删除文件 (2) — P19-B1:**
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` (344 lines)
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (198 lines)

**测试文件 (1, TDD):**
- `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` (551 lines)
  - 8 个 testWidgets 全部通过
  - 覆盖: SC-1 渲染/smoke, 焦点机器 (amountFocused/textFieldFocused), P19-W1 category guard toast, SC-4 digit+save, 各覆盖设计规格

### 2. 技术决策

- **D-05 SmartKeyboard 动画:** `AnimatedSlide` 而非 `AnimatedContainer`，避免需要精确测量高度同时保持流畅滑入滑出
- **D-11/D-13 KeyboardToolbar 浮动:** `Stack+Positioned(bottom: viewInsetsBottom)` 让工具栏永远贴在系统键盘顶部，不随 Scaffold 自动上推
- **D-12 零依赖:** KeyboardToolbar 手写实现，使用已有 `AppColors`/`AppTextStyles`
- **P19-W3 FocusNode 方案:** 每个文本字段独立 FocusNode，addListener 回调在 `initState`，避免 Focus widget Walker 方案的延迟
- **P19-B1 timing:** 旧屏幕删除与 router/shell 改点在同一波次提交，保证 merged git tree 始终绿色编译

### 3. 代码变更统计

- 新增文件: 3 (keyboard_toolbar.dart, manual_one_step_screen.dart, 测试文件)
- 删除文件: 2 (transaction_entry_screen.dart, transaction_confirm_screen.dart)
- 修改文件: 3 (voice_input_screen.dart, entry_mode_navigation_config.dart, main_shell_screen.dart)
- 净增行数: 约 +580 lines (扣除 2 个删除的旧屏幕 ~542 lines)

---

## 遇到的问题与解决方案

### 问题 1: Worktree 路径漂移
**症状:** 首次 `flutter analyze` 报告目标文件 "does not exist on disk"
**原因:** 文件被写入主 repo 路径 (`/Users/xinz/Development/home-pocket-app/lib/...`) 而非 worktree 路径
**解决方案:** 通过 `git rev-parse --show-toplevel` 确认 worktree 根路径，后续所有文件操作均使用 worktree 绝对路径

### 问题 2: Riverpod 3 `Override` 类型找不到
**症状:** 测试文件编译错误 `'Override' isn't a type`
**原因:** Riverpod 3 中 `Override` 移至 `package:flutter_riverpod/misc.dart`，不在主 entrypoint
**解决方案:** 在测试文件头部添加 `import 'package:flutter_riverpod/misc.dart';`

### 问题 3: SC-4 digit-tap+save 测试失败
**症状:** `mockCreateUseCase.execute` 从未被调用（"No matching calls"）
**原因:** `TransactionDetailsForm.initState` 只读一次 `initialCategory`。`_initializeDefaultCategory` 异步完成后 setState 触发新 config，但 form 内部 `_category` 已初始化为 null 不会重读
**解决方案:** SC-4 测试改为预先传入 `initialCategory: _l2Category`，使 form 初始化时即有 category

### 问题 4: 未使用方法编译警告
**症状:** `_selectCategory`、`_selectDate` 被报告为 `unused_element`
**原因:** 这两个方法从旧屏幕移植但实际由 `TransactionDetailsForm` 内部处理，外部不需要调用
**解决方案:** 删除两个方法及其相关未用导入

### 问题 5: `locale` 变量未使用警告
**症状:** `unused_local_variable` warning
**原因:** `final locale = localeAsync.value ?? const Locale('ja')` 但 locale 从未在 build 中使用（form 内部处理）
**解决方案:** 改为 `ref.watch(currentLocaleProvider)` 无变量赋值，仅触发 rebuild

---

## 测试验证

- [x] 单元测试通过 (8 testWidgets, flutter test)
- [x] 静态分析通过 (flutter analyze lib/ — 0 issues)
- [x] 无旧屏幕名称引用 (grep -c 返回 0)
- [x] 代码审查完成 (自检)
- [x] 文档已更新 (SUMMARY.md)

---

## Git 提交记录

```
Commit: d26268e
feat(19-03): create KeyboardToolbar handwritten widget

Commit: f17bd04
feat(19-03): create ManualOneStepScreen single-screen manual entry

Commit: 963b33e
feat(19-03): repoint voice/router/shell to ManualOneStepScreen (D-15/D-16)

Commit: 2dd1a13
test(19-03): widget tests for ManualOneStepScreen — SC-1 + focus machine + P19-W1/W3

Commit: c17b93b
chore(19-03): P19-B1 delete transaction_entry_screen + transaction_confirm_screen

Commit: ca5d6e4
docs(19-03): complete ManualOneStepScreen plan summary
```

---

## 后续工作

- [ ] Plan 04: SmartKeyboard 与 ManualOneStepScreen 集成测试 (端到端键盘流程)
- [ ] Plan 05: 清理 test/ 目录中仍引用旧屏幕的测试文件
- [ ] 验收: 在真实设备上确认 KeyboardToolbar 的 `viewInsetsBottom` 定位与不同键盘高度的兼容性

---

## 参考资源

- PLAN.md: `.planning/phases/19-manual-one-step-keypad-polish/19-03-PLAN.md`
- SUMMARY.md: `.planning/phases/19-manual-one-step-keypad-polish/19-03-SUMMARY.md`
- 设计规格: Phase 19 pattern map (D-05, D-11, D-12, D-13, D-15, D-16, D-24)
- Riverpod 3 migration notes: CLAUDE.md section "Riverpod 3 conventions"

---

**创建时间:** 2026-05-23 13:41
**作者:** Claude Sonnet 4.6
