# Phase 52: Recognition UX + English Voice - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 52-Recognition UX + English Voice
**Areas discussed:** 置信度带+chips 设计, 纠错交互模型, 提示出现时机, 英文覆盖深度, band 框架, chips 限量, 英文 locale 路由, 商家纠错

---

## 置信度带 + chips 设计

### Q1 — 设计流程
| Option | Description | Selected |
|--------|-------------|----------|
| 先出 HTML 设计稿再开发 | mock-first（Phase 43 / nhs / 0cj 模式），稿确认后写生产代码；CONTEXT 只锁约束 | ✓ |
| 现在口述方向、直接开发 | 现在定视觉处理写进 CONTEXT，跳过 mock | |

**User's choice:** 先出 HTML 设计稿再开发
**Notes:** 视觉细节（band 视觉/chip 形态/布局）留稿里定，约束 = ADR-012 纯定性 + ADR-019 调色。

### Q2 — mock 范围
| Option | Description | Selected |
|--------|-------------|----------|
| 只 mock 识别 affordance，坐在现有表单上 | 复用 nhs 表单 + ADR-019，最小范围 | |
| 连录入面板一起重 mock | 把 VoiceRecordPanel 连识别 affordance 一起重设计，覆盖说话中→落定→纠错全流程 | ✓ |

**User's choice:** 连录入面板一起重 mock
**Notes:** 牵动「提示出现时机」（band 可能面板内显示）。

---

## 纠错交互模型

### Q1 — 何时教学习表
| Option | Description | Selected |
|--------|-------------|----------|
| 保存成交易时才教 | 点 chip 立即换+重派生 ledger，但写学习表推迟到 save，避免草稿/reset 污染 | ✓ |
| 点即换、点即教 | 点 chip 同时写学习表 | |
| 换 + 二次确认才教 | 弹确认才写 | |

**User's choice:** 保存成交易时才教

### Q2 — 纠错范围
| Option | Description | Selected |
|--------|-------------|----------|
| chip 和完整选择器都算 | 任何把类目改离识别原值的动作（chip 或选择器）保存时都记一条；需记住识别原始类目 | ✓ |
| 只有点 chip 才教 | 完整选择器手动改不教 | |

**User's choice:** chip 和完整选择器都算

---

## 提示出现时机

### Q1 — 何时可见
| Option | Description | Selected |
|--------|-------------|----------|
| 类目一落定就显示 | 首个 final 落定即渲染到表单；面板在场则同时可见 | ✓ |
| 面板收起后才显示 | 回到素表单才出现 | |

**User's choice:** 类目一落定就显示

### Q2 — 改后处理
| Option | Description | Selected |
|--------|-------------|----------|
| 一改就清掉 band | 用户选定任何类目后 band 消失（user-authoritative），chips 可收起 | ✓ |
| band 保留到保存 | band 一直在直到保存 | |

**User's choice:** 一改就清掉 band

---

## 英文覆盖深度

### Q1 — 覆盖深度
| Option | Description | Selected |
|--------|-------------|----------|
| 务实高频子集 | 只高频 L2 英文关键词 + 明显英文名连锁别名 | |
| 全 138 L2 + 全商家别名 | 每个有 zh/ja 关键词的 L2 都补英文；每家有英文名的商家填 nameEn/别名 | ✓ |
| 最小：几乎只靠货币词 | 极少英文关键词、基本不管商家别名 | |

**User's choice:** 全 138 L2 + 全商家别名
**Notes:** research 先确认 nameEn 填充率 + recognizer en-locale 接线，决定数据活还是接线活。

### Q2 — 数字习语
| Option | Description | Selected |
|--------|-------------|----------|
| 支持「X fifty」→ X.50 | 「five fifty」→5.50（金钱习语），仅金钱上下文触发防与 550 歧义 | ✓ |
| 只做整数词，不做 X.50 习语 | 小数靠 STT 阿拉伯数字 | |

**User's choice:** 支持「X fifty」→ X.50

---

## band 框架（round 2）

| Option | Description | Selected |
|--------|-------------|----------|
| 纯视觉、无可见文字 | 仅颜色/图标强度 + a11y 隐藏标签；零游戏化词风险、i18n 最干净 | ✓ |
| 确定度措辞 | 「确定/大概/不确定」类三语 ARB 文案 | |

**User's choice:** 纯视觉、无可见文字

---

## chips 限量（round 2）

| Option | Description | Selected |
|--------|-------------|----------|
| 上限 ~3 + 一个出口 chip | 前 3 个备选（含降级商家默认类目，L2 去重）+「其他/更多」出口 chip 打开完整选择器 | ✓ |
| 不限量、无出口 chip | 平铺所有 alternates | |

**User's choice:** 上限 ~3 + 一个出口 chip

---

## 英文 locale 路由（round 2）

| Option | Description | Selected |
|--------|-------------|----------|
| 绑 app UI 语言 | app 设英文才走英文识别，复用现有 locale plumbing，最小风险 | |
| 独立语音语言切换 | 录入加 zh/ja/en 语音识别语言选择，独立于 app UI；ja-app 用户也能说英文 | ✓ |

**User's choice:** 独立语音语言切换
**Notes:** 把 localeId 与 app locale 解耦——需 thread session 语音 locale 端到端 + 守 v1.8 WR-04 golden-locale 回归；selector 落点交 plan。

---

## 商家纠错（round 2）

| Option | Description | Selected |
|--------|-------------|----------|
| 可编辑/清除，但不回流学习 | 商家名普通可编辑文本预填，改它不教任何表；本期不加专门 affordance | ✓ |
| 加专门商家纠错 affordance | 显式商家纠正 UI（仍不教商家表） | |

**User's choice:** 可编辑/清除，但不回流学习

---

## Claude's Discretion

- outcome→VoiceParseResult→form thread 形状（D-11）
- band 视觉 / chip 形态 / 布局 / 纠错 sheet 形态（HTML mock 里定）
- 语音语言 selector 落点（面板内 / 表单 / 设置）
- 英文数字词兜底精确 token 集 + 金钱上下文判定
- merchant nameEn 填充策略（接线 vs 数据补写）
- 纠错写路径入口（recordCorrection 定位）

## Deferred Ideas

- 商家纠正回流学习（merchant_category_preferences）→ 明确 out（RECUX 只教 KEYWORD 表）
- 商家专属账本 affordance（商家 ledgerType 列）→ 未来
- 完整口述英文数字状态机 → 不做（只有界 ~30 行兜底）
- 商家库凑 600-800 / 中国及其他地区目录 / FTS5 → MERCH-V2
