# Voice Category Recognition — Improvement Research

**Date:** 2026-05-26
**Author:** Research agent (Claude Opus 4.7)
**Scope:** Strategic options to improve `VoiceCategoryResolver` recognition rate for zh + ja short utterances. Recommendation only — not an implementation plan.

---

## 1. Status quo

### What the architecture docs claim

`docs/arch/02-module-specs/MOD-009_VoiceInput.md:121,207,1459,1541` describes a 3-layer voice category pipeline that **reuses**:

1. **Rule Engine** (category-id based, dual-ledger routing)
2. **MerchantDatabase** with **"500+ merchants"** (`MOD-009 line 121, 1459`)
3. **ML Classifier (TFLite, 85%+ accuracy)** per project memory

### What is actually wired in code today

The voice flow `lib/application/voice/parse_voice_input_use_case.dart:60-104` orchestrates **only two** lookups, neither of them ML:

| Step | Code | Source |
|---|---|---|
| 1. Merchant match | `voice_text_parser.dart:491-503` → `merchant_database.dart:129-171` | Hard-coded **13 entries** (`merchant_database.dart:46-123`) |
| 2. Keyword exact match | `voice_category_resolver.dart:92-106` | `category_keyword_preferences` DAO, populated by 88 seed rows in `lib/shared/constants/default_synonyms.dart:33-159` |
| 2.5. Seed-row substring fallback | `voice_category_resolver.dart:108-131` | Same 88 seeds (added in quick task 260526-l0o) |

**Key finding — the "3-layer" pipeline is documentation-only.** The TFLite classifier in MEMORY.md and MOD-009 has never been implemented:

- `lib/infrastructure/ml/` contains **only** `merchant_database.dart`. No `tflite_classifier.dart`, no `.tflite` asset, no `tflite_flutter` pubspec dependency.
- `lib/application/dual_ledger/classification_service.dart:32-37` documents the gap explicitly with `// TODO: Implement TFLiteClassifier when model is available`.
- "500+ merchants" → actual `_MerchantEntry` count is **13**.

Real pipeline today: **regex-extracted keyword → 13-entry merchant alias table → ~88-entry synonym dict (exact + length-≥2 substring)**. Everything else is aspirational.

---

## 2. Why hand-curated synonyms don't scale

| Evidence | Implication |
|---|---|
| HowNet's extended E-HowNet annotates **~88K** traditional-Chinese lemmas with structured definitions ([CA-EHN paper](https://arxiv.org/pdf/1908.07218)); dining + transport + retail together easily exceed 2K headwords before counting colloquial variants. The current dict is ~88 zh/ja entries. | Coverage is roughly **3 orders of magnitude** below the relevant lexicon. |
| The recent failures all came from **legitimate everyday phrasing** that no curator could have predicted ahead of time — `外出就餐` (formal), `下馆子` (colloquial), `公交卡` (instrument + verb compression), `新干线` (proper noun ja→zh borrowing). Japanese adds katakana variants per merchant (`スタバ` vs `スターバックス`) and dialect (関西 vs 標準語). | Every new user produces a fresh tail of misses; the curation cost grows linearly with users, not logarithmically. |
| Substring fallback added in quick task 260526-l0o (`voice_category_resolver.dart:108-131`) raises recall slightly but is still bounded by what is in the seed list — it cannot match `外出就餐` unless `外食`-class concepts are already seeded. | Substring tricks don't change the asymptote; they only push the failure point one phrasing further out. |

The structural problem: **string equality and substring containment cannot bridge semantic distance**. `外出就餐` ≡ `外食` ≡ `下馆子` ≡ `去饭店` semantically, but share **zero** characters with each other in some pairs.

---

## 3. Options (ranked by effort:value ratio)

| # | Option | Effort | Accuracy gain (est.) | Offline | Privacy | zh + ja |
|---|---|---|---|---|---|---|
| F | Active learning from `category_keyword_preferences` corrections | XS (1-2 days) | +5 pp short-term, +15 pp at 3 months | Yes | Local only | Yes |
| A | Expand hand-curated dict with crowd-sourced lists (zh dining/transport gazetteers) | S (2-4 days) | +8-12 pp on common verbs | Yes | Local | Yes |
| D | Hybrid: dict-first → on-device embedding fallback → user correction | M (1-2 wks) | +20-30 pp | Yes | Local | Yes |
| C | On-device sentence-embedding semantic similarity (multilingual-MiniLM int8) | M | +15-25 pp | Yes | Local | Yes |
| B | Wire a TFLite text classifier (project's "stated" 3-layer design) | M-L | +10-20 pp, brittle on new vocab | Yes | Local | Yes (training-data dependent) |
| E | On-device quantized LLM (Phi-3-mini 4-bit / Qwen2.5 0.5B) for NLU | L | +30-40 pp ceiling, but device-tier limited | Yes (iPhone 14+ / mid-high Android only) | Local | Excellent |

### F. Active learning from corrections (quickest win)

Infrastructure is half-built: `category_keyword_preferences` records corrections with `hitCount` / `lastUsed`, and `voice_category_resolver.dart:92-106` already prefers learned rows over seeds. The improvement is to (a) record the **full extracted keyword** (not just the matched substring) on every accepted correction, and (b) periodically promote frequent learned phrases into the seed set client-side. No new dependencies. Cold-start users see no benefit, so this doesn't help the first-utterance failure mode that motivated this research — but it costs little and compounds.

### A. Crowd-sourced dict expansion

Pull from open lexical resources: HowNet (~88K zh lemmas, [CA-EHN paper](https://arxiv.org/pdf/1908.07218)), [awesome-japanese-nlp-resources](https://github.com/taishi-i/awesome-japanese-nlp-resources/blob/main/docs/huggingface.md), Wiktionary category dumps, kakeibo-competitor public help docs. Could 5×-10× the dict (88 → 800-1000) in a few days. Static asset only — zero privacy impact. Gain plateaus around +10 pp because the long tail keeps growing; quality control is the cost (archaic terms, polysemes like `本` = book OR origin/this).

### B. Wire a TFLite text classifier (per stated design)

Tooling exists via [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) + `BertNLClassifier` ([Google AI Edge docs](https://ai.google.dev/edge/litert/libraries/task_library/bert_nl_classifier)). MobileBERT-multilingual or distilled XLM-R quantized to int8 lands at ~25-50 MB. **But** training a classifier requires labeled data — ~500-1000 utterances per L2 category × ~30 L2 categories = a 15-30K-example dataset. The project has no such corpus. Closed-class: adding a category requires retraining.

### C. On-device semantic embedding similarity

Replace string equality with cosine similarity over sentence embeddings. `paraphrase-multilingual-MiniLM-L12-v2` int8 ONNX is **~118M params → ~120 MB fp32, ~30-40 MB int8** ([Sprylab quantized port](https://huggingface.co/Sprylab/paraphrase-multilingual-MiniLM-L12-v2-onnx-quantized); [int8 ~3× speedup per sbert docs](https://sbert.net/docs/sentence_transformer/usage/efficiency.html)). Alternative: `multilingual-e5-small` (also 384-dim, often better on short text — [intfloat/multilingual-e5-small](https://huggingface.co/intfloat/multilingual-e5-small)).

Pipeline: embed user utterance → cosine-compare against pre-computed embeddings of dict entries → top-1 above threshold wins. The dict stays as the **label set** (each seed = one anchor); the model bridges paraphrase distance. Latency ~30-100 ms on iPhone 14+ / mid-tier Android — acceptable post-STT. Risk: threshold tuning.

### D. Hybrid (recommended primary path)

Pipeline: **dict exact-match → dict embedding-similarity fallback → correction loop (F)**. Confidence is exposed per layer; UI shows a manual-pick affordance only when all three miss. Dict remains the label set, so adding a category stays zero-code. Combines C + F infrastructure; compounds the gains.

### E. On-device LLM for NLU

Phi-3-mini-4bit (~2.4 GB) runs at >12 tok/s on iPhone A16+ ([Phi-3 Technical Report](https://arxiv.org/html/2404.14219v4)). Qwen2.5 0.5B/1.5B is smaller and CJK-tuned ([MLC-LLM](https://www.callstack.com/blog/want-to-run-llms-on-your-device-meet-mlc)). Highest accuracy ceiling, but the **~1-2 GB asset**, battery cost, and exclusion of iPhone 12 / mid-tier Android make it premature for v1.x.

---

## 4. Recommendation

**Primary path: Option D (hybrid dict → embedding → learning).**

Justification:
- **Local-first / privacy:** All inference on device, no telemetry.
- **Offline:** Embeddings + ONNX runtime are bundled assets.
- **Flutter:** `onnxruntime` and `tflite_flutter` are mature; `multilingual-e5-small` int8 fits in a ~40 MB asset — comparable to a single OCR model asset MOD-004 already plans for.
- **zh + ja:** `multilingual-e5-small` and `paraphrase-multilingual-MiniLM-L12-v2` both list zh + ja in their training data and benchmark well on CJK short-text retrieval.
- **Backward-compatible:** The seed dict remains the label set; today's exact-match path stays as the fast path. Embedding only fires on miss. Zero risk to current behavior.
- **Extensibility:** Adding a new L2 category is still "add one row to `default_synonyms.dart`" — the embedding generalizes around that anchor.

**Quick win shippable in 1 week: Option F (close the active-learning loop).**

Specifically: persist the full extracted keyword (not just the dict-matched substring) whenever the user accepts or corrects a category. This costs ~1 day of work, ships with no new dependencies, and starts gathering the corrections corpus we will need to eventually evaluate option D's accuracy gain empirically.

---

## 5. What we should NOT do

- **No cloud NLU APIs** (OpenAI, Google NL API, Azure Language) — even free tiers violate the zero-knowledge architecture and require sending utterances over the network. Non-starter without explicit per-user opt-in, which adds UX/legal complexity disproportionate to the gain.
- **No on-device LLM in v1.x** (option E). The 1-2 GB asset, battery cost, and lower-end-device exclusion are unjustified when option D delivers 70-80% of the gain at 5% of the cost.
- **No federated learning / model updates over P2P sync** in this iteration. The existing P2P sync infrastructure is for `category_keyword_preferences` rows, not model weights; conflating the two would couple sync stability to model lifecycle.
- **Do not abandon the dict**. The dict is the **label set** (which categoryId an utterance maps to). The embedding model only provides similarity. Replacing the dict with a closed-class classifier (option B) sacrifices the zero-code-extensibility property documented in `default_synonyms.dart:18-22`.
- **Do not "fix" the docs/MEMORY.md claim of a wired TFLite classifier without first deciding whether option B or D is the path forward** — premature doc fixes lock in the wrong direction.

---

## 6. Open questions for the user

1. **App-size budget.** Adding a ~40 MB embedding asset (option C/D) raises the app bundle from current (~30-50 MB est.) to ~70-90 MB. Acceptable for v1.4+? Hard ceiling?
2. **Training data acceptance.** Option D's embedding model is pre-trained; we don't need labeled training data. But for evaluating accuracy gain (and tuning the similarity threshold), would you accept (a) synthetic test utterances we author, (b) a small recorded test set from internal use, or (c) only utterances captured via the option-F correction loop (slower but truly user-driven)?
3. **Failure-mode preference.** With embedding fallback, false positives (wrong category at high confidence) become possible in a way today's exact-match doesn't allow. Preference: (a) bias toward recall (more auto-matches, more wrong-categories on edge cases) or (b) bias toward precision (more "please pick manually" prompts)?
4. **Scope for v1.4.** Should option D ship as one phase, or as two — (a) option F quick-win in v1.3.1, (b) full option D in v1.4 after we have correction-loop data to validate against?

---

## Sources

- [Phi-3 Technical Report — arXiv](https://arxiv.org/html/2404.14219v4)
- [MLC-LLM on mobile — Callstack blog](https://www.callstack.com/blog/want-to-run-llms-on-your-device-meet-mlc)
- [intfloat/multilingual-e5-small — Hugging Face](https://huggingface.co/intfloat/multilingual-e5-small)
- [Sprylab/paraphrase-multilingual-MiniLM-L12-v2-onnx-quantized — Hugging Face](https://huggingface.co/Sprylab/paraphrase-multilingual-MiniLM-L12-v2-onnx-quantized)
- [Sentence-Transformers efficiency / int8 quantization](https://sbert.net/docs/sentence_transformer/usage/efficiency.html)
- [BertNLClassifier — Google AI Edge LiteRT Task Library](https://ai.google.dev/edge/litert/libraries/task_library/bert_nl_classifier)
- [Text classification with TFLite Model Maker](https://ai.google.dev/edge/litert/libraries/modify/text_classification)
- [taishi-i/awesome-japanese-nlp-resources](https://github.com/taishi-i/awesome-japanese-nlp-resources/blob/main/docs/huggingface.md)
- [fastText pre-trained zh / ja vectors](https://huggingface.co/facebook/fasttext-zh-vectors)
- [CA-EHN: Commonsense Analogy from E-HowNet — arXiv](https://arxiv.org/pdf/1908.07218)
- [tflite_flutter on pub.dev](https://pub.dev/packages/tflite_flutter)
