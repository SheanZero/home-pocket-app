# 语音识别整体代码梳理 + MOD-009 v2.0 架构文档 + GitHub 生态调研

**日期:** 2026-07-06
**时间:** 20:05
**任务类型:** 文档 + 调研
**状态:** 已完成
**相关模块:** MOD-009 语音记账

---

## 任务概述

用户要求：将语音识别整体代码进行梳理，产出架构文档，并调研 GitHub 上的实现，给出更完善的改进建议。执行方式：并行两个 agent（代码全量勘察 33+4 文件 / GitHub 生态调研 WebSearch+GitHub API+pub.dev 实时抓取），orchestrator 综合产出 MOD-009 v2.0。

---

## 完成的工作

1. **MOD-009_VoiceInput.md 升级 v2.0**（`docs/arch/02-module-specs/`）：v1.0 设计稿（2026-02-22）重写为 as-built 现状架构——文件地图（37 文件分层清单）、双路径数据流、金额解析 L0-L4 五层防线映射、双引擎+reconciler 识别子系统、会话状态机、测试覆盖映射（49 文件 + 6 项薄弱点）、痛点清单 S1-S6、生态调研摘要、改进路线图 P0-P3、演进时间线。
2. **ARCH-000_INDEX.md** MOD-009 行标注 v2.0。
3. **GitHub 生态调研**（全文见本文附录）：speech_to_text 现状与 iOS 拼接放大器证据、离线 ASR 对比（sherpa-onnx/vosk/whisper.cpp/SenseVoice）、ITN/数字解析库（Dart 生态无替代品已确认）、语音记账开源三代演变、设备端 LLM NLU 路线（flutter_gemma/Apple Foundation Models/llama.cpp）、iOS 26 SpeechAnalyzer 新 API。

### 改进建议要点（详见 MOD-009 §10）

- **P0 内部收敛**：AmountArbiter 提取（修双写+层泄漏）、VoiceTuning 常量集中、stop/exit 合并、黄金语料移植（cn2an/Kanjize/NeMo-ja）、补 6 项薄弱测试、审读插件拼接逻辑
- **P1**：mixin 巨石拆分（1075→3×<800）、alternates 全槽位文法校验、sherpa-onnx zh 试点 spike
- **P2**：设备端 LLM 兜底层（开源无先例，差异化点）、iOS 26 SpeechAnalyzer 预研
- **P3**：whisper 事后重转写、ML Kit GenAI 观察

---

## 测试验证

- [x] 文档遵循 docs/arch 规范（编号不变、v2.0 主版本升级、INDEX 同步更新）
- [x] 代码勘察结论与本 session 前两个 quick task（260706-kax/kzr）的一手代码阅读交叉一致
- [x] 调研报告标注全部不确定项（sherpa 模型实测数据、SpeechAnalyzer ITN 行为、SenseVoice license 等）
- [ ] 人工评审 MOD-009 v2.0

---

## Git 提交记录

见本次 commit：`docs(arch): update MOD-009 voice architecture to v2.0 (as-built + research + roadmap)`

---

## 后续工作

- [ ] 按 P0 清单开 quick task（建议从 AmountArbiter 提取 + 黄金语料移植开始）
- [ ] sherpa-onnx spike 立项前先确认 ja 方案（VAD+SenseVoice 段级）可接受
- [ ] 人工评审改进路线优先级

---

# 附录：GitHub 生态调研全文（2026-07-06）

**调研方式:** WebSearch + GitHub API + pub.dev 实时抓取
**评估基准（本 app 约束）:** local-first/零知识、三语 ja(主)/zh/en、槽位抽取（金额/币种/日期/类目/商家/满意度）、现有栈 speech_to_text + 自研规则解析、已知痛点（iOS ITN 拼接毒化、one-shot re-arm、error_no_match 误报、alternates 仅用于金额交叉验证）。

## 1. Flutter STT 插件生态

### speech_to_text (csdcorp) — 现役插件

- repo: https://github.com/csdcorp/speech_to_text — **470★，BSD-3-Clause，最近 push 2026-07-02，83 个 open issues，维护活跃**（作者响应稳定但节奏慢）
- 版本现状：稳定版 **7.4.0**（约 2026-05 发布：iOS Swift concurrency 修复、Android 开始尊重 `pauseFor`），预发布 **7.5.0-beta.1**（Windows beta）。
- README 明确定位：**"commands and short phrases, not continuous spoken conversion or always on listening"** —— 本 app 的连续记账场景本来就超出其设计范围，one-shot 模型是插件层的正确姿势而非 bug。
- 与本 app 痛点直接相关的证据：
  - **7.1.0 changelog："Attempts to address iOS bug that resets transcription after speech pauses by concatenating results"** —— 插件在 iOS 上会把 pause 后被系统重置的识别段**字符串拼接**起来。这正是「ITN 拼接毒化」的插件层放大器：两段各自经过系统 ITN 的文本（"2500"+"46"）被硬拼接。建议直接审读 `SwiftSpeechToTextPlugin` 的这段拼接逻辑，确认 app 的 merger 防线与它的交互。
  - 连续识别不可靠有长期 issue 佐证：[#253（continuous listening 需自行 workaround）](https://github.com/csdcorp/speech_to_text/issues/253)、[#481（数分钟后 iOS error_listen_failed）](https://github.com/csdcorp/speech_to_text/issues/481)、[#313（iOS 上出词慢）](https://github.com/csdcorp/speech_to_text/issues/313)。
  - changelog 中**没有任何 iOS 26 SpeechAnalyzer 适配迹象**（截至 7.4.0/7.5.0-beta.1）。
  - alternates 质量：iOS 侧 alternates 直接透传 `SFTranscription` 的 n-best，社区经验是通常只有 1~3 个且差异集中在同音词，**数字位值级差异恰好是它少数有价值的场景**（app 已在利用）——经验判断，无官方文档背书。
- 竞品插件：没有实质竞争者。`rxlabz/speech_recognition` 已死；`speech_to_text_ultra` 只是 auto-pause 包装。**结论：凡是包装系统 STT 的插件都继承同一批 OS 层怪癖，换插件不解决 ITN 毒化；真正的替代路线是换引擎（见 §2）。**

## 2. 离线 ASR 引擎对比表

| 引擎 | repo / stars | 维护 | license | Flutter 绑定 | 流式 | zh/ja/en | 标点/ITN | 体积/内存量级 | 对本 app 适用性 |
|---|---|---|---|---|---|---|---|---|---|
| **sherpa-onnx** | [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) **13,403★** | 极活跃（push 2026-07-04） | Apache-2.0 | **官方**：pub.dev [`sherpa_onnx`](https://pub.dev/packages/sherpa_onnx) **1.13.3（约 2026-06-15）**，五平台，官方 flutter-examples 含 streaming_asr | 流式 + 非流式 + VAD(silero) + **KWS**（有 zh-en 模型） | zh：流式 zipformer（bilingual zh-en；zh xlarge int8/fp16 2025-06-30）；en：多款；**ja：只有 offline** — ReazonSpeech zipformer（35k 小时，[HF](https://huggingface.co/reazon-research/reazonspeech-k2-v2)），官方文档用 VAD+offline 做 simulated streaming；另有 **SenseVoice zh/en/ja/ko/yue** 非流式 | 原生输出 spoken form（不做 ITN）——**优点：ITN 完全自控**；SenseVoice 例外，`use_itn` 可开关 | int8 流式双语约 100–200MB；SenseVoiceSmall int8 约 200–250MB；运行内存数百 MB（**量级估计未实测**） | **最佳引擎替换候选**。真离线（隐私升级为「音频不出 app」）、ITN 自控根治拼接毒化、连续识别自控。短板：**ja 真流式缺位**（段级交互可规避） |
| **vosk** | [alphacep/vosk-api](https://github.com/alphacep/vosk-api) **14,904★** | core 活跃；**官方 [vosk-flutter](https://github.com/alphacep/vosk-flutter) 75★ 最后 push 2024-10，事实停滞** | Apache-2.0 | 停滞 | 流式 | 三语 small 约 50MB/语种，内存约 300MB | 无 | 最轻 | 模型代际老（Kaldi TDNN），ja 准确率吃亏；**绑定停滞是硬伤，不建议** |
| **whisper.cpp** | [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp) **51,333★** | 极活跃 | MIT | 三方碎片化：[`whisper_ggml`](https://pub.dev/packages/whisper_ggml) 10 个月未更等 | **批处理，无真流式** | 三语强 | 接近书面形式，静音幻觉风险 | tiny 75MB / small 466MB；手机 CPU 勉强实时 | 不适合实时 partials；**可做「事后重转写」兜底** |
| **SenseVoice** | [FunAudioLLM/SenseVoice](https://github.com/FunAudioLLM/SenseVoice) **8,787★** | 活跃 | repo NOASSERTION，**模型权重 license 需核实** | 经 sherpa-onnx | 非流式（<80ms 段级，官方称比 Whisper-small 快 5 倍） | zh/en/ja/ko/yue **一模型全包** | 内置 ITN+标点可关 | int8 约 200–250MB | 一模型覆盖三语最有吸引力；配 VAD 段级正好匹配「说一句记一笔」；关 ITN 喂自研解析器可无缝复用状态机 |

**关键判断：** sherpa-onnx 是唯一同时满足「官方 Flutter 绑定 + 活跃维护 + 三语可拼装 + spoken form 输出」的引擎。现实拼装：zh/en 流式 zipformer（实时 partials），ja 走 VAD + SenseVoice/ReazonSpeech offline（段级约 1s 出全文）——ja 段级反而天然规避 partial-rewrite 毒化。

## 3. ITN / 数字解析库

| 库 | stars / license / 维护 | 语言 | 说明 |
|---|---|---|---|
| [NVIDIA/NeMo-text-processing](https://github.com/NVIDIA/NeMo-text-processing) | 481★，Apache-2.0，push 2026-07-02 | **ja/zh/en ITN 均有 WFST 语法**（ja 已确认） | Python + pynini。可导出 .far 经 Sparrowhawk (C++) 部署——FFI 进 Flutter 工程量大 |
| [wenet-e2e/WeTextProcessing](https://github.com/wenet-e2e/WeTextProcessing) | 791★，Apache-2.0，push 2026-06-26 | zh + en，production-first，有 C++ runtime | 无 ja。补 zh ITN 正规实现的最短路径参照物 |
| [Ailln/cn2an](https://github.com/Ailln/cn2an) | 764★，MIT，push 2026-04 | zh 数字↔阿拉伯（strict/normal/smart） | **当测试语料与算法参照最有价值**（smart 容错、两/俩/仨、廿/卅口语形） |
| [nagataaaas/Kanjize](https://github.com/nagataaaas/Kanjize) | 68★，MIT，2025-06 release | ja 漢数字↔int（到 10^72），含混合记法「3千5百」 | ja 侧测试集来源 |
| Dart 生态 | [`chinese_number`](https://pub.dev/packages/chinese_number)（仅整数）；[medz/numeral.dart](https://github.com/medz/numeral.dart)（ja 解析能力未验证） | — | **Dart 无可直接用的 ITN/FST 库，已确认** |

**防 ITN 拼接的工业模式：** ①ASR 端关 ITN 拿 spoken form 自己做（sherpa/vosk 天然如此；Meta 流式 on-device WFST ITN：[arXiv:2211.03721](https://arxiv.org/pdf/2211.03721)）；②n-best rescoring + 文法 accept 判定（app 的 L3/L4 已是雏形，可推广全槽位）；③ITN 属 display 层后处理（[Azure display text format](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/display-text-format)，佐证 resolve-on-final）。partial 全量重写参照：[arXiv:2312.09463](https://arxiv.org/pdf/2312.09463)。

## 4. 语音记账开源实现案例

| 项目 | 状态 | 结构 | 代际 |
|---|---|---|---|
| [dkp1903/expenso](https://github.com/dkp1903/expenso) 及同模板系 | 9★，2021 停更 | React + Speechly cloud NLU | 第一代 cloud NLU SaaS；**Speechly 被 Roblox 收购后关停，链路全失效** |
| [ParvJoshi20/Expensify](https://github.com/ParvJoshi20/Expensify) | 1★，MIT，2025-10 | Web Speech API + 本地 regex | 第二代纯规则（无多语、无状态机，远简于本 app） |
| [muety/telegram-expense-bot](https://github.com/muety/telegram-expense-bot) | 71★，已 archived | 命令式文本解析 | 参照物 |
| [n8n GPT-4o 模板](https://n8n.io/workflows/11368-track-expenses-automatically-with-telegram-bot-using-gpt-4o-ocr-and-voice-recognition/) 等大量 Telegram bot | 模板 | Whisper (cloud) → GPT-4o JSON | **第三代 STT + cloud LLM slot-filling，2024 起主流** |
| 商业闭源：[Vocash](https://www.vocash.app/voice-expense-tracker)、[ExpenseEasy](https://www.expenseeasy.app/voice-expense-tracking) | 闭源 | 云端 | 佐证「语音记账」是独立卖点 |

**结论（多组关键词交叉验证）：** 无成熟 Flutter 开源语音记账实现；**无任何设备端 LLM slot-filling 的开源记账项目**——第三代全部依赖云端。Home Pocket 走 on-device LLM 路线属差异化空间。

## 5. 设备端 LLM NLU 路线

任务定义：转录文本（≤50 字）→ `{金额,币种,日期,类目,商家,满意度}` JSON。1B 级模型可胜任，关键变量是 JSON 约束手段、延迟、体积、集成成熟度。

| 路线 | 证据 | 成熟度 | 体积/延迟 | 判断 |
|---|---|---|---|---|
| **MediaPipe LLM / LiteRT-LM** | [flutter_gemma](https://github.com/DenisovAV/flutter_gemma) 584★，**1.2.1 发布于 2026-07-05，MIT，22.6k 周下载**；function calling 支持 Gemma 4 E2B/E4B、Gemma 3n、**FunctionGemma 270M**、Qwen3 0.6B 等；[FunctionGemma 实证](https://medium.com/google-developer-experts/on-device-function-calling-with-functiongemma-39f7407e5d83) | 高（早期版本曾需 Flutter master，现状未验证） | Qwen3 0.6B/Gemma 3 1B int4 约 0.5–1GB；S25/S26 GPU ~52 tok/s；**中端 CPU 2–5 tok/s → 不可接受**；旗舰 1–3s 可用 | **Android 首选**。从 FunctionGemma 270M / Qwen3 0.6B 起评；必须 CPU-only 降级开关 |
| **Apple Foundation Models (iOS 26)** | 系统内置 ~3B；**guided generation（`@Generable`）解码层保证 schema**；A17 Pro/M1+ 且 Apple Intelligence 开启；[Apple newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)；WWDC26 开放任意 provider（[二手报道未核实](https://dev.to/arshtechpro/wwdc-2026-apple-just-opened-the-foundation-models-framework-to-any-llm-provider-5ejn)） | 中（[Flutter 桥](https://pub.dev/packages/foundation_models_framework) 0.1.x beta，structured generation 未完成 → 自写 MethodChannel） | 0 下载体积；1–2s 级（未实测） | **iOS 首选**。设备门槛与 iOS 14+ floor 差距大，只能做增强层 |
| **llama.cpp** | [netdur/llama_cpp_dart](https://github.com/netdur/llama_cpp_dart) 299★ MIT 活跃；[Telosnex/fllama](https://github.com/Telosnex/fllama) 208★（license 需核查） | 中（自管 GGUF；**GBNF grammar 硬约束 JSON**） | 同上量级 | 跨平台备选，运维成本高 |
| ML Kit GenAI / Gemini Nano | [官方](https://developers.google.com/ml-kit/genai)；Pixel 9/10、S25/S26 名单 | 低（无 Flutter 插件，alpha） | 0 体积 | 覆盖与 Android 7+ floor 不匹配，**观察** |
| MLC-LLM | [mlc-ai/mlc-llm](https://github.com/mlc-ai/mlc-llm) | 低（无 Flutter 绑定） | — | 跳过 |

**可行性判断：** 完全可行，两条 schema 硬保证路径（Apple guided generation / GBNF / function calling）。正确定位是**兜底层**：规则置信度低或槽位冲突才调，低端机永走规则路径；「满意度」软槽位是 LLM 强项。

## 6. 平台怪癖与新 API

**iOS SFSpeechRecognizer：** `kAFAssistantErrorDomain 1101` 指向 on-device 路径故障（[论坛 715516](https://developer.apple.com/forums/thread/715516)、[664037](https://developer.apple.com/forums/thread/664037)）；`203 Retry` 会话尾良性噪声（社区经验）。约 1 分钟会话上限、partial 全量重写是流式 ASR 固有行为——**金额只能 resolve-on-final，现行设计正确**。插件层拼接（§1）+ 系统层 ITN 重写 = 毒化完整因果链。

**iOS 26 SpeechAnalyzer/SpeechTranscriber：** 三模块（SpeechTranscriber 长语音 / DictationTranscriber 短句 / SpeechDetector VAD）；完全 on-device、为连续场景设计、volatile/finalized 两级结果、Argmax 测比 Whisper large-v3-turbo 快 ~2×（[Argmax](https://www.argmaxinc.com/blog/apple-and-argmax)）。落坑（[日文实测](https://www.docswell.com/s/SimpleMemo/K9NN8Y-2026-06-23-165552)、[callstack](https://www.callstack.com/blog/on-device-speech-transcription-with-apple-speechanalyzer)）：mic buffer 必须过 `AVAudioConverter`；语言模型系统共享资产**首启需联网下载**（AssetInventory，冲击 local-first 需 onboarding 处理）；**无 contextualStrings**（商家热词路径断）；Swift 6 concurrency 约束。**ITN 行为未见文档确认（不确定项）**。speech_to_text 未适配 → 自写 channel + 双栈。[WWDC25 session 277](https://developer.apple.com/videos/play/wwdc2025/277/)。

**Android：** API 33+ `createOnDeviceSpeechRecognizer()` 厂商差异大；[ML Kit GenAI STT](https://developers.google.com/ml-kit/genai/speech-recognition/android)（Gemini Nano/AICore）2026 仍 alpha 设备名单窄——观察。

## 7. 结论矩阵

| # | 方案 | 收益 | 成本 | 风险 | 优先级 |
|---|---|---|---|---|---|
| A | 维持 speech_to_text + 语料强化 + 全槽位文法 accept + 审读插件拼接 | 中（防线补漏防回归） | 低 | 低 | **P0 立即** |
| B | sherpa-onnx 并行试点（zh 流式 zipformer；ja VAD+SenseVoice 段级；KWS 顺带唤醒） | 高（根治 ITN 黑盒、连续自控、隐私升级） | 高（+200-400MB 分发、内存、三语拼装 A/B） | 中（ja 无真流式；离线准确率 vs 系统 STT 需实测，ja 主语言不能盲切） | **P1 spike** |
| C | 设备端 LLM slot-filling 兜底（Android flutter_gemma；iOS 26 Foundation Models） | 中-高（长尾鲁棒、软槽位、开源无先例差异化） | 中（0.5-1GB + 降级策略；Apple 侧近零体积） | 中（低端 CPU 不可用→门控+可关） | **P1-P2 先离线评测** |
| D | iOS 26 SpeechAnalyzer 适配层（<26 回落） | 中（连续模型契合、on-device、快） | 中（双栈；首启联网；丢热词） | 低-中（ITN 未知需真机验证；渗透率） | **P2 预研** |
| E | whisper.cpp 事后重转写兜底 | 低-中 | 中（录音缓存+加密义务） | 低 | P3 |
| F | ML Kit GenAI / Gemini Nano | 低（覆盖窄） | 低-中 | 低 | P3 观察 |
| G | vosk | — | — | 绑定停滞、模型老 | **不建议** |

**主要不确定项：** sherpa 各模型目标机型实测体积/内存/准确率；SpeechAnalyzer 数字格式化行为与三语清单；flutter_gemma 当前是否仍需 Flutter master；SenseVoice 权重 license；fllama license；203 定性（社区经验）；Speechly 关停细节（训练期知识）。

---

**创建时间:** 2026-07-06 20:05
**作者:** Claude (Fable 5)
