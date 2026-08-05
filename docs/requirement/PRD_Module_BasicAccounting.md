# PRD - 基础记账模块

**模块ID:** MOD-001, MOD-002
**模块名称:** 基础记账 + 分类管理
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P0（MVP必备）
**预估工时:** 13天（基础记账8天 + 分类管理5天）

---

## 1. 模块概述

### 1.1 功能定义

基础记账模块是Happy Pocket的核心基础功能，负责处理用户的日常收支记录。包括：
- 支出记录（A01）
- 收入记录（A02）
- 交易列表与查询（A05）
- 交易搜索（A06）
- 交易修正（A07）

分类管理模块负责组织和管理交易分类，包括：
- 分类管理（A03）
- 分类图标与颜色（A04）

### 1.2 用户价值

**对用户的价值:**
- 快速记录每一笔消费和收入
- 清晰查看历史交易
- 通过分类组织支出，便于分析
- 修正错误记录，保持数据准确性

**对产品的价值:**
- 所有高级功能的基础（双轨账本、家庭同步等依赖于此）
- 用户粘性的关键（记账频率决定留存率）
- 数据完整性保证（哈希链从这里开始）

### 1.3 依赖关系

**前置依赖:**
- 数据库初始化（Drift + SQLCipher）
- 密钥管理系统（用于加密note字段）
- 主题系统（和风/赛博双模式）

**被依赖:**
- MOD-003 双轨账本（需要分类信息）
- MOD-005 OCR扫描（自动填充交易）
- MOD-007 数据分析（统计交易数据）
- MOD-004 家庭同步（同步交易记录）

---

## 2. 功能详细规格

### 2.1 A01: 支出记录

#### 2.1.1 功能描述

用户可以快速记录一笔支出，包括金额、分类、备注、时间、照片等信息。

#### 2.1.2 交互流程

```
首页 → 点击"➕"按钮 → 支出记录页面
         ↓
   选择"支出"Tab（默认）
         ↓
   输入金额（大数字键盘）
         ↓
   选择分类（自动推荐）
         ↓
   [可选] 添加备注
   [可选] 拍照
   [可选] 选择时间（默认当前时间）
   [可选] 标记为私密
         ↓
   点击"保存"
         ↓
   系统自动判定生存/灵魂账户
         ↓
   哈希链计算并保存
         ↓
   [如启用] 显示趣味换算Toast
   [如为灵魂消费] 播放庆祝动画
         ↓
   返回首页，列表顶部显示新交易
```

#### 2.1.3 UI设计（和风模式）

```
┌─────────────────────────────────────┐
│ ← 新增支出                     保存 │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │         ¥  1,280            │   │  ← 大数字显示
│  │         ━━━━━━━             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──┬──┬──┬──────────────────┐    │
│  │1 │2 │3 │  [今日 14:30] ▼│    │  ← 时间选择
│  ├──┼──┼──┼──────────────────┤    │
│  │4 │5 │6 │                  │    │
│  ├──┼──┼──┤                  │    │
│  │7 │8 │9 │  数字键盘        │    │
│  ├──┼──┼──┤                  │    │
│  │00│0 │⌫ │                  │    │
│  └──┴──┴──┴──────────────────┘    │
│                                     │
│  分类：                             │
│  ┌────────────────────────────┐    │
│  │ 🍚 食費                ▼   │    │  ← 分类选择器
│  └────────────────────────────┘    │
│                                     │
│  账户类型：                         │
│  ┌──────────┐  ┌──────────┐        │
│  │ 🏠 生存  │  │ 💖 灵魂  │        │  ← 自动判断高亮
│  └──────────┘  └──────────┘        │
│  (系统自动判断，可手动切换)          │
│                                     │
│  备注：                             │
│  ┌────────────────────────────┐    │
│  │ 午餐 @ 吉野家              │    │
│  └────────────────────────────┘    │
│                                     │
│  [📷 拍照]  [📍 位置]  [🔒 私密] │
│                                     │
└─────────────────────────────────────┘
```

#### 2.1.4 数据模型

```dart
class Transaction {
  final String id;              // UUID
  final String bookId;          // 关联账本
  final String deviceId;        // 创建设备
  final int amount;             // 金额（日元，整数）
  final TransactionType type;   // expense | income | transfer
  final String categoryId;      // 分类ID
  final LedgerType ledgerType;  // survival | soul
  final DateTime timestamp;     // 发生时间
  final String? note;           // 备注（加密存储）
  final String? photoHash;      // 照片哈希
  final String? prevHash;       // 前一笔交易的哈希
  final String currentHash;     // 当前交易的哈希
  final DateTime createdAt;     // 创建时间
  final bool isPrivate;         // 是否私密（单人模式无效）
}
```

#### 2.1.5 业务逻辑

**金额验证:**
```dart
class AmountValidator {
  static const int maxAmount = 99999999;  // 9999万9999日元
  static const int minAmount = 1;

  ValidationResult validate(int amount) {
    if (amount < minAmount) {
      return ValidationResult.error('金额必须大于0');
    }
    if (amount > maxAmount) {
      return ValidationResult.error('金额超过上限（9999万日元）');
    }
    return ValidationResult.success();
  }
}
```

**哈希链计算:**
```dart
class HashChainService {
  Future<String> calculateHash(Transaction tx) async {
    // 获取前一笔交易的哈希
    final prevHash = tx.prevHash ?? 'genesis';

    // 构造待哈希数据（关键字段）
    final data = '${tx.id}|${tx.amount}|${tx.type}|${tx.categoryId}|'
                 '${tx.timestamp.millisecondsSinceEpoch}|$prevHash';

    // SHA-256哈希
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<bool> verifyChain(String bookId) async {
    final transactions = await _repo.getTransactions(
      bookId: bookId,
      orderBy: 'timestamp ASC',
    );

    String prevHash = 'genesis';
    for (final tx in transactions) {
      final expectedHash = await calculateHash(
        tx.copyWith(prevHash: prevHash),
      );

      if (tx.currentHash != expectedHash) {
        // 检测到篡改
        await _logTamperDetection(tx);
        return false;
      }

      prevHash = tx.currentHash;
    }

    return true;
  }
}
```

**自动分类（生存/灵魂）:**
```dart
class LedgerTypeClassifier {
  Future<LedgerType> classify(String categoryId) async {
    final category = await _categoryRepo.getById(categoryId);

    // 如果分类明确指定了账户类型
    if (category.ledgerType != LedgerType.auto) {
      return category.ledgerType;
    }

    // 使用规则引擎
    return _ruleEngine.classify(category);
  }
}

class RuleEngine {
  LedgerType classify(Category category) {
    // 规则1：必需消费 → 生存账户
    final survivalCategories = [
      'food_groceries',      // 超市食品
      'housing_rent',        // 房租
      'transport_commute',   // 通勤交通
      'utilities',           // 水电煤
      'medical',             // 医疗
      'education',           // 教育（必需）
    ];

    if (survivalCategories.contains(category.id)) {
      return LedgerType.survival;
    }

    // 规则2：享乐消费 → 灵魂账户
    final soulCategories = [
      'food_restaurant',     // 外食
      'entertainment',       // 娱乐
      'hobby',               // 爱好
      'travel',              // 旅行
      'shopping_luxury',     // 奢侈品
    ];

    if (soulCategories.contains(category.id)) {
      return LedgerType.soul;
    }

    // 默认：生存账户（保守策略）
    return LedgerType.survival;
  }
}
```

#### 2.1.6 验收标准

- ✅ 用户可以在3秒内完成一笔支出记录
- ✅ 金额输入支持数字键盘（0-9、00、删除）
- ✅ 分类选择器显示图标+名称，支持搜索
- ✅ 时间默认当前时间，可选择过去7天内任意时间
- ✅ 备注字段加密存储（ChaCha20-Poly1305）
- ✅ 哈希链正确计算并保存
- ✅ 保存成功后自动返回首页，列表顶部显示新交易
- ✅ 如启用趣味功能，显示换算器Toast（3秒后消失）
- ✅ 如为灵魂消费，播放庆祝动画（2秒，可跳过）

---

### 2.2 A02: 收入记录

#### 2.2.1 功能描述

用户可以记录收入，包括工资、奖金、副业等。收入类型影响分析报表的计算。

#### 2.2.2 与支出的差异

| 特性 | 支出 | 收入 |
|------|------|------|
| 账户类型 | 生存/灵魂 | 不区分（统一为收入）|
| 默认分类 | 食費等 | 工资、奖金、副业 |
| 庆祝动画 | 仅灵魂消费 | 无动画 |
| 趣味换算 | 支持 | 不支持 |

#### 2.2.3 收入分类预设

```dart
const incomeCategories = [
  Category(
    id: 'income_salary',
    name: '給料（月給）',
    icon: '💼',
    color: '#4CAF50',
    ledgerType: LedgerType.income,
  ),
  Category(
    id: 'income_bonus',
    name: 'ボーナス',
    icon: '🎁',
    color: '#8BC34A',
    ledgerType: LedgerType.income,
  ),
  Category(
    id: 'income_sidejob',
    name: '副業',
    icon: '💻',
    color: '#CDDC39',
    ledgerType: LedgerType.income,
  ),
  Category(
    id: 'income_investment',
    name: '投資収益',
    icon: '📈',
    color: '#FFC107',
    ledgerType: LedgerType.income,
  ),
  Category(
    id: 'income_other',
    name: 'その他収入',
    icon: '💰',
    color: '#FF9800',
    ledgerType: LedgerType.income,
  ),
];
```

---

### 2.3 A03-A04: 分类管理

#### 2.3.1 预设分类清单（20个）

**支出分类（15个）:**
```dart
const expenseCategories = [
  // 生存必需（8个）
  Category(id: 'food_groceries', name: '食費（スーパー）', icon: '🛒', color: '#4CAF50', ledgerType: LedgerType.survival),
  Category(id: 'housing_rent', name: '住宅（家賃）', icon: '🏠', color: '#795548', ledgerType: LedgerType.survival),
  Category(id: 'utilities', name: '光熱費', icon: '💡', color: '#FF9800', ledgerType: LedgerType.survival),
  Category(id: 'transport_commute', name: '交通費（通勤）', icon: '🚇', color: '#2196F3', ledgerType: LedgerType.survival),
  Category(id: 'medical', name: '医療費', icon: '💊', color: '#F44336', ledgerType: LedgerType.survival),
  Category(id: 'insurance', name: '保険', icon: '🛡️', color: '#9C27B0', ledgerType: LedgerType.survival),
  Category(id: 'communication', name: '通信費', icon: '📱', color: '#3F51B5', ledgerType: LedgerType.survival),
  Category(id: 'daily_goods', name: '日用品', icon: '🧴', color: '#00BCD4', ledgerType: LedgerType.survival),

  // 灵魂享乐（7个）
  Category(id: 'food_restaurant', name: '食費（外食）', icon: '🍜', color: '#FF9800', ledgerType: LedgerType.soul),
  Category(id: 'entertainment', name: '娯楽', icon: '🎮', color: '#E91E63', ledgerType: LedgerType.soul),
  Category(id: 'hobby', name: '趣味', icon: '🎨', color: '#9C27B0', ledgerType: LedgerType.soul),
  Category(id: 'shopping_fashion', name: 'ファッション', icon: '👔', color: '#FF5722', ledgerType: LedgerType.soul),
  Category(id: 'beauty', name: '美容', icon: '💅', color: '#E91E63', ledgerType: LedgerType.soul),
  Category(id: 'travel', name: '旅行', icon: '✈️', color: '#00BCD4', ledgerType: LedgerType.soul),
  Category(id: 'education_hobby', name: '学習（趣味）', icon: '📚', color: '#3F51B5', ledgerType: LedgerType.soul),
];
```

#### 2.3.2 自定义分类

**创建自定义分类:**
```dart
class CreateCategoryUseCase {
  Future<Category> execute({
    required String name,
    required String icon,
    required String color,
    required LedgerType ledgerType,
  }) async {
    // 验证
    if (name.isEmpty || name.length > 20) {
      throw ValidationException('分类名称长度必须在1-20字符之间');
    }

    if (!_isValidIcon(icon)) {
      throw ValidationException('请选择有效的图标');
    }

    if (!_isValidColor(color)) {
      throw ValidationException('请选择有效的颜色');
    }

    // 创建分类
    final category = Category(
      id: 'custom_${uuid.v4()}',
      name: name,
      icon: icon,
      color: color,
      ledgerType: ledgerType,
      isSystem: false,
      createdAt: DateTime.now(),
    );

    await _categoryRepo.insert(category);
    return category;
  }

  bool _isValidIcon(String icon) {
    // 验证是否为emoji
    return icon.runes.length == 1 || icon.runes.length == 2;
  }

  bool _isValidColor(String color) {
    // 验证十六进制颜色格式
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);
  }
}
```

**图标选择器:**
```
常用图标分类：
- 食物：🍜🍚🍗🍕🍰🍺🍱
- 购物：🛒👔👗👜💄💍
- 交通：🚇🚌🚗✈️🚃
- 娱乐：🎮🎬🎵🎨📚⚽
- 生活：🏠💡💊🧴🛁
- 其他：💰💳📱💻📷
```

**颜色选择器:**
```
预设颜色板（Material Design）:
- 红色系：#F44336, #E91E63, #FF5722
- 蓝色系：#2196F3, #3F51B5, #00BCD4
- 绿色系：#4CAF50, #8BC34A, #009688
- 黄色系：#FFEB3B, #FFC107, #FF9800
- 紫色系：#9C27B0, #673AB7
- 灰色系：#9E9E9E, #607D8B, #795548
```

#### 2.3.3 分类编辑

**限制:**
- ✅ 系统预设分类可以修改颜色和图标
- ❌ 系统预设分类不能修改名称和账户类型
- ✅ 自定义分类可以完全修改
- ❌ 如分类已被交易使用，不能删除（只能归档）

**归档机制:**
```dart
class ArchiveCategoryUseCase {
  Future<void> execute(String categoryId) async {
    // 检查是否被使用
    final usageCount = await _transactionRepo.countByCategory(categoryId);

    if (usageCount > 0) {
      // 不能删除，改为归档
      await _categoryRepo.update(
        categoryId,
        isArchived: true,
      );

      // 归档后的分类不再显示在选择器中
      // 但已有交易仍显示该分类
    } else {
      // 未被使用，直接删除
      await _categoryRepo.delete(categoryId);
    }
  }
}
```

---

### 2.4 A05-A06: 交易列表与搜索

#### 2.4.1 列表展示

**分组方式:**
- 按日期分组（今日、昨日、本周、本月、更早）
- 每组显示日期 + 总金额
- 支持无限滚动加载（每页50条）

**列表项样式（和风模式）:**
```
┌─────────────────────────────────────┐
│  今日  2/3                 ¥3,390   │  ← 组头
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 🍚 食費             ¥1,280 🏠 │  │  ← 生存标记
│  │ 午餐 @ 吉野家                │  │
│  │ 14:30                         │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🎮 趣味             ¥2,110 💖 │  │  ← 灵魂标记
│  │ HG ザク II                   │  │
│  │ 11:20                 [照片]  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**滑动操作:**
- 左滑：删除（显示确认对话框）
- 右滑：编辑

**空状态:**
```
┌─────────────────────────────────────┐
│                                     │
│           📝                        │
│       まだ記録がありません           │
│                                     │
│   [➕ 最初の記録を追加]             │
│                                     │
└─────────────────────────────────────┘
```

#### 2.4.2 搜索功能

**搜索范围:**
- 金额（精确匹配或范围）
- 分类
- 备注关键词
- 日期范围

**搜索UI:**
```
┌─────────────────────────────────────┐
│ ← 搜索交易                          │
├─────────────────────────────────────┤
│  ┌────────────────────────────┐ 🔍 │
│  │ 关键词、金额、分类...       │    │
│  └────────────────────────────┘    │
│                                     │
│  快速筛选：                         │
│  [今日] [本周] [本月]               │
│  [生存] [灵魂] [收入]               │
│                                     │
│  高级筛选：                         │
│  金额范围：¥1000 - ¥5000           │
│  分类：食費、交通費                 │
│  日期：2026/1/1 - 2026/1/31        │
│                                     │
│  ┌─ 结果 (23笔) ─┐                 │
│  │ ...           │                 │
│  └───────────────┘                 │
└─────────────────────────────────────┘
```

**搜索逻辑:**
```dart
class SearchTransactionsUseCase {
  Future<List<Transaction>> execute(SearchQuery query) async {
    return await _repo.search(
      keyword: query.keyword,
      minAmount: query.minAmount,
      maxAmount: query.maxAmount,
      categoryIds: query.categoryIds,
      ledgerTypes: query.ledgerTypes,
      startDate: query.startDate,
      endDate: query.endDate,
    );
  }
}

// SQL示例
SELECT * FROM transactions
WHERE book_id = ?
  AND (note LIKE ? OR category_id IN (?))
  AND amount BETWEEN ? AND ?
  AND timestamp BETWEEN ? AND ?
  AND ledger_type IN (?)
ORDER BY timestamp DESC
LIMIT ? OFFSET ?
```

---

### 2.5 A07: 交易修正

#### 2.5.1 功能描述

用户发现记录错误后，可以创建修正记录。修正采用"插入修正事件"而非"直接修改"，保证哈希链不被破坏。

#### 2.5.2 修正流程

```
查看交易详情 → 点击"修正"
         ↓
   选择修正类型：
   - 修改金额
   - 修改分类
   - 修改备注
   - 修改账户类型
         ↓
   输入新值
         ↓
   确认修正
         ↓
   生成修正记录（新transaction）:
   - type = 'correction'
   - original_tx_id = 被修正的交易ID
   - correction_type = 'amount' | 'category' | ...
   - correction_value = 新值
         ↓
   标记原交易为"已修正"状态
         ↓
   更新显示（列表中显示修正后的值）
```

#### 2.5.3 数据模型

```dart
class CorrectionTransaction extends Transaction {
  final String originalTxId;       // 被修正的交易ID
  final CorrectionType correctionType;
  final dynamic correctionValue;
  final String? reason;             // 修正原因（可选）

  CorrectionTransaction({
    required super.id,
    required super.bookId,
    required super.deviceId,
    required this.originalTxId,
    required this.correctionType,
    required this.correctionValue,
    this.reason,
    // ... 其他字段
  }) : super(type: TransactionType.correction);
}

enum CorrectionType {
  amount,
  category,
  note,
  ledgerType,
  timestamp,
}
```

#### 2.5.4 UI设计

**修正对话框:**
```
┌─────────────────────────────────────┐
│  修正交易                           │
├─────────────────────────────────────┤
│  原记录：                           │
│  🍚 食費  ¥1,280  午餐 @ 吉野家     │
│  2/3 14:30                          │
│                                     │
│  修正内容：                         │
│  ┌────────────────────────────┐    │
│  │ [✓] 金额      ¥1,380       │    │
│  │ [ ] 分类                   │    │
│  │ [ ] 备注                   │    │
│  │ [ ] 账户类型               │    │
│  └────────────────────────────┘    │
│                                     │
│  修正原因（可选）:                  │
│  ┌────────────────────────────┐    │
│  │ 忘记算税费了                │    │
│  └────────────────────────────┘    │
│                                     │
│  ⚠️ 修正后原记录仍保留，           │
│     但列表中显示修正后的值         │
│                                     │
│  [取消]              [确认修正]     │
└─────────────────────────────────────┘
```

**列表中显示修正标记:**
```
┌───────────────────────────────┐
│ 🍚 食費         ¥1,380 🏠 🔄 │  ← 修正标记
│ 午餐 @ 吉野家  (已修正)       │
│ 14:30                         │
└───────────────────────────────┘
```

#### 2.5.5 审计日志查看

用户可以查看交易的完整修正历史：

```
交易详情 → 点击"修正历史"

┌─────────────────────────────────────┐
│  修正历史                           │
├─────────────────────────────────────┤
│  原始记录（2/3 14:30）              │
│  金额：¥1,280                       │
│  分类：食費                         │
│  备注：午餐 @ 吉野家                │
│  哈希：abc123...                    │
│                                     │
│  ───────────────────────────       │
│                                     │
│  修正记录1（2/3 15:00）             │
│  修正人：Device A (自己)            │
│  修正内容：金额 ¥1,280 → ¥1,380    │
│  修正原因：忘记算税费了             │
│  哈希：def456...                    │
│                                     │
│  ───────────────────────────       │
│                                     │
│  当前显示值：¥1,380                 │
│  哈希链状态：✅ 完整                │
└─────────────────────────────────────┘
```

---

## 3. 技术实现

### 3.1 Repository实现

```dart
// lib/features/transaction/data/repositories/transaction_repository_impl.dart

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase db;
  final EncryptionService encryption;

  @override
  Future<void> insert(Transaction transaction) async {
    // 加密note字段
    final encryptedNote = transaction.note != null
        ? await encryption.encrypt(transaction.note!)
        : null;

    // 插入数据库
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        id: transaction.id,
        bookId: transaction.bookId,
        deviceId: transaction.deviceId,
        amount: transaction.amount,
        type: transaction.type.name,
        categoryId: transaction.categoryId,
        ledgerType: transaction.ledgerType.name,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        note: Value(encryptedNote),
        photoHash: Value(transaction.photoHash),
        prevHash: Value(transaction.prevHash),
        currentHash: transaction.currentHash,
        createdAt: transaction.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = db.select(db.transactions)
      ..where((t) => t.bookId.equals(bookId));

    if (ledgerType != null) {
      query.where((t) => t.ledgerType.equals(ledgerType.name));
    }

    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(
        startDate.millisecondsSinceEpoch,
      ));
    }

    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerOrEqualValue(
        endDate.millisecondsSinceEpoch,
      ));
    }

    query
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapToTransaction(row)).toList();
  }

  Transaction _mapToTransaction(TransactionData row) {
    return Transaction(
      id: row.id,
      bookId: row.bookId,
      deviceId: row.deviceId,
      amount: row.amount,
      type: TransactionType.values.byName(row.type),
      categoryId: row.categoryId,
      ledgerType: LedgerType.values.byName(row.ledgerType),
      timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
      note: row.note != null ? encryption.decrypt(row.note!) : null,
      photoHash: row.photoHash,
      prevHash: row.prevHash,
      currentHash: row.currentHash,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }
}
```

### 3.2 UI组件

**金额输入组件:**
```dart
class AmountInput extends StatefulWidget {
  final Function(int) onAmountChanged;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  String _displayAmount = '0';

  void _onNumberPressed(String digit) {
    setState(() {
      if (_displayAmount == '0') {
        _displayAmount = digit;
      } else {
        _displayAmount += digit;
      }
      widget.onAmountChanged(int.parse(_displayAmount));
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_displayAmount.length > 1) {
        _displayAmount = _displayAmount.substring(0, _displayAmount.length - 1);
      } else {
        _displayAmount = '0';
      }
      widget.onAmountChanged(int.parse(_displayAmount));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '¥ ${_formatAmount(_displayAmount)}',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        SizedBox(height: 24),
        // 数字键盘布局
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
            _buildKey('00'),
            _buildKey('0'),
            _buildDeleteKey(),
          ],
        ),
      ],
    );
  }

  String _formatAmount(String amount) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return formatter.format(int.parse(amount));
  }
}
```

---

## 4. 测试计划

### 4.1 单元测试

```dart
void main() {
  group('TransactionRepository', () {
    test('should insert and retrieve transaction', () async {
      final repo = TransactionRepositoryImpl(db, encryption);
      final tx = Transaction(...);

      await repo.insert(tx);
      final retrieved = await repo.getById(tx.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(tx.id));
      expect(retrieved.amount, equals(tx.amount));
    });

    test('should verify hash chain integrity', () async {
      final hashChain = HashChainService(repo);
      final result = await hashChain.verifyChain(bookId);

      expect(result, isTrue);
    });
  });
}
```

### 4.2 Widget测试

```dart
void main() {
  testWidgets('should create transaction', (tester) async {
    await tester.pumpWidget(MyApp());

    // 点击添加按钮
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 输入金额
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('8'));
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    // 验证显示
    expect(find.text('¥ 1,280'), findsOneWidget);

    // 选择分类
    await tester.tap(find.text('食費'));
    await tester.pumpAndSettle();

    // 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证列表
    expect(find.text('¥1,280'), findsOneWidget);
  });
}
```

---

## 5. 附录

### 5.1 工时估算明细

| 任务 | 子任务 | 工时 |
|------|--------|------|
| A01 支出记录 | UI实现 | 2天 |
|             | 业务逻辑 | 1天 |
|             | 哈希链集成 | 1天 |
| A02 收入记录 | UI实现 | 1天 |
|             | 业务逻辑 | 0.5天 |
| A03 分类管理 | 预设分类 | 1天 |
|             | 自定义分类 | 2天 |
| A04 图标颜色 | UI组件 | 2天 |
| A05 交易列表 | 列表UI | 1天 |
|             | 分页加载 | 1天 |
| A06 搜索功能 | 搜索UI | 1天 |
|             | 查询逻辑 | 1天 |
| A07 交易修正 | UI实现 | 1天 |
|             | 修正逻辑 | 1天 |
| **总计** | | **13天** |

### 5.2 相关文档

- [PRD_MVP_Global.md](./PRD_MVP_Global.md) - MVP全局需求
- [PRD_MVP_App.md](./PRD_MVP_App.md) - App端总体需求
- [PRD_Module_DualLedger.md](./PRD_Module_DualLedger.md) - 双轨账本模块（依赖本模块）

---

**文档状态:** Draft
**需要评审:** 产品经理、前端开发、UI/UX设计师
