# Quick Task 260609-ruu: 重新设计添加/修改商品页 - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning — design confirmed by user via HTML mockup

<domain>
## Task Boundary

重新设计 `ShoppingItemFormScreen`（添加/修改商品页，单文件
`lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`），
使其与「添加账目」(`TransactionDetailsForm` / `TransactionEditScreen`) 视觉一致。
HTML 稿见 `mockup.html`（用户已确认布局）。

Out of scope: 不改数据模型、use case、repository；不改同步/加密；不改其他屏。
</domain>

<decisions>
## Implementation Decisions (LOCKED — confirmed by user)

### 三区域卡片式布局（与添加账目一致）
- **区域1 — 商品名称**：单独成卡（白卡 `palette.card`，radius 14，border `palette.borderDefault`），
  内含 name `TextField`。
- **区域2 — 数量 / 用途 / 类型**：同一张卡，三行，行间 `palette.backgroundDivider` 分隔线
  （仿 `DetailInfoCard`）。
- **区域3 — 分类 / 预估价格 / 备注**：同一张卡，分类行 + 预估价格行 + 备注区。
- 复用现有共享组件：`LedgerTypeSelector`、`ListTypeSelector`，卡片样式仿
  `DetailInfoCard` / `_formCard`（transaction_details_form.dart）。

### 用途（原「账本」label）
- ARB `shoppingFormLedgerLabel` 值由「账本」改为「用途」（zh），ja/en 同步
  （ja「用途」、en「Purpose」）。或直接复用 `expenseClassification`（值已是「用途」）——
  planner 任选其一，**优先复用 `expenseClassification` 以保持与账目页同源**。
- 选项标签用 `dailyExpense`/`joyExpense`（日常支出/悦己支出），与账目页一致
  （现商品页用的是 `listLedgerDaily`/`listLedgerJoy`，改为 `dailyExpense`/`joyExpense`）。
- 展示：标题在左、`LedgerTypeSelector` 药丸在右（同 transaction Card B 的行布局）。

### 用途行为 — 始终二选一（与账目一致）【D-1】
- 默认 `LedgerType.daily`，只能在 daily/joy 间切换，**不能取消选择成 null**。
  移除现有「再点一次切回 null」的 toggle-off 逻辑。
- `_ledgerType` 改为非空 `LedgerType`（默认 daily）。
- 编辑模式：若已存在 item 的 `ledgerType == null`，载入时显示为 daily（保存即写 daily）。

### 类型（原「清单」label）
- ARB `shoppingFormListTypeLabel` 值由「清单」改为「类型」（zh），ja/en 同步
  （ja「タイプ」、en「Type」）。
- 设计与「用途」一致：标题在左、`ListTypeSelector` 药丸在右（公共/私有，钢蓝）。
- 编辑模式只读（沿用现有 `enabled: !isEditMode` + locked hint，不变）。

### 标签 — 隐藏【D-2】
- 移除标签 `TextField`（`shopping_form_tags_field`）及其 label，不在 UI 显示。
- **底层数据保留**：编辑模式下原 `item.tags` 透传回 save（create 模式传空 list）。
  即 `_tagsController` 可保留用于持有原值但不渲染，或在 save 时 create→`[]` /
  edit→`widget.item!.tags`。planner 选最简实现，**关键不变量：编辑保存不丢原标签**。

### 分类选择 — 与账目一致
- 改为整行点击（图标 + 「分类」label + 当前值/占位 + chevron `›`），仿
  `DetailInfoRow(showChevron:true, onTap:_pickCategory)`，跳 `CategorySelectionScreen`。
- 移除现有 `OutlinedButton`「更改」(`shopping_form_category_button`)。
- 占位文案：复用 `shoppingFormNoCategorySelected`（未选择分类）或 `pleaseSelectCategory`，
  planner 任选，保留 key 给测试。

### 数量步进器【D-3】
- 最小值 1；create 模式进入即填「1」（`_quantityController` 初值 '1'，非空）。
- 加 `[−] [数量] [＋]` 步进器：− 到 1 即止（不低于 1），＋ **不设上限**。
- 中间数字仍是可手输 `TextField`（保留 key `shopping_form_quantity_field`）；手输 < 1 或非法 → 回落 1。
- save 时的 sanitize 逻辑（quantity < 1 → 1）保留不变。

### 自动聚焦商品名称【D-4】
- create 模式进入页面自动聚焦 name 字段、弹起键盘。用 `FocusNode` +
  `autofocus: true` 或 `WidgetsBinding.addPostFrameCallback` requestFocus。
- 编辑模式不强制聚焦（避免打断查看），create 模式才聚焦。

### 保存按钮【D-5 — 用户明确纠正】
- **位置保持在 AppBar 右上角（标题右侧），不移到底部。**
- 重新设计为更醒目、易点的填充按钮（替换现有朴素 `TextButton`）：
  AppBar action 里放一个填充药丸/按钮，主色（leaf green `palette.daily`/primary
  或樱粉渐变，planner 定），白字「保存」，足够点击热区（≥ 44pt 高）。
- 保留按钮文案 key `shoppingFormSave`（值「保存」），保证现有测试 `find.text('Save')` 仍命中。

### Claude's Discretion
- 步进器 / 卡片的精确像素值、圆角、内边距由 planner/executor 按账目页同款取值。
- 用途 label 用 `expenseClassification` 复用 vs 改 `shoppingFormLedgerLabel` 值 —— 倾向复用。
- 分类占位 key 的选择。
- 标签数据透传的具体写法（controller 持值 vs 直接读 item.tags）。
</decisions>

<specifics>
## Specific References

- 设计参照源（必读）：
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
    （`DetailInfoCard` 用法、`_formCard`、Card B 用途+药丸行布局、`_buildNoteSection`）
  - `lib/features/accounting/presentation/screens/transaction_edit_screen.dart`
    （AppBar 结构 — 但本任务保存键留在 AppBar，**不**照搬其底部渐变大按钮）
  - `lib/features/accounting/presentation/widgets/detail_info_card.dart`（行+分隔线卡片）
  - `lib/shared/widgets/ledger_type_selector.dart` / `list_type_selector.dart`（药丸）
- HTML 稿：`.planning/quick/260609-ruu-redesign-shopping-form/mockup.html`
- 调色板：`lib/core/theme/app_palette.dart`（桜餅×若葉 v1.6，`context.palette`）

## 受影响文件（预估）
- 改：`shopping_item_form_screen.dart`（主体重写 build + 状态）
- 改：`lib/l10n/app_zh.arb` / `app_ja.arb` / `app_en.arb`（`shoppingFormListTypeLabel`、
  可能 `shoppingFormLedgerLabel`；新增「类型」「用途」若不复用）→ 跑 `flutter gen-l10n`
- 改：`test/widget/.../shopping_item_form_screen_test.dart`（tags 字段移除断言、
  category 改行点击、save 按钮、用途无 null toggle、数量默认 1/步进器）
- 可能：golden 重基线（若该屏有 golden；现有 test 文件名含 form 但为 widget 测试，
  执行时按 `flutter test` 结果决定是否需 `--update-goldens`）
</specifics>

<canonical_refs>
## Canonical References

- CLAUDE.md：i18n 规则（三 ARB 全改 + gen-l10n）、Amount Display Style
  （`AppTextStyles.amountSmall` 用于金额）、Widget Parameter Pattern、调色板 v1.6 ADR-019。
- 现有不变量：列表类型 `listType` 创建后不可变（D37-04/SYNC-03）——编辑只读，保持。
</canonical_refs>
