# 53-04 — 下游实现交接（Design → Implementation Handoff）

**Phase:** 53-html（HTML 设计关卡 · 零生产代码）
**Plan:** 53-04（Wave 2 · 关卡出口）
**写于:** 2026-06-29
**性质:** 设计→实现交接。三块设计稿已经用户批准（见 `53-04-design-gate-approval.md`），本文件按已批准的设计面，记录 Phase 54 / 55 / 56 各自继承的关键约束。约束源自 Wave-1 三份批准就绪 QA 的「下游继承」节 + ROADMAP success criteria + REQUIREMENTS。**无生产代码。**

---

## Phase 54 — Onboarding（DESIGN-01 → ONBOARD-01..07）

**已批准设计:** sketch 001 · tone A 温柔抛茶感（两步首启：①整体介绍 → ②基础设置，只显默认值 + 変更 picker 弹窗 + 可后改提示）。

**继承约束:**

- **两步首启**：①整体介绍（隐私 / 端末内暗号化 / 本地优先 / 双账本 / 语音卖点，介绍部分可跳过 — ONBOARD-02）→ ②基础设置（只显默认值，按需 変更 bottom-sheet，非一次性填表）。确认按钮 `この設定で始める`。
- **gate 判定时机**：在 `AppInitializer` settle 之后、主 shell 之前判定（`lib/main.dart` `HomePocketApp._buildHome()` branch 3），**绝不与 init 竞态**（ONBOARD-07）。
- **写穿既有 provider，绝不新建数据轴**：
  - UI 语言 → 写入既有 `localeProvider`，确认后 MaterialApp **即时切换**（ONBOARD-03）。
  - 记账币种 → 写入既有 `Book.currency`，**复用 v1.7 货币选择器**，默认 JPY（ONBOARD-04）。
  - 语音输入语言 → 写入既有语音 locale 设置，默认 = 所选 UI 语言（ONBOARD-05）。
- **`onboarding_complete` 一次性落最后**：仅在用户**显式完成**引导时落，**绝不从 `currency≠null` 反推**；幂等 —— 完成后再次启动直接进主 shell、引导不再出现（ONBOARD-01）。
- **可返回 + 进度 + re-entrant**：引导可返回上一步、显示进度、无法卡死（ONBOARD-06/07）。
- **末尾可跳过的应用锁入口**：引导末尾提供可**明确跳过**的「设置应用锁」入口；跳过后锁保持关闭（衔接 Phase 55，ONBOARD-06）。
- **三语 ARB**：新增引导文案 ja/zh/en 齐全，过 ARB parity + 硬编码 CJK 扫描（实现期约束）。

**依赖关系:** Phase 54 是里程碑首个实现 phase（依赖 Phase 53 设计批准）；Phase 55 依赖 Phase 54（锁入口需先存在），Phase 56 依赖 Phase 54（Setting 承载面）。

---

## Phase 55 — App Lock（DESIGN-02 → LOCK-01..10）

**已批准设计:** sketch 002 · tone B 清爽极简（系统原生、跟随主题；两个独立 surface：Face ID 页 + PIN 页；浅色 + 深色各一组）。

**继承约束:**

- **系统原生、跟随主题**：锁屏浅 / 深两套与系统主题一致，**不引入独立配色轴**（深色遵 ADR-019「桜餅×若葉」`#171210` 家族，primary 若叶绿 `#8DC68D`）。
- **两个独立 surface**：Face ID 页 + PIN 页分离，按设置选择，不混排（仅 Face ID 或 Face ID + PIN → Face ID 页；仅 PIN → 直接 PIN 页；两者都开 → Face ID 优先）。
- **生物识别优先 + PIN 强制兜底**：默认先自动尝试 Face ID/指纹，失败 / 不可用必有 4 位 PIN 逃逸（逃逸 affordance `パスコードを使用`）；启用锁必须先设 PIN（LOCK-05/06）。
- **锁是「已解密 DB 之上的 UI gate」**：它 **不**参与派生 / 绑定 DB 密钥（明确 out of scope per REQUIREMENTS）—— 仅是进入主 shell 前的界面闸门；DB 加密由既有 4 层加密负责。
- **PIN 加盐慢哈希**：4 位 PIN 以 KDF（≥100k 迭代或 Argon2id，跑主 isolate 外）存入既有 secure storage（`StorageKeys.pinHash`，**keychain accessibility 保持 `unlocked_this_device` 不变** —— 改 accessibility 会砖机既有安装，见 MEMORY flutter-secure-storage 教训）；常量时间比对，绝不明文；连续输错递增冷却（持久化计数，成功才清零），无默认数据擦除（LOCK-07/08）。
- **完整 `local_auth` 错误分类一律回退 PIN**：notAvailable / notEnrolled / lockedOut / permanentlyLockedOut / passcodeNotSet / cancel → 全部回退 PIN，**绝不把用户锁在自己数据外**（LOCK-05/10）。
- **生命周期重锁 + 隐私遮罩**：冷启动 + 回前台（`paused`→`resumed`）完整重锁；任务切换器 / 后台快照在 `inactive` 盖统一隐私遮罩层（遮罩是全 app 统一项，**不是 tone 变体轴**）（LOCK-02/03/04）。
- **不可恢复文案**：锁屏文案明确告知忘记 PIN 无法找回（需重装且丢失未同步本地数据），不暗示存在恢复路径；三语 ARB 齐全过 parity + 硬编码 CJK 扫描（LOCK-09）。
- **独立安全评审**：Phase 55 是里程碑**最高风险**整合，**自带独立安全评审**（ROADMAP Research flag —— keychain accessibility 砖机风险 / 应用生命周期 / 生物识别错误分类 / off-isolate KDF 调优）；最高风险的安全工作落在彼处，而非本设计关卡。

**依赖关系:** 依赖 Phase 54（引导末尾「设置应用锁」入口需先存在）；与 Phase 56 相互独立。

---

## Phase 56 — Settings 法务·赞助（DESIGN-03 → DONATE-01..04 + LEGAL-01..06）

**已批准设计:** sketch 003 · tone C 混合（完整 Settings 页；既有分区按序保留并精简合并；`一般` + 单组 `法的情報・応援`；应用锁展开替换孤立生物识别开关）。

**继承约束:**

- **复用既有 Settings 分区并按 winner C 精简合并**：`一般` = 外観 + 音声認識 + 悦己目標 合并为一组；`法的情報・応援` = 四条法务 + 一条外链赞助合并为一组；其余既有分区（家族共有 / データ管理 / アプリについて）按序保留；**不新增独立配色轴**。
- **应用锁展开替换孤立生物识别开关**：`セキュリティ & プライバシー` 内 master `アプリロック` → 展开 `Face ID / 指紋` + `PIN コード` 子行 + 「Face ID が優先」优先注记（与 Phase 55 锁屏设计对齐）。
- **法务页三语离线 + 托管 URL 占位**：プライバシーポリシー（LEGAL-01）/ 利用規約（LEGAL-02）app 内置 ja/zh/en 文本**离线可读** + App Store Connect 强制托管 URL 占位（上线前填）。
- **OSS 经 Flutter 内置 `showLicensePage` / `LicenseRegistry` 自动聚合**（LEGAL-03），**不手维护清单**。
- **特商法表記参考 napu.co.jp/sale 结构**（LEGAL-04 —— 运营者 / 所在地 / 联系方式 / 退款等条目，可遵「请求时提供」型），三语承载，上线前由日本法务确认细节。
- **外链赞助经 `url_launcher` `LaunchMode.externalApplication` 打开外部浏览器**（DONATE-02），到日本赞助平台（FANBOX / OFUSE 等）；**绝不内嵌 WebView、绝不 IAP**；URL 可配置占位（DONATE-04）；中性非交易性措辞、完全可选、不强制付费、不做功能门槛、不反复弹窗（DONATE-01/03）。`url_launcher` 是本里程碑**唯一新运行时依赖**，在 Phase 56 添加（非本关卡）。
- **商店隐私表单如实填写**（LEGAL-05，与 v1.7 汇率出站网络调用一致，非反射式「不收集」）；新增法务 / 合规 / 赞助文案三语覆盖并通过 ARB parity + 硬编码 CJK 扫描（长文本用 bundled per-locale assets 时附「三语齐全」存在性门，LEGAL-06）。
- **外部合规评审余量**：Phase 56 是**上线关卡**，特商法 applicability（个人开发者外部平台赞助）+ Apple/Google donation-review 立场需 JP-legal sign-off + 真实 TestFlight / internal-track 提交（非自评）；调度时为 store-review round-trip 留余量（ROADMAP Research flag）。

**依赖关系:** 依赖 Phase 54（Setting 承载面）；与 Phase 55 相互独立、可并行；排在最后但尽早调度外部评审。

---

## Gate-exit（DESIGN-04）

本设计关卡（Phase 53）产物仅 `.md` / `.html`，全部位于 `.planning/` 下；`git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` 为**空**（无任何 `.dart` / `pubspec` / `lib/` / `test/` / ARB 改动），DESIGN-04 硬关卡满足。

**零生产代码前置约束:** 在本设计关卡获批前（已于 2026-06-29 获批，见 `53-04-design-gate-approval.md`），**不得**为 Phase 54 / 55 / 56 的任何 surface 写生产 Dart —— DESIGN-04 precedence 先于 Phases 54-56（沿用 v1.8 Phase 43 设计关卡 precedent）。三块设计稿现已批准，下游实现可按本交接约束开工；实现期产出的任何 Dart / ARB / test 属于 Phases 54/55/56，**不属于** Phase 53。
