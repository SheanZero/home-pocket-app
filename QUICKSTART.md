# 快速开始指南 (Quick Start Guide)

**目标:** 在5分钟内运行Home Pocket项目

---

## 前提条件

确保已安装以下工具：

- ✅ Flutter 3.16.0+
- ✅ Dart 3.2.0+
- ✅ VS Code 或 Android Studio
- ✅ iOS Simulator (Mac) 或 Android Emulator

### 验证环境

```bash
flutter doctor
```

确保所有项目都显示 ✓ 或至少一个平台可用。

---

## 步骤1: 安装依赖

```bash
cd home-pocket-app

# 安装Flutter包
flutter pub get
```

**预期输出:**
```
Resolving dependencies...
Got dependencies!
```

---

## 步骤2: 代码生成

项目使用Riverpod、Freezed、Drift等代码生成工具。

```bash
# 一次性生成所有代码
flutter pub run build_runner build --delete-conflicting-outputs
```

**这会生成以下文件:**
- `*.g.dart` - Riverpod Provider, JSON序列化, Drift DAO
- `*.freezed.dart` - 不可变数据模型

**注意:** 首次运行可能需要1-2分钟。

---

## 步骤3: 运行应用

### 方法A: 使用命令行

```bash
# 列出可用设备
flutter devices

# 在默认设备上运行
flutter run

# 在特定设备上运行
flutter run -d <device_id>
```

### 方法B: 使用VS Code

1. 打开项目文件夹
2. 按 `F5` 或点击 "Run > Start Debugging"
3. 选择目标设备

### 方法C: 使用Android Studio

1. 打开项目
2. 选择设备/模拟器
3. 点击绿色播放按钮 ▶️

---

## 步骤4: 验证运行

应用启动后，你应该看到:

- ✅ 标题: "Home Pocket"
- ✅ 消息: "Project framework created successfully!"
- ✅ 右下角浮动按钮 (+)

**恭喜!** 项目已成功运行。

---

## 常见问题

### Q1: `build_runner` 报错

**问题:**
```
Could not find package 'xxx'
```

**解决:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q2: 找不到生成的文件

**问题:**
```
Error: 'transaction_list_provider.g.dart' doesn't exist
```

**解决:**
运行代码生成命令（步骤2）

### Q3: iOS模拟器无法启动

**解决:**
```bash
# 打开iOS模拟器
open -a Simulator

# 或使用Xcode启动
```

### Q4: Android模拟器慢

**解决:**
- 启用硬件加速 (HAXM/KVM)
- 或使用真机调试

---

## 下一步

### 1. 查看架构文档

```bash
# 打开完整架构指南
open arch2/01-core-architecture/ARCH-001_Complete_Guide.md

# 或查看项目结构说明
open FLUTTER_PROJECT_STRUCTURE.md
```

### 2. 开始开发

查看 `worklog/PROJECT_DEVELOPMENT_PLAN.md` 了解开发计划。

推荐从 **Phase 1: MOD-006 安全模块** 开始。

### 3. 持续代码生成

在开发过程中，建议使用watch模式:

```bash
flutter pub run build_runner watch
```

这会监听文件变化并自动生成代码。

### 4. 运行测试

```bash
# 运行所有测试
flutter test

# 生成覆盖率报告
flutter test --coverage
```

---

## 开发工作流

```bash
# 1. 创建功能分支
git checkout -b feature/MOD-006-security

# 2. 启动代码监听
flutter pub run build_runner watch

# 3. 在另一个终端运行应用
flutter run

# 4. 开发...

# 5. 运行测试
flutter test

# 6. 提交代码
git add .
git commit -m "feat(MOD-006): implement key manager"
```

---

## 有用的命令

```bash
# 查看设备列表
flutter devices

# 热重载 (应用运行时按 'r')
# 热重启 (应用运行时按 'R')

# 清理构建缓存
flutter clean

# 升级依赖
flutter pub upgrade

# 代码分析
flutter analyze

# 代码格式化
dart format .

# 生成多语言文件
flutter gen-l10n
```

---

## 帮助资源

- **架构文档:** `arch2/01-core-architecture/`
- **模块规范:** `arch2/02-module-specs/`
- **开发计划:** `worklog/PROJECT_DEVELOPMENT_PLAN.md`
- **Git工作流:** 查看README.md

---

## 需要帮助?

- 查看 GitHub Issues
- 阅读架构文档
- 运行 `flutter doctor` 检查环境

---

**祝开发顺利! 🚀**

**更新日期:** 2026-02-03
