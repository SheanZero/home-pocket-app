import '../../../features/accounting/domain/models/category_keyword_preference.dart';
import 'synonyms_support.dart';

/// Voice synonym seeds — admin / statement-line L1 families: Allowance,
/// Other-expense, Tax & social-security, Insurance, Special life-events,
/// Asset / investment vehicles. Phase 50 D-04 (DECOUP-02): the user scope
/// decision INCLUDES these admin families in full L2 coverage (RESEARCH A4
/// "err toward including admin buckets") — every speakable L2 here carries
/// ≥1 zh DIRECT seed AND ≥1 ja DIRECT seed. People say some of these aloud
/// ("汽车税", "房贷"), and the categoryId orphan gate guards typos either way.
///
/// Han-only ja note: several admin terms (所得税, 年金, 生命保険…) have no
/// natural katakana loanword. Per the user word-quality decision we DO NOT
/// force a wrong loanword — we provide the natural kana reading (e.g.
/// しょとくぜい), which is a real spoken form and gives the kana-based ja
/// classifier its non-Han signal.
final List<CategoryKeywordPreference> kSynonymsAdmin = [
  ..._taxAndInsurance,
  ..._specialAndAsset,
  ..._allowanceAndOther,
];

final List<CategoryKeywordPreference> _taxAndInsurance = [
  // ===== Tax & social security =====
  seed('个人所得税', 'cat_tax_income'), // zh — income tax
  seed('所得税', 'cat_tax_income'), // zh/ja — income tax (Han)
  seed('しょとくぜい', 'cat_tax_income'), // ja — income tax (hiragana reading)
  seed('养老金', 'cat_tax_pension'), // zh — pension
  seed('年金保险费', 'cat_tax_pension'), // zh — pension contribution
  seed('ねんきん', 'cat_tax_pension'), // ja — pension (hiragana reading; 年金 is Han)
  seed('医保', 'cat_tax_health_insurance'), // zh — health insurance (national)
  seed('健康保险费', 'cat_tax_health_insurance'), // zh — health insurance premium
  seed('けんこうほけん', 'cat_tax_health_insurance'), // ja — health insurance (hiragana)
  seed('故乡税', 'cat_tax_furusato'), // zh — hometown tax (furusato)
  seed('家乡税', 'cat_tax_furusato'), // zh — furusato nozei
  seed('ふるさと納税', 'cat_tax_furusato'), // ja — furusato nozei (hiragana ふるさと)
  seed('消费税', 'cat_tax_consumption'), // zh — consumption tax
  seed('消費税', 'cat_tax_consumption'), // ja — consumption tax (Han)
  seed('しょうひぜい', 'cat_tax_consumption'), // ja — consumption tax (hiragana reading)
  seed('护理保险费', 'cat_tax_nursing_insurance'), // zh — nursing-care insurance
  seed('介护保险', 'cat_tax_nursing_insurance'), // zh — long-term care insurance
  seed('かいごほけん', 'cat_tax_nursing_insurance'), // ja — care insurance (hiragana reading)
  seed('其他税费', 'cat_tax_other'), // zh — other taxes
  seed('その他税金', 'cat_tax_other'), // ja — other taxes (kana その他)
  // ===== Insurance L1 family =====
  seed('寿险', 'cat_insurance_life'), // zh — life insurance
  seed('人寿保险', 'cat_insurance_life'), // zh — life insurance
  seed('せいめいほけん', 'cat_insurance_life'), // ja — life insurance (hiragana reading; 生命保険 is Han)
  seed('医疗保险', 'cat_insurance_medical'), // zh — medical insurance
  seed('いりょうほけん', 'cat_insurance_medical'), // ja — medical insurance (hiragana reading)
  seed('癌症保险', 'cat_insurance_cancer'), // zh — cancer insurance
  seed('防癌险', 'cat_insurance_cancer'), // zh — cancer cover
  seed('がん保険', 'cat_insurance_cancer'), // ja — cancer insurance (hiragana がん)
  seed('收入保障保险', 'cat_insurance_income'), // zh — income-protection insurance
  seed('しょとくほしょうほけん', 'cat_insurance_income'), // ja — income-protection insurance (hiragana reading)
  seed('其他保险', 'cat_insurance_other'), // zh — other insurance
  seed('その他保険', 'cat_insurance_other'), // ja — other insurance (kana その他)
];

final List<CategoryKeywordPreference> _specialAndAsset = [
  // ===== Special life-events =====
  seed('婚礼', 'cat_special_wedding'), // zh — wedding
  seed('结婚', 'cat_special_wedding'), // zh — marriage
  seed('ウェディング', 'cat_special_wedding'), // ja — wedding (katakana)
  seed('不孕治疗', 'cat_special_fertility'), // zh — fertility treatment
  seed('试管婴儿', 'cat_special_fertility'), // zh — IVF
  seed('ふにんちりょう', 'cat_special_fertility'), // ja — fertility treatment (hiragana reading)
  seed('看护', 'cat_special_nursing'), // zh — nursing care
  seed('护理', 'cat_special_nursing'), // zh — care
  seed('かいご', 'cat_special_nursing'), // ja — nursing care (hiragana reading; 介護 is Han)
  seed('葬礼', 'cat_special_funeral'), // zh — funeral
  seed('丧事', 'cat_special_funeral'), // zh — funeral affairs
  seed('そうしき', 'cat_special_funeral'), // ja — funeral (hiragana reading; 葬式 is Han)
  seed('人生大事', 'cat_special_life_event'), // zh — major life event
  seed('纪念日', 'cat_special_life_event'), // zh — anniversary / milestone
  seed('ライフイベント', 'cat_special_life_event'), // ja — life event (katakana)
  seed('过年', 'cat_special_newyear'), // zh — new-year spending
  seed('新年', 'cat_special_newyear'), // zh — new year
  seed('お正月', 'cat_special_newyear'), // ja — new year (kana お)
  seed('搬家', 'cat_special_movement'), // zh — moving / relocation
  seed('迁居', 'cat_special_movement'), // zh — relocation
  seed('引っ越し', 'cat_special_movement'), // ja — moving (hiragana ひっこし)
  seed('其他特殊支出', 'cat_special_other'), // zh — other special expense
  seed('その他特別費', 'cat_special_other'), // ja — other special cost (kana その他)
  // ===== Asset / investment vehicles =====
  seed('免税投资', 'cat_asset_nisa'), // zh — tax-free investment account (NISA)
  seed('小额投资', 'cat_asset_nisa'), // zh — small-lot investing
  seed('ニーサ', 'cat_asset_nisa'), // ja — NISA (katakana)
  seed('个人养老金账户', 'cat_asset_ideco'), // zh — personal pension account (iDeCo)
  seed('个人养老投资', 'cat_asset_ideco'), // zh — personal retirement investing
  seed('イデコ', 'cat_asset_ideco'), // ja — iDeCo (katakana)
  seed('定投', 'cat_asset_tsumitate'), // zh — periodic investing
  seed('积立投资', 'cat_asset_tsumitate'), // zh — accumulation investing
  seed('つみたて', 'cat_asset_tsumitate'), // ja — accumulation (hiragana)
  seed('存款', 'cat_asset_savings'), // zh — deposit / savings
  seed('储蓄', 'cat_asset_savings'), // zh — savings
  seed('ちょきん', 'cat_asset_savings'), // ja — savings (hiragana reading; 貯金 is Han)
  seed('股票', 'cat_asset_stock'), // zh — stocks
  seed('炒股', 'cat_asset_stock'), // zh — stock trading
  seed('かぶ', 'cat_asset_stock'), // ja — stock (hiragana reading; 株 is Han)
  seed('外汇', 'cat_asset_fx'), // zh — foreign exchange
  seed('炒外汇', 'cat_asset_fx'), // zh — FX trading
  seed('エフエックス', 'cat_asset_fx'), // ja — FX (katakana)
  seed('房产投资', 'cat_asset_realestate'), // zh — real-estate investment
  seed('不动产', 'cat_asset_realestate'), // zh — real estate
  seed('ふどうさん', 'cat_asset_realestate'), // ja — real estate (hiragana reading; 不動産 is Han)
  seed('其他资产', 'cat_asset_other'), // zh — other asset
  seed('その他資産', 'cat_asset_other'), // ja — other asset (kana その他)
];

final List<CategoryKeywordPreference> _allowanceAndOther = [
  // ===== Allowance — direct coverage =====
  seed('零花钱', 'cat_allowance_self'), // zh — own pocket money
  seed('我的零花', 'cat_allowance_self'), // zh — my allowance
  seed('お小遣い', 'cat_allowance_self'), // ja — pocket money (mixed)
  seed('こづかい', 'cat_allowance_self'), // ja — allowance (hiragana)
  seed('配偶零花钱', 'cat_allowance_spouse'), // zh — spouse allowance (neutral)
  seed('伴侣零花钱', 'cat_allowance_spouse'), // zh — partner allowance (neutral, D2 refinement)
  seed('配偶のお小遣い', 'cat_allowance_spouse'), // ja — spouse allowance (mixed)
  seed('つまのこづかい', 'cat_allowance_spouse'), // ja — spouse's allowance (hiragana)
  seed('孩子零花钱', 'cat_allowance_kids'), // zh — kids allowance
  seed('儿童零花', 'cat_allowance_kids'), // zh — children's allowance
  seed('子供のお小遣い', 'cat_allowance_kids'), // ja — kids allowance (mixed)
  seed('こどものこづかい', 'cat_allowance_kids'), // ja — child allowance (hiragana)
  seed('其他零花', 'cat_allowance_other'), // zh — other allowance
  seed('その他お小遣い', 'cat_allowance_other'), // ja — other allowance (kana その他)
  // ===== Other — direct coverage =====
  seed('汇款', 'cat_other_remittance'), // zh — remittance
  seed('转账', 'cat_other_remittance'), // zh — money transfer
  seed('送金', 'cat_other_remittance'), // ja — remittance (Han)
  seed('そうきん', 'cat_other_remittance'), // ja — remittance (hiragana)
  seed('杂费', 'cat_other_misc'), // zh — miscellaneous
  seed('杂项', 'cat_other_misc'), // zh — sundries
  seed('雑費', 'cat_other_misc'), // ja — misc expense (Han)
  seed('ざっぴ', 'cat_other_misc'), // ja — misc expense (hiragana)
  seed('未分类', 'cat_other_unclassified'), // zh — unclassified
  seed('其它支出', 'cat_other_unclassified'), // zh — other spending
  seed('未分類', 'cat_other_unclassified'), // ja — unclassified (Han)
  seed('みぶんるい', 'cat_other_unclassified'), // ja — unclassified (hiragana)
  seed('其他杂项', 'cat_other_other'), // zh — other misc
  seed('その他雑費', 'cat_other_other'), // ja — other misc (kana その他)
  // ===== Other-expense override seeds (Phase 23 D-15 / IN-06) =====
  // Exercises the cat_other_expense → cat_other_other override in
  // VoiceCategoryResolver._ensureL2 via real corpus utterances.
  // 'other' is added as a v1.4+ en-voice hedge — voice gating in v1.3 is
  // zh/ja only, but the override is exercised in case en voice activates.
  // Warning for v1.4+ en voice: 'other' is a common English word that may
  // collide with contextual utterances like "the other day…". Add corpus
  // regression cases before enabling full en voice support.
  seed('その他', 'cat_other_expense'),
  seed('其他', 'cat_other_expense'),
  seed('other', 'cat_other_expense'),
];
