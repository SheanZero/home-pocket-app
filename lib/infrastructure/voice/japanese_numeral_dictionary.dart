/// Japanese numeral dictionary — phonetic-to-NumeralToken lookup table used by
/// `JapaneseNumeralStateMachine` for longest-match tokenization.
///
/// Per D-05: covers every standard digit reading, unit base forms, and all
/// voicing (rendaku) + sokuon assimilation variants as direct entries (no rule
/// engine).
/// Per D-06: separate file so the lexicon can grow as data without touching
/// grammar.
///
/// Consumer: `JapaneseNumeralStateMachine` (Wave 2, Plan 20-05).
/// Layer direction: imports only the sibling `numeral_state_machine.dart`.
/// No imports from lib/features/, lib/application/, or lib/data/.
library;

import 'numeral_state_machine.dart';

/// Phonetic-to-[NumeralToken] lookup table for Japanese voice number parsing.
///
/// Keys are hiragana or katakana strings exactly as returned by the speech
/// recognizer. Multi-character voicing/sokuon variants (e.g. `'はっぴゃく'`) are
/// direct entries — the longest-match tokenizer in `JapaneseNumeralStateMachine`
/// sorts by descending key length so these longer forms win over bare unit forms.
///
/// Entry count: 30 (per D-05 digit matrix + unit base forms + voicing variants).
const Map<String, NumeralToken> japaneseNumeralDictionary = {
  // ─ Digits (multi-reading per D-05) ─────────────────────────────────────────
  'いち': Digit(1),
  'ひと': Digit(1),
  'に': Digit(2),
  'ふた': Digit(2),
  'さん': Digit(3),
  'よん': Digit(4),
  'し': Digit(4),
  'ご': Digit(5),
  'ろく': Digit(6),
  'なな': Digit(7),
  'しち': Digit(7),
  'はち': Digit(8),
  'きゅう': Digit(9),
  'く': Digit(9),

  // ─ Zero readings ────────────────────────────────────────────────────────────
  'ゼロ': ZeroPlaceholder(),
  'れい': ZeroPlaceholder(),
  'まる': ZeroPlaceholder(),

  // ─ Unit base forms ──────────────────────────────────────────────────────────
  'せん': Unit(1000),
  'ひゃく': Unit(100),
  'じゅう': Unit(10),
  'まん': Unit(10000),

  // ─ Voicing / sokuon multi-char variants ────────────────────────────────────
  // These entries are longer than the bare unit forms above. The longest-match
  // tokenizer (Wave 2) descends by key length, so these win over 'せん'/'ひゃく'/'まん'
  // when encountered at the current scan position.
  'いっせん': PackedToken([Digit(1), Unit(1000)]), // 1000 — sokuon
  'さんぜん': PackedToken([Digit(3), Unit(1000)]), // 3000 — rendaku
  'はっせん': PackedToken([Digit(8), Unit(1000)]), // 8000 — sokuon
  'さんびゃく': PackedToken([Digit(3), Unit(100)]), // 300 — voicing
  'ろっぴゃく': PackedToken([Digit(6), Unit(100)]), // 600 — sokuon
  'はっぴゃく': PackedToken([Digit(8), Unit(100)]), // 800 — sokuon
  'いちまん': PackedToken([Digit(1), Unit(10000)]), // 10000
};
