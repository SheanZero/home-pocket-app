# Phase 14: ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02) - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 14 is the user-facing ADR-016 migration phase. It takes the Phase 13 backend foundation (`HappinessReport.joyContribution`, `monthlyJoyTarget`, and the recommendation provider) and makes the app visibly coherent around `Σ joy_contribution`.

**In scope:**
- HomeHeroCard single-mode ring semantics: outer ring becomes monthly Joy target progress, while the existing three-ring language is preserved.
- HomeHero color state machine: sage green `#47B88A` to gold, with 100% handled as ambient state only.
- AnalyticsScreen Variant epsilon: density/Joy-per-yen remains retired; KPI mini-hero leads with Joy Index.
- ARB reconciliation across `ja`, `zh`, and `en`: user-facing copy uses Joy Index / 悦己指数 / ときめき指数; code and ARB keys use JoyContribution semantics.
- Settings UI for `monthly_joy_target`: numeric configuration and recommendation display, constrained by Phase 13's no-delta framing.
- Golden/widget coverage for 0%, 50%, 100%, and >100% states, plus tests asserting no discrete 100% event.

**Out of scope:**
- Rebuilding a Joy trend chart or custom time-window selector; Phase 15 owns that work.
- Family-mode metric redesign; Phase 16 owns family and Soul-vs-Survival analytics expansion. Phase 14 may apply necessary copy/visual consistency only.
- Any badge, milestone, cross-period delta, public sharing, streak, or leaderboard surface.

</domain>

<decisions>
## Implementation Decisions

### HomeHero Three-Ring Structure

- **D-01: Keep three rings in single mode.** Phase 14 does not collapse HomeHero into a single dominant progress ring. Single mode continues to use the three-ring visual structure.
- **D-02: Ring semantics are locked.** In single mode:
  - outer ring = Joy target progress, computed as `min(Σ joy_contribution / active_target, 1.0)`;
  - middle ring = average satisfaction;
  - inner ring = highlights count.
- **D-03: Center display shows cumulative Joy plus target.** Center content should show the real cumulative Joy value and the active target value. It should not show a percentage.
- **D-04: Supporting information stays, but at lower hierarchy.** Average satisfaction, highlights, and Best Joy remain available as lightweight supporting information. They must not compete visually with cumulative Joy / target progress.
- **D-05: Group mode is not redesigned by this decision set.** Current group-mode three-ring semantics can remain, with only necessary copy/visual consistency updates. Do not invent family target semantics in Phase 14.

### Gold Transition Curve

- **D-06: Use a full-range smooth color transition.** Outer ring color transitions smoothly from sage green `#47B88A` to gold across 0%-100%. Do not introduce hidden 70% or 90% thresholds.
- **D-07: Beyond 100%, freeze the progress ring.** At and beyond target, the outer ring stays as a full gold ring. The center may still show the real cumulative Joy value and target value, but no `>100%` percentage is displayed.
- **D-08: Apply color transition only to outer ring and center main number.** Supporting rows, background, and icons stay neutral or keep their semantic colors. This prevents the whole card from feeling like a celebration state.
- **D-09: Use ordinary value-change animation only.** Ring sweep and center number color may naturally animate as values change, but there is no special logic when crossing 100%, and no one-off pulse/glow/haptic/toast/snackbar/copy/notification.

### Analytics Epsilon and ARB Vocabulary

- **D-10: Product-facing term is Joy Index / 悦己指数 / ときめき指数.** This term replaces density / Joy-per-yen language in user-facing HomeHero and Analytics copy.
- **D-11: Code and ARB keys use JoyContribution semantics.** Prefer key names like `homeJoyContribution*` and `analyticsJoyContribution*`, while their displayed values use Joy Index / 悦己指数 / ときめき指数. This keeps implementation names faithful to `Σ joy_contribution` without exposing formula language to users.
- **D-12: Analytics KPI mini-hero leads with Joy Index.** Variant epsilon should place Joy Index (the cumulative value) as the first KPI mini-hero item. Other metrics stay supporting; do not add a separate large Joy Index card.
- **D-13: Do not rebuild a Joy trend chart in Phase 14.** The Phase 13 deletion of daily Joy/¥ trend stays. Custom windows and any future trend redesign belong to Phase 15.
- **D-14: Tooltip/explanation copy is natural-language only.** UI tooltip text should not display the formula. Explain the concept as a monthly accumulated Joy Index / cumulative sense of Joy. Formula correctness is enforced through code/tests and canonical ADR refs, not by exposing math in the product UI.

### Settings Target UI

- **D-15: Planner discretion within Phase 13 constraints.** The user did not select Settings UI for discussion. Planner may choose placement and control details, but must preserve these locked constraints:
  - numeric input for `monthly_joy_target`;
  - blank/unconfigured state uses Phase 13 recommendation as active target;
  - user-configured value and recommendation may both be shown;
  - recommendation copy is neutral reference only, with no delta/comparison language such as higher/lower than recommended, +N, arrows, red/green comparison, or target-raising prompts;
  - all copy goes through ja/zh/en ARB in lockstep.

### the agent's Discretion

- Exact gold color value and interpolation implementation, provided the start is `#47B88A`, the final state reads gold, and 0%-100% is continuous.
- Exact center layout for "Joy value + target" and supporting metric placement, provided percentage is not shown and supporting information has lower hierarchy.
- Exact ARB key inventory, provided `JoyPerYen`, `ROI`, and density-named live UI keys are removed or replaced with JoyContribution semantics.
- Exact Settings screen section placement, input widget style, validation copy, and save behavior, subject to D-15.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — v1.2 milestone vision and accepted ADR-016 migration cost.
- `.planning/REQUIREMENTS.md` — JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06, TOOL-V2-02; cross-phase ADR and i18n constraints.
- `.planning/ROADMAP.md` — Phase 14 goal and success criteria, including ring fill, monthly reset, 100% behavior contract, Settings UI, Analytics epsilon, and ARB cleanup.
- `.planning/STATE.md` — Phase 14 current position and carried pending decision on sage-green-to-gold curve.

### Prior phase hand-off
- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md` — Phase 13 decisions and hand-off: `joyContribution`, `monthlyJoyTarget`, recommendation provider, no-delta Settings framing, and Phase 14 ownership boundaries.

### Architecture / ADR constraints
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — single Joy expression, HomeHero monthly accumulation, target semantics, and 100% ambient-only behavior.
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — superseded density metric; PTVF per-transaction formula remains retained by ADR-016.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — no badges, streaks, cross-period deltas, public sharing, leaderboards, or achievement-trigger behavior.
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — average satisfaction and highlights stay positive/unipolar support metrics.

### Source integration points
- `lib/features/home/presentation/widgets/home_hero_card.dart` — current three-ring HomeHero implementation; Phase 14 changes center display, outer ring fill math, legend/copy, and color semantics.
- `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` — existing three-ring painter; may need color interpolation or should-repaint updates for progress-based outer ring color.
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — Variant delta layout that becomes Variant epsilon.
- `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart` — likely first KPI item replacement point for Joy Index.
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `happinessReportProvider`, `monthlyJoyTargetRecommendationProvider`, and related invalidation points.
- `lib/features/settings/presentation/screens/settings_screen.dart` — Settings section insertion point for target UI.
- `lib/features/settings/domain/models/app_settings.dart` — `monthlyJoyTarget` field from Phase 13.
- `lib/features/settings/domain/repositories/settings_repository.dart` and `lib/data/repositories/settings_repository_impl.dart` — persistence API and SharedPreferences implementation from Phase 13.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` — ARB reconciliation target files.
- `lib/generated/app_localizations*.dart` — generated outputs after `flutter gen-l10n`; do not hand-edit.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `HomeHeroCard` already has three-ring composition, legend rows, Best Joy strip, and single/group mode branching. Phase 14 should evolve this component rather than replacing it wholesale.
- `HappinessRingsPainter` already renders three concentric rings from caller-provided ratios and gradients. It can support the locked structure if the caller computes outer progress from `joyContribution / active_target`.
- `monthlyJoyTargetRecommendationProvider` already exists in `state_happiness.dart`; Settings and HomeHero can consume it instead of reimplementing recommendation logic.
- `formatJoyCumulative` already replaced the density formatter in Phase 13. Use it for displayed Joy Index values unless planner finds a better existing formatter pattern.
- Existing ARB files still contain density/Joy-per-yen vocabulary, including `homeHappinessROI`, `homeJoyPerYenTooltip`, `homeJoyPerYenLegend`, and `analyticsCardTitleJoyTrend`. These are Phase 14 cleanup targets.

### Established Patterns

- User-facing text must go through `S.of(context)` and ja/zh/en ARB parity.
- Lower layers should not import presentation providers. UI surfaces consume application/domain providers through existing Riverpod pattern.
- Settings persistence is SharedPreferences-backed through `AppSettings` and `SettingsRepositoryImpl`; do not introduce a Drift table for this setting.
- AnalyticsScreen uses sectioned cards and per-card `AsyncValue.when` handling; Variant epsilon should preserve fault isolation.
- HomeHero single mode and group mode share a widget; planner should keep group changes scoped unless directly required for copy parity.

### Integration Points

- HomeHero needs access to the active target: configured `AppSettings.monthlyJoyTarget` when present, otherwise the recommendation provider value; if recommendation is Empty, use Phase 13 fallback semantics.
- HomeHero outer ring uses capped progress; center display uses uncapped real cumulative Joy value.
- Refresh/invalidation should include recommendation/settings providers only where needed; do not create broad refresh churn.
- Analytics KPI mini-hero first item should read `HappinessReport.joyContribution` and display Joy Index product copy.
- ARB cleanup must be verified by grep tests or architecture tests so density/Joy-per-yen terms do not remain in live UI code.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly reversed the initial single-ring direction: **single mode must still be three-ring**.
- The center should read as "current cumulative Joy plus target", not as a score percentage.
- The color transition should feel like continuous ambient progress, not a milestone trigger.
- UI vocabulary should feel product-like: Joy Index / 悦己指数 / ときめき指数.
- Implementation names should remain mathematically honest: JoyContribution, not JoyPerYen, ROI, or density.
- Formula text is intentionally not shown in UI; correctness belongs in ADRs, code, and tests.

</specifics>

<deferred>
## Deferred Ideas

- Joy trend chart / custom time windows — Phase 15.
- Family-mode Joy target semantics or family ring redesign — Phase 16 or later.
- Any target history, target auto-adjustment, achievement prompt, or cross-period delta — out of v1.2 scope and blocked by ADR-012 / ADR-016 unless a future ADR explicitly changes the rule.

</deferred>

---

*Phase: 14-ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02)*
*Context gathered: 2026-05-19*
