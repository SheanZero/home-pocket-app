# Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

v1.7 多币种的最后一个 phase——纯**展示 / 输入 / 语音**层。数据层（P40：Drift v21、`Transaction` 三新字段、同步透传）与汇率服务层（P41：`ExchangeRateApiClient` 双源、`ExchangeRateCacheService` cache-first、`RateResult` sealed、`GetExchangeRateUseCase`、never-block-save 不变量）都已落地并验证通过（41 全套 2705/2705 green）。

本 phase 交付：用户能在 `SmartKeyboard` 上选外币（或 zh/ja 语音说出币种）、按币种 ISO 4217 minor unit 输入小数金额、看实时日元换算预览、保存后在列表看到原币种小字标注、在详情/编辑页完整查看并对 **原币金额 + 汇率** 两输入做联动编辑（日元只读派生）——同时 **JPY 路径完全不受影响**。

**不含：** 任何数据层/汇率服务层改动（P40/P41 已完成）；购物清单 estimatedPrice 多币种（本期不做，PROJECT.md 明示）；English 语音币种解析（VOICE-EN-V2-01，已 carried-forward 到 v2）。

**内部并行波：** keypad/display 波与 voice 波相互独立，phase 内并行执行（ROADMAP + STATE 锁定）。

</domain>

<decisions>
## Implementation Decisions

### 币种选择器布局（CURR-01/02）
- **D-01: 单行展示 = 国旗 emoji + 货币符号 + ISO 代码 + 本地化币种名。** 如 🇺🇸 $ USD 美元。搜索按 code 或 name 命中（CURR-02 要求）。币种名随 `currentLocaleProvider` 本地化（ja/zh/en）。
  - 兜底：对无 1:1 国家的币种（EUR、XAF、XCD 等），国旗位用通用区域旗/占位符（如 🇪🇺 给 EUR、或中性占位），避免 emoji 缺字渲染破版——具体占位选择归实现细节。注意 emoji 国旗跨平台渲染差异（iOS/Android）已知风险，需 golden 验证。
- **D-02: 「更多」为展开按钮 / 二级展示打开完整 ISO 4217 列表 + 实时搜索。** 默认 sheet 先呈现常用区（JPY 永远第一 + USD/EUR/CNY/HKD/GBP，按最近使用动态重排——CURR-02 已锁），点「更多」展开/进入带搜索的全表。

### 换算预览面板（DISP-01）
- **D-03: 预览展示 = 日元结果主行 + 汇率副行。** 主行 `≈ ¥7,415`；副行小字 `USD 1 = ¥148.30 · {汇率日期}`。与详情/编辑页口径一致（用户能看到换算依据）。
- **D-04: loading 态 = 原位置灰显 / 骨架。** 预览行原位淡化占位，拿到汇率后原地填充；**不跳动、不遮挡键盘**。配合 P41 D-04 总等待预算 ~3 秒。
- **D-05: 过期/回退汇率 = 预览下方 warning 色小字标签。** `RateResult.fallback`（缓存兜底）或 `fetched.actualDate ≠ 账目日`（周末/节假日代理值）时，预览下方显示 warning（琴 `#C98A00`）色小字（如「使用 6/10 缓存汇率」/「周末，采用 6/9 汇率」）。不阻断保存，仅告知——与反静默原则一致。

### 小数输入门控（CURR-05）
- **D-06: JPY/KRW（0 小数位）时点键隐藏 / 换成其他键。** `smart_keyboard.dart` 的 `onDot` 钩子已是条件可空——0 小数币种时点键不渲染（或换功能键）。注意：换键会改变切币种时的键盘布局，需保证 48dp 触控底线与不误点。
- **D-07: 外币按币种 ISO 4217 minor unit 输入小数，封顶该币种小数位。** USD/EUR/CNY 等 2 位；JPY/KRW 0 位。
- **D-08: 切到 0 小数位币种（JPY/KRW）时已输入的小数直接截断为整数。** `50.50` → `50`（**直接截断，非四舍五入**，不显示小数）。切到「仍有小数但位数更少」的币种时截/留到目标位数。
- **D-09: 转换后存入的日元 `amount` 始终整数。** 唯一换算点 `convertToJpy()` 按 ADR-020 `(originalMinorUnits / subunitToUnit × rate).round()`（用户已确认沿用 `.round()`，**不改 ADR-020**）。

### 详情/编辑页联动编辑（DISP-04 / 受 ADR-022 D-01 规范）
- **D-10: 两输入单派生模型（ADR-022 D-01 已 ratify，DISP-04「三字段双向联动」措辞作废）。** 外币行编辑页可编辑输入仅 **原币金额 + 汇率**；**日元金额只读派生**展示（`convertToJpy()` 实时计算），从不被直接赋值。「原币是事实，日元是结果」。**Phase 42 实施 MUST 按 ADR-022 执行，禁止实现三字段全双向联动**（循环依赖风险）。
- **D-11: 汇率输入字段始终可见可编辑。** 原币金额 / 汇率（可编辑）/ 日元（只读）三行常驻，汇率直接点击编辑——不折叠。
- **D-12: 只读日元派生值改原币 / 改汇率时实时重算。** 每次输入即时 `convertToJpy()` 重算展示，与录入页预览一致体验。
- **D-13（继承自 ADR-022，已锁）:** 手动覆盖后改日期 → 弹窗二选一（保留手动汇率 / 按新日期重取，无默认值）；无覆盖改日期致日元 >1% 变化 → 非阻断 toast +「撤销」（5 秒窗口），自动重算即时保存。

### Claude's Discretion
- **语音币种确认 UX（VOICE-CUR-01/02/03）:** 检测到币种后在共享 `transaction_details_form` 上呈现/高亮/可改再保存——走合理实现。约束已由需求充分锁定：zh 识别 美元/欧元/英镑/港币 等（bare `元` 保持 JPY 终止符行为）；ja 识别 ドル/ユーロ/ポンド 等（bare `ドル` 默认 USD）；识别结果 carried 到表单触发正常 rate-fetch 流；voice 语料测试按 per-currency × per-locale 扩展。`元`/`円` 歧义：zh locale=CNY，ja locale=JPY（已锁）。
- **强制手输汇率 UI（继承 P41 D-08）:** 全新币种 + 离线 + 缓存全空 → `RateResult.unavailable`，UI 要求用户手输汇率才能保存——入口形态 / 弹出时机 / 与预览面板衔接归实现。手动路径永远可用，保存从不被网络阻断。
- **列表行原币小字标注格式（DISP-02）:** 外币行展示 `USD 50.00` 类小字副标注的精确排版（位置/字号/与日元主额关系），JPY 行不变。
- **ISO 4217 列表数据源:** 完整币种列表 + 本地化名 + minor unit 的数据来源（包 / 内嵌表）归 researcher/planner——`NumberFormatter` 当前只硬编码 JPY/CNY/KRW 符号与小数位，需要扩展或引入数据源。
- 小数输入状态机的具体设计（无现有先例，STATE 标注需谨慎设计）。
- 预览 loading / warning 标签的精确文案与 ARB key 命名（ja/zh/en 三语齐全）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### ADR（已接受，MUST 遵守 — Phase 42 实施规范来源）
- `docs/arch/03-adr/ADR-022_Edit_Semantics.md` — **本 phase 编辑页最核心规范。** D-01 外币行日元只读派生（否决三字段双向联动，作废 DISP-04 原措辞）；D-02 覆盖后改日期弹窗二选一；D-03 无覆盖改日期 >1% 非阻断 toast + 撤销 5 秒（阈值 `|newJpy-oldJpy|/oldJpy > 0.01`）。append-only，遵循不改。
- `docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md` — rate 全程 String；唯一换算点 `convertToJpy()`；日元 `.round()` 取整（用户确认沿用）。
- `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md` — 新币种字段排除在 hash 外（编辑保存时不破坏既有链）。

### 需求与路线图
- `.planning/REQUIREMENTS.md` — CURR-01..05 / DISP-01..04 / VOICE-CUR-01..03（本 phase 全部 12 条需求）。
- `.planning/ROADMAP.md` — Phase 42 Goal + 成功标准 1-5（选币器不离屏 / JPY 零改动 / 实时预览 + staleness / 列表标注 + 详情编辑 + USD 50@148.30→amount=7415 集成 smoke）。

### 前序 phase 决策（直接消费）
- `.planning/phases/41-exchange-rate-service/41-CONTEXT.md` — P41 D-01..10 汇率服务决策全集，尤其 D-08（unavailable→强制手输）、TTL/fallback/actualDate 语义（预览面板消费这些信号）。
- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — P40 数据/领域决策；三元组不变量、KRW 0 小数 override、`元` 歧义 zh=CNY/ja=JPY。

### v1.7 调研（HIGH confidence，2026-06-12）
- `.planning/research/STACK.md` — 双源 API 实测、JPY 基准取数与求倒数换算、隐私清单。
- `.planning/research/ARCHITECTURE.md` — 分层落位。
- `.planning/research/PITFALLS.md` — float 精度 / 降级链。

### 关键源文件（已落地，本 phase 直接消费/扩展）
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — 动作行已有 currency 键（`currencyLabel`/`currencySymbol`）+ `onDot` 可空钩子（门控点已在）；48dp 触控底线 NON-NEGOTIABLE。
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — 4-host 共享表单（manual/voice/edit/OCR），编辑页 host 在此扩展两输入一派生。
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — `_getCurrencySymbol`/`_getCurrencyDecimals`（JPY/CNY=`CN¥`/KRW 特例已在），需扩展支持完整币种。
- `lib/shared/utils/currency_conversion.dart` — `convertToJpy()` 唯一换算点。
- `lib/application/currency/rate_result.dart` + `lib/application/currency/get_exchange_rate_use_case.dart` — `RateResult` sealed（fetched/cached/fallback/unavailable/manual）+ use case；P41 已 wire `appGetExchangeRateUseCaseProvider`（`ref.watch` 即用）。
- `lib/infrastructure/voice/{japanese,chinese}_numeral_state_machine.dart` + `lib/shared/constants/voice_currency_suffixes.dart` + `lib/features/accounting/domain/models/voice_parse_result.dart` + `lib/application/voice/parse_voice_input_use_case.dart` — voice 波扩展币种词汇与解析结果携带 currency。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SmartKeyboard`: currency 键与 `onDot?` 门控钩子已就位——D-01/D-06 直接扩展，无需重构键盘骨架。
- `TransactionDetailsForm`: 单一共享表单被 4 host 消费——编辑页联动（D-10/D-11/D-12）在此 host 内做，voice 检测的币种也通过此表单确认（VOICE-CUR-03）。
- `convertToJpy()` + `NumberFormatter`: 换算与格式化单一落点——预览（D-03）、列表标注（DISP-02）、编辑页只读日元（D-12）全部复用，保证三处口径一致。
- `RateResult` sealed + `appGetExchangeRateUseCaseProvider`: 预览面板与编辑页直接 `ref.watch` 消费，fetched.actualDate / fallback.cachedDate 喂 D-05 warning 标签。

### Established Patterns
- ARB 三语齐全（ja/zh/en）+ `flutter gen-l10n`：所有新 UI 文案（预览/loading/warning/选币器/编辑标签）MUST 走 `S.of(context)`，更新全部 3 个 ARB 文件。
- `AppPalette` ThemeExtension via `context.palette`：warning 色用 `palette.warning`（琴 `#C98A00`），禁止硬编码色值；金额用 `AppTextStyles.amountLarge/Medium/Small`（tabularFigures）。
- Golden baseline 工作流：新 UI 需 macOS 基线 golden（选币器 sheet、预览面板各态、编辑页三行、列表外币行）；CI ubuntu 用 BaselineExistenceGoldenComparator。

### Integration Points
- `SmartKeyboard` currency 键 → 新建 `CurrencySelectorSheet`（不离开录入屏，CURR-01）。
- 录入屏金额下方 → 新建实时预览面板（消费 `appGetExchangeRateUseCaseProvider`）。
- 详情/编辑页 → `TransactionDetailsForm` 编辑 host 扩展原币/汇率/只读日元三行 + ADR-022 D-02/D-03 弹窗/toast。
- 列表行（`lib/features/list/`）→ 外币行附原币小字标注（DISP-02）；JPY 行零改动（CURR-04 回归保护）。
- voice 解析 → `voice_parse_result` 携带 currency → `TransactionDetailsForm` 触发 rate-fetch。

</code_context>

<specifics>
## Specific Ideas

- 预览副行格式参照 `USD 1 = ¥148.30 · {日期}`，与详情/编辑页汇率展示口径统一。
- warning 标签文案示例：「使用 {日期} 缓存汇率」/「周末，采用 {营业日} 汇率」——精确措辞与 ARB key 待定。
- 集成 smoke 锚点（ROADMAP SC5）：USD 50 @ 148.30 → `amount=7415`，`original_currency='USD'`。
- 「原币是事实，日元是结果」是编辑模型的核心直觉（ADR-022），实现与文案应体现这一心智模型。

</specifics>

<deferred>
## Deferred Ideas

- **国旗 emoji 跨平台一致性深挖** — 若 golden/真机发现 iOS/Android 国旗渲染差异过大影响体验，可考虑改用 SVG 旗或纯符号方案；本期先用 emoji + 兜底，视验证结果再议。
- **English 语音币种解析（VOICE-EN-V2-01）** — 已 carried-forward 到 v2，本期仅 zh/ja。
- **购物清单 estimatedPrice 多币种** — PROJECT.md 明示本期不做。
- **手动汇率有效性的高级校验**（区间合理性提示等）— 本期沿用 P40/P41 基础校验（正数、可解析）。

None blocking — discussion stayed within phase scope.

</deferred>

---

*Phase: 42-entry-ui-display-voice*
*Context gathered: 2026-06-13*
