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
