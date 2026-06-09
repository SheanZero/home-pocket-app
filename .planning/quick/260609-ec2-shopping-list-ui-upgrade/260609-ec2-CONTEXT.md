# Quick Task 260609-ec2: 升级购物清单交互与样式 (参考第三方 to-do 应用) - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Task Boundary

参考一个第三方 to-do / 购物清单应用的样式，升级 home-pocket 的购物清单（shopping_list feature）。四项需求：

1. **完成图标在 item 前**：每个 item 左侧加一个圆形图标表示完成状态；点击该图标 = 完成 / 取消完成。
2. **filter 左对齐 + 右侧排序入口**：filter 布局改成靠左，右侧固定一个「三横线 ≡」图标；点击进入「手动拖拽排序模式」（参考图#7）。同时修改现在「默认始终可拖拽排序」的行为——平时隐藏拖拽手柄，仅排序模式下出现。
3. **点击 item 进入编辑**：点击 item 本体（而不是前面的完成图标）= 进入编辑（打开编辑表单）。
4. **右侧显示数量**：item 右侧显示数量；数量为空（=1 默认值）时不显示。

> ⚠️ **重要**：两张参考截图（Image #6 / #7）来自一个**第三方应用**，不是 home-pocket 当前的界面。它们是「样式/交互参考」，不是当前状态。需要把参考的样式和交互模式翻译到 home-pocket 既有的双轨账本购物清单结构里，**不要照搬第三方应用的过滤语义**（如「每日购物 / 游戏」标签是第三方的列表分组，home-pocket 有自己的 全部/日常|悦己/分类 过滤体系，保持不变）。

</domain>

<decisions>
## Implementation Decisions (LOCKED — 经用户确认)

### D-1: 数量与右箭头（需求#4 调研结论）
- **移除右侧 chevron（编辑箭头）**，右侧只显示数量。
- 理由：需求#3 让「点击整行 = 进入编辑」，这正是 chevron 原本承担的作用，chevron 在交互上变得冗余；参考图#6 右侧也没有箭头。
- 数量徽章：`quantity > 1` 时在 item 右侧显示（如 `×2`），`quantity == 1`（默认）时不显示。
- 当前 `quantity` 字段已存在于 schema（`shopping_items.quantity`，默认 1，CHECK >= 1），**无需 Drift migration**，schemaVersion 保持 20。
- 当前数量渲染在名称下方副行（`'${item.quantity}×'`），本任务需将其挪到 item **右侧**。

### D-2: 排序模式（需求#2）
- 「三横线 ≡」点击后进入**手动拖拽排序模式**（不是按条件排序），完全对照参考图#7：
  - filter 区左对齐，每个 filter chip 前带 `≡` 前缀（参考图#7 表现）。
  - 每个 item 右侧出现拖拽手柄。
  - 右上角的 `≡` 变成 `✓`（确认 / 退出排序模式）。
- **修改现状**：home-pocket 当前 `SliverReorderableList` + 每个 active item 始终渲染 `ReorderableDragStartListener` 拖拽手柄（始终可拖拽）。改为：拖拽手柄**仅在排序模式下渲染**，平时隐藏；非排序模式无法发起拖拽。
- 需要一个新的排序模式状态（建议新增一个简单的 bool Notifier provider，如 `shoppingReorderModeProvider`，放在 `presentation/providers/`）。

### Claude's Discretion（未单独询问，按既有规范处理）
- 完成圆形图标的具体配色：在 home-pocket 调色板内选择，需符合双轨账本（daily 绿 / joy 粉）与 WCAG AA。建议未完成 = 描边空心圆（中性灰），已完成 = 填充圆 + 白色对勾，填充色可用 item 的 ledger accent（`palette.daily` / `palette.joy`），null 时用中性绿。最终以 ADR-019 v1.6 调色板 token 为准（`context.palette`），不硬编码颜色。
- 排序模式下是否禁用 toggle/编辑/滑动删除：建议排序模式下仅允许拖拽，禁用点击 toggle / 点击编辑 / 滑动删除，避免误操作。
- 完成图标的对勾 vs 叉号：参考图完成态看着像对勾，采用对勾（`Icons.check`）。

</decisions>

<specifics>
## 参考图详细描述（planner 看不到图，以此为准）

### Image #6（普通态 / 目标样式）
- 顶部标题：「购物清单 / 待办事项列表」（这是第三方 app 的标题，**不照搬**）。
- filter 行：左侧两个 chip「每日购物」「游戏」（第三方的列表分组），右侧有「文件夹图标」+「三横线 ≡ 图标」。→ 翻译到 home-pocket：保留既有 filter chips 左对齐，**右侧固定一个 ≡ 排序入口图标**（文件夹图标对应 home-pocket 已有的「分类」入口，保持现状）。
- 分组标题「（未设定）」+ 右侧 `+`（第三方的添加入口，home-pocket 已有 FAB，不动）。
- item 行：
  - **左侧圆形完成图标**。未完成项「除湿剂」：浅灰**空心圆**，内有很淡的对勾。已完成项「笔记本」：**深绿填充圆** + 浅色对勾，文字**删除线 + 变淡**。
  - item 文字为主文本。
  - 右侧普通态留白（**无箭头**）。

### Image #7（排序模式 / 点击 ≡ 之后）
- filter chips 变为左对齐，每个 chip 前带 `≡` 前缀图标（「≡ 每日购物」「≡ 游戏」）。
- 右上角原 `≡` 位置变成红色 `✓`（确认退出排序）。
- item 行：左侧不再是完成圆圈，**右侧出现拖拽手柄 ≡**（深灰横线）。文字保持。
- 选中的分组标题区有浅色高亮背景。

## home-pocket 当前实现要点（现状基线）
- `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart`：
  - 整行 `GestureDetector.onTap` → `toggleItemCompletedUseCaseProvider`（**需改为打开编辑表单**）。
  - `onLongPress` → 进入 batch 选择模式（保留）。
  - `Dismissible` 右滑删除（保留，排序模式下建议禁用）。
  - trailing cluster：编辑 chevron（`Icons.chevron_right`，**删除**）+ 拖拽手柄（`ReorderableDragStartListener` + `Icons.drag_handle`，**改为仅排序模式显示**）。
  - 数量当前在名称下方副行（`'${item.quantity}×'`，`quantity > 1` 才显示）+ estimatedPrice。**数量挪到右侧**；estimatedPrice 的去留由 planner 判断（建议保留在副行，仅移动 quantity；或与数量一起放右侧——保持信息不丢失）。
  - 公共列表归属 chip（attribution，`listType == 'public'`）保留。
- `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart`：
  - body 用 `CustomScrollView` + `SliverReorderableList`（active items）+ `SliverList`（completed items）。
  - `onReorderItem` → `reorderShoppingItemsUseCaseProvider`。
- `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart`：
  - 当前是 `SingleChildScrollView`(横向) 包一个 `Row`：[全部 reset ActionChip] → [日常|悦己 segmented] → [分类 ActionChip]。
  - **需改为**：左侧可横向滚动的 filter chips + 右侧固定的 ≡/✓ 排序切换图标（建议 Row: `Expanded(SingleChildScrollView(...))` + 末尾 IconButton）。
  - 排序模式下：chips 加 `≡` 前缀、右侧图标变 `✓`。
- `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart`：现有 `ListType`、`ShoppingFilter` provider，keepAlive。排序模式新 provider 可放同目录。

## 工程注意事项
- i18n：新增 UI 文案（排序模式切换/退出的 Semantics/Tooltip 等）必须更新 3 个 ARB（`app_en.arb`/`app_ja.arb`/`app_zh.arb`）后 `flutter gen-l10n`。现有可复用 `shoppingReorderItem`、`shoppingEditItem`。
- 代码生成：新增 `@riverpod` provider 后需 `flutter pub run build_runner build --delete-conflicting-outputs`。
- 颜色：一律走 `context.palette`（ADR-019 v1.6），禁止硬编码 hex。
- 命中区域：完成图标与拖拽手柄保持 ≥44px 命中区（WCAG 2.5.5）。
- 测试：购物清单 tile / filter bar 有 widget 测试与 golden masters；本次布局改动会导致 golden 失配，需重新基线化（`--update-goldens`）并更新受影响 widget 测试。完成后跑全量 `flutter test`（含架构测试，如 hardcoded_cjk_ui_scan），`flutter analyze` 必须 0 issue。
- 不动 schema / DAO / repository（数量已存在）；改动集中在 presentation 层 + 可能的 use case（排序模式纯 UI 状态，不入库）。

</specifics>

<canonical_refs>
## Canonical References
- `CLAUDE.md` — 架构分层、Riverpod 3 约定、i18n 规则、调色板规则、Drift 注意事项。
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — 调色板 token（桜餅×若葉）。
- 既有交互锚点编号：DONE-01（toggle）、D38-01（编辑 chevron，本次移除）、D38-02（拖拽手柄）、D38-04（filter bar）、MGMT-02（长按 batch）。
</canonical_refs>
