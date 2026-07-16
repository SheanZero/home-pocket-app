import '../../features/accounting/domain/models/transaction.dart';

/// Side-effect-free result of parsing one shopping-list utterance.
///
/// Every parsed field is optional so callers can keep the user's existing form
/// value when speech does not provide a trustworthy replacement. Privacy type
/// is intentionally absent: speech must never infer whether an item is public
/// or private.
class ShoppingVoiceDraft {
  const ShoppingVoiceDraft({
    required this.rawText,
    this.name,
    this.quantity,
    this.ledgerType,
    this.categoryId,
    this.estimatedPrice,
  });

  final String rawText;
  final String? name;
  final int? quantity;
  final LedgerType? ledgerType;
  final String? categoryId;
  final int? estimatedPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingVoiceDraft &&
          other.rawText == rawText &&
          other.name == name &&
          other.quantity == quantity &&
          other.ledgerType == ledgerType &&
          other.categoryId == categoryId &&
          other.estimatedPrice == estimatedPrice;

  @override
  int get hashCode => Object.hash(
    rawText,
    name,
    quantity,
    ledgerType,
    categoryId,
    estimatedPrice,
  );

  @override
  String toString() =>
      'ShoppingVoiceDraft('
      'rawText: $rawText, '
      'name: $name, '
      'quantity: $quantity, '
      'ledgerType: $ledgerType, '
      'categoryId: $categoryId, '
      'estimatedPrice: $estimatedPrice)';
}

/// Parses a single-item shopping utterance without persistence or I/O.
///
/// The parser deliberately favors partial, high-confidence output over
/// guessing. Missing and conflicting fields remain null for the form to resolve
/// explicitly. This use case only creates a draft; it never saves an item.
class ParseShoppingVoiceInputUseCase {
  const ParseShoppingVoiceInputUseCase();

  ShoppingVoiceDraft execute(String text, {required String localeId}) {
    final locale = _localeFor(localeId);
    final parseText = text.trim();
    if (parseText.isEmpty || locale == _ShoppingVoiceLocale.unsupported) {
      return ShoppingVoiceDraft(rawText: text);
    }

    final name = _extractName(parseText, locale);
    return ShoppingVoiceDraft(
      rawText: text,
      name: name,
      quantity: _extractQuantity(parseText, locale),
      ledgerType: _extractLedgerType(parseText, locale),
      categoryId: name == null ? null : _inferCategoryId(name),
      estimatedPrice: _extractEstimatedPrice(parseText, locale),
    );
  }
}

enum _ShoppingVoiceLocale { ja, zh, en, unsupported }

const _arabicNumberPattern = r'[0-9０-９][0-9０-９,，]*';
const _cjkNumberPattern = r'[零〇一二两兩三四五六七八九十百千万萬]+';
const _localizedNumberPattern = '(?:$_arabicNumberPattern|$_cjkNumberPattern)';
const _englishNumberWord =
    r'(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)';
const _englishNumberPattern =
    '(?:$_arabicNumberPattern|$_englishNumberWord(?:[ -]+$_englishNumberWord)*)';
const _localizedPriceNumberBoundary = r'(?![0-9０-９,，零〇一二两兩三四五六七八九十百千万萬])';
const _englishPriceNumberBoundary = r'(?![A-Za-z0-9０-９,，-])';
const _priceClauseBoundary = r'(?=$|[\s,，、;；。.!！？)\]】])';

const _jaCounterPattern = r'(?:個|本|袋|箱|パック|枚|冊|つ|台|缶|瓶|セット|人前|巻)';
const _zhCounterPattern = r'(?:个|個|件|瓶|袋|盒|箱|包|罐|罐|本|支|条|條|份|套|双|雙|卷|桶|提|斤)';
const _enCounterPattern =
    r'(?:bottles?|bags?|boxes?|packs?|cartons?|cans?|jars?|pieces?|items?|rolls?|pairs?|sets?|loaves?)';

_ShoppingVoiceLocale _localeFor(String localeId) {
  final normalized = localeId.trim().toLowerCase();
  if (normalized.startsWith('ja')) return _ShoppingVoiceLocale.ja;
  if (normalized.startsWith('zh')) return _ShoppingVoiceLocale.zh;
  if (normalized.startsWith('en')) return _ShoppingVoiceLocale.en;
  return _ShoppingVoiceLocale.unsupported;
}

LedgerType? _extractLedgerType(String text, _ShoppingVoiceLocale locale) {
  final lower = text.toLowerCase();
  late final bool hasDaily;
  late final bool hasJoy;

  switch (locale) {
    case _ShoppingVoiceLocale.ja:
      hasDaily = RegExp(r'日常(?:支出)?|普段使い').hasMatch(text);
      hasJoy = RegExp(r'ときめき(?:支出)?|悦己').hasMatch(text);
    case _ShoppingVoiceLocale.zh:
      hasDaily = RegExp(r'日常(?:支出)?|生活必需').hasMatch(text);
      hasJoy = RegExp(r'悦己|悅己|犒劳自己|犒勞自己').hasMatch(text);
    case _ShoppingVoiceLocale.en:
      hasDaily = RegExp(
        r'\b(?:daily|everyday|essential)\b',
        caseSensitive: false,
      ).hasMatch(lower);
      hasJoy = RegExp(r'\bjoy\b', caseSensitive: false).hasMatch(lower);
    case _ShoppingVoiceLocale.unsupported:
      return null;
  }

  if (hasDaily == hasJoy) return null;
  return hasJoy ? LedgerType.joy : LedgerType.daily;
}

int? _extractQuantity(String text, _ShoppingVoiceLocale locale) {
  RegExpMatch? match;
  switch (locale) {
    case _ShoppingVoiceLocale.ja:
      match = RegExp(
        '($_localizedNumberPattern)\\s*$_jaCounterPattern',
      ).firstMatch(text);
    case _ShoppingVoiceLocale.zh:
      match = RegExp(
        '($_localizedNumberPattern)\\s*$_zhCounterPattern',
      ).firstMatch(text);
    case _ShoppingVoiceLocale.en:
      match = RegExp(
        '\\b($_englishNumberPattern)\\s*$_enCounterPattern\\b',
        caseSensitive: false,
      ).firstMatch(text);
      match ??= RegExp(
        '\\b(?:quantity|qty)\\s*(?:is|:)?\\s*($_englishNumberPattern)\\b',
        caseSensitive: false,
      ).firstMatch(text);
      match ??= RegExp(
        '\\bx\\s*($_arabicNumberPattern)\\b',
        caseSensitive: false,
      ).firstMatch(text);
      match ??= RegExp(
        '\\b(?:add|buy|get|need|want)\\s+($_englishNumberPattern)\\s+(?=[a-z])',
        caseSensitive: false,
      ).firstMatch(text);
    case _ShoppingVoiceLocale.unsupported:
      return null;
  }

  final value = _parseNumber(match?.group(1), locale);
  return value != null && value > 0 && value <= 999 ? value : null;
}

int? _extractEstimatedPrice(String text, _ShoppingVoiceLocale locale) {
  // estimatedPrice is an integer amount in the app's local JPY contract. A
  // foreign amount cannot be stored safely without an exchange-rate context,
  // so explicit non-JPY currencies are ignored instead of being mislabeled as
  // yen (for example, "5 dollars" must never become ¥5).
  final hasExplicitForeignCurrency = RegExp(
    r'(?:[$£€₩₽₹฿₫₱]'
    r'|(?:^|[^A-Za-z])(?:dollars?|bucks?|usd|aud|cad|hkd|sgd|nzd|pounds?|sterling|gbp|euros?|eur|yuan|renminbi|cny|rmb|won|krw|rubles?|rub|rupees?|inr|baht|thb|vnd|php|twd)(?![A-Za-z])'
    r'|(?:ドル|ポンド|ユーロ|人民元|中国元|韓国ウォン|ウォン)'
    r'|(?:美元|美金|英镑|英鎊|欧元|歐元|人民币|人民幣|人民元|韩元|韓元|韩币|韓幣|港币|港幣|澳元|加元|新台币|新台幣|台币|台幣))',
    caseSensitive: false,
  ).hasMatch(text);
  if (hasExplicitForeignCurrency) {
    return null;
  }

  final patterns = switch (locale) {
    _ShoppingVoiceLocale.ja => [
      RegExp(
        '(?:参考価格|価格|予算)\\s*(?:は|が|:|：)?\\s*[¥￥]\\s*'
        '($_localizedNumberPattern)$_localizedPriceNumberBoundary'
        '(?:\\s*(?:円|えん))?$_priceClauseBoundary',
      ),
      RegExp(
        '(?:参考価格|価格|予算)\\s*(?:は|が|:|：)?\\s*'
        '($_localizedNumberPattern)\\s*(?:円|えん)$_priceClauseBoundary',
      ),
      RegExp(
        '(?:参考価格|価格|予算)\\s*(?:は|が|:|：)?\\s*'
        '($_localizedNumberPattern)$_localizedPriceNumberBoundary'
        '$_priceClauseBoundary',
      ),
      RegExp(
        '[¥￥]\\s*($_localizedNumberPattern)'
        '$_localizedPriceNumberBoundary(?:\\s*(?:円|えん))?'
        '$_priceClauseBoundary',
      ),
      RegExp('($_localizedNumberPattern)\\s*(?:円|えん)$_priceClauseBoundary'),
    ],
    _ShoppingVoiceLocale.zh => [
      RegExp(
        '(?:参考价格|參考價格|预估价格|預估價格|价格|價格|预算|預算)'
        '\\s*(?:是|为|為|:|：)?\\s*[¥￥]\\s*'
        '($_localizedNumberPattern)$_localizedPriceNumberBoundary'
        '(?:\\s*(?:元|块|塊))?$_priceClauseBoundary',
      ),
      RegExp(
        '(?:参考价格|參考價格|预估价格|預估價格|价格|價格|预算|預算)'
        '\\s*(?:是|为|為|:|：)?\\s*'
        '($_localizedNumberPattern)\\s*(?:元|块|塊)'
        '$_priceClauseBoundary',
      ),
      RegExp(
        '(?:参考价格|參考價格|预估价格|預估價格|价格|價格|预算|預算)'
        '\\s*(?:是|为|為|:|：)?\\s*'
        '($_localizedNumberPattern)$_localizedPriceNumberBoundary'
        '$_priceClauseBoundary',
      ),
      RegExp(
        '[¥￥]\\s*($_localizedNumberPattern)'
        '$_localizedPriceNumberBoundary(?:\\s*(?:元|块|塊))?'
        '$_priceClauseBoundary',
      ),
      RegExp(
        '($_localizedNumberPattern)\\s*(?:元|块|塊)'
        '$_priceClauseBoundary',
      ),
    ],
    _ShoppingVoiceLocale.en => [
      RegExp(
        '\\b(?:estimated(?:\\s+price)?|estimate|reference\\s+price|price|budget)'
        '\\s*(?:is|of|at|:)?\\s*(?:[¥￥]|jpy)\\s*'
        '($_englishNumberPattern)$_englishPriceNumberBoundary'
        '(?:\\s*(?:yen|jpy)\\b)?$_priceClauseBoundary',
        caseSensitive: false,
      ),
      RegExp(
        '\\b(?:estimated(?:\\s+price)?|estimate|reference\\s+price|price|budget)'
        '\\s*(?:is|of|at|:)?\\s*'
        '($_englishNumberPattern)\\s*(?:yen|jpy)\\b'
        '$_priceClauseBoundary',
        caseSensitive: false,
      ),
      RegExp(
        '\\b(?:estimated(?:\\s+price)?|estimate|reference\\s+price|price|budget)'
        '\\s*(?:is|of|at|:)?\\s*'
        '($_englishNumberPattern)$_englishPriceNumberBoundary'
        '$_priceClauseBoundary',
        caseSensitive: false,
      ),
      RegExp(
        '[¥￥]\\s*($_englishNumberPattern)$_englishPriceNumberBoundary'
        '(?:\\s*(?:yen|jpy)\\b)?$_priceClauseBoundary',
        caseSensitive: false,
      ),
      RegExp(
        '\\b($_englishNumberPattern)\\s*(?:yen|jpy)\\b'
        '$_priceClauseBoundary',
        caseSensitive: false,
      ),
    ],
    _ShoppingVoiceLocale.unsupported => const <RegExp>[],
  };

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    final value = _parseNumber(match?.group(1), locale);
    if (value != null && value > 0 && value < 10000000) return value;
  }
  return null;
}

String? _extractName(String text, _ShoppingVoiceLocale locale) {
  final clauses = text.split(RegExp(r'[,，、;；。.!！？]+'));
  for (final clause in clauses) {
    final cleaned = switch (locale) {
      _ShoppingVoiceLocale.ja => _cleanJapaneseNameClause(clause),
      _ShoppingVoiceLocale.zh => _cleanChineseNameClause(clause),
      _ShoppingVoiceLocale.en => _cleanEnglishNameClause(clause),
      _ShoppingVoiceLocale.unsupported => '',
    };
    if (_looksLikeName(cleaned)) return cleaned;
  }
  return null;
}

String _cleanJapaneseNameClause(String value) {
  var result = value.trim();
  result = result.replaceFirst(
    RegExp(r'^(?:買い物リストに)?(?:追加して|追加|買って|買う|購入して|購入|欲しい)　?\s*'),
    '',
  );
  result = result.replaceAll(
    RegExp(
      '(?:参考価格|価格|予算)\\s*(?:は|が|:|：)?\\s*[¥￥]?\\s*$_localizedNumberPattern\\s*(?:円|えん)?',
    ),
    '',
  );
  result = result.replaceAll(RegExp(r'日常(?:支出)?|普段使い|ときめき(?:支出)?|悦己'), '');
  result = result.replaceAll(
    RegExp(
      '(?:を\\s*)?$_localizedNumberPattern\\s*$_jaCounterPattern(?:\\s*の)?',
    ),
    '',
  );
  return _trimNameConnectors(result, RegExp(r'^[のをにと\s]+|[のをにと\s]+$'));
}

String _cleanChineseNameClause(String value) {
  var result = value.trim();
  result = result.replaceFirst(
    RegExp(r'^(?:请|請)?(?:帮我|幫我|我要|我想要|给我|給我)?(?:买|買|添加|加上|来|來|要)\s*'),
    '',
  );
  result = result.replaceAll(
    RegExp(
      '(?:参考价格|參考價格|预估价格|預估價格|价格|價格|预算|預算)\\s*(?:是|为|為|:|：)?\\s*[¥￥]?\\s*$_localizedNumberPattern\\s*(?:元|块|塊)?',
    ),
    '',
  );
  result = result.replaceAll(RegExp(r'日常(?:支出)?|生活必需|悦己|悅己|犒劳自己|犒勞自己'), '');
  result = result.replaceAll(
    RegExp('$_localizedNumberPattern\\s*$_zhCounterPattern'),
    '',
  );
  return _trimNameConnectors(result, RegExp(r'^[的\s]+|[的\s]+$'));
}

String _cleanEnglishNameClause(String value) {
  var result = value.trim();
  result = result.replaceFirst(
    RegExp(
      r'^(?:please\s+)?(?:add|buy|get|put|purchase|i\s+need|i\s+want)\s+',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(
      '\\b(?:estimated(?:\\s+price)?|estimate|reference\\s+price|price|budget)\\s*(?:is|of|at|:)?\\s*(?:[\\\$£€]\\s*)?$_englishNumberPattern\\s*(?:dollars?|usd|yen|jpy|pounds?|gbp|euros?|eur)?\\b',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(r'\b(?:daily|everyday|essential|joy)\b', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(
      '\\b(?:quantity|qty)\\s*(?:is|:)?\\s*$_englishNumberPattern\\b',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(
      '\\b$_englishNumberPattern\\s*$_enCounterPattern\\s*(?:of\\s+)?',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(r'\bx\s*[0-9０-９]+\b', caseSensitive: false),
    '',
  );
  result = result.replaceFirst(
    RegExp('^$_englishNumberPattern\\s+(?=[A-Za-z])', caseSensitive: false),
    '',
  );
  return _trimNameConnectors(
    result,
    RegExp(r'^(?:of|a|an|the|and)\s+|\s+(?:and)$', caseSensitive: false),
  );
}

String _trimNameConnectors(String value, RegExp connectors) {
  var result = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  var previous = '';
  while (result != previous) {
    previous = result;
    result = result.replaceAll(connectors, '').trim();
  }
  return result;
}

bool _looksLikeName(String value) {
  if (value.isEmpty || value.length > 200) return false;
  if (!RegExp(r'[A-Za-z぀-ヿ㐀-鿿]').hasMatch(value)) return false;
  if (RegExp(r'^[\d０-９\s¥￥$£€]+$').hasMatch(value)) return false;
  return true;
}

String? _inferCategoryId(String name) {
  final normalized = name.toLowerCase();
  const categoryKeywords = <String, List<String>>{
    'cat_food_groceries': [
      '牛乳',
      'ミルク',
      '牛奶',
      'milk',
      'パン',
      '面包',
      '麵包',
      'bread',
      '卵',
      '鸡蛋',
      '雞蛋',
      'eggs',
      '食料品',
      '蔬菜',
      'groceries',
    ],
    'cat_daily_household': [
      'トイレットペーパー',
      '洗剤',
      'ティッシュ',
      '卫生纸',
      '衛生紙',
      '洗衣液',
      '肥皂',
      'toilet paper',
      'detergent',
      'soap',
    ],
    'cat_food_cafe': ['コーヒー', '咖啡', 'coffee'],
  };

  for (final entry in categoryKeywords.entries) {
    if (entry.value.any(normalized.contains)) return entry.key;
  }
  return null;
}

int? _parseNumber(String? raw, _ShoppingVoiceLocale locale) {
  if (raw == null) return null;
  final normalized = _normalizeDigits(raw).trim();
  if (normalized.isEmpty) return null;

  final digitsOnly = normalized.replaceAll(RegExp(r'[,，\s]'), '');
  if (RegExp(r'^\d+$').hasMatch(digitsOnly)) {
    return int.tryParse(digitsOnly);
  }
  if (locale == _ShoppingVoiceLocale.en) {
    return _parseEnglishNumber(normalized);
  }
  return _parseCjkNumber(normalized);
}

String _normalizeDigits(String value) {
  const fullWidth = '０１２３４５６７８９';
  const ascii = '0123456789';
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = fullWidth.indexOf(char);
    buffer.write(index == -1 ? char : ascii[index]);
  }
  return buffer.toString();
}

int? _parseCjkNumber(String value) {
  const digits = <String, int>{
    '零': 0,
    '〇': 0,
    '一': 1,
    '二': 2,
    '两': 2,
    '兩': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };
  const units = <String, int>{'十': 10, '百': 100, '千': 1000};
  final characters = value.runes.map(String.fromCharCode).toList();
  if (!characters.any(
    (character) =>
        units.containsKey(character) || character == '万' || character == '萬',
  )) {
    final joined = characters.map((character) => digits[character]).join();
    return joined.contains('null') ? null : int.tryParse(joined);
  }

  var total = 0;
  var section = 0;
  var number = 0;
  for (final character in characters) {
    final digit = digits[character];
    if (digit != null) {
      number = digit;
      continue;
    }
    final unit = units[character];
    if (unit != null) {
      section += (number == 0 ? 1 : number) * unit;
      number = 0;
      continue;
    }
    if (character == '万' || character == '萬') {
      section += number;
      total += (section == 0 ? 1 : section) * 10000;
      section = 0;
      number = 0;
      continue;
    }
    return null;
  }
  return total + section + number;
}

int? _parseEnglishNumber(String value) {
  const units = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };
  const tens = <String, int>{
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  var total = 0;
  var current = 0;
  final tokens = value.toLowerCase().split(RegExp(r'[\s-]+'));
  for (final token in tokens) {
    if (units.containsKey(token)) {
      current += units[token]!;
    } else if (tens.containsKey(token)) {
      current += tens[token]!;
    } else if (token == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
    } else if (token == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    } else {
      return null;
    }
  }
  return total + current;
}
