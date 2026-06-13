---
phase: quick-260613-mgc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
  - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - test/features/accounting/presentation/edit_currency_linked_test.dart
  - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
  - test/golden/currency_linked_edit_fields_golden_test.dart
autonomous: false
requirements: [QUICK-260613-MGC]
must_haves:
  truths:
    - "Tapping the top headline amount on a FOREIGN edit row opens the existing AmountEditBottomSheet keypad (SmartKeyboard) — no new keypad widget is created"
    - "Editing the headline amount on a foreign row updates the original amount (major→minor units, currency-aware) and live-recomputes the card's derived JPY via the single convertToJpy site"
    - "On a foreign edit row the currency card (rate + JPY) renders ABOVE the category/date card"
    - "The foreign currency card shows only two rows — 汇率 (rate) and 日元（换算）(derived JPY); the 原币金额 (original amount) input row is removed"
    - "JPY-native edit rows are byte-identical: headline tap still opens the JPY sheet, no card reorder, no row removal (CURR-04)"
    - "OCR and Voice screens that also use AmountEditBottomSheet keep their existing JPY-whole-unit behavior unchanged"
  artifacts:
    - path: "lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart"
      provides: "Optional currency-aware (major-unit decimal) mode for the existing keypad sheet"
    - path: "lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart"
      provides: "Two-row card (rate + derived JPY) driven by an externally-supplied original amount"
    - path: "lib/features/accounting/presentation/screens/transaction_edit_screen.dart"
      provides: "Foreign headline tap-to-edit wiring + card reorder"
  key_links:
    - from: "transaction_edit_screen.dart headline GestureDetector"
      to: "AmountEditBottomSheet.show (currency-aware mode)"
      via: "onTap for foreign rows"
      pattern: "AmountEditBottomSheet.show"
    - from: "headline onConfirm"
      to: "TransactionDetailsForm.updateOriginalAmount"
      via: "form GlobalKey imperative push → convertToJpy recompute"
      pattern: "updateOriginalAmount"
    - from: "CurrencyLinkedEditFields"
      to: "convertToJpy"
      via: "derived JPY row from injected original amount × rate"
      pattern: "convertToJpy"
---

<objective>
后续微调 Phase 42 外币明细编辑页（`TransactionEditScreen` + 嵌入的 `TransactionDetailsForm`）的两点交互改动，仅作用于外币明细，不改本币（JPY）行为：

改动1（头部金额可编辑）：外币行点击头部大号金额 → 复用**现有**键盘（`AmountEditBottomSheet` + `SmartKeyboard`，目前 OCR/Voice/JPY-edit 三处已在用）编辑原币金额。不新建键盘组件。

改动2（卡片重排 + 精简）：外币行把"原币金额卡"（`CurrencyLinkedEditFields`）移到"分类/日期卡"之前；并删除卡内"原币金额"输入行，只保留"汇率"和"日元（换算）"两行。原币金额此后由头部金额唯一承担展示+编辑。

Purpose: 让外币明细的金额编辑与新建录入一致（头部即原币金额、点击弹现有键盘），并去掉卡内重复的原币金额输入行。
Output: 改动后的 4 个 lib 文件 + 3 个受影响测试文件的更新。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md

@lib/features/accounting/presentation/screens/transaction_edit_screen.dart
@lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
@lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
@lib/features/accounting/presentation/widgets/transaction_details_form.dart
@lib/features/accounting/presentation/widgets/smart_keyboard.dart
@lib/features/accounting/presentation/widgets/amount_input_controller.dart
@lib/features/accounting/presentation/widgets/currency_edit_strings.dart
@lib/features/accounting/presentation/widgets/amount_display.dart
@lib/shared/utils/currency_conversion.dart

# Tests that pin the CURRENT behavior and MUST be updated to match the new design:
@test/features/accounting/presentation/edit_currency_linked_test.dart
@test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
@test/golden/currency_linked_edit_fields_golden_test.dart
</context>

<design_notes>
重要的既有约束（实现前必须吃透，否则会撞已有锁定决策/测试）：

1. ADR-022 D-01 单向数据流不可破坏：永远 `原币 × 汇率 → 日元`，日元只读，绝不回写。改动1/2 只改"原币金额从哪里输入"（卡内 Row 1 → 头部键盘），不改这条不变量。`convertToJpy` 仍是唯一换算点（`lib/shared/utils/currency_conversion.dart`）。

2. 现有键盘是 JPY 整数语义：`AmountEditBottomSheet` 把 `editStr` 当整数，`onConfirm(parsed.round())` 返回整数 JPY；`initialAmount:int`。外币原币金额是**主单位带小数**（112.90），存储为**次单位整数**（11290 cents）。因此键盘需要新增一个**可选的 currency-aware 模式**（主单位小数输入 → 次单位整数），默认行为对 OCR/Voice/JPY-edit 三处保持字节不变。小数位上限用 `currencyFractionDigitsFor(currency)`，次单位换算用 `subunitToUnitFor(currency)`（两者已存在于 `currency_conversion.dart`，键盘的 `onDot`/4 位 cap 也已支持小数输入）。

3. 原币金额行被删除后，`CurrencyLinkedEditFields` 不再内部拥有原币金额输入：原币金额改为由**外部 prop 注入**（widget.originalAmount 已是 prop），rate 行编辑仍在卡内，日元行仍由 `原币 × 当前rate` 派生。头部键盘确认 → 通过 form 的 GlobalKey 把新原币金额推回 form（`_originalAmount` + `convertToJpy` 重算 `_amount`）→ rebuild → 卡片日元行随之更新。

4. 受影响的现有测试（这些 pin 的是旧设计，必须改成新设计的契约，不要为了过测而弱化断言）：
   - `edit_currency_linked_test.dart`：多处 `enterText(edit_original_amount_field, ...)` 驱动原币金额。新设计里原币金额不再由卡内 TextField 输入 → 这些用例改为通过重新 pump（改变 `originalAmount` prop）来驱动，或迁移到 screen 级测试。删除"两个 TextField"的断言（现在卡内只剩 1 个可编辑 TextField=汇率）。
   - `transaction_edit_screen_amount_test.dart` TEST 3：断言外币头部"非 tappable / 无 clear / 无编辑 sheet" → 改为断言外币头部**可点击并打开 `AmountEditBottomSheet`**。TEST 5：原本 `enterText(edit_original_amount_field,'200')` 驱动头部 live 更新 → 改为通过头部键盘输入 200 后头部显示 200.00、卡内日元行随之更新。TEST 4（JPY-native）必须保持不变。
   - `currency_linked_edit_fields_golden_test.dart`：golden 基于含原币金额行的旧卡（带 `$112.90` 前缀行）。删除该行后卡片视觉变化 → 需在 macOS 重新生成 baseline（CI 非 macOS 用 BaselineExistenceGoldenComparator，不像素比对）。同时更新文件头注释与 `find.text(r'$')`/`find.text('112.90')` 断言（原币金额行已移除）。

5. JPY-native 与本币布局零回归（CURR-04）：`_isForeignRow == false` 时头部仍 `onTap:_editAmount`（JPY 整数 sheet），卡片不重排、不删行（`CurrencyLinkedEditFields` 仅在外币行渲染，本来就不影响 JPY）。

6. i18n / palette / AppTextStyles 规范：所有文案 `S.of(context)` / `CurrencyEditStrings`；颜色 `context.palette`；金额样式 `AppTextStyles.amount*`。不新增硬编码字符串/颜色。本次改动应无需新 ARB key（复用既有 record/save/汇率/日元 等）。
</design_notes>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: 给现有键盘 AmountEditBottomSheet 增加可选 currency-aware（主单位小数）模式</name>
  <files>lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart</files>
  <behavior>
    - JPY 默认模式（不传 currency / 传 'JPY'）：行为字节不变 —— `initialAmount:int` 当整数显示，`onConfirm` 收到 `parsed.round()` 整数。OCR/Voice/edit-JPY 三处调用方不受影响。
    - 外币模式（传 currency='USD' 等 + initialAmount=次单位整数 11290）：sheet 把次单位整数转成主单位小数串 "112.90" 作为初始 editStr；`AmountDisplay` 显示对应 currencySymbol/currencyLabel；小数位上限 = `currencyFractionDigitsFor(currency)`；确认时把主单位小数串按 `subunitToUnitFor(currency)` 转回**次单位整数**回调（onConfirm 仍返回 int，但语义是 minor units）。
    - 0 小数位币种（JPY/KRW）在外币模式下不允许小数点（与录入键盘一致）。
  </behavior>
  <action>给 `AmountEditBottomSheet` 增加可选参数 `currency`（String?，null=既有 JPY 整数模式）、`currencySymbol`、`currencyLabel`，以及 `.show(...)` 同步透传。currency 非空时：用 `currencyFractionDigitsFor(currency)` 求 decimals、`subunitToUnitFor(currency)` 求 subunit（import 自 `lib/shared/utils/currency_conversion.dart`）；初始 editStr 由 `initialAmount`(次单位) 转主单位小数串；`AmountDisplay` 传入 symbol/label；`SmartKeyboard` 的 `actionLabel` 复用 `S.of(context).save`（与头部保存语境一致，外币编辑确认）；`onNext` 解析主单位小数串 → `(major * subunit).round()` 次单位整数后回调。JPY 模式下所有现有逻辑保持原样（不要改 `parsed.round()` 路径）。decimals==0 时禁用小数点（onDot 走与 SmartKeyboard 一致的 disabled 处理）。不得新建键盘组件——继续用现有 `SmartKeyboard`。</action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/screens/ocr_review_screen_amount_test.dart test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart</automated>
  </verify>
  <done>OCR/Voice 既有 JPY-sheet 测试全绿（证明默认模式零回归）；sheet 暴露可选 currency 模式可被 Task 2 调用。</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 头部外币可编辑 + 卡片重排 + 卡内删除原币金额行</name>
  <files>lib/features/accounting/presentation/screens/transaction_edit_screen.dart, lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart, lib/features/accounting/presentation/widgets/transaction_details_form.dart</files>
  <behavior>
    - 外币行：点击头部大号金额 → 打开 Task 1 的 currency-aware `AmountEditBottomSheet`（initialAmount=当前原币次单位 `_displayOriginalMinor`，currency=`_displayCurrency`，symbol/label=头部已算好的 topSymbol/topLabel）。确认后头部更新为新主单位串，卡内日元行随之重算。
    - 外币行：`CurrencyLinkedEditFields` 卡片渲染在 分类/日期卡（DetailInfoCard）之前；卡内只剩汇率行 + 日元（换算）只读行，移除原币金额输入行（含其 `$` 前缀 TextField）。
    - JPY-native 行：头部 tap 仍打开 JPY 整数 sheet（`_editAmount` 原样）、clear 仍在、无卡片、无重排（CURR-04 零回归）。
  </behavior>
  <action>
1) `currency_linked_edit_fields.dart`：删除 Row 1（`edit_original_amount_field` 那段 `_LabeledField`+TextField+前缀符号逻辑）及其内部 `_amountController`/`_onAmountChanged`/`_amountError`/`_majorStringToMinor` 中仅服务于该输入的部分。原币金额改为完全来自 `widget.originalAmount`（用一个由 prop 同步的 `_originalAmount` int 字段，didUpdateWidget 时刷新），日元行与 `_deriveJpy()` 继续用它。保留 `onChanged`/`onAmountInvalid` 语义：rate 编辑或外部原币变化仍触发 `_notify()`。卡片现在含 2 行（汇率可编辑 + 日元只读）+ 日期触发标签。

2) `transaction_details_form.dart`：新增公共命令式方法 `updateOriginalAmount(int minorUnits)`（镜像 `updateRate` 的幂等 + `convertToJpy` 重算 `_amount`；同时清掉 `_foreignAmountInvalid` 当值有效），供 screen 头部键盘确认后推回。把 `CurrencyLinkedEditFields` 移动到 build 中 `DetailInfoCard` 之前（仅外币条件块），保持 `_formCard` 包裹；它的 `originalAmount:` 现绑定 `_originalAmount!`（已是 prop 来源），prop 变化时卡内日元行随 rebuild 更新。`onChanged` 回调维持把 `value.originalAmount/appliedRate/jpyAmount` 同步进 form + `onForeignChanged` 上抛（头部 live 跟随汇率编辑导致的原币不变但日元变化——原币不变故头部不变，符合预期）。

3) `transaction_edit_screen.dart`：外币行头部改为可点击：`onTap: _isForeignRow ? _editForeignAmount : _editAmount`。新增 `_editForeignAmount()`：调用 `AmountEditBottomSheet.show(context, initialAmount:_displayOriginalMinor, currency:_displayCurrency, currencySymbol:topSymbol, currencyLabel:topLabel, onConfirm:(minor){ setState(()=>_displayOriginalMinor=minor); _formKey.currentState?.updateOriginalAmount(minor); })`。注意 topSymbol/topLabel 当前在 build 内局部计算——把它们的派生逻辑抽成一个能在 `_editForeignAmount` 复用的 helper，或在 build 内用闭包捕获后传入。外币行的 `onClear` 维持 null（原币清零通过键盘删空处理，保持读不破坏）。JPY-native 路径完全不动。

所有文案 `S.of`/`CurrencyEditStrings`、颜色 `context.palette`、金额 `AppTextStyles.amount*`。运行 build_runner（若改了 @riverpod/@freezed——本任务预计不需要，但 form 改动后跑一次以防 .g.dart 漂移）。
  </action>
  <verify>
    <automated>flutter analyze lib/features/accounting/presentation/screens/transaction_edit_screen.dart lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart lib/features/accounting/presentation/widgets/transaction_details_form.dart</automated>
  </verify>
  <done>analyze 0 issues；外币头部 tap 打开 currency-aware sheet 并回写原币金额、重算日元；外币卡在分类卡之前、仅含汇率+日元两行；JPY-native 路径与卡片渲染逻辑未改。</done>
</task>

<task type="auto">
  <name>Task 3: 更新受影响测试到新设计契约 + 重生成 golden + 全量验证</name>
  <files>test/features/accounting/presentation/edit_currency_linked_test.dart, test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart, test/golden/currency_linked_edit_fields_golden_test.dart</files>
  <action>
1) `edit_currency_linked_test.dart`：把所有 `enterText(edit_original_amount_field, ...)` 驱动原币金额的用例改为新契约 —— 原币金额现由 `originalAmount` prop 注入，不再有 `edit_original_amount_field` TextField。把这类用例改为重新 `pumpHost(...)` 以不同 `originalAmount` 驱动派生 JPY，或断言 rate 编辑路径。删除/修正"findsNWidgets(2) TextField"断言为"findsOneWidget"（卡内只剩汇率 1 个可编辑 TextField）。保留并保持 D-01/D-02/D-03（rate 重算 JPY、manual-override 弹窗、>1% toast+undo）断言不被弱化。

2) `transaction_edit_screen_amount_test.dart`：
   - TEST 3：删除"外币头部 non-tappable / 无 clear / 无 edit sheet"断言；改为：tap 外币 `AmountDisplay` → `find.byType(AmountEditBottomSheet) findsOneWidget`。保留"头部 badge 显示 USD/$、112.90、不显示 JPY/18,093"与"卡内 edit_jpy_derived 仍含 18,093"断言。
   - TEST 5：原 `enterText(edit_original_amount_field,'200')` 改为：tap 头部打开 currency-aware sheet → 用键盘输入 200（点 '2''0''0'）→ 确认（save）→ 头部显示 '200.00'、旧 '112.90' 消失。
   - TEST 1/2/4（JPY-native）保持不变，确认 CURR-04 零回归。

3) `currency_linked_edit_fields_golden_test.dart`：更新文件头注释（卡片不再有原币金额行）；删除 `find.text(r'$')` / `find.text('112.90')`（原币金额行已移除）相关断言，改为断言剩余两行（汇率 160.2564 / 日元 18,093）的存在。golden baseline 仅在 macOS 重新生成：`flutter test --update-goldens test/golden/currency_linked_edit_fields_golden_test.dart`（CI 非 macOS 用 BaselineExistenceGoldenComparator，不像素比对——参见 MEMORY golden-ci-platform-gate）。

4) 全量验证：`flutter test`（必须跑全量，架构测试如 hardcoded_cjk_ui_scan 不能漏）+ `flutter analyze`（0 issues）。
  </action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>`flutter analyze` 0 issues；`flutter test` 全绿（含 edit_currency_linked / transaction_edit_screen_amount / golden / 架构测试）；golden baseline 已在 macOS 重生成；JPY-native 用例未改仍绿。</done>
</task>

</tasks>

<verification>
- 外币明细：头部金额点击 → 现有 SmartKeyboard 键盘（经 AmountEditBottomSheet）弹出，编辑原币金额 → 头部主单位串更新、卡内日元（换算）行随 `convertToJpy` 重算。
- 外币明细：原币金额卡（仅汇率 + 日元两行）位于分类/日期卡之前。
- 本币（JPY）明细：头部 tap 行为、clear、卡片渲染、布局顺序全部零回归（CURR-04）。
- OCR / Voice 的金额 sheet 行为零回归（默认 JPY 整数模式未改）。
- `flutter analyze` 0；`flutter test` 全绿；golden 在 macOS 重生成。
- 无新增硬编码字符串/颜色；金额用 AppTextStyles.amount*；ADR-022 D-01 单向换算不变量保持。
</verification>

<success_criteria>
- 改动1：外币头部金额可点击并复用现有键盘编辑原币金额，回写并 live 重算日元。
- 改动2：外币卡上移至分类卡之前，且只保留汇率 + 日元两行（原币金额行已移除）。
- 仅影响外币明细，本币明细与 OCR/Voice 行为不变。
- 全量 `flutter test` + `flutter analyze` 通过；golden 重新基线。
</success_criteria>

<output>
Create `.planning/quick/260613-mgc-foreign-currency-edit-ui/260613-mgc-SUMMARY.md` when done
</output>
