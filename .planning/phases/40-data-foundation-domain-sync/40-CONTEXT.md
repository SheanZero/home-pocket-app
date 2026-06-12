# Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

多币种的数据/领域/同步底座：三个 ADR（ADR-020 汇率精度 / ADR-021 hash 范围 / ADR-022 编辑策略）、NumberFormatter 货币符号消歧（含 CNY→CN¥ 修复）+ golden 重基、Drift v20→v21 迁移（`exchange_rates` 缓存表 + `transactions` 三个 nullable 列）、`ExchangeRateDao` + repository、`Transaction` Freezed 扩展、`TransactionSyncMapper` null-safe 双向透传 + round-trip 测试、partial-triple 领域不变量。

不含：汇率 HTTP 客户端与缓存服务（Phase 41）、任何 UI/键盘/语音改动（Phase 42）。

</domain>

<decisions>
## Implementation Decisions

### 编辑语义（ADR-022 的内容）
- **D-01: 外币行的日元金额只读。** 编辑页中外币行不可直接修改日元金额；只能修改原币金额和汇率，日元金额始终由 `(originalAmount × appliedRate).round()` 派生。这把 DISP-04 的「三字段双向联动」收窄为「双输入（原币金额、汇率）单派生（日元）」——ADR-022 与 Phase 42 计划必须按此口径执行，REQUIREMENTS.md DISP-04 措辞需同步修正。
- **D-02: 手动覆盖汇率后改日期 → 弹窗询问用户**「保留手动汇率，还是按新日期重取？」。这是 RATE-06（"覆盖不被踩"）与 Phase 41 成功标准 4（"除非覆盖后主动改日期"）矛盾的正式定案：既不静默保留也不静默重取。
- **D-03: 无覆盖、改日期重取导致日元金额变化 >1% → 非阻断 toast + 可撤销。** 直接重算并提示金额变化，提供撤销恢复旧汇率；不阻断保存（与 never-block-save 不变量一致）。ROADMAP Phase 41 成功标准 4 的「确认信号」按此形态理解。

### appliedRate 跨层类型（ADR-020 的补充内容）
- **D-04: 全程 String。** DB `TextColumn`（已锁定）、Freezed 字段 `String? appliedRate`、sync wire 传字符串；唯一的 round() 转换工具内部 `double.parse` 后相乘。与 sync mapper 现有 `merchant`/`photoHash` 的 String 透传模式同构。
- **D-05: 原样保存，不规范化。** API 来源存 JSON 数字的十进制字面量，手动输入存用户原文（trim 后）；只做有效性校验（可解析为正 double），不改写。比较汇率是否变化用数值比较而非字符串比较。

### 货币符号策略（NumberFormatter，本 phase 落地）
- **D-06: 建立完整符号消歧表**，不是只修 CNY。表内明确：CN¥（CNY）、US$（USD）、HK$（HKD）、A$（AUD）、C$（CAD）、NT$（TWD）等所有 `$`/`¥` 系碰撞币种；JPY 保持 `¥` 不变。
- **D-07: 表外冷门币种回退 ISO 代码前缀格式**（如 `XXX 1,234.56`），不依赖 intl 各 locale 的默认符号差异，保证 golden 可锁定。
- **D-08: KRW 特例本 phase 一并做：** 0 小数显示（ISO subunit=100 但显示惯例 0 位）+ ₩ 符号写进同一张消歧表，避免 Phase 42 二次 golden 重基。

### exchange_rates 缓存表结构
- **D-09: 列集 = (currency, rateDate) 主键 + rate + fetchedAt + source + actualRateDate。**
  - `fetchedAt`：支撑 RATE-02「今日汇率短 TTL」的持久判定（重启不失效）。
  - `source`：frankfurter / fawazahmed0 / manual，审计可追溯。
  - `actualRateDate`：周末/节假日请求拿到回溯营业日汇率时记录实际汇率日（RATE-05 的数据基础）。
  - TTL 时长与判定逻辑归 Phase 41 服务层；表只存数据。

### Claude's Discretion
- ADR-022 的次要细节：撤销窗口时长、新建 vs 编辑路径的策略复用方式。
- appliedRate 有效性校验细节（正数、可解析、上下限、科学计数法拒绝等）。
- 符号消歧表的具体币种清单（常用 6 币 + $ 系碰撞币 + Frankfurter 30 币范围内取舍），表外自动回退 ISO 代码。
- `exchange_rates` 索引设计（latest-for-currency 查询需要 `(currency, rateDate DESC)` 形态——记得 v1.6 教训：`customIndices` 是装饰性的，必须在 onCreate + onUpgrade 显式 `CREATE INDEX`）。
- ADR 编号：现有最大 ADR-019，本 phase 三个 ADR 顺延 ADR-020/021/022，并更新 ADR-000_INDEX.md。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v1.7 调研（HIGH confidence，2026-06-12 完成）
- `.planning/research/SUMMARY.md` — 全景：技术栈、关键陷阱（float 精度 / ¥ 碰撞 / hash 范围 / 编辑语义 / partial-triple）、存储冲突裁决（Drift 表胜出）、build order
- `.planning/research/ARCHITECTURE.md` — 集成面、分层落位（`lib/infrastructure/exchange_rate/`、`lib/application/currency/`、`lib/features/currency/domain/`、`lib/data/`）
- `.planning/research/PITFALLS.md` — Pitfall 1（RealColumn "Never"）、Pitfall 2（CN¥）、Pitfall 3（hash 排除）的完整论证
- `.planning/research/STACK.md` — 包选型（`currency_picker`、`sealed_currencies`）与 API 实测记录
- `.planning/research/FEATURES.md` — 竞品功能基线

### 需求与路线图
- `.planning/REQUIREMENTS.md` — STORE-01..05（本 phase）；注意 D-01 修正 DISP-04 口径
- `.planning/ROADMAP.md` — Phase 40 成功标准 1-5（迁移/ADR/符号/sync round-trip/不变量）

### 关键源文件（调研已直接检视确认）
- `lib/data/tables/transactions_table.dart` — v20 列结构；新三列加在此处
- `lib/data/app_database.dart` — `schemaVersion => 20`，迁移模式（`from < N` + `customStatement`）
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — hash 公式输入；新字段必须排除在外（ADR-021）
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — `_getCurrencySymbol` JPY/CNY 共用 `'¥'`（:56-57，待修 bug）；消歧表落点
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — `if (x != null) 'field': x` 条件透传模式（merchant/photoHash 同构范例）
- `test/golden/amount_display_golden_test.dart` — 133 个金额 golden；符号改动后重基范围
- `docs/arch/03-adr/ADR-000_INDEX.md` — ADR 编号索引；新增 ADR-020/021/022 后更新

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TransactionSyncMapper` 条件透传模式（`merchant`/`photoHash`）：新三字段直接照搬 `if (x != null) 'field': x` / `data['field'] as T?`。
- Drift 迁移模式：v19→v20（Phase 36 `shopping_items`）是最近范例，含显式 `CREATE INDEX`（CR-01 教训）。
- `Result<T>` 错误通道：partial-triple 校验在 `CreateTransactionParams` 验证中返回 `Result.error`。

### Established Patterns
- 全部 transactions 列都是 `TextColumn`/`IntColumn`，无 `RealColumn` 先例——appliedRate 用 TextColumn 与现状一致。
- golden 基线只能在 macOS 更新（CI 是存在性比较器）；本 phase 的符号消歧会触发 amount golden 重基，须本机执行。
- `import_guard.yaml` `inherit: true`：新子目录自动受层级约束，无需改配置。

### Integration Points
- `lib/data/tables/` 新增 `exchange_rates_table.dart`；`lib/data/daos/` 新增 `exchange_rate_dao.dart`；`lib/data/repositories/` 实现。
- `lib/features/currency/domain/`（新 feature 目录）：`ExchangeRate` Freezed 模型 + `ExchangeRateRepository` 接口。
- 零改动面（调研已确认）：`analytics_dao.dart`（全部 SUM/ORDER BY 只用 `amount`）、`AppInitializer`、`ApplySyncOperationsUseCase`、`TransactionChangeTracker`。

</code_context>

<specifics>
## Specific Ideas

- 用户对编辑语义的核心直觉：**外币账目「原币是事实，日元是结果」**——日元金额永远是派生值，编辑入口只有原币金额和汇率两个。
- 覆盖×改日期的冲突场景宁可多问一次用户（弹窗二选一），不接受任何静默行为。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

（注意：D-01 对 DISP-04 的口径收窄不是 deferred，是对 Phase 42 需求的已定修正，planner 在 Phase 42 时必须采用。）

</deferred>

---

*Phase: 40-数据与同步基础 (Data Foundation + Domain + Sync)*
*Context gathered: 2026-06-12*
