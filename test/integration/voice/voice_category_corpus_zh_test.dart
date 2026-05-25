import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';

import '../../fixtures/voice_category_corpus_zh.dart';
import '../../helpers/test_provider_scope.dart';

/// Phase 21 D-10 corpus test (zh) for VoiceCategoryResolver.
///
/// Anchor cases (5) get strict, individual `test()` blocks — hard failures.
/// Statistical bucket aggregates non-anchor cases under a per-locale ≥95%
/// accuracy gate (mirrors Phase 20 corpus pattern).
///
/// The zh fixture's anchor #4 (`咖啡 -> cat_hobbies_subscription`) is the
/// learned-override case — `setUpAll` inserts the learned mapping with
/// hitCount=3 via `recordCorrection` so the DAO's `hitCount DESC` ordering
/// makes the learned row win over the seed `咖啡 -> cat_food_cafe` entry.
///
/// VOICE-06 extensibility — a dedicated test inserts a fresh `珍珠奶茶`
/// keyword at runtime (not in DefaultVoiceSynonyms) and asserts the resolver
/// picks it up without any resolver-code change (data source extensible by
/// adding rows to category_keyword_preferences).
void main() {
  late final container = createTestProviderScope();
  late VoiceCategoryResolver resolver;
  late CategoryKeywordPreferenceRepository prefRepo;

  var passCount = 0;
  var totalCount = 0;

  setUpAll(() async {
    // Seed categories first (synonyms reference these categoryIds).
    await container.read(seedCategoriesUseCaseProvider).execute();
    // Seed default voice synonyms (DefaultVoiceSynonyms.all -> hitCount=0).
    await container.read(seedVoiceSynonymsUseCaseProvider).execute();
    prefRepo = container.read(categoryKeywordPreferenceRepositoryProvider);
    // VoiceCategoryResolverProvider is added in Plan 21-05 — construct directly
    // here so this corpus test is independent of that wiring.
    resolver = VoiceCategoryResolver(
      categoryRepository: container.read(categoryRepositoryProvider),
      preferenceRepository: prefRepo,
      categoryService: container.read(categoryServiceProvider),
      merchantDatabase: MerchantDatabase(),
    );

    // Learned-override anchor setup: record 3 corrections so the learned row
    // (hitCount=3) wins over the seed `咖啡 -> cat_food_cafe` (hitCount=0).
    await prefRepo.recordCorrection(
      keyword: '咖啡',
      categoryId: 'cat_hobbies_subscription',
    );
    await prefRepo.recordCorrection(
      keyword: '咖啡',
      categoryId: 'cat_hobbies_subscription',
    );
    await prefRepo.recordCorrection(
      keyword: '咖啡',
      categoryId: 'cat_hobbies_subscription',
    );
  });

  Future<String?> resolveCategory(String input, String keyword) async {
    // WR-04: resolver.resolve() now takes only the extracted keyword. The
    // corpus fixture pre-extracts the keyword, so we drop inputText.
    final r = await resolver.resolve(keyword);
    return r?.categoryId;
  }

  // ─── Anchor cases — strict, individual test() blocks ───
  group('zh anchor cases (VOICE-04 / VOICE-05 / VOICE-06)', () {
    final anchors = voiceCategoryCorpusZh
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
  group('zh statistical corpus (≥95% accuracy gate)', () {
    final nonAnchors = voiceCategoryCorpusZh
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
      // 珍珠奶茶 is NOT in DefaultVoiceSynonyms — insert at runtime.
      await prefRepo.recordCorrection(
        keyword: '珍珠奶茶',
        categoryId: 'cat_food_drinks',
      );
      final actual = await resolver.resolve('珍珠奶茶');
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
    test('D-15: "其他" -> cat_other_other override (Phase 23)', () async {
      final result = await resolver.resolve('其他');
      expect(result, isNotNull,
          reason: 'Phase 23 D-15: 其他 must seed-route through cat_other_expense '
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
    print('zh category corpus: $passCount/$totalCount (${pct.toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    expect(
      totalCount == 0 ? 0.0 : passCount / totalCount,
      greaterThanOrEqualTo(0.95),
      reason:
          'VOICE-04/05/06: zh category corpus accuracy ${pct.toStringAsFixed(1)}% < 95%',
    );
  });
}
