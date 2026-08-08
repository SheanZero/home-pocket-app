# Requirements: Happy Pocket — v2.1 依赖与原生工具链现代化

**Defined:** 2026-08-05
**Core Value:** 用户敢把敏感财务数据托付给 Happy Pocket；依赖与原生工具链升级必须在不降低本地加密、数据可恢复性和现有产品行为的前提下完成。

## v1 Requirements

本里程碑提交范围。这里的“最新”指执行时经官方一手来源确认、且与完整安全/构建/测试组合相容的最新生产稳定窗口；有证据的安全保留是合格结果，beta/RC/EOL、强制 override 或明文回退不是。

### Baseline & Version Decision（基线与版本决策）

- [x] **BASE-01**: 执行升级前重新查询官方来源，记录 Flutter/Dart、Xcode、CocoaPods、JDK、Gradle、AGP、Android SDK 及所有直接依赖的当前版本、最新 production-stable 候选和查询日期
- [x] **BASE-02**: 最终 `pubspec.yaml`、`pubspec.lock`、Gradle wrapper/project、Podfile/Podfile.lock、SwiftPM/Xcode 配置与一份可审计版本决策清单一致，干净 checkout 可重复解析
- [x] **BASE-03**: `docs/testing/DEPENDENCY_COMPATIBILITY.md`、`scripts/dependency_compatibility.dart` 及其正/负合同测试与最终组合同步，自动拒绝被禁止或只升级一半的依赖 lane
- [x] **BASE-04**: 每个未采用表面最新版本的项目都有官方证据、兼容性理由和解除条件；最终基线不含 beta/RC/dev、EOL 空壳、未批准 `dependency_overrides`，且保持 iOS 15 / Android API 24 最低支持

### Flutter, Analyzer & Code Generation（SDK、分析器与代码生成）

- [ ] **GEN-01**: 选择并固定 Flutter 3.44.8 / Dart 3.12.2 的 Stable 身份，Dart SDK 约束、CI 与开发命令使用同一版本；2026-08-08 官方复核的 Flutter 3.44.9 作为待完整身份事务验证的 hold（58-02 已完成本地契约，58-04 尚需将权威 wrapper 接入 Stable CI）
- [ ] **GEN-02**: 以 analyzer 12.1.0、import_lint 2.0.0 与 active riverpod_lint 3.1.4 安全替代旧 analyzer-8/custom_lint 提案；Clean Architecture import guard、Riverpod lint 和仓库自有守卫持续启用并有负向测试（58-02 已完成本地契约，58-04 尚需接入 Stable CI）
- [ ] **GEN-03**: analyzer/build_runner、Riverpod runtime/annotation/generator/lint、Freezed、JSON、Drift generator 作为一个兼容 lane 解析到最新可安全稳定组合，禁止以 override、禁用 lint 或拆分 runtime/annotation/generator 版本来强推升级（58-02 已完成本地契约，58-04 尚需权威 Stable CI wrapper）
- [x] **GEN-04**: 在干净生成状态执行 `flutter pub get`、`flutter gen-l10n`、build_runner 后无非预期生成差异，所有跟踪生成物均由选定工具链重建且未手工编辑

### Platform Plugin Cohorts（平台插件组）

- [ ] **PLUG-01**: 所有直接依赖及重要原生/传递依赖均逐项升级到最新可安全 production-stable，或以 BASE-04 规则形成有证据的 hold；不得用一次 blanket major upgrade 代替逐 lane 验证
- [ ] **PLUG-02**: `file_picker`、`share_plus`、`package_info_plus`、`win32` 作为一个原子兼容组保留或升级，且 `.hpb` 文件选择、导入及系统分享流程在受支持平台上保持可用
- [ ] **PLUG-03**: `speech_to_text` 仅在 7.4.0（或执行时更新 stable）通过 ja/zh/en 解析、权限、取消/错误与 iPhone 语音输入验证后升级，否则记录并保留 7.3.0
- [ ] **PLUG-04**: Firebase Core/Messaging、通知、biometric、secure storage 等原生插件完成 stable 状态核对和编译/初始化回归；升级不得重新显示首版已隐藏的通知设置入口，也不得改变已披露的云端回退策略

### Encrypted Storage & iOS Native Lane（加密存储与 iOS 原生链）

- [ ] **SEC-01**: 保留已验证的 `sqlcipher_flutter_libs 0.6.8 + sqlite3 2.9.4 + SQLCipher Pod 4.10.0`，除非另有 ADR 和等价真机证据；自动禁止 `0.7.0+eol`、`sqlite3_flutter_libs` 与 system/plain SQLite 回退
- [ ] **SEC-02**: iOS 从干净 native artifact 状态用 SwiftPM + 仅 SQLCipher CocoaPods 例外重新解析，保留 Podfile 的 `-lsqlite3` 移除保护，并完成 simulator/device 与 debug/profile/release 相关构建验证
- [ ] **SEC-03**: 原生加密执行路径在首次打开及 close/reopen 后都返回非空 `PRAGMA cipher_version`，且加密库中持久化的 sentinel 数据保持可读
- [ ] **SEC-04**: 前一已发布 schema 的加密 fixture 经真实 `onUpgrade` 路径迁移到当前 schema，历史迁移测试继续通过并验证 user_version、关键表/索引/default 与代表性数据
- [ ] **SEC-05**: 当前及受支持旧格式的 `.hpb` 加密备份可完成 export → 仅测试数据 clear → password restore，wrong-password、截断与资源上限失败均不破坏现有数据
- [ ] **SEC-06**: `ensureNativeLibrary()` 与 AppInitializer 的密钥先于数据库顺序保持不变；已有加密 DB 缺失 master key 时继续 fail closed，依赖升级本身不触发无业务理由的 Drift schema bump

### Android Toolchain & Emulator（Android 工具链与模拟器）

- [ ] **AND-01**: 重新确认并尝试完整的 production-stable Android 候选组合（2026-08-05 候选为 AGP 9.0.1、Gradle 9.1、JDK 17、API 36），同时保持 minSdk 24
- [ ] **AND-02**: 若最终采用 AGP 9，则 built-in Kotlin/new DSL、旧 KGP 移除和 Flutter 临时 opt-out flags 清理必须一次完成并覆盖所有插件；若插件链不兼容则整体回退到最后绿色 AGP 8 组合并记录 blocker
- [ ] **AND-03**: 最终 Android 组合生成非 debug signing 的 release AAB/APK，签名合同继续拒绝缺失或 debug 凭据，release artifact 不含测试专用 registrar/plugin
- [ ] **AND-04**: 在受支持 Android Emulator 上完成关键 integration tests；最终报告明确写明未执行、也不宣称 Android 真机验收

### Automated Quality & Release Gates（自动化质量与发布门禁）

- [ ] **QA-01**: 最终组合通过 `flutter analyze`、custom lint/import guard、架构/隐私/依赖合同和 `git diff --check`，结果为 0 issue 且无新增无依据的 ignore
- [ ] **QA-02**: 目标测试、完整 `flutter test`、覆盖率门禁及必要的单并发复跑全部通过；任何因升级修改的行为先有回归测试再修复
- [ ] **QA-03**: release preflight 从干净状态重新生成 native registrants，证明生产 Runner 不包含 `integration_test` 等开发插件；CI 固定同一 Flutter stable、lockfile 与生成步骤
- [ ] **QA-04**: iPhone Simulator 与 Android Emulator 作为真机前置门禁通过，最终兼容性报告记录命令、环境、commit、版本差异、intentional holds、失败/修复与残余债务

### Wired iPhone Acceptance（有线 iPhone 真机验收）

- [ ] **DEVICE-01**: 建立 additive 的 UAT scheme/config，使用与生产 App 不同的显式 Bundle ID/App ID、container、Keychain access group、entitlements、Firebase/通知配置与测试密钥，并以自动化合同证明身份隔离
- [ ] **DEVICE-02**: UAT 安装/删除/清数据只作用于隔离 App 和 synthetic data；手机中既有生产 App、数据库、Keychain 与备份保持不变，日志/报告不记录 UDID、PIN、密钥、token、金额、备注或同步 payload
- [ ] **DEVICE-03**: 在当前一台有线 `“Xin Zhang”的 iPhone` 上安装与最终 lockfile/commit 对应的签名 profile 或 release-compatible build，记录设备型号、iOS、Xcode、Flutter、构建模式与安装/冷启动结果
- [ ] **DEVICE-04**: 真机完成 SQLCipher cipher_version、close/reopen、前一 release schema migration 和加密 backup clear/restore 关键旅程，恢复后 sentinel 数据与 schema 不变量完全一致
- [ ] **DEVICE-05**: 真机完成首次引导/测试初始化、日常与悦己手动记账、冷重启后持久化，以及 App Lock 的 PIN、Face ID（设备可用时）、取消/不可用回退和前后台重锁验证
- [ ] **DEVICE-06**: 真机完成不暴露 payload 的同步队列/E2EE smoke；如测试环境缺少 relay/APNs/FCM 凭据，必须把该项标为明确限制或阻断，不得把“不可测试”记录为通过
- [ ] **DEVICE-07**: 真机采集带原始元数据的 profile/release 性能证据，覆盖独立冷启动/首个可交互时刻和既有交互 benchmark；相对同机基线无未解释的实质回退，`baseline_required` 不得被记作 pass

## Future Requirements

本里程碑不承诺，但可在后续独立版本评估。

- **FUTURE-01**: 在专门的、可恢复的发布演练中验证生产 Bundle ID 的 in-place upgrade 与既有 Keychain/数据库连续性
- **FUTURE-02**: 扩展 Android 真机、iPad 与多代 iPhone 的设备矩阵
- **FUTURE-03**: 当官方维护的 SQLCipher native packaging 出现时，以独立 ADR 和迁移计划评估 sqlite3 3.x / SwiftPM replacement

## Out of Scope

| Feature | Reason |
|---------|--------|
| beta/RC/dev 依赖或 Flutter channel | 本里程碑只交付 production-stable 兼容窗口 |
| 为清空 `pub outdated` 强推所有 major | 版本号不优先于加密、架构门禁和可复现性 |
| `sqlcipher_flutter_libs 0.7.0+eol`、`sqlite3_flutter_libs`、system/plain SQLite | 会移除或绕开既有 SQLCipher at-rest encryption |
| 新产品功能、UI 重设计、重新显示首版通知/赞助入口 | 会稀释升级回归信号；另立产品版本处理 |
| Android 真机与 iPad 验收 | 用户已限定仅一台 iPhone 真机；Android 以 release build + emulator 为终点 |
| 覆盖生产 Bundle ID 安装或用真实账目/备份做 destructive test | 存在金融数据和 Keychain 丢失风险 |
| App Store/Google Play 提交与法务最终审阅 | 属于独立 release-owner 上线关卡，不是工具链升级内容 |
| 无 ADR 的 SQLCipher 存储架构替换 | 超出依赖升级范围，且必须先证明迁移与安全等价性 |

## Traceability

Every current requirement maps to exactly one v2.1 roadmap phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 57 | Complete |
| BASE-02 | Phase 57 | Complete |
| BASE-03 | Phase 57 | Complete |
| BASE-04 | Phase 57 | Complete |
| GEN-01 | Phase 58 | Pending — 58-04 Stable CI wrapper |
| GEN-02 | Phase 58 | Pending — 58-04 Stable CI wrapper |
| GEN-03 | Phase 58 | Pending — 58-04 Stable CI wrapper |
| GEN-04 | Phase 58 | Complete |
| PLUG-01 | Phase 59 | Pending |
| PLUG-02 | Phase 59 | Pending |
| PLUG-03 | Phase 59 | Pending |
| PLUG-04 | Phase 59 | Pending |
| SEC-01 | Phase 60 | Pending |
| SEC-02 | Phase 60 | Pending |
| SEC-03 | Phase 60 | Pending |
| SEC-04 | Phase 60 | Pending |
| SEC-05 | Phase 60 | Pending |
| SEC-06 | Phase 60 | Pending |
| AND-01 | Phase 61 | Pending |
| AND-02 | Phase 61 | Pending |
| AND-03 | Phase 61 | Pending |
| AND-04 | Phase 61 | Pending |
| QA-01 | Phase 62 | Pending |
| QA-02 | Phase 62 | Pending |
| QA-03 | Phase 62 | Pending |
| QA-04 | Phase 62 | Pending |
| DEVICE-01 | Phase 63 | Pending |
| DEVICE-02 | Phase 63 | Pending |
| DEVICE-03 | Phase 63 | Pending |
| DEVICE-04 | Phase 63 | Pending |
| DEVICE-05 | Phase 63 | Pending |
| DEVICE-06 | Phase 63 | Pending |
| DEVICE-07 | Phase 63 | Pending |

**Coverage:**

- v1 requirements: 33 total (BASE 4 · GEN 4 · PLUG 4 · SEC 6 · AND 4 · QA 4 · DEVICE 7)
- Mapped to phases: 33
- Unmapped: 0

---
*Requirements defined: 2026-08-05*
*Last updated: 2026-08-05 after official-source v2.1 research synthesis*
