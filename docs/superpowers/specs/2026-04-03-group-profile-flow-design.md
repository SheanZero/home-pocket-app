# Group 创建/加入流程 PRD（含 Profile 集成）

**日期:** 2026-04-03
**状态:** 待审核
**相关模块:** Family Sync (MOD-003) + Profile
**前置依赖:** [User Profile Onboarding](2026-04-03-user-profile-onboarding-design.md)

---

## 1. 概述

在现有 Family Sync 的 Group 创建/加入流程中集成用户 Profile（姓名 + 头像），将交互从"设备对设备"升级为"人对人"。同时新增头像图片的 E2EE 同步机制（SHA-256 校验避免重复传输）。

### 核心需求

1. **创建 Group:** 显示 Owner 姓名/头像，Group 名默认 `{姓名}+家`（i18n），邀请码同屏展示
2. **修改 Group 名:** 创建后可修改，变更同步到服务器并通知成员
3. **加入 Group:** 显示自己姓名，输入邀请码 → 服务器验证 → 返回 Group 名 + Owner 信息 → 用户确认后才发送加入请求
4. **Owner 审批:** 看到申请人姓名/头像，确认后 Group 正式激活
5. **头像同步:** E2EE 通道传输，SHA-256 校验（一致跳过，不一致才传输）

### 设计决策摘要

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 设计范围 | 前后端一起（API + 客户端 UI） | 前后端耦合紧密，API 契约需明确 |
| 头像同步方式 | E2EE 通道 + SHA-256 校验 | 零知识架构，不在服务器存储头像 |
| Group 默认名 | i18n 模板 | 各语言自然表达不同 |
| 确认码 | 复用现有 invite code | 已有完整的生成/过期/重新生成逻辑 |
| Owner 通知 | Push + 应用内实时监听 | 最佳体验 + fallback 覆盖 |
| 架构方式 | 重构 Group 流程 | 以 Profile 为中心重新设计 UI 和 Use Case |

---

## 2. 数据模型变更

### 2.1 Groups Table 扩展

```dart
// lib/data/tables/groups_table.dart 新增
TextColumn get groupName => text().withLength(min: 1, max: 50)
    .withDefault(const Constant(''))();
```

### 2.2 GroupMembers Table 扩展

```dart
// lib/data/tables/group_members_table.dart 新增
TextColumn get displayName => text().withLength(min: 1, max: 50)
    .withDefault(const Constant(''))();
TextColumn get avatarEmoji => text()
    .withDefault(const Constant('🏠'))();
TextColumn get avatarImagePath => text().nullable()();   // 本地存储的对方头像路径
TextColumn get avatarImageHash => text().nullable()();    // 头像图片 SHA-256
```

### 2.3 Domain Model 变更

```dart
// GroupInfo 新增 groupName
@freezed
class GroupInfo with _$GroupInfo {
  const factory GroupInfo({
    // ... 现有字段 ...
    required String groupName,           // 新增
  }) = _GroupInfo;
}

// GroupMember 新增 profile 字段
@freezed
class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String groupId,
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String role,
    required String status,
    required String displayName,         // 新增
    required String avatarEmoji,         // 新增
    String? avatarImagePath,             // 新增
    String? avatarImageHash,              // 新增
  }) = _GroupMember;
}
```

### 2.4 DB 迁移

v13（接续 Profile 的 v12）。新增列使用 `withDefault` 确保已有数据兼容：

```dart
onUpgrade: (m, from, to) async {
  if (from < 13) {
    await transaction(() async {
      // Groups: groupName 默认空字符串，迁移后由 app 回填为 deviceName
      await m.addColumn(groups, groups.groupName);
      // GroupMembers: displayName 默认空字符串，avatarEmoji 默认 🏠
      await m.addColumn(groupMembers, groupMembers.displayName);
      await m.addColumn(groupMembers, groupMembers.avatarEmoji);
      await m.addColumn(groupMembers, groupMembers.avatarImagePath);
      await m.addColumn(groupMembers, groupMembers.avatarImageHash);
      // 回填: 将现有成员的 displayName 设为 deviceName
      await customStatement(
        "UPDATE group_members SET display_name = device_name WHERE display_name = ''",
      );
    });
  }
}
```

---

## 3. API 变更

### 3.1 `POST /groups` — 创建 Group

**请求新增字段:**
```json
{
  "deviceId": "xxx",
  "publicKey": "xxx",
  "groupName": "たけしの家庭",
  "displayName": "たけし",
  "avatarEmoji": "🐱",
  "avatarImageHash": "a1b2c3..."
}
```

**响应不变:** `groupId` + `inviteCode` + `inviteExpiresAt`

### 3.2 `POST /groups/{groupId}/join` — 验证邀请码

**请求新增字段:**
```json
{
  "deviceId": "xxx",
  "inviteCode": "385291",
  "publicKey": "xxx",
  "displayName": "ゆきこ",
  "avatarEmoji": "🌸",
  "avatarImageHash": "d4e5f6..."
}
```

**响应新增:**
```json
{
  "groupId": "xxx",
  "status": "confirming",
  "groupName": "たけしの家庭",
  "owner": {
    "deviceId": "xxx",
    "displayName": "たけし",
    "avatarEmoji": "🐱",
    "avatarImageHash": "a1b2c3..."
  }
}
```

Joiner 拿到信息后展示确认画面，**用户点击"确认加入"后才发送下一步请求。**

### 3.3 `POST /groups/{groupId}/confirm-join` — 确认加入（新增 API）

Joiner 确认后发送:
```json
{
  "deviceId": "xxx",
  "confirmed": true
}
```

服务器向 Owner 推送 `joinRequest` 事件（附带 Joiner 的 profile）。

### 3.4 `POST /groups/{groupId}/confirm` — Owner 审批

**不变。** Owner 端已通过 joinRequest 事件获取 Joiner 的 profile。

### 3.5 `PUT /groups/{groupId}/name` — 修改 Group 名（新增 API）

**请求:**
```json
{ "deviceId": "owner_xxx", "groupName": "新しい名前" }
```

**响应:**
```json
{ "groupId": "xxx", "groupName": "新しい名前", "updatedAt": "..." }
```

仅 Owner 有权限。修改后向其他成员推送 `groupNameUpdated` 事件。

### 3.6 Push Notification 事件扩展

| 事件 | 现有 payload | 新增 payload |
|------|-------------|-------------|
| `joinRequest` | deviceId | + `displayName`, `avatarEmoji`, `avatarImageHash` |
| `memberConfirmed` | deviceId | + `displayName`, `avatarEmoji`, `avatarImageHash` |
| `groupNameUpdated` | — | 新事件: `groupId`, `groupName` |

---

## 4. 画面流程与交互规格

### 4.1 Owner 流程（3步）

#### Step 1: CreateGroupScreen（创建 + 邀请码合并）

```
┌──────────────────────────────────────┐
│  ← 返回                              │
│                                      │
│  [Owner 头像]                        │
│  Owner: たけし                        │
│                                      │
│  ┌─ Group 名（可点击 ✎ 编辑）─────┐  │
│  │  たけしの家庭              ✎   │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─ 邀请码区域 ──────────────────┐   │
│  │       385 291                 │   │
│  │     5分钟内有效               │   │
│  └───────────────────────────────┘   │
│                                      │
│  [ 分享邀请码 ]                       │
└──────────────────────────────────────┘
```

**行为:**
- 打开时自动调用 `CreateGroupUseCase`（携带 profile 字段）
- Group 名默认 i18n 模板 `{displayName}の家庭` / `{displayName}的家` / `{displayName}'s Family`
- 点击 Group 名 → 弹出 `GroupRenameDialog` → 修改后调用 `RenameGroupUseCase`
- 邀请码到期自动刷新
- 收到 `joinRequest` 事件 → 自动导航到 Step 2

#### Step 2: MemberApprovalScreen（审批）

```
┌──────────────────────────────────────┐
│                                      │
│  收到加入请求                         │
│                                      │
│  ┌─ 申请人信息 ──────────────────┐   │
│  │  [🌸 头像]                    │   │
│  │  ゆきこ                       │   │
│  │  申请加入 たけしの家庭         │   │
│  └───────────────────────────────┘   │
│                                      │
│  [ 拒绝 ]  [ 批准 ]                  │
└──────────────────────────────────────┘
```

**行为:**
- 通过 Push / SyncTriggerService `joinRequest` 事件触发
- 如果 app 在前台 → 自动弹出此画面
- 如果 app 在后台 → Push 通知，点击进入
- 批准 → `ConfirmMemberUseCase` → 触发头像互相同步 → 进入 Step 3

#### Step 3: GroupManagementScreen

```
┌──────────────────────────────────────┐
│  ← 返回                              │
│                                      │
│  たけしの家庭  ✎        ● 同步中     │
│                                      │
│  ┌─ 成员列表 ────────────────────┐   │
│  │  [🐱] たけし           Owner  │   │
│  │  [🌸] ゆきこ           成员   │   │
│  └───────────────────────────────┘   │
│                                      │
│  [ 邀请新成员 ]                       │
│  [ 解散 Group ]                       │
└──────────────────────────────────────┘
```

**行为:**
- Group 名可点击编辑（仅 Owner）
- 成员显示头像（emoji 或图片）+ 姓名 + 角色
- 头像自动保持最新（通过 avatarSync 机制）

### 4.2 Joiner 流程（4步）

#### Step 1: JoinGroupScreen（输入邀请码）

```
┌──────────────────────────────────────┐
│  ← 返回                              │
│                                      │
│  [🌸 我的头像]                        │
│  我的名称: ゆきこ                     │
│                                      │
│  邀请码                               │
│  ┌──────────────────────────────┐    │
│  │        385 291               │    │
│  └──────────────────────────────┘    │
│                                      │
│  [ 验证 ]                             │
└──────────────────────────────────────┘
```

**行为:**
- 从当前 UserProfile 读取姓名/头像显示
- 输入 6 位码 → 调用 `JoinGroupUseCase`（验证阶段）
- 服务器返回 Group 名 + Owner profile → 导航到 Step 2

#### Step 2: ConfirmJoinScreen（确认 Group 信息）

```
┌──────────────────────────────────────┐
│  ← 返回                              │
│                                      │
│  你要加入的 Group                     │
│  たけしの家庭                         │
│                                      │
│  ┌─ Owner 信息 ─────────────────┐    │
│  │  [🐱 头像]                    │    │
│  │  たけし                       │    │
│  │  Owner                       │    │
│  └───────────────────────────────┘   │
│                                      │
│  [ 确认加入 ]                         │
└──────────────────────────────────────┘
```

**行为:**
- 展示服务器返回的 Group 名 + Owner 姓名/头像
- 点击「确认加入」→ `ConfirmJoinUseCase` → 服务器通知 Owner → 进入 Step 3

#### Step 3: WaitingApprovalScreen（等待审批）

```
┌──────────────────────────────────────┐
│                                      │
│  たけしの家庭                         │
│                                      │
│       [旋转加载]                      │
│                                      │
│  等待 Owner 审批...                   │
│  たけし 正在确认你的请求              │
│                                      │
└──────────────────────────────────────┘
```

**行为:**
- 监听 `memberConfirmed` 事件（Push + SyncTriggerService）
- 收到确认 → 导航到 Step 4

#### Step 4: JoinSuccessScreen（加入成功）

```
┌──────────────────────────────────────┐
│                                      │
│           🎉                         │
│       欢迎加入！                      │
│     たけしの家庭                      │
│                                      │
│      [🐱][🌸]                        │
│   たけし  ゆきこ                      │
│                                      │
│  [ 进入 Group ]                       │
└──────────────────────────────────────┘
```

**行为:**
- 展示双方头像叠加效果
- 点击「进入 Group」→ 导航到 GroupManagementScreen

---

## 5. 头像同步机制（E2EE + SHA-256 校验）

### 5.1 同步时机

| 时机 | 触发条件 | 行为 |
|------|---------|------|
| Group 创建成功 | Owner 确认 Joiner 后 | 双方互相同步头像图片 |
| Profile 修改 | 用户在 Settings 更换头像 | SHA-256 变化 → 推送新头像给所有 Group 成员 |
| Pull Sync | 定期 / 事件触发 | 比对成员 avatarImageHash → 不一致则请求图片 |

### 5.2 SHA-256 校验流程

```
发送方:
  1. 本地图片 → 计算 SHA-256 → 保存到 UserProfile.avatarImageHash
  2. API 请求 / sync payload 中携带 avatarImageHash

接收方:
  1. 收到成员的 avatarImageHash
  2. 比对本地 GroupMember.avatarImageHash
     → 一致: 跳过，不传输图片
     → 不一致 / 本地无图片: 请求图片传输
  3. 收到图片后验证 SHA-256 → 保存到本地 → 更新 GroupMember 记录
```

### 5.3 图片传输协议

基于现有 E2EE sync 通道，新增 `avatarSync` 操作类型:

```json
{
  "type": "avatarSync",
  "deviceId": "sender_xxx",
  "displayName": "たけし",
  "avatarEmoji": "🐱",
  "avatarImageHash": "a1b2c3...",
  "avatarImageBase64": "..."
}
```

**传输约束:**
- 图片经 `image_picker` 压缩后（maxWidth: 512, maxHeight: 512, quality: 80）通常 < 100KB
- Base64 编码后 < 140KB，在现有 sync payload 限制内
- E2EE 加密后通过 `pushSync` 发送，接收方通过 `pullSync` 获取并解密

### 5.4 Emoji-only 场景

- 用户只用 emoji（无自定义图片）: `avatarImageHash` = null，不触发图片传输
- 用户从图片改回 emoji: `avatarImageBase64` = null，接收方删除本地缓存图片，回退 emoji 显示

### 5.5 SyncAvatarUseCase

```dart
// lib/application/family_sync/sync_avatar_use_case.dart
class SyncAvatarUseCase {
  /// 发送方: 检查是否需要同步头像给对方
  Future<void> pushAvatarIfNeeded({
    required String targetDeviceId,
    required String localHash,
    required String? remoteHash,
  });

  /// 接收方: 处理收到的头像数据
  Future<void> handleAvatarSync({
    required String senderDeviceId,
    required Map<String, dynamic> payload,
  });
}
```

---

## 6. 文件结构

```
lib/
├── application/
│   └── family_sync/
│       ├── create_group_use_case.dart       # 重写: 加入 Profile 字段
│       ├── join_group_use_case.dart         # 重写: 两步（验证 → 确认加入）
│       ├── confirm_join_use_case.dart       # 新: Joiner 确认加入
│       ├── confirm_member_use_case.dart     # 扩展: 触发头像同步
│       ├── rename_group_use_case.dart       # 新: 修改 Group 名
│       ├── sync_avatar_use_case.dart        # 新: 头像 SHA-256 校验 + E2EE 传输
│       ├── full_sync_use_case.dart          # 不变
│       ├── pull_sync_use_case.dart          # 不变
│       ├── push_sync_use_case.dart          # 不变
│       └── ...
├── features/
│   └── family_sync/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── group_info.dart              # 扩展: + groupName
│       │   │   ├── group_member.dart            # 扩展: + profile 字段
│       │   │   └── sync_status.dart             # 不变
│       │   └── repositories/
│       │       └── group_repository.dart        # 扩展: + updateGroupName, updateMemberProfile
│       └── presentation/
│           ├── screens/
│           │   ├── create_group_screen.dart     # 新: Owner 创建（合并创建+邀请码）
│           │   ├── join_group_screen.dart       # 新: Joiner 输入邀请码
│           │   ├── confirm_join_screen.dart     # 新: Joiner 确认 Group 信息
│           │   ├── waiting_approval_screen.dart # 重写: 加入 Profile 展示
│           │   ├── member_approval_screen.dart  # 重写: 显示申请人头像/姓名
│           │   ├── join_success_screen.dart     # 新: 欢迎画面
│           │   └── group_management_screen.dart # 重写: 头像 + Group 名编辑
│           ├── widgets/
│           │   ├── group_rename_dialog.dart     # 新: 改名弹窗
│           │   ├── member_avatar.dart           # 重写: 统一用 AvatarDisplay
│           │   └── member_list_tile.dart        # 新: 成员行组件
│           └── providers/
│               ├── group_providers.dart          # 扩展: 新 Use Case 接入
│               └── avatar_sync_providers.dart    # 新: 头像同步状态
```

**Use Case 迁移:** 现有 `lib/features/family_sync/use_cases/` 中的 use case 统一迁移到 `lib/application/family_sync/`，遵循 Thin Feature 规则。

**旧文件处理:** `pairing_screen.dart` 拆分为 `CreateGroupScreen` + `JoinGroupScreen`，旧文件删除。

**跨 Feature 复用:**
- `AvatarDisplay` widget（来自 profile feature）
- `warmEmojis` 常量
- `UserProfile` provider

---

## 7. i18n 新增键

3 语言全部添加:

| 键 | ja | zh | en |
|----|----|----|-----|
| `groupDefaultName` | {name}の家庭 | {name}的家 | {name}'s Family |
| `groupCreate` | グループを作成 | 创建 Group | Create Group |
| `groupName` | グループ名 | Group 名 | Group Name |
| `groupOwner` | オーナー | Owner | Owner |
| `groupMember` | メンバー | 成员 | Member |
| `groupInviteCode` | 招待コード | 邀请码 | Invite Code |
| `groupInviteExpiry` | {minutes}分以内に有効 | {minutes}分钟内有效 | Valid for {minutes} minutes |
| `groupShareCode` | 招待コードを共有 | 分享邀请码 | Share Invite Code |
| `groupEnterCode` | 招待コードを入力 | 输入邀请码 | Enter Invite Code |
| `groupVerify` | 検証 | 验证 | Verify |
| `groupConfirmJoin` | 参加を確認 | 确认加入 | Confirm Join |
| `groupJoinTarget` | 参加するグループ | 你要加入的 Group | Group to Join |
| `groupWaitingApproval` | オーナーの承認を待っています... | 等待 Owner 审批... | Waiting for Owner approval... |
| `groupWaitingDesc` | {name} があなたのリクエストを確認中 | {name} 正在确认你的请求 | {name} is reviewing your request |
| `groupJoinRequest` | 参加リクエストを受信 | 收到加入请求 | Join request received |
| `groupJoinRequestDesc` | {name} が参加を申請 | {name} 申请加入 | {name} wants to join |
| `groupApprove` | 承認 | 批准 | Approve |
| `groupReject` | 拒否 | 拒绝 | Reject |
| `groupJoinSuccess` | ようこそ！ | 欢迎加入！ | Welcome! |
| `groupRename` | グループ名を変更 | 修改 Group 名 | Rename Group |
| `groupRenameFailed` | 名前の変更に失敗しました | 修改名称失败 | Failed to rename |
| `groupSyncing` | 同期中 | 同步中 | Syncing |
| `groupInvalidCode` | 無効な招待コードです | 邀请码无效 | Invalid invite code |
| `groupCodeExpired` | 招待コードの有効期限が切れました | 邀请码已过期 | Invite code expired |
| `groupMyName` | 自分の名前 | 我的名称 | My Name |
| `groupEnterGroup` | グループへ | 进入 Group | Enter Group |

---

## 8. 边界情况与错误处理

### 8.1 两步加入流程的竞态条件

| 场景 | 处理方式 |
|------|---------|
| 邀请码在验证与确认之间过期 | 服务器在 `confirm-join` 时检查：只要 `join`（验证）在有效期内完成即可，`confirm-join` 不再重新校验过期 |
| 两人同时验证同一邀请码 | 服务器在 `confirm-join` 时加锁：第一个成功，第二个返回 `409 Conflict`（Group 已有 pending joiner） |
| Joiner 验证后放弃（不调用 confirm-join） | 验证步骤为只读，不写入 DB。客户端不持久化 "confirming" 状态。无需清理 |
| confirm-join 网络失败 | 客户端显示重试按钮，可重复调用（幂等） |

### 8.2 Group 改名错误处理

- `RenameGroupUseCase`: 先调用服务器 API，**成功后**才更新本地 DB（非乐观更新）
- 失败时显示 `groupRenameFailed` 错误提示，本地数据不变

### 8.3 头像同步失败

- 头像同步失败不阻塞 Group 功能，成员仍可看到 emoji fallback
- 下一次 `pullSync` 周期自动重试（比对 hash 不一致 → 重新传输）
- 不引入专门的 `avatarSyncFailed` 事件，依赖既有 sync 重试机制

### 8.4 Owner 离线时的审批

- Push notification 为最佳努力，不保证送达
- 现有 `SyncTriggerService` 在 app resume 时自动 pull，会获取 pending join request
- Owner 端 `GroupManagementScreen` / `CreateGroupScreen` 监听事件流，app 切回前台时自动刷新

### 8.5 API 兼容性策略

- 新增字段在服务器端设为 **可选**（optional），旧客户端不传时使用默认值（`displayName` 默认 `deviceName`，`avatarEmoji` 默认 `🏠`）
- 新增 API（`confirm-join`、`PUT /name`）为独立 endpoint，不影响现有 API
- 客户端与服务器同步部署（relay 服务器自控），无需 API 版本号
- `groupNameUpdated` 推送事件需在 `PushNotificationService` 和 `SyncTriggerService` 中新增 handler

---

## 9. 安全说明

- **头像图片传输:** 通过现有 E2EE sync 通道（NaCl box: X25519-XSalsa20-Poly1305），服务器无法解密
- **服务器不存储头像:** 零知识架构，头像只在端侧存储，服务器仅中转加密数据
- **SHA-256 校验:** 用于判断是否需要同步，SHA-256 本身通过 API 传输（低敏感元数据）
- **Group 名:** 在服务器明文存储（用于 join 时返回给 Joiner），这是有意为之的设计——Group 名不含财务数据，且需要在配对阶段（E2EE 建立前）展示给 Joiner
- **displayName / avatarEmoji:** 同 Group 名，在服务器暂存用于配对阶段展示。Group 激活后，后续 Profile 更新通过 E2EE 通道同步

---

## 10. 不在范围内

- 后台全量/增量同步流程（独立 PRD）
- 多成员 Group（>2人）的复杂审批流程
- Group 解散后的 Profile 数据清理策略
- 头像图片裁剪编辑器
- QR code 扫描加入（保留现有能力，不在本 PRD 增强）
