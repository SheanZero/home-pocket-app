/// Phase 23 D-15 / IN-06 — single-case hedge skeleton.
///
/// Voice gating in v1.3 is zh/ja only; this file proves the override is
/// wired in case v1.4+ enables en voice. Do NOT expand en corpus coverage
/// beyond this case (CONTEXT.md D-15). RESEARCH Pitfall 6: future en work
/// must add "the other day" regression cases — 'other' is a common English
/// word that may collide with contextual utterances.
///
/// Resolver setup pattern follows voice_category_corpus_zh_test.dart (leaf
/// providers, direct VoiceCategoryResolver construction). No fixture file
/// needed — single inline test per RESEARCH Open Q4.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';

import '../../helpers/test_provider_scope.dart';

void main() {
  late final container = createTestProviderScope();
  late VoiceCategoryResolver resolver;

  setUpAll(() async {
    // Seed categories first (synonyms reference these categoryIds).
    await container.read(seedCategoriesUseCaseProvider).execute();
    // Seed default voice synonyms (DefaultVoiceSynonyms.all → hitCount=0).
    // 'other' seed row was added in Phase 23 D-15 / IN-06.
    await container.read(seedVoiceSynonymsUseCaseProvider).execute();
    resolver = VoiceCategoryResolver(
      categoryRepository: container.read(categoryRepositoryProvider),
      preferenceRepository:
          container.read(categoryKeywordPreferenceRepositoryProvider),
      categoryService: container.read(categoryServiceProvider),
      merchantDatabase: MerchantDatabase(),
    );
  });

  tearDownAll(() {
    container.dispose();
  });

  // ─── Phase 23 D-15 / IN-06 — en override anchor ───
  // Exercises the cat_other_expense → cat_other_other override in
  // VoiceCategoryResolver._ensureL2 via the seeded 'other' synonym.
  group('en hedge corpus (Phase 23 D-15 / IN-06)', () {
    test('"other" -> cat_other_other (en voice hedge)', () async {
      final result = await resolver.resolve('other');
      expect(result, isNotNull,
          reason: 'Phase 23 D-15: "other" must seed-route through '
              'cat_other_expense override to cat_other_other');
      expect(result!.categoryId, 'cat_other_other');
    });
  });
}
