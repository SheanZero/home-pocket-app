# Phase 41: 汇率服务 (Exchange Rate Service) - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

完整可测、离线安全的汇率服务层：`ExchangeRateApiClient` 双源取数（Frankfurter 主源 + fawazahmed0 兜底，jsDelivr → Cloudflare 镜像链）、`ExchangeRateCacheService` cache-first（按 (date, currency) 命中零网络）、周末/节假日实际汇率日透传、application use cases（sealed `RateResult`）、手动覆盖与改日期语义按 ADR-022 执行、never-block-save 硬不变量、隐私验证（URL 零用户数据）。

不含：任何 UI/键盘/预览面板/语音改动（Phase 42）；数据层迁移与领域模型（Phase 40 已完成）。

</domain>

<decisions>
## Implementation Decisions

### 今日汇率 TTL（RATE-02 的「短 TTL」定义）
- **D-01: 当日有效。** 设备本地「今天」内取到的今日汇率不再刷新，跨零点失效。早上取到的值可能整天是前一营业日代理值——可接受（家庭记账场景），由 actualRateDate 标注兜住。历史日期汇率永久有效不受影响。
- **D-02: 保存即定格，永不回填。** 用今日（暂定）汇率保存的账目，次日 ECB 终值不同也不自动改、不提示。appliedRate 是保存时刻的事实；用户随时可手动改。与 ADR-022 反静默原则一致。
- **D-03: 代理值缓存可修正，不算永久。** 缓存行 actualRateDate ≠ rateDate 且 rateDate 已成历史日期 → 下次查询该 (date, currency) 时重取一次，拿到真实当日值后覆盖、从此永久。只影响后续新账目取值；已保存账目按 D-02 不变。注意：周末/节假日重取后拿到的仍是回溯营业日值（这是正确语义，覆盖后仍带 actualRateDate）——真正被修正的是「发布前抢跑」场景。

### 网络等待与降级节奏（RATE-03）
- **D-04: 总等待预算 ~3 秒。** 从发起取汇率到放弃网络、落缓存兜底的全链上限约 3 秒；每源超时约 1-1.5 秒（具体分配 Claude 定）。快速降级优于死等——缓存 + 手动修改永远兜底。
- **D-05: 引入 connectivity 监听作为第一道门。** 系统报告彻底离线时直接跳过网络、走缓存，不等超时。包选型（connectivity_plus 或等价）归 researcher/planner；新增依赖需照常验证 iOS build。
- **D-06: 联机但全链失败 → 叠加约 1 分钟短冷却。** connectivity 显示在线但三源全失败（API 挂/被墙）后记冷却窗口，期内后续请求直接走缓存不碰网；冷却过后下一次请求再探。两层防护保证任何情况下不反复卡 3 秒。

### 手动汇率的缓存语义（RATE-04 / RATE-06 补充）
- **D-07: 手动覆盖写入缓存但仅作最低优先级兜底。** 手动汇率以 source='manual' upsert 进 exchange_rates；取值优先级：API 实时 > API 缓存 > manual 缓存。只有离线且该币种无任何 API 缓存时才落到 manual 值。解决「离线连记几笔生僻币种反复手输」痛点，不污染正常取值。
- **D-08: 零缓存 + 取不到 → RateResult 给 unavailable 形态，强制手动输入。** 全新币种 + 离线（或双源都失败）且缓存全空时，服务返回「无可用汇率」；Phase 42 UI 据此要求用户手输汇率后才能保存外币账目。与三元组不变量自洽——手动路径永远可用，保存从不被网络阻断。

### 缓存留存与清理
- **D-09: 保留 2 年，写入时顺带清理。** upsert 时顺带 DELETE rateDate 早于 2 年前的行，零额外调度。transactions 内联的 appliedRate 不受影响（事实已定格）；超过 2 年的回溯记账属罕见场景，届时走重取或手输。
- **D-10: 备份导出/导入包含 exchange_rates 表。** 恢复后离线也立刻有兜底汇率可用。备份格式多一张表、导入多一条分支；家庭同步管道仍然永不携带缓存（调研锁定，不变）。

### Claude's Discretion
- 每源超时的具体毫秒分配（总预算 ~3 秒内）、是否单源内重试（倾向不重试——源链本身就是重试）。
- sealed `RateResult` 的具体变体设计（fetched / cached / fallback / unavailable / manual 等命名与字段），满足 ROADMAP 成功标准 2/3 的 `fallback` 携带实际缓存日期、`fetched.actualDate` 语义即可。
- use case 拆分粒度（GetExchangeRateUseCase 之外是否单列手动覆盖/改日期重算 use case）。
- 手动汇率有效性校验细节（沿用 Phase 40 结论：正数、可解析，细则 Claude 定）。
- 冷却窗口的精确时长（约 1 分钟）与存放位置（内存级即可，无需持久化）。
- 「今天」的时区判定基准（倾向设备本地日，与账目日期口径一致）。
- 2 年清理的边界精度（按 rateDate 比较即可）。
- >1% 金额差异比较的计算落点（use case 层产出信号，UI 只消费）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v1.7 调研（HIGH confidence，2026-06-12 完成，含 API 实测）
- `.planning/research/STACK.md` — 双源 API 实测：Frankfurter 30 币清单（无 TWD）、fawazahmed0 历史窗口仅 2024-10-10 起（~8 个月滚动）、双源 lookup 伪代码、JPY 基准取数与求倒数换算、隐私清单（URL 零用户数据）。**Phase 41 最核心调研文件。**
- `.planning/research/SUMMARY.md` — 全景与 build order；注意 STATE.md 遗留 flag：fawazahmed0 CDN URL（TWD）需在计划时再实测一次
- `.planning/research/PITFALLS.md` — float 精度 / 降级链 / hash 范围论证
- `.planning/research/ARCHITECTURE.md` — 分层落位：`lib/infrastructure/exchange_rate/`（客户端+缓存服务）、`lib/application/currency/`（use cases）

### ADR（Phase 40 已落，必须遵守）
- `docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md` — rate 全程 String；唯一换算点 `convertToJpy`
- `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md` — 新币种字段排除在 hash 外
- `docs/arch/03-adr/ADR-022_Edit_Semantics.md` — 覆盖×改日期弹窗二选一；无覆盖改日期 >1% → 非阻断 toast + 可撤销；日元只读派生。**Phase 41 的覆盖/改日期 use case 语义直接来源。**

### 需求与路线图
- `.planning/REQUIREMENTS.md` — RATE-01..06（本 phase 全部需求）
- `.planning/ROADMAP.md` — Phase 41 成功标准 1-5（缓存零网络 / fallback 不抛 / actualDate 透传 + TWD 路由 / 覆盖语义 / never-block-save + URL 隐私）
- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — Phase 40 决策全集（D-01..09），尤其 D-09 缓存表列语义与「TTL 判定归 Phase 41」的交接

### 关键源文件（Phase 40 已落地，本 phase 直接消费）
- `lib/features/currency/domain/models/exchange_rate.dart` — `ExchangeRate` Freezed 模型（rate String、source、actualRateDate 已定义）
- `lib/features/currency/domain/repositories/exchange_rate_repository.dart` — `findByDate` / `findLatest` / `upsert` 接口；D-03 可修正语义与 D-09 清理可能需要扩展接口
- `lib/data/daos/exchange_rate_dao.dart` + `lib/data/repositories/exchange_rate_repository_impl.dart` — 已实现的数据层
- `lib/infrastructure/sync/relay_api_client.dart` — 现有 `package:http` 客户端范例（超时/错误处理模式参考）
- `lib/application/settings/` — 备份导出/导入 use case 落点（D-10 需扩展备份范围）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `http ^1.6.0` 已在 pubspec，`relay_api_client.dart` 是现成的 HTTP 客户端 + 超时模式范例——无需新 HTTP 依赖。
- `ExchangeRateDao`/`ExchangeRateRepositoryImpl`/`ExchangeRate` 模型 Phase 40 已交付，服务层直接组合。
- `Result<T>` 错误通道贯穿 application 层——`RateResult` 之外的失败路径沿用。

### Established Patterns
- Use case 类放 `lib/application/{domain}/`，providers 接线放 feature 的 `presentation/providers/`（Phase 42 接线，本 phase 只交付 use case 类）。
- 基础设施目录 `lib/infrastructure/exchange_rate/`（镜像 `sync/` 命名，调研已锁定）。
- `import_guard.yaml` `inherit: true`——新子目录自动受层级约束。
- 新增依赖（connectivity 包，D-05）须验证 `flutter build ios --debug --no-codesign`（参考 CLAUDE.md 依赖 pin 教训）。

### Integration Points
- `CreateTransactionUseCase`/`UpdateTransactionUseCase` 零 HTTP（成功标准 5）——汇率永远预先解析后传入；本 phase 不改这两个 use case，只提供上游服务。
- 备份导出/导入（`lib/application/settings/`）需纳入 exchange_rates 表（D-10）。
- 家庭同步管道零接触——缓存永不进 sync（调研锁定）。
- Phase 42 消费面：sealed `RateResult`（含 unavailable 形态，D-08）+ >1% 变化信号 + staleness 日期，是 Phase 42 预览面板/表单的全部输入契约。

</code_context>

<specifics>
## Specific Ideas

- 用户的取舍倾向一以贯之：**事实一旦保存就不再被系统碰**（保存即定格），但**缓存层允许自我修正**（代理值重取）——「账目是事实，缓存是工具」。
- 体感优先于完整性：宁可 3 秒快速降级 + 标注 staleness，不接受为拿真值让用户等 8 秒。
- 离线体验是一等公民：connectivity 门 + 冷却 + manual 兜底 + 备份含缓存，四处决策都偏向「离线时一切照常」。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 41-汇率服务 (Exchange Rate Service)*
*Context gathered: 2026-06-12*
