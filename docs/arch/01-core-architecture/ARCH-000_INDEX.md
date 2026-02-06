# Home Pocket MVP - 架构技术文档总索引

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完整版
**基于:** PRD_MVP_Global.md, PRD_MVP_App.md, 以及所有模块PRD

---

## 📚 文档结构概览

本目录包含 Home Pocket MVP 应用的完整架构技术设计文档，包括总体架构设计和所有子功能模块的详细技术规格。

### 核心架构文档

| 文档 | 文件名 | 内容概要 | 状态 |
|------|--------|---------|------|
| 📘 总体架构设计 | [01_MVP_Architecture_Design.md](./01_MVP_Architecture_Design.md) | MVP总体技术架构、技术栈选型、层次架构、核心设计决策 | ✅ 完成 |
| 📗 数据架构设计 | [02_Data_Architecture.md](./02_Data_Architecture.md) | 完整数据模型、数据库设计、加密策略、数据流 | ✅ 完成 |
| 📕 安全架构设计 | [03_Security_Architecture.md](./03_Security_Architecture.md) | E2EE实现、密钥管理、哈希链、生物识别 | ✅ 完成 |
| 📙 状态管理架构 | [04_State_Management.md](./04_State_Management.md) | Riverpod架构、Provider模式、依赖注入 | ✅ 完成 |
| 📔 集成模式设计 | [05_Integration_Patterns.md](./05_Integration_Patterns.md) | Repository模式、Use Case模式、CRDT同步 | ✅ 完成 |

### 功能模块技术文档

| 模块 | 文件名 | PRD来源 | 工时 | 状态 |
|------|--------|---------|------|------|
| 🔹 MOD-001/002 基础记账 | [06_MOD_BasicAccounting.md](./06_MOD_BasicAccounting.md) | PRD_Module_BasicAccounting.md | 13天 | ✅ 完成 |
| 🔹 MOD-003 双轨账本 | [07_MOD_DualLedger.md](./07_MOD_DualLedger.md) | PRD_Module_DualLedger.md | 8天 | ✅ 完成 |
| 🔹 MOD-004 家庭同步 | [08_MOD_FamilySync.md](./08_MOD_FamilySync.md) | PRD_Module_FamilySync.md | 12天 | ✅ 完成 |
| 🔹 MOD-005 OCR扫描 | [09_MOD_OCR.md](./09_MOD_OCR.md) | PRD_Module_OCR.md | 7天 | ✅ 完成 |
| 🔹 MOD-006 安全隐私 | [10_MOD_Security.md](./10_MOD_Security.md) | PRD_Module_Security.md | 10天 | ✅ 完成 |
| 🔹 MOD-007 数据分析 | [11_MOD_Analytics.md](./11_MOD_Analytics.md) | PRD_MVP_App.md | 5天 | ✅ 完成 |
| 🔹 MOD-008 设置管理 | [12_MOD_Settings.md](./12_MOD_Settings.md) | PRD_MVP_App.md | 6天 | ✅ 完成 |
| 🔹 MOD-009 国际化 (**已废弃**) | [MOD-009_Internationalization.md](../02-module-specs/MOD-009_Internationalization.md) | 已合并至 MOD-014 | - | ⚠️ 废弃 |
| 🔹 MOD-009 趣味功能 | [13_MOD_Gamification.md](./13_MOD_Gamification.md) | PRD_Module_Gamification.md | 7天 | ✅ 完成 |
| 🔹 MOD-014 国际化多语言 | [MOD-014_i18n.md](../02-module-specs/MOD-014_i18n.md) | 架构增强（规范文档） | 4天 | ✅ 完成 |

### 架构决策记录 (ADRs)

| ADR | 文件名 | 决策内容 | 状态 |
|-----|--------|---------|------|
| ADR-001 | [ADR-001_State_Management.md](./ADR-001_State_Management.md) | 选择Riverpod作为状态管理方案 | ✅ 已接受 |
| ADR-002 | [ADR-002_Database_Solution.md](./ADR-002_Database_Solution.md) | 选择Drift+SQLCipher作为数据库 | ✅ 已接受 |
| ADR-003 | [ADR-003_Multi_Layer_Encryption.md](./ADR-003_Multi_Layer_Encryption.md) | 多层加密策略设计 | ✅ 已接受 |
| ADR-004 | [ADR-004_CRDT_Sync.md](./ADR-004_CRDT_Sync.md) | CRDT同步协议选型 | ✅ 已接受 |
| ADR-005 | [ADR-005_OCR_ML_Tech.md](./ADR-005_OCR_ML_Tech.md) | OCR和ML技术选型 | ✅ 已接受 |
| ADR-006 | [ADR-006_Key_Derivation_Security.md](./ADR-006_Key_Derivation_Security.md) | 密钥派生安全修复 (HKDF+缓存) | ✅ 已实施 |
| ADR-INDEX | [ADR-INDEX.md](./ADR-INDEX.md) | 所有ADR的完整索引 | ✅ 完成 |

---

## 🎯 文档阅读指南

### 对于产品经理

**推荐阅读顺序:**
1. 📘 总体架构设计 (01) - 理解技术架构全貌
2. 🔹 各模块技术文档 (06-13) - 了解实现方案
3. 📗 数据架构 (02) - 掌握数据模型

**关注重点:**
- 技术实现的可行性
- 功能模块的依赖关系
- 开发时间和风险评估

### 对于Flutter工程师

**推荐阅读顺序:**
1. 📘 总体架构设计 (01) - 了解整体架构
2. 📙 状态管理架构 (04) - 掌握Riverpod模式
3. 📔 集成模式设计 (05) - 学习设计模式
4. 🔹 具体模块技术文档 (06-13) - 实现细节

**关注重点:**
- 代码组织结构
- 设计模式应用
- 性能优化策略
- 测试实践

### 对于架构师

**推荐阅读顺序:**
1. 📘 总体架构设计 (01) - 架构全景
2. 📗 数据架构 (02) - 数据设计
3. 📕 安全架构 (03) - 安全设计
4. 所有ADR文档 (14-18) - 设计决策

**关注重点:**
- 架构原则遵循
- 技术选型理由
- 扩展性设计
- 技术风险

### 对于安全专家

**推荐阅读顺序:**
1. 📕 安全架构设计 (03) - 安全总体设计
2. 🔹 MOD-006 安全隐私 (10) - 安全模块实现
3. 📗 数据架构 (02) - 数据加密策略
4. ADR-003 加密策略 (16) - 加密决策

**关注重点:**
- E2EE实现细节
- 密钥管理方案
- 哈希链完整性
- 隐私保护措施

---

## 📊 架构概览

### 技术栈总结

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

### 核心架构原则

1. **Local-First (本地优先)**
   - 所有数据默认存储在本地
   - 同步是可选增强功能
   - 完全离线可用

2. **Privacy by Design (隐私设计)**
   - 端到端加密（E2EE）
   - 零知识架构
   - 用户完全控制数据

3. **Clean Architecture (清晰架构)**
   - 明确的层次分离
   - 领域驱动设计
   - 可测试的组件

4. **SOLID原则**
   - 单一职责原则
   - 开放封闭原则
   - 里氏替换原则
   - 接口隔离原则
   - 依赖倒置原则

### 层次架构

```
┌─────────────────────────────────────────┐
│      Presentation Layer (展示层)        │
│  Screens, Widgets, Themes, Animations   │
├─────────────────────────────────────────┤
│   Business Logic Layer (业务逻辑层)     │
│  Providers, Use Cases, Services         │
├─────────────────────────────────────────┤
│        Domain Layer (领域层)            │
│  Models, Repository Interfaces          │
├─────────────────────────────────────────┤
│         Data Layer (数据层)             │
│  Repository Impl, DAOs, DTOs            │
├─────────────────────────────────────────┤
│    Infrastructure Layer (基础设施层)     │
│  Crypto, ML, Platform Services          │
└─────────────────────────────────────────┘
```

---

## 🏗 MVP功能模块总览

### 模块依赖关系图

```
MOD-006 (安全模块)
    ├─ 所有模块的基础（加密、密钥管理）
    │
MOD-001/002 (基础记账+分类)
    ├─ MOD-003 (双轨账本) 依赖
    ├─ MOD-005 (OCR扫描) 依赖
    ├─ MOD-007 (数据分析) 依赖
    │
MOD-003 (双轨账本)
    ├─ MOD-009 (趣味功能) 依赖
    │
MOD-006 (安全模块)
    ├─ MOD-004 (家庭同步) 依赖
    │
MOD-001/002 + MOD-003
    ├─ MOD-007 (数据分析) 依赖
```

### 开发优先级

**P0（必须有，MVP核心）:**
- MOD-006: 安全模块（基础）
- MOD-001/002: 基础记账+分类
- MOD-003: 双轨账本
- MOD-004: 家庭同步
- MOD-007: 数据分析（基础报表）

**P1（强烈建议）:**
- MOD-005: OCR扫描
- MOD-007: 高级分析（图表）
- MOD-008: 设置管理

**P2（可选，需A/B测试）:**
- MOD-009: 趣味功能

### 开发时间线

```
Week 1-3:  MOD-006 + MOD-001/002  (安全+基础记账)
Week 4-6:  MOD-003                (双轨账本)
Week 7-8:  MOD-006 + MOD-005      (安全增强+OCR)
Week 9-10: MOD-004                (家庭同步)
Week 11:   MOD-007 + MOD-008      (分析+设置)
Week 12:   MOD-009 + 测试优化     (趣味功能+打磨)
```

---

## 🔑 关键技术决策

### 已确定的技术选型

| 技术领域 | 选择方案 | 备选方案 | 决策理由 |
|---------|---------|---------|---------|
| 状态管理 | Riverpod | Bloc, GetX | 类型安全、编译时DI、DevTools优秀 |
| 数据库 | Drift + SQLCipher | Hive, Isar | 类型安全SQL、内置加密、迁移支持 |
| 加密 | Ed25519 + ChaCha20 | RSA + AES | 现代算法、性能好、安全性高 |
| OCR | ML Kit / Vision | Cloud OCR | 本地处理、隐私保护、无API成本 |
| ML分类 | TF Lite | Gemini Nano | 跨平台支持、离线、低延迟 |
| 同步协议 | CRDT (Yjs) | Automerge | 成熟度高、冲突自动解决 |
| 路由 | go_router | auto_route | 声明式、类型安全、深链接 |

详细决策理由请参考ADR文档（14-18）。

---

## 📈 性能与质量目标

### 性能指标

| 指标 | 目标 | 测试设备 | 测试方法 |
|------|------|---------|---------|
| 冷启动 | <3秒 | iPhone 12, Pixel 6 | 从点击到可交互 |
| 热启动 | <1秒 | 同上 | 从后台恢复 |
| 交易保存 | <500ms | 同上 | 含哈希计算 |
| 列表滚动 | 60fps | 同上 | 1000+条记录 |
| OCR识别 | <2秒 | 同上 | 标准小票 |
| 同步耗时 | <10秒 | 同上 | 1000条交易 |
| 内存占用 | <150MB | 同上 | 空闲状态 |
| 包体积 | <50MB | - | APK/IPA压缩后 |

### 质量指标

| 指标 | 目标 | 测试方法 |
|------|------|---------|
| 单元测试覆盖率 | >80% | flutter test --coverage |
| Widget测试覆盖率 | >60% | Widget tests |
| 集成测试覆盖率 | >20% | Integration tests |
| 崩溃率 | <1% | Firebase Crashlytics |
| 数据完整性 | 100% | 哈希链验证 |
| 同步成功率 | >95% | 同步日志分析 |

---

## 🔐 安全架构要点

### 加密层级

```
Layer 4: 传输层 (TLS 1.3 + E2EE)
         ↓
Layer 3: 文件层 (AES-GCM, 照片加密)
         ↓
Layer 2: 字段层 (ChaCha20-Poly1305, 交易备注)
         ↓
Layer 1: 数据库层 (SQLCipher AES-256)
```

### 密钥管理

- **设备密钥对**: Ed25519生成
- **存储位置**: iOS Keychain / Android KeyStore
- **恢复机制**: 24词助记词
- **密钥派生**: HKDF派生专用密钥

### 哈希链

- **算法**: SHA-256
- **结构**: 每笔交易包含前一笔交易哈希
- **用途**: 防篡改审计轨迹
- **验证**: 自动完整性检查

详细设计参见：📕 安全架构设计 (03)

---

## 🧪 测试策略

### 测试金字塔

```
      E2E Tests (10%)
      ├─ 关键用户流程
      └─ 集成场景测试

   Widget Tests (30%)
   ├─ UI组件行为
   └─ 用户交互测试

  Unit Tests (60%)
  ├─ 业务逻辑
  ├─ Use Cases
  ├─ Repositories
  └─ Services
```

### 测试覆盖重点

**必须测试:**
- 所有Use Cases（业务逻辑）
- Repository实现（数据访问）
- 加密服务（安全关键）
- 哈希链服务（完整性关键）
- CRDT服务（同步关键）

**Widget测试:**
- 关键交互组件
- 表单验证
- 导航流程
- 错误处理UI

**集成测试:**
- 端到端用户流程
- 配对+同步流程
- OCR扫描流程
- 数据导入导出

---

## 🚀 开发阶段规划

### Phase 1: 基础设施 (Week 1-3)

**目标**: 建立核心架构和基础功能

**交付物:**
- ✅ 项目结构搭建
- ✅ Drift数据库配置
- ✅ SQLCipher加密设置
- ✅ Riverpod Provider架构
- ✅ 基础UI主题系统
- ✅ 密钥生成和管理
- ✅ 基础记账功能（MOD-001/002）

**关键里程碑:**
- 数据库加密验证通过
- 基础交易CRUD完成
- 哈希链实现并测试

### Phase 2: 双轨账本 (Week 4-6)

**目标**: 实现核心差异化功能

**交付物:**
- ✅ 规则引擎分类器
- ✅ 商家数据库（500+）
- ✅ TF Lite模型集成
- ✅ 灵魂消费庆祝动画
- ✅ 双主题UI系统
- ✅ 月度报表基础

**关键里程碑:**
- 分类准确率>85%
- 双轨账本UI完善
- 自动分类流畅运行

### Phase 3: 安全增强 (Week 7-8)

**目标**: 完善安全和隐私保护

**交付物:**
- ✅ 生物识别认证
- ✅ Recovery Kit生成
- ✅ 哈希链审计UI
- ✅ OCR扫描功能（MOD-005）
- ✅ 照片加密存储
- ✅ 审计日志系统

**关键里程碑:**
- 生物识别集成完成
- OCR准确率>85%
- 完整性验证通过

### Phase 4: 家庭协作 (Week 9-10)

**目标**: 实现家庭同步功能

**交付物:**
- ✅ QR码配对
- ✅ CRDT同步协议
- ✅ 蓝牙/NFC/WiFi传输
- ✅ 冲突解决机制
- ✅ 离线队列管理
- ✅ 家庭视图切换

**关键里程碑:**
- 配对成功率>95%
- 同步冲突率<1%
- 离线队列可靠运行

### Phase 5: 完善与优化 (Week 11-12)

**目标**: 功能完善和性能优化

**交付物:**
- ✅ 数据分析图表（MOD-007）
- ✅ 设置管理（MOD-008）
- ✅ 趣味功能（MOD-009，可选）
- ✅ 性能优化
- ✅ 测试覆盖率>80%
- ✅ Bug修复

**关键里程碑:**
- 所有P0功能完成
- 性能指标达标
- Beta测试准备就绪

---

## 📝 文档使用说明

### 文档规范

所有架构文档遵循以下规范：

1. **Markdown格式**: 使用GitHub Flavored Markdown
2. **代码示例**: 使用Dart语言，遵循Flutter官方风格指南
3. **图表**: 使用ASCII艺术或Mermaid
4. **版本控制**: 每个文档包含版本号和更新日期

### 代码示例约定

```dart
// ✅ 好的示例：清晰、完整、可运行
class GoodExample {
  final String property;

  GoodExample({required this.property});

  void method() {
    // 实现细节
  }
}

// ❌ 避免：不完整、难理解
class BadExample {
  var x;
  doSomething() { /* ... */ }
}
```

### 图表规范

```
# 系统架构使用ASCII图
┌─────────┐
│  组件A   │
└────┬────┘
     │ 依赖
     ▼
┌─────────┐
│  组件B   │
└─────────┘

# 流程使用箭头图
User → System → Database
       ↓
     Result
```

---

## 🔄 文档维护

### 更新频率

- **架构文档**: 重大架构变更时更新
- **模块文档**: 实现细节变更时更新
- **ADR文档**: 新增重大技术决策时添加

### 版本管理

文档版本遵循语义化版本：
- **主版本**: 架构重大变更
- **次版本**: 新增模块或重要功能
- **修订版**: 文档修正和小改进

当前版本: **1.0.0**

---

## 📞 反馈与问题

### 文档问题

如发现文档错误或遗漏：
1. 记录具体文档和章节
2. 说明问题描述
3. 提供改进建议（如有）

### 技术讨论

架构和技术相关讨论：
1. 参考相关ADR文档
2. 基于现有架构提出问题
3. 考虑对现有设计的影响

---

## 📚 参考资源

### 内部文档
- [PRD_MVP_Global.md](../doc/requirement/PRD_MVP_Global.md)
- [PRD_MVP_App.md](../doc/requirement/PRD_MVP_App.md)
- [PRD_Index.md](../doc/requirement/PRD_Index.md)
- 所有模块PRD文档

### 外部资源
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

---

## ✅ 文档完成度

| 类别 | 数量 | 状态 |
|------|------|------|
| 核心架构文档 | 5 | ✅ 100% |
| 功能模块文档 | 9 | ✅ 100% |
| ADR决策记录 | 6 | ✅ 100% |
| **总计** | **20** | **✅ 100%** |

---

**文档状态**: 🟢 **完整版已生成**
**覆盖范围**: 总体架构 + 所有MVP模块 + 关键技术决策
**适用阶段**: MVP开发全周期（Week 1-12）

**生成信息**:
- 生成工具: Claude Sonnet 4.5 + senior-architect skill
- 生成日期: 2026-02-03
- 文档版本: 1.0
- 基于PRD: 12个PRD文档全面分析
