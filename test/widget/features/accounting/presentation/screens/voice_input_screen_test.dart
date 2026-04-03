import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/settings_providers.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../../helpers/test_localizations.dart';

class FakeSpeechRecognitionService implements SpeechRecognitionService {
  @override
  Future<List<stt.LocaleName>> getAvailableLocales() async => [];

  @override
  Future<bool> initialize({
    void Function(String p1)? onStatus,
    void Function(String p1, bool p2)? onError,
  }) async => true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  double normalizeSoundLevelForTest(
    double rawLevel, {
    required bool isAndroid,
  }) {
    return 0;
  }

  @override
  Future<void> cancelListening() async {}

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {}

  @override
  Future<void> stopListening() async {}
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
}

void main() {
  testWidgets('voice input screen shows unified recognition card skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        VoiceInputScreen(
          bookId: 'book-1',
          speechService: FakeSpeechRecognitionService(),
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
}
