# 悦己满足度直方图卡自定义 flex 柱重建 + 对齐 mock（260620-lfp R4）

**日期:** 2026-06-20
**时间:** 18:12
**任务类型:** UI 保真 / 重构
**状态:** 已完成
**相关模块:** MOD-007 Analytics

---

## 任务概述

用户反馈「悦己满足度分布」卡「没有实现」（指未对齐 mock）。当前为 fl_chart BarChart：带网格线、
绿→粉→绿色阶、柱顶无计数、残留「5」注释、有卡内标题，与 mock `round5/r5-drawer-joybar.html` `.histo` 差距大。
本轮弃 fl_chart，改自定义 flex 柱状，逐条还原 mock。

---

## 完成的工作

### 1. `lib/core/theme/analytics_category_palette.dart`
新增 `histoBarBottom = Color(0xFFE7A6B6)`（柱渐变底色，core/theme 允许裸 hex）。

### 2. `satisfaction_distribution_histogram.dart`（重写，弃 fl_chart）
- 10 个 `Expanded` 列、图表区高 140、`crossAxisAlignment: end` 共基线。
- 每非零柱**顶上计数标**（joyText / 10px / w700）；count==0 → **3px 灰残桩**（backgroundMuted）+ 14px 占位（保持柱顶基线一致）、无计数标。
- 柱：**统一**粉色竖直渐变（`palette.joy → histoBarBottom`，非按分数变色）、顶5底2圆角、`max-width 22`、高 ∝ count/maxCount（下限 8）。
- **中位桶** 2px 描边（`lerp(joy,joyLight,.55)`，padding 1 offset）；中位 = `_weightedMedian` 数据派生（**不**硬编码 mock 的「7」）。
- 分数标行（10.5/w600/textSecondary）；foot：左「{count} 笔悦己支出的满足度」+ 右「中位满足度 {value}」pill（joyLight/joyText/圆角7）。
- 末尾暖文案 caption（新 key）。保留 `_normalize`/`_weightedMedian`/`Semantics`；删 BarChart/网格线/tooltip/`_colorForScore`/「5」注释。

### 3. `cards/satisfaction_histogram_card.dart`
`AnalyticsDataCard(showHeader: false)` —— 去掉卡内「悦己·满足度分布 1–10」标题（外层 section header 已标注）。`totalJoyTx < 5` 自隐 + async 分支不动。

### 4. i18n
新增 `analyticsHistogramJoyCaption`（ja/zh/en）：「大多落在中高位——为自己花的钱，多数让你感到值得，偶有几笔不那么满意，也都是真实的体验。」+ gen-l10n。旧 `analyticsHistogramColorCaption` / `analyticsHistogramBarFiveAnnotation` 保留 key（避免 arb_key_parity churn），不再引用。

### 5. 测试
`satisfaction_distribution_histogram_test.dart` 由 fl_chart 结构断言改为自定义柱断言（计数标/中位描边/零桩/分数标/footer/pill/caption），7 测试。

---

## 测试验证

- [x] `flutter gen-l10n` OK
- [x] `flutter analyze` → 0 issues（orchestrator 复跑确认）
- [x] `flutter test`（全量）→ 3072/3072（color_literal_scan / hardcoded_cjk_ui_scan / anti_toxicity_phase47 / arb_key_parity / histogram widget 测试全绿）
- [x] 7 golden macOS 重基线（satisfaction_histogram_card light/dark×en/ja/zh 6 个 + scroll-smoke 1）；empty 态未变（自隐，body 不渲染）
- [x] orchestrator 代码层复核 widget 逐条对齐 spec
- [ ] **设备端视觉待用户确认**

---

## Git 提交记录

```
fe234195 feat(analytics): rebuild 悦己满足度分布 histogram as custom flex bars (drop fl_chart)
2cee111a test(analytics): rebaseline histogram goldens for custom flex bars
```

---

## 保守保留（spec 未给精确值，按"勿发挥"采用 spec 建议值）

- 图表 140 / maxBar 110 / 计数标 14 / 柱高下限 8（spec §2 建议值）
- 分数标独立 Row（spec 允许二选一）
- 两个废弃 ARB key 保留（spec 允许保留）
- 中位描边用运行时 `lerp(joy,joyLight,.55)`（非 mock 字面 `--joyBorder`）

---

**创建时间:** 2026-06-20 18:12
**作者:** Claude Opus 4.8
