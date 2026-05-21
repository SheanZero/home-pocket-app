# Phase 14: ADR-016 Frontend + ARB Reconciliation - Research

**Phase:** 14 - ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02)  
**Researched:** 2026-05-19  
**Status:** Ready for UI-SPEC gate

## Research Objective

Answer: what does the planner need to know to plan Phase 14 well?

Phase 14 is a user-facing migration phase. Phase 13 already shipped the backend and model foundation:

- `HappinessReport.joyContribution`
- `AppSettings.monthlyJoyTarget`
- `SettingsRepository.getMonthlyJoyTarget()` / `setMonthlyJoyTarget(int?)`
- `monthlyJoyTargetRecommendationProvider`
- `GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline`
- `formatJoyCumulative`

The remaining work is presentation, i18n, tests/goldens, and the hard ADR-012/ADR-016 100% behavior contract.

## Canonical Inputs

- `.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md`
- `.planning/phases/13-adr-016-backend-foundation/13-UI-SPEC.md`
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md`
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md`
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md`
- `AGENTS.md`

## Current Implementation Baseline

### HomeHeroCard

Primary files:

- `lib/features/home/presentation/widgets/home_hero_card.dart`
- `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart`
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
- `test/golden/home_hero_card_golden_test.dart`

Current state:

- `HomeHeroCard` is a pure `StatelessWidget` with all data passed through the constructor. This is a strong pattern and should be preserved unless the UI-SPEC explicitly chooses a wrapper component.
- Single mode already reads `happiness.joyContribution`.
- Single-mode outer legend still uses `l10n.homeJoyPerYenLegend`.
- Tooltip key `_TooltipKey.joyContribution` still maps to `l10n.homeJoyPerYenTooltip`.
- `_outerSingle(MetricResult<double> r)` still computes `(data / 2.0).clamp(0.0, 1.0)`. This is the intentional Phase 13 shim and is the central Phase 14 replacement point.
- `_centerText()` still shows average satisfaction for single mode. Phase 14 must change this to cumulative Joy plus active target, with no percentage display.
- The ring title already uses `homeRingSectionTitleSingle`, whose displayed English value is "Joy Index"; however tooltip/legend body copy still describes density.
- `HappinessRingsPainter` accepts fixed `SweepGradient`s and only compares ratios and track color in `shouldRepaint`; gradient changes are not currently in the repaint equality check.

Important planner implication:

`HomeHeroCard` currently has no `monthlyJoyTarget` or recommendation input. The planner should either:

1. Keep `HomeHeroCard` pure and extend its constructor with resolved `activeMonthlyJoyTarget` / `recommendedMonthlyJoyTarget` / optional configured target display data, then update `home_screen.dart` to watch settings + recommendation providers; or
2. Introduce a thin `ConsumerWidget` wrapper that resolves providers and passes plain values into a pure presentational inner widget.

The first option is closer to the Phase 10 pattern but increases constructor width. The second option keeps testability if the inner widget remains pure and the wrapper is small.

### Home Screen Provider Orchestration

Likely file:

- `lib/features/home/presentation/screens/home_screen.dart`

Planner should inspect the current async composition before deciding where to resolve:

- `appSettingsProvider`
- `monthlyJoyTargetRecommendationProvider(bookId, currencyCode)`
- current book currency via the existing book provider path
- current month/year already used for `happinessReportProvider`

Acceptance criteria should require invalidating `appSettingsProvider` and `monthlyJoyTargetRecommendationProvider` on pull-to-refresh or target-save paths only where needed. Avoid broad refresh churn.

### AnalyticsScreen

Primary files:

- `lib/features/analytics/presentation/screens/analytics_screen.dart`
- `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart`
- `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart`
- `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart`

Current state:

- Variant delta structure is still intact: KPI mini-hero, Time group, Distribution group, Stories group.
- The deleted Joy trend section stays deleted. There is no daily Joy trend chart in live UI.
- `KpiMiniHeroStrip` still orders total spending first, Joy second.
- `JoyHeadlineKpiTile` still renders average satisfaction as primary and median/sample coverage as subline.
- ARB labels still say "Avg satisfaction" / "本月平均满足度" / "今月の平均満足度".

Phase 14 requirement tension:

- `14-CONTEXT.md` D-12 says Variant epsilon should place Joy Index as the first KPI mini-hero item.
- Current `KpiMiniHeroStrip` has total spending first.
- Planner should make this an explicit plan task and test it. Do not leave ordering implicit.

Recommended target:

- Replace or generalize `JoyHeadlineKpiTile` so it renders `HappinessReport.joyContribution` as the primary Joy Index KPI using `formatJoyCumulative`.
- Preserve average satisfaction/median/coverage as supporting information if UI-SPEC keeps them.
- Update semantics to avoid transaction details and avoid formula copy.
- Reorder `KpiMiniHeroStrip` so Joy Index is first if the UI-SPEC confirms D-12.

### Settings UI

Primary files:

- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/widgets/appearance_section.dart`
- `lib/features/settings/presentation/providers/state_settings.dart`
- `lib/features/settings/presentation/providers/repository_providers.dart`
- `lib/features/settings/domain/models/app_settings.dart`
- `lib/features/settings/domain/repositories/settings_repository.dart`
- `lib/data/repositories/settings_repository_impl.dart`
- `test/widget/features/settings/presentation/widgets/appearance_section_test.dart`
- `test/unit/data/repositories/settings_repository_impl_test.dart`

Current state:

- `SettingsScreen` receives `bookId`.
- `AppearanceSection` is the existing theme/language section.
- There is no monthly target UI.
- `AppSettings.monthlyJoyTarget` and repository persistence already exist.
- Recommendation data lives in the analytics presentation provider layer, not in settings.

Recommended target:

- Add a new settings section, likely `JoyTargetSection`, rather than overloading `AppearanceSection`.
- Place it near Appearance/Voice if the UI-SPEC chooses "personalization", or near Analytics/Data if the UI-SPEC chooses "metric configuration".
- The section should consume:
  - `AppSettings.monthlyJoyTarget`
  - `monthlyJoyTargetRecommendationProvider(bookId: bookId, currencyCode: currencyCode)`
  - current book currency
  - `SettingsRepository.setMonthlyJoyTarget(int?)`
- Input should be numeric, nullable/clearable, and validated before persistence.
- Blank state uses active target fallback semantics:
  - configured target if present
  - recommendation if `Value<int>`
  - `GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline` if recommendation is `Empty`
- Copy must show recommendation as neutral reference only. Forbidden: higher/lower, above/below, +N, arrows, red/green comparison, achievement prompts.

Planner caution:

`GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline` lives in `lib/application/analytics/`, which is an application-layer file. A settings presentation widget may import it only if the current architecture accepts presentation importing application. The cleaner plan is to expose fallback through a small provider or pass the fallback from the same provider wrapper that resolves recommendation. The planner should inspect import guard behavior before choosing.

### ARB / i18n

Primary files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_zh.arb`
- `lib/generated/app_localizations*.dart`
- `test/helpers/test_localizations.dart`

Current density/Joy-per-yen terms still present:

- `homeHappinessROI`
- `homeSoulChargeStatus`
- `homeJoyIndexTooltip`
- `homeJoyPerYenTooltip`
- `homeJoyPerYenLegend`
- `analyticsCardTitleJoyTrend`
- `analyticsCardCaptionJoyTrendGap`
- "density" / "Joy/¥" strings in all three locale files

Context D-11 says implementation names should use JoyContribution semantics while product copy displays:

- en: Joy Index
- zh: 悦己指数
- ja: ときめき指数

Planner should split ARB work carefully:

1. Rename live code references from `homeJoyPerYen*` to `homeJoyContribution*` or equivalent.
2. Remove or leave-unused obsolete density keys only if no generated/localization call sites remain.
3. Add Settings target UI keys in all three locales in the same task.
4. Run `flutter gen-l10n`.
5. Verify generated files update and are not hand-edited.

Hard grep gates:

- `rg -n "joyPerYen|homeHappinessROI" lib/ --glob '*.dart'` returns 0 in live UI code.
- `rg -n "Joy/¥|density|ROI|幸福密度|ハピネス密度|快乐ROI|幸せROI" lib/l10n/app_*.arb` returns 0 unless the planner intentionally permits an obsolete non-live key. The stronger recommendation is remove/rename the obsolete ARB keys.
- `flutter gen-l10n` succeeds without warnings.

### Tests / Goldens

Existing useful test surfaces:

- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
- `test/golden/home_hero_card_golden_test.dart`
- `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart`
- `test/widget/features/settings/presentation/widgets/appearance_section_test.dart`
- `test/unit/data/repositories/settings_repository_impl_test.dart`
- `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart`

Needed new or changed tests:

- HomeHero active target math:
  - `joyContribution=0`, target 50 -> outer ratio 0
  - `joyContribution=25`, target 50 -> outer ratio 0.5
  - `joyContribution=50`, target 50 -> outer ratio 1.0
  - `joyContribution=80`, target 50 -> outer ratio 1.0 while center shows real 80 and no `>100%`
- HomeHero monthly reset:
  - Use current-month `happinessReportProvider` data and clock-injected/current selected month boundaries if exposed at the screen/provider layer.
  - If no clock seam exists in HomeHero itself, test by constructing current-month vs next-month `HappinessReport` fixtures.
- 100% behavior contract:
  - No toast/snackbar/notification/haptic/copy/celebration animation.
  - Widget test should assert no `SnackBar`, no celebratory strings, no `>100%` text, and no explicit threshold branch artifact.
  - Haptic/notification absence may be source-level grep if no direct test hook exists.
- Ring color:
  - Unit-test the color interpolation helper if extracted.
  - Golden-test 0%, 50%, 100%, and >100% states.
- Analytics:
  - Joy KPI primary value renders `formatJoyCumulative(joyContribution)`.
  - KPI strip ordering has Joy Index first if UI-SPEC confirms D-12.
  - Density strings are absent from rendered widget text.
- Settings:
  - Blank input clears persisted target and shows recommendation/reference fallback.
  - Numeric input persists target and invalidates `appSettingsProvider`.
  - Invalid values do not persist and show localized validation copy.
  - Recommendation remains visible after user configures a value, with no delta language.

## Implementation Strategy Recommendations

### Recommended Plan Decomposition

1. **UI-SPEC before planning**  
   Phase 14 has multiple visual/copy decisions, and `.planning/config.json` has `workflow.ui_phase` and `workflow.ui_safety_gate` enabled. The plan-phase workflow should stop after research until `14-UI-SPEC.md` exists.

2. **HomeHero target data contract**  
   Decide the component boundary first. The plan should avoid interleaving provider wiring, ring math, and visual copy in one task.

3. **HomeHero rendering and tests**  
   Implement active target ratio, center text, smooth outer ring color, 100% no-event assertions, and goldens as one coherent surface.

4. **Settings target UI**  
   Build a separate section widget with direct widget tests and repository-provider overrides. Keep recommendation copy neutral.

5. **Analytics Variant epsilon**  
   Replace average-satisfaction-first KPI with Joy Index primary and verify density UI remains deleted.

6. **ARB reconciliation and generated localization**  
   Land ARB additions/renames/removals in all locales, run `flutter gen-l10n`, and grep for stale density vocabulary.

7. **Final verification sweep**  
   Run targeted widget/golden tests, `flutter gen-l10n`, `dart format .`, `flutter analyze`, and the relevant focused Flutter tests.

### Suggested File Ownership

HomeHero task files:

- `lib/features/home/presentation/widgets/home_hero_card.dart`
- `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
- `test/golden/home_hero_card_golden_test.dart`
- `test/golden/goldens/home_hero_card_*`

Settings task files:

- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/widgets/joy_target_section.dart` (new, if UI-SPEC approves)
- `lib/features/settings/presentation/providers/state_settings.dart` (only if a helper provider is needed)
- `test/widget/features/settings/presentation/widgets/joy_target_section_test.dart` (new)

Analytics task files:

- `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart`
- `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` or renamed replacement
- `lib/features/analytics/presentation/screens/analytics_screen.dart`
- `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart`
- related analytics screen/widget tests

i18n task files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_zh.arb`
- `lib/generated/app_localizations.dart`
- `lib/generated/app_localizations_en.dart`
- `lib/generated/app_localizations_ja.dart`
- `lib/generated/app_localizations_zh.dart`
- `test/helpers/test_localizations.dart`

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| HomeHero active target requires settings + recommendation async data, making existing nested `AsyncValue.when` in `home_screen.dart` unwieldy | High | Plan a small data-resolution wrapper or helper value object before visual work |
| UI-SPEC missing for a frontend phase | High | Stop plan-phase after research and run `$gsd-ui-phase 14` before PLAN.md |
| Stale density ARB keys remain in live UI | High | Add grep gates and generated-localization call-site checks |
| 100% behavior accidentally becomes celebratory via copy, animation, snackbar, or haptic | High | Source grep + widget tests for absence; keep crossing-100 logic out of callbacks |
| Settings recommendation copy becomes comparative | Medium | UI-SPEC must hard-lock ja/zh/en copy; tests grep forbidden delta strings |
| `HappinessRingsPainter.shouldRepaint` ignores gradient/color changes | Medium | Update equality if outer gradient or color is dynamic; or pass colors as comparable fields |
| Goldens become noisy due broad layout changes | Medium | Add focused 0/50/100/>100 fixtures before regenerating goldens |
| Settings UI imports application-layer constants directly and trips import guards | Medium | Prefer provider/wrapper boundary or local presentation fallback copy fed by provider result |
| Formula appears in product tooltip despite D-14 | Medium | Tooltip copy must be natural language only; formula remains in ADR/tests |

## Validation Architecture

### Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | `flutter_test` + golden testing through Flutter test runner |
| Config file | `pubspec.yaml`, `l10n.yaml`, `analysis_options.yaml` |
| Quick run command | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart test/unit/data/repositories/settings_repository_impl_test.dart` |
| Full suite command | `flutter test` |
| Generated code commands | `flutter gen-l10n`; `flutter pub run build_runner build --delete-conflicting-outputs` only if generated Riverpod/Freezed sources change |
| Static command | `flutter analyze` |

### Sampling Strategy

- After HomeHero task commits: run HomeHero widget test plus affected golden test with `--update-goldens` only when intentionally regenerating.
- After Settings task commits: run target-section widget tests and settings repository tests.
- After Analytics task commits: run `joy_headline_kpi_tile_test.dart` plus any AnalyticsScreen widget tests touched.
- After ARB changes: run `flutter gen-l10n` and grep generated call sites.
- Before verification: run `dart format .`, `flutter analyze`, and focused tests for all changed surfaces.

### Required Automated Gates

- `flutter gen-l10n`
- `flutter analyze`
- `rg -n "joyPerYen|homeHappinessROI" lib/ --glob '*.dart'` returns 0
- `rg -n "Joy/¥|density|ROI|幸福密度|ハピネス密度|快乐ROI|幸せROI" lib/l10n/app_*.arb` returns 0, or any remaining hit is documented as non-live and accepted by reviewer
- HomeHero tests assert no percentage center display and no `>100%`
- Settings tests assert recommendation remains visible after user target is configured and no delta copy appears
- Analytics KPI tests assert Joy Index primary value comes from `joyContribution`

### Manual / Visual Gates

- Review 0%, 50%, 100%, and >100% HomeHero goldens.
- Review Settings target section copy in ja/zh/en for register and non-comparative framing.
- Review Analytics KPI mini-hero ordering and density-removal copy.

## Open Questions for UI-SPEC

These should be resolved by `$gsd-ui-phase 14` before PLAN.md exists:

1. Exact HomeHero center layout: one line (`80 / 50`) vs stacked value + target caption.
2. Exact gold endpoint token/value and whether to add a named `AppColors` token.
3. Whether `KpiMiniHeroStrip` must reorder Joy Index before total spending, per D-12.
4. Settings section placement and input behavior: inline editable tile, dialog, or text field section.
5. Exact trilingual product copy for Joy Index and target recommendation.
6. Whether old ARB keys are renamed in place or removed and replaced with new JoyContribution keys.
7. Whether HomeHero should remain entirely pure or use a thin provider wrapper.

## Planning Gate Result

Phase 14 has clear frontend indicators and no `14-UI-SPEC.md` exists. The configured UI safety gate is enabled.

Recommended next step before planning:

`$gsd-ui-phase 14`

After UI-SPEC approval, rerun:

`$gsd-plan-phase 14`

## RESEARCH COMPLETE

