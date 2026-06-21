---
phase: quick-260621-uus
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart
  - lib/features/analytics/presentation/widgets/analytics_section_header.dart
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
  - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/l10n/app_zh.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_en.arb
  - lib/generated/  # gen-l10n regenerated output (git add -f — gitignored-yet-tracked)
  - test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart  # DELETED
  - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
  - test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart
  - test/golden/  # macOS golden re-baseline (affected files only)
autonomous: true
requirements: [QUICK-260621-uus]

must_haves:
  truths:
    - "统计页 AppBar 不再显示「全部条目 ▼」entry-filter dropdown（仅 TimeWindowChip 保留）"
    - "四个分区标题（支出趋势/分类支出/小确幸日历/悦己满足度分布）都不再显示「实用」/「悦己」tag chip；左侧彩色竖条 + 标题保留"
    - "分类支出→悦己 drawer 不再显示 dashed dots + 「把悦己这一块放大看看」connector，也不显示「仅呈现去向，不分高下」副标题与「百分比是各项占悦己自身…」caption；drawer 标题缩短为「悦己 {amount}」并保留金额、笔数、bar 主体"
    - "小确幸日历底部不再显示「这个月有 X 天…」footer caption；悦己满足度分布底部不再显示「大多落在中高位…」footer caption（中位满足度 pill 保留）"
    - "flutter analyze = 0 issues；flutter gen-l10n 干净；FULL flutter test 全绿（golden 已 macOS 重基线）"
    - "所有变 0-ref 的 ARB key 在 3 个 ARB 文件中对称删除并 gen-l10n；编排上无 dead code（孤立 widget/类/import/helper 删除而非隐藏）"
  artifacts:
    - path: "lib/features/analytics/presentation/widgets/analytics_section_header.dart"
      provides: "Section header without tag chip (tone bar + title only)"
      contains: "class AnalyticsSectionHeader"
    - path: "lib/features/analytics/presentation/widgets/joy_spend_drawer.dart"
      provides: "Joy drawer without connector/subtitle/caption"
      contains: "class JoySpendDrawer"
  key_links:
    - from: "analytics_screen.dart"
      to: "AnalyticsSectionHeader"
      via: "constructor call without tag: argument"
      pattern: "AnalyticsSectionHeader\\("
    - from: "analytics_card_registry.dart"
      to: "AnalyticsSectionHeaderSpec"
      via: "typedef without tag member"
      pattern: "typedef AnalyticsSectionHeaderSpec"
---

<objective>
统计页（AnalyticsScreen）删除用户在 3 张截图里用红框圈出的一批"编辑性文案 / 分区标签 / 条目筛选 / 悦己抽屉装饰"UI 元素。**保留所有图表与数据结构**（图表、donut、日历网格、直方图柱、悦己抽屉金额+笔数+bar 主体、节标题左侧彩色竖条、中位满足度 pill 全部不动）。

Purpose: 净化统计页视觉噪声，去掉非数据性的说明/标签/连接器装饰；纯展示层删除，不动任何 provider 数据流（`selectedJoyMetricVariantProvider` 保留，仅删其 UI 控件）。
Output: 7 个 presentation Dart 文件瘦身、1 个 widget 文件 + 1 个 widget 测试文件删除、3 个 ARB 文件对称去键 + gen-l10n、2 个受影响测试文件更新、受影响 golden macOS 重基线。

CRITICAL — 本任务源自 3 张标注截图（planner 无法看到）；orchestrator 已做完整代码定位，下方 spec 即权威完整需求集。**不要再 re-scope 或新增 spec 之外的元素。** 所有 file:line 已由 planner 逐一复核与当前代码匹配。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md

# 关键工程约束（来自 CLAUDE.md / 项目记忆）
# - 所有 UI 文案走 S.of(context)；动 ARB key 必须 3 个文件（ja/zh/en）同步 + flutter gen-l10n
# - lib/generated/ 是 gitignored-yet-tracked：gen-l10n 后必须 git add -f lib/generated/（否则 analyze from clean 会因陈旧生成码失败）
# - 不可对整个 test/ 跑 dart format（repo 非 format-clean）
# - golden 是 macOS 基线；当前在 darwin/macOS，正确平台。CI(ubuntu) 走 BaselineExistenceGoldenComparator
# - 无 @riverpod/@freezed/Drift 改动 → 不跑 build_runner；仅 ARB → flutter gen-l10n
# - 不留 dead code：孤立 widget/类/import/helper/ARB key 删除，而非隐藏
#
# 已验证的 0-ref / 影响事实（planner grep 复核，executor 删前请再确认一次）：
# - analyticsJoyMetricVariantChipLabel 已是 source 0-ref（仅在 ARB），可直接删
# - 其余 4 个 JoyMetricVariant* key 仅被 joy_metric_variant_chip.dart 引用（该文件将删除）→ 删后 0-ref
# - analyticsSectionTagPractical / analyticsSectionTagJoy 仅被 analytics_card_registry.dart 引用 → 删后 0-ref
# - analyticsJoyDrawerConnector / Subtitle / Caption 仅被 joy_spend_drawer.dart 引用 → 删后 0-ref
# - analyticsCalCap 仅被 joy_calendar_heatmap.dart 引用 → 删后 0-ref
# - analyticsHistogramJoyCaption 被 satisfaction_distribution_histogram.dart + 其 widget 测试引用 → 删源码后还需改测试断言（见 T6）
# - analyticsJoyDrawerTitle（改值不删）、analyticsHistogramMedianPill（保留不动）
# - joy_spend_card.dart 薄 wrapper 用 AnalyticsDataCard + JoySpendDrawerBody，不渲染 connector/subtitle/caption →
#   joy_spend_card_golden_test.dart 不应变化（输出不变则不重基线）
</context>

<tasks>

<task type="auto">
  <name>Task 1: 删除 AppBar「全部条目 ▼」entry-filter chip + 删除孤立 chip widget 及其专属测试</name>
  <files>
    lib/features/analytics/presentation/screens/analytics_screen.dart,
    lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart (DELETE),
    test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart (DELETE)
  </files>
  <action>
在 analytics_screen.dart 的 AppBar `actions:` 列表中删除第 60 行 `JoyMetricVariantChip(locale: ctx.locale),`（保留紧邻其上的 `TimeWindowChip(...)`）。同步删除文件顶部对 `JoyMetricVariantChip` 的 import（`import '../widgets/joy_metric_variant_chip.dart';`，第 11 行）。
确认 `JoyMetricVariantChip` 在 lib/ 下已无其它引用后（planner 已确认仅 analytics_screen.dart:60 + 自身定义；executor 删前再 grep 一次 `JoyMetricVariantChip`），删除整个 widget 文件 `joy_metric_variant_chip.dart`，并删除其专属 widget 测试 `joy_metric_variant_chip_test.dart`。
KEEP `providers/state_joy_metric_variant.dart`（enum + `selectedJoyMetricVariantProvider`）—仍被 `buildAnalyticsCardContext` 消费且默认 `JoyMetricVariant.all`，数据流不变，仅移除 UI 控件。注意：`anti_toxicity_phase17_test.dart` 也引用了该 chip，由 Task 6 处理（本 Task 不动它）。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; test ! -f lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart &amp;&amp; test ! -f test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart &amp;&amp; ! grep -rn "JoyMetricVariantChip" lib | grep -v '/generated/' &amp;&amp; ! grep -n "joy_metric_variant_chip" lib/features/analytics/presentation/screens/analytics_screen.dart &amp;&amp; echo OK_T1</automated>
  </verify>
  <done>AppBar 仅剩 TimeWindowChip；JoyMetricVariantChip widget 文件与专属测试已删除；lib/ 下 0 引用 JoyMetricVariantChip；state_joy_metric_variant.dart 保留。</done>
</task>

<task type="auto">
  <name>Task 2: 删除四个 section header 的 tag chip（widget + typedef + registry specs + shell 调用）</name>
  <files>
    lib/features/analytics/presentation/widgets/analytics_section_header.dart,
    lib/features/analytics/presentation/analytics_card_registry.dart,
    lib/features/analytics/presentation/screens/analytics_screen.dart
  </files>
  <action>
四个分区标题（支出趋势/分类支出 截图3、小确幸日历 截图2、悦己满足度分布 截图1）的 tag chip 全部圈出，需整体移除——**KEEP 左侧彩色竖条（`tone`/`SectionTone`）+ 标题**。
1. analytics_section_header.dart：删除 `final String tag;` 字段（第 41-42 行附近）+ 构造函数里的 `required this.tag,`（第 35 行附近）+ build() 末尾的 tag `Container`（pink/green pill，第 93-108 行）+ 紧邻其前的 `const SizedBox(width: 7)`（第 92 行）。保留 width:3 的 bar Container + `Expanded(Text(title...))`。同步清理 doc-comment 里对 tag chip 的描述（避免 hardcoded_cjk / 误导）与 switch 里仅 tag 用到的局部变量（`tagTextColor`/`tagBgColor`）。
2. analytics_card_registry.dart：更新 typedef `AnalyticsSectionHeaderSpec`（第 75-79 行）删除 `String Function(S l10n) tag,` 成员；删除四处 registry spec 里的 `tag: (l10n) => l10n.analyticsSectionTagPractical/Joy,` 行（约 186 / 202 / 218 / 234 行）。
3. analytics_screen.dart：`AnalyticsSectionHeader(...)` 调用（约 103-107 行）删除 `tag: header.tag(l10n),` 实参。
ARB key `analyticsSectionTagPractical` + `analyticsSectionTagJoy` 删后变 0-ref，由 Task 5 统一从 3 个 ARB 删除 + gen-l10n。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; ! grep -n "this.tag\|final String tag\|header.tag\|analyticsSectionTag\|String Function(S l10n) tag" lib/features/analytics/presentation/widgets/analytics_section_header.dart lib/features/analytics/presentation/analytics_card_registry.dart lib/features/analytics/presentation/screens/analytics_screen.dart &amp;&amp; grep -q "SectionTone" lib/features/analytics/presentation/widgets/analytics_section_header.dart &amp;&amp; echo OK_T2</automated>
  </verify>
  <done>AnalyticsSectionHeader 无 tag 字段/无 tag pill；typedef 无 tag 成员；registry 四处 tag 行删除；shell 调用无 tag 实参；SectionTone 左竖条 + 标题保留。</done>
</task>

<task type="auto">
  <name>Task 3: 悦己 drawer 去 connector + 缩短标题 + 删副标题/caption</name>
  <files>lib/features/analytics/presentation/widgets/joy_spend_drawer.dart</files>
  <action>
仅改 `JoySpendDrawer`（嵌在 donut 卡内）；KEEP 标题行 + 金额 + 笔数 count + `JoySpendDrawerBody`（bar 主体）。
1. 删 connector（截图2 #4：dashed dots + 「把悦己这一块放大看看」是同一元素）：删 `_JoyConnector(...)` 调用（第 72-78 行）+ 紧随的 `const SizedBox(height: 10)`（第 79 行）；删除已孤立的 `_JoyConnector` 类定义（第 166-224 行）。ARB key `analyticsJoyDrawerConnector` 删后 0-ref → Task 5 删。
2. 缩短 drawer 标题（截图2 #5：删后缀「花在哪几类开心事」，**保留「悦己 {amount}」前缀**，金额未圈不删）：**不删 key**（仍用于第 96 行 `analyticsJoyDrawerTitle(...)`），改 ARB 值并保留 `{amount}` 占位符——app_zh.arb: `"悦己 {amount}"`，app_ja.arb: `"悦び {amount}"`，app_en.arb: `"Joy {amount}"`（具体改值在 Task 5 统一处理）。本 Task 不动 joy_spend_drawer.dart 第 96 行调用。
3. 删副标题（截图2 #6「仅呈现去向，不分高下」）：删 `Text(l10n.analyticsJoyDrawerSubtitle ...)`（第 121-126 行）+ 紧邻其前的 `const SizedBox(height: 2)`（第 120 行）。ARB key `analyticsJoyDrawerSubtitle` 删后 0-ref → Task 5 删。
4. 删 caption（截图2 #7「百分比是各项占悦己自身的比例 · 不设目标、不与过往相比」）：删 `Text(l10n.analyticsJoyDrawerCaption ...)`（第 133-140 行）+ 紧邻其前的 `const SizedBox(height: 12)`（第 132 行）。ARB key `analyticsJoyDrawerCaption` 删后 0-ref → Task 5 删。
删 3+4 后：保留 标题行 + count + `const SizedBox(height: 13)`（body 前）+ `JoySpendDrawerBody`。复核纵向间距读起来干净（标题行 → SizedBox(13) → body，body 后直接闭合 Container）。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; ! grep -n "_JoyConnector\|analyticsJoyDrawerSubtitle\|analyticsJoyDrawerCaption\|analyticsJoyDrawerConnector" lib/features/analytics/presentation/widgets/joy_spend_drawer.dart &amp;&amp; grep -q "JoySpendDrawerBody" lib/features/analytics/presentation/widgets/joy_spend_drawer.dart &amp;&amp; grep -q "analyticsJoyDrawerTitle" lib/features/analytics/presentation/widgets/joy_spend_drawer.dart &amp;&amp; grep -q "analyticsJoyDrawerCount" lib/features/analytics/presentation/widgets/joy_spend_drawer.dart &amp;&amp; echo OK_T3</automated>
  </verify>
  <done>JoySpendDrawer 无 _JoyConnector / subtitle / caption；标题+金额(title key)+笔数 count+JoySpendDrawerBody 保留；间距读起来干净。</done>
</task>

<task type="auto">
  <name>Task 4: 删两个 footer caption（小确幸日历 + 悦己满足度分布）</name>
  <files>
    lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart,
    lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  </files>
  <action>
1. 小确幸日历 footer caption（截图1 #8「这个月有 X 天，为自己留下了一点小确幸 · 只看「哪些天发生过」」）：joy_calendar_heatmap.dart 约 125-135 行，删 `Text(l10n.analyticsCalCap(joyDays) ...)` + 紧邻其前的 `const SizedBox(height: 10)`（第 126 行）+ 行内 `// §2f` 注释。**删后 `joyDays`（第 57 行 `final joyDays = countByDay.values.where((c) => c > 0).length;`）将变 unused → 一并删除第 57 行**（否则 analyze warning）。保留 GridView + `_CalLegend`。ARB key `analyticsCalCap` 删后 0-ref → Task 5 删。
2. 悦己满足度分布 footer caption（截图1 #9「大多落在中高位——…也都是真实的体验。」）：satisfaction_distribution_histogram.dart 约 129-141 行，删 `Text(l10n.analyticsHistogramJoyCaption ...)` + 紧邻其前的 `const SizedBox(height: 9)`（第 129 行）+ 行内 `// round-5 r5 .histo-cap` 注释。**KEEP「中位满足度 N」median pill（`analyticsHistogramMedianPill`，未圈）**。ARB key `analyticsHistogramJoyCaption` 删后源码 0-ref，但仍被其 widget 测试断言 → 由 Task 6 改测试后，Task 5 删 ARB。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; ! grep -n "analyticsCalCap\|joyDays" lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart &amp;&amp; ! grep -n "analyticsHistogramJoyCaption" lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart &amp;&amp; grep -q "analyticsHistogramMedianPill" lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart &amp;&amp; grep -q "_CalLegend" lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart &amp;&amp; echo OK_T4</automated>
  </verify>
  <done>日历无 cal-cap 且 joyDays 已清；直方图无 joy-caption 且 median pill 保留；GridView/_CalLegend/柱体保留。</done>
</task>

<task type="auto">
  <name>Task 5: 3 个 ARB 对称去键 + 改 drawer 标题值 + flutter gen-l10n</name>
  <files>lib/l10n/app_zh.arb, lib/l10n/app_ja.arb, lib/l10n/app_en.arb, lib/generated/</files>
  <action>
对 app_zh.arb / app_ja.arb / app_en.arb **三文件对称**操作（每个 key 含其 `"key": ...` 行与紧随的 `"@key": { ... }` metadata 块都要删干净，保持 JSON 合法、无悬挂逗号）：

删除以下已确认删后 0-ref 的 key（删前 executor 再 grep 一次确认每个 key 在 lib/（排除 generated）+ test/ 下除"将被删的源/测试文件"外无引用）：
- analyticsJoyMetricVariantChipLabel（已 source 0-ref）
- analyticsJoyMetricVariantSheetTitle
- analyticsJoyMetricVariantOptionAll
- analyticsJoyMetricVariantOptionManualOnly
- analyticsJoyMetricVariantManualOnlyExplain
- analyticsSectionTagPractical
- analyticsSectionTagJoy
- analyticsJoyDrawerConnector
- analyticsJoyDrawerSubtitle
- analyticsJoyDrawerCaption
- analyticsCalCap
- analyticsHistogramJoyCaption（Task 6 已先去测试断言）

改值（**不删 key**，保留 `{amount}` 占位符与其 placeholders metadata）：
- analyticsJoyDrawerTitle → app_zh.arb: `"悦己 {amount}"`；app_ja.arb: `"悦び {amount}"`；app_en.arb: `"Joy {amount}"`

**不动**：analyticsJoyDrawerCount、analyticsHistogramMedianPill、其余所有 key。

完成后运行 `flutter gen-l10n`（无 build_runner——无 @riverpod/@freezed/Drift 改动）。由于 lib/generated/ 是 gitignored-yet-tracked，gen-l10n 后必须 `git add -f lib/generated/` 把重新生成的 Dart 纳入提交（否则 analyze-from-clean 会撞陈旧生成码）。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; flutter gen-l10n &amp;&amp; for k in analyticsJoyMetricVariantChipLabel analyticsJoyMetricVariantSheetTitle analyticsJoyMetricVariantOptionAll analyticsJoyMetricVariantOptionManualOnly analyticsJoyMetricVariantManualOnlyExplain analyticsSectionTagPractical analyticsSectionTagJoy analyticsJoyDrawerConnector analyticsJoyDrawerSubtitle analyticsJoyDrawerCaption analyticsCalCap analyticsHistogramJoyCaption; do if grep -rq "\"$k\"" lib/l10n/; then echo "FAIL: $k still in ARB"; exit 1; fi; done &amp;&amp; for f in app_zh app_ja app_en; do python3 -c "import json;json.load(open('lib/l10n/$f.arb'))" || exit 1; done &amp;&amp; grep -q "analyticsJoyDrawerTitle" lib/l10n/app_en.arb &amp;&amp; echo OK_T5</automated>
  </verify>
  <done>12 个 key 在 3 个 ARB 全删（含 @metadata）；analyticsJoyDrawerTitle 改为「悦己/悦び/Joy {amount}」；3 个 ARB 仍是合法 JSON；gen-l10n 通过；lib/generated/ 已 git add -f。</done>
</task>

<task type="auto">
  <name>Task 6: 修复受影响的非 golden 测试（anti_toxicity_phase17 + histogram widget test）</name>
  <files>
    test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart,
    test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart
  </files>
  <action>
仅在测试断言/构造了**已删除元素**处修复（不放宽其它断言）：
1. anti_toxicity_phase17_test.dart：该文件第二个 group `'Phase 17 Joy metric variant copy'`（约第 184 行至该 group 结束）整组围绕已删除的 `JoyMetricVariantChip` 构建（`_buildSubject` 第 49-65 行 + `_TestSelectedJoyMetricVariant` 类 + tap `find.byType(JoyMetricVariantChip)` 第 195 行）。删除整个该 group + 已孤立的 `_buildSubject` helper + `_TestSelectedJoyMetricVariant` 测试类 + 仅它们用到的 import（`JoyMetricVariantChip`、`selectedJoyMetricVariantProvider`、`JoyMetricVariant` 若别处不再用）。**保留**第一个 group `'Phase 17 — new round-5 B card copy is scan-ready'`（trend/joySpend/calendar 卡的禁词扫描，不依赖 chip）及其 `_buildCardSubject` helper。删后确保文件无未用 import / 未用顶层符号（analyze 0）。
2. satisfaction_distribution_histogram_test.dart：删除断言已移除 caption 的块——第 129-133 行 `// Warm descriptive caption ...` 注释 + `expect(find.textContaining('Mostly mid-to-high'), findsOneWidget,);`。**保留**同测试内 count footer（'10'）与 median pill（'Median satisfaction 4'）断言。
注意：CLAUDE.md 禁止对整个 test/ 跑 dart format；如需格式化仅 `dart format` 这两个被改的文件。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; ! grep -n "JoyMetricVariantChip\|_TestSelectedJoyMetricVariant\|Joy metric variant copy" test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart &amp;&amp; ! grep -n "Mostly mid-to-high\|analyticsHistogramJoyCaption" test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart &amp;&amp; grep -q "scan-ready" test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart &amp;&amp; echo OK_T6</automated>
  </verify>
  <done>anti_toxicity_phase17_test 仅留第一个 card-copy group（无 chip 依赖、无未用 import/符号）；histogram widget test 去掉 caption 断言、保留 count + median pill 断言。</done>
</task>

<task type="auto">
  <name>Task 7: golden macOS 重基线 + 硬门（analyze 0 / gen-l10n / FULL flutter test 全绿）</name>
  <files>test/golden/</files>
  <action>
本任务为 quick 任务的收尾硬门，必须全部通过才算 done。
1. `flutter analyze` 必须 0 issues（若有，回到对应 Task 修根因，不用 `// ignore:` 压制；不删 .g.dart 需要的 import）。
2. golden 重基线（在 macOS / darwin——本机即正确平台）。受影响 golden（节标题 tag 去除 / appbar chip 去除 / 日历 caption / 直方图 caption / donut 内嵌 drawer connector+subtitle+caption 去除）：
   - test/golden/analytics_screen_scroll_smoke_golden_test.dart
   - test/golden/category_donut_card_golden_test.dart（悦己 drawer 嵌套其内）
   - test/golden/joy_calendar_card_golden_test.dart
   - test/golden/satisfaction_histogram_card_golden_test.dart
   逐一 `flutter test --update-goldens <file>` 重基线（清晰的 diff 归因）。
   joy_spend_card_golden_test.dart：planner 已确认 JoySpendCard 薄 wrapper 用 AnalyticsDataCard + JoySpendDrawerBody，**不**渲染 connector/subtitle/caption；先**不**加 --update-goldens 跑一次该文件，若通过则不动；仅当其输出确实变化才重基线。
3. 重基线后跑 **FULL** `flutter test`（不要 scoped 子集——架构测试如 hardcoded_cjk_ui_scan / color_literal_scan / ARB parity 必须被执行），必须全绿。若 ARB-parity 报缺键/多键，回 Task 5 校正三文件对称性。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; flutter analyze 2>&amp;1 | tail -3 &amp;&amp; flutter analyze 2>&amp;1 | grep -q "No issues found" &amp;&amp; flutter test 2>&amp;1 | tail -5 &amp;&amp; echo OK_T7</automated>
  </verify>
  <done>flutter analyze = No issues found；受影响 golden 已 macOS 重基线（joy_spend_card 仅在输出变化时重基线）；FULL flutter test 全绿（含架构/ARB-parity 测试）。</done>
</task>

</tasks>

<verification>
- AppBar 仅 TimeWindowChip；JoyMetricVariantChip widget + 其专属测试已删，lib/ 0 引用。
- 四个 section header 无 tag chip，左竖条 + 标题保留；typedef/registry/shell 全部去 tag。
- 悦己 drawer 无 connector/subtitle/caption，标题缩短为「悦己/悦び/Joy {amount}」，金额/笔数/bar 主体保留。
- 日历 cal-cap + 直方图 joy-caption 删除；joyDays 清理；median pill 保留。
- 12 个 0-ref ARB key 在 3 文件对称删除；gen-l10n 干净；lib/generated/ git add -f。
- 受影响非 golden 测试（anti_toxicity_phase17 第二组 + histogram caption 断言）已修。
- 硬门：flutter analyze 0 / FULL flutter test 全绿 / 受影响 golden macOS 重基线。
</verification>

<success_criteria>
- 所有 7 个 Task 的 `<automated>` verify 通过（OK_T1..OK_T7）。
- 无 dead code：孤立 widget（joy_metric_variant_chip.dart）+ _JoyConnector 类 + 12 ARB key + 受影响测试 helper 全部删除而非隐藏。
- 零数据流改动：state_joy_metric_variant.dart 保留，所有图表/数据结构不动。
- flutter analyze = No issues found；FULL flutter test 全绿；受影响 golden 已在 macOS 重基线。
</success_criteria>

<output>
完成后创建 `.planning/quick/260621-uus-strip-analytics-editorial-captions-tags-/260621-uus-SUMMARY.md`，记录：每 Task 实际删除的行/文件、最终 ARB key 删除清单与 drawer 标题三语终值、golden 重基线文件清单（含 joy_spend_card 是否重基线）、analyze/test 终态计数、commit hash。并按 worklog 规则在 docs/worklog/ 生成工作日志。
</output>
