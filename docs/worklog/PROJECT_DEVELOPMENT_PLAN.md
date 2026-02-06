# Home Pocket 项目开发计划
# Project Development Plan

**文档版本:** 1.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-03
**状态:** 已批准

---

## 1. 项目概述 (Project Overview)

### 1.1 项目信息

- **项目名称:** Home Pocket - 家庭记账应用
- **项目愿景:** 本地优先、隐私保护、双轨记账的家庭财务管理工具
- **目标平台:** iOS 14+ / Android 7+ (API 24+)
- **技术框架:** Flutter 3.16+ / Dart 3.2+

### 1.2 核心特性

1. **双轨账本系统**
   - 生存账本 (Survival Ledger)：日常必需开支
   - 灵魂账本 (Soul Ledger)：自我投资与享乐消费
   - 智能3层分类引擎（规则引擎 → 商户库 → ML分类器）
   - 85%+ 自动分类准确率

2. **多层加密防护**
   - 4层安全架构：生物识别 → PIN码 → 字段加密 → 数据库加密
   - Ed25519 设备密钥对
   - ChaCha20-Poly1305 敏感字段加密
   - SQLCipher 数据库全盘加密
   - 区块链风格哈希链完整性验证

3. **家庭P2P同步**
   - 无需中心服务器
   - QR码面对面配对
   - BLE/NFC/WiFi Direct 多协议同步
   - CRDT (Yjs) 冲突解决
   - 离线队列支持

4. **OCR智能扫描**
   - 相机/相册小票识别
   - 金额准确率 >90%
   - 日期准确率 >85%
   - 商户准确率 >80%
   - AES-GCM 加密照片存储

5. **离线优先架构**
   - 零依赖服务器
   - 完全本地数据存储
   - 离线完整功能
   - P2P设备同步

### 1.3 项目目标

**MVP目标 (v1.0):**
- 完整的双轨记账功能
- 多层加密安全保障
- 家庭设备同步
- 数据分析与报表
- 3语言支持（日文、中文、英文）

**增强功能目标 (v1.1+):**
- OCR智能扫描
- 游戏化体验（大谷换算器、运势系统）
- 高级数据分析

---

## 2. 架构设计原则

### 2.1 核心架构原则

1. **Clean Architecture (5层架构)**
   ```
   Presentation Layer (UI)
        ↓
   Application Layer (Business Logic)
        ↓
   Domain Layer (Entities & Use Cases)
        ↓
   Infrastructure Layer (Data Access)
        ↓
   Foundation Layer (Core Utilities)
   ```

2. **Local-First (本地优先)**
   - 零依赖服务器
   - 完全离线功能
   - P2P设备同步
   - 用户完全控制数据

3. **Privacy by Design (隐私优先)**
   - 零知识架构
   - 端到端加密
   - 无遥测数据收集
   - 生物识别可选

4. **Defense in Depth (多层防御)**
   - 4层安全防护
   - 增量哈希链验证
   - 加密密钥派生
   - 安全备份恢复

5. **Immutability (不可变性)**
   - 所有数据操作使用不可变模式
   - 禁止对象mutation
   - 函数式编程范式

### 2.2 技术栈

**核心框架:**
- Flutter 3.16+
- Dart 3.2+

**状态管理:**
- flutter_riverpod 2.4+
- freezed (不可变数据类)

**数据持久化:**
- Drift 2.14+ (类型安全SQL)
- SQLCipher (数据库加密)

**加密安全:**
- Ed25519 (非对称加密)
- ChaCha20-Poly1305 (AEAD字段加密)
- AES-256-GCM (文件加密)
- AES-256-CBC (数据库加密)

**同步协议:**
- Yjs (CRDT)
- BLE/NFC/WiFi Direct

**OCR/ML:**
- ML Kit (Google)
- Vision Framework (Apple)
- TensorFlow Lite

**导航路由:**
- go_router 13.0+

**图表分析:**
- fl_chart

**国际化:**
- flutter_localizations
- intl

---

## 3. 开发阶段与模块划分

### 阶段 1: 基础设施层 (2周) - Phase 1: Foundation

#### 模块 MOD-006: 安全与隐私 (10天)

**优先级:** P0 (MVP核心)
**依赖:** 无 (基础模块)
**文档:** arch2/02-module-specs/MOD-006_SecurityAndPrivacy.md

**关键交付物:**

1. **密钥管理系统**
   - Ed25519 设备密钥对生成
   - HKDF 密钥派生 (用途分离)
   - 24词 BIP39 恢复助记词
   - 内存密钥缓存

2. **生物识别锁**
   - Face ID (iOS)
   - Touch ID (iOS)
   - 指纹识别 (Android)
   - PIN码备选方案
   - 自动锁定 (5分钟无活动)

3. **字段加密**
   - ChaCha20-Poly1305 (AEAD)
   - 敏感字段加密: amount, note, category
   - 增量加密/解密
   - 批量操作优化

4. **数据库加密**
   - SQLCipher 集成
   - AES-256-CBC
   - 256,000次 PBKDF2 迭代
   - 4KB页大小

5. **哈希链完整性**
   - 区块链风格链式哈希
   - 增量验证 (100-2000x性能提升)
   - SHA-256 哈希算法
   - 防篡改检测

**数据模型:**
```dart
// entities/security_key.dart
@freezed
class SecurityKey with _$SecurityKey {
  const factory SecurityKey({
    required String deviceId,
    required String publicKey,
    required String encryptedPrivateKey,
    required List<String> mnemonicWords,
    required DateTime createdAt,
  }) = _SecurityKey;
}

// entities/hash_chain.dart
@freezed
class HashChainNode with _$HashChainNode {
  const factory HashChainNode({
    required String transactionId,
    required String currentHash,
    required String previousHash,
    required DateTime timestamp,
  }) = _HashChainNode;
}
```

**测试用例:**
- 密钥生成与恢复测试
- 助记词验证测试
- 生物识别集成测试
- 加密/解密性能测试
- 哈希链完整性测试
- 篡改检测测试

**测试覆盖率要求:** ≥80%

---

#### 模块 MOD-014: 国际化 (4天) - 可并行开发

**优先级:** P0 (MVP核心)
**依赖:** 无 (可独立开发)
**文档:** arch2/02-module-specs/MOD-014_i18n.md

**关键交付物:**

1. **多语言支持**
   - 日文 (ja) - 默认语言
   - 中文 (zh-CN)
   - 英文 (en)
   - ARB 文件配置

2. **本地化功能**
   - 运行时语言切换
   - 系统语言自动检测
   - 日期格式化 (locale-aware)
   - 数字格式化
   - 货币格式化

3. **文化适配**
   - RTL语言支持准备
   - 日期格式 (YYYY/MM/DD vs MM/DD/YYYY)
   - 货币符号位置
   - 数字分隔符

**ARB文件结构:**
```
lib/l10n/
├── app_en.arb (英文)
├── app_ja.arb (日文 - 默认)
└── app_zh.arb (中文)
```

**关键翻译项:**
- 导航菜单 (25项)
- 分类名称 (20+项)
- 错误消息 (30+项)
- 按钮标签 (15项)
- 帮助文档 (10页)

**测试用例:**
- 语言切换测试
- 格式化函数测试
- 回退语言测试
- 缺失翻译处理
- ARB文件语法验证

**测试覆盖率要求:** ≥80%

---

### 阶段 2: 核心记账功能 (3周) - Phase 2: Core Accounting

#### 模块 MOD-001: 基础记账与分类 (13天)

**优先级:** P0 (MVP核心)
**依赖:** MOD-006 (安全)
**文档:** doc/arch/02-module-specs/MOD-001_BasicAccounting.md

**关键交付物:**

1. **快速记账**
   - 3秒内完成交易创建
   - 金额、分类、账本选择
   - 可选备注、日期
   - 模板支持

2. **分类体系**
   - 3级分类结构
   - 20+预设分类
   - 自定义分类支持
   - 分类图标与颜色

3. **交易管理**
   - CRUD操作 (Create, Read, Update, Delete)
   - 交易搜索 (金额、分类、日期范围)
   - 批量操作 (删除、分类变更)
   - 交易历史查看

4. **数据导入**
   - CSV格式支持
   - 银行对账单导入
   - 字段映射配置
   - 重复检测

5. **性能优化**
   - 增量余额更新 (40-400x性能提升)
   - 分页加载 (50-100项/页)
   - 复合索引: (bookId, timestamp)
   - 虚拟滚动

**数据模型:**
```dart
// entities/transaction.dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String bookId,
    required double amount,
    required String categoryId,
    String? note,
    required DateTime timestamp,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String hashChainNode,
  }) = _Transaction;
}

// entities/category.dart
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level, // 1, 2, 3
  }) = _Category;
}

// entities/book.dart
@freezed
class Book with _$Book {
  const factory Book({
    required String id,
    required String name,
    required double currentBalance,
    required DateTime lastUpdated,
  }) = _Book;
}
```

**预设分类示例 (20+):**

| Level 1 | Level 2 | Level 3 | 图标 |
|---------|---------|---------|------|
| 食费 | 外食 | - | 🍜 |
| 食费 | 自炊 | - | 🥘 |
| 住居 | 家賃 | - | 🏠 |
| 交通 | 電車 | - | 🚃 |
| 医療 | 病院 | - | 🏥 |
| 娯楽 | 映画 | - | 🎬 |
| ... | ... | ... | ... |

**测试用例:**
- 交易CRUD测试
- 分类管理测试
- 搜索功能测试
- 增量余额更新性能测试
- CSV导入测试
- 大数据量测试 (10000+交易)

**测试覆盖率要求:** ≥80%

**性能目标:**
- 增量余额更新: 40-400x vs 全量重算
- 交易创建: < 3秒
- 列表滚动: 60 FPS

---

#### 模块 MOD-003: 双轨账本 (8天)

**优先级:** P0 (MVP核心)
**依赖:** MOD-001, MOD-006
**文档:** arch2/02-module-specs/MOD-003_DualLedger.md

**关键交付物:**

1. **3层分类引擎**
   - **Layer 1: 规则引擎** (优先级最高)
     - 用户自定义规则
     - 关键词匹配
     - 金额范围规则
   - **Layer 2: 商户数据库** (500+日本商户)
     - 商户名称匹配
     - 分类映射
     - 置信度评分
   - **Layer 3: ML分类器** (回退方案)
     - TensorFlow Lite
     - 历史交易训练
     - 增量学习

2. **双账本视图**
   - 生存账本 (Survival Ledger)
     - 必需开支: 食费、住居、交通、医療
     - 绿色主题
   - 灵魂账本 (Soul Ledger)
     - 享乐消费: 娯楽、趣味、自己投資
     - 紫色主题
     - 庆祝动画

3. **商户数据库 (500+)**
   ```dart
   // data/merchants_ja.dart
   const merchants = [
     Merchant(
       name: "セブンイレブン",
       category: "food_convenience",
       ledgerType: LedgerType.survival,
       confidence: 0.95,
     ),
     Merchant(
       name: "スターバックス",
       category: "leisure_cafe",
       ledgerType: LedgerType.soul,
       confidence: 0.90,
     ),
     // ... 500+ merchants
   ];
   ```

4. **分类准确率**
   - 目标: 85%+ 自动分类准确率
   - 用户纠错反馈机制
   - 规则学习与优化

5. **灵魂消费庆祝**
   - Lottie 动画
   - Toast 消息
   - 积分奖励

**数据模型:**
```dart
// entities/ledger_type.dart
enum LedgerType {
  survival, // 生存账本
  soul,     // 灵魂账本
}

// entities/classification_rule.dart
@freezed
class ClassificationRule with _$ClassificationRule {
  const factory ClassificationRule({
    required String id,
    required String keyword,
    required String categoryId,
    required LedgerType ledgerType,
    required int priority,
    double? minAmount,
    double? maxAmount,
  }) = _ClassificationRule;
}

// entities/merchant.dart
@freezed
class Merchant with _$Merchant {
  const factory Merchant({
    required String name,
    required String categoryId,
    required LedgerType ledgerType,
    required double confidence,
  }) = _Merchant;
}
```

**ML模型:**
- 算法: Random Forest / Naive Bayes
- 训练数据: 用户历史交易 (100+)
- 特征: 金额、时间、备注关键词
- 模型大小: < 2MB
- 推理时间: < 50ms

**测试用例:**
- 规则引擎匹配测试
- 商户数据库查询测试
- ML分类器准确率测试
- 分类置信度测试
- 用户纠错学习测试
- 庆祝动画触发测试

**测试覆盖率要求:** ≥80%

**准确率目标:** 85%+

---

### 阶段 3: 数据同步与分析 (4周) - Phase 3: Sync & Analytics

#### 模块 MOD-004: 家庭同步 (12天)

**优先级:** P0 (MVP核心)
**依赖:** MOD-006, MOD-001
**文档:** arch2/02-module-specs/MOD-004_FamilySync.md

**关键交付物:**

1. **设备配对**
   - QR码生成与扫描
   - 面对面配对流程
   - Ed25519 密钥交换
   - 设备昵称设置

2. **多协议同步**
   - BLE (蓝牙低功耗) - 优先
   - NFC (近场通信) - iOS 13+
   - WiFi Direct - Android
   - 自动协议选择

3. **CRDT冲突解决**
   - Yjs 集成
   - Last-Write-Wins (LWW)
   - 向量时钟 (Vector Clock)
   - 操作转换 (OT)

4. **内部转账**
   - 2阶段提交 (2PC)
   - 原子性保证
   - 转账记录审计
   - 回滚机制

5. **离线队列**
   - 离线操作缓存
   - 自动重试机制
   - 冲突检测与解决
   - 同步状态显示

**数据模型:**
```dart
// entities/device.dart
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String publicKey,
    required String nickname,
    required DateTime pairedAt,
    required DateTime lastSyncAt,
    required bool isActive,
  }) = _Device;
}

// entities/sync_operation.dart
@freezed
class SyncOperation with _$SyncOperation {
  const factory SyncOperation({
    required String id,
    required String type, // create, update, delete
    required String entityType, // transaction, category, etc.
    required String entityId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
    required String deviceId,
    required SyncStatus status,
  }) = _SyncOperation;
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  conflict,
  failed,
}

// entities/internal_transfer.dart
@freezed
class InternalTransfer with _$InternalTransfer {
  const factory InternalTransfer({
    required String id,
    required String fromBookId,
    required String toBookId,
    required double amount,
    required String note,
    required DateTime timestamp,
    required TransferStatus status,
  }) = _InternalTransfer;
}

enum TransferStatus {
  pending,
  committed,
  rolledBack,
}
```

**同步协议流程:**
```
1. 设备A生成QR码 (包含publicKey)
2. 设备B扫描QR码
3. 密钥交换与验证
4. 建立加密通道 (Ed25519 + ChaCha20-Poly1305)
5. 协商同步协议 (BLE/NFC/WiFi Direct)
6. 交换向量时钟
7. 计算差异集
8. 增量同步数据
9. CRDT冲突解决
10. 更新向量时钟
11. 验证完整性 (哈希链)
```

**测试用例:**
- QR码配对测试
- 密钥交换测试
- BLE/NFC/WiFi Direct连接测试
- CRDT冲突解决测试
- 内部转账2PC测试
- 离线队列测试
- 哈希链同步验证测试

**测试覆盖率要求:** ≥80%

---

#### 模块 MOD-007: 数据分析与报表 (8天)

**优先级:** P0 (MVP核心)
**依赖:** MOD-001, MOD-003
**文档:** arch2/02-module-specs/MOD-007_Analytics.md

**关键交付物:**

1. **月度报表**
   - 总收入
   - 总支出
   - 净储蓄
   - 储蓄率
   - 月度对比

2. **分类分析**
   - 支出分类占比饼图
   - Top 10 支出分类
   - 分类趋势折线图
   - 双轨账本对比

3. **趋势分析**
   - 支出趋势折线图 (6个月)
   - 收入趋势折线图
   - 储蓄趋势折线图
   - 周/月/年视图

4. **预算跟踪**
   - 分类预算设置
   - 预算使用率进度条
   - 超支告警 (80%, 90%, 100%)
   - 预算建议

5. **报表导出**
   - PDF报表生成
   - 包含图表与数据表
   - 月度/季度/年度报表
   - 邮件分享

**数据模型:**
```dart
// entities/monthly_report.dart
@freezed
class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
    required double netSavings,
    required double savingsRate,
    required Map<String, double> categoryBreakdown,
    required Map<LedgerType, double> ledgerBreakdown,
  }) = _MonthlyReport;
}

// entities/budget.dart
@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String categoryId,
    required double monthlyLimit,
    required double currentSpent,
    required int year,
    required int month,
  }) = _Budget;
}
```

**图表类型 (fl_chart):**
- 饼图 (PieChart): 分类占比
- 折线图 (LineChart): 趋势分析
- 柱状图 (BarChart): 月度对比
- 进度条 (LinearProgressIndicator): 预算跟踪

**测试用例:**
- 月度报表计算测试
- 分类统计测试
- 趋势计算测试
- 预算跟踪测试
- PDF生成测试
- 图表渲染测试

**测试覆盖率要求:** ≥80%

---

#### 模块 MOD-008: 设置管理 (6天)

**优先级:** P0 (MVP核心)
**依赖:** MOD-006, MOD-001
**文档:** arch2/02-module-specs/MOD-008_Settings.md

**关键交付物:**

1. **应用偏好设置**
   - 主题 (浅色/深色/自动)
   - 语言 (日文/中文/英文)
   - 默认货币 (JPY/CNY/USD)
   - 通知设置
   - 默认账本

2. **备份与恢复**
   - AES-GCM 加密备份导出
   - 密码保护
   - 自动备份 (每日/每周/每月)
   - iCloud/Google Drive 集成
   - 恢复验证

3. **设备管理**
   - 已配对设备列表
   - 设备昵称编辑
   - 设备解除配对
   - 同步状态查看
   - 最后同步时间

4. **安全设置**
   - 生物识别开关
   - PIN码设置/修改
   - 自动锁定时间 (1/5/15分钟)
   - 重置哈希链
   - 查看恢复助记词

5. **关于页面**
   - 应用版本
   - 开源许可证
   - 隐私政策
   - 使用条款
   - 帮助文档

**数据模型:**
```dart
// entities/app_settings.dart
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required ThemeMode themeMode,
    required String locale,
    required String defaultCurrency,
    required bool notificationsEnabled,
    required String defaultBookId,
    required bool biometricEnabled,
    required int autoLockMinutes,
    required BackupFrequency backupFrequency,
  }) = _AppSettings;
}

enum ThemeMode { light, dark, system }
enum BackupFrequency { daily, weekly, monthly, manual }

// entities/backup_file.dart
@freezed
class BackupFile with _$BackupFile {
  const factory BackupFile({
    required String filename,
    required DateTime createdAt,
    required int fileSize,
    required String checksum,
  }) = _BackupFile;
}
```

**备份文件格式:**
```json
{
  "version": "1.0",
  "timestamp": "2026-02-03T12:00:00Z",
  "deviceId": "device-uuid",
  "checksum": "sha256-hash",
  "data": {
    "transactions": [...],
    "categories": [...],
    "books": [...],
    "settings": {...}
  },
  "encryption": {
    "algorithm": "AES-256-GCM",
    "iv": "base64-encoded-iv",
    "salt": "base64-encoded-salt"
  }
}
```

**测试用例:**
- 设置保存与读取测试
- 备份加密/解密测试
- 备份完整性验证测试
- 恢复流程测试
- 设备管理测试
- iCloud/Google Drive集成测试

**测试覆盖率要求:** ≥80%

---

### 阶段 4: 增强功能 (2周) - Phase 4: Enhanced Features

#### 模块 MOD-005: OCR扫描 (7天)

**优先级:** P1 (强烈推荐)
**依赖:** MOD-001, MOD-003, MOD-006
**文档:** arch2/02-module-specs/MOD-005_OCR.md

**关键交付物:**

1. **图像采集**
   - 相机拍摄
   - 相册选择
   - 裁剪与旋转
   - 预览确认

2. **图像预处理**
   - 灰度化
   - 二值化 (Otsu算法)
   - 降噪 (高斯滤波)
   - 透视校正
   - 对比度增强

3. **文本识别**
   - **iOS:** Vision Framework
   - **Android:** ML Kit
   - 金额识别 (正则表达式: `¥?\d{1,3}(,\d{3})*`)
   - 日期识别 (多格式支持)
   - 商户名称识别

4. **智能解析**
   - 金额提取与验证
   - 日期格式转换
   - 商户数据库匹配
   - 自动分类 (基于商户)
   - 置信度评分

5. **加密存储**
   - AES-GCM 加密照片
   - 缩略图生成
   - 安全删除
   - 存储配额管理

**数据模型:**
```dart
// entities/receipt.dart
@freezed
class Receipt with _$Receipt {
  const factory Receipt({
    required String id,
    required String transactionId,
    required String encryptedImagePath,
    required String thumbnailPath,
    required DateTime scannedAt,
    required OcrResult ocrResult,
  }) = _Receipt;
}

// entities/ocr_result.dart
@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({
    double? amount,
    DateTime? date,
    String? merchantName,
    String? categoryId,
    required double amountConfidence,
    required double dateConfidence,
    required double merchantConfidence,
    required String rawText,
  }) = _OcrResult;
}
```

**准确率目标:**
- 金额识别: >90%
- 日期识别: >85%
- 商户识别: >80%

**性能目标:**
- 图像预处理: < 500ms
- OCR识别: < 2秒
- 总流程: < 5秒

**测试用例:**
- 图像预处理测试
- OCR识别准确率测试
- 金额提取测试 (多格式)
- 日期解析测试 (多格式)
- 商户匹配测试
- 加密/解密测试
- 性能基准测试

**测试覆盖率要求:** ≥80%

---

#### 模块 MOD-013: 游戏化体验 (待定)

**优先级:** P1 (推荐)
**依赖:** MOD-001
**文档:** arch2/02-module-specs/MOD-013_Gamification.md

**关键交付物:**

1. **大谷换算器**
   - 将消费金额转换为趣味单位
   - 示例: "这笔消费 = 3个棒球手套"
   - 自定义换算单位
   - Toast动画展示

2. **运势系统**
   - 每日运势 (5级)
     - 大吉 (20%)
     - 中吉 (30%)
     - 吉 (30%)
     - 小吉 (15%)
     - 凶 (5%)
   - 运势主题色
   - 翻牌动画
   - 运势建议

3. **动画效果**
   - Lottie 动画
   - 庆祝特效
   - Toast消息
   - 翻牌交互

4. **OTA配置**
   - 远程配置更新
   - 换算单位库更新
   - 运势文案更新
   - A/B测试支持

**数据模型:**
```dart
// entities/conversion_unit.dart
@freezed
class ConversionUnit with _$ConversionUnit {
  const factory ConversionUnit({
    required String id,
    required String name,
    required double priceJPY,
    required String icon,
    required String category,
  }) = _ConversionUnit;
}

// entities/daily_fortune.dart
@freezed
class DailyFortune with _$DailyFortune {
  const factory Fortune({
    required FortuneLevel level,
    required String message,
    required String advice,
    required DateTime date,
  }) = _DailyFortune;
}

enum FortuneLevel {
  daikichi,  // 大吉
  chukichi,  // 中吉
  kichi,     // 吉
  shokichi,  // 小吉
  kyo,       // 凶
}
```

**换算单位示例:**
```dart
const conversionUnits = [
  ConversionUnit(
    name: "棒球手套",
    priceJPY: 15000,
    icon: "⚾",
  ),
  ConversionUnit(
    name: "拉面",
    priceJPY: 800,
    icon: "🍜",
  ),
  ConversionUnit(
    name: "咖啡",
    priceJPY: 500,
    icon: "☕",
  ),
  // ... more units
];
```

**测试用例:**
- 换算逻辑测试
- 运势生成测试
- 动画触发测试
- OTA配置加载测试

**测试覆盖率要求:** ≥80%

---

## 4. 关键里程碑

| 里程碑 | 完成时间 | 交付物 | 验收标准 |
|--------|----------|--------|----------|
| **M1: 安全基础设施完成** | Week 2 | MOD-006, MOD-014 | - 密钥管理系统可用<br>- 生物识别锁正常<br>- 4层加密正常<br>- 3语言支持完整 |
| **M2: 基础记账功能完成** | Week 5 | MOD-001, MOD-003 | - 快速记账< 3秒<br>- 分类体系完整<br>- 双轨分类≥85%准确率<br>- 增量余额更新正常 |
| **M3: 同步与分析完成** | Week 9 | MOD-004, MOD-007, MOD-008 | - QR码配对成功率>95%<br>- CRDT冲突解决正常<br>- 月度报表准确<br>- 备份/恢复正常 |
| **M4: MVP发布** | Week 10 | 完整MVP (P0模块) | - 所有P0模块测试覆盖率≥80%<br>- 性能指标达标<br>- 安全审查通过<br>- TestFlight/Play内测上线 |
| **M5: 增强功能完成** | Week 12 | MOD-005, MOD-013 | - OCR准确率达标<br>- 游戏化功能完整<br>- 完整版发布 |

**MVP总工期:** 10周（P0模块：61天开发 + 缓冲时间）
**完整版总工期:** 12周（包含P1模块：~71天开发 + 缓冲时间）

---

## 5. 依赖关系图

```
依赖关系 (Dependency Graph)
─────────────────────────────

MOD-006 (Security & Privacy) ← 无依赖，最先开发
    ↓
    ├─→ MOD-001 (Basic Accounting)
    │       ↓
    │       ├─→ MOD-003 (Dual Ledger)
    │       │       ↓
    │       │       └─→ MOD-005 (OCR) [P1]
    │       │
    │       ├─→ MOD-004 (Family Sync)
    │       ├─→ MOD-007 (Analytics & Reports)
    │       ├─→ MOD-008 (Settings Management)
    │       └─→ MOD-013 (Gamification) [P1]
    │
    └─→ MOD-014 (i18n) ← 可并行开发，无依赖


模块开发顺序 (Sequential Order)
────────────────────────────────

Phase 1 (Week 1-2):
  [MOD-006] Security & Privacy (10天)
  [MOD-014] i18n (4天) - 并行开发

Phase 2 (Week 3-5):
  [MOD-001] Basic Accounting (13天)
  [MOD-003] Dual Ledger (8天)

Phase 3 (Week 6-9):
  [MOD-004] Family Sync (12天)
  [MOD-007] Analytics & Reports (8天)
  [MOD-008] Settings Management (6天)

Phase 4 (Week 10-12):
  [MOD-005] OCR (7天) - P1
  [MOD-013] Gamification (待定) - P1
```

**关键路径 (Critical Path):**
```
MOD-006 → MOD-001 → MOD-003 → MOD-004 → MVP Release
(10天)    (13天)    (8天)     (12天)     (Week 10)
```

**并行开发机会:**
- Week 1-2: MOD-006 + MOD-014 并行
- Week 6-9: MOD-004, MOD-007, MOD-008 可交错开发

---

## 6. 测试策略

### 6.1 测试覆盖率要求

**最低覆盖率:** ≥80% (所有模块强制要求)

**分层覆盖率目标:**
- 单元测试: ≥85%
- 组件测试: ≥75%
- 集成测试: ≥70%
- E2E测试: 关键流程100%

### 6.2 测试类型

#### 1. 单元测试 (Unit Tests)

**测试工具:** flutter_test + mockito

**测试范围:**
- 所有业务逻辑函数
- 所有工具函数 (utils/)
- 所有Repository层
- 所有UseCase层
- 所有ViewModel/Provider

**示例:**
```dart
// test/domain/use_cases/create_transaction_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CreateTransactionUseCase', () {
    late CreateTransactionUseCase useCase;
    late MockTransactionRepository mockRepo;

    setUp(() {
      mockRepo = MockTransactionRepository();
      useCase = CreateTransactionUseCase(mockRepo);
    });

    test('should create transaction with valid data', () async {
      // Arrange
      final transaction = Transaction(...);
      when(mockRepo.create(any)).thenAnswer((_) async => transaction);

      // Act
      final result = await useCase.execute(CreateTransactionParams(...));

      // Assert
      expect(result, equals(transaction));
      verify(mockRepo.create(any)).called(1);
    });

    test('should throw exception when amount is negative', () async {
      // Arrange
      final params = CreateTransactionParams(amount: -100);

      // Act & Assert
      expect(
        () => useCase.execute(params),
        throwsA(isA<InvalidAmountException>()),
      );
    });
  });
}
```

#### 2. 组件测试 (Widget Tests)

**测试工具:** flutter_test

**测试范围:**
- 所有UI组件 (lib/presentation/widgets/)
- 所有页面 (lib/presentation/pages/)
- 交互逻辑
- 状态变化

**示例:**
```dart
// test/presentation/widgets/transaction_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionCard', () {
    testWidgets('should display transaction details', (tester) async {
      // Arrange
      final transaction = Transaction(
        amount: 1000,
        category: Category(name: '食費', icon: '🍜'),
        timestamp: DateTime(2026, 2, 3),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionCard(transaction: transaction),
          ),
        ),
      );

      // Assert
      expect(find.text('¥1,000'), findsOneWidget);
      expect(find.text('食費'), findsOneWidget);
      expect(find.text('🍜'), findsOneWidget);
    });

    testWidgets('should call onTap callback when tapped', (tester) async {
      // Arrange
      var tapped = false;
      final transaction = Transaction(...);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: transaction,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TransactionCard));

      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

#### 3. 集成测试 (Integration Tests)

**测试工具:** integration_test

**测试范围:**
- 数据库操作完整流程
- 加密/解密流程
- 同步流程
- 备份/恢复流程

**示例:**
```dart
// integration_test/database_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Database Integration Tests', () {
    testWidgets('should persist encrypted transaction', (tester) async {
      // Arrange
      final app = MyApp();
      await tester.pumpWidget(app);

      // Act: Create transaction
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Restart app
      await tester.pumpWidget(Container());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Assert: Transaction still exists
      expect(find.text('¥1,000'), findsOneWidget);
    });
  });
}
```

#### 4. E2E测试 (End-to-End Tests)

**测试工具:** Playwright (via e2e-runner agent)

**关键用户流程:**
1. 新用户注册流程
2. 快速记账流程
3. 设备配对与同步流程
4. OCR扫描流程
5. 月度报表查看流程
6. 备份与恢复流程

**示例流程 (伪代码):**
```typescript
// e2e/quick_transaction_flow.spec.ts
test('Quick Transaction Flow', async ({ page }) => {
  // 1. Launch app
  await page.goto('app://home-pocket');

  // 2. Complete onboarding
  await page.click('text=開始する');
  await page.fill('input[name=pin]', '123456');
  await page.click('text=次へ');

  // 3. Create transaction
  await page.click('[aria-label=Add Transaction]');
  await page.fill('input[name=amount]', '1000');
  await page.click('text=食費');
  await page.click('text=保存');

  // 4. Verify transaction appears
  await expect(page.locator('text=¥1,000')).toBeVisible();
  await expect(page.locator('text=食費')).toBeVisible();
});
```

### 6.3 性能测试

**测试工具:** flutter_driver + 自定义性能分析

**性能指标:**

| 指标 | 目标 | 测试方法 |
|------|------|----------|
| 增量余额更新 | 40-400x vs 全量重算 | 基准测试 (10000+交易) |
| 哈希链增量验证 | 100-2000x vs 全链验证 | 基准测试 (10000+节点) |
| 快速记账 | < 3秒 | E2E流程计时 |
| 列表滚动 | 60 FPS | flutter_driver性能分析 |
| OCR识别 | < 5秒 | 集成测试计时 |
| 数据库查询 | < 100ms (分页) | 单元测试计时 |

**性能测试示例:**
```dart
// test/performance/balance_update_benchmark.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Balance Update Performance', () {
    test('incremental update should be 40-400x faster', () async {
      // Arrange: 10000 transactions
      final transactions = List.generate(10000, (i) => Transaction(...));

      // Act: Full recalculation
      final fullStart = DateTime.now();
      final fullResult = calculateBalanceFull(transactions);
      final fullDuration = DateTime.now().difference(fullStart);

      // Act: Incremental update
      final incStart = DateTime.now();
      final incResult = calculateBalanceIncremental(transactions.last);
      final incDuration = DateTime.now().difference(incStart);

      // Assert
      expect(incResult, equals(fullResult));
      expect(fullDuration.inMilliseconds / incDuration.inMilliseconds,
          greaterThan(40));
    });
  });
}
```

### 6.4 TDD工作流 (强制)

**Red-Green-Refactor循环:**

```
1. 编写测试 (RED)
   ↓
2. 运行测试 - 应该失败
   ↓
3. 编写最小实现 (GREEN)
   ↓
4. 运行测试 - 应该通过
   ↓
5. 重构代码 (IMPROVE)
   ↓
6. 验证覆盖率 (≥80%)
   ↓
   回到步骤1 (下一个功能)
```

**示例工作流:**
```bash
# 1. 编写测试
# test/domain/use_cases/create_transaction_test.dart

# 2. 运行测试 (应该失败)
flutter test test/domain/use_cases/create_transaction_test.dart
# ❌ FAILED

# 3. 编写实现
# lib/domain/use_cases/create_transaction.dart

# 4. 运行测试 (应该通过)
flutter test test/domain/use_cases/create_transaction_test.dart
# ✅ PASSED

# 5. 重构 (如需要)

# 6. 验证覆盖率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
# 确认覆盖率 ≥80%
```

### 6.5 测试数据管理

**Mock数据:**
```dart
// test/fixtures/mock_data.dart
class MockData {
  static final transaction1 = Transaction(
    id: 'tx-001',
    amount: 1000,
    categoryId: 'cat-food',
    timestamp: DateTime(2026, 2, 3),
  );

  static final category1 = Category(
    id: 'cat-food',
    name: '食費',
    icon: '🍜',
  );

  static final book1 = Book(
    id: 'book-001',
    name: 'My Book',
    currentBalance: 10000,
  );
}
```

**数据库Fixture:**
```sql
-- test/fixtures/test_database.sql
INSERT INTO transactions (id, amount, category_id, timestamp)
VALUES
  ('tx-001', 1000, 'cat-food', '2026-02-03 12:00:00'),
  ('tx-002', 2000, 'cat-housing', '2026-02-03 13:00:00'),
  ('tx-003', 500, 'cat-transport', '2026-02-03 14:00:00');
```

### 6.6 持续集成 (CI)

**GitHub Actions配置:**
```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: |
          if [ $(flutter test --coverage | grep -oP '\d+(?=% coverage)') -lt 80 ]; then
            echo "Coverage below 80%!"
            exit 1
          fi
```

---

## 7. 代码质量标准

### 7.1 强制要求

#### ✅ 不可变性 (Immutability)

**禁止mutation，使用不可变模式:**

```dart
// ❌ WRONG: Mutation
class Transaction {
  double amount;

  void updateAmount(double newAmount) {
    amount = newAmount;  // MUTATION!
  }
}

// ✅ CORRECT: Immutability
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required double amount,
  }) = _Transaction;

  Transaction updateAmount(double newAmount) {
    return copyWith(amount: newAmount);
  }
}
```

#### ✅ 小文件优先

**文件大小限制:**
- 典型: 200-400行
- 最大: 800行
- 超过800行: 必须拆分

**拆分策略:**
```
// 大文件 (1000+ lines)
lib/presentation/pages/transaction_page.dart

// 拆分后:
lib/presentation/pages/transaction_page/
├── transaction_page.dart (100 lines)
├── widgets/
│   ├── transaction_form.dart (150 lines)
│   ├── transaction_list.dart (120 lines)
│   └── transaction_filters.dart (80 lines)
└── providers/
    └── transaction_page_provider.dart (100 lines)
```

#### ✅ 错误处理

**所有异步操作必须有try-catch:**

```dart
// ❌ WRONG: No error handling
Future<Transaction> createTransaction(TransactionParams params) async {
  return await repository.create(params);
}

// ✅ CORRECT: Proper error handling
Future<Either<Failure, Transaction>> createTransaction(
  TransactionParams params,
) async {
  try {
    final transaction = await repository.create(params);
    return Right(transaction);
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on DatabaseException catch (e) {
    return Left(DatabaseFailure(e.message));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}
```

#### ✅ 输入验证

**所有用户输入必须验证:**

```dart
// ❌ WRONG: No validation
void createTransaction(double amount, String note) {
  repository.create(Transaction(amount: amount, note: note));
}

// ✅ CORRECT: Input validation
@freezed
class CreateTransactionParams with _$CreateTransactionParams {
  const factory CreateTransactionParams({
    required double amount,
    String? note,
  }) = _CreateTransactionParams;

  factory CreateTransactionParams.fromJson(Map<String, dynamic> json) =>
      _$CreateTransactionParamsFromJson(json);
}

// Validation
Either<Failure, CreateTransactionParams> validateParams(
  Map<String, dynamic> input,
) {
  if (input['amount'] == null) {
    return Left(ValidationFailure('Amount is required'));
  }

  final amount = double.tryParse(input['amount'].toString());
  if (amount == null || amount <= 0) {
    return Left(ValidationFailure('Amount must be positive'));
  }

  if (input['note'] != null && input['note'].length > 500) {
    return Left(ValidationFailure('Note too long (max 500 chars)'));
  }

  return Right(CreateTransactionParams(
    amount: amount,
    note: input['note'],
  ));
}
```

#### ✅ 无调试代码

**生产代码禁止console.log/print:**

```dart
// ❌ WRONG: Debug code in production
void createTransaction() {
  print('Creating transaction...');  // ❌
  debugPrint('Amount: $amount');     // ❌
}

// ✅ CORRECT: Use logger
import 'package:logger/logger.dart';

final logger = Logger();

void createTransaction() {
  logger.d('Creating transaction');  // Debug级别，仅开发环境
}
```

#### ✅ 安全检查

**提交前必须通过security-reviewer检查:**

```bash
# 运行安全审查
claude skill security-reviewer

# 检查项:
# - 无硬编码密钥、密码、令牌
# - 所有用户输入已验证
# - 防止SQL注入 (使用参数化查询)
# - 防止XSS (清理HTML)
# - API端点限流
```

### 7.2 代码审查检查清单

**提交前自检 (Self-Review Checklist):**

- [ ] **可读性**
  - [ ] 函数名清晰描述功能
  - [ ] 变量名有意义
  - [ ] 代码逻辑清晰
  - [ ] 无魔法数字 (使用常量)

- [ ] **函数大小**
  - [ ] 函数 < 50行
  - [ ] 单一职责原则
  - [ ] 参数 ≤ 4个

- [ ] **文件大小**
  - [ ] 文件 < 800行
  - [ ] 高内聚低耦合

- [ ] **嵌套深度**
  - [ ] 嵌套 ≤ 4层
  - [ ] 提前返回 (early return)
  - [ ] 提取复杂条件为函数

- [ ] **错误处理**
  - [ ] 所有async函数有try-catch
  - [ ] 错误消息清晰
  - [ ] 用户友好的错误提示

- [ ] **无调试代码**
  - [ ] 无console.log/print
  - [ ] 无注释掉的代码
  - [ ] 无TODO标记

- [ ] **无硬编码值**
  - [ ] 使用常量或配置
  - [ ] 无魔法数字
  - [ ] 无硬编码URL/路径

- [ ] **不可变性**
  - [ ] 使用freezed数据类
  - [ ] 禁止mutation
  - [ ] copyWith模式

**PR审查检查清单 (Pull Request Review):**

- [ ] **测试覆盖率**
  - [ ] 覆盖率 ≥ 80%
  - [ ] 关键路径100%覆盖

- [ ] **安全审查**
  - [ ] 通过security-reviewer检查
  - [ ] 无安全漏洞

- [ ] **性能**
  - [ ] 无明显性能问题
  - [ ] 大数据量测试通过

- [ ] **文档**
  - [ ] API文档完整
  - [ ] 复杂逻辑有注释

- [ ] **CI/CD**
  - [ ] 所有测试通过
  - [ ] 代码格式化正确
  - [ ] 静态分析无错误

### 7.3 代码格式化

**Dart格式化规则:**

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_require_non_null_named_parameters
    - annotate_overrides
    - avoid_empty_else
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_relative_lib_imports
    - avoid_return_types_on_setters
    - avoid_shadowing_type_parameters
    - avoid_types_as_parameter_names
    - camel_case_extensions
    - curly_braces_in_flow_control_structures
    - empty_catches
    - empty_constructor_bodies
    - library_names
    - library_prefixes
    - no_duplicate_case_values
    - null_closures
    - omit_local_variable_types
    - prefer_adjacent_string_concatenation
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_contains
    - prefer_equal_for_default_values
    - prefer_final_fields
    - prefer_for_elements_to_map_fromIterable
    - prefer_generic_function_type_aliases
    - prefer_if_null_operators
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_iterable_whereType
    - prefer_single_quotes
    - prefer_spread_collections
    - recursive_getters
    - slash_for_doc_comments
    - type_init_formals
    - unawaited_futures
    - unnecessary_const
    - unnecessary_new
    - unnecessary_null_in_if_null_operators
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_function_type_syntax_for_parameters
    - use_rethrow_when_possible
    - valid_regexps
```

**自动格式化:**
```bash
# 格式化所有Dart文件
dart format .

# 检查格式 (CI中使用)
dart format --set-exit-if-changed .
```

---

## 8. 风险评估与缓解

### 8.1 技术风险

| 风险 ID | 风险描述 | 影响 | 概率 | 缓解措施 | 负责模块 |
|---------|----------|------|------|----------|----------|
| **TR-001** | CRDT同步冲突复杂，边界情况难以处理 | 高 | 中 | - 使用成熟的Yjs库<br>- 充分测试边界情况<br>- 实施向量时钟<br>- 离线队列重试机制 | MOD-004 |
| **TR-002** | 多层加密性能开销影响用户体验 | 中 | 中 | - 实施增量更新<br>- 密钥缓存优化<br>- 批量加密/解密<br>- 性能基准测试 | MOD-006 |
| **TR-003** | OCR准确率不达标 (金额<90%, 日期<85%) | 中 | 低 | - 使用预训练模型 (ML Kit/Vision)<br>- 图像预处理优化<br>- 允许手动修正<br>- 持续训练改进 | MOD-005 |
| **TR-004** | 哈希链验证性能影响启动速度 | 高 | 低 | - 实施增量验证 (ADR-009)<br>- 100-2000x性能提升<br>- 后台异步验证<br>- 定期验证而非每次启动 | MOD-006 |
| **TR-005** | 生物识别兼容性问题 (不同设备) | 低 | 中 | - 提供PIN码备选方案<br>- 设备能力检测<br>- 优雅降级 | MOD-006 |
| **TR-006** | SQLCipher性能开销 | 中 | 低 | - 256,000次PBKDF2迭代优化<br>- 4KB页大小优化<br>- 复合索引优化<br>- 分页查询 | MOD-006 |
| **TR-007** | Flutter版本升级导致破坏性变更 | 中 | 中 | - 锁定Flutter版本 (3.16+)<br>- 测试兼容性<br>- 渐进式升级 | 全模块 |
| **TR-008** | BLE/NFC连接不稳定 | 中 | 中 | - 多协议支持 (BLE/NFC/WiFi Direct)<br>- 自动重连机制<br>- 离线队列 | MOD-004 |

### 8.2 业务风险

| 风险 ID | 风险描述 | 影响 | 概率 | 缓解措施 | 负责模块 |
|---------|----------|------|------|----------|----------|
| **BR-001** | 双轨分类准确率低，用户频繁手动纠错 | 高 | 中 | - 3层分类引擎 (规则+商户库+ML)<br>- 500+商户数据库<br>- 用户纠错反馈学习<br>- 85%+准确率目标 | MOD-003 |
| **BR-002** | 用户学习曲线陡峭，弃用率高 | 中 | 中 | - 新手引导流程<br>- 交互式教程<br>- 上下文帮助<br>- 简化UI | MOD-001, MOD-014 |
| **BR-003** | 家庭成员同步配置复杂 | 中 | 低 | - QR码简化配对<br>- 一键同步<br>- 可视化同步状态 | MOD-004 |
| **BR-004** | 隐私担忧导致用户不信任 | 高 | 低 | - 零知识架构透明化<br>- 开源加密代码<br>- 安全审计报告<br>- 隐私政策明确 | MOD-006 |
| **BR-005** | 备份恢复失败导致数据丢失 | 高 | 低 | - 加密备份验证<br>- 恢复测试<br>- 24词助记词备选<br>- 自动备份提醒 | MOD-008 |
| **BR-006** | 商户数据库不适用于非日本用户 | 中 | 中 | - 多地区商户库计划<br>- 用户自定义商户<br>- 国际化分类体系 | MOD-003 |

### 8.3 项目风险

| 风险 ID | 风险描述 | 影响 | 概率 | 缓解措施 |
|---------|----------|------|------|----------|
| **PR-001** | 开发进度延迟，无法按时发布MVP | 高 | 中 | - 优先级管理 (P0 > P1)<br>- 敏捷迭代<br>- 缓冲时间 (10周 → 12周)<br>- 里程碑跟踪 |
| **PR-002** | 关键开发人员离开 | 高 | 低 | - 代码文档完善<br>- 知识共享<br>- Clean Architecture易维护 |
| **PR-003** | 第三方依赖弃用或破坏性变更 | 中 | 中 | - 依赖版本锁定<br>- 定期更新评估<br>- 备选方案准备 |
| **PR-004** | App Store/Play Store审核被拒 | 中 | 低 | - 遵循平台政策<br>- 隐私政策完善<br>- 提前审核准备 |

### 8.4 风险监控与应对

**风险监控频率:**
- 高影响风险: 每周评估
- 中影响风险: 每两周评估
- 低影响风险: 每月评估

**风险应对流程:**
1. **识别:** 定期风险评估会议
2. **分析:** 影响与概率评分
3. **规划:** 缓解措施制定
4. **执行:** 缓解措施实施
5. **监控:** 风险状态跟踪
6. **复盘:** 风险关闭后总结

---

## 9. 性能优化目标

### 9.1 数据库性能

基于ADR-008和ADR-009的架构决策：

| 性能指标 | 目标 | 基线 | 提升倍数 | 验证方法 |
|----------|------|------|----------|----------|
| **增量余额更新** | < 10ms (10000+交易) | 400ms - 4000ms (全量重算) | 40-400x | 性能基准测试 |
| **哈希链增量验证** | < 10ms (10000+节点) | 1000ms - 20000ms (全链验证) | 100-2000x | 性能基准测试 |
| **分页查询** | < 50ms (50-100项/页) | N/A | N/A | 单元测试计时 |
| **复合索引查询** | < 100ms | > 500ms (无索引) | 5x | SQL EXPLAIN分析 |
| **批量插入** | < 500ms (100项) | N/A | N/A | 集成测试计时 |

**优化技术:**

1. **增量余额更新 (ADR-008):**
   ```dart
   // ❌ 旧方案: 全量重算
   double calculateBalance(List<Transaction> transactions) {
     return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
   }

   // ✅ 新方案: 增量更新
   double updateBalanceIncremental(
     double currentBalance,
     Transaction newTransaction,
   ) {
     return currentBalance + newTransaction.amount;
   }
   ```

2. **哈希链增量验证 (ADR-009):**
   ```dart
   // ❌ 旧方案: 全链验证
   bool verifyFullChain(List<HashChainNode> nodes) {
     for (int i = 1; i < nodes.length; i++) {
       if (nodes[i].previousHash != nodes[i-1].currentHash) {
         return false;
       }
     }
     return true;
   }

   // ✅ 新方案: 增量验证
   bool verifyIncrementalNode(
     HashChainNode previousNode,
     HashChainNode newNode,
   ) {
     return newNode.previousHash == previousNode.currentHash;
   }
   ```

3. **复合索引优化:**
   ```sql
   -- 创建复合索引
   CREATE INDEX idx_transaction_book_timestamp
   ON transactions(book_id, timestamp DESC);

   -- 优化查询
   SELECT * FROM transactions
   WHERE book_id = ?
   ORDER BY timestamp DESC
   LIMIT 50 OFFSET ?;
   ```

4. **分页加载:**
   ```dart
   // 虚拟滚动 + 分页加载
   class TransactionListProvider extends StateNotifier<AsyncValue<List<Transaction>>> {
     int _currentPage = 0;
     static const _pageSize = 50;

     Future<void> loadNextPage() async {
       final transactions = await repository.getTransactions(
         limit: _pageSize,
         offset: _currentPage * _pageSize,
       );
       _currentPage++;
       state = AsyncValue.data([...state.value!, ...transactions]);
     }
   }
   ```

### 9.2 加密性能

| 性能指标 | 目标 | 验证方法 |
|----------|------|----------|
| **密钥派生 (HKDF)** | < 50ms | 单元测试计时 |
| **字段加密 (ChaCha20-Poly1305)** | < 10ms/字段 | 单元测试计时 |
| **批量加密** | < 500ms (100项) | 集成测试计时 |
| **数据库解密 (SQLCipher)** | < 100ms (打开数据库) | 集成测试计时 |

**优化技术:**

1. **密钥缓存:**
   ```dart
   class KeyManager {
     // 缓存派生密钥，避免重复计算
     final Map<String, Uint8List> _keyCache = {};

     Future<Uint8List> getDerivedKey(String purpose) async {
       if (_keyCache.containsKey(purpose)) {
         return _keyCache[purpose]!;
       }

       final key = await _deriveKey(purpose);
       _keyCache[purpose] = key;
       return key;
     }
   }
   ```

2. **批量加密优化:**
   ```dart
   Future<List<Transaction>> encryptBatch(List<Transaction> transactions) async {
     final key = await keyManager.getDerivedKey('field_encryption');

     return transactions.map((tx) => tx.copyWith(
       encryptedAmount: _encryptField(tx.amount, key),
       encryptedNote: tx.note != null ? _encryptField(tx.note!, key) : null,
     )).toList();
   }
   ```

### 9.3 UI性能

| 性能指标 | 目标 | 验证方法 |
|----------|------|----------|
| **快速记账流程** | < 3秒 | E2E测试计时 |
| **列表滚动** | 60 FPS | flutter_driver性能分析 |
| **动画流畅度** | 60 FPS | flutter_driver性能分析 |
| **页面切换** | < 300ms | flutter_driver性能分析 |

**优化技术:**

1. **列表虚拟滚动:**
   ```dart
   ListView.builder(
     itemCount: transactions.length,
     itemBuilder: (context, index) {
       // 仅渲染可见项
       return TransactionCard(transaction: transactions[index]);
     },
   );
   ```

2. **图像缓存:**
   ```dart
   CachedNetworkImage(
     imageUrl: transaction.receiptUrl,
     memCacheWidth: 200,
     memCacheHeight: 200,
   );
   ```

3. **Lottie动画硬件加速:**
   ```dart
   Lottie.asset(
     'assets/animations/celebration.json',
     repeat: false,
     enableMergePaths: true,  // 硬件加速
   );
   ```

### 9.4 性能监控

**开发阶段:**
```bash
# 性能分析
flutter run --profile
# 打开DevTools Performance tab

# 内存分析
flutter run --profile
# 打开DevTools Memory tab

# 帧率监控
flutter run --profile
# 检查Rasterize/UI线程时间
```

**生产阶段:**
```dart
// 自定义性能监控
class PerformanceMonitor {
  static void trackOperation(String name, Future<void> Function() operation) async {
    final start = DateTime.now();
    await operation();
    final duration = DateTime.now().difference(start);

    if (duration.inMilliseconds > 1000) {
      logger.w('Slow operation: $name took ${duration.inMilliseconds}ms');
    }
  }
}
```

---

## 10. 安全合规

### 10.1 加密标准

| 加密算法 | 用途 | 密钥长度 | 标准 |
|----------|------|----------|------|
| **Ed25519** | 设备密钥对、数字签名 | 256-bit | RFC 8032 |
| **ChaCha20-Poly1305** | 敏感字段加密 (AEAD) | 256-bit | RFC 8439 |
| **AES-256-GCM** | 文件加密 (照片、备份) | 256-bit | NIST SP 800-38D |
| **AES-256-CBC** | SQLCipher数据库加密 | 256-bit | NIST FIPS 197 |
| **SHA-256** | 哈希链完整性验证 | 256-bit | NIST FIPS 180-4 |
| **HKDF-SHA256** | 密钥派生 | 256-bit | RFC 5869 |
| **PBKDF2** | 数据库密钥派生 | 256-bit | RFC 2898 |

**加密参数:**
- **SQLCipher迭代次数:** 256,000 (PBKDF2)
- **数据库页大小:** 4KB
- **HKDF盐长度:** 32 bytes
- **ChaCha20 Nonce:** 12 bytes (随机生成)
- **AES-GCM IV:** 12 bytes (随机生成)

### 10.2 隐私保护措施

#### 1. 零知识架构

**原则:**
- 无服务器依赖
- 数据仅存本地
- 用户完全控制数据
- 无第三方数据共享

**实施:**
```dart
// ✅ 本地存储
final database = await openDatabase('home_pocket.db');

// ❌ 禁止云同步到中心服务器
// await uploadToServer(data);  // FORBIDDEN!

// ✅ P2P设备同步
await syncToDevice(pairedDevice, encryptedData);
```

#### 2. 端到端加密

**同步数据流:**
```
设备A                    设备B
  ↓                        ↓
数据 → Ed25519加密 → BLE传输 → Ed25519解密 → 数据
  ↓                        ↓
本地存储                 本地存储
```

**加密保证:**
- 传输层加密 (Ed25519 + ChaCha20-Poly1305)
- 存储层加密 (SQLCipher AES-256-CBC)
- 无中间人可解密

#### 3. 无遥测数据收集

**禁止收集:**
- ❌ 用户行为追踪
- ❌ 崩溃报告自动上传
- ❌ 分析数据
- ❌ 广告ID

**允许收集 (用户明确同意后):**
- ✅ 匿名错误日志 (仅用于调试)
- ✅ 性能指标 (不包含用户数据)

#### 4. 生物识别保护

**可选启用:**
```dart
// 用户可选择是否启用生物识别
final biometricEnabled = await appSettings.getBiometricEnabled();

if (biometricEnabled) {
  final authenticated = await localAuth.authenticate(
    localizedReason: 'Unlock Home Pocket',
  );

  if (authenticated) {
    // 解锁应用
  }
}
```

**备选方案:**
- PIN码 (4-6位数字)
- 图案锁

### 10.3 恢复机制

#### 24词BIP39助记词

**生成:**
```dart
import 'package:bip39/bip39.dart' as bip39;

String generateMnemonic() {
  return bip39.generateMnemonic(strength: 256);  // 24 words
}

// 示例输出:
// "abandon ability able about above absent absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act action actor actress actual adapt"
```

**恢复:**
```dart
Future<bool> recoverFromMnemonic(String mnemonic) async {
  if (!bip39.validateMnemonic(mnemonic)) {
    return false;
  }

  final seed = bip39.mnemonicToSeed(mnemonic);
  final privateKey = derivePrivateKeyFromSeed(seed);
  final publicKey = derivePublicKey(privateKey);

  await keyManager.storeKeys(publicKey, privateKey);
  return true;
}
```

**存储建议:**
- 纸质备份 (推荐)
- 密码管理器
- 金属备份卡

### 10.4 安全审查流程

#### 提交前检查清单

**强制检查项:**

- [ ] **密钥管理**
  - [ ] 无硬编码密钥
  - [ ] 无硬编码密码
  - [ ] 无硬编码API令牌
  - [ ] 敏感配置使用环境变量

- [ ] **输入验证**
  - [ ] 所有用户输入已验证
  - [ ] 使用参数化查询 (防SQL注入)
  - [ ] HTML输出已清理 (防XSS)
  - [ ] 文件上传类型白名单

- [ ] **认证授权**
  - [ ] 生物识别/PIN码保护
  - [ ] 会话超时机制
  - [ ] 敏感操作二次确认

- [ ] **数据保护**
  - [ ] 敏感字段已加密
  - [ ] 数据库已加密 (SQLCipher)
  - [ ] 备份文件已加密
  - [ ] 照片已加密存储

- [ ] **错误处理**
  - [ ] 错误消息不泄露敏感信息
  - [ ] 异常栈不暴露内部逻辑
  - [ ] 日志不包含敏感数据

- [ ] **API安全**
  - [ ] (如有) API端点限流
  - [ ] (如有) HTTPS强制
  - [ ] (如有) CSRF保护

#### Security-Reviewer Agent

**使用方法:**
```bash
# 运行安全审查 agent
claude skill security-reviewer

# 或在CLI中
/security-review
```

**检查范围:**
- OWASP Top 10漏洞
- 密钥泄露检测
- 敏感数据暴露
- 注入攻击风险
- 不安全加密使用

**示例输出:**
```
🔒 Security Review Report
═══════════════════════════════════════

✅ PASS: No hardcoded secrets found
✅ PASS: All user inputs validated
✅ PASS: SQL injection prevention verified
✅ PASS: XSS prevention verified
⚠️  WARN: Consider adding rate limiting to QR code generation
❌ FAIL: Error message in auth.dart:123 leaks user email

Critical Issues: 1
High Issues: 0
Medium Issues: 1
Low Issues: 0

Please fix CRITICAL and HIGH issues before committing.
```

### 10.5 安全最佳实践

#### 1. 最小权限原则

```dart
// ✅ CORRECT: 仅请求必要权限
if (await Permission.camera.request().isGranted) {
  // 使用相机
}

// ❌ WRONG: 请求不必要权限
await Permission.contacts.request();  // 不需要联系人权限
```

#### 2. 安全存储

```dart
// ✅ CORRECT: 使用flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'pin', value: encryptedPin);

// ❌ WRONG: 使用SharedPreferences存储敏感数据
final prefs = await SharedPreferences.getInstance();
await prefs.setString('pin', pin);  // 不安全!
```

#### 3. 证书固定 (如有API)

```dart
// 如果未来需要API调用
import 'package:dio/dio.dart';

final dio = Dio();
dio.options.headers['X-API-Key'] = await secureStorage.read(key: 'api_key');

// 证书固定
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  client.badCertificateCallback = (cert, host, port) {
    return cert.sha256.toString() == expectedCertificateHash;
  };
  return client;
};
```

---

## 11. 部署策略

### 11.1 iOS部署

**目标平台:**
- 最低版本: iOS 14+
- 目标设备: iPhone, iPad
- 架构: arm64

**构建配置:**
```yaml
# ios/Runner/Info.plist
<key>NSCameraUsageDescription</key>
<string>カメラでレシートを撮影します</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>写真からレシートを選択します</string>
<key>NSFaceIDUsageDescription</key>
<string>Face IDでアプリを保護します</string>
<key>MinimumOSVersion</key>
<string>14.0</string>
```

**签名配置:**
```bash
# 自动签名
flutter build ios --release

# 手动签名
flutter build ios --release --no-codesign
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

**TestFlight部署:**
```bash
# 1. 构建 .ipa
flutter build ipa --release

# 2. 上传到App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/home_pocket.ipa \
  --username "your-apple-id@example.com" \
  --password "app-specific-password"

# 3. TestFlight内测邀请
# 在App Store Connect中添加内测用户
```

**App Store发布:**
1. App Store Connect配置
2. 隐私政策URL
3. 应用截图 (6.5", 5.5")
4. 应用描述 (日文、中文、英文)
5. 关键词优化
6. 提交审核

**审核注意事项:**
- 隐私政策必须明确
- 数据收集说明
- 加密导出合规性报告
- 无广告标识符

### 11.2 Android部署

**目标平台:**
- 最低版本: Android 7 (API 24)
- 目标版本: Android 14 (API 34)
- 架构: arm64-v8a, armeabi-v7a, x86_64

**构建配置:**
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"

        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}
```

**权限配置:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.NFC" />

    <application
        android:label="Home Pocket"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false">
        ...
    </application>
</manifest>
```

**签名配置:**
```bash
# 生成密钥库
keytool -genkey -v \
  -keystore ~/home-pocket-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias home-pocket

# 配置签名
# android/key.properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=home-pocket
storeFile=/path/to/home-pocket-release.jks
```

**构建APK:**
```bash
# 构建 Release APK
flutter build apk --release

# 构建 Split APKs (按架构分割)
flutter build apk --release --split-per-abi

# 构建 App Bundle (推荐)
flutter build appbundle --release
```

**Play Store内测:**
```bash
# 1. 上传到Google Play Console
# 2. 创建内测轨道 (Internal Testing)
# 3. 添加测试用户
# 4. 发布内测版本
```

**Play Store发布:**
1. Google Play Console配置
2. 应用详情 (日文、中文、英文)
3. 应用截图 (手机、平板)
4. 特色图片
5. 隐私政策URL
6. 数据安全表单
7. 内容分级
8. 提交审核

**审核注意事项:**
- 数据安全表单必填
- 隐私政策必须可访问
- 敏感权限使用说明
- 无追踪器声明

### 11.3 版本策略

**语义化版本 (Semantic Versioning):**
```
MAJOR.MINOR.PATCH

示例:
1.0.0 - MVP正式版
1.1.0 - 增强功能 (OCR)
1.1.1 - Bug修复
2.0.0 - 破坏性变更
```

**版本计划:**

| 版本 | 阶段 | 功能 | 发布时间 |
|------|------|------|----------|
| v0.1.0 - v0.9.0 | 内部开发 | 迭代开发 | Week 1-9 |
| v1.0.0-beta.1 | 内测 | MVP功能完整 | Week 10 |
| v1.0.0-beta.2 | 内测 | Bug修复 | Week 11 |
| **v1.0.0** | **正式发布** | **MVP** | **Week 12** |
| v1.1.0 | 增强版 | OCR扫描 | Week 14 |
| v1.2.0 | 增强版 | 游戏化 | Week 16 |
| v2.0.0 | 未来规划 | 云备份(可选) | TBD |

**版本号管理:**
```yaml
# pubspec.yaml
name: home_pocket
version: 1.0.0+1
# version: <MAJOR.MINOR.PATCH>+<BUILD_NUMBER>

# iOS: CFBundleShortVersionString = 1.0.0
#      CFBundleVersion = 1

# Android: versionName = 1.0.0
#          versionCode = 1
```

**变更日志 (CHANGELOG.md):**
```markdown
# Changelog

## [1.0.0] - 2026-03-XX

### Added
- 双轨账本系统 (生存账本 vs 灵魂账本)
- 多层加密安全防护
- 家庭P2P设备同步
- 数据分析与月度报表
- 3语言支持 (日文、中文、英文)

### Security
- Ed25519设备密钥对
- ChaCha20-Poly1305字段加密
- SQLCipher数据库加密
- 生物识别锁

## [1.1.0] - 2026-04-XX

### Added
- OCR智能扫描小票
- 商户自动识别与分类

### Improved
- 分类准确率提升至90%
```

### 11.4 CI/CD管道

**GitHub Actions配置:**

```yaml
# .github/workflows/build.yml
name: Build & Deploy

on:
  push:
    branches: [main, develop]
    tags:
      - 'v*'
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .
      - run: flutter test --coverage
      - name: Check coverage
        run: |
          COVERAGE=$(flutter test --coverage | grep -oP '\d+(?=% coverage)')
          if [ $COVERAGE -lt 80 ]; then
            echo "Coverage $COVERAGE% below 80%!"
            exit 1
          fi
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build-ios:
    needs: test
    runs-on: macos-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/Runner.app

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-build
          path: build/app/outputs/bundle/release/app-release.aab
```

**自动化发布:**
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: |
            Release notes for ${{ github.ref }}
            See CHANGELOG.md for details.
          draft: false
          prerelease: false
```

---

## 12. 文档交付物

### 12.1 技术文档

#### 1. API文档

**自动生成 (Dart Doc):**
```bash
# 生成API文档
dart doc .

# 输出到 doc/api/
# 包含所有公共API的文档
```

**文档注释规范:**
```dart
/// Creates a new transaction.
///
/// This function validates the input parameters, encrypts sensitive fields,
/// updates the hash chain, and persists the transaction to the database.
///
/// **Parameters:**
/// - [params]: The transaction creation parameters
///
/// **Returns:**
/// - `Right<Transaction>` if successful
/// - `Left<Failure>` if validation or creation fails
///
/// **Throws:**
/// - Never throws - all errors are returned as `Left<Failure>`
///
/// **Example:**
/// ```dart
/// final result = await createTransaction(
///   CreateTransactionParams(
///     amount: 1000,
///     categoryId: 'cat-food',
///   ),
/// );
///
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (transaction) => print('Created: ${transaction.id}'),
/// );
/// ```
Future<Either<Failure, Transaction>> createTransaction(
  CreateTransactionParams params,
) async {
  // ...
}
```

#### 2. 架构文档

**持续更新 arch2/ 目录:**
- arch2/01-core-architecture/ - 整体架构
- arch2/02-module-specs/ - 模块规范
- arch2/03-adr/ - 架构决策记录

**文档版本控制:**
```bash
# 更新架构文档
git add arch2/
git commit -m "docs(arch2): update ARCH-002 data architecture"
```

#### 3. ADR文档

**记录重大技术决策:**

示例: arch2/03-adr/ADR-010_Database_Migration_Strategy.md
```markdown
# ADR-010: 数据库迁移策略

**状态:** 已批准
**日期:** 2026-02-15

## 背景

需要制定数据库架构变更的迁移策略，确保用户数据安全和应用兼容性。

## 考虑的方案

### 方案1: Drift自动迁移
- 优点: 简单，自动化
- 缺点: 复杂变更难以处理

### 方案2: 手动迁移脚本
- 优点: 完全控制，灵活
- 缺点: 维护成本高

### 方案3: Drift迁移 + 手动回退脚本
- 优点: 自动化 + 安全回退
- 缺点: 需要维护回退脚本

## 决策

选择方案3: Drift自动迁移 + 手动回退脚本

## 决策理由

- Drift提供类型安全的迁移
- 手动回退脚本确保数据安全
- 测试覆盖迁移路径

## 后果

- 每次架构变更需编写迁移脚本
- 需要测试升级和回退路径
- 用户数据安全得到保障

## 实施计划

1. 使用Drift的`@UseMoor`迁移
2. 编写手动回退脚本
3. 单元测试迁移逻辑
4. 集成测试完整升级路径
```

### 12.2 用户文档

#### 1. 应用内帮助

**多语言帮助文档:**
```
lib/l10n/help/
├── help_en.md
├── help_ja.md
└── help_zh.md
```

**内容结构:**
```markdown
# Home Pocket ヘルプ

## 目次

1. [はじめに](#getting-started)
2. [基本的な記録](#quick-transaction)
3. [二重帳簿システム](#dual-ledger)
4. [家族同期](#family-sync)
5. [OCRスキャン](#ocr-scan)
6. [セキュリティ](#security)
7. [バックアップと復元](#backup-restore)
8. [よくある質問](#faq)

## はじめに

Home Pocketへようこそ！...

## 基本的な記録

取引を記録するには...
```

#### 2. README.md

**项目主README:**
```markdown
# Home Pocket

> 本地优先、隐私保护的家庭记账应用

## 特性

- 🔐 **多层加密**: 4层安全防护
- 📊 **双轨账本**: 生存账本 vs 灵魂账本
- 🔄 **P2P同步**: 无需服务器的家庭同步
- 📸 **OCR扫描**: 智能小票识别
- 🌐 **多语言**: 日文、中文、英文

## 快速开始

```bash
# 克隆项目
git clone https://github.com/your-org/home-pocket.git

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 文档

- [架构文档](arch2/01-core-architecture/)
- [模块规范](arch2/02-module-specs/)
- [ADR文档](arch2/03-adr/)
- [开发日志](worklog/)

## 技术栈

- Flutter 3.16+
- Riverpod (状态管理)
- Drift + SQLCipher (数据库)
- Yjs (CRDT同步)

## 许可证

MIT License
```

### 12.3 开发日志

**worklog/ 目录结构:**
```
worklog/
├── PROJECT_DEVELOPMENT_PLAN.md (本文档)
├── 20260203.md
├── 20260204.md
├── ...
└── WEEKLY_SUMMARY.md
```

**每日日志格式:**
```markdown
# 2026-02-03 开发日志

## 完成的工作

- [MOD-006] 实现Ed25519密钥对生成
- [MOD-006] 集成BIP39助记词库
- [MOD-014] 配置ARB文件（日文、中文、英文）

## 遇到的问题

- 生物识别在Android模拟器上无法测试
  - 解决方案: 使用真机测试

## 明天计划

- [MOD-006] 实现ChaCha20-Poly1305字段加密
- [MOD-006] 集成SQLCipher数据库加密
- [MOD-006] 编写加密相关单元测试

## 测试覆盖率

- security_key_test.dart: 85%
- mnemonic_test.dart: 90%
```

### 12.4 测试报告

**自动生成覆盖率报告:**
```bash
# 生成HTML覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 查看报告
open coverage/html/index.html
```

**测试报告模板:**
```markdown
# 测试报告 - MOD-006 安全与隐私

**日期:** 2026-02-10
**模块:** MOD-006
**测试人员:** [Your Name]

## 测试摘要

| 指标 | 结果 |
|------|------|
| 单元测试覆盖率 | 87% |
| Widget测试覆盖率 | 78% |
| 集成测试覆盖率 | 72% |
| 总覆盖率 | 82% ✅ |
| 测试通过率 | 100% |

## 测试用例

### 密钥管理 (10个测试)
- ✅ 密钥对生成测试
- ✅ 助记词生成测试
- ✅ 助记词验证测试
- ✅ 密钥恢复测试
- ✅ 密钥派生测试
- ...

### 加密功能 (8个测试)
- ✅ ChaCha20-Poly1305加密测试
- ✅ ChaCha20-Poly1305解密测试
- ✅ SQLCipher集成测试
- ...

## 性能测试

| 测试项 | 目标 | 实际 | 结果 |
|--------|------|------|------|
| 密钥派生 (HKDF) | < 50ms | 32ms | ✅ |
| 字段加密 | < 10ms/字段 | 6ms | ✅ |
| 批量加密 (100项) | < 500ms | 420ms | ✅ |

## 发现的问题

1. **Issue #001:** 助记词包含非ASCII字符时验证失败
   - 优先级: Medium
   - 状态: 已修复

## 总结

MOD-006模块测试覆盖率达标 (82% > 80%)，所有测试用例通过，性能指标满足要求。
```

### 12.5 性能报告

**性能基准测试报告:**
```markdown
# 性能报告 - 增量余额更新

**日期:** 2026-02-15
**测试环境:** iPhone 13 Pro (iOS 16)

## 测试场景

测试增量余额更新 vs 全量重算的性能对比。

## 测试数据

| 交易数量 | 全量重算 | 增量更新 | 性能提升 |
|----------|----------|----------|----------|
| 100 | 8ms | 0.2ms | 40x |
| 1,000 | 82ms | 0.3ms | 273x |
| 10,000 | 840ms | 0.4ms | 2,100x |
| 100,000 | 8,500ms | 0.5ms | 17,000x |

## 结论

增量余额更新在10,000+交易场景下实现2,100x性能提升，远超40-400x目标。

## 建议

- 保持增量更新策略
- 监控大数据量场景
```

---

## 13. 团队协作

### 13.1 Git工作流

**分支策略:**

```
main (生产分支)
  ↑
develop (开发分支)
  ↑
feature/MOD-XXX-description (功能分支)
```

**分支命名规范:**
```bash
# 功能分支
feature/MOD-006-security-encryption
feature/MOD-001-basic-accounting

# 修复分支
fix/transaction-validation-bug

# 热修复分支 (生产紧急修复)
hotfix/v1.0.1-critical-crash
```

**提交信息格式 (Conventional Commits):**

```
<type>: <description>

[optional body]

[optional footer]
```

**类型 (type):**
- `feat`: 新功能
- `fix`: Bug修复
- `refactor`: 重构
- `docs`: 文档更新
- `test`: 测试相关
- `chore`: 构建/工具配置
- `perf`: 性能优化
- `ci`: CI/CD配置

**示例:**
```bash
# 新功能
git commit -m "feat(MOD-006): implement Ed25519 key pair generation

- Add EdDSA key generation
- Integrate BIP39 mnemonic
- Add unit tests for key manager"

# Bug修复
git commit -m "fix(MOD-001): validate negative transaction amounts

Previously negative amounts were allowed, causing balance calculation errors.
Added validation to reject amounts <= 0."

# 文档更新
git commit -m "docs(arch2): update ADR-008 incremental balance strategy"
```

**提交频率:**
- 小提交，频繁提交
- 每个提交应该是原子性的
- 一个提交解决一个问题

### 13.2 Pull Request流程

**PR创建:**

```bash
# 1. 创建功能分支
git checkout -b feature/MOD-006-field-encryption

# 2. 开发 + 提交
git add .
git commit -m "feat(MOD-006): implement ChaCha20-Poly1305 field encryption"

# 3. 推送到远程
git push -u origin feature/MOD-006-field-encryption

# 4. 创建PR
gh pr create --title "feat(MOD-006): Field Encryption" --body "$(cat <<'EOF'
## Summary
- Implement ChaCha20-Poly1305 AEAD encryption
- Encrypt sensitive fields: amount, note, category
- Add encryption/decryption tests

## Test Plan
- [x] Unit tests for encryption/decryption
- [x] Performance tests (< 10ms/field)
- [x] Integration tests with database
- [x] Security review passed

## Coverage
- Unit: 90%
- Total: 85%

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**PR审查清单:**

**代码质量:**
- [ ] 代码可读性强
- [ ] 遵循代码规范
- [ ] 无重复代码
- [ ] 函数/文件大小合理

**测试:**
- [ ] 测试覆盖率 ≥ 80%
- [ ] 所有测试通过
- [ ] 包含单元测试
- [ ] 包含集成测试 (如需要)

**安全:**
- [ ] 通过security-reviewer检查
- [ ] 无硬编码密钥
- [ ] 输入验证完整
- [ ] 错误处理适当

**性能:**
- [ ] 无明显性能问题
- [ ] 性能测试通过 (如需要)

**文档:**
- [ ] API文档完整
- [ ] 复杂逻辑有注释
- [ ] README更新 (如需要)
- [ ] CHANGELOG更新

**审查流程:**

```
1. 创建PR
   ↓
2. 自动化检查 (CI)
   - 代码格式化
   - 静态分析
   - 测试运行
   - 覆盖率检查
   ↓
3. Code-Reviewer Agent审查
   ↓
4. Security-Reviewer Agent审查
   ↓
5. 人工审查 (Code Owner)
   ↓
6. 修复反馈问题
   ↓
7. 批准 + 合并
```

**合并策略:**
```bash
# Squash and Merge (推荐)
# 将多个提交压缩为一个，保持主分支历史简洁
gh pr merge --squash

# Merge Commit
# 保留完整提交历史
gh pr merge --merge

# Rebase and Merge
# 将功能分支提交重放到主分支
gh pr merge --rebase
```

### 13.3 CI/CD管道

**持续集成流程:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  analyze:
    name: Static Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .

  test:
    name: Unit & Widget Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage
      - name: Check Coverage
        run: |
          COVERAGE=$(flutter test --coverage | grep -oP '\d+(?=% coverage)')
          if [ $COVERAGE -lt 80 ]; then
            echo "❌ Coverage $COVERAGE% below 80%"
            exit 1
          fi
          echo "✅ Coverage: $COVERAGE%"

  integration:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test integration_test/

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Scan for secrets
        uses: trufflesecurity/trufflehog@main
      - name: SAST scan
        uses: AppThreat/sast-scan-action@master
```

**持续部署流程:**

```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-testflight:
    name: Deploy to TestFlight
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release
      - name: Upload to TestFlight
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APP_PASSWORD: ${{ secrets.APP_PASSWORD }}
        run: |
          xcrun altool --upload-app \
            --type ios \
            --file build/ios/ipa/home_pocket.ipa \
            --username "$APPLE_ID" \
            --password "$APP_PASSWORD"

  deploy-play:
    name: Deploy to Play Store
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build appbundle --release
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_KEY }}
          packageName: com.example.home_pocket
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

### 13.4 开发工具

**推荐IDE:**
- **VS Code** + Flutter插件
- **Android Studio** + Flutter插件
- **IntelliJ IDEA** + Flutter插件

**VS Code扩展:**
```json
// .vscode/extensions.json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "usernamehw.errorlens",
    "esbenp.prettier-vscode",
    "eamodio.gitlens",
    "ms-azuretools.vscode-docker"
  ]
}
```

**VS Code配置:**
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

**调试工具:**

1. **Riverpod Inspector**
   ```bash
   # 安装DevTools
   flutter pub global activate devtools

   # 启动DevTools
   flutter pub global run devtools
   ```

2. **DB Browser for SQLite**
   - 查看本地数据库
   - 验证加密数据
   - 调试SQL查询

3. **Flutter DevTools**
   - 性能分析
   - 内存分析
   - 网络监控
   - Widget检查器

**命令别名 (可选):**
```bash
# ~/.bashrc or ~/.zshrc
alias frun="flutter run"
alias ftest="flutter test --coverage"
alias fbuild="flutter build apk --release"
alias fclean="flutter clean && flutter pub get"
alias fanalyze="flutter analyze"
alias fformat="dart format ."
```

---

## 14. 总结

### 14.1 项目概览

**项目名称:** Home Pocket - 家庭记账应用
**技术框架:** Flutter 3.16+ / Dart 3.2+
**核心特性:** 双轨账本、多层加密、P2P同步、OCR扫描

**开发周期:**
- **MVP (v1.0):** 10周 (P0模块)
- **完整版 (v1.2):** 12周 (包含P1增强功能)

**团队规模:** 1-3人小团队
**开发方法:** TDD + Clean Architecture + Agile

### 14.2 关键成功因素

1. **安全优先**
   - 4层加密防护
   - 零知识架构
   - 24词恢复机制

2. **性能优化**
   - 增量余额更新 (40-400x)
   - 增量哈希链验证 (100-2000x)
   - 60 FPS流畅UI

3. **测试驱动**
   - ≥80%测试覆盖率
   - TDD工作流强制执行
   - E2E关键流程测试

4. **代码质量**
   - 不可变性原则
   - 小文件优先
   - 自动化审查

5. **文档完善**
   - 架构文档持续更新
   - ADR记录重大决策
   - API文档自动生成

### 14.3 下一步行动

**立即开始 (Week 1):**
1. 搭建项目基础架构
2. 配置CI/CD管道
3. 开始MOD-006开发 (安全模块)
4. 并行开发MOD-014 (国际化)

**第一个里程碑 (Week 2):**
- M1: 安全基础设施完成
- 验收标准:
  - ✅ 密钥管理系统可用
  - ✅ 生物识别锁正常
  - ✅ 4层加密正常
  - ✅ 3语言支持完整

**持续跟踪:**
- 每日更新开发日志 (worklog/)
- 每周里程碑评估
- 每两周风险评估
- 每月代码审查总结

### 14.4 联系与支持

**项目仓库:** `https://github.com/your-org/home-pocket`
**文档中心:** `arch2/README.md`
**问题跟踪:** GitHub Issues
**讨论区:** GitHub Discussions

---

**文档结束**

**下次更新:** 根据实际开发进度定期更新
**维护责任:** 项目架构师 + 全体开发人员

---

**附录:**

- [A] 架构文档索引 → arch2/01-core-architecture/ARCH-000_INDEX.md
- [B] 模块规范索引 → arch2/02-module-specs/
- [C] ADR索引 → arch2/03-adr/ADR-000_INDEX.md
- [D] 开发日志 → worklog/YYYYMMDD.md
- [E] 变更日志 → CHANGELOG.md

---

**生成信息:**
- 生成日期: 2026-02-03
- 生成工具: Claude Code
- 基于文档: arch2/ 目录 (10个ARCH文档 + 9个MOD文档)
- 开发计划版本: 1.0

🤖 本文档由 Claude Code 基于完整架构分析自动生成
