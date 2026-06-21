---
phase: quick-260621-uus
plan: 01
status: complete
subsystem: analytics-presentation
tags: [analytics, ui-cleanup, l10n, golden]
requirements: [QUICK-260621-uus]
dependency_graph:
  requires: []
  provides: ["统计页净化版（去编辑性文案/分区标签/条目筛选/悦己抽屉装饰）"]
  affects: [analytics_screen, analytics_section_header, joy_spend_drawer, joy_calendar_heatmap, satisfaction_distribution_histogram]
key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/analytics/presentation/widgets/analytics_section_header.dart
    - lib/features/analytics/presentation/analytics_card_registry.dart
    - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
    - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - lib/l10n/app_zh.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_en.arb
    - lib/generated/ (gen-l10n regenerated, git add -f)
    - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
    - test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart
    - test/golden/goldens/ (15 PNG re-baselined)
  deleted:
    - lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart
    - test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart
metrics:
  tasks: 7
  files_modified: 12
  duration: ~25min
  completed: 2026-06-21
---

# Quick 260621-uus: 统计页删除编辑性文案/分区标签/条目筛选/悦己抽屉装饰 Summary

净化统计页（AnalyticsScreen）视觉噪声 —— 删除 3 张标注截图里圈出的一批非数据性 UI（AppBar 条目筛选 chip、四个分区标题的「实用/悦己」tag chip、悦己 drawer 的 connector/副标题/caption、小确幸日历与满足度分布两处 footer caption）。所有图表与数据结构（图表、donut、日历网格、直方图柱、悦己 drawer 金额+笔数+bar 主体、节标题左侧彩色竖条、中位满足度 pill）保留不动；零数据流改动（`selectedJoyMetricVariantProvider` 保留，仅删其 UI 控件）。

## Per-Task 实际删除清单

**Task 1（commit 15ebc181）— AppBar 条目筛选 chip：**
- analytics_screen.dart：删 `JoyMetricVariantChip(locale: ctx.locale)` 调用 + 顶部 import。
- 删整个 widget 文件 `joy_metric_variant_chip.dart` + 专属测试 `joy_metric_variant_chip_test.dart`。
- KEEP `TimeWindowChip`、`state_joy_metric_variant.dart`（enum + provider，数据流不变）。

**Task 2（commit 730b5bb3）— 四个 section header 的 tag chip：**
- analytics_section_header.dart：删 `final String tag` 字段 + 构造函数 `required this.tag` + build 末尾 tag pill `Container` + 其前 `SizedBox(width:7)` + switch 里 `tagTextColor`/`tagBgColor` 局部变量 + 清理 doc-comment 对 tag 的描述。保留 width:3 竖条 + `Expanded(Text(title))` + `SectionTone`。
- analytics_card_registry.dart：typedef `AnalyticsSectionHeaderSpec` 删 `String Function(S l10n) tag` 成员；四处 spec 删 `tag: (l10n) => …`。
- analytics_screen.dart：`AnalyticsSectionHeader(...)` 调用删 `tag: header.tag(l10n)` 实参。

**Task 3（commit 412a8e9d）— 悦己 drawer：**
- joy_spend_drawer.dart：删 `_JoyConnector(...)` 调用 + 其后 `SizedBox(height:10)`；删整个 `_JoyConnector` 类定义；删副标题 `Text(l10n.analyticsJoyDrawerSubtitle)` + 其前 `SizedBox(height:2)`；删 caption `Text(l10n.analyticsJoyDrawerCaption)` + 其前 `SizedBox(height:12)`；更新 doc-comment。
- KEEP 标题行（`analyticsJoyDrawerTitle`）+ count（`analyticsJoyDrawerCount`）+ `SizedBox(height:13)` + `JoySpendDrawerBody`。最终纵向：标题行 → SizedBox(13) → body → 闭合。

**Task 4（commit 4c8b6c20）— 两处 footer caption：**
- joy_calendar_heatmap.dart：删 `Text(l10n.analyticsCalCap(joyDays))` + 其前 `SizedBox(height:10)` + `// §2f` 注释；删孤立的 `final joyDays = …`。KEEP GridView + `_CalLegend`。
- satisfaction_distribution_histogram.dart：删 `Text(l10n.analyticsHistogramJoyCaption)` + 其前 `SizedBox(height:9)` + `.histo-cap` 注释。KEEP count footer + median pill（`analyticsHistogramMedianPill`）。

**Task 5（commit 27224cba）— ARB 对称去键 + 改 drawer 标题值 + gen-l10n：**
- 12 个 0-ref key 在 app_zh/ja/en 三文件对称删除（含 `@key` metadata），用 Python `json` 加载/回写保格式（无整文件 reformat，diff 96 insert / 189 delete）：
  `analyticsJoyMetricVariantChipLabel`, `analyticsJoyMetricVariantSheetTitle`, `analyticsJoyMetricVariantOptionAll`, `analyticsJoyMetricVariantOptionManualOnly`, `analyticsJoyMetricVariantManualOnlyExplain`, `analyticsSectionTagPractical`, `analyticsSectionTagJoy`, `analyticsJoyDrawerConnector`, `analyticsJoyDrawerSubtitle`, `analyticsJoyDrawerCaption`, `analyticsCalCap`, `analyticsHistogramJoyCaption`。
- drawer 标题 `analyticsJoyDrawerTitle` 改值（保留 `{amount}` 占位符）：
  - app_zh.arb: `"悦己 {amount}"`（原「悦己花在哪几类开心事 {amount}」类后缀去除）
  - app_ja.arb: `"悦び {amount}"`
  - app_en.arb: `"Joy {amount}"`（原 "Where your joy {amount} went"）
- `flutter gen-l10n` 干净；`git add -f lib/generated/`（gitignored-yet-tracked）纳入 4 个生成 Dart。

**Task 6（commit 547a359d）— 受影响非 golden 测试：**
- anti_toxicity_phase17_test.dart：删第二组 `'Phase 17 Joy metric variant copy'` + 孤立 `_buildSubject` helper + `_TestSelectedJoyMetricVariant` 类 + `JoyMetricVariantChip` import。保留第一组 `'… round-5 B card copy is scan-ready'` + `_buildCardSubject`。`JoyMetricVariant`/`misc.dart`(Override) 仍被使用故保留。
- satisfaction_distribution_histogram_test.dart：删 `expect(find.textContaining('Mostly mid-to-high'), findsOneWidget)` 断言 + 注释，测试名 `… + warm caption render` → `… render`。保留 count('10') + median pill('Median satisfaction 4') 断言。
- 仅 `dart format` 这两个被改文件（不动整个 test/）。

**Task 7（commit 5b8c1bd9）— golden macOS 重基线 + 硬门：**
- joy_spend_card_golden_test.dart：先无 --update 跑 → 8/8 通过、输出不变 → **不重基线**（符合 planner 预判：薄 wrapper 用 AnalyticsDataCard + JoySpendDrawerBody，不渲染 connector/subtitle/caption）。
- `--update-goldens` 重基线 4 个受影响文件，实际变化 **15 个 PNG**：
  - analytics_screen_scroll_smoke_light_ja.png（×1，分区 tag 去除）
  - joy_calendar_card_{dark_en,dark_ja,dark_zh,expand_light_ja,light_en,light_ja,light_zh}.png（×7，cal-cap 去除）
  - satisfaction_histogram_card_{dark_en,dark_ja,dark_zh,empty_light_ja,light_en,light_ja,light_zh}.png（×7，caption 去除）
  - **category_donut_card golden 输出未变**（JoySpendDrawer 嵌套其内，但该 golden 测试窗未捕获到被删元素 / 输出像素相同），故未重基线。

## 最终态计数

- `flutter analyze` = **No issues found**（0 issues）
- FULL `flutter test` = **3081/3081 全绿**（含架构测试 hardcoded_cjk_ui_scan / color_literal_scan / ARB-parity / anti_toxicity sweep）
- gen-l10n 干净；3 个 ARB 仍为合法 JSON

## Deviations from Plan

无功能性偏差。一处实现选择记录：
- **Task 5 ARB 编辑方式**：plan 描述按 file:line 手删，executor 改用 Python `json.load(object_pairs_hook=OrderedDict)` + `json.dump(indent=2, ensure_ascii=False)` 程序化删键 + 改值。保持键序与 2-space 缩进格式（diff 干净、无整文件 reformat），并对称保证三文件一致 —— 比手工逐行删更稳健、不易漏 `@metadata` 块或留悬挂逗号。
- **观察（非偏差）**：category_donut golden 未变化（虽 JoySpendDrawer 嵌于 donut 卡），与 joy_spend_card 同理；scroll-smoke 全屏 golden 捕获了 drawer 上下文变化并已重基线。

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 15ebc181 | refactor(260621-uus): 删除统计页 AppBar「全部条目 ▼」entry-filter chip + 孤立 widget/测试 |
| 2 | 730b5bb3 | refactor(260621-uus): 删除四个分区标题的「实用/悦己」tag chip（保留左竖条+标题） |
| 3 | 412a8e9d | refactor(260621-uus): 悦己 drawer 去 connector/副标题/caption，缩短标题（保留金额+笔数+bar） |
| 4 | 4c8b6c20 | refactor(260621-uus): 删除小确幸日历 + 悦己满足度分布两处 footer caption（保留 median pill） |
| 5 | 27224cba | chore(260621-uus): 3 ARB 对称删除 12 个 0-ref key + drawer 标题改值 + gen-l10n |
| 6 | 547a359d | test(260621-uus): 修复受影响测试（去 Joy metric variant group + histogram caption 断言） |
| 7 | 5b8c1bd9 | test(260621-uus): macOS 重基线受影响 golden（scroll-smoke/joy_calendar/satisfaction_histogram） |

## Known Stubs

None — 纯删除任务，无引入 stub。

## Self-Check: PASSED

- 删除文件确认不存在：joy_metric_variant_chip.dart ✓ / joy_metric_variant_chip_test.dart ✓
- 7 个 commit 全部在 git log 存在 ✓
- 12 个 ARB key 在 lib/l10n/ 下 0 引用 ✓
- analyze 0 / full test 3081/3081 ✓
