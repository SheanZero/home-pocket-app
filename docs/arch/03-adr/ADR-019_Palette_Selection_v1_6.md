# ADR-019: Palette Selection — v1.6 (配色选定 v1.6)

**文档编号:** ADR-019
**文档版本:** 1.0
**创建日期:** 2026-06-03
**最后更新:** 2026-06-03
**状态:** ✅ 已接受 (Accepted — 2026-06-03)
**决策者:** zxsheanjp@gmail.com (project owner，选定 桜餅×若葉) + Claude (planning agent)
**影响范围:** v1.6 调色板 → AppPalette ThemeExtension token re-value、golden master 全量 re-baseline。本 ADR 仅记录调色板决策，不改架构逻辑。
**相关 ADR:** ADR-018（被本 ADR 取代）、ADR-016 §5（反游戏化契约 — D-03 约束不变）、ADR-017（词汇统一 — daily/joy identifier 来源不变）

> **本 ADR 已 ratify 于 2026-06-03。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-03)
**触发来源:** Quick task 260603-lr5 — 用户从 Pencil 节点 `soqKs` 选定 **桜餅×若葉 (Sakura Mochi × Wakaba)** 方向。
**Ratify 路径:** 用户于 2026-06-03 在 soqKs 节点审查配色后，直接指令将整个 App 配色从 ADR-018 Teal Clarity 切换至 桜餅×若葉。

> **决策演进（重要）：** ADR-018 确立了 Teal Clarity 调色板，并在 quick 260602-jcl 将悦己 joy 从金色改为丁香 Mauve。本次 ADR-019 进一步进化：
> - Primary/daily 从青色 teal `#0E9AA7` 改为若葉 leaf green `#6FA36F`
> - FAB/add-entry 从 teal 渐变改为 **桜粉 sakura pink `#D98CA0`**（仅 FAB，勿扩散）
> - Joy 从丁香 Mauve `#A586B0` 改为 **桜餅 Amber `#C8841A` 暖琥珀系**（完全撤回 Mauve）
> - 背景从冷调 `#F8FCFD` 改为 **暖奶油 warm cream `#FBF7F4`**
> - Shared 钢蓝 `#5B8AC4` 和语义族 success/warning/error/info 保持不变

---

## 🎯 背景 (Context)

### ADR-018 Teal Clarity 的遗留问题

ADR-018 确立了以青色 `#0E9AA7` 为主色的 Teal Clarity 调色板，在 Phase 33/34 落地并通过全量 golden re-baseline。快速迭代 quick 260602-jcl 将 joy 从金色改为丁香 Mauve。

用户在 Pencil `soqKs` 节点中探索新配色方向后，认为 **若葉绿 + 桜粉 + 暖奶油背景** 的自然系配色更符合家计账本的温暖生活感，青色调偏科技感，Mauve 悦己与整体不协调。因此决定切换调色板。

### 约束

- **D-primary（新锁定）:** accentPrimary/nav/tab/按钮 → 若葉绿 `#6FA36F`
- **D-fab-sakura（新锁定）:** FAB/add-entry 渐变 → 桜粉 `#D98CA0` 家族，仅限 FAB，不扩散
- **D-joy-amber（新锁定）:** Joy ledger → 暖琥珀 `#A15C00` 家族，完全撤回 Mauve
- **D-bg-warm-cream（新锁定）:** background → 暖奶油 `#FBF7F4`
- **D-shared-keep（不变）:** Shared steel-blue `#5B8AC4` 不变，三轨色相区分保持清晰
- **D-semantics-keep（不变）:** success/warning/error/info 与 ADR-018 保持一致
- **D-happiness-ring（不变）:** `happiness_ring_palette.dart` 充盈环 Butter 配色独立，不在本 ADR 范围

---

## 🔍 考虑的方案 (Considered Options)

本次决策由用户在 Pencil `soqKs` 节点直接选定，属于 Design Lead 决策，无需多方案对比。参考 ADR-018 的探索基础，核心取舍如下：

| 维度 | ADR-018 Teal Clarity | ADR-019 桜餅×若葉 | 理由 |
|------|---------------------|-------------------|------|
| Primary | 青色 `#0E9AA7` | 若葉绿 `#6FA36F` | 绿色更自然、温暖，家计 app 感更强 |
| FAB | teal 渐变 | 桜粉 `#D98CA0` | 樱粉作情感锚点，聚焦 add-entry 唯一性 |
| Joy | 丁香 Mauve `#A586B0` | 暖琥珀 `#C8841A` | 琥珀在绿色日常旁区分更清晰，Mauve 淡薄 |
| Background | 冷调 `#F8FCFD` | 暖奶油 `#FBF7F4` | 去除科技感，接近纸质账本质感 |
| Shared | steel-blue（不变） | steel-blue（不变） | 三轨 green+amber+blue 色相区分最优 |

---

## ✅ 决策 (Decision)

**选定 桜餅×若葉 (Sakura Mochi × Wakaba) v1.6。**

核心身份：
1. **Primary = 若葉绿 `#6FA36F`**（nav/tab/CTA/borderInputActive），去除青色科技感
2. **FAB = 桜粉 `#D98CA0`**（仅 FAB/add-entry 渐变），作为唯一情感跳色
3. **Joy = 暖琥珀 `#C8841A`/`#A15C00`**（完全取代 Mauve），与绿色日常拉开色相距离
4. **Background = 暖奶油 `#FBF7F4`**，border/text 家族同步暖化
5. **Shared = steel-blue `#5B8AC4`**（不变），green+amber+blue 三轨色相清晰区分

### 逐角色 Hex 表（Phase 260603-lr5 契约）

#### Light (`AppPalette.light`)

| Role (symbol) | Hex | Role (symbol) | Hex |
|---|---|---|---|
| `background` | `#FBF7F4` | `accentPrimary` | `#6FA36F` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#EEF6EC` |
| `backgroundMuted` | `#F3EDE8` | `accentPrimaryBorder` | `#CFE6CF` |
| `backgroundSubtle` | `#FBF7F4` | `fabGradientStart` | `#E09DB4` |
| `backgroundDivider` | `#EAE1DC` | `fabGradientEnd` | `#D98CA0` |
| `textPrimary` | `#20352B` | `actionShadow` | `#33D98CA0` |
| `textSecondary` | `#71877A` | `fabShadow` | `#33D98CA0` |
| `textTertiary` | `#A8BCB2` | `navShadow` | `#08000000` |
| `borderDefault` | `#E6DDD8` | `daily` | `#5FAE72` |
| `borderDivider` | `#EAE1DC` | `dailyText` (amount) | `#2E6B3A` |
| `borderList` | `#DDD4CE` | `dailyLight` | `#EEF6EC` |
| `borderInputActive` | `#6FA36F` | `joy` | `#C8841A` |
| `shared` | `#5B8AC4` | `joyText` (amount) | `#A15C00` |
| `sharedText` (amount) | `#3A6396` | `joyLight` | `#FFF0D6` |
| `sharedLight` | `#E8EFF7` | `joyFullnessBg` | `#FFF0D6` |
| `sharedBorder` | `#CBDBEC` | `joyFullnessBorder` | `#E8C07A` |
| `sharedChevron` | `#A8C2DD` | `joyRoiBg` | `#E4F4EE` |
| `success` | `#2FA37A` | `joyRoiBorder` | `#B8E4D6` |
| `successLight` | `#E4F4EE` | `familyBadgeBg` | `#EEF6EC` |
| `warning` | `#C98A00` | `surfaceCream` | `#FFFAF6` |
| `error` | `#E5484D` | `surfaceCreamBorder` | `#E6DDD8` |
| `info` | `#2A8FB8` | `textMutedGold` | `#A15C00` |
| `errorSurface` | `#FEF2F2` | `satisfactionPillBg` | `#FFF0D6` |
| `errorBorder` | `#FECACA` | `satisfactionPillRose` | `#C8841A` |
| `errorShadow` | `#15E5484D` | `avatarGradientStart` | `#CFE6CF` |
| `recordingGradientStart` | `#E5484D` | `avatarGradientMid` | `#E2F0E2` |
| `recordingGradientEnd` | `#C93040` | `avatarGradientEnd` | `#F0F7F0` |
| `avatarBorderAlpha` | `#80FFFFFF` | `memberGradientA` | `#CFE6CF` |
| `memberGradientB` | `#E2F0E2` | `memberGradientC` | `#F0F7F0` |
| `surfaceScrimLight` | `#14000000` | `surfaceScrimMedium` | `#0A000000` |

#### Dark (`AppPalette.dark`)

| Role (symbol) | Hex | Role (symbol) | Hex |
|---|---|---|---|
| `background` | `#171210` | `accentPrimary` | `#8DC68D` |
| `card` | `#231E1B` | `accentPrimaryLight` | `#1A2E1A` |
| `backgroundMuted` | `#2E2723` | `accentPrimaryBorder` | `#283E28` |
| `backgroundSubtle` | `#1E1916` | `fabGradientStart` | `#EDB8CA` |
| `backgroundDivider` | `#2E2723` | `fabGradientEnd` | `#E09DB4` |
| `textPrimary` | `#F0EBE6` | `actionShadow` | `#33E09DB4` |
| `textSecondary` | `#9A8E87` | `fabShadow` | `#33E09DB4` |
| `textTertiary` | `#6B5F58` | `navShadow` | `#20000000` |
| `borderDefault` | `#2E2723` | `daily` | `#7DC88D` |
| `borderDivider` | `#2E2723` | `dailyText` (amount) | `#7DC88D` |
| `borderList` | `#2E2723` | `dailyLight` | `#1A2E1A` |
| `borderInputActive` | `#8DC68D` | `joy` | `#E0A040` |
| `shared` | `#7FA8D8` | `joyText` (amount) | `#E0A040` |
| `sharedText` (amount) | `#7FA8D8` | `joyLight` | `#2E2010` |
| `sharedLight` | `#1E2A3A` | `joyFullnessBg` | `#2E2010` |
| `sharedBorder` | `#2A3D55` | `joyFullnessBorder` | `#4A3818` |
| `sharedChevron` | `#4A6E8A` | `joyRoiBg` | `#173330` |
| `success` | `#3FC78E` | `joyRoiBorder` | `#2D4D45` |
| `successLight` | `#1E3329` | `familyBadgeBg` | `#1A2E1A` |
| `warning` | `#E5B53A` | `surfaceCream` | `#1A1512` |
| `error` | `#F0676B` | `surfaceCreamBorder` | `#2E2723` |
| `info` | `#5AA8E0` | `textMutedGold` | `#C89050` |
| `errorSurface` | `#2D1515` | `satisfactionPillBg` | `#2E2010` |
| `errorBorder` | `#4D2020` | `satisfactionPillRose` | `#E0A040` |
| `errorShadow` | `#15F0676B` | `avatarGradientStart` | `#1F3020` |
| `recordingGradientStart` | `#F0676B` | `avatarGradientMid` | `#1A2A1B` |
| `recordingGradientEnd` | `#D44050` | `avatarGradientEnd` | `#162416` |
| `avatarBorderAlpha` | `#26FFFFFF` | `memberGradientA` | `#1F3020` |
| `memberGradientB` | `#1A2A1B` | `memberGradientC` | `#162416` |
| `surfaceScrimLight` | `#14000000` | `surfaceScrimMedium` | `#0A000000` |

> **金额文字可访问性（light）：** `dailyText #2E6B3A` 在 `card #FFFFFF` 上 ≈7.0:1（WCAG AA ✅），`joyText #A15C00` ≈5.9:1（✅），`sharedText #3A6396` 同 ADR-018。
>
> **金额文字可访问性（dark）：** `dailyText #7DC88D` 在 `card #231E1B` 上 ≈5.5:1（✅），`joyText #E0A040` ≈5.2:1（✅），均 ≥4.5:1 WCAG AA。

---

## 📋 后果 (Consequences)

### 正面
- 若葉绿 primary + 桜粉 FAB 给予 App 更温暖、更自然的生活感，脱离青色科技感。
- 暖琥珀 Joy 与绿色 Daily 色相距离更大（绿↔橙红），双轨可辨性高于 Mauve（绿↔紫）。
- 暖奶油背景系统性消除冷调观感，与绿色系协调。
- Shared steel-blue 保留，三轨 green+amber+blue 色相黄金三角依然成立。

### 负面
- ADR-018 及 quick 260602-jcl 所有 golden master 全部失效，需全量 re-baseline（≈70 张）。
- 丁香 Mauve 悦己身份仅活跃约 2 天，被本次撤回。
- 暖奶油背景与冷调青色完全切换，视觉验证需要人工确认。

### 中立
- `happiness_ring_palette.dart` 充盈环 Butter 配色不在本次范围，保持独立。
- `joyRoiBg/joyRoiBorder` 保持绿色（ROI/success 语义，非 joy 身份色）。
- 语义族 success/warning/error/info 与暗态变体完全不变。

---

## 🗓️ 实施计划 (Implementation Plan)

| 阶段 | 内容 | 状态 |
|------|------|------|
| quick 260603-lr5 Task 1 | lib/core/theme/app_palette.dart token re-value（全量 light+dark）+ 本 ADR + INDEX + CLAUDE.md | ✅ 已完成 |
| quick 260603-lr5 Task 2 | flutter test --update-goldens 全量 re-baseline（≈70 张 PNG） | ✅ 已完成 |

---

## 🔗 引用 (References)

- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — 被本 ADR 取代的上一版配色决策
- `/Users/xinz/Documents/home1.pen` 节点 `soqKs` — 桜餅×若葉 palette spec 来源（Pencil MCP 加密，只读）
- `lib/core/theme/app_palette.dart` — token 实现文件（ADR-019 消费端）
- `lib/core/theme/happiness_ring_palette.dart` — 充盈环独立 Butter 配色（不受本 ADR 影响）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — 反游戏化 100%-behavior 契约（D-03 约束）
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — daily/joy identifier 来源

---

## 📝 变更历史 (Change Log)

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-03 | 1.0 | 初版创建；用户选定 桜餅×若葉 方向；完整明暗逐角色 hex 表；状态 ✅ 已接受 | Claude planning agent + zxsheanjp |

---

**下次 Review:** v1.6 milestone close 或下一次配色调整时

---

## Update 2026-06-03: Joy 全族转樱粉

**触发:** Quick task 260603-lr5b — 用户要求将悦己 (Joy) 所有颜色从初始暖琥珀系 (#A15C00 家族) 全面替换为 **樱粉 sakura pink #D98CA0 及其变体**。

**变更范围 (app_palette.dart):**

| Token | Light 旧值 | Light 新值 | Dark 旧值 | Dark 新值 |
|-------|-----------|-----------|---------|---------|
| `joy` | `#C8841A` (amber) | `#D98CA0` (sakura) | `#E0A040` (amber) | `#E89BB0` (sakura) |
| `joyText` | `#A15C00` (deep amber) | `#A53D5E` (deep rose, WCAG AA ~6.1:1 on white) | `#E0A040` | `#E89BB0` (WCAG AA ~7.6:1 on dark card) |
| `joyLight` | `#FFF0D6` (amber tint) | `#FBEA EF` (pink tint) | `#2E2010` | `#2E1820` |
| `joyFullnessBg` | `#FFF0D6` | `#FBEAEF` | `#2E2010` | `#2E1820` |
| `joyFullnessBorder` | `#E8C07A` | `#E7B9C6` | `#4A3818` | `#4A2834` |
| `satisfactionPillBg` | `#FFF0D6` | `#FBEAEF` | `#2E2010` | `#2E1820` |
| `satisfactionPillRose` | `#C8841A` | `#D98CA0` | `#E0A040` | `#E89BB0` |
| `textMutedGold` | `#A15C00` | `#A53D5E` | `#C89050` | `#D98CA0` |

**变更范围 (happiness_ring_palette.dart):**

内圈 `target` (悦己目标) 从奶油黄 butter 改为樱粉 sakura，外圈 highlights (青瓷 teal) 和中圈 satisfaction (柔绿 sage) 保持不变，三环色盲安全区分继续成立。调色方案描述从 "青瓷/薰衣草/奶油黄" 更新为 "青瓷/柔绿/樱粉"。

| Token | Light 旧值 | Light 新值 | Dark 旧值 | Dark 新值 |
|-------|-----------|-----------|---------|---------|
| `target` | `#F2D777` (butter) | `#D98CA0` (sakura) | `#F7E08C` (butter) | `#E89BB0` (sakura) |
| `targetText` | `#8A7320` | `#A53D5E` | `#F7E08C` | `#E89BB0` |

**注意事项:**
- 悦己 Joy 与 FAB 添加按钮现在共享樱粉色调 (intentional, user-directed)。此举覆盖了 ADR-019 原始约束 D-fab-sakura 中"粉色仅限 FAB"的指导 — 用户明确要求 Joy 全族转樱粉。
- `joyRoiBg`/`joyRoiBorder` 保持绿色 (ROI/success 语义，非 Joy 身份色)，不受本次影响。
- 所有 golden master 已同步 re-baseline (73 张，全通过)。
- `app_palette_test.dart` 合约断言同步更新至新樱粉值。
