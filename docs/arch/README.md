# Home Pocket MVP - 架构技术文档 (arch2)

**文档版本:** 2.0
**更新日期:** 2026-02-03
**状态:** ✅ 完整版 - 已重构
**生成工具:** Claude Sonnet 4.5 + senior-architect skill

---

## 📁 目录结构

本目录采用模块化架构文档组织结构，按文档类型分为三个子目录：

```
arch2/
├── 01-core-architecture/        # 整体架构文档
│   ├── ARCH-000_INDEX.md       # 架构文档总索引
│   ├── ARCH-001_Complete_Guide.md
│   ├── ARCH-002_Data_Architecture.md
│   ├── ARCH-003_Security_Architecture.md
│   ├── ARCH-004_State_Management.md
│   ├── ARCH-005_Integration_Patterns.md
│   ├── ARCH-006_Error_Boundaries.md
│   ├── ARCH-007_Architecture_Diagram_I18N.md
│   ├── ARCH-008_Layer_Clarification.md
│   └── ARCH-009_I18N_Update_Summary.md
│
├── 02-module-specs/              # 模块功能架构文档
│   ├── MOD-001_BasicAccounting.md
│   ├── MOD-002_DualLedger.md
│   ├── MOD-003_FamilySync.md
│   ├── MOD-004_OCR.md
│   ├── MOD-005_Security.md
│   ├── MOD-006_Analytics.md
│   ├── MOD-007_Settings.md
│   ├── MOD-008_Gamification.md
│   └── MOD-009_Internationalization.md
│
├── 03-adr/                       # 架构决策记录 (ADR)
│   ├── ADR-000_INDEX.md         # ADR总索引
│   ├── ADR-001_State_Management.md
│   ├── ADR-002_Database_Solution.md
│   ├── ADR-003_Multi_Layer_Encryption.md
│   ├── ADR-004_CRDT_Sync.md
│   ├── ADR-005_OCR_ML_Tech.md
│   ├── ADR-006_Key_Derivation_Security.md
│   └── ADR-007_Layer_Responsibilities.md
│
└── README.md                     # 本文件
```

---

## 📋 文档分类说明

### 1️⃣ 整体架构文档 (01-core-architecture/)

包含应用的核心架构设计文档，定义了整体技术栈、分层架构、设计模式等。

**关键文档:**
- `ARCH-000_INDEX.md` - 架构文档索引和导航
- `ARCH-001_Complete_Guide.md` - 完整架构指南（最重要的文档）
- `ARCH-002_Data_Architecture.md` - 数据架构和数据库设计
- `ARCH-003_Security_Architecture.md` - 安全架构和加密方案

**适合阅读人群:**
- 架构师 - 了解整体技术架构和设计决策
- Tech Lead - 掌握技术栈和实现路径
- 新加入团队的工程师 - 快速了解项目架构

### 2️⃣ 模块功能架构文档 (02-module-specs/)

包含每个功能模块的详细技术设计文档，定义了模块的接口、实现细节、数据流等。

**模块列表:**
- `MOD-001` - 基础记账
- `MOD-002` - 双轨账本
- `MOD-003` - 家庭同步
- `MOD-004` - OCR扫描
- `MOD-005` - 安全模块
- `MOD-006` - 数据分析
- `MOD-007` - 设置管理
- `MOD-008` - 趣味功能
- `MOD-009` - 国际化多语言

**适合阅读人群:**
- Flutter 工程师 - 开发具体模块功能
- QA 工程师 - 了解模块功能和测试要点
- 产品经理 - 了解技术实现方案

### 3️⃣ 架构决策记录 (03-adr/)

记录所有重要的架构和技术决策，包括决策背景、考虑的方案、最终选择及理由。

**已记录的决策:**
- `ADR-001` - 选择 Riverpod 作为状态管理方案
- `ADR-002` - 选择 Drift + SQLCipher 作为数据库
- `ADR-003` - 多层加密策略设计
- `ADR-004` - CRDT 同步协议选型
- `ADR-005` - OCR 和 ML 技术选型
- `ADR-006` - 密钥派生安全修复
- `ADR-007` - 架构层职责划分

**适合阅读人群:**
- 架构师 - 了解技术选型理由
- Tech Lead - 进行类似技术决策时参考
- 新加入团队的高级工程师 - 理解技术选择的背景

---

## 📖 快速开始

### 对于新加入的工程师

**推荐阅读顺序:**
1. 📘 `01-core-architecture/ARCH-000_INDEX.md` - 从总索引开始
2. 📗 `01-core-architecture/ARCH-001_Complete_Guide.md` - 完整架构指南
3. 📕 具体负责的模块文档（在 `02-module-specs/` 目录下）
4. 📙 相关的 ADR 决策记录（在 `03-adr/` 目录下）

### 对于产品经理

**推荐阅读顺序:**
1. 📘 `01-core-architecture/ARCH-000_INDEX.md` - 了解整体结构
2. 📗 `02-module-specs/` 目录下的各个模块文档
3. 关注每个模块的"功能概览"和"开发时间估算"部分

### 对于架构师

**推荐阅读顺序:**
1. 📘 `01-core-architecture/ARCH-001_Complete_Guide.md` - 完整架构
2. 📗 `03-adr/` 目录下的所有 ADR 文档
3. 📕 `01-core-architecture/ARCH-002_Data_Architecture.md` - 数据架构
4. 📙 `01-core-architecture/ARCH-003_Security_Architecture.md` - 安全架构

---

## 🎯 技术栈概览

```yaml
平台: Flutter 3.16+ / Dart 3.2+
架构模式: Clean Architecture + Repository Pattern
状态管理: Riverpod 2.4+
数据库: Drift (SQLite) + SQLCipher
加密: Ed25519 + ChaCha20-Poly1305 + AES-256
OCR: ML Kit (Android) / Vision Framework (iOS)
机器学习: TensorFlow Lite
同步协议: CRDT (Yjs-inspired)
测试: flutter_test + integration_test
CI/CD: GitHub Actions
```

---

## 📝 文档命名规则

### 整体架构文档 (ARCH-)
- **格式:** `ARCH-{编号}_{名称}.md`
- **编号规则:** 3位数字（000-999），从 000 开始
- **编号 000:** 保留给索引文件 (INDEX.md)
- **示例:** `ARCH-001_Complete_Guide.md`

### 模块功能架构文档 (MOD-)
- **格式:** `MOD-{编号}_{模块名称}.md`
- **编号规则:** 3位数字（000-999），从 001 开始
- **编号对应:** 按照模块开发优先级排序
- **示例:** `MOD-001_BasicAccounting.md`

### 架构决策记录 (ADR-)
- **格式:** `ADR-{编号}_{决策主题}.md`
- **编号规则:** 3位数字（000-999），从 000 开始
- **编号 000:** 保留给索引文件 (INDEX.md)
- **示例:** `ADR-001_State_Management.md`

**注意事项:**
- 所有编号使用 3 位数字，不足 3 位前面补 0
- 编号按照创建顺序递增，不要跳号
- 文件名使用英文和下划线，不使用中划线（除了前缀）
- 名称部分使用 PascalCase（每个单词首字母大写）

---

## 🔄 文档维护指南

### 添加新的架构文档

1. 确定文档类型（架构/模块/ADR）
2. 查看对应目录下的最大编号
3. 使用 `最大编号 + 1` 作为新文档编号
4. 按照命名规则创建文件
5. 更新对应目录的 INDEX.md 文件

### 更新现有文档

1. 直接修改对应的文档文件
2. 更新文档头部的版本号和修改日期
3. 在文档末尾的"变更历史"部分记录修改内容

### 删除文档

1. 不要删除已有编号的文档
2. 如果文档已过时，在文档头部添加 `[已废弃]` 标记
3. 在废弃说明中注明替代文档
4. 从 INDEX.md 中移除链接，但保留编号记录

---

## 📊 文档统计

| 分类 | 文件数量 | 状态 |
|------|---------|------|
| 整体架构文档 | 10 | ✅ 完成 |
| 模块功能文档 | 9 | ✅ 完成 |
| ADR 决策记录 | 8 | ✅ 完成 |
| **总计** | **27** | **✅ 完成** |

---

## 🔗 相关资源

### 内部文档
- [PRD 文档目录](../doc/requirement/) - 产品需求文档
- [原始 arch 目录](../arch/) - 第一版架构文档（已废弃）

### 外部资源
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [ADR 模板和最佳实践](https://github.com/joelparkerhenderson/architecture-decision-record)

---

## ✅ 文档完成度检查表

- [x] 目录结构重构完成
- [x] 文件命名规则统一
- [x] 整体架构文档完整
- [x] 模块功能文档完整
- [x] ADR 决策记录完整
- [x] README 文档更新
- [x] Claude Rules 文件创建

---

**维护说明:**
- 本文档随着项目架构演进持续更新
- 如有疑问或建议，请联系架构团队
- 文档版本与项目版本保持同步

**文档状态:** 🟢 **完整版，可直接用于 MVP 开发**
