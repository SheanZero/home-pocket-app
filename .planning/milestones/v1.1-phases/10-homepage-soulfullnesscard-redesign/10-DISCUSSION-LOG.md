# Phase 10: HomePage SoulFullnessCard Redesign - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 10-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 10-HomePage SoulFullnessCard Redesign
**Areas discussed:** Card layout & headline metric, Best Joy story card, Family card mechanics & consent, Empty/info icons, Scope expansion to integrated hero card, Ledger amount display variants, ⓘ tooltip content, Tap navigation

---

## Initial Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| 卡片布局 + 头条指标 | 4-tile arrangement (2x2 / 1+3 hero / 横排), headline tile + caption + ⓘ; recentSoulAmount + currency resolution | ✓ |
| Best Joy 故事卡 + all-neutral CTA | Story card design, "all neutral" CTA copy, ¥ candy anti-framing | ✓ |
| 家庭卡 + consent gate (基建空缺) | Group-mode + consent collapse; consent infrastructure does NOT exist in lib/ today | ✓ |
| Empty / thin-sample / loading + ⓘ icons | totalSoulTx==0 copy, n<5 fallback, multi-AsyncValue handling, 2 info icons | ✓ |

**User's choice:** All 4 areas selected, plus user added "整体布局以及 menu" — drove the discussion to expand into overall home-screen integration question.

---

## Q1.1 — Card layout (3 options as Pencil mockups in row 1)

| Option | Description | Selected |
|--------|-------------|----------|
| A · 1 hero + 3 small | Big headline tile + 3 small tiles below | |
| B · 2x2 grid | 4 equal tiles in 2 rows | ✓ (initially) |
| C · 4 in a row | 4 tiles single row, narrow | |

**User's choice:** "B 会好一些" — but flagged 2 concerns: (1) 本月最值 appears twice (once as tile, once as story), wants tile removed; (2) 数字偏多, wants more visual / less digit-heavy. Triggered v3 redesign.

---

## Q1.2 — Headline metric (2 emphasis options as Pencil mockups)

| Option | Description | Selected |
|--------|-------------|----------|
| D · Single PTVF headline | Only PTVF as hero, others as small tiles | |
| E · Three featured (PTVF + 均值 + 最值) | All 3 promoted equally, Highlights demoted to chip | |

**User's choice:** Skipped — replaced by user's "本月最值 出现两次" feedback redirecting to v3 visual research.

---

## Q3 — 3 visual directions (research-grounded alternatives)

| Option | Description | Selected |
|--------|-------------|----------|
| α · Story-led (Spotify Wrapped vibe) | Best Joy as visual hero, 3 chips below | |
| β · Activity Rings (Apple Health vibe) | 3 concentric rings, Best Joy strip below | ✓ |
| γ · Emoji + Sparkline (picker-aligned) | 5 emoji row + 30-day sparkline + ✨ count | |

**User's choice:** β · Activity Rings, with two additional asks: (a) fold in monthly total + 魂/生存 split; (b) more modern style. Drove v3 (β2/β3) modernization pass.

---

## Q4 — Modernized ring designs (β2 light vs β3 dark vs β1 original)

| Option | Description | Selected |
|--------|-------------|----------|
| β2 · 3 gradient rings (light) | Angular gradient strokes, monthly context strip top, asymmetric legend | (intermediate) |
| β3 · 1 hero ring + dark glassmorphism | One dominant ring, dark glass, satellite stats | |
| β1 原版2 · keep original rings, just add header | Minimum-change fallback | |

**User's choice:** "你没有理解我的意思 — 要不图片中的这部分内容也和同心环融合在一起" + screenshot of existing MonthOverviewCard + LedgerComparisonSection. Reframed as scope expansion question.

---

## Q5 — Scope expansion decision

| Option | Description | Selected |
|--------|-------------|----------|
| 扩大 Phase 10 scope (mockup 集成版 + 写明 + amend REQs) | Add HOMEUI-05/06; complexity M→M-L | |
| Phase 10 保持紧 scope | Just SoulFullnessCard; integration to Phase 13/v1.2 | |
| 先 mockup 集成版看看再决定 | Design first, decide scope after | ✓ |

**User's choice:** Mockup the integrated version first → drove v4 (initial integration with full LedgerComparison rows kept).

---

## Q6 — v4 integrated card lock decision

| Option | Description | Selected |
|--------|-------------|----------|
| Lock v4 集成版 (scope 确认) | Add HOMEUI-05/06 REQs | |
| 微调 v4 (需要改动) | Need adjustments | ✓ |
| 放弃 v4 集成版 | Back to SoulFullnessCard only | |

**User's choice:** "尝试将 LedgerComparisonSection 简化, 单人模式下不显示了, 把内容放入到 Happy 信息里, 如果多人模式, 每行显示群组成员的个人当月支出. 然后 LedgerComparisonSection 放到本月最爱的后面". Drove v5 (single + group modes split, member rows after Best Joy).

---

## Q7 — v5 single + group modes lock decision

| Option | Description | Selected |
|--------|-------------|----------|
| Lock v5 (scope 确认) | New REQ HOMEUI-05/06/07 | |
| 微调 v5 (需要改) | Need adjustments | ✓ |
| 放弃 v5 | Back to v8b | |

**User's choice:** "魂的支出和生存支出是否也作为同心环的一部分" — pushed for soul/survival ratio visualization in rings. Triggered explicit anti-pattern conversation.

---

## Q8 — v5 vs v6 (ratio anti-pattern decision)

| Option | Description | Selected |
|--------|-------------|----------|
| v5 · 3 rings + 内联魂/生存文本 (anti-pattern 免险) | Rings encode happiness only; ledger amounts as inline text | |
| v6 · 4 rings (接受 anti-pattern 调和) | Outer ring = soul/total split; happiness rings inside | |

**User's choice:** "还是恢复 3 环, 但内联文本显示太差, 重新调研对于 魂/生存 金额给出 5 种不同的设计方式". Decision: stay with 3-rings + reject ratio anti-pattern, but redesign the inline text approach. Triggered W1-W5 ledger-display variants.

**Notes:** User accepted Claude's pushback on the soul/total ratio anti-pattern (research line 81-82). The "ratio" visualization risk was understood and avoided. Subsequent W2 selection (split bar) is FACTUAL category split, not ROI metric.

---

## Q9 — 5 ledger amount display variants (W1-W5)

| Option | Description | Selected |
|--------|-------------|----------|
| W1 · Pill chips below rings | 2 colored rounded pills | |
| W2 · Horizontal split bar | Bar above rings + text labels | ✓ (with adjustments) |
| W3 · Compact mini-table | 2 rows with tag + amount + trend | |
| W4 · Hero header inline split | Split chip alongside ¥181,400 | |

**User's choice:** "比较倾向 W2, 但做以下几个调整: 1. 把 split bar (UIKFs) 放到 hero header (P2pF4) 下面; 同心环需要加上标题以及图示要和 OnZCP 一样; 在同心环标题的旁边加入一个 info 标识, 点击后弹窗对同心环进行解释; 再尝试设计一下, 同时给出家庭版本以及 dark 版本设计". Triggered v8 final design.

---

## Q10 — v8 final visual lock decision

| Option | Description | Selected |
|--------|-------------|----------|
| Lock v8 (3 variants: single light + family light + family dark) | Visual contract finalized | |
| 微调 v8 | Need fine-tuning | ✓ |
| 跳过视觉定调 | Skip and discuss other gray areas | |

**User's choice:** "微调 v8". Asked what to adjust next.

---

## Q11 — v8 fine-tune dimensions (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| 颜色 / typography / 间距 | Visual variables tweak | ✓ |
| 某个 section 重排 / 删除 / 重命名 | Layout reorganization | |
| Ring 本身的指标 | Which metrics ring | ✓ |
| 文案 / 标题 / Best Joy 呈现 | Copy + Best Joy treatment | ✓ |

**User's choice (free-text):** "颜色 / typography / 间距, 文案 / 标题 / Best Joy 呈现, Ring 本身的指标 (单人/家庭中哪些上环), 5月文字去掉, Home 头部有月份选择, 不需要重复; 本月最爱微调, 突出做了什么和日期, 弱化价钱"

**Applied changes:**
- Removed all "5月" labels from hero header and ring title row of all 3 v8 cards
- Refactored Best Joy strip: tag "本月最爱" preserved as small accent above, BIG "咖啡店 · 4月15日" emphasizes what+when, small "¥3,000 · 满足 10/10 ✨" de-emphasized
- Color polish deferred to last execution stage (D-13)

---

## Q12 — v8 final lock (after fine-tune)

| Option | Description | Selected |
|--------|-------------|----------|
| Lock v8 · 进入剩余 gray areas | Visual contract locked | ✓ |
| 还要再调 | Further adjustments | |

**User's choice:** "Lock v8 · 进入剩余 gray areas".

---

## Q13a — Consent gate mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| 默认 opt-in · 只靠 group 成员存在性门控 | Minimum gate; FAMILY-03 strict deferred to v1.2 | ✓ |
| Phase 10 引入 placeholder field + ADR | New schema field + ADR + provider | |
| Phase 10 推迟 consent · 补丢水印 | Just disclosure watermark | |

**User's choice:** "默认 opt-in · 只靠 group 成员存在性门控" → captured as D-08; FAMILY-03 strict moved to v1.2 deferred ideas.

---

## Q13b — Empty / thin-sample / "all-neutral" CTA

| Option | Description | Selected |
|--------|-------------|----------|
| 三层阶梯 · 0 折整卡 / thin / sat≤2 CTA | Hide whole card if n=0; thin-sample dimming; D-17 CTA | |
| 全底台保留 · Empty 仅文本提示 | Card always rendered; text "Empty" + D-17 CTA | ✓ |

**User's choice:** "全底台保留 · Empty 仅文本提示" → captured as D-09.

---

## Q13c — ⓘ tooltip content (2 tooltips total)

| Option | Description | Selected |
|--------|-------------|----------|
| Ring title (rings 总体) + Joy/¥ legend (PTVF + voice bias) | Voice bias mentioned in tooltip | ✓ (with edit) |
| Ring title (hedonic adaptation) + 均值 legend (voice bias) | Different placement | |

**User's choice:** "选择1, 但现在还不支持语音打分功能, 所以去掉相关文字" → captured as D-10; voice bias removed from tooltip text. Phase 10 tooltips: (1) ring overview semantics; (2) PTVF + hedonic adaptation.

---

## Q13d — Tap navigation

| Option | Description | Selected |
|--------|-------------|----------|
| 整张卡点击 → AnalyticsScreen 「悦己账本」 sub-region | Single onTap callback | ✓ |
| 多点 · ring/best joy/member 行都独立点 | Multiple tap targets | |
| Phase 10 不实现 · 仅 chevron | Defer until Phase 11 ready | |

**User's choice:** "整张卡点击 → 跳转 AnalyticsScreen 「悦己账本」 子区 (Phase 11 deliver)" → captured as D-11.

---

## Claude's Discretion

Areas where the planner has flexibility (per CONTEXT.md D-decisions):

- Widget naming (`HomeHeroCard` vs alternatives)
- File split strategy (master file vs split into rings/member-rows sub-widgets)
- Empty-state copy exact wording
- ⓘ tooltip implementation (Tooltip widget vs custom modal)
- Ring sweep angles for Empty() state (0 vs subdued track)
- Member row avatar color palette derivation
- Trend chip basis (month-over-month formula details)

## Deferred Ideas

### Out-of-Phase-10 (still v1.1)
- AnalyticsScreen 「悦己账本」 sub-region (Phase 11)
- HAPPY-06 thin-sample dim treatment in charts (Phase 11)
- ARB value renames for `homeSoulFullness` / `homeHappinessROI` (Phase 12)

### Out-of-v1.1 (v2 / future milestones)
- Strict FAMILY-03 consent gate with `family_members.shared_analytics_opt_in` field + provider + group settings UI + ADR (Privacy Consent Gate v1.2)
- Voice estimator output range realignment + voice-bias tooltip mention (already deferred per Phase 9 D-12)
- Differentiated tap targets per card section (whole-card-tap is Phase 10 baseline)
- Currency code awareness in `familyHappinessProvider` (currency-agnostic in v1.1)
- Color polish framework / theme-token unification refactor
- `InfoIconButton` reusable widget (if Phase 11 needs same tooltip pattern)

### Forbidden anti-features (binding through milestone close per ADR-012)
- "Joy ROI" / "happiness share" / "soul %" framing
- Per-member happiness leaderboard
- Cross-period happiness comparison chip
- Streaks/badges/targets on rings
- AI-generated joy interpretation
- Public sharing of happiness metrics
- Editable Best Joy ("promote a different transaction")

---

## Scope expansion summary (most consequential outcome)

Phase 10's scope grew during discussion:
- **Original (entering discussion):** Rebuild only `SoulFullnessCard` (REQs HOMEUI-01..04 + FAMILY-03)
- **Final (post-v8 lock):** Replace 3 widgets with 1 integrated `HomeHeroCard` (REQs HOMEUI-01..07 + FAMILY-03)
- **Net additions:** HOMEUI-05 (hero absorbs monthly total), HOMEUI-06 (hero absorbs 魂/生存 split bar), HOMEUI-07 (group mode appends member rows)
- **Net deletions from home_screen tree:** `MonthOverviewCard`, `LedgerComparisonSection`
- **Complexity adjustment:** M → M-L
- **Spec amendment plan units:** 1 plan to amend REQUIREMENTS.md (add HOMEUI-05/06/07 + traceability) + 1 plan to amend ROADMAP.md (Phase 10 goal + critical pitfalls)

This is a substantive enough scope shift that the planner SHOULD allocate 2 explicit plan units for the spec amendments (mirroring Phase 9's plan 09-13 spec-amendments unit). Failing to amend specs before implementation creates a documentation/code drift surface — Phase 8 cleanup-style audit findings would re-emerge.
