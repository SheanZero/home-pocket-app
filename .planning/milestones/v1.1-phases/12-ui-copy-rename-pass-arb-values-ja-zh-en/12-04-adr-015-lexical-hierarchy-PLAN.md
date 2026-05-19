---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 04
type: execute
wave: 3
depends_on:
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/01
files_modified:
  - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
  - docs/arch/03-adr/ADR-000_INDEX.md
autonomous: true
requirements:
  - RENAME-05
user_setup: []

must_haves:
  truths:
    - "ADR-015 file exists at docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md, status `📝 草稿` (Draft) on creation, with Decision date 2026-05-04"
    - "ADR-015 contains a 三语 lexical hierarchy table (rows: documentation register / in-product UI register / KPI math-density exception) per D-08"
    - "ADR-015 contains an explicit CN family-mode anti-collision rule citing Phase 11 commit-of-record for `homeRingSectionTitleGroup` zh=「家族的小确幸」 + ja=「家族の小確幸」 (commit hash to be filled in by executor at write time)"
    - "ADR-015 contains a JP wellbeing-register subsection naming the kanji ladder 無難 / 快適 / 順調 / 満足 / 至福 and explaining why katakana / philosophical kanji registers were rejected"
    - "ADR-015 explicitly DOES NOT relitigate ADR-014 (Path B unipolar-positive scale) — D-08 binding"
    - "ADR-015 explicitly DOES NOT relitigate Phase 9 HAPPY-08 5-emoji ↔ {2,4,6,8,10} mapping — D-08 binding"
    - "ADR-015 lists References-from: ADR-012 / ADR-013 / ADR-014 / Phase 11 D-13 / Phase 10 D-03/D-04"
    - "ADR-015 declares Append-only update protocol (`## Update YYYY-MM-DD: <topic>` sections)"
    - "ADR-000_INDEX.md gains a new ADR-015 section + statistics block updates (草稿 count 3→4, 总计 14→15)"
  artifacts:
    - path: "docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md"
      provides: "Draft ADR codifying lexical hierarchy + JP register + CN family-mode anti-collision"
      min_lines: 120
    - path: "docs/arch/03-adr/ADR-000_INDEX.md"
      provides: "Index entry for ADR-015 + updated statistics"
      contains: "ADR-015"
  key_links:
    - from: "docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md"
      to: "docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md"
      via: "References-from citation"
      pattern: "ADR-015 cites ADR-014 as the picker-icon-D-01 + JP-wellbeing-register-D-03 root rationale"
    - from: "docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md"
      to: "lib/l10n/app_zh.arb#homeRingSectionTitleGroup"
      via: "Phase 11 commit reference"
      pattern: "ADR-015 cites the Phase 11 commit that landed zh=「家族的小确幸」 as evidence for the anti-collision rule"
---

<objective>
Draft `ADR-015_Lexical_Hierarchy_v1_1.md` — the architecture decision record formally codifying (a) the trilingual lexical hierarchy distinguishing documentation-register words (幸福 / happiness / ハピネス) from in-product UI words (悦己 / Joy / ときめき), with `homeHappinessROI` as the sole math-density exception, (b) the CN family-mode anti-collision rule (使用「家族的小确幸」 NOT 「家族悦己」 to avoid carrier-clash with `soulLedger` 「悦己账本」), and (c) the JP wellbeing-kanji-ladder picker-label register choice (無難 → 快適 → 順調 → 満足 → 至福). Per D-08, the ADR explicitly does NOT relitigate ADR-014's Path B unipolar-positive semantics nor Phase 9's HAPPY-08 5-emoji value mapping. Status starts at 📝 草稿 (Draft); flip to ✅ 已接受 happens in Plan 05 at phase close. Update `ADR-000_INDEX.md` with the new section and bump statistics.

Purpose: RENAME-05 deliverable + permanent reference for any future "幸福/happiness in product UI?" or "家族悦己 OK to use?" question. Without this ADR, the lexical hierarchy lives only in CONTEXT.md scratch and PLAN frontmatter; subsequent milestones cannot durably enforce it.

Output: 1 new file (ADR-015) + 1 file edited (INDEX), 1 atomic commit.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md
@docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md
@docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md
@docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md
@docs/arch/03-adr/ADR-000_INDEX.md
@.claude/rules/arch.md

<interfaces>
<!-- Phase 11 commit-of-record for `homeRingSectionTitleGroup` -->
Phase 11 landed zh="家族的小确幸" and ja="家族の小確幸" at lib/l10n/app_zh.arb:693 + lib/l10n/app_ja.arb:693. Executor MUST identify the originating commit at write-time via:
  `git log --oneline -- lib/l10n/app_zh.arb | head -20`
and pick the commit that introduced "家族的小确幸". Cite that hash in ADR-015 §"CN family-mode anti-collision".

<!-- ADR-000 INDEX current statistics block (verified at planner read time, lines 480-491) -->
```
| 状态 | 数量 |
|------|------|
| ✅ 已接受 | 10 |
| ✅ 已实施 | 1 |
| 🔄 讨论中 | 0 |
| ❌ 已拒绝 | 0 |
| 📝 草稿 | 3 |

**总计:** 14个ADR
```

After Plan 04 (ADR-015 added as Draft), the block becomes:
```
| ✅ 已接受 | 10 |
| ✅ 已实施 | 1 |
| 🔄 讨论中 | 0 |
| ❌ 已拒绝 | 0 |
| 📝 草稿 | 4 |

**总计:** 15个ADR
```

(Plan 05 will flip ADR-015 from 📝 草稿 → ✅ 已接受 at phase close — that is a separate plan and a separate INDEX edit.)

<!-- Existing ADR-014 cross-reference for follow-on link -->
ADR-014 lines 446-449 contain the deferred-items entry that mentions Phase 12 picker icon update; ADR-015 should cite ADR-014 in References-from but NOT modify ADR-014's text (ADR-014 is append-only and its substantive Path B decision is locked).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Identify Phase 11 commit-of-record for `homeRingSectionTitleGroup`</name>
  <files>(read-only — capture commit hash for use in Task 2)</files>
  <read_first>
    - lib/l10n/app_zh.arb lines 690-705 (confirm `homeRingSectionTitleGroup` value still 「家族的小确幸」)
  </read_first>
  <action>
    Run:
    ```
    git log --oneline -- lib/l10n/app_zh.arb | head -30
    git log -p --follow -- lib/l10n/app_zh.arb | grep -B2 "家族的小确幸" | head -20
    ```

    Identify the earliest commit that introduced `"homeRingSectionTitleGroup": "家族的小确幸"`. Capture both the short SHA (7 chars) and the commit subject for citation in Task 2. If the value was introduced via squash/merge and the originating commit cannot be cleanly identified, fall back to the merge-point commit on `main` and note the limitation.
  </action>
  <verify>
    <automated>git log --all --oneline --grep="家族的小确幸\|homeRingSectionTitleGroup" | head -10 || git log -p -- lib/l10n/app_zh.arb | grep "家族的小确幸" | head -3</automated>
  </verify>
  <acceptance_criteria>
    - Executor has identified at least one commit hash + subject mentioning `homeRingSectionTitleGroup` OR `家族的小确幸`
    - The hash is recorded for use in Task 2 (held in context, no file edit yet)
  </acceptance_criteria>
  <done>Phase 11 commit-of-record identified.</done>
</task>

<task type="auto">
  <name>Task 2: Author ADR-015 file (Draft status)</name>
  <files>docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md (full file — match document tone, header style, references format)
    - docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md (full file — match v1.1-suffix ADR conventions: "草稿" status, append-only protocol, milestone-bound review schedule)
    - .claude/rules/arch.md (ADR file structure, naming, header fields, append-only rule)
  </read_first>
  <action>
    Create `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`. The file MUST contain the following sections in this order, matching the structural pattern of ADR-012/013/014 (which are the v1.1 sibling ADRs):

    **Header block:**
    ```markdown
    # ADR-015: 词汇分层 v1.1 (Lexical Hierarchy v1.1)

    **状态:** 📝 草稿
    **日期:** 2026-05-04
    **决策者:** zxsheanjp@gmail.com (project owner) + Claude (planning agent)
    **影响范围:** v1.1 milestone UI copy register (ja/zh/en); product-vs-documentation lexical separation; CN family-mode naming; JP picker-label wellbeing register
    ```

    **Section 1 — 背景与问题陈述 (Context):**
    Explain that v1.1 introduces happiness-themed UI surfaces (HomeHeroCard, AnalyticsScreen Variant δ, satisfaction picker) requiring three vocabularies: (a) the philosophical / wellbeing-research register that lives in ADR / docs / README ("幸福" / "happiness" / "ハピネス"), (b) the in-product register that ships to end-users ("悦己" / "Joy" / "ときめき"), and (c) the math-density register where "幸福" is the only legitimate in-product use because the value is a Prospect-Theory density (`homeHappinessROI` KPI title — ADR-013).

    **Section 2 — 决策驱动因素 (Forces):**
    - Anti-Goodhart: ADR-012 binding bans gamification; copy register matters because 「幸福」 in product UI primes self-judgment / leaderboard mental models
    - Three-language asymmetry: each language has different register-stress points (ja: katakana-vs-kanji-vs-hiragana register; zh: philosophical-vs-product register; en: clinical-vs-emotive register)
    - CN family-mode collision risk: post-rename `soulLedger` zh=「悦己账本」 means any family-mode label using 「悦己」 reads as "family is one user's personal soul account" — corrupts the dual-ledger semantic
    - Picker icon binding: ADR-014 Path B (default 5→2; emoji-1 must never be a negative face) creates asymmetric register pressure on val=2 label — it must read as "wellbeing-baseline" not "neutral-as-philosophical-zero" not "negative-emotion-suppressed"

    **Section 3 — 备选方案 (Considered Options):**
    Briefly compare and reject:
    - **Option A**: Allow 「幸福」 / "happiness" / 「ハピネス」 freely in product UI (rejected — primes self-judgment per ADR-012)
    - **Option B**: Use only kanji-native vocabulary in JP product UI, never katakana (rejected — `homeHappinessROI` math-density title legitimately needs 「ハピネス密度」 because the math is a density, not an emotion claim)
    - **Option C**: Use 「家族悦己」 in CN family-mode (rejected — collides with `soulLedger` 「悦己账本」)
    - **Option D (CHOSEN)**: Three-tier hierarchy with the math-density carve-out + explicit family-mode anti-collision rule + explicit JP wellbeing-kanji-ladder picker-label register

    **Section 4 — 决策 (Decision):**
    Present a clean trilingual hierarchy table:
    ```
    | Register tier            | en          | ja          | zh          |
    |--------------------------|-------------|-------------|-------------|
    | Documentation / README   | happiness   | ハピネス    | 幸福        |
    | In-product UI (default)  | Joy         | ときめき    | 悦己        |
    | KPI math-density title   | Joy per ¥   | ハピネス密度 | 幸福密度    |
    | Family-mode label        | Family Joy  | 家族の小確幸 | 家族的小确幸 |
    ```

    Add explanatory paragraphs:
    - Why `homeHappinessROI` retains 「幸福」/「ハピネス」/「Happiness」 (ROADMAP-locked: en="Joy per ¥") — it is a Prospect-Theory density (ADR-013), not an emotion claim
    - Why family-mode uses 「家族的小確幸」 NOT 「家族悦己」 — anti-collision with personal `soulLedger`; aligns with ADR-012 anti-leaderboard binding (a family is not a competing-soul-accounts scoreboard)
    - **Phase 11 evidence**: cite the commit-of-record from Task 1 that landed `homeRingSectionTitleGroup` zh=「家族的小确幸」 + ja=「家族の小確幸」 — this rule predates ADR-015 in code; ADR-015 codifies the de-facto pattern.

    **Section 5 — JP wellbeing-register subsection:**
    Explain the picker-label kanji ladder choice: 無難 / 快適 / 順調 / 満足 / 至福 (val=2/4/6/8/10).
    - Why 無難 (rejected: 中性, フラット, 平静) — wellbeing-anchor at "no problems / unobjectionable", read-along with `soulLedger` ときめき帳 + `survivalLedger` 日々の帳 全 kanji 和風 register
    - Why the ladder is consistent register: kanji 全 + each step a familiar wellbeing kanji compound, no katakana mixing, no philosophical-research register intrusion
    - Why 至福 (val=10) ≠ 至福！ (bottomLabel) — picker UX double-semantic: level-achieved vs scale-anchor hint; the ! 区分 carries the second meaning (D-05)

    **Section 6 — 实施计划 (Implementation):**
    State that the lexical hierarchy is implemented by Phase 12 ARB value rewrites (Plan 01) + picker icon ladder (Plan 02). Future enforcement = code review + grep guards (no automated guard added in v1.1; FUTURE-V2 candidate).

    **Section 7 — 后果 (Consequences):**
    - 正面: durable rule against re-introducing happiness-coded copy; explicit family-mode anti-collision protection; JP wellbeing register documented for future translators
    - 负面: KPI title 「幸福密度」 is the sole exception, requires reviewer vigilance to spot drift (a future copy edit could overgeneralize 「幸福」 to other surfaces); v1.2 register-polish pass (REGISTER-V2-01) may need to re-audit
    - 中立: ADR-015 is append-only — future register revisions go in `## Update YYYY-MM-DD: <topic>` sections, not in-place edits

    **Section 8 — 不在本ADR范围 (Explicitly NOT in scope) — D-08 binding:**
    State explicitly:
    - ADR-015 does NOT relitigate ADR-014's Path B unipolar-positive scale decision (default soul_satisfaction 5 → 2)
    - ADR-015 does NOT relitigate Phase 9 HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping
    - ADR-015 does NOT cover voice estimator [3,10] realignment (ADR-014 D-12 / HAPPY-V2-03 deferred to v1.2)
    - ADR-015 does NOT cover non-RENAME-01..07 ARB keys (REGISTER-V2-01 v1.2 pass)

    **Section 9 — 相关决策 (References):**
    - ADR-012 (No Gamification) — anti-leaderboard binding informs CN family-mode anti-collision
    - ADR-013 (PTVF Scaling) — math-density rationale for `homeHappinessROI` register exception
    - ADR-014 (Soul Satisfaction Unipolar Positive Scale) — picker-icon-D-01 root + JP-wellbeing-register-D-03 root
    - Phase 11 D-13 (FamilyInsightCard 句式) — family-mode 「家族の小確幸」 / 「家族的小确幸」 evidence
    - Phase 10 D-03/D-04 (rings encoding) — confirms no happiness-ROI framing reintroduced in Home

    **Section 10 — Append-only protocol:**
    State: "Future revisions to this ADR (e.g., v1.2 register polish, new family-mode lexical entries) MUST be appended as `## Update YYYY-MM-DD: <topic>` sections after this section. The above sections (1-9) are immutable once status flips to ✅ 已接受 in Phase 12 close (Plan 05)."

    **Section 11 — 变更历史 (Change Log):**
    | 日期 | 版本 | 变更内容 | 作者 |
    |------|------|---------|------|
    | 2026-05-04 | 1.0 | 初版起草 (Draft) | Claude planning agent |

    **Section 12 — 下次Review:**
    `**下次Review:** v1.2 milestone start`

    Aim for ~150-200 lines. Match the writing register / formatting style of ADR-014 (which is also a v1.1 ADR with Chinese section headers + bilingual content). DO NOT use emojis except in section headers / status badge per ADR convention. DO NOT include placeholder template text from `arch.md` template — write substantive content.
  </action>
  <verify>
    <automated>test -f docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md && wc -l docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md | awk '{print $1}'</automated>
  </verify>
  <acceptance_criteria>
    - File exists at the exact path `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`
    - File line count >= 120 (substantive content, not skeleton)
    - `grep -c "📝 草稿" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (status badge)
    - `grep -c "2026-05-04" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (date)
    - `grep -c "ハピネス密度" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (math-density exception captured)
    - `grep -c "家族的小确幸" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (anti-collision rule)
    - `grep -c "家族悦己" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (forbidden form mentioned in Option C / decision rationale)
    - `grep -c "無難" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (JP val=2 ladder anchor)
    - `grep -c "至福" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (JP val=10 ladder peak)
    - `grep -c "ADR-014" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (References)
    - `grep -c "ADR-013" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (References)
    - `grep -c "ADR-012" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (References)
    - `grep -c "Append-only\|append-only" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1
    - `grep -c "HAPPY-08\|5-emoji.*mapping\|{2, 4, 6, 8, 10}\|{2,4,6,8,10}" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (negative-scope statement: explicitly NOT relitigating)
    - `grep -c "不在本ADR范围\|NOT in scope\|D-08" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1
    - File DOES NOT include the literal phrase "Path B unipolar-positive scale 决议" as a (re-)decision — only as a NOT-in-scope reference
  </acceptance_criteria>
  <done>ADR-015 file authored with all 12 sections, Phase 11 commit-of-record cited, status 📝 草稿.</done>
</task>

<task type="auto">
  <name>Task 3: Insert ADR-015 entry into ADR-000_INDEX.md</name>
  <files>docs/arch/03-adr/ADR-000_INDEX.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-000_INDEX.md lines 430-490 (existing ADR-014 entry + statistics block + review schedule table)
  </read_first>
  <action>
    Three Edit tool calls:

    **Edit 1 — insert ADR-015 entry between ADR-014 entry and the `## 🔗 ADR关系图` section:**

    The ADR-014 entry ends at approximately line 451 with the line `**下次Review:** v1.2 milestone start`. Locate the `---` separator that follows ADR-014, and add the ADR-015 entry immediately after that separator.

    Old anchor (find this exact line):
    ```
    **下次Review:** v1.2 milestone start

    ---

    ## 🔗 ADR关系图
    ```

    Replace with:
    ```
    **下次Review:** v1.2 milestone start

    ---

    ### [ADR-015: 词汇分层 v1.1](./ADR-015_Lexical_Hierarchy_v1_1.md)

    **状态:** 📝 草稿
    **日期:** 2026-05-04
    **影响范围:** v1.1 milestone UI copy register (ja/zh/en); product-vs-documentation lexical separation; CN family-mode naming; JP picker-label wellbeing register

    **核心决策:**
    三层 lexical hierarchy: 文档 register 用 「幸福/happiness/ハピネス」; 产品 UI register 用 「悦己/Joy/ときめき」; KPI 数学密度标题 (`homeHappinessROI` 「幸福密度/Joy per ¥/ハピネス密度」) 是产品 UI 中保留 「幸福/Happiness」字样的唯一例外 (PTVF 数学语义 — ADR-013)。CN family-mode 标题 MUST 使用 「家族的小确幸 / 家族の小確幸 / Family Joy」 NOT 「家族悦己」 (与 personal `soulLedger` 「悦己账本」 命名碰撞)。JP picker 等级标签使用全 kanji wellbeing ladder「無難 → 快適 → 順調 → 満足 → 至福」, 与 `ときめき帳 / 日々の帳` 和風文学 register 同列。

    **关键理由:**
    - Anti-Goodhart 防御 (ADR-012 互证): 「幸福」 在产品 UI 中会激发 self-judgment / leaderboard 心智模型
    - CN family-mode 反碰撞: post-rename `soulLedger` zh=「悦己账本」 使 「家族悦己」 读作 "家庭是某用户的私人灵魂账户", 破坏双轨账本语义
    - JP picker val=2 register: ADR-014 Path B 锁定 emoji-1 不可再传递负面情绪, val=2 标签必须读作 "wellbeing-baseline" 而非 「中性」 (哲学/物理学 register) 或 「フラット」 (片假名现代 register, 与 和風 anchor 不一致)

    **不在本 ADR 范围 (D-08 binding):**
    - ❌ 不重新决议 ADR-014 Path B unipolar-positive scale (default 5→2) — 已锁
    - ❌ 不重新决议 HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping — Phase 9 picker test 已锚
    - ❌ 不覆盖 voice estimator [3,10] 重对齐 — ADR-014 D-12 / HAPPY-V2-03 deferred 到 v1.2

    **Append-only:**
    未来的 lexical hierarchy 修订必须以 `## Update YYYY-MM-DD: <topic>` 章节追加, 不修改原决议正文。

    **下次Review:** v1.2 milestone start

    ---

    ## 🔗 ADR关系图
    ```

    **Edit 2 — update statistics block (lines ~482-491):**

    Old:
    ```
    | 状态 | 数量 |
    |------|------|
    | ✅ 已接受 | 10 |
    | ✅ 已实施 | 1 |
    | 🔄 讨论中 | 0 |
    | ❌ 已拒绝 | 0 |
    | 📝 草稿 | 3 |

    **总计:** 14个ADR
    ```

    New:
    ```
    | 状态 | 数量 |
    |------|------|
    | ✅ 已接受 | 10 |
    | ✅ 已实施 | 1 |
    | 🔄 讨论中 | 0 |
    | ❌ 已拒绝 | 0 |
    | 📝 草稿 | 4 |

    **总计:** 15个ADR
    ```

    **Edit 3 — append ADR-015 row to the Review Schedule table (lines ~497-512):**

    Old final row (the ADR-014 row):
    `| ADR-014 | v1.2 milestone start | 一次性评估 |`

    Replace with:
    ```
    | ADR-014 | v1.2 milestone start | 一次性评估 |
    | ADR-015 | v1.2 milestone start | 一次性评估 |
    ```

    Also bump the `**最后更新:**` field at the bottom of the file from `2026-05-01` to `2026-05-04` and the `**文档版本:**` from `1.3` to `1.4`.
  </action>
  <verify>
    <automated>grep -c "ADR-015" docs/arch/03-adr/ADR-000_INDEX.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "ADR-015: 词汇分层 v1.1" docs/arch/03-adr/ADR-000_INDEX.md` returns at least 1
    - `grep -c "./ADR-015_Lexical_Hierarchy_v1_1.md" docs/arch/03-adr/ADR-000_INDEX.md` returns at least 1
    - `grep -c "📝 草稿 | 4" docs/arch/03-adr/ADR-000_INDEX.md` returns exactly 1
    - `grep -c "总计:\\*\\* 15个ADR\\|总计：\\*\\* 15个ADR" docs/arch/03-adr/ADR-000_INDEX.md` returns 1 (handles both ASCII and full-width colon)
    - `grep -c "📝 草稿 | 3" docs/arch/03-adr/ADR-000_INDEX.md` returns 0 (old line gone)
    - `grep -c "总计:\\*\\* 14个ADR\\|总计：\\*\\* 14个ADR" docs/arch/03-adr/ADR-000_INDEX.md` returns 0 (old total gone)
    - `grep -c "| ADR-015 | v1.2 milestone start" docs/arch/03-adr/ADR-000_INDEX.md` returns exactly 1 (review row)
    - `grep -c "最后更新:.*2026-05-04" docs/arch/03-adr/ADR-000_INDEX.md` returns at least 1
    - `grep -c "文档版本:.*1.4" docs/arch/03-adr/ADR-000_INDEX.md` returns at least 1
  </acceptance_criteria>
  <done>INDEX gains ADR-015 section + statistics + review row + version bump.</done>
</task>

<task type="auto">
  <name>Task 4: Commit ADR-015 draft + INDEX update</name>
  <files>(git commit only)</files>
  <read_first>
    - .claude/rules/arch.md (commit message format for arch docs: `docs(arch): ...`)
  </read_first>
  <action>
    Stage exactly 2 files (`docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` + `docs/arch/03-adr/ADR-000_INDEX.md`) and commit:

    ```
    docs(arch): add ADR-015 Lexical Hierarchy v1.1 (Draft)

    Phase 12 RENAME-05 deliverable. ADR-015 codifies the trilingual lexical
    hierarchy:
    - Documentation register: 幸福 / happiness / ハピネス
    - In-product UI register: 悦己 / Joy / ときめき
    - KPI math-density exception (ADR-013): 幸福密度 / Joy per ¥ /
      ハピネス密度 — sole legitimate "happiness" reference in product UI
    - CN family-mode anti-collision: 家族的小确幸 NOT 家族悦己 (collision
      with personal soulLedger 「悦己账本」)
    - JP wellbeing-kanji-ladder picker labels: 無難 / 快適 / 順調 / 満足 / 至福

    Status: 📝 草稿 (Draft); flips to ✅ 已接受 at Phase 12 close (Plan 05).
    Append-only protocol declared.

    Per D-08, ADR-015 explicitly does NOT relitigate:
    - ADR-014 Path B unipolar-positive scale (default 5→2)
    - HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping
    - Voice estimator [3,10] realignment (deferred per ADR-014 D-12)

    INDEX updates:
    - New ADR-015 section between ADR-014 and ADR关系图
    - Statistics: 草稿 3→4; 总计 14→15
    - Review schedule: ADR-015 added with v1.2 milestone start
    - 最后更新 → 2026-05-04; 文档版本 → 1.4

    Refs: D-07, D-08; RENAME-05; Phase 11 commit-of-record for
    homeRingSectionTitleGroup
    ```

    DO NOT use `git add -A`. Stage only the 2 files.
  </action>
  <verify>
    <automated>git diff HEAD~1 --stat | grep -E "(ADR-015_Lexical_Hierarchy_v1_1\.md|ADR-000_INDEX\.md)" | wc -l | grep -q 2 && git log -1 --pretty=format:"%s" | grep -q "docs(arch).*ADR-015 Lexical Hierarchy" && echo PASS || echo FAIL</automated>
  </verify>
  <acceptance_criteria>
    - Commit subject: `docs(arch): add ADR-015 Lexical Hierarchy v1.1 (Draft)`
    - `git diff HEAD~1 --stat` shows exactly 2 files
    - Commit body references D-07, D-08, RENAME-05
    - `git status` clean post-commit
  </acceptance_criteria>
  <done>ADR-015 + INDEX update committed atomically.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| ADR doc ↔ future code review | ADR-015 is the durable contract reviewers cite when blocking PRs that reintroduce 「家族悦己」 / negative-emotion picker icons / 「幸福」 in product UI surfaces (excepting `homeHappinessROI`). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-09 | Repudiation | Future contributor reverts CN family-mode to 「家族悦己」 not knowing about anti-collision rule | mitigate | ADR-015 records the rule + cites Phase 11 commit-of-record. Code review is the human gate. |
| T-12-10 | Tampering | ADR-015 substantive sections edited in-place after status flip | mitigate | Section 10 (Append-only protocol) declares immutability post-✅. Plan 05 status flip will reinforce. |
| T-12-11 | Information disclosure | None — ADR contains no secrets | accept | Public-facing architectural doc; intended for contributor visibility. |
</threat_model>

<verification>
- ADR-015 file exists with all 12 sections, line count ≥ 120
- Status badge `📝 草稿` present
- D-08 NOT-in-scope statement present (ADR-014 Path B + HAPPY-08 mapping not relitigated)
- Append-only protocol section present
- INDEX shows ADR-015 entry, 4 草稿 / 15 total, ADR-015 review row
- Single commit with `docs(arch):` subject affecting exactly 2 files
</verification>

<success_criteria>
- ADR-015 ratified as Draft per D-07 / D-08
- INDEX consistent with Draft state (will flip to ✅ in Plan 05)
- Phase 11 commit-of-record cited for CN family-mode anti-collision precedent
</success_criteria>

<output>
After completion, create `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md` summarizing:
- ADR-015 sections (1-12 outline) + line count
- Phase 11 commit hash cited for `homeRingSectionTitleGroup`
- INDEX edit locations + statistics math
- Commit hash
</output>
