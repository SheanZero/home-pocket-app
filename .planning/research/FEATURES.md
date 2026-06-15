# Feature Research

**Domain:** Personal-finance analytics / statistics page redesign for a dual-ledger (日常 Daily + 悦己 Joy) kakeibo-style app
**Researched:** 2026-06-15
**Confidence:** HIGH (UX patterns from named best-in-class apps + kakeibo philosophy; well-cross-checked). MEDIUM on exact ADR-012 boundary classification of a few "neutral context" patterns — those are flagged as design-phase decisions.

> Scope note: this file covers ONLY the v1.8 statistics-page redesign. It assumes the 15 existing analytics surfaces (KPI strip, 6-month trend, category donut, Daily-vs-Joy snapshot, satisfaction histogram, per-category joy breakdown min-N=3, story cards, family insight, time-window selector, manual-only joy variant) already ship and are NOT re-proposed. New work either (a) promotes/reframes existing internal data, or (b) adds emotionally-affirming joy surfaces compatible with ADR-012.

> **The single most important finding:** the milestone's "make users feel good about spending on themselves" goal has a *non-gamified precedent baked into kakeibo itself*. Kakeibo's fourth reflection question — "How can I improve?" — is explicitly reframed in the literature as **"it might mean deciding to spend MORE on what you really enjoy, and less on purchases you didn't value."** This is values-affirmation, not achievement. It is the philosophical license for the entire 悦己 emotional layer WITHOUT touching streaks/badges/targets-as-achievement. Design phase should anchor on this.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume a modern finance analytics page has. Missing these = the redesign feels incomplete and "not practical," which is exactly the complaint driving v1.8.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Income / Expense / Net (结余) overview as the top one-glance block** | Every comparable app (YNAB, Monarch, Copilot) leads with a money-in / money-out / net summary. Home Pocket currently computes income/expense internally but never surfaces it as a first-class block — the explicit (a) goal of v1.8. | MEDIUM | Income/expense aggregation likely already exists in analytics use cases (monthly reports). Net = income − expense. Needs an income data path verified — historically the app is expense-centric; confirm income transactions are captured. **Dependency risk: if income is not reliably entered, "savings rate" is misleading.** |
| **Savings rate (结余率) as a headline number** | The defining "am I doing OK?" metric in kakeibo (questions 1–3) and every savings-oriented app. `结余率 = (income − expense) / income`. | MEDIUM | Cheap to compute once income/expense block exists. Must degrade gracefully when income = 0 (show "—" not a divide-by-zero or a scary 0%/-∞%). Kakeibo framing: this is THE practical anchor. |
| **Spending-by-category breakdown (donut + ranked list)** | Universal "where did my money go" answer. Already shipped (top-5 + Other donut) — table stakes confirmed, redesign should keep it. | LOW (exists) | Keep. The redesign job is information architecture, not net-new. |
| **Tap-a-category-to-drill-down to its transactions / subcategories** | YNAB: "click a category in the circle graph to drill into subcategories… drill further to see all transactions." Beyond Budget, Expense Buddy do the same. This is the expected interaction model, and Home Pocket's donut is currently a dead-end (no drill). | MEDIUM | The (a) goal explicitly names "分类下钻". Reuses existing per-category data + the v1.4 transaction-list filtering (`GetListTransactionsUseCase` already filters by category). Strong reuse: drill-down can route into the existing filtered list rather than build a new screen. |
| **Spending trend over time (rolling N months)** | "Is my spending going up or down" is a baseline question. 6-month bar trend already exists — keep, possibly restyle. | LOW (exists) | Keep. Trend is rolling/neutral by nature (no judgment copy) so it's ADR-012-safe as-is. |
| **Time-window selector (month / quarter / year / custom)** | Already shipped. Expected control on any analytics page. | LOW (exists) | Keep. |
| **Empty / low-data states** | A redesigned page with richer blocks needs honest empty states (no income yet, <3 joy entries, new user). The app already does 3-variant empty states elsewhere (v1.4/v1.6). | LOW–MEDIUM | Pattern established in codebase; apply consistently to the new overview + joy blocks. Critical for the min-N joy surfaces. |

### Differentiators (Competitive Advantage)

These set Home Pocket apart and directly serve goal (b) — the emotional 悦己 layer. They are the heart of the milestone. All listed here are designed to be ADR-012-compatible (see anti-feature table for the forbidden cousins).

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **"Money well spent" 悦己 affirmation block** — surface total 已花悦己 spend + Σ joy_contribution framed as *celebration of investing in yourself*, not as a score to beat | This is the unique product thesis: a ledger that makes self-spending feel *good and legitimate*, not guilty. Directly the (b) goal and the central design question. The bizorca "how you feel" app validates the pattern: emotional intent categories ("Comfort/Escape") framed as **"chosen consciously… not a moral judgment, a data category."** | MEDIUM | Reuses existing `joy_contribution` (ADR-016) + 已花悦己 totals. The work is framing/IA/copy, not new computation. **Must NOT become a target ring with achievement semantics** — HomeHero's target ring stays isolated per ADR-016 §3; analytics joy block should be reflective, not a progress-to-goal gauge. |
| **Satisfaction / "worth-it" reflection surface** — show that high-spend 悦己 entries also scored high satisfaction; affirm "this was worth it" | Closes the loop kakeibo intends: spending aligned to values feels validated. Uses the existing 1–10 unipolar satisfaction (ADR-014). Affirming framing: "your most satisfying 悦己 spending this period." | MEDIUM | Reuses satisfaction histogram + per-category joy data (min-N=3). Frame as *content/proud*, never as "beat last month's satisfaction." Keep min-N guard to avoid noisy single-entry claims. |
| **Memory / story surface ("best joy moment" card, expanded)** — narrative recall of meaningful self-spending | Memory framing makes spending feel like life, not accounting. "Best joy moment" story card already exists; redesign can elevate it into a richer reflective surface (e.g. a small "悦己 moments this period" strip). | MEDIUM | Reuses existing best-joy-moment story card. Pure surfacing/IA. Story/memory framing is inherently non-competitive → ADR-012-safe. |
| **Values-based reflection prompt (kakeibo Q4, reframed positive)** — a gentle, non-prescriptive "what felt worth it this period?" reflection, NOT a scorecard | Kakeibo's "How can I improve?" is explicitly open-ended and can mean *spend more on what you enjoy*. This is the single most defensible non-gamified way to make self-spending feel good. Differentiator vs every automated competitor (kakeibo apps reflect; Mint/Copilot just report). | MEDIUM–HIGH | New surface. Must be **affirming and open-ended**, never a target or a graded prompt. Risk: drifts into judgment if copy is wrong → tightly constrain in design + run through `anti_toxicity_*_test`. Consider whether a new ADR is needed if it stores user reflection text (privacy + encryption implications). |
| **Sankey / flow visualization of income → expense → 结余** | Monarch's standout 2026 feature; makes savings rate "visceral — when the stream to savings is thinner than to entertainment, no explanation needed." Could powerfully unify the (a) practical overview AND show 悦己 as a deliberate, visible stream rather than a guilty leak. | HIGH | High value but high cost: fl_chart has no native Sankey (would need custom paint or a new dep; note `TOOL-V2-01 fl_chart 1.x→2.x` is already flagged as possibly pulled forward by "全面大改"). Strong candidate for a *design-exploration direction* in Phase 43 HTML, deferrable if cost is too high. The 悦己-as-intentional-stream framing is genuinely on-thesis. |
| **Neutral rolling context ("about typical" band)** | TD MySpend shows current month against an average-month trend ("more / less / about the same"). Lets users orient WITHOUT cross-period delta judgment. Could give the practical overview useful context. | MEDIUM | **BOUNDARY-SENSITIVE — see anti-features.** A neutral rolling baseline band ("your typical month") may be allowable; an explicit "+15% vs last month" delta is HARD-BLOCKED by ADR-012 #4/#7. Design phase must choose the framing carefully and verify against `anti_toxicity_*_test`. Treat as MEDIUM-confidence-allowed, decision deferred to design + possibly a new ADR. |

### Anti-Features (Commonly Requested, Often Problematic)

Patterns that look like obvious "engagement wins" but **VIOLATE ADR-012's permanent anti-gamification contract** (structurally locked by `anti_toxicity_*_test` + `home_screen_isolation_test`). The design phase MUST avoid all of these. Listed with the specific ADR-012 clause they violate.

| Feature (DO NOT BUILD) | Why It Gets Requested | Why Forbidden / Problematic | ADR-012-Compatible Alternative |
|------------------------|-----------------------|------------------------------|--------------------------------|
| **Cross-period delta callouts** ("you spent 15% more than last month", "vs 上月 +3.2") | Standard "spending insight" in Copilot/Monarch; feels helpful | **HARD-BLOCKED — ADR-012 #4 (cross-period delta) + #7 (历史趋势对比).** Provokes self-judgment; the milestone prompt explicitly calls this out as the hard block. | Neutral rolling trend chart (no delta copy) + optional "about typical" band framed without a signed number/judgment. Show the data, omit the verdict. |
| **Streaks** ("7 days of logging", "3 months in a row of saving") | Boosts short-term DAU | **HARD-BLOCKED — ADR-012 #1 (streaks) + #5 (streak displays).** Goodhart's-law core case. | Nothing. Consistency is not a surface. Let the trend chart speak neutrally. |
| **Badges / achievements / milestone unlocks** ("First ¥10k saved!", "Joy master") | Feels rewarding | **HARD-BLOCKED — ADR-012 #2 (badges/achievements) + #7.** | Affirming *ambient* framing only (e.g. ADR-016's color-shift is "continuous f(progress)→color", explicitly NOT an unlock event). No discrete reward moments. |
| **Savings-rate / joy-spend GOAL with achievement celebration** (toast, confetti, "Goal reached!") | Goals motivate | **HARD-BLOCKED for celebration — ADR-012 #2.** Note: ADR-016 already permits a *configurable monthly joy target* as a quiet fill ring on HomeHero, but with NO toast/animation/haptic/>100% number. | Show savings rate as a neutral number with kakeibo "how can I improve (incl. spend more on joy)" reflection. If a target appears at all, mirror ADR-016's ambient, celebration-free contract. Keep targets OFF the analytics page (HomeHero owns the only target ring, per ADR-016 §3 isolation). |
| **Per-member leaderboard / contribution ranking** (who spent more / who's happier in the family) | "See how the family compares" | **HARD-BLOCKED — ADR-012 #6 (per-member breakdown surfaces).** Type-system-enforced (aggregate-only family insight). Especially toxic in family money context. | Aggregate-only family insight (already shipped). Never rank or attribute joy by member on analytics. |
| **Public sharing of happiness/joy metrics** (share card, social link) | Viral growth | **HARD-BLOCKED — ADR-012 #5 (public sharing).** Also violates the zero-knowledge/privacy thesis. | None. Reflection is private by design. |
| **"Spend less on joy" / guilt nudges** ("You spent a lot on yourself this month") | Looks like responsible budgeting | **VIOLATES the product ethic** ("celebrating, not grading"; "让用户的每一笔灵魂支出都是幸福的"). Inverts the milestone goal. | Affirm conscious joy spending (bizorca: "not a moral judgment, a data category"). Frame 悦己 spend as investment-in-self, never as overspend. |
| **Satisfaction-as-target / "hit 8+ satisfaction"** | Gamify the satisfaction score | **HARD-BLOCKED — ADR-012 #3 (daily satisfaction targets)** + Goodhart (the exact distortion ADR-012 protects the satisfaction data from). | Show satisfaction *distribution* and *reflection* ("what felt worth it"), never a satisfaction goal to hit. |

---

## Feature Dependencies

```
Income/Expense/Net overview block (P1)
    └──requires──> reliable income capture (VERIFY: is income entered today?)
    └──enables──> Savings rate headline (P1)
                      └──enables──> Sankey income→expense→结余 (P2, optional)

Category donut (exists)
    └──enables──> Tap-category drill-down (P1)
                      └──reuses──> GetListTransactionsUseCase category filter (v1.4)

joy_contribution + 已花悦己 totals (ADR-016, exists)
    └──enables──> "Money well spent" 悦己 affirmation block (P1)
    └──enables──> Worth-it / satisfaction reflection surface (P2)
                      └──reuses──> satisfaction histogram + per-category joy (min-N=3)

Best-joy-moment story card (exists)
    └──enhances──> Memory/story surface (P2)

Kakeibo Q4 reflection prompt (P2/P3)
    └──conflicts──> any cross-period delta / target framing (must stay open-ended)
    └──may-require──> new ADR if it stores user-authored reflection text (encryption)

Neutral "about typical" rolling band (P3, boundary-sensitive)
    └──conflicts──> cross-period delta (ADR-012 #4) — framing decision gates this
```

### Dependency Notes

- **Savings rate requires income capture:** the biggest open risk. Home Pocket has historically been expense-centric (`amount`, dual-ledger expense classification). If income transactions aren't reliably present, savings rate and the income/expense overview are built on sand. **This must be verified before committing the (a) overview as P1** — see Open Questions.
- **Drill-down reuses v1.4 list, not a new screen:** `GetListTransactionsUseCase` already filters by category/ledger/member. Tapping a donut slice should deep-link into the existing filtered list — minimizes new code and keeps interaction consistent.
- **Joy affirmation reuses ADR-016 data, NOT HomeHero's ring:** ADR-016 §3 isolates the HomeHero target ring. The analytics joy block must be a *reflective* surface (totals + satisfaction + memory), explicitly NOT a second progress-to-target gauge, or it risks both the isolation invariant and the achievement-framing boundary.
- **Kakeibo reflection vs delta conflict:** the reflection prompt is safe ONLY while open-ended and present-focused. The moment it references "last month" quantitatively it becomes ADR-012 #4. Keep them apart.

---

## MVP Definition

### Launch With (v1.8 core)

The practical (a) goal + the safest, highest-reuse parts of the emotional (b) goal.

- [ ] **Income / Expense / Net overview block** — the headline practical fix; the explicit milestone ask (pending income-capture verification)
- [ ] **Savings rate (结余率) number** — cheap once overview exists; the kakeibo practical anchor
- [ ] **Tap-category drill-down** — answers "where did my money go", reuses v1.4 list
- [ ] **"Money well spent" 悦己 affirmation block** — the core emotional thesis, reuses ADR-016 data, framing-only work
- [ ] **Redesigned IA + neutral spending trend** — the "全面重设计" itself; restyle existing trend/donut into a coherent page
- [ ] **Honest empty/low-data states** — required by the new richer blocks (esp. no-income, <3 joy entries)

### Add After Validation (v1.x within milestone if time allows)

- [ ] **Worth-it / satisfaction reflection surface** — once the affirmation block lands well
- [ ] **Memory/story surface (elevated best-joy moments)** — pure surfacing of existing card
- [ ] **Kakeibo Q4 reflection prompt (open-ended, affirming)** — high differentiator; needs careful copy + anti-toxicity verification; possibly a new ADR if it persists text

### Future Consideration (v2+ / design-direction-only)

- [ ] **Sankey income→expense→结余 flow** — high value, high cost (no native fl_chart support; ties to TOOL-V2-01). Explore as a Phase 43 HTML *direction*; defer build if cost-prohibitive
- [ ] **Neutral "about typical" rolling band** — boundary-sensitive (ADR-012 #4 adjacency); only if a clean non-judgmental framing is validated, possibly requiring a new ADR
- [ ] **Per-currency analytics sub-totals** (CUR-V2-02, already a carried backlog item) — out of v1.8 scope unless the redesign naturally absorbs it

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Income/Expense/Net overview | HIGH | MEDIUM | P1 |
| Savings rate headline | HIGH | LOW (after overview) | P1 |
| Tap-category drill-down | HIGH | MEDIUM (reuse) | P1 |
| "Money well spent" 悦己 affirmation block | HIGH | MEDIUM (framing) | P1 |
| Redesigned IA + neutral trend restyle | HIGH | MEDIUM | P1 |
| Honest empty/low-data states | MEDIUM | LOW–MEDIUM | P1 |
| Worth-it / satisfaction reflection | MEDIUM–HIGH | MEDIUM | P2 |
| Memory/story surface (elevated) | MEDIUM | LOW–MEDIUM | P2 |
| Kakeibo Q4 reflection prompt | HIGH (differentiator) | MEDIUM–HIGH | P2 |
| Sankey flow viz | HIGH | HIGH | P3 |
| Neutral "about typical" band | MEDIUM | MEDIUM | P3 (gated by ADR) |

**Priority key:** P1 = launch v1.8; P2 = add within milestone if capacity; P3 = design-direction/defer.

## Competitor Feature Analysis

| Pattern | YNAB / Copilot / Monarch | Kakeibo (method + apps) | Home Pocket Approach |
|---------|--------------------------|--------------------------|----------------------|
| Money overview | Income/expense/net + net-worth dashboards; Monarch customizable | 4 questions: have / save / spend / improve | Income/Expense/Net + 结余率, kakeibo-anchored, privacy-local |
| Where-money-went | Donut/Sankey + drill to transactions (YNAB drill, Monarch Sankey) | Category review at month-end | Donut drill-down → reuse v1.4 filtered list |
| Period context | Cross-period delta, "vs last month" (Copilot/Monarch) | Month-end "how can I improve" reflection | **Neutral trend only; NO delta (ADR-012 #4).** Reflection over comparison |
| Feeling good about spending | Mostly absent or guilt-framed ("over budget"); bizorca "how you feel" app = emotional-intent categories, judgment-free | Q4 reframed: "spend MORE on what you enjoy"; values-alignment | **Core thesis** — 悦己 affirmation + worth-it + memory, celebrating not grading |
| Engagement mechanics | Streaks/badges common in habit-finance apps | None — reflection-based | **None — ADR-012 forbids all.** Ambient framing only |

## Sources

- [Why I Built a Budgeting App That Asks You How You Feel — bizorca](https://www.bizorca.com/p/budgeting-app-how-you-feel) — emotional-intent categories (Survival/Comfort/Escape), "not a moral judgment, a data category"; judgment-free framing without gamification (directly analogous to Daily/Joy)
- [YNAB Budget Reports — YNAB](https://www.ynab.com/blog/ynab-reports-and-data) — click circle-graph category to drill into subcategories then transactions (drill-down model)
- [Using Reports — Monarch Money](https://help.monarch.com/hc/en-us/articles/21846787088916-Using-Reports) and [Best Budgeting Apps 2026 — Online Tool Guides](https://onlinetoolguides.com/best-budgeting-apps/) — customizable dashboards, monthly overviews, Sankey as standout viz
- [Recent Spending — Beyond Budget](https://www.beyondbudgetapp.com/accounts/recent-spending) — donut + ranked category list with amount and % of total
- [Kakeibo: The Japanese Art of Mindful Spending — Penny Hoarder](https://www.thepennyhoarder.com/budgeting/kakeibo/) and [Guide to Kakeibo — SoFi](https://www.sofi.com/learn/content/kakeibo-budgeting-method/) — four reflection questions; "How can I improve?" explicitly includes "spend MORE on what you really enjoy" (values-affirmation, non-gamified)
- [Why Every Budget Fails Without Reflection — kakeibo-templates](https://www.kakeibo-templates.com/blog/budget-fails-without-reflection) — reflection-over-optimization philosophy
- [Sankey Cash Flow Diagrams — ProjectionLab](https://projectionlab.com/financial-terms/sankey-cash-flow-diagram) — "makes savings rate visceral… no explanation needed"; flow-of-money visualization
- [Compare Monthly Spending / rolling baseline — Finny](https://getfinny.app/blog/compare-monthly-spending) and [TD MySpend](https://stories.td.com/ca/en/news/2016-04-14-instantly-know-where-your-money-goes-with-td-myspend) — "about the same / more / less" neutral rolling-average context vs judgmental delta (boundary reference for the allowed-vs-forbidden line)

---
*Feature research for: dual-ledger kakeibo analytics redesign (v1.8)*
*Researched: 2026-06-15*
