# 260620-lfp Round-4 — 悦己满足度分布直方图卡 像素级对齐 SUMMARY

**状态:** 已完成 · 全闸绿 · 2 原子提交 on `main` · NO worktree
**范围:** 仅悦己满足度直方图卡（donut/calendar/joy-drawer/trend 零改动）

---

## 改动

### 1. 颜色 token — `lib/core/theme/analytics_category_palette.dart`
- 新增 `static const Color histoBarBottom = Color(0xFFE7A6B6);`（mock `.bar` 渐变底色）。新裸 hex 仅落在 core/theme，符合 color_literal_scan 白名单。

### 2. 重写 `satisfaction_distribution_histogram.dart`（弃 fl_chart → 自定义 flex 柱）
- 图表区固定高 140 的 `Row` / 10 个 `Expanded` 列 / `crossAxisAlignment: end`。
- 每列 `_BarColumn`：
  - count>0 → 柱顶计数标 `Text('$count')`（fontSize 10 / w700 / `palette.joyText`）；count==0 → 同高（14px）占位，保持柱顶基线一致。
  - 柱：`ConstrainedBox(maxWidth: 22)`，顶圆角 5 / 底圆角 2。
  - count>0 → `barH = max(8, count/maxCount * 110)`，**统一**粉色竖直渐变 `[palette.joy, AnalyticsCategoryPalette.histoBarBottom]`（topCenter→bottomCenter）。
  - count==0 → `barH = 3`，纯色 `palette.backgroundMuted`。
  - 中位桶（`score == medianScore`）→ `Container(padding: all(1), border: all(medianBorder, 2))` 外描边；`medianBorder = Color.lerp(palette.joy, palette.joyLight, 0.55)!`。
- 分数标行：10 个 `Expanded` 居中 `Text('$score')`（fontSize 10.5 / w600 / `palette.textSecondary`）。
- foot：左 count footer（`analyticsHistogramCountFooter(total)`）+ 右中位 pill（仅 `medianScore != null`，joyLight 底 / joyText / 圆角7 / pad 9·3）。
- caption：`analyticsHistogramJoyCaption`（fontSize 11 / `palette.textTertiary` / height 1.55）。
- **保留**：`_normalize`（1–10 补零）、`_weightedMedian`（数据派生加权中位，**永不**硬编码「7」）、`Semantics` label（中性事实）。
- **删除**：`BarChart`/`FlGridData`/`BarTouchData`/`_colorForScore`/「5」注释（不再引用 `analyticsHistogramBarFiveAnnotation`）。fl_chart import 移除。

### 3. 卡片去标题 — `cards/satisfaction_histogram_card.dart`
- `AnalyticsDataCard(showHeader: false, ...)`。title/caption 仍传（必填），但不再渲染——section header 已标注。`totalJoyTx < 5` 自隐 + async 分支不动。

### 4. ARB（三语 + gen-l10n）
- 新增 `analyticsHistogramJoyCaption`（en/ja/zh，spec §4 精确字符串）+ `@`-描述。
- `analyticsHistogramColorCaption` / `analyticsHistogramBarFiveAnnotation`：**保留** key（三语未删），避免 arb_key_parity churn —— 现已无运行时引用（保守选择，spec §4 允许二选一）。
- `flutter gen-l10n` 重生成 `lib/generated/app_localizations*.dart`。

### 5. 测试 — `satisfaction_distribution_histogram_test.dart`
- 从 fl_chart 结构断言改为自定义柱断言：10 分数标、非零柱计数标存在 / 零柱无计数标（恰 3 根渐变柱）、统一渐变跨所有柱相同且底色 == `histoBarBottom`、中位桶（数据派生 score 4，非 mock 字面 7）恰 1 个描边 wrapper、footer + 中位 pill + 暖 caption、Semantics 中性、空桶不抛 + 无中位 pill。7 测试全绿。

---

## Commits（atomic on `main`）
- `fe234195` — feat(analytics): rebuild 悦己满足度分布 histogram as custom flex bars (drop fl_chart)（impl + palette token + 三语 ARB + gen-l10n 生成文件 + 重写 widget test）
- `2cee111a` — test(analytics): rebaseline histogram goldens for custom flex bars（8 masters）

> `.planning/` docs 未提交；ROADMAP/STATE 未动。

---

## 闸结果（按序全绿）
1. **flutter gen-l10n** — OK（新 caption key 生成）。
2. **flutter analyze** — `No issues found!`（0 issues）。
3. **flutter test（全量）** — `All tests passed!`（**3072** 测试）。含 color_literal_scan / hardcoded_cjk_ui_scan / anti_toxicity_phase47（36 sweeps）/ arb_key_parity / satisfaction_distribution_histogram widget（7）。
4. **macOS 重基线** — targeted `--update-goldens`，**8** masters 修改，**零删除**：
   - `satisfaction_histogram_card_{light,dark}_{en,ja,zh}.png`（6）
   - `satisfaction_histogram_card_light_ja.png` 等已含其中（实为 light×3 + dark×3 = 6）
   - `analytics_screen_scroll_smoke_light_ja.png`（1）
   - （实际清单：light_en/ja/zh + dark_en/ja/zh + scroll_smoke_light_ja = **7 文件**；empty_light_ja **未变**——空态卡自隐，直方图体不渲染。）

> 校正：git diff 显示实际改动为 **7 个 PNG**（6 satisfaction + 1 scroll smoke）。`satisfaction_histogram_card_empty_light_ja.png` 未变（自隐态），符合预期，无需重基线。

---

## anti-toxicity 处理
- 新 caption 为描述性暖文案，无 排名/目标/连续/跨期 语义。
- `anti_toxicity_phase47_test`（forbidden 子串：en `score`/`rank`/`vs`…、zh `分数`/`排名`/`对比`…、ja `スコア`/`ランキング`…）三语 × value/self_hide sweep **全绿，未误报**。无需改词重跑。

---

## 保守保留 / spec 未覆盖点（无擅自发挥）
- **`maxBarHeight` / `_maxBarHeight=110`、`_chartHeight=140`、`_countLabelHeight=14`、count>0 下限 `max(8, …)`**：均为 spec §2「建议」值，照采用。
- **分数标位置**：spec 允许「独立行」或「并进每列 Column 末尾」二选一 —— 采用**独立 Row**（更易保证 10 列对齐）。
- **保留 `analyticsHistogramColorCaption` / `analyticsHistogramBarFiveAnnotation` key**：spec §4 允许保留或删除，选**保留**以零 parity churn（现无引用，纯死 key）。
- **零桩圆角**：mock `.bar.zero` 仅覆盖 height，圆角沿用 `.bar` 的 `5 5 2 2` —— 实现中零桩同样用 `_barRadius`（顶5底2），与 mock 一致。
- **中位 border 颜色**：沿用现算法 `Color.lerp(palette.joy, palette.joyLight, 0.55)`（spec §2 明示），非 mock 的 `--joyBorder` 字面值（保持运行时 palette 派生）。

---

## Self-Check: PASSED
- `lib/core/theme/analytics_category_palette.dart` — FOUND（histoBarBottom）
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` — FOUND（无 fl_chart import）
- `lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart` — FOUND（showHeader: false）
- commit `fe234195` — FOUND
- commit `2cee111a` — FOUND
- 全量测试 3072 绿、analyze 0 issues、7 golden 重基线零删除。
