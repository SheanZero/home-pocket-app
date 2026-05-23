# Phase 20: Voice Number Parser (zh + ja) - Research

**Researched:** 2026-05-23
**Domain:** Numeral state machines (Chinese 千/百/十/零/万 + Japanese 千/百/十/万 incl. 万-scale) + cross-final-result chunk merger over `speech_to_text` plugin
**Confidence:** HIGH (algorithms verified against existing code + canonical patterns; CONTEXT.md locks every architectural decision; speech_to_text 7.x runtime behavior cross-verified)

## Summary

This phase rebuilds the voice number parsing pipeline in two clean planes:

1. **Stateless numeral state machines** (`lib/infrastructure/voice/`) — two concrete parsers (zh, ja) sharing an abstract base, public API `int? parse(String text)`. Internally each runs `normalize(text) → List<NumeralToken>` then a left-to-right scanner with a `currentDigit` + `currentSection` accumulator and a `total` register that flushes on `Unit(10000)`. Algorithm shape is the well-established section-accumulator pattern already in use by the legacy `_extractKanjiAmount` (`voice_text_parser.dart:104-137`) — the rebuild only fixes the broken final-tail handling and adds `零`-placeholder semantics + Japanese voicing-variant dictionary.

2. **Stateful chunk merger** (`lib/application/voice/voice_chunk_merger.dart`) — single class owning a buffer, a 2.5 s window `Timer`, and the double-gate predicate (time + lexical continuity). After every `finalResult` it asks `SpeechRecognitionService.restartListen()` to reopen recognition; on timer expiry it commits buffer → calls the infrastructure state machine → clears.

The risk of the phase concentrates in **three** places: (a) the Japanese dictionary's longest-match tokenization (multi-char entries like `はっぴゃく` must beat single-char `は` + `っ` + …), (b) the lexical "not-yet-closed numeric" predicate which must distinguish `1千8百` (expecting digit after 百) from `4十` (Digit-then-Unit, complete), and (c) restart-listen timing — `speech_to_text` emits `finalResult: true` *after* `pauseFor` expires or `stop()` is called, so the merger must re-invoke `startListening` (which creates a new recognition session) and accept that this is the supported pattern.

**Primary recommendation:** (1) Use the trie-backed longest-match tokenizer for Japanese (sort dictionary keys by descending length, scan greedily); (2) implement the merger as a non-Riverpod plain class with explicit `dispose()` mirroring `SyncEngine`, then wire via `@riverpod` provider with `ref.onDispose(merger.dispose)` mirroring `appWebSocketServiceProvider`; (3) add `restartListen()` as a new method on `SpeechRecognitionService` that calls `_speech.listen(...)` with the cached config — cleaner test seam than re-routing through `startListening`; (4) test the merger window logic with `fake_async` (precedent: `phase6_sync_coverage_test.dart`, `websocket_service_test.dart`); (5) thread `Locale` through `extractAmount(text, locale)` as a parameter — caller (`ParseVoiceInputUseCase.execute`) is stateless and locale is per-request from `voiceLocaleIdProvider`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**State machine shape & placement**

- **D-01:** New state machine lives at `lib/infrastructure/voice/numeral_state_machine.dart` (abstract base) + `chinese_numeral_state_machine.dart` + `japanese_numeral_state_machine.dart`. New `voice/` directory under infrastructure (not `speech/`) because `speech/` is reserved for plugin-wrapper code; NLP/numeral logic deserves its own home and pre-positions Phase 21's resolver extensibility.
- **D-02:** zh and ja get two independent concrete state machines sharing the abstract base — zh `零` placeholder vs ja voicing (rendaku/sokuon) are structurally different; merging would create a fat switch statement.
- **D-03:** Public API is **functional, stateless**: `int? parse(String text)`. Buffer/timer/window state lives outside the machine (see D-09). State machine is fully deterministic, trivially testable.
- **D-04:** `lib/application/voice/voice_text_parser.dart` — `_extractKanjiAmount` (lines 59-140) is **fully deleted**. `extractAmount` retains arabic-numeral path (`_extractArabicAmount` stays unchanged) but delegates kanji/kana to the infrastructure state machine. Locale routing: caller passes `Locale` (or language code) so `extractAmount` knows which machine to invoke.

**Hiragana / kana support breadth**

- **D-05:** Japanese numeral dictionary covers **full multi-reading** for every digit (1: いち/ひと, 2: に/ふた, 3: さん, 4: よん/し, 5: ご, 6: ろく, 7: なな/しち, 8: はち, 9: きゅう/く, 0: ゼロ/れい/まる) plus unit base forms (せん, ひゃく, じゅう, まん) PLUS all voicing/sokuon variants as direct entries: いっせん (1000), さんぜん (3000 rendaku), はっせん (8000 sokuon), さんびゃく (300 voicing), ろっぴゃく (600 sokuon), はっぴゃく (800 sokuon), いちまん (10000). Direct entries — no rule engine.
- **D-06:** Dictionary lives in its own file `lib/infrastructure/voice/japanese_numeral_dictionary.dart` — `const Map<String, NumeralToken>`. Separates lexicon from grammar.
- **D-07:** Mixed-input policy: state machine accepts **any combination** of kanji + hiragana + arabic. `normalize(text) -> List<NumeralToken>` converts every recognized form to canonical token stream (`Digit(int)` / `Unit(power)` / `ZeroPlaceholder` / `Skip`). Scanner consumes uniformly.
- **D-08:** zh state machine is **kanji-only — no pinyin fallback**. Chinese recognizers return native script reliably.

**Continued-listening window (VOICE-02 core)**

- **D-09:** Cross-final-result buffer lives in new dedicated class `lib/application/voice/voice_chunk_merger.dart`. Single responsibility: buffer + 2.5s timer + merge predicate + restartListen() orchestration. **Not** in `ParseVoiceInputUseCase` (must stay stateless). **Not** in `voice_input_screen.dart` (NLP logic stays out of presentation).
- **D-10:** Merge trigger is **double gate** (BOTH conditions):
  - **Time gate:** new final arrives ≤ 2.5s after previous final (window measured from previous final's emission timestamp; resets to 2.5s on every successful merge).
  - **Lexical gate:** buffer's last token is "not-yet-closed" numeric (unit like 千/百/十 with no following digit, OR bare digit at end with no preceding unit) AND new chunk's leading token (after `normalize()`) is itself numeric.
- **D-11:** Window length: **2.5 seconds**. Const in voice_chunk_merger; retune in follow-up patch if corpus surfaces miscalibration — no architectural change.
- **D-12:** Listen restart strategy: after every `finalResult` while window open, merger calls `SpeechRecognitionService.restartListen()` (or re-calls `startListening()`, planner discretion). `pauseFor` stays at existing 3 seconds. 2.5s window timer fires without new chunk → merger commits buffered text via `parse(buffer)`, clears buffer, stops auto-restarting. User-initiated stop always commits immediately.

### Claude's Discretion

- Specific class/file names beyond the four state-machine files + dictionary + merger named above — planner picks.
- Whether `restartListen()` is a new method on `SpeechRecognitionService` vs re-call of `startListening()` from merger — both work.
- Exact `Locale` plumbing path through `extractAmount(text, locale)` — parameter vs constructor injection.

### Deferred Ideas (OUT OF SCOPE)

- **Test corpus exact case list & fixture format** — defaults captured in D-12 (Dart-literal fixtures, ~50 cases per locale, anchor cases strict, statistical bucket ≥95%) are recommendations downstream agents can override with cause.
- **億-scale amounts** (e.g., 一億二千万 = 120,000,000) — not in v1.3 milestone scope.
- **English voice number parsing** — explicitly deferred to v1.4+.
- **Voice category resolver level-2 enforcement** (VOICE-04/05/06) — Phase 21.
- **Voice fills shared details form integration** (INPUT-02) — Phase 22.
- **Record button UX** (REC-01, REC-02) — Phase 22.
- **Pinyin / romaji defensive fallbacks** — explicit boundary D-08.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **VOICE-01** | Voice parser converts compound numbers without digit dropping: zh "2千2百零4元"→2204, ja「にせんにひゃくよん（円）」→2204 | State machine algorithm in §Architecture Patterns Pattern 1 + Pattern 2; anchor cases mapped 1:1 to `test()` blocks in §Validation Architecture |
| **VOICE-02** | Voice parser combines intra-number pauses via continued-listening window + locale-aware combining state machine; zh "1千8百"+pause+"4十元"→1840, ja「せんはっぴゃく」+pause+「よんじゅう（円）」→1840 | Double-gate predicate in §Architecture Patterns Pattern 3; lexical predicate walked through both anchor cases; `fake_async` test seam in §Validation Architecture |
| **VOICE-03** | Per-locale corpora ≥95% accuracy each; both corpora committed as test fixtures; per-locale accuracy reported separately | Dart-literal fixture format in §Code Examples; aggregate accuracy reporter pattern (`group()` + per-case `expect` + summary print) in §Validation Architecture |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Numeral token dictionary (ja) | Infrastructure | — | Pure data (const Map); lexicon is a project-wide capability per "Thin Feature" rule. Mirrors `MerchantDatabase` pattern |
| Numeral state machine (zh + ja) | Infrastructure | — | Stateless NLP algorithm; not feature-specific. Same shape as `RuleEngine.classify`, `MerchantDatabase.findMerchant` |
| Voice chunk merger (buffer + 2.5s window + merge predicate) | Application | — | Stateful orchestrator coordinating Infrastructure (state machine) + Infrastructure (SpeechRecognitionService). Precedent: `SyncEngine`, `TransactionChangeTracker` |
| `restartListen()` API surface | Infrastructure | — | Plugin-wrapper concern; lives next to `startListening()` on `SpeechRecognitionService` |
| Locale routing (extractAmount → which machine) | Application | — | Use-case orchestration; `ParseVoiceInputUseCase.execute` already knows locale via screen-level `voiceLocaleIdProvider` |
| Voice screen integration (`_onResult` → merger) | Presentation | — | UI layer feeds chunks to merger; merchant/category/date paths unchanged through stateless `parseVoiceInputUseCase.execute()` |

**Tier sanity check passes:** No Domain layer touched (no new models needed — `VoiceParseResult` already has `int? amount`). No Data layer touched (no Drift schema). No reverse-direction imports.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `speech_to_text` | ^7.0.0 (pinned in pubspec.yaml:41) | Underlying speech recognition plugin (already in project) | csdcorp/speech_to_text is the de facto Flutter speech plugin; iOS uses `SFSpeechRecognizer`, Android uses Google `SpeechRecognizer` [VERIFIED: pubspec.yaml:41; csdcorp/speech_to_text changelog] |
| `fake_async` | ^1.3.3 (pinned in pubspec.yaml:89) | Test seam for merger 2.5s window timer | Already used by `phase6_sync_coverage_test.dart` and `websocket_service_test.dart` for timer-driven code [VERIFIED: pubspec.yaml:89; repo precedent] |
| `mocktail` | ^1.0.4 (pinned in pubspec.yaml:90) | Mock `SpeechRecognitionService` for merger tests | Project-standard mocking library [VERIFIED: pubspec.yaml:90] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` | SDK | `group()` / `test()` / `expect()` corpus runner | Anchor cases as named `test()`; statistical bucket as `group()` with per-case `expect()` |
| `riverpod_annotation` | already in project | `@riverpod` codegen for `voiceChunkMergerProvider` | Mirrors `parseVoiceInputUseCaseProvider` (`repository_providers.dart:232-239`) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `fake_async` for timer tests | Real `Future.delayed(2500ms)` per test | Adds 2.5s × N tests = test-suite drag; `fake_async` flushes instantly. Reject real-timer approach. |
| `restartListen()` as new method | Merger re-calls `startListening()` with all 5 params | New method = single source of truth for restart config; merger doesn't need to remember `localeId`/`listenFor`/`pauseFor`/callbacks. Recommend new method. |
| Locale via constructor injection | Locale via per-call parameter | `ParseVoiceInputUseCase` constructed once, but locale changes per recording session via `voiceLocaleIdProvider`. Parameter approach matches existing per-call shape of `extractAmount`. Recommend parameter. |
| Trie-backed longest-match dict tokenizer (ja) | Hand-coded if/else chains | Dictionary has 25+ entries; trie/sorted-keys greedy match scales linearly and matches the canonical Japanese tokenization pattern [CITED: Sudachi Mode A / focareg longest-match principle, arxiv:2305.19045] |

**Installation:**

No new packages required. `speech_to_text`, `fake_async`, `mocktail` already pinned.

**Version verification:**
```bash
grep "^  speech_to_text\|^  fake_async\|^  mocktail" pubspec.yaml
# speech_to_text: ^7.0.0
# fake_async: ^1.3.3
# mocktail: ^1.0.4
```

## Package Legitimacy Audit

> Phase 20 installs **zero** new packages — only consumes already-pinned deps. Slopcheck not required.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| speech_to_text | pub.dev | 8+ yrs (initial release 2017) | popular Flutter speech plugin | github.com/csdcorp/speech_to_text | n/a (already in project) | Approved |
| fake_async | pub.dev | dart-lang first-party | core Dart library | github.com/dart-lang/fake_async | n/a (already in project) | Approved |
| mocktail | pub.dev | maintained by felangel | popular Dart mocking lib | github.com/felangel/mocktail | n/a (already in project) | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Project Constraints (from CLAUDE.md)

These directives are enforced for every plan / task in this phase:

1. **Thin Feature rule** — state machine + dictionary MUST live in `lib/infrastructure/voice/`, NEVER in `lib/features/`. Application use case (`parse_voice_input_use_case.dart`) is the orchestrator; merger sits in `lib/application/voice/` alongside.
2. **Layer dependency direction** — domain must not import data; application/infrastructure may not import features; structurally enforced by `import_guard` custom_lint + arch tests.
3. **Riverpod 3 conventions** — provider names strip `Notifier` suffix; `AsyncValue.value` is nullable; `ref.listen` for side-effects, `ref.watch` for reads. Use `ProviderContainer.test()` in tests, not `addTearDown(container.dispose)`. (Merger is plain class, not Notifier — provider just wires it.)
4. **`@riverpod` codegen required** — after editing any `@riverpod`-annotated provider, run `flutter pub run build_runner build --delete-conflicting-outputs`.
5. **Immutability** — use `copyWith` on Freezed classes; no in-place mutation. (Not impactful here — state machine is functional; merger holds mutable buffer/timer fields, which is the documented exception per `SyncEngine`/`TransactionChangeTracker` precedent.)
6. **`intl` pinned at 0.20.2** — do not bump.
7. **Test coverage ≥70% per-file** (lib + new tests both touched), `flutter analyze` 0 issues, `dart run custom_lint --no-fatal-infos` 0 errors, `import_guard` 0 violations — all before commit.
8. **Tests are first-class code** — same quality standards as production.

## Architecture Patterns

### System Architecture Diagram

```
[Voice Screen]
   │
   │ (1) startListening(localeId, onResult, onSoundLevel)
   ▼
[SpeechRecognitionService]              ← infrastructure/speech/  (modified: + restartListen())
   │
   │ (2) emits SpeechRecognitionResult
   │       with finalResult: true/false
   ▼
[VoiceChunkMerger]                       ← application/voice/      (NEW)
   │  ─ buffers final chunks
   │  ─ runs double-gate predicate (time + lexical)
   │  ─ on merge-success: calls SpeechRecognitionService.restartListen()
   │  ─ on window-expire: commits buffer
   │
   │ (3) commits buffered text
   ▼
[VoiceTextParser.extractAmount(text, locale)]  ← application/voice/ (refactored: thin transfer station)
   │
   │ (4) routes by locale
   ▼
[NumeralStateMachine.parse(text)]        ← infrastructure/voice/   (NEW abstract base)
   ├──► ChineseNumeralStateMachine                                  (NEW concrete)
   │      normalize → tokenize → scan section-accumulator
   │
   └──► JapaneseNumeralStateMachine                                 (NEW concrete)
          ├─ uses JapaneseNumeralDictionary (const Map)             (NEW data file)
          ├─ longest-match tokenize against dictionary
          ├─ scan section-accumulator
          └─ flushes section on Unit(10000)

[VoiceTextParser.extractAndMatchMerchant / extractDate]  ← UNCHANGED
[FuzzyCategoryMatcher / ParseVoiceInputUseCase]          ← UNCHANGED except merger wiring
```

### Recommended Project Structure
```
lib/
├── infrastructure/
│   ├── voice/                                  # NEW directory
│   │   ├── numeral_state_machine.dart          # abstract base + NumeralToken sealed class
│   │   ├── chinese_numeral_state_machine.dart  # concrete zh
│   │   ├── japanese_numeral_state_machine.dart # concrete ja
│   │   └── japanese_numeral_dictionary.dart    # const Map<String, NumeralToken>
│   └── speech/
│       └── speech_recognition_service.dart     # MODIFIED: + restartListen()
├── application/
│   └── voice/
│       ├── voice_chunk_merger.dart             # NEW: stateful merger
│       ├── voice_text_parser.dart              # MODIFIED: thin transfer station
│       ├── parse_voice_input_use_case.dart     # MODIFIED: wires merger
│       └── repository_providers.dart           # MODIFIED: + voiceChunkMergerProvider
└── features/
    └── accounting/
        └── presentation/
            └── screens/
                └── voice_input_screen.dart     # MODIFIED: _onResult → merger.feedChunk(...)

test/
├── unit/
│   ├── infrastructure/
│   │   └── voice/                                                  # NEW
│   │       ├── chinese_numeral_state_machine_test.dart
│   │       ├── japanese_numeral_state_machine_test.dart
│   │       ├── japanese_numeral_dictionary_test.dart               # lexicon completeness
│   │       ├── voice_number_parser_corpus_zh_test.dart             # statistical ≥95%
│   │       └── voice_number_parser_corpus_ja_test.dart             # statistical ≥95%
│   └── application/
│       └── voice/
│           └── voice_chunk_merger_test.dart                        # fake_async timer + double-gate
└── fixtures/
    ├── voice_corpus_zh.dart                                        # ~50 cases
    └── voice_corpus_ja.dart                                        # ~50 cases
```

### Pattern 1: Chinese Numeral State Machine — section accumulator with 零-placeholder

**What:** Single-pass left-to-right scan with two-level accumulator: `currentSection` holds the partial result under the current 万-multiplier; `currentDigit` is the pending multiplier for the next Unit; `total` is the cumulative result. On encountering `Unit(10000)`, flush `currentSection + currentDigit` (or just `currentDigit` if section empty) × 10000 into `total`. This is the algorithm already in `_extractKanjiAmount` (`voice_text_parser.dart:104-137`) — the rebuild fixes the broken final-tail handling and explicitly models `ZeroPlaceholder` as a no-op token (it doesn't change `currentDigit` or `currentSection`, but it does break the "implicit multiplier" assumption).

**When to use:** Chinese / Japanese kanji numerals where units stack multiplicatively (1×千 + 8×百 = 1800) and `万` is a hard section break.

**Algorithm (pseudo-Dart):**

```dart
int? parse(String text) {
  final tokens = normalize(text);            // List<NumeralToken>
  if (tokens.isEmpty) return null;

  var total = 0;
  var section = 0;
  var digit = 0;
  var sawAny = false;

  for (final tok in tokens) {
    switch (tok) {
      case Digit(:final value):
        digit = value;
        sawAny = true;

      case Unit(:final power) when power == 10000:
        // Flush whole section as × 10000 and reset
        final scoped = section + (digit == 0 ? 1 : digit);  // 万 alone == 10000
        total += scoped * 10000;
        section = 0;
        digit = 0;
        sawAny = true;

      case Unit(:final power):
        // 千/百/十: apply digit as multiplier (default 1 if Unit appears bare like 千二百)
        section += (digit == 0 ? 1 : digit) * power;
        digit = 0;
        sawAny = true;

      case ZeroPlaceholder():
        // zh-only: 「2千2百零4」the 零 just resets digit; the next Digit lands as bare-tail
        digit = 0;
        sawAny = true;

      case Skip():
        // currency suffix, whitespace, etc.
        continue;
    }
  }
  // Flush bare-tail digit (no following unit) — e.g., "2千2百零4" → digit=4
  section += digit;
  total += section;
  return sawAny && total > 0 ? total : null;
}
```

**Walk-through of zh anchor "2千2百零4元":**
- normalize → `[Digit(2), Unit(1000), Digit(2), Unit(100), ZeroPlaceholder, Digit(4), Skip(元)]`
- Digit(2): digit=2
- Unit(1000): section += 2×1000 = 2000, digit=0
- Digit(2): digit=2
- Unit(100): section += 2×100 = 2200, digit=0
- ZeroPlaceholder: digit=0 (no-op effectively)
- Digit(4): digit=4
- Skip: ignored
- Flush: section += 4 → 2204; total += 2204 → **2204** ✓

**Walk-through of ja anchor 「一万二千」:**
- normalize → `[Digit(1), Unit(10000), Digit(2), Unit(1000)]`
- Digit(1): digit=1
- Unit(10000): total += (0 + 1)×10000 = 10000, section=0, digit=0
- Digit(2): digit=2
- Unit(1000): section += 2×1000 = 2000, digit=0
- Flush: total += 2000 → **12000** ✓

**Example:**
```dart
// Source: existing lib/application/voice/voice_text_parser.dart:104-137 (algorithm pattern)
// + new ZeroPlaceholder handling and bare-tail fix (anchor zh "2千2百零4元")
final machine = ChineseNumeralStateMachine();
assert(machine.parse('2千2百零4元') == 2204);
assert(machine.parse('1千8百4十元') == 1840);   // single-pass complete
```

### Pattern 2: Japanese State Machine — longest-match tokenization over voicing dictionary

**What:** Same section-accumulator algorithm as Pattern 1, but `normalize()` must do **greedy longest-match tokenization** against `japanese_numeral_dictionary.dart`. Naive char-by-char tokenization fails on multi-char entries (e.g., はっぴゃく must NOT split into は + っ + ぴ + ゃ + く).

**When to use:** Japanese hiragana numerals where dictionary entries span 2–4 chars (はっぴゃく, ろっぴゃく, さんびゃく, いっせん, さんぜん, はっせん, いちまん, …).

**Algorithm (pseudo-Dart for the tokenizer):**

```dart
// Pre-compute: sort dictionary keys by descending length once at class init.
static final _sortedKeys = japaneseNumeralDictionary.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

List<NumeralToken> normalize(String text) {
  final tokens = <NumeralToken>[];
  var i = 0;
  while (i < text.length) {
    NumeralToken? matched;
    int? matchLen;
    // Try longest match first (sorted descending by key length)
    for (final key in _sortedKeys) {
      if (i + key.length > text.length) continue;
      if (text.substring(i, i + key.length) == key) {
        matched = japaneseNumeralDictionary[key]!;
        matchLen = key.length;
        break;
      }
    }
    // Fallback: arabic digit or kanji digit single char
    if (matched == null) {
      final ch = text[i];
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        matched = Digit(int.parse(ch));
        matchLen = 1;
      } else if (kanjiDigits.containsKey(ch)) {
        matched = Digit(kanjiDigits[ch]!);
        matchLen = 1;
      } else {
        matched = const Skip();
        matchLen = 1;
      }
    }
    if (matched is! Skip) tokens.add(matched);
    i += matchLen!;
  }
  return tokens;
}
```

**Dictionary shape (≥30 entries — see §Code Examples):**

```dart
const Map<String, NumeralToken> japaneseNumeralDictionary = {
  // ── Digits (multi-reading) ──
  'いち': Digit(1), 'ひと': Digit(1),
  'に':   Digit(2), 'ふた': Digit(2),
  'さん': Digit(3),
  'よん': Digit(4), 'し':   Digit(4),
  'ご':   Digit(5),
  'ろく': Digit(6),
  'なな': Digit(7), 'しち': Digit(7),
  'はち': Digit(8),
  'きゅう': Digit(9), 'く': Digit(9),
  'ゼロ': ZeroPlaceholder(), 'れい': ZeroPlaceholder(), 'まる': ZeroPlaceholder(),
  // ── Unit base forms ──
  'せん':   Unit(1000),
  'ひゃく': Unit(100),
  'じゅう': Unit(10),
  'まん':   Unit(10000),
  // ── Voicing / sokuon (multi-char, MUST longest-match first) ──
  'いっせん':   PackedToken([Digit(1), Unit(1000)]),    // 1×1000 = 1000
  'さんぜん':   PackedToken([Digit(3), Unit(1000)]),    // 3×1000 = 3000 (rendaku)
  'はっせん':   PackedToken([Digit(8), Unit(1000)]),    // 8×1000 = 8000 (sokuon)
  'さんびゃく': PackedToken([Digit(3), Unit(100)]),     // 3×100 = 300 (voicing)
  'ろっぴゃく': PackedToken([Digit(6), Unit(100)]),     // 6×100 = 600 (sokuon)
  'はっぴゃく': PackedToken([Digit(8), Unit(100)]),     // 8×100 = 800 (sokuon)
  'いちまん':   PackedToken([Digit(1), Unit(10000)]),   // 1×10000 = 10000
  // ── Kanji digits (single char) — see kanjiDigits map below ──
};
```

`PackedToken` is a `NumeralToken` subtype that holds an inner list; the scanner expands it inline. This keeps the dictionary "data, not rules" per D-05.

**Walk-through of ja anchor 「にせんにひゃくよん」:**
- Longest-match: `に` → Digit(2); `せん` → Unit(1000); `に` → Digit(2); `ひゃく` → Unit(100); `よん` → Digit(4)
- Token stream: `[Digit(2), Unit(1000), Digit(2), Unit(100), Digit(4)]`
- Scan: digit=2 → section+=2000 → digit=2 → section+=200 → digit=4 → flush section+=4 → **2204** ✓

**Walk-through of ja anchor 「せんはっぴゃく」 + 「よんじゅう」 (merged):**
- Merger commits buffer "せんはっぴゃくよんじゅう" to parser
- Longest-match: `せん` → Unit(1000); `はっぴゃく` → PackedToken[Digit(8),Unit(100)]; `よん` → Digit(4); `じゅう` → Unit(10)
- Token stream: `[Unit(1000), Digit(8), Unit(100), Digit(4), Unit(10)]`
- Scan: Unit(1000) with digit=0 → section += 1×1000 = 1000 → Digit(8) → Unit(100) section += 8×100 = 1800 → Digit(4) → Unit(10) section += 4×10 = 1840 → flush → **1840** ✓

**Example:**
```dart
// Source: longest-match principle [CITED: Sudachi Mode A, arxiv:2305.19045 feature-sequence trie]
final machine = JapaneseNumeralStateMachine();
assert(machine.parse('にせんにひゃくよん') == 2204);
assert(machine.parse('せんはっぴゃくよんじゅう') == 1840);
assert(machine.parse('一万二千') == 12000);  // regression guard
```

### Pattern 3: Voice Chunk Merger — double-gate predicate + window timer

**What:** A stateful class owning (a) `String _buffer`, (b) `Timer? _windowTimer`, (c) `_lastFinalAt` timestamp. Exposes `feedChunk(String text, {required bool isFinal})` and `void dispose()`. On final chunk: run double-gate against the current buffer; pass → append + restart timer + call `restartListen()`; fail → commit current buffer (if any), then start a new buffer with the new chunk + restart timer. On window-timer expiry: commit buffer (call `parse`), clear, notify listeners via callback. On `dispose()`: cancel timer, clear buffer.

**When to use:** Cross-final-result merging where the recognizer fragments a single user utterance into multiple `finalResult: true` emissions separated by short pauses.

**Lexical gate (D-10) precise definition:**

A buffer's last token is "not-yet-closed numeric" iff, after running `normalize(buffer)` on the buffer:

1. The last token is a `Unit(power)` with **no preceding Digit in the same section since the previous Unit** — meaning the unit appears bare and expects a multiplier-from-next-chunk. *(Note: This case is actually unusual — `1千8百` parses with implicit digit=1 for unit-without-multiplier — but the gate's purpose is "does the speaker likely want to append more?", and `8百` followed by silence usually does signal more to come.)*
2. **OR** the last token is a `Unit(power)` and the **token before it is a Digit that fits as its multiplier** — meaning `1千8百` ends on `Unit(100)` preceded by `Digit(8)` — the section is "open" because no smaller unit (十) has closed it.
3. **OR** the last token is a bare `Digit` at the very end with the previous Unit larger than 10 — meaning a bare-tail like `2千2百零4` could be the start of `…零4十` (incomplete) **or** could be the complete `2204` (typical case).

**Pragmatic operational predicate (recommended):**

```dart
bool _bufferLooksOpen(String buffer) {
  final tokens = normalizeForLocale(buffer, _locale);
  if (tokens.isEmpty) return false;
  final last = tokens.last;
  // Case A: last token is a Unit > 10 (千/百/万) → open: speaker may add a tens digit
  if (last is Unit && last.power >= 100) return true;
  // Case B: last token is a Unit of 10 (十) preceded immediately by a Digit
  //         AND no smaller scale follows → "4十" alone IS closed at 40,
  //         but "1千8百" → "4十" pattern means buffer "1千8百" needs to absorb "4十"
  //         The check fires on the BUFFER, so "1千8百" ends on Unit(100) → Case A handles it.
  // Case C: bare Digit at end → ambiguous; allow merge only if previous Unit was ≥100
  if (last is Digit) {
    final prevUnits = tokens.whereType<Unit>().toList();
    if (prevUnits.isNotEmpty && prevUnits.last.power >= 100) return true;
  }
  return false;
}

bool _chunkStartsNumeric(String chunk) {
  final tokens = normalizeForLocale(chunk, _locale);
  return tokens.isNotEmpty && (tokens.first is Digit || tokens.first is Unit);
}

bool shouldMerge(String buffer, String newChunk, DateTime now) {
  if (now.difference(_lastFinalAt) > Duration(milliseconds: 2500)) return false;
  if (!_bufferLooksOpen(buffer)) return false;
  if (!_chunkStartsNumeric(newChunk)) return false;
  return true;
}
```

**Walk-through of zh anchor "1千8百" + pause + "4十元":**
- Final 1 arrives: buffer="" → no buffer to gate → buffer="1千8百", `_lastFinalAt`=t1, start 2.5s timer, `restartListen()`
- Final 2 arrives at t1+1.2s:
  - Time gate: 1.2s ≤ 2.5s ✓
  - `_bufferLooksOpen("1千8百")`: normalize → `[Digit(1), Unit(1000), Digit(8), Unit(100)]` → last is Unit(100) ≥ 100 → ✓
  - `_chunkStartsNumeric("4十元")`: normalize → `[Digit(4), Unit(10), Skip(元)]` → first is Digit ✓
  - Merge: buffer="1千8百4十元", restart timer, `restartListen()`
- Timer expires at t1+1.2s+2.5s = t1+3.7s: commit buffer → parse("1千8百4十元") → tokens `[Digit(1), Unit(1000), Digit(8), Unit(100), Digit(4), Unit(10), Skip]`
- Scan: digit=1 → section+=1000 → digit=8 → section+=800 → digit=4 → section+=40 → flush → **1840** ✓

**Walk-through of "1千8百" + pause + "现金" (false-merge regression):**
- Final 1: buffer="1千8百"
- Final 2 "现金" (cash) at t1+1.0s:
  - Time gate ✓
  - `_bufferLooksOpen` ✓
  - `_chunkStartsNumeric("现金")`: normalize → `[Skip, Skip]` → empty → ✗
  - Merge fails: commit "1千8百" → 1800; new buffer="现金" (which will commit on timer expiry as nothing, or — alt — merger could ignore non-numeric chunks entirely)
- **Recommendation:** when merge fails because new chunk is non-numeric, **do not** start a fresh buffer with the non-numeric chunk; immediately commit the existing buffer and clear. Non-numeric chunks flow through the normal merchant/category/date path via `parseVoiceInputUseCase.execute()` unchanged (per CONTEXT.md code_context line 130).

**Example:**
```dart
// Source: D-09, D-10, D-11 from CONTEXT.md
final merger = VoiceChunkMerger(
  parser: parser,
  speechService: speechService,
  locale: voiceLocale,
  onAmountResolved: (amount) => /* update parseResult */,
);
merger.feedChunk('1千8百', isFinal: true);  // buffers, starts 2.5s timer, restartListen()
// ... 1.2s later ...
merger.feedChunk('4十元', isFinal: true);   // merges → buffer="1千8百4十元"
// ... 2.5s later, no new chunks ...
// timer fires → parser.parse("1千8百4十元") → 1840 → onAmountResolved(1840)
```

### Anti-Patterns to Avoid

- **Char-by-char tokenization of Japanese.** はっぴゃく split into single chars yields `[は, っ, ぴ, ゃ, く]` — none of which are in the dictionary individually, so the whole token is dropped → result becomes 0 or wildly wrong. **Always use longest-match against sorted-by-length dictionary keys.**
- **Stateful state machine.** Adding a `_buffer` field to the parser violates D-03 ("functional, stateless `int? parse(String text)`") and makes corpus testing nondeterministic. Keep buffer/timer/window in the merger.
- **Storing locale as merger constructor arg AND parser parameter.** Pick one: per-recording-session locale → merger constructor; per-parse call → method parameter. Recommendation: merger constructor (one merger per recording session — `voice_input_screen.dart` recreates merger on each `_startRecording` if locale changed).
- **Catching `restartListen()` errors silently.** If `_speech.listen()` throws (recognizer busy, permission revoked mid-session), the merger MUST propagate to the screen so the screen can display an error. Don't swallow.
- **Mixing async `parse` with sync timer callback.** `parse(text)` is sync (`int? parse(String)` — D-03). The timer callback can call it directly. Don't wrap in `Future`.
- **Putting the corpus in `test/fixtures/voice_corpus_zh.yaml`** (or `.json`). Dart-literal fixtures (`.dart` files with `const List<({String input, int expected, String? note})>`) are IDE-navigable, refactor-safe, type-checked, and the precedent format in this repo. D-12 recommendation reaffirmed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hiragana → kanji conversion | Custom rule engine for rendaku/sokuon | **Dictionary entries** (D-05/06 already mandated) | Voicing rules in Japanese have many exceptions; storing the ~10 actual forms is finite and bug-free. Rule engine = endless edge cases. |
| Speech-to-text plugin | Bespoke iOS `SFSpeechRecognizer` / Android `SpeechRecognizer` bindings | `speech_to_text ^7.0.0` (already in project) | The plugin handles permissions, locale switching, partial vs final results, and platform deltas (sound-level normalization) |
| Timer cleanup in tests | Real `Future.delayed(2500ms)` | `fake_async` (already in pubspec) | `fake_async` instantly advances simulated time; tests stay sub-millisecond |
| Mock `SpeechRecognitionResult` | Custom test double class | Use the real `SpeechRecognitionResult` constructor from `speech_to_text/speech_recognition_result.dart` (it's a plain Dart class with public constructor) | Mocktail-mocked services + real result objects is the cleanest seam |

**Key insight:** This phase is **all about avoiding the previous hand-rolled parser's failure modes**. The legacy `_extractKanjiAmount` was hand-rolled rule logic with a "remaining digits at the end" branch that double-counted in some cases and dropped digits after `零`. The rebuild uses two well-established patterns (longest-match tokenize + section-accumulator scan) that the broader NLP community has converged on for decades.

## Runtime State Inventory

> Phase 20 is not a rename/refactor — it builds new infrastructure and modifies one file's hot path. No runtime state inventory required (no stored data, no live service config, no OS-registered state, no env vars, no build artifacts that drift).

**Verified:** Confirmed against checklist — no Drift schema change, no ChromaDB/Mem0/secrets keys touched, no Task Scheduler / launchd / pm2 dependencies, no env vars referenced, no installed-package names depend on phase outputs.

## Common Pitfalls

### Pitfall 1: speech_to_text `finalResult` semantics differ between iOS and Android
**What goes wrong:** iOS reliably emits `finalResult: true` exactly once per `listen()` session when `pauseFor` expires, `stop()` is called, or `listenFor` expires. Android tends to emit final results more eagerly (its system recognizer enforces its own short pause) and pauseFor is documented as **ignored on Android** per upstream changelog.
**Why it happens:** Platform recognizer APIs are fundamentally different.
**How to avoid:** The merger's 2.5s window timer is the unifying contract — it doesn't care how many finals arrive or which platform emitted them. Each `feedChunk(text, isFinal: true)` is treated identically. Tests run on host machine (no platform recognizer); production behavior is verified manually via HUMAN-UAT.md on both iOS and Android device builds.
**Warning signs:** Android-only flakiness in corpus tests would indicate platform-specific path leakage. Tests should never instantiate `speech_to_text.SpeechToText` — only mock it.
*Source: [CITED: pub.dev/speech_to_text changelog — "pauseFor … ignored on Android devices"]*

### Pitfall 2: Multi-reading dictionary ambiguity (なな vs しち, よん vs し)
**What goes wrong:** Recognizer may output either reading for the same digit (`なな` or `しち` for 7), and the parser must accept both. If the dictionary only has one reading, ~50% of relevant utterances will be dropped.
**Why it happens:** Real Japanese speakers alternate between native (`なな`, `よん`) and Sino-Japanese (`しち`, `し`) readings, often dialectally.
**How to avoid:** D-05 already mandates all readings. Verify with a corpus case per reading: `しちひゃく` → 700 AND `ななひゃく` → 700.
**Warning signs:** Corpus accuracy below 95% with consistent failures clustering on a single digit reading.

### Pitfall 3: `restartListen()` race with in-flight final result
**What goes wrong:** Merger calls `restartListen()` immediately after `feedChunk(isFinal: true)`. But the recognizer's internal state may still be processing — calling `listen()` while it's mid-stop throws or silently no-ops.
**Why it happens:** speech_to_text wraps native APIs that have multi-state lifecycles (listening → stopping → stopped).
**How to avoid:** `restartListen()` implementation should check `_speech.isListening` first; if true, call `_speech.cancel()` (or `stop()`) first, then call `listen()` on the next microtask via `Future(() => _speech.listen(...))`. Or — simpler — wrap in a try/catch and retry once after a 50ms delay. Pin this in the implementation.
**Warning signs:** Manual testing shows the recognizer drops the second utterance entirely after a pause.

### Pitfall 4: Lexical gate false-positive on numeric-prefixed merchant ("4十元" vs "四十マート")
**What goes wrong:** A merchant or category phrase that happens to start with a numeric token (e.g., a fictional store named「四十マート」or "100円ショップ") would pass `_chunkStartsNumeric` and false-merge.
**Why it happens:** The gate only inspects the leading token; it can't know semantically that the chunk is meant as a merchant name.
**How to avoid:** In practice, mitigated by (a) `_buffer` must also be open (so `1千8百` + `100円ショップ` is a false-merge only if the buffer was open; if the user said `680円` first → buffer "680円" → not open → no false merge), and (b) the timer is short (2.5s) — most merchant phrases follow the amount with > 2.5s pause. Accept residual risk and surface via corpus tests; if a real false-merge case emerges, add a Skip-token recognizer for currency suffixes already in the buffer that signals "closed."
**Warning signs:** Specific user-reported case in HUMAN-UAT.md or beta feedback.

### Pitfall 5: `normalize()` returning empty list for legitimate input
**What goes wrong:** A locale-mismatched input (Japanese text passed to ChineseStateMachine) tokenizes to all-Skip → empty token list → `parse` returns null → amount silently 0.
**Why it happens:** Mixed-locale defensive coding gap.
**How to avoid:** When the routing in `extractAmount(text, locale)` selects a state machine, the machine still must return `null` (not 0, not throw) on no-tokens. Test: ja state machine on zh text returns null cleanly. The Arabic-numeral path in `_extractArabicAmount` (which stays unchanged) is the safety net for cross-locale inputs that contain digits.
**Warning signs:** Amount field shows 0 in UI when user said something parseable.

## Code Examples

Verified patterns from canonical sources and repo precedent:

### NumeralToken sealed type
```dart
// Source: D-07 token taxonomy; Dart sealed class pattern
// File: lib/infrastructure/voice/numeral_state_machine.dart

sealed class NumeralToken {
  const NumeralToken();
}

class Digit extends NumeralToken {
  final int value;
  const Digit(this.value);
}

class Unit extends NumeralToken {
  final int power;   // 10, 100, 1000, 10000
  const Unit(this.power);
}

class ZeroPlaceholder extends NumeralToken {
  const ZeroPlaceholder();
}

class Skip extends NumeralToken {
  const Skip();
}

/// Holds a pre-expanded multi-token sequence for dictionary entries like
/// はっぴゃく → [Digit(8), Unit(100)]. The scanner expands inline.
class PackedToken extends NumeralToken {
  final List<NumeralToken> inner;
  const PackedToken(this.inner);
}
```

### Abstract base
```dart
// Source: D-01, D-02, D-03
// File: lib/infrastructure/voice/numeral_state_machine.dart

abstract class NumeralStateMachine {
  const NumeralStateMachine();

  /// Parse a numeric text string into an integer amount.
  /// Returns null if no recognizable numeric content is found.
  int? parse(String text);

  /// Locale-specific tokenization. Subclasses implement.
  List<NumeralToken> normalize(String text);

  /// Shared scanner (Pattern 1 in RESEARCH.md). Concrete classes call this.
  @protected
  int? scan(List<NumeralToken> tokens) {
    if (tokens.isEmpty) return null;
    var total = 0, section = 0, digit = 0;
    var sawAny = false;
    for (final tok in _expandPacked(tokens)) {
      switch (tok) {
        case Digit(:final value):
          digit = value; sawAny = true;
        case Unit(:final power) when power == 10000:
          total += (section + (digit == 0 ? 1 : digit)) * 10000;
          section = 0; digit = 0; sawAny = true;
        case Unit(:final power):
          section += (digit == 0 ? 1 : digit) * power;
          digit = 0; sawAny = true;
        case ZeroPlaceholder():
          digit = 0; sawAny = true;
        case Skip():
          continue;
        case PackedToken():
          // Already expanded by _expandPacked
          continue;
      }
    }
    section += digit;
    total += section;
    return sawAny && total > 0 ? total : null;
  }

  Iterable<NumeralToken> _expandPacked(List<NumeralToken> tokens) sync* {
    for (final t in tokens) {
      if (t is PackedToken) {
        yield* t.inner;
      } else {
        yield t;
      }
    }
  }
}
```

### Chinese concrete
```dart
// Source: D-02, D-08 (kanji-only)
// File: lib/infrastructure/voice/chinese_numeral_state_machine.dart

class ChineseNumeralStateMachine extends NumeralStateMachine {
  const ChineseNumeralStateMachine();

  static const _kanjiDigits = <String, int>{
    '零': 0, '〇': 0, '一': 1, '壱': 1, '壹': 1,
    '二': 2, '弐': 2, '贰': 2, '三': 3, '参': 3, '叁': 3,
    '四': 4, '五': 5, '伍': 5, '六': 6, '七': 7, '八': 8, '九': 9,
  };
  static const _kanjiUnits = <String, int>{
    '十': 10, '百': 100, '千': 1000, '仟': 1000, '万': 10000, '萬': 10000,
  };
  // Currency suffix Skip set
  static final _skipPattern = RegExp(r'[\s¥￥円えんyen元块塊]');

  @override
  int? parse(String text) => scan(normalize(text));

  @override
  List<NumeralToken> normalize(String text) {
    final tokens = <NumeralToken>[];
    for (final ch in text.characters) {
      if (ch == '零' || ch == '〇') {
        tokens.add(const ZeroPlaceholder());
      } else if (_kanjiDigits.containsKey(ch)) {
        tokens.add(Digit(_kanjiDigits[ch]!));
      } else if (_kanjiUnits.containsKey(ch)) {
        tokens.add(Unit(_kanjiUnits[ch]!));
      } else if (RegExp(r'[0-9]').hasMatch(ch)) {
        tokens.add(Digit(int.parse(ch)));
      } else if (_skipPattern.hasMatch(ch)) {
        // skip whitespace/currency
      }
      // anything else (random kanji/text): drop silently
    }
    return tokens;
  }
}
```

### Japanese concrete (longest-match tokenize)
```dart
// Source: D-05, D-06, D-07 + longest-match principle [CITED: Sudachi, focareg]
// File: lib/infrastructure/voice/japanese_numeral_state_machine.dart

import 'japanese_numeral_dictionary.dart';

class JapaneseNumeralStateMachine extends NumeralStateMachine {
  JapaneseNumeralStateMachine();

  static final _sortedKeys = japaneseNumeralDictionary.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static const _kanjiDigits = <String, int>{
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9, '零': 0, '〇': 0,
  };
  static const _kanjiUnits = <String, int>{
    '十': 10, '百': 100, '千': 1000, '万': 10000, '萬': 10000,
  };
  static final _skipPattern = RegExp(r'[\s¥￥円えんyen]');

  @override
  int? parse(String text) => scan(normalize(text));

  @override
  List<NumeralToken> normalize(String text) {
    final tokens = <NumeralToken>[];
    var i = 0;
    while (i < text.length) {
      NumeralToken? matched;
      int? matchLen;
      // Greedy longest match against dictionary
      for (final key in _sortedKeys) {
        if (i + key.length > text.length) continue;
        if (text.substring(i, i + key.length) == key) {
          matched = japaneseNumeralDictionary[key]!;
          matchLen = key.length;
          break;
        }
      }
      if (matched == null) {
        final ch = text[i];
        if (RegExp(r'[0-9]').hasMatch(ch)) {
          matched = Digit(int.parse(ch));
        } else if (_kanjiDigits.containsKey(ch)) {
          matched = Digit(_kanjiDigits[ch]!);
        } else if (_kanjiUnits.containsKey(ch)) {
          matched = Unit(_kanjiUnits[ch]!);
        } else if (_skipPattern.hasMatch(ch)) {
          matched = const Skip();
        } else {
          matched = const Skip();  // drop unknown chars
        }
        matchLen = 1;
      }
      if (matched is! Skip) tokens.add(matched);
      i += matchLen!;
    }
    return tokens;
  }
}
```

### Japanese dictionary (data file)
```dart
// Source: D-05, D-06
// File: lib/infrastructure/voice/japanese_numeral_dictionary.dart

import 'numeral_state_machine.dart';

const Map<String, NumeralToken> japaneseNumeralDictionary = {
  // ── Digits, multi-reading ──
  'いち': Digit(1), 'ひと': Digit(1),
  'に':   Digit(2), 'ふた': Digit(2),
  'さん': Digit(3),
  'よん': Digit(4), 'し': Digit(4),
  'ご':   Digit(5),
  'ろく': Digit(6),
  'なな': Digit(7), 'しち': Digit(7),
  'はち': Digit(8),
  'きゅう': Digit(9), 'く': Digit(9),
  'ゼロ': ZeroPlaceholder(),
  'れい': ZeroPlaceholder(),
  'まる': ZeroPlaceholder(),
  // ── Unit bases ──
  'せん':   Unit(1000),
  'ひゃく': Unit(100),
  'じゅう': Unit(10),
  'まん':   Unit(10000),
  // ── Voicing / sokuon (packed direct entries; longest-match priority) ──
  'いっせん':   PackedToken([Digit(1), Unit(1000)]),
  'さんぜん':   PackedToken([Digit(3), Unit(1000)]),
  'はっせん':   PackedToken([Digit(8), Unit(1000)]),
  'さんびゃく': PackedToken([Digit(3), Unit(100)]),
  'ろっぴゃく': PackedToken([Digit(6), Unit(100)]),
  'はっぴゃく': PackedToken([Digit(8), Unit(100)]),
  'いちまん':   PackedToken([Digit(1), Unit(10000)]),
  // Note: room to grow with 一千 (いっせん variant) etc. as corpus reveals
};
```

### Merger (stateful, plain class — dispose precedent: SyncEngine)
```dart
// Source: D-09, D-10, D-11, D-12 + SyncEngine pattern (sync_engine.dart:86-92)
// File: lib/application/voice/voice_chunk_merger.dart

import 'dart:async';
import 'dart:ui' show Locale;

import '../../infrastructure/speech/speech_recognition_service.dart';
import '../../infrastructure/voice/numeral_state_machine.dart';

class VoiceChunkMerger {
  VoiceChunkMerger({
    required NumeralStateMachine parser,
    required SpeechRecognitionService speechService,
    required Locale locale,
    required void Function(int amount) onAmountResolved,
    Duration windowDuration = const Duration(milliseconds: 2500),
  })  : _parser = parser,
        _speechService = speechService,
        _locale = locale,
        _onAmountResolved = onAmountResolved,
        _windowDuration = windowDuration;

  final NumeralStateMachine _parser;
  final SpeechRecognitionService _speechService;
  final Locale _locale;
  final void Function(int amount) _onAmountResolved;
  final Duration _windowDuration;

  String _buffer = '';
  Timer? _windowTimer;
  DateTime? _lastFinalAt;
  bool _isActive = true;

  /// Called by the screen's _onResult for every finalResult emission.
  void feedChunk(String text, {required bool isFinal}) {
    if (!_isActive || !isFinal) return;
    final now = DateTime.now();
    if (_shouldMerge(text, now)) {
      _buffer += text;
    } else {
      _commit();
      _buffer = text;
    }
    _lastFinalAt = now;
    _restartTimer();
    _restartListenIfActive();
  }

  /// User tapped stop. Commit any pending buffer immediately.
  void onUserStop() {
    _isActive = false;
    _commit();
    _windowTimer?.cancel();
  }

  /// Disposes timer + cancels restart loop. Mirrors SyncEngine.dispose().
  void dispose() {
    _isActive = false;
    _windowTimer?.cancel();
    _windowTimer = null;
    _buffer = '';
  }

  bool _shouldMerge(String newChunk, DateTime now) {
    if (_buffer.isEmpty) return false;
    if (_lastFinalAt == null) return false;
    if (now.difference(_lastFinalAt!) > _windowDuration) return false;
    if (!_bufferLooksOpen()) return false;
    if (!_chunkStartsNumeric(newChunk)) return false;
    return true;
  }

  bool _bufferLooksOpen() {
    final tokens = _parser.normalize(_buffer);
    if (tokens.isEmpty) return false;
    final last = tokens.last;
    if (last is Unit && last.power >= 100) return true;
    if (last is Digit) {
      final units = tokens.whereType<Unit>().toList();
      if (units.isNotEmpty && units.last.power >= 100) return true;
    }
    return false;
  }

  bool _chunkStartsNumeric(String chunk) {
    final tokens = _parser.normalize(chunk);
    return tokens.isNotEmpty && (tokens.first is Digit || tokens.first is Unit);
  }

  void _commit() {
    if (_buffer.isEmpty) return;
    final amount = _parser.parse(_buffer);
    if (amount != null) _onAmountResolved(amount);
    _buffer = '';
  }

  void _restartTimer() {
    _windowTimer?.cancel();
    _windowTimer = Timer(_windowDuration, () {
      _commit();
      _isActive = false;
      // Stop auto-restart loop once buffer is committed via window timeout.
    });
  }

  void _restartListenIfActive() {
    if (!_isActive) return;
    // NOTE: speechService.restartListen() must guard against in-flight
    // listen() calls — see Pitfall 3.
    _speechService.restartListen();
  }
}
```

### Riverpod provider (mirrors appWebSocketServiceProvider precedent)
```dart
// Source: existing repository_providers.dart pattern; ref.onDispose precedent
// File: lib/application/voice/repository_providers.dart (or extend existing)

@riverpod
VoiceChunkMerger voiceChunkMerger(Ref ref, Locale locale) {
  final parser = locale.languageCode == 'ja'
      ? JapaneseNumeralStateMachine()
      : const ChineseNumeralStateMachine();
  final merger = VoiceChunkMerger(
    parser: parser,
    speechService: ref.watch(appSpeechRecognitionServiceProvider),
    locale: locale,
    onAmountResolved: (amount) {
      // Hook: screen reads via ref.listen or merger exposes a Stream<int>
    },
  );
  ref.onDispose(merger.dispose);
  return merger;
}
```

*Note: planner may choose to expose `onAmountResolved` as a callback set per-recording-session rather than at provider build time — see Open Questions.*

### Test fixture format (Dart literal)
```dart
// Source: D-12 default; existing test-fixture precedent (Dart literal preferred over YAML/JSON)
// File: test/fixtures/voice_corpus_zh.dart

class VoiceCorpusCase {
  final String input;
  final int expected;
  final String? note;
  const VoiceCorpusCase({
    required this.input,
    required this.expected,
    this.note,
  });
}

const List<VoiceCorpusCase> voiceCorpusZh = [
  // Anchor cases (also have dedicated named test() blocks):
  VoiceCorpusCase(input: '2千2百零4元', expected: 2204, note: '零-placeholder anchor'),
  // Routine cases:
  VoiceCorpusCase(input: '一百', expected: 100),
  VoiceCorpusCase(input: '两百', expected: 200, note: '两 vs 二'),
  VoiceCorpusCase(input: '三千五百', expected: 3500),
  VoiceCorpusCase(input: '一万二千', expected: 12000),
  VoiceCorpusCase(input: '九千九百九十九元', expected: 9999),
  // ... ~50 total
];
```

### Corpus test harness (per-locale ≥95% report)
```dart
// Source: D-12 + flutter_test conventions
// File: test/unit/infrastructure/voice/voice_number_parser_corpus_zh_test.dart

void main() {
  final parser = ChineseNumeralStateMachine();
  var pass = 0;
  final failures = <String>[];

  group('ChineseNumeralStateMachine — corpus (≥95% required)', () {
    for (final c in voiceCorpusZh) {
      test('input=${c.input} → expected=${c.expected}${c.note != null ? "  (${c.note})" : ""}', () {
        final actual = parser.parse(c.input);
        if (actual == c.expected) {
          pass++;
        } else {
          failures.add('${c.input}  expected=${c.expected}  actual=$actual');
        }
        // Per-case assert so individual failures are visible in test output
        expect(
          actual,
          equals(c.expected),
          reason: 'corpus case: input="${c.input}" expected=${c.expected} actual=$actual',
        );
      });
    }

    tearDownAll(() {
      final total = voiceCorpusZh.length;
      final accuracy = pass / total;
      // ignore: avoid_print
      print('zh corpus: $pass/$total (${(accuracy * 100).toStringAsFixed(1)}%)');
      expect(accuracy, greaterThanOrEqualTo(0.95),
          reason: 'zh corpus accuracy ${(accuracy * 100).toStringAsFixed(1)}% < 95%; '
              'failures:\n  ${failures.join("\n  ")}');
    });
  });
}
```

### Merger test with fake_async
```dart
// Source: phase6_sync_coverage_test.dart + websocket_service_test.dart precedent
// File: test/unit/application/voice/voice_chunk_merger_test.dart

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpeechService extends Mock implements SpeechRecognitionService {}

void main() {
  group('VoiceChunkMerger — intra-pause merge (VOICE-02)', () {
    test('zh anchor: "1千8百" + 1.2s + "4十元" → 1840', () {
      fakeAsync((async) {
        final svc = _MockSpeechService();
        when(() => svc.restartListen()).thenAnswer((_) async {});
        int? resolved;
        final merger = VoiceChunkMerger(
          parser: const ChineseNumeralStateMachine(),
          speechService: svc,
          locale: const Locale('zh'),
          onAmountResolved: (v) => resolved = v,
        );

        merger.feedChunk('1千8百', isFinal: true);
        async.elapse(const Duration(milliseconds: 1200));
        merger.feedChunk('4十元', isFinal: true);
        async.elapse(const Duration(milliseconds: 2500));  // window expires

        expect(resolved, equals(1840));
        merger.dispose();
      });
    });

    test('false-merge guard: "1千8百" + 1s + "现金" commits 1800, drops 现金', () {
      fakeAsync((async) {
        // ... similar shape, asserts resolved == 1800
      });
    });
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled kanji parser with implicit "remaining digits" tail (`_extractKanjiAmount`, lines 104-137) | Token-stream + section-accumulator with explicit `ZeroPlaceholder` | This phase | Fixes "1千8百零4" digit-drop bug AND removes the doubly-counted-tail edge case |
| Char-by-char tokenization | Greedy longest-match against sorted-by-length dictionary | This phase | Enables はっぴゃく / さんびゃく / etc. multi-char voicing entries [CITED: Sudachi Mode A] |
| Per-partial debounced `parseVoiceInputUseCase.execute()` (voice_input_screen.dart:219-225) for amount | Merger holds amount via cross-final-result window; partial debounce stays for merchant/category/date but bypasses amount path | This phase | Solves VOICE-02 intra-pause merging |
| `extractAmount(text)` (single-arg) | `extractAmount(text, locale)` (two-arg) | This phase | Locale-aware routing required by D-04 |

**Deprecated/outdated:**
- `_extractKanjiAmount` private method — fully deleted per D-04
- `test/unit/application/voice/voice_text_parser_test.dart:45-61` group ('Kanji amount extraction') — retired; replaced by `test/unit/infrastructure/voice/{chinese,japanese}_numeral_state_machine_test.dart` + corpus tests

## Assumptions Log

> All major design decisions are locked by CONTEXT.md (D-01..D-12). Only LOW-impact assumptions remain.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `restartListen()` as new method (vs re-call of `startListening()`) is the cleaner choice | §Alternatives Considered + Pattern 3 | If wrong, planner can swap to merger re-calling `startListening()` with cached params; behavior identical, just API shape differs. Low risk. |
| A2 | Lexical gate Case A (last token Unit ≥ 100 = open) and Case C (bare Digit after Unit ≥ 100 = open) covers all intended merges including both anchor cases | §Pattern 3 | If a real-user case shows false-negative (legit merge rejected), tighten gate by adding Case B (Unit==10 with preceding Digit). If false-positive (bad merge accepted), tighten by tracking ¥/円 currency-suffix Skip as "closed" signal. Both fixable post-hoc without architectural change. |
| A3 | Per-recording-session merger (re-created on every `_startRecording`) is the right lifecycle, not app-singleton | §Pattern 3 + provider example | If wrong, planner can promote to keepAlive provider; merger's `dispose()` handles either lifecycle cleanly. Low risk. |
| A4 | `voice_corpus_zh.dart` and `voice_corpus_ja.dart` belong in `test/fixtures/` (not `test/unit/infrastructure/voice/`) | §Project Structure | Pure file-location choice; trivially movable. CONTEXT.md D-12 default recommendation. |
| A5 | Per-locale corpus size ≈ 50 cases is sufficient to detect ≥95% accuracy with statistical confidence | §Test Framework | If too small, false-positive 95% pass with hidden 5%-bucket regression. Mitigation: corpus should be padded toward 100 cases per locale during planning if researcher's anchor-case list reveals undertested digit-ranges. |
| A6 | speech_to_text 7.x `_speech.listen()` is safe to re-invoke from merger after `finalResult: true` without explicitly calling `_speech.cancel()` first | §Pitfall 3 | If wrong, the second `listen()` no-ops or throws — manual testing on iOS + Android required. Pin defensive `if (isListening) cancel(); await listen();` in implementation. |

## Open Questions

1. **How does the screen receive merger output without a circular dependency?**
   - What we know: merger's `onAmountResolved` callback must update `_parseResult.amount`, then trigger `_resolveCategory` / `_buildAudioFeatures` (existing screen lifecycle).
   - What's unclear: whether to pass a setter callback at merger construction, expose a `Stream<int>` from merger, or use a Riverpod state notifier shim. All three work.
   - Recommendation: callback at construction (simplest; matches `SpeechRecognitionService.startListening`'s pattern of injected callbacks).

2. **What happens to non-final results during the merger window?**
   - What we know: D-09 says merger handles cross-`finalResult` buffering. The current screen also processes `partial` results via debounced `parseVoiceInputUseCase.execute` (line 219-225).
   - What's unclear: should partial results during the merger window also update an in-progress amount display, or only the final-merged amount?
   - Recommendation: keep partial-result path for the visual transcript ("you said: ...") but bypass the amount path during the window — partial amounts cause UI flicker. Merger commits the only "real" amount.

3. **Should the merger know about ja vs zh, or should `parser` injection be enough?**
   - What we know: merger calls `parser.normalize()` for the lexical gate, which is already locale-specific because the right parser was injected.
   - What's unclear: does the merger need `Locale` separately to route `extractAmount` (which still has its own locale-routing requirement)?
   - Recommendation: merger holds `Locale` purely for diagnostic/logging purposes (e.g., debug-print "zh merger committed: 1840"); does not branch on it. Routing happens at parser-injection time in the provider.

4. **What corpus categories to cover beyond the 5 anchor cases?**
   - What we know: ~50 cases per locale per D-12.
   - What's unclear: balance between digit-range coverage (1-9999 sampled), specific suffix combos (元/块/塊/円/円なし), specific intra-pause splits (千/百 split, 百/十 split, 万-boundary split).
   - Recommendation: budget split: 30% single-pass simple (e.g., "三百" → 300), 30% single-pass compound (e.g., "三千五百八十" → 3580), 20% with intra-pause (each goes through merger via a corpus-runner helper that injects pause), 10% edge (零-placeholder, multi-万-boundary, voicing-variant for ja), 10% near-miss (e.g., "三百" with following whitespace, mixed kanji/arabic).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All Dart code | ✓ (project standard) | matches existing | — |
| `speech_to_text` plugin | SpeechRecognitionService modifications | ✓ | ^7.0.0 (pubspec.yaml:41) | — |
| `fake_async` | Merger timer tests | ✓ | ^1.3.3 (pubspec.yaml:89) | — |
| `mocktail` | SpeechRecognitionService mocking | ✓ | ^1.0.4 (pubspec.yaml:90) | — |
| `build_runner` | Riverpod codegen for `voiceChunkMergerProvider` | ✓ (project standard) | matches existing | — |
| iOS recognizer / Android recognizer | Live device verification only | n/a in host tests | — | Host-machine tests use mocks; HUMAN-UAT.md tracks real-device verification |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `fake_async ^1.3.3` + `mocktail ^1.0.4` |
| Config file | `test/` directory (Flutter convention; no separate config) |
| Quick run command | `flutter test test/unit/infrastructure/voice/ test/unit/application/voice/voice_chunk_merger_test.dart` |
| Full suite command | `flutter test --coverage` |
| Coverage threshold | per-file ≥70% on new parser files (per CLAUDE.md / REQUIREMENTS.md Cross-cutting Constraints) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VOICE-01 (anchor) | zh "2千2百零4元" → 2204 | unit (named `test()`) | `flutter test test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart -P 'anchor_zh_2204'` | ❌ Wave 0 |
| VOICE-01 (anchor) | ja「にせんにひゃくよん」→ 2204 | unit (named `test()`) | `flutter test test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart -P 'anchor_ja_2204'` | ❌ Wave 0 |
| VOICE-01 (anchor) | ja「一万二千」→ 12000 (regression guard) | unit (named `test()`) | `flutter test test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart -P 'anchor_ja_12000'` | ❌ Wave 0 |
| VOICE-02 (anchor) | zh "1千8百" + pause + "4十元" → 1840 | unit `fake_async` (named `test()`) | `flutter test test/unit/application/voice/voice_chunk_merger_test.dart -P 'anchor_zh_1840'` | ❌ Wave 0 |
| VOICE-02 (anchor) | ja「せんはっぴゃく」+ pause +「よんじゅう」→ 1840 | unit `fake_async` (named `test()`) | `flutter test test/unit/application/voice/voice_chunk_merger_test.dart -P 'anchor_ja_1840'` | ❌ Wave 0 |
| VOICE-02 (gate) | Buffer "1千8百" + chunk "现金" does NOT merge (commits 1800) | unit `fake_async` | same file | ❌ Wave 0 |
| VOICE-02 (timing) | Buffer "1千8百" + chunk "4十元" 3.0s later → no merge (commits 1800 then 40) | unit `fake_async` | same file | ❌ Wave 0 |
| VOICE-02 (user stop) | User-initiated stop commits buffer immediately | unit `fake_async` | same file | ❌ Wave 0 |
| VOICE-03 (zh corpus) | ≥95% accuracy on `voice_corpus_zh.dart` (~50 cases) with per-locale summary printed | unit corpus | `flutter test test/unit/infrastructure/voice/voice_number_parser_corpus_zh_test.dart` | ❌ Wave 0 |
| VOICE-03 (ja corpus) | ≥95% accuracy on `voice_corpus_ja.dart` (~50 cases) with per-locale summary printed | unit corpus | `flutter test test/unit/infrastructure/voice/voice_number_parser_corpus_ja_test.dart` | ❌ Wave 0 |
| VOICE-01/02 integration | `extractAmount(text, Locale('zh'))` routes to ChineseStateMachine; `extractAmount(text, Locale('ja'))` routes to JapaneseStateMachine | unit | `flutter test test/unit/application/voice/voice_text_parser_test.dart` (updated) | ⚠️ exists, needs update |
| Dictionary completeness | Every digit (0-9) × every reading from D-05 has a dict entry; every voicing variant (はっぴゃく, etc.) maps to correct PackedToken | unit | `flutter test test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` | ❌ Wave 0 |
| `restartListen()` API | `SpeechRecognitionService.restartListen()` exists, is callable, and guards against in-flight `listen()` (Pitfall 3) | unit (mock-based) | `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart` (updated) | ⚠️ exists, needs update |
| Voice screen integration | `_onResult` callback feeds merger; merchant/category/date paths still flow through `parseVoiceInputUseCase.execute` | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (likely needs creation/update) | ⚠️ uncertain — discover during plan |
| Phase gate | All quality gates pass | gate | `flutter analyze && dart run custom_lint --no-fatal-infos && flutter test --coverage` | — |

### Per-Component Validation Strategy

Each component below maps to a dedicated test file. This list scaffolds VALIDATION.md.

1. **ChineseNumeralStateMachine (Pattern 1 zh)** — unit test in `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart`. Coverage: anchor zh 2204; zh 1千8百 single-pass = 1800; bare-tail "三百零四" → 304; mixed-arabic "2百" → 200; empty input → null; non-numeric input → null; `万`-scale "三万五千" → 35000; "一万二千五百八十" → 12580.

2. **JapaneseNumeralStateMachine (Pattern 2 ja)** — unit test in `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart`. Coverage: anchor ja 2204 (hiragana); anchor ja 12000 (kanji); はっぴゃく → 800; ろっぴゃく → 600; さんびゃく → 300; いっせん → 1000; さんぜん → 3000; mixed reading さん + ご + よん combinations; mixed kanji+hiragana 三千 + ろっぴゃく → 3600; null on non-Japanese input.

3. **japaneseNumeralDictionary lexicon** — unit test in `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart`. Coverage: every D-05 reading present and maps to correct token; longest entry > shortest entry (sanity check the sort works); no duplicate keys; PackedToken inner lists have correct cardinality (exactly 2 tokens for digit+unit pairs).

4. **VoiceChunkMerger (Pattern 3)** — unit test with `fake_async` in `test/unit/application/voice/voice_chunk_merger_test.dart`. Coverage: 5 anchor cases above; lexical gate true-positive AND true-negative; time gate at boundary (2.499s merge ok, 2.501s no merge); user-stop commits; dispose cancels timer; restartListen() called exactly once per merge; non-numeric chunk after open buffer commits buffer and drops chunk.

5. **VoiceTextParser locale routing** — unit test in `test/unit/application/voice/voice_text_parser_test.dart` (updated). Coverage: `extractAmount('六百八十円', Locale('ja'))` routes to ja machine; `extractAmount('六百八十块', Locale('zh'))` routes to zh machine; Arabic-numeral path (`_extractArabicAmount`) takes precedence regardless of locale; existing Arabic / date / merchant tests remain passing.

6. **SpeechRecognitionService.restartListen()** — unit test in `test/unit/infrastructure/speech/speech_recognition_service_test.dart` (updated). Coverage: new method callable; guards in-flight state (calls cancel before listen if already listening); preserves locale/callbacks from last `startListening` invocation; surfaces errors from underlying `_speech.listen()`.

7. **Corpus accuracy reporters (VOICE-03)** — two separate test files, `voice_number_parser_corpus_zh_test.dart` and `voice_number_parser_corpus_ja_test.dart`. Each: iterates the fixture, runs `parser.parse(case.input)`, asserts per-case in a `test()` inside a `group()`, prints per-locale summary in `tearDownAll`, fails on aggregate < 95%.

8. **Voice screen integration (intra-pause anchor end-to-end)** — widget test in `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`. Coverage: simulate two `SpeechRecognitionResult(recognizedWords: "1千8百", finalResult: true)` and `("4十元", finalResult: true)` via the screen's `_onResult` injection; assert the resulting `_parseResult.amount` is 1840 (post-merge). This is the ONE widget test that validates the wiring; everything else stays unit-level.

### Sampling Rate
- **Per task commit:** `flutter test test/unit/infrastructure/voice/ test/unit/application/voice/voice_chunk_merger_test.dart` (~all new files, <5s expected)
- **Per wave merge:** `flutter test --coverage`
- **Phase gate:** Full suite green + `flutter analyze` 0 issues + `dart run custom_lint --no-fatal-infos` 0 errors + per-file coverage ≥70% on the 8 new/modified files before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/fixtures/voice_corpus_zh.dart` — covers VOICE-03 (zh per-locale ≥95%)
- [ ] `test/fixtures/voice_corpus_ja.dart` — covers VOICE-03 (ja per-locale ≥95%)
- [ ] `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` — covers VOICE-01 zh anchor + edge cases
- [ ] `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` — covers VOICE-01 ja anchors (including 12000 regression guard)
- [ ] `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` — covers D-05 / D-06 lexicon completeness
- [ ] `test/unit/infrastructure/voice/voice_number_parser_corpus_zh_test.dart` — covers VOICE-03 zh runner
- [ ] `test/unit/infrastructure/voice/voice_number_parser_corpus_ja_test.dart` — covers VOICE-03 ja runner
- [ ] `test/unit/application/voice/voice_chunk_merger_test.dart` — covers VOICE-02 (5 scenarios + dispose + restart)
- [ ] `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — covers screen-level integration (1 anchor case)
- [ ] Updates to: `test/unit/application/voice/voice_text_parser_test.dart` (retire `Kanji amount extraction` group; add `extractAmount(text, locale)` routing tests)
- [ ] Updates to: `test/unit/infrastructure/speech/speech_recognition_service_test.dart` (add `restartListen()` tests)

*Framework install: not needed — flutter_test, fake_async, mocktail all pinned.*

## Security Domain

> `security_enforcement` not explicitly configured; default treats as enabled. Phase 20 is NLP/parser work with no auth/session/access/crypto surface. Most ASVS categories N/A. Documented below for completeness.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a (no auth touched) |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | yes | State machine accepts arbitrary user voice text — must never throw on malformed input; return null. Verified in `parse('')`, `parse('abc')`, `parse('🎉')` tests |
| V6 Cryptography | no | n/a (no new crypto) |
| V8 Data Protection | partial | Voice text is sensitive (financial intent + spoken language). Already handled by `speech_to_text` on-device mode and existing `lib/infrastructure/speech/` config — Phase 20 doesn't change the audio pipeline. State machine processes already-recognized text in-memory only. No logging of `text` content via `debugPrint` or analytics. Confirmed by Pitfall 3 mitigation pattern. |
| V12 File Handling | no | n/a |
| V13 API and Web Service | no | n/a |

### Known Threat Patterns for {stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed input causing DoS (e.g., 10MB voice text from a misbehaving recognizer) | DoS | Set defensive max-length on `extractAmount` (e.g., reject text > 1000 chars). Recognizer can't realistically produce that, but defense-in-depth. |
| Sensitive text leaked via logs | Info Disclosure | NEVER `debugPrint(text)` or `print(buffer)` in production paths. Only print accuracy summary in test `tearDownAll`. CLAUDE.md "no console.log" rule applies (Dart `print`/`debugPrint` equivalent). |
| Locale-mismatched routing dropping amount silently | Tampering (data integrity) | Test: `extractAmount('六百', Locale('ja'))` and `extractAmount('六百', Locale('zh'))` both return 600 (kanji digits/units overlap). Test: `extractAmount('にひゃく', Locale('zh'))` returns null (zh machine rejects hiragana) — but Arabic fallback still triggers if digits present. |

## Sources

### Primary (HIGH confidence)
- `lib/application/voice/voice_text_parser.dart:29-140` — current parser implementation (section-accumulator pattern, kanji digit/unit tables) — directly informs Pattern 1 algorithm
- `lib/infrastructure/speech/speech_recognition_service.dart` — wrapper to be modified; `_speech.listen()` config and `pauseFor: 3s` confirmed
- `lib/application/family_sync/sync_engine.dart:86-92` — `dispose()` pattern precedent for merger
- `lib/application/family_sync/repository_providers.dart:76,110` — `ref.onDispose` provider pattern precedent
- `test/unit/application/family_sync/phase6_sync_coverage_test.dart:340-355` — `fake_async` timer test pattern precedent
- `test/infrastructure/sync/websocket_service_test.dart:350` — additional `fake_async` precedent
- `pubspec.yaml:17,41,89,90` — version pins verified (intl 0.20.2, speech_to_text ^7.0.0, fake_async ^1.3.3, mocktail ^1.0.4)
- `CLAUDE.md` Thin Feature rule, Riverpod 3 conventions, layer dependency rules — all directly cited

### Secondary (MEDIUM confidence)
- [speech_to_text pub.dev changelog](https://pub.dev/packages/speech_to_text/changelog) — finalResult timing on iOS, partialResults parameter, pauseFor ignored on Android
- [Sudachi Mode A documentation (referenced via Medium tokenizer article)](https://medium.com/data-science/how-japanese-tokenizers-work-87ab6b256984) — Japanese longest-match tokenization principle
- [focareg GitHub — Longest Match Principle](https://github.com/TomokiMatsuno/focareg) — longest-match for Japanese compounds
- [arxiv 2305.19045 — Feature-Sequence Trie for Japanese Morphological Analysis](https://arxiv.org/pdf/2305.19045) — trie-backed longest match scaling

### Tertiary (LOW confidence)
- [japanese-numbers-python on GitHub](https://github.com/takumakanari/japanese-numbers-python) — exists as a working parser proof but internal algorithm not visible from README
- General WebSearch on Chinese numeral parsing — surfaced patent and academic references but no canonical algorithm citation; the section-accumulator pattern used here is well-established and directly reuses the existing repo's working algorithm shape

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already pinned and used; speech_to_text 7.x behavior cross-verified via changelog
- Architecture (state machine algorithms): HIGH — Pattern 1 directly inherits from working legacy code; Pattern 2 uses canonical longest-match tokenization principle; both walked through all 5 anchor cases
- Architecture (merger): HIGH — D-09/D-10/D-11/D-12 lock the design; precedent classes (`SyncEngine`, `TransactionChangeTracker`) demonstrate the same shape works in this codebase
- Pitfalls: HIGH (1-3, repo + plugin verified), MEDIUM (4-5, defensive but real)
- Validation Architecture: HIGH — all test files mapped to specific REQ IDs; existing fake_async precedent reused

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 (30 days — stable infrastructure work, no fast-moving deps)
