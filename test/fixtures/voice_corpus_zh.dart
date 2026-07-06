/// Voice number corpus for zh state machine (Phase 20 / VOICE-03).
///
/// ~50 cases covering 千/百/十/零 combinations + currency suffixes +
/// intra-pause anchor merges + adversarial recognizer noise.
/// Anchor cases are also asserted individually in
/// test/integration/voice/voice_corpus_zh_test.dart.
///
/// Used by:
///   - test/integration/voice/voice_corpus_zh_test.dart
///   - test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart
///
/// Conventions:
///   - All entries are pure const (no IO, no DateTime.now()).
///   - `const` records used throughout — data-only, no class wrapper.
///   - No imports from project source (test fixture is data-only).
library;

/// Record type for a single voice corpus test case.
///
/// Shared typedef also declared in voice_corpus_ja.dart; files are siblings
/// and intentionally self-contained (no cross-fixture imports for a trivial
/// record shape). Both use the identical signature so consumers can
/// use either fixture interchangeably.
typedef VoiceCorpusCase = ({String input, int expected, String? note});

/// Quick task 260526-k92 (Item 4): record type for date-phrase corpus cases.
/// `offsetFromToday` is a whole-day offset (negative = past, positive = future).
typedef VoiceDateCase = ({String input, int offsetFromToday, String? note});

/// Chinese voice date-phrase corpus (Item 4 of 260526-k92).
///
/// Covers the new keywords added to `_extractRelativeDate` plus the LAST-wins
/// rule for contradictory mentions. Asserted by
/// `test/integration/voice/voice_date_corpus_test.dart`.
const List<VoiceDateCase> voiceDateCorpusZh = [
  (input: '今天买了水果50元', offsetFromToday: 0, note: 'baseline 今天'),
  (input: '昨天吃饭花了三千日元', offsetFromToday: -1, note: 'baseline 昨天'),
  (input: '前天的咖啡480日元', offsetFromToday: -2, note: 'baseline 前天'),
  (input: '明天预约的诊费', offsetFromToday: 1, note: 'NEW 明天'),
  (input: '昨天今天都没记账', offsetFromToday: 0, note: 'LAST-wins: 今天 after 昨天'),
];

/// Chinese voice numeral corpus — ~50 const test cases.
///
/// Split: 5 anchor + ~15 baseline + ~15 currency suffix + ~10 adversarial + ~5 edge.
const List<VoiceCorpusCase> voiceCorpusZh = [
  // ---------------------------------------------------------------------------
  // Anchor cases (5) — note must contain "anchor"
  // ---------------------------------------------------------------------------
  (input: '2千2百零4元', expected: 2204, note: 'anchor: 零-placeholder VOICE-01'),
  (input: '1千8百4十元', expected: 1840, note: 'anchor: single-pass complete'),
  (input: '1千8百4十', expected: 1840, note: 'anchor: bare-tail (no currency suffix)'),
  (input: '一千二百', expected: 1200, note: 'anchor: legacy regression from voice_text_parser_test'),
  (input: '六百八十块', expected: 680, note: 'anchor: legacy regression — 块 currency'),

  // ---------------------------------------------------------------------------
  // Baseline digit ranges (~15)
  // ---------------------------------------------------------------------------
  (input: '六百八十', expected: 680, note: null),
  (input: '三千', expected: 3000, note: null),
  (input: '九千九百九十九', expected: 9999, note: null),
  (input: '五十', expected: 50, note: null),
  (input: '两千', expected: 2000, note: '两 as alternate reading for 二'),
  (input: '一百零五', expected: 105, note: null),
  (input: '二千零八', expected: 2008, note: null),
  (input: '四百五十', expected: 450, note: null),
  (input: '七千八百', expected: 7800, note: null),
  (input: '一万', expected: 10000, note: null),
  (input: '三万五千', expected: 35000, note: null),
  (input: '十', expected: 10, note: null),
  (input: '一百', expected: 100, note: null),
  (input: '一千', expected: 1000, note: null),
  (input: '九十九', expected: 99, note: null),

  // ---------------------------------------------------------------------------
  // Currency suffix variants (~15)
  // ---------------------------------------------------------------------------
  (input: '680元', expected: 680, note: null),
  (input: '1280块', expected: 1280, note: null),
  (input: '2千元', expected: 2000, note: null),
  (input: '三百块钱', expected: 300, note: null),
  (input: '5百元', expected: 500, note: null),
  (input: '2千5百元', expected: 2500, note: null),
  (input: '8百块', expected: 800, note: null),
  (input: '一千二百元', expected: 1200, note: null),
  (input: '三千五百块', expected: 3500, note: null),
  (input: '4千8百元', expected: 4800, note: null),
  (input: '9千9百9十9块', expected: 9999, note: null),
  (input: '1万元', expected: 10000, note: null),
  (input: '3万5千元', expected: 35000, note: null),
  (input: '1万2千块', expected: 12000, note: null),
  (input: '二万元', expected: 20000, note: null),

  // ---------------------------------------------------------------------------
  // Adversarial / recognizer noise (~10)
  // ---------------------------------------------------------------------------
  (input: '  680元  ', expected: 680, note: 'trailing whitespace — trim before parse'),
  (input: '2千304元', expected: 2304, note: 'mixed arabic+kanji — arabic digit as Digit token'),
  (input: '呃 1千8百元', expected: 1800, note: 'spoken hesitation 呃 → Skip; 1千8百 parsed normally'),
  (input: '那个 3百元', expected: 300, note: 'filler words 那个 → Skip'),
  (input: '就是 2千5', expected: 2500, note: 'filler 就是 → Skip; bare digit tail flush'),
  (input: '零五十', expected: 50, note: 'leading 零 before 五十'),
  (input: '一百零零五', expected: 105, note: 'double 零 placeholder — only final digit matters'),
  (input: '2千2百零04元', expected: 2204, note: 'arabic zero after 零 placeholder'),
  (input: '五百00元', expected: 500, note: 'arabic 00 suffix — tail digit 0'),
  (input: '8百零3块', expected: 803, note: 'mixed single-digit arabic after 零'),

  // ---------------------------------------------------------------------------
  // Edge boundaries (~5)
  // ---------------------------------------------------------------------------
  (input: '9万9千9百9十9元', expected: 99999, note: null),
  (input: '二万', expected: 20000, note: '二万 — 万-flush no-tail'),
  (input: '一万零一', expected: 10001, note: '万+零+digit tail'),
  (input: '千', expected: 1000, note: 'bare 千 — implicit digit=1'),
  (input: '百', expected: 100, note: 'bare 百 — implicit digit=1'),

  // ---------------------------------------------------------------------------
  // Quick task 260526-l0o (Issue 1) — comma-separated amounts + 日元 suffix
  // ---------------------------------------------------------------------------
  (input: '12,450日元', expected: 12450, note: 'l0o Issue 1 repro: half-width comma + 日元'),
  (input: '10,000日元', expected: 10000, note: 'l0o Issue 1: 5-digit half-width'),
  (input: '1,234,567日元', expected: 1234567, note: 'l0o Issue 1: million separator'),
  (input: '12，450日元', expected: 12450, note: 'l0o Issue 1: full-width comma 日元'),
  (input: '1,500元', expected: 1500, note: 'l0o Issue 1 regression: existing 元 + comma'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Quick task 260706-tm6 (voice-consolidation P0-4): cn2an-derived golden
// vectors, two-tier scheme. These lists are NEW and separate — they never feed
// the voiceCorpusZh statistical bucket above, so the existing ≥95% gate is not
// polluted by imported vectors. Asserted strictly (per-case) by
// test/integration/voice/voice_corpus_zh_golden_test.dart.
// ─────────────────────────────────────────────────────────────────────────────

/// Record type for a known-gap corpus case (260706-tm6). [reason] documents
/// why the vector is currently unparseable — the test file skips these via
/// the `skip:` parameter (never ignore comments) with the reason attached, so
/// removing the skip activates the strict assertion unchanged.
typedef VoiceKnownGapCase = ({String input, int expected, String reason});

/// cn2an classic vectors that the current parser reads correctly — asserted
/// strictly, one test() per entry. `note` records the source semantics.
const List<VoiceCorpusCase> voiceCorpusZhGolden = [
  (input: '两百五十', expected: 250, note: 'cn2an: 两 alternate reading + 十位尾'),
  (input: '两千零五', expected: 2005, note: 'cn2an: 零 placeholder after 千'),
  (input: '一千零一', expected: 1001, note: 'cn2an: classic 零-skip vector'),
  (input: '两千三百', expected: 2300, note: 'cn2an: 两 in non-initial scale read'),
  (input: '五千零四十', expected: 5040, note: 'cn2an: 零 placeholder before 十位'),
];

/// cn2an vectors the current parser cannot read — each carries the measured
/// actual and the gap class. Two clusters:
///   1. 口语「整位+裸尾」缩放 (两千五=2500): conflicts with the anchored
///      zero-omitted positional read (2千2百零4=2204, にせんにひゃくよん=2204),
///      so a trailing-digit scaling heuristic would regress existing anchors —
///      deep semantic change, not a shallow fix.
///   2. Missing colloquial/archaic tokens (俩/仨/廿/卅) and decimal spoken
///      forms (块五/五毛) outside the int-JPY parser semantics.
const List<VoiceKnownGapCase> voiceCorpusZhKnownGaps = [
  (
    input: '两千五',
    expected: 2500,
    reason: '口语「整千+裸尾数」缩放语义缺失；与零省略位值直读 anchor（2千2百零4=2204）冲突，'
        '非浅修（现返回 2005）',
  ),
  (
    input: '两万三',
    expected: 23000,
    reason: '口语「整万+裸尾数」缩放语义缺失，同 两千五 gap 类（现返回 20003）',
  ),
  (
    input: '3千2',
    expected: 3200,
    reason: '混写「整千+裸尾数」缩放语义缺失，同 两千五 gap 类（现返回 3002）',
  ),
  (
    input: '俩块钱',
    expected: 2,
    reason: '状态机缺「俩」口语数词 token（现返回 null）',
  ),
  (
    input: '仨百',
    expected: 300,
    reason: '状态机缺「仨」口语数词 token（现返回 100 —— 百 implicit-1 误触发）',
  ),
  (
    input: '廿五',
    expected: 25,
    reason: '状态机缺「廿」古体十位 token（现返回 5）',
  ),
  (
    input: '卅六',
    expected: 36,
    reason: '状态机缺「卅」古体十位 token（现返回 6）',
  ),
  (
    input: '三块五',
    expected: 4,
    reason: '小数口形 3.5 超出 int parser 语义；expected 按 Arabic 小数路径的 '
        'round() 折算（3.5→4）（现返回 5 —— last-wins digit）',
  ),
  (
    input: '十块五毛',
    expected: 11,
    reason: '小数口形 10.5 超出 int parser 语义；expected 按 round() 折算'
        '（10.5→11）（现返回 15 —— 五 被并入整数位）',
  ),
];
