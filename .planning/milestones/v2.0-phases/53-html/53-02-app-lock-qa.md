# App Lock（应用锁屏）— DESIGN-02 QA 与批准记录

**surface**: App Lock / 应用锁屏
**winning sketch**: sketch 002 · tone **B 清爽极简**（系统原生 · 跟随主题）· ★ 选定
**modes**: 浅色模式（ライト）+ 深色模式（ダーク）各一组
**requirement**: **DESIGN-02** — 应用锁屏（生物识别提示 + PIN 输入）的 HTML 设计稿产出并经用户确认
**source**: `.planning/sketches/002-app-lock/index.html`（tone-B 区块：`B · 清爽极简 ★ 选定`）
**ADR**: 配色遵循 ADR-019「桜餅×若葉」v1.6（深色 `screen dark` / `#171210` 家族，primary 若叶绿 `#8DC68D`）

---

## 设计问题（已定）

应用锁是 **两个独立页面**，不是一屏混排：一个 **Face ID 页**、一个 **PIN 页**，由设置决定显示哪个。

- 仅 Face ID，或 Face ID + PIN → 显示 **Face ID 页**（识别失败可经「パスコードを使用」切到 PIN 页）
- 仅 PIN → 直接显示 **PIN 页**
- 两者都开 → **Face ID 优先**，PIN 为兜底

tone B 以系统原生、跟随主题的极简表达胜出（A 暖樱渐变 / C 暖底含重试计数为落选备选）。

---

## 逐元素验证表（DESIGN-02）

每一项给出 sketch 002 tone-B 内可 grep 的确切字符串作为证据。

| DESIGN-02 元素 | 状态 | sketch 002 tone-B 证据（确切串） |
|---|---|---|
| 生物识别提示 Face ID surface | ✓ PRESENT | `Face ID を見つめてください`（浅色 + 深色 Face ID 页各一处）；徽标 `FACE ID` |
| PIN 输入 surface | ✓ PRESENT | `パスコードを入力` + `pin-dots`（4 点指示器）+ 标准九宫格 `keypad`（1–9 / 0 / ⌫）；徽标 `PASSCODE` |
| 两个独立 surface（非混排） | ✓ PRESENT | tone-B 每个主题组含两台 phone：`Face ID 页（浅色）` / `PIN 页（浅色）`、`Face ID 页（主）` / `PIN 页（仅PIN / 回退）` |
| 浅色模式 light mode | ✓ PRESENT | `浅色模式（テーマ: ライト / システム明）`，`screen` 背景 `#fff` 两台 |
| 深色模式 dark mode | ✓ PRESENT | `深色模式（テーマ: ダーク / システム暗）`，`screen dark`（`#171210`）共 2 处（Face ID 深色 + PIN 深色） |
| Face ID 优先 / PIN 兜底逃逸 | ✓ PRESENT | Face ID 页 ghost 按钮 `パスコードを使用`（浅 + 深各一）；PIN 页键盘左下 `Face ID` 功能键回切——表达「Face ID 主、PIN 兜底」双向关系 |

---

## QA 结论

- 胜出 sketch（002 · tone B · 浅色 + 深色）经逐元素 QA **全部满足 DESIGN-02**，设计稿 **已定稿、可提交用户批准**。
- 本次 QA 对 HTML **未作任何编辑**（minimal-edit 触发条件未命中——所有必需元素本就齐备）。tone A/C 未触碰。
- 自动校验通过：`grep "★ 选定"` / `grep "浅色模式"` / `grep "深色模式"` 命中，`grep -c "screen dark"` = 2，`Face ID を見つめてください` / `パスコード` / `パスコードを使用` 均命中。

---

## 下游（Phase 55）继承的约束

本批准的 UI 仅是设计契约；真正的安全敏感实现落在 Phase 55，并携带 **独立安全评审**（ROADMAP Research 标记）。被批准的设计对 Phase 55 隐含：

- **系统原生、跟随主题** 的锁屏（浅 / 深两套，与系统主题一致），不引入独立配色轴。
- **两个独立 surface**：Face ID 页 + PIN 页分离，按设置选择，不混排。
- **生物识别优先 + PIN 强制兜底**：两者都开则 Face ID 先行，失败 / 不可用必有 PIN 逃逸（对应 LOCK-05 / LOCK-10——`local_auth` 全部错误分类一律回退 PIN，绝不把用户锁在自己数据外）。
- **锁是「已解密 DB 之上的 UI gate」**：它 **不** 参与派生 / 绑定 DB 密钥，仅是进入主 shell 前的界面闸门；DB 加密由既有 4 层加密负责（对应 LOCK-02 冷启动重锁 / LOCK-03 回前台 `paused`→`resumed` 完整重锁）。
- **4 位 PIN 以加盐慢哈希** 存入既有 secure storage（keychain accessibility 保持 `unlocked_this_device` 不变）。
- **任务切换器 / 后台隐私遮罩统一**（`inactive` 盖遮罩层，LOCK-04）——遮罩是全 app 统一项，不是 tone 变体轴。
- Phase 55 依赖 Phase 54（引导末尾的「设置应用锁」入口需先存在），并 **自带独立安全评审**——最高风险的安全工作在彼处落地，而非本设计关卡。

---

## DESIGN-04 gate-exit（零生产代码）

本 surface 的全部产物仅为 `.md` / `.html`，位于 `.planning/` 下：`53-02-app-lock-qa.md`（本文件）+ 既有 `002-app-lock/index.html`（未改）。本计划 **零 Dart / 零 pubspec / 零 lib/ / 零 test/ / 零 ARB** 改动，满足 DESIGN-04 硬关卡（`git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` 为空）。
