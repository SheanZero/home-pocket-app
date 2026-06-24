import '../../../features/accounting/domain/models/category_keyword_preference.dart';
import 'synonyms_support.dart';

/// Voice synonym seeds — Health & Medical, Education & Self-Improvement,
/// Hobbies & Entertainment L1 families. Phase 50 D-04 (DECOUP-02): every
/// speakable L2 here carries ≥1 zh DIRECT seed AND ≥1 ja DIRECT seed
/// (full L2 coverage). See `default_synonyms.dart` for the contract.
final List<CategoryKeywordPreference> kSynonymsHealthEducationHobbies = [
  ..._health,
  ..._education,
  ..._hobbies,
];

final List<CategoryKeywordPreference> _health = [
  // ===== Health =====
  seed('病院', 'cat_health_hospital'),
  seed('薬', 'cat_health_medicine'),
  seed('医院', 'cat_health_hospital'),
  seed('药', 'cat_health_medicine'),
  seed('びょういん', 'cat_health_hospital'), // ja — hospital (hiragana reading; 病院 is Han)
  seed('くすり', 'cat_health_medicine'), // ja — medicine (hiragana reading; 薬 is Han)
  // ===== Health & Medical — direct coverage =====
  seed('健身', 'cat_health_fitness'), // zh — fitness
  seed('健身房', 'cat_health_fitness'), // zh — gym
  seed('ジム', 'cat_health_fitness'), // ja — gym
  seed('フィットネス', 'cat_health_fitness'), // ja — fitness
  seed('按摩', 'cat_health_massage'), // zh — massage
  seed('推拿', 'cat_health_massage'), // zh — therapeutic massage
  seed('マッサージ', 'cat_health_massage'), // ja — massage
  seed('せいたい', 'cat_health_massage'), // ja — body adjustment (hiragana)
  seed('看牙', 'cat_health_dental'), // zh — dental visit
  seed('牙科', 'cat_health_dental'), // zh — dentistry
  seed('歯医者', 'cat_health_dental'), // ja — dentist (Han)
  seed('はいしゃ', 'cat_health_dental'), // ja — dentist (hiragana)
  seed('保健品', 'cat_health_supplements'), // zh — supplements
  seed('营养品', 'cat_health_supplements'), // zh — nutrition supplement
  seed('サプリ', 'cat_health_supplements'), // ja — supplement
  seed('サプリメント', 'cat_health_supplements'), // ja — supplement
  seed('体检', 'cat_health_dock'), // zh — medical checkup
  seed('健康检查', 'cat_health_dock'), // zh — health examination
  seed('人間ドック', 'cat_health_dock'), // ja — comprehensive checkup (mixed)
  seed('けんしん', 'cat_health_dock'), // ja — health checkup (hiragana)
  seed('其他医疗', 'cat_health_other'), // zh — other medical
  seed('その他医療', 'cat_health_other'), // ja — other medical (kana その他)
];

final List<CategoryKeywordPreference> _education = [
  // ===== Education =====
  seed('本', 'cat_education_books'),
  seed('书', 'cat_education_books'),
  seed('ほん', 'cat_education_books'), // ja — book (hiragana)
  seed('書籍', 'cat_education_books'), // ja — books (Han)
  // ===== Education & Self-Improvement — direct coverage =====
  seed('报纸', 'cat_education_newspapers'), // zh — newspaper
  seed('订报', 'cat_education_newspapers'), // zh — newspaper subscription
  seed('新聞', 'cat_education_newspapers'), // ja — newspaper (Han)
  seed('しんぶん', 'cat_education_newspapers'), // ja — newspaper (hiragana)
  seed('上课', 'cat_education_classes'), // zh — classes / lessons
  seed('培训', 'cat_education_classes'), // zh — training course
  seed('習い事', 'cat_education_classes'), // ja — lessons (mixed)
  seed('レッスン', 'cat_education_classes'), // ja — lesson
  seed('教材', 'cat_education_textbooks'), // zh — teaching material
  seed('课本', 'cat_education_textbooks'), // zh — textbook
  seed('教科書', 'cat_education_textbooks'), // ja — textbook (Han)
  seed('テキスト', 'cat_education_textbooks'), // ja — textbook
  seed('学费', 'cat_education_tuition'), // zh — tuition
  seed('学杂费', 'cat_education_tuition'), // zh — school fees
  seed('学費', 'cat_education_tuition'), // ja — tuition (Han)
  seed('がくひ', 'cat_education_tuition'), // ja — tuition (hiragana)
  seed('补习班', 'cat_education_cram_school'), // zh — cram school
  seed('辅导班', 'cat_education_cram_school'), // zh — tutoring class
  seed('塾', 'cat_education_cram_school'), // ja/zh — cram school (Han)
  seed('じゅく', 'cat_education_cram_school'), // ja — cram school (hiragana)
  seed('升学考试', 'cat_education_entrance_exam'), // zh — entrance exam
  seed('考试报名', 'cat_education_entrance_exam'), // zh — exam registration
  seed('受験', 'cat_education_entrance_exam'), // ja — entrance exam (Han)
  seed('じゅけん', 'cat_education_entrance_exam'), // ja — taking exams (hiragana)
  seed('学资保险', 'cat_education_gakushi_hoken'), // zh — education insurance
  seed('教育金保险', 'cat_education_gakushi_hoken'), // zh — education savings insurance
  seed('学資保険', 'cat_education_gakushi_hoken'), // ja — gakushi hoken (Han)
  seed('がくしほけん', 'cat_education_gakushi_hoken'), // ja — education insurance (hiragana)
  seed('讲座', 'cat_education_seminar'), // zh — seminar
  seed('研讨会', 'cat_education_seminar'), // zh — workshop
  seed('セミナー', 'cat_education_seminar'), // ja — seminar
  seed('こうざ', 'cat_education_seminar'), // ja — course / lecture (hiragana)
  seed('其他教育', 'cat_education_other'), // zh — other education
  seed('その他教育', 'cat_education_other'), // ja — other education (kana)
];

final List<CategoryKeywordPreference> _hobbies = [
  // ===== Hobbies =====
  seed('映画', 'cat_hobbies_movies'),
  seed('ゲーム', 'cat_hobbies_games'),
  seed('カラオケ', 'cat_hobbies'), // L1 → cat_hobbies_other
  seed('電影', 'cat_hobbies_movies'),
  seed('电影', 'cat_hobbies_movies'),
  seed('游戏', 'cat_hobbies_games'),
  seed('えいが', 'cat_hobbies_movies'), // ja — movie (hiragana)
  // ===== Hobbies & Entertainment — direct coverage =====
  seed('休闲', 'cat_hobbies_leisure'), // zh — leisure
  seed('娱乐', 'cat_hobbies_leisure'), // zh — entertainment
  seed('レジャー', 'cat_hobbies_leisure'), // ja — leisure
  seed('あそび', 'cat_hobbies_leisure'), // ja — play / leisure (hiragana)
  seed('活动', 'cat_hobbies_events'), // zh — event
  seed('演唱会', 'cat_hobbies_events'), // zh — concert
  seed('イベント', 'cat_hobbies_events'), // ja — event
  seed('ライブ', 'cat_hobbies_events'), // ja — live show
  seed('漫画', 'cat_hobbies_books'), // zh — comics / manga
  seed('小说', 'cat_hobbies_books'), // zh — novel
  seed('まんが', 'cat_hobbies_books'), // ja — manga (hiragana)
  seed('コミック', 'cat_hobbies_books'), // ja — comic
  seed('旅游', 'cat_hobbies_travel'), // zh — travel
  seed('旅行', 'cat_hobbies_travel'), // zh — trip
  seed('りょこう', 'cat_hobbies_travel'), // ja — travel (hiragana)
  seed('ツアー', 'cat_hobbies_travel'), // ja — tour
  seed('音乐', 'cat_hobbies_music'), // zh — music
  seed('演唱', 'cat_hobbies_music'), // zh — singing / vocal
  seed('音楽', 'cat_hobbies_music'), // ja — music (Han)
  seed('おんがく', 'cat_hobbies_music'), // ja — music (hiragana)
  seed('兴趣订阅', 'cat_hobbies_subscription'), // zh — hobby subscription
  seed('视频会员', 'cat_hobbies_subscription'), // zh — streaming membership
  seed('動画サブスク', 'cat_hobbies_subscription'), // ja — video subscription (mixed)
  seed('はいしん', 'cat_hobbies_subscription'), // ja — streaming (hiragana)
  seed('追星', 'cat_hobbies_oshikatsu'), // zh — idol fandom
  seed('应援', 'cat_hobbies_oshikatsu'), // zh — cheering / support spending
  seed('推し活', 'cat_hobbies_oshikatsu'), // ja — oshikatsu (mixed)
  seed('おしかつ', 'cat_hobbies_oshikatsu'), // ja — oshikatsu (hiragana)
  seed('其他娱乐', 'cat_hobbies_other'), // zh — other hobbies
  seed('その他趣味', 'cat_hobbies_other'), // ja — other hobbies (kana)
];
