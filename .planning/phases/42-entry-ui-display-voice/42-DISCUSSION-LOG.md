# Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 42-entry-ui-display-voice
**Areas discussed:** 币种选择器布局, 换算预览面板, 小数输入门控行为, 三字段联动编辑

---

## 灰区选择（multiSelect）

| Option | Description | Selected |
|--------|-------------|----------|
| 币种选择器布局 | CurrencySelectorSheet 单行内容 / 「更多」展开方式 | ✓ |
| 换算预览面板 | DISP-01 预览内容 / loading / staleness | ✓ |
| 小数输入门控行为 | CURR-05 点键状态 / 切币种截断 | ✓ |
| 三字段联动编辑 | DISP-04 交互模型 | ✓ |
| 语音币种确认 UX | VOICE-CUR（未选，走合理实现） | |
| 强制手输汇率 UI | P41 D-08（未选，走合理实现） | |

**User's choice:** 全部四个主灰区；语音 + 手输汇率交给 Claude's Discretion。

---

## 币种选择器布局

### Q1 单行展示什么？
| Option | Description | Selected |
|--------|-------------|----------|
| 符号 + 代码 + 币种名 | `$ USD 美元`，三要素清晰 | |
| 代码 + 币种名（无符号） | `USD 美元`，更简洁 | |
| 加国旗 emoji | 符号+代码+名 前加国旗 | ✓ |

**User's choice:** 加国旗 emoji。
**Notes:** Claude 提示国旗对 EUR 等无 1:1 国家币种 + 跨平台 emoji 渲染差异的风险；约定用通用区域旗/占位符兜底，归实现细节，golden 验证。

### Q2 「更多」展开方式？
| Option | Description | Selected |
|--------|-------------|----------|
| 同 sheet 内展开 + 顶部搜索框常驻 | 单层、最少点击 | |
| 二级页/展开按钮 | 默认只显示常用区 + 「更多」按钮 | ✓ |

**User's choice:** 二级页/展开按钮。

---

## 换算预览面板

### Q1 预览展示多少信息？
| Option | Description | Selected |
|--------|-------------|----------|
| 日元结果 + 汇率行 | 主行 ≈¥7,415 + 副行 USD 1=¥148.30·日期 | ✓ |
| 只显日元结果 | 只 ≈¥7,415 | |

**User's choice:** 日元结果 + 汇率行。

### Q2 loading 态？
| Option | Description | Selected |
|--------|-------------|----------|
| 原位置灰显/骨架 | 原位淡化占位，不跳动不遮挡 | ✓ |
| 小 spinner | 转圈 + 「获取汇率中」文案 | |

**User's choice:** 原位置灰显/骨架。

### Q3 回退/过期汇率提示？
| Option | Description | Selected |
|--------|-------------|----------|
| 预览下方 warning 色小字标签 | 「使用 6/10 缓存汇率」warning 色 | ✓ |
| 只加一个小图标 | 汇率日期旁 ⓘ/⚠ 图标 | |

**User's choice:** 预览下方 warning 色小字标签。

---

## 小数输入门控行为

### Q1 JPY/KRW（0 小数位）点键怎么处理？
| Option | Description | Selected |
|--------|-------------|----------|
| 灰显禁用（位置保留） | 键位仍在但置灰，布局不跳动 | |
| 隐藏/换成其他键 | 点键位置空出或换功能 | ✓ |

**User's choice:** 隐藏/换成其他键。

### Q2 中途切到小数位更少的币种怎么办？
| Option | Description | Selected |
|--------|-------------|----------|
| 截断小数部分 | 50.50→50 | |
| 四舍五入 | 50.50→51 | |
| 保留输入但拦截保存 | 不改输入，保存时提示 | |
| Other（freeform） | 「不截断，保留小数点后两位」 | ✓ |

**User's choice (initial freeform):** 「不截断，保留小数点后两位」——与切到 0 位币种冲突，Claude 追问澄清。

**澄清追问（plain text）:** 用户回复「日元保存小数点后两位，但不显示，直接截断」。Claude 反映为明确规则并二次确认。

### Q（确认）小数处理规则
| Option | Description | Selected |
|--------|-------------|----------|
| 对，锁定 | 外币按币种小数位；切 JPY/KRW 直接截断为整数；存入日元始终整数 ADR-020 round | ✓ |
| 存入日元用截断不用 round | 会与 ADR-020 冲突需改 ADR | |

**User's choice:** 对，锁定。
**Notes:** 最终规则——外币按 ISO minor unit 输入；切到 0 位币种直接截断（非四舍五入）；转换后日元 `amount` 始终整数，沿用 ADR-020 `.round()`，不改 ADR。

---

## 三字段联动编辑

**前置：** Claude 读 ADR-022 发现「日元只读派生」与 DISP-04「三字段双向联动」冲突——ADR-022 D-01（已 ratify）选定方案 1B 双输入单派生，明确作废 DISP-04 原措辞。向用户说明冲突已由其已接受 ADR 解决，遵循 ADR-022。

### Q1 汇率字段显著度？
| Option | Description | Selected |
|--------|-------------|----------|
| 始终可见可编辑 | 原币/汇率/日元(只读) 三行常驻 | ✓ |
| 汇率折叠/点击展开 | 默认只显原币+日元，汇率藏入口后 | |

**User's choice:** 始终可见可编辑。

### Q2 只读日元派生值如何更新？
| Option | Description | Selected |
|--------|-------------|----------|
| 改原币/汇率时实时重算 | 每次输入即时 convertToJpy() | ✓ |
| 失焦/提交时重算 | 离开字段或保存时才算 | |

**User's choice:** 改原币/汇率时实时重算。

---

## Claude's Discretion

- 语音币种确认 UX（VOICE-CUR-01/02/03）——需求已充分约束，走合理实现。
- 强制手输汇率 UI（继承 P41 D-08，unavailable 时）——入口形态/时机/衔接归实现。
- 列表行原币小字标注精确排版（DISP-02）。
- ISO 4217 完整列表 + 本地化名 + minor unit 数据源选型。
- 小数输入状态机设计（无现有先例）。
- 预览 loading/warning 文案与 ARB key 命名。

## Deferred Ideas

- 国旗 emoji 跨平台一致性深挖（必要时改 SVG 旗/纯符号）。
- English 语音币种解析（VOICE-EN-V2-01，v2）。
- 购物清单 estimatedPrice 多币种（PROJECT.md 明示本期不做）。
- 手动汇率高级校验（区间合理性等）。
