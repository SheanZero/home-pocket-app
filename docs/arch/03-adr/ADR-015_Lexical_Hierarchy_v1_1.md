# ADR-015: 词汇分层 v1.1 (Lexical Hierarchy v1.1)

**状态:** 📝 草稿
**日期:** 2026-05-04
**决策者:** zxsheanjp@gmail.com (project owner) + Claude (planning agent)
**影响范围:** v1.1 milestone UI copy register (ja/zh/en); product-vs-documentation lexical separation; CN family-mode naming; JP picker-label wellbeing register

---

## 1. 背景与问题陈述 (Context)

v1.1 introduces happiness-themed surfaces across HomeHeroCard, AnalyticsScreen Variant δ, and the satisfaction picker. These surfaces must talk about joy, wellbeing, and spending without turning the app into a self-judgment dashboard.

The milestone therefore needs three vocabularies, not one:

1. A philosophical / wellbeing-research register for ADRs, README, roadmap, and long-form explanation: "幸福" / "happiness" / "ハピネス".
2. An in-product register for end-user UI: "悦己" / "Joy" / "ときめき".
3. A math-density register where "幸福" is legitimate only because the value is a Prospect-Theory density, not an emotion claim: `homeHappinessROI` as "幸福密度" / "Joy per ¥" / "ハピネス密度".

Without this ADR, future copy review would have to rediscover the same boundary every time someone asks whether "幸福" belongs in a button, chart title, family insight, or picker label. ADR-015 makes the boundary durable and citeable.

---

## 2. 决策驱动因素 (Forces)

- **Anti-Goodhart binding:** ADR-012 bans gamification because happiness metrics stop being useful when users optimize for the number. Product copy using 「幸福」 too freely primes self-judgment and leaderboard mental models, even without explicit badges.
- **Three-language asymmetry:** Each language has different register stress points. Japanese has katakana-vs-kanji-vs-hiragana pressure; Chinese has philosophical-vs-product pressure; English has clinical-vs-emotive pressure.
- **CN family-mode collision risk:** After the Phase 12 rename, `soulLedger` zh is 「悦己账本」. A family-mode label using 「家族悦己」 reads as "family is one user's personal soul account", corrupting the dual-ledger semantic.
- **Picker icon binding:** ADR-014 Path B locks default `soul_satisfaction` 5 -> 2 and requires emoji 1 to stop carrying negative emotion. The value-2 label must read as a wellbeing baseline, not philosophical zero, physical neutrality, or suppressed negative affect.
- **Milestone close discipline:** Phase 12 is the last v1.1 phase. Register choices made here will become the reference baseline for v1.2 copy review.

---

## 3. 备选方案 (Considered Options)

### Option A: Allow 「幸福」 / "happiness" / 「ハピネス」 freely in product UI

**结论:** 拒绝。

**理由:** This collapses documentation language into the product surface. In the app, broad "happiness" wording makes every metric feel like a judgment of the user's life, which conflicts with ADR-012's anti-Goodhart and anti-leaderboard binding.

### Option B: Use only kanji-native vocabulary in JP product UI, never katakana

**结论:** 拒绝。

**理由:** The default product register should prefer the Japanese wellbeing kanji ladder where appropriate, but `homeHappinessROI` is a math-density title. 「ハピネス密度」 is legitimate there because it describes the named density concept from ADR-013, not a raw emotion claim.

### Option C: Use 「家族悦己」 in CN family-mode

**结论:** 拒绝。

**理由:** 「悦己」 has been assigned to personal `soulLedger` as 「悦己账本」. Combining it with family mode suggests the family is being folded into one person's private soul ledger, which breaks the cooperative, aggregate-only family contract.

### Option D: Three-tier hierarchy with math-density carve-out and explicit register rules

**结论:** 采用。

**理由:** This keeps documentation precise, product copy approachable, KPI math explainable, CN family mode collision-free, and JP picker labels aligned with the unipolar-positive wellbeing ladder.

---

## 4. 决策 (Decision)

ADR-015 establishes the following trilingual lexical hierarchy:

| Register tier | en | ja | zh |
|----------------|----|----|----|
| Documentation / README | happiness | ハピネス | 幸福 |
| In-product UI (default) | Joy | ときめき | 悦己 |
| KPI math-density title | Joy per ¥ | ハピネス密度 | 幸福密度 |
| Family-mode label | Family Joy | 家族の小確幸 | 家族的小确幸 |

`homeHappinessROI` retains "幸福" / "ハピネス" / the historical Happiness concept only as the math-density exception. ROADMAP locks the current EN value as "Joy per ¥"; the old key name remains for v1.1 ARB compatibility. The semantic root is ADR-013: a Prospect-Theory value-function density, not a promise that the app can measure the user's total happiness.

Family mode MUST use 「家族的小确幸」 / 「家族の小確幸」 / "Family Joy", not 「家族悦己」. This avoids collision with personal `soulLedger` zh=「悦己账本」 and reinforces ADR-012: a family is not a scoreboard of competing soul accounts.

This rule predates ADR-015 in code. `git log -S"家族的小确幸" -- lib/l10n/app_zh.arb` identifies commit `fbd3148` (`feat(10-04): add 24 Phase 10 ARB keys to ja/zh/en atomically`) as the commit-of-record that introduced `homeRingSectionTitleGroup` with zh=「家族的小确幸」 and ja=「家族の小確幸」. Phase 11 D-13 then reused the same family-mode sentence pattern in Analytics. ADR-015 codifies that de-facto pattern as the review rule for future family-mode copy.

The hierarchy is intentionally asymmetric. English uses "Joy" as the product term because it is short, warm, and not clinical. Japanese uses 「ときめき」 for the ledger-level product register, while the satisfaction picker uses kanji compounds for scale levels. Chinese uses 「悦己」 for personal product surfaces and 「小确幸」 for family-mode cooperative summaries.

---

## 5. JP wellbeing-register subsection

The satisfaction picker label ladder is:

| Value | Label |
|-------|-------|
| 2 | 無難 |
| 4 | 快適 |
| 6 | 順調 |
| 8 | 満足 |
| 10 | 至福 |

`無難` is the value-2 anchor. Rejected alternatives:

- `中性` reads as philosophical or physical neutrality, which would imply a zero point rather than a least-positive wellbeing state.
- `フラット` uses a modern katakana register that clashes with `ときめき帳` and `日々の帳`.
- `平静` leans toward emotional suppression or a psychological state, which is not the intended baseline for a purchase that the user chose for self-nourishment.

`無難` means "no problem / unobjectionable" in a familiar wellbeing register. It allows the first picker position to be honest without becoming negative. That matches ADR-014 Path B: the lowest product choice is a baseline, not a sad face.

The full ladder is all kanji and uses familiar wellbeing compounds. `快適` bridges from no-problem baseline to positive comfort; `順調` reads as going well; `満足` names clear satisfaction; `至福` names the peak without importing the research-register 「ハピネス」 into the picker.

This ladder also reads alongside `soulLedger` ja=「ときめき帳」 and `survivalLedger` ja=「日々の帳」. The surrounding UI has a warm, literary Japanese register; mixing katakana labels into the picker would make the scale feel like a generic rating widget instead of part of the same product voice.

`至福` (value 10) is not the same copy role as bottomLabel `至福！`. The level label communicates "level achieved" in the selected state. The bottom hint with `!` communicates the scale peak. The punctuation separates the two meanings without changing the vocabulary.

---

## 6. 实施计划 (Implementation)

Phase 12 implements this hierarchy through:

1. Plan 01: ARB value rewrites for the locked ja/zh/en copy values, including `soulLedger`, `survivalLedger`, `homeHappinessROI`, `homeSoulFullness`, satisfaction level labels, and `satisfactionExcellent`.
2. Plan 02: Satisfaction picker icon ladder update, preserving HAPPY-08 value mapping while removing negative-emotion icon semantics.
3. Plan 04: This ADR and ADR index update.
4. Plan 05: Phase close status flip from `📝 草稿` to `✅ 已接受` after verification.

No automated grep guard is added in v1.1. Enforcement is code review plus explicit ADR citation. A future v1.2 candidate (`REGISTER-V2-01` or a dedicated copy guard) may add automated checks for forbidden product-surface terms.

---

## 7. 后果 (Consequences)

### 正面

- Future contributors have a durable rule against reintroducing broad happiness-coded copy into ordinary product UI.
- CN family-mode copy has explicit anti-collision protection: 「家族的小确幸」 is allowed; 「家族悦己」 is not.
- JP satisfaction picker labels have a documented register rationale for future translator review.
- ADR-012 / ADR-013 / ADR-014 become easier to apply because ADR-015 translates their product philosophy into copy rules.

### 负面

- 「幸福密度」 / 「ハピネス密度」 remains the sole exception, so reviewers must watch for overgeneralization. A future copy edit might incorrectly spread 「幸福」 into unrelated UI because it sees the KPI title.
- The hierarchy creates some localized asymmetry: "Joy", 「ときめき」, 「悦己」, and 「小確幸」 are not literal translations. Future translators must preserve role, not word-for-word sameness.
- v1.2 register polish (`REGISTER-V2-01`) should re-audit whether any non-RENAME keys drift from this hierarchy.

### 中立

- ADR-015 is append-only. Future register revisions go in `## Update YYYY-MM-DD: <topic>` sections, not in-place edits.
- Existing ARB keys such as `homeHappinessROI` are not renamed in v1.1; only values and documentation semantics are governed here.

---

## 8. 不在本ADR范围 (Explicitly NOT in scope) — D-08 binding

ADR-015 does NOT relitigate ADR-014's Path B unipolar-positive scale decision: default `soul_satisfaction` 5 -> 2 remains locked.

ADR-015 does NOT relitigate Phase 9 HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping. The picker values remain `{2, 4, 6, 8, 10}`.

ADR-015 does NOT cover voice estimator [3,10] realignment. That remains deferred by ADR-014 D-12 / HAPPY-V2-03 to v1.2.

ADR-015 does NOT cover non-RENAME-01..07 ARB keys. Full register polish is a v1.2 candidate (`REGISTER-V2-01`).

ADR-015 does NOT change schema, enum names, theme colors, chart formulas, picker `_faceValues`, or family aggregate-only contracts.

---

## 9. 相关决策 (References)

References-from:

- **ADR-012 (No Gamification v1.1):** Anti-leaderboard binding informs the CN family-mode anti-collision rule. Family labels must not imply comparative personal soul accounts.
- **ADR-013 (Joy Density PTVF Scaling):** Provides the math-density rationale for the `homeHappinessROI` register exception.
- **ADR-014 (Soul Satisfaction Unipolar Positive Scale):** Provides picker-icon-D-01 root rationale and JP-wellbeing-register-D-03 root rationale.
- **Phase 11 D-13 (FamilyInsightCard 句式):** Family-mode copy patterns use 「家族の小確幸」 / 「家族的小确幸」 as cooperative aggregate language.
- **Phase 10 D-03/D-04 (rings encoding):** Confirms Home rings should not reintroduce happiness-ROI framing or leaderboard semantics.
- **Phase 10 commit `fbd3148`:** Code-level evidence that `homeRingSectionTitleGroup` already landed as zh=「家族的小确幸」 and ja=「家族の小確幸」 before this ADR.

---

## 10. Append-only protocol

Future revisions to this ADR (e.g., v1.2 register polish, new family-mode lexical entries) MUST be appended as `## Update YYYY-MM-DD: <topic>` sections after this section. The above sections (1-9) are immutable once status flips to `✅ 已接受` in Phase 12 close (Plan 05).

---

## 11. 变更历史 (Change Log)

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-05-04 | 1.0 | 初版起草 (Draft) | Claude planning agent |

---

## 12. 下次Review

**下次Review:** v1.2 milestone start
