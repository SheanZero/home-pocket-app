# 54-05 — 设计偏离 QA 记录（D-03 · 合并身份字段进设置页）

**Phase:** 54-onboarding-flow
**Plan:** 54-05（合并 onboarding 基础设置页）
**写于:** 2026-06-29
**性质:** 设计偏离说明记录。对「合并后的设置页新增 昵称+头像 两行」这一**对已批准 HTML 设计稿的有意偏离**做出口说明，供下游 UI 审查/验收引用。**非违反 design-gate**。

| 项 | 值 |
|---|---|
| **偏离编号** | D-03（CONTEXT.md 锁定决策） |
| **基线设计稿** | sketch 001 · tone-A · `.planning/sketches/001-onboarding-gate/index.html`（53-04 经用户确认） |
| **基线 QA** | `.planning/phases/53-html/53-01-onboarding-qa.md`（DESIGN-01 逐元素 10/10 PASS） |
| **偏离面** | 首启引导「基础设置」步 |
| **偏离性质** | **用户主导的有意决策**，重组已批准组件，零净新视觉语言 |
| **确认按钮文案** | 锁定为 `この設定で始める`（ARB `onboardingStart`，53-01/54-02 一致，未改） |

---

## 偏离内容

基线 sketch 001 tone-A 的「基础设置」步**只含三行设置**——UI 语言 / 通貨 / 音声入力の言語（见 53-01 QA 元素 5/6/7，grep `index.html` 第 73 行确认设置行只有这三类，无任何身份字段）。

合并后的 `OnboardingSettingsScreen`（D-01）在同一页**新增两行身份字段**：

| 新增行 | 来源 | 写入路径 |
|---|---|---|
| 昵称（あなたの呼び名，必填 · D-14） | 折自退役的 `ProfileOnboardingScreen` | `SaveUserProfileUseCase.execute(displayName:)` |
| 头像（タップしてアバターを変更） | 折自退役的 `ProfileOnboardingScreen` | `SaveUserProfileUseCase.execute(avatarEmoji:/avatarImagePath:)` |

起因：D-01 退役独立的 `ProfileOnboardingScreen` gate（原先与首启流串联的第二个 gate），将昵称+头像+`saveUserProfileUseCase` 逻辑折进唯一的首启引导流设置页。最终首启 = 单一引导流（介绍 → 设置 → 锁入口），不再有两个串联 gate。

---

## 为何不是 design-gate 违反

1. **用户主导（user-directed）。** D-03 是 CONTEXT.md 中用户锁定的决策，明确批准在合并后的设置页新增「昵称+头像」两行；不是实现期擅自加的字段。

2. **重组已批准组件，零净新视觉语言。** 新增两行复用两套**均已批准**的视觉成分：
   - 统一「ラベル: 現在値 [変更]」行式样（D-10）——与基线设计稿三设置行同一 `_SettingsRow` 行模式（标签 + 当前值 + `変更` 触发器）。
   - 既有身份采集控件——昵称文本输入 + `AvatarDisplay`/`AvatarPickerScreen`，原样取自已上线的 `ProfileOnboardingScreen`（`warmEmojis` 默认头像、`_ProfileGradientButton` 渐变确认按钮）。

   两套成分都在既有 UI 中存在并经审查；合并只是把它们放进同一页，**未引入任何新控件类型、新配色、新排版语言**（配色仍 `context.palette` ADR-019 桜餅×若葉，文案仍全经 `S.of(context)`）。

3. **确认语义/文案未变。** 确认按钮仍锁定 `この設定で始める`（`onboardingStart`），与 53-01 元素 10、54-02 ARB 单一所有者一致；「只显默认值 + 按需変更弹窗 + 可后改提示」哲学（53-01 元素 8/9/10）原样保留。

---

## 对 53-01 基线的差异小结

| 维度 | 53-01 基线（sketch 001 tone-A） | 54-05 实现 | 差异判定 |
|---|---|---|---|
| 设置行数 | 3（语言/通貨/语音） | 5（+昵称/头像） | **有意新增**（D-03） |
| 行式样 | 「ラベル: 現在値 [変更]」 | 同上（`_SettingsRow`） | 一致 |
| 确认文案 | `この設定で始める` | `この設定で始める` | 一致 |
| default-only + 可后改提示 | PRESENT | PRESENT（`onboardingSettingsHint`） | 一致 |
| 配色/文案体系 | ADR-019 + i18n | `context.palette` + `S.of(context)` | 一致 |

---

## QA 结论

**PASS（有意偏离 · 已说明）。** 合并后的设置页对 sketch 001 tone-A 的唯一偏离 = 新增昵称+头像两行，属 D-03 用户主导决策，重组已批准组件、零净新视觉语言、确认文案锁定不变。该偏离**不构成 design-gate 违反**，无需新出/重做 HTML 设计稿。下游 UI 审查（如 `gsd-ui-review`）应以本记录 + 53-01 基线 QA 为对照基准。

---

**交叉引用:**
- D-03 决策 — `.planning/phases/54-onboarding-flow/54-CONTEXT.md`
- 基线设计稿 — `.planning/sketches/001-onboarding-gate/index.html`（tone-A，第 48–98 行）
- 基线 QA — `.planning/phases/53-html/53-01-onboarding-qa.md`
- 实现 — `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart`
