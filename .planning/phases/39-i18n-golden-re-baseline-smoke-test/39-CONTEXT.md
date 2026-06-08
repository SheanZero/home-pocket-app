# Phase 39: i18n + Golden Re-baseline + Smoke Test - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

把购物清单功能"封箱"——一个验证/收尾型 phase。三件事：
1. **i18n 收尾** — tab label key 重命名 + 清除残留 todo 文案 + ja/zh/en ARB key parity 验证（`flutter gen-l10n` 0 warnings）。
2. **Golden re-baseline** — 为购物清单 UI 建立 golden masters，覆盖 SC3 列出的各状态 × 3 语言 × 2 配色。
3. **Sync smoke test** — 在 presentation/StreamProvider 层确认 GAP-2 reactivity（写入后自动 emit，不靠 `ref.invalidate`）。

并通过质量门：`flutter analyze` 0 issues + `flutter test --coverage` ≥70%（针对 `lib/features/shopping_list/` 与 `lib/application/shopping_list/` 新文件）。

Requirements: NAV-03。

ROADMAP §"Phase 39" 的 5 条 success criteria 是验收口径，已高度规定实现细节。本次讨论解决的是：tab 文案最终形态、golden 粒度与变体边界、既有文案是否复审、smoke test 范围。

**关键现状（讨论中核实）：**
- Phase 38 **已填入全部 shopping ARB 文案**（实值，非占位），三语 key 数已对齐（各 1077）。空状态 3 变体、filter/batch/form/segment 文案均已存在且语气一致。
- 4th nav tab 当前 label = `買い物リスト/购物清单/Shopping List`，但 key 仍叫 `homeTabTodo`；另有残留 stale key `todoTab`（やること/待办/Todo）。SC2 要求 `homeTabTodo`/`todoTab`/`待办`/`Todo` 在 `lib/l10n/` 全部消失。
- nav 图标已是 `shopping_bag_outlined`/`shopping_bag`（NAV-02 在 Phase 38 已完成），本 phase 不动图标。
- 购物清单尚无 golden 测试；widget 测试已存在于 `test/widget/features/shopping_list/presentation/`。

**Out of scope:** 任何新能力（v2 enhancements 见 deferred）；改动 Phase 36/37 的 data/use-case/sync 逻辑；修改现有非购物 golden；调整 Phase 38 已填的文案现值（用户决定接受原样）。

</domain>

<decisions>
## Implementation Decisions

### Tab 文案 + key rename（NAV-03 / SC1 / SC2）
- **D39-01:** 4th nav tab label **缩短**为 `買い物 / 购物 / Shopping`（与兄弟 tab ホーム/一覧/チャート 等长，避免底部 nav 换行/截断；原 `買い物リスト/购物清单/Shopping List` 偏长）。
- **D39-02:** **重命名 ARB key** `homeTabTodo` → `homeTabShopping`（值改为 D39-01 的缩短文案，三语同时改），并**删除 stale key `todoTab`**（值为旧占位 やること/待办/Todo，已核实**无任何 Dart 代码引用**，仅存在于 ARB）。更新代码引用 `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:45`（`l10n.homeTabTodo` → `l10n.homeTabShopping`）。运行 `flutter gen-l10n`。
  - **验收对齐：** rename + delete 后，`grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/` 必须 0 hits（SC2），且三语 key 数仍相等（SC1）。注意：`@homeTabTodo` 的 metadata 条目也要一并改名/删除。

### Golden 覆盖（SC3）
- **D39-03:** **组件级 golden**（延续现有约定 —— 现有 11 个 golden 测试均为组件/widget 级，如 `list_transaction_tile`/`list_sort_filter_bar`/`list_empty_state` 各自一套，固定尺寸 + provider override）。**不**拍整屏 ShoppingListScreen golden。
  - **验收对齐（重要）：** SC3 措辞为 "shopping list **screen states**"。本决策用**组件级 golden 覆盖 SC3 列出的每个状态**——验收时以"每个 SC3 状态都有对应的组件 golden（3 语言 × 2 配色）"为达标口径，而非整屏快照。planner/verifier 须按此口径判定，勿因缺整屏 golden 而判 fail。
- **D39-04:** **golden 集变体**（每个变体默认 3 locales × 2 配色 = 6 图，遵 SC3）：
  - Empty 3 变体：`shoppingEmptyPrivate` / `shoppingEmptyPublicSolo` / `shoppingEmptyPublicFamily`（SC3 明列）。
  - ShoppingItemTile：**active** + **completed**（completed 验证 DONE-01 strikethrough + fade 视觉）。
  - Tile **attribution chip**（public-family 成员归属 chip，SYNC-04）。
  - **Filter bar active** 状态。
  - **Batch 选择栏**（顶部 selection header + 底部 batch action bar，D38-03）。
- **D39-05:** 双轨账本左边框（daily 绿 / joy 樱粉，SHOP-03/ADR-019）**不单列为专门的 daily-vs-joy 成对 golden**（用户决定）。改为：**active/completed tile golden 使用代表性 ledger 顺带覆盖边框**——建议 active 用 daily、completed 用 joy（或反之），让两种边框各出现一次（planner discretion）。验收时**不**因缺少专门的双轨成对 golden 判缺口。

### Smoke test 范围（SC4）
- **D39-06:** smoke test = **SC4 最小断言 + provider 层 privacy 再断言**两条：
  1. （SC4）经 `ApplySyncOperationsUseCase` 写入一个 public item 后，绑定 `watchByListType('public')` 的 **StreamProvider 自动 emit 新状态**，**全程不调用 `ref.invalidate`**（确认 v1.4 GAP-2 lesson 落实在 presentation 层）。
  2. （额外防线）远端写入的 **private item 不出现**在任何 `watchByListType` StreamProvider 的发射结果中（presentation 层重申隐私契约）。
  - **注意去重：** Phase 37 已在 application 层覆盖 reactive round-trip + privacy + tombstone（37 SC5）。本 smoke test 聚焦 **provider/presentation 层**，不复制 application 层的 tombstone 测试。

### 既有文案
- **D39-07:** Phase 38 已填的 shopping 文案现值**接受原样**，本 phase **不修改任何现有 ARB 值**（仅做 D39-01/02 的 tab key rename/delete）。文案一致、语气得体，无需复审调整。

### Claude's Discretion（research / planner）
- 新 key 命名细节确认 `homeTabShopping`（与现有 `homeTab*` 命名约定一致）。
- golden 的尺寸 / seed 数据 / provider override 策略——沿用现有 golden harness 模式（见 `list_sort_filter_bar_golden_test.dart`：`ProviderScope` + `currentLocaleProvider.overrideWith` 同步值 + `MaterialApp` + 固定 `SizedBox`）。
- D39-05 中 active/completed tile 各用哪个 ledger 颜色。
- coverage ≥70% 若个别文件难覆盖时的取舍（优先补真实测试，非降阈值）。
- golden 测试文件落点：`test/golden/`（与现有 golden 同目录）；baseline PNG 落点 `test/golden/goldens/`。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & 验收口径
- `.planning/ROADMAP.md` §"Phase 39" — 5 条 success criteria（验收 bar；SC1 ARB parity、SC2 rename 0-hits、SC3 golden 矩阵、SC4 reactive smoke、SC5 analyze 0 + coverage ≥70%）。
- `.planning/REQUIREMENTS.md` — NAV-03（本 phase 唯一 requirement）+ D1–D8 locked decisions（D5 filter 共享/切段重置、D6 visibility immutable、D8 attribution + dual-ledger accent IN）。

### 前序 phase 决策（直接相关）
- `.planning/phases/38-presentation-shell-ui-widgets/38-CONTEXT.md` — UI 决策来源：D38-01（tap=toggle, 编辑走 trailing chevron）、D38-02（drag handle reorder）、D38-03（batch contextual-action-mode，nav/FAB 隐藏）、D38-04（购物专用 filter bar）；空状态 3 变体、attribution chip 来源（mirror `list_transaction_tile.dart:198-221`）。
- `.planning/phases/37-application-use-cases-sync-integration/37-CONTEXT.md` — application 层 reactive/privacy/tombstone 测试已覆盖（避免本 phase smoke test 重复）；D37-06 privacy gate。
- `.planning/phases/36-data-layer-domain-import-guard/36-CONTEXT.md` — `watchByListType` reactive stream（smoke test 绑定的 DAO 流）。

### v1.6 research
- `.planning/research/PITFALLS.md` — **GAP-2 reactivity lesson**（用 `.watch()` 流，不用 manual invalidate）—— SC4 smoke test 正是验证此点。
- `.planning/research/SUMMARY.md` / `.planning/research/ARCHITECTURE.md` — provider 模式、文件落点。

### Codebase 须读（实现前 mirror）
- `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb` — 全部 shopping 文案已在此；`homeTabTodo`（待 rename）、`todoTab`（待 delete）、`@`-metadata 条目同步处理。
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:45` — 唯一代码引用点（`l10n.homeTabTodo` → `homeTabShopping`）；图标已 `shopping_bag*`（行 28/35）。
- `test/golden/list_sort_filter_bar_golden_test.dart` — golden harness 模板（locale override + 固定尺寸 + `expectLater(find.byType(...), matchesGoldenFile(...))`）。
- `test/golden/list_empty_state_golden_test.dart` / `list_transaction_tile_golden_test.dart` — 空状态 / tile golden 最近邻模板。
- `test/widget/features/shopping_list/presentation/widgets/` — 已有的 shopping widget 测试（`shopping_empty_state_test.dart`、`shopping_item_tile_test.dart`、`shopping_filter_bar_test.dart` 等），golden 可复用其 pump/override 脚手架。
- `lib/application/accounting/.../apply_sync_operations_use_case.dart`（Phase 37 扩展，含 `case 'shopping_item':` 分支）+ `lib/data/daos/`（`watchByListType`）— smoke test 的写入入口与流来源。

### Project rules
- `CLAUDE.md` — i18n 规则（更新全部 3 个 ARB 后跑 `flutter gen-l10n`；输出类 `S`，`l10n.yaml`）、Riverpod 3 约定（provider 名 suffix stripping、`.value` nullable、`ref.listen` 用于 side-effect）、`AppPalette` via `context.palette`（golden 配色来源）、`AppTextStyles.amount*`。
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — golden 配色基线（daily `#5FAE72` / joy 樱粉 / 暖米白背景；dark 变体）。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Golden harness** (`test/golden/list_sort_filter_bar_golden_test.dart` 等 11 个)：`ProviderScope(overrides: [currentLocaleProvider.overrideWith((_) async => locale)])` + `MaterialApp`（含 `S.delegate` + Global*Localizations.delegate）+ 固定 `SizedBox` + `expectLater(find.byType, matchesGoldenFile)`。直接复用此结构建 shopping golden。
- **已有 shopping widget 测试**（`test/widget/features/shopping_list/...`）—— 提供 seed/override 脚手架，golden 可借用其 pump 逻辑。
- **`@Tags(['golden'])`** library tag —— 现有 golden 文件统一打此 tag。

### Established Patterns
- Golden = 组件级、固定尺寸、provider override 同步 locale（避免 settings-repo 异步 timer pending）。历史上部分组件 golden 仅 light；本 phase 须 light+dark 双配色（SC3）—— 用 `themeMode` 参数化（harness 已支持 `theme: ThemeData.light()` / `darkTheme` / `themeMode`，但项目实际配色须经 `AppPalette`/`context.palette`，planner 须确认 golden 用的是 app 主题而非裸 `ThemeData.light()`）。
- ARB 三语同步修改 → `flutter gen-l10n` → 验证 key parity（`jq 'keys|length'` 三者相等）。
- Reactive UI = 绑定 Drift `.watch()` 流，绝不 manual invalidate（GAP-2，SC4 验证点）。

### Integration Points
- **`home_bottom_nav_bar.dart:45`** — 唯一需改的代码点（tab label key）。
- **`lib/l10n/*.arb`** — rename/delete key（含 `@`-metadata）；parity + gen-l10n 校验。
- **`watchByListType('public'|'private')` StreamProvider**（Phase 36 DAO + Phase 38 provider）— smoke test 的观察对象。
- **`ApplySyncOperationsUseCase`**（Phase 37，含 `shopping_item` 分支）— smoke test 模拟远端写入的入口。

</code_context>

<specifics>
## Specific Ideas

- Tab label 要"短得像兄弟 tab"——買い物/购物/Shopping，不带"リスト/清单/List"后缀（D39-01）。
- Golden 不引入新约定：组件级、复用 `list_*_golden_test.dart` 的 harness，落点 `test/golden/` + baseline `test/golden/goldens/`（D39-03）。
- Smoke test 的精神是"写入 → 自动 emit，不 invalidate"——这是 v1.4 GAP-2 教训在 provider 层的回归守卫（D39-06）。
- 双轨边框靠 active/completed tile 顺带各出现一次（daily + joy），不单独成对（D39-05）。

</specifics>

<deferred>
## Deferred Ideas

- **整屏 ShoppingListScreen golden** — 本 phase 用组件级覆盖；若日后想要端到端视觉快照可另议（非 SC 要求）。
- **专门的 daily-vs-joy 双轨边框成对 golden** — 用户选择不单列（D39-05），靠 active/completed 顺带覆盖。
- **v2 shopping enhancements**（SUBTOTAL-01、AUTO-01、GROUP-01、TAGFILT-01、DUP-01、COLLAPSE-01；cross-device synced ordering REORDER-01）— 全部 v2，沿 D8/D37-01 不变。

None beyond the above — 讨论始终在 phase 范围内。

</deferred>

---

*Phase: 39-i18n-golden-re-baseline-smoke-test*
*Context gathered: 2026-06-08*
