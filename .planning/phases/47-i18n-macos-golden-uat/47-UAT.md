# Phase 47 — D-10 On-Device Visual UAT Checklist (GUARD-05)

**Status:** ⏳ AWAITING ON-DEVICE VERIFICATION (blocking-human checkpoint)
**Plan:** 47-06 (Task 2)
**Surface:** Phase 46 round-5 B redesigned analytics page (5 always-visible cards + group-only family_insight), with Phase 47 WR fixes (WR-01 JPY-only honesty / WR-02 donut Other-slice reconciliation / WR-04 calendar refresh consistency), trilingual ARB cleaned, anti-toxicity-swept, macOS-golden-baselined.
**Pre-gate (automated, GREEN):** full `flutter test` 3057/3057 · `flutter analyze` 0 issues · cleaned line coverage 80.48% · `lib/generated/` clean.

---

## How to run

Run the app on a **PHYSICAL iOS device** with device locale = **ja** (the app default — real font/render/gesture fidelity; an iOS simulator is a weaker substitute). zh/en spot-check. Open the statistics/analytics tab and walk each item below, recording per-item pass/fail.

> **BLOCKING (D-12):** any failed item must be fixed (a new gap-closure plan) and re-verified before v1.8 closeout. There is **NO** acknowledged-deferred path for this UAT.

---

## D-10 Checklist

| # | Item | Locale focus | Result | Notes |
|---|------|--------------|--------|-------|
| 1 | All 5 always-visible cards render (within-month trend / category donut / joy-spend / joy-calendar / satisfaction histogram). | ja | ⏳ | |
| 2 | Count-up animates at BOTH anchors: donut center total + 悦己 spend header. | ja | ⏳ | |
| 3 | Donut center shows the TRUE all-category total; slices + legend % visibly reconcile to it (WR-02). | ja | ⏳ | |
| 4 | WR-02 「その他」(Other) slice appears as a neutral long-tail slice when >10 L1 categories have spend; it is NOT tappable. | ja | ⏳ | |
| 5 | Donut/legend full-row drill-down opens the read-only CategoryDrillDownScreen for real L1 rows. | ja | ⏳ | |
| 6 | Joy-calendar inline day-expand opens; WR-04 fix visible — pull-to-refresh re-fetches the expanded day's list (no stale/deleted rows). | ja | ⏳ | |
| 7 | Dark mode renders the full page with ADR-019 dark palette (warm #171210 bg, leaf-green primary, sakura joy). | ja (dark) | ⏳ | |
| 8 | 3-language switch (ja→zh→en) renders all cards + the "Other" label correctly, no overflow/clipping, no hardcoded CJK. | ja/zh/en | ⏳ | |
| 9 | Group-mode family_insight card appears in family/group mode (GUARD-02 aggregate face). | ja (group) | ⏳ | |
| 10 | No anti-gamification copy leaks visible (ranking/streak/target/comparison) in any card, any locale. | ja/zh/en | ⏳ | |

---

## Resume signal

Type **"approved"** if all 10 D-10 items pass on-device; otherwise list the failing item numbers + observed defects (each becomes a blocking gap to close before milestone closeout).
