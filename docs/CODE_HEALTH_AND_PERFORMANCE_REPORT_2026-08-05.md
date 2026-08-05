# Happy Pocket App 代码健康度与性能全面检查报告（修复后独立复审终版）

**复审日期：** 2026-08-05（Asia/Tokyo）

**代码审计基线：** `main` / `14db15f6` (`ci(deps): enforce analyzer 8 compatibility contract`)
**报告范围：** 2026-08-05 首轮报告中的 CR/WR、覆盖率、复杂度、构建链、依赖、隐私发布物及性能可测性。此后仅提交本报告本身。

**技术栈：** Flutter 3.44.0、Dart 3.12.0、Riverpod 3、Drift、SQLCipher。

> 这是对首轮报告的修复后独立复审，而不是把首轮风险静默删除。每项旧发现均保留审计轨迹，并明确标记为 `CLOSED`、`PARTIAL`、`EXTERNAL` 或 `BLOCKED`。其中 `EXTERNAL` 是仓外发布/服务端/法务/设备工作，不能被误读为 App 仓内仍开放的代码缺陷。

## 1. 最终结论

| 维度 | 评分 | 复审结论 |
|---|---:|---|
| 工程健康度 | **92/100** | 静态分析、代码生成、测试、覆盖率、死代码扫描和构建预检均为绿色 |
| 正确性与数据安全 | **90/100** | 首轮备份、恢复与 WebSocket 正确性问题均已在 App 内闭环并有回归测试 |
| 安全与隐私 | **85/100** | App 侧输入限制、nonce 签名和 PrivacyInfo 已落实；服务端 anti-replay 与最终隐私分类仍是外部发布门槛 |
| 架构与可维护性 | **89/100** | 高风险热点已拆分，复杂度总量下降；仍保留少量有意记录的维护性债务 |
| 性能与资源效率 | **83/100** | relay 限制、字体包体和性能测量 harness 已落实；尚无真机基线及经审阅阈值 |
| 发布就绪度 | **58/100** | **不具备发布条件**，原因仅为外部发布门槛，非 App 仓内 P0/P1/P2 开放缺陷 |

### 核心判定

- **App 仓内开放 P0/P1/P2：0。** 首轮所有 App 代码级 CR/WR 已关闭或被明确收敛为仓外依赖。
- **Release-ready：否。** 阻断原因是服务器协同、生产签名、商店素材/QA、隐私与日本法务复核、以及真机性能基线，不是未修复的 App 代码缺陷。
- **客户端不得先于 anti-replay 服务端发布。** App 已发送并签名 nonce，但服务端持久 nonce ledger 尚未获授权修改或部署，故 CR-05 状态为 `BLOCKED / EXTERNAL`。

## 2. 复审证据快照

| 检查 | 最终结果 |
|---|---|
| `flutter analyze` | **PASS**：0 issues |
| `dart run custom_lint --no-fatal-infos` | **PASS**：0 issues |
| 全量 `flutter test --coverage -r expanded` | **PASS**：4,321 passed / 12 skipped / 0 failed |
| 清洗 LCOV | **PASS**：26,960 / 31,171 = **86.49%** |
| 风险逐文件覆盖率 | **PASS**：15 / 15 文件均 ≥70%，0 missing，0 deferred；restore **93.62%**，websocket **94.76%** |
| 覆盖率/CI manifest 契约 | **PASS**：清单、LCOV 与 CI 不变量一致 |
| `build_runner` clean codegen | **PASS** |
| 依赖兼容性契约 | **PASS**：Analyzer 8 lane 已被明确守卫 |
| 未使用生产文件/声明扫描 | **PASS**：0 |
| Android arm64 profile 构建 | **PASS**：APK **73.6 MB**（仅 profile 产物，不与 release APK 比较） |
| iOS release `--no-codesign` | **PASS**：Runner.app **33.2 MB** |
| iOS release preflight | **PASS**：真实 Runner binary 不含 `integration_test` |
| Lucide 应用内字体 | **PASS**：bundled raw **14.3 KB** |
| iOS 隐私清单 | **PASS**：App 的 `PrivacyInfo.xcprivacy` 已被打包 |
| iOS 提交物料校验 | **PARTIAL / EXTERNAL**：1 blocker（0/30 最终截图）；另有 iPad 警告 |

## 3. 首轮发现的最终状态

### Critical findings（CR）

| ID | 首轮问题摘要 | 最终状态 | 复审结论与证据 |
|---|---|---|---|
| CR-01 | 多账本备份恢复会静默删除其他账本交易 | **CLOSED** | 全应用导出在一致工作单元中包含所有账本及交易；多账本 round-trip 回归测试通过。提交 `7362016c`。 |
| CR-02 | relay pull 在读取/解密前无响应与载荷限制 | **PARTIAL** | **App CLOSED**：使用流式读取，并在 JSON/base64/解密前限制 Content-Length、chunked body、单 payload、密文与明文。服务端的 pull page **总字节预算为 EXTERNAL**，须与 relay 仓协同。提交 `4fd817bc`。 |
| CR-03 | 同日第二次导出覆盖前一份备份 | **CLOSED** | UTC 毫秒 + 96-bit 随机 token 文件名、同目录临时文件、flush 与原子 rename，并覆盖碰撞场景。提交 `a9fa71c2`。 |
| CR-04 | Android release 使用 Debug signing | **PARTIAL** | **代码 CLOSED**：release 签名仅接受未入库 `key.properties` 或 CI secrets，缺失时 fail-closed，并拒绝 Debug 证书。生产 keystore/四项 secrets 与 signed AAB 为 **EXTERNAL**。提交 `b111d843`。 |
| CR-05 | relay 已签名请求可在时间窗内重放 | **BLOCKED / EXTERNAL** | **App 侧已完成** 256-bit `X-Request-Nonce`，且将 nonce 纳入 canonical signature。服务端持久 nonce ledger、原子 claim、TTL、冲突响应尚未获授权修改或部署；因此客户端**不可先于服务端发布**。提交 `4b00ba85`。 |
| CR-06 | 随包法律文档为草案并含占位信息 | **CLOSED** | 三语资产、iOS 发布快照及站点来源均已替换为运营方正式信息；草案/占位符/parity 测试通过。日本专业法务复核是 **EXTERNAL** 发布门槛，不再属于文档内容缺陷。提交 `9c989a8c`。 |

### Warning findings（WR）

| ID | 首轮问题摘要 | 最终状态 | 复审结论与证据 |
|---|---|---|---|
| WR-01 | 恢复未使用同步写屏障 | **CLOSED** | `RestoreBackupUseCase` 复用 `SyncEngine.suspendForLocalDataWipe`，等待同步任务、重置旧 outbox/queue/tracker，并仅恢复一次。清理失败时保持 sync paused 的 fail-closed 路径也已补齐。提交 `7a743a64`、`fcff1dc0`。 |
| WR-02 | SharedPreferences 与 Drift rollback 不一致 | **CLOSED（进程内）** | 在 prefs 失败和 DB commit 失败时均对全量旧设置做补偿；失败写入会抛错。进程被强杀期间的持久 journal 是后续增强项，不是当前进程内一致性缺陷。提交 `7e325217`。 |
| WR-03 | WebSocket lifecycle observer 可重复注册 | **CLOSED** | observer 注册/移除和相同身份连接复用均已幂等化；身份变化只执行一次连接切换。提交 `f9503e3a`。 |
| WR-04 | 旧连接异步认证可写入新 channel | **CLOSED** | 每个连接均使用 generation/channel guard；认证、回调、timer、reconnect 与 heartbeat 都验证连接代际。auth failure 的恢复路径亦已覆盖。提交 `ca82b725`、`ed483fe4`。 |

## 4. 覆盖率、构建链与依赖的收敛状态

| 首轮观察 | 最终状态 | 复审结果 |
|---|---|---|
| 逐文件覆盖率清单漂移，存在 106 missing 与 11 deferred | **CLOSED** | 清单替换为 15 个手写风险边界；15/15 均 ≥70%，missing/deferred 均为 0。提交 `11db5485`、`eb057753`。 |
| 加密数据库 testing helper 为生产侧未使用声明 | **CLOSED** | 已移至测试所需边界，生产声明扫描为 0。提交 `5b863b8f`。 |
| integration test plugin registrant 可能污染 release 构建 | **CLOSED** | clean preflight 固化为脚本/CI 检查，iOS registrant 隔离后真实 Runner binary 不含 `integration_test`。提交 `7d4154ee`、`ecf1736f`。 |
| codegen 输出需人工确认 | **CLOSED** | `build_runner` clean 生成与设置 provider 输出已复审。提交 `2671013e`。 |
| 依赖可升级性与 Analyzer 8 兼容性不透明 | **CLOSED（契约）** | 兼容 transitive 包已刷新，Analyzer 8 依赖契约由 CI 守卫。提交 `a261660a`、`14db15f6`。 |
| 大版本/原生工具链升级存在耦合风险 | **EXTERNAL / BACKLOG** | Riverpod/JSON/custom lint、Drift/codegen、file/share/package-info/win32、speech、SQLCipher/sqlite3、Flutter Built-in Kotlin 与 SQLCipher SwiftPM 必须在协调升级窗口、双平台 release 和真机 SQLCipher 验证中处理，不应逐包自动升级。 |

## 5. 可维护性与性能复审

### 5.1 复杂度变化

| 指标 | 首轮 | 复审 | 结论 |
|---|---:|---:|---|
| CC > 20 方法数 | 30 | **25** | 下降 5 |
| 方法 SLOC > 50 数 | 207 | **208** | 接近持平；热点已转为较小的有边界方法 |
| nesting > 5 方法数 | 2 | **1** | 下降 1 |

已拆分的六个首轮热点如下；数值为复审后的 CC / SLOC：

| 热点 | 复审值 | 结果 |
|---|---:|---|
| `CheckGroupUseCase.execute` | **5 / 20** | CLOSED |
| `SyncAvatarUseCase.handleAvatarSync` | **4 / 30** | CLOSED |
| `RefreshGroupSnapshotUseCase.execute` | **12 / 52** | CLOSED（仍保留必要业务分支） |
| `CreateGroupUseCase.execute` | **8 / 37** | CLOSED |
| `ShoppingItemFormScreen.build` | **1 / 9** | CLOSED |
| `GroupManagementScreen._buildGroupContent` | **1 / 18** | CLOSED |

同步/群组拆分提交：`dc0e5365`；家庭 UI：`3ff79340`；购物清单 UI：`ff5e670f`。仍存在的私有辅助方法热点属于后续维护性工作，不构成首轮报告中的开放 P0/P1/P2。

### 5.2 包体积与构建产物

- Android **arm64 profile APK：73.6 MB**。这是 profile 产物，不能与早期 release APK 直接比较，也不应作为商店下载体积。
- iOS **release / no-codesign Runner.app：33.2 MB**。
- Lucide 已从六个 variable-weight 字体替换为最小静态子集；应用实际 bundled 字体 raw **14.3 KB**。提交 `cc03e64a`。
- 已有 Play App Bundle/生产签名后，仍应以 signed AAB 的 ABI split 结果复测商店下载体积。

### 5.3 可重复性能测量

性能 harness 已加入（提交 `f7859aa6`），覆盖：生产 SQLCipher 数据库下 1k/10k transaction（可显式启用 50k）、5 个账本、查询/写入、备份形态 JSON、近 2 MiB relay page 解析、frame build/raster/total、jank 和 RSS，以及 JSON P50/P95/P99 输出。

**状态：EXTERNAL。** 尚未在设备上运行，故没有可采信的真机冷启动、帧、RSS、SQLCipher I/O 或能耗数据；性能阈值也尚未由产品/工程审阅并设定。harness 的存在不等同于已经满足性能目标。

## 6. 隐私与 iOS 发布物

- `ios/Runner/PrivacyInfo.xcprivacy` 已随 Runner 打包，声明 app 自身的追踪与 Required Reason API 情况。提交 `51919830`。
- 三语 Photo Library 使用说明已与选择照片功能对应；未声明不存在的 add-only 权限。
- iOS release materials validator 当前仅保留 **1 个 blocker：最终截图 0/30**，并提示需完成 **iPad 13-inch** QA/素材检查。App Review 联系人与最低 iOS 15 信息已更新（`3ec42edc`）。
- 最终 Archive Privacy Report，以及 E2EE 金融数据在商店隐私表中的分类，需要运营/法务确认，属于 **EXTERNAL**。

## 7. 修复提交审计轨迹

| 提交 | 作用 |
|---|---|
| `7362016c` | CR-01 多账本备份数据集修复 |
| `4fd817bc` | CR-02 App relay pull 限制 |
| `a9fa71c2` | CR-03 唯一导出与原子写入 |
| `b111d843` | CR-04 生产签名 fail-closed |
| `4b00ba85` | CR-05 App nonce 签名准备 |
| `7a743a64`, `fcff1dc0` | WR-01 恢复同步屏障与失败保持暂停 |
| `7e325217` | WR-02 跨存储补偿 |
| `f9503e3a`, `ca82b725`, `ed483fe4` | WR-03/WR-04 WebSocket 生命周期、代际与认证恢复 |
| `5b863b8f`, `11db5485`, `eb057753` | 死代码与覆盖率门禁收敛 |
| `dc0e5365`, `3ff79340`, `ff5e670f` | 同步与 UI 热点拆分 |
| `cc03e64a` | Lucide 字体裁剪 |
| `a261660a`, `14db15f6` | 依赖刷新与 Analyzer 8 契约 |
| `51919830`, `3ec42edc` | iOS PrivacyInfo 与审核物料元数据 |
| `7d4154ee`, `ecf1736f`, `2671013e` | clean preflight、iOS registrant 隔离与 codegen 输出 |
| `f7859aa6` | 可重复设备性能基线 harness |

## 8. 仅剩的外部发布行动清单

| 优先级 | 外部行动 | 完成标准 |
|---|---|---|
| 1 | relay 服务端 nonce ledger 与 pull page 总字节预算 | 服务端原子拒绝重复 nonce（TTL/冲突响应/故障处理）并限制总 page bytes；完成客户端-服务端集成测试后再发布客户端 |
| 1 | Android 生产 keystore/secrets 与 signed AAB | 配置 upload key 及四项 CI secrets，验证非 Debug 证书，构建并检查 signed AAB |
| 1 | iOS 最终截图与 iPad QA | 补齐 30 张最终截图，并完成 iPad 13-inch 审核素材/功能 QA |
| 1 | 隐私与法律最终复核 | 完成 Archive Privacy Report、E2EE 金融数据分类确认及日本专业法务复核 |
| 2 | 真机性能基线 | 在明确授权和指定设备后运行 harness，记录结果并审阅/设定阈值 |
| 3 | 协调依赖与工具链升级 | 在独立升级窗口完成原生/代码生成/SQLCipher 联动验证，不做逐包自动升级 |

## 9. 复审结论

首轮报告提出的 App 仓内正确性、稳定性、资源边界、覆盖率、代码生成、构建链、字体包体和隐私发布物问题，已逐项由独立执行工作闭环并复测。当前代码质量门禁为绿色，App 仓内没有开放的 P0/P1/P2。

仍不建议将当前版本直接标记为 release-ready：这不是因为 App 代码仍含已知 blocker，而是因为安全协议必须先完成服务端协同、生产签名和商店交付物尚未就绪、法务/隐私最终声明需要责任方确认，并且尚未取得真机性能数据与经审阅阈值。

---

_本终版综合独立复审、Flutter/Dart 静态与动态门禁、LCOV 风险清单、代码生成、构建产物和 iOS 发布物校验生成。审计代码基线为 `14db15f6`；后续仅本报告提交会改变 HEAD。_
