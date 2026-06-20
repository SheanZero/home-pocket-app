# Quick Task 260620-v2m: 统计页趋势图柔化/阴影 + 圆环重做(#14) + 成员切分/过滤 - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Task Boundary

统计页面（analytics_screen）两块修复：

**Part 1 — 支出趋势 (within-month cumulative line chart):**
1. 线条变化更柔和（角度不要太锐化）— 曲线平滑化
2. 选「日常」后，日期+金额标签位置仍不对 —— 应在**标注终点（current 端点 marker）的正上方**（参考图 #6）
3. 折线下方加**渐变阴影/面积填充**（参考图 #8，mock 折线下有淡淡的渐变 below-bar fill）

**Part 2 — 分类支出圆环 (category-spend donut, DonutHero):**
1. 圆环按参考图 #14 **重新实现**：标签（百分比 + 分类名）排布在环上、中心显示「本月支出 + 总额」
2. 增加「分类 / 成员」切分切换按键（参考图 #10 红框）—— 切到「成员」时圆环+图例按成员展示支出比例
3. 增加「成员」过滤下拉能力（参考图 #12 / #13）—— 默认「所有成员」，点开列出各成员，可过滤只看某成员的支出

</domain>

<decisions>
## Implementation Decisions (LOCKED — do not revisit)

### D1 — 圆环切片配色：App 调色板（ADR-019），不用参考图彩虹
- 沿用 ADR-019「桜餅×若葉」体系，为 8~10 个分类生成**协调的 若葉绿 / 琥珀 / 钢蓝 家族色阶**。
- **布局** 照搬 #14（标签在环上 + 中心总额），但**配色一律用本 App 体系**，与支出趋势图、首页风格统一。
- 深色模式必须自动适配（`context.palette` / `AppPalette.dark`）。
- 切片颜色需为分类生成稳定、可区分的色阶（同一分类跨刷新颜色稳定）。

### D2 — 成员归属：deviceId → group_members（单设备优雅降级）
- **本 App 交易没有「付款人」字段。** 唯一的每笔成员身份是记账设备 `transactions.deviceId`。
- 成员切分 = `group by deviceId`，显示名/头像经 `group_members`（`GroupMemberDao.watchByGroupId` → `displayName` / `avatarEmoji`）解析。
- 未加入家庭群组 / 单设备时 = **只有 1 个成员**（圆环单片），过滤器仍可用（仅「所有成员」+ 自己）。优雅降级，不报错、不空白。
- 「共同帐户」这种参考图里的伪成员**本轮不单列**（本 App 模型无对应概念）。

### D3 — 圆环标签布局：环上只标百分比，分类名+金额留图例（用户选，折中）
- 参考图 #14 把「% + 分类名」标在环上；本轮**环上只显示百分比**（如 `28.9%`），**分类名 + 金额保留在下方可点图例行**，中心保留「本月支出 + 总额」。
- **关键改动:** 当前 hero（`donut_hero.dart`）环上 `title: ''`（无标签）→ 必须改为显示各切片 `%`。`category_spend_donut_chart.dart` 已有该能力（`PieChartSectionData.title: '${percentage}%'`, radius 72, titleStyle=caption），可直接参照其样式/位置移植进 hero。
- 成员模式同理：环上标各成员占比 `%`，成员名+头像+金额在图例行。
- 小切片 / 长尾「其他」的 `%` 标签避让由实现裁定（如某阈值以下不在环上标、仅图例显示），须可读不糊。
- 这条**修正了原 PLAN 的 must_haves truth #2**（原写「沿用 #14 布局…可点图例行」但**漏了环上 % 标签**）——环上 % 标签是本轮必须新加的，不是「已落地」。

### Claude's Discretion
- 参考图 #14 中心的**文件夹图标 + 分页圆点**是参考 App 自身导航 chrome，本 App **不复制**（仅做 环+环上%标签+中心总额）。
- 环上小切片标签重叠（如 #14 里 5.3%/1.5% 重叠）的避让策略由实现决定（如阈值以下走外引线 / 合并「其他」 / 仅图例不上环），但需可读。
- 「分类/成员」切换 与 「成员过滤」的具体控件样式（segmented control vs chips、下拉 vs bottom sheet）由实现决定，须符合 ADR-019 与现有 analytics 控件风格（参考 `time_window_chip` / `time_window_picker_sheet`）。
- 成员切分时是否同时尊重当前「成员过滤」选择（过滤优先，再按分类/成员切分）由实现决定，倾向：过滤是全局收窄，切分是当前视图维度。

</specifics>

<canonical_refs>
## Canonical References

- **配色:** `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`；`lib/core/theme/app_palette.dart`（`context.palette`）。
- **趋势图现状（近两轮 quick）:** `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart`（jx2/kll 已加坐标轴/网格/上月对比线/端点上下对置标签）；`within_month_trend_card.dart`。
- **圆环现状:** `DonutHero`（`lib/features/analytics/presentation/widgets/donut_hero.dart`, 335行）+ `category_spend_donut_chart.dart`（148行）；卡 `cards/category_donut_card.dart` 喂 `monthlyReportProvider.categoryBreakdowns`。
- **成员数据源:** `lib/data/daos/group_member_dao.dart`（`watchByGroupId` / `findByGroupId`）；`lib/data/tables/group_members_table.dart`（`displayName`/`avatarEmoji`）；`transactions.deviceId`。**无 payer 字段**。
- **成员过滤先例:** `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart`（过滤器 Notifier 模式可参考）。
- **L1 分类 rollup:** `rollupCategoryBreakdownsToL1`（D-11，图例 10 行 L1 来源）。
- **i18n:** 所有新文案走 `S.of(context)`，三套 ARB（ja/zh/en）齐更新后 `flutter gen-l10n`。金额走 `NumberFormatter`，日期走 `DateFormatter`。
- **goldens:** macOS 基线；改动 analytics 卡片需重基线相关 golden（趋势卡 / analytics_screen_smoke / 圆环卡），全套测试须绿。

</canonical_refs>
