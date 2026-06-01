# Phase 32: Palette Exploration & Selection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 32-palette-exploration-selection
**Areas discussed:** 基调与延续性, 双轨账本配色, 参考来源选取, Pencil 交付与选定方式

---

## 基调与延续性 (Base Tone & Continuity)

| Option | Description | Selected |
|--------|-------------|----------|
| 围绕 Wa-Modern 做变体 | 锁定暖象牙白+珊瑚主色为锚点，方案只在账本 accent/辅色/深浅差异。低风险，Phase 33 改动最小 | |
| 保留珊瑚但放开背景/accent | 主色珊瑚不动(品牌记忆点)，背景/账本 accent/语义色自由探索(含更冷/更中性变体) | ✓ |
| 完全开放探索 | 连主色都可换(含冷淡极简、全新主色)。发散最大，但偏离 Wa-Modern 最远，Phase 33 改动最大 | |

**User's choice:** 保留珊瑚但放开背景/accent
**Notes:** 中间路径 — 珊瑚作品牌锚点贯穿所有方案，其余开放。→ CONTEXT D-01。

---

## 双轨账本配色 (Dual-Ledger Accent Strategy)

| Option | Description | Selected |
|--------|-------------|----------|
| 和谐邻近色(近现状) | 两色相接近、低冲突(如现状蓝绿)。财务克制、统一，但区分度弱 | |
| 明确对比 | 日常偏冷静/中性，悦己偏暖/亮，一眼分得开。强化「两本账不同」 | ✓ |
| 悦己升格为亮点色 | 悦己做成可庆祝的高表现亮色 + celebration overlay，日常退为中性底 | |

**User's choice:** 明确对比
**Notes:** 选了视觉对比，未选「悦己庆祝亮点」→ 保持反 gamification 姿态(ADR-016 §5)。→ CONTEXT D-02/D-03。

### 追问 1 — 暖色共存 (珊瑚主色 vs 悦己暖 accent)

| Option | Description | Selected |
|--------|-------------|----------|
| 珊瑚只做动作色 | 珊瑚收窄为 FAB/主按钮/CTA 动作色，不参与账本语义；悦己用另一暖色系(金/橘/珊) | |
| 悦己用珊瑚家族色 | 悦己 accent = 珊瑚同色系亮调，靠明度/饱和度与主色区分 | |
| 每方案自行权衡 | 不锁此点，4-5 方案各试不同解法，选定时一并对比 | ✓ |

**User's choice:** 每方案自行权衡
**Notes:** 作为探索轴而非固定规则。→ CONTEXT D-04。

### 追问 2 — 日常色调

| Option | Description | Selected |
|--------|-------------|----------|
| 保留冷蓝系 | 日常继续冷蓝/青，只调饱和与深浅。与现状连续，冷暖对比 | |
| 走中性灰/石板色 | 日常退到真正中性(灰/slate)，让悦己更跳。「日常=克制背景，悦己=亮点」最强 | |
| 每方案各试 | 不锁，方案各试冷蓝 vs 中性灰，选定时看搭配 | ✓ |

**User's choice:** 每方案各试
**Notes:** → CONTEXT D-05。

---

## 参考来源选取 (Reference Sources)

| Option | Description | Selected |
|--------|-------------|----------|
| 信任 Claude 综合 | 不预设品牌偏好，按「家庭财务+双轨+和风」从多参考综合 4-5 方向 | ✓ |
| 暖中性/亲和(Notion/Claude) | 偏 Notion/Anthropic 暖中性亲和质感 | |
| 冷淡极简(Linear/Stripe) | 偏 Linear/Stripe 冷、精准、极简专业质感 | |

**User's choice:** 信任 Claude 综合
**Notes:** researcher 自行权衡 cool-minimal vs warm-neutral。→ CONTEXT D-06。

---

## Pencil 交付与选定方式 (Pencil Deliverable & Selection)

| Option | Description | Selected |
|--------|-------------|----------|
| 三屏 × 仅浅色 | home hero+list+analytics 三屏，仅浅色。暗色留到 Phase 33 | |
| 三屏 × 浅+暗 | 三屏同时画浅色与暗色。交付量翻倍但能当场看暗色表现 | ✓ |
| 仅 home hero 一屏 | 只画最代表性的一屏快速对比。最省但看不到列表/图表表现 | |

**User's choice:** 三屏 × 浅+暗
**Notes:** 暗色为前瞻评估用(现 AppColorsDark 仅 profile)，非 v1.5 承诺全量暗色。选定允许命名 hybrid(PALETTE-03)。→ CONTEXT D-07/D-08。

---

## Claude's Discretion

- 方案数量 4 vs 5 — 取决于 mined 参考能产出多少真正不同的方向(Success Criterion #1 要求 ≥4 distinct)。
- 无障碍对比度底线 — 正文 ≥4.5:1、大字/UI ≥3:1 (WCAG) 应用于每个方案，保证 Phase 33 可实现。
- 不做中期粗筛 — 4-5 方案一次性呈现做单次选定(除非 planner 有强理由分阶段)。
- Pencil 机制(单 .pen vs 多个、frame 布局、并排比较方式)交 planner/executor。

## Deferred Ideas

- Runtime theming / 用户可选 accent 调色板 — THEME-V2-01，v1.5 只选一套。
- 全量暗色 rollout(超出 profile) — THEME-V2-02；D-07 暗色 mockup 仅供评估。
- 字体/间距/组件重设计 — 超出 v1.5 范围；参考若带出 type/layout 灵感只记录不执行。
