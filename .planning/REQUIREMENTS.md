# Requirements: Home Pocket — v1.8 统计页面重设计（实用化 × 悦己情感化）

**Defined:** 2026-06-15
**Core Value:** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations.

**Milestone goal:** Full overhaul ("全面大改") of the statistics/analytics page — more practical (expense overview, spending trends, category drill-down) and emotionally highlighting 悦己 self-spending so users feel good about spending on themselves — **within the permanent ADR-012 anti-gamification constraint.** A dedicated HTML design-exploration phase (research current implementation → multiple HTML directions → discussion → selection) gates development; build phases follow only after design approval.

**Central design tension (resolved in the GATE phase):** "凸显悦己 / 让用户为自己花钱而感到开心" sits one design decision away from violating ADR-012. Research finding: it is **structurally containable** by inheriting ADR-016 §5's line — ambient `f(progress)→color` is OK; discrete unlock/threshold/celebration/target/comparison is forbidden — and anchoring on kakeibo's own non-gamified Q4 ("spend MORE on what you enjoy" = values-affirmation, not achievement). See `.planning/research/SUMMARY.md`.

---

## v1 Requirements

Requirements for this milestone (v1.8). Each maps to a roadmap phase.

### Design Gate (设计探索关卡)

> Phase 43 — a hard gate. No production code is committed in this phase.

- [x] **GATE-01**: Produce a written deep-research map of the current statistics implementation (seeded by `.planning/research/ARCHITECTURE.md`'s reuse map)
- [x] **GATE-02**: Produce ≥3 HTML design directions, each carrying an ADR-012 self-audit table mapping every emotional element to *ambient / celebratory-of-the-past* (OK) vs *target / comparison / achievement* (forbidden)
- [x] **GATE-03**: Thorough discussion → user selects exactly ONE direction (gate exit criterion = user approval; no Dart/production code committed)
- [x] **GATE-04**: For the selected direction, decide go/no-go on a new ADR if it grazes the ADR-012 boundary (e.g. persisting user-authored reflection text in JOY-04); lock the emotional-vocabulary list for the anti-toxicity sweeps; validate each chart affordance against the current fl_chart 1.2.0 API

### Expense Overview (支出总览)

> Reframed from "收支总览/结余率" because the app has **no income-entry path** today (the only transaction writer hardcodes `TransactionType.expense`), so `totalIncome` is always 0 and a savings rate would be meaningless. Real savings-rate is deferred to a future milestone once income capture lands.

- [x] **OVW-01**: The statistics page presents a first-class expense-overview surface for the active time window — total spend + 日常/悦己 split + top categories — reusing `GetMonthlyReportUseCase` (zero new data work)
- [x] **OVW-02**: The overview obeys ADR-012 — neutral current-window presentation, no cross-period delta and no judgmental framing

### Spending Trend (支出趋势)

- [x] **TREND-01**: Spending trend over time is presented (reusing `GetExpenseTrendUseCase`, 6-month rolling), as neutral rolling context only — no "more/less than last month" judgment framing (ADR-012 #4)

### Category Drill-down (分类下钻)

- [x] **DRILL-01**: Tapping a category (in the donut / category breakdown) drills into that category's transactions for the active window, reusing the v1.4 `GetListTransactionsUseCase` filter path (or one thin read-only path if the design requires it)

### Joy Emotional Surfaces (悦己情感化)

> All four committed. Concrete visual form is decided in the GATE phase under ADR-012; here we commit *which* surfaces ship.

- [ ] **JOY-01**: "值得" affirmation block — surface 已花悦己 + `Σ joy_contribution` as a *celebration of investing in yourself* (framing-only over ADR-016 data; **ambient presentation — must NOT become a progress/target ring; HomeHero owns the only target ring, ADR-016 §3**)
- [ ] **JOY-02**: "值不值" satisfaction-reflection surface — reuse the satisfaction histogram + per-category joy (min-N=3), framed as proud/content, never "beat last month" / ranking
- [~] **JOY-03**: ~~Memory/story surface — elevate the existing "best joy moment" story card (pure surfacing of existing data)~~ — **Descoped (superseded by GATE-03 round-5 B).** round-5 B (the user-approved single source of truth, D-A1) is exactly 5 cards and deliberately omits the 记忆故事 (best-joy story) card; the final selected mock grep-confirms 0 hits for 记忆故事. The joy emotional surface is instead re-carried ambiently by the round-5 B design (JOY-01 已花悦己 amount → 悦己 tab + 悦己花在哪 header; 分类悦己 → 悦己花在哪 stacked bar; 满足度 → satisfaction histogram). No story card is built anywhere in Phase 46; this requirement ID is satisfied **by this descope correction, not by code** (D-A2).
- [~] **JOY-04**: ~~Kakeibo Q4 reflection prompt — an open-ended, affirming "how could spending make you happier next time" prompt; **if it persists user-authored text, a new ADR is required** (encryption/privacy implications) — decided in GATE-04~~ — **Descoped (superseded by GATE-03 round-5 B).** round-5 B is exactly 5 cards and deliberately omits the kakeibo Q4 reflection prompt; the final selected mock grep-confirms 0 hits for kakeibo. GATE-04 already ruled JOY-04 text-persistence NO-GO (static read-only → no persisted text → no encryption/ADR; v1.8 stays no-Drift). A future milestone may revisit JOY-04 — persisting user-authored text would require a new ADR + non-Drift storage (per Phase 43 D-07). No prompt card is built in Phase 46; this requirement ID is satisfied **by this descope correction, not by code** (D-A1/D-A2).

### Redesign — IA + Visual (信息架构与视觉重构)

- [x] **REDES-01**: Full IA + visual redesign of `AnalyticsScreen` — thin shell + a `widgets/cards/` card system (fixed layout), with a data-driven `_refresh()` that preserves HomeHero isolation by construction
- [ ] **REDES-02**: Chart polish — adopt fl_chart 1.2.0 native per-rod `label` (delete the histogram `Stack` hack) + optional donut `cornerRadius`; **no chart-library upgrade/swap (keep `^1.2.0`)**
- [ ] **REDES-03**: Warm/affirming motion via built-in Flutter animations (`TweenAnimationBuilder` count-up, `AnimatedSwitcher`, glow), ADR-012-safe (ambient, not achievement-reward)

### Quality & Guardrails (质量与约束守护)

- [x] **GUARD-01**: HomeHero isolation preserved — `home_screen_isolation_test.dart` stays green; analytics reads/invalidates no `home/*` provider
- [ ] **GUARD-02**: Anti-gamification — every new card joins the `anti_toxicity_*_test` forbidden-substring sweep (ja/zh/en × all states); `FamilyHappiness` stays aggregate-only (no per-member fields); single-Joy-expression preserved (`grep density|joyPerYen lib/` == 0)
- [ ] **GUARD-03**: i18n — ARB parity across ja/zh/en for all new copy; `flutter gen-l10n` clean; 生存/灵魂 grep-ban green (ADR-017)
- [ ] **GUARD-04**: macOS golden re-baseline for new/changed analytics surfaces (chart goldens do not exist today — authored from scratch on macOS, isolated from any library change); full `flutter test` suite as the per-wave gate
- [ ] **GUARD-05**: On-device visual UAT of the redesigned page

---

## v2 Requirements

Deferred to a future release. Tracked but not in this roadmap.

### Income & Savings

- **INCOME-V2-01**: Income-entry capability (the entry flow gains an income type) so a real savings-rate / income-expense net overview becomes meaningful

### Analytics v2

- **ANALYTICS-V2-01**: Sankey income→expense→结余 flow visualization (no native fl_chart support; high cost — explored as a GATE direction only)
- **ANALYTICS-V2-02**: Customizable / reorderable dashboard (user picks which cards show; SharedPreferences-backed card order, never Drift/family-sync)
- **ANALYTICS-V2-03**: Budget vs actual (requires a new `budgets` Drift table + v21→v22 migration; implements the current `GetBudgetProgressUseCase` stub)
- **ANALYTICS-V2-04**: Neutral "about typical" rolling band (boundary-sensitive vs ADR-012 #4; needs a validated non-judgmental framing and likely a new ADR)
- **CUR-V2-02**: Per-currency analytics sub-totals (carried from v1.7)

---

## Out of Scope

Explicitly excluded for v1.8. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Income entry + real savings-rate / income-expense net overview | No income-entry path exists today (only writer hardcodes `expense`); income capture belongs to the entry flow, not the statistics page. Overview reframed to expense-side; real savings-rate deferred to INCOME-V2-01 |
| Budget vs actual (budgets table / Drift migration) | User-excluded; the only ask carrying a schema migration; keeps v1.8 a pure presentation-layer rebuild → ANALYTICS-V2-03 |
| Customizable / reorderable dashboard | User-excluded; v1.8 uses a fixed (redesigned) layout → ANALYTICS-V2-02 |
| Sankey income→expense→结余 flow chart | No native fl_chart support; high cost; explore as a GATE direction only, build deferred → ANALYTICS-V2-01 |
| Neutral "about typical" rolling band | Adjacent to the ADR-012 #4 boundary; needs validated non-judgmental framing + likely a new ADR → ANALYTICS-V2-04 |
| fl_chart 1.x→2.x upgrade (TOOL-V2-01) | **fl_chart 2.x does not exist** — 1.2.0 is the latest published version and is the current pin; the backlog item rests on a false premise. Retire/re-scope TOOL-V2-01 as N/A |
| Cross-period delta callouts, streaks, badges/achievement unlocks, goal-celebration toasts/confetti, per-member leaderboards, public sharing of joy metrics, satisfaction-as-target ("hit 8+") | ADR-012 permanent anti-gamification contract — cross-milestone, structurally enforced by `anti_toxicity_*_test` + type system |
| Per-currency analytics sub-totals (CUR-V2-02) | Carried from v1.7; out of v1.8 scope unless the redesign naturally absorbs it |
| Month-lock / settlement, undo-on-delete, combined family-calendar per-day totals | Existing carried exclusions (v1.4) — candidates for a later milestone |

---

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GATE-01 | Phase 43 | Complete |
| GATE-02 | Phase 43 | Complete |
| GATE-03 | Phase 43 | Complete |
| GATE-04 | Phase 43 | Complete |
| OVW-01 | Phase 44 | Complete |
| OVW-02 | Phase 46 | Complete |
| TREND-01 | Phase 44 | Complete |
| DRILL-01 | Phase 44 | Complete |
| JOY-01 | Phase 46 | Pending |
| JOY-02 | Phase 46 | Pending |
| JOY-03 | Phase 46 | Descoped (Phase 46 — superseded by GATE-03) |
| JOY-04 | Phase 46 | Descoped (Phase 46 — superseded by GATE-03) |
| REDES-01 | Phase 45 | Complete |
| REDES-02 | Phase 46 | Pending |
| REDES-03 | Phase 46 | Pending |
| GUARD-01 | Phase 45 | Complete |
| GUARD-02 | Phase 46 | Pending |
| GUARD-03 | Phase 47 | Pending |
| GUARD-04 | Phase 47 | Pending |
| GUARD-05 | Phase 47 | Pending |

---
*Defined 2026-06-15 — v1.8 统计页面重设计. 20 requirements across 7 categories. Phase numbering continues from v1.7's Phase 42 (starts at Phase 43). Research basis: `.planning/research/SUMMARY.md` (+ STACK/FEATURES/ARCHITECTURE/PITFALLS).*
