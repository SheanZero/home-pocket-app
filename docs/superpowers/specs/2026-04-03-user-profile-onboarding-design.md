# 用户 Profile Onboarding 设计文档

**日期:** 2026-04-03
**状态:** 待审核
**相关模块:** Profile (新建 Feature)

---

## 1. 概述

首次打开 APP 时，引导用户设置个人昵称和头像。头像默认随机分配一个温馨 emoji，用户可从预设 emoji 池中选择，也可上传自定义图片。Profile 数据存储在本地加密数据库（Drift + SQLCipher），用户可随时在 Settings 中修改。

### 核心需求

1. **首次 Onboarding:** 全屏引导页，初始化完成后、主画面前展示
2. **头像系统:** 随机温馨 emoji（默认）+ emoji 网格选择器 + 自定义图片上传
3. **Settings 编辑:** 顶部卡片式 Profile 入口，点击进入编辑画面

### 设计决策摘要

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 存储方式 | Drift 加密数据库 | 符合零知识架构，便于 Family Sync 扩展 |
| Onboarding 时机 | 全屏页面，主画面前 | 确保 profile 在进入主画面前已存在 |
| Emoji 选择器 | 预设温馨 emoji 网格（24个） | 控制风格，保持温暖家庭氛围 |
| 头像选择交互 | 全屏 + Tab 切换（Emoji/照片） | 上部预览，操作空间大，体验清晰 |
| 图片存储 | App 私有目录（不额外加密） | 头像为低敏感数据，OS sandbox 已够用 |
| 必填规则 | 昵称必填，头像可选 | 昵称为核心身份标识；emoji 兜底，无需强制 |
| 架构方式 | 独立 Profile Feature | 清晰边界，符合 Thin Feature，便于扩展 |
| Settings 入口 | 顶部卡片型 | LINE/WeChat 风格，醒目且直觉 |

---

## 2. 数据模型

### 2.1 UserProfiles Table (Drift)

```dart
// lib/data/tables/user_profiles_table.dart
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();                                    // ULID, 主键
  TextColumn get displayName => text().withLength(min: 1, max: 50)(); // 必填，1-50字符
  TextColumn get avatarEmoji => text()();                           // 例: "🐱"（默认随机）
  TextColumn get avatarImagePath => text().nullable()();            // 图片路径（null = 使用 emoji）
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**设计要点:**
- `@DataClassName('UserProfileRow')` 避免与 Freezed domain model `UserProfile` 命名冲突
- `displayName` 使用 `withLength(min: 1, max: 50)` 在 DB 层强制约束（与项目其他 table 一致）
- `id` 使用 ULID（与项目其他 table 一致，便于 Family Sync）
- `avatarEmoji` 始终保留，作为图片删除后的 fallback
- `avatarImagePath` 为 null 时显示 emoji，非 null 时显示图片
- 单用户 APP，仅 1 条记录。未来 Family Sync 时可扩展为多记录
- DB 版本 v11 → v12 迁移

### 2.2 UserProfile Domain Model (Freezed)

```dart
// lib/features/profile/domain/models/user_profile.dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
```

### 2.3 头像显示逻辑

```
if avatarImagePath != null → 显示圆形裁剪图片
else → 显示 avatarEmoji（渐变背景圆形）
```

---

## 3. 架构（文件结构）

```
lib/
├── data/
│   ├── tables/user_profiles_table.dart          # Drift table 定义
│   ├── daos/user_profile_dao.dart               # CRUD 操作
│   └── repositories/user_profile_repository_impl.dart
├── features/
│   └── profile/
│       ├── domain/
│       │   ├── models/user_profile.dart          # Freezed 模型
│       │   └── repositories/user_profile_repository.dart  # 接口
│       └── presentation/
│           ├── screens/
│           │   ├── profile_onboarding_screen.dart    # 首次引导页
│           │   ├── profile_edit_screen.dart           # Settings → 编辑页
│           │   └── avatar_picker_screen.dart          # 全屏 emoji+照片选择
│           ├── widgets/
│           │   └── avatar_display.dart                # emoji/图片 统一显示组件
│           └── providers/
│               └── user_profile_providers.dart         # Repository + 状态 providers
├── application/
│   └── profile/
│       ├── save_user_profile_use_case.dart
│       └── get_user_profile_use_case.dart
└── shared/
    └── constants/
        └── warm_emojis.dart                      # emoji 列表（跨 feature 可复用）
```

**依赖方向:** `Presentation → Application → Domain ← Data`

Settings 画面的 `ProfileSection` widget 引用 profile feature 的 provider，不直接访问 data 层。

---

## 4. 画面流程与交互规格

### 4.1 首次 Onboarding 流程

```
main.dart 初始化完成
  → KeyManager 初始化
  → 数据库初始化
  → seedCategories + ensureDefaultBook（现有流程）
  → 查询 UserProfile 是否存在（DB query）  ← 新增，在所有 seed 之后
  → 不存在 → ProfileOnboardingScreen
  → 存在   → MainShellScreen
```

**关键:** Profile 检查必须在 category seeding 和 book 创建之后执行，确保用户完成 onboarding 进入主画面时所有数据已就绪。

### 4.2 ProfileOnboardingScreen（卡片+插图风格）

```
┌──────────────────────────────────────┐
│                                      │
│   ┌─ 渐变背景欢迎区 ──────────────┐  │
│   │      🏠✨                     │  │
│   │    ようこそ！/ 欢迎！          │  │
│   │    まもる家計簿へ              │  │
│   └────────────────────────────────┘  │
│                                      │
│   ┌─ 白色 Profile 卡片 ───────────┐  │
│   │                               │  │
│   │  [emoji 头像]  点击更换提示    │  │
│   │                mini预览       │  │
│   │                               │  │
│   │  昵称输入框                    │  │
│   │  ────────────────────         │  │
│   │                               │  │
│   │  [ はじめる / 开始 ]           │  │
│   │  (昵称为空时禁用)              │  │
│   └───────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

**行为:**
- 打开时从 `warmEmojis` 随机选一个 emoji 作为默认头像
- 点击头像区域 → 导航到 `AvatarPickerScreen`
- 昵称 `TextField`，空时「开始」按钮灰色禁用
- 点击「开始」→ `SaveUserProfileUseCase` 执行 → `pushReplacement` 到 `MainShellScreen`（不可返回）

### 4.3 AvatarPickerScreen（全屏 + Tab 切换）

```
┌─ AppBar: [取消]  选择头像  [完成] ──┐
│                                     │
│        [圆形预览: 当前选择]           │
│         「预览」标签                  │
│                                     │
│   ┌─ Tab: [Emoji] [照片] ────────┐  │
│   │                              │  │
│   │  Emoji tab:                  │  │
│   │  5列网格，24个温馨 emoji      │  │
│   │  选中 = accentPrimary 边框   │  │
│   │                              │  │
│   │  照片 tab:                   │  │
│   │  触发 image_picker           │  │
│   │  选择后 → 圆形裁剪预览       │  │
│   └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**行为:**
- Emoji tab: 点击即时更新顶部预览，选中项显示 `accentPrimary (#E85A4F)` 边框
- 照片 tab: 调用 `image_picker`（相册选择），压缩后存入 `avatars/` 目录
- 「完成」: 返回上一页，携带选择结果
- 「取消」: 丢弃修改，返回

### 4.4 Settings Profile 入口（顶部卡片型）

```
┌─ Settings 画面 ──────────────────────┐
│                                      │
│  ┌─ Profile 卡片 (最顶部) ────────┐  │
│  │  [头像]  昵称                  │  │
│  │          「编辑个人资料」  ›    │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─ 外观 ─────────────────────────┐  │
│  │  テーマ / 主题          系统 › │  │
│  ├─ 音声入力 ─────────────────────┤  │
│  │  ...                           │  │
│  └────────────────────────────────┘  │
│  ...                                 │
└──────────────────────────────────────┘
```

**行为:** 点击 Profile 卡片 → `ProfileEditScreen`

### 4.5 ProfileEditScreen

```
┌─ AppBar: [←]  编辑个人资料 ──────────┐
│                                      │
│  [大头像显示]                         │
│  点击更换                             │
│  → 导航到 AvatarPickerScreen          │
│                                      │
│  昵称                                │
│  ┌──────────────────────────────┐    │
│  │ たけし                       │    │
│  └──────────────────────────────┘    │
│                                      │
│  [保存]                               │
└──────────────────────────────────────┘
```

---

## 5. 温馨 Emoji 池

24 个精选温馨风格 emoji:

```dart
const warmEmojis = [
  '🏠', '🌸', '🌿', '🐱', '🐶', '🌈',
  '☀️', '🦊', '🐼', '🍀', '⭐', '🌻',
  '🐰', '🦋', '🌙', '🎀', '🧸', '🎵',
  '🏡', '🌷', '🐣', '🍃', '💫', '🫧',
];
```

---

## 6. i18n 新增键

3 语言全部添加:

| 键 | ja | zh | en |
|----|----|----|-----|
| `profileSetup` | はじめまして！ | 初次见面！ | Nice to meet you! |
| `profileSetupSubtitle` | あなたのことを教えてください | 请告诉我们关于你的信息 | Tell us about yourself |
| `profileNickname` | ニックネーム | 昵称 | Nickname |
| `profileNicknamePlaceholder` | ニックネームを入力 | 请输入昵称 | Enter your nickname |
| `profileStart` | はじめる | 开始 | Get Started |
| `profileSelectAvatar` | アバターを選択 | 选择头像 | Select Avatar |
| `profileEmojiTab` | Emoji | 表情 | Emoji |
| `profilePhotoTab` | 写真 | 照片 | Photo |
| `profileUploadPhoto` | 写真をアップロード | 上传照片 | Upload Photo |
| `profileEdit` | プロフィールを編集 | 编辑个人资料 | Edit Profile |
| `profileCancel` | キャンセル | 取消 | Cancel |
| `profileDone` | 完了 | 完成 | Done |
| `profilePreview` | プレビュー | 预览 | Preview |
| `welcomeTo` | まもる家計簿へ | 欢迎使用守护家计簿 | Welcome to Home Pocket |
| `profileNameRequired` | ニックネームを入力してください | 请输入昵称 | Please enter a nickname |
| `profileSave` | 保存 | 保存 | Save |
| `profileChangeAvatar` | タップしてアバターを変更 | 点击更换头像 | Tap to change avatar |
| `profilePhotoPermissionDenied` | 写真へのアクセスが拒否されました | 照片访问被拒绝 | Photo access denied |
| `profilePhotoFailed` | 写真の読み込みに失敗しました | 照片加载失败 | Failed to load photo |
| `profileSaveFailed` | 保存に失敗しました | 保存失败 | Failed to save |
| `profileNameTooLong` | ニックネームは50文字以内で入力してください | 昵称不能超过50个字符 | Nickname must be 50 characters or less |

---

## 7. 技术细节

### 7.1 DB 迁移 (v11 → v12)

```dart
onUpgrade: (m, from, to) async {
  if (from < 12) {
    await transaction(() async {
      await m.createTable(userProfiles);
    });
  }
}
```

### 7.2 输入验证 (SaveUserProfileUseCase)

- `displayName`: trim 后验证非空且 <= 50 字符
- `avatarEmoji`: 验证在 `warmEmojis` 列表中
- 空白字符串（如 "   "）trim 后视为空，拒绝保存
- 旧图片删除顺序: 先更新 DB 指向新图片路径，再删除旧文件（避免 race condition）

### 7.3 图片处理

- **依赖包:** `image_picker` (相册选择)
- **保存路径:** `getApplicationDocumentsDirectory()/avatars/`
- **文件名:** `avatar_{timestamp}.jpg`
- **压缩参数:** `maxWidth: 512, maxHeight: 512, imageQuality: 80`
- **旧图清理:** 上传新图时删除旧文件，节省存储

### 7.4 Onboarding 判定逻辑

```dart
// main.dart 启动流程追加
final profile = await ref.read(userProfileProvider.future);
if (profile == null) {
  // → ProfileOnboardingScreen
} else {
  // → MainShellScreen
}
```

使用 `MaterialApp` 的 `home:` 条件分支，或 `Navigator.pushReplacement`。沿用现有 `MaterialPageRoute` 模式（项目尚未引入 GoRouter）。

### 7.5 依赖包新增

- `image_picker: ^1.0.0` — 相册图片选择
- `path_provider` — 已有（需确认）
- `uuid` — 已有（需确认）

---

## 8. 安全说明

头像图片存储在 App 私有目录，**不使用**项目 4 层加密中的 Layer 3（AES-256-GCM）。这是有意为之的设计决策：头像为低敏感数据，OS sandbox 提供了足够保护。`displayName` 和 `avatarEmoji` 存在 SQLCipher 加密数据库中，受 Layer 1 保护。

参考: `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`

---

## 9. 未来集成点

- **Family Sync (MOD-003):** `UserProfiles` table 使用 ULID 主键，支持多记录扩展。`AvatarDisplay` widget 可考虑提升到 `lib/shared/widgets/` 供家庭成员头像显示复用
- **现有 MemberAvatar widgets:** `lib/features/home/` 和 `lib/features/family_sync/` 中已有基于首字母的 `MemberAvatar` 组件，后续需与 `AvatarDisplay` 统一

---

## 10. 不在范围内

- Family Sync 成员 profile 同步（MOD-003 范围）
- 头像裁剪编辑器（使用 image_picker 内置压缩即可）
- 生物认证与 profile 绑定
- 多用户切换
