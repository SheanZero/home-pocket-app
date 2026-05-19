# Phase 14: ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-19
**Phase:** 14-ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02)
**Areas discussed:** HomeHero ring structure, Gold transition curve, Analytics epsilon and ARB vocabulary

---

## HomeHero Ring Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single main ring | Single-mode HomeHero collapses into one dominant Joy progress ring with center `Σ joy_contribution`. | |
| Keep three-ring layout | Keep the current three-ring language and migrate the outer ring to target progress. | ✓ |
| Planner decides | Leave structure choice to planner. | |

**User's choice:** Keep three-ring layout. The user explicitly corrected the earlier single-ring direction: "还是要 3-ring，单人模式也是 3-ring".
**Notes:** The selected ring mapping is outer Joy target progress, middle average satisfaction, inner highlights. Center shows cumulative Joy plus target, with no percentage. Supporting information remains but should be lower hierarchy.

---

## Gold Transition Curve

| Option | Description | Selected |
|--------|-------------|----------|
| 0-100% full smooth transition | Sage green gradually warms to gold across the full progress range. | ✓ |
| 70-100% late transition | Mostly green until 70%, then gradually gold. | |
| 90-100% near-target transition | Gold appears only near target. | |

**User's choice:** 0-100% full smooth transition.
**Notes:** Beyond 100%, the outer ring freezes full gold while center still shows real cumulative Joy plus target. Color transition applies to outer ring and center main number only. Animation is ordinary value-change animation only, with no special crossing-100% trigger.

---

## Analytics Epsilon and ARB Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Joy Index / 悦己指数 / ときめき指数 | Product-facing term replacing density/Joy-per-yen. | ✓ |
| Cumulative Joy / 累计 Joy / 累積 Joy | Most literal accumulated-value wording. | |
| Joy Total / Joy 总量 / Joy 合計 | Shorter reporting-style term. | |

**User's choice:** Joy Index / 悦己指数 / ときめき指数.
**Notes:** Code and ARB keys should use JoyContribution semantics while UI displays Joy Index. Analytics KPI mini-hero first item should be Joy Index. Phase 14 should not rebuild the Joy trend chart. Tooltip/explanation copy should use natural language only and not show the formula.

---

## the agent's Discretion

- Settings target UI placement, control details, and validation copy, within Phase 13's locked neutral-reference/no-delta constraints.
- Exact gold color value and interpolation implementation.
- Exact ARB key inventory and migration mechanics.

## Deferred Ideas

- Joy trend chart and custom time windows remain for Phase 15.
- Family-mode target semantics or ring redesign remains for Phase 16 or later.
