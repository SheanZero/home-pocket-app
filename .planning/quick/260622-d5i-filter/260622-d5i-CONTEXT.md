# Quick Task 260622-d5i: 统计页「分类支出」卡片 — 悦己部分去边框/分割线分离 + 随成员维度&筛选联动 — Context

**Gathered:** 2026-06-22
**Status:** Ready for planning (design confirmed by user; HTML draft = `260622-d5i-DESIGN.html`)

<domain>
## Task Boundary

统计页（analytics）「カテゴリ支出 / 分类支出」卡片 (`CategoryDonutCard`) 内嵌的悦己 joybar 抽屉 (`JoySpendDrawer`)：
1. **去掉樱粉边框**，改用分割线 (分割线) 把悦己部分和「整体」(donut + 类别图例) 分离。
2. 让悦己部分内容随顶部「分类/成员」维度切换 **和** 成员筛选联动，逻辑与整体分类明细一致。

**不在范围内：** `PerCategoryBreakdownCard`（独立排名列表，无边框、无悦己分区，与本任务无关）、`DailyVsJoyCard`、`happiness_ring_palette`。
</domain>

<decisions>
## Implementation Decisions (LOCKED — confirmed via design gate)

### D1 — 视觉：去边框 + 分割线（已确认「按这个稿开发」）
- 移除 `JoySpendDrawer` 外层 `Container` 的 `border: Border.all(drawerBorderColor)`（樱粉描边）、`borderRadius`、盒子内边距 `(16,16,16,15)`。
- 在悦己部分顶部插入一条 1px 水平分割线，颜色 `context.palette.borderDivider (#EAE1DC)`，上下留白约 16/14px，宽度跟随卡片内容。
- 悦己内容直接贴合卡片 padding 渲染（不再有独立带框盒子）。
- **保留**一个小的「♡悦び」标签 chip（`palette.joyLight` 底 / `palette.joyText` 字），让悦己身份依旧清晰；同一行右侧保留 ¥总额（`joyText`，tabular）+ 计数。数据/文案不变。

### D2 — 行为：成员筛选联动（两种维度都生效）
- `JoySpendDrawer` 改为读取 `donutDimensionStateProvider`（`DonutDimensionView{dimension, memberFilterDeviceId}`）。
- **成员筛选 (`memberFilterDeviceId`)** 设置后，悦己部分收窄到该成员，复用与整体完全相同的 `tx.deviceId == deviceId` 过滤规则（见 `memberFilteredCategoryBreakdown`）。

### D3 — 行为：维度切换（已确认「切成员维度时悦己也按成员拆」）
- `dimension == category`：悦己 = **按类别**看悦己花在哪（现有分组），按成员筛选收窄。
- `dimension == member`：悦己 = **按成员**拆分的悦己花销（新视图：每个成员的悦己总额），按成员筛选收窄（选定成员→单段）。
- 维度切换与整体 donut 一致：category→`monthlyReport`/`memberFilteredCategoryBreakdown`；member→`memberSpendBreakdown`(筛选)。悦己镜像同一开关。

### Claude's Discretion (合理默认，无需再问)
- 成员模式条形图：复用 `JoySpendStackedBar` + `JoySpendSegment`，label=成员名（来自 `CategoryDonutCard` 已算好的 `memberNames`/`memberEmojis`），color 用 `JoyWarmPalette.colorAt(index)` 保持暖色一致，icon 用一个通用「人」图标（`JoySpendSegment.icon` 是 `IconData`，成员无 IconData，用 `Icons.person_outline` 之类占位）。
- 计数文案：category 模式沿用 `analyticsJoyDrawerCount`（「N カテゴリ」）；member 模式新增 `analyticsJoyDrawerMemberCount`（「N メンバー / N 名成员 / N members」）。
- 空态：沿用 `JoySpendDrawerBody` 的 `analyticsJoySpendEmpty`。
</decisions>

<code_context>
## Ground-Truth Implementation Map (verified 2026-06-22)

### Presentation
- **`lib/features/analytics/presentation/widgets/joy_spend_drawer.dart`** — `JoySpendDrawer` (ConsumerWidget). THE target. 当前：watch `joyCategoryAmountsProvider(bookId,startDate,endDate,joyMetricVariant)`；用带樱粉边框的 `Container`（`border: Border.all(Color.lerp(joy,joyLight,0.55))`, radius 18, padding (16,16,16,15)）；内含 drawer-top Row（`analyticsJoyDrawerTitle`=「悦び {amount}」joyText + `analyticsJoyDrawerCount`=「{count} カテゴリ」joyText）+ `JoySpendDrawerBody(amounts, showTotalHeader:false)`。错误分支 invalidate `joyCategoryAmountsProvider`。
- **`lib/features/analytics/presentation/widgets/cards/category_donut_card.dart`** — `CategoryDonutCard` (ConsumerWidget). 在 `wrap(hero)` 里 hero 之后渲染 `JoySpendDrawer(bookId,startDate,endDate,joyMetricVariant)`。已计算好 `donutView`(`donutDimensionStateProvider`)、`memberNames`、`memberEmojis`、`members`、`selfDeviceId` —— 需把 `donutView`/`memberNames`/`memberEmojis` 下传给 `JoySpendDrawer`。`categoryDonutRefreshTargets(ctx)` 是刷新目标单源（当前含 `monthlyReport`+`joyCategoryAmounts`+`memberSpendBreakdown`）。
- **`lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart`** — `JoySpendDrawerBody(amounts: List<JoyCategoryAmount>, showTotalHeader)`. 把 amounts 映射成 `JoySpendSegment`（label 走 `CategoryLocalizationService.resolveFromId`，color `JoyWarmPalette.colorAt(i)`，icon `parentCategoryIconFromId`），渲染 `JoySpendStackedBar`。**成员模式需要一个并行的 segment 构造**（label=成员名、icon=通用人像、color=JoyWarmPalette）——可在 body 加一个命名构造/参数，或在 drawer 内直接构造 segments 传给 `JoySpendStackedBar`。
- **`lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart`** — `JoySpendStackedBar(segments: List<JoySpendSegment>)`，`JoySpendSegment{label,amount,formattedAmount,percent,color,icon}`。通用、可复用。
- **`lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart`** — 维度 toggle + 成员筛选 trigger（无需改，仅参考其 `_withSelf`/`_displayName` 取名逻辑）。

### State (providers)
- **`lib/features/analytics/presentation/providers/state_donut_dimension.dart`** — `donutDimensionStateProvider` / `DonutDimension{category,member}` / `DonutDimensionView{dimension, memberFilterDeviceId}`。memberFilter 跨维度保留。
- **`lib/features/analytics/presentation/providers/state_analytics.dart`**：
  - `joyCategoryAmounts(bookId,startDate,endDate,joyMetricVariant)` (~line 302) → `getJoyCategoryAmountsUseCaseProvider`. **加可选 `String? deviceId` 进 family key 并传给 use case。**
  - `memberFilteredCategoryBreakdown(...,deviceId,...)` (~line 102) — 成员筛选过滤规则的参照：`tx.deviceId == deviceId`。
  - `memberSpendBreakdown(bookId,startDate,endDate,joyMetricVariant)` (~line 178) → `getMemberSpendBreakdownUseCaseProvider`. 整体成员维度数据；**新增并行 `joyMemberAmounts` provider** 复用同 use case 但传 `ledgerType: LedgerType.joy`。

### Application (use cases)
- **`lib/application/analytics/get_joy_category_amounts_use_case.dart`** — `GetJoyCategoryAmountsUseCase.execute({bookIds,startDate,endDate,entrySourceFilter})`. 过滤 `tx.type==expense && entrySource`。**加可选 `String? deviceId`：`&& (deviceId==null || tx.deviceId==deviceId)`**（与 memberFiltered 一致）。
- **`lib/application/analytics/get_member_spend_breakdown_use_case.dart`** — `GetMemberSpendBreakdownUseCase.execute({bookIds,startDate,endDate,entrySourceFilter})`，当前 `ledgerType: null`（跨账本）。**加可选 `LedgerType? ledgerType`（默认 null=现状不变），传给 `findByBookIds`**；joy-by-member provider 传 `LedgerType.joy`。`MemberSpendBreakdown{deviceId,amount,transactionCount}`。

### Theme tokens (ADR-019 light, lib/core/theme/app_palette.dart)
- card `#FFFFFF`, background `#FBF7F4`, textPrimary `#20352B`, textSecondary `#71877A`.
- borderDivider `#EAE1DC`, borderDefault `#E6DDD8`.
- joy `#D98CA0`, joyText `#A53D5E`, joyLight `#FBEAEF`; daily `#5FAE72`, dailyText `#2E6B3A`.
- JoyWarmPalette j1..j7: `#D98CA0 #E2A23B #E0664B #9B5DA6 #EBB87A #B08363 #C7A7AE` (`JoyWarmPalette.colorAt(i)`).
- **NEVER 裸 hex** in widgets — resolve via `context.palette` / `JoyWarmPalette` (RESEARCH A5 rule already in this code).

### Tests / goldens (macOS-baselined — we ARE on macOS, update goldens here)
- `test/golden/category_donut_card_golden_test.dart` — 主 golden（需 `--update-goldens` 重基线；考虑加 member-dimension joy 变体）。
- `test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart` — 结构 widget 测试（去框/分割线后更新）。
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart` — 反毒性（确认去框不破）。
- `test/golden/analytics_screen_scroll_smoke_golden_test.dart` — 滚动 smoke（可能受影响）。
</code_context>

<gotchas>
## Pitfalls (from project memory — MUST honor)
- **l10n generated files gitignored-yet-tracked:** 新增 `analyticsJoyDrawerMemberCount` 到全部 3 个 ARB (ja/zh/en) → `flutter gen-l10n` → 提交时 `lib/generated/` 的 `git add` 可能被拒，必须 **`git add -f lib/generated/`**，否则 analyze 从干净树会失败。
- **架构测试跑全量：** 提交前 `flutter analyze`（0 issues）+ 跑受影响 test；CJK UI 文案必须走 `S.of(context)`（`hardcoded_cjk_ui_scan` 会扫硬编码中日文）。
- **Drift schema 不动**（复用 `findByBookIds`，无新 DAO/迁移，schema 维持现状）。
- **GUARD-01：** analytics 卡片不得 import `home/*`。
- **刷新目标：** 把新增的 `joyMemberAmounts`(未筛选 key) 折进 `categoryDonutRefreshTargets`，保持下拉刷新覆盖。
</gotchas>

<canonical_refs>
## Canonical References
- 设计稿：`.planning/quick/260622-d5i-filter/260622-d5i-DESIGN.html`（Before/After/After+filter 三态）
- ADR-019 桜餅×若葉 palette：`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`
- 悦己 joybar 来源（Phase 46/round-5 r5）：`CategoryDonutCard` doc-comments；D2/260620-v2m 成员维度。
</canonical_refs>
