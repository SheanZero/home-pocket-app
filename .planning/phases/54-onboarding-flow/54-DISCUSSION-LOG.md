# Phase 54: 欢迎 / 首启引导（Onboarding flow） - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-29
**Phase:** 54-onboarding-flow
**Areas discussed:** 引导结构/gate排序, onboarding_complete持久化+数据重置存活, UI语言默认+写入语义, 末尾应用锁入口落地, 设置页交互一致性, 进度/返回/跳过流形态, 一键确认vs昵称必填

---

## 引导结构 / gate 排序

| Option | Description | Selected |
|--------|-------------|----------|
| 欢迎在前 → 昵称在后（两独立 gate） | 严格照批准设计，两个串联 gate | |
| 合并：昵称作为欢迎流额外一步 | 折进欢迎流，退役 ProfileOnboardingScreen | |
| 昵称在前 → 欢迎在后 | 与「首启先介绍」直觉相反 | |
| Other（用户自定义） | 将昵称+头像与欢迎页语言设置合并成同一页 | ✓ |

**User's choice:** 将昵称和欢迎页里面的语言设置合并成一个页面
**Notes:** 澄清：昵称+头像都进这一页；介绍页①保留不动；合并后维持昵称必填。退役独立 ProfileOnboardingScreen gate。有意偏离批准 HTML 稿（设置步新增身份字段）→ CONTEXT D-03 标注。

---

## onboarding_complete 持久化 + 数据重置存活

| Option | Description | Selected |
|--------|-------------|----------|
| 重现，当全新安装（存 Drift AppSettings） | 标志随库被擦，擦库=新开始，状态一致 | ✓ |
| 永不再引导（存 secure_storage） | 扛过擦库，但擦库后无 profile 却跳过收集页，不一致 | |

**User's choice:** 重新出现，当作全新安装（存 Drift AppSettings）
**Notes:** 导入备份后则跳过引导（视为已配置老用户）；实现注记：导入成功后置 onboarding_complete=true，不依赖旧备份。

---

## UI 语言默认 + 写入语义

| Option | Description | Selected |
|--------|-------------|----------|
| 设备语言预选（不支持→回退 ja） | 符合 ONBOARD-03；中文设备预选 zh | ✓ |
| 恒定默认 日本語 | 符合设计稿展示值，但偏离 ONBOARD-03 | |

**User's choice:** 设备语言预选（不支持→回退 ja）
**Notes:** 写入语义=默认跟随系统（'system'），主动在変更里选具体语言才钉死 'ja'/'zh'/'en'。

---

## 末尾应用锁入口落地（Phase 54 范围）

| Option | Description | Selected |
|--------|-------------|----------|
| 进 app + 深链到 Settings 安全区 | 真正设置由 Phase 55 在 Settings 交付，54 不建一次性锁 UI | ✓ |
| 路由到 Phase-54 自建占位屏 | 多一层衔接，54 阶段路径不完整 | |
| 只记「想设锁」意图 flag | 即时反馈弱 | |

**User's choice:** 进 app + 深链到 Settings 安全区
**Notes:** 跳过=进 app 锁关闭；Phase 55 依赖「入口先存在」已满足。

---

## 设置页交互一致性

| Option | Description | Selected |
|--------|-------------|----------|
| 分区混合（身份内联 + 偏好走变更弹窗） | 身份与偏好天然不同，分区呈现 | |
| 全部统一为「行 + 変更」模式 | 昵称/头像/语言/币种/语音 都一行「标签:当前值 [変更]」 | ✓ |

**User's choice:** 全部统一为「行+変更」模式
**Notes:** 昵称行点开=文本输入弹窗；头像行点开=既有头像选择器。

---

## 进度 / 返回 / 跳过 流形态

| Option | Description | Selected |
|--------|-------------|----------|
| 锁入口=确认后「末尾单独一屏」 | 主进度=介绍+设置 2 步，锁屏收尾不占进度 | ✓ (锁位置) |
| 锁入口=正式第 3 步 | 三步纳入进度 | |
| 顶部步进点 + 可返回上一步 | 显式进度 | |
| 无显式进度条，仅返回键/手势 | 更极简 | ✓ (进度呈现) |

**User's choice:** 锁入口=确认后的「末尾单独一屏」；进度=无显式进度条，仅返回键/手势
**Notes:** re-entrant 仍须保证：返回键能从设置↔介绍、锁屏→设置，无法卡死。

---

## 一键确认 vs 昵称必填

| Option | Description | Selected |
|--------|-------------|----------|
| 给默认昵称 → 可不改直接确认 | 保留「只显默认值一键确认」哲学 | |
| 坚持昵称必填 | 昵称行显「未設定」，确认拦截直到设过昵称 | ✓ |

**User's choice:** 坚持昵称必填
**Notes:** 头像随机暖 emoji 默认 + 语言/币种/语音有默认值 → 唯一强制动作=设昵称；不保留零输入一键确认。

---

## Claude's Discretion

- 新增引导文案的 ARB key 命名与组织（三语 ja/zh/en，过 parity + 硬编码 CJK 扫描）。
- 介绍页卖点排版/插画/跳过按钮位置（单屏；轮播=ONBOARD-V2-01 已 defer）。
- 深链到 Settings 安全区的导航机制。
- 「行+変更」各行 bottom-sheet 样式（ADR-019 调色 + 既有组件）。

## Deferred Ideas

- 更丰富介绍轮播 / 权限预说明 — ONBOARD-V2-01（V2）。
- 真正应用锁 PIN/生物识别 + 安全评审 — Phase 55。
- Settings 法务/赞助/日本合规 — Phase 56。
