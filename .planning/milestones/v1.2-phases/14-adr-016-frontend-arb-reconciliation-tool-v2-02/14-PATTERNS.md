# Phase 14: ADR-016 Frontend + ARB Reconciliation - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** HomeHero, Analytics KPI, Settings, ARB/localization, Phase 13 handoff
**Analogs found:** All primary implementation files have in-repo analogs or are self-modifications.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/l10n/app_en.arb`, `app_ja.arb`, `app_zh.arb` | i18n source | generated localization | existing ARB clusters for HomeHero, Analytics, Settings | exact |
| `lib/generated/app_localizations*.dart` | generated i18n | generated output | generated from ARB by `flutter gen-l10n` | exact |
| `lib/features/home/presentation/screens/home_screen.dart` | provider orchestration | Riverpod AsyncValue composition | existing nested `monthlyReportProvider` + `happinessReportProvider` wiring | exact |
| `lib/features/home/presentation/widgets/home_hero_card.dart` | pure presentation widget | constructor data in, UI out | same file Phase 10 pure-widget pattern | exact |
| `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` | custom painter | ratio/color inputs to canvas | same file dynamic ratio rendering | exact |
| `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | widget tests | fixture-driven pure widget tests | existing HomeHeroCard tests | exact |
| `test/golden/home_hero_card_golden_test.dart` | golden tests | fixed-size localized wrapper | existing HomeHeroCard golden tests | exact |
| `lib/features/settings/presentation/screens/settings_screen.dart` | screen composition | settings AsyncValue to sections | existing section insertion pattern | exact |
| `lib/features/settings/presentation/widgets/joy_target_section.dart` | new settings section | provider-free widget + callbacks | `AppearanceSection` / `VoiceSection` section rhythm | close |
| `test/widget/features/settings/presentation/widgets/joy_target_section_test.dart` | widget tests | ProviderScope overrides/dialog tests | existing settings widget tests | close |
| `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart` | widget composition | report models to KPI tiles | same file two-tile row | exact |
| `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` | KPI tile | `HappinessReport` to semantics/UI | same file average-satisfaction tile | exact |
| `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart` | widget tests | localized widget fixture | existing JoyHeadlineKpiTile tests | exact |

---

## Pattern Assignments

### HomeHero target resolution

Use `home_screen.dart` as the provider orchestration boundary. Preserve `HomeHeroCard` as a pure `StatelessWidget`.

Concrete target resolution order:

1. `AppSettings.monthlyJoyTarget` when non-null and `> 0`.
2. `monthlyJoyTargetRecommendationProvider(bookId: bookId, currencyCode: currencyCode)` when it returns `Value<int>`.
3. Phase 13 fallback baseline `GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline` when recommendation is `Empty`.

The implementation should avoid broad refresh churn. The only required additional watches in the HomeHero builder are `appSettingsProvider` and `monthlyJoyTargetRecommendationProvider(bookId, currencyCode)`.

### HomeHero presentation

`HomeHeroCard` currently owns all visual calculation helpers:

- `_outerSingle(happiness.joyContribution)` is still the Phase 13 shim `(data / 2.0).clamp(0.0, 1.0)`.
- `_centerText()` still displays average satisfaction in single mode.
- `_legendSingle()` still calls `homeJoyPerYenLegend`.
- `_TooltipKey.joyContribution` still maps to `homeJoyPerYenTooltip`.

Phase 14 should add plain constructor inputs for active target metadata, then update:

- `_outerSingle` to use `min(joyContribution / activeMonthlyJoyTarget, 1.0)`.
- Center content to show uncapped `formatJoyCumulative(joyContribution, currencyCode)` plus localized target text.
- Outer ring and center main number color from a pure interpolation helper.
- `HappinessRingsPainter.shouldRepaint` to compare dynamic gradients/colors.

### Settings section

Add `JoyTargetSection` as a new section after `VoiceSection` and before `DataManagementSection`.

Keep persistence in existing settings infrastructure:

- Read current value from `AppSettings.monthlyJoyTarget`.
- Save with `SettingsRepository.setMonthlyJoyTarget(int?)`.
- Invalidate `appSettingsProvider` after save/clear.
- Show recommendation as neutral reference; never show deltas, arrows, red/green comparison, or achievement framing.

### Analytics epsilon

`KpiMiniHeroStrip` currently renders total spending first and `JoyHeadlineKpiTile` second. Phase 14 reverses that order and updates `JoyHeadlineKpiTile` to use `HappinessReport.joyContribution` via `formatJoyCumulative`.

Keep average/median/sample coverage as secondary text only.

### ARB and generated localization

ARB edits must happen in ja/zh/en lockstep. `flutter gen-l10n` is mandatory after any ARB change.

Live code should migrate away from:

- `homeJoyPerYen*`
- `homeHappinessROI`
- density / Joy/¥ / ROI copy
- deleted trend keys `analyticsCardTitleJoyTrend` and `analyticsCardCaptionJoyTrendGap`

Final grep gates:

```bash
rg -n "joyPerYen|homeHappinessROI" lib/ --glob "*.dart"
rg -n "Joy/¥|density|ROI|幸福密度|ハピネス密度|快乐ROI|幸せROI" lib/l10n/app_*.arb
```

