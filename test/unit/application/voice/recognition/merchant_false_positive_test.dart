import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_match_entry.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';
import 'package:home_pocket/shared/constants/default_merchants.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fixtures/merchant_false_positive_corpus.dart';

// Phase 50 Plan 03 (SC2): the adversarial false-positive gate. Each of the ~40
// corpus entries (お米 / 杉並区 / comment-words / chain-substring fragments) must
// either produce NO candidate or stay strictly BELOW the 0.85 auto-fill floor
// (D-03). This validates the anchored tiers + per-script min-length guard
// (Assumptions A1/A2) against the FULL ~400-merchant seed — not a toy fixture —
// so we know real chain surfaces do not over-fill on generic utterances.

class _MockMerchantRepository extends Mock implements MerchantRepository {}

/// The orchestrator's auto-fill floor (D-03). Mirrored here as a test constant;
/// the engine itself does not own it, but the gate is defined relative to it.
const double kAutoFillFloor = 0.85;

/// Expand the real authored seed into the same flat MerchantMatchEntry list the
/// recognizer scores over in production — one entry per surface form, matchKey
/// derived with the production normalizer. This is the faithful ~400-merchant
/// adversarial backdrop (not a hand-picked subset).
List<MerchantMatchEntry> _seedEntries() {
  final entries = <MerchantMatchEntry>[];
  for (final m in DefaultMerchants.all) {
    final surfaces = <String>[
      m.nameJa,
      ...m.aliases,
      if (m.nameZh != null) m.nameZh!,
      if (m.nameEn != null) m.nameEn!,
    ];
    for (final s in surfaces) {
      entries.add(
        MerchantMatchEntry(
          matchKey: normalizeMerchantKey(s),
          surface: s,
          merchantId: m.id,
          displayName: m.nameJa,
          categoryId: m.categoryId,
          ledgerHint: 'daily',
        ),
      );
    }
  }
  return entries;
}

void main() {
  late MerchantRecognizer recognizer;

  setUp(() {
    final repo = _MockMerchantRepository();
    final entries = _seedEntries();
    when(repo.loadAllForMatching).thenAnswer((_) async => entries);
    recognizer = MerchantRecognizer(merchantRepository: repo);
  });

  test('corpus has ~40 adversarial entries including お米 and 杉並区', () {
    expect(merchantFalsePositiveCorpus.length, greaterThanOrEqualTo(35));
    expect(merchantFalsePositiveCorpus, contains('お米'));
    expect(merchantFalsePositiveCorpus, contains('杉並区'));
  });

  test(
    'every adversarial entry yields no candidate OR best score < 0.85 (SC2)',
    () async {
      final offenders = <String>[];
      for (final query in merchantFalsePositiveCorpus) {
        final cands = await recognizer.recognize(query);
        if (cands.isEmpty) continue;
        final best = cands.first.score;
        if (best >= kAutoFillFloor) {
          offenders.add(
            '"$query" -> ${cands.first.merchantId} @ '
            '${best.toStringAsFixed(2)}',
          );
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'These adversarial entries auto-filled at/above the 0.85 floor '
            '(false positives — SC2 violated):\n${offenders.join('\n')}',
      );
    },
  );
}
