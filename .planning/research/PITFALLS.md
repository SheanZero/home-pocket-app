# Pitfalls Research — v1.1 Happiness Metric & Display

**Domain:** Subjective wellbeing metrics layered on top of an existing dual-ledger personal-finance app, with family-mode comparison
**Researched:** 2026-05-01
**Confidence:** HIGH (formula edge cases grounded in arithmetic; cultural/behavioural pitfalls grounded in published research and Japan Cabinet Office findings)

> Note: This file replaces the v1.0 PITFALLS.md (cleanup-initiative scope). v1.0 pitfalls have been migrated into the long-running `CLAUDE.md` "Common Pitfalls" list and CI guardrails; they no longer need a research deliverable. This v1.1 file is scoped to the milestone's four phases:
>
> - **Phase 9** — Domain & formula layer (use cases, DAO filtering, deterministic outputs)
> - **Phase 10** — HomePage `SoulFullnessCard` redesign (replaces misleading Happiness ROI)
> - **Phase 11** — Statistics screen wiring (3 dormant DAOs → AnalyticsScreen)
> - **Phase 12** — UI rename pass (ARB-only, ja/zh/en)

---

## Critical Pitfalls

### Pitfall 1: Formula scope leak — `soul_satisfaction` defaulting to 5 on Survival ledger transactions pollutes every aggregation

**What goes wrong:**
Every survival-ledger transaction silently carries `soul_satisfaction = 5` (the schema default). If any of the four personal indicators or two family indicators forget to filter `WHERE ledger_type = 'soul'`, the result is mathematically correct but semantically meaningless: "Avg Satisfaction" reflects neutral ratings on grocery receipts, "Highlights count" stays at zero (5 < 8), and **"Joy per ¥" gets dragged toward zero by huge survival-side denominators** (rent, utilities). A user who buys a ¥80,000 desk lamp (sat=10) and pays ¥120,000 rent (sat=5 default) will see Joy per ¥ ≈ (10+5)/(80000+120000) = 0.000075, when the true joy density of that desk lamp is 10/80000 ≈ 0.000125 — a **40% understatement** purely from survival contamination.

**Why it happens:**
- The `soul_satisfaction` column lives on `transactions` (a single table for both ledgers), not on a soul-only sub-table. Schema makes the filter implicit, not explicit.
- The 3 dormant DAO methods (`getSoulSatisfactionOverview` / `getSatisfactionDistribution` / `getDailySatisfactionTrend`) were written in v1.0 era; their `WHERE` clauses must be re-verified now that they will be exposed.
- Use-case authors writing new aggregations (Joy per ¥, Highlights, Best Joy per ¥, Family Highlights Sum, Shared Joy Insight) will reach for `transactions.soul_satisfaction` without thinking about the ledger filter.
- Tests written from "happy path" rarely include a survival-ledger row in fixtures, so the contamination passes CI silently.

**How to avoid:**
- **Single source of truth:** Add a `_soulOnly()` SQL fragment helper in the DAO layer that returns the canonical `WHERE ledger_type = 'soul' AND deleted_at IS NULL` clause. Every metric query composes from it; no inline `ledger_type` filters scattered across queries.
- **DAO test matrix:** For each of the 6 metrics, add a test fixture with 2 soul rows + 2 survival rows + 1 deleted soul row. Assert that survival rows and deleted rows are excluded from the result — not just that "the soul rows are correct."
- **Type-level isolation:** Wrap the DAO output in a `SoulOnlyMetric<T>` value class so callers cannot accidentally hand it raw `transactions` rows.
- **Comment the schema:** Add a `// SCOPE: soul-only` annotation to every Use Case file in `lib/application/analytics/happiness/` so the convention is grep-able.

**Warning signs:**
- A metric value moves significantly when survival transactions are added/removed in a session.
- "Avg Satisfaction" ≈ 5.0 ± 0.5 in production (suspicious clustering — see Pitfall 5).
- Joy per ¥ varies inversely with survival-spend volume rather than soul-spend joy.
- Code review finds `transactions.soul_satisfaction` referenced in an aggregator without an adjacent `ledger_type` check.

**Phase to address:** **Phase 9 (domain/formula layer).** Lock the `_soulOnly()` fragment in the first PR of Phase 9; require all subsequent metric PRs to compose from it. Add an arch test (`test/architecture/happiness_scope_test.dart`) that greps for `soul_satisfaction` outside DAO files and fails if any reference lacks a co-located `ledger_type='soul'` literal or `_soulOnly()` call.

---

### Pitfall 2: Joy-per-¥ tiny-amount domination — ¥10 transactions crowd out the leaderboard

**What goes wrong:**
"Best Joy per ¥" is `argmax(satisfaction / amount)`. With satisfaction bounded at [1,10] and amount ranging from ¥10 (a vending-machine coffee) to ¥80,000 (a concert ticket), the density ratio spans **four orders of magnitude**. A ¥10 candy with satisfaction=10 has density 1.0; a ¥80,000 ticket with satisfaction=10 has density 0.000125. **The candy wins by 8000×.** Every "Best of the month" story card becomes "you bought a snack" — the feature trivializes itself in week one. Worse, on the trend line (Phase 11), a single ¥10 high-sat purchase creates a vertical spike that compresses every other day to a flat baseline, making the chart unreadable.

**Why it happens:**
- The formula is mathematically correct but ignores that *amount* has a log-normal distribution while *satisfaction* is bounded linear.
- "Argmax of a ratio over heterogeneous denominators" is a known pathology in micro-economics (the "small-base effect"); analysts encounter it in CTR / CVR reporting all the time and apply prior-smoothing or amount-floors.
- Designers framing "the small joy can beat the big one" rhetorically (the milestone's own copy) get blindsided by the arithmetic edge case.

**How to avoid (apply at least one — recommended: combine 1 + 3):**
1. **Amount floor:** Drop transactions below an amount threshold (suggest ¥500 — covers vending machine, single coffee, snack) from "Best Joy per ¥" candidate set. Tunable per locale (¥500 ≈ $3.40 ≈ ¥25 RMB which is ~一杯奶茶). Floor applies only to the "Best" *highlight selection* — does **not** affect the average Joy per ¥ headline (would suppress legitimate small joys from the density numerator/denominator).
2. **Bayesian shrinkage / category prior:** Smooth the per-row density toward the user's per-category mean: `shrunk_density = (satisfaction + α·μ_cat) / (amount + α·N_cat)`. Pulls extreme small-amount rows toward the typical ratio. Higher engineering cost; implement only if (1) is insufficient.
3. **Display amount alongside the highlight:** The story card always shows "¥{amount} · 満足度{sat}/10 · 密度{density}". When users see `¥10` next to a winning highlight, they self-correct. Mitigates UX harm even when the formula stays raw.
4. **Amount-bucket tournament:** Pick the best within each of 3 amount buckets (small/medium/large) and rotate the highlight card. Higher complexity; defer to v1.2 if users complain.

**Warning signs:**
- "Best Joy per ¥" highlight is a sub-¥100 purchase 3+ months in a row.
- Joy per ¥ trend line (Phase 11) has spikes >5× the median value.
- User testing comments include "なんで毎月コンビニ?" / "为什么总是便利店？" / "Why is it always 7-11?"
- Formula output's standard deviation across days is dominated by 1–2 outlier days.

**Phase to address:** **Phase 9 (formula)** for amount-floor decision; **Phase 10 + Phase 11** for displaying amount on the highlight card and considering chart Y-axis log scale. Lock the floor value in Phase 9 with a test fixture proving sub-floor candies are excluded from "Best" but counted in "Avg Satisfaction" and "Joy per ¥" headline.

---

### Pitfall 3: Voice estimator upward bias compounds invisibly across all four personal metrics

**What goes wrong:**
The existing `VoiceSatisfactionEstimator` pre-fills satisfaction with **+0.3 upward bias** (per the milestone context). Users accept the pre-fill in ~60–80% of voice entries (typical survey-default acceptance rate). Compounded across all soul transactions in a month, this lifts every personal metric:
- **Avg Satisfaction:** systematically inflated by ~0.18–0.24 points (≈ +2–3% on a 1–10 scale).
- **Highlights count (sat ≥ 8):** the threshold sits near the edge of the bias-inflated peak; a true-7.7 entry getting voice-estimated to 8.0 flips it into "highlight" status, **inflating count by 8–12%**.
- **Joy per ¥:** numerator gets +0.18 per row but denominator unchanged, lifting density by 2–4%.
- **"Best Joy per ¥":** voice entries are systematically more likely to win the argmax over manually-entered ones.

The user sees a happiness graph that **cannot trend down** because the input pipeline has built-in optimism. When the user inevitably has a bad month, the graph contradicts their lived experience and they distrust the app.

**Why it happens:**
- The voice estimator was built in isolation as a UX convenience (faster entry); its statistical impact on aggregates was not analyzed because aggregates didn't exist yet.
- The +0.3 bias was likely tuned against "users abandon voice entry if the default feels too low" — a UX KPI, not an analytic-truth KPI.
- v1.1 elevates the estimator's output from "single-row UX preview" to "input to four headline indicators" without recalibrating the estimator.

**How to avoid:**
- **Don't fix the estimator in v1.1** (out of scope; risks breaking voice-flow). Instead **disclose** in Phase 10 copy: a small "ⓘ" tap-target on Avg Satisfaction that explains "音声入力時は推定値を含む / 语音输入含估算值 / Voice entries include estimates."
- **Track entry source:** If `transactions.entry_source` exists or can be added without schema change (check pre-Phase-9 — milestone says "no schema"), use it to compute a **manual-only sub-metric** for users who want the unbiased number. If schema is locked, ship a v1.2 ticket: "add `entry_source` column + recalibrate voice bias."
- **Defensive test:** Phase 9 unit test asserts that on a fixture of 30 voice-entered rows + 30 manual rows with identical *true* distribution, the voice-side aggregates are within +0.3 of manual side — i.e. surface the bias quantitatively in CI so any future estimator change updates the assertion.
- **Document the bias on the chart axis** in Phase 11: the histogram caption should note "estimator-included" so analysts can mentally adjust.

**Warning signs:**
- Avg Satisfaction in production never drops below 5.5 even when transaction volume is low.
- Highlight ratio (highlights / total) is structurally above 25% across the user base.
- Customer-support tickets: "this number doesn't match my real feelings."
- Distribution histogram (Phase 11) has a notch immediately *below* 8 (users push toward 8 to hit "highlight").

**Phase to address:** **Phase 9** (test for bias quantification, decide on disclosure copy); **Phase 10** (info icon on Avg Satisfaction card); **Phase 11** (caption on histogram). v1.2 backlog: estimator recalibration + `entry_source` column.

---

### Pitfall 4: Default-value pollution at sat=5 — central-tendency bias amplified by missed inputs

**What goes wrong:**
Three default-value pathways all feed `5` (neutral midpoint) into the satisfaction column:
1. Survival-ledger rows store 5 implicitly (mitigated by Pitfall 1's filter, but only if filter is enforced).
2. Soul rows where the user dismisses the satisfaction picker without choosing → 5.
3. OCR-imported soul rows with no user review → 5.

Once persistent, these "neutral default" rows are statistically indistinguishable from genuine "I felt neutral about this" rows. **The metrics cannot tell apathy from missing data.** Worse: published research shows Japanese, Korean, and Chinese respondents already **systematically cluster their wellbeing Likert responses toward the middle** (Japan Cabinet Office, 2010; Keio SDM thesis 2014) — this is documented as a confound when comparing East Asian vs Western happiness scores. The v1.1 user base is overwhelmingly JP/CN. Combining cultural midpoint-bias with default-pollution produces a histogram that is a **single tall bar at 5** with everything else as noise. The "Highlights count" feature compensates by offering a count of ≥8, but if 70% of inputs are at 5, the highlights feature loses its denominator.

**Why it happens:**
- Default-value design pre-dated the metrics layer; was chosen for UX reasons (form completion) without considering aggregation semantics.
- East-Asian central-tendency bias is invisible to teams researching using English-language happiness-app literature (which is overwhelmingly US/Western-sample-based).
- The midpoint of a 1–10 scale "feels neutral" but is a **weak prior** — a true distribution of voluntary spending should skew positive (people spend on things they expect to enjoy).

**How to avoid:**
- **Distinguish "missing" from "neutral":** Soul rows where the user explicitly tapped the picker should record a flag (or use a sentinel like `0` or `null`) for unrated. If schema-locked, infer it: rows where `soul_satisfaction = 5 AND created_via IN ('ocr_auto','quick_add')` should be **excluded** from Avg Satisfaction (treated as missing). This is a reversible filter — does not modify data.
- **Show coverage explicitly:** Phase 10 card shows "Avg Satisfaction: 7.4 (based on 23/31 rated entries this month)". Users see when the sample is thin.
- **Use median, not mean, for the headline number** — median is robust to a default-5 cluster. Already common in JP wellbeing research for this reason. (Trade-off: less sensitive to genuine improvement; but the milestone's chosen formula is "mean" — so this requires a decision in Phase 9. Recommend offering both: headline = mean, secondary tooltip = median, with a "n=" sample size.)
- **Distribution chart with annotation** (Phase 11): the histogram should color the `5` bar differently and label "中央値・含未評価 / 中点·含未评 / Midpoint (incl. unrated)" so the cluster is contextualized rather than misread as "users are neutral."

**Warning signs:**
- Histogram (Phase 11) has a single bar at sat=5 that is >40% of total.
- Avg Satisfaction barely moves between months despite transaction volume changes.
- Median ≠ mean on the same dataset (a quick health-check).
- Highlights count is structurally low (<10% of soul transactions) across all users.

**Phase to address:** **Phase 9** (decide median vs mean; decide whether to filter `5+ocr_auto`); **Phase 10** (display coverage "n=23/31"); **Phase 11** (histogram annotation for the `5` bar). Defer schema-level "rated/unrated" flag to v1.2.

---

### Pitfall 5: Family-mode comparison toxicity — the difference between a leaderboard and a cooperative metric

**What goes wrong:**
The milestone explicitly chose "反对抗、合作型" (anti-adversarial / cooperative) family indicators (Family Highlights Sum + Shared Joy Insight). This is the right intent, but **how the indicators are computed and rendered determines whether users perceive them as cooperative or competitive.** Two specific failure modes:

1. **Implicit ranking from sum:** Family Highlights Sum is the sum across members. If the UI breaks this down by member ("Mom: 8, Dad: 3, Sister: 12"), it becomes a leaderboard the moment a parent looks at it. Yu-kai Chou (gamification design) and the IxDF / UI-Patterns literature both note: leaderboards are inappropriate for activities that aren't competitive in nature, and family contexts are a textbook case. The Marie Kondo / ときめき framing this milestone borrows is fundamentally **personal and non-comparable** ("does *this* spark joy *for you*"); turning it into ranked counts inverts the philosophy.

2. **Privacy/safety harm via emotional surveillance:** The 2020 Oxford Cybersecurity paper "Privacy threats in intimate relationships" documents that intimate-partner abuse routinely escalates from financial-data access to emotional-state monitoring. Satisfaction scores are **more sensitive than amounts** — a partner can deduce "she rated her solo-coffee at 9 and our anniversary dinner at 4" with deeply harmful results. Sibling-comparison literature (Wolter 2003 IZA; Dove Self-Esteem Project) shows that **parent-initiated comparisons produce significantly more jealousy than sibling-initiated comparisons**, and that comparisons across "soft" dimensions (emotion, body, social) are more harmful than across achievement dimensions. A child seeing "Mom: high joy density / Me: low joy density" lands in this exact harm zone.

**Why it happens:**
- The natural way to compute "family X" in code is `members.map((m) => m.metric).reduce(sum)` and the natural way to display it is "show each member's contribution" — both correct engineering, both produce ranking pressure.
- "Cooperative" gets interpreted as "show the same thing, just for the family" instead of "show only what is genuinely additive across members."
- Privacy treatment of `amount` (already sensitive) gets reused for `satisfaction` without re-evaluating that satisfaction is a **disclosed emotional state**, which has a higher legal/ethical bar in most jurisdictions (GDPR Art.9 special-category personal data argument is plausible for self-reported wellbeing).

**How to avoid:**
- **Aggregate-only rendering:** Family Highlights Sum is shown as a single number ("家族の小確幸: 23 / family Joy moments: 23"). **Never break down by member.** Per-member breakdown is the privacy/toxicity attack surface; refusing to render it is the simplest defense. If the user taps for detail, show *categories* ("snacks: 8, books: 6, outings: 9") — items, not people.
- **Shared Joy Insight is one line of copy, not a chart:** "Top category by avg satisfaction: 本 / 书籍 / Books" — no per-member contribution shown. Mention sample size only if needed for honesty (>= N members reported in this category).
- **Avoid satisfaction values in any per-member surface:** the existing per-member transaction list is fine (already privacy-policy'd), but any *new* widget that shows `member.name + member.satisfaction` is a hard NO. Add a lint or code-review checklist item: "Does this widget render `(member, satisfaction)` together? If yes, justify."
- **Group-mode gating with explicit consent:** Per the milestone, family metrics show only in group mode. Phase 10 should **also** require that all members have opted into shared analytics — a single member's privacy refusal collapses the family card to a placeholder ("Family metrics paused — all members must opt in").
- **Wabi-sabi framing in copy:** the JP/CN copy in Phase 12 should avoid superlative / competitive language ("最高", "ランキング", "排行"). Prefer "今月の家族のときめき" / "本月家族的小确幸" — present-tense, additive, no comparison. (Cross-reference Pitfall 8.)

**Warning signs:**
- Any UI mockup showing `member_name + sat_value` in the same row.
- Per-member contribution stacked-bar charts showing up in the Phase 11 stats redesign.
- User testing produces "妈妈/お母さん why is your number bigger?" type comments.
- A family-mode A/B has higher session length but lower app-store rating.

**Phase to address:** **Phase 9** (lock the aggregate-only DAO contract — DAO returns `int` for Family Highlights Sum, **never** `Map<MemberId, int>`); **Phase 10** (UI consent gate + aggregate-only rendering); **Phase 12** (non-comparative copy in all 3 locales).

---

### Pitfall 6: Hedonic adaptation drift — Joy per ¥ trends downward over time and the app feels like it's accusing the user

**What goes wrong:**
Hedonic adaptation (Wikipedia: "hedonic treadmill"; Dorset Wealth 2024 review) is the documented psychological phenomenon where humans return to a baseline happiness level after positive events. **Applied to a metric:** as users get accustomed to their soul-spending, satisfaction ratings on similar purchases drift down over months — a ¥3000 cafe trip rated 9 in January gets rated 7 in June not because the cafe got worse, but because the user's reference point shifted. The Joy-per-¥ trend line (Phase 11) will therefore have a **systematic downward bias** that has nothing to do with spending choices.

The user sees a graph that goes down over time and concludes one of: (a) "I'm spending wrong" (false), (b) "the app is broken" (false), (c) "I'm becoming less able to feel joy" (potentially harmful self-narrative). None of these are the truth ("you have adapted, which is normal").

**Why it happens:**
- Self-report Likert measures of subjective state are **relative to the rater's recent reference frame**, not absolute. This is well-documented in the OECD subjective-wellbeing methodology guidelines.
- Trend lines invite "is it going up or down?" reading; users expect "going up = good."
- The spending-variety remediation (BMC Psychology 2024, "Does variety in hedonic spending improve happiness?") shows variety attenuates adaptation, but this is a **user-behavior remedy**, not a **chart-design remedy**.

**How to avoid:**
- **Window the trend, don't extrapolate:** Phase 11 should show the trend as **month-to-date vs same-period last month**, not a 6-month or 12-month line. Adaptation operates over months; a single-month window collapses the effect to noise.
- **Rolling baseline reset:** Anchor the y-axis to a rolling-window mean rather than absolute zero. Visually: "vs your typical month" not "absolute density." The chart still shows up/down, but adaptation drift becomes the new zero.
- **Copy choice:** the Phase 11 chart caption should frame it as "今月の傾向 / 本月趋势" rather than "成長 / 增长" or "improvement." Avoid teleological framing.
- **In-app explainer (one-time):** Phase 10's `ⓘ` info modal on Joy per ¥ briefly explains the concept ("感じ方は時間とともに変わる / 感受会随时间变化") so users self-narrate adaptation rather than self-blame. ~40 chars per locale, not a wall of text.
- **Variety nudge (defer to v1.2):** if a user's category mix is narrow, Shared Joy Insight could surface "新しいジャンルを試してみる？" — but **only as a question, never a prescription** (gamification of variety creates Pitfall 7).

**Warning signs:**
- 30-day or 90-day Joy-per-¥ trend has a slope < 0 across the user base average.
- Customer support: "the chart keeps going down even though I'm enjoying my purchases."
- Retention drops at month 3–6 (when adaptation typically becomes visible).

**Phase to address:** **Phase 11** (window selection, baseline anchoring, copy); **Phase 10** (info modal). No Phase 9 work — the formula is correct; this is a chart-framing problem.

---

### Pitfall 7: Goodhart's Law — the metric becomes the target and users learn to game it

**What goes wrong:**
Goodhart's Law: "When a measure becomes a target, it ceases to be a good measure." (Strathern 1997 reformulation; Wikipedia.) Once a satisfaction-based metric is exposed as a headline number, users adapt their **rating behavior** (cheap) rather than their **spending behavior** (the actual goal). Three concrete gaming patterns observed in self-tracking apps:

1. **Rating inflation:** users learn that rating everything ≥8 produces a rising "Highlights count" and feel-good chart. Over weeks, the rating distribution flattens to a high plateau and the metric stops differentiating.
2. **Selective entry:** users stop logging soul transactions they "wouldn't be proud of" (a lukewarm meal, a regretted impulse purchase). The Avg Satisfaction climbs not because life improved, but because the survey sample got curated.
3. **Streak protection / FOMO behavior:** documented in finance-gamification literature (11FS / Smartico / Yu-kai Chou) — users do harmful things (e.g. unnecessary spending) to keep a daily-entry streak alive. Specific to Home Pocket: a user might enter a fake "highlight" purchase to nudge the count past a perceived threshold.

The Facebook/Instagram engagement-vs-wellbeing case (cited in the Goodhart's Law literature search) is the cautionary archetype: prioritizing engagement metrics created teen-mental-health harm. A finance app with a happiness chart is structurally analogous if not designed defensively.

**Why it happens:**
- Headline metrics anchor user attention. The brain optimizes for what is visible.
- The current entry flow (Satisfaction Emoji Picker, Voice Estimator) is fast and low-friction, which is good for completion but means rating is *cheap to manipulate* (no friction = no commitment).
- v1.1 explicitly elevates these previously-private inputs into headline displays.

**How to avoid:**
- **No streaks, no badges, no daily targets in v1.1.** This is the single highest-leverage decision. The milestone is currently silent on this — recommend **Phase 9 product decision: explicitly ban streak/badge mechanics from v1.1 and document the ban in `docs/arch/03-adr/ADR-XXX_No_Gamification_v1_1.md`**.
- **No targets visible to user:** never display "you need 3 more highlights to beat last month." Comparing to last month is fine *as data*; framing it as a *goal* is the trap.
- **Rating distribution health-check (internal-only):** Phase 11 backend (not UI) computes per-user rating-entropy. If a user's ratings collapse to a single value (entropy → 0), an *internal* signal flags this — used to detect gaming, not to nudge the user. Do not surface this to the user (would create meta-gaming).
- **Friction for high ratings (light touch):** if a user rates ≥9, the picker can confirm "本当に最高？" — once. Just enough hesitation to prevent reflex-9 ratings. Trade-off vs UX speed; pilot in Phase 10 and back out if completion drops.
- **Don't reward category breadth either** (avoiding the Pitfall 6 v1.2 trap): "try a new category" is a question, never a metric.

**Warning signs:**
- Per-user rating entropy declines over a 90-day window.
- Highlight ratio (highlights / soul tx count) > 50% at the population level.
- A single user's distribution becomes bimodal at 1 and 10 (the "gaming bipolar" signature).
- App Store reviews mentioning "I rate everything 10 to keep my chart up."

**Phase to address:** **Phase 9** (product-decision ADR banning streaks/badges); **Phase 10** (no daily targets in card copy); **Phase 11** (entropy health-check in DAO, internal-only). No code-level gates, but the ADR is mandatory.

---

### Pitfall 8: Cultural framing — "happiness" / "幸福" / "ハピネス" carries different weight in JP/CN/EN; midpoint clustering is a real demographic effect

**What goes wrong:**
Three orthogonal framing problems specific to the JP/CN markets:

1. **"Happiness" feels heavy in Japanese:** 「幸福」 is closer to existential "well-being / a life well-lived" than to the everyday English "happiness." Using it as a headline label for a coffee-purchase satisfaction score is **scale-mismatched** — the user reads it as "this app is asking me to evaluate my entire life" rather than "rate this purchase." The milestone has already correctly chosen 「ときめき」 (Marie Kondo's Spark Joy term) for soul ledger and 「ハピネス密度」 for ROI. **However**, internal-doc references and developer copy still use 「幸福度」 — risk of leaking the heavier word into UI through inconsistent translations.
2. **「悦己」 (Chinese) carries solo / self-indulgence connotations:** 悦己 (yuè jǐ) literally is "please oneself" — it skews toward solo personal-treat semantics. For *family-mode* indicators, this label can feel mismatched ("家族悦己?" — please oneself, with family?). Phase 12 must verify the Chinese family-mode strings don't compose 悦己 with 家族 in ways that produce odd phrasing.
3. **Central-tendency bias in JP/KR/CN respondents** is a documented demographic confound (Japan Cabinet Office 「幸福度に関する研究会」 reports; Keio SDM thesis 2014; NRI 2024 lifestyle survey). The histogram (Phase 11) will look fundamentally different from a US/EU app. **A "tall middle, thin tails" distribution is normal here, not pathological.** A team applying Western histogram-design heuristics ("if the middle is overrepresented, increase friction") will misdiagnose.

**Why it happens:**
- Translation reviews focus on lexical accuracy ("does 幸福 mean happiness? yes"), not register / weight ("does it carry the same conversational weight as 'happy'? no").
- The team's English-language pitfall-research bibliography is dominated by US samples; the East-Asian midpoint-bias literature is in Japanese / Chinese / Korean and rarely translated.
- 「悦己」 was chosen for the ledger rename without specifically validating the family-mode concatenation.

**How to avoid:**
- **Phase 12 translation contract:** every ARB key changes must be reviewed by a native speaker who is asked specifically: "Does this read as everyday-light or existential-heavy?" — not just "is it accurate?" This is a different review than a lexical pass.
- **Lock the lexical hierarchy in `docs/arch/`:**
  - 幸福 / 幸福 / Happiness — RESERVED for documentation only, **not in user-facing UI**
  - ときめき / 悦己 / Joy — allowed for soul-ledger personal indicators
  - ハピネス密度 / 幸福密度 (zh OK because 幸福 is everyday in Chinese) / Joy per ¥ — allowed for the density metric (note: Chinese 幸福 is closer to English "happy" than Japanese 幸福; the asymmetry is correct, not a bug)
  - For family-mode strings in Chinese, prefer 「家族的小确幸」 (family small happiness — the term `小确幸` borrowed from Murakami is *exactly* the right register here) over any composition with 悦己.
- **Don't over-engineer the histogram for the tall-middle:** Phase 11 should expect and label the central cluster, not "fix" it. Annotate 「分布の中心傾向は文化差を含む」 — adds research-honest framing.
- **Set expectations in stakeholder copy:** internal release notes / customer-success materials should explicitly note that average satisfaction ~5–6 in JP user base is the *expected* baseline, not a problem.

**Warning signs:**
- A translator returns Phase 12 copy with 幸福 reintroduced "for clarity."
- Family-mode Chinese copy contains 「家族悦己」 (the wrong composition).
- An A/B test interprets "JP users cluster at 5" as "JP users are unhappy."
- Marketing materials emphasize "幸せになろう" / "Be happy!" framing — directly inverting the wabi-sabi register the JP product is built on.

**Phase to address:** **Phase 12 (rename pass).** Lock the lexical hierarchy table in the ADR. Brief native-speaker reviewers on register, not just lexical accuracy. Cross-link to Phase 11 histogram caption.

---

### Pitfall 9: Empty-window / cold-start edge cases produce nonsense metrics on day 1 and after data clears

**What goes wrong:**
Month-to-date with zero soul transactions yields, for each formula:
- **Avg Satisfaction:** 0/0 → undefined. Naive `sum / count` crashes; `(sum / count).toStringAsFixed(1)` shows "NaN" — a bug-class string in the headline tile.
- **Joy per ¥:** 0/0 → undefined.
- **Highlights count:** 0 — correct, but the card shows "0 件 / 0 个 / 0 highlights" which on day 1 of a new month feels like an accusation.
- **Best Joy per ¥:** argmax over an empty set → undefined; should not render the story card at all.
- **Family Highlights Sum:** 0 across N members — correct number, hostile copy.
- **Shared Joy Insight:** "top category" undefined when no member has reported.

Single-data-point edge cases are also pathological:
- 1 transaction with sat=10, ¥3000 → Avg=10.0, Joy/¥=0.00333. The tile shows "perfect month" on a single coffee. User screenshots this; UX harm.
- Distribution histogram with 1 row is a single bar — visually broken.
- Daily satisfaction trend with sparse days has zero vs missing ambiguity (rendered as 0 or skipped?).

**Why it happens:**
- Frontend code for "show me a number" defaults to "compute a number" without an empty-state branch.
- Drift / SQL aggregations return `null` on empty sets in some cases and `0` in others depending on the function (`AVG` → NULL; `COUNT` → 0; `SUM` → 0); inconsistent handling at the boundary.
- The milestone copy frames metrics as "always show a number" — the empty-state design isn't in scope unless explicitly added.

**How to avoid:**
- **Empty-state contract per metric (Phase 9):**
  - 0 soul rows in window → return `Option<Metric>` (None / null / sealed `MetricResult.empty`); **frontend never sees a numeric "0".**
  - 1–2 soul rows → return `MetricResult.thinSample(value, n)`; frontend renders with a "(based on n=2)" caption and **no trend indicator** (no "+/-").
  - ≥3 soul rows → return `MetricResult.value(value, n)`; full rendering.
- **Empty-state UI copy (Phase 10):** soul tile shows "今月はまだ記録なし / 本月还没有记录 / No records this month yet — first记录 will start the count." Friendly, not zero. The story card simply does not render.
- **Single-data-point UX (Phase 10):** if n=1, render the tile but with a discreet asterisk or grey-out treatment so the user knows the average isn't representative yet.
- **Histogram rendering (Phase 11):** if sample size <5, replace the histogram with text ("もう少し記録すると分布が見える") — chart libs render single-bar histograms badly anyway.
- **Daily trend (Phase 11):** explicitly choose "missing day = gap in line" (not zero), and document it in a chart legend. Zero-vs-missing ambiguity is the most common chart bug in self-tracking apps.

**Warning signs:**
- "NaN" or "Infinity" appears anywhere in production logs from the metric layer.
- New users churn on day 1 (the empty state was unfriendly).
- Histogram screenshots posted to social media show single-bar charts.
- A test fixture exists for "happy path 30 transactions" but not for "0 / 1 / 2 transactions."

**Phase to address:** **Phase 9** (sealed `MetricResult` types with `.empty` / `.thinSample` / `.value`); **Phase 10** (empty-state copy + thin-sample treatment); **Phase 11** (chart-level empty / sparse handling). Required test cases: n=0, n=1, n=2, n=30; with ledger_type ∈ {soul-only, mixed, survival-only}.

---

### Pitfall 10: Integration tax — extending AnalyticsScreen vs building a new screen has hidden coupling costs

**What goes wrong:**
The milestone says Phase 11 wires the 3 dormant DAOs into the existing AnalyticsScreen. This is the right call (don't proliferate screens), but four specific failure modes:

1. **Provider graph contamination:** the existing AnalyticsScreen has its own provider tree. Adding new providers without auditing the existing graph can re-trigger the v1.0-cleaned-up "duplicate repository providers" issue. Ref `repository_providers.dart` per-feature rule (CLAUDE.md pitfall #10).
2. **Layout fragility:** AnalyticsScreen is presumably rendering monthly reports / expense trends already. Adding histogram + Joy-per-¥ trend line + 4 metric tiles can blow past viewport, creating awkward scroll. iOS 14+ safe-area + dynamic-type-large = particularly tight. Existing layouts assume the current widget tree.
3. **Localization key namespace pollution:** new ARB keys for the satisfaction stats (subtitles, captions, histogram axis labels) get added to a shared `app_*.arb` files; key naming collisions or near-duplicates with existing analytics strings.
4. **Test infrastructure coupling:** existing AnalyticsScreen tests likely use a fixture set that doesn't include `soul_satisfaction` columns populated with realistic distributions. Adding new widget tests on the same fixture base means either (a) updating fixtures globally — ripple effect — or (b) creating parallel fixtures — duplication.

The "extend not build new" call is correct, but **Phase 11 must include explicit budget for the integration tax** or it slips. Typical 30–50% under-estimation in this kind of "just wire it up" work.

**Why it happens:**
- "Extend the screen" reads as smaller scope than it actually is when the existing screen has implicit contracts (layout, providers, localization, tests).
- The 3 DAO methods are described as "dormant" — easy to assume they are clean and just need wiring. Pre-Phase-11 verification that they actually filter `ledger_type='soul'` correctly is non-optional (refer Pitfall 1).

**How to avoid:**
- **Phase 11 starts with an audit pass, not a wiring pass:** review the 3 DAO methods' SQL, audit the existing AnalyticsScreen provider graph, and document the *current* widget tree before adding to it. Output: a one-page "integration footprint" doc in `.planning/`.
- **Sub-region pattern:** the new content goes into a `SoulSatisfactionAnalyticsSection` widget that is a single child of AnalyticsScreen. Keeps the new widgets composable and removable; isolates fixture and localization namespace prefix (use `analyticsSoulXxx` ARB keys to namespace them).
- **Provider scope:** new providers go in `lib/features/analytics/presentation/providers/happiness_providers.dart` (one file, follows the per-feature `repository_providers.dart` rule). Do not reuse / mutate the existing analytics providers.
- **Fixture additive-only:** add new test fixtures in a separate file (e.g. `test/fixtures/soul_satisfaction_fixtures.dart`); existing fixtures untouched.
- **Layout sanity check:** run the AnalyticsScreen at iPhone SE (smallest supported), iPad split-view, dynamic-type-XXL, and screenshot-test in CI. Existing AnalyticsScreen presumably already has golden tests — extend, don't replace.

**Warning signs:**
- Any PR in Phase 11 that touches existing analytics provider files (`use_case_providers.dart` etc.) without explicit justification.
- New ARB keys without a `analyticsSoul*` prefix.
- A single fixture file growing past 600 lines.
- Phase 11 estimate < 0.4× Phase 10 estimate (rule of thumb: integration > greenfield).

**Phase to address:** **Phase 11.** Reserve first sub-task for the integration audit. Build the new content in a sub-region widget and a co-located provider file.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Compute Joy per ¥ in the widget instead of a Use Case | "It's just division — why a use case?" | Formula gets duplicated when stats screen adds it; tests of formula and tests of widget become tangled; survival-ledger filter forgotten in one of the two sites (→ Pitfall 1) | Never — formula authority must be one Use Case, full stop |
| Skip the empty-state branch in v1.1 ("we'll add it when users complain") | Faster ship | First reviewer screenshot shows "NaN/¥0 = Infinity"; PR review blocks; emergency hotfix; user trust dented | Never — empty-state is part of the formula, not a separate feature |
| Reuse existing analytics provider tree instead of new sub-tree | Less Riverpod scaffolding | Re-triggers v1.0-cleaned duplicate-provider issue; CI guardrail blocks PR; rework | Never — v1.0 explicitly locked the per-feature `repository_providers.dart` rule |
| Show per-member breakdown in family card "for transparency" | Users see "where the joy came from" | Toxicity (Pitfall 5); intimate-partner privacy harm; potential GDPR special-category exposure | Never in v1.1; revisit only with explicit consent UX in v1.3+ |
| Display absolute Joy-per-¥ trend line over 6+ months | Looks like "real analytics" | Hedonic-adaptation drift makes line slope down; users self-blame (Pitfall 6) | Never as default; offer as advanced toggle in v1.3+ with explanatory copy |
| Default to mean (not median) for Avg Satisfaction headline | Matches milestone spec literally | Default-5 cluster (Pitfall 4) drags mean toward neutral; metric loses signal | OK for v1.1 *if* "n=k" sample size and median tooltip are shipped (Pitfall 4 mitigation) |
| Translate 「ときめき」 / 「悦己」 by lexical reference only | Faster Phase 12 | Family-mode 「家族悦己」 collision (Pitfall 8); register mismatch | Never — register review is mandatory |
| Add a "best month ever" badge "to celebrate" | Engagement bump | Goodhart gaming (Pitfall 7); user rates everything 10 | Never in v1.1 — bans encoded in ADR |
| Use the voice estimator's output as-is without disclosure | No UX friction | Avg Satisfaction structurally inflated (Pitfall 3); user trust on the metric undermined when bad month doesn't show down | Acceptable only with the `ⓘ` disclosure tooltip; otherwise schedule recalibration |

---

## Integration Gotchas

Common mistakes when wiring this milestone into the existing app.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `getSoulSatisfactionOverview` DAO method (dormant) | Wire as-is without re-reading the SQL | Read the SQL; verify `ledger_type='soul' AND deleted_at IS NULL`; add a fixture test exercising survival + deleted rows before wiring (Pitfall 1) |
| `getSatisfactionDistribution` DAO method (dormant) | Reuse the existing histogram widget | Verify bucket boundaries (1–10 vs 0–10 vs 1–5 emoji-mapped) match the chosen Phase 11 design; add a non-empty / single-bar / sparse test |
| `getDailySatisfactionTrend` DAO method (dormant) | Render as a continuous line | Decide gap-vs-zero rendering policy (Pitfall 9); document in chart legend |
| Existing `currentLocaleProvider` | Use only for date / number formatting | Also gate the ARB string register-mapping (e.g. some keys differ in CN vs JP register beyond translation — Pitfall 8) |
| `S.of(context).homeHappinessROI` rename → `homeJoyDensity` | Add new key, leave old | ARB key parity gate (CI guardrail from v1.0) blocks; **must** rename atomically across all 3 ARB files in a single PR; remove old key in same PR |
| `LedgerType.soul` enum | Update the enum to match new copy | NEVER — the enum is data; the copy is i18n (CLAUDE.md pitfall: schema/enum lock). Phase 12 is ARB-only. |
| `SatisfactionEmojiPicker` (existing widget) | Modify to enforce no-default | Out of scope for v1.1 (defaults stay; mitigated by Pitfall 4's filter / coverage display) |
| `VoiceSatisfactionEstimator` (existing) | Recalibrate the +0.3 bias in v1.1 | Out of scope; disclose via tooltip only (Pitfall 3) |
| Existing `AnalyticsScreen` provider graph | Add providers ad-hoc | Co-locate in new `happiness_providers.dart`; respect per-feature provider rule (Pitfall 10) |
| Existing v1.0 audit re-run | Skip on this milestone | Run once after Phase 12; any new findings indicate v1.1 introduced fresh debt (the v1.0 close gate said "zero open"; v1.1 must hold the line) |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows. (Note: this is a single-device local-first app; "scale" means a single user's transaction history over years, not multi-tenant load.)

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Compute all 6 metrics on widget rebuild | UI lag opening HomePage; battery drain | Cache via `AsyncNotifier` with `keepAlive: true` for the metric provider; invalidate only on transaction insert/update/delete events | Once a user has >3000 transactions (~3 yr usage @ 3/day) |
| Recompute "Best Joy per ¥" via in-memory `argmax` over all soul rows | Frame drops on month change | Push the `argmax` to SQL (`ORDER BY satisfaction*1.0/amount DESC LIMIT 1`); index on `(ledger_type, deleted_at, occurred_at)` already exists per v1.0 schema v15 | At ~5000 soul rows |
| Histogram bucketing in Dart instead of SQL | Same as above | `SELECT satisfaction, COUNT(*) FROM transactions WHERE _soulOnly() AND ... GROUP BY satisfaction` returns 10 rows max | Same threshold |
| Daily trend computed by 31 separate SQL queries | Noticeable open-stats-screen latency | Single `GROUP BY DATE(occurred_at)` query | At ~1000 days × N rows scan with no index |
| Family Highlights Sum: query each member's database separately | N round-trips on group expand | Family sync apply pipeline already aggregates into local DB; query the local aggregate, not per-member | At ≥3 family members with ≥1 yr history each |
| New providers without `keepAlive: true` for cards that stay on HomePage | Provider torn down + rebuilt on every navigation | Mark headline-card providers `@Riverpod(keepAlive: true)`; respect v1.0 keepAlive lifecycle audit (CLAUDE.md pitfall ref) | Immediately on production usage |

---

## Security & Privacy Mistakes

Domain-specific issues beyond the v1.0 4-layer encryption stack.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging satisfaction values in debug output | Leaks emotional state via `flutter logs` / device logs that survive `kDebugMode`-stripped release builds in QA / TestFlight | Add `// SENSITIVE: emotional` comment on satisfaction-handling code; ensure all satisfaction print/debugPrint are wrapped in `if (kDebugMode)` (the v1.0 sync-engine pattern); add an audit-script grep |
| Including satisfaction in backup export without opt-in | Backup file ends up in cloud / shared (iCloud / Google Drive) → emotional data exfiltration | The existing backup includes `transactions` rows; satisfaction is already in the row. Verify the existing backup encrypt-at-rest holds (it does per v1.0 architecture); add a backup-content audit test asserting backups remain encrypted on disk |
| Family sync transmitting per-member satisfaction values | Intimate-partner surveillance vector (Pitfall 5) | Family-mode metrics computed *locally* per member then *only the aggregate* is synced over the family channel; per-member satisfaction never leaves the member's device. Confirm the sync queue payload schema does not include `soul_satisfaction` cross-device |
| Showing satisfaction values in screenshots / app preview / analytics-team test fixtures committed to repo | Fixture leak; PR review reveals real-looking data | Test fixtures use synthetic distributions; add a pre-commit check that fixture files contain `// SYNTHETIC` comment |
| Crash reports / analytics SDK uploading satisfaction values via field captures | Third-party (Sentry / Firebase Crashlytics) ends up with emotional data | Verify whatever crash-reporter is in use scrubs `transactions.*` fields; add to PII-scrub list explicitly |
| Voice estimator output transmitted to a cloud STT before estimation | If voice processing is server-side, the STT vendor sees raw audio of users describing soul purchases | Device-only STT (per v1.0 privacy architecture); verify v1.1 doesn't introduce a fallback path |
| Recovery-kit export includes satisfaction history | Recovery flow exposes data designed for restoration to a third party (e.g. lost-phone replacement) | The recovery flow is BIP39-seed-only; satisfaction is in the encrypted DB which is restored from backup separately; verify v1.1 doesn't piggyback on the recovery export |

---

## UX Pitfalls

Common user-experience mistakes specific to wellbeing-on-finance.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Opening with the headline number on day 1 of a new user | "Joy per ¥: 0" greeting feels accusatory | Empty-state copy + soft CTA "今月最初の悦己を記録してみる / 本月第一笔悦己 / Add your first joy" |
| Showing a downward trend without context | User concludes "I'm broken" (Pitfall 6) | Window to single month; baseline-anchor; explainer modal |
| Comparing this month to last month with prominent +/- | Anchors on the comparison; bad month feels worse | Show comparison only on tap-detail; default view is absolute |
| Highlight story card celebrating a ¥10 candy | Trivializes the feature (Pitfall 2) | Amount floor for "best" eligibility; show amount alongside |
| Family card breaking down by member | Comparison toxicity (Pitfall 5) | Aggregate-only; category breakdown if needed |
| Voice-entered satisfaction silently winning highlights | User intuition: "I didn't even pick that number" | Distinguish manual-rated rows visually in the highlight card (small mic icon); allow re-rate |
| Histogram with single bar at 5 (default cluster) | Looks broken; user doesn't know if it's their data or the app | Annotate the `5` bar specially; show coverage count "n=23 rated of 31" |
| Forcing a satisfaction prompt on every soul transaction | Friction → users abandon soul logging | Picker stays optional (existing behavior); coverage metric (Pitfall 4) shows the gap honestly |
| Using `5` Likert max ≠ actual range | Existing emoji picker is 5-emoji; satisfaction is stored 1–10 | Verify mapping logic in Phase 9; document the 5-emoji ↔ 1–10 mapping (likely 1-2 / 3-4 / 5-6 / 7-8 / 9-10) and ensure tests pin it |
| Family card visible to a member who didn't consent to share | Privacy harm (Pitfall 5) | Group-mode + all-members-opted-in gate (Pitfall 5) |
| `ⓘ` info icons everywhere (over-disclaimer) | "What is this app even doing?" trust loss | Limit to ≤2 info icons in v1.1: one on Avg Satisfaction (voice bias), one on Joy per ¥ (adaptation). All other explainers go in Settings → About |
| Renaming "Happiness ROI" to "Joy per ¥" without grace period | Returning users see a totally new card and can't find their number | Phase 10 ships a one-time tooltip on the renamed card: "前の『Happiness ROI』はここに。よりわかりやすい指標になりました" |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Avg Satisfaction Use Case:** Often missing the soul-only filter — verify the SQL contains `ledger_type='soul' AND deleted_at IS NULL` and the test fixture includes survival rows that must be excluded (Pitfall 1).
- [ ] **Joy per ¥ Use Case:** Often missing the empty-window guard — verify `MetricResult.empty` returned when `count(soul_rows)=0` (Pitfall 9).
- [ ] **Best Joy per ¥ Use Case:** Often missing the amount floor — verify a sub-floor candy with sat=10 does not win (Pitfall 2).
- [ ] **Highlights count:** Often missing the deduplication of voice-estimated near-8 rows — verify a row with sat=7 (real) and a voice-estimated row with sat=8 (true=7.7) are both counted *only if user did not subsequently re-rate*. Define behavior in Phase 9.
- [ ] **Family Highlights Sum:** Often missing the aggregate-only contract — verify the DAO returns `int`, not `Map<MemberId, int>` (Pitfall 5).
- [ ] **Shared Joy Insight:** Often missing the empty-categories handling — verify behavior when no member has any soul transaction yet (Pitfall 9 + 5).
- [ ] **HomePage SoulFullnessCard:** Often missing the empty-state copy — verify zero-state renders soft CTA, not "0 / NaN" (Pitfall 9).
- [ ] **HomePage card:** Often missing the coverage indicator — verify "n=k rated" shown when median is in use or coverage is thin (Pitfall 4).
- [ ] **Family card:** Often missing the consent gate — verify the card collapses if any member has not opted into shared analytics (Pitfall 5).
- [ ] **Stats screen histogram:** Often missing the `5`-bar annotation — verify the midpoint is visually distinguished and labeled "incl. unrated" (Pitfall 4).
- [ ] **Stats screen trend:** Often missing the gap-vs-zero policy doc — verify the chart legend explicitly says "missing days = gap" (Pitfall 9).
- [ ] **ARB rename PR:** Often missing the old-key deletion in the same commit — verify CI ARB-parity gate passes; old keys not lingering (Pitfall 10 / v1.0 ARB parity guard).
- [ ] **Translation review:** Often missing the register / weight pass — verify each Phase 12 string was reviewed by a native speaker on register, not just lexical accuracy (Pitfall 8).
- [ ] **No-gamification ADR:** Often skipped because "we didn't add streaks anyway" — verify ADR exists and explicitly bans streaks/badges/targets (Pitfall 7).
- [ ] **Voice-estimator disclosure tooltip:** Often deferred to v1.2 — verify the tooltip ships in v1.1 Phase 10 (Pitfall 3).
- [ ] **Privacy review:** Often skipped because "we're not adding new fields" — verify satisfaction is treated as emotional-special-category in logging, backup-export, family-sync payload, crash-report scrubbing (Security & Privacy Mistakes section).
- [ ] **AnalyticsScreen integration audit:** Often skipped — verify the Phase 11 first sub-task is the integration footprint doc, not the wiring code (Pitfall 10).
- [ ] **Cold-start tests:** Often missing — verify n=0 / n=1 / n=2 / n=30 fixtures exist for each Use Case (Pitfall 9).
- [ ] **Sub-floor / mixed-ledger tests:** Often missing — verify each Use Case test includes survival rows + sub-floor candies in the input fixture (Pitfalls 1 + 2).
- [ ] **Provider keepAlive audit:** Often missed on new providers — verify `@Riverpod(keepAlive: true)` on every metric provider that backs a HomePage tile (Performance Traps).

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Survival rows polluting metrics (Pitfall 1) | LOW | Add `ledger_type='soul'` to all 6 metrics in a single hotfix PR; bump test fixtures to include survival rows; ship as v1.1.1 |
| Joy per ¥ candy domination (Pitfall 2) | LOW | Add amount floor to "Best Joy per ¥" in a hotfix; doesn't affect headline density; ship as v1.1.1 |
| Voice estimator inflation noticed by users (Pitfall 3) | MEDIUM | If tooltip ships in v1.1, no recovery needed; if not, hotfix the tooltip + log a v1.2 ticket for estimator recalibration + add `entry_source` column |
| Default-5 cluster making metric useless (Pitfall 4) | MEDIUM | Switch headline from mean to median in hotfix (one-line change in Use Case); update copy "中央値" / "中位数" / "median" |
| Family-mode comparison toxicity reported (Pitfall 5) | HIGH | If per-member breakdown shipped, remove it (UI-only PR); if aggregate-only shipped but copy is still competitive, rewrite copy in next ARB-only release; if per-member SATISFACTION VALUES leaked via sync, **incident response**: issue advisory, force-flush sync queue, audit deleted-data assurance |
| Hedonic adaptation downward trend complaints (Pitfall 6) | LOW | Reduce trend window to 30 days in next release; add explainer modal; copy fix |
| Goodhart gaming detected via entropy alarm (Pitfall 7) | MEDIUM | Add "本当に最高？" friction to picker for ≥9 ratings; **do not** add anti-gaming nudges to user-facing UI (creates meta-gaming); review whether streaks/badges accidentally crept in |
| 「幸福」 leaked into UI (Pitfall 8) | LOW | ARB-only hotfix replacing the offending key; CI parity gate ensures all 3 locales update together |
| NaN / Infinity in production (Pitfall 9) | LOW–MEDIUM | If caught pre-release: fix Use Case to return `MetricResult.empty`. If post-release: hotfix + force-cache-invalidate the headline card |
| AnalyticsScreen integration broke layout on small devices (Pitfall 10) | LOW–MEDIUM | Wrap new section in collapsible `ExpansionTile`; ship golden-test screenshots for SE / iPad / dynamic-type-XXL |
| Privacy / emotional-data leak via logs / backup / sync (Security section) | HIGH | Standard incident response; refer to v1.0 4-layer encryption architecture as the recovery framework; verify which layers held; bump schema if needed (against milestone constraint, but life > scope) |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| # | Pitfall | Prevention Phase(s) | Verification |
|---|---------|----------------------|--------------|
| 1 | Survival-row contamination | **9** | Arch test grepping for `soul_satisfaction` outside DAO files; DAO unit tests with survival + deleted fixtures |
| 2 | Joy-per-¥ tiny-amount domination | **9, 10, 11** | Use Case test: sub-floor candy excluded from "Best"; UI shows amount alongside highlight; chart Y-axis sane |
| 3 | Voice estimator upward bias | **9, 10, 11** | Quantification test in Phase 9; tooltip in Phase 10 card; histogram caption in Phase 11 |
| 4 | Default-5 pollution | **9, 10, 11** | Median tooltip + coverage "n=k" caption; histogram `5`-bar annotation |
| 5 | Family-mode toxicity | **9, 10, 12** | DAO returns aggregate-only `int` (not Map); UI consent gate; non-comparative copy review |
| 6 | Hedonic adaptation | **10, 11** | One-time info modal; trend windowed to month; baseline-anchored axis |
| 7 | Goodhart gaming | **9, 10** | ADR banning streaks/badges; entropy health-check internal-only; no daily targets in copy |
| 8 | Cultural framing (JP/CN) | **12** | Lexical hierarchy ADR; native-speaker register review; family-mode 「家族悦己」 collision check |
| 9 | Empty-window / cold-start | **9, 10, 11** | Sealed `MetricResult` (empty / thinSample / value); n=0/1/2/30 test fixtures; chart sparse-data fallback |
| 10 | AnalyticsScreen integration tax | **11** | Integration footprint doc as first sub-task; sub-region widget; co-located providers; new ARB key prefix |

**Phase summary:**
- **Phase 9 (formula / domain):** Pitfalls 1, 2, 3 (test), 4 (decision), 5 (DAO contract), 7 (ADR), 9 (sealed types).
- **Phase 10 (HomePage):** Pitfalls 2 (display), 3 (tooltip), 4 (coverage), 5 (consent gate + copy), 6 (info modal), 7 (no targets), 9 (empty-state).
- **Phase 11 (Statistics):** Pitfalls 2 (chart axis), 3 (caption), 4 (histogram annotation), 6 (window + baseline), 9 (sparse-data), 10 (integration audit + sub-region).
- **Phase 12 (Rename pass):** Pitfalls 5 (non-comparative copy), 8 (lexical hierarchy + register review).

**Cross-cutting (every phase):** Privacy & Security Mistakes section — satisfaction is emotional special-category data; treat the v1.0 4-layer encryption stack as the floor, not the ceiling, especially for logs / backup-export / family-sync payload.

---

## Sources

### Primary — domain research (HIGH / MEDIUM confidence)

- [Goodhart's law — Wikipedia](https://en.wikipedia.org/wiki/Goodhart's_law) — "When a measure becomes a target, it ceases to be a good measure." Strathern 1997 reformulation.
- [Hedonic treadmill — Wikipedia](https://en.wikipedia.org/wiki/Hedonic_treadmill) — adaptation phenomenon.
- [Hedonic Adaptation: Why More Money Won't Always Make You Happier — Dorset Wealth, 2024](https://dorsetwealth.au/hedonic-adaptation/) — applied review.
- [Does variety in hedonic spending improve happiness? — BMC Psychology, 2024](https://bmcpsychology.biomedcentral.com/articles/10.1186/s40359-024-01599-8) — variety attenuates adaptation; relevant to v1.2 variety nudge but not v1.1.
- [Information loss and bias in Likert survey responses — PMC, 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9333316/) — Likert response bias review.
- [Likert scale — Wikipedia](https://en.wikipedia.org/wiki/Likert_scale) — central tendency bias documented.
- [Methodological considerations in subjective wellbeing — OECD Guidelines, NCBI](https://www.ncbi.nlm.nih.gov/books/NBK189566/) — measurement bias in subjective wellbeing.
- [幸福度に関する研究会 — 内閣府 (Japan Cabinet Office)](https://www5.cao.go.jp/keizai2/koufukudo/koufukudo.html) — Japanese government wellbeing index research.
- [日本人の幸福度向上のための幸せの文化差・地域差の研究 — Keio SDM 博論, 2014](https://koara.lib.keio.ac.jp/xoonips/modules/xoonips/download.php/KO40002002-20144197-0003.pdf?file_id=98963) — East-Asian central-tendency clustering documented in JP / KR / CN samples.
- [日本収納達人近藤麻理惠 / Marie Kondo controversy — HOKK Fabrica](https://hokkfabrica.com/marie-kondo-controversy/) — context for ときめき / spark joy register.
- [Wabi-sabi — Wikipedia](https://en.wikipedia.org/wiki/Wabi-sabi) — modesty / non-superlative aesthetic in JP cultural register.
- [Privacy threats in intimate relationships — Journal of Cybersecurity, Oxford, 2020](https://academic.oup.com/cybersecurity/article/6/1/tyaa006/5849222) — intimate-partner data-abuse vectors; the foundational citation for "satisfaction is more sensitive than amounts."
- [Sibling rivalry — EBSCO Research](https://www.ebsco.com/research-starters/psychology/sibling-rivalry) — sibling-comparison harm literature.
- [IZA DP 734 Sibling Rivalry: Six Country Comparison — Wolter, 2003](https://docs.iza.org/dp734.pdf) — parent-initiated comparisons more harmful than sibling-initiated.
- [Sibling Rivalry: How Comparing Siblings Lowers Self-Esteem — Dove Self-Esteem Project](https://www.dove.com/us/en/dove-self-esteem-project/sibling-rivalry-how-comparing-siblings-can-lower-self-esteem.html) — practitioner-facing summary.
- [Gamification in fintech: Financial literacy or just engagement? — 11FS](https://www.11fs.com/article/gamification-in-fintech-financial-literacy-or-just-engagement) — streak-protection harm in finance apps.
- [How to Design Effective Leaderboards — Yu-kai Chou](https://yukaichou.com/advanced-gamification/how-to-design-effective-leaderboards-boosting-motivation-and-engagement/) — leaderboards inappropriate for non-competitive activities.
- [Increase Competitiveness in Users with Leader Boards — IxDF](https://www.interaction-design.org/literature/article/increase-competitiveness-in-users-with-leader-boards) — competitive design pattern; family-mode anti-pattern by negation.
- [Leaderboard design pattern — UI-Patterns.com](https://ui-patterns.com/patterns/leaderboard) — when not to use.
- [Division by zero — Wikipedia](https://en.wikipedia.org/wiki/Division_by_zero) — formal undefined-result handling.
- [BigQuery SQL Functions: SAFE_DIVIDE — Orchestra](https://www.getorchestra.io/guides/bigquery-sql-functions-safe-divide) — pattern for safe ratio computation.

### Primary — project context (HIGH confidence — direct file inspection)

- `.planning/PROJECT.md` — v1.1 milestone scope, formulas locked, schema-locked constraint
- `CLAUDE.md` — 13 known pitfalls including #4 (immutability), #10 (one repository_providers per feature), #11 (Drift TableIndex syntax)
- `.planning/research/SUMMARY.md` (v1.0 — historical) — v1.0 audit close criteria; v1.1 must hold the line at "zero open findings"
- v1.0 audit pipeline & 4 permanent CI guardrails — `import_guard`, `riverpod_lint` / `custom_lint`, `coverde` per-file ≥70% with `--deferred` mechanism, `sqlite3_flutter_libs` rejection — already in CI; this milestone must stay green on all four

---

*Pitfalls research for: v1.1 Happiness Metric & Display milestone — domain layer + HomePage + Statistics + UI rename*
*Researched: 2026-05-01*
*Replaces: v1.0 cleanup-initiative PITFALLS.md (now archived in milestones/v1.0-ROADMAP.md context)*
