---
phase: quick-260620-lfp
plan: 01
subsystem: analytics-presentation
tags: [analytics, presentation, redesign, i18n, golden, adr-012, adr-019]
requires:
  - joyCategoryAmountsProvider (analytics)
  - monthlyReportProvider (analytics)
  - perDayJoyCountsProvider (analytics)
  - satisfactionDistributionProvider / happinessReportProvider (analytics)
provides:
  - AnalyticsSectionHeader (reusable 3px-bar + title + tag-chip section header)
  - JoyWarmPalette (j1–j7 joybar warm palette)
  - JoySpendDrawerBody / JoySpendDrawer (shared + nested joy drawer)
  - sectioned analytics screen (4 section headers, joybar nested in donut)
affects:
  - analytics_screen.dart shell render order
  - analytics_card_registry.dart (6→5 specs)
tech-stack:
  added: []
  patterns: [provider-free section-header descriptor, folded refresh target, shared-body extraction]
key-files:
  created:
    - lib/core/theme/joy_warm_palette.dart
    - lib/features/analytics/presentation/widgets/analytics_section_header.dart
    - lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart
    - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
  modified:
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/analytics/presentation/analytics_card_registry.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
    - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
    - lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
    - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - lib/l10n/app_ja.arb, app_zh.arb, app_en.arb (+ generated)
decisions:
  - "j1–j7 warm palette placed in lib/core/theme/ (only sanctioned 裸hex location, color_literal_scan exempt)"
  - "joyCategoryAmountsProvider folded into categoryDonutRefreshTargets so the nested drawer keeps refreshing (Pitfall-3 / GUARD-01)"
  - "JoySpendDrawer extracted to its own file to keep category_donut_card under the REDES-01 400-LOC cap"
  - "trend card title suppressed via AnalyticsDataCard.showHeader:false (D3 chart internals untouched)"
metrics:
  duration: ~17m
  completed: 2026-06-20
---

# Quick Task 260620-lfp: round5 r5 drawer-joybar analytics rebuild Summary

Rebuilt the analytics 支出侧 screen to match `round5/r5-drawer-joybar.html` — 4 section headers restored (reversing Phase-46 D-F2), the 悦己 joybar nested inside the donut hero behind a pink connector+drawer, calendar legend + data-derived histogram median pill — all from real providers, with strict ADR-012 / ADR-019 / i18n compliance. Pure presentation refactor: no provider/domain/repository data contract changed.

## Tasks Completed (5/5)

| Task | Name | Commit |
|------|------|--------|
| 1 | Joy-warm palette + section-header widget + joybar recolor + ARB | `8cee0dbd` |
| 2 | Nest joybar drawer into CategoryDonutCard + fold refresh + thin wrapper | `971adf09` |
| 3 | Wire 4 section headers into registry + shell (D-F2 reversal) | `ca78e669` |
| 4 | Calendar legend + caption; histogram median pill + footer + outline | `9ed170ac` |
| 5 | Flip structural tests + extract JoySpendDrawer + rebaseline goldens | `adb7fa8a` |
| — | Worklog | `7722b753` |

## What Was Built

- **`JoyWarmPalette`** (core/theme) — j1–j7 warm bar palette + `colorAt(index)` wrapping; the joybar segments now use it (replaces the joy→joyLight lerp). Bare-hex carve-out legal here (color_literal_scan only scans features/application/shared).
- **`AnalyticsSectionHeader`** — reusable 3px bar + 12px/w600 title + tag chip; practical (green/dailyText·dailyLight) vs joy (sakura/joyText·joyLight); title/tag passed pre-localized (zero CJK literal).
- **`JoySpendDrawerBody`** — shared count-up header + joybar + single-column legend, rendered by both the standalone `JoySpendCard` wrapper and the nested drawer.
- **`JoySpendDrawer`** — connector chip (dashed stem + pink pill) + pink-bordered drawer (data-derived ¥ total + N 类 + neutral subtitle/caption) nested inside `CategoryDonutCard`'s hero.
- **Registry/shell** — `AnalyticsCardSpec.sectionHeader` provider-free descriptor (text closures + tone enum); registry 6→5 specs (JoySpend de-registered); shell renders headers with mock 26/10 spacing; `_refresh` untouched (headers carry no providers; donut targets fold in the joy provider).
- **Calendar** — `.cal-legend` strip (淡 + 4 lerp swatches + 浓 + neutral note); continuous depth mapping kept (ADR-012-safe).
- **Histogram** — `histo-foot` (count footer from `total` + weighted-median pill DERIVED from buckets, never literal 7) + median-bucket outline.

## Verification

- `flutter analyze` → **0 issues** (full project).
- `flutter test` (full suite) → **3072 passed**, including architecture tests `hardcoded_cjk_ui_scan`, `color_literal_scan`, `analytics_card_registry_test` (5 specs + folded joy union), `home_screen_isolation_test`, `anti_toxicity_phase47_test` (new joy strings swept).
- 34 affected golden masters rebaselined on macOS (trend / donut / joy_spend / calendar / histogram / scroll-smoke); `daily_vs_joy_card` golden untouched (Pitfall-8).

## Decision Compliance

- **D2** 4 section headers back + joybar nested in donut + JoySpendCard de-registered (file retained as wrapper). ✓
- **D3** `within_month_trend_card` / `within_month_cumulative_line_chart` internals byte-unchanged — only `showHeader:false` on the wrapper. ✓
- **D4** zero mock numbers hardcoded; histogram median weighted from buckets; drawer ¥ total + N 类 from provider. ✓
- **D5** only `joy_warm_palette.dart` (in core/) carries hex; all other chrome via `context.palette` / `Color.lerp`. ✓
- **D7** 4 section titles + 实用/悦己 tags + drawer/calendar/histogram copy in ja/zh/en + gen-l10n. ✓
- **D6** affected goldens rebaselined on macOS; full suite green. ✓

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] REDES-01 LOC cap forced JoySpendDrawer extraction**
- **Found during:** Task 5 (registry structure test).
- **Issue:** Nesting `_JoyDrawer` + `_JoyConnector` into `category_donut_card.dart` (Task 2) pushed it to 578 LOC, tripping the REDES-01 `< 400 LOC` per-card gate.
- **Fix:** Extracted both into `lib/features/analytics/presentation/widgets/joy_spend_drawer.dart` (public `JoySpendDrawer`); card fell to 372 LOC.
- **Commit:** `adb7fa8a`

**2. [Rule 1 - Bug] Forbidden anti-toxicity substrings in new copy**
- **Found during:** Task 5 (anti_toxicity_phase47 sweep).
- **Issue:** en drawer caption「no comparison with the past」+ subtitle「no ranking」and ja caption「比較」tripped the locked forbidden-substring lists.
- **Fix:** Reworded to「never weighed against the past」/「nothing placed above another」/「過去と引き比べることもありません」— semantics preserved, ADR-012-neutral.
- **Commit:** `adb7fa8a`

## Known Stubs

None — all displayed numbers are provider-derived; the median pill, drawer total, and category count are all computed from live data.

## Threat Flags

None — pure presentation refactor; no new endpoint, query, DAO, provider, or trust-boundary surface (all data flows through existing analytics providers already filtering `TransactionType.expense`).

## Self-Check: PASSED

- Created files exist: joy_warm_palette.dart, analytics_section_header.dart, joy_spend_drawer_body.dart, joy_spend_drawer.dart — all FOUND.
- Commits exist: 8cee0dbd, 971adf09, ca78e669, 9ed170ac, adb7fa8a, 7722b753 — all FOUND in git log.
- `flutter analyze` 0 issues; `flutter test` 3072 passed.
