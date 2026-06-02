---
status: complete
quick_id: 260602-hz0
date: 2026-06-02
---

# Summary — 首页三色圆环重设计（5 方案）

## What was delivered

**`docs/design/home-ring-redesign.html`** — 自包含可在浏览器查看的设计探索稿，含 5 个差异化圆环方案，
浅/深色切换，对比表，推荐路径。全部基于 ADR-018 Teal Clarity token（深色用 dark 变体）。

| # | 方案 | 隐喻 | 过渡技法 | 亲和度 | 信息精度 | 改造成本 |
|---|------|------|----------|--------|----------|----------|
| D1 | 柔光三环 | 三独立预算 | 每环同色系 2 段 OKLCH 渐变 + 圆头端点 | ★★★ | ★★★★★ | 低 |
| D2 | 一盘渐变甜甜圈 | 一个整体 | 相邻段接缝端色相接，金↔蓝跳变藏在顶部间隙 | ★★★★ | ★★★ | 中 |
| D3 | 日出仪表弧 | 健康度仪表 | 270° 单条 teal→green→gold，零接缝 | ★★★★ | ★★ | 中 |
| D4 | 流体花瓣环 | 有机色块 | blob 边缘羽化互溶（metaball），无硬边界 | ★★★★★ | ★★ | 高 |
| D5 | 堆叠进度 + 吉祥物 | 堆叠进度 | 粉彩类比色相邻 + 吉祥物承载温度 | ★★★★★ | ★★★★ | 中 |

## Recommendation

- **低风险首选 → D1 柔光三环**：保留现有「三独立预算」语义（与 `HappinessRingsPainter` 一一对应），
  只把纯色换成同色系 2 段 OKLCH 渐变 + 圆头端点 + 暖心圆心，可直接落到现有 `CustomPainter`。
- **体验跃迁 → D2 / D5**：若愿从「三独立目标」转向「月度整体」叙事，单环更平静 / D5 情感最强。
- 注意 D2/D3 连续渐变弱化「各类别占比」精确比较；所有方案保证三类在**明度**上拉开以过色盲 + 120dp。

## Verification (evidence)

- 浏览器 (chrome-devtools, file://) 实测渲染：5 个圆环清晰可辨，浅色 + 深色均正常，**0 console error**。
- 截图确认：D1 同心柔光环 + 🌱 圆心；D2 蓝→teal→绿→金平滑甜甜圈；D3 日出仪表弧 + 标记；
  D4 metaball 花瓣；D5 堆叠 + 😊。深色切换后环用 dark 变体（teal #3FC2CE 等），文字可读。

## Deviations from standard gsd-quick flow

- **未走 gsd-planner → gsd-executor 子代理链。** 原因：(1) 任务产物是设计稿而非代码；
  (2) Pencil MCP 在本环境无法落盘（STATE.md D-03b），且 `gsd-executor` 被剥离 MCP 工具
  (claude-code#13898) → executor 无法操作 Pencil。主代理先在 Pencil live 搭建后确认
  `get_screenshot` 读旧盘渲染空白（`snapshot_layout` 证明节点已在 live model，但不落盘），
  遂**改交付 HTML/SVG** 以保证可验证 + 持久 + 入库；Pencil 临时节点已从 live 画布清除。

## Follow-ups (not done)

- 选定方向后落地到 `happiness_rings_painter.dart`（D1 改动最小）+ golden re-baseline。
- 若选 D2/D5 需同步调整圆心文案与图例语义（从「三目标」到「月度整体」）。
- Pencil 落盘问题（D-03b）仍未解，如需在 Pencil 评审需另案处理上游限制。
