# Phase 41: 汇率服务 (Exchange Rate Service) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 41-汇率服务 (Exchange Rate Service)
**Areas discussed:** 今日汇率 TTL 策略, 网络等待与降级节奏, 手动汇率的缓存语义, 缓存留存与清理

---

## 今日汇率 TTL 策略

### Q1: 「今日汇率」的 TTL 时长？

| Option | Description | Selected |
|--------|-------------|----------|
| 6 小时（推荐） | fetchedAt 超 6 小时重取，能跨过 ECB 发布点 | |
| 当日有效 | 设备本地「今天」取的就不再刷新，零点后失效；网络请求最少 | ✓ |
| 1 小时 | 最新鲜但对一天一变的汇率是无效请求密集 | |

**User's choice:** 当日有效

### Q2: 次日 ECB 终值不同要回填重算吗？

| Option | Description | Selected |
|--------|-------------|----------|
| 不回填，保存即定格（推荐） | appliedRate 是保存时刻的事实，永不自动改 | ✓ |
| 提示但不自动改 | 下次打开详情时若偏差>1% 提示可更新 | |
| 静默回填 | 与已锁定的反静默原则相悖 | |

**User's choice:** 不回填，保存即定格

### Q3: 「代理值」缓存（actualRateDate ≠ rateDate）跨天后按历史永久吗？

| Option | Description | Selected |
|--------|-------------|----------|
| 可修正：代理值不算永久（推荐） | 该日成历史后下次查询重取一次，覆盖后永久；已保存账目不变 | ✓ |
| 简单版：缓存即永久 | 逻辑最简，误差一般<1% | |

**User's choice:** 可修正：代理值不算永久

---

## 网络等待与降级节奏

### Q1: 总等待预算？

| Option | Description | Selected |
|--------|-------------|----------|
| 紧凑：总预算 ~3 秒（推荐） | 每源超时 ~1-1.5 秒，快速降级 | ✓ |
| 宽松：总预算 ~8 秒 | 弱网下更可能拿到真值，代价是转圈久 | |

**User's choice:** 紧凑：总预算 ~3 秒

### Q2: 全链失败后同会话的后续请求？

| Option | Description | Selected |
|--------|-------------|----------|
| 短冷却，约 1 分钟（推荐） | 失败后冷却期内直接走缓存 | |
| 每次都重试 | 无状态但离线时反复等 3 秒 | |
| 监听系统联机状态 | connectivity 监听，彻底离线直接跳过网络 | ✓ |

**User's choice:** 监听系统联机状态

### Q3: 「联机但 API 挂」要不要叠加短冷却？

| Option | Description | Selected |
|--------|-------------|----------|
| 叠加短冷却（推荐） | connectivity 为主门 + 全链失败后 ~1 分钟冷却，双层防护 | ✓ |
| 不叠加，联机就重试 | 接受小概率场景下反复转圈 | |

**User's choice:** 叠加短冷却

---

## 手动汇率的缓存语义

### Q1: 手动覆盖的汇率写进 exchange_rates 缓存吗？

| Option | Description | Selected |
|--------|-------------|----------|
| 写缓存，但仅作兜底（推荐） | source='manual' 入表，优先级最低，仅离线且无 API 缓存时使用 | ✓ |
| 不写缓存 | 语义最干净但离线连续记账要每笔重输 | |
| 写缓存且同日优先 | 复用最强但可能让用户意外 | |

**User's choice:** 写缓存，但仅作兜底

### Q2: 全新币种 + 离线 + 零缓存时怎么办？

| Option | Description | Selected |
|--------|-------------|----------|
| 强制手动输汇率（推荐） | RateResult 增加 unavailable 形态，UI 要求填汇率才能保存 | ✓ |
| 提示切回日元记账 | 简单但丢失原币信息 | |

**User's choice:** 强制手动输汇率

---

## 缓存留存与清理

### Q1: exchange_rates 清理策略？

| Option | Description | Selected |
|--------|-------------|----------|
| 永不清理（推荐） | 数据量可忽略；避免删掉 fawazahmed0 窗口外取不回的老汇率 | |
| 保留 2 年 | 定期删除 2 年前条目 | ✓ |

**User's choice:** 保留 2 年（用户明确选择，未采纳推荐项）

### Q2: 清理时机？

| Option | Description | Selected |
|--------|-------------|----------|
| App 启动后台顺带执行（推荐） | AppInitializer 后异步跑一次 DELETE | |
| 每次写入时顺带 | upsert 时顺手删过期行，零额外调度 | ✓ |

**User's choice:** 每次写入时顺带

### Q3: 备份导出/导入包含 exchange_rates 吗？

| Option | Description | Selected |
|--------|-------------|----------|
| 不包含（推荐） | 纯缓存语义，恢复后按需重取 | |
| 包含 | 恢复后离线立刻有兜底汇率 | ✓ |

**User's choice:** 包含（用户明确选择，未采纳推荐项）

---

## Claude's Discretion

- 每源超时毫秒分配（总预算 ~3 秒内）；单源内不重试的倾向
- sealed `RateResult` 具体变体设计与命名
- use case 拆分粒度
- 手动汇率有效性校验细则（沿用 Phase 40 结论）
- 冷却窗口精确时长与存放位置（内存级）
- 「今天」时区判定基准（倾向设备本地日）
- 2 年清理边界精度
- >1% 差异计算落点（use case 层产出信号）

## Deferred Ideas

None — discussion stayed within phase scope.
