# Fuzzy Category Matching Implementation

**日期:** 2026-02-23
**時間:** 12:32
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Voice Input / Category Matching

---

## 任务概述

Replace the hardcoded keyword-only `CategoryMatcher` with a multi-signal `FuzzyCategoryMatcher` that supports fuzzy edit-distance matching, user-added L2 category matching, and adaptive learning from user corrections. This enables the voice input system to improve category recognition accuracy over time based on user behavior.

---

## 完成的工作

### 1. 主要变更

**New Files Created (12):**
- `lib/application/voice/levenshtein.dart` — O(min(n,m)) space Levenshtein distance with normalized similarity
- `lib/application/voice/fuzzy_category_matcher.dart` — 3-signal scoring engine (seed keywords, edit distance, learned mappings)
- `lib/application/voice/record_category_correction_use_case.dart` — Use case for recording user category corrections
- `lib/data/tables/category_keyword_preferences_table.dart` — Drift table for keyword-category learning
- `lib/data/daos/category_keyword_preference_dao.dart` — DAO with upsert, find, decay operations
- `lib/data/repositories/category_keyword_preference_repository_impl.dart` — Repository implementation
- `lib/features/accounting/domain/models/category_keyword_preference.dart` — Domain model with scoring logic
- `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart` — Abstract repository interface
- `test/unit/application/voice/levenshtein_test.dart` — 15 tests
- `test/unit/application/voice/fuzzy_category_matcher_test.dart` — 5 tests
- `test/unit/application/voice/record_category_correction_use_case_test.dart` — 2 tests
- `test/unit/data/daos/category_keyword_preference_dao_test.dart` — 7 tests

**Modified Files (10):**
- `lib/features/accounting/domain/models/voice_parse_result.dart` — Added `learning` to `MatchSource` enum
- `lib/data/app_database.dart` — Schema v6→v7, added CategoryKeywordPreferences table
- `lib/application/voice/parse_voice_input_use_case.dart` — Replaced CategoryMatcher with FuzzyCategoryMatcher, added keyword extraction
- `lib/features/accounting/presentation/providers/repository_providers.dart` — Added categoryKeywordPreferenceRepositoryProvider
- `lib/features/accounting/presentation/providers/voice_providers.dart` — Replaced CategoryMatcher with FuzzyCategoryMatcher
- `lib/features/accounting/presentation/providers/use_case_providers.dart` — Added recordCategoryCorrectionUseCaseProvider
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — Added voiceKeyword param, category correction recording
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — Added keyword extraction and passing to confirm screen
- `test/unit/application/voice/parse_voice_input_use_case_test.dart` — Updated mocks

**Deleted Files (3):**
- `lib/application/voice/category_matcher.dart` — Old hardcoded matcher
- `test/unit/application/voice/category_matcher_test.dart` — Old tests
- `test/unit/application/voice/category_matcher_test.mocks.dart` — Old mock file

### 2. 技术决策

- **3-Signal Scoring Engine:** Combines seed keyword matching, Levenshtein edit distance matching against DB category names, and learned user preferences. Max-wins scoring with learning bonus overlay.
- **CJK Threshold Fix:** Changed plan's `keyword.length <= 2 ? 0.8` to `keyword.length <= 1 ? 0.8` because 2-char Chinese keywords like '咖啡' couldn't match '咖啡厅' (similarity = 0.667).
- **Learning Model:** `CategoryKeywordPreference` with hitCount-based scoring — `isLearned` threshold at hitCount >= 2, bonus of 0.30 (learned) or 0.15 (single-use).
- **Database Migration:** v6→v7 with `CategoryKeywordPreferences` table using composite PK (keyword, categoryId).

### 3. 代码变更统计
- **修改文件数量:** 30 files (12 new, 10 modified, 3 deleted + generated files)
- **添加代码行数:** ~1,887 lines
- **删除代码行数:** ~333 lines

---

## 遇到的问题与解决方案

### 问题 1: Missing LedgerType import
**症状:** Compilation error in fuzzy_category_matcher.dart
**原因:** Used `LedgerType` in `resolveLedgerType` method without importing transaction.dart
**解决方案:** Added `import '../../features/accounting/domain/models/transaction.dart'`

### 问题 2: Missing mock stubs for suggestForKeyword
**症状:** MissingStubError in tests
**原因:** New `suggestForKeyword` method on repository interface not stubbed in test setup
**解决方案:** Added `when(mockPrefRepo.suggestForKeyword(any)).thenAnswer((_) async => null)` to all test groups

### 问题 3: Unused element warning for learningBonus constructor param
**症状:** Analyzer warning — `learningBonus` never passed via constructor
**原因:** Field was set via direct assignment (`candidate.learningBonus = bonus`) not constructor
**解决方案:** Changed from constructor parameter to field initializer `double learningBonus = 0.0`

### 问题 4: Coupled Tasks 6 and 7
**症状:** Provider wiring (Task 6) couldn't compile without ParseVoiceInputUseCase update (Task 7)
**原因:** Provider passed `fuzzyCategoryMatcher:` parameter that didn't exist yet on the use case constructor
**解决方案:** Combined Tasks 6 and 7 into a single batch

---

## 测试验证

- [x] 单元测试通过 (590 pass, 1 pre-existing failure)
- [x] 新增测试: 29 tests (15 levenshtein + 5 fuzzy matcher + 2 use case + 7 DAO)
- [x] flutter analyze: 0 new warnings (1 pre-existing info in voice_text_parser_test.dart)
- [ ] 手动测试验证
- [x] 代码审查完成

---

## Git 提交记录

```
8596935 feat(voice): add Levenshtein edit distance algorithm
5787d38 feat(voice): add learning source to MatchSource enum
a2069a7 feat(data): add CategoryKeywordPreferences table, DAO, repo for voice learning
4830fc8 feat(voice): add FuzzyCategoryMatcher with 3-signal scoring engine
282d664 feat(voice): add RecordCategoryCorrectionUseCase for learning
c8d47c6 feat(voice): wire FuzzyCategoryMatcher and update ParseVoiceInputUseCase
5fb1fcf feat(voice): record category corrections from TransactionConfirmScreen
e389a3c refactor(voice): remove old CategoryMatcher (replaced by FuzzyCategoryMatcher)
```

---

## 后续工作

- [ ] Manual testing of voice input → category correction → re-recognition flow
- [ ] Consider adding `decayStalePreferences` scheduled cleanup
- [ ] Monitor category match accuracy metrics in production
- [ ] Consider adding confidence threshold tuning based on real usage data

---

## 参考资源

- [Implementation Plan](docs/plans/2026-02-22-fuzzy-category-matching-impl.md)
- [Design Document](docs/plans/2026-02-22-fuzzy-category-matching.md)

---

**创建时间:** 2026-02-23 12:32
**作者:** Claude Opus 4.6
