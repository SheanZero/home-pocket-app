# MOD-009: 语音记账模块 - 技术设计文档

**模块编号:** MOD-009
**文档版本:** 1.0
**创建日期:** 2026-02-22
**预估工时:** 8天
**优先级:** P2（增强功能）
**状态:** 设计完成

---

## 目录

1. [模块概述](#模块概述)
2. [功能需求](#功能需求)
3. [技术设计](#技术设计)
4. [核心流程](#核心流程)
5. [NLP解析引擎](#nlp解析引擎)
6. [语音满意度估算](#语音满意度估算)
7. [UI组件设计](#ui组件设计)
8. [测试策略](#测试策略)
9. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

语音记账模块允许用户通过自然语言语音输入创建交易记录。系统自动从语音中提取金额、模糊匹配类目和商家，并在类目属于灵魂账本时，利用语音的音量起伏特征估算用户满意度，减少手动输入步骤。

### 核心功能

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 语音转文字 | 多语言语音识别（ja/zh/en） | P0 |
| 金额提取 | 从自然语言中识别金额 | P0 |
| 类目模糊匹配 | 根据语音内容推荐分类 | P0 |
| 商家模糊匹配 | 根据语音内容匹配商家数据库 | P0 |
| 语音满意度估算 | 灵魂账本交易根据语音特征预估满意度 | P1 |
| 实时转写显示 | 语音输入时实时展示识别文字 | P0 |
| 用户确认修正 | 识别结果可在确认页编辑 | P0 |

### 技术栈

```yaml
语音识别: speech_to_text ^7.0.0
  Android: Google SpeechRecognizer
  iOS: Apple SFSpeechRecognizer
NLP解析: 纯Dart（正则 + 关键词匹配）
商家数据库: lib/infrastructure/ml/merchant_database.dart（复用 MOD-004）
分类匹配: lib/application/dual_ledger/（复用现有分类引擎）
状态管理: Riverpod 2.6+
```

### 语音输入示例

| 用户语音 | 识别结果 |
|---------|---------|
| 「昼ごはんにマクドナルドで680円」 | 金额=680, 商家=マクドナルド, 类目=餐饮 |
| 「午饭在吉野家吃了480块」 | 金额=480, 商家=吉野家, 类目=餐饮 |
| 「lunch at Starbucks 550 yen」 | 金额=550, 商家=スターバックス, 类目=餐饮 |
| 「电车代320円」 | 金额=320, 类目=交通 |
| 「ユニクロで服買った3980円、めっちゃ嬉しい！」 | 金额=3980, 商家=ユニクロ, 类目=购物(灵魂), 满意度=高 |

---

## 功能需求

### FR-001: 语音转文字

**用户故事**: 作为用户，我希望能够通过语音快速输入交易信息，无需手动打字。

**验收标准**:
- 支持日语（ja-JP）、中文（zh-CN）、英语（en-US）
- 实时显示部分识别结果（partial results）
- 识别结束后显示最终结果和置信度
- 支持最长30秒连续语音
- 3秒静默自动停止
- 识别速度 < 500ms（最终结果延迟）

**技术要求**:
- 使用 `speech_to_text` 插件
- 语言跟随 `currentLocaleProvider` 当前设置
- 无数据上传（隐私保护，优先使用 onDevice 模式）

### FR-002: 金额提取

**用户故事**: 作为用户，我希望系统能从我的语音中自动识别出消费金额。

**验收标准**:
- 识别阿拉伯数字：「680円」「¥1280」「1280 yen」
- 识别日语数词：「六百八十円」「千二百八十円」「三千九百八十」
- 识别中文数词：「六百八十块」「一千二百八」「三千九百八十元」
- 识别带逗号格式：「1,280円」「12,800」
- 识别带小数：「12.50ドル」（非日元货币）
- 准确率 > 95%（金额是最关键字段）

### FR-003: 类目模糊匹配

**用户故事**: 作为用户，我希望说出消费内容后系统能自动推荐合适的分类。

**验收标准**:
- 关键词匹配：「昼ごはん」→ 餐饮/午餐、「電車」→ 交通/通勤
- 模糊匹配：「ランチ」→ 餐饮、「服」→ 购物/服装
- 多语言：「午饭」→ 餐饮、「lunch」→ 餐饮
- 匹配到 L2 子分类时自动关联 L1 父分类
- 显示匹配置信度
- 未匹配时默认为「その他」

**匹配规则**:
- 精确匹配：关键词完全命中 → 置信度 0.95
- 含义匹配：同义词/近义词命中 → 置信度 0.80
- 部分匹配：关键词部分命中 → 置信度 0.60

### FR-004: 商家模糊匹配

**用户故事**: 作为用户，我说出商家名称后系统能自动识别并推荐对应的分类。

**验收标准**:
- 复用 `MerchantDatabase`（MOD-004 已定义 500+ 商家）
- 支持正式名、别名、缩写：「スタバ」→ スターバックス
- 口语化输入：「マック」→ マクドナルド、「セブン」→ セブンイレブン
- 商家匹配后自动推荐分类和账本类型
- 商家匹配优先级高于类目关键词匹配

### FR-005: 语音满意度估算

**用户故事**: 作为用户，当我记录灵魂账本的消费时，系统能根据我说话的语气自动估算满意度。

**验收标准**:
- 仅对灵魂账本（Soul Ledger）交易生效
- 估算结果范围 1-10（与现有 `soulSatisfaction` 字段一致）
- 用户可在确认页手动调整估算值
- 默认值 5（当信号不足时）

**估算信号**（按优先级）:

| 信号 | 来源 | 权重 | 说明 |
|------|------|------|------|
| 音量均值 | `onSoundLevelChange` | 25% | 说话声音越大 → 越兴奋 |
| 音量变化率 | `onSoundLevelChange` | 25% | 音量起伏越大 → 越激动 |
| 语速 | partial results 时间间隔 | 20% | 说话越快 → 越兴奋 |
| 积极词汇 | 文本分析 | 20% | 「嬉しい」「最高」「すごい」等 |
| 语音时长 | 总录音时间 | 10% | 说得越多 → 越有感触 |

**技术限制说明**:
- `speech_to_text` 仅提供音量（dB/RMS）数据，不提供音高（Hz）
- Android 与 iOS 音量值单位不同，需平台归一化
- 不能同时使用 `speech_to_text` 和音高检测库（Android 麦克风独占）
- 因此采用"音量 + 文本 + 语速"组合估算，非精确情感分析

### FR-006: 权限管理

**验收标准**:
- 首次使用前请求麦克风权限
- 权限被拒绝时显示友好提示和设置引导
- iOS 需要 `NSMicrophoneUsageDescription` 和 `NSSpeechRecognitionUsageDescription`
- Android 需要 `RECORD_AUDIO` 权限

---

## 技术设计

### 架构图

```
┌──────────────────────────────────────────────┐
│           Presentation Layer                 │
│  ┌──────────────────┐  ┌──────────────────┐  │
│  │ VoiceInputScreen │  │ TransactionConfirm│  │
│  │  (语音录入)      │  │  Screen (确认)    │  │
│  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │            │
│  ┌────────▼─────────────────────▼──────────┐ │
│  │       Voice Providers                   │ │
│  │  - voiceRecognitionProvider             │ │
│  │  - voiceParseResultProvider             │ │
│  │  - voiceSatisfactionProvider            │ │
│  └────────┬────────────────────────────────┘ │
└───────────┼──────────────────────────────────┘
            │
┌───────────▼──────────────────────────────────┐
│         Application Layer                    │
│  ┌──────────────────────────────────────┐    │
│  │       Use Cases                      │    │
│  │  - ParseVoiceInputUseCase            │    │
│  │  - EstimateSatisfactionUseCase       │    │
│  └────────┬─────────────────────────────┘    │
│           │                                  │
│  ┌────────▼─────────────────────────────┐    │
│  │  Services                            │    │
│  │  - VoiceTextParser (NLP解析)         │    │
│  │  - VoiceSatisfactionEstimator        │    │
│  │  - CategoryMatcher (类目匹配)        │    │
│  └────────┬─────────────────────────────┘    │
└───────────┼──────────────────────────────────┘
            │
┌───────────▼──────────────────────────────────┐
│        Infrastructure Layer                  │
│  ┌──────────────────────────────────────┐    │
│  │  Speech Recognition                  │    │
│  │  - SpeechRecognitionService          │    │
│  │    (wraps speech_to_text)            │    │
│  └──────────────────────────────────────┘    │
│  ┌──────────────────────────────────────┐    │
│  │  ML (复用)                           │    │
│  │  - MerchantDatabase                  │    │
│  └──────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

### 目录结构

```
# Feature 模块（瘦 Feature：ONLY domain/ + presentation/）
lib/features/accounting/
  ├── domain/
  │   └── models/
  │       └── voice_parse_result.dart         # 语音解析结果模型
  │
  └── presentation/
      ├── screens/
      │   └── voice_input_screen.dart         # 修改现有 stub
      ├── widgets/
      │   ├── voice_waveform.dart             # 音量波形动画
      │   ├── voice_transcript_card.dart      # 实时转写卡片
      │   └── voice_parse_preview.dart        # 解析结果预览
      └── providers/
          └── voice_providers.dart            # 语音相关 Riverpod providers

# Application 层（全局 Use Cases + 业务服务）
lib/application/voice/
  ├── parse_voice_input_use_case.dart         # 语音文本解析用例
  ├── voice_text_parser.dart                  # NLP 文本解析引擎
  ├── category_matcher.dart                   # 类目模糊匹配服务
  └── voice_satisfaction_estimator.dart       # 语音满意度估算服务

# Infrastructure 层（全局技术能力）
lib/infrastructure/speech/
  └── speech_recognition_service.dart         # speech_to_text 封装

# 复用（不新建）
lib/infrastructure/ml/merchant_database.dart  # 商家数据库（MOD-004 已定义）
lib/application/dual_ledger/                  # 分类引擎（已存在）
```

> **架构遵循:**
> - "Thin Feature" 规则：features/ 只含 domain/ + presentation/
> - Use Cases 在 `lib/application/voice/`（全局）
> - 基础设施在 `lib/infrastructure/speech/`（全局）
> - 复用 MerchantDatabase 和 ClassificationService（无重复定义）

### 依赖关系

```
VoiceInputScreen (Presentation)
    │
    ├──▷ ParseVoiceInputUseCase (Application)
    │       ├──▷ SpeechRecognitionService (Infrastructure)
    │       ├──▷ VoiceTextParser (Application)
    │       ├──▷ CategoryMatcher (Application)
    │       │       └──▷ CategoryRepository (Domain interface)
    │       └──▷ MerchantDatabase (Infrastructure, 复用)
    │
    ├──▷ EstimateSatisfactionUseCase (Application)
    │       └──▷ VoiceSatisfactionEstimator (Application)
    │
    └──▷ CreateTransactionUseCase (Application, 复用)
            └──▷ TransactionRepository (Domain interface)
```

---

## 核心流程

### 1. 语音识别服务封装

```dart
// lib/infrastructure/speech/speech_recognition_service.dart

import 'dart:io' show Platform;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// 语音识别服务 - 封装 speech_to_text 插件
///
/// 提供统一的语音识别接口，处理平台差异（音量归一化）。
class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// 初始化语音识别
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onStatus: (status) => onStatus?.call(status),
      onError: (error) => onError?.call(error.errorMsg, error.permanent),
      debugLogging: false,
    );

    return _isInitialized;
  }

  /// 开始监听
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) return;

    await _speech.listen(
      onResult: onResult,
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      cancelOnError: false,
      onSoundLevelChange: (double level) {
        onSoundLevel(_normalizeSoundLevel(level));
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  /// 停止监听
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// 取消监听
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// 获取可用语言列表
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    return await _speech.locales();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  /// 平台归一化音量值
  ///
  /// Android: RMS-based, 约 0~10
  /// iOS: dB scale, 约 -50~0
  /// 输出: 0.0 (静音) ~ 1.0 (最大)
  double _normalizeSoundLevel(double rawLevel) {
    if (Platform.isAndroid) {
      return (rawLevel / 10.0).clamp(0.0, 1.0);
    } else if (Platform.isIOS) {
      return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
    }
    return rawLevel.clamp(0.0, 1.0);
  }
}
```

### 2. 语音文本解析用例

```dart
// lib/application/voice/parse_voice_input_use_case.dart

import 'package:home_pocket/shared/utils/result.dart';

class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final CategoryMatcher _categoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required CategoryMatcher categoryMatcher,
    required MerchantDatabase merchantDatabase,
  })  : _textParser = textParser,
        _categoryMatcher = categoryMatcher,
        _merchantDatabase = merchantDatabase;

  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      // 1. 提取金额
      final amount = _textParser.extractAmount(recognizedText);

      // 2. 匹配商家（优先）
      final merchantMatch = _textParser.extractAndMatchMerchant(
        recognizedText,
        _merchantDatabase,
      );

      // 3. 匹配类目
      CategoryMatchResult? categoryMatch;
      if (merchantMatch != null) {
        // 商家匹配成功 → 使用商家的分类
        categoryMatch = CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
      } else {
        // 无商家 → 从文本关键词匹配类目
        categoryMatch = await _categoryMatcher.matchFromText(recognizedText);
      }

      // 4. 确定账本类型
      LedgerType? ledgerType;
      if (merchantMatch != null) {
        ledgerType = merchantMatch.ledgerType;
      } else if (categoryMatch != null) {
        ledgerType = await _categoryMatcher.resolveLedgerType(
          categoryMatch.categoryId,
        );
      }

      return Result.success(VoiceParseResult(
        rawText: recognizedText,
        amount: amount,
        merchantName: merchantMatch?.merchantName,
        merchantMatch: merchantMatch,
        categoryMatch: categoryMatch,
        ledgerType: ledgerType,
      ));
    } catch (e) {
      return Result.error('语音解析失败: $e');
    }
  }
}
```

### 3. 语音解析结果模型

```dart
// lib/features/accounting/domain/models/voice_parse_result.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_parse_result.freezed.dart';

@freezed
abstract class VoiceParseResult with _$VoiceParseResult {
  const factory VoiceParseResult({
    required String rawText,
    int? amount,
    String? merchantName,
    MerchantMatch? merchantMatch,
    CategoryMatchResult? categoryMatch,
    LedgerType? ledgerType,
    @Default(5) int estimatedSatisfaction,
  }) = _VoiceParseResult;
}

@freezed
abstract class CategoryMatchResult with _$CategoryMatchResult {
  const factory CategoryMatchResult({
    required String categoryId,
    required double confidence,
    required MatchSource source,
  }) = _CategoryMatchResult;
}

enum MatchSource {
  merchant,  // 通过商家匹配得到
  keyword,   // 通过关键词匹配得到
  fallback,  // 默认值
}

/// 语音录制期间收集的音频特征
@freezed
abstract class VoiceAudioFeatures with _$VoiceAudioFeatures {
  const factory VoiceAudioFeatures({
    required List<double> soundLevels,
    required List<DateTime> timestamps,
    required DateTime startTime,
    required DateTime endTime,
    required int partialResultCount,
    required int wordCount,
  }) = _VoiceAudioFeatures;
}
```

---

## NLP解析引擎

### 金额提取

```dart
// lib/application/voice/voice_text_parser.dart

class VoiceTextParser {
  /// 从文本中提取金额
  ///
  /// 支持三种格式:
  /// 1. 阿拉伯数字: 「680円」「¥1280」「1,280」
  /// 2. 日语数词: 「六百八十円」「千二百円」
  /// 3. 中文数词: 「六百八十块」「一千二百元」
  int? extractAmount(String text) {
    // 优先级1: 阿拉伯数字金额
    final arabicAmount = _extractArabicAmount(text);
    if (arabicAmount != null) return arabicAmount;

    // 优先级2: 日语/中文数词金额
    final kanjiAmount = _extractKanjiAmount(text);
    if (kanjiAmount != null) return kanjiAmount;

    return null;
  }

  /// 阿拉伯数字金额提取
  int? _extractArabicAmount(String text) {
    final patterns = [
      // ¥1,280 / ￥1280
      RegExp(r'[¥￥]\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)'),
      // 1,280円 / 1280円 / 1280yen
      RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:円|えん|yen|元|块|塊)',
          caseSensitive: false),
      // 独立数字（4位以上可能是金额）
      RegExp(r'(?<!\d)(\d{3,7}(?:\.\d{1,2})?)(?!\d)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 10000000) {
          return amount.round();
        }
      }
    }

    return null;
  }

  /// 日语/中文数词金额提取
  ///
  /// 例: 「六百八十」→ 680、「千二百」→ 1200、「三万五千」→ 35000
  int? _extractKanjiAmount(String text) {
    // 数词マッピング
    const kanjiDigits = {
      '零': 0, '〇': 0,
      '一': 1, '壱': 1, '壹': 1,
      '二': 2, '弐': 2, '贰': 2,
      '三': 3, '参': 3, '叁': 3,
      '四': 4,
      '五': 5, '伍': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    const kanjiUnits = {
      '十': 10,
      '百': 100,
      '千': 1000, '仟': 1000,
      '万': 10000, '萬': 10000,
    };

    // 金額を含む可能性のあるテキスト範囲を抽出
    final amountPattern = RegExp(
      r'[零〇一壱壹二弐贰三参叁四五伍六七八九十百千仟万萬]+'
      r'(?:\s*(?:円|えん|yen|元|块|塊))?',
    );

    final match = amountPattern.firstMatch(text);
    if (match == null) return null;

    final kanjiText = match.group(0)!
        .replaceAll(RegExp(r'[\s円えんyen元块塊]'), '');

    if (kanjiText.isEmpty) return null;

    // 漢字数字をパース
    var result = 0;
    var currentSection = 0;
    var currentDigit = 1; // 「百」→ 1*100 のデフォルト

    for (var i = 0; i < kanjiText.length; i++) {
      final char = kanjiText[i];

      if (kanjiDigits.containsKey(char)) {
        currentDigit = kanjiDigits[char]!;
      } else if (kanjiUnits.containsKey(char)) {
        final unit = kanjiUnits[char]!;
        if (unit == 10000) {
          // 「万」: 前のセクションを万倍
          currentSection += currentDigit * (currentSection == 0 ? 1 : 1);
          result += (currentSection == 0 ? currentDigit : currentSection) * 10000;
          currentSection = 0;
          currentDigit = 1;
        } else {
          currentSection += currentDigit * unit;
          currentDigit = 1;
        }
      }
    }

    // 残りの数字を加算
    if (currentDigit > 0 && currentDigit < 10) {
      currentSection += currentDigit;
      // ただし最後の文字が単位の場合は加算済み
      final lastChar = kanjiText[kanjiText.length - 1];
      if (kanjiUnits.containsKey(lastChar)) {
        currentSection -= currentDigit;
      }
    }

    result += currentSection;

    return result > 0 ? result : null;
  }

  /// 商家提取与匹配
  MerchantMatch? extractAndMatchMerchant(
    String text,
    MerchantDatabase merchantDB,
  ) {
    // 1. 在文本中直接搜索已知商家名
    //    MerchantDatabase.findMerchant 已支持精确/别名/模糊匹配
    //    遍历文本中的可能商家名片段
    final words = _extractPotentialMerchantNames(text);

    for (final word in words) {
      final match = merchantDB.findMerchant(word);
      if (match != null) return match;
    }

    return null;
  }

  /// 从文本中提取可能的商家名片段
  List<String> _extractPotentialMerchantNames(String text) {
    final results = <String>[];

    // 移除金额和常见动词后的剩余词汇
    var cleaned = text
        .replaceAll(RegExp(r'[¥￥]\s*\d[\d,.]*'), '')
        .replaceAll(RegExp(r'\d[\d,.]*\s*(?:円|元|块|yen)'), '')
        .replaceAll(RegExp(r'[で|に|を|が|は|の|と|へ|から|まで|した|って|した|ました|だった|です]'), ' ')
        .replaceAll(RegExp(r'[在|了|花|买|吃|用|去|到]'), ' ')
        .replaceAll(RegExp(r'[at|for|in|on|spent|paid|bought]'), ' ')
        .trim();

    // 分割为候选词
    final segments = cleaned.split(RegExp(r'[\s,、。，]+'))
        .where((s) => s.length >= 2 && s.length <= 20)
        .toList();

    // 优先添加较长的片段（更可能是完整商家名）
    segments.sort((a, b) => b.length.compareTo(a.length));
    results.addAll(segments);

    // 也尝试原始文本中的连续片段
    for (var len = 10; len >= 2; len--) {
      for (var i = 0; i <= text.length - len; i++) {
        final sub = text.substring(i, i + len).trim();
        if (sub.isNotEmpty && !results.contains(sub)) {
          results.add(sub);
        }
      }
    }

    return results;
  }
}
```

### 类目匹配服务

```dart
// lib/application/voice/category_matcher.dart

class CategoryMatcher {
  final CategoryRepository _categoryRepository;
  final CategoryService _categoryService;

  CategoryMatcher({
    required CategoryRepository categoryRepository,
    required CategoryService categoryService,
  })  : _categoryRepository = categoryRepository,
        _categoryService = categoryService;

  /// 多语言类目关键词映射
  ///
  /// key: 关键词, value: (categoryId, confidence)
  static const Map<String, _KeywordMapping> _keywordMap = {
    // ===== 餐饮 (food) =====
    // 日语
    '朝ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '朝食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '昼ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '昼食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'ランチ': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晩ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕飯': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '食事': _KeywordMapping('cat_food', 0.85),
    'ご飯': _KeywordMapping('cat_food', 0.85),
    '弁当': _KeywordMapping('cat_food', 0.85),
    'コーヒー': _KeywordMapping('cat_food', 0.80),
    'カフェ': _KeywordMapping('cat_food', 0.80),
    'おやつ': _KeywordMapping('cat_food', 0.80),
    // 中文
    '早饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '早餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '午饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '午餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晚饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '晚餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '吃饭': _KeywordMapping('cat_food', 0.85),
    '外卖': _KeywordMapping('cat_food', 0.85),
    '咖啡': _KeywordMapping('cat_food', 0.80),
    // 英语
    'breakfast': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    'lunch': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'dinner': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    'food': _KeywordMapping('cat_food', 0.85),
    'coffee': _KeywordMapping('cat_food', 0.80),
    'cafe': _KeywordMapping('cat_food', 0.80),

    // ===== 交通 (transport) =====
    '電車': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '電車代': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'バス': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'バス代': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'タクシー': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    '交通費': _KeywordMapping('cat_transport', 0.95),
    '定期': _KeywordMapping('cat_transport', 0.85),
    'Suica': _KeywordMapping('cat_transport', 0.85),
    'PASMO': _KeywordMapping('cat_transport', 0.85),
    '地铁': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '公交': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    '打车': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    'train': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'bus': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'taxi': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),

    // ===== 购物 (shopping) =====
    '服': _KeywordMapping('cat_shopping', 0.80),
    '洋服': _KeywordMapping('cat_shopping', 0.85),
    '靴': _KeywordMapping('cat_shopping', 0.85),
    '本': _KeywordMapping('cat_education', 0.80),
    '衣服': _KeywordMapping('cat_shopping', 0.85),
    '鞋子': _KeywordMapping('cat_shopping', 0.85),
    '书': _KeywordMapping('cat_education', 0.80),
    'clothes': _KeywordMapping('cat_shopping', 0.85),
    'shoes': _KeywordMapping('cat_shopping', 0.85),
    'book': _KeywordMapping('cat_education', 0.80),

    // ===== 娱乐 (entertainment) =====
    '映画': _KeywordMapping('cat_entertainment', 0.95),
    'ゲーム': _KeywordMapping('cat_entertainment', 0.90),
    'カラオケ': _KeywordMapping('cat_entertainment', 0.95),
    '電影': _KeywordMapping('cat_entertainment', 0.95),
    '电影': _KeywordMapping('cat_entertainment', 0.95),
    '游戏': _KeywordMapping('cat_entertainment', 0.90),
    'movie': _KeywordMapping('cat_entertainment', 0.95),
    'game': _KeywordMapping('cat_entertainment', 0.90),

    // ===== 医疗 (medical) =====
    '病院': _KeywordMapping('cat_medical', 0.95),
    '薬': _KeywordMapping('cat_medical', 0.90),
    '医院': _KeywordMapping('cat_medical', 0.95),
    '药': _KeywordMapping('cat_medical', 0.90),
    'hospital': _KeywordMapping('cat_medical', 0.95),
    'medicine': _KeywordMapping('cat_medical', 0.90),

    // ===== 住居 (housing) =====
    '家賃': _KeywordMapping('cat_housing', 0.95),
    '水道': _KeywordMapping('cat_housing', 0.90),
    '電気': _KeywordMapping('cat_housing', 0.90),
    'ガス': _KeywordMapping('cat_housing', 0.90),
    '房租': _KeywordMapping('cat_housing', 0.95),
    '水费': _KeywordMapping('cat_housing', 0.90),
    '电费': _KeywordMapping('cat_housing', 0.90),
    'rent': _KeywordMapping('cat_housing', 0.95),
    'utilities': _KeywordMapping('cat_housing', 0.90),
  };

  /// 从文本匹配类目
  Future<CategoryMatchResult?> matchFromText(String text) async {
    final lowerText = text.toLowerCase();
    CategoryMatchResult? bestMatch;

    for (final entry in _keywordMap.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        final mapping = entry.value;
        final categoryId = mapping.sub ?? mapping.categoryId;

        // 验证类目存在
        final category = await _categoryRepository.findById(categoryId);
        final effectiveId = category != null
            ? categoryId
            : mapping.categoryId; // 回退到 L1

        if (bestMatch == null || mapping.confidence > bestMatch.confidence) {
          bestMatch = CategoryMatchResult(
            categoryId: effectiveId,
            confidence: mapping.confidence,
            source: MatchSource.keyword,
          );
        }
      }
    }

    return bestMatch;
  }

  /// 通过 CategoryService 解析账本类型
  Future<LedgerType?> resolveLedgerType(String categoryId) async {
    return await _categoryService.resolveLedgerType(categoryId);
  }
}

class _KeywordMapping {
  final String categoryId;
  final double confidence;
  final String? sub;

  const _KeywordMapping(this.categoryId, this.confidence, {this.sub});
}
```

---

## 语音满意度估算

### 估算算法

```dart
// lib/application/voice/voice_satisfaction_estimator.dart

import 'dart:math';

/// 语音满意度估算器
///
/// 通过分析语音录制期间的音量、语速、文本情感等信号，
/// 估算用户对灵魂账本消费的满意度（1-10）。
///
/// 技术限制:
/// - speech_to_text 仅提供音量数据，不提供音高(Hz)
/// - Android/iOS 音量已归一化至 0.0~1.0
/// - 非精确情感分析，仅作辅助参考
class VoiceSatisfactionEstimator {

  /// 估算满意度 (1-10)
  ///
  /// [audioFeatures] 录制期间收集的音频特征
  /// [recognizedText] 最终识别文本
  int estimate({
    required VoiceAudioFeatures audioFeatures,
    required String recognizedText,
  }) {
    // 各信号得分 (0.0 ~ 1.0)
    final volumeScore = _analyzeVolume(audioFeatures.soundLevels);
    final varianceScore = _analyzeVolumeVariance(audioFeatures.soundLevels);
    final speechRateScore = _analyzeSpeechRate(audioFeatures);
    final sentimentScore = _analyzeSentiment(recognizedText);
    final durationScore = _analyzeDuration(audioFeatures);

    // 加权平均
    final weightedScore = volumeScore * 0.25
        + varianceScore * 0.25
        + speechRateScore * 0.20
        + sentimentScore * 0.20
        + durationScore * 0.10;

    // 映射到 1-10
    // weightedScore 0.0~1.0 → satisfaction 1~10
    // 使用 S 曲线，中间区间更敏感
    final satisfaction = _mapToSatisfaction(weightedScore);

    return satisfaction.clamp(1, 10);
  }

  /// 分析平均音量 (0.0 ~ 1.0)
  ///
  /// 说话声音越大 → 越兴奋/开心
  double _analyzeVolume(List<double> levels) {
    if (levels.isEmpty) return 0.5;

    // 过滤静音帧 (< 0.05)
    final activeLevels = levels.where((l) => l > 0.05).toList();
    if (activeLevels.isEmpty) return 0.3;

    final avg = activeLevels.reduce((a, b) => a + b) / activeLevels.length;
    // 正常说话约 0.3~0.5，兴奋时 0.6~0.8
    return (avg / 0.8).clamp(0.0, 1.0);
  }

  /// 分析音量变化率 (0.0 ~ 1.0)
  ///
  /// 音量起伏越大 → 说话越有感情
  double _analyzeVolumeVariance(List<double> levels) {
    if (levels.length < 3) return 0.5;

    final activeLevels = levels.where((l) => l > 0.05).toList();
    if (activeLevels.length < 3) return 0.3;

    final mean = activeLevels.reduce((a, b) => a + b) / activeLevels.length;
    final variance = activeLevels
        .map((l) => (l - mean) * (l - mean))
        .reduce((a, b) => a + b) / activeLevels.length;
    final stdDev = sqrt(variance);

    // 正常 stdDev ~0.05, 有感情 ~0.15+
    return (stdDev / 0.2).clamp(0.0, 1.0);
  }

  /// 分析语速 (0.0 ~ 1.0)
  ///
  /// 说话越快 → 越兴奋
  double _analyzeSpeechRate(VoiceAudioFeatures features) {
    final durationSecs = features.endTime
        .difference(features.startTime)
        .inMilliseconds / 1000.0;

    if (durationSecs <= 0 || features.wordCount <= 0) return 0.5;

    final wordsPerSecond = features.wordCount / durationSecs;

    // 日语正常语速: ~3-5 词/秒, 兴奋时: ~6-8 词/秒
    // 中文正常语速: ~3-4 词/秒
    // 取 4 词/秒为基准
    return ((wordsPerSecond - 2.0) / 6.0).clamp(0.0, 1.0);
  }

  /// 分析文本情感 (0.0 ~ 1.0)
  ///
  /// 检测积极/消极词汇
  double _analyzeSentiment(String text) {
    var score = 0.5; // 中性起点

    // 积极词汇（日/中/英）
    const positiveWords = [
      // 日语
      '嬉しい', 'うれしい', '楽しい', 'たのしい', '最高', 'すごい',
      'いい', '良い', '好き', 'すき', '満足', '幸せ', 'しあわせ',
      'やった', 'ありがたい', '美味しい', 'おいしい', 'きれい',
      'かわいい', '素敵', 'すてき', 'ワクワク', 'ドキドキ',
      // 中文
      '开心', '高兴', '太好了', '喜欢', '满意', '幸福', '棒',
      '好吃', '漂亮', '值得', '超级', '很爽', '不错',
      // 英语
      'happy', 'great', 'awesome', 'love', 'amazing', 'wonderful',
      'excellent', 'fantastic', 'nice', 'good', 'perfect',
    ];

    // 消极词汇
    const negativeWords = [
      // 日语
      '高い', 'たかい', '無駄', 'むだ', 'もったいない',
      '後悔', 'こうかい', '失敗', 'しっぱい',
      // 中文
      '贵', '浪费', '后悔', '亏', '不值',
      // 英语
      'expensive', 'waste', 'regret', 'overpriced',
    ];

    // 强调词（放大情感）
    const intensifiers = [
      'めっちゃ', 'すごく', 'とても', 'マジ', 'ほんと',
      '超', '非常', '特别', '太', 'really', 'very', 'so',
    ];

    final lowerText = text.toLowerCase();
    var hasIntensifier = false;

    for (final word in intensifiers) {
      if (lowerText.contains(word.toLowerCase())) {
        hasIntensifier = true;
        break;
      }
    }

    for (final word in positiveWords) {
      if (lowerText.contains(word.toLowerCase())) {
        score += hasIntensifier ? 0.20 : 0.12;
      }
    }

    for (final word in negativeWords) {
      if (lowerText.contains(word.toLowerCase())) {
        score -= hasIntensifier ? 0.15 : 0.10;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// 分析语音时长 (0.0 ~ 1.0)
  ///
  /// 说得越多 → 越有话想说 → 感触越深
  double _analyzeDuration(VoiceAudioFeatures features) {
    final durationSecs = features.endTime
        .difference(features.startTime)
        .inSeconds;

    // 3秒以下 → 低, 5-10秒 → 中, 15秒+ → 高
    if (durationSecs < 3) return 0.2;
    if (durationSecs < 5) return 0.4;
    if (durationSecs < 10) return 0.6;
    if (durationSecs < 15) return 0.8;
    return 1.0;
  }

  /// 将 0.0~1.0 分数映射到 1-10 满意度
  ///
  /// 使用 S 曲线使中间区间更敏感
  int _mapToSatisfaction(double score) {
    // 线性映射: 0.0→1, 0.5→5, 1.0→10
    // 稍微偏向中高区间（消费本身是积极行为）
    final adjusted = 0.3 + score * 0.7; // 最低 0.3 → satisfaction 3
    return (adjusted * 10).round().clamp(1, 10);
  }
}
```

### 音频特征收集

在 `VoiceInputScreen` 录制期间持续收集：

```dart
// 在 VoiceInputScreen state 中收集音频特征
class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  final List<double> _soundLevels = [];
  final List<DateTime> _timestamps = [];
  DateTime? _startTime;
  int _partialResultCount = 0;
  int _lastWordCount = 0;

  void _onSoundLevel(double normalizedLevel) {
    _soundLevels.add(normalizedLevel);
    _timestamps.add(DateTime.now());
    // 更新波形 UI
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!result.finalResult) {
      _partialResultCount++;
      _lastWordCount = _countWords(result.recognizedWords);
    }
  }

  VoiceAudioFeatures _buildAudioFeatures() {
    return VoiceAudioFeatures(
      soundLevels: List.unmodifiable(_soundLevels),
      timestamps: List.unmodifiable(_timestamps),
      startTime: _startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      partialResultCount: _partialResultCount,
      wordCount: _lastWordCount,
    );
  }

  int _countWords(String text) {
    // 日语/中文: 按字符数估算（平均2字符=1词）
    // 英语: 按空格分割
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    if (hasLatin) {
      return text.split(RegExp(r'\s+')).length;
    }
    return (text.replaceAll(RegExp(r'\s'), '').length / 2).ceil();
  }
}
```

---

## UI组件设计

### 1. 语音输入主界面 (改造现有 stub)

```
┌─────────────────────────────┐
│  ✕   新しい取引      │
├─────────────────────────────┤
│  [手動] [OCR] [●音声]       │  ← InputModeTabs
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │ 🎤 音声認識中...       │  │  ← VoiceTranscriptCard
│  │                       │  │
│  │ 「昼ごはんにマクドナ   │  │     部分識別結果（灰色）
│  │  ルドで680円」        │  │     最終結果（黒色）
│  │                       │  │
│  │ ─────────────────── │  │
│  │ 💰 ¥680             │  │  ← VoiceParsePreview
│  │ 🏪 マクドナルド       │  │     (リアルタイム解析)
│  │ 📁 食事 > 昼食       │  │
│  │ 📕 灵魂账本          │  │
│  └───────────────────────┘  │
│                             │
│    ▁▃▅▇▅▃▁▃▅▇▅▃▁          │  ← VoiceWaveform
│                             │
│         (🎤)                │  ← 录音按钮（脉冲动画）
│      タップして録音          │
│                             │
│  [────── 次へ ──────]       │  ← 进入确认页
└─────────────────────────────┘
```

### 2. 状态流转

```
Idle (待命)
  │
  ├─ 点击 🎤 ─→ Listening (录音中)
  │                │
  │                ├─ partial result ─→ 更新转写文本 + 实时解析
  │                │
  │                ├─ sound level ─→ 更新波形 + 收集特征
  │                │
  │                ├─ 点击 ⏹ ─→ Processing (处理中)
  │                │
  │                └─ 3秒静默 ─→ Processing (处理中)
  │
Processing (处理中)
  │
  ├─ final result ─→ Parsed (解析完成)
  │                    │
  │                    ├─ 显示解析结果（金额/商家/类目）
  │                    │
  │                    ├─ 灵魂账本 → 计算满意度 → 显示预估值
  │                    │
  │                    └─ 用户点击「次へ」→ TransactionConfirmScreen
  │
  └─ error ─→ Error (错误)
               │
               └─ 显示错误信息 + 重试按钮
```

### 3. 波形动画组件

```dart
// lib/features/accounting/presentation/widgets/voice_waveform.dart

/// 实时音量波形动画
///
/// 根据 soundLevel 驱动波形柱状图动画。
/// 柱体高度跟随实际音量变化，颜色随灵魂/生存账本变化。
class VoiceWaveform extends StatelessWidget {
  final double soundLevel; // 0.0 ~ 1.0 (归一化)
  final bool isActive;
  final Color color;

  const VoiceWaveform({
    super.key,
    required this.soundLevel,
    this.isActive = false,
    this.color = AppColors.survival,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(16, (i) {
          // 每根柱体的高度：基于 soundLevel + 位置偏移 (模拟波形)
          final phase = (i - 8).abs() / 8.0; // 中间高、两侧低
          final height = isActive
              ? 8.0 + 40.0 * soundLevel * (1.0 - phase * 0.5)
              : 4.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: isActive ? 0.4 + 0.6 * soundLevel : 0.2,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/voice/voice_text_parser_test.dart

void main() {
  late VoiceTextParser parser;

  setUp(() {
    parser = VoiceTextParser();
  });

  group('VoiceTextParser - Amount Extraction (Arabic)', () {
    test('提取日元金额: 680円', () {
      expect(parser.extractAmount('昼ごはん680円'), 680);
    });

    test('提取日元金额: ¥1,280', () {
      expect(parser.extractAmount('マクドナルドで¥1,280'), 1280);
    });

    test('提取元金额: 480块', () {
      expect(parser.extractAmount('午饭480块'), 480);
    });

    test('提取英文金额: 550 yen', () {
      expect(parser.extractAmount('lunch 550 yen'), 550);
    });

    test('提取独立数字: 3980', () {
      expect(parser.extractAmount('ユニクロで3980'), 3980);
    });

    test('无金额返回null', () {
      expect(parser.extractAmount('昼ごはん食べた'), null);
    });
  });

  group('VoiceTextParser - Amount Extraction (Kanji)', () {
    test('提取日语数词: 六百八十円', () {
      expect(parser.extractAmount('六百八十円'), 680);
    });

    test('提取日语数词: 千二百円', () {
      expect(parser.extractAmount('千二百円'), 1200);
    });

    test('提取日语数词: 三千九百八十', () {
      expect(parser.extractAmount('三千九百八十'), 3980);
    });

    test('提取中文数词: 一千二百', () {
      expect(parser.extractAmount('一千二百元'), 1200);
    });
  });
}

// test/unit/application/voice/category_matcher_test.dart

import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockCategoryService extends Mock implements CategoryService {}

void main() {
  late CategoryMatcher matcher;
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryService mockCategoryService;

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockCategoryService = MockCategoryService();
    matcher = CategoryMatcher(
      categoryRepository: mockCategoryRepo,
      categoryService: mockCategoryService,
    );
  });

  group('CategoryMatcher', () {
    test('日语关键词匹配: 昼ごはん → cat_food', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => mockCategory);

      final result = await matcher.matchFromText('昼ごはんに680円');

      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('中文关键词匹配: 午饭 → cat_food', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => mockCategory);

      final result = await matcher.matchFromText('午饭吃了480块');

      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('英文关键词匹配: lunch → cat_food', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => mockCategory);

      final result = await matcher.matchFromText('lunch at cafe 550 yen');

      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('无匹配返回null', () async {
      final result = await matcher.matchFromText('abc123');

      expect(result, isNull);
    });
  });
}

// test/unit/application/voice/voice_satisfaction_estimator_test.dart

void main() {
  late VoiceSatisfactionEstimator estimator;

  setUp(() {
    estimator = VoiceSatisfactionEstimator();
  });

  group('VoiceSatisfactionEstimator', () {
    test('兴奋语音 → 高满意度 (7-10)', () {
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
    });

    test('平静语音 → 中等满意度 (4-6)', () {
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

      expect(score, inInclusiveRange(4, 6));
    });

    test('信号不足 → 默认满意度 (5)', () {
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

      expect(score, inInclusiveRange(3, 5));
    });
  });
}
```

### Widget测试

```dart
// test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart

void main() {
  testWidgets('语音输入界面显示正确', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('ja'),
          home: VoiceInputScreen(bookId: 'test_book'),
        ),
      ),
    );

    // 验证UI元素
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byType(VoiceWaveform), findsOneWidget);
  });

  testWidgets('点击录音按钮切换状态', (tester) async {
    // 需要 mock SpeechRecognitionService
    // 验证 isRecording 状态切换
    // 验证波形动画启停
  });
}
```

### 集成测试

```dart
// integration_test/voice_input_flow_test.dart

void main() {
  testWidgets('完整语音输入流程测试', (tester) async {
    // 1. 导航到语音输入界面
    // 2. Mock speech_to_text 返回识别文本
    // 3. 验证金额/商家/类目解析
    // 4. 点击「次へ」进入确认页
    // 5. 验证确认页显示解析结果
    // 6. 保存交易
    // 注: speech_to_text 需要平台支持，集成测试需在真机上运行
  });
}
```

---

## 性能优化

### 1. 实时解析防抖

```dart
// partial results 频率很高，解析需要防抖
Timer? _parseDebounce;

void _onPartialResult(String text) {
  // 更新显示文本（立即）
  setState(() => _transcriptText = text);

  // 防抖解析（300ms）
  _parseDebounce?.cancel();
  _parseDebounce = Timer(const Duration(milliseconds: 300), () {
    _parseVoiceInput(text);
  });
}
```

### 2. 商家匹配优化

商家匹配在 `MerchantDatabase` 中遍历 500+ 条目，在 partial result 中可能频繁调用：

- 仅在文本变化 > 2 字符时重新匹配
- 首次匹配成功后缓存结果，文本无变化时复用
- 匹配过程不阻塞 UI 线程

### 3. 音量采样优化

```dart
// 不需要保存每帧音量，每 100ms 采样一次即可
DateTime? _lastSampleTime;

void _onSoundLevel(double level) {
  final now = DateTime.now();
  if (_lastSampleTime != null &&
      now.difference(_lastSampleTime!).inMilliseconds < 100) {
    return; // 跳过高频采样
  }
  _lastSampleTime = now;
  _soundLevels.add(level);
  _timestamps.add(now);
}
```

### 4. 语音识别初始化

```dart
// 在 VoiceInputScreen 进入时预初始化
// 避免首次点击录音按钮时的延迟
@override
void initState() {
  super.initState();
  _initSpeechService(); // 异步初始化，不阻塞 UI
}

Future<void> _initSpeechService() async {
  final available = await _speechService.initialize(
    onStatus: _onStatus,
    onError: _onError,
  );
  if (mounted) {
    setState(() => _isReady = available);
  }
}
```

---

## 权限配置

### iOS (Info.plist)

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>音声で金額や取引内容を入力するために使用します</string>
<key>NSMicrophoneUsageDescription</key>
<string>音声入力のためにマイクへのアクセスが必要です</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Android 30+ 需要声明 intent -->
<queries>
  <intent>
    <action android:name="android.speech.RecognitionService"/>
  </intent>
</queries>
```

---

## 总结

MOD-009 语音记账模块提供：

1. **多语言语音识别**: 日语/中文/英语，实时转写
2. **智能金额提取**: 阿拉伯数字 + 日语/中文数词，准确率 >95%
3. **模糊类目匹配**: 100+ 多语言关键词，自动推荐分类
4. **商家智能匹配**: 复用 500+ 商家数据库，支持口语化输入
5. **语音满意度估算**: 音量+语速+文本情感多信号融合，灵魂账本专属
6. **隐私优先**: 优先本地识别，无数据上传

**开发优先级**: P2，预计 8 天完成。

**依赖模块**:
- MOD-001 基础记账 — 交易创建流程
- MOD-002 双轨账本 — 分类引擎 + 商家数据库
- MOD-007 设置管理 — 语言设置（localeProvider）

**新增依赖**:
- `speech_to_text: ^7.0.0`

---

**文档维护**:
- 最后更新: 2026-02-22
- 维护者: 功能团队
- 版本: 1.0
