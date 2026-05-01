# Feature Research — Happiness Metric & Display (v1.1)

**Domain:** Personal/family finance app — "money happiness / spending wellbeing" indicators (v1.1 milestone scope)
**Researched:** 2026-05-01
**Confidence:** MEDIUM-HIGH (HIGH on JP-specific competitor analysis and academic foundations; MEDIUM on family-mode anti-comparison patterns, since most evidence is indirect — by absence rather than explicit design rhetoric)

---

## Scope & framing

This research covers **only the new v1.1 surface area**: how to express "spending happiness" as quantitative indicators, how to visualize them on home/analytics pages, and how to present family-cooperative versions without producing toxic comparison dynamics. It deliberately excludes already-shipped features (per-transaction satisfaction input, voice sentiment estimation, monthly analytics base, family sync). The four locked personal indicators (Avg Satisfaction / Joy per ¥ / Highlights count / Best Joy per ¥) and two family indicators (Family Highlights Sum / Shared Joy Insight) are taken as given — the goal is to validate that the picked formulas align with industry practice and surface anything we may be missing for the JP primary locale.

**Confidence on the locked formulas:** the four-personal + two-family decomposition turns out to be very well-aligned with what little prior art exists; most of the risk lies not in formula choice but in **presentation** (especially family mode and the "Best" highlight card). See "Differentiators" and "Anti-Features" for where the genuine design risk lives.

---

## Direct prior art (the most important finding)

A Japanese app called **Joy Money** (CAMPFIRE crowdfunding project, currently pre-launch) ships an almost-identical core: 5-point satisfaction per transaction, "支出 × 幸福度 × 思い出" trio of metrics, "beautiful graphs visualizing the relationship between money spent and happiness gained", and per-transaction "memory cards" combining spend + satisfaction + photo. It is positioned for the **推し活 (oshi-katsu / fan-activity)** market — the same JP cultural niche our Soul ledger sits next to.

**What this means for us:**
- Concept-validity is HIGH for the JP market — at least one funded competitor is betting on the same thesis
- Our **family mode** is a clear differentiator (Joy Money is single-user)
- Our **encrypted local-first** architecture is a clear differentiator (Joy Money is presumed cloud-based)
- Joy Money does NOT publish a satisfaction-per-yen formula or argmax highlight card — those are still novel territory; we are early on the formula side, not late

A second adjacent app, **推しPay**, tracks oshi-katsu spend + days-since-start but does not surface satisfaction-density metrics. So the "幸福密度 / Joy per ¥" framing genuinely appears to be unclaimed in the JP market as of search date.

Sources for the direct prior-art block:
- [推し活をもっと楽しく！支出×幸福度×思い出を可視化する新しい家計簿アプリ — CAMPFIRE](https://camp-fire.jp/projects/883660/view)
- [推しPay — Apps on Google Play](https://play.google.com/store/apps/details?id=com.nosuke.oshi_pay)
- [推し活支出管理 — App Store JP](https://apps.apple.com/jp/app/%E6%8E%A8%E3%81%97%E6%B4%BB%E6%94%AF%E5%87%BA%E7%AE%A1%E7%90%86/id1503878877)

---

## Feature Landscape

### Table Stakes (Users Expect These)

These are the dimensions a user opening the v1.1 HomePage will assume exist — missing any of them makes the "happiness metric" framing feel half-baked. All six are already in the locked list, which is reassuring; commentary below documents the **expected behavior** the requirements step should verify against.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Average satisfaction (period summary) | Mood/wellbeing apps universally show period average as the headline number (Daylio's monthly mood score, Headspace's mood overview, every CSAT dashboard). Without it, users can't answer "how was this month overall?" in one glance. | LOW | Simple `AVG(soul_satisfaction) WHERE ledger_type='soul' AND month=current`. Display as 1-decimal float (e.g. `7.3 / 10`); emoji translation OK as secondary. **Empty-state handling is mandatory:** a brand-new month has 0 soul transactions, and "0.0/10" reads as catastrophic. Show "—" or "まだ記録なし". |
| Highlights count (satisfaction ≥ 8) | Threshold-counting is the standard pattern for "wins" in habit/mood trackers (Daylio's "great days" count, Apple Health's "exercise minutes ≥ goal" days). Users want to know "how many genuinely good moments did I have?" not just an average that washes out highs and lows. | LOW | `COUNT(*) WHERE soul_satisfaction >= 8`. Threshold of 8 on a 1-10 scale = top-30% definitionally; aligns with the "1/3 of recordings should feel like wins" intuition embedded in most mood-tracker UX. **Do NOT make threshold user-configurable in v1.1** — over-customization defeats the "comparable across months" property. |
| Joy per ¥ (Σ satisfaction / Σ amount) | Density/efficiency metrics are the entire category — YNAB's "Age of Money", Apple Watch's calorie-per-minute. Once you have two correlated quantities (amount, satisfaction), users will naturally ask the ratio. | MEDIUM | The formula `Σ sat / Σ amount` is correct mathematically but **needs a unit treatment for display** — the raw number (e.g. `0.00012 sat/yen`) is unintelligible. Options: (a) normalize to `sat per ¥1,000` so a ¥1,000 8-satisfaction purchase reads as `8.0`; (b) percentile-rank against the user's own history; (c) graph-only, never display the bare number. **Recommendation:** option (a) — display `"幸福密度 8.2"` with tooltip "1,000円あたりの満足度合計". For non-JPY locales: equivalent normalization (per ¥1k / per $10 / per ¥10) per `currentLocaleProvider`. |
| Best Joy per ¥ moment (story-mode card) | Spotify Wrapped's "your top moment" card is now a universally-recognized pattern; Joy Money's "memory cards" carry the same DNA. Users expect to see a *specific* peak moment celebrated, not just averages. | MEDIUM-HIGH (UI) | `argmax(satisfaction / amount) WHERE ledger_type='soul' AND month=current`. Card should show: amount, satisfaction emoji/score, category, date, optional note. **Edge cases that must be handled:** (1) divide-by-zero for ¥0 transactions (gifts received, refunds — exclude); (2) extreme outliers from very small purchases (a ¥10 candy with sat=10 will dominate forever — consider a floor like "amount must be ≥ ¥100" or use `argmax(sat × log(amount))` to dampen). (3) Same transaction every month — show "still your best!" framing instead of pretending it's new. |
| Satisfaction distribution histogram | Daylio's mood-distribution chart is iconic; users learn more from "I had 3 great days, 12 mediocre, 2 bad" than from any average. Already unblocked by the `getSatisfactionDistribution` DAO. | LOW | 1-10 bar chart, x-axis = satisfaction score, y-axis = transaction count. Color-shade bars: red for ≤3, neutral for 4-7, soul-green (#47B88A) for ≥8 to visually mark the "highlights" zone. Tap a bar → list of transactions at that score (already a known pattern from analytics filtering). |
| Joy per ¥ trend line (over the month) | Standard time-series in any mood/wellbeing app. Already unblocked by the `getDailySatisfactionTrend` DAO. | LOW-MEDIUM | Daily Joy-per-¥ value over month. **Watch out for sparsity**: many days will have 0 soul transactions → produces gaps, not zeros. Either (a) skip empty days and connect dots (best for trend reading), or (b) show as scatter not line. Don't draw zero-lines on empty days — that misleadingly suggests "no joy that day" when it really means "no spending that day". |

**Dependencies on existing capabilities** (all confirmed present per PROJECT.md baseline):
- `transactions.soul_satisfaction` field (1-10) — schema already supports
- `ledger_type='soul'` filter — present in DAO layer
- Three dormant DAO methods (`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`) — exist, just need wiring
- `currentLocaleProvider` + `NumberFormatter` — needed for ¥/$ unit display per locale

---

### Differentiators (Competitive Advantage)

These set v1.1 apart from existing JP/CN/EN finance apps and the one direct competitor (Joy Money). All map to the locked feature list — commentary below explains *why* each is a differentiator and what raises/lowers its impact.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Joy per ¥ as a first-class metric** (not just a graph) | No identified competitor surfaces a satisfaction-density number on the home screen. Joy Money visualizes the *relationship* but doesn't reduce it to a single shareable scalar. Mainstream JP apps (マネーフォワード ME, Zaim) don't track satisfaction at all. The CN budget-app market focuses on *control* (predictive budget alerts, AI auto-categorization), not *appreciation*. A density metric on the home tile is uncontested ground. | MEDIUM | Risk: the metric only "feels right" once a user has 5+ soul transactions in a month. Plan for the cold-start period — show "もう少し記録すると現れます (a few more records will reveal it)" guard text instead of a misleading early number. |
| **Best Joy per ¥ as a celebrated moment, not a leaderboard slot** | Spotify Wrapped showed that a single argmax card reframed as "your top X" is socially shareable and emotionally resonant. Joy Money's memory cards do this for individual purchases but not for an *aggregate winner*. Combined with the soul-ledger-only filter, this lands as "the best joy you bought yourself this month" — a phrasing that has no obvious competitor. | MEDIUM-HIGH | Story-mode card should be visually distinct from the metric tiles (full-width, photo-card composition). Borrows directly from Spotify Wrapped grammar — clean type, single statistic, optional photo. **Anti-pattern to avoid:** comparing against last month ("3% less joy than April") — exactly the social-comparison framing experiential-purchase research shows undermines the satisfaction itself. |
| **Family Highlights Sum (cooperative, not competitive)** | OsidOri (the leading JP couples-finance app) has solved the "shared vs personal" split well, but does not aggregate any wellbeing/joy signal across family members. Honeydue and Splitwise are pure transactional tools. We have a clear lane for "the family had **N joyful moments together**" as a cooperative scoreboard with no per-member breakdown. | MEDIUM | Critical implementation rule: render as a **single number** ("家族の小確幸 27回") with optional category breakdown — **never per-member breakdown** in v1.1. The moment you show "Mom: 12, Dad: 8, Kid: 7" you've built a leaderboard accidentally. The Gilovich body of research on experiential purchases is explicit that comparison-driven evaluation undermines satisfaction. |
| **Shared Joy Insight (top category by family-avg satisfaction)** | "What kind of spending makes our family happiest?" is a question NO existing finance app answers. JP shared apps (OsidOri, Zaim group) answer "what categories do we spend most on?". The semantic shift from amount-based to satisfaction-based category ranking is genuinely novel. | MEDIUM | Compute as `argmax(category, AVG(satisfaction)) WHERE ledger_type='soul' AND family.member IN <all> AND month=current`. **Minimum-N guard** is essential: a single 10-satisfaction sushi meal shouldn't crown "外食" as the family's joy category for the month. Require ≥3 transactions per category before it qualifies. Gracefully fall back to "もっと記録が必要" if no category meets the threshold. |
| **Visual rename from "Soul" → "悦己 / ときめき / Joy"** (ARB-only) | The original "灵魂账本" framing imports translation friction (English "Soul ledger" sounds new-age; Japanese "魂の充実度" reads grim). The v1.1 renames track much better with the **悦己消费 (CN trend)** and **自分へのご褒美 (JP norm)** cultural conversations the target audience is already having. | LOW | This is positioning, not engineering — but its impact on adoption is plausibly larger than any indicator formula. |
| **Local-first + encrypted positioning of joy data** | Joy Money is presumed cloud-based; mainstream JP apps push aggressively for bank-aggregation OAuth. Satisfaction data is *more sensitive* than transaction amounts (it reveals what you secretly love), so on-device-only encryption is a believable trust differentiator. | LOW (already shipped) | Existing infrastructure; v1.1 just inherits it. Worth surfacing in onboarding copy when the joy features first appear. |

---

### Anti-Features (Commonly Requested, Often Problematic)

These are the patterns the v1.1 design must explicitly *not* implement. Several will be requested either by users (who naively want them because they exist in social apps) or by future product instincts (because comparison drives engagement metrics in the short term, even when it harms satisfaction long term). Documenting them now creates a defensible "no" for later.

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|---|---|---|---|
| **Per-member joy leaderboard** ("Mom 8.2 ≫ Dad 6.1") | Looks engaging; mirrors Apple Health's family-share leaderboard; "fairness" instinct says all members should be visible. | The Gilovich/Van Boven body of research on experiential purchases explicitly identifies *social comparison* as the mechanism that undermines satisfaction. A family member with lower joy scores isn't measurably less happy — they may rate more conservatively (cultural and individual variance in scale use is well documented), or have fewer soul transactions. Surfacing the comparison ranks them as "less happy", which is corrosive in a household over months. | Family Highlights **Sum** (single number across the household) + Shared Joy Insight (category-level, no member attribution). Already in the locked list — keep it that way. |
| **"Joy ROI" as a family budget percentage** | The original `Happiness ROI` tile was this — joy as a fraction of total budget. Sounds analytical. | It's a category-mix metric in disguise (a family that spends 100% on rent has 0% "joy ROI"; a family that spends 100% on hobbies has 100%). It rewards mix-shifting toward soul over actual emotional state, which is the opposite of what the metric should measure. The v1.1 spec already calls this out as misleading and replaces it. | Keep the Joy Index / Joy per ¥ density metric; do not resurrect ROI framing in the family tile. |
| **Streak counter on satisfaction value** ("23-day streak of 8+!") | Standard fintech gamification; YNAB's Age-of-Money proves streaks work; Daylio uses streaks. | Streaks on *recording* are fine; **streaks on the satisfaction value itself** create direct pressure to inflate ratings to keep the streak alive. This is a documented bias in self-report scales (response inflation under reward-contingent reporting). | If streaks are added in v1.2+, scope them strictly to "days you logged a soul transaction" — never threshold the satisfaction value. **v1.1 should not add streaks at all** — the milestone is overcommitted already. |
| **Year-over-year / month-over-month joy comparison on home tile** | "Trend" feels insightful; Spotify Wrapped does year-over-year. | Same comparison-drives-dissatisfaction trap as the leaderboard, applied temporally instead of socially. Also creates pressure when last month had unusual spending (medical, travel) producing an unfair baseline. Spotify Wrapped works because it's annual-only and celebratory; finance apps showing monthly deltas tend toward judgmental ("you're 8% less happy than April"). | Show the trend **line within the current month** (already in scope) — that's process information, not judgment. Defer cross-period comparison to v1.2+ and frame as opt-in retrospective ("Year in Joy" report), not always-on home tile. |
| **AI-generated "interpretation" of the user's joy data** ("Your spending suggests you're happiest with food but that may be emotional eating") | Multiple JP/CN apps (叨叨记账, AI auto-categorization apps) lean on AI commentary; sounds insightful. | Two issues: (1) the local-first/zero-knowledge architecture makes server-side AI interpretation incompatible with the trust positioning; (2) algorithmic interpretation of satisfaction data is psychologically loaded — "your hobby spending is a coping mechanism" is the kind of message a finance app should not deliver. | Show data, let the user interpret. If a copy-style touch is wanted, fixed templates pulled from ARB ("今月のときめきは食べ物から！" with no judgment) are safer than generative output. |
| **Letting users edit Best-Joy-per-¥ to "promote" a different transaction** | "But the algorithm picked the wrong one — the actual best moment was the concert, not the cheap coffee" — sounds reasonable. | Once the metric is user-overridable it stops being a measurement and becomes a curated post; it also encourages re-rating transactions to get them onto the highlight card, which is the satisfaction-inflation trap from a different direction. | Keep the argmax algorithmic. If users complain that small purchases dominate, fix the formula (amount floor, log dampening — see Best Joy per ¥ row in Table Stakes) — don't add manual override. |
| **Public sharing of joy data with non-family** | Spotify Wrapped is publicly shareable; users will ask. | Public-share creates the same social-comparison harm as a leaderboard, plus exposes financial info that the local-first architecture is meant to protect. Even export-as-image risks this. | If sharing is added in v1.2+, scope strictly to **screenshot of the Best-Joy-per-¥ card** with amount redacted (e.g., `"¥¥¥¥"` placeholder), not raw indicators. |
| **Negative/penalty satisfaction scores or "regret" tag** | Symmetry argument: if you can mark a 10/10 purchase, you should be able to mark a 1/10 regret. | The 1-10 scale already encodes regret at the low end; adding a separate "regret" tag double-counts and creates a "shame ledger" subtitle that runs counter to the Joy Ledger framing. JP/CN cultural context especially: explicit regret labels feel punitive. | The 1-10 scale is enough. Anti-add. |

---

## Feature Dependencies

```
[Existing infra]
  soul_satisfaction column ──┬──> [Avg Satisfaction]
                              ├──> [Highlights count]
                              ├──> [Joy per ¥ density]
                              │       └──requires──> [unit-display strategy: per ¥1k]
                              ├──> [Best Joy per ¥ card]
                              │       ├──requires──> [amount-floor or log dampening]
                              │       └──requires──> [empty-state handling]
                              ├──> [Satisfaction distribution histogram]
                              │       └──unblocked-by──> getSatisfactionDistribution DAO
                              └──> [Joy per ¥ trend line]
                                      └──unblocked-by──> getDailySatisfactionTrend DAO

[Family sync (existing)]
  shadow books ──┬──> [Family Highlights Sum]
                 │       └──requires──> single-number rendering rule (NO per-member split)
                 └──> [Shared Joy Insight (category × avg sat)]
                          └──requires──> minimum-N guard (≥3 transactions per category)

[ARB rename pass]
  soulLedger / survivalLedger / homeHappinessROI / homeSoulFullness
       └──no code dependencies, but blocks "feels coherent" UX gate

[Anti-pattern conflicts]
  Per-member leaderboard ──conflicts──> Family Highlights Sum (mutually exclusive framings)
  Streak on satisfaction value ──conflicts──> all density metrics (causes inflation)
  Cross-month delta on tile ──conflicts──> "celebration not judgment" framing
```

### Dependency Notes

- **Joy per ¥ requires unit-display strategy:** raw `Σsat/Σamount` is unintelligible (~0.00012). Decide on `per ¥1,000` normalization (or equivalent for non-JPY locales) before wiring the home tile. This is a 30-min decision but it's a prerequisite for *any* density display.
- **Best Joy per ¥ requires divide-by-zero and outlier handling:** without an amount floor, a ¥10 satisfying snack will dominate. Consider `WHERE amount >= 100` plus tiebreaker by absolute satisfaction.
- **Family indicators require shadow-book aggregation:** depends on existing family-sync apply pipeline. The DAO methods may not yet support cross-shadow-book aggregation — verify in requirements step.
- **Empty-state is not optional:** Avg Satisfaction, Joy per ¥, and the Best moment card all break elegantly only if you handle "0 soul transactions this month" explicitly. New users will see this state; so will users mid-month-1.
- **Anti-features cluster around "comparison":** the three top anti-features (per-member leaderboard, year-over-year delta, public sharing) all share a common mechanism — they introduce comparison frames that the experiential-purchase research and self-report-bias research independently warn against. Treat "no comparison surfaces in v1.1" as a single design rule, not three separate rules.

---

## MVP Definition

The v1.1 milestone scope **is** the MVP for the happiness-metric domain. The locked feature list maps cleanly into MVP / Add-after / Future buckets:

### Launch With (v1.1)

All of these are already locked — listing them here for the requirements step to verify formulas + presentation align with industry practice.

- [x] **Avg Satisfaction tile** — period-summary headline number, empty-state safe
- [x] **Joy per ¥ tile** — density metric, unit-normalized to per-¥1k display
- [x] **Highlights count tile** — `COUNT WHERE sat ≥ 8` with non-configurable threshold
- [x] **Best Joy per ¥ story card** — argmax with amount-floor, no manual override, no cross-period comparison
- [x] **Satisfaction histogram** — wired through getSatisfactionDistribution
- [x] **Joy per ¥ trend line** — wired through getDailySatisfactionTrend, sparsity-handled
- [x] **Family Highlights Sum** — single household number, NO per-member split
- [x] **Shared Joy Insight** — category × avg satisfaction with min-N guard
- [x] **ARB rename pass** — Joy Ledger / Daily Ledger / Joy per ¥ / Joy Index across ja/zh/en

### Add After Validation (v1.2+)

Trigger: user feedback shows the v1.1 indicators are read and acted on, but users want more longitudinal context.

- [ ] **Year-in-Joy retrospective** — opt-in, celebratory framing only, no judgmental deltas; modeled on Spotify Wrapped
- [ ] **Per-category joy density** breakdown (drill-down on Shared Joy Insight) — needs minimum-N to avoid one-off events crowning a category
- [ ] **Anticipation board** — flagging *upcoming* planned soul purchases for higher pre-purchase satisfaction (per Gilovich research, anticipation of experiential purchases drives meaningful share of total happiness)
- [ ] **Recording streak** (record-action only, NEVER satisfaction-value streak) — requires careful copy
- [ ] **Mood/context tags** on transactions (alone / with family / as gift) — would unlock per-context joy density; needs schema change so genuinely v1.2+

### Future Consideration (v2+)

Trigger: product-market fit established, JP user base validates the cooperative-family thesis works.

- [ ] **Selective sharing** of Best-Joy card outside family (with amount redaction), if and only if the social-comparison risk can be designed around
- [ ] **Cross-family-member highlight celebration** ("Mom's best moment this month was…") — only if explicit recipient-driven (gift-style), never algorithmic and never ranked
- [ ] **Long-horizon joy trend** (12-month, lifetime) — only if presented as personal-only retrospective, not comparison
- [ ] **Photo attachment for memory cards** (Joy Money parity feature) — adds emotional weight but introduces non-trivial encrypted-blob storage and sync complexity

---

## Feature Prioritization Matrix

Within v1.1 scope (all P1 by milestone definition; relative ranking helps phase ordering and "if we have to cut something" decisions):

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Avg Satisfaction tile | HIGH | LOW | P1 |
| Joy per ¥ tile | HIGH | MEDIUM | P1 |
| Highlights count tile | MEDIUM | LOW | P1 |
| Best Joy per ¥ story card | HIGH (emotional centerpiece) | MEDIUM-HIGH (UI) | P1 |
| Satisfaction histogram | MEDIUM | LOW | P1 |
| Joy per ¥ trend line | MEDIUM | LOW-MEDIUM | P1 |
| Family Highlights Sum | HIGH (in group mode) | MEDIUM | P1 |
| Shared Joy Insight | MEDIUM-HIGH (in group mode) | MEDIUM | P1 |
| ARB rename pass | MEDIUM (positioning) | LOW | P1 |

**If overscoped:** the lowest-loss cut is Shared Joy Insight (depends on min-N guard logic, family aggregation, and copy that isn't judgmental about lower-ranked categories — three risk surfaces in one feature). Family Highlights Sum carries most of the "family mode feels real" value alone.

**Highest-leverage feature:** **Best Joy per ¥ story card.** Industry pattern (Spotify Wrapped, Joy Money's memory cards) shows that a single celebrated moment outperforms multiple metric tiles in shareability and emotional recall. The four metric tiles together establish the *system*; the Best card gives the user *the take-home memory* of the month. Spend UI polish budget here.

---

## Competitor Feature Analysis

| Feature | Joy Money (JP, pre-launch) | OsidOri (JP, shipped) | マネーフォワード ME / Zaim (JP, shipped) | 叨叨记账 / 鲨鱼记账 (CN, shipped) | Daylio (mood, shipped) | Our Approach |
|---|---|---|---|---|---|---|
| Per-transaction satisfaction | 5-point scale | None | None | None | 5-point mood | 1-10 + emoji input (already shipped) |
| Avg Satisfaction summary | Implied (graphs) | N/A | N/A | N/A | Yes (monthly mood avg) | Explicit tile |
| Joy / ¥ density metric | No (graphs only) | N/A | N/A | N/A | N/A (not finance) | **Headline tile + trend line** |
| Highlights count | No | N/A | N/A | N/A | "Great days" count | Tile (sat ≥ 8) |
| Argmax highlight card | "Memory cards" per-transaction (not aggregate) | N/A | N/A | "Peak moment" pushes (notification copy) | N/A | **Aggregate Best card** |
| Histogram of satisfaction | No | N/A | N/A | N/A | Yes (mood distribution) | Yes |
| Trend line over period | Implied (graphs) | N/A | N/A | N/A | Yes (mood line) | Yes |
| Family/group mode | No | Yes (shared+personal split, no joy aggregation) | Yes (Zaim group, no joy concept) | Limited | N/A | **Cooperative joy aggregation (novel)** |
| Family ranking / leaderboard | N/A | No | No | No | N/A | **Explicitly NO** |
| Local-first / encrypted | Unknown (presumed cloud) | Cloud | Cloud (bank-linked) | Cloud | Local | Local + E2EE (already shipped) |
| Cultural framing | 推し活 fan-activity | Couples / shared | Generic budgeting | Young women, light gamification | Generic mood | 悦己 / ときめき / Joy (rename pass) |

**Strategic read:** No competitor occupies the (joy-density × cooperative-family × encrypted-local) intersection. Joy Money owns single-user joy visualization in JP; OsidOri owns shared-budget UX in JP; nobody owns family-cooperative joy. v1.1 is genuinely competing for new ground.

---

## JP/CN market specifics (extra emphasis per quality gate)

### JP market

- **推し活 (oshi-katsu)** is the dominant cultural vector for "happy spending" in JP, particularly among 20-30s women. Joy Money and 推しPay both target it explicitly. Our renamed "ときめき帳 / Joy Ledger" copy should resonate without forcing the oshi-katsu frame (we want general use, not niche).
- **自分へのご褒美 (a reward for myself)** is the equivalent norm one demographic over (30-40s, less media-fan-coded). Joy Index tile copy should accommodate both reads.
- **OsidOri's "shared + personal" split** is the JP-recognized best practice for couples-finance UX. The fact that we surface joy *only on the cooperative side* of the family fits this convention — soul transactions on individual phones stay individual; only highlights *count* (not per-person joy) is shared. Worth verifying explicitly in requirements step.
- **Privacy expectation** in JP family-finance is higher than in EN markets — partners typically don't want full visibility into each other's discretionary spending. The cooperative-only family aggregation respects this; per-member breakdown would violate it.
- **Visual sensibility:** JP finance apps (Zaim particularly, "good design award") favor cute icons and small celebratory animations on entry. Our soul-green (#47B88A) celebration on highlight count being incremented is consistent with this; resist the temptation to import Western dashboard severity.

### CN market

- **悦己消费 (yue-ji xiao-fei, "self-pleasing consumption")** is the directly-translated cultural concept; "悦己账本" as a name is already in idiomatic territory.
- **仪式感 (yi-shi-gan, "sense of ceremony")** is the design language CN apps (iCost, 叨叨记账) ride hard — "completing a record produces a beautifully designed receipt image". Best-Joy-per-¥ as a story card slots directly into this aesthetic vocabulary; even more shareable in CN context than JP.
- **Anti-pattern in CN market:** AI-character-driven "chat to record" (叨叨记账) gives users a virtual companion that reacts to records. Tempting differentiator, but **incompatible with local-first/encrypted positioning** (requires server-side AI). Anti-feature for us.
- **复盘 (fu-pan, "review")** is the standard term for monthly retrospective in CN financial culture; the v1.1 statistics-page work is "悦己复盘". Worth using in CN ARB copy.

### EN market context (third locale)

- Less rich on this specific feature niche; Happy Money's Joy app is the closest reference but is a coaching/personality product, not a metric one. YNAB's "Age of Money" is the only quantitative-density metric with mainstream EN traction.
- "Joy Ledger / Daily Ledger / Joy per ¥ / Joy Index" lexicon as renamed should read cleanly in EN — no equivalent cultural baggage to worry about.

---

## Quality-gate self-check

Verifying against the consumer's quality gate stated in the prompt:

- ✅ **Categories clear** — Table Stakes (6 features), Differentiators (6), Anti-Features (8); each row has Why/Complexity/Notes.
- ✅ **Complexity noted** — every feature row has LOW/MEDIUM/HIGH with reasoning.
- ✅ **Dependencies identified** — diagram + 5-point dependency notes; conflicts called out (3 anti-features × 1 design rule).
- ✅ **JP/CN market practice covered** — dedicated section with five JP-specific findings, four CN-specific findings, and EN noted briefly. Joy Money and OsidOri called out as direct/adjacent prior art.
- ✅ **Family-mode dynamics analyzed with concrete examples** — per-member leaderboard anti-feature has explicit "Mom 8.2 ≫ Dad 6.1" example and Gilovich-research justification; OsidOri's shared-vs-personal split discussed; cooperative-aggregation pattern grounded.
- ✅ **Anti-features called out explicitly with reasoning** — 8 anti-features each with surface appeal / actual problem / alternative.
- ⚠️ **Limitation:** Joy Money is a CAMPFIRE crowdfunding project, so its actual shipped behavior is not yet observable; statements about Joy Money are based on the project's own marketing material. Confidence on Joy Money specifics is MEDIUM, not HIGH.

---

## Sources

### Direct prior art (HIGH relevance)
- [Joy Money — CAMPFIRE crowdfunding (推し活×幸福度×思い出 visualization app)](https://camp-fire.jp/projects/883660/view) — almost-identical core concept; pre-launch
- [推しPay — Apps on Google Play](https://play.google.com/store/apps/details?id=com.nosuke.oshi_pay)
- [推し活支出管理 — App Store JP](https://apps.apple.com/jp/app/%E6%8E%A8%E3%81%97%E6%B4%BB%E6%94%AF%E5%87%BA%E7%AE%A1%E7%90%86/id1503878877)
- [Touch Tech 京都橘大学 — 推し活感覚で続けられる家計簿アプリ (academic-style related project)](https://www.tachibana-u.ac.jp/admission/touchtech/project10.html)

### JP family-finance UX baseline
- [共有できる家計簿アプリ 9選ランキング — マイベスト](https://my-best.com/22600)
- [OsidOri — 共有家計簿アプリ おすすめ10選 (shared+personal split rationale)](https://osidori.co/magazine/%E5%85%B1%E6%9C%89%E3%81%A7%E3%81%8D%E3%82%8B%E5%AE%B6%E8%A8%88%E7%B0%BF%E3%82%A2%E3%83%97%E3%83%AA%E3%81%8A%E3%81%99%E3%81%99%E3%82%8110%E9%81%B8/)
- [Zaim vs マネーフォワードME 比較 — マネーリーフ](https://www.money-leaf.net/paid-zaim-moneyforwardme-comparison/)
- [女性が選ぶ家計簿アプリランキング — PR TIMES (満足度1位データ)](https://prtimes.jp/main/html/rd/p/000000023.000057067.html)

### CN finance-app UX patterns
- [APP+1｜八款记账App评测 — 少数派 (iCost ceremony-design pattern)](https://sspai.com/post/76557)
- [叨叨记账APP的爆火套路 — 人人都是产品经理 (peak-moment notification design)](https://www.woshipm.com/operate/4396844.html)
- [挑选一款简单好用的 iOS 记账 App — 知乎](https://zhuanlan.zhihu.com/p/449989651)

### Mood / wellbeing dashboard prior art
- [Daylio Journal — Mood Tracker (5-point scale, histogram, monthly line graph)](https://daylio.net/)
- [Daylio: mood-quantification — PMC academic study](https://pmc.ncbi.nlm.nih.gov/articles/PMC5344152/)
- [Apple Activity Rings — HIG Components](https://developers.apple.com/design/human-interface-guidelines/components/status/activity-rings/)
- [Headspace My Progress / mood reflection feature](https://help.headspace.com/hc/en-us/articles/360048720853-What-is-the-My-Progress-Feature)

### Story-mode / argmax-card pattern
- [Spotify 2025 Wrapped UX writeup — Spotify Newsroom](https://newsroom.spotify.com/2025-12-03/2025-wrapped-user-experience/)
- [Spotify Wrapped design aesthetic 2025 — Envato Elements](https://elements.envato.com/learn/spotify-wrapped-design-aesthetic)

### Couples / shared finance, anti-leaderboard adjacent
- [Honeydue — Couples Finance App Store listing](https://apps.apple.com/us/app/honeydue-couples-finance/id1157633945)
- [Splitwise vs Honeydue — SmartFinancePick](https://smartfinancepick.com/splitwise-vs-honeydue-splitting-bills-for-couples/)
- [Koody Shared Budget App — design philosophy](https://koody.com/blog/shared-budgeting-app-for-couples)

### Academic / research foundations
- [Gilovich, Kumar, Jampol — Experiential consumption and the pursuit of happiness (PDF)](https://static1.squarespace.com/static/5394dfa6e4b0d7fc44700a04/t/547d589ee4b04b0980670fee/1417500830665/Gilovich+Kumar+Jampol+(in+press)+A+Wonderful+Life+JCP.pdf)
- [Consumers' pursuit of material and experiential purchases — Gilovich 2020 review](https://myscp.onlinelibrary.wiley.com/doi/abs/10.1002/arcp.1053)
- [The Welfare Effects of Social Media — Allcott et al. (Stanford PDF)](https://web.stanford.edu/~gentzkow/research/facebook.pdf)
- [Response bias in self-reports — PNAS](https://www.pnas.org/doi/10.1073/pnas.2412807122)

### Happiness-app / fintech-gamification context
- [Happy Money's Joy App — psychology-based money app](https://happymoney.com/press/happy-money-launches-joy,-the-first-money-app-powered-by-psychology)
- [Gamification in Financial Apps — DashDevs](https://dashdevs.com/blog/gamification-in-financial-apps-unlocking-new-opportunities-for-growth-and-engagement/)
- [YNAB — value-aligned spending philosophy](https://www.ynab.com/)
- [Monarch Money vs YNAB — Motley Fool comparison](https://www.fool.com/money/personal-finance/monarch-money-vs-ynab/)

---
*Feature research for: Personal/family finance app — happiness-metric domain (v1.1 scope)*
*Researched: 2026-05-01*
