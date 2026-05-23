# Phase 20: Voice Number Parser (zh + ja) - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 14 new + 5 modified
**Analogs found:** 19 / 19

---

## File Classification

### New files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/infrastructure/voice/numeral_state_machine.dart` | infrastructure (abstract base + sealed token taxonomy) | transform (string → tokens → int?) | `lib/application/family_sync/sync_orchestrator.dart` (sealed result types) + `lib/infrastructure/ml/merchant_database.dart` (stateless infra class) | role-match (composite) |
| `lib/infrastructure/voice/chinese_numeral_state_machine.dart` | infrastructure (concrete stateless parser) | transform | `lib/infrastructure/ml/merchant_database.dart` + existing `_extractKanjiAmount` in `lib/application/voice/voice_text_parser.dart:59-140` | exact (algorithm) + exact (placement) |
| `lib/infrastructure/voice/japanese_numeral_state_machine.dart` | infrastructure (concrete stateless parser) | transform | same as zh + longest-match tokenize pattern (no in-repo precedent; build per RESEARCH.md Pattern 2) | exact placement, novel algorithm |
| `lib/infrastructure/voice/japanese_numeral_dictionary.dart` | infrastructure (const data table) | data-only | `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart:8-12` (file-scope `const Map<String, X>`) + `lib/infrastructure/ml/merchant_database.dart:46-119` (const `List<_Entry>`) | exact (const Map shape) |
| `lib/application/voice/voice_chunk_merger.dart` | application (stateful orchestrator with Timer + dispose) | event-driven (chunk in, parse out on timer) | `lib/infrastructure/sync/sync_scheduler.dart` (Timer + debounce + dispose) + `lib/application/family_sync/sync_engine.dart` (stateful coordinator with dispose) | exact (Timer + dispose contract) |
| `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` | test (unit) | request-response | `test/unit/infrastructure/ml/merchant_database_test.dart` | exact |
| `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` | test (unit) | request-response | same | exact |
| `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` | test (lexicon completeness) | request-response | `test/unit/infrastructure/ml/merchant_database_test.dart` | exact |
| `test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart` | test (unit, tokenizer focus) | transform | `test/unit/application/voice/voice_text_parser_test.dart:11-61` (group-per-feature shape) | role-match |
| `test/unit/application/voice/voice_chunk_merger_test.dart` | test (unit, fake_async timer) | event-driven | `test/unit/application/family_sync/phase6_sync_coverage_test.dart:338-396` (`fakeAsync` + `async.elapse` + mock callback list) | exact |
| `test/integration/voice/voice_corpus_zh_test.dart` | test (statistical corpus + anchor cases) | batch | `test/unit/application/voice/voice_text_parser_test.dart:45-61` (per-anchor `test()`) — no in-repo aggregate-reporter precedent (build per RESEARCH.md §Validation Architecture) | partial (anchor pattern exists; reporter is novel) |
| `test/integration/voice/voice_corpus_ja_test.dart` | test (statistical corpus + anchor cases) | batch | same | partial |
| `test/fixtures/voice_corpus_zh.dart` | test fixture (Dart-literal records) | data-only | `test/helpers/happiness_test_fixtures.dart` (Dart-literal fixtures library; the only precedent — no `test/fixtures/` dir exists yet, create it) | role-match |
| `test/fixtures/voice_corpus_ja.dart` | test fixture | data-only | same | role-match |

### Modified files

| Modified File | Role | Current Entry Points | Closest "same-shape" change in repo |
|---|---|---|---|
| `lib/application/voice/voice_text_parser.dart` | application (will become thin transfer station) | `extractAmount(String)` lines 16-26 (Arabic + Kanji branches); `_extractKanjiAmount` lines 59-140 (to delete) | n/a — surgical inline refactor |
| `lib/application/voice/parse_voice_input_use_case.dart` | application use case | `execute(String recognizedText)` lines 30-84; constructor lines 19-25 (injects `_textParser`, `_fuzzyCategoryMatcher`, `_merchantDatabase`) | n/a — additive constructor parameter |
| `lib/infrastructure/speech/speech_recognition_service.dart` | infrastructure (plugin wrapper) | `startListening({...})` lines 33-58; `stopListening()` lines 60-63; `cancelListening()` lines 65-68; `isListening` getter line 76 | Mirror the shape of `startListening` (lines 33-58) for the new `restartListen()` |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | presentation | `_onResult(SpeechRecognitionResult)` lines 210-241; nav-to-`ManualOneStepScreen` lines 351-367 (reads `result.amount`) | n/a — handler rewire |
| `test/unit/application/voice/voice_text_parser_test.dart` | test | Kanji group lines 45-61 (4 tests) | n/a — delete & relocate to new state-machine tests |
| `lib/application/voice/repository_providers.dart` | application (Riverpod wiring) | lines 1-23 — already has `appSpeechRecognitionServiceProvider` (line 13) + `startSpeechRecognitionUseCaseProvider` (line 19) | Mirror the `@riverpod` annotation shape (lines 12-15) for the new `voiceChunkMergerProvider`; mirror `ref.onDispose(service.dispose)` from `lib/application/family_sync/repository_providers.dart:76,110` |

---

## Pattern Assignments

### `lib/infrastructure/voice/numeral_state_machine.dart` (abstract base + sealed `NumeralToken`)

**Analog A:** `lib/application/family_sync/sync_orchestrator.dart` — sealed result class taxonomy.

**Sealed-class taxonomy shape** (`sync_orchestrator.dart:19-37`):
```dart
sealed class SyncOrchestratorResult {
  const SyncOrchestratorResult();
}

class SyncOrchestratorSuccess extends SyncOrchestratorResult {
  const SyncOrchestratorSuccess({this.appliedCount = 0, this.pushedCount = 0});
  final int appliedCount;
  final int pushedCount;
}

class SyncOrchestratorNoGroup extends SyncOrchestratorResult {
  const SyncOrchestratorNoGroup();
}

class SyncOrchestratorError extends SyncOrchestratorResult {
  const SyncOrchestratorError(this.message);
  final String message;
}
```

Apply to `NumeralToken` (per RESEARCH.md §Code Examples lines 562-595): `sealed class NumeralToken { const NumeralToken(); }` → concrete `Digit(int value)`, `Unit(int power)`, `ZeroPlaceholder()`, `Skip()`, `PackedToken(List<NumeralToken> inner)`. All `const` constructors, all final fields — identical pattern.

**Analog B:** `lib/infrastructure/ml/merchant_database.dart` — stateless infra class with public lookup.

**Class header + doc-comment shape** (`merchant_database.dart:38-46`):
```dart
/// Merchant lookup database.
///
/// Provides fuzzy merchant matching for voice and OCR modules.
/// This is shared merchant lookup used by OCR and voice-input classification.
class MerchantDatabase {
  static const List<_MerchantEntry> _entries = [ ... ];
```

Apply to the abstract base: doc-comment explaining "voice numeral parsing component shared by zh/ja state machines per Thin Feature rule," followed by `abstract class NumeralStateMachine { const NumeralStateMachine(); int? parse(String text); List<NumeralToken> normalize(String text); @protected int? scan(List<NumeralToken> tokens) {...} }` (full scan body in RESEARCH.md lines 613-650).

---

### `lib/infrastructure/voice/chinese_numeral_state_machine.dart` (concrete, stateless)

**Analog A:** existing `_extractKanjiAmount` (`lib/application/voice/voice_text_parser.dart:59-140`) — the algorithm being lifted to infrastructure and rebuilt.

**Section-accumulator core to copy** (lines 104-137):
```dart
var result = 0;
var currentSection = 0;
var currentDigit = 1;

for (var i = 0; i < kanjiText.length; i++) {
  final char = kanjiText[i];
  if (kanjiDigits.containsKey(char)) {
    currentDigit = kanjiDigits[char]!;
  } else if (kanjiUnits.containsKey(char)) {
    final unit = kanjiUnits[char]!;
    if (unit == 10000) {
      final sectionValue = currentSection == 0 ? currentDigit : currentSection + currentDigit;
      result += sectionValue * 10000;
      currentSection = 0;
      currentDigit = 1;
    } else {
      currentSection += currentDigit * unit;
      currentDigit = 1;
    }
  }
}

final lastChar = kanjiText[kanjiText.length - 1];
if (!kanjiUnits.containsKey(lastChar) && currentDigit < 10) {
  currentSection += currentDigit;
}
result += currentSection;
return result > 0 ? result : null;
```

**What transfers:** `currentSection` / `currentDigit` / `result` accumulator semantics; `Unit(10000)` flush-and-reset; bare-tail handling. **What changes per RESEARCH.md Pattern 1 (lines 230-303):** (1) operate on `List<NumeralToken>` (not raw chars), (2) explicit `ZeroPlaceholder` case (existing code's `'零':0` silently overwrites `currentDigit` — new code makes it intentional), (3) `digit == 0 ? 1 : digit` instead of `currentSection == 0 ? currentDigit : section + currentDigit` (eliminates the legacy double-counting branch on `currentSection == 0`), (4) seed `digit = 0` not `1` (the `1` was a fallback for `千` without preceding digit; new code uses `digit == 0 ? 1 : digit` at the Unit case).

**Analog B:** `lib/infrastructure/ml/merchant_database.dart` for class placement + doc shape.

**Imports pattern (copy this style):** `merchant_database.dart:1` uses relative `import '../../features/...';` — same style applies to new file: relative imports to `numeral_state_machine.dart`.

---

### `lib/infrastructure/voice/japanese_numeral_state_machine.dart` (concrete, stateless, longest-match)

**Analog:** Same as zh state machine for the scanner half. For tokenizer half, no in-repo precedent — algorithm comes from RESEARCH.md Pattern 2 (lines 313-360).

**Pre-sorted-keys pattern (algorithm-only, build per research):**
```dart
static final _sortedKeys = japaneseNumeralDictionary.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

@override
List<NumeralToken> normalize(String text) {
  final tokens = <NumeralToken>[];
  var i = 0;
  while (i < text.length) {
    NumeralToken? matched;
    int? matchLen;
    for (final key in _sortedKeys) {
      if (i + key.length > text.length) continue;
      if (text.substring(i, i + key.length) == key) {
        matched = japaneseNumeralDictionary[key]!;
        matchLen = key.length;
        break;
      }
    }
    // ... arabic / kanji-single-char fallback
    if (matched is! Skip) tokens.add(matched!);
    i += matchLen!;
  }
  return tokens;
}
```

Class shape (constructor, `int? parse(...)` delegating to inherited `scan`) mirrors `MerchantDatabase` (`lib/infrastructure/ml/merchant_database.dart:45-46, 125-161`).

---

### `lib/infrastructure/voice/japanese_numeral_dictionary.dart` (const data table)

**Analog A:** `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart:8-12` — file-scope private const `Map<String, X>`.

**Shape to copy** (verbatim):
```dart
// D-20 names this map _PTVF_BASE_BY_CURRENCY; Dart style requires lower camel.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};
```

Apply: top-level `const Map<String, NumeralToken> japaneseNumeralDictionary = { ... };` (public, not `_`-prefixed, because the state machine in a separate file consumes it — but private is also valid if dictionary is moved into the same file later). Per D-06, separate file. Include the ~30 entries enumerated in RESEARCH.md lines 365-391.

**Analog B:** `lib/infrastructure/ml/merchant_database.dart:46-119` — static const list of entries with sibling private `_MerchantEntry` helper class. Use **only** if dictionary entries grow categorical metadata; for now, flat `Map<String, NumeralToken>` per joy formatter is simpler.

---

### `lib/application/voice/voice_chunk_merger.dart` (stateful, Timer + dispose)

**Analog A:** `lib/infrastructure/sync/sync_scheduler.dart` — Timer-driven stateful class with debounce + `dispose()` that cancels timers and clears state.

**Constructor + injected callbacks shape** (`sync_scheduler.dart:17-26`):
```dart
typedef SyncRequestCallback = Future<void> Function(SyncMode mode);

class SyncScheduler {
  SyncScheduler({
    required SyncRequestCallback onSyncRequested,
    required NeedsFullPullCallback checkNeedsFullPull,
  }) : _onSyncRequested = onSyncRequested,
       _checkNeedsFullPull = checkNeedsFullPull;

  final SyncRequestCallback _onSyncRequested;
  final NeedsFullPullCallback _checkNeedsFullPull;
```

Apply to `VoiceChunkMerger`:
```dart
typedef AmountResolvedCallback = void Function(int amount);

class VoiceChunkMerger {
  VoiceChunkMerger({
    required NumeralStateMachine parser,
    required SpeechRecognitionService speechService,
    required AmountResolvedCallback onAmountResolved,
  }) : _parser = parser, _speechService = speechService, _onAmountResolved = onAmountResolved;

  final NumeralStateMachine _parser;
  final SpeechRecognitionService _speechService;
  final AmountResolvedCallback _onAmountResolved;
```

**Timer + debounce pattern** (`sync_scheduler.dart:27-41`):
```dart
Timer? _debounceTimer;
Timer? _pollingTimer;
// ...
static const _debounceDuration = Duration(seconds: 10);

void onTransactionChanged() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(_debounceDuration, () {
    _enqueueSync(SyncMode.incrementalPush);
  });
}
```

Apply:
```dart
Timer? _windowTimer;
String _buffer = '';
DateTime? _lastFinalAt;
static const _windowDuration = Duration(milliseconds: 2500);

void feedChunk(String text, {required bool isFinal}) {
  if (!isFinal) return;          // partials don't drive merger
  if (_buffer.isEmpty || _shouldMerge(text)) {
    _buffer = _buffer.isEmpty ? text : _buffer + text;
    _lastFinalAt = DateTime.now();
    _restartTimer();
    _speechService.restartListen(...);
  } else {
    _commitAndReset();
    // optionally start fresh buffer with new chunk if numeric-leading
  }
}
```

**Dispose pattern** (`sync_scheduler.dart:82-88`):
```dart
void dispose() {
  _debounceTimer?.cancel();
  _pollingTimer?.cancel();
  _debounceTimer = null;
  _pollingTimer = null;
  _pendingModes.clear();
}
```

Apply identically:
```dart
void dispose() {
  _windowTimer?.cancel();
  _windowTimer = null;
  _buffer = '';
  _lastFinalAt = null;
}
```

**Analog B:** `lib/application/family_sync/sync_engine.dart:86-92` — `void dispose()` pattern coordinating multiple child resources (precedent that merger may also need to stop the speech service if it created/owns it; per CONTEXT.md D-09 merger does NOT own the recognizer — it just calls `restartListen()`).

---

### `lib/infrastructure/speech/speech_recognition_service.dart` (modification — add `restartListen`)

**Current methods to mirror** (lines 33-68):
```dart
Future<void> startListening({
  required void Function(SpeechRecognitionResult result) onResult,
  required void Function(double normalizedLevel) onSoundLevel,
  required String localeId,
  Duration listenFor = const Duration(seconds: 30),
  Duration pauseFor = const Duration(seconds: 3),
}) async {
  if (!_isInitialized) return;
  await _speech.listen( ... );
}

Future<void> stopListening() async { await _speech.stop(); }
Future<void> cancelListening() async { await _speech.cancel(); }
```

**Minimal diff shape:** add new method between `startListening` and `stopListening`. Two implementation choices (per CONTEXT.md D-12, both work):

Option A — cached config + new public method (RESEARCH.md recommends this — line 17, 108-110):
```dart
// Inside class — add state to cache last config
({void Function(SpeechRecognitionResult)? onResult,
  void Function(double)? onSoundLevel,
  String? localeId,
  Duration? listenFor,
  Duration? pauseFor})? _lastConfig;

// Inside startListening, after _isInitialized check, cache the args before calling _speech.listen.

/// Restart listening with the most recently used [startListening] configuration.
Future<void> restartListen() async {
  final cfg = _lastConfig;
  if (cfg == null || !_isInitialized) return;
  if (_speech.isListening) {
    await _speech.cancel();
  }
  await startListening(
    onResult: cfg.onResult!,
    onSoundLevel: cfg.onSoundLevel!,
    localeId: cfg.localeId!,
    listenFor: cfg.listenFor!,
    pauseFor: cfg.pauseFor!,
  );
}
```

Option B — merger holds the config and re-calls `startListening` itself. Both compile; A is cleaner test seam.

**Pitfall 3 mitigation** (per RESEARCH.md lines 540-544): the `cancel()` before re-`listen()` and the `isListening` check are mandatory.

---

### `lib/application/voice/voice_text_parser.dart` (modification — `extractAmount` becomes locale-routing transfer station)

**Current entry point** (lines 16-26):
```dart
int? extractAmount(String text) {
  final arabicAmount = _extractArabicAmount(text);
  if (arabicAmount != null) return arabicAmount;

  final kanjiAmount = _extractKanjiAmount(text);
  if (kanjiAmount != null) return kanjiAmount;

  return null;
}
```

**Minimal diff shape per D-04 + CONTEXT.md "Claude's Discretion" (locale via parameter, recommended by RESEARCH.md line 17, 109):**

```dart
// Constructor change — inject both state machines (mirror ParseVoiceInputUseCase
// constructor shape, parse_voice_input_use_case.dart:19-25)
final ChineseNumeralStateMachine _zhMachine;
final JapaneseNumeralStateMachine _jaMachine;
VoiceTextParser({
  ChineseNumeralStateMachine? zhMachine,
  JapaneseNumeralStateMachine? jaMachine,
}) : _zhMachine = zhMachine ?? const ChineseNumeralStateMachine(),
     _jaMachine = jaMachine ?? const JapaneseNumeralStateMachine();

int? extractAmount(String text, {String? localeId}) {
  final arabicAmount = _extractArabicAmount(text);
  if (arabicAmount != null) return arabicAmount;

  // Route to state machine by locale code prefix (matches voice_locale_helpers.dart conventions)
  if (localeId != null && localeId.startsWith('ja')) {
    return _jaMachine.parse(text);
  }
  if (localeId != null && localeId.startsWith('zh')) {
    return _zhMachine.parse(text);
  }
  // Fallback: try both (or null) — planner picks. Safer to try ja then zh
  // since both are kanji-tolerant.
  return _jaMachine.parse(text) ?? _zhMachine.parse(text);
}
```

**Delete:** `_extractKanjiAmount` (lines 59-140) entirely. Delete the `kanjiDigits` + `kanjiUnits` const Maps (lines 60-88).

**Keep unchanged:** `_extractArabicAmount` (lines 29-54), `extractDate` (lines 148+), `extractAndMatchMerchant` (lines 463+), `_extractPotentialMerchantNames` (lines 478+).

---

### `lib/application/voice/parse_voice_input_use_case.dart` (modification — wire merger between recognizer and `extractAmount`)

**Current shape** (lines 14-30):
```dart
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _fuzzyCategoryMatcher = fuzzyCategoryMatcher,
       _merchantDatabase = merchantDatabase;

  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      final amount = _textParser.extractAmount(recognizedText);
      // ... date / merchant / category / ledger ...
```

**Minimal diff shape (per D-04 + D-09 + Claude's-discretion locale-as-parameter):**

The use case stays **stateless** (CONTEXT.md D-09: "must stay stateless"). Add `localeId` parameter to `execute`:

```dart
Future<Result<VoiceParseResult>> execute(
  String recognizedText, {
  String? localeId,
}) async {
  try {
    final amount = _textParser.extractAmount(recognizedText, localeId: localeId);
    // ... rest unchanged
```

The **merger** itself is NOT injected into this use case. Per CONTEXT.md `<code_context>` line 130: merger is wired at the screen (`voice_input_screen.dart`); merger calls `_parser.parse(...)` directly when its window closes, then notifies via `onAmountResolved` callback. The use case continues to handle merchant/category/date paths through per-partial calls — only the amount path is gated through the merger.

**No constructor change required** unless the planner wants to inject `VoiceChunkMerger` here for symmetry (NOT recommended — keep merger ownership at the screen).

---

### `lib/features/accounting/presentation/screens/voice_input_screen.dart` (modification — `_onResult` feeds merger; navigate reads merger commit)

**Current `_onResult`** (lines 210-241): partial → 300ms debounce → `_parseVoiceInput(text)`; final → `_parseFinalResult(text)`.

**Current `_parseDebounce` declaration** (line 76): `Timer? _parseDebounce;`

**Current navigate site** (lines 351-367): reads `result.amount` from `_parseResult` (VoiceParseResult).

**Minimal diff shape:**

1. **Add state field** (next to `_parseDebounce` at line 76):
   ```dart
   VoiceChunkMerger? _amountMerger;
   int? _mergedAmount;  // updated by merger callback
   ```

2. **Initialize merger** in `_startRecording` (after line 175, before `_speechService.startListening`):
   ```dart
   _amountMerger = VoiceChunkMerger(
     parser: localeId.startsWith('ja') ? jaMachine : zhMachine,
     speechService: ref.read(appSpeechRecognitionServiceProvider),
     onAmountResolved: (amount) {
       if (mounted) setState(() => _mergedAmount = amount);
     },
   );
   ```

3. **Rewire final branch in `_onResult`** (lines 226-240):
   ```dart
   } else {
     final text = result.recognizedWords;
     setState(() {
       _finalText = text;
       _partialText = '';
       _soundLevel = 0.0;
     });
     _parseDebounce?.cancel();
     if (text.isNotEmpty) {
       _amountMerger?.feedChunk(text, isFinal: true);  // amount path: merger
       _parseFinalResult(text);                         // merchant/category/date path: unchanged
     }
   }
   ```
   Note: `_isRecording = false` MUST be removed from this branch — merger drives continued-listening, so the screen stays "recording" until user toggles off OR merger's window closes.

4. **Dispose merger** in `_stopRecording` (after line 185) + in `dispose()` (find existing override at file scope):
   ```dart
   await _amountMerger?.dispose();
   _amountMerger = null;
   ```

5. **Navigate site** (line 355): change `initialAmount: result.amount ?? 0` → `initialAmount: _mergedAmount ?? result.amount ?? 0` (merger's commit wins; falls back to per-partial parse for users who tap nav before window closes).

**Unchanged paths:** `_parseVoiceInput` (partials → merchant/category/date), `_resolveCategory`, `_buildAudioFeatures`, sound-level instrumentation.

---

### `test/unit/application/voice/voice_text_parser_test.dart` (modification — retire kanji group)

**Current kanji group** (lines 45-61) — 4 `test()` blocks: `六百八十円→680`, `千二百円→1200`, `三千九百八十→3980`, `一千二百元→1200`.

**Minimal diff:** delete lines 45-61 entirely. Move equivalent coverage to:
- `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` (ja-specific cases: `六百八十`, `千二百`, `三千九百八十`, `一万二千` regression)
- `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` (zh-specific: `一千二百`, `2千2百零4`, `1千8百4十`)
- Anchor cases also encoded in corpus fixtures (`test/fixtures/voice_corpus_{zh,ja}.dart`) and asserted from the corpus tests as strict named `test()` blocks.

The Arabic group (lines 11-43) and date/merchant groups (lines 63+) stay unchanged.

---

### `lib/application/voice/repository_providers.dart` (modification — add `voiceChunkMergerProvider`)

**Current shape** (lines 1-24, 2 providers): `appSpeechRecognitionServiceProvider` (line 13), `startSpeechRecognitionUseCaseProvider` (line 19).

**Note:** `parseVoiceInputUseCaseProvider` (referenced from voice_input_screen.dart:245) lives in a **different** `repository_providers.dart` — `lib/features/accounting/presentation/providers/repository_providers.dart` per the import on voice_input_screen.dart:20. The CONTEXT.md mentions adding `voiceChunkMergerProvider` to `lib/application/voice/repository_providers.dart` (RESEARCH.md line 206) — that's the correct application-layer home.

**Minimal diff:** append after line 23.

**Pattern to copy A (provider definition)** — `appSpeechRecognitionService` (lines 12-15):
```dart
@riverpod
SpeechRecognitionService appSpeechRecognitionService(Ref ref) {
  return SpeechRecognitionService();
}
```

**Pattern to copy B (provider with `ref.onDispose`)** — `lib/application/family_sync/repository_providers.dart:107-112`:
```dart
@riverpod
WebSocketService appWebSocketService(Ref ref) {
  final service = WebSocketService(baseUrl: RelayApiClient.wsBaseUrl);
  ref.onDispose(service.dispose);
  return service;
}
```

Apply:
```dart
/// Voice number state machines — stateless infrastructure singletons.
@riverpod
ChineseNumeralStateMachine chineseNumeralStateMachine(Ref ref) =>
    const ChineseNumeralStateMachine();

@riverpod
JapaneseNumeralStateMachine japaneseNumeralStateMachine(Ref ref) =>
    const JapaneseNumeralStateMachine();

/// Voice chunk merger — stateful, single-instance-per-recording-session.
/// Disposes its timer when provider is invalidated.
///
/// NOTE: Per CONTEXT.md D-09, the merger is owned by the voice screen, not
/// shared across screens. This provider exists for test-seam injection only;
/// production code constructs the merger directly in _startRecording (see
/// voice_input_screen.dart) so locale + callback can be bound per-session.
```

If the planner picks the provider route (per RESEARCH.md line 17 — "Riverpod-provided singleton with disposal hooks"), the shape is:
```dart
@riverpod
VoiceChunkMerger voiceChunkMerger(Ref ref) {
  final merger = VoiceChunkMerger( ... );
  ref.onDispose(merger.dispose);
  return merger;
}
```

**Codegen reminder:** must run `flutter pub run build_runner build --delete-conflicting-outputs` after edit; `repository_providers.g.dart` will gain new provider classes (mirror lines 16-49 of existing g.dart).

---

### `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` (new)

**Analog:** `test/unit/infrastructure/ml/merchant_database_test.dart` (the closest infrastructure unit-test in the same depth).

**Imports + setUp pattern** (`merchant_database_test.dart:1-11`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';

void main() {
  group('MerchantDatabase', () {
    late MerchantDatabase database;
    setUp(() {
      database = MerchantDatabase();
    });
```

Apply (verbatim shape, swap names):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/voice/chinese_numeral_state_machine.dart';

void main() {
  group('ChineseNumeralStateMachine', () {
    late ChineseNumeralStateMachine machine;
    setUp(() {
      machine = const ChineseNumeralStateMachine();
    });

    test('parses 2千2百零4元 -> 2204 (零-placeholder anchor)', () {
      expect(machine.parse('2千2百零4元'), 2204);
    });
    test('parses 1千8百4十元 -> 1840 (single-pass complete)', () {
      expect(machine.parse('1千8百4十元'), 1840);
    });
    // ... + null / empty / non-numeric cases
  });
}
```

---

### `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` (new)

**Analog:** same `merchant_database_test.dart` shape. Anchor cases per CONTEXT.md `<specifics>` lines 143-146:
- `parser.parse('にせんにひゃくよん')` → 2204
- `parser.parse('せんはっぴゃくよんじゅう')` → 1840 (the merged-buffer scenario; merger test covers the actual merge step)
- `parser.parse('一万二千')` → 12000 (regression guard)
- Per Pitfall 2 (RESEARCH.md lines 534-538): assert both `なな` and `しち` readings for 7 (`しちひゃく → 700`, `ななひゃく → 700`).

---

### `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` (new — lexicon completeness)

**Analog:** `merchant_database_test.dart` for the test-shape, but more declarative — iterate over expected (key, token) pairs.

**Pattern:** a single `group()` with one `test()` per category (digits, units, voicing variants), each iterating over a `const Map<String, NumeralToken>` of expected entries and asserting `japaneseNumeralDictionary[key] == expected`. Catches accidental dictionary deletions.

---

### `test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart` (new — tokenizer focus)

**Analog:** `test/unit/application/voice/voice_text_parser_test.dart:11-43` — group-per-feature with multiple `test()` blocks covering one concrete behavior each.

**Apply:** two `group()`s (zh normalize, ja normalize); each test compares `machine.normalize(input)` against expected `List<NumeralToken>`. Critical case per RESEARCH.md Anti-Pattern (line 501): `normalize('はっぴゃく')` MUST equal `[Digit(8), Unit(100)]` (or `[PackedToken([Digit(8), Unit(100)])]` if PackedToken stays in the token stream), NOT `[]` or partial-match noise.

---

### `test/unit/application/voice/voice_chunk_merger_test.dart` (new — fake_async timer)

**Analog:** `test/unit/application/family_sync/phase6_sync_coverage_test.dart:338-396` — `fakeAsync` + `async.elapse` + per-mode callback list verification.

**Shape to copy** (lines 357-375 verbatim):
```dart
test('pause flushes pending transaction debounce', () {
  fakeAsync((async) {
    final requests = <SyncMode>[];
    final scheduler = SyncScheduler(
      onSyncRequested: (mode) async {
        requests.add(mode);
      },
      checkNeedsFullPull: () async => false,
    );

    scheduler.onTransactionChanged();
    async.elapse(const Duration(seconds: 5));
    scheduler.onAppPaused();
    async.flushMicrotasks();

    expect(requests, [SyncMode.incrementalPush]);
    scheduler.dispose();
  });
});
```

Apply (the anchor zh "1千8百" + "4十元" → 1840 case):
```dart
test('merges intra-pause chunks via double-gate within 2.5s window', () {
  fakeAsync((async) {
    final commits = <int>[];
    final mockSpeech = MockSpeechRecognitionService();
    when(() => mockSpeech.restartListen()).thenAnswer((_) async {});
    final merger = VoiceChunkMerger(
      parser: const ChineseNumeralStateMachine(),
      speechService: mockSpeech,
      onAmountResolved: commits.add,
    );

    merger.feedChunk('1千8百', isFinal: true);
    async.elapse(const Duration(milliseconds: 1200));
    merger.feedChunk('4十元', isFinal: true);
    async.elapse(const Duration(milliseconds: 2500));
    async.flushMicrotasks();

    expect(commits, [1840]);
    verify(() => mockSpeech.restartListen()).called(2);
    merger.dispose();
  });
});
```

Also use mocktail per `test/infrastructure/sync/websocket_service_test.dart:12-14` (`class MockX extends Mock implements X {}`) and `parse_voice_input_use_case_test.dart:10-12` precedents — exactly the right mock-class shape.

---

### `test/integration/voice/voice_corpus_zh_test.dart` and `voice_corpus_ja_test.dart` (new)

**Analog A (anchor pattern):** `voice_text_parser_test.dart:45-61` — one named `test()` per anchor case.

**Analog B (statistical bucket):** no in-repo precedent. Per CONTEXT.md `<decisions>` (lines 73-76) and RESEARCH.md §Validation Architecture:
- 5 anchor cases as strict `test()` blocks at top.
- Remaining ~45 cases driven through one `group('statistical accuracy')` with a `for (final case in voiceCorpusZh) test(case.input, () { expect(machine.parse(case.input), case.expected, reason: 'input="${case.input}" expected=${case.expected}'); })` loop.
- Aggregate accuracy printed at end via `tearDownAll` (build per research — no existing precedent in repo for this exact reporter, but `tearDownAll` is a standard flutter_test hook).
- Suite fails if accuracy < 95% — add `tearDownAll` body that does `expect(passCount / total, greaterThanOrEqualTo(0.95))`.

**Why `test/integration/` not `test/unit/`:** per CONTEXT.md & RESEARCH.md §recommended-project-structure (line 217-227), these are statistical/accuracy corpora; conventionally that's integration-grade even though the implementation is pure. Note RESEARCH.md actually places them at `test/unit/infrastructure/voice/voice_number_parser_corpus_{zh,ja}_test.dart` — planner picks (current Phase 20 layout supports either; `test/integration/voice/` is the location named in the files_to_map prompt).

---

### `test/fixtures/voice_corpus_zh.dart` and `voice_corpus_ja.dart` (new)

**Analog:** `test/helpers/happiness_test_fixtures.dart` — Dart-literal test fixtures library (the only repo precedent for fixtures-as-library).

**Library header shape** (`happiness_test_fixtures.dart:1-18`):
```dart
/// Shared test fixtures for Phase 10 (HomeHeroCard) tests.
///
/// Used by:
///   - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
///
/// Conventions:
///   - All factories are pure (no IO, no DateTime.now())
///   - `const` constructors used wherever possible.
library;
```

Apply:
```dart
/// Voice number corpus for zh state machine (Phase 20 / VOICE-03).
///
/// ~50 cases covering digit ranges, intra-pause variants, currency-suffix variants,
/// and 零-placeholder cases. Anchor cases are also asserted individually in
/// test/integration/voice/voice_corpus_zh_test.dart.
///
/// Used by:
///   - test/integration/voice/voice_corpus_zh_test.dart
library;

/// One corpus entry. Use Dart 3 records for IDE-navigable inline literals.
typedef VoiceCorpusCase = ({String input, int expected, String? note});

const List<VoiceCorpusCase> voiceCorpusZh = [
  (input: '六百八十块',    expected: 680,  note: 'baseline'),
  (input: '2千2百零4元',   expected: 2204, note: 'anchor: 零-placeholder'),
  (input: '1千8百4十元',   expected: 1840, note: 'anchor: single-pass'),
  // ... ~45 more
];
```

**Conventions to mirror** from `happiness_test_fixtures.dart`: pure (no IO), `const` everywhere, descriptive `note` field for inspectable failures.

**Note:** `test/fixtures/` directory does not yet exist — first file in this phase creates the directory. Use `library;` directive per repo convention.

---

## Shared Patterns

### Pattern: Constructor with named-required dependencies + private final fields

**Source:** `lib/application/voice/parse_voice_input_use_case.dart:14-25`
**Apply to:** `VoiceChunkMerger`, modified `VoiceTextParser` constructor

```dart
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _fuzzyCategoryMatcher = fuzzyCategoryMatcher,
       _merchantDatabase = merchantDatabase;
```

### Pattern: Mocktail for service test doubles

**Source:** `test/unit/application/voice/parse_voice_input_use_case_test.dart:10-12`
**Apply to:** `voice_chunk_merger_test.dart` (mock `SpeechRecognitionService`)

```dart
import 'package:mocktail/mocktail.dart';
class _MockFuzzyCategoryMatcher extends Mock implements FuzzyCategoryMatcher {}
class _MockMerchantDatabase extends Mock implements MerchantDatabase {}
```

### Pattern: `@riverpod` annotation + `ref.onDispose` for stateful services

**Source:** `lib/application/family_sync/repository_providers.dart:107-112`
**Apply to:** new `voiceChunkMergerProvider` (if the planner chooses provider route) in `lib/application/voice/repository_providers.dart`

```dart
@riverpod
WebSocketService appWebSocketService(Ref ref) {
  final service = WebSocketService(baseUrl: RelayApiClient.wsBaseUrl);
  ref.onDispose(service.dispose);
  return service;
}
```

### Pattern: Sealed result/token taxonomy

**Source:** `lib/application/family_sync/sync_orchestrator.dart:19-37`
**Apply to:** `NumeralToken` sealed hierarchy (`numeral_state_machine.dart`)

```dart
sealed class SyncOrchestratorResult { const SyncOrchestratorResult(); }
class SyncOrchestratorSuccess extends SyncOrchestratorResult { ... }
class SyncOrchestratorNoGroup extends SyncOrchestratorResult { ... }
class SyncOrchestratorError extends SyncOrchestratorResult { ... }
```

### Pattern: Timer + dispose for stateful application coordinator

**Source:** `lib/infrastructure/sync/sync_scheduler.dart:17-88`
**Apply to:** `VoiceChunkMerger` (Timer-driven window + dispose contract)

Cancel timer in `dispose()`, set to null, clear collections — exact shape.

### Pattern: file-scope `const Map<String, X>` data table

**Source:** `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart:8-12`
**Apply to:** `japanese_numeral_dictionary.dart`

Top-level `const Map<String, NumeralToken>`, lookup via `[key]` with `??` fallback. No initializer, no class wrapper.

### Pattern: `fakeAsync` + `async.elapse` + callback-list verify

**Source:** `test/unit/application/family_sync/phase6_sync_coverage_test.dart:338-396` (and `test/infrastructure/sync/websocket_service_test.dart:1-9` for imports)
**Apply to:** `voice_chunk_merger_test.dart` (window-timer + merge cases)

```dart
import 'package:fake_async/fake_async.dart';
// ...
fakeAsync((async) {
  // arrange callback collector list
  // act: feedChunk(...) + async.elapse(...)
  // assert: callback list matches expected
  // tearDown: instance.dispose();
});
```

### Pattern: `library;` directive + doc header for test fixtures

**Source:** `test/helpers/happiness_test_fixtures.dart:1-18`
**Apply to:** `test/fixtures/voice_corpus_zh.dart` and `voice_corpus_ja.dart`

Triple-slash library doc comment with `Used by:` list and `Conventions:` block, then `library;` directive, then `const` data.

---

## No Analog Found

| File | Role | Reason / Plan |
|---|---|---|
| `test/integration/voice/voice_corpus_*_test.dart` (aggregate-accuracy reporter) | test | No in-repo test prints aggregate stats in `tearDownAll`. Build the reporter per RESEARCH.md §Validation Architecture: maintain `passCount` / `total` counters in test-scope vars, in each iteration `try { expect(...); passCount++; } catch(_) { /* let expect throw */ }` — or use `await tester.runAsync` patterns. The simplest precedent-compatible shape is a `for (final case in corpus)` loop with one `test()` per case + a final `test('accuracy ≥95%')` that calls `expect(passCount / total, greaterThanOrEqualTo(0.95))`. |
| `lib/infrastructure/voice/japanese_numeral_state_machine.dart` (longest-match tokenizer) | infrastructure | No in-repo longest-match tokenizer. Build per RESEARCH.md Pattern 2 (lines 313-360): pre-sort dictionary keys by descending length at class-static init time, greedy scan. |
| `test/fixtures/` directory | test infra | Does not yet exist. First file in this phase creates the directory. The closest existing convention is `test/helpers/` (where `happiness_test_fixtures.dart` lives); the new `test/fixtures/` placement is per CONTEXT.md & RESEARCH.md recommended-project-structure. |

---

## Metadata

**Analog search scope:**
- `lib/infrastructure/` (ml, speech, sync, i18n) — stateless infra + Timer-based services
- `lib/application/` (voice, family_sync, dual_ledger) — use cases + stateful coordinators
- `test/unit/` (application/voice, application/family_sync, infrastructure/ml) — fakeAsync + mocktail patterns
- `test/helpers/` — fixture libraries
- `test/infrastructure/sync/` — websocket-service-style mocking patterns

**Files scanned (Read-tool):** 13 source files; 4 test files; 2 context/research files.

**Pattern extraction date:** 2026-05-23
