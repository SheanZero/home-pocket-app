# Happy Pocket App 代码健康度与性能全面检查报告（初版）

**审计日期：** 2026-08-06（Asia/Tokyo）  
**App 基线：** `main` / `707eb0dd`  
**服务器核验基线：** `/Users/xinz/Development/home-pocket-server` / `main` / `306dff9`  
**用途：** 记录修复前事实、分类和验证基线；后续问题按严重级别逐项串行修复，再发布独立复审终版。

## 1. 执行摘要

本轮没有发现 P0，也没有新的已证实数据损坏、明文敏感日志或 Drift 查询正确性缺陷。全量测试、覆盖率、Analyzer、custom_lint、import_guard 和两轮代码生成均通过。

但“自动化全绿”尚不能等同于 release-ready：代码生成门禁会漏掉未追踪生成文件；Riverpod lint 当前不可采信；重复代码审计仍是固定空结果；WebSocket 控制面缺少解析前资源限制；设备 E2E SDK pin 已落后；有线 iPhone 验收缺少隔离应用身份。Relay 服务端 nonce ledger 已完成，pull 总字节预算仅余一个精确边界错误。

| 维度 | 初版结论 |
|---|---|
| 正确性与数据安全 | 无新增 P0；全量回归绿色 |
| 安全与资源边界 | REST pull 客户端有限制；WebSocket 控制帧仍有未设防解析入口 |
| 工具链可信度 | Analyzer/import_guard 真实生效；Riverpod/duplication 两项存在假绿或未执行 |
| 可维护性 | 死代码 0、层级违规 0；复杂度总量与 2026-08-05 复审一致 |
| 性能 | 已有可重复真机 harness；因隔离 Bundle ID 未完成，本轮尚未安全执行有线 iPhone 基线 |
| 发布就绪度 | 否；必须先关闭本报告 P1/P2 并完成隔离真机验收 |

## 2. 工具链与设备

| 项目 | 结果 |
|---|---|
| Flutter | 3.44.8 Stable，revision `058e0af2c2` |
| Dart / DevTools | 3.12.2 / 2.57.0 |
| Xcode / CocoaPods | 26.2 / 1.16.2 |
| 有线设备 | `“Xin Zhang”的 iPhone`，iOS 26.5；设备标识仅在本机命令中使用，不写入报告 |
| 真机策略 | 仅有线 iPhone；不得覆盖生产 Bundle ID、生产容器或生产 Keychain |

## 3. 自动化证据快照

| 检查 | 初版结果 |
|---|---|
| `scripts/verify_codegen_reproducibility.sh` | PASS：两轮生成，第二轮 0 输出；但 HP-01 证明门禁遗漏未追踪生成文件 |
| `flutter analyze --no-fatal-infos` | PASS：0 issues |
| `dart run custom_lint --no-fatal-infos` | PASS：0 issues |
| import_guard 真实负样例 | PASS：非法 package import 被拒绝并清理 |
| 全量 `flutter test --coverage -r expanded` | PASS：4,361 passed / 12 skipped / 0 failed |
| 清洗 LCOV | 26,960 / 31,171 = **86.49%** |
| 高风险逐文件覆盖率 | 15/15 ≥70%；0 missing、0 deferred |
| 死代码扫描 | 0 findings |
| 层级扫描 | 0 findings |
| 复杂度 | CC>20：25；SLOC>50：208；nesting>5：1 |
| Provider 扫描 | 结果不可采信：上游 Riverpod analyzer plugin 未实际运行 |
| 重复代码扫描 | 未运行：当前实现是固定空 findings 的 stub |

## 4. Audit-Fix 分类

| ID | 问题 | 严重级别 | 分类 | 初版状态 |
|---|---|---:|---|---|
| HP-01 | 代码生成门禁忽略未追踪 `.g.dart` / `.freezed.dart` / l10n 输出 | P1 | auto-fixable | OPEN |
| HP-02 | Relay pull 在 `hasMore=false` 精确预算边界多 1 字节并返回 500 | P1 | auto-fixable（server） | OPEN |
| HP-03 | 有线 iPhone 验收没有隔离 Bundle ID/App ID、容器、Keychain 与测试配置 | P1 | auto-fixable（用户已选择隔离方案） | OPEN |
| HP-04 | WebSocket 控制消息在 `jsonDecode` 前没有长度、深度和 `data` 预算 | P2 | auto-fixable | OPEN |
| HP-05 | `device-e2e.yml` 仍固定 Flutter 3.44.0，而候选基线为 3.44.8 | P2 | auto-fixable | OPEN |
| HP-06 | Riverpod lint 兼容失败会产生假绿，且缺少仓库自有 Provider 负向合同 | P2 | auto-fixable（安全 hold + owned guards） | OPEN |
| HP-07 | duplication audit 固定输出 0，报告会把“未执行”误写成“无重复” | P3 | auto-fixable | OPEN |

### HP-01 — 未追踪生成文件可绕过门禁

- 位置：`scripts/verify_codegen_reproducibility.sh:16-33`、`.github/workflows/audit.yml`。
- 证据：`git diff --exit-code` 不报告未追踪文件；生成文件清单又在第一次生成前由 `git ls-files` 固定。
- 影响：新增生成输入后，CI 工作区内 Analyzer 可通过，但漏提交生成产物的干净 checkout 会失败。
- 完成标准：两轮生成后同时拒绝 tracked diff 与 untracked generated output，并用隔离负样例证明。

### HP-02 — Relay pull 精确边界 off-by-one

- 位置：服务器 `internal/handler/pull_page.go:12-64`。
- 证据：`hasMore:false` suffix 为 19 字节，`true` 为 18 字节；添加消息时仅按较短的 true 预算。
- 影响：1–99 条消息恰好填满 true 边界且实际没有下一页时，最终 false 响应超预算，handler 返回 HTTP 500。
- 完成标准：预算始终预留更大的最终 envelope；补 `hasMore=false` 精确边界和超限回归。

### HP-03 — 真机验收身份未隔离

- 位置：`ios/Runner.xcodeproj/project.pbxproj`、iOS 配置/entitlements、设备测试脚本与合同。
- 证据：Debug/Profile/Release 当前都使用生产 Bundle ID；没有专用 UAT scheme/config。
- 影响：真机安装、清理、备份恢复或 Keychain 测试可能覆盖/读取现有生产应用数据。
- 完成标准：新增 additive 测试身份，静态证明 Bundle ID、container、Keychain、通知/Firebase 和测试密钥均与生产隔离，再运行有线 iPhone。

### HP-04 — WebSocket 控制消息缺少资源预算

- 位置：`lib/infrastructure/sync/websocket_service.dart:216-267`。
- 证据：对未限制的 `raw` 直接 `jsonDecode`，随后复制任意 `data` Map。
- 影响：异常或恶意 relay frame 可造成主 isolate JSON 解析阻塞和显著内存分配。
- 完成标准：解析前限制消息字节数，解析后限制嵌套深度、集合/字段规模与 `data` 预算；超限时断连且不派发事件。

### HP-05 — Device E2E SDK 漂移

- 位置：`.github/workflows/device-e2e.yml:46,79`。
- 证据：设备 lane 使用 3.44.0，Stable/兼容基线使用 3.44.8。
- 影响：设备 E2E 无法证明发布候选 SDK 的原生与插件行为。
- 完成标准：所有发布/设备 lane 从同一可验证基线读取或被合同测试锁定为 3.44.8。

### HP-06 — Provider 审计假绿

- 位置：`analysis_options.yaml`、`scripts/verify_tooling_guards.dart`、Phase 58 验证材料。
- 证据：Flutter 3.44.8 下 `riverpod_lint 3.1.0` 无法解析 analyzer plugin；隔离的 3.1.8 虽可启动，却拒绝 `analysis.setContextRoots` 并静默返回 0 diagnostics。
- 影响：ProviderScope、生命周期和重建相关错误缺少可执行反证。
- 决策：保留单一 Analyzer 8/custom_lint/import_guard 生产图；显式 hold 上游插件，CI 检测静默插件失败，并以仓库自有负向架构测试覆盖关键 Riverpod 不变量。

### HP-07 — 重复代码审计未执行

- 位置：`scripts/audit/duplication.dart`。
- 证据：实现固定写入空 findings，工具来源却标为 `dart_code_linter`。
- 影响：重复安全分支或修复漂移可能被报告成 0 findings。
- 完成标准：要么接入可重复检测器和 fixture，要么明确输出 `not_run` 并使聚合报告降级，禁止假绿。

## 5. Relay 服务端已关闭项

服务端 CR-05 已经关闭，不再列为开放问题：

- `device_id + nonce` 持久复合主键和过期索引已存在；
- PostgreSQL 使用 `INSERT ... ON CONFLICT ... WHERE expires_at <= NOW() RETURNING` 原子 claim；
- 重放返回 409，ledger 故障 fail-closed 返回 503；
- nonce 纳入签名，非法签名不会消耗 nonce；
- 定向 auth/repository/scheduler/migration 测试通过。

仍建议后续增加真实 PostgreSQL 并发双 claim 与重启持久性 E2E，但这不是当前实现缺失。

## 6. 串行修复顺序

1. HP-01 代码生成未追踪产物门禁。
2. HP-02 服务端 pull 精确预算边界。
3. HP-05 Device E2E SDK pin 一致性。
4. HP-04 WebSocket 资源限制。
5. HP-06 Riverpod 安全 hold 与 owned guards。
6. HP-07 duplication 未执行语义。
7. HP-03 隔离 UAT 身份与有线 iPhone 验收。

每项由独立 agent 单独修改，完成定向测试和原子提交后才开始下一项。最终再运行两轮 codegen、Analyzer、custom_lint、完整测试/覆盖率、审计脚本、iPhone device E2E 与性能基线，并产出修复后终版报告。
