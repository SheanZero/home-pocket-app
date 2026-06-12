# ADR-020: 多币种 — appliedRate 存为 TextColumn 全精度字符串

**文档编号:** ADR-020
**文档版本:** 1.0
**创建日期:** 2026-06-12
**最后更新:** 2026-06-12
**状态:** ✅ 已接受
**决策者:** zxsheanjp@gmail.com (project owner) + Claude Sonnet 4.6 (planning agent)
**影响范围:** v1.7 多币种 — transactions 表 appliedRate 列类型；currency_conversion 工具函数；所有外币金额计算路径
**相关 ADR:** ADR-021 (Hash Chain Scope — appliedRate 排除在 hash 外)；ADR-022 (Edit Semantics — D-05 numeric comparison)

> **本 ADR 已 ratify 于 2026-06-12。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-12)
**触发来源:** Phase 40 (STORE-01, STORE-02) — v1.7 多币种数据与同步基础
**Ratify 路径:** 锁定决策 D-04，源自 CONTEXT.md Phase 40 讨论

---

## 🎯 背景 (Context)

### 业务需求

v1.7 多币种功能需要在 transactions 表中记录交易时使用的汇率（`appliedRate`），以便：
1. 在编辑页面准确还原原始换算参数（原币金额 × 汇率 = 日元金额）
2. 支持对历史交易的汇率来源审计
3. 允许 P2P sync 中对端设备无损重建换算结果

### 技术背景

SQLite 的 REAL 类型底层为 64 位 IEEE 754 浮点数（double），对 4–6 位小数汇率（如 `157.3421` JPY/USD）有精度损失风险：

- 存储路径：`double rate = 157.3421` → SQLite REAL → 读取时为 `157.34209999999997`（典型例子）
- 重算路径：`(originalAmount * retrievedRate).round()` 的舍入结果可能与预览时 `(originalAmount * originalRate).round()` 不同
- 结果：用户预览确认的日元金额（如 ¥23,600）与数据库实际存储的金额（¥23,601）出现 1 日元偏差

**参见 PITFALLS.md Pitfall 1**（Float Arithmetic for Money and Rate Precision）。

### 现有代码模式

transactions 表所有列均为 `TextColumn` 或 `IntColumn`，无 `RealColumn` 先例：
- `merchant` → `TextColumn`
- `photoHash` → `TextColumn`
- `amount` → `IntColumn`（JPY 整数）

`RealColumn` 在 transactions 表中从未使用，采用 `TextColumn` 与现有代码模式完全一致。

**要求对标：** STORE-01（appliedRate 持久化）、STORE-02（originalAmount/originalCurrency/appliedRate 并存）

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A: RealColumn (double) — 未选

```dart
// ❌ 未选
RealColumn get appliedRate => real().nullable()();
```

**优势:**
- 算术运算直接使用，无需 parse
- Drift 原生支持

**劣势:**
- ⚠️ 精度损失：4–6 位小数汇率在 double 往返后可能改变末位
- ⚠️ 预览 vs 存储的舍入不一致问题（Pitfall 1）
- ⚠️ 违反"transactions 无 RealColumn"的已有约定

---

### 方案 B: TextColumn (string literal，全精度) — **已选** ✅

```dart
// ✅ 选中
TextColumn get appliedRate => text().nullable()();
```

**优势:**
- 无精度损失：汇率字符串原样往返（"157.3421" → 存储 → 读取 → 仍为 "157.3421"）
- 与 merchant/photoHash 等 TextColumn 字段同构，sync mapper 无需特殊处理
- 人类可读：DB 检查时汇率值直接可见，便于审计
- 唯一 parse 点：仅在 `convertToJpy()` 工具函数中执行 `double.parse(appliedRate)`，集中可控

**劣势:**
- 算术运算前需要 `double.parse()`（但被封装在单一工具函数中，调用方无感知）

---

### 方案 C: IntColumn（scaled integer，如 × 1,000,000）— 未选

```dart
// ❌ 未选
IntColumn get appliedRate => integer().nullable()();
// 存储时：(rate * 1000000).round()；读取时：value / 1000000
```

**优势:**
- 固定精度，无 parse 需本
- 整数运算精确

**劣势:**
- ⚠️ 引入 scale 常量（1e6），所有调用方需了解此约定
- ⚠️ 超出 6 位小数的汇率（如某些加密货币）会损失精度
- ⚠️ Sync wire 需要额外 scale/unscale 转换，不如 string 直接

---

## ✅ 最终决策 (Decision)

**采用方案 B：TextColumn for appliedRate（决策 D-04）**

### 类型约定（跨层一致）

| 层次 | 类型 | 示例值 |
|------|------|--------|
| Drift 列定义 | `TextColumn get appliedRate => text().nullable()()` | — |
| Freezed 字段 | `String? appliedRate` | `"157.3421"` |
| Sync wire (JSON) | `String` (字符串字面量) | `"157.3421"` |
| 唯一 parse 点 | `double.parse(appliedRate!)` | 仅在 `convertToJpy()` 内部 |

### 保存语义（决策 D-05）

- **原样保存，不规范化：** API 来源存 JSON 数字的十进制字面量（如 `"157.3421"`），手动输入存用户原文（trim 后）
- **有效性校验：** 可解析为正 double；拒绝空字符串、非数字、零、负数、科学计数法
- **比较用数值比较：** `double.parse(a) > double.parse(b) * 1.01`（D-03 的 >1% 变化检测），不做字符串比较

---

## 📖 理由 (Rationale)

1. **防止预览 vs 存储的日元金额偏差：** TextColumn 保证汇率字符串完整往返，消除 double 精度损失引起的舍入不一致（Pitfall 1 完全规避）
2. **与现有 transactions 列模式一致：** TextColumn 是 transactions 表的唯一非 IntColumn 模式，RealColumn 引入会破坏此约定
3. **Sync mapper 无需特殊处理：** 与 `merchant`/`photoHash` 同构的 `if (x != null) 'field': x` 条件透传模式直接复用
4. **单一 parse 点：** 将 `double.parse` 限制在 `convertToJpy()` 工具函数内，所有调用方不感知底层类型，未来如需切换为 Decimal 库也只改一处
5. **审计友好：** DB 检查工具中汇率值人类直接可读（`"157.3421"` vs `157.34209999999997`）

---

## ⚠️ 后果 (Consequences)

### 正面影响

- 日元金额派生结果确定性：preview = stored，hash chain 不会因汇率精度问题引入隐性偏差
- Sync round-trip 无损：外币字段字符串透传，无需额外 encode/decode

### 负面影响与约束

- **禁止内联算术：** 所有调用方 MUST 通过 `convertToJpy()`（`lib/shared/utils/currency_conversion.dart`），禁止 `double.parse(tx.appliedRate!) * tx.originalAmount` 散落在 UI/use case 中
- **exchange_rates 缓存表的 rate 列不受本 ADR 约束：** 缓存表的 `rate` 列可使用 RealColumn（该列用于本地 TTL 判断，不进入 transactions hash chain，精度要求不同）。D-04 仅约束 `transactions.applied_rate`

### 架构测试要求

- `schema_v21_migration_test.dart` MUST 包含：`appliedRate` 在 transactions 表中的列类型为 TEXT（不为 REAL）
- `currency_conversion_test.dart` MUST 包含：至少 10 个边界 case 验证 `convertToJpy()` 预览值 == 持久化值

---

## 🚀 实施计划 (Implementation Plan)

**Phase 40 (STORE-01, STORE-02):**
1. `lib/data/tables/transactions_table.dart` — 添加 `TextColumn get appliedRate => text().nullable()()`
2. `lib/shared/utils/currency_conversion.dart` — 实现 `convertToJpy(String originalAmount, String appliedRate, int decimals)` 单一 parse 工具
3. `lib/features/accounting/domain/models/transaction.dart` — Freezed 字段 `String? appliedRate`
4. `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — 条件透传 `if (tx.appliedRate != null) 'appliedRate': tx.appliedRate`

---

## 📚 参考资料

- `.planning/research/PITFALLS.md` — Pitfall 1: Float Arithmetic for Money and Rate Precision
- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — D-04, D-05
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — hash formula (transactionId|amount|timestamp|previousHash)
- ADR-021 — currency fields excluded from hash
- ISO 4217 — JPY exponent = 0 (no sub-units); typical exchange rates 4–6 decimal places

---

## 📋 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-12 | 1.0 | 初始版本，锁定 D-04 TextColumn 决策 | Claude Sonnet 4.6 |

---

**文档维护者:** 技术架构团队
**下次Review:** Phase 40 实施完成后（schema_v21 migration 验收时）
