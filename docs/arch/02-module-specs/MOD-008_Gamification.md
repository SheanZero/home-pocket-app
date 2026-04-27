# MOD-013: 游戏化体验模块

## 1. 模块概述

### 1.1 模块定位
游戏化体验模块为记账应用注入趣味性和参与感,通过"大谷换算器"和"抽运势"功能,将枯燥的数字转化为有趣的互动体验,提升用户的记账积极性和应用粘性。

### 1.2 业务价值
- **趣味化记账**: 通过大谷翔平薪资换算,让用户以更直观有趣的方式理解消费金额
- **情感连接**: 运势系统为记账行为添加仪式感,增强用户与应用的情感联系
- **用户留存**: 游戏化元素提升用户活跃度和应用打开频率
- **品牌差异化**: 独特的游戏化设计成为产品的核心竞争力

### 1.3 核心功能
1. **大谷换算器**: 支持多种换算单位的金额转换展示
2. **运势系统**: 概率分布的运势抽取机制
3. **动画效果**: Toast动画和运势卡片翻转效果
4. **OTA配置**: 支持远程更新换算单位和运势内容

## 2. 功能需求

### 2.1 大谷换算器

#### 2.1.1 换算单位配置
```
支持的换算单位:
- 大谷薪资: 2000日元/秒
- 吉野家牛肉饭: 500日元/碗
- 手游十连抽: 3000日元/次
- 星巴克拿铁: 600日元/杯
- 新干线东京-大阪: 13,000日元/单程
- iPhone 15 Pro: 159,800日元/台
```

#### 2.1.2 换算逻辑
- 根据金额大小自动选择合适的换算单位
- 支持自定义换算单位的优先级
- 显示格式: `等于X个/份/杯XXX`

#### 2.1.3 展示方式
- Toast形式: 记账后自动弹出,3秒后自动消失
- 手动触发: 点击交易详情中的换算按钮
- 动画效果: 从底部滑入,带淡入淡出效果

### 2.2 运势系统

#### 2.2.1 运势类型与概率
```
运势分布:
- 大吉 (10%): "财运亨通,今日适合投资理财"
- 吉 (30%): "收支平衡,保持现状即可"
- 小吉 (35%): "小有收获,控制开支更佳"
- 凶 (20%): "财运欠佳,谨慎消费为宜"
- 大凶 (5%): "破财之相,今日不宜大额支出"
```

#### 2.2.2 抽取规则
- 每日首次打开应用自动触发
- 支持手动抽取(每日3次限制)
- 运势结果当日有效

#### 2.2.3 运势展示
- 卡片翻转动画
- 运势图标和颜色主题
- 运势建议文案
- 分享功能

### 2.3 OTA配置支持

#### 2.3.1 可配置项
- 换算单位列表及汇率
- 运势文案内容
- 运势概率分布
- 动画效果参数

#### 2.3.2 配置更新机制
- 应用启动时检查更新
- 后台定时轮询
- 本地缓存fallback

## 3. 技术设计

### 3.1 架构设计

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
├─────────────────────────────────────────────────────┤
│  GamificationScreen                                  │
│  ├─ OhtaniConverterWidget                           │
│  │  └─ OhtaniToast (Animated)                       │
│  └─ FortuneWidget                                    │
│     ├─ FortuneCard (FlipAnimation)                  │
│     └─ FortuneDialog                                 │
├─────────────────────────────────────────────────────┤
│                   Domain Layer                       │
├─────────────────────────────────────────────────────┤
│  OhtaniConverterUseCase                             │
│  FortuneGeneratorUseCase                            │
│  GetDailyFortuneUseCase                             │
├─────────────────────────────────────────────────────┤
│                    Data Layer                        │
├─────────────────────────────────────────────────────┤
│  ConversionUnitRepositoryImpl (目标位置，未实施)   │
│  FortuneRepositoryImpl (目标位置，未实施)           │
│  OtaConfigService                                    │
└─────────────────────────────────────────────────────┘
```

### 3.2 技术选型
- **状态管理**: Riverpod 2.4+
- **动画**: Flutter Animation API + AnimationController
- **本地存储**: Drift + SharedPreferences
- **网络请求**: dio (OTA配置)
- **随机数生成**: dart:math Random (加密安全)

## 4. 数据模型

### 4.1 领域模型

#### 4.1.1 ConversionUnit (换算单位)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversion_unit.freezed.dart';
part 'conversion_unit.g.dart';

@freezed
class ConversionUnit with _$ConversionUnit {
  const factory ConversionUnit({
    required String id,
    required String name,
    required String unit,
    required double priceInYen,
    required int priority,
    String? iconEmoji,
    String? description,
  }) = _ConversionUnit;

  factory ConversionUnit.fromJson(Map<String, dynamic> json) =>
      _$ConversionUnitFromJson(json);
}
```

#### 4.1.2 Fortune (运势)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fortune.freezed.dart';
part 'fortune.g.dart';

enum FortuneLevel {
  greatBlessing,  // 大吉
  blessing,       // 吉
  smallBlessing,  // 小吉
  curse,          // 凶
  greatCurse,     // 大凶
}

@freezed
class Fortune with _$Fortune {
  const factory Fortune({
    required String id,
    required FortuneLevel level,
    required String title,
    required String message,
    required String advice,
    required DateTime date,
    @Default(false) bool isShared,
  }) = _Fortune;

  factory Fortune.fromJson(Map<String, dynamic> json) =>
      _$FortuneFromJson(json);
}
```

#### 4.1.3 ConversionResult (换算结果)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'conversion_unit.dart';

part 'conversion_result.freezed.dart';

@freezed
class ConversionResult with _$ConversionResult {
  const factory ConversionResult({
    required double originalAmount,
    required ConversionUnit unit,
    required double convertedAmount,
    required String displayText,
  }) = _ConversionResult;
}
```

### 4.2 数据库模型

#### 4.2.1 Fortunes Table
```dart
import 'package:drift/drift.dart';

class Fortunes extends Table {
  TextColumn get id => text()();
  IntColumn get level => intEnum<FortuneLevel>()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get advice => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### 4.2.2 ConversionUnits Table
```dart
import 'package:drift/drift.dart';

class ConversionUnits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get priceInYen => real()();
  IntColumn get priority => integer()();
  TextColumn get iconEmoji => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

## 5. 核心流程

### 5.1 大谷换算流程

```dart
// lib/features/gamification/domain/usecases/convert_to_ohtani.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/conversion_unit.dart';
import '../entities/conversion_result.dart';
import '../repositories/conversion_unit_repository.dart';

part 'convert_to_ohtani.g.dart';

@riverpod
ConvertToOhtaniUseCase convertToOhtaniUseCase(ConvertToOhtaniUseCaseRef ref) {
  final repository = ref.watch(conversionUnitRepositoryProvider);
  return ConvertToOhtaniUseCase(repository);
}

class ConvertToOhtaniUseCase {
  final ConversionUnitRepository _repository;

  ConvertToOhtaniUseCase(this._repository);

  Future<ConversionResult> execute(double amountInYen) async {
    // Get all enabled conversion units sorted by priority
    final units = await _repository.getEnabledUnits();

    if (units.isEmpty) {
      throw Exception('No conversion units available');
    }

    // Select the most appropriate unit based on amount
    final selectedUnit = _selectUnit(amountInYen, units);

    // Calculate converted amount
    final convertedAmount = amountInYen / selectedUnit.priceInYen;

    // Format display text
    final displayText = _formatDisplayText(convertedAmount, selectedUnit);

    return ConversionResult(
      originalAmount: amountInYen,
      unit: selectedUnit,
      convertedAmount: convertedAmount,
      displayText: displayText,
    );
  }

  ConversionUnit _selectUnit(double amount, List<ConversionUnit> units) {
    // Sort by priority
    final sortedUnits = List<ConversionUnit>.from(units)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    // Find the unit where converted amount is in reasonable range (0.1 - 1000)
    for (final unit in sortedUnits) {
      final converted = amount / unit.priceInYen;
      if (converted >= 0.1 && converted <= 1000) {
        return unit;
      }
    }

    // Default to the highest priority unit
    return sortedUnits.first;
  }

  String _formatDisplayText(double amount, ConversionUnit unit) {
    final formattedAmount = amount >= 1
        ? amount.toStringAsFixed(1)
        : amount.toStringAsFixed(2);

    final emoji = unit.iconEmoji ?? '';
    return '等于 $formattedAmount ${unit.unit} ${unit.name} $emoji';
  }
}
```

### 5.2 运势生成流程

```dart
// lib/features/gamification/domain/usecases/generate_fortune.dart
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/fortune.dart';
import '../repositories/fortune_repository.dart';

part 'generate_fortune.g.dart';

@riverpod
GenerateFortuneUseCase generateFortuneUseCase(GenerateFortuneUseCaseRef ref) {
  final repository = ref.watch(fortuneRepositoryProvider);
  return GenerateFortuneUseCase(repository);
}

class GenerateFortuneUseCase {
  final FortuneRepository _repository;
  final Random _random = Random.secure();

  GenerateFortuneUseCase(this._repository);

  Future<Fortune> execute() async {
    // Check daily limit
    final today = DateTime.now();
    final todayCount = await _repository.getFortuneCountByDate(today);

    if (todayCount >= 3) {
      throw Exception('Daily fortune limit reached (3/3)');
    }

    // Generate fortune based on probability distribution
    final level = _generateFortuneLevel();
    final content = await _repository.getFortuneContent(level);

    final fortune = Fortune(
      id: _generateId(),
      level: level,
      title: content.title,
      message: content.message,
      advice: content.advice,
      date: today,
      isShared: false,
    );

    // Save to database
    await _repository.saveFortune(fortune);

    return fortune;
  }

  FortuneLevel _generateFortuneLevel() {
    final value = _random.nextDouble() * 100;

    // Probability distribution:
    // Great Blessing: 10% (0-10)
    // Blessing: 30% (10-40)
    // Small Blessing: 35% (40-75)
    // Curse: 20% (75-95)
    // Great Curse: 5% (95-100)

    if (value < 10) {
      return FortuneLevel.greatBlessing;
    } else if (value < 40) {
      return FortuneLevel.blessing;
    } else if (value < 75) {
      return FortuneLevel.smallBlessing;
    } else if (value < 95) {
      return FortuneLevel.curse;
    } else {
      return FortuneLevel.greatCurse;
    }
  }

  String _generateId() {
    return 'fortune_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }
}
```

### 5.3 获取每日运势流程

```dart
// lib/features/gamification/domain/usecases/get_daily_fortune.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/fortune.dart';
import '../repositories/fortune_repository.dart';

part 'get_daily_fortune.g.dart';

@riverpod
GetDailyFortuneUseCase getDailyFortuneUseCase(GetDailyFortuneUseCaseRef ref) {
  final repository = ref.watch(fortuneRepositoryProvider);
  return GetDailyFortuneUseCase(repository);
}

class GetDailyFortuneUseCase {
  final FortuneRepository _repository;

  GetDailyFortuneUseCase(this._repository);

  Future<Fortune?> execute() async {
    final today = DateTime.now();
    final fortunes = await _repository.getFortunesByDate(today);

    if (fortunes.isEmpty) {
      return null;
    }

    // Return the latest fortune of the day
    return fortunes.first;
  }

  Future<int> getRemainingCount() async {
    final today = DateTime.now();
    final count = await _repository.getFortuneCountByDate(today);
    return 3 - count;
  }
}
```

## 6. Repository実装

> 注：MOD-008 游戏化模块为 v2 backlog 项；下列路径为目标位置，尚未在 lib/ 实施。

### 6.1 ConversionUnitRepository

```dart
// **目标位置（未实施）:** lib/data/repositories/conversion_unit_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/conversion_unit.dart';
import '../../domain/repositories/conversion_unit_repository.dart';
import '../../../../core/database/app_database.dart';

part 'conversion_unit_repository_impl.g.dart';

@riverpod
ConversionUnitRepository conversionUnitRepository(
  ConversionUnitRepositoryRef ref,
) {
  final database = ref.watch(appDatabaseProvider);
  return ConversionUnitRepositoryImpl(database);
}

class ConversionUnitRepositoryImpl implements ConversionUnitRepository {
  final AppDatabase _database;

  ConversionUnitRepositoryImpl(this._database);

  @override
  Future<List<ConversionUnit>> getEnabledUnits() async {
    final units = await (_database.select(_database.conversionUnits)
          ..where((tbl) => tbl.isEnabled.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.priority),
          ]))
        .get();

    return units.map(_toEntity).toList();
  }

  @override
  Future<void> updateUnit(ConversionUnit unit) async {
    await _database.into(_database.conversionUnits).insert(
          ConversionUnitsCompanion.insert(
            id: unit.id,
            name: unit.name,
            unit: unit.unit,
            priceInYen: unit.priceInYen,
            priority: unit.priority,
            iconEmoji: Value(unit.iconEmoji),
            description: Value(unit.description),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> syncFromOta(List<ConversionUnit> units) async {
    await _database.transaction(() async {
      for (final unit in units) {
        await updateUnit(unit);
      }
    });
  }

  @override
  Future<void> initializeDefaults() async {
    final existingCount = await (_database.select(_database.conversionUnits).get())
        .then((rows) => rows.length);

    if (existingCount > 0) {
      return; // Already initialized
    }

    final defaultUnits = [
      ConversionUnit(
        id: 'ohtani_salary',
        name: '大谷薪资',
        unit: '秒',
        priceInYen: 2000,
        priority: 1,
        iconEmoji: '⚾',
        description: '大谷翔平每秒收入约2000日元',
      ),
      ConversionUnit(
        id: 'yoshinoya',
        name: '吉野家牛肉饭',
        unit: '碗',
        priceInYen: 500,
        priority: 2,
        iconEmoji: '🍜',
        description: '一碗吉野家牛肉饭约500日元',
      ),
      ConversionUnit(
        id: 'gacha',
        name: '手游十连抽',
        unit: '次',
        priceInYen: 3000,
        priority: 3,
        iconEmoji: '🎰',
        description: '手游十连抽约3000日元',
      ),
      ConversionUnit(
        id: 'starbucks',
        name: '星巴克拿铁',
        unit: '杯',
        priceInYen: 600,
        priority: 4,
        iconEmoji: '☕',
        description: '一杯星巴克拿铁约600日元',
      ),
      ConversionUnit(
        id: 'shinkansen',
        name: '新干线东京-大阪',
        unit: '单程',
        priceInYen: 13000,
        priority: 5,
        iconEmoji: '🚄',
        description: '新干线东京-大阪单程约13,000日元',
      ),
      ConversionUnit(
        id: 'iphone15pro',
        name: 'iPhone 15 Pro',
        unit: '台',
        priceInYen: 159800,
        priority: 6,
        iconEmoji: '📱',
        description: 'iPhone 15 Pro约159,800日元',
      ),
    ];

    for (final unit in defaultUnits) {
      await updateUnit(unit);
    }
  }

  ConversionUnit _toEntity(ConversionUnitData data) {
    return ConversionUnit(
      id: data.id,
      name: data.name,
      unit: data.unit,
      priceInYen: data.priceInYen,
      priority: data.priority,
      iconEmoji: data.iconEmoji,
      description: data.description,
    );
  }
}
```

### 6.2 FortuneRepository

```dart
// **目标位置（未实施）:** lib/data/repositories/fortune_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/fortune.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../../../../core/database/app_database.dart';

part 'fortune_repository_impl.g.dart';

@riverpod
FortuneRepository fortuneRepository(FortuneRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  return FortuneRepositoryImpl(database);
}

class FortuneRepositoryImpl implements FortuneRepository {
  final AppDatabase _database;

  FortuneRepositoryImpl(this._database);

  @override
  Future<void> saveFortune(Fortune fortune) async {
    await _database.into(_database.fortunes).insert(
          FortunesCompanion.insert(
            id: fortune.id,
            level: fortune.level,
            title: fortune.title,
            message: fortune.message,
            advice: fortune.advice,
            date: fortune.date,
            isShared: Value(fortune.isShared),
          ),
        );
  }

  @override
  Future<List<Fortune>> getFortunesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final fortunes = await (_database.select(_database.fortunes)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(startOfDay))
          ..where((tbl) => tbl.date.isSmallerOrEqualValue(endOfDay))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
          ]))
        .get();

    return fortunes.map(_toEntity).toList();
  }

  @override
  Future<int> getFortuneCountByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final count = await (_database.select(_database.fortunes)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(startOfDay))
          ..where((tbl) => tbl.date.isSmallerOrEqualValue(endOfDay)))
        .get()
        .then((rows) => rows.length);

    return count;
  }

  @override
  Future<FortuneContent> getFortuneContent(FortuneLevel level) async {
    // In a real implementation, this would fetch from database or OTA config
    // For now, return hardcoded content
    return _getDefaultFortuneContent(level);
  }

  FortuneContent _getDefaultFortuneContent(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.greatBlessing:
        return FortuneContent(
          title: '大吉',
          message: '财运亨通,今日适合投资理财',
          advice: '把握机会,适度进取',
        );
      case FortuneLevel.blessing:
        return FortuneContent(
          title: '吉',
          message: '收支平衡,保持现状即可',
          advice: '稳中求进,积少成多',
        );
      case FortuneLevel.smallBlessing:
        return FortuneContent(
          title: '小吉',
          message: '小有收获,控制开支更佳',
          advice: '量入为出,未雨绸缪',
        );
      case FortuneLevel.curse:
        return FortuneContent(
          title: '凶',
          message: '财运欠佳,谨慎消费为宜',
          advice: '减少支出,开源节流',
        );
      case FortuneLevel.greatCurse:
        return FortuneContent(
          title: '大凶',
          message: '破财之相,今日不宜大额支出',
          advice: '避免冲动消费,守住钱包',
        );
    }
  }

  Fortune _toEntity(FortuneData data) {
    return Fortune(
      id: data.id,
      level: data.level,
      title: data.title,
      message: data.message,
      advice: data.advice,
      date: data.date,
      isShared: data.isShared,
    );
  }
}

class FortuneContent {
  final String title;
  final String message;
  final String advice;

  FortuneContent({
    required this.title,
    required this.message,
    required this.advice,
  });
}
```

## 7. UI组件设计

### 7.1 OhtaniToast (换算Toast)

```dart
// lib/features/gamification/presentation/widgets/ohtani_toast.dart
import 'package:flutter/material.dart';
import '../../domain/entities/conversion_result.dart';

class OhtaniToast extends StatefulWidget {
  final ConversionResult result;
  final VoidCallback? onDismiss;

  const OhtaniToast({
    Key? key,
    required this.result,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<OhtaniToast> createState() => _OhtaniToastState();

  static void show(BuildContext context, ConversionResult result) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => OhtaniToast(
        result: result,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

class _OhtaniToastState extends State<OhtaniToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    widget.result.unit.iconEmoji ?? '💰',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¥${widget.result.originalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.result.displayText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 7.2 FortuneCard (运势卡片)

```dart
// lib/features/gamification/presentation/widgets/fortune_card.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/fortune.dart';

class FortuneCard extends StatefulWidget {
  final Fortune? fortune;
  final VoidCallback onTap;
  final bool isFlipping;

  const FortuneCard({
    Key? key,
    this.fortune,
    required this.onTap,
    this.isFlipping = false,
  }) : super(key: key);

  @override
  State<FortuneCard> createState() => _FortuneCardState();
}

class _FortuneCardState extends State<FortuneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FortuneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipping && !oldWidget.isFlipping) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.fortune == null ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final showBack = angle > math.pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: showBack
                ? _buildFortuneFace()
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade700,
            Colors.red.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '今日运势',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '点击抽取',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneFace() {
    if (widget.fortune == null) {
      return _buildCardBack();
    }

    final fortune = widget.fortune!;
    final colors = _getFortuneColors(fortune.level);

    return Transform(
      transform: Matrix4.identity()..rotateY(math.pi),
      alignment: Alignment.center,
      child: Container(
        width: 280,
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getFortuneIcon(fortune.level),
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 20),
              Text(
                fortune.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                fortune.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fortune.advice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getFortuneColors(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.greatBlessing:
        return [Colors.amber.shade600, Colors.orange.shade800];
      case FortuneLevel.blessing:
        return [Colors.green.shade600, Colors.teal.shade800];
      case FortuneLevel.smallBlessing:
        return [Colors.blue.shade600, Colors.indigo.shade800];
      case FortuneLevel.curse:
        return [Colors.grey.shade600, Colors.blueGrey.shade800];
      case FortuneLevel.greatCurse:
        return [Colors.deepPurple.shade700, Colors.deepPurple.shade900];
    }
  }

  String _getFortuneIcon(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.greatBlessing:
        return '🎉';
      case FortuneLevel.blessing:
        return '✨';
      case FortuneLevel.smallBlessing:
        return '🌟';
      case FortuneLevel.curse:
        return '☁️';
      case FortuneLevel.greatCurse:
        return '⚡';
    }
  }
}
```

### 7.3 GamificationScreen (游戏化主页面)

```dart
// lib/features/gamification/presentation/screens/gamification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/generate_fortune.dart';
import '../../domain/usecases/get_daily_fortune.dart';
import '../widgets/fortune_card.dart';
import '../widgets/ohtani_toast.dart';

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> {
  bool _isFlipping = false;

  @override
  Widget build(BuildContext context) {
    final dailyFortuneAsync = ref.watch(getDailyFortuneUseCaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏化体验'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showFortuneHistory,
          ),
        ],
      ),
      body: dailyFortuneAsync.when(
        data: (getDailyFortune) {
          return FutureBuilder(
            future: getDailyFortune.execute(),
            builder: (context, snapshot) {
              final fortune = snapshot.data;

              return FutureBuilder<int>(
                future: getDailyFortune.getRemainingCount(),
                builder: (context, countSnapshot) {
                  final remainingCount = countSnapshot.data ?? 3;

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FortuneCard(
                          fortune: fortune,
                          onTap: () => _drawFortune(),
                          isFlipping: _isFlipping,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          '今日剩余次数: $remainingCount/3',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        if (fortune != null && !fortune.isShared)
                          ElevatedButton.icon(
                            onPressed: () => _shareFortune(fortune),
                            icon: const Icon(Icons.share),
                            label: const Text('分享运势'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }

  Future<void> _drawFortune() async {
    if (_isFlipping) return;

    setState(() {
      _isFlipping = true;
    });

    try {
      final generateFortune = await ref.read(generateFortuneUseCaseProvider.future);
      final fortune = await generateFortune.execute();

      // Wait for flip animation
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('抽到了${fortune.title}!'),
            backgroundColor: _getFortuneColor(fortune.level),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isFlipping = false;
      });
    }
  }

  Color _getFortuneColor(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.greatBlessing:
        return Colors.orange;
      case FortuneLevel.blessing:
        return Colors.green;
      case FortuneLevel.smallBlessing:
        return Colors.blue;
      case FortuneLevel.curse:
        return Colors.grey;
      case FortuneLevel.greatCurse:
        return Colors.deepPurple;
    }
  }

  void _shareFortune(Fortune fortune) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }

  void _showFortuneHistory() {
    // TODO: Navigate to fortune history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('历史记录功能开发中...')),
    );
  }
}
```

## 8. 测试策略

### 8.1 Unit Tests

```dart
// test/features/gamification/domain/usecases/convert_to_ohtani_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConversionUnitRepository extends Mock implements ConversionUnitRepository {}

void main() {
  late ConvertToOhtaniUseCase useCase;
  late MockConversionUnitRepository mockRepository;

  setUp(() {
    mockRepository = MockConversionUnitRepository();
    useCase = ConvertToOhtaniUseCase(mockRepository);
  });

  group('ConvertToOhtaniUseCase', () {
    final testUnits = [
      ConversionUnit(
        id: 'yoshinoya',
        name: '吉野家牛肉饭',
        unit: '碗',
        priceInYen: 500,
        priority: 1,
        iconEmoji: '🍜',
      ),
      ConversionUnit(
        id: 'gacha',
        name: '手游十连抽',
        unit: '次',
        priceInYen: 3000,
        priority: 2,
        iconEmoji: '🎰',
      ),
    ];

    test('should select appropriate unit based on amount', () async {
      // Arrange
      when(mockRepository.getEnabledUnits())
          .thenAnswer((_) async => testUnits);

      // Act
      final result = await useCase.execute(1500);

      // Assert
      expect(result.unit.id, 'yoshinoya'); // 1500/500 = 3 bowls (reasonable)
      expect(result.convertedAmount, 3.0);
      expect(result.displayText, contains('吉野家牛肉饭'));
    });

    test('should format display text correctly', () async {
      // Arrange
      when(mockRepository.getEnabledUnits())
          .thenAnswer((_) async => testUnits);

      // Act
      final result = await useCase.execute(500);

      // Assert
      expect(result.displayText, '等于 1.0 碗 吉野家牛肉饭 🍜');
    });

    test('should throw exception when no units available', () async {
      // Arrange
      when(mockRepository.getEnabledUnits())
          .thenAnswer((_) async => []);

      // Act & Assert
      expect(
        () => useCase.execute(1000),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

### 8.2 Widget Tests

```dart
// test/features/gamification/presentation/widgets/fortune_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FortuneCard', () {
    testWidgets('should show card back when no fortune', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneCard(
              fortune: null,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('今日运势'), findsOneWidget);
      expect(find.text('点击抽取'), findsOneWidget);
    });

    testWidgets('should show fortune when available', (tester) async {
      // Arrange
      final fortune = Fortune(
        id: 'test',
        level: FortuneLevel.greatBlessing,
        title: '大吉',
        message: '财运亨通',
        advice: '把握机会',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneCard(
              fortune: fortune,
              onTap: () {},
              isFlipping: true,
            ),
          ),
        ),
      );

      // Wait for flip animation
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('大吉'), findsOneWidget);
      expect(find.text('财运亨通'), findsOneWidget);
    });

    testWidgets('should trigger onTap when card is tapped', (tester) async {
      // Arrange
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneCard(
              fortune: null,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FortuneCard));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });
  });
}
```

### 8.3 Integration Tests

```dart
// test/features/gamification/domain/usecases/generate_fortune_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFortuneRepository extends Mock implements FortuneRepository {}

void main() {
  late GenerateFortuneUseCase useCase;
  late MockFortuneRepository mockRepository;

  setUp(() {
    mockRepository = MockFortuneRepository();
    useCase = GenerateFortuneUseCase(mockRepository);
  });

  group('GenerateFortuneUseCase', () {
    test('should generate fortune when under daily limit', () async {
      // Arrange
      when(mockRepository.getFortuneCountByDate(any))
          .thenAnswer((_) async => 2);
      when(mockRepository.getFortuneContent(any))
          .thenAnswer((_) async => FortuneContent(
                title: '大吉',
                message: '财运亨通',
                advice: '把握机会',
              ));
      when(mockRepository.saveFortune(any))
          .thenAnswer((_) async => {});

      // Act
      final fortune = await useCase.execute();

      // Assert
      expect(fortune.title, isNotEmpty);
      expect(fortune.message, isNotEmpty);
      expect(fortune.advice, isNotEmpty);
      verify(mockRepository.saveFortune(any)).called(1);
    });

    test('should throw exception when daily limit reached', () async {
      // Arrange
      when(mockRepository.getFortuneCountByDate(any))
          .thenAnswer((_) async => 3);

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockRepository.saveFortune(any));
    });

    test('should follow probability distribution', () async {
      // Arrange
      when(mockRepository.getFortuneCountByDate(any))
          .thenAnswer((_) async => 0);
      when(mockRepository.getFortuneContent(any))
          .thenAnswer((_) async => FortuneContent(
                title: 'Test',
                message: 'Test',
                advice: 'Test',
              ));
      when(mockRepository.saveFortune(any))
          .thenAnswer((_) async => {});

      // Act - Generate 1000 fortunes to test distribution
      final levels = <FortuneLevel>[];
      for (var i = 0; i < 1000; i++) {
        final fortune = await useCase.execute();
        levels.add(fortune.level);
      }

      // Assert - Check approximate distribution
      final greatBlessingCount = levels.where((l) => l == FortuneLevel.greatBlessing).length;
      final blessingCount = levels.where((l) => l == FortuneLevel.blessing).length;
      final smallBlessingCount = levels.where((l) => l == FortuneLevel.smallBlessing).length;
      final curseCount = levels.where((l) => l == FortuneLevel.curse).length;
      final greatCurseCount = levels.where((l) => l == FortuneLevel.greatCurse).length;

      // Allow 5% deviation from expected probabilities
      expect(greatBlessingCount / 1000, closeTo(0.10, 0.05)); // ~10%
      expect(blessingCount / 1000, closeTo(0.30, 0.05)); // ~30%
      expect(smallBlessingCount / 1000, closeTo(0.35, 0.05)); // ~35%
      expect(curseCount / 1000, closeTo(0.20, 0.05)); // ~20%
      expect(greatCurseCount / 1000, closeTo(0.05, 0.05)); // ~5%
    });
  });
}
```

## 9. 性能优化

### 9.1 数据库索引
```sql
CREATE INDEX idx_fortunes_date ON fortunes(date);
CREATE INDEX idx_conversion_units_priority ON conversion_units(priority);
CREATE INDEX idx_conversion_units_enabled ON conversion_units(is_enabled);
```

### 9.2 缓存策略
- 换算单位列表缓存30分钟
- OTA配置缓存24小时
- 运势记录内存缓存当日数据

### 9.3 动画优化
- 使用`RepaintBoundary`包裹动画组件
- 避免不必要的重建
- 使用`const`构造函数

### 9.4 网络优化
- OTA配置增量更新
- 本地fallback机制
- 请求失败重试策略

## 10. 总结

游戏化体验模块通过大谷换算器和运势系统,为记账应用注入了趣味性和参与感。核心技术实现包括:

1. **换算系统**: 基于金额范围自动选择合适单位,支持OTA配置更新
2. **运势系统**: 概率分布的运势生成,每日限制机制
3. **动画效果**: 流畅的Toast滑入、卡片翻转动画
4. **数据持久化**: Drift数据库存储运势记录和换算单位
5. **状态管理**: Riverpod实现响应式状态更新

该模块遵循Clean Architecture设计,保持了良好的可测试性和可维护性,为后续功能扩展(如更多换算单位、运势分享社交功能等)提供了坚实基础。
