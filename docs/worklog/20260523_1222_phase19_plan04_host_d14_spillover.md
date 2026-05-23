# Phase 19 Plan 04: D-14 Spillover — TransactionEditScreen + OcrReviewScreen

**日期:** 2026-05-23
**时间:** 12:22
**任务类型:** 功能开发
**状态:** 已完成（测试待 P19-B2 合并后验证）
**相关模块:** MOD-001 基础记账 / Phase 19 ManualOneStep Keypad Polish

---

## 任务概述

Plan 01 (Phase 19) 将 AmountDisplay 从 TransactionDetailsForm 内部移除，并新增公开方法 `updateAmount(int)`。这一改动导致两个 Phase 18 宿主屏幕（TransactionEditScreen 和 OcrReviewScreen）失去了金额编辑入口（regression）。

Plan 04 修复这一 regression：让两个宿主屏幕各自在 form 上方渲染自己的 `AmountDisplay`，点击时弹出 `AmountEditBottomSheet`（modal sheet UX），通过 `onConfirm` 回调同步宿主状态和 form 内部状态。

---

## 完成的工作

### 1. 主要变更

**Task 1 — TransactionEditScreen 重构 (commit: 7ef84ea)**
- 新增 import: `amount_display.dart`, `amount_edit_bottom_sheet.dart`
- 新增字段: `late int _displayAmount;`，在 `initState` 中初始化为 `widget.transaction.amount`
- 新增方法: `_editAmount()` — 调用 `AmountEditBottomSheet.show()`，onConfirm 同步 `_displayAmount` + `_formKey.currentState?.updateAmount(v)`
- Body Column 顶部插入 `GestureDetector(behavior: HitTestBehavior.opaque, onTap: _editAmount, child: AmountDisplay(...))`
- 保留不变：`_save()` 中的 `Navigator.of(context).pop(true)`（D-18）；AppBar；`_buildSaveButton()`

**Task 2 — OcrReviewScreen 重构 (commit: 572ce60)**
- 相同模式，`_displayAmount` 初始化使用 `widget.draft.maybeWhen((amount, ...) => amount ?? 0, orElse: () => 0)`
- `MaterialBanner` 保留（Phase 18 D-13），位于 AmountDisplay 之后
- 保留不变：`popUntil((r) => r.isFirst)` (D-13)；`entrySource: EntrySource.manual` (MOD-005 marker D-12)

**Task 3 — Widget 测试 (commit: a48ea93)**
- `transaction_edit_screen_amount_test.dart`: TEST 1 (AmountDisplay + sheet open), TEST 2 (onClear + verifyNever)
- `ocr_review_screen_amount_test.dart`: TEST 3 (draft amount display + sheet open), TEST 4 (empty draft MaterialBanner位置)
- Provider override 模式：参照 `transaction_details_form_update_amount_test.dart`

### 2. 技术决策

- **D-14 invariant 严格遵守**：两个宿主屏幕均使用 modal sheet UX，不引入 SmartKeyboard（持久键盘仅 ManualOneStepScreen 使用）
- **`HitTestBehavior.opaque`**：确保 GestureDetector 的点击区域完整覆盖 AmountDisplay 的整个 padding 区域
- **P19-W5 确定性分支**：TEST 2 使用 `verifyNever` 验证 form 内部的 amount > 0 guard 在调用 use case 之前拦截（category seed 来自 widget.transaction，所以 category guard 不触发）

### 3. 代码变更统计

- 修改文件：2 个（transaction_edit_screen.dart, ocr_review_screen.dart）
- 新增文件：2 个（两个测试文件）
- 新增行数：约 +200 行（production）+ ~290 行（test）
- 删除行数：0 行（保留所有 Phase 18 逻辑）

---

## 遇到的问题与解决方案

### 问题 1: P19-B2 staging gap — 测试编译失败

**症状:**
```
amount_edit_bottom_sheet.dart:157:19:
Error: No named parameter with the name 'actionLabel'.
SmartKeyboard({ actionLabel: S.of(context).record, ... })
```

**原因:**  
`amount_edit_bottom_sheet.dart`（Plan 01 创建）使用了 `SmartKeyboard(actionLabel: ...)` API，但本 worktree 中 `smart_keyboard.dart` 仍使用 `nextLabel:` 参数名（Plan 02 负责重命名）。这是已知的 wave-2 staging gap。

**解决方案:**  
按 runtime_notes 的要求，不修改 `smart_keyboard.dart` 或 `amount_edit_bottom_sheet.dart`。测试文件已正确编写（flutter analyze 0 issues），待 orchestrator 合并 Plan 02 worktree 后，测试将编译并通过（GREEN 阶段）。

### 问题 2: `maybeWhen` 多重下划线 lint 警告

**症状:** `info • Unnecessary use of multiple underscores`

**原因:** 初始代码使用 `(amount, _, __, ___, ____)` 形式

**解决方案:** 改为 `(amount, merchant, date, rawOcrText, imagePath)` 使用实际参数名，0 issues

---

## 测试验证

- [x] `flutter analyze transaction_edit_screen.dart` — 0 issues
- [x] `flutter analyze ocr_review_screen.dart` — 0 issues
- [x] `flutter analyze transaction_edit_screen_amount_test.dart` — 0 issues
- [x] `flutter analyze ocr_review_screen_amount_test.dart` — 0 issues
- [ ] `flutter test` — 待 P19-B2 合并后验证（测试编译需要 Plan 02 的 SmartKeyboard 重命名）
- [x] Phase 18 invariants 检查（grep 验证 pop(true), popUntil, MaterialBanner, EntrySource.manual）
- [x] SmartKeyboard 在两个宿主文件中出现 0 次（D-14 invariant）

---

## Git 提交记录

```
Commit: 7ef84ea
feat(19-04): host-owned AmountDisplay + AmountEditBottomSheet in TransactionEditScreen

Commit: 572ce60
feat(19-04): host-owned AmountDisplay + AmountEditBottomSheet in OcrReviewScreen

Commit: a48ea93
test(19-04): add D-14 spillover widget tests for TransactionEditScreen + OcrReviewScreen
```

---

## 后续工作

- [ ] Orchestrator 合并 Plan 02 + Plan 04 worktrees 后，运行 `flutter test test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart test/widget/features/accounting/presentation/screens/ocr_review_screen_amount_test.dart` 验证 4 个测试 GREEN
- [ ] Phase 18 existing test suite (`ocr_two_step_seam_test.dart` 等) 继续通过（no regression）
- [ ] MOD-005 OCR writer 上线时，将 `entrySource: EntrySource.manual` 改为 `EntrySource.ocr`（D-12 placeholder 已标注）

---

## 参考资源

- `.planning/phases/19-manual-one-step-keypad-polish/19-04-PLAN.md`
- `.planning/phases/19-manual-one-step-keypad-polish/19-CONTEXT.md` D-14 决策
- `.planning/phases/19-manual-one-step-keypad-polish/19-RESEARCH.md` §Pitfall 3 (P19-B2 gap)
- `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart`（Plan 01 产物）
- `test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart`（provider override 参考）

---

**创建时间:** 2026-05-23 12:22
**作者:** Claude Sonnet 4.6
