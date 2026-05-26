# 添加账目 form 三卡重排 + 用途/Purpose 改名 + 底部留白裁剪 + Picker 后键盘恢复

**日期:** 2026-05-26
**时间:** 13:59
**任务类型:** UI polish / Bug 修复（4 合 1 quick task）
**状态:** 4/5 任务已完成（Task 5 等待人工 UI 验证）
**相关模块:** Accounting / TransactionDetailsForm / ManualOneStepScreen
**Quick Task:** 260526-j98

---

## 任务概述

针对 v1.3 milestone shipped 后用户反馈的 4 个 UI/交互 polish 项目（截图 #7 layout、截图 #8 whitespace）做出对症修复。本次任务在主分支上以 4 个原子 commit 落地，无新增 ARB key、无 golden 更新。

---

## 完成的工作

### 1. 主要变更

**Item 1：将 TransactionDetailsForm 拆分为 3 张卡片**
- Card A: 分类 / 日期 / 商家（merchant 行作为 DetailInfoCard.trailing）
- Card B: 用途 + LedgerTypeSelector + (soul) SatisfactionEmojiPicker
- Card C: 备注（独立卡片，与 Card B 同样的 14dp 圆角 + AppColors.card 背景）
- 卡间 16dp `SizedBox`
- 新增 `_formCard({required Widget child})` helper 复用 Card B / Card C 的容器装饰
- 将原 `_buildStoreAndMemoSection` 拆为 `_buildMerchantRow` 和 `_buildNoteSection`
- 保留 `ValueKey('merchant-textfield')` / `ValueKey('note-textfield')` 及所有 `merchantFocusNode` / `noteFocusNode` 接线
- 文件：`lib/features/accounting/presentation/widgets/transaction_details_form.dart`

**Item 2：`expenseClassification` 改名**
- zh: 支出分类 → 用途
- ja: 支出分類 → 用途
- en: Expense Type → Purpose
- `@expenseClassification.description` 不变（仍为 "Ledger type section title"，语义仍准确）
- 文件：`lib/l10n/app_{zh,ja,en}.arb`
- 运行 `flutter gen-l10n` 重新生成 `lib/generated/app_localizations_*.dart`（gitignored）

**Item 3：底部留白裁剪**
- 删除 `_computeSmartKeypadHeight(BuildContext)` 方法（无其他调用方）
- `scrollPaddingBottom = math.max(viewInsetsBottom, smartKeypadHeight)` → `math.max(viewInsetsBottom, 32.0)`
- SmartKeyboard 在 `Expanded` 之后的 `AnimatedSlide` 里，物理上占据自己的空间；scrollable 的底部 padding 只需要 clear IME 即可
- 文件：`lib/features/accounting/presentation/screens/manual_one_step_screen.dart`

**Item 4：Picker 关闭后恢复 SmartKeyboard 焦点**
- 在 `TransactionDetailsFormConfig.$new(...)` 上新增可选字段 `VoidCallback? onPickerDismissed`
- 重新运行 `build_runner build --delete-conflicting-outputs` 重新生成 `transaction_details_form_config.freezed.dart`
- 在 form 内提取 `_notifyPickerDismissed()` helper，调用 `widget.config.maybeWhen($new: (...) => onPickerDismissed?.call(), orElse: () {})`
- `_editDate`：在 `showDatePicker` 返回后无论 picked 是否为 null 都调用 dismissal callback
- `_editCategory`：cancel 路径（早期 `return`）和 success 路径都调用 dismissal callback
- 在 `ManualOneStepScreen` 提取 `_restoreKeypadFocus()` helper（从 `_onAmountTap` 重构出来），并作为 `onPickerDismissed` 传入 `TransactionDetailsFormConfig.$new(...)`
- 其他宿主（voice / OCR review / edit）无需修改：默认 null = no-op
- 同步更新 `transaction_details_form.dart` 所有 6 个 `$new:` 解构 lambda 加上第 12 个 positional 参数

### 2. 技术决策

- **3 卡片对所有宿主统一应用**（plan §shared_form_decision Q6 (a)）：voice / OCR review / edit 宿主已经渲染 note 区域，拆成独立卡只是多出 16dp 间距和一圈圆角，视觉上更一致，无 layout breakage
- **`onPickerDismissed` 在 `.$new` 上挂载**：voice / OCR review 宿主传 `.$new` 但不传该字段（默认 null），edit 宿主用 `.edit` 结构上不存在该字段
- **`_notifyPickerDismissed` 用 `maybeWhen`**：而非 `when`，保证 `.edit` 模式（结构上无该字段）安全 no-op
- **底部 padding 用 root-cause fix**：用户拒绝任何 `Align(topCenter)` 的 workaround，直接根治留白来源

### 3. 代码变更统计

| 文件 | 变更 | 备注 |
|---|---|---|
| `lib/l10n/app_zh.arb` | 1 行 | expenseClassification 值改 |
| `lib/l10n/app_ja.arb` | 1 行 | expenseClassification 值改 |
| `lib/l10n/app_en.arb` | 1 行 | expenseClassification 值改 |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | +200/-160 | 3-card split + _formCard helper + _notifyPickerDismissed + 6 个 $new: lambda 加 12th positional |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | +12/-38 | 删除 _computeSmartKeypadHeight + 抽取 _restoreKeypadFocus + 接入 onPickerDismissed |
| `lib/features/accounting/domain/models/transaction_details_form_config.dart` | +5 行 | 加 onPickerDismissed 字段 + 一行 WHY 注释 |
| `lib/features/accounting/domain/models/transaction_details_form_config.freezed.dart` | +23/-2 | build_runner 重新生成 |

---

## 遇到的问题与解决方案

### 问题 1: 第 12 个 positional 必须重命名所有 5+ 个 $new: 解构点
**症状:** 加完 freezed 字段后，`flutter analyze` 报 5 个 lambda arity mismatch
**原因:** Freezed 生成的 `when`/`maybeWhen` 把 factory 的 named param 映射为 positional lambda 参数；新增一个就要在所有解构点同步加
**解决方案:** `grep -n '\$new:'` 列出所有 site，逐一加 `onPickerDismissed`（在使用处）或 `p12`（在不使用处）

### 问题 2: dart format 把 if-without-block 风格暴露为 lint
**症状:** Task 3 完成后 `flutter analyze` 报一条 `curly_braces_in_flow_control_structures` info
**原因:** 原代码 `if (initialMerchant != null) _storeController.text = initialMerchant;` 是单行 if，被 formatter 拆成两行后触发 lint
**解决方案:** 改为正式 block `{ ... }`，符合项目 lint 规范

### 问题 3: Phase 22 voice mic button golden 测试失败
**症状:** Task 4 `flutter test test/widget/features/accounting/` 运行时，`voice_input_screen_mic_button_golden_test.dart` 出现 12.74% 像素差异
**原因:** VoiceInputScreen 内部渲染 TransactionDetailsForm；Item 1 的 3-card 重排虽然 golden 抓取的是 `find.byKey(ValueKey('voice-mic-button'))`，但 `matchesGoldenFile` 实际把 widget 在 layout context 中绘制——form 的卡片增加使 mic button 在屏幕上的位置和包围盒发生变化
**解决方案:** 该 golden 失败是 Item 1 的预期副作用（plan §golden_tests_note 错误地断言"不会影响 voice mic button golden"）。Plan §out_of_scope 明确禁止更新 golden 文件。按 SCOPE BOUNDARY 规则记录到 SUMMARY 的 "Deviations from Plan"，由人工验证步骤决定是否在后续 quick task 中重新基线

---

## 测试验证

- [x] `flutter analyze`（仓库全量）— 4 pre-existing issues（无本次任务相关）
  - 2 条 `category_selection_screen.dart` deprecation info（Phase 18 历史代码）
  - 1 条 firebase_messaging 第三方构建产物 warning
  - 1 条 firebase_messaging 第三方代码 info
- [x] `flutter analyze` 本次任务触及的 3 个文件：0 issues
- [x] `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form*.dart`：29/29 通过
- [x] `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`：10/10 通过
- [⚠] `flutter test test/widget/features/accounting/`：1 个 pre-existing-ish 失败：voice_input_screen_mic_button_golden_test 的 idle golden 因 Item 1 layout 变化而失败（见上"问题 3"）
- [ ] Task 5 人工 UI 验证（pending — checkpoint:human-verify）

---

## Git 提交记录

```bash
a5723d9 feat(260526-j98): split form into 3 cards and rename expenseClassification to 用途/Purpose
80b9f4b fix(260526-j98): trim form bottom padding from full keypad height to 32dp
95e32b7 feat(260526-j98): restore SmartKeyboard focus after date/category picker dismissal
fedf995 chore(260526-j98): regenerate freezed for TransactionDetailsFormConfig.onPickerDismissed
```

基于 `ba9f6de` (chore: remove REQUIREMENTS.md for v1.3 milestone) 之上，分支 `main`。

---

## 后续工作

- [ ] Task 5（checkpoint:human-verify）：在 iOS Simulator 上验证 plan §Task 5 的 10 项视觉/交互 checklist
- [ ] 如人工验证通过 → orchestrator 写 SUMMARY.md 标记 verified
- [ ] 决定是否需要单独 quick task 重新基线 `voice_input_screen_mic_button_idle.png`（建议合并到下一个 milestone 的 VOICE-POLISH-V2 phase）

---

## 参考资源

- Plan：`.planning/quick/260526-j98-form-restructure-note-card-rename-paddin/260526-j98-PLAN.md`
- 同源 keypad-restore 修复参考：260526-inb（IME dismiss 后键盘恢复）
- shared_form 决策：plan §shared_form_decision Q6 (a) — 3 卡片对 4 宿主统一应用

---

**创建时间:** 2026-05-26 13:59
**作者:** Claude Opus 4.7 (1M context)
