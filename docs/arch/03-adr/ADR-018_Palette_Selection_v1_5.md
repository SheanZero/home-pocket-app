# ADR-018: Palette Selection — v1.5 (配色选定 v1.5)

**文档编号:** ADR-018
**文档版本:** 1.0
**创建日期:** 2026-06-01
**最后更新:** 2026-06-01
**状态:** ✅ 已接受 (Accepted — 2026-06-01)
**决策者:** zxsheanjp@gmail.com (project owner，选定 Scheme D) + Claude (planning agent)
**影响范围:** v1.5 调色板 → Phase 33 semantic token system（替换 ~62 个硬编码 `Color(0x…)` 字面量）、Phase 34 golden re-baseline。本 ADR 仅记录调色板决策，不改任何 `lib/` 代码。
**相关 ADR:** ADR-016 §5（反游戏化 / 100%-behavior 契约 — D-03 约束）、ADR-017（v1.5 词汇统一 — daily/joy 等 identifier 来源）、ADR-015（词汇分层 — lineage）

> **本 ADR 已 ratify 于 2026-06-01。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-01)
**触发来源:** Phase 32「Palette Exploration & Selection」— v1.5「文案与配色统一」milestone 的中间环节。
**Ratify 路径:** Phase 32 Plan 03 — 在 PALETTE-03 阻塞式人工检查点，用户于 2026-06-01 选定 **Scheme D「Teal Clarity」**，遂 ratify。

> **决策演进（重要）：** 本阶段最初产出 5 套以珊瑚 `#E85A4F` 为品牌锚点（D-01）的方案。在 PALETTE-03 人工检查点，用户**否决全部珊瑚锚点方案**并重定向：彻底脱离现有配色，给出 5 套全新整体身份（各自独立 primary，nav/menu 底色亦不限于红/珊瑚），从品牌 DESIGN.md 重新挖掘。**D-01 珊瑚锚点由用户显式解除。** 澄清意图：5 个**不同 primary 色相**；**每方案重新定义 Daily/Joy 关系**（非固定冷暖规则）；**primary 不用红/珊瑚**（红仅作语义 `error`）；**至少一套 dark/charcoal-led**；保留明暗双态与净新增语义族。

---

## 🎯 背景 (Context)

### 双轨账本的配色问题

v1.4 末，双轨账本配色存在两个待解问题：(1) 日常蓝 `#5A9CC8` ↔ 悦己绿 `#47B88A` 属低冲突近似色，未强化「两本账不同」语义（D-02）；(2) 无独立 `success/warning/error/info` 语义族（由 olive/coral 兼任）。v1.5「文案与配色统一」要求选定唯一规范调色板并记录每角色精确 hex，供 Phase 33 token 系统消费。

### 约束（D-01 → D-08，见 `32-CONTEXT.md`；经用户重定向修订）

- ~~D-01 珊瑚锚点~~ → **由用户解除**：primary 完全开放，不再锚定珊瑚；nav/menu 底色随方案而变。
- **D-02 双轨可辨:** 日常与悦己须清晰可区分；具体「冷/暖」关系由每方案自行定义（用户要求 rethink）。
- **D-03 不升格悦己为庆祝亮点色:** 与 ADR-016 §5 的 100%-behavior 契约一致（ambient 状态，无离散庆祝）。
- **D-06 参考来源:** 挖掘 VoltAgent/awesome-design-md 品牌 DESIGN.md 集。
- **D-07 Pencil 交付:** 每套方案 home-hero / transaction-list / analytics × 明暗两态，答全语义角色。
- **D-08 选定方式:** 用户选一套或命名混合。
- **新增 guardrail（用户）:** primary 不用红/珊瑚（红仅 `error`）；至少一套 dark/charcoal-led；保留 `success/warning/error/info`。

### 为何需要在 Phase 33 之前决策

Phase 33 (Color Token System) 将散落的 ~62 个硬编码色值整合到统一 semantic token，token 取值需要一个被批准的、每角色精确 hex 的单一来源——即本 ADR。

---

## 🔍 考虑的方案 (Considered Options)

5 套全新方案均渲染于 `home-pocket-palette.pen`（5 scheme groups × 6 frames = 30 frames，明暗两态），合成依据见 `32-PALETTE-SYNTHESIS.md` (v2)。每套以**不同 primary 色相**立身（= 各自 nav/menu 底色），primary 均非红/珊瑚，红仅作 `error`；每套以**自己的逻辑**实现 Daily/Joy 可辨（D-02）；悦己 KPI 仅 ambient（D-03）；金额文字用更深 `*Text` 变体（WCAG ≥4.5:1）。

| 方案 | 名称 / primary | nav 底色 | Daily/Joy 逻辑（重定义） | 谱系 | 结论 |
|------|---------------|---------|------------------------|------|------|
| A | Indigo Trust `#4F46E5` | 靛蓝 | 跨温：slate-indigo 日常 ↔ amber 悦己 | Stripe/Linear | 拒绝 |
| B | Emerald Fresh `#0E9F6E` | 翠绿 | 同族异能：深松绿日常 ↔ 亮青柠悦己 | Spotify/Duolingo | 拒绝 |
| C | Violet Creative `#7C5CFC` | 紫罗兰 | 分裂互补：periwinkle 日常 ↔ rose-pink 悦己 | Notion/Twitch | 拒绝 |
| **D** | **Teal Clarity `#0E9AA7`** | **青色** | **冷锚+暖点：teal-navy 日常 ↔ gold 悦己** | **Vercel/Coinbase** | **✅ 采用** |
| E | Charcoal + Warm `#1F2430`(+amber) | 墨黑 | 中性 primary + 双 accent：steel-blue 日常 ↔ honey 悦己 | Vercel/Figma | 拒绝 |

### 拒绝理由

- **A Indigo Trust：** 稳重可信，但 靛蓝+琥珀 偏「通用 SaaS 仪表盘」观感；青色给出更鲜明的差异化身份，且双轨分离同样强。
- **B Emerald Fresh：** 清新有活力，但同为绿系的 日常(松绿)↔悦己(青柠) 在金额一瞥下最难区分；teal/gold 分离更硬。
- **C Violet Creative：** 富表现力，但 rose-pink 悦己易读作「庆祝/消费娱乐」，与反游戏化克制基调（D-03 精神）相左；teal/gold 更克制。
- **E Charcoal + Warm：** 高级、是 dark-led 选项，但其身份在暗色态最出彩；v1.5 以浅色优先出货（全量暗色为 THEME-V2-02 前瞻），有色相的浅色优先身份（青色）更契合当前出货面。

---

## ✅ 决策 (Decision)

**选定 Scheme D「Teal Clarity」（青色清晰）。** 青色 primary `#0E9AA7` 驱动 nav/menu 底色与 CTA；浅色面为干净的冷调近白。Daily/Joy 采「冷锚+暖点」：日常为深 teal-navy（锚定、稳重），悦己为暖金（高亮点）——全套中最强、最易读的双轨分离，且完全避开红/珊瑚。Shared 为 steel-blue（冷调第三声，以色相区别于青色日常）。红色仅出现在 `error`。

### 逐角色 Hex 表（Phase 33 契约）

行按 `AppColors` / `AppColorsDark` 符号名（Phase 31 已重命名；Pitfall 4：不得发明 survival*/soul* 平行命名）。`*Text` 为金额文字深变体（WCAG ≥4.5:1）；对应浅 tint 仅作背景/标签。`*Border`/`*Chevron`/`fabGradient*` 等派生值从锚色推导，Phase 33 可微调。

#### Light (`AppColors`)

| Role (symbol) | Hex | Role (symbol) | Hex |
|---|---|---|---|
| `background` (=`backgroundWarm`) | `#F8FCFD` | `accentPrimary` | `#0E9AA7` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#E0F4F5` |
| `backgroundMuted` | `#ECF4F5` | `accentPrimaryBorder` | `#B8E4E7` |
| `backgroundSubtle` | `#F8FCFD` | `fabGradientStart` | `#2BB6C2` |
| `backgroundDivider` | `#E5F0F1` | `fabGradientEnd` | `#0E9AA7` |
| `textPrimary` | `#112025` | `daily` | `#1C7A86` |
| `textSecondary` | `#5A7176` | `dailyText` (amount) | `#145E68` |
| `textTertiary` | `#ABC2C6` | `dailyLight` | `#E0F0F2` |
| `borderDefault` | `#E5F0F1` | `joy` | `#F0A81E` |
| `borderDivider` | `#ECF4F5` | `joyText` (amount) | `#9A6500` |
| `borderList` | `#DBEAEC` | `joyLight` (=`tagGreen`) | `#FBEFCF` |
| `borderInputActive` | `#0E9AA7` | `olive` (trends) | `#3DA77E` |
| `shared` | `#5B8AC4` | `oliveLight` | `#E4F4EE` |
| `sharedText` (amount) | `#3A6396` | `oliveBorder` | `#BFE6D6` |
| `sharedLight` | `#E8EFF7` | `success` | `#2FA37A` |
| `sharedBorder` | `#CBDBEC` | `warning` | `#C98A00` |
| `sharedChevron` | `#A8C2DD` | `error` | `#E5484D` |
| `info` | `#2A8FB8` | | |

#### Dark (`AppColorsDark`)

| Role (symbol) | Hex | Role (symbol) | Hex |
|---|---|---|---|
| `background` | `#0C1719` | `accentPrimary` | `#3FC2CE` |
| `card` | `#162527` | `accentPrimaryLight` | `#123034` |
| `backgroundMuted` | `#213537` | `daily` | `#4FB0BC` |
| `backgroundSubtle` | `#102023` | `dailyLight` (=`tagBlue`) | `#173032` |
| `backgroundDivider` | `#213537` | `joy` | `#F0C13A` |
| `textPrimary` | `#E8F2F3` | `joyLight` (=`tagGreen`) | `#33290F` |
| `textSecondary` | `#82989B` | `shared` | `#7FA8D8` |
| `textTertiary` | `#54686A` | `sharedLight` (=`tagOrange`) | `#1E2A3A` |
| `borderDefault` | `#213537` | `olive` | `#5FC79E` |
| `borderDivider` | `#213537` | `oliveLight` | `#1E3329` |
| `borderList` | `#213537` | `joyFullnessBg` | `#33290F` |
| `familyBadgeBg` | `#1E2A3A` | `joyFullnessBorder` | `#4D4015` |
| `success` | `#3FC78E` | `joyRoiBg` | `#173330` |
| `warning` | `#E5B53A` | `joyRoiBorder` | `#2D4D45` |
| `error` | `#F0676B` | `info` | `#5AA8E0` |

> 暗态金额文字直接用提亮后的 accent 本身（明字在暗卡上对比达标）：`dailyText`≈`daily`=`#4FB0BC`，`joyText`≈`joy`=`#F0C13A`，`sharedText`≈`shared`=`#7FA8D8`。

> **金额文字可访问性：** `dailyText #145E68`、`joyText #9A6500`、`sharedText #3A6396` 在 `card #FFFFFF` 上均 ≥4.5:1（WCAG AA 正文/数据文字）。悦己金色 `#F0A81E` 仅作 tag/affordance，金额一律用 `joyText`。

---

## 📋 后果 (Consequences)

### 正面
- Phase 33 获得每角色精确 hex 的单一权威来源，可直接落 token，无返工。
- 新增显式 `success/warning/error/info` 语义族（青色身份下：success 绿、warning 金、error 红、info 蓝），补齐当前缺口。
- 青色 primary + 暖金悦己 的「冷锚+暖点」给出全套最强双轨分离，强化「两本账不同」（D-02），且完全脱离原珊瑚身份（用户诉求）。
- 红色被收敛为单一语义 `error`，不再兼任 primary/品牌色——语义更纯净。

### 负面
- 与现状珊瑚身份完全切换，Phase 33 替换面较大（~62 字面量全部改色相，而非微调）。
- 暖金悦己需拆分浅 tint + 更深 `joyText` 金额变体，token 数量增加（`*Text` 系列）。
- 现有 golden 基线全部因调色板改动失效，需 Phase 34 全量 PALETTE 驱动 re-baseline。

### 中立
- 暗态为前瞻性探索（THEME-V2-02 仍延后全量暗色），暗色 hex 用于 Phase 33 token 完整性与未来出货，非 v1.5 浅色出货承诺。
- `olive`(trends) 在青色身份下取独立 emerald `#3DA77E`，与青色日常以色相区别；Phase 33 可评估是否合并。

---

## 🗓️ 实施计划 (Implementation Plan)

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 32 (本阶段) | 合成（v2，5 新方向）→ 5 套 Pencil 方案 → 用户选定 Scheme D → 本 ADR | ✅ 已完成 |
| Phase 33 (Color Token System) | 按本 ADR hex 表落 semantic token，替换 ~62 硬编码字面量（COLOR-01/02/03）| 待启动 |
| Phase 34 (Golden Re-baseline) | PALETTE 驱动的 golden 像素重基线 | 待启动 |

---

## 🔗 引用 (References)

- `.planning/phases/32-palette-exploration-selection/32-CONTEXT.md` — D-01…D-08 决策上下文（D-01 经用户解除）
- `.planning/phases/32-palette-exploration-selection/32-UI-SPEC.md` — Color Exploration Contract、角色完整性矩阵、可访问性下限
- `.planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md` (v2) — 5 新方向 + 逐角色 hex + WCAG 验证表 + 选定记录
- `home-pocket-palette.pen` — 5 套 Pencil 方案（`get_variables` = 最终 hex 导出源；Scheme D 为选定）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — 反游戏化 100%-behavior 契约（D-03 约束）
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — daily/joy identifier 来源
- `lib/core/theme/app_colors.dart` — 角色 symbol 名（Phase 33 消费端）

---

## 📝 变更历史 (Change Log)

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-01 | 1.0-draft | 初版起草（珊瑚锚点 5 方案），状态 📝 草稿/Proposed | Claude planning agent |
| 2026-06-01 | 1.0 | 用户在 PALETTE-03 否决珊瑚方案并重定向；改为 5 个非珊瑚 primary 新方案；用户选定 **Scheme D「Teal Clarity」**；填入完整明暗 hex 表；状态 ✅ 已接受 | Claude planning agent + zxsheanjp |
| 2026-06-02 | 1.1 | Joy ledger identity 由金 `#F0A81E` 改为 **丁香 Mauve `#A586B0`**（见下方 Update 章节） | zxsheanjp + Claude (quick 260602-jcl) |

---

**下次 Review:** v1.5 milestone close 或 Phase 33 (Color Token System) 开始时（验证 hex 表落 token 的执行情况）

---

## Update 2026-06-02: Joy ledger identity 改丁香 Mauve（quick 260602-jcl）

**背景:** Teal Clarity 落地后，用户反馈 **悦己(Joy) 的金/黄系 `#F0A81E` 与日常(teal) 配在一起「不好看」**
（尤其首页「本月最爱」Best Joy strip）。要求探索更适合悦己的配色。

**探索:** `docs/design/joy-color-explore.html` — 以 teal `#1C7A86` 为锚，排除黄/金（不满）与红（error 专用），
先出 6 个高饱和候选（Terracotta/Coral/Tangerine/Magenta/Orchid/Plum），用户保留 Orchid 并要求低饱和方向；
再出 6 个低饱和·烟熏系（霧紫/丁香/豆沙粉/陶土柔/柔珊瑚/紫藤），各候选在「悦己 pill × 日常 pill 横排 +
金额 + 本月最爱 strip」实面对比、明暗双验、joyText live WCAG ≥4.5:1。

**决策:** 用户选定 **丁香 Mauve** 作为悦己 ledger identity 色。

| 角色 | Light（旧 → 新） | Dark（旧 → 新） |
|------|------------------|------------------|
| `joy` | `#F0A81E` → **`#A586B0`** | `#F0C13A` → **`#C0A3CA`** |
| `joyText`（金额，WCAG AA on #FFFFFF / 暗卡） | `#9A6500` → **`#6B4877`**（7.5:1） | `#F0C13A` → **`#C0A3CA`**（7.0:1） |
| `joyLight` / `joyFullnessBg` / `satisfactionPillBg` | `#FBEFCF` → **`#F2ECF4`** | `#33290F` → **`#2A2030`** |
| `joyFullnessBorder` | `#F0C97A` → **`#CBB4D2`** | `#4D4015` → **`#3E3247`** |
| `satisfactionPillRose`（悦己强调） | `#F0A81E` → **`#A586B0`** | `#F0C13A` → **`#C0A3CA`** |
| `textMutedGold`（悦己区次要文字） | `#C98A00` → **`#8A6E92`** | `#E5B53A` → **`#B79EC4`** |

**不变（刻意保留）:**
- `joyRoiBg/joyRoiBorder` 仍为绿（= success/ROI 语义，非 joy 身份色）。
- `surfaceCream/surfaceCreamBorder` 仍为 teal-white 表面。
- **悦己充盈环**（`happiness_ring_palette.dart` 青瓷/薰衣草/奶油黄 Butter）独立配色，hz0 已定，不在本次范围。

**落地:** `lib/core/theme/app_palette.dart`（明+暗 joy 系 token）+ `app_palette_test.dart` 契约更新；
14 张 golden re-baseline（全部 `daily_vs_joy_card` + `home_hero_card`，无其它 golden 受影响 = 范围精确）；
`flutter analyze` 0 新增 issue；全量 2286/2286 测试绿。Best Joy strip 因走 `joy` token 自动随之变 Mauve。

---

## Update 2026-06-03: Superseded by ADR-019 桜餅×若葉

**本 ADR (ADR-018 Teal Clarity) 已被 ADR-019 取代。** ADR-019 将整体配色从青色清晰迁移至 桜餅×若葉 (Sakura Mochi × Wakaba) v1.6：primary/daily → 若葉绿 `#6FA36F`，FAB → 桜粉 `#D98CA0`，joy → 暖琥珀 `#A15C00`（撤回 Mauve），背景 → 暖奶油 `#FBF7F4`。

参见 `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`。
