import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/alternate_category_chips.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';

import '../../../../../helpers/test_localizations.dart';

/// RECUX-04 / D-17 anti-toxicity widget sweep — Phase 52 (recognition UX).
///
/// Verifies that the still-reachable alternate-category correction chips never
/// leak any forbidden gamification / value-judgment / comparison substring
/// into rendered output in any supported locale. The retired confidence-band
/// surface is intentionally absent from this production-surface gate.
///
/// Rationale (CONTEXT D-17 + UI-SPEC §Copywriting Contract + ADR-012):
/// Anti-toxicity intent is a "compile-and-test gate" (automated, audit-friendly)
/// run INLINE as a merge gate — not deferred to milestone close (the v1.7/v1.8
/// lesson). The sweep pumps the WHOLE surface for each state so any future ARB
/// addition is auto-vetted. Failure modes are silent: a single locale slipping a
/// "score" / "連続" header would ship a regression unnoticed without this sweep.
///
/// COMPLETE banned list (RECUX-04 / fixes v1.8 WR-02 incompleteness): the
/// forbidden vocabulary is the verbatim phase16/phase47 list EXTENDED with the
/// v1.8-WR-02 tokens `score`, `streak`, `accuracy`, `正确率`, `連続`,
/// `ストリーク`, `達成` plus the additional UI-SPEC §Copywriting tokens
/// (badge / leaderboard / 正解率 / 連勝 / 达成). The list is NEVER shrunk to make
/// the sweep pass — if a string trips it, fix the offending COPY and escalate
/// (anti_toxicity §locked-list rule).
///
/// NOTE: this test file LEGITIMATELY contains the banned tokens below as the
/// negative-match list (they are what the sweep asserts are ABSENT from
/// rendered output — not strings the app paints).

// ---------------------------------------------------------------------------
// LOCKED forbidden substring lists — COPIED VERBATIM from
// anti_toxicity_phase16_test.dart / anti_toxicity_phase47_test.dart and
// EXTENDED with the COMPLETE v1.8-WR-02 + UI-SPEC §Copywriting tokens. Do NOT
// relax these without an explicit product/ADR sign-off (D-17). If a surface's
// copy trips a forbidden substring, fix the COPY (escalate) — never shrink the
// list.
// ---------------------------------------------------------------------------

const forbiddenEn = <String>[
  // -- verbatim phase16/phase47 lineup --
  'better',
  'worse',
  'winner',
  'loser',
  'vs',
  'versus',
  'compare',
  'comparison',
  'higher is good',
  'lower is bad',
  'score',
  'rank',
  'ranking',
  'wins',
  'loses',
  // -- v1.8 WR-02 extension (RECUX-04) --
  'streak',
  'accuracy',
  // -- UI-SPEC §Copywriting extension --
  'badge',
  'leaderboard',
  'achievement',
];

const forbiddenZh = <String>[
  // -- verbatim phase16/phase47 lineup --
  '更好',
  '更差',
  '赢',
  '输',
  '胜',
  '败',
  'vs',
  '对比',
  '比较',
  '排名',
  '分数',
  '胜出',
  '落败',
  // -- v1.8 WR-02 extension (RECUX-04) --
  '正确率',
  // -- UI-SPEC §Copywriting extension --
  '达成',
  '连胜',
  '徽章',
  '排行榜',
];

const forbiddenJa = <String>[
  // -- verbatim phase16/phase47 lineup --
  '勝ち',
  '負け',
  'より良い',
  'より悪い',
  '比較',
  '対決',
  'スコア',
  'ランキング',
  '勝つ',
  '負ける',
  // -- v1.8 WR-02 extension (RECUX-04) --
  '連続',
  'ストリーク',
  '達成',
  // -- UI-SPEC §Copywriting extension --
  '正解率',
  '連勝',
  'バッジ',
];

const locales = <Locale>[Locale('en'), Locale('ja'), Locale('zh')];

List<String> _forbiddenFor(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return forbiddenEn;
    case 'ja':
      return forbiddenJa;
    case 'zh':
      return forbiddenZh;
  }
  throw StateError('Unsupported locale: ${locale.languageCode}');
}

// ---------------------------------------------------------------------------
// Coverage guard — every banned-token list must include the COMPLETE v1.8 WR-02
// vocabulary so a future edit cannot silently shrink it back to the v1.8 gap.
// ---------------------------------------------------------------------------

const _requiredEnTokens = <String>['score', 'streak', 'accuracy'];
const _requiredZhTokens = <String>['正确率', '达成'];
const _requiredJaTokens = <String>['連続', 'ストリーク', '達成'];

// ---------------------------------------------------------------------------
// Fixtures — `cat_*` system category ids so the chips resolve REAL trilingual
// labels (CategoryLocalizationService.resolveFromId strips the `cat_` prefix
// and looks up the locale map synchronously: 食費/食费/Food etc.). Using ids
// that already start with `category_` would pass through unchanged and render
// the raw key in all three locales — defeating the trilingual sweep.
// ---------------------------------------------------------------------------

CategoryMatchResult _alt(String id, double confidence) => CategoryMatchResult(
  categoryId: id,
  confidence: confidence,
  source: MatchSource.merchant,
);

final _alternates = <CategoryMatchResult>[
  _alt('cat_food', 0.9),
  _alt('cat_transport', 0.8),
  _alt('cat_hobbies', 0.7),
];

// ---------------------------------------------------------------------------
// Subject builder — the chips paint category labels + the exit chip.
// ---------------------------------------------------------------------------

// The "correction-open" surface is the alternate chips with the exit chip
// (→ full selector) and a currently-selected alternate, i.e. mid-correction.
Widget _correctionOpen() => Scaffold(
  body: AlternateCategoryChips(
    alternates: _alternates,
    selectedCategoryId: 'cat_food',
    onSelect: (_) {},
  ),
);

// ---------------------------------------------------------------------------
// Sweep helper — runs the forbidden-substring sweep against the rendered widget
// tree. Embeds surface / locale / state / substring in the failure reason for
// fast triage.
// ---------------------------------------------------------------------------

void _sweepForbiddenSubstrings({
  required Locale locale,
  required String surface,
  required String state,
}) {
  for (final substring in _forbiddenFor(locale)) {
    expect(
      find.textContaining(substring, findRichText: true),
      findsNothing,
      reason:
          'RECUX-04 / D-17 anti-toxicity violation — $surface / '
          '${locale.languageCode} / $state — forbidden substring "$substring" '
          'leaked into rendered output. Fix the offending COPY and escalate — '
          'NEVER shrink the banned list (anti_toxicity §locked-list rule).',
    );
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Locked-list integrity — the COMPLETE v1.8 WR-02 vocabulary must be present
  // in every locale's banned list, so the sweep can never be made to pass by
  // shrinking the list back to the v1.8 gap.
  // -------------------------------------------------------------------------
  group('RECUX-04 / banned-list integrity (fixes v1.8 WR-02)', () {
    test('en list carries the complete WR-02 tokens', () {
      for (final token in _requiredEnTokens) {
        expect(forbiddenEn, contains(token));
      }
    });
    test('zh list carries the complete WR-02 tokens', () {
      for (final token in _requiredZhTokens) {
        expect(forbiddenZh, contains(token));
      }
    });
    test('ja list carries the complete WR-02 tokens', () {
      for (final token in _requiredJaTokens) {
        expect(forbiddenJa, contains(token));
      }
    });
  });

  // -------------------------------------------------------------------------
  // correction-open (alternates with a selected chip + exit chip). 3 locales.
  // -------------------------------------------------------------------------
  group('RECUX-04 / correction-open / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('correction-open / ${locale.languageCode}', (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(_correctionOpen(), locale: locale),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('alt-chip-exit')),
          findsOneWidget,
          reason:
              'the exit chip (→ full selector) must render in the '
              'correction-open state so its copy is swept.',
        );
        _sweepForbiddenSubstrings(
          locale: locale,
          surface: 'AlternateCategoryChips',
          state: 'correction-open',
        );
      });
    }
  });
}
