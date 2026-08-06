# SQLCipher Native Assets 升级、健康度与性能报告

日期：2026-08-06

工作树：`main`

验证工具链：Flutter 3.44.8 / Dart 3.12.2

## 结论

旧的 `sqlcipher_flutter_libs` 分发路径已替换为 sqlite3 3.x Native
Assets。当前受验证组合为 Drift 2.34.0、drift_dev 2.34.0、sqlite3
3.5.1、SQLCipher 4.17.0。真实 SQLCipher 4.10.0 数据库夹具已在 Android
API 36 模拟设备、iOS 模拟器及 USB iPhone 真机上由 4.17 原地打开，完成
v35→v36 迁移、写入、关闭后重开并再次读取。

所有已发现的代码、工具链和审计问题均已修复；Analyzer、import_lint、
完整测试、覆盖率、依赖基线、审计和复杂度扫描均为绿色。当前没有开放的
代码审计问题。由于本次没有连接 Android 实体机，Android 侧的运行证据来自
API 36 arm64 模拟设备；若商店发布流程要求 Android 实体机证据，应在发布前
在实体机重跑同一个集成测试。

## 依赖与分发结果

| 项目 | 升级后 | 决策 |
|---|---:|---|
| Drift / drift_dev | 2.34.0 | 同版本锁定，避免生成器漂移 |
| sqlite3 | 3.5.1 | 由 `^3.3.1` 解析，使用 Native Assets |
| SQLCipher | 4.17.0 | `hooks.user_defines.sqlite3.source: sqlcipher` |
| analyzer | 12.1.0 | 与 import_lint 2.0.0 的当前兼容线 |
| riverpod_lint | 3.1.4 | 已启用 analysis-server plugin |
| import_lint | 2.0.0 | 替代旧 custom_lint/import_guard host |

Drift 2.34.1+、Riverpod 3.4.x 等候选会把分析器推到 analyzer 13，而当前
import_lint 2.0.0 仍在 analyzer 12 兼容线，因此没有为了追逐次版本而破坏
Analyzer/架构门禁。该 hold 已写入稳定依赖基线，退出条件是整个 lint、生成器
和运行时组合能够一起升级并通过全套验证。

已删除：

- `sqlcipher_flutter_libs` 依赖及旧的显式 native loader；
- Android loader override；
- iOS Podfile 中移除 `-l"sqlite3"` 的 strip；
- `custom_lint` 与 `import_guard_custom_lint` 活跃依赖和 CI 命令。

## 真实 4.10 夹具与安全断言

夹具 `integration_test/fixtures/sqlcipher_4_10_v35.db` 来自仓库升级前的
SQLCipher 4.10.0 amalgamation，源数据库 `journal_mode=delete`，SHA-256：

`58d6f6f1f40e636323e13d40cf013cd9e541a8eb892f60b507cd898e2328c004`

生产打开路径及设备测试同时断言：

- `PRAGMA cipher_version` 匹配 `4.17.x`；实际 Native Asset 二进制为 4.17.0；
- `PRAGMA cipher_status == 1`；
- `sqlite_master` 可读取且包含 schema；
- 数据库文件头不等于 `SQLite format 3\0`；
- v35→v36 迁移后的既有记录和值正确；
- 4.17 写入后关闭，冷重开仍可读取新值；
- 明文 SQLite 文件在打开 SQLCipher 前即被拒绝。

## 平台验证矩阵

| 环境 | Native Assets | 4.10→4.17 迁移/写入/重开 | `journal_mode` |
|---|---|---|---|
| macOS host test | PASS | PASS | 非发布设备证据 |
| Android 16 / API 36 arm64 模拟设备 | PASS | PASS | `delete` |
| iOS 26.2 模拟器 | PASS | PASS | `delete` |
| iPhone iOS 26.5 USB 真机 | PASS | PASS | `delete` |

iOS Profile App 内嵌 `Frameworks/sqlcipher.framework/sqlcipher`；其动态依赖
只有 Apple Foundation、Security、CoreFoundation 和 libSystem，不依赖系统
`libsqlite3`。Android APK 内含 `lib/arm64-v8a/libsqlcipher.so`。因此旧 Android
loader override 和 iOS `-lsqlite3` strip 均已删除，并由最终平台测试证明不再
需要。

观察到的设备均为 `journal_mode=delete`，未触发 WAL 风险条件。SQLCipher
4.10 只保留为历史升级回归夹具，不是应用公开发布的运行时或长期发布基线；
公开运行时基线是 SQLCipher 4.17.x。

## 健康度与修复

升级过程额外发现并修复了三项真实问题：

1. Riverpod 3.3.2 会在 onboarding 的异步语言写入期间回收自动释放的
   `localeProvider`，导致 `UnmountedRefException`。语言是应用级持久状态，
   已改为明确 `keepAlive`，相关 30 项测试恢复通过。
2. 审计合并器仍只接受旧 `import_guard` 的 `tool_source`，无法合并新的
   import_lint 分片。合并契约、schema、测试和文档已协同升级；61 项合并器
   事务/崩溃恢复测试通过。
3. 新 Drift 对一处字符串外键约束给出生成警告。已改用类型化
   `.references(Merchants, #id)`，重新生成后警告消失。

最终健康门禁：

| 检查 | 结果 |
|---|---|
| `flutter analyze` | PASS，0 issues |
| `dart run import_lint` | PASS，0 issues |
| 依赖兼容性/Native Assets 基线 | PASS，0 error / 0 warning |
| 完整 `flutter test --coverage` | PASS，4537 passed / 12 skipped |
| 全局手写代码行覆盖率 | 87.16%（27205 / 31213） |
| 70% 风险文件覆盖率门禁 | PASS，15 / 15，0 缺失 |
| 分层/死代码/Provider 审计 | 0 / 0 / 0 findings |
| 重复代码审计 | 6 条既有接受项，0 open |
| 合并审计目录 | 63 closed / 8 accepted / 0 open |
| dart_code_linter metrics | PASS，534 files，0 issues |
| tooling negative fixtures | PASS |

## Profile 性能基线

发布参考数据来自 USB iPhone、iOS 26.5、Profile 构建、1000 条交易、12 次
SQLCipher 查询/写入重复：

| 指标 | p50 | p95 |
|---|---:|---:|
| SQLCipher 100-row page query | 0.502 ms | 0.634 ms |
| SQLCipher write transaction | 0.879 ms | 1.460 ms |
| 近 2 MiB relay page parse | 8.372 ms | 11.170 ms |
| frame build | 0.269 ms | 6.837 ms |
| frame total | 1.912 ms | 89.429 ms |

帧样本为 17，其中 1 帧超过 16.67 ms（5.88%），来自合成滚动的小样本；
单个 raster 峰值为 89.424 ms。SQLCipher、JSON 物化和 relay 解析均无新增
性能回归信号。该 harness 不测冷启动/TTI，也不应从进程内集成测试推断启动
性能；后续发布性能趋势应在同一型号真机和相同 profile workload 上比较。

## 发布判定

Native Assets 迁移可以合入。发布前只需按团队设备矩阵补齐 Android 实体机
的同测试证据（如果该证据是发布流程的硬性要求）；无需恢复 SQLCipher 4.10
运行时、旧 loader override 或 iOS sqlite strip。
