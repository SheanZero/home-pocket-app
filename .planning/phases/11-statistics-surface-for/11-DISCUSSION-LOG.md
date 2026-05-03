# Phase 11: Statistics Surface for 悦己账本 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 11-Statistics Surface for 悦己账本
**Areas discussed:** 子区放在哪 + 导航 contract, Joy/¥ trend line 数据源策略, Histogram x 轴粒度 + 5 bar 注释口径, Family/group mode 在重建后 AnalyticsScreen 的呈现

---

## Area 1: 子区放在哪 + 导航 contract（升级为整体重构）

### Q1.1 — 「悦己账本统计」子区应该如何与 AnalyticsScreen 共存？

| Option | Description | Selected |
|--------|-------------|----------|
| AnalyticsScreen 内联 + 锚点滚动 | 顶部插入 JoyLedgerSection；GlobalKey + Scrollable.ensureVisible；最小改动 | ✓ |
| 新 AnalyticsRegion enum + 独立路由参数 | `initialRegion` param；joyLedger 模式隐藏其他区域 | |
| 拆出独立 JoyAnalyticsScreen + 独立路由 | 关注点分离最干净，但用户跳转两个 Analytics 页 | |

**User's choice:** AnalyticsScreen 内联 + 锚点滚动 (Recommended)

### Q1.2 — Phase 11 是否对 AnalyticsScreen 有修改？（用户中途追问）

User asked clarifying question: "这次修改对AnalyticsScreen有修改吗"

Claude response listed 5 specific changes (顶部新增 widget / 新 provider / 锚点滚动 / 行数变化 / 不动 ARB key)，并请求是否继续 Area 1 剩下的问题或转向。

User's reply: 「**扩展当前的修改，需要对AnalyticsScreen进行整体重构，忽略之前的实现**」

→ 这次回复触发 scope 升级：从「子区插入」→「AnalyticsScreen 整体重构」。Claude 列出了 spec amendments / 复杂度变化 / ramp 顺序建议（`/gsd-ui-phase 11`）。

### Q1.3 — 重构后的 AnalyticsScreen 如何处置现有 8 个 widget？

| Option | Description | Selected |
|--------|-------------|----------|
| 保留全部 widget，重排 IA「换骨」 | 8 widget 不删；AnalyticsScreen 重组它们的位置与语义 | |
| 「悦己为一等」重建，重叠 widget 删除/重写 | 删 LedgerRatioChart / DailyExpenseChart 重定义；其他保留 | |
| Tab 架构（悦己 / 生存 / 总览），现有 widget 全部冲入对应 tab | TabBar + 3 TabView | |
| **Other**: 现有的widget都删除，重新设计AnalyticsScreen | 用户自由文本回答 | ✓ |

**User's choice:** 「现有的widget都删除，重新设计AnalyticsScreen」

→ Claude flagged 这是 v1.0 UI surfaces 的批量下架（含预算 / 月对比 / 6 个月趋势等）；列出 3 种可能（A 真删 / B 等价重建 / C 部分搬走），请求确认。

### Q1.4 — 真删还是重建（A/B/C）？

User's reply: 「**删除现有widget，在当前phase重新设计分析页面**」

→ 等价于 B（删 widget 文件 + 重新设计 + 等价能力以新形态保留）。锁为 D-01/D-02。

### Q1.5 — 重做后的 AnalyticsScreen 覆盖哪些能力？

| Option | Description | Selected |
|--------|-------------|----------|
| 全部重建：悦己 + 生存 + 跨账本 (Recommended) | 三大区域；plan 量级 ~13；最大 scope | ✓ |
| 只保留「悦己」一等能力，生存/跨账本下架到 v2 backlog | plan 量级 5-7；release notes 显式标注下架 | |
| 折中：保留 KPI + 月对比；预算/分类/趋势 v2 | 中间路线；plan 量级 M-H | |

**User's choice:** 全部重建：悦己 + 生存 + 跨账本 (Recommended)

### Q1.6 — 重建后 AnalyticsScreen 的 IA 形态？

| Option | Description | Selected |
|--------|-------------|----------|
| Tab 架构：悦己 / 生存 / 总览 (Recommended) | TabBar + 3 TabView；信息架构最清晰 | |
| 单页折叠（顶点折叠 / 隐藏-展开） | SingleChildScrollView 三 section + chevron | |
| 入口式：主页悦己 + 入口跳转生存/总览 | 主页轻；生存/总览作为子 screen | |
| **Other**: 在Pencil中给出3种IA形态的样式，我再做选择 | 用户要求视觉迭代锁定 | ✓ |

**User's choice:** 「在Pencil中给出3种IA形态的样式，我再做选择」

→ Claude 在 plain text 跟进确认：路径 A（discuss-phase 标 TBD，交 `/gsd-ui-phase 11` 画 mockup）+ Pencil 文档 A1（沿用 0502.pen）vs A2（新建 0503-analytics-redesign.pen）。

### Q1.7 — 路径 + Pencil 文档？

User's reply: 「**路径 A + Pencil 文档 A2**」

→ 锁为 D-03（IA TBD，交 UI-phase）+ D-04（Pencil 文档新建 `/Users/xinz/Documents/0503-analytics-redesign.pen`）。

---

## Area 2: Joy/¥ trend line 数据源策略

### Q2.1 — 日级 Joy/¥ trend 数据源策略？

| Option | Description | Selected |
|--------|-------------|----------|
| 新增 DAO `getDailySoulRowsForPtvf` + Dart use case 按日 fold (Recommended) | 复用 `_soulExpenseFilter` + DATE() 分组；不动 schema | ✓ |
| 扩展 Phase 9 `SoulRowSample` 加 `day` 字段，改公共 DAO 方法签名 | 跳远风险：影响 Phase 9 已锁合约 | |
| 不画 Joy/¥，画「日均满足度」趋势 + 月级 Joy/¥ 提炼在 headline | 偏离 v1.1 原始「Joy 密度」叙事；REQ amendment 必要 | |

**User's choice:** 新增 DAO `getDailySoulRowsForPtvf` + Dart use case 按日 fold (Recommended)

### Q2.2 — Joy/¥ trend line 某日零魂账 tx 时的呈现（gap-vs-zero policy）？

| Option | Description | Selected |
|--------|-------------|----------|
| 断点：该日不渲染点，线段跳过 (Recommended) | 语义最准确；chart legend 注明「断点 = 未记录」 | ✓ |
| 补零：零日点落在 y=0，连续折线 | 视觉连续；语义错误（「0 = 快乐为零」违反 sealed `MetricResult`） | |
| 补点但不着色：零日空心圈 + 不连线 | 双重点型增加认知负担 | |

**User's choice:** 断点：该日不渲染点，线段跳过 (Recommended)

### Q2.3 — Joy/¥ trend line 月总 n<5 的「thin-sample」处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 文本 fallback：不画图，渲染提示 + CTA (Recommended) | n<5 替换为 Card + 文案 + 「去记录 »」CTA | ✓ |
| 调暗画图：opacity 0.3 折线 + caption「n=k rated」警示 | 视觉连续但与 STATSUI-02 字面要求不一致 | |
| 点画不连线 + headline mean 隐藏 | 语义谨慎但与 Phase 10 D-09 不一致 | |

**User's choice:** 文本 fallback：不画图，渲染提示 + CTA (Recommended)

### Q2.4 — 重建后 AnalyticsScreen 的月份选择器与 Joy/¥ trend / histogram 的时间窗？

| Option | Description | Selected |
|--------|-------------|----------|
| 保留 selectedMonthProvider，所有图表随选中月份变化 (Recommended) | 历史月份回看；与 PROJECT.md「不要双时间轴」不矛盾 | ✓ |
| 删除选择器，锁死 MTD（与 HomePage 同步） | v1.0 关键能力丢失 | |
| 保留选择器但加「本月/历史」toggle | 双状态增加复杂度 | |

**User's choice:** 保留 selectedMonthProvider，所有图表随选中月份变化 (Recommended)

---

## Area 3: Histogram x 轴粒度 + 5 bar 注释口径

### Q3.1 — Histogram x 轴粒度 + 5 bar 注释口径？

| Option | Description | Selected |
|--------|-------------|----------|
| 1-10 全 bucket，5 bar 加「中央値・含未評価」三语注释 (Recommended) | 与 ADR-014 voice 重对齐 v1.2 衔接 | ✓ |
| 只画 picker 5 个值 (2/4/6/8/10) + 一根独立「voice/legacy」bucket | voice bucket 能量不明 | |
| 1-10 全 bucket，但 picker 不可达奇数/5 默认隐藏，toggle 展开 | 双状态增加 UI 复杂度 | |

**User's choice:** 1-10 全 bucket，5 上加「中央値 · 含未评」注释 (Recommended)

### Q3.2 — Histogram bar 颜色 + 计量单位？

| Option | Description | Selected |
|--------|-------------|----------|
| 单色相 soul-green × 绝对计数 (Recommended) | 与魂账主调色一致；ADR-014 unipolar positive 安全 | |
| 按满足度桌面色（1低→ 10高，渐变色带）| 与 satisfaction picker emoji 引导色一致 | ✓ |
| 单色相 soul-green × 百分比（y 轴为 count/total）| 跨月可比但隐藏小样本 | |

**User's choice:** 按满足度桌面色（1低→ 10高，渐变色带）

→ Claude 紧跟 follow-up：cool→warm 双色相还是单色相强度渐变？因为 ADR-014 unipolar positive 张力。

### Q3.3 — Histogram 渐变色带的具体色阶？

| Option | Description | Selected |
|--------|-------------|----------|
| 单色相 soul-green 强度渐变（1 浅绿 → 10 深绿）(Recommended) | ADR-014 安全；与魂账设计语言一致 | |
| 双色相 cool→warm（1 冷色 → 10 暖色） | 与 picker emoji 引导色一致；ADR-014 张力 | ✓ |
| 你决定（UI-phase Pencil 试不同色阶后选）| 与 Phase 10 D-13 颜色 polish 留最后一致 | |

**User's choice:** 双色相 cool→warm（1 冷色 → 10 暖色）

→ 锁为 D-10。已知张力（必须由 UI-phase + 代码评审在三处守护：设计 caption / ARB / accessibilityLabel）。

### Q3.4 — Histogram 与 Joy/¥ trend line 的 thin-sample fallback 一致性？

| Option | Description | Selected |
|--------|-------------|----------|
| 两者使用同一份「本月魂账 < 5 笔」文本 fallback (Recommended) | UI 一致；ARB 仅 1 个 KEY；与 D-07 一致 | ✓ |
| 各自独立 fallback：trend 文本 / histogram 仍画 | 行为不一致；与 STATSUI-02 字面冲突 | |
| trend 画点 + histogram 画 bar，双双加 thin-sample caption，不 fallback | 与 STATSUI-02 字面冲突 | |

**User's choice:** 两者使用同一份「本月魂账 < 5 笔」文本 fallback (Recommended)

---

## Area 4: Family/group mode 在重建后 AnalyticsScreen 的呈现

### Q4.1 — group mode 下 Joy/¥ trend 的表达策略？

| Option | Description | Selected |
|--------|-------------|----------|
| Trend 仅渲染当前 book，不跨成员叠加 (Recommended) | 守 anti-leaderboard 合约 | |
| Trend 多成员叠加（颜色区分，min-N=3 成员才画）| 视觉冲击但**违反** FAMILY-01/02 + ADR-012 binding | ✓（initial）|
| Trend 在 group mode 完全隐藏 | 体验不完整 | |

**User's initial choice:** Trend 多成员叠加（颜色区分，min-N=3 成员才画）

### Q4.2 — group mode 下 histogram 的表达策略？

| Option | Description | Selected |
|--------|-------------|----------|
| Histogram 仅渲染当前 book，与 trend 一致 (Recommended) | 零新增数据合约 | |
| Histogram 合并家庭所有 book 的 distribution（aggregate）| 新 DAO 方法；合规但量级 +1-2 | ✓（initial）|
| Histogram 在 group mode 隐藏，仅保留 trend | 与 trend 选项不一致 | |

**User's initial choice:** Histogram 合并家庭所有 book 的 distribution（aggregate）

### Q4.3 — Tradeoff flag（Claude raised）

Claude flag 了 Q4.1 + Q4.2 选择与 ADR-012 / FAMILY-01/02 / Phase 9 D-08 binding 合约的直接冲突，列出冲突清单 + 4 条路径（X1/X2/X3/D 破合约）+ 推荐 X1 或 X2。

**User's reply:** 「**X2**」

→ 即「trend 当前 book + histogram 当前 book + 新增 FamilyInsightCard 在重建 AnalyticsScreen 顶部，复合 FamilyHighlightsSum + SharedJoyInsight 句式」。锁为 D-11/D-12/D-13。anti-leaderboard 合约保护成功。

### Q4.4 — FamilyInsightCard 与 Phase 10 hero card family rings 的表达分工？

| Option | Description | Selected |
|--------|-------------|----------|
| HomePage = 环图视觉冲击，Analytics = 句式信息密度 (Recommended) | 两个屏分工互补；同份合约两种渲染 | ✓ |
| 两者同时画环图 + 句式侧面包 | 重复表达；ring widget 跨屏依赖复杂 | |
| AnalyticsScreen 根本不画 family，只 HomePage hero card 画 | group mode 体验不完整 | |

**User's choice:** HomePage = 环图视觉冲击，Analytics = 句式信息密度 (Recommended)

→ 锁为 D-14。

---

## Claude's Discretion

下列在 CONTEXT.md `<decisions>` 末尾「Claude's Discretion」节列出，由 planner / UI-phase 决定：
- chart 库选择（fl_chart / charts_flutter / 其他）
- ARB 命名空间前缀（`analytics*` / `joyLedger*` / `joyAnalytics*`）
- 8 个旧 widget 物理删除策略（直接 `rm` vs 移到 `deprecated/`，默认推荐直接删）
- 旧 widget 配套 ARB key 清理 / 迁移
- 月份选择器在不同 IA 候选下的具体 affordance
- `getDailySatisfactionTrend` dormant DAO 处置
- ADR-XXX_Analytics_Redesign_v1_1.md 草稿是否需要
- chart y 轴 baseline / unit display / tooltip 内容细节
- TabController 状态保持策略（如果走 Tab IA）
- FamilyInsightCard 句式具体 ARB 模板（ja/zh/en）
- Phase 11 plan 阶段是否拆 ADR 草稿成独立 plan unit

---

## Deferred Ideas

详见 CONTEXT.md `<deferred>` 节，本节仅列摘要：

**仍在 v1.1 内（Phase 12）：**
- ARB 文案 polish（Phase 11 新 KEY 的 register review 顺便覆盖）
- Phase 12 RENAME 改 home* KEY 与 Phase 11 chart 标题命名空间隔离

**v1.2+ defer：**
- 多成员 Joy/¥ trend 叠加 → 新 REQ FAMILY-V2-04 + ADR-XXX_Cross_Member_Comparison_Reevaluation_v1_2
- Family aggregate distribution / family daily series → 新 family 合约 + 新 DAO
- ADR-014 voice estimator 重对齐
- 预算管理 UI 重设计（Phase 11 删除 BudgetProgressList 的等价能力恢复）
- 6 个月趋势 / 月对比 / 总支出 KPI 在「跨账本总览」具体形态（Phase 11 内或 v1.2 拆）
- 共享 chart widget 抽象层（如发现 Phase 11 与 v1.2 chart 高度重合）
- ARB key garbage collection lint
- ADR-XXX_Analytics_Redesign_v1_1.md（UI-phase 锁 IA 后由 planner 评估必要性）

**Forbidden anti-features（milestone close 前 binding）：**
- 多成员叠加 trend / 多成员 histogram / 任何 Map<MemberId, ?> 合约
- 跨期 happiness 对比
- streaks / badges / daily targets
- AI 生成 Joy 数据解释 / 公开分享
- 「最低/最高满足度成员排行」
- Joy ROI / happiness share / soul % 类框架重新出现
