---
quick: 260714-qit
type: execute
mode: quick-full
wave: 1
depends_on: []
autonomous: true
requirements: [D-01, D-02]
files_modified:
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/widgets/
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/
  - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  - lib/features/shopping_list/presentation/widgets/

must_haves:
  truths:
    - "主页/明细/统计/购物四页面的视觉表面高保真对齐 v15 mockup（布局/间距/圆角/配色/字号/组件形态/空-加载-错误态），符合 D-02 视觉高保真移植"
    - "A1 浅色与 A3 深色是同一套布局的两种主题渲染，全部经 context.palette 派生，无硬编码色值（D-02）"
    - "四个页面各由独立聚焦的 executor 实现，彼此文件不重叠，可原子提交（D-01）"
    - "现有 providers / repositories / 数据流保持不变或仅 additive 扩展；provider 图未破坏（D-02）"
    - "flutter analyze 0 issue；全量 flutter test 绿；受影响 golden 浅+深双主题在 macOS 重基线"
  artifacts:
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  key_links:
    - "所有颜色经 context.palette（AppPalette.light/.dark）→ 单套 widget 代码在浅/深两主题下自动成立"
    - "金额文本经 AppTextStyles.amount*（tabular figures）；UI 文案经 S.of(context)；日期经 DateFormatter；货币经 NumberFormatter/FormatterService"
    - "每个页面的 presentation 层复用其现有 provider（home: monthlyReport/happiness/todayTransactions；list: listFilter/listTransactions/calendarDailyTotals；analytics: analyticsCardRegistry；shopping: filteredShoppingItems/listType/reorder）"
---

<objective>
把 `whole-app-warm-japanese-v15.html` 中 A1（个人·浅色 `solo-light`）/ A3（个人·深色 `solo-dark`）两套主题下的**主页 / 明细 / 统计 / 购物**四个页面，视觉高保真移植到现有 Flutter 屏幕，替换当前 presentation 表面。

Purpose: 让四个主 tab 的视觉与 v15 设计稿一致（温润日系 · ADR-019 桜餅×若葉），同时保住已上线的数据接线与交互。
Output: 四个屏幕（及其 presentation/widgets）的视觉表面更新；无数据层/provider 图破坏；浅深双主题经 palette 自动成立。

遵循 D-01（分屏分批：四个独立 executor，逐屏原子提交）与 D-02（视觉高保真移植：presentation-only，palette 派生浅深，禁硬编码色）。
</objective>

<execution_context>
本任务为 GSD quick-full 多 executor 校验运行。四个 Task 各由一个聚焦 executor 独立实现，互不依赖、文件不重叠，可并行（wave 1）。每个 Task 自成一体——executor 只需读本 Task + 引用文件即可忠实实现该屏。
</execution_context>

<context>
@.planning/quick/260714-qit-whole-app-warm-japanese-v15-html-a1-a3/260714-qit-CONTEXT.md
@CLAUDE.md

# Mockup 源（读整份；A1/A3 由 :root 浅色 + [data-theme="dark"] 深色两套 CSS 变量驱动）
@.superpowers/brainstorm/78061-1783676135/content/whole-app-warm-japanese-v15.html

# 主题机制（禁止修改这三个文件——palette 已完整编码 ADR-019 浅/深；只消费不新增 token）
@lib/core/theme/app_palette.dart
@lib/core/theme/app_theme.dart
@lib/core/theme/app_text_styles.dart

## 共享映射：mockup CSS 变量 → AppPalette token（四个 Task 通用；用 `context.palette.<token>`，浅深自动切换）

| mockup CSS 变量 | 语义 | AppPalette token |
|---|---|---|
| `--primary` / `--hp-primary` `#6FA36F` | 主行动 / nav / tab / active | `accentPrimary`（深 `#8DC68D`） |
| `--hp-primary-soft` `#e2ece4` | 主色浅底（chip/soft） | `accentPrimaryLight` |
| `--hp-primary-text` `#365a49` | 主色深绿文字（月份标题/链接） | `accentPrimary`（或深绿 `dailyText` 视对比需要） |
| `--daily` / `--hp-daily` `#5FAE72` | 日常 | `daily` |
| `--hp-daily-text` `#2E6B3A` | 日常金额/文字 | `dailyText` |
| `--hp-daily-soft` | 日常浅底/tag | `dailyLight` |
| `--joy` / `--hp-joy` `#D98CA0` | 悦己 / FAB 樱粉 | `joy`（FAB 用 `fabGradientStart/End` + `fabShadow`） |
| `--hp-joy-text` `#A53D5E` | 悦己金额/文字（AA） | `joyText` |
| `--hp-joy-soft` `#FBEAEF` | 悦己浅底/tag | `joyLight` |
| `--shared` / `--hp-shared` `#5B8AC4` | 共享 | `shared` / `sharedText` / `sharedLight` |
| `--bg` / `--hp-bg` `#FBF7F4` | 暖米白背景 | `background` |
| `--card` / `--hp-surface` `#FFFFFF` | 卡片面 | `card` |
| `--hp-surface-muted` | 静默面（hover/track/skeleton） | `backgroundMuted` |
| `--border` / `--hp-border` `#E6DDD8` | 边框 | `borderDefault` |
| `--border-soft` / `--hp-border-strong` | 分割线/列表边 | `borderDivider` / `borderList` |
| `--text` / `--hp-text` `#20352B` | 主文字 | `textPrimary` |
| `--text-muted` / `--hp-text-muted` | 次文字 | `textSecondary` |
| `--text-faint` / `--hp-text-faint` | 极弱文字 | `textTertiary` |
| `--success/--warning/--error/--info` | 语义 | `success` / `warning` / `error` / `info` |
| radius sm/md/card/hero/pill | 圆角 | 10 / 14 / 18 / 24 / 999（`BorderRadius.circular`） |

金额文本：一律 `AppTextStyles.amountLarge/amountMedium/amountSmall`（含 tabularFigures），配色用对应 *Text token（`dailyText`/`joyText`/`textPrimary`）。
文案：一律 `S.of(context)`（复用现有 key，见下）；日期 `DateFormatter`；货币 `NumberFormatter`/`FormatterService`。

## 全 Task 通用硬约束（CLAUDE.md）
- **禁硬编码色值**：所有颜色经 `context.palette.*`。禁裸 `Color(0x..)`/`Colors.*`（`color_literal_scan` / `hardcoded_cjk_ui_scan` 会拦）。donut 分类色等既有图表色沿用现有实现，不新增裸 hex。
- **禁改** `app_palette.dart` / `app_theme.dart` / `app_text_styles.dart`（新增 token 会变成跨 Task 共享文件改动，破坏并行——若发现某 mockup 色无对应 token，用最接近的既有 token 或 palette 组合，不新增字段）。
- **禁改数据层**：providers / repositories / use-cases / DAOs / tables 不动；只改 `presentation/`（screens/widgets）。如确需，只允许对**本屏 presentation/providers 下的 filter/state provider 做 additive 扩展**（不改签名语义、不动 lib/data）。
- **ARB 优先复用**：四屏均已上线、l10n key 齐备（home*/list*/analytics*/shopping* 已存在）。**尽量零新增 ARB key** 以保四屏文件不重叠、可并行。确需新增时用屏前缀唯一 key、同步 ja/zh/en 三份、`flutter gen-l10n`、生成物 `git add -f`——并知会 orchestrator 该屏与其它屏的 ARB 编辑需串行/并集合并（已知 same-wave executor ARB 撞键陷阱）。
- **不改动 shell chrome**：底部浮动 pill 导航 + 中央 FAB（`home_bottom_nav_bar.dart` / `main_shell_screen.dart`）**不在本轮范围**——它是四 tab 共享 chrome，改它会引入跨 Task 共享文件依赖。仅实现四个页面 body。
- **golden**：goldens 仅 macOS 基线（`flutter_test_config.dart` 在非 macOS 换 BaselineExistenceGoldenComparator）。macOS executor 用 `flutter test --update-goldens <受影响 golden 测试文件>` 重基线浅+深两主题；**不要**对整个 test/ 跑 `dart format`（仓库非 format-clean）。跑 `flutter test`（全量）而非 scoped——架构测试（color_literal_scan / hardcoded_cjk_ui_scan / theme_dark_mode_coverage）只在全量下触发。
- 改了 `@riverpod`/`@freezed`/Drift/ARB 后跑对应 codegen（`build_runner` / `gen-l10n`）。纯 widget 视觉改动通常无需 build_runner。
</context>

<tasks>

<task type="auto">
  <name>Task: 主页 home（HeroHeader + HomeHeroCard + FamilyInviteBanner + 最近取引，A1/A3）</name>
  <files>
    lib/features/home/presentation/screens/home_screen.dart
    lib/features/home/presentation/widgets/hero_header.dart
    lib/features/home/presentation/widgets/home_hero_card.dart
    lib/features/home/presentation/widgets/home_transaction_tile.dart
    lib/features/home/presentation/widgets/transaction_list_card.dart
    lib/features/home/presentation/widgets/family_invite_banner.dart
    (可按 CLAUDE.md「many small files」200–400 行/文件酌情拆分新 widget 文件，均置于 lib/features/home/presentation/widgets/)
  </files>
  <action>
实现 D-02（视觉高保真移植）主页，浅深两主题经 palette 派生（D-01 拆分：本屏独立 executor）。

参考：mockup JS `home()`(≈911) / `faithfulHero()`(≈897) / `faithfulMetrics()`(≈884) / `faithfulInvite()`(≈901) / `homeTxRow()`(≈906)；CSS `.home-faithful`/`.faithful-*`(≈337–440)/`.app-header`/`.page-month-title.home-month-title`。参考截图 .planning/sketches/audits/home-v15/personal-light.jpg + home-focused.jpg + home-v15-amount-type/。inspector 注：主页严格保留现有 Flutter 组合，只更新视觉表面——因此这是**表面精修**而非重建。

结构（自上而下，对齐 mockup，保留现有 HomeScreen 骨架）：
- Header：月份标题「2026年7月 ▾」深绿（`accentPrimary`，`.page-month-title.home-month-title`），右侧 個人/家族 chip + 月历 icon + 设置 icon（现 HeroHeader 已有，精修间距/圆角/色）。
- HomeHeroCard（`.faithful-hero`）：圆角 22、边框 `color-mix(primary 18%, border)`≈`accentPrimaryBorder`、底 `color-mix(surface 90%, primary-soft)`、`shadow-soft`。内含：今月の支出 label(`textSecondary`) + 大金额(`amountLarge`,`textPrimary`) + trend pill(`accentPrimaryLight`/`accentPrimary`)；先月同期行(`textSecondary`)；双账本 split（ときめき帳 `joyText` / 日々の帳 `dailyText` + `.faithful-split` 条 daily 底+joy 段）；分割线；ときめき度 region title(`eco` icon `joy`/`accentPrimary` + info)；`faithfulMetrics`（目标环 `--goal` + 満足度 scale + 小確幸）；今月の最愛 ticket（`.faithful-ticket`：accent 竖条 + 日历块 + copy + seal，色用 joy/ticket 家族→`joy`/`joyText`/`joyLight`）。
- FamilyInviteBanner（`.faithful-invite`，solo 未 dismiss 时）：头像对 + 文案 + 設定›家庭 路径 + 关闭 + 樱粉「家族を追加」CTA（`joy`）。
- 最近の取引 header（`textPrimary` + すべて見る `accentPrimary`）+ `.faithful-list`（圆角 12、`borderDefault`、行分隔）：每行 `homeTxRow`（L1 icon daily→`dailyText`/joy→`joyText`、category、ledger tag、merchant、amount）。

**保留数据接线**：HomeScreen 现有 provider watch（`monthlyReportProvider`/`happinessReportProvider`/`bestJoyMomentProvider`/`todayTransactionsProvider`/`bookByIdProvider`/`appSettingsProvider`/`monthlyJoyTargetRecommendationProvider`/`isGroupModeProvider`/`homeSelectedMonthProvider`/`currentLocaleProvider`）与 loading/error/data 链、edit→invalidateTransactionDependents、すべて見る→selectedTabIndex 切 tab，全部不动；只改视觉。空/加载/错误态沿用现有（`noTransactionsYet` / CircularProgressIndicator / _ErrorText）但配色经 palette。
ARB：复用现有 home* key（homeRecentTransactions/homeViewAllTransactions/noTransactionsYet 等），零新增。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3 && flutter test test/golden/home_hero_card_golden_test.dart test/widget/features/home 2>&1 | tail -5</automated>
    人工：模拟器浅色+深色各跑一次，主页与 mockup A1/A3、personal-light.jpg 逐区对比（hero 卡/账本 split/目标环/最愛 ticket/最近列表）。
  </verify>
  <done>
- 主页浅/深两主题渲染均高保真对齐 mockup（D-02），无硬编码色（`context.palette` 全覆盖）。
- 现有 home providers/交互全部保留（edit 刷新、切 tab、月份选择、group/solo 分支均正常）。
- `flutter analyze` 0 issue；受影响 home golden 浅+深已在 macOS 重基线；全量 `flutter test` 绿。
  </done>
</task>

<task type="auto">
  <name>Task: 明细 list（月份标题 + 账本 segment + 月历卡 + 筛选栏 + 按日分组列表，A1/A3）</name>
  <files>
    lib/features/list/presentation/screens/list_screen.dart
    lib/features/list/presentation/widgets/list_calendar_header.dart
    lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    lib/features/list/presentation/widgets/list_day_group_header.dart
    lib/features/list/presentation/widgets/list_transaction_tile.dart
    lib/features/list/presentation/widgets/list_empty_state.dart
    (可酌情拆分新 widget 文件于 lib/features/list/presentation/widgets/)
  </files>
  <action>
实现 D-02（视觉高保真移植）明细页，浅深两主题经 palette 派生（D-01：本屏独立 executor）。

参考：mockup JS `listScreen()`(≈994) / `listCalendar()`(≈942) / `listLedgerFilter()`(≈954) / `listFilterBar()`(≈964) / `listTransactionGroups()`(≈979) / `listTransactionRow()`(≈973) / `tabHeader`(≈870) / `monthTitle('list')`(≈871)；CSS `.list-screen`/`.list-calendar*`(≈451–469)/`.list-filter-*`(≈470–485)/`.list-day-header`/`.list-transaction*`(≈486–502)/`.segmented-control`(≈645–652)。

结构（自上而下）：
- Header：月份标题（`.list-month-title` 用 `info` 蓝，`DateFormatter.formatMonthYear`）+ 右侧月历 icon + 设置 icon。现有 AppBar 有 prev/next chevron + 点标题回本月——保留交互，视觉精修。
- 账本 segment（`.list-ledger-segments`，`segmentedControl` すべて/日常(daily tone)/ときめき(joy tone)）：daily active→`dailyLight`底+`daily`字+内描边；joy active→`joyLight`+`joy`；all active→`accentPrimary`。绑现有 `listFilterProvider` 的 ledgerType。
- 月历卡（`.list-calendar`）：7 列 週日格；weekday 周末→`info`；日格 `<span>日</span><small>compact金额</small>`；today→数字 `error` 色；selected→`accentPrimary` 底+白字；outside→opacity .35；底部 summary（今月の合計/选中日合计）。绑现有 CalendarHeaderWidget/`calendarDailyTotalsProvider`。
- 筛选栏（`.list-filter-bar`，sticky）：sort pill（日付/金額·降順/昇順，边 `accentPrimary`）+ spacer + clear（有筛选时）+ category pill（active→`accentPrimaryLight`）+ search icon；展开态→搜索输入框（边 `borderInputActive`）。绑现有 ListSortFilterBar 逻辑。
- 列表：`.list-day-header`（日期分组头，`textSecondary`）+ `.list-transactions` 卡（圆角 14、`borderDefault`、行分隔 `borderList`）；每行 `.list-transaction`：L1 icon(daily→`dailyText`/joy→`joyText`) + category(`textPrimary`) + ledger tag(`dailyLight`/`joyLight` 底) + merchant(`textSecondary`) + amount(`amountSmall`,`textPrimary`) + chevron(`textTertiary`)。金額排序为扁平模式（标题带日期）。

**保留数据接线**：`listFilterProvider`/`listTransactionsProvider`/`listTransactionsBaseProvider`/`calendarDailyTotalsProvider`、RefreshIndicator invalidate、`buildFlatList` 分组、amount-sort 扁平分支、edit→`invalidateTransactionDependents`、swipe delete、外币 annotation（`foreignAnnotation`/`trimWholeFraction`）、三种空态变体（filtered/dayEmpty/noData）全部不动；只改视觉。
ARB：复用现有 list* key（listLedgerDaily/listLedgerJoy/listLoadError/listCalNav* 等），零新增。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3 && flutter test test/golden/list_calendar_header_golden_test.dart test/golden/list_sort_filter_bar_golden_test.dart test/golden/list_transaction_tile_golden_test.dart test/golden/list_day_group_header_golden_test.dart test/golden/list_empty_state_golden_test.dart test/widget/features/list 2>&1 | tail -5</automated>
    人工：模拟器浅+深，账本切换（すべて/日常/ときめき 联动月历金额+月合计+列表）、选中日、搜索、排序、空态各态对比 mockup A1/A3。
  </verify>
  <done>
- 明细页浅/深两主题高保真对齐 mockup（D-02），无硬编码色。
- 账本切换/月历/筛选/搜索/排序/分组/空态/edit 刷新全部保留（provider 图未破坏）。
- `flutter analyze` 0 issue；受影响 list golden 浅+深已 macOS 重基线；全量 `flutter test` 绿。
  </done>
</task>

<task type="auto">
  <name>Task: 统计 analytics（时间窗 + 趋势/分类 donut/悦己日历/满足度直方 四区，A1/A3）</name>
  <files>
    lib/features/analytics/presentation/screens/analytics_screen.dart
    lib/features/analytics/presentation/widgets/analytics_section_header.dart
    lib/features/analytics/presentation/widgets/time_window_chip.dart
    lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
    lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
    lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
    lib/features/analytics/presentation/widgets/donut_hero.dart
    lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
    (及 within_month_cumulative_line_chart/satisfaction_distribution_histogram/joy_calendar_heatmap/donut_dimension_member_controls 等被引用 widget，视觉精修所需；新拆文件置 widgets/)
  </files>
  <action>
实现 D-02（视觉高保真移植）统计页，浅深两主题经 palette 派生（D-01：本屏独立 executor）。

参考：mockup JS `analytics()`(≈1087) / `analyticsSection()`(≈999) / `analyticsTrendCard()`(≈1003) / `analyticsDonutCard()`(≈1042) / `analyticsJoyDrawer()`(≈1034) / `analyticsCalendarCard()`(≈1060) / `analyticsHistogramCard()`(≈1077) / `analyticsLegendRow()`(≈1027)；CSS `.analytics-*`(≈503–643)/`.segmented-control`。

统计页现为 THIN SHELL：body 由 `analyticsCardRegistry` 映射为分区 Column（`AnalyticsSectionHeader` + card）。**保持该 registry 驱动架构不变**（GUARD-01：registry 不 import home/*，`_refresh` 由 registry 派生），只精修各 card 与 section header 的视觉表面。

四区（对齐 mockup 顺序/形态）：
1. 支出の推移（`.analytics-section-head` 首个，绿竖条）→ WithinMonthTrendCard：総支出/日常(daily)/ときめき(joy) segment + insight 条（daily→`dailyLight`/joy→`joyLight`）+ 折线图（当前线 daily→`daily`/joy→`joy`、上月虚线 `textTertiary`、网格 `borderDefault`、渐变填充、终点标注、轴刻度）。图表已有实现（jx2/kll/v2m 累积）——精修配色经 palette，保留轴/网格/carry-forward/悦己单线不变式。
2. カテゴリ支出（joy 竖条 section）→ CategoryDonutCard：donut 环（分类色沿用现有 registry 色，环上 %+icon/emoji badge）+ 中心（今月の支出/总额/件数）+ カテゴリ別/メンバー別 dimension segment + 成员 filter dropdown + legend 行（icon+名+金额+%）+ 内嵌悦己抽屉（`joyLight` chip + stacked bar + 明细行，去边框以分割线分离）。绑现有 `donutDimensionStateProvider`/成员 filter provider。
3. ときめきカレンダー（joy 竖条）→ JoyCalendarCard：热力日历（heat 用 joy 深浅：0→`backgroundMuted`、1→`joyLight`、2/3→`joy` 混合）+ selected 描边 `joyText` + 图例（少→多）+ 选中日明细面板（今日默认选中逻辑保留）。
4. ときめきの満足度（joy 竖条）→ SatisfactionHistogramCard：10 柱直方（bar 渐变 joy、zero→`backgroundMuted`、median 描边）+ 轴 1–10 + median pill(`joyLight`/`joyText`) footer。
- 家庭洞察卡仅 group 模式追加（FamilyInsightDataCard，`success` 家族），solo 不出。
- 顶部 AppBar：标题 + TimeWindowChip（时间窗，`.analytics-window` pill）。

**保留数据接线**：`buildAnalyticsCardContext`/`analyticsCardRegistry`/`_buildCardChildren`/`_refresh`（registry 派生 union + shellRefreshTargets）/`earliestTransactionMonthProvider`/`shadowBooksProvider`(display-only)、各 card 的 provider watch 与 drill-down、pull-to-refresh 全部不动；只改视觉。空/加载/错误态沿用现有 card error state。
ARB：复用现有 analytics* key（analyticsTitle/analyticsCardTitle*/analyticsCalWeekday*/analyticsCalLegend* 等），零新增。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3 && flutter test test/golden/analytics_screen_scroll_smoke_golden_test.dart test/golden/within_month_trend_card_golden_test.dart test/golden/category_donut_card_golden_test.dart test/golden/per_category_breakdown_card_golden_test.dart test/golden/joy_calendar_card_golden_test.dart test/golden/satisfaction_histogram_card_golden_test.dart test/widget/features/analytics 2>&1 | tail -8</automated>
    人工：模拟器浅+深，四区逐个对比 mockup A1/A3（趋势三 tab / donut 分类+成员维度+filter / 日历选中 / 直方 median），确认图表配色浅深皆成立。
  </verify>
  <done>
- 统计页四区浅/深两主题高保真对齐 mockup（D-02），无硬编码色（图表沿用现有 registry 色，无新增裸 hex）。
- registry 驱动架构 + `_refresh` union + GUARD-01（无 home/* 泄漏）保持；所有 card provider/drill-down/时间窗保留。
- `flutter analyze` 0 issue；analytics scroll-smoke + card golden 浅+深已 macOS 重基线；全量 `flutter test` 绿。
  </done>
</task>

<task type="auto">
  <name>Task: 购物 shopping（筛选卡 + 可勾选清单 + 完成区，A1/A3）</name>
  <files>
    lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
    lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart
    lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart
    lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart
    lib/features/shopping_list/presentation/providers/state_shopping_filter.dart  (仅当需 additive 加 ledger 维度)
    (新拆文件置 lib/features/shopping_list/presentation/widgets/)
  </files>
  <action>
实现 D-02（视觉高保真移植）购物页，浅深两主题经 palette 派生（D-01：本屏独立 executor）。

参考：mockup JS `shopping()`(≈1098) / `shoppingFilterCard()`(≈1093) / `shopItem()`(≈1113) / `tabHeader('買い物リスト')`；CSS `.shopping-*`(≈654–671)/`.segmented-control`/`.check`/`.badge`/`.section-title`。参考截图 .planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-*（final-phone / single-card / selected-state 等）。

结构（自上而下）：
- Header：買い物リスト（tabHeader 标题，`textPrimary`）。
- 筛选卡（`.shopping-filter-card`）：family 模式→公開範囲 segment（全部/私有）；**始终**→账本 segment（すべて/日常 daily tone/ときめき joy tone）。segment 用 `.segmented-control` 形态（现 shopping 用 Material SegmentedButton，改为与 list/analytics 一致的 pill segmented 视觉，daily/joy tone 经 palette）。
- 「買うもの」section-title + 並べ替え text-btn（`accentPrimary`）。
- 清单卡（`.shopping-list-card`，圆角 14、`borderDefault`、行分隔）：每行 `.shopping-item`：圆形 check（未完成→边 daily/joy 空心；完成→daily/joy 实心+白勾）+ copy（strong 名 + small meta；完成→删除线+opacity .58）+ ledger badge（daily→`dailyLight`/`dailyText`，joy→`joyLight`/`joyText`）+ drag handle(`textTertiary`)。
- 「完了」section（有完成项时）+ すべて削除 text-btn；完成项列表。
- 空态（`.shopping-empty`，`textSecondary`，圆角 14 卡）。

**保留数据接线**：`filteredShoppingItemsProvider`(Drift .watch 流，**禁** `ref.invalidate` 除 error retry)、`listTypeProvider`(scope all/private)、`batchSelectModeProvider`、`shoppingReorderModeProvider`、SliverReorderableList + proxyDecorator + `reorderShoppingItemsUseCaseProvider.applyOrder`、ClearCompleted 确认对话、ShoppingSelectionHeader/BatchActionBar 批量 chrome 全部不动；只改视觉。
账本 segment 联动：mockup 的账本 filter 若现有 filter provider 未支持，允许**additive 扩展** `state_shopping_filter`（本屏 presentation provider）加 ledger 维度，客户端对已流出的 items 过滤——不改 lib/data、不改 repository、不破坏 scope/reorder/batch 现状；若判断超出 presentation-only 边界则回退为「仅视觉呈现该 segment、暂沿用现有筛选语义」并在 SUMMARY 标注。
ARB：复用现有 shopping* / list ledger key（shoppingListScreenTitle/shoppingSegmentAll/shoppingSegmentPrivate/shoppingCompletedDivider/listLedgerDaily/listLedgerJoy 等），尽量零新增。
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3 && flutter test test/golden/shopping_item_tile_golden_test.dart test/golden/shopping_filter_bar_golden_test.dart test/golden/shopping_empty_state_golden_test.dart test/golden/shopping_batch_chrome_golden_test.dart test/widget/features/shopping_list 2>&1 | tail -8</automated>
    人工：模拟器浅+深，勾选/未勾选/完成删除线/账本 badge/筛选 segment/reorder/批量/空态对比 mockup A1/A3 + v15-shopping-* 截图。
  </verify>
  <done>
- 购物页浅/深两主题高保真对齐 mockup（D-02），无硬编码色。
- filteredShoppingItems 流式反应性、scope/ledger 筛选、reorder、批量、完成清理全部保留（若扩展 filter 为 additive，未破坏现有语义）。
- `flutter analyze` 0 issue；受影响 shopping golden 浅+深已 macOS 重基线；全量 `flutter test` 绿。
  </done>
</task>

</tasks>

<verification>
每个 Task 完成后（该屏 executor 自查）：
- `flutter analyze` = 0 issue（含 color_literal_scan / hardcoded_cjk_ui_scan / theme_dark_mode_coverage 架构测试）。
- 全量 `flutter test` 绿（不 scoped、不经 tail 掩盖 exit code）；受影响 golden 已在 macOS 用 `--update-goldens` 重基线（浅+深两主题，golden 测试通常同时迭代两 brightness）。
- 该屏现有 provider/交互回归通过（无 provider 图破坏、无数据写死）。
- 无硬编码色值：`git diff` 中该屏无裸 `Color(0x..)`/`Colors.*`（palette token 全覆盖）。

四屏合并后（orchestrator）：
- 四屏文件不重叠（home/list/analytics/shopping 各自 feature 目录 + 未新增/串行处理 ARB）→ 无合并冲突。
- 全量 `flutter analyze` + `flutter test` 绿；四屏浅+深 golden 均已重基线。
- 设备端浅色(A1)+深色(A3)四页面逐屏与 mockup 对比通过（人工 UAT）。
</verification>

<success_criteria>
- 主页/明细/统计/购物四页面视觉表面高保真对齐 v15 mockup A1（浅）/A3（深），符合 D-02。
- 全部颜色经 `context.palette` 派生，单套 widget 代码在浅/深两主题下自动成立，零硬编码色。
- 四页面各由独立 executor 原子实现、文件不重叠（D-01）。
- 现有 providers/repositories/数据流保留或仅 additive 扩展，provider 图未破坏。
- `flutter analyze` 0 issue；全量 `flutter test` 绿；四屏浅+深 golden macOS 重基线。
</success_criteria>

<output>
四个 Task 各自原子提交（`feat: <屏> 移植 v15 A1/A3 视觉` 量级）。每屏 executor 完成后知会 orchestrator 该屏状态（含 golden 重基线数、analyze/test 结果、是否 additive 扩展了 provider、是否新增 ARB key）。
</output>
