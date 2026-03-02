# Family Sync PRD (简易版)

**模块:** MOD-003 家庭同步
**版本:** Draft v0.1
**日期:** 2026-03-01
**目的:** 基于现有 UI 实现和服务器 API 接口，梳理 Family Sync 核心功能与待修改项

---

## 1. 产品定位

让家庭成员（2-N人）共享一本账本，实现跨设备的安全记账同步。

**核心价值:**
- 邀请码配对，无需面对面
- 端到端加密，服务器零知识
- 离线优先，网络恢复自动同步
- CRDT 保证并发编辑零冲突

---

## 2. 用户角色

| 角色 | 说明 |
|------|------|
| Owner (群主) | 创建群组的设备，可确认成员、移除成员、解散群组、刷新邀请码 |
| Member (成员) | 通过邀请码加入群组，可退出群组 |

---

## 3. 核心功能清单

### 3.1 设备配对 (Pairing)

| # | 功能 | 现有实现 | 状态 |
|---|------|----------|------|
| P1 | Owner 创建群组，获取 6 位邀请码 + QR | `CreateGroupUseCase` → `POST /group/create` | ✅ 已实现 |
| P2 | Member 输入邀请码加入 | `JoinGroupUseCase` → `POST /group/join` | ✅ 已实现 |
| P3 | Owner 确认 Pending 成员 | `ConfirmMemberUseCase` → `POST /group/confirm` | ✅ 已实现 |
| P4 | 邀请码 10 分钟过期 | 服务器端控制 | ✅ 服务器已实现 |
| P5 | 刷新邀请码 | `RegenerateInviteUseCase` → `POST /group/{id}/invite` | ✅ 已实现 |
| P6 | QR 码扫描加入 | `PairCodeDisplay` 显示 QR | ⚠️ UI 有展示，但缺少扫描入口 |
| P7 | 配对成功推送通知 | `PushNotificationService` | ⚠️ 基础架构有，未集成 |

### 3.2 群组管理 (Group Management)

| # | 功能 | 现有实现 | 状态 |
|---|------|----------|------|
| G1 | 查看群组信息 & 成员列表 | `PairManagementScreen` | ✅ 已实现 |
| G2 | Owner 移除成员 | `RemoveMemberUseCase` → `POST /group/{id}/remove` | ✅ 已实现 |
| G3 | Member 退出群组 | `LeaveGroupUseCase` → `POST /group/{id}/leave` | ✅ 已实现 |
| G4 | Owner 解散群组 | `DeactivateGroupUseCase` → `DELETE /group/{id}` | ✅ 已实现 |
| G5 | 查看同步状态 | `SyncStatusBadge` + `SyncStatusNotifier` | ✅ 已实现 |
| G6 | 设置页入口 | `FamilySyncSettingsSection` | ✅ 已实现 |
| G7 | Home 页邀请 Banner | `FamilyInviteBanner` | ✅ 已实现 |

### 3.3 数据同步 (Data Sync)

| # | 功能 | 现有实现 | 状态 |
|---|------|----------|------|
| S1 | 推送同步数据 | `PushSyncUseCase` → `POST /sync/push` | ✅ 已实现 |
| S2 | 拉取同步数据 | `PullSyncUseCase` → `GET /sync/pull` | ✅ 已实现 |
| S3 | 完整同步周期 | `FullSyncUseCase` (push→pull→reconcile) | ✅ 已实现 |
| S4 | 离线队列 | `SyncQueueManager` + `SyncQueue` 表 | ✅ 已实现 |
| S5 | App 前台触发同步 | `SyncTriggerService` + `SyncLifecycleObserver` | ✅ 已实现 |
| S6 | Push Notification 触发同步 | `PushNotificationService` | ⚠️ 基础架构有，未完整集成 |
| S7 | CRDT 冲突解决 | 依赖 yjs (y-crdt Rust bindings) | ❌ 未集成 (仅架构设计) |
| S8 | ACK 机制 | `POST /sync/ack` | ✅ API 层已实现 |

### 3.4 安全 (Security)

| # | 功能 | 现有实现 | 状态 |
|---|------|----------|------|
| E1 | Ed25519 设备认证签名 | `RequestSigner` in `RelayApiClient` | ✅ 已实现 |
| E2 | Group Symmetric Key (SecretBox) | `E2EEService.encryptForGroup/decryptFromGroup` | ✅ 已实现 |
| E3 | NaCl Box 密钥交换 (confirm 阶段) | `E2EEService.encrypt/decrypt` | ✅ 已实现 |
| E4 | 零知识服务器 | 架构保证 (所有数据加密传输) | ✅ 设计已保证 |

### 3.5 内部转账 (Internal Transfer)

| # | 功能 | 现有实现 | 状态 |
|---|------|----------|------|
| T1 | 发起转账请求 | — | ❌ 未实现 |
| T2 | 接收方确认/拒绝 | — | ❌ 未实现 |
| T3 | 双方自动生成记录 | — | ❌ 未实现 |
| T4 | 24小时超时自动取消 | — | ❌ 未实现 |

---

## 4. 现有 UI 页面

### 4.1 PairingScreen (配对页)
- **路径:** `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- **入口:** Settings → Family Sync (状态 = unpaired 时)
- **布局:** 2 个 Tab
  - Tab 1 "显示我的码": QR 码 + 6 位邀请码 + 过期时间 + 刷新按钮
  - Tab 2 "输入对方码": 6 位数字输入框 + 提交按钮
- **流程:** 创建群组 → 展示邀请码 / 输入邀请码 → 加入成功返回

### 4.2 PairManagementScreen (群组管理页)
- **路径:** `lib/features/family_sync/presentation/screens/pair_management_screen.dart`
- **入口:** Settings → Family Sync (状态 ≠ unpaired 时)
- **布局:** ListView 包含 4 张 Card
  - Card 1: 已配对设备数量
  - Card 2: 群组信息 (ID、配对时间、Book ID、成员数)
  - Card 3: 邀请码 + 刷新按钮 (仅 Owner)
  - Card 4: 成员列表 + 移除按钮 (仅 Owner 可移除非 Owner)
  - 底部: 退出/解散群组按钮

### 4.3 FamilySyncSettingsSection (设置页入口)
- **路径:** `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`
- **布局:** ListTile 显示同步状态 badge + 成员数

### 4.4 FamilyInviteBanner (首页邀请横幅)
- **路径:** `lib/features/home/presentation/widgets/family_invite_banner.dart`
- **布局:** 卡片样式，图标 + 标题 + 描述 + 箭头

---

## 5. 服务器 API 接口一览

**Base URL:** `https://sync.happypocket.app/api/v1`
**认证:** Ed25519 签名 (`Ed25519 <deviceId>:<timestamp>:<base64Sig>`)

| Method | Path | Auth | 说明 |
|--------|------|------|------|
| POST | `/device/register` | None | 注册设备 (幂等) |
| PUT | `/device/push-token` | Ed25519 | 更新推送 Token |
| POST | `/group/create` | Ed25519 | 创建群组 → 返回 groupId + inviteCode |
| POST | `/group/join` | Ed25519 | 加入群组 (6位码) |
| POST | `/group/confirm` | Ed25519 | Owner 确认 Pending 成员 → 交换加密 groupKey |
| GET | `/group/{groupId}/status` | Ed25519 | 查询群组 + 成员列表 |
| DELETE | `/group/{groupId}` | Ed25519 | Owner 解散群组 |
| POST | `/group/{groupId}/leave` | Ed25519 | 非 Owner 退出 |
| POST | `/group/{groupId}/remove` | Ed25519 | Owner 移除成员 |
| POST | `/group/{groupId}/invite` | Ed25519 | 刷新邀请码 |
| POST | `/sync/push` | Ed25519 | 推送加密同步包 (groupId + NaCl SecretBox payload) |
| GET | `/sync/pull` | Ed25519 | 拉取待接收消息 (since cursor) |
| POST | `/sync/ack` | Ed25519 | ACK 已收到的消息 ID |

---

## 6. 待完成的核心修改项

### 🔴 P0 (Must Have - MVP 交付)

| # | 修改项 | 说明 | 涉及层 |
|---|--------|------|--------|
| M1 | **Owner 确认成员的 UI 流程** | PairingScreen 创建群组后，需要展示 Pending 成员并提供确认按钮；当前缺少 "等待确认" 中间状态 UI | Presentation |
| M2 | **Push Notification 完整集成** | FCM/APNs token 注册到服务器 + 收到推送后触发 PullSync | Infrastructure + Application |
| M3 | **CRDT 层集成** | 当前 sync push/pull 只搬运加密 payload，需要接入 yjs 实现实际的 CRDT merge | Infrastructure + Application |
| M4 | **Transaction → CRDT 操作映射** | 新增/修改/删除 Transaction 时生成 CRDT Operation，触发 PushSync | Application |
| M5 | **设备注册自动化** | App 启动时自动 `POST /device/register`，当前未集成到 AppInitializer | Core + Infrastructure |
| M6 | **Error Handling & Retry** | 网络错误、签名过期、群组不存在等边界情况的统一处理 | 全层 |

### 🟡 P1 (Should Have - 体验优化)

| # | 修改项 | 说明 | 涉及层 |
|---|--------|------|--------|
| M7 | **QR 码扫描功能** | 当前只有 QR 展示，缺少相机扫描入口 | Presentation + Infrastructure |
| M8 | **同步进度指示** | 同步时显示进度 (X/Y 条已同步)，当前只有 syncing/synced 二态 | Presentation |
| M9 | **成员状态实时刷新** | PairManagementScreen 应定时或推送触发刷新成员状态 | Presentation |
| M10 | **冲突解决 UI** | 极端情况下 CRDT 无法自动合并时的手动选择界面 | Presentation + Application |
| M11 | **页面命名统一** | "Pair" 系列命名改为 "Group" (PairManagement → GroupManagement 等) | Presentation |

### 🟢 P2 (Nice to Have - 后续迭代)

| # | 修改项 | 说明 | 涉及层 |
|---|--------|------|--------|
| M12 | **内部转账 (B05)** | 两阶段转账请求 → 确认 → 双方记录 | 全层 |
| M13 | **多群组支持** | 一个设备加入多个不同的共享账本 | 全层 |
| M14 | **成员昵称/头像** | 群组成员展示头像和自定义昵称 | Presentation + Data |
| M15 | **灵魂账本隐私** | Soul Ledger 详情对其他成员不可见 (仅显示总额) | Application + Sync |
| M16 | **同步历史日志** | 查看同步记录 (时间、条数、成功/失败) | Presentation + Data |

---

## 7. 数据流概要

### 7.1 配对流程

```
Device A (Owner)                    Server                     Device B (Member)
     │                                │                              │
     ├── POST /group/create ─────────►│                              │
     │◄── groupId + inviteCode ───────┤                              │
     │                                │                              │
     │   (展示 QR/邀请码)              │        (输入邀请码)            │
     │                                │◄──── POST /group/join ───────┤
     │                                │──── push notification ──────►│ (不需要，B已知)
     │◄── push notification ──────────┤                              │
     │                                │                              │
     │   (确认 Pending 成员)            │                              │
     ├── POST /group/confirm ────────►│                              │
     │   (含 NaCl Box 加密的 groupKey) │──── push notification ──────►│
     │                                │                              │
     │   ✅ 配对完成，双方持有 groupKey   │                              │
```

### 7.2 同步流程

```
Device A                           Server                      Device B
     │                                │                              │
     │ (新建 Transaction)              │                              │
     ├── POST /sync/push ────────────►│                              │
     │   {groupId, payload(SecretBox)} │──── push notification ──────►│
     │                                │                              │
     │                                │◄──── GET /sync/pull ─────────┤
     │                                │───── messages[] ─────────────►│
     │                                │                              │
     │                                │◄──── POST /sync/ack ─────────┤
     │                                │   (服务器物理删除已ACK消息)       │
```

---

## 8. 技术约束

1. **E2EE 不可妥协** — 所有同步数据必须客户端加密，服务器仅搬运密文
2. **离线优先** — 无网络时操作排队，恢复后自动同步
3. **CRDT** — 使用 yjs 保证并发编辑的最终一致性
4. **NaCl SecretBox** — 群组共享对称密钥加密 (非 per-recipient)
5. **Ed25519 签名认证** — 无 session/token，每个请求签名
6. **服务器零存储** — ACK 后物理删除同步消息

---

## 9. 开放问题 (待讨论)

1. **yjs Dart 绑定**: 是否有成熟的 Dart FFI binding？还是需要 Rust FFI？
2. **Push Notification**: FCM 在中国大陆可用性？是否需要备选方案 (如 WebSocket 长连接)？
3. **多群组**: MVP 是否限制一个设备只能加入一个群组？
4. **成员上限**: 群组最大成员数？(建议 MVP: 5人)
5. **Owner 转让**: 如果 Owner 退出，是否支持转让 Owner 角色？
6. **命名**: UI 中 "配对" vs "群组" 的用语统一？(当前混用 Pair/Group)

---

*文档用途: 供 Review 核对现有实现完整性，确认优先级和开放问题。*
