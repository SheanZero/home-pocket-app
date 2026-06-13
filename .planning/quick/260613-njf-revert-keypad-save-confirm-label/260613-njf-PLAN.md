---
phase: quick-260613-njf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
  - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
autonomous: true
requirements: [QUICK-260613-NJF]
must_haves:
  truths:
    - "改动2 已撤销：编辑页头部金额键盘按动作键只把金额写回 form（headline display + updateAmount/updateOriginalAmount），不触发整条目保存、不 pop 屏幕"
    - "编辑页外币键盘（currency-aware 模式）动作键文案为「确认」(S.of(context).confirm)，不再是「保存」(save)"
    - "JPY 路径动作键文案仍为「记录」(record) —— 不在本次范围"
    - "OCR / Voice 的 AmountEditBottomSheet 行为零回归（它们用 JPY 模式 record，未受影响）"
    - "flutter analyze 0 issues；flutter test 全绿"
  artifacts:
    - path: "lib/features/accounting/presentation/screens/transaction_edit_screen.dart"
      provides: "_editAmount / _editForeignAmount 恢复为纯 write-back（无 confirmed 标志、无 _save() 调用）"
    - path: "lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart"
      provides: "currency-aware 动作键 label = confirm（替代 save）"
  key_links:
    - from: "amount_edit_bottom_sheet.dart actionLabel"
      to: "S.of(context).confirm"
      via: "_isCurrencyAware ? confirm : record"
      pattern: "S.of(context).confirm"
---

<objective>
撤销 quick 260613-n5c 的「改动2」（编辑页金额键盘动作键 = 整条目保存），恢复键盘动作键的**原始 write-back 语义**；同时把编辑页外币键盘动作键的文案从「保存」改成「确认」。

背景：260613-n5c 改动2（commit `ce64a4d8`）让编辑页 `_editAmount`/`_editForeignAmount` 在键盘确认后调用 `_save()` 完成整条目保存并 pop。用户决定撤销该行为：键盘动作键只确认/写回金额，不保存整条、不返回；整条目保存仍由屏幕底部「保存」按钮负责。并把键盘上误导性的「保存」字样改为「确认」。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@lib/features/accounting/presentation/screens/transaction_edit_screen.dart
@lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
@test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart

# 撤销的精确参照（改动2 的完整 diff）：
# git show ce64a4d8
# 改动2 之前的 TEST 5（外币 live-update，不 pop）：
# git show ce64a4d8^:test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
</context>

<design_notes>
1. `confirm` ARB key 已存在于全部 3 个 ARB（zh「确认」/ ja「確認」/ en「Confirm」，key 行 185）。无需新增 ARB key，无需 gen-l10n。
2. 撤销范围**仅限改动2**。260613-n5c 的「改动1」（汇率日期触发器显示实际日期，commit `3af79040` + golden `08c87829`）**保留不动**。
3. 改动1 引入的 `rateDate` prop、DateFormatter 显示、golden 基线**全部保留**，不要回退。
4. 撤销后 `_editAmount`/`_editForeignAmount` 应回到 260613-mgc 时的纯 write-back 形态（见 `git show ce64a4d8^:...transaction_edit_screen.dart` 对应方法）：onConfirm 内 setState 写回 display + `_formKey.currentState?.updateAmount/updateOriginalAmount`，**不**设 confirmed 标志、**不** await _save()。删除改动2 新增的相关注释段。
5. label：`amount_edit_bottom_sheet.dart` 中 `actionLabel: _isCurrencyAware ? S.of(context).save : S.of(context).record` → 把 currency-aware 分支改为 `S.of(context).confirm`；同步更新该处注释（外币编辑现为「确认」语义）。JPY 分支 `record` 不动。
</design_notes>

<tasks>

<task type="auto">
  <name>Task 1: 撤销改动2代码 + 外币键盘动作键 save→confirm</name>
  <files>lib/features/accounting/presentation/screens/transaction_edit_screen.dart, lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart</files>
  <action>
1) `transaction_edit_screen.dart`：把 `_editAmount` 与 `_editForeignAmount` 恢复为纯 write-back（参照 `git show ce64a4d8^:lib/features/accounting/presentation/screens/transaction_edit_screen.dart` 中这两个方法的改动2之前版本）。删除 `var confirmed = false;`、onConfirm 末尾的 `confirmed = true;`、以及 `await show(...)` 之后的 `if (confirmed && mounted) await _save();`。删除改动2 关于 whole-entry save 的 doc 注释，恢复原 doc 注释（仅 write-back）。`_save()` 方法本身保留不动（底部保存按钮仍用）。
2) `amount_edit_bottom_sheet.dart`：`actionLabel: _isCurrencyAware ? S.of(context).save : S.of(context).record` → currency-aware 分支改为 `S.of(context).confirm`。更新上方注释（「Foreign edit confirms with the 确认 (confirm) semantics; JPY mode keeps the record label」）。
  </action>
  <verify>
    <automated>flutter analyze lib/features/accounting/presentation/screens/transaction_edit_screen.dart lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart</automated>
  </verify>
  <done>analyze 0；键盘动作键只写回金额（不 _save、不 pop）；外币键盘动作键文案 = confirm。</done>
</task>

<task type="auto">
  <name>Task 2: 撤销改动2测试 + 更新 label 断言 + 全量验证</name>
  <files>test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart</files>
  <action>
1) 撤销改动2 在该测试文件引入的内容（参照 `git show ce64a4d8` 的 test diff）：
   - TEST 5 恢复到改动2之前的契约（外币键盘确认 → headline 更新为新值、卡内日元随之 live 重算、**屏幕不 pop**、不调用 update use case 进行整条目保存）。参照 `git show ce64a4d8^:...transaction_edit_screen_amount_test.dart` 的 TEST 5 原文。
   - 删除改动2 新增的 TEST 6（JPY record 键整条目保存）与 TEST 7（swipe 不保存）—— 这两个断言的是已被撤销的 whole-entry-save 行为。
   - 删除改动2 为观察 pop 结果而新增、且其它测试不再需要的脚手架（route launcher / onPopped / 仅服务于 TEST5-7 的 mock use-case 捕获）。其它既有测试（TEST 1/2/3/4 等）保持原样。
2) label 断言：任何在 sheet 内 `find.text('Save')`/`find.text('保存')` 定位外币键盘动作键的查找，改为 `find.text('Confirm')`/对应 locale 的「确认」。确保 TEST 5 仍能正确点到外币键盘动作键。
3) 全量验证：`flutter analyze`（0）+ `flutter test`（全量，含架构测试 hardcoded_cjk_ui_scan，不可跳过）。改动1 的 golden 不应受影响（label 在 bottom sheet，不在 currency_linked golden 内）；若任何 golden 意外变动，停下报告，不要盲目 --update-goldens。
  </action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>analyze 0；flutter test 全绿；TEST 5 为纯 write-back 契约、TEST 6/7 已移除；OCR/Voice sheet 测试未改仍绿；改动1 相关测试与 golden 未受影响。</done>
</task>

</tasks>

<verification>
- 编辑页：点头部金额 → 键盘按动作键（外币显示「确认」/ JPY 显示「记录」）→ 仅写回金额、屏幕停留、不保存整条；底部「保存」按钮仍负责整条目保存。
- 改动1 保留：汇率日期触发器仍显示实际日期 `2026/06/13`。
- OCR / Voice 零回归。
- flutter analyze 0；flutter test 全绿。
</verification>

<success_criteria>
- 改动2 行为完全撤销（键盘动作键回到 write-back，无整条目保存、无 pop）。
- 编辑页外币键盘动作键文案 = 「确认」。
- 改动1 不受影响。
- 全量 flutter test + analyze 通过。
</success_criteria>

<output>
Create `.planning/quick/260613-njf-revert-keypad-save-confirm-label/260613-njf-SUMMARY.md` when done
</output>
