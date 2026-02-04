# Book 模型用途解析

**文档类型:** 技术分析报告
**创建日期:** 2026-02-04
**模块:** MOD-001 Basic Accounting
**作者:** Claude Sonnet 4.5
**状态:** 完成

---

## 📚 **核心概念：多账本支持**

Book（账本）是 Home Pocket 应用中的**容器概念**，用于实现**多账本管理**功能。

### 1️⃣ **什么是 Book？**

```
用户 (User)
  └── 可以创建多个账本 (Books)
       ├── 个人账本 (Personal Book)
       ├── 家庭账本 (Family Book)
       ├── 旅行账本 (Travel Book)
       └── 公司账本 (Business Book)
```

**类比理解：**
- Book = 一个独立的"记账本"
- Transaction = 账本中的每一笔记录
- Category = 账本中使用的分类系统

---

## 🎯 **Book 的 5 大用途**

### **用途 1：账本隔离 (Data Isolation)**

```dart
// 场景：用户创建多个账本
Book personalBook = Book.create(
  name: '个人账本',
  currency: 'CNY',
  deviceId: 'device_001',
);

Book familyBook = Book.create(
  name: '家庭共享账本',
  currency: 'CNY',
  deviceId: 'device_001',
);

Book travelBook = Book.create(
  name: '日本旅行',
  currency: 'JPY',  // 不同货币！
  deviceId: 'device_001',
);
```

**好处：**
- ✅ 数据隔离：个人消费和家庭消费分开
- ✅ 场景分离：旅行、日常、工作分开管理
- ✅ 权限控制：未来可以设置账本共享权限

---

### **用途 2：多货币支持 (Multi-Currency)**

```dart
// Book 的核心字段
const factory Book({
  required String currency,  // ISO 4217: "CNY", "USD", "JPY"
  // ...
});
```

**应用场景：**
- 🇨🇳 中国用户：创建 CNY 账本（人民币）
- 🇺🇸 美国用户：创建 USD 账本（美元）
- 🇯🇵 日本旅行：创建 JPY 账本（日元）
- 💱 跨境消费：不同账本使用不同货币

**实现细节：**
```dart
// Transaction 属于 Book，继承其货币设置
Transaction tx = Transaction.create(
  bookId: 'book_japan_travel',  // 关联到日本旅行账本
  amount: 15000,  // 150 日元（存储为分）
  // 货币由 Book 决定，不需要在 Transaction 中重复存储
);
```

---

### **用途 3：性能优化 - 冗余统计 (Denormalized Statistics)**

```dart
// Statistics (denormalized for performance)
@Default(0) int transactionCount,
@Default(0) int survivalBalance,  // Balance in cents
@Default(0) int soulBalance,      // Balance in cents
```

**为什么需要冗余统计？**

❌ **慢速方案（每次实时计算）：**
```sql
-- 查询账本余额需要扫描所有交易记录
SELECT SUM(amount) FROM transactions WHERE bookId = 'book_001'
-- 如果有 10,000 笔交易，每次都要计算
```

✅ **快速方案（预计算存储）：**
```dart
// 直接读取 Book 中的缓存值
int balance = book.totalBalance;  // O(1) 时间复杂度
```

**更新机制：**
```dart
// 每次创建/更新/删除交易时，增量更新 Book 统计
void onTransactionCreated(Transaction tx) {
  book = book.copyWith(
    transactionCount: book.transactionCount + 1,
    survivalBalance: book.survivalBalance + tx.amount, // 假设是 survival
    updatedAt: DateTime.now(),
  );
}
```

**性能提升：**
- 📊 显示余额：从 O(n) → O(1)
- ⚡ 列表性能：40-400x 改进（参考 ADR-008）

---

### **用途 4：设备关联 (Device Binding)**

```dart
required String deviceId,
```

**用途：**
1. **P2P 同步**（MOD-004 家庭同步）
   - 追踪账本是在哪个设备上创建的
   - 支持多设备同步时的冲突解决

2. **安全审计**
   - 记录账本创建来源
   - 追踪设备访问历史

3. **离线优先架构**
   - 每个设备有唯一 deviceId
   - 本地创建的数据带有设备标记

---

### **用途 5：归档管理 (Archive Support)**

```dart
@Default(false) bool isArchived,
```

**使用场景：**

```dart
// 场景 1：旅行结束，归档旅行账本
Book travelBook = book.copyWith(isArchived: true);

// 场景 2：查询时过滤归档账本
List<Book> activeBooks = await bookRepository.findActive();
// SELECT * FROM books WHERE isArchived = false

// 场景 3：归档账本仍然可查看，但不在默认列表中
List<Book> allBooks = await bookRepository.findAll();
```

**好处：**
- 🗂️ 保持 UI 清爽（隐藏不活跃账本）
- 💾 数据保留（归档不是删除）
- 📈 历史分析（可以重新激活查看历史数据）

---

## 🏗️ **Book 在架构中的位置**

```
┌─────────────────────────────────────────┐
│           User Account                  │
│         (未来 MOD-004)                  │
└─────────────────┬───────────────────────┘
                  │ 1:N
         ┌────────▼─────────┐
         │      Books       │ ◄── 账本（容器）
         │   (多账本支持)    │
         └────────┬─────────┘
                  │ 1:N
         ┌────────▼──────────┐
         │   Transactions    │ ◄── 交易记录
         │  (记账明细)        │
         └───────────────────┘
```

**关系说明：**
- 1 个用户 → N 个账本
- 1 个账本 → N 笔交易
- 每笔交易必须属于某个账本

---

## 💡 **实际应用示例**

### **示例 1：多场景记账**

```dart
// 用户张三有 3 个账本
Book daily = Book.create(name: '日常开销', currency: 'CNY', deviceId: 'phone');
Book investment = Book.create(name: '投资理财', currency: 'CNY', deviceId: 'phone');
Book shopping = Book.create(name: '双11剁手', currency: 'CNY', deviceId: 'phone');

// 创建交易时指定账本
Transaction lunch = Transaction.create(
  bookId: daily.id,  // 属于日常账本
  amount: 3500,  // 35 元
  categoryId: 'cat_food',
  ledgerType: LedgerType.survival,
);

Transaction stock = Transaction.create(
  bookId: investment.id,  // 属于投资账本
  amount: 100000,  // 1000 元
  categoryId: 'cat_investment',
  ledgerType: LedgerType.soul,
);
```

### **示例 2：家庭共享（未来功能）**

```dart
// 创建家庭共享账本
Book familyBook = Book.create(
  name: '张家账本',
  currency: 'CNY',
  deviceId: 'dad_phone',
);

// 未来 MOD-004：多个家庭成员可以同步此账本
// - 爸爸的手机：创建者
// - 妈妈的手机：同步查看和记账
// - 孩子的手机：只读权限
```

### **示例 3：旅行记账**

```dart
// 去日本旅行，创建专门账本
Book japanTrip = Book.create(
  name: '2026东京之旅',
  currency: 'JPY',  // 日元
  deviceId: 'phone',
);

// 记录旅行花费
Transaction hotelFee = Transaction.create(
  bookId: japanTrip.id,
  amount: 1500000,  // 15000 日元
  categoryId: 'cat_housing',
  note: '新宿酒店 3晚',
);

// 旅行结束，归档账本
japanTrip = japanTrip.copyWith(isArchived: true);

// 未来想查看旅行花费时，可以重新打开归档账本
```

---

## 🔍 **Book 的设计哲学**

### **1. 单一职责原则 (SRP)**
- Book 只负责"账本容器"的职责
- 不关心交易细节（由 Transaction 负责）
- 不关心分类（由 Category 负责）

### **2. 性能优先 (Performance First)**
- 冗余统计字段避免实时计算
- 支持 ADR-008 增量更新策略

### **3. 扩展性设计 (Extensibility)**
- `deviceId` 为 P2P 同步预留
- `isArchived` 支持生命周期管理
- `currency` 支持国际化

### **4. 不可变性 (Immutability)**
```dart
// Freezed 模式：所有修改都返回新对象
Book updatedBook = book.copyWith(
  transactionCount: book.transactionCount + 1,
);
// 原始 book 对象不变，符合函数式编程原则
```

---

## 📊 **数据模型详解**

### **完整字段说明**

```dart
@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,              // UUID，唯一标识
    required String name,            // 账本名称，如"日常开销"
    required String currency,        // ISO 4217货币代码
    required String deviceId,        // 创建设备ID
    required DateTime createdAt,     // 创建时间
    DateTime? updatedAt,             // 最后更新时间
    @Default(false) bool isArchived, // 是否归档

    // 性能优化：冗余统计
    @Default(0) int transactionCount,  // 交易数量
    @Default(0) int survivalBalance,   // 生存账本余额（分）
    @Default(0) int soulBalance,       // 灵魂账本余额（分）
  }) = _Book;

  // 计算总余额
  int get totalBalance => survivalBalance + soulBalance;
}
```

### **字段约束**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| id | String | ✅ | UUID v4 | 全局唯一标识 |
| name | String | ✅ | 1-100字符 | 账本名称 |
| currency | String | ✅ | ISO 4217 (3字符) | CNY/USD/JPY 等 |
| deviceId | String | ✅ | - | 设备唯一标识 |
| createdAt | DateTime | ✅ | - | 创建时间戳 |
| updatedAt | DateTime | ❌ | - | 修改时间戳 |
| isArchived | bool | ✅ | 默认 false | 归档标记 |
| transactionCount | int | ✅ | ≥ 0 | 交易总数 |
| survivalBalance | int | ✅ | 可负数 | 生存账本余额 |
| soulBalance | int | ✅ | 可负数 | 灵魂账本余额 |

---

## 🔗 **与其他模型的关系**

### **Book ← Transaction (1:N)**

```dart
// Book 和 Transaction 的关系
class Transaction {
  required String bookId;  // 外键，关联到 Book.id
  // ...
}

// 查询某账本的所有交易
List<Transaction> transactions = await transactionRepository.findByBook(
  bookId: book.id,
);
```

### **Book → Device (N:1)**

```dart
// 未来 MOD-004 实现时
class Device {
  String id;
  String name;
  // ...
}

// 一个设备可以创建多个账本
List<Book> myBooks = await bookRepository.findByDevice(
  deviceId: currentDevice.id,
);
```

---

## ⚡ **性能考虑**

### **1. 索引设计（未来 Data Layer 实现）**

```dart
// books 表的索引
@DataClassName('BookEntity')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  BoolColumn get isArchived => boolean()();

  @override
  List<Index> get indexes => [
    // 主键索引
    Index('books_pk', [id], unique: true),

    // 查询活跃账本的索引
    Index('books_active_idx', [isArchived, deviceId]),
  ];
}
```

### **2. 统计字段更新策略**

```dart
// 增量更新，避免全量重新计算
void updateBookStatisticsIncremental(
  Book book,
  Transaction transaction,
  UpdateType type,
) {
  final delta = type == UpdateType.add ? transaction.amount : -transaction.amount;

  final updatedBook = book.copyWith(
    transactionCount: book.transactionCount + (type == UpdateType.add ? 1 : -1),
    survivalBalance: transaction.ledgerType == LedgerType.survival
        ? book.survivalBalance + delta
        : book.survivalBalance,
    soulBalance: transaction.ledgerType == LedgerType.soul
        ? book.soulBalance + delta
        : book.soulBalance,
    updatedAt: DateTime.now(),
  );

  await bookRepository.update(updatedBook);
}
```

---

## 🚀 **未来扩展方向**

### **1. 账本共享（MOD-004）**
```dart
// 未来可能添加的字段
class Book {
  List<String>? sharedWithDeviceIds;  // 共享给哪些设备
  String? ownerId;                    // 所有者ID
  BookPermission? permission;         // 权限级别（只读/读写）
}
```

### **2. 账本主题和图标**
```dart
class Book {
  String? icon;        // 账本图标
  String? color;       // 主题颜色
  String? coverImage;  // 封面图片
}
```

### **3. 预算功能**
```dart
class Book {
  int? monthlyBudget;     // 月度预算（分）
  int? survivalBudget;    // 生存账本预算
  int? soulBudget;        // 灵魂账本预算
}
```

---

## ✅ **总结**

| 维度 | 说明 |
|------|------|
| **核心定位** | 交易的逻辑容器，实现多账本隔离 |
| **主要用途** | 场景隔离、多货币、性能优化、设备绑定、归档管理 |
| **性能优化** | 冗余统计字段，避免 O(n) 查询 |
| **扩展能力** | 支持未来的家庭同步、权限控制 |
| **设计原则** | 不可变、单一职责、性能优先 |
| **数据完整性** | UUID 唯一性，外键关联 Transaction |
| **用户价值** | 灵活管理不同场景、货币、用途的账本 |

**Book 不仅仅是一个数据模型，它是整个记账系统的"组织单元"，让用户可以灵活地管理不同场景、不同货币、不同用途的账本。**

---

## 📚 **参考资料**

- **架构文档:** `doc/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **模块规范:** `doc/arch/02-module-specs/MOD-001_BasicAccounting.md`
- **性能决策:** `doc/arch/03-adr/ADR-008_Incremental_Balance_Updates.md`
- **源代码:** `lib/features/accounting/domain/models/book.dart`
- **测试代码:** `test/features/accounting/domain/models/book_test.dart`

---

**文档版本:** 1.0
**最后更新:** 2026-02-04
**审核状态:** ✅ 已完成
