# MOD-009: 语音记账模块 - 架构文档（as-built）

**文档编号:** MOD-009
**文档版本:** 2.1
**创建日期:** 2026-02-22
**最后更新:** 2026-07-07
**状态:** 已实施（as-built 现状架构）
**作者:** Claude (Fable 5)，人工评审待定

> **v2.0 说明：** v1.0（2026-02-22）是实现前的技术设计稿（FR 规格 + 代码草图），其内容已被 Phase 20/23/40-42/49-52 与 quick task 260614/260622/260703/260706 系列的实际实现全面超越。v2.0 重写为**现状架构梳理 + 生态调研 + 改进路线**三部分。梳理时点 HEAD = `d8509872`（quick-260706-kzr 之后）。历史设计稿见 git history 中的 v1.0。
>
> **v2.1 更新（2026-07-07）：** §10 路线图 P0 全部六项与 P1-7/8 已由 quick-260706-saz / 260706-tm6 / 260707-bwy 落地——AmountArbiter（`lib/application/voice/amount_arbiter.dart`）、VoiceTuning（`lib/shared/constants/voice_tuning.dart`）、stop/reset 去重、黄金语料两档制（17 golden + 11 known-gap）、薄弱测试补齐、onDevice 离线默认开+静默降级（`VoiceTuning.preferOnDeviceRecognition`）、插件拼接审读（双拼风险 LOW，详见 260706-tm6 SUMMARY）、mixin 拆三文件（591/320/196，同库 part + extension 形态）、宿主语音接线抽出（残余 946 行，keypad/currency 段留待后续）、alternates 币种矛盾压制。**§2/§3/§8 中的 mixin 行号锚点与 S1/S2/S4/S5 痛点描述截至 v2.0 时点，拆分后已部分失效——以代码为准。** P1-9 sherpa spike 与 P2/P3 未动。另：§9.1 的 7.4.0 为调研时 pub 最新版，仓库实际解析 **7.3.0**（concat 逻辑在 `SpeechToTextPlugin.swift` :915-920 一带）。

---

## 目录

1. [模块概述](#1-模块概述)
2. [分层架构与文件地图](#2-分层架构与文件地图)
3. [端到端数据流](#3-端到端数据流)
4. [金额解析防线体系](#4-金额解析防线体系)
5. [识别-分类子系统](#5-识别-分类子系统)
6. [会话状态机与生命周期](#6-会话状态机与生命周期)
7. [测试覆盖映射](#7-测试覆盖映射)
8. [架构痛点清单](#8-架构痛点清单)
9. [生态调研（2026-07）](#9-生态调研2026-07)
10. [改进路线图](#10-改进路线图)
11. [演进时间线](#11-演进时间线)

---

## 1. 模块概述

语音记账允许用户以自然语言口述一笔支出（「刚刚吃饭用了五千三百一十二日元」），系统实时转写并抽取**金额 / 币种 / 日期 / 类目 / 商家 / 满意度**六个槽位自动填充表单。两条交互路径：

- **连续点按会话（主路径）**：`ManualOneStepScreen` 底部「语音记录」bar → 内联 `VoiceRecordPanel` 替换数字键盘 → 边说边填（partial 实时、category/currency/notice 在 final 才 resolve）→ 点空白退出保留内容。one-shot 聆听模型：识别器自然终止即停，点红色重置方块恢复快照重录。
- **legacy hold 路径**：`VoiceInputScreen` 按住说话、松手提交。与主路径共享同一 `VoicePttSessionMixin`（reuse-not-rewrite，260622-nhs D-3），以 `_continuousActive` 为唯一分叉开关。

技术底座：`speech_to_text`（系统 STT）+ 自研规则 NLP（中日数字状态机 + 正则路由 + 关键词/商家双引擎 + 纯 reconciler）。无云端依赖，符合 local-first 约束（注：音频经过 iOS/Android 系统语音服务，见 §9/§10 的隐私升级路线）。

---

## 2. 分层架构与文件地图

依赖方向严格遵守 Presentation → Application → Domain ← Data ← Infrastructure（例外见 §8 S3）。

### infrastructure 层（STT 封装 + 数字状态机）

| 路径 | LOC | 职责 | 关键符号 |
|---|---|---|---|
| `infrastructure/speech/speech_recognition_service.dart` | 170 | 封装 speech_to_text 插件；平台音量归一化；`restartListen` 配置缓存 | `initialize` `startListening` `restartListen` |
| `infrastructure/voice/numeral_state_machine.dart` | 223 | 数字 token 分类学 + `scan` 累加器基类（ITN 位值合并 L0、`detectCurrencyToken`） | `NumeralStateMachine` `NumeralToken`(sealed) |
| `infrastructure/voice/chinese_numeral_state_machine.dart` | 127 | 中文汉字/阿拉伯 → int，`零` 显式占位 | `parse` `normalize` |
| `infrastructure/voice/japanese_numeral_state_machine.dart` | 158 | 日文假名/汉字贪婪最长匹配 → int | `parse` `normalize` |
| `infrastructure/voice/japanese_numeral_dictionary.dart` | 64 | 30 条假名→token 词典（浊音/促音变体） | `japaneseNumeralDictionary` |

### application 层（解析编排 + 防线 + 双引擎）

| 路径 | LOC | 职责 | 关键符号 |
|---|---|---|---|
| `application/voice/start_speech_recognition_use_case.dart` | 52 | 薄封装 service，隔离 presentation↛infra | — |
| `application/voice/parse_voice_input_use_case.dart` | 441 | **编排器**：金额/日期/货币/keyword → 双引擎 → reconciler → ledger 派生 | `execute` `kMerchantAutoFillFloor` |
| `application/voice/voice_text_parser.dart` | 593 | 金额路由 station（Arabic/状态机/spaced/comma 四路）+ 日期抽取 | `extractAmount` `extractDate` `detectConcatRepairCandidate` |
| `application/voice/amount_magnitude_guard.dart` | 336 | L4 纯函数：量级词（千/万/thousand）→ 期望位数 | `expectedDigitCountForAmount` |
| `application/voice/english_number_words.dart` | 76 | 有界英文数字词解析（与 CJK 机隔离） | `parseEnglishNumberWords` |
| `application/voice/voice_chunk_merger.dart` | 243 | 跨 final 的 2.5s 窗口缓冲 + 双闸合并（L1） | `feedChunk` `stop` |
| `application/voice/voice_satisfaction_estimator.dart` | 203 | 音频特征+文本情感 → 1-10 满意度（仅 Joy） | `estimate` |
| `application/voice/recognition/category_recognizer.dart` | 195 | keyword 引擎：精确→learned(hitCount≥3)→seed 子串 | `resolve` `normalizeToL2` `resolveLedgerType` |
| `application/voice/recognition/merchant_recognizer.dart` | 200 | 商家锚定打分器（5 tier，recall-first） | `recognize` |
| `application/voice/record_category_correction_use_case.dart` | 30 | 纠正学习：(keyword,categoryId) hitCount 累加 | `execute` |
| `application/voice/repository_providers.dart` | 42 | speech/状态机 provider | — |
| `application/accounting/seed_voice_synonyms_use_case.dart` | 34 | 幂等 seed 语音同义词 | — |

### domain 层（纯值对象 + 纯仲裁）

| 路径 | LOC | 职责 |
|---|---|---|
| `features/voice/domain/models/voice_parse_result.dart` | 127 | freezed 结果对象（含 `amountRepairCandidate` 双生产者语义） |
| `features/voice/domain/models/merchant_candidate.dart` | 32 | 商家候选（raw score） |
| `features/voice/domain/models/recognition_outcome.dart` | 57 | reconciler 输出 + `ConfidenceBand` |
| `features/voice/domain/services/recognition_reconciler.dart` | 123 | **纯 3×3 truth table**（keyword-priority 合并） |

### presentation 层（会话 mixin + 屏幕 + 组件）

| 路径 | LOC | 职责 |
|---|---|---|
| `…/screens/voice_ptt_session_mixin.dart` | **1075** ⚠ | 会话生命周期巨石：录音/转写/parse/merger/金额仲裁/外币/satisfaction/notice |
| `…/screens/voice_recognition_event_handler_mixin.dart` | 139 | onStatus/onError 基类（D-05 intra-session 门） |
| `…/screens/voice_locale_readiness_mixin.dart` | 99 | cold-start locale 就绪门 |
| `…/screens/manual_one_step_screen.dart` | **1027** ⚠ | 宿主（keypad + 语音接线，三 mixin 合成） |
| `…/screens/manual_one_step_snapshot.dart` | 110 | `ManualEntrySnapshot` reset 快照/还原 |
| `…/screens/voice_input_screen.dart` (+helpers) | 512+93 | legacy hold 屏幕 |
| `…/widgets/voice_listening_overlay.dart` | 402 | 内联 `VoiceRecordPanel`（双态方块） |
| `…/widgets/hold_to_talk_bar.dart` | 108 | `VoiceRecordBar` 入口 bar |
| `…/widgets/voice_waveform.dart` / `voice_error_toast.dart` | 58/52 | 声波 / 错误 toast |
| `features/settings/…/voice_section.dart` (+utils) | 87+14 | 语音语言设置 |
| `…/providers/repository_providers.dart` :253-307 | — | 语音 DI 组合根（`parseVoiceInputUseCaseProvider` 等） |

### shared

| 路径 | LOC | 职责 |
|---|---|---|
| `shared/constants/voice_currency_suffixes.dart` | 149 | 全货币后缀 token + tokenToIso + longest-first 正则 |

---

## 3. 端到端数据流

### 3.1 连续点按会话（主路径）

```
VoiceRecordBar.onTap (manual:981)
  → _onVoiceRecordTap (manual:300)  守卫: initialized && localeReady && !modalOpen
  → ManualEntrySnapshot.capture (manual:304)   ← reset 的还原基线
  → _voiceModalOpen=true → startPttTapSession (mixin:589, _continuousActive=true)
  → startPttSession (mixin:243)  listenFor:30s pauseFor:3s
  ├─ partial (mixin:920): _partialText ← ；300ms debounce → _parseVoiceInput
  │    → _fillFormFromText(fillCategory:false)   ← 实时填 amount/merchant/date，扣住 category
  ├─ final (mixin:931): merger.feedChunk(isFinal) + 收集 result.alternates.skip(1)
  │    → _parseFinalResult(text, alternateTexts) → _fillFormFromText(data:parsed)
  │         resolve-on-final 门: category 查库/updateRecognition/外币换算/全部 notice 只在此时
  │         金额仲裁 (mixin:381-416): _mergedAmount ?? data.amount
  │           例外① concat: detectConcatRepairCandidate(merged)==parsed → parsed 胜
  │           例外② magnitude: merged 违反期望位数而 parsed 满足 → parsed 胜
  ├─ onPttCommitted → 宿主 _lastFillWasVoice=true + keypad 镜像 (manual:165-188)
  └─ 退出: 点空白 exitPttTapSession / 红方块 _onVoiceReset(快照还原+复活重录)
保存: form.submit(entrySource: voice|manual) (manual:932)
```

### 3.2 legacy hold 路径的分叉点

与主路径共用同一 mixin 的 `startPttSession`/`_onResult`/merger/parse/fill/foreign/satisfaction；全部分叉以 `_continuousActive` 为开关：

| 分叉 | 连续 tap | legacy hold |
|---|---|---|
| partial live-fill | ✅（mixin:984） | ❌ 只刷新 `_parseResult` |
| final fill | 立即（mixin:956-966） | 延迟到松手 `stopPttSessionAndCommit`（`_cachedParseFor` 缓存复用） |
| onError | 自定分类（§6） | `super.onError` 基类原样 |
| onStatus terminal | one-shot 停机不 re-arm | 基类 pressStart 驱动 |
| 误触 | — | <300ms 松手 → `cancelPttSessionAndDiscard` |

---

## 4. 金额解析防线体系

针对「iOS ITN 拼接毒化」（系统把「两千五百四十六」归一化为 "2500"+"46" 再拼成 "250046"；插件层 7.1.0 起还会把 pause 重置后的分段**字符串拼接**，放大该问题）的五层纵深：

| 层 | 触发条件 | 代码位置 | 修哪种变体 |
|---|---|---|---|
| **L0** scan 位值合并 | 相邻 Digit，前者尾 0≥1、后者 < scale | `numeral_state_machine.dart:203` | 空格分隔「2500 46」→2546 |
| **L1** merger 空格拼接+整百开放 | 跨 final 两段；`_bufferLooksOpen`（末 Unit≥100 或末 Digit≥10 且 %10==0） | `voice_chunk_merger.dart:114,170-192` | 「2500」+「46元」跨 final；5310+2 |
| **L2** spaced 路由 | 「圆整组+1~2位尾+货币后缀/EOS」签名 | `voice_text_parser.dart:63`，路由 :126 | 单条转写内「2500 46元」强制走状态机 |
| **L3** concat 探测 + alternates 采用 | 金额数字串逐字在 transcript 中；5-9 位、尾可嵌 head 尾零 | 探测 `voice_text_parser.dart:152`；采用 `parse_voice_input_use_case.dart:99-114` | UNSPACED「250046」→2546；alternate 独立解析出候选→静默采用，否则挂 `amountRepairCandidate` 一键确认 |
| **L4** 量级位数仲裁 | rawText/alternate 含量级锚（千/仟/せん/ぜん→乘数位数+3；万/萬/まん→+4；thousand）且 resolvedAmount 位数违反 | 期望 `amount_magnitude_guard.dart:98`；use-case 仲裁 `parse_voice_input_use_case.dart:132-150`；display 仲裁 `mixin:403-416` | 「3千5百16」必须 4 位；「53102」+alternate「五千三百一十二」→5312 |

L4 采用阶梯（`_adoptByMagnitude`，只采位数==期望的候选，precision over recall）：①L3 候选 → ②状态机/英文词重读 primary → ③逐条 alternate 全路由重解析。采用后 **candidate swap**（原读数换进 `amountRepairCandidate`）使既有 1A notice 变「一键改回原值」。

金额 notice 三级（每 final 至多一条，`mixin:485-558`）：conversion-undo(2B) > repair-adopt(1A) > large-amount ≥¥1M(1E)。

**设计公理**（生态调研 §9 佐证）：partial 结果会被全量重写（含数字重切分+重 ITN），金额**只能 resolve-on-final**——现行设计正确，勿与 partials 搏斗。

---

## 5. 识别-分类子系统

```
                 ┌───────────────────────┐
 keyword ───────►│ CategoryRecognizer     │──► CategoryMatchResult? (conf 0.80~1.0)
 (canonical单键)  │ keyword-only, 无条件跑  │        │
                 └───────────────────────┘        ▼
                 ┌───────────────────────┐  ┌──────────────────────┐
 merchantQuery ─►│ MerchantRecognizer     │─►│ RecognitionReconciler │─► RecognitionOutcome
 (=keyword|raw)  │ 5-tier 锚定打分         │  │ 纯 3×3 truth table    │   {selectedCategoryId,
                 │ recall-first,无 floor   │  └──────────────────────┘    band, alternates,
                 └───────────────────────┘        ▲ 0.85 floor           conflict}
                                                  │ (orchestrator 持有)
```

- **调用序**（全在 `ParseVoiceInputUseCase.execute`）：金额+防线 → `_detectCurrency`（与金额分离扫描，bare 元/円全语区 native）→ `extractDate` → `_extractKeyword`（canonical 单键，write==read 契约 T-50-06）→ 引擎 A/B 独立 → reconcile → ledger 派生（`resolveLedgerType(finalCategoryId)`，**绝不用** merchant ledger hint，LEDGER-01）。
- **truth table**（`recognition_reconciler.dart:31-93`）：keyword 永远胜；merchant≥0.85 仅在 keyword=null 时 medium 自动填（还需 `normalizeToL2` 非 null）；异 L2 时 `conflict=true`；below-floor 只作为 Phase-52 chips 上浮，绝不自动填（ADR-012）。
- **纠正学习闭环**：表单改类目 → `RecordCategoryCorrectionUseCase` hitCount 累加 → hitCount≥3 晋升 learned（`kLearnedPromotionThreshold`），CategoryRecognizer 优先命中。write-key==read-key 靠 `resolvedKeyword` 单一 canonical key 保证（260526-pg6）。
- **merchant 打分 tier**：exact 1.00 / alias-prefix 0.85 / anchored-prefix 0.85(>50%) / contain 0.60 / reverse 0.55；脚本最小长度门（kanji≥2 / kana-latin≥3）防误报。

---

## 6. 会话状态机与生命周期

**核心状态**（mixin）：`_pttServiceInitialized` `_isRecording` `_continuousActive`（路径分叉主控）`_restarting`（reset reentrancy fence）`_parsing`（→processing 显示态）`_listenStatus{listening,processing,stopped}` `_partialText/_finalText` `_mergedAmount` `_lastFilledAmount`；宿主侧 `_voiceModalOpen` `_voiceSnapshot` `_lastFillWasVoice`。

**关键转换**：

| 事件 | 位置 | 转换 |
|---|---|---|
| 识别器自终止（连续） | `onStatus` mixin:816 | **one-shot 停机**：stopped，不 re-arm（iOS re-arm 会麦克风假死却状态卡 listening） |
| reset 期间 terminal | mixin:805 | `_restarting` 期间直接吞（防 double-start 假死） |
| 静默错误 | mixin:754 | `{error_no_match, error_speech_timeout}` 按**错误码**白名单（iOS 谎报 permanent:true）→ 干净停机，不 toast 不锁 bar |
| 致命错误 | mixin:774 | teardown + toast + `_recoverBarAfterFatalError`（重 init 解锁 bar）；面板留在 stopped 态 |
| 重置·恢复 | mixin:637 | 守 `_restarting`；cancel→清缓冲+rebuild merger→(必要时 re-init)→startListening；`_continuousActive` **无条件复活**（260706-kax：无论上次会话怎么死，「重新录入」必须生效） |
| app 暂停 | manual:289 | 录音中 → `cancelPttSessionAndDiscard` |

**踩坑记录**（勿回退）：reset 必须 `cancel()` 清识别器内部累积 buffer（只清 app 端文本会带回旧转写）；reset caption 的 `Transform` 必须在 `Visibility` 外层（`maintainSize` 代理盒会挡偏移后的命中）。

---

## 7. 测试覆盖映射

49 个语音专属测试文件：infra 6 / application 金额与解析 9 / recognition 4 / 其他 app 3 / domain 2 / mixin+screen 5 / widget+golden 4 / settings 2 / **三语语料库集成 7 + fixtures 5** / seed 2。

**覆盖薄弱点**：

| 生产文件 | 状况 |
|---|---|
| `manual_one_step_snapshot.dart`（reset 还原核心） | 无直接测试 |
| `voice_locale_readiness_mixin.dart` | 无直接测试 |
| `hold_to_talk_bar.dart` / `voice_waveform` / `voice_error_toast` / `voice_section` | 无直接测试 |
| `seed_voice_synonyms_use_case.dart` | 无 use-case 级测试 |
| 宿主 keypad 镜像逻辑（manual:165-188） | 仅 happy path |
| use-case 采用 × mixin display 采用同时命中的组合 | 无组合测试 |

---

## 8. 架构痛点清单

| # | 痛点 | 证据 |
|---|---|---|
| **S1** | 两个文件超 800 行规约：mixin **1075**、宿主 **1027** | `voice_ptt_session_mixin.dart` / `manual_one_step_screen.dart` |
| **S2** | mixin 巨石：会话状态机+金额仲裁+notice 编排+外币换算+satisfaction 触发混居；三 mixin 抽象契约互相回填（mixin:193-209） | 头注释自陈「ported VERBATIM」 |
| **S3** | 层依赖泄漏：presentation 直连 infra formatter（mixin:43 等 3 处）；mixin 内直接 `VoiceTextParser()` 实例化 + 静态调用（mixin:716/392/407）——金额仲裁**业务逻辑在 presentation**；`kMerchantAutoFillFloor` 为避免 domain→app 依赖而**双份声明** | `parse_voice_input_use_case.dart:21` vs `recognition_reconciler.dart:9` |
| **S4** | 重复逻辑：`stopPttSessionAndCommit` ≈ `exitPttTapSession` 逐行相同；两处 reset 清零重叠；**量级仲裁双写**（use-case + mixin display）；keypad 镜像循环两份 | mixin:277/598/650/1064 |
| **S5** | 魔法数散落：30s/3s 三处、300ms 两义、0.85 四处同值异义、2.5s/800ms/100ms/1M/10M/hitCount≥3、satisfaction 权重与拟合系数 | 详见各文件 |
| **S6** | DI 奇异：`startSpeechRecognitionUseCaseProvider` 无人用（mixin 自建）；merger 另取 service 与 `pttSpeechService` 双封装同底层（`restartListen` 的 `_lastConfig` 缓存跨两封装易漂移）；`voiceLocaleIdProvider` settings→accounting 跨 feature 监听；唯 merchantRecognizer keepAlive | `mixin:217/709`、providers:281 |

---

## 9. 生态调研（2026-07）

完整调研（全部 repo 链接、stars、license、不确定项标注）见 `docs/worklog/20260706_2005_voice_architecture_doc_and_research.md` 附录。摘要：

### 9.1 现役插件 speech_to_text (csdcorp, 470★, v7.4.0)

- README 明确定位「短语，非连续识别」——one-shot 模型是插件层的正确姿势而非缺陷。
- **7.1.0 起 iOS 上把 pause 重置后的识别段字符串拼接**——ITN 毒化的插件层放大器（与系统层 ITN 重写叠加为完整因果链）。
- 无 iOS 26 SpeechAnalyzer 适配迹象；无实质竞品插件（包装系统 STT 的都继承同批 OS 怪癖，换插件不解决毒化）。

### 9.2 离线 ASR 引擎（隐私叙事升级候选）

| 引擎 | 关键事实 | 判断 |
|---|---|---|
| **sherpa-onnx**（k2-fsa, 13.4k★, Apache-2.0, **官方 Flutter 绑定** `sherpa_onnx` 1.13.3） | 流式+VAD+KWS；zh/en 有流式 zipformer；**ja 只有 offline**（ReazonSpeech 35k 小时 / SenseVoice zh-en-ja-ko-yue 段级<80ms）；原生输出 spoken form——**ITN 完全自控** | **最佳引擎替换候选**：根治 ITN 黑盒 + 隐私升级为「音频不出 app」。代价 +200-400MB 模型分发与内存数百 MB |
| vosk（14.9k★） | 官方 Flutter 绑定 2024-10 起停滞；模型代际老（Kaldi TDNN） | **不建议** |
| whisper.cpp（51k★） | 无真流式；静音幻觉风险；Flutter 绑定碎片化 | 仅可做「事后重转写」兜底 |

### 9.3 ITN/数字解析库

- **Dart 生态无可用 ITN/FST 库（已确认）**——自研中日状态机保留为 canonical 实现，无可替代品。
- **cn2an**(764★, zh 数字互转)/**Kanjize**(ja 漢数字)/**NeMo-text-processing**(481★, ja ITN 有 WFST 语法) 的测试用例可移植为本 repo 黄金语料。
- 工业防拼接三模式：①ASR 端关 ITN 拿 spoken form 自己做（sherpa 天然如此，Meta arXiv:2211.03721 同路线）；②n-best 候选统一过数字文法 accept 判定（本 app L3/L4 已是雏形）；③ITN 属 display 层后处理（Azure 文档佐证 resolve-on-final）。

### 9.4 语音记账开源实现

三代演变：cloud NLU SaaS（Speechly，已随收购关停）→ 本地 regex（简陋无多语）→ **STT + cloud LLM slot-filling（2024 起主流，全部依赖云端）**。**未找到任何设备端 LLM slot-filling 的开源记账实现**——Home Pocket 若走该路线属差异化空间，无先例可抄也无隐私妥协先例。

### 9.5 设备端 LLM NLU（兜底层候选）

| 路线 | 事实 | 定位 |
|---|---|---|
| **flutter_gemma**（584★, v1.2.1 2026-07-05, 22.6k 周下载） | function calling 支持 FunctionGemma 270M / Qwen3 0.6B 等；旗舰 GPU ~52 tok/s 可用、**中端 CPU 2-5 tok/s 不可用** | Android 首选；必须置信度门控 + CPU 机型降级 |
| **Apple Foundation Models（iOS 26）** | 系统内置 ~3B；**guided generation 解码层保证 schema**（零 JSON 解析失败）；A17 Pro+ 门槛 | iOS 首选（自写 MethodChannel，现有 Flutter 桥仍 0.1.x beta） |
| llama.cpp（`llama_cpp_dart` 299★） | GBNF grammar 硬约束 JSON | 跨平台备选 |

正确定位：**兜底层而非替换**——规则解析置信度低/槽位冲突时才调用，低端机永远走纯规则路径零延迟惩罚；「满意度」等软槽位（自然语言情绪）是 LLM 明显强项。

### 9.6 平台怪癖与新 API

- iOS `kAFAssistantErrorDomain 1101`（on-device 路径故障，无官方文档）/`203 Retry`（会话尾良性噪声）——与本 app「按错误码分类而非 permanent flag」的修复方向一致。
- **iOS 26 SpeechAnalyzer/SpeechTranscriber**：完全 on-device、为连续/长语音设计（正面回应 one-shot 痛点）、volatile/finalized 两级结果与 resolve-on-final 天然契合、实测比 Whisper large-v3-turbo 快 ~2×。落坑：首启需联网下载语言资产（冲击 local-first 叙事，需 onboarding 处理）、**无 contextualStrings 等价物**（商家热词优化路径断）、**ITN/数字格式化行为未见文档（需真机验证）**。speech_to_text 未适配 → 采用需自写 platform channel + iOS<26 双栈。
- Android：API 33+ `createOnDeviceSpeechRecognizer()` 厂商差异大；ML Kit GenAI STT（Gemini Nano）仍 alpha、设备名单窄。

---

## 10. 改进路线图

### P0 — 内部收敛（纯 Dart、无新依赖、立即可做）

1. **金额仲裁收敛**：把 use-case 与 mixin display 两处量级/concat 仲裁提取为 application 层单一 `AmountArbiter`（输入 {parsed, merged, rawText, alternates}，输出 {adopted, undoCandidate, noticeKind}）——同时解决 S3 业务逻辑泄漏与 S4 双写。
2. **`VoiceTuning` 常量集中**：30s/3s/300ms×2/2.5s/800ms/100ms/0.85×2/1M/10M/hitCount≥3 收口为命名常量单文件（floor 双声明保留 domain 侧，加一致性测试锁值）。
3. **重复合并**：`stopPttSessionAndCommit`+`exitPttTapSession` 合一；两处 reset 清零合一。
4. **黄金语料移植**：cn2an（smart 模式容错、两/俩/仨/廿/卅）、Kanjize（混合记法）、NeMo-ja ITN 用例 → `test/fixtures/voice_corpus_*` 扩充。
5. **补薄弱测试**：snapshot 还原、locale readiness、宿主 keypad 镜像非 happy path、两仲裁站点组合命中。
6. **审读插件 iOS 拼接逻辑**（`SwiftSpeechToTextPlugin` 7.1.0 的 concat 段），确认与 L1 merger 交互无双重拼接。

### P1 — 结构重构 + 引擎 spike（并行、互不依赖）

7. **mixin 拆分**：`VoicePttSessionMixin`(1075) → 会话状态机 / 填充编排 / 外币+notice 三块，各 <800 行；宿主语音接线随之瘦身。
8. **alternates 全槽位文法校验**：L3/L4 的「候选过数字文法 accept」模式推广到日期/币种槽位（工业模式②）。
9. **sherpa-onnx spike**（feature flag 单语区试点，建议 zh）：流式 zipformer + spoken form 直喂自研状态机，实测准确率/体积/内存 vs 系统 STT。**ja 为主语言不可盲切**——ja 需 VAD+SenseVoice 段级方案单独评估（段级识别反而天然规避 partial-rewrite 毒化）。

### P2 — 差异化增强

10. **设备端 LLM 兜底层**：先离线评测（现有三语语料跑 FunctionGemma 270M / Qwen3 0.6B 抽取准确率），达标后按「置信度门控 + 可关闭 + CPU 机型跳过」进 app；iOS 26+ 设备用 Foundation Models guided generation。开源领域无先例，是差异化点。
11. **iOS 26 SpeechAnalyzer 预研**：真机验证 ITN 行为与三语支持清单，跟踪 speech_to_text 适配进度与用户 iOS 26 渗透率，必要时自写 channel。

### P3 — 观察项

12. whisper.cpp 事后重转写兜底（需录音缓存 + 加密义务评估，涉 4 层加密架构）；ML Kit GenAI 跟踪。

---

## 11. 演进时间线

| 时期 | 里程碑 |
|---|---|
| Phase 20 (VOICE-02) | 数字状态机 + chunk merger + 三语语料库地基 |
| Phase 23 | 屏幕拆分：event-handler / locale-readiness mixin 抽出 |
| Phase 40-42 | 外币口语词（currency token 与金额分离扫描） |
| Phase 49 | merchants + match_keys 表（schema v22）+ 归一化 + ~391 seed |
| Phase 50 (DECOUP) | 双引擎解耦，0.85 floor 归 orchestrator |
| Phase 51 (XVAL) | 纯 RecognitionReconciler 3×3 truth table，ledger 后派生 |
| Phase 52 (RECUX/VEN) | confidence band + alternate chips；英文语音（VEN-01） |
| 260614-goh/iww | 外币口语词全三语；连续记账模式 |
| 260622-nhs R1-R8 | 单页 PTT：mixin 提取、内联面板、one-shot 模型、错误分类 |
| 260703 | ITN-concat 四层防线（L0-L3）+ bare 元 native + resolve-on-final 门 |
| 260706-kax | reset 复活死会话 + reentrancy fence + caption 命中修复 |
| 260706-kzr | L4 量级位数守卫（千=4位/万=5位，zh/ja/en） |

---

## 参考资源

- 调研全文（全部 repo 链接与不确定项）：`docs/worklog/20260706_2005_voice_architecture_doc_and_research.md`
- 相关 ADR：ADR-012（低置信度确认而非自动提交）
- 关键外部证据：speech_to_text 7.1.0 changelog（iOS 拼接）、sherpa-onnx 官方 Flutter 绑定（pub.dev `sherpa_onnx`）、arXiv:2211.03721（流式 on-device ITN）、arXiv:2312.09463（partial rewriting）、Apple WWDC25 session 277（SpeechAnalyzer）
