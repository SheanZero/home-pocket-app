# OCR Phase 2: LLM 自动标注 → 轻量级字段分类模型

**来源:** MOD-004 v4.0 未来演进路线 Phase 2
**优先级:** 🟢 低 (Phase 1 启发式规则完成后)
**预估工作量:** 5-7 天 (不含收据收集周期)
**前置条件:** MOD-004 Phase 1 已上线运行，积累 200+ 张真实收据
**关联文件:**
- `docs/arch/02-module-specs/MOD-004_OCR.md`
- `lib/application/ocr/receipt_parser.dart` (Phase 1 启发式规则)
- `lib/infrastructure/ml/ocr/ocr_service.dart` (OCRLine 含 bounding box)

---

## 目标

用轻量级 ML 模型 (~6MB) 替代 Phase 1 的启发式正则规则，提升收据字段提取准确率：

| 字段 | Phase 1 (规则) | Phase 2 (模型) |
|------|---------------|---------------|
| 金额 | ~90% | >95% |
| 日期 | ~85% | >93% |
| 商家 | ~80% | >90% |

## 核心思路

**不做端到端模型 (Donut ~800MB 太大)，保留现有 OCR 管道，只加一个小分类器：**

```
Phase 1:  图像 → OCR(Vision/MLKit) → [正则/关键词规则]     → 金额/日期/商家
Phase 2:  图像 → OCR(Vision/MLKit) → [TinyReceiptKIE 6MB] → 金额/日期/商家
                                      ↑
                                  Token Classification
                                  每个 OCR 行 → 字段标签
```

---

## 完整实施步骤

### Step 1: 收据数据收集 (持续进行，无开发工作)

**目标:** 积累 200-500 张多样化日文收据图像。

**数据来源:**

| 来源 | 方式 | 预计数量 |
|------|------|---------|
| 用户日常使用 | Phase 1 扫描时自动保存原图 (需用户授权) | 100-300 |
| 开发者手动拍摄 | 多种店铺类型、光照条件 | 50-100 |
| 家人朋友收集 | 不同地区、不同收据格式 | 50-100 |

**多样化要求:**

```
店铺类型 (至少覆盖):
├── 便利店: セブン、ファミマ、ローソン
├── 超市: イオン、西友、ライフ
├── 餐厅: 各种レシート形式
├── 药局: マツモトキヨシ、ウエルシア
├── 交通: JR、メトロ
└── 其他: 百均、書店、家電量販店

収据状态:
├── 清晰: 新打印、平整
├── 褪色: 热敏纸老化
├── 折叠: 有折痕
├── 倾斜: 拍摄角度不正
└── 部分遮挡: 手指、阴影
```

**存储方式:**

```
data/receipts/raw/
├── 001_seven_clear.jpg
├── 002_aeon_faded.jpg
├── 003_restaurant_tilted.jpg
└── ...
```

**重要:** 此目录必须 `.gitignore`，不提交到仓库（隐私数据）。

---

### Step 2: OCR 批量扫描 (0.5 天)

**目标:** 用 Phase 1 的 OCR 管道扫描所有收据，获取 text + bounding boxes。

**工具脚本:**

```dart
// tools/batch_ocr_scan.dart (CLI 工具，非 app 代码)

import 'dart:io';
import 'dart:convert';

/// 批量扫描收据图像，输出 OCR 结果 JSON
///
/// 使用方式:
///   dart run tools/batch_ocr_scan.dart \
///     --input data/receipts/raw/ \
///     --output data/receipts/ocr_results/
Future<void> main(List<String> args) async {
  final inputDir = Directory(args.getFlag('input'));
  final outputDir = Directory(args.getFlag('output'));
  await outputDir.create(recursive: true);

  final imageFiles = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'));

  for (final imageFile in imageFiles) {
    // 1. 预处理 (ImagePreprocessor)
    final preprocessed = await imagePreprocessor.process(
      await imageFile.readAsBytes(),
    );

    // 2. OCR (PlatformOcrService via MethodChannel)
    final ocrResult = await ocrService.recognizeText(preprocessed!);

    // 3. 保存结果
    final outputPath = '${outputDir.path}/${imageFile.nameWithoutExtension}.json';
    File(outputPath).writeAsStringSync(jsonEncode({
      'source_image': imageFile.path,
      'full_text': ocrResult.text,
      'lines': ocrResult.lines.map((line) => {
        'text': line.text,
        'x': line.x,
        'y': line.y,
        'width': line.width,
        'height': line.height,
        'confidence': line.confidence,
      }).toList(),
    }));

    print('✅ ${imageFile.path} → $outputPath');
  }
}
```

**输出格式:**

```json
// data/receipts/ocr_results/001_seven_clear.json
{
  "source_image": "data/receipts/raw/001_seven_clear.jpg",
  "full_text": "セブンイレブン新宿店\n2026/02/25 14:30\n...",
  "lines": [
    {
      "text": "セブンイレブン新宿店",
      "x": 0.15, "y": 0.02, "width": 0.70, "height": 0.04,
      "confidence": 0.98
    },
    {
      "text": "2026/02/25 14:30",
      "x": 0.20, "y": 0.06, "width": 0.60, "height": 0.03,
      "confidence": 0.95
    }
  ]
}
```

---

### Step 3: LLM 自动标注 (1 天)

**目标:** 用 Claude API 自动标注每行的字段类型，替代人工标注。

#### 3.1 字段标签定义

```python
# scripts/label_definitions.py

FIELD_LABELS = {
    "STORE":       "店舗名・店舗住所・電話番号",
    "DATE":        "日付・時刻",
    "RECEIPT_NO":  "レシート番号・レジ番号・取引番号",
    "ITEM_NAME":   "商品名・品名",
    "ITEM_PRICE":  "商品金額（単品）",
    "ITEM_QTY":    "商品数量",
    "SUBTOTAL":    "小計",
    "TAX":         "消費税・内税・外税",
    "TOTAL":       "合計・総額・税込合計",
    "PAYMENT":     "支払方法・現金・カード・電子マネー",
    "CHANGE":      "お預り・お釣り",
    "DISCOUNT":    "割引・クーポン・ポイント",
    "BARCODE":     "バーコード番号・JANコード",
    "OTHER":       "上記に該当しないテキスト",
}

# BIO タグ一覧 (モデル出力)
BIO_LABELS = ["O"]  # OTHER は O タグ
for field in FIELD_LABELS:
    if field != "OTHER":
        BIO_LABELS.append(f"B-{field}")
        BIO_LABELS.append(f"I-{field}")

# 計 27 ラベル:
# O, B-STORE, I-STORE, B-DATE, I-DATE, B-RECEIPT_NO, I-RECEIPT_NO,
# B-ITEM_NAME, I-ITEM_NAME, B-ITEM_PRICE, I-ITEM_PRICE, ...
```

#### 3.2 LLM 標注スクリプト

```python
# scripts/label_with_llm.py

import anthropic
import json
import os
from pathlib import Path

client = anthropic.Anthropic()

LABELING_PROMPT = """あなたは日本語レシートの情報抽出専門家です。

以下はOCRで認識されたレシートの各行です。
各行に対して、最も適切なフィールドラベルを1つ付けてください。

## ラベル一覧

| ラベル | 説明 | 例 |
|--------|------|-----|
| STORE | 店舗名・住所・電話 | セブンイレブン新宿店、TEL:03-xxxx |
| DATE | 日付・時刻 | 2026/02/25、14:30 |
| RECEIPT_NO | レシート番号 | No.0123、レジ#02 |
| ITEM_NAME | 商品名 | おにぎり鮭、コカ・コーラ |
| ITEM_PRICE | 商品金額(単品) | ¥150、*120 |
| ITEM_QTY | 数量 | x2、3点 |
| SUBTOTAL | 小計 | 小計 ¥270 |
| TAX | 税金 | 消費税(8%)、内税 ¥21 |
| TOTAL | 合計・総額 | 合計 ¥291、税込合計 |
| PAYMENT | 支払方法 | 現金、VISA、PayPay |
| CHANGE | お預り・お釣り | お預り ¥500、お釣り ¥209 |
| DISCOUNT | 割引・ポイント | 10%OFF、-¥50 |
| BARCODE | バーコード | 4901234567890 |
| OTHER | 上記以外 | ありがとうございました |

## 判定ルール

1. 金額が含まれる行は、文脈から ITEM_PRICE / SUBTOTAL / TAX / TOTAL / CHANGE / DISCOUNT を判別
2. 「合計」「税込」キーワードを含む行 → TOTAL (金額部分も TOTAL)
3. 「小計」キーワードを含む行 → SUBTOTAL
4. 「消費税」「内税」「外税」→ TAX
5. 「お釣り」「お預り」→ CHANGE
6. 商品行に金額が含まれる場合 (例: "おにぎり ¥150")、金額部分のみの行は ITEM_PRICE
7. 行全体で1つのラベルを付ける（行内を分割しない）

## OCR認識結果

{ocr_lines}

## 出力形式

JSON配列で回答してください。余計な説明は不要です:
[
  {{"line_index": 0, "text": "...", "label": "STORE"}},
  {{"line_index": 1, "text": "...", "label": "DATE"}},
  ...
]"""


def label_single_receipt(ocr_json_path: str) -> list[dict]:
    """1枚のレシートOCR結果をClaude APIで自動ラベリング"""

    with open(ocr_json_path) as f:
        ocr_data = json.load(f)

    # OCR行をフォーマット
    formatted_lines = []
    for i, line in enumerate(ocr_data["lines"]):
        formatted_lines.append(
            f"  行{i}: \"{line['text']}\"  "
            f"[x={line['x']:.3f}, y={line['y']:.3f}, "
            f"w={line['width']:.3f}, h={line['height']:.3f}]"
        )

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",  # 低コスト・高速
        max_tokens=2048,
        messages=[{
            "role": "user",
            "content": LABELING_PROMPT.format(
                ocr_lines="\n".join(formatted_lines)
            ),
        }],
    )

    labels = json.loads(response.content[0].text)
    return labels


def batch_label(ocr_dir: str, output_dir: str):
    """全レシートを一括ラベリング"""
    os.makedirs(output_dir, exist_ok=True)

    ocr_files = sorted(Path(ocr_dir).glob("*.json"))
    print(f"Found {len(ocr_files)} OCR results to label")

    for i, ocr_file in enumerate(ocr_files):
        output_path = Path(output_dir) / ocr_file.name
        if output_path.exists():
            print(f"  [{i+1}/{len(ocr_files)}] SKIP (already labeled): {ocr_file.name}")
            continue

        try:
            labels = label_single_receipt(str(ocr_file))

            # OCR データとラベルを結合して保存
            with open(ocr_file) as f:
                ocr_data = json.load(f)

            labeled_data = {
                "source_image": ocr_data["source_image"],
                "lines": []
            }
            for line, label_info in zip(ocr_data["lines"], labels):
                labeled_data["lines"].append({
                    **line,
                    "label": label_info["label"],
                })

            with open(output_path, "w") as f:
                json.dump(labeled_data, f, ensure_ascii=False, indent=2)

            print(f"  [{i+1}/{len(ocr_files)}] ✅ {ocr_file.name}")

        except Exception as e:
            print(f"  [{i+1}/{len(ocr_files)}] ❌ {ocr_file.name}: {e}")


if __name__ == "__main__":
    batch_label(
        ocr_dir="data/receipts/ocr_results/",
        output_dir="data/receipts/labeled/",
    )
```

**実行:**

```bash
# 前提: ANTHROPIC_API_KEY 環境変数を設定済み
python scripts/label_with_llm.py
```

**コスト見積もり:**

| 規模 | Haiku コスト | 所要時間 |
|------|-------------|---------|
| 200 枚 | ~$1 | ~10 分 |
| 500 枚 | ~$3 | ~25 分 |
| 1000 枚 | ~$5 | ~50 分 |

#### 3.3 ラベル品質検証

```python
# scripts/verify_labels.py

import json
from pathlib import Path
from collections import Counter

def verify_labels(labeled_dir: str):
    """ラベリング結果の品質チェック"""

    label_counts = Counter()
    issues = []

    for f in sorted(Path(labeled_dir).glob("*.json")):
        with open(f) as fp:
            data = json.load(fp)

        labels_in_receipt = [line["label"] for line in data["lines"]]
        for label in labels_in_receipt:
            label_counts[label] += 1

        # 検証ルール
        if "TOTAL" not in labels_in_receipt:
            issues.append(f"⚠️  {f.name}: TOTAL ラベルなし")

        if labels_in_receipt.count("TOTAL") > 3:
            issues.append(f"⚠️  {f.name}: TOTAL が {labels_in_receipt.count('TOTAL')} 行 (多すぎ)")

        if "DATE" not in labels_in_receipt:
            issues.append(f"⚠️  {f.name}: DATE ラベルなし")

    # 統計出力
    print("=== ラベル分布 ===")
    for label, count in label_counts.most_common():
        print(f"  {label:15s}: {count:5d}")

    print(f"\n=== 問題検出: {len(issues)} 件 ===")
    for issue in issues:
        print(f"  {issue}")

    # 期待される分布チェック
    total_receipts = len(list(Path(labeled_dir).glob("*.json")))
    if label_counts["TOTAL"] < total_receipts * 0.8:
        print(f"\n❌ TOTAL ラベルの検出率が低い: "
              f"{label_counts['TOTAL']}/{total_receipts} "
              f"({label_counts['TOTAL']/total_receipts*100:.0f}%)")

if __name__ == "__main__":
    verify_labels("data/receipts/labeled/")
```

#### 3.4 手動修正 (必要に応じて)

品質検証で問題が見つかった場合、手動で JSON を修正：

```bash
# 問題のあるファイルを修正
# data/receipts/labeled/003_restaurant_tilted.json
# "label": "ITEM_PRICE" → "label": "TOTAL" (LLM の誤判定を修正)
```

**目標品質: 95%+ のラベルが正確であること。**

---

### Step 4: 訓練データ変換 (0.5 天)

**目標:** LLM ラベル付き JSON を、モデル学習用のトークン分類データセットに変換。

#### 4.1 Tokenizer 準備

```python
# scripts/prepare_tokenizer.py

from sentencepiece import SentencePieceTrainer, SentencePieceProcessor

def train_tokenizer(labeled_dir: str, vocab_size: int = 8000):
    """
    日本語レシート専用 SentencePiece tokenizer を学習。

    汎用日本語 tokenizer ではなく、レシート特有の語彙
    (商品名、金額表記、店舗名) に最適化する。
    """
    # 全レシートのテキストを収集
    texts = []
    for f in Path(labeled_dir).glob("*.json"):
        with open(f) as fp:
            data = json.load(fp)
        for line in data["lines"]:
            texts.append(line["text"])

    # テキストファイルに書き出し
    corpus_path = "data/receipts/corpus.txt"
    with open(corpus_path, "w") as f:
        f.write("\n".join(texts))

    # SentencePiece 学習
    SentencePieceTrainer.train(
        input=corpus_path,
        model_prefix="data/models/receipt_sp",
        vocab_size=vocab_size,
        model_type="unigram",
        character_coverage=0.9995,   # 日本語用（漢字・カナ網羅）
        pad_id=0,
        unk_id=1,
        bos_id=2,
        eos_id=3,
    )
    print(f"✅ Tokenizer saved: data/models/receipt_sp.model ({vocab_size} vocab)")
```

#### 4.2 データセット変換

```python
# scripts/convert_to_training_data.py

import json
import torch
from pathlib import Path
from sentencepiece import SentencePieceProcessor
from label_definitions import BIO_LABELS

LABEL2ID = {label: i for i, label in enumerate(BIO_LABELS)}
MAX_SEQ_LEN = 128  # レシートは通常 50-80 トークン

sp = SentencePieceProcessor(model_file="data/models/receipt_sp.model")


def convert_receipt_to_training_sample(labeled_json_path: str) -> dict | None:
    """
    1枚のラベル付きレシート → トークン分類学習データ

    行レベルラベル → トークンレベル BIO タグ に展開:
      行 "セブンイレブン新宿店" (STORE)
      → tokens: ["▁セブン", "イレブン", "新宿", "店"]
      → labels: [B-STORE,   I-STORE,   I-STORE, I-STORE]
    """
    with open(labeled_json_path) as f:
        data = json.load(f)

    all_token_ids = []
    all_bboxes = []
    all_label_ids = []

    for line in data["lines"]:
        text = line["text"]
        label = line["label"]
        bbox = [
            int(line["x"] * 1000),
            int(line["y"] * 1000),
            int(line["width"] * 1000),
            int(line["height"] * 1000),
        ]

        # Tokenize
        token_ids = sp.encode(text, out_type=int)
        if not token_ids:
            continue

        for i, tid in enumerate(token_ids):
            all_token_ids.append(tid)
            all_bboxes.append(bbox)  # 同一行の全トークンは同じ bbox

            # BIO タグ変換
            if label == "OTHER":
                all_label_ids.append(LABEL2ID["O"])
            elif i == 0:
                all_label_ids.append(LABEL2ID[f"B-{label}"])
            else:
                all_label_ids.append(LABEL2ID[f"I-{label}"])

    # 長さ制限
    if len(all_token_ids) > MAX_SEQ_LEN:
        all_token_ids = all_token_ids[:MAX_SEQ_LEN]
        all_bboxes = all_bboxes[:MAX_SEQ_LEN]
        all_label_ids = all_label_ids[:MAX_SEQ_LEN]

    # パディング
    pad_len = MAX_SEQ_LEN - len(all_token_ids)
    all_token_ids += [0] * pad_len       # PAD token
    all_bboxes += [[0, 0, 0, 0]] * pad_len
    all_label_ids += [-100] * pad_len    # -100 = PyTorch CE loss で無視

    return {
        "input_ids": all_token_ids,
        "bbox": all_bboxes,
        "labels": all_label_ids,
        "attention_mask": [1] * (MAX_SEQ_LEN - pad_len) + [0] * pad_len,
    }


def convert_all(labeled_dir: str, output_path: str, test_ratio: float = 0.1):
    """全データを変換し、train/test 分割して保存"""
    samples = []
    for f in sorted(Path(labeled_dir).glob("*.json")):
        sample = convert_receipt_to_training_sample(str(f))
        if sample:
            samples.append(sample)

    # シャッフル + 分割
    import random
    random.seed(42)
    random.shuffle(samples)

    split = int(len(samples) * (1 - test_ratio))
    train_samples = samples[:split]
    test_samples = samples[split:]

    # 保存
    torch.save({
        "train": train_samples,
        "test": test_samples,
        "label_names": BIO_LABELS,
    }, output_path)

    print(f"✅ Dataset saved: {output_path}")
    print(f"   Train: {len(train_samples)} samples")
    print(f"   Test:  {len(test_samples)} samples")
    print(f"   Labels: {len(BIO_LABELS)} classes")


if __name__ == "__main__":
    convert_all(
        labeled_dir="data/receipts/labeled/",
        output_path="data/models/receipt_dataset.pt",
    )
```

---

### Step 5: モデル定義 & 学習 (1-2 天)

#### 5.1 TinyReceiptKIE モデル

```python
# scripts/model.py

import torch
import torch.nn as nn
import math


class PositionalEncoding2D(nn.Module):
    """レシート上の 2D 位置を encoding する"""

    def __init__(self, hidden_size: int, max_position: int = 1024):
        super().__init__()
        quarter = hidden_size // 4
        self.x_emb = nn.Embedding(max_position, quarter)
        self.y_emb = nn.Embedding(max_position, quarter)
        self.w_emb = nn.Embedding(max_position, quarter)
        self.h_emb = nn.Embedding(max_position, quarter)

    def forward(self, bbox: torch.LongTensor) -> torch.Tensor:
        """bbox: (batch, seq, 4) → (batch, seq, hidden_size)"""
        return torch.cat([
            self.x_emb(bbox[:, :, 0]),
            self.y_emb(bbox[:, :, 1]),
            self.w_emb(bbox[:, :, 2]),
            self.h_emb(bbox[:, :, 3]),
        ], dim=-1)


class TinyReceiptKIE(nn.Module):
    """
    軽量レシートフィールド分類モデル

    アーキテクチャ:
      Token Embedding (8000 vocab)
          +
      2D Position Embedding (x, y, w, h)
          ↓ concat + projection
      3-layer Transformer Encoder (hidden=256, heads=4)
          ↓
      Linear Classifier → BIO labels

    パラメータ数: ~5.5M → FP32: ~22MB → INT8: ~6MB
    """

    def __init__(
        self,
        vocab_size: int = 8000,
        hidden_size: int = 256,
        num_layers: int = 3,
        num_heads: int = 4,
        num_labels: int = 27,       # BIO タグ数
        max_seq_len: int = 128,
        dropout: float = 0.1,
    ):
        super().__init__()
        self.hidden_size = hidden_size

        # Embeddings
        self.word_embeddings = nn.Embedding(vocab_size, hidden_size, padding_idx=0)
        self.position_2d = PositionalEncoding2D(hidden_size)
        self.seq_position = nn.Embedding(max_seq_len, hidden_size)

        # 融合 (word + 2d_pos → hidden)
        self.projection = nn.Linear(hidden_size * 2, hidden_size)
        self.layer_norm = nn.LayerNorm(hidden_size)
        self.dropout = nn.Dropout(dropout)

        # Transformer Encoder
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=hidden_size,
            nhead=num_heads,
            dim_feedforward=hidden_size * 4,
            dropout=dropout,
            activation="gelu",
            batch_first=True,
        )
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)

        # 分類ヘッド
        self.classifier = nn.Sequential(
            nn.Linear(hidden_size, hidden_size),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(hidden_size, num_labels),
        )

    def forward(
        self,
        input_ids: torch.LongTensor,      # (batch, seq)
        bbox: torch.LongTensor,            # (batch, seq, 4)
        attention_mask: torch.LongTensor,   # (batch, seq)
    ) -> torch.Tensor:
        batch_size, seq_len = input_ids.shape

        # Embeddings
        word_emb = self.word_embeddings(input_ids)
        pos_2d_emb = self.position_2d(bbox)
        seq_pos = torch.arange(seq_len, device=input_ids.device).unsqueeze(0)
        seq_emb = self.seq_position(seq_pos)

        # 融合: word + 2d_position
        fused = self.projection(torch.cat([word_emb, pos_2d_emb], dim=-1))
        fused = self.layer_norm(fused + seq_emb)
        fused = self.dropout(fused)

        # Attention mask → padding mask
        src_key_padding_mask = (attention_mask == 0)

        # Transformer
        encoded = self.encoder(fused, src_key_padding_mask=src_key_padding_mask)

        # 分類
        logits = self.classifier(encoded)  # (batch, seq, num_labels)
        return logits
```

#### 5.2 学習スクリプト

```python
# scripts/train.py

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from model import TinyReceiptKIE

def train():
    # データ読み込み
    data = torch.load("data/models/receipt_dataset.pt")
    train_data = data["train"]
    test_data = data["test"]
    num_labels = len(data["label_names"])

    # DataLoader
    train_loader = _make_loader(train_data, batch_size=16, shuffle=True)
    test_loader = _make_loader(test_data, batch_size=32, shuffle=False)

    # モデル
    model = TinyReceiptKIE(num_labels=num_labels)
    print(f"Parameters: {sum(p.numel() for p in model.parameters()):,}")

    # オプティマイザ
    optimizer = torch.optim.AdamW(model.parameters(), lr=3e-4, weight_decay=0.01)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=30)
    criterion = nn.CrossEntropyLoss(ignore_index=-100)

    # GPU
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)

    # 学習ループ
    best_f1 = 0.0
    for epoch in range(30):
        # Train
        model.train()
        total_loss = 0
        for batch in train_loader:
            input_ids, bbox, labels, mask = [b.to(device) for b in batch]
            logits = model(input_ids, bbox, mask)
            loss = criterion(logits.view(-1, num_labels), labels.view(-1))
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            optimizer.zero_grad()
            total_loss += loss.item()

        scheduler.step()

        # Eval
        f1 = evaluate(model, test_loader, data["label_names"], device)
        print(f"Epoch {epoch+1:2d} | Loss: {total_loss/len(train_loader):.4f} | F1: {f1:.4f}")

        if f1 > best_f1:
            best_f1 = f1
            torch.save(model.state_dict(), "data/models/best_receipt_kie.pt")
            print(f"  → Best model saved (F1={f1:.4f})")

    print(f"\n✅ Training complete. Best F1: {best_f1:.4f}")


def evaluate(model, loader, label_names, device) -> float:
    """Micro-F1 スコアを計算"""
    from seqeval.metrics import f1_score as seq_f1

    model.eval()
    all_preds = []
    all_labels = []

    with torch.no_grad():
        for batch in loader:
            input_ids, bbox, labels, mask = [b.to(device) for b in batch]
            logits = model(input_ids, bbox, mask)
            preds = logits.argmax(dim=-1)

            for pred_seq, label_seq in zip(preds, labels):
                pred_tags = []
                true_tags = []
                for p, l in zip(pred_seq, label_seq):
                    if l.item() == -100:
                        continue
                    pred_tags.append(label_names[p.item()])
                    true_tags.append(label_names[l.item()])
                all_preds.append(pred_tags)
                all_labels.append(true_tags)

    return seq_f1(all_labels, all_preds, average="micro")


if __name__ == "__main__":
    train()
```

**実行:**

```bash
# Google Colab (無料 T4 GPU) または ローカル GPU
pip install torch sentencepiece seqeval

python scripts/train.py
# Expected output:
# Parameters: 5,504,027
# Epoch  1 | Loss: 2.3456 | F1: 0.4523
# ...
# Epoch 30 | Loss: 0.1234 | F1: 0.9012
# ✅ Training complete. Best F1: 0.9156
```

**学習スペック:**

| 項目 | 値 |
|------|-----|
| データ数 | 200-500 サンプル |
| バッチサイズ | 16 |
| エポック数 | 30 |
| 学習率 | 3e-4 (CosineAnnealing) |
| 学習時間 (T4 GPU) | ~30 分 |
| 学習時間 (CPU) | ~3 時間 |
| 目標 F1 | >0.85 (200 サンプル) / >0.90 (500 サンプル) |

---

### Step 6: モデル導出 (0.5 天)

#### 6.1 ONNX エクスポート

```python
# scripts/export_onnx.py

import torch
from model import TinyReceiptKIE

model = TinyReceiptKIE(num_labels=27)
model.load_state_dict(torch.load("data/models/best_receipt_kie.pt"))
model.eval()

# ダミー入力
dummy_ids = torch.randint(0, 8000, (1, 128))
dummy_bbox = torch.randint(0, 1000, (1, 128, 4))
dummy_mask = torch.ones(1, 128, dtype=torch.long)

torch.onnx.export(
    model,
    (dummy_ids, dummy_bbox, dummy_mask),
    "data/models/receipt_kie.onnx",
    input_names=["input_ids", "bbox", "attention_mask"],
    output_names=["logits"],
    dynamic_axes={
        "input_ids": {0: "batch", 1: "seq"},
        "bbox": {0: "batch", 1: "seq"},
        "attention_mask": {0: "batch", 1: "seq"},
        "logits": {0: "batch", 1: "seq"},
    },
    opset_version=13,
)
print("✅ ONNX exported: data/models/receipt_kie.onnx")
```

#### 6.2 INT8 量子化

```python
# scripts/quantize_onnx.py

from onnxruntime.quantization import quantize_dynamic, QuantType

quantize_dynamic(
    model_input="data/models/receipt_kie.onnx",
    model_output="data/models/receipt_kie_int8.onnx",
    weight_type=QuantType.QInt8,
)

import os
original = os.path.getsize("data/models/receipt_kie.onnx")
quantized = os.path.getsize("data/models/receipt_kie_int8.onnx")
print(f"✅ Quantized: {original/1e6:.1f}MB → {quantized/1e6:.1f}MB "
      f"({quantized/original*100:.0f}%)")
# Expected: ~22MB → ~6MB (27%)
```

#### 6.3 精度検証 (量子化後)

```python
# scripts/verify_quantized.py

import onnxruntime as ort
import numpy as np

# 元モデル vs 量子化モデルの出力差分を検証
session_fp32 = ort.InferenceSession("data/models/receipt_kie.onnx")
session_int8 = ort.InferenceSession("data/models/receipt_kie_int8.onnx")

# テストデータで推論
for sample in test_samples[:20]:
    inputs = {
        "input_ids": np.array([sample["input_ids"]], dtype=np.int64),
        "bbox": np.array([sample["bbox"]], dtype=np.int64),
        "attention_mask": np.array([sample["attention_mask"]], dtype=np.int64),
    }
    out_fp32 = session_fp32.run(None, inputs)[0]
    out_int8 = session_int8.run(None, inputs)[0]

    # argmax が一致するか
    match = (out_fp32.argmax(-1) == out_int8.argmax(-1)).mean()
    print(f"  Label match: {match*100:.1f}%")

# Expected: >98% の一致率
```

---

### Step 7: Flutter 統合 (1-2 天)

#### 7.1 依存パッケージ

```yaml
# pubspec.yaml に追加
dependencies:
  onnxruntime_flutter: ^1.0.0   # ONNX Runtime for Flutter
```

#### 7.2 モデルアセット配置

```
assets/
└── models/
    ├── receipt_kie_int8.onnx    # ~6MB INT8 量子化モデル
    └── receipt_sp.model         # ~500KB SentencePiece tokenizer

# pubspec.yaml
flutter:
  assets:
    - assets/models/
```

#### 7.3 推論サービス実装

```dart
// lib/infrastructure/ml/receipt_kie_model.dart

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../ocr/ocr_service.dart';

/// BIO ラベル定義
const _bioLabels = [
  'O',
  'B-STORE', 'I-STORE',
  'B-DATE', 'I-DATE',
  'B-RECEIPT_NO', 'I-RECEIPT_NO',
  'B-ITEM_NAME', 'I-ITEM_NAME',
  'B-ITEM_PRICE', 'I-ITEM_PRICE',
  'B-ITEM_QTY', 'I-ITEM_QTY',
  'B-SUBTOTAL', 'I-SUBTOTAL',
  'B-TAX', 'I-TAX',
  'B-TOTAL', 'I-TOTAL',
  'B-PAYMENT', 'I-PAYMENT',
  'B-CHANGE', 'I-CHANGE',
  'B-DISCOUNT', 'I-DISCOUNT',
  'B-BARCODE', 'I-BARCODE',
];

/// レシートフィールド分類結果
class ReceiptFieldResult {
  final String? storeName;
  final String? date;
  final String? total;
  final String? subtotal;
  final String? tax;
  final List<Map<String, String>> items; // [{name, price}]
  final double confidence;

  const ReceiptFieldResult({
    this.storeName,
    this.date,
    this.total,
    this.subtotal,
    this.tax,
    this.items = const [],
    this.confidence = 0.0,
  });
}

/// TinyReceiptKIE モデルの Flutter ラッパー
class ReceiptKIEModel {
  OrtSession? _session;
  bool _isLoaded = false;

  /// モデル読み込み (アプリ起動時に1回)
  Future<void> load() async {
    if (_isLoaded) return;

    OrtEnv.instance.init();
    final modelBytes = await rootBundle.load('assets/models/receipt_kie_int8.onnx');
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(
      modelBytes.buffer.asUint8List(),
      sessionOptions,
    );
    _isLoaded = true;
  }

  /// OCR 結果 → フィールド分類
  Future<ReceiptFieldResult> classify(List<OCRLine> lines) async {
    if (!_isLoaded || _session == null) {
      throw StateError('Model not loaded. Call load() first.');
    }

    // 1. Tokenize + bbox 構築
    final inputIds = <int>[];
    final bboxes = <List<int>>[];
    final lineIndices = <int>[]; // token → 元の行の対応

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final tokens = _tokenize(line.text);
      final bbox = [
        (line.x * 1000).round(),
        (line.y * 1000).round(),
        (line.width * 1000).round(),
        (line.height * 1000).round(),
      ];
      for (final tokenId in tokens) {
        inputIds.add(tokenId);
        bboxes.add(bbox);
        lineIndices.add(i);
      }
    }

    // 2. パディング (max 128)
    const maxLen = 128;
    final seqLen = inputIds.length.clamp(0, maxLen);
    final paddedIds = List<int>.filled(maxLen, 0);
    final paddedBbox = List<List<int>>.generate(maxLen, (_) => [0, 0, 0, 0]);
    final mask = List<int>.filled(maxLen, 0);

    for (var i = 0; i < seqLen; i++) {
      paddedIds[i] = inputIds[i];
      paddedBbox[i] = bboxes[i];
      mask[i] = 1;
    }

    // 3. ONNX 推論
    final inputIdsTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(paddedIds.map((e) => e.toInt()).toList()),
      [1, maxLen],
    );
    final bboxTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(paddedBbox.expand((b) => b).map((e) => e.toInt()).toList()),
      [1, maxLen, 4],
    );
    final maskTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(mask.map((e) => e.toInt()).toList()),
      [1, maxLen],
    );

    final outputs = await _session!.runAsync(
      OrtRunOptions(),
      {
        'input_ids': inputIdsTensor,
        'bbox': bboxTensor,
        'attention_mask': maskTensor,
      },
    );

    // 4. ラベルデコード
    final logitsData = outputs[0]!.value as List; // shape: [1, 128, 27]
    final labels = _decodeLogits(logitsData, seqLen);

    // 5. フィールド集約
    return _aggregateFields(labels, lines, lineIndices, seqLen);
  }

  List<String> _decodeLogits(List logitsData, int seqLen) {
    final labels = <String>[];
    for (var i = 0; i < seqLen; i++) {
      final logits = logitsData[0][i] as List<double>;
      var maxIdx = 0;
      var maxVal = logits[0];
      for (var j = 1; j < logits.length; j++) {
        if (logits[j] > maxVal) {
          maxVal = logits[j];
          maxIdx = j;
        }
      }
      labels.add(_bioLabels[maxIdx]);
    }
    return labels;
  }

  ReceiptFieldResult _aggregateFields(
    List<String> tokenLabels,
    List<OCRLine> lines,
    List<int> lineIndices,
    int seqLen,
  ) {
    // BIO タグを行単位で集約 (多数決)
    final lineLabels = <int, Map<String, int>>{};
    for (var i = 0; i < seqLen; i++) {
      final lineIdx = lineIndices[i];
      final label = tokenLabels[i].replaceFirst(RegExp(r'^[BI]-'), '');
      lineLabels.putIfAbsent(lineIdx, () => {});
      lineLabels[lineIdx]![label] =
          (lineLabels[lineIdx]![label] ?? 0) + 1;
    }

    // 各行の最頻ラベル
    String? store, date, total, subtotal, tax;
    final items = <Map<String, String>>[];

    for (final entry in lineLabels.entries) {
      final lineIdx = entry.key;
      if (lineIdx >= lines.length) continue;
      final votes = entry.value;
      final bestLabel = votes.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      final text = lines[lineIdx].text;

      switch (bestLabel) {
        case 'STORE':
          store ??= text;
        case 'DATE':
          date ??= text;
        case 'TOTAL':
          total ??= text;
        case 'SUBTOTAL':
          subtotal ??= text;
        case 'TAX':
          tax ??= text;
        case 'ITEM_NAME':
          items.add({'name': text, 'price': ''});
        case 'ITEM_PRICE':
          if (items.isNotEmpty && items.last['price']!.isEmpty) {
            items.last['price'] = text;
          }
      }
    }

    return ReceiptFieldResult(
      storeName: store,
      date: date,
      total: total,
      subtotal: subtotal,
      tax: tax,
      items: items,
    );
  }

  List<int> _tokenize(String text) {
    // SentencePiece tokenize (簡易版: バイトペア)
    // 本番では sentencepiece_dart パッケージまたは
    // MethodChannel 経由で native SentencePiece を呼ぶ
    return text.codeUnits.take(20).toList(); // placeholder
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isLoaded = false;
  }
}
```

#### 7.4 Phase 1 → Phase 2 切り替え

```dart
// lib/application/ocr/receipt_parser.dart

class ReceiptParser {
  final ReceiptKIEModel? _kieModel;  // null = Phase 1 (規則ベース)

  ReceiptParser({ReceiptKIEModel? kieModel}) : _kieModel = kieModel;

  Future<ParsedReceiptData> parse(OCRResult ocrResult) async {
    // Phase 2: モデルが利用可能ならモデル推論
    if (_kieModel != null) {
      return _parseWithModel(ocrResult);
    }

    // Phase 1: 啓発式規則 (既存コード)
    return _parseWithRules(ocrResult);
  }

  Future<ParsedReceiptData> _parseWithModel(OCRResult ocrResult) async {
    final result = await _kieModel!.classify(ocrResult.lines);
    return ParsedReceiptData(
      amount: _extractNumber(result.total),
      date: _parseDate(result.date),
      merchant: result.storeName,
      items: result.items.map((i) => ReceiptLineItem(
        name: i['name']!,
        unitPrice: _extractNumber(i['price']) ?? 0,
        quantity: 1,
        subtotal: _extractNumber(i['price']) ?? 0,
      )).toList(),
    );
  }
}
```

---

### Step 8: テスト & 精度比較 (0.5 天)

```dart
// test/unit/infrastructure/ml/receipt_kie_model_test.dart

group('ReceiptKIEModel', () {
  test('classifies convenience store receipt fields', () async {
    final model = ReceiptKIEModel();
    await model.load();

    final lines = [
      OCRLine(text: 'セブンイレブン', x: 0.15, y: 0.02, width: 0.7, height: 0.04),
      OCRLine(text: '2026/02/25', x: 0.2, y: 0.06, width: 0.6, height: 0.03),
      OCRLine(text: '合計 ¥291', x: 0.1, y: 0.4, width: 0.8, height: 0.04),
    ];

    final result = await model.classify(lines);
    expect(result.storeName, contains('セブン'));
    expect(result.total, contains('291'));
    expect(result.date, contains('2026'));
  });
});
```

**Phase 1 vs Phase 2 精度比較:**

```dart
// tools/compare_accuracy.dart

/// 同じテストセットで Phase 1 (規則) と Phase 2 (モデル) を比較
Future<void> compareAccuracy() async {
  final testReceipts = loadTestReceipts(); // 手動ラベル付きテストデータ

  var ruleCorrect = 0, modelCorrect = 0;
  for (final receipt in testReceipts) {
    final ruleResult = ruleParser.parse(receipt.ocrResult);
    final modelResult = await modelParser.parse(receipt.ocrResult);

    if (ruleResult.amount == receipt.groundTruth.amount) ruleCorrect++;
    if (modelResult.amount == receipt.groundTruth.amount) modelCorrect++;
  }

  print('Phase 1 (規則): ${ruleCorrect}/${testReceipts.length} '
        '(${(ruleCorrect/testReceipts.length*100).toStringAsFixed(1)}%)');
  print('Phase 2 (モデル): ${modelCorrect}/${testReceipts.length} '
        '(${(modelCorrect/testReceipts.length*100).toStringAsFixed(1)}%)');
}
```

---

## ディレクトリ構成 (最終)

```
# Python スクリプト (学習パイプライン、gitignore 対象外)
scripts/
├── label_definitions.py        # ラベル定義
├── label_with_llm.py           # Step 3: LLM 自動ラベリング
├── verify_labels.py            # Step 3: 品質検証
├── prepare_tokenizer.py        # Step 4: Tokenizer 学習
├── convert_to_training_data.py # Step 4: データ変換
├── model.py                    # Step 5: TinyReceiptKIE 定義
├── train.py                    # Step 5: 学習スクリプト
├── export_onnx.py              # Step 6: ONNX エクスポート
├── quantize_onnx.py            # Step 6: INT8 量子化
└── verify_quantized.py         # Step 6: 量子化後精度検証

# データ (全て .gitignore)
data/
├── receipts/
│   ├── raw/                    # Step 1: 生レシート画像
│   ├── ocr_results/            # Step 2: OCR 結果 JSON
│   └── labeled/                # Step 3: ラベル付き JSON
└── models/
    ├── receipt_sp.model         # Step 4: SentencePiece tokenizer
    ├── receipt_dataset.pt       # Step 4: 学習データ
    ├── best_receipt_kie.pt      # Step 5: 最良モデル (PyTorch)
    ├── receipt_kie.onnx         # Step 6: FP32 ONNX
    └── receipt_kie_int8.onnx    # Step 6: INT8 ONNX

# Flutter アセット (リリースに含める)
assets/models/
├── receipt_kie_int8.onnx       # ~6MB
└── receipt_sp.model            # ~500KB

# Flutter コード
lib/infrastructure/ml/
└── receipt_kie_model.dart      # Step 7: 推論サービス
```

---

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| 200 サンプルでは F1 が低い | 精度不足 | Phase 1 規則をフォールバックとして残す |
| LLM ラベリング品質にばらつき | 学習ノイズ | verify_labels.py で検出 + 手動修正 |
| ONNX Runtime Flutter の互換性問題 | 統合失敗 | tflite_flutter へのフォールバックパス |
| SentencePiece の Flutter 統合が複雑 | 開発遅延 | MethodChannel 経由で native SP を呼ぶ |
| モデル 6MB がアプリサイズに影響 | UX 悪化 | 初回起動時にダウンロード (オプション) |

## 判断基準

**Phase 2 に進む条件:**
- [ ] Phase 1 が安定稼働し、200+ 枚のレシートが蓄積
- [ ] Phase 1 の精度が目標未達 (金額 <90%) の場合に優先度を上げる
- [ ] Phase 1 の精度が十分 (金額 >95%) なら Phase 2 は見送り可

---

**作成日:** 2026-02-25
**作成者:** Claude Opus 4.6
**関連ドキュメント:** `docs/arch/02-module-specs/MOD-004_OCR.md` (Section: 未来演進路線)
