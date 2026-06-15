# Phase 43: HTML 设计探索关卡 (Design Gate — NO production code) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 43-html-design-gate-no-production-code
**Areas discussed:** 方向差异轴, 悦己情感基调, JOY-04 持久化, Mock 保真与评审

---

## 方向差异轴 (Direction Axes)

### 主差异轴

| Option | Description | Selected |
|--------|-------------|----------|
| 情感基调为主轴 | 布局相近,各取一种悦己表达基调,聚焦"感觉对不对" | |
| 布局/IA 为主轴 | 同一基调,不同信息架构,聚焦"好不好用" | |
| 实用vs悦己配比为主轴 | 从实用主导→均衡→悦己主导,看天平往哪偏 | ✓ |
| 混合:每套是连贯立场 | 不锁单一轴,每套多轴自洽 | |

### 方向数量

| Option | Description | Selected |
|--------|-------------|----------|
| 恰好 3 套 | 满足下限,每套做透 | |
| 4 套 | 多一个极端/实验性方向 | |
| 5 套 | (用户自定) | ✓ |

**User's choice:** 实用vs悦己配比为主轴;**5 套 mock**。对悦己主导端再给 3 套子方案「极简实用派」/「温暖反思派」/「故事画报派」。
**Notes:** 经一轮澄清确认 5-mock 阵容 = **2 实用 + 3 悦己风格**:M1 实用主导 / M2 均衡 / M3 极简实用派(悦己主导但克制干净近实用质感)/ M4 温暖反思派(悦己主导,kakeibo Q4 反思 +「值得」肯定为核心)/ M5 故事画报派(悦己主导,记忆故事/画报式)。M3/M4/M5 是悦己端三种"浓度"。

---

## 悦己情感基调 (Joy Emotional Register)

### JOY-01「值得」卡数字强度

| Option | Description | Selected |
|--------|-------------|----------|
| 数字+ambient 并重 | 金额可见但暖色 ambient 包裹,绝不做 target ring | |
| 弱化数字 | 文字/视觉肯定为主,金额次要 | |
| 各 mock 各试 | M3/M4/M5 各取不同数字强度,看哪种感觉对 | ✓ |

### 措辞 register

| Option | Description | Selected |
|--------|-------------|----------|
| calm-warm 平静温暖 | 克制、像日记,与 kakeibo 反思气质一致 | ✓ |
| warm-encouraging 鼓励热情 | 更外放的肯定,注意别滑向成就感 | |
| neutral 中性陈述 | 几乎不带情绪修饰 | |

### kakeibo Q4 前瞻反思

| Option | Description | Selected |
|--------|-------------|----------|
| 认可 | 框定为价值观肯定(非目标),ADR-012-safe 核心抓手 | ✓ |
| 谨慎 | 需在 mock 看具体措辞再判 | |

**User's choice:** 数字强度=各 mock 各试;措辞=calm-warm;kakeibo Q4=认可。
**Notes:** 硬约束:JOY-01 绝不成为 progress/target ring(HomeHero 独占唯一 target ring, ADR-016 §3)。calm-warm 直接定调 GATE-04 锁定的情感词表。

---

## JOY-04 持久化 (GATE-04 go/no-go)

### Q4 反思 prompt 交互形态

| Option | Description | Selected |
|--------|-------------|----------|
| 静态只读提示 | 温柔提问 + 示例引导,不接受输入。无新 ADR、无存储、无迁移 | ✓ |
| 可输入不持久化 | 用户能写但离开即丢弃 | |
| 可输入并加密持久化 | 触发新 ADR(隐私)+ 存储方案,可能扩大范围 | |

### 存储机制(若持久化)

| Option | Description | Selected |
|--------|-------------|----------|
| 留给新 ADR 决定 | 本阶段非持久化,无需定 | ✓ |
| 加密文件/secure storage | 避开 Drift 迁移 | |
| 新 Drift 列(需迁移) | v21→v22,扩大范围 | |

**User's choice:** 静态只读提示;存储留给新 ADR 决定(本阶段 N/A)。
**Notes:** → **GATE-04 ADR go/no-go = 不需要新 ADR**;v1.8 保持无 Drift 迁移、纯展示层。

---

## Mock 保真与评审 (Mock Production & Review)

### mock 媒介

| Option | Description | Selected |
|--------|-------------|----------|
| 自包含 HTML | 单文件,浏览器直开,executor 可产出/版本控制/截图 | |
| Pencil .pen | 保真高,但本环境 MCP 无法落盘 + executor 访问不到 | |
| HTML + 关键帧 Pencil | 主体 HTML,选定后 Pencil 精细一两帧 | ✓ |

### 数据真实度

| Option | Description | Selected |
|--------|-------------|----------|
| 真实感示例数据 | 模拟一家庭一月账目,情感读感准确 | ✓ |
| 占位符 | 产出快但读感不准 | |
| 含边界态样本 | 真实数据 + 空/低数据态 | |

### 评审覆盖

| Option | Description | Selected |
|--------|-------------|----------|
| 仅中文 + 仅浅色 | 最快,5 mock 各一版 | |
| 仅中文 + 浅+深色 | 看暖调在深色下表现(ADR-019) | ✓ |
| 三语 + 仅浅色 | 关卡就验证三语布局适配 | |

### 选定评判标准(多选)

| Option | Description | Selected |
|--------|-------------|----------|
| 悦己情感共鸣 | "为自己花钱而开心"是否传达到位 | ✓ |
| 实用性 | 总览/趋势/下钻是否更好回答"钱花哪了" | ✓ |
| ADR-012 安全度 | 自审表禁区元素越少越好 | ✓ |
| 复用度/低成本 | 多复用 17 widget + fl_chart 1.2.0 | |

**User's choice:** HTML + 关键帧 Pencil;真实感示例数据;仅中文 + 浅+深色;评判标准=悦己情感共鸣 + 实用性 + ADR-012 安全度。
**Notes:** Pencil 步骤必须主 session 手动做(executor 无 `mcp__pencil__*`,claude-code#13898)。5 mock × 2 theme = 10 视图。三语 parity 留 Phase 47。

---

## Claude's Discretion

- JOY-01 数字强度在 M3/M4/M5 间的具体分配(用户授权"各 mock 各试")。
- mock 文件存放位置/命名(建议 `mocks/` 子目录)、GATE-04 fl_chart affordance 逐图清单、GATE-01 现状深研图章节粒度。

## Deferred Ideas

- 收入录入/真实结余率 → INCOME-V2-01;预算 vs 实际 → ANALYTICS-V2-03;可定制仪表盘 → ANALYTICS-V2-02
- Sankey 流向图(无收入侧数据,不进 5-mock)→ ANALYTICS-V2-01;"about typical" 滚动带 → ANALYTICS-V2-04
- 分币种 analytics 小计 → CUR-V2-02;JOY-04 用户文本持久化(未来需新 ADR)
