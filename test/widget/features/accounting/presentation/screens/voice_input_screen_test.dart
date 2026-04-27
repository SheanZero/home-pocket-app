import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
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

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Category>> findActive() async => [];

  @override
  Future<List<Category>> findAll() async => [];

  @override
  Future<Category?> findById(String id) async => null;

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
  }) {
    return createLocalizedWidget(
      VoiceInputScreen(bookId: 'book-1', speechService: speechService),
      locale: locale,
      overrides: [
        categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
      ],
    );
  }

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
