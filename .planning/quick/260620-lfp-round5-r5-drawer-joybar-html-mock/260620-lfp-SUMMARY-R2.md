# 260620-lfp R2 — 分类支出卡 + 小确幸日历卡 像素级对齐 SUMMARY

严格按 `260620-lfp-FIDELITY-SPEC.md` 实现两张卡，match-the-mock，无自由发挥。趋势卡 / 满足度直方图卡零改动。

## 改动清单

### §0 新建颜色 token（commit a）
- `lib/core/theme/analytics_category_palette.dart`：`survivalSequence`(5)、`joy`、`other`、`heat`(4)、`survivalAt()`、`heatForCount()`。裸 hex 全部精确来自 mock `--cat-*`/`--heat*`，仅落在 `core/theme/`（color_literal_scan 白名单按目录）。

### §1 分类支出卡（commit b）
- `cards/category_donut_card.dart`：`showHeader:false`；在 `build` 里 watch `joyCategoryAmountsProvider`（与 drawer 同 key，Riverpod 去重）构造 `Set<String> joyL1Ids`（categoryId 已是 L1，无 rollup）；把 `entryCount`/`month`/`joyL1Ids` 下传。
- 新建 `widgets/donut_hero.dart`（公开 `DonutHero` + `LegendRow`）—— 从卡里抽出，原因见下「未覆盖/保守保留」#1。
  - §1b hero-top：左 hero-cap (13/w700/textPrimary) + 右 hero-tag pill (10.5/w600, dailyText on dailyLight, 圆角7, padding 9/3)，下方 `SizedBox(18)`。
  - §1c 环几何：`centerSpaceRadius:62`, `radius:22`, `sectionsSpace:0`, `cornerRadius:0`，高度 200。
  - §1d 配色：删除 daily→joy lerp；遍历 rows 维护 `survivalIdx`，joy L1→樱粉、否则 survivalAt(idx++)、长尾 other→藕灰。环弧色与 legend dot 色用同一 `rowColors` 列表，保证一致。
  - §1e 中心三行：label(11/textSecondary) / count-up 总额(28/w800/textPrimary, amountMedium.copyWith) / 笔数(10.5/textTertiary, 顶距3)。
  - §1f 图例：dot 改圆角方块 11×11 r4；name 13/w600；amount 13/w700；pct 11/w600 宽46 右对齐；每行底部 1px borderDivider（最后一行无）；删除 chevron；行 padding 垂直9；行仍可点（InkWell→drill），长尾行不可点。

### §2 小确幸日历卡（commit c）
- `cards/joy_calendar_card.dart`：`showHeader:false`。
- `widgets/joy_calendar_heatmap.dart`：
  - §2b 顶部 Mon-first 星期表头行（7×Expanded，10/w700/textTertiary 居中）。
  - §2c 网格：`childAspectRatio:1.0`, `mainAxisSpacing:6`, `crossAxisSpacing:6`。leading 空白用 `SizedBox.expand()`（**keyless**，见 bug 修复）。
  - §2d 日格：背景离散 `heatForCount`（删连续 lerp `_depthColor`）；圆角8；日号右上角 (`Align.topRight` + padding top3/right4)，8.5/w700；颜色 0→textTertiary、1→joyText、≥2→`Colors.white`；选中环保留 joyText 2px。inline 展开面板保留。
  - §2e 图例：4 色块改离散 `AnalyticsCategoryPalette.heat[0..3]`，13×13 r4。
  - §2f cal-cap：图例下方 `analyticsCalCap(joyDays)`（joyDays = countByDay.values.where(>0).length），11/textTertiary/line-height1.55。

### §4 ARB（commit a）
新增 11 key × 3 locale（ja/zh/en），模板文件是 `app_en.arb`（placeholders 在 en 定义；ja/zh 也补齐 `@`-metadata 以过 arb_key_parity）。`flutter gen-l10n` 通过，generated Dart 用 `git add -f`（lib/generated gitignored-yet-tracked）。

## Commit hashes
- `53928fbc` feat: analytics category palette + 11 round5-r5 ARB keys
- `774c2133` feat(analytics): pixel-align category donut card to round5-r5 mock
- `9640001f` feat(analytics): pixel-align joy calendar card to round5-r5 mock

## 验收闸结果
1. `flutter gen-l10n` — ✅ 无缺 key（template=en）
2. `flutter analyze` — ✅ **No issues found**
3. `flutter test`（全量）— ✅ **3072 passed**（含 color_literal_scan / hardcoded_cjk_ui_scan / anti_toxicity_phase47 / arb_key_parity / analytics_card_registry REDES-01 / donut+calendar widget tests）
4. macOS golden 重基线 — **17 个**（donut 9 + calendar 7 + analytics scroll-smoke 1），**零删除**，targeted update 仅 3 个 golden 文件。

## anti-toxicity 处理
- `analyticsCalCap` 沿用 spec 已软化版「只看哪些天发生过」（去掉 mock 原文「不数连续、不比多少」的 连续/比 触发词）。
- anti_toxicity_phase47 全绿，新串无 forbidden 子串（zh forbidden 含 对比/比较 但不含单字「比」；新串无命中）。未触发任何改词需求。

## 期间发现并自动修复（deviation）
- **[Rule 1 - Bug] GridView 多个 leading 空白格 ValueKey 冲突**：初版给 `SizedBox.expand` 加了共享 `ValueKey('joy_cal_blank')`，月初有 ≥2 个 leading blank 时 sliver child-element list 断言失败（`insertFirst || _childElements[index-1] != null`）。anti_toxicity 的 `inline_expand` 状态先暴露。改为 keyless `SizedBox.expand()`。修复于 `joy_calendar_heatmap.dart`，含在 commit c。
- **[Rule 3 - Blocking] REDES-01 400-LOC 闸**：donut 卡新增 hero-top/center/legend 后达 487 LOC，超 `analytics_card_registry_test.dart` 的 cards/*.dart <400 LOC 架构闸。把 `DonutHero`/`LegendRow` 抽到 `widgets/donut_hero.dart`（cards/ 外，不受 400 闸约束；imports 无 home/）。卡降到 158 LOC。含在 commit b。

## 本 spec 未明确给值 / 保守保留的点（铁律）
1. **donut_hero.dart 抽取**：spec 把所有逻辑写在卡内（`_DonutHero`/`_LegendRow`），但卡内联会破 REDES-01 400-LOC 架构闸。保守做法 = 不删任何逻辑、仅把两个私有 widget 原样升为公开类搬到 cards/ 外的 `widgets/donut_hero.dart`（与既有 `joy_spend_drawer.dart` 同级），行为字节等价。
2. **hero 卡外层容器**（mock `.hero` radial-gradient 背景 + 22px 圆角 + `.hero::before` 樱粉光晕 + shadowHero）：spec §1 只给 hero **内部** 元素值，未给外层 hero 容器的渐变/圆角/阴影/光晕值。保守保留现状 = 仍用 `AnalyticsDataCard` 的标准 Card 外壳（圆角/阴影按主题），未引入 mock 的 radial-gradient/光晕。
3. **joy-connector chip +「悦己抽屉」**（mock `.joy-connector`/`.drawer`）：本轮 spec 未涉及，保留现有 `JoySpendDrawer` 行为不动。
4. **环底灰底环**（mock `#F1ECE8` 底环）：spec §1c 注明「非必须」，未添加（fl_chart PieChart 无独立底环概念，保守不画）。
5. **inline 展开面板内部样式**（日历点击后的交易 tile）：mock 无此元素，spec §2d 注明「保留」，未改。
6. **`crossAxisAlignment` 微调**：donut_hero hero-top Row 去掉了多余的 `crossAxisAlignment:center`（Row 默认即 center），无视觉差异。

## Self-Check: PASSED
- FOUND lib/core/theme/analytics_category_palette.dart
- FOUND lib/features/analytics/presentation/widgets/donut_hero.dart
- FOUND commit 53928fbc / 774c2133 / 9640001f
- flutter analyze: No issues found
- flutter test: 3072 passed
- goldens: 17 modified, 0 deleted
