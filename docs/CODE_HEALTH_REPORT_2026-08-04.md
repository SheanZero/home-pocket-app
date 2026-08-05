# Home Pocket App 代码健康度全面检查报告

**审计日期：** 2026-08-04（Asia/Tokyo）
**审计对象：** `main` / `a6532ad3`（与 `origin/main` 一致）及当前未提交工作区
**技术栈：** Flutter 3.44.0、Dart 3.12.0、Riverpod 3、Drift、SQLCipher
**审计方式：** 静态分析、全量测试、覆盖率、复杂度、死代码、依赖、架构边界、安全与隐私、Android/iOS Release 构建、发布配置与规划文档交叉核对

> 本报告为只读诊断结论。审计开始时工作区已有 **126 个修改项 + 1 个未跟踪文件**，主要是深色主题与 golden 资源；本次未修改业务代码、未覆盖这些用户改动。测试结论因此代表“当前工作区快照”，不是纯净 HEAD。

## 1. 执行摘要

| 维度 | 评分 | 结论 |
|---|---:|---|
| 代码工程健康度 | **76/100（B-）** | 分层、加密、静态分析和全局覆盖率良好；CI 门禁、复杂度和无效代码需要治理 |
| 发布就绪度 | **42/100（D）** | Android/iOS 均可编译，但隐私披露、正式签名、法律占位内容构成发布阻断 |
| 正确性与测试 | 78/100 | 4,425 项通过；11 项失败集中在 golden/设计契约，没有普通业务逻辑失败 |
| 安全实现 | 85/100 | 密钥、SQLCipher、AEAD、备份加密、日志约束整体扎实 |
| 隐私与合规一致性 | 48/100 | Analytics/广告标识权限、relay 存储行为与三语隐私政策存在实质冲突 |
| 架构与可维护性 | 72/100 | Clean Architecture 基础清晰，但高复杂度热点、25 个疑似未使用文件持续增加维护成本 |
| 依赖与平台工程 | 65/100 | 双平台 Release 编译通过；存在 debug 签名、iOS 最低版本偏移及未来工具链兼容警告 |
| 规划与文档治理 | 60/100 | STATE、ROADMAP、AGENTS/PROJECT 对当前里程碑的状态描述不一致 |

### 总结判断

- **核心账本、加密、本地数据与大多数业务行为是健康的。** `flutter analyze` 0 issue，清洗生成代码后的全局覆盖率为 **86.97%**，双平台 Release 均能编译。
- **当前主分支质量流水线不是绿色。** `custom_lint`、全量测试、架构契约测试和逐文件覆盖率门禁均有失败。
- **当前不建议提交应用商店。** 在发布前至少必须处理：Android 正式签名、Firebase Analytics/广告标识与隐私政策冲突、relay 暂存加密消息与“服务器不保存”表述冲突、三语法律草案及真实运营者信息占位。

## 2. 仓库与规模快照

| 指标 | 当前值 |
|---|---:|
| 手写生产 Dart 文件 | 556 |
| 手写生产 Dart 物理行数 | 114,522 |
| `dart_code_linter` 有效源码行 | 53,032 |
| 测试文件 | 560 |
| 测试物理行数 | 128,617 |
| 类 | 954 |
| 功能模块 | 13 |
| Drift 表 | 19 |
| 设备/模拟器 `integration_test` | 1 |
| 当前工作区改动 | 126 modified + 1 untracked |

与 2026-07-02 的既有质量报告相比，手写生产 Dart 文件从约 455 增至 556。上一轮原子备份恢复、Drift 索引、导入层守卫、Argon2id 备份加密和迁移间隙等 P0/P1 修复仍保留；本轮主要暴露的是**发布一致性、门禁漂移和规模增长后的维护风险**。

## 3. 自动化门禁结果

| 检查 | 结果 | 关键数据 |
|---|---|---|
| `flutter analyze` | **PASS** | 0 issues，3.7s |
| `dart run custom_lint --no-fatal-infos` | **FAIL** | 11 个 `import_guard` warning；CI 中该命令为阻断门禁 |
| 架构测试 | **FAIL** | 62 pass / 1 fail；v16 mockup 缺少购物数量减少契约标记 |
| 全量 `flutter test -r expanded` | **FAIL** | `+4425 ~12 -11` |
| 全量覆盖率测试 | **FAIL** | 失败项同上，但成功生成有效 LCOV |
| 清洗后全局覆盖率 | **PASS** | 27,619 / 31,758 = **86.97%**，高于 70% 门槛 |
| 逐文件覆盖率门禁 | **FAIL** | 54 个已检查文件中 2 个低于 70%；另有 11 个长期 deferred |
| `git diff --check` | **PASS** | 无空白/冲突标记问题 |
| Android Release 构建 | **PASS** | 91.1 MB APK；但由 Android Debug 证书签名 |
| iOS Release 无签名构建 | **PASS** | `Runner.app` 35.7 MB |
| 依赖新鲜度 | **WARN** | 44 个 lockfile 包可升级；12 个直接依赖受约束无法到最新可解析版本 |

### 当前 11 个测试失败

- 9 个浅色购物项 tile golden：active/completed/attribution × ja/zh/en；像素差约 0.32%，隔离差异图显示为小范围图标像素变化。
- 1 个 Settings 法务/支持浅色日语 golden；像素差约 0.17%，同样集中在小图标区域。
- 1 个架构契约：[`docs/mockup/v16/index.html`](mockup/v16/index.html) 缺少 `data-action="shopping-quantity-decrease"`。

这些失败没有显示核心账本逻辑回归，但它们仍会让 CI 的 `flutter test --coverage` 直接失败。由于当前工作区包含大量未提交的主题/golden 修改，应先确认哪些差异是有意设计变更，再决定更新基线还是修复组件。

## 4. 阻断项（P0）

### P0-01：隐私政策与实际第三方分析 SDK/权限冲突

Android 原生构建显式引入 Firebase Analytics：

- [`android/app/build.gradle.kts:50`](../android/app/build.gradle.kts#L50) 使用 Firebase BOM；
- [`android/app/build.gradle.kts:51`](../android/app/build.gradle.kts#L51) 引入 `com.google.firebase:firebase-analytics`；
- Release 合并清单包含 `com.google.android.gms.permission.AD_ID` 和 Advertising Services 权限；
- Dart 的 [`pubspec.yaml`](../pubspec.yaml) 没有 `firebase_analytics`，未发现业务侧分析功能或禁用采集配置，说明这更像无意遗留的原生依赖。

但三语隐私政策明确声称“不集成任何第三方分析/追踪 SDK”：

- [`assets/legal/privacy_ja.md:46`](../assets/legal/privacy_ja.md#L46)
- [`assets/legal/privacy_en.md:46`](../assets/legal/privacy_en.md#L46)
- [`assets/legal/privacy_zh.md:46`](../assets/legal/privacy_zh.md#L46)

**影响：** 与 privacy-focused 品牌承诺、Google Data Safety / Apple Privacy Nutrition Label 的申报口径冲突；可能发生未披露的设备/使用数据采集。
**发布前要求：** 如果不需要行为分析，移除原生 Analytics 依赖并验证合并清单不再含广告标识相关权限；如果确实需要，则必须明确配置采集策略、同意机制和三语隐私披露。

### P0-02：家庭同步“设备直连/服务器不保存”的政策表述与 relay 实现不一致

政策声明家庭同步“直接在设备间进行”，且同步数据“不会保存于开发者服务器”：[`assets/legal/privacy_ja.md:40`](../assets/legal/privacy_ja.md#L40)、[`privacy_en.md:40`](../assets/legal/privacy_en.md#L40)、[`privacy_zh.md:40`](../assets/legal/privacy_zh.md#L40)。

实际实现是零知识加密中继，而非直连：

- [`relay_api_client.dart:94`](../lib/infrastructure/sync/relay_api_client.dart#L94) 明确连接 `sync.happypocket.app` relay；
- [`relay_api_client.dart:468`](../lib/infrastructure/sync/relay_api_client.dart#L468) 从服务端拉取 pending messages；
- [`relay_api_client.dart:476`](../lib/infrastructure/sync/relay_api_client.dart#L476) ACK 后触发服务端物理删除；
- [`docs/server/API_PROTOCOL.md:761`](server/API_PROTOCOL.md#L761) 写明服务器存储并转发 opaque encrypted blobs；
- [`docs/arch/server/SERVER-001_SyncRelay.md:40`](arch/server/SERVER-001_SyncRelay.md#L40) 写明同步数据临时存储、ACK 后物理删除。

**影响：** 加密内容对服务器不可读，零知识安全属性仍成立；但“从不保存”这一绝对事实陈述不成立，属于隐私政策与真实处理流程不一致。服务器还持有设备 ID、公钥、群组关系、push token 等必要元数据，政策也应如实描述其目的与保留方式。
**发布前要求：** 将三语政策改为“加密消息经中继服务器临时存储与转发，接收确认或过期后删除；服务端无法解密内容”，并核对服务端真实保留期、日志和删除策略。

### P0-03：Android Release 使用 Debug 证书签名

[`android/app/build.gradle.kts:35`](../android/app/build.gradle.kts#L35) 的 `release` 构建直接设置：

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

对生成 APK 的证书核验结果为 `CN=Android Debug`。这不是可投放 Google Play 的正式密钥管理方案。

**影响：** 无法建立安全、可持续的生产升级签名链；误发布会造成后续升级和供应链风险。
**发布前要求：** 使用受保护的 upload/app signing 配置，通过 CI secret 或本地未入库 `key.properties` 注入；构建后自动验证证书 DN/指纹并拒绝 Debug 签名。

### P0-04：随包法律材料仍是草案并包含真实信息占位

9 个 `assets/legal/*.md` 均保留草案或占位内容。特别是：

- [`assets/legal/tokusho_ja.md:19`](../assets/legal/tokusho_ja.md#L19) 的事業者名、所在地、电话、运营责任人全部是 `[上线前填真实值]`；
- [`assets/legal/tokusho_ja.md:26`](../assets/legal/tokusho_ja.md#L26) 仍使用 `support@example.com`；
- [`assets/legal/privacy_ja.md:5`](../assets/legal/privacy_ja.md#L5) 标注为草案，并在 [`:58`](../assets/legal/privacy_ja.md#L58) 使用示例邮箱；
- 英文、中文版本有同样占位和草案标记。

**影响：** App 内直接展示未完成法律文本，与 ROADMAP 中“日本合规上线关卡完成”的状态不一致。
**发布前要求：** 完成日本法务复核、替换真实运营者/联系方式、统一三语生效日期和版本，加入构建期占位符扫描门禁。

## 5. 高优先级问题（P1）

### P1-01：主分支 CI 的 `custom_lint` 门禁必定失败

当前有 11 个 `import_guard` warning，集中在 accounting、family_sync、shopping_list 的同域 model/repository 导入，以及 `dart:convert`。人工抽查后，这些大多是合法的同领域依赖，问题更像 allowlist 没随代码演进更新，而非真实跨层违规。

CI 在 [`.github/workflows/audit.yml:49`](../.github/workflows/audit.yml#L49) 将该命令设为 hard-fail，因此无论 analyzer 是否绿色，当前 PR/push 门禁仍会红。

**建议：** 逐条确认后更新对应 `import_guard.yaml`；对真正不允许的引用重构，不要通过整体弱化规则解决。

### P1-02：全量测试与设计契约不是绿色

4,425 项通过、12 项跳过、11 项失败。失败全部集中于 10 个 golden 和 1 个 mockup 契约，未发现普通单元/组件业务断言失败。

**建议：** 对当前未提交的主题改动做一次设计确认；有意差异重新生成并人工审图，无意差异修复 icon/layout。补回 `shopping-quantity-decrease` mockup 契约或同步修改契约测试。

### P1-03：逐文件覆盖率门禁有 2 个未豁免失败

- `lib/features/analytics/presentation/providers/state_analytics.dart`：61/113，**53.98%**
- `lib/features/settings/presentation/providers/repository_providers.dart`：34/53，**64.15%**

此外，`.planning/audit/coverage-gate-deferred.txt` 仍有 11 个 2026-04 起的 deferred 项，`files-needing-tests.txt` 也明显落后于现状。尽管清洗后全局覆盖率已达到 86.97%，CI 的逐文件门禁仍会失败。

**建议：** 优先补 provider fallback/error/autoDispose 路径测试；重新生成覆盖率基线并逐项关闭已过期 deferred，而不是扩大豁免范围。

### P1-04：备份导入缺少加密文件和解压后大小上限

[`import_backup_use_case.dart:57`](../lib/application/settings/import_backup_use_case.dart#L57) 对外部文件直接 `readAsBytes()`，[`import_backup_use_case.dart:73`](../lib/application/settings/import_backup_use_case.dart#L73) 直接 `gzip.decode()`，没有输入文件上限、解压后上限或流式解压约束。

备份密码学本身良好：Argon2id + AES-256-GCM，KDF 参数也有上限；但超大文件或高压缩比数据仍可能造成内存耗尽。

**建议：** 文件选择后先限制密文大小；解密后采用有上限的流式解压/累计字节检查；对交易、分类、账本和汇率记录数设置合理上限，并添加 zip-bomb/超大输入回归测试。

### P1-05：支持平台声明与 iOS 实际最低版本不一致

项目说明宣称 iOS 14+，但 [`ios/Podfile:1`](../ios/Podfile#L1) 与 Xcode project 的 `IPHONEOS_DEPLOYMENT_TARGET` 均为 **15.0**。Android 合并清单为 minSdk 24，符合 Android 7+。

**建议：** 明确产品决策：若继续支持 iOS 14，验证所有插件/SQLCipher 后降回 14；若已正式提升到 15，统一 AGENTS、README、商店元数据和测试矩阵。

**修复状态（2026-08-05）：已完成。** 产品最低版本确定为 iOS 15.0；工程配置、当前项目文档、官网与商店介绍、发布门禁及真机测试矩阵已统一，并新增架构契约防止口径回退。

### P1-06：iOS 系统权限说明只有日语

[`ios/Runner/Info.plist:29`](../ios/Runner/Info.plist#L29) 的麦克风、语音识别、Face ID 说明均为日语，仓库中没有 `InfoPlist.strings`。App 支持 ja/zh/en，因此英文或中文系统环境仍会看到日语权限弹窗。

**建议：** 增加 `ja.lproj`、`zh-Hans.lproj`、`en.lproj/InfoPlist.strings`，并加入三语 parity 测试。

**修复状态（2026-08-05）：已完成。** 已为应用显示名、麦克风、语音识别和 Face ID 用途说明补齐日语、简体中文和英文资源，并将 `InfoPlist.strings` variant group 加入 Runner Resources；新增架构测试锁定三语 key parity、显示名和 Xcode 工程引用。

## 6. 中优先级问题（P2）

### P2-01：复杂度热点过大

`dart_code_linter` 检出 **38 个圈复杂度违规**和 **101 个方法 SLOC 违规**。优先关注：

| 位置 | 圈复杂度/规模 | 风险 |
|---|---:|---|
| `lib/data/database/app_database.dart` migration getter | CC 92 / SLOC 583 / nesting 7 | schema 演进回归难定位 |
| `lib/features/home/presentation/screens/home_screen.dart` build | CC 71 / SLOC 415 | UI 状态组合过多，重构/测试成本高 |
| `lib/application/family_sync/check_group_validity_use_case.dart` execute | CC 59 | 高风险同步状态机过度集中 |
| `lib/application/family_sync/pull_sync_use_case.dart` execute | CC 35 / SLOC 218 / nesting 7 | 错误、分页、ACK 时序难验证 |
| `lib/application/family_sync/apply_sync_operations_use_case.dart` | 多个 CC 31–34 方法 | 不同实体处理耦合 |

`app_palette.copyWith` 的 CC 63 主要是机械参数分支，可作为生成/样板例外，不应与业务复杂度等同。

**建议：** 优先按行为边界拆迁移步骤、同步实体处理器和 Home UI section；每次拆分先补 characterization tests，避免大规模一次性重写。

### P2-02：生产目录有 25 个疑似未使用文件

静态扫描识别出 25 个生产侧未被引用文件，主要包括旧 OCR/Voice 页面、旧 Analytics cards、Settings 旧 section、Shopping 批量/选择组件和 demo service。另有约 28 个疑似未使用声明。

**建议：** 先区分“被测试直接引用但运行时未接线”“feature flag 保留”“真实废弃”三类；真实废弃内容用小批次删除并跑全量测试，不直接依据扫描结果批量删除。

### P2-03：设备级 E2E 覆盖面过窄

`integration_test/` 仅有 [`merchant_migration_ladder_test.dart`](../integration_test/merchant_migration_ladder_test.dart)。首启、应用锁、备份恢复、家庭同步、离线队列、推送和真实 SQLCipher 初始化主要依赖 host 测试或历史 UAT 文档。

**建议：** 建立最小设备 smoke：全新安装→onboarding→创建账目→冷启动锁→导出/恢复→家庭同步 push/pull/ACK；iOS/Android 至少各一条 CI 或发布前自动化路径。

### P2-04：依赖与未来 Flutter 兼容债

- `flutter pub outdated`：44 个 lockfile 包可升级，12 个直接依赖受约束；
- `sqlcipher_flutter_libs` 不支持 iOS Swift Package Manager，Flutter 提示未来会升级为错误；
- app 和若干插件仍应用 Kotlin Gradle Plugin，Flutter 3.44 提示未来 Built-in Kotlin 迁移后可能构建失败。

**建议：** 保持 `sqlcipher_flutter_libs ^0.6.x` 和 sqlite3 2.x 的既定安全约束，不做盲目大版本升级；建立分组升级计划并要求 iOS 真机 SQLCipher、Android migration、签名和全量测试共同通过。

### P2-05：发布元数据仍是开发默认值

- [`pubspec.yaml:4`](../pubspec.yaml#L4) 为 `0.1.0+1`，与规划中的 v2.0/首次公开发布口径不一致；
- Android application label 为 `home_pocket`，未使用本地化资源；
- Android Release APK 为 91.1 MB，应在 AAB、ABI 拆分和符号产物层面评估实际商店体积。

### P2-06：规划状态存在漂移

**状态：已修复（2026-08-05）。** v2.0 已通过 GSD 完成审计并以 `tech_debt` override closeout 归档；PROJECT、ROADMAP、STATE、MILESTONES、AGENTS 与 CLAUDE 的当前状态已统一。32/32 需求覆盖、4/4 phase 验证通过、12/12 集成接缝连通、6/6 E2E 流完整。38 个历史 artifact 与上线前 release-owner 配置已由用户选择 A 明确认领并记录到 STATE Deferred Items；完成态需求与 phase 资料位于 `.planning/milestones/v2.0-*`。`.planning/codebase/` 已按当前工作树刷新，最终 `gsd-health` 为 `healthy`（0 error / 0 warning）。

- [`.planning/STATE.md:6`](../.planning/STATE.md#L6) 标记 Phase 56 / v2.0 `complete`；
- [`.planning/ROADMAP.md:15`](../.planning/ROADMAP.md#L15) 和 [`:326`](../.planning/ROADMAP.md#L326) 仍标记 v2.0 `in progress`、P56 unplanned；
- [`PROJECT.md`](../.planning/PROJECT.md) 将 v2.0 视为当前 milestone，但尾部说明又称全部完成并 ready to close；
- 当前 AGENTS 项目状态仍停留在 v1.2 Phase 15。

**建议：** 先归档/关闭 v2.0，再统一 PROJECT、ROADMAP、STATE、REQUIREMENTS、AGENTS；刷新质量基线和 codebase map，避免下一阶段基于错误上下文规划。

## 7. 已验证的健康项

1. **静态类型与 Flutter analyzer 健康。** 当前代码在 Flutter 3.44.0 下 0 issue。
2. **双平台 Release 可编译。** Android APK 与无签名 iOS Runner.app 均成功产出；问题集中在发布配置而非源码编译。
3. **测试资产规模充足。** 560 个测试文件、4,425 项当前通过；测试代码物理行数高于生产代码。
4. **全局覆盖率强。** 排除生成文件后 86.97%，明显高于既定 70% 门槛。
5. **密码学实现良好。** SQLCipher 初始化验证、密钥就绪顺序、ChaCha20-Poly1305/AES-GCM、Argon2id 备份 KDF、`Random.secure()` 和 KDF 参数上限均符合项目威胁模型。
6. **备份恢复具备事务原子性。** 删除与重建在 `UnitOfWork` 中完成，导入中途失败可回滚。
7. **安全存储边界总体受控。** 未发现功能层绕过既有 secure-storage/key-manager 直接管理关键密钥。
8. **敏感日志治理有效。** 架构测试中的生产日志隐私、硬编码 CJK、ARB parity、颜色约束等均通过；唯一架构失败是 mockup 交互契约。
9. **未发现硬编码密钥/令牌。** 常见 secret pattern 扫描没有命中真实凭据。
10. **数据库性能上一轮 P1 已保留修复。** schema v23 的声明索引创建与迁移守卫仍在；未发现重新引入 `sqlite3_flutter_libs`。

## 8. 已接受但应持续跟踪的风险

- 4 位 PIN 当前没有尝试次数限制/递增冷却，仅依靠 Argon2id 抗暴力破解；项目已在 Phase 55 明确接受为 MVP 风险，应在下一安全迭代关闭。
- `groupKey` 作为 SQLCipher 数据库中的字段保存，依赖整库加密而非额外字段加密；这是现有架构的残余风险。
- 11 个逐文件覆盖率 deferred 项长期存在，应设截止 milestone，避免“临时豁免”永久化。
- `sqlcipher_flutter_libs ^0.6.x` 的 pin 是有意决策，但必须持续验证 Flutter/iOS 工具链兼容性。

## 9. 建议处置顺序

### 发布前必须完成

1. 移除无意的 Firebase Analytics/AD_ID，或建立真实同意与披露方案；重新检查 Android merged manifest。
2. 将 relay 暂存/转发、元数据、保留期和删除机制如实写入三语隐私政策。
3. 替换全部法律草案、`support@example.com` 和 `[上线前填真实值]`，完成日本法务复核。
4. 配置 Android 正式签名和 CI 证书校验；设置真实 versionName/versionCode、应用名与商店元数据。
5. 让 `custom_lint`、全量测试、架构契约和逐文件覆盖率全部恢复绿色。

### 下一维护迭代

1. 给备份导入增加文件/解压/记录数上限。
2. 拆分数据库 migration、Home build、family sync 状态机等高复杂度热点。
3. 清理 25 个疑似无效生产文件，并更新 codebase map。
4. 增加 iOS/Android 设备级端到端 smoke 与权限文案本地化。
5. 分组升级依赖并处理 Built-in Kotlin、Swift Package Manager 的未来兼容要求。
6. 关闭 v2.0 规划状态漂移，重建覆盖率和技术债基线。

## 10. 最终结论

Home Pocket 的**核心代码不是“失控”状态**：领域结构、加密链路、类型检查、测试规模和全局覆盖率都处于较好水平。当前最大风险来自“实现已经接近发布，但发布治理没有同步收口”：隐私政策没有准确描述 Analytics 和 relay 行为，法律材料仍是草案，Android 仍用 Debug 签名，质量门禁因配置/视觉基线漂移而红。

因此本次结论是：

- **可以继续开发和修复：是；**
- **可以作为内部测试包使用：是；**
- **可以直接公开上架：否；**
- **建议状态：发布冻结，先关闭 4 个 P0 与所有阻断门禁。**
