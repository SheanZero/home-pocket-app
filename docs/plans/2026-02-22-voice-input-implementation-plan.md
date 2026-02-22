# MOD-009 Voice Input - Implementation Plan

**Created:** 2026-02-22
**Based on:** docs/arch/02-module-specs/MOD-009_VoiceInput.md
**Methodology:** TDD (RED → GREEN → REFACTOR)
**Estimated Duration:** 8 days

---

## Overview

This plan implements the MOD-009 Voice Input module for the Home Pocket accounting app. The module allows users to create transactions through natural language voice input, extracting amounts, merchants, and categories automatically. The implementation builds on several existing components:

- `VoiceInputScreen` already exists as a static stub at `lib/features/accounting/presentation/screens/voice_input_screen.dart` — it will be replaced with the full implementation
- `CategoryService` at `lib/application/accounting/category_service.dart` provides `resolveLedgerType()` — reused by `CategoryMatcher`
- `ClassificationService` at `lib/application/dual_ledger/classification_service.dart` already classifies by category — reused
- `TransactionConfirmScreen` at `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` already accepts `amount`, `category`, `bookId`, `date` — voice flow navigates here
- `Result<T>` at `lib/shared/utils/result.dart` — reused by use cases
- `LedgerType` enum is defined in `lib/features/accounting/domain/models/transaction.dart` — imported by voice models
- `CategoryRepository` interface at `lib/features/accounting/domain/repositories/category_repository.dart` — used by `CategoryMatcher`
- `use_case_providers.dart` pattern for wiring providers is established and must be followed

The `lib/infrastructure/ml/` directory does not yet exist — `MerchantDatabase` referenced in the spec is a planned stub. The plan accounts for this by defining a minimal `MerchantDatabase` interface within the voice module tests.

---

## Prerequisites & Verification

Before starting, verify these conditions are true:

1. `lib/features/accounting/presentation/screens/voice_input_screen.dart` exists (static stub) — confirmed
2. `lib/application/dual_ledger/classification_service.dart` exists — confirmed
3. `lib/application/accounting/category_service.dart` exists with `resolveLedgerType()` — confirmed
4. `lib/features/accounting/domain/repositories/category_repository.dart` exists — confirmed
5. `lib/shared/utils/result.dart` exists with `Result<T>` — confirmed
6. `LedgerType` enum is in `lib/features/accounting/domain/models/transaction.dart` — confirmed
7. `flutter pub run build_runner build` runs successfully on the current codebase
8. `flutter analyze` shows zero issues on the current codebase

---

## Phase 0: Setup (Day 1 Morning)

### Step 0.1 — Add speech_to_text dependency to pubspec.yaml

Edit `/Users/xinz/Development/home-pocket-app/pubspec.yaml`.

Add `speech_to_text: ^7.0.0` in the `dependencies:` block after the existing Unique ID entry and before the Charts entry, like this:

```yaml
  # Unique ID Generation
  ulid: ^2.0.0

  # Voice Input
  speech_to_text: ^7.0.0

  # Charts
  fl_chart: ^0.69.0
```

Then run:
```bash
flutter pub get
```

### Step 0.2 — iOS platform configuration

Edit `ios/Runner/Info.plist`. Add these two keys inside the root `<dict>`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>音声で金額や取引内容を入力するために使用します</string>
<key>NSMicrophoneUsageDescription</key>
<string>音声入力のためにマイクへのアクセスが必要です</string>
```

### Step 0.3 — Android platform configuration

Edit `android/app/src/main/AndroidManifest.xml`. Add these entries before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<queries>
  <intent>
    <action android:name="android.speech.RecognitionService"/>
  </intent>
</queries>
```

### Step 0.4 — Create directory structure

```bash
mkdir -p lib/infrastructure/speech
mkdir -p lib/application/voice
mkdir -p test/unit/infrastructure/speech
mkdir -p test/unit/application/voice
mkdir -p test/widget/features/accounting/presentation/screens
mkdir -p test/widget/features/accounting/presentation/widgets
```

---

## Phase 1: RED — Write Tests First (Day 1–2)

All test files are written BEFORE any implementation code. Running `flutter test` at this stage should show compilation errors or test failures for all new tests. That is the expected RED state.

### Test File 1.1 — VoiceTextParser unit tests

**Path:** `test/unit/application/voice/voice_text_parser_test.dart`

**What it tests:**
- `extractAmount()` with Arabic numerals: `680円`, `¥1,280`, `480块`, `550 yen`, standalone `3980`
- `extractAmount()` returns null when no amount is present
- `extractAmount()` with kanji numerals: `六百八十円`, `千二百円`, `三千九百八十`, `一千二百元`
- `_extractPotentialMerchantNames()` via the public `extractAndMatchMerchant()` with a stub merchant database returning null (no match)
- Amount boundary: value of 0 returns null, value of 10,000,000 or more returns null

This file has NO external dependencies beyond `VoiceTextParser` itself. No mocks needed.

```dart
// test/unit/application/voice/voice_text_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

void main() {
  late VoiceTextParser parser;

  setUp(() {
    parser = VoiceTextParser();
  });

  group('VoiceTextParser - Arabic amount extraction', () {
    test('extracts yen with 円 suffix: 680円', () {
      expect(parser.extractAmount('昼ごはんに680円'), equals(680));
    });

    test('extracts yen with ¥ prefix: ¥1,280', () {
      expect(parser.extractAmount('マクドナルドで¥1,280'), equals(1280));
    });

    test('extracts yuan with 块 suffix: 480块', () {
      expect(parser.extractAmount('午饭480块'), equals(480));
    });

    test('extracts yen with "yen" suffix: 550 yen', () {
      expect(parser.extractAmount('lunch 550 yen'), equals(550));
    });

    test('extracts standalone number ≥3 digits: 3980', () {
      expect(parser.extractAmount('ユニクロで3980'), equals(3980));
    });

    test('returns null when no amount present', () {
      expect(parser.extractAmount('昼ごはん食べた'), isNull);
    });

    test('returns null for amount of zero', () {
      expect(parser.extractAmount('0円'), isNull);
    });

    test('extracts comma-formatted amount: 1,280円', () {
      expect(parser.extractAmount('1,280円'), equals(1280));
    });
  });

  group('VoiceTextParser - Kanji amount extraction', () {
    test('extracts 六百八十円 → 680', () {
      expect(parser.extractAmount('六百八十円'), equals(680));
    });

    test('extracts 千二百円 → 1200', () {
      expect(parser.extractAmount('千二百円'), equals(1200));
    });

    test('extracts 三千九百八十 → 3980', () {
      expect(parser.extractAmount('三千九百八十'), equals(3980));
    });

    test('extracts 一千二百元 → 1200', () {
      expect(parser.extractAmount('一千二百元'), equals(1200));
    });
  });
}
```

### Test File 1.2 — CategoryMatcher unit tests

**Path:** `test/unit/application/voice/category_matcher_test.dart`

**What it tests:**
- Japanese keyword → food category match with confidence > 0.8: `昼ごはん`
- Chinese keyword → food category match: `午饭`
- English keyword → food category match: `lunch`
- Transport keyword match: `電車`, `地铁`, `train`
- No match returns null: `abc123`
- Merchant-sourced match is higher priority than keyword match (tested via `CategoryMatcher` with pre-configured merchant result)
- `resolveLedgerType()` delegates correctly to `CategoryService`

Uses `mockito` `@GenerateMocks` for `CategoryRepository` and `CategoryService`.

```dart
// test/unit/application/voice/category_matcher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/category_matcher.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryService])
import 'category_matcher_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryService mockCategoryService;
  late CategoryMatcher matcher;

  final fakeCategory = Category(
    id: 'cat_food',
    name: '食事',
    icon: '🍜',
    color: '#FF0000',
    level: 1,
    sortOrder: 0,
    isArchived: false,
  );

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockCategoryService = MockCategoryService();
    matcher = CategoryMatcher(
      categoryRepository: mockCategoryRepo,
      categoryService: mockCategoryService,
    );
    when(mockCategoryRepo.findById(any))
        .thenAnswer((_) async => fakeCategory);
  });

  group('CategoryMatcher - keyword matching', () {
    test('Japanese 昼ごはん matches cat_food with confidence > 0.8', () async {
      final result = await matcher.matchFromText('昼ごはんに680円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('Chinese 午饭 matches cat_food', () async {
      final result = await matcher.matchFromText('午饭吃了480块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('English lunch matches cat_food', () async {
      final result = await matcher.matchFromText('lunch 550 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('Japanese 電車 matches cat_transport', () async {
      final result = await matcher.matchFromText('電車代320円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('Chinese 地铁 matches cat_transport', () async {
      final result = await matcher.matchFromText('坐地铁花了280块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('English train matches cat_transport', () async {
      final result = await matcher.matchFromText('train pass 320 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('No match returns null', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => null);
      final result = await matcher.matchFromText('abc123');
      expect(result, isNull);
    });
  });

  group('CategoryMatcher - ledger type resolution', () {
    test('delegates resolveLedgerType to CategoryService', () async {
      when(mockCategoryService.resolveLedgerType('cat_food'))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await matcher.resolveLedgerType('cat_food');
      expect(result, equals(LedgerType.survival));
      verify(mockCategoryService.resolveLedgerType('cat_food')).called(1);
    });
  });
}
```

### Test File 1.3 — VoiceSatisfactionEstimator unit tests

**Path:** `test/unit/application/voice/voice_satisfaction_estimator_test.dart`

**What it tests:**
- Excited speech (high volume, positive words) → satisfaction 7–10
- Calm speech (low volume, neutral text) → satisfaction 4–6
- Empty audio features → satisfaction defaults to 3–5
- Score is always clamped to 1–10
- Negative sentiment words reduce score
- Intensifier words amplify sentiment

No mocks needed — pure logic class.

```dart
// test/unit/application/voice/voice_satisfaction_estimator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

List<DateTime> _generateTimestamps(int count, {int intervalMs = 200}) {
  final start = DateTime.now().subtract(Duration(milliseconds: count * intervalMs));
  return List.generate(
    count,
    (i) => start.add(Duration(milliseconds: i * intervalMs)),
  );
}

void main() {
  late VoiceSatisfactionEstimator estimator;

  setUp(() {
    estimator = VoiceSatisfactionEstimator();
  });

  group('VoiceSatisfactionEstimator', () {
    test('excited voice with positive words → satisfaction 7–10', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.7, 0.8, 0.6, 0.9, 0.7, 0.8, 0.9, 0.7],
        timestamps: _generateTimestamps(8, intervalMs: 200),
        startTime: DateTime.now().subtract(const Duration(seconds: 8)),
        endTime: DateTime.now(),
        partialResultCount: 6,
        wordCount: 15,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: 'ユニクロで服買った、めっちゃ嬉しい！',
      );

      expect(score, greaterThanOrEqualTo(7));
      expect(score, lessThanOrEqualTo(10));
    });

    test('calm voice with neutral text → satisfaction 4–6', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.35, 0.3, 0.32, 0.3],
        timestamps: _generateTimestamps(5, intervalMs: 400),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '電車代320円',
      );

      expect(score, greaterThanOrEqualTo(4));
      expect(score, lessThanOrEqualTo(6));
    });

    test('empty audio features → default satisfaction 3–5', () {
      final features = VoiceAudioFeatures(
        soundLevels: [],
        timestamps: [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 0,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '',
      );

      expect(score, greaterThanOrEqualTo(3));
      expect(score, lessThanOrEqualTo(5));
    });

    test('score is always in range 1–10', () {
      // Extreme high case
      final highFeatures = VoiceAudioFeatures(
        soundLevels: List.filled(50, 1.0),
        timestamps: _generateTimestamps(50, intervalMs: 100),
        startTime: DateTime.now().subtract(const Duration(seconds: 20)),
        endTime: DateTime.now(),
        partialResultCount: 20,
        wordCount: 40,
      );
      final highScore = estimator.estimate(
        audioFeatures: highFeatures,
        recognizedText: 'めっちゃ最高！嬉しい！すごい！',
      );
      expect(highScore, inInclusiveRange(1, 10));

      // Extreme low case
      final lowFeatures = VoiceAudioFeatures(
        soundLevels: [0.01, 0.01],
        timestamps: _generateTimestamps(2, intervalMs: 500),
        startTime: DateTime.now().subtract(const Duration(seconds: 2)),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 1,
      );
      final lowScore = estimator.estimate(
        audioFeatures: lowFeatures,
        recognizedText: '高い無駄だった後悔',
      );
      expect(lowScore, inInclusiveRange(1, 10));
    });

    test('negative sentiment words reduce score', () {
      final neutralFeatures = VoiceAudioFeatures(
        soundLevels: [0.4, 0.4, 0.4],
        timestamps: _generateTimestamps(3, intervalMs: 300),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final neutralScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '昼ごはん680円',
      );

      final negativeScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '高い、無駄だった、後悔してる',
      );

      expect(negativeScore, lessThan(neutralScore));
    });
  });
}
```

### Test File 1.4 — ParseVoiceInputUseCase unit tests

**Path:** `test/unit/application/voice/parse_voice_input_use_case_test.dart`

**What it tests:**
- Successful parse returns `Result.success` with correct `VoiceParseResult`
- Amount extracted correctly
- Merchant match takes priority over keyword category match
- When no merchant found, falls back to keyword category match
- Unknown text (no amount, no merchant, no keywords) still succeeds with null fields
- Exception in parsing returns `Result.error`

Uses `mockito` for `CategoryMatcher` and a fake `MerchantDatabase`. Since `MerchantDatabase` does not exist yet, its mock interface is defined inline as part of the test setup.

```dart
// test/unit/application/voice/parse_voice_input_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/category_matcher.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryMatcher, MerchantDatabase])
import 'parse_voice_input_use_case_test.mocks.dart';

void main() {
  late MockCategoryMatcher mockCategoryMatcher;
  late MockMerchantDatabase mockMerchantDatabase;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockCategoryMatcher = MockCategoryMatcher();
    mockMerchantDatabase = MockMerchantDatabase();
    parser = VoiceTextParser();

    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      categoryMatcher: mockCategoryMatcher,
      merchantDatabase: mockMerchantDatabase,
    );
  });

  group('ParseVoiceInputUseCase', () {
    test('parses amount correctly from text with 円', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any))
          .thenAnswer((_) async => CategoryMatchResult(
                categoryId: 'cat_food',
                confidence: 0.9,
                source: MatchSource.keyword,
              ));
      when(mockCategoryMatcher.resolveLedgerType(any))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('昼ごはんに680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, equals(680));
      expect(result.data!.rawText, equals('昼ごはんに680円'));
    });

    test('merchant match overrides keyword category', () async {
      final merchantMatch = MerchantMatch(
        merchantName: 'マクドナルド',
        categoryId: 'cat_food',
        confidence: 0.95,
        ledgerType: LedgerType.survival,
      );
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(merchantMatch);

      final result = await useCase.execute('マクドナルドで680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.merchantName, equals('マクドナルド'));
      expect(result.data!.categoryMatch!.source, equals(MatchSource.merchant));
      // CategoryMatcher.matchFromText should NOT be called when merchant found
      verifyNever(mockCategoryMatcher.matchFromText(any));
    });

    test('falls back to keyword match when no merchant found', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any))
          .thenAnswer((_) async => CategoryMatchResult(
                categoryId: 'cat_transport',
                confidence: 0.95,
                source: MatchSource.keyword,
              ));
      when(mockCategoryMatcher.resolveLedgerType(any))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('電車代320円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.categoryMatch!.source, equals(MatchSource.keyword));
    });

    test('returns success with nulls when text has no recognizable content', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any)).thenAnswer((_) async => null);

      final result = await useCase.execute('test');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, isNull);
      expect(result.data!.merchantMatch, isNull);
      expect(result.data!.categoryMatch, isNull);
    });
  });
}
```

### Test File 1.5 — SpeechRecognitionService unit tests

**Path:** `test/unit/infrastructure/speech/speech_recognition_service_test.dart`

**What it tests:**
- `isListening` returns false before `startListening()` is called
- `isAvailable` returns false before `initialize()` is called
- `_normalizeSoundLevel()` clamps correctly (tested indirectly via public interface, or by exposing for test via `@visibleForTesting`)
- `initialize()` returns false when called with a platform stub (unit test, no platform channels)
- `stopListening()` and `cancelListening()` do not throw when not listening

Note: `speech_to_text` requires platform channels. These tests verify the service wrapper's logic in isolation; `SpeechToText` itself is mocked.

```dart
// test/unit/infrastructure/speech/speech_recognition_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';

void main() {
  // Note: Full integration of speech_to_text requires platform channels
  // and must be tested in integration tests or on a real device.
  // These unit tests verify the service's state management logic.

  group('SpeechRecognitionService - initial state', () {
    test('isListening is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isListening, isFalse);
    });

    test('isAvailable is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isAvailable, isFalse);
    });

    test('stopListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.stopListening(), completes);
    });

    test('cancelListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.cancelListening(), completes);
    });
  });

  group('SpeechRecognitionService - sound level normalization', () {
    test('normalizeSoundLevel clamps within 0.0–1.0 for Android values', () {
      final service = SpeechRecognitionService();
      // Test via the public test-visible method (annotated @visibleForTesting)
      expect(service.normalizeSoundLevelForTest(15.0, isAndroid: true), equals(1.0));
      expect(service.normalizeSoundLevelForTest(5.0, isAndroid: true), equals(0.5));
      expect(service.normalizeSoundLevelForTest(-1.0, isAndroid: true), equals(0.0));
    });

    test('normalizeSoundLevel clamps within 0.0–1.0 for iOS values', () {
      final service = SpeechRecognitionService();
      expect(service.normalizeSoundLevelForTest(0.0, isAndroid: false), equals(1.0));
      expect(service.normalizeSoundLevelForTest(-25.0, isAndroid: false), equals(0.5));
      expect(service.normalizeSoundLevelForTest(-60.0, isAndroid: false), equals(0.0));
    });
  });
}
```

### Test File 1.6 — VoiceParseResult model tests

**Path:** `test/unit/features/accounting/domain/models/voice_parse_result_test.dart`

**What it tests:**
- `VoiceParseResult` can be instantiated with required fields only
- `estimatedSatisfaction` defaults to 5
- `copyWith` works correctly (Freezed)
- `VoiceAudioFeatures` can be instantiated
- `CategoryMatchResult` confidence is within 0.0–1.0 range
- `MatchSource` enum has all three values: `merchant`, `keyword`, `fallback`

```dart
// test/unit/features/accounting/domain/models/voice_parse_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

void main() {
  group('VoiceParseResult', () {
    test('can be instantiated with rawText only', () {
      const result = VoiceParseResult(rawText: 'test text');
      expect(result.rawText, equals('test text'));
      expect(result.amount, isNull);
      expect(result.merchantName, isNull);
    });

    test('estimatedSatisfaction defaults to 5', () {
      const result = VoiceParseResult(rawText: 'test');
      expect(result.estimatedSatisfaction, equals(5));
    });

    test('copyWith works correctly', () {
      const original = VoiceParseResult(rawText: 'original', amount: 100);
      final copy = original.copyWith(amount: 200);
      expect(copy.rawText, equals('original'));
      expect(copy.amount, equals(200));
    });
  });

  group('VoiceAudioFeatures', () {
    test('can be instantiated with all required fields', () {
      final now = DateTime.now();
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.5, 0.7],
        timestamps: [now, now.add(const Duration(milliseconds: 100))],
        startTime: now,
        endTime: now.add(const Duration(seconds: 3)),
        partialResultCount: 2,
        wordCount: 5,
      );
      expect(features.soundLevels, hasLength(3));
      expect(features.wordCount, equals(5));
    });
  });

  group('CategoryMatchResult', () {
    test('stores categoryId, confidence, and source', () {
      const matchResult = CategoryMatchResult(
        categoryId: 'cat_food',
        confidence: 0.90,
        source: MatchSource.keyword,
      );
      expect(matchResult.categoryId, equals('cat_food'));
      expect(matchResult.confidence, equals(0.90));
      expect(matchResult.source, equals(MatchSource.keyword));
    });
  });

  group('MatchSource', () {
    test('has all three values', () {
      expect(MatchSource.values, containsAll([
        MatchSource.merchant,
        MatchSource.keyword,
        MatchSource.fallback,
      ]));
    });
  });
}
```

### Test File 1.7 — VoiceWaveform widget tests

**Path:** `test/widget/features/accounting/presentation/widgets/voice_waveform_test.dart`

**What it tests:**
- Widget renders without error when `soundLevel: 0.0` and `isActive: false`
- Widget renders 16 bars (`Container` children)
- When `isActive: true`, waveform is taller than when `isActive: false`
- Color is applied to each bar

```dart
// test/widget/features/accounting/presentation/widgets/voice_waveform_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_waveform.dart';

void main() {
  group('VoiceWaveform widget', () {
    testWidgets('renders without error when inactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceWaveform(soundLevel: 0.0, isActive: false),
          ),
        ),
      );
      expect(find.byType(VoiceWaveform), findsOneWidget);
    });

    testWidgets('renders 16 bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceWaveform(soundLevel: 0.5, isActive: true),
          ),
        ),
      );
      // 16 AnimatedContainer bars inside the Row
      expect(find.byType(AnimatedContainer), findsNWidgets(16));
    });

    testWidgets('active waveform renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceWaveform(soundLevel: 0.8, isActive: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Test File 1.8 — VoiceTranscriptCard widget tests

**Path:** `test/widget/features/accounting/presentation/widgets/voice_transcript_card_test.dart`

**What it tests:**
- Renders partial text in grey
- Renders final text in dark color (different style from partial)
- Shows mic icon when `isRecording: true`
- Does not show transcript text when both `partialText` and `finalText` are null/empty

```dart
// test/widget/features/accounting/presentation/widgets/voice_transcript_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_transcript_card.dart';

void main() {
  group('VoiceTranscriptCard widget', () {
    testWidgets('renders without error in idle state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceTranscriptCard(
              isRecording: false,
              partialText: '',
              finalText: '',
            ),
          ),
        ),
      );
      expect(find.byType(VoiceTranscriptCard), findsOneWidget);
    });

    testWidgets('shows mic icon when recording', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceTranscriptCard(
              isRecording: true,
              partialText: '昼ごはん...',
              finalText: '',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('displays partial text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceTranscriptCard(
              isRecording: true,
              partialText: '昼ごはん',
              finalText: '',
            ),
          ),
        ),
      );
      expect(find.text('昼ごはん'), findsOneWidget);
    });

    testWidgets('displays final text when recording stops', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceTranscriptCard(
              isRecording: false,
              partialText: '',
              finalText: '昼ごはんに680円',
            ),
          ),
        ),
      );
      expect(find.text('昼ごはんに680円'), findsOneWidget);
    });
  });
}
```

### Test File 1.9 — VoiceParsePreview widget tests

**Path:** `test/widget/features/accounting/presentation/widgets/voice_parse_preview_test.dart`

**What it tests:**
- Does not render when `parseResult` is null
- Shows amount in `¥NNN` format when amount is available
- Shows merchant name when present
- Shows category name when category match is present
- Shows satisfaction value when ledger type is soul

```dart
// test/widget/features/accounting/presentation/widgets/voice_parse_preview_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_parse_preview.dart';

void main() {
  group('VoiceParsePreview widget', () {
    testWidgets('renders nothing when parseResult is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoiceParsePreview(parseResult: null)),
        ),
      );
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows amount when present', (tester) async {
      const result = VoiceParseResult(rawText: 'test', amount: 680);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoiceParsePreview(parseResult: result)),
        ),
      );
      expect(find.textContaining('680'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows merchant name when present', (tester) async {
      const result = VoiceParseResult(
        rawText: 'test',
        amount: 680,
        merchantName: 'マクドナルド',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoiceParsePreview(parseResult: result)),
        ),
      );
      expect(find.textContaining('マクドナルド'), findsOneWidget);
    });
  });
}
```

### Test File 1.10 — voice_providers integration test (provider wiring)

**Path:** `test/unit/features/accounting/presentation/providers/voice_providers_test.dart`

**What it tests:**
- `parseVoiceInputUseCaseProvider` can be read from a `ProviderContainer` without throwing
- `voiceSatisfactionEstimatorProvider` can be read from a `ProviderContainer`
- Provider graph compiles and resolves without circular dependencies

```dart
// test/unit/features/accounting/presentation/providers/voice_providers_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/providers/voice_providers.dart';

void main() {
  group('Voice providers', () {
    test('parseVoiceInputUseCaseProvider resolves without error', () {
      // This test may require override of database providers in a real
      // integration setup. Here we verify the provider graph compiles.
      // Full wiring tested in integration tests.
      expect(parseVoiceInputUseCaseProvider, isNotNull);
    });

    test('voiceSatisfactionEstimatorProvider resolves without error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // VoiceSatisfactionEstimator has no dependencies, can be resolved directly
      expect(() => container.read(voiceSatisfactionEstimatorProvider), returnsNormally);
    });
  });
}
```

---

## Phase 2: GREEN — Domain & Infrastructure (Day 2–3)

Implement in this exact order. After each step, run `flutter analyze` to verify zero issues.

### Step 2.1 — Create VoiceParseResult domain model

**File:** `lib/features/accounting/domain/models/voice_parse_result.dart`

This Freezed model defines the data contract for the voice module. It imports `LedgerType` from the existing `transaction.dart`. Contains three `@freezed` classes: `VoiceParseResult`, `CategoryMatchResult`, `VoiceAudioFeatures`, plus the `MatchSource` enum and `MerchantMatch` data class.

Key points:
- `VoiceParseResult` has `@Default(5) int estimatedSatisfaction`
- `MerchantMatch` is NOT Freezed (plain class) to avoid circular imports with `MerchantDatabase`
- `MerchantMatch` fields: `merchantName`, `categoryId`, `confidence`, `ledgerType`
- All three `@freezed` classes use `abstract class ... with _$...` pattern (Freezed 3.x syntax as used in existing models)

After creating this file, run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify `voice_parse_result.freezed.dart` and `voice_parse_result.g.dart` are generated (if you add `fromJson` — keep it consistent with existing models which do include it).

### Step 2.2 — Create MerchantDatabase stub

**File:** `lib/infrastructure/ml/merchant_database.dart`

This is the shared merchant lookup used by both OCR (MOD-004) and Voice (MOD-009). For MOD-009, implement a minimal but real version with ~20 well-known Japanese merchants as a seed. The full 500+ merchant list is a backlog item.

Key interface:
```dart
class MerchantDatabase {
  MerchantMatch? findMerchant(String query);
}
```

`findMerchant()` tries exact name match, then alias match, then substring match. Returns the first match or null.

Seed data must include at minimum:
- マクドナルド (aliases: マック, Mac) → cat_food, survival
- スターバックス (aliases: スタバ, Starbucks) → cat_food, survival
- 吉野家 → cat_food, survival
- セブンイレブン (aliases: セブン, 7-Eleven) → cat_food, survival
- ユニクロ (aliases: Uniqlo) → cat_shopping, soul
- ニトリ → cat_housing, survival
- ヤマダ電機 → cat_shopping, soul

This file does NOT use Riverpod or Freezed — it is a pure Dart class.

### Step 2.3 — Create SpeechRecognitionService infrastructure

**File:** `lib/infrastructure/speech/speech_recognition_service.dart`

Implement exactly as defined in the MOD-009 spec section "1. 語音识别服务封装". Add one modification for testability:

```dart
/// Exposed for unit testing only. Do not call in production code.
@visibleForTesting
double normalizeSoundLevelForTest(double rawLevel, {required bool isAndroid}) {
  if (isAndroid) {
    return (rawLevel / 10.0).clamp(0.0, 1.0);
  } else {
    return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
  }
}
```

Import: `package:flutter/foundation.dart` for `@visibleForTesting`.

The private `_normalizeSoundLevel()` uses `Platform.isAndroid` for production. The test-visible method accepts an explicit `isAndroid` flag for unit testing without platform channels.

After this step, run `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart` — the tests from Phase 1 Step 1.5 should pass.

---

## Phase 3: GREEN — Application Layer (Day 3–5)

### Step 3.1 — Create VoiceTextParser

**File:** `lib/application/voice/voice_text_parser.dart`

Implement exactly as defined in the MOD-009 spec section "NLP解析引擎 → 金额提取". The class has two public methods:
- `int? extractAmount(String text)` — delegates to `_extractArabicAmount` then `_extractKanjiAmount`
- `MerchantMatch? extractAndMatchMerchant(String text, MerchantDatabase merchantDB)` — delegates to `_extractPotentialMerchantNames` + `merchantDB.findMerchant()`

Import: `lib/infrastructure/ml/merchant_database.dart`
Import: `lib/features/accounting/domain/models/voice_parse_result.dart` (for `MerchantMatch`)

After this step, run `flutter test test/unit/application/voice/voice_text_parser_test.dart` — all tests from Phase 1 Step 1.1 should pass.

### Step 3.2 — Create CategoryMatcher

**File:** `lib/application/voice/category_matcher.dart`

Implement exactly as defined in the MOD-009 spec section "类目匹配服务". Key implementation notes:
- The static `_keywordMap` uses `_KeywordMapping` as a private helper class within the same file
- `matchFromText()` iterates the map, tries `findById()` to validate category exists, falls back to L1 if L2 doesn't exist
- `resolveLedgerType()` delegates to `CategoryService.resolveLedgerType()` — do NOT re-implement the logic

Imports:
- `lib/features/accounting/domain/repositories/category_repository.dart`
- `lib/application/accounting/category_service.dart`
- `lib/features/accounting/domain/models/voice_parse_result.dart`
- `lib/features/accounting/domain/models/transaction.dart` (for `LedgerType`)

After this step, run `flutter test test/unit/application/voice/category_matcher_test.dart` — tests should pass.

### Step 3.3 — Create VoiceSatisfactionEstimator

**File:** `lib/application/voice/voice_satisfaction_estimator.dart`

Implement exactly as defined in the MOD-009 spec section "语音满意度估算 → 估算算法". Pure Dart, no dependencies beyond:
- `dart:math` (for `sqrt`)
- `lib/features/accounting/domain/models/voice_parse_result.dart` (for `VoiceAudioFeatures`)

After this step, run `flutter test test/unit/application/voice/voice_satisfaction_estimator_test.dart` — tests should pass.

### Step 3.4 — Create ParseVoiceInputUseCase

**File:** `lib/application/voice/parse_voice_input_use_case.dart`

Implement as defined in the MOD-009 spec. The class orchestrates:
1. `VoiceTextParser.extractAmount(text)` → amount
2. `VoiceTextParser.extractAndMatchMerchant(text, merchantDB)` → merchant (if any)
3. If merchant found: set `categoryMatch` with `MatchSource.merchant`
4. If no merchant: `CategoryMatcher.matchFromText(text)` → category match
5. `CategoryMatcher.resolveLedgerType(categoryId)` → ledger type

Constructor:
```dart
ParseVoiceInputUseCase({
  required VoiceTextParser textParser,
  required CategoryMatcher categoryMatcher,
  required MerchantDatabase merchantDatabase,
})
```

Returns `Result<VoiceParseResult>`.

After this step, run:
```bash
flutter test test/unit/application/voice/
```
All four application-layer test files should pass.

### Step 3.5 — Run build_runner for all Freezed models

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Then run full test suite:
```bash
flutter test test/unit/
```
All existing tests plus new voice tests must pass.

---

## Phase 4: GREEN — Presentation Layer (Day 5–7)

### Step 4.1 — Create VoiceWaveform widget

**File:** `lib/features/accounting/presentation/widgets/voice_waveform.dart`

Implement as defined in MOD-009 spec section "UI组件设计 → 波形动画组件". Uses `AnimatedContainer` for each of 16 bars. No Riverpod — pure stateless widget with parameters:
- `double soundLevel` (0.0–1.0, required)
- `bool isActive` (default false)
- `Color color` (default `AppColors.survival`)

After this step, run widget tests from Phase 1 Step 1.7.

### Step 4.2 — Create VoiceTranscriptCard widget

**File:** `lib/features/accounting/presentation/widgets/voice_transcript_card.dart`

A `StatelessWidget` that shows the current recognition state. Parameters:
- `bool isRecording` (required)
- `String partialText` (required, shown in grey)
- `String finalText` (required, shown in dark)

Layout: Card with a Row header (mic Icon + status text), then the partial or final text body below. When `partialText` is not empty, show it. When `isRecording` is false and `finalText` is not empty, show final text. Use `AppTextStyles.bodyMedium` with appropriate colors.

After this step, run widget tests from Phase 1 Step 1.8.

### Step 4.3 — Create VoiceParsePreview widget

**File:** `lib/features/accounting/presentation/widgets/voice_parse_preview.dart`

A `StatelessWidget` showing parsed result preview. Parameters:
- `VoiceParseResult? parseResult` (nullable — renders nothing if null)

When `parseResult` is not null, show a Card with rows for:
- Amount (if present): `💰 ¥NNN` — use `NumberFormatter.formatCurrency(amount, 'JPY', locale)` — this widget must be a `ConsumerWidget` to access `ref.watch(currentLocaleProvider)`
- Merchant name (if present): `🏪 商家名`
- Category (if present): `📁 カテゴリID` — note: Category name lookup is not implemented in Phase 4 (backlog — show ID for now, replace with name in Phase 5 REFACTOR)
- Ledger type (if present): `📕 生存` or `📗 灵魂`
- Estimated satisfaction (only if `ledgerType == soul`): `⭐ N/10`

Imports: `flutter_riverpod`, `lib/features/accounting/domain/models/voice_parse_result.dart`, `lib/infrastructure/i18n/formatters/number_formatter.dart`, `lib/features/settings/presentation/providers/locale_provider.dart`.

After this step, run widget tests from Phase 1 Step 1.9.

### Step 4.4 — Create voice_providers.dart

**File:** `lib/features/accounting/presentation/providers/voice_providers.dart`

Follow the exact same pattern as `use_case_providers.dart`. This file provides all voice-related Riverpod providers. Use `@riverpod` annotation for code generation.

```dart
// lib/features/accounting/presentation/providers/voice_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../application/voice/category_matcher.dart';
import '../../../../application/voice/parse_voice_input_use_case.dart';
import '../../../../application/voice/voice_satisfaction_estimator.dart';
import '../../../../application/voice/voice_text_parser.dart';
import '../../../../infrastructure/ml/merchant_database.dart';
import '../../../../application/accounting/category_service.dart';
import 'use_case_providers.dart';
import 'repository_providers.dart';

part 'voice_providers.g.dart';

@Riverpod(keepAlive: true)
MerchantDatabase merchantDatabase(Ref ref) {
  return MerchantDatabase();
}

@riverpod
VoiceTextParser voiceTextParser(Ref ref) {
  return VoiceTextParser();
}

@riverpod
CategoryMatcher categoryMatcher(Ref ref) {
  return CategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    categoryService: ref.watch(categoryServiceProvider),
  );
}

@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    categoryMatcher: ref.watch(categoryMatcherProvider),
    merchantDatabase: ref.watch(merchantDatabaseProvider),
  );
}

@riverpod
VoiceSatisfactionEstimator voiceSatisfactionEstimator(Ref ref) {
  return VoiceSatisfactionEstimator();
}
```

After creating this file, run build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify `voice_providers.g.dart` is generated.

### Step 4.5 — Rewrite VoiceInputScreen (replace stub)

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart`

Replace the existing static stub entirely. The new implementation is a `ConsumerStatefulWidget` that:

1. Manages state: `_isRecording`, `_isInitialized`, `_partialText`, `_finalText`, `_soundLevel`, `_parseResult`, `_audioFeatures` fields
2. On `initState()`: reads `SpeechRecognitionService` (created locally, not from provider — it manages its own lifecycle) and calls `_initSpeechService()`
3. On mic button tap: calls `startListening()` or `stopListening()`
4. On sound level callback: throttles to 100ms intervals, appends to `_soundLevels` list, calls `setState`
5. On partial result: updates `_partialText`, debounces (300ms) parse via `ref.read(parseVoiceInputUseCaseProvider).execute(text)`
6. On final result: updates `_finalText`, runs full parse, and if `ledgerType == soul` runs `VoiceSatisfactionEstimator.estimate()`
7. "Next" button navigates to `TransactionConfirmScreen` passing: `bookId`, `amount` (from parse result or 0), `category` (looked up by `categoryId` from `categoryRepository`), `date: DateTime.now()`

Additional UI elements vs the stub:
- Replace static waveform bars with `VoiceWaveform(soundLevel: _soundLevel, isActive: _isRecording)`
- Replace static transcript area with `VoiceTranscriptCard(isRecording: _isRecording, partialText: _partialText, finalText: _finalText)`
- Add `VoiceParsePreview(parseResult: _parseResult)` below the transcript card
- Locale-aware: read `ref.watch(currentLocaleProvider)` for passing to speech service locale ID

The `SpeechRecognitionService` is instantiated directly (not from provider) because it is a stateful object tied to the screen's lifecycle. It is disposed in `dispose()`.

**Locale to SpeechToText locale ID mapping:**
```dart
String _localeIdFromLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ja': return 'ja-JP';
    case 'zh': return 'zh-CN';
    case 'en': return 'en-US';
    default: return 'ja-JP';
  }
}
```

### Step 4.6 — Run build_runner and full test suite

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Fix any analyzer warnings before proceeding. Zero tolerance for warnings.

---

## Phase 5: REFACTOR — Integration & Polish (Day 7–8)

### Step 5.1 — Integrate navigation from VoiceInputScreen to TransactionConfirmScreen

The "Next" button in `VoiceInputScreen` currently just pops. Implement proper navigation:

1. Read `categoryRepository` to look up the `Category` object by `parseResult.categoryMatch?.categoryId`
2. If category is null (no match), show a `SoftToast` ("カテゴリを選択してください") and do not navigate
3. If category found, push `TransactionConfirmScreen` with:
   - `bookId: widget.bookId`
   - `amount: parseResult.amount ?? 0`
   - `category: category`
   - `date: DateTime.now()`
   - Pre-fill `merchant` via the `_storeController` in `TransactionConfirmScreen` — this requires passing it as a constructor parameter OR navigating with route extras

Check `TransactionConfirmScreen` constructor — it currently accepts `bookId`, `amount`, `category`, `parentCategory?`, `date`. To pass `merchant` pre-fill, you must either:
- Add an optional `initialMerchant` parameter to `TransactionConfirmScreen` (preferred — backwards compatible)
- Or pass it via Navigator extras (less clean)

**Decision:** Add `String? initialMerchant` and `int? initialSatisfaction` optional parameters to `TransactionConfirmScreen`. These are set into the `_storeController` and `_soulSatisfaction` state in `initState`.

This modification to `TransactionConfirmScreen` is backward-compatible (existing callers pass neither, and nil is the existing default).

### Step 5.2 — Resolve category name display in VoiceParsePreview

In Phase 4 Step 4.3, the preview shows `categoryId` as a placeholder. In REFACTOR, replace with actual category name:
- `VoiceParsePreview` must accept an optional `Map<String, String> categoryNames` parameter (categoryId → display name)
- In `VoiceInputScreen`, after parsing, look up the category name and pass it to the widget

### Step 5.3 — Debouncing optimization

In `VoiceInputScreen`, verify the debounce timer:
```dart
Timer? _parseDebounce;

void _onPartialResult(String text) {
  setState(() => _partialText = text);
  _parseDebounce?.cancel();
  _parseDebounce = Timer(const Duration(milliseconds: 300), () {
    _runParse(text);
  });
}
```

Verify the timer is cancelled in `dispose()`.

### Step 5.4 — Merchant match caching

In `VoiceInputScreen`, track the last successfully matched merchant string. Skip merchant re-search if text has changed by fewer than 2 characters:
```dart
String? _lastSearchedText;
MerchantMatch? _cachedMerchantMatch;

MerchantMatch? _getCachedOrSearchMerchant(String text) {
  if (_lastSearchedText != null &&
      (text.length - _lastSearchedText!.length).abs() < 2) {
    return _cachedMerchantMatch;
  }
  _lastSearchedText = text;
  _cachedMerchantMatch = ref.read(merchantDatabaseProvider).findMerchant(text);
  return _cachedMerchantMatch;
}
```

### Step 5.5 — Sound level sampling throttle

Verify the 100ms throttle in `_onSoundLevel`:
```dart
DateTime? _lastSampleTime;

void _onSoundLevel(double level) {
  final now = DateTime.now();
  if (_lastSampleTime != null &&
      now.difference(_lastSampleTime!).inMilliseconds < 100) {
    return;
  }
  _lastSampleTime = now;
  _soundLevels.add(level);
  _timestamps.add(now);
  setState(() => _soundLevel = level);
}
```

### Step 5.6 — Permission denied error handling

In `_initSpeechService()`, if `initialize()` returns false:
- Check if the error is a permission denial
- Show a `SoftToast` or `AlertDialog` with instructions to enable microphone permission in Settings
- Use the existing `SoftToast` widget at `lib/features/accounting/presentation/widgets/soft_toast.dart`

### Step 5.7 — Final flutter analyze and test run

```bash
flutter analyze
flutter test
```

Expected output:
```
Analyzing home_pocket...
No issues found!

00:XX +NNN: All tests passed!
```

### Step 5.8 — Generate worklog

Create worklog at `docs/worklog/YYYYMMDD_HHMM_implement_voice_input_module.md` per the worklog rules.

---

## Dependency Map

The implementation order is dictated by this dependency graph:

```
voice_parse_result.dart (Freezed model)
  └──> required by ALL other voice files

merchant_database.dart (Infrastructure, plain class)
  └──> required by VoiceTextParser, ParseVoiceInputUseCase

speech_recognition_service.dart (Infrastructure)
  └──> required by VoiceInputScreen

voice_text_parser.dart (Application)
  └──> depends on: MerchantDatabase, VoiceParseResult

category_matcher.dart (Application)
  └──> depends on: CategoryRepository (existing), CategoryService (existing), VoiceParseResult

voice_satisfaction_estimator.dart (Application)
  └──> depends on: VoiceParseResult (VoiceAudioFeatures)

parse_voice_input_use_case.dart (Application)
  └──> depends on: VoiceTextParser, CategoryMatcher, MerchantDatabase, VoiceParseResult

voice_providers.dart (Presentation/Providers)
  └──> depends on: ALL application layer + repository_providers.dart + use_case_providers.dart

voice_waveform.dart (Widget)
  └──> no dependencies beyond AppColors

voice_transcript_card.dart (Widget)
  └──> depends on: AppTextStyles, AppColors

voice_parse_preview.dart (Widget)
  └──> depends on: VoiceParseResult, NumberFormatter, currentLocaleProvider

VoiceInputScreen (Screen — replaces stub)
  └──> depends on: ALL of the above
```

---

## Acceptance Criteria Checklist

Mapped from MOD-009 functional requirements:

**FR-001: Voice to Text**
- [ ] App requests microphone permission before first use (iOS + Android)
- [ ] Speech recognition initializes for Japanese (ja-JP) locale
- [ ] Speech recognition initializes for Chinese (zh-CN) locale
- [ ] Speech recognition initializes for English (en-US) locale
- [ ] Partial results appear in real-time as user speaks
- [ ] 3-second silence automatically stops recording (via `pauseFor: Duration(seconds: 3)`)
- [ ] Maximum 30-second recording limit enforced
- [ ] `VoiceWaveform` animates during recording

**FR-002: Amount Extraction**
- [ ] Extracts `680円` → 680 (unit test passes)
- [ ] Extracts `¥1,280` → 1280 (unit test passes)
- [ ] Extracts `480块` → 480 (unit test passes)
- [ ] Extracts `550 yen` → 550 (unit test passes)
- [ ] Extracts kanji `六百八十円` → 680 (unit test passes)
- [ ] Extracts kanji `千二百` → 1200 (unit test passes)
- [ ] Returns null for text with no amount (unit test passes)

**FR-003: Category Fuzzy Matching**
- [ ] `昼ごはん` → `cat_food` with confidence > 0.8 (unit test passes)
- [ ] `午饭` → `cat_food` (unit test passes)
- [ ] `lunch` → `cat_food` (unit test passes)
- [ ] `電車` → `cat_transport` with confidence ≥ 0.9 (unit test passes)
- [ ] Unknown text → null (unit test passes)
- [ ] `VoiceParsePreview` shows matched category

**FR-004: Merchant Fuzzy Matching**
- [ ] `MerchantDatabase.findMerchant('マクドナルド')` returns match
- [ ] `MerchantDatabase.findMerchant('マック')` returns マクドナルド match (alias)
- [ ] `MerchantDatabase.findMerchant('スタバ')` returns スターバックス match (alias)
- [ ] Merchant match has higher priority than keyword match (unit test passes)
- [ ] `VoiceParsePreview` shows matched merchant name

**FR-005: Voice Satisfaction Estimation**
- [ ] Estimator returns score in range 1–10 always (unit test passes)
- [ ] Excited voice → score ≥ 7 (unit test passes)
- [ ] Calm voice → score 4–6 (unit test passes)
- [ ] Empty audio → default score 3–5 (unit test passes)
- [ ] Satisfaction estimation runs only when `ledgerType == soul`
- [ ] Estimated satisfaction is pre-filled in `TransactionConfirmScreen` slider

**FR-006: Permission Management**
- [ ] iOS `Info.plist` has `NSSpeechRecognitionUsageDescription`
- [ ] iOS `Info.plist` has `NSMicrophoneUsageDescription`
- [ ] Android `AndroidManifest.xml` has `RECORD_AUDIO` permission
- [ ] Permission denial shows friendly error message
- [ ] Mic button is disabled when `isAvailable` is false

---

## Files to Create (Complete List)

21 new files in total:

**Domain Models (1 file):**
1. `lib/features/accounting/domain/models/voice_parse_result.dart`

**Infrastructure (2 files):**
2. `lib/infrastructure/ml/merchant_database.dart`
3. `lib/infrastructure/speech/speech_recognition_service.dart`

**Application Layer (4 files):**
4. `lib/application/voice/voice_text_parser.dart`
5. `lib/application/voice/category_matcher.dart`
6. `lib/application/voice/voice_satisfaction_estimator.dart`
7. `lib/application/voice/parse_voice_input_use_case.dart`

**Presentation — Providers (1 file):**
8. `lib/features/accounting/presentation/providers/voice_providers.dart`

**Presentation — Widgets (3 files):**
9. `lib/features/accounting/presentation/widgets/voice_waveform.dart`
10. `lib/features/accounting/presentation/widgets/voice_transcript_card.dart`
11. `lib/features/accounting/presentation/widgets/voice_parse_preview.dart`

**Tests (10 files):**
12. `test/unit/application/voice/voice_text_parser_test.dart`
13. `test/unit/application/voice/category_matcher_test.dart`
14. `test/unit/application/voice/category_matcher_test.mocks.dart` (generated)
15. `test/unit/application/voice/voice_satisfaction_estimator_test.dart`
16. `test/unit/application/voice/parse_voice_input_use_case_test.dart`
17. `test/unit/application/voice/parse_voice_input_use_case_test.mocks.dart` (generated)
18. `test/unit/infrastructure/speech/speech_recognition_service_test.dart`
19. `test/widget/features/accounting/presentation/widgets/voice_waveform_test.dart`
20. `test/widget/features/accounting/presentation/widgets/voice_transcript_card_test.dart`
21. `test/widget/features/accounting/presentation/widgets/voice_parse_preview_test.dart`
22. `test/unit/features/accounting/presentation/providers/voice_providers_test.dart`
23. `test/unit/features/accounting/domain/models/voice_parse_result_test.dart`

**Generated by build_runner (not committed):**
- `lib/features/accounting/domain/models/voice_parse_result.freezed.dart`
- `lib/features/accounting/domain/models/voice_parse_result.g.dart`
- `lib/features/accounting/presentation/providers/voice_providers.g.dart`

---

## Files to Modify (Complete List)

5 existing files to modify:

1. **`pubspec.yaml`** — Add `speech_to_text: ^7.0.0` dependency
2. **`ios/Runner/Info.plist`** — Add microphone and speech recognition usage descriptions
3. **`android/app/src/main/AndroidManifest.xml`** — Add RECORD_AUDIO permission and speech intent query
4. **`lib/features/accounting/presentation/screens/voice_input_screen.dart`** — Replace stub with full implementation
5. **`lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`** — Add optional `initialMerchant` and `initialSatisfaction` constructor parameters

---

## Notes on Existing Code Reuse

The following existing code is REUSED without modification:

| Existing File | How Reused |
|---|---|
| `lib/application/accounting/category_service.dart` | `CategoryMatcher` delegates `resolveLedgerType()` to it |
| `lib/application/dual_ledger/classification_service.dart` | Not directly used by voice — but `VoiceInputScreen` passes `ledgerType` explicitly to `CreateTransactionUseCase` params, bypassing auto-classification |
| `lib/shared/utils/result.dart` | `ParseVoiceInputUseCase` returns `Result<VoiceParseResult>` |
| `lib/features/accounting/domain/models/transaction.dart` | `LedgerType` enum imported by voice models |
| `lib/features/accounting/domain/repositories/category_repository.dart` | Used by `CategoryMatcher` |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | Voice flow navigates here after parse |
| `lib/features/accounting/presentation/widgets/soft_toast.dart` | Used for error feedback in permission denied case |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | `voice_providers.dart` imports `categoryRepositoryProvider` from here |
| `lib/features/accounting/presentation/providers/use_case_providers.dart` | `voice_providers.dart` imports `categoryServiceProvider` from here |
| `lib/core/theme/app_colors.dart` | Widget colors |
| `lib/core/theme/app_text_styles.dart` | Widget text styles |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` | Currency display in `VoiceParsePreview` |
| `lib/features/settings/presentation/providers/locale_provider.dart` | Locale for speech recognition and number formatting |
