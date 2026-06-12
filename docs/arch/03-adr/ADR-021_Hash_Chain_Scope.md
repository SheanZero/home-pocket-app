# ADR-021: 多币种 — 新货币字段排除在哈希公式外，保持链兼容性

**文档编号:** ADR-021
**文档版本:** 1.0
**创建日期:** 2026-06-12
**最后更新:** 2026-06-12
**状态:** ✅ 已接受
**决策者:** zxsheanjp@gmail.com (project owner) + Claude Sonnet 4.6 (planning agent)
**影响范围:** v1.7 多币种 — HashChainService.calculateTransactionHash 签名约束；schema v21 架构测试；Phase 40 STORE-04
**相关 ADR:** ADR-009 (Incremental Hash Chain Verification)；ADR-020 (Exchange Rate Precision)；ADR-022 (Edit Semantics)

> **本 ADR 已 ratify 于 2026-06-12。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-12)
**触发来源:** Phase 40 (STORE-04) — v1.7 多币种数据与同步基础
**Ratify 路径:** 基于 CONTEXT.md 研究结论与 PITFALLS.md Pitfall 3

---

## 🎯 背景 (Context)

### 业务需求

v1.7 多币种功能为 transactions 表新增三个 nullable 列：
- `original_currency` (TEXT, nullable) — 原币种代码（如 "USD"）
- `original_amount` (TEXT, nullable) — 原币金额字符串（如 "149.99"）
- `applied_rate` (TEXT, nullable) — 汇率字符串（如 "157.3421"，见 ADR-020）

这三列在 schema v20→v21 迁移中以 nullable 形式追加，已有交易行的这三列均为 NULL。

### 技术背景

`HashChainService.calculateTransactionHash` 的当前实现（已直接检视，2026-06-12）：

```dart
// lib/infrastructure/crypto/services/hash_chain_service.dart (v20)
String calculateTransactionHash({
  required String transactionId,
  required double amount,
  required int timestamp,
  required String previousHash,
}) {
  final input = '$transactionId|$amount|$timestamp|$previousHash';
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

**哈希公式：** `SHA-256(transactionId|amount|timestamp|previousHash)`

该公式签名的参数集合为：`{transactionId, amount, timestamp, previousHash}`，不包含任何其他字段。

### 核心问题

若将新三列加入哈希公式，则：
- v20 以前（v1.0–v1.6）所有已存储的 hash 值均基于旧公式
- 迁移后重新计算每条交易的 hash 值将与历史存储值不匹配
- `verifyChain()` 对所有 pre-v21 交易均返回 tampered = true
- 用户看到全账本哈希链完整性失败警告（假阳性）

**要求对标：** STORE-04（hash chain scope 不破坏现有链）

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A: 将三新列加入哈希公式（最大完整性）— 未选

**优势:**
- 货币字段修改可被哈希链检测

**劣势:**
- ⚠️ **破坏所有 pre-v21 链哈希：** 每条历史交易需要重新计算并存储新 hash 值
- ⚠️ 迁移期间窗口内链处于断裂状态，期间 verifyChain 不可用
- ⚠️ 已有用户（v1.0–v1.6）升级后看到"账本完整性异常"误报，严重损害信任
- ⚠️ 需要在 onUpgrade 中对所有行执行 UPDATE + rehash，大账本下可能超时

---

### 方案 B: 新三列排除在哈希公式外（向后兼容）— **已选** ✅

**优势:**
- 现有链哈希完全不受影响，verifyChain 对 pre-v21 交易仍正常通过
- hash_chain_service.dart 零改动（STORE-04 满足）
- partial-triple 领域不变量（CreateTransactionUseCase 验证）作为货币字段的完整性保证机制，无需 hash chain 参与

**劣势:**
- 货币字段的哈希完整性保护不由 hash chain 提供（由 partial-triple 不变量补位）

---

### 方案 C: 版本化哈希公式（双公式兼容）— 未选

**优势:**
- 理论上可兼容新旧两种公式

**劣势:**
- ⚠️ 实现复杂性显著增加（每条交易需存储 hash 版本标志）
- ⚠️ verifyChain 需要区分行版本，测试矩阵倍增
- ⚠️ 此规模的应用无此必要性

---

## ✅ 最终决策 (Decision)

**方案 B：三新列（original_currency、original_amount、applied_rate）排除在哈希公式之外。**

### 哈希公式（v21 确认保持不变）

```
SHA-256(transactionId|amount|timestamp|previousHash)
```

这是 v21 阶段的唯一官方哈希公式定义。

### 函数签名约束（v21 架构不变量）

`HashChainService.calculateTransactionHash` 的参数列表 MUST 继续为且仅为：

```dart
String calculateTransactionHash({
  required String transactionId,
  required double amount,
  required int timestamp,
  required String previousHash,
})
```

参数列表中 MUST NOT 出现：`originalCurrency`、`originalAmount`、`appliedRate`，或任何其他 transactions 表列。

### hash_chain_service.dart 改动

**Phase 40 对 hash_chain_service.dart 零改动。** 本 ADR 是纯约束文档。

---

## 📖 理由 (Rationale)

1. **向后兼容高于边际完整性增益：** hash chain 存在的首要价值是检测核心财务记录（amount + timestamp）的篡改。货币溯源字段是加性元数据，不改变已记账的日元金额事实
2. **partial-triple 不变量补位：** CreateTransactionUseCase 的 partial-triple 验证（original_currency / original_amount / applied_rate 要么全有要么全无）在领域层保证货币字段的一致性，这是比 hash 更早的防御层
3. **零迁移风险：** 不向用户引入任何"账本异常"假阳性警告
4. **STORE-04 精确满足：** 需求明确要求"hash chain scope 不破坏现有链"，方案 A/C 均无法满足此要求

---

## ⚠️ 后果 (Consequences)

### 正面影响

- hash_chain_service.dart 代码零改动，Phase 40 实施风险最低
- pre-v21 账本完整性验证结果不受影响

### 负面影响与约束

- **货币字段不在 hash chain 保护范围内：** 若有人直接修改 SQLite DB 中 `original_currency`/`original_amount`/`applied_rate` 的值，hash chain 不会检测到。接受此风险（partial-triple 不变量 + SQLCipher 数据库加密提供足够防御深度）

### 架构测试要求

`schema_v21_migration_test.dart` MUST 包含以下断言：

```dart
// 断言：calculateTransactionHash 不接受 originalCurrency/originalAmount/appliedRate 参数
// 即：函数签名中不存在这三个命名参数
final hashService = HashChainService();
// 以下调用 MUST 能编译（证明签名仅含 4 个参数）：
hashService.calculateTransactionHash(
  transactionId: 'test',
  amount: 1000.0,
  timestamp: 1000000,
  previousHash: 'genesis',
);
```

### 未来演进约束

任何未来 Phase 若要将货币字段加入 hash 公式，MUST 先创建新 ADR 替代本 ADR，并制定完整的链迁移策略（包括用户升级通知、rehash 方案、回滚路径）。

---

## 🚀 实施计划 (Implementation Plan)

**Phase 40 (STORE-04):**
1. `hash_chain_service.dart` — 零改动（仅添加本 ADR 的文档注释引用）
2. `test/data/schema_v21_migration_test.dart` — 添加哈希签名不变量断言（四参数，无货币字段）

---

## 📚 参考资料

- `.planning/research/PITFALLS.md` — Pitfall 3: Hash Exclusion
- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — D-04 (appliedRate TextColumn)
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — calculateTransactionHash 当前实现（2026-06-12 检视）
- ADR-009 — Incremental Hash Chain Verification（原 hash chain 架构）
- ADR-020 — appliedRate TextColumn 决策

---

## 📋 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-12 | 1.0 | 初始版本，锁定哈希公式排除货币字段的决策 | Claude Sonnet 4.6 |

---

**文档维护者:** 技术架构团队
**下次Review:** Phase 40 实施完成后（schema_v21 架构测试通过时）
