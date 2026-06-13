# ADR-022: 多币种 — 编辑语义（日元只读 / 覆盖×改日期弹窗 / 自动重算 toast）

**文档编号:** ADR-022
**文档版本:** 1.0
**创建日期:** 2026-06-12
**最后更新:** 2026-06-12
**状态:** ✅ 已接受
**决策者:** zxsheanjp@gmail.com (project owner) + Claude Sonnet 4.6 (planning agent)
**影响范围:** v1.7 多币种 — Phase 42 编辑页 UI 实现；Phase 41 汇率 override 状态管理；REQUIREMENTS.md DISP-04 口径修正
**相关 ADR:** ADR-020 (Exchange Rate Precision — D-04, D-05)；ADR-021 (Hash Chain Scope)

> **本 ADR 已 ratify 于 2026-06-12。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-12)
**触发来源:** Phase 40 (CONTEXT.md D-01, D-02, D-03) — v1.7 多币种数据与同步基础
**Ratify 路径:** 锁定决策 D-01/D-02/D-03，源自 Phase 40 CONTEXT.md 讨论

---

## 🎯 背景 (Context)

### 业务需求

外币交易的编辑模型涉及三个相互关联的字段：
- `originalAmount`（原币金额，用户直接输入）
- `appliedRate`（汇率，来源可为自动获取或用户手动覆盖）
- `amount`（日元金额，`transactions.amount` 列，为 JPY 整数）

这三个字段满足约束：`amount = (originalAmount × appliedRate).round()`，即存在一个派生关系。

### 技术背景

#### 问题 1：三字段编辑模型的歧义（D-01 来源）

REQUIREMENTS.md DISP-04 的原始表述为"三字段双向联动"，即任何一个字段改变，其他两个字段随之更新。但三字段中存在一个固定派生关系，"双向联动"存在歧义：
- 若用户直接修改"日元金额"，如何重算原币金额（需要汇率，而汇率也可能变化）？
- 循环依赖：日元 ← 原币×汇率；若日元可直接修改，则原币 ← 日元÷汇率，汇率 ← 日元÷原币，引发 UI 更新循环

用户核心直觉：**"原币是事实，日元是结果"** — 外币账目的日元金额永远是计算派生值，编辑入口应只有原币和汇率两个输入。

#### 问题 2：手动覆盖汇率后改日期的策略冲突（D-02 来源）

REQUIREMENTS.md RATE-06 规定"用户手动覆盖的汇率不被自动重取踩掉"。  
Phase 41 成功标准 SC-4 规定"除非用户手动覆盖后主动改日期"时允许重新获取。  
这两条要求存在语义冲突：覆盖后改日期，应静默保留覆盖还是静默重取新汇率？两种行为都有"静默"问题。

#### 问题 3：无覆盖情况下日期变更触发自动重算（D-03 来源）

当用户没有手动覆盖汇率，改变交易日期触发自动重取导致汇率变化，此时日元金额会发生变化。若变化幅度较大（如 >1%），用户对变化毫不知情可能产生困惑。同时"不阻断保存"是另一项不变量（用户不应被强制确认才能保存）。

---

## 🔍 考虑的方案 (Considered Options)

### D-01：外币行编辑模型

#### 方案 1A: 三字段全双向联动（任意字段改变其余两个重算）
**为何不选：** 存在循环依赖，日元直接修改需要确定如何分配到原币和汇率；UI 更新循环风险；违反"原币是事实"的用户直觉

#### 方案 1B: 双输入单派生（原币金额 + 汇率 → 日元，日元只读）— **已选** ✅
- 编辑页中外币行日元金额字段不可输入（read-only 展示）
- 用户仅能修改原币金额和汇率两个字段
- 日元金额 = `(originalAmount / subunitToUnit * double.parse(appliedRate)).round()`，实时计算展示

---

### D-02：手动覆盖汇率后改日期的处理策略

#### 方案 2A: 静默保留覆盖（RATE-06 字面优先）
**为何不选：** 用户改日期后可能期望汇率也随之更新（RATE-05 场景：节假日选工作日汇率），静默保留旧率会令用户困惑

#### 方案 2B: 静默重取新汇率（Phase 41 SC-4 字面优先）
**为何不选：** 用户明确手动覆盖了汇率，静默踩掉违反用户意图，RATE-06 精神被违反

#### 方案 2C: 显示弹窗让用户选择 — **已选** ✅
- 弹窗文案：「保留手动汇率，还是按新日期重取？」
- 两个选项：「保留手动汇率」（override flag 不变）、「按新日期重取」（override flag 重置，触发重取）
- 无默认值（不允许静默行为）

---

### D-03：无覆盖、改日期自动重算导致日元金额变化 >1%

#### 方案 3A: 阻断保存，强制确认
**为何不选：** 违反"never-block-save"不变量；用户压力过大

#### 方案 3B: 静默重算（不提示）
**为何不选：** 用户不知道金额变了，可能产生账目混乱

#### 方案 3C: 非阻断 toast + 可撤销 — **已选** ✅
- 自动重算并立即保存（不阻断）
- 展示非阻断 toast："日元金额从 ¥X 调整为 ¥Y（汇率更新）"+ [撤销] 按钮
- 撤销操作：恢复旧汇率，日元金额回到原值
- Toast 消失时间：5 秒（用户感知窗口）
- 1% 阈值基于日元金额整数比较：`|newJpy - oldJpy| / oldJpy > 0.01`

---

## ✅ 最终决策 (Decision)

**本 ADR 包含三个子决策，均为 Phase 40 CONTEXT.md 锁定决策的正式记录。**

---

### D-01: JPY 金额只读（外币行编辑模型）

**外币行（originalCurrency != null）的编辑页中，`amount`（日元金额）字段为只读展示，不可直接输入。**

可编辑输入仅有：
- `originalAmount`（原币金额）
- `appliedRate`（汇率）

日元金额派生公式（在 UI 层和持久化层使用同一个 `convertToJpy()` 工具函数）：

```
amount = convertToJpy(originalAmount, appliedRate, currency.decimals)
       = (double.parse(originalAmount) / pow(10, decimals) * double.parse(appliedRate)).round()
```

**含义：** "原币是事实，日元是结果"。日元金额永远由原币金额和汇率派生，从不被直接赋值。

**对 REQUIREMENTS.md DISP-04 的修正：** DISP-04 的"三字段双向联动"措辞不再适用，本 ADR 是外币编辑语义的规范性定义，Phase 42 实施 MUST 按本 ADR 执行。

---

### D-02: 手动覆盖后改日期 — 弹窗询问

**当用户对某条外币交易的 `appliedRate` 执行了手动覆盖（override flag = true），且随后修改了交易日期时，应用 MUST 展示确认弹窗：**

```
标题：「汇率确认」
内容：「您已手动设置了汇率。是否按新日期重新获取汇率？」
选项 A：「保留手动汇率」（override flag 保持 true，不重取）
选项 B：「按新日期重取」（override flag 重置为 false，触发汇率重取）
```

两个选项均显示，无默认选中，用户必须主动选择，禁止静默行为。

**Phase 41 约束：** Rate 服务必须向上返回一个携带 `isManualOverride: bool` 标志的 `RateResult` 类型，编辑页 use case 检查此标志决定是否触发 D-02 弹窗信号。

---

### D-03: 无覆盖自动重算 >1% — 非阻断 toast + 可撤销

**当以下所有条件同时成立时，触发 D-03 逻辑：**
1. 用户未手动覆盖汇率（override flag = false）
2. 用户修改了交易日期
3. 新日期的自动获取汇率导致日元金额变化幅度超过 1%（`|newJpy - oldJpy| / oldJpy > 0.01`）

**行为：**
1. 自动使用新汇率重算，立即更新字段值（不阻断保存流程）
2. 展示非阻断 toast："日元金额已自动调整：¥{oldJpy} → ¥{newJpy}" + [撤销] 按钮
3. [撤销] 被点击时：还原 `appliedRate` 为旧值，重算 `amount` 为旧日元金额
4. Toast 展示窗口：5 秒（撤销按钮在 5 秒后消失，变更永久生效）

**1% 阈值比较：** 基于日元金额整数（不是汇率字符串的字面比较）：

```dart
final changePct = (newJpy - oldJpy).abs() / oldJpy;
if (changePct > 0.01) { /* show toast */ }
```

---

## 📖 理由 (Rationale)

### D-01 理由

- 消除三字段循环依赖：原币金额和汇率是独立输入，日元是唯一派生值，拓扑关系清晰
- 符合会计直觉：外币账目的"事实"是原币金额，日元是计价单位换算结果；用户不应"直接输入日元金额"来反推原币金额
- 防止 UI 更新循环：只有一个输出方向（原币×汇率→日元），不存在循环依赖

### D-02 理由

- 明确告知用户"你的覆盖 vs 新日期的汇率"存在分歧，而非静默选边
- 符合最小惊讶原则（POLA）：静默任何方向都会让用户事后困惑
- RATE-06（"覆盖不被踩"）与 Phase 41 SC-4（"改日期时可重取"）的矛盾通过用户主动选择化解

### D-03 理由

- 满足"never-block-save"不变量：保存不被确认弹窗阻断
- 用户知情权：>1% 变化不是微不足道的，用户有权知道
- 可撤销而非询问：toast + undo 是移动端非阻断反馈的最佳实践（Gmail 撤销模式）
- 5 秒窗口足够用户看到并决定，不过分打扰

---

## ⚠️ 后果 (Consequences)

### 正面影响

- 编辑页 UI 约束明确，Phase 42 实施没有歧义
- 用户对汇率变化始终知情（D-02 弹窗 / D-03 toast）
- 无静默数据修改路径

### 负面影响与约束

- **DISP-04 需同步修正：** REQUIREMENTS.md DISP-04 的"三字段双向联动"表述已被 D-01 收窄，Phase 42 planner MUST 以本 ADR 为规范性定义，不以 DISP-04 原文为准
- **Phase 41 状态模型约束：** 汇率服务 MUST 在 `RateResult` 中携带 `isManualOverride` 状态，否则 D-02 弹窗逻辑无法实现
- **toast 撤销的事务边界：** 撤销操作在 toast 消失前回滚汇率值；若用户在 toast 消失前导航离开，撤销机会随之消失（最终一致性，可接受）

### 与其他 ADR 的交叉约束

| 约束 | 来源 |
|------|------|
| appliedRate 比较用数值比较（D-05），不是字符串比较 | ADR-020 |
| 新三列不在 hash chain 中，D-01 的"日元派生"在领域层而非 hash chain 层保证 | ADR-021 |

---

## 🚀 实施计划 (Implementation Plan)

**Phase 40 (STORE-*，数据基础):**
- partial-triple 不变量（CreateTransactionUseCase）覆盖 D-01 的数据层一致性保证

**Phase 41 (RATE-06, SC-4):**
- `RateResult` 类型携带 `isManualOverride: bool`
- 应用层 use case 检查 override 标志，发送 D-02 弹窗信号

**Phase 42 (DISP-04):**
- 编辑页实现：日元金额只读展示，原币金额 + 汇率可编辑（D-01）
- 弹窗实现：`ChangeRateConfirmationDialog`（D-02）
- Toast 实现：`JpyAmountChangedToast`（D-03）

---

## 📚 参考资料

- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — D-01, D-02, D-03, D-05
- `.planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md` — "外币账目「原币是事实，日元是结果」"核心直觉
- ADR-020 — appliedRate TextColumn (D-04, D-05)
- ADR-021 — 新三列排除在 hash chain 外
- REQUIREMENTS.md — DISP-04（已被本 ADR D-01 收窄）、RATE-06（D-02 对冲）

---

## 📋 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-12 | 1.0 | 初始版本，锁定 D-01/D-02/D-03 编辑语义三项决策 | Claude Sonnet 4.6 |

---

**文档维护者:** 技术架构团队
**下次Review:** Phase 42 实施完成后（编辑页 UI 验收时）

---

## Update 2026-06-13: foreign headline made tap-to-editable (quick 260613-mgc)

D-01 原始实现把外币行的**头部大号金额设为不可点击**（non-tappable），原币金额仅能在 `CurrencyLinkedEditFields` 卡内的"原币金额"输入行编辑。

经用户明确要求（"点击头部数字弹出现有键盘修改"），该交互被**取代**：

- **外币行头部金额现可点击**，复用既有键盘 `AmountEditBottomSheet` + `SmartKeyboard`（OCR/Voice/JPY-edit 三处已在用），新增可选 currency-aware（主单位小数）模式编辑原币金额。**未新建任何键盘组件。**
- 卡内"原币金额"输入行被**移除**；`CurrencyLinkedEditFields` 现仅含两行：汇率（可编辑）+ 日元（换算，只读）。原币金额由头部键盘唯一承担展示+编辑，经 prop 注入卡片。
- 外币卡上移至分类/日期卡之前。

**单向换算不变量完全保留：** 仍是 `原币 × 汇率 → 日元`，日元只读、绝不回写，`convertToJpy()` 仍是唯一换算点（ADR-020）。本次改动只改"原币金额从哪里输入"（卡内行 → 头部键盘），不触碰 D-01 的派生关系、D-02 弹窗、D-03 toast 语义。JPY-native 行零回归（CURR-04）。
