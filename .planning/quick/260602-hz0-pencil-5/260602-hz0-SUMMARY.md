---
status: complete
quick_id: 260602-hz0
date: 2026-06-02
---

# Summary — 悦己充盈环重设计（5 方案）

## Correction (重要)

初稿误把三环当作 **日常/悦己/共享 占比**。经核对 `home_hero_card.dart` + `HappinessRingsPainter`：
三环实为 **三个相互独立的悦己指标**（互不构成占比、不相加，同 Apple Fitness 三环）：
- 外环 **小确幸** highlights 数量（`_highlightsRatio`, count/10）— teal (accentPrimary)
- 中环 **满足度** 满足度均值（`_avgSatisfactionRatio`, 0–10）— green (success)
- 内环 **悦己目标** 累计 ÷ 月目标（`_joyContributionRatio`, 0–100%）— gold (joy)
- 圆心 = 悦己指数（累计值）+ 目标；section 标题「悦己充盈」。

→ 因此「单环分占比 / 单仪表 / 堆叠求和」皆不成立，已重做 5 方案（commit 7312e183）。

## Iteration 3 (最终方向 — 用户锁定 D1)

用户反馈：除 D1 外其余方向（尤其 D4）偏 web、不像手机；要求**锁定 D1 同心三环**，
做**更多变体**，重点 (a) **去掉环间留白**（三环相切）、(b) **配色过渡给出更多风格**，按真机尺寸看。

最终 HTML（采用 `frontend-design` skill 把控视觉；暖色 editorial wellness 风）：
6 个变体全部塞进**手机外框 + 真机尺寸**（环 ≈120–128px、圆心值 + 右侧图例，复刻 app Region 4 布局），
三环**相切无间距**，颜色全用 **OKLCH**（OKLab 插值，避免脏灰中点）：

| | 风格 | 过渡做法 |
|---|---|---|
| ① | 柔光渐变 | 每环同色系 OKLCH 两段（淡→浓）。最稳，改动最小。 |
| ② | 扫掠尾迹 | 弧头亮、向尾 alpha+色相渐隐（comet）。与 Flutter `SweepGradient` 天然契合。 |
| ③ | 冷暖贯通 | 三环取自**同一条 teal→green→gold** 渐变带，相切后读作由外到内的暖意流动，过渡最融合。 |
| ④ | 双色相位 | 每环在同 family 内做色相位移（teal→cyan 等），更活泼。 |
| ⑤ | 粉彩扁平 | 无渐变、柔和纯色，最干净；极简实现。 |
| ⑥ | 充盈光晕 | 浓色弧 + 同色外发光晕，深色下尤其出彩。 |

浏览器实测浅/深双验证、0 console error。

## What was delivered

**`docs/design/home-ring-redesign.html`** — 自包含可在浏览器查看的设计探索稿，5 个方案**均保持三指标独立**，
浅/深色切换 + 对比表 + 推荐路径。三色 teal→green→gold 按明度错开（色盲安全）+ 环内 OKLCH 柔光。

| # | 方案 | 如何呈现三独立指标 | 读数清晰 | 亲和度 | 改造成本 |
|---|------|------|----------|--------|----------|
| D1 | 柔光三环 | 三同心环（半径差区隔）+ 圆头柔光 + 暖心圆心 | ★★★ | ★★★★ | 低 |
| D2 | 标签同心环 | 同心环 + 每环图标 + 弧尖数值胶囊（7/10、8.4、62%） | ★★★★★ | ★★★★ | 中 |
| D3 | 三连小仪表 | 三个独立 270° 小仪表并排（物理分离） | ★★★★★ | ★★★ | 中 |
| D4 | 悦己之花 | 三花瓣自暖心绽放，花瓣长度=各指标进度 | ★★★ | ★★★★★ | 高 |
| D5 | 点阵充能环 | 三同心点阵环，按进度点亮格子（小确幸可数格） | ★★★★ | ★★★★ | 中 |

## Recommendation

- **低风险首选 → D1 柔光三环**：与现有 `HappinessRingsPainter`（三同心环 + SweepGradient + 圆头）一一对应，
  仅换同色系 2 段 OKLCH 柔光 + 三色按明度错开 + 圆心加暖意，可直接落到现有 `CustomPainter`。
- **读数最佳 → D2 标签同心环**（图标+数值胶囊解决「环读不出数字」，非颜色冗余编码天然色盲友好）；
  **最贴主题 → D4 悦己之花**（绽放即充盈，情感最强）。
- 所有方案三指标各自独立（半径/扇区/独立仪表区隔），三色按**明度**错开以过色盲 + 120dp，环内柔光不跨环。

## Verification (evidence)

- 浏览器 (chrome-devtools, file://) 实测渲染：5 个方案均呈现三个独立指标，浅色 + 深色均正常，**0 console error**。
- 截图确认：D1 同心柔光环 + 🌸；D2 环 + 图标 + 数值胶囊；D3 三独立小仪表 7/8.4/62%；
  D4 三花瓣（长度=进度）+ 🌼；D5 三点阵环按进度点亮。深色用 dark 变体（teal #3FC2CE 等）。

## Deviations from standard gsd-quick flow

- **未走 gsd-planner → gsd-executor 子代理链。** 原因：(1) 产物是设计稿而非代码；
  (2) Pencil MCP 本环境无法落盘（D-03b）+ `gsd-executor` 被剥离 MCP（claude-code#13898）→ executor 无法操作 Pencil。
  实测 `get_screenshot` 读旧盘渲染空白、`snapshot_layout` 证明节点仅在 live model → 改 HTML/SVG 交付以保可验证+持久+入库。
- **一次返工**：初版语义错误（三环误判为类别占比），用户纠正后重新调研「三独立径向指标」并重做 5 方案。

## Follow-ups (not done)

- 选定方向后落地到 `happiness_rings_painter.dart`（D1 改动最小）+ golden re-baseline。
- 若选 D2（弧尖数值胶囊）需在 painter 外层叠加 label 层 + i18n；D4 需新画法（花瓣）。
- Pencil 落盘问题（D-03b）仍未解。
