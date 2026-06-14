/// Voice numeral parsing — shared by zh/ja concrete state machines per Thin Feature rule.
///
/// Stateless functional API: `int? parse(String text)`. Buffer/timer state lives
/// in VoiceChunkMerger (`lib/application/voice/voice_chunk_merger.dart`).
///
/// NumeralToken sealed taxonomy + NumeralStateMachine abstract base.
/// Concrete implementations:
///   - ChineseNumeralStateMachine (`chinese_numeral_state_machine.dart`)
///   - JapaneseNumeralStateMachine (`japanese_numeral_state_machine.dart`)
///
/// Consumed by:
///   - Wave 2: Chinese + Japanese concrete state machines
///   - Wave 4: Voice corpus integration tests
///
/// Layer direction: no imports from lib/features/, lib/application/, or lib/data/.
library;

import 'package:flutter/foundation.dart' show protected;

import '../../shared/constants/voice_currency_suffixes.dart';

// ---------------------------------------------------------------------------
// Token taxonomy (D-07)
// ---------------------------------------------------------------------------

/// Base sealed token type for the numeral scanner.
///
/// Each character or multi-character dictionary entry normalizes into one of
/// the five concrete token types below. The scanner consumes uniformly.
sealed class NumeralToken {
  const NumeralToken();
}

/// A single numeric digit value (0–9).
class Digit extends NumeralToken {
  final int value;
  const Digit(this.value);
}

/// A positional unit multiplier: 10, 100, 1000, or 10000 (万-scale).
class Unit extends NumeralToken {
  final int power; // 10, 100, 1000, 10000
  const Unit(this.power);
}

/// Explicit zero placeholder (Chinese 零, Japanese れい/ゼロ in digit position).
///
/// Prevents implicit-digit-1 fallback in the scanner:
/// e.g. '2千2百零4' → Digit(2) Unit(1000) Digit(2) Unit(100) ZeroPlaceholder Digit(4)
/// Without ZeroPlaceholder the scanner would apply digit=1 before Unit(100).
class ZeroPlaceholder extends NumeralToken {
  const ZeroPlaceholder();
}

/// A non-numeric token to be skipped (currency suffix, hesitation sounds, etc.).
class Skip extends NumeralToken {
  const Skip();
}

/// Holds a pre-expanded multi-token sequence for dictionary entries like
/// はっぴゃく → [Digit(8), Unit(100)]. The scanner expands inline.
class PackedToken extends NumeralToken {
  final List<NumeralToken> inner;
  const PackedToken(this.inner);
}

// ---------------------------------------------------------------------------
// Abstract base
// ---------------------------------------------------------------------------

/// Abstract state machine for voice numeral parsing (zh + ja concrete classes).
///
/// Subclasses implement [parse] and [normalize]; the shared [scan] algorithm
/// (Pattern 1 in RESEARCH.md) is provided here as a @protected concrete method.
///
/// Algorithm invariants (Pattern 1):
/// - Left-to-right accumulator: digit → section (flushes on Unit < 万) → total (flushes on 万).
/// - Implicit digit=1 on bare Unit: '千' → 1000 (not 0).
/// - ZeroPlaceholder resets digit to 0 without triggering implicit-1 fallback.
/// - scan() returns null if no numeric tokens were seen or total == 0.
abstract class NumeralStateMachine {
  const NumeralStateMachine();

  /// Parse a numeric text string into an integer amount.
  /// Returns null if no recognizable numeric content is found.
  int? parse(String text);

  /// Locale-specific tokenization. Subclasses implement.
  ///
  /// Every recognized character/entry maps to a [NumeralToken].
  /// Non-numeric characters should map to [Skip].
  List<NumeralToken> normalize(String text);

  /// Detects a spoken currency token in [text] and returns it as a raw token
  /// (e.g. `美元`, `香港ドル`, or the bare `元`/`円`), or null if none present.
  ///
  /// Phase 42 (VOICE-CUR-01/02/03): the numeral path strips currency tokens
  /// from the amount silently; this method runs the SAME longest-first scan
  /// over [VoiceCurrencySuffixes.all] separately so the detected currency is
  /// returned WITHOUT polluting the integer amount result (T-42-07). ISO-code
  /// and bare-token/locale resolution is the caller's responsibility — the raw
  /// token is returned so the use-case layer can disambiguate locale-dependent
  /// bare `元` (zh→CNY, ja→JPY per D-08 locked) from explicit foreign tokens.
  ///
  /// Returns the FIRST (leftmost) longest match so `香港ドル` wins over the
  /// `ドル` substring it contains, mirroring the [all] ordering invariant.
  ///
  /// WR-03: an EXPLICIT-FOREIGN token (present in
  /// [VoiceCurrencySuffixes.tokenToIso]) is preferred over a bare-native token
  /// (元/円/块/ドル-as-native etc.) even when the bare-native token occurs
  /// EARLIER in the string. Pure leftmost-wins mis-classified utterances like
  /// `元宝店买了美元` (bare 元@0 beating 美元@4) as CNY; the explicit foreign
  /// token is the user's actual currency intent. The leftmost/longest tie-break
  /// is applied WITHIN each tier, so containment behavior (香港ドル ⊃ ドル) is
  /// preserved (both are explicit-foreign, leftmost-wins picks 香港ドル).
  ///
  /// Pure: [text] is not mutated; a new string token (or null) is returned.
  String? detectCurrencyToken(String text) {
    // Quick task 260614-goh: lowercase the haystack so English tokens (stored
    // lowercase in [VoiceCurrencySuffixes.all]) match regardless of STT
    // capitalization ("Dollars", "Hong Kong dollars"). CJK toLowerCase is the
    // identity, so zh/ja matching is unaffected. The ORIGINAL-cased token is
    // still returned (for the tokenToIso lookup at the call site).
    final haystack = text.toLowerCase();
    String? bestForeign;
    var bestForeignIndex = -1;
    String? bestNative;
    var bestNativeIndex = -1;

    for (final token in VoiceCurrencySuffixes.all) {
      final idx = haystack.indexOf(token.toLowerCase());
      if (idx < 0) continue;
      final isExplicitForeign =
          VoiceCurrencySuffixes.tokenToIso.containsKey(token);
      if (isExplicitForeign) {
        // Leftmost-wins within the foreign tier; on an exact index tie [all]'s
        // longest-first ordering keeps the longer token (first-seen retained).
        if (bestForeignIndex < 0 || idx < bestForeignIndex) {
          bestForeignIndex = idx;
          bestForeign = token;
        }
      } else {
        if (bestNativeIndex < 0 || idx < bestNativeIndex) {
          bestNativeIndex = idx;
          bestNative = token;
        }
      }
    }

    // Prefer an explicit-foreign token over any bare-native token.
    return bestForeign ?? bestNative;
  }

  /// Shared scanner (Pattern 1 in RESEARCH.md). Concrete classes call this.
  ///
  /// Runs a left-to-right accumulator over [tokens] after flattening
  /// [PackedToken] via [_expandPacked].
  @protected
  int? scan(List<NumeralToken> tokens) {
    if (tokens.isEmpty) return null;
    var total = 0, section = 0, digit = 0;
    var sawAny = false;
    for (final tok in _expandPacked(tokens)) {
      switch (tok) {
        case Digit(:final value):
          digit = value;
          sawAny = true;
        case Unit(:final power) when power == 10000:
          total += (section + (digit == 0 ? 1 : digit)) * 10000;
          section = 0;
          digit = 0;
          sawAny = true;
        case Unit(:final power):
          section += (digit == 0 ? 1 : digit) * power;
          digit = 0;
          sawAny = true;
        case ZeroPlaceholder():
          digit = 0;
          sawAny = true;
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
