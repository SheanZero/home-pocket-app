# PRD - 双轨账本模块

**模块ID:** MOD-003
**模块名称:** 双轨账本（生存账户 + 灵魂账户）
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P0（MVP必备）
**预估工时:** 8天

---

## 1. 模块概述

### 1.1 功能定义

双轨账本是Happy Pocket的核心差异化功能,将所有消费自动分类为两个账户:
- **生存账户（サバイバル勘定）:** 必需支出,如房租、水电、超市食品
- **灵魂账户（ソウル勘定）:** 爱好支出,如外食、娱乐、兴趣消费

**核心价值主张:**
赋予爱好消费正向意义,避免愧疚感。将"买高达模型"重构为"精神资产投资",而非"浪费钱"。

### 1.2 用户场景与痛点

**用户画像:**
- 田中和美惠（35岁夫妇）,美惠喜欢买美妆,田中喜欢买高达模型
- 每月记账时因"兴趣消费"争吵
- 传统记账应用将所有支出视为"负担",缺乏情感设计

**痛点:**
1. **传统记账的负面情绪:** 看到支出报表时只有焦虑和愧疚
2. **爱好消费的道德压力:** 买喜欢的东西时心理负担重
3. **夫妻间因爱好消费争执:** "你又买模型了?" vs "你的化妆品还不够多?"

**Happy Pocket解决方案:**
- 自动将消费分为"必需"和"享乐"两类
- 给灵魂消费正向反馈（庆祝动画）
- 夫妻模式下:伴侣只能看到灵魂账户预算进度,不能看到明细（隐私保护）

### 1.3 与其他模块的依赖关系

**前置依赖:**
- MOD-001 基础记账（需要交易数据）
- MOD-002 分类管理（需要分类信息）

**被依赖:**
- MOD-007 数据分析（双轨报表）
- MOD-009 趣味功能（灵魂消费庆祝动画）
- MOD-004 家庭同步（伴侣隐私设置）

---

## 2. 详细功能规格

### 2.1 自动分类引擎（三层策略）

#### 2.1.1 Layer 1: 规则引擎（优先级最高）

**功能概述:**
基于预设规则,将20个系统分类映射到生存/灵魂账户。

**规则映射表:**

| 分类ID | 分类名称 | 账户类型 | 置信度 |
|--------|---------|---------|--------|
| food_groceries | 食費（スーパー） | survival | 100% |
| food_restaurant | 食費（外食） | soul | 95% |
| housing_rent | 住宅（家賃） | survival | 100% |
| utilities | 光熱費 | survival | 100% |
| transport_commute | 交通費（通勤） | survival | 100% |
| transport_travel | 交通費（旅行） | soul | 95% |
| medical | 医療費 | survival | 100% |
| entertainment | 娯楽 | soul | 100% |
| hobby | 趣味 | soul | 100% |
| shopping_fashion | ファッション | soul | 90% |
| beauty | 美容 | soul | 90% |
| education | 学習 | survival | 80% |
| insurance | 保険 | survival | 100% |
| communication | 通信費 | survival | 100% |
| daily_goods | 日用品 | survival | 95% |

**实现代码:**

```dart
// lib/features/dual_ledger/domain/classifiers/rule_based_classifier.dart

class RuleBasedClassifier {
  /// 规则引擎映射表
  static const Map<String, LedgerTypeRule> categoryRules = {
    // 生存必需（9个）
    'food_groceries': LedgerTypeRule(LedgerType.survival, 1.0),
    'housing_rent': LedgerTypeRule(LedgerType.survival, 1.0),
    'utilities': LedgerTypeRule(LedgerType.survival, 1.0),
    'transport_commute': LedgerTypeRule(LedgerType.survival, 1.0),
    'medical': LedgerTypeRule(LedgerType.survival, 1.0),
    'insurance': LedgerTypeRule(LedgerType.survival, 1.0),
    'communication': LedgerTypeRule(LedgerType.survival, 1.0),
    'daily_goods': LedgerTypeRule(LedgerType.survival, 0.95),
    'education': LedgerTypeRule(LedgerType.survival, 0.8),

    // 灵魂享乐（7个）
    'food_restaurant': LedgerTypeRule(LedgerType.soul, 0.95),
    'entertainment': LedgerTypeRule(LedgerType.soul, 1.0),
    'hobby': LedgerTypeRule(LedgerType.soul, 1.0),
    'shopping_fashion': LedgerTypeRule(LedgerType.soul, 0.9),
    'beauty': LedgerTypeRule(LedgerType.soul, 0.9),
    'travel': LedgerTypeRule(LedgerType.soul, 0.95),
    'education_hobby': LedgerTypeRule(LedgerType.soul, 0.85),
  };

  /// 分类为生存/灵魂账户
  ClassificationResult classify({
    required String categoryId,
    String? note,
    int? amount,
  }) {
    final rule = categoryRules[categoryId];

    if (rule == null) {
      // 未知分类,默认生存（保守策略）
      return ClassificationResult(
        ledgerType: LedgerType.survival,
        confidence: 0.5,
        source: ClassificationSource.defaultRule,
      );
    }

    return ClassificationResult(
      ledgerType: rule.type,
      confidence: rule.confidence,
      source: ClassificationSource.ruleEngine,
    );
  }
}

class LedgerTypeRule {
  final LedgerType type;
  final double confidence;  // 0.0 - 1.0

  const LedgerTypeRule(this.type, this.confidence);
}
```

**边界条件:**
- 用户创建的自定义分类默认为`survival`,需用户手动设置
- 收入类型不参与双轨分类,统一归为`income`

#### 2.1.2 Layer 2: 商家数据库（500+商家）

**功能概述:**
根据商家名称推断账户类型,用于OCR扫描或备注文本匹配。

**商家数据库示例:**

```dart
// lib/features/dual_ledger/data/merchant_database.dart

class MerchantDatabase {
  /// 日本常见商家数据库（500+商家）
  static const Map<String, MerchantInfo> merchants = {
    // 食品 - 生存
    'セブンイレブン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      tags: ['コンビニ', '食品', '日用品'],
    ),
    'ファミリーマート': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      tags: ['コンビニ'],
    ),
    'イオン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      tags: ['スーパー'],
    ),

    // 食品 - 灵魂
    '吉野家': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      tags: ['外食', '牛丼'],
    ),
    'マクドナルド': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      tags: ['外食', 'ファストフード'],
    ),
    'スターバックス': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      tags: ['カフェ'],
    ),

    // 交通 - 生存
    'JR東日本': MerchantInfo(
      category: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      tags: ['電車', '通勤'],
    ),
    '東京メトロ': MerchantInfo(
      category: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      tags: ['地下鉄', '通勤'],
    ),

    // 购物 - 灵魂
    'ヨドバシカメラ': MerchantInfo(
      category: 'shopping_electronics',
      ledgerType: LedgerType.soul,
      confidence: 0.8,  // 可能买必需品或娱乐品
      tags: ['家電', 'カメラ'],
    ),
    'ユニクロ': MerchantInfo(
      category: 'shopping_fashion',
      ledgerType: LedgerType.soul,
      confidence: 0.85,
      tags: ['ファッション'],
    ),
    '無印良品': MerchantInfo(
      category: 'shopping_general',
      ledgerType: LedgerType.soul,
      confidence: 0.8,
      tags: ['雑貨'],
    ),

    // 娱乐 - 灵魂
    'TOHO': MerchantInfo(
      category: 'entertainment',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      tags: ['映画'],
    ),
    'ラウンドワン': MerchantInfo(
      category: 'entertainment',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      tags: ['ゲーム', 'ボウリング'],
    ),

    // 医疗 - 生存
    'マツモトキヨシ': MerchantInfo(
      category: 'medical',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      tags: ['薬局'],
    ),

    // 爱好 - 灵魂
    'ヨドバシ': MerchantInfo(
      category: 'hobby',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      tags: ['ホビー', '模型'],
    ),
  };

  /// 根据商家名称查找
  MerchantInfo? findMerchant(String merchantName) {
    // 精确匹配
    if (merchants.containsKey(merchantName)) {
      return merchants[merchantName];
    }

    // 模糊匹配（包含关系）
    for (final entry in merchants.entries) {
      if (merchantName.contains(entry.key) || entry.key.contains(merchantName)) {
        return entry.value;
      }
    }

    return null;
  }

  /// 从备注文本中提取商家名称
  String? extractMerchantFromNote(String note) {
    // 正则提取 "@ 商家名" 或 "商家名で"
    final patterns = [
      RegExp(r'@\s*([^\s]+)'),  // "@ 吉野家"
      RegExp(r'([^\s]+)で'),    // "吉野家で"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(note);
      if (match != null && match.groupCount > 0) {
        return match.group(1);
      }
    }

    return null;
  }
}

class MerchantInfo {
  final String category;
  final LedgerType ledgerType;
  final double confidence;
  final List<String> tags;

  const MerchantInfo({
    required this.category,
    required this.ledgerType,
    required this.confidence,
    required this.tags,
  });
}
```

**数据维护策略:**
- MVP版本:500个日本常见商家（手工维护）
- V1.0:通过OTA热更新JSON文件扩展至2000+商家
- V2.0:社区贡献机制,用户提交新商家

#### 2.1.3 Layer 3: TensorFlow Lite模型（学习用户习惯）

**注意:** 根据可行性研究,**不使用Gemini Nano**（配额限制、仅前台、设备兼容性问题）,改用TensorFlow Lite本地模型。

**模型架构:**

```dart
// lib/features/dual_ledger/domain/classifiers/tflite_classifier.dart

class TFLiteClassifier {
  late Interpreter _interpreter;

  Future<void> initialize() async {
    // 加载模型文件（200KB轻量级模型）
    _interpreter = await Interpreter.fromAsset('assets/models/ledger_classifier.tflite');
  }

  Future<ClassificationResult> predict({
    required String merchant,
    required String note,
    required int amount,
    required DateTime timestamp,
  }) async {
    // 构建输入特征向量（191维）
    final input = _buildInputTensor(merchant, note, amount, timestamp);

    // 运行推理
    final output = List.filled(2, 0.0).reshape([1, 2]);
    _interpreter.run(input, output);

    // 解析输出：[survival_prob, soul_prob]
    final survivalProb = output[0][0];
    final soulProb = output[0][1];

    return ClassificationResult(
      ledgerType: soulProb > survivalProb ? LedgerType.soul : LedgerType.survival,
      confidence: math.max(survivalProb, soulProb),
      source: ClassificationSource.mlModel,
    );
  }

  List<List<double>> _buildInputTensor(
    String merchant,
    String note,
    int amount,
    DateTime timestamp,
  ) {
    final features = <double>[];

    // 1. 商家嵌入（100维）
    features.addAll(_merchantEmbedding(merchant));

    // 2. 备注关键词嵌入（50维）
    features.addAll(_noteKeywordEmbedding(note));

    // 3. 金额分桶（10维 - one-hot编码）
    features.addAll(_amountBucket(amount));

    // 4. 时间特征（31维）
    features.addAll(_timeFeatures(timestamp));

    return [features];
  }

  List<double> _merchantEmbedding(String merchant) {
    // 使用预训练的Word2Vec嵌入（简化版本）
    // 实际生产中应使用真实的嵌入向量
    final hash = merchant.hashCode.abs() % 100;
    final embedding = List.filled(100, 0.0);
    embedding[hash] = 1.0;
    return embedding;
  }

  List<double> _noteKeywordEmbedding(String note) {
    // 关键词检测
    final soulKeywords = ['旅行', '趣味', '外食', 'ゲーム', '映画', 'カフェ'];
    final survivalKeywords = ['スーパー', '通勤', '家賃', '電気', 'ガス', '薬'];

    final embedding = List.filled(50, 0.0);
    for (var i = 0; i < soulKeywords.length; i++) {
      if (note.contains(soulKeywords[i])) {
        embedding[i] = 1.0;
      }
    }
    for (var i = 0; i < survivalKeywords.length; i++) {
      if (note.contains(survivalKeywords[i])) {
        embedding[25 + i] = 1.0;
      }
    }
    return embedding;
  }

  List<double> _amountBucket(int amount) {
    // 金额分桶：0-500, 500-1000, 1000-2000, ..., >10000
    final buckets = [0, 500, 1000, 2000, 3000, 5000, 7000, 10000, 20000, 50000];
    final embedding = List.filled(10, 0.0);

    for (var i = 0; i < buckets.length; i++) {
      if (amount >= buckets[i]) {
        embedding[i] = 1.0;
      } else {
        break;
      }
    }
    return embedding;
  }

  List<double> _timeFeatures(DateTime timestamp) {
    final features = <double>[];

    // 时间（0-23）- one-hot编码
    final hourEmbedding = List.filled(24, 0.0);
    hourEmbedding[timestamp.hour] = 1.0;
    features.addAll(hourEmbedding);

    // 星期（0-6）- one-hot编码
    final dowEmbedding = List.filled(7, 0.0);
    dowEmbedding[timestamp.weekday - 1] = 1.0;
    features.addAll(dowEmbedding);

    return features;
  }

  void dispose() {
    _interpreter.close();
  }
}
```

**模型训练流程（V1.0）:**
1. 收集用户手动修正的交易数据（标注数据）
2. 每周离线训练新模型
3. 通过OTA推送更新的`.tflite`文件
4. 个性化:每个用户可选择训练个人模型（本地训练）

**性能指标:**
- 推理时间: <50ms（移动设备）
- 模型大小: <500KB
- 准确率目标: >85%

#### 2.1.4 分类决策流程

```
新交易创建
    ↓
Layer 1: 规则引擎
    ├─ 分类ID在规则表中? ──Yes──► 使用规则结果（置信度100%）
    └─ No
        ↓
Layer 2: 商家数据库
    ├─ 备注包含商家名? ──Yes──► 查找商家数据库
    │                              ├─ 找到? ──Yes──► 使用商家结果（置信度80-95%）
    │                              └─ No ↓
    └─ No ↓
        ↓
Layer 3: TensorFlow Lite模型
    └─ 运行ML推理 ──► 使用模型结果（置信度50-90%）
        ↓
    如果置信度<70% ──► 提示用户手动确认
        ↓
    保存最终分类结果
```

**Dart实现:**

```dart
// lib/features/dual_ledger/domain/use_cases/classify_transaction.dart

class ClassifyTransactionUseCase {
  final RuleBasedClassifier _ruleClassifier;
  final MerchantDatabase _merchantDB;
  final TFLiteClassifier _mlClassifier;

  Future<ClassificationResult> execute(Transaction tx) async {
    // Layer 1: 规则引擎
    final ruleResult = _ruleClassifier.classify(
      categoryId: tx.categoryId,
      note: tx.note,
      amount: tx.amount,
    );

    if (ruleResult.confidence >= 0.95) {
      return ruleResult;
    }

    // Layer 2: 商家数据库
    if (tx.note != null) {
      final merchantName = _merchantDB.extractMerchantFromNote(tx.note!);
      if (merchantName != null) {
        final merchantInfo = _merchantDB.findMerchant(merchantName);
        if (merchantInfo != null && merchantInfo.confidence >= 0.8) {
          return ClassificationResult(
            ledgerType: merchantInfo.ledgerType,
            confidence: merchantInfo.confidence,
            source: ClassificationSource.merchantDB,
          );
        }
      }
    }

    // Layer 3: TF Lite模型
    final mlResult = await _mlClassifier.predict(
      merchant: tx.note ?? '',
      note: tx.note ?? '',
      amount: tx.amount,
      timestamp: tx.timestamp,
    );

    // 如果置信度低,标记需要手动确认
    if (mlResult.confidence < 0.7) {
      return mlResult.copyWith(needsConfirmation: true);
    }

    return mlResult;
  }
}

class ClassificationResult {
  final LedgerType ledgerType;
  final double confidence;
  final ClassificationSource source;
  final bool needsConfirmation;

  ClassificationResult({
    required this.ledgerType,
    required this.confidence,
    required this.source,
    this.needsConfirmation = false,
  });

  ClassificationResult copyWith({
    LedgerType? ledgerType,
    double? confidence,
    ClassificationSource? source,
    bool? needsConfirmation,
  }) {
    return ClassificationResult(
      ledgerType: ledgerType ?? this.ledgerType,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
    );
  }
}

enum ClassificationSource {
  ruleEngine,
  merchantDB,
  mlModel,
  defaultRule,
  userOverride,
}
```

---

### 2.2 灵魂账户配置

#### 2.2.1 灵魂账户个性化

**功能概述:**
用户可以自定义灵魂账户的名称、图标、颜色,赋予其个性化意义。

**UI设计（和风模式）:**

```
┌─────────────────────────────────────┐
│ ← 灵魂账户设置                      │
├─────────────────────────────────────┤
│                                     │
│  💖 我的精神资产                    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  账户名称：                         │
│  ┌────────────────────────────┐    │
│  │ 高达基金                    │    │  ← 可编辑（最多20字符）
│  └────────────────────────────┘    │
│                                     │
│  选择图标：                         │
│  ┌────────────────────────────┐    │
│  │ 🤖 ✨ 🎨 🎮 💅 ✈️ 📚       │    │  ← 图标选择器
│  │ 🍜 🎬 🎸 ⚽ 🏃 🧘 📸       │    │
│  └────────────────────────────┘    │
│                                     │
│  选择颜色：                         │
│  ┌────────────────────────────┐    │
│  │ 🔴 🟠 🟡 🟢 🔵 🟣 🟤       │    │  ← 颜色选择器
│  └────────────────────────────┘    │
│                                     │
│  月度预算：                         │
│  ┌────────────────────────────┐    │
│  │ ¥30,000                     │    │  ← 可选设置
│  └────────────────────────────┘    │
│                                     │
│  预算提醒：                         │
│  ┌────────────────────────────┐    │
│  │ ☑ 达到80%时提醒              │    │
│  │ ☐ 达到100%时警告             │    │
│  └────────────────────────────┘    │
│                                     │
│  [保存设置]                         │
└─────────────────────────────────────┘
```

**数据模型:**

```dart
// lib/features/dual_ledger/data/models/soul_account_config.dart

@DataClassName('SoulAccountConfigData')
class SoulAccountConfig extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();

  // 个性化设置
  TextColumn get soulName => text().nullable()();  // "高达基金", "美妆基金"
  TextColumn get iconEmoji => text().nullable()();  // "🤖", "💅"
  TextColumn get colorHex => text().nullable()();   // "#FF8C42"

  // 预算设置
  IntColumn get monthlyBudget => integer().nullable()();  // 30000日元
  BoolColumn get alertAt80Percent => boolean().withDefault(const Constant(true))();
  BoolColumn get alertAt100Percent => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {bookId, deviceId},
  ];
}
```

**实现代码:**

```dart
// lib/features/dual_ledger/presentation/soul_config_screen.dart

class SoulConfigScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(soulAccountConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('灵魂账户设置'),
        actions: [
          TextButton(
            onPressed: () => _saveConfig(ref),
            child: Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildHeader(config),
          SizedBox(height: 32),
          _buildNameInput(ref),
          SizedBox(height: 24),
          _buildIconPicker(ref),
          SizedBox(height: 24),
          _buildColorPicker(ref),
          SizedBox(height: 24),
          _buildBudgetInput(ref),
          SizedBox(height: 24),
          _buildAlertSettings(ref),
        ],
      ),
    );
  }

  Widget _buildHeader(SoulAccountConfig config) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse('0xFF${config.colorHex ?? 'FF8C42'}')),
            Color(int.parse('0xFF${config.colorHex ?? 'FF8C42'}'))
                .withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            config.iconEmoji ?? '💖',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.soulName ?? '我的精神资产',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (config.monthlyBudget != null)
                  Text(
                    '月度预算 ¥${_formatAmount(config.monthlyBudget!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPicker(WidgetRef ref) {
    final icons = [
      '🤖', '✨', '🎨', '🎮', '💅', '✈️', '📚',
      '🍜', '🎬', '🎸', '⚽', '🏃', '🧘', '📸',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择图标', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: icons.map((icon) {
            return _buildIconButton(icon, ref);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPicker(WidgetRef ref) {
    final colors = [
      '#F44336', '#FF9800', '#FFEB3B', '#4CAF50',
      '#2196F3', '#9C27B0', '#795548', '#607D8B',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((colorHex) {
            return _buildColorButton(colorHex, ref);
          }).toList(),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return formatter.format(amount);
  }
}
```

**预设模板:**

```dart
// 预设灵魂账户模板
const soulAccountTemplates = [
  SoulAccountTemplate(
    name: '高达基金',
    icon: '🤖',
    color: '#FF8C42',
    suggestedBudget: 30000,
  ),
  SoulAccountTemplate(
    name: '美妆基金',
    icon: '💅',
    color: '#E91E63',
    suggestedBudget: 20000,
  ),
  SoulAccountTemplate(
    name: '旅行基金',
    icon: '✈️',
    color: '#00BCD4',
    suggestedBudget: 50000,
  ),
  SoulAccountTemplate(
    name: '学习成长',
    icon: '📚',
    color: '#3F51B5',
    suggestedBudget: 15000,
  ),
  SoulAccountTemplate(
    name: '游戏娱乐',
    icon: '🎮',
    color: '#9C27B0',
    suggestedBudget: 25000,
  ),
];
```

---

### 2.3 灵魂消费庆祝动画（C04）

#### 2.3.1 触发条件

```dart
// lib/features/dual_ledger/domain/use_cases/trigger_celebration.dart

class TriggerCelebrationUseCase {
  Future<bool> shouldCelebrate(Transaction tx) async {
    // 条件1: 交易类型为支出
    if (tx.type != TransactionType.expense) {
      return false;
    }

    // 条件2: 账户类型为灵魂
    if (tx.ledgerType != LedgerType.soul) {
      return false;
    }

    // 条件3: 用户未关闭庆祝动画
    final settings = await _settingsRepo.getSettings();
    if (!settings.enableCelebration) {
      return false;
    }

    // 条件4: 不要在修正交易时庆祝
    if (tx.type == TransactionType.correction) {
      return false;
    }

    return true;
  }
}
```

#### 2.3.2 动画效果

**技术实现（使用Lottie）:**

```dart
// lib/features/dual_ledger/presentation/widgets/soul_celebration_animation.dart

class SoulCelebrationAnimation extends StatefulWidget {
  final int amount;
  final VoidCallback onComplete;

  const SoulCelebrationAnimation({
    required this.amount,
    required this.onComplete,
  });

  @override
  State<SoulCelebrationAnimation> createState() => _SoulCelebrationAnimationState();
}

class _SoulCelebrationAnimationState extends State<SoulCelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _message;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _message = _selectMessage();
    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), widget.onComplete);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete,  // 点击跳过
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Stack(
          children: [
            // 粒子爆发效果
            Center(
              child: Lottie.asset(
                'assets/animations/particle_burst.json',
                controller: _controller,
                width: 300,
                height: 300,
              ),
            ),

            // 彩虹光晕
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 200 * _controller.value,
                    height: 200 * _controller.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pink.withOpacity(0.5 * (1 - _controller.value)),
                          Colors.purple.withOpacity(0.3 * (1 - _controller.value)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 正向文案
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(0.3, 0.6, curve: Curves.easeIn),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.pink,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '¥${_formatAmount(widget.amount)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 跳过提示
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'タップしてスキップ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _selectMessage() {
    final messages = [
      '精神资产 +1 💖',
      '快乐值充能中 ⚡',
      '灵魂满足度 UP ✨',
      '这是对自己的投资！🎉',
      '生活需要一些小确幸 🌟',
      '今日の自分へのご褒美 ✨',
      '心を満たす時間 💫',
      'ソウル充電中 ⚡',
    ];

    return messages[Random().nextInt(messages.length)];
  }

  String _formatAmount(int amount) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return formatter.format(amount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Lottie动画文件（particle_burst.json）:**
- 使用LottieFiles社区动画,或自定义创建
- 推荐动画: "Confetti", "Stars Burst", "Heart Particles"
- 文件大小: <100KB
- 帧率: 30fps
- 时长: 2秒

#### 2.3.3 文案库（OTA热更新）

```json
{
  "version": "1.0.0",
  "celebration_messages": [
    {
      "id": "msg_001",
      "text_ja": "精神資産 +1 💖",
      "text_cn": "精神资产 +1 💖",
      "weight": 1.0
    },
    {
      "id": "msg_002",
      "text_ja": "ハッピー充電中 ⚡",
      "text_cn": "快乐值充能中 ⚡",
      "weight": 1.0
    },
    {
      "id": "msg_003",
      "text_ja": "魂の満足度 UP ✨",
      "text_cn": "灵魂满足度 UP ✨",
      "weight": 1.0
    },
    {
      "id": "msg_004",
      "text_ja": "これは自分への投資！🎉",
      "text_cn": "这是对自己的投资！🎉",
      "weight": 0.8
    },
    {
      "id": "msg_005",
      "text_ja": "人生には小確幸が必要 🌟",
      "text_cn": "生活需要一些小确幸 🌟",
      "weight": 0.8
    },
    {
      "id": "msg_006",
      "text_ja": "今日の自分へのご褒美 ✨",
      "text_cn": "今日的自我奖励 ✨",
      "weight": 1.0
    },
    {
      "id": "msg_007",
      "text_ja": "心を満たす時間 💫",
      "text_cn": "充盈内心的时刻 💫",
      "weight": 0.9
    },
    {
      "id": "msg_008",
      "text_ja": "ソウル充電完了 ⚡",
      "text_cn": "灵魂充电完成 ⚡",
      "weight": 1.0
    }
  ]
}
```

---

### 2.4 UI差异化设计

#### 2.4.1 生存账户视觉设计（和风治愈）

**设计规范:**

| 元素 | 规范 |
|------|------|
| 主色调 | 冷静蓝 #4A90D9 |
| 次色调 | 灰蓝 #607D8B |
| 图标 | 🏠（房屋）|
| 字体 | Noto Sans JP Regular |
| 卡片背景 | #F5F5F5（浅灰）|
| 边框 | 1px solid #E0E0E0 |
| 圆角 | 12px |

**进度条样式:**

```dart
// 红绿灯预警式进度条
class SurvivalProgressBar extends StatelessWidget {
  final int spent;  // 已花费
  final int budget; // 预算

  Color _getColor() {
    final ratio = spent / budget;
    if (ratio < 0.7) return Colors.green;      // 安全
    if (ratio < 0.9) return Colors.orange;     // 警告
    return Colors.red;                         // 超支
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (spent / budget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('生存成本', style: TextStyle(fontSize: 16, color: Color(0xFF4A90D9))),
            Text(
              '¥${_formatAmount(spent)} / ¥${_formatAmount(budget)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(_getColor()),
          minHeight: 8,
        ),
        if (spent > budget)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.warning, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  '⚠️ 本月超支 ¥${_formatAmount(spent - budget)}',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

**月报标题:**
- 日文: "生存コスト報告"
- 中文: "生存成本报告"

#### 2.4.2 灵魂账户视觉设计（赛博可爱）

**设计规范:**

| 元素 | 规范 |
|------|------|
| 主色调 | 活力橙 #FF8C42 |
| 次色调 | 粉紫 #E91E63 |
| 图标 | 💖（心形）|
| 字体 | Noto Sans JP Medium |
| 卡片背景 | 渐变（#FF8C42 → #FF6F61）|
| 边框 | 无 |
| 圆角 | 16px |

**进度条样式:**

```dart
// 快乐值充能条
class SoulProgressBar extends StatelessWidget {
  final int spent;  // 已花费
  final int budget; // 预算

  @override
  Widget build(BuildContext context) {
    final ratio = (spent / budget).clamp(0.0, 1.2);  // 允许超过100%显示

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFF6F61)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('💖', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    '灵魂账户',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '¥${_formatAmount(spent)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Stack(
            children: [
              // 背景条
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // 充能条（带闪烁效果）
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow,
                        Colors.pink,
                        Colors.purple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (spent > budget)
            Text(
              '✨ 灵魂太过充实了呢～',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              '残り ¥${_formatAmount(budget - spent)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}
```

**月报标题:**
- 日文: "ソウル輝き報告"
- 中文: "灵魂闪耀报告"

#### 2.4.3 首页双轨卡片布局

```
┌─────────────────────────────────────┐
│  Happy Pocket            ☰          │
├─────────────────────────────────────┤
│                                     │
│  今月の支出                          │
│  ¥185,400                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ┌──────────────────────────┐      │
│  │ 🏠 生存账户               │      │  ← 和风卡片
│  │ ¥155,400 / ¥180,000      │      │
│  │ ████████░░ 86%           │      │
│  │                          │      │
│  │ 食費      ¥45,000        │      │
│  │ 住宅      ¥80,000        │      │
│  │ 交通費    ¥15,000        │      │
│  └──────────────────────────┘      │
│                                     │
│  ┌──────────────────────────┐      │
│  │ 💖 高达基金               │      │  ← 赛博卡片（渐变背景）
│  │ ¥30,000 / ¥30,000        │      │
│  │ ████████████ 100%        │      │
│  │                          │      │
│  │ 趣味      ¥21,100        │      │
│  │ 外食      ¥8,900         │      │
│  │ [查看明细 →]              │      │
│  └──────────────────────────┘      │
│                                     │
│  [➕ 新增记录]                       │
└─────────────────────────────────────┘
```

---

### 2.5 家庭模式下的隐私设计

#### 2.5.1 伴侣视图限制

**规则:**
- 伴侣可以看到:灵魂账户的预算进度（已花费/预算）
- 伴侣不能看到:灵魂账户的具体交易明细
- 目的:避免"买了什么"引发争执,只关注"花了多少"

**UI实现:**

```dart
// lib/features/dual_ledger/presentation/widgets/soul_account_partner_view.dart

class SoulAccountPartnerView extends ConsumerWidget {
  final String partnerDeviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soulSummary = ref.watch(partnerSoulSummaryProvider(partnerDeviceId));

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFF6F61)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                soulSummary.iconEmoji ?? '💖',
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${soulSummary.ownerName}の${soulSummary.soulName ?? '灵魂账户'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '今月の支出',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 进度条（不显示具体金额,只显示百分比）
          LinearProgressIndicator(
            value: soulSummary.progressRatio,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(Colors.yellow),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(soulSummary.progressRatio * 100).toInt()}% 使用済み',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              // 🔒 不显示具体金额
              Icon(Icons.lock, size: 16, color: Colors.white70),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '💡 详细信息受隐私保护',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
```

**数据查询（隐私过滤）:**

```dart
// lib/features/dual_ledger/domain/use_cases/get_partner_soul_summary.dart

class GetPartnerSoulSummaryUseCase {
  Future<SoulSummary> execute(String partnerDeviceId) async {
    final config = await _configRepo.getByDeviceId(partnerDeviceId);

    // 只返回汇总数据,不返回交易明细
    final totalSpent = await _transactionRepo.sumByLedgerType(
      deviceId: partnerDeviceId,
      ledgerType: LedgerType.soul,
      month: DateTime.now().month,
      year: DateTime.now().year,
    );

    return SoulSummary(
      ownerName: config.ownerName,
      soulName: config.soulName,
      iconEmoji: config.iconEmoji,
      monthlyBudget: config.monthlyBudget,
      totalSpent: totalSpent,  // 只有总额
      transactions: [],        // 明细为空！
      progressRatio: config.monthlyBudget > 0
          ? (totalSpent / config.monthlyBudget).clamp(0.0, 1.0)
          : 0.0,
    );
  }
}
```

---

## 3. 数据模型设计

### 3.1 Drift表定义

```dart
// lib/core/database/tables.dart

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get type => text()();  // 'expense' | 'income' | 'transfer'
  TextColumn get categoryId => text()();

  // 双轨账本字段
  TextColumn get ledgerType => text()();  // 'survival' | 'soul'
  RealColumn get classificationConfidence => real().nullable()();  // 分类置信度
  TextColumn get classificationSource => text().nullable()();  // 'rule' | 'merchant' | 'ml' | 'user'

  IntColumn get timestamp => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();
  IntColumn get createdAt => integer()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SoulAccountConfigData')
class SoulAccountConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();
  TextColumn get soulName => text().nullable()();
  TextColumn get iconEmoji => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get monthlyBudget => integer().nullable()();
  BoolColumn get alertAt80Percent => boolean().withDefault(const Constant(true))();
  BoolColumn get alertAt100Percent => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 分类规则覆盖表（用户手动修改的规则）
@DataClassName('CategoryLedgerOverrideData')
class CategoryLedgerOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get categoryId => text()();
  TextColumn get ledgerType => text()();  // 用户覆盖的账户类型
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3.2 实体关系图（ERD）

```
┌─────────────────────┐
│   Transactions      │
├─────────────────────┤
│ id (PK)             │
│ bookId              │──┐
│ categoryId          │  │
│ ledgerType          │  │  关联
│ classification...   │  │
└─────────────────────┘  │
                         │
                         ↓
              ┌──────────────────────┐
              │   Categories         │
              ├──────────────────────┤
              │ id (PK)              │
              │ bookId               │
              │ ledgerType           │  ← 默认规则
              └──────────────────────┘
                         │
                         │  可被覆盖
                         ↓
              ┌──────────────────────┐
              │ CategoryLedger...    │
              ├──────────────────────┤
              │ categoryId (FK)      │
              │ ledgerType           │  ← 用户覆盖
              └──────────────────────┘

┌─────────────────────┐
│ SoulAccountConfigs  │
├─────────────────────┤
│ id (PK)             │
│ bookId              │
│ deviceId            │  ← 每个设备一个配置
│ soulName            │
│ iconEmoji           │
│ monthlyBudget       │
└─────────────────────┘
```

### 3.3 索引设计

```dart
// 查询优化索引
@DataClassName('TransactionData')
class Transactions extends Table {
  // ... 列定义 ...

  @override
  List<Set<Column>> get customIndexes => [
    // 按账户类型和时间查询
    {bookId, ledgerType, timestamp},

    // 按设备和账户类型查询（家庭模式）
    {bookId, deviceId, ledgerType, timestamp},

    // 月度汇总查询
    {bookId, ledgerType, timestamp},
  ];
}
```

---

## 4. UI/UX设计

### 4.1 交易录入页面（支持手动切换账户）

```
┌─────────────────────────────────────┐
│ ← 新增支出                     保存 │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │         ¥  2,110            │   │
│  │         ━━━━━━━             │   │
│  └─────────────────────────────┘   │
│                                     │
│  分类：🎮 趣味                      │
│                                     │
│  账户类型：                         │
│  ┌──────────┐  ┌──────────┐        │
│  │ 🏠 生存  │  │ 💖 灵魂  │ ←      │  自动推荐（高亮）
│  │          │  │   ✓      │        │  用户可手动切换
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ⚙️ 自动判断（置信度 95%）   │   │  显示分类依据
│  │ 来源：分类规则               │   │
│  └─────────────────────────────┘   │
│                                     │
│  备注：                             │
│  ┌────────────────────────────┐    │
│  │ HG 1/144 ザク II           │    │
│  └────────────────────────────┘    │
│                                     │
│  [📷 拍照]                          │
└─────────────────────────────────────┘
```

**交互流程:**
1. 用户输入金额和分类
2. 系统自动判断账户类型（高亮显示）
3. 显示分类依据和置信度
4. 用户可手动切换（点击另一个按钮）
5. 保存时记录`classificationSource = 'user'`

### 4.2 交易列表页面（双标签展示）

```
┌─────────────────────────────────────┐
│  Happy Pocket            ☰          │
├─────────────────────────────────────┤
│  [全部] [生存🏠] [灵魂💖] [收入💰]  │  ← 标签过滤
├─────────────────────────────────────┤
│                                     │
│  今日  2/3                 ¥3,390   │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 🍚 食費（外食）  ¥1,280  💖  │  │  ← 灵魂标记
│  │ 午餐 @ 吉野家                │  │
│  │ 14:30                         │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🎮 趣味          ¥2,110  💖  │  │
│  │ HG ザク II                   │  │
│  │ 11:20                 [照片]  │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  昨日  2/2                ¥12,580   │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 🏠 住宅          ¥80,000 🏠  │  │  ← 生存标记
│  │ 2月份房租                    │  │
│  │ 09:00                         │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🛒 食費（超市）  ¥5,800  🏠  │  │
│  │ イオン                       │  │
│  │ 18:30                         │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 4.3 月度报表页面（双轨对比）

```
┌─────────────────────────────────────┐
│ ← 2月报表                  [导出PDF]│
├─────────────────────────────────────┤
│                                     │
│  总支出：¥185,400                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 生存成本报告                 │   │
│  │ ━━━━━━━━━━━━━━━━━━━━━━━   │   │
│  │                             │   │
│  │ 总计：¥155,400              │   │
│  │ 预算：¥180,000              │   │
│  │ 剩余：¥24,600               │   │
│  │                             │   │
│  │ [饼图]                      │   │
│  │  住宅    51%  ¥80,000       │   │
│  │  食費    29%  ¥45,000       │   │
│  │  交通    10%  ¥15,000       │   │
│  │  其他    10%  ¥15,400       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💖 灵魂闪耀报告              │   │  ← 渐变背景
│  │ ━━━━━━━━━━━━━━━━━━━━━━━   │   │
│  │                             │   │
│  │ 总计：¥30,000               │   │
│  │ 预算：¥30,000               │   │
│  │ 灵魂满足度：100% ✨         │   │
│  │                             │   │
│  │ [饼图]                      │   │
│  │  趣味    70%  ¥21,100       │   │
│  │  外食    30%  ¥8,900        │   │
│  │                             │   │
│  │ 本月精神资产投资回报：      │   │
│  │ 🤖 高达模型 x3              │   │
│  │ 🍜 美食体验 x5              │   │
│  └─────────────────────────────┘   │
│                                     │
│  [查看详细分析]                     │
└─────────────────────────────────────┘
```

---

## 5. 技术实现方案

### 5.1 核心算法伪代码

```
算法: 双轨账本自动分类
输入: Transaction tx
输出: ClassificationResult

function classifyTransaction(tx):
    # Layer 1: 规则引擎
    ruleResult = RuleEngine.classify(tx.categoryId)
    if ruleResult.confidence >= 0.95:
        return ruleResult

    # Layer 2: 商家数据库
    if tx.note != null:
        merchant = extractMerchant(tx.note)
        if merchant != null:
            merchantResult = MerchantDB.lookup(merchant)
            if merchantResult.confidence >= 0.8:
                return merchantResult

    # Layer 3: TF Lite模型
    mlResult = TFLiteModel.predict(tx)

    # 低置信度需要用户确认
    if mlResult.confidence < 0.7:
        mlResult.needsConfirmation = true

    return mlResult

function extractMerchant(note):
    patterns = ["@ (\w+)", "(\w+)で"]
    for pattern in patterns:
        match = regex.search(pattern, note)
        if match:
            return match.group(1)
    return null
```

### 5.2 状态管理（Riverpod）

```dart
// lib/features/dual_ledger/presentation/providers/dual_ledger_providers.dart

// 灵魂账户配置
final soulAccountConfigProvider = StreamProvider.autoDispose<SoulAccountConfig>((ref) {
  final bookId = ref.watch(currentBookIdProvider);
  final deviceId = ref.watch(currentDeviceIdProvider);

  return ref.read(soulAccountConfigRepositoryProvider)
      .watchConfig(bookId: bookId, deviceId: deviceId);
});

// 生存账户月度汇总
final survivalMonthlySummaryProvider = FutureProvider.autoDispose<MonthlySummary>((ref) async {
  final bookId = ref.watch(currentBookIdProvider);
  final now = DateTime.now();

  return ref.read(dualLedgerServiceProvider).getMonthlySummary(
    bookId: bookId,
    ledgerType: LedgerType.survival,
    year: now.year,
    month: now.month,
  );
});

// 灵魂账户月度汇总
final soulMonthlySummaryProvider = FutureProvider.autoDispose<MonthlySummary>((ref) async {
  final bookId = ref.watch(currentBookIdProvider);
  final now = DateTime.now();

  return ref.read(dualLedgerServiceProvider).getMonthlySummary(
    bookId: bookId,
    ledgerType: LedgerType.soul,
    year: now.year,
    month: now.month,
  );
});

// 分类器
final classifierProvider = Provider<TransactionClassifier>((ref) {
  return TransactionClassifier(
    ruleClassifier: ref.read(ruleBasedClassifierProvider),
    merchantDB: ref.read(merchantDatabaseProvider),
    mlClassifier: ref.read(tfliteClassifierProvider),
  );
});
```

### 5.3 第三方库依赖

```yaml
# pubspec.yaml

dependencies:
  # TensorFlow Lite
  tflite_flutter: ^0.10.4

  # 动画
  lottie: ^3.1.0

  # 数字格式化
  intl: ^0.19.0

  # 状态管理
  flutter_riverpod: ^2.5.1

  # 数据库
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.20

  # 加密
  cryptography: ^2.7.0
```

---

## 6. 验收标准

### 6.1 功能完整性

- ✅ 所有交易自动分类为生存或灵魂账户
- ✅ 规则引擎覆盖20个预设分类,准确率100%
- ✅ 商家数据库包含至少500个日本商家
- ✅ TF Lite模型准确率 >85%（在测试集上）
- ✅ 用户可手动修改自动分类结果
- ✅ 灵魂消费播放2秒庆祝动画（可跳过）
- ✅ 用户可自定义灵魂账户名称、图标、颜色
- ✅ 家庭模式下,伴侣只能看到灵魂预算进度,不能看到明细

### 6.2 性能指标

| 指标 | 目标 | 测试方法 |
|------|------|---------|
| 自动分类时间 | <100ms | 单笔交易,从保存到分类完成 |
| TF Lite推理时间 | <50ms | 运行100次取平均值 |
| 庆祝动画流畅度 | 60fps | 使用Flutter DevTools性能监控 |
| 月报生成时间 | <2s | 1000笔交易,生成报表 |
| 商家查找时间 | <10ms | 从500+商家中查找 |

### 6.3 用户体验指标

- ✅ 自动分类准确率 >90%（用户手动修改率<10%）
- ✅ 庆祝动画好评率 >80%（A/B测试）
- ✅ 灵魂账户设置完成率 >70%
- ✅ 月报查看率 >50%

---

## 7. 测试用例

### 7.1 单元测试

```dart
// test/features/dual_ledger/domain/classifiers/rule_based_classifier_test.dart

void main() {
  group('RuleBasedClassifier', () {
    late RuleBasedClassifier classifier;

    setUp(() {
      classifier = RuleBasedClassifier();
    });

    test('should classify food_groceries as survival', () {
      // Given
      final categoryId = 'food_groceries';

      // When
      final result = classifier.classify(categoryId: categoryId);

      // Then
      expect(result.ledgerType, LedgerType.survival);
      expect(result.confidence, 1.0);
      expect(result.source, ClassificationSource.ruleEngine);
    });

    test('should classify hobby as soul', () {
      // Given
      final categoryId = 'hobby';

      // When
      final result = classifier.classify(categoryId: categoryId);

      // Then
      expect(result.ledgerType, LedgerType.soul);
      expect(result.confidence, 1.0);
      expect(result.source, ClassificationSource.ruleEngine);
    });

    test('should return default survival for unknown category', () {
      // Given
      final categoryId = 'unknown_category';

      // When
      final result = classifier.classify(categoryId: categoryId);

      // Then
      expect(result.ledgerType, LedgerType.survival);
      expect(result.confidence, 0.5);
      expect(result.source, ClassificationSource.defaultRule);
    });

    test('should classify food_restaurant as soul with high confidence', () {
      // Given
      final categoryId = 'food_restaurant';

      // When
      final result = classifier.classify(categoryId: categoryId);

      // Then
      expect(result.ledgerType, LedgerType.soul);
      expect(result.confidence, 0.95);
    });

    test('should classify medical as survival', () {
      // Given
      final categoryId = 'medical';

      // When
      final result = classifier.classify(categoryId: categoryId);

      // Then
      expect(result.ledgerType, LedgerType.survival);
      expect(result.confidence, 1.0);
    });
  });

  group('MerchantDatabase', () {
    late MerchantDatabase db;

    setUp(() {
      db = MerchantDatabase();
    });

    test('should find merchant by exact name', () {
      // Given
      final merchantName = '吉野家';

      // When
      final result = db.findMerchant(merchantName);

      // Then
      expect(result, isNotNull);
      expect(result!.ledgerType, LedgerType.soul);
      expect(result.category, 'food_restaurant');
      expect(result.confidence, 0.95);
    });

    test('should extract merchant from note with @ pattern', () {
      // Given
      final note = '午餐 @ 吉野家';

      // When
      final merchant = db.extractMerchantFromNote(note);

      // Then
      expect(merchant, '吉野家');
    });

    test('should extract merchant from note with で pattern', () {
      // Given
      final note = '吉野家で牛丼を食べた';

      // When
      final merchant = db.extractMerchantFromNote(note);

      // Then
      expect(merchant, '吉野家');
    });

    test('should return null if no merchant pattern found', () {
      // Given
      final note = '普通の備考';

      // When
      final merchant = db.extractMerchantFromNote(note);

      // Then
      expect(merchant, isNull);
    });
  });
}
```

### 7.2 Widget测试

```dart
// test/features/dual_ledger/presentation/widgets/soul_celebration_animation_test.dart

void main() {
  testWidgets('should display celebration animation', (tester) async {
    // Given
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoulCelebrationAnimation(
            amount: 2110,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    // When - animation starts
    await tester.pump();

    // Then - should show message
    expect(find.textContaining('精神资产'), findsOneWidget);
    expect(find.text('¥2,110'), findsOneWidget);

    // When - tap to skip
    await tester.tap(find.byType(SoulCelebrationAnimation));
    await tester.pumpAndSettle();

    // Then - should complete
    expect(completed, isTrue);
  });

  testWidgets('should auto-complete after 2 seconds', (tester) async {
    // Given
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoulCelebrationAnimation(
            amount: 1280,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    // When - wait for animation to complete
    await tester.pump(Duration(seconds: 2));
    await tester.pump(Duration(milliseconds: 500));

    // Then - should auto-complete
    expect(completed, isTrue);
  });
}

// test/features/dual_ledger/presentation/widgets/soul_progress_bar_test.dart

void main() {
  testWidgets('should display soul progress bar correctly', (tester) async {
    // Given
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoulProgressBar(
            spent: 15000,
            budget: 30000,
          ),
        ),
      ),
    );

    // Then
    expect(find.text('💖'), findsOneWidget);
    expect(find.text('灵魂账户'), findsOneWidget);
    expect(find.text('¥15,000'), findsOneWidget);
    expect(find.text('残り ¥15,000'), findsOneWidget);
  });

  testWidgets('should show over-budget message', (tester) async {
    // Given
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoulProgressBar(
            spent: 35000,
            budget: 30000,
          ),
        ),
      ),
    );

    // Then
    expect(find.text('✨ 灵魂太过充实了呢～'), findsOneWidget);
  });
}
```

### 7.3 集成测试

```dart
// integration_test/dual_ledger_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete dual ledger flow', (tester) async {
    // Given - launch app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // When - create a soul transaction
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Input amount
    await tester.tap(find.text('2'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    // Select hobby category
    await tester.tap(find.text('趣味'));
    await tester.pumpAndSettle();

    // Then - should auto-classify as soul
    expect(find.text('💖 灵魂'), findsOneWidget);

    // Verify soul account is highlighted
    final soulButton = find.ancestor(
      of: find.text('💖 灵魂'),
      matching: find.byType(Container),
    );
    // TODO: verify button is highlighted

    // When - save transaction
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // Then - should show celebration animation
    expect(find.textContaining('精神资产'), findsOneWidget);

    // When - skip animation
    await tester.tap(find.byType(SoulCelebrationAnimation));
    await tester.pumpAndSettle();

    // Then - should return to home with transaction listed
    expect(find.text('¥2,110'), findsOneWidget);
    expect(find.text('💖'), findsWidgets);  // Soul icon in list
  });

  testWidgets('manual classification override', (tester) async {
    // Given
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Create transaction
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    // Select groceries (auto-classified as survival)
    await tester.tap(find.text('食費（スーパー）'));
    await tester.pumpAndSettle();

    // Verify auto-classification
    expect(find.text('🏠 生存'), findsOneWidget);

    // When - manually change to soul
    await tester.tap(find.text('💖 灵魂'));
    await tester.pumpAndSettle();

    // Then - classification source should be 'user'
    // Save and verify
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // Transaction should be saved as soul type
    // (verify in database or transaction list)
  });
}
```

---

## 8. 开发里程碑

### 8.1 详细任务拆解（8天）

| Day | 任务 | 产出 | 风险 |
|-----|------|------|------|
| **Day 1** | 数据模型设计与实现 | - Drift表定义<br>- Repository实现<br>- 单元测试 | 低 |
| **Day 2** | 规则引擎实现 | - RuleBasedClassifier<br>- 20个分类规则<br>- 单元测试 | 低 |
| **Day 3** | 商家数据库实现 | - MerchantDatabase（500+商家）<br>- 商家查找算法<br>- 单元测试 | 中（数据收集工作量）|
| **Day 4** | TF Lite模型集成 | - TFLiteClassifier<br>- 模型文件（预训练）<br>- 推理测试 | 高（模型训练复杂）|
| **Day 5** | 灵魂账户配置UI | - SoulConfigScreen<br>- 个性化设置<br>- Widget测试 | 低 |
| **Day 6** | 庆祝动画实现 | - SoulCelebrationAnimation<br>- Lottie集成<br>- 动画测试 | 中（动画效果调优）|
| **Day 7** | UI差异化设计 | - 双轨进度条<br>- 月报页面<br>- 主题切换 | 中（设计细节）|
| **Day 8** | 集成测试与优化 | - 端到端测试<br>- 性能优化<br>- Bug修复 | 中 |

### 8.2 关键路径识别

```
Day 1 (数据模型)
    ↓
Day 2 (规则引擎) ──┐
                   ├──► Day 5 (配置UI)
Day 3 (商家库) ────┤
                   │
Day 4 (TF Lite) ───┘
    ↓
Day 6 (庆祝动画) ──┐
                   ├──► Day 8 (集成测试)
Day 7 (UI设计) ────┘
```

**关键路径:** Day 1 → Day 4 → Day 8
**TF Lite模型是最大风险点,可能需要延期至V1.0**

### 8.3 依赖项管理

**外部依赖:**
- TensorFlow Lite Flutter插件（可能有兼容性问题）
- Lottie动画库（需要准备动画文件）
- 商家数据收集（需要数据团队支持）

**内部依赖:**
- MOD-001 基础记账（必须完成）
- MOD-002 分类管理（必须完成）

### 8.4 风险与缓解措施

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| TF Lite模型准确率不达标 | 高 | 高 | MVP阶段降低目标至75%,V1.0优化 |
| 商家数据收集工作量大 | 中 | 中 | 先实现200个核心商家,后续OTA更新 |
| 庆祝动画影响性能 | 低 | 中 | 提供"关闭动画"选项,优化渲染 |
| 文化接受度问题 | 中 | 高 | A/B测试验证,准备降级方案 |

---

## 9. 附录

### 9.1 相关文档链接

- [PRD_Module_BasicAccounting.md](/Users/xinz/Development/ThinkCenter/claudedocs/PRD_Module_BasicAccounting.md)
- [PRD_Modules_Summary.md](/Users/xinz/Development/ThinkCenter/claudedocs/PRD_Modules_Summary.md)
- [research_home_pocket_feasibility_strategy_20260202_CN.md](/Users/xinz/Development/ThinkCenter/claudedocs/research_home_pocket_feasibility_strategy_20260202_CN.md)

### 9.2 技术参考资料

**TensorFlow Lite:**
- [TensorFlow Lite Flutter插件](https://pub.dev/packages/tflite_flutter)
- [文本分类模型训练](https://www.tensorflow.org/lite/examples/text_classification/overview)

**Lottie动画:**
- [Lottie Flutter](https://pub.dev/packages/lottie)
- [LottieFiles社区](https://lottiefiles.com/)

**商家数据:**
- [日本连锁店列表](https://ja.wikipedia.org/wiki/日本の小売業者一覧)
- [コンビニエンスストア](https://ja.wikipedia.org/wiki/コンビニエンスストア)

### 9.3 设计决策记录

**决策001: 为什么不使用Gemini Nano?**
- 日期: 2026-02-03
- 原因: 配额限制、仅前台、设备兼容性问题
- 替代方案: TensorFlow Lite本地模型
- 参考: research_home_pocket_feasibility_strategy_20260202_CN.md 第2.2节

**决策002: 为什么默认保守策略（未知分类→生存）?**
- 日期: 2026-02-03
- 原因: 避免将必需支出误判为享乐,导致预算失控
- 替代方案: 提示用户手动确认
- 影响: 可能降低灵魂消费的识别率

**决策003: 为什么家庭模式只显示灵魂账户进度?**
- 日期: 2026-02-03
- 原因: 避免"买了什么"引发伴侣争执,保护个人隐私
- 替代方案: 完全透明（被否决）
- 用户反馈: Beta测试验证

---

**文档状态:** 完成
**审核状态:** 待评审
**需要评审:** 产品经理、技术负责人、UI/UX设计师

**变更日志:**
- 2026-02-03: 初版完成（基于框架文档和可行性研究）
