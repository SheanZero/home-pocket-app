# Phase 12: UI Copy Rename Pass (ARB values, ja/zh/en) - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 是 v1.1 milestone 的最后一个 phase，**values-only ARB rename** + **picker icon 重设** + **lexical-hierarchy ADR** + **register-aware native-speaker review**。完全机械化的范围、无 schema/逻辑/视觉重构。

**Delivered surface:**
- ARB 值更新 across `lib/l10n/app_{en,ja,zh}.arb` 三语 ×（4 个 home/ledger keys + 5 个 satisfaction level keys + 1 个 satisfaction bottom hint key = **共 10 个 key 的值改写**），keys 全部不动
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart`: 5 个 icon 替换为 sentiment-positive 升级序列
- `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`: 新建（仅 lexical hierarchy；不重复 ADR-014 已有的 Path B unipolar positive 语义决议）
- `flutter gen-l10n` 重生成 `lib/generated/app_localizations*.dart`
- ARB-parity CI guardrail 必须绿
- 既有的 satisfaction picker test (`test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`) 标签字符串需更新且必须仍 pass — pinning HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping

**Not delivered (downstream / deferred):**
- ARB key rename for `homeHappinessROI` / `homeSoulFullness`（已无消费者，但 RENAME-03/04 锁定 values-only；key GC 推迟到 v1.2 → TOOL-V2-02）
- Voice estimator output 重对齐（[3,10] → {2,4,6,8,10}）— ADR-014 锁定 v1.2 → HAPPY-V2-03
- 其他 ARB key / 翻译值 polish（v1.2 register pass）
- 视觉/色调/排版改动（不在 Phase 12 范围）

**Phase 12 是 milestone v1.1 的最后一个 phase**，依赖 Phase 10 + Phase 11 完成；**MUST be LAST** —— ARB churn 与 widget 编辑并行会触发 merge 摩擦。

</domain>

<decisions>
## Implementation Decisions

### Picker icon set (5 icons, ADR-014 unipolar-positive 校准)

- **D-01: 5 icons = sentiment 升级序列**（替换当前 4 sentiment + 1 favorite_border 的不对称组合）：
  - val=2: `Icons.sentiment_neutral_outlined`（替换原 `sentiment_very_dissatisfied_outlined`）
  - val=4: `Icons.sentiment_satisfied_outlined`（替换原 `sentiment_dissatisfied_outlined`）
  - val=6: `Icons.sentiment_satisfied_alt_outlined`（替换原 `sentiment_neutral_outlined`）
  - val=8: `Icons.sentiment_very_satisfied_outlined`（替换原 `sentiment_satisfied_alt_outlined`）
  - val=10: `Icons.favorite_border`（**保留**，与 levelLabels[4] 「至福/最爱/Amazing」语义一致）
  - **Planner verification 要求**：在 plan 阶段确认 `sentiment_satisfied_outlined`（不带 `_alt`）在 Flutter Material Icons 中存在。Flutter 标准的 `Icons.sentiment_satisfied` 是 alias 为 `sentiment_satisfied_alt`；需要 grep `Icons.sentiment_*` 确认 outlined variant 命名是否完全一致。如不存在，planner 用 `sentiment_neutral_outlined` 与 `sentiment_satisfied_alt_outlined` 之间的中间态备选（如 `sentiment_neutral_outlined` + 自定义淡色调），并回填本 D-01。
  - 颜色 token 不动：tile 颜色继续用 `AppColors.tagGreen` (selected) / `AppColorsDark.tagGreen`；icon 颜色继续 `AppColors.soul`（selected）/ `AppColors.textSecondary`（unselected）。dark mode token 完全沿用现有逻辑。
  - 选中态 affordance（border / scale / shadow）不动 — 与现 widget 一致。

### Translation 值锁定 (locked via 4-area discussion)

- **D-02: 4 个 home/ledger keys 翻译值**（RENAME-01..04，全部 PROJECT.md 既锁，**keys 不动**）：

| ARB key | en | ja | zh |
|---|---|---|---|
| `soulLedger` | Joy Ledger | ときめき帳 | 悦己账本 |
| `survivalLedger` | Daily Ledger | 日々の帳 | 日常账本 |
| `homeHappinessROI` ⚰️ | Joy per ¥ | ハピネス密度 | 幸福密度 |
| `homeSoulFullness` ⚰️ | Joy Index | ときめき度 | 悦己充盈 |

  - ⚰️ 标记 = post-Phase-10 已无 Dart 消费者（HomeHeroCard 用新 keys 替代），但 RENAME-03/04 仍按 spec 改值；详见 D-04。
  - EN `homeHappinessROI` 选 ROADMAP「Joy per ¥」(非 PROJECT.md「Joy / ¥」分式) — 语法更逸、避免分式误读；该 key 无消费者，效果纯文档行为。

- **D-03: 5 个 satisfaction picker level keys 翻译值**（RENAME 主体，对应 picker emoji val=2/4/6/8/10）：

| ARB key | val | icon | en | ja | zh |
|---|---|---|---|---|---|
| `satisfactionBad` | 2 | sentiment_neutral | Neutral | **無難** | **平和** |
| `satisfactionSlightlyBad` | 4 | sentiment_satisfied | OK | **快適** | OK |
| `satisfactionNormal` | 6 | sentiment_satisfied_alt | Good | **順調** | 不错 |
| `satisfactionGood` | 8 | sentiment_very_satisfied | Great | **満足** | 满足 |
| `satisfactionVeryGood` | 10 | favorite_border | Amazing | **至福** | 最爱 |

  - **JP set = 全 kanji wellbeing ladder**（無難 → 快適 → 順調 → 満足 → 至福）。Anchored on val=2 = 無難（"no problems / unobjectionable"），与 `soulLedger` ときめき帳 / `survivalLedger` 日々の帳 的和风文学 register 同列。**ADR-015 必须把这个 JP wellbeing register 选择记入 lexical hierarchy 决议**（本套不是 ROADMAP 原 "中性 / OK / 不錯 / 満足 / 最愛"，是 discuss 后的修订）。
  - **Collision check**：JP 「至福」 ≠ JP 「ときめき度」（homeSoulFullness 锁），无 ARB 字根冲突；JP 「無難」 ≠ JP 「日々の帳」/「ときめき帳」，无冲突；JP 「至福」 ≠ Phase 10 「本月最爱」 ARB tag（en 锁字 "Amazing" 不冲突 EN tag "本月最爱" 中文）。
  - **ZH val=2 = 平和**（替换 ROADMAP 原 「中性」 — 后者 philosophical/物理学 register，与 ZH product UI 不亲和）。其余 ZH 4 项保持 ROADMAP 原文。
  - **EN 全套 = ROADMAP 原文** Neutral / OK / Good / Great / Amazing — 满足 ADR-014 unipolar-positive 语义，无修订。

- **D-04: `homeHappinessROI` / `homeSoulFullness` 死键处理 = 仍按 RENAME-03/04 改值**（不删 key、不加 deprecated 元数据）。
  - **Why**：保持 phase 12 在 "values-only" 范围内，避免动 spec 与扩展 phase 范围；ARB 中 2 个未消费 key 是 v1.2 ARB GC 的工作（TOOL-V2-02 已 backlog）。
  - **Plan 阶段动作**：在 ARB `@homeHappinessROI` / `@homeSoulFullness` 描述里**可选**加 `[no live consumers as of v1.1 Phase 10; pending v1.2 ARB GC]`（可选，不强制；planner 决定）。**不动** key 名、不动 description 主体语义、不动 ARB-parity CI 配置。

### bottomLabels 语义错位修复 (RENAME-07 扩展)

- **D-05: bottomLabels 用 `[satisfactionBad, satisfactionNormal, satisfactionExcellent]` 不动**（consumer 0 改动），同时把 `satisfactionExcellent` 纳入本 phase RENAME 范围（**RENAME-07 spec amendment**）。
  - 改 bottom hint 之前: en "Excellent!" / ja "最高！" / zh "最好！"
  - 改 bottom hint 之后: **en "Amazing!" / ja "至福！" / zh "最爱！"**（与 levelLabels[4] 同字 + `!` 强化 scale-end hint 语气）
  - **Why 不改 consumer**：transaction_confirm_screen.dart 改 `bottomLabels: [levelLabels[0], levelLabels[2], levelLabels[4]]` 虽然技术上更优雅，但**跳出 values-only 锁**且会产生与 RENAME-01..06 不同 risk profile 的代码改动；保持 consumer 不动符合 phase 12 mechanical 范围。
  - **Why "至福！" 不与 levelLabels[4] = "至福" 冗余**：picker 渲染时 levelLabel 在头部 row（"满足度 [级别名]"），bottom hint 在 emoji row 下方 spread 三栏；位置与上下文不同，"至福" 与 "至福！" 的 ! 语气区分使其分别承担 "level achieved" 与 "scale peak hint" 双语义。
  - **Spec amendment 工作**：planner 在 PLAN 中执行 REQUIREMENTS.md amend：新增 `RENAME-07: satisfactionExcellent ARB 值同步改写 (Amazing! / 至福！/ 最爱！) — keys 不动，consumer 不动；rationale 是与 levelLabels[4] register 一致避免 scale-anchor hint 跳脱`。Traceability 表更新：v1.1 active REQ 数 31 → 32（含 STATSUI-05/06/07 + RENAME-01..07）。
  - **CI 检查**：`flutter analyze` 必须 0 issues；既有的 picker widget test (`satisfaction_emoji_picker_test.dart`) bottomLabels 断言要更新到新值并 pass。

### Native-speaker register review 流程

- **D-06: Register review 流程 = Claude 多源调研 + AskUserQuestion 关键点 sign-off + DISCUSSION-LOG.md 记录全程**（已在本 discuss session 完成大部分）。
  - **本次 discuss session 已完成**：
    - JP val=2 register 调研（中性 vs ニュートラル vs ふつう vs フラット → 用户初选 フラット → 重新调研 kanji 候选 → 锁定 無難）
    - JP val=4..10 一致性调研（Set α 保守 vs Set β wellbeing ladder vs Set γ tokimeki 联动 → 锁定 Set β 锚 + 「無難」起点 + 「快適」桥接）
    - ZH val=2 register 调研（中性 vs 无忧 vs 平和 vs 如常 → 锁定 平和）
    - satisfactionExcellent 跨语对齐（路径 A/B/C → 锁定 路径 B = 至福！/ 最爱！/ Amazing!）
  - **Plan 阶段补充**（剩余轻量调研）：
    - **EN 全套**：本期接受 ROADMAP 原文 Neutral / OK / Good / Great / Amazing，无需进一步调研（unipolar positive scale 已在 ADR-014 锚定）。
    - **ZH val=4..10**：本期接受 ROADMAP 原文 OK / 不错 / 满足 / 最爱，无需进一步调研。
    - **小检查**：planner 在 plan 中对照 Apple HIG ja / iOS 系统设置 / 主流 ja/zh apps（PayPay、メルカリ、微信支付、支付宝评价系统）register 截图，记录 1 段 evidence 在 plan 的 "Translation Audit" sub-step；如果发现 register 偏差，回退到 discuss-phase reopen。
  - **Sign-off 渠道**：所有翻译值在 D-02/D-03/D-05 已 explicitly locked；plan 阶段不需要再次 AskUserQuestion，除非 planner 发现 register evidence 与 D-02/D-03/D-05 矛盾。

### ADR-015 Lexical Hierarchy

- **D-07: ADR 编号 = ADR-015**（INDEX 当前最大 ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md，下一编号 015）。
- **D-08: ADR-015 scope = 仅 lexical hierarchy**（不重复 ADR-014 已涵盖的 Path B unipolar-positive 语义，避免双重决议产生歧义）。
  - **必须包含**：
    - **三语 lexical hierarchy 表**：
      - "幸福" / "happiness" / "ハピネス" → reserved for documentation, README, marketing copy
      - "悦己" / "Joy" / "ときめき" → in-product UI copy（包括 ARB values, screen titles, toast messages）
      - "幸福密度" / "Joy per ¥" / "ハピネス密度" → 唯一 在产品中保留 「幸福/Happiness」字样的 KPI 标题（基于 PTVF 数学语义，非情绪表达）
    - **CN family-mode anti-collision 规则**：family mode 标题 MUST 是「家族的小确幸 / 家族の小確幸 / Family Joy」。NEVER「家族悦己」(避免与 personal soulLedger 「悦己账本」碰撞，破坏 family-mode 反对抗 binding)。**已在 Phase 11 `homeRingSectionTitleGroup` 落地** (zh "家族的小确幸"; ja "家族の小確幸") — ADR-015 在「Status: 已接受」中引用 Phase 11 commit 作为先例。
    - **JP wellbeing register 选择**：picker level labels 使用 wellbeing kanji ladder（無難 / 快適 / 順調 / 満足 / 至福）作为 D-03 决议引用 — 把"为什么不用片假名 register"的 rationale 收纳进 ADR。
  - **不要包含**：
    - ❌ Path B unipolar positive 语义本身（已在 ADR-014 决议）
    - ❌ Voice estimator realignment（已在 ADR-014 D-12 deferred）
    - ❌ 5-emoji ↔ {2,4,6,8,10} value mapping（已在 Phase 9 picker test 锚定）
  - **状态**：Draft → 「✅ 已接受」at Phase 12 close（即 Phase 12 完工 + verification 通过 + commit 后翻 status；与 Phase 9 ADR-012/013/014 同模式）。
  - **Append-only**：未来对 lexical hierarchy 的修订必须以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。
  - **References from**: ADR-012（不引入跨成员对比 → 防止 family mode 命名碰撞）、ADR-014（Path B unipolar positive → JP register 选择不应暗示负面）、Phase 11 D-13（FamilyInsightCard 句式与 family-mode 「家族的小確幸」标题一致）、Phase 10 D-03/D-04（rings encoding 不重新引入 happiness ROI 框架）。

### Claude's Discretion

下列细节交给 planner / plan 阶段 grep + 验证后决定，不在本 CONTEXT 锁定：

- `sentiment_satisfied_outlined` 在 Flutter Material Icons 中是否真实存在（vs alias `sentiment_satisfied_alt_outlined`）— planner 在 plan 第一个 task 中用 `flutter doctor` 或 IDE 自动补全验证，如不存在用 `sentiment_neutral_outlined` 与 `sentiment_satisfied_alt_outlined` 中间态（细节见 D-01）。
- ARB `@homeHappinessROI` / `@homeSoulFullness` 的 description 是否加 `[no live consumers ...]` 标注 — planner 决定（不强制）。
- ARB `@description` 元数据是否需要随 value 改写更新（如 `@soulLedger.description` 现描述如果含 "Soul Ledger" 字样）— planner 决定，原则是描述应反映新值的语义。
- 既有 worklog 模板与本 phase commit 配套 — planner 按 `.claude/rules/worklog.md` 在每个 plan unit 完成时生成。
- ARB `@@locale` / `@@last_modified` / 其他元 fields 是否动 — planner 决定，原则是不改 metadata 除非工具要求。
- Plan unit 切分（建议 4-5 wave）：
  - Wave 1: ARB value 改写（3 文件 × 10 keys）+ flutter gen-l10n
  - Wave 2: Picker icon 替换 + 既有 picker test 断言更新
  - Wave 3: ADR-015 起草 + REQUIREMENTS.md amend (RENAME-07) + INDEX.md 更新
  - Wave 4: ARB-parity CI 验证 + Translation Audit evidence 收集（plan 内 D-06 register evidence step）
  - Wave 5: 集成 verification + ADR-015 status flip + milestone v1.1 close prep
  - Plan 数预计 5-7（与 Phase 9 13 plan / Phase 10 11 plan / Phase 11 8 plan 相比量级 **最小**，符合 Small-Medium complexity）。
- 是否需要单独 plan unit 跑 CN family-mode collision 验证 — planner 决定（建议直接在 ADR-015 plan unit 引用 Phase 11 既有 commit 作为 evidence；无需新增 plan）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning (always)
- `.planning/PROJECT.md` — v1.1 milestone vision；Target features 节锁 4 个 ARB rename + 翻译值；Out of scope 列出 v1.2 polish；Lexical hierarchy 「幸福/happiness 留 docs；ときめき/悦己/Joy 留 product」核心定位
- `.planning/REQUIREMENTS.md` — RENAME-01..06 active；**plan 阶段 amend RENAME-07** (satisfactionExcellent value rename); v2 deferred 列表（HAPPY-V2-03 voice realignment / TOOL-V2-02 ARB key GC）
- `.planning/ROADMAP.md` — Phase 12 entry；Critical pitfalls 已写「VALUES change, KEYS stay」「Native-speaker register review BEFORE merge」「CN family-mode 家族的小确幸 ≠ 家族悦己」「Picker icon emoji 1: very_dissatisfied → neutral」「Voice estimator deferred per ADR-014」
- `.planning/STATE.md` — Phase 11 complete (2026-05-04)，Phase 12 ready to plan
- `.planning/phases/11-statistics-surface-for/11-CONTEXT.md` — Phase 11 D-13 FamilyInsightCard 句式 (zh "家族小確幸") + Update 2026-05-03 SCOPE-revision，与 Phase 12 ADR-015 family-mode anti-collision 决议互证
- `.planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md` — Phase 10 D-04 family rings 不引入 leaderboard 合约，与 Phase 12 ADR-015 lexical hierarchy 「家族の小確幸 ≠ 家族悦己」 同源；Phase 10 引入新 ARB keys 替代 homeHappinessROI/homeSoulFullness（解释 D-04 死键处理决定）
- `.planning/phases/09-happiness-domain-formula-layer/09-CONTEXT.md` — Phase 9 D-12 voice realignment 推迟到 v1.2（Phase 12 不动 voice estimator 的根本依据）

### ARB source files (Phase 12 直接修改)
- `lib/l10n/app_en.arb` — EN 主翻译；keys 行号：survivalLedger=94 / soulLedger=98 / homeSoulFullness=553 / homeHappinessROI=561 / satisfactionBad=870 / satisfactionSlightlyBad=874 / satisfactionNormal=878 / satisfactionGood=882 / satisfactionVeryGood=886 / satisfactionExcellent=890
- `lib/l10n/app_ja.arb` — JP 主翻译；同上行号
- `lib/l10n/app_zh.arb` — ZH 主翻译；同上行号
- `l10n.yaml` — i18n 配置：output class S，output dir lib/generated；不需要改

### Code consumers (Phase 12 间接影响 / 需要 verify)
- `lib/features/home/presentation/widgets/home_hero_card.dart` — 第 201 行 `l10n.soulLedger` + 第 208 行 `l10n.survivalLedger`（split bar 标签；ARB value 改后自动渲染新值，**代码不动**）
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — `_icons` const 数组（第 17-23 行）需替换为 D-01 sentiment 升级序列
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — 第 661-674 行 picker 调用 `levelLabels: [...]` + `bottomLabels: [...]`，consumer **代码不动**（D-05 决议）；ARB value 改后自动渲染
- `lib/application/voice/voice_satisfaction_estimator.dart` — Phase 12 **不动**（ADR-014 D-12 deferred 到 v1.2）

### Test files (Phase 12 必须更新断言)
- `test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` — 第 19 行 levelLabels 硬编码 + 第 20 行 bottomLabels + 第 37-39 行断言。Phase 12 改值后**断言新值**：levelLabels = `['無難', '快適', '順調', '満足', '至福']`（JP 测试上下文）；bottomLabels = `['無難', '順調', '至福！']`（同 JP 上下文）；断言 `find.text('無難')` / `find.text('順調')` / `find.text('至福！')` 而不是 `'不満'/'普通'/'最高！'`。**HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping 测试（第 56-70 行）保持不动 — value 没变**。

### Architecture / spec docs
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — Path B unipolar positive scale（emoji 1=neutral 不是 negative 的 root rationale；Phase 12 ADR-015 引用此 ADR 作为 picker icon D-01 + JP wellbeing register D-03 的依据）
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — anti-leaderboard binding（Phase 12 ADR-015 引用此 ADR 作为「家族悦己 = 集体排行榜暗示，禁用」的论据）
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF 公式语义（Phase 12 ADR-015 引用以解释为什么 `homeHappinessROI` 翻译值保留 「幸福密度/Joy per ¥/ハピネス密度」中的 「幸福/Happiness」字样 — 数学密度而非情绪表达，唯一例外）
- `docs/arch/03-adr/ADR-000_INDEX.md` — Phase 12 plan 必须把 ADR-015 加入 INDEX

### Project rules
- `CLAUDE.md` — i18n 规则节（"Mandatory: All UI text via S.of(context); Update ALL 3 ARB files when adding translations, then run flutter gen-l10n"）；Common Pitfalls #5（intl pinned at 0.20.2 不能动）
- `.claude/rules/arch.md` — ADR 命名规则（ADR-{NNN}_{决策主题}.md；编号 = max + 1 = 015）；ADR append-only 规则；INDEX 同步更新
- `.claude/rules/worklog.md` — 每个 plan unit 完成 MUST 生成 worklog（YYYYMMDD_HHMM_task.md）
- `.claude/rules/coding-style.md` — Immutability / file size <800 lines

### CI guardrails (Phase 12 必须绿)
- ARB-parity CI guardrail — 三语 ARB 文件 keys 必须严格一致（无新增/删除）
- `flutter gen-l10n` — 必须 0 warnings
- `flutter analyze` — 必须 0 issues
- 既有 satisfaction_emoji_picker_test.dart — 必须 pass with 更新后的断言

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`l10n.yaml`** + Flutter localizations pipeline — Phase 12 不动配置，只动 ARB 内容；`flutter gen-l10n` 自动从新 ARB 值重生成 `lib/generated/app_localizations*.dart`。
- **既有的 ARB 元数据（@key descriptions）** — Phase 12 仅必要时更新（D-04 / Claude's discretion），不强制。
- **既有的 `satisfaction_emoji_picker_test.dart`** — pin HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping；Phase 12 必须保持此断言 pass，仅更新标签字符串断言。
- **Phase 11 已落地的 `homeRingSectionTitleGroup` zh="家族的小确幸"** — Phase 12 ADR-015 family-mode anti-collision 决议直接以此 commit 作为 evidence，无需重新实现。

### Established Patterns

- **ARB key 不动 + values 改值** — Phase 12 全部 RENAME-01..07 严格遵守此模式。任何 「key rename / consumer 改动 / 新 key 引入」 都跳出 phase 范围（明示禁止）。
- **`flutter gen-l10n` 后自动 propagate** — ARB value 改写后所有 `S.of(context).{key}` 调用点自动渲染新值；Phase 12 无需 grep + edit consumer code。
- **Picker `_icons` const 数组替换** — 5 个 IconData 一次替换；不动 `_faceValues` const（{2,4,6,8,10} ADR-014 锁），不动 `_selectedIndex` 映射逻辑，不动 widget 视觉/排版/dark-mode 逻辑。
- **ADR `## Status` flip pattern**（与 Phase 9 ADR-012/013/014 同）— Phase 12 ADR-015 起草时 status="提案中"，Phase 12 close 翻 "✅ 已接受"。
- **REQUIREMENTS.md amend 在 plan 阶段执行**（与 Phase 10 D-06 / Phase 11 D-02 同模式）— Phase 12 plan 中 amend RENAME-07 + 更新 traceability 表 + 更新 v1.1 active REQ 数 31→32。

### Integration Points

- **Phase 12 ↔ Phase 11**: Phase 11 新增 ARB keys（`analyticsCardTitleFamilyInsight` 等）**不在** Phase 12 RENAME-01..07 范围内；planner 在 plan 中 grep 验证 RENAME 不与 Phase 11 新 keys 冲突。Phase 11 的 `homeRingSectionTitleGroup` zh="家族的小确幸" 是 Phase 12 ADR-015 anti-collision 决议的 evidence。
- **Phase 12 ↔ Phase 10**: Phase 10 用新 keys (`homeRingSectionTitleSingle/Group` / `homeJoyIndexTooltip` / `homeJoyPerYenTooltip` / `homeJoyPerYenLegend`) 替代 `homeHappinessROI` / `homeSoulFullness`，使后两者成 dead keys（D-04 决议保留 dead keys 仅改值，不删）。
- **Phase 12 ↔ ADR-014**: ADR-014 是 picker icon D-01 + JP wellbeing register D-03 的语义根。Phase 12 ADR-015 不重复 ADR-014 决议（D-08 binding）。
- **Phase 12 ↔ Voice estimator**: voice_satisfaction_estimator.dart 完全不动（ADR-014 D-12 deferred 到 v1.2）；voice 输出 [3,10] 与 picker {2,4,6,8,10} 不对齐的张力靠 Phase 11 D-09 histogram 5 bar 注释「含未評価/含未评分/Median + unrated」覆盖。

### Known forbidden patterns (CI-enforced or project policy)

- ❌ ARB key rename（任何 key 名改动 — 跨出 phase 12 values-only 范围；TOOL-V2-02 backlog）
- ❌ ARB key 新增（除 RENAME-07 同步范围外不引入新 key）
- ❌ ARB key 删除（包括 dead keys homeHappinessROI/homeSoulFullness — D-04 binding；TOOL-V2-02 处理）
- ❌ 改 `_faceValues = [2, 4, 6, 8, 10]` 常量（ADR-014 锁；HAPPY-08 picker test 第 56-70 行断言）
- ❌ 改 picker `_selectedIndex` 映射逻辑（ADR-014 锁；同上 test 断言保护）
- ❌ 改 picker bottomLabels consumer 调用（D-05 决议保留 [satisfactionBad, satisfactionNormal, satisfactionExcellent] 调用模式）
- ❌ 改 voice_satisfaction_estimator.dart（ADR-014 D-12 + Phase 9 D-12 deferred）
- ❌ 在产品 UI 中引入「幸福」/「happiness」/「ハピネス」字样（除 `homeHappinessROI` 既有 KPI 标题外 — ADR-015 lexical hierarchy binding；ADR-013 PTVF 数学密度的唯一例外）
- ❌ 在产品 UI 中引入「家族悦己」字样（ADR-015 anti-collision binding；用「家族的小確幸/家族の小確幸/Family Joy」）
- ❌ 直接 hardcode 翻译字符串（必须通过 ARB; CLAUDE.md i18n rule）

</code_context>

<specifics>
## Specific Ideas

讨论中沉淀的、定向影响 downstream 判断的产品哲学瞬间：

- **「Picker 5 个图标重设 = sentiment 升级序列」(D-01)** — 用户拒绝 star ramp / heart 渐增等设计跳跃，选择保留 picker 「sentiment-faces」UX 身份的同时升级到全正向 register。这与 ADR-014 Path B unipolar-positive 哲学完全一致：picker 永远不再传递「负面情绪」选项，只传递「无情绪 → 一般 → 满足 → 兴奋 → 至爱」的升级。**未来设计 review 必须保持此 UX 身份**：禁止重新引入 sad/dissatisfied 表情即使作为可选 alt theme。

- **「JP val=2 三轮迭代 (中性 → フラット → 平静 → 無難)」** — 用户的 register 调研经过 3 个 rejection（中性 太 philosophical / フラット 太 katakana 现代 / 平静 太 心理学压抑），最终落到 「無難」，并要求重新基于此构建整个 5-label 的 wellbeing ladder。这表明用户对**和风文学 register vs product UI register vs philosophical register** 的边界有强烈直觉，且**ときめき帳 / 日々の帳** 的全 kanji wellbeing register 是 anchor 点。Phase 12 ADR-015 必须把这个 register 选择 explicitly 记入 hierarchy（不仅是 lexical hierarchy 也是 register hierarchy）。

- **「ZH val=2 = 平和」** — 用户拒绝 ROADMAP 「中性」（与 JP 「中性」 reject 同源），但也没选 「无忧」（CN 现代 product UI 最近 register）— 选择 「平和」 是 wellbeing register 的中间路径。这与 「灵魂账本 → 悦己账本」 改名整体的「让 spending 与 wellbeing 联系起来」哲学一致。

- **「至福！/ 最爱！/ Amazing!」三语 + ! 强化 (D-05 RENAME-07)** — 用户接受了「bottomLabels 与 levelLabels 字面重复但用 ! 区分」这个看似 mild 的设计，实际上是接受了「scale-anchor hint vs level-achieved label」的 picker UX 双层语义。Phase 12 不修改 consumer 是值得保护的 minimum-change 设计原则；「至福！」与「至福」的 ! 区分是这种保守在 register 层的 elegant 兑现。

- **「不动 voice estimator」** — 用户在 discuss 中没有 reopen voice realignment（ADR-014 D-12 v1.2 锁）。这是 milestone 节奏感的体现：Phase 12 是 v1.1 收尾；voice realignment 是 v1.2 起点。强行在 Phase 12 改 voice estimator 输出范围会污染 v1.1 close 的 critical path。

- **「Phase 12 是 milestone 收尾」** — Phase 12 close 时 ADR-015 status flip 到「✅ 已接受」，与 Phase 9 ADR-012/013/014 status flip 是 milestone 仪式的一部分。Phase 12 verification 通过也代表 v1.1 整体可以 close。

- **「Native-speaker register review = Claude 调研代理 + AskUserQuestion sign-off」(D-06)** — 用户认可了「1-developer + Claude pair」项目下，传统的「外聘 native speaker」流程不可行，Claude 代理 + 用户 sign-off 是合理替代。这暗示未来其他 RENAME / register 类工作也可走此模式（不需要 Notion / Slack 收集 native-speaker review）。

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-12 — 仍在 v1.1 内（无）
Phase 12 是 v1.1 最后 phase；任何延期都到 v1.2+。

### Out-of-v1.1 — v2 / 未来 milestone

- **TOOL-V2-02: ARB key GC pass** — 删除 dead keys `homeHappinessROI` / `homeSoulFullness` + 任何 v1.0 widget 删除后遗留的 dead keys（来自 Phase 11 删除的 8 个 widget）。需要全仓库 grep + ARB-parity CI 配合 + REQUIREMENTS.md amend；不在 v1.1 范围。
- **HAPPY-V2-03: Voice estimator output realignment** — voice 输出从 [3,10] → {2,4,6,8,10} 对齐 picker 离散 set；ADR-014 D-12 锁定 v1.2。realignment 时 Phase 11 D-09 histogram 5 bar 「含未評価」 caption 自然消解。
- **REGISTER-V2-01: Full ARB register polish pass** — 对**所有** ARB keys（不仅 RENAME-01..07 范围）做 native-speaker register review；包括 family-sync screens / settings / OCR 流程的 ja/zh 翻译。Phase 12 范围是 milestone-defining keys 的 register 校准；polish pass 是 v1.2 完整度工作。
- **UI-V2-01: Picker 视觉重设** — Phase 12 的 icon 升级是 ADR-014 必要兑现（emoji 1 不能再传负面）；视觉/动效/transition 的更深重设留 v1.2。包括 selected-state shadow/scale animation / bouncy haptics / 自定义 emoji glyphs。
- **DOC-V2-01: ADR-015 follow-up** — `## Update YYYY-MM-DD` 章节追加 v1.2 register polish 决议、其他 lexical hierarchy 修订（如发现 family-sync screens 中「幸福」字样需要清理）；ADR-015 是 living doc。

### Forbidden anti-features (binding through milestone close + beyond)
- ❌ **「家族悦己」 ARB 字符串** — ADR-015 anti-collision binding（永久；任何后续 phase 引入此字样必须先修订 ADR-015）
- ❌ **picker negative-emotion icons**（sentiment_dissatisfied / sentiment_very_dissatisfied 等） — ADR-014 + ADR-015 binding；任何 picker 设计 review 必须保持 sentiment 升级序列
- ❌ **product UI 中「幸福」/「happiness」/「ハピネス」字样**（除 KPI 「幸福密度」 PTVF 数学例外） — ADR-015 lexical hierarchy binding
- ❌ **voice estimator [3,10] → {2,4,6,8,10} realignment in Phase 12** — ADR-014 D-12 + 本 phase 范围保护
- ❌ **Phase 12 引入新 ARB keys**（除 RENAME-07 范围内的 satisfactionExcellent value 改写外） — phase 12 values-only 范围保护

### Reviewed but not folded
无（cross_reference_todos 步骤无匹配；STATE.md 无 phase-12 相关 todo）。

</deferred>

---

*Phase: 12-UI Copy Rename Pass (ARB values, ja/zh/en)*
*Context gathered: 2026-05-04*
