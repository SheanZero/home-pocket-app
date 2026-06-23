# Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 47-i18n-macos-golden-uat
**Areas discussed:** WR 修复取舍, Golden 覆盖广度, 真机 UAT 清单+门槛, 反毒性扫描覆盖

---

## 区域选择（present_gray_areas）

| Option | Description | Selected |
|--------|-------------|----------|
| WR 修复取舍 | Phase 46 评审遗留 4 warning，UAT 前修 vs 丢 backlog | ✓ |
| Golden 覆盖广度 | chart golden 从零撰写，矩阵宽度/粒度/状态 | ✓ |
| 真机 UAT 清单+门槛 | 清单覆盖/设备 locale/失败项是否阻断 | ✓ |
| 反毒性扫描覆盖 | 禁词表复用 vs 扩充/测试文件粒度/孤儿 ARB | ✓ |

**User's choice:** 全选（4/4）

---

## WR 修复取舍

### Q1 — 哪些 WR 折进 Phase 47（多选）
| Option | Description | Selected |
|--------|-------------|----------|
| WR-02 圆环对账 | 中心总额 vs 图例 % 在 >10 L1 时不对账（用户可见） | ✓ |
| WR-04 刷新一致性 | 展开日列表下拉不刷新（状态不一致） | ✓ |
| WR-01 JPY | 卡片金额写死 'JPY'（dead plumbing，app 恒 JPY） | ✓ |
| WR-03 性能 | O(n·k) 重扫 + 谎称 single-pass 注释 | ✓ |

**User's choice:** 全部 4 个折进本阶段、UAT 前修。

### Q2 — WR-01 修法
| Option | Description | Selected |
|--------|-------------|----------|
| 删 dead 字段 | 删 AnalyticsCardContext.currencyCode，显式 JPY-only | ✓ |
| 接进 ctx.currencyCode | 为多币种 analytics 预留（目前恒等 JPY、空跑） | |

### Q3 — WR-02 修法
| Option | Description | Selected |
|--------|-------------|----------|
| 加「其他」rollup | 中心保留真总额，长尾收进中性 Other 切片，全对账 | ✓ |
| 中心改取 rendered set | 中心 = top-10 之和（最简，但隐藏长尾） | |

### Q4 — WR-03 深度
| Option | Description | Selected |
|--------|-------------|----------|
| 仅修 docstring | 删谎称注释、零行为风险 | |
| 重构为单遍 | 一次遍历按 L1 聚合，消除 O(n·k) | ✓ |

**Notes:** 用户对 4 个 warning 全部采纳并要求 UAT 前修，超出最初推荐的「WR-02/04 必修、WR-01/03 轻处理」——更彻底。

---

## Golden 覆盖广度

### Q1 — 覆盖矩阵
| Option | Description | Selected |
|--------|-------------|----------|
| 全矩阵 3语×明暗 | 每卡 ja/zh/en × light/dark（≈30 master），延续 v1.5/v1.6 惯例 | ✓ |
| 代表性子集 | 每卡基准 locale 全覆 + CJK 卡 locale 点测 | |

### Q2 — 粒度
| Option | Description | Selected |
|--------|-------------|----------|
| per-card 为主 | 每卡独立 golden + 1 整页 scroll smoke | ✓ |
| screen-level 为主 | 整页 AnalyticsScreen 截图 | |

### Q3 — 状态覆盖（多选）
| Option | Description | Selected |
|--------|-------------|----------|
| drill-down 屏 | 新 CategoryDrillDownScreen 只读列表 | ✓ |
| 日历展开态 | 小确幸日历 inline 展开 _InlineDayPanel | ✓ |
| group-mode 家庭卡 | family_insight 仅组模式可见 | ✓ |
| empty/初始态 | 各卡空数据/加载态 | ✓ |

**User's choice:** 全矩阵 + per-card + 全部 4 类状态。

---

## 真机 UAT 清单+门槛

### Q1 — 清单覆盖
| Option | Description | Selected |
|--------|-------------|----------|
| 全面核验 | 5 卡 + 动效 + 下钻 + 展开 + WR 修复 + 暗色 + 三语 + 家庭卡 | ✓ |
| 聚焦关键面 | 5 卡默认态 + 下钻 + 暗色，单 locale | |

### Q2 — 设备环境
| Option | Description | Selected |
|--------|-------------|----------|
| 真机 iOS + ja 主 | 物理设备，默认 locale=ja，zh/en 抽检 | ✓ |
| 模拟器为主 | 模拟器跑全矩阵，动效/手势真机点检 | |
| 你来定 | 交给 planner | |

### Q3 — 门槛策略
| Option | Description | Selected |
|--------|-------------|----------|
| 阻断收尾 | UAT 失败项必须修复/重验才能关里程碑 | ✓ |
| 可结转 deferred | 记 human_needed，里程碑 tech_debt 下可关 | |

**Notes:** 用户明确 UAT 阻断里程碑收尾，区别于 v1.1/v1.5 的 human_needed-deferred 历史模式——因 v1.8 是视觉重设计，UAT 是核心验收。

---

## 反毒性扫描覆盖

### Q1 — 禁词表
| Option | Description | Selected |
|--------|-------------|----------|
| 复用已锁表 | 新卡套用 GATE-04 锁定 forbidden 列表 | ✓ |
| 补新措辞专用禁词 | 为堆叠条/日历加新禁词 | |

### Q2 — 测试文件粒度
| Option | Description | Selected |
|--------|-------------|----------|
| 单个 phase47 文件 | anti_toxicity_phase47_test.dart 覆盖 5 卡 | ✓ |
| per-card 文件 | 每卡一个扫描文件 | |

### Q3 — 孤儿 ARB 键
| Option | Description | Selected |
|--------|-------------|----------|
| 本阶段删除 | 删 analyticsGroupHeaderTime/Distribution/Stories + gen-l10n + force-add | ✓ |
| 保留不动 | 留死键避免 force-add 摩擦 | |

---

## Claude's Discretion
- 逐波（wave）拆分与门禁顺序（planner）。
- WR 修复 / ARB / 反毒性 / golden / UAT 的先后编排（planner）。
- 「Other」rollup 切片配色/排序细节（遵 ADR-019 调色板 + 既有 donut 调色）。

## Deferred Ideas
None — 讨论全程在阶段范围内。超出 WR-03 单遍重构的性能优化、多币种 analytics 子总额（CUR-V2-02）、收入/真实结余率（INCOME-V2-01）、fl_chart 2.x（TOOL-V2-01 已 N/A）均明确不在本阶段。
