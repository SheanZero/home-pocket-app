# Phase 20: Voice Number Parser (zh + ja) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 20-voice-number-parser-zh-ja
**Areas discussed:** State machine 形态 & 与现有 parser 的关系, 假名 (hiragana) 数字支持, 续听窗口合并机制 (VOICE-02 核心)

---

## State machine 形态 & 与现有 parser 的关系

### Q1: 新的 numeral state machine 放在哪里？

| Option | Description | Selected |
|--------|-------------|----------|
| `lib/infrastructure/speech/` 下 | 与 SpeechRecognitionService 同目录 — 表明这个 state machine 紧贴识别器输出。speech/ 目前只包 plugin wrapper，加 NLP 类逻辑会混杂 | |
| `lib/infrastructure/voice/` 新目录 | 新建专用 voice/ 目录放「语音 → 结构化」类逻辑。未来 hiragana 词典、locale-specific tokenizer、state machine 都放这里。跨调用者 (zh/ja) 共享。与 application/voice/ 配饰 | ✓ |
| `lib/infrastructure/ml/` 下（复用）| 和 MerchantDatabase / TFLite 同位 — 把这看作「语言模型/字典」类东西。实际上 numeral parsing 不是 ML，那里主要存 ML 资产，语义不及格 | |

**User's choice:** `lib/infrastructure/voice/` 新目录
**Notes:** D-01 — 配饰 application/voice/，且为 Phase 21 dictionary 扩展铺路。

### Q2: zh + ja 合并为一个 state machine，还是拆成两个独立的？

| Option | Description | Selected |
|--------|-------------|----------|
| 单个 machine + locale 参数 | 一个 class，构造函数接受 Locale，内部分支（digit/unit/zero 表不同）。代码极少，但分支只越多越难调。双 locale corpus 可复用 driver | |
| 两个独立 machine 共享 abstract base | ChineseNumeralStateMachine + JapaneseNumeralStateMachine 都 extend NumeralStateMachine。测试独立，bug 隔离。两种语言的"零、10万、浊音「はっぴゃく」"规则实上差别不小，合并后分支会变肥 | ✓ |
| 一个 machine + plug-in rule set | Machine 裸，启动时注入 NumeralRuleSet(zh) / NumeralRuleSet(ja)。抽象费高，v1.3 只两种 locale、明顾过度设计 | |

**User's choice:** 两个独立 machine 共享 abstract base
**Notes:** D-02 — zh "零" placeholder 与 ja 浊音/促音规则结构不同，合并会成 fat switch。

### Q3: 现有 VoiceTextParser.extractAmount（512 行 application 层）怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 完全替换，斗住 kanji 路径 | 新 state machine 同时接管单段 + 多段。extractAmount 在 application 层变成转发器（调 infrastructure machine）。代码干净但需用老测试全部重迹 + 迁移 | ✓ |
| 并列：old parser 处理 arabic，new machine 处理 kanji/kana | Arabic numeral 路径已经稳且被测试覆盖—保留；extractKanjiAmount 改为调 new machine。Arabic / Kanji 二者完全在 extractAmount 里 fallback。较少重构、风险低 | |
| Wrap：新 machine 在外面多一层，内部还沉 old parser 单段调用 | State machine 只负责「跨段合并 + 选择 final string」，拼接出最终 string 后调 老 extractAmount。Old code 一行不动。动冲最小，但两层逻辑重叠、调试点多 | |

**User's choice:** 完全替换，斗住 kanji 路径
**Notes:** D-04 — `_extractArabicAmount` 保留，`_extractKanjiAmount` 删除；extractAmount 变 locale-routing transfer station。

### Q4: Public API 形状？(state machine 如何被外部调用)

| Option | Description | Selected |
|--------|-------------|----------|
| Stateful 对象：feed(chunk) + reset() + currentValue | 保有 buffer，每次调 feed() 增量合并，需 reset() 手动清。适合跨 partial result 流式投递。与「续听窗口」设计配饰最高 | |
| Functional：parse(text) -> int? (无状态) | 每次调用传完整 text（上游按 partial result 拼接）。纯函数，极易测试。但 buffer / 超时 / flush 逻辑被推到调用者身上，application 层代码高 | ✓ |
| 两个都暴露 | Functional 入口给现有单段完整路径（向后兼容）；stateful 对象给新的 partial-stream 路径。API 双接口，表面决定多、反而难演进 | |

**User's choice:** Functional：parse(text) -> int? (无状态)
**Notes:** D-03 — buffer/timer state 全部推到 application 层的 VoiceChunkMerger（见后面 area）。State machine 保持极简、纯函数、可单元测。

---

## 假名 (hiragana) 数字支持

### Q1: 假名数字覆盖范围为？

| Option | Description | Selected |
|--------|-------------|----------|
| 基本集字典：digit × unit × 主要读音 | 1-9 主要读音 + units (じゅう/ひゃく/せん/まん)。不覆盖 はっぴゃく、ろっぴゃく 等浊音变体 | |
| + 浊音/促音变体 (rendaku/sokuon) | 300=さんびゃく, 600=ろっぴゃく, 800=はっぴゃく, 8000=はっせん, 10000=いっまん — VOICE-01 中「せんはっぴゃくよんじゅう」→ 1840 都遭遇这个 | |
| 全覆盖 + 多读音 (4=し/よん, 7=しち/なな, 9=く/きゅう) | 同一数字在不同位设读音不同 (几点「しち」vs 七「なな」。金额上多是 なな)。覆盖 full 是"什么说法都能识别"，但字典量翻倍、测试 corpus 也要扫着加 | ✓ |

**User's choice:** 全覆盖 + 多读音
**Notes:** D-05 — Dictionary 约 70-90 条目（10 digits × 2-3 读音 + 5 units × 2-3 浊/促音变体 + 复合连读如 いっせん/はっせん/さんびゃく/ろっぴゃく/はっぴゃく/いちまん）。Corpus 设计时对应扫覆盖。

### Q2: 假名词典放哪里？

| Option | Description | Selected |
|--------|-------------|----------|
| 嵌入 JapaneseNumeralStateMachine.dart | 与 kanji table 同位在 machine 里 Map const。实现最简、一个文件 self-contained。不利于：后期增加变体需改 code | |
| 抽出为 JapaneseNumeralDictionary 独立文件 | Const Map 独立为 lib/infrastructure/voice/japanese_numeral_dictionary.dart。Machine 心 import；测试中可 stub 字典。反映「词典与词法分离」，也为 Phase 21 词典扩充预热 | ✓ |
| 放 ARB / YAML 资源文件 | 数字/单位词典走文件 (例如 assets/voice/japanese_numerals.yaml)。运行时 load。不推荐 — 这是语言学硬编码，不是本地化内容；load 额外额外规过重 | |

**User's choice:** 抽出为 JapaneseNumeralDictionary 独立文件
**Notes:** D-06 — 词典 / 词法分离；为 Phase 21 词典扩展铺路。

### Q3: 混合输入 (kanji + kana + arabic) 怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 接受任意混合，normalize 到内部 canonical 表示后解析 | Recognizer 返回 "2千2百よん" 也能解 → normalize 为 [2,千,2,百,4] 后进 state machine。鲁棒但 normalize step 调试点多 | ✓ |
| 分路径：arabic / kanji / kana 三者一、不接受混合 | extractAmount 先试 arabic 路径 → 不成功试 kanji-only → 不成功试 kana-only → 都不成功返 null。逻辑清楚但 recognizer 频频混出"2千よん"这样的混合会被 Fail | |
| Kanji + kana 同表，arabic 独立路径 | JapaneseNumeralStateMachine 同时识别二/に/2 、千/せん — normalize 在 machine 内部做。Arabic-only (如「1280円」) 走 old arabic regex。平衡鲁棒与复杂度 | |

**User's choice:** 接受任意混合，normalize 到内部 canonical 表示后解析
**Notes:** D-07 — normalize(text) -> List<NumeralToken> 单独 step；scanner 消费 token list 而非原始字符串。

### Q4: 假名支持与 zh 机器是否对称？zh recognizer 返回拼音吗？

| Option | Description | Selected |
|--------|-------------|----------|
| zh 不同体，只 kanji 路径即可 | 实际中文语音识别引擎不会返回 pinyin；返「2千2百4」 。zh machine 只需 kanji 表 + 「两」/「贰」变体 | ✓ |
| zh 也加拼音 fallback | 防御性在 zh machine 里加一个拼音表 (er, qian, bai, shi)。原则上不会被触发，但万一发生 recognizer fallback 到 pinyin 输出可以补救。额外复杂度 | |
| zh + ja 都只接 native script，不做任何路音/拼音 fallback | 设定边界明确：recognizer 质量不够是 recognizer 问题，not parser。Parser 全责任范围仅限 kanji+kana(ja) / kanji(zh) | |

**User's choice:** zh 不同体，只 kanji 路径即可
**Notes:** D-08 — 与实际发行一致；拼音 fallback 推迟到「recognizer 真的返回 pinyin」实际发生时再说。

---

## 续听窗口合并机制 (VOICE-02 核心)

### Q1: 跨 final result 的 buffer / merger 放哪一层？

| Option | Description | Selected |
|--------|-------------|----------|
| 新建 lib/application/voice/voice_chunk_merger.dart (专职类) | 专职类，持 buffer 并管理 window 超时 + lexical 合并规则。调用 NumeralStateMachine.parse(combinedText)。单一职责、独立可测、与 parser 职责合作清晰 | ✓ |
| 加到现有 ParseVoiceInputUseCase 里个 state 字段 | ParseVoiceInputUseCase 类加 _buffer / _lastChunkAt。代码少，但 use case 原本是 stateless 函数，需重构成 stateful。与现在的 execute(text) -> Result 套路冲突 | |
| 放 voice_input_screen.dart (presentation 层) | 屏幕 widget 里累计 final string，每次拼接后传给 use case。迁移最少、不推荐 — application/infra 逻辑泄到 presentation，违反分层 | |

**User's choice:** 新建 lib/application/voice/voice_chunk_merger.dart (专职类)
**Notes:** D-09 — 单一职责类；持 buffer + window timer + 合并谓词 + restartListen 编排。

### Q2: 「新 chunk 该合并」的触发条件是？

| Option | Description | Selected |
|--------|-------------|----------|
| 纯时间窗：N 秒内收到新 chunk 就拼 | 上个 final 之后 N 秒内有新 final → 拼。逻辑最简，但「1千8百」停顿「现金」会被错合拼成「1千8百现金」。需 normalize 后 parser 丢掉非数字 token | |
| 词法连续性：buffer 末尾是「未闭合」数字 | Buffer 末尾是单位 (千/百/十/万) 或裸 digit，且新 chunk 启头也是 numeric token → 合并。处理精准但需判断 token 类型 | |
| 时间窗 AND 词法连续性 (双门) | 两重条件同时成立才合并—"快且语义续"。避免「停顿后说了另一件事」被错拼。避免错拼的代价是少量「本该合」被错分 | ✓ |

**User's choice:** 时间窗 AND 词法连续性 (双门)
**Notes:** D-10 — 双 gate 严格；避免「1千8百」+「现金」假合，代价是少量边缘 case 可能被错分（可在 corpus 中验证）。

### Q3: 续听窗口长度 (从 final 触发到【方合并】的最大空隔)？

| Option | Description | Selected |
|--------|-------------|----------|
| 1.5 秒 | 较短。深度思考不够用，但 false-merge 风险低。Phase 19 keypad polish 有类似「快输入」场景鲁棒性偏好 | |
| 2.5 秒 | 中间值。能容「呀等一下让我想想」、不至于拿不准 amount 干脆剩下 | ✓ |
| 5 秒 | 偏长。连续多级停顿都能合，但用户说「1千8百」后决定不补了 → 还要等 5s 才 commit。体验重 | |
| 用户交互控制 (点击中止) | 窗口理论上很长 (10s+)，靠用户点「停」按钮才 commit。这个交互模型与 REC-01 (tap-to-toggle vs hold) 耦合太深；Phase 20 独立决定不住 | |

**User's choice:** 2.5 秒
**Notes:** D-11 — 经验值；可在 corpus 测试后微调，不需改架构。

### Q4: Final 触发后怎么「保持听」？

| Option | Description | Selected |
|--------|-------------|----------|
| Final 后自动 restartListen()，pauseFor 不动 (3s) | merger 听到 final 事件 → 启动 window timer 同时调 SpeechRecognitionService.startListening 重启。在 window 期间及时收 下个 final。逻辑清晰、本层完成 | ✓ |
| 拍 pauseFor 加长到 6、8 秒 | 不重启、recognizer 自己多听 一会儿。代码一行改，但：用户说完后要等 6-8s 才出结果，付不起 | |
| 双重：pauseFor 适度拉到 5s + window 里自动重启 | pauseFor 拉长 减少重启次数，另加 window-driven restart 兼顾超常停顿。逻辑双路径，但鲁棒最强 | |

**User's choice:** Final 后自动 restartListen()，pauseFor 不动 (3s)
**Notes:** D-12 — 单层职责；recognizer 配置不变，merger 是唯一新增控制点。

---

## Claude's Discretion

- 具体 class/file 名（state machine 文件名、merger 字段命名等）— planner 在 PLAN.md 中确定。
- `restartListen()` 是 `SpeechRecognitionService` 上新方法 vs merger 再调 `startListening()` — 实现选择，两者都可。
- `Locale` plumbing 路径（参数还是构造函数注入）— planner 选择。
- **测试 corpus 形状**（offered 但 deferred）— Dart-literal fixtures, ~50 cases/locale, anchor cases 严格, statistical bucket ≥95% 为推荐 default；researcher/planner 可有理由覆盖。

## Deferred Ideas

- **億-scale amounts** (一億二千万) — 不在 v1.3 milestone 范围；abstract base 的 `Unit(power)` token 支持未来扩展，无架构改动。
- **English voice number parsing** — REQUIREMENTS.md 明确推后到 v1.4+。
- **Voice category resolver level-2 enforcement** (VOICE-04/05/06) — Phase 21。
- **Voice 填 shared details form 集成** (INPUT-02) — Phase 22。
- **Record button UX** (REC-01, REC-02) — Phase 22。
- **Pinyin / romaji 防御 fallback** — 明确边界 D-08；如发生为 recognizer-quality bug，不在 parser 责任范围。
