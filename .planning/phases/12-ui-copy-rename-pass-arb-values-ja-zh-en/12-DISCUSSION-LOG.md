# Phase 12: UI Copy Rename Pass (ARB values, ja/zh/en) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 12-UI Copy Rename Pass (ARB values, ja/zh/en)
**Areas discussed:** Picker icon set, Dead-key handling, bottomLabels semantic, Native-speaker register review (process + translation details)

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Picker 5 个图标重设 | ADR-014 把 emoji 1 改 neutral；其他 4 个是否对称？需敲具体图标集 + dark mode token | ✓ |
| homeHappinessROI / homeSoulFullness 死键 | Phase 10 用新 key 替代后无消费者；改值/删 key/标 deprecated 三选 | ✓ |
| Picker bottomLabels 语义错位 | satisfactionBad 变 "Neutral" 后放最左边语义错；换 keys / 用 levelLabels[0/2/4] / 引入新 key | ✓ |
| Register review 流程 + 翻译细节 | RENAME-06 native-speaker review 流程 + JP/ZH 翻译细节锁定 | ✓ |

**User's choice:** All four areas selected (multi-select).
**Notes:** 用户选择全部 4 个 — 表示对每个 gray area 都有 active stake 需要 explicit alignment。

---

## Area 1: Picker 5 个图标重设

| Option | Description | Selected |
|--------|-------------|----------|
| Sentiment 升级序列（推荐） | neutral → satisfied → satisfied_alt → very_satisfied → favorite_border；保留 picker sentiment-faces UX 身份 | ✓ |
| Star 十级量化 | star_outline × 1-5 渐增填充；语义平蹋但改变 picker 身份 | |
| Heart 渐增填充 | favorite_border × 1-5；与 Best Joy strip favorite 重叠 | |
| 交给 planner / UI-phase | 仅锁 emoji 1 改 neutral，其余给 plan 阶段 | |

**User's choice:** Sentiment 升级序列（推荐）
**Notes:** 用户接受 plan 阶段验证 `sentiment_satisfied_outlined` 在 Material Icons 中的存在性。dark mode token 沿用现有 AppColors.tagGreen/AppColorsDark.tagGreen 模式。

---

## Area 2: homeHappinessROI / homeSoulFullness 死键处理

| Option | Description | Selected |
|--------|-------------|----------|
| 仍按 RENAME-03/04 改值（推荐） | 满足 RENAME 字面验收，避免动 spec；ARB 仍有 2 dead keys 但 v1.2 GC 处理 | ✓ |
| 删 key + amend RENAME-03/04 为 'cleanup' | 最干净，但跨出 values-only 指令，改 spec 风险 | |
| 改值 + @description 加 deprecated 标记 | 文档型信号，为 v1.2 GC 提前打标 | |

**User's choice:** 仍按 RENAME-03/04 改值（推荐）
**Notes:** 用户认可保持 phase 12 在 "values-only" 范围内，不动 spec。Plan 阶段可选在 @description 加注「[no live consumers as of v1.1 Phase 10; pending v1.2 ARB GC]」（不强制；planner 决定）。

---

## Area 3: Picker bottomLabels 语义错位

| Option | Description | Selected |
|--------|-------------|----------|
| 保持现有 keys + 同步改 satisfactionExcellent 值（推荐） | consumer 不动；扩展 RENAME 加入 satisfactionExcellent 值改写（→ RENAME-07 amend） | ✓ |
| 保持 keys + satisfactionExcellent 不改 | 最小改动，但 bottomLabels[2] 「Excellent!」 与 milestone Joy/悦己/ときめき 词汇脱节 | |
| 改 consumer 用 levelLabels[0/2/4] | 语义最对齐，但跳出 values-only 范围 | |
| 交给 planner / Claude's discretion | CONTEXT 仅记三个选项，planner 决定 | |

**User's choice:** 保持现有 keys + 同步改 satisfactionExcellent 值（推荐）
**Notes:** Plan 阶段执行 REQUIREMENTS.md amend（RENAME-07: satisfactionExcellent ARB 值改写为 至福！/ 最爱！/ Amazing!；keys 不动；consumer 不动）。Traceability 表 v1.1 active REQ 31→32。

---

## Area 4 (流程部分): Native-speaker register review 流程

| Option | Description | Selected |
|--------|-------------|----------|
| Claude 调研代理 + AskUserQuestion 关键点确认（推荐） | Plan 阶段多源调研（Apple HIG/Wikipedia/产品 UI），AskUserQuestion 让用户 sign-off；evidence 入 ADR + DISCUSSION-LOG | ✓ |
| Notion 打调研 + 后面 commit 手动带凭证 | 外部 native speaker 反馈；Plan 加 register-review plan unit 收藏凭证 | |
| Defer RENAME-06 到 v1.2 polish pass | 拆出 Phase 12，只锁 ARB + ADR + Picker icon | |
| 中间路径：plan 提供候选集 + 一次性 sign-off | Plan 内出每 key 2-3 候选 + 推荐 + 凭证，用户阅读 plan 时一次 signoff | |

**User's choice:** Claude 调研代理 + AskUserQuestion 关键点确认（推荐）
**Notes:** 这次 discuss session 已完成大部分 register review（JP/ZH val=2 多轮迭代 + JP val=4..10 ladder 调研 + satisfactionExcellent 跨语对齐）。Plan 阶段补充 EN/ZH val=4..10 与 Apple HIG / 主流 ja/zh apps 的截图 evidence；如果发现矛盾可重 reopen discuss。

---

## Area 4 (翻译细节): JP val=2 (满足度最低值) register

### Round 1: JP val=2 register

| Option | Description | Selected |
|--------|-------------|----------|
| 中性 (kanji) | ROADMAP 原；与 zh "中性" 一致 | |
| ニュートラル (katakana) | 现代 product UI 风格 | |
| ふつう (hiragana 'normal') | 与「ときめき」hiragana 一致；偏轻 | |
| フラット (katakana 'flat') | wellbeing 中性 register；不卷 negative | ✓ |

**User's choice:** フラット (katakana 'flat')
**Notes:** 用户拒绝 中性 (太 philosophical)、ニュートラル (太 katakana 现代)、ふつう (与「ときめき」太接近)；选 フラット 后立即问"是否可以有更好的日文汉字" — 进入 Round 2。

### Round 2: JP val=2 kanji 候选

| Option | Description | Selected |
|--------|-------------|----------|
| 平常 (heijō) | 文学和风、ときめき/日々 同列；emotional baseline | |
| 普通 (futsū) | 商业 UI 通用；与 v=6 'good baseline' 边界模糊 | |
| 並 (nami) 一字 | 食事文化（並・上・特上）；emotional 偏 transactional | |
| 平静 (heisei) | wellbeing register；准确但暗示 'composed/压抑' | ✓ |

**User's choice:** 平静 (heisei) — 同时要求为 OK (val=4) 寻找日语汉字 → 进入 Round 3
**Notes:** 用户在 round 2 选 平静 后立即扩展讨论范围："同时也为 OK 寻找一个合适的日语汉字"。

### Round 3: 用户回退 — 重选 anchor 为「無難」并要求重生 5 set

**User's note:** "無難看起来更像 Normal，是否可以基于無難生成 5 个 level 的日本汉字"
**Decision:** 用户撤回 平静 选择，把 anchor 从 val=2 改为 val=4 = 無難，并要求基于此重生 5-label set。

### Round 4: 完整 JP 5-label set 候选

| Option | Description | Selected |
|--------|-------------|----------|
| Set α: 平穏/無難/不錯/満足/最愛 (保守) | 仅改 val=2/4，保留 ROADMAP val=6/8/10 | |
| Set β: 平穏/無難/順調/満足/至福 (推荐 wellbeing ladder) | 完整心理 ladder；全部规避 collision | ✓ (anchor 修订) |
| Set γ: 無風/無難/上機嫌/充足/ときめき (产品 ときめき 联动) | val=10 用 ときめき 与 soulLedger 字根呼应；val=8 充足 与 homeSoulFullness 撞 | |
| 手动拼接 | 用户 'Other' 自定义 | |

**User's choice:** "Set β 这个不错，但我是想把無難作为第一位，不要平穏了，重新生成 5 个日语汉字，順調 / 満足 / 至福都不错，可以保留"
**Decision:** 用户接受 Set β 的 順調/満足/至福 但替换 val=2 「平穏」 → 「無難」，要求生成 val=4 桥接候选 → Round 5。

### Round 5: JP val=4 桥接 (在 無難 → 順調 之间)

| Option | Description | Selected |
|--------|-------------|----------|
| 快適 (kaiteki) (推荐) | 'comfortable'；無難→快適→順調 = safe→舒适→顺遂；product UI 通用 | ✓ |
| 好調 (kōchō) | 与 順調 lexical 双子；可能太接近 | |
| 微笑 (bishō) | 字面 'slight smile'，与 sentiment_satisfied_outlined 一致；emotional register 与 wellbeing chain 跳 | |
| 円満 (enman) | 'harmonious'；偏家庭/关系 register | |

**User's choice:** 快適 (kaiteki)（推荐）
**Decision:** 最终 JP 5-label set lock = 無難 / 快適 / 順調 / 満足 / 至福。

---

## Area 4 (翻译细节): ZH val=2 satisfactionBad

| Option | Description | Selected |
|--------|-------------|----------|
| 无忧 (推荐) | 与 JP「無難」同源 wellbeing；CN product UI native | |
| 平和 | wellbeing apps register | ✓ |
| 如常 | 'as usual'，daily-life baseline | |
| 中性 (ROADMAP 原) | 哲学/物理学 register；与 JP 中性 reject 同源 | |

**User's choice:** 平和
**Notes:** 用户没选 推荐选项 无忧，而是选了介于 wellbeing 与 emotional 之间的 平和。这是 wellbeing register 的中间路径，与 灵魂账本 → 悦己账本 改名整体的「让 spending 与 wellbeing 联系起来」哲学一致。

---

## Area 4 (翻译细节): satisfactionExcellent 新值 (RENAME-07)

| Option | Description | Selected |
|--------|-------------|----------|
| 路径 A: 至福 / 最爱 / Amazing | 与 levelLabels[4] 完全一致；字面重复但位置不同 | |
| 路径 B: 至福！/ 最爱！/ Amazing!（推荐） | 与 levelLabels[4] 同字 + ! 强化 scale-end hint 语气 | ✓ |
| 路径 C: 保 current 但 ZH 改「最棒！」 | 与 level labels 字不同；与 milestone Joy/悦己/ときめき 词汇脱节 | |
| 交给 plan candidates doc | 范围锁，plan 给 3 候选 + sign-off | |

**User's choice:** 路径 B：至福！/ 最爱！/ Amazing!（推荐）
**Notes:** 接受「bottomLabels 与 levelLabels 字面重复但用 ! 区分」的 minimum-change 设计。「至福」(level achieved) vs 「至福！」(scale peak hint) 的双层语义在 picker UX 中可分别承担。

---

## Final wrap-up

| Option | Description | Selected |
|--------|-------------|----------|
| 全接受 + 写 CONTEXT.md（推荐） | ADR-015 仅 lexical hierarchy；homeHappinessROI EN = 'Joy per ¥' (ROADMAP 选择) | ✓ |
| 'Joy / ¥' (PROJECT.md 原) + ADR-015 lexical-only | EN 选分式 'Joy / ¥' | |
| 继续讨论：ADR scope 需要细化 | 重开 question 锁 ADR-015 是否覆盖 picker semantic shift | |

**User's choice:** 全接受 + 写 CONTEXT.md（推荐）
**Notes:** ADR-015 scope 锁定为 仅 lexical hierarchy（不重复 ADR-014 已涵盖的 Path B unipolar positive 语义；不重新决议 voice realignment）。

---

## Claude's Discretion

下列细节交给 planner / plan 阶段决定：

- `sentiment_satisfied_outlined` 在 Flutter Material Icons 中的真实存在性 — planner verify
- ARB `@homeHappinessROI` / `@homeSoulFullness` 的 description 是否加 deprecated 标注 — planner 决定（不强制）
- ARB `@description` 元数据是否随 value 改写更新 — planner 决定
- ARB `@@locale` / `@@last_modified` 元 fields 是否动 — planner 决定
- Plan unit 切分（建议 4-5 wave；plan 数预计 5-7）— planner 决定
- 是否需要单独 plan unit 跑 CN family-mode collision 验证 — planner 决定（建议直接引用 Phase 11 既有 commit 作为 evidence）

---

## Deferred Ideas

(详见 CONTEXT.md `<deferred>` 节)

### Out-of-v1.1 — v2 / 未来 milestone
- TOOL-V2-02: ARB key GC pass（删除 dead keys + Phase 11 删除 widget 后遗留的 dead keys）
- HAPPY-V2-03: Voice estimator output realignment ([3,10] → {2,4,6,8,10})
- REGISTER-V2-01: 全 ARB register polish pass（family-sync / settings / OCR 流程的 ja/zh）
- UI-V2-01: Picker 视觉重设（动效 / haptics / 自定义 emoji glyphs）
- DOC-V2-01: ADR-015 follow-up sections

### Forbidden anti-features (binding through milestone close + beyond)
- ❌ 「家族悦己」ARB 字符串
- ❌ Picker negative-emotion icons
- ❌ Product UI 中「幸福/happiness/ハピネス」字样（除「幸福密度」KPI 例外）
- ❌ Voice estimator [3,10] → {2,4,6,8,10} realignment in Phase 12
- ❌ Phase 12 引入新 ARB keys（除 RENAME-07 范围外）

### Reviewed but not folded
无（cross_reference_todos 步骤无匹配；STATE.md 无 phase-12 相关 todo）。
