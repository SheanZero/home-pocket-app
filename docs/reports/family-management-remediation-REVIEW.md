---
phase: family-management-remediation
reviewed: 2026-08-01T23:42:14Z
depth: deep
files_reviewed: 108
findings:
  p0: 0
  p1: 0
  p2: 0
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# 家庭管理 P0–P2 修复后第六轮最终独立深度复审

## 最终结论

**CLEAN — P0: 0 / P1: 0 / P2: 0。**

本轮重新审阅客户端家庭状态机、数据面与控制面同步、Avatar semantic staging、删除全部本地数据、Push 身份隔离、v8–v36 Drift 迁移，以及服务端成员资格、WebSocket、epoch/key rotation、owner transfer 和 000016 rollback。没有发现可复现的新增 P0–P2，F01–F23、R3、R4、R5 全部关闭。

## R5 闭环复核

### R5-P1-01：跨资源 wipe journal 与冷启动恢复 — 已关闭

#### 持久化与文件安全

- `FilePrivacyWipeJournalStore` 固定使用 `<Application Support>/home_pocket_privacy/wipe_journal_v1.json`；目录不在 Documents、Avatar staging、backup 或 secure-storage 清理范围内，不会被任何 wipe stage 提前删除。
- support root 必须是绝对、非 link 的真实目录；固定子目录必须位于 root 内且不能是 symlink/普通文件；journal 与 `.tmp` 只允许 regular-file 或 missing。
- journal 上限 4 KiB；只允许 `version/stage/updatedAtEpochMs/checksum` 四个字段；未知版本、阶段、字段、非法 size/type 和 checksum mismatch 全部 fail closed。
- 写入采用同目录 temporary file、`flush: true`、atomic rename；崩溃发生在 advance 前时保留上一安全 pending boundary，下一启动重放幂等阶段。
- journal 不含 identity、group、token、绝对路径、密钥或业务数据。

#### 状态机与崩溃边界

- 首次 destructive step 前持久化 `databasePending`。
- 每一阶段完成后才推进到下一 pending stage；若 callback 成功但 journal advance/response 丢失，旧 stage 保留并安全重做。
- 覆盖 `databasePending → filesPending → secureUserDataPending → settingsPending → memoryPending`；最终内存 reset 成功后才删除 journal。
- DB transaction 已提交但响应丢失会保持 `databasePending`，新实例重做原子、幂等 DB wipe。
- manual/startup use-case 实例通过固定 `coordinationKey` 共享 process-wide single-flight，避免同 isolate 内重复跨资源清理。
- journal 腐坏时不执行任何清理 step、不进入普通 App，保留证据并返回可重试初始化失败。

#### 启动顺序与真实接线

- `AppInitializer` 顺序为：master key → encrypted DB → `resumePending()` → fresh device identity → seed。
- pending wipe 失败会关闭 final container/database，返回 `InitFailureType.privacyWipe`；`bootWithInitializerForTesting` 只显示 failure shell，不创建 HomePocketApp、routes、sync 或 Push。
- production `main.dart` 真实注入 `pendingPrivacyWipeResumer`，并在构造 settings repository 前 pre-warm SharedPreferences。
- secure stage 保留安装 master key，确保崩溃恢复仍可打开 SQLCipher；只清除旧 device identity/keypair、PIN 与 recovery material。
- journal 最后删除后，AppInitializer 才生成新身份；manual success 通过 data-reset signal 生成新身份、seed 默认数据并刷新 provider。

#### 定向证据

- DB response-lost、所有 callback boundary、所有 journal-advance boundary、final delete failure、跨实例并发、no-journal no-op、corrupt fail-closed 均有确定性测试。
- 真实 DB + app-owned files + secure data + preferences 的“新进程恢复”集成测试通过。
- v36 实际表由显式 user/reference 分类全集覆盖；未知/缺失表 fail closed，DB 删除事务原子，`secure_delete=ON`，commit 后执行 WAL truncate。

### R5-P2-01：旧身份 Push generation 与权限策略 — 已关闭

#### 全入口统一策略

| 入口 | 第六轮结论 |
|---|---|
| Foreground Firebase/APNs | subscription 捕获 generation；入口前检查，统一 `_handleIncomingMessage` 再做 policy 前后双检。 |
| Opened-app | 捕获 generation；旧 subscription 在 wipe 时 cancel；消息与导航均复核 generation/policy。 |
| Initial message | 初始化 generation 固定；冷启动消息返回前后均不能越过 wipe revocation。 |
| Local notification tap | 初始化时绑定 generation；旧 callback 即使仍被调用也会 fail closed。 |
| Direct `handleMessage` | 使用当前 generation，仍走同一个 acceptance policy；direct 不制造 navigation side effect。 |
| Public `handleNotificationTap` | 同样走统一 policy；pending intent 额外记录 generation，take 时再次校验。 |

#### Revocation、竞态与恢复

- `clearIdentityBoundState()` 在第一个 await 前同步设置 revoked、递增 generation、清空 bound identity 与 pending navigation。
- 随后 await token/foreground/opened subscriptions cancel，并取消全部 identity-bound local notifications。
- `_accepts` 在异步 policy 前和返回后检查 generation，解决“callback 已开始读取 context，wipe 中途发生”的竞态。
- handler 之后可能产生 local notification/navigation 的分支再次检查 generation；若 notification show 与 wipe 交错，随后 cancelAll。
- Push lifecycle callback 进入 SyncEngine 的 tracked operation/scheduler；ClearAllData 同时 stop-and-wait SyncEngine，数据库 wipe 不会与旧 callback 写入交错。
- wipe 后无家庭期间保持 Push revoked 是正确的 fail-closed 状态；新身份执行 create/join/check 的 device registration 后，`registerCurrentToken()` 会重新初始化 subscriptions 并绑定新 device generation。

#### 家庭权限与兼容

- family 类型统一要求当前 device identity；payload 若带 `identityGeneration` 或 `targetDeviceId` 必须精确匹配。
- 除 metadata-free `group_key_requested` 外，必须提供当前本地 groupId，并由 repository 读取唯一 current group 与唯一 local member；local member role 必须与 group role 一致。
- join/pair approval 仅 active owner/admin + active local member 接受；普通 member、旧 group、removed/inactive 或 malformed payload 全部拒绝。
- pre-activation confirmation/reject/cancel/expire 允许 confirming/pending applicant 的合法生命周期，不会因 active-only gate 把合法消息全部拒绝。
- 可选 `controlRevision` 存在时严格解析且不能落后本地权威 revision；旧 Server 未携带该字段时保持协议兼容。
- `group_key_requested` 按 Server 合同保持 metadata-free，仅用于 wake authenticated durable-ledger fetch；旧 callback generation 仍拒绝，payload 本身不触发导航或使用 key material。
- 非 family type 不被 family policy 误拒；生产日志只输出 type/source/platform 和泛化错误，不输出 token、groupId、payload、identity 或密钥。

## R3/R4 闭环复核

| 历史 finding | 第六轮判定 | 证据 |
|---|---|---|
| R3-P1-01 单个坏 Avatar 阻断 drain/full sync | 已关闭 | per-entry materialize/poison isolation；permanent failure CAS removal；Full/Initial 不被坏头像阻断；精确 settle。 |
| R4-P1-01 同内容 Avatar 误删当前 blob | 已关闭 | content-addressed reuse + `wasCreated`；共享 reference critical section；当前 Profile + 全部 Avatar outbox DB 引用快照；ACK/supersede 后 reference-aware GC。 |
| R4-P1-02 删除全部数据范围不足 | 已关闭 | 全部 v36 user tables、outbox/inbound/control/queue/groups/members/shopping/profile/audit、app files、secure user data、prefs、memory、sync/WS 全接线；本地-only 三语文案一致。 |
| R4-P2-01 transaction failure 留 staging orphan | 已关闭 | 仅补偿本次新建且无 durable 引用的 blob；同 hash reuse 不删；cold-resume GC、retention、quota、oldest-first 与 process-crash orphan 覆盖。 |

## F01–F23 全量状态

| ID | 原始缺口 | 最终状态与证据 |
|---|---|---|
| F01 | pending 成员被提前激活 | CLOSED：权威 local-member status；pending/confirming/awaiting-key/active 分态。 |
| F02 | Push 未初始化/生命周期 callback 缺失 | CLOSED：启动前安装全部 handler，Push initialize 与 cold-start 路径覆盖；R5 generation 隔离已关闭。 |
| F03 | `groupExisted=false` 被当作 valid | CLOSED：解析 bool/groupId/member status；失效时清理本地 family 与 transport。 |
| F04 | WebSocket 未强制成员资格 | CLOSED：pending/active 授权边界、trusted proxy、连接 cap、移除终态关闭。 |
| F05 | 被移除成员仍拉密文且不轮换 key | CLOSED：active membership gate、epoch rotation、旧 epoch pull/ACK 拒绝与 queue cleanup。 |
| F06 | 账单 update/delete 不收敛 | CLOSED：revision/writer/content/tombstone 决胜，FullSync 包含 live state 与必要 tombstone。 |
| F07 | member_confirmed bootstrap 不可靠 | CLOSED：snapshot → targeted key pull → membership revalidate → local active → initial reconcile。 |
| F08 | reject/cancel/expire/reapply 缺失 | CLOSED：独立申请生命周期、定向 Push、清理 scheduler、reapply。 |
| F09 | 邀请按钮为空操作 | CLOSED：regenerate/revoke/share invite 与 owner gate。 |
| F10 | 创建取消产生孤儿家庭 | CLOSED：显式创建、超时后权威恢复、single-live-group 冲突映射。 |
| F11 | 家庭改名不传播 | CLOSED：control event/revision/digest、Push/WS invalidation、authoritative snapshot apply。 |
| F12 | Profile/Avatar 生产同步不可达 | CLOSED：Profile/Avatar semantic outbox、版本合并、immutable staging、drain/full-sync recovery。 |
| F13 | syncId 未传 Server 去重 | CLOSED：稳定外层 sync id、server 唯一约束与原子 replay。 |
| F14 | hasMore 未循环/lastSyncAt 不持久 | CLOSED：有界 pagination、no-progress/empty-page guard、成功后 group-scoped timestamp。 |
| F15 | 离线队列失败后静默删除 | CLOSED：durable dead letter、显式 retry/discard、attention UI、epoch cleanup barrier。 |
| F16 | 坏消息仍 ACK | CLOSED：durable inbound ledger/quarantine、transient 不 ACK、redelivery idempotent、resource limit。 |
| F17 | 恢复家庭没有 group-key 重发 | CLOSED：request/reseal ledger、owner/member recovery、epoch validation。 |
| F18 | Server 允许单设备多个 live 家庭 | CLOSED：DB 约束、create/join service guard、App 前置门禁与冲突恢复。 |
| F19 | Owner transfer/key rotation/安全离场缺失 | CLOSED：000014–000016、recipient-set/hash 校验、rotation coordinator、resume 与 control events。 |
| F20 | 自定义分类语义不同步 | CLOSED：shared category snapshot/tombstone、个人 archive/order/config 隔离、round-trip。 |
| F21 | 账单 photoHash 无可恢复内容 | CLOSED：协议明确 local-only availability，不发送伪恢复 hash；接收端一致。 |
| F22 | 控制面缺 revision/event/time | CLOSED：revision、eventId、occurredAt、actor/reason、digest reconciliation。 |
| F23 | private transaction 缺发送门禁 | CLOSED：producer/full-sync/receiver 三层 fail closed。 |

## 验证结果

### App

- `flutter analyze`：**No issues found**。
- 最终全仓 `flutter test --concurrency=1 -r compact`：**4303 passed / 11 skipped / 0 failed**（根 Agent 在全部补丁合并后执行）。
- 第六轮 journal、ClearAllData、AppInitializer/main、Push generation/policy、notification route 定向套件：**106 passed / 0 failed**。
- 家庭 sync application、repository、infrastructure、Widget 与 integration 广覆盖套件：**624 passed / 0 failed**。
- v8–v36 Drift migration 目录：**109 passed / 0 failed**。
- 全表 wipe、app-owned file symlink、secure-storage user-key boundary、sync stop-and-wait 补充套件：**47 passed / 0 failed**。

### Server

- `go test ./... -count=1`：全部 package 通过。
- `go test -race ./internal/service ./internal/repository ./internal/scheduler ./internal/middleware ./internal/config ./migrations -count=1`：全部通过。
- WebSocket handler 的 trusted-proxy、pending-auth、正常认证与 membership rotation 定向 race：全部通过。
- 000016 down migration 保留 recovery-only archive，逐行等值验证后才移除 active `member_rotation_key`；未发现新的授权、epoch、并发或 rollback 问题。

## 验证限制

- 未配置 `TEST_DATABASE_URL`，真实 PostgreSQL 的 000016 up/down round-trip 明确 SKIP；静态 migration test、sqlmock、Go 全套与 race 不能替代真实 PG。
- 未执行 iOS/Android 真机杀进程、APNs/FCM、后台 initial/opened delivery、文件保护和多设备 E2E UAT；确定性 process reconstruction 与 Push callback race 测试已通过。
- 全仓 Flutter suite 已在全部补丁合并后执行并通过；11 个既有 skip 保持原状。
- production-logging architecture/privacy 测试包含在全仓 suite 中并通过；另已静态复核 Push 日志点，未发现敏感字段输出。
- 工作树已有大量用户/其他 agent 变更；本轮只覆盖本报告，未修改 production/test，未 stage、commit、revert 或切换分支。

## 签署

在当前代码与上述环境限制下，家庭管理 remediation 可签署为：

**CLEAN — 所有历史 P0–P2 已关闭，未发现新的可复现 P0–P2。**

---

_Reviewed: 2026-08-01T23:42:14Z_
_Reviewer: gsd-code-review (inline sixth-pass; no-subagent constraint)_
_Depth: deep_
