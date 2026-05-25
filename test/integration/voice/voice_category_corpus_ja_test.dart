import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';

import '../../fixtures/voice_category_corpus_ja.dart';
import '../../helpers/test_provider_scope.dart';

/// Phase 21 D-10 corpus test (ja) for VoiceCategoryResolver.
///
/// Anchor cases (5) get strict, individual `test()` blocks — hard failures.
/// Statistical bucket aggregates non-anchor cases under a per-locale ≥95%
/// accuracy gate (mirrors Phase 20 corpus pattern).
///
/// The ja fixture's anchors all resolve via static seed lookups + merchant DB
/// (NO learned-override setUp — that anchor is zh-only per Plan 21-06 spec).
///
/// VOICE-06 extensibility — a dedicated test inserts a fresh `タピオカ` keyword
/// at runtime (not in DefaultVoiceSynonyms) and asserts the resolver picks it
/// up without any resolver-code change.
void main() {
  late final container = createTestProviderScope();
  late VoiceCategoryResolver resolver;
  late CategoryKeywordPreferenceRepository prefRepo;

  var passCount = 0;
  var totalCount = 0;

  setUpAll(() async {
    await container.read(seedCategoriesUseCaseProvider).execute();
    await container.read(seedVoiceSynonymsUseCaseProvider).execute();
    prefRepo = container.read(categoryKeywordPreferenceRepositoryProvider);
    resolver = VoiceCategoryResolver(
      categoryRepository: container.read(categoryRepositoryProvider),
      preferenceRepository: prefRepo,
      categoryService: container.read(categoryServiceProvider),
      merchantDatabase: MerchantDatabase(),
    );
  });

  Future<String?> resolveCategory(String input, String keyword) async {
    // WR-04: resolver.resolve() now takes only the extracted keyword. The
    // corpus fixture pre-extracts the keyword, so we drop inputText.
    final r = await resolver.resolve(keyword);
    return r?.categoryId;
  }

  // ─── Anchor cases — strict, individual test() blocks ───
  group('ja anchor cases (VOICE-04 / VOICE-05 / VOICE-06)', () {
    final anchors = voiceCategoryCorpusJa
        .where((c) => c.note?.startsWith('anchor:') ?? false)
        .toList();

    setUpAll(() {
      expect(
        anchors.length,
        greaterThanOrEqualTo(5),
        reason: 'Fixture must contain ≥5 anchor cases (Plan 21-06 / D-10 contract)',
      );
    });

    for (final c in anchors) {
      test('${c.input} -> ${c.expectedCategoryId}  [${c.note}]', () async {
        totalCount++;
        final actual = await resolveCategory(c.input, c.keyword);
        if (actual == c.expectedCategoryId) {
          passCount++;
        } else {
          expect(
            actual,
            c.expectedCategoryId,
            reason:
                'anchor case must pass strictly: input="${c.input}" keyword="${c.keyword}" expected=${c.expectedCategoryId} actual=$actual',
          );
        }
      });
    }
  });

  // ─── Statistical bucket — non-anchor cases ───
  group('ja statistical corpus (≥95% accuracy gate)', () {
    final nonAnchors = voiceCategoryCorpusJa
        .where((c) => !(c.note?.startsWith('anchor:') ?? false))
        .toList();

    for (final c in nonAnchors) {
      test(c.input, () async {
        totalCount++;
        final actual = await resolveCategory(c.input, c.keyword);
        if (actual == c.expectedCategoryId) {
          passCount++;
        } else {
          // Soft per-case failure: log mismatch for inspection but do NOT
          // throw — the ≥95% aggregate gate in tearDownAll is the only gate.
          // ignore: avoid_print
          printOnFailure(
            'mismatch: input="${c.input}" keyword="${c.keyword}" expected=${c.expectedCategoryId} actual=$actual note=${c.note ?? ""}',
          );
        }
      });
    }
  });

  // ─── VOICE-06 extensibility test — runtime data-source insert ───
  group('VOICE-06 extensibility: runtime data-source insert without resolver code change', () {
    test('new keyword row resolves end-to-end without resolver code change', () async {
      // タピオカ is NOT in DefaultVoiceSynonyms — insert at runtime.
      await prefRepo.recordCorrection(
        keyword: 'タピオカ',
        categoryId: 'cat_food_drinks',
      );
      final actual = await resolver.resolve('タピオカ');
      expect(actual, isNotNull,
          reason: 'Resolver must pick up the runtime-inserted keyword');
      expect(actual!.categoryId, 'cat_food_drinks',
          reason: 'VOICE-06: data source extensible without resolver code change');
    });
  });

  // ─── Phase 23 D-15 / IN-06 override anchor ───
  // Exercises the cat_other_expense → cat_other_other override path in
  // VoiceCategoryResolver._ensureL2 via a real seeded corpus utterance.
  group('D-15 other-expense override (Phase 23 / IN-06)', () {
    test('D-15: "その他" -> cat_other_other override (Phase 23)', () async {
      final result = await resolver.resolve('その他');
      expect(result, isNotNull,
          reason: 'Phase 23 D-15: その他 must seed-route through cat_other_expense '
              'override to cat_other_other');
      expect(result!.categoryId, 'cat_other_other');
    });
  });

  tearDownAll(() {
    container.dispose();
    final pct = totalCount == 0 ? 0.0 : (passCount / totalCount * 100);
    // Print is the deliberate test reporter output per Phase 20 pattern.
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    // ignore: avoid_print
    print('ja category corpus: $passCount/$totalCount (${pct.toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    expect(
      totalCount == 0 ? 0.0 : passCount / totalCount,
      greaterThanOrEqualTo(0.95),
      reason:
          'VOICE-04/05/06: ja category corpus accuracy ${pct.toStringAsFixed(1)}% < 95%',
    );
  });
}
