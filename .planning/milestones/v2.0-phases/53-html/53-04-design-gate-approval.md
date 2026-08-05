# 53-04 — 设计关卡批准记录（Design Gate Approval）

**Phase:** 53-html（HTML 设计关卡 · 零生产代码）
**Plan:** 53-04（Wave 2 · 关卡出口）
**写于:** 2026-06-29
**性质:** 关卡闭合记录。汇总 Wave-1 三块设计面（53-01 / 53-02 / 53-03）的批准就绪 QA，记录用户对三块**已选定**设计稿的显式批准；这是 DESIGN-01 / DESIGN-02 / DESIGN-03「经用户确认」一半的落点，同时记录 DESIGN-04 零生产代码 gate-exit 证据。一次性设计产物，**无生产代码**。

---

## 用户批准（2026-06-29）

用户经 GSD 设计关卡审阅了三块**已定稿、winner-selected** 的设计面及其逐元素批准就绪 QA 记录，对**全部三块**给出显式批准：

> **「Approve all three」（批准全部三块，无修改要求）**

无任何修改请求 —— 三块设计稿原样进入下游实现（Phases 54 / 55 / 56）。无需回退任何 Wave-1 plan。

---

## 已批准的三块设计面

| 需求 | 设计面 | 选定设计稿 | 选定 tone | 源文件 | 批准就绪 QA |
|---|---|---|---|---|---|
| **DESIGN-01** | Onboarding / 首启引导 | sketch 001 | A · 温柔抛茶感 | `.planning/sketches/001-onboarding-gate/index.html` | `53-01-onboarding-qa.md`（10/10 元素 PASS） |
| **DESIGN-02** | App Lock / 应用锁屏 | sketch 002 | B · 清爽极简（系统原生 · 跟随主题；浅色 + 深色） | `.planning/sketches/002-app-lock/index.html` | `53-02-app-lock-qa.md`（全元素 PASS） |
| **DESIGN-03** | Settings 法务·赞助（完整设置页） | sketch 003 | C · 混合（合并精简分区 + 法务·应援同组） | `.planning/sketches/003-legal-sponsor/index.html` | `53-03-settings-legal-sponsor-qa.md`（全元素 PASS） |

### DESIGN-01 — Onboarding（sketch 001 · tone A）
批准内容：两步首启 —— ①整体介绍（隐私 / 本地优先 / 双账本 / 语音卖点）→ ②基础设置（只显默认值 · 按需 変更 弹窗 · 提示可后改）。覆盖 app 介绍 + UI语言 / 通貨 / 音声入力 三步默认值设置。逐元素核对见 `53-01-onboarding-qa.md`（10/10 PRESENT，零 HTML 编辑）。

### DESIGN-02 — App Lock（sketch 002 · tone B · 浅色 + 深色）
批准内容：两个独立 surface —— Face ID 页 + PIN 页（非混排），由设置决定显示哪个；Face ID 优先、PIN 强制兜底（失败经「パスコードを使用」逃逸切 PIN）；系统原生、跟随主题，浅色 / 深色各一组（深色遵 ADR-019「桜餅×若葉」`#171210` 家族）。逐元素核对见 `53-02-app-lock-qa.md`（全元素 PRESENT，零 HTML 编辑）。

### DESIGN-03 — Settings 法务·赞助（sketch 003 · tone C）
批准内容：完整 Settings 页（既有 8 区按序保留并精简合并）—— `一般` 合并 外観 + 音声認識 + 悦己目標；`法的情報・応援` 单组承载 プライバシーポリシー + 利用規約 + 特定商取引法に基づく表記 + OSS ライセンス + 外链 開発を応援する；应用锁由 `セキュリティ & プライバシー` 内 master 开关展开 Face ID / 指紋 + PIN コード 子行（替换原孤立生物识别开关）。逐元素核对见 `53-03-settings-legal-sponsor-qa.md`（全元素 PRESENT，零 HTML 编辑）。

---

## 需求落点

- **DESIGN-01「经用户确认」一半** 在此完成 —— 用户已显式批准 onboarding sketch 001 / tone A。
- **DESIGN-02「经用户确认」一半** 在此完成 —— 用户已显式批准 app-lock sketch 002 / tone B（浅 + 深）。
- **DESIGN-03「经用户确认」一半** 在此完成 —— 用户已显式批准 Settings sketch 003 / tone C。
- **DESIGN-04 gate-exit** —— 见下节零生产代码证据。

---

## DESIGN-04 零生产代码 gate-exit 证据

关卡硬条件：仓库零新增生产 Dart。执行命令 `git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` 的输出为**空**（无任何匹配行）—— 工作树无 `.dart` / `pubspec.yaml` / `pubspec.lock` / `lib/` / `test/` / ARB 改动。`git status --short` 同样为空。本关卡全部产物仅为 `.md` / `.html`，均位于 `.planning/` 下：

- `.planning/sketches/001-onboarding-gate/index.html`、`002-app-lock/index.html`、`003-legal-sponsor/index.html`（三块选定稿，Wave-1 未编辑）
- `.planning/phases/53-html/53-01-onboarding-qa.md`、`53-02-app-lock-qa.md`、`53-03-settings-legal-sponsor-qa.md`（Wave-1 批准就绪 QA）
- `.planning/phases/53-html/53-04-design-gate-approval.md`（本文件）+ `53-04-downstream-handoff.md`（下游交接）

DESIGN-04 硬关卡满足（沿用 v1.8 Phase 43 设计关卡 precedent）。

---

## 关卡出口

三块设计稿经用户显式批准（DESIGN-01 / 02 / 03「经用户确认」完成），仓库零生产代码（DESIGN-04），关卡正式闭合。下游 Phase 54 / 55 / 56 的设计→实现交接见 `53-04-downstream-handoff.md`；在本关卡批准前不得为这三块写任何生产 Dart（DESIGN-04 precedence）。
