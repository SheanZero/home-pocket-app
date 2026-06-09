---
phase: quick-260609-ruu
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
  - lib/l10n/app_zh.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_en.arb
  - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
autonomous: true
requirements: [D-1, D-2, D-3, D-4, D-5]

must_haves:
  truths:
    - "三区域卡片布局：商品名称独卡 / 数量+用途+类型同卡 / 分类+预估价格+备注同卡 (D-1/D-2/D-3)"
    - "用途行永远是 daily/joy 二选一；default daily；不能 toggle 成 null (D-1)"
    - "数量行显示 [−] [TextField] [＋] 步进器；最小 1；+ 无上限 (D-3)"
    - "create 模式自动聚焦商品名称 TextField；编辑模式不强制聚焦 (D-4)"
    - "保存按钮在 AppBar actions，填充药丸样式（fabGradient 樱粉渐变），key shoppingFormSave 保留 (D-5)"
    - "标签 TextField 不渲染；编辑保存时原 item.tags 透传；create 时传 [] (D-2)"
    - "分类行整行点击（DetailInfoCard 行样式）进入 CategorySelectionScreen；移除旧 OutlinedButton (D-1)"
    - "listType 编辑只读（D37-04/SYNC-03），locked hint 保留"
    - "flutter analyze 0 issues；flutter gen-l10n 成功；widget 测试全绿"
  artifacts:
    - path: "lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart"
      provides: "重写后的 ShoppingItemFormScreen"
      contains: "_ledgerType 非空 LedgerType"
    - path: "lib/l10n/app_zh.arb"
      provides: "shoppingFormListTypeLabel=类型；用途复用 expenseClassification"
    - path: "lib/l10n/app_en.arb"
      provides: "shoppingFormListTypeLabel=Type"
    - path: "lib/l10n/app_ja.arb"
      provides: "shoppingFormListTypeLabel=タイプ"
    - path: "test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart"
      provides: "更新后 widget 测试"
  key_links:
    - from: "ShoppingItemFormScreen._save()"
      to: "UpdateShoppingItemParams.tags"
      via: "edit 模式：widget.item!.tags 直接传入"
      pattern: "widget\\.item\\.tags"
    - from: "ShoppingItemFormScreen._ledgerType"
      to: "LedgerTypeSelector.selected"
      via: "non-nullable LedgerType field"
      pattern: "_ledgerType = LedgerType\\.daily"
---

<objective>
重写 ShoppingItemFormScreen 的 UI 层，使其与「添加账目」页面视觉风格一致：
三区域卡片布局、步进器数量、非空用途选择、分类行整行点击、AppBar 填充保存按钮、
隐藏标签字段（数据透传）。同步更新 ARB 文案（shoppingFormListTypeLabel 改「类型」）
并更新 widget 测试。

Purpose: 与账目页统一视觉语言；步进器改善数量输入体验；保存按钮更醒目。
Output: 重写的 shopping_item_form_screen.dart + 三个 ARB 更新 + 测试更新。
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/260609-ruu-redesign-shopping-form/260609-ruu-CONTEXT.md
@.planning/STATE.md

# 设计参照（必读 build 前）
@lib/features/accounting/presentation/widgets/detail_info_card.dart
@lib/shared/widgets/ledger_type_selector.dart
@lib/shared/widgets/list_type_selector.dart

# 调色板（桜餅×若葉 v1.6）
@lib/core/theme/app_palette.dart

# 当前待重写文件
@lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart

# 现有测试
@test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: 更新三个 ARB 文件（shoppingFormListTypeLabel 改「类型」）</name>
  <files>lib/l10n/app_zh.arb, lib/l10n/app_ja.arb, lib/l10n/app_en.arb</files>
  <action>
    修改三个 ARB 文件中 `shoppingFormListTypeLabel` 的值：
    - app_zh.arb: 「清单」→「类型」
    - app_ja.arb: 「リスト」→「タイプ」
    - app_en.arb: 「List」→「Type」

    同时保留（不改）以下 key 的值（后续 Task 2 直接复用）：
    - `expenseClassification`（zh「用途」/ ja「用途」/ en「Purpose」）— 用于用途行 label
    - `dailyExpense`（zh「日常支出」）/ `joyExpense`（zh「悦己支出」）— 用于 LedgerTypeSelector 的芯片 label
    - `shoppingFormSave`（zh「保存」/ en「Save」）— 保留，保证测试 find.text('Save') 命中
    - `shoppingFormNoCategorySelected`（zh「未选择分类」/ en「No category」）— 保留，分类占位
    - `shoppingListTypeLockedHint` — 保留，编辑只读提示

    每个 ARB 文件只改 `shoppingFormListTypeLabel` 的值，其余 key 不动。
    修改后运行：`flutter gen-l10n` 验证 ARB 合法。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter gen-l10n 2>&1 | tail -5</automated>
  </verify>
  <done>flutter gen-l10n 无错误；grep 确认三文件中 shoppingFormListTypeLabel 值已更新（zh=类型/ja=タイプ/en=Type）。</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 重写 ShoppingItemFormScreen（三区域卡片布局 + 步进器 + 新 AppBar 按钮）</name>
  <files>lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart</files>
  <behavior>
    - _ledgerType 为非空 LedgerType（默认 daily），onChanged 直接 setState 赋值，不能 toggle 成 null
    - create 模式：_quantityController 初值 '1'；edit 模式：item.quantity.toString()
    - 步进器 − 按钮：quantity - 1，最小 1；+ 按钮：quantity + 1（无上限）
    - _tagsController 仅持值不渲染；_save edit 分支：tags = widget.item!.tags（非 parsedTags）；create 分支：tags = []
    - AppBar save 按钮命中 find.text('Save')（key shoppingFormSave 值 'Save'）
    - 分类行 onTap = _pickCategory，显示 _categoryName ?? l.shoppingFormNoCategorySelected + chevron
    - listType 编辑只读（enabled: !isEditMode），locked hint 保留
    - create 模式：FocusNode(debugLabel:'nameFocus') + autofocus:true 在 name TextField
  </behavior>
  <action>
    完整重写 `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`。
    保留所有现有 import（无需删除），按需补充：
    - `import '../../../../core/theme/app_palette.dart';`（已有可不重复）
    - `import '../../../accounting/presentation/widgets/detail_info_card.dart';`（DetailInfoCard/DetailInfoRow）

    **状态变更（与现有的差异）：**
    1. `LedgerType? _ledgerType` → `LedgerType _ledgerType = LedgerType.daily`（非空）
    2. 新增 `FocusNode _nameFocusNode = FocusNode(debugLabel: 'shoppingNameFocus');`
       仅 create 模式在 `initState` 末尾用 `WidgetsBinding.instance.addPostFrameCallback` 调用 `_nameFocusNode.requestFocus()`
    3. `_tagsController` 保留，create 时仍 `TextEditingController()`，edit 时持有 `item.tags.join(', ')`，但**不渲染**到 UI

    **_save 方法变更：**
    - edit 分支：`tags: widget.item!.tags`（直接透传原标签，不解析 _tagsController）
    - create 分支：`tags: const []`
    - 其余逻辑（quantity sanitize、estimatedPrice sanitize）**不变**

    **build 方法 — 三区域卡片结构：**

    AppBar:
    ```
    AppBar(
      title: Text(isEditMode ? l.shoppingFormEditTitle : l.shoppingFormAddTitle),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildSaveButton(l),
        ),
      ],
    )
    ```

    `_buildSaveButton` 返回 `GestureDetector` / `InkWell`（带 borderRadius 20）包裹：
    ```
    Container(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.fabGradientStart, palette.fabGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: palette.fabShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Text(l.shoppingFormSave, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
    )
    ```
    `onTap: _isSubmitting ? null : _save`。关键：文字是 `l.shoppingFormSave`（即「Save」/「保存」），保证测试 `find.text('Save')` 命中。

    body: `Form(key: _formKey, child: ListView(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), children: [...]))`

    **区域 1 — 商品名称卡：**
    ```
    _sectionLabel('①', l.shoppingFormNameLabel),  // 可选装饰性 label，无需要也可省略
    Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        key: const Key('shopping_form_name_field'),
        controller: _nameController,
        focusNode: _nameFocusNode,
        autofocus: !isEditMode,   // create = true, edit = false
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: l.shoppingFormNameLabel,
          hintStyle: TextStyle(color: palette.textTertiary, fontWeight: FontWeight.w500),
        ),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: palette.textPrimary),
        textInputAction: TextInputAction.next,
        validator: (v) => (v == null || v.trim().isEmpty) ? l.shoppingFormNameRequired : null,
      ),
    ),
    const SizedBox(height: 16),
    ```

    **区域 2 — 数量 / 用途 / 类型卡：**
    用 `DetailInfoCard`（来自 detail_info_card.dart）的容器样式（card color, radius 14, border）
    但行内容自定义（非 DetailInfoRow 因为每行 trailing widget 不同于纯文本）。
    推荐用 `Container(decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.borderDefault)))` 包裹 Column：

    行一（数量）：
    ```
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(
      children: [
        Text(l.shoppingFormQuantityLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.textSecondary)),
        const Spacer(),
        _buildStepper(),  // [−] [TextField] [＋]
      ],
    ))
    ```

    `_buildStepper()`：
    ```
    Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.borderDefault),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _stepBtn('−', () {
          final v = int.tryParse(_quantityController.text) ?? 1;
          if (v > 1) setState(() => _quantityController.text = (v - 1).toString());
        }),
        SizedBox(
          width: 52,
          child: TextField(
            key: const Key('shopping_form_quantity_field'),
            controller: _quantityController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n < 1) setState(() => _quantityController.text = '1');
            },
          ),
        ),
        _stepBtn('＋', () {
          final v = int.tryParse(_quantityController.text) ?? 1;
          setState(() => _quantityController.text = (v + 1).toString());
        }),
      ]),
    )
    ```
    `_stepBtn(String label, VoidCallback onTap)` 返回 `GestureDetector` 包 `Container(width: 38, height: 38, color: palette.backgroundMuted, child: Center(child: Text(label, style: ...dailyText color, fontWeight w500, fontSize 20)))`。
    注意步进器左侧和右侧按钮分别用 `borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11))` 和 `topRight/bottomRight`。

    行一与行二之间的分隔线：`Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: palette.backgroundDivider))`（与 DetailInfoCard 一致）

    行二（用途）：
    ```
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(
      children: [
        Text(l.expenseClassification, style: ...textSecondary 13 w500),  // 复用 expenseClassification key
        const Spacer(),
        LedgerTypeSelector(
          key: const Key('shopping_form_ledger_selector'),
          selected: _ledgerType,                      // 非空
          onChanged: (type) => setState(() => _ledgerType = type),  // 直接赋值，不 toggle null
          dailyLabel: l.dailyExpense,                 // 改为 dailyExpense（日常支出）
          joyLabel: l.joyExpense,                     // 改为 joyExpense（悦己支出）
        ),
      ],
    ))
    ```

    行三（类型）：
    ```
    Padding(padding: ..., child: Row(
      children: [
        Text(l.shoppingFormListTypeLabel, style: ...textSecondary 13 w500),   // 「类型」
        const Spacer(),
        ListTypeSelector(
          key: const Key('shopping_form_list_type_selector'),
          selected: _listType == 'public' ? 'public' : 'private',
          onChanged: (v) => setState(() => _listType = v),
          publicLabel: l.shoppingSegmentPublic,
          privateLabel: l.shoppingSegmentPrivate,
          enabled: !isEditMode,
        ),
      ],
    )),
    ```
    edit 模式下在行三下方追加 locked hint（与现有逻辑相同）：
    `if (isEditMode) Padding(padding: EdgeInsets.fromLTRB(16,4,16,12), child: Text(l.shoppingListTypeLockedHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)))`

    const SizedBox(height: 16),

    **区域 3 — 分类 / 预估价格 / 备注卡：**
    同样用 Container+BoxDecoration 包 Column（三行+分隔线）。

    行一（分类）— 整行点击，仿 DetailInfoRow(showChevron: true)：
    ```
    InkWell(
      onTap: _pickCategory,
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(
        children: [
          Icon(Icons.label_outline, size: 16, color: palette.textTertiary),
          const SizedBox(width: 8),
          Text(l.shoppingFormCategoryLabel, style: ...textSecondary 13 w500),
          const Spacer(),
          Text(
            _categoryName ?? l.shoppingFormNoCategorySelected,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _categoryName != null ? palette.textPrimary : palette.textSecondary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 14, color: palette.textSecondary),
        ],
      )),
    )
    ```
    注意：移除现有的 `Key('shopping_form_category_button')` OutlinedButton。
    测试文件中该 key 的断言需要更新（Task 3 处理）。

    分隔线后行二（预估价格）：
    ```
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(
      children: [
        Text('¥', style: TextStyle(fontSize: 15, color: palette.textSecondary)),
        const SizedBox(width: 8),
        Text(l.shoppingFormPrice, style: ...textSecondary 13 w500),
        Expanded(
          child: TextField(
            key: const Key('shopping_form_price_field'),
            controller: _priceController,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            style: AppTextStyles.amountSmall,    // 金额样式，tabularFigures
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
            onSubmitted: (_) => _save(),
          ),
        ),
      ],
    ))
    ```

    分隔线后行三（备注区）— 含内部标题 + 多行 TextField：
    ```
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.edit_outlined, size: 15, color: palette.textTertiary),
          const SizedBox(width: 6),
          Text(l.shoppingFormNoteLabel, style: ...textSecondary 13 w500),
        ]),
        const SizedBox(height: 8),
        TextField(
          key: const Key('shopping_form_note_field'),
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: l.shoppingFormNoteLabel,
            hintStyle: TextStyle(color: palette.textTertiary),
            filled: true,
            fillColor: palette.backgroundMuted,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    ))
    ```

    const SizedBox(height: 24),  // 底部 padding

    **关键不变量（executor 务必保留）：**
    1. 编辑保存 tags 透传：edit 分支 `tags: widget.item!.tags`（而非 parsedTags）。per D-2
    2. listType 编辑只读：`enabled: !isEditMode`。per D37-04/SYNC-03
    3. 按钮文案 key `shoppingFormSave` 值「保存」/「Save」保留（test find.text）。per D-5
    4. quantity sanitize（< 1 → 1）在 `_save()` 保留不变。per D-3
    5. _nameFocusNode.dispose() 在 dispose() 中调用。

    **禁止改动（范围外）：** 不改 ShoppingItem model，不改 use case，不改 repository，不改其他屏幕。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart 2>&1 | tail -10</automated>
  </verify>
  <done>flutter analyze 对该文件 0 issues；_ledgerType 为非空 LedgerType；步进器 [−][qty][＋] 存在；分类行整行可点；AppBar 有填充渐变保存按钮；标签字段不在 UI 渲染；edit 模式 item.tags 透传。</done>
</task>

<task type="auto">
  <name>Task 3: 更新 widget 测试并完整验证</name>
  <files>test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart</files>
  <action>
    更新 widget 测试文件，使其与重设计后的 UI 保持一致。具体变更点：

    **移除/替换以下断言（UI 已不存在这些 widget）：**
    1. `find.byKey(const Key('shopping_form_tags_field'))` — 标签字段已隐藏（D-2），
       将断言改为 `findsNothing`，或删除该 testWidgets case，
       并在注释中说明「Tags field hidden per D-2; data passes through transparently」。
    2. `find.byKey(const Key('shopping_form_category_button'))` — OutlinedButton 已替换为整行 InkWell，
       删除该断言；可改为验证 `find.text(l.shoppingFormCategoryLabel)` 或 category 区域 InkWell 存在。
       如果测试中用 find.text 即可，直接用：`expect(find.text('Category'), findsOneWidget)`（en locale）。

    **新增测试（覆盖重设计后的行为）：**

    a. `STEPPER-01`: create 模式数量字段初值为 '1'
    ```dart
    testWidgets('STEPPER-01: create mode quantity defaults to 1', (tester) async {
      await _pumpForm(tester, createUseCase: mockCreate, updateUseCase: mockUpdate, deviceIdentityRepo: mockDeviceIdentityRepo);
      await tester.pumpAndSettle();
      final qField = tester.widget<TextField>(find.byKey(const Key('shopping_form_quantity_field')));
      expect(qField.controller?.text, equals('1'));
    });
    ```

    b. `LEDGER-NO-NULL-01`: 用途选择器不能 toggle 成 null（点击已选中的 chip 仍保持选中）
    ```dart
    testWidgets('LEDGER-NO-NULL-01: tapping active daily chip keeps ledger = daily (no null toggle)', (tester) async {
      await _pumpForm(tester, createUseCase: mockCreate, updateUseCase: mockUpdate, deviceIdentityRepo: mockDeviceIdentityRepo);
      await tester.pumpAndSettle();
      // Tap daily chip (already selected)
      await tester.tap(find.byKey(const ValueKey('ledger_type_daily_chip')));
      await tester.pump();
      final sel = tester.widget<LedgerTypeSelector>(find.byKey(const Key('shopping_form_ledger_selector')));
      expect(sel.selected, equals(LedgerType.daily), reason: 'Tapping active chip must not toggle to null');
    });
    ```

    c. `TAGS-D2-01`: 编辑模式保存时透传原 item.tags（edit 分支 tags 等于 item.tags）
    ```dart
    testWidgets('TAGS-D2-01: edit save passes original item.tags through', (tester) async {
      late UpdateShoppingItemParams capturedParams;
      when(() => mockUpdate.execute(any())).thenAnswer((inv) async {
        capturedParams = inv.positionalArguments.first as UpdateShoppingItemParams;
        return Result.success(_makeItem());
      });
      final editItem = _makeItem(name: 'Bread');
      // _makeItem has tags=[] by default; add a tag for a more meaningful test
      // (ShoppingItem.tags defaults to [] in fixture; verify it passes through)
      await _pumpForm(tester, createUseCase: mockCreate, updateUseCase: mockUpdate, deviceIdentityRepo: mockDeviceIdentityRepo, item: editItem);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      verify(() => mockUpdate.execute(any())).called(1);
      expect(capturedParams.tags, equals(editItem.tags), reason: 'Edit save must pass original item.tags (D-2)');
    });
    ```

    注意：`_makeItem` fixture 当前没有 `tags` 字段（ShoppingItem 有 tags 字段），
    需检查 `ShoppingItem` 构造函数，若需要补 `tags: const []`，在 `_makeItem` 内添加即可。

    **保留以下现有测试（不改逻辑）：**
    - ITEM-01 name required validation（find.text('Save') 仍命中，保留）
    - ITEM-02 的 quantity / price / note 字段存在检查（key 未变）
    - ITEM-04 edit mode pre-population（name, titles, save routing）
    - List-type selector 全组（G8Z / G8Z2，key 未变）
    - Ledger default（LEDGER-DEFAULT-01/02，LedgerTypeSelector key 未变）
    - Selector ordering（ORDER-01，两个 selector key 均未变）

    所有 find.text('Save') 调用均保留（AppBar 按钮仍显示 l.shoppingFormSave = 'Save'）。

    完成后运行完整验证：
    1. flutter analyze（全项目 0 issues）
    2. flutter test test/widget/.../shopping_item_form_screen_test.dart（全绿）
    3. flutter test（全项目；若 golden 失败则 flutter test --update-goldens 并检查 diff 是否合理）
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -5 &amp;&amp; flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart --reporter=compact 2>&1 | tail -10</automated>
  </verify>
  <done>flutter analyze 0 issues；shopping_item_form_screen_test.dart 全绿；无遗留 tags_field / category_button key 的断言命中已删除的 widget；新增 STEPPER-01、LEDGER-NO-NULL-01、TAGS-D2-01 测试通过。</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| user→TextFormField(name) | 商品名称用户输入，经 validator 验证非空后传 use case |
| user→TextField(quantity) | 数量输入，_save() 内 sanitize < 1 → 1，防止 0/负值 |
| user→TextField(price) | 预估价格输入，< 0 → null，无符号溢出风险 |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-ruu-01 | Tampering | _quantityController.text | mitigate | _save() sanitize: parsedQuantity < 1 → 1（现有逻辑保留） |
| T-ruu-02 | Tampering | edit mode tags passthrough | mitigate | edit 分支直接用 widget.item!.tags，不解析 _tagsController，无注入面 |
| T-ruu-03 | Information Disclosure | _nameController (create autofocus) | accept | 本地设备 UI 焦点，非网络边界；自动聚焦不暴露额外数据 |
| T-ruu-SC | Tampering | npm/pip/cargo installs | accept | 纯 UI 变更，无新 pub.dev 依赖安装 |
</threat_model>

<verification>
按顺序运行：

```bash
# 1. ARB 合法性 + 生成
cd /Users/xinz/Development/home-pocket-app
flutter gen-l10n

# 2. 单文件分析
flutter analyze lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart

# 3. 全项目分析
flutter analyze

# 4. 该屏 widget 测试
flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart --reporter=compact

# 5. 全项目测试（golden 失败时追加 --update-goldens）
flutter test
```

若 `flutter test` 出现 golden 失败：检查是否是 shopping_item_form_screen 相关的 golden；
若是，运行 `flutter test --update-goldens test/widget/features/shopping_list/...` 并 git add 新基线。
</verification>

<success_criteria>
- `flutter gen-l10n` 成功（无报错）
- `flutter analyze` 全项目 0 issues
- `shoppingFormListTypeLabel`：zh=「类型」/ ja=「タイプ」/ en=「Type」
- `ShoppingItemFormScreen` 三区域卡片布局匹配 CONTEXT.md 锁定决策 D-1～D-5
- `_ledgerType` 为非空 `LedgerType`；onChanged 不能 toggle 成 null
- `_quantityController` create 初值 '1'；步进器 [−][qty][＋] key `shopping_form_quantity_field` 保留
- 标签 TextField `shopping_form_tags_field` 不渲染；edit 模式 `widget.item!.tags` 透传
- AppBar save 按钮：`find.text('Save')` 命中，填充渐变样式（fabGradientStart/End）
- 分类行 InkWell 整行点击替代旧 `shopping_form_category_button` OutlinedButton
- `flutter test shopping_item_form_screen_test.dart` 全绿（含新增 STEPPER-01 / LEDGER-NO-NULL-01 / TAGS-D2-01）
- `flutter test`（全项目）绿色（golden 按需重基线）
</success_criteria>

<output>
创建 `.planning/quick/260609-ruu-redesign-shopping-form/260609-ruu-01-SUMMARY.md` 完成后。
</output>
