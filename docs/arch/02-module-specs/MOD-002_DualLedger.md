# MOD-003: 双轨账本 - 技术设计文档

**模块编号:** MOD-003
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 8天
**优先级:** P0（MVP核心差异化功能）
**状态:** 设计完成

---

## 📋 目录

1. [模块概述](#模块概述)
2. [功能需求](#功能需求)
3. [三层分类引擎](#三层分类引擎)
4. [技术设计](#技术设计)
5. [核心流程](#核心流程)
6. [UI设计](#ui设计)
7. [测试策略](#测试策略)

---

## 模块概述

### 业务价值

双轨账本是Home Pocket的核心差异化功能，通过智能分类引擎自动将交易分类到"生存账本"或"灵魂账本"，帮助用户区分必要支出和享受型支出，培养健康的消费观。

### 核心概念

```
生存账本（Survival Ledger）
  - 必要支出：餐饮、交通、住房、医疗等
  - 目标：记录基本生活成本
  - 颜色：蓝色主题

灵魂账本（Soul Ledger）
  - 享受型支出：娱乐、兴趣、旅游、奢侈品等
  - 目标：记录生活品质投资
  - 颜色：紫色主题
  - 特殊：灵魂消费庆祝动画
```

### 核心功能

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 智能分类 | 三层引擎自动分类交易 | P0 |
| 双账本视图 | 独立展示两个账本 | P0 |
| 账本切换 | 快速切换账本视图 | P0 |
| 灵魂消费庆祝 | 灵魂账本交易触发动画 | P0 |
| 分类规则配置 | 自定义分类规则 | P1 |
| 商家数据库维护 | 更新商家分类信息 | P2 |

---

## 功能需求

### FR-001: 智能分类引擎

**用户故事**: 作为用户，我希望系统自动将我的交易分类到合适的账本，无需手动选择。

**验收标准**:
- ✅ 分类准确率 ≥ 85%
- ✅ 分类耗时 < 100ms
- ✅ 支持三层分类逻辑
- ✅ 支持用户反馈修正

**分类示例**:

| 交易 | 商家 | 分类 | 账本 |
|------|------|------|------|
| 午餐 | 麦当劳 | 餐饮 > 午餐 > 快餐 | 生存 |
| 晚餐 | 米其林餐厅 | 餐饮 > 晚餐 > 高级餐厅 | 灵魂 |
| 地铁 | 上海地铁 | 交通 > 公共交通 > 地铁 | 生存 |
| 电影 | 万达影城 | 娱乐 > 电影 | 灵魂 |
| 房租 | - | 住房 > 租金 | 生存 |
| Switch游戏 | 任天堂 | 娱乐 > 游戏 | 灵魂 |

### FR-002: 双账本视图

**用户故事**: 作为用户，我希望能够独立查看生存账本和灵魂账本的交易。

**验收标准**:
- ✅ 顶部Tab切换账本
- ✅ 显示各账本余额
- ✅ 显示各账本支出占比
- ✅ 支持月度对比
- ✅ 不同账本使用不同主题色

### FR-003: 灵魂消费庆祝

**用户故事**: 作为用户，当我进行灵魂消费时，我希望看到有趣的庆祝动画，增加记账乐趣。

**验收标准**:
- ✅ 灵魂交易创建后自动触发动画
- ✅ 支持多种动画类型（彩纸、烟花、闪光）
- ✅ 动画可配置开关
- ✅ 动画时长1-2秒

---

## 三层分类引擎

### 设计理念

为了达到≥85%的分类准确率，我们采用三层分类引擎，按优先级依次尝试：

```
Layer 1: 规则引擎（Rule Engine）
   ↓ 失败
Layer 2: 商家数据库（Merchant Database）
   ↓ 失败
Layer 3: ML分类器（TF Lite Classifier）
```

### Layer 1: 规则引擎

**原理**: 基于固定规则匹配分类。

**优先级**: 最高（准确率100%，因为是用户自定义）

**示例规则**:

```yaml
rules:
  - categoryId: cat_housing_rent
    ledgerType: survival
    reason: "住房 > 租金 → 必要支出"

  - categoryId: cat_food_breakfast
    ledgerType: survival
    reason: "餐饮 > 早餐 → 必要支出"

  - categoryId: cat_food_luxury
    ledgerType: soul
    reason: "餐饮 > 高级餐厅 → 享受型支出"

  - categoryId: cat_entertainment
    ledgerType: soul
    reason: "娱乐 → 享受型支出"

  - categoryId: cat_hobby
    ledgerType: soul
    reason: "兴趣爱好 → 享受型支出"
```

**实现**:

```dart
// lib/application/dual_ledger/rule_engine.dart

class RuleEngine {
  final Map<String, LedgerType> _categoryRules = {};

  RuleEngine() {
    _initializeDefaultRules();
  }

  void _initializeDefaultRules() {
    // 生存账本规则
    _categoryRules['cat_food_breakfast'] = LedgerType.survival;
    _categoryRules['cat_food_lunch'] = LedgerType.survival;
    _categoryRules['cat_transport_public'] = LedgerType.survival;
    _categoryRules['cat_housing_rent'] = LedgerType.survival;
    _categoryRules['cat_housing_utilities'] = LedgerType.survival;
    _categoryRules['cat_medical'] = LedgerType.survival;
    _categoryRules['cat_daily_necessities'] = LedgerType.survival;

    // 灵魂账本规则
    _categoryRules['cat_entertainment'] = LedgerType.soul;
    _categoryRules['cat_hobby'] = LedgerType.soul;
    _categoryRules['cat_sport'] = LedgerType.soul;
    _categoryRules['cat_travel'] = LedgerType.soul;
    _categoryRules['cat_luxury'] = LedgerType.soul;
    _categoryRules['cat_food_luxury'] = LedgerType.soul;
    _categoryRules['cat_food_dinner_highend'] = LedgerType.soul;
  }

  /// 分类
  LedgerType? classify(String categoryId) {
    return _categoryRules[categoryId];
  }

  /// 添加自定义规则
  void addRule(String categoryId, LedgerType ledgerType) {
    _categoryRules[categoryId] = ledgerType;
  }

  /// 移除规则
  void removeRule(String categoryId) {
    _categoryRules.remove(categoryId);
  }
}
```

### Layer 2: 商家数据库

**原理**: 通过商家名称匹配已知商家的分类。

**优先级**: 中（准确率约80%）

**商家数据库结构**:

```dart
// lib/infrastructure/ml/models/merchant.dart

@freezed
class Merchant with _$Merchant {
  const factory Merchant({
    required String name,           // 商家名称
    required List<String> aliases,  // 别名（支持模糊匹配）
    required String categoryId,     // 推荐分类
    required LedgerType ledgerType, // 账本类型
    required double confidence,     // 置信度 (0-1)
    String? logoUrl,
    Map<String, dynamic>? metadata,
  }) = _Merchant;

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);
}
```

**商家数据示例（部分）**:

```json
{
  "merchants": [
    {
      "name": "麦当劳",
      "aliases": ["麦当劳", "McDonald's", "金拱门"],
      "categoryId": "cat_food_lunch_fastfood",
      "ledgerType": "survival",
      "confidence": 0.9
    },
    {
      "name": "星巴克",
      "aliases": ["星巴克", "Starbucks"],
      "categoryId": "cat_food_coffee",
      "ledgerType": "soul",
      "confidence": 0.85
    },
    {
      "name": "海底捞",
      "aliases": ["海底捞", "海底捞火锅"],
      "categoryId": "cat_food_dinner_hotpot",
      "ledgerType": "soul",
      "confidence": 0.9
    },
    {
      "name": "Uber",
      "aliases": ["Uber", "优步"],
      "categoryId": "cat_transport_taxi",
      "ledgerType": "survival",
      "confidence": 0.95
    },
    {
      "name": "万达影城",
      "aliases": ["万达影城", "万达电影"],
      "categoryId": "cat_entertainment_movie",
      "ledgerType": "soul",
      "confidence": 0.95
    }
  ]
}
```

**实现**:

```dart
// lib/infrastructure/ml/merchant_database.dart

class MerchantDatabase {
  final Map<String, Merchant> _merchants = {};
  bool _initialized = false;

  /// 初始化（加载商家数据）
  Future<void> initialize() async {
    if (_initialized) return;

    // 从assets加载JSON
    final jsonString = await rootBundle.loadString(
      'assets/data/merchants.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final merchantList = json['merchants'] as List;

    for (final item in merchantList) {
      final merchant = Merchant.fromJson(item);
      _merchants[merchant.name.toLowerCase()] = merchant;

      // 同时索引所有别名
      for (final alias in merchant.aliases) {
        _merchants[alias.toLowerCase()] = merchant;
      }
    }

    _initialized = true;
  }

  /// 查找商家
  MerchantClassification? lookup(String merchantName) {
    if (!_initialized) {
      throw Exception('MerchantDatabase未初始化');
    }

    // 精确匹配
    final exactMatch = _merchants[merchantName.toLowerCase()];
    if (exactMatch != null) {
      return MerchantClassification(
        merchant: exactMatch,
        ledgerType: exactMatch.ledgerType,
        confidence: exactMatch.confidence,
      );
    }

    // 模糊匹配（包含匹配）
    for (final entry in _merchants.entries) {
      if (entry.key.contains(merchantName.toLowerCase()) ||
          merchantName.toLowerCase().contains(entry.key)) {
        return MerchantClassification(
          merchant: entry.value,
          ledgerType: entry.value.ledgerType,
          confidence: entry.value.confidence * 0.8,  // 降低置信度
        );
      }
    }

    return null;
  }

  /// 添加新商家
  Future<void> addMerchant(Merchant merchant) async {
    _merchants[merchant.name.toLowerCase()] = merchant;
    // TODO: 持久化到本地数据库
  }
}

/// 商家分类结果
class MerchantClassification {
  final Merchant merchant;
  final LedgerType ledgerType;
  final double confidence;

  MerchantClassification({
    required this.merchant,
    required this.ledgerType,
    required this.confidence,
  });
}
```

### Layer 3: ML分类器

**原理**: 使用TensorFlow Lite模型进行文本分类。

**优先级**: 最低（兜底方案，准确率约70%）

**模型输入**:
- 分类名称
- 商家名称
- 备注

**模型输出**:
- 概率分布：[生存账本概率, 灵魂账本概率]

**实现**:

```dart
// lib/infrastructure/ml/tflite_classifier.dart

import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteClassifier {
  Interpreter? _interpreter;
  bool _initialized = false;

  /// 初始化模型
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ledger_classifier.tflite',
      );
      _initialized = true;
    } catch (e) {
      print('TF Lite模型加载失败: $e');
    }
  }

  /// 预测
  Future<LedgerType> predict({
    required String categoryId,
    String? merchant,
    String? note,
  }) async {
    if (!_initialized || _interpreter == null) {
      // 如果模型未加载，默认返回生存账本
      return LedgerType.survival;
    }

    try {
      // 1. 构建输入文本
      final input = _buildInput(
        categoryId: categoryId,
        merchant: merchant,
        note: note,
      );

      // 2. 文本转向量（简化版，实际应使用tokenizer）
      final inputVector = _textToVector(input);

      // 3. 运行推理
      final output = List.filled(2, 0.0).reshape([1, 2]);
      _interpreter!.run([inputVector], output);

      // 4. 解析结果
      final survivalProb = output[0][0] as double;
      final soulProb = output[0][1] as double;

      return survivalProb > soulProb
          ? LedgerType.survival
          : LedgerType.soul;

    } catch (e) {
      print('ML预测失败: $e');
      return LedgerType.survival;  // 默认生存账本
    }
  }

  String _buildInput({
    required String categoryId,
    String? merchant,
    String? note,
  }) {
    final parts = <String>[
      categoryId,
      if (merchant != null) merchant,
      if (note != null) note,
    ];
    return parts.join(' ');
  }

  List<double> _textToVector(String text) {
    // TODO: 实际实现应使用tokenizer和embedding
    // 这里是简化示例
    return List.filled(128, 0.0);
  }

  void dispose() {
    _interpreter?.close();
    _initialized = false;
  }
}
```

### 分类服务整合

```dart
// lib/application/dual_ledger/classification_service.dart

class ClassificationService {
  final RuleEngine _ruleEngine;
  final MerchantDatabase _merchantDB;
  final TFLiteClassifier _tfliteClassifier;

  ClassificationService({
    required RuleEngine ruleEngine,
    required MerchantDatabase merchantDB,
    required TFLiteClassifier tfliteClassifier,
  })  : _ruleEngine = ruleEngine,
        _merchantDB = merchantDB,
        _tfliteClassifier = tfliteClassifier;

  /// 分类交易
  Future<ClassificationResult> classifyTransaction({
    required String categoryId,
    String? merchant,
    String? note,
  }) async {
    // Layer 1: 规则引擎（最高优先级）
    final ruleResult = _ruleEngine.classify(categoryId);
    if (ruleResult != null) {
      return ClassificationResult(
        ledgerType: ruleResult,
        confidence: 1.0,
        method: ClassificationMethod.rule,
        reason: '基于分类规则',
      );
    }

    // Layer 2: 商家数据库
    if (merchant != null && merchant.isNotEmpty) {
      final merchantResult = _merchantDB.lookup(merchant);
      if (merchantResult != null && merchantResult.confidence > 0.8) {
        return ClassificationResult(
          ledgerType: merchantResult.ledgerType,
          confidence: merchantResult.confidence,
          method: ClassificationMethod.merchant,
          reason: '基于商家: ${merchantResult.merchant.name}',
        );
      }
    }

    // Layer 3: ML分类器（兜底）
    final mlResult = await _tfliteClassifier.predict(
      categoryId: categoryId,
      merchant: merchant,
      note: note,
    );

    return ClassificationResult(
      ledgerType: mlResult,
      confidence: 0.7,  // ML默认置信度
      method: ClassificationMethod.ml,
      reason: '基于机器学习模型',
    );
  }

  /// 用户反馈（修正分类）
  Future<void> provideFeedback({
    required String transactionId,
    required LedgerType correctLedgerType,
  }) async {
    // TODO: 收集用户反馈，用于优化规则和模型
    // 1. 记录到feedback表
    // 2. 如果同一分类的反馈达到阈值，更新规则
  }
}

/// 分类结果
class ClassificationResult {
  final LedgerType ledgerType;
  final double confidence;
  final ClassificationMethod method;
  final String reason;

  ClassificationResult({
    required this.ledgerType,
    required this.confidence,
    required this.method,
    required this.reason,
  });
}

enum ClassificationMethod {
  rule,      // 规则引擎
  merchant,  // 商家数据库
  ml,        // 机器学习
}
```

---

## 技术设计

### Provider架构

```dart
// lib/features/dual_ledger/presentation/providers/ledger_view_provider.dart

@riverpod
class LedgerView extends _$LedgerView {
  @override
  LedgerType build() {
    return LedgerType.survival;  // 默认显示生存账本
  }

  void switchTo(LedgerType type) {
    state = type;
  }

  void toggle() {
    state = state == LedgerType.survival
        ? LedgerType.soul
        : LedgerType.survival;
  }
}

// lib/features/dual_ledger/presentation/providers/ledger_stats_provider.dart

@riverpod
Future<LedgerStats> ledgerStats(
  LedgerStatsRef ref,
  String bookId,
  int year,
  int month,
) async {
  final repo = ref.watch(transactionRepositoryProvider);

  // 获取本月交易
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);

  final transactions = await repo.getTransactions(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );

  // 统计
  final survivalTotal = transactions
      .where((t) =>
          t.ledgerType == LedgerType.survival &&
          t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  final soulTotal = transactions
      .where((t) =>
          t.ledgerType == LedgerType.soul &&
          t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  final total = survivalTotal + soulTotal;

  return LedgerStats(
    survivalTotal: survivalTotal,
    soulTotal: soulTotal,
    survivalPercent: total > 0 ? survivalTotal / total : 0,
    soulPercent: total > 0 ? soulTotal / total : 0,
    transactionCount: transactions.length,
  );
}

@freezed
class LedgerStats with _$LedgerStats {
  const factory LedgerStats({
    required int survivalTotal,
    required int soulTotal,
    required double survivalPercent,
    required double soulPercent,
    required int transactionCount,
  }) = _LedgerStats;
}
```

---

## 核心流程

### 交易创建流程（集成分类）

```dart
// lib/application/accounting/create_transaction_use_case.dart

class CreateTransactionUseCase {
  final TransactionRepository _transactionRepo;
  final ClassificationService _classificationService;  // 新增

  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    try {
      // ...验证逻辑...

      // 智能分类（三层引擎）
      final classificationResult = await _classificationService.classifyTransaction(
        categoryId: params.categoryId,
        merchant: params.merchant,
        note: params.note,
      );

      // 创建交易（使用分类结果）
      final transaction = Transaction.create(
        bookId: params.bookId,
        deviceId: deviceId,
        amount: params.amount,
        type: params.type,
        categoryId: params.categoryId,
        ledgerType: classificationResult.ledgerType,  // 智能分类结果
        timestamp: params.timestamp ?? DateTime.now(),
        note: params.note,
        merchant: params.merchant,
        prevHash: prevHash,
        metadata: {
          'classificationMethod': classificationResult.method.name,
          'classificationConfidence': classificationResult.confidence,
          'classificationReason': classificationResult.reason,
        },
      );

      await _transactionRepo.insert(transaction);

      // 如果是灵魂消费，触发庆祝
      if (transaction.ledgerType == LedgerType.soul) {
        EventBus.instance.publish(SoulTransactionCreatedEvent(transaction));
      }

      return Result.success(transaction);

    } catch (e) {
      return Result.error('创建交易失败: $e');
    }
  }
}
```

---

## UI设计

### 双账本视图切换

```dart
// lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart

class DualLedgerScreen extends ConsumerWidget {
  final String bookId;

  const DualLedgerScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLedger = ref.watch(ledgerViewProvider);
    final statsAsync = ref.watch(ledgerStatsProvider(
      bookId,
      DateTime.now().year,
      DateTime.now().month,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('双轨账本'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: statsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => const SizedBox.shrink(),
            data: (stats) => _StatsHeader(stats: stats),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab切换
          Container(
            color: _getLedgerColor(currentLedger).withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: _LedgerTab(
                    ledgerType: LedgerType.survival,
                    isSelected: currentLedger == LedgerType.survival,
                    onTap: () => ref.read(ledgerViewProvider.notifier)
                        .switchTo(LedgerType.survival),
                  ),
                ),
                Expanded(
                  child: _LedgerTab(
                    ledgerType: LedgerType.soul,
                    isSelected: currentLedger == LedgerType.soul,
                    onTap: () => ref.read(ledgerViewProvider.notifier)
                        .switchTo(LedgerType.soul),
                  ),
                ),
              ],
            ),
          ),

          // 交易列表
          Expanded(
            child: TransactionListScreen(
              bookId: bookId,
              filterLedger: currentLedger,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLedgerColor(LedgerType type) {
    return type == LedgerType.survival
        ? Colors.blue
        : Colors.purple;
  }
}

class _StatsHeader extends StatelessWidget {
  final LedgerStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: '生存账本',
              amount: stats.survivalTotal,
              percent: stats.survivalPercent,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              label: '灵魂账本',
              amount: stats.soulTotal,
              percent: stats.soulPercent,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 灵魂消费庆祝动画

```dart
// lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart

import 'package:lottie/lottie.dart';

class SoulCelebrationOverlay extends ConsumerStatefulWidget {
  const SoulCelebrationOverlay({Key? key}) : super(key: key);

  @override
  ConsumerState<SoulCelebrationOverlay> createState() =>
      _SoulCelebrationOverlayState();
}

class _SoulCelebrationOverlayState
    extends ConsumerState<SoulCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();

    // 监听灵魂消费事件
    EventBus.instance.on<SoulTransactionCreatedEvent>().listen((event) {
      _showCelebration();
    });
  }

  void _showCelebration() async {
    if (_isShowing) return;

    setState(() {
      _isShowing = true;
    });

    // 获取配置
    final config = ref.read(soulAccountConfigProvider);
    if (!config.isEnabled) {
      setState(() {
        _isShowing = false;
      });
      return;
    }

    // 延迟2秒后关闭
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isShowing) return const SizedBox.shrink();

    final config = ref.watch(soulAccountConfigProvider);

    return Positioned.fill(
      child: IgnorePointer(
        child: _getAnimationWidget(config.celebrationType),
      ),
    );
  }

  Widget _getAnimationWidget(CelebrationType type) {
    switch (type) {
      case CelebrationType.confetti:
        return Lottie.asset(
          'assets/animations/confetti.json',
          repeat: false,
        );
      case CelebrationType.fireworks:
        return Lottie.asset(
          'assets/animations/fireworks.json',
          repeat: false,
        );
      case CelebrationType.sparkle:
        return Lottie.asset(
          'assets/animations/sparkle.json',
          repeat: false,
        );
      case CelebrationType.none:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```

---

## 测试策略

### 单元测试：分类引擎

```dart
// test/unit/application/dual_ledger/classification_service_test.dart

void main() {
  late MockRuleEngine mockRuleEngine;
  late MockMerchantDatabase mockMerchantDB;
  late MockTFLiteClassifier mockTFLiteClassifier;
  late ClassificationService classificationService;

  setUp(() {
    mockRuleEngine = MockRuleEngine();
    mockMerchantDB = MockMerchantDatabase();
    mockTFLiteClassifier = MockTFLiteClassifier();

    classificationService = ClassificationService(
      ruleEngine: mockRuleEngine,
      merchantDB: mockMerchantDB,
      tfliteClassifier: mockTFLiteClassifier,
    );
  });

  group('ClassificationService', () {
    test('规则引擎匹配时使用规则结果', () async {
      // Arrange
      when(mockRuleEngine.classify('cat_entertainment'))
          .thenReturn(LedgerType.soul);

      // Act
      final result = await classificationService.classifyTransaction(
        categoryId: 'cat_entertainment',
      );

      // Assert
      expect(result.ledgerType, LedgerType.soul);
      expect(result.method, ClassificationMethod.rule);
      expect(result.confidence, 1.0);

      // 验证只调用了规则引擎
      verify(mockRuleEngine.classify('cat_entertainment')).called(1);
      verifyNever(mockMerchantDB.lookup(any));
      verifyNever(mockTFLiteClassifier.predict(
        categoryId: anyNamed('categoryId'),
      ));
    });

    test('规则不匹配时尝试商家数据库', () async {
      // Arrange
      when(mockRuleEngine.classify('cat_food'))
          .thenReturn(null);

      when(mockMerchantDB.lookup('星巴克'))
          .thenReturn(MerchantClassification(
            merchant: Merchant(
              name: '星巴克',
              aliases: ['星巴克'],
              categoryId: 'cat_food_coffee',
              ledgerType: LedgerType.soul,
              confidence: 0.9,
            ),
            ledgerType: LedgerType.soul,
            confidence: 0.9,
          ));

      // Act
      final result = await classificationService.classifyTransaction(
        categoryId: 'cat_food',
        merchant: '星巴克',
      );

      // Assert
      expect(result.ledgerType, LedgerType.soul);
      expect(result.method, ClassificationMethod.merchant);
      expect(result.confidence, 0.9);

      verify(mockRuleEngine.classify('cat_food')).called(1);
      verify(mockMerchantDB.lookup('星巴克')).called(1);
      verifyNever(mockTFLiteClassifier.predict(
        categoryId: anyNamed('categoryId'),
      ));
    });

    test('规则和商家都不匹配时使用ML', () async {
      // Arrange
      when(mockRuleEngine.classify('cat_unknown'))
          .thenReturn(null);

      when(mockMerchantDB.lookup('未知商家'))
          .thenReturn(null);

      when(mockTFLiteClassifier.predict(
        categoryId: 'cat_unknown',
        merchant: '未知商家',
      )).thenAnswer((_) async => LedgerType.survival);

      // Act
      final result = await classificationService.classifyTransaction(
        categoryId: 'cat_unknown',
        merchant: '未知商家',
      );

      // Assert
      expect(result.ledgerType, LedgerType.survival);
      expect(result.method, ClassificationMethod.ml);

      verify(mockRuleEngine.classify('cat_unknown')).called(1);
      verify(mockMerchantDB.lookup('未知商家')).called(1);
      verify(mockTFLiteClassifier.predict(
        categoryId: 'cat_unknown',
        merchant: '未知商家',
      )).called(1);
    });
  });
}
```

---

## 总结

MOD-003双轨账本模块提供：

1. **三层分类引擎**: 规则 → 商家 → ML，准确率≥85%
2. **双账本视图**: 独立展示生存和灵魂账本
3. **智能分类**: 自动分类交易到合适账本
4. **灵魂庆祝**: 有趣的动画增加记账乐趣
5. **用户反馈**: 支持修正分类，持续优化

**开发优先级**: P0，预计8天完成。

**依赖模块**:
- ✅ MOD-001/002 (基础记账) - 交易创建流程
- ✅ MOD-006 (安全模块) - 数据加密

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 功能团队
- 版本: 1.0
