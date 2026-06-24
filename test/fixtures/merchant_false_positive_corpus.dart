/// Adversarial false-positive corpus for `MerchantRecognizer` (Plan 50-03, SC2).
///
/// ~40 query strings that MUST NOT auto-fill at the 0.85 submit floor (D-03).
/// They are the gate proving the anchored scoring tiers + per-script
/// min-length guard (RESEARCH Assumptions A1/A2) do not regress to the retired
/// bidirectional-substring false-positive behavior (`merchant_database.dart`
/// `:158-159`) at ~400-merchant scale.
///
/// Each entry is a generic word, place name, food noun, or comment-word that
/// COLLIDES with a chain merchant surface under naive substring matching but is
/// NOT a merchant utterance. The contract asserted by
/// `merchant_false_positive_test.dart`:
///
///   recognizer.recognize(entry).isEmpty
///     OR recognizer.recognize(entry).first.score < 0.85
///
/// i.e. every entry either produces no candidate at all, or stays strictly
/// below the orchestrator's auto-fill floor (so the user is asked, never
/// silently committed — ADR-012).
///
/// Conventions (mirror `voice_category_corpus_ja.dart`):
///   - Pure `const` data, no IO, no DateTime.now().
///   - No imports from project source (fixture is data-only).
///
/// Honesty contract: each string is a plausible thing a user could say that is
/// NOT a merchant name. Several deliberately embed or are embedded by a chain
/// surface (e.g. お米 vs a 米-containing chain; モス as a 2-char substring of
/// モスバーガー) to exercise the containment + min-length tiers, not just the
/// trivially-disjoint case.
library;

/// The ~40 adversarial query strings (SC2 gate).
const List<String> merchantFalsePositiveCorpus = <String>[
  // ── generic food / grocery nouns (kanji-containing, len < min on containment)
  'お米', // 米 — collides with any 米-bearing chain; 2 runes, must not prefix-fill
  '米', // bare grain
  'お茶', // tea
  '水', // water
  '卵', // eggs
  '肉', // meat
  '魚', // fish
  '野菜', // vegetables
  'パン', // bread (kana, 2 runes)
  '牛乳', // milk

  // ── place names / wards (kanji, collide with location-named chains)
  '杉並区', // Suginami ward
  '渋谷', // Shibuya
  '新宿', // Shinjuku
  '東京駅', // Tokyo station
  '大阪', // Osaka
  '近所のお店', // "the shop nearby"
  '駅前', // "in front of the station"

  // ── comment / filler words (would naive-substring into many surfaces)
  'コーヒー', // generic coffee word (NOT a cafe brand)
  'カフェ', // generic cafe word
  'ランチ', // lunch
  'ごはん', // a meal
  '買い物', // shopping
  '飲み物', // a drink
  'お店', // "a shop"
  'いつもの', // "the usual"
  'ちょっと', // "a bit"
  'まあまあ', // "so-so"
  'いい感じ', // "feels good"
  'これ', // "this"
  'それ', // "that"

  // ── short fragments that are PROPER substrings of a chain surface
  'モス', // 2-char prefix fragment of モスバーガー — guarded by min-length
  'マツ', // fragment of マツモトキヨシ-style chains
  'すき', // fragment / "like"
  'ばあく', // gibberish overlap

  // ── latin generic words (len >= 3 but not a brand)
  'cafe', // generic
  'shop', // generic
  'mart', // generic suffix shared by many konbini surfaces
  'store', // generic
  'food', // generic
  'the', // article
];
