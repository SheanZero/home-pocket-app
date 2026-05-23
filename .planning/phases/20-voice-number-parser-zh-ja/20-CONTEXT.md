# Phase 20: Voice Number Parser (zh + ja) - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 20 rebuilds Home Pocket's voice number recognition pipeline so compound 千/百/十/零/万 amounts (zh) and 千/百/十/万 amounts incl. 万-scale (ja) parse without digit-dropping (VOICE-01), survive intra-utterance pauses via a continued-listening + lexical-continuity merger (VOICE-02), and reach ≥95% accuracy on per-locale committed corpora reported separately (VOICE-03). The numeral-combining state machine is implementation-grade NLP and lives in `lib/infrastructure/voice/` per "Thin Feature" rule; the cross-final-result chunk buffer lives in a new `lib/application/voice/voice_chunk_merger.dart`. No UI changes (Phase 22 owns INPUT-02 voice-fills-form integration and REC-01/02 button UX). No new Drift schema.

**In scope:**
- New `lib/infrastructure/voice/` directory housing: `numeral_state_machine.dart` (abstract base), `chinese_numeral_state_machine.dart`, `japanese_numeral_state_machine.dart`, `japanese_numeral_dictionary.dart`. All four with functional `int? parse(String text)` API — fully stateless. No buffer, no listeners.
- New `lib/application/voice/voice_chunk_merger.dart` (stateful) — single-purpose class owning the cross-final-result buffer, the 2.5s window timer, and the double-gate merge predicate (time-window AND lexical continuity).
- Modification of `lib/infrastructure/speech/speech_recognition_service.dart` to expose a `restartListen()` call (or restart-from-merger equivalent) so the merger can auto-restart `listen()` after each `finalResult` while the window is open. `pauseFor` left at the existing 3 seconds.
- `VoiceTextParser._extractKanjiAmount` (lib/application/voice/voice_text_parser.dart:59-140) **deleted**; `extractAmount` becomes a thin transfer-station that routes to the infrastructure state machine based on locale.
- Voice corpus test fixtures committed: one for zh, one for ja, each with full case-level reporting (per-case pass/fail visible, anchor cases asserted hard, statistical accuracy ≥95% per-locale).
- Wire `voice_input_screen.dart` final/partial result handler into the new merger (replaces the current per-partial `parseVoiceInputUseCase.execute(text)` call pattern for amount specifically — merchant/category/date paths unchanged).

**Out of scope:**
- English (en) voice number parsing — explicitly deferred per REQUIREMENTS.md.
- Voice category resolver level-2 enforcement — Phase 21 owns VOICE-04/05/06.
- INPUT-02 voice-fills-shared-form integration — Phase 22 owns it (Phase 20 emits a corrected amount; Phase 22 wires it into the shared details form).
- REC-01/02 record button UX changes — Phase 22.
- Drift schema migration.
- Pinyin / romaji fallback paths (zh and ja recognizers return native script reliably; explicit boundary).
- 億-scale amounts (per current parser; not requested in v1.3 milestone scope).
- Voice satisfaction estimator changes — `voice_satisfaction_estimator.dart` untouched.

</domain>

<decisions>
## Implementation Decisions

### State machine shape & placement

- **D-01:** New state machine lives at `lib/infrastructure/voice/numeral_state_machine.dart` (abstract base) + `chinese_numeral_state_machine.dart` + `japanese_numeral_state_machine.dart`. Why a new `voice/` directory under infrastructure instead of `speech/`: `speech/` is reserved for plugin-wrapper code (SpeechRecognitionService); NLP / numeral-parsing logic deserves its own home and will also house `japanese_numeral_dictionary.dart`. Also positions Phase 21's resolver-data extensibility without code change (VOICE-06) to live nearby if it ends up at infrastructure.
- **D-02:** zh and ja get two independent concrete state machines sharing the abstract base. Reason: zh "零" placeholder semantics + ja voicing (rendaku/sokuon `はっぴゃく`/`ろっぴゃく`/`さんびゃく`) are structurally different rules; merging into one machine with locale branches would just create a fat switch statement. Two classes = isolated bug surface + locale-specific corpora drive each class independently.
- **D-03:** Public API is **functional, stateless**: `int? parse(String text)`. Buffer/timer/window state lives outside the machine (see D-09). Implication: state machine takes already-merged final text; "tokenize + scan + accumulate" is a single function call, fully deterministic, trivially testable.
- **D-04:** `lib/application/voice/voice_text_parser.dart` — `_extractKanjiAmount` (lines 59-140) is **fully deleted**. `extractAmount` retains its arabic-numeral path (the existing `_extractArabicAmount` regexes are stable and tested) but for kanji/kana now delegates to the infrastructure state machine. Locale routing: the caller passes `Locale` (or language code) so `extractAmount` knows which machine to invoke. Application layer becomes a thin transfer station; no parsing logic remains there.

### Hiragana / kana support breadth

- **D-05:** Japanese numeral dictionary covers **full multi-reading** for every digit:
  - 1: いち, ひと
  - 2: に, ふた
  - 3: さん
  - 4: よん, し
  - 5: ご
  - 6: ろく
  - 7: なな, しち
  - 8: はち
  - 9: きゅう, く
  - 0: ゼロ, れい, まる
  Plus unit base forms: せん, ひゃく, じゅう, まん.
  Plus all voicing/sokuon assimilation variants: いっせん (1000), さんぜん (3000 rendaku), はっせん (8000 sokuon), さんびゃく (300 voicing), ろっぴゃく (600 sokuon), はっぴゃく (800 sokuon), いちまん (10000). Implementation should treat these as direct entries in the dictionary (not rule-derived), to avoid rule-engine complexity.
- **D-06:** Dictionary lives in its own file `lib/infrastructure/voice/japanese_numeral_dictionary.dart` — `const` `Map<String, NumeralToken>` shape. Reason: separates lexicon from grammar (state machine reads dictionary). Also pre-positions Phase 21 if it ever wants to publish/extend dictionaries by data file (VOICE-06's "extensible by adding entries without code changes" constraint).
- **D-07:** Mixed-input policy: state machine accepts **any combination** of kanji + hiragana + arabic digits. Implementation pattern: a `normalize(text) -> List<NumeralToken>` step converts every recognized form to a canonical `NumeralToken` stream (`Digit(int)` / `Unit(power)` / `ZeroPlaceholder` / `Skip`), then the scanner consumes the token list. Example: "2千2百よん" → `[Digit(2), Unit(1000), Digit(2), Unit(100), Digit(4)]` → 2204. Recognizer's actual mixed outputs (e.g., "2千4百" with partial kana) become a non-event because normalize handles them uniformly.
- **D-08:** zh state machine is **kanji-only — no pinyin fallback**. Chinese speech recognizers (iOS/Android both) return native script reliably; defensive pinyin tables would add maintenance burden for zero observed payoff. Explicit boundary: if recognizer ever returns pinyin (very unlikely), it's a recognizer-quality bug, not a parser-coverage gap.

### Continued-listening window (VOICE-02 core)

- **D-09:** Cross-final-result buffer lives in new dedicated class `lib/application/voice/voice_chunk_merger.dart`. Single responsibility: own the buffer string, the 2.5s window timer, the merge-predicate, and the restartListen() orchestration. **Not** in `ParseVoiceInputUseCase` (which is currently stateless `execute(text)` and should stay stateless — adding `_buffer` field would violate use-case contract). **Not** in `voice_input_screen.dart` (would leak NLP/merging logic to presentation layer).
- **D-10:** Merge trigger is a **double gate** (BOTH conditions must hold):
  - **Time gate:** new final arrives ≤ 2.5 seconds after previous final (window measured from previous final's emission timestamp; resets to 2.5s on every successful merge).
  - **Lexical gate:** buffer's last token is a "not-yet-closed" numeric token (a unit like 千/百/十 with no following digit, OR a bare digit with no preceding unit at the very end) AND the new chunk's leading token (after `normalize()`) is itself numeric. Reason: avoids "1千8百" + "现金" (cash) being false-merged into "1千8百现金"; the lexical gate rejects "现金" as non-numeric leader. Conversely "1千8百" + "4十" passes both gates → merge → "1千8百4十" → 1840.
- **D-11:** Window length: **2.5 seconds**. Captured value — not 1.5s (too aggressive on hesitating users) and not 5s (sluggish commit). 2.5s comfortably swallows "umm let me think" without delaying the commit of "I'm done" cases. Window length is a const in voice_chunk_merger; if corpus testing surfaces miscalibration, retune in a follow-up patch — no architectural change.
- **D-12:** Listen restart strategy: after every `finalResult` while the window is open, the merger calls `SpeechRecognitionService.restartListen()` to reopen the recognizer (`pauseFor` stays at the existing 3 seconds, unchanged from current code). When the 2.5s window timer fires without a new chunk arriving, the merger commits the buffered text by calling the infrastructure state machine `parse(buffer)`, clears buffer, and stops auto-restarting. User-initiated stop (tap-to-toggle off) always commits immediately and clears.

### Test corpus shape (Claude's discretion — researcher/planner finalize)

Corpus shape was offered as a fourth gray area but deferred — downstream agents have enough constraints to land it. Recommended defaults for researcher/planner to validate:
- One Dart-literal fixture file per locale (`test/fixtures/voice_corpus_zh.dart`, `test/fixtures/voice_corpus_ja.dart`); easier than CSV/YAML for IDE navigation + refactor.
- Size: ~50 cases per locale (covers digit ranges, intra-pause variants, currency-suffix variants, multi-reading ja variants, zh 零-placeholder cases).
- Anchor cases (zh 2204, zh 1840, ja 2204, ja 1840, ja 12000) are **strict** — each its own `test()` block, must pass 100%.
- Statistical bucket: remaining cases driven through one `group()` with per-case `expect` calls; aggregate accuracy printed as a summary at end of suite. ≥95% per-locale = pass.
- Per-case failure output: `expect` message includes the input text + expected + actual so failures are inspectable without re-running with print.

### Claude's discretion

- Specific class/file names beyond the four state-machine files + dictionary + merger named above — planner pick concrete identifiers that match existing naming.
- Whether `restartListen()` is a new method on `SpeechRecognitionService` or a re-call of `startListening()` from the merger — implementation choice, both work.
- Exact `Locale` plumbing path through `extractAmount(text, locale)` — call site (`ParseVoiceInputUseCase.execute`) already knows locale via the voice screen's locale-id provider; planner pick whether to pass locale as parameter or via constructor injection.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 20 — phase goal + 5 Success Criteria (committed corpora, anchor cases, infrastructure placement, no schema change)
- `.planning/REQUIREMENTS.md` — VOICE-01 (compound-number anchor cases), VOICE-02 (intra-pause anchor cases + continued-listening window), VOICE-03 (per-locale ≥95% corpora)
- `.planning/PROJECT.md` — milestone-level constraint that zh + ja only; English voice deferred to v1.4+; OCR / FAMILY-V2 / fl_chart out of scope

### Project state and adjacent phases
- `.planning/STATE.md` — Phase 19 completed 2026-05-23; Phase 20 parallel-safe with Phase 19, feeds into Phase 21 (resolver) and Phase 22 (integration)
- `.planning/phases/18-shared-details-form-foundation/18-CONTEXT.md` — shared details form widget (Phase 22 will wire voice into this)
- `.planning/phases/19-manual-one-step-keypad-polish/19-CONTEXT.md` — voice screen now pushes `ManualOneStepScreen` (line 351-368 of voice_input_screen.dart); Phase 20 emits the corrected amount that flows into `initialAmount`

### Architecture
- `docs/arch/02-module-specs/MOD-009_VoiceInput.md` — canonical voice-input module spec (FR-002 amount extraction, existing kanji parser behavior, locale matrix)
- `CLAUDE.md` — Thin Feature rule (infrastructure/voice/ placement of state machine + dictionary), Riverpod 3 provider conventions, intl pin, sqlcipher pin, immutability (`copyWith` on Freezed)

### Code touchpoints (Phase 20 will modify)
- `lib/application/voice/voice_text_parser.dart` — `_extractKanjiAmount` deleted (lines 59-140); `extractAmount` becomes locale-routing transfer station
- `lib/application/voice/parse_voice_input_use_case.dart` — wires merger between recognizer callbacks and `extractAmount`
- `lib/infrastructure/speech/speech_recognition_service.dart` — exposes `restartListen()` (or merger calls `startListening()` again, planner discretion D-12)
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` (lines 175-241) — `_onResult` callback handler updated to feed `VoiceChunkMerger` instead of debounced direct `parseVoiceInputUseCase.execute()`; merchant/category/date paths unchanged

### Existing test reference
- `test/unit/application/voice/voice_text_parser_test.dart` (lines 47-59) — current kanji-amount tests; Phase 20 will retire these in favor of the new state-machine + corpus tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_extractArabicAmount` (`lib/application/voice/voice_text_parser.dart:29-54`) — stable, well-tested regex path for "¥1280" / "1,280円" / standalone-3+digit. Stays as-is; only the kanji path is rebuilt.
- `SpeechRecognitionService.startListening` (`lib/infrastructure/speech/speech_recognition_service.dart:33-57`) — current `partialResults: true` + `pauseFor: 3s` + `cancelOnError: false` config is the right baseline; merger calls this in restart mode.
- `voice_locale_helpers.dart` (`lib/features/settings/presentation/utils/voice_locale_helpers.dart:3-15`) — already maps language code → recognizer locale ID (`zh-CN`, `ja-JP`); merger and state-machine routing use the same code-path.

### Established patterns
- "Thin Feature" rule (per CLAUDE.md): state machine + dictionary go in `lib/infrastructure/voice/`, NEVER inside `lib/features/`. Application use case (`parse_voice_input_use_case.dart`) is the orchestrator; merger sits alongside it as another application-layer concern.
- Stateful classes in `lib/application/` are precedented: `TransactionChangeTracker`, `SyncEngine`, `SyncOrchestrator` all keep state and are tested with mock dependencies. `VoiceChunkMerger` follows the same shape (Riverpod-provided singleton with disposal hooks if needed for window-timer cleanup).
- Functional/stateless parsers in `lib/infrastructure/` are precedented: `MerchantDatabase.findMerchant`, `RuleEngine.classify` etc. Numeral state machine follows the same shape.

### Integration points
- `_onResult` callback in `voice_input_screen.dart:210-241` is the single integration point. Current pattern: every partial calls `parseVoiceInputUseCase.execute(result.recognizedWords)`. New pattern: amount path goes through merger (`merger.feedChunk(text, isFinal: result.finalResult)`); merger commits to `extractAmount` when window closes; merchant/category/date paths continue to flow through `parseVoiceInputUseCase.execute()` unchanged (they don't need cross-final merging — recognizer returns merchant/category text whole in a single final).
- `voice_input_screen.dart:351-367` voice → ManualOneStepScreen push site: receives `initialAmount: result.amount ?? 0`. The amount that lands in `result.amount` MUST be the merger's commit value (post-merge), not a per-partial intermediate. Implementation: merger emits a `VoiceAmountResolved` event or sets a field on `VoiceParseResult` that's read at navigate time.
- Sound-level + partialResultCount instrumentation (`_buildAudioFeatures`, voice_input_screen.dart:305-315) consumed by `VoiceSatisfactionEstimator` — unaffected. Estimator path runs only on the soul-ledger branch, independent of amount path.

</code_context>

<specifics>
## Specific Ideas

Anchor cases that downstream agents MUST encode verbatim as named `test()` blocks (not just rolled into the statistical corpus):

- **zh "2千2百零4元" → 2204** (零-placeholder; no intra-pause; final-result single-pass)
- **zh "1千8百" + pause + "4十元" → 1840** (intra-pause two-final merge; double-gate must pass; result NOT 1800 + 40)
- **ja「にせんにひゃくよん（円）」→ 2204** (pure hiragana; no intra-pause; tests hiragana dictionary + normalize)
- **ja「せんはっぴゃく」+ pause +「よんじゅう（円）」→ 1840** (intra-pause two-final merge; tests merger + sokuon `はっぴゃく` + voicing)
- **ja「一万二千」→ 12000** (万-scale single-pass; existing parser already handles this — regression-guard)

VOICE-02 anchor implementation needs a test seam that simulates two final-result emissions with a measured gap between them (mock `SpeechRecognitionResult` timing); planner specifies fixture format.

VOICE-03 corpus accuracy is reported per-locale, not aggregate. Test suite output must show "zh: 49/50 (98%)" and "ja: 48/50 (96%)" separately; if either drops below 95%, the suite fails.

</specifics>

<deferred>
## Deferred Ideas

- **Test corpus exact case list & fixture format** — offered as 4th gray area, deferred to researcher/planner. Defaults captured in D-12 above (Dart-literal fixtures, ~50 cases per locale, anchor cases strict, statistical bucket ≥95%) are recommendations downstream agents can override with cause.
- **億-scale amounts** (e.g., 一億二千万 = 120,000,000) — not in v1.3 milestone scope; recognizer practically never returns these for everyday spending. If a future user needs them, extend the abstract base's `Unit(power)` token to accept 10^8 — code shape supports it.
- **English voice number parsing** — explicitly deferred to v1.4+ per REQUIREMENTS.md milestone-level "Out of scope".
- **Voice category resolver level-2 enforcement** (VOICE-04/05/06) — Phase 21.
- **Voice fills shared details form integration** (INPUT-02) — Phase 22.
- **Record button UX** (REC-01, REC-02) — Phase 22.
- **Pinyin / romaji defensive fallbacks** — explicit boundary D-08; if needed in the future, it's a recognizer-quality bug to file against speech_to_text, not parser coverage.

</deferred>

---

*Phase: 20-voice-number-parser-zh-ja*
*Context gathered: 2026-05-23*
