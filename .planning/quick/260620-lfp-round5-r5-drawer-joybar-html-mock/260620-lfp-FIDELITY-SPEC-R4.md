# 260620-lfp Round-4 — 悦己满足度分布 直方图卡 像素级对齐 mock

**基准 mock:** `round5/r5-drawer-joybar.html` 的 `.histo` / `.histo .b` / `.bar` / `.cnt` / `.x` / `.b.med` / `.histo-foot` / `.histo-cap`
**用户反馈:** 「这个卡片没有实现」。当前是 fl_chart（带网格线、绿→粉→绿色阶、柱顶无计数、残留「5」注释、有卡内标题），与 mock 差距大。

> 铁律同前：本 spec 给值即全部要求，**不要自己发挥**。范围仅 **悦己满足度直方图卡**。其它卡零改动。
> 当前实现用 fl_chart —— 本轮**改成自定义 flex 柱状**（与 joybar/日历同思路），以获得像素控制。

---

## mock 直方图结构（要逐条还原）
- 10 根柱（满足度 1–10），从公共基线向上长高，柱高 ∝ count。
- **每根非零柱"顶上"有计数标**（`.cnt`：joyText / 10px / w700）。count==0 → 灰色 3px 残桩（`.bar.zero` neutralBg），**无**计数标。
- 柱：max-width **22**，顶圆角 **5**、底圆角 **2**；填充 = **统一**粉色竖直渐变（顶 `--joy` → 底 `#E7A6B6`）。所有柱同一渐变（**不**按分数变色）。
- **中位**桶：2px joyBorder 描边、offset 1（`.b.med .bar{outline}`）。中位 = 数据派生加权中位（保留现算法，**不**硬编码「7」）。
- 柱下：分数标 `.x`（10.5px / textSecondary / w600）。
- 无网格线、无 tooltip、无「5」注释。
- 图下 foot：左「{count} 笔悦己支出的满足度」+ 右「中位满足度 {value}」pill（joyLight 底 / joyText / 圆角7 / pad 9·3）。
- 末尾 caption：mock 暖文案（见 §3）。

---

## 1. 颜色 token（`lib/core/theme/analytics_category_palette.dart`，core/theme 允许裸 hex）
新增：
```dart
/// 满足度柱渐变底色（mock .bar 渐变 var(--joy)→#E7A6B6）。顶色用运行时 palette.joy。
static const Color histoBarBottom = Color(0xFFE7A6B6);
```

## 2. 重写 `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart`
**弃 fl_chart**，改自定义。保留：`_normalize()`（1–10 补零）、`_weightedMedian()`（数据派生中位，§D4）、`Semantics` label。
删除：`BarChart`/`FlGridData`/`BarTouchData`/`_colorForScore`/「5」注释（`analyticsHistogramBarFiveAnnotation` 不再用）。

新 build 结构（值照给）：
- 图表区：固定高度（建议 **140**）的 `Row`，10 个 `Expanded` 列，`crossAxisAlignment: end`。
  - 每列 `Column(mainAxisAlignment: end)`：
    - 计数标：count>0 → `Text('$count')`（fontSize 10 / w700 / `palette.joyText`），居中；count==0 → 同高占位 `SizedBox(height: ~14)`（保持柱顶基线一致）。
    - `SizedBox(height: 2)`
    - 柱：`ConstrainedBox(maxWidth: 22)` 包 `Container(height: barH, decoration: ...)`：
      - count==0 → `barH = 3`，纯色 `palette.backgroundMuted`，圆角 2。
      - count>0 → `barH = (count / maxCount) * maxBarH`（`maxBarH` 建议 **110**，对 count>0 给个下限如 `max(8, …)`），`gradient: LinearGradient(begin: topCenter, end: bottomCenter, colors: [palette.joy, AnalyticsCategoryPalette.histoBarBottom])`，`borderRadius: only(topLeft:5, topRight:5, bottomLeft:2, bottomRight:2)`。
      - 中位桶（`score == medianScore`）：外描边 —— 用 `Container(padding: EdgeInsets.all(1), decoration: BoxDecoration(border: Border.all(color: medianBorder, width: 2), borderRadius: 顶5底2))` 包住柱；`medianBorder = Color.lerp(palette.joy, palette.joyLight, 0.55)!`。
- `SizedBox(height: 6)`
- 分数标行：`Row` 10 个 `Expanded(child: Text('$score', center, fontSize 10.5 / w600 / palette.textSecondary))`。
  - （也可把分数标并进每列 Column 末尾——只要 10 列对齐即可，二选一。）
- `SizedBox(height: 14)`
- foot `Row`：`Expanded(Text(l10n.analyticsHistogramCountFooter(total), caption/textSecondary))` + 中位 pill（仅 `medianScore != null` 时）`Container(joyLight, 圆角7, pad 9·3, child: Text(l10n.analyticsHistogramMedianPill(medianScore), joyText/w600))`。（这段当前已基本符合，沿用。）
- `SizedBox(height: 9)`
- caption：`Text(l10n.analyticsHistogramJoyCaption, fontSize 11 / palette.textTertiary / height 1.55)`（**新 key**，§3；替换原 `analyticsHistogramColorCaption`）。

## 3. 卡片去标题 `lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart`
`AnalyticsDataCard(...)` 加 `showHeader: false`（去掉卡内「悦己·满足度分布 1–10」标题；外层 section header 已标注）。保留 `totalJoyTx < 5` 自隐 + async 分支不动。

## 4. ARB（ja/zh/en 三份 + gen-l10n）
新增 `analyticsHistogramJoyCaption`：
- zh：`大多落在中高位——为自己花的钱，多数让你感到值得，偶有几笔不那么满意，也都是真实的体验。`
- ja：`多くは中〜高め —— 自分のために使ったお金は、たいてい「よかった」と思える。たまに今ひとつでも、それも本当の体験。`
- en：`Mostly mid-to-high — money you spend on yourself usually feels worth it; the occasional miss is a real experience too.`

`analyticsHistogramColorCaption` 与 `analyticsHistogramBarFiveAnnotation` 改为不再被引用：可保留 key（避免 parity churn）或一并三语删除——**二选一，保持 `arb_key_parity` 绿**。
> anti-toxicity：新 caption 为描述性暖文案，无 排名/目标/连续/跨期 语义；若 `anti_toxicity_phase47_test` 误报，改 ADR-012 中性词后重跑绿。

## 5. 测试
更新 `test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart`：原断言可能查 fl_chart 结构 / 「5」注释 → 改为查自定义柱（计数标文本、中位描边、零桩、分数标、footer、pill、caption）。保持其测试意图。

## 6. 验收闸（按序全绿）
1. `flutter gen-l10n`（新 caption key）。
2. `flutter analyze` → 0 issues。
3. `flutter test`（全量）→ 全绿（color_literal_scan：新 hex 仅 core/theme；hardcoded_cjk_ui_scan；anti_toxicity_phase47；satisfaction_distribution_histogram widget 测试；arb_key_parity）。
4. **macOS 重基线**：9 个 `satisfaction_histogram_card_*` golden（light/dark × en/ja/zh + empty）+ `analytics_screen_scroll_smoke_*`（直方图在内）。targeted `--update-goldens`，零删除。
5. 原子提交（1–2 个）。**不提交** .planning/ docs。不动 ROADMAP/STATE。

## 7. 产出
SUMMARY → `260620-lfp-SUMMARY-R4.md`：改动、commit、analyze/test、重基线 golden 数、anti-toxicity 处理、保守保留点。
