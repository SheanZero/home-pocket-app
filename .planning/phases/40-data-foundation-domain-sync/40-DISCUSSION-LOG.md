# Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 40-数据与同步基础 (Data Foundation + Domain + Sync)
**Areas discussed:** 编辑语义 ADR 细节, appliedRate 跨层类型, 符号策略范围, 缓存表结构细节

---

## 编辑语义 ADR 细节

### Q1: 外币行在编辑页直接修改日元金额时，语义是什么？

| Option | Description | Selected |
|--------|-------------|----------|
| 反算汇率（推荐） | 改日元金额 → 保持原币金额不变，反算 appliedRate | |
| 降级为日元行 | 直接改日元 = 「覆盖转换」，确认后清空三字段 | |
| 反算但设阈值拦截 | 默认反算；偏离 >阈值提示「改为纯日元记账」 | |
| Other（自定义） | **日元金额只读**：外币行只能改原币金额和汇率，日元由汇率派生 | ✓ |

**User's choice:** 自定义 — 不能修改日元金额；外币行进编辑页后修改外币金额，通过记录的汇率再算日元金额。
**Notes:** 把 DISP-04「三字段双向联动」收窄为「双输入单派生」；需同步修正 Phase 42 需求口径。

### Q2: 手动覆盖汇率后又修改账目日期，汇率怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 改日期重取，弹窗告知（推荐） | 重取新日期汇率并覆盖手动值，提示已替换 | |
| 手动值始终保留 | 一旦覆盖，任何日期变更不再自动重取 | |
| 询问用户 | 弹窗问「保留手动汇率，还是按新日期重取？」 | ✓ |

**User's choice:** 询问用户
**Notes:** 正式定案 RATE-06 与 Phase 41 成功标准 4 的措辞矛盾——不接受任何静默行为。

### Q3: 无覆盖、改日期重取导致日元金额变化 >1% 时确认信号形态？

| Option | Description | Selected |
|--------|-------------|----------|
| 阻断式确认弹窗（推荐） | 保存前弹窗确认金额变化 | |
| 非阻断 toast + 可撤销 | 直接重算并提示变化，提供撤销，不阻断保存 | ✓ |
| 只高亮预览差异 | 仅在 JPY 预览旁显示旧→新对比 | |

**User's choice:** 非阻断 toast + 可撤销

---

## appliedRate 跨层类型

### Q1: appliedRate 在 Freezed / sync wire / round() 运算点用什么类型？

| Option | Description | Selected |
|--------|-------------|----------|
| 全程 String，算时解析（推荐） | Freezed `String?`，wire 传字符串，round() 内 parse | ✓ |
| 领域 double，DB 边界转字符串 | Freezed `double?`，repository 存取时转换 | |
| 封装值对象 ExchangeRate | String 原始值 + double 缓存的不可变值对象 | |

**User's choice:** 全程 String，算时解析

### Q2: appliedRate 字符串的规范化规则？

| Option | Description | Selected |
|--------|-------------|----------|
| 原样保存，不规范化（推荐） | API 存 JSON 字面量，手动输入存原文（trim），只校验 | ✓ |
| 存前规范化 | 统一去尾零/限小数位再落库 | |

**User's choice:** 原样保存，不规范化
**Notes:** 汇率变化比较用数值比较而非字符串比较。

---

## 符号策略范围

### Q1: NumberFormatter 对外币符号的总体策略？

| Option | Description | Selected |
|--------|-------------|----------|
| 只修 CNY，其余用 intl 默认（推荐） | 仅 CNY→CN¥，其他沿用 intl locale 默认符号 | |
| 建立完整消歧表 | 一次性建立 CN¥/US$/HK$/A$/C$/NT$ 等明确符号表 | ✓ |
| 外币一律用 ISO 代码 | 除 JPY 外全部「USD 50.00」代码格式 | |

**User's choice:** 建立完整消歧表

### Q2: 消歧表未覆盖的冷门币种怎么显示？

| Option | Description | Selected |
|--------|-------------|----------|
| ISO 代码前缀（推荐） | 表外一律「XXX 1,234.56」 | ✓ |
| intl 默认符号 | 交给 intl NumberFormat.currency | |

**User's choice:** ISO 代码前缀

### Q3: KRW 0 小数特例是否本 phase 一并落在 NumberFormatter？

| Option | Description | Selected |
|--------|-------------|----------|
| 本 phase 一并做（推荐） | KRW 0 小数 + ₩ 符号写进同一张表，避免二次 golden 重基 | ✓ |
| 留给 Phase 42 | 显示侧晚点做 | |

**User's choice:** 本 phase 一并做

---

## 缓存表结构细节

### Q1: exchange_rates 表除 (currency, rateDate, rate) 之外还加哪些列？（多选）

| Option | Description | Selected |
|--------|-------------|----------|
| fetchedAt 拉取时间戳（推荐） | 支撑「今日汇率短 TTL」持久判定 | ✓ |
| source 来源列（推荐） | frankfurter / fawazahmed0 / manual 审计追溯 | ✓ |
| actualRateDate 实际汇率日列 | 周末/节假日回溯营业日时记录实际汇率日 | ✓ |
| 只加必需的，其余 Claude 裁量 | 由 Claude 按 RATE-01..06 反推最小列集 | |

**User's choice:** fetchedAt + source + actualRateDate 三列全加
**Notes:** TTL 时长与判定逻辑归 Phase 41 服务层，表只存数据。

---

## Claude's Discretion

- ADR-022 次要细节（撤销窗口时长、新建 vs 编辑路径策略复用）
- appliedRate 有效性校验细节（正数、可解析、上下限、科学计数法拒绝）
- 符号消歧表具体币种清单（表外自动回退 ISO 代码）
- `exchange_rates` 索引设计（显式 CREATE INDEX，v1.6 customIndices 教训）
- ADR 编号顺延 ADR-020/021/022 + 更新 ADR-000_INDEX.md

## Deferred Ideas

None — discussion stayed within phase scope.
