# Architecture Decision Records (ADR) 索引

**项目:** Home Pocket MVP
**最后更新:** 2026-05-04

---

## 📋 ADR概述

Architecture Decision Records (ADR) 记录了项目中的重要架构决策,包括背景、备选方案分析、最终决策及理由。

---

## 📚 ADR列表

### [ADR-001: 选择Riverpod作为状态管理方案](./ADR-001_State_Management.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 整个应用的状态管理层

**核心决策:**
选择 **flutter_riverpod 2.x** 作为状态管理方案

**关键理由:**
- 编译时类型安全
- 自动依赖注入
- 优秀的DevTools支持
- 代码生成减少样板代码
- 测试友好

**备选方案:**
- flutter_bloc (样板代码过多)
- GetX (类型安全性差)
- Provider (功能较弱)

**下次Review:** 2026-08-03

---

### [ADR-002: 选择Drift+SQLCipher作为数据库方案](./ADR-002_Database_Solution.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 数据持久化层、安全架构

**核心决策:**
选择 **Drift + SQLCipher** 组合

**关键理由:**
- 类型安全的SQL查询(编译时检查)
- 透明的数据库级加密(SQLCipher)
- 优秀的迁移支持
- 成熟的生态和活跃维护

**备选方案:**
- Hive + 自定义加密 (NoSQL限制,自定义加密风险)
- Isar (生态不成熟)
- sqflite + SQLCipher (无类型安全)

**安全特性:**
- AES-256-CBC加密
- PBKDF2密钥派生(256,000次迭代)
- FIPS 140-2验证

**下次Review:** 2026-08-03

---

### [ADR-003: 多层加密策略](./ADR-003_Multi_Layer_Encryption.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 整个应用的数据安全层

**核心决策:**
采用 **4层纵深防御加密策略**

**加密层次:**

| 层级 | 技术 | 范围 | 算法 |
|------|------|------|------|
| Layer 1 | SQLCipher | 数据库文件 | AES-256-CBC |
| Layer 2 | cryptography | 敏感字段 | ChaCha20-Poly1305 |
| Layer 3 | cryptography | 照片文件 | AES-256-GCM |
| Layer 4 | 自定义E2EE | 设备间同步 | ChaCha20-Poly1305 |

**密钥管理:**
- 主密钥 → HKDF派生专用密钥
- iOS Keychain / Android KeyStore存储
- Ed25519设备密钥对

**安全标准:**
- ✅ FIPS 140-2验证
- ✅ OWASP移动应用安全标准
- ✅ GDPR合规

**下次Review:** 2026-05-03 (每季度)

---

### [ADR-004: 选择Yjs-inspired CRDT方案](./ADR-004_CRDT_Sync.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 家庭同步功能(MOD-004)

**核心决策:**
选择 **Yjs-inspired CRDT (Last-Write-Wins + 向量时钟)**

**关键理由:**
- 自动冲突解决,无需用户介入
- 向量时钟精确检测并发
- 最终一致性保证
- P2P友好,无需中央服务器
- 生产验证(Yjs广泛使用)

**核心机制:**
- **向量时钟:** 追踪因果关系
- **Lamport时间戳:** 全局顺序
- **Last-Write-Wins:** 冲突解决策略
- **墓碑(Tombstone):** 处理删除

**备选方案:**
- Operational Transformation (实现极其复杂)
- 简单LWW (时钟漂移问题)
- 三路合并 (存储开销大)

**限制:**
- LWW可能丢失并发修改
- 向量时钟膨胀(需定期清理)
- 删除需要墓碑(软删除)

**下次Review:** 2026-08-03

---

### [ADR-005: OCR和ML技术选型](./ADR-005_OCR_ML_Tech.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** OCR扫描功能(MOD-005), 智能分类功能(MOD-003)

**核心决策:**

#### OCR方案: 平台原生OCR
- **Android:** ML Kit Text Recognition v2
- **iOS:** Vision Framework

**关键理由:**
- 免费,无API成本
- 本地处理,隐私保护
- 准确率高(>90%)
- 零维护成本

#### 智能分类方案: 三层引擎

**MVP阶段:**
- Layer 1: 规则引擎 (100%准确率,70%覆盖率)
- Layer 2: 商家数据库 (85%准确率,20%覆盖率)
- 默认: 保守策略(生存账本)

**V1.0阶段:**
- Layer 3: TFLite自训练模型 (75-85%准确率)

**备选方案:**
- TFLite自训练OCR (训练成本高)
- 云端OCR API (违反隐私原则)
- Gemini Nano (设备兼容性差,移至Premium功能)

**性能指标:**
- OCR准确率: 90-95%
- OCR响应时间: 1-2秒
- 分类准确率: 85-90%
- 分类响应时间: <50ms

**下次Review:** 2026-08-03

---

### [ADR-006: 密钥派生安全修复](./ADR-006_Key_Derivation_Security.md)

**状态:** ✅ 已实施
**日期:** 2026-02-03
**影响范围:** 安全架构、密钥管理、数据库加密

**核心决策:**
修复HKDF密钥派生的安全问题，实现数据库密钥缓存

**修复内容:**

#### 1. HKDF salt配置修复
- **问题:** 使用空salt (`nonce: []`)降低安全性
- **修复:** 使用固定应用特定salt (`homepocket-v1-2026`)
- **理由:** 符合RFC 5869标准，确保确定性派生

#### 2. 数据库密钥缓存
- **问题:** 每次都重新派生密钥，性能差
- **修复:** 实现内存缓存机制
- **性能提升:** 500倍（5ms → 0.01ms）

#### 3. 确定性派生保证
- **机制:** 相同主密钥+固定salt+相同info → 相同派生密钥
- **用途:** 支持Recovery Kit恢复、密钥轮换

**安全影响:**
- ✅ 符合密码学标准
- ✅ 增强密钥派生安全强度
- ✅ 降低密钥碰撞风险
- ✅ 显著提升性能

**实施文件:**
- `arch2/02_Data_Architecture.md` (数据库密钥缓存)
- `arch2/03_Security_Architecture.md` (HKDF修复+最佳实践)

**下次Review:** 2026-05-03 (每季度，安全相关)

---

### [ADR-007: 架构层职责划分](./ADR-007_Layer_Responsibilities.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 整体架构、Clean Architecture实施

**核心决策:**
明确Clean Architecture各层职责边界，规范层间依赖关系

**关键职责划分:**
- **Presentation:** UI渲染、用户交互、Provider监听
- **Business Logic:** 业务逻辑、Use Cases、状态管理
- **Domain:** 实体模型、Repository接口、业务规则
- **Data:** Repository实现、DAO、数据源
- **Infrastructure:** 加密、ML、平台服务

**依赖规则:**
- 依赖方向：外层 → 内层
- 核心不依赖外层
- 使用依赖注入解耦

**下次Review:** 2026-08-03

---

### [ADR-008: 账本余额更新策略优化](./ADR-008_Book_Balance_Update_Strategy.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** Data Layer, Repository Pattern, Performance

**核心决策:**
采用 **增量更新 + 修复机制** 替代全量计算

**问题分析:**
1. **数据一致性风险:** 交易插入成功但余额更新失败
2. **性能问题:** 每次交易都重新计算所有交易总和
3. **并发冲突风险:** 多设备同步时可能产生竞态条件

**解决方案:**
- **增量更新:** 仅计算变化的金额（O(1) 时间复杂度）
- **事务包装:** 交易操作和余额更新在同一事务中
- **修复机制:** 提供 `recalculateBalance()` 和 `verifyBalance()`

**性能提升:**
- 单笔交易: 200ms → 5ms (40x)
- 1000笔交易: 200秒 → 5秒 (40x)
- 批量导入: 3.3分钟 → 5秒 (40x)

**实施计划:**
- Phase 1-2: 修改 Repository 实现（2周）
- Phase 3-4: 单元测试和集成测试（2周）
- Phase 5-9: UI集成、文档更新、上线（2周）

**下次Review:** 实施完成后进行效果评估

---

### [ADR-009: 增量哈希链验证策略](./ADR-009_Incremental_Hash_Chain_Verification.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** Security Layer, Performance, Hash Chain Integrity

**核心决策:**
采用 **增量验证 + 检查点机制** 替代全量验证

**问题分析:**
1. **内存问题:** 全量加载所有交易到内存，大账本（>10,000笔）会导致内存溢出
2. **性能问题:** SHA-256 计算阻塞 UI，10,000 笔交易需要 20 秒+
3. **用户体验问题:** 应用启动、同步后长时间卡顿
4. **电池消耗:** 大量 CPU 计算导致电池快速消耗

**解决方案:**
- **检查点机制:** 记录已验证交易的位置
- **增量验证:** 仅验证自上次检查点以来的新交易（通常 <100 笔）
- **定期完整验证:** 每周后台异步进行完整验证
- **智能验证:** 根据情况自动选择验证策略

**性能提升:**
- 1,000 笔: 2秒 → 200ms (10x)
- 10,000 笔: 20秒 → 200ms (100x)
- 100,000 笔: 200秒+ → 200ms (1000x+)

**安全性保证:**
- 增量验证覆盖所有新交易
- 定期完整验证确保整体完整性
- 检查点机制确保连续性

**实施计划:**
- Phase 1-2: 数据库扩展 + Repository 接口（2周）
- Phase 3-4: 增量验证实现 + 集成测试（2周）
- Phase 5-9: UI集成、后台调度、文档更新、上线（2周）

**下次Review:** 实施完成后进行效果评估

---

### [ADR-010: CRDT 冲突解决策略增强](./ADR-010_CRDT_Conflict_Resolution_Strategy.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** Family Sync (MOD-003), CRDT Implementation, Data Integrity

**核心决策:**
采用 **向量时钟 + 因果关系判断** 策略，替代简化的 Last-Write-Wins

**问题分析:**
1. **数据丢失风险:** 并发修改会丢失数据（一方的修改被覆盖）
2. **时钟漂移问题:** 依赖设备时间（时钟漂移导致错误判断）
3. **无法处理字段级冲突:** 整个对象级别覆盖，无法精确到字段
4. **缺少冲突通知:** 用户不知道发生了冲突

**解决方案:**
- **向量时钟:** 使用逻辑时钟精确判断因果关系，不依赖设备时间
- **字段级合并:** 针对不同字段使用不同的合并策略
- **冲突记录:** 记录所有冲突历史，可追溯
- **批量通知:** 同步完成后汇总通知冲突

**关键决策:**
- ✅ **金额并发冲突:** 转为用户手动解决（确保数据准确）
- ✅ **删除冲突:** 恢复交易并标记为"曾被删除"（保留数据）
- ✅ **冲突通知时机:** 批量通知（同步完成后汇总，避免频繁打扰）
- ✅ **向量时钟清理:** 不清理（存储开销极低 <$0.0001/年/用户）

**存储开销:**
- 二进制格式: 38-70 bytes/交易
- 10,000 笔交易: 540 KB
- 成本: <$0.0001/年/用户
- ROI: 8,333x（收益远大于成本）

**实施计划:**
- Phase 1-2: 数据模型扩展 + 向量时钟实现（2周）
- Phase 3-4: 冲突解决实现 + 冲突记录和通知（2周）
- Phase 5-6: 集成测试 + 文档更新（1周）

**下次Review:** 实施完成后进行效果评估

---

### [ADR-011: Codebase Cleanup Initiative Outcome](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

**状态:** ✅ 已接受
**日期:** 2026-04-27 (1.0); 2026-04-28 (1.1 — append-only Update: Re-audit Outcome)
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施

**核心决策:**
记录 Phases 3–6 重构的最终状态、`*.mocks.dart` 策略、以及永久性 CI 守门机制。1.1 追加章节记录 Phase 8 重审计结果（resolved=50, regression=0）、覆盖率门限 80%→70% 修订、Gate 2/8 收口（`--no-fatal-infos` + `--deferred` 机制），以及 smoke-test 执行延迟到 v1 release（FUTURE-QA-01）。

**关键理由:**
- Phase 3-6 完成 87 项 finding 修复（CRITICAL/HIGH/MEDIUM/LOW 全部关闭）
- Mocktail big-bang 替换 mockito（Phase 4-04）
- 4 项常驻 CI 守门：import_guard / riverpod_lint (custom_lint --no-fatal-infos) / coverde 单文件 ≥70% (with --deferred 机制) / sqlite3_flutter_libs 拒绝
- 全部 8 项 EXIT-04 gates 同时通过（`64 checked / 0 failed / 96 missing-from-lcov skipped / 10 deferred skipped` at threshold 70）

**备选方案:**
- 不写 ADR（拒绝：未来贡献者无法理解 CI 守门动机）
- 拆为多份 ADR（拒绝：三个子主题强相关，分拆失去整体性）

**下次Review:** 2026-10-27 (每半年; 含 FUTURE-TOOL-03 覆盖率基线复审 + FUTURE-QA-01 smoke-test 签收)

---

### [ADR-012: No Gamification v1.1](./ADR-012_No_Gamification_v1_1.md)

**状态:** 📝 草稿
**日期:** 2026-05-01
**影响范围:** v1.1 happiness metric surfaces (HomePage, AnalyticsScreen), product roadmap, future feature reviews

**核心决策:**
v1.1 milestone 期间禁止任何形式的游戏化激励机制（streaks / badges / daily targets / cross-period delta / public sharing / per-member breakdown）

**关键理由:**
- Goodhart's Law 防御：metric 不能成为 target
- 家庭场景反比较伦理
- 保持 v1.1 数据基线对 v1.2 调优有效

**备选方案:**
- 温和游戏化（拒绝：不是稳定平衡点，会蔓延为 badges / leaderboard）
- 用户 opt-in 设置（拒绝：会引入 UI surface 与代码路径，强化游戏化是合理选项的认知）

**Forbidden Features (Permanent):**
Streaks, badges, daily targets, cross-period delta, public sharing, per-member breakdown

**下次Review:** v1.2 milestone start

---

### [ADR-013: Joy Density PTVF Scaling](./ADR-013_Joy_Density_PTVF_Scaling.md)

**状态:** 📝 草稿
**日期:** 2026-05-01
**影响范围:** v1.1 happiness metric layer (HAPPY-02), AnalyticsDao 性能预算

**核心决策:**
HAPPY-02 Joy/¥ 密度采用 Kahneman-Tversky PTVF α=0.88，币种相关 base（JPY=500 / CNY=25 / USD=5），Dart 层折叠。

**关键理由:**
- K-T 1979 实证拟合常数（诺贝尔背书）
- 满足"sat=10 ¥10000 击败 sat=6 ¥500"且"10 仍是天花板"双约束（α 临界 ≈ 0.83）
- SQLite 无 POW/EXP，DAO 必须改回行级查询，但月度 soul tx 10-100 行下性能可接受

**备选方案:**
- 朴素 Σsat/Σamount（小金额完全主导）
- sqrt α=0.5（压平太快）
- log Weber-Fechner（amount→0 发散）

**下次Review:** v1.2 milestone start 或月度 soul tx 数中位数 > 1000

---

### [ADR-014: Soul Satisfaction Unipolar Positive Scale](./ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md)

**状态:** 📝 草稿
**日期:** 2026-05-01
**影响范围:** 数据库 schema (v15→v16), 灵魂账本满足度语义, picker UI, voice 估算器（v1.2 重新对齐）

**核心决策:**
满足度 1-10 由"双向中央对称"改为"单极正向"——schema 默认值 5 → 2，每笔 soul 交易至少处于"中性"级别。

**关键理由:**
- 产品哲学："让用户的每一笔灵魂支出都是幸福的"
- 消除默认值 5 带来的中位簇污染
- 预上线状态，schema 迁移成本低
- 跨模态不一致（voice [3,10] vs picker post-remap）接受为短期妥协，v1.2 修复

**延迟项:**
- Phase 12: 5 个 emoji ARB 标签 + picker 图标 (`sentiment_very_dissatisfied` → `sentiment_neutral`)
- v1.2: voice 输出区间对齐

**下次Review:** v1.2 milestone start

---

### [ADR-015: 词汇分层 v1.1](./ADR-015_Lexical_Hierarchy_v1_1.md)

**状态:** 📝 草稿
**日期:** 2026-05-04
**影响范围:** v1.1 milestone UI copy register (ja/zh/en); product-vs-documentation lexical separation; CN family-mode naming; JP picker-label wellbeing register

**核心决策:**
三层 lexical hierarchy: 文档 register 用 「幸福/happiness/ハピネス」; 产品 UI register 用 「悦己/Joy/ときめき」; KPI 数学密度标题 (`homeHappinessROI` 「幸福密度/Joy per ¥/ハピネス密度」) 是产品 UI 中保留 「幸福/Happiness」字样的唯一例外 (PTVF 数学语义 — ADR-013)。CN family-mode 标题 MUST 使用 「家族的小确幸 / 家族の小確幸 / Family Joy」 NOT 「家族悦己」 (与 personal `soulLedger` 「悦己账本」 命名碰撞)。JP picker 等级标签使用全 kanji wellbeing ladder「無難 → 快適 → 順調 → 満足 → 至福」, 与 `ときめき帳 / 日々の帳` 和風文学 register 同列。

**关键理由:**
- Anti-Goodhart 防御 (ADR-012 互证): 「幸福」 在产品 UI 中会激发 self-judgment / leaderboard 心智模型
- CN family-mode 反碰撞: post-rename `soulLedger` zh=「悦己账本」 使 「家族悦己」 读作 "家庭是某用户的私人灵魂账户", 破坏双轨账本语义
- JP picker val=2 register: ADR-014 Path B 锁定 emoji-1 不可再传递负面情绪, val=2 标签必须读作 "wellbeing-baseline" 而非 「中性」 (哲学/物理学 register) 或 「フラット」 (片假名现代 register, 与 和風 anchor 不一致)

**不在本 ADR 范围 (D-08 binding):**
- ❌ 不重新决议 ADR-014 Path B unipolar-positive scale (default 5→2) — 已锁
- ❌ 不重新决议 HAPPY-08 5-emoji ↔ {2,4,6,8,10} value mapping — Phase 9 picker test 已锚
- ❌ 不覆盖 voice estimator [3,10] 重对齐 — ADR-014 D-12 / HAPPY-V2-03 deferred 到 v1.2

**Append-only:**
未来的 lexical hierarchy 修订必须以 `## Update YYYY-MM-DD: <topic>` 章节追加, 不修改原决议正文。

**下次Review:** v1.2 milestone start

---

## 🔗 ADR关系图

```
ADR-001 (Riverpod)
   ↓ 集成
ADR-002 (Drift+SQLCipher) ←─────────┐
   ↓ 加密                          │
ADR-003 (多层加密)                   │
   ↓ 密钥派生                      │ 修复
ADR-006 (密钥派生安全) ──────────────┘
   ↓ 同步
ADR-004 (CRDT) ──────────────────────┐
   ↓ 增强                           │
ADR-010 (向量时钟冲突解决) ──────────┘

ADR-005 (OCR+ML)
   ↓ 使用
ADR-001 (Riverpod)
   ↓ 存储
ADR-002 (Drift)

ADR-008 (余额更新优化) ──→ ADR-002 (Drift)
ADR-009 (哈希链验证优化) ─→ ADR-003 (安全)
```

---

## 📊 决策统计

| 状态 | 数量 |
|------|------|
| ✅ 已接受 | 10 |
| ✅ 已实施 | 1 |
| 🔄 讨论中 | 0 |
| ❌ 已拒绝 | 0 |
| 📝 草稿 | 4 |

**总计:** 15个ADR

---

## 🎯 下次Review计划

| ADR | 下次Review日期 | 频率 |
|-----|---------------|------|
| ADR-001 | 2026-08-03 | 每6个月 |
| ADR-002 | 2026-08-03 | 每6个月 |
| ADR-003 | 2026-05-03 | 每3个月(安全) |
| ADR-004 | 2026-08-03 | 每6个月 |
| ADR-005 | 2026-08-03 | 每6个月 |
| ADR-006 | 2026-05-03 | 每3个月(安全) |
| ADR-007 | 2026-08-03 | 每6个月 |
| ADR-008 | 实施完成后 | 一次性评估 |
| ADR-009 | 实施完成后 | 一次性评估（性能+安全） |
| ADR-010 | 实施完成后 | 一次性评估（数据完整性） |
| ADR-011 | 2026-10-27 | 每6个月 |
| ADR-012 | v1.2 milestone start | 一次性评估 |
| ADR-013 | v1.2 milestone start 或月度 soul tx 数中位数 > 1000 | 一次性评估 |
| ADR-014 | v1.2 milestone start | 一次性评估 |
| ADR-015 | v1.2 milestone start | 一次性评估 |

---

## 📝 ADR模板

创建新ADR时使用以下模板:

```markdown
# ADR-XXX: [决策标题]

**状态:** 🔄 讨论中 / ✅ 已接受 / ❌ 已拒绝
**日期:** YYYY-MM-DD
**决策者:** [决策团队]
**影响范围:** [影响的模块/层]

---

## 背景与问题陈述

### 业务需求
...

### 技术要求
...

---

## 决策驱动因素

### 关键考虑因素
1. ...
2. ...

---

## 备选方案分析

### 方案1: [方案名称] ✅ (选择)

**优势:**
- ✅ ...

**劣势:**
- ⚠️ ...

---

### 方案2: [方案名称]

**为何不选择:**
...

---

## 最终决策

**选择 [方案名称]**

### 核心理由
1. ...

---

## 实施计划

...

---

## 后果分析

### 正面影响
...

### 负面影响
...

---

## 相关决策

- ADR-XXX: ...

---

## 参考资料

...

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| YYYY-MM-DD | 1.0 | 初始版本 | ... |

---

**文档维护者:** ...
**审核者:** ...
**下次Review日期:** ...
```

---

## 🔄 ADR流程

### 1. 提出ADR

当遇到以下情况时,应创建ADR:

- 技术栈选型
- 架构模式选择
- 关键设计决策
- 第三方库选择
- 安全策略制定

### 2. 讨论与评审

- 技术团队讨论
- 备选方案分析
- 原型验证(如需要)

### 3. 决策与记录

- 确定最终方案
- 记录决策理由
- 文档化备选方案

### 4. 实施与跟踪

- 按计划实施
- 跟踪实施进度
- 记录实际效果

### 5. 定期Review

- 按频率Review
- 评估决策有效性
- 必要时更新或废弃

---

## 📞 联系方式

**ADR维护者:** 技术架构团队
**Email:** architecture@homepocket.com
**Slack:** #architecture-decisions

---

**最后更新:** 2026-05-04
**文档版本:** 1.4
