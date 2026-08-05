# PRD - 趣味功能模块

**模块ID:** MOD-009
**模块名称:** 趣味功能模块（游戏化）
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P2（可选A/B测试）
**预估工时:** 7天

---

## 1. 模块概述

### 1.1 功能定义

趣味功能模块通过游戏化设计,为记账行为增添乐趣,提升用户留存率。包括:

- **大谷翔平换算器（C01）:** 将消费金额换算成日本国民级文化符号
- **运势占卜（C02）:** 小票占卜（OCR触发）+ 今日运势（主动触发）
- **灵魂消费庆祝（C04）:** 已在双轨账本模块实现

**重要决策:** 仅当Beta测试用户接受度>60%时才包含在MVP中。

**核心价值主张:**
将严肃的记账行为转化为有趣的社交体验,创造"小确幸"时刻。

### 1.2 用户场景与痛点

**用户画像:**
- 山田花子（28岁,喜欢分享生活）
- 觉得传统记账应用太枯燥,难以坚持
- 希望有一些有趣的元素让记账变得不那么无聊

**痛点:**
1. **记账无聊:** 每天输入数字,没有反馈,缺乏成就感
2. **缺乏动力:** 看到支出报表只有焦虑,没有正向激励
3. **不想分享:** 传统记账数据太隐私,无法与朋友分享

**Happy Pocket解决方案:**
- 大谷翔平换算器:创造社交话题("我今天花了大谷3秒的工资!")
- 运势占卜:将消费转化为"抽签"体验,增加仪式感
- 灵魂消费庆祝:正向反馈,避免愧疚感

### 1.3 文化风险评估

**根据可行性研究:**
- ⚠️ **主要风险:** 游戏化可能与日本Kakeibo传统（深思熟虑的摩擦）冲突
- ⚠️ **年龄问题:** 35-50岁目标用户可能觉得幼稚
- ✅ **缓解措施:** A/B测试验证,提供"成熟模式"关闭趣味功能

**A/B测试决策框架:**
```
Beta测试（100人）
    ↓
对照组（50人,无趣味功能）vs 实验组（50人,有趣味功能）
    ↓
测量指标：
- D7留存率
- 每日记账笔数
- NPS评分
- 用户反馈情绪（正面/负面/中性）
    ↓
Go/No-Go决策：
✅ 继续：实验组D7留存 > 对照组 + 5%，且NPS ≥ 对照组
⚠️ 优化：实验组D7留存 = 对照组 ± 3%，需要调整文案/设计
❌ 移除：实验组D7留存 < 对照组 - 5%，或NPS显著下降
```

### 1.4 与其他模块的依赖关系

**前置依赖:**
- MOD-001 基础记账（需要交易数据）
- MOD-005 OCR扫描（小票占卜触发）

**被依赖:**
- 无（独立功能,可随时启用/禁用）

---

## 2. 详细功能规格

### 2.1 C01: 大谷翔平换算器

#### 2.1.1 功能概述

将消费金额换算成日本国民级文化符号,创造"社交货币"式体验。

**触发机制:**
- 触发时机:交易保存成功后0.5秒
- 展示形式:Toast横幅动画,3秒后自动消失
- 可关闭:✅ 设置中可关闭

**换算单位库（OTA热更新）:**

```json
{
  "version": "1.0.0",
  "last_updated": "2026-02-03",
  "units": [
    {
      "id": "ohtani_salary",
      "name": "大谷翔平の給料",
      "unit_yen": 2000,
      "format_ja": "この金額は大谷翔平の{value}秒分の給料です ⚾",
      "format_cn": "这是大谷翔平{value}秒的工资 ⚾",
      "icon": "⚾",
      "category": "sports",
      "min_amount": 1000,
      "max_amount": 50000
    },
    {
      "id": "yoshinoya_gyudon",
      "name": "吉野家の牛丼",
      "unit_yen": 500,
      "format_ja": "{value}杯の牛丼を食べました 🍚",
      "format_cn": "吃了{value}碗牛肉饭 🍚",
      "icon": "🍚",
      "category": "food",
      "min_amount": 100,
      "max_amount": 10000
    },
    {
      "id": "gacha_pull",
      "name": "ソシャゲの10連ガチャ",
      "unit_yen": 3000,
      "format_ja": "{value}回の10連ガチャが回せます 🎰",
      "format_cn": "可以抽{value}次十连 🎰",
      "icon": "🎰",
      "category": "game",
      "min_amount": 1000,
      "max_amount": 30000
    },
    {
      "id": "starbucks_latte",
      "name": "スタバのラテ",
      "unit_yen": 450,
      "format_ja": "{value}杯のスタバラテです ☕",
      "format_cn": "星巴克拿铁{value}杯 ☕",
      "icon": "☕",
      "category": "food",
      "min_amount": 100,
      "max_amount": 5000
    },
    {
      "id": "tokyo_metro",
      "name": "東京メトロの運賃",
      "unit_yen": 200,
      "format_ja": "東京メトロ{value}回分です 🚇",
      "format_cn": "东京地铁{value}次 🚇",
      "icon": "🚇",
      "category": "transport",
      "min_amount": 100,
      "max_amount": 3000
    },
    {
      "id": "onsen_entry",
      "name": "温泉の入浴料",
      "unit_yen": 800,
      "format_ja": "{value}回分の温泉です ♨️",
      "format_cn": "温泉{value}次 ♨️",
      "icon": "♨️",
      "category": "leisure",
      "min_amount": 500,
      "max_amount": 10000
    },
    {
      "id": "manga_volume",
      "name": "漫画の単行本",
      "unit_yen": 550,
      "format_ja": "{value}冊の漫画が買えます 📚",
      "format_cn": "漫画书{value}本 📚",
      "icon": "📚",
      "category": "hobby",
      "min_amount": 300,
      "max_amount": 10000
    },
    {
      "id": "shiba_inu_food",
      "name": "柴犬の1日分のご飯",
      "unit_yen": 300,
      "format_ja": "柴犬{value}日分のご飯です 🐕",
      "format_cn": "柴犬{value}天的狗粮 🐕",
      "icon": "🐕",
      "category": "pet",
      "min_amount": 100,
      "max_amount": 5000
    }
  ]
}
```

**实现代码:**

```dart
// lib/features/gamification/domain/use_cases/ohtani_converter.dart

class OhtaniConverter {
  final ConversionUnitRepository _unitRepo;

  Future<String?> convert(int amount) async {
    // 1. 获取换算单位库（从OTA配置）
    final units = await _unitRepo.getUnits();

    // 2. 根据金额范围筛选合适的单位
    final suitableUnits = units.where((unit) {
      return amount >= unit.minAmount && amount <= unit.maxAmount;
    }).toList();

    if (suitableUnits.isEmpty) {
      return null;  // 金额不在任何单位范围内
    }

    // 3. 随机选择一个单位
    final random = Random();
    final selectedUnit = suitableUnits[random.nextInt(suitableUnits.length)];

    // 4. 计算换算值
    final count = (amount / selectedUnit.unitYen).round();

    // 5. 格式化文案
    return selectedUnit.formatJa.replaceAll('{value}', count.toString());
  }
}

// lib/features/gamification/presentation/widgets/ohtani_toast.dart

class OhtaniToast extends StatefulWidget {
  final String message;

  const OhtaniToast({required this.message});

  @override
  State<OhtaniToast> createState() => _OhtaniToastState();
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
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    // 3秒后自动消失
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(top: 60, left: 16, right: 16),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90D9), Color(0xFF00BCD4)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**使用示例:**

```dart
// 在交易保存成功后调用
Future<void> _onTransactionSaved(Transaction tx) async {
  final settings = await _settingsRepo.getSettings();

  if (settings.ohtaniConverterEnabled) {
    final message = await _ohtaniConverter.convert(tx.amount);

    if (message != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, _, __) => OhtaniToast(message: message),
        ),
      );
    }
  }
}
```

---

### 2.2 C02: 运势占卜

#### 2.2.1 C02a: 小票占卜（被动触发）

**触发时机:**
用户使用OCR扫描小票时自动触发

**占卜流程:**

```
扫描小票 → OCR识别 → 用户确认
    ↓
点击"保存"
    ↓
小票变形为"签纸"（翻转动画）
    ↓
展示运势结果
    ↓
[可选] 查看详细解读
    ↓
返回首页
```

**运势生成算法:**

```dart
// lib/features/gamification/domain/use_cases/generate_omikuji.dart

class GenerateOmikujiUseCase {
  Future<OmikujiResult> execute(Transaction tx) async {
    // 1. 生成确定性种子（基于交易数据）
    final seed = _generateSeed(tx);

    // 2. 选择运势等级
    final level = _selectLevel(seed);

    // 3. 生成个性化文案
    final message = await _generateMessage(level, tx);

    // 4. 选择相关分类的运势预测
    final forecast = _generateForecast(level, tx.categoryId);

    return OmikujiResult(
      level: level,
      message: message,
      forecast: forecast,
      transactionId: tx.id,
    );
  }

  int _generateSeed(Transaction tx) {
    // 确保同一笔交易每次生成相同的运势
    final dateHash = tx.timestamp.day * 31 + tx.timestamp.month;
    final amountHash = tx.amount % 1000;
    final noteHash = tx.note?.hashCode ?? 0;
    return (dateHash ^ amountHash ^ noteHash) & 0x7FFFFFFF;
  }

  OmikujiLevel _selectLevel(int seed) {
    final random = Random(seed);
    final roll = random.nextDouble() * 100;

    // 运势等级概率分布
    if (roll < 5) return OmikujiLevel.daikichi;      // 大吉 5%
    if (roll < 20) return OmikujiLevel.chukichi;     // 中吉 15%
    if (roll < 45) return OmikujiLevel.shokichi;     // 小吉 25%
    if (roll < 75) return OmikujiLevel.kichi;        // 吉 30%
    if (roll < 90) return OmikujiLevel.suekichi;     // 末吉 15%
    if (roll < 98) return OmikujiLevel.kyo;          // 凶 8%
    return OmikujiLevel.daikyo;                      // 大凶 2%
  }

  Future<String> _generateMessage(OmikujiLevel level, Transaction tx) async {
    final templates = await _messageRepo.getTemplates(level);
    final random = Random(tx.id.hashCode);
    return templates[random.nextInt(templates.length)];
  }

  Map<String, String> _generateForecast(OmikujiLevel level, String categoryId) {
    // 根据分类生成不同的运势预测
    final forecasts = <String, String>{};

    if (categoryId.contains('food')) {
      forecasts['料理運'] = _getFoodFortune(level);
    } else if (categoryId.contains('hobby')) {
      forecasts['趣味運'] = _getHobbyFortune(level);
    } else if (categoryId.contains('shopping')) {
      forecasts['買い物運'] = _getShoppingFortune(level);
    }

    // 通用运势
    forecasts['金運'] = _getMoneyFortune(level);
    forecasts['健康運'] = _getHealthFortune(level);

    return forecasts;
  }
}

enum OmikujiLevel {
  daikichi,   // 大吉
  chukichi,   // 中吉
  shokichi,   // 小吉
  kichi,      // 吉
  suekichi,   // 末吉
  kyo,        // 凶
  daikyo,     // 大凶
}

class OmikujiResult {
  final OmikujiLevel level;
  final String message;
  final Map<String, String> forecast;  // 分类运势
  final String transactionId;

  OmikujiResult({
    required this.level,
    required this.message,
    required this.forecast,
    required this.transactionId,
  });
}
```

**UI设计（签纸翻转动画）:**

```dart
// lib/features/gamification/presentation/widgets/omikuji_reveal.dart

class OmikujiReveal extends StatefulWidget {
  final OmikujiResult result;

  const OmikujiReveal({required this.result});

  @override
  State<OmikujiReveal> createState() => _OmikujiRevealState();
}

class _OmikujiRevealState extends State<OmikujiReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 延迟0.5秒后开始翻转
    Future.delayed(Duration(milliseconds: 500), () {
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * pi;
            final isFront = angle < pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isFront ? _buildReceiptFront() : _buildOmikujiBack(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReceiptFront() {
    // 收据正面（模拟纸质收据）
    return Container(
      width: 300,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('レシート', style: TextStyle(fontSize: 20)),
          Divider(),
          Text('変身中...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOmikujiBack() {
    // 签纸背面（运势结果）
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),  // 翻转背面文字
      child: Container(
        width: 300,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(widget.result.level),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.result.level.displayName,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.result.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 24),
            ...widget.result.forecast.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: TextStyle(color: Colors.white70)),
                    Text(entry.value, style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(OmikujiLevel level) {
    switch (level) {
      case OmikujiLevel.daikichi:
        return [Color(0xFFFFD700), Color(0xFFFF8C00)];  // 金色
      case OmikujiLevel.chukichi:
        return [Color(0xFFFF6B6B), Color(0xFFFF4757)];  // 红色
      case OmikujiLevel.shokichi:
      case OmikujiLevel.kichi:
        return [Color(0xFF4CAF50), Color(0xFF45B7D1)];  // 绿色
      case OmikujiLevel.suekichi:
        return [Color(0xFF5DADE2), Color(0xFF3498DB)];  // 蓝色
      case OmikujiLevel.kyo:
        return [Color(0xFF95A5A6), Color(0xFF7F8C8D)];  // 灰色
      case OmikujiLevel.daikyo:
        return [Color(0xFF9B59B6), Color(0xFF8E44AD)];  // 紫色
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 2.2.2 C02b: 今日运势（主动触发）

**触发时机:**
用户点击首页的"今日运势"入口

**货币化设计:**
预测结果页面展示激励广告（变现入口）

**UI设计:**

```
┌─────────────────────────────────────┐
│  今日運勢                           │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │      [抽签动画]             │   │
│  │                             │   │
│  │   点击获取今日运势           │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  [点击抽签]                         │
└─────────────────────────────────────┘

↓ 点击后

┌─────────────────────────────────────┐
│  今日運勢                      ← │
├─────────────────────────────────────┤
│                                     │
│          大吉                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  今日のあなたは最高の運気！         │
│  財布に優しい日になるでしょう。      │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  各種運勢                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  金運:    ★★★★★               │
│  健康運:  ★★★★☆               │
│  恋愛運:  ★★★☆☆               │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  今日のラッキーアイテム              │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  🍀 牛丼                            │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  [広告] ← 激励广告插入位置          │
│                                     │
│  [もう一度占う]  [閉じる]           │
└─────────────────────────────────────┘
```

---

## 3. 数据模型设计

### 3.1 Drift表定义

```dart
// lib/core/database/tables.dart

@DataClassName('OmikujiRecordData')
class OmikujiRecords extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();  // 关联交易
  TextColumn get level => text()();  // 'daikichi', 'chukichi', etc.
  TextColumn get message => text()();
  TextColumn get forecast => text()();  // JSON格式
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GamificationSettingsData')
class GamificationSettings extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  BoolColumn get ohtaniConverterEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get omikujiEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get soulCelebrationEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 4. UI/UX设计

### 4.1 设置页面（趣味功能开关）

```
┌─────────────────────────────────────┐
│ ← 设置                              │
├─────────────────────────────────────┤
│  趣味功能                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ⚾ 大谷翔平換算器                   │
│  [                            ✓]   │  ← 开关
│  消費金額を面白く換算               │
│                                     │
│  🎴 運勢占い                        │
│  [                            ✓]   │
│  レシート占い＆今日の運勢           │
│                                     │
│  💖 魂消費お祝い                    │
│  [                            ✓]   │
│  魂アカウント支出時のアニメーション  │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ⚠️ 全ての趣味功能を無効にする      │
│  [成熟モード]                       │  ← 一键关闭
│                                     │
└─────────────────────────────────────┘
```

---

## 5. 技术实现方案

### 5.1 OTA热更新

**换算单位库热更新:**

```dart
// lib/features/gamification/data/ota_config_service.dart

class OTAConfigService {
  final http.Client _client;
  final String _configUrl = 'https://cdn.homepocket.app/config/conversion_units.json';

  Future<void> updateConversionUnits() async {
    try {
      final response = await _client.get(Uri.parse(_configUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final version = json['version'];

        // 检查版本是否更新
        final currentVersion = await _prefs.getString('conversion_units_version');
        if (version != currentVersion) {
          // 保存新版本配置
          await _prefs.setString('conversion_units_json', response.body);
          await _prefs.setString('conversion_units_version', version);
        }
      }
    } catch (e) {
      // 更新失败,使用本地缓存
      print('OTA更新失败: $e');
    }
  }

  Future<List<ConversionUnit>> getUnits() async {
    // 1. 尝试从缓存读取
    final cachedJson = await _prefs.getString('conversion_units_json');

    if (cachedJson != null) {
      return _parseUnits(cachedJson);
    }

    // 2. 回退到内置配置
    final defaultJson = await rootBundle.loadString('assets/config/conversion_units.json');
    return _parseUnits(defaultJson);
  }

  List<ConversionUnit> _parseUnits(String json) {
    final data = jsonDecode(json);
    return (data['units'] as List)
        .map((unit) => ConversionUnit.fromJson(unit))
        .toList();
  }
}
```

---

## 6. 验收标准

### 6.1 功能完整性

- ✅ 大谷换算器在交易保存后0.5秒内显示
- ✅ Toast 3秒后自动消失
- ✅ 用户可在设置中关闭趣味功能
- ✅ 小票占卜翻转动画流畅（60fps）
- ✅ 运势等级概率分布正确
- ✅ 同一笔交易每次生成相同运势

### 6.2 A/B测试指标

**对照组（无趣味功能）:**
- D7留存率: 基准值
- 每日记账笔数: 基准值
- NPS评分: 基准值

**实验组（有趣味功能）:**
- D7留存率: 目标 > 基准值 + 5%
- 趣味功能使用率: 目标 > 50%
- 用户反馈情绪: 目标 > 70% 正面
- NPS评分: 目标 ≥ 基准值

**Go/No-Go决策:**
- ✅ 继续: 实验组D7留存 > 对照组 + 5%，且NPS ≥ 对照组
- ⚠️ 优化: 实验组D7留存 = 对照组 ± 3%，需要调整文案/设计
- ❌ 移除: 实验组D7留存 < 对照组 - 5%，或NPS显著下降

---

## 7. 测试用例

### 7.1 单元测试

```dart
void main() {
  group('OhtaniConverter', () {
    test('should select suitable unit for amount', () async {
      // Given
      final amount = 1280;

      // When
      final message = await converter.convert(amount);

      // Then
      expect(message, isNotNull);
      expect(message, contains('杯'));  // 应该匹配吉野家牛丼
    });

    test('should return null for amount out of range', () async {
      // Given
      final amount = 100000;  // 超过所有单位的最大值

      // When
      final message = await converter.convert(amount);

      // Then
      expect(message, isNull);
    });
  });

  group('GenerateOmikujiUseCase', () {
    test('should generate consistent result for same transaction', () async {
      // Given
      final tx = Transaction(id: 'tx-001', amount: 1280, /* ... */);

      // When
      final result1 = await useCase.execute(tx);
      final result2 = await useCase.execute(tx);

      // Then
      expect(result1.level, result2.level);
      expect(result1.message, result2.message);
    });

    test('should respect probability distribution', () async {
      // Given
      final results = <OmikujiLevel>[];

      // When - 生成1000次
      for (var i = 0; i < 1000; i++) {
        final tx = Transaction(id: 'tx-$i', amount: i, /* ... */);
        final result = await useCase.execute(tx);
        results.add(result.level);
      }

      // Then - 验证概率分布
      final daikichi = results.where((l) => l == OmikujiLevel.daikichi).length;
      expect(daikichi, closeTo(50, 20));  // 5% ± 2%
    });
  });
}
```

---

## 8. 开发里程碑（7天）

| Day | 任务 | 产出 |
|-----|------|------|
| **Day 1** | 大谷换算器基础 | 换算逻辑、Toast UI |
| **Day 2** | OTA配置系统 | 热更新机制、单位库 |
| **Day 3** | 运势算法 | 种子生成、概率分布 |
| **Day 4** | 小票占卜UI | 翻转动画、签纸设计 |
| **Day 5** | 今日运势 | 主动触发流程、广告集成 |
| **Day 6** | 设置页面 | 开关、成熟模式 |
| **Day 7** | A/B测试埋点 | 数据收集、分析仪表盘 |

---

**文档状态:** 完成
**审核状态:** 待评审

**重要提醒:**
⚠️ 本模块为P2优先级,**仅当Beta测试验证用户接受度>60%时才包含在MVP中**。
如果A/B测试结果不理想,应立即移除以避免影响核心用户体验。

**变更日志:**
- 2026-02-03: 初版完成（包含A/B测试决策框架）
