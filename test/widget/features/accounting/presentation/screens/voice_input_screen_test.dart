import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

class FakeStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async => true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class FakeDeniedStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async => false;

  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class CapturingStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  void Function(String status)? onStatus;
  void Function(String errorMsg, bool permanent)? onError;
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(double normalizedLevel)? onSoundLevel;
  String? startedLocaleId;
  var stopped = false;
  var canceled = false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    this.onStatus = onStatus;
    this.onError = onError;
    return true;
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => startedLocaleId != null && !stopped;

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    this.onResult = onResult;
    this.onSoundLevel = onSoundLevel;
    startedLocaleId = localeId;
    stopped = false;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  void emitPartial(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.9)], false),
  );

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );
}

class FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  FakeParseVoiceInputUseCase(this.results);

  final Map<String, VoiceParseResult> results;
  final inputs = <String>[];

  @override
  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    inputs.add(recognizedText);
    return Result.success(results[recognizedText]);
  }
}

class FakeVoiceSatisfactionEstimator implements VoiceSatisfactionEstimator {
  VoiceAudioFeatures? lastFeatures;
  String? lastRecognizedText;

  @override
  int estimate({
    required VoiceAudioFeatures audioFeatures,
    required String recognizedText,
  }) {
    lastFeatures = audioFeatures;
    lastRecognizedText = recognizedText;
    return 9;
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final _categories = {
    'food': Category(
      id: 'food',
      name: 'Food',
      icon: 'restaurant',
      color: '#F59E0B',
      level: 1,
      createdAt: DateTime(2026),
    ),
    'dining': Category(
      id: 'dining',
      name: 'Dining',
      icon: 'restaurant_menu',
      color: '#F59E0B',
      parentId: 'food',
      level: 2,
      createdAt: DateTime(2026),
    ),
  };

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Category>> findActive() async => [];

  @override
  Future<List<Category>> findAll() async => [];

  @override
  Future<Category?> findById(String id) async => _categories[id];

  @override
  Future<List<Category>> findByLevel(int level) async => [];

  @override
  Future<List<Category>> findByParent(String parentId) async => [];

  @override
  Future<void> insert(Category category) async {}

  @override
  Future<void> insertBatch(List<Category> categories) async {}

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

void main() {
  Widget buildSubject({
    required StartSpeechRecognitionUseCase speechService,
    Locale locale = const Locale('ja'),
    FakeParseVoiceInputUseCase? parseUseCase,
    FakeVoiceSatisfactionEstimator? satisfactionEstimator,
  }) {
    return createLocalizedWidget(
      VoiceInputScreen(bookId: 'book-1', speechService: speechService),
      locale: locale,
      overrides: [
        categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
        if (parseUseCase != null)
          parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
        if (satisfactionEstimator != null)
          voiceSatisfactionEstimatorProvider.overrideWithValue(
            satisfactionEstimator,
          ),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
      ],
    );
  }

  VoiceParseResult parsedResult({
    required String rawText,
    LedgerType ledgerType = LedgerType.survival,
  }) {
    return VoiceParseResult(
      rawText: rawText,
      amount: 1280,
      parsedDate: DateTime(2026, 4, 27),
      merchantName: 'Cafe',
      categoryMatch: const CategoryMatchResult(
        categoryId: 'dining',
        confidence: 0.91,
        source: MatchSource.keyword,
      ),
      ledgerType: ledgerType,
    );
  }

  testWidgets('parses partial speech with configured voice locale', (
    tester,
  ) async {
    final speechService = CapturingStartSpeechRecognitionUseCase();
    final parseUseCase = FakeParseVoiceInputUseCase({
      'Cafe 1280 yen': parsedResult(rawText: 'Cafe 1280 yen'),
    });

    await tester.pumpWidget(
      buildSubject(speechService: speechService, parseUseCase: parseUseCase),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    speechService.onSoundLevel!(0.7);
    speechService.emitPartial('Cafe 1280 yen');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(speechService.startedLocaleId, 'ja-JP');
    expect(parseUseCase.inputs, contains('Cafe 1280 yen'));
    expect(find.text('Cafe 1280 yen'), findsOneWidget);
    expect(find.textContaining('Dining'), findsOneWidget);
  });

  testWidgets('parses final survival speech and stops on status update', (
    tester,
  ) async {
    final speechService = CapturingStartSpeechRecognitionUseCase();
    final parseUseCase = FakeParseVoiceInputUseCase({
      'Cafe 1280 yen': parsedResult(rawText: 'Cafe 1280 yen'),
    });

    await tester.pumpWidget(
      buildSubject(speechService: speechService, parseUseCase: parseUseCase),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    speechService.emitFinal('Cafe 1280 yen');
    await tester.pumpAndSettle();
    speechService.onStatus!('done');
    await tester.pump();

    expect(parseUseCase.inputs, contains('Cafe 1280 yen'));
    expect(find.text('Cafe 1280 yen'), findsOneWidget);
    expect(find.textContaining('Dining'), findsOneWidget);
    expect(find.textContaining('1,280'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('soul ledger final speech estimates satisfaction from audio', (
    tester,
  ) async {
    final speechService = CapturingStartSpeechRecognitionUseCase();
    final estimator = FakeVoiceSatisfactionEstimator();
    final parseUseCase = FakeParseVoiceInputUseCase({
      'really happy Cafe 1280 yen': parsedResult(
        rawText: 'really happy Cafe 1280 yen',
        ledgerType: LedgerType.soul,
      ),
    });

    await tester.pumpWidget(
      buildSubject(
        speechService: speechService,
        parseUseCase: parseUseCase,
        satisfactionEstimator: estimator,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    speechService.onSoundLevel!(0.2);
    await tester.pump(const Duration(milliseconds: 120));
    speechService.onSoundLevel!(0.8);
    speechService.emitPartial('really happy');
    await tester.pump();
    speechService.emitFinal('really happy Cafe 1280 yen');
    await tester.pumpAndSettle();

    expect(estimator.lastRecognizedText, 'really happy Cafe 1280 yen');
    expect(estimator.lastFeatures?.soundLevels, isNotEmpty);
    expect(estimator.lastFeatures?.partialResultCount, 1);
    expect(estimator.lastFeatures?.wordCount, 2);
  });

  testWidgets('voice input screen shows unified recognition card skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        VoiceInputScreen(
          bookId: 'book-1',
          speechService: FakeStartSpeechRecognitionUseCase(),
        ),
        locale: const Locale('ja'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('認識結果'), findsOneWidget);
    expect(find.text('金額'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.text('日付'), findsOneWidget);
    expect(find.text('タップして録音'), findsOneWidget);
  });

  testWidgets('shows Japanese localized microphone permission toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(speechService: FakeDeniedStartSpeechRecognitionUseCase()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));

    expect(find.text(l10n.voiceMicrophonePermissionRequired), findsOneWidget);
  });

  testWidgets('shows English localized microphone permission toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        speechService: FakeDeniedStartSpeechRecognitionUseCase(),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));

    expect(find.text(l10n.voiceMicrophonePermissionRequired), findsOneWidget);
  });
}
