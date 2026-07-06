---
phase: quick-260706-tm6
plan: 01
subsystem: voice
tags: [voice, corpus, tdd, speech-to-text, offline, privacy]
requires:
  - quick-260706-saz (voice P0 consolidation — VoiceTuning / AmountArbiter homes)
provides:
  - zh/ja golden corpus two-tier scheme (voiceCorpusZhGolden/JaGolden + KnownGaps)
  - ManualEntrySnapshot / VoiceLocaleReadinessMixin / keypad-mirror direct tests
  - on-device recognition default + session-scoped silent fallback (offline Tier 0)
  - speech_to_text 7.3.0 iOS pause-concat read-only audit (this doc, §插件审读)
affects:
  - future sherpa on-device STT task (privacy toggle deferred there)
  - MOD-009 §10 P0-4/P0-5/P0-6 closure
tech-stack:
  added: []
  patterns:
    - two-tier corpus (strict golden + skip-documented known-gap, no stats-gate pollution)
    - single listen call-site fallback (session-latched degrade flag)
key-files:
  created:
    - test/integration/voice/voice_corpus_zh_golden_test.dart
    - test/integration/voice/voice_corpus_ja_golden_test.dart
    - test/widget/features/accounting/presentation/screens/manual_one_step_snapshot_test.dart
    - test/unit/features/accounting/presentation/screens/voice_locale_readiness_mixin_test.dart
    - test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart
  modified:
    - test/fixtures/voice_corpus_zh.dart (append-only)
    - test/fixtures/voice_corpus_ja.dart (append-only)
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart (append-only group)
    - lib/infrastructure/voice/numeral_state_machine.dart (Rule 1 shallow fix)
    - lib/shared/constants/voice_tuning.dart (preferOnDeviceRecognition)
    - lib/infrastructure/speech/speech_recognition_service.dart (onDevice + fallback)
decisions:
  - "俩/仨/廿/卅 与口语缩放（两千五/一万五）一律入 known-gap 不修（plan 显式指令；缩放语义与零省略位值直读 anchor 冲突）"
  - "十万/百万 类 万-flush implicit-1 误触发按 Rule 1 浅修（1 行语义修复，569 voice 测试零回归）"
  - "小数口形 known-gap 的 expected 按 Arabic 小数路径 round() 折算（3.5→4、10.5→11）"
  - "onDevice 降级 catch on Exception（不含 Error）；仅 wantOnDevice 时重试一次，降级路径异常原样传播"
metrics:
  duration: "~3h wall-clock（跨一次 session-limit 中断，2026-07-06 12:29 UTC 起）"
  completed: 2026-07-07
  tests-before: 3632
  tests-after: "3675 passed + 11 skipped (known-gap 档)"
status: complete
---

# Quick 260706-tm6: Voice P0 语料移植 + 薄弱测试补齐 + on-device 离线 Tier 0 Summary

zh/ja 黄金语料两档制落地（cn2an/Kanjize/NeMo-ja 移植，17 golden 全绿 + 11 known-gap 全 skip 带因）、三处薄弱点直测补齐（snapshot 13 字段 / locale readiness 4 态 / keypad 镜像 4 条非 happy path）、startListening 默认 onDevice:true + 单次同参静默降级 + session 级 latch，附 speech_to_text 7.3.0 iOS pause-concat 只读审读。

## Tasks & Commits

| Task | 内容 | Commits |
|------|------|---------|
| 1 (P0-4) | 黄金语料两档制 + 万-flush 浅修 | `13a25ae3` fix, `80c0e17c` test |
| 2 (P0-5) | snapshot / locale readiness / keypad 镜像直测 | `0e39c44b` test |
| 3 (P0-6 / 离线 Tier 0) | onDevice 默认 + 降级（TDD RED→GREEN）+ 插件审读 | `02fcf907` test(RED), `d2e4169e` feat(GREEN) |

## Verification

- `flutter test`（全量，输出落盘读 exit code）：**exit 0，3675 passed + 11 skipped**（基线 3632 全绿，0 修改 0 失败；+43 新增全绿；11 skip 全部为 known-gap 档）
- `flutter analyze`：**0 issues**
- `git diff b6adb89c..HEAD --name-only`：零 `lib/generated` / `lib/l10n` / `test/goldens` / ARB 变更
- 既有 `voice_corpus_zh_test.dart` / `voice_corpus_ja_test.dart` 零 diff；fixture 仅 append；`manual_one_step_screen_test.dart` 仅 append（+229/-0）
- 新增代码 `// ignore:` 零出现（known-gap 全部 `skip:` 参数）
- `~/.pub-cache/.../speech_to_text-7.3.0` 零写入（只读 sed/grep 审读）；repo `git status` clean

## Known-Gap 清单（P0-4，供折入 MOD-009）

### zh（voiceCorpusZhKnownGaps，9 条，来源 cn2an）

| input | expected | 现返回 | reason（gap 类） |
|-------|----------|--------|------------------|
| 两千五 | 2500 | 2005 | 口语「整千+裸尾数」缩放缺失；与零省略位值直读 anchor（2千2百零4=2204）冲突，非浅修 |
| 两万三 | 23000 | 20003 | 同上（整万+裸尾） |
| 3千2 | 3200 | 3002 | 同上（混写整千+裸尾） |
| 俩块钱 | 2 | null | 状态机缺「俩」口语数词 token |
| 仨百 | 300 | 100 | 缺「仨」token（百 implicit-1 误触发） |
| 廿五 | 25 | 5 | 缺「廿」古体十位 token |
| 卅六 | 36 | 6 | 缺「卅」古体十位 token |
| 三块五 | 4（round 3.5） | 5 | 小数口形超出 int parser 语义；expected 按 Arabic 路径 round() 折算 |
| 十块五毛 | 11（round 10.5） | 15 | 同上 |

### ja（voiceCorpusJaKnownGaps，2 条，来源 Kanjize/NeMo-ja）

| input | expected | 现返回 | reason（gap 类） |
|-------|----------|--------|------------------|
| 一万五 | 15000 | 10005 | 口语「整万+裸尾数」缩放缺失；与 にせんにひゃくよん=2204 anchor 冲突 |
| 千五 | 1500 | 1005 | 同上（整千+裸尾） |

**Gap 结构判断**：缩放类（5 条）是同一个语义深坑——「裸尾数按上一单位/10 放大」的口语读法与现行「零省略位值直读」（既有 anchor 依赖）根本冲突，任何缩放启发式都会回归 にせんにひゃくよん=2204 等 anchor，必须带消歧上下文才能做，不是 parser 侧浅修。token 缺失类（4 条）可低风险补（俩/仨 为 2 行 map entry；廿/卅 需 PackedToken 分支 ~8 行），本次按 plan 显式指令入档不修。小数类（2 条）等 int→decimal 语义决策。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 万-flush implicit-1 误触发（十万→110000）**
- **Found during:** Task 1 RED probe（plan 将 十万/百万/じゅうまん/にじゅうまん円/ひゃくまん 列入 GOLDEN 档，实测全红）
- **Issue:** `NumeralStateMachine.scan()` 在 Unit(10000) flush 时用 `digit == 0 ? 1 : digit`，section 已有累积（十=10）而 digit==0 时仍加 implicit-1 → (10+1)×10000=110000
- **Fix:** 改为 `section == 0 && digit == 0 ? 1 : digit`——implicit-1 只对真正裸 万/まん 生效（1 行语义修复，符合 plan「<20 行 parser 侧浅修」例外条款）
- **Files modified:** lib/infrastructure/voice/numeral_state_machine.dart
- **Regression check:** 全量 voice 测试（569）+ 全量套件（3675）零回归；顺带修正 五百万 5010000→5000000 一类同型错误
- **Commit:** `13a25ae3`

### 非偏差备注

- Task 2 可选 ④（hold_to_talk_bar 最小 widget 测试）**跳过**：`test/widget/.../widgets/hold_to_talk_bar_test.dart` 既有测试已覆盖「渲染 l10n 文案 + mic 图标」与「单击触发 onTap」两条，重写无增量。按 plan「做不完直接跳过并在 SUMMARY 声明，不算 gap」。
- 镜像测试 (a) 初版 `find.text('午饭')` 命中商户输入框+面板转写两处，改为直接断言 merchant TextField controller 文本（测试内部调整，非行为变化）。

## 插件审读：speech_to_text 7.3.0 iOS pause-concat（只读，零改动）

审读对象：`~/.pub-cache/hosted/pub.dev/speech_to_text-7.3.0/darwin/speech_to_text/Sources/speech_to_text/SpeechToTextPlugin.swift`

**① 触发条件**：`didFinishRecognition` 回调里 `pseudoFinal = recognitionResult.speechRecognitionMetadata != nil`（:827，iOS 14+）——iOS 在说话人停顿导致 segment 收束时附带 metadata。该值作为 `maybeFinal` 进入 `SpeechResultAggregator.addResult`（:890-898）：当**上一个结果是 pseudo-final（停顿收束）且新结果不是**（`!maybeFinal && interimFinal`，:894），把停顿前的转写压入 `previousTranscriptions`（:895）。即：**同一 listen session 内停顿 → iOS 17/18 丢弃停顿前词语 → 插件把它们记为 previous 并在后续结果里重新拼回**。:914 起的注释自陈这是对 iOS 17/18 行为变化的模拟修复。

**② 拼接格式**：`results` getter（:921 起）把 previous 各段 + 当前段拼成 `aggregatePhrase`，段间**插入单个 ASCII 空格**（:931-932 与 :940-941：`if aggregatePhrase.last != " " { aggregatePhrase += " " }`）——**有分隔符**。拼接后的 aggregate 作为 alternates[0]（primary transcript，confidence 取各段最小值），未拼接的当前段原样跟在 alternates 后面。

**③ 与 L1 voice_chunk_merger 的双重拼接风险**：结论 **LOW（现有 260703 四层防线覆盖）**。
- 插件拼接发生在**单 session 内跨停顿**（前段+空格+后段，整体重发）；merger 拼接发生在**跨 finalResult 的 2.5s 窗口**。重叠场景：pseudo-final 先发「五百」（merger 提交 500），随后 aggregate 发「五百 三十」——merger 的 `_mergePositionalDigit` tail-fits 检查不满足（530 ≥ scale 100）时走 **last-wins**，aggregate 的完整读数**取代**而非叠加先前提交，不产生 500+530 双计。
- 空格分隔意味着 ITN 跨停顿劈开的单个数字（「2500 46元」形）正是 260703 spaced-router（`_spacedRoundGroupPattern` → 状态机位值合并）设计的输入形状，已有防线直接接住。
- alternates 中保留未拼接的当前段原文，260703 1a/1D 的 alternates 交叉验证仍有原始读数可用。
- 残余注意点（非本次范围）：aggregate 的 confidence 取段间最小值，若未来有按置信度过滤的逻辑需注意拼接结果天然偏低。

**④ 版本事实**：pubspec `speech_to_text: ^7.0.0` 实际解析 **7.3.0**（pubspec.lock；`flutter pub outdated` 显示 7.4.0 available）。MOD-009 §9.1 所记 **7.4.0 为上游最新版本，非本地安装版本**——文档回填时应记 7.3.0 并注明差异。

## Self-Check: PASSED

- Files: 5 created + 6 modified 全部存在于 HEAD（`git diff b6adb89c..HEAD --stat` 11 files, +1439/-2）
- Commits: `13a25ae3` `80c0e17c` `0e39c44b` `02fcf907` `d2e4169e` 均在 `git log` 中
- 全量 `flutter test` exit 0（3675+11skip）；`flutter analyze` 0 issues；working tree clean
