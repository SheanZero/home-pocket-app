import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/accounting/presentation/providers/repository_providers.dart';
import 'seed_all_use_case.dart';

part 'seed_providers.g.dart';

/// Phase 23 D-14: Riverpod provider for [SeedAllUseCase].
///
/// Composes the two existing leaf providers via [ref.watch] so the ordering
/// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.
@riverpod
SeedAllUseCase seedAllUseCase(Ref ref) {
  return SeedAllUseCase(
    seedCategories: ref.watch(seedCategoriesUseCaseProvider),
    seedVoiceSynonyms: ref.watch(seedVoiceSynonymsUseCaseProvider),
  );
}
