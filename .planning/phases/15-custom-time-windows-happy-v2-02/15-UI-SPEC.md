---
phase: 15
slug: custom-time-windows-happy-v2-02
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-19
---

# Phase 15 — UI Design Contract

> Visual and interaction contract for the AnalyticsScreen custom-time-window selector (HAPPY-V2-02). Pre-populated from `15-CONTEXT.md`, `15-RESEARCH.md`, and the project's existing design tokens (`lib/core/theme/app_colors.dart`, `lib/core/theme/app_text_styles.dart`). Verified by gsd-ui-checker.

This phase is a **brownfield extension**, not a new design system. It replaces one widget (`MonthChipPicker`) with a richer selector + bottom sheet under the same Wa-Modern visual contract. New surfaces inherit the existing Variant ε AnalyticsScreen scaffolding — no theme tokens, fonts, or color rules change.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Flutter — no shadcn) |
| Preset | not applicable |
| Component library | Flutter Material 3 (`Material 3 + custom Wa-Modern theme`) — `lib/core/theme/app_theme.dart` |
| Icon library | Material Icons (Flutter SDK bundled) — no third-party icon pack |
| Font | `Outfit` (primary, for labels/headlines/amounts), `DM Sans` (nav-only, not used in this phase) |

**Why no shadcn:** project is Flutter, not React/Next.js/Vite. shadcn gate is not applicable. The equivalent design-system role is filled by `AppColors` + `AppTextStyles` + `AppThemeColors` (light/dark token sets). Source: `lib/core/theme/`.

---

## Spacing Scale

Declared values (verified multiples of 4 in `lib/features/analytics/presentation/screens/analytics_screen.dart`):

| Token | Value | Usage in Phase 15 |
|-------|-------|-------------------|
| xs | 4px | Chip internal vertical padding; gap between chip label and dropdown caret |
| sm | 8px | Bottom-sheet row internal padding; gap between type-row chips |
| md | 16px | Bottom-sheet horizontal padding; chip horizontal padding (matches existing `MonthChipPicker` line 52); spacing between type-row and list body |
| lg | 24px | Vertical padding above/below bottom-sheet content; padding around invalid-range error message |
| xl | 32px | Spacing between major sections inside the bottom sheet (header / type row / list body) |

**Exceptions:**
- **Touch targets:** chip `minWidth: 44, minHeight: 44` (matches existing pattern at `month_chip_picker.dart:44`). 44px is iOS HIG / Material accessibility floor and is intentionally not a 4-multiple of the spacing scale — it's a hit-area constraint, not visual whitespace.
- **Pill corner radius:** `999` (fully rounded). Matches existing `MonthChipPicker:49`. Not a spacing token — geometric radius.

---

## Typography

All values from `lib/core/theme/app_text_styles.dart`. Phase 15 introduces **zero** new type styles. The table below lists only the styles consumed by the time-window chip and bottom sheet.

| Role | Token | Size | Weight | Color |
|------|-------|------|--------|-------|
| Chip label (active window) | `AppTextStyles.bodyMedium` | 14 | w500 | `context.wmTextPrimary` |
| Chip dropdown caret (▼) | `AppTextStyles.caption` | 12 | w500 | `context.wmTextSecondary` |
| Bottom-sheet section header (e.g., "Window type", "Pick a week") | `AppTextStyles.titleSmall` | 14 | w600 | `context.wmTextPrimary` |
| Bottom-sheet list row (e.g., "May 2026", "Q2 2026") | `AppTextStyles.bodyMedium` | 14 | w500 | `context.wmTextPrimary` |
| Bottom-sheet selected list row | `AppTextStyles.bodyMedium` | 14 | **w600 (override via `copyWith`)** | `AppColors.accentPrimary` (coral) |
| Invalid-range error copy (SnackBar) | `AppTextStyles.bodyMedium` | 14 | w500 | `context.wmTextPrimary` |
| Type-row chip text (W / M / Q / Y / Custom) | `AppTextStyles.titleSmall` | 14 | w600 | `context.wmTextPrimary` (inactive) / `Colors.white` (active) |

**Line height:** Outfit default per token (most are unset; `headlineLarge` and `amountLarge` use `height: 0.9`). No body line-height override required for this phase.

**No tabular-figures override needed** — dates are not numeric columns. The selector does not render amounts.

---

## Color

Project palette is "Wa-Modern" (warm ivory + coral accent + ledger color codes). Verified in `lib/core/theme/app_colors.dart`. Phase 15 introduces **zero** new colors.

| Role | Value | Usage in Phase 15 |
|------|-------|-------------------|
| Dominant (60%) | `#FCFBF9` (warm ivory `AppColors.background`) | Bottom-sheet background, page background under chip |
| Secondary (30%) | `#FFFFFF` (`AppColors.card`) | Chip surface, list-row hover surface, bottom-sheet card body |
| Accent (10%) | `#E85A4F` (coral `AppColors.accentPrimary`) | Selected list row text, active type-row chip background; system date-range picker primary (auto via `Theme.of(context).colorScheme.primary`, seeded from `accentPrimary` per `app_theme.dart:8`) |
| Destructive | not used in this phase | n/a — Phase 15 has no destructive actions |
| Soul ledger (do NOT use) | `#47B88A` | **Forbidden in this phase.** Soul green is reserved for HomeHero ring + Soul ledger entries. The window selector is screen-chrome and must remain neutral coral. |
| Survival ledger (do NOT use) | `#5A9CC8` | **Forbidden in this phase.** Survival blue is ledger-specific. |
| Olive (trends) (do NOT use) | `#8A9178` | **Forbidden in this phase.** Olive belongs to the six-month trend bars; the selector does not bleed into trend semantics. |

**Accent reserved for:**
1. Selected list-row text in the bottom-sheet body (W/M/Q/Y list).
2. Active type-row pill background in the bottom-sheet header (when user has picked Week vs. Month vs. Quarter etc.).
3. Material `showDateRangePicker` primary color — auto-derived from the seed; no manual override.

**Accent NOT for:**
- The chip surface itself (must remain white card with subtle border, matching the existing `MonthChipPicker` line 46-50 contract).
- The dropdown caret (stays muted secondary).
- Section headers inside the bottom sheet.
- Invalid-range SnackBar (uses default theme SnackBar surface — no destructive red since the failure is validation, not danger).

**Borders:**
- Chip border: `context.wmBorderDefault` → light: `#EFEFEF`; dark: `#353845`.
- Bottom-sheet list-row dividers: rely on Material `ListTile` default (`InkWell` ripple, no explicit border).

**Dark mode:** `AppColorsDark` token set already exists. Phase 15 reads all colors through `context.wm*` extension helpers (`AppThemeColors`), so dark-mode parity is structural — no separate token decisions.

---

## Copywriting Contract

All copy goes through ARB (`lib/l10n/app_{en,ja,zh}.arb`). ja/zh/en parity is non-negotiable per cross-phase constraint #6. Locked CTA verbs/nouns below are the **en authority**; ja/zh translations are planner discretion subject to parity-check tooling.

| Element | Copy (en) | Copy (ja) | Copy (zh) | Notes |
|---------|-----------|-----------|-----------|-------|
| Chip tooltip (rename of `analyticsMonthChipPickerTooltip`) | "Pick a time window" | "期間を選ぶ" | "选择时间范围" | New ARB key: `analyticsTimeWindowChipTooltip`. Replaces the now-misleading "Pick a month" / "月を選ぶ" / "选择月份". |
| Chip label — Week | "Week of {monday, e.g., May 13}" | "{monday}の週" | "{monday}的一周" | Date-anchored per Research §Pitfall 4 + Open Question 3 (resolves Assumption A1). The `{monday}` placeholder is rendered via `FormatterService.formatShortMonthDay` for locale parity. New ARB key: `analyticsTimeWindowChipLabelWeek`. |
| Chip label — Month | "{month} {year}" (e.g., "May 2026") | "{year}年{month}月" | "{year}年{month}月" | Reuse existing `FormatterService.formatMonthYear` — no new ARB key needed for the label format itself (the formatter handles locale switching). |
| Chip label — Quarter | "Q{q} {year}" (e.g., "Q2 2026") | "{year}年 第{q}四半期" | "{year}年 第{q}季度" | New ARB key: `analyticsTimeWindowChipLabelQuarter`. `intl` `QQQ` skeleton produces awkward ja/zh in CLDR — use plain placeholders. |
| Chip label — Year | "{year}" | "{year}年" | "{year}年" | New ARB key: `analyticsTimeWindowChipLabelYear`. |
| Chip label — Custom | "{start} – {end}" (en-dash) | "{start} 〜 {end}" | "{start} 至 {end}" | Each side rendered via `FormatterService.formatShortMonthDay`. New ARB key: `analyticsTimeWindowChipLabelCustom`. |
| Bottom-sheet title | "Time window" | "期間" | "时间范围" | New ARB key: `analyticsTimeWindowSheetTitle`. |
| Type-row chip — Week | "Week" | "週" | "周" | New ARB key: `analyticsTimeWindowTypeWeek`. |
| Type-row chip — Month | "Month" | "月" | "月" | New ARB key: `analyticsTimeWindowTypeMonth`. |
| Type-row chip — Quarter | "Quarter" | "四半期" | "季度" | New ARB key: `analyticsTimeWindowTypeQuarter`. |
| Type-row chip — Year | "Year" | "年" | "年" | New ARB key: `analyticsTimeWindowTypeYear`. |
| Type-row chip — Custom | "Custom" | "カスタム" | "自定义" | New ARB key: `analyticsTimeWindowTypeCustom`. |
| Custom-row affordance ("tap to pick range") | "Pick a date range" | "日付範囲を選ぶ" | "选择日期范围" | New ARB key: `analyticsTimeWindowCustomCta`. Opens system `showDateRangePicker`. |
| **Invalid-range error (>12 months)** | "Range cannot exceed 12 months. Pick a shorter range." | "期間は12ヶ月を超えられません。短い期間を選んでください。" | "时间范围不能超过 12 个月。请选择较短的范围。" | New ARB key: `analyticsTimeWindowErrorTooLong`. SnackBar; planner discretion on dialog vs SnackBar (Recommendation: SnackBar with "OK" action that reopens the sheet per Research Open Q5). |
| **Invalid-range error (start > end)** | "Start date must be before end date." | "開始日は終了日より前にしてください。" | "开始日期必须早于结束日期。" | New ARB key: `analyticsTimeWindowErrorInverted`. Same SnackBar surface as `ErrorTooLong`. |
| **Invalid-range error (end in future)** | "End date cannot be in the future." | "終了日に未来の日付は選べません。" | "结束日期不能晚于今天。" | New ARB key: `analyticsTimeWindowErrorFutureEnd`. Same surface. |
| Empty preset list (no transactions for this granularity) | "No data yet for this view. Add a transaction to begin." | "このビュー用のデータがありません。取引を追加してください。" | "此视图暂无数据。请先添加一笔交易。" | New ARB key: `analyticsTimeWindowEmptyPreset`. **Only reached** if `earliestTransactionMonthProvider` returns null AND the user opens Week/Quarter/Year list. Most users will not see this since AnalyticsScreen itself gates on having any data. |
| KPI tile total label (RENAME) | "Total spending" (was "This month's spending") | "支出合計" (was "今月の支出") | "支出合计" (was "本月支出") | Existing ARB key `analyticsKpiTotalLabel` — generalize per Research Pitfall #6. |
| KPI total delta (MoM) — see `analyticsKpiTotalDeltaIncreased/Decreased` | **Subject to planner re-examination** per Research §Validation row SC-5 | — | — | These keys reference month-over-month. Phase 15 may or may not retire them depending on planner decision on `MonthlyReport.year/month` semantics (Research Pitfall #1 + Open Question 1). If retired, drop from ARB ja/zh/en in lockstep. |

**Primary CTA (this phase):** The active "CTA" is the **chip tap** itself — opens the bottom sheet. Phase 15 has no destructive actions, no save-form, no irreversible operation. The bottom sheet's "apply" is implicit (D-04 immediate-apply); list-row tap = commit.

**Empty state:** Mostly inherited from the existing AnalyticsScreen's per-card empty states (unchanged). The only new empty state is `analyticsTimeWindowEmptyPreset` for the unlikely case of an empty preset list inside the sheet.

**Error state:** Three validation errors (see table). All localized. No system error toString leaks. All surface via SnackBar (recommended) — never as a dialog (would over-dramatize a recoverable validation failure).

**Destructive actions:** None.

**Forbidden copy patterns (cross-phase constraint enforcement):**
- ❌ "vs last quarter", "vs last week", "compared to", "delta", "change" — ADR-012 §4 cross-period delta forbidden.
- ❌ "Best week ever!", "New record!", "Streak!" — ADR-012 §2 + §5 anti-gamification.
- ❌ "Family ranking", "Top spender" — ADR-012 §6 anti-leaderboard.
- ❌ Hardcoded month names like `"May 2026"` in Dart string literals — every date string must go through `FormatterService` (which delegates to `DateFormatter`) per CLAUDE.md i18n rule.

---

## Interaction Contract

> Phase 15 introduces non-trivial new interactions (bottom sheet, type-row navigation, system date-range picker). Spelled out below so the executor has zero ambiguity.

### Chip tap

1. User taps the time-window chip in `AnalyticsScreen` AppBar `actions`.
2. `showModalBottomSheet<TimeWindow>` opens (matches existing `MonthChipPicker:91` pattern).
3. Sheet shows: **Type row** (top, horizontal scroll if needed: W / M / Q / Y / Custom) → **Body** (list for W/M/Q/Y, or "Pick a date range" affordance for Custom).
4. Initial type-row selection reflects the current `TimeWindow` variant.
5. Initial body list scrolls to show the currently selected item highlighted in accent coral.

### Type-row toggle

1. User taps a different type chip (e.g., Month → Quarter).
2. The body re-renders to the new type's chooser.
3. **No commit yet.** Type selection is preview only until the user picks a body row.

### List-row tap (Week / Month / Quarter / Year body)

1. User taps a row in the body (e.g., "Q2 2026").
2. `selectedTimeWindowProvider.notifier.setWindow(window)` invoked immediately (D-04).
3. `Navigator.of(sheetContext).pop()` closes the sheet.
4. AnalyticsScreen re-renders with the new window; cards re-query.

### Custom-range tap

1. User taps "Pick a date range" affordance in the body when Custom is the active type.
2. `showDateRangePicker` (Material) opens — uses `GlobalMaterialLocalizations` for ja/zh/en (already wired in `main.dart:154`).
3. `firstDate` = `earliestTransactionDate` (from `earliestTransactionMonthProvider`, broadened to date precision) or arbitrary fallback (`DateTime(2000, 1, 1)`).
4. `lastDate` = `DateTime.now()` (D-07 — no future dates).
5. User picks start + end and confirms.
6. **Validation** runs:
   - If `start > end` → SnackBar with `analyticsTimeWindowErrorInverted` copy; sheet stays open or reopens.
   - If `(end - start) > 12 months` (calendar-month math per Research Pitfall #5) → SnackBar with `analyticsTimeWindowErrorTooLong`.
   - If `end > today` → SnackBar with `analyticsTimeWindowErrorFutureEnd`. (Defensive — system picker should prevent this, but defense-in-depth per D-08.)
7. If valid: `selectedTimeWindowProvider.notifier.setWindow(TimeWindow.custom(start, end))`; close sheet.

### Backdrop tap / system back gesture

1. Dismisses the sheet without committing.
2. Active window unchanged.
3. No SnackBar.

### Pull-to-refresh on AnalyticsScreen

1. Invalidates **windowed** providers only (`monthlyReportProvider`, `happinessReportProvider`, `satisfactionDistributionProvider`, `bestJoyMomentProvider`, `largestMonthlyExpenseProvider`, `familyHappinessProvider`, plus `expenseTrendProvider(anchor)` where anchor = month containing `window.endDate`).
2. **Must NOT** invalidate any HomeHero / Home tab provider (locked by Research Pitfall #3 + success criterion SC-3 widget test).

### Accessibility

- Chip tooltip (`Tooltip` widget) surfaces `analyticsTimeWindowChipTooltip` for screen readers.
- All type-row chips and list rows reachable via Material's default keyboard/screen-reader semantics.
- Touch targets ≥44pt (chip: `minWidth: 44, minHeight: 44`; list rows: Material `ListTile` default ≥48dp).
- Selected list row uses both color contrast AND the `selected: true` Material semantic flag.

---

## Component Inventory (added / modified in Phase 15)

| Component | Path (planner discretion on exact filename) | Layer | New or Modified |
|-----------|----------------------------------------------|-------|-----------------|
| `TimeWindowChip` (replaces `MonthChipPicker`) | `lib/features/analytics/presentation/widgets/time_window_chip.dart` | Presentation widget | **New** (replaces existing widget) |
| `TimeWindowPickerSheet` | `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` | Presentation widget | **New** |
| `TimeWindowTypeRow` (internal to sheet) | (same file as sheet) | Private widget | **New** |
| `TimeWindow` (Freezed sealed) | `lib/features/analytics/domain/models/time_window.dart` | Domain model | **New** |
| `AnalyticsScreen` AppBar trailing action | `lib/features/analytics/presentation/screens/analytics_screen.dart:62` | Presentation screen | **Modified** — swap `MonthChipPicker` for `TimeWindowChip` |
| `_refresh` invalidation list | same file, lines ~150-188 | Presentation logic | **Modified** — re-key invalidations |
| `analyticsKpiTotalLabel` ARB copy | `lib/l10n/app_{en,ja,zh}.arb` | i18n | **Modified** — generalize from "This month's spending" → "Total spending" (et al.) |
| 12 new ARB keys (see Copywriting table) | same | i18n | **New** |

**Components explicitly NOT touched in this phase** (locked by D-12 and Research §HomeHero isolation):
- `HomeHeroCard` and any `lib/features/home/` widget.
- `MonthlySpendTrendBarChart` (D-10 — stays month-anchored).
- Any settings, recoverkit, or transaction-entry UI.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none (project is Flutter) | not applicable |
| third-party | none | not applicable |
| Flutter SDK Material | `showModalBottomSheet`, `showDateRangePicker`, `ListTile`, `Tooltip`, `InkWell`, `Material` `AppBar` actions | not required — SDK built-ins |
| pub.dev packages | **zero new packages** (per Research §Package Legitimacy Audit) | not applicable |

**Verification:** Phase 15 introduces no external UI dependencies. All visual primitives come from Flutter SDK Material + the existing `lib/core/theme/` tokens. No npm `npx shadcn view` gate, no slopcheck — Flutter doesn't have a registry equivalent and no new packages are added.

---

## Cross-Phase Constraint Mapping

Visual/UX implications of each constraint that applies to this phase:

| Constraint | Visual/Interaction Impact |
|------------|---------------------------|
| ADR-012 §4 (no cross-period delta) | No "vs last month/quarter" overlays, no delta arrows in chip copy, no comparison badges. Widget test asserts `find.byKey(Key('crossPeriodDelta'))` returns `findsNothing` after re-render. |
| ADR-012 §2/§5 (no gamification) | No celebration animations, achievement toasts, or streak displays in or around the selector. The selector is purely functional chrome. |
| ADR-012 §6 (no family leaderboard) | Type-row, list-rows, and any new ARB copy must not introduce per-member labels. FamilyInsightCard follows the window but remains aggregate-only (D-11). |
| ADR-014 (unipolar satisfaction) | No new bipolar color cues. Selected accent stays coral (not red/green). |
| ADR-016 §3 (HomeHero monthly ring) | Selector chrome and copy must not visually imply HomeHero responds to the selector. Tooltip copy ("Pick a time window") makes the scope clear — it's for AnalyticsScreen, not HomeHero. |
| i18n parity (ja/zh/en) | Every new ARB key shipped in all three locales in the same commit. `flutter gen-l10n` must succeed without warnings. No locale-conditional Dart `if` branches for copy. |

---

## Open Decisions for Planner

The following are surfaced from Research §Open Questions and need a locked answer in `15-PLAN.md` before executor work begins. They are listed here because they affect copy or visual contract — gsd-ui-checker will block if any remain unresolved at the spec-approval stage.

1. **`MonthlyReport.year/month` for non-month windows** (Research Pitfall #1, Open Q1): Option A (display-anchor convention) or Option B (parallel `WindowReport` types). **Impact on this spec:** if Option A, KPI label may keep month-context wording; if Option B, generic "Total spending" wording must propagate to every consuming card.
2. **`analyticsKpiTotalDeltaIncreased/Decreased` ARB keys** (MoM delta): retire vs. keep gated by window type? Cross-period delta is forbidden by ADR-012 §4 — these may already be a latent violation since they show "↑ +X% MoM" on the current AnalyticsScreen. Planner should decide: keep (and justify as "scalar, not surface comparison") or drop. **Default recommendation:** drop in this phase to align with ADR-012 §4 unambiguously.
3. **Week label format — date-anchored vs. numeric** (Research Open Q3): this spec locks **date-anchored** ("Week of May 13") per A1. If planner overrides to numeric ("Week 20, 2026"), ARB keys `analyticsTimeWindowChipLabelWeek` must change accordingly and `intl` ISO-week-numbering caveat (Pitfall #4) must be resolved.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS — every user-facing string has an ARB key (or reuses existing); ja/zh/en columns filled; error copy is recoverable, not destructive; forbidden patterns listed in §Copywriting Contract.
- [ ] Dimension 2 Visuals: PASS — bottom-sheet layout follows Material conventions; chip matches existing `MonthChipPicker` decoration contract; touch targets ≥44pt; pill radius 999 consistent.
- [ ] Dimension 3 Color: PASS — palette 60/30/10 from existing `AppColors`; accent coral reserved-for list is explicit; ledger colors (soul green, survival blue, olive) explicitly forbidden in this surface.
- [ ] Dimension 4 Typography: PASS — only 4 distinct styles consumed (`bodyMedium`, `caption`, `titleSmall`, `titleSmall+w600`), all from `AppTextStyles`; zero new type tokens; tabular-figures correctly not applied (no amount columns in this surface).
- [ ] Dimension 5 Spacing: PASS — every spacing value is multiple of 4 except the 44pt touch-target floor (documented exception); inherits the project's existing 4/8/16/24/32 cadence.
- [ ] Dimension 6 Registry Safety: PASS — zero new dependencies (verified by Research §Package Legitimacy Audit); shadcn N/A for Flutter; no third-party UI block introduced.

**Approval:** pending
