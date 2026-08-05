# Happy Pocket App 代码健康度与性能全面检查报告

**审计日期：** 2026-08-05（Asia/Tokyo）

**审计对象：** `main` / `53aa4e4d` (`feat(release): adopt Happy Pocket branding`)

**技术栈：** Flutter 3.44.0、Dart 3.12.0、Riverpod 3、Drift、SQLCipher
**审计范围：** `lib/` 生产代码、Android/iOS 原生配置、数据库与同步链路、备份恢复、测试与覆盖率、依赖、Release 构建及包体积

> 本报告是代码审查、自动化门禁和 Release 构建的组合结果。未在用户物理设备安装或运行 App，因此不包含真机冷启动耗时、frame raster/UI 指标、内存峰值和能耗数据；这些项目列为发布前补充测量。

## 1. 执行摘要

| 维度 | 评分 | 结论 |
|---|---:|---|
| 工程健康度 | **84/100（B+）** | 静态分析、架构守卫、全量测试、覆盖率和双平台编译均为绿色 |
| 正确性与数据安全 | **72/100（C）** | 发现多账本备份恢复可静默丢失其他账本交易，属于必须先修的运行时缺陷 |
| 安全与隐私 | **78/100（C+）** | 加密、SQLCipher、日志和隐私依赖守卫良好；relay 响应上限与请求重放保护仍有缺口 |
| 架构与可维护性 | **81/100（B）** | 分层与 Riverpod lint 绿色；同步模块和大型 UI 方法仍有明显复杂度债务 |
| 性能与资源效率 | **68/100（C+）** | Release 可构建，但 relay 拉取存在内存耗尽面，复杂度热点与包体积仍需治理 |
| 发布就绪度 | **48/100（D）** | Android Debug 签名、法律占位材料及协议安全门槛阻断商店发布 |

### 总结判断

- **主干工程门禁健康。** `flutter analyze` 与 `custom_lint` 均为 0 issue；全量测试 **4,261 通过、12 跳过、0 失败**；清洗生成代码后的行覆盖率 **86.62%**。
- **当前不能安全地对外发布备份恢复功能。** 现有导出只读取当前账本交易，却写入所有账本元数据；导入会清空所有现有账本交易，导致非当前账本数据静默丢失。
- **同步入口存在资源与协议风险。** relay pull 在任何业务资源策略生效前会一次性读取并 JSON/base64 解码整页响应，理论上可在 UI isolate 中制造约 200 MB 级临时分配；已签名请求也缺少 nonce/replay cache。
- **Release 构建可重现，但发布门槛未关闭。** 干净 Android arm64 Release APK 和 iOS `--no-codesign` 构建均通过；Android 仍用 Debug key，三语法律资产仍包含草案和占位信息。

## 2. 仓库与规模快照

| 指标 | 当前值 |
|---|---:|
| 手写生产 Dart 文件 | 522 |
| 手写生产 Dart 物理行数 | 93,300 |
| `dart_code_linter` 有效源码行 | 50,458 |
| 测试文件（含 integration） | 555 |
| 测试物理行数 | 124,204 |
| 扫描类数 | 910 |
| 功能模块 | 13 |
| Drift 表文件 | 19 |
| Drift schemaVersion | 36 |
| `integration_test/` 文件 | 4 |
| 审计结束工作区 | 仅本报告未提交；应用源码无额外改动 |

## 3. 自动化门禁与构建结果

| 检查 | 结果 | 证据 |
|---|---|---|
| `flutter analyze` | **PASS** | 0 issues |
| `dart run custom_lint --no-fatal-infos` | **PASS** | import_guard / Riverpod lint 0 issues |
| 架构测试 | **PASS** | 26 个文件、94 项通过 |
| 全量 `flutter test --coverage -r expanded` | **PASS** | 4,261 passed / 12 skipped / 0 failed，2m26s |
| 全局行覆盖率 | **PASS** | 26,470 / 30,559 = **86.62%** |
| 逐文件覆盖率门槛 | **PASS（范围警告）** | 53 checked / 0 failed / 11 deferred / 106 missing |
| 未使用文件扫描 | **PASS** | 0 个未引用生产文件 |
| 未使用声明扫描 | **WARN** | 1 个 testing helper 候选 |
| Android Release | **PASS（发布阻断仍在）** | clean build 通过，APK 42.4 MB；仍用 Debug signing |
| iOS Release `--no-codesign` | **PASS** | Runner.app 35.9 MB |
| 依赖新鲜度 | **WARN** | 6 个可升级版本被 lockfile 锁住；11 个依赖约束低于当前可解析版本 |
| 工作区一致性 | **PASS** | 审计前后的应用源码保持 clean |

### 覆盖率门槛解释

全局覆盖率高于 70% 门槛，且实际达到 86.62%。但逐文件门槛的输入清单存在明显漂移：106 个路径未出现在 LCOV 中，其中既有生成文件，也有已删除/重命名文件和未执行路径；另有 11 个显式 deferred 项。该门禁当前没有失败，但它不能等价于“所有高风险文件均达到 70%”。建议重建 `cleanup-touched-files.txt` 与 deferred 基线，并将备份多账本、恢复并发、WebSocket 竞态加入风险驱动测试清单。

## 4. 阻断项（BLOCKER）

### CR-01：多账本备份恢复会静默删除未导出账本的交易

**位置：** [`export_backup_use_case.dart`](../lib/application/settings/export_backup_use_case.dart#L56)、[`import_backup_use_case.dart`](../lib/application/settings/import_backup_use_case.dart#L160)、[`backup_restore_screen.dart`](../lib/features/settings/presentation/screens/backup_restore_screen.dart#L103)

导出入口以当前 `bookId` 调用 `findAllByBook(bookId)`，但同一备份包写入全部 books（包含 archived/shadow）。导入时先逐本删除所有现有交易，再只插入包内当前账本的交易。因此 A 账本导出的包恢复后，会保留 B/C 账本外壳但清空其交易。

**影响：** 家庭/多账本用户发生不可见、不可逆的数据丢失。现有备份测试只覆盖单账本，未覆盖 A/B round-trip。

**建议：** 立即暂停或隐藏破坏性恢复入口，直至明确以下一种语义并加入回归测试：

1. 全应用备份：在一致数据库快照内导出所有需保留账本的全部交易；或
2. 单账本备份：格式显式标记目标账本，导入只替换该账本，绝不触碰其他账本。

### CR-02：relay pull 缺少响应体与单条密文字节上限

**位置：** [`relay_api_client.dart`](../lib/infrastructure/sync/relay_api_client.dart#L507)、[`pull_sync_use_case.dart`](../lib/application/family_sync/pull_sync_use_case.dart#L206)、[`e2ee_service.dart`](../lib/infrastructure/sync/e2ee_service.dart#L118)

HTTP client 先完整读取 `response.body`，再对整页做 `jsonDecode`；随后每条消息又产生 base64、密文和明文副本。协议允许单次 push 约 2 MB、pull 每页最多 100 条，客户端现有 500 operation / 64 KiB 限制发生在完整响应读取和解密之后。

**影响：** 活跃家庭成员或异常 relay 响应可在 UI isolate 中触发约 200 MB 级临时分配，导致卡死或 OOM。

**建议：** 改用 `Client.send` 流式累计读取；同时限制 page 总字节、单 payload、base64 解码后密文及解密明文大小。服务端也应对 pull page 建立总字节预算。加入有/无 `Content-Length` 的超限测试，确认超限数据不进入解密。

### CR-03：同一天第二次导出会覆盖上一份加密备份

**位置：** [`export_backup_use_case.dart`](../lib/application/settings/export_backup_use_case.dart#L109)

导出文件名只有 `YYYY-MM-DD`，默认 `writeAsBytes` 会截断同名文件。当天不同账本或不同时间点的第二次导出会无提示覆盖前一份备份。

**建议：** 使用 UTC 时间到毫秒加 ULID 的唯一文件名，并采用同目录临时文件 + flush + atomic rename；增加同日重复导出测试。

### CR-04：Android Release 仍使用 Debug 签名

**位置：** [`build.gradle.kts`](../android/app/build.gradle.kts#L35)

`release.signingConfig = signingConfigs.getByName("debug")`。本次 Release APK 虽成功构建，但不能作为安全、可持续升级的正式发布包。

**建议：** 通过未入库 `key.properties`/CI secret 注入 upload key，并使缺失生产签名时的正式构建 fail closed；CI 对证书 DN/指纹增加非 Debug 断言。

### CR-05：relay 签名请求在五分钟窗口内缺少重放保护

**位置：** [`relay_api_client.dart`](../lib/infrastructure/sync/relay_api_client.dart#L55)、[`API_PROTOCOL.md`](server/API_PROTOCOL.md#L41)

签名仅绑定 method、path、timestamp 和 body hash；协议允许 ±300 秒，但没有 client nonce/request ID，也没有服务端已用 nonce 缓存约定。非幂等的邀请刷新、成员操作和 sync push 可被原样重放。

**建议：** 将随机 request ID/nonce 纳入签名，服务端按 deviceId 在 TTL 内原子拒绝重复 nonce；非幂等路由必须强制该字段，并补协议集成测试。

### CR-06：随包法律文档仍是草案并包含占位信息

**位置：** [`privacy_en.md`](../assets/legal/privacy_en.md#L7)、[`terms_en.md`](../assets/legal/terms_en.md#L7)、[`tokusho_en.md`](../assets/legal/tokusho_en.md#L7) 及 ja/zh 同类资产

仍可检出 `DRAFT`、`support@example.com` 和“上线前填真实值”。relay 暂存、ACK/过期删除和运行元数据说明已经与实现对齐，但正式运营者、联系方式、生效日期与法务复核尚未完成。

**建议：** 上架前完成三语法律审阅和真实值替换；增加 release-only CI 扫描，拒绝草案标记与占位符。

## 5. 高优先级警告

### WR-01：备份恢复未复用清除数据流程的同步写屏障

**位置：** [`backup_restore_screen.dart`](../lib/features/settings/presentation/screens/backup_restore_screen.dart#L138)、[`import_backup_use_case.dart`](../lib/application/settings/import_backup_use_case.dart#L153)、[`sync_engine.dart`](../lib/application/family_sync/sync_engine.dart#L255)

Clear-all 会暂停 push、WebSocket、scheduler 和进行中的同步任务；Import 直接重写数据库，成功后才发 UI 重启信号。活跃 pull/push 可与恢复交错，令恢复结果混入远端变化或继续发送旧 outbox。

**建议：** 将恢复实现为显式状态机：暂停并等待同步、冻结 UI、恢复一致快照、按产品决策复位 family/outbox/tracker，再恢复 engine。补活跃 pull 与 restore 并发测试。

### WR-02：SharedPreferences 写入位于 Drift transaction 内但无法回滚

**位置：** [`import_backup_use_case.dart`](../lib/application/settings/import_backup_use_case.dart#L244)

数据库最终 commit 失败时，主题、语言和 onboarding 设置可能已经写入 SharedPreferences，形成“数据库回滚、设置半恢复”的跨存储不一致。

**建议：** 使用 journal 化两阶段恢复；至少记录旧 settings 并在失败路径补偿。补 DB commit fail-after-prefs 和 prefs fail-after-DB 两类测试。

### WR-03：WebSocket lifecycle observer 可重复注册

**位置：** [`sync_engine.dart`](../lib/application/family_sync/sync_engine.dart#L290)、[`websocket_service.dart`](../lib/infrastructure/sync/websocket_service.dart#L108)

每次前台 reconciliation 都可能重新 connect 并调用 `addObserver(this)`，但没有 `_isObserving` guard；`removeObserver` 每次只删除一个注册项。多次 resume 后可能累积回调、timer 和重连。

**建议：** start/stop observation 幂等；只在身份或连接状态变化时重连，并增加重复 resume 的 observer/reconnect-count 测试。

### WR-04：异步 WebSocket 认证可能把旧连接签名发到新连接

**位置：** [`websocket_service.dart`](../lib/infrastructure/sync/websocket_service.dart#L125)

`_authenticate` 在 await signer 前构造旧连接消息，await 后向当前可变 `_channel` 写入。连接 A 的签名若在连接 B 建立后完成，可能污染 B，触发随机 auth_error 或断连。

**建议：** 为每次连接分配递增 generation，捕获 channel/group/device；await 后仅在 generation 和 channel identity 仍匹配时发送。

## 6. 性能与可维护性热点

### 6.1 复杂度

全库阈值扫描结果：

- CC > 20：**30** 个方法
- 方法 SLOC > 50：**207** 个方法
- nesting > 5：**2** 个方法

优先业务热点：

| 位置 | CC | SLOC | Nesting | 风险 |
|---|---:|---:|---:|---|
| [`CheckGroupUseCase.execute`](../lib/application/family_sync/check_group_use_case.dart#L76) | 59 | 173 | 5 | 群组状态与错误分支集中，回归定位困难 |
| [`SyncAvatarUseCase.handleAvatarSync`](../lib/application/family_sync/sync_avatar_use_case.dart#L399) | 49 | 192 | 6 | 网络、文件、校验与持久化耦合 |
| [`RefreshGroupSnapshotUseCase.execute`](../lib/application/family_sync/refresh_group_snapshot_use_case.dart#L81) | 43 | 144 | 3 | 快照合并与成员状态分支过多 |
| [`CreateGroupUseCase.execute`](../lib/application/family_sync/create_group_use_case.dart#L77) | 38 | 125 | 4 | 创建、密钥、服务端和本地状态耦合 |
| [`ShoppingItemFormScreen.build`](../lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart#L1117) | 18 | 366 | 3 | 大型 build 增加 rebuild 与维护成本 |
| [`GroupManagementScreen._buildGroupContent`](../lib/features/family_sync/presentation/screens/group_management_screen.dart#L514) | 25 | 347 | 2 | 页面状态组合与 UI 分支过密 |

`AppPalette.copyWith` 的 CC 63 主要来自机械 nullable 参数分支，应作为样板例外，不与业务状态机同级处理。

### 6.2 包体积

| 产物 | 测量值 |
|---|---:|
| Android arm64 Release APK | 42.4 MB（DevTools 压缩分析约 40 MB） |
| iOS Release Runner.app（无签名） | 35.9 MB |

Android APK 的主要占用：

- `libapp.so`：12.45 MB
- `libflutter.so`：11.58 MB
- SQLCipher 三 ABI：约 14.49 MB（arm64 5.19 MB、armeabi-v7a 3.56 MB、x86_64 5.75 MB）
- `lucide_icons_flutter` 六个未使用的 variable-weight 字体：约 **2.69 MB raw / 1.23 MB compressed**；项目代码只使用静态 `LucideIcons`，实际 tree-shaken `lucide.ttf` 仅 8 KB compressed

**建议：** 发布使用 AAB 让 Play 按 ABI 分发；评估替换/裁剪 `lucide_icons_flutter` 的额外 variable font assets；保留 SQLCipher 功能优先级，不为体积误换成非加密 sqlite。

### 6.3 构建链稳定性

全量测试后首次直接执行 Android Release，生成的 plugin registrant 残留了 dev-only `integration_test` 引用，导致 release javac 失败。执行 `flutter clean`、重新 `flutter pub get` 后干净构建成功。

这不是当前源码的稳定编译失败，但说明本地“integration test → release build”切换需要显式清理。建议在发布脚本中固定 clean rebuild，或增加构建前检查，避免将 dev plugin registrant 污染误判为产品回归。

## 7. 依赖与工具链健康

`flutter pub outdated --no-dev-dependencies` 结果：

- 6 个依赖已有兼容升级，但 lockfile 仍锁定旧版本；
- 11 个依赖受 `pubspec.yaml` 约束，低于当前可解析版本；
- Drift 2.31.0 → 2.34.3、Riverpod 3.1.0 → 3.4.2 可列入常规升级窗口；
- `package_info_plus`、`share_plus`、`sqlite3` 与 `sqlcipher_flutter_libs` 属项目已记录的联动 pin，不应单包升级；
- `sqlcipher_flutter_libs 0.7.0+eol` 是空壳 EOL 包，当前继续使用功能完整的 0.6.x 是有意决策；
- Flutter 报告 `sqlcipher_flutter_libs` 尚不支持 iOS Swift Package Manager，未来 Flutter 版本会将警告升级为错误；
- Android 构建警告项目与 file_picker/package_info_plus/share_plus/speech_to_text 仍应用 Kotlin Gradle Plugin，未来 Flutter 需要迁移 Built-in Kotlin。

建议建立一次“整组依赖 + Android/iOS Release + SQLCipher 真机验证”的升级窗口，避免逐包自动升级破坏已知兼容组合。

## 8. 已验证的健康项

- Clean Architecture import guard 与 Riverpod lint 均为 0 issue。
- Domain 层纯净、SQLCipher 依赖、敏感日志、ARB 三语 parity、iOS 权限本地化、Android Analytics/AD_ID 排除等架构守卫均通过。
- 备份密文 16 MB、解压 JSON 64 MB 的资源上限已存在，先前 gzip bomb 风险已关闭；本报告新增问题发生在多账本语义、跨存储事务和同步并发层。
- Android/iOS Release 均能在干净环境编译，说明品牌与三语发布表面改动没有破坏双平台构建。
- 未使用文件扫描为 0；仅 [`createEncryptedExecutorAtFileForTesting`](../lib/infrastructure/crypto/database/encrypted_database.dart#L41) 被标记为生产侧未使用声明。若只供测试，应迁入 test helper 或明确导出边界。

## 9. 测量限制

本轮没有安装/覆盖任何用户物理设备上的 App，因此以下指标尚未实测：

- 冷/热启动时间与首次可交互时间；
- 60/120 Hz frame build/raster、jank 百分比；
- 大账本、家庭同步和备份恢复的峰值 RSS/GC；
- SQLCipher 真机 I/O 延迟与迁移时长；
- 前后台 WebSocket、FCM/APNs 的能耗和网络唤醒。

发布前应在至少一台低端 Android 和最低支持 iPhone 上用 profile/release 模式测量。建议数据集覆盖 1k、10k、50k transactions，以及 100 条接近协议上限的 relay page；将 P50/P95/P99、峰值内存和 dropped frames 写入可重复基线。

## 10. 建议执行顺序

| 优先级 | 工作 | 完成标准 |
|---|---|---|
| 1 | 关闭 CR-01 多账本恢复数据丢失 | A/B 多账本 round-trip 绿色；恢复绝不触碰未包含账本 |
| 2 | 限制 relay pull 字节预算 | 流式超限测试通过，超限消息不进入 base64/解密 |
| 3 | 修复导出唯一命名与原子写 | 同日多次导出不覆盖，所有文件均可恢复 |
| 4 | 恢复流程加入同步屏障与跨存储 journal | pull/push 并发测试与 commit/prefs 故障注入测试通过 |
| 5 | WebSocket lifecycle 幂等 + connection generation | 重复 resume 不累积 observer，旧签名不能进入新 channel |
| 6 | relay 请求 nonce / anti-replay | 同一授权报文第二次被服务端拒绝 |
| 7 | 生产签名与法律材料 | CI 拒绝 Debug cert、DRAFT、example.com 和占位符 |
| 8 | 同步复杂度、覆盖清单与包体积治理 | 高风险 CC/SLOC 下降，LCOV missing 清单收敛，AAB/字体优化完成 |
| 9 | 真机性能基线 | 最低支持设备具备启动、帧、内存、SQLCipher/同步 P95 数据 |

## 11. 结论

Happy Pocket 的工程基础已经稳定：分析、测试、覆盖率、架构守卫和双平台 clean build 都是绿色，且相较 2026-08-04 基线，多项隐私、i18n、复杂度与死代码问题已经关闭。

当前风险集中在少数高影响边界，而不是广泛的代码失控：**备份恢复的数据集合语义、relay 输入资源预算、同步/恢复并发、WebSocket 连接代际、正式签名和法律材料**。其中 CR-01 与 CR-02 应在任何公开测试或商店发布前优先处理；在它们关闭前，不建议将当前版本标记为 release-ready。

---

_本报告由 repo-scope deep review、Flutter/Dart 静态与动态门禁、覆盖率工具、dart_code_linter、依赖解析器及 Android/iOS Release 构建证据综合生成。_
