# Happy Pocket App 代码健康度与性能全面检查报告（终版）

**检查日期：** 2026-08-06（Asia/Tokyo）

**修复前基线：** `main` / `707eb0dd`

**修复后代码基线：** `main` / `4db112e9`

**Relay 服务端基线：** `/Users/xinz/Development/home-pocket-server` / `main` / `67dfed5`

**初版报告：** `docs/CODE_HEALTH_AND_PERFORMANCE_REPORT_2026-08-06_INITIAL.md`

## 1. 结论

本轮代码健康度审计已完成“检查 → 独立 agent 串行修复 → 反例复审 → 全量终验”闭环。最终独立 reviewer 对 HP-33～HP-39 的事务、进程锁、取证修复状态机和兼容迁移返回 **No findings**；真实审计目录为 **0 open / 8 accepted / 63 closed**。

App 的静态分析、代码生成、4 路审计、全量测试、覆盖率、高风险文件门禁、iOS UAT 无签名 Profile 构建和 Relay 全量 Go 测试均通过。未发现新的 P0、已证实数据损坏、明文敏感日志、架构越层或未处理死代码。

但本报告不判定“可直接发布”：隔离 UAT 的有线 iPhone 安装仍被 Xcode 账号和 provisioning profile 阻断，因此真机关键旅程、同步交付、迁移阶梯和 Profile 性能基线尚未完成。法律材料虽已填充并生成日/中/英版本，最终法律审阅及正式托管 URL/DNS/TLS 可达性仍是独立的商店发布门禁。

| 维度 | 终版结论 |
|---|---|
| 正确性与回归 | PASS：4,535 passed / 12 skipped / 0 failed |
| 安全与隐私 | PASS：同步输入预算、WebSocket schema/group/generation、日志隐私与 Relay nonce/pull 边界均有合同或测试 |
| 工具链可信度 | PASS：scanner 必须真实 `ran`，merger fail-closed，双文件目录具有崩溃恢复、内核锁和取证修复 |
| 可维护性 | 0 open；复杂度热点较初版下降 2 个 CC>20 方法 |
| 覆盖率 | 87.08%；15/15 高风险文件 ≥70%，0 missing、0 deferred |
| iOS 构建 | PASS：隔离 UAT Profile 无签名构建；真机签名验收 BLOCKED |
| 发布就绪度 | **未就绪**：需完成 UAT profile/真机验收、最终法律审阅及托管确认 |

## 2. 终验环境与证据

| 项目 | 结果 |
|---|---|
| Flutter / Dart / DevTools | 3.44.8 Stable / 3.12.2 / 2.57.0 |
| Xcode / CocoaPods | 26.2 / 1.16.2 |
| 代码生成可复现性 | PASS：第 1 轮生成、Analyzer、合同测试通过；第 2 轮 0 outputs；无 tracked/untracked generated drift |
| `flutter analyze` | PASS：0 issues |
| `custom_lint --format=json` | PASS：`diagnostics: []` |
| tooling guards | PASS：import、layer、ProviderScope、alias、pattern、extension type 负向夹具及生产树检查全部通过 |
| 真实 audit pipeline | PASS：4/4 canonical shards `ran`，均 `scan_failed=false` |
| 全量覆盖率测试 | PASS：4,535 passed / 12 skipped / 0 failed，单并发 13m45s |
| 清洗 LCOV | 27,166 / 31,196 = **87.08%** |
| 高风险逐文件门禁 | PASS：15/15 ≥70%，0 missing、0 deferred |
| Relay `go test ./...` | PASS：全部 package 通过 |
| iOS UAT Profile 无签名构建 | PASS：`Runner.app` 43.7 MB |
| 有线 iPhone UAT 安装/测试 | BLOCKED：Xcode 无登录账号；wildcard profile 不包含目标设备 |

默认并发覆盖率曾在更早复审中只因 `tooling_guard_negative_fixture_test` 的 30 秒子进程限时失败；该文件隔离运行通过。终验使用 `--concurrency=1`，完整套件无失败，避免把资源争用误判为产品回归。

## 3. 修复前后指标

| 指标 | 初版 | 终版 | 变化 |
|---|---:|---:|---:|
| 全量通过测试 | 4,361 | **4,535** | +174 |
| 跳过 / 失败 | 12 / 0 | **12 / 0** | 无新增跳过或失败 |
| 清洗覆盖率 | 86.49% | **87.08%** | +0.59 pp |
| 高风险文件 ≥70% | 15/15 | **15/15** | 保持全绿 |
| CC > 20 方法数 | 25 | **23** | -2 |
| 方法 SLOC > 50 | 208 | **208** | 持平 |
| nesting > 5 | 1 | **1** | 持平 |
| 最高 CC / SLOC / nesting | 未单列 | **63 / 211 / 6** | 作为后续复杂度债务基线 |
| dead-code findings | 0（可信度待加强） | **0，真实 scanner ran** | fail-closed |
| layer findings | 0 | **0** | 保持 |
| provider findings | 不可采信 | **0，owned contract ran** | 假绿已关闭 |
| duplication scan | 未运行 stub | **6 个现场 observation** | 已真实执行 |
| catalogue open | 7 个初版问题 | **0** | 全部闭环 |

性能方面，本轮能确认的是静态复杂度下降、同步控制帧的解析前资源上限和 Profile 构建成功；不能确认真机冷启动、帧时间、内存峰值或数据库迁移时延，因为隔离 UAT 尚不能签名安装。WebSocket 控制帧现限制为 16 KiB、JSON 深度 12，并限制 map、字段名、字符串和节点预算，超限不会进入事件派发。

## 4. 串行问题闭环

### 4.1 初版问题 HP-01～HP-07

| ID | 结果 | 主要提交 |
|---|---|---|
| HP-01 | 代码生成门禁同时拒绝 tracked drift 与未追踪生成产物 | `964ac42a` |
| HP-02 | Relay pull `hasMore=false` 精确预算 off-by-one 修复 | server `67dfed5` |
| HP-03 | 新增隔离 UAT Bundle ID、显示名、Keychain/通知/Firebase 边界和 scheme | `ff2a3362`, `8276c3ad` |
| HP-04 | WebSocket 解析前字节预算及解析后结构预算 | `194ce45c`, `6c10a747` |
| HP-05 | Device E2E Flutter pin 统一至 3.44.8 | `44a1e852` |
| HP-06 | Riverpod 上游 lint 假绿显式 hold，并用仓库自有合同守卫 | `19d587f9` |
| HP-07 | duplication stub 替换为真实 detector 与 allowlist 语义 | `43b13f5b` |

### 4.2 深入审计 HP-08～HP-16

| ID | 结果 | 主要提交 |
|---|---|---|
| HP-08 | finding 生命周期与 reopen/close 语义准确化 | `911fd4ff` |
| HP-09 | shopping persistence seam 去重并统一 | `a49ffaea` |
| HP-10 | avatar MIME sniff 复用与边界收敛 | `ab5cbcb2` |
| HP-11 | device identity 逻辑复用 | `48aa45ff` |
| HP-12 | amount display 逻辑复用 | `bce59440` |
| HP-13 | modal sheet chrome 共享 | `35168dc0` |
| HP-14 | avatar picker route 修正 | `e043746e` |
| HP-15 | UAT Flutter LLDB 初始化配置修正 | `f190014e` |
| HP-16 | iOS 兼容输入摘要刷新 | `7ff97cc9` |

### 4.3 审计与同步边界 HP-17～HP-31

| ID | 结果 | 主要提交 |
|---|---|---|
| HP-17 | merger `--root` 测试合同修正 | `d4627a0b` |
| HP-18 | WebSocket schema 拒绝未知/畸形控制帧 | `51860275`, `72de0323` |
| HP-19 | canonical shard 未运行/失败时 fail-closed | `d47c3893`, `bab3b424` |
| HP-20 | ProviderScope import identity 加固 | `52a807d2` |
| HP-21 | dead-code wrapper 对运行/解析失败 fail-closed | `a61c4fc8` |
| HP-22 | 单条畸形 canonical finding 不再被静默丢弃 | `676ccc7e` |
| HP-23 | 本地 ProviderScope 声明阴影拒绝 | `d6832c53` |
| HP-24 | Provider scanner 契约文档与实现一致 | `4ccf0804` |
| HP-25 | WebSocket 控制帧绑定已认证 group 与当前 connection generation | `c53dd543` |
| HP-26 | merger history/canonical 语义验证和写前拒绝 | `5caff984` |
| HP-27 | scanner partial report 与 custom_lint clean preamble 正确处理 | `83fa8927`, `f8dc4c96` |
| HP-28 | qualified Riverpod alias 阴影拒绝 | `4440298a` |
| HP-29 | custom_lint 0.8.1 使用并严格解析受支持 JSON 格式 | `17629ab4` |
| HP-30 | dart_code_linter 3.2.1 进度帧归一化与 JSON 严格解析 | `07ec5615` |
| HP-31 | record/list/map/switch pattern 阴影拒绝 | `3d2abfc9` |

### 4.4 Catalogue 事务与取证恢复 HP-32～HP-39

| ID | 结果 | 主要提交 |
|---|---|---|
| HP-32 | `issues.json` 与 `ISSUES.md` 初版 journaled pair commit | `494b011f` |
| HP-33 | prepare/journal/terminal/cleanup 全中断点可恢复 | `f6d0496c` |
| HP-34 | `extension type ProviderScope` 阴影拒绝 | `6e2eee6f` |
| HP-35 | 精确接受官方 metrics update footer，其他尾注仍拒绝 | `dc6d08c7` |
| HP-36 | 首版跨进程锁与显式 forensic repair | `24e97984` |
| HP-37 | 永久 inode 的 OS 内核锁；repair `isolating → pending → complete` 可续作 | `f7c41faf` |
| HP-38 | pending quarantine 独占/摘要复验；HP-36 schema v1 安全迁移 | `dfab5bab` |
| HP-39 | repair candidates basename 去重与非规范/symlink root 回归 | `4db112e9` |

HP-39 reviewer 提出的原始重复 journal 反例经真实测试未复现，因为 journal 本就不匹配 transient 正则；仍加入 basename map、写前唯一性守卫，以及尾斜杠、`/.`、symlink root 回归。最终 reviewer 对 HP-33～HP-39 返回 **No findings**。

## 5. Audit catalogue 终态

| Scanner | 状态 | 现场 findings |
|---|---|---:|
| `dart_code_linter` dead code | `ran`, `scan_failed=false` | 0 |
| `import_guard` layer | `ran`, `scan_failed=false` | 0 |
| owned provider contract | `ran`, `scan_failed=false` | 0 |
| owned duplication detector | `ran`, `scan_failed=false` | 6 |

Catalogue 共 71 条：**63 closed、8 accepted、0 open**。8 条 accepted 均为带精确 fingerprint 和 rationale 的 UI 结构 clone；现场 detector 产生 6 个 observation，catalogue 还保留同一受审 clone 的稳定历史锚点。不存在目录级或路径级宽泛忽略。

## 6. Relay 服务端

服务端 `go test ./...` 全部通过，工作树仅保留用户原有未追踪 `.DS_Store`。

- CR-02：pull 在读取/解密前具备响应总字节预算；最终 envelope 边界已修复。
- CR-05：`device_id + nonce` 持久 ledger、原子 claim、重放 409、ledger 故障 503 fail-closed，nonce 纳入签名。
- HP-02：`hasMore=false` 较长 suffix 的精确预算由 `67dfed5` 关闭。

## 7. 有线 iPhone 验收

仅访问用户授权的有线 iPhone，没有使用 iPad、模拟器或无线设备。

已验证：

- Flutter 可识别目标有线设备；
- UAT 无签名 Profile 构建成功，Bundle ID 为 `com.sheanzero.happypocket.app.uat`；
- 显示名为 `Happy Pocket UAT`，`HPUATBuild=YES`；
- `FirebaseMessagingAutoInitEnabled=false`，包内无 `GoogleService-Info.plist`；
- 生产与 UAT App 均未安装到目标设备，因此本轮没有覆盖生产容器或 Keychain。

阻断证据：

- Xcode 报 `No Accounts: Add a new account in Accounts settings`；
- wildcard provisioning profile 不包含目标设备；
- 生产 profile 虽包含设备，但未被用于绕过隔离 UAT 策略。

待完成真机项：关键旅程、同步交付、迁移阶梯、Profile 性能 benchmark、签名安装/启动证据。

解除阻断需要在 Xcode 登录 Apple Developer 账号，打开 `ios/Runner.xcworkspace`，选择 `uat` scheme 与目标有线 iPhone，在 Signing & Capabilities 中使用 team `6Y64KR8RLP` 自动注册设备并生成 UAT profile。完成后应重新运行上述真机矩阵并补充本报告。

## 8. 保留债务与发布门禁

以下不是本轮开放代码缺陷，但必须继续显式管理：

1. **复杂度债务：** CC>20 仍有 23 个方法，SLOC>50 仍有 208 个方法，nesting>5 有 1 个；当前有测试保护，但应在触碰相应功能时继续拆分。
2. **依赖升级窗口：** `pub` 仍报告 48 个与当前约束不兼容的新版本。Riverpod/analyzer/codegen、iOS 原生插件与 SQLCipher 必须联动升级和真机验证，不能逐包自动升级。
3. **SQLCipher SPM：** `sqlcipher_flutter_libs 0.6.8` 仍提示不支持 Swift Package Manager；当前 CocoaPods 链路构建通过，`0.7.0+eol` 不是可直接升级替代项。
4. **Riverpod lint：** 上游 analyzer plugin 兼容问题仍处于显式 hold；当前可信门禁是 Analyzer、custom_lint 协议检测和 owned provider contract。
5. **法律与商店材料：** 日/中/英法律材料已填充，但用户已确认尚未完成最终法律审阅；仓库 `publish/ios/RELEASE_GATES.md` 中正式 DNS/TLS/地区可达性仍未勾选。
6. **真机性能：** 在 UAT 签名解除前，不应把静态复杂度改善或无签名 Profile 构建等同于冷启动、jank、内存或迁移性能通过。

## 9. 最终判定

**代码健康度：PASS。** 当前 HEAD 的自动化、审计可信度、覆盖率和静态资源边界达到既定门禁，0 open finding。

**Relay 安全边界：PASS。** CR-02、CR-05 与 HP-02 已关闭并通过全量 Go 测试。

**有线 iPhone 验收：BLOCKED（外部签名配置）。** 不是代码构建失败，不计为产品通过。

**商店发布：NOT READY。** 需先完成 UAT 真机矩阵、最终法律审阅及正式托管确认。
