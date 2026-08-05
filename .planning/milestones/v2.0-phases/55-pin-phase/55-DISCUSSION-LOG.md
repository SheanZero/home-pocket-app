# Phase 55: 应用锁（生物识别 + PIN） - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 55-pin-phase
**Areas discussed:** 锁的启用模型, PIN 设置/修改/再认证, 失败冷却的手感与可见度, 隐私遮罩 + 忘记 PIN, 生物识别自动触发, 设置衔接 + 安全区呈现, PIN 错误反馈

---

## 锁的启用模型

| Option | Description | Selected |
|--------|-------------|----------|
| 新增 appLockEnabled，生物识别为子开关 | 主开关 appLockEnabled（启用必先设 PIN）+ 锁内 biometricUnlock 子开关；锁生效=ON且pinHash存在 | ✓ |
| 复用 biometricLockEnabled 作主开关 | 不动现有字段名，另记一个生物识别状态 | |
| 生物识别与 PIN 平级两个独立开关 | 允许仅生物识别不设 PIN（与 LOCK-06 冲突） | |

**User's choice:** 新增 appLockEnabled，生物识别为子开关（推荐）
**Notes:** 无论哪种，「锁生效」都额外要求 pinHash 已存在，避免无 PIN 弹锁 / 避免遗留默认 true 误锁。→ D-01 / D-02

---

## PIN 设置 / 修改 / 再认证

### 关锁 / 改 PIN 前是否再认证
| Option | Description | Selected |
|--------|-------------|----------|
| 关锁 + 改 PIN 都要再认证 | 别人拿到已解锁手机也无法偷偷关锁/改 PIN | ✓ |
| 仅改 PIN 要再认证 | 关锁视为已授权 | |
| 都不要 | 信任当前已解锁会话 | |

### 设 PIN 输入流程 + 修改入口
| Option | Description | Selected |
|--------|-------------|----------|
| 输两遍确认 + Settings 有改 PIN | 标准做法，防误设 | ✓ |
| 只输一遍 + 有改 PIN | 少一步确认 | |
| 你决定 | 交 planner | |

**User's choice:** 关锁+改 PIN 都再认证（推荐）；输两遍确认 + Settings 有改 PIN（推荐）
**Notes:** → D-03 / D-04 / D-05

---

## 失败冷却的手感与可见度

### 冷却梯度（首问）
| Option | Description | Selected |
|--------|-------------|----------|
| 宽松起步、封顶 5min | 前5次免延迟，之后 30s→1min→5min 封顶 | |
| 更严格、梯度陡 | 3次→1min、6次→5min、9次→15min | |
| 你决定具体数值 | 交 planner/安全评审 | |
| (Other) MVP 不提供冷却梯度 | 用户自填 | ✓ |

### 可见度（首问）
| Option | Description | Selected |
|--------|-------------|----------|
| 平时极简、仅冷却时显倒计时 | 贴合 tone B | |
| 始终显示剩余次数 | tone C 风格 | |
| 什么都不显 | 最极简 | |
| (Other) 不提供 | 用户自填 | ✓ |

### 连错防护到底做到哪一档（澄清问 — 已显式告知安全后果后）
| Option | Description | Selected |
|--------|-------------|----------|
| 极简固定冷却（折中） | 错 N 次后统一锁 30–60s，满足 LOCK-08 本意 | |
| MVP 真的零速率限制 | 错了清空可立即重试、无任何冷却；需把 LOCK-08 降级为 v2 + 安全评审记接受风险 | ✓ |
| 还是做递增梯度 | 5次→30s→1min→5min 封顶 | |

**User's choice:** MVP 真的零速率限制
**Notes:** Claude 在用户回答后**显式提示安全后果**（4 位 PIN=1万组合、无擦库、无恢复、冷却是唯一暴力破解防线、本 phase 自带安全评审），用户知情后仍主动选零速率限制。→ **D-06（LOCK-08 显式 descope，下游台账须修正、安全评审须签字接受风险）**。可见度问题随之作废。

---

## 隐私遮罩 + 忘记 PIN

### 隐私遮罩外观 + 覆盖范围
| Option | Description | Selected |
|--------|-------------|----------|
| 不透明品牌封面 + 仅启用锁时 | 跟随主题不透明封面，比 blur 稳；未启用锁不盖 | ✓ |
| 不透明封面 + 始终覆盖 | 锁关也盖 | |
| 模糊 blur 遮罩 | 快照时机有透内容风险 | |

### 忘记 PIN 落地
| Option | Description | Selected |
|--------|-------------|----------|
| 可点开的简短说明 | 低调「忘记 PIN?」点开解释需重装/丢未同步数据/不暗示恢复 | ✓ |
| 纯静态文案 | 锁屏底部一行不可点 | |
| 你决定 | 交 planner | |

**User's choice:** 不透明品牌封面 + 仅启用锁时（推荐）；可点开的简短说明（推荐）
**Notes:** → D-07 / D-08

---

## 生物识别自动触发 + Face ID↔PIN 页切换

| Option | Description | Selected |
|--------|-------------|----------|
| 自动弹（冷启+回前台），失败停 Face ID 页 | 停 Face ID 页带「重试」+「パスコードを使用」，点后切 PIN 页 | ✓ |
| 自动弹，失败直接落 PIN 页 | 少一次点击但失去重试 Face ID | |
| 不自动，要手动点 Face ID | 偏离 LOCK-05「自动尝试」 | |

**User's choice:** 自动弹（冷启+回前台），失败停 Face ID 页（推荐）
**Notes:** → D-09

---

## 「现在设置」衔接 + 安全区呈现

| Option | Description | Selected |
|--------|-------------|----------|
| 深链即开始设 PIN + 主开关展子项 | 滚到安全区直接开始设 PIN；主开关→子项（生物识别子开关 + 改 PIN）；notifications 保留 | ✓ |
| 只滚动高亮主开关，用户自己点 | 不自动开始 | |
| 你决定 | 复用 54-03 scrollToSecurity | |

**User's choice:** 深链即开始设 PIN + 主开关展子项（推荐）
**Notes:** → D-10 / D-11

---

## PIN 错误反馈 + 输满即校验

| Option | Description | Selected |
|--------|-------------|----------|
| 输满即校验 + 错误拖动清空 | 无确认键标准九宫格；错误抖动+清空+触觉，不加文案 | ✓ |
| 输满即校验 + 加「PIN 不正确」文案 | 更明确但多视觉噪 | |
| 需按确认键才校验 | 多一步，偏离标准锁屏 | |

**User's choice:** 输满即校验 + 错误拖动清空（推荐）
**Notes:** → D-12

---

## Claude's Discretion

- KDF 方案与参数（加盐慢哈希 ≥100k 或 Argon2id、off-isolate；`cryptography ^2.7.0` 已有，无新依赖；常量时间比对；盐存储位置；`pinHash` 遗留 SHA-256 升级）—— 专项安全评审定。
- 应用生命周期 wiring（根 WidgetsBindingObserver；paused→resumed 重锁 / inactive 遮罩；对齐 sync_lifecycle_observer.dart）。
- `local_auth` 完整错误分类映射 → 一律回退 PIN（LOCK-10；扩展现有 BiometricService）。
- 锁屏 boot-gate 在 `_buildHome()` ladder 的排位 + 回前台覆盖（gate-owned 回调，非 root pushReplacement）。
- 新增 ARB key 命名与组织（三语 parity + 硬编码 CJK 扫描）。

## Deferred Ideas

- LOCK-08 递增冷却 → v2（D-06 显式 descope，下游台账待修正）。
- LOCK-V2-01/02/03（宽限时间 / BIP39 恢复 / 失败擦库）—— 已在 REQUIREMENTS v2。
- Settings 法务/赞助/日本合规 —— Phase 56。
