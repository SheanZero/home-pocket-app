---
phase: quick-260620-lfp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/core/theme/joy_warm_palette.dart
  - lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
  - lib/features/analytics/presentation/widgets/analytics_section_header.dart
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
  - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
  - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
  - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
  - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart
  - test/golden/* (rebaseline)
autonomous: true
requirements: [REDES-R5]

must_haves:
  truths:
    - "Per D2: the analytics screen renders 4 section headers (支出趋势·实用 / 分类支出·实用 / 小确幸日历·悦己 / 悦己满足度分布·悦己) — each a 3px left bar (prac=accentPrimary green / joy=joy sakura) + title + tag chip"
    - "Per D2: the 悦己 stacked bar (joybar) renders INSIDE CategoryDonutCard behind a connector chip + pink-bordered drawer — JoySpendCard is no longer a top-level sibling card"
    - "Per D2/Pitfall-3: pull-to-refresh still invalidates the joy data because joyCategoryAmountsProvider is folded into categoryDonutRefreshTargets (registry union stays analytics-only, GUARD-01)"
    - "Per D5: the joybar j1–j7 7-color warm palette (樱粉/琥珀金/珊瑚赤陶/梅紫藕/桃沙/暖灰褐/藕灰玫) is the segment coloring, defined as a bare-hex carve-out in lib/core/theme/ (the only sanctioned 裸hex, like happiness_ring_palette.dart)"
    - "Per D3: WithinMonthTrendCard / WithinMonthCumulativeLineChart internals are byte-unchanged — only wrapped under the new 支出趋势 section header"
    - "Per D4: all displayed numbers come from existing providers (monthlyReport / joyCategoryAmounts / happinessReport / satisfactionDistribution) — zero mock numbers hardcoded; the histogram median pill is data-derived from buckets"
    - "Per D5: all chrome colors resolve via context.palette.* — color_literal_scan passes (only joy_warm_palette.dart in core/ carries hex)"
    - "Per D7: 4 section titles + 实用/悦己 tag labels + drawer/calendar/histogram supporting copy go through S.of(context) — hardcoded_cjk_ui_scan passes; ja/zh/en ARB all updated + gen-l10n run"
    - "Per D6: the 7 affected golden files are rebaselined on macOS and the FULL flutter test suite passes (incl. hardcoded_cjk_ui_scan / registry_test / anti_toxicity_phase47)"
  artifacts:
    - path: "lib/core/theme/joy_warm_palette.dart"
      provides: "joybar j1–j7 warm palette as bare-hex carve-out outside scanned dirs"
      contains: "JoyWarmPalette"
    - path: "lib/features/analytics/presentation/widgets/analytics_section_header.dart"
      provides: "reusable AnalyticsSectionHeader (3px bar + title + tag chip, palette+ARB driven)"
      contains: "class AnalyticsSectionHeader"
    - path: "lib/features/analytics/presentation/analytics_card_registry.dart"
      provides: "5-spec registry (JoySpend de-registered) + per-spec section-header descriptor; categoryDonut union includes joyCategoryAmountsProvider"
      contains: "sectionHeader"
    - path: "lib/features/analytics/presentation/widgets/cards/category_donut_card.dart"
      provides: "donut hero + nested joy connector chip + pink-bordered drawer (joybar + single-column legend + neutral caption)"
      contains: "joyCategoryAmountsProvider"
    - path: "lib/l10n/app_ja.arb"
      provides: "new section-title / tag / drawer / calendar-legend / histogram-footer ARB keys (ja default)"
      contains: "analyticsSection"
  key_links:
    - from: "lib/features/analytics/presentation/screens/analytics_screen.dart"
      to: "AnalyticsSectionHeader"
      via: "_buildCardChildren renders spec.sectionHeader before each headed card"
      pattern: "AnalyticsSectionHeader"
    - from: "lib/features/analytics/presentation/analytics_card_registry.dart"
      to: "joyCategoryAmountsProvider"
      via: "categoryDonutRefreshTargets now returns monthlyReport + joyCategoryAmounts"
      pattern: "joyCategoryAmountsProvider"
    - from: "lib/features/analytics/presentation/widgets/cards/category_donut_card.dart"
      to: "lib/core/theme/joy_warm_palette.dart"
      via: "drawer joybar segments colored by JoyWarmPalette"
      pattern: "JoyWarmPalette"
    - from: "lib/features/analytics/presentation/widgets/analytics_section_header.dart"
      to: "context.palette"
      via: "tone→bar/tag color resolution"
      pattern: "palette\\.(accentPrimary|joy|dailyText|dailyLight|joyText|joyLight)"
---

<objective>
Rebuild the entire analytics 支出侧 screen to match `round5/r5-drawer-joybar.html` — visual + structural fidelity — while keeping every data contract, all provider wiring, and the round-3-polished trend chart internals byte-unchanged. This is a PURE PRESENTATION refactor (D4/scope): no domain models, repositories, or providers change shape.

Three structural moves drive the work:
1. **Re-introduce 4 section headers** (reverses Phase-46 D-F2's flat lineup) via a NEW reusable `AnalyticsSectionHeader` widget threaded into the shell as per-spec leading metadata.
2. **Nest the 悦己 joybar inside CategoryDonutCard** behind a connector chip + pink-bordered drawer; de-register the top-level `JoySpendCard` (registry 6→5 specs) while folding `joyCategoryAmountsProvider` into `categoryDonutRefreshTargets` so the union never loses the joy refresh target.
3. **Visual fidelity** of donut hero, joy drawer (j1–j7 warm palette), calendar (legend strip + caption), and histogram (data-derived median pill + footer).

Purpose: the previous flat round-5-B lineup diverged too far from the user-approved mock; this restores the mock's sectioned IA and the joybar-as-drawer affordance with strict ADR-012 / ADR-019 / i18n compliance.
Output: rebuilt analytics screen + cards, new section-header widget, new joy-warm palette, new ARB keys (gen-l10n'd), updated structural tests, rebaselined goldens, full suite green.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/260620-lfp-round5-r5-drawer-joybar-html-mock/260620-lfp-CONTEXT.md
@.planning/quick/260620-lfp-round5-r5-drawer-joybar-html-mock/260620-lfp-RESEARCH.md
@.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html

# Current implementation — read before editing (do NOT re-read ranges already in context)
@lib/features/analytics/presentation/screens/analytics_screen.dart
@lib/features/analytics/presentation/analytics_card_registry.dart
@lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
@lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
@lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
@lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
@lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
@lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
@lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
@lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
@lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
@lib/core/theme/happiness_ring_palette.dart

# Project rules to obey (already in CLAUDE.md): i18n S.of / 3 ARB + gen-l10n; AppTextStyles.amount*; context.palette; ADR-012 anti-gamification on 悦己 side
</context>

<critical_constraints>
These are settled — do NOT re-derive or relax:

- **CRITICAL palette placement (verified this session):** `color_literal_scan_test.dart` scans `lib/features/`, `lib/application/`, `lib/shared/` for `Color(0x…)` with NO allowlist. `happiness_ring_palette.dart` escapes ONLY because it lives in `lib/core/theme/`. Therefore the joybar j1–j7 palette MUST be a new file `lib/core/theme/joy_warm_palette.dart` (bare-hex legal there). A `const List<Color>` of j1–j7 placed inside any `lib/features/...` widget WILL fail the scan.
- **Registry union (Pitfall-3 / GUARD-01):** `analytics_screen.dart:_refresh` derives the invalidation union from `registry.where(isVisible).expand(refreshTargets)`. De-registering `JoySpendCard` drops `joySpendRefreshTargets` from the union. You MUST fold `joyCategoryAmountsProvider(...)` into `categoryDonutRefreshTargets` (return BOTH `monthlyReportProvider` AND `joyCategoryAmountsProvider`) so pull-to-refresh still invalidates the drawer. The registry must still import ZERO `home/*` providers (`joyCategoryAmountsProvider` is an analytics provider — safe).
- **JoySpendCard file FATE = thin wrapper, NOT deleted (verified this session):** `anti_toxicity_phase47_test.dart:297` builds `JoySpendCard(...)` as a top-level subject AND `joy_spend_card_golden_test.dart` covers it. Keep `joy_spend_card.dart` as a thin wrapper around the shared drawer body so both tests survive; de-register it from the registry; render the joybar inside the donut via a shared body. Do NOT delete the file (would break two tests + force migration).
- **D3 trend FROZEN:** `within_month_trend_card.dart` and `within_month_cumulative_line_chart.dart` internals (pill tabs, 本月实线+上月虚线, 悦己 single line, X-axis, endpoint labels) are byte-unchanged. The ONLY edit allowed to the trend card is title-suppression for the section-header (see Task 3, accept light redundancy if cleaner).
- **D4 real data, NEVER hardcode mock numbers:** ¥248,600 / ¥47,200 / 86 笔 / median 7 / per-category amounts / heat counts are all SIMULATED. Keep every provider read. The histogram median pill must be DERIVED from `buckets` in-widget (Pitfall-7), not the literal「7」.
- **ADR-012 (Pitfall-6):** 悦己 side (drawer / calendar / histogram) = ZERO cross-period / target ring / ranking / streak / achievement. Use the mock's neutral framing verbatim-equivalent (「仅呈现去向，不分高下」「不数连续、不比多少」). The median pill is descriptive, not a target. New joy strings join the anti-toxicity sweep.
- **Palette mapping (RESEARCH table):** mock `--primary #6FA36F` → `palette.accentPrimary` (NOT a daily token). `--joyBorder #EFC9D5` / `--heat0..3` have NO token → resolve via `Color.lerp(...)` of existing tokens, NOT 裸hex. All other chrome → existing palette tokens.
</critical_constraints>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Joy-warm palette + section-header widget + joybar recolor</name>
  <files>lib/core/theme/joy_warm_palette.dart, lib/features/analytics/presentation/widgets/analytics_section_header.dart, lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb</files>
  <behavior>
    - JoyWarmPalette exposes exactly 7 ordered colors j1..j7 matching the mock hex (#D98CA0 / #E2A23B / #E0664B / #9B5DA6 / #EBB87A / #B08363 / #C7A7AE) plus an `colorAt(index)` that wraps (index % 7) so >7 joy categories cycle deterministically.
    - AnalyticsSectionHeader(title, tag, tone): tone==practical renders a 3px left bar = palette.accentPrimary and a tag chip = palette.dailyText on palette.dailyLight; tone==joy renders bar = palette.joy and tag = palette.joyText on palette.joyLight. Title style 12px/w600 letter-spacing, color palette.textSecondary. Renders title + tag text passed by caller (already localized).
    - JoySpendStackedBar segment colors come from JoyWarmPalette.colorAt(index) (mock j1–j7), replacing the current joy→joyLight lerp; legend dots match. (Segment value carrier `color` is still set by the card — wire the card to pass JoyWarmPalette colors, OR have the bar index into the palette; keep ONE source.)
  </behavior>
  <action>Create `lib/core/theme/joy_warm_palette.dart` mirroring the `happiness_ring_palette.dart` structure (per D5 carve-out — this is the ONLY sanctioned 裸hex location; it MUST live in core/ not features/ to pass color_literal_scan): a `class JoyWarmPalette` with 7 `Color(0x…)` constants j1–j7 from the mock's 悦己暖色调色板 comment, exposed as an ordered `List<Color> segments` + `Color colorAt(int index) => segments[index % segments.length]`. Document WHY hex is allowed here (joybar-专属 palette, analogous to happiness_ring_palette).

Create `lib/features/analytics/presentation/widgets/analytics_section_header.dart`: `enum SectionTone { practical, joy }` + `class AnalyticsSectionHeader extends StatelessWidget` taking `{required String title, required String tag, required SectionTone tone}`. Resolve bar/tag colors from `context.palette` per the mock `.sect-h` spec (3px×13px rounded bar; tag chip 10.5px/w600). Title and tag text are passed pre-localized by the caller — the widget contains NO literal CJK (hardcoded_cjk_ui_scan).

Recolor `joy_spend_stacked_bar.dart` segments to `JoyWarmPalette` (per D5). The current `_segmentColor` lerp lives in `joy_spend_card.dart`'s `_JoySpendBody` (line ~140 assigns `JoySpendSegment.color`; the bar at `joy_spend_stacked_bar.dart:93,175` only READS `segment.color`) — single color source confirmed. The recolor must apply wherever the segment `color` is resolved so BOTH the standalone wrapper and the nested drawer use j1–j7. Pick ONE source: have the shared body assign `JoyWarmPalette().colorAt(index)` to each `JoySpendSegment.color`. The legend dots already read `segment.color`, so they follow automatically.

Add new ARB keys to all 3 files (ja default, then zh, then en — match existing `analytics…` camelCase convention; CJK `·` allowed in values; executor picks reasonable ja/en translations per CONTEXT Discretion). Keys (final names executor's call, suggested): `analyticsSectionTrend`, `analyticsSectionCategory`, `analyticsSectionJoyCalendar`, `analyticsSectionSatisfaction`, `analyticsSectionTagPractical` (实用/実用/Practical), `analyticsSectionTagJoy` (悦己/悦び/Joy), `analyticsJoyDrawerConnector` (把悦己这一块放大看看 / …), `analyticsJoyDrawerTitle` (悦己 ¥… 花在哪几类开心事 — use a placeholder for the amount), `analyticsJoyDrawerSubtitle` (仅呈现去向，不分高下), `analyticsJoyDrawerCaption` (百分比是各项占悦己自身的比例…不与过往比较), `analyticsCalLegendLow`/`analyticsCalLegendHigh` (淡/浓), `analyticsCalLegendNote` (颜色越浓 = 那天的悦己笔数越多), `analyticsHistogramMedianPill` (中位满足度 {value} — parameterized), `analyticsHistogramCountFooter` ({count} 笔悦己支出的满足度 — parameterized). All joy-side strings must be ADR-012-neutral (no 排名/连续/超过/目标). Run `flutter gen-l10n` after editing ARBs.</action>
  <verify>
    <automated>flutter gen-l10n && flutter analyze lib/core/theme/joy_warm_palette.dart lib/features/analytics/presentation/widgets/analytics_section_header.dart lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart</automated>
  </verify>
  <done>joy_warm_palette.dart (in core/) + analytics_section_header.dart compile with 0 analyze issues; gen-l10n succeeds with the new keys present in lib/generated; joybar segments use j1–j7; no CJK literal in the new widget source.</done>
</task>

<task type="auto">
  <name>Task 2: Nest joybar drawer into CategoryDonutCard + fold refresh target + thin JoySpendCard wrapper</name>
  <files>lib/features/analytics/presentation/widgets/cards/category_donut_card.dart, lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart</files>
  <action>Move the joy-drawer body into `category_donut_card.dart`. Extract the reusable joy body (count-up header + JoySpendStackedBar + single-column legend) so it can render in BOTH the standalone wrapper and the nested drawer — single source. Add a private `_JoyDrawer extends ConsumerWidget` inside `category_donut_card.dart` that watches `joyCategoryAmountsProvider` with the SAME key tuple (bookId/startDate/endDate/joyMetricVariant) the de-registered card used, and renders: the mock connector (dashed 2px stem + pink chip「▾ {analyticsJoyDrawerConnector}」) followed by the `.drawer` (pink-bordered card via `Color.lerp(palette.joy, palette.joyLight, t)` for the border — NO 裸hex for joyBorder per RESEARCH A5) containing drawer-top (`analyticsJoyDrawerTitle` with the data-derived ¥ total + 「N 类」count) + drawer-sub (`analyticsJoyDrawerSubtitle`) + the joybar body + drawer-cap2 (`analyticsJoyDrawerCaption`). Append `_JoyDrawer` after the donut legend inside `_DonutHero`'s Column (or in `CategoryDonutCard.build` after the AnalyticsDataCard child) so the joybar sits inside the donut hero per mock §2b. The drawer empty-state (no joy amounts) reuses the existing neutral `analyticsJoySpendEmpty` copy.

Fold the joy refresh target into `categoryDonutRefreshTargets` (Pitfall-3 / GUARD-01): make it return BOTH `monthlyReportProvider(...)` AND `joyCategoryAmountsProvider(...)` keyed on ctx. Update the card's error-retry at `category_donut_card.dart:79` that does `ref.invalidate(targets.single)` — it can no longer use `.single` (now 2 targets); invalidate `targets.first` (the monthlyReport, which is what the donut `.when` error branch owns) or invalidate all. The `_JoyDrawer`'s own error branch invalidates `joyCategoryAmountsProvider`.

Reduce `joy_spend_card.dart` to a THIN WRAPPER (do NOT delete — `anti_toxicity_phase47_test.dart` + `joy_spend_card_golden_test.dart` consume it). It keeps its ctor + `joySpendRefreshTargets` (still referenced by those tests) and delegates its body to the shared joy body extracted above (import it). It is no longer registered in the registry (Task 3 removes its spec). Verify `joySpendRefreshTargets` stays exported.</action>
  <verify>
    <automated>flutter analyze lib/features/analytics/presentation/widgets/cards/category_donut_card.dart lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart</automated>
  </verify>
  <done>CategoryDonutCard renders the connector chip + pink drawer with the joybar inside the hero; `categoryDonutRefreshTargets` returns monthlyReport + joyCategoryAmounts; error-retry no longer uses `.single`; JoySpendCard remains a compiling thin wrapper delegating to the shared body; 0 analyze issues.</done>
</task>

<task type="auto">
  <name>Task 3: Wire 4 section headers into the registry + shell (D-F2 reversal)</name>
  <files>lib/features/analytics/presentation/analytics_card_registry.dart, lib/features/analytics/presentation/screens/analytics_screen.dart, lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart</files>
  <action>Add an optional `sectionHeader` descriptor field to `AnalyticsCardSpec` — a plain provider-FREE struct/record `({String Function(S) title, String Function(S) tag, SectionTone tone})?` (RESEARCH option A). This keeps the registry importing ZERO `home/*` providers (GUARD-01 — the descriptor holds only text-resolver closures + an enum). Drop the `JoySpendCard` spec entirely (registry 6→5 specs: within_month_trend, category_donut[+joy drawer], joy_calendar, satisfaction_histogram, + group-only family_insight). Attach `sectionHeader` to the 4 headed specs per the mock node→section mapping: within_month_trend → (analyticsSectionTrend, analyticsSectionTagPractical, practical); category_donut → (analyticsSectionCategory, analyticsSectionTagPractical, practical); joy_calendar → (analyticsSectionJoyCalendar, analyticsSectionTagJoy, joy); satisfaction_histogram → (analyticsSectionSatisfaction, analyticsSectionTagJoy, joy). The family_insight spec gets NO header. Remove the `joy_spend_card.dart` import from the registry if now unused.

Rewrite `analytics_screen.dart:_buildCardChildren` to render an `AnalyticsSectionHeader` (resolving title/tag via `S.of(context)` from the descriptor closures) immediately before any spec whose `sectionHeader != null`, then the card, with the mock's spacing (section header has `margin:26px 4px 10px` → translate to a leading `SizedBox(height: 26)` before the header except the first, + `SizedBox(height: 10)` between header and card). `_refresh` is untouched (headers carry no providers). Keep the FamilyInsightDataCard shell-injection path intact.

In `within_month_trend_card.dart`: the mock has the section header「支出趋势」ABOVE the card and the card itself has NO separate title (pills sit at top). To avoid a double title (RESEARCH A1), suppress the AnalyticsDataCard title/caption for the trend card — either pass empty strings or render the trend body without the title row. Do this with the MINIMAL change to the card wrapper only; DO NOT touch `_TrendBody`, `_PillTabs`, the chart, or `within_month_cumulative_line_chart.dart` (D3 frozen). If suppression is awkward, accept the section header subsuming the title and leave the inner title — document the choice in the commit. Same consideration applies to the donut/calendar/histogram cards: prefer letting the section header be the section label and keeping the existing card titles (light redundancy acceptable) UNLESS it visibly diverges from the mock — executor's fidelity call, documented.</action>
  <verify>
    <automated>flutter analyze lib/features/analytics/presentation/analytics_card_registry.dart lib/features/analytics/presentation/screens/analytics_screen.dart lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart</automated>
  </verify>
  <done>Registry has 5 specs (no JoySpend), 4 carry a provider-free sectionHeader descriptor; shell renders AnalyticsSectionHeader before each headed card with mock spacing; `_refresh` union unchanged structurally; trend card title handled (suppressed or documented); 0 analyze issues; registry still imports zero home/* providers.</done>
</task>

<task type="auto">
  <name>Task 4: Calendar legend + caption and histogram data-derived median pill + footer</name>
  <files>lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart, lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart, lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart, lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart</files>
  <action>Calendar (mock §3): add the `.cal-legend` strip below the heatmap — 淡 [4 swatches 淡→浓] 浓 + a neutral note — using ARB keys `analyticsCalLegendLow`/`analyticsCalLegendHigh`/`analyticsCalLegendNote`. The 4 swatches map mock --heat0..3 (#F3ECEA/#F4D2DC/#E8A9BC/#D98CA0); since those tokens don't exist, derive them by lerping `palette.backgroundMuted`→`palette.joy` at 4 fixed stops (the legend is illustrative — exact mock hex not required, ADR-012-safe). KEEP the continuous-lerp depth mapping in `joy_calendar_heatmap.dart` as-is (RESEARCH A2 — do not bucket to discrete; ambient is ADR-012-safe) — only ADD the legend strip + caption; the day-number top-right `.dn` placement is cosmetic and may be matched if cheap. The「这个月有 N 天…」caption is already `analyticsCardCaptionJoyCalendar` via AnalyticsDataCard — leave it.

Histogram (mock §4 + Pitfall-7): add a `histo-foot` row below the bars: left = count footer `analyticsHistogramCountFooter` with n DERIVED from `total` (already computed in `_normalize`/fold), right = a med-pill `analyticsHistogramMedianPill` with the median DERIVED from `buckets` in-widget (NOT the literal「7」, D4). Compute the median as the score whose cumulative count crosses 50% of total (weighted median over the 1–10 buckets); pass it through the parameterized ARB key. Outline the median bucket's bar (mock `.b.med` outline = 2px `joyBorder`-lerp outline). Per RESEARCH A3, keep the existing cool→warm `_colorForScore` ramp OR switch to the mock's all-pink joy gradient — executor's fidelity call; if switching, use `Color.lerp(palette.joy, <lighter joy via joyLight>, t)` (NO 裸hex). The histogram receives `buckets` only today — the median is computable from buckets, so NO new provider/data path (D4/scope preserved).</action>
  <verify>
    <automated>flutter analyze lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart</automated>
  </verify>
  <done>Calendar renders a legend strip (4 lerp swatches + 淡/浓 + neutral note) + caption; histogram renders a data-derived median pill (weighted median from buckets, never literal 7) + count footer + median-bucket outline; all colors palette-derived; 0 analyze issues; no new provider introduced.</done>
</task>

<task type="auto">
  <name>Task 5: Flip structural tests, rebaseline goldens (macOS), full-suite gate</name>
  <files>test/widget/features/analytics/presentation/screens/analytics_screen_test.dart, test/widget/features/analytics/presentation/analytics_card_registry_test.dart, test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart, test/golden/*</files>
  <action>Flip the structural tests:
- `analytics_screen_test.dart` — the「renders the flat round-5 B 5-card lineup with NO section headers」test (around :173) + its :178–180 comment must change to assert section headers ARE present (`find.byType(AnalyticsSectionHeader)` finds 4) AND `JoySpendCard` is NO LONGER a top-level sibling card (`find.byType(JoySpendCard)` → `findsNothing` in the screen). The joybar now lives inside CategoryDonutCard — assert the connector/drawer presence instead (e.g. find the JoySpendStackedBar inside the donut card subtree, or a drawer key). **CRITICAL — sweep ALL JoySpendCard references in this file:** there are further `find.byType(JoySpendCard)` uses at `:221` (`ensureVisible(find.byType(JoySpendCard))`) and `:234` (`scrollUntilVisible`) — these will throw once JoySpendCard is no longer in the screen tree. Repoint them to the donut card / JoySpendStackedBar-inside-donut (or delete the now-redundant scroll step). Grep the file for `JoySpendCard` and resolve every hit, not just the :173 assertion.
- `analytics_card_registry_test.dart` — registry length 6→5 (within_month_trend, category_donut, joy_calendar, satisfaction_histogram = 4 always-visible + 1 group-only family). Update the `analyticsCardRegistry.length` expectation (6→5) and its reason text; verify the union still includes `joyCategoryAmountsProvider` (now via categoryDonut's targets) — add/adjust the union assertion so the folded joy target is covered. Update the de-registered-specs comment.
- `anti_toxicity_phase47_test.dart` — add the NEW joy-side strings (drawer connector/subtitle/caption, calendar legend note, histogram median-pill/count-footer) to the forbidden-substring sweep coverage across ja/zh/en. The existing `JoySpendCard` subject builder (line ~297) STILL WORKS (wrapper retained) — leave it; optionally add a CategoryDonutCard drawer-state case so the nested drawer copy is swept.

Then rebaseline goldens ON macOS ONLY (golden-ci-platform-gate memory — never on non-macOS): run `flutter test --update-goldens` SCOPED to the affected files for clean diff attribution: `within_month_trend_card_golden_test.dart`, `category_donut_card_golden_test.dart`, `joy_spend_card_golden_test.dart`, `joy_calendar_card_golden_test.dart`, `satisfaction_histogram_card_golden_test.dart`, `analytics_screen_scroll_smoke_golden_test.dart`, and verify `daily_vs_joy_card_golden_test.dart` (de-registered card, Pitfall-8 — should be unchanged; rebaseline ONLY if an incidental diff appears, do not touch it otherwise). Force-add any gitignored-yet-tracked generated/golden files if `git add` rejects them (Phase-46 gotcha).

Finally run the FULL gate (D6): `flutter analyze` (0 issues) + `flutter test` (entire suite, incl. architecture tests hardcoded_cjk_ui_scan, color_literal_scan, registry_test, home_screen_isolation_test, anti_toxicity_phase47). All must pass.</action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>analytics_screen_test asserts 4 section headers + JoySpendCard not a top-level card with EVERY JoySpendCard reference (incl. :221/:234 ensureVisible/scrollUntilVisible) resolved; registry_test length=5 + folded joy union covered; anti_toxicity_phase47 sweeps the new joy strings; 7 affected goldens rebaselined on macOS; `flutter analyze` 0 issues; FULL `flutter test` green (incl. hardcoded_cjk_ui_scan, color_literal_scan, home_screen_isolation_test).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| n/a (presentation-only refactor) | No new untrusted-input path: no new provider, query, DAO, network, or persistence. All data flows through existing analytics providers already filtering `TransactionType.expense` (Pitfall-5). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-lfp-01 | Information disclosure | registry / shell section-header wiring | mitigate | Section-header descriptor is provider-free (text closures + enum); registry imports zero `home/*` providers — verified by `home_screen_isolation_test` + `analytics_card_registry_test` union assertion (GUARD-01). |
| T-lfp-02 | Tampering | pull-to-refresh union after JoySpendCard de-registration | mitigate | Fold `joyCategoryAmountsProvider` into `categoryDonutRefreshTargets` so the drawer still invalidates; covered by the registry union test. |
| T-lfp-03 | Repudiation/Integrity | ADR-012 anti-gamification on new joy strings | mitigate | All new joy-side copy is ADR-012-neutral and swept by `anti_toxicity_phase47_test` (ja/zh/en); median pill is descriptive, not a target. |
| T-lfp-SC | Tampering | npm/pip/cargo installs | n/a | No package-manager installs — pure Dart presentation edit; fl_chart unchanged at ^1.2.0. |
</threat_model>

<verification>
- `flutter analyze` → 0 issues (CLAUDE.md zero-warning gate).
- `flutter gen-l10n` succeeds; new ARB keys present in all 3 ARB files + generated.
- FULL `flutter test` green, specifically: `hardcoded_cjk_ui_scan` (section titles/tags via S.of), `color_literal_scan` (only `lib/core/theme/joy_warm_palette.dart` carries hex), `analytics_card_registry_test` (5 specs + folded joy union), `home_screen_isolation_test` (registry home-free), `anti_toxicity_phase47_test` (new joy strings swept).
- 7 affected goldens rebaselined on macOS; off-macOS reduces to baseline-existence via `flutter_test_config.dart` (do NOT rebaseline off-macOS).
</verification>

<success_criteria>
- Analytics screen visually + structurally matches `r5-drawer-joybar.html`: 4 section headers, donut hero with nested joy connector+drawer, calendar with legend, histogram with median pill — all from real provider data.
- D2 reversal complete (headers back, joybar nested, JoySpendCard de-registered but file retained as wrapper).
- D3 trend internals byte-unchanged; D4 zero hardcoded mock numbers; D5 only `joy_warm_palette.dart` (in core/) carries hex; D7 all new UI text localized in ja/zh/en.
- Full suite + analyze green; goldens rebaselined on macOS per D6.
</success_criteria>

<output>
Create `.planning/quick/260620-lfp-round5-r5-drawer-joybar-html-mock/260620-lfp-SUMMARY.md` when done.
Generate a worklog under `docs/worklog/` per the project worklog rule.
</output>
