---
phase: 13-adr-016-backend-foundation
slug: monthly-joy-target-baseline-spike
created: 2026-05-19
deciding:
  - fallback_baseline
  - outlier_policy
  - recommendation_persistence_behavior
---

# Phase 13 Spike: Monthly Joy Target Recommendation Baseline

Formula reference: `Σ joy_contribution = Σ(soul_satisfaction * pow(amount / base, 0.88))` per ADR-016 §2, using `ptvfBaseFor('JPY') == 500.0`.

The simulation uses synthetic demo-style monthly soul transactions. No real transaction data or personal information is included.

## Scenario Table

| Scenario | Tx count | Avg amount | Avg satisfaction | Computed Σ joy_contribution | Plausibility commentary |
|----------|----------|------------|------------------|-----------------------------|-------------------------|
| Candy month | 8 | JPY 200 | 5 | 17.9 | Low-cost, modest-satisfaction month lands below the fallback; appropriate for sparse/light engagement. |
| Mid-range mixed | 10 | JPY 500 | 6 | 60.0 | Calibration anchor from D-06; represents a healthy ordinary month without forcing high volume. |
| High-density frequent buyer | 30 | JPY 300 | 7 | 134.0 | Frequent small Joy entries can exceed the fallback naturally; this should be learned from history, not used as cold-start default. |
| Low-engagement 2-tx | 2 | JPY 1,000 | 8 | 29.4 | Good but sparse month stays below the fallback; reinforces that cold-start should not target high-activity users. |
| High-amount low-frequency | 3 | JPY 5,000 | 9 | 204.8 | High spend still attenuates through alpha=0.88 but can exceed 100; this is a personalized-history case, not a fallback baseline. |

## Decision: Fallback Baseline

Fallback baseline: **50**.

The baseline 50 stays within ADR-016 / D-06 candidate range [30, 100]. It is close to the ordinary mid-range calibration scenario (60.0) while staying below it to avoid over-targeting new users with sparse history. The high-density and high-amount scenarios show that personalized recommendations can exceed 100, but those should come from the 3-month median path rather than the cold-start fallback.

Forward consumer: plan 13-06 should embed `static const int _fallbackBaseline = 50;` in `GetMonthlyJoyTargetRecommendationUseCase`.

## Decision: Outlier Policy

**None — rely on median robustness (D-07).**

No per-transaction trim is applied because ADR-013's PTVF alpha scaling already attenuates large-amount transactions. No month-level trim is applied because the recommendation uses exactly three complete past months; dropping max/min from three values is just another way to select the median while throwing away useful signal.

## Decision: Recommendation Persistence Behavior

**Always-show dual display in Settings UI: user value + recommended value, reference-only framing (D-08).**

The recommendation remains visible after a user configures `monthlyJoyTarget`; it is a neutral reference line, not a comparison or judgment. Phase 14 ARB review must scan the `monthly_joy_target` string cluster for forbidden delta language such as higher/lower-than-recommended phrasing, plus/minus deltas, arrows, and colored comparison copy.

## Source-Code Anchors

- `lib/application/analytics/get_happiness_report_use_case.dart` — `_computeJoyContribution` implements `sum += soul_satisfaction * pow(amount / base, 0.88)`.
- `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart` — `ptvfBaseFor` provides JPY 500.0, CNY 25.0, USD 5.0 bases.

## Forward Pointers

- `13-06-PLAN.md` consumes the decided baseline as `_fallbackBaseline = 50`.
- Phase 14 consumes the persistence behavior in Settings UI and must keep recommendation copy reference-only.
