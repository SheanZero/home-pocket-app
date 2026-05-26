/// Voice number corpus for ja state machine (Phase 20 / VOICE-03).
///
/// ~50 cases covering せん/ひゃく/じゅう/まん combinations + currency suffixes +
/// voicing/sokuon variants + multi-reading digits + kanji-literal fallback.
/// Anchor cases are also asserted individually in
/// test/integration/voice/voice_corpus_ja_test.dart.
///
/// Used by:
///   - test/integration/voice/voice_corpus_ja_test.dart
///   - test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart
///
/// Conventions:
///   - All entries are pure const (no IO, no DateTime.now()).
///   - `const` records used throughout — data-only, no class wrapper.
///   - No imports from project source (test fixture is data-only).
library;

/// Record type for a single voice corpus test case.
///
/// Intentionally redeclared here (not imported from voice_corpus_zh.dart).
/// Fixture files are siblings; keeping each self-contained avoids cross-fixture
/// coupling for a trivial record shape. Signature is identical so consumers
/// can use either fixture interchangeably.
typedef VoiceCorpusCase = ({String input, int expected, String? note});

/// Quick task 260526-k92 (Item 4): record type for date-phrase corpus cases.
/// Intentionally redeclared here as `VoiceDateCaseJa` to keep the ja fixture
/// self-contained (siblings the zh `VoiceDateCase`).
typedef VoiceDateCaseJa = ({String input, int offsetFromToday, String? note});

/// Japanese voice date-phrase corpus (Item 4 of 260526-k92).
///
/// Covers the new 明日/あした/あす/明後日/あさって keywords plus baselines for
/// existing 今日/昨日/おととい. Asserted by
/// `test/integration/voice/voice_date_corpus_test.dart`.
const List<VoiceDateCaseJa> voiceDateCorpusJa = [
  (input: 'きょう 牛乳 280円', offsetFromToday: 0, note: 'baseline きょう'),
  (input: '昨日のラーメン 980円', offsetFromToday: -1, note: 'baseline 昨日'),
  (input: 'おととい買った本 1500円', offsetFromToday: -2, note: 'baseline おととい'),
  (input: '明日の昼食 600円', offsetFromToday: 1, note: 'NEW 明日'),
  (input: 'あさっての約束 2000円', offsetFromToday: 2, note: 'NEW あさって'),
];

/// Japanese voice numeral corpus — ~50 const test cases.
///
/// Split: 5 anchor + ~15 baseline + ~15 currency suffix + ~10 multi-reading + ~5 kanji/edge.
const List<VoiceCorpusCase> voiceCorpusJa = [
  // ---------------------------------------------------------------------------
  // Anchor cases (5) — note must contain "anchor"
  // ---------------------------------------------------------------------------
  (input: 'にせんにひゃくよん', expected: 2204, note: 'anchor: pure hiragana VOICE-01'),
  (input: 'にせんにひゃくよん円', expected: 2204, note: 'anchor: pure hiragana + currency suffix'),
  (input: 'せんはっぴゃくよんじゅう', expected: 1840, note: 'anchor: sokuon+voicing single-pass'),
  (input: 'せんはっぴゃくよんじゅう円', expected: 1840, note: 'anchor: same + currency'),
  (input: '一万二千', expected: 12000, note: 'anchor: 万-scale regression guard VOICE-03'),

  // ---------------------------------------------------------------------------
  // Baseline digit ranges + voicing/sokuon forms (~15)
  // ---------------------------------------------------------------------------
  (input: 'ろっぴゃく', expected: 600, note: 'sokuon ろっぴゃく (六百)'),
  (input: 'はっぴゃく', expected: 800, note: 'sokuon はっぴゃく (八百)'),
  (input: 'さんびゃく', expected: 300, note: 'voiced さんびゃく (三百)'),
  (input: 'いっせん', expected: 1000, note: 'sokuon いっせん (一千)'),
  (input: 'さんぜん', expected: 3000, note: 'rendaku さんぜん (三千)'),
  (input: 'はっせん', expected: 8000, note: 'sokuon はっせん (八千)'),
  (input: 'いちまん', expected: 10000, note: 'いちまん (一万)'),
  (input: 'じゅう', expected: 10, note: 'bare じゅう'),
  (input: 'ひゃく', expected: 100, note: 'bare ひゃく — implicit digit=1'),
  (input: 'せん', expected: 1000, note: 'bare せん — implicit digit=1'),
  (input: 'まん', expected: 10000, note: 'bare まん — implicit digit=1, 万-flush'),
  (input: 'ななひゃく', expected: 700, note: 'なな reading (七)'),
  (input: 'しちひゃく', expected: 700, note: 'しち multi-reading (七百)'),
  (input: 'よんじゅう', expected: 40, note: 'よん reading (四)'),
  (input: 'しじゅう', expected: 40, note: 'し multi-reading (四十)'),

  // ---------------------------------------------------------------------------
  // Currency suffix variants (~15)
  // ---------------------------------------------------------------------------
  (input: '680円', expected: 680, note: null),
  (input: 'ろっぴゃくはちじゅう円', expected: 680, note: null),
  (input: 'せんはっぴゃく円', expected: 1800, note: null),
  (input: 'いちまん円', expected: 10000, note: null),
  (input: 'さんぜん円', expected: 3000, note: null),
  (input: 'はっせん円', expected: 8000, note: null),
  (input: 'さんびゃく円', expected: 300, note: null),
  (input: 'ろっぴゃく円', expected: 600, note: null),
  (input: 'はっぴゃく円', expected: 800, note: null),
  (input: 'にせん円', expected: 2000, note: null),
  (input: 'ごじゅう円', expected: 50, note: null),
  (input: 'きゅうひゃく円', expected: 900, note: null),
  (input: 'さんぜんごひゃく円', expected: 3500, note: null),
  (input: 'いちまんごせん円', expected: 15000, note: null),
  (input: 'にまんさんぜん円', expected: 23000, note: null),

  // ---------------------------------------------------------------------------
  // Multi-reading coverage (~10)
  // ---------------------------------------------------------------------------
  (input: 'ひゃくくじゅう', expected: 190, note: 'く=9 alternate reading (九十)'),
  (input: 'くひゃく', expected: 900, note: 'く reading for 九百'),
  (input: 'ろっぴゃくしちじゅう', expected: 670, note: 'しち=7 reading for 七十'),
  (input: 'よんひゃく', expected: 400, note: 'よん reading for 四百'),
  (input: 'しひゃく', expected: 400, note: 'し reading for 四百'),
  (input: 'ふたひゃく', expected: 200, note: 'ふた reading for 二百'),
  (input: 'ひとひゃく', expected: 100, note: 'ひと reading for 一百'),
  (input: 'ひゃくにじゅうさん', expected: 123, note: 'sequential three-unit parse'),
  (input: 'ごせん', expected: 5000, note: 'ご reading for 五千'),
  (input: 'ろくひゃく', expected: 600, note: 'ろく reading for 六百'),

  // ---------------------------------------------------------------------------
  // Kanji digits + units (~5 edge)
  // ---------------------------------------------------------------------------
  (input: '三千九百八十', expected: 3980, note: 'kanji — legacy regression from voice_text_parser_test:55'),
  (input: '千二百', expected: 1200, note: 'kanji bare-千 implicit-1'),
  (input: '六百八十円', expected: 680, note: 'kanji + currency suffix'),
  (input: '一万二千三百四十五', expected: 12345, note: 'kanji 5-unit full parse'),
  (input: '九万九千', expected: 99000, note: 'kanji 万-scale two-section'),

  // ---------------------------------------------------------------------------
  // Quick task 260526-l0o (Issue 1) — comma-separated amounts (ja-side guard)
  // ---------------------------------------------------------------------------
  (input: '12,450円', expected: 12450, note: 'l0o Issue 1 repro ja: comma + 円'),
  (input: '1,234,567円', expected: 1234567, note: 'l0o Issue 1: million separator ja'),
  (input: '12，450円', expected: 12450, note: 'l0o Issue 1: full-width comma ja'),
];
