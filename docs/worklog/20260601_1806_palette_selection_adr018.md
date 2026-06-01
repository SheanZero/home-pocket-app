# Palette Exploration & Selection — ADR-018 (Teal Clarity)

**日期:** 2026-06-01
**时间:** 18:06
**任务类型:** 架构决策 / 设计
**状态:** 已完成
**相关模块:** Phase 32 — Palette Exploration & Selection (v1.5「文案与配色统一」)

---

## 任务概述

为 v1.5「文案与配色统一」milestone 选定唯一规范调色板。挖掘品牌 DESIGN.md 设计参考 → 合成候选方向 → 产出 Pencil 方案 → 用户人工选定 → 记录为 ADR-018。本阶段不改任何 `lib/` 代码，仅产出设计合成文档、Pencil mockups、与已接受的 ADR-018。

---

## 完成的工作

### 1. 主要变更

- **设计参考挖掘（PALETTE-01）：** 从 VoltAgent/awesome-design-md 挖掘并刷新 7+ 品牌 DESIGN.md 配色（Claude/Notion/Wise/Coinbase/Stripe/Spotify/Vercel/Figma 等）。
- **合成文档 `32-PALETTE-SYNTHESIS.md`：** 经两轮——
  - v1：5 套以珊瑚 `#E85A4F` 为锚点的方向（用户在选定检查点否决）。
  - **v2（采纳）：** 5 套全新非珊瑚 primary 身份——A Indigo Trust / B Emerald Fresh / C Violet Creative / **D Teal Clarity** / E Charcoal+Warm。每套独立 primary 色相（= nav/menu 底色），各自重定义 Daily/Joy 关系，红仅作 `error`，含明暗双态与净新增语义族，逐角色 hex + WCAG 验证。
- **Pencil 文档 `home-pocket-palette.pen`：** 5 scheme groups × 6 frames（home-hero / transaction-list / analytics × 明暗）= 30 frames，side-by-side。调色板以 `{scheme}×{mode}` 主题变量集合（按 AppColors 符号命名）存储，`get_variables` = ADR hex 导出源。
- **人工选定（PALETTE-03）：** 阻塞式检查点。用户先否决全部珊瑚方案并重定向（脱离现有配色、5 个不同 primary、nav 底色不限红、rethink Daily/Joy、≥1 dark-led），二轮后选定 **Scheme D「Teal Clarity」**。
- **ADR-018（已接受）：** `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md`——背景 + 5 方案 Considered Options（含拒绝理由）+ 决策（Scheme D + 完整明暗逐角色 hex 表，keyed by AppColors/AppColorsDark symbols）+ 后果 + 实施计划。状态在选定后才翻转 ✅ 已接受（append-only 时序，Pitfall 5）。
- **`ADR-000_INDEX.md`：** 新增 ADR-018 条目块 + review-cadence 行 + 最后更新日期。

### 2. 技术决策

- **选定 Scheme D「Teal Clarity」：** 青色 primary `#0E9AA7`；日常 teal-navy `#1C7A86`（金额 `#145E68`）↔ 悦己暖金 `#F0A81E`（金额 `#9A6500`）的「冷锚+暖点」给出最强双轨分离（D-02），完全脱离珊瑚，红仅 `error`。
- **D-01 珊瑚锚点由用户解除：** 用户级指令优先；记录于 ADR-018 与合成文档 v2 revision note。
- **Pencil 渲染用 literal hex（非变量绑定填充）：** Pencil 主题机制一次仅渲染一个 active 变体，无法 side-by-side；变量集合保留为 `get_variables` 可读的 ADR hex 记录。

### 3. 代码变更统计

- 新增：`home-pocket-palette.pen`（~865KB）、`ADR-018_Palette_Selection_v1_5.md`、本 worklog、`32-PALETTE-SYNTHESIS.md`（含 v1→v2 重写）。
- 修改：`ADR-000_INDEX.md`。
- `lib/` 改动：**0**（本阶段零生产代码）。

---

## 遇到的问题与解决方案

### 问题 1: Pencil MCP 无 save 工具
**症状:** 变量/frames 写入仅改内存中 active editor，`.pen` 不落盘；`export_nodes` 因此失败。
**原因:** 该 MCP 不暴露 save/flush 工具；初期还误写入未命名 scratch 文档。
**解决方案:** `open_document` 绑定目标绝对路径后重建 frames；请用户在 Pencil 内 Cmd+S 落盘（已确认，865KB）。`export_nodes` 在本环境仍报错（工具缺陷）——以 inline `get_screenshot` 与已保存 `.pen` 作为选定依据替代 PNG 导出。

### 问题 2: 用户在选定检查点否决全部初始方案
**症状:** 5 套珊瑚锚点方案均不符合预期。
**原因:** 用户希望彻底脱离现有配色身份。
**解决方案:** 经 AskUserQuestion 澄清意图，重新挖掘多样 primary 品牌参考，产出 5 套全新身份并二次呈现，用户选定 Scheme D。

---

## 测试验证

- [x] 合成文档存在且含 5 个方向 + 可访问性表 + 选定记录
- [x] Pencil 30 frames 渲染验证（5 套 × 6 frames，`get_screenshot` 全部确认）
- [x] `home-pocket-palette.pen` 落盘（865KB）
- [x] ADR-018 状态 ✅ 已接受（仅在选定后翻转），含完整明暗 hex 表
- [x] `ADR-000_INDEX.md` 列出 ADR-018 + review-cadence
- [x] 无 `lib/` 改动
- [ ] PNG 导出（export_nodes 工具缺陷，未产出；以 screenshot 替代）

---

## Git 提交记录

```
docs(32-03): ratify ADR-018 — Scheme D Teal Clarity selected (见本次提交)
```

（含 ADR-018 已接受、INDEX 更新、合成文档 v2、.pen v2、本 worklog。）

---

## 后续工作

- [ ] Phase 33 (Color Token System)：按 ADR-018 hex 表落 semantic token，替换 ~62 硬编码 `Color(0x…)` 字面量
- [ ] Phase 34：PALETTE 驱动的 golden 全量 re-baseline
- [ ] 更新项目 memory 的 App Color Scheme 段（旧珊瑚/sky-blue 值已被 ADR-018 取代）

---

## 参考资源

- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md`
- `.planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md` (v2)
- `home-pocket-palette.pen`

---

**创建时间:** 2026-06-01 18:06
**作者:** Claude (planning agent)
