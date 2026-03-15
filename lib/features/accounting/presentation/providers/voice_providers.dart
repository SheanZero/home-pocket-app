import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/voice/fuzzy_category_matcher.dart';
import '../../../../application/voice/parse_voice_input_use_case.dart';
import '../../../../application/voice/voice_satisfaction_estimator.dart';
import '../../../../application/voice/voice_text_parser.dart';
import '../../../../infrastructure/ml/merchant_database.dart';
import 'repository_providers.dart';
import 'use_case_providers.dart';

part 'voice_providers.g.dart';

/// MerchantDatabase — keepAlive because it holds an in-memory seed dataset.
/// Instantiated once and reused across the app session.
@Riverpod(keepAlive: true)
MerchantDatabase merchantDatabase(Ref ref) {
  return MerchantDatabase();
}

/// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.
@riverpod
VoiceTextParser voiceTextParser(Ref ref) {
  return VoiceTextParser();
}

/// FuzzyCategoryMatcher — multi-signal category matcher with learning.
@riverpod
FuzzyCategoryMatcher fuzzyCategoryMatcher(Ref ref) {
  return FuzzyCategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    preferenceRepository: ref.watch(
      categoryKeywordPreferenceRepositoryProvider,
    ),
    categoryService: ref.watch(categoryServiceProvider),
  );
}

/// ParseVoiceInputUseCase — wired to all voice application services.
@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    fuzzyCategoryMatcher: ref.watch(fuzzyCategoryMatcherProvider),
    merchantDatabase: ref.watch(merchantDatabaseProvider),
  );
}

/// VoiceSatisfactionEstimator — pure stateless class.
@riverpod
VoiceSatisfactionEstimator voiceSatisfactionEstimator(Ref ref) {
  return VoiceSatisfactionEstimator();
}

