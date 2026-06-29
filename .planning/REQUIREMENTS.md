# Requirements: Home Pocket — v2.0 完成第一版上线前最后的功能开发

**Defined:** 2026-06-28
**Core Value:** 用户敢把敏感财务数据托付的家庭记账 app —— 本地优先、端到端加密、日常/悦己双账本让家庭能坦诚谈钱。本里程碑补齐首次公开上线（面向日本市场）所需的欢迎引导、应用锁与合规三块「上线必备」能力。

## v1 Requirements

本里程碑（v2.0）提交范围。每条映射到一个 roadmap phase。新文案一律三语（ja/zh/en）ARB 覆盖、过 parity + 硬编码CJK扫描（各 phase 的 success criteria 承载）。

### Design Gate（设计关卡 — 零生产代码，先于实现）

> 硬约束（用户要求）：先用 Claude design 出 HTML 设计稿，**经用户确认后才进入对应生产代码**。沿用 v1.8 Phase 43 precedent。

- [x] **DESIGN-01**: 欢迎/首启引导流程的 HTML 设计稿产出并经用户确认（含 app 介绍 + UI语言/币种/语音语言三步设置）
- [x] **DESIGN-02**: 应用锁屏（生物识别提示 + PIN 输入）的 HTML 设计稿产出并经用户确认
- [ ] **DESIGN-03**: Setting 法务/赞助区块布局的 HTML 设计稿产出并经用户确认
- [ ] **DESIGN-04**: 设计关卡未获批前不写对应生产 Dart 代码（关卡产物仅 `.planning/` 下 HTML/Markdown）

### Onboarding（欢迎 / 首启引导）

- [ ] **ONBOARD-01**: 仅首次启动展示欢迎/引导流程，完成后不再出现（幂等；`onboarding_complete` 在显式完成时一次性落最后，绝不从「currency≠null」反推）
- [ ] **ONBOARD-02**: 引导内提供 app 整体介绍（隐私 / 本地优先 / 双账本卖点），介绍部分可跳过
- [ ] **ONBOARD-03**: 用户确认 UI 语言（设备语言预选）→ 写入既有 `localeProvider`，MaterialApp 即时生效
- [ ] **ONBOARD-04**: 用户确认记账币种（JPY 默认）→ 写入既有 `Book.currency`（复用 v1.7 货币选择器）
- [ ] **ONBOARD-05**: 用户确认语音输入语言（默认 = 所选 UI 语言）→ 写入既有语音 locale 设置
- [ ] **ONBOARD-06**: 引导末尾提供「设置应用锁」入口，可明确跳过（skip 后锁保持关闭）
- [ ] **ONBOARD-07**: 引导支持返回上一步 + 进度提示，且无法卡死（re-entrant）；gate 在 `AppInitializer` settle 之后判定，绝不与 init 竞态

### App Lock（应用锁 — 生物识别 + PIN）

- [ ] **LOCK-01**: 用户可在 Setting 开启/关闭应用锁（关闭时锁逻辑完全 no-op）
- [ ] **LOCK-02**: 启用后 app 冷启动需通过生物识别或 PIN 解锁后才进入主 shell
- [ ] **LOCK-03**: 启用后 app 从后台回前台需重新解锁（完整重锁；在 `paused`→`resumed` 触发，不在 `inactive`）
- [ ] **LOCK-04**: 任务切换器/后台快照显示隐私遮罩，不泄露账目内容（`inactive` 时盖遮罩层）
- [ ] **LOCK-05**: 解锁默认先自动尝试生物识别（Face ID/指纹），失败或不可用回退到 PIN
- [ ] **LOCK-06**: PIN 为 4 位，作为强制兜底凭据（启用锁必须先设 PIN）
- [ ] **LOCK-07**: PIN 以加盐慢哈希（KDF，≥100k 迭代或 Argon2id，跑在主 isolate 外）存入既有 secure storage（`StorageKeys.pinHash`，**accessibility 保持 unlocked_this_device 不变**），常量时间比对，绝不明文
- [ ] **LOCK-08**: PIN 连续输错有递增冷却/退避（持久化计数，成功才清零），无默认数据擦除
- [ ] **LOCK-09**: 锁屏文案明确告知「忘记 PIN 无法找回、需重装 app 且丢失未同步本地数据」，不暗示存在恢复路径
- [ ] **LOCK-10**: 处理 `local_auth` 完整错误分类（notAvailable/notEnrolled/lockedOut/permanentlyLockedOut/passcodeNotSet/cancel）→ 一律回退 PIN，不把用户锁在自己数据外

### Donation（赞助入口）

- [ ] **DONATE-01**: Setting 内提供一个不打扰的「応援/支援（赞助）」入口
- [ ] **DONATE-02**: 点击经外部浏览器（`url_launcher` `LaunchMode.externalApplication`）打开日本赞助平台（FANBOX/OFUSE 等）链接，绝不内嵌 WebView、绝不 IAP
- [ ] **DONATE-03**: 赞助完全可选 —— 不强制付费、不做功能门槛、不反复弹窗，中性非交易性措辞
- [ ] **DONATE-04**: 赞助链接 URL 可配置（需求阶段留占位，上线前填真实链接）

### Legal & Compliance（合规 / 法务 — 日本市场）

- [ ] **LEGAL-01**: Setting 内提供隐私政策（プライバシーポリシー）页 —— app 内置三语文本（离线可读）+ 托管 URL 占位（App Store Connect 强制要求托管 URL，上线前填）
- [ ] **LEGAL-02**: Setting 内提供利用規約（Terms of Use）页 —— app 内置三语文本 + 托管 URL 占位
- [ ] **LEGAL-03**: Setting 内提供 OSS 开源许可证页，用 Flutter 内置 `showLicensePage`/`LicenseRegistry` 自动聚合（不手维护清单）
- [ ] **LEGAL-04**: Setting 内提供「特定商取引法に基づく表記」页 —— 运营者信息内容**参考 https://www.napu.co.jp/sale/ 的表記结构**（运营者/所在地/联系方式/退款等条目，可遵「请求时提供」型），三语承载，上线前由日本法务确认细节
- [ ] **LEGAL-05**: 商店隐私表单（Apple Privacy Nutrition Labels / Google Data Safety）如实填写，与 v1.7 汇率出站网络调用一致（非反射式「不收集」）
- [ ] **LEGAL-06**: 所有新增法务/合规文案三语（ja/zh/en）覆盖，通过 ARB parity + 硬编码CJK扫描（长文本用 bundled per-locale assets 时附「三语齐全」存在性门）

## v2 Requirements

承认但本里程碑不做，未来版本跟进。

### App Lock v2

- **LOCK-V2-01**: 可配置重锁宽限时间（immediate / 1min / 5min；v2.0 先发固定默认）
- **LOCK-V2-02**: 忘记 PIN 经 BIP39 恢复词重置（v2.0 选了「无恢复」，未来可加）
- **LOCK-V2-03**: 可选「连续 N 次失败后擦除本地数据」（默认关）

### Onboarding / Legal v2

- **ONBOARD-V2-01**: 更丰富的介绍轮播 / 引导内权限预说明
- **LEGAL-V2-01**: 若日本法务判定需要，扩充完整特商法表記（运营者全表記）

## Out of Scope

显式排除，防止范围蔓延。

| Feature | Reason |
|---------|--------|
| IAP / 订阅 / 强制付费 | app 永久免费，仅外链赞助（用户明确要求） |
| 应用内 WebView 打开赞助/法务链接 | 审核风险 + 隐私泄露；统一用外部浏览器 |
| 引入 go_router | gate 是 boot-time 分支 widget 非路由；项目无 go_router，不改导航栈 |
| 改 `flutter_secure_storage` accessibility | 10.x 会读过滤砖机现有安装（项目已知坑 260610-ss7），永不改 |
| PIN 派生/绑定 DB 加密密钥 | 本里程碑锁是「已解密 DB 之上的 UI gate」；改威胁模型超范围 |
| 账号 / 邮箱 / 云登录 | 本地优先零知识架构，不引入账号体系 |
| 手维护 OSS license 清单 | 用 Flutter 内置 `showLicensePage` 自动聚合 |
| 新增付费 SDK / sqlite3_flutter_libs / flutter_markdown | 分别违反免费定位 / SQLCipher 冲突 / 已停维护 |

## Traceability

> 每条 requirement 恰好映射一个 phase（roadmapper 于 2026-06-28 创建 ROADMAP 时填充）。

| Requirement | Phase | Status |
|-------------|-------|--------|
| DESIGN-01 | Phase 53 | Complete |
| DESIGN-02 | Phase 53 | Complete |
| DESIGN-03 | Phase 53 | Pending |
| DESIGN-04 | Phase 53 | Pending |
| ONBOARD-01 | Phase 54 | Pending |
| ONBOARD-02 | Phase 54 | Pending |
| ONBOARD-03 | Phase 54 | Pending |
| ONBOARD-04 | Phase 54 | Pending |
| ONBOARD-05 | Phase 54 | Pending |
| ONBOARD-06 | Phase 54 | Pending |
| ONBOARD-07 | Phase 54 | Pending |
| LOCK-01 | Phase 55 | Pending |
| LOCK-02 | Phase 55 | Pending |
| LOCK-03 | Phase 55 | Pending |
| LOCK-04 | Phase 55 | Pending |
| LOCK-05 | Phase 55 | Pending |
| LOCK-06 | Phase 55 | Pending |
| LOCK-07 | Phase 55 | Pending |
| LOCK-08 | Phase 55 | Pending |
| LOCK-09 | Phase 55 | Pending |
| LOCK-10 | Phase 55 | Pending |
| DONATE-01 | Phase 56 | Pending |
| DONATE-02 | Phase 56 | Pending |
| DONATE-03 | Phase 56 | Pending |
| DONATE-04 | Phase 56 | Pending |
| LEGAL-01 | Phase 56 | Pending |
| LEGAL-02 | Phase 56 | Pending |
| LEGAL-03 | Phase 56 | Pending |
| LEGAL-04 | Phase 56 | Pending |
| LEGAL-05 | Phase 56 | Pending |
| LEGAL-06 | Phase 56 | Pending |

**Coverage:**

- v1 requirements: 31 total (DESIGN 4 · ONBOARD 7 · LOCK 10 · DONATE 4 · LEGAL 6)
- Mapped to phases: 31 (Phase 53: 4 · Phase 54: 7 · Phase 55: 10 · Phase 56: 10)
- Unmapped: 0 ✓ (100% coverage, no orphans, no duplicates)

---
*Requirements defined: 2026-06-28*
*Last updated: 2026-06-28 — traceability filled by roadmapper (4 phases 53-56, 31/31 mapped)*
