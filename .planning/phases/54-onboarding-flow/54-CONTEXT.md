# Phase 54: 欢迎 / 首启引导（Onboarding flow） - Context

**Gathered:** 2026-06-29
**Status:** Ready for planning

<domain>
## Phase Boundary

在 `lib/main.dart` `HomePocketApp._buildHome()` 的 gate ladder 中、`AppInitializer` settle 之后、主 shell 之前，插入**首启引导 gate**：

1. **介绍页**（隐私 / 端末内暗号化 / 本地优先 / 双账本 / 语音卖点；可跳过 → 落到设置页）
2. **设置页**（统一「行+変更」列表：昵称[必填] + 头像 + UI语言 + 记账币种 + 语音输入语言；确认键 `この設定で始める`），写穿既有 provider
3. **末尾单独一屏**：「要设置应用锁吗？」[跳过]/[现在设置]

`onboarding_complete` 仅在用户显式完成引导时一次性落（新增 `AppSettings` 字段），幂等：完成后再启动直接进主 shell。

**本 phase 只澄清「怎么实现已划定范围」。新能力（更丰富介绍轮播 = ONBOARD-V2-01；真正的应用锁 PIN/生物识别 = Phase 55；Settings 法务/赞助 = Phase 56）不在本 phase。**

</domain>

<decisions>
## Implementation Decisions

### 引导结构与 gate 排序
- **D-01 (合并身份步):** 退役独立的 `ProfileOnboardingScreen` gate（`_needsProfileOnboarding`），把它收集的**昵称 + 头像**字段与 `saveUserProfileUseCase` 逻辑**折进欢迎流的设置页**。最终首启=单一引导流（介绍 → 设置 → 锁入口），不再有两个串联 gate。
- **D-02 (介绍页保留):** Phase 53 批准的「①介绍 app 价值」页**保持不动**（隐私/本地优先/双账本/语音卖点，可跳过）。合并只发生在设置页。
- **D-03 (有意偏离批准 HTML 稿):** 批准的 sketch 001 tone-A 设计稿里设置步**没有身份字段**（只有语言/币种/语音）。合并后设置步新增「昵称+头像」两行，属对批准稿的**有意偏离**。planner 视情况补一版设计稿/QA；这是用户显式选择，非违反 design-gate。

### 幂等与持久化（onboarding_complete）
- **D-04 (存 Drift 加密 AppSettings):** `onboarding_complete` 作为 `AppSettings` 新字段存入 Drift 加密库（`@Default(false)`），**绝不从 `currency≠null` 反推**（承接 53-04 交接 / ONBOARD-01）。
- **D-05 (删除全部数据=当全新安装):** 「删除全部数据」（260627-v0w `ClearAllDataUseCase` 擦库）会连同 `onboarding_complete` 一起擦掉 → 重启后**重新走引导**。与「擦库=新开始」一致：昵称/头像/币种也都被擦，重走引导刚好重建身份+设置。
- **D-06 (导入备份=跳过引导):** 「导入备份」后跳过引导（视为已配置老用户）。实现注记：**导入成功后显式置 `onboarding_complete=true`**，不依赖旧备份是否带该字段（兼顾 Phase-54 之前导出的旧备份）。

### 写穿既有 provider（语言/币种/语音）
- **D-07 (UI 语言预选=设备语言):** 默认预选**设备语言**——设备是 ja/zh/en 之一就预选它，其它（如韩语）**回退 ja**（符合 ONBOARD-03「设备语言预选」+ 批准稿 ja-first 的调和）。
- **D-08 (UI 语言写入语义):** 用户**未改动**接受预选 → 写 `'system'`（`AppSettings.language` 现默认值，继续跟随设备）；只有在「変更」里**主动选了具体语言** → 写 `'ja'/'zh'/'en'` 钉死。确认后 MaterialApp 即时切换（`localeProvider`，ONBOARD-03）。
- **D-09 (币种 + 语音):** 币种写入既有 `Book.currency`、**复用 v1.7 货币选择器**、默认 JPY（ONBOARD-04）；语音输入语言写入既有 `AppSettings.voiceLanguage`、默认=所选 UI 语言（ONBOARD-05）。**注记:** 当 UI 语言写 `'system'` 时，语音默认应取「解析后的具体设备语言」（语音 locale 需具体 zh-CN/ja-JP/en-US，不能是 'system'）。

### 设置页交互形态
- **D-10 (统一「行+変更」模式):** 设置页全部字段统一为一行「标签: 当前值 [変更]」——昵称/头像/UI语言/币种/语音 各自点开 bottom-sheet/picker 编辑。昵称行点开=文本输入弹窗；头像行点开=既有头像选择器（`AvatarPickerScreen` / bottom-sheet）。视觉最统一。

### 流形态 / 进度 / 返回（re-entrant）
- **D-11 (锁入口=末尾单独一屏):** `この設定で始める` 确认后，弹出收尾单独一屏「要设置应用锁吗？」[跳过]/[现在设置]。主进度=介绍+设置 **2 步**，锁屏是收尾、不占主进度（贴合批准稿「末尾」措辞）。
- **D-12 (无显式进度条):** 不画步进点/进度条，**仅靠返回键/手势**导航。但 ONBOARD-06/07 仍须保证 re-entrant：返回键能从设置↔介绍、从锁屏→设置，**无法卡死**（Navigator stack + 返回处理）。

### 末尾应用锁入口落地（Phase 54 范围）
- **D-13 (进 app + 深链 Settings 安全区):** 「跳过」=进入 app，锁保持关闭（`biometricLockEnabled` 跳过即 off）；「现在设置」=进入 app 并**深链到 Settings 安全区**——真正的 PIN/生物识别设置由 **Phase 55** 在那里交付。Phase 54 **不建一次性丢弃的锁 UI**，复用现有 Settings 承载。Phase 55 依赖「此入口先存在」已满足。

### 昵称必填
- **D-14 (坚持昵称必填):** 昵称行初始显示「未設定」占位，确认键 `この設定で始める` **被拦截直到用户实际设过昵称**（沿用现有 `ProfileOnboardingScreen` 必填契约，覆盖 D-01 早先草拟的「必填」并明确不给默认占位值）。头像有随机暖 emoji 默认（`randomWarmEmoji()`）、语言/币种/语音有默认值 → **唯一强制动作=设昵称**；不保留「零输入一键确认」。

### Claude's Discretion
- 新增引导文案的 ARB key 命名与组织（实现期约束，三语 ja/zh/en 齐全，过 ARB parity + 硬编码 CJK 扫描）。
- 介绍页卖点的具体排版/插画/跳过按钮位置（单屏列卖点；轮播 = ONBOARD-V2-01 已 defer）。
- 深链到 Settings 安全区的具体导航机制（进 shell 后 push Settings / 传 intent 滚动到安全区）。
- 「行+変更」各行 bottom-sheet 的具体样式（沿用 ADR-019 桜餅×若葉 调色 + 既有组件）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 53 设计批准 + 下游交接（最重要）
- `.planning/phases/53-html/53-04-downstream-handoff.md` — Phase 54 继承的全部锁定约束（两步流、gate 时机、写穿既有 provider、onboarding_complete 显式落、末尾可跳过锁入口、三语 ARB）。
- `.planning/phases/53-html/53-01-onboarding-qa.md` — DESIGN-01 逐元素核对 + 下游继承约束。
- `.planning/sketches/001-onboarding-gate/index.html` — **批准的设计稿**（tone A · 温柔抛茶感；A 块第 48–98 行）。注意 D-03：设置步将新增身份字段、偏离此稿。

### 需求台账
- `.planning/REQUIREMENTS.md` — ONBOARD-01..07（第 21–27 行）+ ONBOARD-V2-01 defer（第 70 行）+ 追踪表（第 98–104 行）。
- `.planning/ROADMAP.md` §Phase 54（第 195–209 行）— Goal + 5 条 Success Criteria。

### 既有代码集成点（实现锚点）
- `lib/main.dart` — `_buildHome()` gate ladder（error→spinner→`_needsProfileOnboarding`→`MainShellScreen`）；`_initialize()` / `_seedAndEnsureDefaultBook()` / `_reinitializeAfterDataReset()` + `dataResetSignalProvider` 监听（260627-v0w）。
- `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` — 待退役的独立 gate（昵称必填 + 头像 `randomWarmEmoji` + `saveUserProfileUseCaseProvider`），字段折进欢迎流。
- `lib/features/settings/domain/models/app_settings.dart` — `AppSettings`（需新增 `onboarding_complete`；现有 `language`/`voiceLanguage`/`biometricLockEnabled(默认true)`）。
- `lib/features/settings/presentation/providers/state_locale.dart` — `localeProvider` / `currentLocaleProvider`（Riverpod 3：名去 Notifier 后缀）。
- 既有 v1.7 货币选择器（`CurrencySelectorSheet` / SmartKeyboard 币种键，复用，默认 JPY）；语音 locale 设置（`state_settings.dart` + `voice_locale_helpers.dart`）。

### 数据重置 / 备份（D-05/D-06 相关）
- `lib/shared/utils/invalidate_all_data_providers.dart` + `lib/core/state/data_reset_signal.dart` — 擦库/导入后的全量失效 + app-root 重 bootstrap（260627-v0w）。
- 备份 `BackupData` 导出/导入路径（researcher 需确认 onboarding_complete 是否进 backup payload，或导入成功后置 true）。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProfileOnboardingScreen` 的昵称/头像采集 + `saveUserProfileUseCase` + `AvatarDisplay`/`AvatarPickerScreen` + `randomWarmEmoji()` — 整体折进欢迎流设置页，不重写采集逻辑。
- v1.7 货币选择器（`Book.currency` 写入路径，默认 JPY）— 直接复用（D-09）。
- `localeProvider`（即时切换）+ `AppSettings.voiceLanguage` + `voice_locale_helpers.dart` — 写穿目标（D-07/08/09）。
- `dataResetSignalProvider` + `invalidateAllDataProviders` + `_reinitializeAfterDataReset` — 擦库/导入后的既有重 bootstrap 机制（D-05/06 直接落在此流上）。
- 既有 Settings 安全区（`security_section.dart`）— 「现在设置」深链目标（D-13），Phase 55 在此扩展。

### Established Patterns
- Gate ladder 在 `_buildHome()` 内以 `if` 分支顺序判定（init settle 之后），新引导 gate 排在 `MainShellScreen` 之前、且**取代** `_needsProfileOnboarding` 分支（D-01）。
- `AppSettings` 经 `appSettingsProvider`（Drift 加密，`@freezed` + `fromJson`）；新增字段走 build_runner 重生。
- Riverpod 3 约定（见 CLAUDE.md）：provider 名去 `Notifier` 后缀、`AsyncValue.value` 可空、side-effect 用 `ref.listen`。

### Integration Points
- `lib/main.dart` `_buildHome()` — 新引导 gate 判定点（读 `onboarding_complete`，init settle 后，绝不竞态）。
- `AppSettings` schema — 新增 `onboarding_complete`（可能触发 Drift schema 版本+迁移，researcher 确认；当前 v22）。
- MaterialApp `locale` — 确认 UI 语言后即时切换（已由 `currentLocaleProvider` 驱动）。
- Settings 安全区 — 「现在设置」深链落点（与 Phase 55 衔接）。

</code_context>

<specifics>
## Specific Ideas

- 设置页确认键文案锁定 `この設定で始める`（批准稿）。
- 介绍卖点四项（隐私/端末内暗号化、本地优先、日常+悦己双账本、声でサッと記録）来自批准稿 CJK 串。
- 锁入口收尾屏措辞中性、可明确跳过；跳过=锁关闭（不暗示已开）。

</specifics>

<deferred>
## Deferred Ideas

- 更丰富的介绍轮播 / 引导内权限预说明 — **ONBOARD-V2-01**（已在 REQUIREMENTS.md 台账，V2）。
- 真正的应用锁 PIN/生物识别设置 UI + 安全评审 — **Phase 55**（本 phase 仅提供深链入口）。
- Settings 法务/赞助/日本合规 — **Phase 56**。

None beyond the above — 讨论始终在 phase scope 内（合并身份步是对既有 onboarding gate 的重组，非新能力）。

</deferred>

---

*Phase: 54-onboarding-flow*
*Context gathered: 2026-06-29*
