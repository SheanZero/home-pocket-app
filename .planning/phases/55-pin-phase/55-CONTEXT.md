# Phase 55: 应用锁（生物识别 + PIN — 最高风险，独立 phase + 安全评审） - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

在「已解密 DB 之上」加一道 **UI gate** 应用锁：

1. **冷启动重锁**：启用后冷启动需解锁才进入主 shell（`_buildHome()` gate ladder）。
2. **回前台重锁**：`paused`→`resumed` 完整重锁（不在 `inactive`）。
3. **任务切换器隐私遮罩**：`inactive` 时盖遮罩层，后台快照不泄露账目。
4. **生物识别优先 + 4 位 PIN 强制兜底**：进锁屏先自动尝试生物识别，失败/不可用一律回退 PIN；PIN 加盐慢哈希存既有 secure storage，常量时间比对，绝不明文。
5. **Setting 可开关**：关闭时锁逻辑完全 no-op；开启必须先设 4 位 PIN。落地点 = Phase 54 已备好的 Settings 安全区（D-13 深链）。

锁是「已解密 DB 之上的 UI gate」，**不参与派生/绑定 DB 加密密钥**（DB 加密由既有 4 层加密负责）。

**本 phase 只澄清「怎么实现已划定范围」。新能力（可配置宽限时间 = LOCK-V2-01；BIP39 恢复词重置 = LOCK-V2-02；失败擦库 = LOCK-V2-03）不在本 phase。**

> **最高风险标记**：keychain accessibility 砖机风险 / 应用生命周期 / 生物识别错误分类 / off-isolate KDF 调优——规划时做一次专项安全评审（`gsd-secure-phase` 或 `--research-phase`）。

</domain>

<decisions>
## Implementation Decisions

### 锁的启用模型与数据模型
- **D-01 (新增 `appLockEnabled` 主开关 + 锁内子开关):** 新增 `appLockEnabled` 主开关（默认 **false**）+ 锁内 `biometricUnlockEnabled` 子开关。**「锁生效」= `appLockEnabled && pinHash != null`**（无 PIN 绝不弹锁）。PIN 永远是基础凭证，生物识别是可选叠加（贴合 002/B：Face ID 页失败→切 PIN 页）。
- **D-02 (退役遗留 `biometricLockEnabled`):** 现有 `biometricLockEnabled`（默认 `true`、SharedPreferences 持久化、**启动时无人读、对锁行为无作用**）在新模型下退役/迁移为 off——绝不让它意外触发新锁。Phase 54 `onboarding_lock_entry_screen.dart` 现写 `setBiometricLock(false)` 的「跳过=锁关闭」语义须迁到新 `appLockEnabled=false`（planner 处理写穿点）。新字段与现有设置同构存 **SharedPreferences（明文 prefs，每字段一 key）**，**无 Drift 迁移，`schemaVersion` 保持 22**（见 [[settings-persisted-via-sharedprefs-not-drift]]）。

### PIN 设置 / 修改 / 再认证
- **D-03 (双输确认):** 设 PIN = 输入→再输一遍确认（防误设进自己都不知道的 PIN）。固定 4 位（LOCK-06）。
- **D-04 (Settings 有「修改 PIN」入口):** 安全区提供「修改 PIN」入口。
- **D-05 (关锁 + 改 PIN 均需再认证):** 关闭应用锁、修改 PIN 前都要求先用现有 PIN 或生物识别**再认证**——防别人拿到已解锁的手机偷偷关锁/改 PIN（符合财务 app 安全定位）。

### 连错防护（⚠ LOCK-08 显式降级）
- **D-06 (MVP 零速率限制 — 已知接受风险):** PIN 输错只 **抖动 + 清空、可立即重试**，**不做任何冷却/退避/失败计数**。这 **显式降级 LOCK-08**（「递增冷却/退避、持久化计数」要求）。
  - **决策前提（用户已被明确告知并仍主动选择）：** 4 位 PIN = 仅 10,000 组合；本 phase 无擦库（LOCK-V2-03 defer）、无恢复路径（LOCK-09）；因此失败冷却本是 4 位 PIN **唯一的暴力破解防线**，零冷却意味着持设备者可穷举全部组合。
  - **⚠ 下游必做动作：** ① 专项安全评审 **必须把此记为「已知接受风险」并显式签字**；② **REQUIREMENTS.md 的 LOCK-08 需改写/降级** —— 由本 phase 范围移出、并入 v2 App Lock 家族（建议新增 `LOCK-V2-04: PIN 连错递增冷却` 或并入 LOCK-V2-03 邻近项）；③ ROADMAP Phase 55 Success Criterion 4 中「连续输错有递增冷却」一句须随之标注 descoped。
  - 不变约束：**无擦库、成功无需清零（因为无计数）、无恢复路径**。
  - 因 D-06，「锁屏显示剩余次数/冷却倒计时」问题作废（无冷却→无可显示），锁屏错误仅抖动+清空（见 D-12）。

### 隐私遮罩 + 忘记 PIN
- **D-07 (不透明品牌封面 + 仅启用锁时):** `inactive` 时盖**跟随主题的不透明品牌封面（纯色/logo）**，**不用 blur**（blur 在某些快照时机仍可能透账目）；**仅在应用锁启用时**覆盖（未启用锁的用户已选择不要隐私门）。遮罩是全 app 统一项，非设计 tone 变体轴。
- **D-08 (忘记 PIN = 可点开的简短说明):** 锁屏放一个低调可点的「忘记 PIN?」文字，点开 = 一段简短说明（**忘记无法找回 / 需重装 app / 会丢失未同步的本地数据 / 不暗示任何恢复路径**，LOCK-09）。非纯静态长文案。

### 生物识别交互（Face ID 页 ↔ PIN 页）
- **D-09 (自动触发 + 失败停 Face ID 页):** 进锁屏 **自动触发 Face ID**（冷启动 + 每次回前台都自动尝试，LOCK-05「默认先自动尝试」）；失败/取消/不可用 → **停在 Face ID 页**，显示「重试」+ ghost 按钮「パスコードを使用」，用户点后切 PIN 页（贴合 002/B；不直接落 PIN 页，保留重试 Face ID 机会）。

### 设置衔接 + 安全区呈现
- **D-10 (深链即开始设 PIN):** Phase 54「现在设置」深链进来 → 滚动到安全区并**直接开始设 PIN 双输流程**（用户刚表达要设，一步到位）。复用 54-03 `scrollToSecurity` 机制。
- **D-11 (SecuritySection 重构):** 安全区重构为：**应用锁主开关** → 开启走设 PIN 流程 → 开启后展开子项「生物识别解锁」子开关 + 「修改 PIN」入口；现有 `notifications` 开关保留。

### PIN 输入反馈
- **D-12 (输满即校验 + 错误抖动清空):** 4 位输满 **即时校验解锁**（无确认键，标准 iOS 九宫格，002/B）；错误时 dots **抖动 + 清空 + 触觉反馈，不加文案**（tone B 极简）。

### Claude's Discretion（技术 / 专项安全评审 territory，非用户灰区）
- **KDF 方案与参数**：加盐慢哈希 ≥100k 迭代或 Argon2id，**跑主 isolate 外**（`compute`/`Isolate`）。`cryptography ^2.7.0` 已在 deps（提供 Argon2id + PBKDF2）——**无需新依赖**。常量时间比对；盐的生成与存储位置（与 `pinHash` 同区或单独 key）。**注：现有 `StorageKeys.pinHash` 注释为「SHA-256」属遗留，须升级为加盐慢哈希**（LOCK-07）。`accessibility` 保持 `unlocked_this_device` 不变（[[flutter-secure-storage-accessibility-read-filter]] / 260610-ss7 砖机坑）。专项安全评审定参数。
- **应用生命周期 wiring**：根 `WidgetsBindingObserver`，`paused→resumed` 重锁、`inactive` 盖遮罩；与既有 `lib/infrastructure/sync/sync_lifecycle_observer.dart` 模式对齐。立即重锁（宽限 = LOCK-V2-01 defer）。注意 iOS 控制中心/通知中心是 `inactive`（仅盖遮罩、不重锁），真正切走才 `paused→resumed`（重锁）。
- **`local_auth` 完整错误分类映射**：notAvailable / notEnrolled / lockedOut / permanentlyLockedOut / passcodeNotSet / cancel **一律回退 PIN**（LOCK-10）。现有 `BiometricService._handlePlatformException` 把 `LockedOut`/`PermanentlyLockedOut`→`lockedOut()`（非 fallbackToPIN）、`passcodeNotSet`/`cancel` 落 default→`error`——需扩展使 **UI 层对每个分类都落到 PIN 页**，绝不锁死用户。
- **锁屏 boot-gate 排位**：在 `_buildHome()` gate ladder 的位置（错误→spinner→onboarding→**应用锁**→`MainShellScreen`），及回前台覆盖机制。遵 [[boot-gate-completion-must-flip-flag-not-pushreplacement]]：解锁完成经 gate-owned 回调 + `setState` 翻 flag，**不要 root `pushReplacement`**。锁是 boot-time 分支 widget，非路由（不引 go_router）。
- 新增锁屏/设置 ARB key 命名与组织（三语 ja/zh/en 齐全，过 parity + 硬编码 CJK 扫描）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求台账 + 路线图（最重要 — LOCK-08 descope 见 D-06）
- `.planning/REQUIREMENTS.md` — LOCK-01..10（第 ~30–40 行）+ App Lock v2（LOCK-V2-01/02/03）+ Out of Scope（改 accessibility / PIN 绑 DB 密钥 / 账号体系 均显式排除）+ 追踪表。**LOCK-08 需按 D-06 改写/降级。**
- `.planning/ROADMAP.md` §Phase 55 — Goal + 5 条 Success Criteria（SC-4 含「递增冷却」一句需随 D-06 标注 descoped）。

### Phase 53 设计批准 + 下游交接
- `.planning/phases/53-html/53-02-app-lock-qa.md` — DESIGN-02 逐元素核对 + **Phase 55 继承的全部锁定约束**（系统原生跟随主题 / 两独立 surface / 生物识别优先+PIN 兜底 / 锁=UI gate 不绑 DB 密钥 / 加盐慢哈希 / 遮罩统一）。
- `.planning/phases/53-html/53-04-downstream-handoff.md` — Phase 53→55 交接。
- `.planning/sketches/002-app-lock/index.html` + `README.md` — **批准的设计稿 tone B「清爽极简」★**（Face ID 页 + PIN 页两独立 surface、浅/深两套；`B · 清爽极简 ★ 选定` 区块）。

### Phase 54 继承（锁入口已就位）
- `.planning/phases/54-onboarding-flow/54-CONTEXT.md` — D-13（引导末尾「设置应用锁」入口：跳过=`setBiometricLock(false)`、「现在设置」=深链 Settings 安全区）；设置项实为明文 SharedPreferences（无 Drift 迁移）。

### 既有安全基础设施（实现锚点 — 复用，勿重写）
- `lib/infrastructure/security/biometric_service.dart` — `BiometricService`（可用性检测 + `authenticate` + 失败计数 + 错误分类）。**错误分类需按 LOCK-10 扩展（见 Discretion）。**
- `lib/infrastructure/security/models/auth_result.dart` — `AuthResult` sealed union（success/failed/fallbackToPIN/tooManyAttempts/lockedOut/error）。
- `lib/infrastructure/security/secure_storage_service.dart` — `StorageKeys.pinHash` + `getPinHash`/`setPinHash`/`deletePinHash`；`accessibility = unlocked_this_device`（**绝不改**）。`pinHash` 注释「SHA-256」属遗留待升级。
- `lib/infrastructure/security/providers.dart` — `biometricServiceProvider` / `biometricAvailabilityProvider`。
- `lib/features/settings/presentation/widgets/security_section.dart` — 现 `biometricLock` + `notifications` 两 SwitchListTile；**按 D-11 重构**。
- `lib/features/settings/domain/models/app_settings.dart` + `lib/data/repositories/settings_repository_impl.dart` — `AppSettings`（`biometricLockEnabled` 默认 true）+ SharedPreferences 持久化；新增 `appLockEnabled`/`biometricUnlockEnabled` 走此模式。
- `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart` — Phase 54 锁入口（现写 `setBiometricLock(false)`，须迁 D-02）。
- `lib/main.dart` — `_buildHome()` gate ladder（锁 gate 插入点）+ 需新增根生命周期 observer。
- `lib/infrastructure/sync/sync_lifecycle_observer.dart` — 既有 `WidgetsBindingObserver` 生命周期模式参考。

### 安全架构
- `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` — 4 层加密 / 密钥管理；锁是其上的 UI gate，不改威胁模型。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BiometricService` + `AuthResult` union + `biometricAvailabilityProvider` — 生物识别认证全套已存在，复用（错误分类按 LOCK-10 扩展，不重写）。
- `SecureStorageService.getPinHash`/`setPinHash`/`deletePinHash` + `StorageKeys.pinHash` — PIN 读写槽位已存在；只需把哈希算法从遗留 SHA-256 升级为加盐慢哈希。
- `cryptography: ^2.7.0`（已在 pubspec）— 提供 Argon2id + PBKDF2，KDF 无需新依赖。
- `security_section.dart` + 54-03 `scrollToSecurity` 深链机制 + `onboarding_lock_entry_screen.dart` — 设置承载 + 引导衔接已就位（D-10/D-11/D-13）。
- `sync_lifecycle_observer.dart` — 根生命周期 observer 范式可仿。

### Established Patterns
- **Gate ladder**：`_buildHome()` 内以 `if` 分支顺序判定（init settle 后），锁 gate 排在 onboarding gate 之后、`MainShellScreen` 之前。遵 [[boot-gate-completion-must-flip-flag-not-pushreplacement]]（gate-owned 完成回调，非 root `pushReplacement`）。
- **设置持久化**：`AppSettings` 经 SharedPreferences（每字段一 key，明文），新字段同构、`@freezed copyWith`、build_runner 重生、无 Drift 迁移、`schemaVersion` 保持 22。
- **Riverpod 3 约定**（见 CLAUDE.md）：provider 名去 `Notifier` 后缀、`AsyncValue.value` 可空、side-effect 用 `ref.listen`。
- **secure storage `accessibility` 永不改**（`unlocked_this_device`），否则砖机现有安装。

### Integration Points
- `lib/main.dart` `_buildHome()` gate ladder — 锁 gate 判定点 + 根 `WidgetsBindingObserver`（`paused→resumed` 重锁、`inactive` 遮罩）。
- `AppSettings` schema — 新增 `appLockEnabled`/`biometricUnlockEnabled`（SharedPreferences，无迁移）。
- `StorageKeys.pinHash`（+ 可能的盐 key）— PIN 加盐慢哈希落点。
- Settings 安全区 `security_section.dart` — 主开关 + 子项重构 + 深链落点。

</code_context>

<specifics>
## Specific Ideas

- 设计基线 = sketch 002 tone **B「清爽极简」**：Face ID 页 + PIN 页**两个独立 surface**（非混排）、系统原生跟随主题、浅/深两套。CJK 串证据：`Face ID を見つめてください`、`パスコードを入力`、`パスコードを使用`、`PASSCODE`/`FACE ID` 徽标。
- PIN 页 = 标准九宫格（1–9 / 0 / ⌫）+ 4 点 `pin-dots` 指示器，输满即校验。
- Face ID 页 → PIN 页逃逸 = ghost 文字「パスコードを使用」（tone B 选定的 affordance，非 tone C 的重试计数）。
- 锁屏措辞中性、不暗示恢复路径；忘记 PIN 说明明告「需重装、丢未同步本地数据」。

</specifics>

<deferred>
## Deferred Ideas

- **LOCK-08 递增冷却/退避** — 本 phase 经 D-06 **显式 descoped**（MVP 零速率限制，已知接受风险）→ 移入 v2 App Lock 家族（建议新增 `LOCK-V2-04` 或并入 LOCK-V2-03 邻近项）。REQUIREMENTS.md + ROADMAP SC-4 须随之标注。
- **LOCK-V2-01** 可配置重锁宽限时间（immediate / 1min / 5min；v2.0 先发固定立即）— 已在 REQUIREMENTS v2。
- **LOCK-V2-02** 忘记 PIN 经 BIP39 恢复词重置（v2.0 选「无恢复」）— 已在 REQUIREMENTS v2。
- **LOCK-V2-03** 可选「连续 N 次失败后擦除本地数据」（默认关）— 已在 REQUIREMENTS v2。
- **Settings 法务/赞助/日本合规** — Phase 56。

讨论始终在 phase scope 内；唯一范围变动是 D-06 对 LOCK-08 的主动降级（用户知情决策），已在上方显式记录待下游台账修正。

</deferred>

---

*Phase: 55-pin-phase*
*Context gathered: 2026-06-30*
