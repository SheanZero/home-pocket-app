# Happy Pocket MVP - 剩余模块PRD内容框架

**文档版本:** 1.0
**创建日期:** 2026年2月3日
**状态:** 框架文档
**说明:** 本文档提供剩余5个核心模块的PRD内容框架，供后续详细编写参考

---

## 已完成的PRD文档

✅ **PRD_MVP_Global.md** - MVP全局产品需求文档
✅ **PRD_MVP_App.md** - App端总体PRD
✅ **PRD_MVP_Server.md** - Server端总体PRD
✅ **PRD_Module_BasicAccounting.md** - 基础记账模块详细PRD

---

## 待详细编写的模块PRD

### 1. PRD_Module_DualLedger.md - 双轨账本模块

**模块ID:** MOD-003
**优先级:** P0（MVP必备）
**工时估算:** 8天

**核心内容框架:**

#### 1.1 功能概述
- 将所有消费自动分类为"生存账户"（必需支出）和"灵魂账户"（爱好支出）
- 核心差异化功能，无论单人还是家庭模式都强制开启
- 赋予爱好消费正向意义，避免愧疚感

#### 1.2 数据模型扩展
```sql
-- 扩展分类表
ALTER TABLE categories ADD COLUMN ledger_type TEXT DEFAULT 'auto';
-- ledger_type: 'survival' | 'soul' | 'auto'

-- 灵魂账户配置表
CREATE TABLE soul_account_config (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  soul_name TEXT,              -- "高达基金"、"美妆基金"
  icon_emoji TEXT,
  color_hex TEXT,
  monthly_budget INTEGER,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, device_id)
);

-- 预设分类映射
INSERT INTO category_ledger_defaults VALUES
  ('food_groceries', 'survival'),
  ('food_restaurant', 'soul'),
  ('transport_commute', 'survival'),
  ('transport_travel', 'soul'),
  ('housing_rent', 'survival'),
  ('hobby', 'soul'),
  ...
```

#### 1.3 自动分类引擎（三层策略）

**Layer 1: 规则引擎（优先级最高）**
```dart
class RuleBasedClassifier {
  final Map<String, LedgerType> categoryRules = {
    'food_groceries': LedgerType.survival,
    'housing_rent': LedgerType.survival,
    'utilities': LedgerType.survival,
    'medical': LedgerType.survival,
    'food_restaurant': LedgerType.soul,
    'entertainment': LedgerType.soul,
    'hobby': LedgerType.soul,
    ...
  };

  LedgerType? classify(String categoryId) {
    return categoryRules[categoryId];
  }
}
```

**Layer 2: 商家数据库（500+商家）**
```dart
class MerchantDatabase {
  final Map<String, MerchantInfo> merchants = {
    '吉野家': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
    ),
    'セブンイレブン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
    ),
    'ヨドバシカメラ': MerchantInfo(
      category: 'shopping_electronics',
      ledgerType: LedgerType.auto,  // 需要进一步判断
      confidence: 0.7,
    ),
    ...
  };
}
```

**Layer 3: TensorFlow Lite模型（学习用户习惯）**
```dart
class TFLiteClassifier {
  Future<LedgerType> predict({
    required String merchant,
    required String note,
    required int amount,
    required DateTime timestamp,
  }) async {
    // 特征向量：
    // - merchant embedding (100维)
    // - note keyword embedding (50维)
    // - amount bucket (10维)
    // - hour_of_day (24维)
    // - day_of_week (7维)

    final input = _buildInputTensor(merchant, note, amount, timestamp);
    final output = await _interpreter.run(input);

    // 输出：[survival_prob, soul_prob]
    return output[1] > 0.5 ? LedgerType.soul : LedgerType.survival;
  }
}
```

#### 1.4 UI差异化设计

**生存账户（和风治愈）:**
- 主色调：冷静蓝 #4A90D9
- 图标：🏠
- 进度条：红绿灯预警式
- 超支提示："⚠️ 本月超支"
- 月报标题："生存成本报告"

**灵魂账户（赛博可爱）:**
- 主色调：活力橙 #FF8C42
- 图标：💖
- 进度条：快乐值充能条
- 超支提示："灵魂太过充实了呢～"
- 月报标题："灵魂闪耀报告"

#### 1.5 灵魂消费庆祝动画（C04）

**触发条件:**
- 交易保存成功
- ledger_type == 'soul'
- 用户未关闭庆祝动画设置

**动画效果:**
```dart
class SoulCelebrationAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 粒子爆发效果
        Lottie.asset('assets/particle_burst.json'),

        // 彩虹光晕
        AnimatedContainer(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.pink.withOpacity(0.5),
                Colors.purple.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // 正向文案
        Center(
          child: Text(
            '精神资产 +1 💖',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
```

**文案库:**
```json
{
  "celebration_messages": [
    "精神资产 +1 💖",
    "快乐值充能中 ⚡",
    "灵魂满足度 UP ✨",
    "这是对自己的投资！🎉",
    "生活需要一些小确幸 🌟"
  ]
}
```

#### 1.6 验收标准
- ✅ 所有交易自动分类为生存或灵魂账户
- ✅ 规则引擎准确率 >90%
- ✅ 用户可手动修改自动分类结果
- ✅ 灵魂消费播放2秒庆祝动画（可跳过）
- ✅ 月度报表分别显示两个账户的统计
- ✅ 用户可自定义灵魂账户名称和图标
- ✅ 家庭模式下，伴侣只能看到灵魂预算进度，不能看到明细

---

### 2. PRD_Module_FamilySync.md - 家庭同步模块

**模块ID:** MOD-004
**优先级:** P0（MVP必备）
**工时估算:** 12天

**核心内容框架:**

#### 2.1 配对方式

**方式一：面对面QR码（MVP实现）**
```
Device A                    Device B
   │                           │
   ├─ 生成QR码 ──────────────►│
   │  (含公钥+book_id)         │ 扫描
   │                           │
   │◄────── 握手请求 ──────────┤
   │  (B的公钥)                │
   │                           │
   ├─ 确认配对 ───────────────►│
   │                           │
 [开始同步]                 [开始同步]
```

**方式二：远程短码（V1.0）**
```
Device A           Relay           Device B
   │                 │                 │
   ├─ 请求短码 ──────►│                 │
   │                 │                 │
   │◄─ 返回123456 ───┤                 │
   │                 │                 │
   │ [通过Line发送]   │                 │
   │                 │                 │
   │                 │◄─── 输入短码 ────┤
   │                 │                 │
   │◄─────────── 交换公钥 ─────────────►│
   │                 │                 │
 [配对完成]                         [配对完成]
```

#### 2.2 同步协议（MVP：本地直连）

**传输方式:**
1. 蓝牙（优先）
2. NFC（次选）
3. 本地WiFi（后备）

**同步时机:**
- 手动触发：用户点击"立即同步"
- 定时触发：每日10次免费自动同步（每2.4小时一次）
- 事件触发：创建交易后提示同步

**同步流程:**
```dart
class SyncService {
  Future<SyncResult> sync() async {
    // 1. 获取本地未同步的交易
    final localChanges = await _getUnsynced();

    // 2. 连接对方设备
    final connection = await _connectPeer();

    // 3. 交换变更集
    final remoteChanges = await connection.exchange(localChanges);

    // 4. 合并变更（CRDT自动冲突解决）
    final merged = await _mergeChanges(remoteChanges);

    // 5. 应用到本地数据库
    await _applyChanges(merged);

    // 6. 标记为已同步
    await _markAsSynced(localChanges);

    return SyncResult.success();
  }
}
```

#### 2.3 冲突解决

**自动解决（CRDT）:**
- Last-Write-Wins：时间戳决定
- Operation Transformation：操作转换
- Causal Consistency：因果一致性

**需要用户干预的冲突:**
- 同一笔消费被重复记录 → 提示合并
- 家庭内部转账状态不一致 → 显示双方版本

#### 2.4 家庭内部转账（B05）

**两阶段提交:**
```
Device A (发起方)          Device B (接收方)
   │                           │
   ├─ REQUEST ─────────────────►│
   │  "转账¥5000"              │
   │                           │
   │                      显示通知
   │                      "TA请求转账"
   │                           │
   │◄────── CONFIRM ────────────┤
   │  "同意"                   │
   │                           │
双方各自创建转账记录
   ├─ 支出 -¥5000              │
   │                      收入 +¥5000
   │                           │
 [同步]                       [同步]
```

**状态机:**
```
PENDING (24h超时)
   ├─ CONFIRMED (双方确认)
   ├─ REJECTED (一方拒绝)
   └─ EXPIRED (超时未处理)
```

#### 2.5 验收标准
- ✅ QR码配对成功率 >95%
- ✅ 同步冲突率 <1%
- ✅ 1000条交易同步时间 <10秒
- ✅ 家庭内部转账两阶段提交成功
- ✅ 离线时自动进入队列，上线后自动同步
- ✅ 哈希链完整性验证通过

---

### 3. PRD_Module_OCR.md - OCR扫描模块

**模块ID:** MOD-005
**优先级:** P1（强烈建议）
**工时估算:** 7天

**核心内容框架:**

#### 3.1 OCR技术选型

**iOS:**
- 框架：Vision Framework
- API：VNRecognizeTextRequest
- 语言：日语（ja）+ 英语（en）

**Android:**
- 框架：ML Kit
- API：Text Recognition v2
- 语言：日语 + 英语

#### 3.2 识别目标

| 字段 | 正则表达式 | 准确率目标 |
|------|-----------|----------|
| 金额 | `¥?\s*\d{1,3}(,\d{3})*\s*円?` | >95% |
| 日期 | `\d{4}[年/]\d{1,2}[月/]\d{1,2}日?` | >90% |
| 商家 | OCR结果第一行（启发式） | >85% |
| 合计 | 关键词匹配 `合計\|合计\|TOTAL\|小計` | >90% |

#### 3.3 识别流程

```dart
Future<ReceiptData> scanReceipt(XFile image) async {
  // 1. 图像预处理（去噪、二值化、旋转校正）
  final processed = await _preprocessImage(image);

  // 2. OCR识别
  final text = await _runOCR(processed);

  // 3. 结构化提取
  final amount = _extractAmount(text);
  final date = _extractDate(text);
  final merchant = _extractMerchant(text);

  // 4. 商家自动分类
  final category = await _merchantDB.classify(merchant);

  // 5. 加密存储照片
  final photoHash = await _encryptAndStore(image);

  return ReceiptData(
    amount: amount,
    date: date,
    merchant: merchant,
    category: category,
    photoHash: photoHash,
  );
}
```

#### 3.4 用户确认界面

```
┌─────────────────────────────────────┐
│ ← OCR识别结果              确认保存  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ [照片预览]                  │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  识别结果：                         │
│  ┌────────────────────────────┐    │
│  │ 金额：¥1,280         ✓     │    │  ← 可编辑
│  ├────────────────────────────┤    │
│  │ 日期：2026/2/3       ✓     │    │
│  ├────────────────────────────┤    │
│  │ 商家：吉野家         ✓     │    │
│  ├────────────────────────────┤    │
│  │ 分类：食費（外食）   ▼     │    │  ← 自动推荐
│  └────────────────────────────┘    │
│                                     │
│  ⚠️ 请确认识别结果是否正确          │
│                                     │
│  [重新扫描]            [确认保存]    │
└─────────────────────────────────────┘
```

#### 3.5 商家自动分类（A11）

**商家数据库（500+）:**
```dart
const merchantDatabase = {
  // 食品
  '吉野家': CategoryMatch('food_restaurant', 0.95),
  'セブンイレブン': CategoryMatch('food_groceries', 0.9),
  'マクドナルド': CategoryMatch('food_fastfood', 0.95),
  'イオン': CategoryMatch('shopping_general', 0.8),

  // 交通
  'JR東日本': CategoryMatch('transport_train', 0.95),
  '東京メトロ': CategoryMatch('transport_train', 0.95),

  // 购物
  'ヨドバシカメラ': CategoryMatch('shopping_electronics', 0.9),
  'ユニクロ': CategoryMatch('shopping_fashion', 0.95),
  '無印良品': CategoryMatch('shopping_general', 0.9),

  // 医疗
  'マツモトキヨシ': CategoryMatch('medical', 0.85),

  // 娱乐
  'TOHO': CategoryMatch('entertainment_movie', 0.95),
  ...
};
```

#### 3.6 验收标准
- ✅ 金额识别准确率 >90%（降低了MVP目标从95%）
- ✅ 日期识别准确率 >85%
- ✅ 商家识别准确率 >80%
- ✅ 识别速度 <2秒
- ✅ 支持模糊、倾斜、褶皱的收据照片
- ✅ 识别失败时提供友好错误提示
- ✅ 用户可手动修正识别结果

---

### 4. PRD_Module_Gamification.md - 趣味功能模块

**模块ID:** MOD-009
**优先级:** P2（可选A/B测试）
**工时估算:** 7天

**重要决策：仅当Beta测试用户接受度>60%时才包含在MVP中**

**核心内容框架:**

#### 4.1 C01: 大谷翔平换算器

**功能概述:**
将消费金额换算成日本国民级文化符号，创造"社交货币"式体验。

**触发机制:**
- 触发时机：交易保存成功后0.5秒
- 展示形式：Toast横幅动画，3秒后自动消失
- 可关闭：✅ 设置中可关闭

**换算单位库（OTA热更新）:**
```json
{
  "version": "1.0.0",
  "units": [
    {
      "id": "ohtani_salary",
      "name": "大谷翔平的工资",
      "unit_yen": 2000,
      "format_ja": "この金額は大谷翔平の{value}秒分の給料です",
      "icon": "⚾",
      "category": "sports"
    },
    {
      "id": "yoshinoya_gyudon",
      "name": "吉野家牛丼",
      "unit_yen": 500,
      "format_ja": "{value}杯の牛丼を食べました",
      "icon": "🍚",
      "category": "food"
    },
    {
      "id": "gacha_pull",
      "name": "手游十连抽",
      "unit_yen": 3000,
      "format_ja": "{value}回の10連ガチャが回せます",
      "icon": "🎰",
      "category": "game"
    },
    ...
  ]
}
```

**实现示例:**
```dart
class OhtaniConverter {
  String convert(int amount) {
    final unit = _selectRandomUnit();
    final count = (amount / unit.unitYen).round();

    return unit.formatJa.replaceAll('{value}', count.toString());
  }

  ConversionUnit _selectRandomUnit() {
    // 根据金额范围选择合适的单位
    // ¥0-1000 → 牛丼、罗森炸鸡
    // ¥1000-10000 → 十连抽、温泉
    // ¥10000+ → 大谷工资、柴犬狗粮
  }
}
```

#### 4.2 C02: 运势占卜

**C02a: 小票占卜（被动触发）**
- 用户使用OCR扫描小票时自动触发
- 小票变形为"签纸"，翻转展示运势
- 根据小票内容生成个性化解读

**C02b: 今日运势（主动触发）**
- 首页提供运势预测入口
- 用户点击后进入预测页面
- 预测结果页面展示激励广告（变现入口）

**运势等级与概率:**
| 等级 | 日文 | 概率 | 颜色 | 文案风格 |
|------|------|------|------|---------|
| 大吉 | 大吉 | 5% | 金色 | 极度正面，夸张祝福 |
| 中吉 | 中吉 | 15% | 红色 | 正面，温馨鼓励 |
| 小吉 | 小吉 | 25% | 橙色 | 轻度正面 |
| 吉 | 吉 | 30% | 绿色 | 平稳，日常祝福 |
| 末吉 | 末吉 | 15% | 蓝色 | 略带警示的好运 |
| 凶 | 凶 | 8% | 灰色 | 幽默调侃 |
| 大凶 | 大凶 | 2% | 紫色 | 搞笑夸张的"坏运" |

**种子算法（确定性）:**
```dart
int generateSeed(Transaction tx) {
  final dateHash = tx.timestamp.day * 31 + tx.timestamp.month;
  final amountHash = tx.amount % 1000;
  final noteHash = tx.note?.hashCode ?? 0;
  return (dateHash ^ amountHash ^ noteHash) & 0x7FFFFFFF;
}

OmikujiLevel getOmikuji(int seed) {
  final random = Random(seed);
  final roll = random.nextDouble() * 100;

  if (roll < 5) return OmikujiLevel.daikichi;
  if (roll < 20) return OmikujiLevel.chukichi;
  // ...
}
```

#### 4.3 验收标准（A/B测试指标）

**对照组（无趣味功能）:**
- D7留存率
- 每日记账笔数
- NPS评分

**实验组（有趣味功能）:**
- D7留存率（目标：高于对照组>5%）
- 趣味功能使用率（目标：>50%）
- 用户反馈情绪（正面/负面/中性）
- NPS评分（目标：不低于对照组）

**Go/No-Go决策:**
- ✅ 继续：实验组D7留存 > 对照组 + 5%，且NPS ≥ 对照组
- ⚠️ 优化：实验组D7留存 = 对照组 ± 3%，需要调整文案/设计
- ❌ 移除：实验组D7留存 < 对照组 - 5%，或NPS显著下降

---

### 5. PRD_Module_Security.md - 安全与隐私模块

**模块ID:** MOD-006
**优先级:** P0（MVP必备）
**工时估算:** 10天

**核心内容框架:**

#### 5.1 密钥管理

**密钥生成（E02）:**
```dart
class KeyManager {
  // 设备主密钥对（Ed25519）
  Future<KeyPair> generateDeviceKeyPair() async {
    final keyPair = await Ed25519().newKeyPair();

    // 存储私钥到安全存储
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(await keyPair.extractPrivateKeyBytes()),
    );

    return keyPair;
  }

  // Recovery Kit（24个助记词）
  Future<String> generateRecoveryKit() async {
    final entropy = _generateEntropy(256);  // 256位熵
    final mnemonic = bip39.entropyToMnemonic(entropy);

    // 显示给用户抄写
    return mnemonic;
  }

  // 从Recovery Kit恢复
  Future<KeyPair> recoverFromMnemonic(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    return await Ed25519().newKeyPairFromSeed(seed);
  }
}
```

**密钥备份UI:**
```
┌─────────────────────────────────────┐
│  Recovery Kit 备份                  │
├─────────────────────────────────────┤
│  ⚠️ 请抄写以下24个单词               │
│     丢失此备份将无法恢复数据         │
│                                     │
│  ┌────────────────────────────┐    │
│  │ 1. abandon   2. ability    │    │
│  │ 3. able      4. about      │    │
│  │ 5. above     6. absent     │    │
│  │ ...                        │    │
│  │ 23. zoo      24. zone      │    │
│  └────────────────────────────┘    │
│                                     │
│  📋 [复制到剪贴板]                  │
│  💾 [保存为PDF]                     │
│  🖨️ [打印]                         │
│                                     │
│  ✅ 我已安全保存                    │
│  ✅ 我理解丢失后果                  │
│                                     │
│  [下一步]                           │
└─────────────────────────────────────┘
```

#### 5.2 生物识别锁（E03）

**支持的认证方式:**
- iOS: Face ID / Touch ID / PIN码
- Android: 指纹识别 / 人脸识别 / PIN码

**启动流程:**
```
App启动
  ↓
检测生物识别可用性
  ↓
显示认证界面
  ↓
用户认证
  ├─ Face ID / 指纹
  ├─ 失败3次 → 强制PIN
  └─ 成功
      ↓
    解密数据库密钥
      ↓
    初始化SQLCipher
      ↓
    进入首页
```

**实现示例:**
```dart
class BiometricLock {
  Future<bool> authenticate({
    required String reason,
  }) async {
    final localAuth = LocalAuthentication();

    // 检查设备支持
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    if (!canCheckBiometrics) {
      return _authenticateWithPIN();
    }

    // 获取可用的生物识别方式
    final availableBiometrics = await localAuth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return _authenticateWithPIN();
    }

    // 尝试生物识别
    try {
      return await localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,  // 允许PIN备用
        ),
      );
    } catch (e) {
      return _authenticateWithPIN();
    }
  }
}
```

#### 5.3 哈希链审计（D03）

**审计日志查看器:**
```
┌─────────────────────────────────────┐
│  哈希链完整性验证                    │
├─────────────────────────────────────┤
│  账本：我们的小窝                    │
│  交易总数：1,234笔                   │
│  最后验证：2026/2/3 14:30           │
│                                     │
│  验证结果：✅ 完整                   │
│                                     │
│  ┌────────────────────────────┐    │
│  │ 哈希链可视化：               │    │
│  │                             │    │
│  │ Genesis                     │    │
│  │   ↓                         │    │
│  │ tx-001 [abc123...]          │    │
│  │   ↓                         │    │
│  │ tx-002 [def456...]          │    │
│  │   ↓                         │    │
│  │ tx-003 [ghi789...]          │    │
│  │   ↓                         │    │
│  │ ...                         │    │
│  └────────────────────────────┘    │
│                                     │
│  📄 [导出审计报告PDF]               │
│                                     │
│  ⚠️ 如检测到篡改，哈希链会显示      │
│     红色警告，并标记受影响的记录     │
└─────────────────────────────────────┘
```

**PDF审计报告内容:**
```
Happy Pocket 审计报告
生成时间：2026年2月3日 14:30

账本信息：
- 账本ID：book-abc123
- 账本名称：我们的小窝
- 成员数量：2人

哈希链验证：
- 总交易数：1,234笔
- 验证状态：✅ 完整
- 首个交易：2025-12-01 09:00
- 最新交易：2026-02-03 14:30

完整哈希链：
1. tx-001 (2025-12-01 09:00)
   金额：¥1,280
   分类：食費
   哈希：abc123def456...
   前哈希：genesis

2. tx-002 (2025-12-01 11:30)
   金额：¥2,500
   分类：交通費
   哈希：def456ghi789...
   前哈希：abc123def456...

...

签名：
本报告由设备 [device-xyz] 生成
公钥指纹：AB:CD:EF:12:34:56
```

#### 5.4 隐私宣言引导（E01）

**首次启动三页引导:**

**第1页：隐私承诺**
```
┌─────────────────────────────────────┐
│                                     │
│           🔒                        │
│                                     │
│       あなたのデータは                │
│       あなただけのもの                │
│                                     │
│  • サーバーに保存されません         │
│  • 会社は見られません               │
│  • 端到端加密で保護                 │
│                                     │
│              ○ ○ ○                │
│                                     │
│                          [次へ] →  │
└─────────────────────────────────────┘
```

**第2页：防篡改承诺**
```
┌─────────────────────────────────────┐
│                                     │
│           ⛓️                        │
│                                     │
│       改ざんできない記録              │
│                                     │
│  • ブロックチェーン技術を使用       │
│  • すべての記録が暗号化              │
│  • 誰も過去を変えられません         │
│                                     │
│              ○ ○ ○                │
│                                     │
│  [戻る] ←                [次へ] →  │
└─────────────────────────────────────┘
```

**第3页：开源承诺**
```
┌─────────────────────────────────────┐
│                                     │
│           👁️                        │
│                                     │
│       透明でオープンソース            │
│                                     │
│  • コードは完全公開                 │
│  • 誰でも検証できます               │
│  • コミュニティと一緒に             │
│                                     │
│              ○ ○ ○                │
│                                     │
│  [戻る] ←              [始める] →  │
└─────────────────────────────────────┘
```

#### 5.5 验收标准
- ✅ 密钥生成成功率 100%
- ✅ Recovery Kit 24个单词正确显示
- ✅ 生物识别认证成功率 >98%
- ✅ 哈希链验证时间 <1秒（1000条记录）
- ✅ 篡改检测灵敏度 100%（修改任何字段都能检测）
- ✅ 审计报告PDF导出成功
- ✅ 隐私宣言引导完成率 >95%

---

## 开发优先级总结

### Phase 1: 核心功能（Week 1-6）
1. MOD-001/002 基础记账 + 分类管理 ✅ 已详细编写
2. MOD-003 双轨账本 📝 框架完成
3. MOD-006 安全与隐私模块 📝 框架完成

### Phase 2: 协作与数据（Week 7-10）
4. MOD-004 家庭同步 📝 框架完成
5. MOD-005 OCR扫描 📝 框架完成

### Phase 3: 趣味功能（Week 9-10，A/B测试）
6. MOD-009 趣味功能 📝 框架完成

### Phase 4: Beta测试（Week 11-12）
- 所有模块集成测试
- Bug修复
- 性能优化
- 用户反馈迭代

---

## 后续工作建议

1. **立即完成的任务:**
   - 将本框架文档扩展为5个完整PRD文档
   - 每个模块PRD包含：功能规格、数据模型、UI设计、验收标准、测试用例

2. **技术预研:**
   - CRDT库选型（Yjs vs Automerge）
   - TensorFlow Lite模型训练流程
   - SQLCipher性能测试

3. **设计工作:**
   - 和风/赛博双主题完整设计稿
   - 关键页面高保真原型
   - 动画效果Demo

4. **风险评估:**
   - 趣味功能文化接受度预调研
   - 家庭同步协议稳定性验证
   - OCR准确率baseline测试

---

**文档状态:** 框架完成
**下一步:** 基于本框架编写5个完整的模块PRD文档
