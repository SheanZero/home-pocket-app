# 260620-lfp Round-2 — 分类支出卡 + 小确幸日历卡 像素级对齐 mock

**Baseline mock (唯一基准):** `.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html`
**用户指令:** 严格按照 mock 实现这两张卡，**卡片内标题去掉**，内部设计（文字大小/颜色/布局）全部按 mock，**不要自己发挥**。

> 铁律：本 spec 给出的就是全部要求。**任何本 spec 未明确给值的地方，不要自己发挥/不要"优化"** —— 若发现 mock 有而 spec 漏写的，停下来在 SUMMARY 标注、保守保留现状，不要臆造。趋势图卡(WithinMonthTrendCard)与满足度直方图卡**不在本轮范围**，零改动。

---

## 0. 新建颜色 token 文件（color_literal_scan 只允许 core/theme 出现裸 hex）

新建 `lib/core/theme/analytics_category_palette.dart`，内容（精确 hex 来自 mock `--cat-*` / `--heat*`）：

```dart
import 'package:flutter/painting.dart';

/// 分类支出环 + 小确幸日历热力的 mock 专属配色（round5 r5）。
/// 裸 hex 仅允许在 lib/core/theme/（color_literal_scan 白名单按目录）。
abstract final class AnalyticsCategoryPalette {
  /// 生存(日常)系分类环色，按金额降序轮转分配。绿/蓝系，避开樱粉(留给悦己)。
  /// food绿 / house蓝 / transit浅绿 / daily柚绿 / comm浅蓝
  static const List<Color> survivalSequence = [
    Color(0xFF5FAE72), Color(0xFF5B8AC4), Color(0xFF86C79A),
    Color(0xFF9FBF8A), Color(0xFF86A9D6),
  ];
  /// 悦己(soul)系分类环色 —— 樱粉，账本暗示。
  static const Color joy = Color(0xFFD98CA0);
  /// 长尾「其他」/未知分类 —— 中性藕灰。
  static const Color other = Color(0xFFC4B6AD);

  /// 日历热力 4 档离散色 heat0..heat3（0笔→heat0；1→heat1；2→heat2；≥3→heat3）。
  static const List<Color> heat = [
    Color(0xFFF3ECEA), Color(0xFFF4D2DC), Color(0xFFE8A9BC), Color(0xFFD98CA0),
  ];

  static Color survivalAt(int i) => survivalSequence[i % survivalSequence.length];
  static Color heatForCount(int count) =>
      count <= 0 ? heat[0] : count == 1 ? heat[1] : count == 2 ? heat[2] : heat[3];
}
```

---

## 1. 分类支出卡 — `cards/category_donut_card.dart`

### 1a. 去掉卡内标题
`AnalyticsDataCard(...)` 增加 `showHeader: false`（删掉卡内「分类支出」标题+caption；外层 section header 已经标注）。**与趋势卡同一手法。**

### 1b. 顶部 hero-top 行（mock `.hero-top`，在环之上、卡 body 最顶）
一行 `Row(spaceBetween)`：
- 左 hero-cap：文案 = 新 ARB `analyticsDonutHeroCap`（见 §4）。样式 fontSize **13**, FontWeight.**w700**, `palette.textPrimary`。
- 右 hero-tag pill：文案 = 新 ARB `analyticsDonutHeroTag(count, month)`。`count` = 本月支出总笔数 = `monthly.categoryBreakdowns.fold(0,(s,b)=>s+b.transactionCount)`；`month` = `monthly.month`。样式 fontSize **10.5**, w600, 文字色 `palette.dailyText`, 背景 `palette.dailyLight`, 圆角 **7**, padding `EdgeInsets.symmetric(horizontal:9, vertical:3)`。
- hero-top 与下方环间距 `SizedBox(height: 18)`。

> 需把 `month` 和 `count` 传进 `_DonutHero`（目前只传 breakdowns/total/categoryMap/bookId）。

### 1c. 环几何（mock 是**细环+大孔**；当前是粗环）
`PieChart` 改：`centerSpaceRadius: 62`, 每段 `radius: 22`, `sectionsSpace: 0`, `cornerRadius: 0`（mock 弧段直角、相邻紧贴无间隙）。SizedBox 高度保持 200。背景灰底环可保留也可去掉（mock 有 `#F1ECE8` 底环，非必须）。

### 1d. 环+图例配色（核心改动：当前是 daily→joy 渐变 lerp，mock 是**按分类的离散色**）
- 在 `CategoryDonutCard.build` 里 `ref.watch(joyCategoryAmountsProvider(...))`（与 drawer 同 key）拿到 `List<JoyCategoryAmount>`，构造 `Set<String> joyL1Ids = {for (a in amounts) a.categoryId}`（**注意：JoyCategoryAmount.categoryId 已是 L1**，无需再 rollup）。把 `joyL1Ids` 传进 `_DonutHero`。
  - 为避免 drawer 重复请求，可把该 async 的 amounts 一并下传给 `JoySpendDrawer`（可选优化；若不做则各自 watch 同 provider，Riverpod 会去重，**也可接受**）。
- `_DonutHero` 配色算法（**严格按此，勿改**）：遍历 rows（已按金额降序），维护一个 `survivalIdx=0`：
  - `if (joyL1Ids.contains(row.categoryId))` → 颜色 = `AnalyticsCategoryPalette.joy`（樱粉）。
  - `else` → 颜色 = `AnalyticsCategoryPalette.survivalAt(survivalIdx++)`。
  - 长尾「其他」(hasOther) 那段/行 → `AnalyticsCategoryPalette.other`。
  - **删除** `_colorFor`（daily→joy lerp）。环弧色与对应图例行 dot 色**必须一致**。

### 1e. 环中心（mock `.ctr` 三行；当前两行，缺「N 笔」）
垂直三行居中：
- k 标签：`analyticsDonutCenterLabel`（"本月支出"，已存在），fontSize **11**, `palette.textSecondary`。
- v 金额：count-up 总额，fontSize **28**, FontWeight.**w800**, `palette.textPrimary`, tabular（用 AppTextStyles.amount* + copyWith 调到 28/w800）。
- n 笔数：新 ARB `analyticsDonutCenterCount(count)`（count 同 1b），fontSize **10.5**, `palette.textTertiary`, 顶距 `SizedBox(height:3)`。

### 1f. 图例行 `_LegendRow`（mock `.hl`）
- dot：**圆角方块** 11×11, `BorderRadius.circular(4)`（当前是 `BoxShape.circle`，改掉），色=对应环弧色。
- name：fontSize **13**, w600, `palette.textPrimary`, ellipsis。
- amount：fontSize **13**, w700, `palette.textPrimary`, tabular。
- pct：fontSize **11**, w600, `palette.textSecondary`, 宽 **46**, 右对齐。
- 行间分隔：每行底部 1px `palette.borderDivider` 下边线，最后一行无（mock `.hl{border-bottom}` + `:last-child{border-bottom:0}`）。
- **删除右侧 chevron 图标**（mock 图例无 chevron）。行仍可点（保留 InkWell→drill 功能），只是去掉箭头视觉。长尾「其他」行仍不可点。
- 行 padding 垂直 **9**。

---

## 2. 小确幸日历卡 — `cards/joy_calendar_card.dart` + `widgets/joy_calendar_heatmap.dart`

### 2a. 去掉卡内标题
`joy_calendar_card.dart` 的 `AnalyticsDataCard(...)` 加 `showHeader: false`。

### 2b. 顶部加**星期表头行**（mock `.wd` 一二三四五六日，周一起）
heatmap 在网格**之上**加一行 7 列星期头：文案用新 ARB 周一..周日（见 §4，Monday-first）。样式 fontSize **10**, FontWeight.**w700**, `palette.textTertiary`, 居中。与现有 leadingBlanks(=weekday-1，周一起) 对齐 —— **保持周一起**。

### 2c. 网格几何（mock `.cal`）
- `GridView.count(crossAxisCount:7)`：`childAspectRatio: 1.0`（正方形，当前 1.3 改掉），`mainAxisSpacing: 6`, `crossAxisSpacing: 6`（当前 4 改 6）。
- leading 空白格：**不要用 `SizedBox.shrink()`**（会塌陷错位）；用占位**透明格** `SizedBox.expand()` 或透明 `DecoratedBox`，占满网格槽位保持对齐（mock `.cell.empty{background:transparent}`）。

### 2d. 日格 `_DayCell`（mock `.cell` + `.dn`）
- 背景：**离散** `AnalyticsCategoryPalette.heatForCount(count)`（删除连续 lerp `_depthColor`）。
- 圆角：`BorderRadius.circular(8)`（当前 6 改 8）。
- 日号 `.dn`：**右上角**（`Align(Alignment.topRight)` + padding `EdgeInsets.only(top:3,right:4)`），**非居中**。fontSize **8.5**, FontWeight w700。颜色：count==0 → `palette.textTertiary`；count==1(heat1) → `palette.joyText`；count≥2(heat2/heat3) → 白色 `Colors.white`（mock：h2/h3 .dn 白，h1 .dn joyText）。
  - 注意：白色字属 UI 语义对比色非分类裸 hex，但稳妥起见也放 core/theme 或用现成 `Colors.white`（`color_literal_scan` 通常不拦 `Colors.white`；若拦则用 palette 里现成的白 token）。
- 选中环：保留现有 `palette.joyText` 2px border。
- 点击展开 inline 面板：**保留**（功能，非 mock 元素，仅点击后出现，不影响默认视觉）。

### 2e. 图例 `_CalLegend`（mock `.cal-legend`）
4 个色块改用**离散** `AnalyticsCategoryPalette.heat[0..3]`（当前 lerp 改掉）。其余（淡/浓/note 文案）保留。色块 13×13 圆角 4。

### 2f. 底部加 cal-cap（mock `.cal-cap`）
图例下方加一段说明：新 ARB `analyticsCalCap(days)`，`days` = 本月有悦己的天数 = `countByDay.values.where((c)=>c>0).length`。fontSize 11, `palette.textTertiary`, line-height 1.55。（原先这句信息在被删掉的卡 caption 里。）

---

## 3. 卡 §1/§2 都要：去标题后不要留空 header 间距

确认 `AnalyticsDataCard(showHeader:false)` 路径不会留下多余 12px gap（看其 build：showHeader false 时整段不渲染，OK）。

---

## 4. ARB（ja 默认 / zh / en 三份全加，然后 `flutter gen-l10n`）

新增 key（占位符类型标注在 template 文件的 placeholders 里）：

| key | zh | ja | en | placeholders |
|---|---|---|---|---|
| analyticsDonutHeroCap | 这个月，钱花在哪 | 今月、お金はどこへ | Where your money went this month | — |
| analyticsDonutHeroTag | {count} 笔 · {month} 月 | {count}件 · {month}月 | {count} entries · month {month} | count:int, month:int |
| analyticsDonutCenterCount | {count} 笔 | {count}件 | {count} entries | count:int |
| analyticsCalCap | 这个月有 {days} 天，为自己留下了一点小确幸 · 只看「哪些天发生过」 | 今月は {days} 日、自分のための小さな幸せ · 「あった日」を見るだけ | {days} days this month held a small joy · just which days | days:int |
| analyticsCalWeekdayMon | 一 | 月 | M | — |
| analyticsCalWeekdayTue | 二 | 火 | T | — |
| analyticsCalWeekdayWed | 三 | 水 | W | — |
| analyticsCalWeekdayThu | 四 | 木 | T | — |
| analyticsCalWeekdayFri | 五 | 金 | F | — |
| analyticsCalWeekdaySat | 六 | 土 | S | — |
| analyticsCalWeekdaySun | 日 | 日 | S | — |

> **anti-toxicity 注意：** `analyticsCalCap` 我已**去掉**了 mock 原文里的「不数连续、不比多少」（含 连续/比 触发词），改为更短的中性版「只看哪些天发生过」。若 `anti_toxicity_phase47_test` 仍对这些新串报错，**保持 ADR-012 中性语义改词**（不要加排名/目标/跨期/连续/比较语义），改完重跑通过。

---

## 5. 验收闸（必须全绿，按序）

1. `flutter gen-l10n` 成功，无缺 key。
2. 若动到 @riverpod/@freezed/ARB：跑 `flutter pub run build_runner build --delete-conflicting-outputs`（本轮大概率只 gen-l10n 即可）。`lib/generated/` 被 add 拒绝时用 `git add -f`。
3. `flutter analyze` → **0 issues**。
4. `flutter test`（全量）→ 全绿。特别注意：`color_literal_scan`（新 palette 在 core/theme ✓）、`hardcoded_cjk_ui_scan`（新 UI 文案全走 ARB ✓）、`anti_toxicity_phase47`（新 joy/cal 文案）、donut/calendar 相关 widget 测试。
5. **macOS 重基线**受影响 golden（donut card / joy_calendar card / analytics scroll-smoke 等）：`flutter test --update-goldens <具体文件>`，**勿**全量 update。零 golden 删除。
6. 原子提交：建议 3 个 commit —— (a) palette token 文件，(b) 分类支出卡 mock 对齐，(c) 小确幸日历卡 mock 对齐 + ARB/gen-l10n（或把 ARB 并进 a）。**不要**提交 .planning/ docs（orchestrator 负责）。

## 6. 产出
写一份简短 SUMMARY 到 `.planning/quick/260620-lfp-round5-r5-drawer-joybar-html-mock/260620-lfp-SUMMARY-R2.md`：列改动、commit hash、analyze/test 结果、重基线 golden 数、anti-toxicity 处理、以及**任何本 spec 未覆盖而你保守保留的点**。
