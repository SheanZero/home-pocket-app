# Host 瘦身收官 + Voice 对象边界 + 隐私降级设置 + reset/mirror & policy 组合测试

**日期:** 2026-07-07
**时间:** 16:05
**任务类型:** [重构|功能开发|测试]
**状态:** 已完成
**相关模块:** [MOD-009] VoiceInput / 记账录入（manual_one_step）+ [MOD-008] Settings
**Quick Task:** 260707-kfb（`.planning/quick/260707-kfb-host-voice-reset-mirror-policy/`）

---

## 任务概述

quick-260707-bwy 的续作，一次性交付 5 个用户预定的可交付物：把宿主 `manual_one_step_screen.dart`
剩余段落机械拆到同库 part 使其 <800 行、把 voice 的 part 耦合升级为纯 Dart 对象边界、给隐私相关的
「设备端识别自动降级」补上用户可关闭的产品面、并补齐 reset/mirror 与 notice/conversion policy 两组
非 happy-path / 组合测试。以三波顺序 executor（A→B→C）在 `main` 上无 worktree 执行，orchestrator 亲跑
全量 `flutter analyze` + full `flutter test` + `custom_lint` 闸。

---

## 完成的工作

### 1. GROUP A — 宿主瘦身 + 非 happy-path 测试（item 1 & 4）
- `manual_one_step_screen.dart` **946 → 599 行**（543 非空，<800）。keypad/currency/save 三段抽到同库 part：
  `manual_one_step_keypad.dart`(91) / `manual_one_step_currency.dart`(201) / `manual_one_step_save.dart`(128)，
  照 `manual_one_step_voice_wiring.dart` 先例（`part of` + `extension on _ManualOneStepScreenState`）。
- 唯一 sanctioned 变换：`setState(...)` → `_rebuild(...)`（8 处；`setState` 是 `@protected`，extension 不可达，
  新增 `void _rebuild(VoidCallback apply){ if(mounted) setState(apply); }`）。`dart format --set-exit-if-changed`
  0 变更，证字节忠实搬移。
- A1 characterization/非 happy-path 测试（8 条，**搬移前**先写并在旧宿主上绿——作为漂移探针）：keypad/currency/
  save 特征化 + 4a（语音填充后手编辑保 `EntrySource.voice`）+ 4b（reset 还原 `_lastFillWasVoice`）+ 4c（外币
  三元组已写后 mirror 写 booked JPY 且不清 triple，D-4）。全部断言可观察面，不碰私有字段。

### 2. GROUP B — Voice 对象边界 + 优先级锁（item 2 & 5）
- 纯 Dart `VoiceAmountNoticePolicy`(132，零 import) + `VoiceFillDecision`(73，仅 application→domain 一个 import)
  抽到 `lib/application/voice/`（与既有纯对象 `AmountArbiter` 同层同目录；按 CLAUDE.md 放置规则，业务 policy 属
  application 层，`features/*/domain/` 只放 model + repo 接口）。零 Flutter / State / BuildContext。
- 两 mixin part 改为委托：`_showVoiceAmountNotice` switch pure policy 的 variant 再映射到既有 ARB 文案/
  `NumberFormatter`/undo·adopt 闭包；`_fillFormFromTextInner` 依 `VoiceFillDecision` 的布尔计划驱动写入/换算/通知。
  所有 async IO、`mounted`/`pttFormState` 守卫、末尾 `onPttCommitted` 留 State。既有 1A/1E/2B/kzr/saz 锁零改断言。
- B2 组合测试锁 **conversion-undo > repair-adopt > large-amount**（断言 decision variant + 数值 payload，
  copy-independent；含双 repair 抑制、阈值 `==`/`-1` 边界、fill-gating 9 例）。

### 3. GROUP C — 隐私降级产品面（item 3）
- `AppSettings.voiceAllowOnDeviceFallback`（freezed `@Default(true)`，向后兼容）+ repo 接口/impl setter，
  经 plaintext SharedPreferences key `voice_allow_on_device_fallback` 持久化，**无 Drift 迁移**（schemaVersion 仍 23，
  镜像 `biometricLockEnabled`/`voiceLanguage`）。
- `SpeechRecognitionService.startListening` 增 `bool allowOnDeviceFallback = true`，进 `_lastConfig` 供
  `restartListen` replay；fallback 守卫改 `if (!wantOnDevice || !allowOnDeviceFallback) rethrow;`——**仅管云端
  RETRY**，on-device 尝试字节不变。经 `StartSpeechRecognitionUseCase` 透传，两 mixin 落点读
  `appSettingsProvider.value?.voiceAllowOnDeviceFallback ?? true`。
- `voice_section.dart` 增设备端状态指示（`cloud_queue`↔`phonelink_lock`）+ 降级开关（默认 ON=允许降级）。
  3 新 ARB key ×{ja,zh,en} + `gen-l10n`（`git add -f lib/generated`）。
- **状态是 policy 非硬件探测**：`speech_to_text` 7.x 无同步「是否支持 on-device」查询，指示器反映有效策略。

### 4. 代码变更统计
- 38 文件，+2406 / −458（仅本任务 `a8ad4a6d^..HEAD`）。零新包、零 Drift 迁移、零 golden 重基线。
- 11 commit：A1 `a8ad4a6d`、A2 `4c4a6c34`、B1 `998c8341`、B2 `62829c3a`、C1 `4c5af415`、
  chore `0aa056a6`、C2 `2ec781e4`、C3 `efe62712`、gate-fix `d11b0019`、gate-fix `12956876`、docs `6a517ec4`。

---

## 遇到的问题与解决方案

### 问题 1: 全量 analyze 抓到 7 个 invalid_override（scoped 漏）
**症状:** C2 给 `StartSpeechRecognitionUseCase.startListening` 加 `allowOnDeviceFallback` 后，full `flutter analyze`
报 7 个 `invalid_override`——5 个测试文件里的 6 个 speech test double override 未带新 named param。
**原因:** executor 的 scoped verify 只跑指定测试文件 + `flutter analyze lib/...`，未覆盖 `test/` 下散落的其它 double；
Dart 中 override 必须接受基类声明的全部 named 参数，否则是编译期错误。
**解决方案:** 给 6 个 override 各补 `bool allowOnDeviceFallback = true`（fake 忽略之，行为中性）。commit `d11b0019`。
这正是 MEMORY「post-merge gate mismatch」——orchestrator 亲跑全量闸是必需。

### 问题 2: full test 唯一失败——settings deep-link scroll 测试
**症状:** `settings_screen_scroll_to_security_test.dart` case 1 断言 `SecuritySection` findsNothing（+3723 −1）。
**根因（经验定位，非臆测）:** 只把 `voice_section.dart` revert 回 C3 前 → 4 case 全绿；证 C3 变高的 VoiceSection 是触发源。
机制 `_maybeScrollToSecurity` 单次 `jumpTo(maxScrollExtent)` 后一帧内读 `_securitySectionKey.currentContext`，
context 为 null 即 bail。300px 病态视口下变高的列表把 lazy `SecuritySection` 推出可构建区 → context null → 跳过
`ensureVisible`。**关键判据:** 同文件 D-10 两 case 已用 390×844 且在 C3 后仍绿（其断言 `SetPinScreen` 只在
context 命中分支触发）——证生产机制在真实视口下不受影响。
**解决方案:** 把 case 1 视口对齐到 390×844。**生产 `settings_screen.dart` 不改**（曾试 bounded-retry，无益于 300px
且给纠缠的 onboarding 代码增复杂度，已弃）。commit `12956876`。上方 tile 高度从来不是契约。

### 问题 3: build_runner 顺手同步了越界的 stale generated 注释
**症状:** C1 跑 build_runner 时 `voice_parse_result.freezed.dart` 出现纯注释 diff（不在 C 组计划文件内）。
**解决方案:** 单独 `chore` commit `0aa056a6`——revert 它会让已提交 generated 与源不同步、过不了 AUDIT-10 stale 检查。

---

## 测试验证

- [x] `flutter analyze` = 0 issues（全量）
- [x] `dart run custom_lint` = 0（`No issues found!`；新 `application/voice/` 仅 import domain、mixin 跨 feature 为相对
      import，deny-mode 守卫不匹配 → 无需 whitelist）
- [x] full `flutter test` = **3724 passed + 11 skipped，0 failed**（exit 0）
- [x] 宿主行数 spot-check：`grep -vc '^$' manual_one_step_screen.dart` = 543（<800）
- [x] `dart format --set-exit-if-changed` 证 A2 字节忠实
- [ ] 设备端 UAT（隐私降级开关关闭后 on-device 失败是否如期报错而非静默走云端）——建议真机确认，随本 voice 线的 on-device UAT 习惯

---

## Git 提交记录

```bash
6a517ec4 docs(quick-260707-kfb): host slim + voice policy objects + privacy-degradation setting + reset/mirror & policy tests
12956876 test(quick-260707-kfb): use realistic viewport for settings deep-link scroll test
d11b0019 fix(quick-260707-kfb): conform speech-recognition test doubles to allowOnDeviceFallback param
efe62712 feat(quick-260707-kfb): settings voice on-device status + auto-degradation toggle (C3)
2ec781e4 feat(quick-260707-kfb): thread allowOnDeviceFallback into speech recognition fallback guard (C2)
0aa056a6 chore(quick-260707-kfb): sync stale voice_parse_result.freezed.dart comment drift
4c5af415 feat(quick-260707-kfb): AppSettings.voiceAllowOnDeviceFallback + repo persistence (C1)
62829c3a test(quick-260707-kfb): lock notice precedence + fill-gating (B2)
998c8341 refactor(quick-260707-kfb): extract pure VoiceFillDecision/VoiceAmountNoticePolicy (B1)
4c4a6c34 refactor(quick-260707-kfb): extract keypad/currency/save into same-library parts (A2)
a8ad4a6d test(quick-260707-kfb): pin manual_one_step reset/mirror/provenance behavior (A1)
```

分支 `main`（本地领先 `origin/main`，含 bwy 等未推送提交）。用户自行处理 push/merge。

---

## 后续工作

- [ ] 隐私降级开关的真机 UAT（关闭后 on-device 失败应显式报错而非静默降级）。
- [ ] on-device「可用性」目前是策略投影而非真实硬件能力探测——`speech_to_text` 7.x 无同步能力 API；若日后需真实
      探测，需插件侧新 API。
- [ ] 宿主 keypad/currency/save 段落已抽出；如后续继续把语音接线等按对象边界深化，可复用本次 pure-object 手法。

---

## 参考资源

- 计划/总结：`.planning/quick/260707-kfb-host-voice-reset-mirror-policy/260707-kfb-{PLAN,SUMMARY}.md`
- 前作：quick-260707-bwy（MOD-009 P0+P1 收官）、260706-saz（`AmountArbiter` 提取）、260706-tm6（on-device Tier 0）
- 规则：CLAUDE.md（放置规则/i18n/SharedPreferences 设置/import_guard）、`.claude/rules/worklog.md`

---

**创建时间:** 2026-07-07 16:05
**作者:** Claude Opus 4.8 (1M context)
