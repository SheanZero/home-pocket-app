# Quick Task 260620-lfp: round5 mock 重做统计页 — Research

**Researched:** 2026-06-20
**Domain:** Flutter presentation-layer rebuild (analytics 支出侧统计页) to match `round5/r5-drawer-joybar.html`
**Confidence:** HIGH (codebase-grounded; all current widgets + palette + ARB + golden inventory read directly)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D1** 严格度 `--full` (discuss + research + plan-check ≤2 + verify).
- **D2** 结构完全对齐 mock，**逆转 Phase 46 D-F2**「扁平无节标题」：重新加回 **4 个节标题**（带 实用/悦己 tag chip），并把悦己堆叠条 **内嵌**进分类支出卡作为 connector+drawer（不再是顶层独立卡 #3）。lineup 5 顶层卡 → 4 节（趋势 / 分类支出[含悦己抽屉] / 小确幸日历 / 满足度分布）+ group-only family_insight。
- **D3** 趋势图 `WithinMonthTrendCard` 内部逐字保留（round-3 成果），只外包「支出趋势·实用」节标题。
- **D4** 数据用真实 provider，mock 数字全是 SIMULATED 示例，绝不写死。
- **D5** 颜色走 `context.palette.*`（ADR-019），禁裸 hex；悦己 7 色暖板（j1–j7）沿用 `JoySpendStackedBar` 已有色板（若已存在则不动）。
- **D6** Golden 重基线 + 全量测试；macOS-only 重基线（CI 用 BaselineExistenceGoldenComparator）。
- **D7** 节标题 + tag 文案走 ARB（ja/zh/en 三份 + `flutter gen-l10n`），禁硬编码串。

### Claude's Discretion
- 节标题做成共享 `AnalyticsSectionHeader` widget（倾向）vs 内联 — planner 定；倾向抽小 widget（3px 竖条 + 标题 + tag）复用 4 处。
- joybar 内嵌后 `JoySpendCard` 文件保留/改造由 planner 定（保留 provider 接线，外壳改为 CategoryDonutCard 内渲染 connector+drawer）。
- ja/en 节标题与 tag 具体译法由 executor 拟定（ja 优先，遵守现有 ARB 风格）。
- ADR-012 反游戏化：悦己侧零跨期/零目标环/零排名/零打卡/零成就，沿用 mock 中性框定语。

### Deferred Ideas (OUT OF SCOPE)
- 不动 domain models / repositories / providers 的数据契约；现有数据来源保持不变（视觉保真 + 结构重排，非数据层重写）。
- 不画入账侧 / 不画结余比率。family 数据仅聚合。
</user_constraints>

## Summary

This is a **pure presentation refactor** of the analytics 支出侧 screen against `round5/r5-drawer-joybar.html`. The data layer, providers, and 5 underlying widgets already exist and stay byte-identical at the data contract. The work is three structural moves plus visual fidelity:

1. **Re-introduce 4 section headers** (D2 reverses Phase 46 D-F2). The old `AnalyticsScreenSectionHeader` was a U+2501-glyph text label — it must be **rebuilt from scratch** as the mock's `.sect-h` (3px left bar tinted primary/joy + 12px/600 title + right tag chip). The shell (`analytics_screen.dart` `_buildCardChildren` + registry) currently emits a flat Column with NO headers; headers must be threaded back WITHOUT making the registry import any `home/*` provider (GUARD-01 / D-B1).
2. **Nest the joybar inside CategoryDonutCard** (D2): `JoySpendCard` stops being top-level card #3; its body (count-up header + `JoySpendStackedBar` + single-column legend) moves under the donut hero behind a `joy-connector` chip「▾ 把悦己这一块放大看看」inside a pink-bordered `.drawer`. The registry drops from 6 specs to 5 (trend, category_donut[+joy drawer], joy_calendar, satisfaction_histogram, family_insight group-only).
3. **Donut center simplification** (mock change 3): center shows ONLY total + neutral「本月支出」label — current `_DonutHero` already does exactly this (`analyticsDonutCenterLabel`, no daily/joy split line). Minimal change here.

**Primary recommendation:** Build a reusable `AnalyticsSectionHeader` widget (3px bar + title + tag chip, palette-driven, ARB-driven text), wire it into the shell's `_buildCardChildren` as per-spec leading metadata (add an optional `sectionHeader` descriptor to `AnalyticsCardSpec` whose value is a plain enum/struct resolved to text+tint at shell build-time — keep the registry importing zero providers). Move `JoySpendCard`'s body into `CategoryDonutCard` via a new private `_JoyDrawer` widget that watches `joyCategoryAmountsProvider` itself (keep its single-source refresh contract). Re-color `JoySpendStackedBar` to the mock's **j1–j7 warm palette** — it does NOT exist today (current bar lerps daily→joyLight, see Pitfall 1).

## Per-Section Gap Analysis

### ① 支出趋势 (实用) — `cards/within_month_trend_card.dart`
- **FROZEN internals (D3).** Card body unchanged (pill-tabs 总支出/日常/悦己, 本月实线+上月虚线, 悦己单线零跨期, X-axis, 终点标注 — all round-3 polished).
- **Only delta:** a「支出趋势」节标题 (prac/green tag「实用」) must render ABOVE this card. Today the registry's spec #1 renders the bare card. Section header is supplied by the shell, not by the card.
- The card already wraps in `AnalyticsDataCard` (title `analyticsCardTitleWithinMonthTrend` = "Spending trend"). Mock has BOTH an outer `.sect-h` 节标题 AND the card. Decision for planner: keep the inner card title or let the section header subsume it (mock card has no separate title — pills sit at top). **Recommend:** section header replaces the visible card title role; consider passing a flag to suppress `AnalyticsDataCard` title, or accept light redundancy. [ASSUMED — needs planner call]

### ② 分类支出 hero (donut) — `cards/category_donut_card.dart` + (legacy `category_spend_donut_chart.dart`)
- Current `_DonutHero` (in category_donut_card.dart) ALREADY matches mock intent: `PieChart` (centerSpaceRadius 56, cornerRadius 4) + center「本月支出」(`analyticsDonutCenterLabel`) + count-up total + 10 L1-rollup legend rows amount-descending + neutral "Other" row when >10 L1.
- **NOTE:** `widgets/category_spend_donut_chart.dart` is the OLD standalone chart widget — `CategoryDonutCard` no longer uses it (donut is inlined as `PieChart` in `_DonutHero`). Confirm whether it's still referenced anywhere; if orphaned, it's out of scope to delete (retain unless planner wants cleanup).
- **Deltas vs mock:**
  - Mock legend dot is a 4px-radius rounded square (`border-radius:4px`); current `_LegendRow` uses a `BoxShape.circle` dot. Cosmetic — match if pursuing pixel fidelity.
  - Mock center label「本月支出」neutral — matches `analyticsDonutCenterLabel`. Good.
  - Mock hero has a「这个月，钱花在哪」hero-cap + 「86 笔 · 5 月」hero-tag at top. Current card uses `AnalyticsDataCard` title/caption (`analyticsCardTitleCategoryDonut` / `analyticsCardCaptionCategoryDonut`). The mock card is a `.hero` (22px radius, radial-gradient bg, larger shadow) — current is a plain `Card`. Hero styling + hero-cap/tag are deltas. [match per D2]
  - **Biggest delta:** the joy DRAWER (②b) must be appended inside this card's Column (see below).
- Donut slice color: mock uses fixed per-category vars (`--cat-food` green, `--cat-joy` pink, etc.); current lerps daily→joy by index. Per D5 keep palette-driven; exact per-category fixed coloring is NOT required (mock comment says 悦己系分类 keep pink「作账本暗示」but it's optional). Keep current lerp unless planner wants fidelity.

### ②b 悦己抽屉 (joybar) — `cards/joy_spend_card.dart` + `widgets/joy_spend_stacked_bar.dart`
- **Current widget API:**
  - `JoySpendCard(bookId, startDate, endDate, joyMetricVariant)` — `ConsumerWidget`, watches `joyCategoryAmountsProvider(book/start/end/variant)`, single-source `joySpendRefreshTargets(ctx)`.
  - `_JoySpendBody(amounts)` builds `JoySpendSegment` list (label/amount/formattedAmount/percent/color) and renders count-up「悦己 ¥…」header (`analyticsJoySpendHeaderLabel`, joyText, amountLarge) + `JoySpendStackedBar(segments)`.
  - `JoySpendStackedBar(segments)` — `Row` of `Flexible(flex: amount)` segments + single-column legend (dot + label + ¥ + %). Already largest→smallest. Local tap-highlight (D-C2 no drill).
- **What it takes to render inside CategoryDonutCard:**
  - The cleanest path that **preserves the single-source refresh contract**: add a private `_JoyDrawer extends ConsumerWidget` inside `category_donut_card.dart` (or a new `widgets/joy_spend_drawer.dart`) that watches `joyCategoryAmountsProvider` with the SAME key and renders connector chip + `.drawer` + reused `_JoySpendBody`/`JoySpendStackedBar`. `_DonutHero` appends it after the legend.
  - **Registry change:** delete the `JoySpendCard` spec (registry → 5 specs). BUT the joy-spend refresh target must NOT be lost from the `_refresh` union — fold `joySpendRefreshTargets` into `categoryDonutRefreshTargets` (return both `monthlyReportProvider` AND `joyCategoryAmountsProvider`) so pull-to-refresh still invalidates the joy data. [CITED: analytics_screen.dart `_refresh` derives the union from `registry.expand(refreshTargets)`]
  - **Discretion (D):** keep `joy_spend_card.dart` file or fold into donut. Recommend: retain `JoySpendStackedBar` + `JoySpendSegment` (reused), extract the body into a shared `_JoyDrawerBody`, and either keep `JoySpendCard` as a thin wrapper (for its existing golden/test) or delete it + migrate its tests.
- **Drawer chrome (mock):** pink gradient bg `#FFF9FB→card`, 1px `--joyBorder #EFC9D5` border, 18px radius; drawer-top「悦己 ¥47,200 花在哪几类开心事」(joyText) +「7 类」(drawer-tot); drawer-sub「仅呈现去向，不分高下」; joybar 32px tall, 9px radius, joyBorder; single-column legend; drawer-cap2 footnote. The connector = dashed 2px stem + pink chip「▾ 把悦己这一块放大看看」.

### ③ 小确幸日历 (悦己) — `cards/joy_calendar_card.dart` + `widgets/joy_calendar_heatmap.dart`
- Current `JoyCalendarHeatmap` = 7-col Monday-first `GridView.count`, continuous `Color.lerp(joyLight, joy, count/maxCount)` depth (ambient, NOT streak), leading-blank offset, inline `AnimatedSize` day-expand panel with read-only tiles.
- **Deltas vs mock:**
  - Mock uses **discrete 4-step heat scale** (`--heat0 #F3ECEA / heat1 #F4D2DC / heat2 #E8A9BC / heat3 #D98CA0`); current uses a CONTINUOUS lerp. The mock cal-legend shows a 4-swatch 淡→浓 scale. Decision: keep continuous lerp (ambient, ADR-012-safe) OR bucket to 4 discrete steps to match. The mock's heat0–3 are a deliberate palette; **no `heat0..heat3` tokens exist** in `app_palette.dart`. [ASSUMED — planner picks: continuous-lerp-keep vs add 4 heat tokens to palette]
  - Mock cell shows the day number top-right (`.dn` 8.5px); current centers it. Cosmetic.
  - Mock has a `.cal-legend` (淡 [swatches] 浓 + 中性说明) + `.cal-cap` footnote「这个月有 16 天…只看哪些天发生过」. Current relies on `AnalyticsDataCard` caption `analyticsCardCaptionJoyCalendar`. The legend strip + caption are deltas to add.
  - Section header「小确幸日历」joy tag「悦己」above the card.

### ④ 悦己满足度分布 (悦己) — `cards/satisfaction_histogram_card.dart` + `widgets/satisfaction_distribution_histogram.dart`
- Current `SatisfactionDistributionHistogram` = `fl_chart` `BarChart`, 1–10 bars, native `BarChartRodLabel` on score-5 (`analyticsHistogramBarFiveAnnotation`), cool→warm `_colorForScore` ramp, color caption. Self-hides when `totalJoyTx < 5`.
- **Deltas vs mock:**
  - Mock bars use a single `joy→#E7A6B6` gradient (all bars pink-family); current ramps daily-green→joy→accentPrimary by score. Per D5 keep palette ramp OR switch to joy-family gradient to match mock's all-pink bars. [ASSUMED — planner call; mock is joy-tab so all-pink is intentional]
  - Mock highlights the **median** bucket (`.b.med` outline) — mock annotates score-7 as median; current annotates score-5 as「中央値・含未評価」. The mock's median is data-derived (中位满足度 7 pill). Current hardcodes score-5 annotation. **Delta:** mock wants a `histo-foot` with「22 笔悦己支出的满足度」+「中位满足度 7」med-pill. Current has neither the footer count nor a data-driven median pill. This needs a median computation + pill (the histogram widget receives `buckets` only; median must be derived or passed). [needs data: median is computable from buckets in-widget]
  - Section header「悦己满足度分布」joy tag「悦己」above the card.

## Section Header Re-introduction (the D2 reversal)

**Old widget is NOT reusable.** Git-recovered `analytics_screen_section_header.dart` (deleted in `cc0b8534`, Phase 46-07) was just:
```dart
Text('━ $label ━', style: caption.copyWith(w700, textSecondary))
```
— a U+2501 glyph text label. The mock's `.sect-h` is a different design entirely (3px left bar + title + tag chip). **Build a NEW `AnalyticsSectionHeader` from scratch.**

**Mock `.sect-h` spec (lines 93–100):**
- `font-size:12px; font-weight:600; letter-spacing:.08em; color:--ink2 (textSecondary)`
- `::before` = 3px×13px rounded bar, `background:--primary` (prac) or `--joy` (joy)
- right tag chip: 10.5px/600, prac = `dailyText` on `dailyLight`, joy = `joyText` on `joyLight`, default = `ink3` on `neutralBg`

**Recommended widget:**
```dart
enum SectionTone { practical, joy }
class AnalyticsSectionHeader extends StatelessWidget {
  const AnalyticsSectionHeader({super.key, required this.title, required this.tag, required this.tone});
  // bar color: tone==practical ? palette.accentPrimary : palette.joy
  // tag colors: practical → palette.dailyText on palette.dailyLight
  //             joy       → palette.joyText  on palette.joyLight
}
```

**Shell wiring WITHOUT breaking GUARD-01 / D-B1:** The registry must import zero `home/*` providers — section-header metadata is plain data (title-key + tone enum), it imports NOTHING, so this is safe. Two clean options:
- **(A) Add optional `sectionHeader` field to `AnalyticsCardSpec`** holding a plain `({String Function(S) title, String Function(S) tag, SectionTone tone})?` descriptor. `_buildCardChildren` renders `AnalyticsSectionHeader` before any spec whose `sectionHeader != null`. Registry stays provider-free (descriptor is text-resolver closures + enum). **Recommended** — keeps render order single-sourced.
- **(B) Hardcode the 4 headers in `_buildCardChildren`** keyed to card type (`built is WithinMonthTrendCard` → 支出趋势 header, etc.). Simpler but couples shell to card types and the family card has no header. Acceptable since lineup is fixed.

Either way: `_refresh` union is untouched (headers carry no providers). The `analytics_screen_test.dart:173` test「renders the flat round-5 B 5-card lineup with NO section headers」**MUST be updated** to assert headers ARE present (see Pitfalls).

**Mock node→section mapping:**
| Mock `.sect-h` | tone | tag | card |
|---|---|---|---|
| 支出趋势 | prac (green) | 实用 | within_month_trend |
| 分类支出 | prac (green) | 实用 | category_donut (+joy drawer) |
| 小确幸日历 | joy (sakura) | 悦己 | joy_calendar |
| 悦己满足度分布 | joy (sakura) | 悦己 | satisfaction_histogram |

## Palette Mapping (mock hex → `context.palette` token)

File: `lib/core/theme/app_palette.dart` (light values shown; dark auto-derived). Resolve via `context.palette.*`.

| Mock CSS var | Hex | `palette` token | Notes |
|---|---|---|---|
| `--bg` | `#FBF7F4` | `background` | warm cream |
| `--card` | `#FFFFFF` | `card` | |
| `--primary` / nav green | `#6FA36F` | **`accentPrimary`** | NOT a `daily` token — leaf-green primary |
| `--primaryLight` | `#EEF6EC` | `accentPrimaryLight` | |
| `--primaryBorder` | `#CFE6CF` | `accentPrimaryBorder` | |
| `--daily` | `#5FAE72` | `daily` | |
| `--dailyText` | `#2E6B3A` | `dailyText` | prac tag text |
| `--dailyLight` | `#EEF6EC` | `dailyLight` | prac tag bg |
| `--joy` (樱粉) | `#D98CA0` | `joy` | |
| `--joyText` | `#A53D5E` | `joyText` | joy tag text / drawer cap |
| `--joyLight` | `#FBEAEF` | `joyLight` | joy tag bg / drawer accents |
| `--joyBorder` | `#EFC9D5` | **NO EXACT TOKEN** | closest: drawer border — use `joyLight`-darkened or add token; see below |
| `--shared` | `#5B8AC4` | `shared` | |
| `--border` | `#E6DDD8` | `borderDefault` | |
| `--divider` | `#EAE1DC` | `borderDivider` | legend row dividers |
| `--borderList` | `#DDD4CE` | `borderList` | |
| `--neutralBg` | `#F1ECE8` | `backgroundMuted` | default tag chip bg |
| `--neutral` / ink3 | `#A8BCB2` | `textTertiary` | |
| ink2 | `#71877A` | `textSecondary` | |
| ink | `#20352B` | `textPrimary` | |

**`--joyBorder #EFC9D5` has no palette token** (the closest existing pink tokens are `satisfactionPillBg`/`joyFullnessBg #FBEAEF` = joyLight, and `satisfactionPillRose #D98CA0` = joy). For the drawer's pink border and the connector chip border, planner choices: (a) use `palette.joyLight` (slightly lighter than mock), (b) derive `Color.lerp(palette.joy, palette.joyLight, t)`, or (c) add a `joyBorder` token to `AppPalette` (touches palette → wider blast radius, but most faithful). **Recommend (b)** to avoid a palette change. [ASSUMED — planner call]

### 悦己 7-color warm palette (j1–j7): DOES NOT EXIST today
**Confirmed gap.** `JoySpendStackedBar` / `_JoySpendBody._segmentColor` currently lerps `Color.lerp(palette.joy, palette.joyLight, t)` — a single-family pink ramp, NOT the mock's 7 distinct warm hues. The mock j1–j7 are:

| var | hue | hex |
|---|---|---|
| j1 | 樱粉 (anchor) | `#D98CA0` |
| j2 | 琥珀金 | `#E2A23B` |
| j3 | 珊瑚赤陶 | `#E0664B` |
| j4 | 梅紫藕 | `#9B5DA6` |
| j5 | 桃沙 | `#EBB87A` |
| j6 | 暖灰褐 | `#B08363` |
| j7 | 藕灰玫 | `#C7A7AE` |

D5 says「沿用现有 `JoySpendStackedBar` 已有的色板（若已存在则不动）」— but it does NOT exist; the current lerp is a different design. **The j1–j7 palette must be introduced.** These are NOT in `AppPalette` and are a joybar-专属 palette (D5 carve-out: "悦己 7 色暖调色板是 joybar 专属调色板"). Recommend a local `const List<Color> _joyWarmPalette` in the joybar widget (or a small `joy_warm_palette.dart`), indexed by segment order — this is the ONE place裸 hex is allowed per D5 (joybar-专属 palette, analogous to `happiness_ring_palette.dart`). [ASSUMED — D5 carve-out interpretation; planner confirms裸hex-allowed-here]

## i18n

- **ARB files:** `lib/l10n/app_en.arb` / `app_ja.arb` / `app_zh.arb` (ja default). `l10n.yaml` → class `S`, output `lib/generated/`. `S.of(context).<key>`.
- **Convention:** analytics keys prefixed `analytics…`; card titles `analyticsCardTitle<Card>` / captions `analyticsCardCaption<Card>` (e.g. `analyticsCardTitleCategoryDonut`, `analyticsCardTitleJoySpend`). Keys are camelCase; CJK punctuation `·` used freely in values.
- **New keys needed (D7):** 4 section titles + 2 tag labels + drawer/calendar/histogram supporting copy. Proposed:

| key | en | ja (default) | zh |
|---|---|---|---|
| `analyticsSectionTrend` | Spending trend | 支出トレンド | 支出趋势 |
| `analyticsSectionCategory` | Category spending | カテゴリ支出 | 分类支出 |
| `analyticsSectionJoyCalendar` | Little joys calendar | 小さな幸せカレンダー | 小确幸日历 |
| `analyticsSectionSatisfaction` | Joy satisfaction | 悦びの満足度 | 悦己满足度分布 |
| `analyticsSectionTagPractical` | Practical | 実用 | 实用 |
| `analyticsSectionTagJoy` | Joy | 悦び | 悦己 |
| `analyticsJoyDrawerConnector` | Zoom into your joy spending | 悦びの内訳を見る | 把悦己这一块放大看看 |
| `analyticsJoyDrawerSubtitle` | Just where it went, no ranking | 使い道だけ、優劣なし | 仅呈现去向，不分高下 |

(en/zh/ja译法 executor 定 per D; ja first. Reuse `analyticsCardTitle*` where the section title can double as the card title to minimize new keys.)
- **anti-toxicity:** new joy-side strings (drawer subtitle, calendar caption, histogram footer) MUST be celebrate-past/neutral — they join `anti_toxicity_phase47_test.dart`'s forbidden-substring sweep (ja/zh/en). Keep mock's「仅呈现去向，不分高下」「不数连续、不比多少」neutral framing (ADR-012).

## Golden + Test Inventory (D6 — macOS-only rebaseline)

**Golden test files to re-baseline (`test/golden/`):**
| file | covers | impact |
|---|---|---|
| `within_month_trend_card_golden_test.dart` | trend card | header added above → likely re-baseline (wrap layout) |
| `category_donut_card_golden_test.dart` | donut hero | **major** — hero styling + nested joy drawer |
| `joy_spend_card_golden_test.dart` | joybar (standalone) | card removed/folded — update or delete + new drawer golden |
| `joy_calendar_card_golden_test.dart` | calendar | legend strip + caption + maybe discrete heat → re-baseline |
| `satisfaction_histogram_card_golden_test.dart` | histogram | median pill + footer + bar color → re-baseline |
| `analytics_screen_scroll_smoke_golden_test.dart` | **whole-screen smoke** | **always re-baseline** — section headers + reordered lineup |
| `daily_vs_joy_card_golden_test.dart` | de-registered card | likely untouched (card not in lineup) — verify no incidental diff |

**Widget/structural tests to UPDATE (not golden):**
- `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart:173` — assertion「renders the flat round-5 B 5-card lineup with NO section headers」**must flip** to assert headers present + JoySpendCard NO LONGER a top-level card (it's now `findsNothing` as a sibling of donut, OR folded). Comment at :178-180 references the deleted header explicitly — rewrite.
- `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` — registry now 5 specs (was 6); render-order + union test must reflect dropped JoySpend spec + folded refresh target.
- `anti_toxicity_phase47_test.dart` — add new section/drawer/calendar strings.

**macOS rebaseline gate:** `flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS (goldens are macOS-baselined; CI ubuntu can't pixel-match). Run `--update-goldens` ONLY on macOS, scoped to the affected files for clean diff attribution. Then FULL `flutter test` (D6) including architecture tests (`hardcoded_cjk_ui_scan` — section titles must go through `S.of`, color_literal_scan — only joybar j1–j7 may be裸hex).

## Pitfalls / Gotchas

### Pitfall 1: joybar 7-color palette does NOT exist (D5 misframe)
CONTEXT D5 says「沿用现有已有色板（若已存在则不动）」but `JoySpendStackedBar` uses a `joy→joyLight` single-family lerp, NOT the mock's 7 distinct warm hues. **The j1–j7 palette must be created.** It's a joybar-专属 palette (D5 carve-out, like `happiness_ring_palette.dart`) → local `const` color list is the sanctioned裸hex exception. Verify `color_literal_scan` allows it (it allows `happiness_ring_palette.dart`); the new list may need the same allowlist treatment.

### Pitfall 2: `color_literal_scan` / `hardcoded_cjk_ui_scan` architecture tests
- All chrome colors MUST be `context.palette.*` — no裸hex except the joybar palette (D5). The mock's `--joyBorder #EFC9D5` and `--heat0..3` have no tokens; resolve via lerp/existing tokens, NOT裸hex.
- All section titles / tags / drawer copy MUST go through `S.of(context)` — `hardcoded_cjk_ui_scan` fails on any literal CJK in widget source (D7).

### Pitfall 3: registry union must not lose the joy refresh target
Folding `JoySpendCard` into the donut deletes its registry spec. `analytics_screen.dart:_refresh` derives the invalidation union from `registry.expand(refreshTargets)`. **Fold `joyCategoryAmountsProvider` into `categoryDonutRefreshTargets`** or the joy drawer won't refresh on pull-to-refresh. (GUARD-01: `joyCategoryAmountsProvider` is an analytics provider — union stays home-free.)

### Pitfall 4: GUARD-01 / D-B1 registry-imports-zero-home
Section-header metadata is plain text/enum — it imports nothing, so it's safe to add to `AnalyticsCardSpec`. Do NOT let header wiring pull a provider into the registry. The `home_screen_isolation_test` + registry union test enforce this.

### Pitfall 5: expense-only filtering trap (analytics-transaction-type-reuse-trap)
Memory gotcha: `findByBookIds` returns ALL tx types; donut/overview must filter `TransactionType.expense`. This is already handled in the existing providers (`monthlyReportProvider`, `joyCategoryAmountsProvider`) — since the data layer is untouched (D4/scope), no new query is introduced. Just don't add any new aggregation that bypasses the filter.

### Pitfall 6: ADR-012 anti-gamification on the 悦己 side
Drawer, calendar, histogram are joy-side → ZERO cross-period / target ring / ranking / streak / achievement. Keep mock's neutral framing verbatim-equivalent (「仅呈现去向，不分高下」「不数连续、不比多少」「不与过往比较」). The median pill on the histogram is descriptive (中位满足度 7) — NOT a target「超过8分」. The joybar in-segment % labels are share-of-self, not ranking. New strings join the anti-toxicity sweep.

### Pitfall 7: median pill needs derivation (histogram)
Mock's「中位满足度 7」+「22 笔悦己支出的满足度」footer don't exist in the current histogram widget (it receives `buckets` only). The median is computable from `buckets` in-widget; the count (n=22) is `total` already computed in `_normalize`/fold. Add a footer row + median pill — derive from data, do NOT hardcode the mock's「7」(D4).

### Pitfall 8: retained-but-unregistered files
`daily_vs_joy_card.dart` + `per_category_breakdown_card.dart` are widget FILES retained with their own tests but NOT in the lineup (Phase 46-07). Leave them alone. `category_spend_donut_chart.dart` is the old standalone donut, likely orphaned (donut now inlined in `_DonutHero`) — verify before touching; out of scope to delete.

### Pitfall 9: D-F2 reversal blast radius
Re-adding headers reverses a Phase-46 LOCKED decision (D-F2). Touch points: `analytics_screen.dart` (`_buildCardChildren`), `analytics_card_registry.dart` (spec shape if option A), the new `AnalyticsSectionHeader` widget, `analytics_screen_test.dart` (assertion flip), the smoke golden. The orphan section-header ARB keys (`analyticsGroupHeaderTime/Distribution/Stories`) were already deleted in 47-03 — the NEW section keys are fresh (no collision).

## Architecture Patterns (existing, to follow)

- **Card = dumb ConsumerWidget + single-source `<card>RefreshTargets(ctx)`.** Each card watches exactly its provider family; error-retry + registry union both draw from the one targets list (D-B2).
- **Pure-UI value carriers:** `JoySpendSegment` (label/amount/formattedAmount/percent/color pre-resolved by the card). The bar widget never fetches/localizes/formats. Mirror this for any new drawer sub-widget.
- **Palette via `context.palette`** (extension `AppPaletteContext on BuildContext`, falls back gracefully in test harnesses).
- **Amounts via `NumberFormatter.formatCurrency(value, 'JPY', locale)` + `AppTextStyles.amount{Large,Medium,Small}`** (tabular figures). Never generic text styles for ¥.
- **Count-up anchors (D-D2):** donut center + joy header use `TweenAnimationBuilder<int>` ~480ms easeOutCubic. The folded drawer keeps the joy-header count-up.

## Don't Hand-Roll

| Problem | Use Instead |
|---|---|
| Currency formatting (¥, tabular) | `NumberFormatter.formatCurrency` + `AppTextStyles.amount*` |
| Category L1 name | `CategoryLocalizationService.resolveFromId(id, locale)` |
| L1 rollup (donut legend) | `rollupCategoryBreakdownsToL1(breakdowns, map, topN:10)` (D-11 single source) |
| Card shell (title/caption/child) | `AnalyticsDataCard` (or hero variant for donut) |
| Error state | `AnalyticsCardErrorState(onRetry:)` |
| Colors | `context.palette.*` (except joybar j1–j7 per D5) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Section header should subsume/replace the inner card title for trend/donut (mock has no separate card title) | ① / ② | Double title rendered; cosmetic, fixable in plan-check |
| A2 | Keep continuous lerp for calendar heat (vs adding discrete heat0–3 tokens) | ③ | Less faithful to mock's 4-step legend; ADR-012-safe either way |
| A3 | Keep joy-family bar colors for histogram (vs all-pink mock gradient) | ④ | Minor visual divergence from mock |
| A4 | joybar j1–j7 introduced as local `const` palette (D5 carve-out =裸hex-allowed) | Palette | If `color_literal_scan` blocks it, needs allowlist entry |
| A5 | `--joyBorder #EFC9D5` resolved via `Color.lerp(joy, joyLight)` not a new palette token | Palette | Slightly off-hex; or add token (wider blast radius) |
| A6 | `category_spend_donut_chart.dart` is orphaned (donut inlined in `_DonutHero`) | ② | If still referenced, don't delete |
| A7 | Folding joy refresh target into `categoryDonutRefreshTargets` is the clean union fix | Pitfall 3 | If kept as a separate hidden spec, union must still include it |

## Open Questions

1. **Keep `JoySpendCard` file as a wrapper or delete it?** (D discretion) — Recommend retain `JoySpendStackedBar`+`JoySpendSegment` (reused in drawer); the card wrapper can stay (for its golden) or be deleted with test migration. Planner decides.
2. **Calendar heat: continuous lerp vs discrete 4-step?** (A2) — affects fidelity + whether palette gains heat tokens.
3. **Histogram bars: palette ramp vs all-pink joy gradient?** (A3).

## Sources

### Primary (HIGH — read directly this session)
- `analytics_screen.dart`, `analytics_card_registry.dart` — shell + registry, `_refresh` union, GUARD-01.
- `cards/{category_donut,joy_spend,joy_calendar,satisfaction_histogram,within_month_trend,analytics_data}_card.dart` — current card structure.
- `widgets/{joy_spend_stacked_bar,joy_calendar_heatmap,satisfaction_distribution_histogram}.dart` — sub-widgets.
- `core/theme/app_palette.dart` — token names + hex (accentPrimary/daily/joy/border* etc.).
- `lib/l10n/app_{en,ja,zh}.arb` — analytics key convention.
- `test/golden/*` inventory + `analytics_screen_test.dart:173` no-headers assertion.
- git `cc0b8534^:…analytics_screen_section_header.dart` — old (non-reusable) header.
- `round5/r5-drawer-joybar.html` — fidelity baseline.

### Secondary (MEDIUM — STATE.md / memory)
- STATE.md Phase 46-07 / 47 decisions (D-F2 flat lineup, section-header deletion, golden rebaseline gate).
- MEMORY: golden-ci-platform-gate (macOS-only), analytics-transaction-type-reuse-trap (expense-only).

## Metadata

**Confidence breakdown:**
- Current widget structure / gap analysis: HIGH (read all source).
- Palette mapping: HIGH (token names + hex confirmed).
- Section-header re-introduction path: HIGH (shell + registry + GUARD verified).
- joybar j1–j7 gap: HIGH (confirmed absent — current uses lerp).
- Golden inventory: HIGH (find listed all files).

**Research date:** 2026-06-20
**Valid until:** stable (codebase snapshot) — re-verify if any Phase-48 analytics work lands first.
