# Phase 19 Plan 01: ARB Key + AmountEditBottomSheet + TransactionDetailsForm Refactor

**日期:** 2026-05-23
**时间:** 11:46
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 19 — Manual One-Step + Keypad Polish (Plan 01)

---

## 任务概述

执行 Phase 19 的第一个计划 (19-01-PLAN.md)。该计划是 Phase 19 的基础层，为后续的 ManualOneStepScreen (Plan 03)、SmartKeyboard 重构 (Plan 02) 和 Phase-18 host 溢出修复 (Plan 04) 提供必需的合同接口。

主要目标：
1. 在三种语言的 ARB 文件中添加 `keyboardToolbarDone` 键并重新生成 S delegate
2. 将表单内部的金额编辑 bottom sheet 提取为独立的 `AmountEditBottomSheet` 组件
3. 重构 `TransactionDetailsForm`：外部化金额、添加 `updateAmount(int)` 方法、添加 ValueKey 标记、添加 FocusNode 配置

---

## 完成的工作

### 1. ARB 键添加 (Task 1)

- 在 `lib/l10n/app_en.arb`、`app_ja.arb`、`app_zh.arb` 中添加 `keyboardToolbarDone` 键
  - en: `"Done"`, ja: `"完了"`, zh: `"完成"`
  - 每个文件包含键值对和 `@keyboardToolbarDone` 元数据
- 运行 `flutter gen-l10n` — 成功，无警告
- 重新生成了 `lib/generated/app_localizations*.dart` 文件
- ARB 一致性测试 (`test/architecture/arb_key_parity_test.dart`) 通过 (P19-B4)

### 2. AmountEditBottomSheet 提取 (Task 2)

- 创建了 `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart`
- 从 `transaction_details_form.dart` 的 `_editAmount()` 方法逐字移植所有处理逻辑
- 公开接口：`AmountEditBottomSheet` 类 + `static Future<void> show(...)` 方法
- **P19-B2 修复**：使用 POST-rename `actionLabel:` API（SmartKeyboard 当前还是 `nextLabel:`，Plan 02 会在同一 wave 内修复）
- 零 `TransactionDetailsForm` 引用（host-agnostic）

### 3. TransactionDetailsForm 重构 (Task 3) — TDD

**RED 阶段（先写失败测试）：**
- 创建了 6 个失败测试覆盖所有新行为

**GREEN 阶段（实现使测试通过）：**

**(A) Freezed config 扩展 (P19-W3)：**
- 在 `$new` factory 中添加 `FocusNode? merchantFocusNode` 和 `FocusNode? noteFocusNode`
- 运行 `build_runner build` 重新生成 `transaction_details_form_config.freezed.dart`

**(B) 表单组件重构：**
- 删除 `_editAmount()` 方法（已提取到 AmountEditBottomSheet）
- 删除 amount `DetailInfoRow`（金额行）
- 删除 `amount_display.dart` 和 `smart_keyboard.dart` 导入
- 删除孤立的 `_formatAmount()` 辅助方法
- 添加 `void updateAmount(int amount)` 公共方法（含幂等性短路判断）
- 添加 ValueKey 标记到 category-chip、date-chip、merchant-textfield、note-textfield (P19-W2)
- 通过 `widget.config.maybeWhen` 将 FocusNode 从配置注入到 TextField (P19-W3)
- 更新所有 `.when/$new` lambda 到新的 11 参数签名

**(C) DetailInfoCard 扩展：**
- 给 `DetailInfoRow` 数据类添加 `Key? key` 字段
- 转发 key 到 `_DetailInfoCardRow({super.key, ...})`

**测试结果：** 6/6 新测试通过，13/13 现有测试继续通过

### 4. 代码变更统计
- 修改文件：12 个
- 创建文件：2 个 (amount_edit_bottom_sheet.dart, test file)
- 删除代码行：~167 行（_editAmount 方法 + 金额行 + 导入 + helper）
- 添加代码行：~310 行（AmountEditBottomSheet + 测试 + updateAmount + ValueKey + FocusNode 配置）

---

## 遇到的问题与解决方案

### 问题 1: `Result.ok` 不存在
**症状：** 测试编译失败，`Member not found: 'Result.ok'`
**原因：** `Result` 类使用 `Result.success` 工厂方法，不是 `Result.ok`
**解决方案：** 修改测试使用 `Result.success()`

### 问题 2: TEST 3 幂等性测试方法错误
**症状：** TEST 3 失败，`Expected: > 1, Actual: 1`
**原因：** 使用 `Builder` 包裹 form 并计数重建次数——但 `Builder` 不会因为 form 的 `setState` 而重建
**解决方案：** 改用 submit 结果验证 + verify-capture 方式，确认状态正确更新且 use case 仅被调用一次

### 问题 3: `DetailInfoRow` 是数据类无法接受 `Key`
**症状：** 无法直接将 `ValueKey('category-chip')` 添加到 `DetailInfoRow`（数据类没有 key 字段）
**原因：** `DetailInfoRow` 是普通 Dart 类不是 Widget，不继承 `Key`
**解决方案：** 给 `DetailInfoRow` 添加 `Key? key` 字段并在 `_DetailInfoCardRow` 中转发

### 问题 4: `$new` 字符串插值错误
**症状：** `build_runner` 失败，`'new' can't be used as an identifier`
**原因：** 测试字符串 `'TEST 6: FocusNode from $new config...'` 中 `$new` 被 Dart 解释为关键字插值
**解决方案：** 改用 raw string `r'TEST 6: FocusNode from $new config...'`

### 问题 5: Dart linter 对多下划线的警告
**症状：** `unnecessary_underscores` info 警告，如 `__, ___` 等
**原因：** Dart 新版本不允许多个下划线作为参数占位符
**解决方案：** 改用具名占位符 `p1, p2, ...p11`

---

## 测试验证

- [x] Task 1: `flutter test test/architecture/arb_key_parity_test.dart` — 2/2 通过
- [x] Task 2: `flutter analyze amount_edit_bottom_sheet.dart` — 仅 actionLabel 预期错误（P19-B2 设计）
- [x] Task 3: `flutter test transaction_details_form_update_amount_test.dart` — 6/6 通过
- [x] Task 3: 现有 smoke + form 测试 — 13/13 继续通过
- [x] `flutter analyze` on form/config/detail_info_card — 0 issues
- [x] `git diff pubspec.yaml pubspec.lock` — 空（D-12: 零新依赖）
- [x] `flutter pub run build_runner build` — 成功，生成 freezed 文件

---

## Git 提交记录

```bash
Commit: 1ab9b56 feat(19-01): add keyboardToolbarDone ARB key in en/ja/zh + regen S delegate
Commit: 1b59372 feat(19-01): extract AmountEditBottomSheet shared widget (POST-rename actionLabel: API)
Commit: 3e4e2b2 test(19-01): add failing tests for updateAmount + ValueKey + FocusNode (RED phase)
Commit: 3a46932 feat(19-01): refactor TransactionDetailsForm — externalize amount, ValueKey markers, FocusNode wiring
Commit: 36673ea docs(19-01): complete plan 01 summary
```

---

## 后续工作

- [ ] Plan 02: SmartKeyboard 重构 — 添加 `actionLabel:` 参数（消除 amount_edit_bottom_sheet.dart 中的 analyze 错误）
- [ ] Plan 03: ManualOneStepScreen — 使用 `updateAmount(int)` + `merchantFocusNode/noteFocusNode` + `keyboardToolbarDone` ARB 键
- [ ] Plan 04: TransactionEditScreen + OcrReviewScreen — 使用 `AmountEditBottomSheet.show(...)` 实现 D-14 host spillover

---

## 参考资源

- `.planning/phases/19-manual-one-step-keypad-polish/19-01-PLAN.md`
- `.planning/phases/19-manual-one-step-keypad-polish/19-01-SUMMARY.md`
- `CLAUDE.md` — Riverpod 3 规范，build_runner 工作流

---

**创建时间:** 2026-05-23 11:46
**作者:** Claude Sonnet 4.6
