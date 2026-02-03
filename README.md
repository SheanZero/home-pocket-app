# Home Pocket (まもる家計簿)

> 本地优先、隐私保护的家庭记账应用 | Local-first, privacy-focused family accounting app

## 🌟 核心特性

**Home Pocket** 是一款零知识架构的家庭记账应用，采用本地优先设计。

- 🔐 **多层加密防护** - 4层安全架构（生物识别 → PIN → 字段加密 → 数据库加密）
- 📊 **双轨账本系统** - 生存账本 vs 灵魂账本，智能分类引擎
- 🔄 **P2P家庭同步** - 无需服务器，设备间端到端加密同步
- 📸 **OCR智能扫描** - 自动识别小票金额、日期、商户
- 🌐 **多语言支持** - 日文、中文、英文
- 📴 **完全离线可用** - 零依赖云服务
- ⛓️ **哈希链完整性** - 区块链风格防篡改保护

## 🎯 项目状态

**当前阶段:** 🟡 Phase 1 - 基础设施层开发中
**版本:** v0.1.0
**最后更新:** 2026-02-03

---

## Features

- ✅ **Fast entry** (expense / income / transfer) with notes and tags  
- ✅ **Categories & budgets** (monthly category budgets, overspend warnings)  
- ✅ **Monthly / yearly reports** (totals, trends, category breakdowns)  
- ✅ **History & search** (filters by date, category, payment method, keywords)  
- ✅ **Local backup / restore** (encrypted export file)  
- ✅ **CSV export** (for spreadsheets / tax / sharing)  

Planned:
- 🔜 **Family sharing** (optional local sync via file / QR / LAN)  
- 🔜 **Receipt capture** (on-device OCR where possible)  
- 🔜 **Rules & templates** (smart categorization, recurring items)  

---

## 🏗️ 技术架构

### Clean Architecture (5层架构)

```
lib/
├── core/                      # 核心配置
│   ├── config/               # 应用配置
│   ├── constants/            # 常量定义
│   ├── router/               # 路由配置 (GoRouter)
│   └── theme/                # 主题配置
│
├── features/                  # 功能模块（按领域划分）
│   ├── accounting/           # 基础记账 (MOD-001)
│   │   ├── presentation/     # UI层
│   │   ├── application/      # 业务逻辑层
│   │   ├── domain/           # 领域层
│   │   └── data/             # 数据层
│   ├── dual_ledger/          # 双轨账本 (MOD-003)
│   ├── family_sync/          # 家庭同步 (MOD-004)
│   ├── security/             # 安全模块 (MOD-006)
│   ├── analytics/            # 数据分析 (MOD-007)
│   ├── settings/             # 设置管理 (MOD-008)
│   └── ocr/                  # OCR扫描 (MOD-005)
│
├── shared/                    # 共享组件
│   ├── widgets/              # 可复用UI组件
│   ├── extensions/           # 扩展方法
│   └── utils/                # 工具函数
│
├── l10n/                     # 国际化
│   ├── app_ja.arb            # 日文
│   ├── app_zh.arb            # 中文
│   └── app_en.arb            # 英文
│
└── generated/                # 生成代码
```

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **Flutter** | 3.16+ | 跨平台UI框架 |
| **Dart** | 3.2+ | 编程语言 |
| **Riverpod** | 2.4+ | 状态管理 + 依赖注入 |
| **Drift** | 2.14+ | 类型安全的数据库ORM |
| **SQLCipher** | 4.5+ | AES-256数据库加密 |
| **Freezed** | 2.4+ | 不可变数据模型 |
| **GoRouter** | 13.0+ | 声明式路由导航 |
| **Cryptography** | 2.5+ | ChaCha20-Poly1305加密 |
| **PointyCastle** | 3.7+ | Ed25519密钥对 |
| **ML Kit** | - | OCR文本识别 (Android) |
| **Vision** | - | OCR文本识别 (iOS) |
| **TFLite** | 0.10+ | ML分类模型 |
| **fl_chart** | 0.65+ | 数据可视化图表 |

### 安全架构

**4层加密防护:**

1. **Layer 1: 数据库加密** - SQLCipher AES-256-CBC
2. **Layer 2: 字段加密** - ChaCha20-Poly1305 (AEAD)
3. **Layer 3: 文件加密** - AES-256-GCM (照片)
4. **Layer 4: 传输加密** - TLS 1.3 + E2EE (同步)

**完整性保护:**
- 区块链风格哈希链
- 增量验证 (100-2000x性能提升)
- 防篡改检测

---

## 🚀 快速开始

### 环境要求

- Flutter 3.16.0+
- Dart 3.2.0+
- iOS 14+ / Android 7+ (API 24+)

### 安装依赖

```bash
# 安装Flutter依赖
flutter pub get

# 代码生成 (Riverpod, Freezed, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# 生成多语言文件
flutter gen-l10n
```

### 运行应用

```bash
# 开发模式运行
flutter run

# 指定设备运行
flutter run -d <device_id>

# 持续监听代码变化并自动生成
flutter pub run build_runner watch
```

### 测试

```bash
# 运行所有单元测试
flutter test

# 运行集成测试
flutter test integration_test/

# 生成测试覆盖率报告
flutter test --coverage
```

**测试覆盖率要求:** ≥80%

## 📖 文档

完整的架构文档位于 `arch2/` 目录:

- [架构总览](arch2/01-core-architecture/ARCH-001_Complete_Guide.md) - 完整技术指南
- [数据架构](arch2/01-core-architecture/ARCH-002_Data_Architecture.md) - 数据库设计、加密策略
- [安全架构](arch2/01-core-architecture/ARCH-003_Security_Architecture.md) - 多层加密、密钥管理
- [状态管理](arch2/01-core-architecture/ARCH-004_State_Management.md) - Riverpod最佳实践
- [层级职责](arch2/01-core-architecture/ARCH-008_Layer_Clarification.md) - Clean Architecture详解
- [模块规范](arch2/02-module-specs/) - 各功能模块详细设计
- [ADR决策记录](arch2/03-adr/) - 技术决策文档
- [开发计划](worklog/PROJECT_DEVELOPMENT_PLAN.md) - 完整开发路线图

## 📋 开发路线图 (Roadmap)

### v0.1 — MVP (Local & Offline)
- [ ] Basic expense/income/transfer entry
- [ ] Category management
- [ ] Monthly list + monthly totals
- [ ] Local DB persistence
- [ ] CSV export

### v0.2 — Tamper-evident Ledger
- [ ] Append-only ledger structure
- [ ] Hash-chained records (detectable edits)
- [ ] Integrity Check screen (verification)
- [ ] Encrypted backup export + restore

### v0.3 — Reports & Quality
- [ ] Monthly/yearly charts
- [ ] Budget settings + alerts
- [ ] Advanced search & filters
- [ ] UX polish (quick add, templates)

### v1.0 — Release
- [ ] Store release readiness (iOS/Android)
- [ ] Full localization (EN/JA)
- [ ] Data migration strategy
- [ ] Privacy policy & in-app help

---

## Screenshots

> Coming soon.  
> Add images to `docs/screenshots/` and embed them here.

---

## License

This project is licensed under the **Apache License 2.0**.  
See the `LICENSE` file for details.

---

## Contributing

Issues and PRs welcome. Please run `flutter analyze` and `flutter test` before submitting.
