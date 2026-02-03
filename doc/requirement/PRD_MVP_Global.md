# Home Pocket MVP 全局产品需求文档

**文档版本:** 1.0
**创建日期:** 2026年2月3日
**状态:** Draft
**基于文档:** BRD_Home_Pocket_Complete.md + research_home_pocket_feasibility_strategy_20260202.md

---

## 目录

1. [产品概述](#1-产品概述)
2. [MVP范围界定](#2-mvp范围界定)
3. [核心用户价值](#3-核心用户价值)
4. [技术架构概览](#4-技术架构概览)
5. [里程碑计划](#5-里程碑计划)
6. [成功度量标准](#6-成功度量标准)
7. [风险管理](#7-风险管理)

---

## 1. 产品概述

### 1.1 产品定义

Home Pocket (まもる家計簿) 是一款面向日本家庭的**隐私优先、防篡改、趣味化**家庭记账应用。采用 Local-First 架构，通过端到端加密（E2EE）和哈希链保证数据安全与不可篡改，同时融入日本文化元素，将传统的记账转变为有趣的家庭互动体验。

### 1.2 核心差异化

| 维度 | 竞品现状 | Home Pocket 优势 |
|------|---------|-----------------|
| **信任** | 云端存储，公司可见数据 | E2EE加密，防篡改哈希链 |
| **体验** | 功能导向，枯燥记账 | 游戏化，趣味互动 |
| **关系** | 监控式共享 | 尊重隐私的家庭协作 |
| **文化** | 通用设计 | 深度融入日本文化 |

### 1.3 产品定位

**愿景声明:**
成为日本家庭财务信任与欢乐的守护者，让每一次记账都成为家庭互动的美好瞬间。

**市场定位:**
高隐私保护 + 适度自动化 + 趣味化 = 蓝海市场

### 1.4 目标用户

**主要用户画像:**
- **画像A：夫妻用户"关系守护者"** (Primary Target)
  - 年龄：25-50岁，已婚或同居伴侣
  - 收入：年收入 ¥400万+，双收入家庭
  - 痛点：经济问题易引发矛盾，缺乏财务透明但又需要个人空间
  - 付费意愿：高（关系稳定 > ¥480/月）

- **画像B：单人用户"爱好经营者"** (Secondary Target)
  - 年龄：25-45岁，单身或暂未共同理财
  - 收入：年收入 ¥350-700万
  - 痛点：爱好消费缺乏规划，容易冲动消费
  - 付费意愿：中等

**目标用户规模:**
- 主要市场（夫妻家庭）：160,000 用户
- 次要市场（单人用户）：75,000 用户
- **总计 SAM:** 235,000 用户

---

## 2. MVP范围界定

### 2.1 时间线调整

**原BRD计划:** 8周
**调整后MVP时间线:** 10-12周

**调整原因:**
- E2EE同步协议复杂度高，需要充分测试
- OCR识别准确率优化需要更多时间
- 家庭配对加密握手容易出现边界问题
- 需要预留文化适应性验证时间

### 2.2 MVP核心功能范围

#### 阶段一：核心记账（Week 1-3）
- ✅ 基础支出/收入记录
- ✅ 分类管理（预设20个分类 + 自定义）
- ✅ 交易列表与搜索
- ✅ 深色模式
- ✅ 数据本地存储（SQLCipher加密）

#### 阶段二：双轨账本与分类（Week 4-6）
- ✅ 双轨账本系统（生存/灵魂账户）
- ✅ 规则引擎自动分类（500+ 商家数据库）
- ✅ TensorFlow Lite 模式学习
- ✅ 基础数据分析（月度饼图、日历热图）
- ⚠️ **不包含** Gemini Nano（降级为V1.0 Premium功能）

#### 阶段三：隐私保护与审计（Week 7-8）
- ✅ OCR扫描（ML Kit本地识别）
- ✅ 哈希链审计日志
- ✅ 生物识别锁（Face ID/指纹/PIN）
- ✅ 密钥生成与备份

#### 阶段四：家庭协作（Week 9-10）
- ✅ 家庭配对（QR码面对面）
- ✅ 基础同步协议（定时同步，每日10次）
- ✅ 个人/家庭视图切换
- ✅ 家庭内部转账
- ⚠️ **不包含** 远程配对（降级为V1.0）

#### 阶段五：趣味功能（Week 9-10，可选A/B测试）
- ⚠️ 大谷翔平换算器（可关闭）
- ⚠️ 小票占卜/今日运势（可关闭）
- ✅ 灵魂消费庆祝动画（可关闭）

**重要决策:**
- 趣味功能在Beta测试阶段进行A/B测试
- 如果30-50岁用户接受度<60%，则从MVP移除
- 优先保证核心功能稳定性

### 2.3 明确排除功能（移至V1.0+）

| 功能 | 移至版本 | 原因 |
|------|---------|------|
| 远程配对（6位短码） | V1.0 | 需要Relay服务器，增加基础设施复杂度 |
| 实时同步推送 | V1.0 | WebSocket + FCM/APNs 需要后端支持 |
| 照片云同步 | V1.0 | S3存储成本，需要付费订阅模型 |
| Gemini Nano 集成 | V1.0 Premium | 设备限制、配额限制、iOS无等价物 |
| 互不侵犯条约 | V1.0 | 依赖双轨账本成熟后验证 |
| 灵魂提案禀议书 | V1.0 | LLM版本为Premium，离线模板版为V1.0 |
| 生存红利分红协议 | V1.0 | 复杂逻辑，需要用户习惯养成 |
| 多设备同步（3+） | V1.0 | 冲突解决复杂度 |

### 2.4 MVP功能优先级

**P0（必须有，否则无法上线）:**
- 支出/收入记录
- 分类管理
- 双轨账本
- 家庭配对（QR码）
- 基础同步
- 哈希链审计
- 密钥管理
- 生物识别锁

**P1（强烈建议，显著提升体验）:**
- OCR扫描
- 交易搜索
- 快捷输入模板（TF Lite学习）
- 商家自动分类
- 月度支出分析
- Widget快捷入口

**P2（可选，增加差异性）:**
- 大谷翔平换算器
- 运势占卜
- 灵魂庆祝动画
- 异常消费检测

---

## 3. 核心用户价值

### 3.1 用户价值主张

**对夫妻用户:**
1. **建立信任，减少冲突**
   - 防篡改技术让双方无法隐瞒或修改记录
   - 透明的家庭账本减少猜疑
   - 互不侵犯条约保护个人隐私空间

2. **趣味互动，增进感情**
   - 把枯燥的记账变成有趣的日常仪式
   - 灵魂账户赋予爱好消费正向意义
   - 共同为生存预算努力，节省部分转入灵魂账户

3. **隐私保护，安心使用**
   - E2EE加密，公司无法看到数据
   - 本地优先，不依赖云端
   - 开源代码，可审计安全性

**对单人用户:**
1. **清晰分离，可持续发展**
   - 双轨账本分离必需与享乐消费
   - 避免冲动消费导致生活困难
   - 为爱好设定合理预算

2. **自我激励，培养习惯**
   - 趣味换算增加记账乐趣
   - 可视化图表激励坚持
   - 成就系统提供正向反馈

### 3.2 核心用户旅程

**新用户首次使用（夫妻模式）:**
```
Day 0: 下载安装
  ↓
  隐私宣言引导（3页滑动）
  ↓
  生成密钥 + Recovery Kit
  ↓
  设置生物识别锁
  ↓
Day 1: 单人使用
  ↓
  记录第一笔消费
  ↓
  自动分类为生存/灵魂账户
  ↓
  查看趣味换算（如启用）
  ↓
Day 3: 家庭配对
  ↓
  与伴侣面对面扫描QR码
  ↓
  设置家庭名称（如"我们的小窝"）
  ↓
  双方数据开始同步
  ↓
Week 1: 培养习惯
  ↓
  每日记账3-5笔
  ↓
  查看家庭月度报表
  ↓
  发现伴侣的消费习惯
  ↓
Month 1: 建立信任
  ↓
  审计日志验证数据完整性
  ↓
  讨论月度预算调整
  ↓
  决定是否开启互不侵犯条约（V1.0）
```

### 3.3 成功场景示例

**场景1：避免金钱冲突**
> 田中夫妇结婚3年，妻子对丈夫购买高达模型感到不满。使用Home Pocket后，丈夫设置"高达基金"灵魂账户，预算¥30,000/月。妻子可以看到预算进度条，但看不到具体买了什么。只要不超预算，妻子不再质疑。丈夫也更自律地控制爱好消费。

**场景2：共同理财目标**
> 佐藤夫妇计划明年买房，设定家庭生存预算¥200,000/月。通过节省超市购物（买半价商品），每月节省¥20,000。根据生存红利协议（V1.0），节省金额50%转入各自灵魂账户，50%存入购房基金。夫妻都有动力省钱，且不影响个人爱好。

**场景3：单人爱好管理**
> 单身摄影师山田，每月收入¥350,000。设定生存预算¥150,000（房租、食物、交通），灵魂预算¥100,000（摄影器材、外拍旅行）。通过双轨账本清晰看到两类消费比例，避免因买镜头导致房租不够。

---

## 4. 技术架构概览

### 4.1 架构原则

1. **Local-First:** 数据优先存储在本地，同步为辅助功能
2. **E2EE (End-to-End Encryption):** 公司无法解密用户数据
3. **防篡改:** 哈希链保证历史记录不可修改
4. **开源透明:** 代码公开审计，增强信任
5. **跨平台一致性:** Flutter确保iOS/Android体验一致

### 4.2 技术栈选型

**客户端（Flutter）:**
- 语言：Dart 3.x
- 框架：Flutter 3.x
- 状态管理：Riverpod 2.x
- 本地数据库：Drift (SQLite) + SQLCipher
- 加密库：pointycastle (Ed25519, ChaCha20-Poly1305)
- OCR：ML Kit (Android), Vision Framework (iOS)
- 机器学习：TensorFlow Lite
- UI组件：Material 3 + 自定义和风/赛博主题

**服务端（MVP不包含，V1.0引入）:**
- Relay服务器：Rust + Actix-web
- 同步协议：基于 Yjs CRDT
- 部署：AWS / GCP
- 存储：S3（照片，加密后）

**开发工具:**
- CI/CD: GitHub Actions
- 测试：Flutter Test, Integration Test
- 监控：Firebase Crashlytics（本地模式）
- 分析：本地匿名化统计

### 4.3 数据架构

**本地数据库结构:**
```sql
-- 账本（Book）
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,  -- 'personal' | 'family'
  created_at INTEGER NOT NULL
);

-- 设备（Device）
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  public_key TEXT NOT NULL,
  name TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id)
);

-- 交易（Transaction）
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,  -- 'expense' | 'income' | 'transfer'
  category_id TEXT NOT NULL,
  ledger_type TEXT DEFAULT 'survival',  -- 'survival' | 'soul'
  timestamp INTEGER NOT NULL,
  note TEXT,
  photo_hash TEXT,
  prev_hash TEXT,
  current_hash TEXT NOT NULL,  -- 哈希链
  created_at INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 分类（Category）
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  ledger_type TEXT DEFAULT 'auto',  -- 'survival' | 'soul' | 'auto'
  is_system INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

-- 同步日志（Sync Log）
CREATE TABLE sync_log (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  synced_at INTEGER NOT NULL,
  sync_count INTEGER NOT NULL,
  status TEXT NOT NULL  -- 'success' | 'failed'
);
```

### 4.4 安全架构

**密钥管理:**
1. 设备密钥对（Ed25519）：首次安装时生成
2. 对称加密密钥（ChaCha20）：从密钥对派生
3. Recovery Kit：24个助记词，可恢复密钥
4. 生物识别：保护本地数据库访问

**数据加密层级:**
- L1: SQLCipher 数据库加密（256-bit AES）
- L2: 交易note字段额外加密（ChaCha20）
- L3: 照片文件加密（AES-GCM）
- L4: 同步传输加密（TLS 1.3 + E2EE）

**哈希链防篡改:**
```dart
String calculateHash(Transaction tx, String prevHash) {
  final data = '${tx.id}|${tx.amount}|${tx.timestamp}|${prevHash}';
  return sha256.convert(utf8.encode(data)).toString();
}

// 验证完整性
bool verifyHashChain(List<Transaction> transactions) {
  String prevHash = 'genesis';
  for (var tx in transactions) {
    final expectedHash = calculateHash(tx, prevHash);
    if (tx.currentHash != expectedHash) {
      return false;  // 检测到篡改
    }
    prevHash = tx.currentHash;
  }
  return true;
}
```

### 4.5 同步协议

**MVP版本：定时轮询（Simple Polling）**
```
Device A                  Device B
   │                         │
   ├─ 生成同步快照            │
   ├─ 计算增量哈希            │
   │                         │
   ├────── 蓝牙/NFC ─────────►│
   │     (传输加密数据)        │
   │                         │
   │◄────── ACK ──────────────┤
   │                         │
   ├─ 更新sync_log           │
   └─ 显示同步成功            └─ 应用变更
```

**V1.0版本：Relay中继（CRDT）**
```
Device A              Relay Server           Device B
   │                       │                      │
   ├─ CRDT操作集 ────────►│                      │
   │  (E2EE加密)           │                      │
   │                       ├──── 转发 ───────────►│
   │                       │                      │
   │                       │◄──── CRDT操作集 ─────┤
   │◄───── 转发 ───────────┤                      │
   │                       │                      │
   └─ 自动合并              └─ 不存储明文           └─ 自动合并
```

### 4.6 机器学习集成

**规则引擎（MVP，优先级P0）:**
```dart
class MerchantClassifier {
  final Map<String, String> merchantDB = {
    '吉野家': 'food_restaurant',
    'セブンイレブン': 'food_groceries',
    'JR東日本': 'transport_commute',
    // ... 500+ 商家
  };

  String? classify(String merchant) {
    return merchantDB[merchant];
  }
}
```

**TensorFlow Lite（MVP，优先级P1）:**
```dart
class TFLiteClassifier {
  // 从用户历史学习
  Future<String> predictCategory(String merchant, String note) async {
    final input = _preprocessInput(merchant, note);
    final output = await _interpreter.run(input);
    return _decodeOutput(output);
  }
}
```

**Gemini Nano（V1.0 Premium）:**
```dart
// 仅限高端Android设备 + Premium订阅
class GeminiNanoClassifier {
  Future<String> classifyWithLLM(Transaction tx) async {
    if (!await _isGeminiNanoAvailable()) {
      return _fallbackClassifier.classify(tx);
    }
    // ... LLM调用
  }
}
```

---

## 5. 里程碑计划

### 5.1 MVP开发时间线（10-12周）

**Phase 0: 验证阶段（Week 0，2周前）**
- ✅ 用户研究：访谈20-30对夫妻
- ✅ 趣味功能接受度调研
- ✅ 竞品体验分析
- ✅ 法律咨询（APPI隐私政策）
- 决策点：如果趣味功能接受度<60%，则从MVP移除

**Phase 1: 核心记账（Week 1-3）**
- Week 1:
  - 项目架构搭建
  - 设计系统实现（和风/赛博双主题）
  - 数据库模型定义
- Week 2:
  - 支出/收入记录UI
  - 分类管理系统
  - 交易列表与搜索
- Week 3:
  - 深色模式适配
  - Widget快捷入口
  - 单元测试覆盖

交付物: 单人模式可用的记账App

**Phase 2: 双轨账本（Week 4-6）**
- Week 4:
  - 双轨账本数据模型
  - 生存/灵魂账户UI设计
  - 规则引擎（500+商家数据库）
- Week 5:
  - TF Lite模型训练与集成
  - 自动分类逻辑
  - 灵魂消费庆祝动画
- Week 6:
  - 月度分析报表（饼图、热图）
  - 预算目标设定
  - 集成测试

交付物: 双轨账本完整功能

**Phase 3: 隐私保护（Week 7-8）**
- Week 7:
  - OCR扫描（ML Kit集成）
  - 商家自动分类（基于OCR结果）
  - 照片加密存储
- Week 8:
  - 哈希链审计日志
  - 密钥生成与Recovery Kit
  - 生物识别锁
  - 安全审计

交付物: 隐私保护功能完备

**Phase 4: 家庭协作（Week 9-10）**
- Week 9:
  - 家庭配对（QR码）
  - E2EE密钥交换
  - 数据同步协议（蓝牙/NFC）
- Week 10:
  - 个人/家庭视图切换
  - 家庭内部转账
  - 同步冲突解决
  - 端到端测试

交付物: 家庭模式可用

**Phase 5: 趣味功能（可选A/B测试，Week 9-10）**
- 大谷翔平换算器（3天）
- 运势占卜（2天）
- 灵魂消费动画（2天）
- A/B测试框架搭建（2天）

**Phase 6: Beta测试与打磨（Week 11-12）**
- Week 11:
  - Beta用户招募（100对夫妻）
  - 性能优化（启动速度、流畅度）
  - 异常处理完善
- Week 12:
  - Bug修复
  - 用户反馈迭代
  - App Store提审准备
  - 隐私政策、用户协议定稿

交付物: 可上线的MVP版本

### 5.2 关键决策点

**决策点1（Week 3结束）:**
- 评估核心记账功能完成度
- 如进度落后>1周，考虑削减P2功能
- 确认双轨账本设计细节

**决策点2（Week 6结束）:**
- 评估双轨账本用户接受度（内部测试）
- 如果体验不佳，考虑简化UI
- 确认是否继续开发趣味功能

**决策点3（Week 8结束）:**
- 评估OCR准确率（目标>85%）
- 如低于80%，考虑降级为V1.0功能
- 确认家庭配对技术方案

**决策点4（Week 10结束）:**
- 评估家庭同步稳定性
- 如数据丢失风险高，考虑延后发布
- 决定是否包含趣味功能

**决策点5（Week 12结束）:**
- 评估Beta测试NPS（目标>40）
- 评估D7留存率（目标>30%）
- Go/No-Go上线决策

### 5.3 Beta测试计划

**Private Beta（4周，April 2026）**
- 招募100对夫妻 + 50个单人用户
- 招募渠道：Twitter、日本创业社区、个人网络
- 测试目标：
  - D7留存 >30%
  - NPS >40
  - 配对成功率 >90%
  - 同步冲突率 <1%
  - 趣味功能使用率（如启用）>50%

**Public Beta（8周，May-June 2026）**
- TestFlight/Google Play Beta
- 目标用户：500-1,000人
- ASO优化开始
- 收集应用商店评分（目标4.5+星）

**官方发布（July 2026）**
- App Store / Google Play 全量发布
- 新闻稿：开源E2EE家庭理财应用
- 媒体目标：TechCrunch Japan, THE BRIDGE, Lifehacker Japan

---

## 6. 成功度量标准

### 6.1 MVP验证指标（Beta阶段）

| 指标 | 目标值 | 底线值 | 测量方法 |
|------|--------|--------|---------|
| Beta用户激活数 | 100 | 80 | TestFlight/Play Console |
| D7留存率 | 40% | 30% | Firebase Analytics |
| 夫妻配对成功率 | 60% | 50% | 应用内埋点 |
| NPS评分 | 50+ | 40+ | 应用内问卷（样本30+）|
| 趣味功能使用率 | 70% | 50% | Feature Flag统计 |
| 应用崩溃率 | <1% | <2% | Crashlytics |
| 平均会话时长 | 3分钟+ | 2分钟+ | Firebase |
| 月均交易笔数 | 20+笔/用户 | 15+笔/用户 | 数据库查询 |

### 6.2 V1.0成功指标（Month 4-12）

| 指标 | Q2 (Apr-Jun) | Q3 (Jul-Sep) | Q4 (Oct-Dec) | 全年目标 |
|------|--------------|--------------|--------------|---------|
| 注册用户总数 | 3,000 | 8,000 | 15,000 | 18,000 |
| 付费订阅用户 | 120 (4%) | 320 (4%) | 600 (4%) | 720 |
| MRR（月经常性收入）| ¥58K | ¥154K | ¥288K | ¥346K |
| D30留存率 | 20% | 25% | 30% | 28%平均 |
| MAU（月活跃用户）| 1,800 | 4,000 | 7,500 | 9,000 |
| App Store评分 | 4.3+ | 4.5+ | 4.6+ | 4.5平均 |
| 有机安装占比 | 60% | 75% | 85% | 80% |
| 混合CAC | ¥150 | ¥80 | ¥50 | ¥70平均 |

### 6.3 Go/No-Go决策矩阵

**继续V1.0开发的条件（至少满足6/8项）:**
- ✅ NPS >40
- ✅ D7留存 >30%
- ✅ 配对成功率 >50%
- ✅ 应用评分 >4.0
- ✅ 崩溃率 <2%
- ✅ 用户月均交易 >15笔
- ✅ Beta用户主动推荐率 >20%
- ✅ 竞品对比优势明确

**需要Pivot的信号:**
- 🟡 NPS <30（产品未引起共鸣）
- 🟡 配对率 <40%（核心场景失败）
- 🟡 趣味功能使用率 <30%（文化排斥确认）
- 🟡 负面反馈主题集中（如"太幼稚"、"不信任加密"）

**停止开发的条件:**
- 🔴 D7留存 <20%（根本性产品失败）
- 🔴 崩溃率 >5%（技术债务不可持续）
- 🔴 安全漏洞无法修复
- 🔴 用户反馈压倒性负面

---

## 7. 风险管理

### 7.1 关键风险识别

| 风险 | 概率 | 影响 | 严重等级 | 缓解措施 |
|------|------|------|---------|---------|
| 趣味功能文化排斥 | 40% | 高 | 🔴 严重 | A/B测试，可关闭开关，准备专业模式 |
| MVP时间线延误（>12周）| 50% | 中 | 🟡 高 | 预留2-4周缓冲，削减P2功能 |
| E2EE同步数据丢失 | 30% | 高 | 🔴 严重 | 使用成熟CRDT库（Yjs），充分测试 |
| 免费转付费率<2% | 35% | 高 | 🔴 严重 | 调整免费档限制，增强Premium价值 |
| Gemini Nano设备不兼容 | 60% | 中 | 🟡 高 | 降级为规则引擎+TF Lite，iOS备选方案 |
| 合作伙伴获客慢 | 40% | 中 | 🟡 高 | 直接销售推广，开发案例研究 |
| 开源代码被克隆 | 50% | 中 | 🟡 高 | AGPL许可，品牌差异化，云服务锁定 |
| ASO排名无改善 | 30% | 中 | 🟡 高 | 投资评论生成，付费ASA广告 |
| 目标市场规模过小 | 25% | 高 | 🔴 严重 | 扩展到单身、自由职业者细分市场 |

### 7.2 风险应对计划

**风险1：趣味功能文化排斥**

触发条件:
- Beta测试NPS <30
- 用户反馈"幼稚"、"不严肃"、"不尊重"
- 启用趣味功能后留存率下降

应对措施:
1. 预发布用户访谈（20-30对夫妻）
2. A/B测试框架（对照组无趣味功能）
3. 所有趣味功能设置可关闭开关
4. 准备"专业模式"作为后备方案

Fallback: 如果普遍排斥，转为"数字Kakeibo 2.0"定位，移除所有趣味元素

**风险2：MVP时间线延误**

触发条件:
- Week 4里程碑未达成
- E2EE同步协议开发超过6天
- OCR准确率<75%

应对措施:
1. 功能削减优先级：
   - 第一削减：Gemini Nano（改用规则引擎）
   - 第二削减：远程家庭配对（仅保留QR码）
   - 第三削减：运势占卜
   - 第四削减：灵魂提案离线模板
   - 永不削减：双轨账本、E2EE、OCR、基础同步
2. 库替代方案：
   - 自研CRDT失败 → 使用Yjs
   - SQLCipher问题 → 使用Hive + 加密
   - ML Kit OCR不佳 → Firebase ML Vision云端回退
3. 团队增援：
   - Week 4进度滞后 → 雇佣合同Flutter开发者（¥500K/月）
   - 优先加密/分布式系统经验

应急预算: ¥1-2M

**风险3：E2EE同步数据丢失**

触发条件:
- Beta用户报告"交易消失"
- 冲突解决产生重复记录
- 家庭同步状态不一致

应对措施:
1. 使用经过验证的CRDT库（Yjs或Automerge）
2. 仅追加事件日志（不删除交易，仅追加修正）
3. 哈希链保证不可变性，易于检测损坏
4. 检测到同步冲突时显示双方版本（手动解决）
5. 本地备份策略：
   - 每日加密JSON导出到设备存储
   - 用户随时可手动导出
   - 灾难恢复时从备份还原
6. 测试策略：
   - 混沌测试：模拟网络中断、时钟偏差
   - 多设备测试：3+设备同时同步
   - Beta要求：至少50个家庭同步30+天

Fallback: 如果E2EE同步过于不稳定，V1.0发布**无家庭同步版本** → 仅本地模式，手动CSV导出/导入共享

### 7.3 应急预案

**预案A：文化适应性失败**
- 条件：30-50岁用户对趣味功能接受度<40%
- 行动：
  1. 立即关闭趣味功能默认状态
  2. 重新定位为"现代数字Kakeibo"
  3. 强调隐私与防篡改技术
  4. 增加传统Kakeibo元素（手写笔记、季节装饰）

**预案B：技术债务过载**
- 条件：崩溃率>5%，安全漏洞频发
- 行动：
  1. 暂停新功能开发
  2. 2周技术债务清理Sprint
  3. 引入外部安全审计
  4. 延后上线时间，不妥协质量

**预案C：市场规模过小**
- 条件：Year 1注册用户<10,000
- 行动：
  1. 扩展目标细分市场（单身、自由职业者、学生）
  2. 调整营销信息
  3. 探索B2B白标市场（咨询师、理财规划师）
  4. 考虑国际扩展（台湾、香港、韩国）

### 7.4 质量保证

**测试策略:**
1. 单元测试覆盖率 >80%
2. 集成测试：所有关键用户旅程
3. 端到端测试：100+自动化场景
4. 安全测试：
   - 密码学实现审计
   - 密钥管理渗透测试
   - 哈希链完整性验证
5. 性能测试：
   - 10,000+交易记录加载时间 <2秒
   - 首次启动时间 <3秒
   - 同步1,000条记录 <10秒

**代码审查:**
- 所有PR需要至少1人审查
- 安全相关代码需要2人审查
- 定期代码质量扫描（SonarQube）

**Beta测试协议:**
- Private Beta: 100用户，4周，密集反馈
- Public Beta: 500-1,000用户，8周
- Bug Bounty: 安全漏洞奖励计划（¥10,000-100,000）

---

## 8. 附录

### 8.1 术语表

| 术语 | 定义 |
|------|------|
| E2EE | End-to-End Encryption，端到端加密 |
| CRDT | Conflict-free Replicated Data Type，无冲突复制数据类型 |
| OCR | Optical Character Recognition，光学字符识别 |
| TF Lite | TensorFlow Lite，移动端机器学习框架 |
| ASO | App Store Optimization，应用商店优化 |
| NPS | Net Promoter Score，净推荐值 |
| MAU | Monthly Active Users，月活跃用户 |
| D7/D30留存 | Day 7 / Day 30 Retention，7日/30日留存率 |
| CAC | Customer Acquisition Cost，客户获取成本 |
| LTV | Lifetime Value，客户生命周期价值 |
| MRR | Monthly Recurring Revenue，月经常性收入 |

### 8.2 参考文档

1. BRD_Home_Pocket_Complete.md - 商业需求文档
2. research_home_pocket_feasibility_strategy_20260202.md - 可行性研究报告
3. PRD_MVP_App.md - App端详细PRD
4. PRD_MVP_Server.md - Server端详细PRD（V1.0）
5. PRD_Module_*.md - 各功能模块详细PRD

### 8.3 版本历史

| 版本 | 日期 | 变更说明 | 作者 |
|------|------|---------|------|
| 1.0 | 2026-02-03 | 初始版本，基于BRD和研究报告 | Claude Sonnet 4.5 |

---

**文档状态:** Draft
**需要评审:** 产品团队、技术团队、法律合规
**下一步行动:** 细化各模块PRD，开始Phase 0用户验证
