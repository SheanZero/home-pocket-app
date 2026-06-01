# ADR-018: Palette Selection — v1.5 (配色选定 v1.5)

**文档编号:** ADR-018
**文档版本:** 1.0
**创建日期:** 2026-06-01
**最后更新:** 2026-06-01
**状态:** 📝 草稿/Proposed (Draft — 待 PALETTE-03 人工选定后 ratify)
**决策者:** zxsheanjp@gmail.com (project owner) + Claude (planning agent)
**影响范围:** v1.5 调色板 → Phase 33 semantic token system（替换 ~62 个硬编码 `Color(0x…)` 字面量）、Phase 34 golden re-baseline。本 ADR 仅记录调色板决策，不改任何 `lib/` 代码。
**相关 ADR:** ADR-016 §5（反游戏化 / 100%-behavior 契约 — D-03 的约束来源）、ADR-017（v1.5 词汇统一 — daily/joy 等 identifier 来源）、ADR-015（词汇分层 — lineage）

> **状态说明（Pitfall 5）:** 本 ADR 在 PALETTE-03 人工选定检查点**之前**起草，状态为 📝 草稿/Proposed。`决策` 章节的具体方案与最终 hex 表在用户选定后于 Task 3 填入，届时状态才翻转为 ✅ 已接受 并进入 append-only 模式。**未选定前不得写 已接受。**

---

## 📋 状态

**当前状态:** 📝 草稿/Proposed (2026-06-01)
**触发来源:** Phase 32「Palette Exploration & Selection」— v1.5「文案与配色统一」milestone 的中间环节：挖掘设计参考 → 合成 4–5 个方向 → 产出 4–5 套 Pencil 方案 → 用户选定一套（或命名混合）→ 本 ADR。
**Ratify 路径:** Phase 32 Plan 03 — 在 PALETTE-03 阻塞式人工检查点选定后，于 Task 3 翻转为 ✅ 已接受。

---

## 🎯 背景 (Context)

### 双轨账本的配色问题

Home Pocket 的「Wa-Modern 和风现代」身份建立在 **暖象牙底 `#FCFBF9` + 珊瑚主色 `#E85A4F`** 之上（`lib/core/theme/app_colors.dart`，`docs/design/design-system.md`）。当前双轨账本配色存在两个待解问题：

1. **日常 (Daily) 与 悦己 (Joy) 的对比不足。** 现状 Daily 蓝 `#5A9CC8` ↔ Joy 绿 `#47B88A` 属低冲突近似色，未能强化「两本账不同」的核心语义。
2. **缺少语义色族。** 现状无独立的 `success/warning/error/info` 家族（由 olive/coral 兼任）；Phase 33 token 系统需要一套显式语义色。

### 约束（D-01 → D-08，见 `32-CONTEXT.md`）

- **D-01 品牌锚点:** 珊瑚 `#E85A4F`（或可辨识的珊瑚色相）在所有方案中保留为品牌记忆点；其余一切（背景、账本 accent、辅助、语义）开放探索。
- **D-02 双轨对比:** 日常读作冷静/冷/中性，悦己读作暖/亮，二者须有清晰视觉对比（非近似），但保持克制不刺眼。
- **D-03 不升格悦己为可庆祝亮点色:** 悦己视觉上更暖/更亮，但不得引入庆祝式 affordance（glow/pulse/sparkle/milestone color-pop）。与 ADR-016 §5 的 100%-behavior 契约（无离散庆祝事件，仅 ambient 状态）一致。
- **D-04 暖色共存轴（探索轴）:** 珊瑚主色（暖）与悦己 accent（暖）的张力是一条探索轴，各方案给出不同解法（如 (a) 珊瑚降级为纯 action 色 + 悦己独立暖家族；(b) 悦己作为珊瑚家族的高亮 tint，以明度区分）。
- **D-05 日常色调轴（探索轴）:** 日常可为延续的冷蓝/teal，或真中性灰/slate；各方案覆盖两端。
- **D-06 参考来源:** 挖掘 VoltAgent/awesome-design-md 品牌 DESIGN.md 集，无品牌预设偏好。
- **D-07 Pencil 交付:** 每套方案在 home-hero / transaction-list / analytics 三屏 × 明暗两态渲染，每套答全语义角色。
- **D-08 选定方式:** 用户可直接选一套，或命名一个混合（如「B 的 Joy + D 的 Daily」）。选定结果 + 每个语义角色的最终 hex 记入本 ADR。

### 为何需要在 Phase 33 之前决策

Phase 33 (Color Token System) 将把散落的 ~62 个硬编码色值整合到统一的 semantic token 系统。token 的取值必须有一个**被批准的、每角色精确 hex 的单一来源**——即本 ADR。没有它，Phase 33 无法实施。

---

## 🔍 考虑的方案 (Considered Options)

5 套方案均渲染于 `home-pocket-palette.pen`（5 scheme groups × 6 frames = 30 frames，明暗两态），合成依据见 `.planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md`。每套保留珊瑚锚点（D-01），日常↔悦己清晰对比（D-02），无庆祝 affordance（D-03）。WCAG 金额文字均已用更深的 `*Text` 变体验证（≥4.5:1）。

> **本节在 Task 3（选定后）补全「拒绝理由」。** 选定前，下表中性地陈述各方案。

| 方案 | 名称 | D-04 解法 | D-05 日常色调 | 挖掘谱系 | 关键 accent（light） | 可访问性 |
|------|------|-----------|--------------|----------|---------------------|----------|
| **A** | Coral-Action + Amber-Joy | (a) 珊瑚纯 action；悦己=琥珀/蜂蜜暖家族 | (a) 冷蓝（延续 `#5A9CC8`） | Claude（cream+coral+amber/teal 分离） | daily `#4E91C0` / joy `#E8A55A` / shared `#D4845A` | 全 `*Text` ≥4.5:1；无 disqualifier |
| **B** | Slate-Daily + Coral-Tint-Joy | (b) 悦己=珊瑚家族高亮 tint，以明度/饱和度区分主色 | (b) 真中性 slate | Coinbase/Stripe 中性 + Claude 暖 tint | daily `#64748D` / joy `#F2845F` / shared `#B5739A` | slate Daily 直接达标；无 disqualifier |
| **C** | Warm-Neutral Calm | (a) 珊瑚 action；悦己=赤陶橙 | (b) 暖中性 taupe | Notion + Claude warm-neutral | daily `#8E8B82` / joy `#DD5B00` / shared `#B98A55` | 全达标；最低色相对比（靠明度/彩度区分）|
| **D** | Cool-Minimal Contrast | (b)-邻接 / 小体量珊瑚；悦己=亮金 | (a) 冷 teal（最强冷暖分裂） | Stripe/Coinbase/Wise | daily `#2A9D99` / joy `#F4B000` / shared `#5B8AA6` | 全达标；金色 joy 仅作 tint，金额用 `#8A6300` |
| **E** | Sage-Neutral + Honey-Joy | (a) 珊瑚 action；悦己=蜂蜜琥珀 | (b) 中性偏 sage（保留一缕旧绿身份） | Wise + Claude | daily `#7E8A72` / joy `#E8A55A` / shared `#C98A5A` | 全达标；sage Daily 对比余量最高 |

每套的完整逐角色 hex、明暗变体、WCAG 表见 `32-PALETTE-SYNTHESIS.md`。每套的 Pencil 变量集合（`get_variables` 可读，按 AppColors symbol 命名，`{scheme}×{mode}` 主题轴）是最终 hex 的权威导出源。

---

## ✅ 决策 (Decision)

**`<SELECTION PENDING — 在 PALETTE-03 人工选定检查点填入>`**

> 用户将选定一套方案（或命名一个混合，D-08）。选定后，本节填入：选定方案名、（若混合）各角色取自哪一套的说明，以及下方完整的明暗逐角色 hex 表。最终 hex 取自 `get_variables` 在 `home-pocket-palette.pen` 上选定方案的变量集合。

### 逐角色 Hex 表（Phase 33 契约 — 待填）

下表行按 `AppColors` / `AppColorsDark` 符号名预列（Phase 31 已重命名；Pitfall 4：不得发明 survival*/soul* 等平行命名）。Hex 列在选定后于 Task 3 填入。

#### Light (`AppColors`)

| Role (symbol) | Light hex | 说明 |
|---|---|---|
| `background` (=`backgroundWarm`) | `<pending>` | 页面背景 |
| `card` | `<pending>` | 卡片/surface |
| `backgroundMuted` | `<pending>` | 分区分隔 |
| `backgroundSubtle` | `<pending>` | 嵌套卡片 |
| `backgroundDivider` | `<pending>` | 卡内分隔 |
| `textPrimary` | `<pending>` | 正文/金额主文字 |
| `textSecondary` | `<pending>` | 次要文字 |
| `textTertiary` | `<pending>` | 失活/chevron |
| `borderDefault` | `<pending>` | 卡片描边 |
| `borderDivider` | `<pending>` | 分区线 |
| `borderList` | `<pending>` | 交易列表线 |
| `borderInputActive` | `<pending>` | 输入激活（珊瑚）|
| `accentPrimary` | `<pending>` | 珊瑚主色（action）|
| `accentPrimaryLight` | `<pending>` | 珊瑚浅 tint |
| `accentPrimaryBorder` | `<pending>` | 珊瑚描边 |
| `fabGradientStart` / `fabGradientEnd` | `<pending>` / `<pending>` | FAB 渐变 |
| `daily` | `<pending>` | 日常 accent/affordance |
| `dailyText` *(净新增金额变体)* | `<pending>` | 日常金额文字（≥4.5:1）|
| `dailyLight` | `<pending>` | 日常 tint |
| `joy` | `<pending>` | 悦己 accent/affordance |
| `joyText` *(净新增金额变体)* | `<pending>` | 悦己金额文字（≥4.5:1）|
| `joyLight` (=`tagGreen` alias) | `<pending>` | 悦己 tint |
| `olive` | `<pending>` | 趋势/ROI |
| `oliveLight` | `<pending>` | olive tint |
| `oliveBorder` | `<pending>` | olive 描边 |
| `shared` | `<pending>` | 群组账本 |
| `sharedText` *(净新增金额变体)* | `<pending>` | 群组金额文字（≥4.5:1）|
| `sharedLight` | `<pending>` | shared tint |
| `sharedBorder` | `<pending>` | shared 描边 |
| `sharedChevron` | `<pending>` | shared chevron |
| `success` *(净新增)* | `<pending>` | 语义-成功 |
| `warning` *(净新增)* | `<pending>` | 语义-警告 |
| `error` *(净新增)* | `<pending>` | 语义-错误 |
| `info` *(净新增)* | `<pending>` | 语义-信息 |

> 注：`dailyText`/`joyText`/`sharedText` 是为满足金额文字 ≥4.5:1 而新增的「更深文字变体」，与对应的浅 tint 配对（tint 仅用于背景/标签，金额一律用 `*Text`）。Phase 33 决定这些是独立 token 还是 `daily`/`joy`/`shared` 的派生。

#### Dark (`AppColorsDark`)

| Role (symbol) | Dark hex | 说明 |
|---|---|---|
| `background` | `<pending>` | |
| `card` | `<pending>` | |
| `backgroundMuted` | `<pending>` | |
| `backgroundSubtle` | `<pending>` | |
| `backgroundDivider` | `<pending>` | |
| `textPrimary` | `<pending>` | |
| `textSecondary` | `<pending>` | |
| `textTertiary` | `<pending>` | |
| `borderDefault` / `borderDivider` / `borderList` | `<pending>` | |
| `accentPrimary` | `<pending>` | 暗态珊瑚（提亮）|
| `daily` / `dailyLight`(=`tagBlue`) | `<pending>` / `<pending>` | |
| `joy` / `joyLight`(=`tagGreen`) | `<pending>` / `<pending>` | |
| `olive` / `oliveLight` | `<pending>` / `<pending>` | |
| `shared` / `sharedLight`(=`tagOrange`) | `<pending>` / `<pending>` | |
| `joyFullnessBg` / `joyFullnessBorder` | `<pending>` / `<pending>` | 悦己卡（暗）|
| `joyRoiBg` / `joyRoiBorder` | `<pending>` / `<pending>` | ROI 卡（暗）|
| `familyBadgeBg` | `<pending>` | 家族徽章 |
| `success` / `warning` / `error` / `info` *(净新增)* | `<pending>` ×4 | 暗态语义 |

> 暗态金额文字直接用提亮后的 accent 本身（明字在暗卡上对比达标），故暗态 `*Text` = 对应 accent。

---

## 📋 后果 (Consequences)

> 正/负/中立的具体条目在 Task 3 选定后补全（取决于所选方案的取舍）。框架如下：

### 正面（预期）
- Phase 33 获得每角色精确 hex 的单一权威来源，可直接落 token，无需返工。
- 新增 `success/warning/error/info` 语义色族，补齐当前缺口。
- 日常↔悦己达成清晰对比（D-02），强化「两本账不同」语义。

### 负面（预期）
- 暖/亮 accent 需拆分为浅 tint + 更深 `*Text` 金额变体，token 数量增加。
- 选定方案若大幅偏离现状，Phase 33 替换面更大（~62 字面量）。

### 中立
- 暗态为前瞻性探索（THEME-V2-02 仍延后全量暗色），暗色方案用于评估，非 v1.5 出货承诺。

---

## 🗓️ 实施计划 (Implementation Plan)

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 32 (本阶段) | 合成 5 方向 → 5 套 Pencil 方案 → 用户选定 → 本 ADR | 进行中 |
| Phase 33 (Color Token System) | 按本 ADR hex 表落 semantic token，替换 ~62 硬编码字面量（COLOR-01/02/03）| 待启动 |
| Phase 34 (Golden Re-baseline) | PALETTE 驱动的 golden 像素重基线 | 待启动 |

---

## 🔗 引用 (References)

- `.planning/phases/32-palette-exploration-selection/32-CONTEXT.md` — D-01…D-08 决策上下文
- `.planning/phases/32-palette-exploration-selection/32-UI-SPEC.md` — Color Exploration Contract、角色完整性矩阵、可访问性下限
- `.planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md` — 5 方向 + 逐角色 hex + WCAG 验证表
- `home-pocket-palette.pen` — 5 套 Pencil 方案（`get_variables` = 最终 hex 导出源）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — 反游戏化 100%-behavior 契约（D-03 约束）
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — daily/joy identifier 来源
- `lib/core/theme/app_colors.dart` — 角色 symbol 名（Phase 33 消费端）

---

## 📝 变更历史 (Change Log)

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-01 | 1.0-draft | 初版起草，状态 📝 草稿/Proposed，决策待 PALETTE-03 人工选定 | Claude planning agent |

---

**下次 Review:** PALETTE-03 人工选定检查点（选定后 ratify 为 ✅ 已接受）
