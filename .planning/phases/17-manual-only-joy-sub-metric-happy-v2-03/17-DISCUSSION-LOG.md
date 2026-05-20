# Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 17-Manual-Only Joy Sub-Metric (HAPPY-V2-03)
**Areas discussed:** Column shape & backfill, Voice-stamping touchpoint, Toggle state + UI + ARB copy, Filter scope + DAO plumbing

---

## Area Selection

User selected all 4 presented gray areas. Free-text note: "后续用中文" (rest of discussion in Chinese).

---

## Area 1 — Column shape & backfill

### Q1.1 — Column shape (`transactions.entry_source`)

| Option | Description | Selected |
|--------|-------------|----------|
| TEXT NOT NULL + 二值 CHECK | TEXT NOT NULL DEFAULT 'manual', CHECK IN ('manual','voice'); 二值 Dart enum; 后期 OCR 重改 schema. | |
| **TEXT NOT NULL + 三值 CHECK（预留 ocr）** | TEXT NOT NULL DEFAULT 'manual', CHECK IN ('manual','voice','ocr'); 三值 Dart enum; ocr 预留但 v1.2 不入库. | ✓ |
| TEXT nullable, 'unknown' = null | TEXT NULL; legacy → null = 'unknown legacy'; 三值 enum 含 unknown. | |
| TEXT NOT NULL, 无 CHECK | TEXT NOT NULL DEFAULT 'manual'; Dart 层 strict decode 拦未知值; 无 DB CHECK 屏障. | |

**Rationale:** 三值 CHECK + 预留 ocr 避免 MOD-005 ship 时再做一次 schema migration. v1.2 范围内 ocr enum 不入库.

---

### Q1.2 — Hash chain + sync payload

| Option | Description | Selected |
|--------|-------------|----------|
| **不入 hash, 进 sync payload** | currentHash 计算不变 (id+amount+timestamp+prevHash); TransactionSyncMapper payload 携带 entry_source; 与 soul_satisfaction 一致 (不入 hash). | ✓ |
| 入 hash, 进 sync payload | entry_source 作 hash 输入; v1.1 已生成 hash 需重算; 与 soul_satisfaction 不一致. | |
| 不入 hash, 不进 sync payload | sync 跨设备丢失 source 身份, fallback 全部 'manual'; 与 SC-2 家庭同步一致性矛盾. | |

**Rationale:** v1.1 hash chain 反向兼容 + 与 soul_satisfaction 现有语义一致.

---

### Notes (implicit decisions for Area 1)

- **Backfill:** pre-launch 项目无真实用户 — column-level DEFAULT 'manual' 直接 backfill 已有 (demo/dev) row, 无独立 UPDATE 步骤. (D-04)
- **Index:** `entry_source` 不单独建 index. 现有 `idx_tx_book_timestamp` + ledger_type 过滤 + 单 book 10–100 row 的典型规模, 低基数二次过滤无显著 plan-cost 收益. (D-05)

---

## Area 2 — Voice-stamping touchpoint

### Q2.1 — Stamping path

| Option | Description | Selected |
|--------|-------------|----------|
| **CreateTransactionParams 显式传** | Params 增 EntrySource entrySource (no default); 两 screen 明确传值; TransactionConfirmScreen 增 entrySource 入参. | ✓ |
| voiceKeyword 隐式推断 | 复用现有 voiceKeyword != null 推断; 语义耦合, 脆弱. | |
| 新增 Voice 使用例变体 | CreateVoiceTransactionUseCase 包装调用; 违反 DRY (两 use case 逻辑雷同). | |
| Repository/DAO 默认 + Voice 覆盖 | DAO/Repo 加默认 manual; 默认值零散在两层; 胶水多于选项 A. | |

**Rationale:** 显式传值是 type-safe + self-documenting; 防止新增 entry path 时静默回归.

---

### Q2.2 — OCR + 非交互插入路径

| Option | Description | Selected |
|--------|-------------|----------|
| **OCR 路径 stamp 'manual'（v1.2）；MOD-005 ship 时再改** | ocr_scanner_screen.dart 推入 confirm 时传 EntrySource.manual; demo_data_service 也是 'manual'; sync 接收侧忠实保留远端值; MOD-005 ship 时独立 commit 改 OCR push 为 EntrySource.ocr. | ✓ |
| OCR 路径染 ocr | Phase 17 同时染 'ocr' row; 问题: MOD-005 未 ship, 'ocr' 语义不准确. | |
| demo 'manual', OCR 'ocr' | 同上问题, 在 MOD-005 ship 前提前染 'ocr'. | |
| OCR 路径拒绝 'ocr' (v1.2 报错)；demo 'manual' | strict 防御代码; 比选项 A 多一点防御逻辑无实际收益. | |

**Rationale:** ocr enum 预留, 但 v1.2 不产 'ocr' row, 保 MOD-005 ship lane 独立.

---

## Area 3 — Toggle state + UI + ARB copy

### Q3.1 — Toggle state

| Option | Description | Selected |
|--------|-------------|----------|
| **Session Riverpod，默认 All entries** | selectedJoyMetricVariantProvider, default JoyMetricVariant.all, session-only; 与 Phase 15 D-12 selectedTimeWindowProvider 一致; 重启 reset. | ✓ |
| Session Riverpod, 默认 All, 用户教育提示 | 同选项 A; UI 加 hint chip; Phase 17 不实现 hint, 留 v1.3+. | |
| SharedPreferences 持久化 | AppSettings.joyMetricVariant 跨 session; "audit lens" 持久化与产品语义错位. | |
| URL / route state | AnalyticsScreen route arg; 与现有架构不一致, 未用 GoRouter query params. | |

**Rationale:** audit lens 是 opt-in 临时工具, session-only 与 selectedTimeWindowProvider 平级.

---

### Q3.2 — UI placement

| Option | Description | Selected |
|--------|-------------|----------|
| **AppBar 后接 TimeWindowChip** | AppBar.actions 中 TimeWindowChip 右侧加 JoyMetricVariantChip (二元 toggle); 与"scope chip"心理模型一致. | ✓ |
| KPI mini-hero 内部 SegmentedButton | 表现"KPI 额外查看玩法"; 语义更精准但 KPI 区拥挤. | |
| Distribution 区头上方 | 控制范围明确但 KPI 区也是 Joy 表现, 位置不明显. | |
| AppBar IconButton + popup menu | 隐藏 state, 违反"状态可见"原则. | |

**Rationale:** AppBar 已建立 scope chip 模式 (TimeWindowChip); 平行的 JoyMetricVariantChip 自然扩展.

---

### Q3.3 — ARB key + 三语 neutral 文案

| Option | Description | Selected |
|--------|-------------|----------|
| **新增 analyticsJoyMetricVariant* keys，中性描述** | 5 新 keys (chipLabel, sheetTitle, optionAll, optionManualOnly, manualOnlyExplain); 中性 anchor wording: en "Manual entries only · excludes voice-estimated entries" / ja "手動入力のみ · 音声推定を除外" / zh "仅手动输入 · 不含语音估算条目"; forbidden-substring 扩展. | ✓ |
| 复用 manualInput/voiceInput | 语义漂移 ("input method" vs "metric variant"). | |
| 新 keys + tooltip / help icon | 重要信息隐藏在 icon click 后. | |
| 新 keys + 选项 description 直接解释 | 与选项 A 部分重合; planner 可自行决定要不要在 sheet option 下加副标题. | |

**Rationale:** 新增独立 keys 避免语义漂移; anchor wording 中性, 不含价值判断; forbidden-substring 扩展防"voice = 不准/不可靠"漏侧.

---

## Area 4 — Filter scope + DAO plumbing

### Q4.1 — Filter coverage (SC-3 明确以外)

| Option | Description | Selected |
|--------|-------------|----------|
| 严格划线 — 只 Joy 层指标 | HappinessReport + 满意度 + per-category + SoulVsSurvival (仅 Soul 侧) + FamilyHappiness; 不覆盖推荐/MonthlyReport/SpendTrend/LargestExpense; HomeHero 不动. | |
| **全覆盖—连 Survival 列也过滤** | SoulVsSurvival 中 Soul + Survival 两侧都过滤; 一致性高 ("manual-only 模式"). | ✓ |
| Joy 指标过滤, 但推荐也过滤 | 推荐受 AnalyticsScreen toggle 影响 = 跨上下文影响 Settings UI, 不推荐. | |
| 严格划线 + KPI mini-hero 加 footnote | 选项 A 范围 + UI footnote; planner 可加 footnote. | |

**Rationale:** "audit lens 是整个 AnalyticsScreen 范围的"语义统一; SoulVsSurvival 两侧都过滤保持 Phase 16 engagement-axis 框架.

---

### Q4.2 — 非 Joy 卡片 + 推荐 + HomeHero

| Option | Description | Selected |
|--------|-------------|----------|
| 不随 toggle. 推荐 / HomeHero 明确不过滤 | "全覆盖"仅限 Joy 类 + SoulVsSurvival; CategoryDonut/SpendTrend/LargestExpense 仍读所有 entries. | |
| **随 toggle，所有 AnalyticsScreen 卡都过滤** | manual-only 是整个 AnalyticsScreen 范围 audit 视图; CategoryDonut, MonthlySpendTrendBarChart (含 6 月趋势), LargestMonthlyExpense, MonthlyReport, KPI mini-hero, KpiHero, Soul-vs-Survival 两侧都过滤; HomeHero / Settings 推荐不过滤. | ✓ |
| 部分随 toggle: 上面所有 + LargestExpense, 但 6 月趋势不随 | 与 Phase 15 D-10 时间窗界不一致; 边界混乱. | |

**Rationale:** "manual-only 模式" 应用于整个 AnalyticsScreen, 比 Joy-only 更清晰; ROADMAP SC-3 "Joy metrics" 措辞需修正 (类 Phase 16 D-15 处理).

---

### Q4.3 — DAO plumbing

| Option | Description | Selected |
|--------|-------------|----------|
| **每个 DAO 方法加 EntrySource? entrySourceFilter 参数** | AnalyticsDao 各 method 增入参; null=不过滤, EntrySource.manual=AND entry_source=?; 表面面积大但 type-safe. | ✓ |
| _soulExpenseFilter / _survivalExpenseFilter 泛型化 | 常量变 function; SQL 拼接集中但 DAO method 签名不能表达过滤; SQL 注入需额外注意. | |
| JoyMetricFilter Freezed object | 提前抽象 over-engineering; Phase 17 唯一过滤是 entry_source. | |
| Repository 层预拼 filter，DAO 接 String | DAO 接受 string 进入 SQL 是严重倒退 (v1.0 反模式). | |

**Rationale:** 显式参数 type-safe; 沿 _soulExpenseFilter 现有常量模式 + 参数绑定避免 SQL injection.

---

## Claude's Discretion (recorded in CONTEXT.md `<decisions>` § Claude's Discretion)

- 准确放置 `EntrySource` enum (sibling 文件 vs append 到 `transaction.dart`).
- Bottom sheet vs popup for `JoyMetricVariantChip`.
- ARB 最终 wording (anchor 已给, forbidden list 已给).
- DAO method 签名中 `entrySourceFilter` 参数顺序.
- Group-mode wiring of `entrySourceFilter` (across-books variant use cases 同样接).
- Migration test fixture 策略 (扩展现有 Drift migration test 模式).
- Per-use-case unit test 扩展策略 (扩展现有 test files).
- Provider family key 是否折叠 `joyMetricVariant`.

---

## Deferred Ideas

- 永久禁止 (ADR-012 §6): Per-family-member voice-vs-manual breakdown
- Out-of-Phase-17: toggle 跨 session 持久化; OCR-only Joy variant; entry_source 过滤推荐 (D-15 显式拒); 多 book toggle 状态; entry_source 审计图表; hash chain 含 entry_source (D-02 显式拒); entry_source 独立 index (D-05 不加)
- Out-of-v1.2: MOD-005 OCR 实现; TOOL-V2-01 fl_chart 1.x; FAMILY-V2-01/02/03 family privacy hardening

---

*Phase: 17 — Manual-Only Joy Sub-Metric (HAPPY-V2-03)*
*Discussion log gathered: 2026-05-20*
