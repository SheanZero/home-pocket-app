# Happy Pocket App / Relay 代码健康度与性能全面检查报告（终版）

日期：2026-08-06（Asia/Tokyo）

App 审计基线：`main` / `55c70b7`

Relay 审计基线：`/Users/xinz/Development/home-pocket-server` / `main` / `ea9161f`

历史修复前事实：`docs/CODE_HEALTH_AND_PERFORMANCE_REPORT_2026-08-06_INITIAL.md`

SQLCipher 专项证据：`docs/SQLCIPHER_NATIVE_ASSETS_UPGRADE_REPORT_2026-08-06.md`

## 结论

本轮完成 App 静态分析、四路审计、依赖/Native Assets 兼容性、完整测试与覆盖率
证据复核、同步协议回归、SQLCipher 真机迁移和 Profile 性能检查，并对 Relay 服务端
追加全量安全、竞态、资源上限、依赖与热点性能审计。

App 审计目录保持 **63 closed / 8 accepted / 0 open**；Relay 新发现的 6 个可复现
问题全部修复并原子提交。最终两个工作区都没有未提交代码，Analyzer、测试、race、
vet/staticcheck、漏洞扫描和发布构建均为绿色。

代码健康度判定为 **PASS**。商店发布仍需完成法律材料最终审阅、正式托管 URL/DNS/TLS
确认；若团队把 Android 实体机列为硬门禁，还需在实体机重跑已通过模拟器的同一
SQLCipher 迁移测试。这些是外部发布验收，不是未修代码缺陷。

## App 最终门禁

| 检查 | 结果 |
|---|---|
| `flutter analyze` | PASS，0 issues（本轮重跑） |
| import/layer audit | PASS，0 findings（本轮重跑） |
| dead-code audit | PASS，0 findings（本轮重跑） |
| Provider contract | PASS，0 findings（本轮重跑） |
| duplication audit | 6 条现场 observation，全部映射到既有 accepted 项；0 open |
| 依赖兼容矩阵 | PASS，0 error / 0 warning（本轮重跑） |
| App/Relay 同步契约定向测试 | PASS，134 项（本轮重跑） |
| 完整 `flutter test --coverage` | PASS，4,537 passed / 12 skipped（同一 App HEAD 的已验证证据） |
| 全局手写代码覆盖率 | 87.16%（27,205 / 31,213） |
| 风险文件覆盖率门禁 | PASS，15 / 15 ≥70%，0 missing |
| audit catalogue | 63 closed / 8 accepted / 0 open |

当前项目不依赖 `custom_lint`。有效静态门禁是 Flutter Analyzer、import_lint、
Riverpod analysis-server plugin 合同和仓库自有 Provider 负向合同；因此
`dart run custom_lint` 不属于当前工具链，也不作为失败项。

## SQLCipher / Native Assets

旧 `sqlcipher_flutter_libs` 分发已由 sqlite3 3.x Native Assets 替代。受验证组合为：

- Drift / drift_dev 2.34.0；
- sqlite3 3.5.1；
- SQLCipher 4.17.0；
- `hooks.user_defines.sqlite3.source: sqlcipher`。

真实 SQLCipher 4.10.0 v35 夹具已由 4.17 在 Android API 36 arm64 模拟器、iOS
模拟器和 USB iPhone 真机原地打开，完成 v35→v36 迁移、写入、关闭和冷重开。
各平台均断言 `cipher_version == 4.17.x`、`cipher_status == 1`、`sqlite_master`
可读且文件头不是普通 SQLite。设备读取的 `journal_mode` 均为 `delete`，没有触发
WAL 长期基线风险；4.10 只作为历史回归夹具，公开运行时基线是 4.17.x。

Android APK 使用 `libsqlcipher.so`，iOS App 内嵌 `sqlcipher.framework` 且不链接系统
libsqlite3，因此旧 Android loader override 与 iOS `-lsqlite3` strip 已删除。

`pub outdated` 显示当前锁定包均未被撤回、也未命中 advisory。Drift 2.34.3、
Riverpod 3.4.x 等更新会改变已验证的 analyzer/codegen/lint 依赖图；在没有安全修复
需要时，本轮保留已完成真机验证的 2.34.0 同版本组合，不做无收益的补丁追逐。

## App Profile 性能

环境：USB iPhone、iOS 26.5、Profile、1,000 条交易、12 次 SQLCipher 重复。

| 指标 | p50 | p95 |
|---|---:|---:|
| SQLCipher 100-row page query | 0.502 ms | 0.634 ms |
| SQLCipher write transaction | 0.879 ms | 1.460 ms |
| 近 2 MiB relay page parse | 8.372 ms | 11.170 ms |
| frame build | 0.269 ms | 6.837 ms |
| frame total | 1.912 ms | 89.429 ms |

17 个帧样本中 1 帧超过 16.67 ms，来自合成滚动小样本；SQL 查询、写入、relay
解析和 build p95 均没有回归信号。该 harness 不测冷启动 TTI，帧结果只能用于同机、
同 workload 趋势比较，不能替代发布版长期性能监控。

## Relay 问题闭环

| ID | 级别 | 结果 | 提交 |
|---|---|---|---|
| F-SRV-01 | High | 修复异步 handler/sqlmock 竞态，全量 race 归零 | `9677b3e` |
| F-SRV-02 | Critical | 18 个可达漏洞归零，Go/Docker 升到 1.26.5，依赖协同升级 | `b2d23b2` |
| F-SRV-03 | High | 限流缓存增加 10,000 项上限、O(1) LRU 和 15 分钟过期 | `ecaebf9` |
| F-SRV-04 | High | Firebase 改用 service-account 类型受限内存凭据 | `9c24851` |
| F-SRV-05 | Medium | `last_seen_at` 写入按分钟节流，后台 DB 触达限制 2 秒 | `780346a` |
| F-SRV-06 | High | FCM/APNs 统一 10 秒截止期，APNs 支持 context 取消 | `3d03521` |

Relay 终验：`go test -race ./...`、`go vet`、`staticcheck`、`govulncheck`、
`go mod verify`、`go mod tidy -diff`、Linux amd64/arm64 无 CGO 构建全部 PASS。
`govulncheck` 最终为 0 个代码可达漏洞。全模块覆盖率 42.2%，核心 `internal/`
覆盖率 60.8%；auth 82.0%，middleware 89.0%。详细报告见服务端
`docs/HEALTH_AND_PERFORMANCE_REPORT_2026-08-06.md`。

## Relay 性能基线

环境：Apple M4 Max、Go 1.26.5、darwin/arm64。

| 热点 | 结果 | 分配 |
|---|---:|---:|
| Ed25519 验签 | 29.035 µs/op | 272 B，3 allocs |
| 2 MiB 请求哈希/签名消息构造 | 0.689 ms/op，3.05 GB/s | 273 B，7 allocs |
| 100 条 pull JSON 组页 | 0.115 ms/op | 286,942 B，509 allocs |
| 限流器已有身份命中 | 37.52 ns/op | 0 B，0 allocs |

热点结果相对于 15 秒客户端超时和服务端速率限制有充分余量，未发现需要继续修改算法
的回归信号。它不代表生产 PostgreSQL 或 FCM/APNs 网络端到端延迟。

## 最终判定

- **App 代码健康度：PASS。** 0 open finding，完整测试与覆盖率门禁已通过。
- **数据库升级与设备验证：PASS。** SQLCipher 4.10→4.17 迁移、写入、冷重开及安全断言通过。
- **Relay 健康度与安全：PASS。** 6 个问题全部关闭，race/static/vulnerability/build 全绿。
- **性能：PASS（当前基线）。** 未检测到数据库、relay 解析、鉴权或服务端组页回归。
- **商店发布：条件未齐。** 法律最终审阅、正式 URL/DNS/TLS 与团队要求的 Android 实体机证据仍是外部发布门禁。
