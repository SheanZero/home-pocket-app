import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:home_pocket/shared/constants/default_synonyms.dart';

/// D-04 MACHINE SET-COMPLETENESS GATE (Phase 50 DECOUP-02, T-50-08).
///
/// The categoryId hard gate (`default_synonyms_categoryid_test.dart`) proves
/// NO orphan id, but it passes just as happily on a partial seed — every
/// present row is legal, the missing rows simply do not exist to fail.
/// A `grep cat_car_fuel` likewise passes on a partial seed. This gate closes
/// THAT failure mode: it proves every L2 has at least one zh seed AND at least
/// one ja seed, and NAMES every uncovered id so the authoring task knows
/// exactly what to add.
///
/// ── target set: FULL L2 coverage ──────────────────────────────────────
/// SCOPE (user decision, continuation of plan 50-02): the target set is now
/// EVERY level-2 category — the previously-excluded admin families are
/// INCLUDED per RESEARCH A4 ("err toward including admin buckets"). There is
/// NO exclusion list any more: `targetL2 = { every Category with level == 2 }`.
/// This deliberately covers the families that the earlier speakable-only scope
/// dropped (`*_other` fallback buckets, `cat_asset_*`, `cat_insurance_*`,
/// `*_insurance`, `*_tax`, `cat_tax_*`, `cat_special_*`). People do say some of
/// these aloud ("汽车税", "房贷"), and the categoryId orphan gate guards typos
/// regardless. The gate's PURPOSE is unchanged — prove every target L2 has
/// ≥1 zh + ≥1 ja DIRECT seed — only the target set widened to all L2.
///
/// ── zh vs ja classification ────────────────────────────────────────────
/// [CategoryKeywordPreference] has NO lang/script field — only `keyword` +
/// `categoryId`. So script is INFERRED from the keyword's codepoints:
///   • a keyword containing any KANA (hiragana / katakana / half-width
///     katakana) is a JA seed ([_isJa]).
///   • a keyword with CJK Han ideographs and NO kana is a ZH seed ([_isZh]).
///     (Han-only words are shared by zh & ja; we count them as ZH. A pure-ja
///     coverage therefore needs at least one kana-bearing surface per L2 —
///     the human spot-check can adjust a borderline Han-only ja word.)
void main() {
  // ── Codepoint helpers ──────────────────────────────────────────────────
  bool hasKana(String kw) {
    for (final r in kw.runes) {
      final hiragana = r >= 0x3040 && r <= 0x309F;
      final katakana = r >= 0x30A0 && r <= 0x30FF;
      final halfWidthKatakana = r >= 0xFF66 && r <= 0xFF9F;
      if (hiragana || katakana || halfWidthKatakana) return true;
    }
    return false;
  }

  bool hasHan(String kw) {
    for (final r in kw.runes) {
      // CJK Unified Ideographs (BMP) + common extension-A range.
      final cjk = r >= 0x4E00 && r <= 0x9FFF;
      final cjkExtA = r >= 0x3400 && r <= 0x4DBF;
      if (cjk || cjkExtA) return true;
    }
    return false;
  }

  bool isJa(String kw) => hasKana(kw);
  bool isZh(String kw) => hasHan(kw) && !hasKana(kw);

  // ── target set: FULL L2 coverage (no exclusion — see header) ───────────
  // User scope decision (continuation of plan 50-02): every level-2 category
  // is a coverage target, including the admin families the earlier scope
  // excluded. The kept variable name `speakableL2` is retained to minimise
  // churn; it now means "every L2", not a speakable subset.
  final speakableL2 = DefaultCategories.all
      .where((c) => c.level == 2)
      .map((c) => c.id)
      .toSet();

  group('DefaultVoiceSynonyms full-L2 coverage (D-04)', () {
    test('targetL2 set is non-empty (broken-filter guard)', () {
      expect(speakableL2, isNotEmpty);
    });

    test(
      'every L2 has >=1 zh direct seed AND >=1 ja direct seed',
      () {
        final offenders = <String>[];
        for (final id in speakableL2) {
          // DIRECT seeds only — an L1 seed covers only that L1's _other bucket
          // via _ensureL2, never an arbitrary sibling L2. So set-completeness
          // requires a seed whose categoryId == this exact L2 id.
          final direct = DefaultVoiceSynonyms.all
              .where((s) => s.categoryId == id)
              .map((s) => s.keyword)
              .toList();
          final hasZh = direct.any(isZh);
          final hasJa = direct.any(isJa);
          if (!hasZh && !hasJa) {
            offenders.add('$id (missing: both)');
          } else if (!hasZh) {
            offenders.add('$id (missing: zh)');
          } else if (!hasJa) {
            offenders.add('$id (missing: ja)');
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'These L2 categories lack a zh and/or ja direct seed '
              '(D-04 full-coverage gap):\n${offenders.join('\n')}',
        );
      },
    );

    test('coverage check iterates the FULL speakable set (no sampling)', () {
      // Re-assert per-id (not just the aggregate offenders list) so the count
      // of executed assertions equals |speakableL2| — a partial loop bug would
      // shrink this and is caught by the non-empty guard above.
      var checked = 0;
      for (final id in speakableL2) {
        final direct = DefaultVoiceSynonyms.all
            .where((s) => s.categoryId == id)
            .map((s) => s.keyword)
            .toList();
        expect(
          direct.any(isZh) && direct.any(isJa),
          isTrue,
          reason: '$id lacks a zh+ja direct seed pair',
        );
        checked++;
      }
      expect(checked, equals(speakableL2.length));
    });
  });
}
