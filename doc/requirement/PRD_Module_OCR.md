# PRD - OCR扫描模块

**模块ID:** MOD-005
**模块名称:** OCR扫描模块
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P1（强烈建议）
**预估工时:** 7天

---

## 1. 模块概述

### 1.1 功能定义

OCR扫描模块通过相机扫描纸质收据,自动识别金额、日期、商家信息并创建交易记录。包括:

- **收据扫描（A10）:** 拍照或从相册选择
- **OCR识别:** 金额、日期、商家名称自动提取
- **商家自动分类（A11）:** 根据商家匹配分类和账户类型
- **用户确认:** 可编辑识别结果
- **照片加密存储:** 收据照片端到端加密保存

**核心价值主张:**
将纸质收据数字化,节省手动输入时间。通过商家数据库自动分类,进一步提升记账效率。

**注意:** 根据可行性研究,准确率目标调整为90%（不是95%）,因为ML Kit在手写/褪色收据上准确率有限。

### 1.2 用户场景与痛点

**用户画像:**
- 佐藤太郎（35岁,经常外食）
- 钱包里积累了大量纸质收据
- 每周末才有时间整理,经常忘记当时买了什么

**痛点:**
1. **手动输入繁琐:** 一张收据要输入金额、日期、商家,容易出错
2. **收据丢失:** 纸质收据容易褪色、丢失,事后无法查证
3. **分类困难:** 不确定这笔消费应该归为哪个分类

**Home Pocket解决方案:**
- 一键扫描,2秒内完成信息提取
- 收据照片加密保存,永不丢失
- 商家数据库自动匹配分类和账户类型

### 1.3 与其他模块的依赖关系

**前置依赖:**
- MOD-001 基础记账（需要交易创建流程）
- MOD-003 双轨账本（需要商家数据库）
- MOD-006 安全与隐私（需要照片加密）

**被依赖:**
- MOD-009 趣味功能（小票占卜）

---

## 2. 详细功能规格

### 2.1 A10: 收据扫描

#### 2.1.1 技术选型

**iOS:**
- 框架: Vision Framework
- API: `VNRecognizeTextRequest`
- 语言: 日语（ja）+ 英语（en）
- 识别级别: `accurate`（高精度模式）

**Android:**
- 框架: ML Kit Text Recognition v2
- API: `TextRecognizer`
- 语言: 日语 + 英语
- 模型: 设备端模型（无需网络）

**为什么不用第三方云OCR（如Google Cloud Vision）?**
- 隐私承诺:数据不上传服务器
- 成本考虑:避免API调用费用
- 离线可用:无网络也能使用

#### 2.1.2 识别目标

| 字段 | 正则表达式 | 准确率目标 |
|------|-----------|----------|
| 金额 | `¥?\s*\d{1,3}(,\d{3})*\s*円?` | >90% |
| 日期 | `\d{4}[年/.-]\d{1,2}[月/.-]\d{1,2}日?` | >85% |
| 商家 | OCR结果第一行（启发式）| >80% |
| 合计 | 关键词匹配 `合計\|合计\|TOTAL\|小計` | >90% |

**降低目标的原因（根据可行性研究）:**
- ML Kit在打印清晰的收据上表现良好（>95%）
- 但在手写、褪色、褶皱的收据上准确率下降至80-85%
- MVP阶段接受较低准确率,提供手动修正流程

#### 2.1.3 识别流程

```dart
// lib/features/ocr/domain/use_cases/scan_receipt.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ScanReceiptUseCase {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
  final MerchantDatabase _merchantDB;
  final EncryptionService _encryption;

  Future<ReceiptData> execute({
    required ImageSource source,  // camera or gallery
  }) async {
    // 1. 获取图像
    final XFile? image = await ImagePicker().pickImage(source: source);
    if (image == null) {
      throw CancelledException('用户取消选择');
    }

    // 2. 图像预处理（提高识别准确率）
    final processedImage = await _preprocessImage(image);

    // 3. OCR识别
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    // 4. 结构化提取
    final extractedData = _extractData(recognizedText);

    // 5. 商家自动分类
    final category = await _classifyMerchant(extractedData.merchant);

    // 6. 加密存储照片
    final photoHash = await _encryptAndStorePhoto(image);

    return ReceiptData(
      amount: extractedData.amount,
      date: extractedData.date,
      merchant: extractedData.merchant,
      category: category,
      photoHash: photoHash,
      rawText: recognizedText.text,
      confidence: extractedData.confidence,
    );
  }

  /// 图像预处理（去噪、二值化、旋转校正）
  Future<XFile> _preprocessImage(XFile image) async {
    final bytes = await image.readAsBytes();
    img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw ImageProcessingException('图像解码失败');
    }

    // 1. 灰度化
    decodedImage = img.grayscale(decodedImage);

    // 2. 对比度增强
    decodedImage = img.adjustColor(decodedImage, contrast: 1.5);

    // 3. 二值化（提高文字清晰度）
    decodedImage = _binarize(decodedImage);

    // 4. 旋转校正（如果需要）
    decodedImage = await _correctRotation(decodedImage);

    // 5. 保存处理后的图像
    final processedBytes = img.encodePng(decodedImage);
    final tempDir = await getTemporaryDirectory();
    final processedFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png');
    await processedFile.writeAsBytes(processedBytes);

    return XFile(processedFile.path);
  }

  img.Image _binarize(img.Image image) {
    // Otsu二值化算法
    final threshold = _calculateOtsuThreshold(image);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        final newPixel = gray > threshold ? img.ColorRgba8(255, 255, 255, 255) : img.ColorRgba8(0, 0, 0, 255);
        image.setPixel(x, y, newPixel);
      }
    }

    return image;
  }

  int _calculateOtsuThreshold(img.Image image) {
    // 简化版Otsu算法（完整实现略）
    return 128;  // MVP阶段使用固定阈值
  }

  /// 结构化数据提取
  ExtractedData _extractData(RecognizedText recognizedText) {
    final text = recognizedText.text;
    final lines = text.split('\n');

    // 1. 提取金额
    final amount = _extractAmount(text);

    // 2. 提取日期
    final date = _extractDate(text);

    // 3. 提取商家名称（启发式：第一行非日期文本）
    final merchant = _extractMerchant(lines);

    return ExtractedData(
      amount: amount,
      date: date,
      merchant: merchant,
      confidence: _calculateConfidence(amount, date, merchant),
    );
  }

  int? _extractAmount(String text) {
    // 正则匹配：¥1,280 或 1280円 或 1280
    final patterns = [
      RegExp(r'[¥￥]\s*(\d{1,3}(?:,\d{3})*)', multiLine: true),
      RegExp(r'(\d{1,3}(?:,\d{3})*)\s*円', multiLine: true),
      RegExp(r'合計.*?(\d{1,3}(?:,\d{3})*)', multiLine: true),
      RegExp(r'TOTAL.*?(\d{1,3}(?:,\d{3})*)', multiLine: true, caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        return int.tryParse(amountStr);
      }
    }

    // 回退：查找最大的数字（可能是合计金额）
    final numbers = RegExp(r'\d{1,3}(?:,\d{3})*').allMatches(text);
    final amounts = numbers
        .map((m) => int.tryParse(m.group(0)!.replaceAll(',', '')))
        .where((a) => a != null && a > 0)
        .toList();

    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b!.compareTo(a!));
      return amounts.first;
    }

    return null;
  }

  DateTime? _extractDate(String text) {
    // 正则匹配日期格式
    final patterns = [
      RegExp(r'(\d{4})[年/.-](\d{1,2})[月/.-](\d{1,2})日?'),
      RegExp(r'(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})'),
      RegExp(r'(\d{2})[/.-](\d{1,2})[/.-](\d{1,2})'),  // YY/MM/DD
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          var year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);

          // 如果是两位年份,补全为完整年份
          if (year < 100) {
            year += 2000;
          }

          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }

    // 回退：使用当前日期
    return DateTime.now();
  }

  String? _extractMerchant(List<String> lines) {
    // 启发式：第一行非空、非日期、非金额的文本
    for (final line in lines) {
      final trimmed = line.trim();

      // 跳过空行
      if (trimmed.isEmpty) continue;

      // 跳过纯数字或日期
      if (RegExp(r'^\d+$').hasMatch(trimmed)) continue;
      if (RegExp(r'\d{4}[年/.-]').hasMatch(trimmed)) continue;

      // 跳过金额行
      if (trimmed.contains('¥') || trimmed.contains('円') || trimmed.contains('合計')) continue;

      // 可能是商家名称
      return trimmed;
    }

    return null;
  }

  double _calculateConfidence(int? amount, DateTime? date, String? merchant) {
    var confidence = 0.0;

    if (amount != null && amount > 0) confidence += 0.4;
    if (date != null) confidence += 0.3;
    if (merchant != null && merchant.isNotEmpty) confidence += 0.3;

    return confidence;
  }

  /// 商家自动分类
  Future<CategoryMatch?> _classifyMerchant(String? merchant) async {
    if (merchant == null || merchant.isEmpty) {
      return null;
    }

    return _merchantDB.findMerchant(merchant);
  }

  /// 加密存储照片
  Future<String> _encryptAndStorePhoto(XFile image) async {
    // 1. 读取图像字节
    final bytes = await image.readAsBytes();

    // 2. 加密
    final encryptedBytes = await _encryption.encryptBytes(bytes);

    // 3. 计算哈希（作为文件名）
    final hash = sha256.convert(bytes);
    final photoHash = base64Encode(hash.bytes);

    // 4. 保存到应用目录
    final appDir = await getApplicationDocumentsDirectory();
    final photoFile = File('${appDir.path}/receipts/$photoHash.enc');
    await photoFile.create(recursive: true);
    await photoFile.writeAsBytes(encryptedBytes);

    return photoHash;
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}

class ReceiptData {
  final int? amount;
  final DateTime? date;
  final String? merchant;
  final CategoryMatch? category;
  final String photoHash;
  final String rawText;
  final double confidence;

  ReceiptData({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.category,
    required this.photoHash,
    required this.rawText,
    required this.confidence,
  });
}

class ExtractedData {
  final int? amount;
  final DateTime? date;
  final String? merchant;
  final double confidence;

  ExtractedData({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.confidence,
  });
}
```

---

### 2.2 A11: 商家自动分类

**商家数据库（500+日本商家）:**

```dart
// lib/features/ocr/data/merchant_database.dart

class MerchantDatabase {
  /// 日本常见商家数据库
  static const Map<String, MerchantInfo> merchants = {
    // 便利店
    'セブンイレブン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['セブン', '7-11', '7-ELEVEN'],
    ),
    'ファミリーマート': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['ファミマ', 'FamilyMart'],
    ),
    'ローソン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['LAWSON'],
    ),

    // 超市
    'イオン': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      aliases: ['AEON'],
    ),
    'イトーヨーカドー': MerchantInfo(
      category: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      aliases: ['ITO YOKADO'],
    ),

    // 餐饮
    '吉野家': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['YOSHINOYA'],
    ),
    'マクドナルド': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ["McDonald's", 'マック'],
    ),
    'スターバックス': MerchantInfo(
      category: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['STARBUCKS', 'スタバ'],
    ),

    // 交通
    'JR東日本': MerchantInfo(
      category: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['JR EAST'],
    ),
    '東京メトロ': MerchantInfo(
      category: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['TOKYO METRO'],
    ),

    // 购物
    'ヨドバシカメラ': MerchantInfo(
      category: 'shopping_electronics',
      ledgerType: LedgerType.soul,
      confidence: 0.8,
      aliases: ['Yodobashi'],
    ),
    'ユニクロ': MerchantInfo(
      category: 'shopping_fashion',
      ledgerType: LedgerType.soul,
      confidence: 0.85,
      aliases: ['UNIQLO'],
    ),

    // 医疗
    'マツモトキヨシ': MerchantInfo(
      category: 'medical',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      aliases: ['Matsumoto Kiyoshi'],
    ),

    // ... 省略其他商家 ...
  };

  /// 查找商家
  CategoryMatch? findMerchant(String merchantName) {
    // 1. 精确匹配
    if (merchants.containsKey(merchantName)) {
      final info = merchants[merchantName]!;
      return CategoryMatch(info.category, info.confidence);
    }

    // 2. 别名匹配
    for (final entry in merchants.entries) {
      if (entry.value.aliases.contains(merchantName)) {
        return CategoryMatch(entry.value.category, entry.value.confidence);
      }
    }

    // 3. 模糊匹配（包含关系）
    for (final entry in merchants.entries) {
      if (merchantName.contains(entry.key) || entry.key.contains(merchantName)) {
        return CategoryMatch(entry.value.category, entry.value.confidence * 0.8);
      }

      // 检查别名
      for (final alias in entry.value.aliases) {
        if (merchantName.contains(alias) || alias.contains(merchantName)) {
          return CategoryMatch(entry.value.category, entry.value.confidence * 0.8);
        }
      }
    }

    return null;
  }
}

class MerchantInfo {
  final String category;
  final LedgerType ledgerType;
  final double confidence;
  final List<String> aliases;

  const MerchantInfo({
    required this.category,
    required this.ledgerType,
    required this.confidence,
    this.aliases = const [],
  });
}
```

---

### 2.3 用户确认界面

**UI设计:**

```
┌─────────────────────────────────────┐
│ ← OCR识别结果              确认保存  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ [照片预览]                  │   │
│  │                             │   │
│  │   [收据照片缩略图]          │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  识别结果：                         │
│  ┌────────────────────────────┐    │
│  │ 金额：¥ 1,280          ✓   │    │  ← 可编辑
│  ├────────────────────────────┤    │
│  │ 日期：2026/2/3         ✓   │    │
│  ├────────────────────────────┤    │
│  │ 商家：吉野家           ✓   │    │
│  ├────────────────────────────┤    │
│  │ 分类：食費（外食）     ▼   │    │  ← 自动推荐
│  │ 账户：💖 灵魂          ▼   │    │
│  └────────────────────────────┘    │
│                                     │
│  置信度：85%                        │  ← 显示识别可信度
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ⚠️ 请确认识别结果是否正确          │
│                                     │
│  [重新扫描]            [确认保存]    │
└─────────────────────────────────────┘
```

**实现代码:**

```dart
// lib/features/ocr/presentation/ocr_confirmation_screen.dart

class OCRConfirmationScreen extends ConsumerStatefulWidget {
  final ReceiptData receiptData;

  const OCRConfirmationScreen({required this.receiptData});

  @override
  ConsumerState<OCRConfirmationScreen> createState() => _OCRConfirmationScreenState();
}

class _OCRConfirmationScreenState extends ConsumerState<OCRConfirmationScreen> {
  late int? _amount;
  late DateTime? _date;
  late String? _merchant;
  late String? _categoryId;
  late LedgerType? _ledgerType;

  @override
  void initState() {
    super.initState();
    _amount = widget.receiptData.amount;
    _date = widget.receiptData.date;
    _merchant = widget.receiptData.merchant;
    _categoryId = widget.receiptData.category?.categoryId;
    _ledgerType = widget.receiptData.category?.ledgerType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR識別結果'),
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: Text('確認保存'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildPhotoPreview(),
          SizedBox(height: 24),
          Text('識別結果:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _buildAmountField(),
          SizedBox(height: 12),
          _buildDateField(),
          SizedBox(height: 12),
          _buildMerchantField(),
          SizedBox(height: 12),
          _buildCategoryField(),
          SizedBox(height: 12),
          _buildLedgerTypeField(),
          SizedBox(height: 24),
          _buildConfidenceBadge(),
          SizedBox(height: 24),
          _buildWarning(),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onRescan,
                  child: Text('再スキャン'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  child: Text('確認保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Uint8List>(
          future: _loadDecryptedPhoto(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return _buildEditableField(
      label: '金額',
      value: _amount != null ? '¥${_formatAmount(_amount!)}' : '',
      icon: _amount != null ? Icons.check_circle : Icons.error,
      iconColor: _amount != null ? Colors.green : Colors.red,
      onTap: () => _editAmount(),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = widget.receiptData.confidence;
    final percentage = (confidence * 100).toInt();

    Color badgeColor;
    if (confidence >= 0.8) {
      badgeColor = Colors.green;
    } else if (confidence >= 0.6) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, size: 16, color: badgeColor),
          SizedBox(width: 8),
          Text(
            '置信度: $percentage%',
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ 請確認識別結果是否正確',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    // 验证必填字段
    if (_amount == null || _amount! <= 0) {
      _showError('請輸入有效的金額');
      return;
    }

    if (_categoryId == null) {
      _showError('請選擇分類');
      return;
    }

    // 创建交易
    final transaction = Transaction(
      id: uuid.v4(),
      bookId: await _bookRepo.getCurrentBookId(),
      deviceId: await _keyManager.getDeviceId(),
      amount: _amount!,
      type: TransactionType.expense,
      categoryId: _categoryId!,
      ledgerType: _ledgerType ?? LedgerType.survival,
      timestamp: _date ?? DateTime.now(),
      note: _merchant,
      photoHash: widget.receiptData.photoHash,
      createdAt: DateTime.now(),
    );

    // 保存
    await ref.read(createTransactionUseCaseProvider).execute(transaction);

    // 返回首页
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onRescan() {
    Navigator.of(context).pop();
  }

  Future<Uint8List> _loadDecryptedPhoto() async {
    final encryptedBytes = await _photoRepo.getPhoto(widget.receiptData.photoHash);
    return await _encryption.decryptBytes(encryptedBytes);
  }
}
```

---

## 3. 数据模型设计

### 3.1 照片存储

```dart
// lib/features/ocr/data/models/receipt_photo.dart

@DataClassName('ReceiptPhotoData')
class ReceiptPhotos extends Table {
  TextColumn get hash => text()();  // SHA-256哈希（作为主键）
  TextColumn get filePath => text()();  // 加密文件路径
  IntColumn get fileSize => integer()();  // 文件大小（字节）
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {hash};
}
```

---

## 4. UI/UX设计

### 4.1 扫描入口

```
┌─────────────────────────────────────┐
│  Home Pocket            ☰          │
├─────────────────────────────────────┤
│                                     │
│  [➕ 新增记录]                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  快速录入：                         │
│  ┌────────────────────────────┐    │
│  │ 📷 扫描收据                 │    │  ← OCR入口
│  │ 自动识别金额、日期、商家     │    │
│  └────────────────────────────┘    │
│                                     │
│  ┌────────────────────────────┐    │
│  │ ✍️ 手动输入                 │    │
│  │ 传统记账方式                │    │
│  └────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

---

## 5. 技术实现方案

### 5.1 第三方库依赖

```yaml
# pubspec.yaml

dependencies:
  # OCR
  google_mlkit_text_recognition: ^0.13.0

  # 图像处理
  image: ^4.1.7
  image_picker: ^1.0.7

  # 加密
  cryptography: ^2.7.0
```

---

## 6. 验收标准

### 6.1 功能完整性

- ✅ 金额识别准确率>90%（清晰收据）
- ✅ 日期识别准确率>85%
- ✅ 商家识别准确率>80%
- ✅ 识别速度<2秒
- ✅ 支持模糊、倾斜、褶皱的收据照片
- ✅ 识别失败时提供友好错误提示
- ✅ 用户可手动修正识别结果

---

## 7. 测试用例

### 7.1 单元测试

```dart
void main() {
  group('ScanReceiptUseCase', () {
    test('should extract amount correctly', () async {
      // Given
      final mockText = '吉野家\n2026/2/3\n合計 ¥1,280';

      // When
      final result = useCase._extractAmount(mockText);

      // Then
      expect(result, 1280);
    });

    test('should extract date correctly', () async {
      // Given
      final mockText = '2026年2月3日\n¥1,280';

      // When
      final result = useCase._extractDate(mockText);

      // Then
      expect(result, DateTime(2026, 2, 3));
    });
  });
}
```

---

## 8. 开发里程碑（7天）

| Day | 任务 | 产出 |
|-----|------|------|
| **Day 1** | ML Kit集成 | OCR识别基础 |
| **Day 2** | 图像预处理 | 去噪、二值化 |
| **Day 3** | 数据提取 | 正则匹配算法 |
| **Day 4** | 商家数据库 | 500+商家 |
| **Day 5** | 照片加密 | 存储与解密 |
| **Day 6** | UI实现 | 确认页面 |
| **Day 7** | 测试优化 | 准确率测试 |

---

**文档状态:** 完成
**审核状态:** 待评审

**变更日志:**
- 2026-02-03: 初版完成
